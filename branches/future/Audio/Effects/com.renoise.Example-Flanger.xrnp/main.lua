--[[---------------------------------------------------------------------------
  com.renoise.flanger_example.lua
---------------------------------------------------------------------------]]--

-- consts

local DELAY_BUFFER_SIZE = 16384
local DELAY_BUFFER_MASK = 16383


-- runtime status

local srate = 48000 -- TODO

local delay_buffer_pos = 0

local delay_buffer_left = {}
local delay_buffer_right = {}

for i=0,DELAY_BUFFER_SIZE - 1 do
  delay_buffer_left[i] = 0.0
  delay_buffer_right[i] = 0.0
end

local tpos = 0
local tdelay0 = 0
local tdelay1 = 0
 
local parameters = {
  delay = 5,
  offset = 0,
  feedback = 0.5,
  speed = 0.1,
  mix = 0.5
}

 
-------------------------------------------------------------------------------

-- __init

function __init(device)
  device:add_parameter("Delay", 1, 10, parameters.delay)
  device:add_parameter("Offset", 0, 5, parameters.offset)
  device:add_parameter("Feedback", -1, 1, parameters.feedback)
  device:add_parameter("Speed", 0.01, 10, parameters.speed)
  device:add_parameter("Mix", 0, 1, parameters.mix)
end


-- __process_input

function __process_input(name, value)
  if (name == "Delay") then
    parameters.delay = value
      
  elseif (name == "Offset") then
    parameters.offset = value
  
  elseif (name == "Feedback") then
    parameters.feedback = value
  
  elseif (name == "Speed") then
    parameters.speed = value
    
  elseif (name == "Mix") then
    parameters.mix = value
    
  end
  
  if (name == "Delay" or name == "Offset") then
    tdelay0 = parameters.delay
    tdelay1 = (parameters.delay + parameters.offset)
    tpos = 0
  end
end


-- __process_audio

function __process_audio(left, right, num_frames)
 local twopi = 2 * math.pi
  local sin = math.sin
  local band = bit.band

  local delay = (parameters.delay - 0.1) * parameters.delay
  local feedback = parameters.feedback
  local speed = parameters.speed
  local mix = parameters.mix
  local offset = parameters.offset
  local trate = twopi / (srate / parameters.speed)
  local sdelay0 = tdelay0 / 1000 * srate
  local sdelay1 = tdelay1 / 1000 * srate
    
  for i=1,num_frames do
    local back0 = band(delay_buffer_pos - sdelay0 + 
      DELAY_BUFFER_SIZE, DELAY_BUFFER_MASK)
    local back1 = band(delay_buffer_pos - sdelay1 + 
      DELAY_BUFFER_SIZE, DELAY_BUFFER_MASK)
    
    local index00 = back0
    local index01 = back1
    local index_10 = band(index00 - 1 + DELAY_BUFFER_SIZE, DELAY_BUFFER_MASK)
    local index_11 = band(index01 - 1 + DELAY_BUFFER_SIZE, DELAY_BUFFER_MASK)
    local index10 = band(index00 + 1, DELAY_BUFFER_MASK)
    local index11 = band(index01 + 1, DELAY_BUFFER_MASK)
    local index20 = band(index00 + 2, DELAY_BUFFER_MASK)
    local index21 = band(index01 + 2, DELAY_BUFFER_MASK)
    
    local y_10 = delay_buffer_left[index_10]
    local y_11 = delay_buffer_right[index_11]
    local y00 = delay_buffer_left[index00]
    local y01 = delay_buffer_right[index01]
    local y10 = delay_buffer_left[index10]
    local y11 = delay_buffer_right[index11]
    local y20 = delay_buffer_left[index20]
    local y21 = delay_buffer_right[index21]
    
    local x0 = back0 - index00
    local x1 = back1 - index01
    
    local c00 = y00
    local c01 = y01
    local c10 = 0.5 * (y10 - y_10)
    local c11 = 0.5 * (y11 - y_11)
    local c20 = y_10 - 2.5 * y00 + 2.0 * y10 - 0.5 * y20
    local c21 = y_11 - 2.5 * y01 + 2.0 * y11 - 0.5 * y21
    local c30 = 0.5 * (y20 - y_10) + 1.5 * (y00 - y10)
    local c31 = 0.5 * (y21 - y_11) + 1.5 * (y01 - y11)
    
    local output0 = ((c30 * x0 + c20) * x0 + c10) * x0 + c00
    local output1 = ((c31 * x1 + c21) * x1 + c11) * x1 + c01
    
    delay_buffer_left[delay_buffer_pos] = left[i] + output0 * feedback
    delay_buffer_right[delay_buffer_pos] = right[i] + output1 * feedback
    
    left[i] = left[i] * (1 - mix) + output0 * mix
    right[i] = right[i] * (1 - mix) + output1 * mix
    
    delay_buffer_pos = band(delay_buffer_pos + 1, DELAY_BUFFER_MASK)
    
    tdelay0 = delay + (delay - 0.1) * sin(tpos)
    tdelay1 = delay + (delay - 0.1) * sin(tpos + offset)
      
    tpos = tpos + trate
    if (tpos > twopi) then tpos = tpos - twopi end
    
    sdelay0 = tdelay0 / 1000 * srate
    sdelay1 = tdelay1 / 1000 * srate
  end
end


-- __flush_audio

function __flush_audio()
  for i=0,DELAY_BUFFER_SIZE - 1 do
    delay_buffer_left[i] = 0.0
    delay_buffer_right[i] = 0.0
  end
end


--[[---------------------------------------------------------------------------
---------------------------------------------------------------------------]]--

