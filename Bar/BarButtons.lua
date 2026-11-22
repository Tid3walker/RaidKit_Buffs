-- RaidKit Buffs: BarButtons
-- Row buttons: creation, tooltips and the use mode (secure attributes, only out of combat).
-- Shared names between the Bar*.lua files: Docs/Architecture.md "Leiste: Aufteilung in Dateien".

local _, ns = ...
local L = ns.L
local B, BS = ns.Bar, ns.BarState
local WEAPON_SLOT, FormatTimeLong, TimerText, HandMark = B.WEAPON_SLOT, B.FormatTimeLong, B.TimerText, B.HandMark

------------------------------------------------------------------------
-- Buttons
------------------------------------------------------------------------

local function ItemLabel(itemID)
    local name = ns.GetItemInfo(itemID)
    if name then return name end
    local e = ns.catalog[itemID]
    return e and e.name or ("Item #" .. itemID)
end

-- Tooltip of a foreign buff (negative ID): spell tooltip, state, what Ctrl+click and right-click do
local function BuffButton_OnEnter(self)
    local b = ns.buffCatalog[self.itemID]
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
    -- active: the real buff tooltip with its effect (2026-11-14); missing or demo: the spell (tipSpell for totems)
    local auraIndex = self.isActive and not self.isDemo and ns:FindBuffAuraIndex(self.itemID)
    -- mount not riding (2026-11-19): the tooltip of the mount Ctrl+click mounts (item or class spell)
    local mount = b.mount and not self.isActive and ns:MountPick()
    if auraIndex then
        GameTooltip:SetUnitBuff("player", auraIndex)
    elseif mount and mount.item then
        GameTooltip:SetItemByID(mount.item)
    elseif mount then
        GameTooltip:SetSpellByID(mount.spellID)
    else
        ns.SetBuffTip(b)
    end
    GameTooltip:AddLine(" ")
    if b.note then GameTooltip:AddLine(ns.Text(b.note), 0.4, 0.8, 1, true) end
    if self.isActive then
        if self.expiration and self.expiration > 0 then
            GameTooltip:AddLine(L["Active - %s left"]:format(FormatTimeLong(self.expiration - GetTime())), 0.2, 1, 0.2)
        else
            GameTooltip:AddLine(L["Active"], 0.2, 1, 0.2)
        end
    elseif b.mount then -- a mount is not a missing buff (user 2026-11-19)
        GameTooltip:AddLine(L["Not mounted"], 0.6, 0.6, 0.6)
    else
        GameTooltip:AddLine(L["Missing"], 1, 0.3, 0.3)
    end
    local entry = self.entry
    if ns.IsSlot(entry) then -- buff slot (mage armors, 2026-11-15): the variants like at an item slot
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Alternatives:"], 1, 1, 1)
        local pick = ns.EntryPick(entry)
        for _, id in ipairs(entry) do
            local text = (id == pick and "> " or "   ") .. ns.EntryName(id)
                .. (ns:GetItemBuffState(id) and (" |cff33ff33" .. L["active"] .. "|r") or "")
            if id == pick then GameTooltip:AddLine(text, 1, 0.82, 0) else GameTooltip:AddLine(text, 1, 1, 1) end
        end
    end
    if b.mount then
        if not self.isActive then
            local text = InCombatLockdown() and L["Ctrl+click: not in combat"] or mount and L["Ctrl+click: mount up"]
                or (ns.InAQ40() and L["No Qiraji crystal in the bags"] or L["No mount in the bags"])
            GameTooltip:AddLine(text, 0.6, 0.6, 0.6)
        end
    elseif self.selfSpell then
        GameTooltip:AddLine(L["Ctrl+click: cast %s"]:format(self.selfSpell), 0.6, 0.6, 0.6)
    else
        GameTooltip:AddLine(L["Foreign buff - Ctrl+click does nothing"], 0.6, 0.6, 0.6)
    end
    if ns.IsSlot(entry) then
        GameTooltip:AddLine(InCombatLockdown() and L["Mouse wheel: switch variant (not in combat)"] or L["Mouse wheel: switch variant"], 0.6, 0.6, 0.6)
    end
    if self.isDemo then
        GameTooltip:AddLine(L["Demo - not real. Right-click: remove"], 0.47, 0.75, 1)
    elseif self.isActive and self.canCancel then
        GameTooltip:AddLine(b.mount and L["Right-click: dismount"] or L["Right-click: remove buff"], 0.6, 0.6, 0.6)
    end
    GameTooltip:AddLine(L["Shift+drag: move bar"], 0.6, 0.6, 0.6)
    GameTooltip:AddLine(L["Shift+right-click: options"], 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

-- Tooltip of a weapon entry: the weapon itself (shows its enchant), state, variants, what Ctrl+click does
local HAND_NAME = ns.LocalizedTable({ main = "Main hand", off = "Off hand" })
local function WeaponButton_OnEnter(self)
    local slot = WEAPON_SLOT[self.hand]
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
    if not GetInventoryItemID("player", slot) or not GameTooltip:SetInventoryItem("player", slot) then
        GameTooltip:SetText(L["Weapon: %s"]:format(HAND_NAME[self.hand]))
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["RaidKit Buffs: %s (slot %d)"]:format(HAND_NAME[self.hand], slot), 1, 0.82, 0)
    if self.isWindfury then
        GameTooltip:AddLine(L["Windfury (totem) active - takes priority over the stone"], 0.3, 0.66, 1, true)
    elseif self.noWeapon then
        GameTooltip:AddLine(L["No weapon in the off hand"], 1, 0.3, 0.3)
    elseif self.isActive then
        GameTooltip:AddLine(L["Active - %s left"]:format(FormatTimeLong(math.max((self.expiration or 0) - GetTime(), 0))), 0.2, 1, 0.2)
    elseif self.otherEnchant then
        GameTooltip:AddLine(L["Other enchant: %s"]:format(ns.WEAPON_ENCHANT_NAMES[self.otherEnchant] or ("#" .. self.otherEnchant)), 1, 0.82, 0)
    else
        GameTooltip:AddLine(L["Missing"], 1, 0.3, 0.3)
    end
    local entry, pick = self.entry, ns.EntryPick(self.entry)
    GameTooltip:AddLine(L["Variants:"], 1, 1, 1)
    for _, id in ipairs(entry) do
        local count = ns.GetItemCount(id) or 0
        local text = (id == pick and "> " or "   ") .. ItemLabel(id)
            .. (count > 0 and (" |cff999999(" .. count .. ")|r") or " |cffff4040(0)|r")
        if id == pick then GameTooltip:AddLine(text, 1, 0.82, 0) else GameTooltip:AddLine(text, 1, 1, 1) end
    end
    if ns.profile.useMode == "ctrl" then
        local text
        if InCombatLockdown() then text = L["Ctrl+click: not in combat"]
        elseif self.isWindfury then text = L["Ctrl+click: locked (Windfury)"]
        elseif self.noWeapon then text = L["Ctrl+click: nothing (no weapon)"]
        elseif self.isActive then text = L["Ctrl+click: nothing (already active)"]
        elseif not self.useID then text = L["Ctrl+click: nothing in the bags"]
        else text = L["Ctrl+click: %s on the %s"]:format(ItemLabel(self.useID), HAND_NAME[self.hand]) end
        GameTooltip:AddLine(text, 0.6, 0.6, 0.6)
    end
    if #entry > 1 then GameTooltip:AddLine(L["Mouse wheel: switch variant"], 0.6, 0.6, 0.6) end
    GameTooltip:AddLine(L["Shift+right-click: options"], 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

local function Button_OnEnter(self)
    if not self.itemID then return end
    if self.isWeapon then return WeaponButton_OnEnter(self) end
    if self.isBuff then return BuffButton_OnEnter(self) end
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
    GameTooltip:SetItemByID(self.itemID)
    GameTooltip:AddLine(" ")
    if self.isActive then
        if self.expiration and self.expiration > 0 then
            GameTooltip:AddLine(L["Active - %s left"]:format(FormatTimeLong(self.expiration - GetTime())), 0.2, 1, 0.2)
        else
            GameTooltip:AddLine(L["Active"], 0.2, 1, 0.2)
        end
    else
        GameTooltip:AddLine(L["Missing"], 1, 0.3, 0.3)
    end
    GameTooltip:AddLine(L["In bags: %d"]:format(self.bagCount or 0), 1, 1, 1)
    local entry = self.entry
    if ns.IsSlot(entry) then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Alternatives:"], 1, 1, 1)
        local pick = ns.EntryPick(entry)
        for _, id in ipairs(entry) do
            local count = ns.GetItemCount(id) or 0
            local text = (id == pick and "> " or "   ") .. ItemLabel(id)
                .. (count > 0 and (" |cff999999(" .. count .. ")|r") or " |cffff4040(0)|r")
                .. (ns:GetItemBuffState(id) and (" |cff33ff33" .. L["active"] .. "|r") or "")
            if id == pick then GameTooltip:AddLine(text, 1, 0.82, 0) else GameTooltip:AddLine(text, 1, 1, 1) end
        end
    end
    if ns.profile.useMode == "ctrl" then
        local text
        if self.combatLocked then
            text = L["Ctrl+click: locked until combat ends (was active when combat started)"]
        elseif self.isActive and not InCombatLockdown() then
            text = L["Ctrl+click: nothing (buff already active)"]
        elseif not self.useID then
            text = L["Ctrl+click: nothing in the bags"]
        else
            text = (self.useID ~= ns.EntryPick(entry) and L["Ctrl+click: %s (substitute)"] or L["Ctrl+click: %s"])
                :format(ItemLabel(self.useID))
        end
        GameTooltip:AddLine(text, 0.6, 0.6, 0.6)
    end
    if ns.IsSlot(entry) then
        GameTooltip:AddLine(InCombatLockdown() and L["Mouse wheel: switch variant (not in combat)"] or L["Mouse wheel: switch variant"], 0.6, 0.6, 0.6)
    end
    if self.isDemo then
        GameTooltip:AddLine(L["Demo - not real. Right-click: remove"], 0.47, 0.75, 1)
    elseif self.isActive and self.canCancel then
        GameTooltip:AddLine(L["Right-click: remove buff"], 0.6, 0.6, 0.6)
    end
    GameTooltip:AddLine(L["Shift+drag: move bar"], 0.6, 0.6, 0.6)
    GameTooltip:AddLine(L["Shift+right-click: options"], 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

local function Button_OnLeave()
    GameTooltip:Hide()
end

local function CreateButton(index)
    local btn = CreateFrame("Button", "RaidKitBuffsButton" .. index, BS.container, "SecureActionButtonTemplate")
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetFrameLevel(BS.container:GetFrameLevel() + 5) -- above the outline
    -- Shift+drag moves the whole bar (the Shift click itself does nothing, see ApplyUseMode)
    btn:RegisterForDrag("LeftButton")
    -- with the options window open plain dragging moves too (Ctrl+click is a click, not a drag)
    -- groups (2026-11-11): moves the group the button belongs to (its parent frame)
    btn:SetScript("OnDragStart", function(self) if IsShiftKeyDown() or ns.optionsOpen then B.StartMove(self:GetParent()) end end)
    btn:SetScript("OnDragStop", function() B.StopMove() end)
    -- Shift+right-click opens the options (runs after the secure click, which does nothing with Shift).
    -- Clicks fire on down and up, so react only to the release.
    btn:SetScript("PostClick", function(_, button, down)
        if button == "RightButton" and not down and IsShiftKeyDown() then ns:ToggleOptions() end
        -- plain right-click removed the buff on purpose: no loss alarm for it
        if button == "RightButton" and not IsShiftKeyDown() then ns.lastCancel = GetTime() end
        -- demo (2026-11-11): right-click on an icon the demo shows active drops just that (no cancel macro then)
        if button == "RightButton" and not down and not IsShiftKeyDown() and ns.demo then
            ns:RemoveDemoRow(btn.entry)
        end
    end)

    btn.border = btn:CreateTexture(nil, "BACKGROUND")
    btn.border:SetPoint("TOPLEFT", -1, 1)
    btn.border:SetPoint("BOTTOMRIGHT", 1, -1)

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    btn.cooldown:SetAllPoints()
    btn.cooldown:SetDrawEdge(false)
    btn.cooldown:SetHideCountdownNumbers(true)

    -- Texts above the cooldown swipe
    local overlay = CreateFrame("Frame", nil, btn)
    overlay:SetAllPoints()
    overlay:SetFrameLevel(btn.cooldown:GetFrameLevel() + 1)

    btn.count = overlay:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    btn.count:SetPoint("BOTTOMRIGHT", -1, 2)
    do -- bag count 2 points smaller (user 2026-11-10)
        local font, size, flags = btn.count:GetFont()
        if font and size then btn.count:SetFont(font, size - 2, flags) end
    end

    btn.timer = TimerText(overlay)

    -- status mark bottom left: since 2026-11-10 (user) only the lock (locked in combat); check and cross are
    -- hidden (SHOW_STATUS_MARKS), the grey icon already tells what is missing. Maybe an option later.
    btn.status = overlay:CreateTexture(nil, "OVERLAY")
    btn.status:SetSize(12, 12)
    btn.status:SetPoint("BOTTOMLEFT", 1, 1)
    -- gold corner top right: the icon is a slot with alternatives
    btn.slotMark = overlay:CreateTexture(nil, "OVERLAY")
    btn.slotMark:SetSize(6, 6)
    btn.slotMark:SetPoint("TOPRIGHT", -1, -1)
    btn.slotMark:SetColorTexture(1, 0.82, 0, 1)
    btn.slotMark:Hide()
    -- weapon entries (2026-11-09): "MH" = main hand, "OH" = off hand, since 2026-11-14 bottom left (HandMark)
    btn.handMark = HandMark(overlay)
    btn.handBg = btn.handMark.bg
    btn.handBg:Hide()
    btn.handMark:Hide()

    -- mouse wheel on a slot: chosen variant (changes the secure "item" attribute, so not in combat)
    btn:SetScript("OnMouseWheel", function(self, delta)
        local entry = self.entry
        if not ns.IsSlot(entry) then return end
        if InCombatLockdown() then
            UIErrorsFrame:AddMessage(L["Switching the variant only works out of combat."], 1, 0.2, 0.2)
            return
        end
        local pick, n, k = ns.EntryPick(entry), #entry, 1
        for i, id in ipairs(entry) do if id == pick then k = i end end
        k = delta < 0 and (k % n) + 1 or ((k - 2) % n) + 1
        entry.pick = entry[k]
        ns:UpdateAll()
        if ns.RefreshOptions then ns:RefreshOptions() end
        if GameTooltip:IsOwned(self) then Button_OnEnter(self) end
    end)

    btn:SetScript("OnEnter", Button_OnEnter)
    btn:SetScript("OnLeave", Button_OnLeave)
    return btn
end

------------------------------------------------------------------------
-- Use mode (secure attributes, set only out of combat!)
------------------------------------------------------------------------

-- "ctrl" = only Ctrl+left-click uses the item (default since schema 8)
-- "off"  = display only, clicks use nothing
-- ("right" = right-click uses, until schema 8; migrated to "ctrl" in Core.lua)
-- In every mode a plain right-click removes the item's buff, like on the Blizzard buff bar.
-- Shift is reserved: Shift+drag moves the bar, Shift+right-click opens the options.
ns.USE_MODES = { "ctrl", "off" }
-- translated on access (ns.LocalizedTable): built while the files load, before the language is known
ns.USE_MODE_LABEL = ns.LocalizedTable({ ctrl = "Ctrl+click", off = "Off (display only)" })
ns.USE_MODE_HINT = ns.LocalizedTable({ ctrl = "Ctrl+click: use" })

-- "/cancelaura <name>" for every buff of every variant of the entry
-- (names deduplicated; an inactive one does nothing)
local function CancelMacro(entry)
    local mb = ns.buffCatalog[ns.EntryMain(entry)]
    if mb and mb.mount then return "/dismount" end -- mount (2026-11-17)
    local lines, seen = {}, {}
    for _, itemID in ipairs(ns.EntryIDs(entry)) do
        for _, spellID in ipairs(ns:GetBuffSpellsForItem(itemID)) do
            local name = ns.GetSpellName(spellID)
            if name and not seen[name] then
                seen[name] = true
                lines[#lines + 1] = "/cancelaura " .. name
            end
        end
    end
    return #lines > 0 and table.concat(lines, "\n") or nil
end

-- What Ctrl+click uses: the chosen variant, else the next one in the bags (list order); nil = none in the bags
local function UseTarget(entry)
    local pick = ns.EntryPick(entry)
    if ns.IsBuffID(pick) then return nil end -- buffs are not in the bags
    if (ns.GetItemCount(pick) or 0) > 0 then return pick end
    for _, id in ipairs(ns.EntryIDs(entry)) do
        if (ns.GetItemCount(id) or 0) > 0 then return id end
    end
end

-- Dynamic part of the use mode, only out of combat (called from UpdateButton on every aura/bag change):
-- "item" = what Ctrl+click would use; Ctrl+click is off while the buff (any variant) is active, so a
-- running buff is never replaced by accident (remove it with right-click first).
local function UpdateSecure(btn)
    if InCombatLockdown() or not btn.entry then return end
    if btn.isWeapon then
        -- weapon: "/use <stone>" puts the cursor in targeting mode, "/use 16|17" applies it to that hand.
        -- Off while active, while Windfury is on the main hand (stone wasted or blocking it), without an
        -- off-hand weapon and without stones in the bags. Never in combat (OnCombatStart).
        local ok = ns.profile.useMode == "ctrl" and not btn.isActive and not btn.noWeapon and btn.useID ~= nil
        btn:SetAttribute("ctrl-type1", ok and "macro" or nil)
        btn:SetAttribute("ctrl-macrotext1", ok and ("/use item:" .. btn.useID .. "\n/use " .. WEAPON_SLOT[btn.hand]) or nil)
        return
    end
    local mb = btn.isBuff and ns.buffCatalog[ns.EntryMain(btn.entry)]
    if mb and mb.mount then
        -- mount (2026-11-19): not riding = Ctrl+click mounts ns:MountPick() (item or class spell); riding = nothing
        -- (right-click dismounts). Out of combat only, like every attribute.
        local m = not btn.isActive and ns:MountPick()
        local ok = ns.profile.useMode == "ctrl" and m
        btn:SetAttribute("ctrl-unit1", nil)
        btn:SetAttribute("item", ok and m.item and ("item:" .. m.item) or nil)
        btn:SetAttribute("spell", ok and m.spell or nil)
        btn:SetAttribute("ctrl-type1", ok and (m.item and "item" or "spell") or nil)
        return
    end
    if btn.isBuff then
        -- own buff (Battle Shout): Ctrl+click casts it unless it is active (like items); foreign: nothing.
        -- A buff slot (mage armors, 2026-11-15) casts the chosen variant (mouse wheel changes it)
        local pb = ns.buffCatalog[ns.EntryPick(btn.entry)]
        btn.selfSpell = pb and ns.IsOwnBuff(pb) and ns.OwnCastName(pb) or nil
        btn:SetAttribute("spell", btn.selfSpell)
        btn:SetAttribute("ctrl-unit1", btn.selfSpell and "player" or nil)
        btn:SetAttribute("ctrl-type1", ns.profile.useMode == "ctrl" and btn.selfSpell and not btn.isActive and "spell" or nil)
        return
    end
    btn:SetAttribute("item", "item:" .. (btn.useID or ns.EntryPick(btn.entry)))
    btn:SetAttribute("ctrl-type1", ns.profile.useMode == "ctrl" and not btn.isActive and "item" or nil)
end

function ns:ApplyUseMode(btn, entry)
    -- Clear every possible variant, then set the one we need.
    btn:SetAttribute("type", nil)
    btn:SetAttribute("type1", nil)
    btn:SetAttribute("type2", nil)
    btn:SetAttribute("ctrl-type1", nil)
    btn:SetAttribute("macrotext2", nil)
    btn:SetAttribute("ctrl-macrotext1", nil)
    btn:SetAttribute("spell", nil)
    btn.isWeapon = ns.IsWeaponEntry(entry)
    btn.hand = btn.isWeapon and entry.hand or nil
    -- foreign buff (negative ID): no item; an own buff gets its spell name for Ctrl+click
    btn.isBuff = ns.buffCatalog[ns.EntryMain(entry)] ~= nil
    -- own buffs (2026-11-14): Battle Shout and the class buffs of selfClass (single-target spell, selfCast); a buff
    -- slot casts its chosen variant (2026-11-15, set again in UpdateSecure when the mouse wheel changes it)
    local b = ns.buffCatalog[ns.EntryPick(entry)]
    btn.selfSpell = b and ns.IsOwnBuff(b) and ns.OwnCastName(b) or nil
    -- an own buff goes on the player, also with a friendly target selected (else Fortitude would buff the target)
    btn:SetAttribute("ctrl-unit1", btn.selfSpell and "player" or nil)
    if b then
        btn:SetAttribute("item", nil)
        if btn.selfSpell then btn:SetAttribute("spell", btn.selfSpell) end
    elseif btn.isWeapon then
        btn:SetAttribute("item", nil) -- macro set in UpdateSecure
    else
        btn:SetAttribute("item", "item:" .. ns.EntryPick(entry))
    end
    -- "macro" with an empty macrotext does nothing: Shift clicks never use or cancel anything
    btn:SetAttribute("shift-type1", "macro")
    btn:SetAttribute("shift-type2", "macro")
    btn:SetAttribute("shift-macrotext1", "")
    btn:SetAttribute("shift-macrotext2", "")
    -- "ctrl-type1" and the final "item" follow in UpdateSecure (depends on buff and bags)
    -- plain right-click: remove the buff (secure macro, so it also works in combat)
    -- weapon enchants cannot be removed here (CancelItemTempEnchantment is risky in addons, PitBull avoids it too)
    -- demo (2026-11-10): no removing at all, so clicking around never cancels a real potion/flask
    local cancel = not btn.isWeapon and not ns.demo and CancelMacro(entry) or nil
    btn.canCancel = cancel ~= nil
    if cancel then
        btn:SetAttribute("type2", "macro")
        btn:SetAttribute("macrotext2", cancel)
    end
end

-- shared with the other Bar*.lua files
B.Button_OnEnter = Button_OnEnter
B.CreateButton = CreateButton
B.UseTarget = UseTarget
B.UpdateSecure = UpdateSecure
