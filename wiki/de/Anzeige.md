[🇬🇧 English](../en/Display.md) · 🇩🇪 Deutsch

# Anzeige

## 5. Die Anzeige

![Anzeige mit Nummern](../../docs/bilder-simulator/Electric%20-%20Sim%20800x480%2004%20Normal.png)

*Die Nummern der Tabelle sind im PDF der Anleitung ins Bild eingezeichnet.*

| Nr. | Was du siehst | Was es bedeutet |
|---|---|---|
| 1 | Modellname, Kopfzeile | Name des Modells im Sender. Die Kopfzeile wird orange bei einer Warnung und rot bei einem Alarm. |
| 2 | Flugzeit | Dauer des laufenden Flugs in Minuten:Sekunden. Sie läuft nur, solange der Motor an ist. |
| 3 | SCHARF / MOTOR AUS | Stellung des Motorschalters (nur wenn einer eingestellt ist). Links davon erscheinen deine eigenen Schalter als grüne Pille, solange sie eingeschaltet sind (z. B. «FAHRWERK»). Ist zu wenig Platz, fällt die vordere weg. |
| 4 | Balken, Akkusymbol | Empfangsstärke (RSSI) in vier Stufen und der Akku des Senders. |
| 5 | Vier Tachos | Ab Werk AKKU (Akkustand in %, darunter Zellenzahl und Gesamtspannung), STROM in Ampere, DREHZAHL in U/min und REGLERTEMP. in °C. «MAX» darunter ist der höchste gemessene Wert mit diesem Akku, keine Grenze. |
| 6 | GAS | Gas in % aus dem Gaskanal, darunter der Strom dazu («bei 46 A») und ein Balken. Steht dort orange «Gaskanal wählen», im Menü unter Flug den Gaskanal wählen. Im Menü (Felder › Grosses Feld) wählst du auch einen anderen Inhalt. |
| 7 | «8 Flüge» | Zahl der Flüge dieses Modells, der laufende mitgezählt, sobald er zählt (Kapitel 7). Antippen öffnet die Flugliste. |
| 8 | ZELLE Ø oder ZELLE TIEFST | Spannung je Zelle unter Last (Kasten in Kapitel 4). «TIEF» ist der tiefste Wert mit diesem Akku. |
| 9 | VERBRAUCHT, Knopf AUF 0 | Verbrauchte mAh seit dem Anstecken bzw. seit «AUF 0». Den Knopf brauchst du nur, wenn dein Regler beim Akkuwechsel nicht selbst bei 0 beginnt. |
| 10 | LEISTUNG | Gesamtspannung × Strom in Watt, darunter die verbrauchte Energie in Wh mit diesem Akku. |
| 11 | HÖHE | Höhe in Metern, darunter Steigen ↑ oder Sinken ↓ in m/s und links gelb die höchste Höhe mit diesem Akku. |
| 12 | SPEED | Geschwindigkeit in km/h, darunter der höchste Wert. |
| 13 | EMPFANG | RSSI in dB, darunter LQ in % und der tiefste RSSI («TIEF»). Liefert dein Empfänger RSSI in dBm (negativ, z. B. ELRS, Crossfire), steht er wie im Sensormenü da, z. B. «-80 dBm». |

Ein kurzer grauer Strich statt einer Zahl heisst: Dieser Wert kommt gerade nicht an oder hat keinen Sensor. Was in welchem Tacho und Feld steht, kannst du im Menü ändern (Kapitel 8, Gruppe Felder).

**Akku %** kommt vom Regler, wenn er ihn liefert und «Akku % kommt von» auf «Regler, sonst gerechnet» steht. Sonst rechnet Electric: Steht das Modell 2 Sekunden ohne Strom, liest es aus der Ruhespannung den Startwert (Kennlinie der Akkuart) und zählt danach mit den verbrauchten mAh und der Kapazität herunter. Dann steht unter dem Tacho «RUHE». Was gerade gilt, steht im Menü in der Zeile «Akku % kommt von».

**Neuer Akku:** Ist die Telemetrie über 30 Sekunden weg (Akku abgesteckt), beginnen MAX- und TIEF-Werte, Wh und Akku % von vorn.

### Kompaktansicht

Wählst du das Layout mit Kopf- und Fussleiste (Kapitel 3), merkt Electric das selbst und zeigt eine kompakte Ansicht: oben eine schmale Leiste mit Flugzeit, SCHARF / MOTOR AUS und Empfang (Modellname und Senderakku stehen in der Ethos-Kopfzeile), darunter die vier Tachos und acht Felder: das grosse Feld (ab Werk GAS, hier ohne Balken), Feld 1 bis 6 und FLÜGE. Antippen von FLÜGE öffnet die Flugliste. Alles andere geht wie im Vollbild.

![Kompaktansicht](../../docs/bilder-simulator/Electric%20-%20Sim%20784x316%2030%20Kompakt%20Normal%20mit%20Gas.png) Kompaktansicht auf X20 und X18RS (784 × 316). Auf X14 und X18 / Twin X Lite ist sie entsprechend kleiner.

### Flugphase, zwei Empfangsbänder, zweiter Akku (ab 0.10.0)

- **Flugphase:** Hat das Modell mehrere Flugphasen, steht der Name der aktiven Phase klein unter dem Modellnamen (Kompaktansicht: rechts neben der Flugzeit). Ethos sagt einem Lua nicht, wie viele Phasen es gibt; die Zeile erscheint darum, sobald das Modell einmal in einer anderen als der ersten Phase war, und wird pro Modell gemerkt. Menü: «Flugphase anzeigen».

- **Zwei Empfangsbänder:** Bei Empfängern mit zwei Bändern (TD 2,4 GHz + 900 MHz, LoRa) erkennt die Suche RSSI und VFR je Band selbst (Ethos meldet das Band jedes Sensors). Die Empfangskachel zeigt gross das bessere Band, darunter «VFR 2.4 x% 900 y%» (ohne VFR: RSSI in dB). Warnung je Band («Achtung! Empfang 2,4 Gigahertz» bzw. «900 Megahertz», Grenze «VFR Warnung unter»), Alarm nur auf RX VFR (Grenze «RX VFR Alarm unter»), ohne RX VFR auf das bessere Band. Damit nicht alles gleichzeitig kommt: RSSI je Band nur ohne VFR, und während eines Empfangsalarms schweigen die Warnungen je Band.

- **Zellen 2 und Empfänger-Akku 2:** Ein zweiter Zellensensor (andere Physical ID) wird als «Zellen 2» gefunden. «in Serie»: beide gehören zum selben Akku (tiefste Zelle aus beiden; Gesamtspannung = Summe der Zellen, wenn kein Spannungssensor zugewiesen ist). «eigener Akku»: eigene Zellenzahl, Akkuart und Grenzen (Akku 2 und Zelle Akku 2, je Warnung und Alarm; ab Werk wie Akku 1), Warnung «Zellenspannung Akku 2», «Akku 2» in Prozent mit Ansage. Unter 0,5 V gilt ein Sensor als «kein Akku». «Empfänger-Akku 2» (RxBatt 2) hat die Grenzen des BEC und die Ansage «Achtung! Empfängerakku 2».

- **Befehlsgrenze:** Mit voller Belegung (40 Sensoren, beide Bänder, Akku 2, aktive Alarme) liegt das Zeichnen nach Mac-Zählung bei 10 173–10 385 und ein Suchschritt bei 5 111 Befehlen, knapp über der eigenen Grenze (0.9.0: 10 098–10 310 und 5 105). Mit den Studio-Prüfdateien liegt das Zeichnen bei bis zu 12 085 (0.9.0: 12 083). Der Sendertest mit dieser Belegung steht noch aus.

## 7. Bedienen

### Flüge erkennen

Ab Werk erkennt Electric einen Flug am **Motorschalter**: «Motor aus bei» steht auf **SF↑**. Schaltest du den Motor scharf, beginnt die Flugzeit; schaltest du ihn aus, sagt der Sender «Motor aus», die Zeit hält an und es kommt die Frage «Flug beendet?».

- **JA, BEENDET**: Der Flug kommt in die Liste.

- **NEIN, NUR PAUSE**: Der Flug bleibt offen. Schaltest du den Motor wieder scharf, läuft er weiter.

- Ein pausierter Flug endet von selbst, wenn du den Akku absteckst (Telemetrie über 30 s weg, «Akkuwechsel beendet Flug»).

Ein Flug zählt erst ab 30 Sekunden Motorlaufzeit («Flug zählt ab»); kürzere Läufe am Boden fallen weg. Ohne Motorschalter oder mit «Flug erkennen über» = «Strom oder Gas» beginnt der Flug, sobald der Strom über 3 A oder das Gas über 10 % liegt, und die Pause mit der Frage kommt nach 20 Sekunden darunter.

![Flug beendet?](../../docs/bilder-simulator/Electric%20-%20Sim%20800x480%2007%20Rueckfrage%20Flug%20beendet.png)

### Flugliste (Seite 2)

Wische nach links oder tippe auf «8 Flüge». Rechts stehen die Flüge, der neuste oben, der laufende blau mit «läuft» oder «Pause». Tippe einen Flug an: Links erscheinen seine Werte. Mit dem Drehrad wählst du Flüge auch ohne Tippen.

![Flugliste](../../docs/bilder-simulator/Electric%20-%20Sim%20800x480%2022%20Flugliste.png)

1. Einen Flug löschen: Flug antippen, **FLUG n LÖSCHEN**, dann **JA, LÖSCHEN**. Die späteren Nummern rücken nach.
2. Alle Flüge löschen: **LISTE LÖSCHEN**, dann **JA, LÖSCHEN**. Der Zähler beginnt wieder bei 1.
3. Zurück zur Anzeige: **< ZURÜCK** oder nach rechts wischen.

Die Liste behält die letzten 20 Flüge. Sie bleibt beim Ausschalten erhalten. Ein pausierter Flug wird beim nächsten Einschalten abgeschlossen und kommt in die Liste (wenn «Akkuwechsel beendet Flug» an ist).

### Verbrauch auf 0

Tippe im Feld VERBRAUCHT auf **AUF 0** und bestätige mit **JA, AUF 0**. Mit **ABBRECHEN** bleibt alles, wie es ist.

### Ansage auf Schalter

Schaltest du **SG↓** ein («Ansage bei»), sagt der Sender den Akkustand und die Flugzeit an. Was angesagt wird, wählst du in der Gruppe Ansagen. Ausserdem sagt Electric beim Entladen alle 10 % den Akkustand an («Akku % ansagen alle»).

### Sender ohne Berührung (X14, X10, X12)

Im Menü oben gibt es **Kapazität auf 0**, **Flug löschen** (vorher bei «Flug Nr. zum Löschen» die Nummer wählen) und
**Ganze Liste löschen**, jeweils mit Rückfrage. Mit dem Drehrad kommst du auf die Flugliste und wählst Flüge; vor dem ersten Flug zurückdrehen führt wieder zur Anzeige.

---
[← Start](../Home.md) | [Zurück](Einrichten.md) | [Weiter →](Alarme.md)
