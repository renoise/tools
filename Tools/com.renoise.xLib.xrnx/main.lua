--------------------------------------------------------------------------------
-- required files (framework)
--------------------------------------------------------------------------------

require 'xLib/xLib'
require 'xLib/xBlockLoop'
require 'xLib/xEffectColumn'
require 'xLib/xFilesystem'
require 'xLib/xLine'
require 'xLib/xLineAutomation'
require 'xLib/xLinePattern'
require 'xLib/xNoteColumn'
require 'xLib/xPhraseMgr'
require 'xLib/xSongPos'
require 'xLib/xStream'
require 'xLib/xStreamArg'
require 'xLib/xStreamArgs'
require 'xLib/xStreamModel'
require 'xLib/xStreamUI'
--require 'xLib/xStreamMgr'

--------------------------------------------------------------------------------
-- required files (unit tests)
--------------------------------------------------------------------------------

require 'xLib/unit_tests/xsongpos_test'
require 'xLib/unit_tests/xnotecolumn_test'
--require 'xLib/unit_tests/xStream_test'

--------------------------------------------------------------------------------
-- preferences
--------------------------------------------------------------------------------

local START_OPTIONS = {"Manual","On Play","On Play + Edit"}
local START_OPTION = {
  MANUAL = 1,
  ON_PLAY = 2,
  ON_PLAY_EDIT = 3,
}


local options = renoise.Document.create("ScriptingToolPreferences"){}
options:add_property("autostart", renoise.Document.ObservableBoolean(false))
options:add_property("manage_gc", renoise.Document.ObservableBoolean(true))
options:add_property("start_option", renoise.Document.ObservableNumber(START_OPTION.ON_PLAY_EDIT))
options:add_property("launch_model", renoise.Document.ObservableString(""))
renoise.tool().preferences = options

--------------------------------------------------------------------------------
-- variables/instances
--------------------------------------------------------------------------------

-- global song accessor
rns = nil

local TOOL_NAME = "xLibTest"
local xpos,xstream

local vb = renoise.ViewBuilder()
local dialog,dialog_content

-------------------------------------------------------------------------------
-- remote-control via xSongPos 

function follow_pos()
  if xpos.pos then
    rns.transport.edit_pos = xpos.pos
    local msg = tostring(xpos).."lines_travelled:"..xpos.lines_travelled
    renoise.app():show_status(msg)
    --print(msg)
  end
end

-------------------------------------------------------------------------------
-- wait with launch until tool has a renoise document to work on
-- workaround for http://goo.gl/UnSDnw

local waiting_to_show_dialog = options.autostart.value

-- post-launch notifier 
local function idle_notifier_actual()
  local view = vb.views["xStreamImplStats"]
  local str_stat = ("Memory usage: %.2f Mb"):format(collectgarbage("count")/1024)
                ..("\nStream active: %s"):format(xstream.active and "true" or "false") 
                ..("\nStream muted: %s"):format(xstream.muted and "true" or "false") 
                ..("\nLines Travelled: %d"):format(xstream._writepos.lines_travelled)
  view.text = str_stat
end

-- pre-launch notifier 
local function idle_notifier()
  --print("*** idle_notifier fired...")
  if waiting_to_show_dialog then
    waiting_to_show_dialog = false
    renoise.tool().app_idle_observable:remove_notifier(idle_notifier)
    renoise.tool().app_idle_observable:add_notifier(idle_notifier_actual)
    show()
  end
end
renoise.tool().app_idle_observable:add_notifier(idle_notifier)


-------------------------------------------------------------------------------
-- handle keys in dialog

local function keyhandler(dlg, key)
  --rprint(key)
  local shift_pressed = string.find(key.modifiers,"shift") and true or false
  --print("shift_pressed",shift_pressed)
  if (key.name == "up") then
    xpos:decrease_by_lines(shift_pressed and 10 or 1)
    follow_pos()
  elseif (key.name == "down") then
    xpos:increase_by_lines(shift_pressed and 10 or 1)
    follow_pos()
  else
    return key
  end
end

-------------------------------------------------------------------------------

function update_launch_models()
  --print("models_observable fired...")
  --print("xstream.models",rprint(xstream.models))
  -- update popup with model names
  local view = vb.views["xStreamImplLaunchModel"]
  if not view then
    return
  end
  local model_names = {"Select a model"}
  local launch_model_index = 1
  for k,v in ipairs(xstream.models) do
    table.insert(model_names,v.name)
    if (v.name == options.launch_model.value) then
      launch_model_index = k
    end
  end
  --print("launch_model_index",launch_model_index)
  view.items = model_names
  view.value = launch_model_index
end

-------------------------------------------------------------------------------
-- invoked by menu entries, autostart - 
-- first time around, the UI/class instances are created 

function show()

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
      --[[
      vb:column{
        vb:row{
          vb:text{
            text = "bounds_mode",
          },
          vb:switch{
            items = {"CAP","LOOP","NULL"},
            value = xpos.bounds_mode,
            width = 120,
            notifier = function(idx)
              xpos.bounds_mode = idx
            end
          },
        },
        vb:row{
          vb:text{
            text = "loop_boundary",
          },
          vb:switch{
            items = {"HARD","SOFT","NONE"},
            value = xpos.loop_boundary,
            width = 120,
            notifier = function(idx)
              xpos.loop_boundary = idx
            end
          },
        },
        vb:row{
          vb:text{
            text = "block_boundary",
          },
          vb:switch{
            items = {"HARD","SOFT","NONE"},
            value = xpos.block_boundary,
            width = 120,
            notifier = function(idx)
              xpos.block_boundary = idx
            end
          },
        },
      }
      ]]
    },
  }


  -- create class instances - but only once


  if not xstream then
    xpos = xSongPos(rns.transport.edit_pos)
    xstream = xStream()
    local model_defs_path = "./xLib/Models/"
    --local model_defs_path = renoise.tool().bundle_path .. "/xLib/Models/" -- not working with junction
    xstream:load_models(model_defs_path)
    xstream.ui = xStreamUI(xstream,vb)
    xstream.models_observable:add_notifier(update_launch_models)
  end


  if dialog and dialog.visible then    
    -- bring to front
    dialog:show() 
  else
    -- create, or re-create if hidden
    
    if not dialog_content then
    
      --vb.views["xStreamImplLaunchModel"] = nil
      --vb.views["xStreamImplStats"] = nil

      local tool_option_w = 140
      dialog_content = vb:column{
        unit_tests,
        vb:row{
          style = "group",
          margin = 6,
          width = tool_option_w,
          vb:column{
            vb:column{
              style = "panel",
              margin = 4,
              width = "100%",
              vb:text{
                text="xStream",
                font = "bold",
              },
            },
            vb:column{
              style = "panel",
              margin = 4,
              width = "100%",
              vb:text{
                text="Decide how to\n"
                  .."control streaming:"
              },
              vb:row{
                vb:popup{
                  bind = options.start_option,
                  items = START_OPTIONS,
                  width = tool_option_w-10,
                },
              },
            },
            vb:column{
              style = "panel",
              margin = 4,
              width = tool_option_w,
              vb:text{
                text= "Launch with the\n"
                    .."chosen model"
              },
              vb:popup{
                items = {"Select a model"},
                id = "xStreamImplLaunchModel",
                notifier = function(idx)
                  options.launch_model.value = xstream.models[idx].file_path
                  print("options.launch_model.value",options.launch_model.value)
                end,
                width = tool_option_w-10,
              }
            },

            vb:column{
              style = "panel",
              margin = 4,
              width = "100%",
              vb:row{
                vb:checkbox{
                  bind = options.autostart,
                },
                vb:text{
                  text="Launch tool when\n"
                    .."Renoise starts:",
                },

              },
            },
            vb:column{
              style = "panel",
              margin = 4,
              width = "100%",
              vb:row{
                vb:checkbox{
                  id = "xStreamImplManageGarbage",
                  notifier = function(checked)
                    options.manage_gc.value = checked
                    xstream.manage_gc = checked
                    print("xstream.manage_gc",xstream.manage_gc)
                  end,
                },
                vb:text{
                  text="Bypass garbage\n"
                    .." collection:",
                },

              },
            },
            vb:column{
              style = "panel",
              margin = 4,
              width = "100%",
              vb:text{
                text= "Stats",
                font = "bold",

              },
              vb:text{
                text= "",
                id = "xStreamImplStats",
              },
            },
          },
          xstream.ui.vb_content
        }

      }
    end

    dialog = renoise.app():show_custom_dialog(
      TOOL_NAME, dialog_content, keyhandler)

    update_launch_models()
    vb.views["xStreamImplManageGarbage"].value = options.manage_gc.value
    xstream.manage_gc = options.manage_gc.value

  end


  -- initialize -----------------------

  local view = vb.views["xStreamImplLaunchModel"]
  for k,v in ipairs(xstream.models) do
    if (v.file_path == options.launch_model.value) then
      view.value = k
    end
  end
  if (view.value > 1) then
    xstream.selected_model_index = view.value-1
  end

  attach_to_song()

end

-------------------------------------------------------------------------------
-- attach to song, once xstream is ready

function attach_to_song()
  --print("attach_to_song()")

  xstream:attach_to_song()

  local add_observable = function(obs,fn)
    if obs:has_notifier(fn) then
      obs:remove_notifier(fn)
    end
    obs:add_notifier(fn)
  end

  -- playback (start option) ------------------------------

  local playing_notifier = function()
    --print("main - playing_notifier fired...")
    if not rns.transport.playing then -- autostop
      if (options.start_option.value ~= START_OPTION.MANUAL) then
        xstream:stop()
      end
    elseif not xstream.active then -- autostart
      if (options.start_option.value ~= START_OPTION.MANUAL) then
        if rns.transport.edit_mode then
          if (options.start_option.value == START_OPTION.ON_PLAY_EDIT) then
            xstream:start()
          end
        else
          if (options.start_option.value == START_OPTION.ON_PLAY) then
            xstream:start()
          end
        end
      end
    end
  end
  add_observable(rns.transport.playing_observable,playing_notifier)


  -- selected track ---------------------------------------

  local track_notifier = function ()
    --print("*** track_notifier fired...")
    if (xstream) then
        xstream.track_index = rns.selected_track_index
    end
  end
  add_observable(rns.selected_track_index_observable,track_notifier)
  track_notifier()


  -- device parameters ------------------------------------

  local device_param_notifier = function ()
    --print("*** device_param_notifier fired...")
    if (xstream) then
      xstream.device = rns.selected_device
      xstream.param_index = rns.selected_track_parameter_index-1 -- FIXME bug in lua API? 
    end
  end
  add_observable(rns.selected_track_parameter_observable,device_param_notifier)
  add_observable(rns.selected_device_observable,device_param_notifier)
  device_param_notifier()


  -- edit-mode --------------------------------------------

  local edit_notifier = function ()
    --print("*** edit_notifier fired...")
    if (xstream) then
        if rns.transport.edit_mode and rns.transport.playing and
          (options.start_option.value == START_OPTION.ON_PLAY_EDIT) 
        then
          xstream.active = rns.transport.edit_mode
        end
    end
  end
  add_observable(rns.transport.edit_mode_observable,edit_notifier)
  edit_notifier()

end


-------------------------------------------------------------------------------
-- tool-specific 
--------------------------------------------------------------------------------

renoise.tool().app_new_document_observable:add_notifier(function()
  --print("*** app_new_document_observable fired...")

  -- global song accessor
  rns = renoise.song()

  if options.autostart.value then
    show()
  end

  --[[
  if xstream then
    attach_to_song()
  end
  ]]

end)

renoise.tool():add_menu_entry{
  name = "Main Menu:Tools:"..TOOL_NAME,
  invoke = function() 
    show() 
  end
}

