--[[============================================================================
main.lua
============================================================================]]--

--------------------------------------------------------------------------------
-- variables 
--------------------------------------------------------------------------------

local app = nil
local waiting_to_show_dialog = true

rns = nil
prefs = nil
_trace_filters = nil
_trace_filters = {
  "^AutoMate*",
  "^xParameterAutomation*",
  "^xAudioDevice*",
}
          --[[
  "^xPatternSelection*",
  "^xSequencerSelection*",
  "xSongPos*"
}
]]

--------------------------------------------------------------------------------
-- includes 
--------------------------------------------------------------------------------

_clibroot = "classes/cLib/classes/"
require (_clibroot.."cLib")
require (_clibroot.."cDebug")
require (_clibroot.."cProcessSlicer")

_vlibroot = "classes/vLib/classes/"
require (_vlibroot..'vLib')
require (_vlibroot.."vTabs")
require (_vlibroot..'vTable')

_xlibroot = "classes/xLib/classes/"
require (_xlibroot.."xTrack")
require (_xlibroot.."xSongPos")
require (_xlibroot.."xAudioDevice")
require (_xlibroot.."xAudioDeviceAutomation")
require (_xlibroot.."xParameterAutomation")
require (_xlibroot.."xPatternSequencer")
require (_xlibroot.."xSequencerSelection")
require (_xlibroot.."xPatternSelection")
require (_xlibroot.."xBlockLoop")

require "classes/AutoMateUI"
require "classes/AutoMate"
require "classes/AutoMatePrefs"

--------------------------------------------------------------------------------
-- initialize
--------------------------------------------------------------------------------

prefs = AutoMatePrefs()
renoise.tool().preferences = prefs
app = AutoMate(prefs)

--------------------------------------------------------------------------------
-- notifications
--------------------------------------------------------------------------------

renoise.tool().app_idle_observable:add_notifier(function()
  --TRACE("main:app_idle_observable fired...")
  if app 
    and waiting_to_show_dialog 
    and prefs.autorun_enabled.value 
  then
    waiting_to_show_dialog = false
    app:show_dialog()
  end
  if app:is_running() then
    app._ui:on_idle()
  end

end)

renoise.tool().app_release_document_observable:add_notifier(function()
  TRACE("main:app_release_document_observable fired...")
  if app:is_running() then
    app:detach_from_song()
  end

end)

renoise.tool().app_new_document_observable:add_notifier(function()
  TRACE("main:app_new_document_observable fired...")

  rns = renoise.song()

  if app:is_running() then
    app:attach_to_song(true)
  end

end)

---------------------------------------------------------------------------------------------------
-- menu entries
---------------------------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:AutoMate",
  invoke = function() 
    app:show_dialog()
  end,
}

---------------------------------------------------------------------------------------------------
-- key/midi bindings
---------------------------------------------------------------------------------------------------

local route_to_status_bar = function(success,msg_or_err)
  --print("route_to_status_bar",success,msg_or_err)
  if msg_or_err then 
    renoise.app():show_status("Message from AutoMate: "..tostring(msg_or_err))
    LOG(msg_or_err) -- log in console
  end
end

-- helper method : create bindings for each scope
-- @param action (string, e.g. "Copy")
local add_scoped_bindings = function(action)

  local eval_action = function()
    if (action == "Cut") then 
      app:cut(route_to_status_bar)
    elseif (action == "Copy") then 
      app:copy(route_to_status_bar)
    elseif (action == "Paste") then 
      app:paste(route_to_status_bar)
    elseif (action == "Clear") then 
      app:clear()
    else 
      error("Unexpected action")
    end
  end

  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Automation (Selected Scope)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Automation (Whole Song)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_scope.value = xParameterAutomation.SCOPE.WHOLE_SONG
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Automation (Whole Pattern)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_scope.value = xParameterAutomation.SCOPE.WHOLE_PATTERN
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Automation (Selection In Sequence)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_scope.value = xParameterAutomation.SCOPE.SELECTION_IN_SEQUENCE
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Automation (Selection In Pattern)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_scope.value = xParameterAutomation.SCOPE.SELECTION_IN_PATTERN
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Device Automation (Selected Scope)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_tab.value = AutoMatePrefs.TAB_DEVICES
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Parameter Automation (Selected Scope)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_tab.value = AutoMatePrefs.TAB_PARAMETERS
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Device Automation (Whole Song)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_tab.value = AutoMatePrefs.TAB_DEVICES
        prefs.selected_scope.value = xParameterAutomation.SCOPE.WHOLE_SONG
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Parameter Automation (Whole Song)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_tab.value = AutoMatePrefs.TAB_PARAMETERS
        prefs.selected_scope.value = xParameterAutomation.SCOPE.WHOLE_SONG
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Device Automation (Whole Pattern)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_tab.value = AutoMatePrefs.TAB_DEVICES
        prefs.selected_scope.value = xParameterAutomation.SCOPE.WHOLE_PATTERN
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Parameter Automation (Whole Pattern)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_tab.value = AutoMatePrefs.TAB_PARAMETERS
        prefs.selected_scope.value = xParameterAutomation.SCOPE.WHOLE_PATTERN
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Device Automation (Selection In Sequence)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_tab.value = AutoMatePrefs.TAB_DEVICES
        prefs.selected_scope.value = xParameterAutomation.SCOPE.SELECTION_IN_SEQUENCE
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Parameter Automation (Selection In Sequence)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_tab.value = AutoMatePrefs.TAB_PARAMETERS
        prefs.selected_scope.value = xParameterAutomation.SCOPE.SELECTION_IN_SEQUENCE
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Device Automation (Selection In Pattern)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_tab.value = AutoMatePrefs.TAB_DEVICES
        prefs.selected_scope.value = xParameterAutomation.SCOPE.SELECTION_IN_PATTERN
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Parameter Automation (Selection In Pattern)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_tab.value = AutoMatePrefs.TAB_PARAMETERS
        prefs.selected_scope.value = xParameterAutomation.SCOPE.SELECTION_IN_PATTERN
        eval_action()
      end
    end
  }
end  

add_scoped_bindings("Cut")
add_scoped_bindings("Copy")
add_scoped_bindings("Paste")
add_scoped_bindings("Clear")

