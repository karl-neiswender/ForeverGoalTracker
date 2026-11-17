local F = STUB_NS
local goal = F.GoalById("epicmounts")
assert(#goal.sections == 9, "racial mount parts retain their positions")
for i, section in ipairs(goal.sections) do
    local savings
    for _, piece in ipairs(section.pieces) do
        if piece.auto and piece.auto.money then savings = piece end
    end
    assert(savings, "savings milestone exists")
    local expected = F.isForever and 1000 or (i == 9 and 1200 or 800)
    assert(savings.auto.money == expected * 10000, "client-specific budget")
    local n = #section.pieces
    if F.isForever then
        -- Forever: save, train with your race's trainer ('Swift as the Wind'), then the free mount ('An Epic Ride')
        assert(savings.name == "Save 1,000 gold on that character", "Journeyman Riding is the Forever cost")
        assert(section.pieces[n - 2] == savings, "saving comes before training on Forever")
        assert(section.pieces[n - 1].auto.skill and section.pieces[n - 1].name:find("('Swift as the Wind')", 1, true)
            and section.pieces[n - 1].name:find("^Train Journeyman Riding from %u"), "race trainer named")
        assert(section.pieces[n].name:find("^Complete 'An Epic Ride' and choose "), "free mount quest")
    else
        assert(section.pieces[n - 1] == savings and section.pieces[n - 2].name == "Train Expert Riding", "Era order kept")
        assert(section.pieces[n].name:find("^Buy "), "Era purchase kept")
        if i < 9 then assert(savings.name:find("800-1,000",1,true), "Era estimate retained") end
    end
end
assert(F.isForever == (#goal.sections[7].pieces[5].links[1].variants == 3), "Ochre Skeletal Warhorse only on Forever")
assert(F.ForeverStatus(goal) == "confirmed" and not F.ForeverNote(goal), "no Unconfirmed notice on the mount goal")
local text = table.concat(goal.tips, " ")
if F.isForever then
    assert(text:find("1,000 gold",1,true) and text:find("200 gold",1,true))
    assert(text:find("100 gold",1,true) and text:find("20 gold",1,true))
    assert(text:find("before faction discounts",1,true))
    assert(#F.GroupParts(goal) == 9, "Skyborne still included")
else
    assert(text:find("Honored",1,true), "Era discount guidance retained")
    assert(#F.GroupParts(goal) == 8, "Skyborne still hidden")
end
print("  all racial budgets, client separation, training/mount prices, discount caveat and stable parts ok")
