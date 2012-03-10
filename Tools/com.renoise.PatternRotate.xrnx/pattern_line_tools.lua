--[[============================================================================
pattern_line_tools.lua
============================================================================]]--

--------------------------------------------------------------------------------

-- copy all effect column properties from src to dest column

local effect_column_properties = {
  "number_value",
  "amount_value",
}

function copy_effect_column(src_column, dest_column)
  for _,property in pairs(effect_column_properties) do
    dest_column[property] = src_column[property]
  end
end


--------------------------------------------------------------------------------

-- copy all note column properties from src to dest column

local note_column_properties = {
  "note_value",
  "instrument_value",
  "volume_value",
  "panning_value",
  "delay_value",
}

function copy_note_column(src_column, dest_column)
  for _,property in pairs(note_column_properties) do
    dest_column[property] = src_column[property]
  end
end


--------------------------------------------------------------------------------

-- creates a copy of the given patternline

function copy_line(src_line, dest_line)

  for index,src_column in pairs(src_line.note_columns) do
    if (not dest_line.note_columns[index]) then
      dest_line.note_columns[index] = {}
    end

    local dest_column = dest_line.note_columns[index]
    copy_note_column(src_column, dest_column)
  end
  
  for index,src_column in pairs(src_line.effect_columns) do
    if (not dest_line.effect_columns[index]) then
      dest_line.effect_columns[index] = {}
    end
    
    local dest_column = dest_line.effect_columns[index]
    copy_effect_column(src_column, dest_column)
  end
end


--------------------------------------------------------------------------------

-- queries the selection range start and end lines

function selection_line_range(pattern_index)

  local line_start, line_end
  
  if (pattern_index == renoise.song().selected_pattern_index) then
    local iter = renoise.song().pattern_iterator:lines_in_pattern(pattern_index)
    
    for pos,line in iter do
      for _,note_column in pairs(line.note_columns) do
        if (note_column.is_selected) then
          line_start = line_start or pos.line
          line_end = line_end and math.max(line_end, pos.line) or pos.line
        end
      end
      
      for _,effect_column in pairs(line.effect_columns) do
        if (effect_column.is_selected) then
          line_start = line_start or pos.line
          line_end = line_end and math.max(line_end, pos.line) or pos.line
        end
      end
    end
  end
    
  return line_start, line_end
end

