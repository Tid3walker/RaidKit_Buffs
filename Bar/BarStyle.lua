-- RaidKit Buffs: BarStyle
-- Look of a group: frame background and border (PlaceFrame, FrameOutset), separators between docked groups,
-- icon borders.
-- Shared names between the Bar*.lua files: Docs/Architecture.md "Leiste: Aufteilung in Dateien".

local _, ns = ...
local B = ns.Bar

-- Option "Trenner anzeigen" (2026-11-14, user): nil = default, on for "Sonstige Buffs" and "Debuffs"
local function SeparatorOn(g)
    if not g then return false end
    if g.separator ~= nil then return g.separator end
    return g.area == "other" or g.area == "debuff"
end
ns.SeparatorOn = SeparatorOn

-- = placeSeparator() in the mockup: a 1 px line in the middle of the gap on the side where the group is docked
-- (side = where f sits: "bottom" = below its target, so the line lies above f). Debuffs keep the red tint of their
-- old divider (extra.debLine, 2026-11-11, replaced by this). A free group has none.
-- Style (2026-11-14, user; ns.StyleOf(g, "sep")): look (solid / dashed / dotted), fading ends (none / left / right /
-- both, its own choice since 2026-11-15, user; before a look "fade"), colour and opacity, thickness, shortened at both
-- ends ("inset"). The line is made of parts (f.sepParts, a pool of WHITE8X8 textures coloured by SetGradient): the
-- dashes / dots / the solid line, each cut where the fading begins (the middle), so every part is a straight gradient
-- between the opacities at its two ends. Debuffs: own red colour as a group value (ns.AREA_GROUPS).
local function SepPart(f, i)
    f.sepParts = f.sepParts or {}
    local t = f.sepParts[i]
    if not t then
        t = f:CreateTexture(nil, "BORDER")
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        f.sepParts[i] = t
    end
    return t
end
local function HideSeparator(f)
    if f.sep then f.sep:Hide() end
    for _, t in ipairs(f.sepParts or {}) do t:Hide() end
end
local function PlaceSeparator(f, side)
    if not f.sep then return end
    HideSeparator(f)
    if not side or not SeparatorOn(f.g) or not f.box then return end
    local s, b, pad = f:GetScale(), f.box, B.MoverPad(f)
    local ol, T, W, H = b.l - pad, b.t - pad, b.w + 2 * pad, b.h + 2 * pad -- outline in f's units, y down
    local half = B.SnapGap() / 2 / s
    local st = ns.StyleOf(f.g, "sep")
    local n, ins = math.max(st.size or 1, 1), math.max(st.inset or 0, 0)
    local r, g, bb = ns.HexColor(st.color)
    local a = st.alpha or 0.5
    local horiz = side == "bottom" or side == "top"
    local len = math.max((horiz and W or H) - 2 * ins, 4)
    -- start of the line (x, y top left) and the step along it
    -- on the pixel grid (2026-11-15, user: the Debuffs line looked thicker than the Other one at the same thickness):
    -- textures snap to whole screen pixels, so a line of 1 unit that starts between two pixels came out 1 or 2 pixels
    -- high depending on where the group sits. The thickness is rounded to whole pixels (at least 1) and the line starts
    -- on a whole pixel row (column). p = f's units per physical pixel (768 = height of the screen in UI units at scale 1).
    local p
    local _, physH = GetPhysicalScreenSize()
    local es = f:GetEffectiveScale()
    if physH and physH > 0 and es and es > 0 then p = 768 / (physH * es) end
    if p then n = math.max(1, math.floor(n / p + 0.5)) * p end
    local x0, y0
    if horiz then
        x0 = ol + ((W - len) / 2)
        y0 = (side == "bottom" and (T - half) or (T + H + half)) - n / 2
        local top = p and f:GetTop()
        if top then y0 = top - math.floor((top - y0) / p + 0.5) * p end
    else
        x0 = (side == "right" and (ol - half) or (ol + W + half)) - n / 2
        y0 = T + ((H - len) / 2)
        local left = p and f:GetLeft()
        if left then x0 = math.floor((left + x0) / p + 0.5) * p - left end
    end
    local function Piece(t, from, size)
        t:ClearAllPoints()
        if horiz then
            t:SetPoint("TOPLEFT", f, "TOPLEFT", x0 + from, -y0)
            t:SetSize(math.max(size, 1), n)
        else
            t:SetPoint("TOPLEFT", f, "TOPLEFT", x0, -(y0 + from))
            t:SetSize(n, math.max(size, 1))
        end
        t:Show()
    end
    -- fading (= sepFadeMask in the mockup): half the length per end (2026-11-15, user: a quarter was a bit short, a
    -- third hardly showed); "both" = from the middle to both ends. "left" = start of the line (left or top)
    local q = len / 2
    local fadeL = st.fade == "left" or st.fade == "both"
    local fadeR = st.fade == "right" or st.fade == "both"
    local function Opacity(x)
        local m = 1
        if fadeL and x < q then m = x / q end
        if fadeR and x > len - q then m = math.min(m, (len - x) / q) end
        return a * m
    end
    local cuts = {}
    if fadeL then cuts[#cuts + 1] = q end
    if fadeR and not fadeL then cuts[#cuts + 1] = len - q end -- "both": one cut in the middle
    local i = 0
    local function Draw(from, to) -- one part, cut where the fading begins
        local pts = { from }
        for _, c in ipairs(cuts) do
            if c > from and c < to then pts[#pts + 1] = c end
        end
        pts[#pts + 1] = to
        for k = 1, #pts - 1 do
            i = i + 1
            local t = SepPart(f, i)
            local x1, x2 = pts[k], pts[k + 1]
            Piece(t, x1, x2 - x1)
            local c1, c2 = CreateColor(r, g, bb, Opacity(x1)), CreateColor(r, g, bb, Opacity(x2))
            if horiz then
                t:SetGradient("HORIZONTAL", c1, c2) -- left to right
            else
                t:SetGradient("VERTICAL", c2, c1) -- bottom to top: the start of the line is at the top
            end
        end
    end
    if st.look == "dashed" or st.look == "dotted" then
        local on = st.look == "dashed" and (4 * n + 2) or n
        local period = st.look == "dashed" and (6 * n + 4) or (3 * n)
        local pos, count = 0, 0
        while pos < len and count < 200 do
            count = count + 1
            Draw(pos, math.min(pos + on, len))
            pos = pos + period
        end
    else
        Draw(0, len)
    end
end

-- Frame style (2026-11-14, user; = frameCss in the mockup). Backgrounds: colour, a vertical gradient, or a Blizzard
-- texture tiled over the colour. Borders as rings outside the frame: { from, to (px outwards), colour, opacity }.
local FRAME_TEXTURES = {
    dialog = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    marble = "Interface\\FrameGeneral\\UI-Background-Marble",
    parchment = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal",
}
local function FrameRings(st)
    local n, e = st.edgeSize or 1, st.edgeAlpha or 1
    if st.edge == "none" then return {} end
    -- "double" removed 2026-11-15 (user); SanitizeStyle turns an old value into "flat"
    if st.edge == "tooltip" then return { { 0, n, "black", 0.85 }, { n, 2 * n, "edge", e } } end
    if st.edge == "dialog" then
        return { { -1, 0, "black", 0.7 }, { 0, n + 1, "edge", e }, { n + 1, n + 3, "black", 0.85 }, { n + 3, n + 4, "edge", e * 0.6 } }
    end
    return { { 0, n, "edge", e } } -- "flat"
end
-- how far the border of a framed group reaches outside its background (2026-11-15, user): counts towards the box, so the
-- gap to snapped groups (and the outline) grows with the border thickness instead of the border eating into it
local function FrameOutset(g)
    if not ns.FrameOn(g) then return 0 end
    local out = 0
    for _, ring in ipairs(FrameRings(ns.StyleOf(g, "frame"))) do
        if ring[2] > out then out = ring[2] end
    end
    return out
end

local function PlaceFrame(f, show, l, t, w, h)
    local st = ns.StyleOf(f.g, "frame")
    local r, g, b = ns.HexColor(st.bgColor)
    local a = st.bgAlpha or 0.85
    local tex = FRAME_TEXTURES[st.bgTex]
    local grad = st.bgTex == "gradient"
    -- background only with a texture other than "None" (2026-11-15); the border can show on its own
    local bg = show and st.bgTex ~= "none"
    f.frameBg:SetShown(bg and not grad)
    f.frameGrad:SetShown(bg and grad)
    f.frameTex:SetShown(bg and tex ~= nil)
    for _, e in ipairs(f.frameEdges) do e:Hide() end
    if not show then return end
    if not bg then
        -- no background: only the border rings below
    elseif grad then
        f.frameGrad:SetGradient("VERTICAL", CreateColor(r * 0.55, g * 0.55, b * 0.55, a), CreateColor(r, g, b, a))
        B.PlaceRect(f.frameGrad, f, l, t, w, h)
    else
        f.frameBg:SetVertexColor(r, g, b, a)
        B.PlaceRect(f.frameBg, f, l, t, w, h)
    end
    if tex then
        if f.frameTex.file ~= tex then
            f.frameTex:SetTexture(tex, "REPEAT", "REPEAT")
            f.frameTex:SetHorizTile(true)
            f.frameTex:SetVertTile(true)
            f.frameTex.file = tex
        end
        f.frameTex:SetVertexColor(1, 1, 1, a * 0.6)
        B.PlaceRect(f.frameTex, f, l, t, w, h)
    end
    local er, eg, eb = ns.HexColor(st.edgeColor)
    for i, ring in ipairs(FrameRings(st)) do
        local edges = f.frameRings[i]
        if not edges then
            edges = {}
            for k = 1, 4 do
                edges[k] = f:CreateTexture(nil, "BORDER")
                f.frameEdges[#f.frameEdges + 1] = edges[k]
            end
            f.frameRings[i] = edges
        end
        local o1, o2, th = ring[1], ring[2], ring[2] - ring[1]
        for _, e in ipairs(edges) do
            if ring[3] == "black" then e:SetColorTexture(0, 0, 0, ring[4]) else e:SetColorTexture(er, eg, eb, ring[4]) end
            e:Show()
        end
        B.PlaceRect(edges[1], f, l - o2, t - o2, w + 2 * o2, th)
        B.PlaceRect(edges[2], f, l - o2, t + h + o1, w + 2 * o2, th)
        B.PlaceRect(edges[3], f, l - o2, t - o1, th, h + 2 * o1)
        B.PlaceRect(edges[4], f, l + w + o1, t - o1, th, h + 2 * o1)
    end
end

-- Icon borders of a group (2026-11-14, style "icon"): thickness and the colours per state as { r, g, b, 1 }
local function IconStyle(g)
    local st = ns.StyleOf(g, "icon")
    local out = { size = st.size or 1 }
    for _, k in ipairs({ "active", "missing", "unwanted", "other" }) do
        local r, gg, b = ns.HexColor(st[k])
        out[k] = { r, gg, b, 1 }
    end
    return out
end
-- puts the border texture n px around its icon
local function SetBorderSize(border, n)
    if border.bsize == n then return end
    border:ClearAllPoints()
    border:SetPoint("TOPLEFT", -n, n)
    border:SetPoint("BOTTOMRIGHT", n, -n)
    border.bsize = n
end

-- shared with the other Bar*.lua files
B.PlaceSeparator = PlaceSeparator
B.FrameOutset = FrameOutset
B.PlaceFrame = PlaceFrame
B.IconStyle = IconStyle
B.SetBorderSize = SetBorderSize
