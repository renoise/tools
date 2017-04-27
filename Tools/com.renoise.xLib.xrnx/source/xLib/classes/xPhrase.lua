--[[============================================================================
xPhrase
============================================================================]]--

--[[--

Static methods for dealing with renoise.Phrase objects
.
#

TODO
  turn tonumber/string conversions into standard cLib methods
  percentage: cNumber.string_to_percentage / percentage_to_string

]]

require(_clibroot.."cDocument")
require(_clibroot..'cFilesystem')
require(_xlibroot.."xNoteColumn")
require(_xlibroot.."xTrack")


class 'xPhrase' (cDocument)

xPhrase.KEY_TRACKING = {
  NONE = 1,
  TRANSPOSE = 2,
  OFFSET = 3,
}

xPhrase.ERROR = {
  MISSING_INSTRUMENT = 1,
  MISSING_PHRASE = 2,
  FILE_EXISTS = 3,
}

xPhrase.DOC_PROPS = {
  {
    name = "name",
    title = "Name",
    value_default = "",
  },
  --mapping = "string",
  --is_empty = "boolean",
  {
    name = "number_of_lines",
    title = "Number of lines",
    value_default = 32,
    value_min = 1,
    value_max = 512,
    value_quantum = 1,
  },
  --lines
  { 
    name = "visible_note_columns",
    title = "Visible note-columns",
    value_min = 1,
    value_max = 12,
    value_quantum = 1,
    value_default = 4,
  },
  {
    name = "visible_effect_columns",
    title = "Visible effect-columns",
    value_min = 0,
    value_max = 8,
    value_quantum = 1,
    value_default = 1,
  },
  {
    name = "key_tracking",
    title = "Key-tracking",
    value_min = xPhrase.KEY_TRACKING.NONE,
    value_max = xPhrase.KEY_TRACKING.OFFSET,
    value_quantum = 1,
    value_default = xPhrase.KEY_TRACKING.TRANSPOSE,
    value_enums = {"None","Transpose","Offset"},
  },
  {
    name = "base_note",
    title = "Base-note",
    value_min = 0,
    value_max = 119,
    value_quantum = 1,
    value_default = 48, -- C-4
    value_tostring = function(val)
      return xNoteColumn.note_value_to_string(val)    
    end,
    value_tonumber = function(val)
      return xNoteColumn.note_string_to_value(val)
    end,
  },
  {
    name = "looping",
    title = "Looping",
    value_default = true,
  },
  {
    name = "loop_start",
    title = "Loop-start",
    value_min = 0,
    value_max = 511,
    value_quantum = 1,
    value_default = 0,
    zero_based = true,
  },
  {
    name = "loop_end",
    title = "Loop-end",
    value_min = 1, 
    value_max = 512, 
    value_quantum = 1,
    value_default = 32,
    zero_based = true,
  },
  {
    name = "autoseek",
    title = "Autoseek",
    value_default = true,
  },
  {
    name = "lpb",
    title = "LPB",
    value_min = 1,
    value_max = 256,
    value_quantum = 1,
    value_default = 4,
  },
  {
    name = "shuffle",
    title = "Shuffle",
    value_min = 0,
    value_max = 1,
    value_default = 0.0,
    value_tostring = function(val)
      return ("%.0f %%"):format(val*100)
    end,
    value_tonumber = function(val)
      return tonumber(string.match(val,"%d*"))/100
    end,
    value_factor = 100,
  },
  {
    name = "instrument_column_visible",
    title = "Instrument-column visible",
    value_default = true,
  },
  {
    name = "volume_column_visible",
    title = "Volume-column visible",
    value_default = false,
  },
  {
    name = "panning_column_visible",
    title = "Panning-column visible",
    value_default = false,
  },
  {
    name = "delay_column_visible",
    title = "Delay-column visible",
    value_default = false,
  },
  {
    name = "sample_effects_column_visible",
    title = "Sample-effects-column visible",
    value_default = true,
  },

}


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
  for k2, phrase_line in ipairs(phrase_lines) do
    for k3, note_col in ipairs(phrase_line.note_columns) do
      -- skip hidden note column 
      if (k3 <= phrase.visible_note_columns) then
        if (note_col.instrument_value == idx_from) then
          note_col.instrument_value = idx_to
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
    if xSampleMapping.within_note_range(note,v) then
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

  return table.concat(rslt,"\n")

end

--------------------------------------------------------------------------------
-- write phrase to (part of) the indicated pattern-track 
-- @param options (table)

function xPhrase.apply_to_track(options)
  TRACE("xPhrase.apply_to_track(options)",options)

  assert(type(options)=="table")
  assert(type(options.instr_index)=="number")
  assert(type(options.phrase)=="InstrumentPhrase")
  assert(type(options.sequence_index)=="number")
  assert(type(options.track_index)=="number")
  --assert(type(options.selection)=="table")
  assert(type(options.anchor_to_selection)=="boolean")
  assert(type(options.cont_paste)=="boolean")
  assert(type(options.skip_muted)=="boolean")
  assert(type(options.expand_columns)=="boolean")
  assert(type(options.expand_subcolumns)=="boolean")
  assert(type(options.insert_zxx)=="boolean")
  assert(type(options.mix_paste)=="boolean")

  local track = rns.tracks[options.track_index]
  if not track then
    return false,"The track doesn't exist"
  end

  local ptrack = xTrack:get_pattern_track(options.sequence_index,options.track_index)

  -- TODO support other track types
  if (track.type ~= renoise.Track.TRACK_TYPE_SEQUENCER) then
    return false,"Can only write to sequencer-tracks"
  end

  local apply_to_selection = (options.selection) and true or false
  local sel = options.selection
  local start_note_col,end_note_col
  local start_fx_col,end_fx_col

  -- when selection is missing, span the entire track
  if not sel then
    sel = xSelection.get_pattern_track(options.sequence_index,options.track_index)
    if options.expand_columns then
      -- if we should expand columns, assume the size
      -- of the original phrase instead of the selection
      local total_phrase_columns = options.phrase.visible_note_columns + options.phrase.visible_effect_columns
      sel.end_column = sel.start_column + total_phrase_columns - 1
    end
  end

  -- restrict start/end column
  if (sel.start_column <= track.visible_note_columns) then
    start_note_col = sel.start_column
    start_fx_col = 1
  else 
    start_note_col = nil
    start_fx_col = sel.start_column - track.visible_note_columns
  end

  if (sel.end_column <= track.visible_note_columns) then
    start_fx_col = nil
    end_note_col = sel.end_column
  else 
    end_note_col = sel.start_column + options.phrase.visible_note_columns - 1
    end_fx_col = sel.end_column - (track.visible_note_columns + (start_note_col and 1 or 0))
  end

  -- produce output
  
  local num_lines = sel.end_line - sel.start_line + 1
  local phrase_num_lines = options.phrase.number_of_lines

  local fully_looped = options.phrase.looping 
    and ((options.phrase.loop_start > 1)
    or ((options.phrase.loop_end-1) < options.phrase.number_of_lines))

  for i = 1,num_lines do

    local source_line_idx = i

    -- support loop points in source phrase
    local get_line_index = function(idx)
      if fully_looped then
        if (idx < options.phrase.loop_end) then
          return idx -- not yet looped
        else
          local range = options.phrase.loop_end-options.phrase.loop_start
          local rslt = (idx-options.phrase.loop_start) % range
          rslt = rslt + options.phrase.loop_start
          return rslt 
        end
      else -- fully encompassing loop
        return idx % phrase_num_lines
      end
    end

    if not options.cont_paste then
      if (i > phrase_num_lines) then
        break
      end
    else
      if options.anchor_to_selection then
        source_line_idx = get_line_index(i)-- % phrase_num_lines
      else
        source_line_idx = get_line_index(sel.start_line+i-1) -- % phrase_num_lines
      end
      if (source_line_idx == 0) then
        source_line_idx = phrase_num_lines
      end
    end
    
    local source_line = options.phrase:line(source_line_idx)
    local target_line = ptrack:line(sel.start_line+i-1)
   
    local high_note_col = track.visible_note_columns
    local high_fx_col = track.visible_effect_columns

    local function get_start_index(col_idx)
      return options.anchor_to_selection and start_fx_col or 1
    end

    local function get_column_offset(col_idx)
      return not options.anchor_to_selection and (col_idx-1) or 0
    end

    -- note columns
    local contains_note = false
    if start_note_col then
      local col_count = 0
      local start_index = get_start_index(start_note_col)
      local column_offset = get_column_offset(start_note_col)
      for col_idx = start_index,renoise.InstrumentPhrase.MAX_NUMBER_OF_NOTE_COLUMNS do
        if (col_idx >= start_note_col) and
          (col_idx <= end_note_col) 
        then

          col_count = col_count + 1
          local skip_column = (options.phrase:column_is_muted(col_count)
            and options.skip_muted) or false

          if not skip_column then

            local target_col = target_line:note_column(col_idx)
            local source_col_idx = col_count+column_offset
            local source_col = source_line:note_column(source_col_idx)

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

            if (target_col.note_value < 121) then
              contains_note = true
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

            high_note_col = math.max(col_idx,high_note_col)

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

    -- effect columns
    if start_fx_col then
      local col_count = 1
      local start_index = get_start_index(start_fx_col)
      local column_offset = get_column_offset(start_fx_col)
      for col_idx = start_index,renoise.InstrumentPhrase.MAX_NUMBER_OF_EFFECT_COLUMNS do
        if (col_idx >= start_fx_col) and
          (col_idx <= end_fx_col) 
        then

          local target_col = target_line:effect_column(col_idx)
          local source_col_idx = col_count+column_offset
          local source_col = source_line:effect_column(col_count+column_offset)

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

          high_fx_col = math.max(col_idx,high_fx_col)

        end
      end
    end

    local col_idx = start_fx_col and start_fx_col+1 or 1
    local target_col = target_line:effect_column(col_idx)
    if target_col and options.insert_zxx and contains_note then
      if (col_idx <= renoise.InstrumentPhrase.MAX_NUMBER_OF_EFFECT_COLUMNS) then
        high_fx_col = math.max(col_idx,high_fx_col)
        target_col.number_string = "0Z"
        target_col.amount_value = 00
      end
    end

    if options.expand_columns then
      track.visible_note_columns = high_note_col
      track.visible_effect_columns = high_fx_col
    end

  end
  
  return true

end

--------------------------------------------------------------------------------
-- export a single phrase, create destination if it doesn't exist
-- @return bool, true when export was succesfull
-- @return xPhrase.ERROR, when an error was encountered

function xPhrase.export_preset(folder,instr_idx,phrase_idx,overwrite,prefix)
  TRACE("xPhrase.export_preset(folder,instr_idx,phrase_idx,overwrite,prefix)",folder,instr_idx,phrase_idx,overwrite,prefix)

  local instr = rns.instruments[instr_idx]
  if not instr then
    return false, xPhrase.ERROR.MISSING_INSTRUMENT
  end

  local phrase = instr.phrases[phrase_idx]
  if not phrase then
    return false, xPhrase.ERROR.MISSING_PHRASE
  end

  -- if path does not exist, attempt to create it 
  if not io.exists(folder) then
    local rslt,err = cFilesystem.makedir(folder)
    if err then
      return false,err
    end
  end

  local phrase_path = xPhrase.get_preset_filepath(folder,phrase,prefix and phrase_idx)
  if not overwrite and io.exists(phrase_path) then
    return false, xPhrase.ERROR.FILE_EXISTS
  end

  renoise.app():save_instrument_phrase(phrase_path)

end

--------------------------------------------------------------------------------
-- generate a valid filename (for exporting phrase presets)
-- @param folder (string)
-- @param phrase (renoise.InstrumentPhrase)
-- @param phrase_idx (number), add prefix to filename [optional]
-- @return string

function xPhrase.get_preset_filepath(folder,phrase,phrase_idx)
  TRACE("xPhrase.get_preset_filepath(folder,phrase,phrase_idx)",folder,phrase,phrase_idx)

  local phrase_path =  nil
  local phrase_name = cFilesystem.sanitize_filename(phrase.name)

  if phrase_idx then
    phrase_path = ("%s%.2d_%.2X_%s.xrnz"):format(folder,phrase_idx,phrase_idx,phrase_name)
  else
    phrase_path = ("%s%s.xrnz"):format(folder,phrase_name)
  end

  return phrase_path

end

--------------------------------------------------------------------------------
-- get the basic preset name, without prefix and file extension
-- e.g. "14_0E_ander patroon.xrnz" becomes "ander patroon"

function xPhrase.get_raw_preset_name(str)
  TRACE("xPhrase.get_raw_preset_name(str)",str)

  local str = cFilesystem.get_raw_filename(str)
  local matched = string.match(str,"%d%d_%x%x_(.*)") 
  return matched or str

end

--------------------------------------------------------------------------------
-- set a property of the phrase
-- (using DOC_PROPS to validate input type/range etc.)
-- @return value (boolean,string,number)

function xPhrase.set_property(phrase,key,val)
  TRACE("xPhrase.set_property(phrase,key,val)",phrase,key,val)

  local prop = cDocument.get_property(xPhrase.DOC_PROPS,key)

  if not prop then
    error("Could not apply value, missing from DOC_PROPS")
  end

  -- fit/clamp values
  if (key == "loop_start") then
    if (val > phrase.number_of_lines) then
      val = phrase.number_of_lines
    end
  end
  if (key == "loop_end") then
    if (val > phrase.number_of_lines) then
      val = phrase.number_of_lines
    end
  end

  return cDocument.apply_value(phrase,prop,val)

end

