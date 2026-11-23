-- Electric: Kern des Widgets. Liest die gewählten Quellen, rechnet Akku %, Zellen, Leistung, Höchst- und
-- Tiefstwerte, Warnungen, Ansagen und die Flugliste, und ruft die Seite zum Zeichnen. Alles Rechnen passiert in
-- wecke(), zeichne() zeichnet nur.
-- Absturzsicher: jeder Wert wird geprüft (nil, Text, NaN, unendlich, riesig), jede Ethos-Abfrage läuft in pcall.
local K = {}
local Z = nil          -- zeichnen.lua
local SEITE = {}       -- geladene Seite (immer nur die sichtbare)
local SEITEN = 2       -- Seite 1 Anzeige, Seite 2 Flugliste

local TEST = nil  -- TESTHAKEN: der Simulator-Ablauf ersetzt genau diese Zeile (bauplan.md, Abschnitt Testhaken)
local SUCHE = nil    -- suche.lua, nur geladen, solange eine Suche läuft
local ZUSTAND = nil  -- testzustand.lua, nur geladen mit TEST.zustand im Simulator
local STUDIO = nil   -- studio.lua (Lua-Studio-Format v1): nur geladen, solange eine Studio-Datei gilt oder geladen wird
local ANSICHT = nil  -- ansicht.lua: zeichnet die Plätze einer Studio-Ansicht
local STUDIO_HINWEIS_S = 8   -- s: so lange steht ein Studio-Hinweis unten, danach bleibt oben rechts ein «!»

local DT_LESEN = 0.2   -- s: Werte lesen und rechnen
local DT_BILD = 0.2    -- s: Bild höchstens so oft auffrischen
local AN_S = 1.0       -- s: so lange muss eine Bedingung gelten, bis die Warnung kommt
local AUS_S = 3.0      -- s: so lange muss sie weg sein, bis die Warnung geht
local ANSAGE_ABSTAND = 3.0
local DAUER_S = 60     -- s: Zähler höchstens so oft in die Datei schreiben
local AKKU_WEG_S = 30  -- s: so lange ohne Telemetrie gilt als Akkuwechsel
local SLOP = 14        -- Pixel: ab hier gilt eine Bewegung als Wisch
local GROSS = 1e7      -- Werte darüber gelten als unplausibel
-- Glaubhafter Bereich je Messwert: was ausserhalb liegt, gilt als «kein Wert» (Strich).
local BEREICH = { uGes = { 0, 200 }, strom = { -20, 2000 }, mahRoh = { 0, 500000 }, proz = { 0, 100 },
  rpm = { 0, 500000 }, temp = { -60, 300 }, bec = { 0, 30 }, hoehe = { -1000, 20000 }, vario = { -200, 200 },
  speed = { 0, 1500 }, rssi = { -150, 150 }, lq = { 0, 100 } }

-- Kennlinie Ruhespannung je Zelle -> Akku % (Paare Spannung, Prozent) je Akkuart, dazu leer/voll für die Balken
local KENNLINIE = {
  { 3.30, 0, 3.60, 8, 3.70, 20, 3.75, 35, 3.80, 50, 3.85, 60, 3.90, 70, 4.00, 82, 4.10, 93, 4.20, 100 },
  { 3.30, 0, 3.60, 8, 3.70, 18, 3.78, 35, 3.85, 50, 3.92, 62, 4.00, 72, 4.10, 84, 4.25, 95, 4.35, 100 },
  { 2.80, 0, 3.00, 5, 3.20, 15, 3.25, 30, 3.28, 50, 3.30, 70, 3.33, 90, 3.40, 98, 3.60, 100 },
  { 2.80, 0, 3.20, 8, 3.40, 25, 3.60, 45, 3.70, 55, 3.80, 65, 3.90, 75, 4.00, 85, 4.10, 94, 4.20, 100 },
  { 1.00, 0, 1.10, 8, 1.18, 25, 1.22, 50, 1.26, 70, 1.30, 85, 1.35, 95, 1.40, 100 },
}
local LEER_VOLL = { { 3.3, 4.2 }, { 3.3, 4.35 }, { 2.8, 3.6 }, { 2.8, 4.2 }, { 1.0, 1.4 } }
K.LEER_VOLL = LEER_VOLL

local floor, abs, max, min = math.floor, math.abs, math.max, math.min

local function lade(datei)
  local f, e = loadfile(datei)
  if not f then error(e, 0) end
  return f()
end

local function clamp(x, a, b)
  if x < a then return a end
  if x > b then return b end
  return x
end

-- Zahl prüfen: nil bei nil, Text, NaN, unendlich oder unplausibel gross.
local function gut(v)
  if type(v) ~= "number" or v ~= v or v > GROSS or v < -GROSS then return nil end
  return v
end

-- Wert einer Quelle als Zahl, sonst nil. Optionen (einzelne Zelle) nur als Tabelle (gemessen 26.1.2).
local function zahl(q, opt)
  if q == nil then return nil end
  local ok, v
  if opt ~= nil then ok, v = pcall(q.value, q, { options = opt }) else ok, v = pcall(q.value, q) end
  if not ok then return nil end
  return gut(v)
end

local function bereich(q)
  local ok1, lo = pcall(q.minimum, q)
  local ok2, hi = pcall(q.maximum, q)
  lo, hi = ok1 and gut(lo), ok2 and gut(hi)
  if lo and hi and hi > lo then return lo, hi end
  return nil
end

-- Schalterartige Quelle: aktiv = über der Mitte ihres Bereichs. nil = keine Quelle.
-- Schalterstellungen, logische Schalter und Funktionsschalter zuerst über q:state() (0.3.1: am Sender zeigte die
-- Pille bei SF oben und unten «MOTOR AUS», im Simulator stimmte der Wert; Sendertest X18RS 20.11.2026).
local SCHALTERART = {}
for _, k in ipairs({ "CATEGORY_SWITCH_POSITION", "CATEGORY_LOGIC_SWITCH", "CATEGORY_FUNCTION_SWITCH" }) do
  if _ENV[k] ~= nil then SCHALTERART[_ENV[k]] = true end
end
local function aktiv(q)
  if q == nil then return nil end
  local okK, kat = pcall(q.category, q)
  if okK and kat ~= nil and SCHALTERART[kat] and type(q.state) == "function" then
    local okS, s = pcall(q.state, q)
    if okS and type(s) == "boolean" then return s end
    if okS and type(s) == "number" and s == s then return s ~= 0 end
  end
  local v = zahl(q)
  if v == nil then return nil end
  local lo, hi = bereich(q)
  return v > (lo and (lo + hi) / 2 or 0)
end

-- Stellung eines Kanals in Prozent 0 … 100 seines Bereichs (Gas unten = 0).
local function prozent(q)
  local v = zahl(q)
  if v == nil then return nil end
  local lo, hi = bereich(q)
  if lo == nil then lo, hi = -1024, 1024 end
  return clamp((v - lo) / (hi - lo) * 100, 0, 100)
end

local function stellen(q, sonst)
  if q == nil then return sonst end
  local ok, d = pcall(q.decimals, q)
  if ok and type(d) == "number" and d >= 0 and d <= 3 then return floor(d) end
  return sonst
end

-- Sprache: 1 = Deutsch, 2 = English. Einstellung 0 heisst «wie der Sender».
local SENDER = nil
local function sprache(w)
  local sp = w.cfg.sprache
  if sp ~= 1 and sp ~= 2 then
    if SENDER == nil then
      SENDER = 2
      if system.getLocale then
        local ok, l = pcall(system.getLocale)
        if ok and type(l) == "string" and l:sub(1, 2):lower() == "de" then SENDER = 1 end
      end
    end
    sp = SENDER
  end
  if w.sp ~= sp or w.T == nil then
    w.sp = sp
    w.T = lade("texte.lua")(sp)
    w.hinweis = nil
  end
end

-- Sprachdatei abspielen: audio/de/<name>.wav oder audio/en/<name>.wav. false, wenn die Datei fehlt.
local AUDIO_DA = {}
local function sage(w, name)
  if not system.playFile then return false end
  local pfad = "audio/" .. (w.sp == 1 and "de" or "en") .. "/" .. name .. ".wav"
  local da = AUDIO_DA[pfad]
  if da == nil then
    local ok, f = pcall(io.open, pfad, "r")
    da = (ok and f ~= nil) or false
    if da then pcall(f.close, f) end
    AUDIO_DA[pfad] = da
  end
  if da then pcall(system.playFile, pfad) end
  return da
end

local function zahlSagen(x, einh, dez)
  if x == nil or not system.playNumber then return end
  if (dez or 0) == 0 then x = floor(x + 0.5) end
  pcall(system.playNumber, x, einh or 0, dez or 0)
end

local function imBereich(k, x)
  local b = BEREICH[k]
  if x == nil or (b and (x < b[1] or x > b[2])) then return nil end
  return x
end

local function zelleProzent(u, typ)
  local k = KENNLINIE[typ] or KENNLINIE[1]
  if u <= k[1] then return 0 end
  for i = 3, #k, 2 do
    if u <= k[i] then
      return k[i - 1] + (k[i + 1] - k[i - 1]) * (u - k[i - 2]) / (k[i] - k[i - 2])
    end
  end
  return 100
end

-- Grenzwerte aus den Einstellungen als Zahlen; nil = nicht gesetzt (Warnung aus).
local GRENZEN = { { "akku", 1 }, { "zelle", 100 }, { "diff", 100 }, { "temp", 1 }, { "strom", 1 }, { "kap", 1 },
  { "bec", 10 }, { "hoehe", 1 }, { "rssi", 1 }, { "lq", 1 } }
local function grenzen(w)
  local c, g = w.cfg, w.g
  if TEST and TEST.cfg then
    for k, x in pairs(TEST.cfg) do c[k] = x end
  end
  for _, e in ipairs(GRENZEN) do
    local wn, al = gut(c[e[1] .. "W"]), gut(c[e[1] .. "A"])
    g[e[1] .. "W"] = (wn and wn > 0) and wn / e[2] or nil
    g[e[1] .. "A"] = (al and al > 0) and al / e[2] or nil
  end
  g.wdh = gut(c.wdh) or 10
  sprache(w)
end

-- Vorgabe des Schalter-Standards des Autors: Motor aus = SF oben, Ansage = SG unten (nur beim ersten Start).
-- Ethos findet Schalterstellungen nicht über den Namen, nur über die Nummer (je Schalter 3 Stellungen, SA↑ = 0;
-- gemessen 26.2.0: SF↑ = 15, SG↓ = 20). Zur Sicherheit wird der Name der gefundenen Quelle verglichen und sonst
-- in den ersten 60 Nummern gesucht.
local function schalterVorgabe(w)
  local function quelle(nr)
    if not CATEGORY_SWITCH_POSITION then return nil end
    local ok, s = pcall(system.getSource, { category = CATEGORY_SWITCH_POSITION, member = nr })
    if ok and s then return s end
    return nil
  end
  local function name(q)
    local ok, n = pcall(q.name, q)
    return ok and n or nil
  end
  local function hol(soll, nr)
    local q = quelle(nr)
    if q and name(q) == soll then return q end
    for k = 0, 59 do
      q = quelle(k)
      if q and name(q) == soll then return q end
    end
    return nil
  end
  local c = w.cfg
  if c.swMotor == nil then c.swMotor = hol("SF\u{2191}", 15) end
  if c.swAnsage == nil then c.swAnsage = hol("SG\u{2193}", 20) end
  if c.swMotor or c.swAnsage then
    w.dateiOffen = true
    if model and model.dirty then pcall(model.dirty) end   -- damit Ethos die Quellen im Widget-Speicher sichert
  end
end

function K.neu()
  local F = lade("felder.lua")
  local w = {
    cfg = F.standard(), g = {}, v = {}, st = {}, eh = {}, dz = {},
    meld = {}, aktiv = {}, nAktiv = 0, stufe = 0, zustand = "keine",
    seite = 1, ziele = {}, nZiele = 0, liste = {}, oben = 0, zn = {},
    dauer = {},            -- dauerhafte Werte (Datei daten/<Modell>.txt): Flugzähler, Nullpunkt des Verbrauchs
    gelesen = false, autoOffen = true, version = K.VERSION, name = K.NAME,
  }
  w.FLUG_N, w.MAX_FLUEGE = F.FLUG_N, F.MAX_FLUEGE
  grenzen(w)
  if CATEGORY_SYSTEM_EVENT and SYSTEM_EVENT_TELEMETRY_ACTIVE then
    local ok, q = pcall(system.getSource, { category = CATEGORY_SYSTEM_EVENT, member = SYSTEM_EVENT_TELEMETRY_ACTIVE })
    if ok then w.qTele = q end
  end
  if CATEGORY_SYSTEM and MAIN_VOLTAGE then
    local ok, q = pcall(system.getSource, { category = CATEGORY_SYSTEM, member = MAIN_VOLTAGE })
    if ok then w.qSender = q end
  end
  if CATEGORY_FLIGHT then                          -- 0.10.0 (Issue #1): aktive Flugphase des Modells, wie DLG
    local m = FLIGHT_CURRENT_MODE or CURRENT_FLIGHT_MODE
    if m ~= nil then
      local ok, q = pcall(system.getSource, { category = CATEGORY_FLIGHT, member = m })
      if ok then w.qPhase = q end
    end
  end
  return w
end

local function telemetrie(w)
  local q = w.qTele
  if q == nil then return true end
  local ok, v = pcall(q.value, q)
  if not ok then return true end
  if type(v) == "number" then return v > 0 end
  if type(v) == "boolean" then return v end
  return true
end

local function hinweis(w, text, now)
  w.hinweis = text
  w.hinweisBis = now + 3
end

-- Zellen eines Zellensensors lesen. Nur ein echter Zellensensor hat eine ganze Zellenzahl und Zellen bis 5 V;
-- ein reiner Spannungssensor liefert auf jede Abfrage die Gesamtspannung (gemessen, Motoren Lua liesAkku).
local function liesZellen(w, q)
  local z = w.zn
  local n0 = #z
  for i = 1, n0 do z[i] = nil end
  if q == nil or OPTION_CELL_COUNT == nil or OPTION_CELL_INDEX == nil then return 0 end
  local n = zahl(q, OPTION_CELL_COUNT)
  if n == nil or n < 1 or n ~= floor(n) or n > 14 then return 0 end
  for i = 1, n do
    local ok, opt = pcall(OPTION_CELL_INDEX, i)
    local u = ok and zahl(q, opt) or nil
    if u == nil or u > 5 or u < 0 then
      for k = 1, n do z[k] = nil end
      return 0
    end
    z[i] = u
  end
  return n
end

-- Höchst- und Tiefstwerte mit diesem Akku
local EXTREM = { { "strom", "stromHoch", "leistHoch" }, { "uGes", "leistHoch" }, { "rpm", "rpmHoch" },
  { "temp", "tempHoch" }, { "hoehe", "hoeheHoch" }, { "speed", "speedHoch" }, { "zellen", "zelleTief" },
  { "bec", "becTief" }, { "rssi", "rssiTief" }, { "lq", "lqTief" } }
local function hoch(v, k, x) if x and (v[k] == nil or x > v[k]) then v[k] = x end end
local function tief(v, k, x) if x and (v[k] == nil or x < v[k]) then v[k] = x end end

local function neuerAkku(w)
  local v = w.v
  v.stromHoch, v.rpmHoch, v.tempHoch, v.hoeheHoch, v.speedHoch, v.leistHoch = nil, nil, nil, nil, nil, nil
  v.zelleTief, v.becTief, v.rssiTief, v.lqTief = nil, nil, nil, nil
  w.anker, w.tRuhe, w.prozRuhe, w.whAkku, w.prozStufe = nil, nil, nil, 0, nil
end

local function lesen(w, now, dt)
  local c, v, d = w.cfg, w.v, w.dauer
  local tele = telemetrie(w)
  local testWerte = TEST and (TEST.v or TEST.ohne or TEST.tele ~= nil)
  if testWerte then tele = TEST.tele ~= false end
  if tele then
    if w.tTeleWeg and now - w.tTeleWeg > AKKU_WEG_S then neuerAkku(w) end
    w.tTeleWeg = nil
  elseif w.tTeleWeg == nil then
    w.tTeleWeg = now
  end
  v.tele = tele
  -- Flugphase (Issue #1): Ethos sagt einem Lua nicht, wie viele Phasen ein Modell hat (gemessen 26.2: nur member 0 =
  -- aktuelle Phase). Darum gilt: Die Zeile erscheint erst, wenn das Modell einmal in einer anderen Phase als 0 war; danach
  -- immer, auch in der Standardphase (Text von Ethos). Ein Modell mit nur einer Phase zeigt nie etwas. Ohne Namensvergleich.
  v.phaseName = nil
  local qp, nr, t = w.qPhase, nil, nil
  if qp then
    local ok1, x = pcall(qp.value, qp)
    local ok2, y = pcall(qp.stringValue, qp)
    nr, t = ok1 and x or nil, ok2 and y or nil
  end
  if TEST and TEST.phase then                      -- Testhaken: { { ab Sekunde, Nummer, Name }, … }
    w.tPhase0 = w.tPhase0 or now
    for _, e in ipairs(TEST.phase) do if now - w.tPhase0 >= e[1] then nr, t = e[2], e[3] end end
  end
  if type(nr) == "number" and nr ~= 0 then w.phaseMehr = true end
  if c.phase ~= false and w.phaseMehr and type(t) == "string" and t ~= "" then v.phaseName = t end
  local function s(q) if tele then return zahl(q) end return nil end
  v.uGes, v.strom, v.mahRoh, v.prozS = s(c.uGes), s(c.strom), s(c.mah), s(c.proz)
  v.rpm, v.temp, v.bec = s(c.rpm), s(c.temp), s(c.bec)
  v.hoehe, v.vario, v.speed, v.rssi, v.lq = s(c.hoehe), s(c.vario), s(c.speed), s(c.rssi), s(c.lq)
  local nz = tele and liesZellen(w, c.zellen) or 0
  v.motorAus, v.ansageSw, v.sw1, v.sw2 = aktiv(c.swMotor), aktiv(c.swAnsage), aktiv(c.sw1), aktiv(c.sw2)
  v.gasP = prozent(c.gas)
  v.sender = zahl(w.qSender)
  if testWerte then
    for k, x in pairs(TEST.v or {}) do
      if k == "zellen" then
        for i = 1, #w.zn do w.zn[i] = nil end
        for i, u in ipairs(x) do w.zn[i] = u end
        nz = #x
      else
        v[k] = x
      end
    end
    for _, k in ipairs(TEST.ohne or {}) do v[k] = nil end
    if not tele then
      for k in pairs(BEREICH) do v[k] = nil end
      v.prozS = nil
      nz = 0
    end
  end
  for k in pairs(BEREICH) do if k ~= "proz" then v[k] = imBereich(k, v[k]) end end
  v.prozS = imBereich("proz", v.prozS)
  if v.rpm then v.rpm = v.rpm / max(1, c.polpaare or 1) end
  -- dBm (negativ, ELRS/Crossfire): intern +120 wie ein positiver Wert (Schwellen, Balken), angezeigt wird dBm
  v.dbm = nil
  if v.rssi and v.rssi < 0 then v.rssi, v.dbm = v.rssi + 120, true end
  if v.rssi then                                   -- Wechsel zwischen dBm und dB: Tiefstwert neu beginnen
    if w.dbmAlt ~= nil and w.dbmAlt ~= (v.dbm == true) then v.rssiTief = nil end
    w.dbmAlt = v.dbm == true
  end

  -- Zellen: Fall 2 Zellensensor (tiefste Zelle, Differenz), Fall 1 nur Gesamtspannung ÷ Zellenzahl.
  -- Zellenzahl «automatisch» ohne Zellensensor wird nie geschätzt (bauplan.md Regel 14): Hinweis zum Einstellen.
  v.zFall, v.zDiff, v.zTiefI = nil, nil, nil
  local n = (c.zellenzahl or 0) > 0 and c.zellenzahl or nil
  if nz > 0 then
    local lo, hi, iLo, summe = nil, nil, nil, 0
    for i = 1, nz do
      local u = w.zn[i]
      summe = summe + u
      if lo == nil or u < lo then lo, iLo = u, i end
      if hi == nil or u > hi then hi = u end
    end
    v.zFall, v.zDiff, v.zTiefI = 2, hi - lo, iLo
    n = n or nz
    if v.uGes == nil then v.uGes = summe end
    v.zelle, v.zMittel = lo, summe / nz
  else
    v.zelle, v.zMittel = nil, nil
    if v.uGes and n then
      v.zFall = 1
      v.zelle = v.uGes / n
      v.zMittel = v.zelle
    end
  end
  v.zellen = n
  v.zellenFehlt = tele and n == nil and v.uGes ~= nil and v.uGes > 1 or false
  if (v.uGes and v.uGes < 1) then v.zelle, v.zMittel, v.zFall = nil, nil, nil end   -- kein Flugakku dran

  -- Verbrauch ab dem Nullpunkt (Knopf «AUF 0»). Zählt der Sensor selbst wieder von vorn (neuer Akku, 2 s am
  -- Stück geglaubt), gilt wieder sein Wert, und Akku % und Tiefstwerte beginnen neu.
  -- Nach einem Neustart fehlt mahHoch: dann gilt der gespeicherte Nullpunkt als letzter bekannter Stand, damit ein
  -- Regler, der inzwischen wieder bei 0 beginnt, erkannt wird (Befund Prüfung 20.11.2026).
  local roh = v.mahRoh
  if roh then
    local hoch = w.mahHoch or (((d.mahNull or 0) > 0) and d.mahNull or nil)
    if hoch and roh < hoch - 5 then
      w.tFall = w.tFall or now
      if now - w.tFall >= 2 then
        w.mahHoch, w.tFall = roh, nil
        if (d.mahNull or 0) > 0 then
          d.mahNull = 0
          w.dateiOffen = true
        end
        neuerAkku(w)
      end
    else
      w.mahHoch, w.tFall = roh, nil
    end
  end
  v.mah = roh and max(0, roh - (d.mahNull or 0)) or nil
  v.kap = (v.mah and (c.kapaz or 0) > 0) and v.mah / c.kapaz * 100 or nil

  -- Akku %: 1. Wert vom Regler (wenn so eingestellt). 2. Startwert aus der Ruhespannung, danach mit den
  -- verbrauchten mAh herunterzählen. 3. Ohne Kapazität oder Verbrauch: nur aus der Spannung in Ruhe.
  v.proz, v.prozVon = nil, nil
  if c.prozQuelle ~= 2 and v.prozS then
    v.proz, v.prozVon = v.prozS, 1
  elseif v.zMittel and v.zMittel > 0.5 then
    local ruhe = (v.strom == nil or v.strom < 2) and (v.rpm == nil or v.rpm < 300)
    if not ruhe then
      w.tRuhe = nil
    elseif w.anker == nil then
      w.tRuhe = w.tRuhe or now
      if now - w.tRuhe >= 2 then w.anker = { zelleProzent(v.zMittel, c.akkuart), v.mah or 0 } end
    end
    if (c.kapaz or 0) > 0 and v.mah then
      if w.anker then
        v.proz = w.anker[1] - (v.mah - w.anker[2]) / c.kapaz * 100
      elseif not ruhe then
        v.proz = 100 - v.mah / c.kapaz * 100           -- nie in Ruhe gemessen (Sender im Flug eingeschaltet)
      end
    else
      if ruhe or w.prozRuhe == nil then w.prozRuhe = zelleProzent(v.zMittel, c.akkuart) end
      v.proz = w.prozRuhe
    end
    if v.proz then v.prozVon = 2 end
  end
  if v.proz then v.proz = clamp(v.proz, 0, 100) end
  v.ruhe = w.anker ~= nil and v.prozVon == 2 and (v.strom == nil or v.strom < 2)

  v.leistung = (v.uGes and v.strom) and v.uGes * max(0, v.strom) or nil
  if v.leistung and dt > 0 then w.whAkku = (w.whAkku or 0) + v.leistung * dt / 3600 end
  v.wh = w.whAkku

  -- Neue Quelle für ein Feld (Suche, Menü, gelöschte Sensoren): dessen Höchst-/Tiefstwerte gelten nicht mehr
  -- (0.3.1: «MAX 98400» aus einer früheren Bindung)
  local qa = w.qAlt or {}
  w.qAlt = qa
  for _, e in ipairs(EXTREM) do
    if qa[e[1]] ~= c[e[1]] then
      qa[e[1]] = c[e[1]]
      for i = 2, #e do v[e[i]] = nil end
    end
  end
  if tele then
    hoch(v, "stromHoch", v.strom) hoch(v, "rpmHoch", v.rpm) hoch(v, "tempHoch", v.temp)
    hoch(v, "hoeheHoch", v.hoehe) hoch(v, "speedHoch", v.speed) hoch(v, "leistHoch", v.leistung)
    if v.zelle and v.zelle > 0.5 then tief(v, "zelleTief", v.zelle) end
    if v.bec and v.bec > 0.5 then tief(v, "becTief", v.bec) end
    tief(v, "rssiTief", v.rssi) tief(v, "lqTief", v.lq)
  end
end

-- Einheiten und Kommastellen der Sensoren, Modellname, Herkunft von Akku % (alle 2 s).
local function liesEinheiten(w)
  local c = w.cfg
  w.dz.hoehe, w.dz.speed, w.dz.vario = stellen(c.hoehe, 0), stellen(c.speed, 0), stellen(c.vario, 1)
  local ok, n = pcall(model.name)
  w.modell = (ok and type(n) == "string" and n ~= "") and n or nil
  if TEST and TEST.modell then w.modell = TEST.modell end   -- neutraler Name für Testbilder (nichts von der Funke ins Repo)
  local T, v = w.T, w.v
  local h = v.prozVon == 1 and T.hRegler or (v.prozVon == 2 and T.hRuhe or T.hKeine)
  w.herkunft = h
  if w.fHerkunft then
    if not pcall(w.fHerkunft.value, w.fHerkunft, h) then w.fHerkunft = nil end
  end
end

-- Eine Warnung führen: kommt nach AN_S, geht nach AUS_S (so flattert sie an der Grenze nicht).
local function melde(w, now, name, stufe, bed, wav, wert, einh, dez)
  local m = w.meld[name]
  if m == nil then
    m = { an = false, name = name }
    w.meld[name] = m
  end
  if bed then
    m.weg = nil
    if not m.an then
      m.seit = m.seit or now
      if now - m.seit >= AN_S then
        m.an = true
        m.tAns = nil
      end
    end
  else
    m.seit = nil
    if m.an then
      m.weg = m.weg or now
      if now - m.weg >= AUS_S then m.an = false end
    end
  end
  if m.an then
    m.stufe, m.wav, m.wert, m.einh, m.dez = stufe, wav, wert, einh, dez
    w.nAktiv = w.nAktiv + 1
    w.aktiv[w.nAktiv] = m
  end
  return m.an
end

-- Meldung sofort ganz aus (ohne Entprellung) und aus der Liste der aktiven Meldungen dieses Aufrufs nehmen.
local function stumm(w, name)
  local m = w.meld[name]
  if m == nil then return false end
  m.an, m.seit, m.weg = false, nil, nil
  local n = 0
  for i = 1, w.nAktiv do
    if w.aktiv[i] ~= m then n = n + 1 w.aktiv[n] = w.aktiv[i] end
  end
  w.nAktiv = n
  return false
end
K.stumm = stumm

-- Überwachte Werte: Name, Wert in w.v, true = Alarm unter der Schwelle, Ansage, Einheit, Kommastellen
local UEBERWACHT = {
  { "akku", "proz", true, "akku_tief", "UNIT_PERCENT", 0 },
  { "zelle", "zelle", true, "zelle_tief", "UNIT_VOLT", 2 },
  { "diff", "zDiff", false, "zellen_ungleich", "UNIT_VOLT", 2 },
  { "temp", "temp", false, "regler_heiss", "UNIT_CELSIUS", 0 },
  { "strom", "strom", false, "strom_hoch", "UNIT_AMPERE", 0 },
  { "kap", "kap", false, "kapazitaet", "UNIT_PERCENT", 0 },
  { "bec", "bec", true, "bec_tief", "UNIT_VOLT", 1 },
  { "hoehe", "hoehe", false, "hoehe", "UNIT_METER", 0 },
  { "rssi", "rssi", true, "empfang", "UNIT_DB", 0 },
  { "lq", "lq", true, "empfang", "UNIT_PERCENT", 0 },
}

local function warnungen(w, now)
  local v, g, st = w.v, w.g, w.st
  w.nAktiv = 0
  local d = v.tele
  local hoechst = 0
  for _, u in ipairs(UEBERWACHT) do
    local k, x = u[1], v[u[2]]
    local gw, ga = g[k .. "W"], g[k .. "A"]
    local function jenseits(gr) return gr ~= nil and x ~= nil and ((u[3] and x < gr) or ((not u[3]) and x > gr)) end
    -- «auch bei Motor aus» = nein: dieser Alarm schweigt ganz (Warnung, Alarm, Ton, Ansage, Vibration), solange der
    -- Motor-aus-Schalter aktiv ist. Ohne Schalter (v.motorAus = nil) gilt das nie.
    local still = v.motorAus == true and w.cfg[k .. "Mot"] == false
    local al = d and not still and jenseits(ga) or false
    local einh = _ENV[u[5]] or 0
    local xs = (k == "rssi" and v.dbm and x) and x - 120 or x   -- dBm-Empfänger: Zahl wie in der Anzeige ansagen
    if w.studio and STUDIO and xs then                          -- Studio-Datei: angepassten Wert ansagen (6.4)
      local a = w.studio.werte["lua:" .. STUDIO.UEBERWACHT[k][1]]
      if a then xs = xs * a.faktor + a.versatz end
    end
    local a = melde(w, now, k .. "A", 2, al, u[4], xs, einh, u[6])
    local wn = melde(w, now, k .. "W", 1, d and not still and not al and jenseits(gw) or false, u[4], xs, einh, u[6])
    if still then a, wn = stumm(w, k .. "A"), stumm(w, k .. "W") end
    if x == nil or (gw == nil and ga == nil) then
      st[k] = nil
    elseif still then                              -- Farbe zeigt den Wert weiter, nur die Meldung schweigt
      st[k] = jenseits(ga) and 2 or (jenseits(gw) and 1 or 0)
    else
      st[k] = a and 2 or ((wn or jenseits(gw)) and 1 or 0)
    end
    if st[k] and st[k] > hoechst then hoechst = st[k] end
  end
  if w.studio and STUDIO then                    -- Grenzen der Studio-Datei für Sensoren, Kanäle, weitere Werte
    local h = STUDIO.grenzenExtra(w, now, melde, d, stumm)
    if h > hoechst then hoechst = h end
  end
  -- Ist der Alarm eines Werts an, fällt dessen Warnung weg
  local n = 0
  for i = 1, w.nAktiv do
    local m = w.aktiv[i]
    local alarm = m.stufe == 1 and w.meld[m.name:sub(1, -2) .. "A"]
    if not (alarm and alarm.an) then
      n = n + 1
      w.aktiv[n] = m
    end
  end
  w.nAktiv = n
  local stx = 0
  for i = 1, n do
    if w.aktiv[i].stufe > stx then stx = w.aktiv[i].stufe end
  end
  w.stufe = stx
  if stx == 2 then
    w.zustand = "alarm"
  elseif stx == 1 then
    w.zustand = "warnung"
  elseif not d then
    w.zustand = "keine"
  else
    w.zustand = "ok"
  end
end

-- Ansagen, nie zwei innerhalb von 3 s. Reihenfolge: Alarm, «Motor aus», Ansage auf Schalter, Akku-%-Schritt.
local function ansagen(w, now)
  local c, v = w.cfg, w.v
  -- Ansage auf Schalter (Flanke aus -> ein)
  if v.ansageSw ~= nil then
    if v.ansageSw and w.ansageAlt == false then w.offenSG = true end
    w.ansageAlt = v.ansageSw
  end
  -- Akku % in Schritten beim Entladen
  local sch = c.schritt or 0
  if sch > 0 and v.proz and v.tele then
    local stufe = floor(v.proz / sch)
    if w.prozStufe == nil or stufe > w.prozStufe + 1 then
      w.prozStufe = stufe                               -- erster Wert oder neuer Akku: still übernehmen
    elseif stufe < w.prozStufe and v.proz < (stufe + 1) * sch - 1 then
      w.prozStufe = stufe
      w.offenSchritt = (stufe + 1) * sch
    end
  end
  if w.tAnsage and now - w.tAnsage < ANSAGE_ABSTAND then return end
  -- Alarm (oder Warnung, wenn so eingestellt), im eigenen Takt
  local wahl = nil
  for i = 1, w.nAktiv do
    local m = w.aktiv[i]
    if (m.stufe == 2 or c.warnAnsage) and (m.tAns == nil or now - m.tAns >= w.g.wdh)
      and (wahl == nil or m.stufe > wahl.stufe) then
      wahl = m
    end
  end
  if wahl then
    wahl.tAns = now
    -- Studio-Datei: Ansage und Vibration je Wert; Werte ohne eigene Ansage (Sensoren, Kanäle) nur mit Ton
    local key, S = wahl.name:sub(1, -2), w.studio
    local vib = c.vibration
    if S and S.gVib[key] ~= nil then vib = S.gVib[key] end
    local laut = false
    if wahl.stufe == 2 and c.ton and system.playTone then pcall(system.playTone, 2200, 180, 60) laut = true end
    if (c.ansage or wahl.stufe == 1) and wahl.wav and not (S and S.gAns[key] == false) then
      local da = sage(w, wahl.wav)
      if da or not S then zahlSagen(wahl.wert, wahl.einh, wahl.dez) end   -- ohne Studio-Datei wie bisher
      if da then laut = true end
    end
    -- Entscheid des Autors (20.11.2026): Eine Studio-Datei macht einen Alarm nie ganz stumm. Ist die Ansage aus oder
    -- fehlt sie (Sensoren, Kanäle), kommt ein Ton; ganz still nur mit «aus = true» (dann gibt es keinen Alarm).
    if not laut and wahl.stufe == 2 and S and system.playTone then
      pcall(system.playTone, 2200, 180, 60)
      laut = true
    end
    if vib and wahl.stufe == 2 and system.playHaptic then pcall(system.playHaptic, "- . -") end
    -- Nur was hörbar war, belegt den Abstand zur nächsten Ansage (0.3.2: stille Studio-Einträge blockierten die
    -- Warteschlange). Ohne Studio-Datei wie bisher (Ton und Ansage im Menü aus = stiller Alarm belegt den Platz).
    if laut or not S then w.tAnsage = now return end
  end
  if w.offenMotor then
    w.offenMotor, w.tAnsage = false, now
    if not sage(w, "motor_aus") and system.playTone then pcall(system.playTone, 900, 250, 0) end
    return
  end
  if w.offenSG then
    w.offenSG, w.tAnsage = false, now
    if c.sgProz and v.proz then sage(w, "akku") zahlSagen(v.proz, UNIT_PERCENT, 0) end
    if c.sgZeit then
      local sek = floor(w.akt and w.akt[2] or 0)
      sage(w, "flugzeit")
      zahlSagen(floor(sek / 60), UNIT_MINUTE, 0)
      zahlSagen(sek % 60, UNIT_SECOND, 0)
    end
    if c.sgHoehe and v.hoehe then sage(w, "hoehe") zahlSagen(v.hoehe, UNIT_METER, 0) end
    if c.sgMah and v.mah then sage(w, "verbraucht") zahlSagen(v.mah, UNIT_MILLIAMPERE_HOUR, 0) end
    return
  end
  if w.offenSchritt then
    local p = w.offenSchritt
    w.offenSchritt, w.tAnsage = nil, now
    sage(w, "akku")
    zahlSagen(p, UNIT_PERCENT, 0)
  end
end

-- ---------------------------------------------------------------- Flüge
-- Ein Flug ist eine Liste: 1 Nr, 2 Dauer s, 3 mAh, 4 Wh, 5 max. Strom, 6 max. Leistung, 7 max. Reglertemp.,
-- 8 tiefste Zelle, 9 max. Höhe, 10 max. Speed, 11 Akku % am Ende. Der laufende Flug (w.akt) hat dazu
-- pause, mahLetzt und still.

local function flugEnde(w)
  local a = w.akt
  w.akt = nil
  if w.dialog == "flug" then w.dialog = nil end
  w.tB = 0
  if a == nil or a[1] == nil then return end
  local r = {}
  for i = 1, w.FLUG_N do r[i] = a[i] end
  local l = w.liste
  l[#l + 1] = r
  while #l > w.MAX_FLUEGE do table.remove(l, 1) end
  w.dateiOffen, w.dateiJetzt = true, true
end

-- Einen Flug löschen; der Zähler geht um eins zurück, spätere Nummern rücken nach (Muster heli-lua).
local function flugLoeschen(w, nr)
  nr = gut(nr)
  if nr == nil then return false end
  nr = floor(nr)
  local weg = false
  if w.akt and w.akt[1] == nr then
    w.akt, weg = nil, true
    w.flugSperre = true                       -- bis der Motor aus ist, beginnt kein neuer Flug
  else
    for i, r in ipairs(w.liste) do
      if r[1] == nr then
        table.remove(w.liste, i)
        weg = true
        break
      end
    end
  end
  w.wahl = nil
  if not weg then return false end
  w.dauer.fluege = max(0, (w.dauer.fluege or 0) - 1)
  for _, r in ipairs(w.liste) do
    if r[1] and r[1] > nr then r[1] = r[1] - 1 end
  end
  if w.akt and w.akt[1] and w.akt[1] > nr then w.akt[1] = w.akt[1] - 1 end
  w.dateiOffen, w.dateiJetzt = true, true
  return true
end

local function flug(w, now, dt)
  local c, v = w.cfg, w.v
  local a = w.akt
  -- Pausierter Flug von vor dem Neustart: Ob der Akku inzwischen gewechselt wurde, ist nicht feststellbar. Mit
  -- «Akkuwechsel beendet Flug» wird er darum gleich abgeschlossen, bevor ein neuer Motorlauf ihn fortsetzen kann
  -- (Befund Prüfung 20.11.2026).
  if a and a.pause and a.vorNeustart and c.akkuEnde then
    flugEnde(w)
    a = nil
  end
  -- Motor an? Mit Motorschalter (Einstellung und Schalter da) nach Schalter, sonst nach Strom oder Gas.
  local schalter = c.erkennung ~= 2 and v.motorAus ~= nil
  local an
  if schalter then
    an = not v.motorAus
  else
    an = (v.strom ~= nil and v.strom >= (c.flugStrom or 3)) or (v.gasP ~= nil and v.gasP >= (c.gasSchwelle or 10))
  end
  w.schalterModus = schalter
  local war = w.motorAn
  w.motorAn = an
  if w.flugSperre then
    if not an then w.flugSperre = nil end
    return
  end
  if schalter and war == true and not an and c.motorAus then w.offenMotor = true end

  if an then
    if a == nil then
      a = { nil, 0 }
      w.akt = a
      if STUDIO and w.studio then STUDIO.flugNeu(w) end   -- Min/Max/Mittel der Studio-Plätze je Flug
    elseif a.pause then
      a.pause, a.mahLetzt, a.vorNeustart = nil, nil, nil   -- Verbrauch während der Pause zählt nicht zum Flug
      if w.dialog == "flug" then w.dialog = nil end
      w.tB = 0
    end
    a.still = nil
  elseif a and not a.pause then
    -- Motor aus: mit Schalter sofort Pause, sonst erst nach «Pause nach» Sekunden ohne Strom und Gas
    a.still = a.still or now
    if schalter or now - a.still >= (c.pauseS or 20) then
      if a[1] then
        a.pause = true
        w.dialog = "flug"
        w.tB = 0
        w.dateiOffen, w.dateiJetzt = true, true    -- offenen Flug sichern
      else
        w.akt, a = nil, nil                        -- zu kurz für einen Flug: verwerfen
      end
    end
  end
  if a and a.pause and c.akkuEnde and w.tTeleWeg and now - w.tTeleWeg > AKKU_WEG_S then
    flugEnde(w)
    return
  end
  if a == nil or a.pause or not an then return end

  a[2] = (a[2] or 0) + dt
  if a[1] == nil and a[2] >= (c.flugMin or 30) then
    w.dauer.fluege = (w.dauer.fluege or 0) + 1
    a[1] = w.dauer.fluege
    w.dateiOffen = true
  end
  if v.mah then
    a[3] = a[3] or 0
    if a.mahLetzt and v.mah > a.mahLetzt then a[3] = a[3] + (v.mah - a.mahLetzt) end
    a.mahLetzt = v.mah
  end
  if v.leistung then a[4] = (a[4] or 0) + v.leistung * dt / 3600 end
  if v.strom and (a[5] == nil or v.strom > a[5]) then a[5] = v.strom end
  if v.leistung and (a[6] == nil or v.leistung > a[6]) then a[6] = v.leistung end
  if v.temp and (a[7] == nil or v.temp > a[7]) then a[7] = v.temp end
  if v.zelle and v.zelle > 0.5 and (a[8] == nil or v.zelle < a[8]) then a[8] = v.zelle end
  if v.hoehe and (a[9] == nil or v.hoehe > a[9]) then a[9] = v.hoehe end
  if v.speed and (a[10] == nil or v.speed > a[10]) then a[10] = v.speed end
  if v.proz then a[11] = v.proz end
  if a[1] and now - (w.tAkt or -1000) >= DAUER_S then   -- laufenden Flug ab und zu sichern
    w.tAkt = now
    w.dateiOffen = true
  end
end

-- Testhaken: Zustand alle 0,5 s als JSON in test-zustand.json (nur Simulator, nur mit TEST.zustand).
local function testZustand(w, now)
  if now - (w.tZustand or -10) < 0.5 then return end
  w.tZustand = now
  if ZUSTAND == nil then
    local ok, v = pcall(system.getVersion)
    if not (ok and type(v) == "table" and v.simulation) then TEST.zustand = nil return end
    local okL, f = pcall(lade, "testzustand.lua")
    if not okL then TEST.zustand = nil print(tostring(w.name) .. ": Fehler: testzustand.lua " .. tostring(f)) return end
    ZUSTAND = f
  end
  local a = w.akt
  w.testExtra = { akt = a and { nr = a[1], dauer = a[2], pause = a.pause or false } or false, nListe = #w.liste,
    wahl = w.wahl or 0, st = w.st, zellen = w.zn, herkunft = w.herkunft or "", schalter = w.schalterModus or false, suchHinweis = w.suchHinweis or false,
    studio = w.studioZustand or "", studioFehler = w.studioFehler or 0, kennung = w.studioKennung or "",
    studioHinweis = w.sHinweis or "", kapaz = w.cfg.kapaz, akkuW = w.cfg.akkuW, akkuA = w.cfg.akkuA }
  local ok, e = pcall(ZUSTAND, w, now, "test-zustand.json")
  if not ok or not e then print(tostring(w.name) .. ": Fehler: Testzustand konnte nicht geschrieben werden " .. tostring(e)) end
end

-- Testhaken einmalig: Flüge, laufender Flug, Seite, Rückfrage
local function testStart(w)
  if not TEST or w.testFertig then return end
  w.testFertig = true
  if TEST.liste then
    w.liste = {}
    for i, r in ipairs(TEST.liste) do w.liste[i] = r end
    w.dauer.fluege = TEST.fluege or #TEST.liste
  end
  if TEST.akt then
    w.akt = {}
    for i, x in ipairs(TEST.akt) do w.akt[i] = x end
    w.akt.pause = TEST.akt.pause
    w.motorAn = TEST.akt.pause and false or true
  end
  if TEST.seite then w.seite = TEST.seite end
  if TEST.wahl then w.wahl = TEST.wahl end
  if TEST.dialog then w.dialog = TEST.dialog end
  if TEST.mahNull then w.dauer.mahNull = TEST.mahNull end
  if TEST.wh then w.whAkku = TEST.wh end
end

-- Studio-Hinweis: Band unten (8 s), danach «!» oben rechts bis zum nächsten Modellwechsel; Text auch ins Log
-- Format 2: Schmuck der Studio-Datei (Referenz studio_symbole.lua, nur geladen bei format = 2) freigeben
local function symFrei(w)
  if w.sym then pcall(w.sym.freigeben) end
  w.sym, w.symOffen = nil, false
end

local function studioHinweis(w, text, now)
  w.sHinweis, w.sHinweisBis, w.sAusruf = text, now + STUDIO_HINWEIS_S, true
  print(tostring(w.name) .. ": " .. text)
end

-- Studio-Datei (Lua-Studio-Format v1): einmal nach dem Laden des Modells in Schritten lesen, danach laufend
-- Quellen suchen, Min/Max/Kurven führen, Änderungen aus dem Menü in .funke.lua schreiben und die Info-Datei.
local function studioWecke(w, now, nurLaden)
  local T = w.T
  if STUDIO == nil then
    local ok, m = pcall(lade, "studio.lua")
    if not ok then
      print(tostring(w.name) .. ": studio.lua nicht ladbar: " .. tostring(m))
      w.studioFertig, w.infoOffen = true, false
      return
    end
    STUDIO = m
    if not w.studioFertig then return end           -- 0.7.1 (A2): felder.lua erst im nächsten Aufruf
  end
  if not w.studioFertig then
    local F = w.studioF
    if F == nil then                                -- 0.7.1 (A2): einmal je Ladevorgang, eigener Aufruf, danach frei
      w.studioF = lade("felder.lua")
      return
    end
    if TEST and TEST.kennung then w.testKennung = TEST.kennung end   -- neutrale Kennung für Testbilder
    if TEST and TEST.lay and not w.testLay then w.lay, w.testLay = TEST.lay, true end   -- Wahl wie der Menü-Setter
    if TEST and TEST.orte then STUDIO.ORTE = TEST.orte end   -- Suchorte nachstellen (Simulator: ein Ordner für alle)
    local okJ, J = true, w.studioWarte
    w.studioWarte = nil
    if J and not J.werk then                         -- 0.7.1 (A2): Einstellungen anwenden, Rest im nächsten Aufruf
      local okA, e = pcall(STUDIO.anwenden1, w, J, F)
      if okA then w.studioWarte, w.schwer = J, true return end
      okJ, J = false, e
    end
    if okJ and J == nil then
      okJ, J = pcall(STUDIO.schritt, w, F)
      -- 0.7.1 (A2): fertig geladene Datei erst im nächsten Aufruf anwenden (Befehlsgrenze wakeup)
      if okJ and J and J.zustand == "geladen" then w.studioWarte = J return end
    end
    if not okJ then                                     -- Laufzeitfehler beim Laden: Standardanzeige, nie hängen bleiben
      print(tostring(w.name) .. ": Studio-Datei: " .. tostring(J))
      w.studioFertig, w.studioJob, w.studioZustand, w.infoOffen, w.studioF = true, nil, "kaputt", true, nil
      studioHinweis(w, T.studioKaputt, now)
      return
    end
    if J == nil then return end
    if J.zustand == "geladen" and J.t0 then             -- für Sendertests: wie lange das Laden nach dem Modellwechsel braucht
      print(string.format("%s: Studio-Datei geladen in %.1f s (%d Schritte)", tostring(w.name), now - J.t0, J.n or 0))
    end
    w.studioFertig, w.infoOffen, w.studioZustand, w.studio = true, true, J.zustand, nil
    w.studioKennung, w.studioF = J.k, nil
    -- 0.7.0: woher die Datei kommt und warum ggf. die Standardanzeige bleibt (R4)
    w.studioQuelle, w.studioWahl = J.quelle, J.wahl or "auto"
    w.sGrund, w.sAngepasst, w.angepasst, w.ansichtGenutzt, w.skalWunsch = nil, nil, false, nil, nil
    w.skalJob, w.skalDeko = nil, nil
    if J.zustand == "kaputt" then w.sGrund = string.format(T.sGrundKaputt, tostring(J.datei))
    elseif J.zustand == "zuNeu" then w.sGrund = T.studioZuNeu
    elseif J.zustand == "fehlt" and J.gewaehltFehlt then w.sGrund = string.format(T.sGrundFehlt, tostring(J.datei))
    elseif J.zustand == "geladen" and next(J.ansichten or {}) == nil then w.sGrund = T.sGrundKeine end
    symFrei(w)
    if J.zustand == "geladen" then
      STUDIO.anwenden(w, J, F)
      w.schwer = true                                   -- in diesem Aufruf keine Sensorsuche (A2)
      if J.roh then                                     -- Format 2: Schmuck in eigenen wakeup prüfen
        local okS, SY = pcall(lade, "studio_symbole.lua")
        if okS and type(SY) == "table" then
          w.sym = SY
          local okA = pcall(SY.start, J.roh)
          w.symOffen = okA
          if not okA then symFrei(w) end
        else
          print(tostring(w.name) .. ": studio_symbole.lua nicht ladbar: " .. tostring(SY))
        end
      end
      grenzen(w)
      w.studioFehler = J.fehler
      if J.fehler > 0 then studioHinweis(w, string.format(T.studioFehler, tostring(J.fehler)), now) end
      if J.funkeVerworfen then studioHinweis(w, T.funkeVerworfen, now) end
    elseif J.zustand == "kaputt" then
      studioHinweis(w, T.studioKaputt, now)
    elseif J.zustand == "zuNeu" then
      studioHinweis(w, T.studioZuNeu, now)
    end
    return
  end
  if w.studio and not nurLaden then STUDIO.wecke(w, now) end
  local sd = w.skalDeko
  if sd then                                              -- 0.7.1 (A2): Schmuck der umgerechneten Ansicht, in Stücken
    local ok, e = pcall(STUDIO.umrechnenDeko, w, sd)
    if not ok then print(tostring(w.name) .. ": Umrechnen Schmuck: " .. tostring(e)) end
    if not (ok and e == false) then w.skalDeko = nil end
    return
  end
  local sw = w.skalWunsch
  if sw and w.studio and not w.symOffen then              -- 0.7.0: Ansicht einmal je Fenstergrösse umrechnen (R3)
    local key = sw[1] .. "x" .. sw[2]
    local ok, n, fertig = pcall(STUDIO.umrechnen, w, sw[1], sw[2], w.skalJob)
    if ok and n and not fertig then w.skalJob = n return end   -- 0.7.1 (A2): in Stücken
    w.skalWunsch, w.skalJob = nil, nil
    if ok and n then
      w.studio.ansichten[key] = n
      if n.dekoVon then w.skalDeko = n end
      local t = string.format(T.sAngepasst, n.von) .. (n.weg > 0 and string.format(T.sWeg, tostring(n.weg)) or "")
      local L = w.L
      if n.unterKopf then w.skalUnterKopf = nil
      elseif L and L.W == sw[1] and L.H == sw[2] then     -- 0.7.2: nur, wenn diese Grösse noch gezeigt wird
        w.sAngepasst = t
        studioHinweis(w, t, now)
        w.sHinweisBis, w.sKurz = now + 5, true          -- 5 s, danach kein «!»
      end
    else
      if not ok then print(tostring(w.name) .. ": Umrechnen: " .. tostring(n)) end
      w.studio.keine = w.studio.keine or {}
      w.studio.keine[key] = true
      w.sGrund = T.sGrundKeine
    end
    w.infoOffen = true
  end
  if w.symOffen and w.sym then                          -- Schmuck: Prüfen in Stücken (nie in paint)
    local ok, fertig = pcall(w.sym.schritt)
    if not ok or fertig then
      w.symOffen = false
    end
  end
  if nurLaden then return end
  if w.funkeOffen and w.studio and now - (w.tFunke or -100) >= 2 then
    w.funkeOffen, w.tFunke = false, now
    local ok, gut = pcall(function() return STUDIO.funkeSchreiben(w.testKennung or STUDIO.kennung(), STUDIO.funkeAusCfg(w, lade("felder.lua"))) end)
    if not (ok and gut) then studioHinweis(w, T.funkeNicht, now) end
  end
  if w.infoOffen then
    local ok, fertig = pcall(STUDIO.infoSchritt, w, w.version, STUDIO.FORMATE or { STUDIO.FORMAT })
    if not ok then print(tostring(w.name) .. ": Info-Datei: " .. tostring(fertig)) end
    if not ok or fertig then
      w.infoOffen = false
      if not w.studio then STUDIO = nil collectgarbage() end   -- ohne Studio-Datei kein Speicher dafür
    end
  end
end

function K.wecke(w)
  local now = os.clock()
  if w.tL == nil then w.tL, w.tE, w.tB = now - DT_LESEN, now - 3, now - 1 end
  if now - w.tL >= DT_LESEN then
    local dt = now - w.tL
    if dt < 0 or dt > 5 then dt = 0 end
    w.tL = now
    testStart(w)
    -- Erster Start ohne gespeicherte Einstellungen: Schalter nach Standard vorgeben (Ethos ruft read nicht immer auf)
    local erst = not w.vorgabe                      -- 0.7.1 (A2): im ersten Aufruf noch keine Studio-Datei laden
    if not w.vorgabe then
      w.vorgabe = true
      if not w.gelesen then schalterVorgabe(w) end
    end
    lesen(w, now, dt)
    if now - w.tE >= 2 then
      w.tE = now
      liesEinheiten(w)
    end
    warnungen(w, now)
    flug(w, now, dt)
    ansagen(w, now)
    if not erst and (not w.studioFertig or w.studio or w.infoOffen) then studioWecke(w, now) end
    if w.sHinweis and now >= w.sHinweisBis then
      w.sHinweis = nil
      if w.sKurz then w.sAusruf, w.sKurz = false, nil end
    end
    if TEST and TEST.zustand then testZustand(w, now) end
    if w.hinweis and now >= w.hinweisBis then w.hinweis = nil end
    -- Datei schreiben: sofort nach einer Rückfrage, sonst frühestens 2 s nach dem letzten Schreiben
    if w.dateiOffen and (w.dateiJetzt or now - (w.tDatei or -100) >= 2) then
      w.dateiOffen, w.dateiJetzt, w.tDatei = false, false, now
      local ok, F = pcall(lade, "felder.lua")
      local okS, erfolg = false, false
      if ok then okS, erfolg = pcall(F.schreibeDatei, w) end
      if not (okS and erfolg) then
        if not w.dateiFehler then print(tostring(w.name) .. ": Fehler: Datei konnte nicht geschrieben werden") end
        w.dateiFehler = true
        w.fehler = "Datei schreiben"
      end
    end
    -- Sensorsuche in Schritten (Ethos begrenzt die Befehle je Aufruf): ein Schritt je wakeup, bis sie fertig ist.
    -- Erster Start ohne gespeicherte Einstellungen: automatisch, sobald Telemetrie da ist (alle 5 s, höchstens 10-mal).
    if w.suche and w.schwer then
      w.schwer = nil                                    -- 0.7.1 (A2): Suche erst im nächsten Aufruf
    elseif w.suche then
      w.schwer = nil
      if SUCHE == nil then
        local okL, f = pcall(lade, "suche.lua")
        SUCHE = okL and f or false
      end
      local ok, n = false, "suche.lua nicht ladbar"
      if SUCHE then ok, n = pcall(SUCHE, w) end
      if not ok or n ~= nil then
        local auto = w.suche == "auto"
        w.suche, w.suchJob, SUCHE = nil, nil, nil
        collectgarbage()
        if ok and type(n) == "number" then
          print(tostring(w.name) .. ": Suche fertig, " .. tostring(n) .. " Sensoren neu zugewiesen")
          if n > 0 or not auto then
            grenzen(w)
            hinweis(w, string.format(auto and w.T.autoSuche or w.T.neuSuche, tostring(n)), now)
            if model and model.dirty then pcall(model.dirty) end
          end
          if auto and (n > 0 or (w.nAuto or 0) >= 10) then w.autoOffen = false end
        else
          print(tostring(w.name) .. ": Fehler in der Sensorsuche: " .. tostring(n))
          w.fehler = "Suche: " .. tostring(n)
          w.autoOffen = false
        end
      end
    elseif w.autoOffen and w.v.tele and not (TEST and (TEST.v or TEST.ohne or TEST.tele ~= nil)) and now - (w.tAuto or -100) >= 5 then
      w.tAuto = now
      w.nAuto = (w.nAuto or 0) + 1
      w.suche = "auto"
    end
  elseif (not w.studioFertig and w.studioJob) or w.symOffen then
    -- Studio-Datei und Schmuck laden: in jedem wakeup ein Schritt, nicht nur alle 0,2 s. Am Sender zeigte das
    -- Vollbild nach dem Modellwechsel noch das Standardlayout (Sendertest Lua-Studio 0.4.0, 21.11.2026; Dauer am
    -- Sender noch ungeklärt, die Log-Zeile «Studio-Datei geladen in … s» misst sie).
    studioWecke(w, now, true)
  end

  if lcd.isVisible and not lcd.isVisible() then return end
  if now - w.tB >= DT_BILD then
    w.tB = now
    if Z == nil then Z = lade("zeichnen.lua") end
    if SEITE[w.seite] == nil then
      for i = 1, SEITEN do SEITE[i] = nil end
      collectgarbage()
      SEITE[w.seite] = lade("seite" .. w.seite .. ".lua")
    end
    w.blink = floor(now * 2) % 2 == 0
    w.seiten = SEITEN
    lcd.invalidate()
  end
end

-- Hat die Studio-Datei (Rohdaten aus Stufe 1) eine Ansicht mit genau dieser Breite und Höhe? Höchstens 2 Ansichten.
local function kommtAnsicht(J, W, H)
  local l = J.d and J.d.ansichten
  if type(l) ~= "table" then return false end
  for i = 1, 2 do
    local a = l[i]
    if type(a) == "table" and a.breite == W and a.hoehe == H then return true end
  end
  return false
end

function K.zeichne(w)
  if Z == nil then return end
  local W, H = lcd.getWindowSize()
  local L = w.L
  if L == nil or L.W ~= W or L.H ~= H then
    L = Z.layout(W, H)
    w.L = L
  end
  Z.punkt = w.sp == 2            -- Englisch: Dezimalpunkt, Tausender mit Komma
  Z.LEER_VOLL = LEER_VOLL
  Z.grund(L)
  w.nZiele = 0
  if W < 300 or H < 150 then                    -- zu klein für Tachos und Felder: nur Name und Flugzeit
    local a = w.akt
    Z.text(L, W / 2, H * 0.32, tostring(w.name), 16, Z.C.grau, CENTERED, W - 8)
    Z.text(L, W / 2, H * 0.68, Z.zeit(a and a[2] or 0), 34, Z.C.weiss, CENTERED, W - 8, true)
    return
  end
  local fe = w.fenster or {}                       -- Fenstergrössen für die Info-Datei
  w.fenster = fe
  local neu = true
  for _, f in ipairs(fe) do if f[1] == W and f[2] == H then neu = false end end
  if neu and #fe < 8 then fe[#fe + 1] = { W, H } w.infoOffen = true end
  local S = SEITE[w.seite]
  local A = w.studio and w.seite == 1 and w.studio.ansichten[W .. "x" .. H]
  local J = w.studioJob
  local warte = false
  if w.studio and w.seite == 1 and not A and next(w.studio.ansichten) and not (w.studio.keine and w.studio.keine[W .. "x" .. H]) then
    if w.skalWunsch == nil then w.skalWunsch = { W, H } end   -- umrechnen im wakeup, nicht hier (Befehlsgrenze)
    warte = true
  end
  -- 0.7.4 (A1): ragt eine genau passende Ansicht in die eigene Kopfzeile, alle Plätze darunter schieben (einmal, im wakeup)
  if A and not A.angepasst and not A.unterKopf and not A.kopfGeprueft then
    A.kopfGeprueft = true
    for _, q in ipairs(A.plaetze) do if q.y < L.kh then A.zuHoch = true end end
  end
  if A and A.zuHoch then
    if w.skalWunsch == nil then w.skalWunsch, w.skalUnterKopf = { W, H }, true end
    A, warte = nil, true
  end
  if A then
    local g = A.von or (W .. "x" .. H)
    if g ~= w.ansichtGenutzt or (A.angepasst == true) ~= w.angepasst then
      w.ansichtGenutzt, w.angepasst, w.infoOffen = g, A.angepasst == true, true
      if not A.angepasst then w.sAngepasst = nil end   -- 0.7.2: genau passende Ansicht, Hinweis «angepasst» gilt nicht mehr
    end
  end
  if A and STUDIO then                             -- Ansicht der Studio-Datei für genau diese Fenstergrösse
    if ANSICHT == nil then ANSICHT = lade("ansicht.lua") end
    ANSICHT.zeichne(w, L, Z, A, STUDIO)
  elseif warte or (w.seite == 1 and not w.studioFertig and J and J.stufe and J.stufe >= 2 and kommtAnsicht(J, W, H)) then
    -- Studio-Datei gefunden und sie hat eine Ansicht für genau diese Fenstergrösse: nicht kurz das Standardlayout
    -- zeigen. Ohne passende Ansicht gilt Format 2, 7.1 (eingebaute Belegung, solange die Prüfung läuft).
    Z.text(L, W / 2, H / 2, w.T.studioLaedt, 20, Z.C.grau, CENTERED, W - 16)
  elseif S then
    S.zeichne(w, L, Z)
  end
  -- Standardanzeige trotz Datei: Grund in der Kopfzeile (R4, A1: nie über den Plätzen)
  w.kopfGrund = (w.seite == 1 and not A and not warte and w.sGrund) or nil
  Z.kopf(w, L)
  Z.hinweis(w, L)
  Z.studioHinweis(w, L)
  if w.dialog then
    w.zielAb = w.nZiele + 1      -- bei offener Rückfrage zählen nur ihre eigenen Knöpfe
    Z.dialog(w, L)
  end
end

local function treffer(w, x, y)
  local ab = w.dialog and (w.zielAb or 1) or 1
  for i = w.nZiele or 0, ab, -1 do         -- zuletzt gezeichnet liegt oben
    local z = w.ziele[i]
    if x >= z.x and x < z.x + z.b and y >= z.y and y < z.y + z.h then return z.id, z.arg end
  end
  return nil
end

-- Aktion nach Antippen oder aus dem Menü. Alles, was Daten löscht, geht nur über eine Rückfrage mit «JA, …».
local function aktion(w, id, arg, now)
  local T = w.T
  if id == "abbrechen" then
    w.dialog = nil
  elseif id == "auf0" then
    w.dialog = "auf0"
  elseif id == "ja_auf0" then
    w.dialog = nil
    local v = w.v
    w.dauer.mahNull = max(0, floor((v.mahRoh or w.mahHoch or 0) + 0.5))
    neuerAkku(w)
    if w.akt then w.akt.mahLetzt = nil end
    hinweis(w, T.aufNull, now)
    w.dateiOffen, w.dateiJetzt = true, true
  elseif id == "nur_pause" then
    w.dialog = nil
  elseif id == "ja_flug" then
    w.dialog = nil
    flugEnde(w)
  elseif id == "seite2" then
    w.seite = 2
  elseif id == "seite1" then
    w.seite = 1
  elseif id == "wahl" then
    w.wahl = arg
  elseif id == "loeschen" and w.wahl then
    w.dialog = "loeschen"
  elseif id == "liste" and (#w.liste > 0 or (w.akt and w.akt[1])) then
    w.dialog = "liste"
  elseif id == "ja_loeschen" then
    w.dialog = nil
    local nr = arg or w.wahl
    if flugLoeschen(w, nr) then hinweis(w, string.format(T.geloescht, tostring(floor(nr))), now) end
  elseif id == "lay" then                          -- 0.7.0: Wahl «Studio-Layout» im Menü, gleich neu laden
    w.lay = type(arg) == "string" and arg or ""
    if model and model.dirty then pcall(model.dirty) end
    w.studio, w.studioFertig, w.studioJob, w.funkeOffen, w.studioWarte = nil, false, nil, false, nil
    symFrei(w)
  elseif id == "ja_studio" then                    -- Zurück auf Studio-Stand: .funke.lua löschen, neu laden
    w.dialog = nil
    if STUDIO == nil then STUDIO = lade("studio.lua") end
    STUDIO.funkeSchreiben(w.testKennung or STUDIO.kennung(), nil)
    w.studio, w.studioFertig, w.studioJob, w.funkeOffen, w.studioWarte = nil, false, nil, false, nil
    symFrei(w)
    hinweis(w, T.studioZurueck, now)
  elseif id == "ja_standard" then                  -- ohne Studio-Datei: Einstellungen und Grenzen auf Werk
    w.dialog = nil
    local F = lade("felder.lua")
    local werk, c = F.standard(), w.cfg
    for k, x in pairs(werk) do
      if F.studioEinstellung(k) or k:match("^%l+[WA]$") then c[k] = x end
    end
    local z = F.ZELLE_WERK[c.akkuart] or F.ZELLE_WERK[1]
    c.zelleW, c.zelleA = z[1], z[2]
    grenzen(w)
    hinweis(w, T.standardZurueck, now)
    w.dateiOffen, w.dateiJetzt = true, true
  elseif id == "ja_liste" then
    w.dialog = nil
    w.liste, w.wahl, w.dauer.fluege, w.oben = {}, nil, 0, 0
    if w.akt and w.akt[1] then w.akt, w.flugSperre = nil, true end
    hinweis(w, T.listeWeg, now)
    w.dateiOffen, w.dateiJetzt = true, true
  end
  w.tB = 0
end

-- Einträge der Flugliste, neueste zuerst (der laufende oder pausierte Flug oben)
function K.eintraege(w)
  local e = {}
  if w.akt and w.akt[1] then e[1] = w.akt end
  for i = #w.liste, 1, -1 do e[#e + 1] = w.liste[i] end
  return e
end

-- Wisch nach links/rechts blättert, auf Seite 2 auf/ab rollt die Liste. Drehrad: Seite 1 -> Seite 2, auf
-- Seite 2 wählt es den Flug (vor den ersten Flug = zurück zu Seite 1). Drehungen behält das Widget immer
-- (gemessen 26.1.2: gibt es eine zurück, kommen keine mehr an).
function K.ereignis(w, kat, wert, x, y)
  if kat == EVT_KEY and (wert == KEY_ROTARY_RIGHT or wert == KEY_ROTARY_LEFT) then
    if w.dialog then return true end
    local rechts = wert == KEY_ROTARY_RIGHT
    if w.seite == 1 then
      if rechts then w.seite = 2 end
    else
      local e = K.eintraege(w)
      local i = 0
      for k, r in ipairs(e) do if r[1] == w.wahl then i = k end end
      i = i + (rechts and 1 or -1)
      if i < 1 then
        w.wahl, w.seite = nil, 1
      else
        i = min(i, #e)
        w.wahl = e[i] and e[i][1] or nil
        local sicht = w.sicht or 6
        if i > w.oben + sicht then w.oben = i - sicht end
        if i <= w.oben then w.oben = i - 1 end
      end
    end
    w.tB = 0
    return true
  end
  if kat ~= EVT_TOUCH then return false end
  x, y = gut(x), gut(y)
  if x == nil or y == nil then return false end
  local t = w.touch
  if wert == TOUCH_START then
    local id, arg = treffer(w, x, y)
    w.touch = { x = x, y = y, id = id, arg = arg }
    return w.dialog ~= nil
  elseif wert == TOUCH_MOVE and t then
    local dx, dy = x - t.x, y - t.y
    if abs(dx) > SLOP or abs(dy) > SLOP then t.id = nil end
    if w.dialog then return true end
    if not t.mein and not t.ethos and abs(dx) > SLOP and abs(dx) > abs(dy) then
      local hinein = (dx < 0 and w.seite < SEITEN) or (dx > 0 and w.seite > 1)
      if hinein then t.mein = true else t.ethos = true end
    end
    if w.seite == 2 and not t.mein and not t.ethos and abs(dy) > SLOP and abs(dy) > abs(dx) then t.rollen = true end
    t.dx, t.dy = dx, dy
    if t.rollen then return true end
    return not t.ethos
  elseif wert == TOUCH_END and t then
    w.touch = nil
    if t.mein then
      if abs(t.dx or 0) >= 50 then
        w.seite = clamp(w.seite + ((t.dx < 0) and 1 or -1), 1, SEITEN)
        w.tB = 0
      end
      return true
    end
    if t.rollen then
      local schritte = floor(abs(t.dy or 0) / 40)
      if schritte > 0 then
        local n = #K.eintraege(w)
        w.oben = clamp(w.oben + ((t.dy < 0) and schritte or -schritte), 0, max(0, n - (w.sicht or 6)))
        w.tB = 0
      end
      return true
    end
    local id, arg = treffer(w, x, y)
    if t.id and t.id == id then
      aktion(w, id, arg or t.arg, os.clock())
      return true
    end
    return w.dialog ~= nil
  end
  return false
end

function K.menue(w)
  local F = lade("felder.lua")
  w.studioListe = function()                         -- Liste «Studio-Layout»: nur beim Öffnen des Menüs (R2.4)
    if STUDIO == nil then STUDIO = lade("studio.lua") end
    return STUDIO.liste()
  end
  lade("menue.lua")(w, F, function()
    grenzen(w)
    w.dateiOffen = true
    if w.studio then w.funkeOffen = true end     -- mit Studio-Datei gehen Änderungen nach .funke.lua
    if model and model.dirty then pcall(model.dirty) end
  end, function()
    w.suche, w.suchJob = "menue", nil       -- läuft in den nächsten wakeup-Aufrufen, Hinweis am Ende
    return "gestartet"
  end, function(id, arg)
    aktion(w, id, arg, os.clock())
  end)
end

function K.lies(w)
  local F = lade("felder.lua")
  w.gelesen = F.lies(w)
  if w.datenAlt then w.dateiOffen = true end      -- aus scripts/elektro übernommen: gleich in den neuen Ordner schreiben
  -- Die Studio-Datei gilt über den gelesenen Einstellungen: nach jedem Lesen neu anwenden
  w.studio, w.studioFertig, w.studioJob, w.studioWarte = nil, false, nil, nil
  w.phaseMehr = nil                                -- Flugphase: neues Modell, neu beobachten
  symFrei(w)
  local d = w.dauer
  if not (gut(d.fluege) and d.fluege >= 0) then d.fluege = 0 end
  if not (gut(d.mahNull) and d.mahNull >= 0) then d.mahNull = 0 end
  d.fluege = floor(d.fluege)
  if w.offen then                                  -- pausierter Flug vom letzten Mal
    w.akt = w.offen
    w.akt.pause = true
    w.akt.vorNeustart = true
    w.offen = nil
  end
  w.autoOffen = not w.gelesen
  grenzen(w)
end

function K.schreibe(w)
  local F = lade("felder.lua")
  F.schreibe(w)
end

return K
