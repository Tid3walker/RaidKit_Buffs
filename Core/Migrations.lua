-- RaidKit Buffs: Core - Migrations
-- One-time conversions of stored profiles (old values, removed features) and EnsureGroups. Run at PLAYER_LOGIN
-- through ns.MigrateAndEnsureRows (Core.lua). Split from Core.lua on 2026-11-20.

local _, ns = ...
local L = ns.L
local CopyTable = ns.CopyTable

-- Once per profile (prof.inheritMigrated, 2026-11-14): the old "Eigene Größe" groups and rows kept all values, even
-- those equal to "Alle Gruppen"; they would all show as overridden. Keeps the look, drops what equals the parent.
local function MigrateInherit(prof)
    if prof.inheritMigrated then return end
    prof.inheritMigrated = true
    local SIZE = { "iconSize", "spacing", "scale", "perLine", "rowSpacing" }
    local function PV(k)
        local v = prof[k]
        if v == nil then v = ns.profileDefaults[k] end
        if v == nil and k == "perLine" then v = 0 end
        return v
    end
    for _, g in ipairs(prof.groups) do
        -- areas showed their name unless switched off; the new default of "Alle Gruppen" is off
        if g.area and g.showName == nil then g.showName = true end
        if g.area == "debuff" and not (type(g.style) == "table" and type(g.style.sep) == "table") then
            g.style = type(g.style) == "table" and g.style or {}
            g.style.sep = { color = "#ff5959", alpha = 0.45 }
        end
        -- row names: before "Alle Gruppen" off switched every group off; now a group value wins
        if prof.showRowNames == false and g.rowNames == true then g.rowNames = nil end
        if g.iconSize ~= nil then
            -- the old fallbacks of "Eigene Größe" (groups: like "Alle Gruppen"; areas: spacing 4, line gap = spacing,
            -- scale on top of the bar's scale)
            if g.area then
                if g.spacing == nil then g.spacing = 4 end
                if g.rowSpacing == nil then g.rowSpacing = g.spacing end
                g.scale = (g.scale or 1) * (prof.scale or 1)
            elseif g.scale == nil then
                g.scale = 1
            end
            if g.perLine == nil then g.perLine = 0 end
            for _, k in ipairs(SIZE) do
                if g[k] == PV(k) then g[k] = nil end
            end
        else
            -- without "Eigene Größe" the other size values were ignored
            g.spacing, g.scale, g.perLine, g.rowSpacing = nil, nil, nil, nil
        end
    end
    if type(prof.rows) ~= "table" then return end
    for _, r in ipairs(prof.rows) do
        if r.scale == 1 then r.scale = nil end
        local g = ns.GroupById(prof, r.group or "main")
        for _, k in ipairs({ "iconSize", "spacing", "perLine" }) do
            if r[k] ~= nil and r[k] == ns.GEff(g, k, prof) then r[k] = nil end
        end
    end
end

-- groups of a profile (also saved profiles): "main" first, the three areas last, every row in a known group,
-- rows kept in group order (stable), so the list in the options and the bar show the same order
-- Once per profile (prof.frameMigrated, 2026-11-15): the frame defaults are "Parchment" / border "None" now, and the
-- border shows without a background. Existing profiles keep their look: the old defaults (gradient, flat line) become
-- values of "All Groups", groups without a frame get border "None". A new profile (no groups yet) takes the new defaults.
local function MigrateFrame(prof, fresh)
    if prof.frameMigrated then return end
    prof.frameMigrated = true
    if fresh then return end
    if type(prof.style) ~= "table" then prof.style = {} end
    if type(prof.style.frame) ~= "table" then prof.style.frame = {} end
    local a = prof.style.frame
    if a.bgTex == nil then a.bgTex = "gradient" end
    if a.edge == nil then a.edge = "flat" end
    for _, g in ipairs(prof.groups) do
        if not g.frame and g.area ~= "unw" and ns.StyleOf(g, "frame", prof).edge ~= "none" then
            if type(g.style) ~= "table" then g.style = {} end
            if type(g.style.frame) ~= "table" then g.style.frame = {} end
            g.style.frame.edge = "none"
        end
    end
end

-- Once per profile (prof.frameAutoMigrated, 2026-11-15, after MigrateFrame): the background is no longer the flag
-- g.frame but the texture ("None" = none, default of "All Groups"; a group without own value follows "All Groups").
-- Keeps the look: "All Groups" keeps its texture if any group had a background (the old default was "parchment"), else
-- goes back to "None"; every group gets an own texture only where it differs from that ("None" for groups without).
local function MigrateFrameAuto(prof, fresh)
    if prof.frameAutoMigrated then return end
    prof.frameAutoMigrated = true
    if fresh then return end
    local a = type(prof.style) == "table" and type(prof.style.frame) == "table" and prof.style.frame or nil
    local oldAll = a and a.bgTex or "parchment"
    local framed = false
    for _, g in ipairs(prof.groups) do
        if g.frame and g.area ~= "unw" then framed = true end
    end
    local newAll = framed and oldAll or "none"
    if newAll == "none" then
        if a then a.bgTex = nil end
    else
        if type(prof.style) ~= "table" then prof.style = {} end
        if type(prof.style.frame) ~= "table" then prof.style.frame = {} end
        prof.style.frame.bgTex = newAll
    end
    for _, g in ipairs(prof.groups) do
        local s = type(g.style) == "table" and type(g.style.frame) == "table" and g.style.frame or nil
        local before = "none"
        if g.frame and g.area ~= "unw" then before = s and s.bgTex or oldAll end
        if before == newAll then
            if s then s.bgTex = nil end
        else
            if type(g.style) ~= "table" then g.style = {} end
            if type(g.style.frame) ~= "table" then g.style.frame = {} end
            g.style.frame.bgTex = before
        end
        if type(g.style) == "table" and type(g.style.frame) == "table" and next(g.style.frame) == nil then g.style.frame = nil end
        if type(g.style) == "table" and next(g.style) == nil then g.style = nil end
        g.frame = nil
    end
end

-- Once per profile (prof.nameAlignMigrated, 2026-11-15): the group name has its own alignment now (before it followed
-- the icons). Keeps the look: "All Groups" gets the side of its icon alignment, a group with rows and its own icon
-- alignment gets the same for its name; the areas follow their icons without an own value anyway.
local function MigrateNameAlign(prof)
    if prof.nameAlignMigrated then return end
    prof.nameAlignMigrated = true
    prof.nameAlign = prof.orientation == "hleft" and "left" or "right"
    for _, g in ipairs(prof.groups) do
        if not g.area and g.orientation and g.nameAlign == nil then
            g.nameAlign = g.orientation == "hleft" and "left" or "right"
        end
    end
end

-- Once per profile (prof.sepFadeMigrated, 2026-11-15, user): fading ends are their own choice (sep.fade) instead of the
-- look "fade". Keeps the look of every stored value: "fade" becomes "solid" + both ends; another stored look gets "none"
-- (it never faded, and the new default is "left"). Values that were never changed follow the new default.
local function MigrateSepFade(prof)
    if prof.sepFadeMigrated then return end
    prof.sepFadeMigrated = true
    local function Fix(holder)
        local s = type(holder) == "table" and type(holder.style) == "table" and holder.style.sep
        if type(s) ~= "table" or s.look == nil or s.fade ~= nil then return end
        if s.look == "fade" then s.look, s.fade = "solid", "both" else s.fade = "none" end
    end
    Fix(prof)
    for _, g in ipairs(prof.groups) do Fix(g) end
end

-- Once per profile (prof.areaNamesMigrated, 2026-11-15, user): Unwanted, Other and Debuffs had "Show group name" on as
-- their own value from the start (ns.AREA_GROUPS until 2026-11-15), so they ignored "All Groups". The old default
-- value is dropped; the areas follow "All Groups" (default off) like every group.
local function MigrateAreaNames(prof)
    if prof.areaNamesMigrated then return end
    prof.areaNamesMigrated = true
    for _, g in ipairs(prof.groups) do
        if g.area and g.showName == true then g.showName = nil end
    end
end

-- Once per profile (prof.bagCountMigrated, session 20, user): "Bag count" is set per group only; the category "Bars"
-- (its default for every group with rows, prof.showCount) is a heading only now. Keeps the look: a group with rows and
-- without an own value takes the old value of "Bars"; then prof.showCount goes (fallback = default off).
local function MigrateBagCount(prof)
    if prof.bagCountMigrated then return end
    prof.bagCountMigrated = true
    if prof.showCount == true then
        for _, g in ipairs(prof.groups) do
            if not g.area and g.showCount == nil then g.showCount = true end
        end
    end
    prof.showCount = nil
end

-- = migrateRowAlign in the mockup (2026-11-18, user): "Icons:" of a group with rows is gone, every row has its own
-- alignment (row.align, BarSplit.lua). Every time, a no-op once done (imported profiles may still carry it): a group on
-- "Left" hands it to its normal rows without an own choice (split rows without one stay "Both sides", as before), then
-- the group forgets its orientation. The areas keep theirs.
local function MigrateRowAlign(prof)
    for _, g in ipairs(prof.groups) do
        if not g.area and g.orientation ~= nil then
            if g.orientation == "hleft" then
                for _, r in ipairs(type(prof.rows) == "table" and prof.rows or {}) do
                    if (r.group or "main") == g.id and r.split == nil and r.align == nil then r.align = "left" end
                end
            end
            g.orientation = nil
        end
    end
end

-- Session 20 (user): "Alle Gruppen" is gone, every group decides on its own (mockup migrateAllGroups).
-- Once per profile (prof.allGroupsMigrated): "Automatic" orientation and name alignment become fixed values with the
-- same look: a group with rows takes the orientation of "Alle Gruppen" (prof.orientation) and its name alignment
-- (prof.nameAlign); an area docked above/below a group takes that group's orientation, otherwise the one of "Alle
-- Gruppen"; its name stays on the side of its icons. Only values other than the defaults ("hright", "right") are stored.
-- Every time (a no-op once done, but old saved and imported profiles still carry them): a value of "Alle Gruppen" that
-- differs from the default goes into every group without its own value (areas too), then it is removed from the
-- profile; ApplyDefaults puts the plain default back, which nothing reads any more.
local function MigrateAllGroups(prof)
    local D = ns.profileDefaults
    if not prof.allGroupsMigrated then
        prof.allGroupsMigrated = true
        local byId, orient = {}, {}
        for _, g in ipairs(prof.groups) do byId[g.id] = g end
        local po = prof.orientation == "hleft" and "hleft" or "hright"
        local function Orient(g, depth)
            if g.orientation then return g.orientation end
            if not g.area then return po end
            local q = type(prof.groupPos) == "table" and prof.groupPos[g.id]
            local t = type(q) == "table" and (q.side == "bottom" or q.side == "top") and byId[q.snap]
            if t and depth < 5 then return Orient(t, depth + 1) end
            return po
        end
        for _, g in ipairs(prof.groups) do orient[g] = Orient(g, 0) end
        for _, g in ipairs(prof.groups) do
            if g.orientation == nil and orient[g] ~= "hright" then g.orientation = orient[g] end
            if g.nameAlign == nil then
                local na = g.area and (orient[g] == "hleft" and "left" or "right") or prof.nameAlign
                if na and na ~= "right" then g.nameAlign = na end
            end
        end
    end
    for k, a in pairs(ns.GROUP_INHERIT) do
        local v = prof[a]
        if v ~= nil and v ~= D[a] then
            for _, g in ipairs(prof.groups) do
                if g[k] == nil then g[k] = v end
            end
        end
        prof[a] = nil
    end
    if prof.showBorders == true then
        for _, g in ipairs(prof.groups) do
            if g.showBorders == nil then g.showBorders = true end
        end
    end
    prof.showBorders, prof.nameAlign = nil, nil
    if type(prof.style) == "table" then
        for sec, vals in pairs(prof.style) do
            local def = ns.STYLE_DEF[sec]
            if def and type(vals) == "table" then
                for k, v in pairs(vals) do
                    if v ~= nil and v ~= def[k] then
                        for _, g in ipairs(prof.groups) do
                            if type(g.style) ~= "table" then g.style = {} end
                            if type(g.style[sec]) ~= "table" then g.style[sec] = {} end
                            if g.style[sec][k] == nil then g.style[sec][k] = v end
                        end
                    end
                end
            end
        end
    end
    prof.style = nil
end

-- Every time (2026-11-16, user; BarSplit.lua): a row has no own size and never wraps any more, every row of a group has
-- the group's "Per line" as places. Old values go: row.iconSize / spacing / scale / perLine, the split groups of
-- 2026-11-15 (g.split / g.splitWidth; their rows stay split rows). A row longer than 20 icons gives the rest to a new
-- row right after it (while there is room), a group whose rows need more places gets wider. Nothing is removed.
local function FitRowWidths(prof)
    local splitGroup = {}
    for _, g in ipairs(prof.groups) do
        if g.split ~= nil then splitGroup[g.id] = g.split == true end
        g.split, g.splitWidth = nil, nil
    end
    local i = 1
    while prof.rows[i] do
        local r = prof.rows[i]
        r.iconSize, r.spacing, r.scale, r.perLine = nil, nil, nil, nil
        if type(r.items) ~= "table" then r.items = {} end
        if splitGroup[r.group] and r.split == nil then r.split = #r.items end -- row of an old split group: all left
        if r.split ~= nil then r.split = math.max(0, math.min(#r.items, math.floor(tonumber(r.split) or #r.items))) end
        local cap = ns.ROW_MAX -- split rows hold as many icons as normal ones since session 20 (before 19: one place was the separator)
        if #r.items > cap and #prof.rows < 10 then
            local rest = {}
            while #r.items > cap do table.insert(rest, 1, table.remove(r.items)) end
            if r.split then r.split = math.min(r.split, #r.items) end
            table.insert(prof.rows, i + 1, { name = r.name, group = r.group, items = rest })
        end
        i = i + 1
    end
    for _, g in ipairs(prof.groups) do
        if not g.area then
            local n = ns.GroupNeed(prof, g)
            if n > ns.GroupWidth(g, prof) then g.perLine = n >= ns.ROW_MAX and 0 or n end
        end
    end
end

-- Once per profile (prof.perLineMigrated, user 2026-11-20): groups with rows have 12 places per row by default
-- (ns.ROW_PER_LINE, before 0 = 20). A group of an older profile without an own value keeps its look (0); a new profile
-- (fresh) gets the new default.
local function MigratePerLine(prof, fresh)
    if prof.perLineMigrated then return end
    prof.perLineMigrated = true
    if fresh then return end
    for _, g in ipairs(prof.groups) do
        if not g.area and g.perLine == nil then g.perLine = 0 end
    end
end

-- fresh = new profile (EnsureRows; it may already hold the class groups, 2026-11-18)
function ns.EnsureGroups(prof, fresh)
    if type(prof.groups) ~= "table" then prof.groups = {} end
    fresh = fresh or #prof.groups == 0 -- new profile (fresh install, reset): new frame defaults (MigrateFrame)
    -- a group with an area's id but without its area (broken import) would hide the real area: drop it
    local areaIds = {}
    for _, a in ipairs(ns.AREA_GROUPS) do areaIds[a.id] = a.area end
    for i = #prof.groups, 1, -1 do
        local g = prof.groups[i]
        if type(g) ~= "table" or (areaIds[g.id] and g.area ~= areaIds[g.id]) then table.remove(prof.groups, i) end
    end
    if not ns.GroupById(prof, "main") then
        table.insert(prof.groups, 1, { id = "main", name = "Buffs & Cons", capTint = true })
    end
    -- columns are gone since 2026-11-14 (user): a column orientation becomes "rows right" (the default) for the bar and
    -- "automatisch" for a group
    if prof.orientation == "vdown" or prof.orientation == "vup" then prof.orientation = "hright" end
    for _, g in ipairs(prof.groups) do
        if g.orientation == "vdown" or g.orientation == "vup" then g.orientation = nil end
    end
    -- the main group is called "Buffs & Cons" since 2026-11-12 (user; before "Hauptleiste"); an own name stays
    local mainG = ns.GroupById(prof, "main")
    if mainG and mainG.name == "Hauptleiste" then mainG.name = "Buffs & Cons" end
    for _, a in ipairs(ns.AREA_GROUPS) do
        if not ns.GroupById(prof, a.id) then
            local g = { id = a.id, area = a.area, name = a.name, capTint = a.capTint }
            if a.style then g.style = CopyTable(a.style) end -- own copy (2026-11-14)
            prof.groups[#prof.groups + 1] = g
        end
    end
    -- "Unerwünschte Buffs" has no "Rahmen" option since 2026-11-14 (user): it already looks like a button with its own frame
    local unwG = ns.GroupById(prof, "unw")
    if unwG then unwG.frame = nil end
    -- Sizes of "Sonstige Buffs" / "Debuffs" (2026-11-12, user: like every group). Until then the profile had own keys
    -- (other*/debuff*) and "Unerwünschte Buffs" without own size used those of "Sonstige". Once: values that differ
    -- from "Alle Gruppen" become "Eigene Größe" of the group (rowSpacing = spacing: lines kept their gap), then the
    -- old keys go. Also runs for imported or loaded old profiles (they come through here).
    local hadOld = false
    for _, pre in ipairs({ "other", "debuff" }) do
        local size, sp, sc = prof[pre .. "IconSize"], prof[pre .. "Spacing"], prof[pre .. "Scale"]
        local per = prof[pre .. "PerLine"]
        if size or sp or sc or per then
            hadOld = true
            local g = ns.GroupById(prof, pre)
            size, sp, sc = size or 30, sp or 4, sc or 1
            if g and g.iconSize == nil and (size ~= (prof.iconSize or 30) or sp ~= (prof.spacing or 4) or sc ~= 1) then
                g.iconSize, g.spacing, g.scale, g.perLine, g.rowSpacing = size, sp, sc, per or 10, sp
            end
        end
        prof[pre .. "IconSize"], prof[pre .. "Spacing"], prof[pre .. "Scale"], prof[pre .. "PerLine"] = nil, nil, nil, nil
    end
    if hadOld then
        local u, o = ns.GroupById(prof, "unw"), ns.GroupById(prof, "other")
        if u and o and u.iconSize == nil and o.iconSize ~= nil then
            u.iconSize, u.spacing, u.scale, u.perLine, u.rowSpacing = o.iconSize, o.spacing, o.scale, o.perLine, o.rowSpacing
        end
    end
    local rowGroups, areas = {}, {}
    for _, g in ipairs(prof.groups) do
        if g.area then areas[#areas + 1] = g else rowGroups[#rowGroups + 1] = g end
    end
    wipe(prof.groups)
    local order = {}
    for _, g in ipairs(rowGroups) do prof.groups[#prof.groups + 1] = g; order[g.id] = #prof.groups end
    for _, g in ipairs(areas) do prof.groups[#prof.groups + 1] = g end
    MigrateInherit(prof) -- once (2026-11-14): only values that differ from the parent stay
    MigrateFrame(prof, fresh) -- once (2026-11-15): old frame defaults kept for existing profiles
    MigrateFrameAuto(prof, fresh) -- once (2026-11-15): texture "None" instead of g.frame, groups follow "All Groups"
    MigrateNameAlign(prof) -- once (2026-11-15): own alignment of the group name, same look as before
    MigrateSepFade(prof) -- once (2026-11-15): fading ends of the separator as their own choice, same look as before
    MigrateAreaNames(prof) -- once (2026-11-15): the areas' group name follows "All Groups"
    MigrateBagCount(prof) -- once (session 20): bag count per group, "Bars" is a heading only
    MigrateAllGroups(prof) -- session 20: "Alle Gruppen" is gone, its values go into the groups
    MigrateRowAlign(prof) -- 2026-11-18: "Icons:" of a group with rows goes into its rows
    -- row spacing at most 20 since 2026-11-18 (user; before 40): larger stored values are cut (= ensureGroups in the mockup)
    for _, g in ipairs(prof.groups) do
        if type(g.rowSpacing) == "number" and g.rowSpacing > 20 then g.rowSpacing = 20 end
    end
    -- once (prof.armorMigrated, 2026-11-15): -22783 was one icon for every mage armor, now it is Mage Armor only;
    -- an old plain icon becomes the slot Mage Armor > Ice Armor, so an active Ice Armor still counts
    if not prof.armorMigrated then
        prof.armorMigrated = true
        for _, r in ipairs(type(prof.rows) == "table" and prof.rows or {}) do
            for i, entry in ipairs(type(r.items) == "table" and r.items or {}) do
                if entry == -22783 then r.items[i] = { -22783, -10220, pick = -22783 } end
            end
        end
    end
    MigratePerLine(prof, fresh) -- 2026-11-20: 12 places per row by default
    if type(prof.rows) ~= "table" then return end
    local keyed = {}
    for i, r in ipairs(prof.rows) do
        if not order[r.group] then r.group = "main" end
        keyed[i] = { r = r, i = i }
    end
    table.sort(keyed, function(a, b)
        local ga, gb = order[a.r.group], order[b.r.group]
        if ga ~= gb then return ga < gb end
        return a.i < b.i
    end)
    for i, k in ipairs(keyed) do prof.rows[i] = k.r end
    FitRowWidths(prof)
end

-- positions of the character: an area without a position gets its default place (ns.AREA_GROUPS snap/side)
function ns.EnsureGroupPos(prof)
    if type(prof.groupPos) ~= "table" then prof.groupPos = {} end
    for _, a in ipairs(ns.AREA_GROUPS) do
        if type(prof.groupPos[a.id]) ~= "table" then prof.groupPos[a.id] = { snap = a.snap, side = a.side } end
    end
    -- groups of the class (2026-11-18, ns.CLASS_GROUPS): their default place while the profile has them and no place
    for _, cg in ipairs(ns.CLASS_GROUPS[ns:PlayerClass()] or {}) do
        if ns.GroupById(prof, cg.id) and type(prof.groupPos[cg.id]) ~= "table" then
            prof.groupPos[cg.id] = { snap = cg.snap, side = cg.side, align = cg.align }
        end
    end
end

-- Once per account (RaidKitBuffsDB.debuffLastFixed): the short-lived default of 2026-11-12 (Debuffs below Unerwünscht,
-- Sonstige below Debuffs) becomes the default again (Sonstige, then Debuffs last, user). Only this exact chain;
-- every other own layout stays. groupPos is a character key, so only chars[].settings have it.
local function FixDebuffLast()
    if RaidKitBuffsDB.debuffLastFixed then return end
    for _, st in pairs(RaidKitBuffsDB.chars) do
        local gp = type(st) == "table" and type(st.settings) == "table" and st.settings.groupPos
        local o, d = type(gp) == "table" and gp.other, type(gp) == "table" and gp.debuff
        if type(o) == "table" and type(d) == "table" and o.snap == "debuff" and o.side == "bottom"
            and d.snap == "unw" and d.side == "bottom" then
            o.snap, d.snap = "unw", "other"
        end
    end
    RaidKitBuffsDB.debuffLastFixed = true
end

local function MigrateAndEnsureRows()
    for _, st in pairs(RaidKitBuffsDB.chars) do
        if type(st) == "table" and type(st.settings) == "table" then ns:EnsureRows(st.settings) end
    end
    for _, p in pairs(RaidKitBuffsDB.profiles) do ns:EnsureRows(p.data) end
    FixDebuffLast()
    -- presets from 0.5.0 are no longer used once every profile has its rows again
    RaidKitBuffsDB.presets = nil
    RaidKitBuffsDB.nextPresetId = nil
end
ns.MigrateAndEnsureRows = MigrateAndEnsureRows
