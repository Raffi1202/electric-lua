# Electric – display for electric planes (FrSky Ethos)

**English** · [Deutsch](README.de.md) · Documentation: [Wiki (English)](wiki/en/Installation.md) · [Wiki (Deutsch)](wiki/de/Installation.md)

> **Configure on your PC with [Lua-Studio](https://github.com/Raffi1202/lua-studio)** – arrange the screen, choose values, alarms and symbols, then transfer to the radio. Download: [latest release](https://github.com/Raffi1202/lua-studio/releases/latest) · [Wiki](https://github.com/Raffi1202/lua-studio/tree/main/wiki)

**Electric** is an Ethos widget (full screen or compact view with the Ethos bars) for electric planes on FrSky radios
with a colour display. It shows battery %, cells (with or without a cell sensor), current, RPM, ESC temperature, used
capacity, power, altitude, speed and signal, with warnings and alarms with voice announcements and a flight list.
Display, menu and voice are in German and English.

![Electric on 800 × 480 (Ethos simulator)](docs/bilder-simulator/Electric%20-%20Sim%20800x480%2012%20Englisch.png)

- **Four gauges:** battery %, current, RPM and ESC temperature.
- **Six fields:** cell, used, power, altitude, speed and signal, plus a large **throttle %** field. You choose what goes where in the menu.
- **Full screen or compact:** in the layout with the Ethos top and bottom bars Electric shows a compact view by itself.
- **Cells:** with a cell sensor the lowest cell and the difference, without one pack voltage ÷ cell count.
- **Battery %:** from the ESC or calculated from resting voltage and used mAh.
- **Limits:** two per value (warning orange, alarm red with tone and announcement).
- **Switches:** announcement on SG↓, «motor off» on SF↑.
- **Flight list:** the last 20 flights, each one can be deleted.
- **Sensors** are assigned automatically on first start. What you choose by hand stays.
- **Lua-Studio:** a settings file per model from the PC app Lua-Studio designs the display freely (boxes with number,
  gauge, bar, graph or status, symbols, own colours) and sets settings and limits. Without this file everything works as before.
- **New in 0.7.0:** the Studio file is also found on the SD card or internal memory, can be chosen in the widget menu («Studio layout») and is adapted to other window sizes; a line at the bottom says why if it is not used.
- **New in 0.6.0 (breaking):** renamed from «Elektro» to **Electric** (widget, folder `scripts/electric`, Studio file `….electric.lua`). Add the widget again in every model, see [Upgrading](wiki/en/Installation.md#upgrading-from-the-german-version-elektro).
- **New in 0.5.0:** «alarm also with motor off» per value (menu and Lua-Studio, on by default), memory is freed on model
  change (about 5 KB stay instead of over 100 KB), the Studio file loads faster and shows «Loading Studio file ...».

**Status:** public pre-release (public beta). 0.5.0 is tested in the Ethos simulator; the transmitter test on the X18RS
follows. Use at your own risk. License: GPL-3.0, see below.

## Quick start

1. Download `Electric-0.7.0.zip` from the latest **release**.
2. Connect the radio by USB, choose **Ethos Suite** on the radio and open the **FrSky Suite** on the computer.
3. Suite › **Lua library** › **Install from local ZIP** › choose the ZIP. Then restart the radio.
4. Model › Screens › **+** › layout **Full screen** (or with bars) › tap the field › widget **Electric**.
5. Switch the model on: Electric finds the sensors itself. Then set battery type, cell count and capacity in the widget menu under **Battery**.

Without the Suite it also works via USB storage or SD card (manual chapter 2). Settings, flights and counters stay when you update.

## Documentation and testing

| What | File |
|---|---|
| Wiki | [English](wiki/en/Installation.md) · [Deutsch](wiki/de/Installation.md) |
| Manual (PDF) | [`docs/Electric - Manual.pdf`](docs/Electric%20-%20Manual.pdf) · German: [`docs/Electric - Anleitung.pdf`](docs/Electric%20-%20Anleitung.pdf) |
| Test guide (German, checklist) | [`TESTLEITFADEN.md`](TESTLEITFADEN.md) |
| Bugs and wishes | GitHub › Issues › New issue |
| Versions | [`CHANGELOG.md`](CHANGELOG.md) |

## Radios and test status

| Display | Radios | Status |
|---|---|---|
| 800 × 480, touch | X20, X20S, X20HD, X20 Pro, X20R, X20RS, X18R, **X18RS** | **X18RS tested on the real radio** (Ethos 26.2.0), the others only in the simulator |
| 640 × 360, no touch | Twin X14, X14S | simulator only |
| 480 × 320, touch | X18, X18S, X18SE, Twin X Lite, Twin X Lite S | simulator only |
| 480 × 272, no touch | X10, X10S, X10 Express, X12S (with Ethos) | simulator only |

Tested on a real X18RS up to 0.4.0: display, sensor search with 48 sensors, compact view, flight list, motor switch SF,
an alarm with the switch armed and off, flight detection, the Lua-Studio settings file (also format 2 with symbols, 10
model changes). Not yet tested on a radio: everything new in 0.5.0, real flights, every single menu item, all radios except the X18RS.
Known problem: after «delete all sensors» in Ethos the fields show 0 until the model is reloaded. Tested with Ethos 26.2 only.
Details (German): [README.de.md](README.de.md).

## Development

Not needed for testers. The Mac tests run with Lua 5.4 from the repo folder, e.g.:

```sh
luac -p src/electric/*.lua
lua test/motoraus-test.lua
lua test/speicher-test.lua
lua test/suche-test.lua src/electric
lua test/format2-test.lua "<folder with the Lua-Studio format 2 test files>"
```

The flows `test/*.json` are meant for a simulator driver based on the Ethos WASM simulator («ethos-tools» plugin); that
driver, the random test and the PDF/package scripts belong to the author's build kit and are not part of this repo.

## Related projects

| Project | What it does |
|---|---|
| [Heli](https://github.com/Raffi1202/heli-lua) | Ethos widget for helicopters with telemetry (any flybarless system) |
| [Jet](https://github.com/Raffi1202/jet-lua) | Ethos widget for turbines (several ECU brands) |
| [Glider](https://github.com/Raffi1202/glider-lua) | Ethos widget for gliders (vario, thermals) |
| [Gas Engine ECU / Carb](https://github.com/Raffi1202/gas-engine-lua) | Ethos widgets for gas engines |
| [Lua-Studio](https://github.com/Raffi1202/lua-studio) | PC app to set up the widgets (Mac/Windows) |

## License

GPL-3.0, see [LICENSE](LICENSE). The module `src/electric/studio_symbole.lua` comes from Lua-Studio (same author, same license).
