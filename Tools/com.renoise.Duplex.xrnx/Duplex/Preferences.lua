--[[============================================================================
-- Duplex.Preferences
============================================================================]]--

--[[--

Manage global settings or individual device-configuration settings for Duplex

Device and application setup for controllers are registered by the controllers itself. Each entry is a file located in the Controllers/Configuration subfolder, and must have the following properties defined:

    {
     ** configuration properties
     name = "Some Config", -- config name as visible in the browser
     pinned = true, -- when true, config is added to the Duplex context menu

     ** device properties
     device = {
       class_name = nil, -- optional custom device class          
       display_name = "Some Device", -- as visible in the browser
       device_name = "Some Device", -- MIDI device name
       control_map = "controlmap.xml", -- path & name of the control map
       protocol = DEVICE_PROTOCOL.MIDI
     },

     ** applications
     applications = { -- list of applications and app configs
       Mixer = { options = "Something" }, -- a mixer app
       Effect = { options = "Something" } -- an effect app
     } 
    }

Once defined, the configuration will be shown in the browser by it's device name   

--]]

--==============================================================================

duplex_configurations = table.create()


--------------------------------------------------------------------------------

--- Global or configuration settings for Duplex

duplex_preferences = renoise.Document.create("ScriptingToolPreferences") {

  --- (number) the seconds required to trigger `DEVICE_EVENT.BUTTON_HELD`
  -- fractional values are supported, 0.5 is half a second
  button_hold_time = 0.5,

  --- (number) the amount of extrapolation applied to automation
  extrapolation_strength = 3,

  --- (table) theming support: specify the default button color
  -- @field red 0xc1
  -- @field blue 0x34
  -- @field green 0x11
  -- @table theme_color
  theme_color = {0xc1,0x34,0x11},

  --- (bool) when enabled, the Duplex browser is displayed on startup
  display_browser_on_start = true,

  --- (bool) enable realtime NRPN message support (experimental)
  nrpn_support = false,

  --- (bool) dump MIDI messages to sdt out (Renoise terminal)
  dump_midi = false,
  
  --- (bool) dump OSC messages to sdt out (Renoise terminal)
  dump_osc = false,
  
  --- (string) the internal OSC connection (disabled if no host/port is specified)
  osc_server_host = "127.0.0.1",

  --- (int) the internal OSC port address
  -- (set this to whatever the renoise OSC server is set to)
  osc_server_port = 8000,

  --- (bool) when OSC is being run the first time, display a message
  osc_first_run = true,

  --- list of user configuration settings (like MIDI device names, app configs)
  -- added during runtime for all available configs:
  
  -- configurations = {
  --    autostart [bool] -- if this config should be started with Renoise
  --    device_in_port [string] -- custom MIDI in device name
  --    device_out_port [string] -- custom MIDI out device name
  -- }
}


