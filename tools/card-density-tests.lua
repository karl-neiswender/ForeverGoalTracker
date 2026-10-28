local F, D, U = STUB_NS, ForeverGoalTrackerDB, STUB_NS.RailUI
local saved = { active = D.active, progress = D.progress, selected = D.selected,
    density = F.Setting("cardDensity"), celebrations = F.Setting("celebrations") }
F.SetSetting("celebrations", "off")
local function Track(frame)
    frame.Show = function(self) self.shownForTest = true end
    frame.Hide = function(self) self.shownForTest = false end
    frame.SetShown = function(self, on) self.shownForTest = on and true or false end
    frame.IsShown = function(self) return self.shownForTest == true end
end

-- A goal not started, one partly done, and one with a faction mark.
local started, fresh, factioned = "thunderfury", nil, nil
for _, g in ipairs(F.goals) do
    local row = U.rows[g.id]
    if row and not g.plannerOwner then
        if not factioned and row.factionWatermark then factioned = g.id end
        -- (the test character's level ticks some steps on its own: find one still at zero)
        if not fresh and g.id ~= started and not row.factionWatermark and F.GoalFraction(g) == 0 then fresh = g.id end
    end
end
assert(factioned and fresh, "a card with a faction mark and one not started")
D.active = { [started] = true, [fresh] = true, [factioned] = true }
D.progress = { [started] = { true }, [fresh] = {}, [factioned] = {} }
local rows = { U.rows[started], U.rows[fresh], U.rows[factioned] }
for _, row in ipairs(rows) do
    Track(row.bar); Track(row.notStarted)
    row.SetHeight = function(self, h) self.heightForTest = h end
    if row.factionWatermark then Track(row.factionWatermark) end
end
F.SelectGoal(started)

-- Comfortable (the default): an empty goal shows "Not started", not an empty bar.
F.SetSetting("cardDensity", "comfortable")
F.ApplyCardDensity()
assert(not rows[1].compact and rows[1].heightForTest == F.ROW_H, "comfortable cards keep their height")
assert(rows[1].bar:IsShown() and not rows[1].notStarted:IsShown(), "a started goal shows its bar")
assert(not rows[2].bar:IsShown() and rows[2].notStarted:IsShown(), "a goal not started has no empty bar")
-- The faction mark shows only on the selected or hovered card.
local wm = U.rows[factioned]
assert(not wm.factionWatermark:IsShown(), "no faction mark at rest")
wm:GetScript("OnEnter")(wm)
assert(wm.factionWatermark:IsShown(), "pointing at the card shows its faction mark")
wm:GetScript("OnLeave")(wm)
assert(not wm.factionWatermark:IsShown(), "and it goes again")

-- Compact: shorter rows, the percentage on the label line, no "Not started" line.
F.SetSetting("cardDensity", "compact")
F.ApplyCardDensity()
assert(rows[1].compact and rows[1].heightForTest == F.ROW_H_COMPACT, "compact cards are slim")
assert(rows[1].eyebrow:GetText():find("%d+%%"), "the label line carries the percentage: " .. tostring(rows[1].eyebrow:GetText()))
assert(not rows[2].eyebrow:GetText():find("%%"), "no percentage before a goal is started")
assert(not rows[2].bar:IsShown() and not rows[2].notStarted:IsShown(), "a compact card not started shows no bar line")
assert(rows[1].bar:IsShown(), "a started compact card keeps its thin line")
local light = F.Bars[rows[1].bar]
assert(light and light.height == 4, "the bar's light follows the thin line, so its tip is no taller than it")
assert(F.fontWidgets[rows[1].name].size == 12 and F.fontWidgets[rows[1].eyebrow].size == 8, "compact text is a step smaller")

-- The setting is listed under My Goals list and applies at once.
local found
for _, section in ipairs(F.SETTINGS) do
    for _, r in ipairs(section.rows) do if r.key == "cardDensity" then found = { section.title, r } end end
end
assert(found and found[1] == "My Goals list" and found[2].apply, "Settings: Goal cards under My Goals list")
F.SetSetting("cardDensity", "comfortable") -- (the Settings row saves it, then calls apply)
found[2].apply("comfortable")

assert(light.height == 6 and F.fontWidgets[rows[1].name].size == 13, "comfortable cards get their bar and text sizes back")
F.SetSetting("cardDensity", saved.density)
F.ApplyCardDensity()
D.active, D.progress, D.selected = saved.active, saved.progress, saved.selected
F.SetSetting("celebrations", saved.celebrations)
print("  card density: comfortable (no empty bar, hover faction mark) and compact (slim, percentage, thin line), setting ok")
