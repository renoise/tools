

--[[===============================================================================================
com.renoise.Sononymph.xrnx (main.lua)
===============================================================================================]]--
--[[

  This tool adds Sononym integration to Renoise

]]

---------------------------------------------------------------------------------------------------
-- global variables
---------------------------------------------------------------------------------------------------

rns = nil -- reference to renoise.song() 
_trace_filters = nil -- don't show traces in console
_trace_filters = {".*"}
--_trace_filters = {"^xOscClient"}

---------------------------------------------------------------------------------------------------
-- required files
---------------------------------------------------------------------------------------------------

print("renoise.tool().bundle_path",renoise.tool().bundle_path)

_clibroot = 'source/cLib/classes/'
_vlibroot = 'source/vLib/classes/'
_xlibroot = 'source/xLib/classes/'

require (_clibroot..'cLib')
require (_clibroot..'cDebug')
require (_clibroot..'cFileMonitor')
--require (_clibroot..'cDocument')
--require (_clibroot..'cFilesystem')
--require (_clibroot..'cObservable')
--require (_clibroot..'cReflection')
--require (_clibroot..'cParseXML')
--require (_clibroot..'cSandbox')
--require (_clibroot..'cColor')

cLib.require (_vlibroot..'vLib')
cLib.require (_vlibroot..'vDialog')
cLib.require (_vlibroot..'vToggleButton')
--cLib.require (_vlibroot..'vDialogWizard')
--cLib.require (_vlibroot..'vPrompt')
--cLib.require (_vlibroot..'vTable')

cLib.require (_xlibroot..'xSample')
--cLib.require (_xlibroot..'xLFO')
--cLib.require (_xlibroot..'xAudioDevice')

require ('source/AppPrefs')
require ('source/AppUI')
require ('source/AppUIAbout')
require ('source/App')


---------------------------------------------------------------------------------------------------
-- local variables & initialization
---------------------------------------------------------------------------------------------------

local TOOL_NAME = "Sononymph"
local TOOL_VERSION = "1.0"
local MIDI_PREFIX = "Tools:"..TOOL_NAME..":"

local prefs = AppPrefs()
renoise.tool().preferences = prefs

-- force all dialogs to have this name
vDialog.DEFAULT_DIALOG_TITLE = TOOL_NAME

local app = nil 

---------------------------------------------------------------------------------------------------
-- start application 

function start(do_show)
  rns = renoise.song()
  if not app then 
    app = App{
      prefs = prefs,
      tool_name = TOOL_NAME,
      tool_version = TOOL_VERSION,
      waiting_to_show_dialog = prefs.autostart.value
    }
  end
  if do_show then
    app.ui:show()    
  end
end


---------------------------------------------------------------------------------------------------
-- tool menu entries

function register_tool_menu()
  local str_name = "Main Menu:Tools:"..TOOL_NAME
  local str_name_active = "Main Menu:Tools:"..TOOL_NAME.." (active)"
  if renoise.tool():has_menu_entry(str_name) then
    renoise.tool():remove_menu_entry(str_name)
  elseif renoise.tool():has_menu_entry(str_name_active) then
    renoise.tool():remove_menu_entry(str_name_active)
  end
  renoise.tool():add_menu_entry{
    name = (app and app.active) and str_name_active or str_name,
    invoke = function() 
      start(true) 
    end
  }
end

register_tool_menu()    

---------------------------------------------------------------------------------------------------
-- notifications
---------------------------------------------------------------------------------------------------

renoise.tool().app_new_document_observable:add_notifier(function()
  TRACE("main app_new_document_observable fired...")
  start(prefs.autostart.value)
end)

---------------------------------------------------------------------------------------------------
-- keyboard/midi mappings

local key_mapping, midi_mapping = nil,nil

midi_mapping = MIDI_PREFIX.."Toggle Link [Trigger]"
renoise.tool():add_midi_mapping{
  name = midi_mapping,
  invoke = function() 
    if app then
      app:toggle_link()
    end
  end
}
key_mapping = "Global:"..TOOL_NAME..":".."Toggle Link [Trigger]"
renoise.tool():add_keybinding{
  name = key_mapping,
  invoke = function(repeated) 
    if not repeated then
      if app then
        app:toggle_link()
      end
    end
  end
}




