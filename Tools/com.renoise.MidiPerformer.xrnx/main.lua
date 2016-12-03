--[[============================================================================
com.renoise.MidiPerformer.xrnx/main.lua
============================================================================]]--
--[[

A tool for quick & easy configuration of MIDI inputs 
.
#
]]

--------------------------------------------------------------------------------
-- Required files
--------------------------------------------------------------------------------

rns = nil
_trace_filters = nil
--_trace_filters = {"^MidiPerformer"}

_clibroot = 'source/cLib/classes/'
_vlibroot = 'source/vLib/classes/'
_xlibroot = 'source/xLib/classes/'

require (_clibroot..'cLib')
require (_clibroot..'cDebug')
require (_clibroot..'cObservable')

require (_vlibroot..'vLib')
require (_vlibroot..'vDialog')
require (_vlibroot..'vTable')

require (_xlibroot..'xTrack')
require (_xlibroot..'xNoteColumn')
require (_xlibroot..'xInstrument')

require ('source/MidiPerformer')
require ('source/MP_UI')
require ('source/MP_Instrument')
require ('source/MP_Prefs')
require ('source/MP_HelpDlg')
require ('source/MP_OptionsDlg')

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------


local app
local prefs = MP_Prefs()
renoise.tool().preferences = prefs

APP_DISPLAY_NAME = "MidiPerformer"

--------------------------------------------------------------------------------
-- Menu entries & MIDI/Key mappings
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:"..APP_DISPLAY_NAME.."...",
  invoke = function() 
    show() 
  end
} 
renoise.tool():add_keybinding {
  name = "Global:"..APP_DISPLAY_NAME..":Show dialog...",
  invoke = function(repeated)
    if (not repeated) then 
      show() 
    end
  end
}

--------------------------------------------------------------------------------

function start()
  rns = renoise.song()
  if not app then
    app = MidiPerformer{
      app_display_name = APP_DISPLAY_NAME,
    }
  end
end

--------------------------------------------------------------------------------

function show()
  if not app then
    start()
  end
  app.ui:show()
end

--------------------------------------------------------------------------------
-- notifications
--------------------------------------------------------------------------------

renoise.tool().app_new_document_observable:add_notifier(function()
  if prefs.autostart.value then
    start()
  end

end)
