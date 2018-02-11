--[[===============================================================================================
-- AutoMateSandboxUI.lua
===============================================================================================]]--

--[[--

User interface for AutoMates' sandbox-based generators/transformers 

--]]

--=================================================================================================

local MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
local DIALOG_W = 270
local SUBMIT_BT_H = 22
local LABEL_W = 60
local CONTENT_W = DIALOG_W-(LABEL_W+10)
local SLIDER_W = 120

---------------------------------------------------------------------------------------------------

class 'AutoMateSandboxUI' (vDialog)

function AutoMateSandboxUI:__init(owner,title)

  --- AutoMateGenerators | AutoMateTransformers
  self._owner = owner 

  --- (AutoMate.TARGET)
  self.target = property(self._get_target,self._set_target)
  self._target = nil

  vDialog.__init(self,{
    --waiting_to_show_dialog = prefs.autorun_enabled.value,
    dialog_title = title,
    --dialog_keyhandler = self.dialog_keyhandler
  })
  
  self._update_presets_requested = false
  self._update_actions_requested = false
  self._update_target_requested = false

  -- ViewBuilder
  self._row_container = nil
  self._rows = {}


  -- observables ----------------------

  self._owner.presets_observable:add_notifier(function()
    print(">>> AutoMateSandboxUI - presets_observable fired...")
    self._update_presets_requested = true
  end)
  self._owner.selected_preset_observable:add_notifier(function()
    print(">>> AutoMateSandboxUI - selected_preset_observable fired...")
    self._update_presets_requested = true
    self:_build_control_rows()
  end)

  self._owner._app.parameter_changed_observable:add_notifier(function()
    self._update_actions_requested = true
    self._update_target_requested = true
  end)
  self._owner._app.device_changed_observable:add_notifier(function()
    self._update_actions_requested = true
    self._update_target_requested = true
  end)
  prefs.selected_tab:add_notifier(function()
    self._update_actions_requested = true
    self._update_target_requested = true
  end)

  renoise.tool().app_idle_observable:add_notifier(self,self.on_idle)

  
end  

---------------------------------------------------------------------------------------------------
-- vDialog methods
---------------------------------------------------------------------------------------------------

function AutoMateSandboxUI:create_dialog()
  TRACE("AutoMateSandboxUI:create_dialog()")

  if not self._view then 
    self._view = self:_build()
  end

  return self._view

end

---------------------------------------------------------------------------------------------------
-- Getters & Setters
---------------------------------------------------------------------------------------------------

function AutoMateSandboxUI:_get_target()
  return self._target
end

function AutoMateSandboxUI:_set_target(val)
  assert(type(val)=="number")
  self._target = val
  self._update_target_requested = true
  self._update_actions_requested = true
end

---------------------------------------------------------------------------------------------------
-- Class methods
---------------------------------------------------------------------------------------------------

function AutoMateSandboxUI:_build()
  TRACE("AutoMateSandboxUI:_build()")

  local vb = self.vb

  self._row_container = vb:column{
    margin = MARGIN
  }
  
  local view = vb:column{
    id = 'rootnode',
    width = DIALOG_W,
    vb:column{
      self:_build_target_display(),
      self:_build_preset_selector(),
      self._row_container,
      self:_build_control_rows(),
      self:_build_lower_toolbar()
    },
  }

  self.update_requested = true
  return view

end

---------------------------------------------------------------------------------------------------

function AutoMateSandboxUI:_build_target_display()
  
  local vb = self.vb 

  return vb:row{
    style = "body",
    vb:horizontal_aligner{
      width = DIALOG_W,
      mode = "justify",
      margin = MARGIN,
      vb:row{
        vb:text{
          text = "Target",
          width = LABEL_W,
        },
        vb:text{
          id = "target_text",
          text = "",
          font = "mono",
        },
      },
    },
  }

end 

---------------------------------------------------------------------------------------------------

function AutoMateSandboxUI:_build_preset_selector()

  local vb = self.vb 

  return vb:row{
    style = "panel",
    margin = MARGIN,
    width = DIALOG_W,
    vb:row{
      vb:text{
        text = "Preset",
        width = LABEL_W,
      },
      vb:popup{
        id = "preset_selector",
        items = {},
        width = CONTENT_W-34,
        notifier = function(idx)
          local selector = vb.views["preset_selector"]            
          self._owner.selected_preset_name = selector.items[idx]
        end
      },
      vb:button{
        --id = "preset_refresh",
        --text = "Refresh",
        bitmap = "images/refresh.bmp",
        tooltip = "Reload available presets from disk",
        notifier = function()
          self._owner:load_presets()
        end
      },
      vb:button{
        --id = "presets_reveal",
        --text = "Reveal",
        bitmap = "images/reveal_folder.bmp",
        tooltip = "Reveal folder containing presets",
        notifier = function()
          renoise.app():open_path(AutoMateGenerators.get_path())
        end
      },
    },
  }

end 

---------------------------------------------------------------------------------------------------

function AutoMateSandboxUI:_build_control_rows()
  TRACE("AutoMateSandboxUI:_build_control_rows()")

  self:_unbuild_control_rows()
  
  local vb = self.vb 

  local preset = self._owner.selected_preset
  if not preset then 
    return 
  end
  
  --print("preset.arguments",rprint(preset.arguments))

  for k,v in ipairs(preset.arguments) do 
    local row = self:_build_control_row(v)
    self._row_container:add_child(row)
    table.insert(self._rows,row)
  end
  return self._row_container

end

---------------------------------------------------------------------------------------------------

function AutoMateSandboxUI:_unbuild_control_rows()
  TRACE("AutoMateSandboxUI:_unbuild_control_rows()")

  for k,v in ipairs(self._rows) do 
    self._row_container:remove_child(v)
  end

  self._rows = {}

end

---------------------------------------------------------------------------------------------------
-- @param arg (AutoMateSandboxArgument)

function AutoMateSandboxUI:_build_control_row(arg)
  TRACE("AutoMateSandboxUI:_build_control_row(arg)",arg)

  assert(type(arg)=="AutoMateSandboxArgument")
  --print(type(arg))

  local vb = self.vb 

  local switch = {
    [AutoMateSandboxArgument.DISPLAY_AS.MINISLIDER] = function()
      local readout = vb:value{
        value = arg.value
      }
      return vb:row{
        vb:minislider{
          width = SLIDER_W,
          value = arg.value,
          min = arg.value_min,
          max = arg.value_max,
          notifier = function(val)
            arg.value = val
            readout.value = val
          end
        },
        readout,
      } 
    end,
    [AutoMateSandboxArgument.DISPLAY_AS.VALUEBOX] = function()
      return vb:valuebox{
        --width = SLIDER_W,
        value = arg.value,
        min = arg.value_min,
        max = arg.value_max,
        notifier = function(val)
          arg.value = val
        end
      }  
    end,
    [AutoMateSandboxArgument.DISPLAY_AS.POPUP] = function()
      return vb:popup{
        width = SLIDER_W,
        value = arg.value,
        --min = arg.value_min,
        --max = arg.value_max,
        items = arg.value_enums,
        notifier = function(idx)
          arg.value = idx
        end
      }  
    end
  }

  local display_ctrl = nil
  if switch[arg.display_as] then 
    display_ctrl = switch[arg.display_as]()
  else 
    error("Unknown/unsupported value for 'display_as'"..tostring(arg.display_as))
  end

  return vb:row{
    vb:text{
      text = arg.name,
      width = LABEL_W,
    },
    display_ctrl,
  }

end


---------------------------------------------------------------------------------------------------

function AutoMateSandboxUI:_build_lower_toolbar()

  local vb = self.vb 
  local is_generator = (type(self._owner)=="AutoMateGenerators") and true or false

  return vb:row{
    style = "body",
    vb:horizontal_aligner{
      mode = "justify",
      margin = MARGIN,
      width = DIALOG_W,
      --[[
      vb:row{
        vb:text{
          text = "Status: OK"
        },
      },
      ]]
      vb:row{
        margin = 2,
        vb:checkbox{
          value = is_generator and 
            prefs.realtime_generate.value or prefs.realtime_transform.value,
          notifier = function(val)
            if is_generator then 
              prefs.realtime_generate.value = val
            else 
              prefs.realtime_transform.value = val
            end
          end
        },
        vb:text{
          text = "Real-time",
        }
      },
      vb:row{
        vb:button{
          id = "apply_button",
          text = is_generator and "Generate Envelope" or "Transform Envelope",
          height = SUBMIT_BT_H,
          notifier = function()
            if is_generator then 
              self._owner._app:generate()
            else
            end 
          end
        },
        vb:button{
          text = "Close",
          height = SUBMIT_BT_H,
          notifier = function()
            self:close()
          end
        }
      }
    }
  }


end

---------------------------------------------------------------------------------------------------
--- Update the entire UI (all update_xx methods...)

function AutoMateSandboxUI:update()
  TRACE("AutoMateSandboxUI:update()")

  self:_update_presets()
  self:_update_actions()

end

---------------------------------------------------------------------------------------------------

function AutoMateSandboxUI:_update_presets()
  TRACE("AutoMateSandboxUI:_update_presets()")
  
  local vb = self.vb
  local items = {}

  for k,v in ipairs(self._owner.presets) do 
    table.insert(items,v.name)
  end

  local selector = vb.views["preset_selector"]
  selector.items = items

  -- always select a preset
  if not self._owner.selected_preset_name then 
    self._owner.selected_preset_name = selector.items[selector.value]
  else 
    for k,v in ipairs(items) do 
      if (v == self._owner.selected_preset_name) then 
        selector.value = k
      end
    end
  end

end

---------------------------------------------------------------------------------------------------

function AutoMateSandboxUI:_update_actions()
  TRACE("AutoMateSandboxUI:_update_actions()")
  
  local vb = self.vb

  local apply_active = false

  if (self._target == AutoMate.TARGET.DEVICE_PARAMETER) then 
    if (prefs.selected_tab.value == AutoMatePrefs.TAB_PARAMETERS) then
      local param = self._owner._app:_resolve_parameter()
      if param then
        apply_active = param.is_automatable
      end
    end
  end
  
  vb.views["apply_button"].active = apply_active


end  

---------------------------------------------------------------------------------------------------

function AutoMateSandboxUI:_update_target()
  TRACE("AutoMateSandboxUI:_update_target()")
  
  local vb = self.vb

  local target_txt = "-"

  if (self._target == AutoMate.TARGET.DEVICE_PARAMETER) then 
    if (prefs.selected_tab.value == AutoMatePrefs.TAB_PARAMETERS) then    
      local param = self._owner._app:_resolve_parameter()
      if param then
        target_txt = ("Param:%s"):format(param.name)
        if not param.is_automatable then 
          target_txt = ("%s (N/A)"):format(target_txt)
        end
      end
    end
  end
  
  vb.views["target_text"].text = target_txt
  vb.views["target_text"].width = CONTENT_W



end  

---------------------------------------------------------------------------------------------------
--- handle idle notifications

function AutoMateSandboxUI:on_idle()

  if not self._view then 
    return
  end

  if self.update_requested then
    self.update_requested = false
    self:update()
  end

  if self._update_presets_requested then
    self._update_presets_requested = false
    self:_update_presets()
  end

  if self._update_actions_requested then
    self._update_actions_requested = false
    self:_update_actions()
  end

  if self._update_target_requested then
    self._update_target_requested = false
    self:_update_target()
  end

  
end
