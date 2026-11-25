# Runs once at the first logon in the VM: labs to C:\UEK188, shortcut, VMware Tools
$ErrorActionPreference = 'Continue'
New-Item -ItemType Directory C:\UEK188\Uebungen -Force | Out-Null
Start-Transcript C:\UEK188\setup.log
Copy-Item "$PSScriptRoot\UEK188\*" C:\UEK188 -Recurse -Force
Get-ChildItem C:\UEK188 -Recurse -File | ForEach-Object { $_.IsReadOnly = $false }  # files from CD are read-only

$lnk = (New-Object -ComObject WScript.Shell).CreateShortcut("$([Environment]::GetFolderPath('Desktop'))\Lab Trainer UEK 188.lnk")
$lnk.TargetPath = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
$lnk.Arguments = '-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\UEK188\Lab\Lab-Trainer.ps1"'
$lnk.IconLocation = "$env:WINDIR\System32\imageres.dll,109"
$lnk.Save()

# Show file extensions (.csv, .md, .ps1 matter in the labs)
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced HideFileExt 0

$tools = Get-PSDrive -PSProvider FileSystem | ForEach-Object { Get-Item "$($_.Root)setup64.exe", "$($_.Root)setup.exe" -ErrorAction SilentlyContinue } | Where-Object { $_.VersionInfo.CompanyName -match 'VMware|Broadcom' } | Select-Object -First 1
if ($tools) { Start-Process $tools.FullName '/S /v "/qn REBOOT=R"' -Wait } else { 'VMware Tools ISO not found' }
Stop-Transcript
shutdown /r /t 15 /c "UEK 188 lab VM is set up. Restarting..."
