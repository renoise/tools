--[[----------------------------------------------------------------------------
-- Duplex.Controllers.Akai-MPK225
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "FocusSwitcher",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "Akai-MPK225",
    device_port_in = "",
    device_port_out = "",
    control_map = "Controllers/Akai-MPK225/Controlmaps/MPK225.xml",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {

    PatternEditor = {
      application = "MidiActions",
      mappings = {control = {group_name = "Triggers",index = 1}},
      options = {action = "GUI:Middle Frame:Show Pattern Editor [Trigger]"},
    },
    ShowMixer = {
      application = "MidiActions",
      mappings = {control = {group_name = "Triggers",index = 2}},
      options = {action = "GUI:Middle Frame:Show Mixer [Trigger]"},
    },
    SampleKeyzones = {
      application = "MidiActions",
      mappings = {control = {group_name = "Triggers",index = 3}},
      options = {action = "GUI:Middle Frame:Show Instrument Sample Keyzones [Trigger]"},
    },
    SampleEditor = {
      application = "MidiActions",
      mappings = {control = {group_name = "Triggers",index = 4}},
      options = {action = "GUI:Middle Frame:Show Instrument Sample Editor [Trigger]"},
    },
    SampleModulation = {
      application = "MidiActions",
      mappings = {control = {group_name = "Triggers",index = 5}},
      options = {action = "GUI:Middle Frame:Show Instrument Sample Modulation [Trigger]"},
    },
    SampleEffects = {
      application = "MidiActions",
      mappings = {control = {group_name = "Triggers",index = 6}},
      options = {action = "GUI:Middle Frame:Show Instrument Sample Effects [Trigger]"},
    },
    PluginEditor = {
      application = "MidiActions",
      mappings = {control = {group_name = "Triggers",index = 7}},
      options = {action = "GUI:Middle Frame:Show Instrument Plugin Editor [Trigger]"},
    },
    MidiEditor = {
      application = "MidiActions",
      mappings = {control = {group_name = "Triggers",index = 8}},
      options = {action = "GUI:Middle Frame:Show Instrument Midi Editor [Trigger]"},
    },

  },
}