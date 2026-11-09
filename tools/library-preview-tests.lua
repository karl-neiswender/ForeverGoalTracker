-- The Goal Library preview drawer: opens from a card, swaps in place, closes, stays read-only.
local F, D = STUB_NS, ForeverGoalTrackerDB
local P, LF, U = F.LibraryPreview, F.libState, F.MaterialsUI
F.SetSetting("celebrations", "off")
local mainW = 1240
U.main.GetWidth = function() return mainW end
U.list.GetWidth = function() return 270 end
F.libraryPanel.IsShown = function() return true end

local function watch(frame)
    frame.Show = function(self) self.testShown = true end
    frame.Hide = function(self) self.testShown = false end
    frame.SetShown = function(self, on) self.testShown = not not on end
    frame.IsShown = function(self) return self.testShown == true end
end
watch(P.tryBtn); watch(P.sideBtn); watch(P.hintBtn); watch(P.body)

D.active, D.activeParts = {}, {}
D.progress = { annihilator = { [1] = true } }
F.ShowTab("library")
local before = STUB_SERIALIZE(D.progress)

-- first click: opens on that goal, drawing its own steps, name and hint count
local axe, aq20 = F.GoalById("annihilator"), F.GoalById("raid_aq20")
assert(axe and aq20, "the fixture goals exist")
P:CardClick(axe)
assert(P.open and P.seen and P.goal == axe and P.fraction == 1, "a click opens the drawer on that goal")
assert(P:IsSelected(axe), "the clicked card reads as selected")
assert(P.name:GetText() == "Annihilator", "the drawer names the goal")
assert(P.listTitle:GetText() == "Steps", "a step goal lists Steps")
assert(P.listCount:GetText() == "1 / " .. #axe.steps, "done steps are counted from saved progress")
assert(P.mainBtn.text:GetText() == "+ Add to My Goals", "not yet added: the drawer offers to add it")
assert(P.mainBtn.gold, "the add button is the gold one")
assert(not P.sideBtn:IsShown(), "no second button before it is added")
assert(P.hintBtn:IsShown() and P.hintsOpen == false, "hints start folded")

-- another card swaps without closing; hints fold again
P.hintBtn:GetScript("OnClick")()
assert(P.hintsOpen, "hints unfold")
P:CardClick(aq20)
assert(P.open and P.goal == aq20 and not P.hintsOpen, "another card swaps in place, hints folded")
assert(not P:IsSelected(axe) and P:IsSelected(aq20), "the selection moves with it")

-- rows cannot tick anything
for i = 1, #aq20.steps do
    local row = P.rows[i]
    assert(row and row:GetScript("OnClick") == nil, "preview rows have no click action")
end
assert(STUB_SERIALIZE(D.progress) == before, "previewing never changes progress")

-- the same card again closes, leaving the handle so it can come back
P:CardClick(aq20)
assert(not P.open and P.seen and P.fraction == 0 and P.goal == aq20, "the same card closes the drawer")
assert(not P:IsSelected(aq20), "a closed drawer selects nothing")
P.handle:GetScript("OnClick")()
assert(P.open and P.goal == aq20, "the handle reopens the last goal")

-- adding from the drawer matches the card's own button
P.mainBtn:GetScript("OnClick")(P.mainBtn)
assert(D.active.raid_aq20, "the drawer adds the goal")
assert(P.mainBtn.text:GetText() == "Open goal" and not P.mainBtn.gold, "added: the main button opens it")
assert(P.sideBtn:IsShown() and P.sideBtn.text:GetText() == "Remove", "added: a second button removes it")
P.sideBtn:GetScript("OnClick")(P.sideBtn)
assert(not D.active.raid_aq20, "the drawer removes the goal")
assert(P.mainBtn.text:GetText() == "+ Add to My Goals", "removed: it offers to add again")

-- a group adds all; a set offers Try on
for _, g in ipairs(F.goals) do
    if g.group and g.sections and #g.sections > 1 then
        P:CardClick(g)
        assert(P.listTitle:GetText() == "What's included", "a group lists its parts")
        assert(P.mainBtn.text:GetText() == "+ Add all to My Goals", "a group adds all")
        break
    end
end
for _, g in ipairs(F.goals) do
    if F.SetPreviewIds(g) and not g.group then
        P:CardClick(g)
        assert(P.tryBtn:IsShown(), "a set can be tried on from the drawer")
        assert(P.listTitle:GetText() == "Items to collect", "a set lists its items")
        break
    end
end

-- the magnifying glass: on the card, never on its buttons
do
    local card = LF.cards["annihilator"]
    assert(card and card.previewGlyph, "cards carry the preview glyph")
    local shown
    card.previewGlyph.SetShown = function(_, on) shown = on end
    local onCard, onButton = true, false
    card.IsMouseOver = function() return onCard end
    card.btn.IsMouseOver = function() return onButton end
    card.glyphOn = nil
    card:GetScript("OnEnter")(card)
    assert(shown == true, "hovering the card shows the glyph")
    onButton = true
    card:GetScript("OnLeave")(card)
    assert(shown == false, "moving onto the Add button hides it")
    onButton = false
    card:GetScript("OnEnter")(card)
    assert(shown == true, "back on the card it returns")
    onCard = false
    card:GetScript("OnLeave")(card)
    assert(shown == false, "leaving the card hides it")
end

-- a small window lays it over the list; too small and it stays shut
mainW = 700
P:Place()
assert(P.overlay and P.canOpen, "a small window opens over the list")
mainW = 330
P:Place()
assert(not P.canOpen and not P.open, "too small: the drawer shuts")
mainW = 1240
P:Place()
assert(P.canOpen and not P.overlay, "room again: it sits beside the list")
