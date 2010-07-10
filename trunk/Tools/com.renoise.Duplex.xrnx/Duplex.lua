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
require "Duplex/UITriggerButton"
require "Duplex/UISlider"
require "Duplex/UISpinner"
require "Duplex/ControlMap"
require "Duplex/Device"
require "Duplex/MidiDevice"
require "Duplex/OscDevice"
require "Duplex/Application"
require "Duplex/Browser"
require "Duplex/Scheduler"

-- TODO: find and load controllers and apps dynamically

require "Duplex/Applications/Mixer"
require "Duplex/Applications/Matrix"
require "Duplex/Applications/Effect"

require "Duplex/Controllers/BCF-2000/BCF-2000"
require "Duplex/Controllers/BCR-2000/BCR-2000"
require "Duplex/Controllers/Launchpad/Launchpad"
require "Duplex/Controllers/Ohm64/Ohm64"
require "Duplex/Controllers/Nocturn/Nocturn"
require "Duplex/Controllers/Remote-SL-MKII/Remote-SL-MKII"

