-- Electric: Update-Test auf dem Mac (ohne Simulator). Prüft, dass eine neue Fassung die Zuweisungen und Einstellungen
-- einer älteren behält:
--  1. Widget-Speicher (Quellen nach Reihenfolge) in jedem Format aus felder.lua M.FORMATE wird gelesen.
--  2. Eine Datei daten/<Modell>.txt einer älteren Fassung (weniger Zeilen, unbekannte Zeilen) wird gelesen,
--     fehlende Werte bekommen den Werkwert, Flüge und Zähler bleiben.
-- Aufruf: /opt/homebrew/opt/lua@5.4/bin/lua test/update-test.lua src/electric
-- Kommt eine Quelle dazu (FORMAT 2), hier einen Fall für Format 1 -> 2 ergänzen: alte 18 Quellen müssen bleiben.
local ordner = arg[1] or "src/electric"
local fehler = 0
local function pruef(bed, text)
  if not bed then fehler = fehler + 1 print("FEHLER: " .. text) end
end

-- Ethos-Ersatz
local function quelle(name) return { value = function() return 1 end, name = function() return name end, category = function() return 1 end } end
CATEGORY_NONE = 0
local SPEICHER, LESE = {}, 0
storage = {
  read = function() LESE = LESE + 1 return SPEICHER[LESE] end,         -- nach Reihenfolge, der Schlüssel zählt nicht
  write = function(_, v) SPEICHER[#SPEICHER + 1] = v end,
}
local DATEI = nil
io.open = function(_, modus)
  if modus == "w" then
    return { write = function(_, s) DATEI = s end, close = function() end }
  end
  if not DATEI then return nil end
  local pos = 1
  return { read = function(_, n) local s = DATEI:sub(pos, pos + n - 1) pos = pos + n return s end, close = function() end }
end
model = { path = function() return "models/test.bin" end, name = function() return "TEST" end }

local F = assert(loadfile(ordner .. "/felder.lua"))()
local q = F.quellen()

-- 1. jedes bekannte Format lesen
for fmt, anz in pairs(F.FORMATE) do
  SPEICHER, LESE = { fmt }, 0
  for i = 1, anz do SPEICHER[#SPEICHER + 1] = quelle("Q" .. i) end
  if fmt >= 2 then SPEICHER[#SPEICHER + 1] = "SD:/scripts/studio/X.electric.lua" end   -- 0.7.0: Wahl Studio-Layout
  SPEICHER[#SPEICHER + 1] = fmt
  local w = { name = "Electric" }
  DATEI = nil
  local gefunden = F.lies(w)
  pruef(gefunden, "Format " .. fmt .. ": nichts gefunden")
  for i = 1, anz do
    local v = w.cfg[q[i]]
    pruef(v and v:name() == "Q" .. i, "Format " .. fmt .. ": Quelle " .. q[i] .. " verloren")
  end
  pruef(w.lay == (fmt >= 2 and "SD:/scripts/studio/X.electric.lua" or ""), "Format " .. fmt .. ": Wahl Studio-Layout falsch (" .. tostring(w.lay) .. ")")
  -- zurückschreiben und wieder lesen (Ethos liest nach Reihenfolge): alles bleibt
  SPEICHER, LESE = {}, 0
  F.schreibe(w)
  local w2 = { name = "Electric" }
  F.lies(w2)
  local gleich = w2.lay == w.lay
  for i = 1, anz do gleich = gleich and w2.cfg[q[i]] == w.cfg[q[i]] end
  pruef(gleich, "Format " .. fmt .. " -> " .. F.FORMAT .. ": Schreiben und Lesen verliert etwas")
end
pruef(F.FORMATE[F.FORMAT] == #q, "FORMATE[FORMAT] muss der Zahl der Quellen entsprechen (" .. #q .. ")")

-- unbekanntes Format: nichts übernehmen, kein Absturz
SPEICHER, LESE = { 99, quelle("X"), 99 }, 0
local w0 = { name = "Electric" }
F.lies(w0)
pruef(w0.cfg.uGes == nil, "unbekanntes Format wurde übernommen")

-- 2. Datei einer älteren Fassung
SPEICHER, LESE = {}, 0
DATEI = "# alt\nakkuart=3\nkapaz=2200\nunbekannt=5\nzelleW=abc\nd_fluege=4.00\nd_mahNull=120.00\n" ..
  "f=1,300,800,9.5,40,700,50,3.70,80,90,60\nf=2,280,750,,,,,,,,\na=3,120,200,2.1,30,500,45,3.80,70,85,70\n"
local w = { name = "Electric" }
F.lies(w)
pruef(w.cfg.akkuart == 3 and w.cfg.kapaz == 2200, "alte Einstellungen verloren")
pruef(w.cfg.zelleW == 350, "unlesbarer Wert bekommt nicht den Werkwert")
pruef(w.cfg.akkuA == 20, "fehlender Wert bekommt nicht den Werkwert")
pruef(w.dauer.fluege == 4 and w.dauer.mahNull == 120, "Zähler verloren")
pruef(#w.liste == 2 and w.liste[1][3] == 800 and w.liste[2][4] == nil, "Flugliste falsch gelesen")
pruef(w.offen and w.offen[1] == 3 and w.offen[8] == 3.8, "offener Flug verloren")

-- 3. Schreiben und wieder lesen ergibt dasselbe
w.akt = w.offen
pruef(F.schreibeDatei(w), "Datei nicht geschrieben")
local w2 = { name = "Electric" }
F.lies(w2)
pruef(w2.cfg.kapaz == 2200 and #w2.liste == 2 and w2.offen and w2.offen[2] == 120, "Schreiben/Lesen nicht gleich")

print(fehler == 0 and "ERGEBNIS: kein Fehler" or ("ERGEBNIS: " .. fehler .. " Fehler"))
os.exit(fehler == 0 and 0 or 1)
