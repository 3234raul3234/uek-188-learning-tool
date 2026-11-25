# Changelog

Was sich in jeder Version geändert hat. Die neueste Version steht oben.
In der VM holst du die neueste Version mit dem Knopf **Update** im Lab-Trainer.

## Beta 0.3 – 25.11.2026
- **Behoben:** Die Installation funktioniert jetzt mit einer Windows-ISO in jeder Sprache. Sprache und Edition werden aus der ISO gelesen.
- **Behoben:** Quiz und Lab 10, 13, 14 und 15 funktionieren bei allen. Lernkarten und Szenario-Daten liegen jetzt in `Unterlagen/`.
- **Behoben:** „VM zurücksetzen“ bietet an, den Snapshot anzulegen, wenn es noch keinen gibt.
- **Behoben:** Knöpfe im Lab-Trainer lagen übereinander.
- **Behoben:** VMware wird auch an einem anderen Installationsort gefunden.
- **Behoben:** Lab 14 akzeptiert CSV mit „;“ und ohne UTF-8, Lab 15 prüft jetzt auch Namen und Skript.
- **Behoben:** START.cmd meldet, wenn die ZIP-Datei nicht entpackt ist. Ein Fehler beim VM-Start wird angezeigt.
- **Update** holt jetzt auch die Unterlagen.
- README: Systemvoraussetzungen, Broadcom-Konto, welche ISO, Snapshot-Tipp.

## Beta 0.2 – 25.11.2026
- **Neu:** Knopf **Update** im Lab-Trainer holt die neuesten Labs von GitHub (mit Prüfung und Backup)
- **Neu:** Versionsnummer im Lab-Trainer
- **Neu:** Selbsttest für alle 15 Labs (`Tests/selbsttest.ps1`), läuft bei jedem Push automatisch auf GitHub
- **Neu:** Formulare für Fehler und Ideen unter *Issues*
- **Behoben:** Lab 5 stürzte bei manchen Netzwerkkarten ab

## Beta 0.1 – 25.11.2026
- 15 Labs mit automatischer Kontrolle
- Lab-Trainer mit Doku-Helfer und Quiz
- Ein-Klick-Installation mit `START.cmd`
- Lizenz: benutzen erlaubt, kopieren und verkaufen nicht
