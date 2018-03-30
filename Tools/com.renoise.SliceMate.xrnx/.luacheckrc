-- define a set of Renoise API-specific globals for the luacheck linter

std = {
  -- these globals can be set and accessed.
  globals = {
    -- lua standard
    "require",
    -- Luabind
    "class",
    -- Renoise API
    "renoise",
    -- Renoise API (lua standard+)
    "table",
    -- related to libraries
    "_clibroot",
    "_vlibroot",
    "_xlibroot",
    "LOG",
    "TRACE",
    "rns",
    "_trace_filters",
    -- libraries
    "cLib",
    "cReflection",
    "vLib",
    "xLib",
    "xLinePattern",
    "xSongPos",
    "xSample",
    "xNoteCapture",
    "xInstrument",
    "xColumns",
    "xCursorPos",
    "xEffectColumn",
    "xPhrase",
    -- specific to this workspace:
    -- classes
    "SliceMate",
    "SliceMate_Prefs",
    "SliceMate_UI",
    -- variables
    "APP_DISPLAY_NAME",
  },
  -- these globals can only be accessed.
  read_globals = {}
}

