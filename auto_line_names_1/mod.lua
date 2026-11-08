function data()
  return {
    info = {
      minorVersion = 0,
      severityAdd = "NONE",
      severityRemove = "NONE",
      name = "Auto Line Names",
      description = "Benennt Linien automatisch nach Start/Ziel, Personen/Fracht und Verkehrsmittel (Strasse, Schiene, Wasser, Luft). Einstellungen: res/scripts/linenamer_config.lua",
      authors = { { name = "Patrick", role = "CREATOR" } },
      tags = { "script mod", "misc" },
    },
    -- Spiel-Menue-Optionen; ob TF3 sie ans Game-Script durchreicht, ist ungeprueft.
    -- Die Config-Datei bleibt der verlaessliche Weg.
    params = {
      { key = "ln_scheme", name = "Schema", values = { "Icon", "Kuerzel", "Kuerzel-Strich", "Ausgeschrieben", "Strecke zuerst" }, defaultIndex = 0 },
      { key = "ln_numbering", name = "Liniennummern", values = { "Aus", "An" }, defaultIndex = 0 },
      { key = "ln_colors", name = "Linienfarben", values = { "Aus", "An" }, defaultIndex = 0 },
    },
    runFn = function(settings, modParams)
      local p = {}
      for _, v in pairs(modParams or {}) do
        if type(v) == "table" then for k, x in pairs(v) do p[k] = x end end
      end
      if game and game.config then game.config.linenamer_params = p end -- API: ungeprueft
    end,
  }
end
