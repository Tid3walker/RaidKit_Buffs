-- RaidKit Buffs: BarState
-- State of the row buttons (active, missing, remaining time, weapon entries) and the loss alarm.
-- Shared names between the Bar*.lua files: Docs/Architecture.md "Leiste: Aufteilung in Dateien".

local _, ns = ...
local L = ns.L
local B, BS = ns.Bar, ns.BarState
local activeButtons, areaFrames, BtnColor = B.activeButtons, B.areaFrames, B.BtnColor
local FormatTimeLong, SetTimer, CatalogDuration = B.FormatTimeLong, B.SetTimer, B.CatalogDuration
local CheckLosses -- defined further down

------------------------------------------------------------------------
-- State
------------------------------------------------------------------------

-- check / cross on the icons (user 2026-11-10: off, the grey icon is enough; maybe an option later)
local SHOW_STATUS_MARKS = false

local STATUS_TEXTURE = {
    ok = "Interface\\RaidFrame\\ReadyCheck-Ready",
    no = "Interface\\RaidFrame\\ReadyCheck-NotReady",
    lock = "Interface\\Buttons\\LockButton-Locked-Up",
}

-- Weapon entry: the hand's enchant (Auras.lua ns:WeaponEntryState). Windfury on the main hand shows the
-- Windfury icon with a blue border and counts as active.
local function UpdateWeaponButton(btn)
    local entry = btn.entry
    local isActive, expiration, activeID, wf, noWeapon, other = ns:WeaponEntryState(entry)
    local useID = B.UseTarget(entry)
    local itemID = activeID or useID or ns.EntryPick(entry)
    local count = ns.GetItemCount(itemID) or 0
    btn.isActive, btn.expiration, btn.bagCount = isActive or false, expiration, count
    btn.duration = CatalogDuration(activeID) -- the game reports no full duration for enchants
    btn.isWindfury, btn.noWeapon, btn.otherEnchant = wf or false, noWeapon or false, other
    btn.activeID = nil -- no loss alarm for weapon enchants (Windfury replaces the stone on purpose)
    if not InCombatLockdown() then btn.useID = useID end
    btn.itemID = itemID
    btn.icon:SetTexture(wf and ns.WINDFURY_ICON or ns.EntryIcon(itemID) or 134400)
    B.UpdateSecure(btn)

    btn.status:SetTexture(isActive and STATUS_TEXTURE.ok or STATUS_TEXTURE.no)
    btn.status:SetShown(SHOW_STATUS_MARKS)
    if isActive then
        btn.icon:SetDesaturated(false)
        btn.icon:SetVertexColor(1, 1, 1)
        if wf then btn.border:SetColorTexture(0.3, 0.66, 1, 1) else btn.border:SetColorTexture(unpack(BtnColor(btn, "active"))) end
    else
        btn.icon:SetDesaturated(true)
        btn.icon:SetVertexColor(0.55, 0.55, 0.55)
        btn.border:SetColorTexture(unpack(BtnColor(btn, "missing")))
    end
    if B.GroupOpt(btn.grp, "showCount") and not wf then
        btn.count:SetText(count)
        if count > 0 then btn.count:SetTextColor(1, 1, 1) else btn.count:SetTextColor(1, 0.2, 0.2) end
        btn.count:Show()
    else
        btn.count:Hide()
    end
    btn.cooldown:Clear()
end

local function UpdateButton(btn)
    if btn.isCounter then return B.UpdateCounterButton(btn) end -- buff counter (2026-11-25, BarAreas.lua)
    -- a pooled button may have shown the counter before: icon back, its number away
    btn.icon:Show()
    if btn.capText then btn.capText:Hide() end
    if btn.isWeapon then return UpdateWeaponButton(btn) end
    local entry = btn.entry
    -- Shown variant: the active one, else what Ctrl+click would use, else the chosen one (red 0)
    local activeID, isActive, expiration, duration
    for _, id in ipairs(ns.EntryIDs(entry)) do
        local a, exp, dur = ns:GetItemBuffState(id)
        if a then activeID, isActive, expiration, duration = id, true, exp, dur break end
    end
    -- full duration for the yellow timer: the aura's own, else the catalog's (buffs matched by name report 0)
    if not duration or duration <= 0 then duration = CatalogDuration(activeID) end
    -- demo (2026-11-10): some inactive icons look active. activeID stays nil, so the loss alarm
    -- never fires for them; removing is switched off for the whole bar while the demo runs.
    local demoExp = not isActive and ns.demo and ns.demo.rows[entry]
    if demoExp then isActive, expiration, duration = true, demoExp, CatalogDuration(ns.EntryPick(entry)) end
    btn.duration = duration
    btn.isDemo = demoExp and true or false -- tooltip + right-click (ns:RemoveDemoRow, 2026-11-11)
    local useID = B.UseTarget(entry)
    local itemID = activeID or useID or ns.EntryPick(entry)
    local count = btn.isBuff and 0 or (ns.GetItemCount(itemID) or 0)
    -- bagCount, not count: btn.count is the FontString that shows the number
    btn.isActive, btn.expiration, btn.bagCount = isActive or false, expiration, count
    btn.activeID = activeID -- for the loss alarm (CheckLosses)
    -- in combat the "item" attribute is frozen, so useID (tooltip) stays what was set before the fight
    if not InCombatLockdown() then btn.useID = useID end

    if btn.itemID ~= itemID or not btn.icon:GetTexture() or btn.icon:GetTexture() == 134400 then
        btn.itemID = itemID
        btn.icon:SetTexture(ns.EntryIcon(itemID) or 134400)
    end
    local mb = ns.buffCatalog[itemID]
    if mb and mb.mount then -- the icon of the real mount while riding (2026-11-17), else the one Ctrl+click mounts (2026-11-19)
        local a = isActive and ns:MountAura()
        local m = not isActive and ns:MountPick()
        btn.icon:SetTexture(a and a.icon or m and m.icon or ns.EntryIcon(itemID))
    end
    B.UpdateSecure(btn)

    if btn.combatLocked then
        btn.status:SetTexture(STATUS_TEXTURE.lock)
        btn.status:Show() -- the lock stays: only it tells why Ctrl+click does nothing in combat
    else
        btn.status:SetTexture(isActive and STATUS_TEXTURE.ok or STATUS_TEXTURE.no)
        btn.status:SetShown(SHOW_STATUS_MARKS)
    end

    if isActive then
        btn.icon:SetDesaturated(false)
        btn.icon:SetVertexColor(1, 1, 1)
        btn.border:SetColorTexture(unpack(BtnColor(btn, "active")))
    else
        btn.icon:SetDesaturated(true)
        btn.icon:SetVertexColor(0.55, 0.55, 0.55)
        btn.border:SetColorTexture(unpack(BtnColor(btn, "missing"))) -- inactive = grey, even with 0 in the bags
    end

    if B.GroupOpt(btn.grp, "showCount") and not btn.isBuff then -- buffs have no bag count
        btn.count:SetText(count)
        if count > 0 then
            btn.count:SetTextColor(1, 1, 1)
        else
            btn.count:SetTextColor(1, 0.2, 0.2)
        end
        btn.count:Show()
    else
        btn.count:Hide()
    end

    -- cooldown swipe only on inactive icons (user 2026-11-10: after drinking, the dark "clock" over the now
    -- active icon is just noise; while the buff is missing it tells when the next one can be used)
    local start, duration, enable
    if not btn.isBuff and not isActive then start, duration, enable = ns.GetItemCooldown(itemID) end
    if start and duration and duration > 1.5 and enable ~= 0 and enable ~= false then
        btn.cooldown:SetCooldown(start, duration)
    else
        btn.cooldown:Clear()
    end
end

-- itemID -> GetTime() until which the icon blinks red (consumable lost, see CheckLosses)
local lostUntil = {}

-- option "Rahmen um die Icons" (2026-11-10, showBorders): off = no border on any bar; a blinking loss
-- alarm still shows its red border (it must never go unnoticed)

function ns:UpdateTimers()
    local now = GetTime()
    local blinkOn = math.floor(now * 2) % 2 == 0
    for _, btn in ipairs(activeButtons) do
        if btn.isActive and btn.expiration and btn.expiration > 0 then
            SetTimer(btn.timer, btn.expiration - now, btn.duration, not B.TimeOn(btn.grp))
            -- open tooltip keeps its remaining time current (2026-11-10, shown to the minute): rebuilt only
            -- when the long text changes, so it does not flicker every frame
            if GameTooltip:IsOwned(btn) then
                local text = FormatTimeLong(btn.expiration - now)
                if btn.tooltipTime ~= text then
                    btn.tooltipTime = text
                    B.Button_OnEnter(btn)
                end
            end
        else
            btn.timer:SetText("")
        end
        local lost = false
        for _, id in ipairs(ns.EntryIDs(btn.entry)) do
            if (lostUntil[id] or 0) > now then lost = true end
        end
        btn.border:SetShown(lost or B.BordersOn(btn.grp))
        if lost then
            btn.border:SetColorTexture(blinkOn and 1 or 0.35, blinkOn and 0.15 or 0, blinkOn and 0.15 or 0, 1)
        elseif btn.blinking then
            btn.border:SetColorTexture(unpack(BtnColor(btn, btn.isActive and "active" or "missing")))
        end
        btn.blinking = lost
    end
    if areaFrames.other then ns:Try("UpdateExtraTimers", B.UpdateAreaTimers) end
end

function ns:UpdateAll()
    if not BS.container or not ns.profile then return end
    ns:ScanAuras()
    for _, btn in ipairs(activeButtons) do
        -- one protected call per button: an error with one item must not leave the rest un-updated
        ns:Try("UpdateButton", UpdateButton, btn)
    end
    ns:Try("CheckLosses", CheckLosses)
    ns:Try("UpdateExtra", B.UpdateExtra)
    ns:UpdateTimers()
end

------------------------------------------------------------------------
-- Loss alarm (proposal 2026-11-09)
-- A consumable buff disappeared although time was left and the player did not remove it himself
-- (right-click on the bar, Blizzard buff frame, unwanted button, death) -> the icon blinks red for
-- 10 s and a chat message appears. Typical cause: the buff cap (Era: 32).
------------------------------------------------------------------------

local watched = {} -- itemID of an active consumable -> expiration time

if CancelUnitBuff then
    hooksecurefunc("CancelUnitBuff", function() ns.lastCancel = GetTime() end)
end

-- Sound of the loss alarm (2026-11-20, user, after Fortitude was pushed off at Loatheb): account wide like the
-- language (RaidKitBuffsDB.lossSound: nil or an unknown key = LOSS_SOUND_DEFAULT, "off" = no sound).
-- First test in the game: of the game's sound kits only RAID_WARNING and TELL_MESSAGE play in Era (the others exist
-- as SOUNDKIT names but have no sound there); the whisper gets lost in a raid (user). Own synthesized sounds were
-- tried and dropped the same day (user: no extra sounds). The user then picked game sounds with a temporary sound
-- browser (every SOUNDKIT name played in the game, lengths measured): raid warning, quest abandoned, murloc.
-- kit = SOUNDKIT name, id = its number (used if the name is missing; the mockup plays the game file from Wowhead, see
-- LOSS_SOUNDS in core.js). The user may still pick ONE own sound later: put the file into Media\Sounds and add
-- { key, label, file = "<name>.ogg" } (PlaySoundFile below already handles it). Channel "Master": also with effects
-- muted.
-- fileId (2026-11-20, user): single game sound files (aggro voices of NPCs and creatures) picked by the user on a
-- listening page of a side session (FileDataIDs and lengths from wago.tools / the Ogg data), played with
-- PlaySoundFile(fileId). The mockup plays the same IDs from Wowhead.
local SOUND_DIR = "Interface\\AddOns\\" .. (...) .. "\\Media\\Sounds\\"
-- header = a heading line in the menu (user 2026-11-20: game sounds and own sounds apart), never a value
ns.LOSS_SOUNDS = {
    { key = "off", label = "Off" },
    { header = true, label = "Game sounds" },
    { key = "RAID_WARNING", label = "Raid warning", kit = "RAID_WARNING", id = 8959 },             -- 1.3 s
    { key = "IG_QUEST_LOG_ABANDON_QUEST", label = "Quest abandoned", kit = "IG_QUEST_LOG_ABANDON_QUEST", id = 846 }, -- 1.3 s
    { key = "MURLOC_AGGRO", label = "Murloc", kit = "MURLOC_AGGRO", id = 416 },                   -- 1.8 s
    { key = "F539959", label = "Dwarf warrior", fileId = 539959 },    -- dwarfmalewarrior1aggroa, 0.3 s
    { key = "F540824", label = "Human pirate", fileId = 540824 },     -- humanmalepirateheavyaggro, 0.9 s
    { key = "F540831", label = "Human peasant", fileId = 540831 },    -- humanpesantmaleaggro, 0.5 s
    { key = "F540839", label = "Human warrior 1", fileId = 540839 },  -- humanwarrior1aggro, 0.8 s
    { key = "F540849", label = "Human warrior 2", fileId = 540849 },  -- humanmalewarrior2aggro, 0.5 s
    { key = "F541306", label = "Orc warrior", fileId = 541306 },      -- orcwarriormale1aggroa, 0.4 s
    { key = "F542792", label = "Undead", fileId = 542792 },           -- undeadmalenpc1aggroa, 0.6 s
    { key = "F547797", label = "Dryad", fileId = 547797 },            -- dryadaggroa, 0.7 s
    -- removed again (user 2026-11-20): Baron Rivendare 544924 (silent in the game), air elemental 548044
    -- own sounds (user 2026-11-20, chosen on a listening page; Freesound, licences in Media\Sounds\CREDITS.txt)
    { header = true, label = "Own sounds" },
    { key = "fail", label = "Fail (retro)", file = "Fail.mp3" },      -- OwlStorm, CC0, 0.4 s
    { key = "nooo", label = "Nooo!", file = "Nooo.mp3" },             -- jorickhoofd, CC BY 4.0, 1.5 s
}
local LOSS_SOUND_DEFAULT = "nooo" -- user 2026-11-20 (before: MURLOC_AGGRO, first RAID_WARNING)

local function SoundEntry(key)
    for _, s in ipairs(ns.LOSS_SOUNDS) do
        if not s.header and s.key == key then return s end
    end
end

function ns.LossSoundList()
    return ns.LOSS_SOUNDS
end

function ns.LossSound()
    local key = RaidKitBuffsDB and RaidKitBuffsDB.lossSound
    return SoundEntry(key) and key or LOSS_SOUND_DEFAULT -- keys of the first version (READY_CHECK ...) fall back
end

-- plays the chosen (or the given) sound; false = the client could not play it (shown by the test)
function ns:PlayLossSound(key)
    local s = SoundEntry(key or ns.LossSound())
    if not s or s.key == "off" then return true end
    if s.file then return PlaySoundFile(SOUND_DIR .. s.file, "Master") and true or false end
    if s.fileId then return PlaySoundFile(s.fileId, "Master") and true or false end
    local kit = SOUNDKIT and SOUNDKIT[s.kit] or s.id
    if not kit then return false end
    return PlaySound(kit, "Master") and true or false
end

-- the alarm itself: icon blinks red for 10 s, chat line with the time that was left, red text in the middle, sound
local function LossAlarm(id, left, test)
    lostUntil[id] = GetTime() + 10
    local name = ns.EntryName(id)
    local msg = L["|cffff4040%s has vanished|r although %s were left (buff cap?)."]:format(name, FormatTimeLong(left))
    ns:Print("%s%s", test and L["[Test] "] or "", msg)
    UIErrorsFrame:AddMessage(L["%s lost!"]:format(name), 1, 0.2, 0.2)
    if not test then ns:RecordLoss(id, left) end -- boss fight / raid summary (Core/LossReport.lua)
    -- several consumables lost at once: one sound
    if GetTime() - (ns.lossSoundAt or 0) < 1 then return end
    ns.lossSoundAt = GetTime()
    if not ns:PlayLossSound() then
        ns:Print(L["The sound '%s' is not available in this client."], ns.Text(SoundEntry(ns.LossSound()).label))
    end
end

-- button "Test" (2026-11-20, user; until the same day also /rkb losstest): the alarm as if the buff cap had pushed off a consumable, without touching any
-- buff. 2026-11-21 (user): a RANDOM elixir, because flasks and Zanza are not pushed off by the buff cap (at least not
-- first), the 1 h consumables are. Order: active elixirs (real remaining time), elixirs on the bar (25 minutes), other
-- active / other consumables, flasks only if nothing else is on the bar.
function ns:TestLoss()
    local tiers, now = { {}, {}, {}, {}, {} }, GetTime()
    for _, btn in ipairs(activeButtons) do
        if not btn.isBuff and not btn.isWeapon then
            local active = btn.isActive and btn.activeID and btn.expiration and btn.expiration > now
            local id = active and btn.activeID or btn.itemID or ns.EntryPick(btn.entry)
            local e = id and ns.catalog[id]
            if id then
                local tier = 5
                if not (e and e.cat == "flask") then
                    tier = ((e and e.cat == "elixir") and 1 or 3) + (active and 0 or 1)
                end
                local list = tiers[tier]
                list[#list + 1] = { id = id, left = active and (btn.expiration - now) or 1500 }
            end
        end
    end
    for _, list in ipairs(tiers) do
        if #list > 0 then
            local c = list[math.random(#list)]
            LossAlarm(c.id, c.left, true)
            return
        end
    end
    ns:Print(L["No consumable on the bar to test the loss alarm with."])
    ns:PlayLossSound()
end

-- Mind control (2026-11-24, user: at Kel'Thuzad every active elixir was reported lost while mind controlled): while
-- the player is charmed the game reports no buffs; afterwards they are back. No alarm while charmed, while the buff
-- list is completely empty (never the buff cap) and LOSS_CHARM_GRACE seconds after a charm. A vanished consumable is
-- only reported LOSS_CONFIRM_DELAY seconds later, if it is still missing and nothing excuses it then (the charm flag
-- may come a moment after the buffs vanish). What is active again afterwards is simply watched again.
local LOSS_CONFIRM_DELAY = 1.5
local LOSS_CHARM_GRACE = 5
local UnitIsCharmed, HasFullControl = UnitIsCharmed, HasFullControl
local pendingLoss = {} -- itemID -> true while a vanished consumable waits for ConfirmLoss

-- why nothing counts as lost right now (nil = a vanished consumable is a real loss)
local function LossExcuse(now)
    if UnitIsCharmed and UnitIsCharmed("player") then
        ns.charmGraceUntil = now + LOSS_CHARM_GRACE
        return "charmed"
    end
    if now < (ns.charmGraceUntil or 0) then return "after charm" end
    if #ns.auraList == 0 then return "no buffs" end
    if (now - (ns.lastCancel or 0)) < 2 then return "removed" end -- right-click, Blizzard buff frame, death
    if UnitIsDeadOrGhost("player") then return "dead" end
    -- loading screen and shortly after it (ns:OnLeavingWorld/OnEnteringWorld): the aura list is not reliable
    if ns.zoning or now < (ns.zoneGraceUntil or 0) then return "zoning" end
    return nil
end

-- Diagnosis (2026-11-24): the last 20 vanished consumables with the verdict, in RaidKitBuffsDB.debugLoss (read from
-- the SavedVariables after /reload). Not shown in the game.
local function LogLoss(id, left, verdict)
    local db = RaidKitBuffsDB
    if not db then return end
    db.debugLoss = db.debugLoss or {}
    local log = db.debugLoss
    log[#log + 1] = string.format("%s %s left=%ds %s charmed=%s control=%s buffs=%d", date("%H:%M:%S"),
        tostring(ns.EntryName(id) or id), math.floor(left), verdict, tostring(UnitIsCharmed and UnitIsCharmed("player")),
        tostring(HasFullControl and HasFullControl()), #ns.auraList)
    while #log > 20 do table.remove(log, 1) end
end

-- active again, or replaced by another variant of the same icon (e.g. a cheaper elixir): no loss
local function IsBackOrReplaced(id)
    for _, btn in ipairs(activeButtons) do
        if btn.isActive and (btn.activeID == id or ns.EntryHas(btn.entry, id)) then return true end
    end
    return false
end

local function ConfirmLoss(id, exp)
    pendingLoss[id] = nil
    local now = GetTime()
    if exp - now <= 1 then return end
    if IsBackOrReplaced(id) then return LogLoss(id, exp - now, "back") end
    local excuse = LossExcuse(now)
    if excuse then return LogLoss(id, exp - now, "excused: " .. excuse) end
    LogLoss(id, exp - now, "ALARM")
    LossAlarm(id, exp - now)
end

CheckLosses = function()
    local now = GetTime()
    local current = {}
    for _, btn in ipairs(activeButtons) do
        if not btn.isBuff and btn.activeID and btn.expiration and btn.expiration > 0 then
            current[btn.activeID] = btn.expiration
        end
    end
    local excuse = LossExcuse(now)
    for id, exp in pairs(watched) do
        if not current[id] and exp - now > 2 and not IsBackOrReplaced(id) then
            if excuse then
                LogLoss(id, exp - now, "excused: " .. excuse)
            elseif not pendingLoss[id] then
                pendingLoss[id] = true
                C_Timer.After(LOSS_CONFIRM_DELAY, function() ns:Try("ConfirmLoss", ConfirmLoss, id, exp) end)
            end
        end
    end
    watched = current
end
