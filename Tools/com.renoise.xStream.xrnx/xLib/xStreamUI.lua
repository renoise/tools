--[[============================================================================
xStreamUI
============================================================================]]--
--[[

	Basic user-interface for xStream. Provides controls for most of 
  the class properties and methods, and built entirely around the 
  available xStream notifiers.

]]

class 'xStreamUI'

xStreamUI.MODEL_CONTROLS = {
  "xStreamAddPreset",
  "xStreamApplyLocallyButton",
  "xStreamApplySelectionButton",
  "xStreamApplyTrackButton",
  "xStreamApplyTrackButton",
  "xStreamCallbackCompile",
  "xStreamCallbackEdit",
  "xStreamExportPresetBank",
  "xStreamImportPresetBank",
  "xStreamModelRemove",
  "xStreamModelRename",
  "xStreamModelSave",
  "xStreamModelSaveAs",
  "xStreamMuteButton",
  "xStreamRevealLocation",
  "xStreamStartButton",
  "xStreamStartPlayButton",
  "xStreamStopButton",
  "xStreamUnmuteButton",
  --"xStreamExportFileButton",
  --"xStreamExportPhraseButton",
}

-------------------------------------------------------------------------------
-- constructor
-- @param xstream (xStream)
-- @param vb (renoise.ViewBuilder)
-- @param midi_prefix (string)

function xStreamUI:__init(xstream,vb,midi_prefix)

  self.xstream = xstream
  self.vb = vb
  self.midi_prefix = midi_prefix

  self.vb_content = nil

  self.show_editor = property(self.get_show_editor,self.set_show_editor)
  self.show_editor_observable = renoise.Document.ObservableBoolean(true)

  self.preset_views = {}
  self.model_views = {}
  self.arg_views = {}
  
  self:build()
  --self:update()

end

--------------------------------------------------------------------------------
-- update everything

function xStreamUI:update()
  TRACE("xStreamUI:update()")

  self:update_args()
  self:update_models()
  self:update_presets()
  self:update_editor()

end

--------------------------------------------------------------------------------

function xStreamUI:update_args()
  TRACE("xStreamUI:update_args()")

  if not self.xstream.selected_model then
    --print("*** No model selected")
    return
  end

  local vb = self.vb
  local args = self.xstream.selected_model.args

  local vb_container = vb.views["xStreamArgsContainer"]
  for k,v in ipairs(self.arg_views) do
    vb_container:remove_child(v)
  end

  self.arg_views = {}

  if (args.length == 0) then
    return
  end

  -- add a custom control for each argument
  for k,arg in ipairs(args.args) do

    -- custom number/string converters 
    local fn_tostring = nil
    local fn_tonumber = nil
    
    --print("arg.properties",rprint(arg.properties))

    if arg.properties.display_as_hex then
      fn_tostring = function(val)
        val = arg.properties.zero_based and val-1 or val
        return ("%X"):format(val)
      end 
      fn_tonumber = function(str)
        local val = tonumber(str, 16)
        val = arg.properties.zero_based and val+1 or val
        return val
      end
    elseif arg.properties.display_as_note then
      --print("arg.properties.display_as_note")
      fn_tostring = function(val)
        return xNoteColumn.note_value_to_string(math.floor(val))
      end 
      fn_tonumber = function(str)
        return xNoteColumn.note_string_to_value(str)
      end
    else
      fn_tostring = function(val)
        val = arg.properties.zero_based and val-1 or val
        return ("%s"):format(val)
      end 
      fn_tonumber = function(str)
        local val = tonumber(str)
        val = arg.properties.zero_based and val+1 or val
        return val
      end
    end
    local model_name = self.xstream.selected_model.name
    local view = vb:row{
      vb:checkbox{
        bind = arg.locked_observable,
        tooltip = "Lock value - can still be changed manually," 
                .."\nbut prevents changes when switching presets"
                .."\nor receiving values from the Renoise API.",
      }
    }

    if (type(arg.observable) == "ObservableNumber") then

      local slider_width = 100
      local full_width = 160

      if arg.properties.items then
        local display = arg.properties.display or "popup"
        if (display == "popup") then
          view:add_child(vb:row{
            tooltip = arg.description,
            vb:text{
              text = arg.name,
              font = "mono",
            },
            vb:popup{
              items = arg.properties.items,
              value = arg.value,
              width = full_width,
              bind = arg.observable,
            },
          })
        elseif (display == "chooser") then
          view:add_child(vb:row{
            tooltip = arg.description,
            vb:text{
              text = arg.name,
              font = "mono",
            },
            vb:chooser{
              items = arg.properties.items,
              value = arg.value,
              width = full_width,
              bind = arg.observable,
            },
          })
        elseif (display == "switch") then
          view:add_child(vb:row{
            tooltip = arg.description,
            vb:text{
              text = arg.name,
              font = "mono",
            },
            vb:switch{
              items = arg.properties.items,
              value = arg.value,
              width = full_width,
              bind = arg.observable,
            },
          })
        end

      elseif (arg.properties.quant == 1) then
        -- integer value
        view:add_child(vb:row{
          tooltip = arg.description,
          vb:text{
            text = arg.name,
            font = "mono",
          },
          vb:valuebox{
            tostring = fn_tostring,
            tonumber = fn_tonumber,
            value = arg.value,
            min = arg.properties.min or -99999,
            max = arg.properties.max or 99999,
            bind = arg.observable,
          }
        })

      else
        -- slider/number

        view:add_child(vb:row{
          tooltip = arg.description,
          vb:text{
            text = arg.name,
            font = "mono",
          },
        })

        local display = arg.properties.display or "minislider"
        if (display == "minislider") then
          view:add_child(vb:minislider{
            value = arg.value,
            width = slider_width,
            min = arg.properties.min or -99999,
            max = arg.properties.max or 99999,
            bind = arg.observable,
          })
        elseif (display == "rotary") then
          view:add_child(vb:rotary{
            value = arg.value,
            --width = slider_width,
            height = 24,
            min = arg.properties.min or -99999,
            max = arg.properties.max or 99999,
            bind = arg.observable,
          })
        end

        view:add_child(vb:valuefield{
          tostring = fn_tostring,
          tonumber = fn_tonumber,
          value = arg.value,
          min = arg.properties.min or -99999,
          max = arg.properties.max or 99999,
          bind = arg.observable,
        })

      end

    elseif (type(arg.observable) == "ObservableBoolean") then

      view:add_child(vb:row{
        tooltip = arg.description,
        vb:checkbox{
          value = arg.value,
          bind = arg.observable,
        },
        vb:text{
          text = arg.name,
          font = "mono",
        },
      })

    elseif (type(arg.observable) == "ObservableString") then

      view:add_child(vb:row{
        tooltip = arg.description,
        vb:text{
          text = arg.name,
          font = "mono",
        },
        vb:textfield{
          text = arg.value,
          width = full_width,
          bind = arg.observable,
        },
      })

    end

    if view then
  
      table.insert(self.arg_views,view)
      vb_container:add_child(view)
    end


  end

end

--------------------------------------------------------------------------------

function xStreamUI:update_models()
  TRACE("xStreamUI:update_models()")

  local vb = self.vb

  local vb_container = vb.views["xStreamModelContainer"]
  for k,v in ipairs(self.model_views) do
    vb_container:remove_child(v)
  end

  self.model_views = {}

  for k,v in ipairs(self.xstream.models) do
    local row = vb:row{
      vb:button{
        text = v.name,
        color = (self.xstream.selected_model_index == k)
          and xLib.COLOR_ENABLED or xLib.COLOR_DISABLED,
        notifier = function()
          self.xstream.selected_model_index = k
        end,
      },
    }
    vb_container:add_child(row)
    table.insert(self.model_views,row)

  end

end

--------------------------------------------------------------------------------

function xStreamUI:update_presets()
  TRACE("xStreamUI:update_presets()")

  if not self.xstream.selected_model then
    --print("*** No model selected")
    return
  end

  local vb = self.vb
  local args = self.xstream.selected_model.args

  local vb_container = vb.views["xStreamArgPresetContainer"]
  for k,v in ipairs(self.preset_views) do
    vb_container:remove_child(v)
  end

  self.preset_views = {}


  if (args.length == 0) then
    return
  end

  local preset_node = args.doc["Presets"]
  
  for k = 1,#preset_node do
    
    local preset_name = args.get_suggested_preset_name(k)

    local midi_mapping = self.midi_prefix..
      ("Set Preset (%.2X)"):format(k)

    local color = (args.selected_preset_index == k)
      and xLib.COLOR_ENABLED or xLib.COLOR_DISABLED

    local row = vb:row{
      vb:button{
        text = "-",
        tooltip = "Remove this preset",
        --color = color,
        notifier = function()
          args:remove_preset(k)
          self:update_presets()
        end
      },
      vb:button{
        text = preset_name,
        tooltip = "Activate this preset",
        color = color,
        notifier = function()
          local success,err = args:recall_preset(k)
          if not success then
            LOG(err)
          end
          self:update_presets()
        end,
        midi_mapping = midi_mapping
      },
      --[[
      vb:button{
        text = "Rename",
        --color = color,
        notifier = function()
          args:rename_preset(k)
          self:update_presets()
        end
      },
      ]]
      vb:button{
        text = "Update",
        tooltip = "Update this preset with the current settings",
        notifier = function()
          args:update_preset(k)
          self:update_presets()
        end
      },

    }
    vb_container:add_child(row)
    table.insert(self.preset_views,row)


  end

end

--------------------------------------------------------------------------------

function xStreamUI:update_editor()
  TRACE("xStreamUI:update_editor()")

  if not self.xstream.selected_model then
    --print("*** No model selected")
    return
  end

  local model = self.xstream.selected_model
  local vb = self.vb

  local view = vb.views["xStreamCallbackEditor"]
  local str_fn = model.callback_str or "Undefined"
  view.text = str_fn

  local view_name = vb.views["xStreamCallbackName"]
  view_name.text = model.file_path

end

--------------------------------------------------------------------------------
-- 
function xStreamUI:build()
  TRACE("xStreamUI:build()")

  if self.vb_content then
    --print("xStreamUI has already been built")
    return
  end

  local vb = self.vb

  local content = vb:column{
    vb:column{
      style = "panel",
      margin = 4,
      vb:text{
        text = "callback/definition",
        id = "xStreamCallbackName",
        font = "bold",
        width = "100%",
      },
      vb:multiline_textfield{
        text = "Here be lua...",
        font = "mono",
        height = 200,
        width = 500, -- 80 characters
        id = "xStreamCallbackEditor",
        notifier = function(str)
          local model = self.xstream.selected_model
          if model then
            -- note: add extra line to avoid end of string being
            -- truncated, one line at a time... API bug? 
            model.callback_str = str .. "\n" 
          end
        end,

      },
      vb:row{
        vb:button{
          text = "⌨ edit callback",
          tooltip = "Toggle the code editor",
          id = "xStreamCallbackEdit",
          active = false,
          notifier = function()
            self:toggle_code_editor()
          end,
        },
        vb:row{

          vb:button{
            text = "compile",
            tooltip = "Compile the callback (will check for error)",
            id = "xStreamCallbackCompile",
            active = false,
            notifier = function()
              local model = self.xstream.selected_model
              local view = vb.views["xStreamCallbackEditor"]
              local passed,err = model:compile(view.text)
              if not passed then
                renoise.app():show_warning(err)
                self.xstream.callback_status_observable.value = err
              else
                self.xstream.callback_status_observable.value = ""
              end
            end,
          },

          -- hackaround for clickable text
          vb:checkbox{
            value = false,
            visible = false,  
            notifier = function()
              if (self.xstream.callback_status_observable.value ~= "") then
                renoise.app():show_warning(
                  "The callback returned the following error:\n"
                  ..self.xstream.callback_status_observable.value
                  .."\n\n(you can also see these messages in the scripting console)")
              end
            end
          },
          vb:text{
            id = "xStreamCallbackStatus",
            text = "",
          }
        },
        vb:row{
          tooltip = "Compile the callback as you type",
          id = "xStreamLiveCoding",
          vb:checkbox{
            bind = self.xstream.live_coding_observable
          },
          vb:text{
            text = "live coding"
          },
        },
      },
    },    
    vb:row{
      vb:column{
        style = "panel",
        margin = 4,
        vb:text{
          text = "models",
          font = "bold",
        },
        vb:row{
          vb:button{
            text = "new",
            tooltip = "Create a new model",
            id = "xStreamModelCreate",
            notifier = function()
              local passed,err = self:create_model()
              if not passed and err then
                renoise.app():show_warning(err)
              end 
            end,
          },
          vb:button{
            text = "load",
            tooltip = "Import model definitions from a folder",
            notifier = function()
              local str_path = renoise.app():prompt_for_path("Select folder containing models")
              if (str_path ~= "") then
                self.xstream:load_models(str_path)
              end
            end,
          },
          vb:button{
            text = "rename",
            tooltip = "Assign a new name to the selected definition",
            id = "xStreamModelRename",
            notifier = function()
              self:rename_model()          
            end,
          },
        },
        vb:row{

          vb:button{
            text = "save",
            tooltip = "Overwrite the existing definition",
            id = "xStreamModelSave",
            notifier = function()
              local passed,err = self.xstream.selected_model:save()
              if not passed and err then
                renoise.app():show_warning(err)
              end 
            end,
          },
          vb:button{
            text = "save_as",
            tooltip = "Save definition under a new name",
            id = "xStreamModelSaveAs",
            notifier = function()
              local passed,err = self.xstream.selected_model:save_as()          
              if not passed and err then
                renoise.app():show_warning(err)
              end 
            end,
          },        
          vb:button{
            text = "delete",
            tooltip = "Delete the selected definition",
            id = "xStreamModelRemove",
            notifier = function()
              self:delete_model()
            end,
          },

        },
        vb:row{
          vb:button{
            text = "reveal_location",
            tooltip = "Reveal the folder in which the definition is located",
            id = "xStreamRevealLocation",
            notifier = function()
              self.xstream.selected_model:reveal_location()          
            end,
          },        
        },
        vb:space{
          height = 6,
        },
        vb:column{
          id = 'xStreamModelContainer',
          tooltip = "Click to activate a model",
        }
      },
      vb:column{
        vb:column{
          style = "panel",
          margin = 4,
          vb:text{
            text = "methods",
            font = "bold",
          },
          vb:row{
            vb:button{
              text = "start",
              tooltip = "Activate streaming",
              id = "xStreamStartButton",
              notifier = function(val)
                self.xstream:start()
              end,
            },
            vb:button{
              text = "start_and_play",
              tooltip = "Activate streaming and start playback",
              id = "xStreamStartPlayButton",
              notifier = function(val)
                self.xstream:start_and_play()
              end,
            },
            vb:button{
              text = "stop",
              tooltip = "Stop streaming",
              id = "xStreamStopButton",
              notifier = function(val)
                self.xstream:stop()
              end,
            },
          },
          vb:row{
            vb:button{
              text = "mute",
              tooltip = "Mute stream (output empty/undefined notes) ",
              id = "xStreamMuteButton",
              notifier = function(val)
                self.xstream:mute()
              end,
            },
            vb:button{
              text = "unmute",
              tooltip = "Unmute stream (resume output) ",
              id = "xStreamUnmuteButton",
              notifier = function(val)
                self.xstream:unmute()
              end,
            },
          },
          vb:row{
            vb:button{
              text = "fill_track",
              tooltip = "Apply output to the selected track",
              id = "xStreamApplyTrackButton",
              notifier = function(val)
                self.xstream:fill_track()
              end,
            },
            vb:button{
              text = "fill_selection",
              tooltip = "Apply output to the selected lines (relative to top of pattern)",
              id = "xStreamApplySelectionButton",
              notifier = function()
                self.xstream:fill_selection()
              end,
            },
            vb:button{
              text = "locally",
              tooltip = "Apply output to the selected lines (relative to start of selection)",
              id = "xStreamApplyLocallyButton",
              notifier = function()
                self.xstream:fill_selection(true)
              end,
            },
          },
          --[[
          vb:button{
            text = "export_to_phrase",
              tooltip = "Create a new phrase in the selected instrument, write output there (automation is ignored)",
            id = "xStreamExportPhraseButton",
            notifier = function(val)
              local instr_idx = rns.selected_instrument_index
              self.xstream:export_to_phrase(instr_idx)
            end,
          },
          vb:button{
            text = "export_to_file",
            tooltip = "TODO",
            active = false,
            id = "xStreamExportFileButton",
            notifier = function(val)
              self.xstream:export_to_file()
            end,
          },
          ]]
        },
        vb:column{
          style = "panel",
          margin = 4,
          vb:text{
            text = "properties",
            font = "bold",
          },
          vb:row{
            tooltip = "The active track index",
            vb:text{
              text = "track_index",
            },
            vb:valuebox{
              min = 0,
              max = 255,
              bind = self.xstream.track_index_observable,
            },
          },
          vb:row{
            tooltip = "The active device index (automation)",
            vb:text{
              text = "device_index",
            },
            vb:valuebox{
              min = 0,
              max = 255,
              bind = self.xstream.device_index_observable,
            },
          },
          vb:row{
            tooltip = "The active device-parameter index (automation)",
            vb:text{
              text = "param_index",
            },
            vb:valuebox{
              min = 0,
              max = 255,
              bind = self.xstream.param_index_observable,
            },
          },

          vb:row{
            tooltip = "Determine how muting works",
            vb:text{
              text = "mute_mode",
            },
            vb:popup{
              items = xStream.MUTE_MODES,
              width = 100,
              bind = self.xstream.mute_mode_observable,
            },
          },
          vb:row{
            tooltip = "Whether to include hidden columns when writing output",
            vb:checkbox{
              bind = self.xstream.include_hidden_observable,
            },
            vb:text{
              text = "include_hidden",
            },
          },
          vb:row{
            tooltip = "Whether to clear undefined values, columns",
            vb:checkbox{
              bind = self.xstream.clear_undefined_observable,
            },
            vb:text{
              text = "clear_undefined",
            },
          },
          vb:row{
            tooltip = "Automatically reveal (sub-)columns with output",
            vb:checkbox{
              bind = self.xstream.expand_columns_observable,
            },
            vb:text{
              text = "expand_columns",
            },
          },
          
        },
      },
      vb:column{
        style = "panel",
        margin = 4,
        id = 'xStreamArgsContainer',
        height = 100,
        vb:horizontal_aligner{
          mode = "justify",
          vb:text{
            text = "args",
            font = "bold",
          },
          vb:button{
            text = "randomize",
            notifier = function()
              self.xstream.selected_model.args:randomize()
            end
          },

        }
      },
      vb:column{
        style = "panel",
        margin = 4,
        vb:text{
          text = "presets",
          font = "bold",
        },
        vb:button{
          text = "import_bank",
          tooltip = "Import preset bank (unsupported values are logged)",
          id = "xStreamImportPresetBank",
          notifier = function(val)
            self.xstream.selected_model.args:import_bank()
            self:update_presets()
          end,
        },
        vb:button{
          text = "export_bank",
          tooltip = "Export preset bank",
          id = "xStreamExportPresetBank",
          notifier = function()
            self.xstream.selected_model.args:export_bank()
          end
        },
        vb:button{
          text = "add_preset",
          tooltip = "Add new preset with the current settings",
          id = "xStreamAddPreset",
          notifier = function(val)
            local model = self.xstream.selected_model
            model.args:add_preset()
            self.xstream.selected_model.args.selected_preset_index = model.args:get_number_of_presets()
            self:update_presets()
          end,
        },
        vb:column{
          tooltip = "Available presets for this model",
          id = 'xStreamArgPresetContainer',
          -- add buttons here..
        }
      },    
    }
  }

  self.xstream.callback_status_observable:add_notifier(function()    
    
    local str_err = self.xstream.callback_status_observable.value
    local view = self.vb.views["xStreamCallbackStatus"]
    if (str_err == "") then
      view.text = "Syntax OK"
      view.tooltip = ""
    else
      view.text = "⚠ Syntax Error"
      view.tooltip = str_err
    end 

  end)


  self.xstream.mute_mode_observable:add_notifier(function()    

  end)

  self.xstream.muted_observable:add_notifier(function()    
    local view = vb.views["xStreamMuteButton"]
    local color = self.xstream.muted 
      and xLib.COLOR_ENABLED or xLib.COLOR_DISABLED
    view.color = color
  end)

  self.xstream.active_observable:add_notifier(function()    
    local view = vb.views["xStreamStartButton"]
    local color = self.xstream.active 
      and xLib.COLOR_ENABLED or xLib.COLOR_DISABLED
    view.color = color
  end)

  self.xstream.models_observable:add_notifier(function()
    self:update_models()
  end)

  local model_name_notifier = function()
    self:update_models()
  end
  
  local model_modified_notifier = function()
    local view = vb.views["xStreamCallbackCompile"]
    view.active = self.xstream.selected_model.modified
  end
  
  local presets_modified_notifier = function()
    TRACE("*** xstream.selected_model.args.presets_modified_notifier fired...")
    self:update_presets()
  end
  
  local selected_model_index_notifier = function()

    local model = self.xstream.selected_model
    if model then

      self:enable_model_controls()

      if model.name_observable:has_notifier(model_name_notifier) then
        model.name_observable:remove_notifier(model_name_notifier)
      end
      model.name_observable:add_notifier(model_name_notifier)

      if model.modified_observable:has_notifier(model_modified_notifier) then
        model.modified_observable:remove_notifier(model_modified_notifier)
      end
      model.modified_observable:add_notifier(model_modified_notifier)

      if model.args.presets_observable:has_notifier(presets_modified_notifier) then
        model.args.presets_observable:remove_notifier(presets_modified_notifier)
      end
      model.args.presets_observable:add_notifier(presets_modified_notifier)

    else

      self:disable_model_controls()

    end
    self:update()
  end
  self.xstream.selected_model_index_observable:add_notifier(selected_model_index_notifier)
  selected_model_index_notifier()
  self.vb_content = content

end

--------------------------------------------------------------------------------

function xStreamUI:disable_model_controls()

  local view
  view = self.vb.views["xStreamCallbackEditor"]
  view.text = ""
  if (renoise.API_VERSION > 4) then
    view.active = false
  end
  for k,v in ipairs(xStreamUI.MODEL_CONTROLS) do
    self.vb.views[v].active = false
  end

  self.vb.views["xStreamArgsContainer"].visible = false
  self.vb.views["xStreamArgPresetContainer"].visible = false

end


--------------------------------------------------------------------------------

function xStreamUI:enable_model_controls()

  local view
  view = self.vb.views["xStreamCallbackEditor"]
  if (renoise.API_VERSION > 4) then
    view.active = true
  end
  for k,v in ipairs(xStreamUI.MODEL_CONTROLS) do
    --print("enable_model_controls",k,v)
    self.vb.views[v].active = true
  end
  self.vb.views["xStreamArgsContainer"].visible = true
  self.vb.views["xStreamArgPresetContainer"].visible = true

end

--------------------------------------------------------------------------------

function xStreamUI:get_show_editor()
  return self.show_editor_observable.value 
end

function xStreamUI:set_show_editor(val)
  TRACE("xStreamUI:set_show_editor(val)",val)

  assert(type(val) == "boolean", "Wrong argument type")
  self.show_editor_observable.value = val

  local view = self.vb.views["xStreamCallbackEditor"]
  local view_bt = self.vb.views["xStreamCallbackEdit"]
  local view_compile = self.vb.views["xStreamCallbackCompile"]
  local view_live_coding = self.vb.views["xStreamLiveCoding"]
  if val then
    view.visible = true
    view_bt.color = xLib.COLOR_ENABLED 
    view_compile.visible = true
    view_live_coding.visible = true
  else
    view.visible = false
    view_bt.color = xLib.COLOR_DISABLED 
    view_compile.visible = false
    view_live_coding.visible = false
  end

end

--------------------------------------------------------------------------------

function xStreamUI:toggle_code_editor()
  local view = self.vb.views["xStreamCallbackEditor"]
  if view.visible then
    self.show_editor = false
  else
    self.show_editor = true
  end
end

--------------------------------------------------------------------------------
-- present the user with a popup containing a text editor, fill it with
-- a blank model template and pass it on to xStream 

function xStreamUI:delete_model()

  local choice = renoise.app():show_prompt("Delete model",
      "Are you sure you want to delete this model \n"
    .."(this action can not be undone)?",
    {"OK","Cancel"})
  
  if (choice == "OK") then
    local model_idx = self.xstream.selected_model_index
    local success,err = self.xstream:delete_model(model_idx)
    if not success then
      renoise.app():show_error(err)
    end
  end

end

--------------------------------------------------------------------------------
-- present the user with a popup containing a text editor, fill it with
-- a blank model template and pass it on to xStream 

function xStreamUI:create_model()
  TRACE("xStreamUI:create_model()")

  local model = xStreamModel(self.xstream)
  local str_name,err = xDialog.prompt_for_string(model.name,
    "Enter a name for the model","Create Model")
  if not str_name then
    return
  end

  model.modified = true
  model.name = str_name
  model.file_path = ("%s%s.lua"):format(self.xstream.last_models_path,str_name)
  model:parse_definition({
    callback = [[-------------------------------------------------------------------------------
-- Empty configuration
-------------------------------------------------------------------------------

-- Use this as a template for your own creations. 
--xline.note_columns[1].note_string = "C-4"
    
]],
  })

  local model_str = model:serialize()

  self.xstream:add_model(model)
  self.xstream.selected_model_index = #self.xstream.models

end

--------------------------------------------------------------------------------

function xStreamUI:rename_model()
  TRACE("xStreamUI:rename_model()")

  local model = self.xstream.selected_model

  local str_name,err = xDialog.prompt_for_string(model.name,
    "Enter a new name","Rename Model")
  if not str_name then
    return
  end

  local str_from = model.file_path
  local folder,filename,ext = xFilesystem.get_path_parts(str_from)

  if not xFilesystem.validate_filename(str_name) then
    renoise.app():show_error("Please avoid using special characters in the name")
    return 
  end

  local str_to = ("%s%s.lua"):format(folder,str_name)
  print("str_from,str_to",str_from,str_to)

  if not os.rename(str_from,str_to) then
    renoise.app():show_error("Failed to rename, perhaps the file is in use by another application?")
    return 
  end

  model.name = str_name
  model.file_path = str_to
  
  self:update()

end
