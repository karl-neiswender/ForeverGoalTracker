local F = STUB_NS
local goal = F.GoalById("epicmounts")
assert(#goal.sections == 9, "racial mount parts retain their positions")
for i, section in ipairs(goal.sections) do
    local savings
    for _, piece in ipairs(section.pieces) do
        if piece.auto and piece.auto.money then savings = piece end
    end
    assert(savings, "savings milestone exists")
    local expected = (F.isForever or i == 9) and 1200 or 800
    assert(savings.auto.money == expected * 10000, "client-specific budget")
    if F.isForever then
        assert(savings.name == "Save 1,200 gold on that character", "exact undiscounted budget")
    elseif i < 9 then
        assert(savings.name:find("800-1,000",1,true), "Era estimate retained")
    end
end
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
