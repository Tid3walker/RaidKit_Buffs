-- RaidKit Buffs: BarMove
-- Moving groups with Shift+drag: hover, edge or middle, snapping, detaching, turning a cluster around.
-- Shared names between the Bar*.lua files: Docs/Architecture.md "Leiste: Aufteilung in Dateien".

local _, ns = ...
local L = ns.L
local B, BS = ns.Bar, ns.BarState
local shownGroups, HOVER_PAD, EDGE_W, SNAP_DIST = B.shownGroups, B.HOVER_PAD, B.EDGE_W, B.SNAP_DIST

local function CursorUI()
    local x, y = GetCursorPosition()
    local s = UIParent:GetEffectiveScale()
    return x / s, y / s
end

-- the visible outline (f.mover): OutlineOf without the name line above the frame (session 4c: the edge band must
-- start at the line the user sees, not at the group name above it)
local function VisibleOutline(f)
    local l, t, w, h = B.OutlineOf(f)
    local nh = (f.nameH or 0) * f:GetScale()
    return l, t - nh, w, h - nh
end

-- distance of a point to a rect (0 inside)
local function RectDist(x, y, l, t, w, h)
    local dx = math.max(l - x, 0, x - (l + w))
    local dy = math.max(y - t, 0, (t - h) - y)
    return math.sqrt(dx * dx + dy * dy)
end

-- = groupAt() in the mockup: the shown group at the point, or nil. A group whose visible outline contains the point
-- wins, else the nearest one within HOVER_PAD (session 4c: always the nearest, never just the first in the list)
local function GroupAt(x, y)
    local best, bestD
    for _, e in ipairs(shownGroups) do
        local f = e.f
        if f:IsShown() and not f.empty and f.box and f.posX then
            local d = RectDist(x, y, VisibleOutline(f))
            if d == 0 then return f end
            if d <= HOVER_PAD and (not bestD or d < bestD) then best, bestD = f, d end
        end
    end
    return best
end
local function CursorOverGroup()
    return GroupAt(CursorUI())
end

-- true if the point lies in the edge band of the group's visible outline (or outside it)
local function OnEdge(f, x, y)
    local l, t, w, h = VisibleOutline(f)
    return x < l + EDGE_W or x > l + w - EDGE_W or y > t - EDGE_W or y < t - h + EDGE_W
end

-- = rootOf() in the mockup: the free group at the end of the snap chain of id
local function RootOf(id)
    local seen, cur = { [id] = true }, id
    while true do
        local q = B.GroupPos(cur)
        if type(q) ~= "table" or not q.snap or seen[q.snap] then return cur end
        cur = q.snap
        seen[cur] = true
    end
end

-- ids of every shown group with the same root (= what a drag from the middle moves)
local function ClusterOf(id)
    local r, set = RootOf(id), {}
    for _, e in ipairs(shownGroups) do
        if RootOf(e.g.id) == r then set[e.g.id] = true end
    end
    return set
end

-- shown and placed frame of a group, or nil
local function ShownFrame(id)
    for _, e in ipairs(shownGroups) do
        if e.g.id == id and e.f.posX and not e.f.empty then return e.f end
    end
end

-- = detachGroup() in the mockup: f comes loose and stays where it is; what hung on it stays where it is too, free
-- (session 4c; before it took over f's snap and jumped). Not shown: default place. Returns true if anything changed.
local function DetachGroup(f)
    local id = f.g.id
    ns.profile.groupPos = ns.profile.groupPos or {}
    local gp = ns.profile.groupPos
    local mine = gp[id]
    local snap = type(mine) == "table" and mine.snap and { snap = mine.snap, side = mine.side } or nil
    local changed = snap ~= nil
    local hangers = {}
    for k, q in pairs(gp) do
        if k ~= id and type(q) == "table" and q.snap == id then hangers[#hangers + 1] = k end
    end
    for _, k in ipairs(hangers) do
        changed = true
        -- session 4c (user): what hung on f stays where it is (free), it no longer jumps into f's place
        local hf = ShownFrame(k)
        if hf then
            B.SetFree(hf)
        else
            gp[k] = nil
        end
    end
    B.SetFree(f)
    return changed
end

-- = reroot() in the mockup: id becomes the root of its cluster by turning the snaps between id and the old root
-- around (B below A becomes A above B). Then id can snap to another group while the rest keeps hanging on it.
local OPPOSITE = { bottom = "top", top = "bottom", left = "right", right = "left" }
local function Reroot(id)
    local gp = ns.profile.groupPos
    local chain, seen = { id }, { [id] = true }
    while true do
        local q = gp[chain[#chain]]
        if type(q) ~= "table" or not q.snap or seen[q.snap] then break end
        chain[#chain + 1] = q.snap
        seen[q.snap] = true
    end
    local sides, aligns = {}, {}
    for i = 1, #chain - 1 do sides[i], aligns[i] = gp[chain[i]].side, gp[chain[i]].align end
    -- the end stays (2026-11-18): B below A on the left = A above B on the left
    for i = #chain - 1, 1, -1 do
        gp[chain[i + 1]] = { snap = chain[i], side = OPPOSITE[sides[i]] or "bottom", align = aligns[i] }
    end

end

-- drag start (2026-11-11): edge = only this group, middle = the root of its cluster (the rest follows it).
-- Session 4b: every group of the dragged cluster may snap (members = their outlines at the start).
-- where the left button went down (session 4c, user: grabbing the edge was unreliable, above all for a group
-- between two others). OnDragStart fires only after a few pixels of movement and on whichever frame took the click
-- (neighbouring outlines overlap with their widened hit rects), so group and zone come from the press point
-- instead: polled every frame in the container's OnUpdate (no hooks on secure buttons needed).
local press -- { x, y, t }
local function NotePress(down)
    if down and not press then
        local x, y = CursorUI()
        press = { x = x, y = y, t = GetTime() }
    elseif not down then
        press = nil
    end
end

B.StartMove = function(f)
    if InCombatLockdown() or not f or not f.box or not f.posX then return end
    local cx, cy = CursorUI()
    if press and GetTime() - press.t < 2 then
        cx, cy = press.x, press.y -- the drag follows the cursor from the press point
        f = GroupAt(cx, cy) or f
    end
    local target = f
    if OnEdge(f, cx, cy) then
        if DetachGroup(f) then ns:Print(L["%s detached, only this group is moved."], ns.GroupDisplayName(f.g)) end
    else
        target = ShownFrame(RootOf(f.g.id))
        if not target then -- root not shown: like the edge
            target = f
            DetachGroup(f)
        end
        B.SetFree(target) -- the root is free already; keeps its place
    end
    B.LayoutGroups()
    local members = {}
    for id in pairs(ClusterOf(target.g.id)) do
        local mf = ShownFrame(id)
        if mf then members[id] = { B.OutlineOf(mf) } end
    end
    members[target.g.id] = { B.OutlineOf(target) }
    BS.drag = { f = target, cx = cx, cy = cy, members = members }
end

-- every frame while dragging (session 4b, user: snapping must not depend on where the drag started): every group of
-- the dragged cluster is tested against the four sides of every other shown group. A side counts when the gap
-- is below SNAP_DIST and the two outlines overlap along that side (no need to hit the corner). The nearest one
-- wins; the cluster is shifted so that this member sits exactly there.
local SIDES = { "bottom", "top", "right", "left" }

-- = sideTaken in the mockup (2026-11-15, user): a side of a group is taken when another group hangs there, or when
-- the group itself hangs on that side of another one (below X = its top is taken). Groups not shown count too (an
-- empty area comes back later); groups of the dragged cluster do not. Only free sides take a snap.
-- Since 2026-11-18 (user: eight snap points) per end of a side: align "start"/"end" (B.SlotAlign, tf = target frame).
-- The side a group itself hangs with is taken at both ends. A buff area above or below takes the whole side (its lines
-- reach the width of the group it hangs on), so it needs both ends free (mid = the snapping group).
local function IsArea(id)
    local g = ns.GroupById(ns.profile, id)
    return g ~= nil and g.area ~= nil
end
local function SideTaken(id, side, members, align, tf, mid)
    local gp = ns.profile.groupPos or {}
    local vert = side == "bottom" or side == "top"
    local any = false
    for k, q in pairs(gp) do
        if type(q) == "table" and q.snap == id and q.side == side and not members[k] then
            any = true
            if (vert and IsArea(k)) or B.SlotAlign(q, tf) == align then return true end
        end
    end
    local own = gp[id]
    if type(own) == "table" and own.snap ~= nil and not members[own.snap] and OPPOSITE[own.side] == side then return true end
    return vert and any and IsArea(mid)
end

local function DragUpdate()
    if not BS.drag then return end
    if not IsMouseButtonDown("LeftButton") then B.StopMove() return end -- OnDragStop may get lost
    local x, y = CursorUI()
    local dx, dy = x - BS.drag.cx, y - BS.drag.cy
    local best
    for mid, r in pairs(BS.drag.members) do
        local ml, mt, mw, mh = r[1] + dx, r[2] + dy, r[3], r[4]
        for _, e in ipairs(shownGroups) do
            local tf = e.f
            if not BS.drag.members[e.g.id] and not tf.empty and tf:IsShown() and tf.posX then
                local tl, tt, tw, th = B.OutlineOf(tf)
                for _, side in ipairs(SIDES) do
                    local vert = side == "bottom" or side == "top"
                    -- which end (2026-11-18, user): the half of the side the dragged group's middle is over; that end
                    -- taken = the other one, both taken = none (only free ends, 2026-11-15)
                    local want
                    if vert then
                        want = (ml + mw / 2 < tl + tw / 2) and "start" or "end"
                    else
                        want = (mt - mh / 2 > tt - th / 2) and "start" or "end" -- y up: higher = start
                    end
                    local other = want == "start" and "end" or "start"
                    local align
                    if not SideTaken(e.g.id, side, BS.drag.members, want, tf, mid) then
                        align = want
                    elseif not SideTaken(e.g.id, side, BS.drag.members, other, tf, mid) then
                        align = other
                    end
                    if align then
                        -- beside the target the icons line up (2026-11-15, B.IconInset; bottom lines: B.IconBottomInset)
                        local mf = ShownFrame(mid)
                        local dI = mf and (B.IconInset(mf) - B.IconInset(tf)) or 0
                        local dB = mf and (B.IconBottomInset(mf) - B.IconBottomInset(tf)) or 0
                        local sx, sy = B.SnapXY(tl, tt, tw, th, side, mw, mh, align, dI, dB)
                        local d, overlap
                        if vert then
                            d = math.abs(sy - mt)
                            overlap = ml < tl + tw and ml + mw > tl
                        else
                            d = math.abs(sx - ml)
                            overlap = mt - mh < tt and mt > tt - th
                        end
                        if overlap and d < SNAP_DIST and (not best or d < best.dist) then
                            best = { member = mid, id = e.g.id, side = side, align = align, dist = d, ox = sx - ml, oy = sy - mt }
                        end
                    end
                end
            end
        end
    end
    BS.drag.snap = best
    local r = BS.drag.members[BS.drag.f.g.id]
    local X, Y = r[1] + dx, r[2] + dy
    if best then X, Y = X + best.ox, Y + best.oy end
    B.PlaceOutline(BS.drag.f, X, Y)
    B.SetFree(BS.drag.f)
    B.LayoutGroups()
end

B.StopMove = function()
    if not BS.drag then return end
    local d = BS.drag
    BS.drag = nil
    if d.snap then
        -- the member that snapped becomes the root of the cluster, then hangs on the target (session 4b)
        local s = d.snap
        if s.member ~= d.f.g.id then Reroot(s.member) end
        ns.profile.groupPos = ns.profile.groupPos or {}
        ns.profile.groupPos[s.member] = { snap = s.id, side = s.side, align = s.align } -- + the end (2026-11-18)
        local mg, tg = ns.GroupById(ns.profile, s.member), ns.GroupById(ns.profile, s.id)
        ns:Print(L["%s snapped %s %s."], mg and ns.GroupDisplayName(mg) or "?", ns.SlotName(s.side, s.align), tg and ns.GroupDisplayName(tg) or "?")
    end
    -- rebuild: a buff area's line width follows the group it hangs on
    ns:RequestRebuild()
    if ns.RefreshOptions then ns:RefreshOptions() end
end

-- stores where group id stands right now as its free position, without message or rebuild (2026-11-20, deleting
-- "Buffs & Cons": the next group takes the main group's place where it stands). false = not shown
function ns:FreezeGroupPos(id)
    if InCombatLockdown() then return false end
    for _, e in ipairs(shownGroups) do
        if e.g.id == id and e.f.posX then B.SetFree(e.f) return true end
    end
    return false
end

-- "Lösen" in the options: the group keeps its place but no longer hangs on another one
function ns:SetGroupFree(id)
    if InCombatLockdown() then return end
    local found
    for _, e in ipairs(shownGroups) do
        if e.g.id == id and e.f.posX then B.SetFree(e.f) found = true end
    end
    if not found then
        -- not shown (no visible row): free at its default place
        if ns.profile.groupPos then ns.profile.groupPos[id] = nil end
        ns:Print(L["The group is not visible right now; it is now free, to the right of the first group."])
    end
    ns:RequestRebuild()
    if ns.RefreshOptions then ns:RefreshOptions() end
end

-- shared with the other Bar*.lua files
B.CursorUI = CursorUI
B.CursorOverGroup = CursorOverGroup
B.OnEdge = OnEdge
B.ClusterOf = ClusterOf
B.NotePress = NotePress
B.DragUpdate = DragUpdate
