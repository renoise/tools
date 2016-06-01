--[[============================================================================
com.renoise.xStream.xrnx (main.lua)
============================================================================]]--
--[[

  Create an instance of xStream, add options and manage preferences. 

]]

--------------------------------------------------------------------------------
-- required files
--------------------------------------------------------------------------------

local app_dir = 'source/'
_vlibroot = 'source/vLib/classes/'
local xlib_root = 'source/xLib/classes/'
_trace_filters = nil
--_trace_filters = {".*"}
--_trace_filters = {"^xStreamUIFavorites"}


require (_vlibroot..'vLib')
require (_vlibroot..'vPrompt')
require (_vlibroot..'vDialog')
require (_vlibroot..'vDialogWizard')
require (_vlibroot..'vTable')
require (_vlibroot..'helpers/vColor')

require (xlib_root..'xLib')
require (xlib_root..'xDebug')
require (xlib_root..'xAudioDevice')
require (xlib_root..'xBlockLoop')
require (xlib_root..'xEffectColumn')
require (xlib_root..'xFilesystem')
require (xlib_root..'xLine')
require (xlib_root..'xLineAutomation')
require (xlib_root..'xLinePattern')
require (xlib_root..'xNoteColumn')
require (xlib_root..'xMidiInput')
require (xlib_root..'xMessage')
require (xlib_root..'xMidiMessage')
require (xlib_root..'xParseXML')
require (xlib_root..'xObservable')
require (xlib_root..'xPhraseManager')
require (xlib_root..'xReflection')
require (xlib_root..'xSandbox')
require (xlib_root..'xScale')
require (xlib_root..'xSongPos')
require (xlib_root..'xVoiceManager')
require (xlib_root..'xPlayPos')
require (xlib_root..'xStreamPos')

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
require (app_dir..'xStreamUIOptions')
require (app_dir..'xStreamUIFavorites')
require (app_dir..'xStreamUIPresetPanel')
require (app_dir..'xStreamUIArgsPanel')
require (app_dir..'xStreamUIArgsEditor')

--------------------------------------------------------------------------------

local prefs = xStreamPrefs()

--[[
local xprefs = xPreferences{
  tool_name = "xStream",
  doc_class_name = "xStreamPrefs",
}
]]

renoise.tool().preferences = prefs

rns = nil 

local TOOL_NAME = "xStream"
local MIDI_PREFIX = "Tools:"..TOOL_NAME..":"
local xpos,xstream

local vb = renoise.ViewBuilder()
local dialog,dialog_content

local waiting_to_show_dialog = prefs.autostart.value
local cached_active 

-------------------------------------------------------------------------------
-- @return boolean, true if we should suspend

function dialog_is_suspended()
  return (xstream.suspend_when_hidden) and
    dialog and not dialog.visible
end

-------------------------------------------------------------------------------
-- wait with launch until tool has a renoise document to work on
-- workaround for http://goo.gl/UnSDnw

local function idle_notifier()
  if waiting_to_show_dialog then
    waiting_to_show_dialog = false
    show() -- will change to idle_notifier_actual 
  end
end
renoise.tool().app_idle_observable:add_notifier(idle_notifier)

-------------------------------------------------------------------------------
-- post-launch notifier, providing some statistics and checking 
-- if the xStream dialog has been hidden, should suspend...

local function idle_notifier_actual()
  --TRACE("*** idle_notifier_actual fired...")
  
  local is_suspended = dialog_is_suspended()
  if is_suspended then
    cached_active = xstream.active
    xstream.active = false
    return
  elseif cached_active then
    xstream.active = cached_active
  end


end

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

  -- app_new_document_observable is not called when script 
  -- is launched the first time after being installed 
  rns = renoise.song()

  if waiting_to_show_dialog then
    return
  end

  -- initialize classes (once)

  if not xstream then
    xpos = xSongPos(rns.transport.edit_pos)
    xstream = xStream()
    xstream.ui = xStreamUI(xstream,vb,MIDI_PREFIX)
    xstream:load_models(prefs.user_folder.value..xStream.MODELS_FOLDER)
    prefs:apply(xstream)
  end

  if dialog and dialog.visible then    
    -- bring to front
    dialog:show() 
  else
    -- create, or re-create if hidden
    if not dialog_content then
      dialog_content = vb:column{
        xstream.ui.vb_content,
      }

      -- initialize -----------------------

      xstream:select_launch_model()
      xstream.favorites:import("./favorites.xml")
      xstream.autosave_enabled = true

    end

    local keyhandler = function (dialog,key)
      TRACE("xStreamUI:keyhandler(dialog,key)",dialog,key)
      --rprint(key)
      local handled = false
      if (key.modifiers=="") and 
        not key.repeated
      then
        if (key.name == "tab") then
          xstream.ui.show_editor = not xstream.ui.show_editor
          handled = true
        elseif (key.name == "space") then
          xstream:start_and_play()
          handled = true
        elseif (key.name == "'") then
          xstream.muted = not xstream.muted
          handled = true
        elseif (key.name == "esc") then
          rns.transport.edit_mode = not rns.transport.edit_mode
          handled = true
        end 
      end
      if not handled then
        return key
      end
    end

    dialog = renoise.app():show_custom_dialog(
      TOOL_NAME, dialog_content, keyhandler)

    -- idle notifier: remove pre-launch, switch to actual one
    local idle_obs = renoise.tool().app_idle_observable
    if idle_obs:has_notifier(idle_notifier) then
      idle_obs:remove_notifier(idle_notifier)
    end
    if idle_obs:has_notifier(idle_notifier_actual) then
      idle_obs:remove_notifier(idle_notifier_actual)
    end
    idle_obs:add_notifier(idle_notifier_actual)

    if xstream.ui.favorites.pinned then
      xstream.ui.favorites:show()
    end

  end

  attach_to_song()

end

-------------------------------------------------------------------------------

function selected_track_index_notifier()
  TRACE("*** selected_track_index_notifier fired...")
  if (xstream) then
    xstream.track_index = rns.selected_track_index
  end
end

-------------------------------------------------------------------------------

function device_param_notifier()
  TRACE("*** xStream - device_param_notifier fired...")
  if xstream then
    xstream.device_param = rns.selected_parameter
  end
end

-------------------------------------------------------------------------------

function edit_notifier()
  TRACE("*** edit_notifier fired...")
  if xstream then
    if rns.transport.edit_mode then
      if dialog_is_suspended() then
        return
      end
      if rns.transport.playing and
        (prefs.start_option.value == xStreamPrefs.START_OPTION.ON_PLAY_EDIT) 
      then
        xstream:start()
      end
    elseif (prefs.start_option.value == xStreamPrefs.START_OPTION.ON_PLAY_EDIT) then
      xstream:stop()
    end
  end
end

-------------------------------------------------------------------------------

function playing_notifier()
  --TRACE("main - playing_notifier fired...")
  if xstream then
    if not rns.transport.playing then -- autostop
      if (prefs.start_option.value ~= xStreamPrefs.START_OPTION.MANUAL) then
        xstream:stop()
      end
    elseif not xstream.active then -- autostart

      if dialog_is_suspended() then
        return
      end

      if (prefs.start_option.value ~= xStreamPrefs.START_OPTION.MANUAL) then
        if rns.transport.edit_mode then
          if (prefs.start_option.value == xStreamPrefs.START_OPTION.ON_PLAY_EDIT) then
            xstream:start()
          end
        else
          if (prefs.start_option.value == xStreamPrefs.START_OPTION.ON_PLAY) then
            xstream:start()
          end
        end
      end
    end
  end
end

-------------------------------------------------------------------------------

function attach_to_song()
  TRACE("attach_to_song()")
  
  xObservable.attach(rns.transport.playing_observable,playing_notifier)
  xObservable.attach(rns.selected_track_index_observable,selected_track_index_notifier)
  xObservable.attach(rns.selected_parameter_observable,device_param_notifier) 
  xObservable.attach(rns.transport.edit_mode_observable,edit_notifier)

  selected_track_index_notifier()
  device_param_notifier()
  edit_notifier()

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
