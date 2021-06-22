if not ESOPie then d("[ESOPIE] ERROR: ESOPie not initialized.") return end

local L = GetString
local LAM = LibAddonMenu2

local LogVerbose = ESOPie.LogVerbose
local LogDebug = ESOPie.LogDebug
local LogInfo = ESOPie.LogInfo
local LogWarning = ESOPie.LogWarning
local LogError = ESOPie.LogError
local Notify = ESOPie.Notify

local ESOPIE_DEFAULT_RING = {
    uniqueid = 0,
    name = L(ESOPIE_DEFAULT_RINGNAME),
    slots = {}
}
local ESOPIE_DEFAULT_SLOTINFO = {
    uniqueid = 0,
    name = L(ESOPIE_DEFAULT_ACTIONNAME),
    icon = ESOPIE_ICON_SLOT_DEFUALT,
    action = ESOPie.actions.ACTION_NOOP,
    data = nil
}
local ESOPIE_DB_DEFAULT = {
    ["rings"] =
    {
        [1] =
        {
            ["uniqueid"] = 1,
            ["name"] = "Root",
            ["slots"] =
            {
                [1] =
                {
                    ["uniqueid"] = 2,
                    ["name"] = "Social",
                    ["action"] = 2,
                    ["icon"] = "/esoui/art/icons/ability_debuff_silence.dds",
                    ["data"] = 12,
                },
                [2] =
                {
                    ["uniqueid"] = 3,
                    ["name"] = "Show Off",
                    ["action"] = 2,
                    ["icon"] = "/esoui/art/icons/ability_debuff_levitate.dds",
                    ["data"] = 9,
                },
                [3] =
                {
                    ["uniqueid"] = 4,
                    ["name"] = "Music",
                    ["action"] = 2,
                    ["icon"] = "/esoui/art/icons/housing_bre_inc_musiclute001.dds",
                    ["data"] = 5,
                },
            },
        },
        [2] =
        {
            ["uniqueid"] = 5,
            ["name"] = "Music",
            ["slots"] =
            {
                [1] =
                {
                    ["uniqueid"] = 6,
                    ["name"] = "Play Lute",
                    ["action"] = 6,
                    ["icon"] = "/esoui/art/icons/housing_bre_inc_musiclute001.dds",
                    ["data"] = 5,
                },
                [2] =
                {
                    ["uniqueid"] = 7,
                    ["name"] = "Play Drums",
                    ["action"] = 6,
                    ["icon"] = "/esoui/art/icons/housing_bre_inc_musicdrum001.dds",
                    ["data"] = 7,
                },
                [3] =
                {
                    ["uniqueid"] = 8,
                    ["name"] = "Play Flute",
                    ["action"] = 6,
                    ["icon"] = "/esoui/art/icons/housing_bre_inc_musicrecorder001.dds",
                    ["data"] = 6,
                },
            },
        },
        [3] =
        {
            ["uniqueid"] = 9,
            ["name"] = "Show Off",
            ["slots"] =
            {
                [1] =
                {
                    ["uniqueid"] = 10,
                    ["action"] = 6,
                    ["icon"] = "/esoui/art/icons/ability_companion_mageguild_001.dds",
                    ["data"] = 611,
                    ["name"] = "Scorch",
                },
                [2] =
                {
                    ["uniqueid"] = 11,
                    ["name"] = "Flex",
                    ["action"] = 6,
                    ["icon"] = "/esoui/art/icons/emote_flex.dds",
                    ["data"] = 468,
                },
            },
        },
        [4] =
        {
            ["uniqueid"] = 12,
            ["name"] = "Social",
            ["slots"] =
            {
                [1] =
                {
                    ["name"] = "Greet",
                    ["action"] = 6,
                    ["icon"] = "/esoui/art/icons/ability_companion_nightblade_013.dds",
                    ["data"] = 162,
                    ["uniqueid"] = 13,
                },
                [2] =
                {
                    ["name"] = "Clap",
                    ["action"] = 6,
                    ["icon"] = "/esoui/art/icons/ability_companion_restorationstaff_002.dds",
                    ["data"] = 185,
                    ["uniqueid"] = 14,
                },
                [3] =
                {
                    ["uniqueid"] = 15,
                    ["action"] = 6,
                    ["icon"] = "/esoui/art/icons/ability_buff_minor_force.dds",
                    ["data"] = 172,
                    ["name"] = "Congratulate",
                },
            },
        },
    },
    ["rootRing"] = 1,
}

local ui = {
    initialized = false,
    nextUniqueID = 0,
    collectionCache = {
        emoteCategoryNames = {},
        emoteCategoryValues = {},
        allyCategoryNames = {},
        allyCategoryValues = {},
    },
    actionChoices = {},
    actionChoicesValues = {},
    ringChoices = {},
    ringChoicesValues = {},
    slotChoices = {},
    slotChoicesValues = {},
    selectedCollectionCategory = 0,
    currentEditingRing = {},
    currentEditingSlot = {}
}

local function GetCategoryFromData(actionType, data)
    if actionType == ESOPie.actions.ACTION_PLAYEMOTE then
        if data and type(data) == "number" then
            local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(data)
            if emoteInfo then
                return emoteInfo.emoteCategory
            end
        end
        return EMOTE_CATEGORY_CEREMONIAL
    end
    return 0
end

local function IsSubringAction(slot)
    return slot and slot.action == ESOPie.actions.ACTION_SUBMENU
end

local function IsCommandAction(slot)
    return slot and (slot.action == ESOPie.actions.ACTION_CHATEXEC or slot.action == ESOPie.actions.ACTION_CODEEXEC)
end

local function IsEmoteAction(slot)
    return slot and slot.action == ESOPie.actions.ACTION_PLAYEMOTE
end

local function IsAllyAction(slot)
    return slot and slot.action == ESOPie.actions.ACTION_SUMMONALLY
end

local function IsCollectableAction(slot)
    return slot and (IsEmoteAction(slot) or IsAllyAction(slot))
end

local function CollectionHasCategory(slot)
    if slot then
        if      slot.action == ESOPie.actions.ACTION_PLAYEMOTE  then return true
        elseif  slot.action == ESOPie.actions.ACTION_SUMMONALLY then return true
        elseif  slot.action == ESOPie.actions.ACTION_SETMOUNT   then return true
        elseif  slot.action == ESOPie.actions.ACTION_SETNCPET   then return true
        end
    end
    return false
end

local function UpdateDropdown(controlName, choices, values, tooltips)
    local control = WINDOW_MANAGER:GetControlByName(controlName)
    if not control then
        LogVerbose("[Update] Unable to find control (%s)", controlName)
        return
    end
    control:UpdateChoices(choices, values, tooltips)
    control:UpdateValue()
end

local function UpdateInternalCache()
    ZO_ClearTable(ui.actionChoices)
    ZO_ClearTable(ui.actionChoicesValues)
    for _, action in pairs(ESOPie.supportedActions) do
        if action and action > 0 then -- Don't include NOOP
            local actionName = GetActionTypeString(action) or string.format("Invalid<%d>", action)
            table.insert(ui.actionChoices, actionName)
            table.insert(ui.actionChoicesValues, action)
        end
    end
end

local function UpdateCollectionsCache()
    local cache = ui.collectionCache
    ZO_ClearTable(cache.emoteCategoryNames)
    ZO_ClearTable(cache.emoteCategoryValues)
    local emoteCategories = PLAYER_EMOTE_MANAGER:GetEmoteCategories()
    for _, category in pairs(emoteCategories) do
        local categoryName = L("SI_EMOTECATEGORY", category)
        table.insert(cache.emoteCategoryNames, categoryName)
        table.insert(cache.emoteCategoryValues, category)
    end
end

local function SelectInitialCollectionCategory()
    if IsCollectableAction(ui.currentEditingSlot) and CollectionHasCategory(ui.currentEditingSlot) then
        ui.selectedCollectionCategory = GetCategoryFromData(ui.currentEditingSlot.action, ui.currentEditingSlot.data)
    else
        ui.selectedCollectionCategory = 0
    end
end

local function SelectInitialSlotForEdit()
    if ui.currentEditingRing then
        ui.currentEditingSlot = FindEntryByIndex(1, ui.currentEditingRing.slots)
        SelectInitialCollectionCategory()
    else
        ui.currentEditingSlot = nil
    end
end

local function RebuildCollectionCategoryDropdown()
    local names = {}
    local values = {}
    if ui.currentEditingSlot then
        local actionType = ui.currentEditingSlot.action
        if actionType == ESOPie.actions.ACTION_PLAYEMOTE then
            names = ui.collectionCache.emoteCategoryNames
            values = ui.collectionCache.emoteCategoryValues
        elseif actionType == ESOPie.actions.ACTION_PLAYMOMENTO then
        elseif actionType == ESOPie.actions.ACTION_SUMMONALLY then
        elseif actionType == ESOPie.actions.ACTION_SETMOUNT then
        elseif actionType == ESOPie.actions.ACTION_SETNCPET then
        end
    end
    UpdateDropdown("ESOPIE_SlotEdit_CollectionCategory", names, values)
end

local function RebuildCollectionItemDropdown()
    local names = {}
    local values = {}
    if ui.currentEditingSlot then
        local actionType = ui.currentEditingSlot.action
        if actionType == ESOPie.actions.ACTION_PLAYEMOTE then
            local categoryId = ui.selectedCollectionCategory
            local emotesList = PLAYER_EMOTE_MANAGER:GetEmoteListForType(categoryId)
            if emotesList then
                for _, emote in pairs(emotesList) do
                    local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(emote)
                    table.insert(names, ZO_CachedStrFormat("<<1>>", emoteInfo.displayName))
                    table.insert(values, emoteInfo.emoteId)
                end
            else
                LogDebug("No emote list")
            end
        end
    end
    UpdateDropdown("ESOPIE_SlotEdit_CollectionItem", names, values)
end

local function RebuildRingDropdowns()
    if not ESOPie.db then LogError("SavedVars DB not initialized.") return end
    ZO_ClearTable(ui.ringChoices)
    ZO_ClearTable(ui.ringChoicesValues)
    for _, ring in pairs(ESOPie.db.rings) do
        table.insert(ui.ringChoices, string.format("%s (%d)", ring.name, #ring.slots))
        table.insert(ui.ringChoicesValues, ring.uniqueid)
    end
    UpdateDropdown("ESOPIE_General_RootRing", ui.ringChoices, ui.ringChoicesValues)
    UpdateDropdown("ESOPIE_RingEdit_Selection", ui.ringChoices, ui.ringChoicesValues)
    UpdateDropdown("ESOPIE_SlotEdit_Subring", ui.ringChoices, ui.ringChoicesValues)
end

local function RebuildSlotDropdowns()
    ZO_ClearTable(ui.slotChoices)
    ZO_ClearTable(ui.slotChoicesValues)
    if ui.currentEditingRing and ui.currentEditingRing.slots then
        for _, slot in pairs(ui.currentEditingRing.slots) do
            table.insert(ui.slotChoices, slot.name)
            table.insert(ui.slotChoicesValues, slot.uniqueid)
        end
    end
    UpdateDropdown("ESOPIE_RingEdit_SlotSelection", ui.slotChoices, ui.slotChoicesValues)
end

local function RebuildAll()
    RebuildRingDropdowns()
    RebuildSlotDropdowns()
    RebuildCollectionCategoryDropdown()
    RebuildCollectionItemDropdown()
end

-------------------------------------------------------------------------------
-- Global Helpers

function ESOPie:ResetToDefault()
    ZO_DeepTableCopy(ESOPIE_DB_DEFAULT, ESOPie.db)
end

-------------------------------------------------------------------------------
-- Initialize Addon Menu and Settings DB

function ESOPie:InitializeSettings()
    ESOPie.db = ZO_SavedVars:NewAccountWide(ESOPie.savedVars, ESOPie.savedVarsVersion, nil, ESOPIE_DB_DEFAULT)
    local saveData = ESOPie.db

    local function InitNextID()
        ui.nextUniqueID = 1
        local largestID = 1
        for _, ring in pairs(ESOPie.db.rings) do
            if ring.uniqueid and ring.uniqueid > largestID then
                largestID = ring.uniqueid
            end
            for _, slot in pairs(ring.slots) do
                if slot.uniqueid and slot.uniqueid > largestID then
                    largestID = slot.uniqueid
                end
            end
        end
        if largestID > 1 then
            ui.nextUniqueID = largestID + 1
        end
    end

    local function GetNextID()
        local id = ui.nextUniqueID
        ui.nextUniqueID = ui.nextUniqueID + 1
        return id
    end

    local function OnPanelCreated(panel)
        if panel ~= ESOPie.LAMPanel then return end
        LogVerbose("OnPanelCreated")
        InitNextID()
        UpdateCollectionsCache()
        RebuildAll()
        ui.initialized = true
    end

    local function CreateNewSlot()
        if ui.currentEditingRing then
            local newSlotInfo = {}
            ZO_DeepTableCopy(ESOPIE_DEFAULT_SLOTINFO, newSlotInfo)
            newSlotInfo.uniqueid = GetNextID()
            table.insert(ui.currentEditingRing.slots, newSlotInfo)
            ui.currentEditingSlot = newSlotInfo
        end
    end

    local function CreateNewRing()
        local newRing = {}
        ZO_DeepTableCopy(ESOPIE_DEFAULT_RING, newRing)
        newRing.uniqueid = GetNextID()
        table.insert(saveData.rings, newRing)
        ui.currentEditingRing = newRing
        CreateNewSlot()
    end

    UpdateInternalCache()
    UpdateCollectionsCache()

    ui.currentEditingRing = FindEntryByID(saveData.rootRing, saveData.rings)
    SelectInitialSlotForEdit()

    local optionsTable = {
        -- TODO: Localize
        {
            type = "header",
            name = "General Options",
        },
        {
            type = "dropdown",
            name = "Root Ring",
            tooltip = "Select the ring to show when first opening ESOPie",
            reference = "ESOPIE_General_RootRing",
            choices = ui.ringChoices,
            choicesValues = ui.ringChoicesValues,
            getFunc = function()
                return saveData.rootRing
            end,
            setFunc = function(value)
                saveData.rootRing = value
            end,
            default = function()
                local ring = FindEntryByID(saveData.rootRing, saveData.rings)
                if not ring and saveData.rings then
                    ring = saveData.rings[1]
                end
                if ring then
                    return ring.uniqueid
                end
                return 0
            end,
        },
        {
            type = "header",
            name = "Configure Ring",
        },
        {
            type = "dropdown",
            name = "Edit Ring",
            tooltip = "Select the ring to configure.",
            choices = ui.ringChoices,
            choicesValues = ui.ringChoicesValues,
            scrollable = true,
            sort = "value-up",
            reference = "ESOPIE_RingEdit_Selection",
            getFunc = function()
                if ui.currentEditingRing then
                    return ui.currentEditingRing.uniqueid
                end
                return 0
            end,
            setFunc = function(value)
                ui.currentEditingRing = FindEntryByID(value, saveData.rings)
                SelectInitialSlotForEdit()
                RebuildAll()
            end,
            default = function()
                local rootRing = FindEntryByID(saveData.rootRing, saveData.rings)
                if rootRing then
                    return rootRing.uniqueid
                else
                    return 0
                end
            end,
        },
        {
            type = "editbox",
            name = "Ring Name",
            tooltip = "Ring name.",
            isMultiline = false,
            reference = "ESOPIE_RingEdit_Name",
            disabled = function() return ui.currentEditingRing == nil end,
            getFunc = function()
                if ui.currentEditingRing then
                    return ui.currentEditingRing.name
                end
                return ""
            end,
            setFunc = function(value)
                if ui.currentEditingRing then
                    ui.currentEditingRing.name = value
                    RebuildRingDropdowns()
                end
            end,
        },
        {
            type = "button",
            name = "New Ring",
            tooltip = "Add a new ring. Note: Unless the new ring is set as Root Ring you will need to reference the ring with a Open Subring slot action to access it.",
            width = "half",
            func = function()
                CreateNewRing()
                SelectInitialSlotForEdit()
                RebuildAll()
            end,
        },
        {
            type = "button",
            name = "Remove Ring",
            width = "half",
            disabled = function() return ui.currentEditingRing == nil end,
            func = function()
                if ui.currentEditingRing then
                    local ringIndex = FindEntryIndexByID(ui.currentEditingRing.uniqueid, saveData.rings)
                    if ringIndex then
                        table.remove(saveData.rings, ringIndex)
                    end
                    ui.currentEditingRing = FindEntryByIndex(1, saveData.rings)
                    SelectInitialSlotForEdit()
                    RebuildAll()
                end
            end,
        },
         -----------------------------------------------------------------------
         {
            type = "divider"
         },
         {
            type = "dropdown",
            name = "Edit Slot",
            tooltip = "Select the slot to edit.",
            scrollable = true,
            sort = "value-up",
            reference = "ESOPIE_RingEdit_SlotSelection",
            choices = ui.slotChoices,
            choicesValues = ui.slotChoicesValues,
            disabled = function() return ui.currentEditingRing == nil end,
            getFunc = function()
                if ui.currentEditingSlot then
                    return ui.currentEditingSlot.uniqueid
                else
                    return 0
                end
            end,
            setFunc = function(value)
                if ui.currentEditingRing then
                    ui.currentEditingSlot = FindEntryByID(value, ui.currentEditingRing.slots)
                end
                SelectInitialCollectionCategory()
                if IsCollectableAction(ui.currentEditingSlot) then
                    RebuildCollectionCategoryDropdown()
                    RebuildCollectionItemDropdown()
                end
            end,
        },
        {
            type = "button",
            name = "New Slot",
            tooltip = "Add a new slot to this ring.",
            width = "half",
            disabled = function() return ui.currentEditingRing == nil end,
            func = function()
                CreateNewSlot()
                SelectInitialCollectionCategory()
                RebuildSlotDropdowns()
                if IsCollectableAction(ui.currentEditingSlot) then
                    RebuildCollectionCategoryDropdown()
                    RebuildCollectionItemDropdown()
                end
            end,
        },
        {
            type = "button",
            name = "Remove Slot",
            tooltip = "Remove the selected slot from this ring.",
            width = "half",
            disabled = function() return ui.currentEditingRing == nil end,
            func = function()
                if ui.currentEditingSlot and ui.currentEditingRing then
                    local slotIndex = FindEntryIndexByID(ui.currentEditingSlot.uniqueid, ui.currentEditingRing.slots)
                    if slotIndex then
                        table.remove(ui.currentEditingRing.slots, slotIndex)
                    end
                    SelectInitialSlotForEdit()
                    RebuildSlotDropdowns()
                    if IsCollectableAction(ui.currentEditingSlot) then
                        RebuildCollectionCategoryDropdown()
                        RebuildCollectionItemDropdown()
                    end
                end
            end,
        },
        {
            type = "submenu",
            name = "Configure Selected Slot",
            reference = "ESOPie_SlotEdit_Submenu",
            disabled = function() return ui.currentEditingSlot == nil end,
            controls = {
                {
                    type = "editbox",
                    name = "Slot Name",
                    tooltip = "",
                    isMultiline = false,
                    getFunc = function()
                        if ui.currentEditingSlot then
                            return ui.currentEditingSlot.name
                        else
                            return ""
                        end
                    end,
                    setFunc = function(value)
                        if ui.currentEditingSlot then
                            ui.currentEditingSlot.name = value
                            RebuildSlotDropdowns()
                        end
                    end,
                },
                {
                    type = "iconpicker",
                    name = "Browse for Icon",
                    tooltip = "Select an icon for the slot.",
                    reference = "ESOPIE_SlotEdit_SlotIconPicker",
                    maxColumns = 6,
                    visibleRows = 6,
                    iconSize = 64,
                    width = "full",
                    choices = ESOPIE_ICON_LIBRARY,
                    getFunc = function()
                        if ui.currentEditingSlot then
                            return ui.currentEditingSlot.icon
                        end
                        return ""
                    end,
                    setFunc = function(value)
                        if ui.currentEditingSlot then
                            ui.currentEditingSlot.icon = value
                        end
                    end,
                },
                {
                    type = "editbox",
                    name = "Icon Path",
                    tooltip = "Any icon can be used if you know the path.",
                    isMultiline = false,
                    getFunc = function()
                        if ui.currentEditingSlot then
                            return ui.currentEditingSlot.icon
                        else
                            return ""
                        end
                    end,
                    setFunc = function(value)
                        if ui.currentEditingSlot then
                            ui.currentEditingSlot.icon = value
                        end
                    end,
                },
                -- TODO: visibility condition
                {
                    type = "divider",
                },
                {
                    type = "dropdown",
                    name = "Slot Action",
                    tooltip = "Select the action that should occur when this slot is activated.",
                    --sort = "value-up",
                    choices = ui.actionChoices,
                    choicesValues = ui.actionChoicesValues,
                    getFunc = function()
                        if ui.currentEditingSlot then
                            return ui.currentEditingSlot.action
                        else
                            return 0
                        end
                    end,
                    setFunc = function(value)
                        if ui.currentEditingSlot then
                            ui.currentEditingSlot.action = value
                            ui.currentEditingSlot.data = nil
                        end
                        SelectInitialCollectionCategory()
                        if IsCollectableAction(ui.currentEditingSlot) then
                            RebuildCollectionCategoryDropdown()
                            RebuildCollectionItemDropdown()
                        end
                    end,
                },
                {
                    type = "submenu",
                    name = "Subring",
                    disabled = function() return not IsSubringAction(ui.currentEditingSlot) end,
                    controls = {
                        {
                            type = "dropdown",
                            name = "Subring",
                            tooltip = "Subring to open",
                            reference = "ESOPIE_SlotEdit_Subring",
                            sort = "value-up",
                            choices = ui.ringChoices,
                            choicesValues = ui.ringChoicesValues,
                            getFunc = function()
                                if IsSubringAction(ui.currentEditingSlot) then
                                    return ui.currentEditingSlot.data
                                else
                                    return 0
                                end
                            end,
                            setFunc = function(value)
                                if IsSubringAction(ui.currentEditingSlot) then
                                    ui.currentEditingSlot.data = value
                                end
                            end,
                        },
                    },
                },
                {
                    type = "submenu",
                    name = "Command",
                    disabled = function() return not IsCommandAction(ui.currentEditingSlot) end,
                    controls = {
                        {
                            type = "editbox",
                            name = "Command",
                            tooltip = "Chat command or Lua code to execute when activated.",
                            isMultiline = true,
                            getFunc = function()
                                if IsCommandAction(ui.currentEditingSlot) and type(ui.currentEditingSlot.data) == "string" then
                                    return ui.currentEditingSlot.data
                                else
                                    return ""
                                end
                            end,
                            setFunc = function(value)
                                if IsCommandAction(ui.currentEditingSlot) then
                                    ui.currentEditingSlot.data = value
                                end
                            end,
                        },
                    }
                },
                {
                    type = "submenu",
                    name = "Collection",
                    disabled = function() return not IsCollectableAction(ui.currentEditingSlot) end,
                    controls = {
                        {
                            type = "dropdown",
                            name = "Category",
                            tooltip = "Collectable category to select from.",
                            reference = "ESOPIE_SlotEdit_CollectionCategory",
                            sort = "name-up",
                            choices = {},
                            choicesValues = {},
                            disabled = function() return not (IsCollectableAction(ui.currentEditingSlot) and CollectionHasCategory(ui.currentEditingSlot)) end,
                            getFunc = function()
                                if IsCollectableAction(ui.currentEditingSlot) then
                                    local categoryId = GetCategoryFromData(ui.currentEditingSlot.action, ui.currentEditingSlot.data)
                                    return categoryId
                                end
                                return 0
                            end,
                            setFunc = function(value)
                                if IsCollectableAction(ui.currentEditingSlot) then
                                    ui.selectedCollectionCategory = value
                                end
                            end,
                        },
                        {
                            type = "dropdown",
                            name = "Collectable",
                            tooltip = "Collectable to use when activated.",
                            reference = "ESOPIE_SlotEdit_CollectionItem",
                            sort = "name-up",
                            choices = {},
                            choicesValues = {},
                            getFunc = function()
                                if IsCollectableAction(ui.currentEditingSlot) and type(ui.currentEditingSlot.data) == "number" then
                                    return ui.currentEditingSlot.data
                                else
                                    return 0
                                end
                            end,
                            setFunc = function(value)
                                if IsCollectableAction(ui.currentEditingSlot) then
                                    ui.currentEditingSlot.data = value
                                    --ui.currentEditingSlot.icon = GetCollectibleIcon(value)
                                end
                            end,
                        },
                    },
                },
            },
        },
    }

    local panelData = {
        type = "panel",
        name = ESOPie.name,
        displayName = L(ESOPIE_SETTINGS_PANEL_NAME),
        author = ESOPie.author,
        version = ESOPie.version,
        registerForRefresh = true,
        registerForDefaults = false,
        slashCommand = ESOPie.slashCommand,
        -- website = "",
        -- feedback = "",
        -- donation = "",
    }

    ESOPie.LAMPanel = LAM:RegisterAddonPanel(ESOPie.settingsPanelName, panelData)
    LAM:RegisterOptionControls(ESOPie.settingsPanelName, optionsTable)

    CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated", OnPanelCreated)
    --CALLBACK_MANAGER:RegisterCallback("LAM-RefreshPanel", OnPanelRefreshed)
    --CALLBACK_MANAGER:RegisterCallback("LAM-PanelOpened", MyLAMPanelOpened)
    --CALLBACK_MANAGER:RegisterCallback("LAM-PanelClosed", MyLAMPanelClosed)
end