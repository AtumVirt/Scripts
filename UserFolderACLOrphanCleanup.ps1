$timestamp=$(get-date).ToString("yyyy-MM-dd-hh_mm_ss")
$LogPath="D:\Temp\Logs\UserFolderACLOrphanCleanup-$timestamp.log"
start-transcript -Path $LogPath

#region Variables
$dirpath = "D:\SHARES\Users"
$orphanPath="D:\Shares\Users\_Orphaned"
$ProductionRun=$true # Change this to $true in order to move directories that could not be matched to a "_Orphaned" folder for deleted/disabled users.
#endregion

#region fix ACLs
# get list of all child directories, in the current directory
$directories = dir $dirpath | where {$_.PsIsContainer} | where-object {$_ -notlike "*_Orphaned"}
$errorList=@() #Initialize empty collection

# iterate over the directories
foreach ($dir in $directories)
{
    # echo out what the full directory is that we’re working on now
    write-host Working on $dir.fullname using $dir.name

    # setup the inheritance and propagation as we want it
    $inheritance = [system.security.accesscontrol.InheritanceFlags]“ContainerInherit, ObjectInherit”
    $propagation = [system.security.accesscontrol.PropagationFlags]“None”
    $allowdeny=[System.Security.AccessControl.AccessControlType]::Allow

    try{
    # get the existing ACLs for the directory
    $acl =  (Get-Item $dir.fullname).GetAccessControl('Access')   #get-acl $dir.fullname # See response from ANthony Mastrean https://stackoverflow.com/questions/6622124/why-does-set-acl-on-the-drive-root-try-to-set-ownership-of-the-object

    # add our user (with the same name as the directory) to have modify perms
    $aclrule = new-object System.Security.AccessControl.FileSystemAccessRule($dir.name, “FullControl”, $inheritance, $propagation, “$allowdeny”)

    # check if given user is Valid

    $sid = $aclrule.IdentityReference.Translate([System.Security.Principal.securityidentifier])


    # add the ACL to the ACL rules
    $acl.AddAccessRule($aclrule)

    # set the acls
    set-acl -aclobject $acl -path $dir.fullname
    }
    catch
    {
    $errorList+=$dir.fullname
    }

} #endregion

#region Fix orphans
if($ProductionRun)
{
write-host Production run -ForegroundColor Yellow
    foreach($item in $errorList )
    {
        try{
        write-host Moving $item to $orphanPath
        get-item $item | Move-item -Destination $orphanPath -Force
        }
        catch
        {
        write-host "[ERROR] $(get-date)"
        $_.Exception.Message

        }

    }
}
#endregion
write-host "-- COMPLETE -- Dumping $errorList to transcript"
$errorList
Stop-Transcript
