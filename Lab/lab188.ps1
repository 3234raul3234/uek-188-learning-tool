# UEK 188 practice labs.  Usage: lab188.ps1 list | start <No> | check <No> | doc <No>
param(
    [ValidateSet('list', 'start', 'check', 'doc', 'doku')][string]$Action = 'list',
    [ValidateRange(1, 15)][int]$No = 1,
    [Alias('LabPfad')][string]$LabPath = $(if (Test-Path 'C:\UEK188\Uebungen') { 'C:\UEK188\Uebungen' } else { Join-Path $env:USERPROFILE 'Lab188' })
)
$ErrorActionPreference = 'Stop'
$script:ok = 0; $script:fail = 0
$SID_USERS = 'S-1-5-32-545'; $SID_ADMINS = 'S-1-5-32-544'
$SID_ME = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$docs = 'C:\UEK188\Unterlagen\Hotel Vier Winde.md'

function Check($text, [bool]$condition, $hint) {
    if ($condition) { Write-Host "[OK] $text" -ForegroundColor Green; $script:ok++ }
    else { Write-Host "[X]  $text" -ForegroundColor Red; if ($hint) { Write-Host "     Hint: $hint" -ForegroundColor Yellow }; $script:fail++ }
}

# Sum of all "Allow" rights of a SID on a path (as int)
function Rights($path, $sid) {
    $r = 0
    foreach ($a in (Get-Acl $path).Access) {
        if ($a.AccessControlType -ne 'Allow') { continue }
        try { $s = $a.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value } catch { continue }
        if ($s -eq $sid) { $r = $r -bor [int]$a.FileSystemRights }
    }
    $r
}
function Has([int]$r, $right) { $m = [int][Security.AccessControl.FileSystemRights]::$right; ($r -band $m) -eq $m }
function ReadCsv($path) { $head = Get-Content $path -TotalCount 1; if ($head -match ';' -and $head -notmatch ',') { Import-Csv $path -Delimiter ';' } else { Import-Csv $path } }  # Excel saves with ;
function Content($name) { $f = Join-Path $dir $name; if (Test-Path $f) { Get-Content $f -Raw } else { '' } }
function IsTrue($value) { "$value" -match '^(true|yes|1)$' }
function PortOpen($target, $port) { $c = New-Object Net.Sockets.TcpClient; try { $c.ConnectAsync($target, $port).Wait(2000) -and $c.Connected } catch { $false } finally { $c.Dispose() } }

$Labs = @{
    1 = @{ Title = 'NTFS permissions by concept (OBJ 5)'; Task = @"
GOAL: Decide who may open which folder.
(Permission = what a person may do with a folder: read, change, or nothing.)

Your folder L1\Company has 3 folders. Set these permissions:

Step 1 - Folder "Accounting" (secret money data):
  - Turn OFF inheritance (= the folder no longer copies permissions from above).
  - Administrators: Full control
  - You: Modify (NOT Full control)
  - Users: no access at all
Step 2 - Folder "Sales": Users may only READ, not write.
Step 3 - Folder "All": Users may Modify.
Step 4 - Write a small table in L1\permissions.md:
  Folder | Group | Right | Reason

How: right-click a folder > Properties > Security tab > Edit / Advanced.
"@
    }
    2 = @{ Title = 'Analyse services (OBJ 1, 2)'; Task = @"
GOAL: Find services that should run but don't.
(Service = a program that runs in the background, e.g. the printer service.)

Step 1 - Find all services with start type "Automatic" that are NOT running.
Step 2 - Save them with PowerShell in the file L2\services.csv
         with the columns: Name, DisplayName, Status
Step 3 - Pick ONE of these services. In L2\notes.md write 2-3 sentences:
         What does it do? Why could it be stopped?

Hint: Get-Service, Where-Object, Select-Object, Export-Csv -NoTypeInformation
"@
    }
    3 = @{ Title = 'Monitoring script with threshold (OBJ 4)'; Task = @"
GOAL: Write a small script that measures your computer.
(Threshold = a limit. Below the limit you get a warning.)

Step 1 - Create the script L3\monitor.ps1
Step 2 - Every time it runs, it adds ONE new line to L3\monitor.csv
         (in the same folder as the script: use `$PSScriptRoot).
Step 3 - Columns of the line:
         Time      = date and time
         CPU       = how busy the processor is, in %
         RAMFreeMB = free memory in MB
         CFreeGB   = free space on drive C: in GB
         Status    = 'WARNING' if CFreeGB is smaller than the threshold, otherwise 'OK'
Step 4 - The script has a parameter -ThresholdGB. If you don't give it, it is 20.

The check runs your script itself and compares the numbers with your computer.
Hint: Get-CimInstance Win32_Processor / Win32_OperatingSystem, Get-PSDrive C, Export-Csv -Append
"@
    }
    4 = @{ Title = 'Patch documentation (OBJ 3)'; Task = @"
GOAL: Write down which Windows updates are installed.
(Patch / update = a fix from Microsoft, it has a number like KB5012345.)

Step 1 - Find all installed updates.
Step 2 - Create L4\patches.md with a table:
         KB | Description | Installed on
Step 3 - Below the table add one line with the newest update:
         Last update: KBxxxxxxx

Hint: Get-HotFix | Sort-Object InstalledOn
"@
    }
    5 = @{ Title = 'System profile for the operations docs (OBJ 1)'; Task = @"
GOAL: Write a short profile of YOUR computer.
(Before you change a system, you always write down how it looks now.)

Create L5\profile.md with exactly these 6 lines and fill in the values:
  Hostname: ...            (name of the computer)
  Operating system: ...    (e.g. Windows 11 Pro)
  IPv4: ...                (IP address)
  Gateway: ...             (the router)
  DNS: ...                 (the DNS server)
  RAM GB: ...              (memory, a whole number)

The check compares your values with the real computer.
Hint: hostname, ipconfig /all, Get-CimInstance Win32_OperatingSystem / Win32_ComputerSystem
"@
    }
    6 = @{ Title = 'Test network and remote access (OBJ 2)'; Task = @"
GOAL: Test if some services can be reached over the network.
(Port = a "door" number. Every service listens at its own door.)

Step 1 - Test these 4 targets:
           www.microsoft.com  port 443
           1.1.1.1            port 53
           localhost          port 3389
           localhost          port 445
Step 2 - Save the result in L6\nettest.csv with the columns:
           Target, Port, Reachable   (Reachable = True or False)
Step 3 - In L6\notes.md explain: which service uses port 3389? Which uses port 445?

Hint: Test-NetConnection -ComputerName <Target> -Port <Port>  ->  look at TcpTestSucceeded
"@
    }
    7 = @{ Title = 'Evaluate the Event Viewer (OBJ 2, 4)'; Task = @"
GOAL: Find the newest errors that Windows has written down.
(Event log = Windows' diary. It writes down errors and warnings.)

Step 1 - Find the last 10 ERRORS in the "System" log.
Step 2 - Save them in L7\errors.csv with the columns:
           TimeCreated, Id, ProviderName   (ProviderName = who reported the error)
Step 3 - In L7\notes.md write: which ProviderName comes up most often?
           What could the error mean? (Search the internet if needed.)

Hint: Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2 } -MaxEvents 10
"@
    }
    8 = @{ Title = 'Local users and administrators (OBJ 5)'; Task = @"
GOAL: See which user accounts exist on this computer.
(Administrator = a user who may change everything.)

Step 1 - Save ALL local users in L8\users.csv with the columns:
           Name, Enabled, Admin
           Enabled = True/False   (is the account switched on?)
           Admin   = True/False   (is the user in the group "Administrators"?)
Step 2 - In L8\notes.md write: on ws01 only "Administrator" may be switched on.
           Which accounts here would you have to switch off for that?

Hint: Get-LocalUser, Get-LocalGroupMember -SID S-1-5-32-544
"@
    }
    9 = @{ Title = 'Software inventory (OBJ 3)'; Task = @"
GOAL: Make a list of all installed programs.
(Inventory = a complete list of what you have.)

Step 1 - Save all installed programs in L9\software.csv with the columns:
           DisplayName, DisplayVersion, Publisher
         Leave out lines without a DisplayName.
Step 2 - Pick 3 programs. In L9\notes.md write if your version is the newest
         (check on the internet).

Hint: the list is in the registry at these 3 places:
  HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*
  HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*
  HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*
"@
    }
    10 = @{ Title = 'Checklists titan and ws01 (OBJ 1)'; Task = @"
GOAL: Plan the setup of 2 computers of the hotel as to-do lists.
(titan = the server, ws01 = a workstation. All facts are in:
 $docs)

Step 1 - Create L10\checklist-titan.md
Step 2 - Create L10\checklist-ws01.md
Step 3 - Write every to-do as a checkbox line:  - [ ] what to do
Step 4 - Think of: VM settings (RAM, CPU, network adapter), VMware Tools,
         computer name, IP address / mask / gateway / DNS, Windows updates,
         printer server with the share pr-office (titan), only the Administrator
         account on ws01, programs to install, and testing at the end.

The check tells you which topics are still missing.
"@
    }
    11 = @{ Title = 'Investigate the Print Spooler service (OBJ 1, 2)'; Task = @"
GOAL: Look closely at ONE service: the Print Spooler.
(Print Spooler = the service that sends your documents to the printer.)

Create L11\spooler.md and answer these 4 points:
  1. Display name, start type and status of the service
  2. Which services it needs to run (dependencies)
  3. The path of its program file (.exe)
  4. Why it can be dangerous: search for "PrintNightmare" and explain it in 2-3 sentences

Hint: Get-Service Spooler | Format-List *, Get-CimInstance Win32_Service -Filter "Name='Spooler'"
"@
    }
    12 = @{ Title = 'Automate monitoring (OBJ 4, d1)'; Task = @"
GOAL: Let your script from Lab 3 run by itself.
(Scheduled task = Windows starts a program for you at certain times.)

Before you start: Lab 3 must be solved.

Step 1 - Create a scheduled task with the name:  Lab188-Monitor
Step 2 - It starts powershell.exe with your file L3\monitor.ps1
Step 3 - It repeats every 15 minutes.

When you are finished, delete the task again:  Unregister-ScheduledTask Lab188-Monitor
Hint: New-ScheduledTaskAction, New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15), Register-ScheduledTask
"@
    }
    13 = @{ Title = 'Subnetting Hotel Vier Winde (OBJ 1)'; Task = @"
GOAL: Calculate a network by hand.
(Subnetting = splitting IP addresses into networks. /23 = the first 23 bits are the network.)

The hotel wants a guest Wi-Fi with the network 10.20.30.0/23.
Calculate it yourself (no online calculator!) and create L13\network.md
with exactly these lines:
  Subnet mask: ...
  Network address: ...
  Broadcast: ...
  First host: ...
  Last host: ...
  Number of hosts: ...

Then 2 questions about the hotel network 172.18.20.64/26 (see $docs):
  Hotel DHCP addresses: ...              (how many addresses are in .66 to .115?)
  172.18.20.130 in hotel network: Yes/No
"@
    }
    14 = @{ Title = 'Permission matrix Hotel Vier Winde (OBJ 5)'; Task = @"
GOAL: Turn a permission table into a list.
(Share = a folder on the server that others can open over the network.)

Step 1 - Open $docs
         and find the table "Server shares and permissions".
Step 2 - Create L14\permissions.csv with the columns: Share, Department, Right
Step 3 - Write ONE line for every share and department that has rights.
         Skip the fields with "-".
         Example line:  Exchange,Management,"R,W"
Step 4 - In L14\notes.md explain how you would build the share "Exchange" with AGDLP
         (AGDLP = users go into Global groups, those into Domain Local groups,
          and those get the Permissions).

Bonus: does anything in the table look strange to you? Write it down too.
"@
    }
    15 = @{ Title = 'Check the logins in the operations docs (OBJ 1, 5)'; Task = @"
GOAL: Find user logins that break the naming rule.
(Login = the user name to sign in.)

The rule: first 3 letters of the first name + first 3 letters of the last name,
all small letters, ä/ö/ü become ae/oe/ue, no spaces.
Example: Gerhard Bär -> ger + bae -> gerbae

Step 1 - Copy all users from $docs
         into L15\users.csv with the columns: FirstName, LastName, Login, Department
Step 2 - Write a script L15\check.ps1 that builds the correct login for every line.
Step 3 - Compare. Write every login that does NOT follow the rule into
         L15\deviations.txt (one per line, written exactly like in the list).

Hint: .Substring(0,3), .ToLower(), -replace 'ä','ae'
"@
    }
}

$dir = Join-Path $LabPath "L$No"

if ($Action -eq 'list') {
    foreach ($n in $Labs.Keys | Sort-Object) { Write-Host "$n  $($Labs[$n].Title)" }
    return
}

if ($Action -eq 'start') {
    if (Test-Path $dir) { Write-Host "Lab $No already exists in $dir (not overwritten)." -ForegroundColor Yellow }
    else {
        New-Item -ItemType Directory $dir | Out-Null
        if ($No -eq 1) { 'Accounting', 'Sales', 'All' | ForEach-Object { New-Item -ItemType Directory (Join-Path $dir "Company\$_") | Out-Null } }
        Set-Content (Join-Path $dir 'Task.txt') $Labs[$No].Task
    }
    Write-Host "`n=== Lab $No - $($Labs[$No].Title) ===  Folder: $LabPath`n" -ForegroundColor Cyan
    Write-Host $Labs[$No].Task
    $extra = if ($PSBoundParameters.ContainsKey('LabPath')) { ' -LabPath "' + $LabPath + '"' } else { '' }
    Write-Host "`nDone? ->  lab188.ps1 check $No$extra" -ForegroundColor Cyan
    return
}

if ($Action -in 'doc', 'doku') {
    # Ready-made section for your own documentation
    if (-not (Test-Path $dir)) { Write-Host "Lab $No not started." -ForegroundColor Red; exit 1 }
    $result = & powershell -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath check $No -LabPath $LabPath 2>&1 | ForEach-Object { "$_" }
    $md = @("## Lab $No – $($Labs[$No].Title)", '', "*$(Get-Date -Format 'dd.MM.yyyy HH:mm') on $env:COMPUTERNAME*", '', '### Task', '```', $Labs[$No].Task.Trim(), '```', '', '### My solution')
    if ($No -eq 1) {
        $md += '**Permissions**', '', '| Folder | Who | Right | Inherited |', '|---|---|---|---|'
        foreach ($o in Get-ChildItem (Join-Path $dir 'Company') -Directory) { foreach ($a in (Get-Acl $o.FullName).Access) { $md += "| $($o.Name) | $($a.IdentityReference) | $($a.FileSystemRights) | $(if ($a.IsInherited) { 'yes' } else { 'no' }) |" } }
        $md += ''
    }
    if ($No -eq 12) { $md += '**Scheduled task**', '```', (Get-ScheduledTask Lab188-Monitor -ErrorAction SilentlyContinue | ForEach-Object { "$($_.TaskName): $($_.Actions[0].Execute) $($_.Actions[0].Arguments) / interval $($_.Triggers[0].Repetition.Interval)" }), '```', '' }
    foreach ($f in Get-ChildItem $dir -Recurse -File | Where-Object Name -NotIn 'Task.txt', 'Auftrag.txt', '.passed', '.bestanden') {
        $md += "**$($f.FullName.Substring($dir.Length + 1))**", '```', ((Get-Content $f.FullName -TotalCount 40 -Encoding UTF8) -join "`n"), '```', ''
    }
    $md += '### Result of the check', '```'
    $md += @($result | Where-Object { $_ -match '^\[|Result|Hint' })
    $md += '```', '', '### What I learned', '- ', ''
    $target = Join-Path $LabPath ('Doku\Lab-{0:D2}.md' -f $No)
    New-Item -ItemType Directory (Split-Path $target) -Force | Out-Null
    [IO.File]::WriteAllText($target, ($md -join "`r`n"), (New-Object Text.UTF8Encoding $true))
    Write-Host "Doc saved: $target"
    return
}

# check
if (-not (Test-Path $dir)) { Write-Host "Lab $No not started. First: lab188.ps1 start $No" -ForegroundColor Red; exit 1 }
Write-Host "`n=== Check Lab $No - $($Labs[$No].Title) ===`n" -ForegroundColor Cyan

switch ($No) {
    1 {
        $b = Join-Path $dir 'Company\Accounting'; $v = Join-Path $dir 'Company\Sales'; $a = Join-Path $dir 'Company\All'
        Check 'Accounting: inheritance disabled' (Get-Acl $b).AreAccessRulesProtected 'Advanced > Disable inheritance (convert inherited permissions)'
        Check 'Accounting: Administrators full control' (Has (Rights $b $SID_ADMINS) 'FullControl')
        $me = Rights $b $SID_ME
        Check 'Accounting: you have Modify' (Has $me 'Modify')
        Check 'Accounting: you do NOT have full control (least privilege)' (-not (Has $me 'FullControl')) 'Your entry: remove full control, keep Modify only'
        Check 'Accounting: Users no access' ((Rights $b $SID_USERS) -eq 0)
        $vu = Rights $v $SID_USERS
        Check 'Sales: Users read & execute' (Has $vu 'ReadAndExecute') 'Add the group "Users"'
        Check 'Sales: Users NO write' (-not (Has $vu 'WriteData'))
        Check 'All: Users modify' (Has (Rights $a $SID_USERS) 'Modify')
        $doc = Content 'permissions.md'
        Check 'Documentation permissions.md with all 3 folders' ($doc -match 'Accounting' -and $doc -match 'Sales' -and $doc -match 'All')
    }
    2 {
        $csv = Join-Path $dir 'services.csv'
        Check 'services.csv exists' (Test-Path $csv) 'Export-Csv -Path ... -NoTypeInformation'
        if (Test-Path $csv) {
            $is = @(ReadCsv $csv)
            $cols = if ($is.Count) { $is[0].PSObject.Properties.Name } else { @() }
            Check 'Columns Name, DisplayName, Status' (('Name', 'DisplayName', 'Status' | Where-Object { $cols -notcontains $_ }).Count -eq 0) 'Select-Object Name, DisplayName, Status'
            $should = @(Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' } | ForEach-Object Name)
            $isN = @($is | ForEach-Object Name)
            # shortcut: services change state all the time, so 2 differences are tolerated
            $missing = @($should | Where-Object { $isN -notcontains $_ }); $extra = @($isN | Where-Object { $should -notcontains $_ })
            Check "Correct services ($($should.Count) expected, $($isN.Count) found)" ($missing.Count -le 2 -and $extra.Count -le 2) "Missing e.g.: $($missing | Select-Object -First 3) / too many: $($extra | Select-Object -First 3)"
        }
        Check 'notes.md with explanation' ((Content 'notes.md').Length -gt 50) 'At least 2-3 sentences'
    }
    3 {
        $s = Join-Path $dir 'monitor.ps1'; $csv = Join-Path $dir 'monitor.csv'
        Check 'monitor.ps1 exists' (Test-Path $s)
        if (Test-Path $s) {
            Remove-Item $csv -ErrorAction SilentlyContinue  # check starts with an empty CSV
            $ErrorActionPreference = 'Continue'
            & powershell -NoProfile -ExecutionPolicy Bypass -File $s
            & powershell -NoProfile -ExecutionPolicy Bypass -File $s
            & powershell -NoProfile -ExecutionPolicy Bypass -File $s -ThresholdGB 999999
            $ErrorActionPreference = 'Stop'
            $rows = @(if (Test-Path $csv) { ReadCsv $csv })
            Check '3 runs = 3 lines in monitor.csv' ($rows.Count -eq 3) 'Export-Csv -Append, path with $PSScriptRoot'
            if ($rows.Count -ge 3) {
                $r = $rows[0]
                $ramReal = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1KB
                $cReal = (Get-PSDrive C).Free / 1GB
                Check 'Columns Time, CPU, RAMFreeMB, CFreeGB, Status' (($null -ne $r.Time) -and ($null -ne $r.CPU) -and ($null -ne $r.RAMFreeMB) -and ($null -ne $r.CFreeGB) -and ($null -ne $r.Status))
                $cpu = $r.CPU -as [double]; $ram = $r.RAMFreeMB -replace ',', '.' -as [double]; $c = $r.CFreeGB -replace ',', '.' -as [double]
                Check "CPU plausible 0-100 ($($r.CPU))" ($null -ne $cpu -and $cpu -ge 0 -and $cpu -le 100)
                Check "RAMFreeMB plausible ($([int]$ram) vs. real $([int]$ramReal))" ($null -ne $ram -and [math]::Abs($ram - $ramReal) -le ($ramReal * 0.3 + 300)) 'FreePhysicalMemory is in KB'
                Check "CFreeGB plausible ($c vs. real $([math]::Round($cReal,1)))" ($null -ne $c -and [math]::Abs($c - $cReal) -le 2) 'Free is in bytes -> / 1GB'
                $exp = if ($cReal -lt 20) { 'WARNING' } else { 'OK' }
                Check "Status at default threshold 20 GB = $exp" ($r.Status -eq $exp)
                Check 'Status at -ThresholdGB 999999 = WARNING' ($rows[2].Status -eq 'WARNING') 'param([int]$ThresholdGB = 20)'
            }
        }
    }
    4 {
        $t = Content 'patches.md'
        Check 'patches.md exists' ($t -ne '')
        if ($t) {
            $hf = @(Get-HotFix | Where-Object InstalledOn | Sort-Object InstalledOn)
            $kbs = @($hf | ForEach-Object HotFixID)
            $in = @($kbs | Where-Object { $t -match $_ })
            Check "All installed updates in the table ($($in.Count)/$($kbs.Count))" ($in.Count -eq $kbs.Count)
            if ($hf.Count) { Check "Last update correct ($($hf[-1].HotFixID))" ($t -match "Last update:\s*$($hf[-1].HotFixID)") }
            Check 'Table present (| lines)' ($t -match '\|.*\|')
        }
    }
    5 {
        $t = (Content 'profile.md') -replace '[*_`]', ''  # ignore Markdown bold etc.
        Check 'profile.md exists' ($t -ne '')
        $os = Get-CimInstance Win32_OperatingSystem
        # not Get-NetIPConfiguration: it crashes with some network adapters
        $routes = @(Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue)
        $ifs = @($routes | ForEach-Object InterfaceIndex)
        $ips = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $ifs -contains $_.InterfaceIndex } | ForEach-Object IPAddress)
        $gws = @($routes | ForEach-Object NextHop)
        $dns = @(Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $ifs -contains $_.InterfaceIndex } | ForEach-Object ServerAddresses)
        $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
        Check "Hostname ($env:COMPUTERNAME)" ($t -match "Hostname:\s*$env:COMPUTERNAME") 'hostname'
        Check 'Operating system' ($t -match ('Operating system:.*' + [regex]::Escape(($os.Caption -replace 'Microsoft ', '')))) "Exactly: $($os.Caption -replace 'Microsoft ', '')"
        Check 'IPv4 address' (@($ips | Where-Object { $t -match "IPv4:.*$([regex]::Escape($_))" }).Count -gt 0) 'ipconfig: IPv4 address of the adapter with a gateway'
        Check 'Gateway' (@($gws | Where-Object { $t -match "Gateway:.*$([regex]::Escape($_))" }).Count -gt 0) 'ipconfig: default gateway'
        Check 'DNS server' (@($dns | Where-Object { $t -match "DNS:.*$([regex]::Escape($_))" }).Count -gt 0) 'ipconfig /all: DNS servers'
        Check "RAM GB (approx. $ram)" ($t -match 'RAM GB:\s*(\d+)' -and [math]::Abs([int]$Matches[1] - $ram) -le 1) 'TotalPhysicalMemory is in bytes -> / 1GB'
    }
    6 {
        $csv = Join-Path $dir 'nettest.csv'
        Check 'nettest.csv exists' (Test-Path $csv)
        if (Test-Path $csv) {
            $is = @(ReadCsv $csv)
            foreach ($z in @(('www.microsoft.com', 443), ('1.1.1.1', 53), ('localhost', 3389), ('localhost', 445))) {
                $line = $is | Where-Object { $_.Target -eq $z[0] -and "$($_.Port)" -eq "$($z[1])" } | Select-Object -First 1
                $real = PortOpen $z[0] $z[1]
                Check "$($z[0]):$($z[1]) -> reachable = $real" ($line -and ((IsTrue $line.Reachable) -eq $real)) 'Columns exactly: Target, Port, Reachable'
            }
        }
        $n = Content 'notes.md'
        Check 'Port 3389 explained (RDP)' ($n -match 'RDP|Remote ?Desktop')
        Check 'Port 445 explained (SMB)' ($n -match 'SMB|file|share')
    }
    7 {
        $csv = Join-Path $dir 'errors.csv'
        Check 'errors.csv exists' (Test-Path $csv)
        if (Test-Path $csv) {
            $is = @(ReadCsv $csv | ForEach-Object { "$($_.ProviderName)|$($_.Id)" })
            $should = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2 } -MaxEvents 10 -ErrorAction SilentlyContinue | ForEach-Object { "$($_.ProviderName)|$($_.Id)" })
            # shortcut: new errors may have appeared since the export, so 2 differences are tolerated
            $hits = @($should | Where-Object { $is -contains $_ }).Count
            Check "Latest errors found ($hits of $($should.Count))" ($is.Count -gt 0 -and $hits -ge ($should.Count - 2)) 'Level = 2 means error; -MaxEvents 10; columns ProviderName and Id'
            Check 'At most 10 entries' ($is.Count -le 10)
        }
        Check 'notes.md with evaluation' ((Content 'notes.md').Length -gt 50) 'Name the most frequent source and explain it'
    }
    8 {
        $csv = Join-Path $dir 'users.csv'
        Check 'users.csv exists' (Test-Path $csv)
        if (Test-Path $csv) {
            $is = @(ReadCsv $csv)
            try { $admins = @(Get-LocalGroupMember -SID $SID_ADMINS | ForEach-Object { $_.SID.Value }) }
            catch { $admins = @(([ADSI]"WinNT://./$((New-Object Security.Principal.SecurityIdentifier $SID_ADMINS).Translate([Security.Principal.NTAccount]).Value.Split('\')[1]),group").Invoke('Members') | ForEach-Object { (New-Object Security.Principal.SecurityIdentifier ([byte[]]$_.GetType().InvokeMember('objectSid', 'GetProperty', $null, $_, $null)), 0).Value }) }
            foreach ($u in Get-LocalUser) {
                $line = $is | Where-Object Name -eq $u.Name | Select-Object -First 1
                $isAdmin = $admins -contains $u.SID.Value
                Check "$($u.Name): Enabled=$($u.Enabled), Admin=$isAdmin" ($line -and (IsTrue $line.Enabled) -eq $u.Enabled -and (IsTrue $line.Admin) -eq $isAdmin) 'All local users, columns Name, Enabled, Admin'
            }
        }
        Check 'notes.md with answer' ((Content 'notes.md').Length -gt 30)
    }
    9 {
        $csv = Join-Path $dir 'software.csv'
        Check 'software.csv exists' (Test-Path $csv)
        if (Test-Path $csv) {
            $is = @(ReadCsv $csv)
            $cols = if ($is.Count) { $is[0].PSObject.Properties.Name } else { @() }
            Check 'Columns DisplayName, DisplayVersion, Publisher' (('DisplayName', 'DisplayVersion', 'Publisher' | Where-Object { $cols -notcontains $_ }).Count -eq 0)
            $paths = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
            $should = @(Get-ItemProperty $paths -ErrorAction SilentlyContinue | Where-Object DisplayName | ForEach-Object DisplayName | Sort-Object -Unique)
            $isN = @($is | ForEach-Object DisplayName)
            $hits = @($should | Where-Object { $isN -contains $_ }).Count
            Check "Programs found ($hits of $($should.Count))" ($hits -ge [math]::Floor($should.Count * 0.9)) 'Query all 3 registry paths'
            Check 'No empty DisplayName' (@($is | Where-Object { -not $_.DisplayName }).Count -eq 0) 'Where-Object DisplayName'
        }
        Check 'notes.md with 3 programs' ((Content 'notes.md').Length -gt 50)
    }
    10 {
        $ti = Content 'checklist-titan.md'; $ws = Content 'checklist-ws01.md'
        Check 'checklist-titan.md exists' ($ti -ne '')
        Check 'checklist-ws01.md exists' ($ws -ne '')
        Check 'Checkboxes to tick' ($ti -match '\[ \]|\[x\]|☐' -and $ws -match '\[ \]|\[x\]|☐') "Write '- [ ] Task'"
        $items = @(
            @('titan', $ti, 'RAM (4 GB)', '4\s*GB|4096'), @('titan', $ti, 'Processors (2 CPU)', 'Processor|CPU'), @('titan', $ti, 'Network adapter intnet-lan', 'intnet'),
            @('titan', $ti, 'Guest additions / VMware Tools', 'Guest Additions|VMware Tools'), @('titan', $ti, 'Server name', 'Server ?name|Host ?name|Computer ?name|Name:\s*titan'),
            @('titan', $ti, 'Static IP', 'static|fixed'), @('titan', $ti, 'Subnet mask', 'Subnet|Mask|255\.255\.255\.192|/26'), @('titan', $ti, 'Gateway', 'Gateway|\bGW\b'), @('titan', $ti, 'DNS (OPNsense)', 'DNS'),
            @('titan', $ti, 'Windows updates', 'Update'), @('titan', $ti, 'Role Print and Document Services', 'Print and Document|Print ?server'), @('titan', $ti, 'Printer driver (PCL-6)', 'Driver|PCL'),
            @('titan', $ti, 'Share pr-office', 'pr-office'), @('titan', $ti, 'Test internet access', 'Internet'),
            @('ws01', $ws, 'VM settings', 'RAM|Memory|GB'), @('ws01', $ws, 'Network adapter intnet-lan', 'intnet'), @('ws01', $ws, 'Guest additions / VMware Tools', 'Guest Additions|VMware Tools'),
            @('ws01', $ws, 'Computer name ws01', 'ws01'), @('ws01', $ws, 'Static IP (until DHCP runs)', 'static|fixed'), @('ws01', $ws, 'DNS (OPNsense)', 'OPNsense'),
            @('ws01', $ws, 'Only the local Administrator account enabled', 'Administrator'), @('ws01', $ws, 'Disable/delete other accounts', 'disabl|delet|remov'),
            @('ws01', $ws, 'Windows updates', 'Update'), @('ws01', $ws, 'Test internet access', 'Internet|ping'),
            # values from the Hotel Vier Winde scenario
            @('titan', $ti, 'IP 172.18.20.120', '172\.18\.20\.120'), @('titan', $ti, 'Mask 255.255.255.192 (/26)', '255\.255\.255\.192|/26'),
            @('titan', $ti, 'Gateway and DNS = OPNsense 172.18.20.65', '172\.18\.20\.65'), @('titan', $ti, 'Printer model HP X58045z', 'X58045'),
            @('ws01', $ws, 'Static IP in the client range .66 - .115', '172\.18\.20\.(6[6-9]|[7-9]\d|10\d|11[0-5])\b'), @('ws01', $ws, 'Mask 255.255.255.192 (/26)', '255\.255\.255\.192|/26'),
            @('ws01', $ws, 'Gateway and DNS 172.18.20.65', '172\.18\.20\.65'), @('ws01', $ws, 'Tool Firefox', 'Firefox'), @('ws01', $ws, 'Tool Notepad++', 'Notepad\+\+')
        )
        foreach ($p in $items) { Check "$($p[0]): $($p[2])" ($p[1] -match $p[3]) "Add an item to the $($p[0]) checklist about: $($p[2])" }
    }
    11 {
        $t = Content 'spooler.md'
        Check 'spooler.md exists' ($t -ne '')
        $svc = Get-Service Spooler
        $start = @{ Automatic = 'Automatic'; Manual = 'Manual'; Disabled = 'Disabled' }["$($svc.StartType)"]
        $status = @{ Running = 'Running|Started'; Stopped = 'Stopped' }["$($svc.Status)"]
        Check 'Display name' ($t -match [regex]::Escape($svc.DisplayName))
        Check "Start type ($($svc.StartType))" ($t -match $start)
        Check "Status ($($svc.Status))" ($t -match $status)
        foreach ($d in $svc.ServicesDependedOn) { Check "Dependency $($d.Name)" ($t -match [regex]::Escape($d.Name)) 'ServicesDependedOn' }
        Check 'Path to spoolsv.exe' ($t -match 'spoolsv\.exe') 'Win32_Service -> PathName'
        Check 'Security risk explained' ($t -match 'PrintNightmare' -and $t.Length -gt 200) 'What was PrintNightmare (2021)?'
    }
    12 {
        Check 'Lab 3 present (L3\monitor.ps1)' (Test-Path (Join-Path $LabPath 'L3\monitor.ps1')) 'Solve Lab 3 first'
        $task = Get-ScheduledTask -TaskName 'Lab188-Monitor' -ErrorAction SilentlyContinue
        Check 'Scheduled task Lab188-Monitor exists' ($null -ne $task) 'Register-ScheduledTask -TaskName Lab188-Monitor ...'
        if ($task) {
            $a = $task.Actions | Select-Object -First 1
            Check 'Starts powershell.exe' ($a.Execute -match 'powershell')
            Check 'With L3\monitor.ps1' ($a.Arguments -match 'monitor\.ps1') '-Argument "-File C:\...\L3\monitor.ps1"'
            $iv = @($task.Triggers | ForEach-Object { $_.Repetition.Interval })
            Check 'Every 15 minutes' ($iv -contains 'PT15M') '-RepetitionInterval (New-TimeSpan -Minutes 15)'
            Check 'Task is enabled' ($task.State -ne 'Disabled')
        }
    }
    13 {
        # ignore Markdown bold; turn table rows '| key | value |' into 'key: value'
        $lines = @(((Content 'network.md') -replace '[*_`]', '') -split '\r?\n' | ForEach-Object { ($_ -replace '^\s*\|\s*', '' -replace '\s*\|\s*$', '' -replace '\s*\|\s*', ': ').Trim() })
        Check 'network.md exists' ((Content 'network.md') -ne '')
        # exactly one answer per question (no "512 and 510"), extra text after the value is fine (e.g. 10.20.30.0/23)
        function Answer($key, $value) { $hit = @($lines | Where-Object { $_ -match "^$([regex]::Escape($key))\s*:" }); $hit.Count -eq 1 -and $hit[0] -match ":\s*$([regex]::Escape($value))(?![\d.]\d)" }
        $should = [ordered]@{ 'Subnet mask' = '255.255.254.0'; 'Network address' = '10.20.30.0'; 'Broadcast' = '10.20.31.255'; 'First host' = '10.20.30.1'; 'Last host' = '10.20.31.254'; 'Number of hosts' = '510'; 'Hotel DHCP addresses' = '50' }
        $hints = @{ 'Subnet mask' = '/23 = 23 ones'; 'Broadcast' = '/23 covers 2 x 256 addresses'; 'Number of hosts' = '2^(32-23) - 2'; 'Hotel DHCP addresses' = 'From 66 to 115, both included' }
        foreach ($k in $should.Keys) { Check "$k = ?" (Answer $k $should[$k]) $(if ($hints[$k]) { $hints[$k] } else { 'One line per question, value right after the colon' }) }
        Check '172.18.20.130 in hotel network = ?' (Answer '172.18.20.130 in hotel network' 'No') '/26 = 64 addresses starting at .64'
    }
    14 {
        $csv = Join-Path $dir 'permissions.csv'
        Check 'permissions.csv exists' (Test-Path $csv)
        if (Test-Path $csv) {
            # departments short: MG, AD, FO, BO, FB, CO, HK, TE (table in Unterlagen\Hotel Vier Winde.md)
            $matrix = [ordered]@{
                'exchange' = 'MG AD FO BO FB CO HK TE'; 'front-office' = 'MG FO'; 'bo' = 'MG BO'; 'administration' = 'MG AD FB CO'; 'conv' = 'MG FB CO'; 'fobe' = 'MG CO'
                'hall' = 'MG AD FO BO CO TE'; 'bar' = 'MG AD FO BO FB CO TE'; 'meetings' = 'MG AD FO BO CO TE'; 'offices' = 'MG AD FO BO CO TE'; 'pr-office' = 'MG AD FO BO FB CO HK TE'
            }
            function Dept($d) { switch -Regex ($d.Trim()) { '^MG$|Manage' { 'MG' } '^AD$|Admin' { 'AD' } '^FO$|Front' { 'FO' } '^BO$|Back' { 'BO' } '^FB$|Food|F&B' { 'FB' } '^CO$|Conv' { 'CO' } '^HK$|House' { 'HK' } '^TE$|Tech' { 'TE' } } }
            # normalise right: 'R,W' / 'R/W' / 'rw' -> 'RW'; lines with '-' or empty do not count
            function Right($r) { -join (($r.ToUpper() -replace '[^RWP]', '').ToCharArray() | Sort-Object -Unique) }
            $is = @(ReadCsv $csv | Where-Object { (Right $_.Right) } | ForEach-Object { "$($_.Share.Trim().ToLower())|$(Dept $_.Department)|$(Right $_.Right)" })
            foreach ($f in $matrix.Keys) {
                $r = if ($f -eq 'pr-office') { 'P' } else { 'RW' }
                $shouldF = @($matrix[$f].Split(' ') | ForEach-Object { "$f|$_|$r" })
                $isF = @($is | Where-Object { $_ -like "$f|*" })
                $match = (@($shouldF | Where-Object { $isF -notcontains $_ }).Count -eq 0) -and (@($isF | Where-Object { $shouldF -notcontains $_ }).Count -eq 0)
                Check "Share $f" $match 'Compare line by line with the table in Unterlagen\Hotel Vier Winde.md'
            }
        }
        $n = Content 'notes.md'
        Check 'AGDLP for Exchange explained' ($n -match 'global|GG_|G_' -and $n -match 'local|DL_') 'User -> global group (per department) -> domain local group (per share + right) -> permission'
    }
    15 {
        $csv = Join-Path $dir 'users.csv'
        Check 'users.csv exists' (Test-Path $csv)
        if (Test-Path $csv) {
            $logins = @('sandel', 'paumic', 'stefuc', 'thokni', 'gerbae', 'Leobru', 'simtau', 'petzac', 'norber', 'sanmar', 'Danber', 'thokro', 'stemei', 'thokle', 'Benkra', 'antber', 'petweb', 'Stetra', 'girpol', 'gerber', 'piaman', 'andkav', 'dandse', 'petdel', 'nicber')
            $rows = @(ReadCsv $csv)
            $is = @($rows | ForEach-Object { $_.Login })
            $missing = @($logins | Where-Object { $is -notcontains $_ })
            Check "All users entered ($($logins.Count - $missing.Count) of $($logins.Count) logins)" ($missing.Count -eq 0) "Missing e.g.: $($missing | Select-Object -First 3)"
            # sample: do first and last name match the login?
            $names = @{ sandel = 'Sandro Della Serra'; thokni = 'Thomas König'; gerbae = 'Gerhard Bär'; dandse = 'Daniel Düsentrieb'; petdel = 'Petro Del Duerr' }
            # umlauts get lost when saving without UTF-8 (König -> K?nig): allow any character in their place
            $wrongNames = @($names.Keys | Where-Object { $k = $_; $re = '^' + ([regex]::Escape($names[$k]) -replace '[äöüÄÖÜ]', '.') + '$'
                    -not ($rows | Where-Object { $_.Login -eq $k -and "$($_.FirstName.Trim()) $($_.LastName.Trim())" -match $re }) })
            Check 'First and last names entered correctly' ($wrongNames.Count -eq 0) "Check the names for: $($wrongNames -join ', ')"
        }
        $script = (((Content 'check.ps1') -replace '(?s)<#.*?#>', '') -split '\r?\n' | ForEach-Object { $_ -replace '#.*$', '' }) -join "`n"  # comments do not count
        Check 'check.ps1 calculates the expected login' ($script -match 'Substring|\.Remove\(|\[0\.\.2\]|-match' -and $script -match 'ToLower|-replace|-creplace') 'The script should calculate the login from first and last name by the rule (take 3 characters, replace umlauts, lower case)'
        $dev = @((Content 'deviations.txt') -split '\r?\n' | ForEach-Object Trim | Where-Object { $_ })
        foreach ($d in 'thokni', 'dandse', 'Leobru', 'Danber', 'Benkra', 'Stetra') { Check "Deviation $d found" ($dev -ccontains $d) }
        $wrong = @($dev | Where-Object { 'thokni', 'dandse', 'Leobru', 'Danber', 'Benkra', 'Stetra' -cnotcontains $_ })
        Check 'No correct logins reported as deviations' ($wrong.Count -eq 0) "These are correct: $($wrong -join ', ')"
    }
}

Write-Host "`nResult: $script:ok of $($script:ok + $script:fail) points" -ForegroundColor Cyan
if ($script:fail -eq 0) { Write-Host 'Lab passed! Now record what you did with "Create doc".' -ForegroundColor Green }
