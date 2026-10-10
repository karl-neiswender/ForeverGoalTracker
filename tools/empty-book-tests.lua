local F, D, E = STUB_NS, ForeverGoalTrackerDB, STUB_NS.emptyUI
local saved = { active = D.active, parts = D.activeParts, selected = D.selected,
    progress = D.progress, celebrations = F.Setting("celebrations") }
assert(#E.detailArt.corners == 4 and #E.art.corners == 0, "four fittings on the goal page only")
assert(E.detailArt.clasp and not E.art.clasp, "one clasp on the goal page only")
local sizes = { {320, 200}, {650, 680}, {1100, 850}, {100, 90}, {320, 200} }
local function texture()
    return {
        SetTexture = function(self, path) self.path = path end,
        SetDesaturated = function() end,
        ClearAllPoints = function() end,
        SetPoint = function(self, point, parent, relative, x, y) self.x, self.y = x, y end,
        SetSize = function(self, w, h) self.w, self.h = w, h end,
        SetTexCoord = function(self, ...) self.uv = {...} end,
        Show = function(self) self.visible = true end,
        Hide = function(self) self.visible = false end,
        SetShown = function(self, value) self.visible = value end,
    }
end
for _, art in ipairs({ E.art, E.detailArt }) do
    local oldTiles, oldCorners = art.tiles, art.corners
    local oldClasp = art.clasp
    local oldCreate, oldW, oldH = art.CreateTexture, art.GetWidth, art.GetHeight
    art.tiles, art.corners = {}, {}
    for i in ipairs(oldCorners) do art.corners[i] = { metal = texture(), shadow = texture() } end
    if oldClasp then art.clasp = { metal = texture(), shadow = texture() } end
    art.CreateTexture = function() return texture() end
    local w, h
    art.GetWidth, art.GetHeight = function() return w end, function() return h end
    for _, size in ipairs(sizes) do
        w, h = unpack(size)
        art:Fit()
        local shown = 0
        for _, tile in ipairs(art.tiles) do
            if tile.visible then
                shown = shown + 1
                assert(tile.x >= 0 and tile.x + tile.w <= w and -tile.y + tile.h <= h, "tiles stay inside the panel")
                assert(math.abs(tile.uv[2] - tile.uv[1]) == tile.w / 512, "horizontal grain never stretches")
                assert(math.abs(tile.uv[4] - tile.uv[3]) == tile.h / 512, "vertical grain never stretches")
                assert(tile.path:find("empty-book-leather", 1, true))
                local col = math.floor(tile.x / 512)
                assert(tile.uv[1] == col % 2, "alternate columns mirror at their shared edge")
            end
        end
        assert(shown == math.ceil(w / 512) * math.ceil(h / 512), "cover completely filled; excess pooled tiles hidden")
        for _, corner in ipairs(art.corners) do
            local expected = math.min(88, (w - 16) / 2, (h - 16) / 2)
            assert(corner.metal.w == expected and corner.metal.h == expected, "fixed fitting size with tiny-panel safety")
            assert(corner.shadow.w == expected, "contact shadow follows fitting size")
        end
        if art.clasp then
            local cornerSize = math.min(88, (w - 16) / 2, (h - 16) / 2)
            local available = h - 2 * cornerSize - 12
            assert(art.clasp.metal.visible == (available > 0), "clasp never overlaps corner fittings")
            if art.clasp.metal.visible then
                assert(art.clasp.metal.w / art.clasp.metal.h == 1.5, "clasp keeps its original proportions")
                assert(art.clasp.metal.h <= available, "clasp fits the available center edge")
                assert(art.clasp.metal.w <= 96, "clasp never stretches on larger windows")
            end
        end
    end
    art.tiles, art.corners = oldTiles, oldCorners
    art.clasp = oldClasp
    art.CreateTexture, art.GetWidth, art.GetHeight = oldCreate, oldW, oldH
end

-- Use the actual show/hide routines. Observe their private empty-note
-- frame as well, because the generic stub does not retain visibility.
local note
for i = 1, 20 do
    local name, value = debug.getupvalue(F.HideEmptyTracker, i)
    if name == "emptyNote" then note = value; break end
end
assert(note)
local watched = { note, E.art, E.detailArt, E.label, E.help, E.button }
local methods = {}
for _, frame in ipairs(watched) do
    methods[frame] = { Show = frame.Show, Hide = frame.Hide, IsShown = frame.IsShown, IsVisible = frame.IsVisible }
    frame.Show = function(self) self.visible = true end
    frame.Hide = function(self) self.visible = false end
    frame.IsShown = function(self) return self.visible == true end
    frame.IsVisible = frame.IsShown
end
D.active, D.activeParts, D.progress = {}, {}, {}
F.SetSetting("celebrations", "off")
F.ShowEmptyTracker()
assert(E.art.visible and E.detailArt.visible, "both empty panels show the book")
assert(E.help.visible and E.button.visible, "existing calls to action remain available")
D.active.thunderfury = true
F.SelectGoal("thunderfury")
assert(not E.art.visible and not E.detailArt.visible, "adding a goal hides all book artwork")
D.active = {}
F.ShowEmptyTracker()
assert(E.art.visible and E.detailArt.visible, "removing the last goal restores the book")

local W, oldTween = F.welcome, F.welcome.Tween
local oldListAlpha, oldDetailAlpha = E.art.SetAlpha, E.detailArt.SetAlpha
E.art.SetAlpha = function(self, value) self.testAlpha = value end
E.detailArt.SetAlpha = E.art.SetAlpha
W.Tween = function(_, _, update, finish)
    update(0.5)
    assert(E.art.testAlpha == E.detailArt.testAlpha, "both surfaces fade together")
    finish()
end
F.AnimateEmpty()
assert(E.art.testAlpha == 1 and E.detailArt.testAlpha == 1, "fade settles both panels")
W.Tween, E.art.SetAlpha, E.detailArt.SetAlpha = oldTween, oldListAlpha, oldDetailAlpha
for frame, old in pairs(methods) do
    frame.Show, frame.Hide, frame.IsShown, frame.IsVisible = old.Show, old.Hide, old.IsShown, old.IsVisible
end
D.active, D.activeParts, D.selected, D.progress = saved.active, saved.parts, saved.selected, saved.progress
F.SetSetting("celebrations", saved.celebrations)
print("  book tile scale/bounds/pooling, four fixed fittings, empty/add/remove transitions and paired fades ok")
