--[[============================================================================
com.renoise.xStream.xrnx (main.lua)
============================================================================]]--
--[[

  Create an instance of xStream

]]

--------------------------------------------------------------------------------
-- required files
--------------------------------------------------------------------------------

_trace_filters = nil
--_trace_filters = {".*"}
--_trace_filters = {"^vDialog"}

_clibroot = 'source/cLib/classes/'
require (_clibroot..'cLib')
require (_clibroot..'cDebug')
require (_clibroot..'cDocument')
require (_clibroot..'cFilesystem')
require (_clibroot..'cObservable')
require (_clibroot..'cReflection')
require (_clibroot..'cParseXML')
require (_clibroot..'cSandbox')

_vlibroot = 'source/vLib/classes/'
require (_vlibroot..'vLib')
require (_vlibroot..'vDialog')
require (_vlibroot..'vDialogWizard')
require (_vlibroot..'vPrompt')
require (_vlibroot..'vTable')
require (_vlibroot..'helpers/vColor')

_xlibroot = 'source/xLib/classes/'
require (_xlibroot..'xLib')
require (_xlibroot..'xAudioDevice')
require (_xlibroot..'xAutomation')
require (_xlibroot..'xBlockLoop')
require (_xlibroot..'xEffectColumn')
require (_xlibroot..'xLine')
require (_xlibroot..'xLineAutomation')
require (_xlibroot..'xLinePattern')
require (_xlibroot..'xMessage')
require (_xlibroot..'xMidiIO')
require (_xlibroot..'xMidiInput')
require (_xlibroot..'xMidiMessage')
require (_xlibroot..'xNoteColumn')
require (_xlibroot..'xOscClient')
require (_xlibroot..'xOscDevice')
require (_xlibroot..'xPhraseManager')
require (_xlibroot..'xPlayPos')
require (_xlibroot..'xScale')
require (_xlibroot..'xSongPos')
require (_xlibroot..'xStreamPos')
require (_xlibroot..'xVoiceManager')

require ('source/xStream')
require ('source/xStreamArg')
require ('source/xStreamArgs')
require ('source/xStreamArgsTab')
require ('source/xStreamBuffer')
require ('source/xStreamFavorite')
require ('source/xStreamFavorites')
require ('source/xStreamModel')
require ('source/xStreamPresets')
require ('source/xStreamPrefs')
require ('source/xStreamUI')
require ('source/xStreamUIModelCreate')
require ('source/xStreamUICallbackCreate')
require ('source/xStreamUIOptions')
require ('source/xStreamUIFavorites')
require ('source/xStreamUIPresetPanel')
require ('source/xStreamUIArgsPanel')
require ('source/xStreamUIArgsEditor')

require ('source/LFO')

--------------------------------------------------------------------------------

local xstream
local prefs = xStreamPrefs()
renoise.tool().preferences = prefs

rns = nil 

local TOOL_NAME = "xStream"
local MIDI_PREFIX = "Tools:"..TOOL_NAME..":"

-- force all dialogs to have this name
vDialog.DEFAULT_DIALOG_TITLE = "xStream"

--------------------------------------------------------------------------------
-- tool menu entry

function register_tool_menu()

  local str_name = "Main Menu:Tools:"..TOOL_NAME
  local str_name_active = "Main Menu:Tools:"..TOOL_NAME.." (active)"

  if renoise.tool():has_menu_entry(str_name) then
    renoise.tool():remove_menu_entry(str_name)
  elseif renoise.tool():has_menu_entry(str_name_active) then
    renoise.tool():remove_menu_entry(str_name_active)
  end

  if xstream then
    str_name = (xstream.active) and str_name_active or str_name
  end

  renoise.tool():add_menu_entry{
    name = str_name,
    invoke = function() 
      show() 
    end
  }
end

register_tool_menu()

-------------------------------------------------------------------------------
-- invoked by menu entries, autostart - 
-- first time around, the UI/class instances are created 

function show()

  rns = renoise.song()

  -- initialize classes (once)

  if not xstream then
    xstream = xStream{
      midi_prefix = MIDI_PREFIX,
    }
    xstream.active_observable:add_notifier(function()
      TRACE("*** main.lua - self.active_observable fired...")
      register_tool_menu()
    end)

  end

  xstream.ui:show()

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

--------------------------------------------------------------------------------
-- keyboard/midi mappings

for i = 1,128 do
  local midi_mapping = MIDI_PREFIX..
    ("Favorites:Favorite #%.2d [Trigger]"):format(i)
  renoise.tool():add_midi_mapping{
    name = midi_mapping,
    invoke = function() 
      if xstream then
        xstream.favorites:trigger(i)
      end
    end
  }
  local key_mapping = "Global:"..TOOL_NAME..":"..
    ("Favorite #%.2d [Trigger]"):format(i)
  renoise.tool():add_keybinding{
    name = key_mapping,
    invoke = function(repeated) 
      if not repeated then
        if xstream then
          xstream.favorites:trigger(i)
        end
      end
    end
  }
end
