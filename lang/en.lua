local strings = {
    -- General
    SI_ESOPIE_TITLE = "ESOPie",
    ESOPIE_TITLE = "ESOPie",
    ESOPIE_BYLINE = "<<1>> <<2>> created by <<3>>.",

    -- Settings
    ESOPIE_DEFAULT_RINGNAME                     = "MyRing",
    ESOPIE_DEFAULT_ACTIONNAME                   = "Action",
    ESOPIE_DEFAULT_ROOTNAME                     = "Root Ring",
    ESOPIE_DEFAULT_SOCIALRING                   = "Social Ring",
    ESOPIE_DEFAULT_WAVEACTION                   = "Wave",
    ESOPIE_DEFAULT_SAYHELLO                     = "Say Hello",
    ESOPIE_DEFAULT_CHATHELLO                    = "Hello!",
    ESOPIE_DEFAULT_OPENEMOTES                   = "Emotes",

    -- Settings UI
    ESOPIE_SETTINGS_PANEL_NAME                  = "ESOPie",

    -- Actions
    ESOPIE_ACTION_NOOP                          = "No Action",
    ESOPIE_ACTION_SUBRING                       = "Open Subring",
    ESOPIE_ACTION_CHATEXEC                      = "Execute Chat Command",
    ESOPIE_ACTION_CODEEXEC                      = "Execute Code",
    ESOPIE_ACTION_GOTOHOME                      = "Go Home",
    ESOPIE_ACTION_PLAYEMOTE                     = "Play Emote",

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