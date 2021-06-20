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

local formData = {
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
    ZO_ClearTable(formData.actionChoices)
    ZO_ClearTable(formData.actionChoicesValues)
    for _, action in pairs(ESOPie.supportedActions) do
        if action and action > 0 then -- Don't include NOOP
            local actionName = GetActionTypeString(action) or string.format("Invalid<%d>", action)
            table.insert(formData.actionChoices, actionName)
            table.insert(formData.actionChoicesValues, action)
        end
    end
end

local function UpdateCollectionsCache()
    local cache = formData.collectionCache
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
    if IsCollectableAction(formData.currentEditingSlot) and CollectionHasCategory(formData.currentEditingSlot) then
        formData.selectedCollectionCategory = GetCategoryFromData(formData.currentEditingSlot.action, formData.currentEditingSlot.data)
    else
        formData.selectedCollectionCategory = 0
    end
end

local function SelectInitialSlotForEdit()
    if formData.currentEditingRing then
        formData.currentEditingSlot = FindEntryByIndex(1, formData.currentEditingRing.slots)
        SelectInitialCollectionCategory()
    else
        formData.currentEditingSlot = nil
    end
end

local function RebuildCollectionCategoryDropdown()
    local names = {}
    local values = {}
    if formData.currentEditingSlot then
        local actionType = formData.currentEditingSlot.action
        if actionType == ESOPie.actions.ACTION_PLAYEMOTE then
            names = formData.collectionCache.emoteCategoryNames
            values = formData.collectionCache.emoteCategoryValues
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
    if formData.currentEditingSlot then
        local actionType = formData.currentEditingSlot.action
        if actionType == ESOPie.actions.ACTION_PLAYEMOTE then
            local categoryId = formData.selectedCollectionCategory
            local emotesList = PLAYER_EMOTE_MANAGER:GetEmoteListForType(categoryId)
            if emotesList then
                for _, emote in pairs(emotesList) do
                    local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(emote)
                    table.insert(names, emoteInfo.displayName)
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
    ZO_ClearTable(formData.ringChoices)
    ZO_ClearTable(formData.ringChoicesValues)
    for _, ring in pairs(ESOPie.db.rings) do
        table.insert(formData.ringChoices, string.format("%s (%d)", ring.name, #ring.slots))
        table.insert(formData.ringChoicesValues, ring.uniqueid)
    end
    UpdateDropdown("ESOPIE_General_RootRing", formData.ringChoices, formData.ringChoicesValues)
    UpdateDropdown("ESOPIE_RingEdit_Selection", formData.ringChoices, formData.ringChoicesValues)
    UpdateDropdown("ESOPIE_SlotEdit_Subring", formData.ringChoices, formData.ringChoicesValues)
end

local function RebuildSlotDropdowns()
    ZO_ClearTable(formData.slotChoices)
    ZO_ClearTable(formData.slotChoicesValues)
    if formData.currentEditingRing and formData.currentEditingRing.slots then
        for _, slot in pairs(formData.currentEditingRing.slots) do
            table.insert(formData.slotChoices, slot.name)
            table.insert(formData.slotChoicesValues, slot.uniqueid)
        end
    end
    UpdateDropdown("ESOPIE_RingEdit_SlotSelection", formData.slotChoices, formData.slotChoicesValues)
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
        formData.nextUniqueID = 1
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
            formData.nextUniqueID = largestID + 1
        end
    end

    local function GetNextID()
        local id = formData.nextUniqueID
        formData.nextUniqueID = formData.nextUniqueID + 1
        return id
    end

    local function OnPanelCreated(panel)
        if panel ~= ESOPie.LAMPanel then return end
        LogVerbose("OnPanelCreated")
        InitNextID()
        UpdateCollectionsCache()
        RebuildAll()
        formData.initialized = true
    end

    local function CreateNewSlot()
        if formData.currentEditingRing then
            local newSlotInfo = {}
            ZO_DeepTableCopy(ESOPIE_DEFAULT_SLOTINFO, newSlotInfo)
            newSlotInfo.uniqueid = GetNextID()
            table.insert(formData.currentEditingRing.slots, newSlotInfo)
            formData.currentEditingSlot = newSlotInfo
        end
    end

    local function CreateNewRing()
        local newRing = {}
        ZO_DeepTableCopy(ESOPIE_DEFAULT_RING, newRing)
        newRing.uniqueid = GetNextID()
        table.insert(saveData.rings, newRing)
        formData.currentEditingRing = newRing
        CreateNewSlot()
    end

    UpdateInternalCache()
    UpdateCollectionsCache()

    formData.currentEditingRing = FindEntryByID(saveData.rootRing, saveData.rings)
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
            choices = formData.ringChoices,
            choicesValues = formData.ringChoicesValues,
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
            choices = formData.ringChoices,
            choicesValues = formData.ringChoicesValues,
            scrollable = true,
            sort = "value-up",
            reference = "ESOPIE_RingEdit_Selection",
            getFunc = function()
                if formData.currentEditingRing then
                    return formData.currentEditingRing.uniqueid
                end
                return 0
            end,
            setFunc = function(value)
                formData.currentEditingRing = FindEntryByID(value, saveData.rings)
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
            disabled = function() return formData.currentEditingRing == nil end,
            getFunc = function()
                if formData.currentEditingRing then
                    return formData.currentEditingRing.name
                end
                return ""
            end,
            setFunc = function(value)
                if formData.currentEditingRing then
                    formData.currentEditingRing.name = value
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
            disabled = function() return formData.currentEditingRing == nil end,
            func = function()
                if formData.currentEditingRing then
                    local ringIndex = FindEntryIndexByID(formData.currentEditingRing.uniqueid, saveData.rings)
                    if ringIndex then
                        table.remove(saveData.rings, ringIndex)
                    end
                    formData.currentEditingRing = FindEntryByIndex(1, saveData.rings)
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
            choices = formData.slotChoices,
            choicesValues = formData.slotChoicesValues,
            disabled = function() return formData.currentEditingRing == nil end,
            getFunc = function()
                if formData.currentEditingSlot then
                    return formData.currentEditingSlot.uniqueid
                else
                    return 0
                end
            end,
            setFunc = function(value)
                if formData.currentEditingRing then
                    formData.currentEditingSlot = FindEntryByID(value, formData.currentEditingRing.slots)
                end
                SelectInitialCollectionCategory()
                if IsCollectableAction(formData.currentEditingSlot) then
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
            disabled = function() return formData.currentEditingRing == nil end,
            func = function()
                CreateNewSlot()
                SelectInitialCollectionCategory()
                RebuildSlotDropdowns()
                if IsCollectableAction(formData.currentEditingSlot) then
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
            disabled = function() return formData.currentEditingRing == nil end,
            func = function()
                if formData.currentEditingSlot and formData.currentEditingRing then
                    local slotIndex = FindEntryIndexByID(formData.currentEditingSlot.uniqueid, formData.currentEditingRing.slots)
                    if slotIndex then
                        table.remove(formData.currentEditingRing.slots, slotIndex)
                    end
                    SelectInitialSlotForEdit()
                    RebuildSlotDropdowns()
                    if IsCollectableAction(formData.currentEditingSlot) then
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
            disabled = function() return formData.currentEditingSlot == nil end,
            controls = {
                {
                    type = "editbox",
                    name = "Slot Name",
                    tooltip = "",
                    isMultiline = false,
                    getFunc = function()
                        if formData.currentEditingSlot then
                            return formData.currentEditingSlot.name
                        else
                            return ""
                        end
                    end,
                    setFunc = function(value)
                        if formData.currentEditingSlot then
                            formData.currentEditingSlot.name = value
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
                        if formData.currentEditingSlot then
                            return formData.currentEditingSlot.icon
                        end
                        return ""
                    end,
                    setFunc = function(value)
                        if formData.currentEditingSlot then
                            formData.currentEditingSlot.icon = value
                        end
                    end,
                },
                {
                    type = "editbox",
                    name = "Icon Path",
                    tooltip = "Any icon can be used if you know the path.",
                    isMultiline = false,
                    getFunc = function()
                        if formData.currentEditingSlot then
                            return formData.currentEditingSlot.icon
                        else
                            return ""
                        end
                    end,
                    setFunc = function(value)
                        if formData.currentEditingSlot then
                            formData.currentEditingSlot.icon = value
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
                    choices = formData.actionChoices,
                    choicesValues = formData.actionChoicesValues,
                    getFunc = function()
                        if formData.currentEditingSlot then
                            return formData.currentEditingSlot.action
                        else
                            return 0
                        end
                    end,
                    setFunc = function(value)
                        if formData.currentEditingSlot then
                            formData.currentEditingSlot.action = value
                            formData.currentEditingSlot.data = nil
                        end
                        SelectInitialCollectionCategory()
                        if IsCollectableAction(formData.currentEditingSlot) then
                            RebuildCollectionCategoryDropdown()
                            RebuildCollectionItemDropdown()
                        end
                    end,
                },
                {
                    type = "submenu",
                    name = "Subring",
                    disabled = function() return not IsSubringAction(formData.currentEditingSlot) end,
                    controls = {
                        {
                            type = "dropdown",
                            name = "Subring",
                            tooltip = "Subring to open",
                            reference = "ESOPIE_SlotEdit_Subring",
                            sort = "value-up",
                            choices = formData.ringChoices,
                            choicesValues = formData.ringChoicesValues,
                            getFunc = function()
                                if IsSubringAction(formData.currentEditingSlot) then
                                    return formData.currentEditingSlot.data
                                else
                                    return 0
                                end
                            end,
                            setFunc = function(value)
                                if IsSubringAction(formData.currentEditingSlot) then
                                    formData.currentEditingSlot.data = value
                                end
                            end,
                        },
                    },
                },
                {
                    type = "submenu",
                    name = "Command",
                    disabled = function() return not IsCommandAction(formData.currentEditingSlot) end,
                    controls = {
                        {
                            type = "editbox",
                            name = "Command",
                            tooltip = "Chat command or Lua code to execute when activated.",
                            isMultiline = true,
                            getFunc = function()
                                if IsCommandAction(formData.currentEditingSlot) and type(formData.currentEditingSlot.data) == "string" then
                                    return formData.currentEditingSlot.data
                                else
                                    return ""
                                end
                            end,
                            setFunc = function(value)
                                if IsCommandAction(formData.currentEditingSlot) then
                                    formData.currentEditingSlot.data = value
                                end
                            end,
                        },
                    }
                },
                {
                    type = "submenu",
                    name = "Collection",
                    disabled = function() return not IsCollectableAction(formData.currentEditingSlot) end,
                    controls = {
                        {
                            type = "dropdown",
                            name = "Category",
                            tooltip = "Collectable category to select from.",
                            reference = "ESOPIE_SlotEdit_CollectionCategory",
                            sort = "name-up",
                            choices = {},
                            choicesValues = {},
                            disabled = function() return not (IsCollectableAction(formData.currentEditingSlot) and CollectionHasCategory(formData.currentEditingSlot)) end,
                            getFunc = function()
                                if IsCollectableAction(formData.currentEditingSlot) then
                                    local categoryId = GetCategoryFromData(formData.currentEditingSlot.action, formData.currentEditingSlot.data)
                                    return categoryId
                                end
                                return 0
                            end,
                            setFunc = function(value)
                                if IsCollectableAction(formData.currentEditingSlot) then
                                    formData.selectedCollectionCategory = value
                                end
                            end,
                        },
                        {
                            type = "dropdown",
                            name = "Emote",
                            tooltip = "Emote to use when activated.",
                            reference = "ESOPIE_SlotEdit_CollectionItem",
                            sort = "name-up",
                            choices = {},
                            choicesValues = {},
                            getFunc = function()
                                if IsCollectableAction(formData.currentEditingSlot) and type(formData.currentEditingSlot.data) == "number" then
                                    return formData.currentEditingSlot.data
                                else
                                    return 0
                                end
                            end,
                            setFunc = function(value)
                                if IsCollectableAction(formData.currentEditingSlot) then
                                    formData.currentEditingSlot.data = value
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