--[[===============================================================================================
xPatternPos
===============================================================================================]]--

--[[--

Static methods for manipulating the position within a renoise.Pattern
.
#

Note: all xPatternPos methods operate on actual selected objects (pattern, line). This is different from xSongPos, where you can pass an imaginary position around. 

## Changelog

0.51
- renamed to xPatternPos - clarifies the purpose

]]

--=================================================================================================

class 'xPatternPos'

---------------------------------------------------------------------------------------------------
-- [Static] restrict to pattern (will only affect the line)
-- @param line_idx, number
-- @return int or nil, [string, error message]

function xPatternPos.restrict_line_index(line_idx)

  assert(type(line_idx)=="number","Expected 'line_idx' to be a number")
  return cLib.clamp_value(line_idx,1,rns.selected_pattern.number_of_lines)

end

---------------------------------------------------------------------------------------------------
-- [Static] 'Safely'' move cursor to specific position in pattern
-- (same as pressing F9 in the pattern editor)

function xPatternPos.jump_to_line(line_idx)
  TRACE("xPatternPos.jump_to_line(idx)",idx)
  line_idx = xSongPos.restrict_line_index(rns.selected_pattern,line_idx)
  rns.selected_line_index = idx
end

---------------------------------------------------------------------------------------------------
-- [Static] Jump to previous line - see xPatternPos.get_previous_line()

function xPatternPos.jump_to_previous_line()
  TRACE("xPatternPos.jump_to_previous_line()")
  local pos = xPatternPos.get_previous_line()
  rns.selected_sequence_index = pos.sequence
  rns.selected_line_index = pos.line
end

---------------------------------------------------------------------------------------------------
-- [Static] Jump to previous line - see xPatternPos.get_previous_line()

function xPatternPos.jump_to_next_line()
  TRACE("xPatternPos.jump_to_next_line()")
  local pos = xPatternPos.get_next_line()
  print("pos",pos)
  rns.selected_sequence_index = pos.sequence
  rns.selected_line_index = pos.line
end

---------------------------------------------------------------------------------------------------
-- [Static] Jump to last line 

function xPatternPos.jump_to_last_line()
  TRACE("xPatternPos.jump_to_last_line()")
  local patt = rns.selected_pattern 
  rns.selected_line_index = patt.number_of_lines
end

---------------------------------------------------------------------------------------------------
-- [Static] Jump to next page (page-down by 16 lines)

function xPatternPos.jump_to_next_page()
  TRACE("xPatternPos.jump_to_next_page()")
  local patt = rns.selected_pattern 
  local line_index = rns.selected_line_index + 16
  rns.selected_line_index = math.min(patt.number_of_lines,line_index)
end

---------------------------------------------------------------------------------------------------
-- [Static] Jump to previous page (page-up by 16 lines)

function xPatternPos.jump_to_previous_page()
  TRACE("xPatternPos.jump_to_previous_page()")
  local line_index = rns.selected_line_index - 16
  rns.selected_line_index = math.max(1,line_index)
end

---------------------------------------------------------------------------------------------------
-- [Static] Move edit cursor to first quarter of the pattern 
-- (same as pressing F9 in the pattern editor)

function xPatternPos.jump_to_first_quarter_row()
  TRACE("xPatternPos.jump_to_first_quarter_row()")
  rns.selected_line_index = 1
end

---------------------------------------------------------------------------------------------------
-- [Static] Move edit cursor to second quarter of the pattern 
-- (same as pressing F10 in the pattern editor)

function xPatternPos.jump_to_second_quarter_row()
  TRACE("xPatternPos.jump_to_second_quarter_row()")
  rns.selected_line_index = 1 + rns.selected_pattern.number_of_lines/4*1
end

---------------------------------------------------------------------------------------------------
-- [Static] Move edit cursor to third quarter of the pattern 
-- (same as pressing F11 in the pattern editor)

function xPatternPos.jump_to_third_quarter_row()
  TRACE("xPatternPos.jump_to_third_quarter_row()")
  rns.selected_line_index = 1 + rns.selected_pattern.number_of_lines/4*2
end

---------------------------------------------------------------------------------------------------
-- [Static] Move edit cursor to fourth quarter of the pattern 
-- (same as pressing F12 in the pattern editor)

function xPatternPos.jump_to_fourth_quarter_row()
  TRACE("xPatternPos.jump_to_fourth_quarter_row()")
  rns.selected_line_index = 1 + rns.selected_pattern.number_of_lines/4*3
end

---------------------------------------------------------------------------------------------------
-- [Static] Return position of previous line, taking the Renoise 'wrap-around' property 
-- into consideration (essentially, same as pressing "arrow up" in the pattern editor)
-- @return renoise.SongPos

function xPatternPos.get_previous_line()
  TRACE("xPatternPos.get_previous_line()")
  
  local line_index = rns.selected_line_index - 1
  local wrapped = rns.transport.wrapped_pattern_edit
  local patt = rns.selected_pattern
  local seq_index = rns.selected_sequence_index
  
  if (line_index < 1) then
    if wrapped then -- previous pattern 
      seq_index = seq_index-1
      if (seq_index > 0) then
        local new_patt_index = rns.sequencer.pattern_sequence[seq_index]
        local new_patt = rns.patterns[new_patt_index]
        line_index = new_patt.number_of_lines + line_index 
      else
        line_index = 1
        seq_index = 1
      end
    else
      line_index = patt.number_of_lines 
    end
  end

  local pos = rns.transport.edit_pos
  pos.sequence = seq_index
  pos.line = line_index

  return pos

end 

---------------------------------------------------------------------------------------------------
-- [Static] Return position of next line, taking the Renoise 'wrap-around' property 
-- into consideration (essentially, same as pressing "arrow down" in the pattern editor)
-- @return renoise.SongPos

function xPatternPos.get_next_line()
  TRACE("xPatternPos.get_next_line()")
  
  local line_index = rns.selected_line_index + 1
  local wrapped = rns.transport.wrapped_pattern_edit
  local patt = rns.selected_pattern
  local seq_index = rns.selected_sequence_index
  
  if (line_index > patt.number_of_lines) then
    if wrapped then -- next pattern
      seq_index = seq_index+1
      local seq_length = #rns.sequencer.pattern_sequence
      if (seq_index > seq_length) then
        seq_index = seq_length
        local new_patt_index = rns.sequencer.pattern_sequence[seq_index]
        local new_patt = rns.patterns[new_patt_index]
        line_index = new_patt.number_of_lines
      else
        line_index = 1
      end
    else
      line_index = 1
    end
  end

  local pos = rns.transport.edit_pos
  pos.sequence = seq_index
  pos.line = line_index

  return pos

end 

