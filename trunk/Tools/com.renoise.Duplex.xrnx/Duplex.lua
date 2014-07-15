--[[============================================================================
--- The Duplex Library
============================================================================]]--

--[[--
  Include the duplex core, applications and device configurations
]]

require "Duplex/Globals"
require "Duplex/Preferences"
require "Duplex/Automation"
require "Duplex/Message"
require "Duplex/MessageStream"
require "Duplex/Display"
require "Duplex/StateController"
require "Duplex/WidgetHooks"
require "Duplex/WidgetKeyboard"
require "Duplex/Canvas"
require "Duplex/CanvasPoint"
require "Duplex/UIComponent"
require "Duplex/UIButtonStrip"
require "Duplex/UIButton"
require "Duplex/UISlider"
require "Duplex/UISpinner"
require "Duplex/UIPad"
require "Duplex/UIKey"
require "Duplex/UIKeyPressure"
require "Duplex/UIPitchBend"
require "Duplex/UILabel"
require "Duplex/ControlMap"
require "Duplex/Device"
require "Duplex/MidiDevice"
require "Duplex/OscDevice"
require "Duplex/OscClient"
require "Duplex/OscVoiceMgr"
require "Duplex/Application"
require "Duplex/RoamingDSP" -- depends on Application
require "Duplex/Browser"
require "Duplex/BrowserProcess"
require "Duplex/Scheduler"
require "Duplex/ProcessSlicer"


-- load all application scripts dynamically (Applications/XXX.lua)

for _, filename in pairs(os.filenames("./Duplex/Applications", "*.lua")) do
  local app_name = split_filename(filename)
  require("Duplex/Applications/" .. app_name)
end


-- load all controller scripts dynamically (Controllers/XXX/XXX.lua)

for _, foldername in pairs(os.dirnames("./Duplex/Controllers")) do
  local subpath = "./Duplex/Controllers/" .. foldername

  for _, filename in pairs(os.filenames(subpath, "*.lua")) do
    -- only load the controller file that matches the controller folder name
    if (split_filename(filename) == foldername) then
      require(subpath .. "/" .. split_filename(filename))
    end
  end

  -- include any device configurations (Controller/Configurations/XXX.lua)
  subpath = "./Duplex/Controllers/" .. foldername .. "/Configurations"
  for _, filename in pairs(os.filenames(subpath, "*.lua")) do
    require(subpath .. "/" .. split_filename(filename))
  end

end

