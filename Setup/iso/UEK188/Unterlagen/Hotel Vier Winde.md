# Hotel Vier Winde – Spickzettel

Kurzfassung aus der Betriebsdoku (v2.0) und dem Netzwerkplan für [[ÜK 188]]. Original in Moodle.

## Netz
| | |
|---|---|
| Netzwerk | 172.18.20.64/26 (255.255.255.192) |
| Hosts | .65 – .126 (62), Broadcast .127 |
| Gateway / Firewall (OPNsense) | 172.18.20.65 – am Anfang auch DNS |
| Clients DHCP (ws01–ws50) | 172.18.20.66 – .115 |
| Drucker | 172.18.20.116 – .119 |
| Server | 172.18.20.120 – .126 |
| DNS- und DHCP-Server (später) | 172.18.20.120 (titan) |
| Domäne | hoviwi.local |

## Systeme (VirtualBox, Adapter intnet-lan)
| Name | System | IP | VM |
|---|---|---|---|
| titan | Windows Server 2025 Standard (Desktop) | 172.18.20.120 | 2 vCPU, 4 GB, 100 GB |
| atlas | Ubuntu Desktop 24.04 | 172.18.20.121 | 2 vCPU, 4 GB, 50 GB |
| helios | Ubuntu Server 24.04 | 172.18.20.122 | 2 vCPU, 4 GB, 50 GB |
| ws01 | Windows 11 Pro | statisch, bis DHCP läuft | 2 vCPU, 4 GB, 100 GB |
| OPNsense | Firewall | .65 | – |

- **titan Rollen:** AD DS, DNS, DHCP, Datei- und Druckdienste, SNMP, Windows Server Backup
- **ws01:** nur lokales Administratorkonto aktiv · Tools: Firefox, Notepad++
- **Drucker pr-office:** HP Color LaserJet Enterprise Flow MFP X58045z, Treiber Universal PCL-6, alle Abteilungen dürfen drucken

## Abteilungen
Geschäftsleitung · Administration · Front-Office (7x24) · Back-Office · Food & Beverage · Convention · Housekeeping · Technik

## Auffälligkeiten in der Doku
- Logins nicht einheitlich (Gross-/Kleinschreibung, thokni, dandse) → [[ÜK 188]] Lab 15
- Freigaben teils `C:\Freigabe\…`, teils `C:\Freigaben\…` oder `C:\Kunden\…`
