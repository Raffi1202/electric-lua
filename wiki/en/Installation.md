🇬🇧 English · [🇩🇪 Deutsch](../de/Installation.md)

# Installation

## 1. What you need

- A FrSky radio with Ethos 26.2 (tested) and a colour display (list at the end).

- An electric model with telemetry, sensors already discovered (Model › Telemetry › Discover sensors). At least the pack voltage is needed; current, consumption, RPM, temperature, altitude, speed and a cell sensor are optional.

- A computer with FrSky Suite and a USB cable.

- The file `Electric-0.6.0.zip`. It is inside `Electric-0.6.0-share.zip`. Unzip only the outer ZIP, not the inner one.

## 2. Install

1. Switch the radio on and connect it to the computer with the USB cable.
2. The radio shows a choice. Select **Ethos Suite**.
3. Open **FrSky Suite** on the computer. The radio appears at the top.
4. Click **Lua library**, then **Install from local ZIP**.
5. Select `Electric-0.6.0.zip`. The Suite copies everything to the right place.
6. Unplug the cable and restart the radio.

Without the Suite: connect the radio as «USB storage» and copy the folder `electric` from the ZIP into `scripts`. If your radio loads scripts from the SD card (System › General › Storage location), it belongs in `scripts` on the SD card. Overwrite an existing folder, do not delete it.

## 11. Which radios

| Display | Radios | Status |
|---|---|---|
| 800 × 480, touch | X20, X20S, X20HD, X20 Pro, X20R, X20RS, X18R, X18RS | X18RS tested on the real radio, the others in the simulator |
| 640 × 360, no touch | Twin X14, X14S | simulated |
| 480 × 320, touch | X18, X18S, X18SE, Twin X Lite, Twin X Lite S | simulated |
| 480 × 272, no touch | X10, X10S, X10 Express, X12S with Ethos | simulated |

Electric version 0.6.0 · 21 Nov 2026

## Upgrading from the German version (Elektro)

Electric was called **Elektro** up to version 0.5.0. From 0.6.0 everything has English names: widget **Electric**, folder `scripts/electric`, Studio file `<model>.electric.lua`. This is a breaking change:
- Install `Electric-0.6.0.zip`, then **add the widget again** in every model (Model › Screens › tap the field › widget **Electric**). The settings of the old widget are not taken over; set battery type, cell count, capacity and limits again.
- Studio files: re-transfer them from Lua-Studio (they are then named `….electric.lua`). Until then Electric still reads an old `….elektro.lua` and writes «old studio file found, please re-transfer» to the log.
- The old folder `scripts/elektro` can be deleted after the change.

---
[← Home](../Home.md) | Previous | [Next →](Setup.md)
