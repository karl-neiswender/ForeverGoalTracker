-- Exercise existing UI widgets, saved choices, later-created widgets and
-- missing-font fallback. The stub cannot prove native font rendering/wraps.
local F = STUB_NS
-- Reject the leaked private helper instead of accepting an unknown API.
local originalRefresh = rawget(_G, "RefreshOverall")
RefreshOverall = false
-- Native FontStrings reject SetText until SetFont succeeds. Also exercise
-- missing font files so optional measurement can never abort startup.
local originalParent = rawget(_G, "UIParent")
UIParent = UIParent -- stabilize the stub's otherwise generated global
local originalCreate = UIParent.CreateFontString
local originalBody, originalTitle = F.TYPE_STYLES.modern.bodyScale, F.TYPE_STYLES.modern.titleScale
for _, failure in ipairs({"none", "modern", "all"}) do
    local font, sample, writes, hidden = nil, nil, 0, false
    local probe = {
        SetFont = function(_, path)
            if failure == "all" or (failure == "modern" and path:find("OpenSans",1,true)) then return false end
            font = path
            return true
        end,
        SetText = function(_, text)
            assert(font, "FontString:SetText(): Font not set")
            sample, writes = text, writes+1
        end,
        GetStringWidth = function()
            assert(sample and sample ~= "", "sample set after font")
            return font:find("OpenSans",1,true) and 100 or 110
        end,
        Hide = function() hidden = true end,
    }
    UIParent.CreateFontString = function() return probe end
    F.typeMetricsMeasured = nil
    F.TYPE_STYLES.modern.bodyScale, F.TYPE_STYLES.modern.titleScale = originalBody, originalTitle
    F.ApplyTypeStyle(true)
    assert(hidden, "measurement probe hidden")
    assert(writes == (failure == "none" and 4 or failure == "modern" and 2 or 0), "only set text on a loaded font")
    if failure ~= "none" then
        assert(F.TYPE_STYLES.modern.bodyScale == originalBody and F.TYPE_STYLES.modern.titleScale == originalTitle,
            "missing fonts retain fallback metrics")
    else
        assert(math.abs(F.TYPE_STYLES.modern.bodyScale - 1.1) < 0.001, "native measurements used")
    end
end
UIParent.CreateFontString = originalCreate
UIParent = originalParent
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
RefreshOverall = originalRefresh
print("  font roles, live switching, stable line advance, lazy widgets, fallback and progress preservation ok")
