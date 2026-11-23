-- Electric: Liste aller Einstellungen (für Menü, Werkwerte und Speicher). Wird nur bei Bedarf geladen und wieder
-- freigegeben. Eine Einstellung steht nur hier: Menü, Prüfung und Speichern richten sich nach dieser Liste.
-- Art: q = Quelle (Sensor, Kanal, Schalter), z = Zahl, b = Ja/Nein, w = Auswahl, t = eigener Text.
-- Jeder Text steht in zwei Sprachen: { "deutsch", "english" }. Ein einfacher Text gilt für beide.
-- q: { name, "q", Text }
-- z: { name, "z", Text, Werkwert, min, max, Kommastellen, Einheit, Schritt }. Zahlen mit Kommastellen sind als ganze
--    Zahl gespeichert (Kommastellen 2: 350 bedeutet 3,50).
-- b: { name, "b", Text, Werkwert }
-- w: { name, "w", Text, Werkwert, { { "Text", 1 }, { "Text", 2 } } }
-- t: { name, "t", Text, Werkwert }  (höchstens 12 Zeichen)
-- Grenzwerte: 0 = aus. Die Werkwerte hat der Autor mit dem Konzept freigegeben (19.11.2026).
local M = {}

-- Inhalte der Tachos und Felder (Nummern bleiben für immer gleich, sie stehen in der Datei)
local INHALT = {
  { { "leer", "empty" }, 0 }, { "Akku %", 1 }, { { "Strom", "Current" }, 2 }, { { "Drehzahl", "RPM" }, 3 },
  { { "Reglertemp.", "ESC temp." }, 4 }, { { "Zelle", "Cell" }, 5 }, { { "Gesamtspannung", "Pack voltage" }, 6 },
  { { "Verbraucht", "Used" }, 7 }, { { "Leistung", "Power" }, 8 }, { { "Höhe", "Altitude" }, 9 },
  { "Vario", 10 }, { "Speed", 11 }, { { "Empfang", "Signal" }, 12 }, { "BEC", 13 },
  { { "Flugzeit", "Flight time" }, 14 }, { { "Gas %", "Throttle %" }, 15 },
}
M.INHALT = INHALT

M.gruppen = {
  { { "Sensoren", "Sensors" }, {
    { "uGes", "q", { "Gesamtspannung", "Pack voltage" } },
    { "zellen", "q", { "Zellen (Zellensensor)", "Cells (cell sensor)" } },
    { "strom", "q", { "Strom", "Current" } },
    { "mah", "q", { "Verbraucht (mAh)", "Used (mAh)" } },
    { "proz", "q", { "Akku % (Regler)", "Battery % (ESC)" } },
    { "rpm", "q", { "Drehzahl", "RPM" } },
    { "temp", "q", { "Reglertemperatur", "ESC temperature" } },
    { "bec", "q", { "BEC-Spannung", "BEC voltage" } },
    { "hoehe", "q", { "Höhe", "Altitude" } },
    { "vario", "q", "Vario" },
    { "speed", "q", { "Geschwindigkeit", "Speed" } },
    { "rssi", "q", "RSSI" },
    { "lq", "q", "LQ" },
    { "rssi2", "q", { "RSSI 900 (2. Band)", "RSSI 900 (2nd band)" } },   -- 0.10.0 (Issue #2): zweites Band, Speicher FORMAT 3
    { "vfr", "q", "VFR 2.4" },
    { "vfr2", "q", { "VFR 900 (2. Band)", "VFR 900 (2nd band)" } },
    { "rxvfr", "q", "RX VFR" },
    { "zellen2", "q", { "Zellen 2", "Cells 2" } },                    -- 0.10.0 (Issue #2): zweiter Zellensensor
    { "bec2", "q", { "Empfänger-Akku 2", "Receiver battery 2" } },
  } },
  { { "Akku", "Battery" }, {
    { "akkuart", "w", { "Akkuart", "Battery type" }, 1,
      { { "LiPo", 1 }, { "LiHV", 2 }, { "LiFe", 3 }, { "Li-Ion", 4 }, { "NiMH", 5 } } },
    { "zellenzahl", "z", { "Zellenzahl (0 = auto)", "Cell count (0 = auto)" }, 0, 0, 14, 0, " S" },
    { "z2modus", "w", { "Zellen 2", "Cells 2" }, 1,
      { { { "in Serie", "in series" }, 1 }, { { "eigener Akku", "own battery" }, 2 } } },
    { "zellenzahl2", "z", { "Zellenzahl Akku 2 (0 = Sensor)", "Cell count battery 2 (0 = sensor)" }, 0, 0, 14, 0, " S" },
    { "kapaz", "z", { "Kapazität", "Capacity" }, 4500, 0, 50000, 0, " mAh", 100 },
    { "prozQuelle", "w", { "Akku % kommt von", "Battery % from" }, 1,
      { { { "Regler, sonst gerechnet", "ESC, else calculated" }, 1 }, { { "immer gerechnet", "always calculated" }, 2 } } },
    { "polpaare", "z", { "Drehzahl teilen durch", "Divide RPM by" }, 1, 1, 30, 0 },
  } },
  { { "Grenzwerte (0 = aus)", "Limits (0 = off)" }, {
    { "akkuW", "z", { "Akku % Warnung unter", "Battery % warn below" }, 30, 0, 100, 0, " %" },
    { "akkuA", "z", { "Akku % Alarm unter", "Battery % alarm below" }, 20, 0, 100, 0, " %" },
    { "zelleW", "z", { "Zelle Warnung unter", "Cell warning below" }, 350, 0, 450, 2, " V", 5 },
    { "zelleA", "z", { "Zelle Alarm unter", "Cell alarm below" }, 330, 0, 450, 2, " V", 5 },
    { "diffW", "z", { "Zellendiff. Warnung über", "Cell diff. warn above" }, 10, 0, 100, 2, " V" },
    { "diffA", "z", { "Zellendiff. Alarm über", "Cell diff. alarm above" }, 20, 0, 100, 2, " V" },
    { "tempW", "z", { "Reglertemp. Warnung über", "ESC temp. warn above" }, 70, 0, 200, 0, " °C" },
    { "tempA", "z", { "Reglertemp. Alarm über", "ESC temp. alarm above" }, 85, 0, 200, 0, " °C" },
    { "stromW", "z", { "Strom Warnung über", "Current warn above" }, 80, 0, 999, 0, " A" },
    { "stromA", "z", { "Strom Alarm über", "Current alarm above" }, 100, 0, 999, 0, " A" },
    { "kapW", "z", { "Verbraucht Warnung über", "Used warn above" }, 70, 0, 100, 0, " %" },
    { "kapA", "z", { "Verbraucht Alarm über", "Used alarm above" }, 80, 0, 100, 0, " %" },
    { "becW", "z", { "BEC Warnung unter", "BEC warning below" }, 0, 0, 200, 1, " V" },
    { "becA", "z", { "BEC Alarm unter", "BEC alarm below" }, 0, 0, 200, 1, " V" },
    { "hoeheW", "z", { "Höhe Warnung über", "Altitude warn above" }, 110, 0, 5000, 0, " m" },
    { "hoeheA", "z", { "Höhe Alarm über", "Altitude alarm above" }, 120, 0, 5000, 0, " m" },
    { "rssiW", "z", { "RSSI Warnung unter", "RSSI warning below" }, 45, 0, 120, 0, " dB" },
    { "rssiA", "z", { "RSSI Alarm unter", "RSSI alarm below" }, 40, 0, 120, 0, " dB" },
    { "lqW", "z", { "LQ Warnung unter", "LQ warning below" }, 70, 0, 100, 0, " %" },
    { "lqA", "z", { "LQ Alarm unter", "LQ alarm below" }, 50, 0, 100, 0, " %" },
    { "vfrW", "z", { "VFR Warnung unter (je Band)", "VFR warning below (per band)" }, 70, 0, 100, 0, " %" },
    { "vfrA", "z", { "RX VFR Alarm unter", "RX VFR alarm below" }, 50, 0, 100, 0, " %" },
  } },
  -- Je Grenzwert-Alarm: kommt er auch, wenn der Schalter «Motor aus bei» aktiv ist? Standard ja (Regel «Alarme trotz
  -- Motor-aus-Schalter», Ergänzung 21.11.2026). Aus = dieser Alarm schweigt nur, solange der Motor aus ist.
  { { "Alarm auch bei Motor aus", "Alarm also with motor off" }, {
    { "akkuMot", "b", "Akku %", true },
    { "zelleMot", "b", { "Zelle", "Cell" }, true },
    { "diffMot", "b", { "Zellendifferenz", "Cell difference" }, true },
    { "tempMot", "b", { "Reglertemperatur", "ESC temperature" }, true },
    { "stromMot", "b", { "Strom", "Current" }, true },
    { "kapMot", "b", { "Verbraucht %", "Used %" }, true },
    { "becMot", "b", "BEC", true },
    { "hoeheMot", "b", { "Höhe", "Altitude" }, true },
    { "rssiMot", "b", "RSSI", true },
    { "lqMot", "b", "LQ", true },
  } },
  { { "Schalter", "Switches" }, {
    { "swMotor", "q", { "Motor aus bei", "Motor off at" } },
    { "swAnsage", "q", { "Ansage bei", "Announce at" } },
    { "sw1", "q", { "Schalter 1", "Switch 1" } },
    { "sw1Name", "t", { "Schalter 1 Name", "Switch 1 name" }, "SCHALTER 1" },
    { "sw2", "q", { "Schalter 2", "Switch 2" } },
    { "sw2Name", "t", { "Schalter 2 Name", "Switch 2 name" }, "SCHALTER 2" },
  } },
  { { "Flug", "Flight" }, {
    { "erkennung", "w", { "Flug erkennen über", "Detect flight by" }, 1,
      { { { "Motorschalter", "Motor switch" }, 1 }, { { "Strom oder Gas", "Current or throttle" }, 2 } } },
    { "gas", "q", { "Gaskanal", "Throttle channel" } },
    { "flugStrom", "z", { "Flug ab Strom", "Flight from current" }, 3, 1, 200, 0, " A" },
    { "gasSchwelle", "z", { "Flug ab Gas", "Flight from throttle" }, 10, 1, 100, 0, " %" },
    { "pauseS", "z", { "Pause nach", "Pause after" }, 20, 5, 300, 0, " s", 5 },
    { "flugMin", "z", { "Flug zählt ab", "Flight counts from" }, 30, 0, 600, 0, " s", 5 },
    { "akkuEnde", "b", { "Akkuwechsel beendet Flug", "Battery change ends flight" }, true },
  } },
  { { "Ansagen", "Announcements" }, {
    { "ansage", "b", { "Alarme ansagen", "Announce alarms" }, true },
    { "warnAnsage", "b", { "Warnung auch ansagen", "Announce warnings too" }, false },
    { "wdh", "z", { "Alarm wiederholen alle", "Repeat alarm every" }, 10, 3, 300, 0, " s" },
    { "schritt", "w", { "Akku % ansagen alle", "Announce battery % every" }, 10,
      { { { "aus", "off" }, 0 }, { "5 %", 5 }, { "10 %", 10 }, { "20 %", 20 } } },
    { "motorAus", "b", { "«Motor aus» ansagen", "Announce «motor off»" }, true },
    { "sgProz", "b", { "Ansage: Akku %", "Announce: battery %" }, true },
    { "sgZeit", "b", { "Ansage: Flugzeit", "Announce: flight time" }, true },
    { "sgHoehe", "b", { "Ansage: Höhe", "Announce: altitude" }, false },
    { "sgMah", "b", { "Ansage: Verbraucht", "Announce: used" }, false },
    { "ton", "b", { "Ton bei Alarm", "Tone on alarm" }, true },
    { "vibration", "b", { "Vibration bei Alarm", "Vibration on alarm" }, false },
  } },
  { { "Felder", "Fields" }, {
    { "t1", "w", { "Tacho 1", "Gauge 1" }, 1, INHALT },
    { "t2", "w", { "Tacho 2", "Gauge 2" }, 2, INHALT },
    { "t3", "w", { "Tacho 3", "Gauge 3" }, 3, INHALT },
    { "t4", "w", { "Tacho 4", "Gauge 4" }, 4, INHALT },
    { "f1", "w", { "Feld 1", "Field 1" }, 5, INHALT },
    { "f2", "w", { "Feld 2", "Field 2" }, 7, INHALT },
    { "f3", "w", { "Feld 3", "Field 3" }, 8, INHALT },
    { "f4", "w", { "Feld 4", "Field 4" }, 9, INHALT },
    { "f5", "w", { "Feld 5", "Field 5" }, 11, INHALT },
    { "f6", "w", { "Feld 6", "Field 6" }, 12, INHALT },
    { "fGross", "w", { "Grosses Feld (links)", "Large field (left)" }, 15, INHALT },
    { "maxStrom", "z", { "Tacho Strom bis", "Current gauge up to" }, 120, 10, 999, 0, " A" },
    { "maxRpm", "z", { "Tacho Drehzahl bis", "RPM gauge up to" }, 12000, 1000, 99000, 0, "", 500 },
    { "maxTemp", "z", { "Tacho Temp. bis", "Temp. gauge up to" }, 100, 30, 200, 0, " °C" },
  } },
  { { "Anzeige", "Display" }, {
    { "sprache", "w", "Sprache / Language", 0,
      { { { "wie der Sender", "as the radio" }, 0 }, { "Deutsch", 1 }, { "English", 2 } } },
    { "phase", "b", { "Flugphase anzeigen", "Show flight mode" }, true },   -- 0.10.0 (Issue #1), Datendatei
  } },
}

-- Werkwerte der Zellen-Schwellen je Akkuart (Warnung, Alarm in 1/100 V)
M.ZELLE_WERK = { { 350, 330 }, { 350, 330 }, { 300, 280 }, { 320, 300 }, { 110, 100 } }

-- Text in der Sprache sp (1 = Deutsch, 2 = English).
function M.text(t, sp)
  if type(t) == "table" then return t[sp] or t[1] end
  return t
end

-- Eigener Text (Schalternamen): nur Buchstaben, Ziffern, Leerzeichen, Punkt, Bindestrich, Umlaute; höchstens
-- 12 Zeichen. Sonst nil.
function M.eigen(v)
  if type(v) ~= "string" then return nil end
  v = v:gsub("[^%w %.%-\195\164\195\182\195\188\195\132\195\150\195\156]", ""):gsub("^%s+", ""):gsub("%s+$", "")
  if #v > 24 then v = v:sub(1, 24) end
  while #v > 0 and #v > 12 do
    v = v:sub(1, #v - 1)
    while #v > 0 and v:byte(#v) >= 128 and v:byte(#v) < 192 do v = v:sub(1, #v - 1) end   -- kein halbes Zeichen
    if #v > 0 and v:byte(#v) >= 192 then v = v:sub(1, #v - 1) end
  end
  if v == "" then return nil end
  return v
end

-- Reihenfolge im Speicher. Ethos speichert Quellen nach Reihenfolge, nicht nach Namen:
-- neue Einstellungen kommen immer ANS ENDE dieser Liste, nie dazwischen. Jede Einstellung aus M.gruppen steht hier.
M.folge = {
  "uGes", "zellen", "strom", "mah", "proz", "rpm", "temp", "bec", "hoehe", "vario", "speed", "rssi", "lq",
  "swMotor", "swAnsage", "sw1", "sw2", "gas",
  "akkuart", "zellenzahl", "kapaz", "prozQuelle", "polpaare",
  "akkuW", "akkuA", "zelleW", "zelleA", "diffW", "diffA", "tempW", "tempA", "stromW", "stromA", "kapW", "kapA",
  "becW", "becA", "hoeheW", "hoeheA", "rssiW", "rssiA", "lqW", "lqA",
  "sw1Name", "sw2Name",
  "erkennung", "flugStrom", "gasSchwelle", "pauseS", "flugMin", "akkuEnde",
  "ansage", "warnAnsage", "wdh", "schritt", "motorAus", "sgProz", "sgZeit", "sgHoehe", "sgMah", "ton", "vibration",
  "t1", "t2", "t3", "t4", "f1", "f2", "f3", "f4", "f5", "f6", "maxStrom", "maxRpm", "maxTemp",
  "sprache", "fGross",
  "akkuMot", "zelleMot", "diffMot", "tempMot", "stromMot", "kapMot", "becMot", "hoeheMot", "rssiMot", "lqMot", "phase",
  "rssi2", "vfr", "vfr2", "rxvfr", "vfrW", "vfrA",   -- 0.10.0: Quellen ans Ende (FORMAT 3), Schwellen in der Datendatei
  "zellen2", "bec2", "z2modus", "zellenzahl2",
}

-- Speicherformat der Quellen im Widget-Speicher: Nummer -> Zahl der Quellen in diesem Format.
-- Kommt eine Quelle dazu: ans Ende von M.folge, FORMAT um eins erhöhen und hier eine Zeile anfügen. Alte Formate
-- bleiben stehen, damit ein Update die Zuweisungen behält (Lehre Motoren ECU 1.2.0, 19.11.2026).
-- 0.5.0: die 10 Einstellungen «Alarm auch bei Motor aus» (akkuMot … lqMot) sind Ja/Nein-Werte. Sie stehen mit Namen
-- in der Datei daten/<Modell>.txt (bzw. mit Studio-Datei in der .funke.lua), nicht im Widget-Speicher: FORMAT bleibt 1.
-- 0.7.0: FORMAT 2 = Format 1 und danach am Ende die Wahl «Studio-Layout» (Text: Pfad der Datei, "" = automatisch).
-- Ein Speicher in Format 1 (bis 0.6.1) wird weiter gelesen, die Wahl steht dann auf automatisch.
-- 0.10.0: FORMAT 3 = 24 Quellen (dazu rssi2, vfr, vfr2, rxvfr am Ende), danach die Wahl «Studio-Layout» wie FORMAT 2.
M.FORMAT = 3
M.FORMATE = { [1] = 18, [2] = 18, [3] = 24 }   -- FORMAT 3: dazu rssi2, vfr, vfr2, rxvfr, zellen2, bec2

-- Feld zu einem Namen (Verzeichnis einmal aufbauen: Ethos begrenzt die Befehle je Aufruf).
local INDEX = nil
function M.feld(name)
  if INDEX == nil then
    INDEX = {}
    for _, g in ipairs(M.gruppen) do
      for _, f in ipairs(g[2]) do INDEX[f[1]] = f end
    end
  end
  return INDEX[name]
end

-- Darf das Studio diese Einstellung setzen? (Lua-Studio-Format v1, studio/beschreibung.json): keine Quellen, keine
-- Grenzwerte (die kommen über «grenzen»), keine Belegung der Tachos und Felder (die kommt über «ansichten»).
local STUDIO_GRUPPE = nil
function M.studioEinstellung(name)
  if STUDIO_GRUPPE == nil then
    STUDIO_GRUPPE = {}
    for gi, g in ipairs(M.gruppen) do
      local gname = type(g[1]) == "table" and g[1][1] or g[1]
      -- «Alarm auch bei Motor aus» kommt wie die Grenzwerte über «grenzen» (Feld beiMotorAus), nicht über «einstellungen»
      if gname ~= "Sensoren" and gname ~= "Felder" and gname:sub(1, 10) ~= "Grenzwerte" and gname:sub(1, 5) ~= "Alarm" then
        for _, f in ipairs(g[2]) do
          if f[2] ~= "q" then STUDIO_GRUPPE[f[1]] = true end
        end
      end
    end
  end
  return STUDIO_GRUPPE[name] == true
end

function M.standard()
  local c = {}
  for _, g in ipairs(M.gruppen) do
    for _, f in ipairs(g[2]) do
      if f[2] ~= "q" then c[f[1]] = f[4] end
    end
  end
  return c
end

local function istQuelle(v)
  local t = type(v)
  if not (t == "userdata" or (t == "table" and type(v.value) == "function")) then return false end
  if CATEGORY_NONE then
    local ok, k = pcall(v.category, v)
    if ok and k == CATEGORY_NONE then return false end
  end
  return true
end
M.istQuelle = istQuelle

-- Gespeicherten Wert prüfen; passt er nicht, gilt der Wert ab Werk.
local function pruefe(f, v)
  local art = f[2]
  if art == "q" then
    if istQuelle(v) then return v end
    return nil
  elseif art == "b" then
    if type(v) == "boolean" then return v end
  elseif art == "z" then
    if type(v) == "number" and v == v and v >= f[5] and v <= f[6] then return math.floor(v) end
  elseif art == "t" then
    return M.eigen(v) or f[4]
  elseif art == "w" then
    if type(v) == "number" then
      for _, a in ipairs(f[5]) do
        if a[2] == v then return v end
      end
    end
  end
  return f[4]
end
M.pruefe = pruefe

local function quellen()
  local r = {}
  for _, name in ipairs(M.folge) do
    local f = M.feld(name)
    if f and f[2] == "q" then r[#r + 1] = name end
  end
  return r
end
M.quellen = quellen

-- Dateiname zum aktuellen Modell (Ordner und Name, nur Buchstaben, Ziffern, _ und -).
function M.datei()
  local ok, p = pcall(model.path)
  if not ok or type(p) ~= "string" or p == "" then
    local ok2, n = pcall(model.name)
    p = (ok2 and type(n) == "string" and n ~= "") and n or "modell"
  end
  p = p:gsub("%.bin$", ""):gsub("[^%w%-]", "_")
  return "daten/" .. p .. ".txt"
end

-- Datei ganz lesen (Ethos liest nur in Stücken), höchstens 12 KB.
local function liesDatei(pfad)
  local ok, f = pcall(io.open, pfad, "r")
  if not ok or not f then return nil end
  local teile, n = {}, 0
  while n < 12288 do
    local ok2, s = pcall(f.read, f, 512)
    if not ok2 or type(s) ~= "string" or s == "" then break end
    teile[#teile + 1] = s
    n = n + #s
  end
  pcall(f.close, f)
  return table.concat(teile)
end

-- Flug als Zeile: Nr, Dauer s, mAh, Wh, max. Strom, max. Leistung, max. Reglertemp., tiefste Zelle, max. Höhe,
-- max. Speed, Akku % am Ende. Fehlende Werte bleiben leer.
M.FLUG_N = 11
local FORM = { "%.0f", "%.0f", "%.0f", "%.1f", "%.0f", "%.0f", "%.0f", "%.2f", "%.0f", "%.0f", "%.0f" }
local MAX_FLUEGE = 20
M.MAX_FLUEGE = MAX_FLUEGE

local function zeile(r)
  local e = {}
  for i = 1, M.FLUG_N do
    local x = r[i]
    e[i] = (type(x) == "number" and x == x and x > -1e7 and x < 1e7) and string.format(FORM[i], x) or ""
  end
  return table.concat(e, ",")
end

local function flug(d)
  local r, i = {}, 0
  for teil in (d .. ","):gmatch("([^,]*),") do
    i = i + 1
    if i <= M.FLUG_N then
      local x = tonumber(teil)
      if x and x == x and x > -1e7 and x < 1e7 then r[i] = x end
    end
  end
  if r[1] and r[1] >= 1 then
    r[1] = math.floor(r[1])
    return r
  end
  return nil
end

-- Einstellungen lesen. Gibt true zurück, wenn schon etwas gespeichert war (sonst läuft die automatische Suche).
function M.lies(w)
  local c = M.standard()
  w.cfg = c
  w.lay = ""                                       -- Studio-Layout: automatisch (Modellname)
  local gefunden = false
  -- Quellen aus dem Widget-Speicher, in jedem bekannten Format
  if storage and storage.read then
    local function hol(name)
      local ok, v = pcall(storage.read, name)
      if ok then return v end
      return nil
    end
    local q = quellen()
    local fmt = hol("fmt")
    local anz = type(fmt) == "number" and M.FORMATE[fmt] or nil
    if anz then
      local werte = {}
      for i = 1, anz do werte[i] = hol("q" .. i) end
      local lay = fmt >= 2 and hol("lay") or nil     -- Ethos liest nach Reihenfolge: vor «ende»
      if hol("ende") == fmt then
        gefunden = true
        for i, name in ipairs(q) do
          if i <= anz then c[name] = istQuelle(werte[i]) and werte[i] or nil end
        end
        if fmt >= 2 then w.lay = type(lay) == "string" and lay or "" end
      else
        print(tostring(w.name) .. ": gespeicherte Sensoren unlesbar, bitte neu zuweisen")
      end
    end
  end
  -- Zahlen, dauerhafte Werte und Flüge aus der Datei
  local text = liesDatei(M.datei())
  w.datenAlt = nil
  if not text then                                 -- Umbenennung 0.6.0: Datei noch im alten Ordner (Elektro), nur lesen
    text = liesDatei("SCRIPTS:/elektro/" .. M.datei())
    if text then
      w.datenAlt = true
      print(tostring(w.name) .. ": settings taken over from scripts/elektro/" .. M.datei())
    end
  end
  w.dauer, w.liste, w.offen = {}, {}, nil
  if text then
    gefunden = true
    local alt7, altBild, neuGross = nil, nil, false     -- Datei bis 0.1.6: Feld 7 statt des Fliegerbilds
    for z in text:gmatch("[^\r\n]+") do
      local k, v = z:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
      if k == "f7" then alt7 = tonumber(v) elseif k == "bild" then altBild = v elseif k == "fGross" then neuGross = true end
      if k == "f" then
        local r = flug(v)
        if r and #w.liste < MAX_FLUEGE then w.liste[#w.liste + 1] = r end
      elseif k == "a" then
        w.offen = flug(v)
      elseif k and k:sub(1, 2) == "d_" then
        local x = tonumber(v)
        if x and x == x and x > -1e7 and x < 1e7 then w.dauer[k:sub(3)] = x end
      elseif k then
        local f = M.feld(k)
        if f and f[2] == "b" then
          c[k] = pruefe(f, v == "1")
        elseif f and f[2] == "t" then
          c[k] = pruefe(f, v)
        elseif f and (f[2] == "z" or f[2] == "w") then
          c[k] = pruefe(f, tonumber(v))
        end
      end
    end
    -- Update von 0.1.x: Wer das Fliegerbild aus hatte, sah dort Feld 7. Dieser Inhalt kommt ins grosse Feld.
    if not neuGross and altBild == "0" and alt7 then
      local f = M.feld("fGross")
      if f then c.fGross = pruefe(f, alt7) end
    end
  end
  return gefunden
end

-- Quellen in den Widget-Speicher (Ethos ruft das beim Speichern des Modells auf).
function M.schreibe(w)
  if not (storage and storage.write) then return end
  local c = w.cfg
  local q = quellen()
  pcall(storage.write, "fmt", M.FORMAT)
  for i, name in ipairs(q) do
    local v = c[name]
    pcall(storage.write, "q" .. i, istQuelle(v) and v or 0)
  end
  pcall(storage.write, "lay", type(w.lay) == "string" and w.lay or "")
  pcall(storage.write, "ende", M.FORMAT)
end

-- Zahlen, dauerhafte Werte und Flüge in die Datei. Gibt true zurück, wenn geschrieben.
function M.schreibeDatei(w)
  local c = w.cfg
  local z = { "# " .. tostring(w.name) .. ": Einstellungen, Zähler und Flüge dieses Modells" }
  for _, name in ipairs(M.folge) do
    local f = M.feld(name)
    local v = c[name]
    if f and f[2] == "b" then
      z[#z + 1] = name .. "=" .. (v and "1" or "0")
    elseif f and f[2] == "t" then
      local e = M.eigen(v)
      if e then z[#z + 1] = name .. "=" .. e end
    elseif f and f[2] ~= "q" and type(v) == "number" then
      z[#z + 1] = name .. "=" .. string.format("%d", math.floor(v))
    end
  end
  local namen = {}
  for k, x in pairs(w.dauer or {}) do
    if type(k) == "string" and type(x) == "number" and x == x then namen[#namen + 1] = k end
  end
  table.sort(namen)
  for _, k in ipairs(namen) do z[#z + 1] = "d_" .. k .. "=" .. string.format("%.2f", w.dauer[k]) end
  for _, r in ipairs(w.liste or {}) do z[#z + 1] = "f=" .. zeile(r) end
  if w.akt and w.akt[1] then z[#z + 1] = "a=" .. zeile(w.akt) end      -- offener Flug geht beim Ausschalten nicht verloren
  if os and os.mkdir then pcall(os.mkdir, "daten") end
  local ok, f = pcall(io.open, M.datei(), "w")
  if not ok or not f then return false end
  local okw = pcall(f.write, f, table.concat(z, "\n") .. "\n")
  pcall(f.close, f)
  return okw
end

return M
