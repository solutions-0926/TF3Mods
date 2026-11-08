# FT3Mods

Mods für Transport Fever 3

---

## Auto Line Names (`auto_line_names_1`)

Benennt Linien automatisch: `🚆 Hamburg ⇄ Berlin`, `🚂 Hafen ⇄ Stahlwerk`, `✈ Hamburg ⇄ München` ...
Erkennt Strasse, Schiene, Wasser, Luft sowie Personen oder Fracht. Eigene Namen werden nie ueberschrieben.

**Status:** auf Basis der Transport-Fever-2-API geschrieben, in TF3 ungetestet.

### Installation
1. `auto_line_names_1.zip` entpacken, Ordner `auto_line_names_1` in den `mods`-Ordner von TF3 legen.
2. Mod im Spiel aktivieren.

### Einstellungen
`res/scripts/linenamer_config.lua`: Schema 1-5, Emoji, Sprache de/en, Stadtnamen, Liniennummern, Farben, Dry-Run.

### Probelauf
`dryRun = true` setzen: die Mod schreibt nur ins Log (`stdout.txt`, Zeilen mit `[AutoLineNames]`), was sie umbenennen wuerde.

### Wenn es nicht laeuft
Log-Meldungen mit `[AutoLineNames]` ansehen. Alle API-abhaengigen Stellen sind in
`res/config/game_script/linenamer.lua` mit `-- API:` markiert.

---

## Auto Line Names (`tf3_auto_line_names`)

Benennt Linien automatisch nach Start/Ziel, Personen/Fracht und Strasse/Schiene/Wasser/Luft.

**Status:** ungetestet in TF3: Game-Script-Registrierung ist im TF3-Wiki noch nicht dokumentiert.

### Installation
Ordner `tf3_auto_line_names` in den `mods`-Ordner von TF3 kopieren.

### Einstellungen
In `content/scripts/linenamer_config.lua`.

### Probelauf
`dryRun = true` setzen: die Mod schreibt nur ins Log (`stdout.txt`, Zeilen mit `[AutoLineNames]`), was sie umbenennen wuerde.
