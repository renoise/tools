--[[============================================================================
com.renoise.VoiceRunner.xrnx/main.lua
============================================================================]]--
--[[

A tool for sorting notes in pattern-tracks 

.
#

This file is mostly registering key-bindings and midi mappings.

@See: VR (main application)

]]

--------------------------------------------------------------------------------
-- Required files
--------------------------------------------------------------------------------

rns = nil
_trace_filters = nil
--_trace_filters = {".*"}

_clibroot = 'source/cLib/classes/'
_xlibroot = 'source/xLib/classes/'
_vlibroot = 'source/vLib/classes/'

require (_clibroot..'cLib')
require (_clibroot..'cDebug')
require (_clibroot..'cFilesystem')
require (_clibroot..'cProcessSlicer')
require (_clibroot..'cColor')

require (_xlibroot..'xLib')
require (_xlibroot..'xColumns') 
require (_xlibroot..'xEffectColumn') 
require (_xlibroot..'xInstrument')
require (_xlibroot..'xLinePattern')
require (_xlibroot..'xMidiCommand')
require (_xlibroot..'xNoteColumn') 
require (_xlibroot..'xMatrixSelection')
require (_xlibroot..'xPatternSelection')
require (_xlibroot..'xPhraseSelection')
require (_xlibroot..'xTrack') 
require (_xlibroot..'xVoiceRunner') 
require (_xlibroot..'xVoiceSorter') 

require (_vlibroot..'vLib')
require (_vlibroot..'vDialog')

require ('source/VR')
require ('source/VR_UI')
require ('source/VR_Prefs')
require ('source/VR_Template')

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local voicerunner
local prefs = VR_Prefs()
renoise.tool().preferences = prefs

APP_DISPLAY_NAME = "VoiceRunner"



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

-- sort/merge ----------------------------

renoise.tool():add_keybinding {
  name = "Global:"..APP_DISPLAY_NAME..":Sort Notes (auto)",
  invoke = function(repeated)
    if (not repeated) then 
      voicerunner:do_sort() 
    end
  end
}
renoise.tool():add_keybinding {
  name = "Global:"..APP_DISPLAY_NAME..":Merge Notes (auto)",
  invoke = function(repeated)
    if (not repeated) then 
      voicerunner:do_merge() 
    end
  end
}
renoise.tool():add_midi_mapping {
  name = VR.MIDI_MAPPING.SORT_NOTES,
  invoke = function(msg)
    voicerunner:do_sort() 
  end
}
renoise.tool():add_midi_mapping {
  name = VR.MIDI_MAPPING.MERGE_NOTES,
  invoke = function(msg)
    voicerunner:do_merge() 
  end
}

-- menu entries: pattern editor

renoise.tool():add_menu_entry {
  name = "Pattern Editor:"..APP_DISPLAY_NAME..":Sort Notes - "..VR.SCOPES[VR.SCOPE.SELECTION_IN_PATTERN],
  invoke = function() 
    voicerunner:do_sort(VR.SCOPE.SELECTION_IN_PATTERN) 
  end
} 
renoise.tool():add_menu_entry {
  name = "Pattern Editor:"..APP_DISPLAY_NAME..":Sort Notes - "..VR.SCOPES[VR.SCOPE.TRACK_IN_PATTERN],
  invoke = function() 
    voicerunner:do_sort(VR.SCOPE.TRACK_IN_PATTERN) 
  end
} 
renoise.tool():add_menu_entry {
  name = "Pattern Editor:"..APP_DISPLAY_NAME..":Sort Notes - "..VR.SCOPES[VR.SCOPE.GROUP_IN_PATTERN],
  invoke = function() 
    voicerunner:do_sort(VR.SCOPE.GROUP_IN_PATTERN) 
  end
} 
renoise.tool():add_menu_entry {
  name = "Pattern Editor:"..APP_DISPLAY_NAME..":Sort Notes - "..VR.SCOPES[VR.SCOPE.WHOLE_PATTERN],
  invoke = function() 
    voicerunner:do_sort(VR.SCOPE.WHOLE_PATTERN) 
  end
} 
renoise.tool():add_menu_entry {
  name = "--Pattern Editor:"..APP_DISPLAY_NAME..":Merge Notes - "..VR.SCOPES[VR.SCOPE.SELECTION_IN_PATTERN],
  invoke = function() 
    voicerunner:do_merge(VR.SCOPE.SELECTION_IN_PATTERN) 
  end
} 
renoise.tool():add_menu_entry {
  name = "Pattern Editor:"..APP_DISPLAY_NAME..":Merge Notes - "..VR.SCOPES[VR.SCOPE.TRACK_IN_PATTERN],
  invoke = function() 
    voicerunner:do_merge(VR.SCOPE.TRACK_IN_PATTERN) 
  end
} 
renoise.tool():add_menu_entry {
  name = "Pattern Editor:"..APP_DISPLAY_NAME..":Merge Notes - "..VR.SCOPES[VR.SCOPE.GROUP_IN_PATTERN],
  invoke = function() 
    voicerunner:do_merge(VR.SCOPE.GROUP_IN_PATTERN) 
  end
} 
renoise.tool():add_menu_entry {
  name = "Pattern Editor:"..APP_DISPLAY_NAME..":Merge Notes - "..VR.SCOPES[VR.SCOPE.WHOLE_PATTERN],
  invoke = function() 
    voicerunner:do_merge(VR.SCOPE.WHOLE_PATTERN) 
  end
} 
renoise.tool():add_menu_entry {
  name = "--Pattern Editor:"..APP_DISPLAY_NAME..":Adjust settings...",
  invoke = function() 
    show() 
  end
} 

-- menu entries: phrase editor 

renoise.tool():add_menu_entry {
  name = "Phrase Editor:"..APP_DISPLAY_NAME..":Sort Notes - "..VR.SCOPES[VR.SCOPE.SELECTION_IN_PHRASE],
  invoke = function() 
    voicerunner:do_sort(VR.SCOPE.SELECTION_IN_PHRASE) 
  end
} 
renoise.tool():add_menu_entry {
  name = "Phrase Editor:"..APP_DISPLAY_NAME..":Sort Notes - "..VR.SCOPES[VR.SCOPE.WHOLE_PHRASE],
  invoke = function() 
    voicerunner:do_sort(VR.SCOPE.WHOLE_PHRASE) 
  end
} 
renoise.tool():add_menu_entry {
  name = "--Phrase Editor:"..APP_DISPLAY_NAME..":Merge Notes - "..VR.SCOPES[VR.SCOPE.SELECTION_IN_PHRASE],
  invoke = function() 
    voicerunner:do_merge(VR.SCOPE.SELECTION_IN_PHRASE) 
  end
} 
renoise.tool():add_menu_entry {
  name = "Phrase Editor:"..APP_DISPLAY_NAME..":Merge Notes - "..VR.SCOPES[VR.SCOPE.WHOLE_PHRASE],
  invoke = function() 
    voicerunner:do_merge(VR.SCOPE.WHOLE_PHRASE) 
  end
} 
renoise.tool():add_menu_entry {
  name = "--Phrase Editor:"..APP_DISPLAY_NAME..":Adjust settings...",
  invoke = function() 
    show() 
  end
} 

-- keybindings: pattern editor

renoise.tool():add_keybinding {
  name = "Pattern Editor:Selection:Sort Notes - "..VR.SCOPES[VR.SCOPE.SELECTION_IN_PATTERN].." ("..APP_DISPLAY_NAME..")",
  invoke = function(repeated)
    if (not repeated) then 
      voicerunner:do_sort(VR.SCOPE.SELECTION_IN_PATTERN) 
    end
  end
}
renoise.tool():add_midi_mapping {
  name = VR.MIDI_MAPPING.SORT_SELECTION_IN_PATTERN,
  invoke = function(msg)
    voicerunner:do_sort(VR.SCOPE.SELECTION_IN_PATTERN) 
  end
}
renoise.tool():add_keybinding {
  name = "Pattern Editor:Selection:Merge Notes - "..VR.SCOPES[VR.SCOPE.SELECTION_IN_PATTERN].." ("..APP_DISPLAY_NAME..")",
  invoke = function(repeated)
    if (not repeated) then 
      voicerunner:do_merge(VR.SCOPE.SELECTION_IN_PATTERN) 
    end
  end
}
renoise.tool():add_midi_mapping {
  name = VR.MIDI_MAPPING.MERGE_SELECTION_IN_PATTERN,
  invoke = function(msg)
    voicerunner:do_merge(VR.SCOPE.SELECTION_IN_PATTERN) 
  end
}

renoise.tool():add_keybinding {
  name = "Phrase Editor:Selection:Sort Notes - "..VR.SCOPES[VR.SCOPE.SELECTION_IN_PHRASE].." ("..APP_DISPLAY_NAME..")",
  invoke = function(repeated)
    if (not repeated) then 
      voicerunner:do_sort(VR.SCOPE.SELECTION_IN_PHRASE) 
    end
  end
}
renoise.tool():add_midi_mapping {
  name = VR.MIDI_MAPPING.SORT_SELECTION_IN_PHRASE,
  invoke = function(msg)
    voicerunner:do_sort(VR.SCOPE.SELECTION_IN_PHRASE) 
  end
}

renoise.tool():add_keybinding {
  name = "Phrase Editor:Selection:Merge Notes - "..VR.SCOPES[VR.SCOPE.SELECTION_IN_PHRASE].." ("..APP_DISPLAY_NAME..")",
  invoke = function(repeated)
    if (not repeated) then 
      voicerunner:do_merge(VR.SCOPE.SELECTION_IN_PHRASE) 
    end
  end
}
renoise.tool():add_midi_mapping {
  name = VR.MIDI_MAPPING.MERGE_SELECTION_IN_PHRASE,
  invoke = function(msg)
    voicerunner:do_merge(VR.SCOPE.SELECTION_IN_PHRASE) 
  end
}

-- TRACK_IN_PATTERN

renoise.tool():add_keybinding {
  name = "Pattern Editor:Selection:Sort Notes - "..VR.SCOPES[VR.SCOPE.TRACK_IN_PATTERN].." ("..APP_DISPLAY_NAME..")",
  invoke = function(repeated)
    if (not repeated) then 
      voicerunner:do_sort(VR.SCOPE.TRACK_IN_PATTERN) 
    end
  end
}
renoise.tool():add_midi_mapping {
  name = VR.MIDI_MAPPING.SORT_TRACK_IN_PATTERN,
  invoke = function(msg)
    voicerunner:do_sort(VR.SCOPE.TRACK_IN_PATTERN) 
  end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Selection:Merge Notes - "..VR.SCOPES[VR.SCOPE.TRACK_IN_PATTERN].." ("..APP_DISPLAY_NAME..")",
  invoke = function(repeated)
    if (not repeated) then 
      voicerunner:do_merge(VR.SCOPE.TRACK_IN_PATTERN) 
    end
  end
}
renoise.tool():add_midi_mapping {
  name = VR.MIDI_MAPPING.MERGE_TRACK_IN_PATTERN,
  invoke = function(msg)
    voicerunner:do_merge(VR.SCOPE.TRACK_IN_PATTERN) 
  end
}

-- GROUP_IN_PATTERN

renoise.tool():add_keybinding {
  name = "Pattern Editor:Selection:Sort Notes - "..VR.SCOPES[VR.SCOPE.GROUP_IN_PATTERN].." ("..APP_DISPLAY_NAME..")",
  invoke = function(repeated)
    if (not repeated) then 
      voicerunner:do_sort(VR.SCOPE.GROUP_IN_PATTERN) 
    end
  end
}
renoise.tool():add_midi_mapping {
  name = VR.MIDI_MAPPING.SORT_GROUP_IN_PATTERN,
  invoke = function(msg)
    voicerunner:do_sort(VR.SCOPE.GROUP_IN_PATTERN) 
  end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Selection:Merge Notes - "..VR.SCOPES[VR.SCOPE.GROUP_IN_PATTERN].." ("..APP_DISPLAY_NAME..")",
  invoke = function(repeated)
    if (not repeated) then 
      voicerunner:do_merge(VR.SCOPE.GROUP_IN_PATTERN) 
    end
  end
}
renoise.tool():add_midi_mapping {
  name = VR.MIDI_MAPPING.MERGE_GROUP_IN_PATTERN,
  invoke = function(msg)
    voicerunner:do_merge(VR.SCOPE.GROUP_IN_PATTERN) 
  end
}

-- WHOLE_PATTERN

renoise.tool():add_keybinding {
  name = "Pattern Editor:Selection:Sort Notes - "..VR.SCOPES[VR.SCOPE.WHOLE_PATTERN].." ("..APP_DISPLAY_NAME..")",
  invoke = function(repeated)
    if (not repeated) then 
      voicerunner:do_sort(VR.SCOPE.WHOLE_PATTERN) 
    end
  end
}
renoise.tool():add_midi_mapping {
  name = VR.MIDI_MAPPING.SORT_WHOLE_PATTERN,
  invoke = function(msg)
    voicerunner:do_sort(VR.SCOPE.WHOLE_PATTERN) 
  end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Selection:Merge Notes - "..VR.SCOPES[VR.SCOPE.WHOLE_PATTERN].." ("..APP_DISPLAY_NAME..")",
  invoke = function(repeated)
    if (not repeated) then 
      voicerunner:do_merge(VR.SCOPE.WHOLE_PATTERN) 
    end
  end
}
renoise.tool():add_midi_mapping {
  name = VR.MIDI_MAPPING.MERGE_WHOLE_PATTERN,
  invoke = function(msg)
    voicerunner:do_merge(VR.SCOPE.WHOLE_PATTERN) 
  end
}

-- WHOLE_PHRASE

renoise.tool():add_keybinding {
  name = "Phrase Editor:Selection:Sort Notes - "..VR.SCOPES[VR.SCOPE.WHOLE_PHRASE].." ("..APP_DISPLAY_NAME..")",
  invoke = function(repeated)
    if (not repeated) then 
      voicerunner:do_sort(VR.SCOPE.WHOLE_PHRASE) 
    end
  end
}
renoise.tool():add_midi_mapping {
  name = VR.MIDI_MAPPING.SORT_WHOLE_PHRASE,
  invoke = function(msg)
    voicerunner:do_sort(VR.SCOPE.WHOLE_PHRASE) 
  end
}

renoise.tool():add_keybinding {
  name = "Phrase Editor:Selection:Merge Notes - "..VR.SCOPES[VR.SCOPE.WHOLE_PHRASE].." ("..APP_DISPLAY_NAME..")",
  invoke = function(repeated)
    if (not repeated) then 
      voicerunner:do_merge(VR.SCOPE.WHOLE_PHRASE) 
    end
  end
}
renoise.tool():add_midi_mapping {
  name = VR.MIDI_MAPPING.MERGE_WHOLE_PHRASE,
  invoke = function(msg)
    voicerunner:do_merge(VR.SCOPE.WHOLE_PHRASE) 
  end
}

-- selection/navigation ---------------

renoise.tool():add_keybinding {
  name = "Pattern Editor:Selection:Select voice-run at cursor position ("..APP_DISPLAY_NAME..")",
  invoke = function(repeated)
    if (not repeated) then 
      voicerunner:select_voice_run() 
    end
  end
}
renoise.tool():add_midi_mapping {
  name = VR.MIDI_MAPPING.SELECT_RUN,
  invoke = function(msg)
    voicerunner:select_voice_run() 
  end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Navigation:Jump to next voice-run in pattern ("..APP_DISPLAY_NAME..")",
  invoke = function(repeated)
    voicerunner:select_next_voice_run() 
  end
}
renoise.tool():add_midi_mapping {
  name = VR.MIDI_MAPPING.SELECT_NEXT_RUN,
  invoke = function(msg)
    voicerunner:select_next_voice_run() 
  end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Navigation:Jump to previous voice-run ("..APP_DISPLAY_NAME..")",
  invoke = function(repeated)
    voicerunner:select_previous_voice_run() 
  end
}
renoise.tool():add_midi_mapping {
  name = VR.MIDI_MAPPING.SELECT_PREV_RUN,
  invoke = function(msg)
    voicerunner:select_previous_voice_run() 
  end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Navigation:Jump to next note-column ("..APP_DISPLAY_NAME..")",
  invoke = function(repeated)
    voicerunner:select_next_note_column()
  end
}
renoise.tool():add_midi_mapping {
  name = VR.MIDI_MAPPING.SELECT_NEXT_NOTECOL,
  invoke = function(msg)
    voicerunner:select_next_note_column()
  end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Navigation:Jump to previous note-column ("..APP_DISPLAY_NAME..")",
  invoke = function(repeated)
    voicerunner:select_previous_note_column()
  end
}
renoise.tool():add_midi_mapping {
  name = VR.MIDI_MAPPING.SELECT_PREV_NOTECOL,
  invoke = function(msg)
    voicerunner:select_previous_note_column()
  end
}

--------------------------------------------------------------------------------
-- invoked by menu entries, autostart - 
-- first time around, the UI/class instances are created 

function show()

  rns = renoise.song()
  if not voicerunner then
    voicerunner = VR{
      app_display_name = APP_DISPLAY_NAME,
    }
  end

  voicerunner.ui:show()

end


--------------------------------------------------------------------------------
-- notifications
--------------------------------------------------------------------------------

renoise.tool().app_new_document_observable:add_notifier(function()
  TRACE("*** app_new_document_observable fired...")

  if prefs.autostart.value then
    show()
  end

end)
