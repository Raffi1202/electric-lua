-- Elektro: Update 0.1.x -> 0.2.0 der Einstellungen in der Datei daten/<Modell>.txt (nicht der Quellen, die prüft
-- update-test.lua). 0.2.0 entfernt «bild», «f7», «f8» und bringt «fGross» (ab Werk 15 = Gas %). War das Fliegerbild
-- aus (bild=0), stand dort Feld 7: dieser Inhalt kommt ins grosse Feld.
-- Aufruf aus dem Repo-Ordner:  /opt/homebrew/opt/lua@5.4/bin/lua test/update-felder-test.lua
local quelle = arg[0]:gsub("test/update%-felder%-test%.lua$", "") .. "src/elektro"
local tmp = os.tmpname()
os.remove(tmp)
assert(os.execute("mkdir -p '" .. tmp .. "/daten' && cp '" .. quelle .. "'/*.lua '" .. tmp .. "/'"))

-- Datei, wie 0.1.6 sie schreibt (gekürzt auf die betroffenen Zeilen, eigene Wahl f1 = 9, Bild aus, 2 Flüge)
local f = assert(io.open(tmp .. "/daten/models_test.txt", "w"))
f:write([[# Elektro: Einstellungen, Zähler und Flüge dieses Modells
akkuart=1
kapaz=2200
f1=9
f2=7
f7=13
f8=14
sprache=0
bild=0
d_fluege=2
f=1,300,2000,40.5,80,1800,55,3.65,90,120,35
f=2,310,2100,41.0,81,1810,55,3.64,91,121,34
]])
f:close()

os.clock = function() return 0 end
system = { getVersion = function() return { simulation = false } end, playFile = function() end,
  playNumber = function() end, playTone = function() end, getSource = function() return nil end }
model = { name = function() return "TEST" end, path = function() return "models/test.bin" end, dirty = function() end }
lcd = { isVisible = function() return false end, invalidate = function() end }
storage = { read = function() return nil end, write = function() end }
local alt = io.open
io.open = function(p, m) return alt((p:sub(1, 1) == "/" and "" or (tmp .. "/")) .. p, m) end
local laden = loadfile
loadfile = function(p) return laden((p:sub(1, 1) == "/" and "" or (tmp .. "/")) .. p) end

local fehler = 0
local function pruefe(ok, text)
  print((ok and "ok     " or "FEHLER ") .. text)
  if not ok then fehler = fehler + 1 end
end

local K = assert(loadfile("kern.lua"))()
K.NAME = "Elektro"
local w = K.neu()
K.lies(w)
pruefe(w.gelesen == true, "Datei gelesen")
pruefe(w.cfg.f1 == 9 and w.cfg.f2 == 7, "eigene Feldwahl bleibt (f1 = 9, f2 = 7)")
pruefe(w.cfg.kapaz == 2200, "Kapazität bleibt")
pruefe(w.cfg.fGross == 13, "Bild war aus: grosses Feld übernimmt Feld 7 (13 = BEC)")
pruefe(w.cfg.f7 == nil and w.cfg.f8 == nil and w.cfg.bild == nil, "alte Einstellungen f7, f8, bild nicht mehr da")
pruefe(#w.liste == 2 and w.dauer.fluege == 2, "Flugliste und Zähler bleiben")
local F = assert(loadfile("felder.lua"))()
F.schreibeDatei(w)
local t = alt(tmp .. "/daten/models_test.txt"):read("a")
pruefe(t:find("\nfGross=13") ~= nil and t:find("\nbild=") == nil and t:find("\nf7=") == nil, "neu geschrieben ohne alte Zeilen")

-- zweiter Fall: Bild war an -> grosses Feld ab Werk Gas %
local g = alt(tmp .. "/daten/models_test.txt", "w")
g:write("akkuart=1\nf7=13\nbild=1\n")
g:close()
w = K.neu()
K.lies(w)
pruefe(w.cfg.fGross == 15, "Bild war an: grosses Feld ab Werk Gas % (15)")

os.execute("rm -rf '" .. tmp .. "'")
print(fehler == 0 and "ERGEBNIS: kein Fehler" or ("ERGEBNIS: " .. fehler .. " Fehler"))
os.exit(fehler == 0 and 0 or 1)
