--[[============================================================================
xPatternPos
============================================================================]]--

--[[--

Static methods for manipulating the position within a renoise.Pattern
.
#

Note: all xPatternPos methods operate on actual selected objects (pattern, line). This is different from xSongPos, where you can pass an imaginary position around. 

## Changelog

0.51
- renamed to xPatternPos - clarifies the purpose

]]

class 'xPatternPos'

---------------------------------------------------------------------------------------------------
-- [Static] restrict to pattern (will only affect the line)
-- @param line_idx, number
-- @return int or nil, [string, error message]

function xPatternPos.restrict_line_index(line_idx)

  assert(type(line_idx)=="number","Expected 'line_idx' to be a number")
  return cLib.clamp_value(line_idx,1,rns.selected_pattern.number_of_lines)

end

-------------------------------------------------------------------------------
-- [Static] 'Safely'' move cursor to specific position in pattern
-- (same as pressing F9 in the pattern editor)

function xPatternPos.jump_to_line(line_idx)
  TRACE("xPatternPos.jump_to_line(idx)",idx)

  -- make the line safe
  line_idx = xSongPos.restrict_line_index(rns.selected_pattern,line_idx)
  --[[
  if (idx <= rns.selected_pattern.number_of_lines) 
    or (idx > 0)
  then
  ]]
    rns.selected_line_index = idx
  --end
end

-------------------------------------------------------------------------------
-- [Static] Move edit cursor to first quarter of the pattern 
-- (same as pressing F9 in the pattern editor)

function xPatternPos.jump_to_first_quarter_row()
  TRACE("xPatternPos.jump_to_first_quarter_row()")
  rns.selected_line_index = 1
end

-------------------------------------------------------------------------------
-- [Static] Move edit cursor to second quarter of the pattern 
-- (same as pressing F10 in the pattern editor)

function xPatternPos.jump_to_second_quarter_row()
  TRACE("xPatternPos.jump_to_second_quarter_row()")
  rns.selected_line_index = 1 + rns.selected_pattern.number_of_lines/4*1
end

-------------------------------------------------------------------------------
-- [Static] Move edit cursor to third quarter of the pattern 
-- (same as pressing F11 in the pattern editor)

function xPatternPos.jump_to_third_quarter_row()
  TRACE("xPatternPos.jump_to_third_quarter_row()")
  rns.selected_line_index = 1 + rns.selected_pattern.number_of_lines/4*2
end

-------------------------------------------------------------------------------
-- [Static] Move edit cursor to fourth quarter of the pattern 
-- (same as pressing F12 in the pattern editor)

function xPatternPos.jump_to_fourth_quarter_row()
  TRACE("xPatternPos.jump_to_fourth_quarter_row()")
  rns.selected_line_index = 1 + rns.selected_pattern.number_of_lines/4*3
end

-------------------------------------------------------------------------------
-- [Static] Move edit cursor to next line 
-- (respects wrapped pattern edit setting)

function xPatternPos.move_to_next_pattern_row()
  TRACE("xPatternPos.move_to_next_pattern_row()")
  local pattern = rns.selected_pattern
  local line_idx = rns.selected_line_index
  line_idx = math.min(pattern.number_of_lines,line_idx+1)
  local wrapped_edit = rns.transport.wrapped_pattern_edit
  if (line_idx == rns.selected_line_index) then
    local seq_length = #rns.sequencer.pattern_sequence
    local new_seq_idx = rns.selected_sequence_index  
    local new_line_idx = rns.selected_line_index
    local last_pattern_in_song = (rns.selected_sequence_index == seq_length)
    if last_pattern_in_song then
      if not wrapped_edit then
        new_line_idx = 1
      end
    else
      new_seq_idx = wrapped_edit and new_seq_idx + 1 or new_seq_idx
      rns.selected_line_index = 1
    end
    rns.selected_sequence_index = new_seq_idx
    rns.selected_line_index = new_line_idx
  else
    rns.selected_line_index = line_idx
  end
end

-------------------------------------------------------------------------------
-- [Static] Move edit cursor to previous line 
-- (respects wrapped pattern edit setting)

function xPatternPos.move_to_previous_pattern_row()
  TRACE("xPatternPos.move_to_previous_pattern_row()")
  local line_idx = rns.selected_line_index
  line_idx = math.max(1,line_idx-1)
  local wrapped_edit = rns.transport.wrapped_pattern_edit
  if (line_idx == rns.selected_line_index) then
    local first_pattern_in_song = (rns.selected_sequence_index == 1)
    local new_seq_idx = rns.selected_sequence_index  
    local new_line_idx = rns.selected_line_index
    if first_pattern_in_song then
      if not wrapped_edit then
        local pattern_idx = rns.sequencer.pattern_sequence[rns.selected_sequence_index]
        new_line_idx = rns.patterns[pattern_idx].number_of_lines
      end
    else
      new_seq_idx = wrapped_edit and new_seq_idx - 1 or new_seq_idx
      local pattern_idx = rns.sequencer.pattern_sequence[new_seq_idx]
      new_line_idx = rns.patterns[pattern_idx].number_of_lines
    end
    rns.selected_sequence_index = new_seq_idx
    rns.selected_line_index = line_idx
  else
    rns.selected_line_index = line_idx
  end
end

