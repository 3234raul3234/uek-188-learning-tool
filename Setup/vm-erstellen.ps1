# Baut Setup-ISO + VMware-VM "UEK188 Windows 11 Edu". Nochmals ausfuehren = VM neu aufsetzen (alte VM-Dateien werden ersetzt).
param([string]$WinIso = 'C:\ISO-Images\Windows\Win11_25H2_EnglishInternational_x64_v2.iso')
$ErrorActionPreference = 'Stop'
$root = 'C:\UEK188'; $vmDir = "$root\VM"; $vmx = "$vmDir\UEK188-Win11Edu.vmx"; $setupIso = "$root\Setup\UEK188-Setup.iso"
$vmw = 'C:\Program Files\VMware\VMware Workstation'
if (-not (Test-Path $WinIso)) { throw "Windows-ISO fehlt: $WinIso" }
if (Test-Path $vmx) { & "$vmw\vmrun.exe" -T ws stop $vmx hard 2>$null; Start-Sleep 3 }  # laufende VM hält die ISO fest

# Setup-ISO aus Setup\iso bauen (autounattend.xml, setup.ps1, Labs)
Remove-Item "$root\Setup\iso\UEK188" -Recurse -Force -ErrorAction SilentlyContinue
# Labs aus dem Repo (C:\UEK188\Lab), Unterlagen aus dem Obsidian-Vault
$cfg = "$root\unterlagen-pfad.txt"  # optional, lokal (nicht im Repo)
$quelle = if (Test-Path $cfg) { (Get-Content $cfg -Raw -Encoding UTF8).Trim() } else { "$root\Unterlagen" }
New-Item -ItemType Directory "$root\Setup\iso\UEK188\Lab", "$root\Setup\iso\UEK188\Unterlagen" -Force | Out-Null
Copy-Item "$root\Lab\*.ps1" "$root\Setup\iso\UEK188\Lab"
Copy-Item "$quelle\ÜK 188 Lernkarten.md", "$quelle\Hotel Vier Winde.md", "$quelle\..\..\..\99 Vorlagen\Arbeitsbericht.md" "$root\Setup\iso\UEK188\Unterlagen" -ErrorAction SilentlyContinue  # Unterlagen sind optional (nicht im Repo)
if (-not ('IsoWriter' -as [type])) {
    Add-Type -TypeDefinition @'
using System.IO; using System.Runtime.InteropServices; using System.Runtime.InteropServices.ComTypes;
public static class IsoWriter {
  public static void Save(object stream, string path) {
    var s = (IStream)stream; var buf = new byte[65536]; var read = Marshal.AllocHGlobal(4);
    try {
      using (var f = File.Create(path)) {
        while (true) { s.Read(buf, buf.Length, read); int n = Marshal.ReadInt32(read); if (n == 0) break; f.Write(buf, 0, n); }
      }
    } finally { Marshal.FreeHGlobal(read); }
  }
}
'@
}
$fsi = New-Object -ComObject IMAPI2FS.MsftFileSystemImage
$fsi.FileSystemsToCreate = 7   # ISO9660 + Joliet + UDF
$fsi.VolumeName = 'UEK188'
$fsi.Root.AddTree("$root\Setup\iso", $false)
[IsoWriter]::Save($fsi.CreateResultImage().ImageStream, $setupIso)
"Setup-ISO: $setupIso"

# VM-Dateien
Remove-Item $vmDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory $vmDir | Out-Null
& "$vmw\vmware-vdiskmanager.exe" -c -s 100GB -a lsilogic -t 0 "$vmDir\UEK188-Win11Edu.vmdk" | Out-Null
if ($LASTEXITCODE) { throw 'Virtuelle Festplatte konnte nicht erstellt werden' }

$cfg = @"
.encoding = "UTF-8"
config.version = "8"
virtualHW.version = "21"
displayName = "UEK188 Windows 11 Edu"
guestOS = "windows9-64"
firmware = "bios"
memsize = "8192"
numvcpus = "4"
cpuid.coresPerSocket = "4"
pciBridge0.present = "TRUE"
pciBridge4.present = "TRUE"
pciBridge4.virtualDev = "pcieRootPort"
pciBridge4.functions = "8"
pciBridge5.present = "TRUE"
pciBridge5.virtualDev = "pcieRootPort"
pciBridge5.functions = "8"
pciBridge6.present = "TRUE"
pciBridge6.virtualDev = "pcieRootPort"
pciBridge6.functions = "8"
pciBridge7.present = "TRUE"
pciBridge7.virtualDev = "pcieRootPort"
pciBridge7.functions = "8"
vmci0.present = "TRUE"
hpet0.present = "TRUE"
nvme0.present = "TRUE"
nvme0:0.present = "TRUE"
nvme0:0.fileName = "UEK188-Win11Edu.vmdk"
sata0.present = "TRUE"
sata0:0.present = "TRUE"
sata0:0.deviceType = "cdrom-image"
sata0:0.fileName = "$WinIso"
sata0:1.present = "TRUE"
sata0:1.deviceType = "cdrom-image"
sata0:1.fileName = "$setupIso"
sata0:2.present = "TRUE"
sata0:2.deviceType = "cdrom-image"
sata0:2.fileName = "$vmw\windows.iso"
ethernet0.present = "TRUE"
ethernet0.connectionType = "nat"
ethernet0.virtualDev = "e1000e"
ethernet0.addressType = "generated"
usb.present = "TRUE"
ehci.present = "TRUE"
usb_xhci.present = "TRUE"
sound.present = "TRUE"
sound.virtualDev = "hdaudio"
mks.enable3d = "TRUE"
svga.graphicsMemoryKB = "4194304"
tools.syncTime = "TRUE"
"@
[IO.File]::WriteAllText($vmx, $cfg, (New-Object Text.UTF8Encoding $false))  # VMware mag kein BOM
"VM: $vmx"
