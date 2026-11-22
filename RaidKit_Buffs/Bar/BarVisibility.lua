-- RaidKit Buffs: BarVisibility
-- Where the bar is shown (display mode), hiding the Blizzard buff bar, combat start and end, death.
-- Shared names between the Bar*.lua files: Docs/Architecture.md "Leiste: Aufteilung in Dateien".

local _, ns = ...
local B, BS = ns.Bar, ns.BarState
local activeButtons, groupFrames, areaFrames = B.activeButtons, B.groupFrames, B.areaFrames
local shownGroups = B.shownGroups

------------------------------------------------------------------------
-- Visibility and the Blizzard buff bar (2026-11-09)
-- p.showMode decides where the bar is shown; there it replaces the Blizzard buff bar: BuffFrame
-- (buffs and debuffs) and TemporaryEnchantFrame (weapon enchants, since 2026-11-09) are moved onto a
-- hidden frame, like other unit frame addons do. Elsewhere they get their parent back.
-- With the options window open (ns.optionsOpen) the bar is always shown, the Blizzard bar only
-- follows the mode. Only out of combat: the bar holds secure buttons.
------------------------------------------------------------------------

local blizzHider
local blizzParents = {}
local blizzHidden = false

local function SetBlizzardBuffsHidden(hide)
    if hide == blizzHidden then return end
    if hide and not blizzHider then
        blizzHider = CreateFrame("Frame")
        blizzHider:Hide()
    end
    -- DebuffFrame (2026-11-12, raid): the current Classic client shows debuffs in a frame of their own
    -- (DebuffFrame.AuraContainer, found by the aura log), not inside BuffFrame. Blizzard frame, so allowed.
    -- Built as a list without holes: a missing frame must not end ipairs early.
    local frames = {}
    for _, f in ipairs({ BuffFrame or false, TemporaryEnchantFrame or false, _G.DebuffFrame or false }) do
        if f then frames[#frames + 1] = f end
    end
    for _, f in ipairs(frames) do
        if hide then
            blizzParents[f] = f:GetParent()
            f:SetParent(blizzHider)
        else
            f:SetParent(blizzParents[f] or UIParent)
        end
    end
    blizzHidden = hide
end

-- Does the display mode apply right now? (party = group without raid)
function ns:BarModeActive()
    local mode = ns.profile and ns.profile.showMode or "group"
    if mode == "never" then return false end
    if mode == "always" then return true end
    local inRaid, inGroup = IsInRaid(), IsInGroup()
    if mode == "party" then return inGroup and not inRaid end
    if mode == "raid" then return inRaid end
    return inGroup
end

local function ApplyVisibility()
    local active = ns:BarModeActive()
    ns.replacing = active -- debuffs are shown by RaidKit Buffs only while it replaces the Blizzard bar
    local on = active or ns.optionsOpen == true or ns.demo ~= nil -- demo: show the bar too (2026-11-10)
    BS.container:SetShown(on)
    -- groups (2026-11-11): every group with a visible row and the three buff areas follow the main group
    for _, f in pairs(groupFrames) do
        if f ~= BS.container then f:SetShown(on and f.built and true or false) end
    end
    for _, f in pairs(areaFrames) do f:SetShown(on) end
    SetBlizzardBuffsHidden(active)
end

-- Group changes, options window opened/closed. In combat it waits for the rebuild after combat.
function ns:UpdateVisibility()
    if not BS.container then return end
    if InCombatLockdown() then
        ns.pendingRebuild = true
        return
    end
    ApplyVisibility()
    if B.UpdateExtra then B.UpdateExtra() end
    B.UpdateMover()
end

-- PLAYER_REGEN_DISABLED fires before the combat lockdown, so attributes can still change here.
-- Out of combat Ctrl+click is switched off while the buff is active (UpdateSecure). In combat the
-- attributes are frozen, so every button becomes usable now, like a normal action bar. Exception:
-- Flasks/Zanza that are active at the pull stay locked until the fight ends.
function ns:OnCombatStart()
    B.StopMove()
    for _, e in ipairs(shownGroups) do e.f.mover:Hide() e.f.mover:EnableMouse(false) end
    if InCombatLockdown() then return end -- too late, the out-of-combat state stays
    -- the unwanted button may have been switched off for editing: in combat its X must always work (review)
    if areaFrames.unw and areaFrames.unw.button then areaFrames.unw.button:EnableMouse(true) end
    for _, btn in ipairs(activeButtons) do
        if btn.isWeapon then
            -- applying a stone takes 3 s: not in combat
            btn:SetAttribute("ctrl-type1", nil)
        elseif btn.isBuff then
            -- foreign buffs stay unusable; own ones (Battle Shout) can always be cast in combat
            btn:SetAttribute("ctrl-type1", ns.profile.useMode == "ctrl" and btn.selfSpell and "spell" or nil)
        else
            btn.combatLocked = ns.IsFlaskEntry(btn.entry) and btn.isActive or nil
            local target = btn.useID or ns.EntryPick(btn.entry)
            btn:SetAttribute("item", "item:" .. target)
            btn:SetAttribute("ctrl-type1", ns.profile.useMode == "ctrl" and not btn.combatLocked and "item" or nil)
        end
    end
    ns:UpdateAll()
end

-- Buffs vanish on death: that is no loss for the alarm
function ns:OnPlayerDead()
    ns.lastCancel = GetTime()
end

-- Zone change with a loading screen (2026-11-21, user: porting out of MC to Orgrimmar reported every active elixir as
-- lost): between PLAYER_LEAVING_WORLD and PLAYER_ENTERING_WORLD the game briefly reports an empty or partial aura
-- list. No loss alarm from leaving until LOSS_ZONE_GRACE seconds after entering (CheckLosses, BarState.lua).
local LOSS_ZONE_GRACE = 5
function ns:OnLeavingWorld()
    ns.zoning = true
end
function ns:OnEnteringWorld()
    ns.zoning = false
    ns.zoneGraceUntil = GetTime() + LOSS_ZONE_GRACE
end

function ns:OnCombatEnd()
    for _, btn in ipairs(activeButtons) do btn.combatLocked = nil end
    ns:UpdateAll() -- re-applies the out-of-combat rule
    -- a group with secure buttons could not follow its snap target in combat (2026-11-11): place it now
    if BS.layoutPending then B.LayoutGroups() end
    B.UpdateMover()
end

-- shared with the other Bar*.lua files
B.ApplyVisibility = ApplyVisibility
