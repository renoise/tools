--[[============================================================================
xVoiceSorter
============================================================================]]--

--[[--

Static methods for dealing with a renoise.Pattern
.
#


]]

class 'xPattern'

-------------------------------------------------------------------------------

function xPattern.jump_to_first_quarter_row()
  rns.selected_line_index = 1
end

-------------------------------------------------------------------------------

function xPattern.jump_to_second_quarter_row()
  rns.selected_line_index = 1 + rns.selected_pattern.number_of_lines/4*1
end

-------------------------------------------------------------------------------

function xPattern.jump_to_third_quarter_row()
  rns.selected_line_index = 1 + rns.selected_pattern.number_of_lines/4*2
end

-------------------------------------------------------------------------------

function xPattern.jump_to_fourth_quarter_row()
  rns.selected_line_index = 1 + rns.selected_pattern.number_of_lines/4*3
end

-------------------------------------------------------------------------------

function xPattern.move_to_next_pattern_row()
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

function xPattern.move_to_previous_pattern_row()
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

