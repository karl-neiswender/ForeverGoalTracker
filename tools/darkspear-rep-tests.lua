local F = STUB_NS
local theramore = assert(F.GoalById("pvp_theramore_expedition"))
assert(theramore.name == "Exalted: Theramore Expeditionary Force")
assert(theramore.short == "Theramore Expedition", "compact goal-list title")
assert(theramore.forever == "new" and theramore.needs == "forever")
assert(F.LibraryVisible(theramore) == F.isForever, "Theramore Expedition is Forever-only")
if F.isForever then
    local frame = {}
    assert(F.ApplyForeverLook(frame, theramore) == "NEW" and frame.foreverNew,
        "Theramore Expedition uses the New in Forever treatment")
end

local darkspear = assert(F.GoalById("pvp_darkspear_raiders"))
assert(darkspear.forever == "confirmed" and darkspear.needs == "forever")
print("  Darkspear Islands reputations: Theramore compact title and New in Forever treatment ok")
