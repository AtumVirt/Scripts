$outputPath= "C:\temp\BrokerAppOutput.csv" #Change this as you desire

#This script assumes you are either local on a delivery controller or you're using The Citrix cloud remote sdk.  If you are using Cloud, uncomment the next line
#Get-XDAuthentication
Add-PSSnapin Citrix*


$dgs=get-brokerdesktopgroup
$ba=get-brokerapplication
$ba| select @{
                Name="Application Name"
                Expression= {$_.PublishedName }
            },

            @{
                Name="Limit Visibility to User"
                Expression= { foreach($u in $_.associatedUserNames) 
                    {$u}
                }
            },

            @{
                Name='DeliveryGroup'
                Expression= {
                    
                    foreach ($obj in $_){
                        # Added a [0] to the end of the property below because the returning object is an int32 ARRAY
                        # which DOESN'T COMPARE proper to a non-array ofc. 
                        $result = $dgs | Where-Object {$_.uid -eq $obj.AssociatedDesktopGroupUIDs[0]}
                        $result.publishedName + '; Priority ' + $obj.AssociatedDesktopGroupPriorities
                    } -join ""
                } 
            } | Export-CSV $outputPath -NoTypeInformation
