-- Elektro: Studio-Datei laden und prüfen (Lua-Studio-Format v1, Abschnitt 12) auf dem Mac.
-- Aufruf aus dem Repo-Ordner:  /opt/homebrew/opt/lua@5.4/bin/lua test/studio-test.lua
--  a) keine Datei: Zustand «fehlt», kein Hinweis
--  b) alle Angriffs- und Grenzfalldateien (test/studio-messen/dateien): nie ein Absturz, Zustand passt
--  c) gültige Datei mit absichtlichen Fehlern (test/studio/gueltig.elektro.lua) und .funke.lua: Werte geprüft
--  d) .funke.lua schreiben: .neu, prüfen, alte entfernen, umbenennen; übrig gebliebene .funke.neu
-- Je Aufruf von studio.schritt höchstens 5000 Lua-Befehle (debug.sethook).
local repo = arg[0]:gsub("test/studio%-test%.lua$", "")
local tmp = os.tmpname()
os.remove(tmp)
assert(os.execute("mkdir -p '" .. tmp .. "/SCRIPTS/studio' '" .. tmp .. "/elektro'"))
assert(os.execute("cp '" .. repo .. "src/elektro/'*.lua '" .. tmp .. "/elektro/'"))

local print_ = print
local fehlerZahl = 0
local function pruefe(ok, text)
  print_((ok and "ok     " or "FEHLER ") .. text)
  if not ok then fehlerZahl = fehlerZahl + 1 end
end

-- Ethos-Umgebung: SCRIPTS:/ -> tmp/SCRIPTS/, relative Pfade -> Skriptordner
local function pfad(p)
  if p:sub(1, 9) == "SCRIPTS:/" then return tmp .. "/SCRIPTS/" .. p:sub(10) end
  if p:sub(1, 1) == "/" then return p end
  return tmp .. "/elektro/" .. p
end
local io_open, os_rename, os_remove = io.open, os.rename, os.remove
io.open = function(p, m) return io_open(pfad(p), m) end
local laden = loadfile
loadfile = function(p, ...) return laden(pfad(p), ...) end
os.rename = function(a, b)
  local f = io_open(pfad(b), "r")                     -- wie am Sender: überschreibt nicht
  if f then f:close() return nil, "exists" end
  return os_rename(pfad(a), pfad(b))
end
os.remove = function(p) return os_remove(pfad(p)) end
os.mkdir = function() return true end
model = { name = function() return "TEST" end, path = function() return "/models/test.bin" end }
system = { getSources = function() return {} end, getVersion = function() return { board = "X18RS", version = "26.2.0" } end }
CATEGORY_TELEMETRY_SENSOR = 4
local zeilen = 0
print = function(...) zeilen = zeilen + 1 end

local F = assert(loadfile("felder.lua"))()
local ST = assert(loadfile("studio.lua"))()

local function kopiere(von, nach)
  local a = assert(io_open(von, "rb")) local t = a:read("a") a:close()
  local b = assert(io_open(nach, "wb")) b:write(t) b:close()
end
local ziel = tmp .. "/SCRIPTS/studio/TEST.elektro.lua"

-- ein ganzer Ladevorgang; Rückgabe Ergebnis, grösste Befehlszahl je Aufruf, Fehlertext
local function ganz()
  local w = {}
  local hoechst, r = 0, nil
  for _ = 1, 400 do
    local n = 0
    debug.sethook(function() n = n + 1 end, "", 1)
    local ok, e = pcall(ST.schritt, w, F)
    debug.sethook()
    if n > hoechst then hoechst = n end
    if not ok then return nil, hoechst, tostring(e) end
    if e then r = e break end
  end
  return r, hoechst
end

-- a) keine Datei
os_remove(ziel)
local r, n = ganz()
pruefe(r and r.zustand == "fehlt", "a) keine Datei: fehlt (" .. n .. " Befehle)")

-- b) Angriffe und Grenzfälle
local liste = io.popen("ls '" .. repo .. "test/studio-messen/dateien/'"):read("a")
local maxN, anzahl = 0, 0
for name in liste:gmatch("[^\n]+") do
  kopiere(repo .. "test/studio-messen/dateien/" .. name, ziel)
  local e, nb, err = ganz()
  anzahl = anzahl + 1
  if nb > maxN then maxN = nb end
  pruefe(e ~= nil and err == nil, "b) " .. name .. ": " .. (err or (e.zustand .. (e.fehler and (", " .. e.fehler .. " Fehler") or ""))) .. ", " .. nb .. " Befehle")
end
pruefe(maxN < 5000, "b) " .. anzahl .. " Dateien, höchstens " .. maxN .. " Befehle je Aufruf (< 5000)")

-- c) gültige Datei mit absichtlichen Fehlern, dazu .funke.lua
kopiere(repo .. "test/studio/gueltig.elektro.lua", ziel)
kopiere(repo .. "test/studio/gueltig.elektro.funke.lua", tmp .. "/SCRIPTS/studio/TEST.elektro.funke.lua")
zeilen = 0
local J, nc = ganz()
pruefe(J and J.zustand == "geladen", "c) gültige Datei geladen, " .. nc .. " Befehle je Aufruf höchstens")
pruefe(J.fehler == zeilen and J.fehler >= 8, "c) Fehler gezählt und je Fehler eine Log-Zeile: " .. tostring(J.fehler) .. " / " .. zeilen)
pruefe(J.einst.kapaz == 3300, "c) Kapazität: .funke.lua (3300) über Studio (2200)")
pruefe(J.einst.zellenzahl == 3 and J.einst.prozQuelle == 2 and J.einst.sw1Name == "FAHRWERK", "c) Einstellungen mit Namen klein_mit_ übernommen")
pruefe(J.einst.flugStrom == nil, "c) ungültige Einstellung (flug_strom = 999) verworfen")
local g = J.grenzen
pruefe(g["lua:akku_proz"].warnung == 35 and g["lua:akku_proz"].alarm == 25, "c) Grenze Akku: Warnung aus .funke.lua (35), Alarm aus Studio (25)")
pruefe(J.grenzenStudio["lua:akku_proz"].warnung == 40, "c) Studio-Stand der Grenze gemerkt (40)")
pruefe(g["lua:strom"].aus == true, "c) Strom: aus = true")
pruefe(g["lua:hoehe"].werk == true and not g["lua:hoehe"].aus, "c) Höhe mit abweichender Richtung: Werkgrenze bleibt, plus Fehler")
pruefe(g["lua:reglertemp"].warnung == nil and g["lua:reglertemp"].alarm == 80, "c) Reglertemp. vertauscht: nur Alarm")
pruefe(g["kanal:3"].richtung == "ueber" and g["kanal:3"].warnung == 50, "c) Kanal 3 mit Richtung")
pruefe(g["sensor:0A10:0"].aus == true, "c) Sensor ohne Richtung: aus")
pruefe(J.werte["lua:drehzahl"].faktor == 0.5 and J.werte["lua:quatsch"] == nil, "c) Werte: Faktor übernommen, unbekannter Schlüssel verworfen")
local a = J.ansichten["784x316"]
pruefe(a ~= nil and J.ansichten["800x480"] ~= nil and J.ansichten["480x272"] == nil, "c) zwei Ansichten, dritte verworfen")
local darst, nK = {}, 0
for _, p in ipairs(a.plaetze) do darst[#darst + 1] = p.darst if p.darst == "kurve" then nK = nK + 1 end end
pruefe(#a.plaetze == 11, "c) 11 von 16 Plätzen gültig (Sensor-Platz 49 px = Mindesthöhe 50 × 784/800) (" .. #a.plaetze .. "): " .. table.concat(darst, ","))
local nV = 0
for _, p in ipairs(J.ansichten["800x480"].plaetze) do if p.darst == "kurve" then nV = nV + 1 end end
pruefe(nK == 1 and nV == 2 and J.ansichten["800x480"].plaetze[4].darst == "zahl", "c) zu kleine Kurven verworfen, höchstens 2 Kurven je Ansicht, dritte wird zahl")
local tz
for _, p in ipairs(a.plaetze) do if p.w == "lua:zelle" then tz = p.titel end end
pruefe(tz and #tz <= 24 and tz:byte(#tz) < 0x80, "c) Titel auf 24 Byte gekürzt, kein halbes Zeichen: " .. tostring(tz))
pruefe(a.plaetze[1].stufen and #a.plaetze[1].stufen == 2, "c) Farbstufen übernommen")

-- d) .funke.lua schreiben (wie am Sender: os.rename überschreibt nicht, darum erst entfernen)
local text = ST.funkeText({ kapaz = 4000, akkuEnde = false, sw1Name = "Möwe" }, { ["lua:akku_proz"] = { warnung = 33, alarm = 21 }, ["lua:strom"] = { aus = true } })
pruefe(ST.studioLaden ~= nil and ST.funkeSchreiben("TEST", text), "d) .funke.lua geschrieben")
local fu, grund = ST.studioLaden(tmp .. "/SCRIPTS/studio/TEST.elektro.funke.lua", 1)
pruefe(fu and fu.einstellungen.kapaz == 4000 and fu.einstellungen.akku_ende == false and fu.einstellungen.sw1_name == "Möwe", "d) zurückgelesen: " .. tostring(grund))
pruefe(fu and fu.grenzen["lua:akku_proz"].warnung == 33 and fu.grenzen["lua:strom"].aus == true, "d) Grenzen zurückgelesen")
pruefe(io_open(tmp .. "/SCRIPTS/studio/TEST.elektro.funke.neu", "r") == nil, "d) keine .funke.neu übrig")
-- übrig gebliebene .funke.neu ohne .funke.lua (Strom weg): wird übernommen
os_rename(tmp .. "/SCRIPTS/studio/TEST.elektro.funke.lua", tmp .. "/SCRIPTS/studio/TEST.elektro.funke.neu")
kopiere(repo .. "test/studio/gueltig.elektro.lua", ziel)
J = ganz()
pruefe(J and J.einst.kapaz == 4000 and io_open(tmp .. "/SCRIPTS/studio/TEST.elektro.funke.lua", "r") ~= nil, "d) .funke.neu nach Stromausfall übernommen")
-- kaputte .funke.lua: nur sie wird verworfen, die Studio-Datei gilt
local k = io_open(tmp .. "/SCRIPTS/studio/TEST.elektro.funke.lua", "w") k:write("return { format = 1, a = os }") k:close()
J = ganz()
pruefe(J and J.zustand == "geladen" and J.funkeVerworfen and J.einst.kapaz == 2200, "d) kaputte .funke.lua verworfen, Studio-Datei gilt (2200)")
-- e) volle Belegung (Abschnitt 12.2): 2 Ansichten zu 16 Plätzen, 8 eigene Werte, 12 Grenzen, ~1060 Elemente
os_remove(tmp .. "/SCRIPTS/studio/TEST.elektro.funke.lua")
kopiere(repo .. "test/studio/voll.elektro.lua", ziel)
local Jv, nv = ganz()
pruefe(Jv and Jv.zustand == "geladen" and Jv.fehler == 0, "e) volle Belegung geladen, 0 Fehler (" .. tostring(Jv and Jv.fehler) .. ")")
pruefe(nv < 5000, "e) höchstens " .. nv .. " Befehle je Aufruf (< 5000)")
local n16 = #Jv.ansichten["784x316"].plaetze + #Jv.ansichten["800x480"].plaetze
pruefe(n16 == 32, "e) 32 Plätze gültig (" .. n16 .. ")")
-- anwenden auf ein Widget wie im Kern (cfg aus felder.lua)
local w = { cfg = F.standard(), v = {}, st = {}, dauer = {} }
local nA = 0
debug.sethook(function() nA = nA + 1 end, "", 1)
ST.anwenden(w, Jv, F)
debug.sethook()
pruefe(nA < 5000 and w.cfg.kapaz == 5000 and w.cfg.polpaare == 7 and w.cfg.becW == 50, "e) angewendet in " .. nA .. " Befehlen, kapaz " .. tostring(w.cfg.kapaz) .. ", becW " .. tostring(w.cfg.becW))
pruefe(w.cfg.zelleW == 350 and w.cfg.zelleA == 330 and w.cfg.diffA == 20, "e) Grenzen in cfg (Zelle 350/330, Diff 20)")
pruefe(#w.studio.extra == 2 and #w.studio.offen == 3, "e) 2 weitere Grenzen, 3 Quellen zu suchen")

-- f) Modellwechsel zehnmal (Abschnitt 12.3): Speicher wächst nicht
local function wechsel()
  local J2 = ganz()
  local w2 = { cfg = F.standard(), v = {}, st = {}, dauer = {} }
  ST.anwenden(w2, J2, F)
  return w2
end
wechsel() collectgarbage() collectgarbage()
local m0 = collectgarbage("count")
for _ = 1, 10 do wechsel() end
collectgarbage() collectgarbage()
local m1 = collectgarbage("count")
pruefe(m1 - m0 < 4, string.format("f) zehn Modellwechsel: Speicher %.1f KB -> %.1f KB", m0, m1))

-- g) Format 6.5: «false» = Stufe aus; ohne Eintrag in der Studio-Datei beginnt .funke.lua mit den Werkgrenzen
kopiere(repo .. "test/studio/demo.elektro.lua", ziel)        -- hat keinen Eintrag für lua:strom
local fk = io_open(tmp .. "/SCRIPTS/studio/TEST.elektro.funke.lua", "w")
fk:write('return { format = 1, grenzen = { ["' .. ("lua:strom"):gsub(".", function(c) return "\\" .. c:byte() end) .. '"] = { warnung = false } } }')
fk:close()
local Jg = ganz()
local gs = Jg and Jg.grenzen["lua:strom"]
pruefe(gs and gs.warnung == nil and gs.alarm == 100 and gs.richtung == "ueber", "g) {warnung = false} ohne Studio-Eintrag: Werk-Alarm 100 ohne Warnung")
local wg = { cfg = F.standard(), v = {}, st = {}, dauer = {} }
ST.anwenden(wg, Jg, F)
pruefe(wg.cfg.stromW == 0 and wg.cfg.stromA == 100, "g) im cfg: Strom Warnung aus (0), Alarm 100")
wg.cfg.tempW = 0                                              -- an der Funke nur die Warnung ausschalten
local txt = ST.funkeAusCfg(wg, F)
local fz = txt and load(txt, "=t", "t", {})()
local tz = fz and fz.grenzen["lua:reglertemp"]
pruefe(tz and tz.warnung == false and tz.alarm == 85, "g) .funke.lua schreibt warnung = false, Alarm bleibt 85")
os_remove(tmp .. "/SCRIPTS/studio/TEST.elektro.funke.lua")

-- h) Befunde der Prüfung 0.3.0
local function datei(text) local x = io_open(ziel, "w") x:write(text) x:close() end
local function lua(k) return '["' .. k:gsub(".", function(c) return "\\" .. c:byte() end) .. '"]' end
os_remove(tmp .. "/SCRIPTS/studio/TEST.elektro.funke.lua")
-- Alarm an der Funke wieder einschalten: aus = false hebt aus = true der Studio-Datei auf
datei("return { format = 1, grenzen = { " .. lua("lua:akku_proz") .. " = { aus = true } } }")
local J1 = ganz()
local w1 = { cfg = F.standard(), v = {}, st = {}, dauer = {} }
ST.anwenden(w1, J1, F)
pruefe(w1.cfg.akkuW == 0 and w1.cfg.akkuA == 0, "h) Studio-Datei schaltet Akku-Alarm aus (0/0)")
w1.cfg.akkuW, w1.cfg.akkuA = 30, 20
pruefe(ST.funkeSchreiben("TEST", ST.funkeAusCfg(w1, F)), "h) .funke.lua mit Akku 30/20 geschrieben")
local J2 = ganz()
local w2 = { cfg = F.standard(), v = {}, st = {}, dauer = {} }
ST.anwenden(w2, J2, F)
pruefe(w2.cfg.akkuW == 30 and w2.cfg.akkuA == 20, "h) nach dem Neuladen bleibt der Alarm an (" .. w2.cfg.akkuW .. "/" .. w2.cfg.akkuA .. ")")
os_remove(tmp .. "/SCRIPTS/studio/TEST.elektro.funke.lua")
-- abweichende Richtung: Werkgrenze, ein Fehler (nicht doppelt gezählt)
datei("return { format = 1, grenzen = { " .. lua("lua:akku_proz") .. " = { richtung = " .. lua("ueber"):sub(2, -2) .. ", warnung = 30, alarm = 20 } } }")
local J3 = ganz()
local w3 = { cfg = F.standard(), v = {}, st = {}, dauer = {} }
ST.anwenden(w3, J3, F)
pruefe(w3.cfg.akkuW == 30 and w3.cfg.akkuA == 20 and J3.fehler == 1, "h) abweichende Richtung: Werkgrenze 30/20, 1 Fehler (" .. J3.fehler .. ")")
-- negativer Faktor bei überwachtem Wert: verworfen
datei("return { format = 1, werte = { " .. lua("lua:akku_proz") .. " = { faktor = -1, versatz = 100 } }, grenzen = { " .. lua("lua:akku_proz") .. " = { warnung = 30, alarm = 20 } } }")
local J4 = ganz()
local w4 = { cfg = F.standard(), v = {}, st = {}, dauer = {} }
ST.anwenden(w4, J4, F)
pruefe(J4.werte["lua:akku_proz"] == nil and w4.cfg.akkuW == 30 and w4.cfg.akkuA == 20 and J4.fehler == 1, "h) negativer Faktor bei Akku %: Eintrag verworfen, Grenze 30/20")
-- kleine Grenze rundet nicht auf «aus»
datei("return { format = 1, grenzen = { " .. lua("lua:zelle_diff") .. " = { warnung = 0.004, alarm = 0.2 } } }")
local J5 = ganz()
local w5 = { cfg = F.standard(), v = {}, st = {}, dauer = {} }
ST.anwenden(w5, J5, F)
pruefe(w5.cfg.diffW == 1 and w5.cfg.diffA == 20, "h) Zellendifferenz-Warnung 0,004 V bleibt an (diffW " .. w5.cfg.diffW .. ")")
-- übrig gebliebene .funke.neu neben .funke.lua wird gelöscht
kopiere(repo .. "test/studio/gueltig.elektro.funke.lua", tmp .. "/SCRIPTS/studio/TEST.elektro.funke.lua")
kopiere(repo .. "test/studio/gueltig.elektro.funke.lua", tmp .. "/SCRIPTS/studio/TEST.elektro.funke.neu")
ganz()
pruefe(io_open(tmp .. "/SCRIPTS/studio/TEST.elektro.funke.neu", "r") == nil, "h) übrige .funke.neu neben .funke.lua gelöscht")
os_remove(tmp .. "/SCRIPTS/studio/TEST.elektro.funke.lua")
-- ungültige Stufe bei überwachtem Wert: Werkgrenze dieser Stufe, nicht «aus»
datei("return { format = 1, grenzen = { " .. lua("lua:akku_proz") .. " = { warnung = " .. lua("x"):sub(2, -2) .. ", alarm = 15 } } }")
local J7 = ganz()
local w7 = { cfg = F.standard(), v = {}, st = {}, dauer = {} }
ST.anwenden(w7, J7, F)
pruefe(w7.cfg.akkuW == 30 and w7.cfg.akkuA == 15 and J7.fehler == 1, "h) ungültige Warnung: Werkwarnung 30, Alarm 15 (" .. w7.cfg.akkuW .. "/" .. w7.cfg.akkuA .. ")")
-- Mindestgrösse mit Bezug 800: Ring 108 × 108 auf 784 × 316 gilt
datei("return { format = 1, ansichten = { { breite = 784, hoehe = 316, plaetze = { { x = 0, y = 0, b = 108, h = 108, w = " .. lua("lua:strom"):sub(2, -2) .. ", darstellung = " .. lua("ring"):sub(2, -2) .. " } } } } }")
local J6 = ganz()
pruefe(J6.fehler == 0 and #J6.ansichten["784x316"].plaetze == 1, "h) Ring 108 × 108 auf 784 × 316 gültig")

-- i) 0.3.2, Befehlsgrenze (Format 12.2): grosse gültige Tabellen in Stücken, je Aufruf < 5000, auch anwenden
local function esc(t) return '"' .. t:gsub(".", function(c) return "\\" .. c:byte() end) .. '"' end
local function gross(teil, n, eintrag)
  local t = { "return { format = 1, " .. teil .. " = {" }
  for i = 1, n do t[#t + 1] = eintrag(i) end
  t[#t + 1] = "} }"
  return table.concat(t)
end
local faelle = {
  { "grenzen x60", gross("grenzen", 60, function(i) return string.format(" [%s] = {richtung=%s,warnung=%d,alarm=%d,ansage=true,vibration=true},", esc(string.format("sensor:%04X:0", i)), esc("ueber"), i, i + 1) end) },
  { "werte x100", gross("werte", 100, function(i) return string.format(" [%s]={faktor=2,einheit=%s,stellen=1},", esc(string.format("sensor:%04X:0", i)), esc("V")) end) },
  { "einstellungen x300", gross("einstellungen", 300, function(i) return string.format("x%d=1,", i) end) },
}
for _, fa in ipairs(faelle) do
  datei(fa[2])
  local Jg, nmax = ganz()
  local nA = 0
  if Jg and Jg.zustand == "geladen" then
    local wg2 = { cfg = F.standard(), v = {}, st = {}, dauer = {} }
    debug.sethook(function() nA = nA + 1 end, "", 1)
    ST.anwenden(wg2, Jg, F)
    debug.sethook()
  end
  pruefe(Jg and Jg.zustand == "geladen" and nmax < 5000 and nA < 5000,
    "i) " .. fa[1] .. ": geladen, schritt höchstens " .. tostring(nmax) .. ", anwenden " .. nA .. " Befehle (< 5000)")
end
datei(faelle[1][2])
local Jx = ganz()
pruefe(Jx and #Jx.extra == 48 and Jx.gAns[Jx.extra[1].key] == true and Jx.fehler >= 1, "i) 60 Sensor-Grenzen: 48 vorbereitet, Rest verworfen mit Hinweis (Format 2, Regel 7.2)")

-- k) 0.3.2 (Prüfung): Betrieb mit 160 Sensor-Grenzen: grenzenExtra je Aufruf < 5000 Befehle (Ring), ein Alarm ganz
--    hinten wird nach einem Umlauf erkannt und bleibt in jedem Aufruf aktiv
datei(gross("grenzen", 160, function(i) return string.format("[%s]={richtung=%s,alarm=%d},", esc(string.format("sensor:%04X:0", i)), esc("ueber"), 200) end))
local Jk = ganz()
pruefe(Jk and Jk.zustand == "geladen", "k) Datei mit 160 Grenzen gültig (" .. tostring(Jk and Jk.zustand) .. ")")
local function melde(w, now, name, stufe, bed)        -- wie kern.lua: an nach 1 s, weg nach 3 s
  local m = w.meld[name]
  if m == nil then m = { an = false, name = name } w.meld[name] = m end
  if bed then
    m.weg = nil
    if not m.an then m.seit = m.seit or now if now - m.seit >= 1.0 then m.an = true end end
  else
    m.seit = nil
    if m.an then m.weg = m.weg or now if now - m.weg >= 3.0 then m.an = false end end
  end
  if m.an then m.stufe = stufe w.nAktiv = w.nAktiv + 1 w.aktiv[w.nAktiv] = m end
  return m.an
end
local function betrieb(wertVon, runden)
  local wk = { cfg = F.standard(), v = {}, st = {}, dauer = {}, meld = {}, aktiv = {}, nAktiv = 0 }
  ST.anwenden(wk, Jk, F)
  for _, x in ipairs(wk.studio.extra) do
    local key = x.key
    wk.studio.quellen[key] = { q = { value = function() return wertVon(key) end }, eh = "V", dez = 0 }
  end
  local maxB, stufen, aktiv = 0, {}, {}
  for r = 1, runden do
    wk.nAktiv = 0
    local nb = 0
    debug.sethook(function() nb = nb + 1 end, "", 1)
    stufen[r] = ST.grenzenExtra(wk, r * 0.2, melde, true)
    debug.sethook()
    aktiv[r] = wk.nAktiv
    if nb > maxB then maxB = nb end
  end
  return wk, maxB, stufen, aktiv
end
local letzter = Jk.extra[#Jk.extra].key
local _, maxK, stK, akK = betrieb(function(k) return k == letzter and 250 or 50 end, 60)
local gefunden, immer = nil, true
for r = 1, 60 do
  if stK[r] == 2 and not gefunden then gefunden = r end
  if gefunden and r > gefunden and not (stK[r] == 2 and akK[r] == 1) then immer = false end
end
pruefe(#Jk.extra == 48 and maxK < 5000, "k) 160 Grenzen in der Datei, 48 übernommen: grenzenExtra höchstens " .. maxK .. " Befehle je Aufruf (< 5000)")
pruefe(gefunden and gefunden <= 22 and immer, "k) Alarm ganz hinten nach " .. tostring(gefunden) .. " Aufrufen (Umlauf + 1 s), danach stabil, ohne Doppel")
-- alle 160 gleichzeitig jenseits: Befehle bleiben begrenzt, Alarm stabil
local _, maxH, stH = betrieb(function() return 250 end, 60)
local stabil = true
for r = 20, 60 do if stH[r] ~= 2 then stabil = false end end
pruefe(maxH < 5000 and stabil, "k) alle 160 Grenzen im Alarm: höchstens " .. maxH .. " Befehle, Stufe stabil")
-- Ausreisser kürzer als 1 s löst keinen Alarm aus (Entprellung wie bei den Grundwerten)
local r0 = 0
local _, _, stA = betrieb(function(k) r0 = r0 + 0 return 50 end, 30)
pruefe(stA[30] == 0, "k) ruhig: Stufe 0")

-- j) 0.3.2: fehlender Sensor -> getSource liefert Kategorie «keine» (Format 12.6): Platz zeigt ---, kein Scheinwert
CATEGORY_NONE, CATEGORY_CHANNEL = 0, 5
local leer = { category = function() return 0 end, value = function() return 0 end }
system.getSource = function() return leer end
local wq = { studio = { offen = { "sensor:0B50:0", "kanal:3" }, quellen = {} } }
for _ = 1, 5 do if ST.quellenSchritt(wq) then break end end
pruefe(wq.studio.quellen["sensor:0B50:0"] == false and wq.studio.quellen["kanal:3"] == false, "j) Kategorie «keine» / fehlender Sensor gilt als nicht gefunden")
system.getSource = nil
-- Sensor der Studio-Datei über die Liste mit Kategorie als Zahl (am Sender liefert die Tabellenform eine leere Liste)
local function sens(a, t, ph) return { appId = function() return a end, subId = function() return t end,
  physId = function() return ph end, category = function() return 4 end, value = function() return 22 end } end
local ziel1, ziel2 = sens(0x0B50, 0, 16), sens(0x0B50, 1, 16)
local aufrufe = {}
system.getSources = function(f) aufrufe[#aufrufe + 1] = type(f) if type(f) == "table" then return {} end return { sens(0x0400, 0, 3), ziel1, ziel2 } end
local ws = { studio = { offen = { "sensor:0B50:0", "sensor:0B50:1:16" }, quellen = {} } }
for _ = 1, 10 do if ST.quellenSchritt(ws) then break end end
pruefe(ws.studio.quellen["sensor:0B50:0"] and ws.studio.quellen["sensor:0B50:0"].q == ziel1
  and ws.studio.quellen["sensor:0B50:1:16"] and ws.studio.quellen["sensor:0B50:1:16"].q == ziel2 and aufrufe[1] == "number"
  and #aufrufe == 1 and ws.studio.sensoren == nil, "j) Studio-Sensoren über getSources(Zahl) gefunden, Liste nur einmal geholt")
system.getSources = function() return {} end
CATEGORY_NONE, CATEGORY_CHANNEL = nil, nil

-- Kennung byteweise
model.name = function() return "M\195\182we 1" end
pruefe(ST.kennung() == "M__we_1", "Kennung «Möwe 1» -> M__we_1")
model.name = function() return "" end
pruefe(ST.kennung() == "modell", "Kennung leer -> modell")

os.execute("rm -rf '" .. tmp .. "'")
print = print_
print(fehlerZahl == 0 and "ERGEBNIS: kein Fehler" or ("ERGEBNIS: " .. fehlerZahl .. " Fehler"))
os.exit(fehlerZahl == 0 and 0 or 1)
