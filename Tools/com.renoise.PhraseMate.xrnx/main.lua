--[[============================================================================
com.renoise.PhraseMate.xrnx/main.lua
============================================================================]]--
--[[

  PhraseMate aims to make it more convenient to work with phrases in the
  pattern editor. Define the behavior of the tool by launching it from
  the tool menu, or use the keyboard shortcuts to produce output
  (search for 'PhraseMate' in Renoise preferences > keys)

]]

--------------------------------------------------------------------------------
-- variables, helpers
--------------------------------------------------------------------------------

local initialized = false
local modified_lines = {}
local suppress_line_notifier = false
local suppress_phrase_notifier = false
local user_set_program = nil

function invoke_task(rslt,err)
  if (rslt == false) then
    renoise.app():show_status(err)
  end
end

--------------------------------------------------------------------------------
-- preferences
--------------------------------------------------------------------------------

local options = renoise.Document.create("ScriptingToolPreferences"){}
options:add_property("anchor_to_selection", renoise.Document.ObservableBoolean(true))
options:add_property("cont_paste", renoise.Document.ObservableBoolean(true))
options:add_property("skip_muted", renoise.Document.ObservableBoolean(true))
options:add_property("expand_columns", renoise.Document.ObservableBoolean(true))
options:add_property("expand_subcolumns", renoise.Document.ObservableBoolean(true))
options:add_property("mix_paste", renoise.Document.ObservableBoolean(false))
options:add_property("zxx_mode", renoise.Document.ObservableBoolean(false))

renoise.tool().preferences = options

--------------------------------------------------------------------------------
-- user interface
--------------------------------------------------------------------------------

local vb,dialog,dialog_content

function show_preferences()

  if dialog and dialog.visible then
    
    dialog:show()

  else

    vb = renoise.ViewBuilder()
    dialog_content = vb:column{
      margin = 6,
      spacing = 6,
      vb:text{
        text="Hover over for more info",
      },

      vb:column{
        style = "group",
        margin = 6,
        vb:row{
        },
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
      vb:column{
        vb:row{
          tooltip = "Insert Zxx commands into the first available effect column when the following conditions are met:"
                  .."\n* Phrase is set to program playback"
                  .."\n* Edit-mode is enabled in Renoise",
          vb:checkbox{
            bind = options.zxx_mode
          },
          vb:text{
            text = "Monitor pattern and"
                .."\ninsert Zxx commands",
          },
        },
      },
    }

    local keyhandler = nil

    dialog = renoise.app():show_custom_dialog(
      "PhraseMate", dialog_content, keyhandler)

  end

end

--------------------------------------------------------------------------------
-- tool setup
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:PhraseMate...",
  invoke = function() 
    show_preferences() 
  end
} 

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Selection:Write Phrase to Selection (PhraseMate)...",
  invoke = function() 
    invoke_task(apply_phrase_to_selection())
  end
} 

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Track:Write Phrase to Track (PhraseMate)...",
  invoke = function() 
    invoke_task(apply_phrase_to_track())
  end
} 

renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Write phrase to selection...",
  invoke = function(repeated)
    if (not repeated) then 
      invoke_task(apply_phrase_to_selection())
    end
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Write Phrase to Track...",
  invoke = function(repeated)
    if (not repeated) then 
      invoke_task(apply_phrase_to_track())
    end
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Select Previous Phrase",
  invoke = function()
    invoke_task(select_previous_phrase())
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Select Next Phrase",
  invoke = function()
    invoke_task(select_next_phrase())
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Capture Phrase From Pattern",
  invoke = function()
    invoke_task(capture_phrase_index())
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Disable Phrases",
  invoke = function(repeated)
    if (not repeated) then 
      invoke_task(set_mode(renoise.Instrument.PHRASES_OFF))
    end
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Set to Program Mode",
  invoke = function(repeated)
    if (not repeated) then 
      invoke_task(set_mode(renoise.Instrument.PHRASES_PLAY_SELECTIVE))
    end
  end
}
renoise.tool():add_keybinding {
  name = "Global:PhraseMate:Set to Keymap Mode",
  invoke = function(repeated)
    if (not repeated) then 
      invoke_task(set_mode(renoise.Instrument.PHRASES_PLAY_KEYMAP))
    end
  end
}


--------------------------------------------------------------------------------
-- main 
--------------------------------------------------------------------------------

-- @param start_col - note/effect column index
-- @param end_col - note/effect column index
-- @param start_line - pattern line
-- @param end_line - pattern line

function apply_phrase_to_track(start_col,end_col,start_line,end_line)

  local rns = renoise.song()  
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
                if options.expand_subcolumns then
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
                if options.expand_subcolumns then
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
                if options.expand_subcolumns then
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
                if options.expand_subcolumns then
                  track.sample_effects_column_visible = true
                end
              elseif not options.mix_paste.value then
                target_col.effect_amount_value = 0
              end          
              if (source_col.effect_number_value > 0) then
                target_col.effect_number_value = source_col.effect_number_value
                if options.expand_subcolumns then
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

  local sel = renoise.song().selection_in_pattern

  if not sel then
    return false, "No selection is defined in the pattern"
  end
  
  if (sel.start_track ~= sel.end_track) then
    return false, "The selection needs to fit within a single track"
  end
  
  return apply_phrase_to_track(sel.start_column,sel.end_column,sel.start_line,sel.end_line)

end

--------------------------------------------------------------------------------
-- capture the phrase index specified at the selected line

function capture_phrase_index()

  local rns = renoise.song()
  local line = rns.selected_line
  local track = rns.selected_track
  local ptrack = rns.selected_pattern_track

  local search_line = function(ptrack,line) 
    for k,fx_col in ipairs(line.effect_columns) do
      if (k <= track.visible_effect_columns) then
        if (fx_col.number_string == "0Z") then
          local num_phrases = #rns.selected_instrument.phrases
          return math.min(num_phrases,fx_col.amount_value)
        end
      else
        break
      end
    end
  end

  -- start search at current line, then move backwards
  for line_idx = rns.selected_line_index, 1, -1 do
    local line = ptrack:line(line_idx)
    local matched_index = search_line(ptrack,line) 
    if matched_index then
      rns.selected_phrase_index = matched_index
      return
    end
  end

end

--------------------------------------------------------------------------------

function select_next_phrase()

  local rns = renoise.song()
  local phrase = rns.selected_phrase
  if not phrase then
    return false, "No phrase is selected"
  end
  
  local phrase_idx = renoise.song().selected_phrase_index
  if (phrase_idx > 1) then
    renoise.song().selected_phrase_index = phrase_idx - 1 
  end

end

--------------------------------------------------------------------------------

function select_previous_phrase()

  local rns = renoise.song()
  local phrase = rns.selected_phrase
  if not phrase then
    return false, "No phrase is selected"
  end
  
  local phrase_idx = renoise.song().selected_phrase_index
  if (phrase_idx > 1) then
    rns.selected_phrase_index = phrase_idx - 1 
  end

end

--------------------------------------------------------------------------------

function select_next_phrase()

  local rns = renoise.song()
  local phrase = rns.selected_phrase
  if not phrase then
    return false, "No phrase is selected"
  end
  
  local phrase_idx = rns.selected_phrase_index
  local num_phrases = #rns.selected_instrument.phrases
  if (phrase_idx < num_phrases) then
    rns.selected_phrase_index = phrase_idx + 1 
  end

end

--------------------------------------------------------------------------------

function set_mode(mode)
  
  local rns = renoise.song()
  local phrase = rns.selected_phrase
  if not phrase then
    return false, "No phrase is selected"
  end

  if (rns.selected_instrument.phrase_playback_mode == mode) then
    rns.selected_instrument.phrase_playback_mode = renoise.Instrument.PHRASES_OFF
  else
    rns.selected_instrument.phrase_playback_mode = mode
  end

end

--------------------------------------------------------------------------------

function line_notifier_fn(pos)
  if not suppress_line_notifier then
    table.insert(modified_lines,pos)
  end
end

--------------------------------------------------------------------------------

function handle_modified_line(pos)

  local rns = renoise.song()
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
          suppress_phrase_notifier = true
          rns.selected_phrase_index = user_set_program or math.min(num_phrases,fx_col.amount_value)
          suppress_phrase_notifier = false
          fx_col.number_string = "0Z"
          fx_col.amount_value = rns.selected_phrase_index
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
      -- do nothing
    elseif zxx_command.effect_column_index then
      line.effect_columns[zxx_command.effect_column_index].amount_value = 0
      line.effect_columns[zxx_command.effect_column_index].number_value = 0
    end
  end

end

--------------------------------------------------------------------------------

function attach_to_pattern()

  modified_lines = {}

  local rns = renoise.song()
  local pattern = rns.selected_pattern

  if not pattern:has_line_notifier(line_notifier_fn) then
    pattern:add_line_notifier(line_notifier_fn)
  end

end

--------------------------------------------------------------------------------

function detach_from_pattern()

  local rns = renoise.song()
  local pattern = rns.selected_pattern

  if pattern:has_line_notifier(line_notifier_fn) then
    pattern:remove_line_notifier(line_notifier_fn)
  end

end


--------------------------------------------------------------------------------

function phrase_notifier()

  if suppress_phrase_notifier then
    return
  end

  local rns = renoise.song()
  user_set_program = rns.selected_phrase_index
  --print(">>> user_set_program",user_set_program)
  
end

--------------------------------------------------------------------------------

function attach_to_song()

  local rns = renoise.song()

  if not rns.selected_pattern_observable:has_notifier(attach_to_pattern) then
    rns.selected_pattern_observable:add_notifier(attach_to_pattern)
  end
  attach_to_pattern()

  if not rns.selected_phrase_observable:has_notifier(phrase_notifier) then
    rns.selected_phrase_observable:add_notifier(phrase_notifier)
  end
  
end


--------------------------------------------------------------------------------

function detach_from_song()

  local rns = renoise.song()
  if rns.selected_pattern_observable:has_notifier(attach_to_pattern) then
    rns.selected_pattern_observable:remove_notifier(attach_to_pattern)
  end
  detach_from_pattern()

  if not rns.selected_phrase_observable:has_notifier(phrase_notifier) then
    rns.selected_phrase_observable:add_notifier(phrase_notifier)
  end

end

--------------------------------------------------------------------------------
-- handle zxx mode
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
-- idle notifier
--------------------------------------------------------------------------------

renoise.tool().app_idle_observable:add_notifier(function()

  local rns = renoise.song()
  if not initialized and rns then
    zxx_mode_handler()
    user_set_program = rns.selected_phrase_index
    initialized = true
  end

  if (#modified_lines > 0) then
    if rns.transport.edit_mode then
      for k,v in ipairs(modified_lines) do
        handle_modified_line(v)
      end
    end
    modified_lines = {}
  end

end)


