class 'xPhrase'

--------------------------------------------------------------------------------
-- replace sample indices in the provided phrase 
-- @param phrase (renoise.InstrumentPhrase)
-- @param idx_from (int)
-- @param idx_to (int)

function xPhrase.replace_sample_index(phrase,idx_from,idx_to)
  --print("xLib.replace_sample_index(phrase,idx_from,idx_to)",phrase,idx_from,idx_to)

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


