-- Einstellungen fuer Auto Line Names. Einfach Werte aendern, Spiel neu laden.
return {
  scheme    = 1,      -- 1 Icon | 2 Kuerzel | 3 Kuerzel mit Strich | 4 Ausgeschrieben | 5 Strecke zuerst
  emoji     = true,   -- false: Schema 1 faellt auf Kuerzel (Schema 2) zurueck
  lang      = "de",   -- "de" oder "en"
  maxStops  = 2,      -- ab mehr Halten: "A <-> B (+n)"
  useTowns  = false,  -- true: Name der naechsten Stadt statt Stationsname (experimentell)
  numbering = false,  -- true: fortlaufende Nummer je Verkehrsmittel, z.B. "ZUG 12"
  colors    = false,  -- true: Linienfarbe nach Typ setzen (experimentell)
  dryRun    = false,  -- true: nur ins Log schreiben, nichts umbenennen
  interval  = 120,    -- Pruefung alle n Ticks
}
