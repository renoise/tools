--[[===============================================================================================
com.renoise.SliceMate.xrnx/main.lua
===============================================================================================]]--
--[[

This tool provides handy features for working with sample-slices 
.
#

]]

---------------------------------------------------------------------------------------------------
-- Required files
---------------------------------------------------------------------------------------------------

rns = nil
_trace_filters = nil
--_trace_filters = {".*"}

_clibroot = 'source/cLib/classes/'
_vlibroot = 'source/vLib/classes/'
_xlibroot = 'source/xLib/classes/'

require (_clibroot..'cLib')
require (_clibroot..'cDebug')
require (_clibroot..'cReflection')

require (_vlibroot..'vLib')
require (_vlibroot..'vDialog')
require (_vlibroot..'vTable')
require (_vlibroot..'vToggleButton')

require (_xlibroot..'xLine')
require (_xlibroot..'xTrack')
require (_xlibroot..'xSongPos')
require (_xlibroot..'xNotePos')
require (_xlibroot..'xInstrument')
require (_xlibroot..'xAutomation')
require (_xlibroot..'xNoteCapture')
require (_xlibroot..'xColumns')
require (_xlibroot..'xSample')

require ('source/SliceMate')
require ('source/SliceMate_UI')
require ('source/SliceMate_Prefs')

---------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------

local app
local prefs = SliceMate_Prefs()
renoise.tool().preferences = prefs

APP_DISPLAY_NAME = "SliceMate"

---------------------------------------------------------------------------------------------------
-- Methods
---------------------------------------------------------------------------------------------------

function show(show_dialog)
  rns = renoise.song()
  if not app then
    app = SliceMate{
      app_display_name = APP_DISPLAY_NAME,
      show_dialog = show_dialog
    }
  elseif (show_dialog) then
    app.ui:show()
  end
end

---------------------------------------------------------------------------------------------------
-- Menu entries & MIDI/Key mappings
---------------------------------------------------------------------------------------------------

-- show dialog 

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:SliceMate...",
  invoke = function() 
    show(true) 
  end
} 

renoise.tool():add_midi_mapping{
  name = "Tools:SliceMate:Show dialog... [Trigger]",
  invoke = function(msg)
    if msg:is_trigger() then
      show(true) 
    end
  end
}

renoise.tool():add_keybinding {
  name = "Global:SliceMate:Show dialog...",
  invoke = function(repeated)
    if (not repeated) then 
      show(true) 
    end
  end
}

-- detach sampler (midi only)

renoise.tool():add_midi_mapping{
  name = "Tools:SliceMate:Detach Sampler... [Trigger]",
  invoke = function(msg)
    if msg:is_trigger() then
      show() 
      app:detach_sampler()
    end
  end
}


-- insert slice 

renoise.tool():add_midi_mapping{
  name = "Tools:SliceMate:Insert Slice [Trigger]",
  invoke = function(msg)
    if msg:is_trigger() then
      show()
      app:insert_slice()
    end
  end
}

renoise.tool():add_keybinding {
  name = "Global:SliceMate:Insert Slice",
  invoke = function(repeated)
    if not repeated then 
      show()
      app:insert_slice()
    end
  end
}

-- previous note

renoise.tool():add_midi_mapping{
  name = "Tools:SliceMate:Previous Note [Trigger]",
  invoke = function(msg)
    if msg:is_trigger() then
      show()
      app:previous_note()
    end
  end
}

renoise.tool():add_keybinding {
  name = "Global:SliceMate:Previous Note",
  invoke = function(repeated)
    if not repeated then 
      show()
      app:previous_note()
    end
  end
}

-- next note

renoise.tool():add_midi_mapping{
  name = "Tools:SliceMate:Next Note [Trigger]",
  invoke = function(msg)
    if msg:is_trigger() then
      show()
      app:next_note()
    end
  end
}

renoise.tool():add_keybinding {
  name = "Global:SliceMate:Next Note",
  invoke = function(repeated)
    if not repeated then 
      show()
      app:next_note()
    end
  end
}

-- previous column

renoise.tool():add_midi_mapping{
  name = "Tools:SliceMate:Previous Column [Trigger]",
  invoke = function(msg)
    if msg:is_trigger() then
      show()
      app:previous_column()
    end
  end
}

renoise.tool():add_keybinding {
  name = "Global:SliceMate:Previous Column",
  invoke = function(repeated)
    if not repeated then 
      show()
      app:previous_column()
    end
  end
}

-- next column

renoise.tool():add_midi_mapping{
  name = "Tools:SliceMate:Next Column [Trigger]",
  invoke = function(msg)
    if msg:is_trigger() then
      show()
      app:next_column()
    end
  end
}

renoise.tool():add_keybinding {
  name = "Global:SliceMate:Next Column",
  invoke = function(repeated)
    if not repeated then 
      show()
      app:next_column()
    end
  end
}

---------------------------------------------------------------------------------------------------
-- notifications
---------------------------------------------------------------------------------------------------

renoise.tool().app_new_document_observable:add_notifier(function()
  if prefs.autostart.value then
    show(prefs.show_on_launch.value)
  end

end)
