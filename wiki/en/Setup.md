🇬🇧 English · [🇩🇪 Deutsch](../de/Einrichten.md)

# Setup

## 3. Set up the screen

1. Tap the **Screens** icon at the bottom (two rectangles).
2. Tap **+** at the top right.
3. Swipe down to the layout **Full screen** (one large field) and tap it. To keep the Ethos top and bottom bars, choose the layout with **one field and the bars** instead (bottom centre of the layout grid); Elektro then shows the compact view (chapter 5).
4. Tap the empty field, then **Widget**.
5. Swipe to the bottom of the list and select **Elektro**. The display appears at once.

You reach the widget menu any time through Model › Screens › select the screen › tap the widget.

## 4. Sensors and battery

1. Switch the model on so telemetry runs. The first time, Elektro finds the sensors itself; a short blue note «… sensors assigned automatically» appears.
2. Open the menu and the group **Sensors**. Check every line and select missing or wrong ones by hand. An empty line is allowed; the field then shows a dash.
3. **Find sensors (empty only)** › **Search** later fills only empty lines; your own choices stay. If you deleted sensors in Ethos and searched again, first reload the model (select another model and back), otherwise the values stay at 0. Then the search binds each line to the matching sensor (same ID and name); lines whose sensor is no longer in the sensor list, including ones you chose yourself, are searched again.
4. The group **Check assignment** shows each chosen sensor with physical ID and AppID (e.g. «ESC Current P04 / 0B50»). If several identical sensors matched, a line «n sensors match, chosen: … - please check» follows.
5. Open the group **Battery** and set **Battery type**, **Cell count** and **Capacity** of your flight pack.

| Menu line | Which sensor belongs there |
|---|---|
| Pack voltage | Voltage of the whole flight pack, e.g. «VFAS», «ESC Voltage», «Volt». Not the receiver voltage. |
| Cells (cell sensor) | Only if you have a cell sensor (e.g. FLVSS, shown as «Cells» or «LiPo»). Otherwise leave empty. |
| Current | ESC current, e.g. «Current», «ESC Current». |
| Used (mAh) | Consumed capacity, e.g. «Consumption». |
| Battery % (ESC) | Only if your ESC sends the battery level in %, e.g. «Fuel», «Bat%». |
| RPM, ESC temperature, BEC voltage | The matching values of the ESC. |
| Altitude, Vario, Speed | From a vario or GPS (e.g. «Alt», «VSpd», «GSpd»). |
| RSSI, LQ | Signal strength «RSSI»; with ELRS and similar the link quality «LQ». |

**Cells with and without a cell sensor.** With a cell sensor the field «CELL LOWEST» shows the weakest cell, below it a small bar per cell (the weakest in yellow) and «Δ» = difference between strongest and weakest cell. Without a cell sensor «CELL Ø» shows the average cell = pack voltage ÷ cell count, with a bar for the pack voltage. For this the
**Cell count** must be set; Elektro never guesses it from the voltage. If it is 0 (auto) and there is no cell sensor, the field shows «Cell count?» in orange and the battery gauge «Set cell count».

![cell sensor](../../docs/bilder-simulator/Elektro%20-%20Sim%20800x480%2020%20Zellensensor.png)
*With cell sensor: bar per cell*

![cell count missing](../../docs/bilder-simulator/Elektro%20-%20Sim%20800x480%2011%20nur%20ein%20Teil%20der%20Sensoren.png)
*No cell sensor, no cell count: «Set cell count»*

## 8. All settings

Open the menu: Model › Screens › select the screen › tap the widget. Every change applies at once and is saved.

| Group | Setting | Default | Effect |
|---|---|---|---|
| top | Battery % from | – | Shows where the battery level comes from now: ESC, calculated or no value. |
| Sensors | 13 lines | empty | See chapter 4. |
| Battery | Battery type | LiPo | LiPo, LiHV, LiFe, Li-Ion or NiMH. Sets the curve for battery % and the bars. |
| Cell count (0 = auto) | 0 | Cells in series. 0 = from the cell sensor; without one please set it. |
| Capacity | 4500 mAh | Capacity of the flight pack, for battery % and the «Used» limit. 0 = battery % from voltage only. |
| Battery % from | ESC, else calculated | «always calculated» ignores the ESC value. |
| Divide RPM by | 1 | For ESCs sending electrical RPM: enter the number of pole pairs. |
| Limits | warning and alarm per value | see chapter 6 | 0 = off. |
| Alarm also with motor off | on/off per value (10 lines) | on | Off = this value stays silent while the motor is off (chapter 6). |
| Switches | Motor off at | SF↑ | Switch position in which the motor is off. |
| Announce at | SG↓ | Switch position for the announcement. |
| Switch 1 and 2 | empty | Own switches shown in the top bar while switched on. |
| Switch 1 and 2 name | SCHALTER 1 / 2 | Your own name, up to 12 characters, e.g. STABI or GEAR. |
| Flight | Detect flight by | Motor switch | Or «Current or throttle». |
| Throttle channel | empty | Throttle channel: for the THROTTLE field and for detection by throttle. |
| Flight from current | 3 A | From this current the flight runs. |
| Flight from throttle | 10 % | From this throttle position the flight runs. |
| Pause after | 20 s | Time without current and throttle until «Flight ended?» appears. |
| Flight counts from | 30 s | Shorter runs do not go into the list. |
| Battery change ends flight | on | A paused flight ends when telemetry is gone for over 30 s. |
| Announcements | Announce alarms | on | Off: on alarm only tone and display. |
| Announce warnings too | off | On: the orange warning is announced too. |
| Repeat alarm every | 10 s | 3 to 300 s. |
| Announce battery % every | 10 % | off, 5 %, 10 % or 20 %. |
| Announce «motor off» | on | Announcement when the motor is switched off. |
| Announce: battery % | on | What the announce switch says. |
| Announce: flight time | on |
| Announce: altitude | off |
| Announce: used | off |
| Tone on alarm | on | Beep before the alarm announcement. |
| Vibration on alarm | off | The radio vibrates on every alarm. |
| Fields | Gauge 1 to 4, Field 1 to 6 | as in the picture | Content: Battery %, Current, RPM, ESC temp., Cell, Pack voltage, Used, Power, Altitude, Vario, Speed, Signal, BEC, Flight time, Throttle % or empty. |
| Large field (left) | Throttle % | The large field at the bottom left; in the compact view the first of the eight fields. After an update from 0.1.x it shows what was in field 7, if the plane picture was off. |
| Current / RPM / Temp. gauge up to | 120 A / 12000 / 100 °C | End value of the arc. |
| Display | Sprache / Language | as the radio | German or English for display, menu and announcements. The menu changes the next time it is opened. |

---
[← Home](../Home.md) | [Previous](Installation.md) | [Next →](Display.md)
