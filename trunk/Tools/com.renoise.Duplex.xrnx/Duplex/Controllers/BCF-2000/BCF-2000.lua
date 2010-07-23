--[[----------------------------------------------------------------------------
-- Duplex.Bcf-2000
----------------------------------------------------------------------------]]--

-- default configuration of the BCF-2000
-- uses a custom device class, a control map and the Mixer application


--==============================================================================

class "BCF2000" (MidiDevice)

function BCF2000:__init(display_name, message_stream, port_in, port_out)
  TRACE("BCF2000:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

  -- the BCF can not handle looped back messages correctly, so we disable 
  -- sending back messages we got from the BCF, in order to break feedback loops...
  self.loopback_received_messages = false
end


--------------------------------------------------------------------------------

-- setup a Mixer app as the only app for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer",
  pinned = true,

  -- device properties
  device = {
    class_name = "BCF2000",          
    display_name = "BCF-2000",
    device_port_in = "BCF2000",
    device_port_out = "BCF2000",
    control_map = "Controllers/BCF-2000/BCF-2000.xml",
    thumbnail = "BCF-2000.bmp",
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
        },
        page = {
          group_name = "PageControls",
        },
        mode = {
          group_name = "ModeControls",
        }
      },
      options = {
        pre_post = 2
      }
    }
  }
}

