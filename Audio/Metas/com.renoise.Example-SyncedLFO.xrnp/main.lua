--[[---------------------------------------------------------------------------
  com.renoise.synced_lfo_example.lua
---------------------------------------------------------------------------]]--

local parameters = {
  offset = 0,
  amount = 1,
  beats = 1.0
}


-------------------------------------------------------------------------------

-- __init (parameter setup)

-- register parameters for the device. can only be done here

function __init(device)
  -- name, min, max, default
  device:add_parameter("Offset", 0, 1, parameters.offset)
  device:add_parameter("Amount", 0, 1, parameters.amount)
  device:add_parameter("Beats", 1/8, 8, parameters.beats)
 
  -- TODO: enum and boolean parameters:
  -- device:add_parameter("LFO Type", {"Sin", "Saw", ...}, parameters.lfo_type)
  -- device:add_parameter("Free Sync", parameters.free_sync)
end


-------------------------------------------------------------------------------

-- __process_input (parameter changes)

-- name: name of the parameter as it was registered
-- value: new value name of the parameter

function __process_input(name, value)
  if (name == "Offset") then
    parameters.offset = value
  elseif (name == "Amount") then
    parameters.amount = value
  elseif (name == "Beats") then
    parameters.beats = value
  end
end



-------------------------------------------------------------------------------

-- __process_event (note, instrument, volume, panning)

-- any of them may be nil (when only a note or only and instr. was triggered)

function __process_event(left, right, num_frames)

-- TODO (Not yet called)

end



-------------------------------------------------------------------------------

-- __process_output (calc value for linked destination)

-- time = {
--   sample_rate (number),
--   beat_pos (number),
--   sample_pos (number),
--   tick_pos (number),
--   playing (number),
--   bpm (number),
--   lpb (number),
--   tbl (number),
--   samples_per_line (number),
--   current_line (number),
--   current_tick (number),
--   current_sequence (number)
-- }

function __process_output(time)
  local value = (time.beat_pos % parameters.beats) / parameters.beats
  return parameters.offset + value * parameters.amount
end


--[[---------------------------------------------------------------------------
---------------------------------------------------------------------------]]--

