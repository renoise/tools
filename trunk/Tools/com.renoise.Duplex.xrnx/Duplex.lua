--[[============================================================================
 The Duplex Library
============================================================================]]--

-- include the duplex core

require "Duplex/Globals"
require "Duplex/MessageStream"
require "Duplex/Display"
require "Duplex/Canvas"
require "Duplex/UIComponent"
require "Duplex/UIButtonStrip"
require "Duplex/UIToggleButton"
require "Duplex/UIPushButton"
require "Duplex/UISlider"
require "Duplex/UISpinner"
require "Duplex/ControlMap"
require "Duplex/Device"
require "Duplex/MidiDevice"
require "Duplex/OscDevice"
require "Duplex/Application"
require "Duplex/Browser"
require "Duplex/Scheduler"


-- load all application scripts dynamically (Applications/XXX.lua)

for _, filename in pairs(os.filenames("./Duplex/Applications", "*.lua")) do
  require("Duplex/Applications/" .. split_filename(filename))
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
end

