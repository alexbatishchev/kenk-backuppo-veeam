# backuppo-veeam.ps1
# wrapper for launching VeeamZIP for desired set of VMS based on tags
# Author: Alexey Batishchev
# alex@batishchev.ru
# launch it as "backuppo-veeam.ps1 -sBackupType daily" or any of your tags in VM's descriprion
##################################################################

Param(
 [string]$sBackupType 
)
. .\settings.ps1
. .\uszfunctions.ps1
log ("=============================")
wlog ("Starting " + $MyInvocation.MyCommand.Name)
wlog ("requested backup type is " + $sBackupType.ToLower())
wlog ("connecting to vc " + $VcHostName )

Add-PSSnapin VMware.VimAutomation.Core
if ($bDoPBUA) {
	Connect-VIServer -Server $VcHostName  -Protocol https -User $sVCLogin -Password $sVCPassword
}
else {
	Connect-VIServer -Server $VcHostName  -Protocol https
}	
wlog ("getting VMs")

$vms_to_find_in = Get-VM | Select-Object Name,Notes,@{n="AllHardDisksSizeGB"; e={(Get-HardDisk -VM $_ | Measure-Object -Sum CapacityGB).Sum}}
$iVMsCount = ($vms_to_find_in | measure).count
wlog ("got $iVMsCount VMs total")
wlog ("searching for tags {$veeamId-$sBackupType}")
$aVMsToProcess = @()

foreach ($this_found_vm in $vms_to_find_in) {
	$vmstr = $this_found_vm.Name
	$sSize = $this_found_vm.AllHardDisksSizeGB
	wlog ("got $vmstr with total disk size $sSize GB")
	if ($this_found_vm.Notes -eq $null) {
		wlog ("null note for this VM, skipping")
		continue
	}
	if ($this_found_vm.Notes.contains("{$veeamId-$sBackupType}")) {
		wlog ("note contains tag" + "{$veeamId-$sBackupType}, adding to process list")
		$aVMsToProcess = $aVMsToProcess + $this_found_vm
	}
	else {
		wlog ("no match in note for this VM, skipping")
	}
} 

Switch ($sSizeSortingPolicy.ToLower()) {
	"smallfirst" {
		wlog ("sorting small first")
		$aVMsToProcess = $aVMsToProcess | sort -Property AllHardDisksSizeGB
	}
	"bigfirst" {
		wlog ("sorting big first")
		$aVMsToProcess = $aVMsToProcess | sort -Property AllHardDisksSizeGB -Descending
	}
	Default {
		wlog ("not sorting")
	}
}

foreach ($this_found_vm in $aVMsToProcess) {
	$vmstr = $this_found_vm.Name
	$sSize = $this_found_vm.AllHardDisksSizeGB
	wlog ("Backuping $vmstr with total disk size $sSize GB, launching VeeamZIP.ps1")
	Invoke-Expression ".\VeeamZIP.ps1 -vmname $vmstr -sBType $sBackupType"
	wlog ("returned from VeeamZIP.ps1")
}

wlog ("now we're done with " + $MyInvocation.MyCommand.Name)

