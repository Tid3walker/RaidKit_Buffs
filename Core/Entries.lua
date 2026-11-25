-- RaidKit Buffs: Core - Entries
-- Row entries (an item, a slot of alternatives, a weapon entry, a foreign buff): IDs, names, icons, buff places,
-- own buffs, faction and class checks. Split from Core.lua on 2026-11-20.

local _, ns = ...
local L = ns.L
local CopyTable = ns.CopyTable

------------------------------------------------------------------------
-- Row entries: an itemID or a slot { itemID, itemID, ..., pick = itemID }
-- A slot is one icon for alternatives of the same buff place. List order = fallback order,
-- [1] = the icon in the options grid, pick = chosen variant (mouse wheel on the bar).
------------------------------------------------------------------------

ns.MAX_VARIANTS = 6       -- icon + 5 alternatives
ns.MAX_VARIANTS_FOOD = 11 -- food and drinks: icon + 10 alternatives (user 2026-11-11)

-- Variant limit of a slot, decided by its main item (grid icon): food/drinks get more room
function ns.MaxVariants(mainID)
    local e = mainID and ns.catalog[mainID]
    if e and e.cat == "food" then return ns.MAX_VARIANTS_FOOD end
    return ns.MAX_VARIANTS
end

function ns.IsSlot(entry)
    return type(entry) == "table"
end

-- the itemIDs of an entry as a list (a slot is its own list)
function ns.EntryIDs(entry)
    if type(entry) == "table" then return entry end
    return { entry }
end

function ns.EntryMain(entry)
    if type(entry) == "table" then return entry[1] end
    return entry
end

function ns.EntryPick(entry)
    if type(entry) == "table" then return entry.pick or entry[1] end
    return entry
end

function ns.EntryHas(entry, itemID)
    for _, id in ipairs(ns.EntryIDs(entry)) do
        if id == itemID then return true end
    end
    return false
end

-- Cleans a slot: numbers only, no duplicates, at most ns.MaxVariants(main), valid pick.
-- Returns the plain itemID when one variant is left, nil when none.
function ns.NormalizeEntry(entry)
    if type(entry) ~= "table" then return entry end
    local out, seen = {}, {}
    local limit = ns.MAX_VARIANTS_FOOD
    for _, id in ipairs(entry) do
        if type(id) == "number" and id ~= 0 and id == math.floor(id) and not seen[id] and #out < limit then
            if #out == 0 then limit = ns.MaxVariants(id) end
            seen[id] = true
            out[#out + 1] = id
        end
    end
    if #out == 0 then return nil end
    -- weapon entries (2026-11-09) stay a slot even with one variant: they carry the hand
    local hand = (entry.hand == "main" or entry.hand == "off") and entry.hand or nil
    if #out == 1 and not hand then return out[1] end
    out.pick = seen[entry.pick] and entry.pick or out[1]
    out.hand = hand
    return out
end

-- Weapon enchant items (stones, oils, poisons) and weapon entries (slot with hand = "main" | "off")
function ns.IsWeaponItem(itemID)
    local e = ns.catalog[itemID]
    return e ~= nil and e.cat == "weapon"
end

function ns.IsWeaponEntry(entry)
    return type(entry) == "table" and (entry.hand == "main" or entry.hand == "off")
end

-- New entry for an item: a slot with its default alternatives (Data.lua ns.DEFAULT_ALTS) or the plain
-- itemID. skip(id) = true leaves an alternative out (e.g. it is already elsewhere in the row).
-- Weapon items always become a slot with a hand (hand, default "main").
function ns.DefaultEntry(itemID, skip, hand)
    local alts = ns.DEFAULT_ALTS[itemID]
    if ns.IsWeaponItem(itemID) then
        local slot = { itemID, pick = itemID, hand = hand or "main" }
        for _, id in ipairs(alts or {}) do slot[#slot + 1] = id end
        return ns.NormalizeEntry(slot)
    end
    if not alts then return itemID end
    local slot = { itemID, pick = itemID }
    for _, id in ipairs(alts) do
        if not (skip and skip(id)) then slot[#slot + 1] = id end
    end
    return ns.NormalizeEntry(slot)
end

-- Items of a row template with the default alternatives; buffs of the other faction are left out
-- tpl.noAlts (2026-11-10, "Essen & Co"): plain icons without ns.DEFAULT_ALTS; weapon items stay a slot with a hand
-- tpl.noAltsFrom (2026-11-14, "Selbst verantwortlich"): the same from that entry on (the "Essen & Co" part)
function ns.TemplateItems(tpl)
    local items = {}
    for i, entry in ipairs(tpl.items) do
        if type(entry) ~= "number" then
            items[#items + 1] = CopyTable(entry)
        elseif not ns.IsBuffID(entry) then
            if tpl.noAlts or (tpl.noAltsFrom and i >= tpl.noAltsFrom) then
                items[#items + 1] = ns.IsWeaponItem(entry) and { entry, pick = entry, hand = "main" } or entry
            else
                items[#items + 1] = ns.DefaultEntry(entry)
            end
        elseif ns.BuffEntry(entry) and ns.BuffFitsFaction(ns.BuffEntry(entry)) then
            items[#items + 1] = entry
        end
    end
    return items
end

------------------------------------------------------------------------
-- Foreign buffs (Data.lua ns.BUFFS): row entries with a negative ID = -(main spell ID)
------------------------------------------------------------------------

function ns.IsBuffID(id)
    return type(id) == "number" and id < 0
end

function ns.BuffEntry(id)
    return ns.buffCatalog[id]
end

-- true if the player casts this catalog buff himself: b.self or his class in b.selfClass (2026-11-14; Battle Shout uses
-- selfClass WARRIOR since 2026-11-20, before b.self, which made it "own" for every class)
function ns.IsOwnBuff(b)
    if not b then return false end
    if b.self then return true end
    local class = ns:PlayerClass()
    for _, c in ipairs(b.selfClass or {}) do
        if c == class then return true end
    end
    return false
end

-- Spell name Ctrl+click casts for an own buff (2026-11-14): b.selfCast (a spell ID or a list of variants, e.g. the
-- mage armors) or spells[1]. From a list the first one the player knows (IsPlayerSpell: exact rank, so the
-- highest ranks; the name check covers lower ranks of a levelling character), else the first. The secure button
-- casts by name, so always the highest rank the player has.
function ns.OwnCastName(b)
    local list = type(b.selfCast) == "table" and b.selfCast or { b.selfCast or b.spells[1] }
    if #list > 1 then
        for _, id in ipairs(list) do
            if IsPlayerSpell and IsPlayerSpell(id) then return ns.GetSpellName(id) end
        end
        for _, id in ipairs(list) do
            local name = ns.GetSpellName(id)
            if name and GetSpellInfo and GetSpellInfo(name) then return name end
        end
    end
    return ns.GetSpellName(list[1])
end

function ns:PlayerFaction()
    local f = UnitFactionGroup("player")
    return f == "Horde" and "H" or "A"
end

-- Paladin buffs only for Alliance, shaman totems only for Horde
function ns.BuffFitsFaction(b)
    return not b.fac or b.fac == ns:PlayerFaction()
end

-- false = useless for the class (listed under "Unpassend für <class>" in the catalog)
function ns.BuffForClass(b)
    local class = ns:PlayerClass()
    if b.hideSet[class] then return false end
    return not b.onlySet or b.onlySet[class] == true
end

-- Icon texture and display name of a row entry ID (item or buff)
function ns.EntryIcon(id)
    local b = ns.buffCatalog[id]
    if b then return "Interface\\Icons\\" .. b.icon end
    return ns.GetItemIcon(id)
end

function ns.EntryName(id)
    local b = ns.buffCatalog[id]
    if b and b.mount then return L["Mount"] end
    if b and b.counter then return L["Buff counter"] end -- no spell of its own (2026-11-25)
    -- a trinket (b.item, 2026-11-20): the item's name, not its buff's (user: "Gift of Life" instead of "Lifegiving Gem")
    if b and b.item then return ns.GetItemInfo(b.item) or b.name end
    if b then return ns.GetSpellName(b.spells[1]) or b.name end
    local name = ns.GetItemInfo(id)
    if name then return name end
    local e = ns.catalog[id]
    return e and e.name or ("Item #" .. tostring(id))
end

-- Buff place of an item (Data.lua ns.BUFF_PLACE); items with the same place overwrite each other
function ns.BuffPlace(itemID)
    local place = ns.BUFF_PLACE[itemID]
    if place then return place end
    local e = ns.catalog[itemID]
    if e and (e.cat == "flask" or e.cat == "food") then return e.cat end
    return "item" .. itemID
end

-- ns.IsMixedEntry (variants with different buff places, the yellow "!" in the options) removed 2026-11-18 (user)

-- Flasks and Zanza (type "flask") stay locked in combat if they were active at the pull
function ns.IsFlaskEntry(entry)
    for _, id in ipairs(ns.EntryIDs(entry)) do
        local e = ns.catalog[id]
        if e and e.cat == "flask" then return true end
    end
    return false
end
