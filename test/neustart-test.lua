-- Elektro: Verhalten nach einem Neustart des Senders (Befunde der unabhängigen Prüfung vom 20.11.2026).
-- Aufruf aus dem Repo-Ordner:  /opt/homebrew/opt/lua@5.4/bin/lua test/neustart-test.lua
-- Läuft in einer Kopie von src/elektro in einem temporären Ordner (das Skript schreibt daten/).
--  a) Nullpunkt «AUF 0» gespeichert, nach dem Neustart beginnt der Regler wieder bei 0: Verbraucht zählt ab 0.
--  b) Pausierter Flug vor dem Neustart, «Akkuwechsel beendet Flug» an: Er kommt in die Liste, der nächste
--     Motorlauf ist ein neuer Flug.
--  c) RSSI in dBm (negativ): angezeigt wie im Sensormenü (-80 dBm), intern +120 für Schwellen.
--  d) Motorschalter über state() (0.3.1).  e) Höchstwert nach Quellwechsel neu (0.3.1).
--  f) Alarm mit Studio «ansage = false»: trotzdem Ton (0.3.2).  g) wakeup mit 160 Grenzen < 5000 Befehle (0.3.2).
local quelle = arg[0]:gsub("test/neustart%-test%.lua$", "") .. "src/elektro"
local tmp = os.tmpname()
os.remove(tmp)
assert(os.execute("mkdir -p '" .. tmp .. "/daten' && cp '" .. quelle .. "'/*.lua '" .. tmp .. "/'"))

local fehler = 0
local function pruefe(ok, text)
  print((ok and "ok     " or "FEHLER ") .. text)
  if not ok then fehler = fehler + 1 end
end

-- nachgebildete Ethos-Umgebung
local T = 0
os.clock = function() return T end
local werte = {}
local function Q(name)
  return { value = function() return werte[name] end, name = function() return name end,
    minimum = function() return -1024 end, maximum = function() return 1024 end, decimals = function() return 0 end,
    category = function() return 1 end }
end
system = { getVersion = function() return { simulation = false } end, playFile = function() end,
  playNumber = function() end, playTone = function() end, getSource = function() return nil end }
model = { name = function() return "TEST" end, path = function() return "models/test.bin" end, dirty = function() end }
lcd = { isVisible = function() return false end, invalidate = function() end }
storage = { read = function() return nil end, write = function() end }
UNIT_PERCENT, UNIT_VOLT, UNIT_MILLIAMPERE_HOUR = 1, 2, 3

local alt = io.open
local ordner = tmp .. "/"
io.open = function(p, m) return alt((p:sub(1, 1) == "/" and "" or ordner) .. p, m) end
local laden = loadfile
loadfile = function(p) return laden((p:sub(1, 1) == "/" and "" or ordner) .. p) end
local function neuerStart()
  local K = assert(loadfile("kern.lua"))()
  local w = K.neu()
  K.lies(w)
  return K, w
end

-- a) Nullpunkt
local K, w = neuerStart()
w.cfg.mah, w.cfg.uGes, w.cfg.strom, w.cfg.zellenzahl, w.cfg.kapaz = Q("mah"), Q("u"), Q("i"), 3, 2200
werte.mah, werte.u, werte.i = 1200, 11.1, 0
for t = 1, 20 do T = t * 0.2 K.wecke(w) end
w.dauer.mahNull = 1200
w.dateiOffen, w.dateiJetzt = true, true
T = 5 K.wecke(w)
pruefe(w.v.mah == 0, "a) vor dem Neustart: Verbraucht 0 nach AUF 0")
K, w = neuerStart()
w.cfg.mah, w.cfg.uGes, w.cfg.strom, w.cfg.zellenzahl, w.cfg.kapaz = Q("mah"), Q("u"), Q("i"), 3, 2200
werte.mah, werte.u = 0, 12.6
T = 100
for k = 1, 20 do T = T + 0.2 K.wecke(w) end
werte.mah = 300
for k = 1, 10 do T = T + 0.2 K.wecke(w) end
pruefe(w.v.mah == 300, "a) nach dem Neustart: Regler 300 mAh -> Verbraucht " .. tostring(w.v.mah) .. " (erwartet 300)")
pruefe((w.dauer.mahNull or 0) == 0, "a) gespeicherter Nullpunkt zurückgesetzt")

-- b) offener Flug
os.execute("rm -f '" .. tmp .. "/daten/'*")
werte = {}
K, w = neuerStart()
w.cfg.strom, w.cfg.mah, w.cfg.erkennung = Q("i"), Q("mah"), 2
T = 0
local function lauf(s, i, roh) werte.i, werte.mah = i, roh for k = 1, s * 5 do T = T + 0.2 K.wecke(w) end end
lauf(1, 0, 0) lauf(60, 30, 900) lauf(25, 0, 900)
pruefe(w.akt and w.akt.pause == true and w.akt[1] == 1, "b) Flug 1 pausiert, Rückfrage offen")
K, w = neuerStart()
w.cfg.strom, w.cfg.mah, w.cfg.erkennung = Q("i"), Q("mah"), 2
T = 500
lauf(5, 0, 0) lauf(60, 30, 800)
pruefe(#w.liste == 1 and w.liste[1][1] == 1, "b) Flug 1 nach dem Neustart in der Liste")
pruefe(w.akt and w.akt[1] == 2, "b) neuer Motorlauf ist Flug 2")

-- c) RSSI in dBm
werte = {}
K, w = neuerStart()
w.cfg.rssi = Q("r")
werte.r = -80
T = 900
for k = 1, 10 do T = T + 0.2 K.wecke(w) end
pruefe(w.v.rssi == 40 and w.v.dbm == true, "c) -80 dBm intern 40, als dBm erkannt")
werte.r = -95
for k = 1, 10 do T = T + 0.2 K.wecke(w) end
pruefe(w.v.rssiTief == 25, "c) Tiefstwert -95 dBm intern 25")
werte.r = 50
for k = 1, 10 do T = T + 0.2 K.wecke(w) end
pruefe(w.v.rssiTief == 50 and not w.v.dbm, "c) Wechsel auf positiven RSSI: Tiefstwert beginnt neu (50)")

-- d) 0.3.1: Motorschalter (Schalterstellung) über state(), nicht über den Wert. Am Sender zeigte die Pille bei SF
--    oben und unten «MOTOR AUS». Hier liefert der Wert immer 1024 (wäre «aktiv»), state() entscheidet.
CATEGORY_SWITCH_POSITION = 7
werte = {}
K, w = neuerStart()
local zustand = false
local sf = { name = function() return "SF↑" end, value = function() return 1024 end, minimum = function() return -1024 end,
  maximum = function() return 1024 end, category = function() return 7 end, state = function() return zustand end }
w.cfg.swMotor, w.cfg.erkennung = sf, 1
T = 1000
for k = 1, 5 do T = T + 0.2 K.wecke(w) end
pruefe(w.v.motorAus == false, "d) SF unten: state() = false -> scharf, trotz Wert 1024")
zustand = true
for k = 1, 5 do T = T + 0.2 K.wecke(w) end
pruefe(w.v.motorAus == true, "d) SF oben: state() = true -> Motor aus")
sf.state = nil                                                 -- ohne state(): wie bisher über den Wert
for k = 1, 5 do T = T + 0.2 K.wecke(w) end
pruefe(w.v.motorAus == true, "d) ohne state(): Wert über der Mitte -> aktiv")
w.cfg.swMotor = Q("kanal")                                     -- andere Quelle (Kategorie 1): Wert entscheidet
werte.kanal = -1024
for k = 1, 5 do T = T + 0.2 K.wecke(w) end
pruefe(w.v.motorAus == false, "d) Kanal als Motorschalter: Wert unter der Mitte -> scharf")

-- e) 0.3.1: neue Quelle für ein Feld setzt dessen Höchstwert zurück («MAX 98400» aus einer früheren Bindung)
werte = {}
K, w = neuerStart()
w.cfg.rpm, w.cfg.temp = Q("rpmAlt"), Q("temp")
werte.rpmAlt, werte.rpmNeu, werte.temp = 98400, 7800, 90
T = 1200
for k = 1, 10 do T = T + 0.2 K.wecke(w) end
local hochAlt = w.v.rpmHoch
werte.temp = 55
w.cfg.rpm = Q("rpmNeu")
for k = 1, 10 do T = T + 0.2 K.wecke(w) end
pruefe(hochAlt and w.v.rpmHoch and w.v.rpmHoch < hochAlt and w.v.rpmHoch == w.v.rpm,
  "e) Drehzahl: MAX nach Quellwechsel neu (" .. tostring(hochAlt) .. " -> " .. tostring(w.v.rpmHoch) .. ")")
pruefe(w.v.tempHoch == 90, "e) Temperatur: gleiche Quelle, MAX bleibt 90")

-- f) 0.3.2, Entscheid des Autors: Studio-Datei mit «ansage = false» macht den Alarm nicht stumm, es kommt ein Ton
--    (auch wenn «Ton bei Alarm» im Menü aus ist). Ohne Studio-Datei bleibt die Menü-Einstellung massgebend.
CATEGORY_SWITCH_POSITION = nil
assert(os.execute("mkdir -p '" .. tmp .. "/SCRIPTS:/studio'"))
local function esc(t) return '"' .. t:gsub(".", function(c) return "\\" .. c:byte() end) .. '"' end
local fs = io.open("SCRIPTS:/studio/TEST.elektro.lua", "w")
fs:write("return { format = 1, grenzen = { [" .. esc("lua:reglertemp") .. "] = { richtung = " .. esc("ueber")
  .. ", warnung = 70, alarm = 85, ansage = false, vibration = false } } }")
fs:close()
local toene = 0
system.playTone = function() toene = toene + 1 end
system.getVersion = function() return { simulation = false, board = "X18RS", version = "26.2.0" } end
werte = {}
K, w = neuerStart()
w.cfg.temp = Q("t")
werte.t = 55
T = 2000
for k = 1, 60 do T = T + 0.2 K.wecke(w) end           -- Studio-Datei laden (setzt Einstellungen auf Studio/Werk)
w.cfg.ton, w.cfg.ansage, w.cfg.vibration = false, false, false
toene, werte.t = 0, 95
for k = 1, 150 do T = T + 0.2 K.wecke(w) end
pruefe(w.studioZustand == "geladen" and w.studio and w.studio.gAns.temp == false, "f) Studio-Datei geladen, Ansage für Reglertemp. aus")
pruefe(toene >= 2, "f) Alarm mit Studio «ansage = false» und Ton im Menü aus: trotzdem Ton (" .. toene .. "×)")
os.remove(ordner .. "SCRIPTS:/studio/TEST.elektro.lua")   -- os.remove ist im Test nicht umgeleitet
toene = 0
K, w = neuerStart()
w.cfg.temp = Q("t")
werte.t = 55
for k = 1, 60 do T = T + 0.2 K.wecke(w) end
w.cfg.ton, w.cfg.ansage, w.cfg.vibration = false, false, false
toene, werte.t = 0, 95
for k = 1, 150 do T = T + 0.2 K.wecke(w) end
pruefe(w.studioZustand == "fehlt" and toene == 0, "f) ohne Studio-Datei: Menü «Ton aus, Ansage aus» gilt wie bisher (" .. toene .. " Töne)")

-- g) 0.3.2 (Prüfung): ganzer wakeup mit Studio-Datei und 160 Sensor-Grenzen bleibt unter 5000 Befehlen
local tg = { "return { format = 1, grenzen = {" }
for i = 1, 160 do tg[#tg + 1] = string.format("[%s]={richtung=%s,alarm=200},", esc(string.format("sensor:%04X:0", i)), esc("ueber")) end
tg[#tg + 1] = "} }"
fs = io.open("SCRIPTS:/studio/TEST.elektro.lua", "w") fs:write(table.concat(tg)) fs:close()
local wert = { value = function() return 50 end, category = function() return 1 end }
system.getSource = function() return wert end
-- Grundlast ohne Studio-Datei (enthält das periodische Speichern von Zählern und Flügen, seit 0.1.x) gegen dieselbe
-- Lage mit 160 Grenzen: die Studio-Datei darf höchstens 2500 Befehle je wakeup dazulegen
local function messe()
  werte = {}
  K, w = neuerStart()
  w.cfg.temp, w.cfg.uGes, w.cfg.strom = Q("t"), Q("u"), Q("i")
  werte.t, werte.u, werte.i = 40, 22, 30
  for k = 1, 400 do T = T + 0.2 K.wecke(w) end         -- laden, Quellen suchen
  local mx = 0
  for k = 1, 60 do
    T = T + 0.2
    local nb = 0
    debug.sethook(function() nb = nb + 1 end, "", 1)
    K.wecke(w)
    debug.sethook()
    if nb > mx then mx = nb end
  end
  return mx
end
local maxW = messe()
local gelanden = w.studioZustand == "geladen" and #w.studio.extra == 48   -- Format 2, Regel 7.2
os.remove(ordner .. "SCRIPTS:/studio/TEST.elektro.lua")
local maxW0 = messe()
pruefe(gelanden and maxW - maxW0 < 2500, "g) 160 Sensor-Grenzen: wakeup höchstens " .. maxW .. " Befehle, ohne Studio-Datei "
  .. maxW0 .. " (Zuschlag " .. (maxW - maxW0) .. " < 2500)")
system.getSource = function() return nil end

os.execute("rm -rf '" .. tmp .. "'")
print(fehler == 0 and "ERGEBNIS: kein Fehler" or ("ERGEBNIS: " .. fehler .. " Fehler"))
os.exit(fehler == 0 and 0 or 1)
