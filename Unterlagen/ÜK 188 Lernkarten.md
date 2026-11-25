# ÜK 188 Lernkarten

Erst selbst antworten, dann aufklappen.

## DHCP
> [!question]- Welche 4 Schritte hat DHCP (DORA)?
> **D**iscover (Client sucht per Broadcast) → **O**ffer (Server bietet IP an) → **R**equest (Client fordert sie an) → **A**cknowledge (Server bestätigt).

> [!question]- Was ist ein Scope, eine Reservierung und ein Ausschluss?
> Scope = IP-Bereich, den der Server vergibt. Reservierung = feste IP für eine MAC-Adresse. Ausschluss = Adressen im Scope, die nie vergeben werden (z. B. für Server und Drucker).

> [!question]- Ein Client hat 169.254.x.x. Was bedeutet das?
> APIPA: Der Client hat keinen DHCP-Server erreicht. Prüfen: Kabel/VLAN, läuft der DHCP-Dienst, ist der Scope voll, fehlt ein DHCP-Relay?

## DNS
> [!question]- Nenne die wichtigsten DNS-Records.
> A (Name → IPv4), AAAA (Name → IPv6), CNAME (Alias), MX (Mailserver), PTR (IP → Name, Reverse Lookup), SRV (Dienste, z. B. AD-Domänencontroller finden), NS (zuständiger Nameserver).

> [!question]- Warum ist DNS für Active Directory so wichtig?
> Clients finden die Domänencontroller über SRV-Records. Ohne funktionierendes DNS gibt es keine Anmeldung, keine GPOs und keinen Domänenbeitritt.

> [!question]- Mit welchen Befehlen testest du DNS?
> `nslookup name`, `Resolve-DnsName name`, `ipconfig /flushdns`, `ipconfig /all` (welcher DNS-Server ist eingetragen?).

## Active Directory & Berechtigungen
> [!question]- Was ist der Unterschied zwischen Domäne, OU und Gruppe?
> Domäne = Verwaltungs- und Sicherheitsgrenze. OU = Ordner zum Strukturieren; dort hängen GPOs. Gruppe = sammelt Benutzer, um ihnen Berechtigungen zu geben.

> [!question]- Was bedeutet AGDLP?
> **A**ccounts kommen in **G**lobale Gruppen, diese in **D**omänenlokale Gruppen, und diese bekommen die **P**ermissions. Berechtigungen nie direkt an Benutzer vergeben.

> [!question]- Freigabe- und NTFS-Berechtigung widersprechen sich. Was gilt?
> Über das Netzwerk gilt die restriktivere der beiden. Lokal gilt nur NTFS. Ein explizites Verweigern schlägt ein Zulassen.

> [!question]- Was ist Vererbung bei NTFS und wann unterbricht man sie?
> Unterordner übernehmen die Rechte des übergeordneten Ordners. Man unterbricht sie, wenn ein Ordner strenger geschützt sein muss (z. B. Buchhaltung oder HR).

> [!question]- Was ist das Prinzip der minimalen Rechte (Least Privilege)?
> Jeder bekommt nur die Rechte, die er für seine Arbeit braucht, und nicht mehr.

## Betrieb & Überwachung
> [!question]- Welche Starttypen hat ein Windows-Dienst?
> Automatisch, Automatisch (verzögert), Manuell (auch Trigger-Start) und Deaktiviert.

> [!question]- Welche Werte überwacht man bei einem Server mindestens?
> CPU, RAM, freien Speicherplatz, Netzwerk, ob die Dienste laufen (Verfügbarkeit) und das Ereignisprotokoll (Fehler, Anmeldungen).

> [!question]- Was ist ein Schwellwert und warum gibt es Warnung und Kritisch?
> Ein Grenzwert, ab dem ein Alarm kommt. Die Warnung lässt Zeit zu reagieren, bevor der Wert kritisch wird und der Service ausfällt.

> [!question]- Nenne Monitoring-Tools und ein Protokoll dafür.
> PRTG, Zabbix, Checkmk, Nagios; Windows: Leistungsüberwachung, Ereignisanzeige. Protokolle: SNMP, WMI.

> [!question]- Wo findest du Fehler eines Dienstes unter Windows?
> In der Ereignisanzeige unter Windows-Protokolle → System bzw. Anwendung, in PowerShell mit `Get-WinEvent`.

## Updates & Patches
> [!question]- Wie läuft sauberes Patch-Management ab?
> Updates prüfen → zuerst in einer Testgruppe installieren → testen → für alle freigeben → Betriebsdoku nachführen. Vorher ein Backup oder einen Snapshot machen.

> [!question]- Was ist WSUS bzw. ein Softwareverteilungssystem?
> Ein zentraler Server, der Updates freigibt und an die Clients verteilt, z. B. WSUS, Intune oder SCCM/MECM. So hat man die Kontrolle darüber, was wann installiert wird.

> [!question]- Was ist der Patch Tuesday?
> Am 2. Dienstag im Monat veröffentlicht Microsoft seine regulären Sicherheitsupdates.

## Dokumentation
> [!question]- Was gehört in eine Betriebsdokumentation?
> Systemübersicht (Server, IPs, Rollen), Services und ihre Abhängigkeiten, Berechtigungskonzept, Patch-Stand, Monitoring-Schwellwerte, Notfall- und Wiederherstellungsablauf, Änderungsprotokoll.
