# Reads the default language and the index of "Windows 11 Education" from a Windows ISO
param([Parameter(Mandatory)][string]$Iso)
$img = Get-DiskImage -ImagePath $Iso
$mountedBefore = $img.Attached  # already mounted by double-click: use it and leave it mounted
if (-not $mountedBefore) { $img = Mount-DiskImage -ImagePath $Iso -PassThru }
try {
    $dl = ($img | Get-Volume).DriveLetter
    $wim = Get-ChildItem "${dl}:\sources\install.wim", "${dl}:\sources\install.esd" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $wim) { throw 'The ISO has no sources\install.wim. Is it a Windows 11 ISO?' }
    # The image list is stored as XML at the end of the WIM file (offset in the header at 0x48)
    $fs = [IO.File]::OpenRead($wim.FullName); $br = New-Object IO.BinaryReader $fs
    try {
        $fs.Position = 0x48; $raw = $br.ReadBytes(8); $size = [BitConverter]::ToUInt64(($raw[0..6] + [byte]0), 0); $off = $br.ReadInt64()
        $fs.Position = $off; $xml = [xml]([Text.Encoding]::Unicode.GetString($br.ReadBytes([int]$size)).TrimStart([char]0xFEFF))
    } finally { $fs.Close() }
    $edu = $xml.WIM.IMAGE | Where-Object { $_.NAME -eq 'Windows 11 Education' } | Select-Object -First 1
    if (-not $edu) { throw "The ISO does not contain 'Windows 11 Education'. Please use the multi-edition ISO from Microsoft." }
    [pscustomobject]@{ Index = [int]$edu.INDEX; Language = [string]$edu.WINDOWS.LANGUAGES.DEFAULT }
} finally { if (-not $mountedBefore) { Dismount-DiskImage -ImagePath $Iso | Out-Null } }
