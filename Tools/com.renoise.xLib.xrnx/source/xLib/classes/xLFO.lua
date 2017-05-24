--[[===============================================================================================
xLFO
===============================================================================================]]--

--[[--

Static LFO implementation for generating basic waveforms

]]

--=================================================================================================

class 'xLFO'

---------------------------------------------------------------------------------------------------
-- [Static] Return sine wave at the given position, starting from 0
-- @param phase (number), a value between 0-1
-- @param min (number), scale "0" to this value
-- @param min (number), scale "1" to this value

function xLFO.sine(phase,min,max)
  local val = math.sin(math.rad(360 * phase))
  return cLib.scale_value(val,-1,1,min,max)
end

---------------------------------------------------------------------------------------------------
-- [Static] Return triangle shape at the given position, starting from 0
-- @param phase (number), a value between 0-1
-- @param min (number), scale "0" to this value
-- @param min (number), scale "1" to this value

function xLFO.triangle(phase,min,max) 
  local val = math.abs(phase % 1)
  return cLib.scale_value(val,0,1,min,max)
end


---------------------------------------------------------------------------------------------------
-- [Static] Return square shape at the given position, starting from 0
-- @param phase (number), a value between 0-1
-- @param min (number), scale "0" to this value
-- @param min (number), scale "1" to this value

function xLFO.square(phase,min,max) 
  local val = (phase <= 0.5) and 1 or 0
  return cLib.scale_value(val,0,1,min,max)
end



