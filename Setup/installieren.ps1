# Ein-Klick-Installation (wird von START.cmd aufgerufen)
Add-Type -AssemblyName System.Windows.Forms
$ErrorActionPreference = 'Stop'
$ziel = 'C:\UEK188'
$quelle = Split-Path $PSScriptRoot
$vmw = (Get-ItemProperty 'HKLM:\SOFTWARE\VMware, Inc.\VMware Workstation', 'HKLM:\SOFTWARE\WOW6432Node\VMware, Inc.\VMware Workstation' -ErrorAction SilentlyContinue | Select-Object -First 1).InstallPath
$vmw = $(if ($vmw) { $vmw.TrimEnd('\') } else { 'C:\Program Files\VMware\VMware Workstation' })
function Info($t) { Write-Host "`n>> $t" -ForegroundColor Cyan }

# 1. VMware vorhanden?
if (-not (Test-Path "$vmw\vmrun.exe")) {
    Write-Host 'VMware Workstation fehlt. Bitte zuerst installieren (gratis), dann START.cmd nochmals starten.' -ForegroundColor Red
    Start-Process 'https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion'
    exit 1
}

# 2. Dateien nach C:\UEK188 (das Setup erwartet diesen Ordner)
if ($quelle -ne $ziel) {
    Info "Kopiere Dateien nach $ziel ..."
    New-Item -ItemType Directory $ziel -Force | Out-Null
    foreach ($d in 'Lab', 'Setup', 'Unterlagen', 'README.md', 'CHANGELOG.md', 'LICENSE', 'START.cmd') { if (Test-Path "$quelle\$d") { Copy-Item "$quelle\$d" $ziel -Recurse -Force } }
}

# 3. Schon eine VM da? Nicht ungefragt ueberschreiben
if (Test-Path "$ziel\VM\UEK188-Win11Edu.vmx") {
    $a = [Windows.Forms.MessageBox]::Show("Es gibt schon eine UEK188-VM.`nNeu bauen? Die alte VM wird dabei GELOESCHT.", 'UeK 188', 'YesNo', 'Warning')
    if ($a -ne 'Yes') { Write-Host 'Abgebrochen, nichts geaendert.'; exit 0 }
}

# 4. Windows-11-ISO waehlen
Info 'Waehle die Windows-11-ISO-Datei aus ...'
$dlg = New-Object Windows.Forms.OpenFileDialog -Property @{ Title = 'Windows-11-ISO auswaehlen'; Filter = 'ISO-Datei (*.iso)|*.iso'; InitialDirectory = "$env:USERPROFILE\Downloads" }
if ($dlg.ShowDialog() -ne 'OK') { Write-Host 'Keine ISO gewaehlt, abgebrochen.' -ForegroundColor Red; exit 1 }

# 5. VM bauen und starten
Info 'Baue die VM ...'
& "$ziel\Setup\vm-erstellen.ps1" -WinIso $dlg.FileName
Info 'Starte die VM ...'
& "$vmw\vmrun.exe" -T ws start "$ziel\VM\UEK188-Win11Edu.vmx" gui
if ($LASTEXITCODE) {
    Write-Host "`nDie VM ist gebaut, liess sich aber nicht starten. Oeffne in VMware: File > Open > $ziel\VM\UEK188-Win11Edu.vmx und klick auf 'Power on'." -ForegroundColor Yellow
    exit 1
}

Write-Host "`nFERTIG! Windows installiert sich jetzt in der VM von selbst (ca. 30 Minuten)." -ForegroundColor Green
Write-Host 'Nichts anklicken, bis der Desktop mit "Lab-Trainer UeK 188" erscheint.' -ForegroundColor Green
