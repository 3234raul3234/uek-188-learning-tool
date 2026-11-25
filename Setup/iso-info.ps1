# Liest aus einer Windows-ISO die Standardsprache und den Index von "Windows 11 Education"
param([Parameter(Mandatory)][string]$Iso)
$img = Mount-DiskImage -ImagePath $Iso -PassThru
try {
    $dl = ($img | Get-Volume).DriveLetter
    $wim = Get-ChildItem "${dl}:\sources\install.wim", "${dl}:\sources\install.esd" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $wim) { throw 'In der ISO fehlt sources\install.wim. Ist das eine Windows-11-ISO?' }
    # Die Image-Liste steht als XML am Ende der WIM-Datei (Offset im Header bei 0x48)
    $fs = [IO.File]::OpenRead($wim.FullName); $br = New-Object IO.BinaryReader $fs
    try {
        $fs.Position = 0x48; $raw = $br.ReadBytes(8); $size = [BitConverter]::ToUInt64(($raw[0..6] + [byte]0), 0); $off = $br.ReadInt64()
        $fs.Position = $off; $xml = [xml]([Text.Encoding]::Unicode.GetString($br.ReadBytes([int]$size)).TrimStart([char]0xFEFF))
    } finally { $fs.Close() }
    $edu = $xml.WIM.IMAGE | Where-Object { $_.NAME -eq 'Windows 11 Education' } | Select-Object -First 1
    if (-not $edu) { throw "Die ISO enthält kein 'Windows 11 Education'. Bitte die Multi-Edition-ISO von Microsoft verwenden." }
    [pscustomobject]@{ Index = [int]$edu.INDEX; Sprache = [string]$edu.WINDOWS.LANGUAGES.DEFAULT }
} finally { Dismount-DiskImage -ImagePath $Iso | Out-Null }
