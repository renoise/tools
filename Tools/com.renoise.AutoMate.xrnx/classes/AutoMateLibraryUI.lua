--[[===============================================================================================
-- AutoMateLibraryUI.lua
===============================================================================================]]--

--[[--

User interface for AutoMateLibrary

--]]

--=================================================================================================

local MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
local DIALOG_W = 450
local SUBMIT_BT_H = 22
local TABLE_W = DIALOG_W-(MARGIN*2)
local TABLE_ROWS = 8
local TABLE_ROW_H = 16
local TABLE_CHECKBOX_W = 16
local TABLE_SCROLL_W = 18
local ROW_STYLE_SELECTED = "body"
local ROW_STYLE_NORMAL = "plain"

---------------------------------------------------------------------------------------------------

class 'AutoMateLibraryUI' (vDialog)

AutoMateLibraryUI.SHOW_IN_LIBRARY = {
  ALL = 1,
  DEVICES = 2,
  ENVELOPES = 3,
}

---------------------------------------------------------------------------------------------------
-- Constructor

function AutoMateLibraryUI:__init(library)
  TRACE("AutoMateLibraryUI:__init(library)",library)

  assert(type(library)=="AutoMateLibrary")
  
  vDialog.__init(self,{
    --waiting_to_show_dialog = prefs.autorun_enabled.value,
    dialog_title = "AutoMate Library",
    --dialog_keyhandler = self.dialog_keyhandler
  })

  --- (AutoMateLibrary) 
  self._library = library

  --- (renoise.Views.View) 
  self._view = nil 
  self._rename_prompt_view = nil

  --- update flags
  self._update_table_requested = false
  self._update_actions_requested = false

  
  -- observables ----------------------

  self._library.presets_observable:add_notifier(function()
    --print(">>> presets_observable fired...")
    self._update_table_requested = true
  end)

  self._library.selected_preset_observable:add_notifier(function()
    --print(">>> selected_preset_observable fired...")
    self._update_actions_requested = true
    self._update_table_requested = true
  end)

  self._library._app.clipboard_observable:add_notifier(function()
    --print(">>> clipboard_observable fired...")
    self._update_actions_requested = true
  end)

  prefs.show_in_library:add_notifier(function()
    --print(">>> show_in_library fired...")
    self._update_table_requested = true
  end)

  renoise.tool().app_idle_observable:add_notifier(self,self.on_idle)
  
end

---------------------------------------------------------------------------------------------------
-- vDialog methods
---------------------------------------------------------------------------------------------------

function AutoMateLibraryUI:create_dialog()
  TRACE("AutoMateLibraryUI:create_dialog()")

  if not self._view then 
    self._view = self:_build()
  end

  return self._view

end

---------------------------------------------------------------------------------------------------
-- Class methods
---------------------------------------------------------------------------------------------------

function AutoMateLibraryUI:_build()
  TRACE("AutoMateLibraryUI:_build()")

  local vb = self.vb

  local view = vb:column{
    id = 'library_rootnode',
    width = DIALOG_W,
    vb:column{
      margin = MARGIN,
      spacing = MARGIN,
      self:_build_toolbar(),
      self:_build_table(),
      self:_build_lower_toolbar(),
      -- self:_build_scopes_panel(),
      -- self:_build_actions_panel(),
      -- self:_build_status_panel(),
    }
  }

  -- rename prompt 
  self._rename_prompt_view = vb:column{
    margin = 6,
    width = 200,
    vb:text{
      text = "",
    },
    vb:textfield{
      id = "rename_prompt_txt",
      width = "100%",
      text = ""
    },
  }
  
  self.update_requested = true
  return view

end

---------------------------------------------------------------------------------------------------

function AutoMateLibraryUI:_build_toolbar()
  TRACE("AutoMateLibraryUI:_build_toolbar()")

  local vb = self.vb

  return vb:horizontal_aligner{
    mode = "justify",
    vb:row{
      vb:text{
        text = "Show"
      },
      vb:popup{
        id = "show_in_library_selector",
        value = prefs.show_in_library.value,
        width = 100,
        items = {
          "All Presets",
          "Device Presets",
          "Params/Envelopes"
        },
        notifier = function(idx)
          prefs.show_in_library.value = idx
        end
      },
      vb:button{
        id = "library_rename",
        --text = "Rename",
        bitmap = "images/rename.bmp",
        tooltip = "Rename the preset",
        notifier = function()
          self:_rename_preset()
        end
      },
      vb:button{
        id = "library_remove",
        --text = "Remove",
        bitmap = "images/delete.bmp",
        tooltip = "Remove the selected preset(s)",
        notifier = function()
          self:_remove_presets()
        end
      },
      --[[
      vb:button{
        id = "library_remap",
        text = "Remap",
        tooltip = "Change parameter assignments",
        notifier = function()

        end
      },
      vb:button{
        id = "library_transform",
        text = "Transform",
        tooltip = "Change parameter assignments",
        notifier = function()

        end
      },
      ]]
      vb:space{
        width = 3
      },
      vb:button{
        id = "library_add",
        text = "+ Add",
        --bitmap = "images/add.bmp",
        tooltip = "Add new preset from clipboard",
        notifier = function()
          self._library._app:add_to_library()
        end
      },
      
    },
    vb:row{
      --[[
      vb:button{
        text = "Options",
        tooltip = "Show library options",
        notifier = function()

        end
      },
      ]]
      vb:button{
        id = "library_refresh",
        --text = "Refresh",
        bitmap = "images/refresh.bmp",
        tooltip = "Reload available presets from disk",
        notifier = function()
          self._library:load_presets()
        end
      },
      vb:button{
        id = "library_reveal",
        --text = "Reveal",
        bitmap = "images/reveal_folder.bmp",
        tooltip = "Reveal folder containing presets",
        notifier = function()
          renoise.app():open_path(AutoMateLibrary.get_path())
        end
      },
    },
  }

end

---------------------------------------------------------------------------------------------------

function AutoMateLibraryUI:_build_lower_toolbar()

  local vb = self.vb

  return vb:row{
    vb:button{
      id = "library_copy",
      text = "Copy",
      --bitmap = "images/copy.bmp",
      height = SUBMIT_BT_H,
      tooltip = "Copy selected preset to the clipboard",
      notifier = function()
        self._library:copy_to_clipboard()
      end
    },
    vb:button{
      id = "library_apply",
      text = "Apply",
      --bitmap = "images/copy.bmp",
      height = SUBMIT_BT_H,
      tooltip = "Apply selected preset to pattern",
      notifier = function()
        self._library:apply_preset_to_pattern()
      end
    },
    vb:row{
      margin = 2,
      vb:text{
        text = "[Parameter - Whole Pattern]"
      }
    }
  }

end

---------------------------------------------------------------------------------------------------

function AutoMateLibraryUI:_build_table()
  TRACE("AutoMateLibraryUI:_build_table()")

  local vb = self.vb

  local handle_header_checked = function(elm,checked)
    --print("handle_header_checked(elm,checked)",elm,checked)
    self._vtable.header_defs.selected.data = checked
    for k,v in ipairs(self._vtable.data) do
      if not checked then 
        -- selected row is always checked
        if (v.name ~= self._library.selected_preset_name) then
          v.selected = checked
        end
      else 
        v.selected = checked
      end
    end
    self._vtable:request_update()
    self._update_actions_requested = true
    --self._update_table_requested = true
  end

  local handle_table_checked = function(elm,checked)
    --print("handle_table_checked(elm,checked)",elm,checked)
    local item = elm.owner:get_item_by_id(elm.item_id)
    if item then
      -- don't allow deselecting all 
      if not checked then 
        local selected_indices = self:get_selected_preset_indices()
        if (#selected_indices == 1) then
          checked = true
        end
      end
      item.selected = checked
      self._library.selected_preset_name = item.name
      --self._vtable:request_update()
      self._update_actions_requested = true
      self._update_table_requested = true
    end
  end

  local do_select_row = function(cell)
    local item = self._vtable:get_item_by_id(cell[vDataProvider.ID])          
    self._library.selected_preset_name = item.name
  end
  
  self._vtable = vTable{
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
        key = "selected",
        col_type = vTable.CELLTYPE.CHECKBOX, 
        col_width = TABLE_CHECKBOX_W,
        notifier=handle_table_checked,
      },       
      {
        key = "name",    
        col_width = "auto", 
        notifier = function(cell,val)
          do_select_row(cell)
        end
      },
      --[[
      {
        key = "num_points",    
        col_width = 50, 
        notifier = function(cell,val)
          do_select_row(cell)
        end
      },
      ]]
      {
        key = "num_lines",    
        col_width = 50, 
        notifier = function(cell,val)
          do_select_row(cell)
        end
      },
      {
        key = "num_params",    
        col_width = 60, 
        notifier = function(cell,val)
          do_select_row(cell)
        end
      },
      {
        key = "device_path",    
        col_width = "auto", 
        notifier = function(cell,val)
          do_select_row(cell)
        end
      },
    },
    header_defs = {
      selected = {
        col_type=vTable.CELLTYPE.CHECKBOX, 
        active=true, 
        notifier=handle_header_checked
      },
      name = {
        data = "Name"
      },
      --[[
      num_points = {
        data = "Points"
      },
      ]]
      num_params = {
        data = "#Params"
      },
      num_lines = {
        data = "#Lines"
      },
      device_path = {
        data = "Device Path"
      }
    }
      
  }
  --self._vtable.show_header = false
  return self._vtable.view

end

---------------------------------------------------------------------------------------------------

function AutoMateLibraryUI:_remove_presets()
  TRACE("AutoMateLibraryUI:_remove_presets()")

  local names = self:get_selected_preset_names()          
  local title = "Delete Presets"  
  local msg = ("Are you sure you want to delete the following presets:"
            .."\n%s"):format(table.concat( names, "\n"))
  local choice = renoise.app():show_prompt(title,msg,{"OK","Cancel"})
  if (choice == "OK") then 
    self._library:remove_presets(names)
  end

end  

---------------------------------------------------------------------------------------------------

function AutoMateLibraryUI:_rename_preset()
  TRACE("AutoMateLibraryUI:_rename_preset()")

  local vb = self.vb

  local preset = self._library.selected_preset
  if not preset then 
    renoise.app():show_warning("No preset is selected")
    return
  end

  vb.views["rename_prompt_txt"].text = self._library.selected_preset_name
  local choice = renoise.app():show_custom_prompt(
    "Rename a file",self._rename_prompt_view,{"Rename","Cancel"})
    
  if (choice == "Rename") then
    local new_name = vb.views["rename_prompt_txt"].text
    local success,err = preset:rename(new_name)
    if not success then 
      if err then 
        renoise.app():show_warning(err)
      end
      return
    end
    -- refresh list 
    self._library.selected_preset_name = new_name
    self._library:load_presets()
  end

end

---------------------------------------------------------------------------------------------------
--- Update the entire UI (all update_xx methods...)

function AutoMateLibraryUI:update()
  TRACE("AutoMateLibraryUI:update()")

  self:_update_table()
  self:_update_actions()

end

---------------------------------------------------------------------------------------------------

function AutoMateLibraryUI:_update_table()
  TRACE("AutoMateLibraryUI:_update_table()")

  if not self._vtable then 
    return
  end

  local rslt = {}

  local get_device_path = function(preset)
    if (type(preset.payload)=="xAudioDeviceAutomation") then 
      local path,file,ext = cFilesystem.get_path_parts(preset.payload.device_path)
      return file
    end
    return "-"
  end

  local get_num_params = function(preset)
    if (type(preset.payload)=="xAudioDeviceAutomation") then 
      return #preset.payload.parameters
    end
    return "-"
  end

  --[[
  local get_num_points = function(preset)
    if (type(preset.payload)=="xEnvelope") then 
      return #preset.payload.points
    end
    return "-"
  end
  ]]

  local get_num_lines = function(preset)
    return preset.payload.number_of_lines
  end

  local show_in_list = function(preset)
    local show = prefs.show_in_library.value
    if (show == AutoMateLibraryUI.SHOW_IN_LIBRARY.ALL) then 
      return true
    end
    if (type(preset.payload) == "xAudioDeviceAutomation") then 
      return (prefs.show_in_library.value == AutoMateLibraryUI.SHOW_IN_LIBRARY.DEVICES)
    else 
      return (prefs.show_in_library.value == AutoMateLibraryUI.SHOW_IN_LIBRARY.ENVELOPES)
    end
  end

  local selected_is_included = false
  for k,v in ipairs(self._library.presets) do 
    local is_selected = v.name == self._library.selected_preset_name
    if show_in_list(v) then
      if is_selected then 
        selected_is_included = true 
      end
      table.insert(rslt,{
        selected = is_selected,
        name = v.name,
        --num_points = get_num_points(v),
        num_params = get_num_params(v),
        num_lines = get_num_lines(v),
        device_path = get_device_path(v),
        __row_style = is_selected and ROW_STYLE_SELECTED or ROW_STYLE_NORMAL,
      })
    end
  end

  -- if selected preset was filtered out, deselect 
  if not selected_is_included then 
    self._library.selected_preset_name = nil
  end

  --print("rslt",rprint(rslt))
  self._vtable.data = rslt

end

---------------------------------------------------------------------------------------------------

function AutoMateLibraryUI:_update_actions()
  TRACE("AutoMateLibraryUI:_update_actions()")

  local vb = self.vb

  local add_active = false
  local rename_active = false 
  local remove_active = false 
  local remap_active = false 
  local transform_active = false 
  local refresh_active = false 
  local reveal_active = false 
  local copy_active = false 

  local get_preset_type = function()
    local preset = self._library.selected_preset
    if preset then 
      return type(preset.payload)
    end
  end
  
  local selected_indices = self:get_selected_preset_indices()
  --print("selected_indices",rprint(selected_indices))
  --local has_selected_preset = (self._library.selected_preset) and true or false
  local has_clipboard = (self._library._app.clipboard) and true or false
  local selected_param_idx = self._library._app:get_selected_parameter_index_in_renoise()
  local is_device_preset = (get_preset_type()=="xAudioDeviceAutomation")
  --print("is_device_preset",is_device_preset,get_preset_type())

  vb.views["library_add"].active = has_clipboard
  vb.views["library_rename"].active = (#selected_indices == 1)
  vb.views["library_remove"].active = (#selected_indices > 0)
  --vb.views["library_remap"].active = is_device_preset and (#selected_indices == 1)
  --vb.views["library_transform"].active = not is_device_preset and (#selected_indices == 1)
  
  vb.views["library_copy"].active = (#selected_indices == 1)
  vb.views["library_apply"].active = 
    (#selected_indices == 1 and selected_param_idx) and true or false

end

---------------------------------------------------------------------------------------------------
-- @return table<string>

function AutoMateLibraryUI:get_selected_preset_names()

  local rslt = {}
  local indices = self:get_selected_preset_indices()
  for k,v in ipairs(indices) do
    local preset = self._library.presets[v]
    if preset then 
      table.insert(rslt,preset.name)
    end
  end
  return rslt

end

---------------------------------------------------------------------------------------------------
-- @return table<number>

function AutoMateLibraryUI:get_selected_preset_indices()
  TRACE("AutoMateLibraryUI:get_selected_preset_indices()")

  local rslt = {}
  for k,v in ipairs(self._vtable.data) do
    if v.selected then 
      table.insert(rslt,k)
    end
  end
  return rslt 

end

---------------------------------------------------------------------------------------------------
--- handle idle notifications

function AutoMateLibraryUI:on_idle()

  if not self._library._app.active 
    or not self._view
  then 
    return
  end

  if self.update_requested then
    self.update_requested = false
    self:update()
  end

  if self._update_table_requested then
    self._update_table_requested = false
    self:_update_table()
  end

  if self._update_actions_requested then
    self._update_actions_requested = false
    self:_update_actions()
  end

  
end
