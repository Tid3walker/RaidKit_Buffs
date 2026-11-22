-- RaidKit Buffs: Bar
-- Builds the rows of secure buttons (click = use item) and updates their state.
--
-- Important: only change position, size, show/hide and attributes of the secure buttons
-- out of combat (BuildBar is only called via ns:RequestRebuild).
-- Visuals (color, texts, cooldown) may be updated at any time.
-- Shared names between the Bar*.lua files: Docs/Architecture.md "Leiste: Aufteilung in Dateien".

local _, ns = ...
local L = ns.L
local B, BS = ns.Bar, ns.BarState
local buttonPool, activeButtons, groupFrames = B.buttonPool, B.activeButtons, B.groupFrames
local shownGroups = B.shownGroups

------------------------------------------------------------------------
-- Build
------------------------------------------------------------------------

-- Icon size and spacing of one row: the values of its group (gs = GroupSettings) or the defaults. Since 2026-11-16 (user)
-- a row has no own size any more (before row.iconSize / spacing / scale / perLine) and never wraps: every row of a
-- group has the group's "Per line" as places (BarSplit.lua).
function ns:RowLayout(rowData, gs)
    if gs then return gs.iconSize, gs.spacing end
    return ns.GEff(nil, "iconSize"), ns.GEff(nil, "spacing")
end

-- effective settings of a group (2026-11-11): own orientation, size, spacing, scale and per line override the
-- bar's ("Alle Gruppen"); row names can be switched off per group
-- Since 2026-11-14 (user) every value on its own: the group's value or the one of "Alle Gruppen" (ns.GEff); before all
-- size values came together with "Eigene Größe"
local function GroupSettings(g)
    local p = ns.profile
    local E = ns.GEff
    return {
        iconSize = E(g, "iconSize"), spacing = E(g, "spacing"), scale = E(g, "scale") or 1, perLine = E(g, "perLine") or 0,
        orientation = g.orientation or "hright", -- own value or the default; read only by the areas since 2026-11-18
        rowSpacing = E(g, "rowSpacing"),
    }
end
ns.GroupSettings = GroupSettings

-- "Rahmen um die Icons" / "Anzahl in Taschen" per group (session 4d, user; before one value for every bar on
-- "Darstellung"): the group's own value; nil = off (no fallback to the profile since session 20)
local function GroupOpt(g, key)
    return g and g[key]
end
local function BordersOn(g) return GroupOpt(g, "showBorders") == true end
-- option "Zeit anzeigen" per group (2026-11-14, user), inherits from "Alle Gruppen" since then (ns.GEff)
local function TimeOn(g) return ns.GEff(g, "showTime") ~= false end

-- font size of the remaining time per group (2026-11-14, user: "Font size" next to "Show time"); only set on change
local function SetTimerSize(fs, size)
    size = size or 10
    if fs.tsize == size then return end
    local font, _, flags = fs:GetFont()
    if font then fs:SetFont(font, size, flags) end
    fs.tsize = size
end
ns.SetTimerSize = SetTimerSize

-- Lays the rows of one group out in its frame. used = buttons of the shared pool taken so far; returns the new count.
local function BuildGroup(f, g, rows, used)
    local gs = GroupSettings(g)
    f:SetScale(gs.scale)
    local istyle = B.IconStyle(g) -- icon border thickness and colours (2026-11-14)
    local tsize = ns.GEff(g, "timeSize") -- font size of the remaining time (2026-11-14)
    for _, l in ipairs(f.labels) do l:Hide() end -- no row names since 2026-11-16 (user: only group names stay)
    f.iconTop = nil -- top of the first icon (B.IconInset: groups beside each other line up their icons, 2026-11-15)

    -- Alignment per row since 2026-11-18 (user; ns.RowAlign, separator menu): left, right or (split rows) both sides.
    -- Before, gs.orientation of the group ("Icons:") put every row left or right. Columns were removed 2026-11-14.
    -- Every row takes the group's icon size/spacing (ns:RowLayout); gs.rowSpacing is the gap between two rows.
    -- The corner a free group grows away from (2026-11-14) follows the rows: left only when every row stands left
    f.alignR = B.RowsAlignRight(rows)
    f.anchorPt = B.AnchorPoint(f.alignR)

    -- first pass: size and length of every row. Rows never wrap since 2026-11-16 (user): one line each, a normal row as
    -- long as its icons; a split row spans the widest row of the group (session 20, user; BarSplit.lua)
    local infos, maxLen = {}, 0
    for r, rowData in ipairs(rows) do
        local size, spacing = ns:RowLayout(rowData, gs)
        local split = ns.IsSplitRow(rowData)
        local len = B.RowLength(rowData, size, spacing)
        infos[r] = { data = rowData, size = size, spacing = spacing, len = len, split = split, align = ns.RowAlign(rowData) }
        maxLen = math.max(maxLen, len)
    end
    -- alignment per row (2026-11-18, user; BarSplit.lua ns.RowAlign): only "both" stretches a split row over the group
    for _, info in ipairs(infos) do
        if info.split and info.align == "both" then info.len = maxLen end
    end

    local function PlaceButton(entry, x, y, size)
        used = used + 1
        local btn = buttonPool[used]
        if not btn then
            btn = B.CreateButton(used)
            buttonPool[used] = btn
        end
        if btn:GetParent() ~= f then
            btn:SetParent(f) -- groups (2026-11-11): the button belongs to its group's frame
            btn:SetFrameLevel(f:GetFrameLevel() + 5)
        end
        btn:SetSize(size, size)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", f, "TOPLEFT", x, -y)
        f.iconTop = math.min(f.iconTop or y, y)
        ns:ApplyUseMode(btn, entry)
        btn.entry = entry -- the profile's own entry: the mouse wheel writes the chosen variant into it
        btn.grp = g -- per-group options (session 4d)
        btn.itemID = ns.EntryPick(entry) -- variant shown (UpdateButton picks the right one)
        btn.useID = nil
        btn.combatLocked = nil
        btn:EnableMouseWheel(ns.IsSlot(entry)) -- plain icons leave the wheel to the camera
        local isWeapon = ns.IsWeaponEntry(entry)
        btn.slotMark:Hide() -- gold square removed (user 2026-11-10); the mouse wheel still switches variants
        btn.handBg:SetShown(isWeapon)
        btn.handMark:SetShown(isWeapon)
        btn.handMark:SetText(isWeapon and (entry.hand == "main" and L["MH"] or L["OH"]) or "")
        btn.icon:SetTexture(ns.EntryIcon(btn.itemID) or 134400) -- 134400 = question mark
        btn.border:SetShown(BordersOn(g)) -- option "Rahmen um die Icons" (2026-11-10, per group since session 4d)
        btn.istyle = istyle -- colours of the border (UpdateButton), 2026-11-14
        B.SetBorderSize(btn.border, istyle.size)
        SetTimerSize(btn.timer, tsize)
        btn:Show()
        activeButtons[#activeButtons + 1] = btn
    end

    local y = 0
    B.ClearSplitMarks(f) -- separators of the split rows (2026-11-17, BarSplit.lua)
    for r, info in ipairs(infos) do
        local size, spacing, rowW = info.size, info.spacing, info.len
        local x0 = info.align == "right" and (maxLen - rowW) or 0 -- right-aligned: the row ends at the right edge
        if r > 1 then y = y + (gs.rowSpacing or 0) end
        if info.split then
            -- split row (2026-11-16, BarSplit.lua): left half from the left, right half from the right of the row
            B.PlaceSplitRow(f, info.data, x0, y, size, spacing, rowW, PlaceButton)
        else
            for i, entry in ipairs(info.data.items) do PlaceButton(entry, x0 + (i - 1) * (size + spacing), y, size) end
        end
        y = y + size
    end
    f.iconBottom = #infos > 0 and y or nil -- bottom of the last icon line (B.IconBottomInset, 2026-11-18)
    local barW, barH = maxLen, y

    local width = math.max(barW, gs.iconSize)
    local height = math.max(barH, gs.iconSize)
    -- placeholder (2026-11-15, = buildGroup in the mockup): "Name (empty)" in a blue box, at least 4 icons wide, 1 high
    f.placeholder = #rows == 0 and g.id ~= "main"
    if f.placeholder then
        width = math.max(4 * (gs.iconSize + gs.spacing) - gs.spacing, B.PlaceholderTextWidth(f, g) + 12)
        height = gs.iconSize
    end
    f:SetSize(width, height)

    -- nothing sticks out left/right of the icons since 2026-11-16 (before the row names; outline, frame and Shift hover
    -- area included them)
    local lw, rw = 0, 0
    f.empty = g.hidden == true -- eye of the group off (2026-11-12): only the main group gets here, as an empty anchor
    if f.placeholder then f.empty = not BS.areaPreview end -- placeholder: only while editing
    f.decoArgs = { -lw, 0, width + lw + rw, height } -- UpdateExtra decorates a placeholder again when editing toggles
    B.Decorate(f, -lw, 0, width + lw + rw, height)
    B.UpdatePlaceholder(f)
    return used
end

function ns:BuildBar()
    if InCombatLockdown() then
        ns.pendingRebuild = true
        return
    end
    if not BS.container then B.CreateContainer() end

    local p = ns.profile
    ns.EnsureGroups(p)
    ns.EnsureGroupPos(p)

    -- Reset everything
    for _, btn in ipairs(buttonPool) do
        btn:Hide()
        btn.itemID = nil
        btn.entry = nil
    end
    wipe(activeButtons)
    wipe(shownGroups)
    for _, f in pairs(groupFrames) do f.built = false end

    -- groups with rows: only visible rows take a line (row.hidden = eye switched off), empty rows none either (2026-11-16,
    -- user; = layoutFromProfile in the mockup); a group without a visible
    -- row is a placeholder while editing (2026-11-15; before not shown), the main group always exists. g.hidden (eye of the group, 2026-11-12) = all its
    -- rows hidden; the main group then stays as an empty anchor (container), what hangs on it takes its place.
    local used = 0
    for _, g in ipairs(p.groups) do
        if not g.area then
            local rows = {}
            for _, rowData in ipairs(p.rows or {}) do
                if not rowData.hidden and not g.hidden and #(rowData.items or {}) > 0
                    and (rowData.group or "main") == g.id then rows[#rows + 1] = rowData end
            end
            -- a group without a visible row is a placeholder (2026-11-15, user): drawn only while editing, like the
            -- area previews (UpdateExtra), so a new empty group can be seen and moved; eye off = not at all
            if g.id == "main" or #rows > 0 or not g.hidden then
                local f = groupFrames[g.id]
                if not f then
                    f = B.CreateGroupFrame("RaidKitBuffsGroup_" .. g.id)
                    groupFrames[g.id] = f
                end
                f.g, f.secure, f.built = g, true, true
                used = BuildGroup(f, g, rows, used)
                shownGroups[#shownGroups + 1] = { g = g, f = f }
            end
        end
    end
    -- groups that are gone or have no visible row (secure buttons inside: only here, out of combat)
    for _, f in pairs(groupFrames) do
        if not f.built then f:Hide() end
    end

    B.LayoutAreas() -- the three buff areas (adds them to shownGroups)
    B.ApplyVisibility()
    B.UpdateExtra() -- draws and measures the areas, then LayoutGroups places every group
    -- once more: the first pass measured the areas before they had a position (no rects yet)
    B.UpdateExtra()
    B.UpdateMover()
end

-- shared with the other Bar*.lua files
B.GroupSettings = GroupSettings
B.GroupOpt = GroupOpt
B.BordersOn = BordersOn
B.TimeOn = TimeOn
B.SetTimerSize = SetTimerSize
