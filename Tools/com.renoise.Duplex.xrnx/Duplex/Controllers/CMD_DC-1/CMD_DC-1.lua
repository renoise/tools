--[[----------------------------------------------------------------------------
-- Duplex.CMDDC1 
----------------------------------------------------------------------------]]--

--[[

Inheritance: CMDDC1 > MidiDevice > Device

A device-specific class 

--]]


--==============================================================================


class "CMDDC1" (MidiDevice)

function CMDDC1:__init(display_name, message_stream, port_in, port_out)
  TRACE("CMDDC1:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

  -- this device has a color-space with 4 degrees of red and green
  -- self.colorspace = {1, 1, 2}
  self.loopback_received_messages = true
  self.default_midi_channel = 6
end



function CMDDC1:send_note_message(num,value,channel,elm,point)

 if (elm.type == "button") then

  if (value == 127 ) then
    MidiDevice.send_midi(self,{tonumber('0x9'..tostring(channel-1)),num,1})
  else 
    MidiDevice.send_midi(self,{tonumber('0x9'..tostring(channel-1)),num,0})
  end

 end

end

function CMDDC1:send_cc_message(num,value,channel)

 local v=math.floor((value%128)/8)
 
 if (num>16) then
  MidiDevice.send_cc_message(self,num,v,channel)
 end

end