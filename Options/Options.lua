-- RaidKit Buffs: Options
-- One content frame ("content") in its own window (/rkb). The Blizzard menu
-- (Esc > Options > AddOns > RaidKit Buffs) only shows a button that opens this window.
-- Layout (2026-11-14): tabs at the top (Profiles | Bars; "Common" until 2026-11-15), the page below them. Every page is its own
-- frame; BeginPage/EndPage move everything created in between onto that page, so the builders can keep using
-- "content".
-- Coordinates: Place(widget, x, y) = offset from the top left of the page being built
-- (or of the content outside a page), y downwards.
-- Deliberately without libraries; only templates that exist in Classic Era.
--
-- Page "Bars", columns: rows of the profile | items of the selected row (or the settings of a group / "All Groups")
-- | catalog.
-- Rows come from the profile; row templates (Data.lua) are copied in via the + menu.
--
-- Drag & drop: custom implementation (items need not be owned, so no cursor item).
--   catalog -> row: add (at the position where it is dropped)
--   row -> row:     reorder
--   row -> outside the item area: remove
--   row list: drag a row onto another row = reorder rows
--   Real items from the bags (cursor) can still be dragged into the item area.
--
-- Files (load order, RaidKit_Buffs.toc):
--   OptionsBase.lua      shared state, layout constants, widget helpers
--   OptionsModel.lua     rows and groups: selection and editing
--   OptionsDrag.lua      drag & drop and the alternatives column
--   OptionsCatalog.lua   catalog column
--   OptionsRows.lua      row list and item grid
--   OptionsProfiles.lua  page "Profiles", the language button, popups
--   OptionsInfo.lua      page "Info" (help, legend, commands, credits, error report)
--   OptionsRefresh.lua   refresh of the options window
--   OptionsBars.lua      settings of a row, a group, "All Groups" and the style tabs (middle column of "Bars")
--   Options.lua          window, pages and navigation, CreateContent (builds every page once)
-- O = ns.Opt (shared functions and constants), S = ns.OptState (shared state), see OptionsBase.lua.
-- Rules: a name used by one file only stays local there. Constants and helpers of OptionsBase.lua are imported as
-- locals (they never change); functions of the other files are called as O.Name(...) (call time, so the load order
-- does not matter); state that several files change lives in S. Lua 5.1 limits (60 upvalues per function, 200
-- locals per file): check with tools/lua-limits.js.

local addonName, ns = ...
local L = ns.L
local O, S = ns.Opt, ns.OptState
local content, TAB_H, PAGE_X, PAGE_W, CONTENT_W = O.content, O.TAB_H, O.PAGE_X, O.PAGE_W, O.CONTENT_W
local CONTENT_H, ROWS_DY, PAGES, COL_BOTTOM = O.CONTENT_H, O.ROWS_DY, O.PAGES, O.COL_BOTTOM
local Place, Button, Label, SetTooltip, Changed = O.Place, O.Button, O.Label, O.SetTooltip, O.Changed
local choiceMenus, CreateChoiceButton, Flat = O.choiceMenus, O.CreateChoiceButton, O.Flat

------------------------------------------------------------------------
-- Pages and navigation
------------------------------------------------------------------------

-- navItems = the tabs; optPage = shown page (pages, buildPage, buildBefore: OptionsBase.lua)
local pages = O.pages
local navItems = {}
local optPage = "rows"

-- Everything created as a child or region of "content" between BeginPage and EndPage
-- is moved onto the page frame, so hiding the page hides it.
local function Snapshot()
    local set = {}
    for _, c in ipairs({ content:GetChildren() }) do set[c] = true end
    for _, r in ipairs({ content:GetRegions() }) do set[r] = true end
    return set
end

local function BeginPage(key, dy)
    local page = CreateFrame("Frame", nil, content)
    page:SetSize(PAGE_W, CONTENT_H - TAB_H - (dy or 0))
    page:SetPoint("TOPLEFT", content, "TOPLEFT", PAGE_X, -(TAB_H + (dy or 0))) -- below the tabs (2026-11-14)
    pages[key] = page
    S.buildBefore = Snapshot()
    S.buildPage = page
end

local function EndPage()
    for _, c in ipairs({ content:GetChildren() }) do
        if not S.buildBefore[c] then c:SetParent(S.buildPage) end
    end
    for _, r in ipairs({ content:GetRegions() }) do
        if not S.buildBefore[r] then r:SetParent(S.buildPage) end
    end
    S.buildPage, S.buildBefore = nil, nil
end

local function HideMenus()
    for _, m in pairs({ S.filterMenu, S.listMenu, S.sortMenu, S.addMenu, S.groupAddMenu, S.buffMenu, S.groupMenu, S.sepMenu }) do m:Hide() end
    for _, m in ipairs(choiceMenus) do m:Hide() end
end
O.HideMenus = HideMenus -- also used by the style tabs (OptionsBars.lua)

-- Explicit frame levels above the item grid, set again after moving the frames onto the page
-- and whenever the window raises the content (SetParent / SetFrameLevel may lift the grid).
local function FixLevels()
    local g = content.gridArea:GetFrameLevel()
    for _, b in ipairs(content.itemButtons) do b:SetFrameLevel(g + 2) end
    if content.flyout then content.flyout:SetFrameLevel(g + 20) end
    if content.stack then O.FixStackLevels(g) end -- rows of a group (OptionsRowStack.lua)
    local edit = content.rowNameEdit
    edit:SetFrameLevel(edit:GetParent():GetFrameLevel() + 10)
end

local function ShowPage(key)
    optPage = key
    HideMenus()
    GameTooltip:Hide()
    for k, page in pairs(pages) do page:SetShown(k == key) end
    for _, item in ipairs(navItems) do item:SetSelected(item.pageKey == key) end
end

-- Navigation (2026-11-14, user: tabs at the top instead of a list on the left, so the pages get the whole width):
-- one tab per page, a line below them, right of the tabs the current profile in one line (click = page "Profiles").
-- Selected tab like the catalog tabs: highlighted, the others with grey text.
local function CreateNavigation()
    for i, pg in ipairs(PAGES) do
        local b = Place(Button(content, ns.Text(pg.label), 110, function() ShowPage(pg.key) end), 10 + (i - 1) * 114, 10)
        b:SetHeight(22)
        b.pageKey, b.label = pg.key, ns.Text(pg.label)
        b.SetSelected = function(self, on)
            self:SetText(on and self.label or ("|cff808080" .. self.label .. "|r"))
            if on then self:LockHighlight() else self:UnlockHighlight() end
        end
        navItems[i] = b
    end
    local line = Place(Flat(content, "ARTWORK", 1, 0.82, 0, 0.45), 0, 34)
    line:SetSize(CONTENT_W, 1)
    -- the profile text right of the tabs (2026-11-14 to 2026-11-20, content.navProf) is gone (user): the own settings are
    -- always stored for the character, the page "Profiles" shows the name.
    -- demo (2026-11-10) in the tab line since 2026-11-15 (user; before in the right column of "All Groups"): at the right
    -- edge, on every page. "+" = more fake buffs (before "Add buffs").
    content.demoBtn = Button(content, "", 150, function() ns:ToggleDemo() end)
    content.demoBtn:SetHeight(22)
    content.demoAddBtn = Button(content, "+", 22, function() ns:DemoAddBuffs(IsShiftKeyDown() and 5 or 1) end)
    content.demoAddBtn:SetHeight(22)
    content.demoAddBtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", -10, -10)
    content.demoBtn:SetPoint("RIGHT", content.demoAddBtn, "LEFT", -4, 0)
    -- "Show: ..." left of the demo (2026-11-15, user; briefly in the bottom line, before in the right column of "All
    -- Bars"): on every page, the menu opens downwards
    local showBtn = CreateChoiceButton(ns.SHOW_MODES, "showMode", L["Show: "], 180)
    showBtn:SetHeight(22)
    showBtn:SetPoint("RIGHT", content.demoBtn, "LEFT", -4, 0)
    content.controls[#content.controls + 1] = showBtn
    SetTooltip(showBtn, L["Show"], L["Where RaidKit Buffs replaces the Blizzard buff bar (buffs and debuffs). Never: always the Blizzard bar. Party: only in a party without a raid. While the options window is open the bar is always shown."])
    SetTooltip(content.demoAddBtn, L["Add buffs"], L["Only during the demo: click = 1 buff, Shift+click = 5 buffs more, until the cap is full. Random every time: an icon of your rows (elixir, potion, food, world buff ...), an unwanted buff (e.g. polymorph) or another buff. This way you can check the color of the bar (from 4 free slots yellow, then orange, at 1 red)."])
    SetTooltip(content.demoBtn, "Demo", L["For one minute: 5 to 20 icons of your rows look active, other buffs (HoTs, procs, trinkets), your unwanted buffs (the red button removes them) and a few debuffs come and go. None of it is real; meanwhile real buffs cannot be removed with a right-click. Only starts out of combat. Click again or close the window to end it."])
end

-- Kept outside CreateContent on purpose: Lua 5.1 allows at most 60 upvalues per function and
-- CreateContent is close to that limit (66 broke loading the whole file, 2026-11-14).
-- Check the count with the luaparse script in Development.md before adding new upvalues there.
local function Content_OnHide()
    GameTooltip:Hide()
    if S.filterMenu then S.filterMenu:Hide() end
    if S.listMenu then S.listMenu:Hide() end
    if S.sortMenu then S.sortMenu:Hide() end
    if S.addMenu then S.addMenu:Hide() end
    if S.groupAddMenu then S.groupAddMenu:Hide() end
    if S.groupMenu then S.groupMenu:Hide() end
    if S.buffMenu then S.buffMenu:Hide() end
    if S.sepMenu then S.sepMenu:Hide() end -- separator of a row (2026-11-17, OptionsRowStack.lua)
    for _, m in ipairs(choiceMenus) do m:Hide() end
    if S.drag then S.drag = nil; S.dragFrame:Hide(); O.HideRowDropGlow() end
    O.HidePopups()
end

local function CreateContent()
    content.built = true -- the frame itself exists since loading (OptionsBase.lua)
    content:SetSize(CONTENT_W, CONTENT_H)
    content:SetScript("OnHide", Content_OnHide)

    content.controls = {}
    local function Add(ctrl, x, y)
        Place(ctrl, x, y)
        content.controls[#content.controls + 1] = ctrl
        return ctrl
    end

    CreateNavigation()

    --------------------------------------------------------------------
    -- Page "Profile"
    --------------------------------------------------------------------
    BeginPage("profiles")
    O.CreateProfilesPage(Add)
    EndPage()

    -- Page "Info" (2026-11-20, user; OptionsInfo.lua)
    BeginPage("info")
    O.CreateInfoPage()
    EndPage()

    --------------------------------------------------------------------
    -- Page "Reihen": rows | items | catalog (old coordinates, moved up by ROWS_DY)
    --------------------------------------------------------------------
    BeginPage("rows", ROWS_DY)
    O.CreateRowColumn()
    O.CreateItemColumn()
    -- the catalog's widgets (session 4d): hidden while "Alle Gruppen" uses the right column (SetCatalogShown)
    local beforeCat = Snapshot()
    O.CreateCatalog()
    content.catalogWidgets = {}
    for _, c in ipairs({ content:GetChildren() }) do
        if not beforeCat[c] then content.catalogWidgets[#content.catalogWidgets + 1] = c end
    end
    for _, r in ipairs({ content:GetRegions() }) do
        if not beforeCat[r] then content.catalogWidgets[#content.catalogWidgets + 1] = r end
    end

    -- middle column: settings of the group and the style tabs (OptionsBars.lua; "All Groups" is gone since session 20)
    O.CreateGroupPanel(Add)
    O.CreateStyleTabs(Add)
    O.CreateRowStack() -- rows of a group on its Layout tab (2026-11-16, OptionsRowStack.lua)

    -- right column of "Alle Gruppen" (no catalog there): empty since 2026-11-15 (user; "Show" and demo -> tab line,
    -- CreateNavigation)

    -- bottom line ("Show" is in the tab line since 2026-11-15): the language at the left end (2026-11-15, user; before
    -- its own page "Common"), how the bar is used at the right end: button right-aligned with the catalog (PAGE_W - 10),
    -- its label right-aligned in front of it (mockup useLbl)
    local sep = Place(Flat(content, "ARTWORK", 1, 1, 1, 0.15), 10, COL_BOTTOM + 10)
    sep:SetSize(PAGE_W - 20, 1)
    O.CreateLanguageButton(Add, 10, COL_BOTTOM + 18)
    O.CreateLossSoundButtons(Add, 290, COL_BOTTOM + 18) -- loss alarm sound + test (2026-11-20, OptionsProfiles.lua)
    local useLbl = Place(Label(content, L["Use:"]), PAGE_W - 10 - 150 - 8 - 150, COL_BOTTOM + 23)
    useLbl:SetWidth(150)
    useLbl:SetJustifyH("RIGHT")
    content.useModeBtn = Place(Button(content, "", 150, function()
        local modes = ns.USE_MODES
        local idx = 1
        for i, m in ipairs(modes) do if m == ns.profile.useMode then idx = i end end
        ns.profile.useMode = modes[(idx % #modes) + 1]
        Changed()
    end), PAGE_W - 10 - 150, COL_BOTTOM + 18)
    EndPage()
    FixLevels()

    ShowPage(optPage)
end

------------------------------------------------------------------------
-- Hosts: own window; the Blizzard options only link to it
------------------------------------------------------------------------

local window -- created on the first /rkb (CreateWindow)

local function CreateWindow()
    window = CreateFrame("Frame", "RaidKitBuffsOptions", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(CONTENT_W + 8, CONTENT_H + 34)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self:SetUserPlaced(false) -- WoW must not remember the place (layout cache): every opening starts centered
    end)
    -- may be pushed past the left, right and bottom edge (2026-11-21, user: large on small screens); at least
    -- WIN_KEEP_X units stay visible sideways and WIN_KEEP_Y below the top, the title bar never leaves the screen
    -- (top inset 0). Positive left/bottom and negative right insets shrink the clamp rect.
    local WIN_KEEP_X, WIN_KEEP_Y = 150, 100
    window:SetClampedToScreen(true)
    window:SetClampRectInsets(window:GetWidth() - WIN_KEEP_X, -(window:GetWidth() - WIN_KEEP_X), 0,
        window:GetHeight() - WIN_KEEP_Y)
    window:Hide()
    tinsert(UISpecialFrames, "RaidKitBuffsOptions") -- Escape closes the window

    -- title bar: addon icon + name left, version right (left of the close button)
    local icon = window:CreateTexture(nil, "OVERLAY")
    icon:SetTexture(ns.ADDON_ICON)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetSize(14, 14)
    icon:SetPoint("TOPLEFT", 8, -4)
    local title = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    title:SetText("RaidKit - Buffs & Consumables")
    local version = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    version:SetPoint("TOPRIGHT", -30, -6)
    local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local v = getMeta and getMeta(addonName, "Version")
    version:SetText(v and ("Version " .. v) or "")

    window:SetScript("OnShow", function(self)
        -- every opening starts in the middle of the screen (user 2026-11-21); moving only lasts while it is open
        self:ClearAllPoints()
        self:SetPoint("CENTER")
        if not content.built then CreateContent() end
        content:SetParent(self)
        content:ClearAllPoints()
        content:SetPoint("TOPLEFT", self, "TOPLEFT", 4, -28)
        content:SetFrameLevel(self:GetFrameLevel() + 2)
        FixLevels()
        content:Show()
        -- every opening starts on the group "Buffs & Cons" (user, session 20; "Alle Gruppen" from 2026-11-14)
        S.selectedGroup = "main"
        ns:RefreshOptions()
        -- editing mode (2026-11-09): bar always shown, outline + preview visible, plain dragging moves
        ns.optionsOpen = true
        ns:UpdateVisibility()
    end)
    window:SetScript("OnHide", function()
        ns.optionsOpen = false
        if ns.demo then ns:StopDemo() end -- closing the window ends the demo too (user 2026-11-10)
        ns:UpdateVisibility() -- in combat: after the fight (bar holds secure buttons)
    end)
end

function ns:ToggleOptions()
    if not window then CreateWindow() end
    if window:IsShown() then
        window:Hide()
    else
        if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
        window:Show()
    end
end

-- Entry under Esc > Options > AddOns: the options are too wide for the canvas,
-- so it only explains and opens the own window.
local function RegisterSettingsPanel()
    local panel = CreateFrame("Frame")
    -- name in the list Esc > Options > AddOns (user 2026-11-21: the full title was cut off there); the .toc title
    -- (addon list) and the heading of this panel keep "RaidKit - Buffs & Consumables"
    panel.name = "RaidKitBuffsConsumables"

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("RaidKit - Buffs & Consumables")
    local text = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    text:SetJustifyH("LEFT")
    text:SetText(L["The options have their own window (also via /rkb or /rkbc)."])
    local open = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    open:SetSize(300, 24) -- = .blizz-btn in the mockup; wide enough for the full title (user 2026-11-21)
    open:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -14)
    open:SetText(L["Open RaidKit - Buffs & Consumables"])
    -- built while the files load (language not known yet, Locale.lua): the texts are set again when shown
    panel:SetScript("OnShow", function()
        text:SetText(L["The options have their own window (also via /rkb or /rkbc)."])
        open:SetText(L["Open RaidKit - Buffs & Consumables"])
    end)
    open:SetScript("OnClick", function()
        if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
        if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then HideUIPanel(InterfaceOptionsFrame) end
        if not window or not window:IsShown() then ns:ToggleOptions() end
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        ns.settingsCategory = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

RegisterSettingsPanel()
