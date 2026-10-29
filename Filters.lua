local ADDON, FGT = ...

-- Who a goal is for. Used by the Library's "For" filter and the My Goals
-- "This character" view. Most goals are for everyone; these say otherwise.
-- Weapons follow Classic weapon skills (one-handed swords: Warrior,
-- Paladin, Rogue, Hunter, Mage, Warlock; two-handed swords: Warrior,
-- Paladin, Hunter; two-handed maces: Warrior, Paladin, Shaman, Druid).
-- Armor sets need no entry: every class version is its own goal.
FGT.CLASSES = {
    { token = "WARRIOR", name = "Warrior" }, { token = "PALADIN", name = "Paladin" },
    { token = "HUNTER", name = "Hunter" },   { token = "ROGUE", name = "Rogue" },
    { token = "PRIEST", name = "Priest" },   { token = "SHAMAN", name = "Shaman" },
    { token = "MAGE", name = "Mage" },       { token = "WARLOCK", name = "Warlock" },
    { token = "DRUID", name = "Druid" },
}

local ONE_HAND_SWORD = { "WARRIOR", "PALADIN", "ROGUE", "HUNTER", "MAGE", "WARLOCK" }
local ONE_HAND_MACE = { "WARRIOR", "PALADIN", "ROGUE", "PRIEST", "SHAMAN", "DRUID" }
local WAND = { "PRIEST", "MAGE", "WARLOCK" }
local SHIELD = { "WARRIOR", "PALADIN", "SHAMAN" }
FGT.GOAL_CLASSES = {
    social_buffs = { "MAGE", "DRUID", "PRIEST", "PALADIN" }, -- supported by FGT.BUFF_CLASSES
    thunderfury = ONE_HAND_SWORD,
    quelserrar = ONE_HAND_SWORD,
    sulfuras = { "WARRIOR", "PALADIN", "SHAMAN", "DRUID" },
    ashbringer = { "WARRIOR", "PALADIN", "HUNTER" },
    zinrokh = { "WARRIOR", "PALADIN", "HUNTER" },
    teebus = ONE_HAND_SWORD,
    bonereavers_edge = { "WARRIOR", "PALADIN", "HUNTER" },
    deathbringer = { "WARRIOR", "PALADIN", "HUNTER", "SHAMAN" },
    lava_dredger = { "WARRIOR", "PALADIN", "SHAMAN", "DRUID" },
    flame_wrath = { "WARRIOR", "PALADIN", "HUNTER", "DRUID" },
    frostguard = ONE_HAND_SWORD,
    gift_of_the_elven_magi = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" },
    glacial_blade = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" },
    gutgore_ripper = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" },
    halberd_of_smiting = { "WARRIOR", "PALADIN", "HUNTER", "DRUID" },
    illusionary_rod = { "WARRIOR", "HUNTER", "PRIEST", "SHAMAN", "DRUID", "MAGE", "WARLOCK" },
    inventors_focal_sword = ONE_HAND_SWORD,
    jindos_judgement = { "WARRIOR", "HUNTER", "PRIEST", "SHAMAN", "DRUID", "MAGE", "WARLOCK" },
    krol_blade = ONE_HAND_SWORD,
    will_of_arlokk = { "WARRIOR", "HUNTER", "PRIEST", "SHAMAN", "DRUID", "MAGE", "WARLOCK" },
    mandokirs_sting = { "WARRIOR", "HUNTER", "ROGUE" },
    mograines_might = { "WARRIOR", "PALADIN", "SHAMAN", "DRUID" },
    obsidian_edged_blade = { "WARRIOR", "PALADIN", "HUNTER" },
    perditions_blade = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" },
    ashkandi = { "WARRIOR", "PALADIN", "HUNTER" },
    maladath = ONE_HAND_SWORD,
    hungering_cold = ONE_HAND_SWORD,
    might_of_menethil = { "WARRIOR", "PALADIN", "SHAMAN", "DRUID" },
    rod_of_the_ogre_magi = { "WARRIOR", "HUNTER", "PRIEST", "SHAMAN", "DRUID", "MAGE", "WARLOCK" },
    shadowstrike = { "WARRIOR", "PALADIN", "HUNTER", "DRUID" },
    silent_fang = ONE_HAND_SWORD,
    spinal_reaper = { "WARRIOR", "PALADIN", "HUNTER", "SHAMAN" },
    staff_of_dominance = { "WARRIOR", "HUNTER", "PRIEST", "SHAMAN", "DRUID", "MAGE", "WARLOCK" },
    staff_of_the_ruins = { "WARRIOR", "HUNTER", "PRIEST", "SHAMAN", "DRUID", "MAGE", "WARLOCK" },
    sulthraze = { "WARRIOR", "PALADIN", "HUNTER" },
    sword_of_zeal = ONE_HAND_SWORD,
    destiny = { "WARRIOR", "PALADIN", "HUNTER" },
    cruel_hand_of_timmy = ONE_HAND_MACE,
    hammer_of_grace = ONE_HAND_MACE,
    mass_of_mcgowan = ONE_HAND_MACE,
    viking_warhammer = ONE_HAND_MACE,
    twig_of_the_world_tree = { "WARRIOR", "PALADIN", "SHAMAN", "DRUID" },
    fiery_war_axe = { "WARRIOR", "PALADIN", "HUNTER", "SHAMAN" }, -- two-handed axe users
    wraith_scythe = { "WARRIOR", "PALADIN", "HUNTER", "SHAMAN" }, -- one-handed axe users
    thrash_blade = ONE_HAND_SWORD,
    viskag = ONE_HAND_SWORD,
    lobotomizer = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" },
    unstoppable_force = { "WARRIOR", "PALADIN", "SHAMAN", "DRUID" },
    touch_of_chaos = WAND,
    wand_of_biting_cold = WAND,
    wand_of_eternal_light = WAND,
    doomfinger = WAND,
    phantom_blade = ONE_HAND_SWORD,
    cruel_barb = ONE_HAND_SWORD,
    gurubashi_dwarf_destroyer = { "WARRIOR", "HUNTER", "ROGUE" }, -- gun users
    hypnotic_blade = { "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }, -- caster dagger users
    claw_of_the_frost_wyrm = { "WARRIOR", "HUNTER", "ROGUE" }, -- off-hand fist weapon: needs Dual Wield
    masterwork_stormhammer = ONE_HAND_MACE,
    immovable_object = SHIELD,
    wall_of_the_dead = SHIELD,
    skullflame_shield = SHIELD,
    ancient_bone_bow = { "WARRIOR", "HUNTER", "ROGUE" },
    annihilator = { "WARRIOR", "PALADIN", "HUNTER", "SHAMAN" }, -- one-handed axe users
    azuresong_mageblade = ONE_HAND_SWORD,
    heartseeker = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" },
    black_amnesty = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" },
    blackcrow = { "WARRIOR", "HUNTER", "ROGUE" },
    blastershot_launcher = { "WARRIOR", "HUNTER", "ROGUE" },
    bloodseeker = { "WARRIOR", "HUNTER", "ROGUE" },
    ice_barbed_spear = { "WARRIOR", "PALADIN", "HUNTER" }, -- polearm users
    barman_shanker = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }, -- dagger users
    lord_valthalaks_staff_of_command = { "WARRIOR", "HUNTER", "PRIEST", "SHAMAN", "DRUID", "MAGE", "WARLOCK" }, -- staff users
    widows_remorse = ONE_HAND_SWORD,
    brain_hacker = { "WARRIOR", "PALADIN", "HUNTER", "SHAMAN" }, -- two-handed axe users
    brutality_blade = ONE_HAND_SWORD,
    cold_forged_hammer = ONE_HAND_MACE,
    claw_of_the_black_drake = { "WARRIOR", "HUNTER", "ROGUE", "SHAMAN", "DRUID" },
    demonslayer = { "WARRIOR", "PALADIN", "HUNTER" },
    draconian_deflector = SHIELD,
    drillborer_disk = SHIELD,
    dwarven_hand_cannon = { "WARRIOR", "HUNTER", "ROGUE" },
    electrified_dagger = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" },
    eskhandars_right_claw = { "WARRIOR", "HUNTER", "ROGUE", "SHAMAN", "DRUID" },
    fang_of_the_crystal_spider = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" },
    felstriker = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" },
    the_untamed_blade = { "WARRIOR", "PALADIN", "HUNTER" },
    the_shatterer = ONE_HAND_MACE,
    crimson_shocker = WAND,
    crackling_staff = { "WARRIOR", "HUNTER", "PRIEST", "SHAMAN", "DRUID", "MAGE", "WARLOCK" },
    core_hound_tooth = { "WARRIOR", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" },
    headmasters_charge = { "WARRIOR", "HUNTER", "PRIEST", "SHAMAN", "DRUID", "MAGE", "WARLOCK" },
    aurastone_hammer = { "WARRIOR", "PALADIN", "ROGUE", "PRIEST", "SHAMAN", "DRUID" },
    arcanite_reaper = { "WARRIOR", "PALADIN", "HUNTER", "SHAMAN" }, -- two-handed axe users
    atiesh = { "MAGE", "WARLOCK", "PRIEST", "DRUID" }, -- one version per class
    benediction = { "PRIEST" },
    rhokdelar = { "HUNTER" },
    lokdelar = { "HUNTER" },
    wolfsbane = { "PALADIN" },
    mount_charger = { "PALADIN" },
    mount_dreadsteed = { "WARLOCK" },
    set_viper = { "DRUID" },
    set_violet_sorcerer = { "MAGE", "PRIEST", "WARLOCK" },
}
FGT.GOAL_RACES = {
    wolfsbane = { "Scourge" },
}

local function Has(list, value)
    for _, v in ipairs(list) do if v == value then return true end end
    return false
end

-- The logged-in character: class token, race token and faction.
function FGT.PlayerProfile()
    local class = UnitClass and select(2, UnitClass("player"))
    local race = UnitRace and select(2, UnitRace("player"))
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    local key = FGT.MaterialsUI and FGT.MaterialsUI.charKey and FGT.MaterialsUI.charKey()
    return { class = class, race = race, faction = faction, key = key }
end

-- The goal's thumbnail. Epic Racial Mounts wears the logged-in character's
-- own race's mount (a Night Elf sees the Swift Saber), like its step does.
function FGT.GoalIcon(goal)
    if goal.group and goal.sections then
        local race = FGT.PlayerProfile().race
        if race then
            for _, section in ipairs(goal.sections) do
                if section.icon and (section.forever ~= "new" or FGT.isForever) then
                    for _, piece in ipairs(section.pieces or {}) do
                        if piece.skipIfRace == race or (piece.auto and piece.auto.forRace == race) then
                            return section.icon
                        end
                    end
                end
            end
        end
    end
    return goal.icon
end

-- "Druid - Bloodfang Armor" -> "DRUID"
local function SectionClass(name)
    local class = type(name) == "string" and name:match("^(%a+) %- ")
    return class and class:upper()
end
FGT.SectionClass = SectionClass

-- True when a goal suits this class (and race and faction, when given).
-- who = { class = "DRUID", race = "NightElf", faction = "Alliance" };
-- any field may be nil to skip that check.
function FGT.GoalFits(goal, who)
    if not who then return true end
    -- a Gear Planner set belongs to the character it was planned for
    if goal.plannerOwner then return not who.key or who.key == goal.plannerOwner end
    if who.faction and goal.faction and goal.faction ~= who.faction then return false end
    local class = who.class
    if class then
        if goal.armorClass then return goal.armorClass:upper() == class end
        if goal.armorChildren then -- a Library collection: any class version fits
            for _, child in ipairs(goal.armorChildren) do
                if child.armorClass and child.armorClass:upper() == class then return true end
            end
            return false
        end
        local classes = FGT.GOAL_CLASSES[goal.id]
        if classes and not Has(classes, class) then return false end
    end
    local races = FGT.GOAL_RACES[goal.id]
    if who.race and races and not Has(races, who.race) then return false end
    return true
end

-- A class version inside a collection, or any other group part.
function FGT.PartFits(goal, part, who)
    if not (who and who.class and goal.armorChildren) then return true end
    local class = SectionClass(part.label)
    return not class or class == who.class
end
