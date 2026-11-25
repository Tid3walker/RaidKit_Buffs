-- RaidKit Buffs: Options - rows and groups: selection and editing
-- Current row and group, adding/moving/removing items, rows and groups, confirmation popups.
-- O = ns.Opt (shared functions and constants), S = ns.OptState (shared state), see OptionsBase.lua.

local _, ns = ...
local L = ns.L
local O, S = ns.Opt, ns.OptState
local MAX_GROUP_ROWS, MAX_UNWANTED, Changed, Rows = O.MAX_GROUP_ROWS, O.MAX_UNWANTED, O.Changed, O.Rows

------------------------------------------------------------------------
-- Actions on the current row
------------------------------------------------------------------------

-- Session 4b (2026-11-11, user: "Unerwünschte Buffs" should show its list like a row): while that group is
-- selected, the middle column edits ns.profile.unwanted through this pseudo row (plain buff IDs, no slots, no
-- alternatives, only buffs). Before, the list was a small field below the catalog (tab "Buffs").
local unwRow = { unwanted = true }
local function CurrentRow()
    if S.selectedGroup == "unw" then
        ns.profile.unwanted = ns.profile.unwanted or {}
        unwRow.items = ns.profile.unwanted
        unwRow.name = L["Unwanted Buffs"] -- set here: at load time the language is not known yet
        return unwRow
    end
    -- the active row of the selected group (2026-11-16: rows are on the group's Layout tab, a click on a line makes
    -- it active), else its first row; a catalog click adds there
    local g = S.selectedGroup and ns.GroupById(ns.profile, S.selectedGroup)
    if not g or g.area then return nil end
    local r = Rows()[S.selectedRow]
    if r and (r.group or "main") == g.id then return r end
    for _, x in ipairs(Rows()) do
        if (x.group or "main") == g.id then return x end
    end
end

------------------------------------------------------------------------
-- Groups (2026-11-11, Docs/Plan-Groups.md; mockup: normalizeGroups, curGroup, addGroup, deleteGroup ...)
-- Data model and ns.EnsureGroups live in Core.lua; positions (groupPos) are character values.
------------------------------------------------------------------------

local function Groups()
    return ns.profile.groups or {}
end

local function CurGroup()
    return S.selectedGroup and ns.GroupById(ns.profile, S.selectedGroup) or nil
end

local function GroupName(g)
    return ns.GroupDisplayName and ns.GroupDisplayName(g) or ((g.name and g.name ~= "") and g.name) or L["Group"]
end

-- number of groups that hold rows (the three buff areas do not count)
local function RowGroupCount()
    local n = 0
    for _, g in ipairs(Groups()) do
        if not g.area then n = n + 1 end
    end
    return n
end

-- EnsureGroups sorts the rows by group; the selected row object stays selected
local function NormalizeGroups()
    local r = Rows()[S.selectedRow]
    ns.EnsureGroups(ns.profile)
    if r then
        for i, x in ipairs(Rows()) do
            if x == r then S.selectedRow = i end
        end
    end
    if S.selectedGroup and not CurGroup() then S.selectedGroup = nil end
end

-- index of the entry that contains itemID (as icon or as alternative)
local function RowIndexOf(row, itemID)
    if not row then return nil end
    for i, entry in ipairs(row.items) do
        if ns.EntryHas(entry, itemID) then return i end
    end
end

-- Removes itemID from the row: a plain icon disappears (returns its index), a slot only loses
-- that variant (a slot with one variant left becomes a plain icon again).
local function TakeFromRow(row, itemID)
    local i = RowIndexOf(row, itemID)
    if not i then return nil end
    local entry = row.items[i]
    if not ns.IsSlot(entry) then
        O.SpliceItem(row, i) -- keeps the halves of a split row (2026-11-15)
        return i
    end
    local rest = { pick = entry.pick, hand = entry.hand } -- weapon entries keep their hand
    for _, id in ipairs(entry) do
        if id ~= itemID then rest[#rest + 1] = id end
    end
    row.items[i] = ns.NormalizeEntry(rest)
end

-- Inserts itemID at position pos (nil = at the end). If it is already in the row, it is moved
-- (an alternative of a slot becomes its own icon). rowArg (2026-11-15): a row of the split stack, else the selected row.
local function InsertItem(itemID, pos, rowArg)
    if not itemID then return end
    local row = rowArg or CurrentRow()
    if not row then
        ns:Print(L["Please create a row first."])
        return
    end
    if row.unwanted then
        -- unwanted list: only buffs, plain IDs (a buff already there is just moved)
        local cb = ns.buffCatalog[itemID]
        if not ns.IsBuffID(itemID) or (cb and cb.counter) then -- not the buff counter either (2026-11-25)
            ns:Print(L["Only buffs can be unwanted."])
            return
        end
        local at = RowIndexOf(row, itemID)
        if at then
            table.remove(row.items, at)
        elseif #row.items >= MAX_UNWANTED then
            ns:Print(L["At most %d unwanted buffs."], MAX_UNWANTED)
            return
        end
        pos = math.min(pos or (#row.items + 1), #row.items + 1)
        table.insert(row.items, pos, itemID)
        Changed()
        return
    end
    -- since 2026-11-11 every row takes consumables and buffs
    local existing = RowIndexOf(row, itemID)
    local entry
    -- a row takes at most the places of its group, a split row one less (2026-11-16, OptionsSplit.lua)
    local cap = O.RowCap(row)
    local function Full() O.PrintRowFull(row) end
    if ns.IsWeaponItem(itemID) then
        -- weapon item (2026-11-09): always a new icon, the same stone may sit on both hands. It takes the
        -- hand the row does not cover yet (main first).
        if #row.items >= cap then
            Full()
            return
        end
        local hasMain, hasOff = false, false
        for _, e in ipairs(row.items) do
            if ns.IsWeaponEntry(e) then
                if e.hand == "main" then hasMain = true else hasOff = true end
            end
        end
        entry = ns.DefaultEntry(itemID, nil, (hasMain and not hasOff) and "off" or "main")
    elseif existing and ns.EntryMain(row.items[existing]) == itemID then
        entry = table.remove(row.items, existing) -- already an icon: moved, with its alternatives
    elseif #row.items >= cap then
        Full()
        return
    elseif existing then
        TakeFromRow(row, itemID) -- alternative of another icon: becomes its own icon
        entry = itemID
    else
        -- new in this row: with its default alternatives (Data.lua), unless they are already in the row
        entry = ns.DefaultEntry(itemID, function(id) return RowIndexOf(row, id) ~= nil end)
    end
    pos = math.min(pos or (#row.items + 1), #row.items + 1)
    table.insert(row.items, pos, entry)
    for _, id in ipairs(ns.EntryIDs(entry)) do
        ns.GetItemInfo(id) -- request item data (may arrive via GET_ITEM_INFO_RECEIVED)
        ns:ClearBuffCache(id)
    end
    Changed()
end

local function RemoveAt(index)
    local row = CurrentRow()
    if row and row.items[index] then
        O.SpliceItem(row, index)
        Changed()
    end
end

local function MoveTo(from, to)
    local row = CurrentRow()
    if not row or not row.items[from] then return end
    local v = table.remove(row.items, from)
    to = math.max(1, math.min(to, #row.items + 1))
    table.insert(row.items, to, v)
    Changed()
end

-- Real item from the cursor (dragged from the bags)
local function AddFromCursor(pos)
    local kind, itemID = GetCursorInfo()
    if kind == "item" and itemID then
        ClearCursor()
        InsertItem(itemID, pos)
        return true
    end
end

-- Moves row `from` to position `to`; returns the new position
local function MoveRowTo(from, to)
    local rows = Rows()
    if not rows[from] then return from end
    to = math.max(1, math.min(to, #rows))
    if to == from then return from end
    local r = table.remove(rows, from)
    table.insert(rows, to, r)
    return to
end

-- "+ Row" on the Layout tab of a group (2026-11-16): the row goes to the end of the selected group and becomes active;
-- at most MAX_GROUP_ROWS per group (before 10 rows in the whole profile)
local function AddRow(row)
    local g = CurGroup()
    if not g or g.area then return end
    local mine = O.GroupRows(g)
    if #mine >= MAX_GROUP_ROWS then
        ns:Print(L["At most %d rows per group."], MAX_GROUP_ROWS)
        return
    end
    row.group = g.id
    O.FitRow(row, g) -- a template longer than the group's rows is cut (2026-11-16, OptionsSplit.lua)
    local rows = Rows()
    local pos = #mine > 0 and (mine[#mine][2] + 1) or (#rows + 1)
    table.insert(rows, pos, row)
    S.selectedRow = pos
    Changed()
end

-- every row takes consumables and buffs (2026-11-11; before there were consumable and buff rows)
local function AddEmptyRow()
    AddRow({ name = "", items = {} }) -- no row names since 2026-11-16
end

-- Copy of a row template (Data.lua); the copy belongs to the profile and is editable (its name stays in the data)
local function AddTemplateRow(tpl)
    AddRow({ name = ns.Text(tpl.name), items = ns.TemplateItems(tpl) })
end
S.groupRenameId = nil -- group whose header turns into an edit box on the next refresh (2026-11-11)

local function StartGroupRename(id)
    if not ns.GroupById(ns.profile, id) then return end
    GameTooltip:Hide()
    S.selectedGroup = id
    S.groupRenameId = id
    ns:RefreshOptions()
end


-- Deletes exactly this row (by table, so a dialog confirmed late cannot delete the wrong one)
local function DeleteRow(row)
    local rows = Rows()
    for i, r in ipairs(rows) do
        if r == row then
            table.remove(rows, i)
            S.selectedRow = math.max(1, math.min(S.selectedRow, #rows))
            Changed()
            return
        end
    end
end

-- StaticPopups are defined while the files load, before the language is known (Locale.lua): their text and
-- buttons hold English keys and are translated each time one is shown. Own button texts ("Yes", "No", "Cancel")
-- instead of Blizzard's YES/NO/CANCEL since 2026-11-15 (user): those follow the client language, not the addon's.
local popupKeys = {}
local function ShowStaticPopup(which, a1, a2, data)
    local d = StaticPopupDialogs[which]
    popupKeys[which] = popupKeys[which] or { text = d.text, button1 = d.button1, button2 = d.button2 }
    d.text = L[popupKeys[which].text]
    d.button1 = L[popupKeys[which].button1]
    d.button2 = popupKeys[which].button2 and L[popupKeys[which].button2] or nil
    return StaticPopup_Show(which, a1, a2, data)
end

StaticPopupDialogs["RAIDKITBUFFS_DELETE_ROW"] = {
    text = L["Delete this row with %d icons?"],
    button1 = L["Yes"],
    button2 = L["No"],
    OnAccept = function(_, row) DeleteRow(row) end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- "-" of a row line (2026-11-16, OptionsRowStack.lua): asks only if the row contains icons
local function AskDeleteRow(row)
    if not row then return end
    if #row.items == 0 then
        DeleteRow(row)
    else
        ShowStaticPopup("RAIDKITBUFFS_DELETE_ROW", #row.items, nil, row)
    end
end

-- "+ Gruppe" (2026-11-15, user): an empty group with the defaults of "Alle Gruppen" (no own frame/name values; the
-- selected row stays where it is). It gets no position entry, so the bar puts it diagonally next to the main group
-- towards the screen middle (NewGroupPoint in BarGroups.lua) and keeps that place once it has rows; while editing it
-- shows as a placeholder. In the list it comes last (RefreshRows); in the data groups with rows stay before the areas.
-- Since 2026-11-20 (user) "+" is a menu: "Empty group" or a preset (ns.GroupPresets: the default groups of a new
-- profile). A preset group gets the preset's name (localized, a number behind it if taken), its values and fresh copies
-- of its rows; its default place (Battle Shout: left of Buffs & Cons, at the end) only while that side is free.
local OPPOSITE = { bottom = "top", top = "bottom", left = "right", right = "left" }

-- may the new group snap to the end align of side of group target? (simplified SideTaken of BarMove.lua): beside the
-- target only that end must be free (a missing align counts as "start", B.SlotAlign); above/below the whole side
local function SideFree(prof, target, side, align)
    if not ns.GroupById(prof, target) then return false end
    local gp = type(prof.groupPos) == "table" and prof.groupPos or {}
    local vert = side == "bottom" or side == "top"
    for _, q in pairs(gp) do
        if type(q) == "table" and q.snap == target and q.side == side
            and (vert or (q.align or "start") == (align or "start")) then return false end
    end
    local own = gp[target]
    return not (type(own) == "table" and own.snap ~= nil and OPPOSITE[own.side] == side)
end

local function AddGroup(preset)
    if RowGroupCount() >= ns.MAX_GROUPS then
        ns:Print(L["At most %d groups with rows."], ns.MAX_GROUPS)
        return
    end
    local prof = ns.profile
    local function NameUsed(name)
        for _, g in ipairs(Groups()) do
            if g.name == name or ns.GroupDisplayName(g) == name then return true end
        end
        return false
    end
    local name
    if preset then
        name = L[preset.name]
        local n = 2
        while NameUsed(name) do name = L[preset.name] .. " " .. n n = n + 1 end
    else
        local n = 2
        while NameUsed(L["Group %d"]:format(n)) do n = n + 1 end
        name = L["Group %d"]:format(n)
    end
    local id = 1
    while ns.GroupById(prof, "g" .. id) do id = id + 1 end
    local g = { id = "g" .. id, name = name, capTint = true } -- capTint on like the main group
    for k, v in pairs(preset and preset.values or {}) do g[k] = type(v) == "table" and CopyTable(v) or v end
    table.insert(prof.groups, RowGroupCount() + 1, g)
    if type(prof.groupPos) ~= "table" then prof.groupPos = {} end
    prof.groupPos[g.id] = nil
    if preset then
        if preset.snap and SideFree(prof, preset.snap, preset.side, preset.align) then
            prof.groupPos[g.id] = { snap = preset.snap, side = preset.side, align = preset.align }
        end
        local rows = Rows()
        for k, row in ipairs(ns.PresetRows(preset)) do
            if k <= MAX_GROUP_ROWS then
                row.group = g.id -- not cut: NormalizeGroups widens the group if a row needs more places (FitRowWidths)
                rows[#rows + 1] = row
            end
        end
        NormalizeGroups() -- rows in the order of the groups
    end
    S.selectedGroup = g.id
    Changed()
    if not preset then ns:Print(L["Add rows with \"+ Row\" or drag rows of another group onto it in the list."]) end
end

-- Deletes exactly this group (by table, like DeleteRow) together with its rows (user 2026-11-20; before they moved to the
-- main group): groups snapped to it take over its snap (or its free position), its position entry is removed. Main
-- group and areas stay.
-- "-" on "Buffs & Cons" (user 2026-11-20, since the presets can bring it back). The main group is the anchor of the
-- bar (its frame is the container, its place is profile.point, the areas hang on it), so it cannot just go: its rows
-- are deleted and the next group with rows moves into it (name as shown, values, rows), "main" takes that group's
-- current place on the screen, groups snapped to that group now hang on "main". Groups snapped to the old main group
-- stay on "main". Without another group the main group stays, empty and with default values.
local function DeleteMainGroup(mainG)
    local prof = ns.profile
    local rows = Rows()
    for i = #rows, 1, -1 do
        if (rows[i].group or "main") == "main" then table.remove(rows, i) end
    end
    if type(prof.groupPos) ~= "table" then prof.groupPos = {} end
    local positions = prof.groupPos
    local nextG
    for _, x in ipairs(prof.groups) do
        if x.id ~= "main" and not x.area then nextG = x break end
    end
    for k in pairs(mainG) do
        if k ~= "id" then mainG[k] = nil end
    end
    if not nextG then
        mainG.name, mainG.capTint = "Buffs & Cons", true
        ns:Print(L["The first group stays as the anchor of the bar; its rows and settings were removed."])
    else
        local name = ns.GroupDisplayName(nextG) -- a default name ("Battle Shout") would not be translated under "main"
        if ns.FreezeGroupPos and ns:FreezeGroupPos(nextG.id) then
            local q = positions[nextG.id]
            if type(q) == "table" and q.x and q.pt then prof.point = { q.pt, "UIParent", q.pt, q.x, q.y, "outline" } end
        end
        for k, v in pairs(nextG) do
            if k ~= "id" then mainG[k] = v end
        end
        mainG.name = name
        for _, r in ipairs(rows) do
            if r.group == nextG.id then r.group = "main" end
        end
        positions[nextG.id] = nil
        for _, o in pairs(positions) do
            if type(o) == "table" and o.snap == nextG.id then o.snap = "main" end
        end
        for i, x in ipairs(prof.groups) do
            if x == nextG then table.remove(prof.groups, i) break end
        end
    end
    positions.main = nil
    S.selectedRow = math.max(1, math.min(S.selectedRow, #rows))
    S.selectedGroup = "main"
    Changed()
end

local function DeleteGroup(g)
    local prof = ns.profile
    if g and g.id == "main" then return DeleteMainGroup(g) end
    if not g or g.area then return end
    local index
    for i, x in ipairs(prof.groups) do
        if x == g then index = i end
    end
    if not index then return end
    local positions = type(prof.groupPos) == "table" and prof.groupPos or {}
    local q = positions[g.id]
    -- its rows go with it (user 2026-11-20: no icons into other rows)
    local rows = Rows()
    for i = #rows, 1, -1 do
        if rows[i].group == g.id then table.remove(rows, i) end
    end
    S.selectedRow = math.max(1, math.min(S.selectedRow, #rows))
    for k, o in pairs(positions) do
        if type(o) == "table" and o.snap == g.id then
            if type(q) == "table" and q.snap then
                positions[k] = { snap = q.snap, side = o.side, align = o.align }
            elseif type(q) == "table" and q.x then
                positions[k] = { x = q.x, y = q.y, pt = q.pt } -- pt: stored corner (2026-11-14)
            else
                local pt = prof.point or {}
                -- same kind of point as the main group's (corner since 2026-11-14, before the centre), 280 to the right
                positions[k] = { x = (pt[4] or 0) + 280, y = pt[5] or 0, pt = pt[6] == "outline" and pt[1] or nil }
            end
        end
    end
    positions[g.id] = nil
    table.remove(prof.groups, index)
    S.selectedGroup = nil
    Changed()
end

StaticPopupDialogs["RAIDKITBUFFS_DELETE_GROUP"] = {
    text = L["Delete group \"%s\" together with its %d rows?"],
    button1 = L["Yes"],
    button2 = L["No"],
    OnAccept = function(_, g) DeleteGroup(g) end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}


-- Warning before hiding "Sonstige Buffs" / "Debuffs" with the eye (user 2026-11-12: every time, not recommended).
-- Texts chosen by the user; plain quotes only (in-game texts are Latin-1).
local function HideAreaGroup(g)
    g.hidden = true
    Changed()
end
StaticPopupDialogs["RAIDKITBUFFS_HIDE_OTHER"] = {
    text = L["Hide \"Other Buffs\"?\n\nYou will no longer see buffs that are not in any row: procs, HoTs, trinkets and buffs from others. As long as RaidKit Buffs replaces the Blizzard bar, they show up nowhere.\n\nNot recommended. Only hide them if another addon shows them."],
    button1 = L["Hide anyway"],
    button2 = L["Cancel"],
    OnAccept = function(_, g) HideAreaGroup(g) end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
StaticPopupDialogs["RAIDKITBUFFS_HIDE_DEBUFF"] = {
    text = L["Hide \"Debuffs\"?\n\nAs long as RaidKit Buffs replaces the Blizzard bar, you will no longer see any debuffs on yourself, not even curses, poisons or boss debuffs.\n\nNot recommended. Only hide them if another addon shows them."],
    button1 = L["Hide anyway"],
    button2 = L["Cancel"],
    OnAccept = function(_, g) HideAreaGroup(g) end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
local AREA_HIDE_POPUP = { other = "RAIDKITBUFFS_HIDE_OTHER", debuff = "RAIDKITBUFFS_HIDE_DEBUFF" }

local function AskDeleteGroup()
    local g = CurGroup()
    if not g then return end
    if g.area then
        ns:Print(L["This area cannot be deleted, only moved."])
        return
    end
    local n = 0
    for _, r in ipairs(Rows()) do
        if (r.group or "main") == g.id then n = n + 1 end
    end
    if n == 0 then
        DeleteGroup(g)
    else
        ShowStaticPopup("RAIDKITBUFFS_DELETE_GROUP", GroupName(g), n, g)
    end
end

-- A row dragged by its grip onto a group in the list (2026-11-16, OptionsRowStack.lua): to the end of that group, if it
-- fits (places per row, MAX_GROUP_ROWS). Buff areas take no rows.
local function MoveRowToGroup(r, g)
    if g.area then
        ns:Print(L["This area takes no rows."])
        ns:RefreshOptions()
        return
    end
    if g.id == (r.group or "main") then
        ns:RefreshOptions()
        return
    end
    local fail
    if ns.RowNeed(r) > ns.GroupWidth(g) then
        fail = L["Does not fit: the row needs %d places, group \"%s\" has %d per row."]:format(ns.RowNeed(r), GroupName(g), ns.GroupWidth(g))
    elseif #O.GroupRows(g) >= MAX_GROUP_ROWS then
        fail = L["At most %d rows per group."]:format(MAX_GROUP_ROWS)
    end
    if fail then
        ns:Print(fail)
        ns:RefreshOptions()
        return
    end
    local rows = Rows()
    for i, x in ipairs(rows) do
        if x == r then table.remove(rows, i) break end
    end
    r.group = g.id
    rows[#rows + 1] = r -- NormalizeGroups puts it last in its group (stable sort)
    ns:Print(L["Row moved to \"%s\"."], GroupName(g))
    Changed()
end
-- shared with the other options files (ns.Opt)
O.CurrentRow, O.Groups, O.CurGroup, O.GroupName = CurrentRow, Groups, CurGroup, GroupName
O.RowGroupCount, O.NormalizeGroups, O.RowIndexOf = RowGroupCount, NormalizeGroups, RowIndexOf
O.TakeFromRow, O.InsertItem, O.RemoveAt, O.MoveTo = TakeFromRow, InsertItem, RemoveAt, MoveTo
O.AddFromCursor, O.AddEmptyRow, O.AddTemplateRow = AddFromCursor, AddEmptyRow, AddTemplateRow
O.StartGroupRename, O.ShowStaticPopup, O.AskDeleteRow, O.MoveRowTo = StartGroupRename, ShowStaticPopup, AskDeleteRow, MoveRowTo
O.AddGroup, O.AREA_HIDE_POPUP, O.AskDeleteGroup, O.MoveRowToGroup = AddGroup, AREA_HIDE_POPUP, AskDeleteGroup, MoveRowToGroup
