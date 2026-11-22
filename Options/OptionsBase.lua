-- RaidKit Buffs: Options - shared state, layout constants, widget helpers
-- Loaded first of the options files. Creates the two tables every options file shares:
--   O = ns.Opt       functions and constants used by more than one file
--   S = ns.OptState  state that more than one file changes (selection, drag, menus)
-- Plain widget code without knowledge of rows, groups or the catalog.

local addonName, ns = ...
local L = ns.L
local O, S = {}, {}
ns.Opt, ns.OptState = O, S

-- The content frame exists from loading on (hidden); CreateContent fills it once when the window opens first
-- (content.built). Since 2026-11-15 (split into several files) so every file can keep it as a plain local.
local content = CreateFrame("Frame", "RaidKitBuffsOptionsContent", UIParent)
content:Hide()
S.dragFrame = nil
S.filterMenu = nil
S.addMenu = nil
S.groupAddMenu = nil -- menu of "+" in the heading line "Bars" (2026-11-20): empty group or a preset
S.listMenu = nil
S.sortMenu = nil
S.buffMenu = nil
-- page under construction (Place anchors there, BeginPage/EndPage in Options.lua) and what existed before it
S.buildPage = nil
S.buildBefore = nil
S.selectedRow = 1
-- group header selected in the row list (2026-11-11): id of the group, nil = a row is selected.
-- The middle column then shows the group settings instead of the row's grid.
S.selectedGroup = nil
-- "Alle Gruppen" (S.allSelected, 2026-11-11) is gone since session 20 (user): a group is always selected
-- sub-tab of the middle column of a group (2026-11-14, user): "layout" | "sep" | "frame" |
-- "icon" ("size" from 2026-11-15 until 2026-11-16)
S.styleTab = "layout"
S.drag = nil -- { itemID, from = "grid" | "catalog" | "alt" | "stack" | "srow" (a row by its grip, 2026-11-16), index }

-- navigation as tabs at the top (TAB_H, 2026-11-14, user; before a list NAV_W 130 wide on the left with the pages at
-- PAGE_X 140, PAGE_W 660). Pages PAGE_W x (CONTENT_H - TAB_H) below the tabs. The page "Reihen" keeps its old
-- coordinates and sits ROWS_DY higher (the profile area used to be above it).
local TAB_H, PAGE_X, PAGE_W = 36, 0, 984 -- 960 until 2026-11-16; session 20 974, 980, 972; 984 since 2026-11-17 (+ MID_EXTRA)
local CONTENT_W, CONTENT_H = PAGE_X + PAGE_W, 552 + 36 -- 552 since 2026-11-12, + the tab line since 2026-11-14
local ROWS_DY = -56
local PAGES = {
    { key = "profiles", label = L["Profiles"] },
    -- "Common" (language, 2026-11-14) removed 2026-11-15 (user): the language is in the bottom line of "Bars"
    { key = "rows", label = L["Bars"] }, -- "Leisten" since 2026-11-12 (user; before "Reihen")
    { key = "info", label = L["Info"] }, -- 2026-11-20 (user): help, legend, commands, credits (OptionsInfo.lua)
}
local MAX_ITEMS = 20 -- 30 until 2026-11-16: rows never wrap now, at most 20 places (BarSplit.lua)
-- rows per group (2026-11-16, user: "probably not more than 5 or 6"; 8 would fit); before 10 rows in the whole profile
local MAX_GROUP_ROWS = 6
local LINE_H = 20
-- lines of the row list: rows (max. 10) plus group headers (main + 5 groups + 3 areas) = 19 (+1), a bit lower than the
-- other lists (17 instead of LINE_H) so they fit above "Benutzen per" (review 2026-11-11)
-- 20 since 2026-11-11 (one spare line): all three columns end at 456, just above the bottom line (user)
local LIST_LINES, ROW_LINE_H = 12, 17 -- line pool: "Alle Gruppen" + 2 categories + main + 5 groups + 3 areas (no rows since 2026-11-16)
-- middle column twice as wide (2026-11-14, user): 20 icons per line (the bar's maximum) at 22 px with 2 px gap and a
-- reserve in the middle for split rows later (MID_GAP); before 30 px, 4 px gap, 6 per line. Row list 190 px (ROWS_W,
-- before 150), so the middle column starts at 215 (before 175) and the catalog at 716 (before 420).
-- 2026-11-16 (user): the list shows only groups (the rows are on the Layout tab of their group), 140 px; the middle
-- column gets the room for a row line: grip, 20 places, separator choice (2026-11-17, before checkbox "Split row"), eye and "-" (MID_EXTRA)
local ITEM_SIZE, ITEM_GAP, ITEMS_PER_LINE, MID_GAP, MID_EXTRA = 22, 2, 20, 10, 84 -- 60 until 2026-11-16; session 20: row line controls (74, 80, 72); 84 since 2026-11-17 (separator box 28 px)
local ITEM_STEP = ITEM_SIZE + ITEM_GAP
local CAT_LINES, CAT_LINE_H = 18, 20 -- 19 until 2026-11-14 (sort button got its own line)
local ROWS_X, ROWS_W = 10, 140
local GRID_X = ROWS_X + ROWS_W + 15 -- 165
local MID_W = ITEMS_PER_LINE * ITEM_STEP - ITEM_GAP + MID_EXTRA -- 550
local CAT_X = GRID_X + MID_W + 13 -- 728 (the catalog keeps its 234 px and 10 px to the edge)
-- right half of the middle column (controls 222 px wide, 2026-11-14)
local COL2 = GRID_X + 242 -- right column of the options (Icons, Orientation, Font size)
-- right column flush with the right edge of the middle column (2026-11-16, user: the size sliders looked squeezed, the
-- style tabs had room on the right): COL_R for 222 px controls, COL_RS for a slider with its reset button (238 px)
local COL_R, COL_RS = GRID_X + MID_W - 222, GRID_X + MID_W - 238
local GRID_Y = 88
-- "Unerwünschte Buffs": 3 lines in the grid, the group settings below it (2026-11-11, user)
local MAX_UNWANTED = 18
-- COL_BOTTOM = end of all three columns (558). The five size sliders are on the Layout tab again since 2026-11-16
-- (user; tab "Size" from 2026-11-15, SIZE_SL), placed by Flow below the checkboxes.
-- Groups, "All Groups", "Bars" and the style tabs (2026-11-15, user): top-aligned from TOP_Y, one line below the other
-- without gaps or overlaps (Flow, called from RefreshRows); the values below are only the first positions. Checkbox
-- lines CB_STEP apart (24 = height of a checkbox, 22 until 2026-11-15).
-- OPT_Y (2026-11-15, user): heading "Options" of the Layout tab, below the one icon line of "Unerwünschte Buffs".
-- STAB_DY: the style tabs take one line below the heading (2026-11-16, user; two lines from 2026-11-15 = 44, before
-- one line): everything below them (TOP_Y, OPT_Y, the grid of "Unerwünschte Buffs", the preview) sits 22 lower than
-- the heading line.
local STAB_DY = 22
local CB_Y, CB_STEP, ORIENT_Y, POS_Y, TOP_Y, OPT_Y = 198, 24, 338, 368, 92 + STAB_DY, 124 + STAB_DY -- 114, 146
local COL_BOTTOM = 558


------------------------------------------------------------------------
-- Widget helpers
------------------------------------------------------------------------

-- While a page is built: relative to that page. Later (e.g. the fold-out column placed on hover): relative
-- to the page the widget lives on, else to the content. Before 2026-11-09 it used the content then, and the
-- column showed up 140 px left and 56 px low on the page "Reihen".
-- pages of the window: key -> frame (BeginPage in Options.lua fills it)
local pages = {}

local function Place(w, x, y)
    local anchor = S.buildPage
    if not anchor then
        local parent = w:GetParent()
        for _, page in pairs(pages) do
            if page == parent then anchor = page end
        end
    end
    w:ClearAllPoints()
    w:SetPoint("TOPLEFT", anchor or content, "TOPLEFT", x, -y)
    return w
end

-- Top-aligned layout (2026-11-15, user; mockup flowLayout): the shown entries one below the other from y, nothing
-- overlaps. Entry: { w, h = line height (nil: own height + gap), dy = offset in its line, pair = control right of a
-- checkbox (centred on it), also = second widget in the line at alsoDy }. x stays where the widget was placed.
-- Returns the y below the last shown entry.
local function Flow(list, y)
    for _, e in ipairs(list) do
        local w = e.w
        if w and w:IsShown() then
            local top = y + (e.dy or 0)
            local _, _, _, x = w:GetPoint(1)
            Place(w, x or 0, top)
            if e.pair then
                local _, _, _, px = e.pair:GetPoint(1)
                Place(e.pair, px or 0, top + (w:GetHeight() - e.pair:GetHeight()) / 2)
            end
            if e.also then
                local _, _, _, ax = e.also:GetPoint(1)
                Place(e.also, ax or 0, top + (e.alsoDy or 0))
            end
            local h = e.h
            if not h then
                h = math.ceil(w.GetStringHeight and w:GetStringHeight() or w:GetHeight()) + (e.gap or 0)
            end
            y = y + h
        end
    end
    return y
end

local function Button(parent, text, width, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width or 80, 22)
    b:SetText(text)
    b:SetScript("OnClick", function() onClick() end)
    return b
end

local function Label(parent, text, template)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    fs:SetText(text or "")
    fs:SetJustifyH("LEFT")
    return fs
end

local function EditBox(parent, width, onEnter)
    local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    e:SetSize(width, 20)
    e:SetAutoFocus(false)
    e:SetScript("OnEnterPressed", function(self)
        if onEnter then onEnter(self) end
        self:ClearFocus()
    end)
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return e
end

local function SetTooltip(widget, title, text)
    widget:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title)
        if text then GameTooltip:AddLine(text, 1, 1, 1, true) end
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Small "+" / "-" / "->+" button next to a column header
local function SmallButton(text, x, tip, onClick, width)
    local b = Place(Button(content, text, width or 20, onClick), x, 66)
    b:SetHeight(20)
    SetTooltip(b, tip)
    return b
end

-- enabled (optional): function; when it returns false the box is greyed out and cannot be clicked
local function CheckBox(parent, text, getter, setter, enabled)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    local label = Label(cb, text, "GameFontHighlight")
    label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    cb:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
    end)
    cb.Refresh = function(self)
        self:SetChecked(getter() and true or false)
        local on = not enabled or enabled()
        if on then self:Enable() else self:Disable() end
        if on then label:SetTextColor(1, 1, 1) else label:SetTextColor(0.5, 0.5, 0.5) end
    end
    return cb
end

-- "Label  value  [-] ===o=== [+]", 222 px wide: label 0, value 96, [-] 124, track 144-198, [+] 202 (230 / 206 / 210
-- until 2026-11-14: room for the inherit button behind it).
-- Own Slider frame without a template (slider templates differ between client versions).
-- enabled (optional): function; when it returns false the control is grey and does nothing.
local function Slider(parent, text, getter, setter, step, minV, maxV, fmt, enabled)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(222, 22)
    local label = Label(f, text, "GameFontHighlight")
    label:SetPoint("LEFT", f, "LEFT", 0, 0)
    local value = Label(f, "", "GameFontNormal")
    value:SetPoint("LEFT", f, "LEFT", 96, 0)

    local bar = CreateFrame("Slider", nil, f)
    bar:SetOrientation("HORIZONTAL")
    bar:SetSize(54, 16)
    bar:SetPoint("LEFT", f, "LEFT", 144, 0)
    bar:SetMinMaxValues(minV, maxV)
    bar:SetValueStep(step)
    if bar.SetObeyStepOnDrag then bar:SetObeyStepOnDrag(true) end
    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetTexture("Interface\\Buttons\\WHITE8X8") -- not SetColorTexture, see Fallstricke
    track:SetVertexColor(0, 0, 0, 0.7)
    track:SetHeight(4)
    track:SetPoint("LEFT")
    track:SetPoint("RIGHT")
    bar:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    bar:GetThumbTexture():SetSize(24, 24)

    local updating = false -- SetValue from Show() must not call the setter again
    local function IsOn() return not enabled or enabled() end
    local function Round(v)
        v = math.max(minV, math.min(maxV, math.floor(v / step + 0.5) * step))
        return tonumber(string.format("%.2f", v)) -- avoid rounding errors with 0.05 steps
    end
    local function Show(v)
        v = v or getter()
        -- fmt: format string or function(value) -> text (e.g. "alle" for 0, 2026-11-10)
        value:SetText(type(fmt) == "function" and fmt(v) or string.format(fmt or "%d", v))
        updating = true
        bar:SetValue(v)
        updating = false
    end
    local function Apply(v)
        if not IsOn() then return end
        v = Round(v)
        if v == getter() then return end
        Show(v) -- update the display first, regardless of what happens next
        setter(v)
    end
    bar:SetScript("OnValueChanged", function(_, v)
        if not updating then Apply(v) end
    end)
    local minus = Button(f, "-", 18, function() Apply(getter() - step) end)
    minus:SetHeight(20)
    minus:SetPoint("LEFT", f, "LEFT", 124, 0)
    local plus = Button(f, "+", 18, function() Apply(getter() + step) end)
    plus:SetHeight(20)
    plus:SetPoint("LEFT", f, "LEFT", 202, 0)

    f.Refresh = function()
        local on = IsOn()
        if on then bar:Enable() else bar:Disable() end
        minus:SetEnabled(on)
        plus:SetEnabled(on)
        bar:GetThumbTexture():SetDesaturated(not on)
        if on then
            label:SetTextColor(1, 1, 1)
            value:SetTextColor(1, 0.82, 0)
        else
            label:SetTextColor(0.5, 0.5, 0.5)
            value:SetTextColor(0.5, 0.5, 0.5)
        end
        Show()
    end
    return f
end

-- "Pro Zeile (max.)" of the rows (2026-11-10): 0 = no wrap. Slider 1-20 since 2026-11-14 (user: "alle" far left
-- before 1 was odd): 20 = no wrap and is stored as 0 like before, so old profiles and the layout code stay as they are
local PER_MAX = 20
local function PerGet(get)
    return function()
        local v = get() or 0
        return (v > 0 and v < PER_MAX) and v or PER_MAX
    end
end
local function PerSet(set)
    return function(v) set(v >= PER_MAX and 0 or v) end
end
local PER_LINE_TIP = L["Places of every row of the group: a row holds at most this many icons and does not wrap. Not less than a row of the group needs."] -- 2026-11-16 (split rows hold as many since session 20)

-- A compact list line: text left, small grey info right
local function ListLine(parent, width)
    local line = CreateFrame("Button", nil, parent)
    line:SetSize(width, LINE_H)
    line:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    line.info = line:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    line.info:SetPoint("RIGHT", -4, 0)
    line.text = line:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    line.text:SetPoint("LEFT", 4, 0)
    line.text:SetPoint("RIGHT", line.info, "LEFT", -4, 0)
    line.text:SetJustifyH("LEFT")
    line.text:SetWordWrap(false)
    line.SetSelected = function(self, selected)
        if selected then
            self:LockHighlight()
            self.text:SetTextColor(1, 0.82, 0)
        else
            self:UnlockHighlight()
            self.text:SetTextColor(1, 1, 1)
        end
    end
    return line
end

local function ListBackground(x, y, width, lines, lineH)
    local f = CreateFrame("Frame", nil, content)
    f:SetSize(width, lines * (lineH or LINE_H))
    Place(f, x, y)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.3)
    return f
end

-- Enable()/Disable() instead of SetEnabled, which is not available for every widget in Classic Era
local function SetButtonEnabled(b, enabled)
    if enabled then b:Enable() else b:Disable() end
end

local function ItemName(itemID)
    if ns.IsBuffID(itemID) then return ns.EntryName(itemID) end
    local name = ns.GetItemInfo(itemID)
    if name then return name end
    local entry = ns.catalog[itemID]
    return entry and entry.name or L["Item #%d (loading ...)"]:format(itemID)
end

-- icon of a catalog item, also while the item is not cached yet (catalog field icon)
local function AltIcon(itemID)
    local entry = ns.catalog[itemID]
    return ns.EntryIcon(itemID) or (entry and entry.icon and ("Interface\\Icons\\" .. entry.icon)) or 134400
end


-- Refresh the options first, then the bar: the display stays correct even
-- if something goes wrong while building the bar (it gets reported then).
local function Changed()
    ns:RefreshOptions()
    ns:RequestRebuild()
end

local function Rows()
    return ns.profile.rows
end
-- Solid colour via WHITE8X8 + SetVertexColor (SetColorTexture stayed transparent in the options, see Fallstricke)
local function Solid(tex, r, g, b, a)
    tex:SetTexture("Interface\\Buttons\\WHITE8X8")
    tex:SetVertexColor(r, g, b, a or 1)
    return tex
end

-- Popup menu with an opaque background. Parented to UIParent (not the options content) and
-- built from plain textures instead of BackdropTemplate: in game the menus stayed transparent
-- with the backdrop and with a colour texture inside the content frame.
local function CreatePopup()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:Hide()
    local function Tex(layer, sub, r, g, b, a)
        local t = f:CreateTexture(nil, layer, nil, sub)
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        t:SetVertexColor(r, g, b, a)
        return t
    end
    local border = Tex("BACKGROUND", -8, 0.45, 0.45, 0.5, 1)
    border:SetAllPoints()
    local bg = Tex("BACKGROUND", -7, 0.05, 0.05, 0.08, 1)
    bg:SetPoint("TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", -1, 1)
    return f
end

-- Generic choice button "<prefix><label>" with a popup that opens downwards; writes ns.profile[key].
-- Used for "Leiste: ..." (ns.ORIENTATIONS) and "Sonstige: ..." (ns.OTHER_DOCKS), 2026-11-09.
-- opt (2026-11-12): { get, set } instead of ns.profile[key] (orientation of a group); a label may be a function;
-- opt.enabled: greyed out when it returns false (row names off, columns), the menu closes.
local choiceMenus = {}
local function CreateChoiceButton(list, key, prefix, width, opt)
    local get = opt and opt.get or function() return ns.profile[key] end
    local set = opt and opt.set or function(v) ns.profile[key] = v end
    local function LabelOf(o) return ns.Text(o.label) end -- labels from Data.lua are English keys (Locale.lua)
    local menu
    local btn = Button(content, "", width or 150, function()
        local open = menu:IsShown()
        for _, m in ipairs(choiceMenus) do m:Hide() end
        menu:SetShown(not open)
    end)
    btn.enabledFn = opt and opt.enabled
    btn:SetHeight(20)
    menu = CreatePopup()
    choiceMenus[#choiceMenus + 1] = menu
    menu.buttons = {}
    -- opt.menuWidth (2026-11-14): wider menu; opt.preview(key, texture): a small sample in front of every entry
    -- (style tab "Frame": the background textures)
    local menuW = opt and opt.menuWidth or 150
    local y = -6
    -- o.header (2026-11-20, alarm sounds "Game sounds" / "Own sounds"): a gold heading line, not clickable, never the
    -- current value
    menu.headers = {}
    for _, o in ipairs(list) do
        if o.header then
            local h = Label(menu, LabelOf(o), "GameFontNormalSmall")
            h:SetPoint("TOPLEFT", 8, y - 4)
            h.choice = o
            menu.headers[#menu.headers + 1] = h
            y = y - 18
        else
            local b = CreateFrame("Button", nil, menu)
            b:SetSize(menuW - 12, 18)
            b:SetPoint("TOPLEFT", 6, y)
            b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            b.text = Label(b, LabelOf(o), "GameFontHighlightSmall")
            if opt and opt.preview then
                b.prev = b:CreateTexture(nil, "ARTWORK")
                b.prev:SetSize(30, 12)
                b.prev:SetPoint("LEFT", 4, 0)
                b.text:SetPoint("LEFT", 40, 0)
            else
                b.text:SetPoint("LEFT", 4, 0)
            end
            b:SetScript("OnClick", function()
                set(o.key)
                menu:Hide()
                Changed()
            end)
            b.choiceKey, b.choice = o.key, o
            menu.buttons[#menu.buttons + 1] = b
            y = y - 18
        end
    end
    menu:SetSize(menuW, -y + 6)
    -- opt.up (2026-11-15, language in the bottom line): the menu opens upwards
    if opt and opt.up then
        menu:SetPoint("BOTTOMLEFT", btn, "TOPLEFT", 0, 2)
    else
        menu:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
    end
    btn.menu = menu
    btn.Refresh = function(self)
        local cur = menu.buttons[1].choice -- first real entry (never a heading)
        local v = get()
        for _, o in ipairs(list) do
            if not o.header and o.key == v then cur = o end
        end
        self:SetText(prefix .. LabelOf(cur))
        for _, h in ipairs(menu.headers) do h:SetText(LabelOf(h.choice)) end
        for _, b in ipairs(menu.buttons) do
            b.text:SetText(LabelOf(b.choice))
            if b.choiceKey == cur.key then b:LockHighlight() else b:UnlockHighlight() end
            if b.prev then opt.preview(b.choiceKey, b.prev) end
        end
        if self.enabledFn then
            local on = self.enabledFn() and true or false
            SetButtonEnabled(self, on)
            if not on then menu:Hide() end
        end
    end
    return btn
end

local function DynamicTooltip(widget, fill)
    widget:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        fill()
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function Flat(parent, layer, r, g, b, a)
    local t = parent:CreateTexture(nil, layer)
    t:SetTexture("Interface\\Buttons\\WHITE8X8")
    t:SetVertexColor(r, g, b, a)
    return t
end

-- Dark layer over the options content that swallows clicks while a popup is open
local function Shade(level)
    local s = CreateFrame("Frame", nil, UIParent)
    s:SetFrameStrata("FULLSCREEN_DIALOG")
    s:SetFrameLevel(level)
    s:EnableMouse(true)
    s:SetAllPoints(content)
    Flat(s, "BACKGROUND", 0, 0, 0, 0.5):SetAllPoints()
    s:Hide()
    return s
end

local function Panel(level, shadeLevel)
    local f = CreatePopup()
    f:SetToplevel(false) -- a raised frame must never cover the popup
    f:SetFrameLevel(level)
    f.shade = Shade(shadeLevel)
    f:SetScript("OnShow", function(self) self.shade:Show() end)
    f:SetScript("OnHide", function(self) self.shade:Hide(); GameTooltip:Hide() end)
    return f
end

-- Blizzard colour picker (2026-11-14, style tabs). a = nil: without opacity. onChange(r, g, b, a) on every change and
-- with the old values on "Cancel". Classic clients report the opacity inverted (like AceGUI's ColorPicker widget).
-- New picker (SetupColorPickerAndShow, client 10.2.5+, also Classic Era 1.15) or the old fields as fallback.
local function OpenColorPicker(r, g, b, a, onChange)
    local inverted = WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE
    local function ReadAlpha()
        if a == nil then return nil end
        local v
        if ColorPickerFrame.GetColorAlpha then v = ColorPickerFrame:GetColorAlpha()
        elseif OpacitySliderFrame then v = OpacitySliderFrame:GetValue() end
        v = v or 0
        if inverted then v = 1 - v end
        return math.floor(v * 100 + 0.5) / 100
    end
    local function Changed2()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        onChange(nr, ng, nb, ReadAlpha())
    end
    local function Cancel() onChange(r, g, b, a) end
    ColorPickerFrame:Hide()
    ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    ColorPickerFrame:SetClampedToScreen(true)
    local shownAlpha = a and (inverted and (1 - a) or a) or nil
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b, hasOpacity = a ~= nil, opacity = shownAlpha,
            swatchFunc = Changed2, opacityFunc = Changed2, cancelFunc = Cancel,
        })
    else
        ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = Changed2, Changed2, Cancel
        ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = a ~= nil, shownAlpha
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame:Show()
    end
end

-- shared with the other options files (ns.Opt)
O.content, O.pages = content, pages
O.TAB_H, O.PAGE_X, O.PAGE_W, O.CONTENT_W, O.CONTENT_H = TAB_H, PAGE_X, PAGE_W, CONTENT_W, CONTENT_H
O.ROWS_DY, O.PAGES, O.MAX_GROUP_ROWS, O.MAX_ITEMS, O.LINE_H = ROWS_DY, PAGES, MAX_GROUP_ROWS, MAX_ITEMS, LINE_H
O.LIST_LINES, O.ROW_LINE_H, O.ITEM_SIZE, O.ITEM_GAP = LIST_LINES, ROW_LINE_H, ITEM_SIZE, ITEM_GAP
O.ITEMS_PER_LINE, O.ITEM_STEP, O.CAT_LINES, O.CAT_LINE_H = ITEMS_PER_LINE, ITEM_STEP, CAT_LINES, CAT_LINE_H
O.ROWS_X, O.ROWS_W, O.GRID_X, O.MID_W, O.CAT_X, O.COL2 = ROWS_X, ROWS_W, GRID_X, MID_W, CAT_X, COL2
O.COL_R, O.COL_RS = COL_R, COL_RS
O.GRID_Y, O.MAX_UNWANTED, O.CB_Y, O.CB_STEP = GRID_Y, MAX_UNWANTED, CB_Y, CB_STEP
O.ORIENT_Y, O.POS_Y, O.STAB_DY, O.COL_BOTTOM, O.Place = ORIENT_Y, POS_Y, STAB_DY, COL_BOTTOM, Place
O.TOP_Y, O.Flow, O.OPT_Y, O.MID_GAP = TOP_Y, Flow, OPT_Y, MID_GAP
O.Button, O.Label, O.EditBox, O.SetTooltip, O.SmallButton = Button, Label, EditBox, SetTooltip, SmallButton
O.CheckBox, O.Slider, O.PER_MAX, O.PerGet, O.PerSet = CheckBox, Slider, PER_MAX, PerGet, PerSet
O.PER_LINE_TIP, O.ListLine, O.ListBackground = PER_LINE_TIP, ListLine, ListBackground
O.SetButtonEnabled, O.ItemName, O.AltIcon, O.Changed, O.Rows = SetButtonEnabled, ItemName, AltIcon, Changed, Rows
O.Solid, O.CreatePopup, O.choiceMenus, O.CreateChoiceButton = Solid, CreatePopup, choiceMenus, CreateChoiceButton
O.DynamicTooltip, O.Flat, O.Panel, O.OpenColorPicker = DynamicTooltip, Flat, Panel, OpenColorPicker
