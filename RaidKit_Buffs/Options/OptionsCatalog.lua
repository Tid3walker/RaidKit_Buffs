-- RaidKit Buffs: Options - catalog column
-- Lists, filters, sorting and menus of the catalog on the right of the page "Bars".
-- O = ns.Opt (shared functions and constants), S = ns.OptState (shared state), see OptionsBase.lua.

local _, ns = ...
local L = ns.L
local O, S = ns.Opt, ns.OptState
local content, CAT_LINES, CAT_LINE_H, CAT_X, COL_BOTTOM = O.content, O.CAT_LINES, O.CAT_LINE_H, O.CAT_X, O.COL_BOTTOM
local Place, Button, Label, EditBox, ListBackground = O.Place, O.Button, O.Label, O.EditBox, O.ListBackground
local ItemName, AltIcon, CreatePopup = O.ItemName, O.AltIcon, O.CreatePopup

------------------------------------------------------------------------
-- Catalog (right column)
------------------------------------------------------------------------

local filterIndex, catList, catSearch, catOffset = 1, nil, "", 0 -- catList: key of ns.CATALOG_LISTS
-- catalog tab "consume" | "buff" (switched by hand), category of the Buffs tab
local catTab, buffFilterIndex = "consume", 1

-- Active entry of ns.CATALOG_LISTS (dropdown "Liste"); starts on "Raid: <own class>"
local function CurrentList()
    if not catList then catList = "raid:" .. ns:PlayerClass() end
    for _, l in ipairs(ns.CATALOG_LISTS) do
        if l.key == catList then return l end
    end
    catList = "raid"
    return ns.CATALOG_LISTS[2]
end

-- Active entry of ns.CATALOG_SORTS (saved account wide in RaidKitBuffsDB.catSort, default "Typ")
local function CurrentSort()
    local wanted = RaidKitBuffsDB.catSort or "type"
    for _, s in ipairs(ns.CATALOG_SORTS) do
        if s.key == wanted then return s end
    end
    return ns.CATALOG_SORTS[1]
end

local function Contains(t, value)
    for _, v in ipairs(t) do
        if v == value then return true end
    end
    return false
end

-- = placesOf in the mockup (2026-11-16, user): names of the groups whose rows hold id, in group order, then
-- "Unwanted Buffs" when id is on the unwanted list; the tooltip of the catalog check lists them
local function PlacesOf(id, unwanted)
    local out, inGroup = {}, {}
    for _, r in ipairs(O.Rows()) do
        if not r.unwanted and O.RowIndexOf(r, id) then inGroup[r.group or "main"] = true end
    end
    for _, g in ipairs(ns.profile.groups or {}) do
        if inGroup[g.id] then out[#out + 1] = O.GroupName(g) end
    end
    local groups = #out
    if unwanted then
        local ug
        for _, g in ipairs(ns.profile.groups or {}) do
            if g.area == "unw" then ug = g break end
        end
        out[#out + 1] = ug and O.GroupName(ug) or L["Unwanted Buffs"]
    end
    return out, groups
end

-- "Typ"/"Werte" split the sorted list into sections: a { header = label } line before each group,
-- groups in the order of ns.FILTERS, empty groups left out. "Werte" uses the primary stat.
local function WithHeaders(list)
    local sort = CurrentSort()
    if not sort.group then return list end
    local out = {}
    for _, f in ipairs(ns.FILTERS) do
        if f.group == sort.group and (f.cat or f.stats) then
            local hasHeader = false
            for _, e in ipairs(list) do
                local inGroup
                if f.cat then inGroup = e.cat == f.cat else inGroup = Contains(f.stats, e.primary) end
                if inGroup then
                    if not hasHeader then
                        out[#out + 1] = { header = ns.Text(f.label) }
                        hasHeader = true
                    end
                    out[#out + 1] = e
                end
            end
        end
    end
    return out
end

-- Sorts entries A-Z by the displayed name, by culture (2026-11-20, user: ns.SortKey folds ä to a, é to e ...);
-- keys computed once per sort, equal keys by ID so the order never jumps
local function SortByName(list)
    local key = {}
    for _, e in ipairs(list) do key[e] = ns.SortKey(ItemName(e.id)) end
    table.sort(list, function(a, b)
        if key[a] ~= key[b] then return key[a] < key[b] end
        return a.id < b.id
    end)
end

-- Returns the catalog lines for the active list, category, search text and sort mode
-- (entries plus { header = ... } lines when sorted by type or stat).
-- "Raid: <class>" hides items whose primary stat that class cannot use (ns.CLASS_HIDE).
local function FilteredCatalog()
    local filter = ns.FILTERS[filterIndex]
    local cur = CurrentList()
    local hide = cur.class and ns.CLASS_HIDE[cur.class] or {}
    local search = catSearch:lower()
    local list = {}
    for _, e in ipairs(ns.catalogList) do
        local ok = (not cur.raid or ns.RAID_ITEMS[e.id]) and not hide[e.primary] and filter.match(e)
        if ok and search ~= "" then
            local localName = (ns.GetItemInfo(e.id) or ""):lower()
            ok = e.name:lower():find(search, 1, true) or localName:find(search, 1, true)
                or (ns.Text(e.note) or ""):lower():find(search, 1, true)
        end
        if ok then list[#list + 1] = e end
    end
    -- alphabetical by the displayed (localized) name; names not loaded yet use the English one
    SortByName(list)
    return WithHeaders(list)
end

-- Second icon of a catalog line (user 2026-11-20, = buffLink in the mockup): a trinket shows the icon of its buff
-- (b.aura), a proc what triggers it (b.src: item, enchant or talent; class = only for that class). Returns the tooltip
-- heading, the list { icon, name } and the icon behind the name (only where it differs from the line's icon), or nil.
local function LinkOf(b)
    if not b or not b.isBuff then return nil end
    if b.aura then
        local a = b.aura
        return L["Buff:"], { { icon = a.icon, name = ns.GetSpellName(a.spell) or a.name } }, a.icon
    end
    if not b.src then return nil end
    local class, list, mark = ns:PlayerClass(), {}, nil
    for _, s in ipairs(b.src) do
        if not s.class or s.class == class then
            local name = (s.spell and ns.GetSpellName(s.spell)) or (s.item and ns.GetItemInfo(s.item)) or s.name
            list[#list + 1] = { icon = s.icon, name = name }
            if not mark and s.icon ~= b.icon then mark = s.icon end
        end
    end
    if #list == 0 then return nil end
    return L["Triggered by:"], list, mark
end

-- "Buffs" tab: sections per category (ns.BUFF_FILTERS); buffs of the other faction are never shown,
-- buffs useless for the class come last under "Unpassend für <class>" (e.g. for "Unerwünscht").
local function FilteredBuffs()
    local filter = ns.BUFF_FILTERS[buffFilterIndex] or ns.BUFF_FILTERS[1]
    local search = catSearch:lower()
    local list = {}
    for _, b in ipairs(ns.BUFFS) do
        local ok = ns.BuffFitsFaction(b) and (not filter.cat or b.cat == filter.cat)
        if ok and search ~= "" then
            ok = b.name:lower():find(search, 1, true) or ItemName(b.id):lower():find(search, 1, true)
                or (ns.Text(b.note) or ""):lower():find(search, 1, true)
        end
        if ok then list[#list + 1] = b end
    end
    SortByName(list)
    -- per category: the entries without sub, then each part of f.subs (2026-11-20, user: auras before totems,
    -- long buffs before cooldowns); subTop[entry] = first entry of a later part, drawn with a faint line above it
    local out, subTop = {}, {}
    for _, f in ipairs(ns.BUFF_FILTERS) do
        if f.cat then
            local hasHeader, parts = false, { false }
            for _, s in ipairs(f.subs or {}) do parts[#parts + 1] = s end
            for p, sub in ipairs(parts) do
                local first = true
                for _, b in ipairs(list) do
                    if b.cat == f.cat and (b.sub or false) == sub and ns.BuffForClass(b) then
                        if not hasHeader then out[#out + 1] = { header = ns.Text(f.label) } hasHeader = true
                        elseif first and p > 1 then subTop[b] = true end
                        first = false
                        out[#out + 1] = b
                    end
                end
            end
        end
    end
    local hasHeader = false
    for _, b in ipairs(list) do
        if not ns.BuffForClass(b) then
            if not hasHeader then out[#out + 1] = { header = L["Unsuitable for %s"]:format(ns:ClassName(ns:PlayerClass())) } hasHeader = true end
            out[#out + 1] = b
        end
    end
    return out, subTop
end

local function CreateFilterMenu(anchor)
    S.filterMenu = CreatePopup()

    local colX = { type = 8, stat = 168 }
    local colY = { type = -24, stat = -24 }
    local head1 = Label(S.filterMenu, L["Type"], "GameFontNormalSmall")
    head1:SetPoint("TOPLEFT", colX.type + 4, -8)
    local head2 = Label(S.filterMenu, L["Stats"], "GameFontNormalSmall")
    head2:SetPoint("TOPLEFT", colX.stat + 4, -8)

    S.filterMenu.buttons = {}
    for i, f in ipairs(ns.FILTERS) do
        local b = CreateFrame("Button", nil, S.filterMenu)
        b:SetSize(156, 18)
        b:SetPoint("TOPLEFT", colX[f.group], colY[f.group])
        colY[f.group] = colY[f.group] - 18
        b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        b.text = Label(b, ns.Text(f.label), "GameFontHighlightSmall")
        b.text:SetPoint("LEFT", 4, 0)
        b:SetScript("OnClick", function()
            filterIndex, catOffset = i, 0
            S.filterMenu:Hide()
            ns:RefreshOptions()
        end)
        S.filterMenu.buttons[i] = b
    end
    local height = math.max(-colY.type, -colY.stat) + 8
    S.filterMenu:SetSize(332, height)
    S.filterMenu:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -2)
end

-- One column: Alle, Raid, then "Raid: <class>" for every class (gap before the class entries)
local function CreateListMenu(anchor)
    S.listMenu = CreatePopup()
    S.listMenu.buttons = {}
    local y = -6
    for i, l in ipairs(ns.CATALOG_LISTS) do
        if l.class and not ns.CATALOG_LISTS[i - 1].class then y = y - 6 end
        local b = CreateFrame("Button", nil, S.listMenu)
        b:SetSize(222, 18)
        b:SetPoint("TOPLEFT", 6, y)
        b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        b.text = Label(b, ns.Text(l.label), "GameFontHighlightSmall")
        b.text:SetPoint("LEFT", 4, 0)
        b:SetScript("OnClick", function()
            catList, catOffset = l.key, 0
            S.listMenu:Hide()
            ns:RefreshOptions()
        end)
        b.listKey = l.key
        S.listMenu.buttons[i] = b
        y = y - 18
    end
    S.listMenu:SetSize(234, -y + 6)
    S.listMenu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
end

-- "Sortierung": A-Z / Typ / Werte (ns.CATALOG_SORTS), remembered in RaidKitBuffsDB.catSort
local function CreateSortMenu(anchor)
    S.sortMenu = CreatePopup()
    S.sortMenu.buttons = {}
    local y = -6
    for i, s in ipairs(ns.CATALOG_SORTS) do
        local b = CreateFrame("Button", nil, S.sortMenu)
        b:SetSize(222, 18) -- as wide as the button above it (2026-11-14)
        b:SetPoint("TOPLEFT", 6, y)
        b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        b.text = Label(b, ns.Text(s.label), "GameFontHighlightSmall")
        b.text:SetPoint("LEFT", 4, 0)
        b:SetScript("OnClick", function()
            RaidKitBuffsDB.catSort, catOffset = s.key, 0
            S.sortMenu:Hide()
            ns:RefreshOptions()
        end)
        b.sortKey = s.key
        S.sortMenu.buttons[i] = b
        y = y - 18
    end
    S.sortMenu:SetSize(234, -y + 6)
    S.sortMenu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
end

-- "Kategorie" of the Buffs tab: Alle / Weltbuffs / Raidbuffs / Situativ (ns.BUFF_FILTERS)
local function CreateBuffMenu(anchor)
    S.buffMenu = CreatePopup()
    S.buffMenu.buttons = {}
    local y = -6
    for i, f in ipairs(ns.BUFF_FILTERS) do
        local b = CreateFrame("Button", nil, S.buffMenu)
        b:SetSize(222, 18)
        b:SetPoint("TOPLEFT", 6, y)
        b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        b.text = Label(b, ns.Text(f.label), "GameFontHighlightSmall")
        b.text:SetPoint("LEFT", 4, 0)
        b:SetScript("OnClick", function()
            buffFilterIndex, catOffset = i, 0
            S.buffMenu:Hide()
            ns:RefreshOptions()
        end)
        S.buffMenu.buttons[i] = b
        y = y - 18
    end
    S.buffMenu:SetSize(234, -y + 6)
    S.buffMenu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
end

local function CreateCatalog()
    -- Tabs instead of the header "Katalog" (2026-11-09): Consumables | Buffs. Since 2026-11-11 only switched
    -- by hand (every row takes both kinds); before, selecting a row switched to the tab of its kind.
    local function Tab(text, width, x, key)
        local b = Place(Button(content, text, width, function()
            if S.addMenu then S.addMenu:Hide() end
            S.filterMenu:Hide() S.listMenu:Hide() S.sortMenu:Hide() S.buffMenu:Hide()
            catTab, catOffset = key, 0
            ns:RefreshOptions()
        end), x, 66)
        b:SetHeight(20)
        return b
    end
    -- each half of the 234 px line (2026-11-14, user: the sort button has its own line now; before 84 + 50 px)
    content.tabConsume = Tab("Consumables", 116, CAT_X, "consume")
    content.tabBuff = Tab("Buffs", 116, CAT_X + 118, "buff")

    -- Sort (only consumables): its own line below the tabs, as wide as "List" (2026-11-14, user: right of the tabs it
    -- was far too small for "Sort: Type" in other languages); "List" and "Category" moved one line down
    local sortBtn = Place(Button(content, "", 234, function()
        if S.addMenu then S.addMenu:Hide() end
        S.filterMenu:Hide()
        S.listMenu:Hide()
        if S.sortMenu:IsShown() then S.sortMenu:Hide() else S.sortMenu:Show() end
    end), CAT_X, 88)
    content.sortBtn = sortBtn
    CreateSortMenu(sortBtn)

    local filterBtn = Place(Button(content, "", 234, function()
        if S.addMenu then S.addMenu:Hide() end
        S.listMenu:Hide()
        S.sortMenu:Hide()
        if S.filterMenu:IsShown() then S.filterMenu:Hide() else S.filterMenu:Show() end
    end), CAT_X, 138) -- below "List" (swapped 2026-11-08; 113 until 2026-11-14)
    content.filterBtn = filterBtn
    CreateFilterMenu(filterBtn)

    -- Dropdown "Liste": Alle / Raid / Raid: <class> (ns.CATALOG_LISTS)
    local listBtn = Place(Button(content, "", 234, function()
        if S.addMenu then S.addMenu:Hide() end
        S.filterMenu:Hide()
        S.sortMenu:Hide()
        if S.listMenu:IsShown() then S.listMenu:Hide() else S.listMenu:Show() end
    end), CAT_X, 113) -- 88 until 2026-11-14 (sort line above it now)
    content.listBtn = listBtn
    CreateListMenu(listBtn)

    -- Buffs tab: category in place of "Liste" (slider "Proc-Reserve" removed 2026-11-10: fixed steps, CapLevel in Bar.lua)
    local buffFilterBtn = Place(Button(content, "", 234, function()
        if S.addMenu then S.addMenu:Hide() end
        if S.buffMenu:IsShown() then S.buffMenu:Hide() else S.buffMenu:Show() end
    end), CAT_X, 88)
    content.buffFilterBtn = buffFilterBtn
    CreateBuffMenu(buffFilterBtn)


    local list = ListBackground(CAT_X, 165, 234, CAT_LINES) -- 140 until 2026-11-14 (one line for the sort button)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, delta)
        catOffset = catOffset - delta * 3
        ns:RefreshOptions()
    end)

    content.catLines = {}
    for i = 1, CAT_LINES do
        local line = CreateFrame("Button", nil, list)
        line:SetSize(234, CAT_LINE_H)
        line:SetPoint("TOPLEFT", 0, -(i - 1) * CAT_LINE_H)
        line:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        line:RegisterForDrag("LeftButton")
        line.icon = line:CreateTexture(nil, "ARTWORK")
        line.icon:SetSize(CAT_LINE_H - 2, CAT_LINE_H - 2)
        line.icon:SetPoint("LEFT", 2, 0)
        line.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        line.check = line:CreateTexture(nil, "OVERLAY")
        line.check:SetSize(16, 16)
        line.check:SetPoint("RIGHT", -2, 0)
        line.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        -- tooltip of the check (2026-11-16, user): which groups hold the icon. Mouse motion only, so click and drag
        -- still reach the line below.
        line.checkHit = CreateFrame("Frame", nil, line)
        line.checkHit:SetAllPoints(line.check)
        line.checkHit:EnableMouse(true)
        line.checkHit:SetMouseClickEnabled(false)
        line.checkHit:SetScript("OnEnter", function(self)
            if not line.places or #line.places == 0 or S.drag then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(L["Used in:"], 1, 0.82, 0)
            for i, name in ipairs(line.places) do
                if i > line.placesGroups then GameTooltip:AddLine(name, 1, 0.3, 0.3) else GameTooltip:AddLine(name, 1, 1, 1) end
            end
            GameTooltip:Show()
        end)
        line.checkHit:SetScript("OnLeave", function() GameTooltip:Hide() end)
        line.text =line:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        line.text:SetPoint("LEFT", line.icon, "RIGHT", 4, 0)
        line.text:SetPoint("RIGHT", line.check, "LEFT", -2, 0)
        line.text:SetJustifyH("LEFT")
        line.text:SetWordWrap(false)
        -- items with default alternatives (user 2026-11-10): icon of the first alternative right after the
        -- name (placed in the refresh, the name width varies); the tooltip lists all alternatives
        line.alt = line:CreateTexture(nil, "OVERLAY")
        line.alt:SetSize(12, 12)
        line.alt:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        line.alt:Hide()
        -- section header (sort "Typ"/"Werte"): gold text with a thin line below, no icon
        line.head = line:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        line.head:SetPoint("LEFT", 4, 0)
        line.head:SetPoint("RIGHT", -4, 0)
        line.head:SetJustifyH("LEFT")
        line.head:SetWordWrap(false)
        line.headLine = line:CreateTexture(nil, "ARTWORK")
        line.headLine:SetTexture("Interface\\Buttons\\WHITE8X8")
        line.headLine:SetVertexColor(1, 0.82, 0, 0.35)
        line.headLine:SetHeight(1)
        line.headLine:SetPoint("BOTTOMLEFT", 2, 1)
        line.headLine:SetPoint("BOTTOMRIGHT", -2, 1)
        -- part of a category (2026-11-20, user: auras, then totems): faint grey line on the top edge of the first
        -- entry of the part, in the 1 px above the icon, so it takes no line of the list
        line.subLine = line:CreateTexture(nil, "ARTWORK")
        line.subLine:SetTexture("Interface\\Buttons\\WHITE8X8")
        line.subLine:SetVertexColor(1, 1, 1, 0.2)
        line.subLine:SetHeight(1)
        line.subLine:SetPoint("TOPLEFT", 6, 0)
        line.subLine:SetPoint("TOPRIGHT", -6, 0)
        line.subLine:Hide()
        line:SetScript("OnClick", function(self)
            if not self.entry then return end
            -- since 2026-11-16 the rows are on the Layout tab of their group: already in the group = removed from its
            -- row, else added to the active row (gold line); "All Groups", Other and Debuffs take nothing
            local g, row = O.CurGroup(), O.CurrentRow()
            if not row or (not row.unwanted and S.styleTab ~= "layout") then
                ns:Print(L["Select a group with rows (tab Layout) first."])
                return
            end
            local has = row.unwanted and row or O.GroupRowOf(g, self.entry.id)
            local idx = has and O.RowIndexOf(has, self.entry.id)
            if idx then
                O.SpliceItem(has, idx)
                O.Changed()
            else
                O.InsertItem(self.entry.id)
            end
        end)
        line:SetScript("OnDragStart", function(self)
            if self.entry then O.StartDrag(self.entry.id, "catalog") end
        end)
        line:SetScript("OnDragStop", O.FinishDrag)
        line:SetScript("OnEnter", function(self)
            if not self.entry or S.drag then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.entry.isBuff then
                ns.SetBuffTip(self.entry)
            else
                GameTooltip:SetItemByID(self.entry.id)
            end
            GameTooltip:AddLine(" ")
            if self.entry.note then
                GameTooltip:AddLine(ns.Text(self.entry.note), 0.4, 0.8, 1, true)
            end
            -- default alternatives as a list with icons (user 2026-11-10)
            local alts = not self.entry.isBuff and ns.DEFAULT_ALTS[self.entry.id]
            if alts and #alts > 0 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(L["Alternatives:"], 1, 0.82, 0)
                for _, id in ipairs(alts) do
                    GameTooltip:AddLine(("|T%s:14:14|t %s"):format(tostring(AltIcon(id)), ItemName(id)), 1, 1, 1)
                end
                GameTooltip:AddLine(" ")
            end
            -- buff of a trinket / trigger of a proc (2026-11-20, LinkOf), with icons like the alternatives
            local label, list = LinkOf(self.entry)
            if label then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(label, 1, 0.82, 0)
                for _, x in ipairs(list) do
                    GameTooltip:AddLine(("|TInterface\\Icons\\%s:14:14|t %s"):format(x.icon, x.name), 1, 1, 1)
                end
                GameTooltip:AddLine(" ")
            end
            GameTooltip:AddLine(L["Drag into the row or click: add/remove"], 0.6, 0.6, 0.6, true)
            if self.entry.isBuff then
                GameTooltip:AddLine(L["Unwanted: select \"Unwanted Buffs\" in the row list, then add"], 0.6, 0.6, 0.6, true)
            end
            GameTooltip:Show()
        end)
        line:SetScript("OnLeave", function() GameTooltip:Hide() end)
        content.catLines[i] = line
    end

    -- search field ends at 456 like the other columns (2026-11-11). It starts right after its label, whose width
    -- depends on the language (2026-11-14, user: "Recherche :" / "Buscar:" did not fit the fixed 42 px); the box
    -- always ends at CAT_X + 222 (the edit box template draws its left border 5 px before the box)
    local searchLabel = Place(Label(content, L["Search:"], "GameFontHighlightSmall"), CAT_X, COL_BOTTOM - 17)
    local labelW = math.ceil(searchLabel:GetStringWidth() or 36)
    local search = Place(EditBox(content, 222 - (labelW + 8)), CAT_X + labelW + 8, COL_BOTTOM - 22)
    search:SetScript("OnTextChanged", function(self)
        catSearch = self:GetText() or ""
        catOffset = 0
        ns:RefreshOptions()
    end)
end

-- the catalog gives way to the settings of "Alle Gruppen" in the right column (session 4d). Remembers which widgets
-- were shown, so the tab-dependent ones come back as they were.
local function SetCatalogShown(on)
    if on == content.catalogOn then return end
    content.catalogOn = on
    if not on then
        content.catalogHidden = {}
        for _, w in ipairs(content.catalogWidgets) do
            if w:IsShown() then
                w:Hide()
                content.catalogHidden[#content.catalogHidden + 1] = w
            end
        end
        for _, m in pairs({ S.filterMenu, S.listMenu, S.sortMenu, S.buffMenu }) do m:Hide() end
    else
        for _, w in ipairs(content.catalogHidden or {}) do w:Show() end
        content.catalogHidden = nil
    end
end

local function RefreshCatalog()
    -- tabs: Consumables (Liste, Kategorie, Sortierung) | Buffs (Kategorie); the unwanted list is edited in the
    -- group "Unerwünschte Buffs" since session 4b (2026-11-11)
    local isBuff = catTab == "buff"
    content.tabConsume:SetText(isBuff and "|cff808080Consumables|r" or "Consumables")
    content.tabBuff:SetText(isBuff and "Buffs" or "|cff808080Buffs|r")
    if isBuff then content.tabBuff:LockHighlight() content.tabConsume:UnlockHighlight()
    else content.tabConsume:LockHighlight() content.tabBuff:UnlockHighlight() end
    for _, w in ipairs({ content.listBtn, content.filterBtn, content.sortBtn }) do w:SetShown(not isBuff) end
    content.buffFilterBtn:SetShown(isBuff)
    if isBuff then
        S.filterMenu:Hide() S.listMenu:Hide() S.sortMenu:Hide()
    else
        S.buffMenu:Hide()
    end
    local bf = ns.BUFF_FILTERS[buffFilterIndex] or ns.BUFF_FILTERS[1]
    content.buffFilterBtn:SetText(L["Category: %s"]:format(ns.Text(bf.label)))
    for i, b in ipairs(S.buffMenu.buttons) do
        if i == buffFilterIndex then b:LockHighlight() else b:UnlockHighlight() end
    end

    local filter = ns.FILTERS[filterIndex]
    content.filterBtn:SetText(L["Category: %s"]:format(ns.Text(filter.label)))
    for i, b in ipairs(S.filterMenu.buttons) do
        if i == filterIndex then b:LockHighlight() else b:UnlockHighlight() end
    end

    local cur = CurrentList()
    content.listBtn:SetText(L["List: %s"]:format(ns.Text(cur.label)))
    for _, b in ipairs(S.listMenu.buttons) do
        if b.listKey == cur.key then b:LockHighlight() else b:UnlockHighlight() end
    end
    local sort = CurrentSort()
    content.sortBtn:SetText(L["Sort: %s"]:format(ns.Text(sort.label)))
    for _, b in ipairs(S.sortMenu.buttons) do
        if b.sortKey == sort.key then b:LockHighlight() else b:UnlockHighlight() end
    end
    local list, subTop
    if isBuff then list, subTop = FilteredBuffs() else list = FilteredCatalog() end
    local unwanted = {}
    for _, id in ipairs(ns.profile.unwanted or {}) do unwanted[id] = true end

    local maxOffset = math.max(0, #list - CAT_LINES)
    catOffset = math.max(0, math.min(catOffset, maxOffset))
    local row, grp = O.CurrentRow(), O.CurGroup()
    for i, line in ipairs(content.catLines) do
        local e = list[catOffset + i]
        local isHeader = e and e.header and true or false
        -- header lines carry no entry, so click, drag and tooltip ignore them
        line.entry = not isHeader and e or nil
        line.head:SetShown(isHeader)
        line.headLine:SetShown(isHeader)
        line.subLine:SetShown(e ~= nil and subTop ~= nil and subTop[e] == true)
        line.icon:SetShown(not isHeader)
        line.text:SetShown(not isHeader)
        line:GetHighlightTexture():SetAlpha(isHeader and 0 or 1)
        if isHeader then
            line.head:SetText(e.header)
            line.check:Hide()
            line.places = nil
            line.alt:Hide()
            line:Show()
        elseif e then
            line.icon:SetTexture(ns.EntryIcon(e.id) or 134400)
            line.text:SetText(ItemName(e.id))
            -- first default alternative (user 2026-11-10): the name gives way for its icon, which sits 3 px
            -- behind the end of the name (text box = 234 - icon - check - gaps)
            -- since 2026-11-20 the same place shows the buff of a trinket / the trigger of a proc (LinkOf)
            local alts = not e.isBuff and ns.DEFAULT_ALTS[e.id]
            local _, _, mark = LinkOf(e)
            local altTex = (alts and #alts > 0) and AltIcon(alts[1]) or (mark and ("Interface\\Icons\\" .. mark)) or nil
            local hasAlt = altTex ~= nil
            line.text:SetPoint("RIGHT", line.check, "LEFT", hasAlt and -17 or -2, 0)
            if hasAlt then
                local maxW = 210 - CAT_LINE_H - 15
                line.alt:SetTexture(altTex)
                line.alt:ClearAllPoints()
                line.alt:SetPoint("LEFT", line.text, "LEFT", math.min(line.text:GetStringWidth(), maxW) + 3, 0)
                line.alt:Show()
            else
                line.alt:Hide()
            end
            local inRow = (row and row.unwanted) and O.RowIndexOf(row, e.id) ~= nil or O.GroupRowOf(grp, e.id) ~= nil
            -- check = on a bar (2026-11-16, user): gold = in a row of any group, red = only on "Unwanted Buffs" (before
            -- a red cross); the name stays green for the selected group; the check's tooltip names the groups
            local places, groups = PlacesOf(e.id, unwanted[e.id] == true)
            line.places, line.placesGroups = places, groups
            if groups > 0 then line.check:SetVertexColor(1, 1, 1) else line.check:SetVertexColor(1, 0.15, 0.15) end
            line.check:SetShown(#places > 0)
            if inRow then line.text:SetTextColor(0.4, 1, 0.4) else line.text:SetTextColor(1, 1, 1) end
            line:Show()
        else
            line:Hide()
        end
    end
end

-- shared with the other options files (ns.Opt)
O.CreateCatalog, O.SetCatalogShown, O.RefreshCatalog = CreateCatalog, SetCatalogShown, RefreshCatalog
