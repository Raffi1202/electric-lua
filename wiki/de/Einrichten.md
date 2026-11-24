[🇬🇧 English](../en/Setup.md) · 🇩🇪 Deutsch

# Einrichten

## 3. Bildschirm einrichten

1. Tippe unten auf das Symbol **Bildschirme** (zwei Rechtecke).
2. Tippe oben rechts auf **+**.
3. Wische nach unten bis zum Layout **Vollbild** (ein einziges grosses Feld) und tippe es an. Willst du die Ethos-Kopf- und Fussleiste behalten, wähle das Layout mit **einem Feld und den Leisten** (im Auswahlraster unten in der Mitte); Electric zeigt dann die Kompaktansicht (Kapitel 5).
4. Tippe in das leere Feld, dann auf **Widget**.
5. Wische in der Liste ganz nach unten und wähle **Electric**. Die Anzeige erscheint sofort.

Das Menü des Widgets erreichst du später jederzeit über Modell › Bildschirme › den Bildschirm wählen › Widget antippen.

## 4. Sensoren und Akku einstellen

1. Schalte das Modell ein, damit die Telemetrie läuft. Beim ersten Mal sucht Electric die Sensoren selbst; unten erscheint kurz blau «… Sensoren automatisch zugewiesen».
2. Öffne das Menü und die Gruppe **Sensoren**. Kontrolliere jede Zeile. Was leer oder falsch ist, wählst du von Hand. Eine leere Zeile ist erlaubt, das Feld zeigt dann einen Strich.
3. Mit **Sensoren suchen (nur leere)** › **Suchen** füllt Electric später nur die leeren Zeilen, deine eigene Wahl bleibt. Hast du in Ethos Sensoren gelöscht und neu gesucht, lade zuerst das Modell neu (anderes Modell wählen und zurück), sonst bleiben die Werte auf 0. Danach bindet die Suche jede Zeile an den passenden Sensor (gleiche Kennung und gleicher Name); Zeilen, deren Sensor nicht mehr in der Sensorliste steht, auch von Hand gewählte, werden neu gesucht.
4. In der Gruppe **Zuordnung prüfen** steht je Zeile der gewählte Sensor mit Physical ID und AppID (z. B. «ESC Strom P04 / 0B50»). Passten mehrere gleiche Sensoren, steht darunter «n Sensoren passen, gewählt: … - bitte prüfen».
5. Öffne die Gruppe **Akku** und stelle **Akkuart**, **Zellenzahl** und **Kapazität** deines Flugakkus ein.

| Zeile im Menü | Welcher Sensor gehört hinein |
|---|---|
| Gesamtspannung | Spannung des ganzen Flugakkus, z. B. «VFAS», «ESC Voltage», «Volt». Nicht die Empfängerspannung. |
| Zellen (Zellensensor) | Nur wenn du einen Zellensensor hast (z. B. FLVSS, Anzeige «Cells» oder «LiPo»). Sonst leer lassen. |
| Strom | Strom des Reglers, z. B. «Current», «ESC Current». |
| Verbraucht (mAh) | Verbrauchte Kapazität, z. B. «Consumption». |
| Akku % (Regler) | Nur wenn dein Regler den Akkustand in % liefert, z. B. «Fuel», «Bat%». |
| Drehzahl, Reglertemperatur, BEC-Spannung | Die gleichnamigen Werte des Reglers. |
| Höhe, Vario, Geschwindigkeit | Vom Vario oder GPS (z. B. «Alt», «VSpd», «GSpd»). |
| RSSI, LQ | Empfangsstärke «RSSI», bei ELRS und ähnlichen die Verbindungsqualität «LQ». |

**Zellen mit und ohne Zellensensor.** Hast du einen Zellensensor, zeigt das Feld «ZELLE TIEFST» die schwächste Zelle, darunter einen kleinen Balken je Zelle (die schwächste gelb) und «Δ» = Unterschied zwischen stärkster und schwächster Zelle. Ohne Zellensensor zeigt «ZELLE Ø» die mittlere Zelle = Gesamtspannung ÷ Zellenzahl, darunter einen Balken mit der Gesamtspannung. Dafür muss die **Zellenzahl** eingestellt sein; Electric rät sie nie aus der Spannung. Steht sie auf 0 (automatisch) und es gibt keinen Zellensensor, steht im Feld orange «Zellenzahl?» und im Akku-Tacho «Zellenzahl einstellen».

![Zellensensor](../../docs/bilder-simulator/Electric%20-%20Sim%20800x480%2020%20Zellensensor.png)
*Mit Zellensensor: ZELLE TIEFST, Balken je Zelle*

![Zellenzahl fehlt](../../docs/bilder-simulator/Electric%20-%20Sim%20800x480%2011%20nur%20ein%20Teil%20der%20Sensoren.png)
*Ohne Zellensensor und ohne Zellenzahl: «Zellenzahl einstellen»*

## 8. Alle Einstellungen

Menü öffnen: Modell › Bildschirme › den Bildschirm wählen › Widget antippen. Jede Änderung gilt sofort und bleibt gespeichert.

| Gruppe | Einstellung | Ab Werk | Was sie bewirkt |
|---|---|---|---|
| oben | Akku % kommt von | – | Zeigt, woher der Akkustand gerade kommt: Regler, gerechnet oder kein Wert. |
| Sensoren | 13 Zeilen | leer | Siehe Kapitel 4. |
| Akku | Akkuart | LiPo | LiPo, LiHV, LiFe, Li-Ion oder NiMH. Bestimmt die Kennlinie für Akku % und die Balken. |
| Zellenzahl (0 = auto) | 0 | Zellen in Serie. 0 = vom Zellensensor; ohne Zellensensor bitte einstellen. |
| Kapazität | 4500 mAh | Kapazität des Flugakkus. Für Akku % und die Grenze «Verbraucht». 0 = Akku % nur aus der Spannung. |
| Akku % kommt von | Regler, sonst gerechnet | «immer gerechnet» übergeht den Wert des Reglers. |
| Drehzahl teilen durch | 1 | Für Regler, die die elektrische Drehzahl senden: Zahl der Polpaare eintragen. |
| Grenzwerte | je Wert Warnung und Alarm | siehe Kapitel 6 | 0 = aus. |
| Alarm auch bei Motor aus | je Wert ein/aus (10 Zeilen) | ein | Aus = dieser Wert schweigt, solange der Motor aus ist (Kapitel 6). |
| Schalter | Motor aus bei | SF↑ | Schalterstellung, in der der Motor aus ist. |
| Ansage bei | SG↓ | Schalterstellung für die Ansage. |
| Schalter 1 und 2 | leer | Eigene Schalter, die in der Kopfzeile erscheinen, solange sie eingeschaltet sind. |
| Schalter 1 und 2 Name | SCHALTER 1 / 2 | Eigener Name, höchstens 12 Zeichen, z. B. STABI oder FAHRWERK. |
| Flug | Flug erkennen über | Motorschalter | Oder «Strom oder Gas». |
| Gaskanal | leer | Kanal des Gases: für das Feld GAS und für die Erkennung über Gas. |
| Gas umkehren | aus | Für Gas Reverse (Vollgas = Knüppel hinten): Gas % = 100 − Gasstellung, für das Feld GAS und die Erkennung über Gas. |
| Flug ab Strom | 3 A | Ab diesem Strom läuft der Flug (Erkennung über Strom oder Gas). |
| Flug ab Gas | 10 % | Ab dieser Gasstellung läuft der Flug. |
| Pause nach | 20 s | So lange ohne Strom und Gas, bis die Frage «Flug beendet?» kommt. |
| Flug zählt ab | 30 s | Kürzere Läufe kommen nicht in die Liste. |
| Akkuwechsel beendet Flug | ein | Ein pausierter Flug endet, wenn die Telemetrie über 30 s weg ist. |
| Ansagen | Alarme ansagen | ein | Aus: bei Alarm nur Ton und Anzeige. |
| Warnung auch ansagen | aus | Ein: auch die orange Warnung wird angesagt. |
| Alarm wiederholen alle | 10 s | 3 bis 300 s. |
| Akku % ansagen alle | 10 % | aus, 5 %, 10 % oder 20 %. |
| «Motor aus» ansagen | ein | Ansage beim Ausschalten des Motors. |
| Ansage: Akku % | ein | Was auf dem Ansageschalter gesagt wird. |
| Ansage: Flugzeit | ein |
| Ansage: Höhe | aus |
| Ansage: Verbraucht | aus |
| Ton bei Alarm | ein | Piepton vor der Alarm-Ansage. |
| Vibration bei Alarm | aus | Der Sender vibriert bei jedem Alarm. |
| Felder | Tacho 1 bis 4, Feld 1 bis 6 | wie im Bild | Inhalt wählbar: Akku %, Strom, Drehzahl, Reglertemp., Zelle, Gesamtspannung, Verbraucht, Leistung, Höhe, Vario, Speed, Empfang, BEC, Flugzeit, Gas % oder leer. |
| Grosses Feld (links) | Gas % | Das grosse Feld unten links; in der Kompaktansicht das erste der acht Felder. Nach dem Update von 0.1.x steht hier, was vorher in Feld 7 stand, falls das Fliegerbild aus war. |
| Tacho Strom / Drehzahl / Temp. bis | 120 A / 12000 / 100 °C | Endwert des Bogens. |
| Anzeige | Sprache / Language | wie der Sender | Deutsch oder Englisch für Anzeige, Menü und Ansagen. Das Menü wechselt beim nächsten Öffnen. |

---
[← Start](../Home.md) | [Zurück](Installation.md) | [Weiter →](Anzeige.md)
