--[[===============================================================================================
xLFO
===============================================================================================]]--

--[[--

Static LFO implementation for generating basic waveforms

]]

--=================================================================================================

class 'xLFO'

---------------------------------------------------------------------------------------------------
-- [Static] Return sine wave at the given position 

function xLFO.sine(phase,min,max)
  --TRACE("xLFO.sine(phase,min,max)",phase,min,max)
  local val = math.sin(math.rad(360 * phase))
  return cLib.scale_value(val,-1,1,min,max)
end

---------------------------------------------------------------------------------------------------
-- [Static] Return triangle shape at the given position 

function xLFO.triangle(phase,min,max) 
  --TRACE("xLFO.triangle(phase,min,max)",phase,min,max)
  local val = math.abs(phase % 1)
  return cLib.scale_value(val,0,1,min,max)
end



