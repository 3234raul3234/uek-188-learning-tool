# Szenario: Hotel Vier Winde

Die Labs spielen in der (fiktiven) Firma **Hotel Vier Winde AG**. Hier stehen alle Daten, die du für die Labs brauchst.

## Netz
| | |
|---|---|
| Netzwerk | 172.18.20.64/26 (255.255.255.192) |
| Gateway / Firewall (OPNsense) | 172.18.20.65 – am Anfang auch DNS |
| Clients DHCP (ws01–ws50) | 172.18.20.66 – .115 |
| Drucker | 172.18.20.116 – .119 |
| Server | 172.18.20.120 – .126 |
| DNS- und DHCP-Server (später) | 172.18.20.120 (titan) |
| Domäne | hoviwi.local |

## Systeme (VMs, Netzwerkadapter intnet-lan)
| Name | System | IP | VM |
|---|---|---|---|
| titan | Windows Server 2025 Standard (Desktop) | 172.18.20.120 | 2 vCPU, 4 GB, 100 GB |
| atlas | Ubuntu Desktop 24.04 | 172.18.20.121 | 2 vCPU, 4 GB, 50 GB |
| helios | Ubuntu Server 24.04 | 172.18.20.122 | 2 vCPU, 4 GB, 50 GB |
| ws01 | Windows 11 | statisch, bis DHCP läuft | 2 vCPU, 4 GB, 100 GB |

- **titan Rollen:** AD DS, DNS, DHCP, Datei- und Druckdienste, SNMP, Windows Server Backup
- **ws01:** nur das lokale Administratorkonto ist aktiv · Tools: Firefox, Notepad++
- **Drucker pr-office:** HP Color LaserJet Enterprise Flow MFP X58045z, Treiber Universal PCL-6

## Benutzer (Kapitel 5.3 – 5.9)
| Abteilung | Vorname | Nachname | Login |
|---|---|---|---|
| Administration | Sandro | Della Serra | sandel |
| Administration | Paula | Michel | paumic |
| Administration | Stefanie | Fuchs | stefuc |
| Administration | Thomas | König | thokni |
| Back Office | Gerhard | Bär | gerbae |
| Back Office | Leonora | Brunner | Leobru |
| Back Office | Simon | Tauber | simtau |
| Front Office | Gerhard | Bär | gerbae |
| Front Office | Petra | Zack | petzac |
| Front Office | Nora | Berger | norber |
| Front Office | Sandra | Martinez | sanmar |
| Front Office | Daniela | Bertolini | Danber |
| Front Office | Thomas | Kro | thokro |
| Front Office | Stefan | Meier | stemei |
| Front Office | Thomas | Kleiner | thokle |
| Food & Beverage | Benjamin | Krakenhofer | Benkra |
| Food & Beverage | Antonio | Bernardo | antber |
| Food & Beverage | Peter | Weber | petweb |
| Convention | Stefanie | Trapp | Stetra |
| Convention | Girgio | Politano | girpol |
| Housekeeping | Gertrude | Bertram | gerber |
| Housekeeping | Pia | Manjou | piaman |
| Housekeeping | Andrea | Kaviezel | andkav |
| Technik | Daniel | Düsentrieb | dandse |
| Technik | Petro | Del Duerr | petdel |
| Technik | Nico | Berger | nicber |

## Serverfreigaben und Berechtigungen (Kapitel 5.10)
L = Lesen/Ausführen · S = Schreiben · D = Drucken · – = keine Rechte

| Freigabe | Geschäftsleitung | Administration | Front-Office | Back-Office | Food & Beverage | Convention | Housekeeping | Technik |
|---|---|---|---|---|---|---|---|---|
| Austausch | L,S | L,S | L,S | L,S | L,S | L,S | L,S | L,S |
| Front-office | L,S | – | L,S | – | – | – | – | – |
| BO | L,S | – | – | L,S | – | – | – | – |
| Administration | L,S | L,S | – | – | L,S | L,S | – | – |
| Conv | L,S | – | – | – | L,S | L,S | – | – |
| FOBE | L,S | – | – | – | – | L,S | – | – |
| Saal | L,S | L,S | L,S | L,S | – | L,S | – | L,S |
| Bar | L,S | L,S | L,S | L,S | L,S | L,S | – | L,S |
| Sitzungen | L,S | L,S | L,S | L,S | – | L,S | – | L,S |
| Büros | L,S | L,S | L,S | L,S | – | L,S | – | L,S |
| pr-office | D | D | D | D | D | D | D | D |
