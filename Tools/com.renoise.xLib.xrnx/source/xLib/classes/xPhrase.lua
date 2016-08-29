--[[============================================================================
xPhrase
============================================================================]]--

--[[--

Static methods for dealing with renoise.Phrase objects
.
#

]]

class 'xPhrase'

--==============================================================================

--- replace sample indices in the provided phrase 
-- @param phrase (renoise.InstrumentPhrase)
-- @param idx_from (int)
-- @param idx_to (int)

function xPhrase.replace_sample_index(phrase,idx_from,idx_to)
  TRACE("xLib.replace_sample_index(phrase,idx_from,idx_to)",phrase,idx_from,idx_to)

  if not phrase.instrument_column_visible then
    return
  end

  idx_from = idx_from-1
  idx_to = idx_to-1

  local phrase_lines = phrase:lines_in_range(1,phrase.number_of_lines)
  --print("phrase_lines",#phrase_lines,phrase_lines)
  for k2, phrase_line in ipairs(phrase_lines) do
    for k3, note_col in ipairs(phrase_line.note_columns) do
      -- skip hidden note column 
      if (k3 <= phrase.visible_note_columns) then
        if (note_col.instrument_value == idx_from) then
          note_col.instrument_value = idx_to
          --print("replaced sample index",k2,k3,idx_from,idx_to)
        end
      end
    end
  end

end

--------------------------------------------------------------------------------
-- check if note is referring to keymapped phrase
-- @param note (int)
-- @param instr (renoise.Instrument) or table containing 'note_range'
-- @return bool

function xPhrase.note_is_keymapped(note,instr)
  TRACE("xPhrase.note_is_keymapped(note,instr)",note,instr)

  for k,v in ipairs(instr.phrase_mappings) do
    --print("note_range",v.note_range[1],v.note_range[2])
    if (note >= v.note_range[1]) and (note <= v.note_range[2]) then
      return true
    end
  end
  return false

end

--------------------------------------------------------------------------------
-- remove commands that does not belong in a phrase
-- @param phrase (renoise.InstrumentPhrase)

function xPhrase.clear_foreign_commands(phrase)
  TRACE("xPhrase.clear_foreign_commands(phrase)",phrase)

  if phrase.is_empty then
    return
  end

  local blacklist = {
    "0Z",                         -- phrase index
    "ZT","ZL","ZK","ZG","ZB","ZD" -- global commands
  }
  
  for k,v in ipairs(phrase.lines) do
    --print("k,v",k,v)
    if phrase.sample_effects_column_visible then
      for note_col_idx,note_col in ipairs(v.note_columns) do
        if (table.find(blacklist,note_col.effect_number_string)) then
          note_col.effect_number_string = "00"
          note_col.effect_amount_string = "00"
        end
      end
    end
    for fx_col_idx,fx_col in ipairs(v.effect_columns) do
      if (fx_col_idx > phrase.visible_effect_columns) then
        break
      elseif (table.find(blacklist,fx_col.number_string)) then
        fx_col.number_string = "00"
        fx_col.amount_string = "00"
      end
    end

  end

end

--------------------------------------------------------------------------------
-- create a string representation of the phrase
-- @param phrase renoise.InstrumentPhrase
-- @return string

function xPhrase.stringify(phrase)
  TRACE("xPhrase.stringify",phrase)

  if phrase.is_empty then
    return ""
  end

  local rslt = {}
  for k,v in ipairs(phrase.lines) do
    table.insert(rslt,tostring(v))
  end

  --print("*** stringify - rslt",rprint(rslt))
  return table.concat(rslt,"\n")

end

--------------------------------------------------------------------------------
-- write phrase to (part of) the indicated pattern-track 
-- @param options (table)
--  {
--    instr_index = int,
--    phrase = InstrumentPhrase,
--    anchor_to_selection = bool,
--    expand_subcolumns = bool,
--    cont_paste = bool,
--    mix_paste = bool,
--    selection = table, -- Pattern-selection (xSelection)
--  }

function xPhrase.apply_to_track(options)
  TRACE("xPhrase.apply_to_track(options)",options)

  assert(type(options)=="table")
  assert(type(options.instr_index)=="number")
  assert(type(options.phrase)=="InstrumentPhrase")
  assert(type(options.anchor_to_selection)=="boolean")
  assert(type(options.expand_subcolumns)=="boolean")
  assert(type(options.cont_paste)=="boolean")
  assert(type(options.mix_paste)=="boolean")
  assert(type(options.selection)=="table")

  local track = rns.tracks[options.selection.start_track]

  if not track then
    return false,"The track doesn't exist"
  end

  -- TODO support other track types
  if (track.type ~= renoise.Track.TRACK_TYPE_SEQUENCER) then
    return false,"Can only write to sequencer-tracks"
  end

  local sel = options.selection
  local ptrack = rns.selected_pattern_track
  local start_note_col,end_note_col
  local start_fx_col,end_fx_col
  --local restrict_to_selection = options.selection
  --[[
  if not start_column then
    -- supply defaults
    start_line = 1
    start_note_col = 1
    start_fx_col = 1
    end_line = #ptrack.lines
    end_note_col = phrase.visible_note_columns
    end_fx_col = phrase.visible_effect_columns
  else
    -- validate start/end column
    if (start_column <= track.visible_note_columns) then
      start_note_col = start_column
      start_fx_col = 1
    else
      start_note_col = nil
      start_fx_col = start_column - phrase.visible_note_columns
    end
    if (end_column <= phrase.visible_note_columns) then
      start_fx_col = nil
      end_note_col = end_column
    else 
      end_note_col = start_column + phrase.visible_note_columns - 1
      end_fx_col = end_column - phrase.visible_note_columns
    end
  end
  ]]

  print("sel",rprint(sel))
  print("track",track)

  -- validate start/end column
  if (sel.start_column <= track.visible_note_columns) then
    start_note_col = sel.start_column
    start_fx_col = 1
  else
    start_note_col = nil
    start_fx_col = sel.start_column - options.phrase.visible_note_columns
  end
  if (sel.end_column <= options.phrase.visible_note_columns) then
    start_fx_col = nil
    end_note_col = sel.end_column
  else 
    end_note_col = sel.start_column + options.phrase.visible_note_columns - 1
    end_fx_col = sel.end_column - options.phrase.visible_note_columns
  end

  -- produce output
  
  local num_lines = sel.end_line - sel.start_line
  local phrase_num_lines = options.phrase.number_of_lines

  for i = 1,num_lines do

    local source_line_idx = i

    if not options.cont_paste then
      if (i > phrase_num_lines) then
        break
      end
    else
      if options.anchor_to_selection then
        source_line_idx = i % phrase_num_lines
      else
        source_line_idx = (sel.start_line+i-1) % phrase_num_lines
      end
      if (source_line_idx == 0) then
        source_line_idx = phrase_num_lines
      end
    end
    
    local source_line = options.phrase:line(source_line_idx)
    local target_line = ptrack:line(sel.start_line+i-1)
   
    if start_note_col then
      local col_count = 0
      for col_idx = 1,renoise.InstrumentPhrase.MAX_NUMBER_OF_NOTE_COLUMNS do
        if (col_idx >= start_note_col) and
          (col_idx <= end_note_col) 
        then

          col_count = col_count + 1
          local skip_column = (options.phrase:column_is_muted(col_count)
            and options.skip_muted) or false

          if not skip_column then

            local source_col = source_line:note_column(col_count)
            local target_col = target_line:note_column(col_idx)

            -- note
            if (source_col.note_value < 121) then
              target_col.note_value = source_col.note_value
            elseif not options.mix_paste then
              target_col.note_value = 121
            end

            -- instrument 
            if (source_col.note_value < 121) then
              target_col.instrument_value = options.instr_index-1
            elseif not options.mix_paste then
              target_col.note_value = 121
            end

            -- volume
            if options.phrase.volume_column_visible then
              if (source_col.volume_value ~= 255) then
                target_col.volume_value = source_col.volume_value
                if options.expand_subcolumns then
                  track.volume_column_visible = true
                end
              elseif not options.mix_paste then
                target_col.volume_value = 255
              end          
            end          
  
            -- panning
            if options.phrase.panning_column_visible then
              if (source_col.panning_value ~= 255) then
                target_col.panning_value = source_col.panning_value
                if options.expand_subcolumns then
                  track.panning_column_visible = true
                end
              elseif not options.mix_paste then
                target_col.panning_value = 255
              end      
            end      
            
            -- delay
            if options.phrase.delay_column_visible then
              if (source_col.delay_value > 0) then
                target_col.delay_value = source_col.delay_value
                if options.expand_subcolumns then
                  track.delay_column_visible = true
                end
              elseif not options.mix_paste then
                target_col.delay_value = 0
              end          
            end          
  
            -- sample effects
            if options.phrase.sample_effects_column_visible then
              if (source_col.effect_amount_value > 0) then
                target_col.effect_amount_value = source_col.effect_amount_value
                if options.expand_subcolumns then
                  track.sample_effects_column_visible = true
                end
              elseif not options.mix_paste then
                target_col.effect_amount_value = 0
              end          
              if (source_col.effect_number_value > 0) then
                target_col.effect_number_value = source_col.effect_number_value
                if options.expand_subcolumns then
                  track.sample_effects_column_visible = true
                end
              elseif not options.mix_paste then
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
            if not options.mix_paste then
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
          elseif not options.mix_paste then
            target_col.amount_value = 0
          end          
          if (source_col.number_value > 0) then
            target_col.number_value = source_col.number_value
          elseif not options.mix_paste then
            target_col.number_value = 0
          end 

          col_count = col_count + 1

        end
      end
    end

  end
  
  return true

end

