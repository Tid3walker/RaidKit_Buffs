-- RaidKit Buffs: Data - Buffs
-- Foreign buffs (catalog tab "Buffs"), buff filters, default unwanted buffs, buff cap, mounts, preprocessing
-- (ns.buffCatalog). Split from Data.lua on 2026-11-20.

local _, ns = ...
local L = ns.L

------------------------------------------------------------------------
-- Foreign buffs (catalog tab "Buffs", proposal 2026-11-09, see Docs/Roadmap.md)
-- Not items: in rows a buff is stored as a NEGATIVE number = -(main spell ID), so slots, drag & drop and
-- export keep working. Buff rows have no alternatives: the single and the group version of one buff are
-- ONE entry (spells = every spell ID that counts, main spell first). Only buffs worth preparing before a
-- pull (>= 10 min, like the raid list) plus Battle Shout; short ones (HoTs, shields ...) appear in the
-- area "Sonstige" below the bar. Exception since 2026-11-17: the categories trinket and proc (short effects on
-- purpose, for an own proc row/group). Detection: spell IDs (highest rank) or the localized buff NAME of these
-- spells, so lower ranks count too. All IDs checked against Wowhead Classic (2026-11-09).
--   cat   world / raid / situ / own (2026-11-14) / trinket / proc / skill (2026-11-17) / misc
--   hide  classes that do not need it (list), only = only these classes
--   fac   "A" = Alliance only, "H" = Horde only (paladins/shamans); other faction: never shown
--   self  the player casts it himself (Ctrl+click casts the spell)
--   selfClass  (2026-11-14) the same, but only for these classes (priest Fortitude, mage Intellect ...); others
--         see it as a foreign buff. selfCast = spell cast by Ctrl+click (the single-target version, highest rank by
--         name, on the player), else spells[1]; a list = the first one the player knows. ns.IsOwnBuff and
--         ns.OwnCastName in Core.lua
--   dur   duration in seconds (0 = aura/totem without duration; info/mockup)
--   sub   (2026-11-20) part of its category: entries without sub come first, then each sub of the category's subs
--         (ns.BUFF_FILTERS), each part sorted A-Z with a faint line before it (aura: "totem", skill: "cd" = cooldowns)
--   tipSpell  (2026-11-14) spell whose tooltip is shown while the buff is missing; the aura spells of totems and
--         Leader of the Pack have no description, the totem/talent spell has (with the effect)
-- Deliberately missing: Traces of Silithyst (no effect in instances).
------------------------------------------------------------------------

local NO_MELEE_CASTER = { "MAGE", "WARLOCK", "PRIEST" }
local NO_MELEE = { "WARRIOR", "ROGUE", "HUNTER" } -- casters only (spell damage trinkets ...)
ns.BUFFS = {
    { spells = { 22888 }, dur = 7200, cat = "world", icon = "inv_misc_head_dragon_01", name = "Rallying Cry of the Dragonslayer", note = L["Onyxia/Nefarian: crit, spell crit, AP"] },
    { spells = { 16609 }, dur = 3600, cat = "world", icon = "spell_arcane_teleportorgrimmar", name = "Warchief's Blessing", note = L["Rend: health, attack speed, MP5"] },
    { spells = { 24425 }, dur = 7200, cat = "world", icon = "ability_creature_poison_05", name = "Spirit of Zandalar", note = L["Heart of Hakkar: +15% stats"] },
    { spells = { 15366 }, dur = 3600, cat = "world", icon = "spell_holy_mindvision", name = "Songflower Serenade", note = L["Crit, spell crit, stats"] },
    { spells = { 22817 }, dur = 7200, cat = "world", icon = "spell_nature_undyingstrength", name = "Fengus' Ferocity", note = L["Dire Maul: +200 AP"] },
    { spells = { 22818 }, dur = 7200, cat = "world", icon = "spell_nature_massteleport", name = "Mol'dar's Moxie", note = L["Dire Maul: +15% Stamina"] },
    { spells = { 22820 }, dur = 7200, cat = "world", icon = "spell_holy_lesserheal02", name = "Slip'kik's Savvy", note = L["Dire Maul: +3% spell crit"], hide = { "WARRIOR", "ROGUE", "HUNTER" } },
    { spells = { 23768 }, dur = 7200, cat = "world", icon = "inv_misc_orb_02", name = "Sayge's Dark Fortune of Damage", note = L["Darkmoon: +10% damage"] },
    { spells = { 23736 }, dur = 7200, cat = "world", icon = "inv_misc_orb_02", name = "Sayge's Dark Fortune of Agility", note = L["Darkmoon: +10% Agility"] },
    { spells = { 23735 }, dur = 7200, cat = "world", icon = "inv_misc_orb_02", name = "Sayge's Dark Fortune of Strength", note = L["Darkmoon: +10% Strength"] },
    { spells = { 23737 }, dur = 7200, cat = "world", icon = "inv_misc_orb_02", name = "Sayge's Dark Fortune of Stamina", note = L["Darkmoon: +10% Stamina"] },
    { spells = { 23767 }, dur = 7200, cat = "world", icon = "inv_misc_orb_02", name = "Sayge's Dark Fortune of Armor", note = L["Darkmoon: +10% armor"] },
    { spells = { 23769 }, dur = 7200, cat = "world", icon = "inv_misc_orb_02", name = "Sayge's Dark Fortune of Resistance", note = L["Darkmoon: +25 resistances"] },
    { spells = { 23766 }, dur = 7200, cat = "world", icon = "inv_misc_orb_02", name = "Sayge's Dark Fortune of Intelligence", note = L["Darkmoon: +10% Intellect"], hide = { "WARRIOR", "ROGUE" } },
    { spells = { 23738 }, dur = 7200, cat = "world", icon = "inv_misc_orb_02", name = "Sayge's Dark Fortune of Spirit", note = L["Darkmoon: +10% Spirit"], hide = { "WARRIOR", "ROGUE", "HUNTER" } },
    -- Supercharged Chronoboon Displacer (user 2026-11-17): the buff that holds the world buffs suspended by the Chronoboon
    -- Displacer (Wowhead spell 349981, icon of the item). Costs a slot; the user tested that it cannot be removed.
    { spells = { 349981 }, dur = 0, cat = "world", icon = "inv_misc_enggizmos_24", name = "Supercharged Chronoboon Displacer", note = L["Holds the world buffs suspended by the Chronoboon Displacer"] },

    { spells = { 21564, 10938 }, dur = 3600, cat = "raid", icon = "spell_holy_prayeroffortitude", name = "Fortitude", note = L["Priest: Stamina (single or group)"], selfClass = { "PRIEST" }, selfCast = 10938 },
    { spells = { 21850, 9885 }, dur = 3600, cat = "raid", icon = "spell_nature_regeneration", name = "Mark / Gift of the Wild", note = L["Druid: stats, armor, resistances (single or group)"], selfClass = { "DRUID" }, selfCast = 9885 },
    { spells = { 25289 }, dur = 120, cat = "raid", icon = "ability_warrior_battleshout", name = "Battle Shout", note = L["Warrior: melee attack power (group)"], hide = NO_MELEE_CASTER, selfClass = { "WARRIOR" } }, -- every melee class (2026-11-20, before only = WARRIOR, self = true)
    { spells = { 25898, 20217 }, dur = 900, cat = "raid", icon = "spell_magic_greaterblessingofkings", name = "Blessing of Kings", note = L["Paladin: +10% stats (greater blessing too)"], fac = "A" },
    { spells = { 25916, 25291 }, dur = 900, cat = "raid", icon = "spell_holy_greaterblessingofkings", name = "Blessing of Might", note = L["Paladin: attack power (greater blessing too)"], fac = "A", hide = NO_MELEE_CASTER },
    { spells = { 25895, 1038 }, dur = 900, cat = "raid", icon = "spell_holy_greaterblessingofsalvation", name = "Blessing of Salvation", note = L["Paladin: -30% threat (greater blessing too)"], fac = "A" },
    { spells = { 25362 }, dur = 0, cat = "aura", sub = "totem", icon = "spell_nature_earthbindtotem", name = "Strength of Earth", note = L["Shaman totem: Strength"], tipSpell = 25361, fac = "H", hide = NO_MELEE_CASTER },
    { spells = { 25360 }, dur = 0, cat = "aura", sub = "totem", icon = "spell_nature_invisibilitytotem", name = "Grace of Air", note = L["Shaman totem: Agility"], tipSpell = 25359, fac = "H", hide = NO_MELEE_CASTER },
    { spells = { 20906 }, dur = 0, cat = "aura", icon = "ability_trueshot", name = "Trueshot Aura", note = L["Hunter: attack power (group)"], hide = NO_MELEE_CASTER, selfClass = { "HUNTER" } },
    { spells = { 24932 }, dur = 0, cat = "aura", icon = "spell_nature_unyeildingstamina", name = "Leader of the Pack", note = L["Druid (cat/bear): +3% crit (group)"], tipSpell = 17007, hide = NO_MELEE_CASTER },
    { spells = { 9910 }, dur = 600, cat = "raid", icon = "spell_nature_thorns", name = "Thorns", note = L["Druid: nature damage to attackers"] },
    { spells = { 23028, 10157 }, dur = 3600, cat = "raid", icon = "spell_holy_arcaneintellect", name = "Arcane Intellect", note = L["Mage: Intellect (single or group)"], hide = { "WARRIOR", "ROGUE" }, selfClass = { "MAGE" }, selfCast = 10157 },
    { spells = { 27681, 27841 }, dur = 3600, cat = "raid", icon = "spell_holy_prayerofspirit", name = "Divine Spirit", note = L["Priest: Spirit (single or group)"], hide = { "WARRIOR", "ROGUE", "HUNTER" }, selfClass = { "PRIEST" }, selfCast = 27841 },

    { spells = { 19900 }, dur = 0, cat = "aura", icon = "spell_fire_sealoffire", name = "Fire Resistance Aura", note = L["Paladin: fire resistance"], fac = "A" },
    { spells = { 10535 }, dur = 0, cat = "aura", sub = "totem", icon = "spell_fireresistancetotem_01", name = "Fire Resistance Totem", note = L["Shaman totem: fire resistance"], tipSpell = 10538, fac = "H" },
    { spells = { 19898 }, dur = 0, cat = "aura", icon = "spell_frost_wizardmark", name = "Frost Resistance Aura", note = L["Paladin: frost resistance"], fac = "A" },
    { spells = { 10477 }, dur = 0, cat = "aura", sub = "totem", icon = "spell_frostresistancetotem_01", name = "Frost Resistance Totem", note = L["Shaman totem: frost resistance"], tipSpell = 10479, fac = "H" },
    { spells = { 10599 }, dur = 0, cat = "aura", sub = "totem", icon = "spell_nature_natureresistancetotem", name = "Nature Resistance Totem", note = L["Shaman totem: nature resistance"], tipSpell = 10601, fac = "H" },
    { spells = { 27683, 10958 }, dur = 1200, cat = "raid", icon = "spell_holy_prayerofshadowprotection", name = "Shadow Protection", note = L["Priest: shadow resistance (single or group)"] },
    { spells = { 19896 }, dur = 0, cat = "aura", icon = "spell_shadow_sealofkings", name = "Shadow Resistance Aura", note = L["Paladin: shadow resistance"], fac = "A" },
    { spells = { 10170 }, dur = 600, cat = "raid", icon = "spell_holy_flashheal", name = "Amplify Magic", note = L["Mage: more healing and spell damage taken"] },
    { spells = { 10174 }, dur = 600, cat = "raid", icon = "spell_nature_abolishmagic", name = "Dampen Magic", note = L["Mage: less spell damage taken"] },
    { spells = { 6346 }, dur = 600, cat = "raid", icon = "spell_holy_excorcism", name = "Fear Ward", note = L["Priest (dwarf only): prevents the next fear"], fac = "A" },

    -- "Eigene" (user 2026-11-14): buffs a class keeps on itself, for "Selbst verantwortlich". Variants that exclude each
    -- other (only one armor at a time) are one icon: active if any of them is up; Ctrl+click casts the first one in
    -- selfCast the player knows (ns.OwnCastName). IDs and texts from Wowhead Classic 2026-11-14.
    { spells = { 10952 }, dur = 600, cat = "skill", icon = "spell_holy_innerfire", name = "Inner Fire", note = L["Priest: armor, attack power"], only = { "PRIEST" }, selfClass = { "PRIEST" } },
    -- mage armors: one icon each since 2026-11-15 (user: Ice Armor showed the Mage Armor icon); the mage template has
    -- them as one slot Mage Armor > Ice Armor, the active one is shown. Frost Armor = Ice Armor of low levels.
    { spells = { 22783 }, dur = 1800, cat = "skill", icon = "spell_magearmor", name = "Mage Armor", note = L["Mage: one armor at a time (Mage or Ice Armor)"], only = { "MAGE" }, selfClass = { "MAGE" }, selfCast = 22783 },
    { spells = { 10220, 7301 }, dur = 1800, cat = "skill", icon = "spell_frost_frostarmor02", name = "Ice Armor", note = L["Mage: one armor at a time (Mage or Ice Armor)"], only = { "MAGE" }, selfClass = { "MAGE" }, selfCast = { 10220, 7301 } },
    { spells = { 11735, 696 }, dur = 1800, cat = "skill", icon = "spell_shadow_ragingscream", name = "Demon Armor", note = L["Warlock: Demon Armor (or Demon Skin)"], only = { "WARLOCK" }, selfClass = { "WARLOCK" }, selfCast = { 11735, 696 } },
    { spells = { 25296 }, dur = 0, cat = "skill", icon = "spell_nature_ravenform", name = "Aspect of the Hawk", note = L["Hunter: ranged attack power"], only = { "HUNTER" }, selfClass = { "HUNTER" } },
    { spells = { 16864 }, dur = 600, cat = "skill", icon = "spell_nature_crystalball", name = "Omen of Clarity", note = L["Druid (talent): Clearcasting"], only = { "DRUID" }, selfClass = { "DRUID" } },
    { spells = { 10432 }, dur = 600, cat = "skill", icon = "spell_nature_lightningshield", name = "Lightning Shield", note = L["Shaman: Lightning Shield"], only = { "SHAMAN" }, selfClass = { "SHAMAN" } },
    { spells = { 25780 }, dur = 1800, cat = "skill", icon = "spell_holy_sealoffury", name = "Righteous Fury", note = L["Paladin (tank): more threat"], only = { "PALADIN" }, selfClass = { "PALADIN" } },

    -- "Trinkets" (user 2026-11-17): buffs of on-use trinkets, icon = the trinket. IDs from Wowhead Classic 2026-11-17;
    -- tipSpell = the use spell where the aura spell has no description. No click action (user 2026-11-17).
    { spells = { 28866 }, dur = 15, cat = "trinket", icon = "inv_trinket_naxxramas04", item = 22954, name = "Kiss of the Spider", note = L["Naxxramas: +20% attack speed (15 sec)"], hide = NO_MELEE_CASTER },
    { spells = { 25891 }, dur = 20, cat = "trinket", icon = "spell_nature_abolishmagic", item = 21180, name = "Earthstrike", note = L["Blackwing Lair: +280 attack power (20 sec)"], hide = NO_MELEE_CASTER },
    { spells = { 28777 }, dur = 20, cat = "trinket", icon = "inv_trinket_naxxramas03", item = 23041, name = "Slayer's Crest", note = L["Naxxramas: +260 attack power (20 sec)"], hide = NO_MELEE_CASTER },
    { spells = { 29602, 29604 }, dur = 20, cat = "trinket", icon = "inv_misc_enggizmos_19", item = 23570, name = "Jom Gabbar", note = L["Ahn'Qiraj: +65 attack power every 2 sec (20 sec)"], hide = NO_MELEE_CASTER },
    { spells = { 26480 }, dur = 30, cat = "trinket", icon = "inv_misc_ahnqirajtrinket_04", item = 21670, name = "Badge of the Swarmguard", note = L["Ahn'Qiraj: armor penetration on hits (30 sec)"], hide = NO_MELEE_CASTER },
    { spells = { 24662 }, dur = 20, cat = "trinket", icon = "inv_jewelry_necklace_13", item = 19949, name = "Zandalarian Hero Medallion", note = L["Zul'Gurub: +40 damage, less with every hit (20 sec)"], tipSpell = 24661, hide = NO_MELEE_CASTER, aura = { icon = "ability_criticalstrike", name = "Restless Strength", spell = 24662 } },
    -- Devilsaur Eye: reward of a hunter-only quest (user 2026-11-20), so only hunters can have it
    { spells = { 24352 }, dur = 20, cat = "trinket", icon = "inv_misc_eye_01", item = 19991, name = "Devilsaur Eye", note = L["+150 attack power, +2% hit (20 sec)"], only = { "HUNTER" }, aura = { icon = "ability_hunter_pet_raptor", name = "Devilsaur Fury", spell = 24352 } },
    -- Diamond Flask: reward of the warrior-only quest "Voodoo Feathers" (user 2026-11-20); the Era client gives spell
    -- 24427 (user 2026-11-25, /rkb debug), the newer item effect 363880 is not used there
    { spells = { 24427 }, dur = 60, cat = "trinket", icon = "inv_drink_01", item = 20130, name = "Diamond Flask", note = L["+75 Strength (1 min)"], only = { "WARRIOR" } },
    { spells = { 23725 }, dur = 20, cat = "trinket", icon = "inv_misc_gem_pearl_05", item = 19341, name = "Lifegiving Gem", note = L["Warrior: +15% max. health (20 sec)"], only = { "WARRIOR" } },
    { spells = { 23726 }, dur = 20, cat = "trinket", icon = "inv_misc_idol_03", item = 19342, name = "Venomous Totem", note = L["Rogue: +30% chance to apply poisons (20 sec)"], only = { "ROGUE" }, aura = { icon = "spell_totem_wardofdraining", name = "Venomous Totem", spell = 23726 } },
    { spells = { 24575 }, dur = 20, cat = "trinket", icon = "inv_jewelry_necklace_13", item = 19948, name = "Zandalarian Hero Badge", note = L["Zul'Gurub: +2000 armor, +30 defense, less with every hit taken (20 sec)"], tipSpell = 24574, aura = { icon = "spell_shadow_grimward", name = "Brittle Armor", spell = 24575 } },
    { spells = { 23506 }, dur = 20, cat = "trinket", icon = "inv_misc_armorkit_04", item = 19024, name = "Arena Grand Master", note = L["Absorbs 750-1250 damage (20 sec)"], aura = { icon = "spell_holy_devotionaura", name = "Aura of Protection", spell = 23506 } },
    { spells = { 26400 }, dur = 20, cat = "trinket", icon = "inv_misc_ahnqirajtrinket_03", item = 21647, name = "Fetish of the Sand Reaver", note = L["Ahn'Qiraj: -70% threat (20 sec)"], aura = { icon = "spell_magic_lesserinvisibilty", name = "Arcane Shroud", spell = 26400 } },
    { spells = { 28862 }, dur = 20, cat = "trinket", icon = "inv_trinket_naxxramas02", item = 23001, name = "Eye of Diminution", note = L["Naxxramas: -35% threat (20 sec)"], hide = NO_MELEE, aura = { icon = "spell_magic_lesserinvisibilty", name = "The Eye of Diminution", spell = 28862 } },
    { spells = { 23271 }, dur = 15, cat = "trinket", icon = "inv_misc_stonetablet_11", item = 18820, name = "Talisman of Ephemeral Power", note = L["Molten Core: +175 spell damage and healing (15 sec)"], hide = NO_MELEE, aura = { icon = "spell_holy_mindvision", name = "Ephemeral Power", spell = 23271 } },
    { spells = { 24659 }, dur = 20, cat = "trinket", icon = "inv_jewelry_necklace_13", item = 19950, name = "Zandalarian Hero Charm", note = L["Zul'Gurub: +204 spell damage, less with every cast (20 sec)"], tipSpell = 24658, hide = NO_MELEE, aura = { icon = "spell_lightning_lightningbolt01", name = "Unstable Power", spell = 24659 } },
    { spells = { 28779 }, dur = 20, cat = "trinket", icon = "inv_trinket_naxxramas06", item = 23046, name = "The Restrained Essence of Sapphiron", note = L["Naxxramas: +130 spell damage and healing (20 sec)"], hide = NO_MELEE },
    { spells = { 26166 }, dur = 30, cat = "trinket", icon = "inv_misc_eye_01", item = 21473, name = "Eye of Moam", note = L["Ruins of Ahn'Qiraj: +50 spell damage, -100 target resistances (30 sec)"], hide = NO_MELEE, aura = { icon = "inv_misc_ahnqirajtrinket_04", name = "Obsidian Insight", spell = 26166 } },
    { spells = { 27675 }, dur = 15, cat = "trinket", icon = "inv_jewelry_talisman_09", item = 22268, name = "Draconic Infused Emblem", note = L["+100 spell damage, +190 healing (15 sec)"], hide = NO_MELEE, aura = { icon = "spell_holy_mindvision", name = "Chromatic Infusion", spell = 27675 } },
    { spells = { 24998 }, dur = 15, cat = "trinket", icon = "inv_misc_gem_stone_01", item = 20636, name = "Hibernation Crystal", note = L["+350 healing (15 sec)"], hide = NO_MELEE, aura = { icon = "spell_nature_healingwavegreater", name = "Healing of the Ages", spell = 24998 } },
    { spells = { 24268 }, dur = 30, cat = "trinket", icon = "inv_zulgurubtrinket", item = 19930, name = "Mar'li's Eye", note = L["Zul'Gurub: 60 mana every 5 sec (30 sec)"], hide = NO_MELEE },
    { spells = { 15646 }, dur = 10, cat = "trinket", icon = "inv_jewelry_amulet_07", item = 11832, name = "Burst of Knowledge", note = L["Spells cost 100 mana less (10 sec)"], hide = NO_MELEE },
    { spells = { 23723 }, dur = 20, cat = "trinket", icon = "spell_nature_wispheal", item = 19339, name = "Mind Quickening Gem", note = L["Mage: +33% casting speed (20 sec)"], only = { "MAGE" } },
    { spells = { 23734 }, dur = 20, cat = "trinket", icon = "inv_misc_gem_03", item = 19344, name = "Natural Alignment Crystal", note = L["Shaman: +20% spell damage and healing, +20% mana cost (20 sec)"], only = { "SHAMAN" }, aura = { icon = "spell_nature_spiritarmor", name = "Nature Aligned", spell = 23734 } },
    { spells = { 23733 }, dur = 20, cat = "trinket", icon = "inv_scroll_08", item = 19343, name = "Scrolls of Blinding Light", note = L["Paladin: +25% attack speed, +33% casting speed (20 sec)"], only = { "PALADIN" }, aura = { icon = "spell_holy_searinglight", name = "Blinding Light", spell = 23733 } },
    { spells = { 24543 }, dur = 20, cat = "trinket", icon = "inv_jewelry_necklace_19", item = 19957, name = "Hazza'rah's Charm of Destruction", note = L["Warlock: +10% crit with Destruction spells (20 sec)"], only = { "WARLOCK" }, aura = { icon = "spell_fire_windsofwoe", name = "Massive Destruction", spell = 24543 } },
    { spells = { 23780 }, dur = 20, cat = "trinket", icon = "spell_holy_blessingofprotection", item = 19345, name = "Aegis of Preservation", note = L["Priest: +500 armor, heals when hit (20 sec)"], only = { "PRIEST" } },
    -- "Procs" (user 2026-11-17): talent procs a class gets on itself and weapon procs (Crusader ...).
    -- Variants of one effect (ranks, the same talent of two classes) are one entry. No click action.
    { spells = { 20007 }, dur = 15, cat = "proc", icon = "spell_holy_blessingofstrength", name = "Crusader", note = L["Crusader enchant (Holy Strength): +100 Strength (15 sec), can be up twice with two weapons"], hide = NO_MELEE_CASTER, src = { { icon = "spell_holy_greaterheal", name = "Enchant Weapon - Crusader", spell = 20034 } } },
    { spells = { 16551 }, dur = 3, cat = "proc", icon = "ability_backstab", name = "Felstriker", note = L["Weapon proc: every hit lands and crits (3 sec)"], hide = NO_MELEE_CASTER, src = { { icon = "inv_weapon_shortblade_25", name = "Felstriker", item = 12590 } } },
    { spells = { 21165 }, dur = 10, cat = "proc", icon = "spell_nature_invisibilty", name = "Empyrean Demolisher", note = L["Weapon proc (Haste): +20% attack speed (10 sec)"], hide = NO_MELEE_CASTER, src = { { icon = "inv_hammer_05", name = "Empyrean Demolisher", item = 17112 } } },
    { spells = { 12970, 12966, 12967, 12968, 12969, 16280, 16257, 16277, 16278, 16279 }, dur = 15, cat = "proc", icon = "ability_ghoulfrenzy", name = "Flurry", note = L["Talent: up to +30% attack speed after a crit"], only = { "WARRIOR", "SHAMAN" } },
    { spells = { 14204, 12880, 14201, 14202, 14203 }, dur = 12, cat = "proc", icon = "spell_shadow_unholyfrenzy", name = "Enrage", note = L["Warrior talent: up to +25% melee damage after being crit (12 sec)"], only = { "WARRIOR" } },
    { spells = { 14149, 14143 }, dur = 20, cat = "proc", icon = "ability_fiegndead", name = "Remorseless", note = L["Rogue talent: up to +40% crit for the next attack after a kill"], only = { "ROGUE" } },
    { spells = { 6150 }, dur = 12, cat = "proc", icon = "ability_warrior_innerrage", name = "Quick Shots", note = L["Hunter talent: +30% ranged attack speed (12 sec)"], only = { "HUNTER" }, src = { { icon = "spell_nature_ravenform", name = "Improved Aspect of the Hawk", spell = 19552 } } },
    { spells = { 12536, 16870, 16246 }, dur = 15, cat = "proc", icon = "spell_shadow_manaburn", name = "Clearcasting", note = L["Talent proc: the next spell costs no mana"], only = { "MAGE", "DRUID", "SHAMAN" }, src = { { icon = "spell_shadow_manaburn", name = "Arcane Concentration", spell = 11213, class = "MAGE" }, { icon = "spell_nature_crystalball", name = "Omen of Clarity", spell = 16864, class = "DRUID" }, { icon = "spell_shadow_manaburn", name = "Elemental Focus", spell = 16164, class = "SHAMAN" } } },
    { spells = { 17941 }, dur = 10, cat = "proc", icon = "spell_shadow_twilight", name = "Shadow Trance", note = L["Warlock talent: the next Shadow Bolt is instant"], only = { "WARLOCK" } },
    { spells = { 15271 }, dur = 15, cat = "proc", icon = "spell_shadow_requiem", name = "Spirit Tap", note = L["Priest talent: +100% Spirit after a kill (15 sec)"], only = { "PRIEST" } },
    { spells = { 16886 }, dur = 15, cat = "proc", icon = "spell_nature_naturesblessing", name = "Nature's Grace", note = L["Druid talent: the next spell casts 0.5 sec faster"], only = { "DRUID" } },
    { spells = { 20055, 20050, 20052, 20053, 20054 }, dur = 8, cat = "proc", icon = "ability_racial_avatar", name = "Vengeance", note = L["Paladin talent: up to +15% physical and Holy damage after a crit (8 sec)"], only = { "PALADIN" } },
    -- "Abilities" (user 2026-11-17): buffs of abilities and talents the player activates himself (cooldowns),
    -- split off from "Procs" (they are no procs). No click action.
    { spells = { 18499 }, dur = 10, cat = "skill", sub = "cd", icon = "spell_nature_ancestralguardian", name = "Berserker Rage", note = L["Warrior: immune to fear, extra rage (10 sec)"], only = { "WARRIOR" } },
    { spells = { 29131 }, dur = 10, cat = "skill", sub = "cd", icon = "ability_racial_bloodrage", name = "Bloodrage", note = L["Warrior: 1 rage per second (10 sec)"], tipSpell = 2687, only = { "WARRIOR" } },
    { spells = { 12328 }, dur = 30, cat = "skill", sub = "cd", icon = "spell_shadow_deathpact", name = "Death Wish", note = L["Warrior talent: +20% physical damage, -20% armor (30 sec)"], only = { "WARRIOR" } },
    { spells = { 1719 }, dur = 15, cat = "skill", sub = "cd", icon = "ability_criticalstrike", name = "Recklessness", note = L["Warrior: +100% crit chance, +20% damage taken (15 sec)"], only = { "WARRIOR" } },
    -- Retaliation (user 2026-11-20; Wowhead Classic spell 20230: counterattacks melee hits for 15 sec, at most 30,
    -- 30 min cooldown shared with Recklessness and Shield Wall)
    { spells = { 20230 }, dur = 15, cat = "skill", sub = "cd", icon = "ability_warrior_challange", name = "Retaliation", note = L["Warrior: counterattacks melee attackers (15 sec, max. 30)"], only = { "WARRIOR" } },
    { spells = { 12292 }, dur = 20, cat = "skill", sub = "cd", icon = "ability_rogue_slicedice", name = "Sweeping Strikes", note = L["Warrior talent: the next 5 attacks hit a second target"], only = { "WARRIOR" } },
    { spells = { 2565 }, dur = 5, cat = "skill", sub = "cd", icon = "ability_defend", name = "Shield Block", note = L["Warrior: +75% block chance for the next attack (5 sec)"], only = { "WARRIOR" } },
    -- Shield Wall (user 2026-11-20; Wowhead Classic spell 871: -75% damage taken for 10 sec, 30 min cooldown)
    { spells = { 871 }, dur = 10, cat = "skill", sub = "cd", icon = "ability_warrior_shieldwall", name = "Shield Wall", note = L["Warrior: -75% damage taken (10 sec)"], only = { "WARRIOR" } },
    { spells = { 12976 }, dur = 20, cat = "skill", sub = "cd", icon = "spell_holy_ashestoashes", name = "Last Stand", note = L["Warrior talent: +30% max. health (20 sec)"], only = { "WARRIOR" } },
    { spells = { 6774, 5171 }, dur = 21, cat = "skill", sub = "cd", icon = "ability_rogue_slicedice", name = "Slice and Dice", note = L["Rogue: +30% attack speed"], only = { "ROGUE" } },
    { spells = { 13877 }, dur = 15, cat = "skill", sub = "cd", icon = "ability_warrior_punishingblow", name = "Blade Flurry", note = L["Rogue talent: +20% attack speed, hits a second target (15 sec)"], only = { "ROGUE" } },
    { spells = { 13750 }, dur = 15, cat = "skill", sub = "cd", icon = "spell_shadow_shadowworddominate", name = "Adrenaline Rush", note = L["Rogue talent: +100% energy regeneration (15 sec)"], only = { "ROGUE" } },
    { spells = { 14177 }, dur = 0, cat = "skill", sub = "cd", icon = "spell_ice_lament", name = "Cold Blood", note = L["Rogue talent: the next attack crits"], only = { "ROGUE" } },
    { spells = { 3045 }, dur = 15, cat = "skill", sub = "cd", icon = "ability_hunter_runningshot", name = "Rapid Fire", note = L["Hunter: +40% ranged attack speed (15 sec)"], only = { "HUNTER" } },
    { spells = { 12042 }, dur = 15, cat = "skill", sub = "cd", icon = "spell_nature_lightning", name = "Arcane Power", note = L["Mage talent: +30% spell damage, +30% mana cost (15 sec)"], only = { "MAGE" } },
    { spells = { 28682 }, dur = 0, cat = "skill", sub = "cd", icon = "spell_fire_sealoffire", name = "Combustion", note = L["Mage talent: rising crit with fire spells"], tipSpell = 11129, only = { "MAGE" } },
    { spells = { 12043 }, dur = 0, cat = "skill", sub = "cd", icon = "spell_nature_enchantarmor", name = "Presence of Mind", note = L["Mage talent: the next spell is instant"], only = { "MAGE" } },
    { spells = { 14751 }, dur = 0, cat = "skill", sub = "cd", icon = "spell_frost_windwalkon", name = "Inner Focus", note = L["Priest talent: the next spell costs no mana, +25% crit"], only = { "PRIEST" } },
    { spells = { 10060 }, dur = 15, cat = "raid", icon = "spell_holy_powerinfusion", name = "Power Infusion", note = L["Priest talent: +20% spell damage and healing (15 sec)"], hide = NO_MELEE },
    { spells = { 17116, 16188 }, dur = 0, cat = "skill", sub = "cd", icon = "spell_nature_ravenform", name = "Nature's Swiftness", note = L["Talent: the next Nature spell is instant"], only = { "DRUID", "SHAMAN" } },
    { spells = { 16166 }, dur = 0, cat = "skill", sub = "cd", icon = "spell_nature_wispheal", name = "Elemental Mastery", note = L["Shaman talent: the next spell crits and costs no mana"], only = { "SHAMAN" } },
    { spells = { 20216 }, dur = 0, cat = "skill", sub = "cd", icon = "spell_holy_heal", name = "Divine Favor", note = L["Paladin talent: the next heal crits"], only = { "PALADIN" } },

    -- "Sonstiges" (user 2026-11-10): buffs that only cost a slot, e.g. from equipped items. Wowhead spell 17670:
    -- buff "Argent Dawn Commission" of the trinket (item 12846, Scourgestones); default in "Unerwünscht".
    { spells = { 17670 }, dur = 0, cat = "misc", icon = "inv_jewelry_talisman_07", name = "Argent Dawn Commission", note = L["Argent Dawn trinket: only for Scourgestones, costs a buff slot"] },
    -- Mount (user 2026-11-17): ONE entry for every mount (in Era a mount is a buff and costs a slot). Detection by
    -- IsMounted(), not by spell IDs (ns:MountAura in Auras.lua); while riding it shows the icon of the real mount,
    -- right-click = /dismount. spells = { 458 } (Brown Horse) only gives the entry its ID -458, it is never matched.
    -- Not riding (2026-11-19): icon and Ctrl+click = the mount of ns:MountPick (lists below).
    { spells = { 458 }, dur = 0, cat = "misc", icon = "ability_mount_ridinghorse", name = "Mount", note = L["Any mount: active while mounted, right-click dismounts. Not mounted: Ctrl+click mounts your first 100% mount (else 60%), in AQ40 a Qiraji crystal (red first)"], mount = true },
    -- Buff counter (user 2026-11-25): the used buff slots as a number, can go into any row (B.UpdateCounterButton).
    -- 990032 is no spell, it only gives the entry its ID -990032 and never matches an aura.
    { spells = { 990032 }, dur = 0, cat = "misc", icon = "spell_holy_magicalsentry", name = "Buff counter", note = L["Shows how many of the 32 buff slots are in use, colored like the bar when slots run short. Drag it into any row."], counter = true },
    -- transformations (user 2026-11-10: costumes etc. only cost a slot and can be cancelled), default in
    -- "Unerwünscht" for every class. Spell IDs and names from Wowhead Classic 2026-11-10.
    { spells = { 24708, 24709, 24710, 24711, 24712, 24713, 24723, 24732, 24735, 24736, 24740, 24741 }, dur = 3600, cat = "misc", icon = "ability_rogue_disguise", name = "Hallowed Wand Costume", note = L["Hallowed Wand: pirate, ninja, leper gnome, skeleton, bat, ghost or wisp costume"] },
    { spells = { 24924, 24925, 24926, 24927 }, dur = 1200, cat = "misc", icon = "inv_misc_food_59", name = "Hallow's End Candy", note = L["Hallow's End candy: transformation"] },
    { spells = { 16591, 16595, 16593 }, dur = 600, cat = "misc", icon = "spell_shadow_raisedead", name = "Noggenfogger Elixir", note = L["Skeleton, shrunk or slow fall"] },
    { spells = { 8219, 8220, 8221, 8222 }, dur = 3600, cat = "misc", icon = "ability_rogue_disguise", name = "Savory Deviate Delight", note = L["Pirate or ninja (Flip Out, Yaaarrrr)"] },
    { spells = { 16739 }, dur = 300, cat = "misc", icon = "spell_shadow_antishadow", name = "Orb of Deception", note = L["Disguised as another race"] },
    { spells = { 22736 }, dur = 600, cat = "misc", icon = "ability_rogue_disguise", name = "Gordok Ogre Suit", note = L["Dire Maul: disguised as a Gordok ogre"] },
    { spells = { 26157, 26272, 26273, 26274 }, dur = 1800, cat = "misc", icon = "spell_frost_frostshock", name = "PX-238 Winter Wondervolt", note = L["Winter Veil: transformation"] },
}

-- Categories of the "Buffs" tab (also the section headers of its list). Within a category the catalog sorts by the
-- displayed name (ns.SortKey); subs (2026-11-20, user) = parts after the entries without sub, split by a faint line
ns.BUFF_FILTERS = {
    { label = L["All"] },
    { label = L["World Buffs"], cat = "world" },
    -- Since 2026-11-20 (user) the categories say how a buff works, the same for every class (only filters depend on the
    -- class): "Situational" and "Own" are gone (Docs/Buff-Detection.md "Buff-Katalog: Kategorien")
    { label = L["Raid Buffs"], cat = "raid" }, -- a player casts it on others, it has a duration (Battle Shout too)
    { label = L["Auras & Totems"], cat = "aura", subs = { "totem" } }, -- works only in range, no duration (auras, Trueshot, Leader; then the totems)
    { label = L["Abilities"], cat = "skill", subs = { "cd" } }, -- a class casts it on itself only: long ones (Inner Fire, armors) first, then cooldowns
    -- 2026-11-17: buffs of on-use trinkets; item (2026-11-20) = the trinket, whose name the catalog shows. aura (2026-11-20) = the buff where its icon differs from the trinket's
    -- (second icon in the catalog); src on procs = what triggers them (item, enchant, talent; class = only that class)
    { label = L["Trinkets"], cat = "trinket" },
    { label = L["Procs"], cat = "proc" }, -- 2026-11-17: talent and weapon procs
    { label = L["Misc"], cat = "misc" }, -- 2026-11-10: Argent Dawn Commission
}

-- Default of the list "Unerwünscht" per class: buffs that only cost a buff slot (removed with one click).
-- Argent Dawn Commission (-17670) for every class (user 2026-11-10). Per class (user 2026-11-10: a mage of
-- course wants Intellect): melee classes drop Int/Spirit; hunters and casters drop the melee-only attack
-- power buffs (Blessing of Might, Battle Shout of a warrior in the group) and Thorns.
-- Order (user 2026-11-12): Argent Dawn Commission first, then the class buffs, then the transformations.
local CASTER_UNWANTED = { -25916, -25289, -9910 } -- Might, Battle Shout, Thorns
ns.DEFAULT_UNWANTED = {
    WARRIOR = { -23028, -27681 }, -- Arcane Intellect, Divine Spirit
    ROGUE = { -23028, -27681 },
    HUNTER = { -25916, -25289, -27681 }, -- Might, Battle Shout, Divine Spirit
    MAGE = CASTER_UNWANTED,
    WARLOCK = CASTER_UNWANTED,
    PRIEST = CASTER_UNWANTED,
    DRUID = CASTER_UNWANTED,
    PALADIN = CASTER_UNWANTED,
    SHAMAN = CASTER_UNWANTED,
}
-- transformations for every class (user 2026-11-10), order user 2026-11-12: Hallow's End Candy, Savory Deviate
-- Delight (Flip Out), Gordok Ogre Suit, Hallowed Wand Costume (Pirate Costume), Noggenfogger, Winter Wondervolt,
-- Orb of Deception (not in the user's list, at the end)
local TRANSFORMS = { -24924, -8219, -22736, -24708, -16591, -26157, -16739 }
for class, list in pairs(ns.DEFAULT_UNWANTED) do
    local copy = { -17670 }
    for _, id in ipairs(list) do copy[#copy + 1] = id end
    for _, id in ipairs(TRANSFORMS) do copy[#copy + 1] = id end
    ns.DEFAULT_UNWANTED[class] = copy
end

-- Rank of every default entry (2026-11-12): Argent Dawn Commission, Int/Spirit, Might/Battle Shout/Thorns, then
-- TRANSFORMS. ns.SortUnwanted puts a list into this order once; entries of the user's own keep their order at the end.
local UNWANTED_RANK = {}
for i, id in ipairs({ -17670, -23028, -27681, -25916, -25289, -9910 }) do UNWANTED_RANK[id] = i end
for i, id in ipairs(TRANSFORMS) do UNWANTED_RANK[id] = 100 + i end
function ns.SortUnwanted(list)
    local keyed = {}
    for i, id in ipairs(list) do keyed[i] = { id = id, k = UNWANTED_RANK[id] or (1000 + i) } end
    table.sort(keyed, function(a, b) return a.k < b.k end)
    for i, e in ipairs(keyed) do list[i] = e.id end
end

-- Buff cap: Classic Era 32 (research 2026-11-09). RaidKit Buffs is an Era-only addon (user 2026-11-21), so the cap
-- always applies; versions or realms without a cap are not handled (user 2026-11-25).
ns.BUFF_CAP = 32
-- Debuffs the Blizzard bar shows on the player (DEBUFF_MAX_DISPLAY, 16): size of the debuff preview
ns.DEBUFF_CAP = DEBUFF_MAX_DISPLAY or 16

-- Mount to mount up with (user 2026-11-19, ns:MountPick in Auras.lua; item IDs from Wowhead Classic 2026-11-19).
-- In Era a mount is an item in the bags. MOUNT_FAST: every 100 % mount item (racial epics, PvP, raid drops, rare
-- mounts); MOUNT_QIRAJI: the AQ40 crystals in the order the user wants (red, blue, green, yellow, black last);
-- MOUNT_CLASS_SPELLS: paladin Charger, warlock Dreadsteed (spells, no item; they come before the bags).
-- Without any 100 % mount (user 2026-11-19) the same with 60 %: MOUNT_SLOW (every 60 % mount item, level 40 mounts incl.
-- never released colours, harmless) and MOUNT_CLASS_SPELLS_SLOW (Warhorse, Felsteed). Riding Turtle is no 60 % mount.
ns.MOUNT_FAST = {}
for _, id in ipairs({ 18777, 18776, 18778, 18786, 18787, 18785, 18772, 18773, 18774, 18766, 18767, 18902, 18796, 18797,
    18798, 18788, 18789, 18790, 18793, 18795, 18794, 18791, 13334, 13335, 19030, 19029, 18241, 18244, 18243, 18242, 18245,
    18246, 18247, 18248, 19872, 19902, 13086, 21176, 12302, 12303, 12330, 12351, 12353, 12354, 13317, 13326, 13327, 13328,
    13329, 15292, 15293, 8586 }) do
    ns.MOUNT_FAST[id] = true
end
ns.MOUNT_SLOW = {}
for _, id in ipairs({ 2414, 2411, 5656, 5655, 5864, 5873, 5872, 5874, 5875, 8563, 8595, 13321, 13322, 13325, 8631, 8632, 8629, 8630,
    8627, 8628, 12325, 12326, 12327, 1132, 5665, 5668, 5663, 8588, 8591, 8592, 8589, 8590, 15290, 15277, 13331, 13332, 13333 }) do
    ns.MOUNT_SLOW[id] = true
end
ns.MOUNT_QIRAJI = { 21321, 21218, 21323, 21324, 21176 }
ns.MOUNT_CLASS_SPELLS = { { id = 23214, icon = "ability_mount_charger" }, { id = 23161, icon = "ability_mount_dreadsteed" } }
ns.MOUNT_CLASS_SPELLS_SLOW = { { id = 13819, icon = "spell_nature_swiftness" }, { id = 5784, icon = "spell_nature_swiftness" } }
ns.AQ40_INSTANCE_ID = 531

-- Lookup -spellID -> buff entry; class sets
ns.buffCatalog = {}
for _, b in ipairs(ns.BUFFS) do
    b.id = -b.spells[1]
    b.isBuff = true
    local set = {}
    for _, c in ipairs(b.hide or {}) do set[c] = true end
    b.hideSet = set
    if b.only then
        b.onlySet = {}
        for _, c in ipairs(b.only) do b.onlySet[c] = true end
    end
    ns.buffCatalog[b.id] = b
end
