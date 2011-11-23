--[[----------------------------------------------------------------------------
-- Duplex.Monome 
----------------------------------------------------------------------------]]--

--[[

Inheritance: Monome > OscDevice > Device

A device-specific class, comes with presets for both the monome128 and 64

--]]


--==============================================================================

class "Monome" (OscDevice)

function Monome:__init(name, message_stream,prefix,address,port_in,port_out)
  TRACE("Monome:__init", name, message_stream,prefix,address,port_in,port_out)

  OscDevice.__init(self, name, message_stream,prefix,address,port_in,port_out)

  -- this device has a monochrome color-space 
  self.colorspace = {1, 1, 1}

  self.SERIALOSC = 1
  self.MONOMESERIAL = 2

  -- set the default communication protocol 
  self.comm_protocol = self.MONOMESERIAL


end

--------------------------------------------------------------------------------

-- set prefix both for Duplex and the MonomeSerial application
-- @param prefix (string), e.g. "/my_device" 

function Monome:set_device_prefix(prefix)
  TRACE("Monome:set_device_prefix()",prefix)

  -- unlike the generic OscDevice, monome always need a prefix value
  if (not prefix) then return end

  OscDevice.set_device_prefix(self,prefix)

  if (self.client) and (self.client.is_open) then
    self.client:send(
      renoise.Osc.Message("/sys/prefix",{
        {tag="i", value=0},
        {tag="s", value=self.prefix} 
      })
    )
  end

end

--------------------------------------------------------------------------------

-- clear display before releasing device

function Monome:release()
  TRACE("Monome:release()")

  if (self.client) and (self.client.is_open) then
    self.client:send(
      renoise.Osc.Message(self.prefix.."/clear",{
        {tag="i", value=0},
      })
    )
  end
  OscDevice.release(self)

end


--------------------------------------------------------------------------------

-- quantize value to determine lit/off state
function Monome:point_to_value(pt)
  TRACE("Monome:point_to_value")

  local color = self:quantize_color(pt.color)
  return (color[1]==0xff) and 1 or 0

end

--------------------------------------------------------------------------------

-- override default OscDevice method (comm protocol support)
function Monome:send_osc_message(message,value)
  TRACE("Monome:send_osc_message()",message,value)

  if (self.comm_protocol==self.MONOMESERIAL) 
  and (string.sub(message,1,13)=="/grid/led/set") then
    message = "/led"..string.sub(message,14)
  end

  OscDevice.send_osc_message(self,message,value)
  
end


--------------------------------------------------------------------------------

-- override default OscDevice method (comm protocol support)
function Monome:receive_osc_message(value_str)
  TRACE("Monome:receive_osc_message()",value_str)

  if (self.comm_protocol==self.MONOMESERIAL) 
  and (string.sub(value_str,1,6)=="/press") then
    value_str = "/grid/key"..string.sub(value_str,7)
  end

  OscDevice.receive_osc_message(self,value_str)
  
end



--==============================================================================

-- Include these configurations for the monome

local CTRL_PATH = "Duplex/Controllers/Monome/Configurations/"
require (CTRL_PATH.."m64_Matrix")
require (CTRL_PATH.."m64_MixerTransport")
require (CTRL_PATH.."m64_Recorder")
require (CTRL_PATH.."m64_StepSequencer")
require (CTRL_PATH.."m128_MatrixEffect")
require (CTRL_PATH.."m128_MixerTransport")
require (CTRL_PATH.."m128_RecorderMixer")
require (CTRL_PATH.."m128_RecorderMatrix")
require (CTRL_PATH.."m128_StepSequencer")
