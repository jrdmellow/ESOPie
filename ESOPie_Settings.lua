if not ESOPie then d("[ESOPIE] ERROR: ESOPie not initialized.") return end

local L = GetString
local LAM = LibAddonMenu2

function ESOPie:InitializeSettings()

    local ESOPIE_DEFAULT_SLOTINFO = {
        name = L(ESOPIE_DEFAULT_ACTIONNAME),
        icon = ESOPIE_ICON_SLOT_DEFUALT,
        action = ESOPIE_ACTION_NOOP,
        data = {}
    }

    local ESOPIE_DB_DEFAULT = {
        rings = {
            [1] = {
                name = L(ESOPIE_DEFAULT_ROOTNAME),
                slots = {
                    {
                        name = L(ESOPIE_DEFAULT_SOCIALRING),
                        icon = "",
                        action = ESOPIE_ACTION_SUBMENU,
                        data = 2,
                    },
                    {
                        name = L(ESOPIE_DEFAULT_OPENEMOTES),
                        icon = "",
                        action = ESOPIE_ACTION_OPENEMOTEWHEEL,
                        data = nil,
                    }
                }
            },
            [2] = {
                name = L(ESOPIE_DEFAULT_SOCIALRING),
                slots = {
                    {
                        name = L(ESOPIE_DEFAULT_WAVEACTION),
                        icon = "",
                        action = ESOPIE_ACTION_CHATEXEC,
                        data = "/wave",
                    },
                    {
                        name = L(ESOPIE_DEFAULT_SAYHELLO),
                        icon = "",
                        action = ESOPIE_ACTION_CHATEXEC,
                        data = "/s " .. L(ESOPIE_DEFAULT_CHATHELLO),
                    },
                }
            },
        },
        rootRing = 1,
    }

    local panelName = "ESOPieSettingsPanel"

    local panelData = {
        type = "panel",
        name = L(ESOPIE_SETTINGS_PANEL_NAME),
        author = ESOPie.author,
    }

    local optionsTable = {
        {
            type = "submenu",
            name =  L(ESOPIE_SETTINGS_RINGS_HEADER),
            tooltip =  L(ESOPIE_SETTINGS_RINGS_TOOLTIP),
            controls = {
                --[[{-- Config Import From
                    type = "dropdown",
                    name = GetString(ESOPIE_SETTINGS_RING_SELECTION),
                    tooltip = GetString(ESOPIE_SETTINGS_RING_SELECTION_TOOLTIP),
                    choices = ESOPie.chatConfSyncChoices,
                    choicesValues = pChatData.chatConfSyncChoicesCharIds,
                    sort = "name-up",
                    scrollable = true,
                    width = "full",
                    getFunc = function() return GetCurrentCharacterId() end,
                    setFunc = function(p_charId)
                        pChat.SyncChatConfig(true, p_charId)
                    end,
                },]]--
            },
            reference = "ESOPieRingsSubMenu"
        },
        {
            type = "submenu",
            name =  L(ESOPIE_SETTINGS_SLOTS_HEADER),
            tooltip =  L(ESOPIE_SETTINGS_SLOTS_TOOLTIP),
            controls = {},
            reference = "ESOPieSlotsSubMenu"
        }
    }

    LAM:RegisterAddonPanel(panelName, panelData)
    LAM:RegisterOptionControls(panelName, optionsTable)

    ESOPie.db = ZO_SavedVars:NewAccountWide(ESOPie.savedVars, ESOPie.savedVarsVersion, nil, ESOPIE_DB_DEFAULT)
end