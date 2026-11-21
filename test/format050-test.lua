-- Electric 0.6.0: liest das gespeicherte Format von Elektro 0.5.0 unverändert (Umbenennung, Modelle werden auf der
-- Funke von «elektro» auf den neuen Schlüssel umgestellt, der Widget-Speicher bleibt stehen).
-- Aufruf aus dem Repo-Ordner:  /opt/homebrew/opt/lua@5.4/bin/lua test/format050-test.lua
-- Prüft: Widget-Speicher FORMAT 1 mit 18 Quellen in der Reihenfolge von 0.5.0 (fest im Test), Lesen eines so
-- geschriebenen Speichers, und die Datei daten/<Modell>.txt im Aufbau von 0.5.0.
local quelle = arg[0]:gsub("test/format050%-test%.lua$", "") .. "src/electric/"
local fehler = 0
local function pruefe(ok, text)
  print((ok and "ok     " or "FEHLER ") .. text)
  if not ok then fehler = fehler + 1 end
end

-- Reihenfolge der Quellen im Widget-Speicher in Elektro 0.5.0 (q1 … q18), abgeschrieben aus 0.5.0, nie ändern
local FOLGE_050 = { "uGes", "zellen", "strom", "mah", "proz", "rpm", "temp", "bec", "hoehe", "vario", "speed", "rssi", "lq",
  "swMotor", "swAnsage", "sw1", "sw2", "gas" }

local tmp = os.tmpname()
os.remove(tmp)
assert(os.execute("mkdir -p '" .. tmp .. "/daten'"))
model = { name = function() return "TEST" end, path = function() return "models/test.bin" end }
local alt = io.open
io.open = function(p, m) return alt((p:sub(1, 1) == "/" and "" or tmp .. "/") .. p, m) end
os.mkdir = function() return true end
local F = assert(loadfile(quelle .. "felder.lua"))()

pruefe(F.FORMAT == 1 and F.FORMATE[1] == 18, "FORMAT 1 mit 18 Quellen wie 0.5.0")
local q = F.quellen()
local gleich = #q == #FOLGE_050
for i, n in ipairs(FOLGE_050) do if q[i] ~= n then gleich = false end end
pruefe(gleich, "Reihenfolge der Quellen gleich wie 0.5.0 (" .. table.concat(q, ",") .. ")")

-- Speicher, wie ihn 0.5.0 geschrieben hat: fmt, q1..q18, ende
local function quell(n) return { n = n, value = function() return 1 end, name = function(s) return s.n end } end
local SP = { fmt = 1, ende = 1 }
for i, n in ipairs(FOLGE_050) do SP["q" .. i] = (i % 3 == 0) and 0 or quell("Q-" .. n) end  -- jede 3. Quelle leer (0)
storage = { read = function(k) return SP[k] end, write = function(k, v) SP[k] = v end }
-- Datei wie 0.5.0: Zahlen, Ja/Nein (auch «auch bei Motor aus»), Zähler, Flüge
local f = assert(io.open(F.datei(), "w"))
f:write("# Elektro: Einstellungen\nkapaz=3300\nzellenzahl=6\nakkuW=35\ntempMot=0\nlqMot=1\nansage=0\nsw1Name=STABI\n",
  "d_fluege=12.00\nd_mahNull=0.00\nf=1,412,3110,66.2,88,1950,57,3.62,96,138,31\n")
f:close()
local w = { name = "Electric" }
pruefe(F.lies(w) == true, "Speicher und Datei von 0.5.0 als vorhanden erkannt")
local ok = true
for i, n in ipairs(FOLGE_050) do
  local v = w.cfg[n]
  if i % 3 == 0 then ok = ok and v == nil else ok = ok and type(v) == "table" and v.n == "Q-" .. n end
end
pruefe(ok, "alle 18 Quellen an der richtigen Stelle gelesen (leere bleiben leer)")
local c = w.cfg
pruefe(c.kapaz == 3300 and c.zellenzahl == 6 and c.akkuW == 35 and c.tempMot == false and c.lqMot == true
  and c.ansage == false and c.sw1Name == "STABI", "Zahlen und Ja/Nein aus der Datei von 0.5.0 gelesen")
pruefe(w.dauer.fluege == 12 and #w.liste == 1 and w.liste[1][3] == 3110, "Zähler und Flugliste aus der Datei von 0.5.0 gelesen")
-- Zurückschreiben: gleiches Format
SP = {}
F.schreibe(w)
pruefe(SP.fmt == 1 and SP.ende == 1 and SP.q1 and SP.q1.n == "Q-uGes" and SP.q3 == 0 and SP.q18 == 0 and SP.q19 == nil,
  "Schreiben bleibt im Format von 0.5.0 (fmt 1, q1..q18)")

-- 0.6.1: keine Datei im neuen Ordner, aber im alten scripts/elektro/daten: wird gelesen, nie gelöscht
assert(os.execute("mkdir -p '" .. tmp .. "/SCRIPTS:/elektro/daten' && mv '" .. tmp .. "/" .. F.datei() .. "' '" .. tmp .. "/SCRIPTS:/elektro/" .. F.datei() .. "'"))
print = function() end
local w2 = { name = "Electric" }
local da = F.lies(w2)
print = _G.druck or io.write and function(...) io.write(table.concat({ ... }, "\t") .. "\n") end
pruefe(da and w2.datenAlt and w2.cfg.kapaz == 3300 and #w2.liste == 1, "alte Datei aus scripts/elektro/daten übernommen")
pruefe(alt(tmp .. "/SCRIPTS:/elektro/" .. F.datei(), "r") ~= nil, "alte Datei bleibt stehen (nie gelöscht)")
pruefe(F.schreibeDatei(w2) and alt(tmp .. "/" .. F.datei(), "r") ~= nil, "Schreiben geht in den neuen Ordner")
os.execute("rm -rf '" .. tmp .. "'")
print(fehler == 0 and "ERGEBNIS: kein Fehler" or ("ERGEBNIS: " .. fehler .. " Fehler"))
os.exit(fehler == 0 and 0 or 1)
