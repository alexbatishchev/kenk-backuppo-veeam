# kenk-backuppo-veeam
Tool to make backup of vSphere's VMs by desired backup plan with free version of Veeam Backup & Replication
Searching for virtual machines in vSphere tagged with set of notes and starting Veeam Backup for it

# how to use
* plan one ore more backup plans for VMs, for example
    * daily every day at 22:00
    * weekly every friday at 22:00
    * monthly every 1st sunday at 01:00
* deploy windows server with Veeam Backup & Replication and PowerCli
* set options in settings.ps1 file (like backup storage location, VC credentials and e-mail alert adress)
* set task scheduler to run script at desired time
    * run a program %SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe
    * with arguments C:\scripts\kenk-backuppo-veeam\backuppo-veeam.ps1 -sBackupType weekly
    * with working path C:\scripts\kenk-backuppo-veeam\
* add tags to descriptions of your VMs like "{veeam1-daily}, {veeam1-monthly}, {veeam1-weekly}

