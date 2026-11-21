# Electric – Anzeige für Elektroflieger (FrSky Ethos)

[English](README.md) · **Deutsch** · Doku: [Wiki (Deutsch)](wiki/de/Installation.md) · [Wiki (English)](wiki/en/Installation.md)

> **Am PC einrichten mit [Lua-Studio](https://github.com/Raffi1202/lua-studio)**: Bildschirm einteilen, Werte, Alarme und Symbole wählen, auf die Funke übertragen.

Ethos-Widget für Elektroflieger auf FrSky-Sendern mit Farbdisplay. Es zeigt auf einem Bildschirm Akku, Zellen,
Strom, Drehzahl, Reglertemperatur, Verbrauch, Leistung, Höhe, Speed und Empfang. Dazu kommen Warnungen und Alarme
mit Sprachansagen sowie eine Flugliste. Anzeige, Menü und Ansagen gibt es auf Deutsch und Englisch.

![Electric auf 800 × 480 (Ethos-Simulator)](docs/bilder-simulator/Electric%20-%20Sim%20800x480%2004%20Normal.png)

- **Vier Tachos:** Akku %, Strom, Drehzahl und Reglertemperatur.
- **Sechs Felder:** Zelle, Verbraucht, Leistung, Höhe, Speed und Empfang, dazu ein grosses Feld **Gas %** (aus dem
  Gaskanal, mit dem Strom dazu). Was wo steht, wählst du im Menü.
- **Vollbild oder kompakt:** Im Layout mit Ethos-Kopf- und Fussleiste zeigt Electric von selbst eine Kompaktansicht
  mit vier Tachos und acht Feldern.
- **Zellen:** mit Zellensensor die tiefste Zelle und die Differenz, ohne Zellensensor Gesamtspannung ÷ Zellenzahl.
- **Akku %:** vom Regler oder aus Ruhespannung und verbrauchten mAh gerechnet.
- **Grenzwerte:** zwei je Wert (Warnung orange, Alarm rot mit Ton und Ansage).
- **Schalter:** Ansage auf SG↓, «Motor aus» auf SF↑.
- **Flugliste:** die letzten 20 Flüge, einzeln löschbar.
- **Sensoren** werden beim ersten Start automatisch zugewiesen. Was du von Hand wählst, bleibt.
- **Lua-Studio (neu in 0.3.0):** Eine Einstellungsdatei je Modell aus dem PC-Programm Lua-Studio gestaltet die
  Anzeige frei (Kästchen mit Zahl, Ring, Balken, Verlauf oder Status, eigene Farben) und setzt Einstellungen und
  Grenzwerte. Ohne diese Datei läuft alles wie bisher.
- **Symbole und Schmuck (neu in 0.4.0, Lua-Studio-Format 2):** Kästchen mit Symbol und fetter Einheit, dazu frei
  platzierte Symbole, Texte, Linien und Rahmen. Format-1-Dateien laufen unverändert.
- **Neu in 0.6.0 (Bruch):** umbenannt von «Elektro» in **Electric** (Widget, Ordner `scripts/electric`, Studio-Datei `….electric.lua`). Das Widget in jedem Modell neu wählen, siehe [Umstieg](wiki/de/Installation.md#umstieg-von-der-deutschen-version-elektro).
- **Neu in 0.5.0:** «Alarm auch bei Motor aus» je Wert (Menü und Lua-Studio, ab Werk ein), Speicher wird beim
  Modellwechsel freigegeben (es bleiben rund 5 KB statt über 100 KB), Studio-Datei lädt schneller und zeigt
  «Studio-Datei wird geladen ...» statt kurz der Standardanzeige.

**Status:** öffentliche Vorabversion (pre-release / public beta). Lizenz: GPL-3.0, siehe unten.

## Schnellstart in 5 Schritten

1. `Electric-0.6.1.zip` aus dem neusten **Release** herunterladen (rechts auf der Repo-Seite unter «Releases»).
2. Sender per USB anschliessen, am Sender **Ethos Suite** wählen, am Computer die **FrSky Suite** öffnen.
3. Suite › **Lua-Bibliothek** › **Von lokaler ZIP installieren** › die ZIP wählen. Danach den Sender neu starten.
4. Modell › Bildschirme › **+** › Layout **Vollbild** (oder mit Leisten) › ins Feld tippen › Widget **Electric**.
5. Modell einschalten: Electric sucht die Sensoren selbst. Danach im Widget-Menü unter **Akku** Akkuart, Zellenzahl und Kapazität einstellen.

Ohne Suite geht es auch per USB-Speicher bzw. SD-Karte (Anleitung Kapitel 2). Beim Aktualisieren bleiben
Einstellungen, Flüge und Zähler erhalten.

## Anleitung und Testen

| Was | Datei |
|---|---|
| Anleitung zum Ausdrucken | [`docs/Electric - Anleitung.pdf`](docs/Electric%20-%20Anleitung.pdf) (HTML-Fassung in `docs/anleitung/`) |
| Manual (English) | [`docs/Electric - Manual.pdf`](docs/Electric%20-%20Manual.pdf) |
| Testleitfaden für Tester (Häkchenliste) | [`TESTLEITFADEN.md`](TESTLEITFADEN.md) |
| Fehler melden, Wünsche | GitHub › Issues › New issue (Vorlagen «Fehler / Bug» und «Wunsch / Idee») |
| Versionen | [`CHANGELOG.md`](CHANGELOG.md) |
| Texte der Sprachansagen | [`docs/Sprachansagen.md`](docs/Sprachansagen.md) |

## Sender und Stand der Erprobung (Version 0.6.1, 21.11.2026)

| Display | Sender | Stand |
|---|---|---|
| 800 × 480, Berührung | X20, X20S, X20HD, X20 Pro, X20R, X20RS, X18R, **X18RS** | **X18RS am echten Sender getestet** (Ethos 26.2.0), die übrigen nur im Simulator |
| 640 × 360, ohne Berührung | Twin X14, X14S | nur im Simulator nachgestellt |
| 480 × 320, Berührung | X18, X18S, X18SE, Twin X Lite, Twin X Lite S | nur im Simulator nachgestellt |
| 480 × 272, ohne Berührung | X10, X10S, X10 Express, X12S (mit Ethos) | nur im Simulator nachgestellt |

**Am echten Sender geprüft** (X18RS, Ethos 26.2.0, Empfänger SR10 Plus am FBUS, Telemetrie aus einem Sensor-Simulator):
- Seiten 1 und 2 werden sauber angezeigt, das Log bleibt leer.
- Die automatische Sensorsuche läuft mit 48 Sensoren durch, auch mit doppelten Sensoren und mehreren Instanzen.
- Nach einem Neuladen der Skripte bleibt das Log ohne Fehler.
- Version 0.1.6: volle Flugliste (20 Flüge) laden, einen Flug löschen, Nummern rücken nach, Datei geschrieben, Log leer.
- Version 0.2.0: Kompaktansicht im Layout mit Leisten (784 × 316) mit Live-Telemetrie sauber, Gas % live von 0 bis 100 %
  mit Balken, Flugerkennung über Gas, Rückfrage AUF 0, Flugliste öffnen und zurück, Update von 0.1.6 ohne Verlust, Log leer.
- Version 0.3.0 (ohne Telemetrie): Einstellungsdatei aus Lua-Studio. Ohne Datei entsteht die Info-Datei für Lua-Studio;
  die Demo-Datei wird geladen und angezeigt; Änderungen im Widget-Menü gehen in `…electric.funke.lua` (neu schreiben,
  vorhandene Datei ersetzen, bleibt nach dem Neuladen, «Zurück» stellt den Studio-Stand her und entfernt sie); eine
  kaputte Datei zeigt einen Hinweis und die Standardansicht statt eines Absturzes; Lua-Studio 0.2.0 überträgt eine
  Einstellungsdatei per Serial und Electric lädt sie. Log jeweils leer.
- Version 0.3.0 mit Telemetrie aus einem Sensor-Simulator: Live-Werte und Sensorsuche sauber; ein Alarm (Reglertemperatur)
  kommt mit Ton und Ansage bei Motorschalter aus. Den Fall «ein» hat 0.3.0 wegen eines Fehlers nicht erkannt (Pille immer
  MOTOR AUS).
- Version 0.3.1: Motorschalter SF in beiden Stellungen richtig (Pille SCHARF / MOTOR AUS, Log), Alarm (Reglertemperatur)
  bei SF scharf und aus, Flugerkennung über SF mit Rückfrage «Flug beendet?», Flugliste mit Details (Vollbild), Log leer.
  **Nicht bestanden:** Nach «Alle Sensoren löschen» und neuer Suche in Ethos zeigen die Felder 0, auch nach «Suchen» im
  Widget. Umweg: Modell neu laden (anderes Modell wählen und zurück), dann im Widget-Menü «Suchen».
- Version 0.3.2: Info-Datei für Lua-Studio mit Sensorliste.
- Version 0.4.0 (Lua-Studio-Format 2): volle Testdatei der Lua Suite (16 Plätze mit Symbol 64 px und fetter Einheit,
  Schmuck) im Vollbild, 10 Modellwechsel, Log leer (kein «Max instructions»). Eine in Lua-Studio gestaltete und per
  Serial übertragene Ansicht (7 Symbole 32 px, fette Einheit) wird geladen und gezeigt.
- Die Sprachansagen wurden mit Version 0.1.2 abgehört.

**Noch nicht am echten Sender geprüft:**
- alles Neue aus Version 0.5.0 (bisher nur Simulator und Mac-Tests).
- jeder Menüpunkt einzeln
- Zeilen der Flugliste in der Kompaktansicht antippen
- Studio-Platz mit Sensor, Ton bei Studio-Alarm ohne Ansage (0.3.2)
- Format 2 im Layout mit Leisten (784 × 316), Sensorsuche mit 0.4.0, zwei Luas mit demselben Symbol
- Zellen-Alarm
- Kompaktansicht mit Einstellungsdatei aus Lua-Studio, englische Sprache mit Einstellungsdatei
- Neustart des Senders mit pausiertem Flug (neu in 0.1.6, nur am Mac und im Simulator getestet)
- Flugerkennung und Flugliste mit einem echten Flug
- echte Regler-Telemetrie im Flug
- alle Sender ausser der X18RS

**Im Simulator** (Ethos 26.2.0) laufen 24 Abläufe auf allen Displaygrössen (Vollbild und kompakt) fehlerfrei, dazu auf dem Mac ein Zufallstest, ein Update-Test von der Vorversion und Tests für Sensorsuche und Neustart.

**Bekannte Grenzen:**
- Kompaktansicht (neu in 0.2.0): Fenstergrössen 784 × 316 (X20, X18RS), 630 × 258 (X14), 472 × 210 (X18, Twin X Lite) im
  Simulator gemessen und getestet; am echten Sender: siehe oben.
- X10 / X12 (480 × 272): kein Simulator für das Layout mit Leisten, Kompaktansicht dort nicht geprüft.
- Befehle je Aufruf (Lua-Studio-Format 2 verlangt unter 5 000): am Mac gezählt braucht das Zeichnen bis rund 13 000
  (volle Format-2-Datei; eingebaute Seite rund 8 700) und ein wakeup bis rund 9 100 (Sensorsuche; ohne Studio-Datei
  rund 7 600). Die Pflichttests 12, 16 und 17 des Formats sind in diesem Punkt offen. Am X18RS lief die volle Datei
  ohne «Max instructions».
- Der Lua-Speicher liegt bei rund 133 KB. Mit vielen anderen Lua-Widgets auf dem Sender kann er knapp werden.
- Getestet ist nur Ethos 26.2.

## Wo liegt was

| Inhalt | Ort |
|---|---|
| Skript, 1:1 so wie es auf den Sender kommt | `src/electric/` |
| Anleitung (PDF, Quelle als HTML) | `docs/`, `docs/anleitung/` |
| Bilder aus dem Ethos-Simulator | `docs/bilder-simulator/` |
| Abläufe für den Simulator, Mac-Tests | `test/` |
| Release-ZIP (nicht im Repo, als Download im GitHub-Release) | `dist/` |

## Entwickeln

Für Tester nicht nötig. Die Tests auf dem Mac laufen mit Lua 5.4 aus dem Repo-Ordner, z. B.:

```sh
luac -p src/electric/*.lua
lua test/motoraus-test.lua
lua test/speicher-test.lua
lua test/suche-test.lua src/electric
lua test/format2-test.lua "<Ordner mit den Format-2-Testdateien von Lua-Studio>"
```

Die Abläufe `test/*.json` sind für einen Simulator-Treiber auf Basis des Ethos-WASM-Simulators (Plugin «ethos-tools»)
gedacht; dieser Treiber, der Zufallstest und die Skripte für PDF und Paket gehören zum Bauwerkzeug des Autors und sind
nicht Teil dieses Repos.

## Weitere Projekte

| Projekt | Wozu |
|---|---|
| [Heli](https://github.com/Raffi1202/heli-lua) | Ethos-Widget für Helis (Rotorflight) |
| [Jet](https://github.com/Raffi1202/jet-lua) | Ethos-Widget für Turbinen (mehrere ECU-Hersteller) |
| [Glider](https://github.com/Raffi1202/glider-lua) | Ethos-Widget für Segler (Vario, Thermik) |
| [Gas Engine ECU / Carb](https://github.com/Raffi1202/gas-engine-lua) | Ethos-Widgets für Verbrennungsmotoren |
| [Lua-Studio](https://github.com/Raffi1202/lua-studio) | PC-Programm zum Einrichten der Widgets (Mac/Windows) |
| [Ethos-Sensor-IDs](https://github.com/Raffi1202/ethos-sensor-ids) | Welchen Sensor Ethos zu jeder AppID anlegt |

## Lizenz

GPL-3.0, siehe [LICENSE](LICENSE). Der Baustein `src/electric/studio_symbole.lua` stammt aus Lua-Studio (gleicher Autor, gleiche Lizenz).
