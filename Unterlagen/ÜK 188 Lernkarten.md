# UEK 188 Flashcards

Answer yourself first, then expand.

## DHCP
> [!question]- What are the 4 steps of DHCP (DORA)?
> **D**iscover (client searches by broadcast) → **O**ffer (server offers an IP) → **R**equest (client requests it) → **A**cknowledge (server confirms).

> [!question]- What is a scope, a reservation and an exclusion?
> Scope = IP range the server hands out. Reservation = fixed IP for a MAC address. Exclusion = addresses in the scope that are never handed out (e.g. for servers and printers).

> [!question]- A client has 169.254.x.x. What does that mean?
> APIPA: the client did not reach a DHCP server. Check: cable/VLAN, is the DHCP service running, is the scope full, is a DHCP relay missing?

## DNS
> [!question]- Name the most important DNS records.
> A (name → IPv4), AAAA (name → IPv6), CNAME (alias), MX (mail server), PTR (IP → name, reverse lookup), SRV (services, e.g. finding AD domain controllers), NS (responsible name server).

> [!question]- Why is DNS so important for Active Directory?
> Clients find the domain controllers via SRV records. Without working DNS there is no logon, no GPOs and no domain join.

> [!question]- Which commands do you use to test DNS?
> `nslookup name`, `Resolve-DnsName name`, `ipconfig /flushdns`, `ipconfig /all` (which DNS server is configured?).

## Active Directory & permissions
> [!question]- What is the difference between a domain, an OU and a group?
> Domain = administrative and security boundary. OU = folder for structuring; GPOs are linked there. Group = collects users to give them permissions.

> [!question]- What does AGDLP mean?
> **A**ccounts go into **G**lobal groups, these into **D**omain **L**ocal groups, and these get the **P**ermissions. Never give permissions directly to users.

> [!question]- Share and NTFS permissions contradict each other. Which applies?
> Over the network the more restrictive of the two applies. Locally only NTFS applies. An explicit deny beats an allow.

> [!question]- What is inheritance in NTFS and when do you break it?
> Subfolders take over the permissions of the parent folder. You break it when a folder has to be protected more strictly (e.g. accounting or HR).

> [!question]- What is the principle of least privilege?
> Everyone gets only the rights they need for their work, and no more.

## Operations & monitoring
> [!question]- Which start types does a Windows service have?
> Automatic, Automatic (delayed start), Manual (also trigger start) and Disabled.

> [!question]- Which values do you monitor on a server at least?
> CPU, RAM, free disk space, network, whether the services are running (availability) and the event log (errors, logons).

> [!question]- What is a threshold and why are there warning and critical levels?
> A limit from which an alarm is raised. The warning gives you time to react before the value becomes critical and the service fails.

> [!question]- Name monitoring tools and a protocol for them.
> PRTG, Zabbix, Checkmk, Nagios; Windows: Performance Monitor, Event Viewer. Protocols: SNMP, WMI.

> [!question]- Where do you find errors of a service in Windows?
> In the Event Viewer under Windows Logs → System or Application, in PowerShell with `Get-WinEvent`.

## Updates & patches
> [!question]- What does clean patch management look like?
> Review updates → install in a test group first → test → release for everyone → update the operations documentation. Make a backup or snapshot first.

> [!question]- What is WSUS or a software distribution system?
> A central server that approves updates and distributes them to the clients, e.g. WSUS, Intune or SCCM/MECM. That way you control what is installed and when.

> [!question]- What is Patch Tuesday?
> On the 2nd Tuesday of the month Microsoft publishes its regular security updates.

## Documentation
> [!question]- What belongs in operations documentation?
> System overview (servers, IPs, roles), services and their dependencies, permission concept, patch level, monitoring thresholds, emergency and recovery procedure, change log.
