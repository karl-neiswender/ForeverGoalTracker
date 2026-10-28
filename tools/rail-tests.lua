local F, D = STUB_NS, ForeverGoalTrackerDB
local R, U, S = F.Rail, F.RailUI, F.MaterialsUI
local list = U.list
local function Track(frame, shown)
    frame.shownForTest = shown or false
    frame.Show = function(self) self.shownForTest = true end
    frame.Hide = function(self) self.shownForTest = false end
    frame.SetShown = function(self, on) self.shownForTest = on and true or false end
    frame.IsShown = function(self) return self.shownForTest end
    frame.SetAlpha = function(self, a) self.alphaForTest = a end
    frame.GetAlpha = function(self) return self.alphaForTest or 1 end
end
list.SetWidth = function(self, w) self.widthForTest = w end
list.GetWidth = function(self) return self.widthForTest or 258 end
Track(list, true); Track(R.head); Track(R.filter); Track(R.card); Track(R.handle, true)
for _, d in ipairs(R.divider) do Track(d.tex) end
-- (the stub doesn't remember SetParent: track where the controls are)
R.inner.parentForTest = R.head
R.inner.SetParent = function(self, p) self.parentForTest = p end
R.inner.GetParent = function(self) return self.parentForTest end
D.active = { thunderfury = true, sulfuras = true, gold_5k = true }
D.progress = { thunderfury = {}, sulfuras = {}, gold_5k = {} }
D.favorites = { sulfuras = true }
F.SelectGoal("thunderfury")
-- Rail marks are made the first time a card folds: track them as they appear.
local makeMarks = F.RailMarks
F.RailMarks = function(row)
    local made = makeMarks(row)
    if made then Track(row.rail) end
    return made
end
local rows = {}
for _, id in ipairs({ "thunderfury", "sulfuras", "gold_5k" }) do
    local row = U.rows[id]
    assert(not row.rail, "no rail marks until a card folds")
    Track(row, true); Track(row.body, true)
    row.body.SetSize = function(self, w, h) self.sizeForTest = w end
    row.body.SetPoint = function(self, point, rel, relPoint) self.pointsForTest = (self.pointsForTest or 0) + 1 end
    row.body.ClearAllPoints = function(self) self.pointsForTest = 0; self.sizeForTest = nil end
    rows[#rows + 1] = row
end
local placed = 0
local oldPlace = F.materialsPanel.Place
F.materialsPanel.Place = function(self, ...) placed = placed + 1; return oldPlace(self, ...) end

-- The Filters bar folds the view, sort, search and completed controls away (folded by default).
F.SetSetting("celebrations", "off")
local controls = { F.myGoalsView, U.sortBar, F.listSearch }
for _, c in ipairs(controls) do Track(c, true) end
R.head.SetHeight = function(self, h) self.heightForTest = h end
local function Shown() for _, c in ipairs(controls) do if not c:IsShown() then return false end end; return true end
local function Hidden() for _, c in ipairs(controls) do if c:IsShown() then return false end end; return true end
R:SetFilters(false, true)
assert(not R.filtersOpen and Hidden() and R.head.heightForTest == 28, "folded: only the Filters bar: " .. tostring(R.head.heightForTest))
assert(R.bar.count:GetText():find("^%d+ goals$"), "the bar counts the goals: " .. tostring(R.bar.count:GetText()))
R.bar:GetScript("OnClick")(R.bar)
assert(R.filtersOpen and D.listFiltersOpen and Shown() and R.head.heightForTest == 126, "the bar opens the filters and remembers it")
R.bar:GetScript("OnClick")(R.bar)
assert(not R.filtersOpen and D.listFiltersOpen == nil and Hidden(), "and folds them again")
F.listQuery = "thunder"; F.LayoutGoalList()
assert(R.bar.count:GetText():find("^%d+ of %d+$"),"a filter left on while folded still shows: " .. tostring(R.bar.count:GetText()))
F.listQuery = ""; F.LayoutGoalList()
F.SetSetting("celebrations", "full")
local oldVisible = list.IsVisible
list.IsVisible = function() return true end
R.bar:GetScript("OnClick")(R.bar)
local ease = R.fdriver:GetScript("OnUpdate")
assert(ease and Shown(), "Full motion eases the filters open")
ease(R.fdriver, 0.05)
assert(R.p > 0 and R.p < 1 and R.head.heightForTest > 28 and R.head.heightForTest < 126, "mid-ease height")
ease(R.fdriver, 1)
assert(R.p == 1 and not R.fdriver:GetScript("OnUpdate") and R.head.heightForTest == 126, "settles open")
R:SetFilters(false, true)
list.IsVisible = oldVisible
F.SetSetting("celebrations", "off")

-- Folding at once (motion off): the rail, saved.
F.SetSetting("celebrations", "off")
R:Toggle()
assert(R.f == 1 and F.ListIsRail() and D.listRail == true, "the handle folds the list and remembers it")
assert(list.widthForTest == 98, "the rail is the icons' width: " .. tostring(list.widthForTest))
for _, d in ipairs(R.divider) do assert(d.tex:IsShown(), "the folded header has its bronze divider") end
for _, row in ipairs(rows) do
    assert(row.rail and row.railBar and row.railStar, "folding makes the card's rail marks")
    assert(not row.body:IsShown() and row.rail:IsShown(), "cards show their icon marks, not their text")
    assert(row.body.sizeForTest == 230, "each card's text layer keeps the open width (trimmed by its clip)")
end
assert(not R.head:IsShown() and R.filter:IsShown(), "the header's controls give way to the filter button")
assert(placed > 0, "the Materials drawer follows the list's new edge")

-- The rail's card tooltip is the open list's full tooltip (name, category, difficulty...).
local lines = {}
-- (the stub hands out a new GameTooltip on every lookup: install a real one for the test)
GameTooltip = setmetatable({
    SetOwner = function() lines = {} end,
    AddLine = function(_, text) lines[#lines + 1] = text end,
}, { __index = function() return function() end end })
rows[1]:GetScript("OnEnter")(rows[1])
assert(#lines > 1 and lines[1] == rows[1].goal.name and lines[2] == rows[1].goal.category, "rail tooltip: the same full tooltip as the open list")

-- The filter card holds the list's own controls; the count shows while filtering.
R:OpenCard()
assert(R.card:IsShown() and R.inner:GetParent() == R.card, "the filter card carries the real search, sort and view")
assert(not R.filtersOpen and Shown(), "the card shows every control, even with the list's filters folded")
R.bar:GetScript("OnClick")(R.bar)
assert(not R.filtersOpen, "the bar does nothing inside the card")
F.listSearch:SetText("thunder")
F.listQuery = "thunder"; F.LayoutGoalList(); R:UpdateFilter()
-- (the stub's cards don't track visibility, so only the count's form is checked)
assert(R.filter.lit and R.filter.count:GetText() and R.filter.count:GetText():find("^%d+ of %d+$"), "a filter lights the button with a count: " .. tostring(R.filter.count:GetText()))
F.listQuery = ""; F.listSearch:SetText(""); F.LayoutGoalList(); R:UpdateFilter()
assert(R.filter.count:GetText():find("^%d+ of %d+$"), "the count stays without a filter (grey): " .. tostring(R.filter.count:GetText()))
R.CloseCard()
assert(not R.card:IsShown(), "the card closes")

-- The empty tracker always shows the full list, and the rail comes back after.
local wasActive = D.active
D.active = {}
F.ShowEmptyTracker()
assert(R.f == 0 and not R.handle:IsShown() and D.listRail == true, "an empty tracker opens the list without forgetting the choice")
D.active = wasActive
F.SelectGoal("thunderfury")
-- (Core's HideEmptyTracker calls this; the stub's empty note never reports shown, so it returns first)
F.RailEmpty(false)
assert(R.f == 1 and R.handle:IsShown(), "goals back: the rail again")

-- Opening again (motion off).
R:Toggle()
assert(R.f == 0 and not F.ListIsRail() and D.listRail == nil and list.widthForTest == 258, "the handle opens the list")
for _, d in ipairs(R.divider) do assert(not d.tex:IsShown(), "the open list has no rail divider") end
for _, row in ipairs(rows) do
    assert(row.body:IsShown() and not row.rail:IsShown() and row.body.sizeForTest == nil, "text back, filling the card again")
end
assert(R.head:IsShown() and R.inner:GetParent() == R.head, "the controls are back in the list")
assert(Hidden() and R.head.heightForTest == 28, "and the folded filters fold again")

-- Full motion: one finite slide that can reverse.
F.SetSetting("celebrations", "full")
list.IsVisible = function() return true end
R:Toggle()
local step = R.driver:GetScript("OnUpdate")
assert(step and R.target == 1, "folding starts a slide")
step(R.driver, 0.1)
assert(R.f > 0 and R.f < 1 and list.widthForTest < 258 and list.widthForTest > 98, "mid-slide width")
R:Toggle()
local back = R.f
R.driver:GetScript("OnUpdate")(R.driver, 0.05)
assert(R.f < back, "a fold reverses from where it is")
R.driver:GetScript("OnUpdate")(R.driver, 1)
assert(R.f == 0 and not R.driver:GetScript("OnUpdate"), "settles and stops")

-- Subtle: the list fades out, changes and fades back in.
F.SetSetting("celebrations", "subtle")
R:Toggle()
R.driver:GetScript("OnUpdate")(R.driver, 0.1)
assert(R.f == 0 and list.alphaForTest < 1, "subtle: fading before the change")
R.driver:GetScript("OnUpdate")(R.driver, 0.1)
assert(R.f == 1, "subtle: changed at the midpoint")
R.driver:GetScript("OnUpdate")(R.driver, 1)
assert(not R.driver:GetScript("OnUpdate") and list.alphaForTest == 1, "subtle: back to full strength")

-- Reload restores the rail; demo scenes always show the full list.
F.SetSetting("celebrations", "off")
R.f, R.target = 0, 0
R.events:GetScript("OnEvent")(R.events, "PLAYER_LOGIN")
assert(R.f == 1, "login restores the rail")
D.demoBackup = {}
R:Sync(true)
assert(R.f == 0, "demo scenes show the full list")
D.demoBackup = nil
R:Sync(true)
assert(R.f == 1, "and the rail returns after")
-- The Library's filters share the list's frame: full width there, rail back on My Goals.
F.ShowTab("library")
assert(list.widthForTest == 258, "the Library's filters get the full width: " .. tostring(list.widthForTest))
F.ShowTab("tracker")
assert(list.widthForTest == 98 and R.f == 1, "back on My Goals the list is folded again: " .. tostring(list.widthForTest))
R:Toggle()
GameTooltip = nil
F.materialsPanel.Place = oldPlace
F.RailMarks = makeMarks
print("  rail: Filters bar (fold, open, saved, count, ease, card), fold and open (Off, Full with reversal, Subtle), clipped card text, rail marks, full tooltip, filter card and count, empty tracker, saved choice, demo, Library width, divider ok")
