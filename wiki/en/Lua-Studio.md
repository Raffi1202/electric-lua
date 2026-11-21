🇬🇧 English · [🇩🇪 Deutsch](../de/Lua-Studio.md)

# Lua-Studio

### Settings file from Lua-Studio

With the PC program **Lua-Studio** you design the display freely for each model: for every box you choose the value, the display type (number, gauge, horizontal or vertical bar, graph, status), title, range, colours and an extra line (MIN, MAX or Ø over the flight). Settings and limits per model come with it. Lua-Studio writes the file `scripts/studio/modelname.electric.lua` to the SD card. In the file name, only the letters A–Z and digits of the model name are kept, everything else becomes `_` («Möwe 2» becomes `M__we_2`); Lua-Studio does this itself. Electric reads it when the model is loaded.

- **Without this file** Electric works exactly as before, without any message.

- **With the file** its layout applies only to the window size it was made for (e.g. full screen 800 × 480 or with bars 784 × 316). For other sizes Electric draws its built-in display.

- **After a model change** Electric reads the file in small steps, which can take a moment. If the file has a layout for this window size, it shows «Loading Studio file ...» meanwhile instead of the built-in display; otherwise Electric shows its built-in display right away.

- **Symbols, bold unit and decoration** (from version 0.4.0, Lua-Studio 0.3.0 or newer): a box can show a symbol at the top left (e.g. battery, clock, altitude) and the unit in bold. Freely placed symbols, texts, lines and frames can sit under the boxes. Lua-Studio writes the images to `scripts/studio/symbole/`. If an image is missing or broken, Electric shows the box without the symbol and briefly «Studio: n symbols missing» at the bottom. Symbols and decoration never change a limit or an alarm.

- **Limits** apply per value, whether and however it is shown. If a value is missing in the file, the factory limit applies. An alarm is only switched off if the file says so explicitly. If an entry does not fit the value (e.g. wrong direction), the factory limit applies as well, with a message. «Also with motor off» can be set per limit in Lua-Studio too (from version 0.5.0, also for sensors and channels). The radio menu only lists Electric's own 10 values; limits for sensors and channels from the file are set in Lua-Studio.

- **If you change** battery, limits or other settings in the menu on the radio, Electric writes this to its own file `…electric.funke.lua`. The Lua-Studio file stays unchanged. Lua-Studio shows the differences and takes them over on request.

- **Menu › Studio file › Reset:** with a file «Back to Studio settings» (your changes on the radio are deleted), without a file «Back to defaults» (factory settings and limits; sensors and flights stay). Both ask first.

- **Messages:** if the file is broken, too new or contains invalid entries, a band at the bottom shows it for 8 seconds (e.g. «Studio file broken - default»), then an orange «!» stays at the top right. Electric always keeps running, if in doubt with the built-in display.

- Electric also writes `…electric.info.json` with model name, radio and sensor list. Only Lua-Studio reads it.

---
[← Home](../Home.md) | [Previous](Alarms.md) | [Next →](FAQ.md)
