--[[============================================================================
com.renoise.PhraseMate.xrnx/main.lua
============================================================================]]--
--[[

PhraseMate aims to make it more convenient to work with phrases 
.
#

## TODO
* When replacing with phrase, detect when/if original notes are released and insert note-off 
* Detect duplicate phrases (xPhraseManager.find_duplicates). Make optional
* Allow writing phrases into master/group/send tracks
  By then, 'clear_foreign_commands' should be optional (allow for 'pure' fx phrases)
* Option: enable loop on phrases (default = on)

]]

--------------------------------------------------------------------------------
-- required files
--------------------------------------------------------------------------------

rns = nil
_xlibroot = 'source/xLib/classes/'
_trace_filters = nil
--_trace_filters = {".*"}

require (_xlibroot..'xLib')
require (_xlibroot.."xPhrase")
require (_xlibroot..'xDebug')
require (_xlibroot..'xInstrument')
require (_xlibroot..'xNoteColumn') 
require (_xlibroot..'xPhraseManager')
require (_xlibroot..'xSelection')

--------------------------------------------------------------------------------
-- static variables
--------------------------------------------------------------------------------

local UI_TABS = {
  INPUT = 1,
  OUTPUT = 2,
  REALTIME = 3,
}

local INPUT_SCOPES = {
  "Selection in Pattern",
  "Selection in Matrix",
  "Track in Pattern",
  "Track in Song",
}
local INPUT_SCOPE = {
  SELECTION_IN_PATTERN = 1,
  SELECTION_IN_MATRIX = 2,
  TRACK_IN_PATTERN = 3,
  TRACK_IN_SONG = 4,
}

local SOURCE_INSTR = {
  CAPTURE_ONCE = 1,
  CAPTURE_ALL = 2,
  SELECTED = 3,
  CUSTOM = 4,
}

local TARGET_INSTR = {
  SAME = 1,
  NEW = 2,
  CUSTOM = 3,
}

local PLAYBACK_MODES = {"Off","Prg","Map"}
local PLAYBACK_MODE = {
  PHRASES_OFF = 1,
  PHRASES_PLAY_SELECTIVE = 2,
  PHRASES_PLAY_KEYMAP = 3,
}

local MIDI_MAPPING = {
  PREV_PHRASE_IN_INSTR = "Global:PhraseMate:Select Previous Phrase in Instrument [Trigger]",
  NEXT_PHRASE_IN_INSTR = "Global:PhraseMate:Select Next Phrase in Instrument [Trigger]",
  SET_PLAYBACK_MODE = "Global:PhraseMate:Select Playback Mode [Set]",
}

local UI_SOURCE_ITEMS = {"➜ Autocapture","➜ Capture All Instr.","➜ Selected Instrument"}
local UI_TARGET_ITEMS = {"➜ Same Instrument","➜ New Instrument(s)"}

local UI_WIDTH = 186
local UI_KEYMAP_LABEL_W = 90
local UI_INSTR_LABEL_W = 45
local UI_INSTR_POPUP_W = 125
local UI_BUTTON_LG_H = 22

--------------------------------------------------------------------------------
-- 'class'
--------------------------------------------------------------------------------

--- int, can change during collection when auto-capturing
local source_instr_idx = nil

--- int, the destination for our collected phrases
local target_instr_idx = nil

--- bool, true when we have successfully determined the source instr.
local done_with_capture = false

--- (table) source -> target mappings, when creating new instrument(s)
local source_target_map = {}

--- keep track of 'ghost notes' when reading note columns
local ghost_columns = {}

--- table<[instr_idx]{
--  {
--    sequence_index = int,
--    phrase_index = int,
--  }
local collected_phrases = {}

-- realtime
local modified_lines = {}
local suppress_line_notifier = false
local realtime_update_requested = false

--------------------------------------------------------------------------------
-- helper functions
--------------------------------------------------------------------------------

function invoke_task(rslt,err)
  if (rslt == false and err) then
    renoise.app():show_status(err)
  end
end

--------------------------------------------------------------------------------
-- preferences
--------------------------------------------------------------------------------

local options = renoise.Document.create("ScriptingToolPreferences"){}
options:add_property("active_tab_index",renoise.Document.ObservableNumber(UI_TABS.INPUT))
options:add_property("output_show_collection_report", renoise.Document.ObservableBoolean(true))
options:add_property("anchor_to_selection", renoise.Document.ObservableBoolean(true))
options:add_property("cont_paste", renoise.Document.ObservableBoolean(true))
options:add_property("skip_muted", renoise.Document.ObservableBoolean(true))
options:add_property("expand_columns", renoise.Document.ObservableBoolean(true))
options:add_property("expand_subcolumns", renoise.Document.ObservableBoolean(true))
options:add_property("mix_paste", renoise.Document.ObservableBoolean(false))
options:add_property("input_scope", renoise.Document.ObservableNumber(INPUT_SCOPE.SELECTION_IN_PATTERN))
--options:add_property("output_source_instrument", renoise.Document.ObservableNumber(1))
--options:add_property("output_target_instrument", renoise.Document.ObservableNumber(1))
--options:add_property("output_skip_duplicates", renoise.Document.ObservableBoolean(true))
--options:add_property("input_collect_everything", renoise.Document.ObservableBoolean(false))
options:add_property("input_replace_collected", renoise.Document.ObservableBoolean(false))
options:add_property("input_source_instr", renoise.Document.ObservableNumber(SOURCE_INSTR.CAPTURE_ONCE))
options:add_property("input_target_instr", renoise.Document.ObservableNumber(TARGET_INSTR.NEW))
options:add_property("input_create_keymappings", renoise.Document.ObservableBoolean(true))
options:add_property("input_keymap_range", renoise.Document.ObservableNumber(1))
options:add_property("input_keymap_offset", renoise.Document.ObservableNumber(0))
options:add_property("zxx_mode", renoise.Document.ObservableBoolean(false))

renoise.tool().preferences = options

options.input_source_instr:add_notifier(function(idx)
  print(options.input_source_instr.value)
end)

--------------------------------------------------------------------------------
-- user interface
--------------------------------------------------------------------------------

local vb,dialog,dialog_content

function show_preferences()

  rns = renoise.song()

  if dialog and dialog.visible then
    dialog:show()
  else
    vb = renoise.ViewBuilder()
    dialog_content = vb:column{
      margin = 6,
      spacing = 4,
      vb:column{
        width = "100%",
        vb:column{
          width = "100%",
          style = "group",
          margin = 3,
          vb:horizontal_aligner{
            mode = "justify",
            vb:text{              
              id = "ui_realtime_phrase_name_header",
              text = "Current Phrase",
              font = "bold",
            },
            vb:button{
              text = "?",
              tooltip = "Visit github for documentation and source code",
              notifier = function()
                renoise.app():open_url("https://github.com/renoise/xrnx/tree/master/Tools/com.renoise.PhraseMate.xrnx")
              end
            }
          },
          vb:text{              
            id = "ui_realtime_phrase_name",
            text = "",
          },
          vb:row{
            vb:button{
              id = "ui_realtime_prev",
              text = "Prev",
              tooltip = "Select the previous phrase",
              width = 36,
              height = UI_BUTTON_LG_H,
              midi_mapping = MIDI_MAPPING.PREV_PHRASE_IN_INSTR,
              notifier = function()
                invoke_task(xPhraseManager.select_previous_phrase())
              end
            },
            vb:button{
              id = "ui_realtime_next",
              text = "Next",
              tooltip = "Select the next phrase",
              width = 36,
              height = UI_BUTTON_LG_H,
              midi_mapping = MIDI_MAPPING.NEXT_PHRASE_IN_INSTR,
              notifier = function()
                invoke_task(xPhraseManager.select_next_phrase())
              end
            },
            vb:space{
              width = 6,
            },
            vb:switch{
              id = "ui_realtime_playback_mode",
              width = 100,
              tooltip = "Choose the phrase playback-mode",
              midi_mapping = MIDI_MAPPING.SET_PLAYBACK_MODE,
              height = UI_BUTTON_LG_H,
              items = PLAYBACK_MODES,
              notifier = function(idx)
                rns.selected_instrument.phrase_playback_mode = idx
              end
            },
          },
        },

      },
      vb:switch{
        width = UI_WIDTH,
        items = {"Input","Output","Realtime"},
        bind = options.active_tab_index,
        notifier = function()
          ui_show_tab()
        end
      },
      vb:column{
        id = "tab_input",
        visible = false,
        width = "100%",
        --margin = 6,
        spacing = 3,
        vb:row{
          margin = 6,
          style = "group",
          width = "100%",
          vb:chooser{
            width = "100%",
            items = INPUT_SCOPES,
            bind = options.input_scope,
          },
        },
        vb:column{
          style = "group",
          margin = 6,
          width = "100%",
          --[[
          vb:row{
            vb:checkbox{
              bind = options.output_skip_duplicates,
            },
            vb:text{
              text = "Skip duplicate phrases"
            },
          },
          ]]
          vb:row{
            vb:text{
              text = "Source",
              width = UI_INSTR_LABEL_W,
            },
            vb:popup{
              id = "ui_source_popup",
              items = get_source_instr(),
              value = options.input_source_instr.value,
              width = UI_INSTR_POPUP_W,
              notifier = function(idx)
                if (idx > #UI_SOURCE_ITEMS) then
                  options.input_source_instr.value = #UI_SOURCE_ITEMS+1
                else
                  options.input_source_instr.value = idx
                end
              end
            },
          },
          vb:row{
            vb:text{
              text = "Target",
              width = UI_INSTR_LABEL_W,
            },
            vb:popup{
              id = "ui_target_popup",
              items = get_target_instr(),
              value = options.input_target_instr.value,
              width = UI_INSTR_POPUP_W,
              notifier = function(idx)
                if (idx > #UI_TARGET_ITEMS) then
                  options.input_target_instr.value = #UI_TARGET_ITEMS+1
                else
                  options.input_target_instr.value = idx
                end
              end
            },
          },
        },
        vb:column{
          style = "group",
          margin = 6,
          width = "100%",
          --[[
          vb:row{
            tooltip = "Try to collect as much data as possible, including notes from other instruments",
            vb:checkbox{
              bind = options.input_collect_everything,
            },
            vb:text{
              text = "Collect everything"
            },
          },
          ]]
          vb:row{
            tooltip = "After collecting notes, insert a phrase trigger-note in their place",
            vb:checkbox{
              bind = options.input_replace_collected,
            },
            vb:text{
              text = "Replace notes with phrase"
            },
          },
          vb:row{
            tooltip = "Choose whether to create keymappings for the new phrases",
            vb:checkbox{
              bind = options.input_create_keymappings,
            },
            vb:text{
              text = "Create keymap"
            },
          },
          vb:column{
            id = "keymap_options",
            vb:row{
              tooltip = "Choose how many semitones each mapping should span",
              vb:space{
                width = 20,
              },
              vb:text{
                text = "Semitone range",
                width = UI_KEYMAP_LABEL_W,
              },
              vb:valuebox{
                id = "ui_input_keymap_range",
                min = 1,
                max = 119,
                bind = options.input_keymap_range,
              }
            },
            vb:row{
              tooltip = "Choose starting note for the new mappings",
              vb:space{
                width = 20,
              },
              vb:text{
                text = "Starting offset",
                width = UI_KEYMAP_LABEL_W,
              },
              vb:valuebox{
                id = "ui_input_keymap_offset",
                min = 0,
                max = 119,
                bind = options.input_keymap_offset,
                tostring = function(val)
                  return xNoteColumn.note_value_to_string(math.floor(val))
                end,
                tonumber = function(str)
                  return xNoteColumn.note_string_to_value(str)
                end,
              },
            },
          },
        },
        vb:button{
          text = "Collect phrases",
          width = "100%",
          height = 22,
          notifier = function()
            invoke_task(collect_phrases())
          end
        },
      },
      vb:column{ 
        id = "tab_output",
        visible = false,
        width = "100%",
        spacing = 3,
        vb:column{ 
          style = "group",
          margin = 3,
          width = "100%",
          vb:row{
            tooltip = "When writing to a selection, this option determines if the output is written relative to the top of the selection, or the top of the pattern",
            vb:checkbox{
              bind = options.anchor_to_selection
            },
            vb:text{
              text = "Anchor to selection",
            }
          },
          vb:row{
            tooltip = "When source phrase is shorter than pattern/selection, repeat in order to fill",
            vb:checkbox{
              bind = options.cont_paste
            },
            vb:text{
              text = "Continuous paste",
            }
          },
          vb:row{
            tooltip = "Skip note-columns when they are muted in the phrase (and clear pattern, unless mix-paste is enabled)",
            vb:checkbox{
              bind = options.skip_muted
            },
            vb:text{
              text = "Skip muted columns",
            }
          },
          vb:row{
            tooltip = "Show additional note columns if required by source phrase",
            vb:checkbox{
              bind = options.expand_columns
            },
            vb:text{
              text = "Expand columns",
            }
          },
          vb:row{
            tooltip = "Show sub-columns (VOL/PAN/DLY/FX) if required by source phrase",
            vb:checkbox{
              bind = options.expand_subcolumns
            },
            vb:text{
              text = "Expand sub-columns",
            }
          },
          vb:row{
            tooltip = "Attempt to keep existing content when producing output (works the same as Mix-Paste in the advanced edit panel)",
            vb:checkbox{
              bind = options.mix_paste
            },
            vb:text{
              text = "Mix-Paste",
            }
          },
        },
        vb:column{
          width = "100%",
          vb:button{
            text = "Write to selection",
            width = "100%",
            height = 22,
            notifier = function()
              invoke_task(apply_phrase_to_selection())
            end
          },
          vb:button{
            text = "Write to track",
            width = "100%",
            height = 22,
            notifier = function()
              invoke_task(apply_phrase_to_track())
            end
          },
        },
      },
      vb:column{ 
        id = "tab_realtime",
        visible = false,
        width = "100%",
        spacing = 3,
        vb:column{
          style = "group",
          margin = 3,
          width = "100%",
          tooltip = "Insert Zxx commands into the first available effect column when the following conditions are met:"
                  .."\n* Phrase is set to program playback"
                  .."\n* Edit-mode is enabled in Renoise",
          vb:row{
            vb:checkbox{
              bind = options.zxx_mode
            },
            vb:text{
              text = "Monitor changes to pattern "
                  .."\nand insert Zxx commands as"
                  .."\nnotes are entered."
            },
          },
          vb:text{
            text = "Note: realtime is active only while "
                .."\nEdit Mode is enabled in Renoise, "
                .."\nand phrase is set to Prg mode...",
            font = "italic",
          },
        },
      },

    }

    local keyhandler = nil

    dialog = renoise.app():show_custom_dialog(
      "PhraseMate", dialog_content, keyhandler)
  end

  ui_show_tab()
  ui_update_keymap()
  ui_update_realtime()
  ui_update_instruments()

end

--------------------------------------------------------------------------------

function ui_update_keymap()
  
  if not vb then return end

  local active = options.input_create_keymappings.value
  vb.views["ui_input_keymap_range"].active = active
  vb.views["ui_input_keymap_offset"].active = active

end

options.input_create_keymappings:add_notifier(ui_update_keymap)

--------------------------------------------------------------------------------

function ui_update_instruments()

  if not vb then return end

  local active = options.input_create_keymappings.value
  vb.views["ui_input_keymap_range"].active = active
  vb.views["ui_input_keymap_offset"].active = active

end

--------------------------------------------------------------------------------

function ui_update_realtime()

  if not vb then return end

  local instr = rns.selected_instrument
  local instr_has_phrases = (#instr.phrases > 0) and true or false
  vb.views["ui_realtime_playback_mode"].value = instr.phrase_playback_mode
  vb.views["ui_realtime_prev"].active = instr_has_phrases and xPhraseManager.can_select_previous_phrase()
  vb.views["ui_realtime_next"].active = instr_has_phrases and xPhraseManager.can_select_next_phrase()
  vb.views["ui_realtime_phrase_name"].text = ("%.2X : %s"):format(
    rns.selected_phrase_index, instr_has_phrases and rns.selected_phrase and rns.selected_phrase.name or "N/A")
  --vb.views["ui_realtime_phrase_name"].width = UI_WIDTH
  --vb.views["ui_realtime_phrase_name_header"].width = UI_WIDTH
end

--------------------------------------------------------------------------------

function ui_show_tab()

  if not vb then return end

  local tabs = {
    vb.views["tab_input"],
    vb.views["tab_output"],
    vb.views["tab_realtime"],
  }

  for k,v in ipairs(tabs) do
    v.visible = (options.active_tab_index.value == k) and true or false
  end

end

--------------------------------------------------------------------------------
-- Menu entries & MIDI/Key mappings
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:PhraseMate...",
  invoke = function() 
    show_preferences() 
  end
} 
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Show preferences...",
  invoke = function(repeated)
    if (not repeated) then 
      show_preferences() 
    end
  end
}

-- input : SELECTION_IN_PATTERN

renoise.tool():add_midi_mapping{
  name = "Tools:PhraseMate:Create Phrase from Selection in Pattern [Trigger]",
  invoke = function(msg)
    if msg:is_trigger() then
      invoke_task(collect_phrases(INPUT_SCOPE.SELECTION_IN_PATTERN))
    end
  end
}
renoise.tool():add_menu_entry {
  name = "Pattern Editor:PhraseMate:Create Phrase from Selection",
  invoke = function() 
    invoke_task(collect_phrases(INPUT_SCOPE.SELECTION_IN_PATTERN))
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Create Phrase from Selection in Pattern",
  invoke = function(repeated)
    if (not repeated) then 
      invoke_task(collect_phrases(INPUT_SCOPE.SELECTION_IN_PATTERN))
    end
  end
}

-- input : SELECTION_IN_MATRIX

renoise.tool():add_midi_mapping{
  name = "Tools:PhraseMate:Create Phrase from Selection in Matrix [Trigger]",
  invoke = function(msg)
    if msg:is_trigger() then
      invoke_task(collect_phrases(INPUT_SCOPE.SELECTION_IN_MATRIX))
    end
  end
}
renoise.tool():add_menu_entry {
  name = "Pattern Matrix:PhraseMate:Create Phrase from Selection",
  invoke = function() 
    invoke_task(collect_phrases(INPUT_SCOPE.SELECTION_IN_MATRIX))
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Create Phrase from Selection in Matrix",
  invoke = function(repeated)
    if (not repeated) then 
      invoke_task(collect_phrases(INPUT_SCOPE.SELECTION_IN_MATRIX))
    end
  end
}

-- input : TRACK_IN_PATTERN

renoise.tool():add_midi_mapping{
  name = "Tools:PhraseMate:Create Phrase from Track [Trigger]",
  invoke = function(msg)
    if msg:is_trigger() then
      invoke_task(collect_phrases(INPUT_SCOPE.TRACK_IN_PATTERN))
    end
  end
}
renoise.tool():add_menu_entry {
  name = "Pattern Editor:PhraseMate:Create Phrase from Track",
  invoke = function() 
    invoke_task(collect_phrases(INPUT_SCOPE.TRACK_IN_PATTERN))
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Create Phrase from Track",
  invoke = function(repeated)
    if (not repeated) then 
      invoke_task(collect_phrases(INPUT_SCOPE.TRACK_IN_PATTERN))
    end
  end
}

-- input : TRACK_IN_SONG

renoise.tool():add_midi_mapping{
  name = "Tools:PhraseMate:Create Phrases from Track in Song [Trigger]",
  invoke = function(msg)
    if msg:is_trigger() then
      invoke_task(collect_phrases(INPUT_SCOPE.TRACK_IN_SONG))
    end
  end
}
renoise.tool():add_menu_entry {
  name = "Pattern Editor:PhraseMate:Create Phrases from Track in Song",
  invoke = function() 
    invoke_task(collect_phrases(INPUT_SCOPE.TRACK_IN_SONG))
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Create Phrases from Track in Song",
  invoke = function(repeated)
    if (not repeated) then 
      invoke_task(collect_phrases(INPUT_SCOPE.TRACK_IN_SONG))
    end
  end
}

-- output : apply_phrase_to_selection

renoise.tool():add_midi_mapping{
  name = "Tools:PhraseMate:Write Phrase to Selection In Pattern [Trigger]",
  invoke = function(msg)
    if msg:is_trigger() then
      invoke_task(apply_phrase_to_selection())
    end
  end
}
renoise.tool():add_menu_entry {
  name = "--- Pattern Editor:PhraseMate:Write Phrase to Selection In Pattern",
  invoke = function() 
    invoke_task(apply_phrase_to_selection())
  end
} 
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Write Phrase to Selection in Pattern",
  invoke = function(repeated)
    if (not repeated) then 
      invoke_task(apply_phrase_to_selection())
    end
  end
}

-- output : apply_phrase_to_track

renoise.tool():add_midi_mapping{
  name = "Tools:PhraseMate:Write Phrase to Track [Trigger]",
  invoke = function(msg)
    if msg:is_trigger() then
      invoke_task(apply_phrase_to_track())
    end
  end
}
renoise.tool():add_menu_entry {
  name = "Pattern Editor:PhraseMate:Write Phrase to Track",
  invoke = function() 
    invoke_task(apply_phrase_to_track())
  end
} 

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Write Phrase to Track",
  invoke = function(repeated)
    if (not repeated) then 
      invoke_task(apply_phrase_to_track())
    end
  end
}

-- realtime

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Select Previous Phrase in Instrument",
  invoke = function()
    invoke_task(xPhraseManager.select_previous_phrase())
  end
}
renoise.tool():add_midi_mapping {
  name = MIDI_MAPPING.PREV_PHRASE_IN_INSTR,
  invoke = function(msg)
    if msg:is_trigger() then
      invoke_task(xPhraseManager.select_previous_phrase())
    end
  end
}

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Select Next Phrase in Instrument",
  invoke = function()
    invoke_task(xPhraseManager.select_next_phrase())
  end
}
renoise.tool():add_midi_mapping {
  name = MIDI_MAPPING.NEXT_PHRASE_IN_INSTR,
  invoke = function(msg)
    if msg:is_trigger() then
      invoke_task(xPhraseManager.select_next_phrase())
    end
  end
}

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Set Playback Mode to 'Off'",
  invoke = function(repeated)
    if (not repeated) then 
      invoke_task(xPhraseManager.set_playback_mode(renoise.Instrument.PHRASES_OFF))
    end
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Set Playback Mode to 'Program'",
  invoke = function(repeated)
    if (not repeated) then 
      invoke_task(xPhraseManager.set_playback_mode(renoise.Instrument.PHRASES_PLAY_SELECTIVE))
    end
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Set Playback Mode to 'Keymap'",
  invoke = function(repeated)
    if (not repeated) then 
      invoke_task(xPhraseManager.set_playback_mode(renoise.Instrument.PHRASES_PLAY_KEYMAP))
    end
  end
}
renoise.tool():add_midi_mapping {
  name = "Global:PhraseMate:Select Playback Mode [Set]",
  invoke = function(msg)
    local mode = xLib.clamp_value(msg.int_value,1,3)
    invoke_task(xPhraseManager.set_playback_mode(renoise.Instrument.PHRASES_PLAY_KEYMAP))
  end
}

-- addendum

renoise.tool():add_menu_entry {
  name = "--- Pattern Editor:PhraseMate:Adjust settings...",
  invoke = function() 
    show_preferences()
  end
}
renoise.tool():add_menu_entry {
  name = "--- Pattern Matrix:PhraseMate:Adjust settings...",
  invoke = function() 
    show_preferences()
  end
}

--------------------------------------------------------------------------------
-- Input methods
--------------------------------------------------------------------------------

function get_source_instr()

  local rslt = table.copy(UI_SOURCE_ITEMS)
  for k = 1,127 do
    local instr = rns.instruments[k]
    local instr_name = instr and instr.name or ""
    table.insert(rslt,("%.2X %s"):format(k-1,instr_name))
  end
  return rslt

end

--------------------------------------------------------------------------------

function get_target_instr()

  local rslt = table.copy(UI_TARGET_ITEMS)
  for k = 1,127 do
    local instr = rns.instruments[k]
    local instr_name = instr and instr.name or ""
    table.insert(rslt,("%.2X %s"):format(k-1,instr_name))
  end
  return rslt

end

--------------------------------------------------------------------------------
-- return pattern name, or "Patt XX" if not defined

function get_pattern_name(seq_idx)
  local name = rns.patterns[rns.sequencer:pattern(seq_idx)].name
  return (name=="") and ("Pattern %.2d"):format(seq_idx) or "Pattern "..name
end

--------------------------------------------------------------------------------
-- return track name, or "Track XX" if not defined

function get_track_name(trk_idx)
  local name = rns.tracks[trk_idx].name
  return (name=="") and ("Track %.2d") or name 
end

--------------------------------------------------------------------------------
-- when doing CAPTURE_ONCE, grab the instrument nearest to our cursor 

function do_capture_once(trk_idx,seq_idx)
  TRACE("do_capture_once(trk_idx,seq_idx)",trk_idx,seq_idx)

  if not done_with_capture 
    and (options.input_source_instr.value == SOURCE_INSTR.CAPTURE_ONCE) 
  then
    local seq_idx,trk_idx = rns.selected_sequence_index,rns.selected_track_index
    rns.selected_sequence_index = seq_idx
    rns.selected_track_index = trk_idx
    source_instr_idx = xInstrument.autocapture()
    rns.selected_sequence_index,rns.selected_track_index = seq_idx,trk_idx
    done_with_capture = true
    --print("*** captured instrument",source_instr_idx)
  end

end

--------------------------------------------------------------------------------
-- look for implicit/explicit phrase trigger in the provided patternline
-- @param line (renoise.PatternLine)
-- @param note_col_idx (int)
-- @param instr_idx (int)
-- @param trk_idx (int)
-- @return bool

function note_is_phrase_trigger(line,note_col_idx,instr_idx,trk_idx)
  TRACE("note_is_phrase_trigger(line,note_col_idx,instr_idx,trk_idx)",line,note_col_idx,instr_idx,trk_idx)

  -- no note means no triggering 
  local note_col = line.note_columns[note_col_idx]
  if (note_col.note_value > renoise.PatternLine.NOTE_OFF) then
    --print("No note available")
    return false
  end

  -- no phrases means no triggering 
  local instr = rns.instruments[instr_idx]
  if (#instr.phrases == 0) then
    --print("No phrases available")
    return false
  end

  local track = rns.tracks[trk_idx]
  --local visible_note_cols = track.visible_note_columns
  local visible_fx_cols = track.visible_effect_columns

  local get_zxx_command = function()
    for k,v in ipairs(line.effect_columns) do
      if (k > visible_fx_cols) then
        break
      elseif (v.number_string == "0Z") then
        return v.amount_value
      end
    end
  end

  if (note_col.effect_number_string == "0Z") 
    and (note_col.effect_amount_value > 0x00)
    and (note_col.effect_amount_value < 0x7F)
  then
    return true
  elseif (instr.phrase_playback_mode == renoise.Instrument.PHRASES_PLAY_SELECTIVE) then
    return true
  elseif (instr.phrase_playback_mode == renoise.Instrument.PHRASES_PLAY_KEYMAP) 
    and xPhrase.note_is_keymapped(note_col.note_value,instr)
  then
    return true
  else
    local zxx_index = get_zxx_command() 
    --print("zxx_index",zxx_index)
    if (zxx_index > 0x00) and (zxx_index <= 0x7F) then
      return true
    end
  end

  return false

end


--------------------------------------------------------------------------------
-- reuse instrument (via map), take over (when empty) or create as needed
-- will update target_instr_idx ...

function allocate_target_instr()
  TRACE("allocate_target_instr()")

  if (options.input_target_instr.value == TARGET_INSTR.NEW) then

    -- attempt to re-use previously created
    local do_copy = false
    if source_target_map[source_instr_idx] then
      target_instr_idx = source_target_map[source_instr_idx]
      --print("*** allocate_target_instr - reuse",target_instr_idx)
    else
      target_instr_idx = xInstrument.get_first_available()
      source_target_map[source_instr_idx] = target_instr_idx
      --print("*** allocate_target_instr - takeover",target_instr_idx)
      do_copy = true
    end

    if not target_instr_idx then
      target_instr_idx = #rns.instruments+1
      rns:insert_instrument_at(target_instr_idx)
      source_target_map[source_instr_idx] = target_instr_idx
      --print("*** allocate_target_instr - create",target_instr_idx)
      do_copy = true
    end

    if do_copy then
      local target_instr = rns.instruments[target_instr_idx]
      local source_instr = rns.instruments[source_instr_idx]
      target_instr:copy_from(source_instr)
      target_instr.name = ("#%s"):format(source_instr.name)
    end

  end

end

--------------------------------------------------------------------------------
-- continue existing phrase, take over empty phrase or create as needed

function allocate_phrase(track,seq_idx,trk_idx,selection)

  local phrase,phrase_idx

  -- continue existing
  if collected_phrases[source_instr_idx] then
    for k,v in ipairs(collected_phrases[source_instr_idx]) do
      if (v.sequence_index == seq_idx) then
        local instr = rns.instruments[target_instr_idx]
        phrase,phrase_idx = instr.phrases[v.phrase_index],v.phrase_index
        --print(">>> reusing phrase in seq,trk",seq_idx,trk_idx,"for source/target",source_instr_idx,target_instr_idx,phrase_idx,phrase)
      end
    end
  end

  -- takeover/create
  if not phrase then
    
    local takeover = true
    local create_keymap = options.input_create_keymappings.value
    local keymap_range = options.input_keymap_range.value
    local keymap_offset = options.input_keymap_offset.value
    phrase,phrase_idx = xPhraseManager.auto_insert_phrase(target_instr_idx,create_keymap,keymap_range,keymap_offset,takeover)
    --print("*** allocate_phrase - phrase,phrase_idx",phrase,phrase_idx)

    -- maintain a record for later
    if not collected_phrases[source_instr_idx] then
      collected_phrases[source_instr_idx] = {}
    end
    table.insert(collected_phrases[source_instr_idx],{
      instrument_index = target_instr_idx,
      track_index = trk_idx,
      sequence_index = seq_idx,
      phrase_index = phrase_idx,
    })
    --print(">>> allocate_phrase - collected_phrases...",#collected_phrases,rprint(collected_phrases))

    -- name & configure the phrase
    if phrase then
      phrase.name = ("%s : %s"):format(get_pattern_name(seq_idx),get_track_name(trk_idx))
      phrase.number_of_lines = 1 + selection.end_line - selection.start_line
      phrase.volume_column_visible = track.volume_column_visible
      phrase.panning_column_visible = track.panning_column_visible
      phrase.delay_column_visible = track.delay_column_visible
      phrase.sample_effects_column_visible = track.sample_effects_column_visible
      if (track.type == renoise.Track.TRACK_TYPE_SEQUENCER) then
        phrase.visible_note_columns = track.visible_note_columns
      end
      phrase.visible_effect_columns = track.visible_effect_columns
    end

  end

  if not phrase then
    return false,"Could not allocate phrase"
  end

  return phrase,phrase_idx

end

--------------------------------------------------------------------------------
-- invoked through the 'collect phrases' button/shortcuts
-- @param scope (INPUT_SCOPE), when invoked via shortcut
-- @return table (created phrase indices)

function collect_phrases(scope)
  TRACE("collect_phrases(scope)",scope)

  if not scope then
    scope = options.input_scope.value
  end

  -- reset variables
  source_target_map = {}
  collected_phrases = {}
  ghost_columns = {}
  source_instr_idx = rns.selected_instrument_index
  target_instr_idx = rns.selected_instrument_index

  -- do collection

  if (scope == INPUT_SCOPE.SELECTION_IN_PATTERN) then
    collect_from_pattern_selection()
  elseif (scope == INPUT_SCOPE.SELECTION_IN_MATRIX) then
    collect_from_matrix_selection()
  elseif (scope == INPUT_SCOPE.TRACK_IN_PATTERN) then
    collect_from_track_in_pattern()
  elseif (scope == INPUT_SCOPE.TRACK_IN_SONG) then
    collect_from_track_in_song()
  else
    error("Unexpected output scope")
  end

  -- post-process / finalize

  local delete_instruments = {}

  --print("*** collect_phrases - collected_phrases",rprint(collected_phrases))
  if (type(collected_phrases)=="table") then

    local cached_instr_idx = rns.selected_instrument_index

    for instr_idx,collected in pairs(collected_phrases) do
      --print("instr_idx,collected",instr_idx,collected)
      for __,v in pairs(collected) do

        local instr = rns.instruments[v.instrument_index]

        if (options.input_target_instr.value == TARGET_INSTR.NEW) 
          and (#instr.phrases == 0)
        then
          -- newly created instrument contains no phrases,
          -- it seems safe to remove it again          
          delete_instruments[v.instrument_index] = true
        else

          local phrase = instr.phrases[v.phrase_index]

          -- remove empty phrases
          if phrase.is_empty then
            instr:delete_phrase_at(v.phrase_index)
            --print("*** deleted empty phrase at ",v.phrase_index)
          else

            -- TODO check for duplicates 
            --local duplicates = 0

            xPhrase.clear_foreign_commands(phrase)

            -- replace notes with phrase trigger 
            -- (if multiple instruments, each is a separate note-column)
            if options.input_replace_collected.value then
              local track = rns.tracks[v.track_index]
              local patt_idx = rns.sequencer:pattern(v.sequence_index)
              local patt_lines = rns.pattern_iterator:lines_in_pattern_track(patt_idx,v.track_index)
              for ___,line in patt_lines do
                
                -- allocate column
                local col_idx = 1
                for k,note_col in ipairs(line.note_columns) do
                  if (note_col.effect_number_string ~= "0Z") then
                    col_idx = k
                    track.visible_note_columns = k
                    break
                  end
                end
                --print("*** replace notes, create trigger in column",col_idx)

                local trigger_note_col = line.note_columns[col_idx]
                trigger_note_col.instrument_value = v.instrument_index-1
                trigger_note_col.note_string = "C-4"
                trigger_note_col.effect_number_string = "0Z"
                trigger_note_col.effect_amount_value = v.phrase_index
                track.sample_effects_column_visible = true
                break
              end
            end

          end

          -- bring the phrase editor to front for all created instruments 
          instr.phrase_editor_visible = true

          -- switch to the relevant playback mode
          if options.input_create_keymappings then
            instr.phrase_playback_mode = renoise.Instrument.PHRASES_PLAY_KEYMAP
          end

        end

      end
    end

    if (options.input_target_instr.value == TARGET_INSTR.NEW) then
      rns.selected_instrument_index = target_instr_idx
    end
    if (#rns.selected_instrument.phrases > 0) then
      rns.selected_phrase_index = #rns.selected_instrument.phrases
    end

    -- remove newly created instruments without phrases
    if not table.is_empty(delete_instruments) then
      for k = 127,1,-1 do
        if delete_instruments[k] then
          --print("delete instrument at",k)
          rns:delete_instrument_at(k)
        end
      end
      rns.selected_instrument_index = cached_instr_idx
    end

    -- show report 
    --[[
    if options.output_show_collection_report.value then
      local msg = ("Created %d phrases"):format(#collected_phrases)
      if (duplicates > 0) then
        msg = ("%s (ignored %d duplicates)"):format(msg,duplicates)
      end
      renoise.app():show_message(msg)
    end
    ]]

  end

end

--------------------------------------------------------------------------------
-- @return bool
-- @return string (error message)

function collect_from_pattern_selection()
  TRACE("collect_from_pattern_selection()")

  local patt_sel,err = xSelection.get_pattern_if_single_track()
  if not patt_sel then
    return false,err
  end

  local seq_idx = rns.selected_sequence_index
  do_capture_once(patt_sel.start_track,seq_idx)

  do_collect(nil,nil,patt_sel)

end

--------------------------------------------------------------------------------
-- collect phrases from the matrix selection
-- @return bool
-- @return string (error message)

function collect_from_matrix_selection()
  TRACE("collect_from_matrix_selection()")

  local matrix_sel,err = xSelection.get_matrix_selection()
  if table.is_empty(matrix_sel) then
    return false,"No selection is defined in the matrix"
  end

  local create_keymap = options.input_create_keymappings.value
  for seq_idx = 1, #rns.sequencer.pattern_sequence do
    if matrix_sel[seq_idx] then
      for trk_idx = 1, #rns.tracks do
        if matrix_sel[seq_idx][trk_idx] then
          do_capture_once(trk_idx,seq_idx)
          do_collect(seq_idx,trk_idx)
        end
      end
    end
  end

end

--------------------------------------------------------------------------------
-- collect phrases from the selected pattern-track 
-- @return bool
-- @return string (error message)

function collect_from_track_in_pattern()
  TRACE("collect_from_track_in_pattern()")

  local trk_idx = rns.selected_track_index
  local seq_idx = rns.selected_sequence_index
  do_capture_once(trk_idx,seq_idx)

  do_collect()

end

--------------------------------------------------------------------------------
-- collect phrases from the selected track in the song
-- @return bool
-- @return string (error message)

function collect_from_track_in_song()
  TRACE("collect_from_track_in_song()")

  local trk_idx = rns.selected_track_index

  for seq_idx = 1, #rns.sequencer.pattern_sequence do
    do_capture_once(trk_idx,seq_idx)
    do_collect(seq_idx)
  end

end

--------------------------------------------------------------------------------
-- invoked as we travel through pattern-tracks...
-- @param seq_idx (int)
-- @param trk_idx (int)
-- @param patt_sel (table), specified when doing SELECTION_IN_PATTERN

function do_collect(seq_idx,trk_idx,patt_sel)
  TRACE("do_collect(seq_idx,trk_idx,patt_sel)",seq_idx,trk_idx,patt_sel)

  assert(source_instr_idx,"Expected source_instr_idx to be defined")

  if not seq_idx then
    seq_idx = rns.selected_sequence_index
  end
  if not trk_idx then
    trk_idx = rns.selected_track_index
  end

  if not patt_sel then
    patt_sel = xSelection.get_pattern_track(seq_idx,trk_idx)
  end
  --print("*** patt_sel",rprint(patt_sel))

  -- make sure ghost columns are initialized
  if not ghost_columns[trk_idx] then
    ghost_columns[trk_idx] = {}
  end

  -- set up our iterator
  local track = rns.tracks[trk_idx]
  local patt_idx = rns.sequencer:pattern(seq_idx)
  local patt_lines = rns.pattern_iterator:lines_in_pattern_track(patt_idx,trk_idx)

  -- loop through pattern, create phrases/instruments as needed

  local target_phrase,target_phrase_idx = nil

  for pos, line in patt_lines do
    if pos.line > patt_sel.end_line then break end
    if pos.line >= patt_sel.start_line then
      if not line.is_empty then

        local phrase_line_idx = pos.line - (patt_sel.start_line-1)

        -- iterate through note-columns
        for note_col_idx,note_col in ipairs(line.note_columns) do
          

          if (note_col_idx > track.visible_note_columns) then
            --print("*** do_collect - skip hidden note-column",note_col_idx)
          else
            --print("*** do_collect - note_col_idx,line idx",note_col_idx,pos.line)

            local instr_value = note_col.instrument_value
            local has_note_value = (instr_value < 255)
            local capture_all = (options.input_source_instr.value == SOURCE_INSTR.CAPTURE_ALL)

            -- before switching instrument/phrase, produce a note-off
            if has_note_value and target_phrase then
              local do_note_off = false
              if capture_all 
                and ghost_columns[trk_idx][note_col_idx]
                and (instr_value+1 ~= ghost_columns[trk_idx][note_col_idx])
              then
                -- special treatment for this mode, as the source 
                -- can change during iteration 
                do_note_off = true
                source_instr_idx = ghost_columns[trk_idx][note_col_idx]
                allocate_target_instr()
                target_phrase,target_phrase_idx = allocate_phrase(track,seq_idx,trk_idx,patt_sel)
              elseif (source_instr_idx ~= instr_value+1)
                and (source_instr_idx == ghost_columns[trk_idx][note_col_idx])
              then
                -- standard 'fixed' source instrument
                do_note_off = true
              end
              if do_note_off then
                local phrase_col = target_phrase:line(phrase_line_idx).note_columns[note_col_idx]
                phrase_col.note_value = renoise.PatternLine.NOTE_OFF
              end
            end

            -- do we need to change source/create instruments on the fly? 
            if capture_all then
              if has_note_value then
                source_instr_idx = instr_value+1
                target_phrase = nil
                --print("*** do_collect - switched to source instrument...")
              elseif ghost_columns[trk_idx][note_col_idx] then
                source_instr_idx = ghost_columns[trk_idx][note_col_idx]
                target_phrase = nil
                --print("*** do_collect - ghost columns decided source instrument...")
              end
            end

            -- initialize the phrase
            if not target_phrase then
              allocate_target_instr()
              target_phrase,target_phrase_idx = allocate_phrase(track,seq_idx,trk_idx,patt_sel)
            end

            local phrase_col = target_phrase:line(phrase_line_idx).note_columns[note_col_idx]
            --print("phrase_col",phrase_col)

            -- maintain ghost columns
            if (instr_value < 255) then
              ghost_columns[trk_idx][note_col_idx] = instr_value+1
            end
            --print("*** do_collect - ghost_columns",rprint(ghost_columns))

            -- copy note-column when we have an active (ghost-)note 
            local do_copy = capture_all and ghost_columns[trk_idx][note_col_idx] or
              (ghost_columns[trk_idx][note_col_idx] == source_instr_idx)

            if (do_copy) then
              if not note_is_phrase_trigger(line,note_col_idx,source_instr_idx,trk_idx) then
                phrase_col:copy_from(note_col)                
                --print("*** do_collect - copied this column",note_col)
                if options.input_replace_collected.value then
                  note_col:clear()
                end
              end
            end
          
          end

        end

        -- fx columns are always copied
        for fx_col_idx,fx_col in ipairs(line.effect_columns) do
          local phrase_col = target_phrase:line(phrase_line_idx).effect_columns[fx_col_idx]
          phrase_col:copy_from(fx_col)
          if options.input_replace_collected.value then
            fx_col:clear()
          end
        end

      end
    end
  end


end


--------------------------------------------------------------------------------
-- Output methods
--------------------------------------------------------------------------------
-- @param start_col - note/effect column index
-- @param end_col - note/effect column index
-- @param start_line - pattern line
-- @param end_line - pattern line

function apply_phrase_to_track(start_col,end_col,start_line,end_line)

  local track_index = rns.selected_track_index
  local instr_index = rns.selected_instrument_index
  local phrase = rns.selected_phrase

  if not phrase then
    return false,"No phrase was selected"
  end

  suppress_line_notifier = true

  local track = rns.selected_track

  -- TODO support other track types
  if (track.type == renoise.Track.TRACK_TYPE_SEQUENCER) then
    return false,"Can only write to sequencer tracks"
  end

  local ptrack = rns.selected_pattern_track
  
  local start_note_col,end_note_col
  local start_fx_col,end_fx_col
  local restrict_to_selection = start_col

  if not start_col then
    start_line = 1
    start_note_col = 1
    start_fx_col = 1
    end_line = #ptrack.lines
    end_note_col = phrase.visible_note_columns
    end_fx_col = phrase.visible_effect_columns
  else
    if (start_col <= track.visible_note_columns) then
      start_note_col = start_col
      start_fx_col = 1
    else
      start_note_col = nil
      start_fx_col = start_col - phrase.visible_note_columns
    end
    if (end_col <= phrase.visible_note_columns) then
      start_fx_col = nil
      end_note_col = end_col
    else 
      end_note_col = start_col + phrase.visible_note_columns - 1
      end_fx_col = end_col - phrase.visible_note_columns
    end
  end

  -- produce output
  
  local num_lines = end_line - start_line
  local phrase_num_lines = phrase.number_of_lines

  for i = 1,num_lines do

    local source_line_idx = i

    if not options.cont_paste.value then
      if (i > phrase_num_lines) then
        break
      end
    else
      if options.anchor_to_selection.value then
        source_line_idx = i % phrase_num_lines
      else
        source_line_idx = (start_line+i-1) % phrase_num_lines
      end
      if (source_line_idx == 0) then
        source_line_idx = phrase_num_lines
      end
    end
    
    local source_line = phrase:line(source_line_idx)
    local target_line = ptrack:line(start_line+i-1)
   
    if start_note_col then
      local col_count = 0
      for col_idx = 1,renoise.InstrumentPhrase.MAX_NUMBER_OF_NOTE_COLUMNS do
        if (col_idx >= start_note_col) and
          (col_idx <= end_note_col) 
        then

          col_count = col_count + 1
          local skip_column = (phrase:column_is_muted(col_count)
            and options.skip_muted.value) or false

          if not skip_column then

            local source_col = source_line:note_column(col_count)
            local target_col = target_line:note_column(col_idx)

            -- note
            if (source_col.note_value < 121) then
              target_col.note_value = source_col.note_value
            elseif not options.mix_paste.value then
              target_col.note_value = 121
            end

            -- instrument 
            if (source_col.note_value < 121) then
              target_col.instrument_value = instr_index-1
            elseif not options.mix_paste.value then
              target_col.note_value = 121
            end

            -- volume
            if phrase.volume_column_visible then
              if (source_col.volume_value ~= 255) then
                target_col.volume_value = source_col.volume_value
                if options.expand_subcolumns.value then
                  track.volume_column_visible = true
                end
              elseif not options.mix_paste.value then
                target_col.volume_value = 255
              end          
            end          
  
            -- panning
            if phrase.panning_column_visible then
              if (source_col.panning_value ~= 255) then
                target_col.panning_value = source_col.panning_value
                if options.expand_subcolumns.value then
                  track.panning_column_visible = true
                end
              elseif not options.mix_paste.value then
                target_col.panning_value = 255
              end      
            end      
            
            -- delay
            if phrase.delay_column_visible then
              if (source_col.delay_value > 0) then
                target_col.delay_value = source_col.delay_value
                if options.expand_subcolumns.value then
                  track.delay_column_visible = true
                end
              elseif not options.mix_paste.value then
                target_col.delay_value = 0
              end          
            end          
  
            -- sample effects
            if phrase.sample_effects_column_visible then
              if (source_col.effect_amount_value > 0) then
                target_col.effect_amount_value = source_col.effect_amount_value
                if options.expand_subcolumns.value then
                  track.sample_effects_column_visible = true
                end
              elseif not options.mix_paste.value then
                target_col.effect_amount_value = 0
              end          
              if (source_col.effect_number_value > 0) then
                target_col.effect_number_value = source_col.effect_number_value
                if options.expand_subcolumns.value then
                  track.sample_effects_column_visible = true
                end
              elseif not options.mix_paste.value then
                target_col.effect_number_value = 0
              end  
            end  

            if options.expand_columns and 
              (track.visible_note_columns < col_idx)
            then
              track.visible_note_columns = col_idx
            end

          else

            -- muted: clear when not mix-pasting
            if not options.mix_paste.value then
              local target_col = target_line:note_column(col_idx)
              target_col:clear()
            end

          end          
        
        end
      end
    end

    if start_fx_col then
    local col_count = 1
      for col_idx = 1,track.visible_effect_columns do
        if (col_idx >= start_fx_col) and
          (col_idx <= end_fx_col) 
        then

          local source_col = source_line:effect_column(col_count)
          local target_col = target_line:effect_column(col_idx)

          if (source_col.amount_value > 0) then
            target_col.amount_value = source_col.amount_value
          elseif not options.mix_paste.value then
            target_col.amount_value = 0
          end          
          if (source_col.number_value > 0) then
            target_col.number_value = source_col.number_value
          elseif not options.mix_paste.value then
            target_col.number_value = 0
          end 

          col_count = col_count + 1

        end
      end
    end

  end
  
  suppress_line_notifier = false

  return true

end

--------------------------------------------------------------------------------

function apply_phrase_to_selection()

  local pass,err = xSelection.pattern_has_single_track()
  if not pass then
    return false,err
  end

  local sel = rns.selection_in_pattern
  return apply_phrase_to_track(sel.start_column,sel.end_column,sel.start_line,sel.end_line)

end

--------------------------------------------------------------------------------
-- Realtime methods
--------------------------------------------------------------------------------

function line_notifier_fn(pos)
  if not suppress_line_notifier then
    table.insert(modified_lines,pos)
    --print("modified_lines",#modified_lines)
  end
end

--------------------------------------------------------------------------------

function handle_modified_line(pos)
  TRACE("handle_modified_line(pos)",pos)

  local patt = rns.patterns[pos.pattern]
  local ptrack = patt:track(pos.track)
  local line = ptrack:line(pos.line)
  local instr = rns.selected_instrument
  local has_phrases = (#instr.phrases > 0)
  local program_mode = (instr.phrase_playback_mode == renoise.Instrument.PHRASES_PLAY_SELECTIVE)

  local matching_note = nil

  for k,note_col in ipairs(line.note_columns) do
    if (note_col.instrument_value == rns.selected_instrument_index-1) then
      matching_note = {
        note_column_index = k,
      }
      break
    end
  end
  --print("matching_note",rprint(matching_note))

  if matching_note and has_phrases and program_mode then
    --print("add Zxx command")
    for k,fx_col in ipairs(line.effect_columns) do
      local has_zxx_command = (fx_col.number_string == "0Z")
      if has_zxx_command then
        --print("existing zxx command",fx_col.amount_value)
        local where_we_were = rns.transport.edit_pos.line - rns.transport.edit_step
        if (pos.line == where_we_were) then
          local num_phrases = #rns.selected_instrument.phrases
          local zxx_command_value = has_zxx_command and fx_col.amount_value or rns.selected_phrase_index
          fx_col.number_string = "0Z"
          fx_col.amount_value = zxx_command_value
        else
          --print("got here")
        end
        break
      elseif fx_col.is_empty then
        --print("no zxx - add selected")
        fx_col.number_string = "0Z"
        fx_col.amount_value = rns.selected_phrase_index
        break
      end
    end

  elseif not matching_note then
    --print("clear Zxx command")
    local zxx_command = nil
    for k,fx_col in ipairs(line.effect_columns) do
      if (fx_col.number_string == "0Z") then
        zxx_command = {
          effect_column_index = k,
        }
        break
      end
    end
    if zxx_command then
      if zxx_command.note_column_index then
        --line.note_columns[zxx_command.note_column_index].effect_amount_value = 0
        --line.note_columns[zxx_command.note_column_index].effect_number_value = 0
      elseif zxx_command.effect_column_index then
        line.effect_columns[zxx_command.effect_column_index].amount_value = 0
        line.effect_columns[zxx_command.effect_column_index].number_value = 0
      end
    end

  end

end

--------------------------------------------------------------------------------
function phrase_playback_mode_handler()
  TRACE("phrase_playback_mode_handler")

  realtime_update_requested = true

end

--------------------------------------------------------------------------------

function phrase_index_notifier()
  TRACE("phrase_index_notifier")
  realtime_update_requested = true
end

--------------------------------------------------------------------------------

function ui_update_instruments()
  TRACE("ui_update_instruments")

  if not vb then return end

  vb.views["ui_source_popup"].items = get_source_instr()
  vb.views["ui_target_popup"].items = get_target_instr()
  if (options.input_target_instr.value < 3) then
    vb.views["ui_target_popup"].value = options.input_target_instr.value
  end

end

--------------------------------------------------------------------------------

function attach_to_instrument()
  TRACE("attach_to_instrument()")

  local instr = rns.selected_instrument

  if not instr.phrase_playback_mode_observable:has_notifier(phrase_playback_mode_handler) then
    instr.phrase_playback_mode_observable:add_notifier(phrase_playback_mode_handler)
  end

  ui_update_realtime()

end

--------------------------------------------------------------------------------

function detach_from_instrument()
  TRACE("detach_from_instrument()")

  local instr = rns.selected_instrument

  if instr.phrase_playback_mode_observable:has_notifier(phrase_playback_mode_handler) then
    instr.phrase_playback_mode_observable:remove_notifier(phrase_playback_mode_handler)
  end

end

--------------------------------------------------------------------------------

function attach_to_pattern()
  TRACE("attach_to_pattern()")

  modified_lines = {}

  local pattern = rns.selected_pattern

  if not pattern:has_line_notifier(line_notifier_fn) then
    pattern:add_line_notifier(line_notifier_fn)
  end

end

--------------------------------------------------------------------------------

function detach_from_pattern()
  TRACE("detach_from_pattern()")

  local pattern = rns.selected_pattern

  if pattern:has_line_notifier(line_notifier_fn) then
    pattern:remove_line_notifier(line_notifier_fn)
  end

end

--------------------------------------------------------------------------------

function attach_to_song()
  TRACE("attach_to_song()")

  if not rns.selected_pattern_observable:has_notifier(attach_to_pattern) then
    rns.selected_pattern_observable:add_notifier(attach_to_pattern)
  end
  attach_to_pattern()
  
  if not rns.selected_instrument_observable:has_notifier(attach_to_instrument) then
    rns.selected_instrument_observable:add_notifier(attach_to_instrument)
  end
  attach_to_instrument()

  if not rns.selected_phrase_observable:has_notifier(phrase_index_notifier) then
    rns.selected_phrase_observable:add_notifier(phrase_index_notifier)
  end

  if not rns.instruments_observable:has_notifier(ui_update_instruments) then
    rns.instruments_observable:add_notifier(ui_update_instruments)
  end

end


--------------------------------------------------------------------------------

function detach_from_song()
  TRACE("detach_from_song()")

  if rns.selected_pattern_observable:has_notifier(attach_to_pattern) then
    rns.selected_pattern_observable:remove_notifier(attach_to_pattern)
  end
  detach_from_pattern()

  if rns.selected_instrument_observable:has_notifier(attach_to_instrument) then
    rns.selected_instrument_observable:remove_notifier(attach_to_instrument)
  end
  detach_from_instrument()

  if rns.selected_phrase_observable:has_notifier(phrase_index_notifier) then
    rns.selected_phrase_observable:remove_notifier(phrase_index_notifier)
  end

  if rns.instruments_observable:has_notifier(ui_update_instruments) then
    rns.instruments_observable:remove_notifier(ui_update_instruments)
  end

end


--------------------------------------------------------------------------------
-- notifications
--------------------------------------------------------------------------------

renoise.tool().app_idle_observable:add_notifier(function()

  if realtime_update_requested then
    realtime_update_requested = false
    ui_update_realtime()
  end

  if (#modified_lines > 0) then
    if rns.transport.edit_mode then
      for k,v in ipairs(modified_lines) do
        handle_modified_line(v)
      end
    end
    modified_lines = {}
    --user_set_program = nil
    --print("user_set_program 2",user_set_program)
  end

end)

--------------------------------------------------------------------------------

renoise.tool().app_new_document_observable:add_notifier(function()
  TRACE("*** app_new_document_observable fired...")

  rns = renoise.song()
  attach_to_song()
  ui_update_realtime()

end)


--------------------------------------------------------------------------------

renoise.tool().app_release_document_observable:add_notifier(function()
  TRACE("*** app_release_document_observable fired...")

  detach_from_song()

end)


