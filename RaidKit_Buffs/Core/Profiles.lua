-- RaidKit Buffs: Profiles
-- Every character edits its OWN settings (RaidKitBuffsDB.chars[key].settings = ns.profile).
-- Saved profiles are named copies without the bar position. Loading copies a saved profile
-- (all of it, or only rows / only appearance) into the own settings; nothing is linked.
-- Also: schema 7 migration (linked profiles -> own settings) and export/import as text.

local _, ns = ...
local L = ns.L

local CopyTable = ns.CopyTable

-- Keys that belong to the character (position of the bar). Never saved into or loaded from a profile.
-- orientation and otherDock depend on where the bar sits on the screen, so they belong here too
-- (otherDock is unused since 2026-11-10, see Bar.lua).
-- groupPos (2026-11-11): positions of the groups, like point
ns.CHAR_KEYS = { point = true, orientation = true, otherDock = true, groupPos = true }
-- "Reihen" part of a profile; every other key is "Darstellung" (incl. useMode). groups (2026-11-11) belong to the
-- rows, because every row names its group
ns.ROW_KEYS = { rows = true, buffOverrides = true, unwanted = true, groups = true }

local MAX_NAME = 40

local function CharState()
    return RaidKitBuffsDB.chars[ns.CharKey()]
end

local function Today()
    return date("%d.%m.%Y")
end

-- Copy of the settings without the character keys
function ns:ProfileData(src)
    local d = CopyTable(src)
    for k in pairs(ns.CHAR_KEYS) do d[k] = nil end
    return d
end

-- Missing keys from the defaults, but never the character keys
local function FillData(d)
    ns.ApplyDefaults(d, ns.profileDefaults)
    for k in pairs(ns.CHAR_KEYS) do d[k] = nil end
end

local function DeepEqual(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    for k, v in pairs(a) do
        if not DeepEqual(v, b[k]) then return false end
    end
    for k in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

------------------------------------------------------------------------
-- Setup (called from InitDB in Core.lua, ADDON_LOADED)
------------------------------------------------------------------------

-- Schema 7: until 0.6.0 a character pointed to a shared profile (chars[key] = "Name").
-- Now every character gets a copy of its old profile as own settings. Profiles that were not
-- named after a character become saved profiles; a character that used one remembers it as base.
function ns:MigrateToOwnSettings(db)
    local oldProfiles, oldChars = db.profiles, db.chars
    db.profiles, db.chars = {}, {}
    for name, prof in pairs(oldProfiles) do
        if type(prof) == "table" and oldChars[name] == nil then
            db.profiles[name] = { saved = Today(), data = ns:ProfileData(prof) } -- class unknown
        end
    end
    for key, name in pairs(oldChars) do
        local prof = type(name) == "string" and oldProfiles[name]
        if type(prof) == "table" then
            db.chars[key] = { settings = CopyTable(prof), base = db.profiles[name] and name or nil }
        end
    end
end

-- Own settings of this character; new characters start with the defaults
-- (the class rows follow in EnsureRows at PLAYER_LOGIN).
function ns:InitCharSettings(db)
    local key = ns.CharKey()
    local st = db.chars[key]
    if type(st) ~= "table" or type(st.settings) ~= "table" then
        st = { settings = CopyTable(ns.profileDefaults) }
        db.chars[key] = st
    end
    if st.base and not db.profiles[st.base] then st.base = nil end
    ns.profile = st.settings
    ns.ApplyDefaults(ns.profile, ns.profileDefaults)
    for name, p in pairs(db.profiles) do
        if type(p) ~= "table" or type(p.data) ~= "table" then
            db.profiles[name] = nil
        else
            FillData(p.data)
        end
    end
end

------------------------------------------------------------------------
-- Queries
------------------------------------------------------------------------

function ns:GetProfileNames()
    local names = {}
    for name in pairs(RaidKitBuffsDB.profiles) do names[#names + 1] = name end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    return names
end

function ns:GetProfile(name)
    return name and RaidKitBuffsDB.profiles[name]
end

-- Name of the profile loaded or saved last (nil = own settings never saved)
function ns:GetBaseProfile()
    return CharState().base
end

-- saved profile from before 2026-11-12 with the main group still called "Hauptleiste" (renamed by ns.EnsureGroups)
local function HasOldMainName(d)
    for _, g in ipairs(type(d.groups) == "table" and d.groups or {}) do
        if type(g) == "table" and g.id == "main" and g.name == "Hauptleiste" then return true end
    end
    return false
end

-- true if the own settings differ from the base profile (the page "Profiles" then shows "Own" instead of the name).
function ns:IsModified()
    local base = ns:GetBaseProfile()
    local p = ns:GetProfile(base)
    if not p then return false end
    -- saved profile from before 2026-11-12: move the old area sizes onto the groups first (like the own settings),
    -- otherwise it would count as changed
    local d = p.data
    if type(d) == "table" and (d.otherIconSize or d.otherSpacing or d.otherScale or d.otherPerLine or d.debuffIconSize
        or d.debuffSpacing or d.debuffScale or d.debuffPerLine or HasOldMainName(d)) and type(d.rows) == "table" then
        ns.EnsureGroups(d)
    end
    for k, v in pairs(ns.profile) do
        if not ns.CHAR_KEYS[k] and not DeepEqual(v, p.data[k]) then return true end
    end
    for k in pairs(p.data) do
        if ns.profile[k] == nil then return true end
    end
    return false
end

function ns:ClassName(token)
    return token and ((LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or token) or "?"
end

-- "7 Reihen (3 sichtbar), 34 Items"
function ns:ProfileSummary(name)
    local p = ns:GetProfile(name)
    local rows, visible, items = 0, 0, 0
    for _, r in ipairs(p.data.rows or {}) do
        rows = rows + 1
        if not r.hidden then visible = visible + 1 end
        items = items + #(r.items or {})
    end
    return rows, visible, items
end

-- Trimmed name or nil + error text
function ns:CheckProfileName(name)
    name = strtrim(name or "")
    if name == "" then return nil, L["Please enter a profile name."] end
    if #name > MAX_NAME then return nil, L["The name is too long (at most %d characters)."]:format(MAX_NAME) end
    return name
end

------------------------------------------------------------------------
-- Actions
------------------------------------------------------------------------

local function Changed()
    ns:RequestRebuild()
    if ns.RefreshOptions then ns:RefreshOptions() end
end

-- Saves the own settings under this name (overwrites an existing profile).
-- Profiles are fixed copies (user 2026-11-20): they change only here. Gone: the automatic profile per character
-- (2026-11-09 to 2026-11-20, schema 10 deleted them) and the self-saving own profile ("Weg 2", st.own, schema 11).
function ns:SaveProfile(name)
    RaidKitBuffsDB.profiles[name] = { class = ns:PlayerClass(), saved = Today(), data = ns:ProfileData(ns.profile) }
    CharState().base = name
    if ns.RefreshOptions then ns:RefreshOptions() end
end

-- Copies a saved profile into the own settings: everything except the position (session 20, user; before rows and/or
-- appearance by choice, the appearance lived in "Alle Gruppen"; the groups carry it now). rows/look: kept for /rkb.
function ns:LoadProfile(name, rows, look)
    rows, look = true, true
    local p = ns:GetProfile(name)
    if not p then return false end
    for k, v in pairs(p.data) do
        if not ns.CHAR_KEYS[k] then
            if ns.ROW_KEYS[k] then
                if rows then ns.profile[k] = CopyTable(v) end
            elseif look then
                ns.profile[k] = CopyTable(v)
            end
        end
    end
    ns.ApplyDefaults(ns.profile, ns.profileDefaults)
    ns:EnsureRows(ns.profile)
    CharState().base = name
    Changed()
    return true
end

function ns:RenameProfile(old, new)
    local db = RaidKitBuffsDB
    if not db.profiles[old] or db.profiles[new] then return false end
    db.profiles[new], db.profiles[old] = db.profiles[old], nil
    for _, st in pairs(db.chars) do
        if st.base == old then st.base = new end
    end
    if ns.RefreshOptions then ns:RefreshOptions() end
    return true
end

function ns:CopyProfile(src, new)
    local db = RaidKitBuffsDB
    if not db.profiles[src] or db.profiles[new] then return false end
    db.profiles[new] = CopyTable(db.profiles[src])
    db.profiles[new].saved = Today()
    return true
end

-- Deletes only the saved copy; characters that loaded it keep their settings
function ns:DeleteProfile(name)
    local db = RaidKitBuffsDB
    if not db.profiles[name] then return false end
    db.profiles[name] = nil
    for _, st in pairs(db.chars) do
        if st.base == name then st.base = nil end
    end
    if ns.RefreshOptions then ns:RefreshOptions() end
    return true
end

-- Own settings back to the class default (= new character). The position stays.
function ns:ResetProfile()
    for k in pairs(ns.profile) do
        if not ns.CHAR_KEYS[k] then ns.profile[k] = nil end
    end
    ns.ApplyDefaults(ns.profile, ns.profileDefaults)
    ns:EnsureRows(ns.profile)
    CharState().base = nil -- the page "Profiles" shows "Own"
    Changed()
end

-- /rkb reset (user 2026-11-20: way back for a group pushed off the screen; before, /rkb reset reset the settings,
-- which the button "Default (class) ..." does). Only the character keys of the position: the main group goes to its
-- default place, every other position is forgotten, so the areas and the class groups snap to their default places
-- again (EnsureGroupPos) and other groups appear diagonally next to the main group (BarGroups.lua NewGroupPoint).
-- Rows, groups and style stay. In combat BuildBar waits for the end of the fight.
function ns:ResetPositions()
    ns.profile.point = CopyTable(ns.profileDefaults.point)
    ns.profile.groupPos = {}
    ns.EnsureGroupPos(ns.profile)
    Changed()
end

------------------------------------------------------------------------
-- Export / import: "!RKB1!" + base64 of a small serializer (no loadstring, so pasted
-- text can never run as code). Strings carry their length, so no escaping is needed.
------------------------------------------------------------------------

local EXPORT_PREFIX = "!RKB1!"

local function Serialize(v, out)
    local t = type(v)
    if t == "table" then
        out[#out + 1] = "{"
        for k, val in pairs(v) do
            local tk, tv = type(k), type(val)
            if (tk == "string" or tk == "number") and (tv == "table" or tv == "string" or tv == "number" or tv == "boolean") then
                Serialize(k, out)
                Serialize(val, out)
            end
        end
        out[#out + 1] = "}"
    elseif t == "string" then
        out[#out + 1] = "s" .. #v .. ":" .. v
    elseif t == "number" then
        out[#out + 1] = "n" .. tostring(v) .. ";"
    elseif t == "boolean" then
        out[#out + 1] = v and "T" or "F"
    end
end

-- returns value, next position (value nil = invalid)
local function Deserialize(s, pos, depth)
    if depth > 20 then return nil end
    local c = s:sub(pos, pos)
    if c == "{" then
        local t = {}
        pos = pos + 1
        while true do
            local nc = s:sub(pos, pos)
            if nc == "" then return nil end
            if nc == "}" then return t, pos + 1 end
            local k, v
            k, pos = Deserialize(s, pos, depth + 1)
            if k == nil or type(k) == "table" or type(k) == "boolean" then return nil end
            v, pos = Deserialize(s, pos, depth + 1)
            if v == nil then return nil end
            t[k] = v
        end
    elseif c == "s" then
        local len, start = s:match("^(%d+):()", pos + 1)
        len = tonumber(len)
        if not len then return nil end
        local str = s:sub(start, start + len - 1)
        if #str ~= len then return nil end
        return str, start + len
    elseif c == "n" then
        local num, nextPos = s:match("^([^;]+);()", pos + 1)
        num = tonumber(num)
        if not num or num ~= num then return nil end -- nil or NaN
        return num, nextPos
    elseif c == "T" then
        return true, pos + 1
    elseif c == "F" then
        return false, pos + 1
    end
    return nil
end

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local B64_INDEX = {}
for i = 1, 64 do B64_INDEX[B64:sub(i, i)] = i - 1 end

local function Base64Encode(data)
    local out = {}
    for i = 1, #data, 3 do
        local a, b, c = data:byte(i, i + 2)
        local n = a * 65536 + (b or 0) * 256 + (c or 0)
        local c1 = math.floor(n / 262144) % 64
        local c2 = math.floor(n / 4096) % 64
        local c3 = math.floor(n / 64) % 64
        local c4 = n % 64
        out[#out + 1] = B64:sub(c1 + 1, c1 + 1) .. B64:sub(c2 + 1, c2 + 1)
            .. (b and B64:sub(c3 + 1, c3 + 1) or "=") .. (c and B64:sub(c4 + 1, c4 + 1) or "=")
    end
    return table.concat(out)
end

local function Base64Decode(text)
    text = text:gsub("[^%w%+/]", "") -- drops "=", spaces and line breaks
    local out = {}
    for i = 1, #text, 4 do
        local chunk = text:sub(i, i + 3)
        local n, count = 0, #chunk
        for j = 1, 4 do
            n = n * 64 + (B64_INDEX[chunk:sub(j, j)] or 0)
        end
        local a, b, c = math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256
        if count >= 2 then out[#out + 1] = string.char(a) end
        if count >= 3 then out[#out + 1] = string.char(b) end
        if count >= 4 then out[#out + 1] = string.char(c) end
    end
    return table.concat(out)
end

function ns:ExportProfile(name)
    local p = ns:GetProfile(name)
    if not p then return nil end
    local out = {}
    Serialize({ v = 1, name = name, class = p.class, data = p.data }, out)
    return EXPORT_PREFIX .. Base64Encode(table.concat(out))
end

local function Clamp(v, minV, maxV)
    if type(v) ~= "number" then return nil end
    return math.max(minV, math.min(maxV, v))
end

local VALID_ROW_NAME_POS = { left = true, right = true, topleft = true, topright = true, bottomleft = true, bottomright = true }
local VALID_NAME_ALIGN = { left = true, center = true, right = true } -- group name (2026-11-15)

-- style tables (2026-11-14, ns.STYLE_DEF): only known keys; colours "#rrggbb", choices from their lists, numbers clamped
local STYLE_CHOICES = {
    bgTex = { none = true, solid = true, gradient = true, dialog = true, marble = true, parchment = true }, -- none: 2026-11-15
    edge = { none = true, flat = true, tooltip = true, dialog = true }, -- "double" removed 2026-11-15 (-> "flat")
    look = { solid = true, dashed = true, dotted = true, fade = true }, -- "fade": old value, MigrateSepFade converts it
    fade = { none = true, left = true, right = true, both = true }, -- fading ends of the separator (2026-11-15)
}
local STYLE_RANGES = { bgAlpha = { 0, 1 }, edgeAlpha = { 0, 1 }, alpha = { 0, 1 }, edgeSize = { 1, 8 }, inset = { 0, 60 } }
local function SanitizeStyle(s)
    if type(s) ~= "table" then return nil end
    local out
    for sec, def in pairs(ns.STYLE_DEF) do
        local src = type(s[sec]) == "table" and s[sec] or nil
        if src then
            local o = {}
            for k, dv in pairs(def) do
                local v = src[k]
                if type(dv) == "string" and type(v) == "string" then
                    if k == "edge" and v == "double" then v = "flat" end
                    if STYLE_CHOICES[k] then
                        if STYLE_CHOICES[k][v] then o[k] = v end
                    elseif v:match("^#%x%x%x%x%x%x$") then
                        o[k] = v:lower()
                    end
                elseif type(dv) == "number" and type(v) == "number" then
                    local r = STYLE_RANGES[k] or (sec == "icon" and { 1, 4 } or { 1, 6 })
                    o[k] = math.max(r[1], math.min(r[2], v))
                end
            end
            if next(o) then
                out = out or {}
                out[sec] = o
            end
        end
    end
    return out
end

-- Only known keys with the right types; everything else from the defaults
local function SanitizeData(d)
    if type(d) ~= "table" or type(d.rows) ~= "table" then return nil end
    local out = {}
    out.iconSize = Clamp(d.iconSize, 12, 64) -- 12 since 2026-11-10 (one slider for all tabs on "Darstellung")
    out.spacing = Clamp(d.spacing, 0, 20)
    out.scale = Clamp(d.scale, 0.5, 2)
    out.rowSpacing = Clamp(d.rowSpacing, 0, 20) -- 40 until 2026-11-18
    out.perLine = Clamp(d.perLine, 0, 20)
    if VALID_ROW_NAME_POS[d.rowNamePos] then out.rowNamePos = d.rowNamePos end
    if VALID_NAME_ALIGN[d.nameAlign] then out.nameAlign = d.nameAlign end
    if ns.USE_MODE_LABEL[d.useMode] then out.useMode = d.useMode end
    for _, k in ipairs({ "showRowNames", "showCount", "showOther", "showBorders", "showGroupName", "showTime" }) do
        if type(d[k]) == "boolean" then out[k] = d[k] end
    end
    out.timeSize = Clamp(d.timeSize, 6, 20) -- font size of the time (2026-11-14)
    out.style = SanitizeStyle(d.style) -- style of "Alle Gruppen" (2026-11-14)
    -- values stored one by one since 2026-11-14: an export with this mark needs no conversion (ns.EnsureGroups)
    if d.inheritMigrated == true then out.inheritMigrated = true end
    if d.armorMigrated == true then out.armorMigrated = true end -- mage armor slot (2026-11-15, Core.lua)
    if d.frameMigrated == true then out.frameMigrated = true end -- frame defaults (2026-11-15, Core.lua MigrateFrame)
    if d.frameAutoMigrated == true then out.frameAutoMigrated = true end -- texture "None" (2026-11-15, MigrateFrameAuto)
    if d.nameAlignMigrated == true then out.nameAlignMigrated = true end -- name alignment (2026-11-15, MigrateNameAlign)
    if d.sepFadeMigrated == true then out.sepFadeMigrated = true end -- fading ends (2026-11-15, MigrateSepFade)
    if d.areaNamesMigrated == true then out.areaNamesMigrated = true end -- area names (2026-11-15, MigrateAreaNames)
    if d.bagCountMigrated == true then out.bagCountMigrated = true end -- bag count per group (session 20, MigrateBagCount)
    if d.allGroupsMigrated == true then out.allGroupsMigrated = true end -- no "Alle Gruppen" (session 20, MigrateAllGroups)
    if d.perLineMigrated == true then out.perLineMigrated = true end -- 12 places per row (2026-11-20, MigratePerLine)
    -- display mode; exports from before schema 9 still carry showBar
    for _, m in ipairs(ns.SHOW_MODES) do
        if d.showMode == m.key then out.showMode = m.key end
    end
    if not out.showMode and d.showBar == false then out.showMode = "never" end
    -- old area sizes (until 2026-11-12): kept for ns.EnsureGroups, which moves them onto the area groups
    out.otherPerLine = Clamp(d.otherPerLine, 0, 20) -- 0 = "alle" (as many as fit), 2026-11-10
    out.debuffPerLine = Clamp(d.debuffPerLine, 0, 20)
    for _, pre in ipairs({ "other", "debuff" }) do
        out[pre .. "IconSize"] = Clamp(d[pre .. "IconSize"], 12, 64)
        out[pre .. "Spacing"] = Clamp(d[pre .. "Spacing"], 0, 20)
        out[pre .. "Scale"] = Clamp(d[pre .. "Scale"], 0.5, 2)
    end
    -- "Unerwünscht": known buffs only
    if type(d.unwanted) == "table" then
        out.unwanted = {}
        for _, id in ipairs(d.unwanted) do
            if ns.buffCatalog[id] and #out.unwanted < 20 then out.unwanted[#out.unwanted + 1] = id end
        end
    end
    out.rows = {}
    for _, r in ipairs(d.rows) do
        if type(r) == "table" and #out.rows < 10 then
            -- every row takes both kinds (2026-11-11); an old "kind" field is dropped
            local row = { name = type(r.name) == "string" and r.name:sub(1, 40) or "", items = {}, hidden = r.hidden == true or nil }
            for _, entry in ipairs(type(r.items) == "table" and r.items or {}) do
                -- itemID or slot { itemID, ..., pick = itemID }, or a known -spellID (foreign buff)
                if #row.items < 30 then
                    local clean
                    if ns.IsBuffID(entry) then
                        if ns.buffCatalog[entry] then clean = entry end
                    elseif type(entry) == "table" then
                        clean = ns.NormalizeEntry(entry)
                        -- buff slots (2026-11-15, mage armors): only known buffs; item slots: only items
                        if clean ~= nil then
                            local buffSlot = ns.IsBuffID(ns.EntryMain(clean))
                            for _, id in ipairs(ns.EntryIDs(clean)) do
                                if buffSlot ~= ns.IsBuffID(id) or (buffSlot and not ns.buffCatalog[id]) then clean = nil break end
                            end
                            if clean and buffSlot and ns.IsWeaponEntry(clean) then clean = nil end
                        end
                    elseif type(entry) == "number" and entry > 0 and entry == math.floor(entry) then
                        clean = entry
                    end
                    if clean then row.items[#row.items + 1] = clean end
                end
            end
            -- no own size of a row since 2026-11-16 (user): row.iconSize / spacing / scale / perLine are not taken over
            -- split row (2026-11-16; 2026-11-15 rows of a split group): icons of the left half, name of the right half
            row.split = Clamp(type(r.split) == "number" and math.floor(r.split) or nil, 0, #row.items)
            -- remembered separator of a row that is not split (2026-11-16, OptionsSplit.lua SetRowSplit)
            if not row.split and type(r.splitOff) == "number" then row.splitOff = Clamp(math.floor(r.splitOff), 0, #row.items) end
            -- look of the separator on the bar (2026-11-17, BarSplit.lua SEP_KINDS); "gap" is the default, not stored
            if type(r.sepStyle) == "string" and ns.SEP_BY_KEY and ns.SEP_BY_KEY[r.sepStyle] and r.sepStyle ~= "gap"
                and r.sepStyle ~= "none" then row.sepStyle = r.sepStyle end
            -- alignment of the row (2026-11-18, BarSplit.lua ROW_ALIGNS)
            if type(r.align) == "string" and ns.ROW_ALIGN_BY_KEY and ns.ROW_ALIGN_BY_KEY[r.align] then row.align = r.align end
            if type(r.nameR) == "string" then row.nameR = r.nameR:sub(1, 40) end
            if type(r.group) == "string" and #r.group <= 16 then row.group = r.group end -- checked below
            out.rows[#out.rows + 1] = row
        end
    end
    -- groups (2026-11-11): known fields only; the three areas only with their fixed ids
    out.groups = {}
    local areaOf = {}
    for _, a in ipairs(ns.AREA_GROUPS) do areaOf[a.id] = a.area end
    local validOrient = {}
    for _, o in ipairs(ns.ORIENTATIONS or {}) do validOrient[o.key] = true end
    local seen, nRowGroups = {}, 0
    for _, g in ipairs(type(d.groups) == "table" and d.groups or {}) do
        if type(g) == "table" and type(g.id) == "string" and #g.id <= 16 and not seen[g.id] then
            local isArea = g.area ~= nil
            -- areas only with their fixed id; no row group with an area's id; at most MAX_GROUPS row groups
            local ok
            if isArea then ok = areaOf[g.id] == g.area
            else ok = not areaOf[g.id] and nRowGroups < ns.MAX_GROUPS end
            if ok and not isArea then nRowGroups = nRowGroups + 1 end
            if ok then
                seen[g.id] = true
                local ng = { id = g.id, area = isArea and g.area or nil,
                    name = type(g.name) == "string" and g.name:sub(1, MAX_NAME) or "" }
                for _, k in ipairs({ "frame", "showName", "rowNames", "capTint", "showBorders", "showCount", "hidden", "separator", "showTime" }) do
                    if type(g[k]) == "boolean" then ng[k] = g[k] end
                end
                -- own orientation: every group, the buff areas too since 2026-11-11 (nil there = "automatisch")
                if validOrient[g.orientation] then ng.orientation = g.orientation end
                -- own position of the row names (2026-11-12): groups with rows only
                if not isArea and VALID_ROW_NAME_POS[g.rowNamePos] then ng.rowNamePos = g.rowNamePos end
                if VALID_NAME_ALIGN[g.nameAlign] then ng.nameAlign = g.nameAlign end -- group name (2026-11-15)
                -- own size values one by one (2026-11-14; before all together with "Eigene Größe"), font size, style
                ng.iconSize, ng.spacing, ng.scale = Clamp(g.iconSize, 12, 64), Clamp(g.spacing, 0, 20), Clamp(g.scale, 0.5, 2)
                ng.perLine = Clamp(g.perLine, 0, 20)
                ng.rowSpacing = Clamp(g.rowSpacing, 0, 20) -- 40 until 2026-11-18
                ng.timeSize = Clamp(g.timeSize, 6, 20)
                -- split group of 2026-11-15: its rows become split rows (FitRowWidths in Core.lua), then the flag goes
                if not isArea and g.split == true then ng.split = true end
                ng.style = SanitizeStyle(g.style)
                out.groups[#out.groups + 1] = ng
            end
        end
    end
    ns.EnsureGroups(out) -- rows of unknown groups go to "main"
    out.buffOverrides = {}
    if type(d.buffOverrides) == "table" then
        for id, spells in pairs(d.buffOverrides) do
            if type(id) == "number" and type(spells) == "table" then
                local list = {}
                for _, s in ipairs(spells) do
                    if type(s) == "number" then list[#list + 1] = s end
                end
                if #list > 0 then out.buffOverrides[id] = list end
            end
        end
    end
    FillData(out)
    return out
end

-- Saves an export text as a new profile (does not load it).
-- Returns the profile name, or nil + error text. A taken name gets a number: "Tank (2)".
function ns:ImportProfile(text)
    text = strtrim(text or "")
    if text:sub(1, #EXPORT_PREFIX) ~= EXPORT_PREFIX then
        return nil, L["This is not a RaidKit Buffs export (it starts with %s)."]:format(EXPORT_PREFIX)
    end
    local raw = Base64Decode(text:sub(#EXPORT_PREFIX + 1))
    local obj, nextPos = Deserialize(raw, 1, 0)
    local data = type(obj) == "table" and nextPos == #raw + 1 and SanitizeData(obj.data)
    if not data then return nil, L["The export text is incomplete or damaged."] end
    local base = ns:CheckProfileName(type(obj.name) == "string" and obj.name or "") or "Import"
    local name, n = base, 2
    while RaidKitBuffsDB.profiles[name] do
        name = base .. " (" .. n .. ")"
        n = n + 1
    end
    RaidKitBuffsDB.profiles[name] = {
        class = type(obj.class) == "string" and RAID_CLASS_COLORS and RAID_CLASS_COLORS[obj.class] and obj.class or nil,
        saved = Today(),
        data = data,
    }
    if ns.RefreshOptions then ns:RefreshOptions() end
    return name
end
