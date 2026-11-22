-- RaidKit Buffs: Options - settings of the page "Bars" (middle column)
-- Builders for the panel of the selected group and the style tabs (Layout | Separator |
-- Background/Frame | Icon borders; one line since 2026-11-16). Called once from CreateContent (Options.lua) while the page "Bars" is built; what
-- is shown for the current selection decides RefreshRows (OptionsRefresh.lua) through the lists stored on
-- content (grpPanel, stylePanel ...). The rows of a group: OptionsRowStack.lua (2026-11-16). "All Groups" (its panel,
-- the inherit buttons, "Like All Groups", "Automatic") is gone since session 20 (user): every group decides on its own.
-- O = ns.Opt (shared functions and constants), S = ns.OptState (shared state), see OptionsBase.lua.

local _, ns = ...
local L = ns.L
local O, S = ns.Opt, ns.OptState
local PER_MAX, Changed, content = O.PER_MAX, O.Changed, O.content
local Place, Label, GRID_X, Slider, OPT_Y = O.Place, O.Label, O.GRID_X, O.Slider, O.OPT_Y
local PerGet, PerSet, SetTooltip, PER_LINE_TIP, CheckBox = O.PerGet, O.PerSet, O.SetTooltip, O.PER_LINE_TIP, O.CheckBox
local COL2, CreateChoiceButton, ORIENT_Y, CB_Y, Button = O.COL2, O.CreateChoiceButton, O.ORIENT_Y, O.CB_Y, O.Button
local POS_Y, MID_W, COL_RS = O.POS_Y, O.MID_W, O.COL_RS
local Flat, Solid, OpenColorPicker, TOP_Y = O.Flat, O.Solid, O.OpenColorPicker, O.TOP_Y

-- The inherit buttons "↺" (2026-11-14), "Like All Groups" and the panel of "Alle Gruppen" with its note on moving the
-- bar (MOVE_HINT) are gone since session 20 (user): no "Alle Gruppen", every group decides on its own.

-- Reset button "↺" behind every slider of a group (2026-11-16, user; mockup resetBtn): gold = the group has its own
-- value, click = back to the default of the addon; grey = the default. Child of its slider, IB_DX right of its left
-- edge (2 px after the 222 px control), so it moves and hides with it. fmt(v) -> text for the tooltip (optional).
local IB_DX = 224
local function Fv(v)
    if v == math.floor(v) then return tostring(v) end
    return string.format("%.2f", v)
end
-- Since 2026-11-17 (user) also behind the colour fields and sliders of the style tabs (SReset in CreateStyleTabs):
-- ResetIcon is the button itself, own() -> gold and clickable, reset() on click, texts() -> current, default value.
local function ResetIcon(ctrl, own, reset, texts)
    local b = CreateFrame("Button", nil, ctrl)
    b:SetSize(14, 14)
    b:SetPoint("LEFT", ctrl, "LEFT", IB_DX, 0)
    b:SetFrameLevel(ctrl:GetFrameLevel() + 2)
    b.tex = b:CreateTexture(nil, "ARTWORK")
    b.tex:SetAllPoints()
    b.tex:SetTexture("Interface\\Buttons\\UI-RefreshButton")
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetScript("OnClick", function()
        if not own() then return end
        GameTooltip:Hide()
        reset()
        Changed()
    end)
    O.DynamicTooltip(b, function()
        if own() then
            GameTooltip:SetText(L["Changed: %s (default: %s)"]:format(texts()))
            GameTooltip:AddLine(L["Click: back to the default value."], 0.6, 0.6, 0.6, true)
        else
            GameTooltip:SetText(L["Default value"])
        end
    end)
    b.Refresh = function(self)
        local on = own()
        self.tex:SetDesaturated(not on)
        if on then self.tex:SetVertexColor(1, 0.82, 0) else self.tex:SetVertexColor(0.45, 0.45, 0.45) end
    end
    content.controls[#content.controls + 1] = b
    return ctrl
end
-- "↺" of a group value (Layout): own value = g[key] set, reset = remove it (the default of the addon, ns.GEff)
local function ResetButton(ctrl, key, fmt)
    fmt = fmt or Fv
    return ResetIcon(ctrl, function() local g = O.CurGroup() return g ~= nil and g[key] ~= nil end,
        function() O.CurGroup()[key] = nil end,
        function() return fmt(ns.GEff(O.CurGroup(), key)), fmt(ns.GDefault(O.CurGroup(), key)) end)
end

local function CreateGroupPanel(Add)
    -- Group settings (2026-11-11, mockup "gpanel"). Since session 20 (user) every group decides on its own (no "Alle
    -- Gruppen"): no own value = the default of the addon (ns.GEff). "Buff-Limit-Färbung" stays per group (its default
    -- depends on the kind of group). Frame / separator / icon borders: "Visible" on the style tabs.
    -- Buff areas (g.area) have no rows: row-only widgets (notArea) are hidden there.
    local function G() return O.CurGroup() end
    local function GSet(key) return function(v) local g = G() if g then g[key] = v Changed() end end end
    -- the default is not stored (a group without the value has the default)
    local function GOwnSet(key)
        return function(v)
            local g = G()
            if not g then return end
            if v == ns.GDefault(g, key) then g[key] = nil else g[key] = v end
            Changed()
        end
    end
    local function GEffGet(key) return function() return ns.GEff(G(), key) end end
    local function GOn(key) return function() local g = G() return g ~= nil and ns.GEff(g, key) and true or false end end
    local grpPanel, notArea, areaOnly = {}, {}, {}
    local function GAdd(w, onlyRows, onlyAreas)
        grpPanel[#grpPanel + 1] = w
        if onlyRows then notArea[w] = true end
        if onlyAreas then areaOnly[w] = true end
        return w
    end
    content.gNameCb = GAdd(Add(CheckBox(content, L["Show group name"], GOn("showName"), GOwnSet("showName")), GRID_X, 112))
    -- "Show row names" and the position of the row names are gone since 2026-11-16 (user: only group names stay)
    local capCb = GAdd(Add(CheckBox(content, L["Buff cap tint"], function()
        local g = G()
        if not g then return false end
        if g.id == "main" then return g.capTint ~= false end
        return g.capTint == true
    end, GSet("capTint")), GRID_X, 156))
    SetTooltip(capCb, L["Background is tinted when few buff slots are free"], L["From 4 free slots yellow, then orange, at 1 red."])
    content.gCapCb = capCb
    -- bag count: the group's own value, no inheritance and no reset button (session 20, user: "Leisten" is a heading only;
    -- MigrateBagCount in Core.lua copied its old value into every group with rows)
    content.gCountCb = GAdd(Add(CheckBox(content, L["Bag count"], GOn("showCount"), GOwnSet("showCount")), GRID_X, 200), true)
    -- remaining time in the icons (2026-11-14, user), its font size right of it in the same line
    content.gTimeCb = GAdd(Add(CheckBox(content, L["Show time"], GOn("showTime"), GOwnSet("showTime")), GRID_X, 244))
    SetTooltip(content.gTimeCb, L["Show time"], L["Remaining time in the icons of this group."])
    content.gTimeSize = GAdd(Add(Slider(content, L["Font size"], GEffGet("timeSize"), GOwnSet("timeSize"), 1, 6, 20, nil, GOn("showTime")),
        COL2, 245))
    SetTooltip(content.gTimeSize, L["Font size"], L["Size of the remaining time in the icons of this group."])
    content.gTimeCb.pair = content.gTimeSize
    -- orientation of the group as a dropdown (2026-11-12, user). Since session 20 (user) without "Automatic": every group,
    -- the three areas too, has its own value; none stored = the default "Rows right" (ns.EffectiveOrientation)
    -- icon alignment in the right column since 2026-11-16 (user; own line on the left from 2026-11-15, before right of
    -- "Show group name"): right of the first checkbox line without a partner (RefreshRows)
    content.gOrientBtn = GAdd(Add(CreateChoiceButton(ns.ORIENTATIONS, nil, L["Icons: "], 222, {
        get = function() local g = G() return g and (g.orientation or "hright") end,
        set = function(v) local g = G() if g then g.orientation = v end end,
    }), COL2, ORIENT_Y), nil, true) -- only Unwanted, Other, Debuffs since 2026-11-18 (user): rows set it per row
    SetTooltip(content.gOrientBtn, L["Orientation"], L["How the icons of this group are laid out: rows left- or right-aligned."])
    -- alignment of the group name (2026-11-15, user): only the name, right of "Show group name", grey without the name.
    -- Own value only since session 20 (default "right")
    content.gNameAlignBtn = GAdd(Add(CreateChoiceButton(ns.NAME_ALIGNS, nil, L["Orientation: "], 222, {
        get = function() local g = G() return g and (g.nameAlign or "right") end,
        set = function(v) local g = G() if g then g.nameAlign = v end end,
        enabled = GOn("showName"),
    }), COL2, CB_Y))
    SetTooltip(content.gNameAlignBtn, L["Alignment of the group name"], L["Where the name of this group stands."])
    content.gNameCb.pair = content.gNameAlignBtn
    -- one line (2026-11-15; before 165 px and wrapping), "Lösen" at the right end of the column in the same line
    content.gPosText = GAdd(Place(Label(content, "", "GameFontHighlightSmall"), GRID_X, POS_Y))
    content.gPosText:SetWidth(MID_W - 70)
    content.gPosText:SetJustifyH("LEFT")
    content.gPosText:SetWordWrap(false)
    -- "Lösen": only while snapped; Bar.lua stores the current position on screen as free position
    content.gFreeBtn = GAdd(Place(Button(content, L["Detach"], 60, function()
        local g = G()
        local q = g and type(ns.profile.groupPos) == "table" and ns.profile.groupPos[g.id]
        if not (type(q) == "table" and q.snap) then return end
        if ns.SetGroupFree then ns:SetGroupFree(g.id) end
        ns:RefreshOptions()
    end), GRID_X + MID_W - 60, POS_Y - 2))
    SetTooltip(content.gFreeBtn, L["Detach"], L["The group stays where it is now, but no longer hangs on the other group."])
    -- size of the group on the Layout tab again since 2026-11-16 (user; own tab "Size" from 2026-11-15): two columns
    -- below the checkboxes, left icon size / spacing / scale, right per line / row spacing (RefreshRows places them)
    content.gSizes = {
        GAdd(Add(Slider(content, L["Icon size"], GEffGet("iconSize"), GOwnSet("iconSize"), 2, 12, 64), GRID_X, OPT_Y)),
        GAdd(Add(Slider(content, L["Spacing"], GEffGet("spacing"), GOwnSet("spacing"), 1, 0, 20), GRID_X, OPT_Y)),
        GAdd(Add(Slider(content, L["Scale"], GEffGet("scale"), GOwnSet("scale"), 0.05, 0.5, 2, "%.2f"), GRID_X, OPT_Y)),
    }
    local gPerLine = GAdd(Add(Slider(content, L["Per line (max.)"], PerGet(GEffGet("perLine")), PerSet(function(v)
        local g = G()
        if g and not g.area and not O.WidthOK(g, v) then return end -- a row of the group would not fit (2026-11-16)
        GOwnSet("perLine")(v)
    end), 1, 1, PER_MAX),
        COL_RS, OPT_Y))
    SetTooltip(gPerLine, L["Per line (max.)"], L[PER_LINE_TIP] .. " " .. L["Other, Debuffs: at most this many icons in one line, then they wrap; snapped above or below a group at most as wide as that group (20 = as many as fit; free: 10)."])
    local gRowSp = GAdd(Add(Slider(content, L["Row spacing"], GEffGet("rowSpacing"), GOwnSet("rowSpacing"), 1, 0, 20), COL_RS, OPT_Y)) -- max 20 since 2026-11-18 (user; before 40)
    SetTooltip(gRowSp, L["Row spacing"], L["Spacing between two rows of this group. Unwanted, Other, Debuffs: spacing between their lines."])
    content.gSizes[4], content.gSizes[5] = gPerLine, gRowSp
    for i, key in ipairs({ "iconSize", "spacing", "scale", "perLine", "rowSpacing" }) do
        ResetButton(content.gSizes[i], key, key == "perLine" and function(v)
            return tostring((v and v > 0 and v < PER_MAX) and v or PER_MAX)
        end or nil)
    end
    ResetButton(content.gTimeSize, "timeSize")
    -- fine line above the size sliders (2026-11-16, user; "Font size" stays with the options above it)
    content.gSizeLine = GAdd(Place(Flat(content, "ARTWORK", 1, 1, 1, 0.15), GRID_X, OPT_Y))
    content.gSizeLine:SetSize(MID_W, 1)
    -- heading "Options" with a line on the Layout tab (2026-11-15, user; like "Background" on the Frame tab), the same
    -- height for every group; shown by RefreshRows
    local optLine = Place(Flat(content, "ARTWORK", 1, 1, 1, 0.15), GRID_X, O.OPT_Y + 20)
    optLine:SetSize(MID_W, 1)
    content.optHead = { Place(Label(content, L["Options"]), GRID_X, O.OPT_Y), optLine }
    content.grpPanel, content.grpNotArea, content.grpAreaOnly = grpPanel, notArea, areaOnly
end

local function CreateStyleTabs(Add)
    --------------------------------------------------------------------
    -- Style tabs (2026-11-14, user; mockup "Style tabs", Docs/Idea-Style.md): "Layout | Frame | Separator | Icon
    -- borders" on their own line below the heading (the heading has the full width for the name; more tabs can
    -- follow), for every group. Layout = the widgets above. A group shows its checkbox (g.separator / g.showBorders;
    -- the frame: "None" in its lists since 2026-11-15); its values are its own (no "Alle Gruppen" since session 20).
    -- Two columns: left GRID_X, right COL_RS (2026-11-17, before flush with the edge: colour fields and sliders end
    -- 16 px before the edge, their "↺" fills it).
    --------------------------------------------------------------------
    -- One line again since 2026-11-16 (user; two lines from 2026-11-15): the tab "Size" is gone (its sliders are on
    -- Layout), "Layout" and "Separator" narrower, the two long labels keep 160 px ("Rahmen um die Icons" did not fit
    -- into 120): 90 + 110 + 160 + 160 + 3 x 3 = 529 of MID_W 550. Same tabs and places for every group (mockup STABS).
    local STABS = { { key = "layout", label = L["Layout"], w = 90 }, { key = "sep", label = L["Separator"], w = 110 },
        { key = "frame", label = L["Background/Frame"], w = 160 }, { key = "icon", label = L["Icon borders"], w = 160 } }
    content.styleTabs = {}
    local x = GRID_X
    for i, t in ipairs(STABS) do
        local b = Place(Button(content, t.label, t.w, function()
            O.HideMenus()
            if ColorPickerFrame:IsShown() then ColorPickerFrame:Hide() end
            S.styleTab = t.key
            ns:RefreshOptions()
        end), x, 88)
        x = x + t.w + 3
        b:SetHeight(20)
        b.key, b.label = t.key, t.label
        content.styleTabs[i] = b
    end
    local function SG() return O.CurGroup() end -- always a group since session 20
    local VIS = {
        -- the frame has no checkbox since 2026-11-15 (user): texture and border "None"; its values are always editable
        frame = { get = function() return true end },
        sep = { get = function(g) return ns.SeparatorOn(g) end, set = function(g, v) g.separator = v end },
        icon = { get = function(g) return g.showBorders == true end, set = function(g, v) g.showBorders = v or nil end },
    }
    -- stores a value of the group; the default (STYLE_DEF) is removed instead
    local function SStore(holder, sec, key, v, parentV)
        if v == parentV then
            local s = type(holder.style) == "table" and holder.style[sec]
            if type(s) == "table" then
                s[key] = nil
                if next(s) == nil then holder.style[sec] = nil end
                if next(holder.style) == nil then holder.style = nil end
            end
            return
        end
        if type(holder.style) ~= "table" then holder.style = {} end
        if type(holder.style[sec]) ~= "table" then holder.style[sec] = {} end
        holder.style[sec][key] = v
    end
    local function SPut(sec, key, v)
        local g = SG()
        if g then SStore(g, sec, key, v, ns.STYLE_DEF[sec][key]) end
    end
    local function SGet(sec, key) return function() return ns.StyleOf(SG(), sec)[key] end end
    -- "↺" behind every colour field and slider (2026-11-17, user; mockup sReset): own value = one of keys stored in
    -- g.style[sec], click = back to STYLE_DEF. show(style) -> text for the tooltip
    local function SReset(ctrl, sec, keys, show)
        return ResetIcon(ctrl, function()
            local g = SG()
            local s = g and type(g.style) == "table" and g.style[sec]
            if type(s) ~= "table" then return false end
            for _, k in ipairs(keys) do
                if s[k] ~= nil then return true end
            end
            return false
        end, function()
            for _, k in ipairs(keys) do SPut(sec, k, ns.STYLE_DEF[sec][k]) end
        end, function() return show(ns.StyleOf(SG(), sec)), show(ns.STYLE_DEF[sec]) end)
    end
    -- tooltip texts: "#a0a0aa 50%" (colour with opacity), numbers like the Layout tab
    local function ColourText(key, alphaKey)
        return function(st)
            local s = string.lower(tostring(st[key]))
            if alphaKey then s = s .. string.format(" %d%%", math.floor((st[alphaKey] or 1) * 100 + 0.5)) end
            return s
        end
    end
    local function NumText(key) return function(st) return Fv(st[key]) end end
    local function SSet(sec, key) return function(v) SPut(sec, key, v) Changed() end end
    -- values can be changed while the element is visible
    local function SOn(sec, extra)
        return function()
            local ok = SG() ~= nil and VIS[sec].get(SG())
            return (ok and (not extra or extra())) and true or false
        end
    end
    -- widgets per tab: { w = widget, cond = function(grp) -> shown }
    local stylePanel = { frame = {}, sep = {}, icon = {} }
    local function SAdd(sec, w, cond) stylePanel[sec][#stylePanel[sec] + 1] = { w = w, cond = cond } return w end
    local function SHead(sec, text, x, y)
        SAdd(sec, Place(Label(content, text), x, y))
        local line = Place(Flat(content, "ARTWORK", 1, 1, 1, 0.15), x, y + 20)
        line:SetSize(222, 1)
        SAdd(sec, line)
    end
    -- notes of a tab: below its controls, one below the other (RefreshRows: O.Flow from content.styleNotes[sec].y)
    content.styleNotes = { frame = { y = TOP_Y + 118 }, sep = { y = TOP_Y + 118 },
        icon = { y = TOP_Y + 62 } }
    local function SNote(sec, text, cond)
        local n = Place(Label(content, text, "GameFontDisableSmall"), GRID_X, TOP_Y)
        n:SetWidth(MID_W)
        n:SetJustifyH("LEFT")
        local list = content.styleNotes[sec]
        list[#list + 1] = n
        return SAdd(sec, n, cond)
    end
    -- top line of the left column (2026-11-15, user): the checkbox that shows the element, a line below it (Separator,
    -- Icon borders; the frame has "None" in its lists instead). The heading of "Alle Gruppen" and "Like All Groups" are
    -- gone since session 20.
    local function STop(sec, cbText, tip)
        local cb = Add(CheckBox(content, cbText, function() local g = SG() return g ~= nil and VIS[sec].get(g) end,
            function(v) local g = SG() if g then VIS[sec].set(g, v) Changed() end end), GRID_X, TOP_Y - 4)
        SetTooltip(cb, cbText, tip)
        SAdd(sec, cb)
        local line = Place(Flat(content, "ARTWORK", 1, 1, 1, 0.15), GRID_X, TOP_Y + 20)
        line:SetSize(222, 1)
        SAdd(sec, line)
    end
    -- colour field: label + box, click = colour picker (with opacity when alphaKey is given)
    local function Swatch(sec, text, key, alphaKey, x, y, extra)
        local f = CreateFrame("Button", nil, content)
        f:SetSize(222, 20)
        Place(f, x, y)
        f.label = Label(f, text, "GameFontNormal")
        f.label:SetPoint("LEFT", 0, 0)
        f.edge = f:CreateTexture(nil, "BORDER")
        f.edge:SetSize(36, 18)
        f.edge:SetPoint("RIGHT", 0, 0)
        Solid(f.edge, 0.55, 0.55, 0.55, 1)
        f.back = f:CreateTexture(nil, "ARTWORK", nil, 0)
        f.back:SetSize(34, 16)
        f.back:SetPoint("CENTER", f.edge, "CENTER")
        Solid(f.back, 0.12, 0.12, 0.12, 1)
        f.fill = f:CreateTexture(nil, "ARTWORK", nil, 1)
        f.fill:SetSize(34, 16)
        f.fill:SetPoint("CENTER", f.edge, "CENTER")
        f.fill:SetTexture("Interface\\Buttons\\WHITE8X8")
        f:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        local on = SOn(sec, extra)
        f:SetScript("OnClick", function()
            if not on() then return end
            local st = ns.StyleOf(SG(), sec)
            local r, g, b = ns.HexColor(st[key])
            OpenColorPicker(r, g, b, alphaKey and st[alphaKey] or nil, function(nr, ng, nb, na)
                SPut(sec, key, ns.ToHex(nr, ng, nb))
                if alphaKey and na then SPut(sec, alphaKey, na) end
                Changed()
            end)
        end)
        f.Refresh = function(self)
            local st = ns.StyleOf(SG(), sec)
            local r, g, b = ns.HexColor(st[key])
            self.fill:SetVertexColor(r, g, b, alphaKey and st[alphaKey] or 1)
            local en = on()
            if en then self.label:SetTextColor(1, 0.82, 0) else self.label:SetTextColor(0.5, 0.5, 0.5) end
            self.fill:SetAlpha(en and 1 or 0.35)
        end
        content.controls[#content.controls + 1] = f
        return SReset(f, sec, alphaKey and { key, alphaKey } or { key }, ColourText(key, alphaKey))
    end
    local function SSlider(sec, text, key, step, minV, maxV, x, y, fmt, extra)
        local s = Add(Slider(content, text, SGet(sec, key), SSet(sec, key), step, minV, maxV, fmt, SOn(sec, extra)), x, y)
        SReset(s, sec, { key }, NumText(key))
        return SAdd(sec, s)
    end
    -- choice button; "↺" behind it since 2026-11-20 (user: texture, border style, separator look, fade ends), the
    -- tooltip names the entries
    local function SChoice(sec, text, key, list, x, y, preview, extra, cond)
        local b = Add(CreateChoiceButton(list, nil, text, 222, {
            get = SGet(sec, key), set = function(v) SPut(sec, key, v) end, enabled = SOn(sec, extra),
            preview = preview, menuWidth = 200,
        }), x, y)
        SReset(b, sec, { key }, function(st)
            for _, e in ipairs(list) do
                if e.key == st[key] then return L[e.label] end
            end
            return tostring(st[key])
        end)
        return SAdd(sec, b, cond)
    end
    local notUnw = function() local g = SG() return not (g and g.area == "unw") end

    -- Frame: background left, border right (not for "Unerwünschte Buffs": its own button frame). No checkbox since
    -- 2026-11-15 (user): texture "None" = no background, border "None" = no border; the frame shows with either
    -- (ns.FrameOn). Since session 20 (user) without "Automatic": texture and style are the group's own values (default
    -- "None").
    SHead("frame", L["Background"], GRID_X, TOP_Y)
    SHead("frame", L["Border"], COL_RS, TOP_Y)
    local BG_LIST = { { key = "none", label = "None##texture" }, { key = "solid", label = "Solid" }, { key = "gradient", label = "Gradient" },
        { key = "dialog", label = "Dialog (dark)" }, { key = "marble", label = "Marble" }, { key = "parchment", label = "Parchment" } }
    local BG_FILES = {
        dialog = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        marble = "Interface\\FrameGeneral\\UI-Background-Marble",
        parchment = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal",
    }
    local function TexPreview(key, tex)
        local st = ns.StyleOf(SG(), "frame")
        local r, g, b = ns.HexColor(st.bgColor)
        if BG_FILES[key] then
            tex:SetTexture(BG_FILES[key])
            tex:SetVertexColor(1, 1, 1, 1)
        else
            tex:SetTexture("Interface\\Buttons\\WHITE8X8")
            if key == "none" then
                tex:SetVertexColor(0, 0, 0, 0)
            elseif key == "gradient" then
                tex:SetGradient("VERTICAL", CreateColor(r * 0.55, g * 0.55, b * 0.55, 1), CreateColor(r, g, b, 1))
            else
                tex:SetVertexColor(r, g, b, 1)
            end
        end
    end
    local EDGE_LIST = { { key = "none", label = "None" }, { key = "flat", label = "Flat line" }, -- "Double line" removed 2026-11-15
        { key = "tooltip", label = "Tooltip" }, { key = "dialog", label = "Dialog" } }
    SChoice("frame", L["Texture: "], "bgTex", BG_LIST, GRID_X, TOP_Y + 26, TexPreview, notUnw)
    SChoice("frame", L["Style: "], "edge", EDGE_LIST, COL_RS, TOP_Y + 26, nil, notUnw)
    -- colours and thickness: while its part is not "None"
    local function BgOn() return notUnw() and ns.StyleOf(SG(), "frame").bgTex ~= "none" end
    local function EdgeOn() return notUnw() and ns.StyleOf(SG(), "frame").edge ~= "none" end
    SAdd("frame", Swatch("frame", L["Color and opacity"], "bgColor", "bgAlpha", GRID_X, TOP_Y + 58, BgOn))
    SAdd("frame", Swatch("frame", L["Color and opacity"], "edgeColor", "edgeAlpha", COL_RS, TOP_Y + 58, EdgeOn))
    SSlider("frame", L["Thickness"], "edgeSize", 1, 1, 8, COL_RS, TOP_Y + 86, nil, EdgeOn)
    SNote("frame", L["\"Unwanted Buffs\" has its own button frame."], function(grp) return grp ~= nil and grp.area == "unw" end)

    -- Separator: the checkbox instead of the heading "Line" (2026-11-15, user)
    STop("sep", L["Show separator"], L["Thin line on the side where this group is docked. Only when it is snapped to another group."])
    SHead("sep", L["Size"], COL_RS, TOP_Y)
    local SEP_LIST = { { key = "solid", label = "Solid" }, { key = "dashed", label = "Dashed" }, { key = "dotted", label = "Dotted" } }
    SChoice("sep", L["Look: "], "look", SEP_LIST, GRID_X, TOP_Y + 26)
    -- fading ends as their own choice (2026-11-15, user; before the look "Fading at the ends", solid only), in the line
    -- of "Shorten" (both are about the ends). Vertical lines: left = top, right = bottom
    local SEP_FADES = { { key = "none", label = "No" }, { key = "left", label = "Left" },
        { key = "right", label = "Right" }, { key = "both", label = "Both sides" } }
    local fadeBtn = SChoice("sep", L["Fade ends: "], "fade", SEP_FADES, GRID_X, TOP_Y + 52)
    SetTooltip(fadeBtn, L["Fade ends"], L["The line fades out toward these ends over half of its length (both sides: from the middle), whatever its look. Lines beside a group: left = top, right = bottom."])
    SAdd("sep", Swatch("sep", L["Color and opacity"], "color", "alpha", GRID_X, TOP_Y + 84))
    SSlider("sep", L["Thickness"], "size", 1, 1, 6, COL_RS, TOP_Y + 26)
    local shorten = SSlider("sep", L["Shorten"], "inset", 1, 0, 60, COL_RS, TOP_Y + 52)
    SetTooltip(shorten, L["Shorten"], L["The line ends this many pixels before both ends of the group."])
    SNote("sep", L["Only shown when the group is snapped to another one."])

    -- Icon borders: the checkbox instead of the heading "Size" (2026-11-15, user). Only the colours that occur in the
    -- selected group (2026-11-14, user): rows active/missing, "Unerwünschte Buffs" unwanted, "Sonstige Buffs" other,
    -- Debuffs none (type colour). Stacked from the top without gaps, the notes below (RefreshRows).
    STop("icon", L["Show icon borders"], L["Without borders the colors are missing too (green active, red unwanted, debuff type). The red loss alarm still flashes."])
    SSlider("icon", L["Thickness"], "size", 1, 1, 4, GRID_X, TOP_Y + 26)
    local colHead = Place(Label(content, L["Colors"]), COL_RS, TOP_Y)
    local colLine = Place(Flat(content, "ARTWORK", 1, 1, 1, 0.15), COL_RS, TOP_Y + 20)
    colLine:SetSize(222, 1)
    content.iconColHead = { colHead, colLine }
    SAdd("icon", colHead, function(grp) return grp ~= nil and grp.area ~= "debuff" end)
    SAdd("icon", colLine, function(grp) return grp ~= nil and grp.area ~= "debuff" end)
    content.iconColours = {}
    for _, c in ipairs({
        { key = "active", text = L["Active"], on = function(grp) return not grp.area end },
        { key = "missing", text = L["Missing"], on = function(grp) return not grp.area end },
        { key = "unwanted", text = L["Unwanted"], on = function(grp) return grp.area == "unw" end },
        { key = "other", text = L["Other buffs"], on = function(grp) return grp.area == "other" end },
    }) do
        c.w = Swatch("icon", c.text, c.key, nil, COL_RS, TOP_Y + 26)
        SAdd("icon", c.w, function(grp) return grp ~= nil and c.on(grp) end)
        content.iconColours[#content.iconColours + 1] = c
    end
    SNote("icon", L["Debuffs keep the color of their type, a lost consumable still flashes red."])

    -- the tab "Size" (2026-11-15) is gone since 2026-11-16 (user): its five sliders are on Layout (CreateGroupPanel)
    content.stylePanel = stylePanel
end

O.CreateGroupPanel, O.CreateStyleTabs = CreateGroupPanel, CreateStyleTabs
