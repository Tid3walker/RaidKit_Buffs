-- RaidKit Buffs: Options - group list and the grid of "Unwanted Buffs"
-- Left column (groups and areas; the rows are on the Layout tab of their group since 2026-11-16, OptionsRowStack.lua)
-- and the item grid in the middle (only for the list of "Unwanted Buffs" since 2026-11-16).
-- O = ns.Opt (shared functions and constants), S = ns.OptState (shared state), see OptionsBase.lua.

local _, ns = ...
local L = ns.L
local O, S = ns.Opt, ns.OptState
local content, MAX_ITEMS, LIST_LINES, ROW_LINE_H = O.content, O.MAX_ITEMS, O.LIST_LINES, O.ROW_LINE_H
local ITEM_SIZE, ITEM_GAP, ITEMS_PER_LINE, ITEM_STEP = O.ITEM_SIZE, O.ITEM_GAP, O.ITEMS_PER_LINE, O.ITEM_STEP
local ROWS_X, ROWS_W, GRID_X, MID_W, GRID_Y, COL_BOTTOM = O.ROWS_X, O.ROWS_W, O.GRID_X, O.MID_W, O.GRID_Y, O.COL_BOTTOM
local Place, Label, EditBox, SetTooltip, SmallButton = O.Place, O.Label, O.EditBox, O.SetTooltip, O.SmallButton
local ListLine, ListBackground, Changed, Rows, Solid = O.ListLine, O.ListBackground, O.Changed, O.Rows, O.Solid
local CreatePopup = O.CreatePopup

------------------------------------------------------------------------
-- Build content
------------------------------------------------------------------------

-- a popup menu of entries { label, action } and gold headings { header }
local function FillMenu(menu, entries)
    local y = -6
    for _, e in ipairs(entries) do
        if e.header then
            local h = Label(menu, e.header, "GameFontNormalSmall")
            h:SetPoint("TOPLEFT", 10, y - 4)
            y = y - 20
        else
            local b = CreateFrame("Button", nil, menu)
            b:SetSize(156, 18)
            b:SetPoint("TOPLEFT", 6, y)
            b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            b.text = Label(b, e.label, "GameFontHighlightSmall")
            b.text:SetPoint("LEFT", 4, 0)
            b:SetScript("OnClick", function()
                menu:Hide()
                e.action()
            end)
            y = y - 18
        end
    end
    menu:SetSize(168, -y + 6)
end

-- menu of "+ Row" (OptionsRowStack.lua places it below that button): empty row or a copy of a row template
local function CreateAddMenu()
    S.addMenu = CreatePopup()
    -- every row takes consumables and buffs (2026-11-11): one empty row, one template list
    local entries = {
        { label = L["Empty row"], action = function() O.AddEmptyRow() end },
        { header = L["Templates"] },
    }
    for _, tpl in ipairs(ns:GetRowTemplates()) do
        entries[#entries + 1] = { label = ns.Text(tpl.name), action = function() O.AddTemplateRow(tpl) end }
    end
    FillMenu(S.addMenu, entries)
end

-- menu of "+" in the heading line "Bars" (user 2026-11-20, = groupAddMenu in the mockup): empty group, then below the
-- heading "Presets" the default groups of a new profile (ns.GroupPresets; more may follow)
local function CreateGroupAddMenu()
    S.groupAddMenu = CreatePopup()
    local entries = {
        { label = L["Empty group"], action = function() O.AddGroup() end },
        { header = L["Presets"] },
    }
    for _, p in ipairs(ns.GroupPresets()) do
        entries[#entries + 1] = { label = L[p.name], action = function() O.AddGroup(p) end }
    end
    FillMenu(S.groupAddMenu, entries)
end

local function CreateRowColumn()
    -- 2026-11-12 (user): no heading "Reihen" any more. Since 2026-11-16 (user) the list shows only groups and areas:
    -- "+" = new group, "-" = delete the selected group ("+ Row" is on the Layout tab of a group, OptionsRowStack.lua).
    -- Since session 20 (user) "Alle Gruppen" is gone and both buttons sit right-aligned in the heading line "Leisten"
    -- (the first line of the list; = options-rows.js)
    CreateAddMenu()
    CreateGroupAddMenu()
    -- "+" opens a menu since 2026-11-20 (user): empty group or a preset; below the heading line, left-aligned with it
    content.addGroupBtn = SmallButton("+", ROWS_X, L["New group (empty or preset)"], function()
        if S.addMenu then S.addMenu:Hide() end
        local m = S.groupAddMenu
        if m:IsShown() then m:Hide() return end
        m:ClearAllPoints()
        m:SetPoint("TOPLEFT", content.rowLines[1], "BOTTOMLEFT", 0, -2)
        m:Show()
    end)
    SetTooltip(content.addGroupBtn, L["New group (empty or preset)"],
        L["It appears next to the first group, then drag it where you want it. Add rows with \"+ Row\" on its Layout tab."])
    content.rowDelBtn = SmallButton("-", ROWS_X + 22, L["Delete selected group"], function()
        if S.selectedGroup then O.AskDeleteGroup() end
    end)
    -- Group list (2026-11-11, boxes since 2026-11-12; rows only until 2026-11-16): the categories "Bars" and "Areas",
    -- every group one line. content.listModel[k] = { cat = "bars" | "areas" } | { g = group }, built in RefreshRows. Click = settings in the middle column; a row
    -- dragged by its grip onto a group = into that group (OptionsRowStack.lua).
    local list = ListBackground(ROWS_X, 88, ROWS_W, 1) -- 140 px since 2026-11-16 (before 190)
    list:SetHeight(COL_BOTTOM - 88) -- down to the end of the other columns
    content.rowList = list
    content.rowLines = {}
    content.listModel = {}
    local function LineModel(k) return content.listModel[k] end
    local function Rename(k)
        local m = LineModel(k)
        if m and m.g then O.StartGroupRename(m.g.id) end
    end
    for k = 1, LIST_LINES do
        local line = ListLine(list, ROWS_W)
        line:SetHeight(ROW_LINE_H)
        line:SetPoint("TOPLEFT", 0, -(k - 1) * ROW_LINE_H) -- placed again in RefreshRows (gaps between the boxes)
        -- box look (2026-11-12, mockup .rowline.root/.grp/.sub): background of a header / of "Alle Gruppen" and the
        -- 1 px edges top, bottom, left, right; RefreshRows shows the ones the line needs
        line.grpBg = Solid(line:CreateTexture(nil, "BACKGROUND"), 1, 1, 1, 0.08)
        line.grpBg:SetAllPoints()
        line.grpBg:Hide()
        line.edges = {}
        for e = 1, 4 do line.edges[e] = line:CreateTexture(nil, "BORDER") end
        line.edges[1]:SetPoint("TOPLEFT") line.edges[1]:SetPoint("TOPRIGHT") line.edges[1]:SetHeight(1)
        line.edges[2]:SetPoint("BOTTOMLEFT") line.edges[2]:SetPoint("BOTTOMRIGHT") line.edges[2]:SetHeight(1)
        line.edges[3]:SetPoint("TOPLEFT") line.edges[3]:SetPoint("BOTTOMLEFT") line.edges[3]:SetWidth(1)
        line.edges[4]:SetPoint("TOPRIGHT") line.edges[4]:SetPoint("BOTTOMRIGHT") line.edges[4]:SetWidth(1)
        line.dropGlow = line:CreateTexture(nil, "BACKGROUND", nil, 1)
        line.dropGlow:SetAllPoints()
        line.dropGlow:SetColorTexture(1, 0.82, 0, 0.25)
        line.dropGlow:Hide()
        -- eye of a group (2026-11-12): whole group on the bar; the row count moves left of it
        line.eye = CreateFrame("Button", nil, line)
        line.eye:SetSize(16, 16)
        line.eye:SetPoint("RIGHT", -2, 0)
        line.eye:SetNormalTexture("Interface\\LFGFrame\\LFG-Eye")
        line.eye:GetNormalTexture():SetTexCoord(0, 0.125, 0, 0.25) -- first frame of the eye animation
        line.eye:SetScript("OnClick", function()
            local m = LineModel(k)
            if m and m.g then
                -- eye of a group (2026-11-12, user): hides the whole group on the bar, areas too. Hiding "Sonstige Buffs"
                -- or "Debuffs" asks every time (user: not recommended); showing again never asks
                local g = m.g
                if not g.hidden and O.AREA_HIDE_POPUP[g.area] then
                    O.ShowStaticPopup(O.AREA_HIDE_POPUP[g.area], nil, nil, g)
                else
                    g.hidden = (not g.hidden) or nil
                    Changed()
                end
            end
        end)
        line.eye:SetScript("OnEnter", function(self)
            local m = LineModel(k)
            local g = m and m.g
            if not g then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(g.hidden and L["Hidden - click shows the group in the bar"]
                or L["Visible - click hides the whole group in the bar"])
            if g.area == "unw" then
                GameTooltip:AddLine(L["While hidden, unwanted buffs appear under \"Other Buffs\"."], 0.6, 0.6, 0.6, true)
            end
            GameTooltip:Show()
        end)
        line.eye:SetScript("OnLeave", function() GameTooltip:Hide() end)
        -- pencil = rename this group right here in the list (double-click does the same)
        line.pencil = CreateFrame("Button", nil, line)
        line.pencil:SetSize(14, 14)
        line.pencil:SetPoint("RIGHT", line.eye, "LEFT", -2, 0)
        line.pencil:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
        line.pencil:SetHighlightTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up", "ADD")
        line.pencil:SetScript("OnEnter", function(self)
            local m = LineModel(k)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(L["Rename group"])
            GameTooltip:Show()
        end)
        line.pencil:SetScript("OnLeave", function() GameTooltip:Hide() end)
        line.pencil:SetScript("OnClick", function() Rename(k) end)
        line.info:ClearAllPoints()
        line.info:SetPoint("RIGHT", line.pencil, "LEFT", -3, 0)
        line:SetScript("OnClick", function()
            content.rowNameEdit:ClearFocus() -- cancels a pending rename
            local m = LineModel(k)
            if not m then return end
            if m.cat then
                return -- "Leisten" and "Bereiche" are headings only (session 20, user)
            elseif m.g then
                S.selectedGroup = m.g.id
            end
            ns:RefreshOptions()
        end)
        line:SetScript("OnDoubleClick", function() Rename(k) end)

        content.rowLines[k] = line
    end
    -- "+" and "-" right-aligned in the first line (always the heading "Leisten", session 20), above the line.
    -- Children of the line (= mockup C.rowLines[0].append): a frame level set once on a sibling was lost when the
    -- toplevel window raised itself, then the line covered the buttons and swallowed the clicks (user, after session 20)
    for i, b in ipairs({ content.rowDelBtn, content.addGroupBtn }) do
        b:SetParent(content.rowLines[1])
        b:SetSize(18, 16)
        b:ClearAllPoints()
        b:SetPoint("RIGHT", content.rowLines[1], "RIGHT", -2 - (i - 1) * 22, 0)
        b:SetFrameLevel(content.rowLines[1]:GetFrameLevel() + 2)
    end

    -- Inline rename of a group: the edit box replaces the name of the line (see RefreshRows).
    -- Enter = save, Escape or losing focus = cancel.
    local edit = EditBox(list, ROWS_W - 40)
    edit:SetFrameLevel(list:GetFrameLevel() + 10)
    edit:Hide()
    edit:SetScript("OnEnterPressed", function(self)
        local text = strtrim(self:GetText() or "")
        local g = self.groupId and ns.GroupById(ns.profile, self.groupId)
        -- unchanged text keeps the stored name (a default like "Battle Shout" stays localized, user 2026-11-20)
        if g and text ~= ns.GroupDisplayName(g) then g.name = text end
        self:ClearFocus()
        Changed()
    end)
    edit:SetScript("OnEditFocusLost", function(self)
        self:Hide()
        ns:RefreshOptions()
    end)
    content.rowNameEdit = edit
end

-- Middle column: header = name of the selected group, grid = the list of "Unwanted Buffs" (rows: OptionsRowStack.lua)
local function CreateItemColumn()
    content.itemsLabel = Place(Label(content, ""), GRID_X, 70)
    content.itemsLabel:SetWidth(MID_W) -- narrower while the style tabs are shown (RefreshRows)
    content.itemsLabel:SetWordWrap(false)

    -- the grid takes the whole middle column (2026-11-14): 20 per line, 2 lines for 30 items
    local gridW = MID_W
    local gridH = math.ceil(MAX_ITEMS / ITEMS_PER_LINE) * ITEM_STEP - ITEM_GAP
    local gridArea = CreateFrame("Button", nil, content)
    gridArea:SetSize(gridW + 8, gridH + 8)
    Place(gridArea, GRID_X - 4, GRID_Y - 4)
    local gridBg = gridArea:CreateTexture(nil, "BACKGROUND")
    gridBg:SetAllPoints()
    gridBg:SetColorTexture(0, 0, 0, 0.3)
    local glow = gridArea:CreateTexture(nil, "BORDER")
    glow:SetAllPoints()
    glow:SetColorTexture(1, 0.82, 0, 0.15)
    glow:Hide()
    gridArea:SetScript("OnReceiveDrag", function() O.AddFromCursor() end)
    gridArea:SetScript("OnClick", function() O.AddFromCursor() end)
    content.gridArea, content.gridGlow = gridArea, glow

    -- preview of a group's icons on the Layout tab (2026-11-15, user; mockup C.preview): in the line where "Unerwünschte
    -- Buffs" has its icons (grid y GRID_Y + STAB_DY + 4), grey, no mouse (a plain Frame); RefreshRows fills it. At most
    -- PREVIEW_MAX icons, the label "Preview" keeps the end of the line.
    local PREVIEW_MAX = 17
    local pv = CreateFrame("Frame", nil, content)
    pv:SetSize(gridW + 8, ITEM_STEP - ITEM_GAP + 8)
    Place(pv, GRID_X - 4, GRID_Y + O.STAB_DY)
    local pvBg = pv:CreateTexture(nil, "BACKGROUND")
    pvBg:SetAllPoints()
    pvBg:SetColorTexture(0, 0, 0, 0.3)
    pv.icons = {}
    for i = 1, PREVIEW_MAX do
        local t = pv:CreateTexture(nil, "ARTWORK")
        t:SetSize(ITEM_SIZE, ITEM_SIZE)
        t:SetPoint("TOPLEFT", pv, "TOPLEFT", 4 + (i - 1) * ITEM_STEP, -4)
        t:SetDesaturated(true)
        t:SetAlpha(0.55)
        pv.icons[i] = t
    end
    pv.label = Label(pv, L["Preview"], "GameFontDisableSmall")
    pv.label:SetPoint("RIGHT", pv, "RIGHT", -6, 0)
    pv:Hide()
    content.preview = pv

    content.itemButtons = {}
    for i = 1, MAX_ITEMS do
        local b = CreateFrame("Button", nil, content)
        b:SetSize(ITEM_SIZE, ITEM_SIZE)
        b:SetFrameLevel(gridArea:GetFrameLevel() + 2)
        local col = (i - 1) % ITEMS_PER_LINE
        local line = math.floor((i - 1) / ITEMS_PER_LINE)
        Place(b, GRID_X + col * ITEM_STEP, GRID_Y + line * ITEM_STEP)
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetAllPoints()
        b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        -- gold corner (user 2026-11-12, mockup variant A, instead of the thick gold frame): the icon has
        -- alternatives. A triangle bottom right with a thin dark edge, both made from a square whose upper left
        -- corner is moved onto the upper right one (SetVertexOffset, also used by WeakAuras/Questie in Classic).
        b.altMark = {}
        for k, spec in ipairs({ { 11, 0, 0, 0, 0.7, 0 }, { 9, 1, 0.82, 0, 1, 1 } }) do
            local size = spec[1]
            local t = b:CreateTexture(nil, "OVERLAY", nil, spec[6])
            t:SetSize(size, size)
            t:SetPoint("BOTTOMRIGHT", 0, 0)
            t:SetColorTexture(spec[2], spec[3], spec[4], spec[5])
            t:SetVertexOffset(UPPER_LEFT_VERTEX or 1, size, 0)
            t:Hide()
            b.altMark[k] = t
        end
        -- gold corner: the icon has alternatives (column below on hover)
        b.slotMark = b:CreateTexture(nil, "OVERLAY")
        b.slotMark:SetSize(6, 6)
        b.slotMark:SetPoint("TOPRIGHT", -1, -1)
        Solid(b.slotMark, 1, 0.82, 0, 1)
        b.slotMark:Hide()
        -- weapon entries (2026-11-09): "MH"/"OH" bottom left and 3 points smaller like the bar (2026-11-14);
        -- a click switches main hand / off hand. The width follows the text (RefreshRows).
        local hm = CreateFrame("Button", nil, b)
        hm:SetSize(13, 9)
        hm:SetPoint("BOTTOMLEFT", 0, 0)
        hm:SetFrameLevel(b:GetFrameLevel() + 3)
        hm.bg = Solid(hm:CreateTexture(nil, "BACKGROUND"), 0.43, 0.16, 0.63, 0.95)
        hm.bg:SetAllPoints()
        hm.text = hm:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        do
            local font, size, flags = hm.text:GetFont()
            if font and size then hm.text:SetFont(font, size - 3, flags) end -- same as Bar.lua HAND_MARK_SHRINK
        end
        hm.text:SetPoint("CENTER", 0, 0)
        hm:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        hm:SetScript("OnClick", function()
            local entry = O.CurrentRow() and O.CurrentRow().items[i]
            if not ns.IsWeaponEntry(entry) then return end
            entry.hand = entry.hand == "main" and "off" or "main"
            Changed()
        end)
        hm:SetScript("OnEnter", function(self)
            local entry = O.CurrentRow() and O.CurrentRow().items[i]
            if not ns.IsWeaponEntry(entry) then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(L["Hand: %s"]:format(entry.hand == "main" and L["Main hand"] or L["Off hand"]))
            GameTooltip:AddLine(L["Click: switch main hand/off hand"], 0.6, 0.6, 0.6)
            GameTooltip:Show()
        end)
        hm:SetScript("OnLeave", function() GameTooltip:Hide() end)
        hm:Hide()
        b.handMark = hm
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        b:RegisterForDrag("LeftButton")
        b:SetScript("OnClick", function(self, button)
            if O.AddFromCursor(i) then return end
            if button == "RightButton" then
                O.RemoveAt(i)
            elseif ns.IsSlot(self.entry) and self.entry.pick ~= self.itemID then
                self.entry.pick = self.itemID -- left click: the icon itself becomes the chosen variant
                Changed()
            end
        end)
        b:SetScript("OnReceiveDrag", function() O.AddFromCursor(i) end)
        b:SetScript("OnDragStart", function(self)
            if self.itemID then O.StartDrag(self.itemID, "grid", i) end
        end)
        b:SetScript("OnDragStop", O.FinishDrag)
        b:SetScript("OnEnter", function(self)
            if not self.itemID or S.drag then return end
            O.OpenFlyout(i)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT") -- right of the icon: the column below stays visible
            local buff = ns.buffCatalog[self.itemID]
            if buff then
                ns.SetBuffTip(buff)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(L["Drag: change order"], 0.6, 0.6, 0.6)
                GameTooltip:AddLine(L["Drag out or right-click: remove"], 0.6, 0.6, 0.6)
                GameTooltip:Show()
                return
            end
            GameTooltip:SetItemByID(self.itemID)
            GameTooltip:AddLine(" ")
            if ns.IsSlot(self.entry) and self.entry.pick == self.itemID then
                GameTooltip:AddLine(L["Picked (Ctrl+click uses this one first)"], 1, 0.82, 0)
            elseif ns.IsSlot(self.entry) then
                GameTooltip:AddLine(L["Click: mark as picked"], 0.6, 0.6, 0.6)
            end
            GameTooltip:AddLine(L["Drag: change order"], 0.6, 0.6, 0.6)
            GameTooltip:AddLine(L["Drag out or right-click: remove"], 0.6, 0.6, 0.6)
            if not ns.IsFlaskEntry(self.entry) and not ns.IsBuffID(ns.EntryMain(self.entry)) then
                GameTooltip:AddLine(L["Below: alternatives (drag an item into the empty field)"], 0.6, 0.6, 0.6)
            end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        content.itemButtons[i] = b
    end
    O.CreateFlyout()

    content.emptyHint = Label(content, L["Empty - drag items from the\ncatalog here"], "GameFontDisable")
    content.emptyHint:SetPoint("CENTER", gridArea, "CENTER")
    content.emptyHint:SetJustifyH("CENTER")
end

-- shared with the other options files (ns.Opt)
O.CreateRowColumn, O.CreateItemColumn = CreateRowColumn, CreateItemColumn
