# Using Citrix cloud it can be helpful to find out which domain controller is used to manage the AD account for an object
Get-AcctADAccount| foreach-object {
  $dcHint=$_.DomainControllerHint
  if($dcHint -ne $null) { $dcHint=$dcHint.Split('_')[1] }
  new-object -TypeName psobject -Property @{
    ADAccountName = $_.ADAccountName
      Decoded_DomainControllerHint=  [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($dcHint))
    }  
}
