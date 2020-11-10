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
$veeamId = "veeam2"


###########################################
# set it for your backup server's paths 
$DailyPath 		= "D:\VeeamBackups\Daily"
$WeeklyPath 	= "F:\VeeamBackups\Weekly"
$MonthlyPath 	= "H:\VeeamBackups\Monthly"
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
