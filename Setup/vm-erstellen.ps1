# Builds the setup ISO + VMware VM "UEK188 Windows 11 Edu" (normally via START.cmd).
# Directly:  vm-erstellen.ps1 -WinIso "C:\path\to\Windows11.iso"   (old VM files are replaced)
param([string]$WinIso)
if (-not $WinIso) { throw 'Please use START.cmd or give the ISO: vm-erstellen.ps1 -WinIso "C:\path\to\Windows11.iso"' }
$ErrorActionPreference = 'Stop'
$root = 'C:\UEK188'; $vmDir = "$root\VM"; $vmx = "$vmDir\UEK188-Win11Edu.vmx"; $setupIso = "$root\Setup\UEK188-Setup.iso"
$vmw = (Get-ItemProperty 'HKLM:\SOFTWARE\VMware, Inc.\VMware Workstation', 'HKLM:\SOFTWARE\WOW6432Node\VMware, Inc.\VMware Workstation' -ErrorAction SilentlyContinue | Select-Object -First 1).InstallPath
if (-not $vmw) { $vmw = 'C:\Program Files\VMware\VMware Workstation' }
$vmw = $vmw.TrimEnd('\')
if (-not (Test-Path "$vmw\vmrun.exe")) { throw "VMware Workstation not found ($vmw)" }
if (-not (Test-Path $WinIso)) { throw "Windows ISO missing: $WinIso" }
if (Test-Path $vmx) { try { & "$vmw\vmrun.exe" -T ws stop $vmx hard 2>&1 | Out-Null } catch {}; Start-Sleep 3 }  # a running VM locks the ISO

# Read language and Education index from the ISO, so that every language and every multi-edition ISO works
$info = & "$PSScriptRoot\iso-info.ps1" -Iso $WinIso
"ISO: language $($info.Language), Windows 11 Education = index $($info.Index)"

# Setup ISO from a build folder: autounattend.xml (adjusted), setup.ps1, labs, documents
$stage = "$root\Setup\iso-build"
Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory "$stage\UEK188\Lab" -Force | Out-Null
Copy-Item "$root\Setup\iso\autounattend.xml", "$root\Setup\iso\setup.ps1" $stage  # only these two, no old leftovers
$xml = [IO.File]::ReadAllText("$stage\autounattend.xml") -replace '(<Key>/IMAGE/INDEX</Key><Value>)\d+', "`${1}$($info.Index)" -replace '<UILanguage>[^<]+</UILanguage>', "<UILanguage>$($info.Language)</UILanguage>"
[IO.File]::WriteAllText("$stage\autounattend.xml", $xml, (New-Object Text.UTF8Encoding $false))
Copy-Item "$root\Lab\*.ps1" "$stage\UEK188\Lab"
New-Item -ItemType Directory "$stage\UEK188\Unterlagen" -Force | Out-Null
Copy-Item "$root\Unterlagen\*" "$stage\UEK188\Unterlagen" -ErrorAction SilentlyContinue
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
$fsi.Root.AddTree($stage, $false)
[IsoWriter]::Save($fsi.CreateResultImage().ImageStream, $setupIso)
"Setup ISO: $setupIso"

# VM files
Remove-Item $vmDir -Recurse -Force -ErrorAction SilentlyContinue
if (Test-Path $vmDir) { throw "The folder $vmDir is still in use. Close VMware and start again." }
New-Item -ItemType Directory $vmDir | Out-Null
& "$vmw\vmware-vdiskmanager.exe" -c -s 100GB -a lsilogic -t 0 "$vmDir\UEK188-Win11Edu.vmdk" | Out-Null
if ($LASTEXITCODE) { throw 'The virtual disk could not be created' }

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
$(if (Test-Path "$vmw\windows.iso") { "sata0:2.present = `"TRUE`"`nsata0:2.deviceType = `"cdrom-image`"`nsata0:2.fileName = `"$vmw\windows.iso`"" })
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
[IO.File]::WriteAllText($vmx, $cfg, (New-Object Text.UTF8Encoding $false))  # VMware does not like a BOM
"VM: $vmx"
