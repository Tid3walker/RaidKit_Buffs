-- RaidKit Buffs: Core
-- Namespace, helpers and API compatibility, profile defaults, SavedVariables init, combat-safe rebuild, errors,
-- events. Row entries: Entries.lua; rows, groups, style: Rows.lua; migrations: Migrations.lua; /rkb: Slash.lua.

local addonName, ns = ...
local L = ns.L

ns.name = addonName
-- same icon as "## IconTexture" in the .toc (Flask of the Titans), also in the title of the options window
ns.ADDON_ICON = "Interface\\Icons\\INV_Potion_62"

------------------------------------------------------------------------
-- Helpers / API compatibility (Classic Era 1.15.x)
------------------------------------------------------------------------

ns.GetItemCount = (C_Item and C_Item.GetItemCount) or GetItemCount
ns.GetItemIcon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
ns.GetItemSpell = (C_Item and C_Item.GetItemSpell) or GetItemSpell
ns.GetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
ns.GetItemCooldown = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown

-- Spell name by ID (GetSpellInfo may be replaced by C_Spell.GetSpellInfo in newer clients)
function ns.GetSpellName(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        return info and info.name
    end
    return GetSpellInfo and (GetSpellInfo(spellID))
end

function ns:Print(msg, ...)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99RaidKit Buffs|r: " .. tostring(msg):format(...))
end

local function CopyTable(src)
    if type(src) ~= "table" then return src end
    local t = {}
    for k, v in pairs(src) do t[k] = CopyTable(v) end
    return t
end
ns.CopyTable = CopyTable

-- Fills in missing keys from defaults (recursively), never overwrites anything.
local function ApplyDefaults(t, defaults)
    for k, v in pairs(defaults) do
        if t[k] == nil then
            t[k] = CopyTable(v)
        elseif type(v) == "table" and type(t[k]) == "table" and k ~= "rows" then
            ApplyDefaults(t[k], v)
        end
    end
end
ns.ApplyDefaults = ApplyDefaults

------------------------------------------------------------------------
-- Settings of a character / saved profile (defaults)
------------------------------------------------------------------------

ns.profileDefaults = {
    iconSize = 30,       -- 30 since 2026-11-10 (user: same default everywhere; before 32)
    spacing = 4,
    scale = 1,
    rowSpacing = 4,      -- gap between two rows (before 2026-11-08 the same as spacing)
    perLine = 0,         -- "Pro Zeile (max.)" of the rows (2026-11-10): 0 = no wrap; row.perLine overrides it
    nameAlign = "right", -- alignment of the group name (2026-11-15, user): "left" | "center" | "right" (ns.NAME_ALIGNS)
    rowNamePos = "topleft", -- default since 2026-11-09 (before: "left"); "left" | "right" | "topleft" | "topright" | "bottomleft" | "bottomright"
    showMode = "raid",  -- where the bar replaces the Blizzard buff bar: "never" | "always" | "party" | "raid" | "group"
                        -- (default "raid" since 2026-11-10, before "group")
                        -- (ns.SHOW_MODES; schema 9 replaced showBar, /rkb show|hide|toggle)
    useMode = "ctrl",   -- "ctrl" (default since schema 8) | "off" (see Bar.lua)
    showRowNames = false, -- off by default since 2026-11-15 (user)
    showCount = false,   -- bag count on the icons; off by default since 2026-11-14 (user)
    showBorders = false, -- option "Rahmen um die Icons" (2026-11-10), every bar; off by default since 2026-11-10 (user)
    -- "Alle Gruppen" defaults that groups inherit (2026-11-14, ns.GROUP_INHERIT): group name, time, its font size
    showGroupName = false,
    showTime = true,
    timeSize = 8, -- 8 since 2026-11-15 (user; before 10)
    -- style = { frame = {...}, sep = {...}, icon = {...} }: values of "Alle Gruppen" that differ from ns.STYLE_DEF
    -- (2026-11-14, Docs/Idea-Style.md); nil = the look before
    -- (attachToBuffs/attachOffsetY removed 2026-11-09; old values stay in the SavedVariables, unused)
    -- top middle of the screen, 25 units (about 1 cm) below the edge (2026-11-21, user: the options window is large on
    -- small screens; before { "CENTER", "UIParent", "CENTER", 0, 150 }). Top centre of the outline, stored again as its
    -- top-left corner by LayoutGroups (NeedsResave) without moving the bar.
    point = { "TOP", "UIParent", "TOP", 0, -25, "outline" },
    -- belong to the character like the position (ns.CHAR_KEYS), 2026-11-09
    -- "hleft" | "hright" | "vdown" | "vup" (ns.ORIENTATIONS); "hright" since 2026-11-14 (user's layout: rows end at the
    -- right edge, "Unwanted Buffs" docked on the left grows away from the bar), before "hleft"
    orientation = "hright",
    otherDock = "bottom",  -- unused since 2026-11-10 (Andocken removed from the options, always "bottom")
    buffOverrides = {}, -- [itemID] = { spellID, ... }
    -- area below the bar (proposal 2026-11-09): buffs that no row shows, counter, unwanted buffs
    showOther = true,   -- unused since 2026-11-09 ("Sonstige" always shown; kept so old profiles stay valid)
    -- (otherPerLine, otherIconSize/Spacing/Scale, debuffPerLine, debuffIconSize/Spacing/Scale: own sizes of "Sonstige"
    -- and "Debuffs" 2026-11-10 to 2026-11-12. Since then "Eigene Größe" on their groups like every group;
    -- ns.EnsureGroups moves old values over once and removes the keys.)
    -- (capReserve removed 2026-11-10: fixed warning steps by free buff slots, see CapLevel in Bar.lua)
    -- unwanted = { -spellID, ... } buffs removed by the red button; class default in ns:EnsureRows
    -- rows = { { name, items = { itemID or { itemID, ..., pick = itemID } or -spellID (foreign buff), ... },
    --            hidden = bool, (kind = "buff" in rows before 2026-11-11: ignored, every row takes both)
    --            iconSize, spacing, scale, perLine = own appearance of the row (nil = bar values),
    --            group = id of its group (2026-11-11, nil = "main") }, ... }
    -- groups (2026-11-11, Docs/Plan-Groups.md; part of "Reihen"): { { id, name, frame, showName, rowNames = false
    --            (row names off), capTint, orientation, iconSize, spacing, scale, perLine, rowSpacing ("Eigene Größe",
    --            all or none; rowSpacing since 2026-11-12; on every group incl. the areas since 2026-11-12, nil =
    --            "Alle Gruppen"), orientation also on the areas
    --            (2026-11-11, nil there = "automatisch": rows aligned like the group they hang on),
    --            showBorders, showCount (session 4d; nil = the profile's showBorders/showCount),
    --            separator (2026-11-14, "Trenner anzeigen"; nil = on for "other"/"debuff", off else, ns.SeparatorOn),
    --            area = "unw" | "other" | "debuff" for the three buff areas }, ... }; ns.EnsureGroups fills it
    -- groupPos (character key like point): [id] = { x, y } (free, centre offset like point) or
    --            { snap = id, side = "bottom" | "top" | "left" | "right" }; the main group's free position = point
}

local function CharKey()
    return (UnitName("player") or "?") .. " - " .. (GetRealmName() or "?")
end
ns.CharKey = CharKey
-- Saving, loading, export/import and the character settings: Profiles.lua

local function InitDB()
    -- fresh install (no SavedVariables yet, user 2026-11-10): the options open at the first login, so the
    -- bar can be set up although the display mode ("Raid") hides it outside a raid
    ns.freshInstall = RaidKitBuffsDB == nil
    RaidKitBuffsDB = RaidKitBuffsDB or {}
    local db = RaidKitBuffsDB
    db.auraLog = nil -- aura log of 2026-11-12 (Four Horsemen diagnosis) was removed again: drop its data
    db.soundScan, db.soundFavs = nil, nil -- temporary sound browser of 2026-11-20 (alarm sounds chosen): drop its data
    db.profiles = db.profiles or {}
    db.chars = db.chars or {}
    -- language (2026-11-14; options: bottom line of "Bars"): account wide, nil = follow the client; texts translate from here on
    if db.language ~= nil and type(db.language) ~= "string" then db.language = nil end
    ns.SetLanguage(db.language)

    -- Schema 2 (Shift+drag): every profile locked once (the lock itself is gone since schema 5)
    if (db.schema or 1) < 2 then
        for _, prof in pairs(db.profiles) do prof.locked = true end
        db.schema = 2
    end
    -- Schema 3: use mode "click" (left-click) became "right" (right-click)
    if db.schema < 3 then
        for _, prof in pairs(db.profiles) do
            if prof.useMode == "click" then prof.useMode = "right" end
        end
        db.schema = 3
    end
    -- Schema 4: every profile starts with use mode "off" once (new default, 2026-11-08)
    if db.schema < 4 then
        for _, prof in pairs(db.profiles) do prof.useMode = "off" end
        db.schema = 4
    end
    -- Schema 5: lock removed (Shift+drag always moves), drop the old key
    if db.schema < 5 then
        for _, prof in pairs(db.profiles) do prof.locked = nil end
        db.schema = 5
    end
    -- Schema 6: own row spacing; existing profiles keep their look (row gap = icon spacing)
    if db.schema < 6 then
        for _, prof in pairs(db.profiles) do
            if prof.rowSpacing == nil then prof.rowSpacing = prof.spacing or 4 end
        end
        db.schema = 6
    end

    -- Schema 7: own settings per character instead of linked profiles (Profiles.lua)
    if db.schema < 7 then
        ns:MigrateToOwnSettings(db)
        db.schema = 7
    end

    -- Schema 8: right-click now removes the buff, so use mode "right" is gone -> "ctrl" (2026-11-08)
    if db.schema < 8 then
        for _, st in pairs(db.chars) do
            if type(st) == "table" and type(st.settings) == "table" and st.settings.useMode == "right" then
                st.settings.useMode = "ctrl"
            end
        end
        for _, p in pairs(db.profiles) do
            if type(p) == "table" and type(p.data) == "table" and p.data.useMode == "right" then
                p.data.useMode = "ctrl"
            end
        end
        db.schema = 8
    end

    -- Schema 9 (2026-11-09): "Leiste anzeigen" (showBar) became the display mode showMode.
    -- Bar switched off -> "never" (Blizzard bar as before), otherwise the default "group".
    if db.schema < 9 then
        local function Migrate(d)
            if type(d) ~= "table" then return end
            if d.showMode == nil then d.showMode = (d.showBar == false) and "never" or "group" end
            d.showBar = nil
        end
        for _, st in pairs(db.chars) do
            if type(st) == "table" then Migrate(st.settings) end
        end
        for _, p in pairs(db.profiles) do
            if type(p) == "table" then Migrate(p.data) end
        end
        db.schema = 9
    end

    -- Schema 10 (2026-11-20, user): own settings are private. The automatic profile named after each character
    -- (st.own, 2026-11-09 to 2026-11-20) is gone; the old ones are deleted for all characters at once (user: "räum mit
    -- weg"). Only profiles saved on purpose stay in the list.
    if db.schema < 10 then
        for _, st in pairs(db.chars) do
            if type(st) == "table" and st.own then
                db.profiles[st.own] = nil
                st.own = nil
            end
        end
        for _, st in pairs(db.chars) do
            if type(st) == "table" and st.base and not db.profiles[st.base] then st.base = nil end
        end
        db.schema = 10
    end

    -- Schema 11 (2026-11-20, user): profiles are fixed copies. The self-saving own profile ("Weg 2", st.own, same day)
    -- is gone; the profile itself stays as a normal saved profile, only the mark is dropped.
    if db.schema < 11 then
        for _, st in pairs(db.chars) do
            if type(st) == "table" then st.own = nil end
        end
        db.schema = 11
    end

    ns:InitCharSettings(db) -- sets ns.profile = own settings of this character
end

------------------------------------------------------------------------
-- Combat-safe rebuild
------------------------------------------------------------------------

-- Layout/content of secure buttons must not change in combat.
-- Requests are queued and applied on PLAYER_REGEN_ENABLED.
function ns:RequestRebuild()
    if not ns.ready then return end
    if InCombatLockdown() then
        if not ns.pendingRebuild then
            ns:Print(L["Change will be applied after combat."])
        end
        ns.pendingRebuild = true
        -- what needs no secure change (bag count, colors ...) shows right away (2026-11-22, user: "Bag count" in
        -- combat had no effect until the next aura or bag event); UpdateAll also runs on UNIT_AURA in combat
        ns:Try("UpdateAll", ns.UpdateAll, ns)
        return
    end
    ns.pendingRebuild = false
    ns:Try("BuildBar", ns.BuildBar, ns)
    ns:Try("UpdateAll", ns.UpdateAll, ns)
end

------------------------------------------------------------------------
-- Error reporting
------------------------------------------------------------------------

-- Runs fn protected. An error does not abort the calling chain
-- (e.g. the options refresh) and is reported once in chat,
-- even when Lua error display is turned off.
local reportedErrors = {}

function ns:Try(label, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        err = tostring(err)
        if not reportedErrors[err] then
            reportedErrors[err] = label
            ns:Print(L["|cffff4040Error|r in %s: %s"], label, err)
            ns:Print(L["Please pass this message on to the developer."])
        end
    end
    return ok
end

-- All errors reported so far as "label: message" (for /rkb debug)
function ns:GetReportedErrors()
    local list = {}
    for err, label in pairs(reportedErrors) do list[#list + 1] = label .. ": " .. err end
    return list
end

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------

local events = CreateFrame("Frame")
ns.events = events

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")

local function OnEvent(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... == addonName then
            InitDB()
            events:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_LOGIN" then
        ns.MigrateAndEnsureRows() -- Migrations.lua
        ns.ready = true
        ns:BuildBar()
        events:RegisterUnitEvent("UNIT_AURA", "player")
        events:RegisterEvent("PLAYER_ENTERING_WORLD")
        events:RegisterEvent("PLAYER_LEAVING_WORLD") -- loading screen: no loss alarm (ns:OnLeavingWorld)
        events:RegisterEvent("BAG_UPDATE_DELAYED")
        events:RegisterEvent("BAG_UPDATE_COOLDOWN")
        events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
        events:RegisterEvent("PLAYER_REGEN_DISABLED")
        events:RegisterEvent("PLAYER_REGEN_ENABLED")
        events:RegisterEvent("PLAYER_DEAD")
        events:RegisterEvent("ENCOUNTER_START") -- boss fight: losses of it in the chat afterwards (LossReport.lua)
        events:RegisterEvent("ENCOUNTER_END")
        events:RegisterEvent("GROUP_ROSTER_UPDATE") -- display mode: party/raid joined or left
        events:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player") -- weapon swapped / weapon enchant applied
        ns:UpdateAll()
        if ns.freshInstall then
            -- shortly after the loading screen, out of combat; the open window also shows the bar
            C_Timer.After(2, function()
                if InCombatLockdown() or ns.optionsOpen then return end
                ns:ToggleOptions()
                ns:Print(L["Welcome! This is where you set up RaidKit Buffs. By default the bar replaces the Blizzard buff bar only in raids (button \"Show\" at the top of this window). /rkb opens this window again."])
            end)
        end
        -- one-time tip: moving and options are only reachable with Shift
        if not RaidKitBuffsDB.shiftTipShown then
            ns:Print(L["Tip: /rkb opens the options. While they are open, the bar is visible and can be dragged; otherwise Shift+drag an icon."])
            RaidKitBuffsDB.shiftTipShown = true
        end
    elseif event == "UNIT_AURA" or event == "UNIT_INVENTORY_CHANGED" then
        ns:UpdateAll()
    elseif event == "PLAYER_LEAVING_WORLD" then
        ns:OnLeavingWorld() -- BarVisibility.lua
    elseif event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" then
        if event == "PLAYER_ENTERING_WORLD" then
            ns:OnEnteringWorld()
            ns:Try("LossReportZone", ns.OnLossReportZone, ns) -- raid entered or left (LossReport.lua)
        end
        ns:MountPickChanged() -- zone (AQ40) decides the mount (2026-11-19)
        ns:UpdateVisibility() -- shows/hides the bar and the Blizzard buff bar (display mode)
        ns:UpdateAll()
    elseif event == "PLAYER_DEAD" then
        ns:OnPlayerDead() -- buffs vanish on death: no loss alarm
    elseif event == "ENCOUNTER_START" then
        ns:OnEncounterStart(select(2, ...)) -- encounterID, encounterName, ...
    elseif event == "ENCOUNTER_END" then
        ns:OnEncounterEnd()
    elseif event == "BAG_UPDATE_DELAYED" or event == "BAG_UPDATE_COOLDOWN" then
        if event == "BAG_UPDATE_DELAYED" then ns:MountPickChanged() end
        ns:UpdateAll()
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        ns:UpdateAll()
        if ns.RefreshOptions then ns:RefreshOptions() end
    elseif event == "PLAYER_REGEN_DISABLED" then
        ns:OnCombatStart()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if ns.pendingRebuild then
            ns:RequestRebuild()
        end
        ns:OnCombatEnd()
        ns:OnLossReportCombatEnd() -- losses of a boss fight in the chat (LossReport.lua)
    end
end

events:SetScript("OnEvent", function(self, event, ...)
    ns:Try(event, OnEvent, self, event, ...)
end)
