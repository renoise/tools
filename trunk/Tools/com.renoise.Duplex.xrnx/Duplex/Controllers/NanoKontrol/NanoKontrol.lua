--[[----------------------------------------------------------------------------
-- Duplex.NanoKontrol
----------------------------------------------------------------------------]]--

-- default configuration of the NanoKontrol
-- uses a custom device class, a control map and the Mixer application


--==============================================================================

class "NanoKontrol" (MidiDevice)

function NanoKontrol:__init(display_name, message_stream, port_in, port_out)
  TRACE("NanoKontrol:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

  self.loopback_received_messages = false
end


--------------------------------------------------------------------------------

-- setup a Mixer app as the only app for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer + Transport",
  pinned = true,

  -- device properties
  device = {
    class_name = "NanoKontrol",          
    display_name = "NanoKontrol",
    device_port_in = "NanoKontrol",
    device_port_out = "NanoKontrol",
    control_map = "Controllers/NanoKontrol/NanoKontrol.xml",
    thumbnail = "NanoKontrol.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  applications = {
    Mixer = {
      mappings = {
        mute = {
          group_name = "Buttons1",
        },
        solo = {
          group_name = "Buttons2",
        },
        panning = {
          group_name= "Encoders",
        },
        levels = {
          group_name = "Faders",
        }
    },
  },
    Transport = {
      mappings = {
        goto_previous = {
          group_name = "Transport",
          index = 1,
        },
        goto_next = {
          group_name = "Transport",
          index = 3,
        },
        stop_playback = {
          group_name = "Transport",
          index = 5,
        },
        start_playback = {
          group_name = "Transport",
          index = 2,
        },
        loop_pattern = {
          group_name = "Transport",
          index = 4,
        },
        edit_mode = {
          group_name = "Transport",
          index = 6,
        },
      },
    },
  }
}

