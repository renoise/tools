--[[============================================================================
main.lua
============================================================================]]--

--[[

Unit-tests for the xLib library
.
#

TODO 
* capture results from asynchroneous test methods

PLANNED 
* turn tool into simple testrunner framework (class)


]]

_xlib_tests = table.create()
_trace_filters = {".*"}

_clibroot = "source/cLib/classes/"
_vlibroot = 'source/vLib/classes/'
_xlibroot = "source/xLib/classes/"

require (_clibroot.."cLib")
require (_clibroot.."cDebug")
require (_clibroot.."cFilesystem")
require (_vlibroot..'vLib')
require (_vlibroot..'vDialog')
require (_vlibroot..'vTable')
require (_xlibroot.."xLib")

require ('source/xLibTool')
require ('source/xLibPrefs')

--------------------------------------------------------------------------------
-- test runner
--------------------------------------------------------------------------------

-- this string is assigned as the dialog title
APP_DISPLAY_NAME = "xLib"

-- reference to the vDialog that contains the application UI
local vdialog

-- implementing preferences as a class only has benefits
-- (you can still use renoise.tool().preferences from anywhere...)   
local prefs = xLibPrefs()
renoise.tool().preferences = prefs

rns = nil 


--------------------------------------------------------------------------------
-- Show the application UI 
--------------------------------------------------------------------------------

function show()

  -- set global reference to the renoise song
  rns = renoise.song()

  -- create dialog if it doesn't exist
  if not vdialog then
    vdialog = xLibTool{
      dialog_title = APP_DISPLAY_NAME,
      waiting_to_show_dialog = prefs.autostart.value,
    }
  end

  vdialog:show()
  
end

--------------------------------------------------------------------------------
-- menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:xLib",
  invoke = function()
    show()
  end  
}

--------------------------------------------------------------------------------
-- notifications
--------------------------------------------------------------------------------

renoise.tool().app_new_document_observable:add_notifier(function()
  rns = renoise.song()
  if prefs.autostart.value then
    show()
  end
end)

