--[[===============================================================================================
com.renoise.xStream.xrnx (main.lua)
===============================================================================================]]--
--[[

  Create an instance of xStream

]]

---------------------------------------------------------------------------------------------------
-- global variables
---------------------------------------------------------------------------------------------------

rns = nil -- reference to renoise.song() 
_trace_filters = nil -- don't show traces in console
--_trace_filters = {".*"}
--_trace_filters = {"^xStreamBuffer*","^xStreamStack*","^xStreamProcess*"}
_trace_filters = {"^>>> xStreamBuffer:write_line*","^xStreamStackMember*"}

---------------------------------------------------------------------------------------------------
-- required files
---------------------------------------------------------------------------------------------------

_clibroot = 'source/cLib/classes/'
_vlibroot = 'source/vLib/classes/'
_xlibroot = 'source/xLib/classes/'

require (_clibroot..'cLib')
require (_clibroot..'cDebug')
require (_clibroot..'cDocument')
require (_clibroot..'cFilesystem')
require (_clibroot..'cObservable')
require (_clibroot..'cReflection')
require (_clibroot..'cParseXML')
require (_clibroot..'cSandbox')
require (_clibroot..'cTable')
require (_clibroot..'cColor')

require (_vlibroot..'vLib')
require (_vlibroot..'vDialog')
require (_vlibroot..'vDialogWizard')
require (_vlibroot..'vPrompt')
require (_vlibroot..'vTable')

require (_xlibroot..'xLib')
require (_xlibroot..'xLFO')
require (_xlibroot..'xAudioDevice')
require (_xlibroot..'xAutomation')
require (_xlibroot..'xBlockLoop')
require (_xlibroot..'xEffectColumn')
require (_xlibroot..'xLine')
require (_xlibroot..'xLineAutomation')
require (_xlibroot..'xLinePattern')
require (_xlibroot..'xMessage')
require (_xlibroot..'xMidiIO')
require (_xlibroot..'xMidiInput')
require (_xlibroot..'xMidiMessage')
require (_xlibroot..'xNoteColumn')
require (_xlibroot..'xOscClient')
require (_xlibroot..'xOscDevice')
require (_xlibroot..'xPhraseManager')
require (_xlibroot..'xPatternPos')
require (_xlibroot..'xPatternSequencer')
require (_xlibroot..'xPlayPos')
require (_xlibroot..'xScale')
require (_xlibroot..'xSongPos')
require (_xlibroot..'xSongSettings')
require (_xlibroot..'xStreamPos')
require (_xlibroot..'xStreamBuffer')
require (_xlibroot..'xTransport')
require (_xlibroot..'xVoiceManager')

require ('source/xStream')
require ('source/xStreamArg')
require ('source/xStreamArgs')
require ('source/xStreamArgsTab')
require ('source/xStreamFavorite')
require ('source/xStreamFavorites')
require ('source/xStreamModel')
require ('source/xStreamModels')
require ('source/xStreamModelPresets')
--require ('source/xStreamProcess')
require ('source/xStreamStack')
require ('source/xStreamStacks')
require ('source/xStreamStackMember')
require ('source/xStreamPrefs')
require ('source/xStreamUserData')
require ('source/xStreamUILuaEditor')
require ('source/xStreamUI')
require ('source/xStreamUIModelCreate')
require ('source/xStreamUICallbackCreate')
require ('source/xStreamUIGlobalToolbar')
require ('source/xStreamUIModelToolbar')
require ('source/xStreamUIStackToolbar')
require ('source/xStreamUIOptions')
require ('source/xStreamUIFavorites')
require ('source/xStreamUIPresetPanel')
require ('source/xStreamUIArgsPanel')
require ('source/xStreamUIArgsEditor')


---------------------------------------------------------------------------------------------------
-- local variables & initialization
---------------------------------------------------------------------------------------------------

local xstream
local TOOL_NAME = "xStream"
local MIDI_PREFIX = "Tools:"..TOOL_NAME..":"

renoise.tool().preferences = xStreamPrefs()

-- force all dialogs to have this name
vDialog.DEFAULT_DIALOG_TITLE = "xStream"

---------------------------------------------------------------------------------------------------
-- invoked by menu entries, autostart - 
-- first time around, the UI/class instances are created 

function show()
  rns = renoise.song()
  -- initialize classes (once)
  if not xstream then
    xstream = xStream{
      midi_prefix = MIDI_PREFIX,
      tool_name = TOOL_NAME,
    }
    xstream.stack.active_observable:add_notifier(function()
      TRACE("xStream main.lua - self.active_observable fired...")
      register_tool_menu()
    end)
  end
  xstream.ui:show()
end

---------------------------------------------------------------------------------------------------
-- tool menu entry

function register_tool_menu()
  local str_name = "Main Menu:Tools:"..TOOL_NAME
  local str_name_active = "Main Menu:Tools:"..TOOL_NAME.." (active)"
  if renoise.tool():has_menu_entry(str_name) then
    renoise.tool():remove_menu_entry(str_name)
  elseif renoise.tool():has_menu_entry(str_name_active) then
    renoise.tool():remove_menu_entry(str_name_active)
  end
  renoise.tool():add_menu_entry{
    name = (xstream and xstream.active) and str_name_active or str_name,
    invoke = function() 
      show() 
    end
  }
end

register_tool_menu()    

---------------------------------------------------------------------------------------------------
-- notifications
---------------------------------------------------------------------------------------------------

renoise.tool().app_new_document_observable:add_notifier(function()
  TRACE("xStream main app_new_document_observable fired...")
  if renoise.tool().preferences.autostart.value then
    show()
  end
end)

---------------------------------------------------------------------------------------------------
-- keyboard/midi mappings
--[[
  
local key_mapping, midi_mapping = nil,nil

--== "favorites" ==--

for i = 1,64 do
  midi_mapping = MIDI_PREFIX..("Favorites:Favorite #%.2d [Trigger]"):format(i)
  renoise.tool():add_midi_mapping{
    name = midi_mapping,
    invoke = function() 
      if xstream then
        xstream.favorites:trigger(i)
      end
    end
  }
  key_mapping = "Global:"..TOOL_NAME..":"..("Favorite #%.2d [Trigger]"):format(i)
  renoise.tool():add_keybinding{
    name = key_mapping,
    invoke = function(repeated) 
      if not repeated then
        if xstream then
          xstream.favorites:trigger(i)
        end
      end
    end
  }
end


--== "presets" ==--

for i = 1,16 do
  midi_mapping = MIDI_PREFIX..("Presets:Preset #%.2d [Trigger]"):format(i)
  renoise.tool():add_midi_mapping{
    name = midi_mapping,
    invoke = function() 
      if xstream then
        xstream.stack:set_selected_preset_index(i)
      end
    end
  }
  
  key_mapping = "Global:"..TOOL_NAME..":"..("Preset #%.2d [Trigger]"):format(i)
  renoise.tool():add_keybinding{
    name = key_mapping,
    invoke = function(repeated) 
      if not repeated then
        if xstream then
          xstream.stack:set_selected_preset_index(i)
        end
      end
    end
  }

  
end

midi_mapping = MIDI_PREFIX.."Presets:Select Next Preset [Trigger]"
renoise.tool():add_midi_mapping{
  name = midi_mapping,
  invoke = function() 
    if xstream then
      xstream.stack:select_next_preset()
    end
  end
}
key_mapping = "Global:"..TOOL_NAME..":".."Select Next Preset [Trigger]"
renoise.tool():add_keybinding{
  name = key_mapping,
  invoke = function(repeated) 
    if not repeated then
      if xstream then
        xstream.stack:select_next_preset()
      end
    end
  end
}

midi_mapping = MIDI_PREFIX.."Presets:Select Previous Preset [Trigger]"
renoise.tool():add_midi_mapping{
  name = midi_mapping,
  invoke = function() 
    if xstream then
      xstream.stack:select_previous_preset()
    end
  end
}
key_mapping = "Global:"..TOOL_NAME..":".."Select Previous Preset [Trigger]"
renoise.tool():add_keybinding{
  name = key_mapping,
  invoke = function(repeated) 
    if not repeated then
      if xstream then
        xstream.stack:select_previous_preset()
      end
    end
  end
}

--== "apply" ==--

midi_mapping = MIDI_PREFIX.."Apply to Track [Trigger]"
renoise.tool():add_midi_mapping{
  name = midi_mapping,
  invoke = function() 
    if xstream then
      xstream.stack:fill_track()
    end
  end
}
key_mapping = "Global:"..TOOL_NAME..":".."Apply to Track [Trigger]"
renoise.tool():add_keybinding{
  name = key_mapping,
  invoke = function(repeated) 
    if not repeated then
      if xstream then
        xstream.stack:fill_track()
      end
    end
  end
}

midi_mapping = MIDI_PREFIX.."Apply to Selection (Local) [Trigger]"
renoise.tool():add_midi_mapping{
  name = midi_mapping,
  invoke = function() 
    if xstream then
      xstream.stack:fill_selection(true)
    end
  end
}
key_mapping = "Global:"..TOOL_NAME..":".."Apply to Selection (Local) [Trigger]"
renoise.tool():add_keybinding{
  name = key_mapping,
  invoke = function(repeated) 
    if not repeated then
      if xstream then
        xstream.stack:fill_selection(true)
      end
    end
  end
}

midi_mapping = MIDI_PREFIX.."Apply to Selection [Trigger]"
renoise.tool():add_midi_mapping{
  name = midi_mapping,
  invoke = function() 
    if xstream then
      xstream.stack:fill_selection()
    end
  end
}
key_mapping = "Global:"..TOOL_NAME..":".."Apply to Selection [Trigger]"
renoise.tool():add_keybinding{
  name = key_mapping,
  invoke = function(repeated) 
    if not repeated then
      if xstream then
        xstream.stack:fill_selection()
      end
    end
  end
}

midi_mapping = MIDI_PREFIX.."Apply to Line (Local) [Trigger]"
renoise.tool():add_midi_mapping{
  name = midi_mapping,
  invoke = function() 
    if xstream then
      xstream.stack:fill_line(true)
    end
  end
}
key_mapping = "Global:"..TOOL_NAME..":".."Apply to Line (Local) [Trigger]"
renoise.tool():add_keybinding{
  name = key_mapping,
  invoke = function(repeated) 
    if not repeated then
      if xstream then
        xstream.stack:fill_line(true)
      end
    end
  end
}

midi_mapping = MIDI_PREFIX.."Apply to Line [Trigger]"
renoise.tool():add_midi_mapping{
  name = midi_mapping,
  invoke = function() 
    if xstream then
      xstream.stack:fill_line()
    end
  end
}
key_mapping = "Global:"..TOOL_NAME..":".."Apply to Line [Trigger]"
renoise.tool():add_keybinding{
  name = key_mapping,
  invoke = function(repeated) 
    if not repeated then
      if xstream then
        xstream.stack:fill_line()
      end
    end
  end
}
]]
