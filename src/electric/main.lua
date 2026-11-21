-- Electric: Ethos-Widget für Elektroflieger.
-- Diese Datei meldet nur das Widget an. Die Arbeit steckt in kern.lua und wird erst beim ersten Gebrauch geladen.
-- Für ein neues Lua ändern sich hier nur die vier Zeilen NAME, KEY, VERSION und INFO.
local NAME = "Electric"     -- Anzeigename in Ethos und Vorsatz aller Meldungen
local KEY = "elec"          -- Schlüssel des Widgets: a–z/0–9, höchstens 7 Zeichen (Ethos); seit 0.6.0 «elec» (vorher «elektro»)
local VERSION = "0.6.1"    -- die Versionsnummer steht nur hier (x.y.z); das Suite-Paket liest sie von hier
local INFO = "Electric: display for electric planes (full screen or compact with bars) with battery, cells, current, RPM, ESC temperature, throttle, altitude, speed, signal, alarms, announcements, flight list and a settings file from Lua-Studio."   -- ein Satz für die FrSky Suite
-- Speicher (Auftrag 21.11.2026): Den Kern halten nur die Widget-Instanzen fest (w.kern). Hier steht er nur in einer
-- schwachen Tabelle. Verwirft Ethos beim Modellwechsel alle Electric-Instanzen, gibt die Müllabfuhr den ganzen Kern samt
-- Seiten, Studio-Tabellen und Symbolen frei, ohne close-Ereignis. Mehrere Instanzen teilen sich denselben Kern.
local LAGER = setmetatable({}, { __mode = "v" })
local gemeldet = {}

local function kern(w)
  local K = (type(w) == "table" and w.kern) or LAGER.k
  if K == nil then
    local f, e = loadfile("kern.lua")
    if not f then error(e, 0) end
    K = f()
    K.VERSION, K.NAME, K.INFO = VERSION, NAME, INFO
    LAGER.k = K
  end
  if type(w) == "table" and w.kern == nil and w.cfg ~= nil then w.kern = K end
  return K
end

-- Ein Fehler im Skript darf die Funke nicht stören: einmal pro Stelle melden und weiterlaufen.
local function ruf(name, w, ...)
  local ok, a = pcall(function(...) return kern(w)[name](w, ...) end, ...)
  if ok then return a end
  if not gemeldet[name] then
    gemeldet[name] = true
    print(NAME .. ": Fehler in " .. name .. ": " .. tostring(a))
  end
  if type(w) == "table" then w.fehler = name .. ": " .. tostring(a) end
  return nil
end

local function create()
  local ok, w = pcall(function() local K = kern() local n = K.neu() n.kern = K return n end)
  if ok and type(w) == "table" then return w end
  print(NAME .. ": Fehler in create: " .. tostring(w))
  return { fehler = "create: " .. tostring(w) }
end

-- Nach einem Neuladen der Skripte ruft Ethos die Rückrufe kurz mit w = nil auf (gemessen am Sender, 20.11.2026):
-- jeder Rückruf prüft darum zuerst, ob w ein fertiges Widget ist.
local function ok(w) return type(w) == "table" and w.cfg ~= nil end

local function paint(w)
  if type(w) ~= "table" then return end
  if w.cfg then ruf("zeichne", w) end
  if w.fehler then                             -- Fehler klein und sichtbar über dem Bild, unten links
    pcall(function()
      local t = NAME .. ": " .. tostring(w.fehler)
      local _, H = lcd.getWindowSize()
      lcd.font(FONT_S)
      lcd.color(lcd.RGB(0, 0, 0))
      lcd.drawFilledRectangle(0, H - 26, lcd.getTextSize(t) + 16, 26)
      lcd.color(lcd.RGB(239, 68, 68))
      lcd.drawText(8, H - 24, t)
    end)
  end
end

local function init()
  system.registerWidget({
    key = KEY,
    name = NAME,
    create = create,
    wakeup = function(w) if ok(w) then ruf("wecke", w) end end,
    paint = paint,
    event = function(w, kat, wert, x, y) if ok(w) then return ruf("ereignis", w, kat, wert, x, y) end end,
    configure = function(w) if ok(w) then ruf("menue", w) end end,
    read = function(w) if ok(w) then ruf("lies", w) end end,
    write = function(w) if ok(w) then ruf("schreibe", w) end end,
    title = false,
  })
end

return { init = init }
