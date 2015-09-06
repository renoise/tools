--[[============================================================================
xItemModset
============================================================================]]--
--[[]]

class 'xItemModset' (xItem)

xItemModset.column_defs = {
  {key = "show",    col_width=25, col_type=vTable.CELLTYPE.BITMAP},
  {key = "checked", col_width=20, col_type=vTable.CELLTYPE.CHECKBOX},
  {key = "summary", col_width=30, col_type=vTable.CELLTYPE.BUTTON},
  {key = "index",   col_width=25, align="center", formatting="%02d"},
  {key = "name",    col_width="auto"},
  {key = "vol",     col_width=30, align="center", transform=function(val) return (val==0) and "--" or val end },
  {key = "pan",     col_width=30, align="center", transform=function(val) return (val==0) and "--" or val end },
  {key = "ptc",     col_width=30, align="center", transform=function(val) return (val==0) and "--" or val end },
  {key = "cut",     col_width=30, align="center", transform=function(val) return (val==0) and "--" or val end },
  {key = "res",     col_width=30, align="center", transform=function(val) return (val==0) and "--" or val end },
  {key = "drv",     col_width=30, align="center", transform=function(val) return (val==0) and "--" or val end },
}

xItemModset.header_defs = {
  index   = {data = "#",   align="center"},
  name    = {data = "Modulation Set"},
  checked = {data = false,  col_type=vTable.CELLTYPE.CHECKBOX},
  show    = {data = ""},
  summary  = {data = "Info", align="center"},
  vol     = {data = "Vol", align="center"},
  pan     = {data = "Pan", align="center"},
  ptc     = {data = "Ptc", align="center"},
  cut     = {data = "Cut", align="center"},
  res     = {data = "Res", align="center"},
  drv     = {data = "Drv", align="center"},
}

--------------------------------------------------------------------------------

function xItemModset:__init(...)

	self.sample_links = {}

  xItem.__init(self,...)

end

--------------------------------------------------------------------------------
-- export by bringing focus to item, then executing the API call
-- @param instr_idx (int)
-- @param export_path (string)
-- @param args (table) not used 
-- @return bool, false when export failed

function xItemModset:export(instr_idx,export_path,args)
  TRACE("xItemModset:export(instr_idx,export_path,args)",instr_idx,export_path,args)

  local rslt = false
  local instr,modset = self:focus(instr_idx)
  if modset then
    local filename = self:prep_export_name(export_path,modset.name,"xrno")
    rslt = renoise.app():save_instrument_modulation_set(filename)
  else
    error("Failed to bring focus to modulation set before export")
  end

  return rslt

end

--------------------------------------------------------------------------------
-- "bring focus to this item before export" 
-- @return renoise.Instrument, renoise.InstrumentPhrase or false

function xItemModset:focus(instr_idx)
  TRACE("xItemModset:focus(instr_idx)",instr_idx)

  local instr = self:focus_instr(instr_idx)
  if not instr then
    return false
  end

  local modset = instr.sample_modulation_sets[self.index]
  if modset then
    renoise.song().selected_sample_modulation_set_index = self.index
    return instr,modset
  else
    --print("*** no modulation set found at this index",self.index)
    return false
  end

end

