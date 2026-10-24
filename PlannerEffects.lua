local ADDON, FGT = ...

-- The goal pages' weather and light for the Gear Planner's racial backdrops (Karl, 2026-10-24):
-- the drifting clouds and dust of Ambience.lua on every race, and on top of them each race's
-- own particles: snow, motes, ash and embers, blown dust. (Lights were tried, sun rays, a sun
-- bloom, torch flames and light shafts, and were far too strong on the dimmed backdrops: Karl,
-- 2026-10-24. The engine can still draw them: a spec may carry `sunrays`, `blooms`, `flames`.)
--
-- Nothing here is new engine. The particles and lights are the goal page's own (the banner's
-- ResetEmbers / StepEmbers and ResetShafts / StepShafts in Core.lua, with their slow, never
-- flashing limits); this file runs a second copy of that object on the backdrop's texture, so
-- everything is placed by where it sits in the artwork (u and v, 0 to 1 from its top left) and
-- follows the picture as it is moved, zoomed or resized. They draw above the scenery and under
-- the planner's edge shading, the light and the character. Settings > Images > Image effects
-- applies: Full plays all of it, Subtle only the clouds, Off none. All of it stops while the
-- planner is hidden.
local pb, B, A = FGT.plannerBackdrop, FGT.goalBanner, FGT.ambience
if not (pb and B) then return end
local host, area, art = pb.frame, pb.area, pb.texture

-- The spec shapes are the banner's own (see the long note above B.shafts in Core.lua).
local function Snow(count, rise, sizeScale, strength, fadeIn)
    return { fall = true, box = { 0.0, 1.0, 0.0, 1.0 }, count = count, blurShare = 0.15, rise = rise or 0.55,
        sizeScale = sizeScale, strength = strength, fadeIn = fadeIn }
end
local function Motes(box, count, scale, strength, fadeIn)
    return { float = true, box = box, count = count, blurShare = 0.12, rise = 0.06, scale = scale, strength = strength,
        fadeIn = fadeIn }
end
local function Sand(box, count, wind)
    return { drift = true, box = box, count = count, blurShare = 0.12, rise = 0.55, wind = wind, strength = 1.4 }
end
local function Embers(box, field, count)
    return { box = box, field = field, count = count, blurShare = 0.22, rise = 0.30 }
end

-- What each race gets. `dust` is the leaf-and-dust layer's strength against the goal page's (the
-- leaves are those layers: stronger where the scene is leafy). Places are in the backdrop
-- (1143 x 1376 px).
local SPECS = {
    -- the snow: many more flakes, smaller, a little slower and fainter than the goal pages', and slow to appear
    Dwarf = { dust = 0.7, embers = Snow(150, 0.42, 0.7, 0.6, 0.3) },
    Gnome = { dust = 0.7, embers = Snow(150, 0.42, 0.7, 0.6, 0.3) },
    NightElf = { dust = 0.9, embers = Motes({ 0.10, 0.95, 0.30, 0.85 }, 26, 1.2, 0.65, 0.75) }, -- fainter, and about 8 s to appear
    Scourge = { dust = 1.8, embers = Motes({ 0.25, 0.90, 0.45, 0.95 }, 14, nil, 0.75) },
    Orc = { dust = 0.7, embers = Embers({ 0.15, 0.95, 0.62, 0.97 }, { 0.10, 1.0, 0.30, 0.97 }, 22) }, -- the embers (the floating ash was taken out)
    Tauren = { dust = 1 }, -- the goal page's own clouds and leaves (the blown dust was taken out)
    Troll = { dust = 0.7 }, -- only the clouds and the blowing leaves (the fast blown dust was taken out)
    Human = { dust = 2.2 }, -- clouds and leaves only, the leaves a little stronger than the others'
}
local STRENGTH = 1 -- the particles' and lights' overall level on the backdrop

-- The second copy of the banner's engine: its own tables, drawing on the planner's backdrop.
-- `flat` keeps the goal page's fade toward the left edge and its faded bottom out of it (the
-- planner shades its own edges); false in `lightMask` leaves the goal page's mask behind.
local E = setmetatable({
    host = host, art = art, uv = { 0, 1, 0, 1 }, flat = true, lightMask = false,
    emberDots = {}, shafts = {}, shaftInfo = {}, lightSpan = {},
    emberLevel = 4, shaftLevel = 3, glowLevel = STRENGTH, sourceAspect = 1143 / 1376, coldStart = 5,
    emberCount = 0, shaftCount = 0,
}, { __index = B })
FGT.PlannerEffects = { engine = E, specs = SPECS }

-- The drifting clouds and dust: above the backdrop (sublevel 0), the clouds under the dust.
local layers = A and A.Build and A.Build(host, area, 2, 1) or {}
local driver = CreateFrame("Frame", nil, host)
local race, running, dirty, clock = nil, false, false, 0

local function Tick(_, dt)
    dt = math.min(dt or 0, 0.05)
    clock = clock + dt
    local w = art:GetWidth() or 0
    if w < 1 then return end
    E.shownArtHeight = art:GetHeight() or 0
    if dirty then
        -- (made once the backdrop has its size: particles are placed in the art's pixels)
        dirty = false
        E:ResetEmbers(); E:ResetShafts()
    end
    E:StepEmbers(dt)
    E:StepShafts(clock)
end

-- Stops stepping. `clear` also takes the particles away (a setting or a race changed them); with
-- the planner merely closed they are kept, and carry on where they were when it opens again.
local function Stop(clear)
    if running then driver:SetScript("OnUpdate", nil); running = false end
    if clear then E:HideEmbers(); E:HideShafts(); dirty = true end
end

local function Refresh()
    local level = FGT.EffectsLevel()
    local visible = area:IsVisible() and true or false
    if A and A.Apply then A.Apply(layers, level, visible, true) end
    local spec = SPECS[race]
    if visible and level == "full" and spec then
        if not running then
            running = true
            driver:SetScript("OnUpdate", Tick)
        end
    else
        Stop(visible)
    end
end

local function SetRace(raceFile)
    if raceFile == race then return end
    race = raceFile
    local spec = SPECS[race]
    E.glowSpec = spec
    if A and A.SetDustStrength then A.SetDustStrength(layers, spec and spec.dust or 1) end
    -- the old race's particles and lights go; the new ones are made at the next step
    E:HideEmbers(); E:HideShafts()
    dirty = true
    Refresh()
end

FGT.PlannerEffects.Refresh, FGT.PlannerEffects.SetRace = Refresh, SetRace
FGT.PlannerEffects.driver, FGT.PlannerEffects.layers, FGT.PlannerEffects.Tick = driver, layers, Tick
area:HookScript("OnShow", Refresh)
area:HookScript("OnHide", Refresh)
SetRace(pb.frame.race)
