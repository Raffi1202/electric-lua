-- Electric: Sensoren automatisch zuweisen (Vorgaben Sensorzuordnung, 20.11.2026).
-- Füllt nur leere Felder; was von Hand gesetzt ist, bleibt. Vorher wird jedes zugewiesene Telemetriefeld neu an
-- den Sensor der aktuellen Liste gebunden (gleiche AppID, Teilwert, Physical ID und Name); ohne Gegenstück wird es
-- frei und neu gesucht (0.3.1: nach «Alle Sensoren löschen» lieferten alte Verweise am Sender 0 und Alarm).
-- Stufe 1, Kennung: AppID + Teilwert -> Schlüssel (kennung.lua, gemeinsame Tabelle, nur während der Suche
--   geladen). Je Feld eine Rangfolge von Schlüsseln; der erste Schlüssel, zu dem es einen Sensor gibt, gewinnt.
--   Passen mehrere Sensoren (Instanzen, Physical IDs): zuerst der mit gültigem Wert, dann die niedrigste Instanz,
--   dann die niedrigste Physical ID. Dazu ein Hinweis «n Sensoren passen» im Menü.
-- Stufe 2, nur für Sensoren ohne Kennung (DIY 0x5xxx, berechnete, ELRS/CRSF): Name und Einheit als Rückfall.
-- Der Name allein ist kein Merkmal (gleichnamige Sensoren verschiedener Geräte).
-- Ethos begrenzt die Befehle je Aufruf («Max instructions count reached», am Sender mit 37 Sensoren, 20.11.2026):
-- Die Suche läuft darum in Schritten über mehrere wakeup-Aufrufe (Zustand in w.suchJob): je Aufruf höchstens
-- JE_AUFRUF Sensoren lesen bzw. eine Regel der Rückfallstufe. kennung.lua wird einmal nach Bereich indiziert
-- (je Sensor nur die Einträge seines 16er-Bereichs).
-- Rückgabe: nil = läuft noch (wieder aufrufen), sonst die Zahl der neu zugewiesenen Felder (fertig).
-- w.suchHinweis enthält je Feld den Hinweis (oder nichts).
local JE_AUFRUF = 10   -- Sensoren lesen je Aufruf
local JE_REGEL = 25    -- Sensoren je Aufruf in der Rückfallstufe

-- Rangfolge der Schlüssel je Feld. «kraftstoff» (0x0600) ist bei Betaflight/INAV verbrauchte mAh, sonst
-- Akku %: entschieden wird nach der Einheit des Sensors.
local RANG = {
  uGes = { "esc_u", "akku_u", "rb35_bat1_u", "bat1_u", "rb_bat1_u", "rb25_bat1_u", "sp_u", "d_akku_u" },
  zellen = { "zellen" },
  strom = { "esc_i", "strom", "rb35_bat1_i", "bat1_i", "rb_bat1_i", "sp_i", "rb25_i", "d_strom" },
  mah = { "esc_mah", "rb_bat1_mah", "kraftstoff_mah" },
  proz = { "kraftstoff_proz" },
  rpm = { "esc_rpm", "rpm" },
  temp = { "esc_temp", "sp_temp", "temp1" },
  bec = { "bec_u", "rx_batt", "rx_batt1", "bec2_u" },
  hoehe = { "hoehe", "rb35_hoehe", "gps_hoehe", "d_hoehe" },
  vario = { "vario", "rb35_vario", "d_vario" },
  speed = { "airspeed", "gps_speed" },
  rssi = { "rssi", "rx_rssi1", "d_rssi" },
  lq = { "rx_qualitaet" },
  rssi2 = { "rssi_b2" }, vfr = { "vfr" }, vfr2 = { "vfr_b2" }, rxvfr = { "rx_vfr" },   -- 0.10.0: zwei Bänder
  zellen2 = { "zellen" }, bec2 = { "rx_batt2" },     -- 0.10.0: zweiter Zellensensor (andere Physical ID), RxBatt 2
}
local FOLGE = { "uGes", "zellen", "strom", "mah", "proz", "rpm", "temp", "bec", "hoehe", "vario", "speed", "rssi", "lq",
  "rssi2", "vfr", "vfr2", "rxvfr", "zellen2", "bec2" }

-- Rückfall (Stufe 2): Namensteile, Ausschluss (gilt für Namensteil und Einheit), Einheit
local REGELN = {
  { feld = "zellen", teile = { "cell", "zelle", "lipo", "flvs" }, ohne = { "rx" } },
  { feld = "uGes", teile = { "vfas", "volt", "spann", "vbat", "batt" }, ohne = { "rx", "adc", "cell", "zelle", "bec", "%" }, einheit = UNIT_VOLT },
  { feld = "strom", teile = { "curr", "strom", "amp" }, ohne = { "rx" }, einheit = UNIT_AMPERE },
  { feld = "mah", teile = { "consum", "mah", "verbrauch", "capa", "used" }, ohne = {}, einheit = UNIT_MILLIAMPERE_HOUR },
  { feld = "proz", teile = { "bat%", "batt%", "fuel", "charge", "remain", "akku %" }, ohne = { "rx", "lq", "rssi" } },
  { feld = "rpm", teile = { "rpm", "drehz", "headsp" }, ohne = {}, einheit = UNIT_RPM },
  { feld = "temp", teile = { "esc t", "esc_t", "temp esc", "regler" }, ohne = {} },
  { feld = "temp", teile = { "temp", "tmp" }, ohne = { "rx", "gps" }, einheit = UNIT_CELSIUS },
  { feld = "bec", teile = { "bec", "rxbt", "rx batt", "rx volt" }, ohne = {} },
  { feld = "hoehe", teile = { "alt", "höhe", "hoehe", "height" }, ohne = { "gps" }, einheit = UNIT_METER },
  { feld = "vario", teile = { "vspd", "vario", "vsi", "climb" }, ohne = {}, einheit = UNIT_METER_PER_SECOND },
  { feld = "speed", teile = { "speed", "gspd", "aspd" }, ohne = { "vspd", "head" }, einheit = UNIT_KPH },
  { feld = "rssi", teile = { "rssi", "1rss" }, ohne = {} },
  { feld = "lq", teile = { "link q", "rqly", "lq" }, ohne = {} },
}

local function rufe(q, f)
  if type(q[f]) ~= "function" then return nil end
  local okf, v = pcall(q[f], q)
  if okf then return v end
  return nil
end

local function hat(name, teile)
  for _, m in ipairs(teile) do
    if name:find(m, 1, true) then return true end
  end
  return false
end

-- Passt die Art eines Schlüssels zur Einheit des Sensors? (nur für Sensoren ohne Teilwert)
local function passt(key, e)
  if e == nil then return false end
  if key:find("_u$") or key:find("batt") then return e == UNIT_VOLT end
  if key:find("_i$") or key:find("strom") then return e == UNIT_AMPERE end
  if key:find("mah") then return e == UNIT_MILLIAMPERE_HOUR end
  if key:find("rpm") then return e == UNIT_RPM end
  if key:find("temp") then return e == UNIT_CELSIUS end
  return false
end

local function hex(x)
  if type(x) ~= "number" or x ~= x or x < 0 or x > 65535 then return "?" end
  return string.format("%04X", math.floor(x))
end

-- Bereich einer AppID im Index: einzelne IDs unter 0x0100 und ab 0xF000, sonst der 16er-Block
local function bereich(id)
  if id < 0x0100 or id >= 0xF000 then return id end
  return id - id % 16
end

-- Start: Sensorliste holen, kennung.lua laden und indizieren (eine Liste von Einträgen je Bereich)
local function start(w)
  local J = { schritt = "lesen", i = 0, S = {}, nach = {}, n = 0, regel = 0 }
  w.suchHinweis = {}
  if system.getSources and CATEGORY_TELEMETRY_SENSOR then
    local ok, liste = pcall(system.getSources, CATEGORY_TELEMETRY_SENSOR)
    if ok and type(liste) == "table" then J.liste = liste end
  end
  J.liste = J.liste or {}
  J.index, J.ki = {}, 0
  J.schritt = "index"                                -- 0.7.1: Index in Stücken (Befehlsgrenze wakeup, A2)
  return J
end

-- Schlüssel eines Sensors über den Index
local function schluessel(J, s)
  if type(s.id) ~= "number" or s.id ~= s.id or s.id < 0 or s.id > 65535 then return nil end
  local l = J.index[bereich(math.floor(s.id))]
  if l == nil then return nil end
  local erster = nil
  for _, k in ipairs(l) do
    if s.id >= k[1] and s.id <= k[2] then
      if type(s.teil) == "number" then
        if k[3] == nil or k[3] == s.teil then return k[4] end
      else
        -- Ohne Teilwert (gemessen 26.2: per Lua angelegte Sensoren liefern subId = nil): den Eintrag nehmen,
        -- dessen Art zur Einheit passt; sonst den ersten (Teilwert 0).
        erster = erster or k[4]
        if passt(k[4], s.einheit) then return k[4] end
      end
    end
  end
  return erster
end

local function setze(J, c, feld, s)
  if c[feld] ~= nil or s.vergeben then return false end
  c[feld] = s.q
  s.vergeben = true
  J.n = J.n + 1
  return true
end

return function(w)
  local c = w.cfg
  local J = w.suchJob
  if J == nil then
    w.suchJob = start(w)
    return nil
  end

  if J.schritt == "index" then                       -- kennung.lua laden, dann je Aufruf höchstens 50 Einträge
    if J.K == nil then
      local okK, K = pcall(function() local f = loadfile("kennung.lua") return f and f() end)
      J.K = (okK and type(K) == "table") and K or {}
      return nil
    end
    local K = J.K
    local bis = math.min(#K, J.ki + 50)
    for i = J.ki + 1, bis do
      local k = K[i]
      if type(k[1]) == "number" then
        local b = bereich(k[1])
        local l = J.index[b] or {}
        l[#l + 1] = k
        J.index[b] = l
      end
    end
    J.ki = bis
    if bis >= #K then J.K, J.schritt = nil, "lesen" end
    return nil
  end

  if J.schritt == "lesen" then                       -- je Aufruf höchstens JE_AUFRUF Sensoren
    local bis = math.min(#J.liste, J.i + JE_AUFRUF)
    for i = J.i + 1, bis do
      local q = J.liste[i]
      local name = rufe(q, "name")
      local s = { q = q, name = type(name) == "string" and string.lower(name) or "", roh = type(name) == "string" and name or "?",
        id = rufe(q, "appId"), teil = rufe(q, "subId"), phys = rufe(q, "physId"), einheit = rufe(q, "unit") }
      local wert = rufe(q, "value")
      s.wert = type(wert) == "number" and wert == wert and wert ~= 0
      s.key = schluessel(J, s)
      if s.key == "kraftstoff" then
        s.key = (s.einheit == UNIT_MILLIAMPERE_HOUR) and "kraftstoff_mah" or "kraftstoff_proz"
      end
      -- 0.10.0 (Issue #2): RSSI/VFR des zweiten Bands (TD 900 MHz = Band 1, LoRa = Band 2) über band() der Quelle
      -- (gemessen 26.2). Ohne band(): Reihenfolge, der zweite Sensor derselben Art ist das zweite Band.
      if s.key == "rssi" or s.key == "vfr" then
        local b = rufe(q, "band")
        J.zahl = J.zahl or {}
        J.zahl[s.key] = (J.zahl[s.key] or 0) + 1
        if (type(b) == "number" and b ~= 0) or (b == nil and J.zahl[s.key] > 1) then s.key = s.key .. "_b2" end
      end
      J.S[#J.S + 1] = s
      if s.key then
        local l = J.nach[s.key] or {}
        l[#l + 1] = s
        J.nach[s.key] = l
      end
    end
    J.i = bis
    if J.i >= #J.liste then J.schritt, J.index, J.liste = "kennung", nil, nil end
    return nil
  end

  if J.schritt == "kennung" then                     -- Stufe 1: Kennung mit Rangfolge (kleine Listen)
    -- Zuerst neu binden (siehe oben); Quellen ausserhalb der Telemetrie (Kanäle, Schalter) bleiben.
    local function kenn(id, teil, phys, name)
      return tostring(id) .. ":" .. tostring(teil) .. ":" .. tostring(phys) .. ":" .. tostring(name)
    end
    local da = {}
    for _, s in ipairs(J.S) do
      local k = kenn(s.id, s.teil, s.phys, s.roh)
      if da[k] == nil then da[k] = s end
    end
    for _, feld in ipairs(#J.S > 0 and FOLGE or {}) do     -- ohne Sensorliste nichts leeren
      local q = c[feld]
      local kat = q ~= nil and rufe(q, "category") or nil
      if q ~= nil and (kat == nil or kat == CATEGORY_TELEMETRY_SENSOR or (CATEGORY_NONE ~= nil and kat == CATEGORY_NONE)) then
        local name = rufe(q, "name")
        local s = da[kenn(rufe(q, "appId"), rufe(q, "subId"), rufe(q, "physId"), type(name) == "string" and name or "?")]
        if s then
          -- derselbe Sensor, nur ein neues Objekt: Höchst-/Tiefstwerte bleiben (kern.lua vergleicht mit w.qAlt)
          if w.qAlt and w.qAlt[feld] == q then w.qAlt[feld] = s.q end
          c[feld], s.vergeben = s.q, true
        else
          c[feld] = nil
        end
      end
    end
    local function vor(a, b)
      if a.wert ~= b.wert then return a.wert end                         -- (a) liefert gerade einen Wert
      local ia, ib = (a.id or 0) % 16, (b.id or 0) % 16
      if ia ~= ib then return ia < ib end                                -- (b) niedrigste Instanz
      return (a.phys or 99) < (b.phys or 99)                             -- (c) niedrigste Physical ID
    end
    for _, feld in ipairs(FOLGE) do
      if c[feld] == nil then
        for _, key in ipairs(RANG[feld]) do
          local beste, anz = nil, 0
          local physZ = feld == "zellen2" and c.zellen and rufe(c.zellen, "physId") or nil
          for _, s in ipairs(J.nach[key] or {}) do
            if not s.vergeben and not (feld == "zellen2" and (c.zellen == nil or s.phys == physZ)) then
              anz = anz + 1
              if beste == nil or vor(s, beste) then beste = s end
            end
          end
          if beste then
            if setze(J, c, feld, beste) and anz > 1 then
              w.suchHinweis[feld] = { anz, beste.roh, beste.phys, hex(beste.id) }
            end
            break
          end
        end
      end
    end
    J.schritt, J.nach = "rueckfall", nil
    return nil
  end

  -- Stufe 2: Regel für Regel (erst alle Namensteile, dann alle Einheiten), je Aufruf höchstens JE_REGEL Sensoren,
  -- nur Sensoren ohne Kennung
  if J.regel == 0 then J.regel, J.pos = 1, 0 end
  local nr = J.regel
  if nr <= 2 * #REGELN then
    local r = REGELN[nr <= #REGELN and nr or nr - #REGELN]
    local nachName = nr <= #REGELN
    local fertig = c[r.feld] ~= nil or (not nachName and r.einheit == nil)
    if not fertig then
      local bis = math.min(#J.S, J.pos + JE_REGEL)
      for k = J.pos + 1, bis do
        local s = J.S[k]
        if not s.key and not s.vergeben and not hat(s.name, r.ohne)
          and ((nachName and hat(s.name, r.teile)) or ((not nachName) and s.einheit == r.einheit)) then
          setze(J, c, r.feld, s)
          fertig = true
          break
        end
      end
      J.pos = bis
      if J.pos >= #J.S then fertig = true end
    end
    if fertig then J.regel, J.pos = nr + 1, 0 end
    if J.regel <= 2 * #REGELN then return nil end
  end
  w.suchJob = nil
  return J.n
end
