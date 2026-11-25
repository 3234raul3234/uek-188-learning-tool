# Fenster für lab188.ps1: Lab wählen, starten, Ordner öffnen, prüfen
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
$lab = Join-Path $PSScriptRoot 'lab188.ps1'
$cfg = Join-Path (Split-Path $PSScriptRoot) 'unterlagen-pfad.txt'  # optional, lokal (nicht im Repo): Ordner mit Lernkarten
$vault = if (Test-Path $cfg) { (Get-Content $cfg -Raw -Encoding UTF8).Trim() } else { '' }
$root = if (Test-Path 'C:\UEK188\Uebungen') { 'C:\UEK188\Uebungen' } else { Join-Path $env:USERPROFILE 'Lab188' }

function Lab($aktion, $nr) { & powershell -NoProfile -ExecutionPolicy Bypass -File $lab $aktion $nr 2>&1 | ForEach-Object { "$_" } }
function C($hex) { [Drawing.ColorTranslator]::FromHtml($hex) }
function F($groesse, $stil = 'Regular', $name = 'Segoe UI') { New-Object Drawing.Font($name, $groesse, [Drawing.FontStyle]$stil) }
function Status($n) { if (Test-Path (Join-Path $root "L$n\.bestanden")) { 'bestanden' } elseif (Test-Path (Join-Path $root "L$n")) { 'gestartet' } else { 'neu' } }

$blau = C '#2563EB'; $gruen = C '#16A34A'; $grau = C '#9CA3AF'; $hell = C '#F3F4F6'; $dunkel = C '#111827'
$labs = Lab list 1 | Where-Object { $_ -match '^(\d+)\s+(.*?)\s*\((HZ.*)\)' } | ForEach-Object { @{ Titel = $Matches[2]; HZ = $Matches[3] -replace 'HZ', 'Handlungsziel' } }

$form = New-Object Windows.Forms.Form -Property @{ Text = 'Lab-Trainer ÜK 188'; Size = '1120,720'; MinimumSize = '900,560'; StartPosition = 'CenterScreen'; BackColor = $hell; Font = (F 10) }

# Kopfzeile
$kopf = New-Object Windows.Forms.Panel -Property @{ Dock = 'Top'; Height = 80; Width = $form.ClientSize.Width; BackColor = (C '#1E3A8A') }  # Breite vorab, sonst landen die rechts verankerten Knöpfe ausserhalb
$kopf.Controls.Add((New-Object Windows.Forms.Label -Property @{ Text = 'Lab-Trainer ÜK 188'; Font = (F 20 'Bold'); ForeColor = 'White'; Location = '24,10'; AutoSize = $true }))
$kopf.Controls.Add((New-Object Windows.Forms.Label -Property @{ Text = 'Services betreiben, warten und überwachen'; Font = (F 10); ForeColor = (C '#BFDBFE'); Location = '28,50'; AutoSize = $true }))
$fortschritt = New-Object Windows.Forms.Label -Property @{ Font = (F 12 'Bold'); ForeColor = 'White'; TextAlign = 'MiddleRight'; Size = '260,80'; Dock = 'Right'; Padding = '0,0,24,0' }
$kopf.Controls.Add($fortschritt)

# Lab-Karten links
$liste = New-Object Windows.Forms.ListBox -Property @{ Location = '20,100'; Size = '360,560'; Anchor = 'Top,Bottom,Left'; DrawMode = 'OwnerDrawFixed'; ItemHeight = 70; BorderStyle = 'None'; BackColor = $hell; IntegralHeight = $false }
$labs | ForEach-Object { [void]$liste.Items.Add($_.Titel) }
$liste.Add_DrawItem({
        param($s, $e)
        if ($e.Index -lt 0) { return }
        $g = $e.Graphics; $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'ClearTypeGridFit'
        $n = $e.Index + 1; $st = Status $n; $l = $labs[$e.Index]
        $sel = ($e.State -band [Windows.Forms.DrawItemState]::Selected) -ne 0
        $r = $e.Bounds
        $g.FillRectangle((New-Object Drawing.SolidBrush $hell), $r)
        $karte = New-Object Drawing.Rectangle $r.X, ($r.Y + 5), ($r.Width - 8), ($r.Height - 10)
        $g.FillRectangle((New-Object Drawing.SolidBrush $(if ($sel) { C '#EFF6FF' } else { [Drawing.Color]::White })), $karte)
        if ($sel) { $g.FillRectangle((New-Object Drawing.SolidBrush $blau), $karte.X, $karte.Y, 5, $karte.Height) }
        $farbe = switch ($st) { 'bestanden' { $gruen } 'gestartet' { $blau } default { $grau } }
        $kreis = New-Object Drawing.Rectangle ($karte.X + 18), ($karte.Y + 12), 36, 36
        $g.FillEllipse((New-Object Drawing.SolidBrush $farbe), $kreis)
        $mitte = New-Object Drawing.StringFormat -Property @{ Alignment = 'Center'; LineAlignment = 'Center' }
        $symbol = if ($st -eq 'bestanden') { [string][char]0x2713 } else { "$n" }
        $g.DrawString($symbol, (F 11.5 'Bold'), [Drawing.Brushes]::White, [Drawing.RectangleF]$kreis, $mitte)
        $g.DrawString($l.Titel, (F 10.5 'Bold'), (New-Object Drawing.SolidBrush $dunkel), ($karte.X + 68), ($karte.Y + 9))
        $info = "$($l.HZ)  ·  " + @{ bestanden = 'Bestanden'; gestartet = 'In Arbeit'; neu = 'Noch nicht gestartet' }[$st]
        $g.DrawString($info, (F 9), (New-Object Drawing.SolidBrush $farbe), ($karte.X + 68), ($karte.Y + 33))
    })

# Ausgabe rechts
$rahmen = New-Object Windows.Forms.Panel -Property @{ Location = '400,100'; Size = '690,490'; Anchor = 'Top,Bottom,Left,Right'; BackColor = 'White'; Padding = '20,16,20,16' }
$text = New-Object Windows.Forms.RichTextBox -Property @{ Dock = 'Fill'; ReadOnly = $true; BorderStyle = 'None'; BackColor = 'White'; Font = (F 10.5 'Regular' 'Consolas'); ForeColor = $dunkel }
$rahmen.Controls.Add($text)

function Zeige($zeilen) {
    $text.Clear()
    foreach ($z in $zeilen) {
        if ($z -match 'Fertig\? ->') { $z = 'Fertig? Klick auf "Prüfen".' }
        $text.SelectionFont = if ($z -match '^===|^Ergebnis') { F 12 'Bold' } else { F 10.5 'Regular' 'Consolas' }
        $text.SelectionColor = if ($z -match '^\[OK\]|bestanden') { $gruen } elseif ($z -match '^\[X\]') { C '#DC2626' } elseif ($z -match 'Tipp:') { C '#D97706' } elseif ($z -match '^===|^Ergebnis|Fertig\?') { $blau } else { $dunkel }
        $text.AppendText("$z`n")
    }
}
function Willkommen {
    $text.Clear()
    $text.SelectionFont = F 16 'Bold'; $text.SelectionColor = $dunkel; $text.AppendText("Willkommen!`n`n")
    $text.SelectionFont = F 11; $text.SelectionColor = (C '#4B5563')
    $text.AppendText("1.  Links ein Lab auswählen`n2.  ""Lab starten"" zeigt dir den Auftrag`n3.  ""Ordner öffnen"" und die Aufgabe lösen`n4.  ""Prüfen"" kontrolliert dein Ergebnis`n5.  ""Doku erstellen"" macht dir einen Abschnitt für die Moodle-Dokumentation`n`nOben rechts: ""Quiz"" fragt dich die Lernkarten ab.")
}
function Aktualisiere {
    $fertig = @(1..$labs.Count | Where-Object { (Status $_) -eq 'bestanden' }).Count
    $fortschritt.Text = "$fertig von $($labs.Count) bestanden"
    $liste.Invalidate()
}
function Nr { if ($liste.SelectedIndex -lt 0) { [Windows.Forms.MessageBox]::Show('Wähle zuerst links ein Lab aus.', 'Lab-Trainer') | Out-Null; return $null }; $liste.SelectedIndex + 1 }

function Meldung($t) { [Windows.Forms.MessageBox]::Show($t, 'Lab-Trainer') | Out-Null }
function Knopf($titel, $farbe, $rechts, $aktion) {
    $b = New-Object Windows.Forms.Button -Property @{ Text = $titel; Size = '160,46'; FlatStyle = 'Flat'; BackColor = $farbe; ForeColor = 'White'; Font = (F 10.5 'Bold'); Cursor = 'Hand'; Anchor = 'Bottom,Right' }
    $b.FlatAppearance.BorderSize = 0
    $b.Location = New-Object Drawing.Point ($form.ClientSize.Width - $rechts), ($form.ClientSize.Height - 66)
    $b.Add_Click($aktion); $form.Controls.Add($b)
}
Knopf 'Lab starten' $blau 690 { $n = Nr; if ($n) { Zeige (Lab start $n); Aktualisiere } }
Knopf 'Ordner öffnen' (C '#4B5563') 520 { $n = Nr; if ($n) { $p = Join-Path $root "L$n"; if (Test-Path $p) { explorer.exe $p } else { Meldung 'Starte das Lab zuerst.' } } }
Knopf 'Prüfen' $gruen 350 {
    $n = Nr; if (-not $n) { return }
    if ((Status $n) -eq 'neu') { Meldung 'Starte das Lab zuerst.'; return }
    $form.Cursor = 'WaitCursor'; $aus = Lab check $n; $form.Cursor = 'Default'
    $marke = Join-Path $root "L$n\.bestanden"
    if ($aus -match 'Lab bestanden') { New-Item -ItemType File $marke -Force | Out-Null } else { Remove-Item $marke -ErrorAction SilentlyContinue }
    Zeige $aus; Aktualisiere
}
Knopf 'Doku erstellen' (C '#7C3AED') 180 {
    $n = Nr; if (-not $n) { return }
    if ((Status $n) -eq 'neu') { Meldung 'Starte das Lab zuerst.'; return }
    $form.Cursor = 'WaitCursor'; $aus = Lab doku $n; $form.Cursor = 'Default'
    $datei = ($aus | Where-Object { $_ -match '^Doku gespeichert: (.+)' } | ForEach-Object { $Matches[1] }) | Select-Object -First 1
    if (-not $datei) { Zeige $aus; return }
    Set-Clipboard -Value (Get-Content $datei -Raw -Encoding UTF8)
    Start-Process notepad.exe $datei
    Zeige @("=== Doku für Lab $n erstellt ===", '', "Gespeichert: $datei", '', '[OK] Der Text ist in der Zwischenablage: in Word oder Obsidian einfügen (Ctrl+V).', '', 'Tipp: Ergänze einen Screenshot und schreib unter "Was ich gelernt habe" 2-3 Sätze.')
}

# Quiz mit den Lernkarten: was du nicht weisst, kommt öfter
function Quiz {
    $datei = @((Join-Path (Split-Path $PSScriptRoot) 'Unterlagen\ÜK 188 Lernkarten.md'), "$vault\ÜK 188 Lernkarten.md") | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $datei) { Meldung 'Lernkarten nicht gefunden.'; return }
    $karten = @(); $akt = $null
    foreach ($z in Get-Content $datei -Encoding UTF8) {
        if ($z -match '^> \[!question\]-\s*(.+)') { $akt = [pscustomobject]@{ Frage = $Matches[1]; Antwort = '' }; $karten += $akt }
        elseif ($akt -and $z -match '^> ?(.*)') { $akt.Antwort += ($Matches[1] -replace '\*\*|`', '') + "`r`n" }
        else { $akt = $null }
    }
    $statDatei = Join-Path $root 'quiz.csv'
    New-Item -ItemType Directory $root -Force | Out-Null
    $stat = @{}; if (Test-Path $statDatei) { Import-Csv $statDatei | ForEach-Object { $stat[$_.Frage] = [pscustomobject]@{ Frage = $_.Frage; Richtig = [int]$_.Richtig; Falsch = [int]$_.Falsch } } }
    foreach ($k in $karten) { if (-not $stat[$k.Frage]) { $stat[$k.Frage] = [pscustomobject]@{ Frage = $k.Frage; Richtig = 0; Falsch = 0 } } }
    $runde = New-Object Collections.ArrayList
    $karten | Sort-Object { $stat[$_.Frage].Falsch - $stat[$_.Frage].Richtig }, { Get-Random } -Descending | Select-Object -First 10 | ForEach-Object { [void]$runde.Add($_) }
    $q = @{ i = 0; richtig = 0; nochmal = @{} }

    $qf = New-Object Windows.Forms.Form -Property @{ Text = 'Quiz ÜK 188'; Size = '760,520'; StartPosition = 'CenterParent'; BackColor = 'White'; Font = (F 11); FormBorderStyle = 'FixedDialog'; MaximizeBox = $false }
    $stand = New-Object Windows.Forms.Label -Property @{ Location = '30,20'; Size = '680,24'; ForeColor = $grau; Font = (F 10 'Bold') }
    $frage = New-Object Windows.Forms.Label -Property @{ Location = '30,50'; Size = '680,90'; Font = (F 15 'Bold'); ForeColor = $dunkel }
    $antwort = New-Object Windows.Forms.Label -Property @{ Location = '30,150'; Size = '680,220'; Font = (F 11); ForeColor = (C '#374151'); BackColor = (C '#F0FDF4'); Padding = '12,12,12,12'; Visible = $false }
    function QKnopf($t, $farbe, $x) { $b = New-Object Windows.Forms.Button -Property @{ Text = $t; Location = "$x,395"; Size = '220,46'; FlatStyle = 'Flat'; BackColor = $farbe; ForeColor = 'White'; Font = (F 10.5 'Bold'); Cursor = 'Hand' }; $b.FlatAppearance.BorderSize = 0; $qf.Controls.Add($b); $b }
    $zeigen = QKnopf 'Antwort zeigen' $blau 260
    $ja = QKnopf 'Gewusst' $gruen 140
    $nein = QKnopf 'Nicht gewusst' (C '#DC2626') 380
    $qf.Controls.AddRange(@($stand, $frage, $antwort))
    $weiter = {
        if ($q.i -ge $runde.Count) {
            $stat.Values | Export-Csv $statDatei -NoTypeInformation -Encoding UTF8
            Meldung "Fertig! $($q.richtig) von $($runde.Count) Antworten gewusst.`n`nWas du nicht wusstest, kommt beim nächsten Quiz zuerst."
            $qf.Close(); return
        }
        $stand.Text = "Frage $($q.i + 1) von $($runde.Count)   ·   $($q.richtig) gewusst"
        $frage.Text = $runde[$q.i].Frage; $antwort.Text = $runde[$q.i].Antwort
        $antwort.Visible = $false; $zeigen.Visible = $true; $ja.Visible = $false; $nein.Visible = $false
    }
    $zeigen.Add_Click({ $antwort.Visible = $true; $zeigen.Visible = $false; $ja.Visible = $true; $nein.Visible = $true })
    $ja.Add_Click({ $stat[$runde[$q.i].Frage].Richtig++; $q.richtig++; $q.i++; & $weiter })
    $nein.Add_Click({
            $k = $runde[$q.i]; $stat[$k.Frage].Falsch++
            if (-not $q.nochmal[$k.Frage]) { $q.nochmal[$k.Frage] = $true; [void]$runde.Add($k) }  # am Ende der Runde nochmals
            $q.i++; & $weiter
        })
    & $weiter
    [void]$qf.ShowDialog($form)
}

# VM-Steuerung, nur auf dem Host (VMware lässt sich nur von aussen steuern)
$vmx = 'C:\UEK188\VM\UEK188-Win11Edu.vmx'; $vmrun = 'C:\Program Files\VMware\VMware Workstation\vmrun.exe'
function VmGast { $pw = (Get-Content 'C:\UEK188\Setup\Zugangsdaten.txt' | Where-Object { $_ -match '^Passwort:\s*(.+)' } | ForEach-Object { $Matches[1].Trim() }); @('-T', 'ws', '-gu', 'Administrator', '-gp', $pw) }
function VmAktualisieren {
    $g = VmGast; $quelle = $vault
    $dateien = @(Get-ChildItem "$PSScriptRoot\*.ps1" | ForEach-Object { , @($_.FullName, "C:\UEK188\Lab\$($_.Name)") })
    foreach ($u in "$quelle\ÜK 188 Lernkarten.md", "$quelle\Hotel Vier Winde.md", "$quelle\..\..\..\99 Vorlagen\Arbeitsbericht.md") { if (Test-Path $u) { $dateien += , @($u, "C:\UEK188\Unterlagen\$(Split-Path $u -Leaf)") } }
    $fehler = 0
    foreach ($d in $dateien) { & $vmrun @g CopyFileFromHostToGuest $vmx $d[0] $d[1] | Out-Null; if ($LASTEXITCODE) { $fehler++ } }
    if ($fehler) { "VM aktualisieren: $fehler von $($dateien.Count) Dateien fehlgeschlagen (läuft die VM?)" } else { "VM aktualisiert: $($dateien.Count) Dateien" }
}
function KopfKnopf($t, $x, $aktion) {
    $b = New-Object Windows.Forms.Button -Property @{ Text = $t; Size = '150,36'; FlatStyle = 'Flat'; BackColor = (C '#1E40AF'); ForeColor = 'White'; Font = (F 10 'Bold'); Cursor = 'Hand'; Anchor = 'Top,Right' }
    $b.FlatAppearance.BorderColor = (C '#60A5FA')
    $b.Location = New-Object Drawing.Point ($form.ClientSize.Width - $x), 22
    $b.Add_Click($aktion); $kopf.Controls.Add($b); $b.BringToFront()
}
KopfKnopf 'Quiz' 430 { Quiz }
if (-not (Test-Path 'C:\UEK188\Uebungen') -and (Test-Path $vmx)) {
    KopfKnopf 'VM aktualisieren' 590 { $form.Cursor = 'WaitCursor'; $m = VmAktualisieren; $form.Cursor = 'Default'; Zeige @('=== VM ===', '', $m) }
    KopfKnopf 'VM zurücksetzen' 750 {
        $ok = [Windows.Forms.MessageBox]::Show("Die VM wird auf den frischen Zustand (Snapshot 'Frisch') zurückgesetzt.`nAlle Übungen IN DER VM gehen verloren.`n`nWeiter?", 'VM zurücksetzen', 'YesNo', 'Warning')
        if ($ok -ne 'Yes') { return }
        $form.Cursor = 'WaitCursor'
        & $vmrun -T ws revertToSnapshot $vmx Frisch | Out-Null; $r1 = $LASTEXITCODE
        & $vmrun -T ws start $vmx gui | Out-Null
        foreach ($i in 1..30) { if ((& $vmrun -T ws checkToolsState $vmx) -eq 'running') { break }; Start-Sleep 3 }
        $m = VmAktualisieren
        $form.Cursor = 'Default'
        Zeige @('=== VM zurückgesetzt ===', '', $(if ($r1) { '[X] Snapshot "Frisch" nicht gefunden' } else { '[OK] Snapshot "Frisch" wiederhergestellt' }), $m)
    }
}

$form.Controls.AddRange(@($liste, $rahmen, $kopf))
Willkommen; Aktualisiere
[void]$form.ShowDialog()
