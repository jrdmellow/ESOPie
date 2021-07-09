if not ESOPie then
    d("ESOPie not initialized properly!")
    return
end

local L = GetString
local GetValueSafe = function(table, sub, default)
    if table and table[sub] then return table[sub] end
    return default
end

-- TODO: figure out a way to support these
local ESOPIE_INACCESSIBLE_SLASH_COMMANDS = {
    "/s", "/say", "/y", "/yell", "/t", "/tell", "/w", "/whisper", "/r", "/reply",
    "/respond", "/e", "/emote", "/me", "/p", "/party", "/group",
    "/g1", "/guild1", "/g2", "/guild2", "/g3", "/guild3", "/g4", "/guild4", "/g5", "/guild5",
    "/o1", "/officer1", "/o2", "/officer2", "/o3", "/officer3", "/o4", "/officer4", "/o5", "/officer5",
    "/z", "/zone", "/zen", "/zde", "/zfr", "/zjp", "/zru",
    "/dezone", "/frzone", "/enzone", "/jpzone", "/ruzone",
}

local LogVerboseC = ESOPie.LogVerboseC
local LogVerbose = ESOPie.LogVerbose
local LogDebug = ESOPie.LogDebug
local LogInfo = ESOPie.LogInfo
local LogWarning = ESOPie.LogWarning
local LogError = ESOPie.LogError
local Notify = ESOPie.Notify

-------------------------------------------------------------------------------
-- ESOPie Handler

function ESOPie:ExecuteChatCommand(entry, commandStr)
    assert(entry)
    LogVerboseC("debugExecution", "ExecuteChatCommand(%s): %s", entry.name or "nil", commandStr or "nil")
    if not commandStr then Notify(ZO_CachedStrFormat(L(ESOPIE_SI_CHAT_NOCOMMAND), ZO_SELECTED_TEXT:Colorize(entry.name))) return end
    if not commandStr:find("/") == 1 then Notify(ZO_CachedStrFormat(L(ESOPIE_SI_CHAT_INVALIDFIRSTCHAR), ZO_SELECTED_TEXT:Colorize(entry.name))) return end
    local command = nil
    local args = nil
    local p = commandStr:find(" ")
    if p then
        command = commandStr:sub(1, p-1)
        args = commandStr:sub(p+1)
    else
        command = commandStr
    end
    for i, cmd in pairs(ESOPIE_INACCESSIBLE_SLASH_COMMANDS) do
        if cmd == command then
            Notify(L(ESOPIE_SI_CHAT_COMMANDNOTSUPPORTED))
            return
        end
    end
    SLASH_COMMANDS[command](args) -- TODO: Hacky. Better way?
end

function ESOPie:ExecuteCustomCommand(entry, luaCode)
    assert(entry)
    LogVerboseC("debugExecution", "ExecuteCustomCommand(%s): %s", entry.name or "nil", luaCode or "nil")
    if not luaCode then Notify(ZO_CachedStrFormat(L(ESOPIE_SI_LUA_NOCODE), ZO_SELECTED_TEXT:Colorize(entry.name))) return end
    local f = assert(zo_loadstring(luaCode))
    f()
end

function ESOPie:ExecuteEmote(entry, itemId)
    assert(entry and itemId)
    LogVerboseC("debugExecution", "ExecuteEmote(%s): %d", entry.name or "nil", itemId or "nil")
    if not itemId or type(itemId) ~= "number" then LogWarning("Emote payload is invalid.") return end
    local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(itemId)
    if emoteInfo then
        PlayEmoteByIndex(emoteInfo.emoteIndex)
    end
end

function ESOPie:ExecuteUseCollectible(entry, itemId)
    assert(entry)
    LogVerboseC("debugExecution", "ExecuteUseCollectible(%s): %d", entry.name or "nil", itemId or "nil")
    if not itemId or type(itemId) ~= "number" then LogWarning("Collectible payload is invalid.") return end
    if IsCollectibleUnlocked(itemId) then
        UseCollectible(itemId, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    else
        Notify(ZO_CachedStrFormat(L(ESOPIE_SI_COLLECTIBLE_NOTUNLOCKED), ZO_SELECTED_TEXT:Colorize(GetCollectibleName(itemId))))
    end
end

function ESOPie:ExecuteGoToHome(entry, data)
    assert(entry)
    LogVerboseC("debugExecution", "ExecuteUseCollectible(%s): %s", entry.name or "nil", data or "nil")
    if not CanLeaveCurrentLocationViaTeleport() then
        Notify(L(ESOPIE_SI_FASTTRAVELUNAVAILABLE))
        return
    end
    local targetPlayer = nil
    local houseId = nil
    if entry.data and type(entry.data) == "table" then
        if entry.data.houseId and type(entry.data.houseId) == "number" then
            houseId = entry.data.houseId
        end
        if entry.data.targetPlayer and type(entry.data.targetPlayer) == "string" then
            targetPlayer = entry.data.targetPlayer
        end
    end
    if not houseId then
        houseId = GetHousingPrimaryHouse()
        if not houseId then
            LogWarning("No valid house for slot %s", entry.name)
            return
        end
    end
    if targetPlayer == GetDisplayName() then
        targetPlayer = nil
    end
    local collectibleId = GetCollectibleIdForHouse(houseId)
    if not IsCollectibleUnlocked(collectibleId) then
        LogVerbose("Not unlocked %d", collectibleId)
        Notify(ZO_CachedStrFormat(L(ESOPIE_SI_COLLECTIBLE_NOTUNLOCKED), ZO_SELECTED_TEXT:Colorize(GetCollectibleName(collectibleId))))
        return
    end
    if targetPlayer then
        JumpToSpecificHouse(targetPlayer, houseId)
    else
        RequestJumpToHouse(houseId)
    end
end

function ESOPie:Initialize()
    self:InitializeSettings()
    self.pieRoot = ESOPie_RadialMenuController:New(ESOPie_UI_Root, "ESOPie_EntryTemplate", self.radialAnimation, self.entryAnimation)
    self.pieRoot:SetSlotActivateCallback(function(selectedEntry) self:OnSlotActivate(selectedEntry) end)
    self.pieRoot:SetSlotNavigateCallback(function(selectedEntry) self:OnSlotNavigate(selectedEntry) end)
    self.pieRoot:SetPopulateSlotsCallback(function() self:OnPopulateSlots() end)

    self.interactionLayer = ZO_ActionLayerFragment:New(self.actionLayerName)

    local function RegisterHandler(action, handler)
        if self.executionCallbacks[action] then
            LogError("Handler already registered for %s", ESOPie_GetActionTypeString(action))
            return
        end
        if type(handler) ~= "function" then
            LogError("Handler is not a function for %s", ESOPie_GetActionTypeString(action))
            return
        end
        self.executionCallbacks[action] = handler
    end

    RegisterHandler(self.Action.Noop, function(entry, data) end) -- Do nothing.
    RegisterHandler(self.Action.Submenu, function(entry, data) end) -- Do nothing; handled by navigate callback.
    RegisterHandler(self.Action.ChatExec, function(entry, data) self:ExecuteChatCommand(entry, data) end)
    RegisterHandler(self.Action.CodeExec, function(entry, data) self:ExecuteCustomCommand(entry, data) end)
    RegisterHandler(self.Action.GoToHome, function(entry, data) self:ExecuteGoToHome(entry, data) end)
    RegisterHandler(self.Action.PlayEmote, function(entry, data) self:ExecuteEmote(entry, data) end)
    RegisterHandler(self.Action.PlayMomento, function(entry, data) self:ExecuteUseCollectible(entry, data) end)
    RegisterHandler(self.Action.SummonAlly, function(entry, data) self:ExecuteUseCollectible(entry, data) end)
    RegisterHandler(self.Action.SetMount, function(entry, data) self:ExecuteUseCollectible(entry, data) end)
    RegisterHandler(self.Action.SetVanityPet, function(entry, data) self:ExecuteUseCollectible(entry, data) end)
    RegisterHandler(self.Action.SetCostume, function(entry, data) self:ExecuteUseCollectible(entry, data) end)
    RegisterHandler(self.Action.SetPolymorph, function(entry, data) self:ExecuteUseCollectible(entry, data) end)

    local actionsSize = 0
    for _, action in pairs(self.Action) do
        actionsSize = actionsSize + 1
    end
    local actionNamesSize = #self.actionNames
    local callbacksSize = #self.executionCallbacks
    if actionsSize ~= callbacksSize then
        LogWarning("Action and execution callback size mismatch (%d : %d).", actionsSize, callbacksSize)
    end
    if actionsSize ~= actionNamesSize then
        LogWarning("Action and names size mismatch (%d : %d).", actionsSize, actionNamesSize)
    end
    LogInfo("%s %s initalized.", self.name, self.version)
end

function ESOPie:ResolveEntryIcon(entry)
    if self.utils.EntryIsSlot(entry) then
        if not entry.icon or entry.icon == "" then
            if self.utils.IsCollectableAction(entry) and entry.data and type(entry.data) == "number" then
                return GetCollectibleIcon(entry.data)
            elseif self.utils.IsHouseAction(entry) then
                local houseId = nil
                if entry.data and entry.data.houseId and type(entry.data.houseId) == "number" then
                    houseId = entry.data.houseId
                else
                    houseId = GetHousingPrimaryHouse()
                end
                if houseId then return GetCollectibleIcon(GetCollectibleIdForHouse(houseId)) end
            end
        else
            return entry.icon
        end
    end
    return ESOPIE_ICON_SLOT_DEFAULT
end

function ESOPie:GetActiveControlSettings()
    if IsInGamepadPreferredMode() then
        return self.db.controlOptions["gamepad"]
    else
        return self.db.controlOptions["keyboard"]
    end
end

function ESOPie:GetRootRing(index)
    assert(self.db)
    if index <= #self.db.rootRings then
        return self.utils.FindEntryByID(self.db.rootRings[index], self.db.entries, self.EntryType.Ring)
    end
    return nil
end

function ESOPie:GetSelectedSlotFromEntry(entry)
    if not entry or not entry.data then return nil end
    return self.utils.FindEntryByID(entry.data.uniqueid, self.db.entries, ESOPie.EntryType.Slot)
end

function ESOPie:ExecuteSlotAction(selectedEntry)
    local slotInfo = self:GetSelectedSlotFromEntry(selectedEntry)
    if not slotInfo then LogWarning("Invalid slot info for activate") return end
    local handler = self.executionCallbacks[slotInfo.action]
    if handler then
        handler(slotInfo, slotInfo.data)
    else
        LogWarning("Unhandled action %s", self.utils.GetActionTypeString(slotInfo.action))
    end
end

function ESOPie:OnSlotActivate(selectedEntry)
    LogVerboseC("debugCallbacks", "OnSlotActivate(%s)", GetValueSafe(selectedEntry, "name", "Invalid entry"))
    local interactMode = self:GetActiveControlSettings().bindingInteractMode
    if interactMode == ESOPie.InteractMode.Hold then
        self:ExecuteSlotAction(selectedEntry)
    end
end

function ESOPie:OnSlotNavigate(selectedEntry)
    LogVerboseC("debugCallbacks", "OnSlotNavigate(%s)", GetValueSafe(selectedEntry, "name", "Invalid entry"))
    local slotInfo = self:GetSelectedSlotFromEntry(selectedEntry)
    if not slotInfo then LogWarning("Invalid slot info for navigate") return end
    if slotInfo.action == ESOPie.Action.Submenu then
        LogVerbose("NavigateTo %s (%s): %s", slotInfo.name, self.utils.GetActionTypeString(slotInfo.action), tostring(slotInfo.data))
        self.pieRoot.menuControl.selectedLabel:SetText("")
        self.displayedRing = self.utils.FindEntryByID(slotInfo.data, self.db.entries, self.EntryType.Ring)
        if self.displayedRing then
            ESOPie.pieRoot:ShowMenu()
        else
            self.pieRoot:StopInteraction()
            LogError("Displayed ring not valid")
        end
    else
        local interactMode = self:GetActiveControlSettings().bindingInteractMode
        if interactMode == ESOPie.InteractMode.Toggle then
            self:ExecuteSlotAction(selectedEntry)
            self.pieRoot:StopInteraction()
        end
    end
end

function ESOPie:OnPopulateSlots()
    local ring = ESOPie.displayedRing
    if not ring or not ring.slots then LogWarning("Displayed ring not valid.") return end
    local maxSlots = ESOPie.maxVisibleSlots
    if ESOPie.showCancelButton then
        maxSlots = maxSlots - 1
    end
    local slotCount = math.min(maxSlots, #ring.slots)
    for i=1, slotCount do
        local slotInfo = self.utils.FindEntryByID(ring.slots[i], self.db.entries)
        if slotInfo then
            -- TODO: check visibility condition
            local name = slotInfo.name
            local icon = self:ResolveEntryIcon(slotInfo)
            if name == nil or name == '' then name = "Slot " .. i end
            if icon == nil or icon == '' then icon = ESOPIE_ICON_SLOT_DEFUALT end
            self.pieRoot:AddSlot(name, icon, icon, slotInfo.uniqueid)
        end
    end
    if ESOPie.showCancelButton or slotCount == 1 then -- RadialMenu needs at least 2 items
        self.pieRoot:AddSlot(L(SI_RADIAL_MENU_CANCEL_BUTTON), ESOPIE_ICON_SLOT_CANCEL, ESOPIE_ICON_SLOT_CANCEL, 0)
    end
end

function ESOPie:ShowRing(ringIndex)
    if not self.pieRoot:IsInteracting() then
        self.currentSlotInfo = nil
        self.displayedRing = self:GetRootRing(ringIndex)
        if self.displayedRing then
            self.activeBindingIndex = ringIndex
            if IsInGamepadPreferredMode() then
                PushActionLayerByName(self.actionLayerName)
            end
            self.pieRoot:StartInteraction()
        end
    else
        LogWarning("Cannot open ring binding %d. Ring binding %d is already active", ringIndex, self.activeBindingIndex)
    end
end

function ESOPie:HideRing(ringIndex)
    if self.pieRoot:IsInteracting() then
        assert(self.activeBindingIndex)
        if self.activeBindingIndex == ringIndex then
            self.activeBindingIndex = nil
            RemoveActionLayerByName(self.actionLayerName)
            self.pieRoot:StopInteraction()
        else
            LogWarning("Cannot hide ring binding %d. Ring binding %d is currently active.", ringIndex, self.activeBindingIndex)
        end
    end
end

function ESOPie:BeginInteractHold(ringIndex) self:ShowRing(ringIndex) end
function ESOPie:EndInteractHold(ringIndex) self:HideRing(ringIndex) end

function ESOPie:ToggleInteract(ringIndex)
    if self.pieRoot:IsInteracting() then
        self:HideRing(ringIndex)
    else
        self:ShowRing(ringIndex)
    end
end

-------------------------------------------------------------------------------
-- Binding Callbacks

function ESOPie:OnRingBindingPress(ringIndex)
    LogVerboseC("debugCallbacks", "OnRingBindingPress(%d)", ringIndex)
    local interactMode = self:GetActiveControlSettings().bindingInteractMode
    if interactMode == self.InteractMode.Hold then
        self:BeginInteractHold(ringIndex)
    else
        self:ToggleInteract(ringIndex)
    end
end

function ESOPie:OnRingBindingRelease(ringIndex)
    LogVerboseC("debugCallbacks", "OnRingBindingRelease(%d)", ringIndex)
    local interactMode = self:GetActiveControlSettings().bindingInteractMode
    if interactMode == self.InteractMode.Hold then
        self:EndInteractHold(ringIndex)
    end
end

function ESOPie:OnNavigateInteraction()
    LogVerboseC("debugCallbacks", "OnNavigateInteraction")
    self:OnSlotNavigate(self.pieRoot.currentSelectedEntry)
end

function ESOPie:OnCancelInteraction()
    LogVerboseC("debugCallbacks", "OnNavigateInteraction")
    self.pieRoot:CancelSelection()
end

-------------------------------------------------------------------------------
-- AddOn Initialization

EVENT_MANAGER:RegisterForEvent(ESOPie.name, EVENT_ADD_ON_LOADED, function(event, addonName)
    if addonName == ESOPie.name then
        EVENT_MANAGER:UnregisterForEvent(ESOPie.name, EVENT_ADD_ON_LOADED)
        ESOPie:Initialize()
    end
end)

--[[
SLASH_COMMANDS["/esopie_reset"] = function(args)
    ESOPie:ResetToDefault()
end
]]--