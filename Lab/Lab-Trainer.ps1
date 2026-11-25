# Window for lab188.ps1: choose, start, open folder, check
$version = 'Beta 0.5'  # increase with every change and add to CHANGELOG.md
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
$lab = Join-Path $PSScriptRoot 'lab188.ps1'
$root = if (Test-Path 'C:\UEK188\Uebungen') { 'C:\UEK188\Uebungen' } else { Join-Path $env:USERPROFILE 'Lab188' }

function Lab($action, $no) { & powershell -NoProfile -ExecutionPolicy Bypass -File $lab $action $no 2>&1 | ForEach-Object { "$_" } }
function C($hex) { [Drawing.ColorTranslator]::FromHtml($hex) }
function F($size, $style = 'Regular', $name = 'Segoe UI') { New-Object Drawing.Font($name, $size, [Drawing.FontStyle]$style) }
# '.bestanden' = marker of older versions
function Status($n) { if ((Test-Path (Join-Path $root "L$n\.passed")) -or (Test-Path (Join-Path $root "L$n\.bestanden"))) { 'passed' } elseif (Test-Path (Join-Path $root "L$n")) { 'started' } else { 'new' } }

$blue = C '#2563EB'; $green = C '#16A34A'; $grey = C '#9CA3AF'; $light = C '#F3F4F6'; $dark = C '#111827'
$labs = Lab list 1 | Where-Object { $_ -match '^(\d+)\s+(.*?)\s*\((OBJ.*)\)' } | ForEach-Object { @{ Title = $Matches[2]; Obj = $Matches[3] -replace 'OBJ', 'Objective' } }

$form = New-Object Windows.Forms.Form -Property @{ Text = "Lab Trainer UEK 188 – $version"; Size = '1120,720'; MinimumSize = '1120,640'; StartPosition = 'CenterScreen'; BackColor = $light; Font = (F 10) }

# Header
$head = New-Object Windows.Forms.Panel -Property @{ Dock = 'Top'; Height = 80; Width = $form.ClientSize.Width; BackColor = (C '#1E3A8A') }  # width up front, otherwise right-anchored buttons end up outside
$head.Controls.Add((New-Object Windows.Forms.Label -Property @{ Text = 'Lab Trainer UEK 188'; Font = (F 20 'Bold'); ForeColor = 'White'; Location = '24,10'; AutoSize = $true }))
$head.Controls.Add((New-Object Windows.Forms.Label -Property @{ Text = 'Operate, maintain and monitor services'; Font = (F 10); ForeColor = (C '#BFDBFE'); Location = '28,50'; AutoSize = $true }))
$progress = New-Object Windows.Forms.Label -Property @{ Font = (F 12 'Bold'); ForeColor = 'White'; TextAlign = 'MiddleRight'; Size = '210,80'; Dock = 'Right'; Padding = '0,0,20,0' }
$head.Controls.Add($progress)

# Lab cards on the left
$list = New-Object Windows.Forms.ListBox -Property @{ Location = '20,100'; Size = '360,560'; Anchor = 'Top,Bottom,Left'; DrawMode = 'OwnerDrawFixed'; ItemHeight = 70; BorderStyle = 'None'; BackColor = $light; IntegralHeight = $false }
$labs | ForEach-Object { [void]$list.Items.Add($_.Title) }
$list.Add_DrawItem({
        param($s, $e)
        if ($e.Index -lt 0) { return }
        $g = $e.Graphics; $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'ClearTypeGridFit'
        $n = $e.Index + 1; $st = Status $n; $l = $labs[$e.Index]
        $sel = ($e.State -band [Windows.Forms.DrawItemState]::Selected) -ne 0
        $r = $e.Bounds
        $g.FillRectangle((New-Object Drawing.SolidBrush $light), $r)
        $card = New-Object Drawing.Rectangle $r.X, ($r.Y + 5), ($r.Width - 8), ($r.Height - 10)
        $g.FillRectangle((New-Object Drawing.SolidBrush $(if ($sel) { C '#EFF6FF' } else { [Drawing.Color]::White })), $card)
        if ($sel) { $g.FillRectangle((New-Object Drawing.SolidBrush $blue), $card.X, $card.Y, 5, $card.Height) }
        $colour = switch ($st) { 'passed' { $green } 'started' { $blue } default { $grey } }
        $circle = New-Object Drawing.Rectangle ($card.X + 18), ($card.Y + 12), 36, 36
        $g.FillEllipse((New-Object Drawing.SolidBrush $colour), $circle)
        $centre = New-Object Drawing.StringFormat -Property @{ Alignment = 'Center'; LineAlignment = 'Center' }
        $symbol = if ($st -eq 'passed') { [string][char]0x2713 } else { "$n" }
        $g.DrawString($symbol, (F 11.5 'Bold'), [Drawing.Brushes]::White, [Drawing.RectangleF]$circle, $centre)
        $g.DrawString($l.Title, (F 10.5 'Bold'), (New-Object Drawing.SolidBrush $dark), ($card.X + 68), ($card.Y + 9))
        $info = "$($l.Obj)  ·  " + @{ passed = 'Passed'; started = 'In progress'; new = 'Not started yet' }[$st]
        $g.DrawString($info, (F 9), (New-Object Drawing.SolidBrush $colour), ($card.X + 68), ($card.Y + 33))
    })

# Output on the right
$frame = New-Object Windows.Forms.Panel -Property @{ Location = '400,100'; Size = '690,490'; Anchor = 'Top,Bottom,Left,Right'; BackColor = 'White'; Padding = '20,16,20,16' }
$text = New-Object Windows.Forms.RichTextBox -Property @{ Dock = 'Fill'; ReadOnly = $true; BorderStyle = 'None'; BackColor = 'White'; Font = (F 10.5 'Regular' 'Consolas'); ForeColor = $dark }
$frame.Controls.Add($text)

function Show-Lines($lines) {
    $text.Clear()
    foreach ($z in $lines) {
        if ($z -match 'Done\? ->') { $z = 'Done? Click "Check".' }
        $text.SelectionFont = if ($z -match '^===|^Result') { F 12 'Bold' } else { F 10.5 'Regular' 'Consolas' }
        $text.SelectionColor = if ($z -match '^\[OK\]|passed') { $green } elseif ($z -match '^\[X\]') { C '#DC2626' } elseif ($z -match 'Hint:') { C '#D97706' } elseif ($z -match '^===|^Result|Done\?') { $blue } else { $dark }
        $text.AppendText("$z`n")
    }
}
function Welcome {
    $text.Clear()
    $text.SelectionFont = F 16 'Bold'; $text.SelectionColor = $dark; $text.AppendText("Welcome!`n`n")
    $text.SelectionFont = F 11; $text.SelectionColor = (C '#4B5563')
    $text.AppendText("1.  Choose a lab on the left`n2.  ""Start lab"" shows you the task`n3.  ""Open folder"" and solve the task`n4.  ""Check"" tests your result`n5.  ""Create doc"" writes a section for your documentation`n`nTop right: ""Quiz"" tests you with the flashcards.")
}
function Refresh-View {
    $done = @(1..$labs.Count | Where-Object { (Status $_) -eq 'passed' }).Count
    $progress.Text = "$done of $($labs.Count) passed`n$version"
    $list.Invalidate()
}
function Selected { if ($list.SelectedIndex -lt 0) { [Windows.Forms.MessageBox]::Show('Choose a lab on the left first.', 'Lab Trainer') | Out-Null; return $null }; $list.SelectedIndex + 1 }

function Message($t) { [Windows.Forms.MessageBox]::Show($t, 'Lab Trainer') | Out-Null }
function Add-Button($title, $colour, $right, $action) {
    $b = New-Object Windows.Forms.Button -Property @{ Text = $title; Size = '160,46'; FlatStyle = 'Flat'; BackColor = $colour; ForeColor = 'White'; Font = (F 10.5 'Bold'); Cursor = 'Hand'; Anchor = 'Bottom,Right' }
    $b.FlatAppearance.BorderSize = 0
    $b.Location = New-Object Drawing.Point ($form.ClientSize.Width - $right), ($form.ClientSize.Height - 66)
    $b.Add_Click($action); $form.Controls.Add($b)
}
Add-Button 'Start lab' $blue 690 { $n = Selected; if ($n) { Show-Lines (Lab start $n); Refresh-View } }
Add-Button 'Open folder' (C '#4B5563') 520 { $n = Selected; if ($n) { $p = Join-Path $root "L$n"; if (Test-Path $p) { explorer.exe $p } else { Message 'Start the lab first.' } } }
Add-Button 'Check' $green 350 {
    $n = Selected; if (-not $n) { return }
    if ((Status $n) -eq 'new') { Message 'Start the lab first.'; return }
    $form.Cursor = 'WaitCursor'; $out = Lab check $n; $form.Cursor = 'Default'
    $mark = Join-Path $root "L$n\.passed"
    if ($out -match 'Lab passed') { New-Item -ItemType File $mark -Force | Out-Null } else { Remove-Item $mark, (Join-Path $root "L$n\.bestanden") -ErrorAction SilentlyContinue }
    Show-Lines $out; Refresh-View
}
Add-Button 'Create doc' (C '#7C3AED') 180 {
    $n = Selected; if (-not $n) { return }
    if ((Status $n) -eq 'new') { Message 'Start the lab first.'; return }
    $form.Cursor = 'WaitCursor'; $out = Lab doc $n; $form.Cursor = 'Default'
    $file = ($out | Where-Object { $_ -match '^Doc saved: (.+)' } | ForEach-Object { $Matches[1] }) | Select-Object -First 1
    if (-not $file) { Show-Lines $out; return }
    Set-Clipboard -Value (Get-Content $file -Raw -Encoding UTF8)
    Start-Process notepad.exe $file
    Show-Lines @("=== Doc for lab $n created ===", '', "Saved: $file", '', '[OK] The text is on the clipboard: paste it into Word or Obsidian (Ctrl+V).', '', 'Hint: add a screenshot and write 2-3 sentences under "What I learned".')
}

# Quiz with the flashcards: what you don't know comes up more often
function Quiz {
    $file = Join-Path (Split-Path $PSScriptRoot) 'Unterlagen\ÜK 188 Lernkarten.md'
    if (-not (Test-Path $file)) { Message 'Flashcards not found.'; return }
    $cards = @(); $cur = $null
    foreach ($z in Get-Content $file -Encoding UTF8) {
        if ($z -match '^> \[!question\]-\s*(.+)') { $cur = [pscustomobject]@{ Q = $Matches[1]; A = '' }; $cards += $cur }
        elseif ($cur -and $z -match '^> ?(.*)') { $cur.A += ($Matches[1] -replace '\*\*|`', '') + "`r`n" }
        else { $cur = $null }
    }
    $statFile = Join-Path $root 'quiz.csv'
    New-Item -ItemType Directory $root -Force | Out-Null
    $stat = @{}; if (Test-Path $statFile) { Import-Csv $statFile | Where-Object Question | ForEach-Object { $stat[$_.Question] = [pscustomobject]@{ Question = $_.Question; Right = [int]$_.Right; Wrong = [int]$_.Wrong } } }
    foreach ($k in $cards) { if (-not $stat[$k.Q]) { $stat[$k.Q] = [pscustomobject]@{ Question = $k.Q; Right = 0; Wrong = 0 } } }
    $round = New-Object Collections.ArrayList
    $cards | Sort-Object { $stat[$_.Q].Wrong - $stat[$_.Q].Right }, { Get-Random } -Descending | Select-Object -First 10 | ForEach-Object { [void]$round.Add($_) }
    $q = @{ i = 0; right = 0; again = @{} }

    $qf = New-Object Windows.Forms.Form -Property @{ Text = 'Quiz UEK 188'; Size = '760,520'; StartPosition = 'CenterParent'; BackColor = 'White'; Font = (F 11); FormBorderStyle = 'FixedDialog'; MaximizeBox = $false }
    $state = New-Object Windows.Forms.Label -Property @{ Location = '30,20'; Size = '680,24'; ForeColor = $grey; Font = (F 10 'Bold') }
    $question = New-Object Windows.Forms.Label -Property @{ Location = '30,50'; Size = '680,90'; Font = (F 15 'Bold'); ForeColor = $dark }
    $answer = New-Object Windows.Forms.Label -Property @{ Location = '30,150'; Size = '680,220'; Font = (F 11); ForeColor = (C '#374151'); BackColor = (C '#F0FDF4'); Padding = '12,12,12,12'; Visible = $false }
    function QButton($t, $colour, $x) { $b = New-Object Windows.Forms.Button -Property @{ Text = $t; Location = "$x,395"; Size = '220,46'; FlatStyle = 'Flat'; BackColor = $colour; ForeColor = 'White'; Font = (F 10.5 'Bold'); Cursor = 'Hand' }; $b.FlatAppearance.BorderSize = 0; $qf.Controls.Add($b); $b }
    $show = QButton 'Show answer' $blue 260
    $yes = QButton 'I knew it' $green 140
    $no = QButton "I didn't know it" (C '#DC2626') 380
    $qf.Controls.AddRange(@($state, $question, $answer))
    $next = {
        if ($q.i -ge $round.Count) {
            $stat.Values | Export-Csv $statFile -NoTypeInformation -Encoding UTF8
            Message "Done! You knew $($q.right) of $($round.Count) answers.`n`nWhat you didn't know comes first in the next quiz."
            $qf.Close(); return
        }
        $state.Text = "Question $($q.i + 1) of $($round.Count)   ·   $($q.right) known"
        $question.Text = $round[$q.i].Q; $answer.Text = $round[$q.i].A
        $answer.Visible = $false; $show.Visible = $true; $yes.Visible = $false; $no.Visible = $false
    }
    $show.Add_Click({ $answer.Visible = $true; $show.Visible = $false; $yes.Visible = $true; $no.Visible = $true })
    $yes.Add_Click({ $stat[$round[$q.i].Q].Right++; $q.right++; $q.i++; & $next })
    $no.Add_Click({
            $k = $round[$q.i]; $stat[$k.Q].Wrong++
            if (-not $q.again[$k.Q]) { $q.again[$k.Q] = $true; [void]$round.Add($k) }  # once more at the end of the round
            $q.i++; & $next
        })
    & $next
    [void]$qf.ShowDialog($form)
}

# VM control, only on the host (VMware can only be controlled from outside)
$vmx = 'C:\UEK188\VM\UEK188-Win11Edu.vmx'
$vmw = (Get-ItemProperty 'HKLM:\SOFTWARE\VMware, Inc.\VMware Workstation', 'HKLM:\SOFTWARE\WOW6432Node\VMware, Inc.\VMware Workstation' -ErrorAction SilentlyContinue | Select-Object -First 1).InstallPath
$vmrun = Join-Path $(if ($vmw) { $vmw } else { 'C:\Program Files\VMware\VMware Workstation' }) 'vmrun.exe'
function VmGuest { $pw = (Get-Content 'C:\UEK188\Setup\Zugangsdaten.txt' | Where-Object { $_ -match '^(Password|Passwort):\s*(.+)' } | ForEach-Object { $Matches[2].Trim() }); @('-T', 'ws', '-gu', 'Administrator', '-gp', $pw) }
function VmUpdate {
    $g = VmGuest
    $files = @(Get-ChildItem "$PSScriptRoot\*.ps1" | ForEach-Object { , @($_.FullName, "C:\UEK188\Lab\$($_.Name)") })
    & $vmrun @g createDirectoryInGuest $vmx 'C:\UEK188\Unterlagen' 2>&1 | Out-Null  # missing in older VMs
    foreach ($u in Get-ChildItem (Join-Path (Split-Path $PSScriptRoot) 'Unterlagen\*.md') -ErrorAction SilentlyContinue) { $files += , @($u.FullName, "C:\UEK188\Unterlagen\$($u.Name)") }
    $errors = 0
    foreach ($d in $files) { & $vmrun @g CopyFileFromHostToGuest $vmx $d[0] $d[1] | Out-Null; if ($LASTEXITCODE) { $errors++ } }
    if ($errors) { "Update VM: $errors of $($files.Count) files failed (is the VM running?)" } else { "VM updated: $($files.Count) files" }
}
function Add-HeadButton($t, $x, $action) {
    $b = New-Object Windows.Forms.Button -Property @{ Text = $t; Size = '130,36'; FlatStyle = 'Flat'; BackColor = (C '#1E40AF'); ForeColor = 'White'; Font = (F 9.5 'Bold'); Cursor = 'Hand'; Anchor = 'Top,Right' }
    $b.FlatAppearance.BorderColor = (C '#60A5FA')
    $b.Location = New-Object Drawing.Point ($form.ClientSize.Width - $x), 22
    $b.Add_Click($action); $head.Controls.Add($b); $b.BringToFront()
}
Add-HeadButton 'Quiz' 350 { Quiz }

# Auto-update from GitHub (not in the git repo on the host, otherwise local changes would be overwritten)
function Update-Labs {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $base = 'https://raw.githubusercontent.com/3234raul3234/uek-188-learning-tool/main/'
    $main = Split-Path $PSScriptRoot
    $wc = New-Object Net.WebClient; $new = @{}
    foreach ($n in 'Lab/lab188.ps1', 'Lab/Lab-Trainer.ps1', 'Unterlagen/ÜK 188 Lernkarten.md', 'Unterlagen/Hotel Vier Winde.md', 'Unterlagen/Arbeitsbericht.md') {
        $url = $base + (($n -split '/' | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/')
        try { $b = $wc.DownloadData($url) } catch { return "[X] Download failed ($n). Is the VM connected to the internet?" }
        if ($n -like '*.ps1') {
            $tmp = Join-Path $env:TEMP "uek188-$(Split-Path $n -Leaf)"; [IO.File]::WriteAllBytes($tmp, $b)
            $e = $null; [Management.Automation.Language.Parser]::ParseFile($tmp, [ref]$null, [ref]$e) | Out-Null
            if ($e -or $b.Length -lt 1000) { return "[X] $n on GitHub is broken. Nothing was changed." }  # never install a broken version
        }
        $new[(Join-Path $main $n)] = $b
    }
    # ignore line endings: the ZIP has CRLF, GitHub raw LF (otherwise the first click always says "new")
    function Text($bytes) { [Text.Encoding]::UTF8.GetString($bytes) -replace "`r", '' }
    $changed = @($new.Keys | Where-Object { -not (Test-Path $_) -or (Text ([IO.File]::ReadAllBytes($_))) -cne (Text $new[$_]) })
    if (-not $changed) { return 'current' }
    foreach ($target in $changed) { New-Item -ItemType Directory (Split-Path $target) -Force | Out-Null; if (Test-Path $target) { Copy-Item $target "$target.bak" -Force }; [IO.File]::WriteAllBytes($target, $new[$target]) }
    "new: $(($changed | ForEach-Object { Split-Path $_ -Leaf }) -join ', ')"
}
if (-not (Test-Path (Join-Path (Split-Path $PSScriptRoot) '.git'))) {
    Add-HeadButton 'Update' 490 {
        $form.Cursor = 'WaitCursor'; $m = Update-Labs; $form.Cursor = 'Default'
        if ($m -eq 'current') { Message 'You already have the latest version.' }
        elseif ($m -like 'new:*') {
            Message "Update installed ($($m.Substring(5))).`nThe Lab Trainer restarts now."
            Start-Process powershell.exe "-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
            $form.Close()
        }
        else { Show-Lines @('=== Update ===', '', $m) }
    }
}

if (-not (Test-Path 'C:\UEK188\Uebungen') -and (Test-Path $vmx)) {
    Add-HeadButton 'Update VM' 630 { $form.Cursor = 'WaitCursor'; $m = VmUpdate; $form.Cursor = 'Default'; Show-Lines @('=== VM ===', '', $m) }
    Add-HeadButton 'Reset VM' 770 {
        $snaps = @(& $vmrun -T ws listSnapshots $vmx)
        $snap = if ($snaps -contains 'Frisch') { 'Frisch' } else { 'Fresh' }  # 'Frisch' = name in older versions
        if ($snaps -notcontains $snap) {
            # the snapshot only exists once someone creates it: offer it now
            $make = [Windows.Forms.MessageBox]::Show("There is no snapshot 'Fresh' yet.`nSave the current state of the VM as 'Fresh' now?`n(Best right after the installation, it takes a few minutes.)", 'Create snapshot', 'YesNo', 'Question')
            if ($make -ne 'Yes') { return }
            $form.Cursor = 'WaitCursor'; & $vmrun -T ws snapshot $vmx Fresh | Out-Null; $r = $LASTEXITCODE; $form.Cursor = 'Default'
            Show-Lines @('=== Snapshot ===', '', $(if ($r) { '[X] The snapshot could not be created' } else { '[OK] Snapshot "Fresh" created. From now on this button resets the VM to it.' }))
            return
        }
        $ok = [Windows.Forms.MessageBox]::Show("The VM will be reset to its fresh state (snapshot '$snap').`nAll exercises INSIDE THE VM will be lost.`n`nContinue?", 'Reset VM', 'YesNo', 'Warning')
        if ($ok -ne 'Yes') { return }
        $form.Cursor = 'WaitCursor'
        & $vmrun -T ws revertToSnapshot $vmx $snap | Out-Null; $r1 = $LASTEXITCODE
        & $vmrun -T ws start $vmx gui | Out-Null
        foreach ($i in 1..30) { if ((& $vmrun -T ws checkToolsState $vmx) -eq 'running') { break }; Start-Sleep 3 }
        $m = VmUpdate
        $form.Cursor = 'Default'
        Show-Lines @('=== VM reset ===', '', $(if ($r1) { "[X] Snapshot '$snap' not found" } else { "[OK] Snapshot '$snap' restored" }), $m)
    }
}

$form.Controls.AddRange(@($list, $frame, $head))
Welcome; Refresh-View
[void]$form.ShowDialog()
