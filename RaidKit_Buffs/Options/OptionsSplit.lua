-- RaidKit Buffs: Options - split rows: separator choice of a row (2026-11-17; before the option "Split row"), width rules for the rows of a group (2026-11-16, user; mockup
-- js/options-split.js). Replaces the split groups of 2026-11-15. Data model and bar layout: BarSplit.lua. The grid of a
-- split row: OptionsRowStack.lua (the rows of a group on its Layout tab).
-- - Every row line of a group has the choice of the separator (OptionsRowStack.lua; 2026-11-16 to 2026-11-17 the
--   checkbox "Split row"): "None" = a normal row, any look = split (SetRowSep). Splitting: the
--   separator starts in the middle of the icons (odd number: the left half gets one more), session 20, user; before
--   every icon started left. It is a yellow line between the icons, so the row keeps all its places (before one place
--   was the separator X), and it can be dragged with the mouse. Off: both halves become one row again (left, then
--   right).
-- - "Per line" of a group (and of "All Groups") is the most icons a row of the group holds. It cannot go below what a
--   row of the group needs (message, the change is refused).
-- - A row that does not fit cannot be dragged into a group; a template longer than the group's rows is cut.
-- O = ns.Opt (shared functions and constants), S = ns.OptState (shared state), see OptionsBase.lua.

local _, ns = ...
local L = ns.L
local O = ns.Opt
local Changed = O.Changed

-- how many icons fit into a row: the places of its group (split or not, since session 20)
local function RowCap(row)
    return ns.GroupWidth(ns.RowGroupOf(row))
end

-- message for a full row
local function PrintRowFull(row)
    local g = ns.RowGroupOf(row)
    ns:Print(L["The row is full: group \"%s\" has %d places per row."], O.GroupName(g), ns.GroupWidth(g))
end

-- = setRowSplit in the mockup
local function SetRowSplit(row, on)
    if not row or row.unwanted or on == ns.IsSplitRow(row) then return end
    -- off keeps the place of the separator in row.splitOff, on brings it back (2026-11-16, user); first time: middle
    if on then
        -- the row keeps its alignment (2026-11-18, user): without an own choice a split row would become "both"
        if row.align == nil then row.align = ns.RowAlign(row) end
        local s = tonumber(row.splitOff) or math.ceil(#row.items / 2) -- separator in the middle (session 20, user)
        row.split, row.splitOff = math.max(0, math.min(#row.items, math.floor(s))), nil
    else
        row.split, row.splitOff = nil, row.split
    end
    Changed()
end

-- = setRowSep in the mockup (2026-11-17, user; replaces the checkbox "Split row"): the choice of a row line. "none" = a
-- normal row (like the checkbox off), any other look splits the row (like on) and keeps the look in row.sepStyle
-- ("gap", the look of session 20, is not stored)
local function SetRowSep(row, key)
    if not row or row.unwanted then return end
    if key == "none" then return SetRowSplit(row, false) end
    row.sepStyle = key ~= "gap" and key or nil
    if not ns.IsSplitRow(row) then SetRowSplit(row, true) else Changed() end
end

-- = setRowAlign in the mockup (2026-11-18, user): alignment of a row (BarSplit.lua ROW_ALIGNS), always stored once
-- chosen; "both" only for a split row
local function SetRowAlign(row, key)
    if not row or row.unwanted or not ns.ROW_ALIGN_BY_KEY[key] or (key == "both" and not ns.IsSplitRow(row)) then return end
    row.align = key
    Changed()
end

-- = widthOk in the mockup: may "Per line" of group g (nil = "All Groups") become v? Refuses with a message when a row
-- would not fit any more (user 2026-11-16).
local function WidthOK(g, v)
    local W = ns.WidthOf(v)
    local list = {}
    if g then
        list[1] = g
    else
        for _, x in ipairs(ns.profile.groups) do
            if not x.area and x.perLine == nil then list[#list + 1] = x end
        end
    end
    for _, x in ipairs(list) do
        local n = ns.GroupNeed(ns.profile, x)
        if n > W then
            ns:Print(L["Too narrow: a row of group \"%s\" needs %d places."], O.GroupName(x), n)
            ns:RefreshOptions()
            return false
        end
    end
    return true
end

-- a row added to group g (template, copy): cut to its places with a message
local function FitRow(row, g)
    local cap = ns.GroupWidth(g)
    if #row.items <= cap then return end
    local names = {}
    while #row.items > cap do
        local e = table.remove(row.items, cap + 1)
        names[#names + 1] = O.ItemName(ns.EntryMain(e))
    end
    if row.split then row.split = math.min(row.split, cap) end
    ns:Print(L["Only %d icons fit in a row of group \"%s\", left out: %s"], cap, O.GroupName(g), table.concat(names, ", "))
end

-- group g takes rows from elsewhere (a deleted group): it gets wider if one of them needs more places
local function WidenFor(g)
    local n = ns.GroupNeed(ns.profile, g)
    if n <= ns.GroupWidth(g) then return end
    g.perLine = n >= ns.ROW_MAX and 0 or n
    ns:Print(L["Group \"%s\" now has %d places per row."], O.GroupName(g), n)
end

-- Runs fn (a change of the row) and puts the icon id into the given half ("L" / "R"); the order inside each half is
-- kept. Halves are told apart by the main id of every icon, so they survive whatever fn moves.
local function SplitDo(row, side, id, fn)
    local left = {}
    for i = 1, ns.RowSplit(row) do left[ns.EntryMain(row.items[i])] = true end
    fn()
    if id ~= nil then left[id] = side == "L" or nil end
    local lefts, rights = {}, {}
    for _, e in ipairs(row.items) do
        if left[ns.EntryMain(e)] then lefts[#lefts + 1] = e else rights[#rights + 1] = e end
    end
    wipe(row.items)
    for _, e in ipairs(lefts) do row.items[#row.items + 1] = e end
    for _, e in ipairs(rights) do row.items[#row.items + 1] = e end
    row.split = #lefts
    Changed()
end

-- removes icon i of a row; a removed left icon makes the left half one shorter
local function SpliceItem(row, i)
    local e = table.remove(row.items, i)
    if row.split and i <= row.split then row.split = row.split - 1 end
    return e
end

-- shared with the other options files (ns.Opt)
O.RowCap, O.PrintRowFull, O.SetRowSplit, O.SetRowSep, O.WidthOK = RowCap, PrintRowFull, SetRowSplit, SetRowSep, WidthOK
O.SetRowAlign = SetRowAlign
O.FitRow, O.WidenFor, O.SplitDo, O.SpliceItem = FitRow, WidenFor, SplitDo, SpliceItem
