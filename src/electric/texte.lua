-- Electric: alle Texte der Anzeige in zwei Sprachen. Jeder Text steht genau einmal hier: { deutsch, englisch }.
-- Der Kern holt sich nur die Texte der gewählten Sprache (1 = Deutsch, 2 = English) und gibt den Rest wieder frei.
-- Texte des Menüs stehen bei den Einstellungen in felder.lua. Meldungen im Protokoll (print) bleiben deutsch.
local TEXT = {
  scharf = { "SCHARF", "ARMED" },
  motorAus = { "MOTOR AUS", "MOTOR OFF" },
  -- Titel der Tachos und Felder (lang, kurz für 480 x 320)
  t1 = { "AKKU", "BATTERY" }, t2 = { "STROM", "CURRENT" }, t3 = { "DREHZAHL", "MOTOR" },
  t4 = { "REGLERTEMP.", "ESC TEMP" }, t5 = { "ZELLE Ø", "CELL Ø" }, t5z = { "ZELLE TIEFST", "CELL LOWEST" },
  t5k = { "ZELLE MIN", "CELL MIN" }, t6 = { "SPANNUNG", "VOLTAGE" }, t7 = { "VERBRAUCHT", "USED" },
  t7k = { "VERBR.", "USED" }, t8 = { "LEISTUNG", "POWER" }, t8k = { "LEIST.", "POWER" }, t9 = { "HÖHE", "ALTITUDE" },
  t10 = { "VARIO", "VARIO" }, t11 = { "SPEED", "SPEED" }, t12 = { "EMPFANG", "SIGNAL" }, t13 = { "BEC", "BEC" },
  t14 = { "FLUGZEIT", "FLIGHT TIME" }, t15 = { "GAS", "THROTTLE" },
  bei = { "bei %s A", "at %s A" }, gasWaehlen = { "Gaskanal wählen", "Select throttle" },
  ampere = { "AMPERE", "AMPS" }, umin = { "U/MIN", "RPM" },
  max = { "MAX", "MAX" }, tief = { "TIEF", "LOW" }, ruhe = { "RUHE", "REST" },
  auf0 = { "AUF 0", "RESET" },
  zellenEinst = { "Zellenzahl einstellen", "Set cell count" },
  zellenKurz = { "Zellenzahl?", "Cell count?" },
  fluege = { "%s Flüge", "%s flights" }, flug1 = { "1 Flug", "1 flight" },
  -- Seite 2
  flug = { "FLUG %s", "FLIGHT %s" }, flugListe = { "FLÜGE", "FLIGHTS" }, fertig = { "%s fertig", "%s done" },
  laeuft = { "läuft", "running" }, pause = { "Pause", "paused" },
  nr = { "Nr", "No" }, dauer = { "Dauer", "Time" }, maxM = { "Max m", "Max m" },
  dFlugdauer = { "Flugdauer", "Duration" }, dVerbrauch = { "Verbrauch", "Used" }, dEnergie = { "Energie", "Energy" },
  dStrom = { "Max. Strom", "Max. current" }, dLeistung = { "Max. Leistung", "Max. power" },
  dTemp = { "Max. Reglertemp.", "Max. ESC temp" }, dZelle = { "Tiefste Zelle", "Lowest cell" },
  dHoehe = { "Max. Höhe", "Max. altitude" }, dSpeed = { "Max. Speed", "Max. speed" },
  dAkku = { "Akku am Ende", "Battery at end" },
  keineFluege = { "Noch keine Flüge", "No flights yet" }, antippen = { "Flug in der Liste antippen", "Tap a flight in the list" },
  zurueck = { "< ZURÜCK", "< BACK" }, flugLoeschen = { "FLUG %s LÖSCHEN", "DELETE FLIGHT %s" },
  flugLoeschen0 = { "FLUG LÖSCHEN", "DELETE FLIGHT" }, listeLoeschen = { "LISTE LÖSCHEN", "CLEAR LIST" },
  -- Hinweise (%s = Anzahl)
  autoSuche = { "%s Sensoren automatisch zugewiesen", "%s sensors assigned automatically" },
  neuSuche = { "%s Sensoren neu zugewiesen", "%s sensors newly assigned" },
  aufNull = { "Verbrauch auf 0 gesetzt", "Used capacity reset" },
  geloescht = { "Flug %s gelöscht", "Flight %s deleted" }, listeWeg = { "Flugliste gelöscht", "Flight list cleared" },
  -- Rückfragen
  qFlug = { "Flug beendet?", "Flight ended?" }, qFlugZ = { "Dieser Flug: %s", "This flight: %s" },
  jaFlug = { "JA, BEENDET", "YES, ENDED" }, neinFlug = { "NEIN, NUR PAUSE", "NO, JUST PAUSE" },
  qAuf0 = { "Kapazität auf 0?", "Reset capacity?" }, qAuf0Z = { "Für einen frisch geladenen Akku.", "For a freshly charged battery." },
  jaAuf0 = { "JA, AUF 0", "YES, RESET" },
  qLoeschen = { "Flug %s löschen?", "Delete flight %s?" }, qLoeschenZ = { "Die Nummern danach rücken nach.", "The following numbers move up." },
  qListe = { "Alle Flüge löschen?", "Delete all flights?" }, qListeZ = { "Der Flugzähler beginnt wieder bei 1.", "The flight counter starts again at 1." },
  jaLoeschen = { "JA, LÖSCHEN", "YES, DELETE" },
  abbrechen = { "ABBRECHEN", "CANCEL" },
  -- Menü (Kopf)
  mSuchen = { "Sensoren suchen (nur leere)", "Find sensors (empty only)" },
  mKnopf = { "Suchen", "Search" },
  mAuf0 = { "Kapazität auf 0", "Reset capacity" }, mAuf0K = { "Auf 0", "Reset" },
  mNr = { "Flug Nr. zum Löschen", "Flight no. to delete" }, mLoeschen = { "Flug löschen", "Delete flight" },
  mLoeschenK = { "Löschen", "Delete" }, mListe = { "Ganze Liste löschen", "Delete whole list" },
  mHerkunft = { "Akku % kommt von", "Battery % from" },
  mZuordnung = { "Zuordnung prüfen", "Check assignment" },
  mPasst = { "%s Sensoren passen, gewählt: %s - bitte prüfen", "%s sensors match, chosen: %s - please check" },
  mKeiner = { "kein Sensor", "no sensor" },
  -- Studio-Datei (Lua-Studio-Format v1)
  studioKaputt = { "Studio-Datei kaputt - Standard", "Studio file broken - default" },
  studioZuNeu = { "Studio-Datei zu neu - Lua aktualisieren", "Studio file too new - update the Lua" },
  studioFehler = { "Studio-Datei: %s Fehler", "Studio file: %s errors" },
  studioLaedt = { "Studio-Datei wird geladen ...", "Loading Studio file ..." },
  sGrundKaputt = { "Studio: Datei fehlerhaft (%s)", "Studio: file broken (%s)" },
  sGrundKeine = { "Studio: keine passende Ansicht", "Studio: no matching view" },
  sGrundFehlt = { "Studio: gewählte Datei fehlt (%s)", "Studio: chosen file missing (%s)" },
  sAngepasst = { "Studio: Ansicht %s angepasst", "Studio: view %s adapted" },
  sWeg = { ", %s Plätze weggelassen", ", %s fields left out" },
  mLayout = { "Studio-Layout", "Studio layout" },
  mLayoutAuto = { "automatisch (Modellname)", "automatic (model name)" },
  funkeVerworfen = { "Änderungen an der Funke verworfen", "Changes on the radio discarded" },
  funkeNicht = { "Änderung nicht gespeichert", "Change not saved" },
  studioZurueck = { "Zurück auf Studio-Stand", "Back to Studio settings" },
  standardZurueck = { "Zurück auf Standard", "Back to defaults" },
  mStudio = { "Studio-Datei", "Studio file" },
  sFehlt = { "keine", "none" }, sGeladen = { "geladen", "loaded" }, sKaputt = { "kaputt", "broken" },
  sZuNeu = { "zu neu", "too new" },
  mStudioK = { "Zurück", "Reset" },
  qStudio = { "Zurück auf Studio-Stand?", "Back to Studio settings?" },
  qStudioZ = { "Deine Änderungen an der Funke werden gelöscht.", "Your changes on the radio are deleted." },
  qStandard = { "Zurück auf Standard?", "Back to defaults?" },
  qStandardZ = { "Einstellungen und Grenzwerte ab Werk; Sensoren und Flüge bleiben.", "Factory settings and limits; sensors and flights stay." },
  jaZurueck = { "JA, ZURÜCK", "YES, RESET" },
  hRegler = { "Regler", "ESC" }, hRuhe = { "gerechnet", "calculated" }, hKeine = { "kein Wert", "no value" },
}

return function(sp)
  local t = {}
  for k, p in pairs(TEXT) do t[k] = p[sp] or p[1] end
  return t
end
