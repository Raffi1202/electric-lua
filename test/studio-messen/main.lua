-- Mess-Widget «smess» (nur zum Testen, kommt nie in ein Paket): Speicher und Verhalten der Studio-Ladefunktion
-- am echten Sender, neben dem laufenden Electric-Widget (Lua-Studio-Format v1, Abschnitt 12).
-- Einbau: Ordner nach SCRIPTS:/smess/ (main.lua und dateien/*.txt). Modell mit Electric laden, zweiten Bildschirm
-- mit diesem Widget anlegen und anzeigen. Es misst je Datei einen Schritt pro Sekunde und schreibt alles ins Log
-- (print) und nach SCRIPTS:/smess/daten/ergebnis.txt.

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

-- Erwartung am Mac mit der erneuerten Referenz (16 KB, Lua 5.4, 20.11.2026): gültig = OK, sonst abgewiesen mit diesem Grund
local DATEIEN = {
  { "g16_lang24", "OK" }, { "g12_lang24", "OK" }, { "typisch", "OK" }, { "g16_513", "OK" }, { "g16_liste", "OK" },
  { "g16_tab", "OK" }, { "g16_text", "OK" }, { "fehlt_nicht_da", "fehlt" }, { "format99", "zuNeu" },
  { "mem_lang", "kaputt" }, { "mem700", "kaputt" }, { "mem513", "kaputt" }, { "mem_liste", "kaputt" }, { "mem_tab", "kaputt" },
  { "a", "kaputt" }, { "b", "kaputt" }, { "binaer", "kaputt" }, { "c", "kaputt" }, { "escapeQuote", "kaputt" },
  { "global", "kaputt" }, { "inf", "kaputt" }, { "koerzion", "kaputt" }, { "pruefer3_a1", "kaputt" },
  { "pruefer3_a2", "kaputt" }, { "pruefer3_a3", "kaputt" }, { "pruefer3_a4", "kaputt" }, { "pruefer3_a5", "kaputt" },
  { "pruefer3_a6", "kaputt" }, { "pruefer3_a7", "kaputt" }, { "riesigeListe", "kaputt" }, { "schleife", "kaputt" },
  { "tiefe", "kaputt" },
}

local zeilen = {}
local function melde(t)
  print("SMESS " .. t)
  zeilen[#zeilen + 1] = t
end

local function kb() return collectgarbage("count") end
-- freier Lua-Speicher laut Ethos in KB (nil, wenn es die Abfrage nicht gibt)
local function frei()
  if not system.getMemoryUsage then return nil end
  local ok, m = pcall(system.getMemoryUsage)
  if ok and type(m) == "table" and type(m.luaRamAvailable) == "number" then return m.luaRamAvailable / 1024 end
  return nil
end
local function fr() local x = frei() return x and string.format("%.0f", x) or "?" end

-- Abschnitt 12.6: Bestätigungen am Sender (nur im eigenen Ordner)
local function pruefe126()
  local function ja(x) return x and "ja" or "NEIN" end
  -- loadfile mit Modus «t» und eigener Umgebung
  local f = io.open("dateien/t_text.txt", "w")
  if f then f:write("return { format = 1 }") f:close() end
  local ok, ch = pcall(loadfile, "dateien/t_text.txt", "t", {})
  melde("12.6 loadfile(p, \"t\", {}): " .. ja(ok and type(ch) == "function"))
  -- os.remove
  melde("12.6 os.remove vorhanden: " .. ja(type(os.remove) == "function") .. ", os.rename vorhanden: " .. ja(type(os.rename) == "function"))
  -- os.rename auf einen Zielnamen, den es schon gibt
  local a = io.open("dateien/t_neu.txt", "w") if a then a:write("NEU") a:close() end
  local b = io.open("dateien/t_alt.txt", "w") if b then b:write("ALT") b:close() end
  local okR, r1, r2 = pcall(os.rename, "dateien/t_neu.txt", "dateien/t_alt.txt")
  local c = io.open("dateien/t_alt.txt", "r")
  local inhalt = c and c:read(16) or "?"
  if c then c:close() end
  melde("12.6 os.rename auf vorhandenen Namen: pcall " .. ja(okR) .. ", Rückgabe " .. tostring(r1) .. " " .. tostring(r2) .. ", Inhalt danach " .. tostring(inhalt))
  -- Umweg der Spezifikation: erst entfernen, dann umbenennen
  local d = io.open("dateien/t_neu.txt", "w") if d then d:write("NEU2") d:close() end
  local okE = pcall(os.remove, "dateien/t_alt.txt")
  local okR2, s1 = pcall(os.rename, "dateien/t_neu.txt", "dateien/t_alt.txt")
  local e = io.open("dateien/t_alt.txt", "r")
  local inhalt2 = e and e:read(16) or "?"
  if e then e:close() end
  melde("12.6 os.remove + os.rename: remove " .. ja(okE) .. ", rename " .. ja(okR2) .. " " .. tostring(s1) .. ", Inhalt " .. tostring(inhalt2))
  pcall(os.remove, "dateien/t_alt.txt") pcall(os.remove, "dateien/t_text.txt")
  -- os.mkdir (Ergänzung 1)
  melde("12.6 os.mkdir vorhanden: " .. ja(type(os.mkdir) == "function"))
  -- system.getSource mit Tabelle
  local okS, q = pcall(system.getSource, { category = CATEGORY_TELEMETRY_SENSOR, appId = 0xF101, subId = 0 })
  melde("12.6 getSource{Tabelle} RSSI: pcall " .. ja(okS) .. ", Quelle " .. (okS and q and tostring(q:name()) or "keine"))
  -- %w nur ASCII
  local u = ("M\195\182we"):gsub("[^%w]", "_")
  melde("12.6 %w nur ASCII: «Möwe» -> " .. u .. " " .. ja(u == "M__we"))
  -- Speicher laut Ethos, falls es die Abfrage gibt
  if system.getMemoryUsage then
    local okM, m = pcall(system.getMemoryUsage)
    if okM and type(m) == "table" then
      local t = {}
      for k, v in pairs(m) do t[#t + 1] = k .. "=" .. tostring(v) end
      table.sort(t)
      melde("getMemoryUsage: " .. table.concat(t, " "))
    end
  end
end

local schritt, tLetzt = 0, -10

local function wakeup(w)
  local jetzt = os.clock()
  if jetzt - tLetzt < 1 or schritt >= #DATEIEN + 2 then return end
  tLetzt = jetzt
  schritt = schritt + 1
  if schritt == 1 then
    collectgarbage("collect")
    melde(string.format("Start: Lua-Speicher belegt %.1f KB (alle Skripte, Electric läuft daneben), frei %s KB", kb(), fr()))
    pruefe126()
  elseif schritt <= #DATEIEN + 1 then
    local name, erwartet = DATEIEN[schritt - 1][1], DATEIEN[schritt - 1][2]
    collectgarbage("collect")
    local m0 = kb()
    local freiVor = fr()
    collectgarbage("stop")
    local okL, d, g = pcall(studioLaden, "dateien/" .. name .. ".txt", 1)
    local spitze = kb() - m0
    local freiNach = fr()
    collectgarbage("restart")
    collectgarbage("collect")
    local bleibend = kb() - m0
    local ist = (not okL) and ("FEHLER " .. tostring(d)) or (d and "OK" or tostring(g))
    melde(string.format("%-14s %-7s erwartet %-6s %s  Spitze %6.1f KB  bleibend %5.1f KB  belegt %.1f KB  frei vorher %s KB, nachher %s KB",
      name, ist, erwartet, ist == erwartet and "ok" or "ABWEICHUNG", spitze, bleibend, kb(), freiVor, freiNach))
    d = nil
    collectgarbage("collect")
  else
    melde(string.format("Ende: Lua-Speicher belegt %.1f KB, frei %s KB", kb(), fr()))
    pcall(os.mkdir, "daten")
    local f = io.open("daten/ergebnis.txt", "w")
    if f then
      f:write(table.concat(zeilen, "\n"), "\n")
      f:close()
    end
  end
  lcd.invalidate()
end

local function paint(w)
  local _, H = lcd.getWindowSize()
  lcd.font(FONT_XS)
  lcd.color(WHITE)
  local von = math.max(1, #zeilen - math.floor(H / 14) + 1)
  for i = von, #zeilen do lcd.drawText(4, (i - von) * 14, zeilen[i]) end
end

local function init()
  system.registerWidget({ key = "smess", name = "Studio-Messung", create = function() return {} end,
    wakeup = wakeup, paint = paint, title = false })
end

return { init = init }
