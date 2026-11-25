# Scenario: Hotel Vier Winde

The labs take place at the (fictional) company **Hotel Vier Winde Ltd**. This page contains all the data you need for the labs.

## Network
| | |
|---|---|
| Network | 172.18.20.64/26 (255.255.255.192) |
| Gateway / firewall (OPNsense) | 172.18.20.65 – also DNS at the beginning |
| Clients DHCP (ws01–ws50) | 172.18.20.66 – .115 |
| Printers | 172.18.20.116 – .119 |
| Servers | 172.18.20.120 – .126 |
| DNS and DHCP server (later) | 172.18.20.120 (titan) |
| Domain | hoviwi.local |

## Systems (VMs, network adapter intnet-lan)
| Name | System | IP | VM |
|---|---|---|---|
| titan | Windows Server 2025 Standard (Desktop) | 172.18.20.120 | 2 vCPU, 4 GB, 100 GB |
| atlas | Ubuntu Desktop 24.04 | 172.18.20.121 | 2 vCPU, 4 GB, 50 GB |
| helios | Ubuntu Server 24.04 | 172.18.20.122 | 2 vCPU, 4 GB, 50 GB |
| ws01 | Windows 11 | static until DHCP runs | 2 vCPU, 4 GB, 100 GB |

- **titan roles:** AD DS, DNS, DHCP, File and Print Services, SNMP, Windows Server Backup
- **ws01:** only the local Administrator account is enabled · tools: Firefox, Notepad++
- **Printer pr-office:** HP Color LaserJet Enterprise Flow MFP X58045z, driver Universal PCL-6

## Users
| Department | First name | Last name | Login |
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
| Technical | Daniel | Düsentrieb | dandse |
| Technical | Petro | Del Duerr | petdel |
| Technical | Nico | Berger | nicber |

## Server shares and permissions
R = read/execute · W = write · P = print · – = no rights

| Share | Management | Administration | Front Office | Back Office | Food & Beverage | Convention | Housekeeping | Technical |
|---|---|---|---|---|---|---|---|---|
| Exchange | R,W | R,W | R,W | R,W | R,W | R,W | R,W | R,W |
| Front-office | R,W | – | R,W | – | – | – | – | – |
| BO | R,W | – | – | R,W | – | – | – | – |
| Administration | R,W | R,W | – | – | R,W | R,W | – | – |
| Conv | R,W | – | – | – | R,W | R,W | – | – |
| FOBE | R,W | – | – | – | – | R,W | – | – |
| Hall | R,W | R,W | R,W | R,W | – | R,W | – | R,W |
| Bar | R,W | R,W | R,W | R,W | R,W | R,W | – | R,W |
| Meetings | R,W | R,W | R,W | R,W | – | R,W | – | R,W |
| Offices | R,W | R,W | R,W | R,W | – | R,W | – | R,W |
| pr-office | P | P | P | P | P | P | P | P |
