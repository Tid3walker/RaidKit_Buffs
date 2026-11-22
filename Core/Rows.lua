-- RaidKit Buffs: Core - Rows
-- Rows of a profile (defaults from the class templates, EnsureRows), groups and their default places, group
-- values (GEff) and styles. Split from Core.lua on 2026-11-20.

local _, ns = ...
local L = ns.L
local CopyTable = ns.CopyTable

------------------------------------------------------------------------
-- Rows
-- A profile owns its rows directly. Row templates (Data.lua) are only copied in.
------------------------------------------------------------------------

function ns:PlayerClass()
    local _, token = UnitClass("player")
    return token or "WARRIOR"
end

function ns:GetRowTemplates()
    return ns.ROW_TEMPLATES[ns:PlayerClass()] or {}
end

-- Rows of a new profile: a copy of the class templates marked visible (user 2026-11-11: only the active rows in
-- the list; the others stay available through "+" in the options, e.g. "Schutz", "Tank", "Situativ")
-- tpl.visible = place in the new profile (2026-11-14: 1 "Selbst verantwortlich", 2 "Raidbuffs", 3 "Weltbuffs");
-- true counts as the template order
-- groupId (2026-11-20, presets of "+" in the options): only the templates of that group ("main" = those without
-- tpl.group); nil = all of them
local function DefaultRows(groupId)
    local list = {}
    for i, tpl in ipairs(ns:GetRowTemplates()) do
        if tpl.visible and (groupId == nil or (tpl.group or "main") == groupId) then
            list[#list + 1] = { tpl = tpl, k = (type(tpl.visible) == "number" and tpl.visible or 100) * 1000 + i }
        end
    end
    table.sort(list, function(a, b) return a.k < b.k end)
    local rows = {}
    for _, e in ipairs(list) do
        -- chosen language; tpl.group (2026-11-18): the row starts in that class group (ns.CLASS_GROUPS)
        local row = { name = ns.Text(e.tpl.name), items = ns.TemplateItems(e.tpl), group = e.tpl.group }
        -- separator and eye of the template (user 2026-11-19): split = icons on the left, splitLast = icons on the
        -- right (counted after the faction filter); a split that leaves one side empty is dropped
        local split = e.tpl.split or (e.tpl.splitLast and #row.items - e.tpl.splitLast)
        if split and split > 0 and split < #row.items then row.split, row.sepStyle = split, e.tpl.sepStyle end
        row.hidden = e.tpl.hidden or nil
        rows[#rows + 1] = row
    end
    return rows
end

-- Group presets of the "+" menu in the options (user 2026-11-20): the default groups of a new profile, to add again as
-- a new group. key = group id in a new profile ("main" or an id of ns.CLASS_GROUPS), name = English key of the name,
-- values = group values (CLASS_GROUPS entry without id/name/place), snap/side/align = default place (may be nil).
-- More presets may follow (user); their rows come from the visible templates of that group (ns.PresetRows).
function ns.GroupPresets()
    local list = { { key = "main", name = "Buffs & Cons", values = {} } }
    for _, cg in ipairs(ns.CLASS_GROUPS[ns:PlayerClass()] or {}) do
        local values = {}
        for k, v in pairs(cg) do
            if k ~= "id" and k ~= "name" and k ~= "snap" and k ~= "side" and k ~= "align" then values[k] = v end
        end
        list[#list + 1] = { key = cg.id, name = cg.name, values = values, snap = cg.snap, side = cg.side, align = cg.align }
    end
    return list
end

-- fresh copies of the rows a preset brings (row.group is set by the caller)
function ns.PresetRows(preset)
    return DefaultRows(preset.key)
end

-- Puts the profile's row with one of the given names into the order of the class template with the fixed key
-- tplKey (2026-11-12): the template's entries (faction filtered, missing ones added), then every other entry of
-- the row as it was. Only plain buff/item IDs are compared; slots (tables) of the row stay behind the template
-- entries. Templates are found by t.key (2026-11-14: t.name is localized); rows by their stored name, given as a
-- set of accepted names (German name of older profiles and the localized one).
function ns.ResortRowByTemplate(prof, tplKey, rowNames)
    local tpl
    for _, t in ipairs(ns:GetRowTemplates()) do
        if t.key == tplKey then tpl = t break end
    end
    if not tpl or type(prof.rows) ~= "table" then return end
    for _, row in ipairs(prof.rows) do
        if rowNames[row.name or ""] and type(row.items) == "table" then
            local items, seen = ns.TemplateItems(tpl), {}
            for _, e in ipairs(items) do
                if type(e) == "number" then seen[e] = true end
            end
            for _, e in ipairs(row.items) do
                if type(e) ~= "number" or not seen[e] then items[#items + 1] = e end
            end
            row.items = items
        end
    end
end

-- Gives a profile its rows if it has none yet (new profile, reset, migration).
-- Needs the player class, so it only runs from PLAYER_LOGIN on.
--
-- Migration 0.5.0 -> 0.6.0: 0.5.0 stored rows in presets (RaidKitBuffsDB.presets) and the
-- profile only pointed to one. If the profile pointed to a custom preset, its rows come back.
function ns:EnsureRows(prof)
    -- list "Unerwünscht": class default once (new key 2026-11-09, also for existing profiles)
    if type(prof.unwanted) ~= "table" then
        prof.unwanted = CopyTable(ns.DEFAULT_UNWANTED[ns:PlayerClass()] or {})
    end
    -- new order of the list (user 2026-11-12), once per profile; later changes by hand stay
    if not prof.unwantedSorted then
        ns.SortUnwanted(prof.unwanted)
        prof.unwantedSorted = true
    end
    local fresh
    if type(prof.rows) ~= "table" then
        local presets = RaidKitBuffsDB.presets
        local old = presets and prof.preset and presets[prof.preset]
        prof.rows = old and CopyTable(old.rows) or DefaultRows()
        prof.preset = nil
        -- new profile (fresh install, reset): the groups of the class (2026-11-18, ns.CLASS_GROUPS) for its rows
        if not old and type(prof.groups) ~= "table" then
            fresh = true
            prof.groups = {}
            for _, cg in ipairs(ns.CLASS_GROUPS[ns:PlayerClass()] or {}) do
                local g = {}
                for k, v in pairs(cg) do
                    if k ~= "snap" and k ~= "side" and k ~= "align" then g[k] = v end
                end
                prof.groups[#prof.groups + 1] = g
            end
        end
    end
    -- warrior row "Raidbuffs" in the new order of the template (user 2026-11-12: + Leader of the Pack, Trueshot
    -- Aura), once per profile: template order first, entries of the user's own keep their order behind it
    if not prof.raidbuffsSorted then
        prof.raidbuffsSorted = true
        if ns:PlayerClass() == "WARRIOR" then
            ns.ResortRowByTemplate(prof, "raid", { ["Raidbuffs"] = true, [L["Raid Buffs"]] = true })
        end
    end
    -- row "Raidbuffs": Stamina, Intellect, Spirit, Gift of the Wild first (user 2026-11-14), once per profile; only
    -- moves what the row holds, adds nothing
    if not prof.raidbuffsFront then
        prof.raidbuffsFront = true
        for _, row in ipairs(prof.rows) do
            if (row.name == "Raidbuffs" or row.name == "Raid Buffs" or row.name == L["Raid Buffs"])
                and type(row.items) == "table" then
                row.items = ns.FrontRaidBuffs(row.items)
            end
        end
    end
    ns.EnsureGroups(prof, fresh) -- groups (2026-11-11)
end

------------------------------------------------------------------------
-- Groups (2026-11-11, Docs/Plan-Groups.md): rows are combined into groups; each group has its own position
-- (free or snapped to another group's edge), an optional frame and own settings. "Unerwünschte Buffs",
-- "Sonstige Buffs" and "Debuffs" are three fixed groups (g.area). Old profiles get one group "main" with every
-- row and the three areas snapped below each other = the old layout. No schema step: EnsureGroups fills it.
------------------------------------------------------------------------

ns.MAX_GROUPS = 6 -- groups with rows (the three areas come on top)
-- snap/side = default place (new profiles, reset). Since 2026-11-14 (user, the layout they use): Buffs & Cons, below
-- it "Other Buffs", below that "Debuffs"; "Unwanted Buffs" left of Buffs & Cons (side "left" = sits left of its
-- target). Before: Unwanted, Other, Debuffs below each other under Buffs & Cons (Debuffs last, user 2026-11-12).
-- Debuffs: own red separator colour. No own showName since 2026-11-15 (user: a fresh install showed the names of the
-- three areas although "All Groups" has "Show group name" off; MigrateAreaNames drops the old default value)
ns.AREA_GROUPS = {
    { id = "unw", area = "unw", name = "Unwanted Buffs", capTint = true, snap = "main", side = "left" },
    { id = "other", area = "other", name = "Other Buffs", capTint = true, snap = "main", side = "bottom" },
    { id = "debuff", area = "debuff", name = "Debuffs", snap = "other", side = "bottom",
        style = { sep = { color = "#ff5959", alpha = 0.45 } } },
}

------------------------------------------------------------------------
-- Group values and style (2026-11-14, user; mockup: GROUP_INHERIT / gEff, STYLE_DEF / styleOf; Docs/Idea-Style.md)
-- From 2026-11-14 a group inherited from "Alle Gruppen". Since session 20 (user) "Alle Gruppen" is gone: every group
-- decides on its own, a value it does not store is the default of the addon (MigrateAllGroups moved the old values).
------------------------------------------------------------------------

-- values of a group: group key -> key in ns.profileDefaults (until session 20 the key of "Alle Gruppen")
ns.GROUP_INHERIT = {
    -- showCount is no longer inherited since session 20 (user: per group only, MigrateBagCount)
    showName = "showGroupName", rowNames = "showRowNames", showTime = "showTime",
    timeSize = "timeSize", iconSize = "iconSize", spacing = "spacing", scale = "scale", perLine = "perLine",
    rowSpacing = "rowSpacing",
}

-- "Per line" of a group with rows (user 2026-11-20: 12 icons per row by default; before 0 = 20 places). The buff areas
-- keep the profile default 0 (= as many as fit). Groups of older profiles got their old value once (MigratePerLine).
ns.ROW_PER_LINE = 12

-- default of value k for group g (nil g = the profile default, e.g. "All Groups" of old profiles)
function ns.GDefault(g, k)
    if k == "perLine" and g and not g.area then return ns.ROW_PER_LINE end
    local v = ns.profileDefaults[ns.GROUP_INHERIT[k] or k]
    if v == nil and k == "perLine" then v = 0 end
    return v
end

-- value that counts for group g: its own value, else its default (ns.GDefault). The third argument (a profile) is not
-- needed any more since session 20 and ignored.
function ns.GEff(g, k)
    if g and g[k] ~= nil then return g[k] end
    return ns.GDefault(g, k)
end

-- Style sections: frame (background + border of a group frame), sep (separator line), icon (icon borders).
-- Colours "#rrggbb", opacity separate. STYLE_DEF = the look before 2026-11-14.
-- Frame defaults: texture "None" and border "None" since 2026-11-15 (user; before "gradient" / "flat", MigrateFrame and
-- MigrateFrameAuto). A group without own values has these defaults (no "All Groups" since session 20).
ns.STYLE_DEF = {
    frame = { bgTex = "none", bgColor = "#28282e", bgAlpha = 0.85, edge = "none", edgeColor = "#6c6c78", edgeAlpha = 1, edgeSize = 1 },
    -- fade (2026-11-15, user): which ends fade out, its own choice for every look ("none" | "left" | "right" | "both",
    -- default "left"); before a look "fade" (both ends, solid only), converted by MigrateSepFade
    sep = { look = "solid", fade = "left", color = "#a0a0aa", alpha = 0.5, size = 1, inset = 0 },
    icon = { size = 1, active = "#33e633", missing = "#595959", unwanted = "#ff3030", other = "#555555" },
}

-- resolved style of a section: STYLE_DEF < g.style (nil g = the defaults; "Alle Gruppen" level gone since session 20)
function ns.StyleOf(g, sec)
    local out = {}
    for k, v in pairs(ns.STYLE_DEF[sec]) do out[k] = v end
    local o = g and type(g.style) == "table" and type(g.style[sec]) == "table" and g.style[sec]
    if o then for k, v in pairs(o) do out[k] = v end end
    if out.edge == "double" then out.edge = "flat" end -- "Double line" removed 2026-11-15 (user)
    if out.look == "fade" then out.look, out.fade = "solid", "both" end -- old look "fade" (MigrateSepFade converts it)
    return out
end

-- alignment of the group name (2026-11-15, user; mockup nameAlignOf): "left" | "center" | "right". Since session 20
-- (user: no "Automatic") the group's own value, else the default "right"
function ns.NameAlign(g)
    return type(g) == "table" and g.nameAlign or "right"
end

-- frame of a group (2026-11-15, user; mockup frameOn): texture or border other than "none"; either one makes the frame.
-- "Unwanted Buffs" never (it has its own button frame).
function ns.FrameOn(g)
    if type(g) ~= "table" or g.area == "unw" then return false end
    local st = ns.StyleOf(g, "frame")
    return st.bgTex ~= "none" or st.edge ~= "none"
end

-- "#rrggbb" -> r, g, b (0-1); anything else is white
function ns.HexColor(hex)
    local n = type(hex) == "string" and tonumber(hex:sub(2), 16) or nil
    if not n then return 1, 1, 1 end
    return math.floor(n / 65536) % 256 / 255, math.floor(n / 256) % 256 / 255, n % 256 / 255
end

function ns.ToHex(r, g, b)
    local function C(v) return math.max(0, math.min(255, math.floor((v or 0) * 255 + 0.5))) end
    return string.format("#%02x%02x%02x", C(r), C(g), C(b))
end

function ns.GroupById(prof, id)
    for _, g in ipairs(prof.groups or {}) do
        if g.id == id then return g end
    end
end

-- Default names of the fixed groups (2026-11-14, localization): profiles store g.name, older ones in German.
-- A stored default (German or English spelling) shows the localized default; an own name is shown as typed.
local DEFAULT_GROUP_NAMES = {
    main = { key = "Buffs & Cons", names = { ["Buffs & Cons"] = true, ["Hauptleiste"] = true } },
    unw = { key = "Unwanted Buffs", names = { ["Unwanted Buffs"] = true, ["Unerwünschte Buffs"] = true } },
    other = { key = "Other Buffs", names = { ["Other Buffs"] = true, ["Sonstige Buffs"] = true } },
    debuff = { key = "Debuffs", names = { ["Debuffs"] = true } },
    shout = { key = "Battle Shout", names = { ["Battle Shout"] = true } }, -- warrior group (2026-11-18, ns.CLASS_GROUPS)
}

function ns.GroupDisplayName(g)
    if type(g) ~= "table" then return L["Group"] end
    local name = type(g.name) == "string" and g.name or ""
    local def = DEFAULT_GROUP_NAMES[g.id]
    if def and (name == "" or def.names[name]) then return L[def.key] end
    if name == "" then return L["Group"] end
    return name
end
