--[[============================================================================
xPhraseManager
============================================================================]]--

--[[--

This class will assist in managing phrases, phrase mappings
.
#


Note that some methods only work with the selected instrument. This is a 
API limitation which would stands until we can determine the selected phrase 
without having to rely on the global 'selected_phrase/_index' property

See also: 
http://forum.renoise.com/index.php/topic/26329-the-api-wishlist-thread/?p=221484


--]]

--==============================================================================

class 'xPhraseManager'

--------------------------------------------------------------------------------
-- Retrieve the next available phrase mapping, based on current criteria
-- @param instr_idx (int), index of instrument 
-- @param insert_range (int), the size of the mapping in semitones
-- @param insert_idx (int), start search from this phrase index (first, if nil)
-- @return table{} or nil (if not able to find room)
-- @return int, the index where we can insert

function xPhraseManager.get_available_slot(instr_idx,insert_range,insert_idx)
  TRACE("xPhraseManager.get_available_slot(instr_idx,insert_range,insert_idx)",instr_idx,insert_range,insert_idx)

  assert(type(instr_idx)=="number","Expected instr_idx to be a number")

  local instr = rns.instruments[instr_idx]
  if not instr then
    return
  end

  local note_range = {}
  local max_note = 119
  local phrase_idx = nil
  local prev_end = nil

  -- provide defaults
  if not insert_idx then
    insert_idx = 1
  end
  if not insert_range then
    insert_range = 12 -- NTrapPrefs.PHRASE_RANGE_DEFAULT
  end

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
    stop_at = begin_at + insert_range - 1
  end

  if (stop_at-begin_at < insert_range) then
    -- another phrase appears within our range
    insert_range = stop_at-begin_at
  end
  if (stop_at > max_note) then
    -- there isn't enough room on the piano
    insert_range = max_note-prev_end-1
  end

  -- if not room for the start, return
  if (begin_at > 119) then
    return 
  end

  note_range = {begin_at,begin_at+insert_range}

  return note_range,phrase_idx

end

--------------------------------------------------------------------------------
--- Automatically add a new phrase to the specified instrument 
-- @param instr_idx (int), index of instrument 
-- @param create_keymap (bool), add mapping 
-- @return 
--  + InstrumentPhrase, the resulting phrase object
--  + int, the phrase index
--  or nil if failed

function xPhraseManager.auto_insert_phrase(instr_idx,create_keymap)
  TRACE("xPhraseManager.auto_insert_phrase(instr_idx,create_keymap)",instr_idx,create_keymap)

  local instr = rns.instruments[instr_idx]
  if not instr then
    LOG("*** Failed to allocate a phrase (could not locate instrument)")
    return
  end

  local vphrase,vphrase_idx = xPhraseManager.get_available_slot(instr_idx)
  if not vphrase then
    LOG("*** Failed to allocate a phrase (no more room left?)")
    return
  end
  
  local pmap = nil
  local phrase = instr:insert_phrase_at(vphrase_idx)
  if (renoise.API_VERSION > 4) then
    -- need to create mapping
    --print("insert phrase",phrase,"at index",#instr.phrase_mappings+1)
    pmap = instr:insert_phrase_mapping_at(#instr.phrase_mappings+1,phrase)
    --self:attach_to_phrase_mapping(pmap)
  end
  phrase.mapping.note_range = {
    vphrase[1],
    vphrase[2]
  }
  phrase.mapping.base_note = vphrase[1]
  phrase:clear()

  return phrase,vphrase_idx

end


--------------------------------------------------------------------------------
-- Select previous phrase 
-- @return int (phrase index) or nil if no phrase was selected

function xPhraseManager.select_previous_phrase()
  TRACE("xPhraseManager.select_previous_phrase()")

  local instr = rns.selected_instrument
  local phrase_idx = rns.selected_phrase_index
  if not phrase_idx then
    LOG("*** No phrase have been selected")
    return
  end

  phrase_idx = math.max(1,phrase_idx-1)
  rns.selected_phrase_index = phrase_idx

  return phrase_idx

end

--------------------------------------------------------------------------------
-- Select previous/next phrase 
-- @return int (phrase index) or nil if no phrase was selected

function xPhraseManager.select_next_phrase()
  TRACE("xPhraseManager.select_next_phrase()")

  local instr = rns.selected_instrument
  local phrase_idx = rns.selected_phrase_index
  if not phrase_idx then
    LOG("*** No phrase have been selected")
    return
  end

  phrase_idx = math.min(#instr.phrases,phrase_idx+1)
  rns.selected_phrase_index = phrase_idx

  return phrase_idx
  

end

--------------------------------------------------------------------------------
-- Select next phrase mapping as it appears in phrase bar

function xPhraseManager.select_next_phrase_mapping()
  TRACE("xPhraseManager.select_next_phrase_mapping()")

  local instr = rns.selected_instrument
  local phrase = rns.selected_phrase
  if not phrase.mapping then
    LOG("*** No mapping has been assigned to selected phrase")
    return
  end

  local lowest_note = nil
  local candidates = {}
  for k,v in ipairs(instr.phrases) do
    if v.mapping
      and (v.mapping.note_range[1] > phrase.mapping.note_range[1]) 
    then
      candidates[v.mapping.note_range[1]] = {
        phrase = v,
        index = k,
      }
      if not lowest_note then
        lowest_note = v.mapping.note_range[1]
      end
      lowest_note = math.min(lowest_note,v.mapping.note_range[1])
    end
  end

  if not table.is_empty(candidates) then
    rns.selected_phrase_index = candidates[lowest_note].index
  end

end

--------------------------------------------------------------------------------
-- Select previous phrase mapping as it appears in phrase bar

function xPhraseManager.select_previous_phrase_mapping()
  TRACE("xPhraseManager.select_previous_phrase_mapping()")

  local instr = rns.selected_instrument
  local phrase = rns.selected_phrase
  if not phrase.mapping then
    LOG("*** No mapping has been assigned to selected phrase")
    return
  end

  local highest_note = nil
  local candidates = {}
  for k,v in ipairs(instr.phrases) do
    if v.mapping
      and (v.mapping.note_range[1] < phrase.mapping.note_range[1]) 
    then
      candidates[v.mapping.note_range[1]] = {
        phrase = v,
        index = k,
      }
      if not highest_note then
        highest_note = v.mapping.note_range[1]
      end
      highest_note = math.max(highest_note,v.mapping.note_range[1])
    end
  end

  if not table.is_empty(candidates) then
    rns.selected_phrase_index = candidates[highest_note].index
  end

end



--------------------------------------------------------------------------------

function xPhraseManager.set_selected_phrase(idx)
  TRACE("xPhraseManager.set_selected_phrase(idx)",idx)

  local instr = rns.selected_instrument
  if instr.phrases[idx] then
    rns.selected_phrase_index = idx
  end

end

--------------------------------------------------------------------------------
-- API5: Using the mapping index to specify the selected phrase

function xPhraseManager.set_selected_phrase_by_mapping_index(idx)
  TRACE("xPhraseManager.set_selected_phrase_by_mapping_index(idx)",idx)

  local instr = rns.selected_instrument
  local mapping = instr.phrase_mappings[idx]
  if not mapping then
    LOG("*** Could not find the specified phrase mapping")
    return
  end
  
  for k,v in ipairs(instr.phrases) do
    if (rawequal(v,mapping.phrase)) then
      rns.selected_phrase_index = k
    end
  end

end

--------------------------------------------------------------------------------
-- Delete the currently selected phrase

function xPhraseManager.delete_selected_phrase()
  TRACE("xPhraseManager.delete_selected_phrase()")

  local instr = rns.selected_instrument
  local phrase_idx = rns.selected_phrase_index
  if (phrase_idx 
    and instr.phrases[phrase_idx]) 
  then
    instr:delete_phrase_at(phrase_idx)
  end

end

--------------------------------------------------------------------------------
-- Delete the currently selected phrase mapping
-- TODO in API4+, delete phrase + mapping

function xPhraseManager.delete_selected_phrase_mapping()
  TRACE("xPhraseManager.delete_selected_phrase_mapping()")

  local instr = rns.selected_instrument
  local phrase_idx = rns.selected_phrase_index
  if (phrase_idx 
    and instr.phrases[phrase_idx]
    and instr.phrases[phrase_idx].mapping) 
  then
    instr:delete_phrase_mapping_at(phrase_idx)
  end

end

--------------------------------------------------------------------------------
-- @return renoise.InstrumentPhraseMapping or nil

function xPhraseManager.get_selected_mapping()
  TRACE("xPhraseManager.get_selected_mapping()")

  local phrase = rns.selected_phrase
  if phrase then
    return phrase.mapping
  end

end

--------------------------------------------------------------------------------
-- @return int

function xPhraseManager.get_selected_mapping_index()
  TRACE("xPhraseManager.get_selected_mapping_index()")

  local instr = rns.selected_instrument
  local phrase = rns.selected_phrase
  if not phrase then
    return 
  end

  local mapping = phrase.mapping
  if not mapping then
    return
  end

  for k,v in ipairs(instr.phrase_mappings) do
    if (rawequal(phrase,v.phrase)) then
      return k
    end 
  end

end

