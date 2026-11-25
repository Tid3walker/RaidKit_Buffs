-- RaidKit Buffs: loss report
-- Collects the consumables the loss alarm reported (BarState.lua, LossAlarm) and repeats them in the chat
-- (user 2026-11-24): right after a boss fight (as soon as the player is out of combat) the losses of that fight, and
-- when leaving a raid instance every loss of the visit. Only real alarms count (not the "Test" button), so only Era.

local _, ns = ...
local L = ns.L

local GetInstanceInfo, IsInInstance, InCombatLockdown = GetInstanceInfo, IsInInstance, InCombatLockdown

-- the boss fight going on: { name, losses = { entry, ... } }; ended = waits for the end of combat to be printed
local encounter

-- losses of the current raid visit, per character so a /reload or disconnect inside keeps them:
-- RaidKitBuffsDB.chars[key].raidLosses = { instance = name, list = { { id, left, at = "21:14", boss }, ... } }
local function RaidLog(create)
    local st = RaidKitBuffsDB and RaidKitBuffsDB.chars[ns.CharKey()]
    if not st then return nil end
    if create and not st.raidLosses then st.raidLosses = { list = {} } end
    return st.raidLosses
end

-- item link (clickable in the chat) or the entry's name
local function ItemText(id)
    local _, link = ns.GetItemInfo(id)
    return link or ns.EntryName(id) or tostring(id)
end

local function TimeText(left)
    return ns.Bar.FormatTimeLong(left)
end

-- called by LossAlarm for every real loss
function ns:RecordLoss(id, left)
    local boss = encounter and not encounter.ended and encounter.name or nil
    if encounter and not encounter.ended then
        encounter.losses[#encounter.losses + 1] = { id = id, left = left }
    end
    local log = RaidLog(false)
    if log and log.instance then
        log.list[#log.list + 1] = { id = id, left = math.floor(left), at = date("%H:%M"), boss = boss }
    end
end

local function PrintEncounter()
    local e = encounter
    encounter = nil
    if not e or #e.losses == 0 then return end
    local parts = {}
    for _, l in ipairs(e.losses) do
        parts[#parts + 1] = L["%s (%s left)"]:format(ItemText(l.id), TimeText(l.left))
    end
    ns:Print("%s", L["Lost during %s: %s"]:format(e.name, table.concat(parts, ", ")))
end

-- ENCOUNTER_START / ENCOUNTER_END (Core.lua)
function ns:OnEncounterStart(name)
    encounter = { name = name or "?", losses = {} }
end
function ns:OnEncounterEnd()
    if not encounter then return end
    encounter.ended = true
    if not InCombatLockdown() then PrintEncounter() end -- else at PLAYER_REGEN_ENABLED
end
-- PLAYER_REGEN_ENABLED
function ns:OnLossReportCombatEnd()
    if encounter and encounter.ended then PrintEncounter() end
end

local function PrintRaid(log)
    if #log.list == 0 then
        ns:Print("%s", L["No consumable lost in %s."]:format(log.instance))
        return
    end
    ns:Print("%s", L["Consumables lost in %s: %d"]:format(log.instance, #log.list))
    for _, l in ipairs(log.list) do
        local line = L["%s %s, %s left"]:format(l.at or "", ItemText(l.id), TimeText(l.left))
        if l.boss then line = line .. " (" .. l.boss .. ")" end
        ns:Print("%s", line)
    end
end

-- PLAYER_ENTERING_WORLD: entering a raid starts (or continues) its list; leaving it prints and clears the list. As a
-- ghost (released after a wipe, running back) the list stays, so a wipe does not split the raid in two.
function ns:OnLossReportZone()
    local _, kind = IsInInstance()
    local log = RaidLog(false)
    if kind == "raid" then
        local name = GetInstanceInfo()
        if log and log.instance and log.instance ~= name then
            PrintRaid(log) -- straight from one raid into another
            log = nil
        end
        if not log or not log.instance then
            log = RaidLog(true)
            log.instance, log.list = name, {}
        end
    elseif log and log.instance and not UnitIsDeadOrGhost("player") then
        PrintRaid(log)
        log.instance, log.list = nil, {}
    end
end
