--[[----------------------------------------------------------------------------
-- Duplex.Bcf-2000
----------------------------------------------------------------------------]]--

-- default configurations of the Bcf-2000
-- only uses a control map and the MixConsole application


--------------------------------------------------------------------------------

device_configurations:insert {

  -- configuration properties
  name = "MixConsole",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "BCF-2000",
    device_name = "BCF2000",
    control_map = "Controllers/BCF-2000/bcf-2000.xml",
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
