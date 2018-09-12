


# Adding Citrix Snapins
Add-PSSnapin Citrix*
$path="AppsForImport.xml"
  #Importing Application Data
  $apps = Import-Clixml $path
  foreach ($app in $apps[0])
   {
       #Resetting failure detection
        $failed = $false
       #Publishing Application
        Write-Host "Publishing APPLICATON:" $app.PublishedName
        
        if ($app.CommandLineArguments.Length -lt 2) {$app.CommandLineArguments = " "}
        
        Try{
          $Results = @()
            #Prep for Application Import - Removing Null values
            #   * Not just some null value, any null values seems to crash this processes.
            #   * Application folders screw this field up, had to use PublishedName for -Name property.
          
          $group=get-brokerdesktopgroup -name "DummyDeliveryGroup" -ErrorAction SilentlyContinue
            
          if(!($group)) {
              New-BrokerDesktopGroup -DeliveryType AppsOnly -DesktopKind Shared -MinimumFunctionalLevel L7_9 -Name "DummyDeliveryGroup" 
            }
          
            $MakeApp = 'New-BrokerApplication -ApplicationType HostedOnDesktop -DesktopGroup "DummyDeliveryGroup"'
            if($app.CommandLineExecutable -ne $null){$MakeApp += ' -CommandLineExecutable $app.CommandLineExecutable'}
            if($app.Description -ne $null){$MakeApp += ' -Description $app.Description'}
            if($app.ClientFolder -ne $null){$MakeApp += ' -ClientFolder $app.ClientFolder'}
            if($app.CommandLineArguments -ne $null){$MakeApp += ' -CommandLineArguments $app.CommandLineArguments'}
            if($app.PublishedName -ne $null){$MakeApp += ' -Name $app.PublishedName'} 
            if($app.UserFilterEnabled -ne $null){$MakeApp += ' -UserFilterEnabled $app.UserFilterEnabled'}
            if($app.Enabled -ne $null){$MakeApp += ' -Enabled $app.Enabled'}
            if($dg -ne $null){$MakeApp += ' -DesktopGroup $dg'}
            if($app.WorkingDirectory -ne $null){$MakeApp += ' -WorkingDirectory $app.WorkingDirectory'}
            if($app.PublishedName -ne $null){$MakeApp += ' -PublishedName $app.PublishedName'}
            if($app.AdminFolderName -ne $null){$MakeApp += ' -AdminFolder $app.AdminFolderName'}
            #Creating Application
            $Results = Invoke-Expression $MakeApp | out-string -Stream
            $Results = $Results[16] -replace '^[^:]+:', ''
            $Results= $Results.Trim()
          #write-host "Browser Name Before:"$Results 
        }
        catch
        {
            write-host  -ForegroundColor Red $_.Exception.Message
            write-host  -ForegroundColor Red $_.Exception.ItemName
            write-host  -ForegroundColor Red "Error on "  $app.BrowserName
            write-host  -ForegroundColor Red "Error on "  $app.CommandLineExecutable
            write-host  -ForegroundColor Red "Error on "  $app.Description
            write-host  -ForegroundColor Red "Error on "  $app.CommandLineArguments
            write-host  -ForegroundColor Red "Error on "  $app.Enabled
            write-host  -ForegroundColor Red "Error on "  $app.Name
            write-host  -ForegroundColor Red "Error on "  $app.UserFilterEnabled
           $failed = $true
        }
       #Publishing Application
        Write-Host -ForegroundColor Green "Application Succesfully Published:" $app.PublishedName
        
        if ($app.CommandLineArguments.Length -lt 2) {$app.CommandLineArguments = " "}
        if($failed -ne $true)
        {
            #Importing Icon
            $IconUid = New-BrokerIcon -EncodedIconData $app.EncodedIconData
            
            #Setting applications icon
                  $application = Get-BrokerApplication -BrowserName "$Results" 
            # write-host "Broker Name:"""$Results""
            Set-BrokerApplication -InputObject $application -IconUid $IconUid.Uid
            write-host -ForegroundColor Green "Icon changed for application:" $app.PublishedName
 
            # Adding Users and Groups to application associations
            If($app.AssociatedUserNames -ne $null)
            {
                Try
                {
                    $users = $app.AssociatedUserNames
 
                    foreach($user in $users)
                    {
                        
                        $fullappath = $app.AdminFolderName + $app.PublishedName
                        #write-host "Full Path: $fullappath"
                        #Add-BrokerUser -Name "$user" -Application "$fullappath" 
                        write-host "[Debug] Would execute Add-BrokerUser -Name "$user" -Application "$fullappath" " -ForegroundColor Yellow
                    }
                    
                }
                catch
                {
                    write-host  -ForegroundColor Red $_.Exception.Message
                    write-host  -ForegroundColor Red $_.Exception.ItemName
                    write-host  -ForegroundColor Red "Error on User  "  $user "for application:" $app.PublishedName
                }
                write-host -ForegroundColor Green "Users Succesfully added for application(Limit Visibility Section):" $app.PublishedName
             }
         }
   }
