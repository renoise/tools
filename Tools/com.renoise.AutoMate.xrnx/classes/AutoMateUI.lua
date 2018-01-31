--[[===============================================================================================
-- AutoMateUI.lua
===============================================================================================]]--

--[[--

# AutoMate

--]]

--=================================================================================================

local MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
local DIALOG_W = 205
local NULL_MARGIN = -3
local CONTENT_W = DIALOG_W - (2*MARGIN)
local ACTION_BT_W = CONTENT_W/3
local LEFT_COL_W = CONTENT_W/4
local RIGHT_COL_W = CONTENT_W-82
local SCOPES_W = CONTENT_W-(MARGIN*3)
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


class 'AutoMateUI'

function AutoMateUI:__init(app)
  TRACE("AutoMateUI:__init()")

  --- (NTrap) instance of main class
  self._app = app

  --- (renoise.ViewBuilder) 
  self._vb = renoise.ViewBuilder()

  --- (renoise.Dialog) reference to the main dialog 
  self._dialog = nil

  --- (renoise.Views.View) 
  self._view = nil -- self:build()

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
  self.update_tabs_requested = false
  self.update_options_requested = false

  -- observables

  self._app.clipboard_observable:add_notifier(self,function()
    --print("clipboard_observable fired...")
    self.update_actions_requested = true
  end)

  self._app.processing_changed_observable:add_notifier(self,function()
    --print("processing_changed_observable fired...")
    if self._app.active then
      if self._is_processing then
        -- update right away
        self:_update_active_state()
        self:_update_actions()
      else
        self.update_actions_requested = true
        self.update_active_state_requested = true
      end        
    end
  end)

end

---------------------------------------------------------------------------------------------------
--- @return boolean

function AutoMateUI:get_is_processing()
  return self._app.processing and true or false
end

---------------------------------------------------------------------------------------------------

--- Show the dialog

function AutoMateUI:show()
  TRACE("AutoMateUI:show()")

  if (not self._dialog or not self._dialog.visible) then

    if not self._view then
      self._view = self:build()
    end
    self._app:attach_to_song()

    self._dialog = renoise.app():show_custom_dialog(
      "AutoMate", self._view,function(dialog,key)
        return self:_keyhandler(dialog,key)
      end)

    self._dialog:show()
  end

end

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

function AutoMateUI:_keyhandler(dialog,key)
  TRACE("AutoMateUI:_keyhandler(dialog,key)",dialog,key)
  
  local key_was_handled = false
  local param_tab_selected = (prefs.selected_tab.value == AutoMatePrefs.TAB_PARAMETERS)
  --local device_tab_selected = (prefs.selected_tab.value == AutoMatePrefs.TAB_DEVICES)

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
        self._app:clear()
      end,
    }
    if switch[key.name] then 
      switch[key.name]()
      key_was_handled = true
    end      

  elseif (key.modifiers == "control") then
    local switch = {
      ["x"] = function()
        self._app:cut()
      end,
      ["c"] = function()
        self._app:copy()
      end,
      ["v"] = function()
        self._app:paste()
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

--- Hide the dialog

function AutoMateUI:hide()
  TRACE("AutoMateUI:hide()")

  if (self._dialog and self._dialog.visible) then
    self._dialog:close()
  end

  self._dialog = nil

end

---------------------------------------------------------------------------------------------------

--- Build

function AutoMateUI:build()
  TRACE("AutoMateUI:build()")

  local vb = self._vb
  local view = vb:column{
    id = 'app_rootnode',
    width = DIALOG_W,
    vb:column{
      margin = MARGIN,
      spacing = MARGIN,
      self:_build_tabs(),
      self:_build_scopes_panel(),
      self:_build_actions_panel(),
      self:_build_processing_panel(),
    }
  }

  self.update_requested = true
  return view

end

---------------------------------------------------------------------------------------------------

function AutoMateUI:_build_tabs()
  local vb = self._vb
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
      self.update_tabs_requested = true
      self.update_actions_requested = true
    end,
    --on_resize = function()
    --  print("vtabs.on_resize")
    --end,
  }

  return self._vtabs.view

end  

---------------------------------------------------------------------------------------------------

function AutoMateUI:_build_tab_devices()

  local vb = self._vb
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

  local vb = self._vb
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

  local vb = self._vb
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
    --  print("_device_vtable.on_scroll()")
    --end,
    --on_resize = function()
    --  print("_device_vtable.on_resize()")
    --end,
      
  }
  self._device_vtable.show_header = false
  return self._device_vtable.view

end

---------------------------------------------------------------------------------------------------

function AutoMateUI:_build_param_table()

  local vb = self._vb
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
    --  print("_param_vtable.on_scroll()")
    --end,
    --on_resize = function()
    --  print("_param_vtable.on_resize()")
    --end,
      
  }
  self._param_vtable.show_header = false
  return self._param_vtable.view

end


---------------------------------------------------------------------------------------------------

function AutoMateUI:_build_scopes_panel()
    
  local vb = self._vb
  return vb:column{
    id = "app_scopes_panel",    
    style = "group",
    margin = MARGIN,
    vb:horizontal_aligner{
      mode = "justify",
      vb:text{
        text = "Available Scopes",
        font = "bold",
      },
      vb:row{
        spacing = NULL_MARGIN,
        vb:button{
          text = "◂",
          notifier = function()
            self._app:select_previous_scope()
          end,
        },
        vb:button{
          text = "▸",
          notifier = function()
            self._app:select_next_scope()
          end,
        },
      }
    },
    vb:chooser{
      id = "app_scopes_chooser",
      bind = prefs.selected_scope,
      items = SCOPE_NAMES,
      width = SCOPES_W,
    }
  }

end  

---------------------------------------------------------------------------------------------------

function AutoMateUI:_build_actions_panel()

  local vb = self._vb
  return vb:column{
    id = "app_actions_panel",
    vb:row{
      vb:button{
        id = "app_action_cut",
        text = "Cut",
        width = ACTION_BT_W,
        notifier = function()
          self._app:cut()
        end
      },
      vb:button{
        id = "app_action_copy",
        text = "Copy",
        width = ACTION_BT_W,
        notifier = function()
          self._app:copy()
        end
      },
      vb:button{
        id = "app_action_paste",
        text = "Paste",
        width = ACTION_BT_W,
        notifier = function()
          self._app:paste()
        end,
      },
    },
    vb:row{
      vb:button{
        id = "app_action_clear",
        text = "Clear",
        width = ACTION_BT_W,
        notifier = function()
          self._app:clear()
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
    }
  }

end

---------------------------------------------------------------------------------------------------

function AutoMateUI:_build_processing_panel()

  local vb = self._vb

  return vb:column{
    id = "app_processing_panel",
    --style = "panel",
    width = CONTENT_W-MARGIN,
    vb:horizontal_aligner{      
      mode = "justify",
      --width = CONTENT_W,
      width = "100%",
      vb:text{
        text = "Processing..."
      },
      vb:button{
        text = "Cancel",
        notifier = function()
          self._app.slicer:stop()
        end
      }
    }
  }

end

---------------------------------------------------------------------------------------------------

function AutoMateUI:_build_options_panel()

  local vb = self._vb

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
              local vb = self._vb
              if val then 
                prefs.yield_at.value = vb.views["app_options_yield_popup"].value+1
              else
                prefs.yield_at.value = xAudioDeviceAutomation.YIELD_AT.NONE
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

end

---------------------------------------------------------------------------------------------------

function AutoMateUI:_update_tabs()
  TRACE("AutoMateUI:_update_tabs()")
  
  local vb = self._vb
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

  local ctrl_device_tab = self._vb.views["device_tab_track_select"]
  local ctrl_param_tab = self._vb.views["param_tab_track_select"]
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

  -- device selector (params tab)
  local ctrl = self._vb.views["param_tab_device_select"]
  local device_names = {"None selected"}
  for k,v in ipairs(trk.devices) do 
    table.insert(device_names,v.name)
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
      name = v.name,
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

  local vb = self._vb

  local cut_active = false
  local copy_active = false
  local clear_active = false
  local paste_active = false
  local move_active = false
  local swap_active = false

  local has_selected_device = self._app.selected_device_idx 
    and (self._app.selected_device_idx > 0)

  if not self._is_processing and has_selected_device then 

    local device = self._app:_resolve_device()  
    local param = self._app:_resolve_parameter()  
  
    local param_is_automatable = (device and param and param.is_automatable) and true or false
      --and not ( table.find(xAudioDevice.BYPASS_INCAPABLE,device.device_path)) 
      
    cut_active = param_is_automatable
    copy_active = param_is_automatable
    clear_active = param_is_automatable
    --move_active = true
    --swap_active = true
    if not param_is_automatable then 
      paste_active = false
    else
      -- only paste when clipboard is compatible
      if (prefs.selected_tab.value == AutoMatePrefs.TAB_DEVICES) then 
        paste_active = (type(self._app._clipboard)=="xAudioDeviceAutomation")
      else--if (prefs.selected_tab.value == AutoMatePrefs.TAB_PARAMETERS) then 
        paste_active = (type(self._app._clipboard)=="xParameterAutomation")
      end
    end
  end

  vb.views["app_action_cut"].active = cut_active
  vb.views["app_action_copy"].active = copy_active
  vb.views["app_action_clear"].active = clear_active
  vb.views["app_action_paste"].active = paste_active
  vb.views["app_action_move"].active = move_active
  vb.views["app_action_swap"].active = swap_active

end

---------------------------------------------------------------------------------------------------

function AutoMateUI:_update_options()
  TRACE("AutoMateUI:_update_options()")

  local vb = self._vb

  local yield_active = (prefs.yield_at.value ~= xAudioDeviceAutomation.YIELD_AT.NONE) 
  vb.views["app_options_yield_popup"].active = yield_active
  vb.views["app_options_yield_checkbox"].value = yield_active

  if yield_active then 
    vb.views["app_options_yield_popup"].value = prefs.yield_at.value-1
  end

end

---------------------------------------------------------------------------------------------------
--- Disable UI while performing (sliced) processing

function AutoMateUI:_update_active_state()

  local vb = self._vb
  
  vb.views["app_scopes_chooser"].active = not self._is_processing
  vb.views["app_processing_panel"].visible = self._is_processing
  
  self._vtabs.active = not self._is_processing
  self._device_vtable.active = not self._is_processing
  self._param_vtable.active = not self._is_processing
    
end

---------------------------------------------------------------------------------------------------
--- handle idle notifications

function AutoMateUI:on_idle()

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

