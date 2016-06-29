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
    --print("get_first_available - v.name",v.name)
    if xInstrument.is_empty(v) and (v.name == "") then
      return k
    end
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

