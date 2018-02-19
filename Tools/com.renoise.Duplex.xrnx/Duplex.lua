--[[===============================================================================================
--- The Duplex Library
===============================================================================================]]--

--[[--

]]

-- include supporting classes

rns = nil
_trace_filters = nil
--_trace_filters = {"^Matrix*"}
--_trace_filters = {"^StateController*"}
--_trace_filters = {"^Recorder*","^UISlider*"}
--_trace_filters = {".*"}

_clibroot = "cLib/classes/"
_xlibroot = "xLib/classes/"

require (_clibroot.."cLib")
require (_clibroot.."cDebug")
require (_clibroot.."cObservable")
require (_clibroot.."cColor")
require (_clibroot.."cScheduler")
require (_clibroot.."cProcessSlicer")

cLib.require (_xlibroot.."xLib")
cLib.require (_xlibroot.."xMessage")
cLib.require (_xlibroot.."xMidiMessage")
cLib.require (_xlibroot.."xAutomation")
cLib.require (_xlibroot.."xBlockLoop")
cLib.require (_xlibroot.."xTrack")
cLib.require (_xlibroot.."xTransport")
cLib.require (_xlibroot.."xSongPos")
cLib.require (_xlibroot.."xPatternPos")
cLib.require (_xlibroot.."xScale")
cLib.require (_xlibroot.."xInstrument")
cLib.require (_xlibroot.."xOscClient")
cLib.require (_xlibroot.."xNoteColumn")
cLib.require (_xlibroot.."xPatternSequencer")
cLib.require (_xlibroot.."xSongSettings")
cLib.require (_xlibroot.."xCursorPos")


-- include the duplex core, applications and device configurations
require "Duplex/Globals"
require "Duplex/Preferences"
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
require "Duplex/UILabel"
require "Duplex/UILed"
require "Duplex/ControlMap"
require "Duplex/Device"
require "Duplex/MidiDevice"
require "Duplex/OscDevice"
require "Duplex/OscVoiceMgr"
require "Duplex/Application"
require "Duplex/Automateable" -- extends Application
require "Duplex/RoamingDSP" -- extends Automateable
require "Duplex/Options"
require "Duplex/Browser"
require "Duplex/BrowserProcess"


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
  -- TODO error message when configuration folder is missing
  subpath = "./Duplex/Controllers/" .. foldername .. "/Configurations"
  for _, filename in pairs(os.filenames(subpath, "*.lua")) do
    require(subpath .. "/" .. split_filename(filename))
  end

end

