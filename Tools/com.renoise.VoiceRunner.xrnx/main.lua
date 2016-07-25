--[[============================================================================
com.renoise.VoiceRunner.xrnx/main.lua
============================================================================]]--
--[[

A tool for sorting notes in pattern-tracks 

.
#


]]

--------------------------------------------------------------------------------
-- Required files
--------------------------------------------------------------------------------

rns = nil
_xlibroot = 'source/xLib/classes/'
_vlibroot = 'source/vLib/classes/'
--_trace_filters = nil
_trace_filters = {".*"}

require (_vlibroot..'vLib')
require (_vlibroot..'vDialog')

require (_xlibroot..'xLib')
require (_xlibroot..'xDebug')
require (_xlibroot..'xEffectColumn') 
require (_xlibroot..'xFilesystem')
require (_xlibroot..'xInstrument')
require (_xlibroot..'xLinePattern')
require (_xlibroot..'xMidiCommand')
require (_xlibroot..'xNoteColumn') 
require (_xlibroot..'xSelection')
require (_xlibroot..'xVoiceRunner') 
require (_xlibroot..'xVoiceSorter') 

require ('source/VR')
require ('source/VR_UI')
require ('source/VR_Prefs')
require ('source/VR_Template')
require ('source/ProcessSlicer')

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local voicerunner
local prefs = VR_Prefs()
renoise.tool().preferences = prefs

APP_DISPLAY_NAME = "VoiceRunner"

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
  name = "Global:"..APP_DISPLAY_NAME..":Show preferences...",
  invoke = function(repeated)
    if (not repeated) then 
      show() 
    end
  end
}
renoise.tool():add_keybinding {
  name = "Pattern Editor:Selection:Select voice-run ("..APP_DISPLAY_NAME..")",
  invoke = function(repeated)
    if (not repeated) then 
      voicerunner:select_voice_run() 
    end
  end
}
--------------------------------------------------------------------------------
-- invoked by menu entries, autostart - 
-- first time around, the UI/class instances are created 

function show()

  rns = renoise.song()
  if not voicerunner then
    voicerunner = VR{
      app_display_name = APP_DISPLAY_NAME,
    }
  end

  voicerunner.ui:show()

end


--------------------------------------------------------------------------------
-- notifications
--------------------------------------------------------------------------------

renoise.tool().app_new_document_observable:add_notifier(function()
  TRACE("*** app_new_document_observable fired...")

  if prefs.autostart.value then
    show()
  end

end)
