# Self-test: every lab must fail when unsolved and pass with the model solution.
# Local:  powershell -ExecutionPolicy Bypass -File Tests\selbsttest.ps1   (also used by GitHub Actions)
param([Alias('Nur')][int[]]$Only)
$ErrorActionPreference = 'Continue'
$lab = Join-Path (Split-Path $PSScriptRoot) 'Lab\lab188.ps1'
$L = Join-Path $env:TEMP 'uek188-selftest'
Remove-Item $L -Recurse -Force -ErrorAction SilentlyContinue
function Lab($action, $no) { & powershell -NoProfile -ExecutionPolicy Bypass -File $lab $action $no -LabPath $L 2>&1 | ForEach-Object { "$_" } }
function Write-Lab($file, $text) { $p = Join-Path $L $file; New-Item -ItemType Directory (Split-Path $p) -Force | Out-Null; [IO.File]::WriteAllText($p, $text, (New-Object Text.UTF8Encoding $true)) }
function Port($z, $p) { $c = New-Object Net.Sockets.TcpClient; try { $c.ConnectAsync($z, $p).Wait(2000) -and $c.Connected } catch { $false } finally { $c.Dispose() } }

# Model solutions per lab
$solution = @{
    1  = {
        $me = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value; $b = "$L\L1\Company\Accounting"
        icacls $b /inheritance:d | Out-Null; icacls $b /remove:g "*$me" | Out-Null
        icacls $b /grant "*${me}:(OI)(CI)M" | Out-Null; icacls $b /grant '*S-1-5-32-544:(OI)(CI)F' | Out-Null
        icacls "$L\L1\Company\Sales" /grant '*S-1-5-32-545:(OI)(CI)RX' | Out-Null
        icacls "$L\L1\Company\All" /grant '*S-1-5-32-545:(OI)(CI)M' | Out-Null
        Write-Lab 'L1\permissions.md' '| Accounting | Sales | All |'
    }
    2  = {
        Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' } | Select-Object Name, DisplayName, Status | Export-Csv "$L\L2\services.csv" -NoTypeInformation
        Write-Lab 'L2\notes.md' 'This service is a trigger service and only starts when needed, that is why it is stopped.'
    }
    3  = {
        Write-Lab 'L3\monitor.ps1' @'
param([int]$ThresholdGB = 20)
$c = [math]::Round((Get-PSDrive C).Free / 1GB, 1)
[pscustomobject]@{
  Time = Get-Date -Format s
  CPU = [int](Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average).Average
  RAMFreeMB = [int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1KB)
  CFreeGB = $c
  Status = if ($c -lt $ThresholdGB) { 'WARNING' } else { 'OK' }
} | Export-Csv "$PSScriptRoot\monitor.csv" -Append -NoTypeInformation
'@
    }
    4  = {
        $hf = @(Get-HotFix | Where-Object InstalledOn | Sort-Object InstalledOn)
        $t = "| KB | Description | Date |`n|--|--|--|`n" + (($hf | ForEach-Object { "| $($_.HotFixID) | $($_.Description) | $($_.InstalledOn) |" }) -join "`n")
        if ($hf.Count) { $t += "`n`nLast update: $($hf[-1].HotFixID)" }
        Write-Lab 'L4\patches.md' $t
    }
    5  = {
        $os = Get-CimInstance Win32_OperatingSystem; $r = Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Sort-Object RouteMetric | Select-Object -First 1
        $ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $r.InterfaceIndex | Select-Object -First 1).IPAddress
        $dns = (Get-DnsClientServerAddress -AddressFamily IPv4 -InterfaceIndex $r.InterfaceIndex).ServerAddresses -join ', '
        Write-Lab 'L5\profile.md' ("Hostname: $env:COMPUTERNAME`nOperating system: $($os.Caption -replace 'Microsoft ')`nIPv4: $ip`nGateway: $($r.NextHop)`n" +
            "DNS: $dns`nRAM GB: $([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB))")
    }
    6  = {
        @(('www.microsoft.com', 443), ('1.1.1.1', 53), ('localhost', 3389), ('localhost', 445)) | ForEach-Object { [pscustomobject]@{ Target = $_[0]; Port = $_[1]; Reachable = (Port $_[0] $_[1]) } } | Export-Csv "$L\L6\nettest.csv" -NoTypeInformation
        Write-Lab 'L6\notes.md' '3389 is RDP (Remote Desktop), 445 is SMB for file shares.'
    }
    7  = {
        Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2 } -MaxEvents 10 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, ProviderName | Export-Csv "$L\L7\errors.csv" -NoTypeInformation
        if (-not (Test-Path "$L\L7\errors.csv")) { Write-Lab 'L7\errors.csv' '"TimeCreated","Id","ProviderName"' }
        Write-Lab 'L7\notes.md' 'Source X appears most often, which means that a driver could not be loaded.'
    }
    8  = {
        $adm = @(Get-LocalGroupMember -SID S-1-5-32-544 | ForEach-Object { $_.SID.Value })
        Get-LocalUser | Select-Object Name, Enabled, @{ n = 'Admin'; e = { $adm -contains $_.SID.Value } } | Export-Csv "$L\L8\users.csv" -NoTypeInformation
        Write-Lab 'L8\notes.md' 'Disable all accounts except Administrator.'
    }
    9  = {
        Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
            Where-Object DisplayName | Select-Object DisplayName, DisplayVersion, Publisher | Export-Csv "$L\L9\software.csv" -NoTypeInformation
        Write-Lab 'L9\notes.md' 'Program A is up to date, program B is outdated, program C is up to date according to the website.'
    }
    10 = {
        Write-Lab 'L10\checklist-titan.md' "- [ ] 4 GB RAM, 2 CPU, intnet-lan`n- [ ] VMware Tools`n- [ ] Server name titan`n- [ ] static IP 172.18.20.120, subnet mask 255.255.255.192, gateway 172.18.20.65, DNS`n- [ ] Updates`n- [ ] Print and Document Services, driver PCL-6 HP X58045z, share pr-office`n- [ ] Test internet"
        Write-Lab 'L10\checklist-ws01.md' "- [ ] 4 GB RAM, intnet-lan, VMware Tools`n- [ ] Name ws01, static 172.18.20.66 /26, gateway 172.18.20.65, DNS OPNsense`n- [ ] only Administrator, disable others`n- [ ] Firefox, Notepad++, updates, internet ping"
    }
    11 = {
        $sv = Get-Service Spooler; $p = (Get-CimInstance Win32_Service -Filter "Name='Spooler'").PathName
        Write-Lab 'L11\spooler.md' "$($sv.DisplayName), start type $($sv.StartType), status $($sv.Status), depends on $($sv.ServicesDependedOn.Name -join ', '), path $p. PrintNightmare was a vulnerability in the spooler in 2021 that allowed remote code execution with SYSTEM rights. That is why it should be disabled on servers without printing."
    }
    12 = {
        & $solution[3]
        $a = New-ScheduledTaskAction -Execute powershell.exe -Argument "-NoProfile -File `"$L\L3\monitor.ps1`""
        $t = New-ScheduledTaskTrigger -Once -At (Get-Date).AddHours(1) -RepetitionInterval (New-TimeSpan -Minutes 15)
        Register-ScheduledTask -TaskName Lab188-Monitor -Action $a -Trigger $t -Force | Out-Null
    }
    13 = { Write-Lab 'L13\network.md' "Subnet mask: 255.255.254.0`nNetwork address: 10.20.30.0`nBroadcast: 10.20.31.255`nFirst host: 10.20.30.1`nLast host: 10.20.31.254`nNumber of hosts: 510`nHotel DHCP addresses: 50`n172.18.20.130 in hotel network: No" }
    14 = {
        $m = [ordered]@{ 'Exchange' = 'MG AD FO BO FB CO HK TE'; 'Front-office' = 'MG FO'; 'BO' = 'MG BO'; 'Administration' = 'MG AD FB CO'; 'Conv' = 'MG FB CO'; 'FOBE' = 'MG CO'; 'Hall' = 'MG AD FO BO CO TE'; 'Bar' = 'MG AD FO BO FB CO TE'; 'Meetings' = 'MG AD FO BO CO TE'; 'Offices' = 'MG AD FO BO CO TE'; 'pr-office' = 'MG AD FO BO FB CO HK TE' }
        $an = @{ MG = 'Management'; AD = 'Administration'; FO = 'Front Office'; BO = 'Back Office'; FB = 'Food & Beverage'; CO = 'Convention'; HK = 'Housekeeping'; TE = 'Technical' }
        $m.Keys | ForEach-Object { $f = $_; $m[$f].Split(' ') | ForEach-Object { [pscustomobject]@{ Share = $f; Department = $an[$_]; Right = $(if ($f -eq 'pr-office') { 'P' } else { 'R,W' }) } } } | Export-Csv "$L\L14\permissions.csv" -NoTypeInformation -Encoding UTF8
        Write-Lab 'L14\notes.md' 'Users go into global groups GG_Department, these into the domain local group DL_Exchange_RW, which gets read/write.'
    }
    15 = {
        $u = @"
FirstName;LastName;Login;Department
Sandro;Della Serra;sandel;Administration
Paula;Michel;paumic;Administration
Stefanie;Fuchs;stefuc;Administration
Thomas;König;thokni;Administration
Gerhard;Bär;gerbae;Back Office
Leonora;Brunner;Leobru;Back Office
Simon;Tauber;simtau;Back Office
Petra;Zack;petzac;Front Office
Nora;Berger;norber;Front Office
Sandra;Martinez;sanmar;Front Office
Daniela;Bertolini;Danber;Front Office
Thomas;Kro;thokro;Front Office
Stefan;Meier;stemei;Front Office
Thomas;Kleiner;thokle;Front Office
Benjamin;Krakenhofer;Benkra;Food & Beverage
Antonio;Bernardo;antber;Food & Beverage
Peter;Weber;petweb;Food & Beverage
Stefanie;Trapp;Stetra;Convention
Girgio;Politano;girpol;Convention
Gertrude;Bertram;gerber;Housekeeping
Pia;Manjou;piaman;Housekeeping
Andrea;Kaviezel;andkav;Housekeeping
Daniel;Düsentrieb;dandse;Technical
Petro;Del Duerr;petdel;Technical
Nico;Berger;nicber;Technical
"@ | ConvertFrom-Csv -Delimiter ';'
        $u | Export-Csv "$L\L15\users.csv" -NoTypeInformation -Encoding UTF8
        Write-Lab 'L15\check.ps1' 'Import-Csv users.csv | ForEach-Object { ($_.FirstName.Substring(0,3) + ($_.LastName -replace " ","" -replace "ä","ae").Substring(0,3)).ToLower() }'
        $dev = $u | Where-Object { $_.Login -cne ($_.FirstName.Substring(0, 3) + ($_.LastName -replace ' ', '' -replace 'ä', 'ae' -replace 'ö', 'oe' -replace 'ü', 'ue').Substring(0, 3)).ToLower() } | ForEach-Object Login
        Write-Lab 'L15\deviations.txt' ($dev -join "`n")
    }
}

$all = if ($Only) { $Only } else { 1..15 }
$failed = 0
foreach ($n in $all) {
    if ($n -eq 12 -and (Get-ScheduledTask Lab188-Monitor -ErrorAction SilentlyContinue)) {
        Write-Host 'Lab 12: skipped, a real task Lab188-Monitor already exists on this computer (left untouched)' -ForegroundColor Yellow; continue
    }
    Lab start $n | Out-Null
    $raw = Lab check $n
    $unsolved = -not ($raw -match 'Lab passed')
    try { & $solution[$n] } catch { "Solution lab $n throws an error: $_" }
    $out = Lab check $n
    $solved = [bool]($out -match 'Lab passed')
    if ($n -eq 12) { Unregister-ScheduledTask Lab188-Monitor -Confirm:$false -ErrorAction SilentlyContinue }
    $ok = $unsolved -and $solved
    if (-not $ok) { $failed++ }
    Write-Host ("Lab {0,2}: unsolved red={1,-5} solved green={2,-5} {3}" -f $n, $unsolved, $solved, $(if ($ok) { 'OK' } else { 'FAILED' })) -ForegroundColor $(if ($ok) { 'Green' } else { 'Red' })
    if (-not $solved) { $out | Where-Object { $_ -match '^\[X\]|Hint|Exception|Error' } | ForEach-Object { "         $_" } }
}
Remove-Item $L -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "`n$($all.Count - $failed) of $($all.Count) labs OK."
exit $failed
