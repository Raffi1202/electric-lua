-- Electric: «Alarm auch bei Motor aus» je Grenzwert (Lua-Studio-Format 2, Abschnitt 3.5, Auftrag 21.11.2026).
-- Aufruf aus dem Repo-Ordner:  /opt/homebrew/opt/lua@5.4/bin/lua test/motoraus-test.lua
-- Läuft in einer Kopie von src/electric in einem temporären Ordner (das Skript schreibt daten/ und SCRIPTS:/studio).
--  a) Menü, Standard EIN: Alarm kommt auch bei Motor aus (Pflichtregel «Alarme trotz Motor-aus-Schalter»).
--  b) Menü AUS, Motor aus: Alarm schweigt (kein Ton, keine Meldung), die Farbe zeigt den Wert weiter.
--  c) Menü AUS, Motor ein: Alarm kommt.  d) laufender Alarm schweigt sofort, wenn der Motor ausgeht.
--  e) Studio-Datei «beiMotorAus = false» für einen überwachten Wert.  f) für eine Sensor-Grenze.
--  g) .funke.lua «beiMotorAus = true» hebt das false der Studio-Datei auf; Menüänderung landet in .funke.lua.
--  h) falscher Typ zählt als true, mit Fehler.  i) ohne Motorschalter schweigt nie etwas.
local quelle = arg[0]:gsub("test/motoraus%-test%.lua$", "") .. "src/electric"
local tmp = os.tmpname()
os.remove(tmp)
assert(os.execute("mkdir -p '" .. tmp .. "/daten' '" .. tmp .. "/SCRIPTS:/studio' && cp '" .. quelle .. "'/*.lua '" .. tmp .. "/'"))

local fehler = 0
local function pruefe(ok, text)
  print((ok and "ok     " or "FEHLER ") .. text)
  if not ok then fehler = fehler + 1 end
end

-- nachgebildete Ethos-Umgebung (wie test/neustart-test.lua)
local T = 0
os.clock = function() return T end
local werte = {}
local function Q(name)
  return { value = function() return werte[name] end, name = function() return name end,
    minimum = function() return -1024 end, maximum = function() return 1024 end, decimals = function() return 0 end,
    category = function() return 1 end }
end
local toene, ansagen, vibs = 0, 0, 0
system = { getVersion = function() return { simulation = false, board = "X18RS", version = "26.2.0" } end,
  playFile = function() ansagen = ansagen + 1 end, playNumber = function() ansagen = ansagen + 1 end,
  playHaptic = function() vibs = vibs + 1 end, playTone = function() toene = toene + 1 end,
  getSource = function() return nil end }
model = { name = function() return "TEST" end, path = function() return "models/test.bin" end, dirty = function() end }
lcd = { isVisible = function() return false end, invalidate = function() end }
storage = { read = function() return nil end, write = function() end }
UNIT_PERCENT, UNIT_VOLT, UNIT_MILLIAMPERE_HOUR = 1, 2, 3
CATEGORY_SWITCH_POSITION = 7

local alt = io.open
local ordner = tmp .. "/"
io.open = function(p, m) return alt((p:sub(1, 1) == "/" and "" or ordner) .. p, m) end
local laden = loadfile
loadfile = function(p) return laden((p:sub(1, 1) == "/" and "" or ordner) .. p) end
local os_remove, os_rename = os.remove, os.rename
os.remove = function(p) return os_remove((p:sub(1, 1) == "/" and "" or ordner) .. p) end
os.rename = function(a, b) return os_rename(ordner .. a, ordner .. b) end
local function esc(t) return '"' .. t:gsub(".", function(c) return "\\" .. c:byte() end) .. '"' end
local STUDIO = "SCRIPTS:/studio/TEST.electric.lua"
local FUNKE = "SCRIPTS:/studio/TEST.electric.funke.lua"
local function schreib(p, t) local f = assert(io.open(p, "w")) f:write(t) f:close() end

-- Motorschalter SF: state() = true heisst «Motor aus» aktiv
local motorAus = false
local sf = { name = function() return "SF↑" end, value = function() return 0 end, minimum = function() return -1024 end,
  maximum = function() return 1024 end, category = function() return 7 end, state = function() return motorAus end }

local K, w
local function start(mitSchalter)
  os.execute("rm -f '" .. tmp .. "/daten/'*")
  K = assert(loadfile("kern.lua"))()
  w = K.neu()
  K.lies(w)
  w.cfg.temp, w.cfg.erkennung = Q("t"), 1
  w.cfg.swMotor = mitSchalter ~= false and sf or nil
  werte.t = 40
end
local function lauf(s) for _ = 1, math.floor(s * 5) do T = T + 0.2 K.wecke(w) end end
local function alarmAn() local m = w.meld.tempA return m ~= nil and m.an == true end

-- a) Standard: Haken EIN, Motor aus -> Alarm kommt
start()
pruefe(w.cfg.tempMot == true and w.cfg.akkuMot == true and w.cfg.lqMot == true, "a) Standard ab Werk: «auch bei Motor aus» EIN")
motorAus = true
lauf(2)
toene, werte.t = 0, 95
lauf(15)
pruefe(w.v.motorAus == true and alarmAn() and toene >= 1, "a) Haken EIN, Motor aus: Alarm kommt (" .. toene .. " Töne)")

-- b) Haken AUS, Motor aus -> still, Farbe bleibt rot
start()
w.cfg.tempMot = false
motorAus = true
lauf(2)
toene, ansagen, vibs, werte.t = 0, 0, 0, 95
w.cfg.ansage, w.cfg.vibration = true, true
lauf(15)
pruefe(not alarmAn() and toene == 0 and ansagen == 0 and vibs == 0 and w.zustand ~= "alarm",
  "b) Haken AUS, Motor aus: Alarm schweigt (" .. toene .. " Töne, " .. ansagen .. " Ansagen, " .. vibs .. " Vibrationen, Zustand " .. tostring(w.zustand) .. ")")
pruefe(w.st.temp == 2, "b) Farbe des Werts zeigt weiter die Alarmstufe (st = " .. tostring(w.st.temp) .. ")")
-- c) Haken AUS, Motor ein -> Alarm kommt
motorAus = false
toene = 0
lauf(15)
pruefe(alarmAn() and toene >= 1, "c) Haken AUS, Motor ein: Alarm kommt (" .. toene .. " Töne)")
-- d) laufender Alarm schweigt sofort, wenn der Motor ausgeht (ohne die 3 s Entprellung)
motorAus = true
lauf(0.4)
toene, ansagen, vibs = 0, 0, 0
lauf(15)
pruefe(not alarmAn() and toene == 0 and ansagen == 0 and vibs == 0,
  "d) laufender Alarm schweigt sofort bei Motor aus (" .. toene .. " Töne, " .. ansagen .. " Ansagen, " .. vibs .. " Vibrationen)")

-- i) ohne Motorschalter schweigt nie etwas, auch mit Haken AUS
start(false)
w.cfg.tempMot = false
lauf(2)
toene, werte.t = 0, 95
lauf(15)
pruefe(w.v.motorAus == nil and alarmAn() and toene >= 1, "i) ohne Motorschalter: Alarm kommt trotz Haken AUS")

-- e) Studio-Datei: überwachter Wert mit beiMotorAus = false
schreib(STUDIO, "return { format = 1, grenzen = { [" .. esc("lua:reglertemp") .. "] = { richtung = " .. esc("ueber")
  .. ", warnung = 70, alarm = 85, beiMotorAus = false }, [" .. esc("lua:strom") .. "] = { richtung = " .. esc("ueber")
  .. ", alarm = 90, beiMotorAus = " .. esc("ja") .. " } } }")
start()
motorAus = true
lauf(15)                                                   -- Studio-Datei laden
pruefe(w.studioZustand == "geladen" and w.cfg.tempMot == false and w.studio.motBasis.temp == false,
  "e) Studio-Datei geladen: Reglertemp. «auch bei Motor aus» = AUS")
pruefe(w.cfg.akkuMot == true and w.cfg.stromMot == true, "e) fehlender Schlüssel = EIN")
-- h) falscher Typ: true plus Fehler
pruefe((w.studio.fehler or 0) >= 1, "h) beiMotorAus = \"ja\": zählt als true, Fehler gezählt (" .. tostring(w.studio.fehler) .. ")")
toene, werte.t = 0, 95
lauf(15)
pruefe(not alarmAn() and toene == 0, "e) Studio AUS, Motor aus: Alarm schweigt (" .. toene .. " Töne)")
motorAus = false
lauf(15)
pruefe(alarmAn() and toene >= 1, "e) Studio AUS, Motor ein: Alarm kommt (" .. toene .. " Töne)")

-- g) Menüänderung mit Studio-Datei: geht nach .funke.lua; beim nächsten Laden hebt true das false auf
w.cfg.tempMot = true
w.funkeOffen = true
lauf(3)
local f = io.open(FUNKE, "r")
local text = f and f:read("a") or ""
if f then f:close() end
pruefe(text:find("beiMotorAus = true", 1, true) ~= nil, "g) .funke.lua enthält «beiMotorAus = true»")
start()
motorAus = true
lauf(15)
pruefe(w.studioZustand == "geladen" and w.cfg.tempMot == true and w.studio.motBasis.temp == false,
  "g) .funke.lua true über Studio false: Haken EIN, Basis bleibt AUS")
toene, werte.t = 0, 95
lauf(15)
pruefe(alarmAn() and toene >= 1, "g) Haken wieder EIN, Motor aus: Alarm kommt")
os.remove(FUNKE)

-- f) Sensor-Grenze der Studio-Datei mit beiMotorAus = false
schreib(STUDIO, "return { format = 1, grenzen = { [" .. esc("sensor:0042:0") .. "] = { richtung = " .. esc("ueber")
  .. ", alarm = 40, beiMotorAus = false }, [" .. esc("sensor:0043:0") .. "] = { richtung = " .. esc("ueber")
  .. ", alarm = 40 } } }")
local sensorWert = 50
local function sensor(id)
  return { value = function() return sensorWert end, category = function() return 1 end, name = function() return "S" .. id end,
    appId = function() return id end, subId = function() return 0 end, physId = function() return 0 end }
end
local liste = { sensor(0x42), sensor(0x43) }
system.getSource = function() return liste[1] end
system.getSources = function() return liste end
CATEGORY_TELEMETRY_SENSOR = 4
start()
motorAus = true
lauf(30)
local m42, m43 = w.meld["sensor:0042:0A"], w.meld["sensor:0043:0A"]
pruefe(w.studioZustand == "geladen" and m43 and m43.an and not (m42 and m42.an),
  "f) Sensor-Grenzen, Motor aus: ohne Schlüssel Alarm, mit beiMotorAus = false still")
pruefe(w.studio.st["sensor:0042:0"] == 2, "f) stille Sensor-Grenze zeigt die Farbe weiter (st = " .. tostring(w.studio.st["sensor:0042:0"]) .. ")")
motorAus = false
lauf(10)
m42 = w.meld["sensor:0042:0A"]
pruefe(m42 and m42.an, "f) Motor ein: Sensor-Alarm kommt")
system.getSource = function() return nil end

-- j) Befund Heli-Prüfer 21.11.: Eintrag ohne Stufe (nur beiMotorAus / nur ansage) oder beide Stufen false ohne «aus»
--    darf den überwachten Alarm nie abschalten: Werkgrenze (Reglertemp. 70/85, Strom 80/100, Akku 30/20)
schreib(STUDIO, "return { format = 1, grenzen = { [" .. esc("lua:reglertemp") .. "] = { beiMotorAus = false }, ["
  .. esc("lua:strom") .. "] = { ansage = false }, [" .. esc("lua:akku_proz") .. "] = { warnung = false, alarm = false } } }")
system.getSource = function() return nil end
start()
lauf(15)
pruefe(w.studioZustand == "geladen" and w.cfg.tempW == 70 and w.cfg.tempA == 85, "j) nur beiMotorAus: Werkgrenze Reglertemp. 70/85 (" .. tostring(w.cfg.tempW) .. "/" .. tostring(w.cfg.tempA) .. ")")
pruefe(w.cfg.stromW == 80 and w.cfg.stromA == 100, "j) nur ansage: Werkgrenze Strom 80/100 (" .. tostring(w.cfg.stromW) .. "/" .. tostring(w.cfg.stromA) .. ")")
pruefe(w.cfg.akkuW == 30 and w.cfg.akkuA == 20, "j) warnung = false, alarm = false ohne aus: Werkgrenze Akku 30/20 (" .. tostring(w.cfg.akkuW) .. "/" .. tostring(w.cfg.akkuA) .. ")")
pruefe(w.cfg.tempMot == false, "j) beiMotorAus = false gilt trotzdem")
motorAus = false
toene, werte.t = 0, 95
lauf(15)
pruefe(alarmAn() and toene >= 1, "j) Reglertemp.-Alarm kommt mit der Werkgrenze")
os.remove(STUDIO)

-- k) 0.6.0 Übergang: Studio-Datei nur unter dem alten Namen <Kennung>.elektro.lua wird gelesen, mit Log-Hinweis
schreib("SCRIPTS:/studio/TEST.elektro.lua", "return { format = 1, grenzen = { [" .. esc("lua:reglertemp") .. "] = { richtung = "
  .. esc("ueber") .. ", warnung = 60, alarm = 75 } } }")
local alteDruck, hinweisAlt = print, false
print = function(s) if tostring(s):find("old studio file found", 1, true) then hinweisAlt = true end end
start()
lauf(15)
print = alteDruck
pruefe(w.studioZustand == "geladen" and w.cfg.tempW == 60 and w.cfg.tempA == 75 and hinweisAlt,
  "k) alte Studio-Datei .elektro.lua gelesen (60/75), Hinweis im Log")
os.remove("SCRIPTS:/studio/TEST.elektro.lua")

-- Menü: eigene Gruppe, nicht über «einstellungen» der Studio-Datei
local F = assert(loadfile("felder.lua"))()
pruefe(F.feld("tempMot") and F.feld("tempMot")[2] == "b" and not F.studioEinstellung("tempMot"),
  "Menü: «auch bei Motor aus» je Wert als Ja/Nein, nicht als Studio-Einstellung")

os.execute("rm -rf '" .. tmp .. "'")
print(fehler == 0 and "ERGEBNIS: kein Fehler" or ("ERGEBNIS: " .. fehler .. " Fehler"))
os.exit(fehler == 0 and 0 or 1)
