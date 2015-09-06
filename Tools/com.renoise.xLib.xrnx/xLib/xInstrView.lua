--[[============================================================================
xInstrView
============================================================================]]--

--[[

  "Instrument View" - using tabs and tables to show instrument assets 

  relies on some methods from xMerger/xCleaner to be present

  In progress: keyhandler methods up/down

]]

--------------------------------------------------------------------------------

require (_xlibroot.."xLib")
require (_xlibroot.."xItem")
require (_xlibroot.."xItemSample")
require (_xlibroot.."xItemModset")
require (_xlibroot.."xItemFxChain")
require (_xlibroot.."xItemPhrase")

--------------------------------------------------------------------------------

class 'xInstrView'

xInstrView.TAB = {
  SAMPLES = 1,
  MODULATION = 2,
  EFFECTS = 3,
  PHRASES = 4,
}

xInstrView.TAB_LABELS = {
  "Samples","Modulation","Effects","Phrases"
}

xInstrView.TABLE_ROWS = 12

--------------------------------------------------------------------------------
-- @param xMerger, instance of main class
-- @param vb (ViewBuilder)
-- @param view (renoise.Views.Rack) 
-- @param controls_view (renoise.Views.Rack) 

function xInstrView:__init(xMerger,vb,view,controls_view)
  TRACE("xInstrView:__init()",xMerger,vb,view,controls_view)

  --- (xMerger) instance of main class
  --x = xMerger

  -- (ViewBuilder) 
  self.vb = vb

  -- (renoise.Views.Rack) tabs+table
  self.view = view

  -- (renoise.Views.Rack) instr.selector
  self.controls_view = controls_view

  -- (bool) true = collect information whenever we switch instrument
  self.auto_update = false

  -- (xLib.DESTINATION) acting as source or target?
  -- defined when using two instances of xInstrView 
  self.destination = nil

  self.uid = vLib.generate_uid()

  self.width = 200
  self.controls_width = 200
  self.num_rows = xInstrView.TABLE_ROWS

  -- set when gathering information
  self.instr = nil
  self.instr_idx = nil

  self.sample_idx = nil
  self.modset_idx = nil
  self.fxchain_idx = nil
  self.phrase_idx = nil

  self.samples = {}
  self.modsets = {}
  self.fxchains = {}
  self.phrases = {}

  -- (vTabs) 
  self.tabs = nil

  -- (vTable)
  self.sample_table = nil
  self.mod_table = nil
  self.fx_table = nil
  self.phrase_table = nil

  -- (function) handle when items are checked
  -- @param tab_idx (int)
  -- @param item_id (int)
  self.on_checked = nil

end

--------------------------------------------------------------------------------

function xInstrView:build()
  TRACE("xInstrView:build()")
  
  local vb = self.vb

  local controls_content = vb:row{

    vb:popup {
      items = {},
      id = self.uid .. "instr_popup",
      value = 1,
      width = self.controls_width-xLib.LARGE_BUTTON_H,
      height = xLib.LARGE_BUTTON_H,
      notifier = function(idx)
        x._ui:switch_to_instr(idx,self.destination)
      end,
    },
    vb:button{
      text = "≡",
      width = xLib.LARGE_BUTTON_H,
      height = xLib.LARGE_BUTTON_H,
      id = self.uid .. "bt_sync",
      tooltip = "Synchronize with the selected instrument",
      notifier = function(val)
        x._ui:toggle_sync_mode(self.destination)
      end,
    },
  }
  self.controls_view:add_child(controls_content)

  self:build_tabs()
  self:build_sample_table()
  self:build_modset_table()
  self:build_fxchain_table()
  self:build_phrase_table()

end

--------------------------------------------------------------------------------

function xInstrView:build_tabs()
  TRACE("xInstrView:build_tabs()")

  self.tabs = vTabs{
    vb = self.vb,
    --style = "plain",
    labels = xInstrView.TAB_LABELS,              
    layout = vTabs.LAYOUT.ABOVE,                 
    width = self.width,                          
    --height = 200,                                
    switcher_width = self.width,                 
    switcher_height = xLib.SWITCHER_H,           
    notifier = function(idx)
      --print("*** xInstrView self.tabs.on_change",idx)
    end,
    on_resize = function(idx)
      --print("*** xInstrView self.tabs.on_resize",idx)
    end,
    tabs = {
      self.vb:column{},
      self.vb:column{},
      self.vb:column{},
      self.vb:column{},
    }
  }
  self.tabs:set_index(1)
  self.view:add_child(self.tabs.view)

end

--------------------------------------------------------------------------------

function xInstrView:on_summary_pressed(tab_idx,item_id,do_focus)
  TRACE("xInstrView:on_summary_pressed(tab_idx,item_id,do_focus)",tab_idx,item_id,do_focus)

  local item = self:get_item_by_tab_row(tab_idx,item_id)
  --print("item,tab_idx,item_id",item,tab_idx,item_id)

  if item then
    if do_focus then
      --self:focus_to_sample(item.index)
      self:focus_to_item(tab_idx,item.index)
    end
    local instr_idx = rns.selected_instrument_index

    if (instr_idx == self.instr_idx) then
      -- leave the rest to notifiers...
      self:set_renoise_index_by_tab(tab_idx,item.index)
    else
      --self.sample_idx = item.index
      self:set_selected_index_by_tab(tab_idx,item.index)
      self:highlight_row(tab_idx)
    end
    self:display_item_summary(item)
  end

end

--------------------------------------------------------------------------------
--- generic event handler for checkbox cells in table header
-- @param tab_idx (xInstrView.TAB)
-- @param item_id (int)
-- @param checked (bool)

function xInstrView:on_header_checkbox(tab_idx,item_id,checked)
  TRACE("xInstrView:on_header_checkbox(tab_idx,item_id,checked)",tab_idx,item_id,checked)

  local vtable = self:get_table_by_tab(tab_idx)

  vtable.header_defs.checked.data = checked
  for k,v in ipairs(vtable.data) do
    v.checked = checked
  end
  --print("self.samples",rprint(self.samples))

  --vtable:update()
  vtable:request_update()

  self:update_tab_labels()

  if self.on_checked then
    self.on_checked(tab_idx,item_id)
  end


end

--------------------------------------------------------------------------------
--- generic event handler for checkbox cells in table body

function xInstrView:on_table_checkbox(tab_idx,elm,checked)
  TRACE("xInstrView:on_table_checkbox(tab_idx,elm,checked)",tab_idx,elm,checked)

  local vtable = self:get_table_by_tab(tab_idx)

  local item = vtable:get_item_by_id(elm.item_id)
  if item then
    item.checked = checked
    self:update_tab_labels()
    if self.on_checked then
      self.on_checked(tab_idx,elm.item_id)
    end
  end

end

--------------------------------------------------------------------------------

function xInstrView:build_sample_table()

  local header_checkbox_handler = function(elm,checked)
    self:on_header_checkbox(xInstrView.TAB.SAMPLES,elm.item_id,checked)
  end

  local checkbox_handler = function(elm,checked)
    self:on_table_checkbox(xInstrView.TAB.SAMPLES,elm,checked)
  end

  local summary_handler = function(elm,do_focus)
    self:on_summary_pressed(xInstrView.TAB.SAMPLES,elm.item_id,do_focus)
  end

  local show_handler = function(elm)
    summary_handler(elm,true)
  end

  self.sample_table = vTable{
    vb = self.vb,
    column_defs = table.rcopy(xItemSample.column_defs),       
    header_defs = table.rcopy(xItemSample.header_defs),       
    width = self.width-3,                                     
    num_rows = self.num_rows,
    on_update_complete = function(v)
      -- highlight selected item
      self:highlight_row(xInstrView.TAB.SAMPLES)
      -- add tooltips
      if self.samples then
        local col_idx = v:get_col_idx("summary")
        for row_idx = 1, v.num_rows do
          local summary_button = v:get_cell(row_idx,col_idx)
          local item = self.samples[row_idx+v.row_offset]
          local str_tooltip = (item) and self.samples[row_idx+v.row_offset].summary or nil
          --summary_button:set_tooltip(str_tooltip)
          summary_button.tooltip = str_tooltip
        end
      end
    end,

  }

  -- add customizations to the table
  self.sample_table.name = "sample_table"
  self.sample_table:set_column_def("show","notifier",show_handler)           
  self.sample_table:set_column_def("checked","notifier",checkbox_handler)    
  self.sample_table:set_column_def("summary","pressed",summary_handler)    
  self.sample_table:set_header_def("checked","notifier",header_checkbox_handler) 
  self:add_symbolized_summary(xInstrView.TAB.SAMPLES)

  self.tabs:add_content(1,self.sample_table.view)
  --self.sample_table:update()
  self.sample_table:request_update()

end

--------------------------------------------------------------------------------
-- create a compact representation of the summary 
-- @tab_idx (xInstrView.TAB)
-- @return string

function xInstrView:add_symbolized_summary(tab_idx)
  TRACE("xInstrView:add_symbolized_summary(tab_idx)",tab_idx)

  local vtable = self:get_table_by_tab(tab_idx)
  local fn_transform = function(val,vcell)
    --print("fn_transform(val,vcell)",val,vcell)
    -- no data id - cast to string 
    if not vcell.item_id then
      return tostring(vcell.text)
    end
    -- return the (previously computed) symmary_symbol
    local xitem = vtable:get_item_by_id(vcell.item_id)
    if not xitem then
      --print("fn_transform got here 2",vcell.text)
      return tostring(vcell.text)
    end
    --print("fn_transform got here 3",vcell.text)
    return xitem.summary_symbol
  end
  vtable:set_column_def("summary","transform",fn_transform)
  
end

-------------------------------------------------------------------------------

function xInstrView:build_modset_table()

  local header_checkbox_handler = function(elm,checked)
    self:on_header_checkbox(xInstrView.TAB.MODULATION,elm.item_id,checked)
  end

  local checkbox_handler = function(elm,checked)
    self:on_table_checkbox(xInstrView.TAB.MODULATION,elm,checked)
  end

  local summary_handler = function(elm,do_focus)
    self:on_summary_pressed(
      xInstrView.TAB.MODULATION,elm.item_id,do_focus)
  end

  local show_handler = function(elm)
    summary_handler(elm,true)
  end

  --self.mod_table = vTable(self.vb,self.vb.views[self.uid.."tab_mod_table"])
  self.mod_table = vTable{
    vb = self.vb,
    --id = self.uid.."tab_mod_table",
    column_defs = table.rcopy(xItemModset.column_defs),          
    header_defs = table.rcopy(xItemModset.header_defs),   
    width = self.width-3,
    num_rows = self.num_rows,
    on_update_complete = function(v)
      self:highlight_row(xInstrView.TAB.MODULATION)
    end
  }
  -- add customizations to the table
  self.mod_table.name = "mod_table"
  self.mod_table:set_column_def("show","notifier",show_handler)
  self.mod_table:set_column_def("checked","notifier",checkbox_handler)
  self.mod_table:set_column_def("summary","pressed",summary_handler)
  self.mod_table:set_header_def("checked","notifier",header_checkbox_handler)
  self:add_symbolized_summary(xInstrView.TAB.MODULATION)

  self.tabs:add_content(2,self.mod_table.view)
  --self.mod_table:update()
  self.mod_table:request_update()

end

--------------------------------------------------------------------------------

function xInstrView:build_fxchain_table()

  local header_checkbox_handler = function(elm,checked)
    TRACE("xInstrView - header_checkbox_handler fired...")
    self:on_header_checkbox(xInstrView.TAB.EFFECTS,elm.item_id,checked)
  end

  --[[
  local checkbox_handler = function(elm,checked)
    self.fxchains[elm.item_id].checked = checked
    self:update_tab_labels()
    if self.on_checked then
      self.on_checked(xInstrView.TAB.EFFECTS,elm.item_id)
    end
  end
  ]]
  local checkbox_handler = function(elm,checked)
    self:on_table_checkbox(xInstrView.TAB.EFFECTS,elm,checked)
  end

  local summary_handler = function(elm,do_focus)
    self:on_summary_pressed(
      xInstrView.TAB.EFFECTS,elm.item_id,do_focus)
  end

  local show_handler = function(elm)
    summary_handler(elm,true)
  end

  --self.fx_table = vTable(self.vb,self.vb.views[self.uid.."tab_fx_table"])
  self.fx_table = vTable{
    vb = self.vb,
    --id = self.uid.."tab_fx_table",
    column_defs = table.rcopy(xItemFxChain.column_defs),    
    header_defs = table.rcopy(xItemFxChain.header_defs),    
    width = self.width-3,
    num_rows = self.num_rows,
    on_update_complete = function(v)
      self:highlight_row(xInstrView.TAB.EFFECTS)
    end,
  }
  -- add customizations to the table
  self.fx_table:set_column_def("show","notifier",show_handler)
  self.fx_table:set_column_def("checked","notifier",checkbox_handler)
  self.fx_table:set_column_def("summary","pressed",summary_handler)
  self.fx_table:set_header_def("checked","notifier",header_checkbox_handler)
  self:add_symbolized_summary(xInstrView.TAB.EFFECTS)

  self.tabs:add_content(3,self.fx_table.view)
  --self.fx_table:update()
  self.fx_table:request_update()

end

--------------------------------------------------------------------------------

function xInstrView:build_phrase_table()

  local header_checkbox_handler = function(elm,checked)
    self:on_header_checkbox(xInstrView.TAB.PHRASES,elm.item_id,checked)
  end

  --[[
  local checkbox_handler = function(elm,checked)
    self.phrases[elm.item_id].checked = checked
    self:update_tab_labels()
    if self.on_checked then
      self.on_checked(xInstrView.TAB.PHRASES,elm.item_id)
    end
  end
  ]]
  local checkbox_handler = function(elm,checked)
    self:on_table_checkbox(xInstrView.TAB.PHRASES,elm,checked)
  end

  local summary_handler = function(elm,do_focus)
    self:on_summary_pressed(
      xInstrView.TAB.PHRASES,elm.item_id,do_focus)
  end

  local show_handler = function(elm)
    summary_handler(elm,true)
  end

  --self.phrase_table = vTable(self.vb,self.vb.views[self.uid.."tab_phrase_table"])
  self.phrase_table = vTable{
    vb = self.vb,
    --id = self.vb.views[self.uid.."tab_phrase_table",
    column_defs = table.rcopy(xItemPhrase.column_defs),   
    header_defs = table.rcopy(xItemPhrase.header_defs),   
    width = self.width - 3,
    num_rows = self.num_rows,
    on_update_complete = function()
      self:highlight_row(xInstrView.TAB.PHRASES)
    end,

  }
  -- add customizations to the table
  self.phrase_table:set_column_def("show","notifier",show_handler)
  self.phrase_table:set_column_def("checked","notifier",checkbox_handler)
  self.phrase_table:set_column_def("summary","pressed",summary_handler)
  self.phrase_table:set_header_def("checked","notifier",header_checkbox_handler)
  self:add_symbolized_summary(xInstrView.TAB.PHRASES)

  self.tabs:add_content(4,self.phrase_table.view)
  --self.phrase_table:update()
  self.phrase_table:request_update()

end


--------------------------------------------------------------------------------
-- set table data, while providing some default values
-- @param vtable (vTable)
-- @param xdata (table)
-- @param maintain_offset (bool), maintain the table row - when possible 

function xInstrView.populate_table(vtable,xdata,maintain_offset)
  TRACE("xInstrView.populate_table(vtable,xdata,maintain_offset)",vtable,xdata,maintain_offset)

  if table.is_empty(xdata) then
    --print("*** populate_table - missing data for the table")
    --return
  end

  for i = 1, #xdata do
    local item = xdata[i]
    if (item) then
      item.summary_symbol = item:symbolize_summary()
      item.highlighted = false
      item.show = "Icons/Sample_Autoselect.bmp"
    end
  end
  --vtable:set_data(xdata,true)
  vtable.data = xdata

end


--------------------------------------------------------------------------------
-- highlight the item relevant to the current tab/table 
-- @param tab_idx (xInstrView.TAB)

function xInstrView:highlight_row(tab_idx)
  TRACE("xInstrView:highlight_row(tab_idx)",tab_idx)

  if not tab_idx then
    --print("*** xInstrView no tab is currently set as active")
    return
  end

  local row_idx = nil
  
  local xdata = self:get_data_by_tab(tab_idx)
  if table.is_empty(xdata) then
    --print("*** xInstrView highlight_row - missing data for the table")
    return
  end

  local selected_idx = self:get_selected_index_by_tab(tab_idx)
  --print("selected_idx",selected_idx)
  for k,v in ipairs(xdata) do
    if (v.index == selected_idx) then
      row_idx = k
    end
  end
  --print("row_idx",row_idx)

  -- scroll table if needed
  -- above: offset = row index
  -- below: offset = row index - num_row
  local vtable = self:get_table_by_tab(tab_idx)
  local col_show_idx = vtable:get_col_idx("show")
  local col_name_idx = vtable:get_col_idx("name")
  local col_summary_idx = vtable:get_col_idx("summary")

  -- set all rows to neutral style...
  local cell = nil
  for i = 1,vtable.num_rows do
    if col_name_idx then
      cell = vtable.cells[i][col_show_idx]
      cell.mode = "body_color"
    end
    if col_name_idx then
      cell = vtable.cells[i][col_name_idx]
      cell.font = "normal"
    end
    if col_summary_idx then
      cell = vtable.cells[i][col_summary_idx]
      cell.color = {0,0,0}
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

  --print("got here")
  local row = vtable.cells[row_idx-vtable.row_offset]
  if col_name_idx then
    cell = row[col_show_idx]
    cell.mode = "transparent"
    --print("cell.mode",cell.mode,cell)
  end
  if col_name_idx then
    cell = row[col_name_idx]
    cell.font = "bold"
    --print("cell.font",cell.font,cell)
  end
  if col_summary_idx then
    cell = row[col_summary_idx]
    cell.color = {0xcf,0xcf,0xcf}
    --print("cell.color",cell.color,cell)
  end


end


--------------------------------------------------------------------------------
-- update text on the tabs
-- when possible, display selected/total item count too

function xInstrView:update_tab_labels()
  --print("xInstrView:update_tab_labels()")

  local lbls = xInstrView.TAB_LABELS

  if not table.is_empty(self.samples) then
    local sel_samples = vVector.count_checked(self.samples)
    local sel_modsets = vVector.count_checked(self.modsets)
    local sel_fxchains = vVector.count_checked(self.fxchains)
    local sel_phrases = vVector.count_checked(self.phrases)
    lbls = {
      ("Samples (%i/%i)"):format(sel_samples,#self.samples),
      ("Modulation (%i/%i)"):format(sel_modsets,#self.modsets),
      ("Effects (%i/%i)"):format(sel_fxchains,#self.fxchains),
      ("Phrases (%i/%i)"):format(sel_phrases,#self.phrases),
    }
  end

  self.tabs:set_labels(lbls)

end

--------------------------------------------------------------------------------
-- update with current instruments

function xInstrView:update_instr_popup()
  --print("xInstrView:update_instr_popup()")

  local instr_popup = self.vb.views[self.uid.."instr_popup"]
  instr_popup.items = xLib.get_instrument_list()

end
--------------------------------------------------------------------------------

function xInstrView:get_instr_popup_value()

  local instr_popup = self.vb.views[self.uid.."instr_popup"]
  return instr_popup.value

end
--------------------------------------------------------------------------------

function xInstrView:set_instr_popup_value(val)

  local instr_popup = self.vb.views[self.uid.."instr_popup"]
  instr_popup.value = val

end
--------------------------------------------------------------------------------
-- show the summary of the item
-- @param item (xItem)

function xInstrView:display_item_summary(item)

  local str_msg = ("## Summary of '%s'\n%s"):format(
    item.name,item.summary)
  x._ui.vlog:clear()
  x._ui.vlog:add(str_msg)

end

--------------------------------------------------------------------------------
--- "light" update of table (single item)
-- @param item (xItem)
-- @param tab_idx 

function xInstrView:update_item(item,tab_idx)
  TRACE("xInstrView:update_item(item,tab_idx)",item,tab_idx)

  self:display_item_summary(item)

  local maintain_table_offset = true
  if (tab_idx == 1) then
    xInstrView.populate_table(
      self.sample_table,self.samples,maintain_table_offset)

  -- TODO other tabs

  end
end
--------------------------------------------------------------------------------
-- @return table, checked item indices {1,5,11,...}

function xInstrView:get_checked(t)
  TRACE("xInstrView:get_checked(t)",t)

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
-- @return renoise.Views.Button

function xInstrView:get_sync_button()

  return self.vb.views[self.uid.."bt_sync"]
  
end

--------------------------------------------------------------------------------
-- bring focus to the active/scanned instrument
-- @param idx (int)
-- @return bool

function xInstrView:focus_instr()
  TRACE("xInstrView:focus_instr()")

  local instr = rns.instruments[self.instr_idx]
  if not instr then
    --print("*** could not find instrument with index",self.instr_idx)
    return false
  else
    rns.selected_instrument_index = self.instr_idx
    return true
  end

end


--------------------------------------------------------------------------------
-- update all tables, typically done after a scan when data has changed
-- @param time_elapsed (number), the time it took to scan

function xInstrView:show_results(time_elapsed)
  TRACE("xInstrView:show_results(time_elapsed)",time_elapsed)

  xInstrView.populate_table(self.sample_table, self.samples)
  xInstrView.populate_table(self.mod_table, self.modsets)
  xInstrView.populate_table(self.fx_table, self.fxchains)
  xInstrView.populate_table(self.phrase_table, self.phrases)

  local count_all_tokens = function(t,token)
    local count = 0
    if (table.is_empty(t)) then
      return count
    end
    for k,v in ipairs(t) do
      count = count+v:count_tokens(token)
    end
    return count
  end

  -- output log message 
  local str_log = ("Scanned instrument in %.2f seconds"
    .."\nFound %d samples (%d issues)"
    .."\nFound %d modulation sets (%d issues)"
    .."\nFound %d effect chains (%d issues)"):format(
    time_elapsed,
    #self.samples,
    count_all_tokens(self.samples,"ISSUE"),
    #self.modsets,
    count_all_tokens(self.modsets,"ISSUE"),
    #self.fxchains,
    count_all_tokens(self.fxchains,"ISSUE")
  )

  x._ui.vlog:add(str_log,true)

  self:update_tab_labels()
  self:highlight_row(self.tabs.index)


end


--------------------------------------------------------------------------------
-- called by the keyhandler - select next item in active table

function xInstrView:navigate_down_list()
  TRACE("xInstrView:navigate_down_list()")

  local tab_idx = self.tabs.index
  local row_idx = self:get_selected_index_by_tab(tab_idx)
  if not row_idx then
    --print("No row is selected")
    return
  end

  self:set_selected_table_row_index(tab_idx,row_idx+1)

end

--------------------------------------------------------------------------------
-- called by the keyhandler - select next item in active table

function xInstrView:navigate_up_list()
  TRACE("xInstrView:navigate_up_list()")

  local tab_idx = self.tabs.index
  local row_idx = self:get_selected_index_by_tab(tab_idx)
  if not row_idx then
    --print("*** xInstrView No row is selected")
    return
  end  

  self:set_selected_table_row_index(tab_idx,row_idx-1)

end

--------------------------------------------------------------------------------
-- select item in table, optionally focus/scroll to the item
-- @param tab_idx (xInstrView.TAB) 
-- @param item_idx (int) the item @index
-- @param scroll (focus) TODO 
-- @param scroll (bool) TODO

function xInstrView:set_selected_table_row_index(tab_idx,item_id,focus,scroll)

  local vtable = self:get_table_by_tab(tab_idx)
  local xitem = vtable.data[item_id]
  if xitem then
    -- TODO handle scrolling/active logic row within the vTable class
    self:set_selected_index_by_tab(tab_idx,xitem.index)
  else
    --print("*** xInstrView Could not retrieve xitem")
  end

  self:highlight_row(tab_idx)

end

--------------------------------------------------------------------------------

function xInstrView:focus_to_item(tab_idx,idx)

  if not self:focus_instr() then
    --print("*** couldn't focus")
    return
  end

  if (tab_idx == xInstrView.TAB.SAMPLES) then
    -- if already in the sampler, retain existing focus 
    if (renoise.app().window.active_middle_frame < 2) or
      (renoise.app().window.active_middle_frame > 6)
    then
      renoise.app().window.active_middle_frame = 
        renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR
    end
  elseif (tab_idx == xInstrView.TAB.MODULATION) then
    renoise.app().window.active_middle_frame = 
      renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_MODULATION
    rns.selected_sample_modulation_set_index = idx
  elseif (tab_idx == xInstrView.TAB.EFFECTS) then
    renoise.app().window.active_middle_frame = 
      renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EFFECTS
    rns.selected_sample_device_chain_index = idx
  elseif (tab_idx == xInstrView.TAB.PHRASES) then
    self.instr.phrase_editor_visible = true
    -- FIXME missing/invalid call in API
    rns.selected_phrase_index = idx
  end

end

--------------------------------------------------------------------------------
-- retrieve the currently selected item in any tab
-- @param tab_idx (xInstrView.TAB) 
-- @return int or nil

function xInstrView:get_selected_index_by_tab(tab_idx)
  TRACE("xInstrView:get_selected_index_by_tab(tab_idx)",tab_idx)

  if (tab_idx == xInstrView.TAB.SAMPLES) then
    return self.sample_idx
  elseif (tab_idx == xInstrView.TAB.MODULATION) then
    return self.modset_idx
  elseif (tab_idx == xInstrView.TAB.EFFECTS) then
    return self.fxchain_idx
  elseif (tab_idx == xInstrView.TAB.PHRASES) then
    return self.phrase_idx
  else
    error("Unknown tab type")
  end

end

--------------------------------------------------------------------------------
-- set the currently selected item in any tab
-- @param tab_idx (xInstrView.TAB) 

function xInstrView:set_selected_index_by_tab(tab_idx,int)
  TRACE("xInstrView:set_selected_index_by_tab(tab_idx,int)",tab_idx,int)
 
  if (tab_idx == xInstrView.TAB.SAMPLES) then
    self.sample_idx = int
  elseif (tab_idx == xInstrView.TAB.MODULATION) then
    self.modset_idx = int
  elseif (tab_idx == xInstrView.TAB.EFFECTS) then
    self.fxchain_idx = int
  elseif (tab_idx == xInstrView.TAB.PHRASES) then
    self.phrase_idx = int
  else
    error("Unknown tab type")
  end

end

--------------------------------------------------------------------------------
-- retrieve vtable from any tab
-- @param tab_idx (xInstrView.TAB) 
-- @return vTable or nil

function xInstrView:get_table_by_tab(tab_idx)

  if (tab_idx == xInstrView.TAB.SAMPLES) then
    return self.sample_table
  elseif (tab_idx == xInstrView.TAB.MODULATION) then
    return self.mod_table
  elseif (tab_idx == xInstrView.TAB.EFFECTS) then
    return self.fx_table
  elseif (tab_idx == xInstrView.TAB.PHRASES) then
    return self.phrase_table
  else
    error("Unknown tab type")
  end

end

--------------------------------------------------------------------------------
-- retrieve data from any tab
-- @param tab_idx (xInstrView.TAB) 
-- @return table or nil

function xInstrView:get_data_by_tab(tab_idx)
  TRACE("xInstrView:get_data_by_tab(tab_idx)",tab_idx)

  if (tab_idx == xInstrView.TAB.SAMPLES) then
    return self.samples
  elseif (tab_idx == xInstrView.TAB.MODULATION) then
    return self.modsets
  elseif (tab_idx == xInstrView.TAB.EFFECTS) then
    return self.fxchains
  elseif (tab_idx == xInstrView.TAB.PHRASES) then
    return self.phrases
  else
    error("Unknown tab type")
  end

end

--------------------------------------------------------------------------------
-- set selected "renoise item" index from any tab
-- @param tab_idx (xInstrView.TAB) 
-- @return int or nil

function xInstrView:set_renoise_index_by_tab(tab_idx,int)

  if (tab_idx == xInstrView.TAB.SAMPLES) then
    rns.selected_sample_index = int
  elseif (tab_idx == xInstrView.TAB.MODULATION) then
    rns.selected_sample_modulation_set_index = int
  elseif (tab_idx == xInstrView.TAB.EFFECTS) then
    rns.selected_sample_device_chain_index = int
  elseif (tab_idx == xInstrView.TAB.PHRASES) then
    rns.selected_phrase_index = int
  else
    error("Unknown tab type")
  end

end

--------------------------------------------------------------------------------
-- retrieve item from any tab by its row
-- @param tab_idx (xInstrView.TAB) 
-- @return xItem or nil

function xInstrView:get_item_by_tab_row(tab_idx,item_id)

  local item
  if (tab_idx == xInstrView.TAB.SAMPLES) then
    --item = vVector.match_by_key_value(self.samples,"item_id",item_id)
    item = self.sample_table:get_item_by_id(item_id)
  elseif (tab_idx == xInstrView.TAB.MODULATION) then
    --item = vVector.match_by_key_value(self.modsets,"item_id",item_id)
    item = self.modset_table:get_item_by_id(item_id)
  elseif (tab_idx == xInstrView.TAB.EFFECTS) then
    --item = vVector.match_by_key_value(self.fxchains,"item_id",item_id)
    item = self.fxchain_table:get_item_by_id(item_id)
  elseif (tab_idx == xInstrView.TAB.PHRASES) then
    --item = vVector.match_by_key_value(self.phrases,"item_id",item_id)
    item = self.phrase_table:get_item_by_id(item_id)
  else
    error("Unknown tab type")
  end

  return item

end
