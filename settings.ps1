#####################################################
# settings.ps1
# edit this variables to customize main script
#####################################################

##################################################################
# PATHS and adresses
##################################################################

# Log path related settings
$sLogFileNameTemplate = "yyyy-MM-dd" #"yyyy-MM-dd-HH-mm-ss"
$sLogFilePathTemplate = "yyyy-MM"


$VcHostName = "10.11.68.100"

$bDoPBUA = $true # set to false if you're running script from authenticated to VC user (and to not to store password in plain text \_()_/
$sVCLogin = "administrator@vsphere.local"
$sVCPassword = "password"

# this will be first part of searching tag like {veeam2-daily}
$veeamId = "veeam1"


###########################################
# set it for your backup server's paths 
$DailyPath 		= "D:\VeeamBackups\Daily"
$WeeklyPath 	= "F:\VeeamBackups\Weekly"
$MonthlyPath 	= "H:\VeeamBackups\Monthly"
###########################################
# Retention Policies and compression (https://helpcenter.veeam.com/docs/backup/powershell/start-vbrzip.html?ver=100)
# Desired compression level (Optional; Possible values: 0 - None, 4 - Dedupe-friendly, 5 - Optimal, 6 - High, 9 - Extreme) 
$iDefaultCompressionLevel = 6
# Quiesce VM when taking snapshot (Optional; VMware Tools are required; Possible values: $True/$False)
$bDefaultEnableQuiescencePolicy = $true

$sDailyDefaultRetention = "In1Week"
$sWeeklyDefaultRetention = "In2Weeks"
$sMonthlyDefaultRetention = "In1Month"

$sSizeSortingPolicy = "SmallFirst" # "BigFirst", "None"
#################################################
New-Item -ItemType Directory -Force -Path $DailyPath 
New-Item -ItemType Directory -Force -Path $WeeklyPath 
New-Item -ItemType Directory -Force -Path $MonthlyPath 

$sCurDate = (Get-Date)
$Hostname = ($env:computername).ToLower()
$sVeeamZipLogsPath = $PSScriptRoot + "\logs\" + $sCurDate.ToString($sLogFilePathTemplate)
New-Item -ItemType Directory -Force -Path $sVeeamZipLogsPath


##################################################################
# Notification Settings
##################################################################

# Enable notification (Optional)
$EnableNotification = $true # $false 
# Email SMTP server
$SMTPServer = "smtpserver.domain.com"
# Email FROM
$EmailFrom = $Hostname + "@domain.com" 
# Email TO
$EmailTo = "monitoring@domain.com"
# Email subject
$EmailSubject = ("Что-то пошло не так при резервном копировании VEEAM $sBType ВМ $VmName на бэкапере $Hostname")
