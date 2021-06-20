local L = GetString

ESOPie = ESOPie or {}
ESOPie.name = "ESOPie"
ESOPie.version = "0.1"
ESOPie.author = "Planetshine Games"
ESOPie.slashCommand = "/esopie"
ESOPie.settingsPanelName = "ESOPieSettingsPanel"
ESOPie.prefix = string.format("[%s]: ", ESOPie.name)
ESOPie.savedVars = "ESOPieSavedVars"
ESOPie.savedVarsVersion = 3
ESOPie.logger = nil
ESOPie.actionLayerName = "RadialMenu"
ESOPie.radialAnimation = nil --"DefaultRadialMenuAnimation" -- Disabled the animation to keep it snappy.
ESOPie.entryAnimation = "SelectableItemRadialMenuEntryAnimation"
ESOPie.actions = {
    ACTION_NOOP = 1,
    ACTION_SUBMENU = 2,
    ACTION_CHATEXEC = 3,
    ACTION_CODEEXEC = 4,
    ACTION_GOTOHOME = 5,
    ACTION_PLAYEMOTE = 6,
}
ESOPie.actionNames = {
    L(ESOPIE_ACTION_NOOP),
    L(ESOPIE_ACTION_SUBRING),
    L(ESOPIE_ACTION_CHATEXEC),
    L(ESOPIE_ACTION_CODEEXEC),
    L(ESOPIE_ACTION_GOTOHOME),
    L(ESOPIE_ACTION_PLAYEMOTE),
}
-- Temporary: Limit visible actions and sort
ESOPie.supportedActions = {
    ESOPie.actions.ACTION_NOOP,
    ESOPie.actions.ACTION_PLAYEMOTE,
    ESOPie.actions.ACTION_CHATEXEC,
    ESOPie.actions.ACTION_SUBMENU,
}
ESOPie.showCancelButton = false
ESOPie.maxVisibleSlots = 8
ESOPie.displayedRing = nil
ESOPie.selectedSlotInfo = nil

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

local ESOPIE_ICON_SLOT_DEFUALT = "EsoUI/Art/Icons/crafting_dwemer_shiny_cog.dds"
local ESOPIE_ICON_SLOT_EMPTY = "EsoUI/Art/Quickslots/quickslot_emptySlot.dds"
local ESOPIE_ICON_SLOT_CANCEL = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_cancel_down.dds"

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

function ESOPie:Initialize()
    self.InitializeSettings()
    self.pieRoot = ESOPie_RadialMenuController:New(ESOPie_UI_Root, "ESOPie_EntryTemplate", self.radialAnimation, self.entryAnimation)
    self.pieRoot:SetSlotActivateCallback(function(selectedEntry) self:OnSlotActivate(selectedEntry) end)
    self.pieRoot:SetSlotNavigateCallback(function(selectedEntry) self:OnSlotNavigate(selectedEntry) end)
    self.pieRoot:SetPopulateSlotsCallback(function() self:OnPopulateSlots() end)

    LogInfo("%s %s initalized.", ESOPie.name, ESOPie.version)
end

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
    if not commandStr then Notify("Slot has no code to execute.") return end
    LogWarning("Custom command -- TODO")
end

function ESOPie:ExecuteEmote(emoteId)
    if not emoteId or type(emoteId) ~= "number" then LogWarning("Payload is invalid.") return end
    local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(emoteId)
    PlayEmoteByIndex(emoteInfo.emoteIndex)
end

function ESOPie:ExecuteCallback(slotInfo)
    if slotInfo.action == ESOPie.actions.ACTION_NOOP or slotInfo.action == ESOPie.actions.ACTION_SUBMENU then return end
    LogVerbose("%s(%s): %s", slotInfo.name, GetActionTypeString(slotInfo.action), slotInfo.data)
    if slotInfo.action == ESOPie.actions.ACTION_CHATEXEC then
        self:ExecuteChatCommand(slotInfo.data)
    elseif slotInfo.action == ESOPie.actions.ACTION_CODEEXEC then
        self:ExecuteCustomCommand(slotInfo.data)
    elseif slotInfo.action == ESOPie.actions.ACTION_PLAYEMOTE then
        self:ExecuteEmote(slotInfo.data)
    else
        LogDebug("Unhandled action %s", GetActionTypeString(slotInfo.action))
    end
end

function ESOPie:GetRing(id)
    if self.db and self.db.rings then
        local ring = FindEntryByID(id, self.db.rings)
        if not ring then
            LogError("Ring <%d> not found.", id)
        end
        return ring
    else
        LogWarning("SaveData invalid.")
    end
    return nil
end

function ESOPie:GetRootRing()
    return self:GetRing(self.db.rootRing)
end

function ESOPie:GetSelectedSlotFromEntry(entry)
    if not entry then return end
    if self.displayedRing and self.displayedRing.slots then
        for _, slot in pairs(self.displayedRing.slots) do
            if slot.uniqueid == entry.data.uniqueid then
                return slot
            end
        end
        LogDebug("Entry %s<%d> not found in ring %s", entry.name, entry.uniqueid, self.displayedRing.name)
    end
    return nil
end

function ESOPie:OnSlotActivate(selectedEntry)
    local slotInfo = self:GetSelectedSlotFromEntry(selectedEntry)
    if not slotInfo then LogWarning("Invalid slot info for activate") return end
    self:ExecuteCallback(slotInfo)
end

function ESOPie:OnSlotNavigate(selectedEntry)
    local slotInfo = self:GetSelectedSlotFromEntry(selectedEntry)
    if not slotInfo then LogWarning("Invalid slot info for navigate") return end
    LogVerbose("NavigateTo %s (%s): %s", slotInfo.name, GetActionTypeString(slotInfo.action), slotInfo.data)
    if slotInfo.action == ESOPie.actions.ACTION_SUBMENU then
        self.pieRoot:StopInteraction()
        self.pieRoot.menuControl.selectedLabel:SetText("")
        self.displayedRing = self:GetRing(slotInfo.data)
        if self.displayedRing then
            -- delay the call slightly
            zo_callLater(function() ESOPie.pieRoot:StartInteraction() end, ESOPIE_SUBRING_OPEN_DELAY_MS)
        else
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
    for i=1, math.min(maxSlots, #ring.slots) do -- TODO: Handle more than 8 slots somehow. Another binding?
        local slotInfo = ring.slots[i]
        local name = slotInfo.name
        local icon = slotInfo.icon
        if name == nil or name == '' then name = "Slot " .. i end
        if icon == nil or icon == '' then icon = ESOPIE_ICON_SLOT_DEFUALT end
        self.pieRoot:AddSlot(name, icon, icon, slotInfo.uniqueid)
    end
    if ESOPie.showCancelButton then
        self.pieRoot:AddSlot(L(SI_RADIAL_MENU_CANCEL_BUTTON), ESOPIE_ICON_SLOT_CANCEL, ESOPIE_ICON_SLOT_CANCEL, 0)
    end
end

function ESOPie:OnHoldMenuOpen()
    LogVerbose("Menu Open: Push %s", self.actionLayerName)
    self.currentSlotInfo = nil
    self.displayedRing = self:GetRootRing()
    if self.displayedRing then
        self.pieRoot:StartInteraction()
    end
end

function ESOPie:OnHoldMenuClose()
    LogVerbose("Menu Close: Pop %s", self.actionLayerName)
    --self.currentSlotInfo = nil
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