"use strict";
/* RaidKit Buffs mockup: catalog, buffs, filters, templates, profile defaults (= Data.lua).
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

/* ===================== Catalog (= Data.lua) ===================== */
/*CATALOG-START*/
// generated from Data.lua (tools\sync-mockup-catalog.ps1)
const CATALOG = [
  { id: 13510, buff: 17626, dur: 7200, cat: "flask", stats: "hp", tier: 1, icon: "inv_potion_62", name: "Flask of the Titans", note: "+1200 max. health" },
  { id: 13511, buff: 17627, dur: 7200, cat: "flask", stats: "mana", tier: 1, icon: "inv_potion_97", name: "Flask of Distilled Wisdom", note: "+2000 max. mana" },
  { id: 13512, buff: 17628, dur: 7200, cat: "flask", stats: "spell", tier: 1, icon: "inv_potion_41", name: "Flask of Supreme Power", note: "+150 spell damage" },
  { id: 13513, buff: 17629, dur: 7200, cat: "flask", stats: "resist", tier: 1, icon: "inv_potion_48", name: "Flask of Chromatic Resistance", note: "+25 all resistances" },
  { id: 13506, buff: 17624, dur: 60, cat: "flask", stats: "other", tier: 1, icon: "inv_potion_26", name: "Flask of Petrification", note: "Petrified: immune, no actions (1 min)" },
  { id: 9206, buff: 11405, dur: 3600, cat: "elixir", stats: "ap", tier: 1, icon: "inv_potion_61", name: "Elixir of Giants", note: "+25 Strength" },
  { id: 13453, buff: 17537, dur: 3600, cat: "elixir", stats: "ap hp", tier: 2, icon: "inv_potion_40", name: "Elixir of Brute Force", note: "+18 Strength, +18 Stamina" },
  { id: 12820, buff: 17038, dur: 1200, cat: "elixir", stats: "ap", tier: 2, icon: "inv_potion_92", name: "Winterfall Firewater", note: "+35 melee attack power" },
  { id: 3391, buff: 3164, dur: 3600, cat: "elixir", stats: "ap", tier: 3, icon: "inv_potion_57", name: "Elixir of Ogre's Strength", note: "+8 Strength" },
  { id: 6662, buff: 8212, dur: 120, cat: "elixir", stats: "ap", tier: 3, icon: "inv_potion_10", name: "Elixir of Giant Growth", note: "+8 Strength, enlarged" },
  { id: 2454, buff: 2367, dur: 3600, cat: "elixir", stats: "ap", tier: 3, icon: "inv_potion_56", name: "Elixir of Lion's Strength", note: "+4 Strength" },
  { id: 9224, buff: 11406, dur: 300, cat: "elixir", stats: "ap", tier: 2, icon: "inv_potion_27", name: "Elixir of Demonslaying", note: "+265 attack power vs. demons" },
  { id: 13452, buff: 17538, dur: 3600, cat: "elixir", stats: "agi crit", tier: 1, icon: "inv_potion_32", name: "Elixir of the Mongoose", note: "+25 Agility, +2% crit" },
  { id: 9187, buff: 11334, dur: 3600, cat: "elixir", stats: "agi", tier: 2, icon: "inv_potion_94", name: "Elixir of Greater Agility", note: "+25 Agility" },
  { id: 8949, buff: 11328, dur: 3600, cat: "elixir", stats: "agi", tier: 3, icon: "inv_potion_93", name: "Elixir of Agility", note: "+15 Agility" },
  { id: 3390, buff: 3160, dur: 3600, cat: "elixir", stats: "agi", tier: 3, icon: "inv_potion_92", name: "Elixir of Lesser Agility", note: "+8 Agility" },
  { id: 2457, buff: 2374, dur: 3600, cat: "elixir", stats: "agi", tier: 3, icon: "inv_potion_91", name: "Elixir of Minor Agility", note: "+4 Agility" },
  { id: 3825, buff: 3593, dur: 3600, cat: "elixir", stats: "hp", tier: 1, icon: "inv_potion_43", name: "Elixir of Fortitude", note: "+120 max. health" },
  { id: 2458, buff: 2378, dur: 3600, cat: "elixir", stats: "hp", tier: 3, icon: "inv_potion_42", name: "Elixir of Minor Fortitude", note: "+27 max. health" },
  { id: 20004, buff: 24361, dur: 3600, cat: "elixir", stats: "regen", tier: 1, icon: "inv_potion_80", name: "Major Troll's Blood Potion", note: "+20 health every 5 sec" },
  { id: 3826, buff: 3223, dur: 3600, cat: "elixir", stats: "regen", tier: 2, icon: "inv_potion_79", name: "Mighty Troll's Blood Potion", note: "+12 health every 5 sec" },
  { id: 3388, buff: 3222, dur: 3600, cat: "elixir", stats: "regen", tier: 3, icon: "inv_potion_78", name: "Strong Troll's Blood Potion", note: "+6 health every 5 sec" },
  { id: 3382, buff: 3219, dur: 3600, cat: "elixir", stats: "regen", tier: 3, icon: "inv_potion_77", name: "Weak Troll's Blood Potion", note: "+2 health every 5 sec" },
  { id: 9179, buff: 11396, dur: 3600, cat: "elixir", stats: "mana", tier: 1, icon: "inv_potion_10", name: "Elixir of Greater Intellect", note: "+25 Intellect" },
  { id: 13447, buff: 17535, dur: 3600, cat: "elixir", stats: "mana spirit", tier: 2, icon: "inv_potion_29", name: "Elixir of the Sages", note: "+18 Intellect, +18 Spirit" },
  { id: 3383, buff: 3166, dur: 3600, cat: "elixir", stats: "mana", tier: 3, icon: "inv_potion_06", name: "Elixir of Wisdom", note: "+6 Intellect" },
  { id: 20007, buff: 24363, dur: 3600, cat: "elixir", stats: "mp5", tier: 1, icon: "inv_potion_45", name: "Mageblood Potion", note: "+12 mana every 5 sec" },
  { id: 13454, buff: 17539, dur: 3600, cat: "elixir", stats: "spell", tier: 1, icon: "inv_potion_25", name: "Greater Arcane Elixir", note: "+35 spell damage" },
  { id: 9155, buff: 11390, dur: 1800, cat: "elixir", stats: "spell", tier: 2, icon: "inv_potion_30", name: "Arcane Elixir", note: "+20 spell damage" },
  { id: 21546, buff: 26276, dur: 1800, cat: "elixir", stats: "spell", tier: 1, icon: "inv_potion_60", name: "Elixir of Greater Firepower", note: "+40 fire damage" },
  { id: 6373, buff: 7844, dur: 1800, cat: "elixir", stats: "spell", tier: 3, icon: "inv_potion_33", name: "Elixir of Firepower", note: "+10 fire damage" },
  { id: 17708, buff: 21920, dur: 1800, cat: "elixir", stats: "spell", tier: 1, icon: "inv_potion_03", name: "Elixir of Frost Power", note: "+15 frost damage" },
  { id: 9264, buff: 11474, dur: 1800, cat: "elixir", stats: "spell", tier: 1, icon: "inv_potion_46", name: "Elixir of Shadow Power", note: "+40 shadow damage" },
  { id: 13445, buff: 11348, dur: 3600, cat: "elixir", stats: "armor", tier: 1, icon: "inv_potion_66", name: "Elixir of Superior Defense", note: "+450 armor" },
  { id: 8951, buff: 11349, dur: 3600, cat: "elixir", stats: "armor", tier: 2, icon: "inv_potion_65", name: "Elixir of Greater Defense", note: "+250 armor" },
  { id: 3389, buff: 3220, dur: 3600, cat: "elixir", stats: "armor", tier: 3, icon: "inv_potion_64", name: "Elixir of Defense", note: "+150 armor" },
  { id: 5997, buff: 673, dur: 3600, cat: "elixir", stats: "armor", tier: 3, icon: "inv_potion_63", name: "Elixir of Minor Defense", note: "+50 armor" },
  { id: 9088, buff: 11371, dur: 1800, cat: "elixir", stats: "resist", tier: 1, icon: "inv_potion_28", name: "Gift of Arthas", note: "+10 shadow resistance, may infect attackers" },
  { id: 18294, buff: 22807, dur: 3600, cat: "elixir", stats: "other", tier: 1, icon: "inv_potion_05", name: "Elixir of Greater Water Breathing", note: "Water breathing" },
  { id: 5996, buff: 7178, dur: 1800, cat: "elixir", stats: "other", tier: 2, icon: "inv_potion_17", name: "Elixir of Water Breathing", note: "Water breathing" },
  { id: 8827, buff: 11319, dur: 1800, cat: "elixir", stats: "other", tier: 1, icon: "inv_potion_15", name: "Elixir of Water Walking", note: "Water walking" },
  { id: 9154, buff: 11389, dur: 3600, cat: "elixir", stats: "other", tier: 1, icon: "inv_potion_53", name: "Elixir of Detect Undead", note: "Undead on the minimap" },
  { id: 9233, buff: 11407, dur: 3600, cat: "elixir", stats: "other", tier: 1, icon: "inv_potion_53", name: "Elixir of Detect Demon", note: "Demons on the minimap" },
  { id: 3828, buff: 6512, dur: 600, cat: "elixir", stats: "other", tier: 1, icon: "inv_potion_01", name: "Elixir of Detect Lesser Invisibility", note: "Detect lesser invisibility" },
  { id: 10592, buff: 12608, dur: 600, cat: "elixir", stats: "other", tier: 1, icon: "inv_potion_36", name: "Catseye Elixir", note: "Better stealth detection" },
  { id: 13455, buff: 17540, dur: 120, cat: "potion", stats: "armor", tier: 1, icon: "inv_potion_69", name: "Greater Stoneshield Potion", note: "+2000 armor (2 min)" },
  { id: 4623, buff: 4941, dur: 90, cat: "potion", stats: "armor", tier: 2, icon: "inv_potion_67", name: "Lesser Stoneshield Potion", note: "+1000 armor (90 sec)" },
  { id: 13442, buff: 17528, dur: 20, cat: "potion", stats: "ap", tier: 1, icon: "inv_potion_41", name: "Mighty Rage Potion", note: "+60 Strength, 45-75 rage (20 sec)" },
  { id: 5634, buff: 6615, dur: 30, cat: "potion", stats: "other", tier: 1, icon: "inv_potion_04", name: "Free Action Potion", note: "Immune to stuns and slows" },
  { id: 20008, buff: 24364, dur: 5, cat: "potion", stats: "other", tier: 1, icon: "inv_potion_07", name: "Living Action Potion", note: "Immune, removes stuns/slows" },
  { id: 3387, buff: 3169, dur: 6, cat: "potion", stats: "other", tier: 1, icon: "inv_potion_62", name: "Limited Invulnerability Potion", note: "Immune to physical damage (6 sec)" },
  { id: 9030, buff: 11359, dur: 30, cat: "potion", stats: "other", tier: 1, icon: "inv_potion_01", name: "Restorative Potion", note: "Removes a harmful effect every 5 sec" },
  { id: 9036, buff: 11364, dur: 180, cat: "potion", stats: "resist", tier: 1, icon: "inv_potion_16", name: "Magic Resistance Potion", note: "+50 all resistances (3 min)" },
  { id: 13458, buff: 17546, dur: 3600, cat: "elixir", stats: "resist", tier: 1, icon: "inv_potion_22", name: "Greater Nature Protection Potion", note: "Absorbs 1950-3250 nature damage" },
  { id: 6052, buff: 7254, dur: 3600, cat: "elixir", stats: "resist", tier: 2, icon: "inv_potion_06", name: "Nature Protection Potion", note: "Absorbs 1350-2250 nature damage" },
  { id: 13457, buff: 17543, dur: 3600, cat: "elixir", stats: "resist", tier: 1, icon: "inv_potion_24", name: "Greater Fire Protection Potion", note: "Absorbs 1950-3250 fire damage" },
  { id: 6049, buff: 7233, dur: 3600, cat: "elixir", stats: "resist", tier: 2, icon: "inv_potion_16", name: "Fire Protection Potion", note: "Absorbs 975-1625 fire damage" },
  { id: 13456, buff: 17544, dur: 3600, cat: "elixir", stats: "resist", tier: 1, icon: "inv_potion_20", name: "Greater Frost Protection Potion", note: "Absorbs 1950-3250 frost damage" },
  { id: 6050, buff: 7239, dur: 3600, cat: "elixir", stats: "resist", tier: 2, icon: "inv_potion_13", name: "Frost Protection Potion", note: "Absorbs 1350-2250 frost damage" },
  { id: 13459, buff: 17548, dur: 3600, cat: "elixir", stats: "resist", tier: 1, icon: "inv_potion_23", name: "Greater Shadow Protection Potion", note: "Absorbs 1950-3250 shadow damage" },
  { id: 6048, buff: 7242, dur: 3600, cat: "elixir", stats: "resist", tier: 2, icon: "inv_potion_44", name: "Shadow Protection Potion", note: "Absorbs 675-1125 shadow damage" },
  { id: 13461, buff: 17549, dur: 3600, cat: "elixir", stats: "resist", tier: 1, icon: "inv_potion_83", name: "Greater Arcane Protection Potion", note: "Absorbs 1950-3250 arcane damage" },
  { id: 6051, buff: 7245, dur: 3600, cat: "elixir", stats: "resist", tier: 2, icon: "inv_potion_09", name: "Holy Protection Potion", note: "Absorbs 300-500 holy damage" },
  { id: 2459, buff: 2379, dur: 15, cat: "potion", stats: "speed", tier: 1, icon: "inv_potion_95", name: "Swiftness Potion", note: "+50% run speed (15 sec)" },
  { id: 6372, buff: 7840, dur: 20, cat: "potion", stats: "speed", tier: 1, icon: "inv_potion_13", name: "Swim Speed Potion", note: "+100% swim speed" },
  { id: 9172, buff: 11392, dur: 18, cat: "potion", stats: "other", tier: 1, icon: "inv_potion_25", name: "Invisibility Potion", note: "Invisibility (18 sec)" },
  { id: 3823, buff: 3680, dur: 15, cat: "potion", stats: "other", tier: 2, icon: "inv_potion_18", name: "Lesser Invisibility Potion", note: "Lesser invisibility (15 sec)" },
  { id: 20452, buff: 24799, dur: 900, cat: "food", stats: "ap", tier: 1, icon: "inv_misc_food_64", name: "Smoked Desert Dumplings", note: "Well Fed: +20 Strength", use: 24800 },
  { id: 13810, buff: 18125, dur: 600, cat: "food", stats: "ap", tier: 2, icon: "inv_misc_food_41", name: "Blessed Sunfruit", note: "+10 Strength" },
  { id: 13928, buff: 18192, dur: 600, cat: "food", stats: "agi", tier: 1, icon: "inv_misc_fish_13", name: "Grilled Squid", note: "+10 Agility" },
  { id: 21023, buff: 25661, dur: 900, cat: "food", stats: "hp", tier: 1, icon: "inv_misc_food_65", name: "Dirge's Kickin' Chimaerok Chops", note: "+25 Stamina" },
  { id: 13934, buff: 18191, dur: 600, cat: "food", stats: "hp", tier: 2, icon: "inv_misc_food_47", name: "Mightfish Steak", note: "+10 Stamina" },
  { id: 13927, buff: 18191, dur: 600, cat: "food", stats: "hp", tier: 2, icon: "inv_misc_monsterhead_03", name: "Cooked Glossy Mightfish", note: "+10 Stamina" },
  { id: 11950, buff: 18191, dur: 600, cat: "food", stats: "hp", tier: 2, icon: "inv_misc_food_58", name: "Windblossom Berries", note: "+10 Stamina (Felwood)" },
  { id: 20516, buff: 24870, dur: 900, cat: "food", stats: "hp spirit", tier: 2, icon: "inv_misc_food_19", name: "Bobbing Apple", note: "Stamina/Spirit by level (60: +15)" },
  { id: 21254, buff: 24870, dur: 900, cat: "food", stats: "hp spirit", tier: 2, icon: "inv_misc_food_62", name: "Winter Veil Cookie", note: "Stamina/Spirit by level (60: +15)" },
  { id: 18045, buff: 19710, dur: 900, cat: "food", stats: "hp spirit", tier: 2, icon: "inv_misc_food_47", name: "Tender Wolf Steak", note: "Well Fed: +12 Stamina/Spirit" },
  { id: 12218, buff: 19710, dur: 900, cat: "food", stats: "hp spirit", tier: 2, icon: "inv_misc_food_06", name: "Monster Omelet", note: "Well Fed: +12 Stamina/Spirit" },
  { id: 17222, buff: 19710, dur: 900, cat: "food", stats: "hp spirit", tier: 2, icon: "inv_misc_food_66", name: "Spider Sausage", note: "Well Fed: +12 Stamina/Spirit" },
  { id: 12215, buff: 19710, dur: 900, cat: "food", stats: "hp spirit", tier: 2, icon: "inv_drink_19", name: "Heavy Kodo Stew", note: "Well Fed: +12 Stamina/Spirit" },
  { id: 12216, buff: 19710, dur: 900, cat: "food", stats: "hp spirit", tier: 2, icon: "inv_misc_food_48", name: "Spiced Chili Crab", note: "Well Fed: +12 Stamina/Spirit" },
  { id: 12210, buff: 19709, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_50", name: "Roast Raptor", note: "Well Fed: +8 Stamina/Spirit" },
  { id: 13851, buff: 19709, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_48", name: "Hot Wolf Ribs", note: "Well Fed: +8 Stamina/Spirit" },
  { id: 12211, buff: 19709, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_48", name: "Spiced Wolf Ribs", note: "Well Fed: +8 Stamina/Spirit" },
  { id: 12212, buff: 19709, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_drink_17", name: "Jungle Stew", note: "Well Fed: +8 Stamina/Spirit" },
  { id: 12214, buff: 19709, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_drink_19", name: "Mystery Stew", note: "Well Fed: +8 Stamina/Spirit" },
  { id: 3729, buff: 19709, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_bowl_01", name: "Soothing Turtle Bisque", note: "Well Fed: +8 Stamina/Spirit" },
  { id: 3728, buff: 19709, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_14", name: "Tasty Lion Steak", note: "Well Fed: +8 Stamina/Spirit" },
  { id: 12213, buff: 19709, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_49", name: "Carrion Surprise", note: "Well Fed: +8 Stamina/Spirit" },
  { id: 4457, buff: 19709, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_18", name: "Barbecued Buzzard Wing", note: "Well Fed: +8 Stamina/Spirit" },
  { id: 6038, buff: 19709, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_ammo_firetar", name: "Giant Clam Scorcho", note: "Well Fed: +8 Stamina/Spirit" },
  { id: 20074, buff: 19709, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_64", name: "Heavy Crocolisk Stew", note: "Well Fed: +8 Stamina/Spirit" },
  { id: 3727, buff: 19708, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_18", name: "Hot Lion Chops", note: "Well Fed: +6 Stamina/Spirit" },
  { id: 5479, buff: 19708, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_17", name: "Crispy Lizard Tail", note: "Well Fed: +6 Stamina/Spirit" },
  { id: 3666, buff: 19708, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_10", name: "Gooey Spider Cake", note: "Well Fed: +6 Stamina/Spirit" },
  { id: 3663, buff: 19708, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_bowl_01", name: "Murloc Fin Soup", note: "Well Fed: +6 Stamina/Spirit" },
  { id: 3726, buff: 19708, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_47", name: "Big Bear Steak", note: "Well Fed: +6 Stamina/Spirit" },
  { id: 3664, buff: 19708, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_bowl_01", name: "Crocolisk Gumbo", note: "Well Fed: +6 Stamina/Spirit" },
  { id: 1082, buff: 19708, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_bowl_01", name: "Redridge Goulash", note: "Well Fed: +6 Stamina/Spirit" },
  { id: 1017, buff: 19708, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_16", name: "Seasoned Wolf Kabob", note: "Well Fed: +6 Stamina/Spirit" },
  { id: 12209, buff: 19708, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_47", name: "Lean Wolf Steak", note: "Well Fed: +6 Stamina/Spirit" },
  { id: 3665, buff: 19708, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_egg_04", name: "Curiously Tasty Omelet", note: "Well Fed: +6 Stamina/Spirit" },
  { id: 5527, buff: 19708, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_shell_01", name: "Goblin Deviled Clams", note: "Well Fed: +6 Stamina/Spirit" },
  { id: 5480, buff: 19708, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_72", name: "Lean Venison", note: "Well Fed: +6 Stamina/Spirit" },
  { id: 3662, buff: 19706, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_47", name: "Crocolisk Steak", note: "Well Fed: +4 Stamina/Spirit" },
  { id: 724, buff: 19706, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_10", name: "Goretusk Liver Pie", note: "Well Fed: +4 Stamina/Spirit" },
  { id: 5525, buff: 19706, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_shell_02", name: "Boiled Clams", note: "Well Fed: +4 Stamina/Spirit" },
  { id: 3220, buff: 19706, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_49", name: "Blood Sausage", note: "Well Fed: +4 Stamina/Spirit" },
  { id: 2684, buff: 19706, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_65", name: "Coyote Steak", note: "Well Fed: +4 Stamina/Spirit" },
  { id: 5476, buff: 19706, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_fish_05", name: "Fillet of Frenzy", note: "Well Fed: +4 Stamina/Spirit" },
  { id: 5477, buff: 19706, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_bowl_01", name: "Strider Stew", note: "Well Fed: +4 Stamina/Spirit" },
  { id: 2683, buff: 19706, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_08", name: "Crab Cake", note: "Well Fed: +4 Stamina/Spirit" },
  { id: 2687, buff: 19706, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_48", name: "Dry Pork Ribs", note: "Well Fed: +4 Stamina/Spirit" },
  { id: 6888, buff: 19705, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_egg_03", name: "Herb Baked Egg", note: "Well Fed: +2 Stamina/Spirit" },
  { id: 2680, buff: 19705, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_65", name: "Spiced Wolf Meat", note: "Well Fed: +2 Stamina/Spirit" },
  { id: 2888, buff: 19705, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_48", name: "Beer Basted Boar Ribs", note: "Well Fed: +2 Stamina/Spirit" },
  { id: 17197, buff: 19705, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_62", name: "Gingerbread Cookie", note: "Well Fed: +2 Stamina/Spirit" },
  { id: 5472, buff: 19705, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_68", name: "Kaldorei Spider Kabob", note: "Well Fed: +2 Stamina/Spirit" },
  { id: 5474, buff: 19705, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_60", name: "Roasted Kodo Meat", note: "Well Fed: +2 Stamina/Spirit" },
  { id: 12224, buff: 19705, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_misc_food_46", name: "Crispy Bat Wing", note: "Well Fed: +2 Stamina/Spirit" },
  { id: 13932, buff: 18222, dur: 600, cat: "food", stats: "regen", tier: 1, icon: "inv_misc_fish_19", name: "Poached Sunscale Salmon", note: "+6 health every 5 sec" },
  { id: 18254, buff: 22730, dur: 600, cat: "food", stats: "mana", tier: 1, icon: "inv_misc_food_63", name: "Runn Tum Tuber Surprise", note: "+10 Intellect" },
  { id: 13931, buff: 18194, dur: 600, cat: "food", stats: "mp5", tier: 1, icon: "inv_drink_17", name: "Nightfin Soup", note: "+8 mana every 5 sec" },
  { id: 21217, buff: 25941, dur: 900, cat: "food", stats: "mp5", tier: 2, icon: "inv_misc_fish_21", name: "Sagefish Delight", note: "+6 mana every 5 sec" },
  { id: 21072, buff: 25694, dur: 900, cat: "food", stats: "mp5", tier: 3, icon: "inv_misc_fish_20", name: "Smoked Sagefish", note: "+3 mana every 5 sec" },
  { id: 22238, buff: 27721, dur: 3600, cat: "food", stats: "spell", tier: 1, icon: "inv_valentineschocolate02", name: "Very Berry Cream", note: "+23 spell damage" },
  { id: 22239, buff: 27722, dur: 3600, cat: "food", stats: "spell", tier: 1, icon: "inv_valentineschocolate03", name: "Sweet Surprise", note: "+44 healing" },
  { id: 13929, buff: 18193, dur: 600, cat: "food", stats: "spirit", tier: 1, icon: "inv_misc_fish_03", name: "Hot Smoked Bass", note: "+10 Spirit" },
  { id: 13813, buff: 18141, dur: 600, cat: "food", stats: "spirit", tier: 1, icon: "inv_drink_16", name: "Blessed Sunfruit Juice", note: "+10 Spirit" },
  { id: 12217, buff: 15852, dur: 600, cat: "other", stats: "other", tier: 1, icon: "inv_drink_17", name: "Dragonbreath Chili", note: "Fire breath proc in melee" },
  { id: 22237, buff: 27723, dur: 3600, cat: "food", stats: "other", tier: 1, icon: "inv_valentineschocolate04", name: "Dark Desire", note: "+2% hit chance" },
  { id: 22236, buff: 27720, dur: 3600, cat: "food", stats: "other", tier: 1, icon: "inv_valentineschocolate01", name: "Buttermilk Delight", note: "+13 defense" },
  { id: 21151, buff: 25804, dur: 900, cat: "food", stats: "hp", tier: 1, icon: "inv_drink_04", name: "Rumsey Rum Black Label", note: "+15 Stamina" },
  { id: 18269, buff: 22789, dur: 900, cat: "food", stats: "hp", tier: 2, icon: "inv_drink_03", name: "Gordok Green Grog", note: "+10 Stamina" },
  { id: 21114, buff: 25722, dur: 900, cat: "food", stats: "hp", tier: 2, icon: "inv_drink_04", name: "Rumsey Rum Dark", note: "+10 Stamina" },
  { id: 20709, buff: 25037, dur: 900, cat: "food", stats: "hp", tier: 3, icon: "inv_drink_08", name: "Rumsey Rum Light", note: "+5 Stamina" },
  { id: 17198, buff: 19705, dur: 900, cat: "food", stats: "hp spirit", tier: 3, icon: "inv_drink_04", name: "Egg Nog", note: "Well Fed: +2 Stamina/Spirit" },
  { id: 5342, buff: 6114, dur: 300, cat: "food", stats: "mana", tier: 3, icon: "inv_drink_04", name: "Raptor Punch", note: "+4 Intellect, -5 Stamina" },
  { id: 18284, buff: 22790, dur: 900, cat: "food", stats: "spirit", tier: 1, icon: "inv_drink_05", name: "Kreeg's Stout Beatdown", note: "+25 Spirit, -5 Intellect" },
  { id: 12460, buff: 16329, dur: 600, cat: "elixir", stats: "ap", tier: 1, icon: "inv_misc_monsterscales_07", name: "Juju Might", note: "+40 attack power" },
  { id: 12451, buff: 16323, dur: 1800, cat: "elixir", stats: "ap", tier: 1, icon: "inv_misc_monsterscales_11", name: "Juju Power", note: "+30 Strength" },
  { id: 12450, buff: 16322, dur: 20, cat: "elixir", stats: "other", tier: 1, icon: "inv_misc_monsterscales_17", name: "Juju Flurry", note: "+3% attack speed (20 sec)" },
  { id: 12455, buff: 16326, dur: 600, cat: "elixir", stats: "resist", tier: 1, icon: "inv_misc_monsterscales_15", name: "Juju Ember", note: "+15 fire resistance" },
  { id: 12457, buff: 16325, dur: 600, cat: "elixir", stats: "resist", tier: 1, icon: "inv_misc_monsterscales_09", name: "Juju Chill", note: "+15 frost resistance" },
  { id: 12458, buff: 16327, dur: 1800, cat: "elixir", stats: "mana", tier: 1, icon: "inv_misc_monsterscales_13", name: "Juju Guile", note: "+30 Intellect" },
  { id: 12459, buff: 16321, dur: 10, cat: "elixir", stats: "other", tier: 1, icon: "inv_misc_monsterscales_17", name: "Juju Escape", note: "+5% dodge (10 sec, rogues only per tooltip)" },
  { id: 20079, buff: 24382, dur: 7200, cat: "flask", stats: "hp spirit", tier: 1, icon: "inv_potion_30", name: "Spirit of Zanza", note: "+50 Stamina, +50 Spirit" },
  { id: 20081, buff: 24383, dur: 7200, cat: "flask", stats: "speed", tier: 1, icon: "inv_potion_31", name: "Swiftness of Zanza", note: "+20% run speed" },
  { id: 20080, buff: 24417, dur: 7200, cat: "flask", stats: "other", tier: 1, icon: "inv_potion_29", name: "Sheen of Zanza", note: "3% spell reflection" },
  { id: 10310, buff: 12179, dur: 1800, cat: "other", stats: "ap", tier: 1, icon: "inv_scroll_02", name: "Scroll of Strength IV", note: "+17 Strength" },
  { id: 4426, buff: 8120, dur: 1800, cat: "other", stats: "ap", tier: 2, icon: "inv_scroll_02", name: "Scroll of Strength III", note: "+13 Strength" },
  { id: 2289, buff: 8119, dur: 1800, cat: "other", stats: "ap", tier: 3, icon: "inv_scroll_02", name: "Scroll of Strength II", note: "+9 Strength" },
  { id: 954, buff: 8118, dur: 1800, cat: "other", stats: "ap", tier: 3, icon: "inv_scroll_02", name: "Scroll of Strength", note: "+5 Strength" },
  { id: 10309, buff: 12174, dur: 1800, cat: "other", stats: "agi", tier: 1, icon: "inv_scroll_02", name: "Scroll of Agility IV", note: "+17 Agility" },
  { id: 4425, buff: 8117, dur: 1800, cat: "other", stats: "agi", tier: 2, icon: "inv_scroll_02", name: "Scroll of Agility III", note: "+13 Agility" },
  { id: 1477, buff: 8116, dur: 1800, cat: "other", stats: "agi", tier: 3, icon: "inv_scroll_02", name: "Scroll of Agility II", note: "+9 Agility" },
  { id: 3012, buff: 8115, dur: 1800, cat: "other", stats: "agi", tier: 3, icon: "inv_scroll_02", name: "Scroll of Agility", note: "+5 Agility" },
  { id: 10307, buff: 12178, dur: 1800, cat: "other", stats: "hp", tier: 1, icon: "inv_scroll_07", name: "Scroll of Stamina IV", note: "+16 Stamina" },
  { id: 4422, buff: 8101, dur: 1800, cat: "other", stats: "hp", tier: 2, icon: "inv_scroll_07", name: "Scroll of Stamina III", note: "+12 Stamina" },
  { id: 1711, buff: 8100, dur: 1800, cat: "other", stats: "hp", tier: 3, icon: "inv_scroll_07", name: "Scroll of Stamina II", note: "+8 Stamina" },
  { id: 1180, buff: 8099, dur: 1800, cat: "other", stats: "hp", tier: 3, icon: "inv_scroll_07", name: "Scroll of Stamina", note: "+4 Stamina" },
  { id: 10308, buff: 12176, dur: 1800, cat: "other", stats: "mana", tier: 1, icon: "inv_scroll_01", name: "Scroll of Intellect IV", note: "+16 Intellect" },
  { id: 4419, buff: 8098, dur: 1800, cat: "other", stats: "mana", tier: 2, icon: "inv_scroll_01", name: "Scroll of Intellect III", note: "+12 Intellect" },
  { id: 2290, buff: 8097, dur: 1800, cat: "other", stats: "mana", tier: 3, icon: "inv_scroll_01", name: "Scroll of Intellect II", note: "+8 Intellect" },
  { id: 955, buff: 8096, dur: 1800, cat: "other", stats: "mana", tier: 3, icon: "inv_scroll_01", name: "Scroll of Intellect", note: "+4 Intellect" },
  { id: 10306, buff: 12177, dur: 1800, cat: "other", stats: "spirit", tier: 1, icon: "inv_scroll_01", name: "Scroll of Spirit IV", note: "+15 Spirit" },
  { id: 4424, buff: 8114, dur: 1800, cat: "other", stats: "spirit", tier: 2, icon: "inv_scroll_01", name: "Scroll of Spirit III", note: "+11 Spirit" },
  { id: 1712, buff: 8113, dur: 1800, cat: "other", stats: "spirit", tier: 3, icon: "inv_scroll_01", name: "Scroll of Spirit II", note: "+7 Spirit" },
  { id: 1181, buff: 8112, dur: 1800, cat: "other", stats: "spirit", tier: 3, icon: "inv_scroll_01", name: "Scroll of Spirit", note: "+3 Spirit" },
  { id: 10305, buff: 12175, dur: 1800, cat: "other", stats: "armor", tier: 1, icon: "inv_scroll_07", name: "Scroll of Protection IV", note: "+240 armor" },
  { id: 4421, buff: 8095, dur: 1800, cat: "other", stats: "armor", tier: 2, icon: "inv_scroll_07", name: "Scroll of Protection III", note: "+180 armor" },
  { id: 1478, buff: 8094, dur: 1800, cat: "other", stats: "armor", tier: 3, icon: "inv_scroll_07", name: "Scroll of Protection II", note: "+120 armor" },
  { id: 3013, buff: 8091, dur: 1800, cat: "other", stats: "armor", tier: 3, icon: "inv_scroll_07", name: "Scroll of Protection", note: "+60 armor" },
  { id: 8410, buff: 10667, dur: 3600, cat: "other", stats: "ap", tier: 1, icon: "inv_stone_15", name: "R.O.I.D.S.", note: "+25 Strength (aura: Rage of Ages)" },
  { id: 8412, buff: 10669, dur: 3600, cat: "other", stats: "agi", tier: 1, icon: "inv_misc_dust_02", name: "Ground Scorpok Assay", note: "+25 Agility" },
  { id: 8411, buff: 10668, dur: 3600, cat: "other", stats: "hp", tier: 1, icon: "inv_drink_12", name: "Lung Juice Cocktail", note: "+25 Stamina" },
  { id: 8423, buff: 10692, dur: 3600, cat: "other", stats: "mana", tier: 1, icon: "inv_potion_32", name: "Cerebral Cortex Compound", note: "+25 Intellect" },
  { id: 8424, buff: 10693, dur: 3600, cat: "other", stats: "spirit", tier: 1, icon: "inv_misc_food_30", name: "Gizzard Gum", note: "+25 Spirit" },
  { id: 11564, buff: 15233, dur: 1800, cat: "other", stats: "armor", tier: 1, icon: "inv_misc_gem_ruby_02", name: "Crystal Ward", note: "+200 armor" },
  { id: 11563, buff: 15231, dur: 1800, cat: "other", stats: "spirit", tier: 1, icon: "inv_misc_gem_crystal_02", name: "Crystal Force", note: "+30 Spirit" },
  { id: 11567, buff: 15279, dur: 600, cat: "other", stats: "other", tier: 1, icon: "inv_misc_gem_stone_01", name: "Crystal Spire", note: "12 nature damage to attackers" },
  { id: 11562, buff: 15229, dur: 15, cat: "other", stats: "regen", tier: 1, icon: "inv_misc_gem_diamond_02", name: "Crystal Restore", note: "Heals 670 over 15 sec" },
  { id: 5206, buff: 5665, dur: 600, cat: "other", stats: "ap", tier: 3, icon: "inv_misc_herb_07", name: "Bogling Root", note: "+1 melee damage" },
  { id: 8956, buff: 11350, dur: 15, cat: "other", stats: "other", tier: 1, icon: "inv_potion_11", name: "Oil of Immolation", note: "Fire damage around you (15 sec)" },
];
/*CATALOG-END*/
/* ----- Weapon enchants (proposal 2026-11-09, Docs/Plan-WeaponEnchants.md; later in Data.lua) -----
   Temporary weapon enchants: stones, oils, poisons. No aura: detected per hand with GetWeaponEnchantInfo()
   (enchant = enchant ID; 2629/2684/2685 confirmed by CharacterStatsClassic, the others still to verify).
   cat "weapon". In a row a weapon item is always a slot with hand = "main" | "off" (H/N on the icon).
   Items, names, icons and durations checked against Wowhead Classic (2026-11-09). stats: primary stat for the
   class filter ("poison" only for rogues). */
const WEAPON_ITEMS = [
  { id: 18262, enchant: null, dur: 1800, cat: "weapon", stats: "crit ap", tier: 1, icon: "inv_stone_02", name: "Elemental Sharpening Stone", note: "+2% melee crit (weapon)" },
  { id: 23122, enchant: 2684, dur: 3600, cat: "weapon", stats: "ap", tier: 1, icon: "inv_stone_sharpeningstone_02", name: "Consecrated Sharpening Stone", note: "+100 AP vs. undead (weapon)" },
  { id: 12404, enchant: null, dur: 1800, cat: "weapon", stats: "ap", tier: 1, icon: "inv_stone_sharpeningstone_05", name: "Dense Sharpening Stone", note: "+8 damage, bladed weapon" },
  { id: 7964, enchant: null, dur: 1800, cat: "weapon", stats: "ap", tier: 2, icon: "inv_stone_sharpeningstone_04", name: "Solid Sharpening Stone", note: "+6 damage, bladed weapon" },
  { id: 2871, enchant: null, dur: 1800, cat: "weapon", stats: "ap", tier: 3, icon: "inv_stone_sharpeningstone_03", name: "Heavy Sharpening Stone", note: "+4 damage, bladed weapon" },
  { id: 12643, enchant: null, dur: 1800, cat: "weapon", stats: "ap", tier: 1, icon: "inv_stone_weightstone_05", name: "Dense Weightstone", note: "+8 damage, blunt weapon" },
  { id: 7965, enchant: null, dur: 1800, cat: "weapon", stats: "ap", tier: 2, icon: "inv_stone_weightstone_04", name: "Solid Weightstone", note: "+6 damage, blunt weapon" },
  { id: 3241, enchant: null, dur: 1800, cat: "weapon", stats: "ap", tier: 3, icon: "inv_stone_weightstone_03", name: "Heavy Weightstone", note: "+4 damage, blunt weapon" },
  { id: 20749, enchant: null, dur: 1800, cat: "weapon", stats: "spell", tier: 1, icon: "inv_potion_105", name: "Brilliant Wizard Oil", note: "+36 spell damage, +1% spell crit" },
  { id: 20748, enchant: 2629, dur: 1800, cat: "weapon", stats: "mp5 heal", tier: 1, icon: "inv_potion_100", name: "Brilliant Mana Oil", note: "12 MP5, +25 healing" },
  { id: 23123, enchant: 2685, dur: 3600, cat: "weapon", stats: "spell", tier: 1, icon: "inv_potion_26", name: "Blessed Wizard Oil", note: "+60 spell damage vs. undead" },
  { id: 20750, enchant: null, dur: 1800, cat: "weapon", stats: "spell", tier: 2, icon: "inv_potion_104", name: "Wizard Oil", note: "+24 spell damage" },
  { id: 20747, enchant: null, dur: 1800, cat: "weapon", stats: "mp5", tier: 2, icon: "inv_potion_99", name: "Lesser Mana Oil", note: "8 MP5" },
  { id: 3824, enchant: null, dur: 1800, cat: "weapon", stats: "other", tier: 2, icon: "inv_potion_23", name: "Shadow Oil", note: "15% chance: Shadow Bolt (melee)" },
  { id: 3829, enchant: null, dur: 1800, cat: "weapon", stats: "other", tier: 2, icon: "inv_potion_20", name: "Frost Oil", note: "10% chance: Frostbolt (melee)" },
  { id: 8928, enchant: null, dur: 1800, cat: "weapon", stats: "poison", tier: 1, icon: "ability_poisons", name: "Instant Poison VI", note: "Poison: 112-148 nature damage" },
  { id: 20844, enchant: null, dur: 1800, cat: "weapon", stats: "poison", tier: 1, icon: "ability_rogue_dualweild", name: "Deadly Poison V", note: "Poison: 136 nature damage over 12 sec" },
  { id: 3776, enchant: null, dur: 1800, cat: "weapon", stats: "poison", tier: 1, icon: "inv_potion_19", name: "Crippling Poison II", note: "Poison: -70% movement speed" },
  { id: 9186, enchant: null, dur: 1800, cat: "weapon", stats: "poison", tier: 1, icon: "spell_nature_nullifydisease", name: "Mind-numbing Poison III", note: "Poison: +60% casting time" },
  { id: 10922, enchant: null, dur: 1800, cat: "weapon", stats: "poison", tier: 1, icon: "ability_poisonsting", name: "Wound Poison IV", note: "Poison: -135 healing" },
];
CATALOG.push(...WEAPON_ITEMS);
// Windfury Totem: weapon enchant of the main hand, refreshed by the totem; has priority over a stone
const WINDFURY = { name: "Windfury Totem", icon: "spell_nature_windfury" };
const ICON_URL = (icon) => `https://wow.zamimg.com/images/wow/icons/large/${icon}.jpg`;
const CAT_BY_ID = Object.fromEntries(CATALOG.map((e) => [e.id, e]));
for (const e of CATALOG) { const s = e.stats.split(/[\s,]+/); e.statSet = new Set(s); e.primary = s[0]; }
// notes are keys (shown through L() like the catalog notes); mockup-only texts
const EXTRA = { 6948: { id: 6948, name: "Hearthstone", icon: "inv_misc_rune_01", dur: 0, note: "Example of an item without a catalog entry" },
  // default alternative of Mighty Rage Potion; instant rage, no buff, so not in the catalog
  5633: { id: 5633, name: "Great Rage Potion", icon: "inv_potion_21", dur: 0, cat: "potion", note: "Instant 30-60 rage, no buff" } };

/* ===================== Buff catalog (proposal 2026-11-09, later ns.BUFFS in Data.lua) ===================== */
// Foreign buffs (not items). In row entries a buff has a negative id: -buff (main spell ID), so drag & drop works
// unchanged. Buffs get no alternatives by hand, only the fixed pairs of DEFAULT_ALTS (mage armors, 2026-11-15); single and group version of the same buff are ONE entry
// (spells = all spell IDs that count, main spell first). Only buffs worth preparing before the pull (>= 10 min,
// like the raid list of the consumables) plus Battle Shout; short ones (HoTs, shields, BoP ...) appear under
// "Sonstige". All spell IDs checked against Wowhead Classic (2026-11-09). In Lua the detection needs all ranks
// (or the buff name); the mockup only knows the highest rank.
// cat: world / raid / situ / own / trinket / proc / skill (2026-11-17) / misc. hide: classes that do not need it. only: only these classes. fac: A = Alliance only,
// H = Horde only. self: the player casts it himself (Ctrl+click casts it). dur 0 = aura/totem without duration.
const BUFFS = [
  { buff: 22888, dur: 7200, cat: "world", icon: "inv_misc_head_dragon_01", name: "Rallying Cry of the Dragonslayer", note: "Onyxia/Nefarian: crit, spell crit, AP" },
  { buff: 16609, dur: 3600, cat: "world", icon: "spell_arcane_teleportorgrimmar", name: "Warchief's Blessing", note: "Rend: health, attack speed, MP5" },
  { buff: 24425, dur: 7200, cat: "world", icon: "ability_creature_poison_05", name: "Spirit of Zandalar", note: "Heart of Hakkar: +15% stats" },
  { buff: 15366, dur: 3600, cat: "world", icon: "spell_holy_mindvision", name: "Songflower Serenade", note: "Crit, spell crit, stats" },
  { buff: 22817, dur: 7200, cat: "world", icon: "spell_nature_undyingstrength", name: "Fengus' Ferocity", note: "Dire Maul: +200 AP" },
  { buff: 22818, dur: 7200, cat: "world", icon: "spell_nature_massteleport", name: "Mol'dar's Moxie", note: "Dire Maul: +15% Stamina" },
  { buff: 22820, dur: 7200, cat: "world", icon: "spell_holy_lesserheal02", name: "Slip'kik's Savvy", note: "Dire Maul: +3% spell crit", hide: ["WARRIOR", "ROGUE", "HUNTER"] },
  { buff: 23768, dur: 7200, cat: "world", icon: "inv_misc_orb_02", name: "Sayge's Dark Fortune of Damage", note: "Darkmoon: +10% damage" },
  { buff: 23736, dur: 7200, cat: "world", icon: "inv_misc_orb_02", name: "Sayge's Dark Fortune of Agility", note: "Darkmoon: +10% Agility" },
  { buff: 23735, dur: 7200, cat: "world", icon: "inv_misc_orb_02", name: "Sayge's Dark Fortune of Strength", note: "Darkmoon: +10% Strength" },
  { buff: 23737, dur: 7200, cat: "world", icon: "inv_misc_orb_02", name: "Sayge's Dark Fortune of Stamina", note: "Darkmoon: +10% Stamina" },
  { buff: 23767, dur: 7200, cat: "world", icon: "inv_misc_orb_02", name: "Sayge's Dark Fortune of Armor", note: "Darkmoon: +10% armor" },
  { buff: 23769, dur: 7200, cat: "world", icon: "inv_misc_orb_02", name: "Sayge's Dark Fortune of Resistance", note: "Darkmoon: +25 resistances" },
  { buff: 23766, dur: 7200, cat: "world", icon: "inv_misc_orb_02", name: "Sayge's Dark Fortune of Intelligence", note: "Darkmoon: +10% Intellect", hide: ["WARRIOR", "ROGUE"] },
  { buff: 23738, dur: 7200, cat: "world", icon: "inv_misc_orb_02", name: "Sayge's Dark Fortune of Spirit", note: "Darkmoon: +10% Spirit", hide: ["WARRIOR", "ROGUE", "HUNTER"] },
  // Supercharged Chronoboon Displacer (user 2026-11-17) = Data.lua: holds the suspended world buffs, cannot be removed
  { buff: 349981, dur: 0, cat: "world", icon: "inv_misc_enggizmos_24", name: "Supercharged Chronoboon Displacer", note: "Holds the world buffs suspended by the Chronoboon Displacer" },

  { buff: 21564, spells: [21564, 10938], dur: 3600, cat: "raid", icon: "spell_holy_prayeroffortitude", name: "Fortitude", note: "Priest: Stamina (single or group)", selfClass: ["PRIEST"] },
  { buff: 21850, spells: [21850, 9885], dur: 3600, cat: "raid", icon: "spell_nature_regeneration", name: "Mark / Gift of the Wild", note: "Druid: stats, armor, resistances (single or group)", selfClass: ["DRUID"] },
  { buff: 25289, dur: 120, cat: "raid", icon: "ability_warrior_battleshout", name: "Battle Shout", note: "Warrior: melee attack power (group)", hide: ["MAGE", "WARLOCK", "PRIEST"], selfClass: ["WARRIOR"] }, // every melee class (2026-11-20)
  { buff: 25898, spells: [25898, 20217], dur: 900, cat: "raid", icon: "spell_magic_greaterblessingofkings", name: "Blessing of Kings", note: "Paladin: +10% stats (greater blessing too)", fac: "A" },
  { buff: 25916, spells: [25916, 25291], dur: 900, cat: "raid", icon: "spell_holy_greaterblessingofkings", name: "Blessing of Might", note: "Paladin: attack power (greater blessing too)", fac: "A", hide: ["MAGE", "WARLOCK", "PRIEST"] },
  { buff: 25895, spells: [25895, 1038], dur: 900, cat: "raid", icon: "spell_holy_greaterblessingofsalvation", name: "Blessing of Salvation", note: "Paladin: -30% threat (greater blessing too)", fac: "A" },
  { buff: 25362, dur: 0, cat: "aura", sub: "totem", icon: "spell_nature_earthbindtotem", name: "Strength of Earth", note: "Shaman totem: Strength", fac: "H", hide: ["MAGE", "WARLOCK", "PRIEST"] },
  { buff: 25360, dur: 0, cat: "aura", sub: "totem", icon: "spell_nature_invisibilitytotem", name: "Grace of Air", note: "Shaman totem: Agility", fac: "H", hide: ["MAGE", "WARLOCK", "PRIEST"] },
  { buff: 20906, dur: 0, cat: "aura", icon: "ability_trueshot", name: "Trueshot Aura", note: "Hunter: attack power (group)", hide: ["MAGE", "WARLOCK", "PRIEST"], selfClass: ["HUNTER"] },
  { buff: 24932, dur: 0, cat: "aura", icon: "spell_nature_unyeildingstamina", name: "Leader of the Pack", note: "Druid (cat/bear): +3% crit (group)", hide: ["MAGE", "WARLOCK", "PRIEST"] },
  { buff: 9910, dur: 600, cat: "raid", icon: "spell_nature_thorns", name: "Thorns", note: "Druid: nature damage to attackers" },
  { buff: 23028, spells: [23028, 10157], dur: 3600, cat: "raid", icon: "spell_holy_arcaneintellect", name: "Arcane Intellect", note: "Mage: Intellect (single or group)", hide: ["WARRIOR", "ROGUE"], selfClass: ["MAGE"] },
  { buff: 27681, spells: [27681, 27841], dur: 3600, cat: "raid", icon: "spell_holy_prayerofspirit", name: "Divine Spirit", note: "Priest: Spirit (single or group)", hide: ["WARRIOR", "ROGUE", "HUNTER"], selfClass: ["PRIEST"] },

  { buff: 19900, dur: 0, cat: "aura", icon: "spell_fire_sealoffire", name: "Fire Resistance Aura", note: "Paladin: fire resistance", fac: "A" },
  { buff: 10535, dur: 0, cat: "aura", sub: "totem", icon: "spell_fireresistancetotem_01", name: "Fire Resistance Totem", note: "Shaman totem: fire resistance", fac: "H" },
  { buff: 19898, dur: 0, cat: "aura", icon: "spell_frost_wizardmark", name: "Frost Resistance Aura", note: "Paladin: frost resistance", fac: "A" },
  { buff: 10477, dur: 0, cat: "aura", sub: "totem", icon: "spell_frostresistancetotem_01", name: "Frost Resistance Totem", note: "Shaman totem: frost resistance", fac: "H" },
  { buff: 10599, dur: 0, cat: "aura", sub: "totem", icon: "spell_nature_natureresistancetotem", name: "Nature Resistance Totem", note: "Shaman totem: nature resistance", fac: "H" },
  { buff: 27683, spells: [27683, 10958], dur: 1200, cat: "raid", icon: "spell_holy_prayerofshadowprotection", name: "Shadow Protection", note: "Priest: shadow resistance (single or group)" },
  { buff: 19896, dur: 0, cat: "aura", icon: "spell_shadow_sealofkings", name: "Shadow Resistance Aura", note: "Paladin: shadow resistance", fac: "A" },
  { buff: 10170, dur: 600, cat: "raid", icon: "spell_holy_flashheal", name: "Amplify Magic", note: "Mage: more healing and spell damage taken" },
  { buff: 10174, dur: 600, cat: "raid", icon: "spell_nature_abolishmagic", name: "Dampen Magic", note: "Mage: less spell damage taken" },
  { buff: 6346, dur: 600, cat: "raid", icon: "spell_holy_excorcism", name: "Fear Ward", note: "Priest (dwarf only): prevents the next fear", fac: "A" },
  // "Eigene" (user 2026-11-14) = Data.lua: buffs a class keeps on itself; exclusive variants (armors) are one icon
  { buff: 10952, dur: 600, cat: "skill", icon: "spell_holy_innerfire", name: "Inner Fire", note: "Priest: armor, attack power", only: ["PRIEST"], selfClass: ["PRIEST"] },
  // mage armors one icon each since 2026-11-15 (user); the mage template has the slot Mage Armor > Ice Armor
  { buff: 22783, dur: 1800, cat: "skill", icon: "spell_magearmor", name: "Mage Armor", note: "Mage: one armor at a time (Mage or Ice Armor)", only: ["MAGE"], selfClass: ["MAGE"] },
  { buff: 10220, spells: [10220, 7301], dur: 1800, cat: "skill", icon: "spell_frost_frostarmor02", name: "Ice Armor", note: "Mage: one armor at a time (Mage or Ice Armor)", only: ["MAGE"], selfClass: ["MAGE"] },
  { buff: 11735, spells: [11735, 696], dur: 1800, cat: "skill", icon: "spell_shadow_ragingscream", name: "Demon Armor", note: "Warlock: Demon Armor (or Demon Skin)", only: ["WARLOCK"], selfClass: ["WARLOCK"] },
  { buff: 25296, dur: 0, cat: "skill", icon: "spell_nature_ravenform", name: "Aspect of the Hawk", note: "Hunter: ranged attack power", only: ["HUNTER"], selfClass: ["HUNTER"] },
  { buff: 16864, dur: 600, cat: "skill", icon: "spell_nature_crystalball", name: "Omen of Clarity", note: "Druid (talent): Clearcasting", only: ["DRUID"], selfClass: ["DRUID"] },
  { buff: 10432, dur: 600, cat: "skill", icon: "spell_nature_lightningshield", name: "Lightning Shield", note: "Shaman: Lightning Shield", only: ["SHAMAN"], selfClass: ["SHAMAN"] },
  { buff: 25780, dur: 1800, cat: "skill", icon: "spell_holy_sealoffury", name: "Righteous Fury", note: "Paladin (tank): more threat", only: ["PALADIN"], selfClass: ["PALADIN"] },
  // "Trinkets" (user 2026-11-17) = Data.lua: buffs of on-use trinkets, icon = the trinket
  { buff: 28866, dur: 15, cat: "trinket", icon: "inv_trinket_naxxramas04", item: 22954, name: "Kiss of the Spider", note: "Naxxramas: +20% attack speed (15 sec)", hide: ["MAGE","WARLOCK","PRIEST"] },
  { buff: 25891, dur: 20, cat: "trinket", icon: "spell_nature_abolishmagic", item: 21180, name: "Earthstrike", note: "Blackwing Lair: +280 attack power (20 sec)", hide: ["MAGE","WARLOCK","PRIEST"] },
  { buff: 28777, dur: 20, cat: "trinket", icon: "inv_trinket_naxxramas03", item: 23041, name: "Slayer's Crest", note: "Naxxramas: +260 attack power (20 sec)", hide: ["MAGE","WARLOCK","PRIEST"] },
  { buff: 29602, spells: [29602, 29604], dur: 20, cat: "trinket", icon: "inv_misc_enggizmos_19", item: 23570, name: "Jom Gabbar", note: "Ahn'Qiraj: +65 attack power every 2 sec (20 sec)", hide: ["MAGE","WARLOCK","PRIEST"] },
  { buff: 26480, dur: 30, cat: "trinket", icon: "inv_misc_ahnqirajtrinket_04", item: 21670, name: "Badge of the Swarmguard", note: "Ahn'Qiraj: armor penetration on hits (30 sec)", hide: ["MAGE","WARLOCK","PRIEST"] },
  { buff: 24662, dur: 20, cat: "trinket", icon: "inv_jewelry_necklace_13", item: 19949, name: "Zandalarian Hero Medallion", note: "Zul'Gurub: +40 damage, less with every hit (20 sec)", hide: ["MAGE","WARLOCK","PRIEST"], aura: { icon: "ability_criticalstrike", name: "Restless Strength", spell: 24662 } },
  { buff: 24352, dur: 20, cat: "trinket", icon: "inv_misc_eye_01", item: 19991, name: "Devilsaur Eye", note: "+150 attack power, +2% hit (20 sec)", only: ["HUNTER"], aura: { icon: "ability_hunter_pet_raptor", name: "Devilsaur Fury", spell: 24352 } },
  { buff: 24427, dur: 60, cat: "trinket", icon: "inv_drink_01", item: 20130, name: "Diamond Flask", note: "+75 Strength (1 min)", only: ["WARRIOR"] },
  { buff: 23725, dur: 20, cat: "trinket", icon: "inv_misc_gem_pearl_05", item: 19341, name: "Lifegiving Gem", note: "Warrior: +15% max. health (20 sec)", only: ["WARRIOR"] },
  { buff: 23726, dur: 20, cat: "trinket", icon: "inv_misc_idol_03", item: 19342, name: "Venomous Totem", note: "Rogue: +30% chance to apply poisons (20 sec)", only: ["ROGUE"], aura: { icon: "spell_totem_wardofdraining", name: "Venomous Totem", spell: 23726 } },
  { buff: 24575, dur: 20, cat: "trinket", icon: "inv_jewelry_necklace_13", item: 19948, name: "Zandalarian Hero Badge", note: "Zul'Gurub: +2000 armor, +30 defense, less with every hit taken (20 sec)", aura: { icon: "spell_shadow_grimward", name: "Brittle Armor", spell: 24575 } },
  { buff: 23506, dur: 20, cat: "trinket", icon: "inv_misc_armorkit_04", item: 19024, name: "Arena Grand Master", note: "Absorbs 750-1250 damage (20 sec)", aura: { icon: "spell_holy_devotionaura", name: "Aura of Protection", spell: 23506 } },
  { buff: 26400, dur: 20, cat: "trinket", icon: "inv_misc_ahnqirajtrinket_03", item: 21647, name: "Fetish of the Sand Reaver", note: "Ahn'Qiraj: -70% threat (20 sec)", aura: { icon: "spell_magic_lesserinvisibilty", name: "Arcane Shroud", spell: 26400 } },
  { buff: 28862, dur: 20, cat: "trinket", icon: "inv_trinket_naxxramas02", item: 23001, name: "Eye of Diminution", note: "Naxxramas: -35% threat (20 sec)", hide: ["WARRIOR","ROGUE","HUNTER"], aura: { icon: "spell_magic_lesserinvisibilty", name: "The Eye of Diminution", spell: 28862 } },
  { buff: 23271, dur: 15, cat: "trinket", icon: "inv_misc_stonetablet_11", item: 18820, name: "Talisman of Ephemeral Power", note: "Molten Core: +175 spell damage and healing (15 sec)", hide: ["WARRIOR","ROGUE","HUNTER"], aura: { icon: "spell_holy_mindvision", name: "Ephemeral Power", spell: 23271 } },
  { buff: 24659, dur: 20, cat: "trinket", icon: "inv_jewelry_necklace_13", item: 19950, name: "Zandalarian Hero Charm", note: "Zul'Gurub: +204 spell damage, less with every cast (20 sec)", hide: ["WARRIOR","ROGUE","HUNTER"], aura: { icon: "spell_lightning_lightningbolt01", name: "Unstable Power", spell: 24659 } },
  { buff: 28779, dur: 20, cat: "trinket", icon: "inv_trinket_naxxramas06", item: 23046, name: "The Restrained Essence of Sapphiron", note: "Naxxramas: +130 spell damage and healing (20 sec)", hide: ["WARRIOR","ROGUE","HUNTER"] },
  { buff: 26166, dur: 30, cat: "trinket", icon: "inv_misc_eye_01", item: 21473, name: "Eye of Moam", note: "Ruins of Ahn'Qiraj: +50 spell damage, -100 target resistances (30 sec)", hide: ["WARRIOR","ROGUE","HUNTER"], aura: { icon: "inv_misc_ahnqirajtrinket_04", name: "Obsidian Insight", spell: 26166 } },
  { buff: 27675, dur: 15, cat: "trinket", icon: "inv_jewelry_talisman_09", item: 22268, name: "Draconic Infused Emblem", note: "+100 spell damage, +190 healing (15 sec)", hide: ["WARRIOR","ROGUE","HUNTER"], aura: { icon: "spell_holy_mindvision", name: "Chromatic Infusion", spell: 27675 } },
  { buff: 24998, dur: 15, cat: "trinket", icon: "inv_misc_gem_stone_01", item: 20636, name: "Hibernation Crystal", note: "+350 healing (15 sec)", hide: ["WARRIOR","ROGUE","HUNTER"], aura: { icon: "spell_nature_healingwavegreater", name: "Healing of the Ages", spell: 24998 } },
  { buff: 24268, dur: 30, cat: "trinket", icon: "inv_zulgurubtrinket", item: 19930, name: "Mar'li's Eye", note: "Zul'Gurub: 60 mana every 5 sec (30 sec)", hide: ["WARRIOR","ROGUE","HUNTER"] },
  { buff: 15646, dur: 10, cat: "trinket", icon: "inv_jewelry_amulet_07", item: 11832, name: "Burst of Knowledge", note: "Spells cost 100 mana less (10 sec)", hide: ["WARRIOR","ROGUE","HUNTER"] },
  { buff: 23723, dur: 20, cat: "trinket", icon: "spell_nature_wispheal", item: 19339, name: "Mind Quickening Gem", note: "Mage: +33% casting speed (20 sec)", only: ["MAGE"] },
  { buff: 23734, dur: 20, cat: "trinket", icon: "inv_misc_gem_03", item: 19344, name: "Natural Alignment Crystal", note: "Shaman: +20% spell damage and healing, +20% mana cost (20 sec)", only: ["SHAMAN"], aura: { icon: "spell_nature_spiritarmor", name: "Nature Aligned", spell: 23734 } },
  { buff: 23733, dur: 20, cat: "trinket", icon: "inv_scroll_08", item: 19343, name: "Scrolls of Blinding Light", note: "Paladin: +25% attack speed, +33% casting speed (20 sec)", only: ["PALADIN"], aura: { icon: "spell_holy_searinglight", name: "Blinding Light", spell: 23733 } },
  { buff: 24543, dur: 20, cat: "trinket", icon: "inv_jewelry_necklace_19", item: 19957, name: "Hazza'rah's Charm of Destruction", note: "Warlock: +10% crit with Destruction spells (20 sec)", only: ["WARLOCK"], aura: { icon: "spell_fire_windsofwoe", name: "Massive Destruction", spell: 24543 } },
  { buff: 23780, dur: 20, cat: "trinket", icon: "spell_holy_blessingofprotection", item: 19345, name: "Aegis of Preservation", note: "Priest: +500 armor, heals when hit (20 sec)", only: ["PRIEST"] },
  // "Procs" (user 2026-11-17) = Data.lua: talent and weapon procs
  { buff: 20007, dur: 15, cat: "proc", icon: "spell_holy_blessingofstrength", name: "Crusader", note: "Crusader enchant (Holy Strength): +100 Strength (15 sec), can be up twice with two weapons", hide: ["MAGE","WARLOCK","PRIEST"], src: [{ icon: "spell_holy_greaterheal", name: "Enchant Weapon - Crusader", spell: 20034 }] },
  { buff: 16551, dur: 3, cat: "proc", icon: "ability_backstab", name: "Felstriker", note: "Weapon proc: every hit lands and crits (3 sec)", hide: ["MAGE","WARLOCK","PRIEST"], src: [{ icon: "inv_weapon_shortblade_25", name: "Felstriker", item: 12590 }] },
  { buff: 21165, dur: 10, cat: "proc", icon: "spell_nature_invisibilty", name: "Empyrean Demolisher", note: "Weapon proc (Haste): +20% attack speed (10 sec)", hide: ["MAGE","WARLOCK","PRIEST"], src: [{ icon: "inv_hammer_05", name: "Empyrean Demolisher", item: 17112 }] },
  { buff: 12970, spells: [12970, 12966, 12967, 12968, 12969, 16280, 16257, 16277, 16278, 16279], dur: 15, cat: "proc", icon: "ability_ghoulfrenzy", name: "Flurry", note: "Talent: up to +30% attack speed after a crit", only: ["WARRIOR","SHAMAN"] },
  { buff: 14204, spells: [14204, 12880, 14201, 14202, 14203], dur: 12, cat: "proc", icon: "spell_shadow_unholyfrenzy", name: "Enrage", note: "Warrior talent: up to +25% melee damage after being crit (12 sec)", only: ["WARRIOR"] },
  { buff: 14149, spells: [14149, 14143], dur: 20, cat: "proc", icon: "ability_fiegndead", name: "Remorseless", note: "Rogue talent: up to +40% crit for the next attack after a kill", only: ["ROGUE"] },
  { buff: 6150, dur: 12, cat: "proc", icon: "ability_warrior_innerrage", name: "Quick Shots", note: "Hunter talent: +30% ranged attack speed (12 sec)", only: ["HUNTER"], src: [{ icon: "spell_nature_ravenform", name: "Improved Aspect of the Hawk", spell: 19552 }] },
  { buff: 12536, spells: [12536, 16870, 16246], dur: 15, cat: "proc", icon: "spell_shadow_manaburn", name: "Clearcasting", note: "Talent proc: the next spell costs no mana", only: ["MAGE","DRUID","SHAMAN"], src: [{ icon: "spell_shadow_manaburn", name: "Arcane Concentration", spell: 11213, class: "MAGE" }, { icon: "spell_nature_crystalball", name: "Omen of Clarity", spell: 16864, class: "DRUID" }, { icon: "spell_shadow_manaburn", name: "Elemental Focus", spell: 16164, class: "SHAMAN" }] },
  { buff: 17941, dur: 10, cat: "proc", icon: "spell_shadow_twilight", name: "Shadow Trance", note: "Warlock talent: the next Shadow Bolt is instant", only: ["WARLOCK"] },
  { buff: 15271, dur: 15, cat: "proc", icon: "spell_shadow_requiem", name: "Spirit Tap", note: "Priest talent: +100% Spirit after a kill (15 sec)", only: ["PRIEST"] },
  { buff: 16886, dur: 15, cat: "proc", icon: "spell_nature_naturesblessing", name: "Nature's Grace", note: "Druid talent: the next spell casts 0.5 sec faster", only: ["DRUID"] },
  { buff: 20055, spells: [20055, 20050, 20052, 20053, 20054], dur: 8, cat: "proc", icon: "ability_racial_avatar", name: "Vengeance", note: "Paladin talent: up to +15% physical and Holy damage after a crit (8 sec)", only: ["PALADIN"] },
  // "Abilities" (user 2026-11-17) = Data.lua: buffs of activated abilities/talents, split off from "Procs"
  { buff: 18499, dur: 10, cat: "skill", sub: "cd", icon: "spell_nature_ancestralguardian", name: "Berserker Rage", note: "Warrior: immune to fear, extra rage (10 sec)", only: ["WARRIOR"] },
  { buff: 29131, dur: 10, cat: "skill", sub: "cd", icon: "ability_racial_bloodrage", name: "Bloodrage", note: "Warrior: 1 rage per second (10 sec)", only: ["WARRIOR"] },
  { buff: 12328, dur: 30, cat: "skill", sub: "cd", icon: "spell_shadow_deathpact", name: "Death Wish", note: "Warrior talent: +20% physical damage, -20% armor (30 sec)", only: ["WARRIOR"] },
  { buff: 1719, dur: 15, cat: "skill", sub: "cd", icon: "ability_criticalstrike", name: "Recklessness", note: "Warrior: +100% crit chance, +20% damage taken (15 sec)", only: ["WARRIOR"] },
  { buff: 20230, dur: 15, cat: "skill", sub: "cd", icon: "ability_warrior_challange", name: "Retaliation", note: "Warrior: counterattacks melee attackers (15 sec, max. 30)", only: ["WARRIOR"] }, // user 2026-11-20
  { buff: 12292, dur: 20, cat: "skill", sub: "cd", icon: "ability_rogue_slicedice", name: "Sweeping Strikes", note: "Warrior talent: the next 5 attacks hit a second target", only: ["WARRIOR"] },
  { buff: 2565, dur: 5, cat: "skill", sub: "cd", icon: "ability_defend", name: "Shield Block", note: "Warrior: +75% block chance for the next attack (5 sec)", only: ["WARRIOR"] },
  { buff: 871, dur: 10, cat: "skill", sub: "cd", icon: "ability_warrior_shieldwall", name: "Shield Wall", note: "Warrior: -75% damage taken (10 sec)", only: ["WARRIOR"] }, // user 2026-11-20
  { buff: 12976, dur: 20, cat: "skill", sub: "cd", icon: "spell_holy_ashestoashes", name: "Last Stand", note: "Warrior talent: +30% max. health (20 sec)", only: ["WARRIOR"] },
  { buff: 6774, spells: [6774, 5171], dur: 21, cat: "skill", sub: "cd", icon: "ability_rogue_slicedice", name: "Slice and Dice", note: "Rogue: +30% attack speed", only: ["ROGUE"] },
  { buff: 13877, dur: 15, cat: "skill", sub: "cd", icon: "ability_warrior_punishingblow", name: "Blade Flurry", note: "Rogue talent: +20% attack speed, hits a second target (15 sec)", only: ["ROGUE"] },
  { buff: 13750, dur: 15, cat: "skill", sub: "cd", icon: "spell_shadow_shadowworddominate", name: "Adrenaline Rush", note: "Rogue talent: +100% energy regeneration (15 sec)", only: ["ROGUE"] },
  { buff: 14177, dur: 0, cat: "skill", sub: "cd", icon: "spell_ice_lament", name: "Cold Blood", note: "Rogue talent: the next attack crits", only: ["ROGUE"] },
  { buff: 3045, dur: 15, cat: "skill", sub: "cd", icon: "ability_hunter_runningshot", name: "Rapid Fire", note: "Hunter: +40% ranged attack speed (15 sec)", only: ["HUNTER"] },
  { buff: 12042, dur: 15, cat: "skill", sub: "cd", icon: "spell_nature_lightning", name: "Arcane Power", note: "Mage talent: +30% spell damage, +30% mana cost (15 sec)", only: ["MAGE"] },
  { buff: 28682, dur: 0, cat: "skill", sub: "cd", icon: "spell_fire_sealoffire", name: "Combustion", note: "Mage talent: rising crit with fire spells", only: ["MAGE"] },
  { buff: 12043, dur: 0, cat: "skill", sub: "cd", icon: "spell_nature_enchantarmor", name: "Presence of Mind", note: "Mage talent: the next spell is instant", only: ["MAGE"] },
  { buff: 14751, dur: 0, cat: "skill", sub: "cd", icon: "spell_frost_windwalkon", name: "Inner Focus", note: "Priest talent: the next spell costs no mana, +25% crit", only: ["PRIEST"] },
  { buff: 10060, dur: 15, cat: "raid", icon: "spell_holy_powerinfusion", name: "Power Infusion", note: "Priest talent: +20% spell damage and healing (15 sec)", hide: ["WARRIOR","ROGUE","HUNTER"] },
  { buff: 17116, spells: [17116, 16188], dur: 0, cat: "skill", sub: "cd", icon: "spell_nature_ravenform", name: "Nature's Swiftness", note: "Talent: the next Nature spell is instant", only: ["DRUID","SHAMAN"] },
  { buff: 16166, dur: 0, cat: "skill", sub: "cd", icon: "spell_nature_wispheal", name: "Elemental Mastery", note: "Shaman talent: the next spell crits and costs no mana", only: ["SHAMAN"] },
  { buff: 20216, dur: 0, cat: "skill", sub: "cd", icon: "spell_holy_heal", name: "Divine Favor", note: "Paladin talent: the next heal crits", only: ["PALADIN"] },
  // "Sonstiges" (user 2026-11-10): buff of the trinket Argent Dawn Commission (item 12846, Wowhead spell 17670)
  { buff: 17670, dur: 0, cat: "misc", icon: "inv_jewelry_talisman_07", name: "Argent Dawn Commission", note: "Argent Dawn trinket: only for Scourgestones, costs a buff slot" },
  // Mount (user 2026-11-17) = Data.lua: one entry for every mount, in the game detected by IsMounted() (ns:MountAura);
  // the mockup knows the simulated mounts of MOUNT_SIM. ID -458 (Brown Horse) only as its ID
  { buff: 458, spells: [23229, 23510, 26656, 24242, 25953, 26054, 472], dur: 0, cat: "misc", icon: "ability_mount_ridinghorse", name: L("Mount"), note: "Any mount: active while mounted, right-click dismounts. Not mounted: Ctrl+click mounts your first 100% mount (else 60%), in AQ40 a Qiraji crystal (red first)", mount: true },
  // Buff counter (user 2026-11-25, = Data/Buffs.lua): the free buff slots as a number on an icon, can go into any row.
  // 990032 is no spell (only gives the entry its ID -990032), it never matches an aura.
  { buff: 990032, dur: 0, cat: "misc", icon: "spell_holy_magicalsentry", name: L("Buff counter"), note: "Shows how many of the 32 buff slots are in use, colored like the bar when slots run short. Drag it into any row.", counter: true },
  // transformations (user 2026-11-10), = Data.lua; Wowhead Classic spell IDs
  { buff: 24708, spells: [24708, 24709, 24710, 24711, 24712, 24713, 24723, 24732, 24735, 24736, 24740, 24741], dur: 3600, cat: "misc", icon: "ability_rogue_disguise", name: "Hallowed Wand Costume", note: "Hallowed Wand: pirate, ninja, leper gnome, skeleton, bat, ghost or wisp costume" },
  { buff: 24924, spells: [24924, 24925, 24926, 24927], dur: 1200, cat: "misc", icon: "inv_misc_food_59", name: "Hallow's End Candy", note: "Hallow's End candy: transformation" },
  { buff: 16591, spells: [16591, 16595, 16593], dur: 600, cat: "misc", icon: "spell_shadow_raisedead", name: "Noggenfogger Elixir", note: "Skeleton, shrunk or slow fall" },
  { buff: 8219, spells: [8219, 8220, 8221, 8222], dur: 3600, cat: "misc", icon: "ability_rogue_disguise", name: "Savory Deviate Delight", note: "Pirate or ninja (Flip Out, Yaaarrrr)" },
  { buff: 16739, dur: 300, cat: "misc", icon: "spell_shadow_antishadow", name: "Orb of Deception", note: "Disguised as another race" },
  { buff: 22736, dur: 600, cat: "misc", icon: "ability_rogue_disguise", name: "Gordok Ogre Suit", note: "Dire Maul: disguised as a Gordok ogre" },
  { buff: 26157, spells: [26157, 26272, 26273, 26274], dur: 1800, cat: "misc", icon: "spell_frost_frostshock", name: "PX-238 Winter Wondervolt", note: "Winter Veil: transformation" },
];
for (const b of BUFFS) { b.id = -b.buff; b.isBuff = true; b.spells = b.spells || [b.buff]; }
const BUFF_BY_ID = Object.fromEntries(BUFFS.map((b) => [b.id, b]));
// = ns.BUFF_FILTERS: categories of the "Buffs" tab (also the section headers)
const BUFF_FILTERS = [
  { label: L("All") },
  { label: L("World Buffs"), cat: "world" },
  // since 2026-11-20 (user, = ns.BUFF_FILTERS): how a buff works, the same for every class; "Situational" / "Own" gone
  { label: L("Raid Buffs"), cat: "raid" }, // a player casts it on others, with a duration (Battle Shout too)
  { label: L("Auras & Totems"), cat: "aura", subs: ["totem"] }, // only in range, no duration; auras first, then totems (sub)
  { label: L("Abilities"), cat: "skill", subs: ["cd"] }, // a class casts it on itself only: long ones first, then cooldowns (sub "cd")
  { label: L("Trinkets"), cat: "trinket" }, // 2026-11-17: buffs of on-use trinkets
  { label: L("Procs"), cat: "proc" }, // 2026-11-17: talent and weapon procs
  { label: L("Misc"), cat: "misc" }, // 2026-11-10: Argent Dawn Commission
];
const playerFaction = "A"; // mockup: simulated faction (Alliance)
const isBuffId = (id) => id < 0;
const buffFits = (b) => (!b.fac || b.fac === playerFaction);
const buffForClass = (b) => !(b.hide && b.hide.includes(playerClass)) && !(b.only && !b.only.includes(playerClass));
// = default of the "Unerwünscht" list per class (useless buffs that only cost a buff slot)
// Argent Dawn Commission (-17670) for every class (user 2026-11-10), = Data.lua. Per class (user 2026-11-10: a mage
// wants Intellect): melee drop Int/Spirit; hunters and casters drop Might, Battle Shout (melee only) and Thorns.
// order (user 2026-11-12, = Data.lua): Argent Dawn Commission first, then class buffs, then transformations
const CASTER_UNWANTED = [-25916, -25289, -9910];
const DEFAULT_UNWANTED = { WARRIOR: [-23028, -27681], ROGUE: [-23028, -27681],
  HUNTER: [-25916, -25289, -27681] };
for (const c of ["MAGE", "WARLOCK", "PRIEST", "DRUID", "PALADIN", "SHAMAN"]) DEFAULT_UNWANTED[c] = CASTER_UNWANTED;
// transformations for every class (user 2026-11-10), order user 2026-11-12
const TRANSFORMS = [-24924, -8219, -22736, -24708, -16591, -26157, -16739];
for (const c of Object.keys(DEFAULT_UNWANTED)) DEFAULT_UNWANTED[c] = [-17670, ...DEFAULT_UNWANTED[c], ...TRANSFORMS];
for (const c of ["WARRIOR", "ROGUE", "MAGE", "PRIEST", "WARLOCK", "HUNTER", "DRUID", "PALADIN", "SHAMAN"]) DEFAULT_UNWANTED[c] = DEFAULT_UNWANTED[c] || [-17670];
// buffs that are not in any catalog: only for the simulation (procs, cooldowns, trinkets, HoTs, shields)
// mounts for the button "Mount" and the simulated bags (2026-11-17; Wowhead Classic spell IDs; item = the mount item,
// 2026-11-19; order = bag order; aq = only usable in AQ40)
const MOUNT_SIM = [
  { buff: 23229, item: 18777, icon: "ability_mount_ridinghorse", name: "Swift Brown Steed" },
  { buff: 23510, item: 19030, icon: "ability_mount_mountainram", name: "Stormpike Battle Charger" },
  { buff: 26656, item: 21176, icon: "inv_misc_qirajicrystal_05", name: "Black Qiraji Battle Tank", itemName: "Black Qiraji Resonating Crystal" },
  { buff: 24242, item: 19872, icon: "ability_mount_raptor", name: "Swift Razzashi Raptor" },
  { buff: 472, item: 2414, icon: "ability_mount_ridinghorse", name: "Pinto", itemName: "Pinto Bridle", slow: true },
  { buff: 25953, item: 21218, icon: "inv_misc_qirajicrystal_04", name: "Blue Qiraji Battle Tank", itemName: "Blue Qiraji Resonating Crystal", aq: true },
  { buff: 26054, item: 21321, icon: "inv_misc_qirajicrystal_02", name: "Red Qiraji Battle Tank", itemName: "Red Qiraji Resonating Crystal", aq: true },
];
// = ns.MOUNT_FAST / ns.MOUNT_QIRAJI in Data.lua (2026-11-19, Wowhead Classic): 100 % mount items, AQ40 crystals (red first)
const MOUNT_FAST = new Set([18777, 18776, 18778, 18786, 18787, 18785, 18772, 18773, 18774, 18766, 18767, 18902, 18796, 18797,
  18798, 18788, 18789, 18790, 18793, 18795, 18794, 18791, 13334, 13335, 19030, 19029, 18241, 18244, 18243, 18242, 18245, 18246,
  18247, 18248, 19872, 19902, 13086, 21176, 12302, 12303, 12330, 12351, 12353, 12354, 13317, 13326, 13327, 13328, 13329, 15292,
  15293, 8586]);
const MOUNT_SLOW = new Set([2414, 2411, 5656, 5655, 5864, 5873, 5872, 5874, 5875, 8563, 8595, 13321, 13322, 13325, 8631, 8632, 8629, 8630,
  8627, 8628, 12325, 12326, 12327, 1132, 5665, 5668, 5663, 8588, 8591, 8592, 8589, 8590, 15290, 15277, 13331, 13332, 13333]); // 60 %, only without any 100 % mount (2026-11-19)
const MOUNT_QIRAJI = [21321, 21218, 21323, 21324, 21176];
const OTHER_SIM = [
  { buff: 12970, dur: 15, icon: "ability_ghoulfrenzy", name: "Flurry", proc: true },
  { buff: 12880, dur: 12, icon: "spell_shadow_unholyfrenzy", name: "Enrage", proc: true },
  { buff: 20007, dur: 15, icon: "spell_holy_blessingofstrength", name: "Holy Strength", proc: true },
  { buff: 2687, dur: 10, icon: "ability_racial_bloodrage", name: "Bloodrage", proc: true },
  { buff: 12328, dur: 30, icon: "spell_shadow_deathpact", name: "Death Wish", proc: true },
  { buff: 1719, dur: 15, icon: "ability_criticalstrike", name: "Recklessness", proc: true },
  { buff: 28866, dur: 15, icon: "inv_trinket_naxxramas04", name: "Kiss of the Spider", proc: true },
  { buff: 25315, dur: 15, icon: "spell_holy_renew", name: "Renew" },
  { buff: 25299, dur: 12, icon: "spell_nature_rejuvenation", name: "Rejuvenation" },
  { buff: 10901, dur: 30, icon: "spell_holy_powerwordshield", name: "Power Word: Shield" },
  { buff: 15363, dur: 15, icon: "spell_holy_layonhands", name: "Inspiration" },
];
// Era buff cap (research 2026-11-09). Rule in the simulation = working assumption of the user: at the cap
// the oldest buff drops, but never Flask, Zanza or world buffs.
const BUFF_CAP = 32;

// = ns.FILTERS in Data.lua; the same entries are the section headers when sorted by type/stat
const FILTERS = [
  { group: "type", label: L("All") },
  { group: "type", label: L("Flasks, Zanza"), cat: "flask" },
  { group: "type", label: L("Elixirs, Jujus, Resistances"), cat: "elixir" },
  { group: "type", label: L("Potions"), cat: "potion" },
  { group: "type", label: L("Food, Alcohol"), cat: "food" },
  { group: "type", label: L("Weapon (stones, oils, poisons)"), cat: "weapon" },
  { group: "type", label: L("Misc"), cat: "other" },
  { group: "stat", label: L("Attack Power / Strength"), stats: ["ap"] },
  { group: "stat", label: L("Agility"), stats: ["agi"] },
  { group: "stat", label: L("Health / Stamina"), stats: ["hp"] },
  { group: "stat", label: L("Health Regeneration"), stats: ["regen"] },
  { group: "stat", label: L("Spirit"), stats: ["spirit"] },
  { group: "stat", label: L("Mana / Intellect"), stats: ["mana"] },
  { group: "stat", label: L("MP5"), stats: ["mp5"] },
  { group: "stat", label: L("Spell Damage / Healing"), stats: ["spell"] },
  { group: "stat", label: L("Armor"), stats: ["armor"] },
  { group: "stat", label: L("Resistance"), stats: ["resist"] },
  { group: "stat", label: L("Misc"), stats: ["speed", "other", "crit", "poison"] },
];
for (const f of FILTERS) {
  f.match = f.cat ? (e) => e.cat === f.cat : f.stats ? (e) => f.stats.some((s) => e.statSet.has(s)) : () => true;
}
// = ns.CATALOG_SORTS in Data.lua (button "Sortierung", saved in RaidKitBuffsDB.catSort)
const CATALOG_SORTS = [
  { key: "alpha", label: L("A-Z") },
  { key: "type", label: L("Type"), group: "type" },
  { key: "stat", label: L("Stats"), group: "stat" },
];
// = ns.ORIENTATIONS in Data.lua (setting orientation, button "Leiste: ..."; proposal 2026-11-09)
const ORIENTATIONS = [
  // columns (vdown/vup) removed 2026-11-14 (user), labels without "Rows"
  { key: "hleft", label: L("Left") },
  { key: "hright", label: L("Right") },
];
// = ns.NAME_ALIGNS in Data.lua (2026-11-15, user): alignment of the group name only, the icons have ORIENTATIONS
const NAME_ALIGNS = [
  { key: "left", label: L("Left") },
  { key: "center", label: L("Center") },
  { key: "right", label: L("Right") },
];
// = PREVIEW_ICONS in OptionsRefresh.lua (2026-11-15, user): grey examples on the Layout tab of "Other" and "Debuffs"
// (buffs/debuffs no row covers; all in Classic Era, checked on Wowhead)
const PREVIEW_ICONS = {
  other: ["spell_holy_powerinfusion", "spell_nature_lightning", "inv_trinket_naxxramas04", "spell_nature_abolishmagic", "spell_nature_wispheal"],
  debuff: ["spell_holy_ashestoashes", "spell_holy_removecurse", "inv_misc_bandage_08"],
};
const PREVIEW_MAX = 17; // the label "Preview" keeps the end of the line
// = ns.OTHER_DOCKS in Data.lua (setting otherDock, button "Sonstige: ..."): where the buff area docks
const OTHER_DOCKS = [
  { key: "bottom", label: L("bottom") },
  { key: "top", label: L("top") },
  { key: "left", label: L("left") },
  { key: "right", label: L("right") },
];
// = ns.ROW_NAME_POSITIONS in Data.lua (setting rowNamePos, button "Namen: ..." in the options)
const ROW_NAME_POSITIONS = [
  { key: "left", label: L("Left") },
  { key: "right", label: L("Right") },
  { key: "topleft", label: L("Top left") },
  { key: "topright", label: L("Top right") },
  { key: "bottomleft", label: L("Bottom left") },
  { key: "bottomright", label: L("Bottom right") },
];
// = ns.CATALOG_LISTS in Data.lua: Alle, Raid, Raid: <class> (filled after CLASS_HIDE)
const CATALOG_LISTS = [];
/*RAID-START*/
// generated from Data.lua ns.RAID_ITEMS (tools\sync-mockup-catalog.ps1)
const RAID_ITEMS = new Set([13510, 13511, 13512, 13513, 9206, 13453, 12820, 13452, 9187, 3825, 20004, 13445, 9088, 9179, 13447, 20007, 13454, 21546, 17708, 9264, 13458, 13457, 13456, 13459, 13461, 13455, 13442, 5634, 20008, 3387, 9030, 9036, 20452, 13810, 13928, 21023, 18045, 12218, 17222, 12215, 12216, 18254, 13931, 12217, 22237, 22236, 22238, 22239, 21151, 18284, 12451, 12460, 12455, 12457, 12458, 20079, 8410, 8412, 8411, 8423, 8424, 18262, 12404, 12643, 23122, 20749, 20748, 23123, 8928, 20844]);
/*RAID-END*/
// = ns.CLASS_HIDE in Data.lua: hidden primary stats in "Raid: <class>"
const MELEE_HIDE = new Set(["mana", "mp5", "spell", "spirit"]), CASTER_HIDE = new Set(["ap", "agi"]);
const CLASS_HIDE = { WARRIOR: MELEE_HIDE, ROGUE: MELEE_HIDE, HUNTER: new Set(["spell", "spirit"]), PALADIN: new Set(), DRUID: new Set(), SHAMAN: new Set(), MAGE: CASTER_HIDE, WARLOCK: CASTER_HIDE, PRIEST: CASTER_HIDE };
const CLASS_ORDER = ["WARRIOR", "ROGUE", "HUNTER", "PALADIN", "DRUID", "SHAMAN", "MAGE", "WARLOCK", "PRIEST"];
// weapon enchants (2026-11-09): poisons only for rogues; raid list gets the raid-worthy stones, oils and poisons
for (const c of CLASS_ORDER) if (c !== "ROGUE") CLASS_HIDE[c] = new Set([...CLASS_HIDE[c], "poison"]);
for (const id of [18262, 12404, 12643, 23122, 20749, 20748, 23123, 8928, 20844]) RAID_ITEMS.add(id);

// = ns.ClassLabel (the client's localized class names; the mockup uses the fallback table of Data.lua)
const CLASS_NAMES = { WARRIOR: L("Warrior"), ROGUE: L("Rogue"), HUNTER: L("Hunter"), PALADIN: L("Paladin"), DRUID: L("Druid"), SHAMAN: L("Shaman"), MAGE: L("Mage"), WARLOCK: L("Warlock"), PRIEST: L("Priest") };
CATALOG_LISTS.push({ key: "all", label: L("All") }, { key: "raid", label: L("Raid"), raid: true },
  ...CLASS_ORDER.map((t) => ({ key: "raid:" + t, label: fmt(L("Raid: %s"), CLASS_NAMES[t]), raid: true, cls: t })));
// mockup: simulated player class; another one via the address, e.g. raidkit_buffs.html?class=MAGE (2026-11-10)
const playerClass = (() => { const c = (new URLSearchParams(location.search).get("class") || "").toUpperCase(); return CLASS_NAMES[c] ? c : "WARRIOR"; })();

// = ns.IsOwnBuff in Core.lua (2026-11-14): Battle Shout (self) or a class buff of the player's class (selfClass)
const isOwnBuff = (x) => !!x && (!!x.self || (x.selfClass || []).includes(playerClass));
// = OWN_BUFFS in Data.lua: what a class casts on itself, at the front of "Selbst verantwortlich" (user 2026-11-14)
const OWN_BUFFS = { PRIEST: [-21564, -27681, -10952], MAGE: [-23028, [-22783, -10220]], DRUID: [-21850, -16864], HUNTER: [-20906, -25296],
  WARLOCK: [-11735], SHAMAN: [-10432] };
// = SelfRow in Data.lua: "Selbst verantwortlich" (user 2026-11-14), "Buffs" + "Essen & Co" in one row, own buffs first.
// visible = place in a new profile: 1 "Selbst verantwortlich", 2 "Raidbuffs", 3 "Weltbuffs" (user 2026-11-14)
// name (user 2026-11-18, before "Personal"): the role of the template, else the class (= SelfRow in Data.lua):
// warrior "Tank" (the old template "Tank" is gone), priest/druid/paladin/shaman "Healer", the others the class
// split (user 2026-11-20, = SelfRow in Templates.lua): separator "Gap" before the first food, aligned both sides
const selfRow = (own, buffs, food, name) => ({ name, visible: 1, noAltsFrom: own.length + buffs.length + 1, split: own.length + buffs.length, items: [...own, ...buffs, ...food] });
// = ns.ROW_TEMPLATES in Data.lua (menu "+"); a new profile gets all, only "visible" ones shown
const WARRIOR_BUFFS = [13510, 20079, 13452, 13445, 3825, 12460, 12451];
// weapon slots (user 2026-11-09: in "Essen & Co"): off hand only, Elemental -> Dense Sharpening Stone
// Dirge's Kickin' Chimaerok Chops removed 2026-11-10 (user); Dumplings -> Sunfruit, Rum -> Grog (user 2026-11-10)
const WARRIOR_FOOD = [{ v: [20452, 13810, 13928, 21023, 12215, 12218, 12216, 17222, 18045] }, { v: [21151, 18269] }, { v: [18262, 12404, 12643], hand: "off" }];
const ROW_TEMPLATES = {
  WARRIOR: [
    // items with an entry in DEFAULT_ALTS become slots (templateItems = ns.TemplateItems)
    { name: L("Buffs"), items: [...WARRIOR_BUFFS] }, // not in a new profile since 2026-11-14 (user)
    { name: L("Food & Co"), noAlts: true, items: [...WARRIOR_FOOD] },
    // Battle Shout first from 2026-11-14 to 2026-11-18 (user), now in its own group "Battle Shout" (template below)
    selfRow([], WARRIOR_BUFFS, WARRIOR_FOOD, L("Tank")),
    { name: L("Blasted Lands"), items: [8410, 8412, 8411] },
    // + the resistance buffs of the removed "Situativ" (2026-11-18, user; Amplify Magic to "Raidbuffs", Fear Ward gone)
    // in a new profile hidden, potions left | resistances right (user 2026-11-19)
    { name: L("Protection"), visible: 4, hidden: true, split: 5, sepStyle: "icon", items: [13461, 13458, 13459, 13457, 13456, -19900, -10535, -19898, -10477, -10599, -27683] },
    { name: L("Combat"), items: [13455, 13442, 3387, 5634] },
    { name: L("DPS"), items: [13452, 12451, 12460, 20452] },
    // rows with foreign buffs (negative IDs, no alternatives); buffs of the other faction are dropped. Since 2026-11-11 every
    // row takes consumables and buffs (no row kind any more)
    // order of the user (2026-11-10): Songflower, Rend, Ony, ZG, Fengus, Mol'dar, DMF
    { name: L("World Buffs"), visible: 3, splitLast: 2, sepStyle: "icon", items: [-15366, -16609, -22888, -24425, -22817, -22818, -23768, -990032, -349981] }, // + Chronoboon (2026-11-17), right of the separator (2026-11-19); buff counter left of it (2026-11-25)
    // order of the user 2026-11-12 (= Data.lua); Battle Shout removed 2026-11-14 (own buff, "Selbst verantwortlich")
    // Trueshot before LotP (2026-11-17), Amplify Magic at the end (2026-11-18); "Situativ" removed 2026-11-18 (user)
    { name: L("Raid Buffs"), visible: 2, splitLast: 1, sepStyle: "icon", items: [-21564, -21850, -20906, -24932, -25362, -25360, -25898, -25916, -10170] }, // Amplify Magic right (2026-11-19)
    // Battle Shout alone (user 2026-11-18): in a new profile the only row of the group "shout" (CLASS_GROUPS)
    { name: L("Battle Shout"), visible: 5, group: "shout", items: [-25289] },
  ],
};
// = ns.CLASS_GROUPS in Data.lua (user 2026-11-18): groups a new profile of a class gets besides Buffs & Cons and the
// areas; snap/side/align = default place (ensureGroups), the rest are group values
const CLASS_GROUPS = {
  WARRIOR: [{ id: "shout", name: "Battle Shout", iconSize: 64, snap: "main", side: "left", align: "end" }], // big, bottom left
};
// = BuffRows() in Data.lua (user 2026-11-10): three buff rows for every other class, by the usual raid role in Era
// (rogue/hunter physical, mage/warlock spell damage, priest/druid/paladin/shaman healer). Consumable rows (2026-11-10)
// like the warrior's: "Buffs", "Essen & Co" (weapon oil/poison) visible, "Schutz", "Blasted Lands", "Kampf" hidden.
{
  const WORLD_COMMON = [-15366, -16609, -22888, -24425]; // Songflower, Rend, Ony, ZG (user 2026-11-10)
  const WORLD = { physical: [-22817, -22818, -23768], caster: [-22820, -22818, -23768], healer: [-22820, -22818, -23766] };
  const RAID = {
    ROGUE: [-25289, -21564, -21850, -25898, -25916, -25895, -25362, -25360, -20906, -24932], // Trueshot before LotP (2026-11-17)
    HUNTER: [-21564, -21850, -25898, -25895, -23028, -25360, -20906, -24932],
    caster: [-21564, -21850, -25898, -25895, -23028, -27681],
    healer: [-21564, -21850, -25898, -25895, -23028, -27681],
  };
  const SITU_COMMON = [-19900, -10535, -19898, -10477, -10599, -27683];
  const buffRows = (world, raid) => [
    { name: L("World Buffs"), visible: 3, splitLast: 2, sepStyle: "icon", items: [...WORLD_COMMON, ...world, -990032, -349981] }, // + Chronoboon at the end (2026-11-17), separated (2026-11-19); buff counter left of it (2026-11-25)
    { name: L("Raid Buffs"), visible: 2, splitLast: 1, sepStyle: "icon", items: [...raid, -10170] }, // + Amplify Magic right (2026-11-20, = warrior)
  ]; // "Situativ" removed 2026-11-18 (user): SITU_COMMON is part of "Schutz"
  const PROTECTION = [13461, 13458, 13459, 13457, 13456];
  const consumableRows = (name, buffs, food, blasted, combat, own) => [
    { name: L("Buffs"), items: [...buffs] }, // not in a new profile since 2026-11-14 (user)
    { name: L("Food & Co"), noAlts: true, items: [...food] }, // no alternatives (user 2026-11-10)
    selfRow(own || [], buffs, food, name),
    { name: L("Blasted Lands"), items: [...blasted] },
    { name: L("Protection"), visible: 4, hidden: true, split: PROTECTION.length, sepStyle: "icon", items: [...PROTECTION, ...SITU_COMMON] }, // + resistance buffs (2026-11-18); new profile: hidden, separated (2026-11-19)
    { name: L("Combat"), items: [...combat] },
  ];
  const BLASTED = { physical: [8410, 8412, 8411], hunter: [8412, 8411], caster: [8423, 8424, 8411] };
  // slots with their alternative for "Essen & Co" (noAlts, user 2026-11-10) = DUMPLINGS() / RUM() in Data.lua
  // food buffs never stack in Classic (user 2026-11-14): one food slot per template = SQUID() / RUNN_TUM() / NIGHTFIN() in Data.lua
  const SQUID = () => ({ v: [13928, 20452, 13810, 21023, 12215, 12218, 12216, 17222, 18045] }), // rogue: Squid first, then the Dumplings slot
    RUNN_TUM = () => ({ v: [18254, 13931] }), NIGHTFIN = () => ({ v: [13931, 18254] }),
    RUM = () => ({ v: [21151, 18269] });
  // Zanza always right of the flask (user 2026-11-14, every class)
  const CONSUMABLES = {
    ROGUE: consumableRows(L("Rogue"), [20079, 13452, 12451, 12460],
      [SQUID(), RUM(), { v: [8928], hand: "main" }, { v: [20844], hand: "off" }], BLASTED.physical, [5634, 20008, 3387]),
    HUNTER: consumableRows(L("Hunter"), [20079, 13452, 12460], [13928, RUM()], BLASTED.hunter, [5634, 20008, 3387], OWN_BUFFS.HUNTER),
    MAGE: consumableRows(L("Mage"), [13512, 20079, 13454, 21546, 17708], [RUNN_TUM(), RUM(), { v: [20749], hand: "main" }], BLASTED.caster, [5634, 20008], OWN_BUFFS.MAGE),
    WARLOCK: consumableRows(L("Warlock"), [13512, 20079, 13454, 9264], [RUNN_TUM(), RUM(), { v: [20749], hand: "main" }], BLASTED.caster, [5634, 20008], OWN_BUFFS.WARLOCK),
  };
  const HEALER = (c) => consumableRows(L("Healer"), [13511, 20079, 20007, 9179, 12458], [NIGHTFIN(), RUM(), { v: [20748], hand: "main" }], BLASTED.caster, [5634, 20008], OWN_BUFFS[c]);
  ROW_TEMPLATES.ROGUE = [...CONSUMABLES.ROGUE, ...buffRows(WORLD.physical, RAID.ROGUE)];
  ROW_TEMPLATES.HUNTER = [...CONSUMABLES.HUNTER, ...buffRows(WORLD.physical, RAID.HUNTER)];
  for (const c of ["MAGE", "WARLOCK"]) ROW_TEMPLATES[c] = [...CONSUMABLES[c], ...buffRows(WORLD.caster, RAID.caster)];
  for (const c of ["PRIEST", "DRUID", "PALADIN", "SHAMAN"]) ROW_TEMPLATES[c] = [...HEALER(c), ...buffRows(WORLD.healer, RAID.healer)];
  // = OWN_BUFFS filter in Data.lua (user 2026-11-14): "Raidbuffs" = buffs from others, own buffs only in "Selbst verantwortlich"
  OWN_BUFFS.WARRIOR = [-25289];
  for (const [c, list] of Object.entries(ROW_TEMPLATES)) {
    const own = new Set(OWN_BUFFS[c] || []);
    // = ns.FrontRaidBuffs (user 2026-11-14): Stamina, Intellect, Spirit, Gift of the Wild first, the rest keeps its order
    const FRONT = [-21564, -23028, -27681, -21850];
    for (const t of list) if (t.name === L("Raid Buffs")) {
      const kept = t.items.filter((id) => !own.has(id));
      t.items = [...FRONT.filter((id) => kept.includes(id)), ...kept.filter((id) => !FRONT.includes(id))];
    }
  }
}
const PROFILE_DEFAULTS = {
  iconSize: 30, spacing: 4, scale: 1, rowSpacing: 4, rowNamePos: "topleft", // icon sizes 30 everywhere since 2026-11-10
  showMode: "raid", useMode: "ctrl", showRowNames: false /* off since 2026-11-15 (user) */, showCount: false /* off since 2026-11-14 (user) */, showBorders: false, // "raid" since 2026-11-10 (before "group")
  showOther: true, perLine: 0, /* sizes of Sonstige and Debuffs: on their groups since 2026-11-12 */ orientation: "hright" /* since 2026-11-14 (user's layout), before "hleft" */, nameAlign: "right" /* group name, 2026-11-15 */, otherDock: "bottom", unwanted: DEFAULT_UNWANTED[playerClass] || [],
  point: ["TOP", "UIParent", "TOP", 0, -25, "outline"], // = Core.lua (2026-11-21, user: top middle, about 1 cm gap)
  groupPos: {}, // positions of the other groups (proposal 2026-11-11, character key like point)
  showGroupName: false, showTime: true, timeSize: 8, /* 8 since 2026-11-15 (user; before 10) */ // "Alle Gruppen" defaults for groups (2026-11-14)
};
// Values of a group (2026-11-14 until session 20 inherited from "Alle Gruppen"; since session 20, user, every group
// decides on its own: no own value = the default of the addon, PROFILE_DEFAULTS). group key -> key in PROFILE_DEFAULTS.
// = MigrateAllGroups in Core.lua moves old values of "Alle Gruppen" into the groups.
const GROUP_INHERIT = {
  // showCount is no longer inherited since session 20 (user: per group only, = MigrateBagCount in Core.lua)
  showName: "showGroupName", rowNames: "showRowNames", showTime: "showTime", timeSize: "timeSize",
  iconSize: "iconSize", spacing: "spacing", scale: "scale", perLine: "perLine", rowSpacing: "rowSpacing",
};
// = ns.ROW_PER_LINE / ns.GDefault in Rows.lua (user 2026-11-20): groups with rows have 12 places per row by default,
// the buff areas keep 0 (= as many as fit); null g = the profile default
const ROW_PER_LINE = 12;
function gDefault(g, k) {
  if (k === "perLine" && g && !g.area) return ROW_PER_LINE;
  return PROFILE_DEFAULTS[GROUP_INHERIT[k]] ?? (k === "perLine" ? 0 : null);
}
// value that counts for group g: its own value, else its default
function gEff(g, k) {
  if (g && g[k] != null) return g[k];
  return gDefault(g, k);
}
