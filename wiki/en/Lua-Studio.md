🇬🇧 English · [🇩🇪 Deutsch](../de/Lua-Studio.md)

# Lua-Studio

### Settings file from Lua-Studio

With the PC program **Lua-Studio** you design the display freely for each model: for every box you choose the value, the display type (number, gauge, horizontal or vertical bar, graph, status), title, range, colours and an extra line (MIN, MAX or Ø over the flight). Settings and limits per model come with it. Lua-Studio writes the file `scripts/studio/modelname.electric.lua` to the SD card. In the file name, only the letters A–Z and digits of the model name are kept, everything else becomes `_` («Möwe 2» becomes `M__we_2`); Lua-Studio does this itself. Electric reads it when the model is loaded.

- **Without this file** Electric works exactly as before, without any message.

- **Where and which file (from 0.7.0):** Electric looks for the file in `scripts/studio` in the set script location, then on the SD card, then in the internal memory. If the file name does not match the model name, choose the file in the widget menu under **Studio layout** (the list shows every file with its location; «automatic (model name)» is the previous way). The choice in the menu wins over the model name.

- **With the file** its layout applies to the window size it was made for. If there is no layout for this size, Electric 0.7.0 adapts the layout with the most similar aspect ratio and shows «Studio: view 800x480 adapted» in the header for 5 s. Boxes that get too small are shown as a number or left out. If the built-in display stays although there is a file, the header gives the reason, e.g. «Studio: file broken (…)» or «Studio: no matching view».

- **After a model change** Electric reads the file in small steps, which can take a moment. If the file has a layout for this window size, it shows «Loading Studio file ...» meanwhile instead of the built-in display; otherwise Electric shows its built-in display right away.

- **Decoration (lines, frames, texts; from version 0.4.0, Lua-Studio format 2):** freely placed texts, lines and frames under the boxes. Symbols are removed from version 0.8.0: Electric silently skips symbols and bold units in older files, the unit is shown small next to the value. Decoration never changes a limit or an alarm.

- **Limits** apply per value, whether and however it is shown. If a value is missing in the file, the factory limit applies. An alarm is only switched off if the file says so explicitly. If an entry does not fit the value (e.g. wrong direction), the factory limit applies as well, with a message. «Also with motor off» can be set per limit in Lua-Studio too (from version 0.5.0, also for sensors and channels). The radio menu only lists Electric's own 10 values; limits for sensors and channels from the file are set in Lua-Studio.

- **If you change** battery, limits or other settings in the menu on the radio, Electric writes this to its own file `…electric.funke.lua`. The Lua-Studio file stays unchanged. Lua-Studio shows the differences and takes them over on request.

- **Menu › Studio file › Reset:** with a file «Back to Studio settings» (your changes on the radio are deleted), without a file «Back to defaults» (factory settings and limits; sensors and flights stay). Both ask first.

- **Messages:** if the file is broken, too new or contains invalid entries, a band at the bottom shows it for 8 seconds (e.g. «Studio file broken - default»), then an orange «!» stays at the top right. Electric always keeps running, if in doubt with the built-in display.

- Electric also writes `…electric.info.json` with model name, radio and sensor list. Only Lua-Studio reads it.

---
[← Home](../Home.md) | [Previous](Alarms.md) | [Next →](FAQ.md)
