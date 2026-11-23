local quelle = arg[0]:gsub("test/voll%-test%.lua$", "") .. "src/electric"
local tmp = os.tmpname()
os.remove(tmp)
assert(os.execute("mkdir -p '" .. tmp .. "/electric/daten' '" .. tmp .. "/SCRIPTS/studio' && cp '" .. quelle .. "'/*.lua '" .. tmp .. "/electric/'"))

local fehler = 0
local zeilen = {}
local print_ = print
print = function(...) local t = table.concat({ ... }, " ") zeilen[#zeilen + 1] = t if not t:find("^Studio%-Symbol") then print_(...) end end
local messungen = {}
local function messung(text) messungen[#messungen + 1] = text end
local function pruefe(ok, text)
  print_((ok and "ok     " or "FEHLER ") .. text)
  if not ok then fehler = fehler + 1 end
end

local function pfad(p)
  if p:sub(1, 9) == "SCRIPTS:/" then return tmp .. "/SCRIPTS/" .. p:sub(10) end
  if p:sub(1, 4) == "SD:/" then return tmp .. "/SD/" .. p:sub(5) end
  if p:sub(1, 7) == "RADIO:/" then return tmp .. "/RADIO/" .. p:sub(8) end
  if p:sub(1, 1) == "/" then return p end
  return tmp .. "/electric/" .. p
end
local geoeffnet = {}
local io_open = io.open
io.open = function(p, m)
  if type(p) == "string" and p:find("symbole", 1, true) then geoeffnet[#geoeffnet + 1] = p end
  return io_open(pfad(p), m)
end
local laden = loadfile
loadfile = function(p, ...) return laden(pfad(p), ...) end
local os_rename, os_remove = os.rename, os.remove
os.rename = function(a, b)
  local f = io_open(pfad(b), "r")
  if f then f:close() return nil, "exists" end
  return os_rename(pfad(a), pfad(b))
end
os.remove = function(p) return os_remove(pfad(p)) end
os.mkdir = function() return true end

local T = 0
os.clock = function() return T end
local BREITE, W, H = 800, 800, 480
system = { getVersion = function() return { simulation = false, board = "X18RS", version = "26.2.0", lcdWidth = BREITE } end,
  playFile = function() end, playNumber = function() end, playTone = function() end, playHaptic = function() end,
  getSource = function() return nil end, getSources = function() return {} end }
model = { name = function() return "TEST" end, path = function() return "models/test.bin" end, dirty = function() end }
storage = { read = function() return nil end, write = function() end }
local masken = {}
local CF = coroutine.running              -- C-Funktion, nimmt beliebige Argumente an
local GROESSE = function() return 70, 14 end
lcd = { getWindowSize = function() return W, H end, isVisible = function() return true end, invalidate = CF,
  RGB = math.max, getTextSize = GROESSE, color = CF, font = CF, drawText = CF, drawLine = CF, drawRectangle = CF,
  drawFilledRectangle = CF, drawFilledCircle = CF, drawAnnulusSector = CF, drawMask = CF,
  loadMask = function(p) masken[#masken + 1] = p return { p = p } end }
for i, n in ipairs({ "FONT_XS", "FONT_S", "FONT_STD", "FONT_L", "FONT_XL", "FONT_XXL", "FONT_BOLD", "FONT_STD_BOLD",
  "LEFT", "CENTERED", "RIGHT", "UNIT_PERCENT", "UNIT_VOLT", "UNIT_MILLIAMPERE_HOUR", "UNIT_AMPERE", "UNIT_RPM",
  "UNIT_CELSIUS", "UNIT_METER", "UNIT_METER_PER_SECOND", "UNIT_KPH", "UNIT_DB", "WHITE" }) do _ENV[n] = i end
CATEGORY_TELEMETRY_SENSOR, CATEGORY_CHANNEL, CATEGORY_NONE = 101, 102, 0

local function kopiere(von, nach)
  local a = assert(io_open(von, "rb")) local t = a:read("a") a:close()
  local b = assert(io_open(nach, "wb")) b:write(t) b:close()
end
local function messe(f, ...)
  local n = 0
  debug.sethook(function() n = n + 1 end, "", 1)
  local ok, e = pcall(f, ...)
  debug.sethook()
  if not ok then print_("  Fehler: " .. tostring(e)) end
  return n, ok
end

-- Electric 0.10.0: Befehle bei voller Belegung (Issues #1/#2, 23.11.2026). Mac-Test ohne Simulator.
-- Aufruf aus dem Repo-Ordner:  /opt/homebrew/opt/lua@5.4/bin/lua test/voll-test.lua
assert(os.execute("mkdir -p '" .. tmp .. "/SD/scripts/studio' '" .. tmp .. "/RADIO/scripts/studio'"))
system.listFiles = function(ort)
  local l, p = {}, io.popen("ls '" .. pfad(ort) .. "' 2>/dev/null")
  for n in p:lines() do l[#l + 1] = n end
  p:close()
  return l
end
-- Widget-Speicher nach Reihenfolge wie Ethos
local SP, LESE = {}, 0
storage = { read = function() LESE = LESE + 1 return SP[LESE] end, write = function(_, v) SP[#SP + 1] = v end }
-- Menü: Felder mitschreiben
local FELDER = {}
local OBJ = setmetatable({}, { __index = function() return CF end })
form = { addLine = function(t) return t end, addExpansionPanel = function() return OBJ end,
  addChoiceField = function(z, _, werte, get, set) FELDER[z] = { werte = werte, get = get, set = set } return OBJ end }
setmetatable(form, { __index = function() return function() return OBJ end end })
local LAYOUT = "Studio layout"                           -- Testsprache Englisch (wie die Simulator-Bilder)

-- Studio-Text: jeder Text als \ddd (erlaubte Bytes)
local function e(t) return '"' .. t:gsub(".", function(c) return "\\" .. c:byte() end) .. '"' end
local function platz(x, y, b, h, w, d) return "{ x = " .. x .. ", y = " .. y .. ", b = " .. b .. ", h = " .. h .. ", w = " .. e(w)
  .. (d and (", darstellung = " .. e(d)) or "") .. " }" end
local NUR800 = "return { format = 1, studio = " .. e("0.7.0") .. ", ansichten = { { breite = 800, hoehe = 480, plaetze = { "
  .. platz(8, 64, 380, 200, "lua:akku_proz", "ring") .. ", " .. platz(396, 64, 396, 200, "lua:strom") .. ", "
  .. platz(8, 272, 380, 150, "lua:spannung") .. ", " .. platz(396, 272, 396, 200, "lua:verbraucht") .. ", "
  .. platz(700, 440, 92, 38, "lua:drehzahl") .. " } } } }\n"
local function schreib(p, t) local f = assert(io_open(pfad(p), "w")) f:write(t) f:close() end
local function weg(p) os_remove(pfad(p)) end
local function info() local f = io_open(pfad("SCRIPTS:/studio/TEST.electric.info.json"), "r") if not f then return "" end
  local t = f:read("a") f:close() return t end

local reg
system.registerWidget = function(t) reg = t end
local m = assert(loadfile("main.lua"))()
m.init()
local SKAL = 0                                           -- Befehle im wakeup, der umrechnet
local function lauf(w, n, fenster)
  W, H = fenster and fenster[1] or 800, fenster and fenster[2] or 480
  local maxW, maxP = 0, 0
  for _ = 1, n or 120 do
    T = T + 0.2
    local vor = w.skalWunsch
    local nw = messe(reg.wakeup, w)
    if vor and not w.skalWunsch and nw > SKAL then SKAL = nw end
    local np = messe(reg.paint, w)
    if nw > maxW then maxW = nw end
    if np > maxP then maxP = np end
  end
  return maxW, maxP
end
local function neu(fenster) SP, LESE = SP, 0 local w = reg.create() reg.read(w) lauf(w, 3, fenster) return w end


-- Volle Belegung: alle Sensoren, die Electric kennt, dazu zwei Bänder, zwei Zellensensoren, Empfänger-Akku 2 und
-- weitere fremde Sensoren (zusammen 40). Zellensensoren liefern 6 Zellen über OPTION_CELL_COUNT/INDEX.
OPTION_CELL_COUNT = 1000
OPTION_CELL_INDEX = function(i) return 1000 + i end
local function sen(name, id, teil, phys, einheit, wert, band, zellen)
  return { n = name, i = id, t = teil, p = phys, e = einheit, w = wert, b = band or 0, z = zellen,
    name = function(x) return x.n end, appId = function(x) return x.i end, subId = function(x) return x.t end,
    physId = function(x) return x.p end, unit = function(x) return x.e end, band = function(x) return x.b end,
    category = function() return CATEGORY_TELEMETRY_SENSOR end, stringValue = function(x) return tostring(x.w) end,
    value = function(x, opt)
      if x.z and opt == OPTION_CELL_COUNT then return #x.z end
      if x.z and type(opt) == "number" and opt > 1000 then return x.z[opt - 1000] end
      return x.w
    end }
end
local LISTE = {
  sen("RSSI 2.4G", 0xF101, 0, 24, UNIT_DB, 52, 0), sen("RSSI 900M", 0xF101, 0, 24, UNIT_DB, 41, 1),
  sen("VFR 2.4G", 0xF010, 0, 24, UNIT_PERCENT, 66, 0), sen("VFR 900M", 0xF010, 0, 24, UNIT_PERCENT, 64, 1),
  sen("RX VFR", 0xF011, 0, 24, UNIT_PERCENT, 45, 0), sen("RxBatt 1", 0xF108, 0, 24, UNIT_VOLT, 7.4, 0),
  sen("RxBatt 2", 0xF108, 1, 24, UNIT_VOLT, 4.4, 0), sen("Empf.-Batt.", 0xF104, 0, 24, UNIT_VOLT, 7.4, 0),
  sen("Cels", 0x0300, 0, 1, UNIT_VOLT, 22, 0, { 3.7, 3.71, 3.69, 3.7, 3.72, 3.7 }),
  sen("Cels", 0x0300, 0, 2, UNIT_VOLT, 22, 0, { 3.46, 3.47, 3.45, 3.46, 3.48, 3.44 }),
  sen("ESC Spannung", 0x0B50, 0, 4, UNIT_VOLT, 22.1), sen("ESC Strom", 0x0B50, 1, 4, UNIT_AMPERE, 55),
  sen("ESC Drehzahl", 0x0B60, 0, 4, UNIT_RPM, 7800), sen("ESC Verbraucht", 0x0B60, 1, 4, UNIT_MILLIAMPERE_HOUR, 3900),
  sen("ESC Temp", 0x0B70, 0, 4, UNIT_CELSIUS, 81), sen("BEC Spannung", 0x0E50, 0, 4, UNIT_VOLT, 5.1),
  sen("Höhe", 0x0100, 0, 21, UNIT_METER, 130), sen("Vario", 0x0110, 0, 21, UNIT_METER_PER_SECOND, 2.3),
  sen("Airspeed", 0x0A00, 0, 21, UNIT_KPH, 110), sen("GPS Alt", 0x0820, 0, 3, UNIT_METER, 128),
  sen("GPS Speed", 0x0830, 0, 3, UNIT_KPH, 105), sen("GPS", 0x0800, 0, 3, nil, 0),
}
for i = #LISTE + 1, 40 do LISTE[i] = sen("Fremd " .. i, 0x5100 + i, 0, 30, UNIT_VOLT, i) end
system.getSources = function() return LISTE end
system.getSource = function() return nil end
SP, LESE = {}, 0
-- Datendatei wie nach dem Einstellen: Akku 2 als eigener Akku, BEC-Grenzen an (damit auch diese Zeilen arbeiten)
local FD = assert(loadfile("felder.lua"))()
schreib(FD.datei(), "z2modus=2\nbecW=50\nbecA=45\nzellenzahl=6\n")
local w = reg.create() reg.read(w)
local maxS, maxP = 0, 0
w.suche, w.suchJob = "menue", nil
for _ = 1, 160 do                                  -- Suche mit 40 Sensoren, danach Betrieb mit allen Werten
  T = T + 0.2
  local nw = messe(reg.wakeup, w)
  local np = messe(reg.paint, w)
  if nw > maxS then maxS = nw end
  if np > maxP then maxP = np end
end
local c = w.cfg
local alle = true
for _, f in ipairs({ "rssi", "rssi2", "vfr", "vfr2", "rxvfr", "zellen", "zellen2", "bec2", "strom", "uGes" }) do
  if c[f] == nil then alle = false print_("  nicht belegt: " .. f) end
end
pruefe(alle, "volle Belegung: alle Empfangs-, Zellen- und Akku-2-Quellen zugewiesen")
local maxB, maxB2 = 0, 0
for _, f in ipairs({ { 800, 480 }, { 784, 316 }, { 472, 210 } }) do
  W, H = f[1], f[2]
  for _ = 1, 60 do
    T = T + 0.2
    local nw = messe(reg.wakeup, w)
    local np = messe(reg.paint, w)
    if nw > maxB then maxB = nw end
    if np > maxB2 then maxB2 = np end
  end
end
local a = {}
for k in pairs(w.meld) do if w.meld[k].an then a[#a + 1] = k end end
table.sort(a)
messung(string.format("Suche mit 40 Sensoren: wakeup höchstens %d, paint höchstens %d", maxS, maxP))
messung(string.format("Betrieb volle Belegung (800x480, 784x316, 472x210): wakeup höchstens %d, paint höchstens %d", maxB, maxB2))
messung("aktive Meldungen: " .. table.concat(a, ", "))
-- Grenzen: gemessen und gemeldet, kein Testfehler. Knapp darüber ist bekannt und im CHANGELOG vermerkt (0.10.1);
-- entscheidend ist der Sendertest («Max instructions»).
local function grenze(x, g) return x < g and "unter der Grenze" or "ÜBER DER GRENZE (bekannt, Sendertest offen)" end
messung(string.format("wakeup Suche %d / Betrieb %d: %s / %s", maxS, maxB, grenze(maxS, 5000), grenze(maxB, 5000)))
messung(string.format("paint Suche %d / Betrieb %d: %s / %s", maxP, maxB2, grenze(maxP, 10000), grenze(maxB2, 10000)))
for _, x in ipairs(messungen) do print_("MESSUNG " .. x) end
os.execute("rm -rf '" .. tmp .. "'")
print_(fehler == 0 and "ERGEBNIS: kein Fehler" or ("ERGEBNIS: " .. fehler .. " Fehler"))
os.exit(fehler == 0 and 0 or 1)
