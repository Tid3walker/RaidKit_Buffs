-- RaidKit Buffs: BarAreaIcons
-- Icons of the buff areas (other, weapon, debuff, unwanted) and the three area frames (CreateAreas).
-- Shared names between the Bar*.lua files: Docs/Architecture.md "Leiste: Aufteilung in Dateien".

local _, ns = ...
local L = ns.L
local B, BS = ns.Bar, ns.BarState
local areaFrames, TimerText, HandMark = B.areaFrames, B.TimerText, B.HandMark

-- Frame levels (2026-11-10): the secure button of the row "Unerwünschte Buffs" lies at area + 2 (above the
-- outline at + 1) and keeps its place in combat; every icon lies above it (+ 3), so its own mouse handling wins.
local ICON_LEVEL = 3

-- icons of the areas can be dragged with Shift (and while editing): they move their area (2026-11-11)
local function AreaDrag(o)
    o:RegisterForDrag("LeftButton")
    o:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() or ns.optionsOpen then B.StartMove(self:GetParent()) end
    end)
    o:SetScript("OnDragStop", function() B.StopMove() end)
end

local function CreateOtherIcon(i)
    local o = CreateFrame("Button", nil, BS.extra)
    o:SetFrameLevel(BS.extra:GetFrameLevel() + ICON_LEVEL)
    o:RegisterForClicks("RightButtonUp")
    o.border = o:CreateTexture(nil, "BACKGROUND")
    o.border:SetPoint("TOPLEFT", -1, 1)
    o.border:SetPoint("BOTTOMRIGHT", 1, -1)
    o.icon = o:CreateTexture(nil, "ARTWORK")
    o.icon:SetAllPoints()
    o.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    o.timer = TimerText(o) -- inside the icon like the rows (2026-11-12)
    o:SetScript("OnEnter", function(self)
        if not self.aura then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        if self.aura.demo then
            GameTooltip:SetSpellByID(self.aura.spellId)
            GameTooltip:AddLine(L["Demo - not real"], 0.47, 0.75, 1)
            GameTooltip:Show()
            return
        end
        GameTooltip:SetUnitBuff("player", self.aura.index)
        if self.unwanted then GameTooltip:AddLine(L["Unwanted"], 1, 0.3, 0.3) end
        GameTooltip:AddLine(InCombatLockdown() and L["Right-click: remove (not possible in combat)"] or L["Right-click: remove"], 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    o:SetScript("OnLeave", function() GameTooltip:Hide() end)
    o:SetScript("OnClick", function(self, button)
        if B.ShiftOptions(button) then return end -- Shift+right-click = options, never removes (2026-11-14)
        if not self.aura then return end
        if self.aura.demo then ns:RemoveDemoAura(self.aura) return end -- demo: just drop it
        if ns.demo then -- real buff during the demo: never removed (user 2026-11-10)
            UIErrorsFrame:AddMessage(L["No real buffs are removed during the demo."], 1, 0.2, 0.2)
            return
        end
        if InCombatLockdown() then
            UIErrorsFrame:AddMessage(L["Cannot be removed in combat (comes with the buff bar replacement)."], 1, 0.2, 0.2)
            return
        end
        CancelUnitBuff("player", self.aura.index)
    end)
    AreaDrag(o)
    B.otherPool[i] = o
    return o
end

-- Weapon enchants of hands that no row covers (Windfury, poisons, oils ...), first under "Sonstige" with H/N
local weaponPool = {}
local function CreateWeaponIcon(i)
    local o = CreateFrame("Frame", nil, BS.extra)
    o:SetFrameLevel(BS.extra:GetFrameLevel() + ICON_LEVEL)
    o:EnableMouse(true)
    o.border = o:CreateTexture(nil, "BACKGROUND")
    o.border:SetPoint("TOPLEFT", -1, 1)
    o.border:SetPoint("BOTTOMRIGHT", 1, -1)
    o.border:SetColorTexture(0.69, 0.28, 0.97, 1)
    o.icon = o:CreateTexture(nil, "ARTWORK")
    o.icon:SetAllPoints()
    o.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    o.handMark = HandMark(o) -- bottom left like the rows (2026-11-14)
    o.timer = TimerText(o) -- inside the icon like the rows (2026-11-12)
    o:SetScript("OnEnter", function(self)
        if not self.slot then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetInventoryItem("player", self.slot)
        GameTooltip:Show()
    end)
    o:SetScript("OnLeave", function() GameTooltip:Hide() end)
    o:SetScript("OnMouseUp", function(_, button) B.ShiftOptions(button) end)
    AreaDrag(o)
    weaponPool[i] = o
    return o
end

-- Debuff icons (2026-11-09): only while the bar replaces the Blizzard bar. Border = DebuffTypeColor,
-- stack count bottom right, no right-click (debuffs cannot be removed).
local debuffPool = {}
local function CreateDebuffIcon(i)
    local o = CreateFrame("Frame", nil, BS.extra)
    o:SetFrameLevel(BS.extra:GetFrameLevel() + ICON_LEVEL)
    o:EnableMouse(true)
    o.border = o:CreateTexture(nil, "BACKGROUND")
    o.border:SetPoint("TOPLEFT", -1, 1)
    o.border:SetPoint("BOTTOMRIGHT", 1, -1)
    o.icon = o:CreateTexture(nil, "ARTWORK")
    o.icon:SetAllPoints()
    o.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    o.count = o:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    o.count:SetPoint("BOTTOMRIGHT", 1, -1)
    o.timer = TimerText(o) -- inside the icon like the rows (2026-11-12)
    o:SetScript("OnEnter", function(self)
        if not self.aura then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        if self.aura.demo then
            GameTooltip:SetSpellByID(self.aura.spellId)
            GameTooltip:AddLine(L["Demo - not real"], 0.47, 0.75, 1)
        else
            GameTooltip:SetUnitDebuff("player", self.aura.index)
        end
        GameTooltip:Show()
    end)
    o:SetScript("OnLeave", function() GameTooltip:Hide() end)
    o:SetScript("OnMouseUp", function(_, button) B.ShiftOptions(button) end)
    AreaDrag(o)
    debuffPool[i] = o
    return o
end

-- Icons of the row "Unerwünschte Buffs" (2026-11-10), red border, timer below. Since 2026-11-11 (user) they
-- have their own mouse handling and lie above the secure button (ICON_LEVEL): right-click removes just this
-- buff (out of combat, CancelUnitBuff like "Sonstige"). Clicks on the X (and next to the icons) still reach
-- the secure button, which removes all, also in combat. The hit rect covers the gaps and the timer below,
-- so a click near an icon never removes all by accident.
local unwPool = {}
local function CreateUnwIcon(i)
    local o = CreateFrame("Button", nil, BS.extra)
    o:SetFrameLevel(BS.extra:GetFrameLevel() + ICON_LEVEL)
    o:RegisterForClicks("AnyUp")
    o.border = o:CreateTexture(nil, "BACKGROUND")
    o.border:SetPoint("TOPLEFT", -1, 1)
    o.border:SetPoint("BOTTOMRIGHT", 1, -1)
    o.border:SetColorTexture(1, 0.19, 0.19, 1)
    o.icon = o:CreateTexture(nil, "ARTWORK")
    o.icon:SetAllPoints()
    o.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    o.timer = TimerText(o) -- inside the icon like the rows (2026-11-12)
    o:SetScript("OnEnter", function(self)
        if not self.aura then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        if self.aura.demo then
            GameTooltip:SetSpellByID(self.aura.spellId)
            GameTooltip:AddLine(L["Demo - not real"], 0.47, 0.75, 1)
        else
            GameTooltip:SetUnitBuff("player", self.aura.index)
        end
        GameTooltip:AddLine(L["Unwanted"], 1, 0.3, 0.3)
        GameTooltip:AddLine((InCombatLockdown() and not self.aura.demo) and L["Right-click: remove only this one (not possible in combat)"]
            or L["Right-click: remove only this one"], 0.6, 0.6, 0.6)
        GameTooltip:AddLine(L["Click the X: remove all (also in combat)"], 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    o:SetScript("OnLeave", function() GameTooltip:Hide() end)
    o:SetScript("OnClick", function(self, button)
        if B.ShiftOptions(button) then return end -- Shift+right-click = options, never removes (2026-11-14)
        if button ~= "RightButton" or not self.aura then return end -- left-click on an icon: nothing
        if self.aura.demo then ns:RemoveDemoAura(self.aura) return end
        if ns.demo then
            UIErrorsFrame:AddMessage(L["No real buffs are removed during the demo."], 1, 0.2, 0.2)
            return
        end
        if InCombatLockdown() then
            UIErrorsFrame:AddMessage(L["Cannot be removed one by one in combat. The X removes all."], 1, 0.2, 0.2)
            return
        end
        CancelUnitBuff("player", self.aura.index)
    end)
    AreaDrag(o)
    unwPool[i] = o
    return o
end

-- preview of the maximum size (edges + placeholders), shown together with the outlines
local function NewPreview(r, g, b)
    local pv = CreateFrame("Frame", nil, BS.extra)
    pv:SetFrameLevel(BS.extra:GetFrameLevel() + 1)
    pv:EnableMouse(false)
    pv:Hide()
    pv.edges, pv.cells, pv.rgb = {}, {}, { r, g, b }
    for k = 1, 4 do
        local e = pv:CreateTexture(nil, "OVERLAY")
        e:SetColorTexture(r, g, b, 0.8)
        pv.edges[k] = e
    end
    return pv
end

-- The three area frames (2026-11-11): plain group frames anchored to UIParent; only "Unerwünscht" holds a secure
-- button (so it never moves or hides in combat). Each one: name (like a row name), preview, its icons.
local function CreateAreas()
    for _, a in ipairs({ "unw", "other", "debuff" }) do
        local f = B.CreateGroupFrame("RaidKitBuffsArea_" .. a)
        f.area = a
        f.secure = a == "unw"
        f.width = 1
        areaFrames[a] = f
        BS.extra = f
        f.label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") -- name, placed by PlaceName
        f.label:SetTextColor(0.78, 0.78, 0.82) -- like the group name of a group with rows (2026-11-15; before gold)
        if a == "unw" then
            -- row "Unerwünschte Buffs" (user 2026-11-10, replaces the small red button): an invisible secure button
            -- (macro "/cancelaura ...", works in combat) over the whole row, the icons lie above it (CreateUnwIcon).
            -- Position and size only out of combat (LayoutAreas): as large as the whole list could get.
            local unw = CreateFrame("Button", "RaidKitBuffsUnwantedButton", f, "SecureActionButtonTemplate")
            unw:SetFrameLevel(f:GetFrameLevel() + 2)
            unw:SetSize(1, 1)
            unw:RegisterForClicks("AnyUp", "AnyDown")
            unw:SetAttribute("type1", "macro")
            -- Shift is reserved for moving (like the row buttons): a Shift click runs an empty macro (review 2026-11-11)
            unw:SetAttribute("shift-type1", "macro")
            unw:SetAttribute("shift-macrotext1", "")
            unw:SetScript("PostClick", function(_, button, down)
                -- Shift+right-click opens the options (2026-11-14); the secure part ignores right-clicks
                if button == "RightButton" and IsShiftKeyDown() then
                    if not down then B.ShiftOptions(button) end
                    return
                end
                ns.lastCancel = GetTime()
                if ns.demo then ns:RemoveDemoUnwanted() end -- demo (2026-11-10): its unwanted buffs go too
            end)
            unw:SetScript("OnEnter", function(self)
                if not self.active or #self.active == 0 then return end
                if f.SetUnwHover then f.SetUnwHover(true) end -- red frame: "a click removes these"
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
                GameTooltip:SetText(f.g and ns.GroupDisplayName(f.g) or L["Unwanted Buffs"], 1, 0.3, 0.3)
                for _, au in ipairs(self.active) do GameTooltip:AddLine(au.name or "?", 1, 1, 1) end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(L["Click the X: remove all (also in combat)"], 0.6, 0.6, 0.6)
                GameTooltip:AddLine(L["Right-click an icon: remove only this one"], 0.6, 0.6, 0.6)
                GameTooltip:AddLine(L["List: options, catalog tab \"Buffs\""], 0.6, 0.6, 0.6)
                GameTooltip:Show()
            end)
            unw:SetScript("OnLeave", function()
                GameTooltip:Hide()
                if f.SetUnwHover then f.SetUnwHover(false) end
            end)
            f.button = unw
            -- the row looks like a button (user 2026-11-11, chosen in the mockup): dark background, 1 px gold frame,
            -- red X at the end; red frame while the mouse is over it. Only as wide as the icons plus the X cell.
            local box = { edges = {} }
            box.bg = f:CreateTexture(nil, "BACKGROUND", nil, 2)
            box.bg:SetColorTexture(0.13, 0.09, 0.04, 0.9)
            for k = 1, 4 do
                box.edges[k] = f:CreateTexture(nil, "BORDER", nil, 1)
                box.edges[k]:SetColorTexture(0.54, 0.43, 0.12, 1)
            end
            box.x = f:CreateTexture(nil, "ARTWORK")
            box.x:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
            box.x:SetSize(12, 12)
            function box:SetShown(on)
                self.bg:SetShown(on)
                self.x:SetShown(on)
                for _, e in ipairs(self.edges) do e:SetShown(on) end
            end
            box:SetShown(false)
            f.unwBox = box
            f.SetUnwHover = function(on)
                for _, e in ipairs(box.edges) do
                    if on then e:SetColorTexture(1, 0.25, 0.25, 1) else e:SetColorTexture(0.54, 0.43, 0.12, 1) end
                end
            end
            f.preview = NewPreview(1, 0.25, 0.25) -- one red cell while empty and the previews show
        elseif a == "other" then
            -- the counter "Buffs n/32" (session 4b, hidden since 4c) is gone since 2026-11-25: the "Buff counter" in a
            -- row replaces it (B.UpdateCounterButton in BarAreas.lua)
            f.preview = NewPreview(0.1, 0.6, 1) -- blue: room for "Sonstige"
        else
            -- debuff section: the name, then the icons. Its divider (f.debLine, 2026-11-11) is the group separator
            -- since 2026-11-14 (PlaceSeparator, option "Trenner anzeigen", default on here)
            f.preview = NewPreview(1, 0.2, 0.2) -- red: maximum of debuffs
        end
    end
    BS.extra = areaFrames.other
end

-- shared with the other Bar*.lua files
B.CreateOtherIcon = CreateOtherIcon
B.weaponPool = weaponPool
B.CreateWeaponIcon = CreateWeaponIcon
B.debuffPool = debuffPool
B.CreateDebuffIcon = CreateDebuffIcon
B.unwPool = unwPool
B.CreateUnwIcon = CreateUnwIcon
B.CreateAreas = CreateAreas
