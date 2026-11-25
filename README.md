# ÜK 188 Lern-Tool

> 🚧 **Beta-Version:** Das Tool wird noch entwickelt. Es kann Fehler geben, und Aufgaben können sich noch ändern. Probleme oder Ideen bitte unter [Issues](https://github.com/3234raul3234/uek-188-learning-tool/issues/new/choose) melden (dafür brauchst du ein gratis GitHub-Konto). Was neu ist, steht im [Changelog](CHANGELOG.md).

Ein Übungsprogramm für den **ÜK 188** (Services betreiben, warten und überwachen).
Du bekommst eine Windows-VM mit **15 Aufgaben**. Das Programm sagt dir sofort, ob du sie richtig gelöst hast.

---

## Was dein PC braucht
- Windows 10 oder 11, mindestens **16 GB RAM** (die VM bekommt 8 GB) und etwa **40 GB freien Speicher auf Laufwerk C:**
- Virtualisierung eingeschaltet (bei den meisten PCs schon der Fall)
- Internet für die Downloads

## Installieren (3 Schritte)

**1. VMware installieren**
**VMware Workstation Pro** ist gratis. Für den Download brauchst du ein gratis **Broadcom-Konto**:
1. Auf https://support.broadcom.com ein Konto erstellen und anmelden
2. Oben **My Downloads** öffnen → **Free Software Downloads**
3. **VMware Workstation Pro** → **for Windows** → neueste Version (17.5, 25H2 oder neuer) herunterladen und installieren

Mehr Infos: https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion

**2. Windows 11 herunterladen**
Öffne https://www.microsoft.com/software-download/windows11. Wähle unter **„Download Windows 11 Disk Image (ISO)“** (deutsch: *Windows 11-Datenträgerimage (ISO) herunterladen*) den Eintrag **„Windows 11 (multi-edition ISO for x64 devices)“** und eine **beliebige Sprache**, z. B. Deutsch. Dann lädst du die ISO-Datei herunter (ca. 7 GB).
**Lösch die ISO danach nicht**: Die VM braucht sie, und zum Neubauen auch.

**3. Dieses Tool starten**
- Klick oben auf den grünen Knopf **Code** und dann auf **Download ZIP**
- ⚠️ **Zuerst entpacken:** Rechtsklick auf die ZIP-Datei → *Alle extrahieren*
- Im **entpackten** Ordner doppelt auf **`START.cmd`** klicken. (Windows legt oft zwei gleich heissende Ordner ineinander: `START.cmd` liegt im **inneren** Ordner.) Warnt Windows, klick auf *Weitere Informationen* → *Trotzdem ausführen*
- Wähle die Windows-ISO aus Schritt 2 aus

**Fertig.** Das Tool kopiert sich nach `C:\UEK188` (den entpackten Ordner kannst du danach löschen) und baut die VM. Windows installiert sich jetzt von selbst. Warte ca. **30 Minuten** und klick in der Zeit nichts an.

**VM später wieder öffnen:** VMware starten → **File → Open** → `C:\UEK188\VM\UEK188-Win11Edu.vmx` → **Power on**.

---

## Benutzen

1. Melde dich in der VM an. Benutzer: **Administrator**, Passwort: **Lab188-uek**
2. Doppelklick auf **Lab-Trainer UeK 188** auf dem Desktop
3. Links eine Aufgabe wählen und dann:
   **Lab starten** → **Ordner öffnen** → Aufgabe lösen → **Prüfen**

Grün heisst richtig, rot heisst falsch, und unter Rot steht ein Tipp.
Alles, was du für die Aufgaben wissen musst (Netz, Benutzer, Freigaben), steht in der VM unter `C:\UEK188\Unterlagen`.

Extra-Knöpfe:
- **Doku erstellen**: schreibt dir einen Text für deine Dokumentation
- **Quiz**: fragt dich Theorie ab
- **Update**: holt die neueste Version der Aufgaben

**Tipp:** Mach direkt nach der Installation einen Snapshot: in VMware **VM → Snapshot → Take Snapshot**, Name `Frisch`. So kannst du die VM jederzeit auf frisch zurücksetzen.

**Auf deinem PC** (nicht in der VM) gibt es die Verknüpfung **Lab-Trainer UeK 188 (PC)**. Dort hat der Lab-Trainer zwei Knöpfe mehr:
- **VM aktualisieren**: bringt neue Aufgaben in die laufende VM
- **VM zurücksetzen**: setzt die VM auf den Snapshot `Frisch` zurück (gibt es noch keinen, legt der Knopf ihn an)

---

## Gut zu wissen

- Windows ist **nicht aktiviert**, unten rechts erscheint ein Wasserzeichen. Zum Üben funktioniert alles. Für eine Aktivierung brauchst du eine eigene Lizenz.
- Das Passwort ist nur für diese VM. Verwende es nirgends sonst.
- Die Tastatur in der VM ist auf **Schweizerdeutsch** eingestellt. Ändern kannst du sie in Windows unter *Einstellungen → Zeit und Sprache → Sprache und Region*.
- Etwas kaputt gemacht? Snapshot zurücksetzen oder `C:\UEK188\START.cmd` starten und die VM neu bauen lassen.

## Lizenz

Du darfst das Tool **benutzen**, um zu lernen. **Kopieren, weitergeben und verkaufen ist nicht erlaubt.** Die Details stehen in [LICENSE](LICENSE).
