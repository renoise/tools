--[[============================================================================
xTransport
============================================================================]]--

--[[--

Extended transport, including pattern-sequence sections and more
.
#


]]


class 'xTransport'

-------------------------------------------------------------------------------
-- Basic transport controls
-------------------------------------------------------------------------------

function xTransport.forward()

  local play_pos = rns.transport.playback_pos
  play_pos.sequence = play_pos.sequence + 1
  local seq_len = #rns.sequencer.pattern_sequence
  if (play_pos.sequence <= seq_len) then
   local new_patt_idx = 
    rns.sequencer.pattern_sequence[play_pos.sequence]
   local new_patt = rns:pattern(new_patt_idx)
   if (play_pos.line > new_patt.number_of_lines) then
    play_pos.line = 1
   end
   rns.transport.playback_pos = play_pos
  end

end

-------------------------------------------------------------------------------

function xTransport.rewind()

  local play_pos = rns.transport.playback_pos
  play_pos.sequence = play_pos.sequence - 1
  if (play_pos.sequence < 1) then
   play_pos.sequence = 1
  end
  local new_patt_idx = 
   rns.sequencer.pattern_sequence[play_pos.sequence]
  local new_patt = rns:pattern(new_patt_idx)
  if (play_pos.line > new_patt.number_of_lines) then
   play_pos.line = 1
  end
  rns.transport.playback_pos = play_pos 


end

-------------------------------------------------------------------------------

function xTransport.pause()

  rns.transport:stop()

end

-------------------------------------------------------------------------------

function xTransport.resume()

  local mode = renoise.Transport.PLAYMODE_CONTINUE_PATTERN
  rns.transport:start(mode)  

end

-------------------------------------------------------------------------------

function xTransport.restart()

  local mode = renoise.Transport.PLAYMODE_RESTART_PATTERN
  rns.transport:start(mode)

end

-------------------------------------------------------------------------------

function xTransport.toggle_loop()

  rns.transport.loop_pattern = not rns.transport.loop_pattern

end

-------------------------------------------------------------------------------

function xTransport.toggle_record()

  rns.transport.edit_mode = not rns.transport.edit_mode

end


-------------------------------------------------------------------------------
-- Sections (Pattern-Sequence)
-------------------------------------------------------------------------------

function xTransport.toggle_loop_section()

    local seq_pos = song().transport.edit_pos.sequence
    local section_index = xTransport.get_section_index_by_seq_pos(seq_pos)
    xTransport.loop_section_by_index(section_index)

end

-------------------------------------------------------------------------------

function xTransport.loop_section_by_index(section_index)

  local positions = xTransport.gather_section_positions()
  if table.is_empty(positions) then
    return
  end
  if not positions[section_index] then
    return
  end

  -- rules: enable loop if partially selected, or unselected
  -- disable loop if section (and _only_ section) is wholly looped

  local section_start = positions[section_index] 
  local section_end = positions[section_index+1] and 
    positions[section_index+1]-1 or #song().sequencer.pattern_sequence

  local within_range = function(pos,range_start,range_end)
    return pos >= range_start and pos <= range_end
  end

  local enable_loop = false
  local loop_seq_empty = (song().transport.loop_sequence_range[1] == 0) and 
    (song().transport.loop_sequence_range[2] == 0)
  if not loop_seq_empty then
    local all_looped,all_empty = false,false
    for k,v in ipairs(song().sequencer.pattern_sequence) do
      if within_range(k,section_start,section_end) then
        if within_range(k,song().transport.loop_sequence_start,song().transport.loop_sequence_end) then
          if not all_looped then
            all_looped = true
          end
          all_empty = false
        else
          if not all_empty then
            all_empty = true
          end
          all_looped = false
        end
      end
    end
    if all_looped then
      enable_loop = false
    elseif all_empty then
      enable_loop = true
    end
  else
    enable_loop = true
  end

  if enable_loop then
    song().transport.loop_sequence_range = {section_start,section_end}
  else
    song().transport.loop_sequence_range = {}
  end

end

-------------------------------------------------------------------------------

function xTransport.get_section_index_by_seq_pos(seq_pos)

  local positions = xTransport.gather_section_positions()
  if not table.is_empty(positions) then
    for k,v in ipairs(positions) do
      if (v > seq_pos) then
        return k-1
      elseif (v == seq_pos) then
        return k
      end
    end
    return #positions,positions
  end
  
end

-------------------------------------------------------------------------------

function xTransport.gather_section_positions()

  local positions = {}
  for k,v in ipairs(song().sequencer.pattern_sequence) do
    if song().sequencer:sequence_is_start_of_section(k) then
      table.insert(positions,k)
    end
  end
  return positions

end

