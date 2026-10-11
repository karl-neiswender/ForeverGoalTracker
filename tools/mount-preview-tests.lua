local F = STUB_NS
local oldJournal, oldDress, oldMod = C_MountJournal, DressUpMount, IsModifiedClick
local scans, shown = 0, nil
C_MountJournal = {
    GetMountFromItem = function() return nil end,
    GetMountIDs = function() scans = scans+1; return {96,111,97,400} end,
    GetMountInfoByID = function(id) return ({[96]="Swift White Ram",[111]="Swift Zulian Tiger",[97]="Swift Brown Ram",[400]="Blue Qiraji Battle Tank"})[id] end,
}
DressUpMount = function(id) shown = id; return true end
IsModifiedClick = function(kind) return kind == "DRESSUP" end
assert(F.ItemMountID(19902) == 111)
assert(F.ItemMountID(18785) == 96 and F.ItemMountID(18786) == 97, "individual mount colors")
assert(F.ItemMountID(21218) == 400, "crystal item differs from mount name")
assert(F.ItemCanPreview(19902) and scans == 1, "one journal scan per session")
assert(F.PreviewItemClick(18786, "LeftButton") and shown == 97)
local colors = {{18785, "Swift White Ram"}, {18786, "Swift Brown Ram"}}
F.mountPreviewCycle = nil
assert(F.PreviewItemClick(18785, "LeftButton", colors) and shown == 96)
assert(F.PreviewItemClick(18785, "LeftButton", colors) and shown == 97)
assert(F.PreviewItemClick(18785, "LeftButton", colors) and shown == 96)
shown = 97
assert(not F.PreviewItemClick(18785, "RightButton") and shown == 97)
assert(not F.ItemMountID(12360), "materials do not resolve as mounts")
DressUpMount = false
assert(not F.ItemMountID(18785), "unsupported client has no mount preview hint")
C_MountJournal, DressUpMount, IsModifiedClick = oldJournal, oldDress, oldMod
print("  mount names, color variants, direct preview, cache and unsupported client guards ok")
