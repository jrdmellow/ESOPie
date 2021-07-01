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
    ESOPIE_ACTION_PLAYEMOTE                     = "Do Emote",
    ESOPIE_ACTION_PLAYMOMENTO                   = "Use Momento",
    ESOPIE_ACTION_SUMMONALLY                    = "Summon Ally",
    ESOPIE_ACTION_SETMOUNT                      = "Change Mount",
    ESOPIE_ACTION_SETNCPET                      = "Change Non-Combat Pet",
    ESOPIE_ACTION_SETCOSTUME                    = "Change Costume",
    ESOPIE_ACTION_SETPOLYMORPH                  = "Change Polymorph",

    -- Bindings
    ESOPIE_BINDING_INTERACTIONLAYER             = "ESOPie",
    ESOPIE_BINDING_CATEGORY_MENU                = "ESOPie (While Showing)",
    SI_BINDING_NAME_ESOPIE_OPEN_RING_1          = "Open Ring 1 (Hold)",
    SI_BINDING_NAME_ESOPIE_OPEN_RING_2          = "Open Ring 2 (Hold)",
    SI_BINDING_NAME_ESOPIE_OPEN_RING_3          = "Open Ring 3 (Hold)",
    SI_BINDING_NAME_ESOPIE_OPEN_RING_4          = "Open Ring 4 (Hold)",
    SI_BINDING_NAME_ESOPIE_OPEN_RING_5          = "Open Ring 5 (Hold)",
    SI_BINDING_NAME_ESOPIE_OPEN_RING_6          = "Open Ring 6 (Hold)",
    SI_BINDING_NAME_ESOPIE_MENU_ACTIVATE_SLOT   = "Navigate to Slot",
}

for stringId, stringValue in pairs(strings) do
    ZO_CreateStringId(stringId, stringValue)
    SafeAddVersion(stringId, 1)
end