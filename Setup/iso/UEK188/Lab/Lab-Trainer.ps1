# Fenster für lab188.ps1: Lab wählen, starten, Ordner öffnen, prüfen
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
$lab = Join-Path $PSScriptRoot 'lab188.ps1'
$root = if (Test-Path 'C:\UEK188\Uebungen') { 'C:\UEK188\Uebungen' } else { Join-Path $env:USERPROFILE 'Lab188' }

function Lab($aktion, $nr) { & powershell -NoProfile -ExecutionPolicy Bypass -File $lab $aktion $nr 2>&1 | ForEach-Object { "$_" } }
function C($hex) { [Drawing.ColorTranslator]::FromHtml($hex) }
function F($groesse, $stil = 'Regular', $name = 'Segoe UI') { New-Object Drawing.Font($name, $groesse, [Drawing.FontStyle]$stil) }
function Status($n) { if (Test-Path (Join-Path $root "L$n\.bestanden")) { 'bestanden' } elseif (Test-Path (Join-Path $root "L$n")) { 'gestartet' } else { 'neu' } }

$blau = C '#2563EB'; $gruen = C '#16A34A'; $grau = C '#9CA3AF'; $hell = C '#F3F4F6'; $dunkel = C '#111827'
$labs = Lab list 1 | Where-Object { $_ -match '^(\d+)\s+(.*?)\s*\((HZ.*)\)' } | ForEach-Object { @{ Titel = $Matches[2]; HZ = $Matches[3] -replace 'HZ', 'Handlungsziel' } }

$form = New-Object Windows.Forms.Form -Property @{ Text = 'Lab-Trainer ÜK 188'; Size = '1120,720'; MinimumSize = '900,560'; StartPosition = 'CenterScreen'; BackColor = $hell; Font = (F 10) }

# Kopfzeile
$kopf = New-Object Windows.Forms.Panel -Property @{ Dock = 'Top'; Height = 80; BackColor = (C '#1E3A8A') }
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
    $text.AppendText("1.  Links ein Lab auswählen`n2.  ""Lab starten"" zeigt dir den Auftrag`n3.  ""Ordner öffnen"" und die Aufgabe lösen`n4.  ""Prüfen"" kontrolliert dein Ergebnis")
}
function Aktualisiere {
    $fertig = @(1..$labs.Count | Where-Object { (Status $_) -eq 'bestanden' }).Count
    $fortschritt.Text = "$fertig von $($labs.Count) bestanden"
    $liste.Invalidate()
}
function Nr { if ($liste.SelectedIndex -lt 0) { [Windows.Forms.MessageBox]::Show('Wähle zuerst links ein Lab aus.', 'Lab-Trainer') | Out-Null; return $null }; $liste.SelectedIndex + 1 }

function Knopf($titel, $farbe, $rechts, $aktion) {
    $b = New-Object Windows.Forms.Button -Property @{ Text = $titel; Size = '210,46'; FlatStyle = 'Flat'; BackColor = $farbe; ForeColor = 'White'; Font = (F 10.5 'Bold'); Cursor = 'Hand'; Anchor = 'Bottom,Right' }
    $b.FlatAppearance.BorderSize = 0
    $b.Location = New-Object Drawing.Point ($form.ClientSize.Width - $rechts), ($form.ClientSize.Height - 66)
    $b.Add_Click($aktion); $form.Controls.Add($b)
}
Knopf 'Lab starten' $blau 690 { $n = Nr; if ($n) { Zeige (Lab start $n); Aktualisiere } }
Knopf 'Ordner öffnen' (C '#4B5563') 466 { $n = Nr; if ($n) { $p = Join-Path $root "L$n"; if (Test-Path $p) { explorer.exe $p } else { [Windows.Forms.MessageBox]::Show('Starte das Lab zuerst.', 'Lab-Trainer') | Out-Null } } }
Knopf 'Prüfen' $gruen 242 {
    $n = Nr; if (-not $n) { return }
    if ((Status $n) -eq 'neu') { [Windows.Forms.MessageBox]::Show('Starte das Lab zuerst.', 'Lab-Trainer') | Out-Null; return }
    $form.Cursor = 'WaitCursor'; $aus = Lab check $n; $form.Cursor = 'Default'
    $marke = Join-Path $root "L$n\.bestanden"
    if ($aus -match 'Lab bestanden') { New-Item -ItemType File $marke -Force | Out-Null } else { Remove-Item $marke -ErrorAction SilentlyContinue }
    Zeige $aus; Aktualisiere
}

$form.Controls.AddRange(@($liste, $rahmen, $kopf))
Willkommen; Aktualisiere
[void]$form.ShowDialog()
