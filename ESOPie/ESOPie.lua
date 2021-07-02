local L = GetString

ESOPie = ESOPie or {}
ESOPie.name = "ESOPie"
ESOPie.version = "0.2.2 BETA"
ESOPie.author = "FiveStar"
ESOPie.url = "https://github.com/jrdmellow/ESOPie/wiki"
ESOPie.slashCommand = "/esopie"
ESOPie.settingsPanelName = "ESOPieSettingsPanel"
ESOPie.prefix = string.format("[%s]: ", ESOPie.name)
ESOPie.savedVars = "ESOPieSavedVars"
ESOPie.savedVarsVersion = 4
ESOPie.logger = nil
ESOPie.actionLayerName = "ESOPieInteractionLayer"
ESOPie.radialAnimation = nil --"DefaultRadialMenuAnimation" -- Disabled the animation to keep it snappy.
ESOPie.entryAnimation = "SelectableItemRadialMenuEntryAnimation"
ESOPie.EntryType = {
    Ring = 1,
    Slot = 2,
}
ESOPie.InteractMode = {
    Hold = 1,
    Toggle = 2,
}
ESOPie.CollectionType = {
    Allies = 1,
    Momento = 2,
    VanityPet = 3,
    Mount = 4,
    Emote = 5,
}
ESOPie.Action = {
    Noop = 1,
    Submenu = 2,
    ChatExec = 3,
    CodeExec = 4,
    GoToHome = 5,
    PlayEmote = 6,
    PlayMomento = 7,
    SummonAlly = 8,
    SetMount = 9,
    SetVanityPet = 10,
    SetCostume = 11,
    SetPolymorph = 12,
}
ESOPie.actionNames = {
    [ESOPie.Action.Noop]                = L(ESOPIE_SI_ACTION_NOOP),
    [ESOPie.Action.Submenu]             = L(ESOPIE_SI_ACTION_SUBRING),
    [ESOPie.Action.ChatExec]            = L(ESOPIE_SI_ACTION_CHATEXEC),
    [ESOPie.Action.CodeExec]            = L(ESOPIE_SI_ACTION_CODEEXEC),
    [ESOPie.Action.GoToHome]            = L(ESOPIE_SI_ACTION_GOTOHOME),
    [ESOPie.Action.PlayEmote]           = L(ESOPIE_SI_ACTION_PLAYEMOTE),
    [ESOPie.Action.PlayMomento]         = L(ESOPIE_SI_ACTION_PLAYMOMENTO),
    [ESOPie.Action.SummonAlly]          = L(ESOPIE_SI_ACTION_SUMMONALLY),
    [ESOPie.Action.SetMount]            = L(ESOPIE_SI_ACTION_SETMOUNT),
    [ESOPie.Action.SetVanityPet]        = L(ESOPIE_SI_ACTION_SETNCPET),
    [ESOPie.Action.SetCostume]          = L(ESOPIE_SI_ACTION_SETCOSTUME),
    [ESOPie.Action.SetPolymorph]        = L(ESOPIE_SI_ACTION_SETPOLYMORPH),
}
-- Temporary: Limit visible actions and sort
ESOPie.supportedActions = {
    ESOPie.Action.Noop,
    ESOPie.Action.Submenu,
    ESOPie.Action.PlayEmote,
    ESOPie.Action.PlayMomento,
    ESOPie.Action.SummonAlly,
    ESOPie.Action.SetMount,
    ESOPie.Action.SetVanityPet,
    ESOPie.Action.SetCostume,
    ESOPie.Action.SetPolymorph,
    ESOPie.Action.GoToHome,
    ESOPie.Action.ChatExec,
    ESOPie.Action.CodeExec,
}
ESOPie.showCancelButton = false
ESOPie.maxRingBindings = 6
ESOPie.maxVisibleSlots = 12
ESOPie.openRingDelay = 50
ESOPie.displayedRing = nil
ESOPie.selectedSlotInfo = nil
ESOPie.activeBindingIndex = nil
ESOPie.executionCallbacks = {}

local LOG_LEVEL_VERBOSE = "V"
local LOG_LEVEL_DEBUG = "D"
local LOG_LEVEL_INFO = "I"
local LOG_LEVEL_WARN = "W"
local LOG_LEVEL_ERROR = "E"

if LibDebugLogger then
    ESOPie.logger = LibDebugLogger.Create(ESOPie.name)
    LOG_LEVEL_VERBOSE = LibDebugLogger.LOG_LEVEL_VERBOSE
    LOG_LEVEL_DEBUG = LibDebugLogger.LOG_LEVEL_DEBUG
    LOG_LEVEL_INFO = LibDebugLogger.LOG_LEVEL_INFO
    LOG_LEVEL_WARN = LibDebugLogger.LOG_LEVEL_WARNING
    LOG_LEVEL_ERROR = LibDebugLogger.LOG_LEVEL_ERROR
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

ESOPIE_ICON_SLOT_DEFAULT = ESOPIE_ICON_LIBRARY_DEFAULT or "/EsoUI/Art/Icons/crafting_dwemer_shiny_cog.dds"
ESOPIE_ICON_SLOT_EMPTY = "/EsoUI/Art/Quickslots/quickslot_emptySlot.dds"
ESOPIE_ICON_SLOT_CANCEL = "/EsoUI/Art/HUD/Gamepad/gp_radialIcon_cancel_down.dds"

local function ESOPie_DevLog(level, fmt, ...)
    if ESOPie.logger and ESOPie.logger.Log then
        if type(ESOPie.logger.Log) == "function" then
            ESOPie.logger:Log(level, fmt, ...)
        end
    end
end

function ESOPie_Notify(fmt, ...)
    local str = string.format(fmt, ...)
    CHAT_SYSTEM:AddMessage(str)
end

ESOPie.DevLog = ESOPie_DevLog
ESOPie.LogVerbose = function(fmt, ...) ESOPie_DevLog(LOG_LEVEL_VERBOSE, fmt, ...) end
ESOPie.LogDebug = function(fmt, ...) ESOPie_DevLog(LOG_LEVEL_DEBUG, fmt, ...) end
ESOPie.LogInfo = function(fmt, ...) ESOPie_DevLog(LOG_LEVEL_INFO, fmt, ...) end
ESOPie.LogWarning = function(fmt, ...) ESOPie_DevLog(LOG_LEVEL_WARN, fmt, ...) end
ESOPie.LogError = function(fmt, ...) ESOPie_DevLog(LOG_LEVEL_ERROR, fmt, ...) end
ESOPie.Notify = ESOPie_Notify

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
    SLASH_COMMANDS[command](args) -- Hacky. Better way?
end

function ESOPie:ExecuteCustomCommand(entry, luaCode)
    assert(entry)
    if not luaCode then Notify(ZO_CachedStrFormat(L(ESOPIE_SI_LUA_NOCODE), ZO_SELECTED_TEXT:Colorize(entry.name))) return end
    local f = assert(zo_loadstring(luaCode))
    f()
end

function ESOPie:ExecuteEmote(entry, itemId)
    assert(entry and itemId)
    if not itemId or type(itemId) ~= "number" then LogWarning("Emote payload is invalid.") return end
    local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(itemId)
    if emoteInfo then
        PlayEmoteByIndex(emoteInfo.emoteIndex)
    end
end

function ESOPie:ExecuteUseCollectible(entry, itemId)
    assert(entry and itemId)
    if not itemId or type(itemId) ~= "number" then LogWarning("Collectible payload is invalid.") return end
    if IsCollectibleUnlocked(itemId) then
        UseCollectible(itemId, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    else
        Notify(ZO_CachedStrFormat(L(ESOPIE_SI_COLLECTIBLE_NOTUNLOCKED), ZO_SELECTED_TEXT:Colorize(GetCollectibleName(itemId))))
    end
end

function ESOPie:ExecuteGoToHome(entry, data)
    assert(entry)
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

function ESOPie:GetRing(id)
    if self.db and self.db.entries then
        local ring = self.utils.FindEntryByID(id, self.db.entries, ESOPie.EntryType.Ring)
        if not ring then
            LogError("Ring <%d> not found.", id)
        end
        return ring
    else
        LogWarning("SaveData invalid.")
    end
    return nil
end

function ESOPie:GetRootRing(index)
    if index <= #self.db.rootRings then
        return self:GetRing(self.db.rootRings[index])
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
        LogVerbose("%s => %s (%s)", slotInfo.name, self.utils.GetActionTypeString(slotInfo.action), slotInfo.data or "nil")
        handler(slotInfo, slotInfo.data)
    else
        LogDebug("Unhandled action %s", self.utils.GetActionTypeString(slotInfo.action))
    end
end

function ESOPie:OnSlotActivate(selectedEntry)
    local interactMode = self:GetActiveControlSettings().bindingInteractMode
    if interactMode == ESOPie.InteractMode.Hold then
        self:ExecuteSlotAction(selectedEntry)
    end
end

function ESOPie:OnSlotNavigate(selectedEntry)
    local slotInfo = self:GetSelectedSlotFromEntry(selectedEntry)
    if not slotInfo then LogWarning("Invalid slot info for navigate") return end
    LogVerbose("NavigateTo %s (%s): %s", slotInfo.name, self.utils.GetActionTypeString(slotInfo.action), slotInfo.data)
    if slotInfo.action == ESOPie.Action.Submenu then
        self.pieRoot.menuControl.selectedLabel:SetText("")
        self.displayedRing = self:GetRing(slotInfo.data)
        if self.displayedRing then
            -- delay the call slightly
            zo_callLater(function() ESOPie.pieRoot:ShowMenu() end, self.openRingDelay)
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

function ESOPie:BeginInteractHold(ringIndex)
    self:ShowRing(ringIndex)
end

function ESOPie:EndInteractHold(ringIndex)
    self:HideRing(ringIndex)
end

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
    local interactMode = self:GetActiveControlSettings().bindingInteractMode
    if interactMode == self.InteractMode.Hold then
        self:BeginInteractHold(ringIndex)
    else
        self:ToggleInteract(ringIndex)
    end
end

function ESOPie:OnRingBindingRelease(ringIndex)
    local interactMode = self:GetActiveControlSettings().bindingInteractMode
    if interactMode == self.InteractMode.Hold then
        self:EndInteractHold(ringIndex)
    end
end

function ESOPie:OnNavigateInteraction()
    self:OnSlotNavigate(self.pieRoot.currentSelectedEntry)
end

function ESOPie:OnCancelInteraction()
    self.pieRoot:CancelSelection()
end

-------------------------------------------------------------------------------
-- AddOn Initialization

EVENT_MANAGER:RegisterForEvent(ESOPie.name, EVENT_ADD_ON_LOADED, function(event, addonName)
    if addonName == ESOPie.name then
        ESOPie:Initialize()
    end
end)

--[[
SLASH_COMMANDS["/esopie_reset"] = function(args)
    ESOPie:ResetToDefault()
end
]]--