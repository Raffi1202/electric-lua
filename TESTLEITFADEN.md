# Testleitfaden Electric 0.7.3

Danke, dass du Electric testest! Arbeite die Testfälle der Reihe nach durch und hake ab, was so klappt wie beschrieben.
Klappt etwas nicht, melde es (ganz unten steht wie). Ein Testfall dauert meistens nur ein bis zwei Minuten.

*English testers: the widget, the menu and the manual are also in English (`docs/Electric - Manual.pdf`). Set the
language in the widget menu (Display › Language) or leave it «as the radio». The test cases below follow the same
order as the manual. Report problems with the issue template «Fehler / Bug».*

## Was du brauchst

- FrSky-Sender mit Ethos **26.2** und Farbdisplay. Am echten Sender getestet ist bisher nur die **X18RS**.
  Andere Sender laufen im Simulator; dein Test auf einem anderen Sender hilft besonders.
- Ein Elektromodell mit Telemetrie. Mindestens die Akkuspannung (z. B. VFAS, ESC Voltage). Strom, Verbrauch,
  Drehzahl, Reglertemperatur, Höhe, Speed oder Zellensensor sind willkommen, aber freiwillig.
- Am Modell: die Sensoren schon gesucht (Modell › Telemetrie › Sensoren suchen).
- Computer mit der FrSky Suite und ein USB-Kabel.
- Die Datei `Electric-0.7.3.zip` aus dem GitHub-Release (Seite «Releases» rechts im Repo).
- Die Anleitung `docs/Electric - Anleitung.pdf`. Die Testfälle verweisen auf ihre Kapitel.

**Sicherheit:** Teste mit abgenommenem Propeller, solange du am Tisch arbeitest. Der Flugtest (Testfall 11)
ist freiwillig und gehört auf den Flugplatz.

**Vorher sichern:** Erstelle in der FrSky Suite eine Sicherung deines Senders. Electric ändert keine Modelle,
es legt nur Dateien im Ordner `scripts/electric` an.

## Testfälle

Notiere dir für die Meldung: Sender, Ethos-Version (System › Info) und welche Sensoren dein Modell hat.

### 1. Installieren (Anleitung Kapitel 2)
- [ ] Mit der FrSky Suite: Lua-Bibliothek › Von lokaler ZIP installieren › `Electric-0.7.3.zip`. Sender neu starten.
- **Erwartet:** Die Suite meldet keinen Fehler. Nach dem Neustart erscheint keine Fehlermeldung.

### 2. Bildschirm einrichten (Kapitel 3)
- [ ] Neuer Bildschirm mit dem Layout **Vollbild**, Widget **Electric** wählen.
- **Erwartet:** Die Anzeige erscheint sofort: oben der Modellname, darunter vier Tachos und sechs Felder. Unten links steht **kein** roter Text.

### 2b. Gas % und Kompaktansicht (neu in 0.2.0)
- [ ] Menü › Flug › **Gaskanal** wählen (dein Gas-Kanal, z. B. CH3). Gasknüppel langsam von ganz unten nach ganz oben (Propeller ab, Motorschalter aus oder Akku ab).
- **Erwartet:** Das grosse Feld GAS links unten zeigt 0 % bis 100 % mit Balken. Ohne Gaskanal steht dort orange «Gaskanal wählen».
- [ ] Einen zweiten Bildschirm mit dem Layout **mit Kopf- und Fussleiste** (ein Feld, im Auswahlraster unten Mitte) anlegen und Electric wählen.
- **Erwartet:** Kompaktansicht: oben Flugzeit und Empfang, darunter vier Tachos und acht Felder (GAS, Zelle, Verbraucht, Leistung, Höhe, Speed, Empfang, Flüge). Nichts ragt über den Rand, kein roter Text. FLÜGE antippen öffnet die Flugliste.

### 2c. Einstellungsdatei aus Lua-Studio (neu in 0.3.0, nur wenn du Lua-Studio hast)
- [ ] In Lua-Studio für dein Modell eine Ansicht gestalten und auf den Sender übertragen, dann das Modell neu laden.
- **Erwartet:** Electric zeigt deine Kästchen. Steht unten ein Hinweis («Studio-Datei …»), bitte mit Log melden.
- [ ] Im Widget-Menü die Kapazität ändern, Modell neu laden.
- **Erwartet:** Die Änderung bleibt. Menü › Studio-Datei › Zurück › «JA, ZURÜCK» stellt den Stand aus Lua-Studio wieder her.
- [ ] **Neu in 0.4.0 (Lua-Studio ab 0.3.0):** einigen Kästchen ein Symbol und die fette Einheit geben, dazu einen
  Schmuck (Text oder Symbol) setzen, übertragen, Modell neu laden.
- **Erwartet:** Symbole erscheinen nach wenigen Bildern in der Farbe des Werts, der Titel rückt ein, die fette
  Einheit steht oben links und nicht mehr neben dem Wert. Kein Hinweis «Symbole fehlen».

### 3. Ohne Telemetrie
- [ ] Empfänger aus.
- **Erwartet:** Überall graue Striche, Flugzeit 0:00, kein roter Text.

### 4. Sensoren automatisch zuweisen (Kapitel 4)
- [ ] Modell einschalten und etwa 10 Sekunden warten.
- **Erwartet:** Unten erscheint kurz blau «… Sensoren automatisch zugewiesen». Die Werte erscheinen in den Tachos und Feldern.
- [ ] Widget-Menü öffnen (Modell › Bildschirme › Widget antippen) › Gruppe **Zuordnung prüfen**.
- **Erwartet:** Jede Zeile nennt einen passenden Sensor oder «kein Sensor». Die Empfängerspannung steht **nicht** bei Gesamtspannung.
- [ ] Eine Zeile in der Gruppe **Sensoren** leeren, dann oben **Suchen** drücken.
- **Erwartet:** Nur die leere Zeile wird neu gefüllt, deine anderen Zeilen bleiben.
- [ ] In Ethos unter Modell › Telemetrie › Menü (⋮) **Alle Sensoren löschen**, dann **Sensoren suchen**. Danach das
  **Modell neu laden** (anderes Modell wählen und zurück) und im Widget-Menü **Suchen** drücken.
- **Erwartet:** Alle Werte erscheinen wieder richtig, kein Feld bleibt auf 0, kein Alarm. Die MAX-Werte beginnen neu.
  Bekannt: Ohne Neuladen des Modells bleiben die Felder auf 0 (Sendertest 0.3.1).

### 5. Akku (Kapitel 4 und 5)
- [ ] Menü › Akku: Akkuart, Zellenzahl und Kapazität deines Akkus einstellen. Vollen Akku anstecken.
- **Erwartet:** Der Tacho AKKU zeigt einen plausiblen Wert (voll geladen etwa 95–100 %). Darunter Zellenzahl und Spannung.
  ZELLE Ø (ohne Zellensensor) bzw. ZELLE TIEFST (mit Zellensensor) zeigt etwa 4,1–4,2 V je Zelle bei LiPo.
- [ ] Zellenzahl auf 0 stellen (nur ohne Zellensensor).
- **Erwartet:** Orange «Zellenzahl einstellen» im Akku-Tacho und «Zellenzahl?» im Zellenfeld. Danach wieder richtig einstellen.

### 6. Motorschalter (Kapitel 7, «Flüge erkennen»)
- [ ] Prüfen, dass im Menü › Schalter «Motor aus bei» **SF↑** steht (oder deinen Motorschalter wählen). Propeller ab!
- [ ] Motor scharf schalten, dann wieder aus.
- **Erwartet:** Oben grüne Pille **SCHARF**, beim Ausschalten graue Pille **MOTOR AUS** und die Ansage «Motor aus».

### 7. Flug am Boden, Rückfrage (Kapitel 7)
- [ ] Motor scharf, etwas über 30 Sekunden laufen lassen (wenig Gas genügt), dann Motor aus.
- **Erwartet:** Die Flugzeit läuft nur bei scharfem Motor. Nach dem Ausschalten kommt «Flug beendet?».
- [ ] **NEIN, NUR PAUSE** wählen, Motor wieder scharf.
- **Erwartet:** Die Flugzeit läuft weiter.
- [ ] Motor aus, **JA, BEENDET**.
- **Erwartet:** Unten links steht «1 Flug» (bzw. die Zahl um 1 höher).

### 8. Flugliste (Kapitel 7, «Flugliste»)
- [ ] Nach links wischen oder unten links «… Flüge» antippen.
- **Erwartet:** Rechts die Liste, der neuste Flug oben. Ein Flug antippen zeigt links Dauer, Verbrauch, Energie usw.
- [ ] Einen Flug löschen: **FLUG n LÖSCHEN** › **JA, LÖSCHEN**.
- **Erwartet:** Der Flug ist weg, die späteren Nummern rücken nach. **ABBRECHEN** ändert nichts.

### 9. Verbrauch auf 0 (Kapitel 7)
- [ ] Im Feld VERBRAUCHT auf **AUF 0** tippen, dann **JA, AUF 0**.
- **Erwartet:** Verbraucht steht auf 0 mAh, Hinweis «Verbrauch auf 0 gesetzt».

### 10. Warnung, Alarm und Ansagen (Kapitel 6)
- [ ] Menü › Grenzwerte: «Akku» Warnung auf 95 % und Alarm auf 90 % stellen (zum Testen, danach zurück auf 30/20).
- **Erwartet:** Liegt der Akku darunter: Kopfzeile erst orange (Warnung), dann rot mit Rahmen, Ton und Ansage «Achtung! Akku …». Die Ansage wiederholt sich alle 10 Sekunden.
- [ ] **Pflicht: Alarm mit Motorschalter aus und ein.** Den Alarm von oben einmal mit **SF↑ (Motor aus)** und einmal
  mit **SF↓ (scharf)** auslösen. Propeller ab!
- **Erwartet:** In beiden Stellungen kommen Alarm, Ton und Ansage gleich. Der Motorschalter darf keinen Alarm
  unterdrücken; er steuert nur Flugzeit, Flugerkennung und die Ansage «Motor aus».
- [ ] **Pflicht ab 0.5.0: «Alarm auch bei Motor aus».** Menü › Alarm auch bei Motor aus › «Akku %» ausschalten. Den
  Akku-Alarm von oben auslösen: (1) Haken EIN, SF↑ (Motor aus): Alarm kommt. (2) Haken AUS, SF↑: still, kein Ton,
  keine Ansage, Wert bleibt rot. (3) Haken AUS, SF↓ (scharf): Alarm kommt. Danach den Haken wieder einschalten.
- [ ] **Ab 0.5.0: Studio-Datei nach dem Modellwechsel.** Modell mit Studio-Datei laden.
- **Erwartet:** Erst «Studio-Datei wird geladen ...», dann die Studio-Ansicht, nie das Standardlayout dazwischen. Im
  Debug-Log steht «Electric: Studio-Datei geladen in x s (n Schritte)»: die Zeit notieren.
- [ ] Schalter **SG↓** einschalten.
- **Erwartet:** Ansage von Akkustand und Flugzeit.

### 11. Echter Flug (freiwillig, auf dem Flugplatz)
- [ ] Einen normalen Flug machen.
- **Erwartet:** Plausible Werte während des Flugs. Akku-%-Ansagen alle 10 % beim Entladen. Der Flug steht danach in der Liste mit Max-Strom, Max-Höhe usw.

### 12. Neustart
- [ ] Sender aus- und wieder einschalten.
- **Erwartet:** Einstellungen, Sensoren, Flugzähler und Flugliste sind noch da. Kein roter Text.
- [ ] Nur mit Regler, der beim Akkuwechsel selbst bei 0 beginnt: AUF 0 drücken, Sender aus, neuen Akku anstecken, Sender ein.
- **Erwartet:** VERBRAUCHT beginnt bei 0 und zählt mit dem Regler hoch.

### 13. Englisch
- [ ] Menü › Anzeige › Sprache auf **English**, Menü schliessen und wieder öffnen.
- **Erwartet:** Anzeige, Menü und Ansagen sind englisch.

### 14. Sender ohne Berührung (nur X14, X10, X12)
- [ ] Mit dem Drehrad zur Flugliste und zurück. Im Menü oben **Kapazität auf 0** und **Flug löschen** ausprobieren.
- **Erwartet:** Alles geht ohne Berührung, jede Löschung fragt nach.

## Einen Fehler melden

1. Im Repo auf GitHub: **Issues › New issue › «Fehler / Bug»**. Das Formular fragt alles Nötige ab.
2. **Bildschirmfoto:** Am Sender ein Foto mit dem Handy genügt. Wichtig ist roter Text unten links im Widget.
3. **Log:** Lua-Fehler stehen im Log des Senders. In der FrSky Suite (Sender per USB im Modus «Ethos Suite»)
   das **Debug-Log** öffnen und den Text mit «Electric» kopieren. Alternativ unter System › Info die gespeicherten Fehler abfotografieren.
4. Gib die **Nummer des Testfalls** an und was du erwartet hast.

Ideen und Wünsche bitte mit der Vorlage **«Wunsch / Idee»**.

## Bekannte Grenzen von 0.7.3

- Am echten Sender getestet nur auf der **X18RS** (Ethos 26.2.0). Die anderen Sender nur im Simulator.
- Nicht am echten Sender geprüft: jeder Menüpunkt einzeln, Flugerkennung und Flugliste mit einem echten Flug.
- Einstellungsdatei aus Lua-Studio: am Sender ohne Telemetrie geprüft (ohne Datei, Demo-Datei, `.funke.lua`,
  kaputte Datei, Übertragung aus Lua-Studio). Mit Telemetrie geprüft: Anzeige, Sensorsuche, Alarm bei Motorschalter
  aus und ein, Motorschalter, Flugerkennung und Flugliste (0.3.1). Format 2 (0.4.0): volle Testdatei im Vollbild, 10 Modellwechsel, Ansicht aus Lua-Studio per Serial. Noch offen: Format 2 mit Leisten, Studio-Platz mit Sensor,
  Kompaktansicht und Englisch mit Einstellungsdatei.
- Nach «Alle Sensoren löschen» in Ethos zeigen die Felder 0, bis das Modell neu geladen ist (dann «Suchen»).
  Bitte darauf besonders achten.
- Die Ansagen wurden mit Version 0.1.2 abgehört.
- Befehle je Aufruf (Lua-Studio-Format 2 verlangt unter 5 000): am Mac gezählt braucht das Zeichnen bis rund 13 000
  (volle Format-2-Datei; eingebaute Seite rund 8 700) und ein wakeup bis rund 9 100 (Sensorsuche; ohne Studio-Datei
  rund 7 600). Die Pflichttests 12, 16 und 17 des Formats sind in diesem Punkt offen. Am X18RS lief die volle Datei
  ohne «Max instructions».
- Die Kompaktansicht ist neu in 0.2.0. Auf X10 / X12 ist sie nicht geprüft.
- Lua-Speicher rund 133 KB. Auf Sendern mit vielen anderen Lua-Widgets kann der Speicher knapp werden.
