--[[============================================================================
xInstrument
============================================================================]]--

--[[--

Static methods for dealing with renoise.Instrument
.
#

--]]

class 'xInstrument'

--------------------------------------------------------------------------------
-- Set the instrument to use the previous scale 
-- @param instr, renoise.Instrument

function xInstrument.set_previous_scale(instr)
  TRACE("xInstrument.set_previous_scale(instr)",instr)

  assert(type(instr)=="Instrument","Expected instr to be a renoise.Instrument")

  local scale_name = instr.trigger_options.scale_mode
  local scale_idx = xScale.get_scale_index_by_name(scale_name)
  if (scale_idx > 1) then
    xInstrument.set_scale_by_index(instr,scale_idx-1)
  end

end

--------------------------------------------------------------------------------
-- Set the instrument to use the next scale 
-- @param instr, renoise.Instrument

function xInstrument.set_next_scale(instr)
  TRACE("xInstrument.set_next_scale(instr)",instr)

  assert(type(instr)=="Instrument","Expected instr to be a renoise.Instrument")

  local scale_name = instr.trigger_options.scale_mode
  local scale_idx = xScale.get_scale_index_by_name(scale_name)
  if (scale_idx < #xScale.SCALES) then
    xInstrument.set_scale_by_index(instr,scale_idx+1)
  end

end

--------------------------------------------------------------------------------
-- Set the instrument to use the a specific scale 
-- @param instr, renoise.Instrument
-- @param scale_idx, number

function xInstrument.set_scale_by_index(instr,scale_idx)
  TRACE("xInstrument.set_scale_by_index(instr,scale_idx)",instr,scale_idx)

  assert(type(instr)=="Instrument","Expected instr to be a renoise.Instrument")
  assert(type(scale_idx)=="number","Expected scale_idx to be a number")

  local scale = xScale.SCALES[scale_idx]
  if scale then
    instr.trigger_options.scale_mode = scale.name
  end

end

--------------------------------------------------------------------------------
-- [Static] Test whether the instrument contain sample slices
-- @param instr (renoise.Instrument)
-- @return bool

function xInstrument.is_sliced(instr)
  TRACE("xInstrument.is_sliced(instr)",instr)

  if (#instr.samples > 0) then
    return (instr.sample_mappings[1][1].read_only)
  end

end

--------------------------------------------------------------------------------
-- [Static] Test whether the keyzone can be reached with the instrument
-- (running in program mode + sample columns)
-- @param instr (renoise.Instrument)
-- @return boolean

function xInstrument.is_keyzone_available(instr)
  TRACE("xInstrument.is_keyzone_available(instr)",instr)

  if (#instr.phrases == 0) then
    return true
  end

  local all_sample_cols = true
  for k,v in ipairs(instr.phrases) do
    if not v.instrument_column_visible then
      all_sample_cols = false
    end
  end
  if all_sample_cols then
    return false
  end
  return true

end

--------------------------------------------------------------------------------
-- [Static] Test whether instrument seems to be triggering a phrase
-- @param instr (renoise.Instrument)
-- @return boolean

function xInstrument.is_triggering_phrase(instr)
  TRACE("xInstrument.is_triggering_phrase(instr)",instr)

  if (#instr.phrases == 0) then
    return false
  end
  
  if (instr.phrase_playback_mode == renoise.Instrument.PHRASES_OFF) then
    return false
  end

  if (instr.phrase_playback_mode == renoise.Instrument.PHRASES_PLAY_SELECTIVE) then
    return true
  end

  -- TODO check for keymapped phrases 
  -- for now, assume that we are triggering a phrase 
  return true

end

-------------------------------------------------------------------------------
-- [Static] Figure out the phrase playback mode
-- @return boolean

function xInstrument.get_phrase_playback_enabled(instr)
  TRACE("xInstrument.get_phrase_playback_enabled(instr)",instr)

  --- implementation depends on API version
  if (renoise.API_VERSION > 4) then
    return not (instr.phrase_playback_mode == renoise.Instrument.PHRASES_OFF)
  else
    return instr.phrase_playback_enabled 
  end
end

-------------------------------------------------------------------------------
-- [Static] Set the phrase playback mode
-- @return boolean

function xInstrument.set_phrase_playback_enabled(instr,bool)
  TRACE("xInstrument.set_phrase_playback_enabled(instr,bool)",instr,bool)

  if (renoise.API_VERSION > 4) then
    -- this is a v4 method, so we assume Keymap trigger mode 
    local enum = bool and renoise.Instrument.PHRASES_PLAY_KEYMAP
      or renoise.Instrument.PHRASES_OFF
    instr.phrase_playback_mode = enum
  else
    instr.phrase_playback_enabled = bool
  end
end

-------------------------------------------------------------------------------
-- [Static] Detect if there is a slice marker *approximately* at the sample pos
-- @return boolean, [error message (string)]

function xInstrument.get_slice_marker_at_pos(instr,pos,threshold)
  TRACE("xInstrument.get_slice_marker_at_pos(instr,pos,threshold)",instr,pos,threshold)

  if not xInstrument.is_sliced(instr) then
    return false, "Instrument contains no slices"
  end

  local sample = instr.samples[1]
  local max = pos + threshold
  local min = pos - threshold

  for marker_idx = 1,#sample.slice_markers do
    local marker = sample.slice_markers[marker_idx]
    if (marker < max) and (marker > min) then
      return marker_idx
    end
  end

end


--------------------------------------------------------------------------------
-- [Static] Figure out which samples are mapped to the provided note
-- @return table<number> (sample indices)

function xInstrument.get_samples_mapped_to_note(instr,note)
  TRACE("xInstrument.get_samples_mapped_to_note(instr,note)",instr,note)

  local rslt = table.create()
  for sample_idx = 1,#instr.samples do 
    local sample = instr.samples[sample_idx]
    if xSampleMapping.within_note_range(note,sample.sample_mapping) then
      rslt:insert(sample_idx)
    end
  end
  return rslt

end

--------------------------------------------------------------------------------
-- [Static] Return the slice markers associated with a given sample 
-- @param instr (renoise.Instrument)
-- @param sample_idx (number)
-- @return table<number>

function xInstrument.get_slice_marker_by_sample_idx(instr,sample_idx)
  TRACE("xInstrument.get_slice_marker_by_sample_idx(instr,sample_idx)",instr,sample_idx)

  assert(type(instr)=="Instrument","Expected renoise.Instrument as argument")
  assert(type(sample_idx)=="number","Expected number as argument")

  if instr.samples[1] then
    return instr.samples[1].slice_markers[sample_idx-1]
  end 

end

--------------------------------------------------------------------------------
-- [Static] Perform a simple autocapture and return the instrument 
-- @return int (instrument index) or nil 

function xInstrument.autocapture()
  TRACE("xInstrument.autocapture()")

  rns:capture_nearest_instrument_from_pattern()
  return rns.selected_instrument_index

end

--------------------------------------------------------------------------------
-- [Static] Locate the first empty instrument in instrument list
-- @return int or nil 

function xInstrument.get_first_available()
  TRACE("xInstrument.get_first_available()")

  for k,v in ipairs(rns.instruments) do
    if xInstrument.is_empty(v) and (v.name == "") then
      return k
    end
  end

end

--------------------------------------------------------------------------------
-- [Static] Resolve the assigned track (midi input properties)
-- @param instr (renoise.Instrument)
-- @return number, track index

function xInstrument.resolve_midi_track(instr)
  TRACE("xInstrument.resolve_midi_track(instr)",instr)

  if (instr.midi_input_properties.assigned_track == 0) then
    return rns.selected_track_index
  else
    return instr.midi_input_properties.assigned_track
  end
end

--------------------------------------------------------------------------------
-- [Static] Check if instrument contains any samples, modulation etc. 
-- @param instr (renoise.Instrument)
-- @return bool

function xInstrument.is_empty(instr)
  TRACE("xInstrument.is_empty(instr)",instr)

  local is_empty = true
  if (#instr.samples > 0)
    and (#instr.phrases > 0)
    and (#instr.sample_device_chains > 0)
    and (#instr.sample_modulation_sets > 0)
    and not instr.plugin_properties.plugin_loaded
  then
    is_empty = false
  end

  return is_empty

end

--------------------------------------------------------------------------------
-- [Static] TODO reset sample-based part of instrument 

function xInstrument.reset_sampler()

end
