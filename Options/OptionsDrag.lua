-- RaidKit Buffs: Options - drag & drop and the alternatives column
-- Own drag & drop (catalog, grid, row list) and the fold-out column below a grid icon.
-- O = ns.Opt (shared functions and constants), S = ns.OptState (shared state), see OptionsBase.lua.

local _, ns = ...
local L = ns.L
local O, S = ns.Opt, ns.OptState
local content, ITEM_SIZE, ITEMS_PER_LINE, ITEM_STEP = O.content, O.ITEM_SIZE, O.ITEMS_PER_LINE, O.ITEM_STEP
local GRID_X, GRID_Y, Place, Changed, Rows, Solid = O.GRID_X, O.GRID_Y, O.Place, O.Changed, O.Rows, O.Solid

------------------------------------------------------------------------
-- Drag & Drop
------------------------------------------------------------------------

local function GridTargetIndex()
    for i, b in ipairs(content.itemButtons) do
        if b:IsShown() and b:IsMouseOver() then return i end
    end
end


-- grid area only counts while it is shown (hidden while a group is selected)
local function OverGrid()
    return content.gridArea:IsShown() and content.gridArea:IsMouseOver()
end

local function HideRowDropGlow()
    for _, l in ipairs(content.rowLines) do l.dropGlow:Hide() end
end

-- Fold-out column with alternatives (defined further down, after StartDrag/FinishDrag)
local UpdateFlyoutHover, FlyoutTarget, HighlightFlyout, DropOnFlyout
-- (FinishDrag: in ns.Opt, assigned below) -- defined below; the dragFrame's OnUpdate needs it already

local function CreateDragFrame()
    S.dragFrame = CreateFrame("Frame", nil, UIParent)
    S.dragFrame:SetFrameStrata("TOOLTIP")
    S.dragFrame:SetSize(ITEM_SIZE, ITEM_SIZE)
    S.dragFrame.icon = S.dragFrame:CreateTexture(nil, "ARTWORK")
    S.dragFrame.icon:SetAllPoints()
    S.dragFrame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    S.dragFrame.icon:SetAlpha(0.8)
    S.dragFrame.hint = S.dragFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    S.dragFrame.hint:SetPoint("TOP", S.dragFrame, "BOTTOM", 0, -2)
    S.dragFrame:Hide()
    S.dragFrame:SetScript("OnUpdate", function(self)
        -- Safety net: a column cell that started the drag can be hidden while dragging (the column of
        -- another icon reuses the cells); a hidden frame may never get OnDragStop.
        if S.drag and not IsMouseButtonDown("LeftButton") then
            O.FinishDrag()
            return
        end
        local x, y = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)
        if S.drag and S.drag.from == "srow" then -- a row by its grip (2026-11-16, OptionsRowStack.lua)
            O.RowDragHover(self, S.drag)
            return
        end
        if S.drag then
            UpdateFlyoutHover(true)
            local ft = FlyoutTarget(S.drag)
            HighlightFlyout(ft)
            if ft and not ft.self then
                content.gridGlow:Hide()
                self.hint:SetText(S.drag.from == "alt" and S.drag.index == content.flyout.index
                    and L["Move"] or "|cff40ff40" .. L["As alternative"] .. "|r")
                return
            end
        end
        local overGrid = OverGrid()
        local overStack = O.OverStack() -- rows of the group (2026-11-16, OptionsRowStack.lua)
        content.gridGlow:SetShown(overGrid)
        if S.drag and (S.drag.from == "grid" or S.drag.from == "alt" or S.drag.from == "stack") and not overGrid and not overStack then
            self.hint:SetText("|cffff4040" .. L["Remove"] .. "|r")
        elseif S.drag and S.drag.from == "catalog" and (overGrid or overStack) then
            local row = overStack and O.StackRowUnderMouse() or O.CurrentRow()
            if row and row.unwanted and not ns.IsBuffID(S.drag.itemID) then
                self.hint:SetText("|cffff4040" .. L["Buffs only"] .. "|r")
            else
                self.hint:SetText(O.RowIndexOf(row, S.drag.itemID) and L["Move"] or "|cff40ff40" .. L["Add"] .. "|r")
            end
        else
            self.hint:SetText("")
        end
    end)
end

local function StartDrag(itemID, from, index)
    if not itemID then return end
    if not S.dragFrame then CreateDragFrame() end
    S.drag = { itemID = itemID, from = from, index = index }
    S.dragFrame.icon:SetTexture(ns.EntryIcon(itemID) or 134400)
    S.dragFrame:Show()
    GameTooltip:Hide()
end

-- Drag a row by its grip (2026-11-16, OptionsRowStack.lua; before by its line in the list). Icon = first item of the row.
local function StartRowDrag(index)
    local row = Rows()[index]
    if not row then return end
    if not S.dragFrame then CreateDragFrame() end
    S.drag = { from = "srow", index = index }
    S.dragFrame.icon:SetTexture(row.items[1] and ns.EntryIcon(ns.EntryMain(row.items[1])) or 134400)
    S.dragFrame:Show()
    GameTooltip:Hide()
end

function O.FinishDrag() -- assigns the local declared above
    if not S.drag then return end
    local d = S.drag
    S.drag = nil
    S.dragFrame:Hide()
    content.gridGlow:Hide()
    HideRowDropGlow()

    if d.from == "srow" then
        O.RowDragDrop(d) -- onto another line or onto a group in the list (OptionsRowStack.lua)
        return
    end

    HighlightFlyout(nil)
    local ft = FlyoutTarget(d)
    if ft then
        if ft.self then ns:RefreshOptions() else DropOnFlyout(d, ft) end
        return
    end

    -- rows of the group (2026-11-16, OptionsRowStack.lua): from them, or dropped onto them
    if d.from == "stack" or O.OverStack() then
        O.StackDrop(d)
        return
    end
    local target = GridTargetIndex()
    local overGrid = OverGrid()
    if d.from == "alt" then
        if overGrid or target then
            O.InsertItem(d.itemID, target) -- the alternative becomes its own icon
        else
            O.TakeFromRow(d.row or O.CurrentRow(), d.itemID) -- dragged out = removed (d.row: column of the stack)
            Changed()
        end
    elseif d.from == "grid" then
        if target then
            if target ~= d.index then O.MoveTo(d.index, target) end
        elseif overGrid then
            O.MoveTo(d.index, #O.CurrentRow().items)
        else
            O.RemoveAt(d.index)
        end
    elseif overGrid or target then
        O.InsertItem(d.itemID, target)
    end
end

------------------------------------------------------------------------
-- Fold-out column with alternatives (like ItemRack)
-- Hovering an icon of the grid (also while dragging) opens a column below it: the icon's alternatives
-- and an empty field. Dropping an item on the empty field adds an alternative, then a new empty field
-- appears (at most ns.MaxVariants variants: 6, food/drinks 11). While dragging, the column stays open until
-- another icon of the grid is hovered. More than FLY_PER_COL fields wrap into a second column to the right
-- (2026-11-11), so the column stays inside the window. Mockup: Docs/mockup/raidkit_buffs.html
-- (renderFlyout / dropOnFlyout).
------------------------------------------------------------------------

local CELL_STEP = ITEM_STEP -- same step as the grid (2026-11-14: 22 + 2, before 30 + 4)
local FLY_PER_COL = 6

-- f.row / f.anchor: column of an icon of the row stack of a split group (2026-11-15), else the selected row's grid
local function FlyoutEntry()
    local row = content.flyout.row or O.CurrentRow()
    local i = content.flyout.index
    return row and i and row.items[i], row
end

local function CloseFlyout()
    local f = content.flyout
    if f.index then
        f.index = nil
        f:Hide()
    end
    f.row, f.anchor = nil, nil
end

-- (RenderFlyout: in ns.Opt, assigned below) -- assigned below

-- row, anchor (2026-11-15): an icon of the rows of a group (OptionsRowStack.lua); nil = icon index of the grid
local function OpenFlyout(index, row, anchor)
    local f = content.flyout
    local cur = row or O.CurrentRow()
    if cur and cur.unwanted then return end -- the unwanted list has no alternatives
    if f.index == index and f.row == row and f:IsShown() then return end
    f.index, f.row, f.anchor = index, row, anchor
    O.RenderFlyout()
end

-- Real item from the cursor (bags) dropped on the column: becomes an alternative
local function AddAltFromCursor(k)
    local kind, itemID = GetCursorInfo()
    if kind == "item" and itemID then
        ClearCursor()
        DropOnFlyout({ from = "catalog", itemID = itemID }, { k = k })
        return true
    end
end

local function CreateFlyoutCell(f, isEmpty)
    local c = CreateFrame("Button", nil, f)
    c:SetSize(ITEM_SIZE, ITEM_SIZE)
    c.pickBorder = c:CreateTexture(nil, "BACKGROUND")
    c.pickBorder:SetPoint("TOPLEFT", -2, 2)
    c.pickBorder:SetPoint("BOTTOMRIGHT", 2, -2)
    Solid(c.pickBorder, 1, 0.82, 0, 1)
    c.pickBorder:Hide()
    c.icon = c:CreateTexture(nil, "ARTWORK")
    c.icon:SetAllPoints()
    c.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    c.glow = c:CreateTexture(nil, "OVERLAY")
    c.glow:SetAllPoints()
    Solid(c.glow, 0.25, 1, 0.25, 0.3)
    c.glow:Hide()
    c.dropLine = c:CreateTexture(nil, "OVERLAY")
    c.dropLine:SetPoint("BOTTOMLEFT", c, "TOPLEFT", 0, 1)
    c.dropLine:SetPoint("BOTTOMRIGHT", c, "TOPRIGHT", 0, 1)
    c.dropLine:SetHeight(3)
    Solid(c.dropLine, 0.1, 0.6, 1, 1)
    c.dropLine:Hide()
    c:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    c:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    if isEmpty then
        Solid(c.icon, 1, 1, 1, 0.06)
        local plus = c:CreateFontString(nil, "OVERLAY", "GameFontDisableLarge")
        plus:SetPoint("CENTER")
        plus:SetText("+")
        c:SetScript("OnClick", function() AddAltFromCursor(nil) end)
        c:SetScript("OnReceiveDrag", function() AddAltFromCursor(nil) end)
        c:SetScript("OnEnter", function(self)
            if S.drag then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(L["Drag an alternative here"])
            GameTooltip:AddLine(L["Catalog item or icon from the row"], 0.6, 0.6, 0.6)
            GameTooltip:Show()
        end)
    else
        c:RegisterForDrag("LeftButton")
        c:SetScript("OnDragStart", function(self)
            if self.itemID then StartDrag(self.itemID, "alt", f.index) end
            if S.drag then S.drag.row = f.row end -- column of the row stack (2026-11-15)
        end)
        c:SetScript("OnDragStop", O.FinishDrag)
        c:SetScript("OnReceiveDrag", function(self) AddAltFromCursor(self.k) end)
        c:SetScript("OnClick", function(self, button)
            if AddAltFromCursor(self.k) then return end
            local entry, row = FlyoutEntry()
            if not ns.IsSlot(entry) or not self.itemID then return end
            if button == "RightButton" then
                O.TakeFromRow(row, self.itemID)
            else
                entry.pick = self.itemID
            end
            Changed()
        end)
        c:SetScript("OnEnter", function(self)
            if S.drag or not self.itemID then return end
            local entry = FlyoutEntry()
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(self.itemID)
            GameTooltip:AddLine(" ")
            if ns.EntryPick(entry) == self.itemID then
                GameTooltip:AddLine(L["Picked (Ctrl+click uses this one first)"], 1, 0.82, 0)
            else
                GameTooltip:AddLine(L["Click: mark as picked"], 0.6, 0.6, 0.6)
            end
            GameTooltip:AddLine(L["Drag: order (= replacement order)"], 0.6, 0.6, 0.6)
            GameTooltip:AddLine(L["Drag out or right-click: remove"], 0.6, 0.6, 0.6)
            GameTooltip:Show()
        end)
    end
    c:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return c
end

local function CreateFlyout()
    local f = CreateFrame("Frame", nil, content)
    f:SetFrameLevel(content.gridArea:GetFrameLevel() + 20)
    f:SetWidth(ITEM_SIZE + 6)
    -- the column takes the mouse itself (2026-11-18, user): over the gaps between its cells and its edge the mouse fell
    -- through to the icons of the next row below, whose OnEnter opened their own column instead
    f:EnableMouse(true)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    Solid(bg, 0.04, 0.04, 0.05, 0.96)
    local edge = f:CreateTexture(nil, "BORDER")
    edge:SetPoint("TOPLEFT", -1, 0)
    edge:SetPoint("BOTTOMRIGHT", 1, -1)
    Solid(edge, 0.42, 0.35, 0.16, 1)
    f.cells = {}
    for k = 1, ns.MAX_VARIANTS_FOOD - 1 do f.cells[k] = CreateFlyoutCell(f, false) end
    f.empty = CreateFlyoutCell(f, true)
    -- without a drag: close as soon as the mouse is neither over the column nor over its icon
    f:SetScript("OnUpdate", function(self)
        if S.drag or not self.index then return end
        local b = self.anchor or content.itemButtons[self.index]
        if not self:IsMouseOver() and not (b and b:IsMouseOver()) then CloseFlyout() end
    end)
    f:Hide()
    content.flyout = f
end

O.RenderFlyout = function()
    local f = content.flyout
    local entry = FlyoutEntry()
    if entry == nil then
        f.index = nil
        f:Hide()
        return
    end
    local ids = ns.EntryIDs(entry)
    -- Flasks and Zanza get no alternatives: no empty field, and no column at all if there is nothing in it
    -- buffs: only the fixed pairs of ns.DEFAULT_ALTS (mage armors, 2026-11-15, user), no empty field
    local isBuff = ns.IsBuffID(ids[1])
    local allowAdd = not ns.IsFlaskEntry(entry) and not isBuff and #ids < ns.MaxVariants(ids[1])
    if #ids == 1 and not allowAdd then
        f.index = nil
        f:Hide()
        return
    end
    local pick = ns.EntryPick(entry)
    if f.anchor then
        Place(f, f.anchor.px - 3, f.anchor.py + ITEM_SIZE) -- below its icon in the row stack (2026-11-15)
    else
        local col = (f.index - 1) % ITEMS_PER_LINE
        local line = math.floor((f.index - 1) / ITEMS_PER_LINE)
        Place(f, GRID_X + col * CELL_STEP - 3, GRID_Y + line * CELL_STEP + ITEM_SIZE)
    end
    -- field n (0-based): column n / FLY_PER_COL, line n % FLY_PER_COL
    local n = 0
    local function PlaceCell(c)
        c:ClearAllPoints()
        c:SetPoint("TOPLEFT", f, "TOPLEFT", 3 + math.floor(n / FLY_PER_COL) * CELL_STEP,
            -(4 + (n % FLY_PER_COL) * CELL_STEP))
        c:Show()
        n = n + 1
    end
    for k, c in ipairs(f.cells) do
        local id = ids[k + 1] -- [1] is the icon in the grid
        c.itemID, c.k = id, k + 1
        c.glow:Hide()
        c.dropLine:Hide()
        if id then
            c.icon:SetTexture(ns.EntryIcon(id) or 134400)
            c.pickBorder:SetShown(ns.IsSlot(entry) and id == pick)
            PlaceCell(c)
        else
            c:Hide()
        end
    end
    f.empty.glow:Hide()
    if allowAdd then
        PlaceCell(f.empty)
    else
        f.empty:Hide()
    end
    local cols = math.max(1, math.ceil(n / FLY_PER_COL))
    f:SetWidth(ITEM_SIZE + 6 + (cols - 1) * CELL_STEP)
    -- no yellow "!" below the cells any more (2026-11-18, user: its note about alternatives that do not overwrite each
    -- other spoke of a green check mark that is gone since 2026-11-10, and it had no use)
    local y = 4 + math.min(n, FLY_PER_COL) * CELL_STEP
    f:SetHeight(y)
    f:Show()
end

-- Opens the column of the grid icon under the mouse. While dragging it stays open until another
-- icon is hovered; without a drag the column's own OnUpdate closes it.
UpdateFlyoutHover = function(dragging)
    local f = content.flyout
    if f:IsShown() and f:IsMouseOver() then return end
    local ic = O.StackIconUnderMouse()
    local i = GridTargetIndex()
    if ic then
        OpenFlyout(ic.i, ic.row, ic)
    elseif i then
        OpenFlyout(i)
    elseif not dragging then
        CloseFlyout()
    end
end

-- Drop target in the open column: { k = position } (k nil = empty field), { self = true } = no-op
FlyoutTarget = function(d)
    local f = content.flyout
    if not f:IsShown() or not f.index or not f:IsMouseOver() then return nil end
    if d.from == "grid" and not f.row and d.index == f.index then return { self = true } end
    if d.from == "stack" and f.row and f.row == O.Rows()[d.r] and d.index == f.index then return { self = true } end
    if f.empty:IsShown() and f.empty:IsMouseOver() then return { cell = f.empty } end
    for _, c in ipairs(f.cells) do
        if c:IsShown() and c:IsMouseOver() then return { cell = c, k = c.k } end
    end
    return { self = true } -- gap or warning inside the column
end

HighlightFlyout = function(ft)
    local f = content.flyout
    if not f then return end
    f.empty.glow:SetShown(ft ~= nil and ft.cell == f.empty)
    for _, c in ipairs(f.cells) do c.dropLine:SetShown(ft ~= nil and ft.cell == c) end
end

-- Adds the dragged item(s) to the icon whose column is open: before position ft.k or at the end.
-- From the grid the whole icon moves in (with its alternatives); every item stays unique in the row.
DropOnFlyout = function(d, ft)
    local f = content.flyout
    local row = f.row or O.CurrentRow()
    local gi = f.index
    if not row or not gi or not row.items[gi] then return end
    -- source of a whole icon: the grid (selected row) or the row stack of a split group (any row of it, 2026-11-15)
    local whole = d.from == "grid" or d.from == "stack"
    local srcRow = d.from == "stack" and O.Rows()[d.r] or row
    if whole and not (srcRow and srcRow.items[d.index]) then return end
    -- buffs get no alternatives by hand, only the fixed pairs of ns.DEFAULT_ALTS (mage armors, 2026-11-15, user);
    -- a column only takes consumables
    local srcMain = whole and ns.EntryMain(srcRow.items[d.index]) or d.itemID
    if srcMain and (ns.IsBuffID(srcMain) or ns.IsBuffID(ns.EntryMain(row.items[gi]))) then
        ns:Print(L["Buffs have no alternatives."])
        return
    end
    -- weapon enchants only combine with weapon enchants (2026-11-09); the same stone may sit on both hands,
    -- so it is not taken out of the other weapon icon
    local targetWeapon = ns.IsWeaponEntry(row.items[gi])
    local srcWeapon
    if whole then srcWeapon = ns.IsWeaponEntry(srcRow.items[d.index]) else srcWeapon = ns.IsWeaponItem(d.itemID) end
    if (srcWeapon and true or false) ~= targetWeapon then
        ns:Print(L["Weapon enchants can only be combined with each other as alternatives."])
        return
    end
    local ids = {}
    if whole then
        for _, id in ipairs(ns.EntryIDs(srcRow.items[d.index])) do ids[#ids + 1] = id end
        O.SpliceItem(srcRow, d.index) -- keeps the halves of a split row (2026-11-15)
        if srcRow == row and d.index < gi then gi = gi - 1 end
    else
        ids[1] = d.itemID
    end
    local sameSlot = d.from == "alt" and d.index == f.index and d.row == f.row
    -- take the items out of other icons of the row
    for _, id in ipairs(ids) do
        local j = O.RowIndexOf(row, id)
        if j and j ~= gi and not sameSlot and not targetWeapon then
            if O.TakeFromRow(row, id) and j < gi then gi = gi - 1 end
        end
    end
    local entry = row.items[gi]
    local slot = { pick = ns.EntryPick(entry), hand = ns.IsWeaponEntry(entry) and entry.hand or nil }
    for _, id in ipairs(ns.EntryIDs(entry)) do slot[#slot + 1] = id end
    local k = ft.k or (#slot + 1)
    for _, id in ipairs(ids) do
        local old
        for i, x in ipairs(slot) do if x == id then old = i end end
        if old ~= 1 then
            if old then
                table.remove(slot, old)
                if old < k then k = k - 1 end
            end
            if #slot >= ns.MaxVariants(slot[1]) then
                ns:Print(L["At most %d variants per icon."], ns.MaxVariants(slot[1]))
                break
            end
            table.insert(slot, math.max(2, math.min(k, #slot + 1)), id)
            k = k + 1
            ns.GetItemInfo(id)
            ns:ClearBuffCache(id)
        end
    end
    row.items[gi] = ns.NormalizeEntry(slot)
    f.index = gi
    if f.row then f.anchor = nil end -- the stack is drawn again; RefreshRows finds the icon (SyncFlyout)
    Changed()
end

-- after a refresh (RefreshRows): the column of a stack icon follows its icon, the grid's closes for groups
local function SyncFlyout(grp)
    local f = content.flyout
    if f.row then
        local b = f.index and O.StackButton(f.row, f.index)
        if b then
            f.anchor = b
            O.RenderFlyout()
        else
            CloseFlyout()
        end
    elseif grp then
        CloseFlyout()
    elseif f.index then
        O.RenderFlyout()
    end
end

-- shared with the other options files (ns.Opt)
O.HideRowDropGlow, O.StartDrag, O.StartRowDrag, O.CloseFlyout = HideRowDropGlow, StartDrag, StartRowDrag, CloseFlyout
O.OpenFlyout, O.CreateFlyout, O.SyncFlyout = OpenFlyout, CreateFlyout, SyncFlyout
