# Electric: Sprachansagen

Diese Liste ist die einzige Quelle der Ansagen. Texte immer hier ändern und die WAV-Dateien danach neu erzeugen
(Text-to-Speech, siehe Format unten).
Ablage: `src/electric/audio/de/<Dateiname>.wav` und `src/electric/audio/en/<Dateiname>.wav`.
Format WAV A-law, mono, 16 kHz, 8 Bit. Stimmen wie die Ethos-Originale: deutsch de-DE-Wavenet-E (Tempo 1,1),
englisch en-US-Wavenet-F. Vorne und hinten keine Stille, weil meist direkt danach die Zahl folgt.

| Dateiname | Deutsch | Englisch | Aussprache-Hinweis | Wann |
|---|---|---|---|---|
| `akku_tief` | Achtung! Akku | Warning! Battery | – | Akku % unter der Alarmschwelle, danach die Zahl mit «Prozent» |
| `zelle_tief` | Achtung! Zellenspannung | Warning! Cell voltage | – | Zelle (mittlere oder tiefste) unter der Alarmschwelle, danach die Zahl mit «Volt» |
| `zellen_ungleich` | Achtung! Zellen ungleich | Warning! Cells unbalanced | – | Zellendifferenz über der Alarmschwelle (nur mit Zellensensor), danach die Zahl mit «Volt» |
| `regler_heiss` | Achtung! Reglertemperatur | Warning! ESC temperature | ESC im Englischen buchstabiert | Reglertemperatur über der Alarmschwelle, danach die Zahl mit «Grad Celsius» |
| `strom_hoch` | Achtung! Strom | Warning! Current | – | Strom über der Alarmschwelle, danach die Zahl mit «Ampere» |
| `kapazitaet` | Achtung! Kapazität | Warning! Capacity | – | Verbraucht über der Alarmschwelle (% der Kapazität), danach die Zahl mit «Prozent» |
| `bec_tief` | Achtung! BEC-Spannung | Warning! BEC voltage | BEC als Wort («Beck») wie bei Heli RF | BEC unter der Alarmschwelle, danach die Zahl mit «Volt» |
| `hoehe` | Höhe | Altitude | – | Höhe über der Alarmschwelle und Ansage auf Schalter (wenn «Ansage: Höhe» ein), danach die Zahl mit «Meter» |
| `empfang` | Achtung! Empfang | Warning! Signal | – | RSSI oder LQ unter der Alarmschwelle, danach die Zahl |
| `motor_aus` | Motor aus | Motor off | – | Motorschalter auf «aus» (wenn «Motor aus ansagen» ein) |
| `akku` | Akku | Battery | – | Akku-%-Schritt und Ansage auf Schalter, danach die Zahl mit «Prozent» |
| `flugzeit` | Flugzeit | Flight time | – | Ansage auf Schalter, danach Minuten und Sekunden |
| `verbraucht` | Verbraucht | Used | – | Ansage auf Schalter (wenn «Ansage: Verbraucht» ein), danach die Zahl mit «Milliamperestunden» |

Zahlen und Einheiten spricht Ethos selbst in der Sprache des Senders (`system.playNumber`). Fehlt eine Datei,
kommt beim Alarm nur Ton und Zahl, bei «Motor aus» ein kurzer Ton.

Stand 19.11.2026: alle 13 Dateien deutsch und englisch erzeugt und in 0.1.1 eingebaut.
Am Sender noch nicht abgehört.
