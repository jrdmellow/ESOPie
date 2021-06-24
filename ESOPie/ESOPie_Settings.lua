if not ESOPie then d("[ESOPIE] ERROR: ESOPie not initialized.") return end

local L = GetString
local LAM = LibAddonMenu2
local Dialog = LibDialog

local LogVerbose = ESOPie.LogVerbose
local LogDebug = ESOPie.LogDebug
local LogInfo = ESOPie.LogInfo
local LogWarning = ESOPie.LogWarning
local LogError = ESOPie.LogError
local Notify = ESOPie.Notify

local ESOPIE_DEFAULT_RING = {
    uniqueid = 0,
    type = ESOPie.EntryType.Ring,
    name = L(ESOPIE_DEFAULT_RINGNAME),
    slots = {}
}
local ESOPIE_DEFAULT_SLOTINFO = {
    uniqueid = 0,
    type = ESOPie.EntryType.Slot,
    name = L(ESOPIE_DEFAULT_ACTIONNAME),
    icon = ESOPIE_ICON_SLOT_DEFAULT,
    action = ESOPie.Action.Noop,
    data = nil
}
local ESOPIE_DB_DEFAULT = {
    ["entries"] =
    {
        --- SLOTS
        {
            ["uniqueid"] = 1,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = "Social",
            ["action"] = ESOPie.Action.Submenu,
            ["icon"] = "/esoui/art/icons/ability_debuff_silence.dds",
            ["data"] = 15,
        },
        {
            ["uniqueid"] = 2,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = "Show Off",
            ["action"] = ESOPie.Action.Submenu,
            ["icon"] = "/esoui/art/icons/ability_debuff_levitate.dds",
            ["data"] = 14,
        },
        {
            ["uniqueid"] = 3,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = "Music",
            ["action"] = ESOPie.Action.Submenu,
            ["icon"] = "/esoui/art/icons/housing_bre_inc_musiclute001.dds",
            ["data"] = 13,
        },
        {
            ["uniqueid"] = 4,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = "Play Lute",
            ["action"] = ESOPie.Action.PlayEmote,
            ["icon"] = "/esoui/art/icons/housing_bre_inc_musiclute001.dds",
            ["data"] = 5,
        },
        {
            ["uniqueid"] = 5,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = "Play Drums",
            ["action"] = ESOPie.Action.PlayEmote,
            ["icon"] = "/esoui/art/icons/housing_bre_inc_musicdrum001.dds",
            ["data"] = 7,
        },
        {
            ["uniqueid"] = 6,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = "Play Flute",
            ["action"] = ESOPie.Action.PlayEmote,
            ["icon"] = "/esoui/art/icons/housing_bre_inc_musicrecorder001.dds",
            ["data"] = 6,
        },
        {
            ["uniqueid"] = 7,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = "Scorch",
            ["action"] = ESOPie.Action.PlayEmote,
            ["icon"] = "/esoui/art/icons/ability_companion_mageguild_001.dds",
            ["data"] = 611,
        },
        {
            ["uniqueid"] = 8,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = "Flex",
            ["action"] = ESOPie.Action.PlayEmote,
            ["icon"] = "/esoui/art/icons/emote_flex.dds",
            ["data"] = 468,
        },
        {
            ["uniqueid"] = 9,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = "Greet",
            ["action"] = ESOPie.Action.PlayEmote,
            ["icon"] = "/esoui/art/icons/ability_companion_nightblade_013.dds",
            ["data"] = 162,
        },
        {
            ["uniqueid"] = 10,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = "Clap",
            ["action"] = ESOPie.Action.PlayEmote,
            ["icon"] = "/esoui/art/icons/ability_companion_restorationstaff_002.dds",
            ["data"] = 185,
        },
        {
            ["uniqueid"] = 11,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = "Congratulate",
            ["action"] = ESOPie.Action.PlayEmote,
            ["icon"] = "/esoui/art/icons/ability_buff_minor_force.dds",
            ["data"] = 172,
        },
        --- RINGS
        {
            ["uniqueid"] = 12,
            ["type"] = ESOPie.EntryType.Ring,
            ["name"] = "Root",
            ["slots"] = { 1, 2, 3 },
        },
        {
            ["uniqueid"] = 13,
            ["type"] = ESOPie.EntryType.Ring,
            ["name"] = "Music",
            ["slots"] = { 4, 5, 6},
        },
        {
            ["uniqueid"] = 14,
            ["type"] = ESOPie.EntryType.Ring,
            ["name"] = "Show Off",
            ["slots"] = { 7, 8 },
        },
        {
            ["uniqueid"] = 15,
            ["type"] = ESOPie.EntryType.Ring,
            ["name"] = "Social",
            ["slots"] = { 9, 10, 11 },
        },
    },
    ["rootRings"] = { 12, 13, 0, 0, 0, 0 },
    ["savedVersion"] = ESOPie.savedVarsVersion,
}

local ui = {
    initialized = false,
    nextUniqueID = 0,
    collectionCategoryCache = {
        [ESOPie.CollectionType.Allies] = { names = {}, values = {} },
        [ESOPie.CollectionType.Momento] = { names = {}, values = {} },
        [ESOPie.CollectionType.VanityPet] = { names = {}, values = {} },
        [ESOPie.CollectionType.Emote] = { names = {}, values = {} },
    },
    actionChoices = {},
    actionChoicesValues = {},
    bindingRingChoices = {},
    bindingRingValues = {},
    configurationChoices = {},
    configurationValues = {},
    selectedCollectionCategory = 0,
    currentEditing = nil
}

local function EntryIsRing(entry)
    if not entry then return false end
    return entry.type == ESOPie.EntryType.Ring
end

local function EntryIsSlot(entry)
    if not entry then return false end
    return entry.type == ESOPie.EntryType.Slot
end

local function GetCategoryFromData(actionType, data)
    if actionType == ESOPie.Action.PlayEmote then
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

local function IsSubringAction(entry)
    if not EntryIsSlot(entry) then return false end
    return entry.action == ESOPie.Action.Submenu
end

local function IsCommandAction(entry)
    if not EntryIsSlot(entry) then return false end
    return entry.action == ESOPie.Action.ChatExec or entry.action == ESOPie.Action.CodeExec
end

local function IsEmoteAction(entry)
    if not EntryIsSlot(entry) then return false end
    return entry.action == ESOPie.Action.PlayEmote
end

local function IsAllyAction(entry)
    if not EntryIsSlot(entry) then return false end
    return entry.action == ESOPie.Action.SummonAlly
end

local function IsCollectableAction(entry)
    if not EntryIsSlot(entry) then return false end
    return IsEmoteAction(entry) or IsAllyAction(entry)
end

local function CollectionHasCategory(entry)
    if not EntryIsSlot(entry) then return false end
    if      entry.action == ESOPie.Action.PlayEmote     then return true
    elseif  entry.action == ESOPie.Action.SummonAlly    then return true
    elseif  entry.action == ESOPie.Action.SetMount      then return true
    elseif  entry.action == ESOPie.Action.SetVanityPet  then return true
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
    local emoteCache = ui.collectionCategoryCache[ESOPie.CollectionType.Emote]
    ZO_ClearTable(emoteCache.names)
    ZO_ClearTable(emoteCache.values)
    local emoteCategories = PLAYER_EMOTE_MANAGER:GetEmoteCategories()
    for _, category in pairs(emoteCategories) do
        local categoryName = L("SI_EMOTECATEGORY", category)
        table.insert(emoteCache.names, categoryName)
        table.insert(emoteCache.values, category)
    end
end

local function SelectInitialCollectionCategory()
    if IsCollectableAction(ui.currentEditing) and CollectionHasCategory(ui.currentEditing) then
        ui.selectedCollectionCategory = GetCategoryFromData(ui.currentEditing.action, ui.currentEditing.data)
    else
        ui.selectedCollectionCategory = 0
    end
end

local function RebuildCollectionCategoryDropdown()
    local names = {}
    local values = {}
    if EntryIsSlot(ui.currentEditing) then
        local actionType = ui.currentEditing.action
        if actionType == ESOPie.Action.PlayEmote then
            local cache = ui.collectionCategoryCache[ESOPie.CollectionType.Emote]
            names = cache.names
            values = cache.values
        elseif actionType == ESOPie.Action.PlayMomento then
        elseif actionType == ESOPie.Action.SummonAlly then
        elseif actionType == ESOPie.Action.SetMount then
        elseif actionType == ESOPie.Action.SetVanityPet then
        end
    end
    UpdateDropdown("ESOPIE_SlotEdit_CollectionCategory", names, values)
end

local function RebuildCollectionItemDropdown()
    local names = {}
    local values = {}
    if EntryIsSlot(ui.currentEditing) then
        local actionType = ui.currentEditing.action
        if actionType == ESOPie.Action.PlayEmote then
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
    ZO_ClearTable(ui.bindingRingChoices)
    ZO_ClearTable(ui.bindingRingValues)
    table.insert(ui.bindingRingChoices, "Disabled")
    table.insert(ui.bindingRingValues, 0)
    for _, entry in pairs(ESOPie.db.entries) do
        if EntryIsRing(entry) then
            table.insert(ui.bindingRingChoices, ZO_CachedStrFormat("<<1>>", entry.name))
            table.insert(ui.bindingRingValues, entry.uniqueid)
        end
    end
    for i=1,ESOPie.maxRingBindings do
        UpdateDropdown("ESOPIE_General_RingBinding" .. tostring(i), ui.bindingRingChoices, ui.bindingRingValues)
    end
    UpdateDropdown("ESOPIE_SlotEdit_Subring", ui.bindingRingChoices, ui.bindingRingValues)

    ZO_ClearTable(ui.configurationChoices)
    ZO_ClearTable(ui.configurationValues)
    for _, ringId in pairs(ui.bindingRingValues) do
        local ring = FindEntryByID(ringId, ESOPie.db.entries, ESOPie.EntryType.Ring)
        if ring then
            table.insert(ui.configurationChoices, ZO_CachedStrFormat("|cffffff<<1>>|r (Ring)", ring.name))
            table.insert(ui.configurationValues, ring.uniqueid)
            for _, slotId in pairs(ring.slots) do
                local slot = FindEntryByID(slotId, ESOPie.db.entries, ESOPie.EntryType.Slot)
                if slot then
                    table.insert(ui.configurationChoices, ZO_CachedStrFormat("-> |c777777<<1>>|r", slot.name))
                    table.insert(ui.configurationValues, slot.uniqueid)
                end
            end
        end
    end
    UpdateDropdown("ESOPIE_Configure_Selection", ui.configurationChoices, ui.configurationValues)
end

local function RebuildAll()
    RebuildRingDropdowns()
    RebuildCollectionCategoryDropdown()
    RebuildCollectionItemDropdown()
end

-------------------------------------------------------------------------------
-- Global Helpers

function ESOPie:ResetToDefault()
    ZO_ClearTable(self.db)
    ZO_DeepTableCopy(ESOPIE_DB_DEFAULT, self.db)
    LogDebug("Settings reset to default.")
end

-------------------------------------------------------------------------------
-- Initialize Addon Menu and Settings DB

function ESOPie:InitializeSettings()
    LogVerbose("Loading save data %s v%d.", self.savedVars, self.savedVarsVersion)
    self.db = ZO_SavedVars:NewAccountWide(self.savedVars, self.savedVarsVersion, nil, ESOPIE_DB_DEFAULT)

    local saveData = ESOPie.db or {}

    local function InitNextID()
        ui.nextUniqueID = 1
        local largestID = 1
        for _, entry in pairs(ESOPie.db.entries) do
            if entry.uniqueid and entry.uniqueid > largestID then
                largestID = entry.uniqueid
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

    local function RemoveEntry(uniqueid, ensureType)
        local entryIndex = FindEntryIndexByID(uniqueid, saveData.entries, ensureType)
        if entryIndex then table.remove(saveData.entries, entryIndex) end
    end

    local function RemoveRing(uniqueid)
        RemoveEntry(uniqueid, ESOPie.EntryType.Ring)
    end

    local function RemoveSlot(uniqueid)
        RemoveEntry(uniqueid, ESOPie.EntryType.Slot)
        for _, entry in pairs(saveData.entries) do
            if EntryIsRing(entry) then
                local removeIndex = nil
                for index, id in pairs(entry.slots) do
                    if id == uniqueid then
                        removeIndex = index
                    end
                end
                if removeIndex then
                    table.remove(entry.slots, removeIndex)
                end
            end
        end
    end

    local function CreateNewSlot()
        if EntryIsRing(ui.currentEditing) then
            local newSlotInfo = {}
            ZO_DeepTableCopy(ESOPIE_DEFAULT_SLOTINFO, newSlotInfo)
            newSlotInfo.uniqueid = GetNextID()
            table.insert(saveData.entries, newSlotInfo)
            table.insert(ui.currentEditing.slots, newSlotInfo.uniqueid)
            return newRing
        end
        return nil
    end

    local function CreateNewRing()
        local newRing = {}
        ZO_DeepTableCopy(ESOPIE_DEFAULT_RING, newRing)
        newRing.uniqueid = GetNextID()
        table.insert(saveData.entries, newRing)
        return newRing
    end

    local function OnConfirmRemoveEntry()
        if EntryIsRing(ui.currentEditing) then
            RemoveRing(ui.currentEditing.uniqueid)
        elseif EntryIsSlot(ui.currentEditing) then
            RemoveSlot(ui.currentEditing.uniqueid)
        end
        ui.currentEditing = FindEntryByID(saveData.rootRings[1], saveData.entries)
        RebuildRingDropdowns()
        LAM.util.RequestRefreshIfNeeded(ESOPie.LAMPanel)
    end

    local function OnConfirmChangeSlotAction(value)
        ui.currentEditing.action = value
        ui.currentEditing.data = nil
        SelectInitialCollectionCategory()
        if IsCollectableAction(ui.currentEditing) then
            RebuildCollectionCategoryDropdown()
            RebuildCollectionItemDropdown()
        end
        LAM.util.RequestRefreshIfNeeded(ESOPie_SlotEdit_Submenu)
    end

    UpdateInternalCache()
    UpdateCollectionsCache()

    ui.currentEditing = FindEntryByID(saveData.rootRings[1], saveData.entries)

    local optionsTable = {
        -- TODO: Localize
        {
            type = "submenu",
            name = "General Options",
            controls = {
                {
                    type = "dropdown",
                    reference = "ESOPIE_General_RingBinding1",
                    name = "Ring Binding 1",
                    scrollable = true,
                    choices = ui.bindingRingChoices,
                    choicesValues = ui.ringValues,
                    getFunc = function()
                        return saveData.rootRings[1]
                    end,
                    setFunc = function(value)
                        saveData.rootRings[1] = value
                    end,
                },
                {
                    type = "dropdown",
                    reference = "ESOPIE_General_RingBinding2",
                    name = "Ring Binding 2",
                    scrollable = true,
                    choices = ui.bindingRingChoices,
                    choicesValues = ui.ringValues,
                    getFunc = function()
                        return saveData.rootRings[2]
                    end,
                    setFunc = function(value)
                        saveData.rootRings[2] = value
                    end,
                },
                {
                    type = "dropdown",
                    reference = "ESOPIE_General_RingBinding3",
                    name = "Ring Binding 3",
                    scrollable = true,
                    choices = ui.bindingRingChoices,
                    choicesValues = ui.ringValues,
                    getFunc = function()
                        return saveData.rootRings[3]
                    end,
                    setFunc = function(value)
                        saveData.rootRings[3] = value
                    end,
                },
                {
                    type = "dropdown",
                    reference = "ESOPIE_General_RingBinding4",
                    name = "Ring Binding 4",
                    scrollable = true,
                    choices = ui.bindingRingChoices,
                    choicesValues = ui.ringValues,
                    getFunc = function()
                        return saveData.rootRings[4]
                    end,
                    setFunc = function(value)
                        saveData.rootRings[4] = value
                    end,
                },
                {
                    type = "dropdown",
                    reference = "ESOPIE_General_RingBinding5",
                    name = "Ring Binding 5",
                    scrollable = true,
                    choices = ui.bindingRingChoices,
                    choicesValues = ui.ringValues,
                    getFunc = function()
                        return saveData.rootRings[5]
                    end,
                    setFunc = function(value)
                        saveData.rootRings[5] = value
                    end,
                },
                {
                    type = "dropdown",
                    reference = "ESOPIE_General_RingBinding6",
                    name = "Ring Binding 6",
                    scrollable = true,
                    choices = ui.bindingRingChoices,
                    choicesValues = ui.ringValues,
                    getFunc = function()
                        return saveData.rootRings[6]
                    end,
                    setFunc = function(value)
                        saveData.rootRings[6] = value
                    end,
                },
            },
        },
        -----------------------------------------------------------------------
        {
            type = "header",
            name = "Configure Rings and Slots",
        },
        {
            type = "button",
            name = "New Ring",
            tooltip = "Add a new ring.\nNote: You will need to either set a binding or create a sub-ring slot to access the new ring.",
            width = "half",
            func = function()
                ui.currentEditing = CreateNewRing()
                RebuildAll()
            end,
        },
        {
            type = "dropdown",
            reference = "ESOPIE_Configure_Selection",
            name = "Entry to Configure",
            tooltip = "Select the ring or slot to configure.",
            scrollable = 20,
            choices = ui.configurationChoices,
            choicesValues = ui.configurationValues,
            getFunc = function()
                if ui.currentEditing then
                    return ui.currentEditing.uniqueid
                end
                return 0
            end,
            setFunc = function(value)
                ui.currentEditing = FindEntryByID(value, saveData.entries)
                SelectInitialCollectionCategory()
                RebuildAll()
            end,
        },
        {
            type = "editbox",
            name = "Name",
            tooltip = "Enter the display name of the selected entry.",
            isMultiline = false,
            reference = "ESOPIE_Configure_Name",
            disabled = function() return ui.currentEditing == nil end,
            getFunc = function()
                if ui.currentEditing then
                    return ui.currentEditing.name
                end
                return ""
            end,
            setFunc = function(value)
                if ui.currentEditing then
                    ui.currentEditing.name = valuewwwwww
                    RebuildRingDropdowns()
                end
            end,
        },
        {
            type = "button",
            name = "Remove",
            tooltip = "Remove the selected entry",
            width = "full",
            disabled = function() return ui.currentEditing == nil end,
            func = function()
                local entryName = ui.currentEditing.name or ("Slot" .. tostring(ui.currentEditing.uniqueid))
                local confirmStr = ZO_CachedStrFormat("Are you sure you want to |cff0000permanently remove|r <<1>>?\nYou will not be able to undo this.", entryName)
                LibDialog:RegisterDialog(ESOPie.name, "RemoveEntryDialog", "Remove Entry", confirmStr, function() OnConfirmRemoveEntry() end, nil, nil, true)
                LibDialog:ShowDialog(ESOPie.name, "RemoveEntryDialog")
            end,
        },
         -----------------------------------------------------------------------
        {
            type = "submenu",
            name = "Configure Selected Ring",
            reference = "ESOPie_RingEdit_Submenu",
            disabled = function() return not EntryIsRing(ui.currentEditing) end,
            controls = {
                {
                    type = "editbox",
                    name = "Slot Count",
                    disabled = true,
                    getFunc = function()
                        if EntryIsRing(ui.currentEditing) then
                            return #ui.currentEditing.slots
                        end
                        return 0
                    end,
                    setFunc = function(value) end,
                },
                {
                    type = "button",
                    name = "New Slot",
                    tooltip = ZO_CachedStrFormat("Add a new slot to this ring. (Maximum of <<1>> per ring)", ESOPie.maxVisibleSlots),
                    width = "full",
                    disabled = function() return not EntryIsRing(ui.currentEditing) or table.getn(ui.currentEditing.slots) >= ESOPie.maxVisibleSlots end,
                    func = function()
                        CreateNewSlot()
                        SelectInitialCollectionCategory()
                        RebuildRingDropdowns()
                        if IsCollectableAction(ui.currentEditing) then
                            RebuildCollectionCategoryDropdown()
                            RebuildCollectionItemDropdown()
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
            disabled = function() return not EntryIsSlot(ui.currentEditing) end,
            controls = {
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
                        if ui.currentEditing then
                            return ui.currentEditing.icon
                        end
                        return ESOPIE_ICON_SLOT_DEFAULT
                    end,
                    setFunc = function(value)
                        if ui.currentEditing then
                            ui.currentEditing.icon = value
                        end
                    end,
                },
                {
                    type = "editbox",
                    name = "Icon Path",
                    tooltip = "Any icon can be used if you know the path.",
                    isMultiline = false,
                    getFunc = function()
                        if ui.currentEditing then
                            return ui.currentEditing.icon
                        end
                        return ESOPIE_ICON_SLOT_DEFAULT
                    end,
                    setFunc = function(value)
                        if ui.currentEditing then
                            ui.currentEditing.icon = value
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
                        if ui.currentEditing then
                            return ui.currentEditing.action
                        end
                        return ESOPie.Action.Noop
                    end,
                    setFunc = function(value)
                        if ui.currentEditing then
                            if ui.currentEditing.action ~= ESOPie.Action.Noop and ui.currentEditing.data ~= nil then
                                local entryName = ui.currentEditing.name or ("Slot" .. tostring(ui.currentEditing.uniqueid))
                                local currentActionName = GetActionTypeString(ui.currentEditing.action)
                                local newActionName = GetActionTypeString(value)
                                local confirmStr = ZO_CachedStrFormat("Are you sure you want to change the action of <<1>> from \"<<2>>\" to \"<<3>>\"?\nYou will lose any data associated with the existing action.", entryName, currentActionName, newActionName)
                                LibDialog:RegisterDialog(ESOPie.name, "ChangeActionTypeDialog", "Change Slot Action", confirmStr, function() OnConfirmChangeSlotAction(value) end, nil, nil, true)
                                LibDialog:ShowDialog(ESOPie.name, "ChangeActionTypeDialog")
                            else
                                OnConfirmChangeSlotAction(value)
                            end
                        end
                    end,
                },
                {
                    type = "submenu",
                    name = "Subring",
                    disabled = function() return not IsSubringAction(ui.currentEditing) end,
                    controls = {
                        {
                            type = "dropdown",
                            reference = "ESOPIE_SlotEdit_Subring",
                            name = "Subring",
                            tooltip = "Subring to open",
                            sort = "value-up",
                            scrollable = true,
                            choices = ui.bindingRingChoices,
                            choicesValues = ui.bindingRingChoices,
                            getFunc = function()
                                if IsSubringAction(ui.currentEditing) then
                                    return ui.currentEditing.data
                                else
                                    return 0
                                end
                            end,
                            setFunc = function(value)
                                if IsSubringAction(ui.currentEditing) then
                                    ui.currentEditing.data = value
                                end
                            end,
                        },
                    },
                },
                {
                    type = "submenu",
                    name = "Command",
                    disabled = function() return not IsCommandAction(ui.currentEditing) end,
                    controls = {
                        {
                            type = "editbox",
                            name = "Command",
                            tooltip = "Chat command or Lua code to execute when activated.",
                            isMultiline = true,
                            getFunc = function()
                                if IsCommandAction(ui.currentEditing) and type(ui.currentEditing.data) == "string" then
                                    return ui.currentEditing.data
                                else
                                    return ""
                                end
                            end,
                            setFunc = function(value)
                                if IsCommandAction(ui.currentEditing) then
                                    ui.currentEditing.data = value
                                end
                            end,
                        },
                    }
                },
                {
                    type = "submenu",
                    name = "Collection",
                    disabled = function() return not IsCollectableAction(ui.currentEditing) end,
                    controls = {
                        {
                            type = "dropdown",
                            reference = "ESOPIE_SlotEdit_CollectionCategory",
                            name = "Category",
                            tooltip = "Collectable category to select from.",
                            sort = "name-up",
                            scrollable = true,
                            choices = {},
                            choicesValues = {},
                            disabled = function() return not (IsCollectableAction(ui.currentEditing) and CollectionHasCategory(ui.currentEditing)) end,
                            getFunc = function()
                                if IsCollectableAction(ui.currentEditing) then
                                    local categoryId = GetCategoryFromData(ui.currentEditing.action, ui.currentEditing.data)
                                    return categoryId
                                end
                                return 0
                            end,
                            setFunc = function(value)
                                if IsCollectableAction(ui.currentEditing) then
                                    ui.selectedCollectionCategory = value
                                    RebuildCollectionItemDropdown()
                                end
                            end,
                        },
                        {
                            type = "dropdown",
                            reference = "ESOPIE_SlotEdit_CollectionItem",
                            name = "Collectable",
                            tooltip = "Collectable to use when activated.",
                            sort = "name-up",
                            scrollable = true,
                            choices = {},
                            choicesValues = {},
                            getFunc = function()
                                if IsCollectableAction(ui.currentEditing) and type(ui.currentEditing.data) == "number" then
                                    return ui.currentEditing.data
                                else
                                    return 0
                                end
                            end,
                            setFunc = function(value)
                                if IsCollectableAction(ui.currentEditing) then
                                    ui.currentEditing.data = value
                                    --ui.currentEditing.icon = GetCollectibleIcon(value)
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