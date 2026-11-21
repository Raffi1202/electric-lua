-- Electric: Speicher beim Modellwechsel freigeben (Auftrag 21.11.2026). Läuft über main.lua wie in Ethos.
-- Aufruf aus dem Repo-Ordner:  /opt/homebrew/opt/lua@5.4/bin/lua test/speicher-test.lua
-- Prüft: zwei Instanzen teilen denselben Kern; fällt eine weg, läuft die andere weiter; fallen alle weg, sammelt die
-- Müllabfuhr den Kern ein (es bleiben höchstens 20 KB); eine neue Instanz danach lädt den Kern neu und läuft.
local quelle = arg[0]:gsub("test/speicher%-test%.lua$", "") .. "src/electric"
local tmp = os.tmpname()
os.remove(tmp)
assert(os.execute("mkdir -p '" .. tmp .. "/daten' && cp '" .. quelle .. "'/*.lua '" .. tmp .. "/'"))
local ordner = tmp .. "/"

local fehler = 0
local function pruefe(ok, text)
  print((ok and "ok     " or "FEHLER ") .. text)
  if not ok then fehler = fehler + 1 end
end

local T = 0
os.clock = function() return T end
system = { getVersion = function() return { simulation = false, board = "X18RS", version = "26.2.0" } end,
  playFile = function() end, playNumber = function() end, playTone = function() end, getSource = function() return nil end }
model = { name = function() return "TEST" end, path = function() return "models/test.bin" end, dirty = function() end }
lcd = { isVisible = function() return false end, invalidate = function() end }
storage = { read = function() return nil end, write = function() end }
UNIT_PERCENT, UNIT_VOLT, UNIT_MILLIAMPERE_HOUR = 1, 2, 3
local alt = io.open
io.open = function(p, m) return alt((p:sub(1, 1) == "/" and "" or ordner) .. p, m) end
local laden = loadfile
loadfile = function(p) return laden((p:sub(1, 1) == "/" and "" or ordner) .. p) end
local reg
system.registerWidget = function(t) reg = t end
local druck = print
print = function() end                                     -- Meldungen des Widgets nicht ausgeben
local function sag(...) druck(...) end
local m = assert(loadfile("main.lua"))()
m.init()
local function gc() collectgarbage() collectgarbage() end
gc()
local m0 = collectgarbage("count")
local w1, w2 = reg.create(), reg.create()
for _ = 1, 30 do T = T + 0.05 reg.wakeup(w1) reg.wakeup(w2) end
reg.read(w1)
local schwach = setmetatable({ k = w1.kern }, { __mode = "v" })
print = sag
pruefe(w1.kern ~= nil and w1.kern == w2.kern and not w1.fehler and not w2.fehler, "zwei Instanzen teilen denselben Kern")
gc()
local mit = collectgarbage("count") - m0
w1 = nil
gc()
pruefe(schwach.k ~= nil, "eine Instanz weg: Kern bleibt für die andere")
print = function() end
for _ = 1, 10 do T = T + 0.05 reg.wakeup(w2) end
print = sag
pruefe(not w2.fehler, "die andere Instanz läuft weiter")
w2 = nil
gc()
local bleibt = collectgarbage("count") - m0
pruefe(schwach.k == nil and bleibt <= 20, string.format("alle Instanzen weg: Kern frei, belegt mit 2 Instanzen +%.1f KB, bleibt %.1f KB (<= 20)", mit, bleibt))
print = function() end
local w3 = reg.create()
for _ = 1, 10 do T = T + 0.05 reg.wakeup(w3) end
print = sag
pruefe(w3.kern ~= nil and not w3.fehler, "neue Instanz nach der Freigabe lädt den Kern neu und läuft")

os.execute("rm -rf '" .. tmp .. "'")
print(fehler == 0 and "ERGEBNIS: kein Fehler" or ("ERGEBNIS: " .. fehler .. " Fehler"))
os.exit(fehler == 0 and 0 or 1)
