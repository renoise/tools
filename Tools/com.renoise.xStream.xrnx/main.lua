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
local vlib_root = 'source/vLib/classes/'
local xlib_root = 'source/xLib/classes/'
--_trace_filters = nil
_trace_filters = {".*"}
--_trace_filters = {"^xStreamUIFavorites"}


require (vlib_root..'helpers/vColor')
require (vlib_root..'vPrompt')
require (vlib_root..'vDialog')

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
require (xlib_root..'xParseXML')
require (xlib_root..'xObservable')
require (xlib_root..'xPhraseManager')
require (xlib_root..'xReflection')
require (xlib_root..'xScale')
require (xlib_root..'xSongPos')
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
require (app_dir..'xStreamUI')
require (app_dir..'xStreamUIOptions')
require (app_dir..'xStreamUIFavorites')
require (app_dir..'xStreamUIPresetPanel')
require (app_dir..'xStreamUIArgsPanel')
require (app_dir..'xStreamUIArgsEditor')

--------------------------------------------------------------------------------
-- preferences
--------------------------------------------------------------------------------

-- TODO refactor as xStreamPrefs
local options = renoise.Document.create("ScriptingToolPreferences"){}

-- general
options:add_property("autostart", renoise.Document.ObservableBoolean(false))
options:add_property("launch_model", renoise.Document.ObservableString(""))
options:add_property("launch_selected_model", renoise.Document.ObservableBoolean(true))
-- user interface
options:add_property("editor_visible_lines", renoise.Document.ObservableNumber(16))
options:add_property("favorites_pinned", renoise.Document.ObservableBoolean(false))
options:add_property("live_coding", renoise.Document.ObservableBoolean(true))
options:add_property("model_args_visible", renoise.Document.ObservableBoolean(false))
options:add_property("model_browser_visible", renoise.Document.ObservableBoolean(false))
options:add_property("presets_visible", renoise.Document.ObservableBoolean(false))
options:add_property("show_editor", renoise.Document.ObservableBoolean(true))
options:add_property("tool_options_visible", renoise.Document.ObservableBoolean(false))
-- streaming
options:add_property("suspend_when_hidden", renoise.Document.ObservableBoolean(false))
options:add_property("start_option", renoise.Document.ObservableNumber(xStreamUIOptions.START_OPTION.ON_PLAY_EDIT))
options:add_property("scheduling", renoise.Document.ObservableNumber(xStreamUIOptions.START_OPTION.ON_PLAY_EDIT))
options:add_property("mute_mode", renoise.Document.ObservableNumber(xStream.MUTE_MODE.OFF))
options:add_property("writeahead_factor", renoise.Document.ObservableNumber(175))
-- output
options:add_property("automation_playmode", renoise.Document.ObservableNumber(xStream.PLAYMODE.POINTS))
options:add_property("include_hidden", renoise.Document.ObservableBoolean(false))
options:add_property("clear_undefined", renoise.Document.ObservableBoolean(true))
options:add_property("expand_columns", renoise.Document.ObservableBoolean(true))


renoise.tool().preferences = options

--------------------------------------------------------------------------------
-- variables/instances
--------------------------------------------------------------------------------

rns = nil 

local TOOL_NAME = "xStream"
local MIDI_PREFIX = "Tools:"..TOOL_NAME..":"
local xpos,xstream

local vb = renoise.ViewBuilder()
local dialog,dialog_content

local waiting_to_show_dialog = options.autostart.value
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
    xstream.ui = xStreamUI(xstream,vb,MIDI_PREFIX,options)
    xstream:load_models(xStream.MODELS_FOLDER)

    -- apply options ------------------


    -- general options
    xstream.ui.options.autostart = options.autostart.value
    xstream.launch_model = options.launch_model.value
    xstream.launch_selected_model = options.launch_selected_model.value

    -- user interface options
    xstream.live_coding = options.live_coding.value
    xstream.ui.show_editor = options.show_editor.value
    xstream.ui.args.visible = options.model_args_visible.value
    xstream.ui.presets.visible = options.presets_visible.value
    xstream.ui.favorites.pinned = options.favorites_pinned.value
    xstream.ui.editor_visible_lines = options.editor_visible_lines.value

    -- streaming options
    xstream.ui.options.start_option = options.start_option.value
    xstream.scheduling = options.scheduling.value
    xstream.mute_mode = options.mute_mode.value
    xstream.suspend_when_hidden = options.suspend_when_hidden.value
    xstream.writeahead_factor = options.writeahead_factor.value

    -- output outputs
    xstream.automation_playmode = options.automation_playmode.value
    xstream.include_hidden = options.include_hidden.value
    xstream.clear_undefined = options.clear_undefined.value
    xstream.expand_columns = options.expand_columns.value


    -- notifiers --

    xstream.live_coding_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.live_coding_observable fired...")
      options.live_coding.value = xstream.live_coding_observable.value
    end)

    xstream.automation_playmode_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.automation_playmode_observable fired...")
      options.automation_playmode.value = xstream.automation_playmode_observable.value
    end)

    xstream.writeahead_factor_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.writeahead_factor_observable fired...")
      options.writeahead_factor.value = xstream.writeahead_factor_observable.value
    end)

    xstream.include_hidden_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.include_hidden_observable fired...")
      options.include_hidden.value = xstream.include_hidden_observable.value
    end)

    xstream.clear_undefined_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.clear_undefined_observable fired...")
      options.clear_undefined.value = xstream.clear_undefined_observable.value
    end)

    xstream.expand_columns_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.expand_columns_observable fired...")
      options.expand_columns.value = xstream.expand_columns_observable.value
    end)

    xstream.active_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.active_observable fired...")
      register_tool_menu()
    end)

    xstream.ui.options.start_option_observable:add_notifier(function()
      TRACE("*** xStreamUI - xstream.ui.options.start_option_observable fired...")
      options.start_option.value = xstream.ui.options.start_option_observable.value
    end)

    xstream.launch_model_observable:add_notifier(function()
      TRACE("*** xStreamUI - xstream.launch_model_observable fired...")
      options.launch_model.value = xstream.launch_model_observable.value
    end)

    xstream.launch_selected_model_observable:add_notifier(function()
      TRACE("*** xStreamUI - xstream.launch_selected_model_observable fired...")
      options.launch_selected_model.value = xstream.launch_selected_model_observable.value
    end)

    xstream.ui.options.autostart_observable:add_notifier(function()
      TRACE("*** xStreamUI - xstream.ui.options.autostart_observable fired...")
      options.autostart.value = xstream.ui.options.autostart_observable.value
    end)

    xstream.suspend_when_hidden_observable:add_notifier(function()
      TRACE("*** xStreamUI - xstream.suspend_when_hidden_observable fired...")
      options.suspend_when_hidden.value = xstream.suspend_when_hidden_observable.value
    end)

    xstream.scheduling_observable:add_notifier(function()
      TRACE("*** xStreamUI - xstream.scheduling_observable fired...")
      options.scheduling.value = xstream.scheduling_observable.value
    end)

    xstream.mute_mode_observable:add_notifier(function()
      TRACE("*** xStreamUI - xstream.mute_mode_observable fired...")
      options.mute_mode.value = xstream.mute_mode_observable.value
    end)

    xstream.ui.show_editor_observable:add_notifier(function()
      TRACE("*** xStreamUI - xstream.ui.show_editor_observable fired...")
      options.show_editor.value = xstream.ui.show_editor_observable.value
    end)

    xstream.ui.tool_options_visible_observable:add_notifier(function()
      TRACE("*** xStreamUI - xstream.ui.tool_options_visible_observable fired...")
      options.tool_options_visible.value = xstream.ui.tool_options_visible_observable.value
    end)

    xstream.ui.model_browser_visible_observable:add_notifier(function()
      TRACE("*** xStreamUI - xstream.ui.model_browser_visible_observable fired...")
      options.model_browser_visible.value = xstream.ui.model_browser_visible
    end)

    xstream.ui.args.visible_observable:add_notifier(function()
      TRACE("*** xStreamUI - xstream.ui.args.visible_observable fired...")
      options.model_args_visible.value = xstream.ui.args.visible
    end)

    xstream.ui.presets.visible_observable:add_notifier(function()
      TRACE("*** xStreamUI - xstream.ui.presets.visible_observable fired...")
      options.presets_visible.value = xstream.ui.presets.visible
    end)

    xstream.ui.favorites.pinned_observable:add_notifier(function()
      TRACE("*** xStreamUI - xstream.ui.favorites.pinned_observable fired...")
      options.favorites_pinned.value = xstream.ui.favorites.pinned
    end)

    xstream.ui.editor_visible_lines_observable:add_notifier(function()
      TRACE("*** xStreamUI - xstream.ui.editor_visible_lines_observable fired...")
      options.editor_visible_lines.value = xstream.ui.editor_visible_lines
    end)

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
      --print(">>> open pinned favorites")
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
        (options.start_option.value == xStreamUIOptions.START_OPTION.ON_PLAY_EDIT) 
      then
        xstream:start()
      end
    elseif (options.start_option.value == xStreamUIOptions.START_OPTION.ON_PLAY_EDIT) then
      xstream:stop()
    end
  end
end

-------------------------------------------------------------------------------

function playing_notifier()
  TRACE("main - playing_notifier fired...")
  if xstream then
    if not rns.transport.playing then -- autostop
      if (options.start_option.value ~= xStreamUIOptions.START_OPTION.MANUAL) then
        xstream:stop()
      end
    elseif not xstream.active then -- autostart

      if dialog_is_suspended() then
        return
      end

      if (options.start_option.value ~= xStreamUIOptions.START_OPTION.MANUAL) then
        if rns.transport.edit_mode then
          if (options.start_option.value == xStreamUIOptions.START_OPTION.ON_PLAY_EDIT) then
            xstream:start()
          end
        else
          if (options.start_option.value == xStreamUIOptions.START_OPTION.ON_PLAY) then
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
-- on new document 

renoise.tool().app_new_document_observable:add_notifier(function()
  TRACE("*** app_new_document_observable fired...")

  rns = renoise.song()

  if options.autostart.value then
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
