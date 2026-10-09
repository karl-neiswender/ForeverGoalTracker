local F = STUB_NS
local outer, inner = F.detailViewport, F.detailStepsScroll
local viewHeight, bodyHeight, scroll, stepHeight = 200, 0, 0, 600
F.detailHeaderHeight = 320
outer.scroll.GetHeight = function() return viewHeight end
outer.content.SetHeight = function(_, h) bodyHeight = h end
outer.content.GetHeight = function() return bodyHeight end
outer.scroll.GetVerticalScroll = function() return scroll end
outer.scroll.SetVerticalScroll = function(_, value) scroll = value end
inner.content.GetHeight = function() return stepHeight end
inner.scroll.GetHeight = function() return math.max(0, bodyHeight - F.detailHeaderHeight) end
F.UpdateDetailViewport()
assert(outer.short and bodyHeight >= 320 + 600, "short panel contains the entire banner and steps")
inner.scroll:GetScript("OnMouseWheel")(inner.scroll, -1)
assert(scroll == 36, "wheel over steps scrolls the entire short panel")
outer.scroll:GetScript("OnMouseWheel")(outer.scroll, -1000)
assert(scroll == bodyHeight - viewHeight, "scroll cannot pass the content bottom")
outer.scroll:GetScript("OnMouseWheel")(outer.scroll, 1000)
assert(scroll == 0, "all banner content remains reachable at the top")
-- Expanding materials or adding a longer note grows the scrollable page.
stepHeight = 1000
F.UpdateDetailViewport()
assert(bodyHeight >= 1320, "expanded recipes cannot escape the scroll child")
F.detailHeaderHeight = 440
F.UpdateDetailViewport()
assert(bodyHeight >= 1440, "long notes and wrapped titles remain reachable")
viewHeight = 700
F.UpdateDetailViewport()
assert(not outer.short and bodyHeight == 700 and scroll == 0, "tall panel restores fixed banner layout")
viewHeight = 202 -- minimum 360px window minus header/panel margins
F.UpdateDetailViewport()
assert(outer.short and bodyHeight > viewHeight, "minimum-height window scrolls safely")
print("  minimum/tall heights, full-page wheel, content bounds, expanded recipes and long headers ok")
