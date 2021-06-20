local strings = {
    -- General
    SI_ESOPIE_TITLE = "ESOPie",
    ESOPIE_TITLE = "ESOPie",
    ESOPIE_BYLINE = "<<1>> <<2>> created by <<3>>.",

    -- Settings
    ESOPIE_DEFAULT_RINGNAME                     = "New Ring",
    ESOPIE_DEFAULT_ACTIONNAME                   = "New Slot",
    ESOPIE_DEFAULT_ROOTNAME                     = "Root",
    ESOPIE_DEFAULT_SOCIALRING                   = "Social",
    ESOPIE_DEFAULT_WAVEACTION                   = "Wave",
    ESOPIE_DEFAULT_OPENEMOTES                   = "Emotes",

    -- Settings UI
    ESOPIE_SETTINGS_PANEL_NAME                  = "ESOPie",

    -- Actions
    ESOPIE_ACTION_NOOP                          = "No Action",
    ESOPIE_ACTION_SUBRING                       = "Open Subring",
    ESOPIE_ACTION_CHATEXEC                      = "Execute Chat Command",
    ESOPIE_ACTION_CODEEXEC                      = "Execute Lua Code",
    ESOPIE_ACTION_GOTOHOME                      = "Go Home",
    ESOPIE_ACTION_PLAYEMOTE                     = "Play Emote",
    ESOPIE_ACTION_PLAYMOMENTO                   = "Play Momento",
    ESOPIE_ACTION_SUMMONALLY                    = "Summon Ally",
    ESOPIE_ACTION_SETMOUNT                      = "Change Mount",
    ESOPIE_ACTION_SETNCPET                      = "Change Non-Combat Pet",

    -- Bindings
    ESOPIE_BINDING_INTERACTIONLAYER             = "ESOPie",
    ESOPIE_BINDING_CATEGORY_MENU                = "ESOPie (While Showing)",
    SI_BINDING_NAME_ESOPIE_HOLD_ITERACTION      = "Open ESOPie (Hold)",
    SI_BINDING_NAME_ESOPIE_MENU_ACTIVATE_SLOT   = "Navigate to Slot",
}

for stringId, stringValue in pairs(strings) do
    ZO_CreateStringId(stringId, stringValue)
    SafeAddVersion(stringId, 1)
end