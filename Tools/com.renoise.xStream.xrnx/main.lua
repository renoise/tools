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
local xLib_dir = 'source/xLib/'

require (xLib_dir..'xLib')
require (xLib_dir..'xAudioDevice')
require (xLib_dir..'xBlockLoop')
require (xLib_dir..'xColor')
require (xLib_dir..'xDialog')
require (xLib_dir..'xEffectColumn')
require (xLib_dir..'xFilesystem')
require (xLib_dir..'xLine')
require (xLib_dir..'xLineAutomation')
require (xLib_dir..'xLinePattern')
require (xLib_dir..'xNoteColumn')
require (xLib_dir..'xParseXML')
require (xLib_dir..'xObservable')
require (xLib_dir..'xPhraseMgr')
require (xLib_dir..'xReflection')
require (xLib_dir..'xScale')
require (xLib_dir..'xSongPos')
require (xLib_dir..'xStreamPos')

require (app_dir..'xStream')
require (app_dir..'xStreamArg')
require (app_dir..'xStreamArgs')
require (app_dir..'xStreamFavorite')
require (app_dir..'xStreamFavorites')
require (app_dir..'xStreamModel')
require (app_dir..'xStreamPresets')
require (app_dir..'xStreamUI')

require (xLib_dir..'unit_tests/xsongpos_test')
require (xLib_dir..'unit_tests/xnotecolumn_test')
require (xLib_dir..'unit_tests/xeffectcolumn_test')
require (xLib_dir..'unit_tests/xstream_test')
require (xLib_dir..'unit_tests/xparsexml_test')
require (xLib_dir..'unit_tests/xfilesystem_test')
        
--------------------------------------------------------------------------------
-- preferences
--------------------------------------------------------------------------------


local options = renoise.Document.create("ScriptingToolPreferences"){}
options:add_property("autostart", renoise.Document.ObservableBoolean(false))
options:add_property("editor_visible_lines", renoise.Document.ObservableNumber(16))
options:add_property("favorites_visible", renoise.Document.ObservableBoolean(true))
options:add_property("launch_model", renoise.Document.ObservableString(""))
options:add_property("live_coding", renoise.Document.ObservableBoolean(true))
options:add_property("manage_gc", renoise.Document.ObservableBoolean(false))
options:add_property("model_args_visible", renoise.Document.ObservableBoolean(false))
options:add_property("model_browser_visible", renoise.Document.ObservableBoolean(false))
options:add_property("presets_visible", renoise.Document.ObservableBoolean(false))
options:add_property("show_editor", renoise.Document.ObservableBoolean(true))
options:add_property("show_unit_tests", renoise.Document.ObservableBoolean(false))
options:add_property("suspend_when_hidden", renoise.Document.ObservableBoolean(false))
options:add_property("start_option", renoise.Document.ObservableNumber(xStreamUI.START_OPTION.ON_PLAY_EDIT))
options:add_property("tool_options_visible", renoise.Document.ObservableBoolean(false))
options:add_property("writeahead_factor", renoise.Document.ObservableNumber(175))

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
  return (options.suspend_when_hidden.value) and
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

  local unit_tests = vb:column{
    margin = 6,
    vb:row{
      vb:text{
        text="Click class name to run unit-test",
      },
    },
    vb:row{
      style = "group",
      margin = 6,
      vb:button{
        text="xSongPos",
        width = 100,
        notifier = function()
          xsongpos_test()
        end
      },
      vb:button{
        text="xNoteColumn",
        width = 100,
        notifier = function()
          xnotecolumn_test()
        end
      },
      vb:button{
        text="xEffectColumn",
        width = 100,
        notifier = function()
          xeffectcolumn_test()
        end
      },
      --[[
      vb:button{
        text="xStream",
        width = 100,
        notifier = function()
          xstream_test()
        end
      },
      ]]
      vb:button{
        text="xParseXML",
        width = 100,
        notifier = function()
          xparsexml_test()
        end
      },
      vb:button{
        text="xFilesystem",
        width = 100,
        notifier = function()
          xfilesystem_test()
        end
      },

    },
  }


  -- initialize classes (once)

  if not xstream then

    xpos = xSongPos(rns.transport.edit_pos)
    xstream = xStream()
    xstream.ui = xStreamUI(xstream,vb,MIDI_PREFIX)
    xstream:load_models(xStream.MODELS_FOLDER)

    -- apply options ------------------

    xstream.ui.start_option = options.start_option.value
    xstream.ui.launch_model = options.launch_model.value
    xstream.ui.autostart = options.autostart.value
    xstream.ui.suspend_when_hidden = options.suspend_when_hidden.value
    xstream.ui.manage_gc = options.manage_gc.value
    xstream.ui.show_editor = options.show_editor.value
    xstream.ui.tool_options_visible = options.tool_options_visible.value
    xstream.ui.model_browser_visible = options.model_browser_visible.value
    xstream.ui.model_args_visible = options.model_args_visible.value
    xstream.ui.presets_visible = options.presets_visible.value
    xstream.ui.favorites_visible = options.favorites_visible.value
    xstream.ui.editor_visible_lines = options.editor_visible_lines.value
    xstream.live_coding = options.live_coding.value
    xstream.writeahead_factor = options.writeahead_factor.value

    -- add notifiers ------------------

    xstream.ui.start_option_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.ui.start_option_observable fired...")
      options.start_option.value = xstream.ui.start_option_observable.value
    end)

    xstream.ui.launch_model_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.ui.launch_model_observable fired...")
      options.launch_model.value = xstream.ui.launch_model_observable.value
    end)

    xstream.ui.autostart_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.ui.autostart_observable fired...")
      options.autostart.value = xstream.ui.autostart_observable.value
    end)

    xstream.ui.suspend_when_hidden_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.ui.suspend_when_hidden_observable fired...")
      options.suspend_when_hidden.value = xstream.ui.suspend_when_hidden_observable.value
    end)

    xstream.ui.manage_gc_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.ui.manage_gc_observable fired...")
      options.manage_gc.value = xstream.ui.manage_gc_observable.value
    end)

    xstream.ui.show_editor_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.ui.show_editor_observable fired...")
      options.show_editor.value = xstream.ui.show_editor_observable.value
    end)

    xstream.ui.tool_options_visible_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.ui.tool_options_visible_observable fired...")
      options.tool_options_visible.value = xstream.ui.tool_options_visible_observable.value
    end)

    xstream.ui.model_browser_visible_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.ui.model_browser_visible_observable fired...")
      options.model_browser_visible.value = xstream.ui.model_browser_visible
    end)

    xstream.ui.model_args_visible_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.ui.model_args_visible_observable fired...")
      options.model_args_visible.value = xstream.ui.model_args_visible
    end)

    xstream.ui.presets_visible_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.ui.presets_visible_observable fired...")
      options.presets_visible.value = xstream.ui.presets_visible
    end)

    xstream.ui.favorites_visible_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.ui.favorites_visible_observable fired...")
      options.favorites_visible.value = xstream.ui.favorites_visible
    end)

    xstream.ui.editor_visible_lines_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.ui.editor_visible_lines_observable fired...")
      options.editor_visible_lines.value = xstream.ui.editor_visible_lines
    end)

    xstream.live_coding_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.live_coding_observable fired...")
      options.live_coding.value = xstream.live_coding_observable.value
    end)

    xstream.writeahead_factor_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.writeahead_factor_observable fired...")
      options.writeahead_factor.value = xstream.writeahead_factor_observable.value
    end)

    xstream.active_observable:add_notifier(function()
      TRACE("*** main.lua - xstream.active_observable fired...")
      register_tool_menu()
    end)

  end


  if dialog and dialog.visible then    
    -- bring to front
    dialog:show() 
  else
    -- create, or re-create if hidden
    if not dialog_content then
      dialog_content = vb:column{
        unit_tests,
        xstream.ui.vb_content,
      }
      unit_tests.visible = options.show_unit_tests.value

      -- initialize -----------------------

      xstream.ui:select_launch_model()
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
        (options.start_option.value == xStreamUI.START_OPTION.ON_PLAY_EDIT) 
      then
        xstream:start()
      end
    elseif (options.start_option.value == xStreamUI.START_OPTION.ON_PLAY_EDIT) then
      xstream:stop()
    end
  end
end

-------------------------------------------------------------------------------

function playing_notifier()
  TRACE("main - playing_notifier fired...")
  if xstream then
    if not rns.transport.playing then -- autostop
      if (options.start_option.value ~= xStreamUI.START_OPTION.MANUAL) then
        xstream:stop()
      end
    elseif not xstream.active then -- autostart

      if dialog_is_suspended() then
        return
      end

      if (options.start_option.value ~= xStreamUI.START_OPTION.MANUAL) then
        if rns.transport.edit_mode then
          if (options.start_option.value == xStreamUI.START_OPTION.ON_PLAY_EDIT) then
            xstream:start()
          end
        else
          if (options.start_option.value == xStreamUI.START_OPTION.ON_PLAY) then
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
  
  xLib.attach_to_observable(rns.transport.playing_observable,playing_notifier)
  xLib.attach_to_observable(rns.selected_track_index_observable,selected_track_index_notifier)
  xLib.attach_to_observable(rns.selected_parameter_observable,device_param_notifier) 
  xLib.attach_to_observable(rns.transport.edit_mode_observable,edit_notifier)

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
    ("Favorite #%.2d [Trigger]"):format(i)
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
