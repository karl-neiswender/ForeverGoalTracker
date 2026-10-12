-- Keep internal typography helpers while the public font choice is withdrawn.
local F, D = STUB_NS, ForeverGoalTrackerDB
assert(F.SETTING_DEFAULTS.typeStyle == nil and F.TYPE_STYLES.modern == nil)
assert(not D.settings or D.settings.typeStyle == nil, "saved Modern choice retired at startup")
for _, group in ipairs(F.SETTINGS) do
    assert(group.title ~= "Typography", "no public Typography group")
    for _, row in ipairs(group.rows) do assert(row.key ~= "typeStyle", "no font selector") end
end
local progress = STUB_SERIALIZE(D.progress)
local originalRefresh = rawget(_G, "RefreshOverall")
RefreshOverall = false -- catch the previously leaked local helper
local function observe(widget)
    widget.SetFont = function(self, path, size, flags)
        self.testFont = {path,size,flags}
        return not (rawget(self,"rejectTitle") and path:find("Cinzel",1,true))
    end
    widget.SetSpacing = function(self, spacing) self.testSpacing = spacing end
end
for widget in pairs(F.fontWidgets) do observe(widget) end
-- Even an obsolete preference reintroduced at runtime cannot select Modern.
F.SetSetting("typeStyle","modern")
F.ApplyTypeStyle()
local count = 0
for widget, spec in pairs(F.fontWidgets) do
    if rawget(widget,"testFont") then
        count = count+1
        assert(widget.testFont[1] == F.TYPE_STYLES.serif[spec.role])
        assert(widget.testFont[2] == spec.size)
    end
end
assert(count > 30, "existing UI font coverage")
D.settings.typeStyle = nil
-- A temporary internal profile exercises future swaps without a player option.
F.TYPE_STYLES.test = {body=F.TYPE_STYLES.serif.body, title=F.TYPE_STYLES.serif.title,
    bodyScale=1, titleScale=1.10}
for i=1,5 do
    F.activeTypeStyle="test"; F.ApplyTypeStyle()
    F.activeTypeStyle="serif"; F.ApplyTypeStyle()
end
local later = CreateFrame("EditBox")
observe(later)
F.RegisterFont(later,"title",12,"")
assert(later.testFont[1] == F.TYPE_STYLES.serif.title, "lazy widget uses Serif")
later.rejectTitle=true
F.ApplyTypeStyle()
assert(later.testFont[1] == F.TYPE_STYLES.serif.body and later.testFont[2] == 12, "native fallback")
for widget, spec in pairs(F.fontWidgets) do
    if rawget(widget,"testFont") then
        assert(widget.testFont[2] == spec.size, "internal swaps restore original size")
        if spec.lineHeight then
            assert(widget.testSpacing == math.floor(spec.size*(F.LINE_HEIGHT-1)+0.5))
        end
    end
end
F.TYPE_STYLES.test=nil
assert(STUB_SERIALIZE(D.progress) == progress, "typography does not change progress")
RefreshOverall=originalRefresh
print("  saved Modern retired, public choice removed, Serif restored, internal swaps/lazy widgets/fallback preserved")
