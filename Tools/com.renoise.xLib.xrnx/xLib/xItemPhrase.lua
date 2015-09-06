--[[============================================================================
xItemPhrase
============================================================================]]--
--[[]]

class 'xItemPhrase' (xItem)

xItemPhrase.column_defs = {
  {key = "show",    col_width=25, col_type=vTable.CELLTYPE.BITMAP},
  {key = "checked", col_width=20, col_type=vTable.CELLTYPE.CHECKBOX},
  {key = "summary", col_width=30, col_type=vTable.CELLTYPE.BUTTON},
  {key = "index",   col_width=25, align="center", formatting="%02d"},
  {key = "name",    col_width="auto"},
  {key = "num_lines",col_width=35},
  {key = "lpb",     col_width=30},
  {key = "visible_note_cols",col_width=30},
  {key = "instr_col",col_width=30},
  --{key = "keymapped",col_width=30},
}

xItemPhrase.header_defs = {
  checked   = {data = false, col_type=vTable.CELLTYPE.CHECKBOX},
  index     = {data = "#", align="center"},
  instr_col = {data = "##", align="center"},
  lpb       = {data = "LPB", align="center"},
  name      = {data = "Phrase"},
  num_lines = {data = "Lines", align="center"},
  show      = {data = ""},
  summary      = {data = "Info", align="center"},
  visible_note_cols = {data = "Cols", align="center"},
  --keymapped = {data = "KMap", align="center"},
}

--------------------------------------------------------------------------------

function xItemPhrase:__init(...)

  local args = select(1,...)

	self.instr_col          = args.instr_col
	self.lpb                = args.lpb
	self.num_lines          = args.num_lines
	self.visible_note_cols  = args.visible_note_cols

  xItem.__init(self,...)

end


--------------------------------------------------------------------------------
-- export by bringing focus to item, then executing the API call
-- @return bool, false when export failed

function xItemPhrase:export(instr_idx,export_path,args)
  TRACE("xItemPhrase:export(instr_idx,export_path,args)",instr_idx,export_path,args)

  local rslt = false
  local instr,phrase = self:focus(instr_idx)
  if phrase then
    local filename = self:prep_export_name(export_path,phrase.name,"xrnz")
    rslt = renoise.app():save_instrument_phrase(filename)
  else
    error("Failed to bring focus to phrase before export")
  end

  return rslt

end

--------------------------------------------------------------------------------
-- "bring focus to this item before export" 
-- @return renoise.Instrument, renoise.InstrumentPhrase or false

function xItemPhrase:focus(instr_idx)
  TRACE("xItemPhrase:focus(instr_idx)",instr_idx)

  local instr = self:focus_instr(instr_idx)
  if not instr then
    return false
  end

  local phrase = instr.phrases[self.index]
  if phrase then
    rns.selected_phrase_index = self.index
    return instr,phrase
  else
    --print("*** no phrase found at this index",self.index)
    return false
  end

end
