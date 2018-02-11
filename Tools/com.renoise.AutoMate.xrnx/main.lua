--[[============================================================================
main.lua
============================================================================]]--

--------------------------------------------------------------------------------
-- variables 
--------------------------------------------------------------------------------

local app = nil
--local waiting_to_show_dialog = true

rns = nil
prefs = nil
_trace_filters = nil
--[[
_trace_filters = {
  "^AutoMate*",
  "^cPersistence*",
}
  "^xEnvelope*",
  "^xParameterAutomation*",
  "^xAudioDevice*",
  "^cReflection*",
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
require (_clibroot.."cNumber")
require (_clibroot.."cSandbox")
require (_clibroot.."cFilesystem")
require (_clibroot.."cPersistence")
require (_clibroot.."cProcessSlicer")

_vlibroot = "classes/vLib/classes/"
require (_vlibroot..'vLib')
require (_vlibroot.."vTabs")
require (_vlibroot..'vTable')
require (_vlibroot..'vDialog')

_xlibroot = "classes/xLib/classes/"
require (_xlibroot.."xLib")
require (_xlibroot.."xTrack")
require (_xlibroot.."xSongPos")
require (_xlibroot.."xAudioDevice")
require (_xlibroot.."xAudioDeviceAutomation")
require (_xlibroot.."xEnvelope")
require (_xlibroot.."xParameterAutomation")
require (_xlibroot.."xPatternSequencer")
require (_xlibroot.."xSequencerSelection")
require (_xlibroot.."xPatternSelection")
require (_xlibroot.."xBlockLoop")

require "classes/AutoMate"
require "classes/AutoMatePreset"
require "classes/AutoMatePresetManager"
require "classes/AutoMateClip"
require "classes/AutoMatePrefs"
require "classes/AutoMateUI"
require "classes/AutoMateSandbox"
require "classes/AutoMateSandboxArgument"
require "classes/AutoMateSandboxManager"
require "classes/AutoMateSandboxUI"
require "classes/AutoMateUserData"
require "classes/AutoMateLibrary"
require "classes/AutoMateLibraryUI"
require "classes/AutoMateGenerator"
require "classes/AutoMateGenerators"
--require "classes/AutoMateTransformer"
--require "classes/AutoMateTransformers"

--------------------------------------------------------------------------------
-- initialize
--------------------------------------------------------------------------------

prefs = AutoMatePrefs()
renoise.tool().preferences = prefs
app = AutoMate(prefs)

--------------------------------------------------------------------------------
-- notifications
--------------------------------------------------------------------------------

renoise.tool().app_release_document_observable:add_notifier(function()
  TRACE("main:app_release_document_observable fired...")

  if app.active then
    app:detach_from_song()
  end

end)

renoise.tool().app_new_document_observable:add_notifier(function()
  TRACE("main:app_new_document_observable fired...")

  rns = renoise.song()

  if app.active then
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
        prefs.selected_scope.value = AutoMate.SCOPE.WHOLE_SONG
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Automation (Whole Pattern)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_scope.value = AutoMate.SCOPE.WHOLE_PATTERN
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Automation (Selection In Sequence)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_scope.value = AutoMate.SCOPE.SELECTION_IN_SEQUENCE
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Automation (Selection In Pattern)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_scope.value = AutoMate.SCOPE.SELECTION_IN_PATTERN
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
        prefs.selected_scope.value = AutoMate.SCOPE.WHOLE_SONG
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Parameter Automation (Whole Song)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_tab.value = AutoMatePrefs.TAB_PARAMETERS
        prefs.selected_scope.value = AutoMate.SCOPE.WHOLE_SONG
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Device Automation (Whole Pattern)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_tab.value = AutoMatePrefs.TAB_DEVICES
        prefs.selected_scope.value = AutoMate.SCOPE.WHOLE_PATTERN
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Parameter Automation (Whole Pattern)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_tab.value = AutoMatePrefs.TAB_PARAMETERS
        prefs.selected_scope.value = AutoMate.SCOPE.WHOLE_PATTERN
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Device Automation (Selection In Sequence)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_tab.value = AutoMatePrefs.TAB_DEVICES
        prefs.selected_scope.value = AutoMate.SCOPE.SELECTION_IN_SEQUENCE
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Parameter Automation (Selection In Sequence)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_tab.value = AutoMatePrefs.TAB_PARAMETERS
        prefs.selected_scope.value = AutoMate.SCOPE.SELECTION_IN_SEQUENCE
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Device Automation (Selection In Pattern)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_tab.value = AutoMatePrefs.TAB_DEVICES
        prefs.selected_scope.value = AutoMate.SCOPE.SELECTION_IN_PATTERN
        eval_action()
      end
    end
  }
  renoise.tool():add_keybinding {
    name = ("Global:AutoMate:%s Parameter Automation (Selection In Pattern)"):format(action),
    invoke = function(repeated)
      if not repeated then 
        prefs.selected_tab.value = AutoMatePrefs.TAB_PARAMETERS
        prefs.selected_scope.value = AutoMate.SCOPE.SELECTION_IN_PATTERN
        eval_action()
      end
    end
  }
end  

add_scoped_bindings("Cut")
add_scoped_bindings("Copy")
add_scoped_bindings("Paste")
add_scoped_bindings("Clear")

