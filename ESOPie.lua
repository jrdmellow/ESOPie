local L = GetString

local LOG_VERBOSE = "V"
local LOG_DEBUG = "D"
local LOG_INFO = "I"
local LOG_WARN = "W"
local LOG_ERROR = "E"

ESOPie = ESOPie or {}
ESOPie.name = "ESOPie"
ESOPie.version = "0.1"
ESOPie.author = "Planetshine Games"
ESOPie.prefix = string.format("[%s]: ", ESOPie.name)
ESOPie.savedVars = "ESOPieSavedVars"
ESOPie.savedVarsVersion = 1
ESOPie.logger = nil
ESOPie.actionLayerName = "RadialMenu"
ESOPie.radialAnimation = nil --"DefaultRadialMenuAnimation" -- Disabled the animation to keep it snappy.
ESOPie.entryAnimation = "SelectableItemRadialMenuEntryAnimation"
ESOPie.actions = {
    ACTION_NOOP = 0,
    ACTION_SUBMENU = 1,
    ACTION_CHATEXEC = 2,
    ACTION_CUSTOMEXEC = 3,
    ACTION_OPENEMOTEWHEEL = 4,
    ACTION_GOTOHOME = 5
}
ESOPie.actionNames = {
    L(ESOPIE_ACTION_SUBRING),
    L(ESOPIE_ACTION_CHATEXEC),
    L(ESOPIE_ACTION_CODEEXEC),
    L(ESOPIE_ACTION_OPENEMOTE),
    L(ESOPIE_ACTION_GOTOHOME)
}
-- ESOPie.iconLibrary = ESOPIE_ICON_LIBRARY or {}
ESOPie.showCancelButton = true
ESOPie.maxVisibleSlots = 8
ESOPie.displayedRing = nil
ESOPie.selectedSlotInfo = nil

if LibDebugLogger then
    ESOPie.logger = LibDebugLogger.Create(ESOPie.name)
    LOG_VERBOSE = LibDebugLogger.LOG_LEVEL_VERBOSE
    LOG_DEBUG = LibDebugLogger.LOG_LEVEL_DEBUG
    LOG_INFO = LibDebugLogger.LOG_LEVEL_INFO
    LOG_WARN = LibDebugLogger.LOG_LEVEL_WARNING
    LOG_ERROR = LibDebugLogger.LOG_LEVEL_ERROR
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

local ESOPIE_ACTION_NOOP = ESOPie.actions.ACTION_NOOP
local ESOPIE_ACTION_SUBMENU = ESOPie.actions.ACTION_SUBMENU
local ESOPIE_ACTION_CHATEXEC = ESOPie.actions.ACTION_CHATEXEC
local ESOPIE_ACTION_CUSTOMEXEC = ESOPie.actions.ACTION_CUSTOMEXEC
local ESOPIE_ACTION_OPENEMOTEWHEEL = ESOPie.actions.ACTION_OPENEMOTEWHEEL

local ESOPIE_ICON_SLOT_DEFUALT = "EsoUI/Art/Icons/crafting_dwemer_shiny_cog.dds"
local ESOPIE_ICON_SLOT_EMPTY = "EsoUI/Art/Quickslots/quickslot_emptySlot.dds"
local ESOPIE_ICON_SLOT_CANCEL = "EsoUI/Art/HUD/Gamepad/gp_radialIcon_cancel_down.dds"

local function Print(level, fmt, ...)
    if ESOPie.logger and ESOPie.logger.Log then
        if type(ESOPie.logger.Log) == "function" then
            ESOPie.logger:Log(level, fmt, ...)
        end
    end
end

local function Notify(fmt, ...)
    local str = string.format(fmt, ...)
    CHAT_SYSTEM:AddMessage(str)
    Print(LOG_DEBUG, str)
end

ESOPie.Print = Print
ESOPie.Notify = Notify

-------------------------------------------------------------------------------
-- ESOPie Handler

function ESOPie:Initialize()
    self.InitializeSettings()
    self.pieRoot = ESOPie_RadialMenuController:New(ESOPie_UI_Root, "ESOPie_EntryTemplate", self.radialAnimation, self.entryAnimation)
    self.pieRoot:SetSlotActivateCallback(function(selectedEntry) self:OnSlotActivate(selectedEntry) end)
    self.pieRoot:SetSlotNavigateCallback(function(selectedEntry) self:OnSlotNavigate(selectedEntry) end)
    self.pieRoot:SetPopulateSlotsCallback(function() self:OnPopulateSlots() end)

    Print(LOG_INFO, "%s %s initalized.", ESOPie.name, ESOPie.version)
end

function ESOPie:ExecuteChatCommand(commandStr)
    if not commandStr then Notify("Slot has no chat command to execute.") return end
    if not commandStr:find("/") == 1 then
        Notify("First character of a chat command must be '/': %s", commandStr)
        return
    end
    Print(LOG_VERBOSE, "Chat command: %s", commandStr)
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
    Print(LOG_WARN, "Custom command -- TODO")
end

function ESOPie:ExecuteCallback(slotInfo)
    if slotInfo.action == ESOPIE_ACTION_NOOP or slotInfo.action == ESOPIE_ACTION_SUBMENU then return end
    Print(LOG_VERBOSE, "%s(%s): %s", slotInfo.name, self.actionNames[slotInfo.action], slotInfo.data)
    if slotInfo.action == ESOPIE_ACTION_CHATEXEC then
        self:ExecuteChatCommand(slotInfo.data)
    elseif slotInfo.action == ESOPIE_ACTION_CUSTOMEXEC then
        self:ExecuteCustomCommand(slotInfo.data)
    elseif slotInfo.action == ESOPIE_ACTION_OPENEMOTEWHEEL then
        Print(LOG_DEBUG, "Show emote wheel")
    else
        if slotInfo.action <= #self.actionNames then
            Print(LOG_DEBUG, "Unhandled action %s(%d)", self.actionNames[slotInfo.action], slotInfo.action)
        else
            Print(LOG_DEBUG, "Unhandled action <unnamed>(%d)", slotInfo.action)
        end
    end
end

function ESOPie:GetRingByIndex(ringIndex)
    if self.db and self.db.rings and self.db.rootRing and ringIndex <= #self.db.rings then
        return self.db.rings[ringIndex]
    end
    return nil
end

function ESOPie:GetRootRing()
    if self.db and self.db.rootRing then
        return self:GetRingByIndex(self.db.rootRing)
    end
    return nil
end

function ESOPie:GetSelectedSlotFromEntry(entry)
    if self.displayedRing and self.displayedRing.slots then
        for _, slot in pairs(self.displayedRing.slots) do
            if slot.name == entry.name then
                return slot
            end
        end
        Print(LOG_DEBUG, "Entry %s not found in ring %s", entry.name, self.displayedRing.name)
    end
    return nil
end

function ESOPie:OnSlotActivate(selectedEntry)
    local slotInfo = self:GetSelectedSlotFromEntry(selectedEntry)
    if not slotInfo then Print(LOG_WARN, "Invalid slot info for activate") return end
    self:ExecuteCallback(slotInfo)
end

function ESOPie:OnSlotNavigate(selectedEntry)
    local slotInfo = self:GetSelectedSlotFromEntry(selectedEntry)
    if not slotInfo then Print(LOG_WARN, "Invalid slot info for navigate") return end
    Print(LOG_VERBOSE, "NavigateTo %s(%s): %s", slotInfo.name, self.actionNames[slotInfo.action], slotInfo.data)
    if slotInfo.action == ESOPIE_ACTION_SUBMENU then
        self.pieRoot:StopInteraction()
        self.pieRoot.menuControl.selectedLabel:SetText("")
        self.displayedRing = self:GetRingByIndex(slotInfo.data)
        if self.displayedRing then
            -- delay the call slightly
            zo_callLater(function() ESOPie.pieRoot:StartInteraction() end, ESOPIE_SUBRING_OPEN_DELAY_MS)
        else
            Print(LOG_ERROR, "Invalid ring index")
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
        Print(LOG_VERBOSE, "   " .. i .. " " .. slotInfo.name)
        local name = slotInfo.name
        local icon = slotInfo.icon
        if name == nil or name == '' then name = "Slot " .. i end
        if icon == nil or icon == '' then icon = ESOPIE_ICON_SLOT_DEFUALT end
        self.pieRoot:AddSlot(name, icon, icon)
    end
    if ESOPie.showCancelButton then
        self.pieRoot:AddSlot(L(SI_RADIAL_MENU_CANCEL_BUTTON), ESOPIE_ICON_SLOT_CANCEL, ESOPIE_ICON_SLOT_CANCEL)
    end
end

function ESOPie:OnHoldMenuOpen()
    Print(LOG_VERBOSE, "Menu Open: Push %s", self.actionLayerName)
    self.currentSlotInfo = nil
    self.displayedRing = self:GetRootRing()
    if self.displayedRing then
        self.pieRoot:StartInteraction()
    end
end

function ESOPie:OnHoldMenuClose()
    Print(LOG_VERBOSE, "Menu Close: Pop %s", self.actionLayerName)
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
