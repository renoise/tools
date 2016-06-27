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
-- @param instr (renoise.Instrument)
-- @return bool

function xPhrase.note_is_keymapped(note,instr)
  TRACE("xPhrase.note_is_keymapped(note,instr)",note,instr)

  for k,v in ipairs(instr.phrase_mappings) do
    if (note >= v.note_range[1]) and (note < v.note_range[2]) then
      return true
    end
  end
  return false

end

--------------------------------------------------------------------------------
-- look for implicit/explicit phrase trigger in the provided patternline
-- @param line (renoise.PatternLine)
-- @param note_col_idx (int)
-- @param instr_idx (int)
-- @param trk_idx (int)
-- @return bool

function xPhrase.note_is_phrase_trigger(line,note_col_idx,instr_idx,trk_idx)
  TRACE("xPhrase.note_is_phrase_trigger(line,note_col_idx,instr_idx,trk_idx)",line,note_col_idx,instr_idx,trk_idx)

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
-- remove commands that does not belong in a phrase
-- @param phrase (renoise.InstrumentPhrase)

function xPhrase.clear_foreign_commands(phrase)
  TRACE("xPhrase.clear_foreign_commands(phrase)",phrase)

  if phrase.is_empty then
    return
  end

  local blacklist = {"0Z"}
  
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
