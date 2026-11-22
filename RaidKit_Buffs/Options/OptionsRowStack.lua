-- RaidKit Buffs: Options - the rows of a group on its Layout tab (2026-11-16, user; mockup js/options-row-stack.js)
-- The list on the left shows only groups; a group shows all its rows on the Layout tab (instead of the grey preview), one
-- line per row, the options of the group below them. No row names any more.
-- A line: grip (drag = move the row: onto another line = there, onto a group in the list = into that group), the places
-- of the group (light squares, "Per line"), the icons, a split row with its X (BarSplit.lua); right of it the checkbox
-- separator choice (2026-11-17, before the checkbox "Split row"), the eye (row hidden on the bar) and "-" (delete the row). Click on a free spot = active row (gold): a click
-- in the catalog adds there. Icons: drag within the row, into another row of the group, out (= removed); right-click
-- removes; the alternatives column opens below every icon. Below the lines: "+ Row" (empty or template, at most
-- MAX_GROUP_ROWS per group).
-- O = ns.Opt (shared functions and constants), S = ns.OptState (shared state), see OptionsBase.lua.

local _, ns = ...
local L = ns.L
local O, S = ns.Opt, ns.OptState
local content, ITEM_SIZE, ITEM_GAP, ITEM_STEP, ITEMS_PER_LINE = O.content, O.ITEM_SIZE, O.ITEM_GAP, O.ITEM_STEP, O.ITEMS_PER_LINE
local GRID_X, GRID_Y, MID_W, Place, Rows, Changed, Solid = O.GRID_X, O.GRID_Y, O.MID_W, O.Place, O.Rows, O.Changed, O.Solid

local STK_PL = 16 -- x of the first place of a full line (grip before it)
-- x of the first place of a line of a group with W places (2026-11-20, user; = stkPL in the mockup): the places stand
-- centred between the grip and the separator box, so a smaller "Per line" shrinks the row towards the middle
local function StkPL(W) return STK_PL + math.floor((ITEMS_PER_LINE - W) * ITEM_STEP / 2) end
-- right of the places: separator choice (box 16 px; checkbox "Split row" until 2026-11-17), eye (16), "-" (14), anchored by their centre (frame sizes of
-- the templates differ). Centres 18 px apart (session 20, user: "take a little room from between the three"): 11 px
-- after the last place, 3 px between them
local SEP_HIT = 10 -- width of the grip around the separator line of a split row (session 20: draggable)
local STK_END = STK_PL + ITEMS_PER_LINE * ITEM_STEP - ITEM_GAP -- 494: right edge of the last place
-- since the fourth in-game test of 2026-11-17 the separator box is 28 px wide (dot variants): centres +22, +47, +65
local STK_CB, STK_EYE, STK_DEL = STK_END + 22, STK_END + 47, STK_END + 65

-- rows of group g: list of { row, index in Rows() }
local function GroupRows(g)
    local out = {}
    for i, r in ipairs(Rows()) do
        if g and (r.group or "main") == g.id then out[#out + 1] = { r, i } end
    end
    return out
end

-- row of group g that holds id (the catalog marks and removes per group since 2026-11-16)
local function GroupRowOf(g, id)
    if not g or g.area then return nil end
    for _, e in ipairs(GroupRows(g)) do
        if O.RowIndexOf(e[1], id) then return e[1] end
    end
end

local function LineUnderMouse()
    local st = content.stack
    if not st or not st:IsShown() then return nil end
    for _, line in ipairs(st.lines) do
        if line:IsShown() and line:IsMouseOver() then return line end
    end
end

local function IconUnderMouse()
    local st = content.stack
    if not st or not st:IsShown() then return nil end
    for _, ic in ipairs(st.icons) do
        if ic:IsShown() and ic:IsMouseOver() then return ic end
    end
end

local function OverStack()
    return content.stack ~= nil and content.stack:IsShown() and content.stack:IsMouseOver()
end

-- icon of the stack for row object r, index i (the alternatives column opens below it)
local function StackButton(r, i)
    if not content.stack or not content.stack:IsShown() then return nil end
    for _, ic in ipairs(content.stack.icons) do
        if ic:IsShown() and ic.row == r and ic.i == i then return ic end
    end
end

-- side of the separator under the mouse: "L" / "R" (nil = normal row)
local function CursorSide(line)
    if not line.sep:IsShown() then return nil end
    local x = GetCursorPosition() / line:GetEffectiveScale()
    local sx = line.sep:GetCenter()
    return (sx and x >= sx) and "R" or "L"
end

-- runs fn on row dst: a split row keeps its halves and puts id into side (OptionsSplit.lua SplitDo)
local function Run(dst, side, id, fn)
    if side then
        O.SplitDo(dst, side, id, fn)
    else
        fn()
        Changed()
    end
end

-- a real item from the cursor (bags) dropped onto a line: at pos or the end of its half
local function AddFromCursorTo(line, pos)
    local kind, itemID = GetCursorInfo()
    if kind ~= "item" or not itemID then return false end
    local row = Rows()[line.ri]
    if not row then return false end
    ClearCursor()
    local side = CursorSide(line)
    local at = pos or (side == "L" and (ns.RowSplit(row) + 1)) or (#row.items + 1)
    Run(row, side, itemID, function() O.InsertItem(itemID, at, row) end)
    return true
end

-- one icon of the stack (pool, created when needed)
local function CreateIcon(st)
    local b = CreateFrame("Button", nil, st)
    b:SetSize(ITEM_SIZE, ITEM_SIZE)
    b:SetFrameLevel(st:GetFrameLevel() + 3)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    -- gold corner = the icon has alternatives
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
    -- weapon entries: "MH"/"OH" bottom left, a click switches the hand (like the grid, OptionsRows.lua)
    local hm = CreateFrame("Button", nil, b)
    hm:SetSize(13, 9)
    hm:SetPoint("BOTTOMLEFT", 0, 0)
    hm:SetFrameLevel(b:GetFrameLevel() + 3)
    hm.bg = Solid(hm:CreateTexture(nil, "BACKGROUND"), 0.43, 0.16, 0.63, 0.95)
    hm.bg:SetAllPoints()
    hm.text = hm:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    do
        local font, size, flags = hm.text:GetFont()
        if font and size then hm.text:SetFont(font, size - 3, flags) end
    end
    hm.text:SetPoint("CENTER", 0, 0)
    hm:SetScript("OnClick", function()
        local entry = b.row and b.row.items[b.i]
        if not ns.IsWeaponEntry(entry) then return end
        entry.hand = entry.hand == "main" and "off" or "main"
        Changed()
    end)
    hm:Hide()
    b.hand = hm
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnClick", function(self, button)
        local line = self.line
        if line and AddFromCursorTo(line, self.i) then return end
        local row, entry = self.row, self.row and self.row.items[self.i]
        if not entry then return end
        if button == "RightButton" then
            GameTooltip:Hide()
            O.SpliceItem(row, self.i)
            Changed()
        elseif ns.IsSlot(entry) and entry.pick ~= self.itemID then
            entry.pick = self.itemID -- the icon itself becomes the chosen variant
            Changed()
        end
    end)
    b:SetScript("OnReceiveDrag", function(self) if self.line then AddFromCursorTo(self.line, self.i) end end)
    b:SetScript("OnDragStart", function(self)
        if not self.itemID then return end
        O.StartDrag(self.itemID, "stack", self.i)
        if S.drag then S.drag.r = self.line and self.line.ri end
    end)
    b:SetScript("OnDragStop", O.FinishDrag)
    b:SetScript("OnEnter", function(self)
        if not self.itemID or S.drag then return end
        O.OpenFlyout(self.i, self.row, self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local buff = ns.buffCatalog[self.itemID]
        if buff then ns.SetBuffTip(buff) else GameTooltip:SetItemByID(self.itemID) end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Drag: change order, also into another row of the group"], 0.6, 0.6, 0.6, true)
        GameTooltip:AddLine(L["Drag out or right-click: remove"], 0.6, 0.6, 0.6)
        local entry = self.row and self.row.items[self.i]
        if not buff and not ns.IsFlaskEntry(entry) then
            GameTooltip:AddLine(L["Below: alternatives (drag an item into the empty field)"], 0.6, 0.6, 0.6)
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

local function Tip(frame, title, text)
    frame:SetScript("OnEnter", function(self)
        if S.drag then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(type(title) == "function" and title() or title)
        if text then GameTooltip:AddLine(text, 0.6, 0.6, 0.6, true) end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- = stackSlots in the mockup (2026-11-18, user: "alignment and separator visible in the options at once"): the place
-- of every icon of row r in a line of W places, like on the bar. A normal row from the left or the right; a split row
-- "left"/"right": both halves together at that edge with g empty places between them (the separator: its places, else
-- 1; none if the row is full); "both": the left half from the left, the right half from the right, the free places
-- between them. Returns slots (place of icon i, 0-based), gapFrom, gapTo (places of the gap, gapTo exclusive);
-- gapFrom = gapTo = the place after the left half when there is no gap.
local function StackSlots(r, W)
    local n, al, slots = #r.items, ns.RowAlign(r), {}
    if not ns.IsSplitRow(r) then
        local off = al == "right" and (W - n) or 0
        for i = 1, n do slots[i] = off + i - 1 end
        return slots
    end
    local s, k = ns.RowSplit(r), ns.SEP_BY_KEY[ns.RowSepStyle(r)]
    local off, g = 0, 0
    if al == "both" then
        g = W - n
    else
        if n < W then g = math.min(k and k.places or 1, W - n) end
        if al == "right" then off = W - n - g end
    end
    for i = 1, n do slots[i] = off + (i <= s and (i - 1) or (i - 1 + g)) end
    return slots, off + s, off + s + g
end

-- = startSepDrag in the mockup: while the separator is held (OnUpdate) only it follows the mouse as the yellow line,
-- over all places of the row; the icons stay where they are. Letting go snaps it into the nearest gap: the left half =
-- every icon whose centre lies left of it (third in-game test of session 20, user); since 2026-11-18 the icons stand
-- where StackSlots puts them, then the row is laid out again.
local function SepX(sep)
    local line = sep:GetParent()
    local row = line.ri and Rows()[line.ri]
    local left = line:GetLeft()
    if not row or not left then return nil end
    local x = GetCursorPosition() / line:GetEffectiveScale() - left
    local W = ns.GroupWidth(ns.RowGroupOf(row))
    local pl = StkPL(W)
    return math.max(pl - ITEM_GAP / 2, math.min(pl + W * ITEM_STEP - ITEM_GAP / 2, x)), row, W
end

local function SepDragUpdate(sep)
    local x = SepX(sep)
    if not x then return end
    sep:ClearAllPoints()
    sep:SetPoint("TOPLEFT", sep:GetParent(), "TOPLEFT", x - SEP_HIT / 2, 0)
end

local function StopSepDrag(sep)
    if not sep:GetScript("OnUpdate") then return end
    sep:SetScript("OnUpdate", nil)
    sep.bar:SetColorTexture(1, 0.82, 0, 1)
    local x, row, W = SepX(sep)
    if x and ns.IsSplitRow(row) then
        local s, slots = 0, StackSlots(row, W)
        for i = 1, #row.items do
            if StkPL(W) + slots[i] * ITEM_STEP + ITEM_SIZE / 2 < x then s = i end
        end
        if s ~= ns.RowSplit(row) then
            row.split = s
            Changed()
            return
        end
    end
    ns:RefreshOptions() -- back into its gap
end

-- separator of a split row: SEP_HIT px wide to grab it, the yellow line (3 px) in its middle, above the icons. Since
-- 2026-11-18 (user) a gap of empty places instead shows sep.boxF: a yellow frame around them (sep sized to the gap) with
-- the look of the separator in grey in its middle (minis drawn by LayoutRowStack); grabbing it turns it into the line.
local function SepBoxColor(sep, hover)
    for _, t in ipairs(sep.boxF.edges) do t:SetColorTexture(1, hover and 0.95 or 0.82, hover and 0.63 or 0, hover and 1 or 0.75) end
    sep.boxF.fill:SetColorTexture(1, 0.82, 0, hover and 0.14 or 0.06)
end
local function CreateSeparator(line)
    local sep = CreateFrame("Button", nil, line)
    sep:SetSize(SEP_HIT, ITEM_SIZE + 2)
    sep:SetFrameLevel(line:GetFrameLevel() + 5)
    sep.bar = Solid(sep:CreateTexture(nil, "OVERLAY"), 1, 0.82, 0, 1)
    sep.bar:SetSize(3, ITEM_SIZE + 2) -- 2 px until the second in-game test (user: "a little thicker")
    sep.bar:SetPoint("CENTER")
    local box = CreateFrame("Frame", nil, sep)
    box:SetPoint("TOPLEFT", 0, -1)
    box:SetPoint("BOTTOMRIGHT", 0, 1)
    box.fill = Solid(box:CreateTexture(nil, "BACKGROUND"), 1, 0.82, 0, 0.06)
    box.fill:SetAllPoints()
    box.edges = {}
    for k, p in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
        local t = box:CreateTexture(nil, "BORDER")
        t:SetPoint(p[1])
        t:SetPoint(p[2])
        if k <= 2 then t:SetHeight(1) else t:SetWidth(1) end
        box.edges[k] = t
    end
    box:Hide()
    sep.boxF = box
    SepBoxColor(sep, false)
    Tip(sep, L["Separator"], L["Drag left or right: icons change between the halves."])
    sep:HookScript("OnEnter", function(self) self.bar:SetColorTexture(1, 0.95, 0.63, 1) SepBoxColor(self, true) end)
    sep:HookScript("OnLeave", function(self)
        if self:GetScript("OnUpdate") then return end
        self.bar:SetColorTexture(1, 0.82, 0, 1)
        SepBoxColor(self, false)
    end)
    sep:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" or not line.ri then return end
        GameTooltip:Hide()
        self.boxF:Hide() -- while dragged it is the line again
        self.bar:Show()
        self:SetWidth(SEP_HIT)
        self.bar:SetColorTexture(1, 0.95, 0.63, 1)
        self:SetScript("OnUpdate", SepDragUpdate)
    end)
    sep:SetScript("OnMouseUp", StopSepDrag)
    sep:SetScript("OnHide", StopSepDrag)
    return sep
end

local function CreateLine(st)
    local line = CreateFrame("Button", nil, st)
    line:SetFrameLevel(st:GetFrameLevel() + 1)
    line:SetHeight(ITEM_SIZE + 2)
    -- active row: gold background (mockup .sline.sel), hover: a little lighter, drop target of a row: green line below
    line.sel = Solid(line:CreateTexture(nil, "BACKGROUND", nil, 1), 1, 0.82, 0, 0.12)
    line.sel:SetAllPoints()
    line.sel:Hide()
    local hl = Solid(line:CreateTexture(nil, "HIGHLIGHT"), 1, 1, 1, 0.05)
    hl:SetAllPoints()
    -- drop gap of a dragged row: on its own frame above the icons (2026-11-16, user: the icons hid it except 1 px),
    -- placed on the border between two lines in RowDragHover
    line.dropF = CreateFrame("Frame", nil, line)
    line.dropF:SetAllPoints()
    line.dropF:SetFrameLevel(line:GetFrameLevel() + 6) -- = g + 7 (FixStackLevels)
    line.drop = Solid(line.dropF:CreateTexture(nil, "OVERLAY"), 0.25, 1, 0.25, 1)
    line.drop:SetHeight(2)
    line.drop:Hide()
    -- grip: three short lines (in-game texts only Latin-1, so no symbol)
    local grip = CreateFrame("Button", nil, line)
    grip:SetSize(12, 18)
    grip:SetPoint("LEFT", line, "LEFT", 2, 0)
    for k = 1, 3 do
        local t = Solid(grip:CreateTexture(nil, "ARTWORK"), 0.6, 0.6, 0.66, 1)
        t:SetSize(9, 2)
        t:SetPoint("CENTER", 0, 4 - (k - 1) * 4)
    end
    grip:RegisterForDrag("LeftButton")
    grip:SetScript("OnDragStart", function() if line.ri then O.StartRowDrag(line.ri) end end)
    grip:SetScript("OnDragStop", O.FinishDrag)
    Tip(grip, L["Drag: move the row"], L["Onto another row = there; onto a group in the list = into that group."])
    -- the places of the group (free ones stay visible), the separator of a split row as a yellow line (session 20)
    line.cells = {}
    for slot = 1, ns.ROW_MAX do
        local c = Solid(line:CreateTexture(nil, "BORDER"), 1, 1, 1, 0.07)
        c:SetSize(ITEM_SIZE, ITEM_SIZE)
        line.cells[slot] = c
    end
    line.sep = CreateSeparator(line)
    -- right of the places (2026-11-16, user): separator, eye, "-". Since 2026-11-17 (user) the separator is a choice
    -- instead of the checkbox "Split row": a 16 px box with the look as a small drawing (empty = not split; text until
    -- the second in-game test, DrawMini; since 2026-11-18 plus the alignment along the bottom), a click opens
    -- S.sepMenu below it (= .ssepbtn in the mockup)
    local cb = CreateFrame("Button", nil, line)
    cb:SetSize(28, 16)
    cb:SetPoint("CENTER", line, "LEFT", STK_CB, 0)
    cb.edge = Solid(cb:CreateTexture(nil, "BACKGROUND", nil, 1), 0.54, 0.54, 0.59, 1)
    cb.edge:SetAllPoints()
    local fill = Solid(cb:CreateTexture(nil, "BACKGROUND", nil, 2), 0.07, 0.07, 0.07, 1)
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", -1, 1)
    cb:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    cb:SetScript("OnClick", function(self)
        local row = line.ri and Rows()[line.ri]
        if row then O.OpenSepMenu(row, self) end
    end)
    Tip(cb, function()
        local row = line.ri and Rows()[line.ri]
        local k = ns.SEP_BY_KEY[row and ns.RowSepStyle(row) or "none"]
        local a = ns.ROW_ALIGN_BY_KEY[ns.RowAlign(row)]
        return L["Alignment"] .. ": " .. L[a.label] .. "\n" .. L["Separator"] .. ": " .. L[k.label]
    end, L["Click: choose alignment and separator. Left / Right: the whole row sits at that edge, a separator is only its gap. Both sides (split rows only): the left half fills from the left, the right half from the right. The yellow line shows where the separator is; drag it or drop icons left or right of it."])
    line.cb = cb
    local eye = CreateFrame("Button", nil, line)
    eye:SetSize(16, 16)
    eye:SetPoint("CENTER", line, "LEFT", STK_EYE, 0)
    eye:SetNormalTexture("Interface\\LFGFrame\\LFG-Eye")
    eye:GetNormalTexture():SetTexCoord(0, 0.125, 0, 0.25) -- first frame of the eye animation
    eye:SetScript("OnClick", function()
        local row = line.ri and Rows()[line.ri]
        if not row then return end
        row.hidden = (not row.hidden) or nil
        Changed()
    end)
    Tip(eye, function()
        local row = line.ri and Rows()[line.ri]
        return row and row.hidden and L["Hidden - click shows the row in the bar"] or L["Visible - click hides the row in the bar"]
    end)
    line.eye = eye
    local del = CreateFrame("Button", nil, line)
    del:SetSize(14, 14)
    del:SetPoint("CENTER", line, "LEFT", STK_DEL, 0)
    del:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
    del:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
    del:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
    del:SetScript("OnClick", function()
        local row = line.ri and Rows()[line.ri]
        if row then O.AskDeleteRow(row) end
    end)
    Tip(del, L["Delete row"])
    line:RegisterForClicks("LeftButtonUp")
    line:SetScript("OnClick", function(self)
        if AddFromCursorTo(self) then return end
        if self.ri then
            S.selectedRow = self.ri -- active row (gold): a click in the catalog adds there
            ns:RefreshOptions()
        end
    end)
    line:SetScript("OnReceiveDrag", function(self) AddFromCursorTo(self) end)
    line:Hide()
    return line
end

-- = drawMini in the mockup: pieces { x, y, w, h } around the middle of holder, textures created when needed
-- (holder.minis). first = pieces already drawn (keep them); returns the number drawn so far, HideMinisFrom hides the rest
local function DrawMini(holder, list, first)
    holder.minis = holder.minis or {}
    local n = first or 0
    for _, m in ipairs(list) do
        n = n + 1
        local t = holder.minis[n]
        if not t then
            t = Solid(holder:CreateTexture(nil, "OVERLAY"), 1, 0.82, 0, 1)
            holder.minis[n] = t
        end
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", holder, "CENTER", m[1], -m[2])
        t:SetSize(m[3], m[4])
        t:Show()
    end
    return n
end
local function HideMinisFrom(holder, n)
    for i = n + 1, #(holder.minis or {}) do holder.minis[i]:Hide() end
end

-- = the separator menu in the mockup (2026-11-17, user): the looks of SEP_KINDS (BarSplit.lua), symbol in front of the
-- name, the current one marked; S.sepMenu.row = row it was opened for. Since 2026-11-18 (user) the alignment of the row
-- on top (ROW_ALIGNS), each part under a grey heading
local function CreateSepMenu()
    local m = O.CreatePopup()
    m.items, m.aligns, m.all = {}, {}, {}
    local y = -4
    local function Heading(text)
        local h = O.Label(m, text, "GameFontDisableSmall")
        h:SetPoint("TOPLEFT", 10, y - 3)
        y = y - 14
    end
    local function Item(mini, label, onClick)
        local b = CreateFrame("Button", nil, m)
        b:SetHeight(18)
        b:SetPoint("TOPLEFT", 6, y)
        b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        b.sel = Solid(b:CreateTexture(nil, "BACKGROUND"), 1, 0.82, 0, 0.18)
        b.sel:SetAllPoints()
        b.sym = CreateFrame("Frame", nil, b)
        b.sym:SetSize(28, 14)
        b.sym:SetPoint("LEFT", 0, 0)
        DrawMini(b.sym, mini)
        b.text = O.Label(b, label, "GameFontHighlightSmall")
        b.text:SetPoint("LEFT", 34, 0)
        m.textW = math.max(m.textW or 0, b.text:GetStringWidth())
        b:SetScript("OnClick", function()
            m:Hide()
            if m.row then onClick(m.row) end
        end)
        m.all[#m.all + 1] = b
        y = y - 18
        return b
    end
    Heading(L["Alignment"])
    for i, a in ipairs(ns.ROW_ALIGNS) do
        m.aligns[i] = Item(a.mini, L[a.label], function(row) O.SetRowAlign(row, a.key) end)
    end
    Heading(L["Separator"])
    for i, k in ipairs(ns.SEP_KINDS) do
        m.items[i] = Item(k.mini, L[k.label], function(row) O.SetRowSep(row, k.key) end)
    end
    local w = math.max(120, math.ceil(m.textW or 0) + 44) -- drawing column + name + room
    for _, b in ipairs(m.all) do b:SetWidth(w) end
    m:SetSize(w + 12, -y + 4)
    S.sepMenu = m
end

-- opens the separator menu of row below its button (a second click on the same button closes it)
local function OpenSepMenu(row, btn)
    local m = S.sepMenu
    local open = m:IsShown() and m.row == row
    O.HideMenus()
    GameTooltip:Hide()
    if open then return end
    m.row = row
    local cur, al, split = ns.RowSepStyle(row), ns.RowAlign(row), ns.IsSplitRow(row)
    for i, b in ipairs(m.items) do b.sel:SetShown(ns.SEP_KINDS[i].key == cur) end
    -- "Both sides" only for a split row (greyed and without a click otherwise)
    for i, b in ipairs(m.aligns) do
        local key = ns.ROW_ALIGNS[i].key
        local off = key == "both" and not split
        b.sel:SetShown(key == al)
        if off then b:Disable() else b:Enable() end
        local c = off and 0.42 or 1
        b.text:SetTextColor(c, c, off and 0.45 or 1)
        for _, t in ipairs(b.sym.minis or {}) do
            if off then t:SetColorTexture(0.42, 0.42, 0.45, 1) else t:SetColorTexture(1, 0.82, 0, 1) end
        end
    end
    m:ClearAllPoints()
    m:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", -4, -2)
    m:Show()
end

-- built once from CreateContent (Options.lua), while the page "Bars" is built
local function CreateRowStack()
    CreateSepMenu()
    local st = CreateFrame("Frame", nil, content)
    st:SetSize(MID_W + 8, 30)
    Place(st, GRID_X - 4, GRID_Y + O.STAB_DY)
    local bg = st:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.3)
    st.empty = O.Label(st, L["No rows yet - add one with \"+ Row\""], "GameFontDisable")
    st.empty:SetPoint("CENTER")
    st.lines, st.icons = {}, {}
    st:Hide()
    content.stack = st
    -- "+ Row" below the lines: empty row or a template (menu S.addMenu, OptionsRows.lua)
    -- O.Button calls onClick without arguments: anchor to content.addRowBtn, not self (self = nil put the menu at the
    -- bottom left of the screen, 2026-11-16)
    local add = O.Button(content, L["+ Row"], 76, function()
        if S.addMenu:IsShown() then S.addMenu:Hide() return end
        S.addMenu:ClearAllPoints()
        S.addMenu:SetPoint("TOPLEFT", content.addRowBtn, "BOTTOMLEFT", 0, -2)
        S.addMenu:Show()
    end)
    add:SetHeight(20)
    Place(add, GRID_X, GRID_Y)
    O.SetTooltip(add, L["Add row (empty or template)"], L["At most %d rows per group."]:format(O.MAX_GROUP_ROWS))
    add:Hide()
    content.addRowBtn = add
end

-- frame levels (FixLevels in Options.lua): above the grid, below the alternatives column
local function FixStackLevels(g)
    local st = content.stack
    st:SetFrameLevel(g)
    for _, line in ipairs(st.lines) do
        line:SetFrameLevel(g + 1)
        line.sep:SetFrameLevel(g + 6) -- above the icons (g + 3), it is dragged
        line.dropF:SetFrameLevel(g + 7) -- green drop gap above icons and separator
    end
    for _, ic in ipairs(st.icons) do ic:SetFrameLevel(g + 3) end
end

-- Draws the rows of the selected group (RefreshRows). grp = selected group, styled = a style tab other than Layout.
-- Returns the y where "Options" starts (below the lines and "+ Row"), nil = not shown.
local function LayoutRowStack(grp, styled)
    local st, add = content.stack, content.addRowBtn
    if not grp or grp.area or styled then
        st:Hide()
        add:Hide()
        for _, ic in ipairs(st.icons) do ic.row = nil end
        return nil
    end
    local mine = GroupRows(grp)
    local W = ns.GroupWidth(grp)
    local active = O.CurrentRow()
    local top = GRID_Y + O.STAB_DY
    local h = math.max(#mine, 1) * ITEM_STEP - ITEM_GAP + 8
    Place(st, GRID_X - 4, top)
    st:SetHeight(h)
    st:Show()
    st.empty:SetShown(#mine == 0)
    local pl = StkPL(W)
    local function SX(slot) return pl + slot * ITEM_STEP end
    local used = 0
    for k = 1, math.max(#mine, #st.lines) do
        local e = mine[k]
        local line = st.lines[k]
        if e and not line then
            line = CreateLine(st)
            line:SetFrameLevel(st:GetFrameLevel() + 1)
            st.lines[k] = line
        end
        if not e then
            line:Hide()
            line.ri = nil
        else
            local r, ri = e[1], e[2]
            line.ri = ri
            line:ClearAllPoints()
            line:SetPoint("TOPLEFT", st, "TOPLEFT", 0, -(3 + (k - 1) * ITEM_STEP))
            line:SetPoint("RIGHT", st, "RIGHT", 0, 0)
            line.sel:SetShown(r == active)
            line.drop:Hide()
            local split = ns.IsSplitRow(r)
            local slots, gapFrom, gapTo = StackSlots(r, W)
            -- = layoutRowStack in the mockup: a split row keeps all W places (session 20, user; before one was the
            -- separator X). Since 2026-11-18 (user) the icons stand like on the bar (StackSlots: alignment, the gap of
            -- the separator); from session 20 to then always in their order from the left with the yellow line after the
            -- left half. While the line is dragged the icons stay where they are (third in-game test of session 20).
            for slot, c in ipairs(line.cells) do
                c:ClearAllPoints()
                c:SetPoint("TOPLEFT", line, "TOPLEFT", SX(slot - 1), -1)
                c:SetShown(slot <= W)
            end
            local style = ns.RowSepStyle(r)
            local sep = line.sep
            sep:ClearAllPoints()
            local gw = split and ((gapTo - gapFrom) * ITEM_STEP - ITEM_GAP) or 0
            if gw > 0 then
                -- a gap of empty places: yellow frame around them, the look of the separator in grey in its middle
                sep:SetPoint("TOPLEFT", line, "TOPLEFT", SX(gapFrom), 0)
                sep:SetWidth(gw)
                sep.bar:Hide()
                sep.boxF:Show()
                HideMinisFrom(sep.boxF, DrawMini(sep.boxF, ns.SEP_BY_KEY[style].mini))
                for _, t in ipairs(sep.boxF.minis) do t:SetColorTexture(0.78, 0.78, 0.82, 1) end
            else
                -- no gap: the yellow line between the halves
                sep:SetPoint("TOPLEFT", line, "TOPLEFT", SX(gapFrom or 0) - ITEM_GAP / 2 - SEP_HIT / 2, 0)
                sep:SetWidth(SEP_HIT)
                sep.bar:Show()
                sep.boxF:Hide()
            end
            sep:SetShown(split)
            -- since 2026-11-18 (user) the box also shows the alignment of the row: marks along its bottom (ROW_ALIGNS bar)
            local a = ns.ROW_ALIGN_BY_KEY[ns.RowAlign(r)]
            HideMinisFrom(line.cb, DrawMini(line.cb, a.bar, DrawMini(line.cb, ns.SEP_BY_KEY[style].mini)))
            if split then line.cb.edge:SetColorTexture(1, 0.82, 0, 1) else line.cb.edge:SetColorTexture(0.54, 0.54, 0.59, 1) end
            line.eye:GetNormalTexture():SetDesaturated(r.hidden == true)
            line.eye:GetNormalTexture():SetAlpha(r.hidden and 0.35 or 1)
            local lineY = 3 + (k - 1) * ITEM_STEP
            for i, entry in ipairs(r.items) do
                used = used + 1
                local ic = st.icons[used]
                if not ic then
                    ic = CreateIcon(st)
                    st.icons[used] = ic
                end
                local x = SX(slots[i])
                ic:ClearAllPoints()
                ic:SetPoint("TOPLEFT", st, "TOPLEFT", x, -(lineY + 1))
                ic.px, ic.py = GRID_X - 4 + x, top + lineY + 1 -- page coordinates (alternatives column)
                ic.row, ic.i, ic.line, ic.entry = r, i, line, entry
                ic.itemID = ns.EntryMain(entry)
                ic.icon:SetTexture(ns.EntryIcon(ic.itemID) or 134400)
                ic.icon:SetAlpha(r.hidden and 0.4 or 1)
                local hasAlt = ns.IsSlot(entry) and #entry > 1
                for _, t in ipairs(ic.altMark) do t:SetShown(hasAlt) end
                local isWeapon = ns.IsWeaponEntry(entry)
                ic.hand:SetShown(isWeapon)
                ic.hand.text:SetText(isWeapon and (entry.hand == "main" and L["MH"] or L["OH"]) or "")
                if isWeapon then ic.hand:SetWidth(math.max(13, ic.hand.text:GetStringWidth() + 2)) end
                ic:Show()
            end
            line:Show()
        end
    end
    for i = used + 1, #st.icons do
        st.icons[i]:Hide()
        st.icons[i].row = nil
    end
    -- "+ Row" below the lines, "Options" below it
    Place(add, GRID_X, top + h + 4)
    add:Show()
    O.SetButtonEnabled(add, #mine < O.MAX_GROUP_ROWS)
    return top + h + 4 + 22 + 6
end

-- = FinishDrag for the stack: d.from "catalog", "alt" (d.row = row of the column) or "stack" (d.r, d.index)
local function StackDrop(d)
    local rows = Rows()
    local line = LineUnderMouse()
    if not line then
        -- dragged out of the stack: removed
        if d.from == "stack" and not OverStack() then
            local src = rows[d.r]
            if src and src.items[d.index] then
                O.SpliceItem(src, d.index)
                Changed()
                return
            end
        end
        ns:RefreshOptions()
        return
    end
    local dst = rows[line.ri]
    if not dst then return end
    local ic = IconUnderMouse()
    local target = (ic and ic.row == dst) and ic.i or nil
    local s = ns.RowSplit(dst)
    local side = ns.IsSplitRow(dst) and (target and (target <= s and "L" or "R") or CursorSide(line)) or nil
    local at = target or (side == "L" and (s + 1)) or (#dst.items + 1)
    if d.from == "catalog" then
        Run(dst, side, d.itemID, function() O.InsertItem(d.itemID, at, dst) end)
        return
    end
    if d.from == "alt" then
        local src = d.row or O.CurrentRow()
        Run(dst, side, d.itemID, function()
            if src and src ~= dst then O.TakeFromRow(src, d.itemID) end
            O.InsertItem(d.itemID, at, dst)
        end)
        return
    end
    if d.from ~= "stack" then return end
    local src, i = rows[d.r], d.index
    if not src or not src.items[i] then return end
    local entry = src.items[i]
    local id = ns.EntryMain(entry)
    if src == dst then
        if target == i then
            ns:RefreshOptions()
            return
        end
        local to = target or (side == "L" and s) or (side == "R" and (s + 1)) or #dst.items
        Run(dst, side, id, function()
            local v = table.remove(dst.items, i)
            table.insert(dst.items, math.max(1, math.min(to, #dst.items + 1)), v)
        end)
        return
    end
    -- into another row of the group: the whole icon with its alternatives, only while that row has room
    if #dst.items >= O.RowCap(dst) then
        O.PrintRowFull(dst)
        ns:RefreshOptions()
        return
    end
    Run(dst, side, id, function()
        O.SpliceItem(src, i)
        for _, x in ipairs(ns.EntryIDs(entry)) do O.TakeFromRow(dst, x) end
        table.insert(dst.items, math.max(1, math.min(at, #dst.items + 1)), entry)
    end)
end

-- row of the line under the mouse (drag hint "Add" / "Move")
local function StackRowUnderMouse()
    local line = LineUnderMouse()
    return line and Rows()[line.ri] or nil
end

-- = rowDropIndex in the mockup (2026-11-16, user): where the dragged row (index from) ends up when it is dropped above
-- (before) or below line i; the green line shows that gap
local function RowDropIndex(from, i, before)
    if from == i then return from end -- its own line: stays
    if before then return from < i and i - 1 or i end
    return from < i and i or i + 1
end

-- a row dragged by its grip (S.drag.from "srow"): target = a line of the stack (upper half = above it, lower half =
-- below it; before 2026-11-16 the line was always below and the row went to the line's place) or a group in the list
local function RowDragTarget(from)
    local line = LineUnderMouse()
    if line then
        local _, cy = line:GetCenter()
        local _, y = GetCursorPosition()
        local before = y / line:GetEffectiveScale() > cy
        return { line = line, i = line.ri, before = before, to = RowDropIndex(from, line.ri, before) }
    end
    for k, l in ipairs(content.rowLines) do
        local m = content.listModel and content.listModel[k]
        if l:IsShown() and l:IsMouseOver() and m and m.g then return { k = k, g = m.g } end
    end
end

-- while dragging a row (OnUpdate of the drag frame): glow on the target, hint text
local function RowDragHover(frame, d)
    local t = RowDragTarget(d.index)
    local moves = t ~= nil and t.line ~= nil and t.to ~= d.index
    for k, l in ipairs(content.rowLines) do l.dropGlow:SetShown(t ~= nil and t.g ~= nil and t.k == k) end
    for _, line in ipairs(content.stack.lines) do
        local on = t ~= nil and t.line == line
        if on then
            -- green line above (upper half) or below (lower half) = where the row will go; from the start of the drag,
            -- also at the row's own place (2026-11-16, user: no waiting for the first move)
            -- centred on the border to the next line (1 px each side): the icons leave exactly that free
            local edge, dy = t.before and "TOP" or "BOTTOM", t.before and 1 or -1
            line.drop:ClearAllPoints()
            line.drop:SetPoint(edge .. "LEFT", line, edge .. "LEFT", 0, dy)
            line.drop:SetPoint(edge .. "RIGHT", line, edge .. "RIGHT", 0, dy)
        end
        line.drop:SetShown(on)
    end
    if t and t.g then
        frame.hint:SetText(L["Into \"%s\""]:format(O.GroupName(t.g)))
    elseif moves then
        frame.hint:SetText(L["Move"])
    else
        frame.hint:SetText("")
    end
end

local function RowDragDrop(d)
    local t = RowDragTarget(d.index)
    for _, line in ipairs(content.stack.lines) do line.drop:Hide() end
    local r = Rows()[d.index]
    if not t or not r then
        ns:RefreshOptions()
        return
    end
    if t.g then
        O.MoveRowToGroup(r, t.g)
        return
    end
    if t.to == d.index then
        ns:RefreshOptions()
        return
    end
    S.selectedRow = O.MoveRowTo(d.index, t.to)
    Changed()
end

-- shared with the other options files (ns.Opt)
O.CreateRowStack, O.FixStackLevels, O.LayoutRowStack, O.StackDrop, O.GroupRows = CreateRowStack, FixStackLevels, LayoutRowStack, StackDrop, GroupRows
O.OverStack, O.StackIconUnderMouse, O.StackButton, O.StackRowUnderMouse = OverStack, IconUnderMouse, StackButton, StackRowUnderMouse
O.GroupRowOf, O.RowDragHover, O.RowDragDrop, O.OpenSepMenu = GroupRowOf, RowDragHover, RowDragDrop, OpenSepMenu
