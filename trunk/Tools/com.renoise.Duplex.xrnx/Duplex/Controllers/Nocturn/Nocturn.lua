--[[----------------------------------------------------------------------------
-- Duplex.Nocturn
----------------------------------------------------------------------------]]--

-- default configurations of the Nocturn
-- only uses a control map and the MixConsole application

--------------------------------------------------------------------------------

class "Nocturn" (MidiDevice)

function Nocturn:__init(name, message_stream)
  TRACE("Nocturn:__init", name, message_stream)
  MidiDevice.__init(self, name, message_stream)

  self.loopback_received_messages = true

end


device_configurations:insert {

  -- configuration properties
  name = "MixConsole",
  pinned = true,

  -- device properties
  device = {
    class_name = "Nocturn",          
    display_name = "Nocturn Automap",
    device_name = "Automap MIDI",
    control_map = "Controllers/Nocturn/Nocturn.xml",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  -- setup "MixConsole" as the only app for this configuration
  applications = {
    MixConsole = {
      levels = {
        group_name = "Encoders",
      },
      mute = {
        group_name = "Pots",
      },
      master = {
        group_name = "XFader",
      },
    }
  }
}
