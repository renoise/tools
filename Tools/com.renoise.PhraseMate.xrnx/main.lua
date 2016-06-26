--[[============================================================================
com.renoise.PhraseMate.xrnx/main.lua
============================================================================]]--
--[[

PhraseMate aims to make it more convenient to work with phrases 
.
#

## How to use

Define the behavior of the tool by launching it from the tool menu, or 
use the keyboard shortcuts to produce output (search for 'PhraseMate' in 
Renoise preferences > keys)

## TODO

* Re-use empty phrases ('takeover') when collection didn't yield any results 
* Detect duplicate phrases (xPhraseManager.find_duplicates)

## LIMITATIONS

When collecting a phrase from a specific source instrument, the tool will look for effects that are associated with that particular instrument. In case multiple instruments are triggered on the same line (but in different note-columns), any effect commands are not removed as they might influence both instruments.  
When the source instrument is already making use of phrases, notes that trigger phrases are skipped
When starting to collect phrases from the middle of a pattern/song, ghost notes are not resolved until an instrument is reached. As a result, the first notes might be missing. 

## PLANNED

Ability to transpose and harmonize notes
- Read from pattern using triggering note as basenote 
- Apply to pattern using a specific basenote

]]

--------------------------------------------------------------------------------
-- required files
--------------------------------------------------------------------------------

rns = nil
_xlibroot = 'source/xLib/classes/'
_trace_filters = nil
--_trace_filters = {".*"}

require (_xlibroot..'xLib')
require (_xlibroot..'xDebug')
require (_xlibroot.."xPhrase")
require (_xlibroot..'xPhraseManager')
require (_xlibroot..'xNoteColumn') 
require (_xlibroot..'xSelection')

--------------------------------------------------------------------------------
-- variables, helpers
--------------------------------------------------------------------------------

local UI_TABS = {
  INPUT = 1,
  OUTPUT = 2,
  REALTIME = 3,
}

local OUTPUT_SCOPE = {
  SELECTION_IN_PATTERN = 1,
  SELECTION_IN_MATRIX = 2,
  TRACK_IN_PATTERN = 3,
  TRACK_IN_SONG = 4,
}

local PLAYBACK_MODES = {"Off","Prg","Map"}
local PLAYBACK_MODE = {
  PHRASES_OFF = 1,
  PHRASES_PLAY_SELECTIVE = 2,
  PHRASES_PLAY_KEYMAP = 3,
}

local UI_WIDTH = 186
local UI_KEYMAP_LABEL_W = 90
local UI_BUTTON_LG_H = 22

local initialized = false
local modified_lines = {}
local suppress_line_notifier = false

-- int, phrase index when manually set 
local user_set_program = nil

-- keep track of 'ghost notes' thoughout note columns
local ghost_columns = {}

function invoke_task(rslt,err)
  if (rslt == false and err) then
    renoise.app():show_status(err)
  end
end

--------------------------------------------------------------------------------
-- preferences
--------------------------------------------------------------------------------

local options = renoise.Document.create("ScriptingToolPreferences"){}
-- general
options:add_property("active_tab_index",renoise.Document.ObservableNumber(UI_TABS.INPUT))
options:add_property("output_show_collection_report", renoise.Document.ObservableBoolean(true))
-- input
options:add_property("anchor_to_selection", renoise.Document.ObservableBoolean(true))
options:add_property("cont_paste", renoise.Document.ObservableBoolean(true))
options:add_property("skip_muted", renoise.Document.ObservableBoolean(true))
options:add_property("expand_columns", renoise.Document.ObservableBoolean(true))
options:add_property("expand_subcolumns", renoise.Document.ObservableBoolean(true))
options:add_property("mix_paste", renoise.Document.ObservableBoolean(false))
-- output
options:add_property("output_scope", renoise.Document.ObservableNumber(OUTPUT_SCOPE.SELECTION_IN_PATTERN))
--options:add_property("output_skip_duplicates", renoise.Document.ObservableBoolean(true))
options:add_property("output_collect_everything", renoise.Document.ObservableBoolean(false))
options:add_property("output_collect_in_new", renoise.Document.ObservableBoolean(true))
options:add_property("output_replace_collected", renoise.Document.ObservableBoolean(true))
options:add_property("output_create_keymappings", renoise.Document.ObservableBoolean(true))
options:add_property("output_keymap_range", renoise.Document.ObservableNumber(1))
options:add_property("output_keymap_offset", renoise.Document.ObservableNumber(1))
-- realtime
options:add_property("zxx_mode", renoise.Document.ObservableBoolean(false))

renoise.tool().preferences = options

--print("options.output_scope.value",options.output_scope.value)

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
            items = {
              "Selection in Pattern",
              "Selection in Matrix",
              "Track in pattern",
              "Track in song",
            },
            bind = options.output_scope,
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
            vb:checkbox{
              bind = options.output_collect_everything,
            },
            vb:text{
              text = "Collect everything"
            },
          },
          vb:row{
            vb:checkbox{
              bind = options.output_collect_in_new,
            },
            vb:text{
              text = "Collect in new instrument"
            },
          },
          vb:row{
            vb:checkbox{
              bind = options.output_replace_collected,
            },
            vb:text{
              text = "Replace notes with phrase"
            },
          },
          vb:row{
            vb:checkbox{
              bind = options.output_create_keymappings,
            },
            vb:text{
              text = "Create keymap"
            },
          },
          vb:column{
            id = "keymap_options",
            vb:row{
              vb:space{
                width = 20,
              },
              vb:text{
                text = "Semitone range",
                width = UI_KEYMAP_LABEL_W,
              },
              vb:valuebox{
                id = "ui_output_keymap_range",
                bind = options.output_keymap_range,
              }
            },
            vb:row{
              vb:space{
                width = 20,
              },
              vb:text{
                text = "Starting offset",
                width = UI_KEYMAP_LABEL_W,
              },
              vb:valuebox{
                id = "ui_output_keymap_offset",
                min = 0,
                max = 120,
                bind = options.output_keymap_offset,
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
          vb:text{
            text = "These buttons are also accessible"
                .."\nvia keyboard shortcuts and MIDI:",
          },
          vb:row{
            vb:button{
              text = "Prev",
              width = 36,
              height = UI_BUTTON_LG_H,
              notifier = function()
                invoke_task(xPhraseManager.select_previous_phrase())
              end
            },
            vb:button{
              text = "Next",
              width = 36,
              height = UI_BUTTON_LG_H,
              notifier = function()
                invoke_task(xPhraseManager.select_next_phrase())
              end
            },
            vb:space{
              width = 6,
            },
            vb:switch{
              width = 100,
              height = UI_BUTTON_LG_H,
              items = PLAYBACK_MODES,
              notifier = function(idx)
                invoke_task(xPhraseManager.set_playback_mode(idx))
              end
            },
          },
        },
        vb:row{
          style = "group",
          margin = 3,
          width = "100%",
          tooltip = "Insert Zxx commands into the first available effect column when the following conditions are met:"
                  .."\n* Phrase is set to program playback"
                  .."\n* Edit-mode is enabled in Renoise",
          vb:checkbox{
            bind = options.zxx_mode
          },
          vb:text{
            text = "Monitor changes to pattern"
                .."\nand insert Zxx commands as"
                .."\nnotes are entered",
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

end

--------------------------------------------------------------------------------

function ui_update_keymap()
  local active = options.output_create_keymappings.value
  vb.views["ui_output_keymap_range"].active = active
  vb.views["ui_output_keymap_offset"].active = active
end

options.output_create_keymappings:add_notifier(ui_update_keymap)

--------------------------------------------------------------------------------

function ui_show_tab()

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
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:PhraseMate...",
  invoke = function() 
    show_preferences() 
  end
} 

-- input

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Selection:Copy Selection to Phrase (PhraseMate)",
  invoke = function() extract_phrase() end
}

-- output

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Selection:Write Phrase to Selection In Pattern (PhraseMate)",
  invoke = function() 
    invoke_task(apply_phrase_to_selection())
  end
} 

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Track:Write phrase to Track (PhraseMate)",
  invoke = function() 
    invoke_task(apply_phrase_to_track())
  end
} 

--------------------------------------------------------------------------------
-- Keybindings
--------------------------------------------------------------------------------

-- input

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Copy Selection in Pattern to Phrase",
  invoke = function(repeated)
    if (not repeated) then 
      invoke_task(extract_phrase())
    end
  end
}

-- output

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Write Phrase to Selection in Pattern",
  invoke = function(repeated)
    if (not repeated) then 
      invoke_task(apply_phrase_to_selection())
    end
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
  name = "Global:PhraseMate:Select Previous Phrase",
  invoke = function()
    invoke_task(xPhraseManager.select_previous_phrase())
  end
}

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Select Next Phrase",
  invoke = function()
    invoke_task(xPhraseManager.select_next_phrase())
  end
}

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Disable Phrases",
  invoke = function(repeated)
    if (not repeated) then 
      invoke_task(xPhraseManager.set_playback_mode(renoise.Instrument.PHRASES_OFF))
    end
  end
}

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Set to Program Mode",
  invoke = function(repeated)
    if (not repeated) then 
      invoke_task(xPhraseManager.set_playback_mode(renoise.Instrument.PHRASES_PLAY_SELECTIVE))
    end
  end
}

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Set to Keymap Mode",
  invoke = function(repeated)
    if (not repeated) then 
      invoke_task(xPhraseManager.set_playback_mode(renoise.Instrument.PHRASES_PLAY_KEYMAP))
    end
  end
}

--------------------------------------------------------------------------------
-- Input methods
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

-- invoked when pressing the 'collect phrases' button/shortcut
-- @return bool
-- @return string (error message)

function collect_phrases()
  TRACE("collect_phrases()")

  -- table, will contain the indices of created phrases
  local rslt = nil

  local source_instr_idx = renoise.song().selected_instrument_index
  local target_instr_idx = renoise.song().selected_instrument_index
  
  -- clone instrument (create next to original)
  if options.output_collect_in_new.value then
    target_instr_idx = source_instr_idx+1
    local source_instr = rns.instruments[source_instr_idx]
    local target_instr = rns:insert_instrument_at(target_instr_idx)
    target_instr:copy_from(source_instr)
  end

  ghost_columns = {}

  if (options.output_scope.value == OUTPUT_SCOPE.SELECTION_IN_PATTERN) then
    rslt = collect_from_pattern_selection(source_instr_idx,target_instr_idx)
  elseif (options.output_scope.value == OUTPUT_SCOPE.SELECTION_IN_MATRIX) then
    rslt = collect_from_matrix_selection(source_instr_idx,target_instr_idx)
  elseif (options.output_scope.value == OUTPUT_SCOPE.TRACK_IN_PATTERN) then
    rslt = collect_from_track_in_pattern(source_instr_idx,target_instr_idx)
  elseif (options.output_scope.value == OUTPUT_SCOPE.TRACK_IN_SONG) then
    rslt = collect_from_track_in_song(source_instr_idx,target_instr_idx)
  else
    error("Unexpected output scope")
  end


  if (type(rslt)=="table") and (#rslt > 0) then

    -- TODO check for duplicates 
    local duplicates = 0

    -- if cloned instrument, select it
    if options.output_collect_in_new.value then
      rns.selected_instrument_index = target_instr_idx
    end
    -- update selected phrase-index
    --print("rslt",rprint(rslt))
    rns.selected_phrase_index = rslt[#rslt]

    -- show report to user
    if options.output_show_collection_report.value then
      local msg = ("Created %d phrases"):format(#rslt)
      if (duplicates > 0) then
        msg = ("%s (ignored %d duplicates)"):format(msg,duplicates)
      end
      renoise.app():show_message(msg)
    end
    

  end


  return rslt

end

--------------------------------------------------------------------------------
-- @param target_instr_idx (int)
-- @return bool
-- @return string (error message)

function collect_from_pattern_selection(source_instr_idx,target_instr_idx)
  TRACE("collect_from_pattern_selection(source_instr_idx,target_instr_idx)",source_instr_idx,target_instr_idx)

  local patt_sel,err = xSelection.get_pattern_if_single_track()
  if not patt_sel then
    return false,err
  end

  local phrase_idx = create_phrase(source_instr_idx,target_instr_idx,nil,nil,patt_sel)
  return {phrase_idx}

end

--------------------------------------------------------------------------------
-- collect phrases from the matrix selection
-- @param target_instr_idx (int)
-- @return bool
-- @return string (error message)

function collect_from_matrix_selection(source_instr_idx,target_instr_idx)
  TRACE("collect_from_matrix_selection(source_instr_idx,target_instr_idx)",source_instr_idx,target_instr_idx)

  local matrix_sel,err = xSelection.get_matrix_selection()
  if table.is_empty(matrix_sel) then
    return false,"No selection is defined in the matrix"
  end

  local create_keymap = options.output_create_keymappings.value
  local phrase_indices = {}
  for seq_idx = 1, #rns.sequencer.pattern_sequence do
    if matrix_sel[seq_idx] then
      for trk_idx = 1, #rns.tracks do
        if matrix_sel[seq_idx][trk_idx] then
          table.insert(phrase_indices,
            create_phrase(source_instr_idx,target_instr_idx,seq_idx,trk_idx))
        end
      end
    end
  end

  return phrase_indices

end

--------------------------------------------------------------------------------
-- collect phrases from the selected pattern-track 
-- @param target_instr_idx (int)
-- @return bool
-- @return string (error message)

function collect_from_track_in_pattern(source_instr_idx,target_instr_idx)
  TRACE("collect_from_track_in_pattern(source_instr_idx,target_instr_idx)",source_instr_idx,target_instr_idx)

  local phrase_idx = create_phrase(source_instr_idx,target_instr_idx)
  return {phrase_idx}

end

--------------------------------------------------------------------------------
-- collect phrases from the selected track in the song
-- @param target_instr_idx (int)
-- @return bool
-- @return string (error message)

function collect_from_track_in_song(source_instr_idx,target_instr_idx)
  TRACE("collect_from_track_in_song(source_instr_idx,target_instr_idx)",source_instr_idx,target_instr_idx)

  local phrase_indices = {}
  for seq_idx = 1, #rns.sequencer.pattern_sequence do
    table.insert(phrase_indices,
      create_phrase(source_instr_idx,target_instr_idx,seq_idx))
  end

  return phrase_indices

end

--------------------------------------------------------------------------------
-- invoked by the collect_from_xx methods
-- @param target_instr_idx (int)
-- @param seq_idx (int)
-- @param trk_idx (int)
-- @param patt_sel (table), pattern-selection
-- @return int (index of newly created phrase) or nil

function create_phrase(source_instr_idx,target_instr_idx,seq_idx,trk_idx,patt_sel)
  TRACE("create_phrase(source_instr_idx,target_instr_idx,seq_idx,trk_idx,patt_sel)",source_instr_idx,target_instr_idx,seq_idx,trk_idx,patt_sel)

  if not seq_idx then
    seq_idx = rns.selected_sequence_index
  end
  if not trk_idx then
    trk_idx = rns.selected_track_index
  end

  local takeover = true
  local create_keymap = options.output_create_keymappings.value
  local keymap_range = options.output_keymap_range.value
  local keymap_offset = options.output_keymap_offset.value
  local phrase,phrase_idx = xPhraseManager.auto_insert_phrase(target_instr_idx,create_keymap,keymap_range,keymap_offset)
  if phrase then
    if not patt_sel then
      patt_sel = xSelection.get_pattern_track(seq_idx,trk_idx)
    end
    local track = rns.tracks[trk_idx]
    local patt_idx = rns.sequencer:pattern(seq_idx)
    local patt_lines = rns.pattern_iterator:lines_in_pattern_track(patt_idx,trk_idx)
    copy_selected_lines_to_phrase(patt_sel,phrase,patt_lines,source_instr_idx,phrase_idx,trk_idx)
    phrase.name = ("%s : %s"):format(get_pattern_name(seq_idx),get_track_name(trk_idx))
    phrase.volume_column_visible = track.volume_column_visible
    phrase.panning_column_visible = track.panning_column_visible
    phrase.delay_column_visible = track.delay_column_visible
    phrase.sample_effects_column_visible = track.sample_effects_column_visible
    phrase.visible_note_columns = track.visible_note_columns
    phrase.visible_effect_columns = track.visible_effect_columns
  end

  return phrase_idx

end

--------------------------------------------------------------------------------
-- copy over a range of lines to the provided instrument-phrase
-- @param selection (table), pattern-selection
-- @param phrase (InstrumentPhrase)
-- @param patt_lines (iterator:table<PatternLine>)
-- @param source_instr_idx (int) if defined, only include notes from this instr
-- @param phrase_idx (int) 
-- @param trk_idx (int) 

function copy_selected_lines_to_phrase(selection,phrase,patt_lines,source_instr_idx,phrase_idx,trk_idx)
  TRACE("copy_selected_lines_to_phrase(selection,phrase,patt_lines,source_instr_idx,phrase_idx,trk_idx)",selection,phrase,patt_lines,source_instr_idx,phrase_idx,trk_idx)

  phrase.number_of_lines = 1 + selection.end_line - selection.start_line
  for pos, line in patt_lines do
    if pos.line > selection.end_line then break end
    if pos.line >= selection.start_line then
      if not line.is_empty then
        local phrase_line_idx = pos.line - (selection.start_line-1)
        if options.output_collect_everything.value then
          local phrase_line = phrase:line(phrase_line_idx)
          phrase_line:copy_from(line)
          if options.output_replace_collected.value then
            line:clear()
          end

        elseif source_instr_idx then   
          --print("pos,source_instr_idx",pos,source_instr_idx)

          for note_col_idx,note_col in ipairs(line.note_columns) do
            --print("note_col",note_col)
            local phrase_col = phrase:line(phrase_line_idx).note_columns[note_col_idx]

            --print("phrase_col",phrase_col)

            -- maintain ghost columns
            if (note_col.instrument_value < 255) then
              ghost_columns[note_col_idx] = note_col.instrument_value+1
            elseif (note_col.note_value == renoise.PatternLine.NOTE_OFF) then
              table.remove(ghost_columns,note_col_idx)
            end
            --print("ghost_columns",rprint(ghost_columns))

            -- we have a note - ghost or actual
            if (ghost_columns[note_col_idx] == source_instr_idx) then

              -- skip if triggering phrase
              local is_phrase_trigger = xPhrase.note_is_phrase_trigger(line,note_col_idx,source_instr_idx,trk_idx)
              --print(">>> is_phrase_trigger",is_phrase_trigger)
              if not is_phrase_trigger then
                phrase_col:copy_from(note_col)
                
                if options.output_replace_collected.value then
                  note_col:clear()
                end
              end

            end

          end

          for fx_col_idx,fx_col in ipairs(line.effect_columns) do
            local phrase_col = phrase:line(phrase_line_idx).effect_columns[fx_col_idx]
              phrase_col:copy_from(fx_col)
              if options.output_replace_collected.value then
                fx_col:clear()
              end
          end

        else
          error("Should not get here")
        end
      end
    end
  end

  xPhrase.clear_foreign_commands(phrase)

  if options.output_replace_collected.value then
    if not phrase.is_empty then
      for k,v in patt_lines do
        local trigger_note_col = v.note_columns[1]
        local trigger_fx_col = v.effect_columns[1]
        trigger_note_col.instrument_value = source_instr_idx-1
        trigger_note_col.note_string = "C-4"
        trigger_fx_col.number_string = "0Z"
        trigger_fx_col.amount_value = phrase_idx
        break
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
    return false,"ApplyPhrase will not work without a selected phrase"
  end

  suppress_line_notifier = true

  local track = renoise.song().selected_track
  local ptrack = renoise.song().selected_pattern_track
  
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

  local sel = renoise.song().selection_in_pattern
  return apply_phrase_to_track(sel.start_column,sel.end_column,sel.start_line,sel.end_line)

end

--------------------------------------------------------------------------------
-- Realtime methods
--------------------------------------------------------------------------------

function line_notifier_fn(pos)
  if not suppress_line_notifier then
    table.insert(modified_lines,pos)
  end
end

--------------------------------------------------------------------------------

function handle_modified_line(pos)

  local patt = rns.patterns[pos.pattern]
  local ptrack = patt:track(pos.track)
  local line = ptrack:line(pos.line)
  local instr = rns.selected_instrument
  local has_phrases = (#instr.phrases > 0)
  local program_mode = (instr.phrase_playback_mode == renoise.Instrument.PHRASES_PLAY_SELECTIVE)

  local zxx_command = nil
  local matching_note = nil

  for k,note_col in ipairs(line.note_columns) do
    if (note_col.instrument_value == rns.selected_instrument_index-1) then
      matching_note = {
        note_column_index = k,
      }
      break
    end
  end

  for k,fx_col in ipairs(line.effect_columns) do
    if (fx_col.number_string == "0Z") then
      zxx_command = {
        effect_column_index = k,
      }
      break
    end
  end

  --print("matching_note",rprint(matching_note))
  --print("zxx_command",rprint(zxx_command))

  if matching_note and has_phrases and program_mode then

    -- add Zxx command

    for k,fx_col in ipairs(line.effect_columns) do
      local has_zxx_command = (fx_col.number_string == "0Z")
      if has_zxx_command then
        local where_we_were = rns.transport.edit_pos.line - rns.transport.edit_step
        if (pos.line == where_we_were) then
          local num_phrases = #rns.selected_instrument.phrases
          rns.selected_phrase_index = user_set_program or math.min(num_phrases,fx_col.amount_value)
          fx_col.number_string = "0Z"
          fx_col.amount_value = rns.selected_phrase_index
        else
          --print("got here")
        end
        break
      elseif fx_col.is_empty then
        fx_col.number_string = "0Z"
        fx_col.amount_value = rns.selected_phrase_index
        break
      end
    end

  elseif not matching_note and zxx_command then

    -- clear Zxx command

    if zxx_command.note_column_index then
      --line.note_columns[zxx_command.note_column_index].effect_amount_value = 0
      --line.note_columns[zxx_command.note_column_index].effect_number_value = 0
    elseif zxx_command.effect_column_index then
      line.effect_columns[zxx_command.effect_column_index].amount_value = 0
      line.effect_columns[zxx_command.effect_column_index].number_value = 0
    end
  end

end

--------------------------------------------------------------------------------
--[[
function phrase_playback_mode_handler()
  print("phrase_playback_mode_handler")

end

--------------------------------------------------------------------------------

function attach_to_instrument()

  local instr = rns.selected_instrument

  if not instr.phrase_playback_mode_observable:has_notifier(phrase_playback_mode_handler) then
    instr.phrase_playback_mode_observable:add_notifier(phrase_playback_mode_handler)
  end

end

--------------------------------------------------------------------------------

function detach_from_instrument()

  local instr = rns.selected_instrument

  if instr.phrase_playback_mode_observable:has_notifier(phrase_playback_mode_handler) then
    instr.phrase_playback_mode_observable:remove_notifier(phrase_playback_mode_handler)
  end

end
]]

--------------------------------------------------------------------------------

function attach_to_pattern()

  modified_lines = {}

  local pattern = rns.selected_pattern

  if not pattern:has_line_notifier(line_notifier_fn) then
    pattern:add_line_notifier(line_notifier_fn)
  end

end

--------------------------------------------------------------------------------

function detach_from_pattern()

  local pattern = rns.selected_pattern

  if pattern:has_line_notifier(line_notifier_fn) then
    pattern:remove_line_notifier(line_notifier_fn)
  end

end

--------------------------------------------------------------------------------
--[[
function phrase_notifier()

  user_set_program = rns.selected_phrase_index
  print("user_set_program 1",user_set_program)

end
]]
--------------------------------------------------------------------------------

function attach_to_song()

  if not rns.selected_pattern_observable:has_notifier(attach_to_pattern) then
    rns.selected_pattern_observable:add_notifier(attach_to_pattern)
  end
  attach_to_pattern()
  
  --[[
  if not rns.selected_instrument_observable:has_notifier(attach_to_instrument) then
    rns.selected_instrument_observable:add_notifier(attach_to_instrument)
  end
  attach_to_instrument()
  ]]

end


--------------------------------------------------------------------------------

function detach_from_song()

  if rns.selected_pattern_observable:has_notifier(attach_to_pattern) then
    rns.selected_pattern_observable:remove_notifier(attach_to_pattern)
  end
  detach_from_pattern()

  --[[
  if rns.selected_instrument_observable:has_notifier(attach_to_instrument) then
    rns.selected_instrument_observable:remove_notifier(attach_to_instrument)
  end
  detach_from_instrument()
  ]]

end

--------------------------------------------------------------------------------

local zxx_mode_handler = function()
  if options.zxx_mode.value then
    attach_to_song()
  else
    detach_from_song()
  end
end
options.zxx_mode:add_notifier(zxx_mode_handler)

--------------------------------------------------------------------------------
-- notifications
--------------------------------------------------------------------------------

renoise.tool().app_idle_observable:add_notifier(function()

  if not initialized and rns then
    zxx_mode_handler()
    initialized = true
  end

  if (#modified_lines > 0) then
    if rns.transport.edit_mode then
      for k,v in ipairs(modified_lines) do
        handle_modified_line(v)
      end
    end
    modified_lines = {}
    user_set_program = nil
    --print("user_set_program 2",user_set_program)
  end

end)

--------------------------------------------------------------------------------

renoise.tool().app_new_document_observable:add_notifier(function()
  TRACE("*** app_new_document_observable fired...")

  rns = renoise.song()

end)

--------------------------------------------------------------------------------

