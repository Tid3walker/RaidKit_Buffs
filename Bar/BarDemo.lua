-- RaidKit Buffs: BarDemo
-- Demo mode: fake buffs and debuffs come and go so the layout can be judged without a raid.
-- Shared names between the Bar*.lua files: Docs/Architecture.md "Leiste: Aufteilung in Dateien".

local _, ns = ...
local L = ns.L
local B = ns.Bar
local activeButtons, areaFrames = B.activeButtons, B.areaFrames

------------------------------------------------------------------------
-- Demo mode (2026-11-10): fake buffs (HoTs, Flurry, Enrage, trinkets ...) and debuffs come and go
-- under "Sonstige Buffs" / "Debuffs" for at most ns.DEMO_SECONDS, so the layout can be judged
-- without a raid. Only plain frames and ns.demo; real auras, the counter's cap logic and the rows
-- stay untouched (the counter adds the demo buffs). The bar is shown while it runs (ApplyVisibility).
------------------------------------------------------------------------

local demoTicker

-- remaining time of a row icon that the demo shows active: world buffs 30 min to 1:45 h (user 2026-11-10),
-- never more than the buff really lasts (Songflower, Rend: 1 h); everything else 5 to 55 minutes
local function DemoRowExp(entry, now)
    local b = type(entry) == "number" and ns.buffCatalog[entry]
    if b and b.cat == "world" then
        local minutes = math.random(30, 105)
        if b.dur and b.dur > 0 then minutes = math.min(minutes, math.floor(b.dur / 60)) end
        return now + minutes * 60
    end
    return now + math.random(5, 55) * 60
end

local function DemoAura(def, now)
    return { demo = true, spellId = def.id, name = def.name, icon = "Interface\\Icons\\" .. def.icon,
        expiration = def.dur > 0 and now + def.dur or 0, duration = def.dur, dispel = def.dispel }
end

-- adds one random entry of defs that is not in list yet
local function DemoAdd(list, defs, now)
    local free = {}
    for _, def in ipairs(defs) do
        local taken = false
        for _, a in ipairs(list) do
            if a.spellId == def.id then taken = true end
        end
        if not taken then free[#free + 1] = def end
    end
    if #free > 0 then list[#list + 1] = DemoAura(free[math.random(#free)], now) end
end

-- free buff slots for demo buffs: the demo never shows more than the cap allows
local function DemoFree()
    local demo = ns.demo
    return ns.BUFF_CAP - #ns.auraList - (demo and (#demo.buffs + demo.nRows) or 0)
end

local function DemoRefresh()
    if B.UpdateExtra then B.UpdateExtra() end
    if areaFrames.other then B.UpdateAreaTimers() end
    if ns.UpdateDemoButton then ns:UpdateDemoButton() end -- button "Demo beenden (0:42)"
end

local function DemoTick()
    local demo = ns.demo
    if not demo then return end
    local now = GetTime()
    if now >= demo.endTime then
        ns:StopDemo()
        return
    end
    for _, list in ipairs({ demo.buffs, demo.debuffs }) do
        for i = #list, 1, -1 do
            local exp = list[i].expiration
            if exp > 0 and exp <= now then table.remove(list, i) end
        end
    end
    -- "here and there": a new buff roughly every 2 s, a debuff every 4 s; never beyond the buff cap
    if #demo.buffs < 8 and DemoFree() > 0 and math.random() < 0.5 then DemoAdd(demo.buffs, ns.DEMO_BUFFS, now) end
    if #demo.debuffs < 4 and math.random() < 0.25 then DemoAdd(demo.debuffs, ns.DEMO_DEBUFFS, now) end
    -- an unwanted buff comes back now and then, so the red button can be tried again
    if DemoFree() > 0 and math.random() < 0.1 then DemoAdd(demo.buffs, demo.unwantedDefs, now) end
    DemoRefresh()
end

-- Demo versions of the player's unwanted buffs (p.unwanted, e.g. Arcane Intellect for warriors), only
-- those that are not really active: the red button lights up and removes them (user 2026-11-10)
local function DemoUnwantedDefs()
    local defs, real = {}, {}
    for _, a in ipairs(ns.auraList) do real[a.spellId] = true end
    for _, id in ipairs(ns.profile.unwanted or {}) do
        local b = ns.buffCatalog[id]
        local active = false
        for _, spellID in ipairs(ns:GetBuffSpellsForItem(id)) do
            if real[spellID] then active = true end
        end
        if b and b.spells and b.icon and not active then
            defs[#defs + 1] = { id = b.spells[1], name = b.name, icon = b.icon, dur = b.dur or 1800 }
        end
    end
    return defs
end

-- red button during the demo: drop the demo's unwanted buffs (the real ones go via the secure macro)
function ns:RemoveDemoUnwanted()
    local demo = ns.demo
    if not demo then return end
    local set = {}
    for _, d in ipairs(demo.unwantedDefs) do set[d.id] = true end
    for i = #demo.buffs, 1, -1 do
        if set[demo.buffs[i].spellId] then table.remove(demo.buffs, i) end
    end
    DemoRefresh()
end

-- Start only out of combat: the rebuild switches right-click removing off (rows; "Sonstige" checks
-- ns.demo itself), and secure attributes cannot change in combat (user 2026-11-10: real potions must
-- never be clicked away during the demo). The red button stays: it only removes the user's own
-- unwanted list, plus the demo's unwanted buffs.
function ns:StartDemo()
    if ns.demo then return end
    if InCombatLockdown() then
        ns:Print(L["The demo only starts out of combat."])
        return
    end
    local now = GetTime()
    ns.demo = { endTime = now + ns.DEMO_SECONDS, buffs = {}, debuffs = {}, rows = {}, nRows = 0,
        unwantedDefs = DemoUnwantedDefs() }
    -- 5 to 20 icons of the rows look active, world buffs included (user 2026-11-10): currently inactive
    -- non-weapon icons, 5 to 55 minutes left, world buffs 30 min to 1:45 h (DemoRowExp). Keyed by the profile's entry table (stable across rebuilds).
    -- Room stays for 2 unwanted and 4 other demo buffs; nothing goes beyond the buff cap.
    -- Every group gets at least one active icon (user 2026-11-19): the budget covers one per group (+1 for the long
    -- world buff), still never beyond the cap.
    local candidates, groupOf, groups, nGroups = {}, {}, {}, 0
    for _, btn in ipairs(activeButtons) do
        if not btn.isActive and not btn.isWeapon then
            candidates[#candidates + 1] = btn.entry
            groupOf[btn.entry] = btn.grp
            if btn.grp and not groups[btn.grp] then groups[btn.grp], nGroups = true, nGroups + 1 end
        end
    end
    local budget = math.max(math.min(math.max(math.random(5, 20), nGroups + 1), #candidates, DemoFree() - 6), 0)
    local filled = {}
    -- always one 2-hour world buff with more than 100 minutes left (user 2026-11-14: shows the longest time text,
    -- e.g. "115m"), if the rows hold an inactive one
    local long = {}
    for i, entry in ipairs(candidates) do
        local b = type(entry) == "number" and ns.buffCatalog[entry]
        if b and b.cat == "world" and (b.dur or 0) >= 7200 then long[#long + 1] = i end
    end
    if #long > 0 and budget > 0 then
        local entry = table.remove(candidates, long[math.random(#long)])
        ns.demo.rows[entry] = now + math.random(101, 119) * 60
        ns.demo.nRows = ns.demo.nRows + 1
        budget = budget - 1
        if groupOf[entry] then filled[groupOf[entry]] = true end
    end
    for g in pairs(groups) do
        if not filled[g] and budget > 0 then
            local mine = {}
            for i, entry in ipairs(candidates) do
                if groupOf[entry] == g then mine[#mine + 1] = i end
            end
            local entry = table.remove(candidates, mine[math.random(#mine)])
            ns.demo.rows[entry] = DemoRowExp(entry, now)
            ns.demo.nRows = ns.demo.nRows + 1
            budget = budget - 1
        end
    end
    for _ = 1, budget do
        local entry = table.remove(candidates, math.random(#candidates))
        ns.demo.rows[entry] = DemoRowExp(entry, now)
        ns.demo.nRows = ns.demo.nRows + 1
    end
    for _ = 1, 2 do
        if DemoFree() > 0 then DemoAdd(ns.demo.buffs, ns.demo.unwantedDefs, now) end
    end
    for _ = 1, 4 do
        if DemoFree() > 0 then DemoAdd(ns.demo.buffs, ns.DEMO_BUFFS, now) end
    end
    for _ = 1, 2 do DemoAdd(ns.demo.debuffs, ns.DEMO_DEBUFFS, now) end
    demoTicker = C_Timer.NewTicker(1, DemoTick)
    ns:Print(L["Demo running (at most 1 minute): %d row icons active, other and unwanted buffs and debuffs come and go. Right-click removes only demo buffs, real ones stay; the X removes the unwanted ones. Clicking again or closing the options window ends it."], ns.demo.nRows)
    ns:RequestRebuild() -- bar shown, right-click off (out of combat, see above)
    DemoRefresh()
end

function ns:StopDemo()
    if not ns.demo then return end
    ns.demo = nil
    if demoTicker then demoTicker:Cancel() demoTicker = nil end
    ns:Print(L["Demo ended."])
    if InCombatLockdown() then
        -- right-click stays off until the fight ends (the safe direction), then the rebuild follows
        ns.pendingRebuild = true
        ns:UpdateAll()
    else
        ns:RequestRebuild()
    end
    DemoRefresh()
end

function ns:ToggleDemo()
    if ns.demo then ns:StopDemo() else ns:StartDemo() end
end

-- free buff slots left for the demo (button "Buffs hinzufügen")
function ns:DemoFree()
    return DemoFree()
end

-- Button "Buffs hinzufügen" (user 2026-11-10): fills the buff slots step by step, so the colour of the bar
-- (CapLevel) can be checked. Every click takes a random kind (user 2026-11-10: all kinds, not only "Sonstige"):
--   row   = an inactive icon of a visible row turns active (elixirs, potions, food, world buffs ...)
--   unw   = a buff of the list "Unerwünscht" (transformations ...) not shown yet
--   other = a demo buff for "Sonstige" (not shown yet first, then repeats)
-- Row icons get their demo time (DemoRowExp), the other buffs last until the demo ends.
local function DemoPickKind(demo)
    local kinds = {}
    local rows = {}
    for _, btn in ipairs(activeButtons) do
        if not btn.isActive and not btn.isWeapon and not demo.rows[btn.entry] then rows[#rows + 1] = btn.entry end
    end
    if #rows > 0 then kinds[#kinds + 1] = "row" end
    local unw = {}
    for _, def in ipairs(demo.unwantedDefs) do
        local taken = false
        for _, a in ipairs(demo.buffs) do
            if a.spellId == def.id then taken = true end
        end
        if not taken then unw[#unw + 1] = def end
    end
    if #unw > 0 then kinds[#kinds + 1] = "unw" end
    kinds[#kinds + 1] = "other"
    return kinds[math.random(#kinds)], rows, unw
end

function ns:DemoAddBuffs(n)
    local demo = ns.demo
    if not demo then return end
    local now = GetTime()
    local rowsChanged = false
    for _ = 1, n do
        if DemoFree() <= 0 then break end
        local kind, rows, unw = DemoPickKind(demo)
        if kind == "row" then
            local entry = rows[math.random(#rows)]
            demo.rows[entry] = DemoRowExp(entry, now)
            demo.nRows = demo.nRows + 1
            rowsChanged = true
        else
            local pool = unw
            if kind == "other" then
                pool = {}
                for _, def in ipairs(ns.DEMO_BUFFS) do
                    local taken = false
                    for _, a in ipairs(demo.buffs) do
                        if a.spellId == def.id then taken = true end
                    end
                    if not taken then pool[#pool + 1] = def end
                end
                if #pool == 0 then pool = ns.DEMO_BUFFS end
            end
            local aura = DemoAura(pool[math.random(#pool)], now)
            aura.expiration = demo.endTime + 1
            aura.duration = nil -- ends with the demo, not after its real duration: no yellow timer
            demo.buffs[#demo.buffs + 1] = aura
        end
    end
    if rowsChanged then ns:UpdateAll() end -- row icons read ns.demo.rows in UpdateButton
    DemoRefresh()
end

-- seconds left (for the options button), nil = not running
function ns:DemoLeft()
    return ns.demo and math.max(math.ceil(ns.demo.endTime - GetTime()), 0) or nil
end

-- right-click on a demo icon: just drop it
-- Right-click on a row icon that only the demo shows active (user 2026-11-11): it goes back to grey, like a
-- removed buff. Real buffs stay untouched (the rows have no cancel macro during the demo).
function ns:RemoveDemoRow(entry)
    local demo = ns.demo
    if not demo or not entry or not demo.rows[entry] then return false end
    demo.rows[entry] = nil
    demo.nRows = demo.nRows - 1
    GameTooltip:Hide()
    ns:UpdateAll()
    DemoRefresh()
    return true
end

function ns:RemoveDemoAura(aura)
    local demo = ns.demo
    if not demo then return end
    for _, list in ipairs({ demo.buffs, demo.debuffs }) do
        for i = #list, 1, -1 do
            if list[i] == aura then table.remove(list, i) end
        end
    end
    GameTooltip:Hide()
    DemoRefresh()
end
