-- Aufruf aus dem Repo-Ordner:  /opt/homebrew/opt/lua@5.4/bin/lua test/nil-test.lua src/electric
-- Rückrufe mit w = nil aufrufen: darf keinen Fehler werfen
local reg
system = { registerWidget = function(t) reg = t end }
local m = assert(loadfile(arg[1] .. "/main.lua"))()
m.init()
for _, k in ipairs({ "wakeup", "paint", "event", "configure", "read", "write" }) do
  local ok, e = pcall(reg[k], nil, 1, 2, 3, 4)
  if not ok then print("FEHLER " .. k .. ": " .. tostring(e)) os.exit(1) end
end
print("ERGEBNIS: kein Fehler")
