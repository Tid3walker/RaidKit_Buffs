-- RaidKit Buffs: Options - refresh of the options window
-- Shows, places and fills the widgets of the page "Bars" for the selection (group with its rows, area, "All Groups").
-- O = ns.Opt (shared functions and constants), S = ns.OptState (shared state), see OptionsBase.lua.

local _, ns = ...
local L = ns.L
local O, S = ns.Opt, ns.OptState
local content, MAX_ITEMS, ROW_LINE_H, ITEM_GAP = O.content, O.MAX_ITEMS, O.ROW_LINE_H, O.ITEM_GAP
local ITEMS_PER_LINE, ITEM_STEP, GRID_X, MID_W, COL_RS = O.ITEMS_PER_LINE, O.ITEM_STEP, O.GRID_X, O.MID_W, O.COL_RS
local GRID_Y, MAX_UNWANTED, CB_Y, CB_STEP = O.GRID_Y, O.MAX_UNWANTED, O.CB_Y, O.CB_STEP
local Place, SetButtonEnabled, Rows, Flow, TOP_Y, OPT_Y = O.Place, O.SetButtonEnabled, O.Rows, O.Flow, O.TOP_Y, O.OPT_Y
local COL_BOTTOM = O.COL_BOTTOM

------------------------------------------------------------------------
-- Refresh
------------------------------------------------------------------------

local LIST_INDENT = 8 -- groups and rows below the categories (2026-11-15)

-- grey examples on the Layout tab of "Other" and "Debuffs" (2026-11-15, user; mockup PREVIEW_ICONS): buffs/debuffs no
-- row covers, all in Classic Era (Power Infusion, Innervate, Kiss of the Spider, Earthstrike, Mind Quickening; Weakened
-- Soul, Forbearance, Recently Bandaged)
local PREVIEW_ICONS = {
    other = { "spell_holy_powerinfusion", "spell_nature_lightning", "inv_trinket_naxxramas04", "spell_nature_abolishmagic",
        "spell_nature_wispheal" },
    debuff = { "spell_holy_ashestoashes", "spell_holy_removecurse", "inv_misc_bandage_08" },
}
-- "Position: ..." of the group panel: side and end in words by ns.SlotName (BarBase.lua, 2026-11-18; before SIDE_NAME here)

local function RefreshRows()
    O.NormalizeGroups() -- rows sorted by group, unknown groups -> main (2026-11-11)
    -- something is always selected since 2026-11-16 (no row selection in the list any more): nothing = the main group
    if not S.selectedGroup then S.selectedGroup = "main" end
    local rows = Rows()
    local grp = O.CurGroup()
    SetButtonEnabled(content.rowDelBtn, grp ~= nil and not grp.area) -- "Buffs & Cons" too since 2026-11-20
    SetButtonEnabled(content.addGroupBtn, O.RowGroupCount() < ns.MAX_GROUPS)

    if S.selectedRow > #rows then S.selectedRow = math.max(#rows, 1) end
    local edit = content.rowNameEdit
    local editing = edit:HasFocus()
    if not editing then edit:Hide() end

    -- list model: the two categories and one line per group (rows until 2026-11-16, since then they are on the Layout
    -- tab of their group; "Alle Gruppen" first from 2026-11-12 until session 20). 12 lines hold everything.
    local model = {}
    -- order of the list (2026-11-15, user; = refreshOptions in the mockup): main group, the three areas, then the other
    -- groups in the order they were added (a new one comes last); the data keeps groups with rows before the areas.
    -- The list is for managing rows, where a group lies on the screen is shown by the bar itself.
    -- Two categories since 2026-11-15 (user; = refreshOptions in the mockup): "Leisten" (groups with rows, main first,
    -- new ones last) and "Bereiche" (Unwanted, Other, Debuffs: filled by the addon, no rows). Groups and rows indented.
    local function PushGroup(g)
        local n = 0
        for _, r in ipairs(rows) do
            if r.group == g.id then n = n + 1 end
        end
        model[#model + 1] = { g = g, n = n, last = true }
    end
    model[#model + 1] = { cat = "bars" }
    for _, g in ipairs(O.Groups()) do
        if not g.area then PushGroup(g) end
    end
    model[#model + 1] = { cat = "areas" }
    for _, g in ipairs(O.Groups()) do
        if g.area then PushGroup(g) end
    end
    content.listModel = model

    -- boxes (user 2026-11-12, mockup proposal B): a grey box per group, 4 px between boxes
    local GOLD, GREY = { 1, 0.82, 0, 0.35 }, { 1, 1, 1, 0.25 }
    local function Edges(line, color, top, bottom, sides)
        local show = { top, bottom, sides, sides }
        for e = 1, 4 do
            line.edges[e]:SetColorTexture(unpack(color))
            line.edges[e]:SetShown(show[e])
        end
    end
    local y = 0
    for k, line in ipairs(content.rowLines) do
        local m = model[k]
        if not m then
            line:Hide()
        else
            if (m.g or m.cat) and k > 1 then y = y + (m.cat and 6 or 4) end -- gap before every group box / category
            local indent = m.cat and 0 or LIST_INDENT
            line:ClearAllPoints()
            line:SetPoint("TOPLEFT", content.rowList, "TOPLEFT", indent, -y)
            line:SetWidth(content.rowList:GetWidth() - indent)
            y = y + ROW_LINE_H
        end
        if not m then
            -- nothing
        elseif m.cat then
            -- category heading, no eye/pencil, no box: "Leisten" and "Bereiche" are headings only (session 20, user;
            -- from 2026-11-15 "Leisten" was clickable with the default of the bag count)
            line.grpBg:Hide()
            Edges(line, GOLD, false, false, false)
            line.eye:Hide()
            line.pencil:Hide()
            line.text:SetPoint("LEFT", line, "LEFT", 2, 0)
            line.text:SetText(string.upper(m.cat == "bars" and L["Bars"] or L["Areas"]))
            line.text:Show()
            line.info:SetText("")
            line:SetSelected(false)
            line.text:SetTextColor(0.6, 0.6, 0.66)
            line:Show()
        elseif m.g then
            -- group header: no eye, row count right (empty for the buff areas); areas look like any group
            local g = m.g
            line.grpBg:SetColorTexture(1, 1, 1, 0.08)
            line.grpBg:Show()
            Edges(line, GREY, true, m.last, true)
            -- eye of the group (2026-11-12): like a row's, pale while the group is hidden
            line.eye:Show()
            line.eye:GetNormalTexture():SetDesaturated(g.hidden == true)
            line.eye:GetNormalTexture():SetAlpha(g.hidden and 0.35 or 1)
            line.pencil:Show()
            line.text:SetPoint("LEFT", line, "LEFT", 4, 0)
            line.text:SetText(O.GroupName(g))
            line.text:SetShown(not (editing and edit.groupId == g.id))
            if S.groupRenameId == g.id and not editing then
                S.groupRenameId = nil
                line.text:Hide()
                edit.groupId, edit.rowIndex = g.id, nil
                edit:ClearAllPoints()
                edit:SetPoint("LEFT", line, "LEFT", 4, 0)
                edit:SetText(ns.GroupDisplayName(g)) -- the shown (localized) name, not the stored key (user 2026-11-20)
                edit:Show()
                edit:SetFocus()
                edit:HighlightText()
                editing = true
            end
            line.info:SetText(g.area and "" or m.n)
            local sel = S.selectedGroup == g.id
            line:SetSelected(sel)
            if not sel then
                if g.hidden then line.text:SetTextColor(0.5, 0.5, 0.5) else line.text:SetTextColor(0.78, 0.78, 0.82) end
            end
            line:Show()
        end
    end
    -- middle column: settings of the selected group (2026-11-11; "Alle Gruppen" until session 20)
    -- style tabs (2026-11-14): "Layout" or one of the style panels
    local styled = grp ~= nil and S.styleTab ~= "layout"
    -- "Unerwünschte Buffs" (session 4b): its list in the grid like a row, the group settings below the grid
    local unwSel = grp ~= nil and grp.area == "unw"
    -- the grid is only for the list of "Unwanted Buffs" since 2026-11-16 (rows: OptionsRowStack.lua)
    content.gridArea:SetShown(unwSel and not styled)
    local gridLines = math.ceil((unwSel and MAX_UNWANTED or MAX_ITEMS) / ITEMS_PER_LINE)
    content.gridArea:SetHeight(gridLines * ITEM_STEP - ITEM_GAP + 8)
    -- "Unerwünschte Buffs" has the style tabs on the line below the heading (2026-11-14): its grid one line lower;
    -- rows have no tabs, their grid stays at GRID_Y. +4: 2 px between the tabs and the grid frame, as below a heading
    local gridY = GRID_Y + (unwSel and O.STAB_DY + 4 or 0) -- two tab lines since 2026-11-15
    if content.gridY ~= gridY then
        content.gridY = gridY
        Place(content.gridArea, GRID_X - 4, gridY - 4)
        for i, b in ipairs(content.itemButtons) do
            Place(b, GRID_X + ((i - 1) % ITEMS_PER_LINE) * ITEM_STEP, gridY + math.floor((i - 1) / ITEMS_PER_LINE) * ITEM_STEP)
        end
    end
    for _, w in ipairs(content.grpPanel) do
        local show = grp ~= nil and not styled
        if show and content.grpNotArea[w] then show = not grp.area end
        if show and content.grpAreaOnly[w] then show = grp.area and true or false end
        -- debuffs do not count towards the buff cap: no "Buff-Limit-Färbung" there (session 4c, user)
        if show and w == content.gCapCb then show = grp.area ~= "debuff" end

        w:SetShown(show)
        if not show and w.menu then w.menu:Hide() end
    end
    -- style tabs and their panels (2026-11-14)
    for _, b in ipairs(content.styleTabs) do
        b:SetShown(grp ~= nil)
        local on = b.key == S.styleTab
        b:SetText(on and b.label or ("|cff808080" .. b.label .. "|r"))
        if on then b:LockHighlight() else b:UnlockHighlight() end
    end
    content.itemsLabel:SetWidth(MID_W) -- "Like All Groups" is gone (session 20): the heading has the full width
    for sec, list in pairs(content.stylePanel) do
        for _, e in ipairs(list) do
            local show = styled and S.styleTab == sec and (not e.cond or e.cond(grp))
            e.w:SetShown(show and true or false)
            if not show and e.w.menu then e.w.menu:Hide() end
        end
    end
    if styled and S.styleTab == "icon" then
        -- only the colours of this group, from the top without gaps
        local y = TOP_Y + 26
        for _, c in ipairs(content.iconColours) do
            if grp and c.on(grp) then
                Place(c.w, COL_RS, y) -- right column of the style tabs (2026-11-17)
                y = y + 24
            end
        end
        content.styleNotes.icon.y = math.max(TOP_Y + 48, y - 4) + 14 -- below the thickness and the last colour
    end
    if not styled and ColorPickerFrame:IsShown() then ColorPickerFrame:Hide() end
    O.SetCatalogShown(true)
    if grp then
        local q = type(ns.profile.groupPos) == "table" and ns.profile.groupPos[grp.id]
        local tg = type(q) == "table" and q.snap and ns.GroupById(ns.profile, q.snap)
        -- with the end of the side (2026-11-18, eight snap points); another group on the same side of the same target: a
        -- note, they can overlap when one of them grows (= refreshOptions in the mockup)
        local text = L["Position: free"]
        if tg then
            local tf = ns.Bar.groupFrames[tg.id] or ns.Bar.areaFrames[tg.id]
            text = L["Position: snapped %s \"%s\""]:format(ns.SlotName(q.side, ns.Bar.SlotAlign(q, tf)), O.GroupName(tg))
            for k, o in pairs(ns.profile.groupPos) do
                if k ~= grp.id and type(o) == "table" and o.snap == q.snap and o.side == q.side then
                    local mg = ns.GroupById(ns.profile, k)
                    text = text .. "\n" .. L["Shares this side with \"%s\": they can overlap if one grows."]:format(mg and O.GroupName(mg) or "?")
                    break
                end
            end
        end
        content.gPosText:SetText(text)
        content.gFreeBtn:SetShown(tg and not styled and true or false) -- hidden on the style tabs (2026-11-14)
    end
    -- top-aligned (2026-11-15, user; = refreshOptions in the mockup): every shown line of the middle column one below
    -- the other from the top, nothing overlaps and nothing is kept free that the view does not need; groups, "All
    -- Bars", "Bars" and the notes of the style tabs alike. An option a group does not have leaves no gap. "Unwanted
    -- Buffs" starts below its grid. Rows keep their size block at the bottom (room for the alternatives column).
    -- "Names: ..." and "Font size" sit right of their checkbox (pair, centred on it).
    local function CbLine(w) return { w = w, h = CB_STEP, pair = w.pair } end
    -- Layout tab (2026-11-15, user): heading "Options" with a line at OPT_Y on every page (below the icon line of
    -- "Unerwünschte Buffs", the same height everywhere), the options below it top-aligned; the size sliders of the
    -- group below the checkboxes since 2026-11-16 (user)
    local optOn = not styled and grp ~= nil
    for _, w in ipairs(content.optHead) do w:SetShown(optOn and true or false) end
    -- the rows of a group on its Layout tab (2026-11-16, user; OptionsRowStack.lua): "Options" starts below them
    local optY = O.LayoutRowStack(grp, styled) or OPT_Y
    Place(content.optHead[1], GRID_X, optY)
    Place(content.optHead[2], GRID_X, optY + 20)
    if grp and not styled then
        -- 2026-11-16 (user; = refreshOptions in the mockup): checkboxes on the left, their controls on the right; "Icons:
        -- ..." right of the first checkbox line without a partner ("Bag count", or "Buff cap tint" for the areas), own
        -- line on the right if there is none (Debuffs; a checkbox line high like there, so the gap to "Orientation" is
        -- the same as on Other Buffs). Below them a fine line and the five size sliders in two columns (tab "Size"
        -- gone), then the position.
        local count, cap = CbLine(content.gCountCb), CbLine(content.gCapCb)
        local list = { count, cap, CbLine(content.gNameCb), CbLine(content.gTimeCb) }
        if not grp.area then
            -- groups with rows: no "Icons:" since 2026-11-18 (user), the alignment is set per row
        elseif content.gCountCb:IsShown() then
            count.pair = content.gOrientBtn
        elseif content.gCapCb:IsShown() then
            cap.pair = content.gOrientBtn
        else
            -- centred in the line like a pair beside a checkbox (Flow: (24 - 20) / 2 = 2; a fixed 1 left it 1 px higher
            -- than on Other Buffs, user 2026-11-16; the mockup's buttons are 22 px, there it is 1)
            table.insert(list, 1, { w = content.gOrientBtn, dy = (CB_STEP - content.gOrientBtn:GetHeight()) / 2, h = CB_STEP })
        end
        local sz = content.gSizes -- icon size, spacing, scale | per line, row spacing
        list[#list + 1] = { w = content.gSizeLine, dy = 6, h = 12 }
        list[#list + 1] = { w = sz[1], h = 24, pair = sz[4] }
        list[#list + 1] = { w = sz[2], h = 24, pair = sz[5] }
        list[#list + 1] = { w = sz[3], h = 24 }
        list[#list + 1] = { w = content.gPosText, dy = 8, h = 32, also = content.gFreeBtn, alsoDy = -5 }
        Flow(list, optY + 24)
    end
    -- preview (2026-11-15, user): examples for Other / Debuffs, grey and without mouse, only on the Layout tab
    -- ("Unerwünschte Buffs" shows its real list there, a group with rows its real rows since 2026-11-16)
    local pvIcons = {}
    if grp and not styled and (grp.area == "other" or grp.area == "debuff") then
        for _, ic in ipairs(PREVIEW_ICONS[grp.area] or {}) do pvIcons[#pvIcons + 1] = "Interface\\Icons\\" .. ic end
    end
    content.preview:SetShown(#pvIcons > 0)
    for i, t in ipairs(content.preview.icons) do
        t:SetTexture(pvIcons[i])
        t:SetShown(pvIcons[i] ~= nil)
    end
    if styled then
        local notes, list = content.styleNotes[S.styleTab], {}
        for _, n in ipairs(notes) do list[#list + 1] = { w = n, gap = 6 } end
        Flow(list, notes.y)
    end

    local row = unwSel and O.CurrentRow() or nil -- unwanted list: pseudo row (session 4b)
    if grp then
        content.itemsLabel:SetText(L["Group: %s"]:format(O.GroupName(grp)))
    end

    -- not on the style tabs: the icons of "Unerwünschte Buffs" covered the checkbox there (2026-11-15, user)
    local items = (row and not styled) and row.items or {}
    for i, b in ipairs(content.itemButtons) do
        local entry = not (unwSel and i > MAX_UNWANTED) and items[i] or nil
        local itemID = entry and ns.EntryMain(entry) -- slot: first variant; the others are in the column
        b.entry, b.itemID = entry, itemID
        if itemID then
            b.icon:SetTexture(ns.EntryIcon(itemID) or 134400)
            local isWeapon = ns.IsWeaponEntry(entry)
            b.slotMark:Hide() -- gold square removed (user 2026-11-10): the column below shows the alternatives
            local hasAlt = ns.IsSlot(entry) and #entry > 1 -- gold corner (2026-11-12, before a thick gold frame)
            for _, t in ipairs(b.altMark) do t:SetShown(hasAlt) end
            b.handMark:SetShown(isWeapon)
            b.handMark.text:SetText(isWeapon and (entry.hand == "main" and L["MH"] or L["OH"]) or "")
            if isWeapon then b.handMark:SetWidth(math.ceil(b.handMark.text:GetStringWidth()) + 2) end
            b:Show()
        else
            b:Hide()
        end
    end
    content.emptyHint:SetShown(unwSel and not styled and #items == 0)
    O.SyncFlyout(grp) -- the column of a stack icon follows it (OptionsDrag.lua)
end

local function Refresh()
    local prof = ns.profile
    -- 2026-11-20 (user): the name of the loaded/saved profile while the settings equal it, otherwise grey "Own" (the own
    -- settings are always stored for the character anyway); no "(changed)", no "- not saved -"
    local base = ns:GetBaseProfile()
    if base and not ns:IsModified() then
        content.profName:SetText(base)
    else
        content.profName:SetText("|cff808080" .. L["Own##profile"] .. "|r")
    end
    O.RefreshProfilesPage()
    O.RefreshInfoPage() -- live counter and error count of the page "Info" (2026-11-20)
    content.useModeBtn:SetText(ns.USE_MODE_LABEL[prof.useMode] or prof.useMode)
    ns:UpdateDemoButton()
    RefreshRows()
    O.RefreshCatalog()

    for _, c in ipairs(content.controls) do c:Refresh() end
end

-- text of the demo button (2026-11-10); called every second by the demo (Bar.lua), no full refresh
function ns:UpdateDemoButton()
    if not content or not content.demoBtn then return end
    local left = ns:DemoLeft()
    content.demoBtn:SetText(left and L["Stop demo (%d:%02d)"]:format(math.floor(left / 60), left % 60)
        or L["Start demo (1 min.)"])
    if content.demoAddBtn then SetButtonEnabled(content.demoAddBtn, left ~= nil and ns:DemoFree() > 0) end
end

function ns:RefreshOptions()
    if not content or not content:IsVisible() or not ns.profile then return end
    if S.drag then return end -- do not rebuild during drag & drop
    ns:Try("RefreshOptions", Refresh)
end
