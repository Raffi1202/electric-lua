-- Electric: Einstellungen im Ethos-Menü (Modell › Bildschirme › Widget antippen, oder Widget lange drücken ›
-- Widget konfigurieren). Baut sich aus felder.lua: Gruppen als aufklappbare Felder, oben die Knöpfe für alles,
-- was sonst nur per Berührung geht (X14, X10 und X12 haben keine Berührung). Jede Löschung fragt nach.
return function(w, F, fertig, suche, aktion)
  local c = w.cfg
  local name = tostring(w.name)
  local sp, T = w.sp or 1, w.T or {}       -- Sprache beim Öffnen; ein Wechsel gilt im Menü ab dem nächsten Öffnen
  local function tx(t) return F.text(t, sp) end

  local function frage(titel, zeile, ja, id, arg)
    if not form.openDialog then return end
    pcall(form.openDialog, {
      title = titel, message = zeile,
      buttons = {     -- Ethos zeigt den letzten Knopf links und wählt ihn vor (gemessen 26.1.2): ABBRECHEN zuletzt
        { label = ja, action = function() pcall(aktion, id, arg) return true end },
        { label = T.abbrechen, action = function() return true end },
      },
    })
  end

  local kopf = form.addLine(T.mSuchen or "Sensoren suchen")
  if form.addButton then
    form.addButton(kopf, nil, { text = T.mKnopf or "Suchen", press = function()
      local ok, n = pcall(suche)
      if ok then
        print(name .. ": Suche " .. tostring(n))
      else
        print(name .. ": Fehler bei der Suche: " .. tostring(n))
        w.fehler = "Suche: " .. tostring(n)
      end
    end })
  end
  form.addStaticText(form.addLine(name), nil, "Version " .. tostring(w.version or ""))
  -- Studio-Datei: Zustand und «Zurück auf Studio-Stand» (mit Datei) bzw. «Zurück auf Standard» (ohne)
  local zs = w.studioZustand
  local zt = (zs == "geladen" and T.sGeladen) or (zs == "kaputt" and T.sKaputt) or (zs == "zuNeu" and T.sZuNeu) or T.sFehlt
  if zs == "geladen" and (w.studioFehler or 0) > 0 then zt = zt .. ", " .. string.format(T.studioFehler, tostring(w.studioFehler)) end
  local ls = form.addLine((T.mStudio or "Studio") .. ": " .. tostring(zt))
  if form.addButton then
    form.addButton(ls, nil, { text = T.mStudioK, press = function()
      if w.studio then frage(T.qStudio, T.qStudioZ, T.jaZurueck, "ja_studio")
      else frage(T.qStandard, T.qStandardZ, T.jaZurueck, "ja_standard") end
    end })
  end
  -- 0.7.0: Studio-Layout wählen (R2). Die Liste entsteht nur hier, beim Öffnen des Menüs.
  if form.addChoiceField and w.studioListe then
    local okL, l = pcall(w.studioListe)
    l = okL and l or {}
    local werte, pfade = { { T.mLayoutAuto or "automatisch", 1 } }, { "" }
    local akt = 1
    for i, e in ipairs(l) do
      werte[#werte + 1] = { e[2] .. " (" .. e[3] .. ")", i + 1 }
      pfade[i + 1] = e[1]
      if e[1] == w.lay then akt = i + 1 end
    end
    if akt == 1 and w.lay and w.lay ~= "" then           -- gewählte Datei nicht mehr da: trotzdem anzeigen
      werte[#werte + 1] = { (w.lay:match("[^/]+$") or w.lay) .. " (?)", #werte + 1 }
      pfade[#werte] = w.lay
      akt = #werte
    end
    form.addChoiceField(form.addLine(T.mLayout or "Studio layout"), nil, werte, function() return akt end, function(v)
      akt = v
      pcall(aktion, "lay", pfade[v] or "")
    end)
  end
  local zh = form.addLine(T.mHerkunft)
  w.fHerkunft = form.addStaticText(zh, nil, w.herkunft or "")

  if form.addButton then
    form.addButton(form.addLine(T.mAuf0), nil, { text = T.mAuf0K, press = function()
      frage(T.qAuf0, T.qAuf0Z, T.jaAuf0, "ja_auf0")
    end })
    -- gewählte Nummer bleibt gespeichert (Datei), damit sie nach dem Neustart gleich ist
    local function nr() local x = w.dauer.mnr return (type(x) == "number" and x >= 1 and x <= 99999) and math.floor(x) or 1 end
    form.addNumberField(form.addLine(T.mNr), nil, 1, 99999, nr, function(v)
      w.dauer.mnr = v
      fertig()
    end)
    form.addButton(form.addLine(T.mLoeschen), nil, { text = T.mLoeschenK, press = function()
      local nr = nr()
      frage(string.format(T.qLoeschen, tostring(nr)), T.qLoeschenZ, T.jaLoeschen, "ja_loeschen", nr)
    end })
    form.addButton(form.addLine(T.mListe), nil, { text = T.mLoeschenK, press = function()
      frage(T.qListe, T.qListeZ, T.jaLoeschen, "ja_liste")
    end })
  end

  -- Zuordnung prüfen: je Sensorfeld Name, Physical ID und AppID, damit gleichnamige Sensoren unterscheidbar sind;
  -- nach einer Suche mit mehreren passenden Sensoren der Hinweis «n Sensoren passen».
  local pz = form.addExpansionPanel(T.mZuordnung or "Zuordnung")
  pcall(pz.open, pz, false)
  -- Zahl als Hex-Text, nur wenn sie eine glaubhafte ganze Zahl ist (sonst «?»)
  local function hx(x, stellen)
    if type(x) ~= "number" or x ~= x or x < 0 or x > 65535 then return "?" end
    return string.format("%0" .. stellen .. "X", math.floor(x))
  end
  local function info(q)
    if not F.istQuelle(q) then return T.mKeiner or "-" end
    local function r(f) local okf, v = pcall(q[f], q) if okf then return v end return nil end
    local nm, ph, id = r("name"), r("physId"), r("appId")
    local t = tostring(nm or "?")
    if type(id) == "number" then
      t = t .. "  P" .. hx(ph, 2) .. " / " .. hx(id, 4)
    end
    return t
  end
  for _, f in ipairs(F.gruppen[1][2]) do
    form.addStaticText(form.addLine(tx(f[3]), pz), nil, info(c[f[1]]))
    local h = w.suchHinweis and w.suchHinweis[f[1]]
    if h and T.mPasst then
      local gew = tostring(h[2]) .. " P" .. hx(h[3], 2) .. "/" .. tostring(h[4])
      form.addStaticText(form.addLine("", pz), nil, string.format(T.mPasst, tostring(h[1]), gew))
    end
  end

  for _, g in ipairs(F.gruppen) do
    local panel = form.addExpansionPanel(tx(g[1]))
    pcall(panel.open, panel, false)
    for _, f in ipairs(g[2]) do
      local feld, art = f[1], f[2]
      local line = form.addLine(tx(f[3]), panel)
      local function get() return c[feld] end
      local function set(v)
        if art == "q" and not F.istQuelle(v) then v = nil end
        if art == "t" then v = F.eigen(v) or f[4] end
        if feld == "akkuart" then                -- Zellen-Schwellen auf dem Werkwert folgen der Akkuart
          local alt, neu = F.ZELLE_WERK[c.akkuart] or F.ZELLE_WERK[1], F.ZELLE_WERK[v] or F.ZELLE_WERK[1]
          if c.zelleW == alt[1] and c.zelleA == alt[2] then c.zelleW, c.zelleA = neu[1], neu[2] end
        end
        c[feld] = v
        fertig()
      end
      if art == "q" then
        form.addSourceField(line, nil, get, set)
      elseif art == "b" then
        form.addBooleanField(line, nil, get, set)
      elseif art == "t" then
        if form.addTextField then form.addTextField(line, nil, get, set) end
      elseif art == "w" then
        local wahl = {}
        for i, a in ipairs(f[5]) do wahl[i] = { tx(a[1]), a[2] } end
        form.addChoiceField(line, nil, wahl, get, set)
      elseif art == "z" then
        local fe = form.addNumberField(line, nil, f[5], f[6], get, set)
        if fe then
          if f[7] and f[7] > 0 then pcall(fe.decimals, fe, f[7]) end
          if f[8] then pcall(fe.suffix, fe, f[8]) end
          if f[9] then pcall(fe.step, fe, f[9]) end
          pcall(fe.default, fe, f[4])
        end
      end
    end
  end
end
