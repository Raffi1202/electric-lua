local quelle = arg[0]:gsub("test/layout%-test%.lua$", "") .. "src/electric"
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

-- Electric 0.7.0: Studio-Layout wird immer gefunden (Auftrag 22.11.2026, R1–R4). Mac-Test ohne Simulator.
-- Aufruf aus dem Repo-Ordner:  /opt/homebrew/opt/lua@5.4/bin/lua test/layout-test.lua
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

-- F1 Name falsch: ohne Wahl Standard, nach der Wahl im Menü das Layout
schreib("SCRIPTS:/studio/Falsch.electric.lua", NUR800)
schreib("SCRIPTS:/studio/Falsch.electric.funke.lua", "return { format = 1 }\n")
local w = neu()
lauf(w)
pruefe(w.studio == nil and w.studioZustand == "fehlt" and w.sGrund == nil, "F1: Name passt nicht, keine Wahl: Standardanzeige ohne Hinweis")
FELDER = {}
reg.configure(w)
local fe = FELDER[LAYOUT]
local nr
for _, x in ipairs(fe and fe.werte or {}) do if x[1] == "Falsch.electric.lua (SCRIPTS)" then nr = x[2] end end
pruefe(fe and fe.werte[1][1] == "automatic (model name)" and fe.get() == 1 and nr and #fe.werte == 2,
  "F1: Menü zeigt «automatisch» und Falsch.electric.lua (SCRIPTS), ohne .funke.lua")
fe.set(nr)
lauf(w)
pruefe(w.studio and w.studio.ansichten["800x480"] and w.studioWahl == "menue", "F1: nach der Wahl im Menü gilt das Layout")
local I = info()
pruefe(I:find('"studioQuelle": "SCRIPTS:/studio/Falsch.electric.lua"', 1, true) and I:find('"studioWahl": "menue"', 1, true)
  and I:find('"ansichtGenutzt": "800x480"', 1, true) and I:find('"angepasst": false', 1, true)
  and I:find('"sensoren"') < I:find('"studioQuelle"'), "F1: Info-Datei mit den neuen Feldern am Ende")
SP = {}
reg.write(w)
local w1 = neu()
lauf(w1)
pruefe(w1.lay == "SCRIPTS:/studio/Falsch.electric.lua" and w1.studio ~= nil, "F1: Wahl bleibt über das Speichern erhalten")
FELDER = {} reg.configure(w1) FELDER[LAYOUT].set(1) lauf(w1)
pruefe(w1.lay == "" and w1.studio == nil, "F1: zurück auf automatisch")
schreib("SCRIPTS:/studio/TEST.electric.lua", NUR800)
FELDER = {} reg.configure(w1) FELDER[LAYOUT].set(2) lauf(w1)
pruefe(w1.studioQuelle == "SCRIPTS:/studio/Falsch.electric.lua", "F1: passende Datei und Wahl: die Wahl gewinnt (R2.3)")
weg("SCRIPTS:/studio/TEST.electric.lua") weg("SCRIPTS:/studio/Falsch.electric.lua") weg("SCRIPTS:/studio/Falsch.electric.funke.lua")
SP = {}

-- F2 Ort: Datei nur in SD:/scripts/studio bzw. RADIO:/scripts/studio
schreib("SD:/scripts/studio/TEST.electric.lua", NUR800)
local w2 = neu() lauf(w2)
pruefe(w2.studio and w2.studioQuelle == "SD:/scripts/studio/TEST.electric.lua" and info():find('"studioQuelle": "SD:/scripts/studio/TEST.electric.lua"', 1, true),
  "F2: Datei nur auf SD:/scripts/studio gefunden, studioQuelle zeigt den Ort")
weg("SD:/scripts/studio/TEST.electric.lua")
schreib("RADIO:/scripts/studio/TEST.electric.lua", NUR800)
local w2b = neu() lauf(w2b)
pruefe(w2b.studio and w2b.studioQuelle == "RADIO:/scripts/studio/TEST.electric.lua", "F2: Datei nur auf RADIO:/scripts/studio gefunden")
schreib("SD:/scripts/studio/TEST.electric.lua", "kaputt")
local w2c = neu() lauf(w2c)
pruefe(w2c.studioZustand == "kaputt" and w2c.studioQuelle == "SD:/scripts/studio/TEST.electric.lua", "F2: Reihenfolge SCRIPTS, SD, RADIO (erster Fund gilt)")
weg("SD:/scripts/studio/TEST.electric.lua")
FELDER = {} reg.configure(w2b)
pruefe(FELDER[LAYOUT].werte[2][1] == "TEST.electric.lua (RADIO)", "F2: Menü zeigt den Ort in Klammern")
weg("RADIO:/scripts/studio/TEST.electric.lua")

-- F3 Grösse: nur 800 × 480, Fenster 784 × 316 (und 640 × 360): umgerechnet, 5-s-Hinweis, Befehle
schreib("SCRIPTS:/studio/TEST.electric.lua", NUR800)
for _, f in ipairs({ { 784, 316 }, { 640, 360 }, { 472, 210 } }) do
  local w3 = neu(f)
  local mw, mp = lauf(w3, 20, f)
  local key = f[1] .. "x" .. f[2]
  local A = w3.studio and w3.studio.ansichten[key]
  local kh = w3.L.kh
  local drin = A ~= nil
  for _, q in ipairs(A and A.plaetze or {}) do
    if q.x < 0 or q.y < kh or q.x + q.b > f[1] or q.y + q.h > f[2] then drin = false end
  end
  pruefe(A and A.angepasst and A.von == "800x480" and drin, "F3 " .. key .. ": Ansicht umgerechnet, " .. (A and #A.plaetze or 0)
    .. " Plätze innerhalb unter der Kopfzeile (" .. kh .. " px), " .. (A and A.weg or 0) .. " weggelassen")
  pruefe(w3.sHinweis and w3.sHinweis:find("Studio: view 800x480 adapted", 1, true), "F3 " .. key .. ": Hinweis «" .. tostring(w3.sHinweis) .. "»")
  local I3 = info()
  pruefe(I3:find('"ansichtGenutzt": "800x480"', 1, true) and I3:find('"angepasst": true', 1, true), "F3 " .. key .. ": Info-Datei angepasst = true")
  local mw2, mp2 = lauf(w3, 30, f)
  pruefe(w3.sHinweis == nil and not w3.sAusruf, "F3 " .. key .. ": nach 5 s kein Hinweis und kein «!» mehr")
  messung(string.format("F3 %s: wakeup beim Umrechnen %d, paint mit umgerechneter Ansicht höchstens %d, danach wakeup höchstens %d Befehle (erster wakeup beim Laden %d)", key, SKAL, mp2, mw2, mw))
  pruefe(SKAL > 0 and SKAL < 5000 and mp2 < 10000 and mw2 < 5000, "F3 " .. key .. ": Befehlsgrenzen (wakeup < 5000, paint < 10000)")
  SKAL = 0
end

-- F4 Fehlerfall: Syntaxfehler -> Standard mit Hinweiszeile
schreib("SCRIPTS:/studio/TEST.electric.lua", "return { format = 1, ansichten = { { breite = 800 }\n")
local w4 = neu() lauf(w4)
pruefe(w4.studio == nil and w4.sGrund == "Studio: file broken (TEST.electric.lua)", "F4: Standard mit Hinweis «" .. tostring(w4.sGrund) .. "»")
pruefe(info():find('"hinweis": "Studio: file broken (TEST.electric.lua)"', 1, true), "F4: Hinweis in der Info-Datei")
schreib("SCRIPTS:/studio/TEST.electric.lua", "return { format = 1, studio = " .. e("0.7.0") .. " }\n")
local w4b = neu() lauf(w4b)
pruefe(w4b.studio and w4b.sGrund == "Studio: no matching view", "F4: Datei ohne Ansicht: «keine passende Ansicht»")
weg("SCRIPTS:/studio/TEST.electric.lua")

-- F5 Update: Speicher der Vorversion (FORMAT 1, 18 Quellen, ohne Wahl)
local function q(n) return { value = function() return 1 end, name = function() return n end, category = function() return 1 end } end
SP = { 1 }
for i = 1, 18 do SP[#SP + 1] = (i % 4 == 0) and 0 or q("Q" .. i) end
SP[#SP + 1] = 1
local w5 = neu() lauf(w5)
local F = assert(loadfile("felder.lua"))()
local alle = true
for i, n in ipairs(F.quellen()) do
  local v = w5.cfg[n]
  if i % 4 == 0 then alle = alle and v == nil else alle = alle and v and v:name() == "Q" .. i end
end
pruefe(alle and w5.lay == "", "F5: Speicher der Vorversion gelesen, alle Quellen da, Wahl steht auf automatisch")
FELDER = {} reg.configure(w5)
pruefe(FELDER[LAYOUT].get() == 1, "F5: Menü zeigt «automatisch (Modellname)»")

os.execute("rm -rf '" .. tmp .. "'")
for _, x in ipairs(messungen) do print_("MESSUNG " .. x) end
print_(fehler == 0 and "ERGEBNIS: kein Fehler" or ("ERGEBNIS: " .. fehler .. " Fehler"))
os.exit(fehler == 0 and 0 or 1)
