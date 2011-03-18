--[[============================================================================
operators.lua
============================================================================]]--

function arccosine(real_amplification, real_unused, real_x)
  return real_amplification * (-1 + 2 * math.acos(-1 + 2 * real_x) / PI)
end


--------------------------------------------------------------------------------
  
function arcsine(real_amplification, real_unused, real_x)
  return real_amplification * math.asin(-1 + 2 * real_x) / HALFPI
end


--------------------------------------------------------------------------------

function cosine(real_amplification, real_unused, real_x)
  return real_amplification * math.cos(TWOPI*real_x)
end


--------------------------------------------------------------------------------

function morpher(real_amplification, arr_real_sources, real_weight)
  local real_part1 = arr_real_sources[1] * (1 - real_weight)
  local real_part2 = arr_real_sources[2] * real_weight
  
  print(real_weight)
  
  return real_amplification * ( arr_real_sources[1] * (1 - real_weight) + arr_real_sources[2] * real_weight )
end


--------------------------------------------------------------------------------

function noise(real_amplification, real_unused1, real_unused2)
  return real_amplification - 2 * real_amplification * math.random()
end


--------------------------------------------------------------------------------

function pulse(real_amplification, real_width, real_x)
  if real_x > real_width then 
  return -real_amplification 
  else 
  return real_amplification 
  end
end


--------------------------------------------------------------------------------

function saw(real_amplification, real_unused, real_x)
  return real_amplification*(2*real_x-1)
end


--------------------------------------------------------------------------------

function sine(real_amplification, real_unused, real_x)
  return real_amplification * math.sin(TWOPI*real_x)
end


--------------------------------------------------------------------------------

function square(real_amplification, real_unused, real_x)
  return pulse(real_amplification, 0.5, real_x)
end


--------------------------------------------------------------------------------

function tangent(real_amplification, real_width, real_x)
  return real_amplification * math.tan(PI*real_x)*real_width
end


--------------------------------------------------------------------------------

function triangle(real_amplification, real_unused, real_x)
  if real_x < 0.5 then
    return real_amplification*(-1+2*real_x/0.5)
  else
    return triangle(real_amplification,real_unused,1-real_x)
  end
end


--------------------------------------------------------------------------------


function variator(real_amplification, real_previous_value, bool_change)

  if not bool_change then
    return real_previous_value
  end

  local real_variation = (math.random() - 0.5) * real_amplification

  if(real_previous_value == real_amplification) then
  
    --avoid continuous clipping
	return real_amplification - real_variation

  elseif(real_previous_value == -real_amplification) then
  
    --avoid continuous clipping
    return -real_amplification + real_variation
  
  else
  
    local real_value = real_previous_value + real_variation;
	
	real_value = math.max(-real_amplification, real_value)
	real_value = math.min(real_amplification, real_value)
	
	return real_value
  
  end
  
end

--------------------------------------------------------------------------------

function wave(real_amplification, buffer, real_x)

  local int_chan
  local real_value = 0
  
  if 
	buffer == 0.5 or --not initalized
    not buffer or 
	not buffer.has_sample_data 
  then
    return 0
  end
  
  for int_chan = 1, buffer.number_of_channels do
    real_value = real_value + 
    real_amplification * buffer:sample_data	(
      int_chan,
      (buffer.number_of_frames-1)*real_x+1
    )
  end
  real_value = real_value / buffer.number_of_channels
  
  return real_value  
end


--------------------------------------------------------------------------------

function none(real_unused1, real_unused2, real_unused3)
  return 0
end

