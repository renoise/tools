--[[============================================================================
--- The Duplex Library
============================================================================]]--

--[[--

]]

-- include supporting classes

rns = nil
_trace_filters = nil
--_trace_filters = {"^UIButton*"}
--_trace_filters = {"^StateController*"}
--_trace_filters = {"^Recorder*","^UISlider*"}
--_trace_filters = {".*"}

_clibroot = "cLib/classes/"
_xlibroot = "xLib/classes/"

require (_clibroot.."cLib")
require (_clibroot.."cDebug")
require (_clibroot.."cColor")
require (_clibroot.."cScheduler")
require (_clibroot.."cProcessSlicer")

require (_xlibroot.."xMessage")
require (_xlibroot.."xMidiMessage")
require (_xlibroot.."xAutomation")
require (_xlibroot.."xTrack")
require (_xlibroot.."xTransport")
require (_xlibroot.."xScale")
require (_xlibroot.."xInstrument")
require (_xlibroot.."xNoteColumn")
require (_xlibroot.."xPatternSequencer")
require (_xlibroot.."xSongSettings")
require (_xlibroot.."xCursorPos")


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
require "Duplex/UIKeyPressure"
require "Duplex/UIPitchBend"
require "Duplex/UILabel"
require "Duplex/UILed"
require "Duplex/ControlMap"
require "Duplex/Device"
require "Duplex/MidiDevice"
require "Duplex/OscDevice"
require "Duplex/OscClient"
require "Duplex/OscVoiceMgr"
require "Duplex/Application"
require "Duplex/Automateable" -- extends Application
require "Duplex/RoamingDSP" -- extends Automateable
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

