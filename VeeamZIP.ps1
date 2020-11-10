# Author: Vladimir Eremin
# Created Date: 3/24/2015
# http://forums.veeam.com/member31097.html
##################################################################
# KENK-ed version 2020
##################################################################
# User Defined Variables
##################################################################
Param(
 [string]$VmName, 
 [string]$sBType 
)

. .\settings.ps1
. .\uszfunctions.ps1

wlog ("#########################")
wlog ("starting VeeamZip.ps1")
wlog ("requested backup type is " + $sBType.ToLower())

# Retention settings (Optional; By default, VeeamZIP files are not removed and kept in the specified location for an indefinite period of time. 
# Possible values: Never , Tonight, TomorrowNight, In3days, In1Week, In2Weeks, In1Month)
$Retention = "In2Weeks"

Switch ($sBType.ToLower()) {
	"daily" {
		$Directory = $DailyPath 
        $Retention = "In1Week"
	}
	"weekly" {
		$Directory = $WeeklyPath 
        $Retention = "In2Weeks"
	}
	"monthly" {
		$Directory = $MonthlyPath 
        $Retention = "In1Month"
	}
	Default {"BType Out of range"; exit}
}
wlog ("Retention policy set as $Retention ")
wlog ("will try to make backup to $Directory")


# Names of VMs to backup separated by semicolon (Mandatory)
if(-not($VmName)) { Throw "You must supply a value for -VmName" }
$VMNames = $VmName
wlog ("VM to backup is $VMNames")

# Directory that VM backups should go to (Mandatory; for instance, C:\Backup)
# $Directory = "F:\VeeamBackups\Weekly"
# Desired compression level (Optional; Possible values: 0 - None, 4 - Dedupe-friendly, 5 - Optimal, 6 - High, 9 - Extreme) 
$CompressionLevel = "5"
# Quiesce VM when taking snapshot (Optional; VMware Tools are required; Possible values: $True/$False)
$EnableQuiescence = $True
# Protect resulting backup with encryption key (Optional; $True/$False)
$EnableEncryption = $False
# Encryption Key (Optional; path to a secure string)
$EncryptionKey = ""


##################################################################
# Email formatting 
##################################################################

$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"

##################################################################
# End User Defined Variables
##################################################################

wlog ("Starting working on")

#################### DO NOT MODIFY PAST THIS LINE ################
Asnp VeeamPSSnapin

wlog ("Get-VBRServer $VcHostName")

$Server = Get-VBRServer -name $VcHostName
$ErrorNotification = $false
$MesssagyBody = @()
#$aLog = @()
foreach ($VMName in $VMNames)
{
	wlog ("Find-VBRViEntity -Name $VMName")
	$VM = Find-VBRViEntity -Name $VMName -Server $Server
	If ($EnableEncryption)
	{
		$EncryptionKey = Add-VBREncryptionKey -Password (cat $EncryptionKey | ConvertTo-SecureString)
		$ZIPSession = Start-VBRZip -Entity $VM -Folder $Directory -Compression $CompressionLevel -DisableQuiesce:(!$EnableQuiescence) -AutoDelete $Retention -EncryptionKey $EncryptionKey
	}
	Else 
	{
		wlog ("Start-VBRZip")
		$ZIPSession = Start-VBRZip -Entity $VM -Folder $Directory -Compression $CompressionLevel -DisableQuiesce:(!$EnableQuiescence) -AutoDelete $Retention 
	}

	wlog ("now done with Start-VBRZip")

	#preparing reports
	$TaskSessions = $ZIPSession.GetTaskSessions().logger.getlog().updatedrecords
	$TaskSessions | sort OrdinalId | Export-Csv -path ("$sVeeamZipLogsPath\" + $ZIPSession.LogsSubFolder + $sBType) –NoTypeInformation -encoding unicode -Delimiter ";"
	
	$FailedSessions = $TaskSessions | where {$_.status -eq "EWarning" -or $_.Status -eq "EFailed"}

	if ($FailedSessions -ne $Null)	{
		$MesssagyBody = $MesssagyBody + ($ZIPSession | Select-Object @{n="Name";e={($_.name).Substring(0, $_.name.LastIndexOf("("))}} ,@{n="Start Time";e={$_.CreationTime}},@{n="End Time";e={$_.EndTime}},Result,@{n="Details";e={$FailedSessions.Title}})
		$ZIPSession | Add-Member -NotePropertyName Details -NotePropertyValue ($FailedSessions.Title)
		$ErrorNotification = $true
		wlog ("there will be ErrorNotification because of FailedSessions ")	
	}
	Else {
		$MesssagyBody = $MesssagyBody + ($ZIPSession | Select-Object @{n="Name";e={($_.name).Substring(0, $_.name.LastIndexOf("("))}} ,@{n="Start Time";e={$_.CreationTime}},@{n="End Time";e={$_.EndTime}},Result,@{n="Details";e={($TaskSessions | sort OrdinalId -Descending | select -first 1).Title}})
		$ZIPSession | Add-Member -NotePropertyName Details -NotePropertyValue (($TaskSessions | sort OrdinalId -Descending | select -first 1).Title)
	}
	

	#preparing logs	to export
	$thisLog = "" |Select  VMName,Name,CreationTime,EndTime,Result,Retention
	$thisLog.VMName 		= $VMName
	$thisLog.Name			= $ZIPSession.Name
	$thisLog.CreationTime	= $ZIPSession.CreationTime
	$thisLog.EndTime		= $ZIPSession.EndTime
	$thisLog.Result			= $ZIPSession.Result
	$thisLog.Retention		= $Retention

	if ($thisLog.Result -ne "Success") {
		$ErrorNotification = $true
		wlog ("there will be ErrorNotification because of thisLog.Result")	
	}	

	$thisLog  | Export-Csv -path "$sVeeamZipLogsPath\temp.csv" –NoTypeInformation -encoding unicode -Delimiter ";"
	Get-Content "$sVeeamZipLogsPath\temp.csv" | select -skip 1 | Out-File "$sVeeamZipLogsPath\log.csv" -Append -Encoding Unicode 
}
If ($ErrorNotification) {
	wlog ("preparing notification")	
	$Message = New-Object System.Net.Mail.MailMessage $EmailFrom, $EmailTo
	$Message.Subject = $EmailSubject
	$Message.IsBodyHTML = $True
	$message.Body = $MesssagyBody | ConvertTo-Html -head $style | Out-String
	$SMTP = New-Object Net.Mail.SmtpClient($SMTPServer)
	if ($EnableNotification) {
		wlog ("sending notification")	
		$SMTP.Send($Message)
		wlog ("notification sent")	
	}
}
wlog ("We're done with VeeamZip.ps1")	