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
    action = ESOPIE_ACTION_NOOP,
    data = {}
}
local ESOPIE_DB_DEFAULT = {
    rings = {
        [1] = {
            uniqueid = 1,
            name = L(ESOPIE_DEFAULT_ROOTNAME),
            slots = {
                {
                    uniqueid = 2,
                    name = L(ESOPIE_DEFAULT_SOCIALRING),
                    icon = "",
                    action = ESOPie.actions.ACTION_SUBMENU,
                    data = L(ESOPIE_DEFAULT_SOCIALRING),
                },
                {
                    uniqueid = 3,
                    name = L(ESOPIE_DEFAULT_OPENEMOTES),
                    icon = "",
                    action = ESOPie.actions.ACTION_OPENEMOTEWHEEL,
                    data = nil,
                }
            }
        },
        [2] = {
            uniqueid = 4,
            name = L(ESOPIE_DEFAULT_SOCIALRING),
            slots = {
                {
                    uniqueid = 5,
                    name = L(ESOPIE_DEFAULT_WAVEACTION),
                    icon = "",
                    action = ESOPie.actions.ACTION_CHATEXEC,
                    data = "/wave",
                },
                {
                    uniqueid = 6,
                    name = L(ESOPIE_DEFAULT_SAYHELLO),
                    icon = "",
                    action = ESOPie.actions.ACTION_CHATEXEC,
                    data = "/s " .. L(ESOPIE_DEFAULT_CHATHELLO),
                },
            }
        },
    },
    rootRing = 1,
}

local formData = {
    nextUniqueID = 0,
    collectionCache = {
        emoteCategories = {},
        emoteCategoryNames = {},
        emoteCategoryValues = {},
        mountNames = {},
        mountValues = {},
        momentoNames = {},
        momentoValues = {},
    },
    iconCategoryNames = { "General", "Abilities", "Achievements", "Other" },
    iconCategoryValues = { ESOPIE_ICON_CATEGORY_GENERAL, ESOPIE_ICON_CATEGORY_ABILITIES, ESOPIE_ICON_CATEGORY_ACHIEVEMENTS, ESOPIE_ICON_CATEGORY_OTHER },
    actionChoices = {},
    actionChoicesValues = {},
    ringChoices = {},
    ringChoicesValues = {},
    slotChoices = {},
    slotChoicesValues = {},
    selectedEmoteCategory = 0,
    selectedIconCategory = ESOPIE_ICON_CATEGORY_GENERAL,
    currentEditingRing = {},
    currentEditingSlot = {}
}

local function ToggleSubmenu(controlName, open) -- Thanks to AutoCategory for this one
    local control = WINDOW_MANAGER:GetControlByName(controlName, "")
    if not control then
        LogVerbose("[Toggle] Unable to find control (%s)", controlName)
        return
    end
    control.open = open
    if control.open then
        control.animation:PlayFromStart()
    else
        control.animation:PlayFromEnd()
    end
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

local function UpdateTexture(controlName, image)
    local control = WINDOW_MANAGER:GetControlByName(controlName)
    if not control then
        LogVerbose("[Preview] Unable to find control (%s)", controlName)
    end
    LogVerbose("Updating texture '%s' => '%s'", controlName, image)
    control.texture:SetTexture(image)
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
    UpdateDropdown("ESOPIE_SlotEdit_EmoteCategory", cache.emoteCategoryNames, cache.emoteCategoryValues)

    ZO_ClearTable(cache.mountNames)
    ZO_ClearTable(cache.mountValues)
    -- COLLECTIBLE_CATEGORY_TYPE_MOUNT

    ZO_ClearTable(cache.momentoNames)
    ZO_ClearTable(cache.momentoValues)
    -- COLLECTIBLE_CATEGORY_TYPE_MEMENTO
end

local function RefreshEmotePreview()
    local icon = "/esoui/art/help/help_tabicon_emotes_up.dds"
    if formData.currentEditingSlot then
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(formData.currentEditingSlot.data)
        if collectibleData then
            icon = collectibleData:GetIcon()
        end
    end
    UpdateTexture("ESOPIE_SlotEdit_EmoteIcon", icon)
end

local function RebuildEmoteDropdown()
    local emoteNames = {}
    local emoteValues = {}
    local emotesList = PLAYER_EMOTE_MANAGER:GetEmoteListForType(formData.selectedEmoteCategory)
    for _, emote in pairs(emotesList) do
        local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(emote)
        table.insert(emoteNames, emoteInfo.displayName)
        table.insert(emoteValues, emoteInfo.emoteId)
    end
    UpdateDropdown("ESOPIE_SlotEdit_Emote", emoteNames, emoteValues)
    RefreshEmotePreview()
end

local function RebuildDropdowns()
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

    ZO_ClearTable(formData.slotChoices)
    ZO_ClearTable(formData.slotChoicesValues)
    if formData.currentEditingRing and formData.currentEditingRing.slots then
        for _, slot in pairs(formData.currentEditingRing.slots) do
            table.insert(formData.slotChoices, slot.name)
            table.insert(formData.slotChoicesValues, slot.uniqueid)
        end
    end
    UpdateDropdown("ESOPIE_RingEdit_SlotSelection", formData.slotChoices, formData.slotChoicesValues)

    --ToggleSubmenu("ESOPie_RingEdit_Submenu", formData.currentlyEditingRing ~= nil)
    --ToggleSubmenu("ESOPie_SlotEdit_Submenu", formData.currentEditingSlot ~= nil)
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
        RebuildDropdowns()
    end

    local function OnPanelRefreshed(panel)
        if panel ~= ESOPie.LAMPanel then return end
        if formData.nextUniqueID > 1 then -- panel has been created
            LogVerbose("OnPanelRefreshed")
            RebuildDropdowns()
        end
    end

    InitNextID()

    ZO_ClearTable(formData.actionChoices)
    ZO_ClearTable(formData.actionChoicesValues)
    for _, action in pairs(ESOPie.actions) do
        if action and action > 0 then -- Don't include NOOP
            local actionName = GetActionTypeString(action) or string.format("Invalid<%d>", action)
            table.insert(formData.actionChoices, actionName)
            table.insert(formData.actionChoicesValues, action)
        end
    end

    formData.currentEditingRing = FindEntryByID(saveData.rootRing, saveData.rings)
    formData.currentEditingSlot = nil

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
            type = "divider"
        },
        {
            type = "dropdown",
            name = "Configure Ring",
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
                formData.currentEditingSlot = nil
                RebuildDropdowns()
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
            type = "button",
            name = "New Ring",
            tooltip = "Add a new ring. Note: Unless the new ring is set as Root Ring you will need to reference the ring with a Open Subring slot action to access it.",
            width = "full",
            func = function()
                local newRing = {}
                ZO_DeepTableCopy(ESOPIE_DEFAULT_RING, newRing)
                newRing.uniqueid = GetNextID()
                table.insert(saveData.rings, newRing)
                formData.currentEditingRing = newRing
                formData.currentEditingSlot = nil
                RebuildDropdowns()
            end,
        },
        -----------------------------------------------------------------------
        {
            type = "submenu",
            name = "Configure Selected Ring",
            reference = "ESOPie_RingEdit_Submenu",
            disabled = function() return formData.currentEditingRing == nil end,
            controls = {
                {
                    type = "editbox",
                    name = "Ring Name",
                    tooltip = "Ring name.",
                    isMultiline = false,
                    reference = "ESOPIE_RingEdit_Name",
                    getFunc = function()
                        if formData.currentEditingRing then
                            return formData.currentEditingRing.name
                        end
                        return ""
                    end,
                    setFunc = function(value)
                        if formData.currentEditingRing then
                            formData.currentEditingRing.name = value
                        end
                        RebuildDropdowns()
                    end,
                },
                {
                    type = "button",
                    name = "Remove Ring",
                    width = "full",
                    func = function()
                        if formData.currentEditingRing then
                            local ringIndex = FindEntryIndexByID(formData.currentEditingRing.uniqueid, saveData.rings)
                            if ringIndex then
                                table.remove(saveData.rings, ringIndex)
                            end
                            formData.currentlyEditingRing = nil
                            formData.currentEditingSlot  = nil
                            RebuildDropdowns()
                        end
                    end,
                },
                {
                    type = "dropdown",
                    name = "Configure Slot",
                    tooltip = "Select the slot to edit.",
                    scrollable = true,
                    sort = "value-up",
                    reference = "ESOPIE_RingEdit_SlotSelection",
                    choices = formData.slotChoices,
                    choicesValues = formData.slotChoicesValues,
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
                            RebuildDropdowns()
                        end
                    end,
                },
                {
                    type = "button",
                    name = "New Slot",
                    tooltip = "Add a new slot to this ring.",
                    width = "full",
                    func = function()
                        if formData.currentEditingRing then
                            local newSlotInfo = {}
                            ZO_DeepTableCopy(ESOPIE_DEFAULT_SLOTINFO, newSlotInfo)
                            newSlotInfo.uniqueid = GetNextID()
                            table.insert(formData.currentEditingRing.slots, newSlotInfo)
                            formData.currentEditingSlot = newSlotInfo
                            RebuildDropdowns()
                        end
                    end,
                },
            },
        },
         -----------------------------------------------------------------------
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
                        end
                        RebuildDropdowns()
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
                    beforeShow = function(control, iconPicker) return preventShow end,
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
                    sort = "value-up",
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
                    end,
                },
                {
                    type = "submenu",
                    name = "Command",
                    disabled = function()
                        if formData.currentEditingSlot then
                            return not (formData.currentEditingSlot.action == ESOPie.actions.ACTION_CHATEXEC or formData.currentEditingSlot.action == ESOPie.actions.ACTION_CODEEXEC)
                        else
                            return true
                        end
                    end,
                    controls = {
                        {
                            type = "editbox",
                            name = "Command",
                            tooltip = "Chat command or Lua code to execute when activated.",
                            isMultiline = true,
                            disabled = function()
                                if formData.currentEditingSlot then
                                    return formData.currentEditingSlot.action ~= ESOPie.actions.ACTION_CHATEXEC and formData.currentEditingSlot.action ~= ESOPie.actions.ACTION_CODEEXEC
                                else
                                    return true
                                end
                            end,
                            getFunc = function()
                                if formData.currentEditingSlot then
                                    return formData.currentEditingSlot.data
                                else
                                    return ""
                                end
                            end,
                            setFunc = function(value)
                                if formData.currentEditingSlot then
                                    formData.currentEditingSlot.data = value
                                end
                            end,
                        },
                    }
                },
                {
                    type = "submenu",
                    name = "Subring",
                    disabled = function()
                        return not (formData.currentEditingSlot and formData.currentEditingSlot.action == ESOPie.actions.ACTION_SUBMENU)
                    end,
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
                                if formData.currentEditingSlot then
                                    return formData.currentEditingSlot.data
                                else
                                    return 0
                                end
                            end,
                            setFunc = function(value)
                                if formData.currentEditingSlot then
                                    formData.currentEditingSlot.data = value
                                end
                            end,
                        },
                    },
                },
                {
                    type = "submenu",
                    name = "Emote",
                    disabled = function()
                        return not (formData.currentEditingSlot and formData.currentEditingSlot.action == ESOPie.actions.ACTION_PLAYEMOTE)
                    end,
                    controls = {
                        {
                            type = "dropdown",
                            name = "Category",
                            tooltip = "Emote category to select from.",
                            reference = "ESOPIE_SlotEdit_EmoteCategory",
                            sort = "name-up",
                            choices = formData.collectionCache.emoteCategoryNames,
                            choicesValues = formData.collectionCache.emoteCategoryValues,
                            getFunc = function()
                                if formData.currentEditingSlot then
                                    local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(formData.currentEditingSlot.data)
                                    if emoteInfo then
                                        formData.selectedEmoteCategory = emoteInfo.emoteCategory
                                    end
                                end
                                return formData.selectedEmoteCategory
                            end,
                            setFunc = function(value)
                                formData.selectedEmoteCategory = value
                                RebuildEmoteDropdown()
                            end,
                        },
                        {
                            type = "dropdown",
                            name = "Emote",
                            tooltip = "Emote to use when activated.",
                            reference = "ESOPIE_SlotEdit_Emote",
                            sort = "name-up",
                            choices = {},
                            choicesValues = {},
                            getFunc = function()
                                if formData.currentEditingSlot then
                                    return formData.currentEditingSlot.data
                                else
                                    return 0
                                end
                            end,
                            setFunc = function(value)
                                if formData.currentEditingSlot then
                                    formData.currentEditingSlot.data = value
                                end
                                RefreshEmotePreview()
                            end,
                        },
                        {
                            type = "texture",
                            image = "/esoui/art/help/help_tabicon_emotes_up.dds",
                            imageWith = 64,
                            imageHeight = 64,
                            reference = "ESOPIE_SlotEdit_EmoteIcon",
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
    CALLBACK_MANAGER:RegisterCallback("LAM-RefreshPanel", OnPanelRefreshed)
    --CALLBACK_MANAGER:RegisterCallback("LAM-PanelOpened", MyLAMPanelOpened)
    --CALLBACK_MANAGER:RegisterCallback("LAM-PanelClosed", MyLAMPanelClosed)
end