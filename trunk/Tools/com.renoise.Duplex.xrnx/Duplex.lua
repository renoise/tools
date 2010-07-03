--[[--------------------------------------------------------------------------
 The Duplex Library
--------------------------------------------------------------------------]]--

-- includes

require "Duplex/Globals"
require "Duplex/MessageStream"
require "Duplex/Display"
require "Duplex/Canvas"
require "Duplex/UIComponent"
require "Duplex/UIToggleButton"
require "Duplex/UISlider"
require "Duplex/UISpinner"
require "Duplex/ControlMap"
require "Duplex/Device"
require "Duplex/MIDIDevice"
require "Duplex/OscDevice"
require "Duplex/Application"
require "Duplex/Browser"

-- TODO: find and load controllers and apps dynamically

require "Duplex/Applications/MixConsole"
require "Duplex/Applications/PatternMatrix"

require "Duplex/Controllers/BCF-2000/Bcf-2000"
require "Duplex/Controllers/BCR-2000/Bcr-2000"
require "Duplex/Controllers/Launchpad/Launchpad"
require "Duplex/Controllers/Ohm64/Ohm64"
require "Duplex/Controllers/Nocturn/Nocturn"
require "Duplex/Controllers/Remote-SL-MKII/Remote-SL-MKII"

