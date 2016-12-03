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

CHANGELOG
* added double-press support
* changed index into observable number

]]


class 'vSelection' 

vSelection.SELECT_MODE = {
  SINGLE = 1,   
  MULTIPLE = 2, 
}

vSelection.ORIENTATION = {
  HORIZONTAL = 1,   
  VERTICAL = 2, 
}

function vSelection:__init(...)
  TRACE("vSelection:__init(...)",...)

  local args = cLib.unpack_args(...)

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
  self.index_observable = renoise.Document.ObservableNumber(0)

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

  --- (int) each time a single index is set, the index/time is saved
  -- this makes it possible to detect a double-press event
  self.last_selected_index = nil
  self.last_selected_time = nil

  --- (number) the timeout for detecting double-presses (in seconds)
  self.doublepress_timeout = 0.3

  --- (ObservableBang), fired on double-press 
  -- note: use "self.last_selected_index" to obtain the item
  self.doublepress_observable = renoise.Document.ObservableBang()

  -- vSelection.ORIENTATION, affects which arrow keys are handled
  self.orientation = args.orientation or vSelection.ORIENTATION.VERTICAL

  -- initialize --

  if args.require_selection then
    self._require_selection = args.require_selection
  end

  if self._require_selection then
    self.index_observable.value = 1
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

  self.index_observable.value = (self._require_selection) 
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

  self.index_observable.value = self._indices[1]

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
    LOG("*** vSelection:toggle_index - value is outside range")
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
    self.index_observable.value = 0
  else
    self.index_observable.value = self._indices[1]
  end

  return changed,added,removed

end


--------------------------------------------------------------------------------
-- avoid that the selection picks up a double-press, e.g. when displaying
-- a new set of data 

function vSelection:reset()
  TRACE("vSelection:reset()")

  self.index_observable.value = 0
  self._indices = {}
  self.last_selected_index = nil
  self.last_selected_time = nil

end

--------------------------------------------------------------------------------
--- check if a given index is selected
-- @param idx (number)
-- @return int (index)

function vSelection:contains_index(idx)
  TRACE("vSelection:contains_index(idx)",idx)

  local values = table.values(self._indices)
  return table.find(values,idx)

end

--------------------------------------------------------------------------------
-- select next item 

function vSelection:select_previous()
  TRACE("vSelection:select_previous()")

  if self.index 
    and (self.index > 1)
  then
    self:set_index(self.index-1)
  end

end

--------------------------------------------------------------------------------

function vSelection:select_next()
  TRACE("vSelection:select_next()")

  if self.index and self.num_items
    and (self.index < self.num_items)
  then
    self:set_index(self.index+1)
  end

end

--------------------------------------------------------------------------------
-- TODO: 
--  * support modifier keys (multi-select only)
--  * page up/down, home/end
-- @return key (table) for unhandled keys

function vSelection:keyhandler(key)
  TRACE("vSelection:keyhandler(key)",key)

  if (key.modifiers == "") then

    if (self.orientation == vSelection.ORIENTATION.VERTICAL) then
      if (key.name == "up") then
        self:select_previous()
      elseif (key.name == "down") then
        self:select_next()
      end
    elseif (self.orientation == vSelection.ORIENTATION.HORIZONTAL) then
      if (key.name == "left") then
        self:select_previous()
      elseif (key.name == "right") then
        self:select_next()
      end
    else
      error("Unsupported orientation")
    end
  end

end


--------------------------------------------------------------------------------
-- Getters and setters 
--------------------------------------------------------------------------------
-- @return bool (true when changed, false on invalid index or mode)
-- @return table>int (added_items)
-- @return table>int (removed_items)

function vSelection:set_indices(t)
  --TRACE("vSelection:set_indices(t)",t)

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
    self.index_observable.value = t[1]
  end

  return changed,added,removed

end

function vSelection:get_indices()
  --TRACE("vSelection:get_indices()",self._indices)
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
  if val and (self.index_observable.value == 0) then
    self._indices = {1}
    self.index_observable.value = 1
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
  local changed = (self.index_observable.value ~= idx)

  -- turn off previously selected
  for k,v in ripairs(self._indices) do
    if (v ~= idx) then
      table.insert(removed,v)
      table.remove(self._indices,k)
      changed = true
    end
  end

  self.index_observable.value = idx

  if (idx > 0) then
    self._indices = {idx}
    table.insert(added,idx)
  end

  -- handle double-pressed items
  if self.last_selected_index 
    and (self.last_selected_index == idx) 
  then
    if (os.clock() < self.last_selected_time + self.doublepress_timeout) then
      self.doublepress_observable:bang()
      self.last_selected_index = nil
      self.last_selected_time = nil
    else
      self.last_selected_index = idx
      self.last_selected_time = os.clock()
    end
  elseif not self.last_selected_index 
    or (self.last_selected_index ~= idx) 
  then
    self.last_selected_index = idx
    self.last_selected_time = os.clock()
  end

  return changed,added,removed

end

function vSelection:get_index()
  return self.index_observable.value
end

--------------------------------------------------------------------------------
-- @return bool (when changed)
-- @return table (added_items)
-- @return table (removed_items)

function vSelection:set_mode(val)
  TRACE("vSelection:set_mode(val)",val)

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
      self.index_observable.value = 1
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

