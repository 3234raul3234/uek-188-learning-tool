# Selbsttest: jedes Lab muss ungelöst durchfallen und mit Musterlösung bestehen.
# Lokal:  powershell -ExecutionPolicy Bypass -File Tests\selbsttest.ps1   (auch von GitHub Actions genutzt)
param([int[]]$Nur)
$ErrorActionPreference = 'Continue'
$lab = Join-Path (Split-Path $PSScriptRoot) 'Lab\lab188.ps1'
$L = Join-Path $env:TEMP 'uek188-selbsttest'
Remove-Item $L -Recurse -Force -ErrorAction SilentlyContinue
function Lab($aktion, $nr) { & powershell -NoProfile -ExecutionPolicy Bypass -File $lab $aktion $nr -LabPfad $L 2>&1 | ForEach-Object { "$_" } }
function Schreib($datei, $text) { $p = Join-Path $L $datei; New-Item -ItemType Directory (Split-Path $p) -Force | Out-Null; [IO.File]::WriteAllText($p, $text, (New-Object Text.UTF8Encoding $true)) }
function Port($z, $p) { $c = New-Object Net.Sockets.TcpClient; try { $c.ConnectAsync($z, $p).Wait(2000) -and $c.Connected } catch { $false } finally { $c.Dispose() } }

# Musterlösungen pro Lab
$loesung = @{
    1  = {
        $me = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value; $b = "$L\L1\Firma\Buchhaltung"
        icacls $b /inheritance:d | Out-Null; icacls $b /remove:g "*$me" | Out-Null
        icacls $b /grant "*${me}:(OI)(CI)M" | Out-Null; icacls $b /grant '*S-1-5-32-544:(OI)(CI)F' | Out-Null
        icacls "$L\L1\Firma\Verkauf" /grant '*S-1-5-32-545:(OI)(CI)RX' | Out-Null
        icacls "$L\L1\Firma\Alle" /grant '*S-1-5-32-545:(OI)(CI)M' | Out-Null
        Schreib 'L1\berechtigungen.md' '| Buchhaltung | Verkauf | Alle |'
    }
    2  = {
        Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' } | Select-Object Name, DisplayName, Status | Export-Csv "$L\L2\dienste.csv" -NoTypeInformation
        Schreib 'L2\notiz.md' 'Der Dienst ist ein Trigger-Dienst und startet nur bei Bedarf, darum ist er gestoppt.'
    }
    3  = {
        Schreib 'L3\monitor.ps1' @'
param([int]$SchwelleGB = 20)
$c = [math]::Round((Get-PSDrive C).Free / 1GB, 1)
[pscustomobject]@{
  Zeit = Get-Date -Format s
  CPU = [int](Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average).Average
  RAMFreiMB = [int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1KB)
  CFreiGB = $c
  Status = if ($c -lt $SchwelleGB) { 'WARNUNG' } else { 'OK' }
} | Export-Csv "$PSScriptRoot\monitor.csv" -Append -NoTypeInformation
'@
    }
    4  = {
        $hf = @(Get-HotFix | Where-Object InstalledOn | Sort-Object InstalledOn)
        $t = "| KB | Beschreibung | Datum |`n|--|--|--|`n" + (($hf | ForEach-Object { "| $($_.HotFixID) | $($_.Description) | $($_.InstalledOn) |" }) -join "`n")
        if ($hf.Count) { $t += "`n`nLetztes Update: $($hf[-1].HotFixID)" }
        Schreib 'L4\patches.md' $t
    }
    5  = {
        $os = Get-CimInstance Win32_OperatingSystem; $r = Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Sort-Object RouteMetric | Select-Object -First 1
        $ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $r.InterfaceIndex | Select-Object -First 1).IPAddress
        $dns = (Get-DnsClientServerAddress -AddressFamily IPv4 -InterfaceIndex $r.InterfaceIndex).ServerAddresses -join ', '
        Schreib 'L5\steckbrief.md' ("Hostname: $env:COMPUTERNAME`nBetriebssystem: $($os.Caption -replace 'Microsoft ')`nIPv4: $ip`nGateway: $($r.NextHop)`n" +
            "DNS: $dns`nRAM GB: $([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB))")
    }
    6  = {
        @(('www.microsoft.com', 443), ('1.1.1.1', 53), ('localhost', 3389), ('localhost', 445)) | ForEach-Object { [pscustomobject]@{ Ziel = $_[0]; Port = $_[1]; Erreichbar = (Port $_[0] $_[1]) } } | Export-Csv "$L\L6\netztest.csv" -NoTypeInformation
        Schreib 'L6\notiz.md' '3389 ist RDP (Remotedesktop), 445 ist SMB für Dateifreigaben.'
    }
    7  = {
        Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2 } -MaxEvents 10 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, ProviderName | Export-Csv "$L\L7\fehler.csv" -NoTypeInformation
        if (-not (Test-Path "$L\L7\fehler.csv")) { Schreib 'L7\fehler.csv' '"TimeCreated","Id","ProviderName"' }
        Schreib 'L7\notiz.md' 'Am häufigsten kommt Quelle X vor, das bedeutet, dass ein Treiber nicht geladen werden konnte.'
    }
    8  = {
        $adm = @(Get-LocalGroupMember -SID S-1-5-32-544 | ForEach-Object { $_.SID.Value })
        Get-LocalUser | Select-Object Name, @{ n = 'Aktiv'; e = { $_.Enabled } }, @{ n = 'Admin'; e = { $adm -contains $_.SID.Value } } | Export-Csv "$L\L8\benutzer.csv" -NoTypeInformation
        Schreib 'L8\notiz.md' 'Alle Konten ausser Administrator deaktivieren.'
    }
    9  = {
        Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
            Where-Object DisplayName | Select-Object DisplayName, DisplayVersion, Publisher | Export-Csv "$L\L9\software.csv" -NoTypeInformation
        Schreib 'L9\notiz.md' 'Programm A ist aktuell, Programm B ist veraltet, Programm C ist aktuell laut Website.'
    }
    10 = {
        Schreib 'L10\checkliste-titan.md' "- [ ] 4 GB RAM, 2 CPU, intnet-lan`n- [ ] Gasterweiterungen`n- [ ] Servername titan`n- [ ] statische IP 172.18.20.120, Subnetzmaske 255.255.255.192, Gateway 172.18.20.65, DNS`n- [ ] Updates`n- [ ] Druck- und Dokumentdienste, Treiber PCL-6 HP X58045z, Freigabe pr-office`n- [ ] Internet testen"
        Schreib 'L10\checkliste-ws01.md' "- [ ] 4 GB RAM, intnet-lan, Gasterweiterungen`n- [ ] Name ws01, statisch 172.18.20.66 /26, Gateway 172.18.20.65, DNS OPNsense`n- [ ] nur Administrator, andere deaktivieren`n- [ ] Firefox, Notepad++, Updates, Internet ping"
    }
    11 = {
        $sv = Get-Service Spooler; $p = (Get-CimInstance Win32_Service -Filter "Name='Spooler'").PathName
        Schreib 'L11\spooler.md' "$($sv.DisplayName), Starttyp $($sv.StartType), Status $($sv.Status), hängt ab von $($sv.ServicesDependedOn.Name -join ', '), Pfad $p. PrintNightmare war 2021 eine Lücke im Spooler, die Remotecodeausführung mit SYSTEM-Rechten erlaubte. Darum auf Servern ohne Druckfunktion deaktivieren."
    }
    12 = {
        & $loesung[3]
        $a = New-ScheduledTaskAction -Execute powershell.exe -Argument "-NoProfile -File `"$L\L3\monitor.ps1`""
        $t = New-ScheduledTaskTrigger -Once -At (Get-Date).AddHours(1) -RepetitionInterval (New-TimeSpan -Minutes 15)
        Register-ScheduledTask -TaskName Lab188-Monitor -Action $a -Trigger $t -Force | Out-Null
    }
    13 = { Schreib 'L13\netz.md' "Subnetzmaske: 255.255.254.0`nNetzadresse: 10.20.30.0`nBroadcast: 10.20.31.255`nErster Host: 10.20.30.1`nLetzter Host: 10.20.31.254`nAnzahl Hosts: 510`nHotel DHCP-Adressen: 50`n172.18.20.130 im Hotelnetz: Nein" }
    14 = {
        $m = [ordered]@{ 'Austausch' = 'GL AD FO BO FB CO HK TE'; 'Front-office' = 'GL FO'; 'BO' = 'GL BO'; 'Administration' = 'GL AD FB CO'; 'Conv' = 'GL FB CO'; 'FOBE' = 'GL CO'; 'Saal' = 'GL AD FO BO CO TE'; 'Bar' = 'GL AD FO BO FB CO TE'; 'Sitzungen' = 'GL AD FO BO CO TE'; 'Büros' = 'GL AD FO BO CO TE'; 'pr-office' = 'GL AD FO BO FB CO HK TE' }
        $an = @{ GL = 'Geschäftsleitung'; AD = 'Administration'; FO = 'Front-Office'; BO = 'Back-Office'; FB = 'Food & Beverage'; CO = 'Convention'; HK = 'Housekeeping'; TE = 'Technik' }
        $m.Keys | ForEach-Object { $f = $_; $m[$f].Split(' ') | ForEach-Object { [pscustomobject]@{ Freigabe = $f; Abteilung = $an[$_]; Recht = $(if ($f -eq 'pr-office') { 'D' } else { 'L,S' }) } } } | Export-Csv "$L\L14\berechtigungen.csv" -NoTypeInformation -Encoding UTF8
        Schreib 'L14\notiz.md' 'Benutzer in globale Gruppen GG_Abteilung, diese in die domänenlokale Gruppe DL_Austausch_RW, diese bekommt Lesen/Schreiben.'
    }
    15 = {
        $u = @"
Vorname;Nachname;Login;Abteilung
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
Daniel;Düsentrieb;dandse;Technik
Petro;Del Duerr;petdel;Technik
Nico;Berger;nicber;Technik
"@ | ConvertFrom-Csv -Delimiter ';'
        $u | Export-Csv "$L\L15\benutzer.csv" -NoTypeInformation -Encoding UTF8
        Schreib 'L15\pruefen.ps1' '# berechnet das Soll-Login'
        $abw = $u | Where-Object { $_.Login -cne ($_.Vorname.Substring(0, 3) + ($_.Nachname -replace ' ', '' -replace 'ä', 'ae' -replace 'ö', 'oe' -replace 'ü', 'ue').Substring(0, 3)).ToLower() } | ForEach-Object Login
        Schreib 'L15\abweichungen.txt' ($abw -join "`n")
    }
}

$alle = if ($Nur) { $Nur } else { 1..15 }
$fehler = 0
foreach ($n in $alle) {
    Lab start $n | Out-Null
    $roh = Lab check $n
    $ungeloest = -not ($roh -match 'Lab bestanden')
    try { & $loesung[$n] } catch { "Lösung Lab $n wirft Fehler: $_" }
    $aus = Lab check $n
    $geloest = [bool]($aus -match 'Lab bestanden')
    if ($n -eq 12) { Unregister-ScheduledTask Lab188-Monitor -Confirm:$false -ErrorAction SilentlyContinue }
    $ok = $ungeloest -and $geloest
    if (-not $ok) { $fehler++ }
    Write-Host ("Lab {0,2}: ungelöst rot={1,-5} gelöst grün={2,-5} {3}" -f $n, $ungeloest, $geloest, $(if ($ok) { 'OK' } else { 'FEHLER' })) -ForegroundColor $(if ($ok) { 'Green' } else { 'Red' })
    if (-not $geloest) { $aus | Where-Object { $_ -match '^\[X\]|Tipp|Exception|Fehler' } | ForEach-Object { "         $_" } }
}
Remove-Item $L -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "`n$($alle.Count - $fehler) von $($alle.Count) Labs in Ordnung."
exit $fehler
