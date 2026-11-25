-- RaidKit Buffs: Data - Catalog
-- Catalog of all consumables that apply a buff (class independent), weapon enchants, raid list, buff places,
-- default alternatives, class filter, preprocessing (ns.catalog). Split from Data.lua on 2026-11-20.
--
-- Fields per entry:
--   id    item ID
--   buff  spell ID of the aura on the player AFTER use (not the use spell!)
--         Example food: eating casts "Food" (24800), the buff afterwards is 24799.
--   dur   buff duration in seconds (info/mockup)
--   cat   type: flask (flasks and Zanza, 2 h buffs), elixir (incl. jujus and 1 h protection potions),
--         potion (combat/emergency potions), food (food and alcohol),
--         other (incl. scrolls)
--   stats stat tags (space separated): ap agi hp regen spirit mana mp5 spell armor resist crit speed other
--         The FIRST tag is the primary stat (decides the class filter).
--   tier  1 = best, 2 = 2nd best, 3 = weak (data only; the catalog tabs use ns.RAID_ITEMS)
--   icon  Wowhead icon name (HTML mockup only; in game the icon comes from GetItemIcon)
--   name  English name (fallback/search; in game the localized name is shown)
--   note  short stat note shown to the user (tooltip and search), English key L["..."], German in Locale_deDE.lua
-- All IDs checked against Wowhead Classic (2026-11-08), see Docs/Buff-Detection.md.
-- After changes: run tools\sync-mockup-catalog.ps1.

local _, ns = ...
local L = ns.L

ns.catalogList = {
    -- Flasks
    { id = 13510, buff = 17626, dur = 7200, cat = "flask", stats = "hp", tier = 1, icon = "inv_potion_62", name = "Flask of the Titans", note = L["+1200 max. health"] },
    { id = 13511, buff = 17627, dur = 7200, cat = "flask", stats = "mana", tier = 1, icon = "inv_potion_97", name = "Flask of Distilled Wisdom", note = L["+2000 max. mana"] },
    { id = 13512, buff = 17628, dur = 7200, cat = "flask", stats = "spell", tier = 1, icon = "inv_potion_41", name = "Flask of Supreme Power", note = L["+150 spell damage"] },
    { id = 13513, buff = 17629, dur = 7200, cat = "flask", stats = "resist", tier = 1, icon = "inv_potion_48", name = "Flask of Chromatic Resistance", note = L["+25 all resistances"] },
    { id = 13506, buff = 17624, dur = 60, cat = "flask", stats = "other", tier = 1, icon = "inv_potion_26", name = "Flask of Petrification", note = L["Petrified: immune, no actions (1 min)"] },

    -- Elixirs: strength / attack power
    { id = 9206, buff = 11405, dur = 3600, cat = "elixir", stats = "ap", tier = 1, icon = "inv_potion_61", name = "Elixir of Giants", note = L["+25 Strength"] },
    { id = 13453, buff = 17537, dur = 3600, cat = "elixir", stats = "ap hp", tier = 2, icon = "inv_potion_40", name = "Elixir of Brute Force", note = L["+18 Strength, +18 Stamina"] },
    { id = 12820, buff = 17038, dur = 1200, cat = "elixir", stats = "ap", tier = 2, icon = "inv_potion_92", name = "Winterfall Firewater", note = L["+35 melee attack power"] },
    { id = 3391, buff = 3164, dur = 3600, cat = "elixir", stats = "ap", tier = 3, icon = "inv_potion_57", name = "Elixir of Ogre's Strength", note = L["+8 Strength"] },
    { id = 6662, buff = 8212, dur = 120, cat = "elixir", stats = "ap", tier = 3, icon = "inv_potion_10", name = "Elixir of Giant Growth", note = L["+8 Strength, enlarged"] },
    { id = 2454, buff = 2367, dur = 3600, cat = "elixir", stats = "ap", tier = 3, icon = "inv_potion_56", name = "Elixir of Lion's Strength", note = L["+4 Strength"] },
    { id = 9224, buff = 11406, dur = 300, cat = "elixir", stats = "ap", tier = 2, icon = "inv_potion_27", name = "Elixir of Demonslaying", note = L["+265 attack power vs. demons"] },
    -- Elixirs: agility
    { id = 13452, buff = 17538, dur = 3600, cat = "elixir", stats = "agi crit", tier = 1, icon = "inv_potion_32", name = "Elixir of the Mongoose", note = L["+25 Agility, +2% crit"] },
    { id = 9187, buff = 11334, dur = 3600, cat = "elixir", stats = "agi", tier = 2, icon = "inv_potion_94", name = "Elixir of Greater Agility", note = L["+25 Agility"] },
    { id = 8949, buff = 11328, dur = 3600, cat = "elixir", stats = "agi", tier = 3, icon = "inv_potion_93", name = "Elixir of Agility", note = L["+15 Agility"] },
    { id = 3390, buff = 3160, dur = 3600, cat = "elixir", stats = "agi", tier = 3, icon = "inv_potion_92", name = "Elixir of Lesser Agility", note = L["+8 Agility"] },
    { id = 2457, buff = 2374, dur = 3600, cat = "elixir", stats = "agi", tier = 3, icon = "inv_potion_91", name = "Elixir of Minor Agility", note = L["+4 Agility"] },
    -- Elixirs: health
    { id = 3825, buff = 3593, dur = 3600, cat = "elixir", stats = "hp", tier = 1, icon = "inv_potion_43", name = "Elixir of Fortitude", note = L["+120 max. health"] },
    { id = 2458, buff = 2378, dur = 3600, cat = "elixir", stats = "hp", tier = 3, icon = "inv_potion_42", name = "Elixir of Minor Fortitude", note = L["+27 max. health"] },
    -- Elixirs: health regeneration
    { id = 20004, buff = 24361, dur = 3600, cat = "elixir", stats = "regen", tier = 1, icon = "inv_potion_80", name = "Major Troll's Blood Potion", note = L["+20 health every 5 sec"] },
    { id = 3826, buff = 3223, dur = 3600, cat = "elixir", stats = "regen", tier = 2, icon = "inv_potion_79", name = "Mighty Troll's Blood Potion", note = L["+12 health every 5 sec"] },
    { id = 3388, buff = 3222, dur = 3600, cat = "elixir", stats = "regen", tier = 3, icon = "inv_potion_78", name = "Strong Troll's Blood Potion", note = L["+6 health every 5 sec"] },
    { id = 3382, buff = 3219, dur = 3600, cat = "elixir", stats = "regen", tier = 3, icon = "inv_potion_77", name = "Weak Troll's Blood Potion", note = L["+2 health every 5 sec"] },
    -- Elixirs: mana / intellect / MP5
    { id = 9179, buff = 11396, dur = 3600, cat = "elixir", stats = "mana", tier = 1, icon = "inv_potion_10", name = "Elixir of Greater Intellect", note = L["+25 Intellect"] },
    { id = 13447, buff = 17535, dur = 3600, cat = "elixir", stats = "mana spirit", tier = 2, icon = "inv_potion_29", name = "Elixir of the Sages", note = L["+18 Intellect, +18 Spirit"] },
    { id = 3383, buff = 3166, dur = 3600, cat = "elixir", stats = "mana", tier = 3, icon = "inv_potion_06", name = "Elixir of Wisdom", note = L["+6 Intellect"] },
    { id = 20007, buff = 24363, dur = 3600, cat = "elixir", stats = "mp5", tier = 1, icon = "inv_potion_45", name = "Mageblood Potion", note = L["+12 mana every 5 sec"] },
    -- Elixirs: spell damage
    { id = 13454, buff = 17539, dur = 3600, cat = "elixir", stats = "spell", tier = 1, icon = "inv_potion_25", name = "Greater Arcane Elixir", note = L["+35 spell damage"] },
    { id = 9155, buff = 11390, dur = 1800, cat = "elixir", stats = "spell", tier = 2, icon = "inv_potion_30", name = "Arcane Elixir", note = L["+20 spell damage"] },
    { id = 21546, buff = 26276, dur = 1800, cat = "elixir", stats = "spell", tier = 1, icon = "inv_potion_60", name = "Elixir of Greater Firepower", note = L["+40 fire damage"] },
    { id = 6373, buff = 7844, dur = 1800, cat = "elixir", stats = "spell", tier = 3, icon = "inv_potion_33", name = "Elixir of Firepower", note = L["+10 fire damage"] },
    { id = 17708, buff = 21920, dur = 1800, cat = "elixir", stats = "spell", tier = 1, icon = "inv_potion_03", name = "Elixir of Frost Power", note = L["+15 frost damage"] },
    { id = 9264, buff = 11474, dur = 1800, cat = "elixir", stats = "spell", tier = 1, icon = "inv_potion_46", name = "Elixir of Shadow Power", note = L["+40 shadow damage"] },
    -- Elixirs: armor / resistance
    { id = 13445, buff = 11348, dur = 3600, cat = "elixir", stats = "armor", tier = 1, icon = "inv_potion_66", name = "Elixir of Superior Defense", note = L["+450 armor"] },
    { id = 8951, buff = 11349, dur = 3600, cat = "elixir", stats = "armor", tier = 2, icon = "inv_potion_65", name = "Elixir of Greater Defense", note = L["+250 armor"] },
    { id = 3389, buff = 3220, dur = 3600, cat = "elixir", stats = "armor", tier = 3, icon = "inv_potion_64", name = "Elixir of Defense", note = L["+150 armor"] },
    { id = 5997, buff = 673, dur = 3600, cat = "elixir", stats = "armor", tier = 3, icon = "inv_potion_63", name = "Elixir of Minor Defense", note = L["+50 armor"] },
    { id = 9088, buff = 11371, dur = 1800, cat = "elixir", stats = "resist", tier = 1, icon = "inv_potion_28", name = "Gift of Arthas", note = L["+10 shadow resistance, may infect attackers"] },
    -- Elixirs: misc
    { id = 18294, buff = 22807, dur = 3600, cat = "elixir", stats = "other", tier = 1, icon = "inv_potion_05", name = "Elixir of Greater Water Breathing", note = L["Water breathing"] },
    { id = 5996, buff = 7178, dur = 1800, cat = "elixir", stats = "other", tier = 2, icon = "inv_potion_17", name = "Elixir of Water Breathing", note = L["Water breathing"] },
    { id = 8827, buff = 11319, dur = 1800, cat = "elixir", stats = "other", tier = 1, icon = "inv_potion_15", name = "Elixir of Water Walking", note = L["Water walking"] },
    { id = 9154, buff = 11389, dur = 3600, cat = "elixir", stats = "other", tier = 1, icon = "inv_potion_53", name = "Elixir of Detect Undead", note = L["Undead on the minimap"] },
    { id = 9233, buff = 11407, dur = 3600, cat = "elixir", stats = "other", tier = 1, icon = "inv_potion_53", name = "Elixir of Detect Demon", note = L["Demons on the minimap"] },
    { id = 3828, buff = 6512, dur = 600, cat = "elixir", stats = "other", tier = 1, icon = "inv_potion_01", name = "Elixir of Detect Lesser Invisibility", note = L["Detect lesser invisibility"] },
    { id = 10592, buff = 12608, dur = 600, cat = "elixir", stats = "other", tier = 1, icon = "inv_potion_36", name = "Catseye Elixir", note = L["Better stealth detection"] },

    -- Potions
    { id = 13455, buff = 17540, dur = 120, cat = "potion", stats = "armor", tier = 1, icon = "inv_potion_69", name = "Greater Stoneshield Potion", note = L["+2000 armor (2 min)"] },
    { id = 4623, buff = 4941, dur = 90, cat = "potion", stats = "armor", tier = 2, icon = "inv_potion_67", name = "Lesser Stoneshield Potion", note = L["+1000 armor (90 sec)"] },
    { id = 13442, buff = 17528, dur = 20, cat = "potion", stats = "ap", tier = 1, icon = "inv_potion_41", name = "Mighty Rage Potion", note = L["+60 Strength, 45-75 rage (20 sec)"] },
    { id = 5634, buff = 6615, dur = 30, cat = "potion", stats = "other", tier = 1, icon = "inv_potion_04", name = "Free Action Potion", note = L["Immune to stuns and slows"] },
    { id = 20008, buff = 24364, dur = 5, cat = "potion", stats = "other", tier = 1, icon = "inv_potion_07", name = "Living Action Potion", note = L["Immune, removes stuns/slows"] },
    { id = 3387, buff = 3169, dur = 6, cat = "potion", stats = "other", tier = 1, icon = "inv_potion_62", name = "Limited Invulnerability Potion", note = L["Immune to physical damage (6 sec)"] },
    { id = 9030, buff = 11359, dur = 30, cat = "potion", stats = "other", tier = 1, icon = "inv_potion_01", name = "Restorative Potion", note = L["Removes a harmful effect every 5 sec"] },
    { id = 9036, buff = 11364, dur = 180, cat = "potion", stats = "resist", tier = 1, icon = "inv_potion_16", name = "Magic Resistance Potion", note = L["+50 all resistances (3 min)"] },
    { id = 13458, buff = 17546, dur = 3600, cat = "elixir", stats = "resist", tier = 1, icon = "inv_potion_22", name = "Greater Nature Protection Potion", note = L["Absorbs 1950-3250 nature damage"] },
    { id = 6052, buff = 7254, dur = 3600, cat = "elixir", stats = "resist", tier = 2, icon = "inv_potion_06", name = "Nature Protection Potion", note = L["Absorbs 1350-2250 nature damage"] },
    { id = 13457, buff = 17543, dur = 3600, cat = "elixir", stats = "resist", tier = 1, icon = "inv_potion_24", name = "Greater Fire Protection Potion", note = L["Absorbs 1950-3250 fire damage"] },
    { id = 6049, buff = 7233, dur = 3600, cat = "elixir", stats = "resist", tier = 2, icon = "inv_potion_16", name = "Fire Protection Potion", note = L["Absorbs 975-1625 fire damage"] },
    { id = 13456, buff = 17544, dur = 3600, cat = "elixir", stats = "resist", tier = 1, icon = "inv_potion_20", name = "Greater Frost Protection Potion", note = L["Absorbs 1950-3250 frost damage"] },
    { id = 6050, buff = 7239, dur = 3600, cat = "elixir", stats = "resist", tier = 2, icon = "inv_potion_13", name = "Frost Protection Potion", note = L["Absorbs 1350-2250 frost damage"] },
    { id = 13459, buff = 17548, dur = 3600, cat = "elixir", stats = "resist", tier = 1, icon = "inv_potion_23", name = "Greater Shadow Protection Potion", note = L["Absorbs 1950-3250 shadow damage"] },
    { id = 6048, buff = 7242, dur = 3600, cat = "elixir", stats = "resist", tier = 2, icon = "inv_potion_44", name = "Shadow Protection Potion", note = L["Absorbs 675-1125 shadow damage"] },
    { id = 13461, buff = 17549, dur = 3600, cat = "elixir", stats = "resist", tier = 1, icon = "inv_potion_83", name = "Greater Arcane Protection Potion", note = L["Absorbs 1950-3250 arcane damage"] },
    { id = 6051, buff = 7245, dur = 3600, cat = "elixir", stats = "resist", tier = 2, icon = "inv_potion_09", name = "Holy Protection Potion", note = L["Absorbs 300-500 holy damage"] },
    { id = 2459, buff = 2379, dur = 15, cat = "potion", stats = "speed", tier = 1, icon = "inv_potion_95", name = "Swiftness Potion", note = L["+50% run speed (15 sec)"] },
    { id = 6372, buff = 7840, dur = 20, cat = "potion", stats = "speed", tier = 1, icon = "inv_potion_13", name = "Swim Speed Potion", note = L["+100% swim speed"] },
    { id = 9172, buff = 11392, dur = 18, cat = "potion", stats = "other", tier = 1, icon = "inv_potion_25", name = "Invisibility Potion", note = L["Invisibility (18 sec)"] },
    { id = 3823, buff = 3680, dur = 15, cat = "potion", stats = "other", tier = 2, icon = "inv_potion_18", name = "Lesser Invisibility Potion", note = L["Lesser invisibility (15 sec)"] },

    -- Food
    { id = 20452, buff = 24799, dur = 900, cat = "food", stats = "ap", tier = 1, icon = "inv_misc_food_64", name = "Smoked Desert Dumplings", note = L["Well Fed: +20 Strength"] },
    { id = 13810, buff = 18125, dur = 600, cat = "food", stats = "ap", tier = 2, icon = "inv_misc_food_41", name = "Blessed Sunfruit", note = L["+10 Strength"] },
    { id = 13928, buff = 18192, dur = 600, cat = "food", stats = "agi", tier = 1, icon = "inv_misc_fish_13", name = "Grilled Squid", note = L["+10 Agility"] },
    { id = 21023, buff = 25661, dur = 900, cat = "food", stats = "hp", tier = 1, icon = "inv_misc_food_65", name = "Dirge's Kickin' Chimaerok Chops", note = L["+25 Stamina"] },
    { id = 13934, buff = 18191, dur = 600, cat = "food", stats = "hp", tier = 2, icon = "inv_misc_food_47", name = "Mightfish Steak", note = L["+10 Stamina"] },
    { id = 13927, buff = 18191, dur = 600, cat = "food", stats = "hp", tier = 2, icon = "inv_misc_monsterhead_03", name = "Cooked Glossy Mightfish", note = L["+10 Stamina"] },
    { id = 11950, buff = 18191, dur = 600, cat = "food", stats = "hp", tier = 2, icon = "inv_misc_food_58", name = "Windblossom Berries", note = L["+10 Stamina (Felwood)"] },
    { id = 20516, buff = 24870, dur = 900, cat = "food", stats = "hp spirit", tier = 2, icon = "inv_misc_food_19", name = "Bobbing Apple", note = L["Stamina/Spirit by level (60: +15)"] },
    { id = 21254, buff = 24870, dur = 900, cat = "food", stats = "hp spirit", tier = 2, icon = "inv_misc_food_62", name = "Winter Veil Cookie", note = L["Stamina/Spirit by level (60: +15)"] },
    { id = 18045, buff = 19710, dur = 900, cat = "food", stats = "hp spirit", tier = 2, icon = "inv_misc_food_47", name = "Tender Wolf Steak", note = L["Well Fed: +12 Stamina/Spirit"] },
    { id = 12218, buff = 19710, dur = 900, cat = "food", stats = "hp spirit", tier = 2, icon = "inv_misc_food_06", name = "Monster Omelet", note = L["Well Fed: +12 Stamina/Spirit"] },
    { id = 17222, buff = 19710, dur = 900, cat = "food", stats = "hp spirit", tier = 2, icon = "inv_misc_food_66", name = "Spider Sausage", note = L["Well Fed: +12 Stamina/Spirit"] },
    { id = 12215, buff = 19710, dur = 900, cat = "food", stats = "hp spirit", tier = 2, icon = "inv_drink_19", name = "Heavy Kodo Stew", note = L["Well Fed: +12 Stamina/Spirit"] },
    { id = 12216, buff = 19710, dur = 900, cat = "food", stats = "hp spirit", tier = 2, icon = "inv_misc_food_48", name = "Spiced Chili Crab", note = L["Well Fed: +12 Stamina/Spirit"] },
    { id = 12210, buff = 19709, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_50", name = "Roast Raptor", note = L["Well Fed: +8 Stamina/Spirit"] },
    { id = 13851, buff = 19709, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_48", name = "Hot Wolf Ribs", note = L["Well Fed: +8 Stamina/Spirit"] },
    { id = 12211, buff = 19709, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_48", name = "Spiced Wolf Ribs", note = L["Well Fed: +8 Stamina/Spirit"] },
    { id = 12212, buff = 19709, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_drink_17", name = "Jungle Stew", note = L["Well Fed: +8 Stamina/Spirit"] },
    { id = 12214, buff = 19709, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_drink_19", name = "Mystery Stew", note = L["Well Fed: +8 Stamina/Spirit"] },
    { id = 3729, buff = 19709, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_bowl_01", name = "Soothing Turtle Bisque", note = L["Well Fed: +8 Stamina/Spirit"] },
    { id = 3728, buff = 19709, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_14", name = "Tasty Lion Steak", note = L["Well Fed: +8 Stamina/Spirit"] },
    { id = 12213, buff = 19709, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_49", name = "Carrion Surprise", note = L["Well Fed: +8 Stamina/Spirit"] },
    { id = 4457, buff = 19709, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_18", name = "Barbecued Buzzard Wing", note = L["Well Fed: +8 Stamina/Spirit"] },
    { id = 6038, buff = 19709, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_ammo_firetar", name = "Giant Clam Scorcho", note = L["Well Fed: +8 Stamina/Spirit"] },
    { id = 20074, buff = 19709, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_64", name = "Heavy Crocolisk Stew", note = L["Well Fed: +8 Stamina/Spirit"] },
    { id = 3727, buff = 19708, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_18", name = "Hot Lion Chops", note = L["Well Fed: +6 Stamina/Spirit"] },
    { id = 5479, buff = 19708, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_17", name = "Crispy Lizard Tail", note = L["Well Fed: +6 Stamina/Spirit"] },
    { id = 3666, buff = 19708, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_10", name = "Gooey Spider Cake", note = L["Well Fed: +6 Stamina/Spirit"] },
    { id = 3663, buff = 19708, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_bowl_01", name = "Murloc Fin Soup", note = L["Well Fed: +6 Stamina/Spirit"] },
    { id = 3726, buff = 19708, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_47", name = "Big Bear Steak", note = L["Well Fed: +6 Stamina/Spirit"] },
    { id = 3664, buff = 19708, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_bowl_01", name = "Crocolisk Gumbo", note = L["Well Fed: +6 Stamina/Spirit"] },
    { id = 1082, buff = 19708, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_bowl_01", name = "Redridge Goulash", note = L["Well Fed: +6 Stamina/Spirit"] },
    { id = 1017, buff = 19708, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_16", name = "Seasoned Wolf Kabob", note = L["Well Fed: +6 Stamina/Spirit"] },
    { id = 12209, buff = 19708, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_47", name = "Lean Wolf Steak", note = L["Well Fed: +6 Stamina/Spirit"] },
    { id = 3665, buff = 19708, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_egg_04", name = "Curiously Tasty Omelet", note = L["Well Fed: +6 Stamina/Spirit"] },
    { id = 5527, buff = 19708, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_shell_01", name = "Goblin Deviled Clams", note = L["Well Fed: +6 Stamina/Spirit"] },
    { id = 5480, buff = 19708, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_72", name = "Lean Venison", note = L["Well Fed: +6 Stamina/Spirit"] },
    { id = 3662, buff = 19706, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_47", name = "Crocolisk Steak", note = L["Well Fed: +4 Stamina/Spirit"] },
    { id = 724, buff = 19706, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_10", name = "Goretusk Liver Pie", note = L["Well Fed: +4 Stamina/Spirit"] },
    { id = 5525, buff = 19706, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_shell_02", name = "Boiled Clams", note = L["Well Fed: +4 Stamina/Spirit"] },
    { id = 3220, buff = 19706, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_49", name = "Blood Sausage", note = L["Well Fed: +4 Stamina/Spirit"] },
    { id = 2684, buff = 19706, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_65", name = "Coyote Steak", note = L["Well Fed: +4 Stamina/Spirit"] },
    { id = 5476, buff = 19706, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_fish_05", name = "Fillet of Frenzy", note = L["Well Fed: +4 Stamina/Spirit"] },
    { id = 5477, buff = 19706, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_bowl_01", name = "Strider Stew", note = L["Well Fed: +4 Stamina/Spirit"] },
    { id = 2683, buff = 19706, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_08", name = "Crab Cake", note = L["Well Fed: +4 Stamina/Spirit"] },
    { id = 2687, buff = 19706, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_48", name = "Dry Pork Ribs", note = L["Well Fed: +4 Stamina/Spirit"] },
    { id = 6888, buff = 19705, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_egg_03", name = "Herb Baked Egg", note = L["Well Fed: +2 Stamina/Spirit"] },
    { id = 2680, buff = 19705, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_65", name = "Spiced Wolf Meat", note = L["Well Fed: +2 Stamina/Spirit"] },
    { id = 2888, buff = 19705, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_48", name = "Beer Basted Boar Ribs", note = L["Well Fed: +2 Stamina/Spirit"] },
    { id = 17197, buff = 19705, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_62", name = "Gingerbread Cookie", note = L["Well Fed: +2 Stamina/Spirit"] },
    { id = 5472, buff = 19705, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_68", name = "Kaldorei Spider Kabob", note = L["Well Fed: +2 Stamina/Spirit"] },
    { id = 5474, buff = 19705, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_60", name = "Roasted Kodo Meat", note = L["Well Fed: +2 Stamina/Spirit"] },
    { id = 12224, buff = 19705, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_misc_food_46", name = "Crispy Bat Wing", note = L["Well Fed: +2 Stamina/Spirit"] },
    { id = 13932, buff = 18222, dur = 600, cat = "food", stats = "regen", tier = 1, icon = "inv_misc_fish_19", name = "Poached Sunscale Salmon", note = L["+6 health every 5 sec"] },
    { id = 18254, buff = 22730, dur = 600, cat = "food", stats = "mana", tier = 1, icon = "inv_misc_food_63", name = "Runn Tum Tuber Surprise", note = L["+10 Intellect"] },
    { id = 13931, buff = 18194, dur = 600, cat = "food", stats = "mp5", tier = 1, icon = "inv_drink_17", name = "Nightfin Soup", note = L["+8 mana every 5 sec"] },
    { id = 21217, buff = 25941, dur = 900, cat = "food", stats = "mp5", tier = 2, icon = "inv_misc_fish_21", name = "Sagefish Delight", note = L["+6 mana every 5 sec"] },
    { id = 21072, buff = 25694, dur = 900, cat = "food", stats = "mp5", tier = 3, icon = "inv_misc_fish_20", name = "Smoked Sagefish", note = L["+3 mana every 5 sec"] },
    { id = 22238, buff = 27721, dur = 3600, cat = "food", stats = "spell", tier = 1, icon = "inv_valentineschocolate02", name = "Very Berry Cream", note = L["+23 spell damage"] },
    { id = 22239, buff = 27722, dur = 3600, cat = "food", stats = "spell", tier = 1, icon = "inv_valentineschocolate03", name = "Sweet Surprise", note = L["+44 healing"] },
    { id = 13929, buff = 18193, dur = 600, cat = "food", stats = "spirit", tier = 1, icon = "inv_misc_fish_03", name = "Hot Smoked Bass", note = L["+10 Spirit"] },
    { id = 13813, buff = 18141, dur = 600, cat = "food", stats = "spirit", tier = 1, icon = "inv_drink_16", name = "Blessed Sunfruit Juice", note = L["+10 Spirit"] },
    { id = 12217, buff = 15852, dur = 600, cat = "other", stats = "other", tier = 1, icon = "inv_drink_17", name = "Dragonbreath Chili", note = L["Fire breath proc in melee"] },
    { id = 22237, buff = 27723, dur = 3600, cat = "food", stats = "other", tier = 1, icon = "inv_valentineschocolate04", name = "Dark Desire", note = L["+2% hit chance"] },
    { id = 22236, buff = 27720, dur = 3600, cat = "food", stats = "other", tier = 1, icon = "inv_valentineschocolate01", name = "Buttermilk Delight", note = L["+13 defense"] },

    -- Alcohol (rum and grog overwrite each other)
    { id = 21151, buff = 25804, dur = 900, cat = "food", stats = "hp", tier = 1, icon = "inv_drink_04", name = "Rumsey Rum Black Label", note = L["+15 Stamina"] },
    { id = 18269, buff = 22789, dur = 900, cat = "food", stats = "hp", tier = 2, icon = "inv_drink_03", name = "Gordok Green Grog", note = L["+10 Stamina"] },
    { id = 21114, buff = 25722, dur = 900, cat = "food", stats = "hp", tier = 2, icon = "inv_drink_04", name = "Rumsey Rum Dark", note = L["+10 Stamina"] },
    { id = 20709, buff = 25037, dur = 900, cat = "food", stats = "hp", tier = 3, icon = "inv_drink_08", name = "Rumsey Rum Light", note = L["+5 Stamina"] },
    { id = 17198, buff = 19705, dur = 900, cat = "food", stats = "hp spirit", tier = 3, icon = "inv_drink_04", name = "Egg Nog", note = L["Well Fed: +2 Stamina/Spirit"] },
    { id = 5342, buff = 6114, dur = 300, cat = "food", stats = "mana", tier = 3, icon = "inv_drink_04", name = "Raptor Punch", note = L["+4 Intellect, -5 Stamina"] },
    { id = 18284, buff = 22790, dur = 900, cat = "food", stats = "spirit", tier = 1, icon = "inv_drink_05", name = "Kreeg's Stout Beatdown", note = L["+25 Spirit, -5 Intellect"] },

    -- Juju
    { id = 12460, buff = 16329, dur = 600, cat = "elixir", stats = "ap", tier = 1, icon = "inv_misc_monsterscales_07", name = "Juju Might", note = L["+40 attack power"] },
    { id = 12451, buff = 16323, dur = 1800, cat = "elixir", stats = "ap", tier = 1, icon = "inv_misc_monsterscales_11", name = "Juju Power", note = L["+30 Strength"] },
    { id = 12450, buff = 16322, dur = 20, cat = "elixir", stats = "other", tier = 1, icon = "inv_misc_monsterscales_17", name = "Juju Flurry", note = L["+3% attack speed (20 sec)"] },
    { id = 12455, buff = 16326, dur = 600, cat = "elixir", stats = "resist", tier = 1, icon = "inv_misc_monsterscales_15", name = "Juju Ember", note = L["+15 fire resistance"] },
    { id = 12457, buff = 16325, dur = 600, cat = "elixir", stats = "resist", tier = 1, icon = "inv_misc_monsterscales_09", name = "Juju Chill", note = L["+15 frost resistance"] },
    { id = 12458, buff = 16327, dur = 1800, cat = "elixir", stats = "mana", tier = 1, icon = "inv_misc_monsterscales_13", name = "Juju Guile", note = L["+30 Intellect"] },
    { id = 12459, buff = 16321, dur = 10, cat = "elixir", stats = "other", tier = 1, icon = "inv_misc_monsterscales_17", name = "Juju Escape", note = L["+5% dodge (10 sec, rogues only per tooltip)"] },

    -- Zanza (only one at a time)
    { id = 20079, buff = 24382, dur = 7200, cat = "flask", stats = "hp spirit", tier = 1, icon = "inv_potion_30", name = "Spirit of Zanza", note = L["+50 Stamina, +50 Spirit"] },
    { id = 20081, buff = 24383, dur = 7200, cat = "flask", stats = "speed", tier = 1, icon = "inv_potion_31", name = "Swiftness of Zanza", note = L["+20% run speed"] },
    { id = 20080, buff = 24417, dur = 7200, cat = "flask", stats = "other", tier = 1, icon = "inv_potion_29", name = "Sheen of Zanza", note = L["3% spell reflection"] },

    -- Scrolls
    { id = 10310, buff = 12179, dur = 1800, cat = "other", stats = "ap", tier = 1, icon = "inv_scroll_02", name = "Scroll of Strength IV", note = L["+17 Strength"] },
    { id = 4426, buff = 8120, dur = 1800, cat = "other", stats = "ap", tier = 2, icon = "inv_scroll_02", name = "Scroll of Strength III", note = L["+13 Strength"] },
    { id = 2289, buff = 8119, dur = 1800, cat = "other", stats = "ap", tier = 3, icon = "inv_scroll_02", name = "Scroll of Strength II", note = L["+9 Strength"] },
    { id = 954, buff = 8118, dur = 1800, cat = "other", stats = "ap", tier = 3, icon = "inv_scroll_02", name = "Scroll of Strength", note = L["+5 Strength"] },
    { id = 10309, buff = 12174, dur = 1800, cat = "other", stats = "agi", tier = 1, icon = "inv_scroll_02", name = "Scroll of Agility IV", note = L["+17 Agility"] },
    { id = 4425, buff = 8117, dur = 1800, cat = "other", stats = "agi", tier = 2, icon = "inv_scroll_02", name = "Scroll of Agility III", note = L["+13 Agility"] },
    { id = 1477, buff = 8116, dur = 1800, cat = "other", stats = "agi", tier = 3, icon = "inv_scroll_02", name = "Scroll of Agility II", note = L["+9 Agility"] },
    { id = 3012, buff = 8115, dur = 1800, cat = "other", stats = "agi", tier = 3, icon = "inv_scroll_02", name = "Scroll of Agility", note = L["+5 Agility"] },
    { id = 10307, buff = 12178, dur = 1800, cat = "other", stats = "hp", tier = 1, icon = "inv_scroll_07", name = "Scroll of Stamina IV", note = L["+16 Stamina"] },
    { id = 4422, buff = 8101, dur = 1800, cat = "other", stats = "hp", tier = 2, icon = "inv_scroll_07", name = "Scroll of Stamina III", note = L["+12 Stamina"] },
    { id = 1711, buff = 8100, dur = 1800, cat = "other", stats = "hp", tier = 3, icon = "inv_scroll_07", name = "Scroll of Stamina II", note = L["+8 Stamina"] },
    { id = 1180, buff = 8099, dur = 1800, cat = "other", stats = "hp", tier = 3, icon = "inv_scroll_07", name = "Scroll of Stamina", note = L["+4 Stamina"] },
    { id = 10308, buff = 12176, dur = 1800, cat = "other", stats = "mana", tier = 1, icon = "inv_scroll_01", name = "Scroll of Intellect IV", note = L["+16 Intellect"] },
    { id = 4419, buff = 8098, dur = 1800, cat = "other", stats = "mana", tier = 2, icon = "inv_scroll_01", name = "Scroll of Intellect III", note = L["+12 Intellect"] },
    { id = 2290, buff = 8097, dur = 1800, cat = "other", stats = "mana", tier = 3, icon = "inv_scroll_01", name = "Scroll of Intellect II", note = L["+8 Intellect"] },
    { id = 955, buff = 8096, dur = 1800, cat = "other", stats = "mana", tier = 3, icon = "inv_scroll_01", name = "Scroll of Intellect", note = L["+4 Intellect"] },
    { id = 10306, buff = 12177, dur = 1800, cat = "other", stats = "spirit", tier = 1, icon = "inv_scroll_01", name = "Scroll of Spirit IV", note = L["+15 Spirit"] },
    { id = 4424, buff = 8114, dur = 1800, cat = "other", stats = "spirit", tier = 2, icon = "inv_scroll_01", name = "Scroll of Spirit III", note = L["+11 Spirit"] },
    { id = 1712, buff = 8113, dur = 1800, cat = "other", stats = "spirit", tier = 3, icon = "inv_scroll_01", name = "Scroll of Spirit II", note = L["+7 Spirit"] },
    { id = 1181, buff = 8112, dur = 1800, cat = "other", stats = "spirit", tier = 3, icon = "inv_scroll_01", name = "Scroll of Spirit", note = L["+3 Spirit"] },
    { id = 10305, buff = 12175, dur = 1800, cat = "other", stats = "armor", tier = 1, icon = "inv_scroll_07", name = "Scroll of Protection IV", note = L["+240 armor"] },
    { id = 4421, buff = 8095, dur = 1800, cat = "other", stats = "armor", tier = 2, icon = "inv_scroll_07", name = "Scroll of Protection III", note = L["+180 armor"] },
    { id = 1478, buff = 8094, dur = 1800, cat = "other", stats = "armor", tier = 3, icon = "inv_scroll_07", name = "Scroll of Protection II", note = L["+120 armor"] },
    { id = 3013, buff = 8091, dur = 1800, cat = "other", stats = "armor", tier = 3, icon = "inv_scroll_07", name = "Scroll of Protection", note = L["+60 armor"] },

    -- Misc (Blasted Lands, Silithus crystals, etc.)
    { id = 8410, buff = 10667, dur = 3600, cat = "other", stats = "ap", tier = 1, icon = "inv_stone_15", name = "R.O.I.D.S.", note = L["+25 Strength (aura: Rage of Ages)"] },
    { id = 8412, buff = 10669, dur = 3600, cat = "other", stats = "agi", tier = 1, icon = "inv_misc_dust_02", name = "Ground Scorpok Assay", note = L["+25 Agility"] },
    { id = 8411, buff = 10668, dur = 3600, cat = "other", stats = "hp", tier = 1, icon = "inv_drink_12", name = "Lung Juice Cocktail", note = L["+25 Stamina"] },
    { id = 8423, buff = 10692, dur = 3600, cat = "other", stats = "mana", tier = 1, icon = "inv_potion_32", name = "Cerebral Cortex Compound", note = L["+25 Intellect"] },
    { id = 8424, buff = 10693, dur = 3600, cat = "other", stats = "spirit", tier = 1, icon = "inv_misc_food_30", name = "Gizzard Gum", note = L["+25 Spirit"] },
    { id = 11564, buff = 15233, dur = 1800, cat = "other", stats = "armor", tier = 1, icon = "inv_misc_gem_ruby_02", name = "Crystal Ward", note = L["+200 armor"] },
    { id = 11563, buff = 15231, dur = 1800, cat = "other", stats = "spirit", tier = 1, icon = "inv_misc_gem_crystal_02", name = "Crystal Force", note = L["+30 Spirit"] },
    { id = 11567, buff = 15279, dur = 600, cat = "other", stats = "other", tier = 1, icon = "inv_misc_gem_stone_01", name = "Crystal Spire", note = L["12 nature damage to attackers"] },
    { id = 11562, buff = 15229, dur = 15, cat = "other", stats = "regen", tier = 1, icon = "inv_misc_gem_diamond_02", name = "Crystal Restore", note = L["Heals 670 over 15 sec"] },
    { id = 5206, buff = 5665, dur = 600, cat = "other", stats = "ap", tier = 3, icon = "inv_misc_herb_07", name = "Bogling Root", note = L["+1 melee damage"] },
    { id = 8956, buff = 11350, dur = 15, cat = "other", stats = "other", tier = 1, icon = "inv_potion_11", name = "Oil of Immolation", note = L["Fire damage around you (15 sec)"] },
}

------------------------------------------------------------------------
-- Weapon enchants (2026-11-09, Docs/Plan-WeaponEnchants.md): stones, oils, poisons. No aura: detected per
-- hand with GetWeaponEnchantInfo() by the enchant ID (enchant). Items, icons and durations checked against
-- Wowhead Classic; enchant IDs from the NovaRaidCompanion data for Classic (2629/2684/2685 also used by
-- CharacterStatsClassic). Same fields as the catalog, but enchant instead of buff; not read by the tools.
-- stats: primary stat for the class filter ("poison" = rogues only).
------------------------------------------------------------------------
ns.WEAPON_ITEMS = {
    { id = 18262, enchant = 2506, dur = 1800, cat = "weapon", stats = "crit ap", tier = 1, icon = "inv_stone_02", name = "Elemental Sharpening Stone", note = L["+2% melee crit (weapon)"] },
    { id = 23122, enchant = 2684, dur = 3600, cat = "weapon", stats = "ap", tier = 1, icon = "inv_stone_sharpeningstone_02", name = "Consecrated Sharpening Stone", note = L["+100 AP vs. undead (weapon)"] },
    { id = 12404, enchant = 1643, dur = 1800, cat = "weapon", stats = "ap", tier = 1, icon = "inv_stone_sharpeningstone_05", name = "Dense Sharpening Stone", note = L["+8 damage, bladed weapon"] },
    { id = 7964, enchant = 483, dur = 1800, cat = "weapon", stats = "ap", tier = 2, icon = "inv_stone_sharpeningstone_04", name = "Solid Sharpening Stone", note = L["+6 damage, bladed weapon"] },
    { id = 2871, enchant = 14, dur = 1800, cat = "weapon", stats = "ap", tier = 3, icon = "inv_stone_sharpeningstone_03", name = "Heavy Sharpening Stone", note = L["+4 damage, bladed weapon"] },
    { id = 12643, enchant = 1703, dur = 1800, cat = "weapon", stats = "ap", tier = 1, icon = "inv_stone_weightstone_05", name = "Dense Weightstone", note = L["+8 damage, blunt weapon"] },
    { id = 7965, enchant = 484, dur = 1800, cat = "weapon", stats = "ap", tier = 2, icon = "inv_stone_weightstone_04", name = "Solid Weightstone", note = L["+6 damage, blunt weapon"] },
    { id = 3241, enchant = 21, dur = 1800, cat = "weapon", stats = "ap", tier = 3, icon = "inv_stone_weightstone_03", name = "Heavy Weightstone", note = L["+4 damage, blunt weapon"] },
    { id = 20749, enchant = 2628, dur = 1800, cat = "weapon", stats = "spell", tier = 1, icon = "inv_potion_105", name = "Brilliant Wizard Oil", note = L["+36 spell damage, +1% spell crit"] },
    { id = 20748, enchant = 2629, dur = 1800, cat = "weapon", stats = "mp5 heal", tier = 1, icon = "inv_potion_100", name = "Brilliant Mana Oil", note = L["12 MP5, +25 healing"] },
    { id = 23123, enchant = 2685, dur = 3600, cat = "weapon", stats = "spell", tier = 1, icon = "inv_potion_26", name = "Blessed Wizard Oil", note = L["+60 spell damage vs. undead"] },
    { id = 20750, enchant = 2627, dur = 1800, cat = "weapon", stats = "spell", tier = 2, icon = "inv_potion_104", name = "Wizard Oil", note = L["+24 spell damage"] },
    { id = 20747, enchant = 2625, dur = 1800, cat = "weapon", stats = "mp5", tier = 2, icon = "inv_potion_99", name = "Lesser Mana Oil", note = L["8 MP5"] },
    { id = 3824, enchant = 25, dur = 1800, cat = "weapon", stats = "other", tier = 2, icon = "inv_potion_23", name = "Shadow Oil", note = L["15% chance: Shadow Bolt (melee)"] },
    { id = 3829, enchant = 26, dur = 1800, cat = "weapon", stats = "other", tier = 2, icon = "inv_potion_20", name = "Frost Oil", note = L["10% chance: Frostbolt (melee)"] },
    { id = 8928, enchant = 625, dur = 1800, cat = "weapon", stats = "poison", tier = 1, icon = "ability_poisons", name = "Instant Poison VI", note = L["Poison: 112-148 nature damage"] },
    { id = 20844, enchant = 2630, dur = 1800, cat = "weapon", stats = "poison", tier = 1, icon = "ability_rogue_dualweild", name = "Deadly Poison V", note = L["Poison: 136 nature damage over 12 sec"] },
    { id = 3776, enchant = 603, dur = 1800, cat = "weapon", stats = "poison", tier = 1, icon = "inv_potion_19", name = "Crippling Poison II", note = L["Poison: -70% movement speed"] },
    { id = 9186, enchant = 643, dur = 1800, cat = "weapon", stats = "poison", tier = 1, icon = "spell_nature_nullifydisease", name = "Mind-numbing Poison III", note = L["Poison: +60% casting time"] },
    { id = 10922, enchant = 706, dur = 1800, cat = "weapon", stats = "poison", tier = 1, icon = "ability_poisonsting", name = "Wound Poison IV", note = L["Poison: -135 healing"] },
}

-- Windfury Totem: weapon enchant on the main hand (all ranks, NovaRaidCompanion). Has priority over a stone.
ns.WINDFURY_ENCHANTS = { [563] = true, [564] = true, [1783] = true, [2638] = true, [2639] = true }
ns.WINDFURY_ICON = "Interface\\Icons\\Spell_Nature_Windfury"

-- Names of other weapon enchants for "Sonstige" (not in the catalog): shaman weapons, lower ranks.
-- Everything else shows as "Waffen-Verzauberung" with the icon of the weapon.
ns.WEAPON_ENCHANT_NAMES = {
    [283] = "Windfury Weapon", [284] = "Windfury Weapon", [525] = "Windfury Weapon", [1669] = "Windfury Weapon",
    [15] = "Flametongue Weapon", [4] = "Flametongue Weapon", [3] = "Flametongue Weapon", [523] = "Flametongue Weapon",
    [1665] = "Flametongue Weapon", [1666] = "Flametongue Weapon",
    [2] = "Frostbrand Weapon", [12] = "Frostbrand Weapon", [524] = "Frostbrand Weapon", [1667] = "Frostbrand Weapon",
    [1668] = "Frostbrand Weapon",
    [29] = "Rockbiter Weapon", [6] = "Rockbiter Weapon", [1] = "Rockbiter Weapon", [503] = "Rockbiter Weapon",
    [1663] = "Rockbiter Weapon", [683] = "Rockbiter Weapon", [1664] = "Rockbiter Weapon",
    [13] = "Coarse Sharpening Stone", [40] = "Rough Sharpening Stone", [20] = "Coarse Weightstone", [19] = "Rough Weightstone",
    [323] = "Instant Poison", [324] = "Instant Poison II", [325] = "Instant Poison III", [623] = "Instant Poison IV",
    [624] = "Instant Poison V", [7] = "Deadly Poison", [8] = "Deadly Poison II", [626] = "Deadly Poison III",
    [627] = "Deadly Poison IV", [22] = "Crippling Poison", [35] = "Mind-numbing Poison", [23] = "Mind-numbing Poison II",
    [703] = "Wound Poison", [704] = "Wound Poison II", [705] = "Wound Poison III",
    [2623] = "Minor Wizard Oil", [2624] = "Minor Mana Oil", [2626] = "Lesser Wizard Oil",
}

------------------------------------------------------------------------
-- Tiers and class filter
------------------------------------------------------------------------

-- Catalog lists (one dropdown in the options): "Alle" = whole catalog, "Raid" = ns.RAID_ITEMS for
-- every class, "Raid: <class>" = ns.RAID_ITEMS minus what that class cannot use (ns.CLASS_HIDE).
-- The options start on "Raid: <own class>". Filled below, after ns.CLASS_ORDER.
ns.CATALOG_LISTS = {}

-- Hand-picked raid list: buffs taken before a pull that make the character stronger or more durable
-- (stats, health, regeneration, armor, resistances), plus the raid combat potions (since 2026-11-09, user:
-- the former 10 minute rule left "Tränke" empty although the row "Kampf" needs them). No scrolls, detection,
-- water breathing/walking, speed, invisibility or weak variants. tools\sync-mockup-catalog.ps1
-- copies the IDs between the markers into the mockup. Rule: no item that is strictly weaker than another
-- one here and shares its buff slot (e.g. Crystal Ward vs. Superior Defense); cheap alternatives the user
-- wants are the exception (Blessed Sunfruit, Elixir of Greater Agility). Equivalent items (same buff and
-- value, e.g. Monster Omelet = Tender Wolf Steak) are always listed together.
-- RAID-START
ns.RAID_ITEMS = {
    -- Flasks
    [13510] = true, -- Flask of the Titans
    [13511] = true, -- Flask of Distilled Wisdom
    [13512] = true, -- Flask of Supreme Power
    [13513] = true, -- Flask of Chromatic Resistance
    -- Elixirs
    [9206] = true,  -- Elixir of Giants
    [13453] = true, -- Elixir of Brute Force
    [12820] = true, -- Winterfall Firewater
    [13452] = true, -- Elixir of the Mongoose
    [9187] = true,  -- Elixir of Greater Agility (cheap alternative to Mongoose)
    [3825] = true,  -- Elixir of Fortitude
    [20004] = true, -- Major Troll's Blood Potion
    [13445] = true, -- Elixir of Superior Defense
    [9088] = true,  -- Gift of Arthas
    [9179] = true,  -- Elixir of Greater Intellect
    [13447] = true, -- Elixir of the Sages
    [20007] = true, -- Mageblood Potion
    [13454] = true, -- Greater Arcane Elixir
    [21546] = true, -- Elixir of Greater Firepower
    [17708] = true, -- Elixir of Frost Power
    [9264] = true,  -- Elixir of Shadow Power
    -- Potions
    [13458] = true, -- Greater Nature Protection Potion
    [13457] = true, -- Greater Fire Protection Potion
    [13456] = true, -- Greater Frost Protection Potion
    [13459] = true, -- Greater Shadow Protection Potion
    [13461] = true, -- Greater Arcane Protection Potion
    -- combat potions (user 2026-11-09: the 10 minute rule made no sense, the row "Kampf" is filled from here)
    [13455] = true, -- Greater Stoneshield Potion
    [13442] = true, -- Mighty Rage Potion
    [5634] = true,  -- Free Action Potion
    [20008] = true, -- Living Action Potion
    [3387] = true,  -- Limited Invulnerability Potion
    [9030] = true,  -- Restorative Potion
    [9036] = true,  -- Magic Resistance Potion
    -- Food
    [20452] = true, -- Smoked Desert Dumplings
    [13810] = true, -- Blessed Sunfruit (cheap alternative to the dumplings)
    [13928] = true, -- Grilled Squid
    [21023] = true, -- Dirge's Kickin' Chimaerok Chops
    [18045] = true, -- Tender Wolf Steak
    [12218] = true, -- Monster Omelet (same buff as Tender Wolf Steak)
    [17222] = true, -- Spider Sausage (same buff)
    [12215] = true, -- Heavy Kodo Stew (same buff)
    [12216] = true, -- Spiced Chili Crab (same buff)
    [18254] = true, -- Runn Tum Tuber Surprise
    [13931] = true, -- Nightfin Soup
    [12217] = true, -- Dragonbreath Chili
    [22237] = true, -- Dark Desire
    [22236] = true, -- Buttermilk Delight
    [22238] = true, -- Very Berry Cream
    [22239] = true, -- Sweet Surprise
    -- Alcohol
    [21151] = true, -- Rumsey Rum Black Label
    [18284] = true, -- Kreeg's Stout Beatdown
    -- Juju
    [12451] = true, -- Juju Power
    [12460] = true, -- Juju Might
    [12455] = true, -- Juju Ember
    [12457] = true, -- Juju Chill
    [12458] = true, -- Juju Guile
    -- Zanza
    [20079] = true, -- Spirit of Zanza
    -- Misc
    [8410] = true,  -- R.O.I.D.S.
    [8412] = true,  -- Ground Scorpok Assay
    [8411] = true,  -- Lung Juice Cocktail
    [8423] = true,  -- Cerebral Cortex Compound
    [8424] = true,  -- Gizzard Gum
    -- Weapon enchants (2026-11-09)
    [18262] = true, -- Elemental Sharpening Stone
    [12404] = true, -- Dense Sharpening Stone
    [12643] = true, -- Dense Weightstone
    [23122] = true, -- Consecrated Sharpening Stone
    [20749] = true, -- Brilliant Wizard Oil
    [20748] = true, -- Brilliant Mana Oil
    [23123] = true, -- Blessed Wizard Oil
    [8928] = true,  -- Instant Poison VI
    [20844] = true, -- Deadly Poison V
}
-- RAID-END

-- Buff places: items with the same place overwrite each other (Docs/Buff-Detection.md, "Buffs, die sich
-- gegenseitig überschreiben"). Only used for the yellow hint in the options when the alternatives of one
-- icon do not share a place; nothing is forbidden. Not listed: type "flask" = "flask", type "food" =
-- "food" (Well Fed), everything else its own place (ns.BuffPlace in Core.lua).
ns.BUFF_PLACE = {
    -- confirmed by the user (2026-11-08)
    [13452] = "agi", [9187] = "agi",           -- Mongoose, Greater Agility
    [9206] = "str", [12451] = "str",           -- Elixir of Giants, Juju Power
    -- community rules, not yet confirmed in game
    [8949] = "agi", [3390] = "agi", [2457] = "agi",
    [12460] = "ap", [12820] = "ap",            -- Juju Might, Winterfall Firewater
    [20079] = "zanza", [20081] = "zanza", [20080] = "zanza",
    [3825] = "fort", [2458] = "fort",
    [13445] = "def", [8951] = "def", [3389] = "def", [5997] = "def",
    [20004] = "troll", [3826] = "troll", [3388] = "troll", [3382] = "troll",
    [21151] = "rum", [21114] = "rum", [20709] = "rum", [18269] = "rum", -- Rumsey Rum, Gordok Green Grog
    [13457] = "fireprot", [6049] = "fireprot",
    [13456] = "frostprot", [6050] = "frostprot",
    [13458] = "natureprot", [6052] = "natureprot",
    [13459] = "shadowprot", [6048] = "shadowprot",
    [13455] = "stoneshield", [4623] = "stoneshield",
    [13442] = "rage", [5633] = "rage",         -- Great Rage Potion: instant rage, no buff (not in the catalog)
}

-- Default alternatives (user, 2026-11-08): an item listed here becomes a slot with these alternatives
-- when it is added to a row (catalog, bags) or comes from a row template. Order = fallback order.
-- Deliberately without alternatives: Flasks, Zanza, Blasted Lands buffs, Limited Invulnerability Potion,
-- Free Action Potion. Greater Arcane Protection has no smaller Arcane Protection Potion in Classic Era.
ns.DEFAULT_ALTS = {
    -- main elixirs (user 2026-11-25): the strongest scroll (rank IV) as the second alternative, the first one where
    -- the elixir had none
    [13452] = { 9187, 10309 },  -- Elixir of the Mongoose: Elixir of Greater Agility, Scroll of Agility IV
    [9206] = { 10310 },         -- Elixir of Giants: Scroll of Strength IV
    [3825] = { 10307 },         -- Elixir of Fortitude: Scroll of Stamina IV
    [9179] = { 10308 },         -- Elixir of Greater Intellect: Scroll of Intellect IV
    [13447] = { 10306 },        -- Elixir of the Sages: Scroll of Spirit IV
    [12451] = { 9206, 10310 },  -- Juju Power: Elixir of Giants, Scroll of Strength IV (user 2026-11-25)
    [12460] = { 12820 },        -- Juju Might: Winterfall Firewater
    -- Smoked Desert Dumplings: Blessed Sunfruit, Grilled Squid (agility, on purpose; user 2026-11-10), then
    -- Dirge's with its alternatives (user 2026-11-11: one food icon that covers everything relevant)
    [20452] = { 13810, 13928, 21023, 12215, 12218, 12216, 17222, 18045 },
    -- Dirge's Kickin' Chimaerok Chops: all "+12 Stamina/Spirit" Well Fed foods, alphabetical
    [21023] = { 12215, 12218, 12216, 17222, 18045 }, -- Heavy Kodo Stew, Monster Omelet, Spiced Chili Crab,
                                                     -- Spider Sausage, Tender Wolf Steak
    [21151] = { 18269 },        -- Rumsey Rum Black Label: Gordok Green Grog
    [13445] = { 8951, 10305 },  -- Elixir of Superior Defense: Elixir of Greater Defense, Scroll of Protection IV
    [13457] = { 6049 },         -- Greater Fire Protection Potion: Fire Protection Potion
    [13456] = { 6050 },         -- Greater Frost Protection Potion: Frost Protection Potion
    [13458] = { 6052 },         -- Greater Nature Protection Potion: Nature Protection Potion
    [13459] = { 6048 },         -- Greater Shadow Protection Potion: Shadow Protection Potion
    [13455] = { 4623 },         -- Greater Stoneshield Potion: Lesser Stoneshield Potion
    [13442] = { 5633 },         -- Mighty Rage Potion: Great Rage Potion (instant rage, no buff)
    [20004] = { 3388 },         -- Major Troll's Blood Potion: Strong Troll's Blood Potion
    [18262] = { 12404, 12643 }, -- Elemental Sharpening Stone: Dense Sharpening Stone, Dense Weightstone (blunt; user 2026-11-10)
    -- buffs (2026-11-15, user): mage armors, only one can be up; dragged into a row they come as one slot
    [-22783] = { -10220 },      -- Mage Armor: Ice Armor
    [-10220] = { -22783 },      -- Ice Armor: Mage Armor
}

-- Class (English token from UnitClass) -> hidden primary stats in "Raid: <class>"
-- "poison" (rogue poisons, 2026-11-09) is hidden for every class but the rogue
local MELEE = { mana = true, mp5 = true, spell = true, spirit = true, poison = true }
local CASTER = { ap = true, agi = true, poison = true }
ns.CLASS_HIDE = {
    WARRIOR = MELEE, ROGUE = { mana = true, mp5 = true, spell = true, spirit = true },
    HUNTER = { spell = true, spirit = true, poison = true },
    PALADIN = { poison = true }, DRUID = { poison = true }, SHAMAN = { poison = true },
    MAGE = CASTER, WARLOCK = CASTER, PRIEST = CASTER,
}

-- Order in the dropdown; names fall back to this table (localized) if the client table is missing
ns.CLASS_ORDER = { "WARRIOR", "ROGUE", "HUNTER", "PALADIN", "DRUID", "SHAMAN", "MAGE", "WARLOCK", "PRIEST" }
local CLASS_FALLBACK = {
    WARRIOR = L["Warrior"], ROGUE = L["Rogue"], HUNTER = L["Hunter"], PALADIN = L["Paladin"], DRUID = L["Druid"],
    SHAMAN = L["Shaman"], MAGE = L["Mage"], WARLOCK = L["Warlock"], PRIEST = L["Priest"],
}
-- The client's class names fit only when the chosen language is the client's (2026-11-14: own language choice);
-- otherwise the English fallback, translated (CLASS_FALLBACK holds English keys, see Locale.lua)
function ns.ClassLabel(token)
    local client = ns.CLIENT_LOCALE == "enGB" and "enUS" or ns.CLIENT_LOCALE
    if (ns.activeLocale or "enUS") == client and LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token] then
        return LOCALIZED_CLASS_NAMES_MALE[token]
    end
    return CLASS_FALLBACK[token] and L[CLASS_FALLBACK[token]] or token
end

ns.CATALOG_LISTS[1] = { key = "all", label = L["All"] }
ns.CATALOG_LISTS[2] = { key = "raid", label = L["Raid"], raid = true }
for _, token in ipairs(ns.CLASS_ORDER) do
    ns.CATALOG_LISTS[#ns.CATALOG_LISTS + 1] =
        -- label built when shown (ns.Text): the language is not known while this file loads
        { key = "raid:" .. token, label = function() return L["Raid: %s"]:format(ns.ClassLabel(token)) end, raid = true, class = token }
end


------------------------------------------------------------------------
-- Preprocessing
------------------------------------------------------------------------

-- Weapon items join the catalog (no buffs: detected per hand, see Auras.lua); enchant ID -> item
ns.enchantItem = {}
for _, e in ipairs(ns.WEAPON_ITEMS) do
    ns.catalogList[#ns.catalogList + 1] = e
    ns.enchantItem[e.enchant] = e.id
end

-- Lookup itemID -> entry; buffs list for Auras.lua; stats as a set.
ns.catalog = {}
for _, e in ipairs(ns.catalogList) do
    e.buffs = { e.buff } -- weapon items: empty (no buff)
    e.statSet = {}
    for s in e.stats:gmatch("%S+") do -- not %a+: that would cut "mp5" to "mp"
        e.statSet[s] = true
        e.primary = e.primary or s
    end
    ns.catalog[e.id] = e
end
