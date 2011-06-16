--[[----------------------------------------------------------------------------
-- Duplex.ZoomR16
----------------------------------------------------------------------------]]--

--[[

Inheritance: ZoomR16 > MidiDevice > Device

A device-specific class 

--]]


--==============================================================================

class "ZoomR16" (MidiDevice)

function ZoomR16:__init(display_name, message_stream, port_in, port_out)
  TRACE("ZoomR16:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

  -- setup a monochrome colorspace for the Zoom
  self.colorspace = {1,1,1}
end


--------------------------------------------------------------------------------

-- setup Mixer + Matrix + Effect as apps

duplex_configurations:insert {

  -- configuration properties
  name = "Transport",
  pinned = true,

  -- device properties
  device = {
    class_name = "ZoomR16",
    display_name = "ZoomR16",
    device_port_in = "ZOOM R16_24 Audio Interface",
    device_port_out = "ZOOM R16_24 Audio Interface",
    control_map = "Controllers/ZoomR16/ZoomR16.xml",
    thumbnail = "ZoomR16.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  applications = {
    Transport = {
      mappings = {
        stop_playback = {
          group_name = "Buttons",
          index = 1,
        },
        start_playback = {
          group_name = "Buttons",
          index = 2,
        },

      }
    },

  }
}