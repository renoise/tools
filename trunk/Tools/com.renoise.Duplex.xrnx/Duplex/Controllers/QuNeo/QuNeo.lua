--[[----------------------------------------------------------------------------
-- Duplex.QuNeo
----------------------------------------------------------------------------]]--

--[[

Inheritance: QuNeo > MidiDevice > Device

A device-specific class 

--]]

--==============================================================================

class "QuNeo" (MidiDevice)

function QuNeo:__init(display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

  -- this device has a color-space with 128 degrees of red and green
  self.colorspace = {0x7F, 0x7F, 0}

end

function QuNeo:send_note_message(num,value,channel,elm,point)

  if elm.quneo_pad_mode then

    -- if the control-map define a "quneo_pad_mode" value, 
    -- send a specially formatted value

    if (elm.quneo_pad_mode == "pad") then

      local r_level = math.floor(point.color[1]/2)
      local g_level = math.floor(point.color[2]/2)
      MidiDevice.send_note_message(self,num,g_level,channel)
      MidiDevice.send_note_message(self,num+1,r_level,channel)

    elseif (elm.quneo_pad_mode == "grid") then
      -- not implemented
    elseif (elm.quneo_pad_mode == "corner") then
      -- not implemented
    end

  else

    -- normal note
    MidiDevice.send_note_message(self,num,value,channel)

  end



end


