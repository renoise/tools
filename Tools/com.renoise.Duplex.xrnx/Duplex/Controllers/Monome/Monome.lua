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

  self.SERIALOSC = 1
  self.MONOMESERIAL = 2

  -- set the default communication protocol 
  self.comm_protocol = self.MONOMESERIAL

  -- enable/disable device tilt sensors on startup
  -- e.g. {true,false,true} to enable 1st and 3rd sensor
  self.adc_enabled = {true}

  -- determine the initial brightness (0-15)
  self.brightness = 10

  -- this device has a monochrome color-space 
  self.colorspace = {1}

  OscDevice.__init(self, name, message_stream,prefix,address,port_in,port_out)

  -- set our own defaults
  self.feedback_prevention_enabled = true
  --self.bundle_messages = true


end

--------------------------------------------------------------------------------

-- set prefix both for Duplex and the MonomeSerial application,
-- perform other device initialization here as well...
-- @param prefix (string), e.g. "/my_device" 

function Monome:set_device_prefix(prefix)
  TRACE("Monome:set_device_prefix()",prefix)

  -- unlike the generic OscDevice, monome always need a prefix value
  if not prefix then return end

  OscDevice.set_device_prefix(self,prefix)

  if (self.client) and (self.client.is_open) then
    self.client:send(
      renoise.Osc.Message("/sys/prefix",{
        {tag="i", value=0},
        {tag="s", value=self.prefix} 
      })
    )

    -- set brightness
    local osc_msg = "/grid/led/intensity %i"
    self:send_osc_message(osc_msg,self.brightness)

    -- enable tilt sensor 
    for k,v in ipairs(self.adc_enabled) do
      local osc_val = v and 1 or 0
      local osc_msg = ("/tilt/set %i %%i"):format(k)
      self:send_osc_message(osc_msg,osc_val)
    end

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

-- override default OscDevice method (comm protocol support)
-- @return false when message was rejected 

function Monome:send_osc_message(message,value)
  --TRACE("Monome:send_osc_message()",message,value)

  if (self.comm_protocol==self.MONOMESERIAL) then

    -- put the most often-used first
    if (string.sub(message,1,13)=="/grid/led/set") then
      message = "/led"..string.sub(message,14)
    elseif (string.sub(message,1,19)=="/grid/led/intensity") then
      message = "/intensity"..string.sub(message,20)
    end
    
  end

  OscDevice.send_osc_message(self,message,value)
  
end


--------------------------------------------------------------------------------

-- override default OscDevice method (comm protocol support)

function Monome:receive_osc_message(value_str)
  --TRACE("Monome:receive_osc_message()",value_str)

  --print("*** Monome.receive_osc_message - value_str",value_str)

  if (self.comm_protocol==self.MONOMESERIAL) then

    if (string.sub(value_str,1,6)=="/tilt ") then
      -- split the message into non-whitespace chunks
      local split_msg = string.gmatch(value_str,"[^%s]+")
      local osc_vars = table.create()
      for vars in split_msg do
        osc_vars:insert(vars)
      end
      value_str = ("/tilt 0 %i %i 0"):format(osc_vars[2],osc_vars[3])
    elseif(string.sub(value_str,1,6)=="/press") then
      value_str = "/grid/key"..string.sub(value_str,7)
    end

  end

  OscDevice.receive_osc_message(self,value_str)
  
end



