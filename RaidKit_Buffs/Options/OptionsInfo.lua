-- RaidKit Buffs: Options - page "Info"
-- Third tab next to "Profiles" and "Bars" (user 2026-11-20): header, how the bar is used, legend, buff cap with a live
-- counter, chat commands, credits, error report. Mockup: js/options-info.js (same texts, same columns).
-- Three columns; inside a column every block hangs below the previous one (Chain), so wrapped texts never overlap.
-- The maker is only the short tag in "## Author" of the .toc, NEVER the user's real name (user 2026-11-20); without
-- it the line is hidden.
-- O = ns.Opt (shared functions and constants), S = ns.OptState (shared state), see OptionsBase.lua.

local addonName, ns = ...
local L = ns.L
local O, S = ns.Opt, ns.OptState
local content, Place, Button, Label, Flat = O.content, O.Place, O.Button, O.Label, O.Flat

local LOGO_TEXTURE = "Interface\\AddOns\\" .. addonName .. "\\Media\\Textures\\Logo"
local LOGO_SIZE = 80 -- = .ilogo in the mockup

-- English keys (translated when the page is built: the language is set only after ADDON_LOADED, Locale.lua)
local INFO_USE = {
    { "Ctrl+click", "use the item, cast your own class buff or mount up" },
    { "Right-click", "remove the buff (not in combat)" },
    { "Mouse wheel", "switch to another variant of the slot (not in combat)" },
    { "Shift+drag", "move a group; it snaps to other groups" },
    { "Shift+right-click", "open these options" },
    { "Red X", "remove all unwanted buffs, also in combat" },
}
local INFO_LEGEND = {
    { "Gray icon", "buff missing" },
    { "Colored icon", "buff active, minutes left at the top" },
    { "Yellow time", "less than 10 % of the duration left" },
    { "Number", "how many are in your bags (red: none), if switched on" },
    { "Lock", "can only be used after combat" },
    { "Red border", "unwanted buff" },
    { "MH / OH", "weapon enchant on the main hand / off hand" },
    { "Number in a row", "used buff slots (buff counter, from the buff catalog)" },
    { "Yellow, orange, red bar", "few free buff slots: yellow from 4, red at 1" },
    { "Blinking red", "a consumable vanished early (buff cap?), with chat line and sound" },
}
local INFO_COMMANDS = {
    { "/rkb, /rkbc", "open or close these options" },
    { "/rkb show | hide | toggle", "show or hide the bar (hidden = Blizzard buff bar)" },
    { "/rkb profile", "list the saved profiles" },
    { "/rkb profile <name>", "load a profile, e.g. in a macro for tank and damage" },
    { "/rkb reset", "move the bar back to its default place" },
}
local INFO_CREDITS = {
    { "Sounds", "from Freesound.org: \"Noooh!\" by jorickhoofd (CC BY 4.0), \"Retro video game sfx - Fail\" by OwlStorm (CC0)" },
    { "Icons and game sounds", "Blizzard Entertainment" },
    { "Languages", "English, Deutsch, Français, Español" },
}

local INFO_X, INFO_W, INFO_Y = { 10, 338, 666 }, 308, 12 -- = INFO_X, INFO_W in the mockup
local HEAD_GAP, TEXT_GAP = 14, 4

local function Meta(field)
    local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return get and get(addonName, field)
end

-- one font string for a list of { key, text }: key gold, text white, one line each (wrapped at the column width)
local function PairText(list)
    local lines = {}
    for _, p in ipairs(list) do
        lines[#lines + 1] = "|cffffd100" .. L[p[1]] .. "|r: " .. L[p[2]]
    end
    return table.concat(lines, "\n")
end

-- a column: every widget hangs below the previous one. col.alignTo (user 2026-11-21): the first widget starts at the
-- height of that widget (columns 2 and 3 at the first heading of column 1, "On the bar", below the header)
local function Add(col, w, gap)
    if col.last then
        w:ClearAllPoints()
        w:SetPoint("TOPLEFT", col.last, "BOTTOMLEFT", 0, -(gap or 0))
    elseif col.alignTo then
        w:ClearAllPoints()
        w:SetPoint("TOPLEFT", col.alignTo, "TOPLEFT", col.x - INFO_X[1], 0)
    else
        Place(w, col.x, INFO_Y)
    end
    col.last = w
    return w
end
local function Text(col, text, template, gap)
    local fs = Label(content, text, template or "GameFontHighlightSmall")
    fs:SetWidth(INFO_W)
    fs:SetSpacing(2)
    return Add(col, fs, gap or TEXT_GAP)
end
local function Heading(col, text)
    local head = Add(col, Label(content, L[text], "GameFontNormal"), HEAD_GAP)
    local line = Flat(content, "ARTWORK", 1, 0.82, 0, 0.35)
    line:SetSize(INFO_W, 1)
    Add(col, line, 2)
    return head
end

-- error report: version, client, language, class, buff cap, counts, errors. Never the character or realm name.
local function ErrorReport()
    local version, build = GetBuildInfo()
    local prof, groups = ns.profile, 0
    for _, g in ipairs(prof.groups or {}) do
        if not g.area then groups = groups + 1 end
    end
    local errors = ns:GetReportedErrors()
    local lines = {
        "RaidKit Buffs " .. tostring(Meta("Version")),
        ("Client: %s (%s), %s, project %s"):format(tostring(version), tostring(build), GetLocale(), tostring(WOW_PROJECT_ID)),
        ("Class: %s, buff cap: %s"):format(select(2, UnitClass("player")) or "?", ns.BUFF_CAP),
        ("Groups: %d, rows: %d, saved profiles: %d"):format(groups, #(prof.rows or {}), #ns:GetProfileNames()),
        ("Errors (%d):"):format(#errors),
    }
    for _, e in ipairs(errors) do lines[#lines + 1] = e end
    if #errors == 0 then lines[#lines + 1] = "-" end
    return table.concat(lines, "\n")
end

local function RefreshInfoPage()
    if not content.infoErrors then return end
    content.infoErrors:SetText(L["Errors this session: %d"]:format(#ns:GetReportedErrors()))
end

local function CreateInfoPage()
    local c1, c2, c3 = { x = INFO_X[1] }, { x = INFO_X[2] }, { x = INFO_X[3] }

    -- column 1: header, use, legend
    -- the addon logo (user 2026-11-21, variant "A header" of the mockup proposals): 80 px left of the title, instead
    -- of the potion icon before. Media\Textures\Logo.tga (256x256, 24 bit, made with tools\image-to-tga.ps1 from
    -- Assets\Logos v1); a black 1 px edge like the mockup. The text block sits vertically centered beside it.
    local head = CreateFrame("Frame", nil, content)
    head:SetSize(INFO_W, LOGO_SIZE + 2)
    Add(c1, head)
    local edge = head:CreateTexture(nil, "BACKGROUND")
    edge:SetTexture("Interface\\Buttons\\WHITE8X8") -- not SetColorTexture (Knowledge/Media.md)
    edge:SetVertexColor(0, 0, 0, 1)
    edge:SetSize(LOGO_SIZE + 2, LOGO_SIZE + 2)
    edge:SetPoint("TOPLEFT", 0, 0)
    local logo = head:CreateTexture(nil, "ARTWORK")
    logo:SetTexture(LOGO_TEXTURE)
    logo:SetSize(LOGO_SIZE, LOGO_SIZE)
    logo:SetPoint("TOPLEFT", 1, -1)
    local author = Meta("Author")
    local title = Label(head, "RaidKit - Buffs & Consumables", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", edge, "TOPRIGHT", 8, (author and author ~= "") and -20 or -26)
    local sub = Label(head, L["Version %s - WoW Classic Era"]:format(tostring(Meta("Version"))), "GameFontDisableSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    if author and author ~= "" then
        local by = Label(head, L["by %s"]:format(author), "GameFontDisableSmall")
        by:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -2)
    end
    local firstHead = Heading(c1, "On the bar")
    c2.alignTo, c3.alignTo = firstHead, firstHead -- columns 2 and 3 start at this height (user 2026-11-21)
    Text(c1, PairText(INFO_USE))
    Heading(c1, "Colors and signs")
    Text(c1, PairText(INFO_LEGEND))

    -- column 2: buff cap, chat commands
    Heading(c2, "Buff cap")
    Text(c2, L["Classic Era shows at most 32 buffs on you. When all slots are full, a new buff pushes another one off, consumables included. RaidKit Buffs colors the bar when slots run short and raises an alarm when a consumable vanished early; after a boss fight and when leaving the raid it lists what was lost. Tip: put useless buffs into \"Unwanted Buffs\" and remove them with the red X."])
    Heading(c2, "Chat commands")
    Text(c2, PairText(INFO_COMMANDS))
    Text(c2, L["Macro example: a macro with \"/rkb profile Tank\" loads that profile with one click."], "GameFontDisableSmall", 6)

    -- column 3: credits, error report
    Heading(c3, "Credits")
    Text(c3, PairText(INFO_CREDITS))
    Heading(c3, "Report a problem")
    Text(c3, L["A red error line in the chat? The button puts the version, the game client and the errors into a text you can copy (Ctrl+C) and pass on. It contains no character name."])
    content.infoErrors = Text(c3, "")
    content.infoErrors:SetTextColor(0.4, 1, 0.4)
    Add(c3, Button(content, L["Error report ..."], 160, function()
        O.ShowPopup(L["Error report"], { box = ErrorReport(), readOnly = true,
            note = L["The text is selected - Ctrl+C to copy."], button1 = L["Close"] })
    end), 8)

    -- live counter: once a second while the page is shown (OnUpdate runs only for a shown frame)
    local elapsed = 0
    S.buildPage:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        if elapsed < 1 then return end
        elapsed = 0
        RefreshInfoPage()
    end)
    RefreshInfoPage()
end

-- shared with the other options files (ns.Opt)
O.CreateInfoPage, O.RefreshInfoPage = CreateInfoPage, RefreshInfoPage
