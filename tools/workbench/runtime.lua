-- Deliberately synthetic game state. Never reads the real WTF folder.
LAB_NOW = 100
GetTime = function() return LAB_NOW end
GetBuildInfo = function() return "1.60.1", "0", "", 16001 end
GetItemInfo = false
-- No live character exists offline. The fixtures populate the roster explicitly.
UnitName = function() return "" end
IsQuestFlaggedCompleted = function() return false end
GetItemCount = function() return 0 end
IsEquippedItem = function() return false end
IsInGuild = function() return false end
GetStatisticsCategoryList = nil
GetStatistic = nil
LAB_QUEUE = {}
C_Timer.After = function(seconds, callback) table.insert(LAB_QUEUE, {at=LAB_NOW+seconds, fn=callback}) end
function LAB_TIMERS()
    for i=#LAB_QUEUE,1,-1 do
        if LAB_QUEUE[i].at <= LAB_NOW then local job=table.remove(LAB_QUEUE,i); job.fn() end
    end
end
-- Serialization is only between test runtimes, not to the real game save.
function STUB_SERIALIZE(v)
    local kind=type(v)
    if kind == "table" then
        local out={}
        for k,x in pairs(v) do
            local s=STUB_SERIALIZE(x)
            if s and (type(k)=="string" or type(k)=="number") then
                out[#out+1]="["..(type(k)=="string" and string.format("%q",k) or tostring(k)).."]="..s
            end
        end
        return "{"..table.concat(out,",").."}"
    elseif kind=="string" then return string.format("%q",v)
    elseif kind=="number" or kind=="boolean" then return tostring(v) end
end
-- Retrieve private helpers through Lua's debug API in the test runtime only.
function LAB_FIND(ns, wanted)
    local seen={}
    local function visit(fn)
        if type(fn)~="function" or seen[fn] then return end
        seen[fn]=true
        for i=1,1000 do
            local name,value=debug.getupvalue(fn,i)
            if not name then break end
            if name==wanted then return value end
            if type(value)=="function" then local found=visit(value); if found then return found end end
        end
    end
    for _,fn in pairs(ns) do local value=visit(fn); if value then return value end end
    error("Offline adapter could not find "..wanted)
end
function LAB_BIND(ns)
    LAB_PROGRESS=LAB_FIND(ns,"GoalProgress")
    -- ToggleStep is captured by the actual step-row click closures.
    ns.SelectGoal("thunderfury")
    LAB_TOGGLE=LAB_FIND(ns,"ToggleStep")
    LAB_AUTO=LAB_FIND(ns,"ApplyAutoRules")
end
function LAB_ROWS(ns, goal)
    local rows={}
    local progress=ForeverGoalTrackerDB.progress[goal.id] or {}
    local function add(entry,key,section,kind)
        local text=type(entry)=="table" and (entry.text or entry.name) or entry
        rows[#rows+1]={text=text or "",key=key,section=section,kind=kind or "step",done=progress[key]==true,
            automatic=type(entry)=="table" and entry.auto~=nil}
    end
    if goal.sections then
        for si,section in ipairs(goal.sections) do
            if ns.PartSelected(goal,si) then
                for pi,piece in ipairs(section.pieces or {}) do
                    if not ns.PieceSkipped(piece) then
                        if piece.materials and #piece.materials>0 then
                            add(piece,si.."_"..pi.."_piece",section.name,"heading")
                            for mi,m in ipairs(piece.materials) do add(m,si.."_"..pi.."_m"..mi,section.name) end
                        else add(piece,si.."_"..pi.."_piece",section.name) end
                    end
                end
            end
        end
    else
        for i,step in ipairs(goal.steps or {}) do if ns.PartSelected(goal,i) then add(step,i) end end
    end
    return rows
end
function LAB_SNAPSHOT(ns)
    local DB=ForeverGoalTrackerDB
    local goals={}
    for _,g in ipairs(ns.goals) do
        local done,total=LAB_PROGRESS(g)
        goals[#goals+1]={id=g.id,name=g.name,category=g.category,difficulty=g.difficulty,duration=g.timeEstimate,
            description=g.note or "",forever=ns.ForeverNote(g),note=ns.GoalNote(g),done=done,total=total,
            active=DB.active[g.id]==true or (g.group and ns.SelectedPartCount(g)>0),group=g.group or false,
            rows=LAB_ROWS(ns,g),tips=g.tips or {},autoLevels=g.autoLevels or false}
    end
    local undo=ns.resetUndo
    return {goals=goals,selected=DB.selected,undo=undo and {goal=undo.id,seconds=math.max(0,math.ceil(undo.expires-LAB_NOW))},
        chat=STUB_PRINTS,characters=DB.characters,fixture=DB.labFixture or "fresh"}
end
function LAB_FIXTURE(name,id)
    local DB=ForeverGoalTrackerDB
    DB.labFixture=name
    DB.characters={}
    if name~="fresh" then
        DB.characters["Preview-Realm"]={name="Preview",realm="Realm",class="WARRIOR",race="Human",faction="Alliance",
            level=60,xp=0,xpMax=1,lastSeen=time(),items={},quests={},reps={},skills={},money=100000000,bosses={}}
        local c=DB.characters["Preview-Realm"]
        if name=="loot" then c.items[18563]=1; c.items[18564]=1; c.items[19019]=1 end
        if name=="quests" then c.quests[7848]=true; c.quests[7487]=true end
        LAB_AUTO()
    end
    STUB_NS.SelectGoal(id)
end
