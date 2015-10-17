--[[============================================================================
xPhraseMgr
============================================================================]]--
--[[

	This class will assist in managing phrases, phrase mappings

]]

class 'xPhraseMgr'

function xPhraseMgr:__init()

  -- int, default key-range size when creating new phrases
	self.default_range = 1

  -- int, our instrument 
	self.instr_idx = nil

end

--------------------------------------------------------------------------------
-- retrieve the next available phrase mapping, based on current criteria
-- @param insert_idx (int), start search from this phrase index (first, if nil)
-- @return table{} or nil (if not able to find room)
-- @return int, the index where we can insert

function xPhraseMgr:get_available_slot(insert_idx)

  local instr = rns.instruments[self.instr_idx]
  assert(instr,"no instrument-index defined")

  if not insert_idx then
    insert_idx = 1
  end

  local note_range = {}
  local max_note = 119
  local phrase_idx = nil
  local prev_end = nil

	local range = self.default_range

  -- find empty space from the selected phrase and upwards
  local begin_at, stop_at
  if insert_idx then
    for k,v in ipairs(instr.phrase_mappings) do
      if (k >= insert_idx) then
        if not prev_end then
          prev_end = v.note_range[1]-1
        end
        if not begin_at and
          (v.note_range[1] > prev_end+1) 
        then
          begin_at = prev_end+1
          stop_at = v.note_range[1]-1
          --print("found room between",begin_at,stop_at)
          phrase_idx = k
          break
        end
        prev_end = v.note_range[2]
      end
    end
  end
  
  if not begin_at then
    begin_at = (prev_end) and prev_end+1 or 0
    if table.is_empty(instr.phrase_mappings) then
      phrase_idx = 1
    else
      phrase_idx = #instr.phrase_mappings+1
    end

  end
  if not stop_at then
    stop_at = begin_at + range - 1
  end

  if (stop_at-begin_at < range) then
    -- another phrase appears within our range
    range = stop_at-begin_at
  end
  if (stop_at > max_note) then
    -- there isn't enough room on the piano
    range = max_note-prev_end-1
  end

  -- if not room for the start, return
  if (begin_at > 119) then
    return 
  end

  note_range = {begin_at,begin_at+range}

  return note_range,phrase_idx

end

