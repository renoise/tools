--[[===============================================================================================
-- AutoMateUI.lua
===============================================================================================]]--

--[[--

# AutoMate

--]]

--=================================================================================================

local MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
local DIALOG_W = 205
local BUTTON_H = 21
local NULL_MARGIN = -3
local CONTENT_W = DIALOG_W - (2*MARGIN)
local ACTION_BT_W = CONTENT_W/3
local LEFT_COL_W = CONTENT_W/4
local RIGHT_COL_W = CONTENT_W-82
local SCOPES_W = CONTENT_W-42
local TABLE_W = CONTENT_W-2
local TABLE_ROWS = 8
local TABLE_ROW_H = 16
local TABLE_BITMAP_W = 18
local TABLE_SCROLL_W = 18
local BITMAP_AUTOMATED_UNKNOWN = "images/AutomationList_Unknown.bmp"
local BITMAP_AUTOMATED_ACTIVE = "images/AutomationList_Active.bmp"
local BITMAP_AUTOMATED_EMPTY = "images/AutomationList_Empty.bmp"
local BITMAP_AUTOMATED_NONE = "images/AutomationList_None.bmp"
local ROW_STYLE_SELECTED = "body"
local ROW_STYLE_NORMAL = "plain"

-- NB: relies on AutoMatePrefs.SCOPE_XX
local SCOPE_NAMES = {
  "Whole Song",
  "Whole Pattern",
  "Selection in Sequence",
  "Selection in Pattern",
}

---------------------------------------------------------------------------------------------------
-- Constructor method

class 'AutoMateUI' (vDialog)

function AutoMateUI:__init(app)
  TRACE("AutoMateUI:__init(app)",app)

  --- initialize our super-class
  vDialog.__init(self,{
    waiting_to_show_dialog = prefs.autorun_enabled.value,
    dialog_title = "AutoMate",
    dialog_keyhandler = self.dialog_keyhandler
  })
  
  --- (AutoMate) instance of main class
  self._app = app

  --- (renoise.Views.View) 
  self._view = nil 

  --- (boolean) true while app is performing a sliced process
  self._is_processing = property(self.get_is_processing)

  --- various controls
  --self._options_bt = nil
  self._device_vtable = nil
  self._param_vtable = nil

  --- (bool)
  self.update_requested = false
  self.update_tracks_requested = false
  self.update_devices_requested = false
  self.update_params_requested = false
  self.update_actions_requested = false
  self.update_status_requested = false
  self.update_tabs_requested = false
  self.update_options_requested = false

  -- observables ----------------------

  self._app.clipboard_observable:add_notifier(self,function()
    --print("clipboard_observable fired...")
    self.update_actions_requested = true
  end)

  self._app.status_observable:add_notifier(self,function()
    --print("status_observable fired...")
    if self._app.active then
      if self._is_processing then
        -- update right away
        self:_update_active_state()
        self:_update_status()
        self:_update_actions()
      else
        self.update_actions_requested = true
        self.update_status_requested = true
        self.update_active_state_requested = true
      end        
    end
  end)

  self._app.device_changed_observable:add_notifier(self,function()
    --print(">>> device_changed_observable fired...")
    self.update_devices_requested = true    
    self.update_params_requested = true    
    self.update_actions_requested = true     
  end)

  self._app.parameter_changed_observable:add_notifier(self,function()
    --print(">>> parameter_changed_observable fired...")
    self.update_params_requested = true    
    self.update_actions_requested = true    
  end)

  self._app.track_changed_observable:add_notifier(self,function()
    --print(">>> track_changed_observable fired...")
    self.update_tracks_requested = true
    self.update_devices_requested = true
    self.update_params_requested = true
  end)

  renoise.tool().app_idle_observable:add_notifier(self,self.on_idle)
  

end

---------------------------------------------------------------------------------------------------
-- vDialog methods
---------------------------------------------------------------------------------------------------

function AutoMateUI:create_dialog()
  TRACE("AutoMateUI:create_dialog()")

  if not self._view then 
    self._view = self:build()
  end

  return self._view

end

---------------------------------------------------------------------------------------------------
-- Getter/Setter methods
---------------------------------------------------------------------------------------------------
--- @return boolean

function AutoMateUI:get_is_processing()
  return ((self._app.status_observable.value == AutoMate.STATUS.COPYING) 
    or (self._app.status_observable.value == AutoMate.STATUS.PASTING)
    or (self._app.status_observable.value == AutoMate.STATUS.GENERATING))
      and true or false
end

---------------------------------------------------------------------------------------------------
-- Class methods 
---------------------------------------------------------------------------------------------------
-- Keyhandler 
--
-- CMD/CTRL + X : Cut 
-- CMD/CTRL + C : Copy 
-- CMD/CTRL + C : Paste 
-- Delete       : Clear
-- Up           : Previous parameter/device
-- Down         : Next parameter/device
-- Left         : Shift scope backward
-- Right        : Shift scope forward

function AutoMateUI:dialog_keyhandler(dialog,key)
  TRACE("AutoMateUI:dialog_keyhandler(dialog,key)",dialog,key)
  
  local key_was_handled = false
  local param_tab_selected = (prefs.selected_tab.value == AutoMatePrefs.TAB_PARAMETERS)
  --local device_tab_selected = (prefs.selected_tab.value == AutoMatePrefs.TAB_DEVICES)

  local done_callback = function(success,msg_or_err)
    if msg_or_err then 
      renoise.app():show_status(msg_or_err)
    end
  end
  
  if (key.modifiers == "") then 
    local switch = {
      ["up"] = function()
        if param_tab_selected then 
          self._app:select_previous_parameter()
        else -- if device_tab_selected then 
          self._app:select_previous_device()
        end
      end,
      ["down"] = function()
        if param_tab_selected then 
          self._app:select_next_parameter()
        else -- if device_tab_selected then 
          self._app:select_next_device()
        end
      end,
      ["left"] = function()
        self._app:select_previous_scope()
      end,
      ["right"] = function()
        self._app:select_next_scope()
      end,
      ["del"] = function()
        self._app:clear(done_callback)
      end,
    }
    if switch[key.name] then 
      switch[key.name]()
      key_was_handled = true
    end      

  elseif (key.modifiers == "control") then
    local switch = {
      ["x"] = function()
        self._app:cut(done_callback)
      end,
      ["c"] = function()
        self._app:copy(done_callback)
      end,
      ["v"] = function()
        self._app:paste(done_callback)
      end,
    }
    if switch[key.name] then 
      switch[key.name]()
      key_was_handled = true
    end
    
  end

  -- allow forwarding keystrokes to Renoise 
  if not key_was_handled then
    return key
  end

end

---------------------------------------------------------------------------------------------------
--- Build

function AutoMateUI:build()
  TRACE("AutoMateUI:build()")

  local vb = self.vb
  local view = vb:column{
    id = 'app_rootnode',
    width = DIALOG_W,
    vb:column{
      margin = MARGIN,
      spacing = MARGIN,
      self:_build_tabs(),
      self:_build_scopes_panel(),
      self:_build_actions_panel(),
      self:_build_status_panel(),
    }
  }

  self.update_requested = true
  return view

end

---------------------------------------------------------------------------------------------------

function AutoMateUI:_build_tabs()
  local vb = self.vb
  self._vtabs = vTabs{
    vb = vb,
    id = "vTabs",
    tooltip = "vTabs",
    --index = 1,
    --midi_mapping = "Global:vTabs:vLib_demo",
    labels = {"Devices","Parameters","Options"},
    width = CONTENT_W,
    --height = 175,
    --layout = vTabs.LAYOUT.BELOW,
    --size_method = vTabs.SIZE_METHOD.FIXED,
    --switcher_align = vTabs.SWITCHER_ALIGN.LEFT,
    switcher_width = CONTENT_W,
    --switcher_height = 24,
    tabs = {
      self:_build_tab_devices(),
      self:_build_tab_parameters(),
      self:_build_options_panel(),
    },
    notifier = function(elm)
      prefs.selected_tab.value = elm.index
      self:_update_tabs() -- avoid flicker
      self.update_actions_requested = true
    end,

  }

  return self._vtabs.view

end  

---------------------------------------------------------------------------------------------------

function AutoMateUI:_build_tab_devices()

  local vb = self.vb
  return vb:column{
    id = 'app_tab_devices',

    -- NAVIGATION

    vb:row{
      margin = MARGIN,
      spacing = NULL_MARGIN,
      vb:text{
        text = "Track",
        width = LEFT_COL_W,
      },
      vb:popup{
        id = "device_tab_track_select",
        items = {},
        width = RIGHT_COL_W,
        notifier = function(idx)
          self._app.selected_track_idx = idx
        end
      },
      vb:row{
        spacing = NULL_MARGIN,
        vb:button{
          text = "◂",
          notifier = function()
            self._app:select_previous_track()
          end,
        },
        vb:button{
          text = "▸",
          notifier = function()
            self._app:select_next_track()
          end,
        },
      }         
    },
    -- make tabs the same height
    vb:space{
      height = 2,
    },
    self:_build_device_table(),
  }

end

---------------------------------------------------------------------------------------------------

function AutoMateUI:_build_tab_parameters()

  local vb = self.vb
  return vb:column{
    id = 'app_tab_parameters',

    -- NAVIGATION    
    vb:column{
      margin = MARGIN,
      vb:row{
        spacing = NULL_MARGIN,
        vb:text{
          text = "Track",
          width = LEFT_COL_W,
        },
        vb:popup{
          id = "param_tab_track_select",
          items = {},
          width = RIGHT_COL_W,
          notifier = function(idx)
            self._app.selected_track_idx = idx
          end
        },
        vb:row{
          spacing = NULL_MARGIN,
          vb:button{
            text = "◂",
            notifier = function()
              self._app:select_previous_track()
            end,
          },
          vb:button{
            text = "▸",
            notifier = function()
              self._app:select_next_track()
            end,
          },
        }        
      },
      vb:row{
        spacing = NULL_MARGIN,
        vb:text{
          text = "Device",
          width = LEFT_COL_W,
        },
        vb:popup{
          id = "param_tab_device_select",
          items = {},
          width = RIGHT_COL_W,
          notifier = function(idx)
            self._app.selected_device_idx = idx - 1
          end
        },
        vb:row{
          spacing = NULL_MARGIN,
          vb:button{
            text = "◂",
            notifier = function()
              self._app:select_previous_device()
            end,
          },
          vb:button{
            text = "▸",
            notifier = function()
              self._app:select_next_device()
            end,
          },
        }         
      },
    },

    self:_build_param_table(),


  }

end

---------------------------------------------------------------------------------------------------

function AutoMateUI:_build_device_table()

  local vb = self.vb
  self._device_vtable = vTable{
    --id = "app_vtable_params",
    vb = vb,
    width = TABLE_W,
    --height = 300,
    scrollbar_width = TABLE_SCROLL_W,
    row_height = TABLE_ROW_H,
    --header_height = 30,
    --show_header = false,
    row_style = "invisible",
    cell_style = "invisible",
    num_rows = TABLE_ROWS,
    column_defs = {
      {
        key = "status_bitmap",
        col_width = TABLE_BITMAP_W, 
        col_type = vTable.CELLTYPE.BITMAP, 
        --tooltip="",
      },       
      {
        key = "name",    
        col_width="auto", 
        --tooltip="This is some text",
        notifier=function(cell,val)
          local item = self._device_vtable:get_item_by_id(cell[vDataProvider.ID])          
          self._app.selected_device_idx = item.index
        end
      },
    },
    --header_defs = {},
    --data = {},
    --on_scroll = function()
    --end,
    --on_resize = function()
    --end,
      
  }
  self._device_vtable.show_header = false
  return self._device_vtable.view

end

---------------------------------------------------------------------------------------------------

function AutoMateUI:_build_param_table()

  local vb = self.vb
  self._param_vtable = vTable{
    --id = "app_vtable_params",
    vb = vb,
    width = TABLE_W,
    --height = 300,
    scrollbar_width = TABLE_SCROLL_W,
    row_height = TABLE_ROW_H,
    --header_height = 30,
    row_style = "invisible",
    cell_style = "invisible",
    show_header = false,
    num_rows = TABLE_ROWS-1,
    column_defs = {
      {
        key = "status_bitmap",
        col_width = TABLE_BITMAP_W, 
        col_type=vTable.CELLTYPE.BITMAP, 
        --tooltip="",
      },      
      {
        key = "name",    
        col_width="auto", 
        --tooltip="This is some text",
        notifier=function(cell,val)
          local item = self._param_vtable:get_item_by_id(cell[vDataProvider.ID])
          --print("clicked row",item.index)
          self._app.selected_parameter_idx = item.index
          self.update_params_requested = true
        end
      },
    },
    --header_defs = {},
    --data = {},
    --on_scroll = function()
    --end,
    --on_resize = function()
    --end,
      
  }
  self._param_vtable.show_header = false
  return self._param_vtable.view

end


---------------------------------------------------------------------------------------------------

function AutoMateUI:_build_scopes_panel()
    
  local vb = self.vb
  return vb:column{
    id = "app_scopes_panel",    
    style = "group",
    margin = MARGIN,
    vb:horizontal_aligner{
      mode = "justify",
      vb:chooser{
        id = "app_scopes_chooser",
        bind = prefs.selected_scope,
        items = SCOPE_NAMES,
        width = SCOPES_W,
        notifier = function()
          self:_update_scopes()
        end
      },
      vb:row{
        spacing = NULL_MARGIN,
        vb:button{
          id = "app_scopes_flick_previous",
          text = "◂",
          tooltip = "Flick to previous within scope",
          notifier = function()
            self._app:select_previous_scope()
          end,
        },
        vb:button{
          id = "app_scopes_flick_next",
          text = "▸",
          tooltip = "Flick to next within scope",
          notifier = function()
            self._app:select_next_scope()
          end,
        },
      }
    },

  }

end  

---------------------------------------------------------------------------------------------------

function AutoMateUI:_build_actions_panel()

  local done_callback = function(success,msg_or_err)    
    if msg_or_err then 
      if success then 
        renoise.app():show_status(msg_or_err)
      else
        renoise.app():show_warning(msg_or_err)
      end
    end
  end

  local vb = self.vb
  return vb:column{
    id = "app_actions_panel",
    vb:row{
      vb:button{
        id = "app_action_cut",
        text = "Cut",
        width = ACTION_BT_W,
        notifier = function()
          self._app:cut(done_callback)
        end
      },
      vb:button{
        id = "app_action_copy",
        text = "Copy",
        width = ACTION_BT_W,
        notifier = function()
          self._app:copy(done_callback)
        end
      },
      vb:button{
        id = "app_action_paste",
        text = "Paste",
        width = ACTION_BT_W,
        notifier = function()
          self._app:paste(done_callback)
        end,
      },
    },
    vb:row{
      vb:button{
        id = "app_action_clear",
        text = "Clear",
        width = ACTION_BT_W,
        notifier = function()
          self._app:clear(done_callback)
        end
      },           
      vb:button{
        id = "app_action_move",
        text = "Move",
        width = ACTION_BT_W,
      },
      vb:button{
        id = "app_action_swap",
        text = "Swap",
        width = ACTION_BT_W,
      },
    },
    vb:space{
      height = 3,
    },
    vb:row{
      vb:button{
        id = "app_action_generate",
        text = "Generate",
        width = ACTION_BT_W,
        notifier = function()
          self._app:show_generate_dialog(AutoMate.TARGET.DEVICE_PARAMETER)
        end
      },
      vb:button{
        id = "app_action_transform",
        text = "Transform",
        width = ACTION_BT_W,
        notifier = function()
          self._app:show_transform_dialog()
        end
      },
      vb:row{
        spacing = NULL_MARGIN,
        vb:button{
          id = "app_action_add_to_library",
          text = "+",
          tooltip = "Add to Library",
          width = BUTTON_H,
          notifier = function()
            self._app:add_to_library()
          end
        },
        vb:button{
          text = "Library",
          tooltip = "Use the Library to store and recall presets",
          width = ACTION_BT_W-BUTTON_H,
          notifier = function()
            self._app:show_library()
          end
        },
      }
    }
  
  }

end

---------------------------------------------------------------------------------------------------

function AutoMateUI:_build_status_panel()

  local vb = self.vb

  return vb:column{
    width = CONTENT_W-2,
    style = "group",
    vb:horizontal_aligner{      
      mode = "justify",
      width = "100%",
      margin = 2,
      vb:text{
        id = "app_status_readout",
        text = "Welcome to AutoMate",
      },
      vb:row{
        vb:button{
          id = "app_status_cancel_processing",
          text = "Cancel",
          notifier = function()
            self._app.slicer:stop()
          end
        },
      }
    }
  }

end

---------------------------------------------------------------------------------------------------

function AutoMateUI:_build_options_panel()

  local vb = self.vb

  return vb:column{
    spacing = MARGIN,
    width = CONTENT_W,
    vb:column{
      margin = MARGIN,
      style = "group",
      width = "100%",
      vb:text{
        text = "General Options",
        font = "bold",
      },
      vb:column{
        vb:row{
          vb:checkbox{
            bind = prefs.autorun_enabled,
          },
          vb:text{
            text = "Auto-start tool"
          },
        },
      },      
    },
    --[[
    vb:column{
      margin = MARGIN,
      style = "group",
      width = "100%",
      vb:text{
        text = "Generate & Transform",
        font = "bold",
      },
      vb:column{
        vb:row{
          vb:checkbox{
            id = "app_options_realtime_checkbox",
            notifier = function(val)

            end
          },
          vb:text{
            text = "Apply changes in real-time"
          },
        },
      },
    },
    vb:column{
      margin = MARGIN,
      style = "group",
      width = "100%",
      vb:text{
        text = "Paste Options",
        font = "bold",
      },
      vb:column{
        vb:row{
          vb:checkbox{
            id = "app_options_mix_paste",
            notifier = function(val)

            end
          },
          vb:text{
            text = "Mix-Paste"
          },
        },
        vb:row{
          vb:checkbox{
            id = "app_options_continuous_paste",
            notifier = function(val)

            end
          },
          vb:text{
            text = "Continuous Paste"
          },
        },
      },
    },
    ]]
    vb:column{
      margin = MARGIN,
      style = "group",
      width = "100%",
      vb:text{
        text = "Advanced Options",
        font = "bold",
      },
      vb:column{
        vb:row{
          vb:checkbox{
            id = "app_options_yield_checkbox",
            --value = false,
            notifier = function(val)
              local vb = self.vb
              if val then 
                prefs.yield_at.value = vb.views["app_options_yield_popup"].value+1
              else
                prefs.yield_at.value = xLib.YIELD_AT.NONE
              end
              self.update_options_requested = true
            end
          },
          vb:text{
            text = "Throttle"
          },
          vb:popup{
            id = "app_options_yield_popup",
            width = CONTENT_W - 66,
            items = {
              "Slow: Pattern",
              "Fast: Parameter",
            },
            notifier = function(val)
              prefs.yield_at.value = val+1
              self.update_options_requested = true              
            end
          }
        },
      },
    },
  }

end

---------------------------------------------------------------------------------------------------
--- Update the entire UI (all update_xx methods...)

function AutoMateUI:update()
  TRACE("AutoMateUI:update()")

  self:_update_tabs()
  self:_update_tracks()
  self:_update_devices()
  self:_update_params()
  self:_update_actions()
  self:_update_options()
  self:_update_active_state()
  self:_update_scopes()
  self:_update_status()

end

---------------------------------------------------------------------------------------------------

function AutoMateUI:_update_tabs()
  TRACE("AutoMateUI:_update_tabs()")
  
  local vb = self.vb
  local is_options_tab = (prefs.selected_tab.value == AutoMatePrefs.TAB_OPTIONS) 

  vb.views["app_scopes_panel"].visible = not is_options_tab
  vb.views["app_actions_panel"].visible = not is_options_tab
  
  self._vtabs.index = prefs.selected_tab.value


end

---------------------------------------------------------------------------------------------------
-- populate track list

function AutoMateUI:_update_tracks()
  TRACE("AutoMateUI:_update_tracks()")

  if not self._app._active then
    return
  end

  local track_names = {}
  for k,v in ipairs(rns.tracks) do 
    table.insert(track_names,("%.2d:%s"):format(k,v.name))
  end

  local ctrl_device_tab = self.vb.views["device_tab_track_select"]
  local ctrl_param_tab = self.vb.views["param_tab_track_select"]
  ctrl_device_tab.items = track_names
  ctrl_param_tab.items = track_names
  ctrl_device_tab.value = self._app.selected_track_idx
  ctrl_param_tab.value = self._app.selected_track_idx

end

---------------------------------------------------------------------------------------------------
-- populate device list

function AutoMateUI:_update_devices()
  TRACE("AutoMateUI:_update_devices()")

  if not self._app._active then
    return
  end

  local trk = self._app:_resolve_track()
  assert(trk,"failed to resolve track")

  -- get name + display name (if different)
  local get_display_name = function(device)
    if (device.name == device.display_name) then 
      return device.name
    else
      return ("%s [%s]"):format(device.name,device.display_name)
    end
  end

  -- device selector (params tab)
  local ctrl = self.vb.views["param_tab_device_select"]
  local device_names = {"None selected"}
  for k,v in ipairs(trk.devices) do 
    table.insert(device_names,get_display_name(v))
  end
  ctrl.items = device_names

  -- show device in selector - NB: can be nil
  if self._app.selected_device_idx 
    and (self._app.selected_device_idx > 0) 
  then 
    ctrl.value = 1 + self._app.selected_device_idx
  else
    ctrl.value = 1
  end
  
  -- device table (device tab)
  local device_table_data = {}
  for k,v in ipairs(trk.devices) do 
    local is_selected = (k == self._app.selected_device_idx) 
    local status_bitmap = xAudioDevice.is_automated(v)
      and BITMAP_AUTOMATED_ACTIVE or BITMAP_AUTOMATED_EMPTY
    
    table.insert(device_table_data,{
      index = k,
      name = get_display_name(v),
      status_bitmap = status_bitmap,
      __row_style = is_selected and ROW_STYLE_SELECTED or ROW_STYLE_NORMAL,
    })
  end
  self._device_vtable.data = device_table_data
  
end

---------------------------------------------------------------------------------------------------
-- populate parameter list/table

function AutoMateUI:_update_params()
  TRACE("AutoMateUI:_update_params()")

  if not self._app._active then
    return
  end

  -- no device selected 
  if not self._app.selected_device_idx or (self._app.selected_device_idx == 0) then 
    self._param_vtable.data = {}
    return
  end 

  --print("self._app.selected_device_idx",self._app.selected_device_idx)
  local device = self._app:_resolve_device()
  assert(type(device)=="AudioDevice")

  local sel_param_idx = self._app.selected_parameter_idx

  local get_status_bitmap = function(param)
    return param.is_automated and BITMAP_AUTOMATED_ACTIVE 
      or param.is_automatable and BITMAP_AUTOMATED_EMPTY 
      or BITMAP_AUTOMATED_NONE
  end    

  -- table in params tab
  local param_names_data = {}

  -- workaround for missing API access to first parameter (bypass):
  -- add "dummy" entry for completeness
  if not table.find(xAudioDevice.BYPASS_INCAPABLE,device.device_path) then
    table.insert(param_names_data,{
      index = 0,
      status_bitmap = BITMAP_AUTOMATED_UNKNOWN,
      name = "Active / Bypassed",
      __row_style = ROW_STYLE_NORMAL,      
    })
  end

  for k,v in ipairs(device.parameters) do 
    local is_selected = (k == self._app.selected_parameter_idx)
    local row_style = is_selected and ROW_STYLE_SELECTED or ROW_STYLE_NORMAL
    local status_bitmap = get_status_bitmap(v)
    table.insert(param_names_data,{
      index = k,
      status_bitmap = status_bitmap,
      name = v.name,
      __row_style = row_style,      
    })
  end
  --rprint(param_names_data)
  self._param_vtable.data = param_names_data
  
end

---------------------------------------------------------------------------------------------------

function AutoMateUI:_update_actions()
  TRACE("AutoMateUI:_update_actions()")

  local vb = self.vb

  local cut_active = false
  local copy_active = false
  local clear_active = false
  local paste_active = false
  local move_active = false
  local swap_active = false
  --
  local transform_active = false 
  local generate_active = false
  local add_active = false

  local has_selected_device = self._app.selected_device_idx 
    and (self._app.selected_device_idx > 0)

  if not self._is_processing and has_selected_device then 

    local device = self._app:_resolve_device()  
    local param = self._app:_resolve_parameter()  
    local tab_is_parameter = (prefs.selected_tab.value == AutoMatePrefs.TAB_PARAMETERS)
    local param_is_automatable = (device and param and param.is_automatable) and true or false
    local param_is_automated = (device and param and param.is_automated) and true or false

    cut_active = param_is_automatable and param_is_automated
    copy_active = param_is_automatable and param_is_automated

    if not param_is_automatable or not self._app._clipboard then 
      paste_active = false
    else
      if (prefs.selected_tab.value == AutoMatePrefs.TAB_DEVICES) then 
        paste_active = type(self._app._clipboard.payload)=="xAudioDeviceAutomation"
      else--if (prefs.selected_tab.value == AutoMatePrefs.TAB_PARAMETERS) then 
        paste_active = type(self._app._clipboard.payload)=="xEnvelope"
      end
    end

    clear_active = param_is_automatable and param_is_automated
    generate_active = param_is_automatable and tab_is_parameter
    --move_active = true
    --swap_active = true
    --transform_active = param_is_automatable and param_is_automated
    add_active = self._app._clipboard and true or false

  end

  vb.views["app_action_cut"].active = cut_active
  vb.views["app_action_copy"].active = copy_active
  vb.views["app_action_clear"].active = clear_active
  vb.views["app_action_paste"].active = paste_active
  vb.views["app_action_move"].active = move_active
  vb.views["app_action_swap"].active = swap_active
  vb.views["app_action_generate"].active = generate_active
  vb.views["app_action_transform"].active = transform_active
  vb.views["app_action_add_to_library"].active = add_active

end

---------------------------------------------------------------------------------------------------

function AutoMateUI:_update_status()
  TRACE("AutoMateUI:_update_status()")

  local vb = self.vb
  local status_txt = vb.views["app_status_readout"]
  local cancel_bt = vb.views["app_status_cancel_processing"]
  cancel_bt.visible = false

  local get_clip_summary = function()
    if not self._app._clipboard then 
      return "Clipboard is empty"
    else 
      local payload = self._app._clipboard.payload
      if (type(payload)=="xAudioDeviceAutomation") then 
        return ("Copied %d params"):format(#payload.parameters)
      elseif (type(payload)=="xEnvelope") then 
        return ("Copied %d points"):format(#payload.points)
      end
    end
  end

  if (self._app.status_observable.value == AutoMate.STATUS.READY) then 
    status_txt.text = ""
  elseif (self._app.status_observable.value == AutoMate.STATUS.COPYING) then 
    status_txt.text = "Copying Automation..."
    cancel_bt.visible = true
  elseif (self._app.status_observable.value == AutoMate.STATUS.GENERATING) then 
    status_txt.text = "Generating Envelope..."
    cancel_bt.visible = true
  elseif (self._app.status_observable.value == AutoMate.STATUS.PASTING) then 
    status_txt.text = "Pasting Automation..."
    cancel_bt.visible = true
  elseif (self._app.status_observable.value == AutoMate.STATUS.DONE_COPYING) then 
    status_txt.text = get_clip_summary()
  elseif (self._app.status_observable.value == AutoMate.STATUS.DONE_PASTING) then 
    status_txt.text = "Done Pasting."
  end


end

---------------------------------------------------------------------------------------------------

function AutoMateUI:_update_options()
  TRACE("AutoMateUI:_update_options()")

  local vb = self.vb

  local yield_active = (prefs.yield_at.value ~= xLib.YIELD_AT.NONE) 
  vb.views["app_options_yield_popup"].active = yield_active
  vb.views["app_options_yield_checkbox"].value = yield_active

  if yield_active then 
    vb.views["app_options_yield_popup"].value = prefs.yield_at.value-1
  end

end

---------------------------------------------------------------------------------------------------
--- Disable UI while performing (sliced) processing

function AutoMateUI:_update_active_state()
  TRACE("AutoMateUI:_update_active_state()")

  local vb = self.vb
  
  vb.views["app_scopes_chooser"].active = not self._is_processing
  
  self._vtabs.active = not self._is_processing
  self._device_vtable.active = not self._is_processing
  self._param_vtable.active = not self._is_processing
    
end

---------------------------------------------------------------------------------------------------

function AutoMateUI:_update_scopes()
  TRACE("AutoMateUI:_update_scopes()")

  local vb = self.vb
  local scope_is_song = (prefs.selected_scope.value == AutoMate.SCOPE.WHOLE_SONG)
  local flick_prev = vb.views["app_scopes_flick_previous"]
  local flick_next = vb.views["app_scopes_flick_next"]

  flick_prev.active = not scope_is_song
  flick_next.active = not scope_is_song

end


---------------------------------------------------------------------------------------------------
--- handle idle notifications

function AutoMateUI:on_idle()

  if not self._app.active then 
    return
  end

  if self.update_requested then
    self.update_requested = false
    self:update()
  end

  if self.update_tracks_requested then
    self.update_tracks_requested = false
    self:_update_tracks()
  end

  if self.update_devices_requested then
    self.update_devices_requested = false
    self:_update_devices()
  end

  if self.update_params_requested then
    self.update_params_requested = false
    self:_update_params()
  end

  if self.update_actions_requested then
    self.update_actions_requested = false
    self:_update_actions()
  end

  if self.update_status_requested then
    self.update_status_requested = false
    self:_update_status()
  end

  if self.update_tabs_requested then
    self.update_tabs_requested = false
    self:_update_tabs()
  end

  if self.update_options_requested then
    self.update_options_requested = false
    self:_update_options()
  end

  if self.update_active_state_requested then
    self.update_active_state_requested = false
    self:_update_active_state()
  end
  
end

