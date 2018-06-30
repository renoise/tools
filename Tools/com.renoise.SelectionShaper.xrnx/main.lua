--[[===============================================================================================
main.lua
===============================================================================================]]--

--[[

## About

SSK (Selection Shaper Kai)
Maintained by danoise@renoise since v2.5, original tool by uprime22 & satobox

## Tool page (download)

## Forum (discuss)

## Github (source and documentation)


]]

--=================================================================================================
-- Variables

rns = nil
local app = nil

_trace_filters = {"^vButtonStrip*"}
--_trace_filters = {"^SSK_Gui_Keyzone*"}
_trace_filters = nil
_trace_filters = {".*"}

---------------------------------------------------------------------------------------------------
-- Include required files 

_clibroot = 'source/cLib/classes/'
_vlibroot = 'source/vLib/classes/'
_xlibroot = 'source/xLib/classes/'

require (_clibroot..'cLib')
require (_clibroot..'cDebug')
require (_clibroot..'cTable')
require (_clibroot..'cString')
require (_clibroot..'cReflection')
require (_clibroot..'cWaveform')

require (_vlibroot..'vLib')
require (_vlibroot..'vControl')
require (_vlibroot..'vButtonStrip')
require (_vlibroot..'vDialog')

require (_xlibroot..'xKeyZone')
require (_xlibroot..'xSample')
require (_xlibroot..'xSampleMapping')
require (_xlibroot..'xSampleBuffer')
require (_xlibroot..'xSampleBufferOperation')
require (_xlibroot..'xPersistentSettings')
require (_xlibroot..'xInstrument')
require (_xlibroot..'xNoteColumn')

-- load preferences before some ssk_* classes 
require ('source/ssk_prefs')
renoise.tool().preferences = SSK_Prefs()
local prefs = renoise.tool().preferences

require ('source/ssk_config')
require ('source/gui_util')
require ('source/ssk_gui')
require ('source/ssk_gui_keyzone')
require ('source/ssk_selection')
require ('source/ssk_generator')
require ('source/ssk_modify')
require ('source/ssk_dialog_create')
require ('source/ssk')


---------------------------------------------------------------------------------------------------
-- Create the application instance

function create()
  rns = renoise.song()
  if not app then  
    app = SSK(renoise.tool().preferences)
  end
end

---------------------------------------------------------------------------------------------------
-- Show the application UI 

function show()
  if not app then 
    create()
  end 
  if app.ui then
    app.ui:show()
  end
end

---------------------------------------------------------------------------------------------------
-- Notifications

renoise.tool().app_new_document_observable:add_notifier(function()
  rns = renoise.song()
  show() 
end)

---------------------------------------------------------------------------------------------------

renoise.tool():add_menu_entry{
  name = "Main Menu:Tools:Selection Shaper Kai ...",
  invoke = function() 
    show()
  end
}

renoise.tool():add_menu_entry{
  name = "Sample Editor:Process:Selection Shaper Kai ...",
  invoke = function() 
    show()
  end
}

--[[
renoise.tool():add_keybinding {
  name = "Sample Editor:Selection Shaper:Flick range forward",
  invoke = function()
    flick_range()
  end
}

renoise.tool():add_keybinding {
  name = "Sample Editor:Selection Shaper:Flick range backward",
  invoke = function()
    flick_back()
  end
}
renoise.tool():add_keybinding {
  name = "Sample Editor:Selection Shaper:Flickback and Setloop",
  invoke = function()
    flick_back()
    set_loop()
  end
}

renoise.tool():add_keybinding {
  name = "Sample Editor:Selection Shaper:Flick and Setloop",
  invoke = function()
    flick_range()
    set_loop()
  end
}

--]]

---------------------------------------------------------------------------------------------------
