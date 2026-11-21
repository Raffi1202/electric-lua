[🇬🇧 English](../en/Installation.md) · 🇩🇪 Deutsch

# Installation

## 1. Was du brauchst

- Einen FrSky-Sender mit Ethos 26.2 (getestet) und Farbdisplay (Liste am Schluss).

- Ein Elektromodell mit Telemetrie, die Sensoren schon gesucht (Modell › Telemetrie › Sensoren suchen). Nötig ist mindestens die Akkuspannung; Strom, Verbrauch, Drehzahl, Temperatur, Höhe, Speed und Zellensensor sind freiwillig.

- Einen Computer mit der FrSky Suite und ein USB-Kabel.

- Die Datei `Elektro-0.5.0.zip`. Sie liegt neben dieser Anleitung in `Elektro-0.5.0-zum-Teilen.zip`. Entpacke nur die äussere ZIP, die innere nicht.

## 2. Installieren

1. Sender einschalten und mit dem USB-Kabel am Computer anschliessen.
2. Am Sender erscheint eine Auswahl. Wähle **Ethos Suite**.
3. Öffne am Computer die **FrSky Suite**. Der Sender wird oben angezeigt.
4. Klicke auf **Lua-Bibliothek**, dann auf **Von lokaler ZIP installieren**.
5. Wähle die Datei `Elektro-0.5.0.zip`. Die Suite kopiert alles an den richtigen Ort.
6. Ziehe das Kabel ab und starte den Sender neu.

Ohne Suite: Sender als «USB-Speicher» anschliessen und den Ordner `elektro` aus der ZIP in den Ordner `scripts` kopieren. Lädt dein Sender die Skripte von der SD-Karte (System › Allgemein › Speicherort), gehört er nach `scripts` auf der SD-Karte. Einen vorhandenen Ordner überschreiben, nicht löschen.

## 11. Welche Sender

| Display | Sender | Stand |
|---|---|---|
| 800 × 480, Berührung | X20, X20S, X20HD, X20 Pro, X20R, X20RS, X18R, X18RS | X18RS am echten Sender getestet, die übrigen im Simulator |
| 640 × 360, ohne Berührung | Twin X14, X14S | im Simulator nachgestellt |
| 480 × 320, Berührung | X18, X18S, X18SE, Twin X Lite, Twin X Lite S | im Simulator nachgestellt |
| 480 × 272, ohne Berührung | X10, X10S, X10 Express, X12S mit Ethos | im Simulator nachgestellt |

![480x320](../../docs/bilder-simulator/Elektro%20-%20Sim%20480x320%2006%20Alarm.png)
*480 × 320 (X18): gekürzte Titel*

![Englisch](../../docs/bilder-simulator/Elektro%20-%20Sim%20800x480%2012%20Englisch.png)
*Englisch: Sprache im Menü oder wie der Sender*

Elektro Version 0.5.0 · 21.11.2026

---
[← Start](../Home.md) | Zurück | [Weiter →](Einrichten.md)
