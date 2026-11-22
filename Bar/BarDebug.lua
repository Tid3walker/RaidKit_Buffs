-- RaidKit Buffs: BarDebug
-- Diagnostics: /rkb debug, other frames showing the player's aura icons.
-- Shared names between the Bar*.lua files: Docs/Architecture.md "Leiste: Aufteilung in Dateien".

local _, ns = ...
local L = ns.L
local B, BS = ns.Bar, ns.BarState
local activeButtons, shownGroups, FormatTimeLong = B.activeButtons, B.shownGroups, B.FormatTimeLong
local SIDE_NAME = B.SIDE_NAME

-- Other frames that show one of the player's aura icons (2026-11-10, user: "King of the Gordok" showed a
-- second icon outside the bar). Walks all frames once and compares visible textures with the aura icons;
-- RaidKit Buffs's own frames are skipped. Prints name and parent chain, so the source (Blizzard or an addon) is
-- visible without /fstack.
local function FrameLabel(f)
    local ok, name = pcall(function() return f.GetDebugName and f:GetDebugName() or f:GetName() end)
    return ok and name or tostring(f)
end
local function IsOwnFrame(f)
    while f do
        if f == BS.container then return true end
        local name = f.GetName and f:GetName()
        if name and name:find("^RaidKitBuffs") then return true end
        f = f.GetParent and f:GetParent()
    end
    return false
end
local function DebugForeignAuraIcons()
    local icons = {}
    for _, filter in ipairs({ "HELPFUL", "HARMFUL" }) do
        for i = 1, 40 do
            local name, icon = UnitAura("player", i, filter)
            if not name then break end
            if icon then icons[icon] = name end
        end
    end
    if not next(icons) or not EnumerateFrames then return end
    local hits, seen = 0, {}
    local f = EnumerateFrames()
    while f do
        if f:IsVisible() and not IsOwnFrame(f) then
            for _, r in ipairs({ f:GetRegions() }) do
                if r.IsObjectType and r:IsObjectType("Texture") and r:IsVisible() then
                    local aura = icons[r:GetTexture()]
                    local label = aura and FrameLabel(f)
                    if aura and not seen[label] then
                        seen[label] = true
                        hits = hits + 1
                        if hits <= 10 then
                            local parent = f:GetParent()
                            ns:Print(L["Foreign display: %s in %s (parent: %s)"], aura, label,
                                parent and FrameLabel(parent) or "-")
                        end
                    end
                end
            end
        end
        f = EnumerateFrames(f)
    end
    if hits == 0 then
        ns:Print(L["Foreign display: none (no other visible frame shows a buff/debuff icon)"])
    elseif hits > 10 then
        ns:Print(L["Foreign display: %d more left out"], hits - 10)
    end
end

-- ItemRack (user 2026-11-12, raid: its minimap menu lay behind the buffs). RaidKit Buffs does not touch ItemRack (user):
-- its menu hangs on its minimap button, i.e. inside the Minimap, and is drawn with the Minimap's layer (LOW), not
-- with its own "HIGH". So the bar itself goes one layer lower, see BAR_STRATA. The diagnosis
-- "/rkb ebene" for this was removed on 2026-11-20 (problem solved, user: fewer commands).

-- /rkb debug: what the bar thinks about every icon (to track down wrong colours in game)
-- group names (2026-11-15, user: "Show group name" showed only the free line above Buffs & Cons; until 2026-11-20
-- also as "/rkb names", now only part of /rkb debug): per group with rows wanted (GEff showName), name line height, label shown / really visible,
-- alpha, text, anchor point and offsets, frame level and strata. One chat line, also stored in
-- RaidKitBuffsDB.debugNames (read from the SavedVariables after /reload).
function ns:DebugGroupNames()
    local nparts = {}
    for _, e in ipairs(shownGroups) do
        local nl = e.f.nameLabel
        if nl and not e.g.area then
            local p1, rel, p2, x, y = nl:GetPoint(1)
            nparts[#nparts + 1] = string.format("%s: want=%s h=%s shown=%s vis=%s a=%.2f '%s' %s>%s %s/%s rel=%s lvl=%s %s",
                e.g.id, tostring(ns.GEff(e.g, "showName")), tostring(e.f.nameH), tostring(nl:IsShown()),
                tostring(nl:IsVisible()), nl:GetAlpha() or 0, nl:GetText() or "", tostring(p1), tostring(p2),
                tostring(x and math.floor(x)), tostring(y and math.floor(y)), tostring(rel == e.f),
                tostring(e.f:GetFrameLevel()), tostring(e.f:GetFrameStrata()))
        end
    end
    local text = table.concat(nparts, "; ")
    RaidKitBuffsDB.debugNames = text
    ns:Print(L["Group names: %s"], text)
end

function ns:DebugBar()
    ns:Print(L["Debug: %d icons, bar %s"], #activeButtons, BS.container and BS.container:IsShown() and L["visible"] or L["not shown"])
    local debuffFrame = _G.DebuffFrame
    ns:Print(L["Show: %s, party %s, raid %s, replaces Blizzard: %s, BuffFrame %s, DebuffFrame %s, options open: %s, debuffs: %d"],
        tostring(ns.profile.showMode), tostring(IsInGroup()), tostring(IsInRaid()), tostring(ns.replacing == true),
        BuffFrame and (BuffFrame:IsVisible() and L["visible"] or L["hidden"]) or L["missing"],
        debuffFrame and (debuffFrame:IsVisible() and L["visible"] or L["hidden"]) or L["missing"], tostring(ns.optionsOpen == true),
        #(ns.debuffList or {}))
    -- places per row (2026-11-16: "Per line" of the group, rows never wrap): icons / places of every row, "split" =
    -- split row (icons left + right)
    local parts = {}
    for _, rowData in ipairs(ns.profile.rows or {}) do
        if not rowData.hidden then
            local W = ns.GroupWidth(ns.RowGroupOf(rowData))
            local n = #rowData.items
            parts[#parts + 1] = ns.IsSplitRow(rowData)
                and string.format("%s %d+%d/%d %s (%s)", rowData.name or "?", ns.RowSplit(rowData), n - ns.RowSplit(rowData), W, L["split"], ns.RowSepStyle(rowData))
                or string.format("%s %d/%d", rowData.name or "?", n, W)
        end
    end
    ns:Print(L["Places per row: %s"], table.concat(parts, ", "))
    -- groups (2026-11-11): shown or not, free or snapped, box size, still waiting for the end of a fight
    local gparts = {}
    for _, e in ipairs(shownGroups) do
        local q = B.GroupPos(e.g.id)
        local where = q and q.snap and (SIDE_NAME[q.side] or "?") .. " " .. q.snap or L["free"]
        gparts[#gparts + 1] = string.format("%s: %s%s, %dx%d", ns.GroupDisplayName(e.g), where, e.f.empty and L[" (empty)"] or "",
            e.f.box and e.f.box.w or 0, e.f.box and e.f.box.h or 0)
    end
    ns:Print(L["Groups%s: %s"], BS.layoutPending and L[" (position waits for the end of combat)"] or "", table.concat(gparts, "; "))
    ns:DebugGroupNames()
    -- row "Unerwünschte Buffs" (2026-11-10): does the long macro arrive completely? (many costume names)
    local macro = B.UnwantedMacro() or ""
    local _, nLines = macro:gsub("\n", "")
    ns:Print(L["Unwanted: %d entries, macro %d characters, %d lines (/cancelaura)"], #(ns.profile.unwanted or {}),
        #macro, macro == "" and 0 or nLines + 1)
    -- mount (2026-11-17): is the mount recognised, and by which way (mount journal or learned when mounting)
    local ma, learned = ns:MountAura(), {}
    for id in pairs(ns.mountSpells) do learned[#learned + 1] = tostring(id) end
    ns:Print(L["Mount: mounted %s, mount journal %s, aura %s, learned %s"], tostring(ns.mounted == true),
        tostring(C_MountJournal ~= nil and C_MountJournal.GetMountFromSpell ~= nil),
        ma and (tostring(ma.name) .. " " .. tostring(ma.spellId)) or "-", #learned > 0 and table.concat(learned, ",") or "-")
    -- mount for Ctrl+click while not riding (2026-11-19): item or class spell, and whether AQ40 was recognised
    local mp = ns:MountPick()
    ns:Print(L["Mount to use: %s (AQ40: %s)"], mp and (mp.item and ("item " .. mp.item .. " " .. tostring(ns.GetItemInfo(mp.item)))
        or ("spell " .. tostring(mp.spellID) .. " " .. tostring(mp.spell))) or "-", tostring(ns.InAQ40()))
    -- weapon enchants (2026-11-09): raw IDs, to check in game what Windfury does to a stone
    if GetWeaponEnchantInfo then
        local mh, mhMs, _, mhID, oh, ohMs, _, ohID = GetWeaponEnchantInfo()
        local function Hand(has, ms, id)
            if not has then return "-" end
            local name = ns.WINDFURY_ENCHANTS[id] and "Windfury Totem" or (ns.enchantItem[id] and ns.EntryName(ns.enchantItem[id]))
                or ns.WEAPON_ENCHANT_NAMES[id] or "?"
            return L["%s (ID %s, %s left)"]:format(name, tostring(id), FormatTimeLong((ms or 0) / 1000))
        end
        ns:Print(L["Weapon: main hand %s | off hand %s | off-hand weapon: %s"], Hand(mh, mhMs, mhID), Hand(oh, ohMs, ohID),
            tostring(not OffhandHasWeapon or OffhandHasWeapon() and true or false))
    end
    for i, btn in ipairs(activeButtons) do
        local r, g, b = btn.icon:GetVertexColor()
        local spells = table.concat(ns:GetBuffSpellsForItem(btn.itemID), ",")
        ns:Print(L["%d. %s (%d): active=%s count=%s gray=%s color=%.2f/%.2f/%.2f buffs=%s"],
            i, ns.EntryName(btn.itemID) or "?", btn.itemID, tostring(btn.isActive), tostring(btn.bagCount),
            tostring(btn.icon.IsDesaturated and btn.icon:IsDesaturated()), r or -1, g or -1, b or -1, spells)
    end
    -- every active buff (counter / buff cap): index, spell ID, name
    local parts = {}
    for _, a in ipairs(ns.auraList) do parts[#parts + 1] = a.index .. ":" .. tostring(a.spellId) .. " " .. tostring(a.name) end
    -- buff cap detection (2026-11-09): the season "Fresh" has no cap
    local seasonNote = ns.season and ns.NO_CAP_SEASONS[ns.season] and (" = " .. ns.NO_CAP_SEASONS[ns.season]) or ""
    if ns.HAS_BUFF_CAP then
        ns:Print(L["Buff cap: %s (project %s, season %s%s)"], ns.BUFF_CAP, tostring(WOW_PROJECT_ID), tostring(ns.season), seasonNote)
    else
        ns:Print(L["Buff cap: none (project %s, season %s%s)"], tostring(WOW_PROJECT_ID), tostring(ns.season), seasonNote)
    end
    ns:Print(L["Active buffs (%d%s): %s"], #ns.auraList, ns.HAS_BUFF_CAP and ("/" .. ns.BUFF_CAP) or "", table.concat(parts, ", "))
    ns:Try("debug foreign icons", DebugForeignAuraIcons)
    local errors = ns:GetReportedErrors()
    if #errors > 0 then
        ns:Print(L["Errors reported so far:"])
        for _, e in ipairs(errors) do ns:Print("|cffff4040%s|r", e) end
    else
        ns:Print(L["No Lua errors reported."])
    end
end
