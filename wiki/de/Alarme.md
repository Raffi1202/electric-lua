[🇬🇧 English](../en/Alarms.md) · 🇩🇪 Deutsch

# Alarme

> **Vorabversion:** Version 0.5.0 ist im Ethos-Simulator getestet, der Sendertest an der X18RS folgt. Nutzung auf eigene Verantwortung.


## 6. Warnungen und Alarme

Jeder überwachte Wert hat zwei Grenzen: Warnung (orange, nur Anzeige) und Alarm (rot, Rahmen, Ton und Ansage). Beide stellst du im Menü in der Gruppe **Grenzwerte** ein, 0 schaltet eine Grenze aus. Die Werte ab Werk:

| Wert | Warnung (orange) | Alarm (rot, Ton, Ansage) |
|---|---|---|
| Akku % | unter 30 % | unter 20 %, «Achtung! Akku» und die Zahl |
| Zelle (mittlere oder tiefste) | unter 3,50 V | unter 3,30 V, «Achtung! Zellenspannung» und die Zahl |
| Zellendifferenz (nur mit Zellensensor) | über 0,10 V | über 0,20 V, «Achtung! Zellen ungleich» und die Zahl |
| Reglertemperatur | über 70 °C | über 85 °C, «Achtung! Reglertemperatur» und die Zahl |
| Strom | über 80 A | über 100 A, «Achtung! Strom» und die Zahl |
| Verbraucht (in % der Kapazität) | über 70 % | über 80 %, «Achtung! Kapazität» und die Zahl |
| BEC-Spannung | aus | aus |
| Höhe | über 110 m | über 120 m, «Höhe» und die Zahl |
| RSSI (bei dBm-Werten: Schwelle = dBm + 120, z. B. 40 = -80 dBm) | unter 45 dB | unter 40 dB, «Achtung! Empfang» und die Zahl |
| LQ | unter 70 % | unter 50 %, «Achtung! Empfang» und die Zahl |

Die Zellen-Grenzen gelten für LiPo und LiHV. Wählst du eine andere Akkuart und stehen die Zellen-Grenzen noch auf dem Werkwert, stellt Electric sie passend um: LiFe 3,00/2,80 V, Li-Ion 3,20/3,00 V, NiMH 1,10/1,00 V.

![Warnung](../../docs/bilder-simulator/Electric%20-%20Sim%20800x480%2005%20Warnung.png)
*Warnung: Kopf und Wert orange, kein Ton*

![Alarm](../../docs/bilder-simulator/Electric%20-%20Sim%20800x480%2006%20Alarm.png)
*Alarm: Kopf rot, roter Rahmen, Ton und Ansage*

Eine Warnung erscheint, wenn der Wert 1 Sekunde lang jenseits der Grenze liegt, und verschwindet, wenn er 3 Sekunden lang wieder gut ist. Ein Alarm piept, sagt den Wert an und wiederholt das alle 10 Sekunden («Alarm wiederholen alle»), solange er besteht. Zwischen zwei Ansagen liegen immer mindestens 3 Sekunden.

**Alarm auch bei Motor aus** (ab Version 0.5.0): Ab Werk kommen alle Warnungen und Alarme auch, wenn der Motorschalter auf «aus» steht. Im Menü in der Gruppe **Alarm auch bei Motor aus** kannst du das je Wert ausschalten. Dann schweigt dieser Wert, solange der Motorschalter auf «aus» steht: keine Meldung, kein Ton, keine Ansage, keine Vibration. Die Farbe des Werts zeigt die Grenze weiter. Sobald du den Motor scharf schaltest, kommt der Alarm wieder. Ohne eingestellten Motorschalter gilt diese Einstellung nie.

### Was nie stumm wird
- Eine Lua-Studio-Datei schaltet einen überwachten Alarm **nur mit `aus = true`** ganz aus (Entscheid des Autors 20.11.2026). Ein Eintrag ohne Stufen (nur Ansage, Vibration oder «auch bei Motor aus») oder mit Warnung und Alarm beide `false` behält die Werkgrenze.
- «Alarm auch bei Motor aus» = aus macht diesen Wert nur still, solange der Motorschalter auf aus steht; ohne eingestellten Motorschalter gilt es nie.
- Electric hat keine Fehlercodes oder Abschaltgründe eines Reglers; alle Alarme sind Grenzwert-Alarme wie oben aufgeführt.

---
[← Start](../Home.md) | [Zurück](Anzeige.md) | [Weiter →](Lua-Studio.md)
