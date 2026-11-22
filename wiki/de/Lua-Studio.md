[🇬🇧 English](../en/Lua-Studio.md) · 🇩🇪 Deutsch

# Lua-Studio

### Einstellungsdatei aus Lua-Studio

Mit dem PC-Programm **Lua-Studio** gestaltest du die Anzeige je Modell frei: Für jedes Kästchen wählst du Wert, Darstellung (Zahl, Ring, Balken waagrecht oder senkrecht, Verlauf, Status), Titel, Bereich, Farben und Zusatzzeile (MIN, MAX oder Ø über den Flug). Dazu kommen Einstellungen und Grenzwerte je Modell. Lua-Studio legt dafür auf der SD-Karte die Datei `scripts/studio/Modellname.electric.lua` an. Im Dateinamen stehen vom Modellnamen nur Buchstaben A–Z und Ziffern, alles andere wird zu `_` (aus «Möwe 2» wird `M__we_2`); Lua-Studio rechnet das selbst. Electric liest sie beim Laden des Modells.

- **Ohne diese Datei** arbeitet Electric genau wie bisher, ohne Hinweis.

- **Wo und welche Datei (ab 0.7.0):** Electric sucht die Datei in `scripts/studio` unter dem eingestellten Skript-Speicherort, dann auf der SD-Karte, dann im internen Speicher. Passt der Dateiname nicht zum Modellnamen, wähle die Datei im Widget-Menü unter **Studio-Layout** (die Liste zeigt jede Datei mit Ort; «automatisch (Modellname)» ist der bisherige Weg). Die Wahl im Menü gilt vor dem Modellnamen.

- **Mit Datei** gilt ihre Ansicht für die Fenstergrösse, für die sie gemacht ist. Fehlt eine Ansicht für diese Grösse, rechnet Electric ab 0.7.0 die Ansicht mit dem ähnlichsten Seitenverhältnis um und zeigt 5 s lang «Studio: Ansicht 800x480 angepasst» in der Kopfzeile. Zu kleine Kästchen werden als Zahl gezeigt oder weggelassen. Bleibt trotz Datei die eingebaute Anzeige, steht in der Kopfzeile der Grund, z. B. «Studio: Datei fehlerhaft (…)» oder «Studio: keine passende Ansicht».

- **Nach dem Wechsel des Modells** liest Electric die Datei in kleinen Schritten, das kann einen Moment dauern. Hat die Datei eine Ansicht für diese Fenstergrösse, steht solange «Studio-Datei wird geladen ...» statt der eingebauten Anzeige; sonst zeigt Electric gleich seine eingebaute Anzeige.

- **Symbole, fette Einheit und Schmuck** (ab Version 0.4.0, Lua-Studio ab 0.3.0): Ein Kästchen kann oben links ein Symbol tragen (z. B. Akku, Uhr, Höhe) und die Einheit fett zeigen. Dazu kommen frei platzierte Symbole, Texte, Linien und Rahmen unter den Kästchen. Die Bilder schreibt Lua-Studio nach `scripts/studio/symbole/`. Fehlt ein Bild oder ist es kaputt, zeigt Electric das Kästchen ohne Symbol und unten kurz «Studio: n Symbole fehlen». Symbole und Schmuck ändern nie einen Grenzwert oder Alarm.

- **Grenzwerte** gelten je Wert, egal ob und wie er angezeigt wird. Fehlt ein Wert in der Datei, gilt die Werkgrenze. Ein Alarm geht nur aus, wenn die Datei das ausdrücklich so will. Passt eine Angabe nicht zum Wert (z. B. falsche Richtung), gilt ebenfalls die Werkgrenze, mit Hinweis. Auch «auch bei Motor aus» lässt sich in Lua-Studio je Grenze einstellen (ab Version 0.5.0, auch für Sensoren und Kanäle). Im Menü der Funke stehen nur die 10 eigenen Werte von Electric; Grenzen für Sensoren und Kanäle aus der Datei stellst du in Lua-Studio ein.

- **Änderst du an der Funke** Akku, Grenzwerte oder andere Einstellungen im Menü, schreibt Electric das in eine eigene Datei `…electric.funke.lua`. Die Datei von Lua-Studio bleibt unverändert. Lua-Studio zeigt die Unterschiede und übernimmt sie auf Wunsch.

- **Menü › Studio-Datei › Zurück:** mit Datei «Zurück auf Studio-Stand» (deine Änderungen an der Funke werden gelöscht), ohne Datei «Zurück auf Standard» (Einstellungen und Grenzwerte ab Werk; Sensoren und Flüge bleiben). Beides fragt nach.

- **Hinweise:** Ist die Datei kaputt, zu neu oder enthält sie ungültige Angaben, steht 8 Sekunden lang unten ein Band (z. B. «Studio-Datei kaputt - Standard»), danach oben rechts ein oranges «!». Electric läuft immer weiter, im Zweifel mit der eingebauten Anzeige.

- Electric schreibt dazu die Datei `…electric.info.json` mit Modellname, Sender und Sensorliste. Nur Lua-Studio liest sie.

---
[← Start](../Home.md) | [Zurück](Alarme.md) | [Weiter →](FAQ.md)
