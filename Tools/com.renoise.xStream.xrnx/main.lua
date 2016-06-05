--[[============================================================================
com.renoise.xStream.xrnx (main.lua)
============================================================================]]--
--[[

  Create an instance of xStream

]]

--------------------------------------------------------------------------------
-- required files
--------------------------------------------------------------------------------

local app_dir = 'source/'
_xlibroot = 'source/xLib/classes/'
_vlibroot = 'source/vLib/classes/'
_trace_filters = nil
--_trace_filters = {".*"}
--_trace_filters = {"^xVoiceManager"}


require (_vlibroot..'vLib')
require (_vlibroot..'vPrompt')
require (_vlibroot..'vDialog')
require (_vlibroot..'vDialogWizard')
require (_vlibroot..'vTable')
require (_vlibroot..'helpers/vColor')

require (_xlibroot..'xLib')
require (_xlibroot..'xDebug')
require (_xlibroot..'xAudioDevice')
require (_xlibroot..'xBlockLoop')
require (_xlibroot..'xEffectColumn')
require (_xlibroot..'xFilesystem')
require (_xlibroot..'xLine')
require (_xlibroot..'xLineAutomation')
require (_xlibroot..'xLinePattern')
require (_xlibroot..'xNoteColumn')
require (_xlibroot..'xMidiInput')
require (_xlibroot..'xMidiIO')
require (_xlibroot..'xMessage')
require (_xlibroot..'xMidiMessage')
require (_xlibroot..'xParseXML')
require (_xlibroot..'xObservable')
require (_xlibroot..'xPhraseManager')
require (_xlibroot..'xReflection')
require (_xlibroot..'xSandbox')
require (_xlibroot..'xScale')
require (_xlibroot..'xSongPos')
require (_xlibroot..'xVoiceManager')
require (_xlibroot..'xPlayPos')
require (_xlibroot..'xStreamPos')

require (app_dir..'xStream')
require (app_dir..'xStreamArg')
require (app_dir..'xStreamArgs')
require (app_dir..'xStreamArgsTab')
require (app_dir..'xStreamFavorite')
require (app_dir..'xStreamFavorites')
require (app_dir..'xStreamModel')
require (app_dir..'xStreamPresets')
require (app_dir..'xStreamPrefs')
require (app_dir..'xStreamUI')
require (app_dir..'xStreamUIModelCreate')
require (app_dir..'xStreamUICallbackCreate')
require (app_dir..'xStreamUIOptions')
require (app_dir..'xStreamUIFavorites')
require (app_dir..'xStreamUIPresetPanel')
require (app_dir..'xStreamUIArgsPanel')
require (app_dir..'xStreamUIArgsEditor')

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
      waiting_to_show_dialog = true
    }
    xstream.ui.on_idle_notifier = function()
      xstream:on_idle()
    end

    xstream.active_observable:add_notifier(function()
      TRACE("*** main.lua - self.active_observable fired...")
      register_tool_menu()
    end)

  end

  xstream.ui:show()

end

--------------------------------------------------------------------------------

renoise.tool().app_release_document_observable:add_notifier(function()
  TRACE("*** app_release_document_observable fired...")
  rns = renoise.song()
  if xstream then
    xstream:stop()
  end
end)

--------------------------------------------------------------------------------

renoise.tool().app_new_document_observable:add_notifier(function()
  TRACE("*** app_new_document_observable fired...")

  rns = renoise.song()

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
