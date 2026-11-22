-- RaidKit Buffs: BarGroups
-- Group frames: free and snapped positions, LayoutGroups, outlines, decorations (Decorate, UpdateMover, counter)
-- and creating the frames.
-- Shared names between the Bar*.lua files: Docs/Architecture.md "Leiste: Aufteilung in Dateien".

local _, ns = ...
local L = ns.L
local B, BS = ns.Bar, ns.BarState
local groupFrames, areaFrames, shownGroups, MOVER_PAD = B.groupFrames, B.areaFrames, B.shownGroups, B.MOVER_PAD
local FRAME_PAD, GNAME_H = B.FRAME_PAD, B.GNAME_H

------------------------------------------------------------------------
-- Groups: frames, positions, snapping, moving (2026-11-11, Docs/Plan-Groups.md, mockup: layoutGroups/dragGroup)
--
-- Every group frame is anchored to UIParent only (never to another group): positions are computed here.
-- A free group sits at its position (main: p.point, others: p.groupPos[id] = { x, y, pt }, offsets of a corner of
-- its outline in the group's scale, see AnchorPoint; before 2026-11-14 centre offsets). A snapped group (p.groupPos[id] = { snap = id, side = ... }) sits at that edge of
-- the other group's box and follows it when it moves or grows. Frames with secure buttons (the row groups and
-- "Unerwünschte Buffs") are never moved in combat; their layout waits for the end of the fight (layoutPending).
-- Positions below are in UIParent units, y up; a box is { left, top, width, height }.
------------------------------------------------------------------------

-- Shift+drag on any icon moves its group; there is no lock and no visible handle. While Shift is held over a
-- group a thin outline (the "mover") shows that it can be moved; with the options window open every group shows
-- it, and the empty space inside the outline can be dragged too (also an empty area with its preview).
-- WoW has no "Shift pressed over frame" event, so a throttled OnUpdate checks cursor and Shift.
-- Never in combat: the groups hold secure buttons.

-- 2026-11-11 (user: outlines looked shifted, unclear which group the others hang on): every group has the same
-- outline, exactly on its frame or MOVER_PAD around icons and names without one; the cap tint uses the same box.
-- The drag start decides what moves: the middle of a group moves the whole docked cluster (its root is dragged),
-- the edge (EDGE_W inside the outline) only this group (DetachGroup). Hovering shows it: what would move is yellow.

BS.layoutPending = false -- a secure group could not move in combat
BS.areaPreview = false   -- previews of the areas shown (outlines visible)
BS.drag = nil               -- group being dragged: { f, cx, cy, left, top, snap }

local BoxOf -- defined below (FreePoint uses it)
local NewGroupPoint -- defined below (FreePoint uses it)
local function GroupPos(id)
    return ns.profile.groupPos and ns.profile.groupPos[id]
end

-- Corner a free group grows away from (2026-11-14, user: a new, longer row made the bar grow from its middle to both
-- sides and under the minimap): rows left/right = top left/top right (columns down/up
-- were removed 2026-11-14). A free position is stored as the offset of that corner of the outline from the same corner of UIParent
-- (point table with OUTLINE as 6th value; groupPos { x, y, pt }). Older positions (centre of the frame) are read as
-- before and stored again in the new form by LayoutGroups, without moving the group.
local OUTLINE = "outline"
local function AnchorPoint(alignR)
    return alignR and "TOPRIGHT" or "TOPLEFT"
end

-- free position of a group as a point table (main: p.point; others: groupPos, default right of main)
local function FreePoint(id)
    local p = ns.profile
    if id == "main" then return p.point end
    local q = GroupPos(id)
    if q and q.x and q.pt then return { q.pt, "UIParent", q.pt, q.x, q.y, OUTLINE } end
    if q and q.x then return { "CENTER", "UIParent", "CENTER", q.x, q.y } end
    -- no position yet (new group, or loaded with "nur Reihen"): diagonally next to the main group (NewGroupPoint,
    -- 2026-11-15; before right of the main group's box, under the minimap for a bar at the top right)
    local pt = NewGroupPoint(id)
    if pt then return pt end
    return { "CENTER", "UIParent", "CENTER", 0, 0 }
end

-- offset of an anchor point from a box's top-left corner (x right, y down)
local function PointOffset(point, w, h)
    local x = point:find("LEFT") and 0 or point:find("RIGHT") and w or w / 2
    local y = point:find("TOP") and 0 or point:find("BOTTOM") and h or h / 2
    return x, y
end

-- moves a group frame so that its top-left corner is at X/Y (UIParent units, y up). Secure frames stay where
-- they are in combat (then LayoutGroups runs again after the fight).
local function PlaceTopLeft(f, X, Y)
    if f.secure and InCombatLockdown() then
        if f.posX ~= X or f.posY ~= Y then BS.layoutPending = true end
        return
    end
    f.posX, f.posY = X, Y
    local s = f:GetScale()
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", X / s, Y / s)
end

-- outline of a group: on the frame, or MOVER_PAD around the box without one (frame's own units)
local function MoverPad(f)
    return ns.FrameOn(f.g) and 0 or MOVER_PAD
end

-- free position: the anchor point of the frame (or of its outline, OUTLINE) at the given point of UIParent
-- (offsets in the frame's scale)
local function PlaceFree(f, pt)
    local s, W, H = f:GetScale(), f:GetWidth(), f:GetHeight()
    local uw, uh = UIParent:GetWidth(), UIParent:GetHeight()
    local rx, ry = PointOffset(pt[3] or "CENTER", uw, uh) -- from UIParent's top-left, y down
    local ax, ay = rx + (pt[4] or 0) * s, (uh - ry) + (pt[5] or 0) * s
    if pt[6] == OUTLINE and f.box then
        -- the outline's corner at ax/ay; the frame's top-left lies (b.l - pad, b.t - pad) before the outline's
        local b, pad = f.box, MoverPad(f)
        local px, py = PointOffset(pt[1], (b.w + 2 * pad) * s, (b.h + 2 * pad) * s)
        PlaceTopLeft(f, ax - px - (b.l - pad) * s, ay + py + (b.t - pad) * s)
        return
    end
    local px, py = PointOffset(pt[1] or "CENTER", W * s, H * s)
    PlaceTopLeft(f, ax - px, ay + py)
end

-- box of a group (icons, names, frame) in UIParent units
BoxOf = function(f)
    local s, b = f:GetScale(), f.box
    return (f.posX or 0) + b.l * s, (f.posY or 0) - b.t * s, b.w * s, b.h * s
end

-- remembers where a group is right now as its free position (a snap is released): the corner f.anchorPt of its
-- outline, as offset from the same corner of UIParent (2026-11-14; before the centre of the frame)
local function SetFree(f)
    local id = f.g.id
    local s, pt = f:GetScale(), f.anchorPt or "TOPLEFT"
    local l, t, w, h = BoxOf(f)
    local pad = MoverPad(f) * s
    local ox, oy = PointOffset(pt, w + 2 * pad, h + 2 * pad)
    local cx, cy = l - pad + ox, t + pad - oy -- the outline's corner, UIParent units, y up
    local uh = UIParent:GetHeight()
    local rx, ry = PointOffset(pt, UIParent:GetWidth(), uh)
    local x = math.floor((cx - rx) / s + 0.5)
    local y = math.floor((cy - (uh - ry)) / s + 0.5)
    ns.profile.groupPos = ns.profile.groupPos or {}
    if id == "main" then
        ns.profile.point = { pt, "UIParent", pt, x, y, OUTLINE }
        ns.profile.groupPos.main = nil
    else
        ns.profile.groupPos[id] = { x = x, y = y, pt = pt }
    end
end

-- true if the stored free position of a placed group is not yet in the form of SetFree for its current corner
-- (older centre position, or the orientation changed); LayoutGroups then stores it again where it is
local function NeedsResave(f)
    local id, want = f.g.id, f.anchorPt or "TOPLEFT"
    if id == "main" then
        local pt = ns.profile.point
        return type(pt) ~= "table" or pt[6] ~= OUTLINE or pt[1] ~= want
    end
    local q = GroupPos(id)
    return type(q) == "table" and q.x ~= nil and q.pt ~= want
end

-- outline rect of a group in UIParent units (left, top, width, height; y up). Since session 4b (2026-11-11) groups
-- are laid out by their outlines, so outlines of framed and unframed groups line up (user: "Unerwünschte" stuck out)
local function OutlineOf(f)
    local l, t, w, h = BoxOf(f)
    local pad = MoverPad(f) * f:GetScale()
    return l - pad, t + pad, w + 2 * pad, h + 2 * pad
end

-- = newGroupPos in the mockup (2026-11-15, user): a group without position goes diagonally next to the main group,
-- towards the middle of the screen (left and down for a bar at the top right), NEW_GROUP_GAP away; a shown group in
-- the way pushes it further towards the middle (no room on the screen there: below/above that group); kept on the
-- screen. Returned as point table (top-left corner of the outline), nil while the main group has no place yet.
local NEW_GROUP_GAP = 20
NewGroupPoint = function(id)
    local f, main = groupFrames[id] or areaFrames[id], BS.container
    if not (f and f.box and main and main.posX and f ~= main) then return nil end
    local gap, uw, uh = NEW_GROUP_GAP, UIParent:GetWidth(), UIParent:GetHeight()
    local ml, mt, mw, mh = OutlineOf(main)
    local _, _, w, h = OutlineOf(f)
    local toLeft, down = ml + mw / 2 > uw / 2, mt - mh / 2 > uh / 2
    local function ClampX(v) return math.min(math.max(v, 0), math.max(uw - w, 0)) end
    local function ClampY(v) return math.min(math.max(v, h), uh) end -- top edge, y up
    local X = ClampX(toLeft and (ml - gap - w) or (ml + mw + gap))
    local Y = ClampY(down and (mt - mh - gap) or (mt + gap + h))
    for _ = 1, 20 do
        local hit = false
        for _, e in ipairs(shownGroups) do
            local o = e.f
            if o ~= f and not o.empty and o.posX and o:IsShown() then
                local l, t, ow, oh = OutlineOf(o)
                if X < l + ow + gap and X + w + gap > l and Y - h < t + gap and Y + gap > t - oh then
                    local nx = toLeft and (l - gap - w) or (l + ow + gap)
                    if nx == ClampX(nx) then X = nx else Y = ClampY(down and (t - oh - gap) or (t + gap + h)) end
                    hit = true
                end
            end
        end
        if not hit then break end
    end
    local s = f:GetScale()
    return { "TOPLEFT", "UIParent", "BOTTOMLEFT", X / s, Y / s, OUTLINE }
end

-- moves a group so that the top-left corner of its outline is at X/Y
local function PlaceOutline(f, X, Y)
    local s, b, pad = f:GetScale(), f.box, MoverPad(f)
    PlaceTopLeft(f, X - (b.l - pad) * s, Y + (b.t - pad) * s)
end

-- gap between two snapped outlines (UIParent units): fixed since session 20 (before row spacing of "Alle Gruppen" + 2)
local function SnapGap()
    return ns.profileDefaults.rowSpacing + 2
end

-- orientation of a group: its own value, else the default "Rows right" (no "Automatic" since session 20, user).
-- Returns a key of ns.ORIENTATIONS.
function ns.EffectiveOrientation(g)
    if not g then return nil end
    return g.orientation or "hright"
end

-- How far the first icon line of a group lies below the top of its outline (UIParent units). Beside each other
-- (snapped left/right) groups line up their icons, not their outlines (2026-11-15, user: "Unwanted Buffs" has a
-- button frame 4 px around its icons, so its icons sat lower than those of Buffs & Cons). f.iconTop = top of the
-- first icon in f's units (y down), set where the icons are placed (Bar.lua BuildGroup, BarAreas.lua UpdateExtra);
-- nil (empty, placeholder): the top of the box.
local function IconInset(f)
    local b = f.box
    if not b then return 0 end
    local top = f.iconTop or b.t
    return (top - (b.t - MoverPad(f))) * f:GetScale()
end

-- = iconBottomInset in the mockup (2026-11-18): how far the last icon line ends above the bottom of the outline. Only
-- groups with rows (f.iconBottom, Bar.lua BuildGroup); areas and groups without icons: the padding of the outline
local function IconBottomInset(f)
    local b = f.box
    if not b or not f.iconBottom then return MoverPad(f) * f:GetScale() end
    return (b.t + b.h + MoverPad(f) - f.iconBottom) * f:GetScale()
end

-- = snapXY in the mockup. Top-left corner of an outline w x h at the given side of outline t. Eight snap points since
-- 2026-11-18 (user): every side has a start and an end. Above/below: "start" = left-aligned, "end" = right-aligned;
-- left/right of the target: "start" = first icon lines at the same height (dInset = IconInset(group) - IconInset(target),
-- 2026-11-15), "end" = last icon lines at the same height (dBottom = IconBottomInset(group) - IconBottomInset(target)).
local function SnapXY(tl, tt, tw, th, side, w, h, align, dInset, dBottom)
    local gap, isEnd = SnapGap(), align == "end"
    if side == "bottom" then return isEnd and (tl + tw - w) or tl, tt - th - gap end
    if side == "top" then return isEnd and (tl + tw - w) or tl, tt + h + gap end
    local y = isEnd and (tt - th + h - (dBottom or 0)) or (tt + (dInset or 0))
    if side == "right" then return tl + tw + gap, y end
    return tl - w - gap, y
end

-- = slotAlign in the mockup: the end of the side a snap q uses on target frame tf. Stored since 2026-11-18 (q.align);
-- older snaps: above/below like the target's rows (right-aligned = "end"), beside it the top ("start")
local function SlotAlign(q, tf)
    if type(q) ~= "table" then return "start" end
    if q.align == "start" or q.align == "end" then return q.align end
    if (q.side == "bottom" or q.side == "top") and tf and tf.alignR then return "end" end
    return "start"
end

-- = layoutGroups() in the mockup: free groups first, snapped ones after their target. A target that is not shown
-- (an empty area) passes its own snap on; a loop falls back to the free position. The dragged group is placed by
-- DragUpdate.
local function LayoutGroups()
    if not BS.container then return end
    BS.layoutPending = false
    local combat = InCombatLockdown()
    local shown = {}
    for _, e in ipairs(shownGroups) do
        -- a secure group that never got a position cannot get one in combat: treat it as not shown
        if not e.f.empty and not (combat and e.f.secure and e.f.posX == nil) then shown[e.g.id] = e.f end
    end
    -- out of combat an empty secure group ("Unerwünschte Buffs") still goes to its place (review 2026-11-11):
    -- its first buff may come in combat, when it can no longer move
    local function Wanted(f)
        return not f.empty or (f.secure and not combat)
    end
    -- id = target of a group snapped on side. A hidden target passes on its place: the group goes where the last hidden
    -- group of the chain would be, on that group's side of the shown one (2026-11-18, user: a group snapped below the
    -- empty "Unerwünschte Buffs", which hang left of Buffs & Cons, went below Buffs & Cons instead of left of it).
    -- q0 = the snap of the group. Returns the shown target and the snap whose side and end count (q0 or the last hidden
    -- one), or nil + the hidden group whose free position to take.
    local function Resolve(q0)
        local seen, cur, q = {}, q0.snap, q0
        while cur and not shown[cur] and not seen[cur] do
            seen[cur] = true
            local n = GroupPos(cur)
            if not n or not n.snap then return nil, cur end -- free hidden group: take its free position
            cur, q = n.snap, n
        end
        if cur and shown[cur] then return cur, nil, q end
        return nil, nil
    end
    local placed, progress = {}, true
    local docked = {} -- id -> side it is snapped on (separator)
    while progress do
        progress = false
        for _, e in ipairs(shownGroups) do
            local id, f = e.g.id, e.f
            if not placed[id] and Wanted(f) then
                local q = GroupPos(id)
                if BS.drag and BS.drag.f == f then
                    placed[id] = true -- placed by the drag
                    progress = true
                elseif not q and id ~= "main" then
                    -- nothing here: no position yet (new group): placed last, next to the others (NewGroupPoint)
                elseif not q or not q.snap then
                    PlaceFree(f, FreePoint(id))
                    -- older centre position or other orientation: store the corner where the group is now (2026-11-14)
                    if not combat and f.posX and f.box and NeedsResave(f) then SetFree(f) end
                    placed[id] = true
                    progress = true
                else
                    local tid, freeId, sq = Resolve(q)
                    if not tid then
                        PlaceFree(f, FreePoint(freeId or id))
                        placed[id] = true
                        progress = true
                    elseif placed[tid] then
                        local tf = shown[tid]
                        local tl, tt, tw, th = OutlineOf(tf)
                        local _, _, w, h = OutlineOf(f)
                        PlaceOutline(f, SnapXY(tl, tt, tw, th, sq.side, w, h, SlotAlign(sq, tf), IconInset(f) - IconInset(tf),
                            IconBottomInset(f) - IconBottomInset(tf)))
                        docked[id] = sq.side
                        placed[id] = true
                        progress = true
                    end
                end
            end
        end
    end
    for _, e in ipairs(shownGroups) do
        if not placed[e.g.id] and Wanted(e.f) then
            PlaceFree(e.f, FreePoint(e.g.id)) -- loop, or a new group without position: free
            -- a new group keeps the place it gets with its first row (2026-11-15), so it never jumps when the others
            -- change; as an empty placeholder it is placed anew each time, so its real size counts once rows come in
            if not combat and not BS.drag and not e.f.placeholder and e.g.id ~= "main" and not GroupPos(e.g.id)
                and e.f.posX then
                SetFree(e.f)
            end
        end
    end
    -- separators (2026-11-14): only on groups snapped to another one that is shown
    for _, e in ipairs(shownGroups) do
        B.PlaceSeparator(e.f, shown[e.g.id] and docked[e.g.id] or nil)
    end
end


-- box decorations of a group: optional frame, group name, cap tint, outline (all relative to its top-left)
local function PlaceRect(r, f, l, t, w, h)
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", f, "TOPLEFT", l, -t)
    r:SetSize(math.max(w, 1), math.max(h, 1))
end
local function PlaceEdges(edges, f, l, t, w, h)
    PlaceRect(edges[1], f, l, t, w, 1)
    PlaceRect(edges[2], f, l, t + h - 1, w, 1)
    PlaceRect(edges[3], f, l, t, 1, h)
    PlaceRect(edges[4], f, l + w - 1, t, 1, h)
end
-- box = icons and names (lw/rw = names left/right of the icons, w/h = icon block); frame padding and group name
-- come on top. main: the tint keeps the old box (outline, 8 px around the rows).
-- counter "Buffs n/32" (session 4b): in the name line of the main group, on the side away from the group name
-- (right, or left when the rows end at the right edge)
-- Session 4c (user 2026-11-11): the place does not fit either; hidden until it becomes an option per group that the
-- user switches on himself (Roadmap). Text, colour and tooltip keep being updated.
local SHOW_COUNTER = false
local function PlaceCounter()
    local f = BS.container
    local c, hit = f and f.counter, f and f.counterHit
    if not c or not f.box then return end
    c:SetShown(SHOW_COUNTER)
    hit:SetShown(SHOW_COUNTER)
    local b = f.box
    c:ClearAllPoints()
    hit:ClearAllPoints()
    if f.alignR then
        c:SetPoint("TOPLEFT", f, "TOPLEFT", b.l, -(b.t + 1))
        c:SetJustifyH("LEFT")
        hit:SetPoint("TOPLEFT", c, "TOPLEFT", 0, 1)
    else
        c:SetPoint("TOPRIGHT", f, "TOPLEFT", b.l + b.w, -(b.t + 1))
        c:SetJustifyH("RIGHT")
        hit:SetPoint("TOPRIGHT", c, "TOPRIGHT", 0, 1)
    end
end


local function Decorate(f, l, t, w, h)
    local g = f.g
    local fp = ns.FrameOn(g) and FRAME_PAD or 0
    local ownName = ns.GEff(g, "showName") and not g.area -- inherits from "Alle Gruppen" (2026-11-14)
    -- the main group keeps its name line for the counter (session 4b), only while it is shown (SHOW_COUNTER)
    local nameH = (ownName or (f == BS.container and SHOW_COUNTER)) and GNAME_H or 0
    -- 2026-11-15 (user, = buildGroup in the mockup): the name line lies inside the frame, the tint and the visible
    -- outline, so no part of the box is left out of the visible outline any more (VisibleOutline in BarMove.lua).
    -- Before (session 4b until 2026-11-15) the name stood above the frame and the outline left that line out.
    f.nameH = 0
    local fo = B.FrameOutset(g) -- the border lies inside the box (2026-11-15), the background stays at fp
    f.box = { l = l - fp - fo, t = t - fp - fo - nameH, w = w + 2 * (fp + fo), h = h + 2 * (fp + fo) + nameH }
    local show = not f.empty
    B.PlaceFrame(f, show and ns.FrameOn(g), l - fp, t - fp - nameH, w + 2 * fp, h + 2 * fp + nameH) -- style (2026-11-14)
    f.nameLabel:SetShown(show and ownName and true or false)
    if ownName then
        -- in the line above the rows, flush with the edge of the rows (names included) on the side of the alignment
        local y = -(t - nameH - math.floor(fp / 2 + 0.5))
        f.nameLabel:SetText(ns.GroupDisplayName(g))
        f.nameLabel:ClearAllPoints()
        -- the name's own alignment since 2026-11-15 (user; before = the group's): left, centre or right
        local na = ns.NameAlign(g, f.alignR)
        if na == "right" then
            f.nameLabel:SetPoint("TOPRIGHT", f, "TOPLEFT", l + w, y)
        elseif na == "center" then
            f.nameLabel:SetPoint("TOP", f, "TOPLEFT", l + w / 2, y)
        else
            f.nameLabel:SetPoint("TOPLEFT", f, "TOPLEFT", l, y)
        end
    end
    -- outline and tint (2026-11-11): the same for every group, on the frame or MOVER_PAD around the box (name included)
    local b, pad = f.box, MoverPad(f)
    f.mover:ClearAllPoints()
    f.mover:SetPoint("TOPLEFT", f, "TOPLEFT", b.l - pad, -(b.t - pad))
    f.mover:SetSize(b.w + 2 * pad, b.h + 2 * pad)
    PlaceRect(f.capTint, f, b.l - pad, b.t - pad, b.w + 2 * pad, b.h + 2 * pad)
    if f == BS.container then PlaceCounter() end
end

-- placeholder of an empty group (2026-11-15): text width for its size (BuildGroup), shown while not f.empty
local function PlaceholderTextWidth(f, g)
    f.phText:SetText(L["%s (empty)"]:format(ns.GroupDisplayName(g)))
    return f.phText:GetStringWidth()
end
local function UpdatePlaceholder(f)
    local on = f.placeholder and not f.empty and true or false
    f.phBg:SetShown(on)
    f.phText:SetShown(on)
end

-- What a group draws right now (icons, names, the button frame of "Unwanted Buffs"): left, top, right, bottom in
-- UIParent units (y up), nil while nothing is shown. Without the outline, the click button of "Unwanted Buffs" and
-- the previews (they cover the whole reserved width). Used for the "Demo-Modus" text (2026-11-15).
local function ShownRect(gf)
    local l, t, r, b
    local k = gf:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local function Add(o)
        if not (o and o:IsShown()) then return end
        local ol, ot, orr, ob = o:GetLeft(), o:GetTop(), o:GetRight(), o:GetBottom()
        if not (ol and ot and orr and ob) then return end
        ol, ot, orr, ob = ol * k, ot * k, orr * k, ob * k
        l, r = math.min(l or ol, ol), math.max(r or orr, orr)
        t, b = math.max(t or ot, ot), math.min(b or ob, ob)
    end
    for _, c in ipairs({ gf:GetChildren() }) do
        if c ~= gf.mover and c ~= gf.button and c ~= gf.preview then Add(c) end
    end
    if gf.unwBox then Add(gf.unwBox.bg) end
    Add(gf.nameLabel)
    Add(gf.label)
    for _, lb in ipairs(gf.labels or {}) do Add(lb) end
    return l, t, r, b
end

local function UpdateMover()
    if not BS.container then return end
    local combat = InCombatLockdown()
    -- options window open = editing: outlines and previews stay visible. Not during the demo (user 2026-11-10:
    -- the demo shows the bar as it really looks); Shift over a group still shows its outline.
    local editing = BS.drag ~= nil or (ns.optionsOpen and not ns.demo)
    local over = (not combat and not BS.drag and (editing or IsShiftKeyDown())) and B.CursorOverGroup() or nil
    -- what would move (hover) or moves (drag), 2026-11-11: middle = the docked cluster, edge = the group alone
    local hot = {}
    if BS.drag then
        hot = B.ClusterOf(BS.drag.f.g.id)
    elseif over then
        local x, y = B.CursorUI()
        if B.OnEdge(over, x, y) then hot[over.g.id] = true else hot = B.ClusterOf(over.g.id) end
    end
    for _, e in ipairs(shownGroups) do
        local f = e.f
        local show = not combat and f:IsShown() and not f.empty and (editing or hot[e.g.id])
        f.mover:SetShown(show and true or false)
        -- editing: the empty space inside the outline can be dragged too (the icons lie above it).
        -- Shift over a group (2026-11-14, user): the outline takes the mouse too, so Shift+right-click on the frame
        -- or between the icons opens the options (before only the icons did, a visible frame invited misses)
        f.mover:EnableMouse(show and (editing or IsShiftKeyDown()) and true or false)
        local r, g, b = 0.1, 0.6, 1
        if hot[e.g.id] then
            if BS.drag and BS.drag.snap then r, g, b = 0.25, 1, 0.25 else r, g, b = 1, 0.82, 0 end
        end
        if f.mover.color ~= r + g * 2 + b * 4 then
            f.mover.color = r + g * 2 + b * 4
            for _, edge in ipairs(f.mover.edges) do edge:SetColorTexture(r, g, b, 0.8) end
        end
    end
    -- the secure button of "Unerwünschte Buffs" takes no clicks while editing: dragging the area there must not
    -- remove every unwanted buff
    local unw = areaFrames.unw
    if unw and unw.button and not combat then unw.button:EnableMouse(not editing) end
    -- "Demo-Modus" in big letters next to the bar while the demo runs (user 2026-11-10). It goes on the side
    -- with more screen room: left of a bar in the right half, else right of it, vertically centred on the
    -- outline box of Buffs & Cons. Since 2026-11-15 (user: "Unwanted Buffs" docked on the left covered it) 10 px beyond
    -- every shown group whose outline reaches into the line of the text, not only beyond Buffs & Cons.
    local dl = BS.container.demoLabel
    if dl then
        local on = ns.demo ~= nil and BS.container:IsShown() and BS.container.box ~= nil
        dl:SetShown(on and true or false)
        if on then
            local cx = BS.container:GetCenter()
            local leftSide = cx and cx * BS.container:GetScale() > UIParent:GetWidth() / 2
            -- what is really drawn, not the outline (2026-11-15, user: the text ended up in the middle of the screen; the
            -- outline of "Unwanted Buffs" keeps room for every buff of its list and is mostly empty)
            local ml, mt, mr, mb = ShownRect(BS.container)
            if not ml then
                local w, h
                ml, mt, w, h = OutlineOf(BS.container)
                mr, mb = ml + w, mt - h
            end
            local cy = (mt + mb) / 2
            local ks = BS.container:GetEffectiveScale() / UIParent:GetEffectiveScale() -- units of the text -> UIParent
            local half = (dl:GetStringHeight() or 20) * ks / 2 + 4
            local left, right = ml, mr
            for _, e in ipairs(shownGroups) do
                local gf = e.f
                if gf ~= BS.container and gf:IsShown() and not gf.empty then
                    local l, t, r, b = ShownRect(gf)
                    if l and t > cy - half and b < cy + half then
                        left, right = math.min(left, l), math.max(right, r)
                    end
                end
            end
            local k = 1 / ks -- UIParent units -> units of the text
            -- no room on that side of the screen: the other side
            local tw = (dl:GetStringWidth() or 120) * ks
            if leftSide and left - 10 - tw < 0 then leftSide = false
            elseif not leftSide and right + 10 + tw > UIParent:GetWidth() then leftSide = true end
            dl:ClearAllPoints()
            if leftSide then
                dl:SetPoint("RIGHT", UIParent, "BOTTOMLEFT", (left - 10) * k, cy * k)
            else
                dl:SetPoint("LEFT", UIParent, "BOTTOMLEFT", (right + 10) * k, cy * k)
            end
        end
    end
    -- together with the outlines every area shows its preview box (also empty ones, so they can be dragged)
    local pv = not combat and BS.container:IsShown() and (editing or over ~= nil) and true or false
    if pv ~= BS.areaPreview then
        BS.areaPreview = pv
        if B.UpdateExtra then B.UpdateExtra() end
    end
end

-- Draw layer of every group (2026-11-12): "BACKGROUND", the lowest. Before "LOW" (2026-11-10, ItemRack's menus must
-- always lie above the bar), but ItemRack's minimap menu lives inside the Minimap and is drawn with its layer, which
-- is "LOW" too, so the bar covered it in the raid. RaidKit Buffs does not change ItemRack (user). Below "BACKGROUND"
-- there is only the game world.
local BAR_STRATA = "BACKGROUND"

-- Shift+right-click anywhere on a group opens/closes the options (2026-11-14): outline, area icons, the unwanted
-- button. The row buttons do the same in their PostClick. Returns true when it handled the click.
local function ShiftOptions(button)
    if button == "RightButton" and IsShiftKeyDown() then
        ns:ToggleOptions()
        return true
    end
end

local function CreateGroupFrame(name)
    local f = CreateFrame("Frame", name, UIParent)
    -- far back in the draw order (BAR_STRATA). Every child inherits the strata; the options window is its own frame.
    f:SetFrameStrata(BAR_STRATA)
    f:SetSize(1, 1)
    f.labels = {} -- row names
    -- optional frame like the "Unerwünschte Buffs" button (2026-11-11); its look comes from the style "frame" since
    -- 2026-11-14 (PlaceFrame): colour (frameBg), a texture pattern on top (frameTex) or a gradient (frameGrad),
    -- border as rings of 4 edges each (frameRings, built on demand)
    f.frameBg = f:CreateTexture(nil, "BACKGROUND", nil, -2)
    f.frameBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    f.frameTex = f:CreateTexture(nil, "BACKGROUND", nil, -1)
    f.frameGrad = f:CreateTexture(nil, "BACKGROUND", nil, -1)
    f.frameGrad:SetTexture("Interface\\Buttons\\WHITE8X8")
    f.frameRings = {}
    f.frameEdges = {} -- all ring edges (shown/hidden together)
    -- background tint by free buff slots (2026-11-10, CapLevel): a plain texture, may change in combat
    f.capTint = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    f.capTint:Hide()
    -- option "Trenner anzeigen" (2026-11-14): line on the docked side, placed by LayoutGroups (PlaceSeparator)
    f.sep = f:CreateTexture(nil, "BORDER")
    f.sep:Hide()
    f.nameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.nameLabel:SetTextColor(0.78, 0.78, 0.82)
    f.nameLabel:Hide()
    -- placeholder of an empty group while editing (2026-11-15): light blue box with "Name (empty)" (UpdatePlaceholder)
    f.phBg = f:CreateTexture(nil, "BACKGROUND", nil, 2)
    f.phBg:SetColorTexture(0.1, 0.6, 1, 0.12)
    f.phBg:SetAllPoints(f)
    f.phBg:Hide()
    f.phText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.phText:SetTextColor(0.47, 0.75, 1)
    f.phText:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.phText:Hide()
    -- outline (1 px edges); takes the mouse only while editing (drag on the empty space of the group)
    local mv = CreateFrame("Frame", nil, f)
    -- the edge can be grabbed a little outside the line too (session 4b, user: edge should work earlier)
    mv:SetHitRectInsets(-5, -5, -5, -5)
    mv:SetFrameLevel(f:GetFrameLevel() + 1)
    mv:EnableMouse(false)
    mv:RegisterForDrag("LeftButton")
    mv:SetScript("OnDragStart", function() B.StartMove(f) end)
    mv:SetScript("OnDragStop", function() B.StopMove() end)
    mv:SetScript("OnMouseUp", function(_, button) ShiftOptions(button) end)
    mv:Hide()
    mv.edges = {}
    local function Edge(p1, p2, w, h)
        local e = mv:CreateTexture(nil, "OVERLAY")
        e:SetColorTexture(0.1, 0.6, 1, 0.8)
        e:SetPoint(p1, mv, p1, 0, 0)
        e:SetPoint(p2, mv, p2, 0, 0)
        if w then e:SetWidth(w) end
        if h then e:SetHeight(h) end
        mv.edges[#mv.edges + 1] = e
    end
    Edge("TOPLEFT", "TOPRIGHT", nil, 1)
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
    Edge("TOPLEFT", "BOTTOMLEFT", 1, nil)
    Edge("TOPRIGHT", "BOTTOMRIGHT", 1, nil)
    f.mover = mv
    f.box = { l = 0, t = 0, w = 1, h = 1 }
    return f
end

local function CreateContainer()
    BS.container = CreateGroupFrame("RaidKitBuffsFrame")
    groupFrames.main = BS.container

    -- "Demo-Modus" label (2026-11-10), placed in UpdateMover; a child of the container, so it moves with it
    BS.container.demoLabel = BS.container:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    BS.container.demoLabel:SetText(L["Demo mode"])
    BS.container.demoLabel:SetTextColor(1, 0.5, 0.1)
    BS.container.demoLabel:Hide()

    -- Remaining durations every 0.5 s, outline every 0.05 s, a dragged group every frame
    local timerElapsed, moverElapsed = 0, 0
    BS.container:SetScript("OnUpdate", function(_, elapsed)
        B.NotePress(IsMouseButtonDown("LeftButton"))
        if BS.drag then B.DragUpdate() end
        moverElapsed = moverElapsed + elapsed
        if moverElapsed >= 0.05 then
            moverElapsed = 0
            UpdateMover()
        end
        timerElapsed = timerElapsed + elapsed
        if timerElapsed >= 0.5 then
            timerElapsed = 0
            -- weapon enchants have no event when they run out or Windfury comes and goes: poll them
            if ns:ScanWeapon() then ns:UpdateAll() else ns:UpdateTimers() end
        end
    end)
end

-- shared with the other Bar*.lua files
B.GroupPos = GroupPos
B.AnchorPoint = AnchorPoint
B.MoverPad = MoverPad
B.SetFree = SetFree
B.OutlineOf = OutlineOf
B.PlaceOutline = PlaceOutline
B.SnapGap = SnapGap
B.SnapXY = SnapXY
B.IconInset = IconInset
B.IconBottomInset = IconBottomInset
B.SlotAlign = SlotAlign
B.LayoutGroups = LayoutGroups
B.PlaceRect = PlaceRect
B.PlaceCounter = PlaceCounter
B.Decorate = Decorate
B.PlaceholderTextWidth = PlaceholderTextWidth
B.UpdatePlaceholder = UpdatePlaceholder
B.UpdateMover = UpdateMover
B.ShiftOptions = ShiftOptions
B.CreateGroupFrame = CreateGroupFrame
B.CreateContainer = CreateContainer
