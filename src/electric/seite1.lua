-- Electric: Seite 1, Aufbau wie Heli RF. Vollbild: oben vier Tachos, unten links ein grosses Feld (ab Werk Gas %)
-- und die Zahl der Flüge, rechts sechs Felder. Kompaktansicht (Layout mit Kopf- und Fussleiste): oben vier Tachos,
-- unten acht Felder (grosses Feld, Feld 1–6, Flüge). Was in welchem Tacho und Feld steht, wählt man im Menü.
-- Eine Seite zeichnet nur: Werte kommen aus w.v, Texte aus w.T.
local S = {}
local floor, max, min = math.floor, math.max, math.min

-- Inhalt Nummer n für Tacho oder Feld: { titel, wert, einheit, anteil, farbe, unten, untenFarbe, st, akzent }
local function inhalt(w, Z, n, klein)
  local v, c, T, C, st = w.v, w.cfg, w.T, Z.C, w.st
  local function mx(x, e) return x and (T.max .. " " .. x .. e) or nil end
  if n == 1 then
    local unten = v.uGes and ((v.zellen and (string.format("%.0f", v.zellen) .. "S ") or "") .. Z.zahl(v.uGes, 1) .. "V")
    if v.ruhe and unten then unten = unten .. " " .. T.ruhe end
    local uf = C.weiss
    if v.zellenFehlt and v.proz == nil then unten, uf = T.zellenEinst, C.orange end
    return { titel = T.t1, wert = Z.zahl(v.proz, 0), einheit = "%", anteil = v.proz and v.proz / 100,
      farbe = Z.stufenFarbe(st.akku, C.gruen), unten = unten, untenFarbe = uf, st = st.akku, akzent = C.gruen,
      zusatz = unten, zusatzFarbe = uf }
  elseif n == 2 then
    return { titel = T.t2, wert = Z.zahl(v.strom, 0), einheit = T.ampere, anteil = v.strom and v.strom / max(1, c.maxStrom),
      farbe = Z.stufenFarbe(st.strom, C.blau), unten = mx(Z.zahl(v.stromHoch, 0), "A"), untenFarbe = C.gelb, st = st.strom,
      akzent = C.blau, einheitKurz = "A" }
  elseif n == 3 then
    return { titel = T.t3, wert = Z.zahl(v.rpm, 0), einheit = T.umin, anteil = v.rpm and v.rpm / max(1, c.maxRpm),
      farbe = C.hblau, unten = mx(Z.zahl(v.rpmHoch, 0), ""), untenFarbe = C.gelb, akzent = C.hblau }
  elseif n == 4 then
    return { titel = T.t4, wert = Z.zahl(v.temp, 0), einheit = "°C", anteil = v.temp and v.temp / max(1, c.maxTemp),
      farbe = Z.stufenFarbe(st.temp, C.gruen), unten = mx(Z.zahl(v.tempHoch, 0), "°C"), untenFarbe = C.gelb, st = st.temp,
      akzent = Z.stufenFarbe(st.temp, C.gruen) }
  elseif n == 5 then
    local lv = Z.LEER_VOLL[c.akkuart] or Z.LEER_VOLL[1]
    local titel = v.zFall == 2 and (klein and T.t5k or T.t5z) or T.t5
    local unten = v.zFall == 2 and (v.zDiff and ("Δ " .. Z.zahl(v.zDiff, 2) .. "V"))
      or (v.zelleTief and ((klein and "↓" or (T.tief .. " ")) .. Z.zahl(v.zelleTief, 2) .. "V"))
    local uf = C.titel
    if v.zellenFehlt then unten, uf = T.zellenKurz, C.orange end
    local stz = st.zelle
    if st.diff and (stz == nil or st.diff > stz) then stz = st.diff end
    return { titel = titel, wert = v.zelle and (Z.zahl(v.zelle, 2) .. "V"), einheit = "V",
      anteil = v.zelle and (v.zelle - lv[1]) / (lv[2] - lv[1]), farbe = Z.stufenFarbe(stz, C.gruen),
      unten = unten, untenFarbe = uf, st = stz, wertFarbe = C.gruen, zellen = true, akzent = C.gruen }
  elseif n == 6 then
    return { titel = T.t6, wert = v.uGes and (Z.zahl(v.uGes, 1) .. "V"), einheit = "V",
      anteil = v.zelle and (v.zelle - 3.3) / 0.9, farbe = C.gruen,
      unten = v.zellen and (string.format("%.0f", v.zellen) .. "S"), akzent = C.gruen }
  elseif n == 7 then
    return { titel = klein and T.t7k or T.t7, wert = v.mah and string.format("%.0f", v.mah), einheit = "mAh",
      anteil = v.kap and v.kap / 100, farbe = Z.stufenFarbe(st.kap, C.blau), unten = "mAh", st = st.kap, knopf = true,
      akzent = C.blau }
  elseif n == 8 then
    local p = v.leistung and (v.leistung >= 10000 and (Z.zahl(v.leistung / 1000, 1) .. " kW") or (string.format("%.0f", v.leistung) .. " W"))
    return { titel = klein and T.t8k or T.t8, wert = p, einheit = "W",
      anteil = v.leistung and v.uGes and v.leistung / max(1, v.uGes * c.maxStrom), farbe = C.blau,
      unten = v.wh and (Z.zahl(v.wh, 1) .. " Wh"), akzent = C.blau }
  elseif n == 9 then
    local e = (w.dz.hoehe or 0) > 0 and 1 or 0
    return { titel = T.t9, wert = v.hoehe and (Z.zahl(v.hoehe, e) .. " m"), einheit = "m",
      anteil = v.hoehe and v.hoehe / max(1, (w.g.hoeheA or 150) * 1.2), farbe = Z.stufenFarbe(st.hoehe, C.hblau),
      unten = v.vario and ((v.vario >= 0 and "↑ " or "↓ ") .. Z.zahl(math.abs(v.vario), 1) .. " m/s"),
      links = (not klein) and v.hoeheHoch and (T.max .. " " .. Z.zahl(v.hoeheHoch, 0) .. " m") or nil,
      ringUnten = v.hoeheHoch and (T.max .. " " .. Z.zahl(v.hoeheHoch, 0) .. " m"), st = st.hoehe, akzent = C.hblau }
  elseif n == 10 then
    return { titel = T.t10, wert = v.vario and ((v.vario >= 0 and "↑" or "↓") .. Z.zahl(math.abs(v.vario), 1)),
      einheit = "m/s", anteil = v.vario and math.abs(v.vario) / 5, farbe = C.hblau, unten = "m/s", akzent = C.hblau }
  elseif n == 11 then
    return { titel = T.t11, wert = v.speed and (string.format("%.0f", v.speed) .. (klein and "" or " km/h")), einheit = "km/h",
      anteil = v.speed and v.speed / 200, farbe = C.hblau, unten = mx(v.speedHoch and string.format("%.0f", v.speedHoch), ""),
      untenFarbe = C.titel, akzent = C.hblau }
  elseif n == 12 then
    local z = nil
    if v.lq then z = "LQ " .. string.format("%.0f", v.lq) .. "%" end
    local d0 = v.dbm and 120 or 0                    -- dBm-Sensor: so anzeigen, wie er im Sensormenü steht
    if v.zweiBand then                               -- 0.10.0: beide Bänder (VFR, sonst RSSI), gross steht das bessere
      local function b(x, e) return x and (string.format("%.0f", x) .. e) or "--" end
      if v.vfr24 or v.vfr900 then z = "2.4 " .. b(v.vfr24, "%") .. "  900 " .. b(v.vfr900, "%")
      else z = "2.4 " .. b(v.rssi24, "") .. "  900 " .. b(v.rssi900, "") end
    end
    if v.rssiTief and not (klein and z) and not v.zweiBand then z = (z and (z .. "  ") or "") .. T.tief .. " " .. string.format("%.0f", v.rssiTief - d0) end
    local stx = st.rssi
    for _, k in ipairs({ "lq", "rssi24", "rssi900", "vfr24", "vfr900", "rxvfr" }) do   -- 0.10.0: auch die Bänder
      if st[k] and (stx == nil or st[k] > stx) then stx = st[k] end
    end
    local eh = v.dbm and "dBm" or "dB"
    local wert = v.rssi and (string.format("%.0f", v.rssi - d0) .. " " .. eh) or (v.lq and (string.format("%.0f", v.lq) .. "%"))
    return { titel = T.t12, wert = wert, einheit = eh, anteil = v.rssi and v.rssi / 100 or (v.lq and v.lq / 100),
      farbe = Z.stufenFarbe(stx, C.gruen), unten = z, st = stx, wertFarbe = C.gruen, akzent = C.gruen }
  elseif n == 13 then
    return { titel = T.t13, wert = v.bec and (Z.zahl(v.bec, 1) .. "V"), einheit = "V", anteil = v.bec and v.bec / 8.4,
      farbe = Z.stufenFarbe(st.bec, C.gruen), unten = v.becTief and (T.tief .. " " .. Z.zahl(v.becTief, 1) .. "V"),
      st = st.bec, akzent = C.akzent }
  elseif n == 14 then
    local a = w.akt
    return { titel = T.t14, wert = Z.zeit(a and a[2] or 0), einheit = "", anteil = a and a[2] and a[2] / 600,
      farbe = C.blau, unten = nil, akzent = C.blau }
  elseif n == 15 then                                    -- Gas % aus dem Gaskanal, zum Vergleich mit dem Strom
    local unten, uf = nil, C.titel
    if c.gas == nil and v.gasP == nil then
      unten, uf = T.gasWaehlen, C.orange
    elseif v.strom then
      unten = string.format(T.bei, string.format("%.0f", v.strom))
    end
    return { titel = T.t15, wert = v.gasP and (string.format("%.0f", v.gasP) .. " %"), einheit = "%",
      anteil = v.gasP and v.gasP / 100, farbe = C.hblau, unten = unten, untenFarbe = uf, akzent = C.hblau, gas = true }
  end
  return nil
end

local function tacho(w, L, Z, x, y, b, h, n)
  local k = inhalt(w, Z, n, L.klein)
  if k == nil then
    Z.kachel(L, x, y, b, h)
    return
  end
  if n == 9 then k.unten = k.ringUnten end
  if k.wert and k.einheit and (n == 5 or n == 6 or n == 8 or n == 9 or n == 11 or n == 12 or n == 13) then
    k.wert = k.wert:gsub("%s*[%a/]+$", "")             -- im Tacho steht die Einheit unter der Zahl
  end
  if n == 8 and w.v.leistung and w.v.leistung >= 10000 then k.einheit = "kW" end
  if n == 15 and w.v.gasP then k.wert = string.format("%.0f", w.v.gasP) end
  Z.ring(L, x, y, b, h, k)
end

local function feld(w, L, Z, x, y, b, h, n, gross)
  local C, s = Z.C, L.s
  local k = inhalt(w, Z, n, L.klein)
  if k == nil then
    Z.kachel(L, x, y, b, h)
    return
  end
  if gross then                                          -- grosses Feld: grosse Zahl, Balken, Zusatz darunter
    Z.feld(L, x, y, b, h, { titel = k.titel, wert = k.wert, zusatz = k.unten, zusatzFarbe = k.untenFarbe,
      farbe = k.wertFarbe or (k.gas and C.hblau) or C.weiss, st = k.st, gr = 50, balken = k.anteil or 0,
      balkenFarbe = k.farbe })
    return
  end
  local zusatz = k.unten
  if n == 7 then zusatz = "mAh" end
  if n == 1 then k.wert = k.wert and (k.wert .. " %") end
  if n == 2 or n == 3 or n == 4 then k.wert = k.wert and (k.wert .. (k.einheitKurz or (n == 4 and "°C" or ""))) end
  Z.feld(L, x, y, b, h, { titel = k.titel, wert = k.wert, zusatz = zusatz, zusatzFarbe = k.untenFarbe,
    farbe = k.wertFarbe or C.weiss, st = k.st, links = k.links })
  if n == 7 then                                         -- Knopf «AUF 0»: fragt immer nach
    local kb, kh = max(54 * s, 46), max(20 * s, 16)
    Z.knopf(w, L, "auf0", x + 10 * s, y + h - 10 * s - kh, kb, kh, w.T.auf0, C.akzent, false, 10, C.weiss)
    -- grössere Tippfläche für den Finger (unsichtbar)
    if L.kompakt then Z.ziel(w, "auf0", x, y, b, h) else Z.ziel(w, "auf0", x, y + h * 0.45, b * 0.45, h * 0.55) end
  elseif n == 5 and w.v.zelle and not w.v.zellenFehlt then
    -- Fall 1: Balken mit der Gesamtspannung; Fall 2: ein Balken je Zelle (tiefste gelb)
    local v, cfg = w.v, w.cfg
    local lv = Z.LEER_VOLL[cfg.akkuart] or Z.LEER_VOLL[1]
    local function anteil(u) return max(0, min(1, (u - lv[1]) / (lv[2] - lv[1]))) end
    local bx, bb = x + 14 * s, b * (L.klein and 0.34 or 0.40)
    local bh = max(7, floor(10 * s))
    local by = y + h - 15 * s - bh / 2
    local fz = Z.stufenFarbe(k.st, C.gruen)
    if v.zFall == 2 then
      local n2 = #w.zn
      local sb = bb / max(1, n2)
      local ph = max(14, floor(22 * s))
      for i = 1, n2 do
        local u = w.zn[i] or 0
        local hh = ph * (0.25 + 0.75 * anteil(u))
        Z.rechteck(bx + (i - 1) * sb, by + bh - ph, max(1, sb - 2), ph, C.spur)
        Z.rechteck(bx + (i - 1) * sb, by + bh - hh, max(1, sb - 2), hh, i == v.zTiefI and (w.st.diff and w.st.diff > 0 and Z.stufenFarbe(w.st.diff, C.gelb) or C.gelb) or C.gruen)
      end
    else
      Z.rund(bx, by, bb, bh, 2 * s, C.spur)
      local f = anteil(v.zelle)
      if f > 0 then Z.rund(bx, by, max(2, bb * f), bh, 2 * s, fz) end
      if v.uGes then Z.text(L, bx, by - max(9 * s, 7), Z.zahl(v.uGes, 1) .. "V", 11, C.titel, LEFT, bb) end
    end
  end
end

-- Zahl der Flüge (antippen öffnet die Flugliste)
local function fluege(w, L, Z, x, y, b, h, alsFeld)
  local C, T = Z.C, w.T
  local n = w.dauer.fluege or 0
  if alsFeld then
    Z.feld(L, x, y, b, h, { titel = T.flugListe, wert = string.format("%.0f", n), farbe = C.weiss })
  else
    Z.kachel(L, x, y, b, h)
    local t = n == 1 and T.flug1 or string.format(T.fluege, string.format("%.0f", n))
    Z.text(L, x + b / 2, y + h / 2, t, 16, C.weiss, CENTERED, b - 12 * L.s, true)
  end
  Z.ziel(w, "seite2", x, y, b, h)
end

-- Kompaktansicht: vier Tachos, darunter zwei Reihen mit je vier Feldern (Konzept «Luas kompakt», 20.11.2026)
local function kompakt(w, L, Z)
  local W, H, g, c = L.W, L.H, L.gp, w.cfg
  local y1 = L.y0
  local frei = H - y1 - 2 * g
  local h1 = floor(frei * 0.54)
  local b1 = (W - 5 * g) / 4
  for i = 1, 4 do tacho(w, L, Z, g + (i - 1) * (b1 + g), y1, b1, h1, c["t" .. i] or 0) end
  local y2 = y1 + h1 + g
  local hf = (H - y2 - 2 * g) / 2
  local bf = (W - 5 * g) / 4
  local liste = { c.fGross or 15, c.f1 or 0, c.f2 or 0, c.f3 or 0, c.f4 or 0, c.f5 or 0, c.f6 or 0 }
  for i = 1, 8 do
    local x, y = g + ((i - 1) % 4) * (bf + g), y2 + ((i - 1) // 4) * (hf + g)
    if i == 8 then fluege(w, L, Z, x, y, bf, hf, true) else feld(w, L, Z, x, y, bf, hf, liste[i]) end
  end
end

function S.zeichne(w, L, Z)
  if L.kompakt then return kompakt(w, L, Z) end
  local W, H, g, s, c = L.W, L.H, L.gp, L.s, w.cfg
  local y1 = L.y0
  local h1 = floor(198 * s)
  local b1 = (W - 5 * g) / 4
  for i = 1, 4 do tacho(w, L, Z, g + (i - 1) * (b1 + g), y1, b1, h1, c["t" .. i] or 0) end
  local y2 = y1 + h1 + g
  local h2 = H - y2 - g
  local bb = floor(232 * s)
  local fh = max(floor(40 * s), L.tipp)
  feld(w, L, Z, g, y2, bb, h2 - fh - g, c.fGross or 15, true)
  fluege(w, L, Z, g, H - g - fh, bb, fh, false)
  local x0 = 2 * g + bb
  local bf, hf = (W - x0 - 3 * g) / 3, (h2 - g) / 2
  for i = 1, 6 do
    local col, row = (i - 1) % 3, (i - 1) // 3
    feld(w, L, Z, x0 + col * (bf + g), y2 + row * (hf + g), bf, hf, c["f" .. i] or 0)
  end
end

return S
