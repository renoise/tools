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
-- Retrieve the next available phrase mapping
-- @param instr_idx (int), index of instrument 
-- @param insert_range (int), the size of the mapping in semitones
-- @param keymap_offset (int), start search from this note [first, if nil]
-- @return table{} or nil (if not able to find room)
-- @return int, the index where we can insert

function xPhraseManager.get_available_slot(instr_idx,insert_range,keymap_offset)
  TRACE("xPhraseManager.get_available_slot(instr_idx,insert_range,keymap_offset)",instr_idx,insert_range,keymap_offset)

  assert(type(instr_idx)=="number","Expected instr_idx to be a number")

  local instr = rns.instruments[instr_idx]
  if not instr then
    return false,"Could not locate instrument"
  end

  -- provide defaults...
  if not keymap_offset then
    keymap_offset = 0
  end
  if not insert_range then
    insert_range = 12 
  end

  -- find empty space from the selected phrase and upwards
  -- (nb: phrase mappings are always ordered by note)
  local phrase_idx = nil
  local max_note = 119
  local begin_at = nil
  local stop_at = nil
  local prev_end = nil

  for k,v in ipairs(instr.phrase_mappings) do
    --print(">>> check mapping",v.note_range[1],v.note_range[2])

    if (v.note_range[2] >= keymap_offset) then      

      -- find first gap

      if not prev_end then
        prev_end = v.note_range[1]-1
      end
      if not begin_at 
        and (v.note_range[1] > prev_end+1) 
      then
        begin_at = prev_end+1
        stop_at = v.note_range[1]-1
        --print(">>> found room between",begin_at,stop_at)
        phrase_idx = k
        break
      else
        --print(">>> no room at",v.note_range[1],v.note_range[2])
      end
      prev_end = v.note_range[2]
    else
      --print(">>> less than keymap_offset")
      local next_mapping = instr.phrase_mappings[k+1]
      if next_mapping 
        and (next_mapping.note_range[1] > keymap_offset)
      then
        prev_end = keymap_offset-1 --v.note_range[2]
      end

    end
  end
  
  if not begin_at then
    begin_at = math.max(keymap_offset,(prev_end) and prev_end+1 or 0)
    if table.is_empty(instr.phrase_mappings) then
      phrase_idx = 1
    else
      phrase_idx = #instr.phrase_mappings+1
    end
    --print(">>> found begin_at",begin_at,phrase_idx)
  end
  if not stop_at then
    stop_at = begin_at + insert_range - 1
    --print(">>> found stop_at",stop_at)
  end

  stop_at = math.min(119,stop_at)

  if (stop_at-begin_at < insert_range) then
    -- another phrase appears within our range
    insert_range = stop_at-begin_at
  end
  if (stop_at > max_note) then
    -- there isn't enough room on the piano
    insert_range = max_note-prev_end-1
  end

  -- no room for the start
  if (begin_at > 119) then
    return false,"There is no more room for phrase mapping"
  end

  local note_range = {begin_at,begin_at+insert_range}
  --print(">>> note_range...",rprint(note_range))

  return note_range,phrase_idx

end

--------------------------------------------------------------------------------
-- retrieve existing, empty phrase, searching 'back-to-back' (no gaps)
-- @param instr_idx (int), index of instrument 
-- @param keymap_offset (int), start search from this note [first, if nil]
-- @return table{} or nil, note-range 
-- @return int or nil, the index where we can insert

function xPhraseManager.get_empty_slot(instr_idx,keymap_offset)
  TRACE("xPhraseManager.get_empty_slot(instr_idx,keymap_offset)",instr_idx,keymap_offset)

  assert(type(instr_idx)=="number","Expected instr_idx to be a number")

  local instr = rns.instruments[instr_idx]
  if not instr then
    return false,"Could not locate instrument"
  end

  --print("*** get_empty_slot - instr.name",instr.name)

  -- provide defaults...
  if not keymap_offset then
    keymap_offset = 0
  end

  -- start by looking at phrase mappings

  local stop_at = nil
  for k,v in ipairs(instr.phrase_mappings) do
    --print("*** get_empty_slot - check mapping",v.note_range[1],v.note_range[2])
    if (v.note_range[1] >= keymap_offset) 
      and stop_at 
      and (v.note_range[1] == stop_at+1)
    then
      --print("*** get_empty_slot - v.phrase.is_empty",v.phrase.is_empty)
      if v.phrase.is_empty then
        return v.note_range,k
      end
    end
    if not stop_at then
      stop_at = v.note_range[2]
    end

  end

  -- next, look at the phrase themselves

  for k,v in ipairs(instr.phrases) do
    --print("*** get_empty_slot - v.is_empty",v.is_empty)
    if v.is_empty then
      if v.mapping then
        return v.mapping.note_range,k
      else
        return nil,k
      end
    end
  end

end

--------------------------------------------------------------------------------
--- Automatically add a new phrase to the specified instrument 
-- @param instr_idx (int), index of instrument 
-- @param create_keymap (bool), add mapping 
-- @param insert_range (int), size of mappings (in semitones)
-- @param keymap_offset (int), starting note (0-120)
-- @return 
--  + InstrumentPhrase, the resulting phrase object
--  + int, the phrase index
--  or nil if failed

function xPhraseManager.auto_insert_phrase(instr_idx,create_keymap,insert_range,keymap_offset,takeover)
  TRACE("xPhraseManager.auto_insert_phrase(instr_idx,create_keymap,insert_range,keymap_offset,takeover)",instr_idx,create_keymap,insert_range,keymap_offset,takeover)

  local instr = rns.instruments[instr_idx]
  if not instr then
    local msg = "Failed to allocate a phrase (could not locate instrument)"
    return false,msg
  end

  local vphrase_range,vphrase_idx = nil,nil

  -- locate empty phrase before creating a new one
  local do_create = true
  if takeover then
    vphrase_range,vphrase_idx = xPhraseManager.get_empty_slot(instr_idx,keymap_offset)
    if vphrase_idx then
      --print("*** auto_insert_phrase - located empty phrase")
      do_create = false
      create_keymap = false
    end
  end

  if not vphrase_idx then
    if create_keymap then
      vphrase_range,vphrase_idx = xPhraseManager.get_available_slot(instr_idx,insert_range,keymap_offset)
      if not vphrase_range then
        local err = "Failed to allocate a phrase (no more room left?)"
        return false,err
      end
    else
      vphrase_idx = (#instr.phrases > 0) and #instr.phrases+1 or 1
    end
  end

  --print(">>> vphrase_idx #2",vphrase_idx)

  local phrase = nil
  if do_create then
    if (#instr.phrases == 126) then
      local err = "Failed to allocate a phrase (can only have up to 126 phrase per instrument)"
      return false,err
    end
    phrase = instr:insert_phrase_at(vphrase_idx)
    phrase:clear() -- clear default C-4 
    --print(">>> inserted phrase at",vphrase_idx,"in",instr.name)
  else
    phrase = instr.phrases[vphrase_idx]
  end

  if (create_keymap and renoise.API_VERSION > 4) then
    instr:insert_phrase_mapping_at(#instr.phrase_mappings+1,phrase)
  end
  if (create_keymap or renoise.API_VERSION <= 4) then
    phrase.mapping.note_range = {
      vphrase_range[1],
      vphrase_range[2]
    }
    phrase.mapping.base_note = vphrase_range[1]
  end

  return phrase,vphrase_idx

end


--------------------------------------------------------------------------------
-- Select previous phrase 
-- @return int (phrase index) or nil if no phrase was selected

function xPhraseManager.select_previous_phrase()
  TRACE("xPhraseManager.select_previous_phrase()")

  local phrase_idx = rns.selected_phrase_index
  if not phrase_idx or (phrase_idx == 0) then
    return false,"No phrase have been selected"
  end

  phrase_idx = math.max(1,phrase_idx-1)
  rns.selected_phrase_index = phrase_idx

  return phrase_idx

end

--------------------------------------------------------------------------------
-- @return bool (true when able to select earlier phrase)

function xPhraseManager.can_select_previous_phrase()
  TRACE("xPhraseManager.can_select_previous_phrase()")

  local phrase_idx = rns.selected_phrase_index
  if not phrase_idx or (phrase_idx == 0) then
    return false,"No phrase have been selected"
  end

  local instr = rns.selected_instrument
  return (rns.selected_phrase_index > 1) and true or false

end

--------------------------------------------------------------------------------
-- Select previous/next phrase 
-- @return int (phrase index) or nil if no phrase was selected

function xPhraseManager.select_next_phrase()
  TRACE("xPhraseManager.select_next_phrase()")

  local phrase_idx = rns.selected_phrase_index
  if not phrase_idx or (phrase_idx == 0) then
    return false,"No phrase have been selected"
  end

  local instr = rns.selected_instrument
  phrase_idx = math.min(#instr.phrases,phrase_idx+1)
  rns.selected_phrase_index = phrase_idx

  return phrase_idx
  

end

--------------------------------------------------------------------------------
-- @return bool (true when able to select earlier phrase)

function xPhraseManager.can_select_next_phrase()
  TRACE("xPhraseManager.can_select_next_phrase()")

  local phrase_idx = rns.selected_phrase_index
  if not phrase_idx or (phrase_idx == 0) then
    return false,"No phrase have been selected"
  end

  local instr = rns.selected_instrument
  return (rns.selected_phrase_index < #instr.phrases) and true or false

end


--------------------------------------------------------------------------------
-- Select next phrase mapping as it appears in phrase bar

function xPhraseManager.select_next_phrase_mapping()
  TRACE("xPhraseManager.select_next_phrase_mapping()")

  local phrase = rns.selected_phrase
  if not phrase.mapping then
    return false,"No mapping has been assigned to selected phrase"
  end

  local instr = rns.selected_instrument
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
    return false,"No mapping has been assigned to selected phrase"
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
-- API5: Using the mapping index to retrieve the selected phrase

function xPhraseManager.get_phrase_index_by_mapping_index(instr_idx,mapping_idx)
  TRACE("xPhraseManager.get_phrase_index_by_mapping_index(instr_idx,mapping_idx)",instr_idx,mapping_idx)

  local instr = rns.instruments[instr_idx]
  if not instr then
    return false,"Could not find the specified instrument"
  end

  local mapping = instr.phrase_mappings[mapping_idx]
  if not mapping then
    return false,"Could not find the specified phrase mapping"
  end
  
  for k,v in ipairs(instr.phrases) do
    if (rawequal(v,mapping.phrase)) then
      return k
    end
  end

end

--------------------------------------------------------------------------------
-- API5: Using a phrase to retrieve the phrase-mapping index

function xPhraseManager.get_mapping_index_by_phrase_index(instr_idx,phrase_idx)

  local instr = rns.instruments[instr_idx]
  if not instr then
    return false,"Could not find the specified instrument"
  end

  local phrase = instr.phrases[phrase_idx]
  if not phrase then
    return false,"Could not find the specified phrase"
  end
  
  for k,v in ipairs(instr.phrase_mappings) do
    if (rawequal(v,phrase.mapping)) then
      return v,k
    end
  end

end

--------------------------------------------------------------------------------
-- API5: Assign a property value to both the phrase and it's mapping (if any)
-- @param phrase_idx (int)
-- @param prop_name (string)
-- @param prop_value (number/string/boolean)

function xPhraseManager.set_universal_phrase_property(instr_idx,phrase_idx,prop_name,prop_value)

  local accepted_prop_names = {
    "key_tracking",
    "base_note",
    "note_range",
    "looping",
    "loop_start",
    "loop_end",
  }

  if not table.find(accepted_prop_names,prop_name) then
    return false,"Property name is not allowed for phrase mappings"
  end

  local instr = rns.instruments[instr_idx]
  if not instr then
    return false,"Could not find the specified instrument"
  end

  local phrase = instr.phrases[phrase_idx]
  --print("phrase",phrase)
  if phrase then
    phrase[prop_name] = prop_value
  end
  
  local mapping,mapping_idx = xPhraseManager.get_mapping_index_by_phrase_index(instr_idx,phrase_idx)
  --print("mapping,mapping_idx",mapping,mapping_idx)
  if mapping then
    mapping[prop_name] = prop_value
  end

  return true

end

--------------------------------------------------------------------------------
-- Delete the currently selected phrase

function xPhraseManager.delete_selected_phrase()
  TRACE("xPhraseManager.delete_selected_phrase()")

  local instr = rns.selected_instrument
  local phrase_idx = rns.selected_phrase_index
  if (phrase_idx and instr.phrases[phrase_idx]) then
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
-- @return int or nil

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

--------------------------------------------------------------------------------
-- @param mode (int), renoise.Instrument.PHRASES_xxx
-- @return int or nil
-- @return string (error message when failed)
--[[
function xPhraseManager.set_playback_mode(mode)
  TRACE("xPhraseManager.set_playback_mode(mode)",mode)

  local phrase = rns.selected_phrase
  if not phrase then
    return false, "No phrase is selected"
  end

  if (rns.selected_instrument.phrase_playback_mode == mode) then
    rns.selected_instrument.phrase_playback_mode = renoise.Instrument.PHRASES_OFF
  else
    rns.selected_instrument.phrase_playback_mode = mode
  end

end
]]

--------------------------------------------------------------------------------
-- locate duplicate phrases within instrument
-- @param instr
-- @return table, each entry having this form:
--    {
--      source_phrase_index=int,
--      target_phrase_index=int, -- duplicate
--    }

function xPhraseManager.find_duplicates(instr)
  TRACE("xPhraseManager.find_duplicates(instr)",instr)

  local phrases_map = {}
  local duplicates = {}

  for k,v in ipairs(instr.phrases) do
    local stringified = xPhrase.stringify(v)
    if phrases_map[stringified] then
      table.insert(duplicates,{
        source_phrase_index = phrases_map[stringified].phrase_index,
        target_phrase_index = k,
      })
    else
      phrases_map[stringified] = {
        phrase_index = k,
      }
    end
  end

  return duplicates

end
