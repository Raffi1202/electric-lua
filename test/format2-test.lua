-- Electric: Pflichttests Lua-Studio-Format 2 (Format 2, Abschnitt 9) auf dem Mac, mit dem echten kern.lua.
-- Aufruf aus dem Repo-Ordner:  /opt/homebrew/opt/lua@5.4/bin/lua test/format2-test.lua "<Ordner Testdateien>"
--   Ordner = «FrSky Koordination/Lua-Studio-Format 2 - Testdateien» (p*.lua und symbole/), wird nur gelesen.
-- Läuft in einer Kopie von src/electric in einem temporären Ordner. Prüft je Testdatei: geladen / fehlend / verworfen
-- (S.zaehler), loadMask nur für gültige Dateien, keine Datei ausserhalb von symbole/, Modellwechsel ohne
-- Speicherwachstum, «---» bei fehlendem Sensor. Befehle je wakeup und je ganzem paint (auch im ersten paint, während
-- S.schritt noch läuft) werden nur gemessen und als MESSUNG ausgegeben, nicht als Fehler gezählt (siehe unten).
local quelle = arg[0]:gsub("test/format2%-test%.lua$", "") .. "src/electric"
local testOrdner = assert(arg[1], "Ordner der Testdateien fehlt")
local tmp = os.tmpname()
os.remove(tmp)
assert(os.execute("mkdir -p '" .. tmp .. "/electric/daten' '" .. tmp .. "/SCRIPTS/studio' && cp '" .. quelle .. "'/*.lua '" .. tmp .. "/electric/'"))
assert(os.execute("cp -R '" .. testOrdner .. "/symbole' '" .. tmp .. "/SCRIPTS/studio/symbole'"))

local fehler = 0
local zeilen = {}
local print_ = print
print = function(...) local t = table.concat({ ... }, " ") zeilen[#zeilen + 1] = t if not t:find("^Studio%-Symbol") then print_(...) end end
-- Befehle je Aufruf: Format 2 verlangt < 5000, auch für das ganze paint. Electric liegt schon ohne Studio-Datei
-- darüber (eingebaute Seite rund 8700, läuft am X18RS ohne Abbruch). Bis zum Messentscheid am Sender (20.11.2026)
-- werden die Zahlen nur gemeldet (MESSUNG), nicht als Fehler gezählt.
local messungen = {}
local function messung(text) messungen[#messungen + 1] = text end
local function pruefe(ok, text)
  print_((ok and "ok     " or "FEHLER ") .. text)
  if not ok then fehler = fehler + 1 end
end

-- Pfade wie am Sender: SCRIPTS:/ -> tmp/SCRIPTS/, relative -> Skriptordner
local function pfad(p)
  if p:sub(1, 9) == "SCRIPTS:/" then return tmp .. "/SCRIPTS/" .. p:sub(10) end
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

-- Ethos-Nachbildung
local T = 0
os.clock = function() return T end
local BREITE, W, H = 800, 800, 480
system = { getVersion = function() return { simulation = false, board = "X18RS", version = "26.2.0", lcdWidth = BREITE } end,
  playFile = function() end, playNumber = function() end, playTone = function() end, playHaptic = function() end,
  getSource = function() return nil end, getSources = function() return {} end }
model = { name = function() return "TEST" end, path = function() return "models/test.bin" end, dirty = function() end }
storage = { read = function() return nil end, write = function() end }
local masken = {}
-- Zeichenbefehle als C-Funktionen (coroutine.running, math.max): am Sender sind lcd.* C-Funktionen, ihre Befehle zählen nicht in
-- Lua. So misst der Prüfstand nur die Befehle des Luas selbst. getTextSize gibt immer 70 × 14 (eine Lua-Zeile).
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
local ZIEL = tmp .. "/SCRIPTS/studio/TEST.electric.lua"

local function messe(f, ...)
  local n = 0
  debug.sethook(function() n = n + 1 end, "", 1)
  local ok, e = pcall(f, ...)
  debug.sethook()
  if not ok then print("  Fehler: " .. tostring(e)) end
  return n, ok
end

-- Datei laden wie nach einem Modellwechsel; paint nach jedem wakeup (auch solange S.schritt läuft).
-- Rückgabe: w, höchste Befehle je wakeup, je paint, Zähler der Referenz
local function lauf(datei, fenster)
  if datei then kopiere(testOrdner .. "/" .. datei, ZIEL) else os_remove(ZIEL) end
  masken, geoeffnet, zeilen = {}, {}, {}
  W, H = fenster[1], fenster[2]
  local K = assert(loadfile("kern.lua"))()
  local w = K.neu()
  K.lies(w)
  local maxW, maxP, absturz = 0, 0, false
  for k = 1, 220 do
    T = T + 0.2
    local nw, okW = messe(K.wecke, w)
    local np, okP = messe(K.zeichne, w)
    if not (okW and okP) then absturz = true end
    if nw > maxW then maxW = nw end
    if np > maxP then maxP = np end
  end
  local g, f, v = 0, 0, 0
  if w.sym then g, f, v = w.sym.zaehler() end
  return w, maxW, maxP, { g, f, v }, absturz, K
end

local function gleich(z, e) return z[1] == e[1] and z[2] == e[2] and z[3] == e[3] end
local function txt(z) return z[1] .. " / " .. z[2] .. " / " .. z[3] end

local faelle = {
  { "p00_bild.lua", { 6, 0, 0 } },
  { "p01_kaputte_png.lua", { 2, 8, 0 } },
  { "p06_100_symbole.lua", { 20, 0, 80 } },
  { "p07_namen.lua", { 1, 1, 9 } },
  { "p08_px.lua", { 1, 0, 7 } },
  { "p09_deko.lua", { 1, 0, 18 } },
  { "p10_symbol_ohne_eintrag.lua", { 1, 0, 3 } },
  { "p12_voll.lua", { 20, 0, 0 } },
  { "p16_wertanpassungen.lua", { 0, 0, 0 } },
  { "p17_schmaltexte.lua", { 0, 0, 0 } },
}
for _, fa in ipairs(faelle) do
  for _, fe in ipairs({ { 800, 480 }, { 784, 316 } }) do
    local w, maxW, maxP, z, absturz = lauf(fa[1], fe)
    pruefe(not absturz and w.studioZustand == "geladen" and gleich(z, fa[2]),
      string.format("%s %dx%d: %s (erwartet %s)", fa[1], fe[1], fe[2], txt(z), txt(fa[2])))
    messung(string.format("%s %dx%d: wakeup höchstens %d, paint höchstens %d Befehle", fa[1], fe[1], fe[2], maxW, maxP))
    if fa[1] == "p01_kaputte_png.lua" and fe[1] == 800 then
      local nur = #masken == 2
      for _, p in ipairs(masken) do if not (p:find("akku_48.png", 1, true) or p:find("uhr_48.png", 1, true)) then nur = false end end
      pruefe(nur, "p01: loadMask nur für akku_48 und uhr_48 (" .. #masken .. " Aufrufe)")
      local da = false
      for _, z in ipairs(zeilen) do if z:find("Studio: 8 Symbole fehlen", 1, true) or z:find("Studio: 8 symbols missing", 1, true) then da = true end end
      pruefe(da, "p01: Hinweis «Studio: 8 Symbole fehlen»")
    end
    if fa[1] == "p07_namen.lua" and fe[1] == 800 then
      local gut = true
      for _, p in ipairs(geoeffnet) do
        if p ~= "SCRIPTS:/studio/symbole/aaaaaaaaaaaaaaaaaaaaaaaa_48.png" and p ~= "SCRIPTS:/studio/symbole/akku_48.png" then gut = false print("  geöffnet: " .. p) end
      end
      pruefe(gut, "p07: io.open nur für die zwei gültigen Namen")
    end
  end
end

-- Test 11: Format-1-Datei mit Format-2-Feldern: Felder überlesen, keine Symbole, kein Schmuck
local w11, mw, mp = lauf("p11_format1.lua", { 800, 480 })
print_("  p11: Zustand " .. tostring(w11.studioZustand) .. ", sym " .. tostring(w11.sym) .. ", Masken " .. #masken .. ", wakeup " .. mw .. ", paint " .. mp)
messung("p11 800x480: wakeup höchstens " .. mw .. ", paint höchstens " .. mp .. " Befehle")
pruefe(w11.studioZustand == "geladen" and w11.sym == nil and #masken == 0,
  "p11 (Format 1): geladen, keine Symbole/kein Schmuck, Bild wie v1")

-- Test 15 mit Displaybreite 640: alle 48-px-Dateien abgewiesen ausser fremdkante_48 (38 × 38)
BREITE = 640
local _, _, _, z15 = lauf("p01_kaputte_png.lua", { 630, 258 })
pruefe(gleich(z15, { 1, 9, 0 }), "p01 bei 640 px: " .. txt(z15) .. " (erwartet 1 / 9 / 0)")
BREITE = 800

-- Test 13: Modellwechsel 10 × hin und her (p12 64 px, p06 24 px): Lua-Speicher wächst nicht dauerhaft
collectgarbage("collect")
local speicher = {}
for i = 1, 10 do
  lauf(i % 2 == 1 and "p12_voll.lua" or "p06_100_symbole.lua", { 800, 480 })
  collectgarbage("collect") collectgarbage("collect")
  speicher[i] = collectgarbage("count")
end
pruefe(speicher[10] < speicher[2] + 40, string.format("13: Modellwechsel, Lua-Speicher nach 2./10. Wechsel %.0f / %.0f KB", speicher[2], speicher[10]))

-- fehlender Sensor in einem Studio-Platz zeichnet «---» (Format 1 und 2, alle Darstellungen ausser Status)
local function esc(t) return '"' .. t:gsub(".", function(c) return "\\" .. c:byte() end) .. '"' end
for _, fm in ipairs({ 1, 2 }) do
  for _, da in ipairs({ "zahl", "balken_w", "balken_s", "kurve", "ring" }) do
    local f = io_open(tmp .. "/fehlt.lua", "w")
    f:write("return { format = " .. fm .. ", ansichten = { { breite = 800, hoehe = 480, plaetze = { { x = 10, y = 70, b = 380, h = 200, w = "
      .. esc("sensor:0B50:0") .. ", darstellung = " .. esc(da) .. " } } } } }")
    f:close()
    kopiere(tmp .. "/fehlt.lua", ZIEL)
    W, H = 800, 480
    local K = assert(loadfile("kern.lua"))()
    local w = K.neu() K.lies(w)
    for k = 1, 60 do T = T + 0.2 K.wecke(w) end
    local texte, alt = {}, lcd.drawText
    lcd.drawText = function(x, y, t) texte[#texte + 1] = tostring(t) end
    K.zeichne(w)
    lcd.drawText = alt
    local gefunden = false
    for _, t in ipairs(texte) do if t == "---" then gefunden = true end end
    pruefe(w.studioZustand == "geladen" and gefunden, "fehlender Sensor, Format " .. fm .. ", " .. da .. ": zeigt «---»")
  end
end

-- ohne Studio-Datei: nichts geladen, kein Symbol-Baustein
local w0, m0w, m0p = lauf(nil, { 800, 480 })
messung("ohne Studio-Datei 800x480: wakeup höchstens " .. m0w .. ", paint höchstens " .. m0p .. " Befehle (Grundlast)")
pruefe(w0.studioZustand == "fehlt" and w0.sym == nil, "ohne Studio-Datei: kein studio_symbole geladen")

for _, m in ipairs(messungen) do print_("MESSUNG " .. m) end
os.execute("rm -rf '" .. tmp .. "'")
print_(fehler == 0 and "ERGEBNIS: kein Fehler" or ("ERGEBNIS: " .. fehler .. " Fehler"))
os.exit(fehler == 0 and 0 or 1)
