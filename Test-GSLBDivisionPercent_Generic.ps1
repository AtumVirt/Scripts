<#
.SYNOPSIS
Queries DNS the specified number of times and calculates the percentage of results returned to estimate GSLB DNS Distribution.

.DESCRIPTION
Queries DNS the specified number of times and calculates the percentage of results returned to estimate GSLB DNS Distribution.

.PARAMETER dnsServer 
The IP address of the DNS server to query.  This should be the root zone holder in the case of GSLB, not the delegated zone

.PARAMETER expectedResult1
The IP address of one side of the GSLB 

.PARAMETER expectedResult2
The IP address of the other side of the GSLB 

.PARAMETER numberOfQueries
The number of times to query DNS to calculate distribution.

.EXAMPLE

.\Test-GSLBDivisonPercent.ps1 -dnsServer 10.0.0.3 -expectedResult1 10.0.1.5 -expectedResult2 10.0.2.5 -dnsName Citrix.atumvirt.com

#>
param(
[Parameter(Mandatory=$true)]
[string]$dnsServer,
[Parameter(Mandatory=$true)]
[string]$expectedResult1,
[Parameter(Mandatory=$true)]
[string]$expectedResult2,
[Parameter(Mandatory=$true)]
[string]$dnsName,
$numberOfQueries=5000
)

function Find-Percent{
  param(
    $objectArray, #array with the data
    $ipPair #IP's to check, like -ipPair "192.168.1.1","192.168.1.2"
  )
  
  [array]$counts = @() # Object to store data in

  foreach ($ip in $ipPair){ # Check each IP in the pair
    $thisIPCount = ($objectArray | Where-Object {$_.ipaddress -match $ip}).count # Count appearance of this unique IP
    $thisItem = New-Object psobject -Property @{
      IP = $ip
      Count = $thisIPCount
    }
    #$thisItem = @{$ip = $thisIPcount} # Put data in a hashtable
    $counts += $thisItem
  }
  $totalCount = $counts[0].count + $counts[1].count #Sum for Total Count
  
  foreach ($ip in $counts){ # Do percent math
    $thisPercent = ($ip.count/$totalCount)*100  #think this is correct
    Write-Host -fore yellow "$($ip.ip) is $($thisPercent)% of the returned results."
  }
}

$results=@()

for($i=0;$i -lt $numberOfQueries;$i++) { $results+=Resolve-DnsName $dnsName -server  $dnsServer } #Resolve it n times


Find-Percent -objectArray $results -ipPair $expectedResult1,$expectedResult2
