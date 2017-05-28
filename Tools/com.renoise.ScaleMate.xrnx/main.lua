--[[============================================================================
com.renoise.ScaleMate.xrnx/main.lua
============================================================================]]--
--[[

ScaleMate tool registration

]]

--------------------------------------------------------------------------------
-- Require files (app+libraries)
--------------------------------------------------------------------------------

-- where to find the cLib classes (required) 
_clibroot = 'source/cLib/classes/'
_xlibroot = 'source/xLib/classes/'

-- debug/trace filters can be configured here
-- (see cDebug for more details)
--_trace_filters = {".*"} -- trace everything
_trace_filters = nil  -- no tracing

require (_clibroot..'cLib')
--require (_clibroot..'cDebug')
require (_clibroot..'cObservable')
require (_xlibroot..'xScale')
require (_xlibroot..'xMidiCommand')
require (_xlibroot..'xEffectColumn')
require (_xlibroot..'xLinePattern')

require ('source/ScaleMate')
require ('source/ScaleMate_UI')
require ('source/ScaleMate_Prefs')

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

-- this string is assigned as the dialog title
APP_DISPLAY_NAME = "ScaleMate"

-- reference to the dialog that contains the application UI
local app,dialog

-- implementing preferences as a class only has benefits
-- (you can still use renoise.tool().preferences from anywhere...)   
local prefs = ScaleMate_Prefs()
renoise.tool().preferences = prefs

-- a global reference to renoise.song(),
-- the variable is set when show() is called
rns = nil



--------------------------------------------------------------------------------
-- Menu entries & MIDI/Key mappings
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:"..APP_DISPLAY_NAME.."...",
  invoke = function() 
    show() 
  end
} 
renoise.tool():add_keybinding {
  name = "Global:"..APP_DISPLAY_NAME..":Show dialog...",
  invoke = function(repeated)
    if (not repeated) then 
      show() 
    end
  end
}

--------------------------------------------------------------------------------
-- Show the application UI --------------------------------------------------------------------------------

function show()

  -- set global reference to the renoise song
  rns = renoise.song()

  -- create dialog if it doesn't exist
  if not dialog then
    app = ScaleMate{
      dialog_title = "ScaleMate"
    }
    dialog = app.dialog
  end

  dialog:show()
  
end

renoise.tool().app_new_document_observable:add_notifier(function()
  show()
end)
--[[
]]
