# Electric versions (formerly Elektro)

The version number is in `src/electric/main.lua` (`local VERSION`). It is the same in the manual, the Suite package and here.
The top section appears in the FrSky Suite as version note. From 0.5.0 on in English; older entries in German.

## 0.7.4 (22 Nov 2026, pre-release)

- A layout whose boxes reach into the widget's own header is moved below it (all boxes, proportionally), so the
  header never covers a value.
- The unit is left out only if the title contains it as a word of its own (e.g. «Akku %», «Strom (A)»), not inside
  another word («Höhe max», «Akku Strom»).

## 0.7.3 (22 Nov 2026, pre-release)

- Box header (Lua-Studio format 2, transmitter test): no large bold unit next to the symbol any more. A unit marked
  «bold» is shown small next to the value, and not at all if the title already contains it (e.g. «Akku %»).
  The title text is as high as the symbol, so the symbol is never larger than the text beside it.
- Full screen 800 × 480: the reserved «Flights» button no longer covers a box; boxes reaching into it are shortened.
- Instruction limit: full stress files (16 boxes with symbols) ran on the X18RS without «Max instructions».

## 0.7.2 (22 Nov 2026, pre-release)

- Info file: the hint «view … adapted» is cleared when the widget switches back to a window size with an exact layout
  (before, it could stay from the scaled preview in the screen setup).

## 0.7.1 (22 Nov 2026, pre-release)

- Studio hints («view … adapted», «file broken», «no matching view») are shown in the widget's own header instead of
  a band at the bottom, so no value is covered.
- Instruction limit kept in every wakeup (< 5000), also right after loading a model: the sensor index, loading
  `studio.lua`/`felder.lua`, applying the Studio file and scaling a layout (boxes and decoration) are spread over
  several calls. Highest wakeup in the Mac tests 4687 (before 7832).

## 0.7.0 (22 Nov 2026, pre-release)

- Studio layout is always found: the Studio file is searched in `SCRIPTS:/studio/`, `SD:/scripts/studio/` and
  `RADIO:/scripts/studio/` (in this order). `.funke.lua` and the info file stay in `SCRIPTS:/studio/`.
- New menu entry «Studio layout»: choose any `*.electric.lua` (shown with its location) if the file name does not match
  the model name; «automatic (model name)» is the previous way. The choice wins and is stored at the end of the widget
  storage (FORMAT 2). Storage from 0.6.1 is read without loss, the choice is then «automatic».
- Other window size: without an exact layout, the layout with the most similar aspect ratio is scaled to the window
  (below the header), once per size in wakeup. Boxes that get too small become a number or are left out (counted).
  A hint «Studio: view 800x480 adapted» shows for 5 s.
- If the built-in display stays although a file was found or chosen, a line at the bottom gives the reason
  («Studio: file broken (…)», «Studio: no matching view», «Studio: chosen file missing (…)»).
- Info file: new fields at the end `studioQuelle`, `studioWahl`, `ansichtGenutzt`, `angepasst`, `hinweis`.
- Tests: `test/layout-test.lua` (cases F1–F5 on the Mac).

## 0.6.1 (21 Nov 2026, pre-release)

- Upgrade from Elektro: if there is no `daten/<model>.txt` in `scripts/electric`, Electric reads the old one from
  `scripts/elektro/daten/` (settings, counters, flight list), writes «settings taken over from scripts/elektro/…» to the
  log and saves it in the new folder. The old folder is never changed or deleted.
- The widget storage format is unchanged since 0.5.0 (FORMAT 1, 18 sources in the same order): a model whose widget key
  is converted from `elektro` to `elec` keeps its sensors and switches. Test: `test/format050-test.lua`.

## 0.6.0 (21 Nov 2026, pre-release)

- **Renamed from Elektro – breaking: old models must re-add the widget; Studio files must be renamed or re-transferred.**
  Visible name **Electric**, folder on the radio `scripts/electric`, widget key `elec` (Ethos allows at most 7
  characters), Studio files `<Kennung>.electric.lua` / `.electric.funke.lua` / `.electric.info.json`, `"lua": "electric"`
  in `beschreibung.json` and the info file, packages `Electric-0.6.0.zip` and `Electric-0.6.0-share.zip`, repository
  `electric-lua`. The settings of the old widget are not taken over (they belong to the widget key).
- Transition: if there is no `<Kennung>.electric.lua` but an old `<Kennung>.elektro.lua`, Electric reads it and writes
  «old studio file found, please re-transfer» to the log. Changes on the radio go to the new `.electric.funke.lua`.
- Suite description (INFO) in English. No other functional change compared with 0.5.0.
- Test: `test/motoraus-test.lua` case k (old studio file).

## 0.5.0 (21 Nov 2026, pre-release)

- **Memory freed on model change:** after changing to a model without Elektro, about 129 KB of Lua memory stayed in use so far, about 207 KB with a large Studio file and symbols (X18RS simulator). Now only the widgets themselves hold the core; when Ethos drops them on a model change, garbage collection frees everything. About 5 KB stay, also after several changes.
- **«Alarm also with motor off» per value** (Lua-Studio format 2, section 3.5, key `beiMotorAus`): new menu group with 10 on/off settings, all on by default. Off = this value stays completely silent (message, tone, announcement, vibration) while the motor switch is set to off; a running alarm stops at once, the colour of the value stays. Without a motor switch the setting never applies. Lua-Studio can set it per limit, also for sensors and channels; changes on the radio go into the `.funke.lua`. `beschreibung.json` and the info file report `"beiMotorAus": true`.
- **Fix (critical, since 0.3.0):** a limit entry of the Studio file without levels (only `ansage`, `vibration` or `beiMotorAus`) or with `warnung = false` and `alarm = false` without `aus = true` switched the monitored alarm off completely. Now the factory limit applies; an alarm is only fully silent with `aus = true`.
- **Studio file after a model change:** loading and symbols now take one step in every wakeup, not only every 0.2 s (a full file takes 15–27 steps, counted on the Mac). If the file has a layout for the window size, «Studio-Datei wird geladen ...» / «Loading Studio file ...» is shown while loading instead of the built-in layout. After loading Elektro writes «Elektro: Studio-Datei geladen in x s (n Schritte)» to the log, so the time can be measured on the radio. A runtime error while loading leads to the built-in display with a message instead of a hang.
- The widget storage FORMAT stays 1: the new on/off values are stored by name in the model file or `.funke.lua`.
- Tests: `test/motoraus-test.lua`, `test/speicher-test.lua`.

## 0.4.0 (21.11.2026)

- **Lua-Studio-Format 2:** Symbole als Bildmasken (`SCRIPTS:/studio/symbole/<name>_<px>.png`), fette Einheit oben
  links (`einheitZeigen`), Schmuck je Ansicht (`deko`: Symbol, Text, Linie, Rahmen). Über den Referenzbaustein
  `studio_symbole.lua` der Lua Suite (wörtlich übernommen): Kopfprüfung jeder PNG vor dem Laden, höchstens 4 Masken je
  wakeup und je Bild zum ersten Mal, Hinweis «Studio: n Symbole fehlen». Format-1-Dateien laufen wie bisher.
- Pflichtregeln Format 2: werte, grenzen und einstellungen höchstens 48 Einträge (Rest verworfen mit Hinweis),
  Prüfung in Stücken zu 8, Kanäle aus der Studio-Datei nur mit Wert. Info-Datei meldet `formate: [1, 2]`.
- Die Diagnosezeile «Motorschalter …» im Log (0.3.1) ist wieder weg; der Motorschalter ist am Sender bestätigt.
- Tests: `test/format2-test.lua` (alle Pflicht-Testdateien p00–p17 der Lua Suite: Zählungen, loadMask nur für gültige
  Dateien, keine Datei ausserhalb von symbole/, 640 px, Modellwechsel).
- Am Sender (X18RS, Ethos 26.2.0): volle Testdatei `p12_voll.lua` (16 Symbole 64 px, fette Einheit, Schmuck) im
  Vollbild und 10 Modellwechsel ohne Fehler. Am Mac gezählt braucht das ganze Bild bis rund 13 000 Befehle (eingebaute
  Seite rund 8 700), ein wakeup bis rund 9 100 (Sensorsuche; ohne Studio-Datei rund 7 600); am Sender kein «Max
  instructions». Die Pflichttests 12, 16 und 17 (unter 5 000) sind in diesem Punkt offen. Eine in Lua-Studio gestaltete
  Ansicht (7 Symbole, fette Einheit) wird per Serial übertragen, geladen und gezeigt.
- Korrektur aus der Prüfung: Ein fehlender Sensor oder Kanal in einem Studio-Platz zeigt wieder «---» (war im Umbau
  verloren gegangen); die Original-Tabellen der Datei bleiben nur bei Format 2 im Speicher.

## 0.3.2 (20.11.2026)

Korrekturen aus der Prüfung von Jet 0.2.0 (dessen Studio-Teil von Elektro stammt) und Sendertest 0.3.1:
- **Befehlsgrenze:** Grosse gültige Studio-Dateien brauchten bis 12 340 Befehle in einem Aufruf (z. B. 100
  Wert-Anpassungen); am Sender droht «Max instructions». Einstellungen, Werte, Grenzen, Zusammenführen und das
  Vorbereiten der weiteren Grenzen laufen jetzt in Stücken (höchstens rund 2 600 Befehle je Aufruf, `anwenden` rund 3 000).
  Im Betrieb prüft Elektro die Grenzen für Sensoren und Kanäle der Studio-Datei im Ring, je Aufruf 10 (vorher alle in
  jedem Aufruf: 60 Grenzen über 7 000 Befehle). Grenzen, die gerade warnen, alarmieren oder kurz davor sind, prüft es
  zusätzlich in jedem Aufruf (höchstens 6), mit derselben Entprellung wie die Grundwerte. Bis 10 Grenzen ändert sich
  nichts; bei 160 Grenzen kommt ein neuer Alarm nach höchstens etwa 4,2 s statt nach 1 s.
- **Fehlende Sensoren der Studio-Datei:** `system.getSource` liefert dafür ein Objekt der Kategorie «keine». Elektro
  prüft die Kategorie; der Platz zeigt «---» statt eines Scheinwerts, kein Fehlalarm.
- **Sensoren der Studio-Datei und Info-Datei:** Am Sender (X18RS, Ethos 26.2.0) liefert `system.getSources` mit einer
  Tabelle als Filter eine leere Liste, und `system.getSource` über die AppID ein Objekt ohne Wert (Messwidget
  20.11.2026). Elektro holt die Sensorliste jetzt mit der Kategorie als Zahl (wie die Sensorsuche) und sucht
  Studio-Sensoren darin über AppID, Teilwert und Physical ID. Vorher hätten Studio-Plätze mit Sensoren am Sender «---»
  gezeigt und die Info-Datei keine Sensoren enthalten (beides am Sender noch nicht geprüft).
- **Alarm nie ganz stumm (Entscheid des Autors):** Schaltet die Studio-Datei die Ansage eines Werts aus, oder hat ein
  Sensor bzw. Kanal keine eigene Ansage, kommt beim Alarm ein Ton. Ganz still nur mit `aus = true`.
- Mit Studio-Datei belegt nur, was hörbar war, den Abstand zur nächsten Ansage; stille Einträge blockieren die
  Ansagen nicht mehr. Ohne Studio-Datei bleibt es wie bisher.
- Sendertest 0.3.1: Motorschalter, Alarm bei SF scharf und aus, Flugerkennung und Flugliste bestanden. Nach «Alle
  Sensoren löschen» bleiben die Felder auf 0, bis das Modell neu geladen ist (Ursache wird gemessen); die Anleitung
  nennt den Umweg.
- Tests: `test/studio-test.lua` (i, j, k), `test/neustart-test.lua` (f, g).

## 0.3.1 (20.11.2026)

Korrekturen aus dem Sendertest von 0.3.0 (X18RS, Ethos 26.2.0):
- **Motorschalter:** Die Pille zeigte bei SF oben und unten «MOTOR AUS», Flugzeit und Flugerkennung über den
  Schalter liefen nicht. Schalterstellungen, logische Schalter und Funktionsschalter liest Elektro jetzt über ihren
  Zustand (`state`), andere Quellen wie bisher über den Wert. Bei jedem Umschalten steht eine Zeile im Log.
- **Sensoren nach «Alle Sensoren löschen»:** Alte Verweise lieferten 0 und lösten Alarme aus, «Sensoren suchen» füllte
  nur leere Zeilen. Die Suche bindet jetzt jede Zeile an den passenden neuen Sensor (AppID, Teilwert, Physical ID,
  Name); Zeilen ohne Gegenstück werden neu gesucht. Quellen ausserhalb der Telemetrie bleiben.
- **MAX-Werte:** Bekommt ein Feld eine neue Quelle, beginnen seine Höchst- und Tiefstwerte neu (vorher stand z. B.
  «MAX 98400» aus einer früheren Zuordnung).
- Alarme kommen weiterhin auch bei Motorschalter «aus» (Regel des Autors, Pflichttest im Testleitfaden 10).
- Tests: `test/suche-test.lua` (h), `test/neustart-test.lua` (d, e), Simulatorablauf 25 (SF umlegen).

## 0.3.0 (20.11.2026)

- **Einstellungsdatei aus Lua-Studio** (Lua-Studio-Format v1): Elektro liest beim Laden des Modells
  `scripts/studio/<Modell>.elektro.lua`, prüft jede Angabe und zeigt bei Problemen einen Hinweis (nie ein Absturz).
  Freie Kästchen mit sechs Darstellungsarten (Zahl, Ring, Balken waagrecht/senkrecht, Verlauf, Status), eigene
  Farben und Farbstufen, Zusatzzeile MIN/MAX/Ø, Einstellungen und Grenzwerte je Modell, Grenzen auch für Sensoren und
  Kanäle. Änderungen im Funken-Menü gehen in eine eigene Datei `…elektro.funke.lua`. Menü «Zurück auf Studio-Stand»
  bzw. «Zurück auf Standard». Info-Datei für Lua-Studio mit Sensorliste.
- Ohne Einstellungsdatei bleiben Anzeige, Einstellungen und Alarme wie in 0.2.0. Neu sind dann nur die Menüzeile
  «Studio-Datei: keine» mit «Zurück auf Standard» und die Info-Datei `scripts/studio/<Kennung>.elektro.info.json`
  für Lua-Studio (Modellname, Sender, Sensorliste).
- Tests: `test/studio-test.lua` (alle Angriffs- und Grenzfalldateien, volle Belegung, zehn Modellwechsel,
  Stromausfall beim Schreiben), Simulatorabläufe 40–43.

## 0.2.0 (20.11.2026)

- **Kompaktansicht:** Im Ethos-Layout mit Kopf- und Fussleiste erkennt Elektro das flache Fenster selbst und zeigt
  eine schmale Leiste (Flugzeit, Pillen, Empfang), vier Tachos und acht Felder. Der Hinweis «nur im Vollbild» fällt weg.
- **Gas %:** neuer Inhalt aus dem Gaskanal (kein Sensor nötig), mit dem Strom dazu. Ab Werk im grossen Feld unten
  links, das das Fliegerbild ersetzt; wählbar auch für jeden Tacho und jedes Feld.
- Fliegerbild und Einstellung «Fliegerbild» entfernt, ebenso Feld 7 und 8; neu «Grosses Feld (links)». Beim Update
  bleiben die übrigen Einstellungen, Flüge und Zähler erhalten. War das Fliegerbild aus, kommt der Inhalt von Feld 7
  ins grosse Feld; Feld 8 entfällt (`test/update-felder-test.lua`).
- Die Sensorsuche schreibt ihr Ergebnis ins Log.
- Am echten Sender getestet (X18RS, Ethos 26.2.0): Kompaktansicht, Gas % live, Flugerkennung über Gas, Log leer.
- Flugliste: Zeilen nie niedriger als 32 Pixel (auf kleinen Displays weniger Zeilen, mit Rollen).
- Sehr kleine Fenster (unter 300 × 150): nur Name und Flugzeit.

## 0.1.6 (20.11.2026)

Korrekturen aus der unabhängigen Prüfung:
- «AUF 0» und dann Neustart des Senders: Begann der Regler mit dem neuen Akku wieder bei 0, zeigte VERBRAUCHT
  über lange Zeit 0 mAh, und Akku % und der Kapazitätsalarm stimmten nicht. Elektro erkennt den Neubeginn jetzt
  auch nach einem Neustart.
- Ein pausierter Flug von vor dem Neustart lief mit dem nächsten Akku weiter (zwei Akkus als ein Flug). Mit
  «Akkuwechsel beendet Flug» wird er beim Einschalten abgeschlossen und kommt in die Liste.
- RSSI in dBm (ELRS, Crossfire) steht jetzt wie im Sensormenü da, z. B. «-80 dBm», statt umgerechnet als «40 dB».
- Anleitung: Bei allen Alarmen wird die Zahl angesagt; Hinweis zu dBm-Schwellen.
- Für Tester: README mit Schnellstart und englischer Zusammenfassung, `TESTLEITFADEN.md`, Vorlagen für
  Fehlermeldungen und Wünsche auf GitHub. Testabläufe ohne Pfade des Entwicklers.
- Am echten Sender getestet (X18RS, Ethos 26.2.0): 20 Flüge laden ohne Befehlsgrenze, Flug löschen, Datei
  schreiben, Log leer. Nicht am Sender getestet: Neustart mit pausiertem Flug.
- dBm-Alarm sagt die angezeigte Zahl an; Tiefstwert beginnt beim Wechsel dB/dBm neu.

## 0.1.5 (20.11.2026)

- Nach einem Neuladen der Skripte ruft Ethos die Widget-Rückrufe kurz ohne Widget auf; das gab Fehlermeldungen im
  Protokoll. Alle Rückrufe prüfen jetzt zuerst, ob das Widget da ist.
- Am echten Sender getestet (X18RS, Ethos 26.2.0): Anzeige, Sensorsuche mit 48 Sensoren, Neuladen ohne Fehler.

## 0.1.4 (20.11.2026)

- Sensorsuche brach am Sender mit vielen Sensoren ab («Max instructions count reached»). Sie läuft jetzt in
  Schritten über mehrere Aufrufe (je Aufruf höchstens 10 Sensoren lesen bzw. 25 Sensoren je Rückfallregel),
  die Kennung wird über einen Index nach AppID-Bereich nachgeschlagen. Höchstens rund 4'200 Befehle je Aufruf
  (gemessen am Mac mit 100 Sensoren); eine Suche mit 100 Sensoren dauert etwa 15 Sekunden.

## 0.1.3 (20.11.2026)

- Automatische Sensorzuordnung nach der gemeinsamen Kennung (AppID + Teilwert, `kennung.lua`): je Feld eine
  Rangfolge (z. B. Regler vor FAS/VFAS, Reglertemperatur vor Temp1), bei mehreren passenden Sensoren der mit Wert,
  sonst die niedrigste Instanz bzw. Physical ID, mit Hinweis im Menü. «Kraftstoff» 0x0600 in mAh zählt als
  Verbrauch, in % als Akku %. Name und Einheit nur noch als Rückfall für Sensoren ohne Kennung.
- Neue Menügruppe «Zuordnung prüfen»: je Sensor Name, Physical ID und AppID.

## 0.1.2 (19.11.2026)

- Werkvorgabe der Schalter am Sender behoben: Motor aus = SF↑ und Ansage = SG↓ werden beim ersten Start jetzt
  wirklich eingetragen (Ethos findet Schalterstellungen nur über ihre Nummer, nicht über den Namen).

## 0.1.1 (19.11.2026)

- Sprachansagen deutsch und englisch (13 Dateien in `audio/de` und `audio/en`): Alarme, «Motor aus», Akku-%-Schritte
  und Ansage auf Schalter sprechen jetzt statt nur Ton und Zahl.

## 0.1.0 (19.11.2026)

- Erste Fassung nach dem freigegebenen Konzept (19.11.2026): Seite 1 mit 4 Tachos und 6 Feldern (wählbar),
  Seite 2 Flugliste, Akku % vom Regler oder gerechnet, Zellen mit oder ohne Zellensensor, zwei Schwellen je Wert,
  Alarm- und Schrittansagen, Ansage auf Schalter, «Motor aus», Flug über Motorschalter oder Strom/Gas,
  deutsch und englisch, alle Displaygrössen. Speicherformat mit Formattabelle für spätere Updates.
