-- RaidKit Buffs: BarBase
-- Shared base of the bar files (Bar*.lua, split 2026-11-15): the tables B (ns.Bar: shared functions and
-- constants) and BS (ns.BarState: state several files change), frame tables, timer and hand-mark helpers, group
-- layout constants.
-- Shared names between the Bar*.lua files: Docs/Architecture.md "Leiste: Aufteilung in Dateien".

local _, ns = ...
local L = ns.L
local B, BS = {}, {}
ns.Bar, ns.BarState = B, BS

BS.container = nil -- frame of the main group ("RaidKitBuffsFrame"); every group has its own frame since 2026-11-11
local buttonPool = {}  -- every button ever created, reused
local activeButtons = {}
-- Groups (2026-11-11, Docs/Plan-Groups.md): rows are combined into groups, each with its own frame and position.
-- The three buff areas ("Unerwünschte Buffs", "Sonstige Buffs", "Debuffs") are groups too (g.area).
local groupFrames = {}  -- [group id] = frame of a group with rows ("main" = container)
local areaFrames = {}   -- [area] = frame of an area group ("unw" / "other" / "debuff")
local shownGroups = {}  -- built groups in group order: { g = group, f = frame }
-- area being drawn right now (UpdateExtra switches it per area; the helpers PlaceX/PlaceName use it)
BS.extra = nil

local WEAPON_SLOT = { main = 16, off = 17 } -- inventory slots of the weapon hands
local BORDER_ACTIVE = { 0.2, 0.9, 0.2, 1 }
local BORDER_MISSING = { 0.35, 0.35, 0.35, 1 }
-- border colour of a row button by state ("active" / "missing"): its group's style since 2026-11-14 (btn.istyle,
-- set in BuildGroup), the old fixed colours as fallback
local function BtnColor(btn, state)
    local st = btn.istyle
    if st and st[state] then return st[state] end
    return state == "active" and BORDER_ACTIVE or BORDER_MISSING
end

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------

-- Short form for the icon timer. Rounds up like Blizzard's buff frame (2026-11-10): a fresh 2-hour buff has
-- 1:59:59 left and reads "120m" (minutes since 2026-11-14, before "2h"); below one minute seconds.
local function FormatTime(seconds)
    seconds = math.max(seconds or 0, 0)
    -- minutes from one minute on, also above an hour (2026-11-14, user: more exact than "2h"), e.g. "87m", "120m"
    if seconds > 60 then
        return string.format("%dm", math.ceil(seconds / 60))
    else
        return string.format("%ds", math.ceil(seconds))
    end
end

-- Long form for tooltips and chat (user 2026-11-10: exact to the minute), e.g. "1 Std. 59 Min.".
-- Below one minute in seconds.
local function FormatTimeLong(seconds)
    seconds = math.max(seconds or 0, 0)
    if seconds < 60 then
        return string.format(L["%d sec"], math.ceil(seconds))
    end
    local minutes = math.floor(seconds / 60)
    local h, m = math.floor(minutes / 60), minutes % 60
    if h == 0 then return string.format(L["%d min"], m) end
    if m == 0 then return string.format(L["%d hr"], h) end
    return string.format(L["%d hr %d min"], h, m)
end

-- Remaining time at the top inside an icon, with a soft dark background (user 2026-11-12: easier to read). The
-- background follows the text width and is hidden while the text is empty (SetText is wrapped on this instance).
local TIMER_BG_ALPHA = 0.55
local function TimerText(parent)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOP", parent, "TOP", 0, -2)
    local bg = parent:CreateTexture(nil, "OVERLAY", nil, -1) -- below the text in the same layer
    bg:SetColorTexture(0, 0, 0, TIMER_BG_ALPHA)
    bg:SetPoint("TOPLEFT", fs, "TOPLEFT", -2, 1)
    bg:SetPoint("BOTTOMRIGHT", fs, "BOTTOMRIGHT", 2, -1)
    bg:Hide()
    local setText = fs.SetText
    fs.SetText = function(self, text)
        setText(self, text)
        bg:SetShown(text ~= nil and text ~= "")
    end
    fs.bg = bg
    return fs
end

-- Hand mark of weapon entries (2026-11-14, user): "MH"/"OH" bottom left on a violet patch, 3 points smaller than
-- the small font (the remaining time sits at the top). Returns the text; the patch is text.bg.
local HAND_MARK_SHRINK = 3 -- 2 was a bit too big (user 2026-11-14)
local function HandMark(parent)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    local font, size, flags = fs:GetFont()
    if font and size then fs:SetFont(font, size - HAND_MARK_SHRINK, flags) end
    -- the patch sits flush in the corner (user 2026-11-14): text 1 px in, patch 1 px around it
    fs:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 1, 1)
    local bg = parent:CreateTexture(nil, "OVERLAY", nil, -1) -- below the text in the same layer
    bg:SetColorTexture(0.43, 0.16, 0.63, 0.9)
    bg:SetPoint("TOPLEFT", fs, "TOPLEFT", -1, 1)
    bg:SetPoint("BOTTOMRIGHT", fs, "BOTTOMRIGHT", 1, -1)
    fs.bg = bg
    return fs
end
ns.HandMark = HandMark

-- Remaining time of a buff with its color (user 2026-11-12): at most 10 % of the full duration left = yellow
-- (Blizzard's yellow), else white. dur nil/0 (unknown, debuffs, auras without duration) stays white.
-- The color is only set when it changes (runs every update).
local LOW_TIME_SHARE = 0.10
local TIMER_WHITE, TIMER_LOW = { 1, 1, 1 }, { 1, 0.82, 0 }
-- hidden (2026-11-14): option "Zeit anzeigen" of the group is off
local function SetTimer(fs, left, dur, hidden)
    if hidden then fs:SetText("") return end
    left = math.max(left or 0, 0)
    fs:SetText(FormatTime(left))
    local low = (dur and dur > 0 and left <= dur * LOW_TIME_SHARE) and true or false
    if fs.low ~= low then
        fs.low = low
        fs:SetTextColor(unpack(low and TIMER_LOW or TIMER_WHITE))
    end
end

-- full duration of a catalog entry (consumable, foreign buff or weapon enchant), nil if unknown
local function CatalogDuration(id)
    local e = id and (ns.catalog[id] or ns.buffCatalog[id])
    return e and e.dur and e.dur > 0 and e.dur or nil
end

------------------------------------------------------------------------
-- Group layout constants (used by several Bar*.lua files)
------------------------------------------------------------------------
local MOVER_PAD = 2       -- outline of a group without a frame: this far around icons and names (before: main 8, others 3)
local HOVER_PAD = 8       -- Shift hover: the cursor may be this far outside an outline
local EDGE_W = 12         -- edge band inside the outline: dragging there moves only this group (session 4b: 8 -> 12)
local SNAP_DIST = 16      -- snap when a group comes this close to an edge position of another group
local FRAME_PAD = 5       -- optional frame of a group: room around icons and names
local GNAME_H = 14        -- group name above the frame
local SIDE_NAME = ns.LocalizedTable({ bottom = "below", top = "above", left = "left of", right = "right of" })
ns.GROUP_SIDE_NAME = SIDE_NAME
-- = slotName in the mockup (2026-11-18, eight snap points): side and end in words, e.g. "below (left)", "left of (bottom)"
local ALIGN_NAME = { start = { v = "(left)", h = "(top)" }, ["end"] = { v = "(right)", h = "(bottom)" } }
function ns.SlotName(side, align)
    local a = ALIGN_NAME[align] or ALIGN_NAME.start
    return (SIDE_NAME[side] or L["at"]) .. " " .. L[(side == "bottom" or side == "top") and a.v or a.h]
end

-- shared with the other Bar*.lua files
B.buttonPool = buttonPool
B.activeButtons = activeButtons
B.groupFrames = groupFrames
B.areaFrames = areaFrames
B.shownGroups = shownGroups
B.WEAPON_SLOT = WEAPON_SLOT
B.BtnColor = BtnColor
B.FormatTimeLong = FormatTimeLong
B.TimerText = TimerText
B.HandMark = HandMark
B.SetTimer = SetTimer
B.CatalogDuration = CatalogDuration
B.MOVER_PAD = MOVER_PAD
B.HOVER_PAD = HOVER_PAD
B.EDGE_W = EDGE_W
B.SNAP_DIST = SNAP_DIST
B.FRAME_PAD = FRAME_PAD
B.GNAME_H = GNAME_H
B.SIDE_NAME = SIDE_NAME
