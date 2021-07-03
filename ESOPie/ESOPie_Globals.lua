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
ESOPie.utils = {}
ESOPie.showCancelButton = false
ESOPie.maxRingBindings = 6
ESOPie.maxVisibleSlots = 12
ESOPie.openRingDelay = 50
ESOPie.displayedRing = nil
ESOPie.selectedSlotInfo = nil
ESOPie.activeBindingIndex = nil
ESOPie.executionCallbacks = {}
--[[ESOPie.dev = {
    debugCallbacks = false,
    debugExecution = false,
}]]--

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

local function ESOPie_Notify(fmt, ...)
    local str = string.format(fmt, ...)
    CHAT_SYSTEM:AddMessage(str)
end

local LOG_LEVEL_VERBOSE = "V"
local LOG_LEVEL_DEBUG = "D"
local LOG_LEVEL_INFO = "I"
local LOG_LEVEL_WARN = "W"
local LOG_LEVEL_ERROR = "E"

ESOPie.logger = nil
if LibDebugLogger then
    ESOPie.logger = LibDebugLogger.Create(ESOPie.name)
    LOG_LEVEL_VERBOSE = LibDebugLogger.LOG_LEVEL_VERBOSE
    LOG_LEVEL_DEBUG = LibDebugLogger.LOG_LEVEL_DEBUG
    LOG_LEVEL_INFO = LibDebugLogger.LOG_LEVEL_INFO
    LOG_LEVEL_WARN = LibDebugLogger.LOG_LEVEL_WARNING
    LOG_LEVEL_ERROR = LibDebugLogger.LOG_LEVEL_ERROR
end

ESOPie.DevLog = ESOPie_DevLog
ESOPie.LogVerboseCond = function(condName, fmt, ...) if ESOPie.dev and ESOPie.dev[condName] then ESOPie_DevLog(LOG_LEVEL_VEROSE, fmt, ...) end end
ESOPie.LogVerbose = function(fmt, ...) ESOPie_DevLog(LOG_LEVEL_VERBOSE, fmt, ...) end
ESOPie.LogDebug = function(fmt, ...) ESOPie_DevLog(LOG_LEVEL_DEBUG, fmt, ...) end
ESOPie.LogInfo = function(fmt, ...) ESOPie_DevLog(LOG_LEVEL_INFO, fmt, ...) end
ESOPie.LogWarning = function(fmt, ...) ESOPie_DevLog(LOG_LEVEL_WARN, fmt, ...) end
ESOPie.LogError = function(fmt, ...) ESOPie_DevLog(LOG_LEVEL_ERROR, fmt, ...) end
ESOPie.Notify = ESOPie_Notify

ESOPie.utils.GetActionTypeString = function(action)
    if type(action) == "number" and action > 0 then
        if action <= #ESOPie.actionNames then
            return ESOPie.actionNames[action]
        end
    end
    return nil
end

ESOPie.utils.FindEntryByID = function(id, haystack, ensureType)
    if id and haystack then
        for _, entry in pairs(haystack) do
            if entry.uniqueid == id and (ensureType == nil or entry.type == ensureType) then
                return entry
            end
        end
    end
    return nil
end

ESOPie.utils.FindEntryIndexByID = function(id, haystack, ensureType)
    if id and haystack then
        for i, entry in pairs(haystack) do
            if entry.uniqueid == id and (ensureType == nil or entry.type == ensureType) then
                return i
            end
        end
    end
    return nil
end

ESOPie.utils.NumericTableContains = function(table, search)
    for i, v in ipairs(table) do
        if v == search then return true end
    end
    return false
end

ESOPie.utils.TableContainsKey = function(table, search)
    return table[search] ~= nil
end

ESOPie.utils.EntryIsRing = function(entry)
    if not entry then return false end
    return entry.type == ESOPie.EntryType.Ring
end

ESOPie.utils.EntryIsSlot = function(entry)
    if not entry then return false end
    return entry.type == ESOPie.EntryType.Slot
end

ESOPie.utils.IsSubringAction = function(entry)
    if not ESOPie.utils.EntryIsSlot(entry) then return false end
    return entry.action == ESOPie.Action.Submenu
end

ESOPie.utils.IsCommandAction = function(entry)
    if not ESOPie.utils.EntryIsSlot(entry) then return false end
    return entry.action == ESOPie.Action.ChatExec or entry.action == ESOPie.Action.CodeExec
end

ESOPie.utils.IsHouseAction = function(entry)
    if not ESOPie.utils.EntryIsSlot(entry) then return false end
    return entry.action == ESOPie.Action.GoToHome
end

ESOPie.utils.IsCollectableAction = function(entry)
    if not ESOPie.utils.EntryIsSlot(entry) then return false end
    if      entry.action == ESOPie.Action.PlayEmote     then return true
    elseif  entry.action == ESOPie.Action.PlayMomento   then return true
    elseif  entry.action == ESOPie.Action.SummonAlly    then return true
    elseif  entry.action == ESOPie.Action.SetMount      then return true
    elseif  entry.action == ESOPie.Action.SetVanityPet  then return true
    elseif  entry.action == ESOPie.Action.SetCostume    then return true
    elseif  entry.action == ESOPie.Action.SetPolymorph  then return true
    end
end

ESOPie.utils.CollectionHasCategory = function(entry)
    if not ESOPie.utils.EntryIsSlot(entry) then return false end
    if      entry.action == ESOPie.Action.PlayEmote     then return true
    elseif  entry.action == ESOPie.Action.SummonAlly    then return true
    elseif  entry.action == ESOPie.Action.SetMount      then return true
    elseif  entry.action == ESOPie.Action.SetVanityPet  then return true
    --elseif  entry.action == ESOPie.Action.SetCostume    then return true
    --elseif  entry.action == ESOPie.Action.SetPolymorph  then return true
    end
    return false
end