--[[---------------------------------------------------------------------------
  com.renoise.shape_example.lua
---------------------------------------------------------------------------]]--

local abs = math.abs

local function shape_factors(amount)
  return (2 * amount / (1 - amount)), (1.0 - (amount*0.5))
end


local function shape(input, factor)
  return (1 + factor) * input / (1 + factor * abs(input)) 
end
  

-------------------------------------------------------------------------------

local parameters = {
  amount = 0.5
}

    
-------------------------------------------------------------------------------

-- __init (parameter setup)

-- register parameters for the device. can only be done here

function __init(device)
  device:add_parameter("Amount", 0.0, 0.98, parameters.amount)
end


-------------------------------------------------------------------------------

-- __process_input (parameter changes)

-- name: name of the parameter as it was registered
-- value: new value name of the parameter


function __process_input(name, value)
  if (name == "Amount") then
    parameters.amount = value
  end
end


-------------------------------------------------------------------------------

-- __process_audio

-- left, right: table of floats for inplace procesing
-- num_frames: number of frames that are valid in left/right

function __process_audio(left, right, num_frames)
  local factor, comp_gain = shape_factors(parameters.amount)
  
  for i = 1,num_frames do
    left[i] = shape(left[i], factor) * comp_gain
    right[i] = shape(right[i], factor) * comp_gain
  end
end


--[[---------------------------------------------------------------------------
---------------------------------------------------------------------------]]--
