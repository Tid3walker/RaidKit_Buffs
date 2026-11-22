-- RaidKit Buffs: Bar - split rows and the width of a group's rows (2026-11-16, user; mockup js/bar-split.js)
-- Replaces the split groups of 2026-11-15: every row of a group can be "split" (separator choice of a row line, 2026-11-17; before the option "Split row").
-- "Per line" of the group (or "All Groups") is the most icons a row of the group holds, 20 = the maximum; a split row
-- holds as many as a normal one (since session 20; before one place was the separator). Rows never wrap (only Other
-- and Debuffs do; Unwanted grows sideways as before), a row has no own size.
-- Width on the bar (session 20, user): a normal row is as long as its icons; a split row spans the widest row of the
-- group (left half from the left edge, right half from the right edge, the rest stays free in the middle). Its own
-- length is its icons plus the gap of its separator, so a full split row makes the group that much wider. In the
-- options the separator is a yellow line (OptionsRowStack.lua, it can be dragged). On the bar it is the gap, since
-- 2026-11-17 (user) with a look of its own per row (SEP_KINDS: a dash, a line, a dot, an icon-wide gap ...), drawn in
-- the middle of the free space between the halves.
-- Data: row.split = number of icons in the left half (nil = normal row); row.sepStyle = look of the separator on the
-- bar (nil = "gap", the plain gap of session 20, so older split rows look the same). Row names are not shown since
-- 2026-11-16.
-- Shared names between the Bar*.lua files: Docs/Architecture.md "Leiste: Aufteilung in Dateien".

local _, ns = ...
local B = ns.Bar

local ROW_MAX = 20
local SPLIT_GAP = 10 -- smallest extra gap between the halves of a split row on the bar (= mockup)
ns.ROW_MAX = ROW_MAX

-- = SEP_KINDS in the mockup (2026-11-17, user): the looks of the separator, in the order of the menu. "none" = not
-- split. mini = small drawing in the box of a row line and in the menu, { x, y, w, h } around its centre, at most 24 px
-- wide (gold; second in-game test, user: instead of the text symbols, "|" had to be written "||" there). marks(size) =
-- the pieces drawn on the bar as { x, y, w, h } around the centre of the gap; pad = free px left and right of the
-- marks (default 4; the dot 10 since the first in-game test, user: "more room left and right"); places = the gap is
-- that many empty icon places (+ mid px), no pad then. Line and double line were removed in the fourth in-game test
-- (user) for the dot variants dotIcon "[.]", dotPair "[].[]" and dotWide "[ ] . [ ]"; a stored "line" / "line2" is
-- unknown now and shows as "gap".
-- Lines (fifth in-game test, user; instead of "Dash" and "Two dashes"): gapOf = the gap is the one of that look (each
-- line as wide as the matching dot, the user: line plus room left and right = the dot), marks(size, spacing) = a 2 px
-- line across that gap with 8 px to the icons (4 until the sixth in-game test, user: "a little more room"). The key "dash" stays for the short "Line", so a stored dash becomes
-- it; "dash2" is unknown now and shows as "gap".
local function Round(v) return math.floor(v + 0.5) end
local SepGap -- defined below (LineMarks uses it)
-- = lineMarks in the mockup: a horizontal line across the smallest gap of look key (free room = spacing + gap)
local function LineMarks(key)
    return function(s, spacing)
        local w = spacing + SepGap(key, s, spacing) - 16
        return { { -w / 2, -1, w, 2 } }
    end
end
local SEP_KINDS = {
    { key = "none", mini = {}, label = "None" },
    { key = "gap", mini = { { -4, -4, 1, 8 }, { -6, -4, 2, 1 }, { -6, 3, 2, 1 }, { 3, -4, 1, 8 }, { 4, -4, 2, 1 }, { 4, 3, 2, 1 } }, label = "Gap" },
    { key = "icon", mini = { { -5, -5, 10, 1 }, { -5, 4, 10, 1 }, { -5, -4, 1, 8 }, { 4, -4, 1, 8 } }, label = "Gap (1 place)", places = 1 },
    { key = "dot", mini = { { -2, -2, 4, 4 } }, label = "Dot", pad = 10, marks = function() return { { -2, -2, 4, 4 } } end },
    { key = "dotIcon", mini = { { -5, -5, 10, 1 }, { -5, 4, 10, 1 }, { -5, -4, 1, 8 }, { 4, -4, 1, 8 }, { -1, -1, 2, 2 } }, label = "Dot (1 place)", places = 1,
        marks = function() return { { -2, -2, 4, 4 } } end },
    { key = "dotPair", mini = { { -9, -3, 6, 1 }, { -9, 2, 6, 1 }, { -9, -2, 1, 4 }, { -4, -2, 1, 4 }, { -1, -1, 2, 2 }, { 3, -3, 6, 1 }, { 3, 2, 6, 1 }, { 3, -2, 1, 4 }, { 8, -2, 1, 4 } }, label = "Dot (2 places)", places = 2, mid = 12,
        marks = function() return { { -2, -2, 4, 4 } } end },
    { key = "dotWide", mini = { { -12, -3, 6, 1 }, { -12, 2, 6, 1 }, { -12, -2, 1, 4 }, { -7, -2, 1, 4 }, { -1, -1, 2, 2 }, { 6, -3, 6, 1 }, { 6, 2, 6, 1 }, { 6, -2, 1, 4 }, { 11, -2, 1, 4 } }, label = "Dot (3 places)", places = 3,
        marks = function() return { { -2, -2, 4, 4 } } end },
    { key = "dash", mini = { { -4, -1, 8, 2 } }, label = "Line", gapOf = "dot", marks = LineMarks("dash") },
    { key = "hline1", mini = { { -6, -1, 12, 2 } }, label = "Line (1 place)", gapOf = "dotIcon", marks = LineMarks("hline1") },
    { key = "hline2", mini = { { -9, -1, 18, 2 } }, label = "Line (2 places)", gapOf = "dotPair", marks = LineMarks("hline2") },
    { key = "hline3", mini = { { -12, -1, 24, 2 } }, label = "Line (3 places)", gapOf = "dotWide", marks = LineMarks("hline3") },
}
local SEP_BY_KEY = {}
for _, k in ipairs(SEP_KINDS) do SEP_BY_KEY[k.key] = k end
ns.SEP_KINDS, ns.SEP_BY_KEY = SEP_KINDS, SEP_BY_KEY
local SEP_R, SEP_G, SEP_B, SEP_A = 0.78, 0.78, 0.82, 0.85 -- = SEP_COLOR in the mockup

-- most icons of a row for a "Per line" value (0 or 20 = 20)
function ns.WidthOf(perLine)
    perLine = tonumber(perLine) or 0
    if perLine > 0 and perLine < ROW_MAX then return math.floor(perLine) end
    return ROW_MAX
end

-- most icons of every row of group g (prof = profile, default the own settings)
function ns.GroupWidth(g, prof)
    return ns.WidthOf(ns.GEff(g, "perLine", prof))
end

-- group of a row (nil while there is no profile)
function ns.RowGroupOf(row)
    return ns.profile and row and ns.GroupById(ns.profile, row.group or "main") or nil
end

function ns.IsSplitRow(row)
    return type(row) == "table" and not row.unwanted and row.split ~= nil
end

-- = ROW_ALIGNS in the mockup (2026-11-18, user): alignment of one row, chosen in the separator menu. "left" / "right":
-- the whole row at that edge of the group, a split row only as wide as its icons plus the gap of its separator; "both":
-- a split row spans the widest row of the group (left half from the left, right half from the right; the look before
-- 2026-11-18). row.align nil = a split row "both", a normal row "right" (until the same day like "Icons:" of its
-- group, which groups with rows no longer have; MigrateRowAlign in Core.lua); a normal row never "both".
-- mini = drawing in the menu, bar = marks along the bottom of the row's separator box ({ x, y, w, h } around the centre)
local ROW_ALIGNS = {
    { key = "left", label = "Left", mini = { { -13, -4, 7, 8 }, { -5, -4, 7, 8 } }, bar = { { -12, 6, 10, 1 } } },
    { key = "right", label = "Right", mini = { { -2, -4, 7, 8 }, { 6, -4, 7, 8 } }, bar = { { 2, 6, 10, 1 } } },
    { key = "both", label = "Both sides", mini = { { -13, -4, 7, 8 }, { 6, -4, 7, 8 } }, bar = { { -12, 6, 6, 1 }, { 6, 6, 6, 1 } } },
}
local ROW_ALIGN_BY_KEY = {}
for _, a in ipairs(ROW_ALIGNS) do ROW_ALIGN_BY_KEY[a.key] = a end
ns.ROW_ALIGNS, ns.ROW_ALIGN_BY_KEY = ROW_ALIGNS, ROW_ALIGN_BY_KEY

-- effective alignment of a row
function ns.RowAlign(row)
    local a = row and ROW_ALIGN_BY_KEY[row.align or ""] and row.align or nil
    if ns.IsSplitRow(row) then return a or "both" end
    if a and a ~= "both" then return a end
    return "right"
end

-- = rowsAlignRight in the mockup: the corner a group with rows grows away from and how a group docked above or below it
-- lines up (2026-11-18, before "Icons:" of the group): left only when every row stands left
function B.RowsAlignRight(rows)
    for _, r in ipairs(rows) do
        if ns.RowAlign(r) ~= "left" then return true end
    end
    return #rows == 0
end

-- number of icons in the left half
function ns.RowSplit(row)
    local n = #row.items
    local s = tonumber(row.split) or n
    return math.max(0, math.min(n, s))
end

-- look of the separator of a row: "none" for a normal row, else its sepStyle (unknown or nil = "gap")
function ns.RowSepStyle(row)
    if not ns.IsSplitRow(row) then return "none" end
    local s = row.sepStyle
    return (s and s ~= "none" and SEP_BY_KEY[s]) and s or "gap"
end

-- places a row needs (split or not, since session 20)
function ns.RowNeed(row)
    return #row.items
end

-- = sepGap in the mockup: extra room between the halves for a look (on top of the normal spacing): k.places empty icon
-- places (+ k.mid), else the marks plus its pad on each side, at least SPLIT_GAP
function SepGap(style, size, spacing)
    local k = SEP_BY_KEY[style]
    if k and k.gapOf then return SepGap(k.gapOf, size, spacing) end
    if k and k.places then return k.places * (size + spacing) + (k.mid or 0) end
    local lo, hi
    for _, m in ipairs(k and k.marks and k.marks(size, spacing) or {}) do
        lo, hi = math.min(lo or m[1], m[1]), math.max(hi or (m[1] + m[3]), m[1] + m[3])
    end
    return math.max(SPLIT_GAP, lo and (math.ceil(hi - lo) + 2 * (k.pad or 4)) or 0)
end

-- = rowLength in the mockup: own length of a row on the bar (a split row: its icons plus the gap of its look);
-- BuildGroup stretches every split row to the widest row of the group afterwards
function B.RowLength(rowData, size, spacing)
    local extra = ns.IsSplitRow(rowData) and SepGap(ns.RowSepStyle(rowData), size, spacing) or 0
    return math.max(#rowData.items * (size + spacing) - spacing + extra, size)
end

-- pieces of the separators on a group frame f (textures, created when needed): BuildGroup hides them first
function B.ClearSplitMarks(f)
    f.rsepUsed = 0
    for _, t in ipairs(f.rseps or {}) do t:Hide() end
end

local function SplitMark(f, x, y, w, h)
    f.rseps = f.rseps or {}
    f.rsepUsed = (f.rsepUsed or 0) + 1
    local t = f.rseps[f.rsepUsed]
    if not t then
        t = f:CreateTexture(nil, "ARTWORK")
        t:SetColorTexture(SEP_R, SEP_G, SEP_B, SEP_A)
        f.rseps[f.rsepUsed] = t
    end
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", f, "TOPLEFT", x, -y)
    t:SetSize(w, h)
    t:Show()
end

-- most places one row of group g needs (the width cannot go below it, user 2026-11-16)
function ns.GroupNeed(p, g)
    local n = 0
    for _, r in ipairs(p.rows or {}) do
        if (r.group or "main") == g.id then n = math.max(n, ns.RowNeed(r)) end
    end
    return n
end

-- = placeSplitRow in the mockup: icons of one split row (BuildGroup in Bar.lua), rowW px wide, x0 = left edge of the
-- row. PlaceButton(entry, x, y, size) from BuildGroup. No names since 2026-11-16 (user: only group names stay; before a
-- name per half, row.nameR, in f.labelsR). The separator (2026-11-17): its pieces in the middle of the free space
-- between the halves, vertically in the middle of the icons, as textures of the group frame f.
local function PlaceSplitRow(f, rowData, x0, y, size, spacing, rowW, PlaceButton)
    local n, s = #rowData.items, ns.RowSplit(rowData)
    for i, entry in ipairs(rowData.items) do
        local x
        if i <= s then x = (i - 1) * (size + spacing) else x = rowW - (n - i + 1) * (size + spacing) + spacing end
        PlaceButton(entry, x0 + x, y, size)
    end
    local k = SEP_BY_KEY[ns.RowSepStyle(rowData)]
    if not k or not k.marks then return end
    local a = s > 0 and (x0 + s * (size + spacing) - spacing) or x0
    local b = n > s and (x0 + rowW - (n - s) * (size + spacing) + spacing) or (x0 + rowW)
    local cx, cy = Round((a + b) / 2), y + Round(size / 2)
    for _, m in ipairs(k.marks(size, spacing)) do SplitMark(f, cx + Round(m[1]), cy + Round(m[2]), m[3], Round(m[4])) end
end
-- shared with the other Bar*.lua files
B.PlaceSplitRow = PlaceSplitRow
