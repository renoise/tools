--[[============================================================================
main.lua
============================================================================]]--

_trace_filters = nil
--_trace_filters = {".*"}


--------------------------------------------------------------------------------
-- includes
--------------------------------------------------------------------------------

_xlibroot = "source/xLib/classes/"
require (_xlibroot.."xLib")
require (_xlibroot.."xDebug")
require (_xlibroot.."xReflection")
require (_xlibroot.."xPhrase")
require (_xlibroot.."xSample")
require (_xlibroot.."xSampleMapping")
require (_xlibroot.."xNoteColumn")
require (_xlibroot.."xInstrument")
require (_xlibroot.."xAudioDevice")


_vlibroot = "source/vLib/classes/"
require (_vlibroot.."vLib")
require (_vlibroot.."helpers/vString")
require (_vlibroot.."vTable")
require (_vlibroot.."vTabs")

require ("source/ProcessSlicer")
require ("source/xCleaner")
require ("source/xCleanerUI")

--------------------------------------------------------------------------------
-- preferences
--------------------------------------------------------------------------------

options = renoise.Document.create("ScriptingToolPreferences"){}
options:add_property("samplename",renoise.Document.ObservableNumber(xCleaner.SAMPLENAME.SHORTEN))
options:add_property("samplename_add_velocity",renoise.Document.ObservableBoolean(true))
options:add_property("samplename_add_note",renoise.Document.ObservableBoolean(true))
options:add_property("check_unreferenced",renoise.Document.ObservableBoolean(true))
options:add_property("find_issues",renoise.Document.ObservableBoolean(true))
options:add_property("skip_empty_samples",renoise.Document.ObservableBoolean(true))

renoise.tool().preferences = options


--------------------------------------------------------------------------------
-- main
--------------------------------------------------------------------------------

--local ntrap_preferences = NTrapPrefs()
--renoise.tool().preferences = ntrap_preferences
--ntrap:retrieve_settings(ntrap_preferences)

-- workaround for http://goo.gl/UnSDnw
local waiting_to_show_dialog = false

local x = nil

local function show_dialog()

  if not x then
    x = xCleaner()
  end

  x:show()
  x:gather()

end

--------------------------------------------------------------------------------
-- menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry{
  name = "Instrument Box:xCleaner...",
  invoke = function() 
    show_dialog() 
  end
}

--------------------------------------------------------------------------------
-- keybindings
--------------------------------------------------------------------------------

renoise.tool():add_keybinding{
  name = "Global:Tools:xCleaner...",
  invoke = function() 
    show_dialog() 
  end
}


--------------------------------------------------------------------------------
-- notifications
--------------------------------------------------------------------------------

renoise.tool().app_new_document_observable:add_notifier(function()
  if x then
    x:attach_to_song()
  end
end)

renoise.tool().app_became_active_observable:add_notifier(function()

end)

renoise.tool().app_idle_observable:add_notifier(function()
  --TRACE("main:app_idle_observable fired...")
  if (waiting_to_show_dialog) then
    waiting_to_show_dialog = false
    show_dialog() 
  end
  if x then
    x:on_idle()
  end

end)



--------------------------------------------------------------------------------
-- debug
--------------------------------------------------------------------------------

--_AUTO_RELOAD_DEBUG = function()
--show_dialog()
--end
