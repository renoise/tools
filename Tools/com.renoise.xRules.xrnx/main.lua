--[[============================================================================
main.lua
============================================================================]]--
--[[--

# xRules

xRules lets you rewrite and transform incoming MIDI/OSC messages on-the-fly, using a visual programming interface. Outgoing messages can be routed into Renoise, or passed on to external devices. 

## Links

Renoise: [Tool page](http://www.renoise.com/tools/xrules/)

Renoise Forum: [Feedback and bugs](http://forum.renoise.com/index.php/topic/47224-new-tool-31-xrules/)

Github: [Documentation and source](https://github.com/renoise/xrnx/blob/master/Tools/com.renoise.xRules.xrnx/) 



--]]

--==============================================================================

_trace_filters = nil
--_trace_filters = {".*"}
--_trace_filters = {"^xRule*"}

_clibroot = "source/cLib/classes/"
_xlibroot = "source/xLib/classes/"
_vlibroot = "source/vLib/classes/"
_vlib_img = _vlibroot .. "images/"

require (_clibroot.."cLib")
require (_clibroot.."cDebug")
require (_clibroot.."cFilesystem")
require (_clibroot.."cDocument")
require (_clibroot.."cSandbox")
require (_clibroot.."cReflection")
require (_clibroot.."cObservable")
require (_clibroot.."cPreferences")
require (_clibroot.."cParseXML")
require (_clibroot.."cString")

cLib.require (_xlibroot.."xLib")
cLib.require (_xlibroot.."xAudioDevice")
cLib.require (_xlibroot.."xAutomation")
cLib.require (_xlibroot.."xMessage")
cLib.require (_xlibroot.."xValue")
cLib.require (_xlibroot.."xMidiMessage")
cLib.require (_xlibroot.."xMidiInput")
cLib.require (_xlibroot.."xOscRouter")
cLib.require (_xlibroot.."xOscPattern")
cLib.require (_xlibroot.."xOscMessage")
cLib.require (_xlibroot.."xOscValue")
cLib.require (_xlibroot.."xOscClient")
cLib.require (_xlibroot.."xOscDevice")
cLib.require (_xlibroot.."xNoteColumn")
cLib.require (_xlibroot.."xTrack")
cLib.require (_xlibroot.."xTransport")
cLib.require (_xlibroot.."xBlockLoop")
cLib.require (_xlibroot.."xSongPos")
cLib.require (_xlibroot.."xPlayPos")
cLib.require (_xlibroot.."xParameter")
cLib.require (_xlibroot.."xPhraseManager")
cLib.require (_xlibroot.."xRule")
cLib.require (_xlibroot.."xRuleset")
cLib.require (_xlibroot.."xRules")
cLib.require (_xlibroot.."xScale")

require (_vlibroot.."vLib")
require (_vlibroot.."vTable")
require (_vlibroot.."vLogView")
require (_vlibroot.."vPrompt")
require (_vlibroot.."vDialog")
require (_vlibroot.."vArrowButton")
require (_vlibroot.."vDialogWizard")
require (_vlibroot.."vFileBrowser")
--require (_vlibroot.."helpers/vVector")

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

--------------------------------------------------------------------------------
-- main
--------------------------------------------------------------------------------

rns = nil
app = nil

-- pre-launch configuration
local preferences = xRulesAppPrefs()
--renoise.tool().preferences = preferences

local cprefs = cPreferences{
  tool_name = "xRules",
  doc_class_name = "xRulesAppPrefs",
}

local launch_with_profile = function(doc)
  renoise.tool().preferences = doc
  app = xRulesApp(cprefs)
end

local show_dialog = function()
  if app then
    app:show_dialog()
  else
    cprefs.launch_callback = function(doc)
      launch_with_profile(doc)
      app:show_dialog()
    end
    cprefs.default_callback = function()
      renoise.tool().preferences = preferences
      app = xRulesApp(cprefs)
      app:show_dialog()
    end
    cprefs:attempt_launch()
  end
end

local launch = function()
  if app then
    app:launch()
  else
    cprefs.launch_callback = function(doc)
      --print(">>> launch_callback (launch)...")
      launch_with_profile(doc)
      app:launch()
    end
    cprefs.default_callback = function()
      renoise.tool().preferences = preferences
      app = xRulesApp(cprefs)
      app:launch()
    end
    cprefs:attempt_launch()
  end
end


--------------------------------------------------------------------------------
-- menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:xRules",
  invoke = function()
    show_dialog()
  end  
}

--------------------------------------------------------------------------------
-- keybindings
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Global:xRules:Show Dialog...",
  invoke = function(repeated) 
    if (not repeated) then 
      app:show_dialog()
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
  if waiting_to_show_dialog 
    and renoise.song()
  then
    rns = renoise.song()
    waiting_to_show_dialog = false
    if preferences.autorun_enabled.value then
      launch()
    end
    if preferences.show_on_startup.value then
      show_dialog()
    end
    renoise.tool().app_idle_observable:remove_notifier(app_idle_notifier)
  end
end
renoise.tool().app_idle_observable:add_notifier(app_idle_notifier)

renoise.tool().app_new_document_observable:add_notifier(function()
  --print(">>> app_new_document_observable fired...",rns,renoise.song())
  rns = renoise.song()
end)

renoise.tool().app_release_document_observable:add_notifier(function()
  --print(">>> app_release_document_observable fired...",rns,renoise.song())
  rns = renoise.song()
end)

