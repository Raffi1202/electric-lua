🇬🇧 English · [🇩🇪 Deutsch](../de/Anzeige.md)

# Display

## 5. The display

![Display with numbers](../../docs/bilder-simulator/Electric%20-%20Sim%20800x480%2012%20Englisch.png)

*The numbers of the table are drawn into this picture in the PDF manual.*

This picture shows an alarm (red top bar and frames); in normal operation the top bar is dark.

| No. | What you see | What it means |
|---|---|---|
| 1 | Model name, top bar | Name of the model in the radio. The top bar turns orange on a warning and red on an alarm. |
| 2 | Flight time | Duration of the current flight in minutes:seconds. It runs only while the motor is on. |
| 3 | ARMED / MOTOR OFF | Position of the motor switch (only if one is set). To its left your own switches appear as green pills while switched on (e.g. «GEAR»). If there is not enough room, the front one is left out. |
| 4 | Bars, battery icon | Signal strength (RSSI) in four steps and the radio's own battery. |
| 5 | Four gauges | By default BATTERY (level in %, below it cell count and pack voltage), CURRENT in amps, MOTOR in RPM and ESC TEMP in °C. «MAX» below is the highest value measured with this pack, not a limit. |
| 6 | THROTTLE | Throttle in % from the throttle channel, below it the current at that moment («at 46 A») and a bar. If it shows «Select throttle» in orange, choose the Throttle channel in the menu under Flight. In the menu (Fields › Large field) you can also choose another content. |
| 7 | «8 flights» | Number of flights of this model, the current one included once it counts (chapter 7). Tap to open the flight list. |
| 8 | CELL Ø or CELL LOWEST | Voltage per cell under load (box in chapter 4). «LOW» is the lowest value with this pack. |
| 9 | USED, button RESET | mAh used since plugging in or since «RESET». You only need the button if your ESC does not start at 0 after a pack change. |
| 10 | POWER | Pack voltage × current in watts, below it the energy used with this pack in Wh. |
| 11 | ALTITUDE | Altitude in metres, below it climb ↑ or sink ↓ in m/s and in yellow the highest altitude with this pack. |
| 12 | SPEED | Speed in km/h, below it the highest value. |
| 13 | SIGNAL | RSSI in dB, below it LQ in % and the lowest RSSI («LOW»). If your receiver sends RSSI in dBm (negative, e.g. ELRS, Crossfire), it is shown as in the sensor menu, e.g. «-80 dBm». |

A short grey dash instead of a number means: this value is not arriving or has no sensor. You choose what each gauge and field shows in the menu (chapter 8, group Fields).

**Battery %** comes from the ESC if it sends it and «Battery % from» is «ESC, else calculated». Otherwise Electric calculates: when the model rests 2 seconds without current, it takes the start value from the resting voltage (curve of the battery type) and then counts down with the used mAh and the capacity. «REST» then appears below the gauge. The menu line «Battery % from» shows what applies.

**New pack:** if telemetry is gone for more than 30 seconds (pack unplugged), MAX and LOW values, Wh and battery % start again.

### Compact view

If you choose the layout with top and bottom bars (chapter 3), Electric notices it and shows a compact view: a narrow bar with flight time, ARMED / MOTOR OFF and signal (model name and radio battery are in the Ethos top bar), below it the four gauges and eight fields: the large field (THROTTLE by default, here without bar), fields 1 to 6 and FLIGHTS. Tap FLIGHTS to open the flight list. Everything else works as in the full screen.

![compact view](../../docs/bilder-simulator/Electric%20-%20Sim%20784x316%2030%20Kompakt%20Normal%20mit%20Gas.png) Compact view on X20 and X18RS (784 × 316). On X14 and X18 / Twin X Lite it is smaller accordingly.

### Flight mode, two receiver bands, second battery (from 0.10.0)

- **Flight mode:** If the model has several flight modes, the active one is shown small under the model name (compact view: right of the flight time). Ethos does not tell a Lua how many modes exist, so the line appears once the model has been in a mode other than the first one, and this is remembered per model. Menu: «Show flight mode».

- **Two receiver bands:** With dual-band receivers (TD 2.4 GHz + 900 MHz, LoRa) the search finds RSSI and VFR per band by itself (Ethos reports the band of each sensor). The receiver box shows the better band large and «VFR 2.4 x% 900 y%» below (without VFR: RSSI in dB). Warning per band («Warning! 2.4 gigahertz signal» / «900 megahertz signal», limit «VFR warning below»), alarm only on RX VFR (limit «RX VFR alarm below»), without RX VFR on the better band.

- **Cells 2 and receiver battery 2:** A second cell sensor (different physical ID) is found as «Cells 2». «in series»: both belong to the same pack (lowest cell of both, sum of voltage). «own battery»: own cell count, warning «Cell voltage battery 2», «Battery 2» in percent with announcement. «Receiver battery 2» (RxBatt 2) uses the BEC limits and «Warning! Receiver battery 2».

- **Instruction limit:** With full load (40 sensors, both bands, battery 2, active alarms) drawing counts 10,188–10,400 and a search step 5,044 instructions on the Mac, slightly above the own limit (0.9.0 similar). The transmitter test with this load is still pending.

## 7. Operation

### Detecting flights

By default Electric detects a flight by the **motor switch**: «Motor off at» is **SF↑**. Arm the motor and the flight time starts; switch it off and the radio says «Motor off», the time stops and the question «Flight ended?» appears.

- **YES, ENDED**: the flight goes into the list.

- **NO, JUST PAUSE**: the flight stays open. Arm the motor again and it continues.

- A paused flight ends by itself when you unplug the pack (telemetry gone for over 30 s, «Battery change ends flight»).

A flight counts only after 30 seconds of motor time («Flight counts from»); shorter runs on the ground are dropped. Without a motor switch, or with «Detect flight by» = «Current or throttle», the flight starts as soon as the current is above 3 A or the throttle above 10 %, and the pause with the question comes after 20 seconds below.

### Flight list (page 2)

Swipe left or tap «8 flights». The flights are on the right, newest first, the current one in blue with «running» or «paused». Tap a flight and its values appear on the left. The rotary encoder also selects flights.

![flight list](../../docs/bilder-simulator/Electric%20-%20Sim%20800x480%2013%20Englisch%20Flugliste.png)

1. Delete one flight: tap it, **DELETE FLIGHT n**, then **YES, DELETE**. The later numbers move up.
2. Delete all flights: **CLEAR LIST**, then **YES, DELETE**. The counter starts at 1 again.
3. Back to the display: **< BACK** or swipe right.

The list keeps the last 20 flights. It survives switching off. A paused flight is closed at the next switch-on and goes into the list (if «Battery change ends flight» is on).

### Used capacity to 0

Tap **RESET** in the USED field and confirm with **YES, RESET**. **CANCEL** leaves everything as it is.

### Announcement on a switch

Switch **SG↓** on («Announce at») and the radio announces battery level and flight time. Choose what is announced in the group Announcements. In addition Electric announces the battery level every 10 % while discharging («Announce battery % every»).

### Radios without touch (X14, X10, X12)

At the top of the menu there are **Reset capacity**, **Delete flight** (first choose the number at «Flight no. to delete») and **Delete whole list**, each with a question. The rotary encoder takes you to the flight list and selects flights; turning back before the first flight returns to the display.

---
[← Home](../Home.md) | [Previous](Setup.md) | [Next →](Alarms.md)
