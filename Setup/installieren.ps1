# One-click installation (called by START.cmd)
Add-Type -AssemblyName System.Windows.Forms
$ErrorActionPreference = 'Stop'
$target = 'C:\UEK188'
$source = Split-Path $PSScriptRoot
$vmw = (Get-ItemProperty 'HKLM:\SOFTWARE\VMware, Inc.\VMware Workstation', 'HKLM:\SOFTWARE\WOW6432Node\VMware, Inc.\VMware Workstation' -ErrorAction SilentlyContinue | Select-Object -First 1).InstallPath
$vmw = $(if ($vmw) { $vmw.TrimEnd('\') } else { 'C:\Program Files\VMware\VMware Workstation' })
function Info($t) { Write-Host "`n>> $t" -ForegroundColor Cyan }

# 1. Is VMware installed?
if (-not (Test-Path "$vmw\vmrun.exe")) {
    Write-Host 'VMware Workstation is missing. Please install it first (free), then run START.cmd again.' -ForegroundColor Red
    Start-Process 'https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion'
    exit 1
}

# 2. Is there already a VM? Never overwrite without asking (ask first, change things afterwards)
if (Test-Path "$target\VM\UEK188-Win11Edu.vmx") {
    $a = [Windows.Forms.MessageBox]::Show("There is already a UEK188 VM.`nRebuild it? The old VM will be DELETED.", 'UEK 188', 'YesNo', 'Warning')
    if ($a -ne 'Yes') { Write-Host 'Cancelled, nothing changed.'; exit 0 }
}

# 3. Choose the Windows 11 ISO
Info 'Choose the Windows 11 ISO file ...'
$dlg = New-Object Windows.Forms.OpenFileDialog -Property @{ Title = 'Choose the Windows 11 ISO'; Filter = 'ISO file (*.iso)|*.iso'; InitialDirectory = "$env:USERPROFILE\Downloads" }
# TopMost owner: otherwise the dialog opens behind the console
if ($dlg.ShowDialog((New-Object Windows.Forms.Form -Property @{ TopMost = $true })) -ne 'OK') { Write-Host 'No ISO chosen, cancelled, nothing changed.' -ForegroundColor Red; exit 1 }

# 4. Copy files to C:\UEK188 (the setup expects this folder)
if ($source -ne $target) {
    Info "Copying files to $target ..."
    New-Item -ItemType Directory $target -Force | Out-Null
    Remove-Item "$target\Setup\iso\UEK188" -Recurse -Force -ErrorAction SilentlyContinue  # leftover of an old version
    foreach ($d in 'Lab', 'Setup', 'Unterlagen', 'README.md', 'CHANGELOG.md', 'LICENSE', 'START.cmd') { if (Test-Path "$source\$d") { Copy-Item "$source\$d" $target -Recurse -Force } }
}

# 5. Build and start the VM
Info 'Building the VM ...'
& "$target\Setup\vm-erstellen.ps1" -WinIso $dlg.FileName
# Shortcut on the computer for the VM buttons (update / reset VM), created before the start so it exists either way
$lnk = (New-Object -ComObject WScript.Shell).CreateShortcut("$([Environment]::GetFolderPath('Desktop'))\Lab Trainer UEK 188 (PC).lnk")
$lnk.TargetPath = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
$lnk.Arguments = "-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$target\Lab\Lab-Trainer.ps1`""
$lnk.IconLocation = "$env:WINDIR\System32\imageres.dll,109"; $lnk.Save()

Info 'Starting the VM ...'
& "$vmw\vmrun.exe" -T ws start "$target\VM\UEK188-Win11Edu.vmx" gui
if ($LASTEXITCODE) {
    Write-Host "`nThe VM is built but could not be started. In VMware open: File > Open > $target\VM\UEK188-Win11Edu.vmx and click 'Power on'." -ForegroundColor Yellow
    exit 1
}

Write-Host "`nDONE! Windows now installs itself in the VM (about 30 minutes)." -ForegroundColor Green
Write-Host 'Do not click anything until the desktop with "Lab Trainer UEK 188" appears.' -ForegroundColor Green
