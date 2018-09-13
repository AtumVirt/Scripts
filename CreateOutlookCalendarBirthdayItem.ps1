#Use case:  User had a personal calendar that they shared.  They wanted to add birthdays to it with the age the person would be in the subject/body of each reminder, rather than a generic one.
#Inputs:  CSV with the following header/columns:  EmployeeName,EmployeeBirthday,Repeat,CalendarName
#Add-CalendarMeeting modified from https://gallery.technet.microsoft.com/office/Create-Meeting-is-MS-f117778d
 param(
     [Parameter(Mandatory=$true)]
     $contentPath
     )

#region Functions
Function GetNextBirthday
{
    param(
     [Parameter( 
            Mandatory = $True, 
            HelpMessage="The string for the birthday of the person")] 
        $Birthday
    )
        $DateTimeBirthday=get-date $Birthday
        $NextYear=(Get-Date).AddYears(1).Year
        $NextBirthday = Get-date "$($DateTimeBirthday.Month)/$($DateTimeBirthday.Day)/$NextYear"
        return $NextBirthday
}
function Add-CalendarMeeting { 
 
param ( 
 
[cmdletBinding()] 
 
    # Subject Parameter     
    [Parameter( 
        Mandatory = $True, 
        HelpMessage="Please provide a subject of your calendar invite.")] 
    [Alias('sub')] 
    [string] $Subject, 
 
    #Body parameter 
    [Parameter( 
        Mandatory = $True, 
        HelpMessage="Please provide a description of your calendar invite.")] 
    [Alias('bod')] 
    [string] $Body, 
 
    #Location Parameter 
    [Parameter( 
        Mandatory = $True, 
        HelpMessage="Please provide the location of your meeting.")] 
 
    [Alias('loc')] 
    [string] $Location, 
     [Parameter( 
        Mandatory = $True, 
        HelpMessage="Please provide name of the shared calendar.")] 
     [string] $CalendarName,

    # Importance Parameter 
    [int] $Importance = 1, 
 
    # All Day event Parameter 
    [bool] $AllDayEvent = $false, 
 
    # Set Reminder Parameter 
    [bool] $EnableReminder = $True, 
 
    # Busy Status Parameter 
    [string] $BusyStatus = 2, 
 
    # Metting Start Time Parameter 
    [datetime] $MeetingStart =(Get-Date), 
 
    # Meeting time duration parameter 
    [int] $MeetingDuration = 30,  
 
    # Meeting time End parameter 
        #[datetime] $MeetingEnd = (Get-Date).AddMinutes(+30), 
 
    # by Default Reminder Duration 
    [int] $Reminder = 15 

 
 
 
) 
 
BEGIN {  
         
        Write-Verbose " Creating Outlook as an Object" 
         
        # Create a new appointments using Powershell 
        $outlookApplication = New-Object -ComObject 'Outlook.Application' 
        # Creating a instatance of Calenders 
        #$newCalenderItem = $outlookApplication.CreateItem('olAppointmentItem') 
        
        $outlookNameSpace= $outlookApplication.GetNamespace('MAPI')
        $calendar=$outlookNameSpace.GetDefaultFolder(9).folders | where-object {$_.Name -eq $item.CalendarName}
        $newCalenderItem=$calendar.Items.Add()
 
      } 
 
 
PROCESS {  
         
         Write-Verbose "Creating Calender Invite" 
     
         $newCalenderItem.AllDayEvent = $AllDayEvent 
         $newCalenderItem.Subject = $Subject 
         $newCalenderItem.Body = $Body 
         $newCalenderItem.Location  = $Location 
         $newCalenderItem.ReminderSet = $EnableReminder 
         $newCalenderItem.Importance = $importance 
         $newCalenderItem.Start = $MeetingStart 
 
         if ( ! ($AllDayEvent)) { 
 
         $newCalenderItem.Duration = $MeetingDuration 
          
         } 

         $newCalenderItem.ReminderMinutesBeforeStart = $Reminder 
         # 2 is busy, 3 is ou to office 
         $newCalenderItem.BusyStatus = $BusyStatus 
              
    } 
 
END { 
     
        Write-Verbose "Saving Calender Item" 
        
        
        
        $newCalenderItem.Save() 
 
       } 
 
    } 
#endregion

$items=import-csv $contentPath

foreach($item in $items)
{
    $nextBirthday=GetNextBirthday $item.EmployeeBirthday
    #write-host "foreach item"
    if($item.repeat -eq "TRUE")
    {
        for($i=0; $i -lt 10; $i++)
        {
            $nextBirthday= (GetNextBirthday $nextBirthday).AddYears($i)
            $dateDiff=(get-date $nextBirthday) - (get-date $item.EmployeeBirthday)
            [int]$years=$dateDiff.days/365.25
            $subject="Birthday: $($item.EmployeeName) is turning $years years old!"
            $body="$($item.EmployeeName) is turning $years years old!"
            $location="Office"
            Add-CalendarMeeting -Subject $subject -body $body -AllDayEvent $true -MeetingStart $nextBirthday -Location $location -CalendarName $item.CalendarName

        }
    }
    else
    {
            $nextBirthday= (GetNextBirthday $item.EmployeeBirthday)
            $dateDiff=(get-date $nextBirthday) - (get-date $item.EmployeeBirthday)
            [int]$years=$dateDiff.days/365.25
            $subject="Birthday: $($item.EmployeeName) is turning $years years old!"
            $body="$($item.EmployeeName) is turning $years years old!"

            $location="Office"
            Add-CalendarMeeting -Subject $subject -body $body -AllDayEvent $true -MeetingStart $nextBirthday -Location $location  -CalendarName $item.CalendarName

    }

}

