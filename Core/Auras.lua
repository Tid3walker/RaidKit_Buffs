-- RaidKit Buffs: Auras
-- Scans the player's buffs and answers "is the buff of item X active?".
-- Also keeps the full list of active buffs (counter, area "Sonstige", loss alarm).

local _, ns = ...

local GetAuraDataByIndex = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
local UnitBuff, UnitDebuff = UnitBuff, UnitDebuff
local GetWeaponEnchantInfo, OffhandHasWeapon = GetWeaponEnchantInfo, OffhandHasWeapon
local IsMounted = IsMounted
local GetMountFromSpell = C_MountJournal and C_MountJournal.GetMountFromSpell

-- spellID -> expirationTime (0 = never expires), duration; name -> the same (buffs of other ranks)
local active = {}
local activeDuration = {}
local activeByName = {}
-- every active buff in buff index order: { index, spellId, name, icon, expiration, duration }
local auraList = {}
ns.auraList = auraList
-- every debuff in index order (shown while RaidKit Buffs replaces the Blizzard buff bar, 2026-11-09):
-- { index, spellId, name, icon, count, dispel, expiration, duration }
local debuffList = {}
ns.debuffList = debuffList

local function ScanDebuffs()
    wipe(debuffList)
    for i = 1, 40 do
        local d
        if GetAuraDataByIndex then
            local a = GetAuraDataByIndex("player", i, "HARMFUL")
            if not a then break end
            d = { spellId = a.spellId, name = a.name, icon = a.icon, count = a.applications,
                dispel = a.dispelName, expiration = a.expirationTime, duration = a.duration }
        else
            local n, ic, count, dispel, dur, exp, _, _, _, id = UnitDebuff("player", i)
            if not n then break end
            d = { spellId = id, name = n, icon = ic, count = count, dispel = dispel, expiration = exp, duration = dur }
        end
        d.index = i
        d.expiration = d.expiration or 0
        debuffList[#debuffList + 1] = d
    end
end

-- Weapon enchants per hand (2026-11-09): what GetWeaponEnchantInfo() reports right now.
-- ns.weapon.main / .off = { enchant, expiration (GetTime), itemID (catalog item or nil), wf } or nil;
-- ns.weapon.offWeapon = an off-hand weapon is equipped (no shield / held item).
-- Windfury Totem (ns.WINDFURY_ENCHANTS) wins on the main hand: the game reports only one enchant per hand.
ns.weapon = { offWeapon = true }
local weaponKey = ""

local function HandInfo(has, ms, id)
    if not has or not id then return nil end
    return { enchant = id, expiration = GetTime() + (ms or 0) / 1000, itemID = ns.enchantItem[id],
        wf = ns.WINDFURY_ENCHANTS[id] == true }
end

-- Returns true when something changed that the bar must show (enchant on/off/other, off-hand weapon).
function ns:ScanWeapon()
    if not GetWeaponEnchantInfo then return false end
    local mh, mhMs, _, mhID, oh, ohMs, _, ohID = GetWeaponEnchantInfo()
    local w = ns.weapon
    w.main, w.off = HandInfo(mh, mhMs, mhID), HandInfo(oh, ohMs, ohID)
    w.offWeapon = not OffhandHasWeapon or OffhandHasWeapon() and true or false
    -- re-applying the same enchant also counts (expiration jumps up)
    local key = table.concat({ tostring(mhID), tostring(mh and math.floor((mhMs or 0) / 60000)),
        tostring(ohID), tostring(oh and math.floor((ohMs or 0) / 60000)), tostring(w.offWeapon) }, ",")
    local changed = key ~= weaponKey
    weaponKey = key
    return changed
end

-- State of a weapon entry: active when its hand carries one of its variants, or Windfury on the main hand.
-- Returns isActive, expiration, activeItemID, isWindfury, noWeapon, otherEnchant
function ns:WeaponEntryState(entry)
    local hand = entry.hand
    if hand == "off" and not ns.weapon.offWeapon then return false, nil, nil, false, true end
    local h = ns.weapon[hand]
    if not h then return false end
    if hand == "main" and h.wf then return true, 0, nil, true end
    if h.itemID and ns.EntryHas(entry, h.itemID) then return true, h.expiration, h.itemID end
    return false, nil, nil, false, false, h.enchant
end

function ns:ScanAuras()
    ScanDebuffs()
    ns:ScanWeapon()
    wipe(active)
    wipe(activeDuration)
    wipe(activeByName)
    wipe(auraList)
    for i = 1, 40 do
        local spellId, expirationTime, duration, name, icon
        if GetAuraDataByIndex then
            local aura = GetAuraDataByIndex("player", i, "HELPFUL")
            if not aura then break end
            spellId, expirationTime, duration, name, icon = aura.spellId, aura.expirationTime, aura.duration, aura.name, aura.icon
        else
            local n, ic, _, _, dur, exp, _, _, _, id = UnitBuff("player", i)
            if not n then break end
            spellId, expirationTime, duration, name, icon = id, exp, dur, n, ic
        end
        if spellId then
            active[spellId] = expirationTime or 0
            activeDuration[spellId] = duration or 0
        end
        if name then activeByName[name] = expirationTime or 0 end
        auraList[#auraList + 1] = { index = i, spellId = spellId, name = name, icon = icon,
            expiration = expirationTime or 0, duration = duration or 0 }
    end
    ns:ScanMount()
end

-- Mount (2026-11-17, user): one catalog entry (b.mount) for every mount. Active = IsMounted(). Which aura is the mount
-- (icon, tooltip, covered in "Sonstige"): C_MountJournal.GetMountFromSpell where the client has it, else learned: the
-- auras without duration that appeared in the scan where IsMounted() turned true (per session; /rkb debug shows it).
local mountSpells, prevIds, wasMounted, scanned = {}, {}, false, false
ns.mountSpells = mountSpells
local function IsMountSpell(id)
    if not id then return false end
    if mountSpells[id] then return true end
    return GetMountFromSpell ~= nil and GetMountFromSpell(id) ~= nil
end
function ns:ScanMount()
    local mounted = IsMounted and IsMounted() and true or false
    if mounted and not wasMounted and scanned then
        for _, a in ipairs(auraList) do
            if a.spellId and not prevIds[a.spellId] and (a.duration or 0) == 0 then mountSpells[a.spellId] = true end
        end
    end
    wasMounted, scanned = mounted, true
    wipe(prevIds)
    for _, a in ipairs(auraList) do
        if a.spellId then prevIds[a.spellId] = true end
    end
    ns.mounted = mounted
end
-- the aura of the current mount, nil when not mounted or not known
function ns:MountAura()
    if not ns.mounted then return nil end
    for _, a in ipairs(auraList) do
        if IsMountSpell(a.spellId) then return a end
    end
    return nil
end

-- Mount to mount up with (2026-11-19, user): while not riding, the mount icon shows a mount and Ctrl+click mounts it.
-- In AQ40 (instanceID 531) the first Qiraji crystal of ns.MOUNT_QIRAJI in the bags (red first); elsewhere a paladin's
-- Charger / warlock's Dreadsteed, else the first 100 % mount item in bag order (ns.MOUNT_FAST); without any 100 %
-- mount the same with 60 % (Warhorse / Felsteed, ns.MOUNT_SLOW; user 2026-11-19). Result
-- { item = itemID, icon } or { spell = name, spellID, icon }; nil = none (no click). Cached until bags or zone change
-- (ns:MountPickChanged, Core.lua events).
local GetNumSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
local GetSlotItemID = C_Container and C_Container.GetContainerItemID or GetContainerItemID
local mountPick, mountPickDirty = nil, true
function ns:MountPickChanged() mountPickDirty = true end
function ns.InAQ40()
    return GetInstanceInfo ~= nil and select(8, GetInstanceInfo()) == ns.AQ40_INSTANCE_ID
end
local function FindMount()
    if ns.InAQ40() then
        for _, id in ipairs(ns.MOUNT_QIRAJI) do
            if (ns.GetItemCount(id) or 0) > 0 then return { item = id, icon = ns.GetItemIcon(id) } end
        end
        return nil
    end
    for tier = 1, 2 do -- 1 = 100 %, 2 = 60 %
        for _, s in ipairs(tier == 1 and ns.MOUNT_CLASS_SPELLS or ns.MOUNT_CLASS_SPELLS_SLOW) do
            if IsSpellKnown and IsSpellKnown(s.id) then
                return { spell = ns.GetSpellName(s.id) or s.id, spellID = s.id, icon = "Interface\\Icons\\" .. s.icon }
            end
        end
        local set = tier == 1 and ns.MOUNT_FAST or ns.MOUNT_SLOW
        for bag = 0, NUM_BAG_SLOTS or 4 do
            for slot = 1, GetNumSlots(bag) or 0 do
                local id = GetSlotItemID(bag, slot)
                if id and set[id] then return { item = id, icon = ns.GetItemIcon(id) } end
            end
        end
    end
    return nil
end
function ns:MountPick()
    if mountPickDirty then mountPick, mountPickDirty = FindMount(), false end
    return mountPick
end

-- Returns the buff spell IDs that count as "active" for an item.
-- Priority: manual override in the profile > catalog > the item's use spell
-- (exclusive: the first available source is used alone).
-- Foreign buffs (negative ID): the spells of the ns.BUFFS entry.
local buffCache = {}

function ns:GetBuffSpellsForItem(itemID)
    local b = ns.buffCatalog[itemID]
    if b and b.mount then -- the aura of the current mount (covered in "Sonstige")
        local a = ns:MountAura()
        return a and { a.spellId } or {}
    end
    if b then return b.spells end

    local override = ns.profile and ns.profile.buffOverrides[itemID]
    if override and #override > 0 then
        return override
    end

    local cached = buffCache[itemID]
    if cached then return cached end

    -- The catalog wins and is exclusive: for food the use spell ("Food") would
    -- otherwise already count as active while eating.
    local list = {}
    local entry = ns.catalog[itemID]
    if entry then
        for _, id in ipairs(entry.buffs) do list[#list + 1] = id end
    else
        local _, useSpellID = ns.GetItemSpell(itemID)
        if useSpellID then
            list[#list + 1] = useSpellID
        end
    end
    -- Only cache if something was found (item data may load asynchronously).
    if #list > 0 then buffCache[itemID] = list end
    return list
end

function ns:ClearBuffCache(itemID)
    if itemID then buffCache[itemID] = nil else wipe(buffCache) end
end

-- localized buff names of a foreign buff (lower ranks have other spell IDs but the same name)
local nameCache = {}
function ns:GetBuffNames(id)
    local names = nameCache[id]
    if names then return names end
    names = {}
    local b = ns.buffCatalog[id]
    if b and (b.mount or b.counter) then return names end -- never by name (Brown Horse / the counter are only IDs)
    for _, spellID in ipairs(b and b.spells or {}) do
        local n = ns.GetSpellName(spellID)
        if n then names[#names + 1] = n end
    end
    if #names > 0 then nameCache[id] = names end
    return names
end

-- Tooltips of foreign buffs (2026-11-14): the aura index of an active buff, so the tooltip can show the real
-- buff text (SetUnitBuff, e.g. "Increases Strength by 77."); nil when it is not active.
-- Matches like GetItemBuffState: spell IDs first, then the localized names (lower ranks).
function ns:FindBuffAuraIndex(id)
    local b = ns.buffCatalog[id]
    if not b then return nil end
    if b.mount then
        local a = ns:MountAura()
        return a and a.index
    end
    for _, a in ipairs(auraList) do
        for _, spellID in ipairs(b.spells) do
            if a.spellId == spellID then return a.index end
        end
    end
    local names = ns:GetBuffNames(id)
    for _, a in ipairs(auraList) do
        for _, n in ipairs(names) do
            if a.name == n then return a.index end
        end
    end
    return nil
end

-- spell for the tooltip of a missing buff: tipSpell (totem/talent spell with the effect) or the main spell
function ns.BuffTipSpell(b)
    return b.tipSpell or b.spells[1]
end
-- tooltip of a catalog buff that is not active (2026-11-17): the mount entry and the buff counter (2026-11-25) have
-- no spell of their own, only their name
function ns.SetBuffTip(b)
    if b.mount or b.counter then
        GameTooltip:SetText(ns.EntryName(b.id), 1, 1, 1)
    else
        GameTooltip:SetSpellByID(ns.BuffTipSpell(b))
    end
end

-- Returns: isActive, expirationTime, duration
function ns:GetItemBuffState(itemID)
    local mb = ns.buffCatalog[itemID]
    if mb and mb.mount then return ns.mounted == true, 0, 0 end
    for _, spellID in ipairs(ns:GetBuffSpellsForItem(itemID)) do
        local exp = active[spellID]
        if exp then
            return true, exp, activeDuration[spellID]
        end
    end
    if ns.buffCatalog[itemID] then
        for _, name in ipairs(ns:GetBuffNames(itemID)) do
            local exp = activeByName[name]
            if exp then return true, exp, 0 end
        end
    end
    return false
end
