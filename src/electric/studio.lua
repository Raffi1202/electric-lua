-- Electric: Studio-Datei je Modell lesen, prüfen und anwenden (Lua-Studio-Format v1).
-- Wird nur geladen, solange ein Modell geladen wird bzw. eine Studio-Datei gilt. Alles in Schritten: Der Kern ruft
-- M.schritt(w) je wakeup auf, bis es «fertig» meldet (Befehlsgrenze am Sender).
-- Dateien: SCRIPTS:/studio/<Kennung>.electric.lua (schreibt nur das Studio), .funke.lua (schreibt nur dieses Lua),
-- .info.json (schreibt nur dieses Lua, liest nur das Studio).
local M = {}
local floor = math.floor

M.ORDNER = "SCRIPTS:/studio/"
-- 0.7.0: Suchorte der Studio-Datei, in dieser Reihenfolge. .funke.lua und Info-Datei bleiben in M.ORDNER.
M.ORTE = { "SCRIPTS:/studio/", "SD:/scripts/studio/", "RADIO:/scripts/studio/" }
M.LUA = "electric"
M.LUA_ALT = "elektro"   -- Name bis 0.5.0: eine Studio-Datei <Kennung>.elektro.lua wird noch gelesen (Übergang)
M.FORMAT = 2           -- höchstes Format, das diese Version liest (Format 2 seit 0.4.0)
M.FORMATE = { 1, 2 }   -- für die Info-Datei

-- ===== Referenz studioLaden, WÖRTLICH aus «Lua-Studio-Format v1 - Referenz studio_laden.lua» =====
local MAX_BYTE = 16384
local MAX_ELEMENTE = 1200   -- Kommas + «=» + «{» ausserhalb von Texten (Befehle und Speicher, gemessen)
local MAX_TABELLEN = 240    -- «{» ausserhalb von Texten (Speicher)
local SCHLUESSELWOERTER = { "and", "break", "do", "else", "elseif", "end", "for", "function", "goto", "if", "in",
  "local", "nil", "not", "or", "repeat", "then", "until", "while" }

local function studioLaden(pfad, hoechstesFormat)
  local ok, f = pcall(io.open, pfad, "r")
  if not ok or not f then return nil, "fehlt" end
  local teile, n = {}, 0
  while true do
    local ok2, s = pcall(f.read, f, 512)
    if not ok2 then f:close() return nil, "kaputt" end
    if not s or #s == 0 then break end
    n = n + #s
    if n > MAX_BYTE then f:close() return nil, "kaputt" end
    teile[#teile + 1] = s
  end
  f:close()
  local s = table.concat(teile)
  teile = nil
  -- 1. Anfang: nur «return {»
  if not s:find("^%s*return%s*{") then return nil, "kaputt" end
  -- 2. erlaubte Bytes: Buchstaben, Ziffern, Leerraum, _ { } [ ] = , " \ - .
  if s:find('[^%w%s_{}%[%]=,"\\%-%.]') then return nil, "kaputt" end
  -- 2b. nach «\» nur Ziffern (Dezimal-Escapes); sperrt \" \z \x \u{…}, die die Textgrenzen verschieben könnten
  if s:find("\\%D") then return nil, "kaputt" end
  -- 3. verbotene Folgen: Verkettung, Kommentar, lange Texte
  if s:find("..", 1, true) or s:find("--", 1, true) or s:find("[[", 1, true) then return nil, "kaputt" end
  -- 4. Schlüsselwörter ausserhalb von Texten (Texte enthalten nie ein rohes ", das Studio schreibt \34)
  local ohneTexte = s:gsub('"[^"]*"', '""')
  for _, w in ipairs(SCHLUESSELWOERTER) do
    if ohneTexte:find("%f[%w_]" .. w .. "%f[^%w_]") then return nil, "kaputt" end
  end
  -- 4b. «-» nur als Vorzeichen direkt vor einer Ziffer, nach = , { [ (keine Rechenketten)
  if ohneTexte:find("%-%s*%D") or ohneTexte:find("[^=,{%[%s]%s*%-") then return nil, "kaputt" end
  local _, anzahlReturn = ohneTexte:gsub("%f[%w_]return%f[^%w_]", "")
  if anzahlReturn ~= 1 then return nil, "kaputt" end
  -- 4b2. kein Name und keine Zahl länger als 24 Zeichen (Speicher: lange Schlüssel)
  if ohneTexte:find(string.rep("[%w_]", 25)) then return nil, "kaputt" end
  -- 4c. reine Daten: Namen nur als Schlüssel direkt vor «=», sonst nur true/false (kein _ENV, keine Variablen, keine Aufrufe)
  if ohneTexte:find("==", 1, true) then return nil, "kaputt" end
  local rest = ohneTexte:gsub("^%s*return", "")
  rest = rest:gsub("[%a_][%w_]*%s*=", "=")
  rest = rest:gsub("%f[%w_]true%f[^%w_]", "")
  rest = rest:gsub("%f[%w_]false%f[^%w_]", "")
  local nameGefunden = rest:find("[%a_]")
  rest = nil
  if nameGefunden then return nil, "kaputt" end
  -- 4d. nach «[» nur ein Text, eine Zahl oder ein Vorzeichen (keine Ausdrücke als Schlüssel)
  if ohneTexte:find('%[%s*[^%d"%-]') then return nil, "kaputt" end
  -- 5. Grösse der Tabelle begrenzen (Befehlsgrenze beim Aufbau)
  local _, kommas = ohneTexte:gsub(",", "")
  local _, gleich = ohneTexte:gsub("=", "")
  local _, klammern = ohneTexte:gsub("{", "")
  if klammern > MAX_TABELLEN or kommas + gleich + klammern > MAX_ELEMENTE then return nil, "kaputt" end
  -- 6. laden ohne Umgebung, nur Text
  -- Zwischentexte der Prüfung freigeben, bevor übersetzt wird (Speicher-Spitze)
  ohneTexte = nil
  collectgarbage("collect")
  local ok3, chunk = pcall(load, s, "=studio", "t", {})
  s = nil
  collectgarbage("collect")
  if not ok3 or type(chunk) ~= "function" then return nil, "kaputt" end
  local ok4, d = pcall(chunk)
  if not ok4 or type(d) ~= "table" or math.type(d.format) ~= "integer" or d.format < 1 then return nil, "kaputt" end
  if d.format > hoechstesFormat then return nil, "zuNeu" end
  return d
end
-- ===== Ende Referenz =====
M.studioLaden = studioLaden

-- Werte dieses Luas (wie studio/beschreibung.json): Feld in w.v (oder Sonderfall), Einheit, Stellen, min, max,
-- Grenzrichtung (nur überwachte Werte), Name de/en. Die Prüfung test/studio-test.lua vergleicht mit der JSON-Datei.
M.WERTE = {
  akku_proz = { "proz", "%", 0, 0, 100, "unter", "Akku %", "Battery %", u = "akku" },
  strom = { "strom", "A", 0, 0, 120, "ueber", "Strom", "Current", u = "strom" },
  drehzahl = { "rpm", "U/min", 0, 0, 12000, nil, "Drehzahl", "RPM" },
  reglertemp = { "temp", "°C", 0, 0, 100, "ueber", "Reglertemp.", "ESC temp.", u = "temp" },
  zelle = { "zelle", "V", 2, 3.3, 4.2, "unter", "Zelle", "Cell", u = "zelle" },
  zelle_diff = { "zDiff", "V", 2, 0, 0.5, "ueber", "Zellendifferenz", "Cell difference", u = "diff" },
  spannung = { "uGes", "V", 1, 0, 60, nil, "Gesamtspannung", "Pack voltage" },
  verbraucht = { "mah", "mAh", 0, 0, 5000, nil, "Verbraucht", "Used" },
  verbraucht_proz = { "kap", "%", 0, 0, 100, "ueber", "Verbraucht %", "Used %", u = "kap" },
  leistung = { "leistung", "W", 0, 0, 3000, nil, "Leistung", "Power" },
  energie = { "wh", "Wh", 1, 0, 100, nil, "Energie", "Energy" },
  hoehe = { "hoehe", "m", 0, 0, 200, "ueber", "Höhe", "Altitude", u = "hoehe" },
  vario = { "vario", "m/s", 1, -5, 5, nil, "Vario", "Vario" },
  speed = { "speed", "km/h", 0, 0, 200, nil, "Speed", "Speed" },
  rssi = { "rssi", "dB", 0, 0, 100, "unter", "Empfang (RSSI)", "Signal (RSSI)", u = "rssi" },
  lq = { "lq", "%", 0, 0, 100, "unter", "Empfang (LQ)", "Link quality", u = "lq" },
  bec = { "bec", "V", 1, 0, 8.4, "unter", "BEC", "BEC", u = "bec" },
  flugzeit = { "!flugzeit", "s", 0, 0, 600, nil, "Flugzeit", "Flight time" },
  gas_proz = { "gasP", "%", 0, 0, 100, nil, "Gas %", "Throttle %" },
  fluege = { "!fluege", "", 0, 0, 100, nil, "Flüge", "Flights" },
  motor = { "!motor", "", 0, 0, 1, nil, "Motor", "Motor", status = true },
}
-- überwachte Werte: Studio-Schlüssel -> Name in kern.lua (UEBERWACHT, cfg <name>W / <name>A) und Teiler im cfg
M.UEBERWACHT = { akku = { "akku_proz", 1 }, zelle = { "zelle_diff", 100 }, diff = { "zelle_diff", 100 },
  temp = { "reglertemp", 1 }, strom = { "strom", 1 }, kap = { "verbraucht_proz", 1 }, bec = { "bec", 10 },
  hoehe = { "hoehe", 1 }, rssi = { "rssi", 1 }, lq = { "lq", 1 } }
M.UEBERWACHT.zelle[1] = "zelle"

-- Darstellungsarten und Mindestgrösse (X18RS, 784 Pixel breit), Abschnitt 7
M.DARST = { zahl = { 90, 50 }, ring = { 110, 110 }, balken_w = { 140, 40 }, balken_s = { 50, 110 },
  kurve = { 180, 90 }, status = { 120, 40 } }

-- Studio-Name einer Einstellung (klein mit _) -> Name in felder.lua
local function luaName(s) return (s:gsub("_(%l)", function(c) return c:upper() end)) end
M.luaName = luaName

-- Modellkennung (Abschnitt 2.1), byteweise
function M.kennung()
  local ok, n = pcall(model.name)
  local k = ((ok and type(n) == "string") and n or ""):gsub("[^%w]", "_"):sub(1, 32)
  if k == "" then k = "modell" end
  return k
end

local function endlich(v) return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge end
local function ganz(v) return math.type(v) == "integer" end
local function kuerze(t, n)
  if type(t) ~= "string" then return nil end
  if #t <= n then return t end
  local e = n
  while e > 0 do
    local b = t:byte(e + 1)
    if b == nil or b < 0x80 or b > 0xBF then break end   -- nur vor einem Byte kürzen, das ein Zeichen beginnt
    e = e - 1
  end
  return t:sub(1, e)
end
M.kuerze = kuerze
local function farbe(f)
  if type(f) ~= "table" or #f ~= 3 then return nil end
  for i = 1, 3 do
    if not ganz(f[i]) or f[i] < 0 or f[i] > 255 then return nil end
  end
  return { f[1], f[2], f[3] }
end

-- Wert-Schlüssel nach 6.6. Rückgabe: Art ("lua", "sensor", "kanal", "leer") und Teile, sonst nil.
function M.schluessel(k)
  if type(k) ~= "string" then return nil end
  if k == "leer" then return "leer" end
  local s = k:match("^lua:([%w_]+)$")
  if s then return M.WERTE[s] and "lua" or nil, s end
  local a, sub, ph = k:match("^sensor:(%x%x%x%x):(%d+):?(%d*)$")
  if a and not a:find("%l") then
    local p = ph ~= "" and tonumber(ph) or nil
    if p and p > 27 then return nil end
    return "sensor", tonumber(a, 16), tonumber(sub), p
  end
  local n = k:match("^kanal:(%d+)$")
  if n and tonumber(n) >= 1 and tonumber(n) <= 64 then return "kanal", tonumber(n) end
  return nil
end

-- ===== Prüfen (Abschnitt 6). Jede Prüfung zählt Fehler und schreibt je Fehler eine Zeile ins Log. =====
local function fehler(J, wo, warum)
  J.fehler = J.fehler + 1
  print("Electric: Studio-Datei " .. J.datei .. ": " .. wo .. ": " .. warum)
end

-- Einstellungen: nur die, die felder.lua kennt und die keine Quelle, kein Grenzwert und kein Feld sind
-- Befehlsgrenze (Format 12.2: unter 5000 je Aufruf auch für die grösste zulässige Datei): Tabellen werden in Stücken
-- zu JE_EINTRAG Einträgen geprüft (0.3.2; vorher z. B. 100 Wert-Anpassungen = 12 340 Befehle in einem Aufruf).
-- Format 2, Regel 7.1: höchstens 8 Einträge je Aufruf; 7.2: werte, grenzen, einstellungen höchstens 48 Einträge.
local JE_EINTRAG = 8
local MAX_LISTE = 48
-- Rückgabe true = fertig. Stand in J.teilK (letzter Schlüssel), next statt pairs (kein __pairs).
local function teile(J, quelle, wo, f)
  if quelle == nil then return true end
  if type(quelle) ~= "table" then fehler(J, wo, "keine Tabelle") return true end
  local k, e
  if J.teilK == nil then k, e = next(quelle) else k, e = next(quelle, J.teilK) end
  local n = 0
  while k ~= nil do
    f(k, e)
    n = n + 1
    if n >= JE_EINTRAG then J.teilK = k return false end
    k, e = next(quelle, k)
  end
  J.teilK = nil
  return true
end

local function einstEintrag(J, F, s, v, ziel)
  do
    local f = type(s) == "string" and F.feld(luaName(s))
    if f and F.studioEinstellung(f[1]) then
      local art, gut = f[2], nil
      if art == "z" then gut = ganz(v) and v >= f[5] and v <= f[6]
      elseif art == "b" then gut = type(v) == "boolean"
      elseif art == "t" then gut = type(v) == "string" and F.eigen(v) ~= nil
      elseif art == "w" then
        if ganz(v) then for _, a in ipairs(f[5]) do if a[2] == v then gut = true end end end
      end
      if gut then ziel[f[1]] = (art == "t") and F.eigen(v) or v
      else fehler(J, "einstellungen." .. tostring(s), "ungültig, Werkwert") end
    end
  end
end

local function werteEintrag(J, k, e, ziel)
  do
    local art, s = M.schluessel(k)
    if not art or art == "leer" or type(e) ~= "table" then
      fehler(J, "werte." .. tostring(k), "Eintrag verworfen")
    elseif art == "lua" and M.WERTE[s].u and type(e.faktor) == "number" and e.faktor < 0 then
      -- überwachter Wert mit negativem Faktor: die Alarmrichtung würde sich drehen, darum ganzer Eintrag verworfen
      fehler(J, "werte." .. k .. ".faktor", "negativ bei überwachtem Wert, Eintrag verworfen")
    else
      local a = { faktor = 1, versatz = 0 }
      if e.faktor ~= nil then
        if endlich(e.faktor) and math.abs(e.faktor) >= 0.0001 and math.abs(e.faktor) <= 10000 then a.faktor = e.faktor
        else fehler(J, "werte." .. k .. ".faktor", "ungültig, 1") end
      end
      if e.versatz ~= nil then
        if endlich(e.versatz) and e.versatz >= -100000 and e.versatz <= 100000 then a.versatz = e.versatz
        else fehler(J, "werte." .. k .. ".versatz", "ungültig, 0") end
      end
      if e.einheit ~= nil then
        if type(e.einheit) == "string" then a.einheit = kuerze(e.einheit, 8) else fehler(J, "werte." .. k .. ".einheit", "kein Text") end
      end
      if e.stellen ~= nil then
        if ganz(e.stellen) and e.stellen >= 0 and e.stellen <= 3 then a.stellen = e.stellen
        else fehler(J, "werte." .. k .. ".stellen", "ungültig") end
      end
      if e.name ~= nil then
        if type(e.name) == "string" then a.name = kuerze(e.name, 24) else fehler(J, "werte." .. k .. ".name", "kein Text") end
      end
      ziel[k] = a
    end
  end
end

-- Grenzen: nur Felder sammeln; die Richtung und die Reihenfolge prüft M.grenzenFertig nach dem Zusammenführen
local function grenzeEintrag(J, k, e, ziel)
  do
    local art = M.schluessel(k)
    if not art or art == "leer" or type(e) ~= "table" then
      fehler(J, "grenzen." .. tostring(k), "Eintrag verworfen")
    else
      local z = ziel[k] or {}
      if e.richtung ~= nil then
        if e.richtung == "unter" or e.richtung == "ueber" then z.richtung = e.richtung
        else z.richtungFalsch = true end
      end
      for _, n in ipairs({ "warnung", "alarm" }) do      -- false = diese Stufe aus (Format 6.5)
        if e[n] ~= nil then
          if e[n] == false or endlich(e[n]) then z[n] = e[n]
          else
            fehler(J, "grenzen." .. k .. "." .. n, "ungültig, Werkgrenze dieser Stufe")
            z[n] = "werk"                               -- überwachter Wert: Werkgrenze; sonst gilt die Stufe als nicht vorhanden
          end
        end
      end
      for _, n in ipairs({ "ansage", "vibration", "aus", "beiMotorAus" }) do   -- beiMotorAus: Format 2, 3.5
        if e[n] ~= nil then
          if type(e[n]) == "boolean" then z[n] = e[n] else fehler(J, "grenzen." .. k .. "." .. n, "kein true/false") end
        end
      end
      ziel[k] = z
    end
  end
end

-- Nach dem Zusammenführen: Richtung und Reihenfolge prüfen. Ergebnis je Schlüssel:
-- { richtung, warnung (oder nil = aus), alarm, ansage, vibration }
local function grenzeFertig(J, k, z, still, r)
  local function f(wo, warum) if not still then fehler(J, wo, warum) end end
  do
    local art, s = M.schluessel(k)
    local def = art == "lua" and M.WERTE[s][6] or nil
    local richtung = z.richtung or def
    local e = { ansage = z.ansage ~= false, vibration = z.vibration ~= false, beiMotorAus = z.beiMotorAus ~= false }
    if def and M.WERTE[s].u and (z.richtungFalsch or richtung ~= def) then
      -- überwachter Electric-Wert mit falscher oder abweichender Richtung: Werkgrenze bleibt (Alarm-Sicherheit)
      f("grenzen." .. k .. ".richtung", "passt nicht zum Wert, Werkgrenze gilt")
      e.werk = true
    elseif z.richtungFalsch or richtung == nil or (def and richtung ~= def) then
      f("grenzen." .. k .. ".richtung", "fehlt oder ungültig, Grenze aus")
      e.aus = true
    elseif z.aus then
      e.aus = true
    else
      e.richtung = richtung
      e.warnung = z.warnung or nil
      e.alarm = z.alarm or nil
      local ueberwacht = def and M.WERTE[s].u
      if e.warnung == "werk" and not ueberwacht then e.warnung = nil end
      if e.alarm == "werk" and not ueberwacht then e.alarm = nil end
      -- Entscheid des Autors (20.11.2026): Eine Studio-Datei schaltet einen überwachten Alarm nie ganz aus, ausser mit
      -- «aus = true». Ein Eintrag ohne Stufe (nur ansage, vibration, beiMotorAus) oder mit beiden Stufen false: Werkgrenze.
      if ueberwacht and type(e.warnung) ~= "number" and type(e.alarm) ~= "number" and e.warnung ~= "werk" and e.alarm ~= "werk" then
        e.werk, e.warnung, e.alarm = true, nil, nil
      end
      if type(e.warnung) == "number" and type(e.alarm) == "number" and ((richtung == "unter" and not (e.alarm < e.warnung))
        or (richtung == "ueber" and not (e.alarm > e.warnung))) then
        f("grenzen." .. k, "Alarm und Warnung vertauscht, nur Alarm gilt")
        e.warnung = nil
      end
    end
    r[k] = e
  end
end
function M.grenzenFertig(J, roh, still)
  local r = {}
  for k, z in pairs(roh) do grenzeFertig(J, k, z, still, r) end
  return r
end

local function pruefePlatz(J, wo, p, br, ho, kurven)
  if type(p) ~= "table" then fehler(J, wo, "kein Platz, verworfen") return nil end
  for _, n in ipairs({ "x", "y", "b", "h" }) do
    if not ganz(p[n]) then fehler(J, wo .. "." .. n, "fehlt oder keine ganze Zahl, Platz verworfen") return nil end
  end
  local darst = p.darstellung
  if darst ~= nil and not M.DARST[darst] then fehler(J, wo .. ".darstellung", "unbekannt, zahl") darst = nil end
  darst = darst or "zahl"
  local art, s = M.schluessel(p.w)
  if not art then fehler(J, wo .. ".w", "unbekannter Wert, Platz verworfen") return nil end
  if darst == "status" and not (art == "lua" and M.WERTE[s].status) then fehler(J, wo .. ".darstellung", "status passt nicht, zahl") darst = "zahl" end
  if darst ~= "status" and art == "lua" and M.WERTE[s].status then darst = "status" end
  if darst == "kurve" and kurven[1] >= 2 then fehler(J, wo, "mehr als 2 Kurven, zahl") darst = "zahl" end
  -- Mindestgrösse (Abschnitt 7): Tabellenwert × breite / 800, gerundet; Bezug immer 800
  local mb = floor(M.DARST[darst][1] * br / 800 + 0.5)
  local mh = floor(M.DARST[darst][2] * br / 800 + 0.5)
  if p.x < 0 or p.y < 0 or p.x + p.b > br or p.y + p.h > ho or p.b < mb or p.h < mh then
    fehler(J, wo, "Lage oder Grösse ungültig, Platz verworfen")
    return nil
  end
  if darst == "kurve" then kurven[1] = kurven[1] + 1 end
  local q = { x = p.x, y = p.y, b = p.b, h = p.h, w = p.w, art = art, s = s, darst = darst, zusatz = "keine", kurveS = 120,
    roh = (J.d and J.d.format == 2) and p or nil }     -- Original-Platz für studio_symbole.lua (nur Format 2)
  if p.titel ~= nil then
    if type(p.titel) == "string" then q.titel = kuerze(p.titel, 24) else fehler(J, wo .. ".titel", "kein Text") end
  end
  if p.min ~= nil or p.max ~= nil then
    if endlich(p.min) and endlich(p.max) and p.max > p.min then q.min, q.max = p.min, p.max
    else fehler(J, wo .. ".min/max", "ungültig, Standard") end
  end
  for _, n in ipairs({ "farbe", "farbeWarn", "farbeAlarm", "hintergrund" }) do
    if p[n] ~= nil then
      q[n] = farbe(p[n])
      if not q[n] then fehler(J, wo .. "." .. n, "ungültig, Standard") end
    end
  end
  if p.zusatz ~= nil then
    if p.zusatz == "keine" or p.zusatz == "min" or p.zusatz == "max" or p.zusatz == "mittel" then q.zusatz = p.zusatz
    else fehler(J, wo .. ".zusatz", "ungültig, keine") end
  end
  if p.kurveS ~= nil then
    if ganz(p.kurveS) and p.kurveS >= 30 and p.kurveS <= 600 then q.kurveS = p.kurveS
    else fehler(J, wo .. ".kurveS", "ungültig, 120") end
  end
  if p.stufen ~= nil then
    local ok = type(p.stufen) == "table" and #p.stufen <= 3
    local st = {}
    if ok then
      for i, e in ipairs(p.stufen) do
        local fb = type(e) == "table" and farbe(e.farbe)
        if not (fb and endlich(e.ab) and (i == 1 or e.ab > st[i - 1].ab)) then ok = false break end
        st[i] = { ab = e.ab, farbe = fb }
      end
    end
    if ok then q.stufen = st else fehler(J, wo .. ".stufen", "ungültig, Liste verworfen") end
  end
  return q
end

-- Eine Ansicht in Teilen prüfen: je Aufruf höchstens JE_AUFRUF Plätze. Rückgabe: true = fertig.
local JE_AUFRUF = 6
local function pruefeAnsicht(J, i, a)
  local wo = "ansichten[" .. i .. "]"
  local A = J.ansicht
  if A == nil then
    if type(a) ~= "table" or not ganz(a.breite) or not ganz(a.hoehe) or a.breite < 100 or a.breite > 1024
      or a.hoehe < 100 or a.hoehe > 1024 or type(a.plaetze) ~= "table" then
      fehler(J, wo, "Ansicht verworfen")
      return true
    end
    A = { r = { breite = a.breite, hoehe = a.hoehe, plaetze = {}, roh = (J.d and J.d.format == 2) and a or nil },
      kurven = { 0 }, k = 0 }
    J.ansicht = A
  end
  local bis = math.min(#a.plaetze, 16, A.k + JE_AUFRUF)
  for k = A.k + 1, bis do
    local q = pruefePlatz(J, wo .. ".plaetze[" .. k .. "]", a.plaetze[k], a.breite, a.hoehe, A.kurven)
    if q then A.r.plaetze[#A.r.plaetze + 1] = q end
  end
  A.k = bis
  if A.k < math.min(#a.plaetze, 16) then return false end
  if #a.plaetze > 16 then fehler(J, wo, "mehr als 16 Plätze, Rest verworfen") end
  local key = A.r.breite .. "x" .. A.r.hoehe
  J.ansichten[key] = J.ansichten[key] or A.r
  J.ansicht = nil
  return true
end

-- ===== Ablauf beim Modellwechsel, ein Schritt je Aufruf =====
-- Rückgabe: nil = läuft noch, sonst das Ergebnis { zustand = "fehlt"|"geladen"|"kaputt"|"zuNeu", ... }
function M.schritt(w, F)
  local J = w.studioJob
  if J == nil then
    J = { stufe = 1, fehler = 0, k = w.testKennung or M.kennung(), t0 = os.clock(), n = 0 }
    J.basis = M.ORDNER .. J.k .. "." .. M.LUA
    J.datei = J.k .. "." .. M.LUA .. ".lua"
    w.studioJob = J                                      -- gleich weiter mit Stufe 1 (ein Schritt weniger)
  end
  J.n = J.n + 1                                          -- Zahl der Schritte, für die Log-Zeile nach dem Laden
  if J.stufe == 1 then                                   -- Studio-Datei suchen und laden, ein Ort je Aufruf
    local d, grund
    local lay = type(w.lay) == "string" and w.lay or ""
    if lay ~= "" and not J.oi then                       -- Wahl im Menü gewinnt (R2.3)
      J.wahl, J.quelle, J.datei = "menue", lay, lay:match("[^/]+$") or lay
      d, grund = studioLaden(lay, M.FORMAT)
      if grund == "fehlt" then print("Electric: chosen studio file missing: " .. lay) J.gewaehltFehlt = true end
    else
      J.wahl = "auto"
      J.oi = (J.oi or 0) + 1
      local ort = M.ORTE[J.oi]
      if ort then
        d, grund = studioLaden(ort .. J.datei, M.FORMAT)
        if grund == "fehlt" then return nil end           -- nächster Ort im nächsten Aufruf
        J.quelle = ort .. J.datei
      else                                                -- Übergang 0.6.0: Datei noch unter dem alten Namen (Elektro)
        local alt = J.k .. "." .. M.LUA_ALT .. ".lua"
        d, grund = studioLaden(M.ORDNER .. alt, M.FORMAT)
        if d then print("Electric: old studio file found (" .. alt .. "), please re-transfer from Lua-Studio") end
        if grund ~= "fehlt" then J.datei, J.quelle = alt, M.ORDNER .. alt end
      end
    end
    if not d then
      J.zustand = grund
      if grund ~= "fehlt" then print("Electric: Studio-Datei " .. J.datei .. ": " .. grund) end
      w.studioJob = nil
      return J
    end
    J.d, J.stufe = d, 2
    return nil
  elseif J.stufe == 2 then                               -- .funke.lua laden, übrig gebliebene .funke.neu
    local fu, grund = studioLaden(J.basis .. ".funke.lua", M.FORMAT)
    -- übrig gebliebene .funke.neu (Strom weg beim Schreiben): nur ohne .funke.lua übernehmen, sonst löschen
    local okO, nf = pcall(io.open, J.basis .. ".funke.neu", "r")
    if okO and nf then
      nf:close()
      local neu = grund == "fehlt" and studioLaden(J.basis .. ".funke.neu", M.FORMAT)
      local okR, r = false, nil
      if neu then okR, r = pcall(os.rename, J.basis .. ".funke.neu", J.basis .. ".funke.lua") end
      if neu and okR and r then fu, grund = neu, nil
      else pcall(os.remove, J.basis .. ".funke.neu") end
    end
    if fu == nil and grund ~= "fehlt" and grund ~= nil then
      J.funkeVerworfen = true
      print("Electric: Studio-Datei " .. J.k .. "." .. M.LUA .. ".funke.lua: " .. tostring(grund) .. ", verworfen")
    end
    J.fu, J.stufe = fu, 3
    return nil
  elseif J.stufe == 3 then                               -- Einstellungen, Werte, Grenzen, in Stücken
    if J.aufg == nil then
      local d, fu = J.d, J.fu
      J.einst, J.werte, J.grenzenRoh, J.funkeEinst, J.funkeGrenzen = {}, {}, {}, {}, {}
      J.aufg = { { "e", d.einstellungen, J.einst, "einstellungen" }, { "w", d.werte, J.werte, "werte" },
        { "g", d.grenzen, J.grenzenRoh, "grenzen" } }
      if fu then
        J.aufg[4] = { "e", fu.einstellungen, J.funkeEinst, "einstellungen", true }
        J.aufg[5] = { "g", fu.grenzen, J.funkeGrenzen, "grenzen", true }
      end
      J.ai3, J.teilK = 1, nil
      return nil
    end
    local a = J.aufg[J.ai3]
    if a == nil then
      J.aufg, J.ai3 = nil, nil
      J.stufe, J.ai, J.ansichten = 4, 0, {}
      return nil
    end
    local datei = J.datei
    if a[5] then J.datei = J.k .. "." .. M.LUA .. ".funke.lua" end
    local ziel, f = a[3], nil
    if a[1] == "e" then f = function(k, e) einstEintrag(J, F, k, e, ziel) end
    elseif a[1] == "w" then f = function(k, e) werteEintrag(J, k, e, ziel) end
    else f = function(k, e) grenzeEintrag(J, k, e, ziel) end end
    a.n = a.n or 0
    local fertig = teile(J, a[2], a[4], function(k, e)
      a.n = a.n + 1
      if a.n <= MAX_LISTE then f(k, e) end            -- Format 2, Regel 7.2: ab dem 49. Eintrag verworfen
    end)
    if fertig and a.n > MAX_LISTE then fehler(J, a[4], (a.n - MAX_LISTE) .. " Einträge über " .. MAX_LISTE .. " verworfen") end
    J.datei = datei
    if fertig then J.ai3 = J.ai3 + 1 end
    return nil
  elseif J.stufe == 4 then                               -- je Aufruf eine Ansicht
    local liste = J.d.ansichten
    if liste ~= nil and type(liste) ~= "table" then fehler(J, "ansichten", "keine Liste") liste = nil end
    if J.ansicht == nil then J.ai = J.ai + 1 end
    local a = liste and liste[J.ai]
    if a ~= nil and J.ai <= 2 then
      pruefeAnsicht(J, J.ai, a)
      return nil
    end
    if liste and #liste > 2 then fehler(J, "ansichten", "mehr als 2, Rest verworfen") end
    J.stufe = 5
    return nil
  end
  -- Stufe 5: zusammenführen (Studio, darüber .funke.lua je Feld), in Stücken (Befehlsgrenze), dann fertig
  local t = J.s5 or 1
  if t == 1 then                                         -- Einstellungen (nur bekannte Felder, wenige)
    J.einstStudio = {}
    for k, v in pairs(J.einst) do J.einstStudio[k] = v end
    for k, v in pairs(J.funkeEinst) do J.einst[k] = v end
    J.grenzenStudio, J.grenzen, J.s5, J.teilK = {}, {}, 2, nil
    return nil
  elseif t == 2 then                                     -- Studio-Stand merken, Fehler zählt erst Teil 4
    local r = J.grenzenStudio
    if teile(J, J.grenzenRoh, "grenzen", function(k, z) grenzeFertig(J, k, z, true, r) end) then J.s5 = 3 end
    return nil
  elseif t == 3 then                                     -- .funke.lua je Feld darüber
    local ak = J.einst.akkuart or (w.cfg and w.cfg.akkuart)
    if teile(J, J.funkeGrenzen, "grenzen", function(k, z)
      local g = J.grenzenRoh[k] or M.werkGrenze(k, F, ak) or {}
      for n, x in pairs(z) do g[n] = x end
      J.grenzenRoh[k] = g
    end) then J.s5 = 4 end
    return nil
  elseif t == 4 then
    local r = J.grenzen
    if teile(J, J.grenzenRoh, "grenzen", function(k, z) grenzeFertig(J, k, z, false, r) end) then
      J.s5, J.extra, J.gAns, J.gVib, J.schl = 5, {}, {}, {}, {}
    end
    return nil
  elseif t == 5 then                                     -- weitere Grenzen (Sensoren, Kanäle, nicht überwachte Lua-Werte)
    if not teile(J, J.grenzen, "grenzen", function(key, e)
      local art, s = M.schluessel(key)
      if not (art == "lua" and M.WERTE[s].u) and not e.aus and (e.warnung or e.alarm) then
        J.extra[#J.extra + 1] = { key = key, art = art, s = s, e = e }
        J.gAns[key], J.gVib[key] = e.ansage, e.vibration
        if art == "sensor" or art == "kanal" then J.schl[key] = true end
      end
    end) then return nil end
  end
  J.zustand = "geladen"
  -- Format 2: studio_symbole.lua (Referenz) braucht die Original-Tabellen (symbole, ansichten mit Plätzen und deko).
  -- Nur diese bleiben, werte/grenzen/einstellungen der Datei werden frei.
  local d = J.d
  if d.format == 2 then J.roh = { format = 2, symbole = d.symbole, ansichten = d.ansichten } end
  J.d, J.fu, J.grenzenRoh, J.s5 = nil, nil, nil, nil
  w.studioJob = nil
  return J
end

-- Werkgrenze eines überwachten Lua-Werts als Eintrag in angezeigter Einheit (für das Zusammenführen, Format 6.5)
function M.werkGrenze(key, F, akkuart)
  local art, s = M.schluessel(key)
  if art ~= "lua" or not M.WERTE[s].u then return nil end
  local n = M.WERTE[s].u
  local div = M.UEBERWACHT[n][2]
  local werk = F.standard()
  local wW, wA = werk[n .. "W"], werk[n .. "A"]
  if n == "zelle" then
    local z = F.ZELLE_WERK[akkuart or 1] or F.ZELLE_WERK[1]
    wW, wA = z[1], z[2]
  end
  return { richtung = M.WERTE[s][6], warnung = (wW and wW > 0) and wW / div or false,
    alarm = (wA and wA > 0) and wA / div or false }
end

-- ===== .funke.lua schreiben (Abschnitt 9): Text nach Abschnitt 4, erst .funke.neu, prüfen, dann umbenennen =====
local function esc(t)
  return '"' .. t:gsub(".", function(c) return "\\" .. c:byte() end) .. '"'
end
local function zahl(v)
  if ganz(v) then return string.format("%d", v) end
  if v == floor(v) and math.abs(v) < 1e9 then return string.format("%d", floor(v)) end
  return string.format("%.4f", v)
end
M.esc, M.zahl = esc, zahl

-- einst: { [Name in felder.lua] = Wert }, grenzen: { [Schlüssel] = { warnung=, alarm=, aus= } }
function M.funkeText(einst, grenzen)
  local t = { "return { format = 1, einstellungen = {" }
  local namen = {}
  for k in pairs(einst) do namen[#namen + 1] = k end
  table.sort(namen)
  for _, k in ipairs(namen) do
    local s = k:gsub("(%u)", function(c) return "_" .. c:lower() end)
    local v = einst[k]
    local x = type(v) == "boolean" and tostring(v) or (type(v) == "string" and esc(v) or zahl(v))
    t[#t + 1] = " " .. s .. " = " .. x .. ","
  end
  t[#t + 1] = " }, grenzen = {"
  local gk = {}
  for k in pairs(grenzen) do gk[#gk + 1] = k end
  table.sort(gk)
  for _, k in ipairs(gk) do
    local e = grenzen[k]
    local f = {}
    if e.aus == true then f[#f + 1] = "aus = true" elseif e.aus == false then f[#f + 1] = "aus = false" end
    if e.warnung == false then f[#f + 1] = "warnung = false" elseif e.warnung then f[#f + 1] = "warnung = " .. zahl(e.warnung) end
    if e.alarm == false then f[#f + 1] = "alarm = false" elseif e.alarm then f[#f + 1] = "alarm = " .. zahl(e.alarm) end
    if e.beiMotorAus ~= nil then f[#f + 1] = "beiMotorAus = " .. tostring(e.beiMotorAus == true) end
    t[#t + 1] = " [" .. esc(k) .. "] = { " .. table.concat(f, ", ") .. " },"
  end
  t[#t + 1] = " } }\n"
  return table.concat(t)
end

-- Rückgabe true, wenn geschrieben (oder leer gelöscht)
function M.funkeSchreiben(kennung, text)
  local basis = M.ORDNER .. kennung .. "." .. M.LUA
  pcall(os.mkdir, "SCRIPTS:/studio")
  if text == nil then                                   -- nichts geändert: Datei weg
    pcall(os.remove, basis .. ".funke.lua")
    return true
  end
  local ok, f = pcall(io.open, basis .. ".funke.neu", "w")
  if not ok or not f then return false end
  local okW = pcall(f.write, f, text)
  f:close()
  if not okW or not studioLaden(basis .. ".funke.neu", M.FORMAT) then
    pcall(os.remove, basis .. ".funke.neu")
    return false
  end
  -- Am Sender überschreibt os.rename eine vorhandene Datei nicht (gemessen X18RS 20.11.2026): erst löschen
  local alt = io.open(basis .. ".funke.lua", "r")
  if alt then alt:close() pcall(os.remove, basis .. ".funke.lua") end
  local okR, r = pcall(os.rename, basis .. ".funke.neu", basis .. ".funke.lua")
  return okR and r ~= nil and r ~= false
end

-- ===== Info-Datei (Abschnitt 14), JSON, nur das Studio liest sie =====
local function jtext(t)
  t = tostring(t or "")
  return '"' .. t:gsub('[%c"\\]', function(c)
    if c == '"' then return '\\"' elseif c == "\\" then return "\\\\" elseif c == "\n" then return "\\n" end
    return string.format("\\u%04X", c:byte())
  end) .. '"'
end
M.jtext = jtext

-- Liste aller Telemetriesensoren. Am Sender (X18RS, Ethos 26.2.0, 20.11.2026) liefert getSources mit einer Tabelle
-- { category = … } eine LEERE Liste; mit der Kategorie als Zahl geht es (wie die Sensorsuche). Tabelle nur als Rückfall.
local function sensorListe()
  if not (system.getSources and CATEGORY_TELEMETRY_SENSOR) then return {} end
  local ok, l = pcall(system.getSources, CATEGORY_TELEMETRY_SENSOR)
  if ok and type(l) == "table" and #l > 0 then return l end
  ok, l = pcall(system.getSources, { category = CATEGORY_TELEMETRY_SENSOR })
  if ok and type(l) == "table" then return l end
  return {}
end

-- Sensorliste in Schritten (je Aufruf 10, höchstens 100). Rückgabe: nil = läuft, sonst true (geschrieben/unnötig)
function M.infoSchritt(w, version, formate)
  local I = w.infoJob
  if I == nil then
    I = { i = 0, s = {} }
    I.liste = sensorListe()
    w.infoJob = I
    return nil
  end
  local bis = math.min(#I.liste, I.i + 10, 100)
  for i = I.i + 1, bis do
    local q = I.liste[i]
    local function r(f) local okf, v = pcall(q[f], q) if okf then return v end return nil end
    local a, sub, ph, nm, e = r("appId"), r("subId"), r("physId"), r("name"), r("unit")
    local t = '{ "appId": ' .. (ganz(a) and a or 0) .. ', "sub": ' .. (ganz(sub) and sub or 0)
      .. ', "phys": ' .. (ganz(ph) and ph or 0) .. ', "name": ' .. jtext(nm)
    local okE, eh = false, nil
    if e ~= nil and system.getUnitName then okE, eh = pcall(system.getUnitName, e) end
    if okE and type(eh) == "string" and eh ~= "" then t = t .. ', "einheit": ' .. jtext(eh) end
    I.s[#I.s + 1] = t .. " }"
  end
  I.i = bis
  if I.i < math.min(#I.liste, 100) then return nil end
  local okV, ver = pcall(system.getVersion)
  ver = okV and type(ver) == "table" and ver or {}
  local fenster = {}
  for _, f in ipairs(w.fenster or {}) do fenster[#fenster + 1] = '{ "breite": ' .. f[1] .. ', "hoehe": ' .. f[2] .. ' }' end
  local okN, name = pcall(model.name)
  local okP, pfad = pcall(model.path)
  local st = w.studio and w.studio.zustand or w.studioZustand or "fehlt"
  local t = '{\n "format": 1,\n "lua": "' .. M.LUA .. '",\n "luaVersion": ' .. jtext(version)
    .. ',\n "formate": [' .. table.concat(formate, ", ") .. '],\n "beiMotorAus": true,\n "modell": ' .. jtext(w.testKennung and "ELECTRIC DEMO" or (okN and name or ""))
    .. ',\n "kennung": ' .. jtext(w.testKennung or M.kennung())
    .. ((okP and type(pfad) == "string") and (',\n "modellPfad": ' .. jtext(pfad)) or "")
    .. ',\n "funke": ' .. jtext(ver.board) .. ',\n "ethos": ' .. jtext(ver.version)
    .. ',\n "fenster": [' .. table.concat(fenster, ", ") .. '],\n "studioDatei": ' .. jtext(st)
    .. ((w.studioFehler and w.studioFehler > 0) and (',\n "fehler": ' .. w.studioFehler) or "")
    .. ',\n "sensoren": [\n  ' .. table.concat(I.s, ",\n  ") .. '\n ]'
    .. ',\n "studioQuelle": ' .. jtext(w.studioQuelle or "") .. ',\n "studioWahl": ' .. jtext(w.studioWahl or "auto")
    .. ',\n "ansichtGenutzt": ' .. jtext(w.ansichtGenutzt or "") .. ',\n "angepasst": ' .. tostring(w.angepasst == true)
    .. ',\n "hinweis": ' .. jtext(w.sGrund or w.sAngepasst or "") .. '\n}\n'
  w.infoJob = nil
  if w.testKennung and t ~= w.infoAlt then print("ZUSTAND INFO " .. t:gsub("\n", " ")) end   -- nur Testbilder
  if t == w.infoAlt then return true end               -- nichts geändert: nicht schreiben (SD-Karte schonen)
  pcall(os.mkdir, "SCRIPTS:/studio")
  local ok, f = pcall(io.open, M.ORDNER .. (w.testKennung or M.kennung()) .. "." .. M.LUA .. ".info.json", "w")
  if ok and f then
    local okW = pcall(f.write, f, t)
    f:close()
    if okW then w.infoAlt = t return true end
  end
  print("Electric: Info-Datei konnte nicht geschrieben werden")
  return true
end

-- ===== Anwenden und Betrieb =====
-- Grenze eines überwachten Werts als Ganzzahlen im cfg (<name>W, <name>A), aus dem Eintrag e (oder Werk)
local function grenzeCfg(J, F, c, n, e, werk)
  local info = M.UEBERWACHT[n]
  local key, div = "lua:" .. info[1], info[2]
  local wW, wA = werk[n .. "W"], werk[n .. "A"]
  if n == "zelle" then
    local z = F.ZELLE_WERK[c.akkuart] or F.ZELLE_WERK[1]
    wW, wA = z[1], z[2]
  end
  if e == nil or e.werk then return wW, wA end
  if e.aus then return 0, 0 end
  local a = J.werte and J.werte[key]
  local fW, fA = F.feld(n .. "W"), F.feld(n .. "A")
  local function roh(x, f, werkWert)
    if x == "werk" then return werkWert end           -- ungültige Stufe: Werkgrenze
    if x == nil then return 0 end
    if a then x = (x - a.versatz) / a.faktor end      -- Grenze gilt im angezeigten Wert, cfg im Rohwert
    x = floor(x * div + 0.5)
    if x < 1 then x = 1 end                          -- 0 hiesse «Stufe aus»: eine gesetzte Grenze bleibt an
    if x > f[6] then x = f[6] end
    return x
  end
  return roh(e.warnung, fW, wW), roh(e.alarm, fA, wA)
end

-- Ergebnis von M.schritt auf das Widget anwenden (nur bei Zustand «geladen»)
function M.anwenden(w, J, F)
  local c = w.cfg
  local werk = F.standard()
  local S = { zustand = "geladen", fehler = J.fehler, werte = J.werte, ansichten = J.ansichten, einstBasis = {},
    grenzBasis = {}, motBasis = {}, gAns = J.gAns or {}, gVib = J.gVib or {}, extra = J.extra or {}, quellen = {}, offen = {}, st = {},
    zx = {}, kurven = {} }
  for _, g in ipairs(F.gruppen) do
    for _, f in ipairs(g[2]) do
      local k = f[1]
      if F.studioEinstellung(k) then
        local b = J.einstStudio[k]
        if b == nil then b = werk[k] end
        S.einstBasis[k] = b
        local v = J.einst[k]
        if v == nil then v = werk[k] end
        c[k] = v
      end
    end
  end
  for n, info in pairs(M.UEBERWACHT) do
    local key = "lua:" .. info[1]
    local e = J.grenzen[key]
    c[n .. "W"], c[n .. "A"] = grenzeCfg(J, F, c, n, e, werk)
    local bW, bA = grenzeCfg(J, F, c, n, J.grenzenStudio[key], werk)
    S.grenzBasis[n] = { bW, bA }
    if e then S.gAns[n], S.gVib[n] = e.ansage, e.vibration end
    -- «auch bei Motor aus» (3.5): fehlt der Eintrag, gilt true; Basis = Studio-Datei ohne .funke.lua
    local bs = J.grenzenStudio[key]
    c[n .. "Mot"] = not (e and e.beiMotorAus == false)
    S.motBasis[n] = not (bs and bs.beiMotorAus == false)
  end
  -- weitere Grenzen: in M.schritt (Stufe 5, Teil 5) in Stücken vorbereitet (Befehlsgrenze)
  local schl = J.schl or {}
  for _, a in pairs(J.ansichten) do
    for _, q in ipairs(a.plaetze) do
      if q.art == "sensor" or q.art == "kanal" then schl[q.w] = true end
    end
  end
  for key in pairs(schl) do S.offen[#S.offen + 1] = key end
  w.studio = S
end

-- ===== 0.7.0: Liste für das Menü «Studio-Layout» (nur beim Öffnen des Menüs, R2.4) =====
-- Alle *.electric.lua der Suchorte ohne .funke.lua; gleicher Name an einem späteren Ort nur einmal (SCRIPTS: kann
-- derselbe Ordner sein wie SD:/scripts). Rückgabe: { { pfad, name, ort }, ... }
function M.liste()
  local r, schon = {}, {}
  local ende = "." .. M.LUA .. ".lua"
  for _, ort in ipairs(M.ORTE) do
    local ok, l = pcall(system.listFiles, ort)
    if ok and type(l) == "table" then
      for _, n in ipairs(l) do
        if type(n) == "string" and n:sub(-#ende) == ende and not n:find("%.funke%.lua$") and not schon[n] and #r < 40 then
          schon[n] = true
          r[#r + 1] = { ort .. n, n, ort:match("^(%u+):") or ort }
        end
      end
    end
  end
  return r
end

-- ===== 0.7.0: Ansicht auf eine andere Fenstergrösse umrechnen (R3), einmal je Grösse, im wakeup =====
-- Kopfzeile wie Z.layout (zeichnen.lua): Plätze bleiben darunter.
local function kopfH(W, H)
  local kompakt = H < W * 0.5 or W < 400 or H < 250
  local sk = kompakt and math.min(W / 784, H / 316) * 0.72 or math.min(W / 800, H / 480)
  return floor((kompakt and 47 or 56) * sk)
end

-- Ansicht mit dem ähnlichsten Seitenverhältnis, bei Gleichstand die grössere Fläche
function M.besteAnsicht(ansichten, W, H)
  local best, bd, bf = nil, nil, nil
  for _, a in pairs(ansichten) do
    if not a.angepasst then
      local d = math.abs(math.log((a.breite / a.hoehe) / (W / H)))
      local f = a.breite * a.hoehe
      if best == nil or d < bd - 1e-9 or (math.abs(d - bd) <= 1e-9 and f > bf) then best, bd, bf = a, d, f end
    end
  end
  return best
end

function M.umrechnen(w, W, H)
  local S = w.studio
  local a = S and M.besteAnsicht(S.ansichten, W, H)
  if a == nil then return nil end
  local kq, kz = kopfH(a.breite, a.hoehe), kopfH(W, H)
  local fx, fy = W / a.breite, (H - kz) / math.max(1, a.hoehe - kq)
  local function px(x) return floor(x * fx + 0.5) end
  local function py(y) return kz + floor(math.max(0, y - kq) * fy + 0.5) end
  local n = { breite = W, hoehe = H, plaetze = {}, angepasst = true, von = a.breite .. "x" .. a.hoehe, weg = 0 }
  for _, q in ipairs(a.plaetze) do
    local x, y = px(q.x), py(q.y)
    local b, h = math.min(W - x, px(q.x + q.b) - x), math.min(H - y, py(q.y + q.h) - y)
    local darst = q.darst
    local function passt(d) return b >= floor(M.DARST[d][1] * W / 800 + 0.5) and h >= floor(M.DARST[d][2] * W / 800 + 0.5) end
    if not passt(darst) then darst = "zahl" end
    if b >= 1 and h >= 1 and passt(darst) then
      local q2 = {}
      for k, v in pairs(q) do q2[k] = v end
      q2.x, q2.y, q2.b, q2.h, q2.darst = x, y, b, h, darst
      if q.roh then
        local r = {}
        for k, v in pairs(q.roh) do r[k] = v end
        r.x, r.y, r.b, r.h = x, y, b, h
        if darst ~= q.darst then r.darstellung = darst end
        q2.roh = r
      end
      n.plaetze[#n.plaetze + 1] = q2
    else
      n.weg = n.weg + 1
    end
  end
  if a.roh then                                          -- Format 2: Schmuck mit umrechnen (studio_symbole.lua)
    n.roh = { breite = W, hoehe = H }
    local SY = w.sym
    if SY and SY.dekoUmrechnen then
      local ok, _, weg = pcall(SY.dekoUmrechnen, a.roh, n.roh, function(g)
        local g2 = {}
        for k, v in pairs(g) do g2[k] = v end
        g2.s = nil                                       -- Schrift neu wählen (textVorbereiten)
        g2.x, g2.y = px(g.x), py(g.y)
        if g.b then
          if g.a == "linie" then g2.b, g2.h = px(g.x + g.b) - g2.x, py(g.y + g.h) - g2.y
          else g2.b, g2.h = math.max(1, px(g.x + g.b) - g2.x), math.max(1, py(g.y + g.h) - g2.y) end
        end
        if g2.x >= W or g2.y >= H or (g2.b and (g2.x + g2.b > W or g2.y + g2.h > H)) then return nil end
        return g2
      end, W, H)
      if ok and weg then n.weg = n.weg + weg end
    end
  end
  return n
end

-- Sensoren und Kanäle der Studio-Datei suchen, in Schritten. Rückgabe true = fertig.
-- Fehlender Sensor: system.getSource liefert ein Objekt der Kategorie «keine» (Format 12.6, X18RS), nicht nil
local function echt(q)
  if q == nil then return nil end
  if CATEGORY_NONE ~= nil then
    local ok, k = pcall(function() return q:category() end)
    if ok and k == CATEGORY_NONE then return nil end
  end
  return q
end

function M.quellenSchritt(w)
  local S = w.studio
  local key = S.offen[#S.offen]
  if key == nil then return true end
  local art, a, sub, ph = M.schluessel(key)
  local q, eh, dez = nil, nil, nil
  if art == "kanal" and CATEGORY_CHANNEL then
    local ok, r = pcall(system.getSource, { category = CATEGORY_CHANNEL, member = a - 1 })
    if ok and echt(r) then
      local okV, v = pcall(function() return r:value() end)   -- Format 2, Regel 7.3: auch den Wert prüfen
      if okV and v ~= nil then q, eh, dez = r, "%", 0 end
    end
  elseif art == "sensor" then
    -- Sensorliste in Stücken durchgehen (AppID, Teilwert, Physical ID falls angegeben). Nicht über getSource mit
    -- appId: am Sender lieferte das ein Objekt ohne Wert (value nil, Messwidget X18RS 20.11.2026).
    local P = S.phys
    if P == nil or P.key ~= key then
      S.phys = { key = key, l = S.sensoren or sensorListe(), i = 0 }
      S.sensoren = S.phys.l                             -- Liste nur einmal je Studio-Datei holen
      return false
    end
    local bis = math.min(#P.l, P.i + 20)
    for i = P.i + 1, bis do
      local s = P.l[i]
      local function r(f) local okf, v = pcall(s[f], s) if okf then return v end return nil end
      if r("appId") == a and (r("subId") or 0) == sub and (ph == nil or r("physId") == ph) then q = echt(s) break end
    end
    P.i = bis
    if q == nil and P.i < #P.l then return false end
    S.phys = nil
  end
  if q ~= nil and art == "sensor" then
    local okD, d = pcall(q.decimals, q)
    if okD and math.type(d) == "integer" then dez = d end
    local okU, u = pcall(q.unit, q)
    if okU and u ~= nil and system.getUnitName then
      local okN, nm = pcall(system.getUnitName, u)
      if okN and type(nm) == "string" then eh = nm end
    end
  end
  if q == nil then print("Electric: Studio: " .. key .. " nicht gefunden, Platz zeigt ---") end
  S.quellen[key] = q and { q = q, eh = eh, dez = dez, kanal = art == "kanal" } or false
  S.offen[#S.offen] = nil
  if #S.offen == 0 then S.sensoren = nil end
  return #S.offen == 0
end

-- Wert eines Schlüssels: Zahl (angepasst nach «werte»), Einheit, Stellen, Name (Sprache sp)
function M.wert(w, key, art, s, sp)
  local S, v = w.studio, w.v
  local x, eh, dez, name
  if art == "lua" then
    local d = M.WERTE[s]
    local f = d[1]
    if f == "!flugzeit" then x = w.akt and w.akt[2] or 0
    elseif f == "!fluege" then x = w.dauer and w.dauer.fluege or 0
    elseif f == "!motor" then if v.motorAus ~= nil then x = v.motorAus and 0 or 1 end
    else x = v[f] end
    eh, dez, name = d[2], d[3], d[sp == 2 and 8 or 7]
  elseif art == "sensor" or art == "kanal" then
    local Q = S.quellen[key]
    if Q then
      local ok, r = pcall(Q.q.value, Q.q)
      if ok and type(r) == "number" and r == r then x = Q.kanal and r / 10.24 or r end
      eh, dez = Q.eh, Q.dez
    end
    name = key
  else
    return nil, "", 0, ""
  end
  local a = S.werte[key]
  if a then
    if x then x = x * a.faktor + a.versatz end
    eh, dez, name = a.einheit or eh, a.stellen or dez, a.name or name
  end
  return x, eh or "", dez or 0, name or ""
end

-- Laufend (je wakeup nach dem Lesen): Quellen suchen, Min/Max/Mittel, Kurvenpunkte der sichtbaren Ansicht
function M.wecke(w, now)
  local S = w.studio
  if #S.offen > 0 then M.quellenSchritt(w) end
  local L = w.L
  local a = L and S.ansichten[L.W .. "x" .. L.H]
  if a == nil then return end
  for i, q in ipairs(a.plaetze) do
    if q.zusatz ~= "keine" or q.darst == "kurve" then
      local x = M.wert(w, q.w, q.art, q.s, 1)
      if x and q.zusatz ~= "keine" then
        local z = S.zx[q.w]
        if z == nil then z = { x, x, 0, 0 } S.zx[q.w] = z end
        if x < z[1] then z[1] = x end
        if x > z[2] then z[2] = x end
        z[3], z[4] = z[3] + x, z[4] + 1
      end
      if q.darst == "kurve" then
        local K = S.kurven[i]
        if K == nil or K.w ~= q.w then K = { w = q.w, n = 0, p = {}, t = -1e9 } S.kurven[i] = K end
        if now - K.t >= q.kurveS / 120 then
          K.t = now
          K.n = K.n % 120 + 1                           -- Ringpuffer, höchstens 120 Punkte
          K.p[K.n] = x or false
          K.voll = K.voll or K.n == 120
        end
      end
    end
  end
end

-- Min/Max/Mittel beginnen neu (neuer Flug)
function M.flugNeu(w)
  if w.studio then w.studio.zx = {} end
end

-- Grenzen der weiteren Werte prüfen (aus warnungen im Kern, mit dessen melde). Rückgabe: höchste Stufe
-- Befehlsgrenze im Betrieb (0.3.2, Prüfung): je Aufruf nur JE_RING Einträge im Ring neu prüfen, sonst brauchten
-- 60 Sensor-Grenzen über 7000 Befehle je wakeup. «Heisse» Einträge (Stufe >= 1 oder Entprellung läuft) werden zusätzlich
-- in jedem Aufruf geprüft, höchstens JE_HEISS; so gilt die Entprellung wie bei den Grundwerten und nichts flackert.
-- Ein neuer Alarm wird spätestens nach einem Umlauf gesehen (160 Grenzen: 16 Aufrufe, etwa 3,2 s), dann nach 1 s gemeldet.
local JE_RING, JE_HEISS = 10, 6
function M.grenzenExtra(w, now, melde, tele, stumm)
  local S = w.studio
  local L = S.extra
  local n = #L
  if n == 0 then return 0 end
  local heiss, dran, anM = S.extraHeiss or {}, S.extraDran or {}, S.extraAnM or {}
  S.extraHeiss, S.extraDran, S.extraAnM = heiss, dran, anM
  local runde = (S.runde or 0) + 1
  S.runde = runde
  local hoechst = 0
  local function pruef(x)
    local wert, _, dez = M.wert(w, x.key, x.art, x.s, 1)
    local e = x.e
    local function jenseits(gr)
      if gr == nil or wert == nil then return false end
      if e.richtung == "unter" then return wert < gr end
      return wert > gr
    end
    local still = e.beiMotorAus == false and w.v.motorAus == true   -- 3.5: schweigt nur, solange der Motor aus ist
    local al = tele and not still and jenseits(e.alarm) or false
    local m = melde(w, now, x.key .. "A", 2, al, nil, wert, 0, dez)
    local wn = melde(w, now, x.key .. "W", 1, tele and not still and not al and jenseits(e.warnung) or false, nil, wert, 0, dez)
    if still and stumm then m, wn = stumm(w, x.key .. "A"), stumm(w, x.key .. "W") end
    local st
    if wert == nil then st = nil
    elseif still then st = jenseits(e.alarm) and 2 or (jenseits(e.warnung) and 1 or 0)
    else st = m and 2 or ((wn or jenseits(e.warnung)) and 1 or 0) end
    S.st[x.key] = st
    if st and st > hoechst then hoechst = st end
    dran[x.key] = runde
    local mA, mW = w.meld[x.key .. "A"], w.meld[x.key .. "W"]
    if (st and st >= 1) or (mA and (mA.an or mA.seit)) or (mW and (mW.an or mW.seit)) then heiss[x.key] = x
    else heiss[x.key] = nil end
    for _, mm in ipairs({ mA, mW }) do                 -- Liste der gemeldeten (an) Meldungen, mit Runde des Eintrags
      if mm.an then anM[mm], mm.runde = true, runde else anM[mm] = nil end
    end
  end
  local start = S.ring or 0
  local anz = math.min(n, JE_RING)
  for j = 1, anz do pruef(L[(start + j - 1) % n + 1]) end
  S.ring = (start + anz) % n
  local zusatz = 0
  for key, x in pairs(heiss) do                        -- nur vorhandene Schlüssel werden geändert (pairs bleibt gültig)
    if zusatz >= JE_HEISS then break end
    if dran[key] ~= runde then
      zusatz = zusatz + 1
      pruef(x)
    end
  end
  -- Gemeldet, aber in diesem Aufruf nicht geprüft: Stand des letzten Besuchs gilt (sehr viele gleichzeitig)
  for m in pairs(anM) do
    if m.runde ~= runde then
      w.nAktiv = w.nAktiv + 1
      w.aktiv[w.nAktiv] = m
      if m.stufe > hoechst then hoechst = m.stufe end
    end
  end
  return hoechst
end

-- Änderungen aus dem Funken-Menü gegenüber dem Studio-Stand als Text für .funke.lua (nil = keine Änderung)
function M.funkeAusCfg(w, F)
  local S, c = w.studio, w.cfg
  local einst, grenzen, n = {}, {}, 0
  for k, b in pairs(S.einstBasis) do
    if c[k] ~= b then einst[k] = c[k] n = n + 1 end
  end
  for nm, info in pairs(M.UEBERWACHT) do
    local b = S.grenzBasis[nm]
    local cw, ca = c[nm .. "W"] or 0, c[nm .. "A"] or 0
    if cw ~= b[1] or ca ~= b[2] then
      local key = "lua:" .. info[1]
      local a = S.werte[key]
      local function anz(x)
        if x == 0 then return false end              -- Stufe aus
        x = x / info[2]
        if a then x = x * a.faktor + a.versatz end
        return x
      end
      if cw == 0 and ca == 0 then grenzen[key] = { aus = true }
      else grenzen[key] = { aus = false, warnung = anz(cw), alarm = anz(ca) } end   -- hebt ein «aus» der Studio-Datei auf
      n = n + 1
    end
    local cm = c[nm .. "Mot"] ~= false                 -- «auch bei Motor aus» je Feld wie «ansage» (3.5)
    if cm ~= S.motBasis[nm] then
      local key = "lua:" .. info[1]
      grenzen[key] = grenzen[key] or {}
      grenzen[key].beiMotorAus = cm
      n = n + 1
    end
  end
  if n == 0 then return nil end
  return M.funkeText(einst, grenzen)
end

return M
