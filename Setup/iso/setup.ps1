# Laeuft einmal beim ersten Login in der VM: Labs nach C:\UEK188, Verknuepfung, VMware Tools
$ErrorActionPreference = 'Continue'
New-Item -ItemType Directory C:\UEK188\Uebungen -Force | Out-Null
Start-Transcript C:\UEK188\setup.log
Copy-Item "$PSScriptRoot\UEK188\*" C:\UEK188 -Recurse -Force
Get-ChildItem C:\UEK188 -Recurse -File | ForEach-Object { $_.IsReadOnly = $false }  # Dateien von CD sind schreibgeschuetzt

$lnk = (New-Object -ComObject WScript.Shell).CreateShortcut("$([Environment]::GetFolderPath('Desktop'))\Lab-Trainer UeK 188.lnk")
$lnk.TargetPath = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
$lnk.Arguments = '-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\UEK188\Lab\Lab-Trainer.ps1"'
$lnk.IconLocation = "$env:WINDIR\System32\imageres.dll,109"
$lnk.Save()

# Dateiendungen anzeigen (.csv, .md, .ps1 sind in den Labs wichtig)
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced HideFileExt 0

$tools = Get-PSDrive -PSProvider FileSystem | ForEach-Object { Get-Item "$($_.Root)setup64.exe", "$($_.Root)setup.exe" -ErrorAction SilentlyContinue } | Where-Object { $_.VersionInfo.CompanyName -match 'VMware|Broadcom' } | Select-Object -First 1
if ($tools) { Start-Process $tools.FullName '/S /v "/qn REBOOT=R"' -Wait } else { 'VMware Tools ISO nicht gefunden' }
Stop-Transcript
shutdown /r /t 15 /c "UeK 188 Lab-VM ist fertig eingerichtet. Neustart..."
