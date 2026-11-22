-- RaidKit Buffs: Core - Slash
-- Slash commands /rkb and /rkbc (/rkb since 2026-11-21, user; the long form removed the same day, user: two are enough; until 2026-11-21 /cbar and /consumebar, addon renamed from ConsumeBar). Split from Core.lua on 2026-11-20.
-- Trimmed on 2026-11-20 (user): only what is useful as a macro or as a way out. Gone, because the options window has a
-- button for it or the diagnosis was for a solved problem: mode, save, row, demo, losstest, names, ebene/strata,
-- lage/position, lock/unlock. /rkb reset resets the position now (before: the settings, = "Default (class) ...").
-- /rkb debug stays for diagnosis in game but is not listed in the help.

local _, ns = ...
local L = ns.L


------------------------------------------------------------------------
-- Slash commands
------------------------------------------------------------------------

SLASH_RAIDKITBUFFS1 = "/rkb"
SLASH_RAIDKITBUFFS2 = "/rkbc"

-- display mode "never" <-> the mode used before (default "group"), e.g. as a macro; applied after combat if needed
-- (RequestRebuild)
local function SetShown(cmd)
    local p = ns.profile
    local off = p.showMode == "never"
    if cmd == "hide" or (cmd == "toggle" and not off) then
        if not off then p.lastShowMode = p.showMode end
        p.showMode = "never"
    else
        p.showMode = (p.lastShowMode and p.lastShowMode ~= "never") and p.lastShowMode or "group"
    end
    ns:RequestRebuild()
    if ns.RefreshOptions then ns:RefreshOptions() end
    local label = p.showMode
    for _, m in ipairs(ns.SHOW_MODES) do if m.key == p.showMode then label = ns.Text(m.label) end end
    ns:Print(L["Show: %s."], p.showMode == "never" and L["Never (Blizzard buff bar)"] or label)
end

-- /rkb profile          saved profiles and the one loaded last
-- /rkb profile <Name>   load it completely (e.g. as a macro for tank <-> damage); position stays
local function Profile(rest)
    if rest == "" then
        local base = ns:GetBaseProfile()
        ns:Print(L["Loaded: %s"], base and (base .. (ns:IsModified() and L[" (modified)"] or "")) or L["- not saved -"])
        local names = ns:GetProfileNames()
        ns:Print(L["Saved profiles: %s"], #names > 0 and table.concat(names, ", ") or L["none"])
        return
    end
    local name
    for _, n in ipairs(ns:GetProfileNames()) do
        if n:lower() == rest:lower() then name = n end
    end
    if name and ns:LoadProfile(name, true, true) then
        ns:Print(L["Profile '%s' loaded. Position unchanged."], name)
    else
        ns:Print(L["Profile '%s' does not exist. /rkb profile lists all."], rest)
    end
end

SlashCmdList.RAIDKITBUFFS = function(input)
    local cmd, rest = (input or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd = cmd:lower()

    if cmd == "" then
        ns:ToggleOptions()
    elseif cmd == "show" or cmd == "hide" or cmd == "toggle" then
        SetShown(cmd)
    elseif cmd == "profile" then
        Profile(rest)
    elseif cmd == "reset" then
        ns:ResetPositions()
        ns:Print(L["Position reset: the bar is back at its default place."])
    elseif cmd == "debug" then
        ns:Try("DebugBar", ns.DebugBar, ns)
    else
        ns:Print(L["Commands: /rkb or /rkbc (options), /rkb show|hide|toggle, /rkb profile [name], /rkb reset (position)"])
    end
end
