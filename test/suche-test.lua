-- Electric: Pflichtfälle der Sensorzuordnung (Vorgaben Sensorzuordnung 20.11.2026) auf dem Mac, mit nachgebildeten
-- Ethos-Sensoren. Aufruf (im Projektordner): /opt/homebrew/opt/lua@5.4/bin/lua test/suche-test.lua src/electric
local ordner = arg[1] or "src/electric"
local fehler = 0
local function pruef(bed, text) if not bed then fehler = fehler + 1 print("FEHLER: " .. text) end end
CATEGORY_TELEMETRY_SENSOR, UNIT_VOLT, UNIT_AMPERE, UNIT_MILLIAMPERE_HOUR, UNIT_PERCENT = 1, 1, 2, 3, 4
UNIT_RPM, UNIT_CELSIUS, UNIT_METER, UNIT_METER_PER_SECOND, UNIT_KPH = 5, 6, 7, 8, 9
local SENS = {}
system = { getSources = function() return SENS end }
local function sensor(name, id, teil, phys, einheit, wert)
  return { n = name, i = id, t = teil, p = phys, e = einheit, w = wert,
    name = function(s) return s.n end, appId = function(s) return s.i end, subId = function(s) return s.t end,
    physId = function(s) return s.p end, unit = function(s) return s.e end, value = function(s) return s.w end }
end
local alt = loadfile
loadfile = function(p) return alt(ordner .. "/" .. p) end
local suche = assert(loadfile("suche.lua"))
-- Befehle je Aufruf zählen (Ethos bricht bei zu vielen Befehlen in einem Aufruf ab)
local MAXBEF, AUFRUFE = 0, 0
local function schritte(w)
  local f = suche()
  local n, k = nil, 0
  repeat
    local bef = 0
    debug.sethook(function() bef = bef + 1 end, "", 1)
    n = f(w)
    debug.sethook()
    if bef > MAXBEF then MAXBEF = bef end
    k = k + 1
  until n ~= nil or k > 500
  AUFRUFE = math.max(AUFRUFE, k)
  return n
end
local function lauf(liste)
  SENS = liste
  local w = { cfg = {} }
  local n = schritte(w)
  return w, n
end
local function ist(w, feld, s) return w.cfg[feld] == s end

-- (a) gleichnamige Sensoren verschiedener Geräte: «Strom» bei 0x0028 (D-Hub), 0x0200 (FAS), 0x0220 (Strom 2)
local d, fas, s2 = sensor("Strom", 0x0028, 0, 0, UNIT_AMPERE, 5), sensor("Strom", 0x0200, 0, 2, UNIT_AMPERE, 5), sensor("Strom", 0x0220, 0, 3, UNIT_AMPERE, 5)
local w = lauf({ d, s2, fas })
pruef(ist(w, "strom", fas), "(a) Strom: FAS 0x0200 erwartet")
-- Regler vor FAS: ESC 0x0B50 Teil 1 = Strom, Teil 0 = Spannung
local escU, escI = sensor("ESC Spannung", 0x0B50, 0, 4, UNIT_VOLT, 22), sensor("ESC Strom", 0x0B50, 1, 4, UNIT_AMPERE, 30)
local vfas = sensor("VFAS", 0x0210, 0, 2, UNIT_VOLT, 22)
w = lauf({ fas, vfas, escI, escU })
pruef(ist(w, "strom", escI) and ist(w, "uGes", escU), "(a) ESC-Strom/Spannung vor FAS/VFAS")
-- (b) zwei Instanzen derselben AppID: niedrigste Instanz, Hinweis
local i1, i0 = sensor("ESC Temp", 0x0B71, 0, 5, UNIT_CELSIUS, 40), sensor("ESC Temp", 0x0B70, 0, 4, UNIT_CELSIUS, 40)
w = lauf({ i1, i0 })
pruef(ist(w, "temp", i0), "(b) niedrigste Instanz 0x0B70 erwartet")
pruef(w.suchHinweis.temp and w.suchHinweis.temp[1] == 2, "(b) Hinweis «2 Sensoren passen» fehlt")
-- Temperatur: esc_temp vor temp1
w = lauf({ sensor("Temp1", 0x0400, 0, 1, UNIT_CELSIUS, 20), i0 })
pruef(ist(w, "temp", i0), "esc_temp vor temp1")
-- (c) gleiche AppID auf zwei Physical IDs: der mit Wert, sonst niedrigste Physical ID
local p3, p8 = sensor("VFAS", 0x0210, 0, 3, UNIT_VOLT, nil), sensor("VFAS", 0x0210, 0, 8, UNIT_VOLT, 22.1)
w = lauf({ p3, p8 })
pruef(ist(w, "uGes", p8), "(c) Sensor mit Wert erwartet")
pruef(w.suchHinweis.uGes and w.suchHinweis.uGes[1] == 2, "(c) Hinweis fehlt")
local q3, q8 = sensor("VFAS", 0x0210, 0, 8, UNIT_VOLT, nil), sensor("VFAS", 0x0210, 0, 3, UNIT_VOLT, nil)
w = lauf({ q3, q8 })
pruef(ist(w, "uGes", q8), "(c) ohne Wert: niedrigste Physical ID erwartet")
-- (d) nur Gesamtspannung ohne Zellen: Zellen bleibt leer, Empfängerspannung wird nie Gesamtspannung
local rx = sensor("RxBatt", 0xF104, 0, 0, UNIT_VOLT, 5.1)
w = lauf({ rx, vfas })
pruef(ist(w, "uGes", vfas) and w.cfg.zellen == nil and ist(w, "bec", rx), "(d) VFAS, keine Zellen, RxBatt = BEC")
w = lauf({ rx })
pruef(w.cfg.uGes == nil, "(d) RxBatt darf nie Gesamtspannung werden")
-- (e) Betaflight-«Kraftstoff» 0x0600 in mAh = Verbraucht, in % = Akku %
local kmah, kproz = sensor("Kraftstoff", 0x0600, 0, 1, UNIT_MILLIAMPERE_HOUR, 800), sensor("Kraftstoff", 0x0600, 0, 1, UNIT_PERCENT, 70)
w = lauf({ kmah })
pruef(ist(w, "mah", kmah) and w.cfg.proz == nil, "(e) Kraftstoff mAh = Verbraucht")
w = lauf({ kproz })
pruef(ist(w, "proz", kproz) and w.cfg.mah == nil, "(e) Kraftstoff % = Akku %")
-- (f) leeres Modell
local w0, n0 = lauf({})
pruef(n0 == 0 and next(w0.cfg) == nil, "(f) leeres Modell")
-- (g) 100 Sensoren: läuft durch, nimmt die passenden
local viele = {}
for i = 1, 96 do viele[i] = sensor("DIY " .. i, 0x5100 + i, 0, 10, 0, 1) end
viele[97], viele[98], viele[99], viele[100] = escU, escI, i0, sensor("RSSI", 0xF101, 0, 0, 0, 80)
w = lauf(viele)
pruef(ist(w, "uGes", escU) and ist(w, "strom", escI) and ist(w, "temp", i0) and w.cfg.rssi == viele[100], "(g) 100 Sensoren")
-- von Hand gesetzt bleibt
SENS = { escU, vfas }
local wh = { cfg = { uGes = vfas } }
schritte(wh)
pruef(wh.cfg.uGes == vfas, "von Hand gesetztes Feld überschrieben")
-- Rückfall nur für Sensoren ohne Kennung: DIY-Sensor «Volt» 0x5200 wird Gesamtspannung, wenn sonst keiner da ist
local diy = sensor("Akku Volt", 0x5200, 0, 10, UNIT_VOLT, 12)
w = lauf({ diy, rx })
pruef(ist(w, "uGes", diy), "Rückfall Name für DIY-Sensor")
-- ohne Teilwert (subId = nil), Einheit entscheidet: ESC Spannung/Strom 0x0B50, ESC Drehzahl/mAh 0x0B60
local nu, ni = sensor("ESC Spannung", 0x0B50, nil, 4, UNIT_VOLT, 22), sensor("ESC Strom", 0x0B50, nil, 4, UNIT_AMPERE, 30)
local nr, nm = sensor("ESC Drehzahl", 0x0B60, nil, 4, UNIT_RPM, 9000), sensor("ESC mAh", 0x0B60, nil, 4, UNIT_MILLIAMPERE_HOUR, 500)
w = lauf({ ni, nu, nm, nr })
pruef(ist(w, "uGes", nu) and ist(w, "strom", ni) and ist(w, "rpm", nr) and ist(w, "mah", nm), "ohne Teilwert: Einheit entscheidet")
-- (h) 0.3.1: nach «Alle Sensoren löschen» + «Sensoren suchen» in Ethos: alte Verweise liefern 0. Die Suche bindet
-- jedes Feld an den neuen Sensor (AppID, Teilwert, Physical ID, Name); ohne Gegenstück neu gesucht.
local altU, altI = sensor("ESC Spannung", 0x0B50, 0, 4, UNIT_VOLT, 0), sensor("ESC Strom", 0x0B50, 1, 4, UNIT_AMPERE, 0)
local altT = sensor("ESC Temp", 0x0B70, 0, 9, UNIT_CELSIUS, 0)                     -- lag auf anderer Physical ID
local kanal = sensor("Gas", 0, 0, 0, 0, 0)
kanal.category = function() return 99 end                                           -- keine Telemetrie: bleibt
local neuU, neuI = sensor("ESC Spannung", 0x0B50, 0, 4, UNIT_VOLT, 22), sensor("ESC Strom", 0x0B50, 1, 4, UNIT_AMPERE, 30)
local neuT = sensor("ESC Temp", 0x0B70, 0, 4, UNIT_CELSIUS, 40)
SENS = { neuU, neuI, neuT }
local wr = { cfg = { uGes = altU, strom = altI, temp = altT, vario = kanal } }
local nr2 = schritte(wr)
pruef(wr.cfg.uGes == neuU and wr.cfg.strom == neuI, "(h) Spannung/Strom an die neuen Sensoren gebunden")
pruef(wr.cfg.temp == neuT and nr2 == 1, "(h) Temperatur ohne Gegenstück neu gesucht (1 neu), n = " .. tostring(nr2))
pruef(wr.cfg.vario == kanal, "(h) Quelle ausserhalb der Telemetrie bleibt")
-- gleicher Sensor neu gebunden: Höchstwerte bleiben (w.qAlt folgt dem neuen Objekt); neu gesuchtes Feld: nicht
local wq = { cfg = { uGes = altU, temp = altT }, qAlt = { uGes = altU, temp = altT } }
SENS = { neuU, neuT }
schritte(wq)
pruef(wq.qAlt.uGes == neuU and wq.cfg.uGes == neuU, "(h) Neu-Binden: qAlt folgt, MAX bleibt")
pruef(wq.qAlt.temp == altT and wq.cfg.temp == neuT, "(h) neu gesuchtes Feld: qAlt bleibt alt, MAX beginnt neu")
-- leere Sensorliste: nichts leeren
SENS = {}
local wl = { cfg = { uGes = altU } }
schritte(wl)
pruef(wl.cfg.uGes == altU, "(h) leere Sensorliste darf kein Feld leeren")
-- derselbe Sensor von Hand in zwei Feldern: beide bleiben
SENS = { neuU }
local wd = { cfg = { uGes = neuU, bec = neuU } }
schritte(wd)
pruef(wd.cfg.uGes == neuU and wd.cfg.bec == neuU, "(h) Doppelbelegung von Hand bleibt")
-- (i) 0.10.0 zwei Bänder: RSSI/VFR über band() (0 = 2,4 GHz, sonst zweites Band), RX VFR; ohne band() nach Reihenfolge
local function mitBand(q, b) q.b = b q.band = function(x) return x.b end return q end
local r24, r9 = mitBand(sensor("RSSI 2.4G", 0xF101, 0, 24, UNIT_DB, 70), 0), mitBand(sensor("RSSI 900M", 0xF101, 0, 24, UNIT_DB, 60), 1)
local v24, v9 = mitBand(sensor("VFR 2.4G", 0xF010, 0, 24, UNIT_PERCENT, 99), 0), mitBand(sensor("VFR 900M", 0xF010, 0, 24, UNIT_PERCENT, 95), 1)
local rx = mitBand(sensor("RX VFR", 0xF011, 0, 24, UNIT_PERCENT, 99), 0)
w = lauf({ r9, v9, r24, v24, rx })                    -- zweites Band zuerst in der Liste: band() entscheidet
pruef(ist(w, "rssi", r24) and ist(w, "rssi2", r9) and ist(w, "vfr", v24) and ist(w, "vfr2", v9) and ist(w, "rxvfr", rx),
  "(i) zwei Bänder über band(), unabhängig von der Reihenfolge")
local o24, o9 = sensor("RSSI A", 0xF101, 0, 24, UNIT_DB, 70), sensor("RSSI B", 0xF101, 0, 24, UNIT_DB, 60)
w = lauf({ o24, o9 })
pruef(ist(w, "rssi", o24) and ist(w, "rssi2", o9), "(i) ohne band(): erster RSSI = 2,4 GHz, zweiter = zweites Band")
-- (j) 0.10.0 Zellen 2 über eine andere Physical ID, Empfänger-Akku 2 = 0xF108 Teilwert 1
local z1, z2 = sensor("Cels", 0x0300, 0, 1, UNIT_VOLT, 22), sensor("Cels", 0x0300, 0, 2, UNIT_VOLT, 22)
local rb1, rb2 = sensor("RxBatt 1", 0xF108, 0, 24, UNIT_VOLT, 7.4), sensor("RxBatt 2", 0xF108, 1, 24, UNIT_VOLT, 7.3)
w = lauf({ z2, rb2, z1, rb1 })
pruef(ist(w, "zellen", z1) and ist(w, "zellen2", z2) and ist(w, "bec2", rb2), "(j) Zellen 2 über Physical ID, Empfänger-Akku 2")
w = lauf({ z1 })
pruef(ist(w, "zellen", z1) and w.cfg.zellen2 == nil, "(j) nur ein Zellensensor: Zellen 2 bleibt leer")
print(string.format("Befehle je Aufruf höchstens %d, Aufrufe je Suche höchstens %d", MAXBEF, AUFRUFE))
pruef(MAXBEF < 10000, "zu viele Befehle in einem Aufruf: " .. MAXBEF)
print(fehler == 0 and "ERGEBNIS: kein Fehler" or ("ERGEBNIS: " .. fehler .. " Fehler"))
os.exit(fehler == 0 and 0 or 1)
