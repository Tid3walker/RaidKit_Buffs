-- RaidKit Buffs: Options - page "Profiles", account wide buttons (language, alarm sound), popups
-- Saving, loading, renaming, export/import of profiles; the language; the alarm sound; the small popup dialogs.
-- O = ns.Opt (shared functions and constants), S = ns.OptState (shared state), see OptionsBase.lua.

local _, ns = ...
local L = ns.L
local O, S = ns.Opt, ns.OptState
local content, LINE_H, Place, Button, Label, EditBox = O.content, O.LINE_H, O.Place, O.Button, O.Label, O.EditBox
local SetTooltip, CheckBox, ListLine, SetButtonEnabled = O.SetTooltip, O.CheckBox, O.ListLine, O.SetButtonEnabled
local CreateChoiceButton, DynamicTooltip, Flat, Panel = O.CreateChoiceButton, O.DynamicTooltip, O.Flat, O.Panel

------------------------------------------------------------------------
-- Profiles: page "Profile" (list, info, load, manage) and small popups.
-- Own frames instead of StaticPopup: Shade + popup lie above the options window.
-- Levels in FULLSCREEN_DIALOG: popup shade 40, popup 50.
------------------------------------------------------------------------

local popup
local profSel -- selected saved profile on the page "Profile" (session only)
local PROF_LINES = 13
local BOX_H, BOX_BAR = 90, 27 -- export/import box: height, right inset for the scroll bar

-- Small popup like StaticPopup: text, optional edit box, optional note, 1-2 buttons.
-- opts: edit = default text | box = text of the wide multi-line box (export/import), readOnly (box only), note,
--       button1, button2 (nil = only one button), onAccept(value) -> false keeps it open
local function ShowPopup(text, opts)
    if not popup then
        popup = Panel(50, 40)
        popup.text = Label(popup, "", "GameFontHighlight")
        popup.text:SetJustifyH("CENTER")
        popup.edit = EditBox(popup, 220)
        popup.edit:SetScript("OnEscapePressed", function() popup:Hide() end)
        popup.edit:SetScript("OnEnterPressed", function() popup.b1:Click() end)
        -- multi-line box for export/import (2026-11-20): wraps the long string over several lines and scrolls,
        -- so its length is visible at a glance (mockup: textarea.wtext, 90 px)
        local box = CreateFrame("Frame", nil, popup)
        box:SetHeight(BOX_H)
        Flat(box, "BACKGROUND", 0.33, 0.33, 0.33, 1):SetAllPoints()
        local fill = Flat(box, "BORDER", 0.04, 0.04, 0.04, 1)
        fill:SetPoint("TOPLEFT", 1, -1)
        fill:SetPoint("BOTTOMRIGHT", -1, 1)
        box.scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
        box.scroll:SetPoint("TOPLEFT", 5, -5)
        box.scroll:SetPoint("BOTTOMRIGHT", -BOX_BAR, 5)
        local text = CreateFrame("EditBox", nil, box.scroll)
        text:SetMultiLine(true)
        text:SetAutoFocus(false)
        text:SetFontObject(GameFontHighlightSmall)
        text:SetMaxLetters(0)
        text:EnableMouse(true)
        box.scroll:SetScrollChild(text)
        box.scroll:EnableMouse(true)
        box.scroll:SetScript("OnMouseDown", function() text:SetFocus() end)
        -- keep the cursor visible (own code instead of Blizzard's ScrollingEdit_* helpers, no Era addon uses those)
        text:SetScript("OnCursorChanged", function(_, _, y, _, h)
            local top, height = box.scroll:GetVerticalScroll(), box.scroll:GetHeight()
            y = -y
            if y < top then box.scroll:SetVerticalScroll(y)
            elseif y + h > top + height then box.scroll:SetVerticalScroll(y + h - height) end
        end)
        text:SetScript("OnEscapePressed", function() popup:Hide() end)
        text:SetScript("OnTextChanged", function(self, userInput)
            if userInput and popup.opts.readOnly then
                self:SetText(popup.opts.box)
                self:HighlightText()
            end
        end)
        text:SetScript("OnEditFocusGained", function(self) if popup.opts.readOnly then self:HighlightText() end end)
        box.text = text
        popup.box = box
        popup.note = Label(popup, "", "GameFontDisableSmall")
        popup.note:SetJustifyH("CENTER")
        popup.gen = 0
        popup.b1 = Button(popup, "", 110, function()
            local gen = popup.gen
            local field = popup.opts.box and popup.box.text or popup.edit
            if popup.opts.onAccept and popup.opts.onAccept(field:GetText()) == false then return end
            if popup.gen == gen then popup:Hide() end -- unless onAccept opened the next popup
        end)
        popup.b2 = Button(popup, "", 110, function() popup:Hide() end)
    end
    popup.gen = popup.gen + 1
    popup.opts = opts
    local w = opts.box and 420 or 320
    popup:SetWidth(w)
    popup.text:SetWidth(w - 32)
    popup.text:SetText(text)
    popup.text:ClearAllPoints()
    popup.text:SetPoint("TOP", 0, -16)
    local y = 16 + popup.text:GetStringHeight() + 10

    popup.edit:SetShown(opts.edit ~= nil)
    if opts.edit then
        popup.edit:SetMaxLetters(40)
        popup.edit:SetText(opts.edit)
        popup.edit:ClearAllPoints()
        popup.edit:SetPoint("TOP", 0, -y)
        y = y + 30
    end
    local box = popup.box
    box:SetShown(opts.box ~= nil)
    if opts.box then
        box:SetWidth(w - 32)
        box:ClearAllPoints()
        box:SetPoint("TOP", 0, -y)
        box.text:SetWidth(w - 32 - 5 - BOX_BAR)
        box.text:SetText(opts.box)
        box.text:SetCursorPosition(0)
        box.scroll:SetVerticalScroll(0)
        y = y + BOX_H + 10
    end
    popup.note:SetShown(opts.note ~= nil)
    if opts.note then
        popup.note:SetWidth(w - 32)
        popup.note:SetText(opts.note)
        popup.note:ClearAllPoints()
        popup.note:SetPoint("TOP", 0, -y)
        y = y + popup.note:GetStringHeight() + 10
    end
    popup.b1:SetText(opts.button1 or L["OK"])
    popup.b1:ClearAllPoints()
    popup.b2:SetShown(opts.button2 ~= nil)
    if opts.button2 then
        popup.b2:SetText(opts.button2)
        popup.b1:SetPoint("TOP", popup, "TOP", -58, -y)
        popup.b2:ClearAllPoints()
        popup.b2:SetPoint("TOP", popup, "TOP", 58, -y)
    else
        popup.b1:SetPoint("TOP", popup, "TOP", 0, -y)
    end
    popup:SetHeight(y + 22 + 14)
    popup:ClearAllPoints()
    popup:SetPoint("CENTER", content, "CENTER", 0, 40)
    popup:Show()
    local field = opts.box and box.text or (opts.edit and popup.edit)
    if field then
        field:SetFocus()
        field:HighlightText()
    end
end

-- List of saved profiles: "lines" lines of LINE_H, mouse wheel scrolls.
-- Line: name, blue "eigenes" for the own profile (2026-11-10), green "geladen" for the base profile, class (grey).
local function ProfileList(x, y, width, lines, getSel, onSel, onDouble)
    local box = Place(CreateFrame("Frame", nil, content), x, y)
    box:SetSize(width, lines * LINE_H)
    Flat(box, "BACKGROUND", 0, 0, 0, 0.3):SetAllPoints()
    box.offset = 0
    box.lines = {}
    for i = 1, lines do
        local l = ListLine(box, width)
        l:SetPoint("TOPLEFT", 0, -(i - 1) * LINE_H)
        l:SetScript("OnClick", function(self) onSel(self.profileName) end)
        if onDouble then l:SetScript("OnDoubleClick", function(self) onDouble(self.profileName) end) end
        box.lines[i] = l
    end
    local empty = Label(box, L["No profiles saved yet.\n\"Save as ...\" creates one."], "GameFontDisableSmall")
    empty:SetPoint("CENTER")
    empty:SetJustifyH("CENTER")
    box:EnableMouseWheel(true)
    box:SetScript("OnMouseWheel", function(self, delta)
        self.offset = self.offset - delta
        self:Refresh()
    end)
    box.Refresh = function(self)
        local names = ns:GetProfileNames()
        -- "loaded" only while the settings equal it, like the name at the top (2026-11-20); no "own" any more
        local loaded = not ns:IsModified() and ns:GetBaseProfile()
        self.offset = math.max(0, math.min(self.offset, #names - lines))
        for i, l in ipairs(self.lines) do
            local n = names[self.offset + i]
            if n then
                local p = ns:GetProfile(n)
                l.profileName = n
                l.text:SetText(n)
                local tag = n == loaded and ("|cff66ff66" .. L["loaded"] .. "|r  ") or ""
                l.info:SetText(tag .. (p.class and ns:ClassName(p.class) or ""))
                l:SetSelected(n == getSel())
                l:Show()
            else
                l:Hide()
            end
        end
        empty:SetShown(#names == 0)
    end
    return box
end

-- Selection still valid? Otherwise the base profile or the first one.
local function ValidSel(sel)
    if sel and ns:GetProfile(sel) then return sel end
    local base = ns:GetBaseProfile()
    if base then return base end
    return ns:GetProfileNames()[1]
end

local function RefreshProfilesPage()
    profSel = ValidSel(profSel)
    content.profList:Refresh()
    for _, b in ipairs(content.profNeedSel) do SetButtonEnabled(b, profSel ~= nil) end
    SetButtonEnabled(content.profLoad, profSel ~= nil)
    if not profSel then
        content.profInfo:SetText("|cff808080" .. L["No profile selected."] .. "|r")
        return
    end
    local p = ns:GetProfile(profSel)
    local rows, visible, items = ns:ProfileSummary(profSel)
    local text = "|cffffd100" .. profSel .. "|r\n"
        .. "|cff808080" .. (p.class and (ns:ClassName(p.class) .. " · ") or "") .. L["saved %s"]:format(p.saved or "?") .. "|r\n"
        .. L["%s rows (%s visible), %s items"]:format(rows, visible, items) .. "\n"
        .. L["Use: %s"]:format(ns.USE_MODE_LABEL[p.data.useMode] or "?")
    if p.class and p.class ~= ns:PlayerClass() then
        text = text .. "\n|cffff9933" .. L["Profile for %s - the rows may not suit your class."]:format(ns:ClassName(p.class)) .. "|r"
    end
    content.profInfo:SetText(text)
end

local function HidePopups()
    if popup then popup:Hide() end
end

local function DoLoad()
    if not profSel then return end
    local name = profSel
    local function Go()
        -- everything except the position (session 20, user; before rows and/or appearance by choice)
        if ns:LoadProfile(name, true, true) then
            S.selectedRow, S.selectedGroup = 1, nil
            ns:Print(L["Profile '%s' loaded (%s). Position unchanged."], name, L["Rows + Appearance"])
            ns:RefreshOptions()
        end
    end
    if not ns:GetBaseProfile() or ns:IsModified() then
        ShowPopup(L["Your own settings are not saved as a profile.\nLoad \"%s\" anyway?"]:format(name),
            { button1 = L["Load"], button2 = L["Cancel"], onAccept = Go })
    else
        Go()
    end
end

local function AskOverwrite(name)
    if not name then return end
    ShowPopup(L["Overwrite profile \"%s\" with the current settings?"]:format(name), {
        button1 = L["Overwrite"], button2 = L["Cancel"],
        onAccept = function()
            ns:SaveProfile(name)
            ns:Print(L["Profile '%s' saved."], name)
            ns:RefreshOptions()
        end,
    })
end

local function AskSaveAs()
    ShowPopup(L["Name for the profile:"], {
        -- nothing saved yet: the character's name as suggestion
        edit = ns:GetBaseProfile() or UnitName("player") or "", button1 = L["Save"], button2 = L["Cancel"],
        onAccept = function(value)
            local name, err = ns:CheckProfileName(value)
            if not name then ns:Print(err) return false end
            if ns:GetProfile(name) then AskOverwrite(name) return end
            ns:SaveProfile(name)
            ns:Print(L["Profile '%s' saved."], name)
            profSel = name
            ns:RefreshOptions()
        end,
    })
end

-- Popup with a name field for rename / copy; action(newName) does the work
local function AskName(text, default, button, action)
    ShowPopup(text, {
        edit = default, button1 = button, button2 = L["Cancel"],
        onAccept = function(value)
            local name, err = ns:CheckProfileName(value)
            if not name then ns:Print(err) return false end
            if name == profSel then return end
            if ns:GetProfile(name) then ns:Print(L["Profile '%s' already exists."], name) return false end
            action(name)
            profSel = name
            ns:RefreshOptions()
        end,
    })
end

-- Page "Profile": own settings on top, below the saved profiles:
-- list left, info + load in the middle, actions on the selected profile right.
-- Language (2026-11-14, user; own page "Common" until 2026-11-15): for the whole addon, not per profile
-- (RaidKitBuffsDB.language, account wide; nil = follow the game client). More languages may follow (ns.LANGUAGES);
-- a client language RaidKit Buffs does not offer shows English. Changing it needs /reload (Locale.lua).
StaticPopupDialogs["RAIDKITBUFFS_RELOAD_LANGUAGE"] = {
    text = "The new language is used after reloading the interface. Reload now?",
    button1 = "Reload now",
    button2 = L["Cancel"],
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function LanguageName(code)
    for _, l in ipairs(ns.LANGUAGES) do
        if l.key == code then return l.label end
    end
    return code
end

-- Language button (2026-11-14; page "Common" until 2026-11-15, now at the left end of the bottom line of "Bars", user):
-- 260 px, the menu opens upwards. Created by CreateContent (Options.lua) on the page "Bars".
local function CreateLanguageButton(Add, x, y)
    -- language names stay in their own language (functions: ns.Text does not translate them)
    local list = { { key = false, label = function()
        return L["Automatic (%s)"]:format(LanguageName(ns.ClientLanguage())) -- the client's language, short for the menu
    end } }
    for _, l in ipairs(ns.LANGUAGES) do
        local name = l.label
        list[#list + 1] = { key = l.key, label = function() return name end }
    end
    content.languageBtn = Add(CreateChoiceButton(list, nil, L["Language: "], 260, {
        up = true,
        get = function() return RaidKitBuffsDB and RaidKitBuffsDB.language or false end,
        set = function(v)
            if not RaidKitBuffsDB then return end
            local new = v or nil
            if new == RaidKitBuffsDB.language then return end
            RaidKitBuffsDB.language = new
            O.ShowStaticPopup("RAIDKITBUFFS_RELOAD_LANGUAGE")
        end,
    }), x, y)
    SetTooltip(content.languageBtn, L["Language"], L["For every character. Automatic = the language of the game client; if RaidKit Buffs does not offer it, English. Takes effect after reloading the interface."])
end

-- Sound of the loss alarm (2026-11-20, user) in the bottom line of "Bars", right of the language: 230 px, menu
-- upwards; choosing a sound plays it once. "Test" runs the whole alarm (ns:TestLoss, BarState.lua).
-- Account wide like the language: RaidKitBuffsDB.lossSound (nil = default).
local function CreateLossSoundButtons(Add, x, y)
    content.lossSoundBtn = Add(CreateChoiceButton(ns.LossSoundList(), nil, L["Alarm sound: "], 230, {
        up = true,
        get = function() return ns.LossSound() end,
        set = function(v)
            if not RaidKitBuffsDB then return end
            RaidKitBuffsDB.lossSound = v
            ns:PlayLossSound(v)
        end,
    }), x, y)
    SetTooltip(content.lossSoundBtn, L["Alarm sound"], L["Played when a consumable vanishes although time was left (usually the buff cap). For every character. Choosing a sound plays it once."])
    -- Place, not Add: content.controls get :Refresh() (OptionsRefresh.lua), a plain button has none
    content.lossTestBtn = Place(Button(content, L["Test"], 60, function() ns:TestLoss() end), x + 236, y)
    content.lossTestBtn:SetHeight(20)
    SetTooltip(content.lossTestBtn, L["Test the loss alarm"], L["Shows the alarm as if the buff cap had pushed off a consumable of the bar: red blinking icon, chat line, sound. No buff is removed."])
end

local function CreateProfilesPage(Add)
    Place(Label(content, L["Profile:"]), 10, 12)
    content.profName = Place(Label(content, "", "GameFontHighlight"), 58, 12)
    content.profName:SetWidth(420)
    content.profName:SetWordWrap(false)
    local nameHover = Place(CreateFrame("Frame", nil, content), 58, 8)
    nameHover:SetSize(420, 22)
    nameHover:EnableMouse(true)
    DynamicTooltip(nameHover, function()
        local base = ns:GetBaseProfile()
        if base and not ns:IsModified() then
            GameTooltip:SetText(base)
            GameTooltip:AddLine(L["Your settings equal this profile (last loaded or saved)."], 1, 1, 1, true)
        else
            GameTooltip:SetText(L["Own##profile"])
            GameTooltip:AddLine(L["Your own settings. They are always stored for this character; \"Save\" or \"Save as ...\" puts them into a profile."], 1, 1, 1, true)
        end
    end)

    -- 2026-11-20 (user, mockup proposal C with the middle buttons on top): no button row at the top any more. Left the
    -- list, middle Load / Default and below the info on the selected profile (everything that fetches settings), right
    -- Save / Save as and the actions on the list (everything that writes into the list). "Save" overwrites the profile
    -- SELECTED in the list, any time.
    local PX, PW, MX, Y0, STEP = 490, 160, 262, 70, 26
    content.profNeedSel = {}
    content.profSave = Place(Button(content, L["Save"], PW, function() AskOverwrite(profSel) end), PX, Y0)
    content.profNeedSel[1] = content.profSave
    DynamicTooltip(content.profSave, function()
        GameTooltip:SetText(L["Save"])
        GameTooltip:AddLine(L["Overwrites the profile \"%s\" with the current settings."]:format(profSel or "-"), 1, 1, 1, true)
        GameTooltip:AddLine(L["Select the profile in the list first."], 0.6, 0.6, 0.6, true)
    end)
    local saveAs = Place(Button(content, L["Save as ..."], PW, AskSaveAs), PX, Y0 + STEP)
    SetTooltip(saveAs, L["Save as"], L["Save the current settings as a profile with a new name. Without the position of the bar - it belongs to the character."])
    local sep0 = Place(Flat(content, "ARTWORK", 1, 1, 1, 0.15), PX, Y0 + 2 * STEP + 6)
    sep0:SetSize(PW, 1)
    -- resets the own settings, not a saved profile (was in the manage dialog); a special "Load" (user), below it
    local className = ns:ClassName(ns:PlayerClass())
    local reset = Place(Button(content, L["Default (%s) ..."]:format(className), PW, function()
        ShowPopup(L["Reset your own settings to the default for %s?\nThe position of the bar stays."]:format(className), {
            button1 = L["Reset"], button2 = L["Cancel"],
            onAccept = function()
                ns:ResetProfile()
                S.selectedRow, S.selectedGroup = 1, nil
                ns:Print(L["Own settings reset to default (%s). Position unchanged."], className)
                ns:RefreshOptions()
            end,
        })
    end), MX, Y0 + STEP)
    SetTooltip(reset, L["Default"], L["Rows and appearance like a new character of this class. Saved profiles stay untouched."])
    local sep = Place(Flat(content, "ARTWORK", 1, 1, 1, 0.15), 10, 40)
    sep:SetSize(660 - 20, 1) -- the page layout of "Profiles" kept its width (2026-11-14)

    -- saved profiles
    Place(Label(content, L["Saved profiles:"]), 10, 50)
    content.profList = ProfileList(10, Y0, 240, PROF_LINES, function() return profSel end,
        function(n) profSel = n; ns:RefreshOptions() end,
        function(n) profSel = n; DoLoad() end)
    content.profInfo = Place(Label(content, "", "GameFontHighlightSmall"), MX, Y0 + 2 * STEP + 10)
    content.profInfo:SetWidth(214)
    content.profInfo:SetSpacing(3)
    -- "Take over: Rows / Appearance" is gone since session 20 (user): loading takes everything except the position
    content.profLoad = Place(Button(content, L["Load"], PW, DoLoad), MX, Y0)
    DynamicTooltip(content.profLoad, function()
        GameTooltip:SetText(L["Load"])
        GameTooltip:AddLine(L["Copy \"%s\" into your own settings."]:format(profSel or "-"), 1, 1, 1, true)
        GameTooltip:AddLine(L["Everything except the position of the bar."], 0.6, 0.6, 0.6, true)
        GameTooltip:AddLine(L["Double-click in the list does the same."], 0.6, 0.6, 0.6, true)
    end)

    -- actions on the selected profile, below Save / Save as and their line (Rename at 136; y as before 2026-11-20)
    local function Act(text, y, onClick, tipTitle, tipText, needsSel)
        local b = Place(Button(content, text, PW, onClick), PX, y + 32)
        if tipTitle then SetTooltip(b, tipTitle, tipText) end
        if needsSel then content.profNeedSel[#content.profNeedSel + 1] = b end
        return b
    end
    Act(L["Rename ..."], 104, function()
        local old = profSel
        AskName(L["New name for \"%s\":"]:format(old), old, L["Rename"], function(name)
            ns:RenameProfile(old, name)
            ns:Print(L["Profile '%s' is now called '%s'."], old, name)
        end)
    end, nil, nil, true)
    Act(L["Copy ..."], 130, function()
        local src = profSel
        AskName(L["Name for the copy of \"%s\":"]:format(src), L["%s (copy)"]:format(src), L["Copy"], function(name)
            ns:CopyProfile(src, name)
            ns:Print(L["Profile '%s' copied to '%s'."], src, name)
        end)
    end, L["Copy"], L["Copy a saved profile under a new name, e.g. as a starting point for a variant."], true)
    Act(L["Delete"], 156, function()
        local name = profSel
        ShowPopup(L["Delete profile \"%s\"?\nThis cannot be undone."]:format(name), {
            button1 = L["Delete"], button2 = L["Cancel"],
            onAccept = function()
                ns:DeleteProfile(name)
                ns:Print(L["Profile '%s' deleted."], name)
                profSel = nil
                ns:RefreshOptions()
            end,
        })
    end, L["Delete"], L["Deletes only the saved profile. Characters that loaded it keep their settings."], true)
    local sep1 = Place(Flat(content, "ARTWORK", 1, 1, 1, 0.15), PX, 188 + 32)
    sep1:SetSize(PW, 1)
    Act(L["Export ..."], 196, function()
        ShowPopup(L["Export of \"%s\""]:format(profSel), {
            box = ns:ExportProfile(profSel), readOnly = true, button1 = L["Close"],
            note = L["The text is selected - Ctrl+C to copy, e.g. for the guild Discord."],
        })
    end, L["Export"], L["Output the profile as text to share it with others."], true)
    Act(L["Import ..."], 222, function()
        ShowPopup(L["Paste the export text here (Ctrl+V):"], {
            box = "", button1 = L["Import"], button2 = L["Cancel"],
            note = L["The profile is only saved, not loaded."],
            onAccept = function(value)
                local name, err = ns:ImportProfile(value)
                if not name then ns:Print(err) return false end
                ns:Print(L["Profile '%s' imported. Click \"Load\" to use it."], name)
                profSel = name
                ns:RefreshOptions()
            end,
        })
    end, L["Import"], L["Save an export text as a new profile. If the name already exists, the import gets a number."])

    local note1 = Place(Label(content, L["Every character has its own settings, always stored for it. A profile is a saved copy: \"Save\" and \"Save as ...\" write one, \"Load\" copies one in."], "GameFontDisableSmall"), 10, 350)
    note1:SetWidth(640)
    -- orientation is per group since session 20 and travels with the profile
    local note2 = Place(Label(content, L["Never in the profile: the position of the bar - it depends on where the bar sits on the screen."], "GameFontDisableSmall"), 10, 395)
    note2:SetWidth(640)
end

-- shared with the other options files (ns.Opt)
O.RefreshProfilesPage, O.HidePopups, O.CreateLanguageButton = RefreshProfilesPage, HidePopups, CreateLanguageButton
O.CreateLossSoundButtons = CreateLossSoundButtons
O.CreateProfilesPage = CreateProfilesPage
O.ShowPopup = ShowPopup -- error report of the page "Info" (2026-11-20, OptionsInfo.lua)
