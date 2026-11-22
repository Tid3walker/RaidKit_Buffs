-- RaidKit Buffs: Data - Lists
-- Fixed choices of the options and the bar: catalog filters and sorts, name alignments and positions, display
-- modes, demo buffs, orientations, docks. Split from Data.lua on 2026-11-20.

local _, ns = ...
local L = ns.L

------------------------------------------------------------------------
-- Catalog filters (group "type" = left column of the menu, "stat" = right column).
-- The same entries are the section headers when the catalog is sorted by type or stat:
-- "type" groups by e.cat, "stat" groups by the primary stat (first tag) in this order.
------------------------------------------------------------------------

ns.FILTERS = {
    { group = "type", label = L["All"] },
    { group = "type", label = L["Flasks, Zanza"], cat = "flask" },
    { group = "type", label = L["Elixirs, Jujus, Resistances"], cat = "elixir" },
    { group = "type", label = L["Potions"], cat = "potion" },
    { group = "type", label = L["Food, Alcohol"], cat = "food" },
    { group = "type", label = L["Weapon (stones, oils, poisons)"], cat = "weapon" },
    { group = "type", label = L["Misc"], cat = "other" },
    { group = "stat", label = L["Attack Power / Strength"], stats = { "ap" } },
    { group = "stat", label = L["Agility"], stats = { "agi" } },
    { group = "stat", label = L["Health / Stamina"], stats = { "hp" } },
    { group = "stat", label = L["Health Regeneration"], stats = { "regen" } },
    { group = "stat", label = L["Spirit"], stats = { "spirit" } },
    { group = "stat", label = L["Mana / Intellect"], stats = { "mana" } },
    { group = "stat", label = L["MP5"], stats = { "mp5" } },
    { group = "stat", label = L["Spell Damage / Healing"], stats = { "spell" } },
    { group = "stat", label = L["Armor"], stats = { "armor" } },
    { group = "stat", label = L["Resistance"], stats = { "resist" } },
    { group = "stat", label = L["Misc"], stats = { "speed", "other", "crit", "poison" } },
}
for _, f in ipairs(ns.FILTERS) do
    if f.cat then
        f.match = function(e) return e.cat == f.cat end
    elseif f.stats then
        f.match = function(e)
            for _, s in ipairs(f.stats) do
                if e.statSet[s] then return true end
            end
            return false
        end
    else
        f.match = function() return true end
    end
end

-- Catalog sort modes (button "Sortierung", saved in RaidKitBuffsDB.catSort).
-- group = FILTERS group whose entries become the section headers (nil = plain A-Z list).
ns.CATALOG_SORTS = {
    { key = "alpha", label = L["A-Z"] },
    { key = "type", label = L["Type"], group = "type" },
    { key = "stat", label = L["Stats"], group = "stat" },
}

-- Position of the row names in the bar (profile.rowNamePos, button "Names: ..." in the options)
-- alignment of the group name only (2026-11-15, user); the icons use ns.ORIENTATIONS (profile.nameAlign, g.nameAlign)
ns.NAME_ALIGNS = {
    { key = "left", label = L["Left"] },
    { key = "center", label = L["Center"] },
    { key = "right", label = L["Right"] },
}

ns.ROW_NAME_POSITIONS = {
    { key = "left", label = L["Left"] },
    { key = "right", label = L["Right"] },
    { key = "topleft", label = L["Top left"] },
    { key = "topright", label = L["Top right"] },
    { key = "bottomleft", label = L["Bottom left"] },
    { key = "bottomright", label = L["Bottom right"] },
}

-- Where the bar is shown (profile.showMode, button "Anzeige: ...", 2026-11-09). Wherever it is shown it
-- replaces the Blizzard buff bar (buffs and debuffs); elsewhere the Blizzard bar stays. party = group
-- without raid. With the options window open the bar is always shown.
ns.SHOW_MODES = {
    { key = "never", label = L["Never"] },
    { key = "always", label = L["Always"] },
    { key = "party", label = L["Party"] },
    { key = "group", label = L["Party + Raid"] },
    { key = "raid", label = L["Raid"] },
}

-- Demo mode (2026-11-10, button on "Darstellung"): fake auras for "Sonstige Buffs" and
-- "Debuffs", so the layout can be judged without a raid. Spell IDs checked on Wowhead Classic
-- (2026-11-10); icon = file in Interface\Icons; dur 0 = no duration; dispel = DebuffTypeColor key.
ns.DEMO_BUFFS = {
    { id = 25315, name = "Renew", icon = "spell_holy_renew", dur = 15 },
    { id = 25299, name = "Rejuvenation", icon = "spell_nature_rejuvenation", dur = 12 },
    { id = 9858, name = "Regrowth", icon = "spell_nature_resistnature", dur = 21 },
    { id = 10901, name = "Power Word: Shield", icon = "spell_holy_powerwordshield", dur = 30 },
    { id = 12970, name = "Flurry", icon = "ability_ghoulfrenzy", dur = 15 },
    { id = 12880, name = "Enrage", icon = "spell_shadow_unholyfrenzy", dur = 12 },
    { id = 20007, name = "Holy Strength", icon = "spell_holy_blessingofstrength", dur = 15 },
    { id = 28866, name = "Kiss of the Spider", icon = "inv_trinket_naxxramas04", dur = 15 },
    { id = 24427, name = "Diamond Flask", icon = "inv_drink_01", dur = 60 },
    { id = 10060, name = "Power Infusion", icon = "spell_holy_powerinfusion", dur = 15 },
}
ns.DEMO_DEBUFFS = {
    { id = 6788, name = "Weakened Soul", icon = "spell_holy_ashestoashes", dur = 15 },
    { id = 11717, name = "Curse of Recklessness", icon = "spell_shadow_unholystrength", dur = 120, dispel = "Curse" },
    { id = 10894, name = "Shadow Word: Pain", icon = "spell_shadow_shadowwordpain", dur = 18, dispel = "Magic" },
    { id = 11201, name = "Crippling Poison", icon = "ability_poisonsting", dur = 12, dispel = "Poison" },
    { id = 23170, name = "Brood Affliction: Bronze", icon = "inv_misc_head_dragon_bronze", dur = 0 },
    { id = 12294, name = "Mortal Strike", icon = "ability_warrior_savageblow", dur = 10 },
}
ns.DEMO_SECONDS = 60

-- How the rows lie in the bar (profile.orientation, button "Ausrichtung: ..."). hright: every row ends at the
-- right edge, icon order unchanged. The columns (vdown/vup) are gone since 2026-11-14 (user: they did not look good
-- and the names did not fit); old values become rows (ns.EnsureGroups), the labels lost the word "Rows".
ns.ORIENTATIONS = {
    { key = "hleft", label = L["Left"] },
    { key = "hright", label = L["Right"] },
}

-- Where the area "Sonstige" (counter, unwanted button, other buffs) docks (profile.otherDock,
-- button "Sonstige: ..."). It grows away from the bar.
ns.OTHER_DOCKS = {
    { key = "bottom", label = L["bottom"] },
    { key = "top", label = L["top"] },
    { key = "left", label = L["left"] },
    { key = "right", label = L["right"] },
}
