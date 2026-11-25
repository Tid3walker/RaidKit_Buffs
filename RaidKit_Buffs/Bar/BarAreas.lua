-- RaidKit Buffs: BarAreas
-- The buff areas below the bar ("Unwanted Buffs", "Other Buffs", "Debuffs"): sizes, names, cap tint,
-- timers, previews, measuring and UpdateExtra.
-- Shared names between the Bar*.lua files: Docs/Architecture.md "Leiste: Aufteilung in Dateien".

local _, ns = ...
local L = ns.L
local B, BS = ns.Bar, ns.BarState
local activeButtons, groupFrames, areaFrames = B.activeButtons, B.groupFrames, B.areaFrames
local shownGroups, WEAPON_SLOT, SetTimer = B.shownGroups, B.WEAPON_SLOT, B.SetTimer
local CatalogDuration, FRAME_PAD = B.CatalogDuration, B.FRAME_PAD
local UpdatePreview -- defined further down

------------------------------------------------------------------------
-- Area below the bar (proposal 2026-11-09, mockup: renderExtras / buildOtherPreview)
--   the bar's background tint by free buff slots (CapLevel, 2026-11-10) and the "Buff counter" in a row (2026-11-25)
--   red unwanted button (secure macro "/cancelaura ...", works in combat). It is always shown (Show/Hide
--   of a secure frame is impossible in combat) and only made visible with SetAlpha while an unwanted
--   buff is active; a click without active unwanted buffs does nothing.
--   "Sonstige": every active buff that no visible row shows, plain frames (no secure buttons), so they
--   may change in combat. Right-click removes a buff out of combat (CancelUnitBuff).
--   preview: placeholders for the maximum size, shown together with the Shift outline
-- The area is anchored below the bar and does not count into its size: the rows never move.
------------------------------------------------------------------------

-- Warning steps by free buff slots (user 2026-11-10, replaces the slider "Proc-Reserve"): 5 or more free =
-- no tint; 4 yellow, 3 light orange, 2 orange, 1 soft red, 0 (full) red. bg = background of the bar
-- (capTint, same box as the outline), text = colour of the counter. Same as CAP_LEVELS in the mockup.
local CAP_LEVELS = {
    [4] = { bg = { 1, 0.82, 0, 0.14 },    text = { 1, 0.82, 0 } },
    [3] = { bg = { 1, 0.65, 0.16, 0.17 }, text = { 1, 0.69, 0.19 } },
    [2] = { bg = { 1, 0.45, 0.08, 0.20 }, text = { 1, 0.54, 0.12 } },
    [1] = { bg = { 1, 0.24, 0.18, 0.22 }, text = { 1, 0.35, 0.27 } },
    [0] = { bg = { 1, 0.12, 0.12, 0.32 }, text = { 1, 0.19, 0.19 } },
}
B.CapLevel = function(free)
    if free > 4 then return nil end
    return CAP_LEVELS[math.max(free, 0)]
end

-- buff slots in use right now, demo buffs included (= the bar's tint and the buff counter; capFreeNow in the mockup)
local function BuffsUsed()
    local demo = ns.demo
    return #ns.auraList + (demo and (#demo.buffs + demo.nRows) or 0)
end
B.BuffsUsed = BuffsUsed

-- "Buff counter" in a row (user 2026-11-25, = updateCounterButton in the mockup; replaces the hidden counter
-- "Buffs n/32" of session 4b..4c and the line on "Info"): the USED buff slots as a big number in the colour of the tint
-- (white up to 27, then CAP_LEVELS), without icon and border. Never grey, no timer, bag count, cooldown or status mark;
-- no secure action (UpdateSecure finds no own spell, CancelMacro returns nil). Plain widgets only: allowed in combat.
B.UpdateCounterButton = function(btn)
    local used = BuffsUsed()
    local lv = B.CapLevel(ns.BUFF_CAP - used)
    btn.itemID = ns.EntryPick(btn.entry)
    btn.isActive, btn.expiration, btn.bagCount, btn.activeID, btn.isDemo, btn.blinking = true, nil, 0, nil, false, false
    btn.icon:Hide()
    btn.border:SetColorTexture(0, 0, 0, 0)
    btn.status:Hide()
    btn.count:Hide()
    btn.cooldown:Clear()
    btn.timer:SetText("")
    local t = btn.capText
    if not t then
        t = btn.count:GetParent():CreateFontString(nil, "OVERLAY")
        t:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btn.capText = t
    end
    local size = math.floor((btn:GetHeight() or 0) * 0.55 + 0.5)
    if size < 8 then size = 16 end
    if btn.capTextSize ~= size then
        t:SetFont(STANDARD_TEXT_FONT, size, "OUTLINE")
        btn.capTextSize = size
    end
    t:SetText(used)
    if lv then t:SetTextColor(unpack(lv.text)) else t:SetTextColor(1, 1, 1) end
    t:Show()
end

-- tooltip of the buff counter (before: of the counter "Buffs n/32"): slots, free, buffs no row shows
B.ShowCounterTip = function(owner)
    local cap = ns.BUFF_CAP
    local n = BuffsUsed()
    local free = cap - n
    GameTooltip:SetOwner(owner, "ANCHOR_BOTTOMLEFT")
    GameTooltip:SetText(L["Buff slots: %d of %d"]:format(n, cap))
    local lv = B.CapLevel(free)
    if free > 0 then GameTooltip:AddLine(L["%d free"]:format(free), lv and lv.text[1] or 0.2, lv and lv.text[2] or 1, lv and lv.text[3] or 0.2)
    else GameTooltip:AddLine(L["Full - the next buff pushes out another one"], 1, 0.3, 0.3, true) end
    GameTooltip:AddLine(L["From 4 free slots on the bar is tinted: yellow, orange, red at 1."], 0.6, 0.6, 0.6, true)
    GameTooltip:AddLine(L["RaidKit Buffs does not see invisible buffs (some enchants, set bonuses)."], 0.6, 0.6, 0.6, true)
    local covered, first = B.CoveredSet(), true
    for _, au in ipairs(ns.auraList) do
        if not covered[au.spellId] and not covered[au.name] then
            if first then GameTooltip:AddLine(" ") GameTooltip:AddLine(L["Not in a row:"], 1, 1, 1) first = false end
            GameTooltip:AddLine(au.name or "?", 0.6, 0.6, 0.6)
        end
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["Shift+drag: move bar"], 0.6, 0.6, 0.6)
    GameTooltip:AddLine(L["Shift+right-click: options"], 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

local OTHER_TOP = 0 -- icons of "Sonstige" start at the top (session 4b: the counter moved to the main group)
local otherPool = {}

-- Position inside the area being drawn (extra), measured from its top-left corner: mirrored when the area is
-- right-aligned (box.alignR). Same as placeX() in the mockup. (Growing upwards is gone since the areas are
-- groups, 2026-11-11: snapped above a group they grow upwards by themselves, the bottom edge stays.)
local function PlaceX(frame, x, y, box)
    box = box or BS.extra
    local corner = "TOP" .. (box.alignR and "RIGHT" or "LEFT")
    frame:ClearAllPoints()
    frame:SetPoint(corner, box, corner, box.alignR and -x or x, -y)
end

-- Size of an area group ("unw" / "other" / "debuff"). Since 2026-11-12 (user: everything like the other groups) the
-- same "Eigene Größe" as every group: on = the group's iconSize, spacing, scale, perLine, rowSpacing (effective size =
-- size * scale like ns:RowLayout), off = the values of "Alle Gruppen" (the area frame already has the bar's scale).
-- Before: own profile keys other*/debuff* (2026-11-10), "Unerwünschte" like "Sonstige" (moved over by ns.EnsureGroups).
-- rowSpacing = gap between the area's lines, like the gap between two rows.
-- Since 2026-11-14 (user) every value on its own (ns.GEff: group value or "Alle Gruppen"). The area frame already has
-- the scale of "Alle Gruppen", so an own scale counts relative to it: effective scale = the value shown in the options
-- (before it came on top of the bar's scale; ns.EnsureGroups converted old values once).
local function AreaLayout(id)
    local p = ns.profile
    local g = ns.GroupById(p, id)
    local E = ns.GEff
    local sc = E(g, "scale") or 1 -- the area frame is not scaled any more (no "Alle Gruppen" since session 20)
    return (E(g, "iconSize") or 30) * sc, (E(g, "spacing") or 4) * sc, (E(g, "rowSpacing") or 4) * sc, E(g, "perLine") or 0
end

-- group an area hangs on above/below (directly or through areas that are not built), or nil
local function AreaAnchor(id)
    local seen = {}
    local q = B.GroupPos(id)
    while q and q.snap and not seen[q.snap] do
        seen[q.snap] = true
        if q.side ~= "bottom" and q.side ~= "top" then return nil end
        local f = groupFrames[q.snap]
        if f and f.built then return f end
        for _, af in pairs(areaFrames) do
            if af.g and af.g.id == q.snap then return af end
        end
        q = B.GroupPos(q.snap)
    end
end

-- Orientation of an area group (2026-11-11, user: like the row groups). nil = "automatisch": rows, aligned like the
-- group it hangs on (as before); hleft/hright = rows from the left/right. Columns were removed 2026-11-14 (user).
-- = areaSlot / areaExtent in the mockup

-- room below an area icon for its timer: 0 since 2026-11-12 (user: the time sits inside the icon like with the rows;
-- before 10 px below every icon line)
local AREA_TIMER_H = 0

-- position of icon i (1-based) of n in the area f: x from its corner (PlaceX mirrors it when right-aligned), y from
-- top. lineH = size + AREA_TIMER_H + rowSpacing (OtherSize); along a line the step is size + sp.
local function AreaSlot(f, i, n, per, size, sp, lineH)
    local k = (i - 1) % per
    return k * (size + sp), math.floor((i - 1) / per) * lineH
end

-- width, height and lines (rows of icons, for names below) that n icons (n >= 1) take in the area f
local function AreaExtent(f, n, per, size, sp, lineH)
    local rs = lineH - size - AREA_TIMER_H
    local lines = math.ceil(n / per)
    return math.min(n, per) * (size + sp) - sp, lines * lineH - rs, lines
end

-- Icon size, spacing, icons per line and line height of an area (kind nil = "other", "unw", "debuff"; areaId = its
-- group, the same). Snapped above or below a group the lines are at most as wide as that group (2026-11-11), so they
-- end flush with it; free or beside a group only "Pro Zeile" counts ("alle" = 10 then). At least 4 per line.
local function OtherSize(kind, areaId)
    local p = ns.profile
    local id = areaId or kind or "other"
    local size, sp, rs, per = AreaLayout(id)
    if per == 0 then per = 99 end -- 0 = "alle" (2026-11-10): as many as fit into the width
    local anchor = AreaAnchor(id)
    local width
    if anchor then
        -- in this area's own units (the anchor may have another scale)
        local aw = anchor.area and anchor.width or anchor:GetWidth()
        width = aw and aw * anchor:GetScale()
    end
    if width then
        local fit = math.floor((width + sp + 0.5) / (size + sp)) -- +0.5: float widths
        per = math.max(math.min(per, fit), 4)
    elseif per == 99 then
        per = 10
    end
    return size, sp, per, size + AREA_TIMER_H + rs
end

-- "Sonstige Buffs" and "Debuffs" behave like self-wrapping rows with names (user 2026-11-09).
-- Same as placeAbs / namesAbove / nameSide / counterSide / placeName in the mockup.
local DEBUFF_GAP_ABOVE = 12 -- NAME_GAP: room for the name of the debuffs when names sit above
local DEB_GAP = 0           -- top of the debuff area to the icons; 4 until 2026-11-14 (room below the old divider)

-- Position from the left or right edge of the area (side "LEFT" / "RIGHT"), y from its top.
local function PlaceAbs(frame, side, x, y)
    local corner = "TOP" .. side
    frame:ClearAllPoints()
    frame:SetPoint(corner, BS.extra, corner, side == "RIGHT" and -x or x, -y)
end

local function NamesAbove() return BS.extra.namePos ~= nil and BS.extra.namePos:find("^top") ~= nil end
local function NameSide() return BS.extra.namePos and BS.extra.namePos:find("right$") and "RIGHT" or "LEFT" end
local function DebuffGap() return NamesAbove() and DEBUFF_GAP_ABOVE or 0 end

-- Name of a wrapping row whose lines start at y0 and take n lines. A line is the icon plus the timer
-- below it. boxW (2026-11-11, row "Unerwünschte Buffs"): the row is a framed button only boxW wide; its name
-- keeps clear of the frame (4 px further out) and ends at the button's edge, never sticking out of the area.
local function PlaceName(label, y0, n, lineH, size, boxW)
    local pos = BS.extra.namePos
    local pad, x = boxW and 4 or 0, 0
    if pos == "topcenter" then
        -- centred over the area, or over the button of "Unerwünschte Buffs" (2026-11-15, = placeName in the mockup)
        local w = BS.extra.width
        local cx = boxW and (BS.extra.alignR and w - boxW / 2 or boxW / 2) or w / 2
        label:ClearAllPoints()
        label:SetPoint("BOTTOM", BS.extra, "TOPLEFT", cx, -(y0 - 1 - pad))
        return
    end
    if boxW and (NameSide() == "RIGHT") ~= (BS.extra.alignR and true or false) then
        x = math.max(BS.extra.width - math.max(boxW, label:GetStringWidth()), 0)
    end
    if pos:find("^top") then
        -- like the rows' names (user 2026-11-10: same gap): bottom edge 1 px above the first line
        local side = NameSide()
        label:ClearAllPoints()
        label:SetPoint("BOTTOM" .. side, BS.extra, "TOP" .. side, side == "RIGHT" and -x or x, -(y0 - 1 - pad))
    elseif pos:find("^bottom") then
        local last = y0 + (n - 1) * lineH
        PlaceAbs(label, NameSide(), x, last + size + AREA_TIMER_H + 1 + pad)
    else
        -- beside the first line, outside the area like the rows' names (6 px gap), vertically centred
        local yy = y0 + size / 2 - 5 -- 5 = about half the font height
        label:ClearAllPoints()
        if pos == "left" then
            label:SetPoint("TOPRIGHT", BS.extra, "TOPLEFT", -6, -yy)
        else
            label:SetPoint("TOPLEFT", BS.extra, "TOPRIGHT", 6, -yy)
        end
    end
end

-- names and spell IDs of the unwanted buffs / of the buffs shown by visible rows
local function SpellSet(ids)
    local set = {}
    for _, id in ipairs(ids) do
        for _, spellID in ipairs(ns:GetBuffSpellsForItem(id)) do set[spellID] = true end
        if ns.IsBuffID(id) then
            for _, name in ipairs(ns:GetBuffNames(id)) do set[name] = true end
        end
    end
    return set
end

local function CoveredSet()
    local ids = {}
    for _, btn in ipairs(activeButtons) do
        for _, id in ipairs(ns.EntryIDs(btn.entry)) do ids[#ids + 1] = id end
    end
    return SpellSet(ids)
end

local function UnwantedMacro()
    local lines, seen, len = {}, {}, 0
    for _, id in ipairs(ns.profile.unwanted or {}) do
        for _, name in ipairs(ns:GetBuffNames(id)) do
            local line = "/cancelaura " .. name
            -- macrotext of a secure button may be longer than a normal macro (255); 1023 since 2026-11-10 because
            -- of the many costume names (ItemRack also builds longer ones). /rkb debug shows the length.
            if not seen[name] and len + #line + 1 <= 1023 then
                seen[name] = true
                lines[#lines + 1] = line
                len = len + #line + 1
            end
        end
    end
    return #lines > 0 and table.concat(lines, "\n") or nil
end

-- Active unwanted buffs (real ones first, then the demo's): the row "Unerwünschte Buffs" (2026-11-10)
local function ActiveUnwanted()
    local set, list = SpellSet(ns.profile.unwanted or {}), {}
    for _, a in ipairs(ns.auraList) do
        if set[a.spellId] or set[a.name] then list[#list + 1] = a end
    end
    if ns.demo then
        for _, a in ipairs(ns.demo.buffs) do
            if set[a.spellId] then list[#list + 1] = a end
        end
    end
    return list, set
end

-- remaining durations of every area icon (from ns:UpdateTimers, may run in combat)
B.UpdateAreaTimers = function()
    local now = GetTime()
    -- group of each pool for "Zeit anzeigen" (2026-11-14); weapon enchants stand in "Sonstige Buffs"
    local fo, fd, fu = areaFrames.other, areaFrames.debuff, areaFrames.unw
    for _, pool in ipairs({ otherPool, B.debuffPool, B.weaponPool, B.unwPool }) do
        local isBuff = pool ~= B.debuffPool -- yellow timer only for buffs (user 2026-11-12)
        local af = pool == B.debuffPool and fd or pool == B.unwPool and fu or fo
        local hidden = not B.TimeOn(af and af.g)
        for _, o in ipairs(pool) do
            if o:IsShown() and o.aura then
                local exp = o.aura.expiration
                if exp and exp > 0 then
                    SetTimer(o.timer, exp - now, isBuff and o.aura.duration or nil, hidden)
                else
                    o.timer:SetText("")
                end
            end
        end
    end
end

-- Width, alignment, names, counter and the secure macro of the three areas: only out of combat (from BuildBar).
-- Adds the areas to shownGroups (after the row groups).
B.LayoutAreas = function()
    if not areaFrames.other then B.CreateAreas() end
    local p = ns.profile
    for _, g in ipairs(p.groups) do
        local f = g.area and areaFrames[g.area]
        if f then
            f.g = g
            f:SetScale(1) -- own scale in AreaLayout (no "Alle Gruppen" since session 20)
            -- right-aligned like the group it hangs on (rows ending at the right edge)
            local anchor = AreaAnchor(g.id)
            -- own orientation only since session 20 (user: no "Automatic"; before like the group it hangs on, else like
            -- "All Groups", MigrateAllGroups kept that look); none stored = the default "Rows right"
            f.alignR = g.orientation ~= "hleft"
            local size, sp, per, lineH = OtherSize(g.area, g.id)
            f.anchorPt = B.AnchorPoint(f.alignR) -- corner a free area grows away from (2026-11-14)
            f.width = per * (size + sp) - sp
            f:SetSize(f.width, 1)
            -- names like the rows' names; only "Gruppenname zeigen" decides (own value or "Alle Gruppen", = el._pos in the
            -- mockup since 2026-11-14). Before 2026-11-15 "Reihennamen zeigen" had to be on too: since that option lives
            -- in the category "Leisten" (groups with rows only), switching it showed or hid the names of the areas.
            -- the name is the group name since 2026-11-15 (user: every group alike, = el._pos in the mockup): on top,
            -- on the side of the alignment; before at the position of the row names (p.rowNamePos)
            -- own alignment of the name since 2026-11-15 (user): "topleft" | "topcenter" | "topright"
            f.namePos = ns.GEff(g, "showName") and ("top" .. ns.NameAlign(g)) or nil
            f.label:SetText(ns.GroupDisplayName(g))
            BS.extra = f
            if g.area == "other" then
                f.previewCells = nil -- layout changed: UpdatePreview lays the box out again
            elseif g.area == "unw" then
                -- secure button over the whole possible row (only here, out of combat)
                local _, uhMax = AreaExtent(f, math.max(#(p.unwanted or {}), 1), per, size, sp, lineH)
                PlaceX(f.button, 0, 0)
                f.button:SetSize(f.width, uhMax)
                -- the red button stays during the demo (2026-11-10): it removes the real unwanted buffs (a deliberate
                -- click on the user's own list) and, via PostClick, the demo's unwanted ones
                local macro = UnwantedMacro()
                f.button:SetAttribute("macrotext1", macro)
                f.button:SetShown(macro ~= nil and not g.hidden) -- eye of the group off (2026-11-12): no click area
            end
            shownGroups[#shownGroups + 1] = { g = g, f = f }
        end
    end
    BS.extra = areaFrames.other
    UpdatePreview(true)
end

-- Box of a preview: edges, placeholders filling from the top corner (PlaceX with the box itself as box)
local function LayoutPreview(box, y, nLines, cells, open, kind)
    local size, sp, per, lineH = OtherSize(kind, BS.extra.g and BS.extra.g.id)
    box.alignR = BS.extra.alignR
    -- exactly over the icon places (2026-11-11, before 3 px around them: the box ran into the area's name)
    PlaceX(box, 0, y)
    box:SetSize(per * (size + sp) - sp, nLines * lineH - (lineH - size - AREA_TIMER_H)) -- last line without the row gap
    -- no lines around the placeholders any more (session 4b, user: why a second frame inside the group?); the
    -- group's outline shows the area, the cells show the places
    for _, e in ipairs(box.edges) do e:Hide() end
    local r, g, b = unpack(box.rgb)
    for i = 1, math.max(cells, #box.cells) do
        local c = box.cells[i]
        if i <= cells then
            if not c then
                c = box:CreateTexture(nil, "ARTWORK")
                c:SetTexture("Interface\\Buttons\\WHITE8X8")
                box.cells[i] = c
            end
            local line = math.floor((i - 1) / per)
            local cx, cy = AreaSlot(BS.extra, i, cells, per, size, sp, lineH)
            PlaceX(c, cx, cy, box)
            c:SetSize(size, size)
            c:SetVertexColor(r, g, b, open and 0.12 * (1 - line / nLines) or 0.12)
            c:Show()
        elseif c then
            c:Hide()
        end
    end
end

-- Previews, fully dynamic (user 2026-11-09): "Sonstige Buffs" gets every buff slot that the rows do not use
-- RIGHT NOW: 32 minus the active buffs that a visible row shows (and the unwanted ones). The boxes are only laid out again when the number changes (force: after LayoutAreas).
-- Debuffs: their maximum; "Unerwünscht": one cell. Plain frames: allowed in combat.
UpdatePreview = function(force)
    local o, d, u = areaFrames.other, areaFrames.debuff, areaFrames.unw
    if not o then return end
    BS.extra = o
    local _, _, per = OtherSize(nil, o.g.id)
    local covered, used = CoveredSet(), 0
    for _, a in ipairs(ns.auraList) do
        if covered[a.spellId] or covered[a.name] then used = used + 1 end
    end
    if ns.demo then used = used + ns.demo.nRows end -- demo-active icons of the rows (2026-11-10)
    -- unwanted buffs have their own row since 2026-11-10 (hidden row, 2026-11-12: they sit in "Sonstige" itself)
    if not (u and u.g and u.g.hidden) then used = used + #ActiveUnwanted() end
    local cells = math.max(ns.BUFF_CAP - used, 0)
    if cells ~= o.previewCells or force then
        o.previewCells = cells
        o.previewLines = math.ceil(cells / per)
        LayoutPreview(o.preview, OTHER_TOP, math.max(o.previewLines, 1), cells, false)
        o.preview.empty = cells == 0 -- every buff slot used by a row: no blue box
    end
    if force then
        BS.extra = d
        local _, _, dper = OtherSize("debuff", d.g.id)
        LayoutPreview(d.preview, DebuffGap() + DEB_GAP, math.ceil(ns.DEBUFF_CAP / dper), ns.DEBUFF_CAP, false, "debuff")
        BS.extra = u
        LayoutPreview(u.preview, 0, 1, 1, false, "unw")
        BS.extra = o
    end
end

-- Box of an area after drawing it: everything shown (icons with their timer, names, previews, counter, frame of
-- the unwanted button) relative to its top-left corner. Read from the real regions (GetLeft/GetTop), so names
-- placed left/right/above/below are covered without doing the math twice.
-- fullX, fullW (2026-11-12, user: the bar shook while buffs came and went): the outline always covers the whole
-- width the area can take (Sonstige/Debuffs: f.width from 0, Unerwünscht: its button for the whole list from -4), so
-- a group snapped beside it, and everything hanging on that, no longer moves with every buff. fullX is measured from
-- the side the icons start at (PlaceX mirrors it when right-aligned).
-- A frame that was just shown has no rect until WoW's next layout pass (2026-11-14, user: after a /reload the first
-- opening of the options showed flat outlines for "Sonstige"/"Debuffs" until the first move). Then GetLeft() is
-- nil and the fallback box below is wrong; remeasure asks UpdateExtra to run once more on the next frame.
local remeasure, remeasureQueued, remeasureTries = nil, nil, 0
local function MeasureArea(f, regions, fullX, fullW)
    local fl, ft = f:GetLeft(), f:GetTop()
    local x0, y0, x1, y1
    if not (fl and ft) and f:IsVisible() then remeasure = true end
    if fl and ft then
        for _, r in ipairs(regions) do
            local region, below = r[1], r[2] or 0
            if region:IsShown() then
                local l, rr, t, b = region:GetLeft(), region:GetRight(), region:GetTop(), region:GetBottom()
                if not (l and rr and t and b) and region:IsVisible() then remeasure = true end
                if l and rr and t and b then
                    -- local: x right, y down; rounded to whole units (2026-11-12, "/rkb lage": width 362/363 every
                    -- second). WoW snaps regions to screen pixels, so l - fl carries a sub-pixel rest that depends on
                    -- where f itself stands; floor/ceil of e.g. -4.0001 gave one unit more, that moved f, and back.
                    l, rr = math.floor(l - fl + 0.5), math.floor(rr - fl + 0.5)
                    t, b = math.floor(ft - t + 0.5), math.floor(ft - b + 0.5) + below
                    x0, x1 = math.min(x0 or l, l), math.max(x1 or rr, rr)
                    y0, y1 = math.min(y0 or t, t), math.max(y1 or b, b)
                end
            end
        end
    end
    if not x0 then x0, y0, x1, y1 = 0, 0, f.width, 16 end
    if fullW then
        local a = f.alignR and (f.width - fullX - fullW) or fullX
        x0, x1 = math.min(x0, a), math.max(x1, a + fullW)
    end
    -- hanging above/below a group, the outline is as wide as that group's (session 4b, user: the edges of
    -- "Unerwünschte Buffs" did not line up); grows on the side away from the alignment
    local anchor = f.g and AreaAnchor(f.g.id)
    if anchor and anchor ~= f and anchor.box and anchor.posX then
        local _, _, aw = B.OutlineOf(anchor)
        local want = aw / f:GetScale() - 2 * B.MoverPad(f) - (ns.FrameOn(f.g) and 2 * (FRAME_PAD + B.FrameOutset(f.g)) or 0)
        if want > x1 - x0 then
            if f.alignR then x0 = x1 - want else x1 = x0 + want end
        end
    end
    local l, t, w, h = math.floor(x0), math.floor(y0), math.ceil(x1 - x0), math.ceil(y1 - y0)
    -- 1 unit of hysteresis (2026-11-12): a box that only differs by a rounding unit keeps its old values, so the
    -- loop measure -> place -> measure can never swing back and forth
    local m = f.measured
    if m and math.abs(m[1] - l) <= 1 and math.abs(m[2] - t) <= 1 and math.abs(m[3] - w) <= 1
        and math.abs(m[4] - h) <= 1 then
        l, t, w, h = m[1], m[2], m[3], m[4]
    else
        f.measured = { l, t, w, h }
    end
    B.Decorate(f, l, t, w, h)
end

-- Counter, the three areas and their boxes, then the layout of every group (may run in combat: only plain
-- frames, alpha and textures; secure groups keep their place until the fight ends)
B.UpdateExtra = function()
    local fo, fu, fd = areaFrames.other, areaFrames.unw, areaFrames.debuff
    if not fo or not fo.g then return end
    remeasure = nil -- set by MeasureArea when a rect is not there yet
    UpdatePreview() -- the blue preview follows the active buffs of the rows (2026-11-09)
    local demo = ns.demo -- demo mode (2026-11-10): fake buffs/debuffs, see ns:StartDemo
    local n = BuffsUsed()
    -- the buff counter follows every change here, also the demo's ticks, which call only UpdateExtra (user 2026-11-25:
    -- the counter showed 28 in yellow while the tint was already red); before it was only drawn in UpdateButton
    for _, btn in ipairs(activeButtons) do
        if btn.isCounter then B.UpdateCounterButton(btn) end
    end
    local pv = BS.areaPreview
    local size, sp, per, lineH = OtherSize(nil, fo.g.id)
    -- icon borders and font size of the time per area (2026-11-14, style "icon" / "Font size")
    local stU, stO, stD = B.IconStyle(fu.g), B.IconStyle(fo.g), B.IconStyle(fd.g)
    local tsU, tsO, tsD = ns.GEff(fu.g, "timeSize"), ns.GEff(fo.g, "timeSize"), ns.GEff(fd.g, "timeSize")

    -- ----- "Unerwünschte Buffs": every active unwanted buff (real ones, then the demo's); the secure button
    -- under it (LayoutAreas) removes all with one click, right-click on an icon just that one
    BS.extra = fu
    -- own size since 2026-11-11 (user): "Eigene Größe" of its group, else like "Alle Gruppen" (since 2026-11-12)
    local usize, usp, uper, ulineH = OtherSize("unw", fu.g.id)
    local unwList, unwantedSet = ActiveUnwanted()
    -- eye of an area off (2026-11-12, user): the area is not drawn, not even as preview while editing. Hidden
    -- "Unerwünschte Buffs": its buffs show under "Sonstige" like any other buff.
    if fu.g.hidden then unwList, unwantedSet = {}, {} end
    local pvU, pvO, pvD = pv and not fu.g.hidden, pv and not fo.g.hidden, pv and not fd.g.hidden
    fu.button.active = unwList
    local nU = #unwList
    for i, a in ipairs(unwList) do
        local o = B.unwPool[i] or B.CreateUnwIcon(i)
        o.aura = a
        o:SetSize(usize, usize)
        -- hit rect over half the gap on each side and the timer below (2026-11-11): only the X removes all
        o:SetHitRectInsets(-math.floor(usp / 2), -math.ceil(usp / 2), 0, -(AREA_TIMER_H + usp))
        -- after the X cell at the start (user 2026-11-12: X on the other side; before it was at the end)
        local ux, uy = AreaSlot(fu, i, nU, uper, usize, usp, ulineH)
        PlaceX(o, ux + 14 + usp, uy)
        o.icon:SetTexture(a.icon)
        o.border:SetShown(B.BordersOn(fu.g))
        o.border:SetColorTexture(unpack(stU.unwanted))
        B.SetBorderSize(o.border, stU.size)
        B.SetTimerSize(o.timer, tsU)
        o:Show()
    end
    for i = nU + 1, #B.unwPool do
        B.unwPool[i]:Hide()
        B.unwPool[i].aura = nil
    end
    local uw, uh, uLines = AreaExtent(fu, math.max(nU, 1), uper, usize, usp, ulineH)
    if nU == 0 then uLines = 0 end
    -- button look (2026-11-11): X cell (14 px, at the start since 2026-11-12) + icons, dark 3 px around, 1 px frame
    local box = fu.unwBox
    local unwW = uw + usp + 14
    if nU > 0 then
        local w, h = unwW, uh
        PlaceX(box.bg, -3, -3)
        box.bg:SetSize(w + 6, h + 6)
        local e = box.edges
        PlaceX(e[1], -4, -4) e[1]:SetSize(w + 8, 1)
        PlaceX(e[2], -4, h + 3) e[2]:SetSize(w + 8, 1)
        PlaceX(e[3], -4, -4) e[3]:SetSize(1, h + 8)
        PlaceX(e[4], w + 3, -4) e[4]:SetSize(1, h + 8)
        PlaceX(box.x, 1, (usize - 12) / 2) -- X cell 0..14 at the start side (2026-11-12)
        box:SetShown(true)
    else
        box:SetShown(false)
    end
    fu.preview:SetShown(pvU and nU == 0)
    fu.label:SetShown(fu.namePos ~= nil and (nU > 0 or pvU))
    if fu.namePos then PlaceName(fu.label, 0, math.max(uLines, 1), ulineH, usize, nU > 0 and unwW or usize + 6) end
    fu.empty = nU == 0 and not pvU
    local regions = { { fu.label }, { fu.preview }, { box.bg }, { box.edges[1] }, { box.edges[2] } }
    for i = 1, nU do regions[#regions + 1] = { B.unwPool[i], AREA_TIMER_H } end
    -- whole width of the button with every buff of the list active (frame 4 px around it)
    local uwFull = AreaExtent(fu, math.max(#(ns.profile.unwanted or {}), 1), uper, usize, usp, ulineH)
    fu.iconTop = nU > 0 and 0 or nil -- first icon line (B.IconInset, 2026-11-15)
    MeasureArea(fu, regions, -4, uwFull + usp + 14 + 8)

    -- ----- "Sonstige Buffs": weapon enchants of hands no row covers, other buffs, demo buffs
    BS.extra = fo
    local lv = B.CapLevel(ns.BUFF_CAP - n)
    local oTop = OTHER_TOP
    local coveredHand = {}
    for _, btn in ipairs(activeButtons) do
        if btn.isWeapon then coveredHand[btn.hand] = true end
    end
    -- Sonstige: active buffs not shown by a visible row, in buff index order (= stable); demo buffs last;
    -- unwanted buffs are left out: they have their own row (2026-11-10)
    local covered = CoveredSet()
    local others = {}
    for _, a in ipairs(ns.auraList) do
        if not covered[a.spellId] and not covered[a.name] and not unwantedSet[a.spellId] and not unwantedSet[a.name] then
            others[#others + 1] = a
        end
    end
    if demo then
        for _, a in ipairs(demo.buffs) do
            if not unwantedSet[a.spellId] then others[#others + 1] = a end
        end
    end
    -- eye of the area off (2026-11-12): nothing drawn here (weapon enchants and buffs still count towards the cap)
    if fo.g.hidden then others, coveredHand = {}, { main = true, off = true } end
    -- total first (AreaSlot gets the count)
    local nTot = #others
    for _, hand in ipairs({ "main", "off" }) do
        if ns.weapon[hand] and not coveredHand[hand] then nTot = nTot + 1 end
    end
    local function OtherSlot(i)
        local x, y = AreaSlot(fo, i, nTot, per, size, sp, lineH)
        return x, oTop + y
    end
    local used = 0
    for _, hand in ipairs({ "main", "off" }) do
        local h = ns.weapon[hand]
        if h and not coveredHand[hand] then
            used = used + 1
            local o = B.weaponPool[used] or B.CreateWeaponIcon(used)
            o.slot = WEAPON_SLOT[hand]
            o.aura = { expiration = h.wf and 0 or h.expiration, duration = CatalogDuration(h.itemID) } -- for the timer
            o:SetSize(size, size)
            PlaceX(o, OtherSlot(used))
            local icon = h.wf and ns.WINDFURY_ICON
                or (h.itemID and ns.EntryIcon(h.itemID)) or GetInventoryItemTexture("player", o.slot) or 134400
            o.icon:SetTexture(icon)
            o.handMark:SetText(hand == "main" and L["MH"] or L["OH"])
            o.border:SetShown(B.BordersOn(fo.g))
            B.SetBorderSize(o.border, stO.size) -- colour stays violet (weapon enchant)
            B.SetTimerSize(o.timer, tsO)
            o:Show()
        end
    end
    local nWeapon = used
    for i = nWeapon + 1, #B.weaponPool do
        B.weaponPool[i]:Hide()
        B.weaponPool[i].aura = nil
    end
    local nOther = 0 -- index in otherPool; the position continues after the weapon enchants (used)
    for _, a in ipairs(others) do
        used = used + 1
        nOther = nOther + 1
        local o = otherPool[nOther] or B.CreateOtherIcon(nOther)
        o.aura = a
        o.unwanted = false
        o:SetSize(size, size)
        PlaceX(o, OtherSlot(used))
        o.icon:SetTexture(a.icon)
        o.border:SetColorTexture(unpack(stO.other)) -- colour of the group (2026-11-14, before fixed grey)
        o.border:SetShown(B.BordersOn(fo.g))
        B.SetBorderSize(o.border, stO.size)
        B.SetTimerSize(o.timer, tsO)
        o:Show()
    end
    for i = nOther + 1, #otherPool do
        otherPool[i]:Hide()
        otherPool[i].aura = nil
    end
    local _, _, usedLines = AreaExtent(fo, math.max(used, 1), per, size, sp, lineH)
    if used == 0 then usedLines = 0 end
    fo.preview:SetShown(pvO and not fo.preview.empty)
    local otherLines = math.max(pvO and fo.previewLines or 0, usedLines)
    fo.label:SetShown(fo.namePos ~= nil and otherLines > 0)
    if fo.namePos then PlaceName(fo.label, oTop, math.max(otherLines, 1), lineH, size) end
    -- empty without buffs and preview, like the debuffs (session 4b: the counter is no longer part of it)
    fo.empty = used == 0 and not (pvO and fo.preview:IsShown())
    regions = { { fo.label }, { fo.preview } }
    for i = 1, nWeapon do regions[#regions + 1] = { B.weaponPool[i], AREA_TIMER_H } end
    for i = 1, nOther do regions[#regions + 1] = { otherPool[i], AREA_TIMER_H } end
    fo.iconTop = nTot > 0 and select(2, OtherSlot(1)) or nil -- first icon line (B.IconInset, 2026-11-15)
    MeasureArea(fo, regions, 0, fo.width)

    -- ----- "Debuffs": only while replacing the Blizzard bar, demo debuffs always. The name at the top (names
    -- above), the icons DEB_GAP later; the divider is the group separator since 2026-11-14. Border = DebuffTypeColor.
    BS.extra = fd
    local debuffs = {}
    if ns.replacing then
        for _, d in ipairs(ns.debuffList) do debuffs[#debuffs + 1] = d end
    end
    if demo then
        for _, d in ipairs(demo.debuffs) do debuffs[#debuffs + 1] = d end
    end
    if fd.g.hidden then debuffs = {} end -- eye of the area off (2026-11-12)
    local dsize, dsp, dper, dlineH = OtherSize("debuff", fd.g.id)
    local debTop = DebuffGap() + DEB_GAP
    local nDebuffs = 0
    local nDebTotal = #debuffs
    for _, d in ipairs(debuffs) do
        nDebuffs = nDebuffs + 1
        local o = B.debuffPool[nDebuffs] or B.CreateDebuffIcon(nDebuffs)
        o.aura = d
        o:SetSize(dsize, dsize)
        local dx, dy = AreaSlot(fd, nDebuffs, nDebTotal, dper, dsize, dsp, dlineH)
        PlaceX(o, dx, debTop + dy)
        o.icon:SetTexture(d.icon)
        local color = DebuffTypeColor and (DebuffTypeColor[d.dispel or "none"] or DebuffTypeColor.none)
        if color then o.border:SetColorTexture(color.r, color.g, color.b, 1) else o.border:SetColorTexture(0.8, 0, 0, 1) end
        o.count:SetText(d.count and d.count > 1 and d.count or "")
        o.border:SetShown(B.BordersOn(fd.g))
        B.SetBorderSize(o.border, stD.size) -- colour = debuff type
        B.SetTimerSize(o.timer, tsD)
        o:Show()
    end
    for i = nDebuffs + 1, #B.debuffPool do
        B.debuffPool[i]:Hide()
        B.debuffPool[i].aura = nil
    end
    fd.preview:SetShown(pvD)
    fd.label:SetShown(fd.namePos ~= nil and (nDebuffs > 0 or pvD))
    if fd.namePos then
        local dLines = pvD and math.ceil(ns.DEBUFF_CAP / dper) or math.ceil(nDebuffs / dper)
        PlaceName(fd.label, debTop, math.max(dLines, 1), dlineH, dsize)
    end
    fd.empty = nDebuffs == 0 and not pvD
    regions = { { fd.label }, { fd.preview } }
    for i = 1, nDebuffs do regions[#regions + 1] = { B.debuffPool[i], AREA_TIMER_H } end
    fd.iconTop = nDebTotal > 0 and debTop or nil -- first icon line (B.IconInset, 2026-11-15)
    MeasureArea(fd, regions, 0, fd.width)
    BS.extra = fo

    -- empty groups (placeholders, 2026-11-15) show together with the area previews (= renderExtras in the mockup);
    -- only drawing changes, so this is fine in combat too (BS.areaPreview is off there anyway)
    for _, e in ipairs(shownGroups) do
        local f = e.f
        if f.placeholder and f.empty ~= not BS.areaPreview then
            f.empty = not BS.areaPreview
            B.Decorate(f, unpack(f.decoArgs))
            B.UpdatePlaceholder(f)
        end
    end

    -- background tint by free buff slots (2026-11-10, user: fixed steps) on every group with "Buff-Limit-Färbung"
    -- (2026-11-11: each group for itself; main and the two buff areas by default). Plain textures: allowed in combat.
    for _, e in ipairs(shownGroups) do
        local g, f = e.g, e.f
        -- debuffs never (session 4c, user: they do not count towards the buff cap)
        local on = lv and not f.empty and g.area ~= "debuff"
            and (g.id == "main" and g.capTint ~= false or g.id ~= "main" and g.capTint == true)
        if on then
            f.capTint:SetColorTexture(unpack(lv.bg))
            f.capTint:Show()
        else
            f.capTint:Hide()
        end
    end
    B.LayoutGroups()
    -- a rect was missing (frame just shown): measure again on the next frame, at most 3 times in a row
    if remeasure then
        remeasureTries = remeasureTries + 1
        if remeasureTries <= 3 and not remeasureQueued then
            remeasureQueued = true
            C_Timer.After(0, function()
                remeasureQueued = nil
                if B.UpdateExtra then B.UpdateExtra() end
            end)
        end
    else
        remeasureTries = 0
    end
end

-- shared with the other Bar*.lua files
B.otherPool = otherPool
B.CoveredSet = CoveredSet
B.UnwantedMacro = UnwantedMacro
