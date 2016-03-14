--[[============================================================================
main.lua
============================================================================]]--
--[[--

## About

  xLib-based tool, boilerplate code

--]]

--==============================================================================

--remdebug.engine.start()

_trace_filters = {".*"}
_trace_filters = nil

_xlibroot = "source/xLib/classes/"
require (_xlibroot.."xLib")
require (_xlibroot.."xDebug")
require (_xlibroot.."xDocument")
require (_xlibroot.."xFilesystem")
require (_xlibroot.."xMessage")
require (_xlibroot.."xValue")
require (_xlibroot.."xMidiMessage")
require (_xlibroot.."xMidiInput")
require (_xlibroot.."xOscRouter")
require (_xlibroot.."xOscPattern")
require (_xlibroot.."xOscMessage")
require (_xlibroot.."xOscValue")
require (_xlibroot.."xOscClient")
require (_xlibroot.."xOscDevice")
require (_xlibroot.."xNoteColumn")
require (_xlibroot.."xSandbox")
require (_xlibroot.."xParseXML")
require (_xlibroot.."xObservable")
require (_xlibroot.."xReflection")
require (_xlibroot.."xRule")
require (_xlibroot.."xRuleset")
require (_xlibroot.."xRules")

_vlibroot = "source/vLib/classes/"
_vlib_img = _vlibroot .. "images/"
require (_vlibroot.."vLib")
require (_vlibroot.."vTable")
require (_vlibroot.."vLogView")
require (_vlibroot.."vPrompt")
require (_vlibroot.."vDialog")
require (_vlibroot.."vDialogWizard")
require (_vlibroot.."vFileBrowser")
require (_vlibroot.."helpers/vVector")
require (_vlibroot.."helpers/vString")

require "source/xRulesApp"
require "source/xRulesAppPrefs"
require "source/xRulesUI"
require "source/xRulesUIAction"
require "source/xRulesUICondition"
require "source/xRulesUIEditor"
require "source/xRulesAppDialogCreate"
require "source/xRulesAppDialogExport"
require "source/xRulesAppDialogPrefs"
require "source/xRulesAppDialogHelp"
require "source/xRulesAppDialogLog"

--------------------------------------------------------------------------------
-- main
--------------------------------------------------------------------------------

rns = nil

local preferences = xRulesAppPrefs()
renoise.tool().preferences = preferences

--print("main.lua - #midi_inputs",#preferences.midi_inputs)
--print("main.lua - #osc_devices",#preferences.osc_devices)

-- issue: DocumentList (osc_devices) is not accessible 
-- workaround: manually import preferences
--preferences:import("./preferences.xml")

app = xRulesApp(preferences)



--------------------------------------------------------------------------------
-- menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:xRules",
  invoke = function()
    if app then
      app:show_dialog()
    end
  end  
}

--------------------------------------------------------------------------------
-- keybindings
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Global:xRules:Show Dialog...",
  invoke = function(repeated) 
    if (not repeated) then 
      if app then
        app:show_dialog()
      end
    end
  end
}

--------------------------------------------------------------------------------
-- notifications
--------------------------------------------------------------------------------

-- show/run application once renoise is ready
-- (workaround for http://goo.gl/UnSDnw)
local waiting_to_show_dialog = true
local function app_idle_notifier()
  --print("*** app_idle_notifier")
  if app 
    and waiting_to_show_dialog 
    or renoise.song() -- app:is_running()
  then
    rns = renoise.song()
    waiting_to_show_dialog = false
    if app.prefs.autorun_enabled.value then
      app:launch()
    end
    if app.prefs.show_on_startup.value then
      app:show_dialog()
    end
    renoise.tool().app_idle_observable:remove_notifier(app_idle_notifier)
  end
end
renoise.tool().app_idle_observable:add_notifier(app_idle_notifier)

renoise.tool().app_new_document_observable:add_notifier(function()
  rns = renoise.song()

end)

--[[
renoise.tool().app_release_document_observable:add_notifier(function()
  if app:is_running() then
    app:detach_from_song()
  end

end)

]]

