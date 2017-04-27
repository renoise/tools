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
-- test whether the instrument contain sample slices
-- @param instr (renoise.Instrument)
-- @return bool

function xInstrument.is_sliced(instr)

  if (#instr.samples > 0) then
    return (instr.sample_mappings[1][1].read_only)
  end

end

--------------------------------------------------------------------------------
-- test whether the keyzone can be reached with the instrument
-- (running in program mode + sample columns, or TODO: having the entire 
-- keyzone filled with phrases using sample columns)
-- @param instr (renoise.Instrument)
-- @return bool 

function xInstrument.is_keyzone_available(instr)

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

function xInstrument.is_triggering_phrase(instr)

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
-- detect if there is a slice marker *approximately* at the sample pos

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
-- figure out which sample index belong to the given note
-- @return number (slice index), nil, or false,error message
function xInstrument.get_sample_idx_from_note(instr,note)

  for sample_idx = 1,#instr.samples do 
    local sample = instr.samples[sample_idx]
    if xSampleMapping.within_note_range(note,sample.sample_mapping) then
      return sample_idx
    end
  end

end

--------------------------------------------------------------------------------

function xInstrument.get_slice_marker_by_sample_idx(instr,sample_idx)
  TRACE("xInstrument.get_slice_marker_by_sample_idx(instr,sample_idx)",instr,sample_idx)

  local markers = instr.samples[1].slice_markers
  return markers[sample_idx-1]

end

--------------------------------------------------------------------------------
-- perform a simple autocapture and return the instrument 
-- @return int or nil 

function xInstrument.autocapture()
  TRACE("xInstrument.autocapture()")

  rns:capture_nearest_instrument_from_pattern()
  return rns.selected_instrument_index

end

--------------------------------------------------------------------------------
-- locate the first empty instrument in instrument list
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
-- resolve the assigned track (midi input properties)
-- @param instr (renoise.Instrument)
-- @return number, track index

function xInstrument.resolve_midi_track(instr)
  if (instr.midi_input_properties.assigned_track == 0) then
    return rns.selected_track_index
  else
    return instr.midi_input_properties.assigned_track
  end
end

--------------------------------------------------------------------------------
-- check if instrument contains any samples, modulation etc. 
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
-- TODO reset sample-based part of instrument 

function xInstrument.reset_sampler()

end
