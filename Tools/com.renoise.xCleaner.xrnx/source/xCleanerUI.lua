--[[============================================================================
xCleanerUI
============================================================================]]--

--[[

  User interface for xCleaner 

]]

local DIALOG_W = 390
local MARGIN = 6


local function zero_pad(str,count)
  return ("%0"..count.."s"):format(str) 
end


local function get_instrument_list()

  local rslt = table.create()
  for k,v in ipairs(renoise.song().instruments) do
    local display_num = zero_pad(tostring(k-1),2)
    local display_name = v.name
    if (display_name == "") then
      display_name = "(Untitled Instrument)"
    end
    rslt:insert(("%s:%s"):format(display_num,display_name))
  end
  return rslt

end

--------------------------------------------------------------------------------

class 'xCleanerUI'

xCleanerUI.TAB = {
  SAMPLES = 1,
  MODULATION = 2,
  EFFECTS = 3,
}

xCleanerUI.TAB_LABELS = {
  "Samples","Modulation","Effects"
}

function xCleanerUI:__init(xCleaner)
  TRACE("xCleanerUI:__init(xCleaner)")

  --- (xCleaner) instance of main class
  self._x = xCleaner

  -- viewbuilder stuff
  self.vb = renoise.ViewBuilder()
  self.dialog = nil
  self.dialog_content = nil

  -- (vTabs) the sample/modulation/effects
  self.tabs = nil

  -- (bool), sync with selected instr
  self.follow_selection = true

  -- (vTable) the various tables 
  self.sample_table = nil
  self.mod_table = nil
  self.fx_table = nil

  -- 

  options.samplename:add_notifier(function()
    self:update_sample_name_options()
  end)

  options.find_issues:add_notifier(function()
    local elm = self.vb.views.find_issues
    self._x:set_issue_scanning_pref(elm.value)
  end)

  self._x:set_issue_scanning_pref(options.find_issues.value)

end

--------------------------------------------------------------------------------

function xCleanerUI:build()
  TRACE("xCleanerUI:build()")

  local large_button_h = 24
  local label_w = 90
  local vb = self.vb

  local content = vb:column{
    margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
    spacing = MARGIN,
    vb:column{
      style = "group",
      margin = MARGIN,
      width = DIALOG_W,
      vb:horizontal_aligner{
        vb:column{
          vb:space{
            height = 3,
          },
          vb:text {
            text = "Instr.",
          },
        },
        vb:popup {
          items = {},
          id = "instr_source_popup",
          value = 1,
          width = DIALOG_W - 132,
          height = large_button_h,
          notifier = function(idx)
            
          end,
        },
        vb:button{
          text = "↺", --≡
          id = "bt_sync_source",
          height = large_button_h,
          width = large_button_h,
          tooltip = "Focus the last scanned instrument",
          notifier = function(val)
            self:focus_instr()
          end,
        },
        vb:button{
          text = "Scan",
          width = 67,
          height = large_button_h,
          notifier = function()
            self._x:gather()
          end,
        },
      },
    },
    vb:column{
      --width = DIALOG_W,
      vb:column{
        style = "group",
        margin = MARGIN,
        vb:space{
          width = DIALOG_W-(MARGIN*2),
          height = 1,
        },
        vb:row{
          vb:text{
            text = "Sample-names",
            width = label_w,
          },
          vb:column{
            vb:row{
              vb:popup{
                id = "check_samples_keep_name",
                items = xCleaner.SAMPLENAMES,
                bind = options.samplename,
                width = 120,
                --[[
                notifier = function()
                  local elm = self.vb.views.check_unreferenced
                  xCleaner.check_unreferenced = elm.value
                end
                ]]
              },
              vb:textfield{
                id = "textfield_sample_name",
                text = "Enter name...",
                width = 100,
              },
            },
            vb:row{
              vb:checkbox{
                id = "checkbox_sample_add_velocity",
                bind = options.samplename_add_velocity,
              },
              vb:text{
                text = "Velocity",
              },
              vb:checkbox{
                id = "checkbox_sample_add_note",
                bind = options.samplename_add_note,
              },
              vb:text{
                text = "Note",
              },
            },
          },
        },
        vb:space{
          height = MARGIN,
        },
        vb:row{
          vb:text{
            text = "Scanning options",
            width = label_w,
          },
          vb:column{
            vb:row{
              vb:checkbox{
                id = "check_unreferenced",
                bind = options.check_unreferenced,
                --[[
                value = xCleaner.check_unreferenced,
                notifier = function()
                  local elm = self.vb.views.check_unreferenced
                  xCleaner.check_unreferenced = elm.value
                end
                ]]
              },
              vb:text{
                text = "Auto-select unreferenced content",
              },
            },
            vb:row{
              vb:checkbox{
                id = "skip_empty",
                bind = options.skip_empty_samples,
                --[[
                value = xCleaner.skip_empty_samples,
                ]]
                notifier = function()
                  local elm = self.vb.views.skip_empty
                  xCleaner.skip_empty_samples = elm.value
                end
              },
              vb:text{
                text = "Leave empty samples intact",
              },
            },        
            vb:row{
              vb:checkbox{
                id = "find_issues",
                bind = options.find_issues,
                --[[
                value = self._x.find_issues,
                notifier = function()
                  local elm = self.vb.views.find_issues
                  self._x:set_issue_scanning_pref(elm.value)
                end
                ]]
              },
              vb:text{
                text = "Detect channel issues (increases scanning time!)",
              },
            },
            vb:row{
              vb:checkbox{
                bind = options.detect_leading_trailing_silence,
              },
              vb:text{
                text = "Detect leading/trailing silence",
              },
            },
            vb:row{
              vb:space{
                width = 20,
              },
              vb:row{
                spacing = -3,
                style="plain",
                vb:valuefield{
                  min = 0,
                  max = 1,
                  width = 40,
                  bind = options.detect_silence_threshold,                
                  tostring = function(val)
                    return ("%d"):format(math.lin2db(val))
                  end,
                  tonumber = function(val)
                    return math.db2lin(val)
                  end,
                },
              },
              vb:text{
                text = "Threshold (db)",
              },
              vb:checkbox{
                bind = options.trim_leading_silence,
              },
              vb:text{
                text = "Trim leading",
              },              
            },

          },
        },

      },

    },
    vb:column{
      id = "tabs",
      --style = "border",
    },
    --[[
    vb:column{
      style = "group",
      margin = 4,
    },
    ]]
    vb:multiline_textfield{
      id = "info",
      text = "",
      height = 60,
      width = DIALOG_W,
      font = "mono",
    },
    vb:row{
      vb:button{
        text = "Remove Checked",
        id = "bt_remove_selected",
        height = large_button_h,
        width = 120,
        notifier = function()

          local choice = renoise.app():show_prompt("",
            "Are you sure you want to remove the selected assets?", 
            {"OK","Cancel"})

          if (choice == "OK") then
            self._x:remove_assets()
          end

        end,
      },
      vb:button{
        text = "Process Selected",
        id = "bt_fix_issue",
        height = large_button_h,
        width = 120,
        notifier = function()
          --self._x:prepare_fix()
          self:fix_selected_item()
        end,
      },
      vb:button{
        text = "Process All",
        id = "bt_fix_all_issues",
        height = large_button_h,
        width = 100,
        notifier = function()
          --renoise.app():show_message("Not yet implemented")
          
          self._x:fix_issues()

        end,
      },
    }
  }

  -- add tabs ---------------------------------------------

  self.tabs = vTabs{
    vb = vb,
    index = 0,
    layout = vTabs.LAYOUT.ABOVE,
    labels = xCleanerUI.TAB_LABELS,
    --width = DIALOG_W,
    height = nil,
    switcher_width = DIALOG_W,
    tabs ={
      vb:row{
        id = "tab_sample_table",
        style="plain",
      },
      vb:row{
        id = "tab_mod_table",
        style="group",
      },
      vb:row{
        id = "tab_fx_table",
        style="panel",
      },
    },
  }
  vb.views.tabs:add_child(self.tabs.view)
  self.tabs.index = 1

  self:build_fx_table()
  self:build_mod_table()
  self:build_samples_table()

  self:update_sample_name_options()

  return content

end

--------------------------------------------------------------------------------

function xCleanerUI:build_fx_table()
  TRACE("xCleanerUI:build_fx_table()")

  local fxchain_show = function(cell,checked)
    local item,item_index = cell.owner.dataprovider:get(cell.item_id)
    if item then
      self:focus_to_fxchain(item_index)
      self:add_to_log(item.summary,true)
    end
  end

  local fxchain_select = function(cell,checked)
    local item,item_index = cell.owner.dataprovider:get(cell.item_id)
    item.checked = checked
    self:update_tab_labels()
    self:update_main_buttons()
  end

  local fxchain_select_all = function(cell,checked)
    self.fx_table.header_defs.checked.data = checked
    for k,v in ipairs(self._x.fxchains) do
      v.checked = checked
    end
    self.fx_table:update()
    self:update_tab_labels()
    self:update_main_buttons()
  end

  self.fx_table = vTable{
    vb = self.vb,
    width = DIALOG_W,
    column_defs = {
      {key = "show",  col_width=25, col_type=vTable.CELLTYPE.BITMAP, notifier=fxchain_show},
      {key = "checked", col_width=20, col_type=vTable.CELLTYPE.CHECKBOX, notifier=fxchain_select},
      {key = "show_summary", col_width=30, col_type=vTable.CELLTYPE.BUTTON, pressed=fxchain_show},
      {key = "index", col_width=25, col_type=vTable.CELLTYPE.TEXT, align="center", formatting="%02d"},
      {key = "name",  col_width="auto", col_type=vTable.CELLTYPE.TEXT, notifier=fxchain_show},
    },
    header_defs = {
      show  = {data = ""},
      checked = {data = false,  col_type=vTable.CELLTYPE.CHECKBOX, notifier=fxchain_select_all},
      show_summary = {data = "Info", align="center"},
      index   = {data = "#", align="center"},
      name    = {data = "Effect Chain"},
    },
    num_rows = 12,
    on_update_complete = function()
      self:highlight_row(xCleanerUI.TAB.EFFECTS)
    end,
  }
  self.fx_table:update()
  self.vb.views.tab_fx_table:add_child(self.fx_table.view)

end

--------------------------------------------------------------------------------

function xCleanerUI:build_mod_table()
  TRACE("xCleanerUI:build_mod_table()")

  local modset_show = function(cell,checked)
    local item,item_index = cell.owner.dataprovider:get(cell.item_id)
    if item then
      self:focus_to_modset(item_index)
      self:add_to_log(item.summary,true)
    end
  end

  local modset_select = function(cell,checked)
    --print(">>> modset_select",cell,checked)
    local item,item_index = cell.owner.dataprovider:get(cell.item_id)
    item.checked = checked
    self:update_tab_labels()
    self:update_main_buttons()
  end

  local modset_select_all = function(cell,checked)
    self.mod_table.header_defs.checked.data = checked
    for k,v in ipairs(self._x.modsets) do
      v.checked = checked
    end
    self.mod_table:update()
    self:update_tab_labels()
    self:update_main_buttons()
  end

  self.mod_table = vTable{
    vb = self.vb,
    width = DIALOG_W,
    num_rows = 12,
    column_defs = {
      {key = "show",  col_width=25, col_type=vTable.CELLTYPE.BITMAP, notifier=modset_show},
      {key = "checked", col_width=20, col_type=vTable.CELLTYPE.CHECKBOX, notifier=modset_select},
      {key = "show_summary", col_width=30, col_type=vTable.CELLTYPE.BUTTON, pressed=modset_show},
      {key = "index", col_width=25, col_type=vTable.CELLTYPE.TEXT, align="center", formatting="%02d"},
      {key = "name",  col_width="auto", col_type=vTable.CELLTYPE.TEXT, notifier=modset_show},
    },
    header_defs = {
      show  = {data = ""},
      checked = {data = false,  col_type=vTable.CELLTYPE.CHECKBOX, notifier=modset_select_all},
      show_summary = {data = "Info", align="center"},
      index = {data = "#",   align="center"},
      name  = {data = "Modulation Set"},
    },
    on_update_complete = function()
      self:highlight_row(xCleanerUI.TAB.MODULATION)
    end
  }
  --self.mod_table:update()
  self.vb.views.tab_mod_table:add_child(self.mod_table.view)

end

--------------------------------------------------------------------------------

function xCleanerUI:build_samples_table()
  TRACE("xCleanerUI:build_samples_table()")

  local header_checkbox_handler = function(cell,checked)
    self.sample_table.header_defs.checked.data = checked
    --print("self.sample_table.header_defs.checked.data",self.sample_table.header_defs.checked.data)
    for k,v in ipairs(self._x.samples) do
      v.checked = checked
    end
    --print("self._x.samples",rprint(self._x.samples))
    self.sample_table:update()
    self:update_mod_fx_tables()
    self:update_tab_labels()
    self:update_main_buttons()
    
  end

  local checkbox_handler = function(cell,checked)
    --print("checkbox_handler(cell,checked)",cell,checked)
    --self._x.samples[cell.item_id].checked = checked
    local item = cell.owner.dataprovider:get(cell.item_id)
    item.checked = checked
    self:update_mod_fx_tables()
    self:update_tab_labels()
    self:update_main_buttons()
  end

  local action_handler = function(cell,value)
    --print("action_handler(cell,checked)",cell,value)
    local item = cell.owner.dataprovider:get(cell.item_id)
    item.action = value
  end

  local select_sample_handler = function(cell,do_focus)
    --print("select_sample_handler",cell,do_focus)
    local item,item_index = cell.owner.dataprovider:get(cell.item_id)
    if item then
      if do_focus then
        self:focus_to_sample(item_index)
      end
      local instr_idx = renoise.song().selected_instrument_index
      if (instr_idx == self._x.instr_idx) then
        renoise.song().selected_sample_index = item_index
      else
        self._x.sample_idx = item_index
        self:highlight_row(xCleanerUI.TAB.SAMPLES)
      end
      self:display_item_summary(item)
    end
  end

  local focus_sample_handler = function(idx)
    --print("focus_sample_handler",idx)
    select_sample_handler(idx,true)
  end

  local valuebox_handler = function(idx,value)
    --print("focus_sample_handler",idx,value)
    local item = cell.owner.dataprovider:get(cell.item_id)
    item.valuebox = value
  end

  local zero_indexed = function(val)
    --print("zero_indexed",val)
    return val-1
  end

  self.sample_table = vTable{
    vb = self.vb,
    width = DIALOG_W,
    column_defs = {
      {key = "show",  col_width=25, col_type=vTable.CELLTYPE.BITMAP, notifier=focus_sample_handler},
      {key = "checked", col_width=20, col_type=vTable.CELLTYPE.CHECKBOX, notifier=checkbox_handler},
      {key = "show_summary", col_width=30, col_type=vTable.CELLTYPE.BUTTON, pressed=select_sample_handler},
      {key = "index", col_width=25, col_type=vTable.CELLTYPE.TEXT, align="center", formatting="%02X", transform=zero_indexed },
      {key = "name",  col_width="auto", col_type=vTable.CELLTYPE.TEXT, notifier=select_sample_handler},
      {key = "bit_depth_display",col_width=30, col_type=vTable.CELLTYPE.TEXT, align="center"},
      {key = "num_channels_display",col_width=25, col_type=vTable.CELLTYPE.TEXT, align="center"},
      {key = "sample_rate", col_width=40, col_type=vTable.CELLTYPE.TEXT},
    },
    header_defs = {
      show  = {data = ""},
      checked = {data = false,  col_type=vTable.CELLTYPE.CHECKBOX, notifier=header_checkbox_handler},
      index = {data = "#",  align="center"},
      name  = {data = "Sample"},
      bit_depth_display = {data = "Bits"},
      num_channels_display = {data = "Ch"},
      sample_rate = {data = "Rate"},
      show_summary = {data = "Info", align="center"},
    },
    num_rows = 12,
  }
  self.sample_table.on_update_complete = function()
    -- highlight row
    self:highlight_row(xCleanerUI.TAB.SAMPLES)
    -- add tooltips
    if self._x.samples then
      local col_idx = self.sample_table:get_col_idx("show_summary")
      for row_idx = 1, self.sample_table.num_rows do
        local show_summary_button = self.sample_table:get_cell(row_idx,col_idx)
        local item = self._x.samples[row_idx+self.sample_table.row_offset]
        local str_tooltip = (item) and self._x.samples[row_idx+self.sample_table.row_offset].summary or nil
        show_summary_button:set_tooltip(str_tooltip)
      end
    end
  end
  self.sample_table:update()
  self.vb.views.tab_sample_table:add_child(self.sample_table.view)
  
end

--------------------------------------------------------------------------------
-- display scan results in table (adds a few extra properties)
-- @param time_elapsed (number), the time it took to scan

function xCleanerUI:show_results(time_elapsed)
  TRACE("xCleanerUI:show_results(time_elapsed)",time_elapsed)

  self:populate_table(self.sample_table,self._x.samples,self._x.instr.samples)
  --self:populate_table(self.sample_table,self._x.samples,self._x.instr.sample_modulation_sets)
  --self:populate_table(self.sample_table,self._x.samples,self._x.instr.sample_device_chains)
  
  local count_all_tokens = function(t,token)
    local count = 0
    if (table.is_empty(t)) then
      return count
    end
    for k,v in ipairs(t) do
      count = count+xCleaner.count_tokens(v,token)
    end
    return count
  end

  -- output log message 
  local str_log = ("Finished scanning instrument assets in %.2f seconds"
    .."\nFound %d samples (%d issues)"
    .."\nFound %d modulation sets (%d issues)"
    .."\nFound %d effect chains (%d issues)"):format(
    time_elapsed,
    #self._x.samples,
    count_all_tokens(self._x.samples,"ISSUE"),
    #self._x.modsets,
    count_all_tokens(self._x.modsets,"ISSUE"),
    #self._x.fxchains,
    count_all_tokens(self._x.fxchains,"ISSUE")
  )

  self:add_to_log(str_log,true)
  
  self:update_mod_fx_tables()
  self:update_tab_labels()
  self:update_main_buttons()
  --print("got here - self.tabs.index",self.tabs.index)
  self:highlight_row(self.tabs.index)

end

--------------------------------------------------------------------------------
-- set table data, while providing some default values
-- @param vtable (vTable)
-- @param xdata (table)
-- @param rns_table (table), iterate through samples/modulation/etc.
-- @param maintain_offset (bool), maintain the table row - when possible 

function xCleanerUI:populate_table(vtable,xdata,rns_table,maintain_offset)
  TRACE("xCleanerUI:populate_table(vtable,xdata,rns_table,maintain_offset)",vtable,xdata,rns_table,maintain_offset)

  for i = 1, #rns_table do
    local item = xdata[i]
    if (item) then
      local str_issues = xCleaner.has_issues(item) and "⚠" or 
        xCleaner.has_warnings(item) and "⚠" or ""
      local str_unreferenced = xCleaner.is_unreferenced(item) and "✝" or ""
      item.show_summary = ("%s%s"):format(str_unreferenced,str_issues)
      item.highlighted = false
      item.show = "Icons/Sample_Autoselect.bmp"
      item.name = rns_table[i].name
    end
  end
  -- TODO feature gone
  --vtable:set_header_data("checked",xCleaner.check_unreferenced)
  vtable:set_data(xdata,true)
  
  vtable:update()

end


--------------------------------------------------------------------------------
-- when checking samples on and off, modulation/fx might change

function xCleanerUI:update_mod_fx_tables()
  TRACE("xCleanerUI:update_mod_fx_tables()")

  local instr = self._x.instr

  self._x:gather_modulation()
  self._x:gather_effects()

  self:populate_table(self.mod_table,self._x.modsets,instr.sample_modulation_sets)
  self:populate_table(self.fx_table,self._x.fxchains,instr.sample_device_chains)

end

--------------------------------------------------------------------------------

function xCleanerUI:show()
  TRACE("xCleanerUI:show()")

  self._x:attach_to_song()

  if not self.dialog or not self.dialog.visible then
    
    if not self.dialog_content then
      self.dialog_content = self:build()
    end

    local function keyhandler(dialog, key)
      if (key.modifiers == "" and key.name == "return") then
        --perform_slicing()
      elseif (key.modifiers == "" and key.name == "esc") then
        self.dialog:close()
      end
    end
      
    self.dialog = renoise.app():show_custom_dialog("xCleaner - instrument cleaner", 
      self.dialog_content, keyhandler)

  else
    self.dialog:show()
  end

  self:update_instr_selector()
  self:update_tab_labels()
  self:update_main_buttons()

end


--------------------------------------------------------------------------------
-- highlight the item relevant to the current tab/table 
-- @param tab_idx (xCleanerUI.TAB)

function xCleanerUI:highlight_row(tab_idx)
  TRACE("xCleanerUI:highlight_row(tab_idx)",tab_idx)

  --[[
  local instr_idx = renoise.song().selected_instrument_index
  if (instr_idx ~= self._x.instr_idx) then
    return
  end
  ]]

  local selected_idx = nil
  local row_idx = nil
  local vtable = nil
  local vdata = nil

  if (tab_idx == xCleanerUI.TAB.SAMPLES) then
    selected_idx = self._x.sample_idx
    vtable = self.sample_table
    vdata = self._x.samples
  elseif (tab_idx == xCleanerUI.TAB.MODULATION) then
    selected_idx = self._x.modset_idx
    vtable = self.mod_table
    vdata = self._x.modsets
  elseif (tab_idx == xCleanerUI.TAB.EFFECTS) then
    selected_idx = self._x.fxchain_idx
    vtable = self.fx_table
    vdata = self._x.fxchains
  else
    error("Unsupported tab index",tab_idx)
  end


  if table.is_empty(vdata) then
    return
  end

  for k,v in ipairs(vdata) do
    if (v.index == selected_idx) then
      row_idx = k
    end
  end

  local col_name_idx = vtable:get_col_idx("name")
  local col_summary_idx = vtable:get_col_idx("show_summary")
  --print("col_name_idx",col_name_idx)
  --print("col_summary_idx",col_summary_idx)

  for i = 1,vtable.num_rows do
    -- set text to normal
    if col_name_idx then
      vtable.cells[i][col_name_idx].font = "normal"
    end
    -- set button to theme color
    if col_summary_idx then
      vtable.cells[i][col_summary_idx].color = {0,0,0}
    end
  end


  if not row_idx then
    return
  end


  -- check if the row is currently visible 
  if (row_idx > (vtable.row_offset + vtable.num_rows)) or
    (row_idx <= vtable.row_offset)
  then
    return
  end

  if col_name_idx then
    vtable.cells[row_idx-vtable.row_offset][col_name_idx].font = "bold"
  end
  if col_summary_idx then
    vtable.cells[row_idx-vtable.row_offset][col_summary_idx].color = {0xcf,0xcf,0xcf}
  end


end

--------------------------------------------------------------------------------

function xCleanerUI:update_instr_selector()
  --print("xCleanerUI:update_instr_selector()")

  local vb = self.vb
  local ctrl = vb.views.instr_source_popup
  local instr_idx = renoise.song().selected_instrument_index

  ctrl.items = get_instrument_list()

  if (self.follow_selection) then
    ctrl.value = instr_idx
  end


end

--------------------------------------------------------------------------------
-- update the text on the tabs
-- when possible, display selected/total item count too

function xCleanerUI:update_tab_labels()
  --print("xCleanerUI:update_tab_labels()")

  local lbls = xCleanerUI.TAB_LABELS

  if not table.is_empty(self._x.samples) then
    local sel_samples = self:count_checked(self._x.samples)
    local sel_modsets = self:count_checked(self._x.modsets)
    local sel_fxchains = self:count_checked(self._x.fxchains)
    lbls = {
      ("Samples (%i/%i)"):format(sel_samples,#self._x.samples),
      ("Modulation (%i/%i)"):format(sel_modsets,#self._x.modsets),
      ("Effects (%i/%i)"):format(sel_fxchains,#self._x.fxchains),
    }
  end

  self.tabs:set_labels(lbls)

end

--------------------------------------------------------------------------------
-- enable/disable buttons, based on program state

function xCleanerUI:update_main_buttons()
  TRACE("xCleanerUI:update_main_buttons()")

  local bt_remove_selected = self.vb.views.bt_remove_selected
  local bt_fix_issue = self.vb.views.bt_fix_issue
  local bt_fix_all_issues = self.vb.views.bt_fix_all_issues

  bt_remove_selected.active = false
  bt_fix_issue.active = false
  bt_fix_all_issues.active = false

  local instr = renoise.song().instruments[self._x.instr_idx]
  if not instr then
    return
  end

  bt_fix_all_issues.active = true

  local sel_samples = self:count_checked(self._x.samples)
  local sel_modsets = self:count_checked(self._x.modsets)
  local sel_fxchains = self:count_checked(self._x.fxchains)

  -- generally, if *any* item is checked
  if (sel_samples >0) or (sel_modsets >0) or (sel_fxchains >0) then
    bt_remove_selected.active = true
    --bt_fix_all_issues.active = true
  end

  -- if selected item in current tab
  local item_idx,data = self:get_selected()
  if item_idx then
    bt_fix_issue.active = true
  end

end

--------------------------------------------------------------------------------
-- @param item (table)

function xCleanerUI:display_item_summary(item)

  local str_msg = ("## Summary of '%s'\n%s"):format(
    item.name,item.summary)
  self:clear_log()
  self:add_to_log(str_msg)

end

--------------------------------------------------------------------------------
-- invoked when the samplename option has changed

function xCleanerUI:update_sample_name_options()
  TRACE("xCleanerUI:update_sample_name_options()")

  local custom_name = (options.samplename.value == xCleaner.SAMPLENAME.CUSTOM) 
  local create_name = (options.samplename.value > xCleaner.SAMPLENAME.SHORTEN) 
  --local vb_ctrl = self.vb.views["check_samples_keep_name"]
  local vb_textfield = self.vb.views["textfield_sample_name"]
  --local vb_velocity = self.vb.views["checkbox_sample_add_velocity"]
  --local vb_note = self.vb.views["checkbox_sample_add_note"]

  vb_textfield.visible = custom_name 
  --vb_velocity.active = create_name
  --vb_note.active = create_name



end

--------------------------------------------------------------------------------
-- 

function xCleanerUI:update_item(item,tab_idx)
  TRACE("xCleanerUI:update_item(item,tab_idx)",item,tab_idx)

  
  self:display_item_summary(item)


  local maintain_table_offset = true
  if (tab_idx == 1) then
    self:populate_table(
      self.sample_table,self._x.samples,self._x.instr.samples,
      maintain_table_offset)

  -- TODO other tabs

  end
end
--------------------------------------------------------------------------------
-- TODO use vTable/vVector.match
-- @param t (table)
-- @return int

function xCleanerUI:count_checked(t)
  TRACE("xCleanerUI:count_checked(t)",t)

  local count = 0
  if (table.is_empty(t)) then
    return count
  end

  for k,v in ipairs(t) do
    if (type(v.checked)=="boolean") and (v.checked) then
      count = count+1
    end
  end
  return count
  
end
--------------------------------------------------------------------------------
-- @return int
-- @return table

function xCleanerUI:get_selected()
  TRACE("xCleanerUI:get_selected()")

  local tab_idx = self.tabs.index
  local data,item_idx
  if (tab_idx == xCleanerUI.TAB.SAMPLES) then
    data = self._x.samples
    item_idx = self._x.sample_idx
  elseif (tab_idx == xCleanerUI.TAB.MODULATION) then
    data = self._x.modsets
    item_idx = self._x.modset_idx
  elseif (tab_idx == xCleanerUI.TAB.EFFECTS) then
    data = self._x.fxchains
    item_idx = self._x.fxchain_idx
  end

  return item_idx,data

end

--------------------------------------------------------------------------------

function xCleanerUI:fix_selected_item()
  TRACE("xCleanerUI:fix_selected_item()")

  local instr = self._x.instr
  local tab_idx = self.tabs.index
  local item_idx,data = self:get_selected()
  --print("item_idx,data",item_idx,data)
  
  local update_callback = function(item,tab_idx)
    self:update_item(item,tab_idx)
  end

  local item = vVector.match_by_key_value(data,"index",item_idx)
  --print("item",rprint(item))
  if not xCleaner.has_issues(item) then
    renoise.app():show_message("This item has no known issues that can be fixed")
    return
  end

  self._x:fix_issue(instr,tab_idx,data,item_idx,update_callback)

end

--------------------------------------------------------------------------------
-- @return table, checked item indices {1,5,11,...}

function xCleanerUI:get_checked(t)
  TRACE("xCleanerUI:get_checked(t)",t)
  --rprint(t)

  local rslt = {}
  if (table.is_empty(t)) then
    return rslt
  end

  for k,v in ipairs(t) do
    if (type(v.checked)=="boolean") and v.checked then
      table.insert(rslt,v.index)
    end
  end
  return rslt
  
end


--------------------------------------------------------------------------------

function xCleanerUI:clear_log(txt)
  TRACE("xCleanerUI:clear_log()")

  self.vb.views.info.text = ""

end

--------------------------------------------------------------------------------
-- TODO use vLog widget

function xCleanerUI:add_to_log(txt,autoscroll)
  TRACE("xCleanerUI:add_to_log(txt,autoscroll)",txt,autoscroll)

  txt = cString.strip_leading_trailing_chars(txt,"\n",true,true)

  local elm = self.vb.views.info
  if (elm.text == nil) or (elm.text == "") then
    elm.text = txt
  else
    elm.text = ("%s\n%s"):format(elm.text,txt)
  end

  if autoscroll then
    elm:scroll_to_last_line()
  end

end

--------------------------------------------------------------------------------
-- bring focus to the active/scanned instrument
-- @param idx (int)
-- @return bool

function xCleanerUI:focus_instr()
  TRACE("xCleanerUI:focus_instr()")

  local instr = renoise.song().instruments[self._x.instr_idx]
  if not instr then
    LOG("could not find instrument with index",self._x.instr_idx)
    return false
  else
    renoise.song().selected_instrument_index = self._x.instr_idx
    return true
  end

end

--------------------------------------------------------------------------------

function xCleanerUI:focus_to_sample(idx)
  TRACE("xCleanerUI:focus_to_sample(idx)",idx)

  if not self:focus_instr() then
    LOG("*** Couldn't bring focus to sample")
    return
  end

  -- if already in the sampler, retain existing focus 
  if (renoise.app().window.active_middle_frame < 2) or
    (renoise.app().window.active_middle_frame > 6)
  then
    renoise.app().window.active_middle_frame = 
      renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR
  end

end


--------------------------------------------------------------------------------

function xCleanerUI:focus_to_modset(idx)
  TRACE("xCleanerUI:focus_to_modset(idx)",idx)

  if not self:focus_instr() then
    return
  end

  renoise.app().window.active_middle_frame = 
    renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_MODULATION

  renoise.song().selected_sample_modulation_set_index = idx

end

--------------------------------------------------------------------------------

function xCleanerUI:focus_to_fxchain(idx)
  TRACE("xCleanerUI:focus_to_fxchain(idx)",idx)

  if not self:focus_instr() then
    return
  end

  renoise.app().window.active_middle_frame = 
    renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EFFECTS

  renoise.song().selected_sample_device_chain_index = idx

end

