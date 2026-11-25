# Changelog

Was sich in jeder Version geändert hat. Die neueste Version steht oben.
In der VM holst du die neueste Version mit dem Knopf **Update** im Lab-Trainer.

## Beta 0.4 – 25.11.2026
- **Behoben:** Lab 15 akzeptiert Namen auch dann, wenn die CSV ohne UTF-8 gespeichert wurde (Umlaute). Kommentare zählen nicht mehr als Skript.
- **Behoben:** Lab 14 prüft auch das Recht jeder Zeile, falsche Zusatzzeilen fallen auf. Abkürzungen (GL, FO, …) sind erlaubt.
- **Behoben:** Lab 13 akzeptiert Markdown-Fettdruck. Lab 10 erkennt „4096 MB“ und „255.255.255.192“ und hat Tipps.
- **Behoben:** Der erste Klick auf „Update“ meldete immer „neu“.
- **Behoben:** Reste einer alten Version konnten alte Unterlagen in die VM bringen.
- **Behoben:** START.cmd fragt zuerst und kopiert erst danach. Auf dem PC gibt es jetzt die Verknüpfung „Lab-Trainer UeK 188 (PC)“.
- Selbsttest lässt eine echte Lab-12-Aufgabe in Ruhe.
- Lizenz klarer: Benutzen in Lehre, Berufsschule und ÜK erlaubt.
- README: Broadcom-Klickweg, ISO behalten, innerer Ordner, VM wieder öffnen, Tastatur.

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
