-- Auto Line Names. Auf Basis der TF2-API geschrieben, in TF3 ungetestet.
-- Fragile Stellen sind mit "API:" markiert und per pcall abgesichert.

local cfg = {}
do
  local ok, c = pcall(require, "linenamer_config")
  cfg = ok and type(c) == "table" and c or {}
  local okp, p = pcall(function() return game.config.linenamer_params end) -- API:
  if okp and type(p) == "table" then
    if p.ln_scheme then cfg.scheme = p.ln_scheme + 1 end
    if p.ln_numbering then cfg.numbering = p.ln_numbering == 1 end
    if p.ln_colors then cfg.colors = p.ln_colors == 1 end
  end
end
local function opt(k, d) local v = cfg[k]; if v == nil then return d end; return v end
local SCHEME, EMOJI, LANG = opt("scheme", 1), opt("emoji", true), opt("lang", "de")
local MAXSTOPS, USETOWNS, NUMBERING, COLORS = opt("maxStops", 2), opt("useTowns", false), opt("numbering", false), opt("colors", false)
local DRY, INTERVAL = opt("dryRun", false), opt("interval", 120)

local ICON = {
  road  = { pax = "🚌", cargo = "🚚" }, rail = { pax = "🚆", cargo = "🚂" },
  water = { pax = "⛴", cargo = "🚢" }, air  = { pax = "✈", cargo = "🛩" },
}
local CODE = {
  de = { road = { pax = "BUS", cargo = "LKW" }, rail = { pax = "ZUG", cargo = "GZ" },
         water = { pax = "FÄH", cargo = "SCH" }, air = { pax = "FLG", cargo = "FRA" } },
  en = { road = { pax = "BUS", cargo = "TRK" }, rail = { pax = "TRN", cargo = "FRT" },
         water = { pax = "FRY", cargo = "SHP" }, air = { pax = "AIR", cargo = "CGO" } },
}
local WORD = {
  de = { road = { pax = "Buslinie", cargo = "Lkw-Fracht" }, rail = { pax = "Bahnlinie", cargo = "Güterzug" },
         water = { pax = "Fährlinie", cargo = "Frachtschiff" }, air = { pax = "Flugverbindung", cargo = "Luftfracht" } },
  en = { road = { pax = "Bus line", cargo = "Truck freight" }, rail = { pax = "Rail line", cargo = "Freight train" },
         water = { pax = "Ferry", cargo = "Cargo ship" }, air = { pax = "Flight", cargo = "Air cargo" } },
}
local COLOR = { -- RGB 0..1
  road = { 0.85, 0.65, 0.1 }, rail = { 0.2, 0.45, 0.85 }, water = { 0.1, 0.65, 0.65 }, air = { 0.6, 0.35, 0.8 },
}

local function nameOf(entity)
  local c = api.engine.getComponent(entity, api.type.ComponentType.NAME) -- API:
  return c and c.name or "?"
end

local function townNameFor(stationGroup)
  local ok, res = pcall(function() -- API: Position der Stationsgruppe + naechste Stadt
    local e = game.interface.getEntity(stationGroup)
    local pos = e and e.position
    if not pos then return nil end
    local towns = game.interface.getEntities({ pos = { pos[1], pos[2] }, radius = 5000 }, { type = "TOWN", includeData = true })
    local best, bd
    for _, t in pairs(towns or {}) do
      local tp = t.position
      if tp then
        local d = (tp[1] - pos[1]) ^ 2 + (tp[2] - pos[2]) ^ 2
        if not bd or d < bd then best, bd = t.name, d end
      end
    end
    return best
  end)
  return ok and res or nil
end

local function stopLabel(stationGroup)
  if USETOWNS then local t = townNameFor(stationGroup); if t then return t end end
  return nameOf(stationGroup)
end

local function modeOf(line)
  local E = api.type.enum.TransportMode -- API:
  local tm = line.vehicleInfo.transportModes
  local function has(m) return E[m] ~= nil and tm[E[m] + 1] end
  if has("AIRCRAFT") or has("SMALL_AIRCRAFT") then return "air" end
  if has("SHIP") or has("SMALL_SHIP") then return "water" end
  if has("TRAIN") or has("ELECTRIC_TRAIN") then return "rail" end
  return "road"
end

local function isCargo(stops)
  for _, stop in ipairs(stops) do
    local sg = api.engine.getComponent(stop.stationGroup, api.type.ComponentType.STATION_GROUP) -- API:
    if sg and sg.stations then
      for _, st in pairs(sg.stations) do
        local s = api.engine.getComponent(st, api.type.ComponentType.STATION) -- API:
        if s and s.cargo then return true end
      end
    end
  end
  return false
end

local function build(mode, cargo, names, num)
  local kind = cargo and "cargo" or "pax"
  local a, b, n = names[1], names[#names], #names
  local route = (n <= MAXSTOPS or n == 2) and (a .. " ⇄ " .. b) or (a .. " ⇄ " .. b .. " (+" .. (n - 2) .. ")")
  local code = CODE[LANG][mode][kind]
  local tag = num and (code .. " " .. num) or code
  local scheme = SCHEME
  if scheme == 1 and not EMOJI then scheme = 2 end
  if scheme == 1 then return ICON[mode][kind] .. " " .. (num and (num .. " ") or "") .. route
  elseif scheme == 2 then return tag .. " " .. route
  elseif scheme == 3 then local r = route:gsub(" ⇄ ", "–"); return tag .. " " .. r
  elseif scheme == 4 then return WORD[LANG][mode][kind] .. (num and (" " .. num) or "") .. ": " .. route
  else return route .. " · " .. tag end
end

local managed = {}   -- [lineId] = { name = zuletzt vergebener Name, num = Liniennummer }
local counters = {}  -- [mode] = letzte Nummer
local timer = 0

local function isDefaultName(s) return s == "" or s:match("^%a+ %d+$") ~= nil end

local function process(lineId)
  local line = api.engine.getComponent(lineId, api.type.ComponentType.LINE) -- API:
  if not line or not line.stops or #line.stops < 2 then return end
  local curName = nameOf(lineId)
  local m = managed[lineId]
  if not (m and m.name == curName) and not isDefaultName(curName) then return end -- manuell benannt: nie anfassen
  local mode, cargo = modeOf(line), isCargo(line.stops)
  if not m then
    m = {}
    if NUMBERING then counters[mode] = (counters[mode] or 0) + 1; m.num = counters[mode] end
    managed[lineId] = m
  end
  local names = {}
  for _, stop in ipairs(line.stops) do names[#names + 1] = stopLabel(stop.stationGroup) end
  local new = build(mode, cargo, names, m.num)
  if new == curName then return end
  if DRY then print("[AutoLineNames] DRY-RUN: '" .. curName .. "' -> '" .. new .. "'"); return end
  m.name = new
  api.cmd.sendCommand(api.cmd.make.setName(lineId, new)) -- API:
  if COLORS then
    local c = COLOR[mode]
    pcall(function() -- API: Farbkommando in TF3 unbekannt
      api.cmd.sendCommand(api.cmd.make.setColor(lineId, api.type.Vec3f.new(c[1], c[2], c[3])))
    end)
  end
end

local function run()
  -- API: falls getLines in TF3 fehlt -> api.engine.forEachEntityWithComponent(..., LINE)
  for _, lineId in ipairs(api.engine.system.lineSystem.getLines()) do
    local ok, err = pcall(process, lineId)
    if not ok then print("[AutoLineNames] Fehler bei Linie " .. tostring(lineId) .. ": " .. tostring(err)) end
  end
end

function data()
  return {
    update = function()
      timer = timer + 1
      if timer % INTERVAL == 0 then
        local ok, err = pcall(run)
        if not ok then print("[AutoLineNames] " .. tostring(err)) end
      end
    end,
    save = function() return { managed = managed, counters = counters } end,
    load = function(s) managed = s and s.managed or {}; counters = s and s.counters or {} end,
  }
end
