--[[============================================================================
xItem
============================================================================]]--
--[[

  The core class for representing Renoise assets within the xLib library
  When extending this class, implement a focus/export mechanism

]]

class 'xItem'

-- define for table represention
--xItem.column_defs = {}
--xItemSample.header_defs = {}

--------------------------------------------------------------------------------

function xItem:__init(...)
  --TRACE("xItem:__init(...)",...)

  local args = select(1,...)

  -- (string) name, as it appears in the Renoise UI
	self.name = nil 

  -- (int) the index of the item within Renoise
	self.index = nil 

  -- (bool) "ticked" state of the item within the table
  self.checked = args.checked or false

  -- (string) a string containing special "tokens" 
  -- ISSUE - item has a recognized issue (which can be fixed)
  -- WARNING - an issue that require user attention
  -- REMOVE - item is obsolete, can be removed 
  -- KEEP - item is in use, should not be removed
	self.summary = args.summary or ""

  -- brute-force: set other class arguments
  for k,v in pairs(args) do
    self[k] = v
  end

  -- (function)
  self.update_callback = nil

end

--------------------------------------------------------------------------------

function xItem:__tostring()

  return ("xItem - name = '%s', index = %d"):format(self.name,self.index)

end


--------------------------------------------------------------------------------
-- turn the standard "summary" text into a brief representation, 
-- suitable as a button label - e.g. "✝⚠2" (remove, issues/warnings)
-- @return bool

function xItem:symbolize_summary()
  TRACE("xItem:symbolize_summary()")

  local str_issues = self:has_issues() and "⚠" or 
    self:has_warnings() and "⚠" or ""
  local str_unreferenced = self:is_unreferenced() and "✝" or ""
  return ("%s%s"):format(str_unreferenced,str_issues)

end


--------------------------------------------------------------------------------
-- @return bool

function xItem:is_unreferenced()
  --TRACE("xItem:is_unreferenced()",self.summary)
  return (self.summary:match("REMOVE")=="REMOVE") 
end

--------------------------------------------------------------------------------
-- @return bool

function xItem:has_issues()
  --TRACE("xItem:has_issues()",self.summary)
  return (self.summary:match("ISSUE")=="ISSUE") 
end

--------------------------------------------------------------------------------
-- @return bool

function xItem:has_warnings()
  --TRACE("xItem:has_warnings()",self.summary)
  return (self.summary:match("WARNING")=="WARNING") 
end

--------------------------------------------------------------------------------
-- count specific text tokens in the .summary data field
-- @param token (string), i.e. "ISSUE" or "REMOVE" 
-- @return int

function xItem:count_tokens(token)

  local count = 0
  local m = self.summary:gmatch(token)
  for k,v in m do
    count = count+1
  end
  return count
  
end

--------------------------------------------------------------------------------
-- part of the generic "bring focus to this item" scheme
-- @return renoise.Instrument or false

function xItem:focus_instr(instr_idx)

  local instr = rns.instruments[instr_idx]
  if instr then
    rns.selected_instrument_index = instr_idx
    return instr
  else
    --print("xItem:focus_instr - no instrument found at this index",instr_idx)
    return false
  end

end


--------------------------------------------------------------------------------
-- override this method 
-- @param instr_idx (int)
-- @param export_path (string)
-- @param args (table)

function xItem:export(instr_idx,export_path,args)

  TRACE("xItem:export - unimplemented method")

end


--------------------------------------------------------------------------------
-- provide a sanitized, and (optionally) unique name for the exported preset
-- @param string (string)

function xItem:prep_export_name(path,name,ext)
  TRACE("xItem:prep_export_name(path,name,ext)",path,name,ext)

  name = xLib.sanitize_filename(name)
  local filename = ("%s/%s.%s"):format(path,name,ext)
  if (x.prefs.unique_export_names.value) then
    -- in case we have enabled the global "unique_export_names" option
    filename = xLib.ensure_unique_filename(filename)
  end
  --print("filename",filename)
  return filename

end


