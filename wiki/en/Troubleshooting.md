🇬🇧 English · [🇩🇪 Deutsch](../de/Fehlerbehebung.md)

# Troubleshooting

## 9. Troubleshooting

| What you see | Cause | What to do |
|---|---|---|
| Dashes everywhere, flight time 0:00 | No telemetry | Switch the model on. Check that the receiver is bound. |
| «Set cell count» or «Cell count?» | No cell sensor and cell count 0 | Menu › Battery › set Cell count. |
| Battery % is wrong | Wrong capacity or battery type, or pack plugged in under load | Check Menu › Battery. Plug the pack in before giving throttle. |
| No «ARMED / MOTOR OFF» at the top, flights do not count | Motor switch not found | Menu › Switches › «Motor off at»: choose the position, e.g. SF↑. |
| An alarm does not come with the motor off | «Alarm also with motor off» is off for this value (menu or Lua-Studio) | Menu › Alarm also with motor off › switch the value on. |
| RPM far too high | ESC sends electrical RPM | Menu › Battery › «Divide RPM by» = pole pairs of the motor. |
| On alarm only a beep and the number | Voice files missing on the radio (folder audio) | Repeat chapter 2. |
| A single value shows a dash | Sensor not assigned or sends nothing | Menu › Sensors: check the line (chapter 4). |
| THROTTLE shows a dash and «Select throttle» | No throttle channel set | Menu › Flight › Throttle channel (chapter 8). |
| Red text at the bottom left | Script error. The radio keeps working. | Take a photo of the text and report it: on GitHub under Issues, template «Fehler / Bug» (see TESTLEITFADEN.md in the repository). |
| At the bottom «Studio file broken - default», «too new» or «n errors», then «!» at the top right | The Lua-Studio file is broken, made for a newer Elektro version or contains invalid entries | Transfer it again from Lua-Studio or update Elektro. What exactly is wrong is in the log (one line per error). |
| The widget is missing from the list | Not installed or radio not restarted | Repeat chapter 2, restart the radio. |

## 10. Update and remove

**Update:** install the new ZIP exactly as in chapter 2. Your settings, sensors, flights and counters are kept.

**Remove:** first take the widget off the screen (Model › Screens), then uninstall it in FrSky Suite under Lua library.

### Lua memory («too much RAM»)
All Lua scripts on the radio share one Lua memory (about 2048 KB on the X18RS). If Ethos reports «too much RAM» or not enough Lua memory, switch the radio off and on again. From version 0.5.0 Elektro frees its memory when you change to a model without Elektro (about 5 KB stay, measured in the simulator).

---
[← Home](../Home.md) | [Previous](FAQ.md) | [Next →](Changelog.md)
