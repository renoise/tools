--[[---------------------------------------------------------------------------
  com.renoise.shape_example.lua
---------------------------------------------------------------------------]]--

manifest = {
  name = "Shape (Example Plugin)",
  identifier = "com.renoise.shape_example",
  author = "taktik [taktik@renoise.com]",
  type = "Effect"
}


-------------------------------------------------------------------------------

local abs = math.abs

local parameters = {
  amount = 0.5
}

local function shape(input, k)
  return (1 + k) * input / (1 + k * abs(input))
end
  
    
-------------------------------------------------------------------------------

-- __init

function __init(device)
  device:add_parameter("Amount", 0.0, 0.98, parameters.amount)
end


-- __process_input

function __process_input(name, value)
  if (name == "Amount") then
    parameters.amount = value
  end
end


-- __process_audio

function __process_audio(left, right, num_frames)
  local amount = parameters.amount
  local k = 2 * amount / (1 - amount)
  
  for i = 1,num_frames do
    left[i] = shape(left[i], k)
    right[i] = shape(right[i], k)
  end
end


--[[---------------------------------------------------------------------------
---------------------------------------------------------------------------]]--
