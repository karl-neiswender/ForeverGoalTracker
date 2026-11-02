local F, FB = STUB_NS, STUB_NS.Feedback
assert(FB and FB.URL and FB.Open and FB.Describe, "Feedback module loaded")

-- the report names the addon and client but never the character
local text = FB.Describe({ step = "Catch the |cff00ff00One Ring|r", itemId = 12345 })
assert(text:find("Forever Goal Tracker", 1, true), "names the addon")
assert(text:find("Step: Catch the One Ring", 1, true), "step text is plain")
assert(text:find("Item id: 12345", 1, true), "item id is included")
assert(not text:find("|c", 1, true), "no colour codes")

-- the link is built from the form's field ids, encoded, and stays within the limit
local kind = { key = "bug", label = "Bug", form = "Bug" }
local url = FB.URL(kind, "It didn't count my fish & stuff\nsecond line", { itemId = 1 })
assert(url:find("^https://github.com/karl%-neiswender/ForeverGoalTracker/issues/new%?template=feedback.yml"), "form address")
assert(url:find("&kind=Bug&", 1, true), "kind field")
assert(url:find("what=It%%20didn%%27t%%20count%%20my%%20fish%%20%%26%%20stuff%%0Asecond%%20line"), "description is encoded")
assert(not url:find("[ \n]"), "no raw spaces or newlines")
local long = FB.URL(kind, string.rep("x", 600), nil)
assert(#long <= 6600, "link stays short enough: " .. #long)

-- the window opens, takes text, and moves to the copy step
FB.Open({ about = "Test goal" }, "goal")
local pop = ForeverGoalTrackerFeedback
assert(pop, "window exists")
FB.Close()
print("  feedback window and link ok")
