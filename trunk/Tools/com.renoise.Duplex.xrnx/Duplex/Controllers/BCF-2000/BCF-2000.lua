--[[----------------------------------------------------------------------------
-- Duplex.Bcf-2000
----------------------------------------------------------------------------]]--

-- default configurations of the Bcf-2000
-- only uses a control map and the MixConsole application


--==============================================================================

class "BFC2000" (MidiDevice)

function BFC2000:__init(name, message_stream)
  TRACE("BFC2000:__init", name, message_stream)

  MidiDevice.__init(self, name, message_stream)

  -- the motor faders of the BFC can not handle looped back messages
  -- correctly, so we disable sending back messages we got from the BFC
  -- in order to break feedback loops...
  self.loopback_received_messages = false
end

--------------------------------------------------------------------------------

device_configurations:insert {

  -- configuration properties
  name = "MixConsole",
  pinned = true,

  -- device properties
  device = {
    class_name = "BFC2000",          
    display_name = "BCF-2000",
    device_name = "BCF2000",
    control_map = "Controllers/BCF-2000/BCF-2000.xml",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  -- setup "MixConsole" as the only app for this configuration
  applications = {
    MixConsole = {
      mute = {
        group_name = "Buttons1",
      },
      panning = {
        group_name= "Encoders",
      },
      levels = {
        group_name = "Faders",
      },
      page = {
        group_name = "PageControls",
      }
    }
  }
}
