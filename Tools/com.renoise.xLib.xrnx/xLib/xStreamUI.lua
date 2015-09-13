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
  "xStreamStartButton",
  "xStreamStartPlayButton",
  "xStreamStopButton",
  "xStreamMuteButton",
  "xStreamUnmuteButton",
  "xStreamApplyTrackButton",
  "xStreamApplyTrackButton",
  "xStreamApplySelectionButton",
  "xStreamApplyLocallyButton",
  "xStreamExportPhraseButton",
  "xStreamExportFileButton",
  "xStreamCallbackCompile",
  "xStreamModelSave",
  "xStreamModelSaveAs",
  "xStreamRevealLocation",
  "xStreamImportPreset",
  "xStreamAddPreset",


}

-------------------------------------------------------------------------------
-- constructor
-- @param xstream (xStream)
-- @param vb (renoise.ViewBuilder)

function xStreamUI:__init(xstream,vb)

  self.xstream = xstream
  self.vb = vb

  self.vb_content = nil

  self.preset_views = {}
  self.model_views = {}
  self.arg_views = {}
  
  self:build()
  self:update()

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

  local vb_container = vb.views["xStreamArgsContainer"]
  for k,v in ipairs(self.arg_views) do
    vb_container:remove_child(v)
  end

  self.arg_views = {}

  if (self.xstream.selected_model.args.length == 0) then
    return
  end

  for k,arg in ipairs(self.xstream.selected_model.args.args) do

    -- add a custom control for each argument
    --print("k,arg.name",k,arg.name)
    --print("k,arg.observable",arg.observable,type(arg.observable))
    --print("k,arg.properties.zero_based",arg.properties.zero_based)

    -- custom number/string converters 
    local fn_tostring = nil
    local fn_tonumber = nil
    
    print("arg.properties",rprint(arg.properties))

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
      print("arg.properties.display_as_note")
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

    local view

    if (type(arg.observable) == "ObservableNumber") then

      local slider_width = 100
      local full_width = 180

      if arg.properties.items then
        local display = arg.properties.display or "popup"
        if (display == "popup") then
          view = vb:row{
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
          }
        elseif (display == "chooser") then
          view = vb:row{
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
          }
        elseif (display == "switch") then
          view = vb:row{
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
          }
        end

      elseif (arg.properties.quant == 1) then
        -- integer value
        view = vb:row{
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
        }

      else
        -- slider/number

        view = vb:row{
          tooltip = arg.description,
          vb:text{
            text = arg.name,
            font = "mono",
          },
        }

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

      view = vb:row{
        tooltip = arg.description,
        vb:text{
          text = arg.name,
          font = "mono",
        },
        vb:checkbox{
          value = arg.value,
          bind = arg.observable,
        },
      }

    elseif (type(arg.observable) == "ObservableString") then

      view = vb:row{
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
      }

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
  --[[
  local vb_chooser = vb.views["xStreamModelChooser"]
  local items = {"None"}
  for k,model in ipairs(self.xstream.models) do
    table.insert(items,model.name)
  end
  vb_chooser.items = items
  ]]

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

  local vb_container = vb.views["xStreamArgPresetContainer"]
  for k,v in ipairs(self.preset_views) do
    vb_container:remove_child(v)
  end

  self.preset_views = {}

  if (self.xstream.selected_model.args.length == 0) then
    return
  end

  local preset_node = self.xstream.selected_model.args.doc["Presets"]
  --print("preset_node",preset_node)
  
  for k = 1,#preset_node do
    --print(k,preset_node[k])
    
    local preset_name = self.xstream.selected_model.args.preset_names[k] or 
      self.xstream.selected_model.args.get_suggested_preset_name(k)

    local color = (self.xstream.selected_model.args.selected_preset_index == k)
      and xLib.COLOR_ENABLED or xLib.COLOR_DISABLED

    local row = vb:row{
      vb:button{
        text = "-",
        --color = color,
        notifier = function()
          self.xstream.selected_model.args:remove_preset(k)
          self:update_presets()
        end
      },
      vb:button{
        text = preset_name,
        color = color,
        notifier = function()
          self.xstream.selected_model.args:recall_preset(k)
          self:update_presets()
        end
      },
      vb:button{
        text = "Rename",
        --color = color,
        notifier = function()
          self.xstream.selected_model.args:rename_preset(k)
          self:update_presets()
        end
      },
      vb:button{
        text = "Update",
        --color = color,
        notifier = function()
          self.xstream.selected_model.args:update_preset(k)
          self:update_presets()
        end
      },
      vb:button{
        text = "Export",
        --color = color,
        notifier = function()
          self.xstream.selected_model.args:export_preset(k)
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

  local vb = self.vb
  local view = vb.views["xStreamCallbackEditor"]
  local model = self.xstream.selected_model
  local str_fn = model.callback_str or "Undefined"
  view.text = str_fn

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
        font = "bold",
      },
      vb:multiline_textfield{
        text = "Here be lua...",
        font = "mono",
        height = 200,
        width = 500,
        id = "xStreamCallbackEditor",
        notifier = function(str)
          local model = self.xstream.selected_model
          if model then
            -- note: add extra line to avoid end of string being
            -- truncated, one line at a time... 
            model.callback_str = str .. "\n" 
          end
        end,

      },
      vb:horizontal_aligner{
        mode = "justify",
        vb:row{
          vb:button{
            text = "compile",
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
          vb:button{
            text = "save",
            id = "xStreamModelSave",
            notifier = function()
              local passed,err = self.xstream.selected_model:save()
              if not passed then
                renoise.app():show_warning(err)
              end 
            end,
          },
          vb:button{
            text = "save_as",
            id = "xStreamModelSaveAs",
            notifier = function()
              local passed,err = self.xstream.selected_model:save_as()          
              if not passed then
                renoise.app():show_warning(err)
              end 
            end,
          },
          vb:button{
            text = "reveal_location",
            id = "xStreamRevealLocation",
            notifier = function()
              self.xstream.selected_model:reveal_location()          
            end,
          },
          -- hackaround for clickable text
          vb:checkbox{
            value = false,
            width = 1,
            notifier = function()
              renoise.app():show_warning(
                "The callback returned the following error:\n"
                ..self.xstream.callback_status_observable.value
                .."\n\n(you can also see these messages in the scripting console)")
            end
          },
          vb:text{
            id = "xStreamCallbackStatus",
            --bind = self.xstream.callback_status_observable
            text = "",
          }
        },
        vb:row{
          vb:checkbox{
            bind = self.xstream.live_coding_observable
          },
          vb:text{
            text = "live coding"
          }
        }
      }
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
            text = "load_models",
            notifier = function()
              local str_path = renoise.app():prompt_for_path("Select folder containing models")
              if (str_path ~= "") then
                self.xstream:load_models(str_path)
              end
            end,
          },
          vb:button{
            text = "remove",
            id = "xStreamModelRemove",
            notifier = function()
              local model_idx = self.xstream.selected_model_index
              self.xstream:remove_model(model_idx)
            end,
          },
        },

        vb:column{
          id = 'xStreamModelContainer',
        }
        --[[
        vb:chooser{
          id = 'xStreamModelChooser',
          items = {"",""},
          bind = self.xstream.selected_model_index_observable,
        }
        ]]
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
              id = "xStreamStartButton",
              notifier = function(val)
                self.xstream:start()
              end,
            },
            vb:button{
              text = "start_and_play",
              id = "xStreamStartPlayButton",
              notifier = function(val)
                self.xstream:start_and_play()
              end,
            },
            vb:button{
              text = "stop",
              id = "xStreamStopButton",
              notifier = function(val)
                self.xstream:stop()
              end,
            },
          },
          vb:row{
            vb:button{
              text = "mute",
              id = "xStreamMuteButton",
              notifier = function(val)
                self.xstream:mute()
              end,
            },
            vb:button{
              text = "unmute",
              id = "xStreamUnmuteButton",
              notifier = function(val)
                self.xstream:unmute()
              end,
            },
          },
          vb:row{
            vb:button{
              text = "fill_track",
              id = "xStreamApplyTrackButton",
              notifier = function(val)
                self.xstream:fill_track()
              end,
            },
            vb:button{
              text = "fill_selection",
              id = "xStreamApplySelectionButton",
              notifier = function()
                self.xstream:fill_selection()
              end,
            },
            vb:button{
              text = "locally",
              id = "xStreamApplyLocallyButton",
              notifier = function()
                self.xstream:fill_selection(true)
              end,
            },
          },
          vb:button{
            text = "export_to_phrase",
            id = "xStreamExportPhraseButton",
            notifier = function(val)
              local instr_idx = rns.selected_instrument_index
              self.xstream:export_to_phrase(instr_idx)
            end,
          },
          vb:button{
            text = "export_to_file",
            id = "xStreamExportFileButton",
            notifier = function(val)
              self.xstream:export_to_file()
            end,
          },
        },
        vb:column{
          style = "panel",
          margin = 4,
          vb:text{
            text = "properties",
            font = "bold",
          },
          vb:row{
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
            vb:checkbox{
              bind = self.xstream.include_hidden_observable,
            },
            vb:text{
              text = "include_hidden",
            },
          },
          vb:row{
            vb:checkbox{
              bind = self.xstream.clear_undefined_observable,
            },
            vb:text{
              text = "clear_undefined",
            },
          },
          vb:row{
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
        vb:text{
          text = "args",
          font = "bold",
        },
        --[[
        vb:value{
          height = 50,
          id = "xstream_producer_instr_idx",
          --value = instr_idx,
          bind = xstream.selected_model.args.instr_idx,
        },
        vb:rotary{
          height = 50,
          min = 0,
          max = 0x80,
          bind = xstream.selected_model.args.volume,
        },
        ]]
        -- TODO add args here
      },
      vb:column{
        style = "panel",
        margin = 4,
        vb:text{
          text = "presets",
          font = "bold",
        },
        vb:button{
          text = "import_preset()",
          id = "xStreamImportPreset",
          notifier = function(val)
            self.xstream.selected_model.args:import_preset()
            self:update_presets()
          end,
        },
        vb:button{
          text = "add_preset()",
          id = "xStreamAddPreset",
          notifier = function(val)
            self.xstream.selected_model.args:add_preset()
            self:update_presets()
          end,
        },
        vb:column{
          -- add buttons here
          id = 'xStreamArgPresetContainer',
        
        }
      },    
    }
  }

  --[[
  vb:column{
    style = "panel",
    vb:text{
      text = "scheduling",
    },
    vb:button{
      text = "LINE",
      notifier = function(val)
        xstream.scheduling = xStream.SCHEDULING.LINE
      end,
    },
    vb:button{
      text = "BEAT",
      notifier = function(val)
        xstream.scheduling = xStream.SCHEDULING.BEAT
      end,
    },
    vb:button{
      text = "BAR",
      notifier = function(val)
        xstream.scheduling = xStream.SCHEDULING.BAR
      end,
    },
    vb:button{
      text = "BLOCK",
      notifier = function(val)
        xstream.scheduling = xStream.SCHEDULING.BLOCK
      end,
    },
    vb:button{
      text = "PATTERN",
      notifier = function(val)
        xstream.scheduling = xStream.SCHEDULING.PATTERN
      end,
    },
  },
  vb:column{
    style = "panel",
    vb:text{
      text = "trigger",
    },
    vb:button{
      text = "LINE",
      notifier = function(val)
        xstream.scheduling = xStream.SCHEDULING.LINE
      end,
    },
    vb:button{
      text = "BEAT",
      notifier = function(val)
        xstream.scheduling = xStream.SCHEDULING.BEAT
      end,
    },
    vb:button{
      text = "BAR",
      notifier = function(val)
        xstream.scheduling = xStream.SCHEDULING.BAR
      end,
    },
    vb:button{
      text = "BLOCK",
      notifier = function(val)
        xstream.scheduling = xStream.SCHEDULING.BLOCK
      end,
    },
    vb:button{
      text = "PATTERN",
      notifier = function(val)
        xstream.scheduling = xStream.SCHEDULING.PATTERN
      end,
    },
  },
  ]]

  self.xstream.callback_status_observable:add_notifier(function()    
    TRACE("*** callback_status_observable fired...",self.xstream.callback_status_observable.value)
    
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
    --print("*** mute_mode_observable fired...",self.xstream.mute_mode)

  end)

  self.xstream.muted_observable:add_notifier(function()    
    --print("*** muted_observable fired...",self.xstream.muted)
    local view = vb.views["xStreamMuteButton"]
    local color = self.xstream.muted 
      and xLib.COLOR_ENABLED or xLib.COLOR_DISABLED
    view.color = color
  end)

  self.xstream.active_observable:add_notifier(function()    
    --print("*** active_observable fired...",self.xstream.active)
    local view = vb.views["xStreamStartButton"]
    local color = self.xstream.active 
      and xLib.COLOR_ENABLED or xLib.COLOR_DISABLED
    view.color = color
  end)

  self.xstream.models_observable:add_notifier(function()
    self:update_models()
  end)

  local model_name_notifier = function()
    --print("*** xstream.selected_model.name_observable fired...",self.xstream.selected_model.name)
    self:update_models()
  end
  
  local model_modified_notifier = function()
    --print("*** xstream.selected_model.callback_str_observable fired...")
    local view = vb.views["xStreamCallbackCompile"]
    view.active = self.xstream.selected_model.modified
  end
  
  local selected_model_index_notifier = function()
    --print("*** xstream.selected_model_index_observable fired...",self.xstream.selected_model_index)
    -- attach to model 
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





