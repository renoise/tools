--[[============================================================================
xPhraseManager
============================================================================]]--

--[[--

Static methods for managing phrases, phrase mappings and presets
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


xPhraseManager.MAX_NUMBER_OF_PHRASES = 126

--------------------------------------------------------------------------------
-- Retrieve the next available phrase mapping
-- @param instr_idx (int), index of instrument 
-- @param keymap_range (int), the size of the mapping in semitones
-- @param keymap_offset (int), start search from this note [first, if nil]
-- @return table{} or nil (if not able to find room)
-- @return int, the index where we can insert

function xPhraseManager.get_available_slot(instr_idx,keymap_range,keymap_offset)
  TRACE("xPhraseManager.get_available_slot(instr_idx,keymap_range,keymap_offset)",instr_idx,keymap_range,keymap_offset)

  assert(type(instr_idx)=="number","Expected instr_idx to be a number")

  local instr = rns.instruments[instr_idx]
  if not instr then
    return false,"Could not locate instrument"
  end

  -- provide defaults...
  if not keymap_offset then
    keymap_offset = 0
  end
  if not keymap_range then
    keymap_range = 12 
  end

  -- find empty space from the selected phrase and upwards
  -- (nb: phrase mappings are always ordered by note)
  local phrase_idx = nil
  local max_note = 119
  local begin_at = nil
  local stop_at = nil
  local prev_end = nil

  for k,v in ipairs(instr.phrase_mappings) do

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
        phrase_idx = k
        break
      else
      end
      prev_end = v.note_range[2]
    else
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
  end
  if not stop_at then
    stop_at = begin_at + keymap_range - 1
  end

  stop_at = math.min(119,stop_at)

  if (stop_at-begin_at < keymap_range) then
    -- another phrase appears within our range
    keymap_range = stop_at-begin_at
  end
  if (stop_at > max_note) then
    -- there isn't enough room on the piano
    keymap_range = max_note-prev_end-1
  end

  -- no room for the start
  if (begin_at > 119) then
    return false,"There is no more room for phrase mapping"
  end

  local note_range = {begin_at,begin_at+keymap_range}

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

  -- provide defaults...
  if not keymap_offset then
    keymap_offset = 0
  end

  -- start by looking at phrase mappings

  local stop_at = nil
  for k,v in ipairs(instr.phrase_mappings) do
    if (v.note_range[1] >= keymap_offset) 
      and stop_at 
      and (v.note_range[1] == stop_at+1)
    then
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
-- @param instr_idx (int), index of instrument [required]
-- @param insert_at_idx (int), insert at this position [optional, default = end]
-- @param takeover (bool), 'take over' empty phrases [optional]
-- @param keymap_args (table), define to create keymapping [optional]
--  keymap_range (int), size of mappings (in semitones)
--  keymap_offset (int), starting note (0-120)
-- @return InstrumentPhrase, the resulting phrase object
-- @return int, the phrase index or nil if failed

function xPhraseManager.auto_insert_phrase(instr_idx,insert_at_idx,takeover,keymap_args)
  TRACE("xPhraseManager.auto_insert_phrase(instr_idx,insert_at_idx,takeover,keymap_args)",instr_idx,insert_at_idx,takeover,keymap_args)

  assert(type(instr_idx)=="number")

  if insert_at_idx then
    assert(type(insert_at_idx)=="number")
  end

  if takeover then
    assert(type(takeover)=="boolean")
  end

  local create_keymap = false
  local keymap_range,keymap_offset
  if keymap_args then
    create_keymap = true
    keymap_range = keymap_args.keymap_range
    keymap_offset = keymap_args.keymap_offset
    assert(type(keymap_range)=="number")
    assert(type(keymap_offset)=="number")
  end

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
      do_create = false
      create_keymap = false
    end
  end

  if not vphrase_idx then
    if create_keymap then
      vphrase_range,vphrase_idx = xPhraseManager.get_available_slot(instr_idx,keymap_range,keymap_offset)
      if not vphrase_range then
        local err = "Failed to allocate keymapping for the phrase (not enough room)"
        return false,err
      end
    end
  end

  local phrase_map_idx = vphrase_idx

  vphrase_idx = insert_at_idx and insert_at_idx
    or (#instr.phrases > 0) and #instr.phrases+1 or 1

  local phrase = nil
  if do_create then
    if (#instr.phrases == xPhraseManager.MAX_NUMBER_OF_PHRASES) then
      local err = "Failed to allocate phrase (each instrument can only contain up to 126 phrases)"
      return false,err
    end
    phrase = instr:insert_phrase_at(vphrase_idx)
  else
    phrase = instr.phrases[vphrase_idx]
  end

  if (create_keymap and renoise.API_VERSION > 4) then
    instr:insert_phrase_mapping_at(phrase_map_idx,phrase)
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
-- Select first phrase 
-- @return boolean, true if phrase was selected

function xPhraseManager.select_first_phrase()
  TRACE("xPhraseManager.select_first_phrase()")

  local instr = rns.selected_instrument
  if (#instr.phrases == 0) then
    return false,"Instrument does not contain any phrases"
  end

  rns.selected_phrase_index = 1
  return true

end

--------------------------------------------------------------------------------
-- Select last phrase 
-- @return boolean, true if phrase was selected

function xPhraseManager.select_last_phrase()
  TRACE("xPhraseManager.select_last_phrase()")

  local instr = rns.selected_instrument
  if (#instr.phrases == 0) then
    return false,"Instrument does not contain any phrases"
  end

  rns.selected_phrase_index = #instr.phrases
  return true

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
-- @param instr_idx (number)
-- @param phrase_idx (number)
-- @param prop_name (string)
-- @param prop_value (number/string/boolean)

function xPhraseManager.set_universal_property(instr_idx,phrase_idx,prop_name,prop_value)

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
  if phrase then
    phrase[prop_name] = prop_value
  end
  
  local mapping,mapping_idx = xPhraseManager.get_mapping_index_by_phrase_index(instr_idx,phrase_idx)
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
-- @param toggle (bool), makes same mode toggle between off & mode
-- @return boolean, true when mode was set
-- @return string (error message when failed)

function xPhraseManager.set_playback_mode(mode,toggle)
  TRACE("xPhraseManager.set_playback_mode(mode,toggle)",mode,toggle)

  local phrase = rns.selected_phrase
  if not phrase then
    return false, "No phrase is selected"
  end

  if toggle then
    if (rns.selected_instrument.phrase_playback_mode == mode) then
      rns.selected_instrument.phrase_playback_mode = renoise.Instrument.PHRASES_OFF
    else
      rns.selected_instrument.phrase_playback_mode = mode
    end
  else
    rns.selected_instrument.phrase_playback_mode = mode
  end

  return true

end

--------------------------------------------------------------------------------
-- @return boolean, true when mode was set
-- @return string (error message when failed)

function xPhraseManager.cycle_playback_mode()
  TRACE("xPhraseManager.cycle_playback_mode()")

  local phrase = rns.selected_phrase
  if not phrase then
    return false, "No phrase is selected"
  end

  if (rns.selected_instrument.phrase_playback_mode == renoise.Instrument.PHRASES_OFF) then
    rns.selected_instrument.phrase_playback_mode = renoise.Instrument.PHRASES_PLAY_SELECTIVE
  elseif (rns.selected_instrument.phrase_playback_mode == renoise.Instrument.PHRASES_PLAY_SELECTIVE) then
    rns.selected_instrument.phrase_playback_mode = renoise.Instrument.PHRASES_PLAY_KEYMAP
  elseif (rns.selected_instrument.phrase_playback_mode == renoise.Instrument.PHRASES_PLAY_KEYMAP) then
    rns.selected_instrument.phrase_playback_mode = renoise.Instrument.PHRASES_OFF
  end

  return true

end

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

--------------------------------------------------------------------------------
-- export indicated phrases in the instrument
-- @return bool, true when export was succesfull
-- @return string, error message when a problem was encountered
-- @return table, on problem, the indices not yet processed

function xPhraseManager.export_presets(folder,instr_idx,indices,overwrite,prefix)
  TRACE("xPhraseManager.export_presets(folder,instr_idx,indices,overwrite,prefix)",folder,instr_idx,indices,overwrite,prefix)

  assert(type(folder)=="string")
  assert(type(instr_idx)=="number")

  for k,v in ripairs(indices) do
    local rslt,err = xPhrase.export_preset(folder,instr_idx,v,overwrite,prefix)
    if err then
      return false,err,indices
    end
    indices[k] = nil
  end
  return true

end

--------------------------------------------------------------------------------
-- import one or more phrase presets into instrument
-- @param files (table)
-- @param instr_idx (int)
-- @param insert_at_idx (int) [optional]
-- @param takeover (bool) [optional]
-- @param keymap_args (table), see auto_insert_phrase [optional]
-- @param remove_prefix (bool), remove the "09_0A_" prefix [optional]
-- @return bool, true when import was succesfull
-- @return string, error message when failed

function xPhraseManager.import_presets(files,instr_idx,insert_at_idx,takeover,keymap_args,remove_prefix)
  TRACE("xPhraseManager.import_presets(files,instr_idx,insert_at_idx,takeover,keymap_args,remove_prefix)",files,instr_idx,insert_at_idx,takeover,keymap_args,remove_prefix)

  assert(type(files)=="table")
  assert(type(instr_idx)=="number")

  for k,v in ipairs(files) do

    local phrase,phrase_idx_or_err = xPhraseManager.auto_insert_phrase(instr_idx,insert_at_idx,takeover,keymap_args)
    if not phrase then
      return false,phrase_idx_or_err
    end

    rns.selected_phrase_index = phrase_idx_or_err
    if not renoise.app():load_instrument_phrase(v) then
      return false,"Failed to load phrase preset: "..tostring(v)
    end

    if remove_prefix then
      rns.selected_phrase.name = xPhrase.get_raw_preset_name(rns.selected_phrase.name)
    end

  end

end

