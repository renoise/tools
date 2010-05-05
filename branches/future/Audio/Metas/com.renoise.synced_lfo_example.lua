--[[---------------------------------------------------------------------------
  com.renoise.synced_lfo_example.lua
---------------------------------------------------------------------------]]--

manifest = {
  name = "*Beat LFO (Example Plugin)",
  identifier = "com.renoise.synced_lfo_example",
  author = "taktik [taktik@renoise.com]",
  type = "Meta"
}


-------------------------------------------------------------------------------

local parameters = {
  offset = 0,
  amount = 1,
  beats = 1.0
}


-------------------------------------------------------------------------------

-- __init

function __init(device)
  device:add_parameter("Offset", 0, 1, parameters.offset)
  device:add_parameter("Amount", 0, 1, parameters.amount)
  device:add_parameter("Beats", 1/8, 8, parameters.beats)
end


-- __process_input

function __process_input(name, value)
  if (name == "Offset") then
    parameters.offset = value
  elseif (name == "Amount") then
    parameters.amount = value
  elseif (name == "Beats") then
    parameters.beats = value
  end
end


-- __process_output

function __process_output(time)
  local value = (time.beat_pos % parameters.beats) / parameters.beats
  return parameters.offset + value * parameters.amount
end


--[[---------------------------------------------------------------------------
---------------------------------------------------------------------------]]--

