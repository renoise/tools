--[[============================================================================
xItemFxChain
============================================================================]]--
--[[]]

class 'xItemFxChain' (xItem)

xItemFxChain.column_defs = {
  {key = "show",    col_width=25, col_type=vTable.CELLTYPE.BITMAP},
  {key = "checked", col_width=20, col_type=vTable.CELLTYPE.CHECKBOX},
  {key = "summary", col_width=30, col_type=vTable.CELLTYPE.BUTTON},
  {key = "index",   col_width=25, align="center", formatting="%02d"},
  {key = "name",    col_width="auto"},
  {key = "num_devices", col_width=25, align="center"},
  {key = "routing", col_width=80},
}

xItemFxChain.header_defs = {
  index   = {data = "#", align="center"},
  name    = {data = "Effect Chain"},
  checked = {data = false,  col_type=vTable.CELLTYPE.CHECKBOX},
  show    = {data = ""},
  summary = {data = "Info", align="center"},
  num_devices = {data = "#Devices", align="center"},
  routing = {data = "Output Routing"},
}

--------------------------------------------------------------------------------

function xItemFxChain:__init(...)

	self.sample_links = {}
	self.device_links_in = {}
	self.device_links_out = {}

  self.routing = nil

  xItem.__init(self,...)

end


--------------------------------------------------------------------------------
-- export by bringing focus to item, then executing the API call
-- @param instr_idx (int)
-- @param export_path (string)
-- @param args (table) not used 
-- @return bool, false when export failed

function xItemFxChain:export(instr_idx,export_path,args)
  TRACE("xItemFxChain:export(instr_idx,export_path,args)",instr_idx,export_path,args)

  local rslt = false
  local instr,fxchain = self:focus(instr_idx)
  if fxchain then
    local filename = self:prep_export_name(export_path,fxchain.name,"xrnt")
    rslt = renoise.app():save_instrument_device_chain(filename)
  else
    error("Failed to bring focus to effect-chain before export")
  end

  return rslt

end

--------------------------------------------------------------------------------
-- "bring focus to this item before export" 
-- @return renoise.Instrument, renoise.InstrumentPhrase or false

function xItemFxChain:focus(instr_idx)
  TRACE("xItemFxChain:focus(instr_idx)",instr_idx)

  local instr = self:focus_instr(instr_idx)
  if not instr then
    return false
  end

  local fxchain = instr.sample_device_chains[self.index]
  if fxchain then
    rns.selected_sample_device_chain_index = self.index
    return instr,fxchain
  else
    --print("*** no effect-chain found at this index",self.index)
    return false
  end

end
