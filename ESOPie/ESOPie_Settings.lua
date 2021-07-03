if not ESOPie then d("[ESOPIE] ERROR: ESOPie not initialized.") return end

local L = GetString
local LAM = LibAddonMenu2

local LogVerbose = ESOPie.LogVerbose
local LogDebug = ESOPie.LogDebug
local LogInfo = ESOPie.LogInfo
local LogWarning = ESOPie.LogWarning
local LogError = ESOPie.LogError
local Notify = ESOPie.Notify

local TOOLTIP_DEFAULT_FONT = "ZoFontGame"
local TOOLTIP_TITLE_FONT = "ZoFontTooltipTitle"

local ESOPIE_DEFAULT_RING = {
    uniqueid = 0,
    type = ESOPie.EntryType.Ring,
    name = L(ESOPIE_SI_DEFAULT_RINGNAME),
    slots = {}
}
local ESOPIE_DEFAULT_SLOTINFO = {
    uniqueid = 0,
    type = ESOPie.EntryType.Slot,
    name = L(ESOPIE_SI_DEFAULT_ACTIONNAME),
    icon = "",
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
            ["name"] = L(ESOPIE_SI_DEFAULT_SOCIAL),
            ["action"] = ESOPie.Action.Submenu,
            ["icon"] = "/esoui/art/icons/ability_debuff_silence.dds",
            ["data"] = 15,
        },
        {
            ["uniqueid"] = 2,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = L(ESOPIE_SI_DEFAULT_SHOWOFF),
            ["action"] = ESOPie.Action.Submenu,
            ["icon"] = "/esoui/art/icons/ability_debuff_levitate.dds",
            ["data"] = 14,
        },
        {
            ["uniqueid"] = 3,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = L(ESOPIE_SI_DEFAULT_MUSIC),
            ["action"] = ESOPie.Action.Submenu,
            ["icon"] = "/esoui/art/icons/housing_bre_inc_musiclute001.dds",
            ["data"] = 13,
        },
        {
            ["uniqueid"] = 4,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = L(ESOPIE_SI_DEFAULT_LUTE),
            ["action"] = ESOPie.Action.PlayEmote,
            ["icon"] = "/esoui/art/icons/housing_bre_inc_musiclute001.dds",
            ["data"] = 5,
        },
        {
            ["uniqueid"] = 5,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = L(ESOPIE_SI_DEFAULT_DRUM),
            ["action"] = ESOPie.Action.PlayEmote,
            ["icon"] = "/esoui/art/icons/housing_bre_inc_musicdrum001.dds",
            ["data"] = 7,
        },
        {
            ["uniqueid"] = 6,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = L(ESOPIE_SI_DEFAULT_FLUTE),
            ["action"] = ESOPie.Action.PlayEmote,
            ["icon"] = "/esoui/art/icons/housing_bre_inc_musicrecorder001.dds",
            ["data"] = 6,
        },
        {
            ["uniqueid"] = 7,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = L(ESOPIE_SI_DEFAULT_SCORCH),
            ["action"] = ESOPie.Action.PlayEmote,
            ["icon"] = "",
            ["data"] = 611,
        },
        {
            ["uniqueid"] = 8,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = L(ESOPIE_SI_DEFAULT_FLEX),
            ["action"] = ESOPie.Action.PlayEmote,
            ["icon"] = "/esoui/art/icons/emote_flex.dds",
            ["data"] = 468,
        },
        {
            ["uniqueid"] = 9,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = L(ESOPIE_SI_DEFAULT_GREET),
            ["action"] = ESOPie.Action.PlayEmote,
            ["icon"] = "/esoui/art/icons/ability_companion_nightblade_013.dds",
            ["data"] = 162,
        },
        {
            ["uniqueid"] = 10,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = L(ESOPIE_SI_DEFAULT_CLAP),
            ["action"] = ESOPie.Action.PlayEmote,
            ["icon"] = "/esoui/art/icons/ability_companion_restorationstaff_002.dds",
            ["data"] = 185,
        },
        {
            ["uniqueid"] = 11,
            ["type"] = ESOPie.EntryType.Slot,
            ["name"] = L(ESOPIE_SI_DEFAULT_CONGRATULATE),
            ["action"] = ESOPie.Action.PlayEmote,
            ["icon"] = "/esoui/art/icons/ability_buff_minor_force.dds",
            ["data"] = 172,
        },
        --- RINGS
        {
            ["uniqueid"] = 12,
            ["type"] = ESOPie.EntryType.Ring,
            ["name"] = L(ESOPIE_SI_DEFAULT_ROOT),
            ["slots"] = { 1, 2, 3 },
        },
        {
            ["uniqueid"] = 13,
            ["type"] = ESOPie.EntryType.Ring,
            ["name"] = L(ESOPIE_SI_DEFAULT_MUSIC),
            ["slots"] = { 4, 5, 6},
        },
        {
            ["uniqueid"] = 14,
            ["type"] = ESOPie.EntryType.Ring,
            ["name"] = L(ESOPIE_SI_DEFAULT_SHOWOFF),
            ["slots"] = { 7, 8 },
        },
        {
            ["uniqueid"] = 15,
            ["type"] = ESOPie.EntryType.Ring,
            ["name"] = L(ESOPIE_SI_DEFAULT_SOCIAL),
            ["slots"] = { 9, 10, 11 },
        },
    },
    controlOptions = {
        ["keyboard"] = {
            ["bindingInteractMode"] = ESOPie.InteractMode.Hold
        },
        ["gamepad"] = {
            ["bindingInteractMode"] = ESOPie.InteractMode.Toggle
        }
    },
    ["rootRings"] = { 12, 13, 0, 0, 0, 0 },
    ["savedVersion"] = ESOPie.savedVarsVersion,
}

local ui = {
    initialized = false,
    nextUniqueID = 0,
    collectionPopulateCallbacks = {},
    collectibleCategories = { names = {}, values = {}, tooltips = {}, collectibles = {} },
    actionChoices = {},
    actionChoicesValues = {},
    bindingRingChoices = {},
    bindingRingValues = {},
    configurationChoices = {},
    configurationValues = {},
    selectedCollectionCategory = 0,
    currentEditing = nil
}

-------------------------------------------------------------------------------
-- Unique IDs

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

-------------------------------------------------------------------------------
-- Entry Utilities

local function RemoveEntry(uniqueid, ensureType)
    local entryIndex = ESOPie.utils.FindEntryIndexByID(uniqueid, ESOPie.db.entries, ensureType)
    if entryIndex then table.remove(ESOPie.db.entries, entryIndex) end
end

local function RemoveRing(uniqueid)
    local ring = ESOPie.utils.FindEntryByID(uniqueid, ESOPie.db.entries, ESOPie.EntryType.Ring)
    if ring then
        for _, slotId in pairs(ring.slots) do
            RemoveEntry(slotId, ESOPie.EntryType.Slot)
        end
        RemoveEntry(uniqueid, ESOPie.EntryType.Ring)
    end
end

local function RemoveSlot(uniqueid)
    RemoveEntry(uniqueid, ESOPie.EntryType.Slot)
    for _, entry in pairs(ESOPie.db.entries) do
        if ESOPie.utils.EntryIsRing(entry) then
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

local function CreateNewSlot(entryToAdd)
    assert(entryToAdd)
    if ESOPie.utils.EntryIsRing(entryToAdd) then
        local newSlotInfo = {}
        ZO_DeepTableCopy(ESOPIE_DEFAULT_SLOTINFO, newSlotInfo)
        newSlotInfo.uniqueid = GetNextID()
        table.insert(ESOPie.db.entries, newSlotInfo)
        table.insert(entryToAdd.slots, newSlotInfo.uniqueid)
        return newSlotInfo
    else
        LogError("Cannot add slot to an entry that is not a ring.")
    end
    return nil
end

local function CreateNewRing()
    local newRing = {}
    ZO_DeepTableCopy(ESOPIE_DEFAULT_RING, newRing)
    newRing.uniqueid = GetNextID()
    table.insert(ESOPie.db.entries, newRing)
    return newRing
end

-------------------------------------------------------------------------------
-- Action Utilities

local function GetCategoryFromEntry(entry)
    if entry.action == ESOPie.Action.PlayEmote then
        if entry.data and type(entry.data) == "number" then
            local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(entry.data)
            if emoteInfo then
                return emoteInfo.emoteCategory
            end
        end
    elseif ESOPie.utils.CollectionHasCategory(entry) then
        if entry.data and type(entry.data) == "number" then
            local topLevelIndex, subIndex = GetCategoryInfoFromCollectibleId(entry.data)
            local categoryId = GetCollectibleCategoryId(topLevelIndex, subIndex)
            return categoryId
        end
    end

    if ui.collectibleCategories.values and #ui.collectibleCategories.values > 0 then
        return ui.collectibleCategories.values[1]
    else
        return 0
    end
end

-------------------------------------------------------------------------------
-- Tooltip Helpers

local function ShowCollectibleTooltip(control, collectibleId)
    InitializeTooltip(ItemTooltip, control, TOPLEFT, 0, 0, BOTTOMRIGHT)
    ItemTooltip:SetCollectible(collectibleId, SHOW_NICKNAME, SHOW_PURCHASABLE_HINT, SHOW_BLOCK_REASON, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    ItemTooltipTopLevel:BringWindowToTop()
end
local function ShowGenericEmoteTooltip(control, emoteInfo)
    InitializeTooltip(ItemTooltip, control, TOPLEFT, 0, 0, BOTTOMRIGHT)
    ItemTooltip:AddLine(ZO_CachedStrFormat("<<Z:1>>", emoteInfo.displayName), TOOLTIP_TITLE_FONT, ZO_SELECTED_TEXT:UnpackRGB())
    ZO_Tooltip_AddDivider(ItemTooltip)
    ItemTooltip:AddLine(ZO_CachedStrFormat(L(ESOPIE_SI_TOOLTIP_DOEMOTE), ZO_SELECTED_TEXT:Colorize(emoteInfo.emoteSlashName)), TOOLTIP_DEFAULT_FONT, ZO_NORMAL_TEXT:UnpackRGB())
    ItemTooltipTopLevel:BringWindowToTop()
end

-------------------------------------------------------------------------------
-- Cached Data

local function UpdateInternalCache()
    ZO_ClearTable(ui.actionChoices)
    ZO_ClearTable(ui.actionChoicesValues)
    for _, action in pairs(ESOPie.supportedActions) do
        if action and action > 0 then -- Don't include NOOP
            local actionName = ESOPie.utils.GetActionTypeString(action) or string.format("Invalid<%d>", action)
            table.insert(ui.actionChoices, actionName)
            table.insert(ui.actionChoicesValues, action)
        end
    end
end

local function PopulateCollectablesByCategory(categoryTypes, unlockedOnly)
    for _, categoryType in pairs(categoryTypes) do
        local categoryName = L("SI_COLLECTIBLECATEGORYTYPE", categoryType)
        table.insert(ui.collectibleCategories.names, categoryName)
        table.insert(ui.collectibleCategories.values, categoryType)
        local collectibles = { names = {}, values = {}, tooltips = {} }
        for index = 1, GetTotalCollectiblesByCategoryType(categoryType) do
            local collectibleId = GetCollectibleIdFromType(categoryType, index)
            if not unlockedOnly or IsCollectibleUnlocked(collectibleId) then
                if not ui.collectibleCategories.collectibles[categoryType] then
                    ui.collectibleCategories.collectibles[categoryType] = { names = {}, values = {}, tooltips = {} }
                end
                local collectibles = ui.collectibleCategories.collectibles[categoryType]
                table.insert(collectibles.names, GetCollectibleName(collectibleId))
                table.insert(collectibles.values, collectibleId)
                table.insert(collectibles.tooltips, function(tooltipControl) ShowCollectibleTooltip(tooltipControl, collectibleId) end)
            end
        end
    end
end

local function PopulateCollectablesBySubCategory(categoryTypes, unlockedOnly)
    for topLevelIndex = 1, GetNumCollectibleCategories() do
        local categoryName, subCategories, _, _, _, _ = GetCollectibleCategoryInfo(topLevelIndex)
        for subIndex = 1, subCategories do
            local categoryId = GetCollectibleCategoryId(topLevelIndex, subIndex)
            local subName, numCollectibles, _, _ = GetCollectibleSubCategoryInfo(topLevelIndex, subIndex)
            for collectibleIndex = 1, numCollectibles do
                local collectibleId = GetCollectibleId(topLevelIndex, subIndex, collectibleIndex)
                local categoryType = GetCollectibleCategoryType(collectibleId)
                if ESOPie.utils.NumericTableContains(categoryTypes, categoryType) then
                    if not unlockedOnly or IsCollectibleUnlocked(collectibleId) then
                        if not ui.collectibleCategories.collectibles[categoryId] then
                            table.insert(ui.collectibleCategories.names, subName)
                            table.insert(ui.collectibleCategories.values, categoryId)
                            ui.collectibleCategories.collectibles[categoryId] = { names = {}, values = {}, tooltips = {} }
                        end
                        local collectibles = ui.collectibleCategories.collectibles[categoryId]
                        table.insert(collectibles.names, GetCollectibleName(collectibleId))
                        table.insert(collectibles.values, collectibleId)
                        table.insert(collectibles.tooltips, function(tooltipControl) ShowCollectibleTooltip(tooltipControl, collectibleId) end)
                    end
                end
            end
        end
    end
end

local function PopulateEmotes()
    local emoteCategories = PLAYER_EMOTE_MANAGER:GetEmoteCategories()
    for _, categoryId in pairs(emoteCategories) do
        local categoryName = L("SI_EMOTECATEGORY", categoryId)
        table.insert(ui.collectibleCategories.names, categoryName)
        table.insert(ui.collectibleCategories.values, categoryId)

        local collectibles = { names = {}, values = {}, tooltips = {} }
        local emotesList = PLAYER_EMOTE_MANAGER:GetEmoteListForType(categoryId)
        if emotesList then
            for _, emote in pairs(emotesList) do
                local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(emote)
                local emoteDisplayName = ZO_CachedStrFormat("<<1>>", emoteInfo.displayName)
                table.insert(collectibles.names, emoteDisplayName)
                table.insert(collectibles.values, emoteInfo.emoteId)
                local emoteCollectibleId = GetEmoteCollectibleId(emoteInfo.emoteIndex)
                if emoteCollectibleId then
                    table.insert(collectibles.tooltips, function(tooltipControl) ShowCollectibleTooltip(tooltipControl, emoteCollectibleId) end)
                else
                    table.insert(collectibles.tooltips, function(tooltipControl) ShowGenericEmoteTooltip(tooltipControl, emoteInfo) end)
                end
            end
        else
            LogDebug("No emote list for category %d", categoryId)
        end
        ui.collectibleCategories.collectibles[categoryId] = collectibles
    end
end

-------------------------------------------------------------------------------
-- UI Updates

local function UpdateDropdown(controlName, choices, values, tooltips)
    local control = WINDOW_MANAGER:GetControlByName(controlName)
    if not control then
        LogVerbose("[Update] Unable to find control (%s)", controlName)
        return
    end
    control:UpdateChoices(choices, values, tooltips)
    control:UpdateValue()
end

local function SelectInitialCollectionCategory()
    if ESOPie.utils.IsCollectableAction(ui.currentEditing) and ESOPie.utils.CollectionHasCategory(ui.currentEditing) then
        ui.selectedCollectionCategory = GetCategoryFromEntry(ui.currentEditing)
    else
        ui.selectedCollectionCategory = 0
        if #ui.collectibleCategories.values > 0 then
            ui.selectedCollectionCategory = ui.collectibleCategories.values[1]
        end
    end
end

local function UpdateCollectionsCache()
    ZO_ClearTable(ui.collectibleCategories.names)
    ZO_ClearTable(ui.collectibleCategories.values)
    ZO_ClearTable(ui.collectibleCategories.tooltips)
    ZO_ClearTable(ui.collectibleCategories.collectibles)
    if ESOPie.utils.IsCollectableAction(ui.currentEditing) then
        local actionType = ui.currentEditing.action
        local callback = ui.collectionPopulateCallbacks[actionType]
        if callback and type(callback) == "function" then
            callback()
        else
            LogWarning("No populate callback for action <%s>", ESOPie.utils.GetActionTypeString(actionType))
        end
    else
        LogVerbose("Not editing a slot")
    end
    SelectInitialCollectionCategory()
end

local function RebuildCollectionsDropdowns()
    local collectibleNames = {}
    local collectibleValues = {}
    local collectibleTooltips = nil
    local currentCategory = ui.collectibleCategories.collectibles[ui.selectedCollectionCategory]
    if currentCategory then
        collectibleNames = currentCategory.names
        collectibleValues = currentCategory.values
        if not ZO_IsTableEmpty(currentCategory.tooltips) then
            collectibleTooltips = currentCategory.tooltips
        end
    end
    UpdateDropdown("ESOPIE_SlotEdit_CollectionItem", collectibleNames, collectibleValues, collectibleTooltips)
    local categoryTooltips = nil
    if not ZO_IsTableEmpty(ui.collectibleCategories.tooltips) then
        categoryTooltips = ui.collectibleCategories.tooltips
    end
    UpdateDropdown("ESOPIE_SlotEdit_CollectionCategory", ui.collectibleCategories.names, ui.collectibleCategories.values, categoryTooltips)
end

local function RebuildRingDropdowns()
    if not ESOPie.db then LogError("SavedVars DB not initialized.") return end
    ZO_ClearTable(ui.bindingRingChoices)
    ZO_ClearTable(ui.bindingRingValues)
    table.insert(ui.bindingRingChoices, L(ESOPIE_SI_SETTINGS_BINDINGDISABLED))
    table.insert(ui.bindingRingValues, 0)
    for _, entry in pairs(ESOPie.db.entries) do
        if ESOPie.utils.EntryIsRing(entry) then
            table.insert(ui.bindingRingChoices, entry.name)
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
        local ring = ESOPie.utils.FindEntryByID(ringId, ESOPie.db.entries, ESOPie.EntryType.Ring)
        if ring then
            table.insert(ui.configurationChoices, ZO_CachedStrFormat("|cffffff<<1>>|r", ring.name))
            table.insert(ui.configurationValues, ring.uniqueid)
            for _, slotId in pairs(ring.slots) do
                local slot = ESOPie.utils.FindEntryByID(slotId, ESOPie.db.entries, ESOPie.EntryType.Slot)
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
    RebuildCollectionsDropdowns()
end

local function RefreshBindingWarning()
    local validBindingCount = 0
    for i=1,ESOPie.maxRingBindings do
        local layerIndex, categoryIndex, actionIndex = GetActionIndicesFromName("ESOPIE_OPEN_RING_" .. tostring(i))
        for j=1,4 do
            local keyCode, _, _, _, _ = GetActionBindingInfo(layerIndex, categoryIndex, actionIndex, j)
            if layerIndex and keyCode > 0 then
                validBindingCount = validBindingCount + 1
            end
        end
    end

    if validBindingCount == 0 then
        ESOPie_BindingWarning.data.text = L(ESOPIE_SI_SETTINGS_NOBINDINGSDETECTED)
    else
        ESOPie_BindingWarning.data.text = ""
    end
    ESOPie_BindingWarning:UpdateValue()
end

-------------------------------------------------------------------------------
-- Global Helpers

function ESOPie:ResetToDefault()
    ZO_ClearTable(self.db)
    ZO_DeepTableCopy(ESOPIE_DB_DEFAULT, self.db)
    LogDebug("Settings reset to default.")
end

function ESOPie:CleanOrphanedSlots()
    LogVerbose("Cleaning up orphaned slots")
    local rings = {}
    local slots = {}
    for index, entry in pairs(ESOPie.db.entries) do
        if ESOPie.utils.EntryIsRing(entry) then
            table.insert(rings, entry)
        elseif ESOPie.utils.EntryIsSlot(entry) then
            table.insert(slots, entry)
        else
            LogVerbose("Invalid slot type in entries at index %d", index)
        end
    end

    local orphans = {}
    for _, slot in pairs(slots) do
        local foundOwner = false
        for _, ring in pairs(rings) do
            for _, slotId in pairs(ring.slots) do
                if slotId == slot.uniqueid then foundOwner = true break end
            end
            if foundOwner then break end
        end
        if not foundOwner then
            table.insert(orphans, slot)
        end
    end

    if not ZO_IsTableEmpty(orphans) then
        for _, entry in pairs(orphans) do
            LogVerbose("> %s", entry.name)
            RemoveEntry(entry.uniqueid)
        end
        LogWarning("Cleaning up %d orphaned slots", #orphans)
    end
end
-------------------------------------------------------------------------------
-- Initialize Addon Menu and Settings DB

function ESOPie:InitializeSettings()
    LogVerbose("Loading save data %s v%d.", self.savedVars, self.savedVarsVersion)
    self.db = ZO_SavedVars:NewAccountWide(self.savedVars, self.savedVarsVersion, nil, ESOPIE_DB_DEFAULT)
    self:CleanOrphanedSlots()

    local function OnConfirmRemoveEntry()
        if ESOPie.utils.EntryIsRing(ui.currentEditing) then
            RemoveRing(ui.currentEditing.uniqueid)
            ui.currentEditing = nil
        elseif ESOPie.utils.EntryIsSlot(ui.currentEditing) then
            local owner = ESOPie.utils.FindEntryOwner(ui.currentEditing.uniqueid, ESOPie.db.entries, ESOPie.EntryType.Ring)
            RemoveSlot(ui.currentEditing.uniqueid)
            ui.currentEditing = owner
        end
        if not ui.currentEditing then
            ui.currentEditing = ESOPie.utils.FindEntryByID(ESOPie.db.rootRings[1], ESOPie.db.entries)
        end
        RebuildRingDropdowns()
        LAM.util.RequestRefreshIfNeeded(ESOPie.LAMPanel)
    end

    local function OnConfirmChangeSlotAction(value)
        ui.currentEditing.action = value
        ui.currentEditing.data = nil
        UpdateCollectionsCache()
        RebuildCollectionsDropdowns()
        LAM.util.RequestRefreshIfNeeded(ESOPie_SlotEdit_Submenu)
    end

    local function OnCollectionItemDropdownMouseEnter(control)
        if control.m_data.tooltip then
            if type(control.m_data.tooltip) == "function" then
                control.m_data.tooltip(control) -- initialize tooltip with a function
            elseif type(control.m_data.tooltip) == "string" then
                InitializeTooltip(ItemTooltip, control, TOPLEFT, 0, 0, BOTTOMRIGHT)
                SetTooltipText(ItemTooltip, control.m_data.tooltip)
                ItemTooltipTopLevel:BringWindowToTop()
            else
                ClearTooltip(ItemTooltip)
            end
        else
            ClearTooltip(ItemTooltip)
        end
    end

    local function OnCollectionItemDropdownMouseExit(control)
        ClearTooltip(ItemTooltip)
    end

    local function OnPanelCreated(panel)
        if panel ~= ESOPie.LAMPanel then return end
        LogVerbose("OnPanelCreated")

        if ESOPIE_SlotEdit_CollectionItem and ESOPIE_SlotEdit_CollectionItem.scrollHelper then
            ESOPIE_SlotEdit_CollectionItem.scrollHelper.OnMouseEnter = function(self, control) OnCollectionItemDropdownMouseEnter(control) end
            ESOPIE_SlotEdit_CollectionItem.scrollHelper.OnMouseExit = function(self, control) OnCollectionItemDropdownMouseExit(control) end
        end

        InitNextID()
        UpdateCollectionsCache()
        RebuildAll()
        ui.initialized = true
    end

    local function OnPanelOpened(panel)
        if panel ~= ESOPie.LAMPanel then return end
        LogVerbose("OnPanelOpened")
        RefreshBindingWarning()
    end

    --[[
    COLLECTIBLE_CATEGORY_TYPE_HOUSE
    ]]--

    ui.collectionPopulateCallbacks[ESOPie.Action.PlayEmote] = PopulateEmotes
    ui.collectionPopulateCallbacks[ESOPie.Action.PlayMomento] = function() PopulateCollectablesByCategory({ COLLECTIBLE_CATEGORY_TYPE_MEMENTO }, true) end
    ui.collectionPopulateCallbacks[ESOPie.Action.SetMount] = function() PopulateCollectablesBySubCategory({ COLLECTIBLE_CATEGORY_TYPE_MOUNT }, true) end
    ui.collectionPopulateCallbacks[ESOPie.Action.SetVanityPet] = function() PopulateCollectablesBySubCategory({ COLLECTIBLE_CATEGORY_TYPE_VANITY_PET }, true) end
    ui.collectionPopulateCallbacks[ESOPie.Action.SummonAlly] = function() PopulateCollectablesBySubCategory({ COLLECTIBLE_CATEGORY_TYPE_ASSISTANT, COLLECTIBLE_CATEGORY_TYPE_COMPANION }, true) end
    ui.collectionPopulateCallbacks[ESOPie.Action.SetCostume] = function() PopulateCollectablesBySubCategory({ COLLECTIBLE_CATEGORY_TYPE_COSTUME }, true) end
    ui.collectionPopulateCallbacks[ESOPie.Action.SetPolymorph] = function() PopulateCollectablesBySubCategory({ COLLECTIBLE_CATEGORY_TYPE_POLYMORPH }, true) end


    UpdateInternalCache()

    ui.currentEditing = ESOPie.utils.FindEntryByID(ESOPie.db.rootRings[1], ESOPie.db.entries)

    local optionsTable = {
        {
            type = "description",
            text = "",
            reference = "ESOPie_BindingWarning"
        },
        {
            type = "submenu",
            name = L(ESOPIE_SI_SETTINGS_GENERALMENU_NAME),
            controls = {
                {
                    type = "header",
                    name = L(ESOPIE_SI_SETTINGS_BINDINGSHEADER),
                },
                {
                    type = "dropdown",
                    reference = "ESOPIE_General_RingBinding1",
                    name = L("ESOPIE_SI_SETTINGS_RINGBINDING", 1),
                    scrollable = true,
                    choices = ui.bindingRingChoices,
                    choicesValues = ui.ringValues,
                    getFunc = function()
                        return ESOPie.db.rootRings[1]
                    end,
                    setFunc = function(value)
                        ESOPie.db.rootRings[1] = value
                    end,
                },
                {
                    type = "dropdown",
                    reference = "ESOPIE_General_RingBinding2",
                    name = L("ESOPIE_SI_SETTINGS_RINGBINDING", 2),
                    scrollable = true,
                    choices = ui.bindingRingChoices,
                    choicesValues = ui.ringValues,
                    getFunc = function()
                        return ESOPie.db.rootRings[2]
                    end,
                    setFunc = function(value)
                        ESOPie.db.rootRings[2] = value
                    end,
                },
                {
                    type = "dropdown",
                    reference = "ESOPIE_General_RingBinding3",
                    name = L("ESOPIE_SI_SETTINGS_RINGBINDING", 3),
                    scrollable = true,
                    choices = ui.bindingRingChoices,
                    choicesValues = ui.ringValues,
                    getFunc = function()
                        return ESOPie.db.rootRings[3]
                    end,
                    setFunc = function(value)
                        ESOPie.db.rootRings[3] = value
                    end,
                },
                {
                    type = "dropdown",
                    reference = "ESOPIE_General_RingBinding4",
                    name = L("ESOPIE_SI_SETTINGS_RINGBINDING", 4),
                    scrollable = true,
                    choices = ui.bindingRingChoices,
                    choicesValues = ui.ringValues,
                    getFunc = function()
                        return ESOPie.db.rootRings[4]
                    end,
                    setFunc = function(value)
                        ESOPie.db.rootRings[4] = value
                    end,
                },
                {
                    type = "dropdown",
                    reference = "ESOPIE_General_RingBinding5",
                    name = L("ESOPIE_SI_SETTINGS_RINGBINDING", 5),
                    scrollable = true,
                    choices = ui.bindingRingChoices,
                    choicesValues = ui.ringValues,
                    getFunc = function()
                        return ESOPie.db.rootRings[5]
                    end,
                    setFunc = function(value)
                        ESOPie.db.rootRings[5] = value
                    end,
                },
                {
                    type = "dropdown",
                    reference = "ESOPIE_General_RingBinding6",
                    name = L("ESOPIE_SI_SETTINGS_RINGBINDING", 6),
                    scrollable = true,
                    choices = ui.bindingRingChoices,
                    choicesValues = ui.ringValues,
                    getFunc = function()
                        return ESOPie.db.rootRings[6]
                    end,
                    setFunc = function(value)
                        ESOPie.db.rootRings[6] = value
                    end,
                },
                {
                    type = "header",
                    name = L(ESOPIE_SI_SETTINGS_CONTROLSHEADER),
                },
                {
                    type = "dropdown",
                    name = L(ESOPIE_SI_SETTINGS_KEYBOARDINTERACTMODE),
                    scrollable = true,
                    choices = { L(ESOPIE_SI_SETTINGS_INTERACTMODEHOLD), L(ESOPIE_SI_SETTINGS_INTERACTMODETOGGLE)  },
                    choicesValues = { ESOPie.InteractMode.Hold, ESOPie.InteractMode.Toggle },
                    getFunc = function() return ESOPie.db.controlOptions["keyboard"].bindingInteractMode end,
                    setFunc = function(value) ESOPie.db.controlOptions["keyboard"].bindingInteractMode = value end,
                },
                {
                    type = "dropdown",
                    name = L(ESOPIE_SI_SETTINGS_GAMEPADINTERACTMODE),
                    scrollable = true,
                    choices = { L(ESOPIE_SI_SETTINGS_INTERACTMODEHOLD), L(ESOPIE_SI_SETTINGS_INTERACTMODETOGGLE)  },
                    choicesValues = { ESOPie.InteractMode.Hold, ESOPie.InteractMode.Toggle },
                    getFunc = function() return ESOPie.db.controlOptions["gamepad"].bindingInteractMode end,
                    setFunc = function(value) ESOPie.db.controlOptions["gamepad"].bindingInteractMode = value end,
                },
            },
        },
        -----------------------------------------------------------------------
        {
            type = "header",
            name = L(ESOPIE_SI_SETTINGS_CONFIGUREHEADER_NAME),
        },
        {
            type = "button",
            name = L(ESOPIE_SI_SETTINGS_NEWRING),
            tooltip = L(ESOPIE_SI_SETTINGS_NEWRING_TT),
            width = "half",
            func = function()
                ui.currentEditing = CreateNewRing()
                RebuildAll()
            end,
        },
        {
            type = "dropdown",
            reference = "ESOPIE_Configure_Selection",
            name = L(ESOPIE_SI_SETTINGS_ENTRYSELECT),
            tooltip = L(ESOPIE_SI_SETTINGS_ENTRYSELECT_TT),
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
                ui.currentEditing = ESOPie.utils.FindEntryByID(value, ESOPie.db.entries)
                UpdateCollectionsCache()
                RebuildAll()
            end,
        },
        {
            type = "editbox",
            name = L(ESOPIE_SI_SETTINGS_ENTRYNAME),
            tooltip = L(ESOPIE_SI_SETTINGS_ENTRYNAME_TT),
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
                    ui.currentEditing.name = value
                    RebuildRingDropdowns()
                end
            end,
        },
        {
            type = "button",
            name = L(ESOPIE_SI_SETTINGS_NEWSLOT),
            tooltip = ZO_CachedStrFormat(L(ESOPIE_SI_SETTINGS_NEWSLOT_TT), ESOPie.maxVisibleSlots),
            width = "half",
            disabled = function() return not ui.currentEditing end,
            func = function()
                local ringToAddSlot = nil
                if self.utils.EntryIsRing(ui.currentEditing) then
                    ringToAddSlot = ui.currentEditing
                else
                    ringToAddSlot = self.utils.FindEntryOwner(ui.currentEditing.uniqueid, ESOPie.db.entries, ESOPie.EntryType.Ring)
                end
                if ringToAddSlot then
                    local newSlot = CreateNewSlot(ringToAddSlot)
                    ui.currentEditing = newSlot
                    RebuildRingDropdowns()
                    UpdateCollectionsCache()
                    RebuildCollectionsDropdowns()
                end
            end,
        },
        {
            type = "button",
            name = L(ESOPIE_SI_SETTINGS_REMOVE),
            tooltip = L(ESOPIE_SI_SETTINGS_REMOVE_TT),
            width = "half",
            disabled = function() return ui.currentEditing == nil end,
            func = function()
                local entryName = ui.currentEditing.name or ("Entry" .. tostring(ui.currentEditing.uniqueid))
                local confirmStr = ZO_CachedStrFormat(L(ESOPIE_SI_SETTINGS_CONFIRMREMOVE), entryName)
                if ESOPie.utils.EntryIsRing(ui.currentEditing) then
                    local slotNames = {}
                    for _, slotId in pairs(ui.currentEditing.slots) do
                        local slot = ESOPie.utils.FindEntryByID(slotId, ESOPie.db.entries, ESOPie.EntryType.Slot)
                        if slot then
                            table.insert(slotNames, ZO_CachedStrFormat(" - |c55eeff<<1>>|r", slot.name or ("Slot" .. slotId)))
                        end
                    end

                    if not ZO_IsTableEmpty(slotNames) then
                        confirmStr = table.concat({ confirmStr, "\n\n" .. L(ESOPIE_SI_SETTINGS_CONFIRMADDITIONAL) .. "\n", table.concat(slotNames, "\n") }, "")
                    end
                end
                confirmStr = table.concat({ confirmStr, "\n\n" .. L(ESOPIE_SI_SETTINGS_CONFIRMPERMANENCE) }, "")
                LibDialog:RegisterDialog(ESOPie.name, "RemoveEntryDialog", L(ESOPIE_SI_SETTINGS_CONFIRMREMOVE_TITLE), confirmStr, function() OnConfirmRemoveEntry() end, nil, nil, true)
                LibDialog:ShowDialog(ESOPie.name, "RemoveEntryDialog")
            end,
        },
         -----------------------------------------------------------------------
        {
            type = "submenu",
            name = L(ESOPIE_SI_SETTINGS_CONFIGURESLOTMENU),
            reference = "ESOPie_SlotEdit_Submenu",
            disabled = function() return not ESOPie.utils.EntryIsSlot(ui.currentEditing) end,
            controls = {
                {
                    type = "iconpicker",
                    name = L(ESOPIE_SI_SETTINGS_BROWSEICON),
                    tooltip = L(ESOPIE_SI_SETTINGS_BROWSEICON_TT),
                    reference = "ESOPIE_SlotEdit_SlotIconPicker",
                    maxColumns = 6,
                    visibleRows = 6,
                    iconSize = 64,
                    width = "full",
                    choices = ESOPIE_ICON_LIBRARY,
                    getFunc = function()
                        if ui.currentEditing then
                            if not ui.currentEditing.icon or ui.currentEditing.icon == "" then
                                return ESOPIE_ICON_SLOT_DEFAULT
                            end
                            return ui.currentEditing.icon
                        end
                        return ""
                    end,
                    setFunc = function(value)
                        if ui.currentEditing then
                            if value == ESOPIE_ICON_SLOT_DEFAULT then
                                ui.currentEditing.icon = ""
                            else
                                ui.currentEditing.icon = value
                            end
                        end
                    end,
                },
                {
                    type = "description",
                    text = ZO_HINT_TEXT:Colorize(L(ESOPIE_SI_SETTINGS_MAGICICONDESC)),
                },
                {
                    type = "editbox",
                    name = L(ESOPIE_SI_SETTINGS_ICONPATH),
                    tooltip = L(ESOPIE_SI_SETTINGS_ICONPATH_TT),
                    isMultiline = false,
                    getFunc = function()
                        if ui.currentEditing then
                            return ui.currentEditing.icon
                        end
                        return ""
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
                    reference = "ESOPIE_SlotEdit_Action",
                    name = L(ESOPIE_SI_SETTINGS_SLOTACTION),
                    tooltip = L(ESOPIE_SI_SETTINGS_SLOTACTION_TT),
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
                                local currentActionName = ESOPie.utils.GetActionTypeString(ui.currentEditing.action)
                                local newActionName = ESOPie.utils.GetActionTypeString(value)
                                local confirmStr = ZO_CachedStrFormat(L(ESOPIE_SI_SETTINGS_CONFIRMCHANGEACTION), entryName, newActionName, currentActionName)
                                LibDialog:RegisterDialog(ESOPie.name, "ChangeActionTypeDialog", L(ESOPIE_SI_SETTINGS_CONFIRMCHANGEACTION_TITLE), confirmStr, function() OnConfirmChangeSlotAction(value) end, nil, nil, true)
                                LibDialog:ShowDialog(ESOPie.name, "ChangeActionTypeDialog")
                            else
                                OnConfirmChangeSlotAction(value)
                            end
                        end
                    end,
                },
                {
                    type = "submenu",
                    name = L(ESOPIE_SI_SETTINGS_SUBRINGMENU),
                    disabled = function() return not ESOPie.utils.IsSubringAction(ui.currentEditing) end,
                    controls = {
                        {
                            type = "dropdown",
                            reference = "ESOPIE_SlotEdit_Subring",
                            name = L(ESOPIE_SI_SETTINGS_SUBRING),
                            tooltip = L(ESOPIE_SI_SETTINGS_SUBRING_TT),
                            sort = "name-up",
                            scrollable = true,
                            choices = ui.bindingRingChoices,
                            choicesValues = ui.bindingRingChoices,
                            getFunc = function()
                                if ESOPie.utils.IsSubringAction(ui.currentEditing) then
                                    return ui.currentEditing.data
                                else
                                    return 0
                                end
                            end,
                            setFunc = function(value)
                                if ESOPie.utils.IsSubringAction(ui.currentEditing) then
                                    ui.currentEditing.data = value
                                end
                            end,
                        },
                    },
                },
                {
                    type = "submenu",
                    name = L(ESOPIE_SI_SETTINGS_COLLECTIONMENU),
                    disabled = function() return not ESOPie.utils.IsCollectableAction(ui.currentEditing) end,
                    controls = {
                        {
                            type = "dropdown",
                            reference = "ESOPIE_SlotEdit_CollectionCategory",
                            name = L(ESOPIE_SI_SETTINGS_COLLECTIONCATEGORY),
                            tooltip = L(ESOPIE_SI_SETTINGS_COLLECTIONCATEGORY_TT),
                            sort = "name-up",
                            scrollable = true,
                            choices = {},
                            choicesValues = {},
                            disabled = function() return not (ESOPie.utils.IsCollectableAction(ui.currentEditing) and ESOPie.utils.CollectionHasCategory(ui.currentEditing)) end,
                            getFunc = function()
                                if ESOPie.utils.IsCollectableAction(ui.currentEditing) then
                                    return ui.selectedCollectionCategory
                                end
                                return 0
                            end,
                            setFunc = function(value)
                                if ESOPie.utils.IsCollectableAction(ui.currentEditing) then
                                    ui.selectedCollectionCategory = value
                                    RebuildCollectionsDropdowns()
                                end
                            end,
                        },
                        {
                            type = "dropdown",
                            reference = "ESOPIE_SlotEdit_CollectionItem",
                            name = L(ESOPIE_SI_SETTINGS_COLLECTIBLE),
                            tooltip = L(ESOPIE_SI_SETTINGS_COLLECTIBLE_TT),
                            sort = "name-up",
                            scrollable = true,
                            choices = {},
                            choicesValues = {},
                            getFunc = function()
                                if ESOPie.utils.IsCollectableAction(ui.currentEditing) and type(ui.currentEditing.data) == "number" then
                                    return ui.currentEditing.data
                                else
                                    return 0
                                end
                            end,
                            setFunc = function(value)
                                if ESOPie.utils.IsCollectableAction(ui.currentEditing) then
                                    ui.currentEditing.data = value
                                    --ui.currentEditing.icon = GetCollectibleIcon(value)
                                end
                            end,
                        },
                    },
                },
                {
                    type = "submenu",
                    name = L(ESOPIE_SI_SETTINGS_COMMANDMENU),
                    disabled = function() return not ESOPie.utils.IsCommandAction(ui.currentEditing) end,
                    controls = {
                        {
                            type = "editbox",
                            name = L(ESOPIE_SI_SETTINGS_COMMAND),
                            tooltip = L(ESOPIE_SI_SETTINGS_COMMAND_TT),
                            isMultiline = true,
                            getFunc = function()
                                if ESOPie.utils.IsCommandAction(ui.currentEditing) and type(ui.currentEditing.data) == "string" then
                                    return ui.currentEditing.data
                                else
                                    return ""
                                end
                            end,
                            setFunc = function(value)
                                if ESOPie.utils.IsCommandAction(ui.currentEditing) then
                                    ui.currentEditing.data = value
                                end
                            end,
                        },
                    }
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
        website = ESOPie.url,
        -- feedback = "",
        -- donation = "",
    }

    ESOPie.LAMPanel = LAM:RegisterAddonPanel(ESOPie.settingsPanelName, panelData)
    LAM:RegisterOptionControls(ESOPie.settingsPanelName, optionsTable)

    CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated", OnPanelCreated)
    --CALLBACK_MANAGER:RegisterCallback("LAM-RefreshPanel", OnPanelRefreshed)
    CALLBACK_MANAGER:RegisterCallback("LAM-PanelOpened", OnPanelOpened)
    --CALLBACK_MANAGER:RegisterCallback("LAM-PanelClosed", MyLAMPanelClosed)
end

-- ZO_NORMAL_TEXT
-- ZO_SELECTED_TEXT
-- ZO_CONTRAST_TEXT
-- ZO_SECOND_CONTRAST_TEXT
-- ZO_HIGHLIGHT_TEXT
-- ZO_HINT_TEXT
-- ZO_SUCCEEDED_TEXT