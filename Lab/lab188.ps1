# ÜK 188 Praxis-Labs.  Nutzung: lab188.ps1 list | start <Nr> | check <Nr>
param(
    [ValidateSet('list', 'start', 'check', 'doku')][string]$Aktion = 'list',
    [ValidateRange(1, 15)][int]$Nr = 1,
    [string]$LabPfad = $(if (Test-Path 'C:\UEK188\Uebungen') { 'C:\UEK188\Uebungen' } else { Join-Path $env:USERPROFILE 'Lab188' })
)
$ErrorActionPreference = 'Stop'
$script:ok = 0; $script:fail = 0
$SID_USERS = 'S-1-5-32-545'; $SID_ADMINS = 'S-1-5-32-544'
$SID_ME = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value

function Pruefe($text, [bool]$bedingung, $tipp) {
    if ($bedingung) { Write-Host "[OK] $text" -ForegroundColor Green; $script:ok++ }
    else { Write-Host "[X]  $text" -ForegroundColor Red; if ($tipp) { Write-Host "     Tipp: $tipp" -ForegroundColor Yellow }; $script:fail++ }
}

# Summe aller "Zulassen"-Rechte einer SID auf einem Pfad (als int)
function Rechte($pfad, $sid) {
    $r = 0
    foreach ($a in (Get-Acl $pfad).Access) {
        if ($a.AccessControlType -ne 'Allow') { continue }
        try { $s = $a.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value } catch { continue }
        if ($s -eq $sid) { $r = $r -bor [int]$a.FileSystemRights }
    }
    $r
}
function Hat([int]$r, $recht) { $m = [int][Security.AccessControl.FileSystemRights]::$recht; ($r -band $m) -eq $m }
function Inhalt($name) { $f = Join-Path $dir $name; if (Test-Path $f) { Get-Content $f -Raw } else { '' } }
function IstWahr($wert) { "$wert" -match '^(true|ja|wahr|1)$' }
function PortOffen($ziel, $port) { $c = New-Object Net.Sockets.TcpClient; try { $c.ConnectAsync($ziel, $port).Wait(2000) -and $c.Connected } catch { $false } finally { $c.Dispose() } }

$Labs = @{
    1 = @{ Titel = 'NTFS-Berechtigungen nach Konzept (HZ 5)'; Auftrag = @"
Berechtigungskonzept Firma Muster AG, Ordner: L1\Firma
  Buchhaltung : Vererbung DEAKTIVIERT. Administratoren = Vollzugriff, DU = Ändern (nicht Vollzugriff), Benutzer = kein Zugriff
  Verkauf     : Benutzer (Users) = Lesen und Ausführen, aber KEIN Schreiben
  Alle        : Benutzer (Users) = Ändern
Dokumentiere alles als Tabelle in L1\berechtigungen.md (Ordner | Gruppe | Recht | Begründung).
Werkzeuge: Explorer > Eigenschaften > Sicherheit, oder icacls / Get-Acl / Set-Acl
"@
    }
    2 = @{ Titel = 'Dienste analysieren (HZ 1, 2)'; Auftrag = @"
Ein Server macht Probleme. Finde alle Dienste mit Starttyp 'Automatic', die NICHT laufen.
  1. Exportiere sie nach L2\dienste.csv mit den Spalten Name, DisplayName, Status (PowerShell!)
  2. Schreib in L2\notiz.md zu einem dieser Dienste: was er macht und warum er evtl. gestoppt ist.
Tipp: Get-Service, Where-Object, Select-Object, Export-Csv -NoTypeInformation
"@
    }
    3 = @{ Titel = 'Monitoring-Skript mit Schwellwert (HZ 4)'; Auftrag = @"
Schreib L3\monitor.ps1. Jeder Aufruf hängt EINE Zeile an L3\monitor.csv an (neben dem Skript, `$PSScriptRoot).
  Spalten: Zeit, CPU (Auslastung in %), RAMFreiMB, CFreiGB, Status
  Parameter: -SchwelleGB (Standard 20). Status = 'WARNUNG' wenn CFreiGB < SchwelleGB, sonst 'OK'
Der Check startet dein Skript selbst und vergleicht die Werte mit dem echten System.
Tipp: Get-CimInstance Win32_Processor / Win32_OperatingSystem, Get-PSDrive C, Export-Csv -Append
"@
    }
    4 = @{ Titel = 'Patch-Dokumentation (HZ 3)'; Auftrag = @"
Führe die Betriebsdoku nach: Erstelle L4\patches.md mit
  - einer Tabelle aller installierten Updates (KB | Beschreibung | Installiert am)
  - der Zeile 'Letztes Update: KBxxxxxxx'
Tipp: Get-HotFix | Sort-Object InstalledOn
"@
    }
    5 = @{ Titel = 'System-Steckbrief für die Betriebsdoku (HZ 1)'; Auftrag = @"
Wie beim Hotel Vier Winde: Bevor du etwas änderst, nimmst du das System auf.
Erstelle L5\steckbrief.md über DEINEN PC mit diesen Zeilen:
  Hostname: ...
  Betriebssystem: ...   (z. B. Windows 11 Pro)
  IPv4: ...
  Gateway: ...
  DNS: ...
  RAM GB: ...
Der Check vergleicht alles mit dem echten System.
Tipp: hostname, ipconfig /all, Get-NetIPConfiguration, Get-CimInstance Win32_OperatingSystem / Win32_ComputerSystem
"@
    }
    6 = @{ Titel = 'Netzwerk und Remotezugriff testen (HZ 2)'; Auftrag = @"
Prüfe, welche Dienste erreichbar sind. Teste diese 4 Ziele:
  www.microsoft.com Port 443  |  1.1.1.1 Port 53  |  localhost Port 3389  |  localhost Port 445
  1. Speichere das Ergebnis in L6\netztest.csv mit den Spalten Ziel, Port, Erreichbar (True/False)
  2. Erkläre in L6\notiz.md: Welcher Dienst läuft auf Port 3389 und welcher auf Port 445?
Tipp: Test-NetConnection -ComputerName <Ziel> -Port <Port>  ->  TcpTestSucceeded
"@
    }
    7 = @{ Titel = 'Ereignisanzeige auswerten (HZ 2, 4)'; Auftrag = @"
Überwachung Windows: Finde die letzten 10 FEHLER im System-Protokoll.
  1. Exportiere sie nach L7\fehler.csv mit den Spalten TimeCreated, Id, ProviderName
  2. Schreib in L7\notiz.md: Welche Quelle (ProviderName) kommt am häufigsten vor und was bedeutet der Fehler?
Tipp: Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2 } -MaxEvents 10
"@
    }
    8 = @{ Titel = 'Lokale Benutzer und Administratoren (HZ 5)'; Auftrag = @"
Auf ws01 darf nur das lokale Administratorkonto aktiv sein. Prüfe, wie es auf deinem PC aussieht.
  1. Exportiere ALLE lokalen Benutzer nach L8\benutzer.csv mit den Spalten Name, Aktiv, Admin
     (Aktiv = True/False, Admin = True/False: ist der Benutzer in der Gruppe Administratoren?)
  2. Schreib in L8\notiz.md: Welche Konten müsstest du deaktivieren, damit wie auf ws01 nur der Administrator aktiv ist?
Tipp: Get-LocalUser, Get-LocalGroupMember -SID S-1-5-32-544
"@
    }
    9 = @{ Titel = 'Software-Inventar (HZ 3)'; Auftrag = @"
Software-Unterhalt beginnt mit einem Inventar.
  1. Exportiere alle installierten Programme nach L9\software.csv mit den Spalten DisplayName, DisplayVersion, Publisher
     (ohne Einträge ohne DisplayName)
  2. Schreib in L9\notiz.md: Such dir 3 Programme aus und prüfe im Internet, ob deine Version aktuell ist.
Tipp: Die Programme stehen in der Registry unter
  HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*
  HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*
  HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*
"@
    }
    10 = @{ Titel = 'Checklisten titan und ws01 (HZ 1, Auftrag 2)'; Auftrag = @"
Das ist dein Moodle-Auftrag 2. Der Check prüft, ob deine Checklisten vollständig sind.
  Erstelle L10\checkliste-titan.md und L10\checkliste-ws01.md (mit Kästchen, z. B. '- [ ] Aufgabe')
  Infos: Betriebsdokumentation, Netzwerkplan und Moodle-Auftrag 2 und 3.
Denk an: VirtualBox-Einstellungen (RAM, CPU, Netzwerkadapter), Gasterweiterungen, Name, IP-Konfiguration,
Updates, Druckerserver, nur lokales Administratorkonto auf ws01, Tools, Kontrolle, ...
Danach kannst du die Checklisten in Moodle hochladen.
"@
    }
    11 = @{ Titel = 'Dienst Druckwarteschlange untersuchen (HZ 1, 2)'; Auftrag = @"
Für den Drucker pr-office braucht titan den Dienst Druckwarteschlange (Spooler). Untersuche ihn auf deinem PC.
Erstelle L11\spooler.md mit:
  - Anzeigename, Starttyp und Status des Dienstes
  - von welchen Diensten er abhängt
  - Pfad der Programmdatei (.exe)
  - warum der Spooler ein Sicherheitsrisiko sein kann (Stichwort: PrintNightmare)
Tipp: Get-Service Spooler | Format-List *, Get-CimInstance Win32_Service -Filter "Name='Spooler'"
"@
    }
    12 = @{ Titel = 'Monitoring automatisieren (HZ 4, d1)'; Auftrag = @"
Dein Monitoring-Skript aus Lab 3 soll automatisch laufen.
  Erstelle eine geplante Aufgabe mit dem Namen  Lab188-Monitor
  - startet powershell.exe mit deinem L3\monitor.ps1
  - wiederholt sich alle 15 Minuten
Voraussetzung: Lab 3 ist gelöst.
Tipp: New-ScheduledTaskAction, New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15), Register-ScheduledTask
Aufräumen, wenn du fertig bist:  Unregister-ScheduledTask Lab188-Monitor
"@
    }
    13 = @{ Titel = 'Subnetting Hotel Vier Winde (HZ 1)'; Auftrag = @"
Das Hotel Vier Winde will ein Gäste-WLAN mit dem Netz 10.20.30.0/23. Rechne selbst (ohne Rechner im Internet)!
Erstelle L13\netz.md mit genau diesen Zeilen:
  Subnetzmaske: ...
  Netzadresse: ...
  Broadcast: ...
  Erster Host: ...
  Letzter Host: ...
  Anzahl Hosts: ...
Und zwei Fragen zum bestehenden Hotelnetz 172.18.20.64/26 (Betriebsdoku/Netzwerkplan):
  Hotel DHCP-Adressen: ...        (wie viele Adressen hat der Bereich .66 bis .115?)
  172.18.20.130 im Hotelnetz: Ja/Nein
"@
    }
    14 = @{ Titel = 'Berechtigungsmatrix Hotel Vier Winde (HZ 5)'; Auftrag = @"
Vorbereitung für Tag 3 (Benutzer, Gruppen, Permissions): Übertrage die Tabelle 'Serverfreigaben und
Berechtigungen' aus der Betriebsdoku in L14\berechtigungen.csv mit den Spalten Freigabe, Abteilung, Recht
  - eine Zeile pro Freigabe und Abteilung, die Rechte hat (keine Zeilen für '-')
  - Freigaben: Austausch, Front-office, BO, Administration, Conv, FOBE, Saal, Bar, Sitzungen, Büros, pr-office
  - Abteilungen: Geschäftsleitung, Administration, Front-Office, Back-Office, Food & Beverage, Convention, Housekeeping, Technik
  - Recht: L,S oder D (wie in der Tabelle)
In L14\notiz.md: Wie setzt du die Freigabe 'Austausch' mit AGDLP um? (Welche globalen und domänenlokalen Gruppen?)
Kommt dir in der Tabelle etwas komisch vor? Notier es auch, Fehler in der Doku finden ist Teil vom Job.
"@
    }
    15 = @{ Titel = 'Logins in der Betriebsdoku prüfen (HZ 1, 5)'; Auftrag = @"
Bevor du die Benutzer im AD anlegst, prüfst du die Liste in der Betriebsdoku (Kapitel 5.3 - 5.9).
Die Regel für Logins: 3 Buchstaben Vorname + 3 Buchstaben Nachname, alles klein,
ä/ö/ü = ae/oe/ue, Leerzeichen weglassen. Beispiel: Gerhard Bär -> gerbae
  1. Erfasse alle Benutzer in L15\benutzer.csv mit den Spalten Vorname, Nachname, Login, Abteilung
  2. Schreib ein Skript L15\pruefen.ps1, das für jede Zeile das Soll-Login nach der Regel berechnet
  3. Schreib alle Logins aus der Doku, die NICHT der Regel entsprechen, in L15\abweichungen.txt (eins pro Zeile, wie in der Doku geschrieben)
Tipp: .Substring(0,3), .ToLower(), -replace 'ä','ae'
"@
    }
}

$dir = Join-Path $LabPfad "L$Nr"

if ($Aktion -eq 'list') {
    foreach ($n in $Labs.Keys | Sort-Object) { Write-Host "$n  $($Labs[$n].Titel)" }
    return
}

if ($Aktion -eq 'start') {
    if (Test-Path $dir) { Write-Host "Lab $Nr existiert schon in $dir (wird nicht überschrieben)." -ForegroundColor Yellow }
    else {
        New-Item -ItemType Directory $dir | Out-Null
        if ($Nr -eq 1) { 'Buchhaltung', 'Verkauf', 'Alle' | ForEach-Object { New-Item -ItemType Directory (Join-Path $dir "Firma\$_") | Out-Null } }
        Set-Content (Join-Path $dir 'Auftrag.txt') $Labs[$Nr].Auftrag
    }
    Write-Host "`n=== Lab $Nr - $($Labs[$Nr].Titel) ===  Ordner: $LabPfad`n" -ForegroundColor Cyan
    Write-Host $Labs[$Nr].Auftrag
    Write-Host "`nFertig? ->  lab188.ps1 check $Nr" -ForegroundColor Cyan
    return
}

if ($Aktion -eq 'doku') {
    # Fertiger Abschnitt für die Moodle-Dokumentation / Obsidian
    if (-not (Test-Path $dir)) { Write-Host "Lab $Nr nicht gestartet." -ForegroundColor Red; exit 1 }
    $pruef = & powershell -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath check $Nr -LabPfad $LabPfad 2>&1 | ForEach-Object { "$_" }
    $md = @("## Lab $Nr – $($Labs[$Nr].Titel)", '', "*$(Get-Date -Format 'dd.MM.yyyy HH:mm') auf $env:COMPUTERNAME*", '', '### Auftrag', '```', $Labs[$Nr].Auftrag.Trim(), '```', '', '### Meine Lösung')
    if ($Nr -eq 1) {
        $md += '**Berechtigungen**', '', '| Ordner | Wer | Recht | Vererbt |', '|---|---|---|---|'
        foreach ($o in Get-ChildItem (Join-Path $dir 'Firma') -Directory) { foreach ($a in (Get-Acl $o.FullName).Access) { $md += "| $($o.Name) | $($a.IdentityReference) | $($a.FileSystemRights) | $(if ($a.IsInherited) { 'ja' } else { 'nein' }) |" } }
        $md += ''
    }
    if ($Nr -eq 12) { $md += '**Geplante Aufgabe**', '```', (Get-ScheduledTask Lab188-Monitor -ErrorAction SilentlyContinue | ForEach-Object { "$($_.TaskName): $($_.Actions[0].Execute) $($_.Actions[0].Arguments) / Intervall $($_.Triggers[0].Repetition.Interval)" }), '```', '' }
    foreach ($f in Get-ChildItem $dir -Recurse -File | Where-Object Name -NotIn 'Auftrag.txt', '.bestanden') {
        $md += "**$($f.FullName.Substring($dir.Length + 1))**", '```', ((Get-Content $f.FullName -TotalCount 40) -join "`n"), '```', ''
    }
    $md += '### Ergebnis der Kontrolle', '```'
    $md += @($pruef | Where-Object { $_ -match '^\[|Ergebnis|Tipp' })
    $md += '```', '', '### Was ich gelernt habe', '- ', ''
    $ziel = Join-Path $LabPfad ('Doku\Lab-{0:D2}.md' -f $Nr)
    New-Item -ItemType Directory (Split-Path $ziel) -Force | Out-Null
    [IO.File]::WriteAllText($ziel, ($md -join "`r`n"), (New-Object Text.UTF8Encoding $true))
    Write-Host "Doku gespeichert: $ziel"
    return
}

# check
if (-not (Test-Path $dir)) { Write-Host "Lab $Nr nicht gestartet. Zuerst: lab188.ps1 start $Nr" -ForegroundColor Red; exit 1 }
Write-Host "`n=== Check Lab $Nr - $($Labs[$Nr].Titel) ===`n" -ForegroundColor Cyan

switch ($Nr) {
    1 {
        $b = Join-Path $dir 'Firma\Buchhaltung'; $v = Join-Path $dir 'Firma\Verkauf'; $a = Join-Path $dir 'Firma\Alle'
        Pruefe 'Buchhaltung: Vererbung deaktiviert' (Get-Acl $b).AreAccessRulesProtected 'Erweitert > Vererbung deaktivieren (Rechte übernehmen)'
        Pruefe 'Buchhaltung: Administratoren Vollzugriff' (Hat (Rechte $b $SID_ADMINS) 'FullControl')
        $me = Rechte $b $SID_ME
        Pruefe 'Buchhaltung: du hast Ändern' (Hat $me 'Modify')
        Pruefe 'Buchhaltung: du hast NICHT Vollzugriff (Least Privilege)' (-not (Hat $me 'FullControl')) 'Dein Eintrag: Vollzugriff weg, nur Ändern'
        Pruefe 'Buchhaltung: Benutzer kein Zugriff' ((Rechte $b $SID_USERS) -eq 0)
        $vu = Rechte $v $SID_USERS
        Pruefe 'Verkauf: Benutzer Lesen und Ausführen' (Hat $vu 'ReadAndExecute') 'Gruppe "Benutzer" hinzufügen'
        Pruefe 'Verkauf: Benutzer KEIN Schreiben' (-not (Hat $vu 'WriteData'))
        Pruefe 'Alle: Benutzer Ändern' (Hat (Rechte $a $SID_USERS) 'Modify')
        $doc = Join-Path $dir 'berechtigungen.md'
        Pruefe 'Doku berechtigungen.md mit allen 3 Ordnern' ((Test-Path $doc) -and ((Get-Content $doc -Raw) -match 'Buchhaltung' -and (Get-Content $doc -Raw) -match 'Verkauf' -and (Get-Content $doc -Raw) -match 'Alle'))
    }
    2 {
        $csv = Join-Path $dir 'dienste.csv'
        Pruefe 'dienste.csv existiert' (Test-Path $csv) 'Export-Csv -Path ... -NoTypeInformation'
        if (Test-Path $csv) {
            $ist = @(Import-Csv $csv)
            $spalten = if ($ist.Count) { $ist[0].PSObject.Properties.Name } else { @() }
            Pruefe 'Spalten Name, DisplayName, Status' (('Name', 'DisplayName', 'Status' | Where-Object { $spalten -notcontains $_ }).Count -eq 0) 'Select-Object Name, DisplayName, Status'
            $soll = @(Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' } | ForEach-Object Name)
            $istN = @($ist | ForEach-Object Name)
            # shortcut: Dienste ändern ihren Zustand laufend, darum 2 Abweichungen Toleranz
            $fehlt = @($soll | Where-Object { $istN -notcontains $_ }); $zuviel = @($istN | Where-Object { $soll -notcontains $_ })
            Pruefe "Richtige Dienste ($($soll.Count) erwartet, $($istN.Count) gefunden)" ($fehlt.Count -le 2 -and $zuviel.Count -le 2) "Fehlt z. B.: $($fehlt | Select-Object -First 3) / zu viel: $($zuviel | Select-Object -First 3)"
        }
        Pruefe 'notiz.md mit Erklärung' ((Test-Path (Join-Path $dir 'notiz.md')) -and (Get-Item (Join-Path $dir 'notiz.md')).Length -gt 50) 'Mindestens 2-3 Sätze'
    }
    3 {
        $s = Join-Path $dir 'monitor.ps1'; $csv = Join-Path $dir 'monitor.csv'
        Pruefe 'monitor.ps1 existiert' (Test-Path $s)
        if (Test-Path $s) {
            Remove-Item $csv -ErrorAction SilentlyContinue  # Check startet mit leerer CSV
            $ErrorActionPreference = 'Continue'
            & powershell -NoProfile -ExecutionPolicy Bypass -File $s
            & powershell -NoProfile -ExecutionPolicy Bypass -File $s
            & powershell -NoProfile -ExecutionPolicy Bypass -File $s -SchwelleGB 999999
            $ErrorActionPreference = 'Stop'
            $rows = @(if (Test-Path $csv) { Import-Csv $csv })
            Pruefe '3 Aufrufe = 3 Zeilen in monitor.csv' ($rows.Count -eq 3) 'Export-Csv -Append, Pfad mit $PSScriptRoot'
            if ($rows.Count -ge 3) {
                $r = $rows[0]
                $ramEcht = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1KB
                $cEcht = (Get-PSDrive C).Free / 1GB
                Pruefe 'Spalten Zeit, CPU, RAMFreiMB, CFreiGB, Status' (($null -ne $r.Zeit) -and ($null -ne $r.CPU) -and ($null -ne $r.RAMFreiMB) -and ($null -ne $r.CFreiGB) -and ($null -ne $r.Status))
                $cpu = $r.CPU -as [double]; $ram = $r.RAMFreiMB -replace ',', '.' -as [double]; $c = $r.CFreiGB -replace ',', '.' -as [double]
                Pruefe "CPU plausibel 0-100 ($($r.CPU))" ($null -ne $cpu -and $cpu -ge 0 -and $cpu -le 100)
                Pruefe "RAMFreiMB plausibel ($([int]$ram) vs. echt $([int]$ramEcht))" ($null -ne $ram -and [math]::Abs($ram - $ramEcht) -le ($ramEcht * 0.3 + 300)) 'FreePhysicalMemory ist in KB'
                Pruefe "CFreiGB plausibel ($c vs. echt $([math]::Round($cEcht,1)))" ($null -ne $c -and [math]::Abs($c - $cEcht) -le 2) 'Free ist in Bytes -> / 1GB'
                $erw = if ($cEcht -lt 20) { 'WARNUNG' } else { 'OK' }
                Pruefe "Status bei Standard-Schwelle 20 GB = $erw" ($r.Status -eq $erw)
                Pruefe 'Status bei -SchwelleGB 999999 = WARNUNG' ($rows[2].Status -eq 'WARNUNG') 'param([int]$SchwelleGB = 20)'
            }
        }
    }
    4 {
        $md = Join-Path $dir 'patches.md'
        Pruefe 'patches.md existiert' (Test-Path $md)
        if (Test-Path $md) {
            $t = Get-Content $md -Raw
            $hf = @(Get-HotFix | Where-Object InstalledOn | Sort-Object InstalledOn)
            $kbs = @($hf | ForEach-Object HotFixID)
            $drin = @($kbs | Where-Object { $t -match $_ })
            Pruefe "Alle installierten Updates in der Tabelle ($($drin.Count)/$($kbs.Count))" ($drin.Count -eq $kbs.Count)
            if ($hf.Count) { Pruefe "Letztes Update korrekt ($($hf[-1].HotFixID))" ($t -match "Letztes Update:\s*$($hf[-1].HotFixID)") }
            Pruefe 'Tabelle vorhanden (|-Zeilen)' ($t -match '\|.*\|')
        }
    }
    5 {
        $t = Inhalt 'steckbrief.md'
        Pruefe 'steckbrief.md existiert' ($t -ne '')
        $os = Get-CimInstance Win32_OperatingSystem
        $netz = @(Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway })
        $ips = @($netz | ForEach-Object { $_.IPv4Address.IPAddress })
        $gws = @($netz | ForEach-Object { $_.IPv4DefaultGateway.NextHop })
        $dns = @($netz | ForEach-Object { $_.DNSServer.ServerAddresses } | Where-Object { $_ -match '^\d+\.' })
        $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
        Pruefe "Hostname ($env:COMPUTERNAME)" ($t -match "Hostname:\s*$env:COMPUTERNAME") 'hostname'
        Pruefe 'Betriebssystem' ($t -match ('Betriebssystem:.*' + [regex]::Escape(($os.Caption -replace 'Microsoft ', '')))) "Genau so: $($os.Caption -replace 'Microsoft ', '')"
        Pruefe 'IPv4-Adresse' (@($ips | Where-Object { $t -match "IPv4:.*$([regex]::Escape($_))" }).Count -gt 0) 'ipconfig: IPv4-Adresse des Adapters mit Gateway'
        Pruefe 'Gateway' (@($gws | Where-Object { $t -match "Gateway:.*$([regex]::Escape($_))" }).Count -gt 0) 'ipconfig: Standardgateway'
        Pruefe 'DNS-Server' (@($dns | Where-Object { $t -match "DNS:.*$([regex]::Escape($_))" }).Count -gt 0) 'ipconfig /all: DNS-Server'
        Pruefe "RAM GB (ca. $ram)" ($t -match 'RAM GB:\s*(\d+)' -and [math]::Abs([int]$Matches[1] - $ram) -le 1) 'TotalPhysicalMemory ist in Bytes -> / 1GB'
    }
    6 {
        $csv = Join-Path $dir 'netztest.csv'
        Pruefe 'netztest.csv existiert' (Test-Path $csv)
        if (Test-Path $csv) {
            $ist = @(Import-Csv $csv)
            foreach ($z in @(('www.microsoft.com', 443), ('1.1.1.1', 53), ('localhost', 3389), ('localhost', 445))) {
                $zeile = $ist | Where-Object { $_.Ziel -eq $z[0] -and "$($_.Port)" -eq "$($z[1])" } | Select-Object -First 1
                $echt = PortOffen $z[0] $z[1]
                Pruefe "$($z[0]):$($z[1]) -> erreichbar = $echt" ($zeile -and ((IstWahr $zeile.Erreichbar) -eq $echt)) 'Spalten genau: Ziel, Port, Erreichbar'
            }
        }
        $n = Inhalt 'notiz.md'
        Pruefe 'Port 3389 erklärt (RDP)' ($n -match 'RDP|Remotedesktop|Remote Desktop')
        Pruefe 'Port 445 erklärt (SMB)' ($n -match 'SMB|Datei|Freigabe')
    }
    7 {
        $csv = Join-Path $dir 'fehler.csv'
        Pruefe 'fehler.csv existiert' (Test-Path $csv)
        if (Test-Path $csv) {
            $ist = @(Import-Csv $csv | ForEach-Object { "$($_.ProviderName)|$($_.Id)" })
            $soll = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2 } -MaxEvents 10 -ErrorAction SilentlyContinue | ForEach-Object { "$($_.ProviderName)|$($_.Id)" })
            # shortcut: neue Fehler können seit dem Export dazugekommen sein, darum 2 Abweichungen Toleranz
            $treffer = @($soll | Where-Object { $ist -contains $_ }).Count
            Pruefe "Die letzten Fehler gefunden ($treffer von $($soll.Count))" ($ist.Count -gt 0 -and $treffer -ge ($soll.Count - 2)) 'Level = 2 heisst Fehler; -MaxEvents 10; Spalten ProviderName und Id'
            Pruefe 'Höchstens 10 Einträge' ($ist.Count -le 10)
        }
        $n = Inhalt 'notiz.md'
        Pruefe 'notiz.md mit Auswertung' ($n.Length -gt 50) 'Häufigste Quelle nennen und erklären'
    }
    8 {
        $csv = Join-Path $dir 'benutzer.csv'
        Pruefe 'benutzer.csv existiert' (Test-Path $csv)
        if (Test-Path $csv) {
            $ist = @(Import-Csv $csv)
            try { $admins = @(Get-LocalGroupMember -SID $SID_ADMINS | ForEach-Object { $_.SID.Value }) }
            catch { $admins = @(([ADSI]"WinNT://./$((New-Object Security.Principal.SecurityIdentifier $SID_ADMINS).Translate([Security.Principal.NTAccount]).Value.Split('\')[1]),group").Invoke('Members') | ForEach-Object { (New-Object Security.Principal.SecurityIdentifier ([byte[]]$_.GetType().InvokeMember('objectSid', 'GetProperty', $null, $_, $null)), 0).Value }) }
            foreach ($u in Get-LocalUser) {
                $zeile = $ist | Where-Object Name -eq $u.Name | Select-Object -First 1
                $istAdmin = $admins -contains $u.SID.Value
                Pruefe "$($u.Name): Aktiv=$($u.Enabled), Admin=$istAdmin" ($zeile -and (IstWahr $zeile.Aktiv) -eq $u.Enabled -and (IstWahr $zeile.Admin) -eq $istAdmin) 'Alle lokalen Benutzer, Spalten Name, Aktiv, Admin'
            }
        }
        Pruefe 'notiz.md mit Antwort' ((Inhalt 'notiz.md').Length -gt 30)
    }
    9 {
        $csv = Join-Path $dir 'software.csv'
        Pruefe 'software.csv existiert' (Test-Path $csv)
        if (Test-Path $csv) {
            $ist = @(Import-Csv $csv)
            $spalten = if ($ist.Count) { $ist[0].PSObject.Properties.Name } else { @() }
            Pruefe 'Spalten DisplayName, DisplayVersion, Publisher' (('DisplayName', 'DisplayVersion', 'Publisher' | Where-Object { $spalten -notcontains $_ }).Count -eq 0)
            $pfade = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
            $soll = @(Get-ItemProperty $pfade -ErrorAction SilentlyContinue | Where-Object DisplayName | ForEach-Object DisplayName | Sort-Object -Unique)
            $istN = @($ist | ForEach-Object DisplayName)
            $treffer = @($soll | Where-Object { $istN -contains $_ }).Count
            Pruefe "Programme gefunden ($treffer von $($soll.Count))" ($treffer -ge [math]::Floor($soll.Count * 0.9)) 'Alle 3 Registry-Pfade abfragen'
            Pruefe 'Keine leeren DisplayName' (@($ist | Where-Object { -not $_.DisplayName }).Count -eq 0) 'Where-Object DisplayName'
        }
        Pruefe 'notiz.md mit 3 Programmen' ((Inhalt 'notiz.md').Length -gt 50)
    }
    10 {
        $ti = Inhalt 'checkliste-titan.md'; $ws = Inhalt 'checkliste-ws01.md'
        Pruefe 'checkliste-titan.md existiert' ($ti -ne '')
        Pruefe 'checkliste-ws01.md existiert' ($ws -ne '')
        Pruefe 'Kästchen zum Abhaken' ($ti -match '\[ \]|\[x\]|☐' -and $ws -match '\[ \]|\[x\]|☐') "Schreib '- [ ] Aufgabe'"
        $punkte = @(
            @('titan', $ti, 'RAM (4 GB)', '4\s*GB'), @('titan', $ti, 'Prozessoren (2 CPU)', 'Prozessor|CPU'), @('titan', $ti, 'Netzwerkadapter intnet-lan', 'intnet'),
            @('titan', $ti, 'Gasterweiterungen', 'Gasterweiterung|Guest Additions'), @('titan', $ti, 'Servername', 'Servername|Hostname|Computername'),
            @('titan', $ti, 'Statische IP', 'statisch'), @('titan', $ti, 'Subnetzmaske', 'Subnetz|Maske'), @('titan', $ti, 'Gateway', 'Gateway'), @('titan', $ti, 'DNS (OPNsense)', 'DNS'),
            @('titan', $ti, 'Windows-Updates', 'Update'), @('titan', $ti, 'Rolle Druck- und Dokumentdienste', 'Druck-? ?und Dokument'), @('titan', $ti, 'Druckertreiber (PCL-6)', 'Treiber|PCL'),
            @('titan', $ti, 'Freigabe pr-office', 'pr-office'), @('titan', $ti, 'Internetzugriff testen', 'Internet'),
            @('ws01', $ws, 'VirtualBox-Einstellungen', 'RAM|Arbeitsspeicher|GB'), @('ws01', $ws, 'Netzwerkadapter intnet-lan', 'intnet'), @('ws01', $ws, 'Gasterweiterungen', 'Gasterweiterung|Guest Additions'),
            @('ws01', $ws, 'Computername ws01', 'ws01'), @('ws01', $ws, 'Statische IP (bis DHCP läuft)', 'statisch'), @('ws01', $ws, 'DNS (OPNsense)', 'OPNsense'),
            @('ws01', $ws, 'Nur lokales Administratorkonto aktiv', 'Administrator'), @('ws01', $ws, 'Andere Konten deaktivieren/löschen', 'deaktiv|lösch|entfern'),
            @('ws01', $ws, 'Windows-Updates', 'Update'), @('ws01', $ws, 'Internetzugriff testen', 'Internet|ping'),
            # Werte aus Betriebsdoku/Netzwerkplan Hotel Vier Winde
            @('titan', $ti, 'IP 172.18.20.120', '172\.18\.20\.120'), @('titan', $ti, 'Maske 255.255.255.192 (/26)', '255\.255\.255\.192|/26'),
            @('titan', $ti, 'Gateway und DNS = OPNsense 172.18.20.65', '172\.18\.20\.65'), @('titan', $ti, 'Druckermodell HP X58045z', 'X58045'),
            @('ws01', $ws, 'Statische IP im Client-Bereich .66 - .115', '172\.18\.20\.(6[6-9]|[7-9]\d|10\d|11[0-5])\b'), @('ws01', $ws, 'Maske 255.255.255.192 (/26)', '255\.255\.255\.192|/26'),
            @('ws01', $ws, 'Gateway und DNS 172.18.20.65', '172\.18\.20\.65'), @('ws01', $ws, 'Tool Firefox', 'Firefox'), @('ws01', $ws, 'Tool Notepad++', 'Notepad\+\+')
        )
        foreach ($p in $punkte) { Pruefe "$($p[0]): $($p[2])" ($p[1] -match $p[3]) }
    }
    11 {
        $t = Inhalt 'spooler.md'
        Pruefe 'spooler.md existiert' ($t -ne '')
        $svc = Get-Service Spooler
        $start = @{ Automatic = 'Automati'; Manual = 'Manu'; Disabled = 'Deaktiv|Disabled' }["$($svc.StartType)"]
        $status = @{ Running = 'Running|Läuft|Wird ausgeführt|Gestartet'; Stopped = 'Stopped|Beendet|Gestoppt' }["$($svc.Status)"]
        Pruefe 'Anzeigename (Druckwarteschlange)' ($t -match [regex]::Escape($svc.DisplayName))
        Pruefe "Starttyp ($($svc.StartType))" ($t -match $start)
        Pruefe "Status ($($svc.Status))" ($t -match $status)
        foreach ($d in $svc.ServicesDependedOn) { Pruefe "Abhängigkeit $($d.Name)" ($t -match [regex]::Escape($d.Name)) 'ServicesDependedOn' }
        Pruefe 'Pfad zu spoolsv.exe' ($t -match 'spoolsv\.exe') 'Win32_Service -> PathName'
        Pruefe 'Sicherheitsrisiko erklärt' ($t -match 'PrintNightmare' -and $t.Length -gt 200) 'Was war PrintNightmare (2021)?'
    }
    12 {
        Pruefe 'Lab 3 vorhanden (L3\monitor.ps1)' (Test-Path (Join-Path $LabPfad 'L3\monitor.ps1')) 'Zuerst Lab 3 lösen'
        $task = Get-ScheduledTask -TaskName 'Lab188-Monitor' -ErrorAction SilentlyContinue
        Pruefe 'Geplante Aufgabe Lab188-Monitor existiert' ($null -ne $task) 'Register-ScheduledTask -TaskName Lab188-Monitor ...'
        if ($task) {
            $a = $task.Actions | Select-Object -First 1
            Pruefe 'Startet powershell.exe' ($a.Execute -match 'powershell')
            Pruefe 'Mit L3\monitor.ps1' ($a.Arguments -match 'monitor\.ps1') '-Argument "-File C:\...\L3\monitor.ps1"'
            $iv = @($task.Triggers | ForEach-Object { $_.Repetition.Interval })
            Pruefe 'Alle 15 Minuten' ($iv -contains 'PT15M') '-RepetitionInterval (New-TimeSpan -Minutes 15)'
            Pruefe 'Aufgabe ist aktiviert' ($task.State -ne 'Disabled')
        }
    }
    13 {
        $t = Inhalt 'netz.md'
        Pruefe 'netz.md existiert' ($t -ne '')
        $soll = [ordered]@{ 'Subnetzmaske' = '255.255.254.0'; 'Netzadresse' = '10.20.30.0'; 'Broadcast' = '10.20.31.255'; 'Erster Host' = '10.20.30.1'; 'Letzter Host' = '10.20.31.254'; 'Anzahl Hosts' = '510'; 'Hotel DHCP-Adressen' = '50' }
        $tipps = @{ 'Subnetzmaske' = '/23 = 23 Einsen'; 'Broadcast' = '/23 umfasst 2 x 256 Adressen'; 'Anzahl Hosts' = '2^(32-23) - 2'; 'Hotel DHCP-Adressen' = 'Von 66 bis 115, beide mitgezählt' }
        foreach ($k in $soll.Keys) { Pruefe "$k = ?" ($t -match "$k\s*:\s*$([regex]::Escape($soll[$k]))(\s|$)") $tipps[$k] }
        Pruefe '172.18.20.130 im Hotelnetz = ?' ($t -match '172\.18\.20\.130 im Hotelnetz:\s*Nein') '/26 = 64 Adressen ab .64'
    }
    14 {
        $csv = Join-Path $dir 'berechtigungen.csv'
        Pruefe 'berechtigungen.csv existiert' (Test-Path $csv)
        if (Test-Path $csv) {
            # Abteilungen kurz: GL, AD, FO, BO, FB, CO, HK, TE (Tabelle aus der Betriebsdoku, Kap. 5.10)
            $matrix = [ordered]@{
                'austausch' = 'GL AD FO BO FB CO HK TE'; 'front-office' = 'GL FO'; 'bo' = 'GL BO'; 'administration' = 'GL AD FB CO'; 'conv' = 'GL FB CO'; 'fobe' = 'GL CO'
                'saal' = 'GL AD FO BO CO TE'; 'bar' = 'GL AD FO BO FB CO TE'; 'sitzungen' = 'GL AD FO BO CO TE'; 'bueros' = 'GL AD FO BO CO TE'; 'pr-office' = 'GL AD FO BO FB CO HK TE'
            }
            function Abt($a) { switch -Regex ($a) { 'Gesch' { 'GL' } 'Admin' { 'AD' } 'Front' { 'FO' } 'Back' { 'BO' } 'Food|F&B' { 'FB' } 'Conv' { 'CO' } 'House' { 'HK' } 'Tech' { 'TE' } } }
            $ist = @(Import-Csv $csv | Where-Object { $_.Recht -match '[SD]' } | ForEach-Object { "$($_.Freigabe.Trim().ToLower() -replace 'ü','ue')|$(Abt $_.Abteilung)" })
            foreach ($f in $matrix.Keys) {
                $sollF = @($matrix[$f].Split(' ') | ForEach-Object { "$f|$_" })
                $istF = @($ist | Where-Object { $_ -like "$f|*" })
                $passt = (@($sollF | Where-Object { $istF -notcontains $_ }).Count -eq 0) -and (@($istF | Where-Object { $sollF -notcontains $_ }).Count -eq 0)
                Pruefe "Freigabe $f" $passt "Soll: $($matrix[$f])"
            }
        }
        $n = Inhalt 'notiz.md'
        Pruefe 'AGDLP für Austausch erklärt' ($n -match 'global|GG_|G_' -and $n -match 'lokal|DL_' ) 'Benutzer -> Globale Gruppe (pro Abteilung) -> Domänenlokale Gruppe (pro Freigabe + Recht) -> Berechtigung'
    }
    15 {
        $csv = Join-Path $dir 'benutzer.csv'
        Pruefe 'benutzer.csv existiert' (Test-Path $csv)
        if (Test-Path $csv) {
            $logins = @('sandel', 'paumic', 'stefuc', 'thokni', 'gerbae', 'Leobru', 'simtau', 'petzac', 'norber', 'sanmar', 'Danber', 'thokro', 'stemei', 'thokle', 'Benkra', 'antber', 'petweb', 'Stetra', 'girpol', 'gerber', 'piaman', 'andkav', 'dandse', 'petdel', 'nicber')
            $ist = @(Import-Csv $csv | ForEach-Object { $_.Login })
            $fehlt = @($logins | Where-Object { $ist -notcontains $_ })
            Pruefe "Alle Benutzer erfasst ($($logins.Count - $fehlt.Count) von $($logins.Count) Logins)" ($fehlt.Count -eq 0) "Es fehlen z. B.: $($fehlt | Select-Object -First 3)"
        }
        Pruefe 'pruefen.ps1 existiert' (Test-Path (Join-Path $dir 'pruefen.ps1'))
        $abw = @((Inhalt 'abweichungen.txt') -split '\r?\n' | ForEach-Object Trim | Where-Object { $_ })
        foreach ($a in 'thokni', 'dandse', 'Leobru', 'Danber', 'Benkra', 'Stetra') { Pruefe "Abweichung $a gefunden" ($abw -ccontains $a) }
        $falsch = @($abw | Where-Object { 'thokni', 'dandse', 'Leobru', 'Danber', 'Benkra', 'Stetra' -cnotcontains $_ })
        Pruefe 'Keine korrekten Logins als Abweichung gemeldet' ($falsch.Count -eq 0) "Diese sind korrekt: $($falsch -join ', ')"
    }
}

Write-Host "`nErgebnis: $script:ok von $($script:ok + $script:fail) Punkten" -ForegroundColor Cyan
if ($script:fail -eq 0) { Write-Host 'Lab bestanden! Jetzt kurz einen Arbeitsbericht in Obsidian schreiben.' -ForegroundColor Green }
