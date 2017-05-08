--[[===============================================================================================
xTransport
===============================================================================================]]--

--[[--

Extended control of the Renoise transport 
.
#

See also:
@{xPatternSequencer}, for control of the pattern section (including sections)  

]]


class 'xTransport'

---------------------------------------------------------------------------------------------------
-- [Static] Move playback position into next pattern 
-- if the pattern doesn't exist, stay at the current one 
-- if the line doesn't exist, play from the first one

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

---------------------------------------------------------------------------------------------------
-- [Static] Move playback position into previous pattern 
-- if the pattern doesn't exist, stay at the current one 
-- if the line doesn't exist, play from the first one

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

---------------------------------------------------------------------------------------------------
-- [Static] Stop/pause playback in Renoise

function xTransport.pause()

  rns.transport:stop()

end

---------------------------------------------------------------------------------------------------
-- [Static] Resume playback in Renoise (start from current line)

function xTransport.resume()

  local mode = renoise.Transport.PLAYMODE_CONTINUE_PATTERN
  rns.transport:start(mode)  

end

---------------------------------------------------------------------------------------------------
-- [Static] Restart playback in Renoise (start from first line)

function xTransport.restart()

  local mode = renoise.Transport.PLAYMODE_RESTART_PATTERN
  rns.transport:start(mode)

end

---------------------------------------------------------------------------------------------------
-- [Static] Toogle pattern-loop in Renoise

function xTransport.toggle_loop()

  rns.transport.loop_pattern = not rns.transport.loop_pattern

end

---------------------------------------------------------------------------------------------------
-- [Static] Toggle edit/record-mode in Renoise 

function xTransport.toggle_record()

  rns.transport.edit_mode = not rns.transport.edit_mode

end

--------------------------------------------------------------------------------
-- [Static] Expanded check for looped pattern, will also consider if the 
-- (currently playing) pattern is looped via the pattern sequence 

function xTransport.pattern_is_looped()
  TRACE("xTransport.pattern_is_looped()")

  if rns.transport.loop_pattern then
    return true
  end

  local seq_idx = rns.transport.playback_pos.sequence
  if (rns.transport.loop_sequence_start == seq_idx) and
    (rns.transport.loop_sequence_end == seq_idx) 
  then
    return true
  end

end



