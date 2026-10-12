local F, D = STUB_NS, ForeverGoalTrackerDB
local screenW, screenH = 1920, 1080
local oldScreen = F.ScreenSize
F.ScreenSize = function() return screenW, screenH end
F.windowScale = 1
local main, grip
for _, frame in ipairs(STUB_FRAMES) do
    if rawget(frame, "_stubName") == "ForeverGoalTrackerFrame" then main = frame end
end
assert(main)
for _, frame in ipairs(STUB_FRAMES) do
    if rawget(frame, "_stubParent") == main and frame:GetScript("OnMouseDown") then grip = frame end
end
assert(grip, "main-window resize grip")
local width, height, left, top = 1344, 756, 100, 1000
local bounds
main.GetWidth = function() return width end
main.GetHeight = function() return height end
main.GetLeft = function() return left end
main.GetTop = function() return top end
main.GetEffectiveScale = function() return F.windowScale end
main.SetSize = function(self, w, h)
    width, height = w, h
    self:GetScript("OnSizeChanged")(self)
end
main.ClearAllPoints = function() end
main.SetPoint = function(_, _, _, _, x, y) left, top = x, y end
main.SetResizeBounds = function(_, ...) bounds = {...} end
D.frameLeft, D.frameTop = nil, nil

local minW, minH, maxW, maxH, defaultW, defaultH = F.WindowSizeBounds()
assert(defaultW == 1344 and defaultH == 756)
assert(minW == 1008 and minH == 567 and maxW == 1680 and maxH == 945, "approved 75–125% range")
for _, scale in ipairs({0.7, 1, 1.3}) do
    for _, screen in ipairs({{640,480}, {1024,768}, {1920,1080}, {3440,1440}, {3840,2160}}) do
        screenW, screenH, F.windowScale = screen[1], screen[2], scale
        minW, minH, maxW, maxH, defaultW, defaultH = F.WindowSizeBounds()
        local w, h = F.DefaultSize()
        assert(w == defaultW and h == defaultH, "default is shared baseline")
        assert(minW <= w and w <= maxW and minH <= h and h <= maxH, "ordered limits")
        assert(maxW <= screenW/scale-60 and maxH <= screenH/scale-60, "screen margin wins")
        assert(minW >= math.ceil(w*0.75) and minH >= math.ceil(h*0.75), "readable minimum")
        assert(maxW <= math.floor(w*1.25) and maxH <= math.floor(h*1.25), "relative maximum")
        F.sessionWidth, F.sessionHeight = 99999, 1
        F.PlaceWindow()
        assert(width == maxW and height == minH, "independent clamping on placement")
        assert(bounds[1] == minW and bounds[2] == minH and bounds[3] == maxW and bounds[4] == maxH)
        assert(left >= 0 and left + width <= screenW/scale and top >= height and top <= screenH/scale)
        main:SetSize(1,99999)
        assert(width == minW and height == maxH, "programmatic size change clamped")
    end
end

-- Legacy bounds and live drag use exactly the same range.
screenW, screenH, F.windowScale = 1920, 1080, 1
main.SetResizeBounds = false
main.SetMinResize = function(_, w, h) bounds = {w,h} end
main.SetMaxResize = function(_, w, h) bounds[3], bounds[4] = w,h end
F.sessionWidth, F.sessionHeight = F.DefaultSize()
F.PlaceWindow()
assert(bounds[1] == 1008 and bounds[2] == 567 and bounds[3] == 1680 and bounds[4] == 945)
local oldCursor = GetCursorPosition
local cx, cy = 0, 0
GetCursorPosition = function() return cx,cy end
grip:GetScript("OnMouseDown")(grip)
grip:GetScript("OnUpdate")(grip)
assert(width == 1344 and height == 756, "click alone does not resize")
cx, cy = -10000,10000
grip:GetScript("OnUpdate")(grip)
assert(width == 1008 and height == 567, "drag stops at proportional minimum")
cx, cy = 10000,-10000
grip:GetScript("OnUpdate")(grip)
assert(width <= 1680 and height <= 945 and width >= 1008 and height >= 567, "drag stops at maximum/anchor edge")
grip:GetScript("OnMouseUp")(grip)
assert(F.sessionWidth == width and F.sessionHeight == height and not F.sizeStart, "mouse-up keeps valid session dimensions")
GetCursorPosition = oldCursor
F.ScreenSize = oldScreen
print("  relative bounds, small screens, UI scales, placement, both resize APIs, independent dimensions and drag clamping ok")
