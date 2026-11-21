[🇬🇧 English](../en/Troubleshooting.md) · 🇩🇪 Deutsch

# Fehlerbehebung

## 9. Wenn etwas nicht geht

| Was du siehst | Ursache | Was du tust |
|---|---|---|
| Überall Striche, Flugzeit 0:00 | Keine Telemetrie | Modell einschalten. Prüfen, ob der Empfänger verbunden ist. |
| «Zellenzahl einstellen» bzw. «Zellenzahl?» | Kein Zellensensor und Zellenzahl auf 0 | Menü › Akku › Zellenzahl einstellen. |
| Akku % stimmt nicht | Falsche Kapazität oder Akkuart, oder Akku unter Last angesteckt | Menü › Akku kontrollieren. Den Akku anstecken, bevor du Gas gibst. |
| Kein «SCHARF / MOTOR AUS» oben, Flüge zählen nicht | Motorschalter nicht gefunden | Menü › Schalter › «Motor aus bei» die Stellung wählen, z. B. SF↑. |
| Bei Motor aus kommt ein Alarm nicht | «Alarm auch bei Motor aus» für diesen Wert aus (Menü oder Lua-Studio) | Menü › Alarm auch bei Motor aus › den Wert einschalten. |
| Drehzahl viel zu hoch | Regler sendet elektrische Drehzahl | Menü › Akku › «Drehzahl teilen durch» = Polpaare des Motors. |
| Bei Alarm nur ein Piepton und die Zahl | Die Sprachdateien fehlen auf dem Sender (Ordner audio) | Kapitel 2 wiederholen. |
| Ein einzelner Wert zeigt einen Strich | Sensor nicht zugewiesen oder liefert nichts | Menü › Sensoren: Zeile kontrollieren (Kapitel 4). |
| GAS zeigt einen Strich und «Gaskanal wählen» | Kein Gaskanal eingestellt | Menü › Flug › Gaskanal wählen (Kapitel 8). |
| Unten links steht roter Text | Fehler im Skript. Der Sender läuft normal weiter. | Text abfotografieren und als Fehler melden: auf GitHub unter Issues, Vorlage «Fehler / Bug» (siehe TESTLEITFADEN.md im Repo). |
| Unten «Studio-Datei kaputt - Standard», «zu neu» oder «n Fehler», danach oben rechts «!» | Die Datei von Lua-Studio ist kaputt, für eine neuere Elektro-Version oder enthält ungültige Angaben | In Lua-Studio neu übertragen bzw. Elektro aktualisieren. Was genau falsch ist, steht im Log (je Fehler eine Zeile). |
| Das Widget fehlt in der Liste | Nicht installiert oder Sender nicht neu gestartet | Kapitel 2 wiederholen, Sender neu starten. |

## 10. Aktualisieren und Entfernen

**Aktualisieren:** Die neue ZIP genau wie in Kapitel 2 installieren. Deine Einstellungen, Sensoren, Flüge und Zähler bleiben erhalten.

**Entfernen:** Zuerst das Widget vom Bildschirm nehmen (Modell › Bildschirme), dann in der FrSky Suite unter Lua-Bibliothek deinstallieren.

### Lua-Speicher («too much RAM»)
Alle Lua-Skripte der Funke teilen sich einen Lua-Speicher (rund 2048 KB auf der X18RS). Meldet Ethos «too much RAM» bzw. zu wenig Lua-Speicher, die Funke aus- und wieder einschalten. Ab Version 0.5.0 gibt Elektro seinen Speicher frei, wenn du auf ein Modell ohne Elektro wechselst (es bleiben rund 5 KB, im Simulator gemessen).

---
[← Start](../Home.md) | [Zurück](FAQ.md) | [Weiter →](Versionen.md)
