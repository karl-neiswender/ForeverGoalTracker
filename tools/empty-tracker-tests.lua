local F, D, E = STUB_NS, ForeverGoalTrackerDB, STUB_NS.emptyUI
local saved = { active = D.active, parts = D.activeParts, selected = D.selected,
    progress = D.progress, celebrations = F.Setting("celebrations") }

-- The banner is cropped from its right edge and never wider than 62% of the panel.
local hero = E.hero
local function texture()
    return {
        ClearAllPoints = function() end,
        SetPoint = function() end,
        SetSize = function(self, w, h) self.w, self.h = w, h end,
        SetHeight = function(self, h) self.h = h end,
        SetTexCoord = function(self, ...) self.uv = {...} end,
    }
end
local oldArt, oldShade, oldTop, oldW, oldH = hero.art, hero.shade, hero.top, hero.GetWidth, hero.GetHeight
hero.art, hero.shade, hero.top = texture(), texture(), texture()
local oldPath, oldAspect = E.artPath, E.artAspect
E.artPath = "allclasses_test"
for _, case in ipairs({ { 900, 700, 4/3 }, { 400, 700, 4/3 }, { 1400, 500, 1 } }) do
    local w, h, aspect = case[1], case[2], case[3]
    E.artAspect = aspect
    hero.GetWidth, hero.GetHeight = function() return w end, function() return h end
    hero:Fit()
    assert(hero.art.h == h, "banner fills the panel's height")
    assert(hero.art.w <= math.floor(w * 0.62) and hero.art.w <= math.floor(h * aspect), "banner width capped")
    assert(hero.art.uv[2] == 1 and hero.art.uv[1] >= 0, "cropped from the right edge")
end
hero.art, hero.shade, hero.top, hero.GetWidth, hero.GetHeight = oldArt, oldShade, oldTop, oldW, oldH
E.artPath, E.artAspect = oldPath, oldAspect

-- Use the actual show/hide routines. Observe their private empty-note
-- frame as well, because the generic stub does not retain visibility.
local note
for i = 1, 20 do
    local name, value = debug.getupvalue(F.HideEmptyTracker, i)
    if name == "emptyNote" then note = value; break end
end
assert(note)
local watched = { note, E.hero, E.column, E.add, E.ghost }
local methods = {}
for _, frame in ipairs(watched) do
    methods[frame] = { Show = frame.Show, Hide = frame.Hide, IsShown = frame.IsShown, IsVisible = frame.IsVisible }
    frame.Show = function(self) self.visible = true end
    frame.Hide = function(self) self.visible = false end
    frame.IsShown = function(self) return self.visible == true end
    frame.IsVisible = frame.IsShown
end
local savedHad = D.hadGoals
D.active, D.activeParts, D.progress, D.hadGoals = {}, {}, {}, nil
F.SetSetting("celebrations", "off")
F.ShowEmptyTracker()
assert(E.hero.visible and E.column.visible, "the banner hero shows on the empty goal page")
assert(E.add.visible and E.ghost.visible, "the + card and its faint card show in the list")
assert(E.title:GetText():find("first goal", 1, true) and E.help.text:GetText() == "Help me get started",
    "a player who never picked a goal is invited to start")
assert(E.add.name:GetText() == "Choose your first goal", "the + card invites a first pick, without a count")
D.active.thunderfury = true
F.SelectGoal("thunderfury")
assert(not E.hero.visible and not E.column.visible and not E.add.visible and not E.ghost.visible,
    "adding a goal hides the empty state")
assert(D.hadGoals, "having a goal is remembered")
D.active = {}
F.ShowEmptyTracker()
assert(E.hero.visible and E.add.visible, "removing the last goal brings it back")
assert(E.title:GetText():find("list is clear", 1, true) and E.help.text:GetText() == "Find my next goal"
    and E.cleared and E.add.name:GetText() == "Choose your next goal", "a cleared list says so and offers the next goal")

-- The + card and its faint card follow Settings > Goal cards.
local density = F.Setting("cardDensity")
F.SetSetting("cardDensity", "compact"); F.ApplyCardDensity()
assert(F.fontWidgets[E.add.name].size == 12 and F.fontWidgets[E.add.eyebrow].size == 8, "compact: the + card is a compact card")
F.SetSetting("cardDensity", "comfortable"); F.ApplyCardDensity()
assert(F.fontWidgets[E.add.name].size == 13, "comfortable: a comfortable card")
F.SetSetting("cardDensity", density); F.ApplyCardDensity()

-- The + card opens the Goal Library; the text link opens the Gear Planner;
-- the button opens the suggestions (skipping tracked goals once cleared).
local oldShowTab, opened = F.ShowTab, nil
F.ShowTab = function(tab) opened = tab end
E.add:GetScript("OnClick")(E.add)
assert(opened == "library", "+ card opens the Goal Library")
E.gear:GetScript("OnClick")(E.gear)
assert(opened == "gear", "the text link opens the Gear Planner")
F.ShowTab = oldShowTab
local oldOpen, args = F.OpenWelcome, nil
F.OpenWelcome = function(...) args = { ... } end
E.help:GetScript("OnClick")(E.help)
assert(args and args[1] == nil and args[2] == true, "a cleared list opens Find my next goal")
E.cleared = false
E.help:GetScript("OnClick")(E.help)
assert(args[1] == 2, "a first visit opens the suggestions")
F.OpenWelcome = oldOpen
D.hadGoals = savedHad

-- The entrance settles every part at full strength (the faint card at its own).
local W, oldTween = F.welcome, F.welcome.Tween
local alphas = {}
for _, frame in ipairs({ E.column, E.add, E.ghost }) do
    methods[frame].SetAlpha = frame.SetAlpha
    frame.SetAlpha = function(self, value) alphas[self] = value end
end
local oldArtAlpha, artP = E.SetArtAlpha, nil
E.SetArtAlpha = function(p) artP = p end
W.Tween = function(_, _, update, finish)
    update(0.5)
    if finish then finish() else update(1) end
end
F.AnimateEmpty()
assert(alphas[E.column] == 1 and alphas[E.add] == 1 and alphas[E.ghost] == E.GHOST_ALPHA, "fade settles the column and cards")
assert(artP == 1, "banner fades in fully")
W.Tween, E.SetArtAlpha = oldTween, oldArtAlpha
for frame, old in pairs(methods) do
    frame.Show, frame.Hide, frame.IsShown, frame.IsVisible = old.Show, old.Hide, old.IsShown, old.IsVisible
    if old.SetAlpha then frame.SetAlpha = old.SetAlpha end
end
D.active, D.activeParts, D.selected, D.progress = saved.active, saved.parts, saved.selected, saved.progress
F.SetSetting("celebrations", saved.celebrations)
print("  banner crop/bounds, first-visit and cleared copy, + card, Gear Planner link and settled fades ok")
