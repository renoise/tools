--[[===============================================================================================
com.renoise.ScaleMate.xrnx/main.lua
===============================================================================================]]--
--[[

ScaleMate tool registration

]]

--=================================================================================================
-- Require files (app+libraries)

-- where to find the cLib classes (required) 
_clibroot = 'source/cLib/classes/'
_xlibroot = 'source/xLib/classes/'

-- debug/trace filters can be configured here
-- (see cDebug for more details)
_trace_filters = nil  -- no tracing
--_trace_filters = {".*"} -- trace everything

require (_clibroot..'cLib')
require (_clibroot..'cDebug')
require (_clibroot..'cObservable')
require (_xlibroot..'xCursorPos')
require (_xlibroot..'xTrack')
require (_xlibroot..'xPatternPos')
require (_xlibroot..'xColumns')
require (_xlibroot..'xScale')
require (_xlibroot..'xMidiCommand')
require (_xlibroot..'xEffectColumn')
require (_xlibroot..'xLinePattern')

require ('source/ScaleMate')
require ('source/ScaleMate_UI')
require ('source/ScaleMate_Prefs')

---------------------------------------------------------------------------------------------------
-- Variables

rns = nil

local TOOL_NAME = "ScaleMate"
local MIDI_PREFIX = "Tools:"..TOOL_NAME..":"

local app = nil
local prefs = ScaleMate_Prefs()
renoise.tool().preferences = prefs

---------------------------------------------------------------------------------------------------
-- Menu entries & MIDI/Key mappings

-- toggle_message_value
local function toggle_message_value(message, value)
  if (message:is_trigger()) then
    return not value
  else
    return value
  end
end

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:"..TOOL_NAME.."...",
  invoke = function() 
    show() 
  end
} 
renoise.tool():add_keybinding {
  name = "Global:"..TOOL_NAME..":Show dialog...",
  invoke = function(repeated)
    if (not repeated) then 
      show() 
    end
  end
}

--== scale modes ==--

for k,v in ipairs(xScale.SCALES) do 
  renoise.tool():add_keybinding {
    name = "Global:"..TOOL_NAME..(":Set Scale Mode (%s)"):format(v.name),
    invoke = function(repeated)
      if (not repeated) then 
        app:set_scale(v.name)
      end
    end
  }
  midi_mapping = MIDI_PREFIX..("Set Scale Mode (%s) [Trigger]"):format(v.name)
  renoise.tool():add_midi_mapping{
    name = midi_mapping,
    invoke = function(message)     
      if app and message:is_trigger() then
        app:set_scale(v.name)
      end
    end
  }
end 

--== write-to-pattern ==--

renoise.tool():add_keybinding {
  name = "Global:"..TOOL_NAME..":Write to Pattern [Toggle]",
  invoke = function(repeated)
    if (not repeated) then 
      prefs.write_to_pattern.value = not prefs.write_to_pattern.value
    end
  end
}
midi_mapping = MIDI_PREFIX.."Write to Pattern [Toggle]"
renoise.tool():add_midi_mapping{
  name = midi_mapping,
  invoke = function(message)     
    if app then
      prefs.write_to_pattern.value = toggle_message_value(
        message, prefs.write_to_pattern.value)
    end
  end
}

--== clear commands ==--

renoise.tool():add_keybinding {
  name = "Global:"..TOOL_NAME..":Clear Commands (Track)",
  invoke = function(repeated)
    if (not repeated) then 
      app:clear_pattern_track()
    end
  end
}
midi_mapping = MIDI_PREFIX.."Clear Commands (Track) [Trigger]"
renoise.tool():add_midi_mapping{
  name = midi_mapping,
  invoke = function(message)     
    if app and message:is_trigger() then
      app:clear_pattern_track()
    end
  end
}

---------------------------------------------------------------------------------------------------
-- Create the application instance
-- will register keyboard shortcuts/midi mappings...

function create()
  rns = renoise.song()
  if not app then  
    app = ScaleMate{
      dialog_title = TOOL_NAME,
      midi_prefix = MIDI_PREFIX,
    }
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
  create() 
end)

--show()
