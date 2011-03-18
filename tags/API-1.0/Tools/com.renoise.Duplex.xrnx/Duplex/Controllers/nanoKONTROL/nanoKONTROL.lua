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
    display_name = "nanoKONTROL",
    device_port_in = "nanoKONTROL",
    device_port_out = "nanoKONTROL",
    control_map = "Controllers/nanoKONTROL/nanoKONTROL.xml",
    thumbnail = "nanoKONTROL.bmp",
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
          group_name = "TransportRow1",
          index = 1,
        },
        start_playback = {
          group_name = "TransportRow1",
          index = 2,
        },
        goto_next = {
          group_name = "TransportRow1",
          index = 3,
        },
        
        loop_pattern = {
          group_name = "TransportRow2",
          index = 1,
        },
        stop_playback = {
          group_name = "TransportRow2",
          index = 2,
        },
        edit_mode = {
          group_name = "TransportRow2",
          index = 3,
        },
      },
      options = {
      }

    },
  }
}

