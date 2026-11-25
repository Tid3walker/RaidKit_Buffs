-- RaidKit Buffs: Data - Templates
-- Row templates per class, class groups and the default rows of a new profile, raid buffs in front.
-- Split from Data.lua on 2026-11-20.

local _, ns = ...
local L = ns.L

------------------------------------------------------------------------
-- Row templates per class (menu "+" in the options). Adding one copies it into the
-- profile, so the copy is freely editable. A new profile gets a copy of every template;
-- visible = shown in the bar from the start, the others are hidden (eye off).
-- Items with an entry in ns.DEFAULT_ALTS become a slot with those alternatives (ns.DefaultEntry in Core.lua).
------------------------------------------------------------------------

-- food slot of the "Essen & Co" rows (user 2026-11-11): Dumplings first, then Sunfruit, Squid, Dirge's and the
-- "+12 Stamina/Spirit" foods; without = an item left out (rogue: Grilled Squid has an icon of its own); fresh table per use
local function DUMPLINGS_FULL(without)
    local slot = { 20452, pick = 20452 }
    for _, id in ipairs(ns.DEFAULT_ALTS[20452]) do
        if id ~= without then slot[#slot + 1] = id end
    end
    return slot
end

local function JoinAll(...)
    local out = {}
    for k = 1, select("#", ...) do
        for _, v in ipairs((select(k, ...))) do out[#out + 1] = v end
    end
    return out
end

-- "Selbst verantwortlich" (user 2026-11-14): everything of "Buffs" and "Essen & Co" in one row, in that order, own buffs
-- (warrior: Battle Shout) first. The "Buffs" part gets ns.DEFAULT_ALTS like the row "Buffs", the "Essen & Co" part
-- none (noAltsFrom = first food entry, see ns.TemplateItems).
-- visible = place in a new profile (user 2026-11-14): 1 "Selbst verantwortlich", 2 "Raidbuffs", 3 "Weltbuffs"; every
-- other template only through "+" ("Buffs" and "Essen & Co" too since then). Since 2026-11-19 (user's profile) also
-- 4 "Schutz" (hidden) and 5 "Battle Shout"; split (icons on the left) / splitLast (icons on the right, robust against
-- the faction filter) / sepStyle / hidden are copied into the new row (DefaultRows in Core.lua).
-- name (user 2026-11-18, before "Personal" / "Selbst verantwortlich"): the role the template is made for, else the
-- class: warrior "Tank" (the old template "Tank" is gone), priest/druid/paladin/shaman "Healer", the others the class.
local function SelfRow(own, buffs, food, name)
    -- split (user 2026-11-20): separator "Gap" (no sepStyle) before the first food, so the row is split, aligned both sides
    return { key = "self", name = name, visible = 1, noAltsFrom = #own + #buffs + 1, split = #own + #buffs,
        items = JoinAll(own, buffs, food) }
end

local WARRIOR_BUFFS = {
    13510, -- Flask of the Titans
    20079, -- Spirit of Zanza
    13452, -- Elixir of the Mongoose
    13445, -- Elixir of Superior Defense
    3825,  -- Elixir of Fortitude
    12460, -- Juju Might
    12451, -- Juju Power
}
-- no ns.DEFAULT_ALTS (noAlts), only the alternatives below (user 2026-11-10: Dumplings -> Sunfruit, Squid;
-- Rum -> Grog; stone -> Dense stones; 2026-11-11: Dirge's and its alternatives under the Dumplings)
local WARRIOR_FOOD = {
    DUMPLINGS_FULL(), -- Smoked Desert Dumplings, Sunfruit, Squid, Dirge's + its alternatives
    { 21151, 18269, pick = 21151 }, -- Rumsey Rum Black Label, Gordok Green Grog
    -- weapon: Elemental Sharpening Stone on the off hand only (user 2026-11-10: main hand usually
    -- gets Windfury; drag the stone from the catalog to add the main hand again)
    { 18262, 12404, 12643, pick = 18262, hand = "off" }, -- + Dense Sharpening Stone, Dense Weightstone
}

ns.ROW_TEMPLATES = {
    WARRIOR = {
        -- since 2026-11-14 (user) not in a new profile: "Selbst verantwortlich" holds both
        { key = "buffs", name = L["Buffs"], items = JoinAll(WARRIOR_BUFFS) },
        { key = "food", name = L["Food & Co"], noAlts = true, items = JoinAll(WARRIOR_FOOD) },
        -- Battle Shout first from 2026-11-14 to 2026-11-18 (user), now in its own group "Battle Shout" (template below)
        SelfRow({}, WARRIOR_BUFFS, WARRIOR_FOOD, L["Tank"]),
        { key = "blasted", name = L["Blasted Lands"], items = { -- only here, not in any other template
            8410,  -- R.O.I.D.S.
            8412,  -- Ground Scorpok Assay
            8411,  -- Lung Juice Cocktail
        } },
        -- in a new profile hidden, potions left | resistances right (user 2026-11-19, PROTECTION_ROW)
        { key = "protection", name = L["Protection"], visible = 4, hidden = true, split = 5, sepStyle = "icon", items = {
            13461, -- Greater Arcane Protection Potion
            13458, -- Greater Nature Protection Potion
            13459, -- Greater Shadow Protection Potion
            13457, -- Greater Fire Protection Potion
            13456, -- Greater Frost Protection Potion
            -- since 2026-11-18 (user) the resistance buffs of the removed template "Situativ" (without Amplify Magic,
            -- that went to the end of "Raidbuffs"; Fear Ward is gone)
            -19900, -- Fire Resistance Aura (Alliance)
            -10535, -- Fire Resistance Totem (Horde)
            -19898, -- Frost Resistance Aura (Alliance)
            -10477, -- Frost Resistance Totem (Horde)
            -10599, -- Nature Resistance Totem (Horde)
            -27683, -- Shadow Protection
        } },
        { key = "combat", name = L["Combat"], items = {
            13455, -- Greater Stoneshield Potion
            13442, -- Mighty Rage Potion
            3387,  -- Limited Invulnerability Potion
            5634,  -- Free Action Potion
        } },
        { key = "dps", name = L["DPS"], items = { -- strength / attack power / agility only, no health or armor
            13452, -- Elixir of the Mongoose
            12451, -- Juju Power
            12460, -- Juju Might
            20452, -- Smoked Desert Dumplings
        } },
        -- rows with foreign buffs: negative IDs = ns.BUFFS below; buffs of the other faction are dropped (since 2026-11-11 every row may mix both kinds)
        -- world buffs in the order of the user (2026-11-10): Songflower, Rend, Ony, ZG, Fengus, Mol'dar, DMF
        { key = "world", name = L["World Buffs"], visible = 3, splitLast = 2, sepStyle = "icon", items = {
            -15366, -- Songflower Serenade
            -16609, -- Warchief's Blessing
            -22888, -- Rallying Cry of the Dragonslayer
            -24425, -- Spirit of Zandalar
            -22817, -- Fengus' Ferocity
            -22818, -- Mol'dar's Moxie
            -23768, -- Sayge's Dark Fortune of Damage
            -990032, -- Buff counter (user 2026-11-25: left of the Chronoboon, right of the separator)
            -349981, -- Supercharged Chronoboon Displacer (user 2026-11-17: at the end)
        } },
        { key = "raid", name = L["Raid Buffs"], visible = 2, splitLast = 1, sepStyle = "icon", items = { -- Amplify Magic right
            -- order of the user (2026-11-12): Battle Shout, Prayer, Gift, Leader, Trueshot, Strength, Grace; the
            -- Alliance blessings (dropped for the Horde) in the place of the totems. Battle Shout removed 2026-11-14
            -- (user: own buff, it sits in "Selbst verantwortlich"; see the OWN_BUFFS filter below). Trueshot before
            -- Leader of the Pack since 2026-11-17 (user)
            -21564, -- Fortitude (Prayer of Fortitude)
            -21850, -- Mark / Gift of the Wild
            -20906, -- Trueshot Aura
            -24932, -- Leader of the Pack
            -25362, -- Strength of Earth (Horde)
            -25360, -- Grace of Air (Horde)
            -25898, -- Blessing of Kings (Alliance)
            -25916, -- Blessing of Might (Alliance)
            -10170, -- Amplify Magic (user 2026-11-18, from the removed template "Situativ")
        } },
        -- "Situativ" removed 2026-11-18 (user): its resistance buffs are in "Schutz", Amplify Magic in "Raidbuffs"
        -- Battle Shout alone (user 2026-11-18): in a new profile the only row of the group "shout" (ns.CLASS_GROUPS)
        { key = "shout", name = L["Battle Shout"], visible = 5, group = "shout", items = { -25289 } },
    },
}

-- Groups a new profile of a class gets besides "Buffs & Cons" and the three areas (user 2026-11-18; = CLASS_GROUPS in
-- the mockup). Their rows come from the templates with the same group (tpl.group). snap/side/align = default place
-- (ns.EnsureGroupPos), the rest are group values. Existing profiles get them only with /rkb reset.
ns.CLASS_GROUPS = {
    WARRIOR = {
        -- big icon at the bottom left of Buffs & Cons
        { id = "shout", name = "Battle Shout", iconSize = 64, snap = "main", side = "left", align = "end" },
    },
}

-- Buff rows for the other classes (user 2026-11-10): three rows each, by the usual raid role in Era.
-- Rogue/hunter = physical damage, mage/warlock = spell damage, priest/druid/paladin/shaman = healer
-- (hybrids pick their row by the most common raid role; feral/enhancement/shadow players adjust by hand).
-- Buffs of the other faction are dropped when the template is copied. Consumable rows (2026-11-10, user):
-- like the warrior's, from the catalog only: "Buffs", "Essen & Co" (with the weapon oil/poison)
-- visible, "Schutz" (user 2026-11-10), "Blasted Lands" and "Kampf" hidden. Alternatives come from ns.DEFAULT_ALTS when copied, except in
-- rows with noAlts ("Essen & Co", user 2026-11-10: plain icons).
-- Wowhead 2026-11-10: Fengus' Ferocity = attack power (melee and ranged); Blessing of Might and Battle Shout
-- = melee attack power only (useless for hunters and casters); Trueshot Aura = ranged + melee, Leader of
-- the Pack = ranged + melee crit.
-- order of the user (2026-11-10): Songflower, Rend, Ony, ZG, then Fengus/Slip'kik, Mol'dar, DMF
local WORLD_COMMON = { -15366, -16609, -22888, -24425 } -- Songflower, Warchief's Blessing, Rallying Cry, Zandalar
local WORLD = {
    physical = { -22817, -22818, -23768 }, -- Fengus' Ferocity, Mol'dar's Moxie, Sayge's Damage
    caster = { -22820, -22818, -23768 },   -- Slip'kik's Savvy, Mol'dar's Moxie, Sayge's Damage
    healer = { -22820, -22818, -23766 },   -- Slip'kik's Savvy, Mol'dar's Moxie, Sayge's Intelligence
}
-- Battle Shout first for the rogue (user 2026-11-20; the warrior has it in his own group "Battle Shout"; the hunter
-- has it in his default "Unwanted" list, melee attack power only)
local RAID = {
    ROGUE = { -25289, -21564, -21850, -25898, -25916, -25895, -25362, -25360, -20906, -24932 }, -- + Might, Salvation, SoE, GoA, Trueshot, LotP (user 2026-11-15; swapped 2026-11-17)
    HUNTER = { -21564, -21850, -25898, -25895, -23028, -25360, -20906, -24932 }, -- + Salvation, Int, GoA, Trueshot, LotP
    caster = { -21564, -21850, -25898, -25895, -23028, -27681 }, -- Fort, Mark, Kings, Salvation, Int, Spirit
    healer = { -21564, -21850, -25898, -25895, -23028, -27681 },
}
-- resistances: auras (Alliance) or totems (Horde), Shadow Protection; since 2026-11-18 (user) the end of "Schutz"
-- (before the template "Situativ")
local SITU_COMMON = { -19900, -10535, -19898, -10477, -10599, -27683 }

local function Join(a, b)
    local out = {}
    for _, v in ipairs(a) do out[#out + 1] = v end
    for _, v in ipairs(b or {}) do out[#out + 1] = v end
    return out
end
local function BuffRows(world, raid)
    return {
        -- + Chronoboon at the end (2026-11-17), separated on the right (user 2026-11-19); the buff counter left of it,
        -- also right of the separator (user 2026-11-25)
        { key = "world", name = L["World Buffs"], visible = 3, splitLast = 2, sepStyle = "icon", items = Join(Join(WORLD_COMMON, world), { -990032, -349981 }) },
        -- like the warrior's row (user 2026-11-20): Amplify Magic separated on the right
        { key = "raid", name = L["Raid Buffs"], visible = 2, splitLast = 1, sepStyle = "icon", items = Join(raid, { -10170 }) },
        -- "Situativ" removed 2026-11-18 (user): SITU_COMMON is part of "Schutz" (ConsumableRows)
    }
end
-- slots with their alternative for the "Essen & Co" rows (noAlts, user 2026-11-10); a fresh table per use
-- Food buffs never stack in Classic (one "Well Fed" at a time, a new one replaces the old; user 2026-11-14), so
-- every template has exactly one food slot, the other foods are its alternatives.
-- rogue (2026-11-14): Grilled Squid first, then Dumplings and the rest of the Dumplings slot (was an icon of its own)
local function SQUID()
    local slot = DUMPLINGS_FULL(13928)
    table.insert(slot, 1, 13928)
    slot.pick = 13928
    return slot
end
local function RUNN_TUM() return { 18254, 13931, pick = 18254 } end -- Runn Tum Tuber Surprise, Nightfin Soup (mage, warlock)
local function NIGHTFIN() return { 13931, 18254, pick = 13931 } end -- Nightfin Soup, Runn Tum Tuber Surprise (healers)
local function RUM() return { 21151, 18269, pick = 21151 } end       -- Rumsey Rum Black Label, Gordok Green Grog
local PROTECTION = { 13461, 13458, 13459, 13457, 13456 } -- greater arcane/nature/shadow/fire/frost protection
-- own buffs of a class at the front of "Selbst verantwortlich" (user 2026-11-14: what the class casts on itself,
-- e.g. a priest Fortitude, a mage Intellect, a druid Mark of the Wild). Only buffs of ns.BUFFS with selfClass.
-- Paladins, shamans, warlocks and rogues have none in the catalog (blessings/totems come from others in a raid).
-- 2026-11-14 (user): also the buffs of the catalog section "Eigene" (Inner Fire, armors, aspect ...).
-- Paladins (healer template) get nothing: blessings come from others, Righteous Fury only for tanks (catalog).
local OWN_BUFFS = {
    PRIEST = { -21564, -27681, -10952 }, -- Fortitude, Divine Spirit (talent), Inner Fire
    -- Arcane Intellect, armor slot Mage Armor > Ice Armor (2026-11-15, user; before one icon for both)
    MAGE = { -23028, { -22783, -10220, pick = -22783 } },
    DRUID = { -21850, -16864 },          -- Mark of the Wild, Omen of Clarity (talent)
    HUNTER = { -20906, -25296 },         -- Trueshot Aura (talent, most raid hunters are marksmen), Aspect of the Hawk
    WARLOCK = { -11735 },                -- Demon Armor / Demon Skin
    SHAMAN = { -10432 },                 -- Lightning Shield
}
local function ConsumableRows(name, buffs, food, blasted, combat, own)
    return {
        { key = "buffs", name = L["Buffs"], items = Join(buffs) }, -- not in a new profile since 2026-11-14 (user)
        { key = "food", name = L["Food & Co"], noAlts = true, items = Join(food) }, -- no alternatives (user 2026-11-10)
        SelfRow(own or {}, buffs, food, name),
        { key = "blasted", name = L["Blasted Lands"], items = Join(blasted) },
        -- + resistance buffs (2026-11-18); in a new profile hidden, potions | resistances (user 2026-11-19)
        { key = "protection", name = L["Protection"], visible = 4, hidden = true, split = #PROTECTION, sepStyle = "icon", items = Join(PROTECTION, SITU_COMMON) },
        { key = "combat", name = L["Combat"], items = Join(combat) },
    }
end
local BLASTED = {
    physical = { 8410, 8412, 8411 }, -- R.O.I.D.S., Ground Scorpok Assay, Lung Juice Cocktail
    hunter = { 8412, 8411 },        -- (strength is useless for hunters)
    caster = { 8423, 8424, 8411 },  -- Cerebral Cortex Compound, Gizzard Gum, Lung Juice Cocktail
}
local CONSUMABLES = {
    ROGUE = ConsumableRows(L["Rogue"],
        { 20079, 13452, 12451, 12460 },          -- Spirit of Zanza, Mongoose, Juju Power, Juju Might
        { SQUID(), RUM(),                        -- Grilled Squid (+ Dumplings slot), Rumsey Rum Black Label
          { 8928, pick = 8928, hand = "main" },    -- Instant Poison VI
          { 20844, pick = 20844, hand = "off" } }, -- Deadly Poison V
        BLASTED.physical,
        { 5634, 20008, 3387 }),                  -- Free Action, Living Action, Limited Invulnerability
    HUNTER = ConsumableRows(L["Hunter"],
        { 20079, 13452, 12460 },                 -- Zanza, Mongoose, Juju Might (attack power, ranged too)
        { 13928, RUM() },                        -- Grilled Squid, Rumsey Rum Black Label
        BLASTED.hunter,
        { 5634, 20008, 3387 }, OWN_BUFFS.HUNTER),
    MAGE = ConsumableRows(L["Mage"],
        -- Zanza always right of the flask (user 2026-11-14, every class)
        { 13512, 20079, 13454, 21546, 17708 },   -- Supreme Power, Zanza, Greater Arcane, Greater Firepower, Frost Power
        { RUNN_TUM(), RUM(),                     -- Runn Tum Tuber Surprise (+ Nightfin Soup), Rumsey Rum Black Label
          { 20749, pick = 20749, hand = "main" } }, -- Brilliant Wizard Oil
        BLASTED.caster,
        { 5634, 20008 }, OWN_BUFFS.MAGE),
    WARLOCK = ConsumableRows(L["Warlock"],
        { 13512, 20079, 13454, 9264 },           -- Supreme Power, Zanza, Greater Arcane, Shadow Power
        { RUNN_TUM(), RUM(),
          { 20749, pick = 20749, hand = "main" } },
        BLASTED.caster,
        { 5634, 20008 }, OWN_BUFFS.WARLOCK),
}
-- healers: mana and intellect, Brilliant Mana Oil; own buffs per class (OWN_BUFFS)
local function HealerConsumables(class)
    return ConsumableRows(L["Healer"],
        { 13511, 20079, 20007, 9179, 12458 },        -- Distilled Wisdom, Zanza, Mageblood, Greater Intellect, Juju Guile
        { NIGHTFIN(), RUM(),                         -- Nightfin Soup (+ Runn Tum Tuber Surprise), Rumsey Rum Black Label
          { 20748, pick = 20748, hand = "main" } }, -- Brilliant Mana Oil
        BLASTED.caster,
        { 5634, 20008 }, OWN_BUFFS[class])
end

ns.ROW_TEMPLATES.ROGUE = Join(CONSUMABLES.ROGUE, BuffRows(WORLD.physical, RAID.ROGUE))
ns.ROW_TEMPLATES.HUNTER = Join(CONSUMABLES.HUNTER, BuffRows(WORLD.physical, RAID.HUNTER))
for _, class in ipairs({ "MAGE", "WARLOCK" }) do
    ns.ROW_TEMPLATES[class] = Join(CONSUMABLES[class], BuffRows(WORLD.caster, RAID.caster))
end
for _, class in ipairs({ "PRIEST", "DRUID", "PALADIN", "SHAMAN" }) do
    ns.ROW_TEMPLATES[class] = Join(HealerConsumables(class), BuffRows(WORLD.healer, RAID.healer))
end

-- "Raidbuffs" = buffs that come from others (user 2026-11-14): a buff the class casts on itself (OWN_BUFFS, warrior
-- Battle Shout) sits in "Selbst verantwortlich" and is left out of its "Raidbuffs" (priest: no Fortitude/Divine
-- Spirit, mage: no Intellect, druid: no Mark, hunter: no Trueshot). Done here for every class at once.
OWN_BUFFS.WARRIOR = { -25289 } -- Battle Shout

-- "Raidbuffs" start with Stamina, Intellect, Spirit, Gift of the Wild (user 2026-11-14, every class), as far as the
-- row holds them (unwanted or own buffs are not in it); every other entry keeps its order behind them.
-- Also used once for existing profiles (Core.lua, flag raidbuffsFront).
ns.RAID_FRONT = { -21564, -23028, -27681, -21850 } -- Fortitude, Arcane Intellect, Divine Spirit, Mark of the Wild
function ns.FrontRaidBuffs(items)
    local front, rest, rank = {}, {}, {}
    for i, id in ipairs(ns.RAID_FRONT) do rank[id] = i end
    for _, e in ipairs(items) do
        if type(e) == "number" and rank[e] then front[rank[e]] = e else rest[#rest + 1] = e end
    end
    local out = {}
    for i = 1, #ns.RAID_FRONT do
        if front[i] then out[#out + 1] = front[i] end
    end
    for _, e in ipairs(rest) do out[#out + 1] = e end
    return out
end

for class, templates in pairs(ns.ROW_TEMPLATES) do
    local own = {}
    for _, id in ipairs(OWN_BUFFS[class] or {}) do own[id] = true end
    for _, tpl in ipairs(templates) do
        if tpl.key == "raid" then -- key, not the localized name
            local kept = {}
            for _, id in ipairs(tpl.items) do
                if not own[id] then kept[#kept + 1] = id end
            end
            tpl.items = ns.FrontRaidBuffs(kept)
        end
    end
end
