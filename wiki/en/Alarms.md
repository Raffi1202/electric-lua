🇬🇧 English · [🇩🇪 Deutsch](../de/Alarme.md)

# Alarms

> **Pre-release:** version 0.5.0 is tested in the Ethos simulator; the transmitter test on the X18RS follows. Use at your own risk.


## 6. Warnings and alarms

Every monitored value has two limits: warning (orange, display only) and alarm (red, frame, tone and announcement). Set both in the menu group **Limits**; 0 switches a limit off. Defaults:

| Value | Warning (orange) | Alarm (red, tone, voice) |
|---|---|---|
| Battery % | below 30 % | below 20 %, «Warning! Battery» and the number |
| Cell (average or lowest) | below 3.50 V | below 3.30 V, «Warning! Cell voltage» and the number |
| Cell difference (cell sensor only) | above 0.10 V | above 0.20 V, «Warning! Cells unbalanced» and the number |
| ESC temperature | above 70 °C | above 85 °C, «Warning! ESC temperature» and the number |
| Current | above 80 A | above 100 A, «Warning! Current» and the number |
| Used (% of capacity) | above 70 % | above 80 %, «Warning! Capacity» and the number |
| BEC voltage | off | off |
| Altitude | above 110 m | above 120 m, «Altitude» and the number |
| RSSI (for dBm values: limit = dBm + 120, e.g. 40 = -80 dBm) | below 45 dB | below 40 dB, «Warning! Signal» and the number |
| LQ | below 70 % | below 50 %, «Warning! Signal» and the number |

The cell limits are for LiPo and LiHV. If you choose another battery type while the cell limits are still at their defaults, Elektro changes them: LiFe 3.00/2.80 V, Li-Ion 3.20/3.00 V, NiMH 1.10/1.00 V.

![warning](../../docs/bilder-simulator/Elektro%20-%20Sim%20800x480%2005%20Warnung.png)
*Warning: top bar and value orange, no tone*

![alarm](../../docs/bilder-simulator/Elektro%20-%20Sim%20800x480%2012%20Englisch.png)
*Alarm: top bar red, red frame, tone and voice*

A warning appears when the value is beyond the limit for 1 second and disappears when it is good again for 3 seconds. An alarm beeps, announces the value and repeats every 10 seconds («Repeat alarm every») as long as it lasts. There are always at least 3 seconds between two announcements.

**Alarm also with motor off** (from version 0.5.0): by default all warnings and alarms also come when the motor switch is set to «off». In the menu group **Alarm also with motor off** you can turn this off per value. That value then stays silent while the motor switch is set to «off»: no message, no tone, no announcement, no vibration. The colour of the value still shows the limit. As soon as you arm the motor, the alarm comes back. Without a motor switch set, this setting never applies.

### What can never be silenced
- A Lua-Studio file can switch a monitored alarm off completely **only with `aus = true`** (user decision 20 Nov 2026). An entry without levels (only announcement, vibration or «also with motor off») or with warning and alarm both `false` keeps the factory limit.
- «Alarm also with motor off» = off silences that value only while the motor switch is set to off; without a motor switch set it never applies.
- Elektro has no error codes or shutdown reasons from an ESC; all its alarms are limit alarms as listed above.

---
[← Home](../Home.md) | [Previous](Display.md) | [Next →](Lua-Studio.md)
