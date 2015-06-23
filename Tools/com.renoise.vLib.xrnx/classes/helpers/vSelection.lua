--[[============================================================================
vSelection
============================================================================]]--
--[[

  This class contains properties and methods for dealing with single- 
  or multi-selection of items 

  Generally, all methods return a boolean result along with one or two tables
  containing items that were added/removed as part of the operation. 

  PLANNED
  - generic keyboard support:
    - next/previous item
    - orientation (in which direction is next?)


]]


class 'vSelection' 

vSelection.SELECT_MODE = {
  SINGLE = 1,   
  MULTIPLE = 2, 
}

function vSelection:__init(...)
  TRACE("vSelection:__init(...)",...)

  local args = vLib.unpack_args(...)

  --- (bool) enforce that at least one item remains selected at all times
  self.require_selection = property(self.get_require_selection,self.set_require_selection)
  self._require_selection = args.require_selection or false

  --- (vSelection.SELECT_MODE) single or multi-selection? 
  self.mode = property(self.get_mode,self.set_mode)
  self._mode = args.mode or vSelection.SELECT_MODE.SINGLE

  --- (int) the index of the (first) selected item, or 0 when no selection
  -- note: setting this property while in multi-select mode will "collapse" 
  -- the selection to a single item, while getting will return the first item
  self.index = property(self.get_index,self.set_index)
  self._index = 0

  --- (table)
  -- note: the sequence reflects the order in which the items were selected: 
  -- if you select the third item, and then the first item, this property 
  -- contains an array of values in the following sequence: {3,1}
  self.indices = property(self.get_indices,self.set_indices)
  self._indices = {}

  --- (int) vSelection does not contain a direct reference to the data -
  --instead you provide it with @num_items - this is used for determining
  --if a given index is valid, how many items to select when selecting all
  self.num_items = property(self.get_num_items,self.set_num_items)
  self._num_items = nil

  -- initialize -----------------------

  if args.require_selection then
    self._require_selection = args.require_selection
  end

  if self._require_selection then
    self._index = 1
  end

end

--------------------------------------------------------------------------------
-- @return bool (true when changed)
-- @return table (removed_items)

function vSelection:clear_selection()
  TRACE("vSelection:clear_selection()")

  if (self._mode == vSelection.SELECT_MODE.SINGLE) 
    and self._require_selection 
  then
    return false
  end

  -- leave minimum "required selection" intact
  if self._require_selection and (#self._indices == 1) then
    return false
  end

  -- signal if selection has changed
  local removed = {}
  local changed = false
  
  for k,v in ripairs(self._indices) do
    if (v) then
      if (self._require_selection and k==1) then
        -- keep this one
      else
        table.insert(removed,v)
        table.remove(self._indices,k)
        changed = true
      end
    end
  end

  self._index = (self._require_selection) 
    and self._indices[1] or 1

  return changed,removed

end

--------------------------------------------------------------------------------
-- @return bool (true when changed)
-- @return table (added_items)

function vSelection:select_all()
  TRACE("vSelection:select_all()")

  if (self._mode == vSelection.SELECT_MODE.SINGLE) then
    return false
  end

  -- signal if selection has changed
  local added = {}
  local changed = false

  for idx = 1,self.num_items do
    if not (self:contains_index(idx)) then
      table.insert(self._indices,idx)
      table.insert(added,idx)
      changed = true
    end
  end

  self._index = self._indices[1]

  return changed,added

end

--------------------------------------------------------------------------------
--- toggle a selected bar on or off, depending on its current state 
-- @return bool (true when changed)
-- @return table (added_items)
-- @return table (removed_items)

function vSelection:toggle_index(idx)
  TRACE("vSelection:toggle_index(idx)",idx)

  local added,removed = {},{}
  local changed = false

  if (idx > self.num_items) then
    print("*** vSelection:toggle_index - value is outside range")
    return false
  end

  local contained = self:contains_index(idx)

  if not contained then
    table.insert(self._indices,idx)
    table.insert(added,idx)
    changed = true
  else
    if self._require_selection and (#self._indices == 1) then
      return
    else
      table.insert(removed,idx)
      table.remove(self._indices,contained)
      changed = true
    end
  end

  if table.is_empty(self._indices) then
    self._index = 0
  else
    self._index = self._indices[1]
  end

  return changed,added,removed

end


--------------------------------------------------------------------------------
--- check if a given index is selected
-- @param idx (number)
-- @return int (index)

function vSelection:contains_index(idx)

  local values = table.values(self._indices)
  return table.find(values,idx)

end

--------------------------------------------------------------------------------
-- GETTERS & SETTERS
--------------------------------------------------------------------------------
-- @return bool (true when changed, false on invalid index or mode)
-- @return table>int (added_items)
-- @return table>int (removed_items)

function vSelection:set_indices(t)
  TRACE("vSelection:set_indices(t)",t)

  local added,removed = {},{}
  local changed = false

  if (self._mode == vSelection.SELECT_MODE.SINGLE) then
    return false
  elseif (self._mode == vSelection.SELECT_MODE.MULTIPLE) then
    -- remove existing indices 
    local values = table.values(t)
    for k,v in ripairs(self._indices) do
      if not (table.find(values,v)) then
        table.insert(removed,v)
        table.remove(self._indices,k)
        changed = true
      end
    end
    for k,v in ipairs(t) do
      if not (self:contains_index(v)) then
        table.insert(added,v)
        table.insert(self._indices,v)
        changed = true
      end
    end
    self._index = t[1]
  end

  return changed,added,removed

end

function vSelection:get_indices()
  TRACE("vSelection:get_indices()",self._indices)
  return self._indices
end


--------------------------------------------------------------------------------
-- @return bool (when changed)
-- @return table (added_items)
-- @return table (removed_items)

function vSelection:set_require_selection(val)
  TRACE("vSelection:set_require_selection(val)",val)

  local added,removed = {},{}
  local changed = (val ~= self._require_selection)

  self._require_selection = val
  if val and not self._index then
    self._indices = {1}
    self._index = 1
    changed = true
  end

  return changed,added,removed

end

function vSelection:get_require_selection()
  TRACE("vSelection:get_require_selection()",self._require_selection)

  return self._require_selection
end

--------------------------------------------------------------------------------
-- @return bool (when changed)
-- @return table (added_items)
-- @return table (removed_items)

function vSelection:set_index(idx)
  TRACE("vSelection:set_index(idx)",idx)

  local added,removed = {},{}
  local changed = (self._index ~= idx)

  -- turn off previously selected
  for k,v in ripairs(self._indices) do
    if (v ~= idx) then
      table.insert(removed,v)
      table.remove(self._indices,k)
      changed = true
    end
  end

  self._index = idx
  if (idx > 0) then
    self._indices = {idx}
    table.insert(added,idx)
  end

  return changed,added,removed

end

function vSelection:get_index()
  TRACE("vSelection:get_index()",self,self._index)
  return self._index
end

--------------------------------------------------------------------------------
-- @return bool (when changed)
-- @return table (added_items)
-- @return table (removed_items)

function vSelection:set_mode(val)

  local added,removed = {},{}
  local changed = (val ~= self._mode)

  if changed and (val == vSelection.SELECT_MODE.SINGLE) then
    -- collapse multi-selection when entering single mode
    -- (keep the first one)
    for k,v in ripairs(self._indices) do
      if (k > 1) then
        table.insert(removed,v)
        table.remove(self._indices,k)
      end 
    end
    -- add selected index if required to
    if self._require_selection 
      and table.is_empty(self._indices) 
    then
      self._indices = {1}
      self._index = 1
    end
  end

  self._mode = val

  return changed,added,removed

end

function vSelection:get_mode()
  TRACE("vSelection:get_mode()",self._mode)
  return self._mode
end

--------------------------------------------------------------------------------

function vSelection:set_num_items(val)
  TRACE("vSelection:set_num_items(val)",val)

  -- remove indices that are out-of-bounds
  if self._num_items and (val > self._num_items) then
    for k,v in ripairs(self._indices) do
      if (val > v) then
        table.remove(self._indices,k)
      end
    end
  end

  self._num_items = val

end

function vSelection:get_num_items()
  TRACE("vSelection:get_num_items()",self._num_items)
  return self._num_items
end

