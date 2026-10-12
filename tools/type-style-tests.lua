-- Exercise existing UI widgets, saved choices, later-created widgets and
-- missing-font fallback. The stub cannot prove native font rendering/wraps.
local F = STUB_NS
local progress = STUB_SERIALIZE(ForeverGoalTrackerDB.progress)
local function observe(widget)
    widget.SetFont = function(self, path, size, flags)
        self.testFont = { path, size, flags }
        return not (rawget(self, "rejectModern") and path:find("OpenSans", 1, true))
    end
    widget.SetSpacing = function(self, spacing) self.testSpacing = spacing end
end
for widget in pairs(F.fontWidgets) do observe(widget) end
F.SetSetting("typeStyle", "modern")
F.ApplyTypeStyle()
local count = 0
for widget, spec in pairs(F.fontWidgets) do
    if rawget(widget, "testFont") then
        count = count + 1
        assert(widget.testFont[1]:find("OpenSans", 1, true))
        if spec.lineHeight then
            local originalAdvance = spec.size + math.floor(spec.size * (F.LINE_HEIGHT - 1) + 0.5)
            assert(math.abs(widget.testFont[2] + widget.testSpacing - originalAdvance) < 0.001)
        end
    end
end
assert(count > 30, "existing UI font coverage")
for i = 1, 5 do
    F.SetSetting("typeStyle", "serif"); F.ApplyTypeStyle()
    F.SetSetting("typeStyle", "modern"); F.ApplyTypeStyle()
end
local later = CreateFrame("EditBox")
observe(later)
F.RegisterFont(later, "body", 12, "")
assert(later.testFont[1]:find("OpenSans-Regular", 1, true), "lazy widget follows choice")
later.rejectModern = true
F.ApplyTypeStyle()
assert(later.testFont[1] == F.TYPE_STYLES.serif.body and later.testFont[2] == 12, "font fallback")
F.SetSetting("typeStyle", "serif"); F.ApplyTypeStyle()
assert(ForeverGoalTrackerDB.settings.typeStyle == nil, "default stored sparsely")
for widget, spec in pairs(F.fontWidgets) do
    if rawget(widget, "testFont") then
        assert(widget.testFont[2] == spec.size, "switching restores original size")
    end
end
assert(STUB_SERIALIZE(ForeverGoalTrackerDB.progress) == progress, "style does not change progress")
-- Leave modern selected to carry it through the next startup session.
F.SetSetting("typeStyle", "modern"); F.ApplyTypeStyle()
print("  font roles, live switching, stable line advance, lazy widgets, fallback and progress preservation ok")
