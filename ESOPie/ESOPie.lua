local L = GetString

ESOPie = ESOPie or {}
ESOPie.name = "ESOPie"
ESOPie.version = "0.2.2 BETA"
ESOPie.author = "Planetshine Games"
ESOPie.url = "https://github.com/jrdmellow/ESOPie"
ESOPie.slashCommand = "/esopie"
ESOPie.settingsPanelName = "ESOPieSettingsPanel"
ESOPie.prefix = string.format("[%s]: ", ESOPie.name)
ESOPie.savedVars = "ESOPieSavedVars"
ESOPie.savedVarsVersion = 4
ESOPie.logger = nil
ESOPie.actionLayerName = "RadialMenu"
ESOPie.radialAnimation = nil --"DefaultRadialMenuAnimation" -- Disabled the animation to keep it snappy.
ESOPie.entryAnimation = "SelectableItemRadialMenuEntryAnimation"
ESOPie.EntryType = {
    Ring = 1,
    Slot = 2,
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
    [ESOPie.Action.Noop]                = L(ESOPIE_ACTION_NOOP),
    [ESOPie.Action.Submenu]             = L(ESOPIE_ACTION_SUBRING),
    [ESOPie.Action.ChatExec]            = L(ESOPIE_ACTION_CHATEXEC),
    [ESOPie.Action.CodeExec]            = L(ESOPIE_ACTION_CODEEXEC),
    [ESOPie.Action.GoToHome]            = L(ESOPIE_ACTION_GOTOHOME),
    [ESOPie.Action.PlayEmote]           = L(ESOPIE_ACTION_PLAYEMOTE),
    [ESOPie.Action.PlayMomento]         = L(ESOPIE_ACTION_PLAYMOMENTO),
    [ESOPie.Action.SummonAlly]          = L(ESOPIE_ACTION_SUMMONALLY),
    [ESOPie.Action.SetMount]            = L(ESOPIE_ACTION_SETMOUNT),
    [ESOPie.Action.SetVanityPet]        = L(ESOPIE_ACTION_SETNCPET),
    [ESOPie.Action.SetCostume]          = L(ESOPIE_ACTION_SETCOSTUME),
    [ESOPie.Action.SetPolymorph]        = L(ESOPIE_ACTION_SETPOLYMORPH),
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
    ESOPie.Action.ChatExec,
    --ESOPie.Action.CodeExec,
}
ESOPie.showCancelButton = false
ESOPie.maxRingBindings = 6
ESOPie.maxVisibleSlots = 12
ESOPie.displayedRing = nil
ESOPie.selectedSlotInfo = nil
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

local ESOPIE_SUBRING_OPEN_DELAY_MS = 50

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
    ESOPie_DevLog(LOG_LEVEL_DEBUG, str)
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

function ESOPie:ExecuteChatCommand(commandStr)
    if not commandStr then Notify("Slot has no chat command to execute.") return end
    if not commandStr:find("/") == 1 then
        Notify("First character of a chat command must be '/': %s", commandStr)
        return
    end
    LogVerbose("Chat command: %s", commandStr)
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
            Notify("ESOPie currently does not support this chat command. Hopefully soon!")
            return
        end
    end
    SLASH_COMMANDS[command](args)
end

function ESOPie:ExecuteCustomCommand(luaCode)
    if not luaCode then Notify("Slot has no code to execute.") return end
    LogWarning("Custom command -- TODO")
end

function ESOPie:ExecuteEmote(itemId)
    if not itemId or type(itemId) ~= "number" then LogWarning("Payload is invalid.") return end
    local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(itemId)
    if emoteInfo then
        PlayEmoteByIndex(emoteInfo.emoteIndex)
    end
end

function ESOPie:ExecuteUseCollectible(itemId)
    if IsCollectibleUnlocked(itemId) then
        UseCollectible(itemId, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    else
        Notify("Ally %s is not unlocked.", ZO_CachedStrFormat("<<1>>", GetCollectibleName(itemId)))
    end
end

function ESOPie:Initialize()
    self:InitializeSettings()
    self.pieRoot = ESOPie_RadialMenuController:New(ESOPie_UI_Root, "ESOPie_EntryTemplate", self.radialAnimation, self.entryAnimation)
    self.pieRoot:SetSlotActivateCallback(function(selectedEntry) self:OnSlotActivate(selectedEntry) end)
    self.pieRoot:SetSlotNavigateCallback(function(selectedEntry) self:OnSlotNavigate(selectedEntry) end)
    self.pieRoot:SetPopulateSlotsCallback(function() self:OnPopulateSlots() end)

    local function RegisterHandler(action, handler)
        if self.executionCallbacks[action] then
            LogError("Handler already registered for %s", GetActionTypeString(action))
            return
        end
        if type(handler) ~= "function" then
            LogError("Handler is not a function for %s", GetActionTypeString(action))
            return
        end
        self.executionCallbacks[action] = handler
    end

    RegisterHandler(self.Action.Noop, function(data) end) -- Do nothing.
    RegisterHandler(self.Action.Submenu, function(data) end) -- Do nothing; handled by navigate callback.
    RegisterHandler(self.Action.ChatExec, function(data) self:ExecuteChatCommand(data) end)
    RegisterHandler(self.Action.CodeExec, function(data) self:ExecuteCustomCommand(data) end)
    RegisterHandler(self.Action.GoToHome, function(data) self:ExecuteGoToHome(data) end)
    RegisterHandler(self.Action.PlayEmote, function(data) self:ExecuteEmote(data) end)
    RegisterHandler(self.Action.PlayMomento, function(data) self:ExecuteUseCollectible(data) end)
    RegisterHandler(self.Action.SummonAlly, function(data) self:ExecuteUseCollectible(data) end)
    RegisterHandler(self.Action.SetMount, function(data) self:ExecuteUseCollectible(data) end)
    RegisterHandler(self.Action.SetVanityPet, function(data) self:ExecuteUseCollectible(data) end)
    RegisterHandler(self.Action.SetCostume, function(data) self:ExecuteUseCollectible(data) end)
    RegisterHandler(self.Action.SetPolymorph, function(data) self:ExecuteUseCollectible(data) end)

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
    if EntryIsSlot(entry) then
        if entry.icon and entry.icon == ESOPIE_ICON_SLOT_DEFAULT then
            if IsCollectableAction(entry) and entry.data and type(entry.data) == "number" then
                return GetCollectibleIcon(entry.data)
            end
        else
            return entry.icon
        end
    end
    return ESOPIE_ICON_SLOT_DEFAULT
end

function ESOPie:GetRing(id)
    if self.db and self.db.entries then
        local ring = FindEntryByID(id, self.db.entries, ESOPie.EntryType.Ring)
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
    return FindEntryByID(entry.data.uniqueid, self.db.entries, ESOPie.EntryType.Slot)
end

function ESOPie:OnSlotActivate(selectedEntry)
    local slotInfo = self:GetSelectedSlotFromEntry(selectedEntry)
    if not slotInfo then LogWarning("Invalid slot info for activate") return end

    local handler = self.executionCallbacks[slotInfo.action]
    if handler then
        LogVerbose("%s => %s (%s)", slotInfo.name, GetActionTypeString(slotInfo.action), slotInfo.data)
        handler(slotInfo.data)
    else
        LogDebug("Unhandled action %s", GetActionTypeString(slotInfo.action))
    end
end

function ESOPie:OnSlotNavigate(selectedEntry)
    local slotInfo = self:GetSelectedSlotFromEntry(selectedEntry)
    if not slotInfo then LogWarning("Invalid slot info for navigate") return end
    LogVerbose("NavigateTo %s (%s): %s", slotInfo.name, GetActionTypeString(slotInfo.action), slotInfo.data)
    if slotInfo.action == ESOPie.Action.Submenu then
        self.pieRoot.menuControl.selectedLabel:SetText("")
        self.displayedRing = self:GetRing(slotInfo.data)
        if self.displayedRing then
            -- delay the call slightly
            zo_callLater(function() ESOPie.pieRoot:ShowMenu() end, ESOPIE_SUBRING_OPEN_DELAY_MS)
        else
            self.pieRoot:StopInteraction()
            LogError("Displayed ring not valid")
        end
    end
end

function ESOPie:OnPopulateSlots()
    local ring = ESOPie.displayedRing
    if not ring or not ring.slots then Notify("Displayed ring not valid.") return end

    local maxSlots = ESOPie.maxVisibleSlots
    if ESOPie.showCancelButton then
        maxSlots = maxSlots - 1
    end
    local slotCount = math.min(maxSlots, #ring.slots)
    for i=1, slotCount do
        local slotInfo = FindEntryByID(ring.slots[i], self.db.entries)
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

function ESOPie:OnHoldMenuOpen(ringIndex)
    self.currentSlotInfo = nil
    self.displayedRing = self:GetRootRing(ringIndex)
    if self.displayedRing then
        self.pieRoot:StartInteraction()
    end
end

function ESOPie:OnHoldMenuClose()
    self.pieRoot:StopInteraction()
end

-------------------------------------------------------------------------------
-- AddOn Initialization

EVENT_MANAGER:RegisterForEvent(ESOPie.name, EVENT_ADD_ON_LOADED, function(event, addonName)
    if addonName == ESOPie.name then
        ESOPie:Initialize()
    end
end)


SLASH_COMMANDS["/esopie_reset"] = function(args)
    ESOPie:ResetToDefault()
end