--[[============================================================================
xParameter
============================================================================]]--

--[[--

Abstract device-parameter class, supports relative values (xMidiMessage)
.
#

PLANNED
  Parameter pickup (remember last set value)

]]

class 'xParameter'

-------------------------------------------------------------------------------
--- Apply a value, optionally with a specific mode
-- @param param - DeviceParameter
-- @param val - number
-- @param mode - xMidiMessage.MODE - absolute/relative + number of bits
-- @param val_min - int, smallest possible value (derived from mode if not specified)
-- @param val_max - int, largest possible value (derived from mode if not specified)
-- @param msg_type - xMidiMessage.TYPE (required for 14-bit relative msgs)

function xParameter.set_value(param,val,mode,val_min,val_max,msg_type)
  TRACE("xParameter.set_value(param,val,mode,val_min,val_max,msg_type)",param,val,mode,val_min,val_max,msg_type)

  assert(type(param)=="DeviceParameter","Expected param to be an instance of DeviceParameter")
  assert(type(val)=="number","Expected value to be a number")
  assert(type(mode)=="string","Expected mode to be a string")

  local new_val = param.value
  local step_size = nil

  if mode:find("7") then
    if not val_min then val_min = 0 end
    if not val_max then val_max = 127 end
    step_size = param.value_max/127
  elseif mode:find("14") then
    if not val_min then val_min = 0 end
    if not val_max then val_max = 16383 end
    step_size = param.value_max/16383
  end

  if not mode then
    -- TODO treat as undefined - floating point 
  elseif mode:find("abs") then
    -- TODO treat as absolute - using 7/14 bit_depth 
    new_val = cLib.scale_value(val,val_min,val_max,0,param.value_max)
  elseif mode:find("rel_7") then
    -- treat as 7 bit relative control 
    local num = val --midi_msg[3]
    if (mode == "rel_7_signed") then
      if (num < 64) then
        num = - num
      elseif (num > 64) then
        num = num-64
      else
        num = 0
      end
    elseif (mode == "rel_7_signed2") then
      if (num > 64) then
        num = - (num-64)
      elseif (num < 64) then
        num = num
      else
        num = 0
      end
    elseif (mode == "rel_7_offset") then
      if (num < 64) then
        num = - (64-num)
      elseif (num > 64) then
        num = num-64
      else
        num = 0
      end
    elseif (mode == "rel_7_twos_comp") then
      if (num > 64) then
        num = - (128-num)
      elseif (num < 65) then
        num = num
      else
        num = 0
      end
    end
    if (num > 0) then
      new_val = math.min(new_val+(step_size*num),param.value_max)
    elseif (num < 0) then
      new_val = math.max(new_val-(step_size*math.abs(num)),0)
    end
  elseif mode:find("rel_14") then
    -- treat as 14 bit relative control 
    local num = val
    local msb,lsb = xMidiMessage.split_mb(val)
    if (msg_type == xMidiMessage.TYPE.NRPN) then
      if (mode == "rel_14_msb") then
        if (msb == 0x7F) then
          num = - (0x80-num)
        elseif (msb == 0x00) then
          num = num
        end
      elseif (mode == "rel_14_offset") then
        if (msb == 0x3F) then
          num = - (0x2000-num)
        elseif (msb == 0x40) then
          num = num - 0x2000
        end
      elseif (mode == "rel_14_twos_comp") then
        if (msb == 0x40) then 
          num = - (num - 0x2000)
        elseif (msb == 0x00) then 
          num = num
        end
      end
    elseif (msg_type == xMidiMessage.TYPE.CONTROLLER_CHANGE) then
      if (mode == "rel_14_msb") then
        if (msb == 0x7F) then 
          num = - (0x4000-num)
        elseif (msb == 0x00) then 
          num = num
        end
      elseif (mode == "rel_14_offset") then
        if (msb == 0x3F) then -- 63
          num = - (0x2000-num)
        elseif (msb == 0x40) then 
          num = num - 0x2000
        end
      elseif (mode == "rel_14_twos_comp") then
        if (msb == 0x40) then 
          num = (0x2000-num)
        elseif (msb == 0x00) then 
          num = num
        end
      end
    else
      error("Expected CONTROLLER_CHANGE or NRPN as message-type")
    end
    if (num < 0) then
      new_val = math.max(new_val-(step_size*math.abs(num)),0)
    else
      new_val = math.min(new_val+(step_size*num),param.value_max)
    end
  end

  param.value = new_val

end

-------------------------------------------------------------------------------
--- Increment value by "number of steps"

function xParameter.increment_value(param,val)
  TRACE("xParameter.increment_value(param,val)",param,val)

  assert(type(param)=="DeviceParameter","Expected param to be an instance of DeviceParameter")
  assert(type(val)=="number","Expected value to be a number")

  local step_size = param.value_max/127
  param.value = math.min(param.value_max,(param.value + (step_size*val)))

end

-------------------------------------------------------------------------------
--- Decrement value by "number of steps"

function xParameter.decrement_value(param,val)
  TRACE("xParameter.decrement_value(param,val)",param,val)

  assert(type(param)=="DeviceParameter","Expected param to be an instance of DeviceParameter")
  assert(type(val)=="number","Expected value to be a number")

  local step_size = param.value_max/127
  param.value = math.max(param.value_min,(param.value - (step_size*val)))

end

