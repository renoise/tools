--[[===============================================================================================
xSongPos
===============================================================================================]]--

--[[--

Static methods for working with renoise.SongPos (or alike).

##

Three options are designed to deal with song boundaries, pattern-loop and block-loop boundaries. 
By default, they are set to settings which mimic the behavior in Renoise when playing/manipulating 
the playback position. Please see xSongPos.OUT_OF_BOUNDS/LOOP_BOUNDARY/BLOCK_BOUNDARY for more 
information. 

Note: throughout, the class accepts not only an instance of `renoise.SongPos` as argument, 
but also "SongPos-alike" objects - tables that contain a line and sequence property. 

]]

class 'xSongPos'

--- How to deal with sequence (song) boundaries
-- CAP: do not exceed, cap at beginning/end
-- LOOP: going past the end will take us to the start, and vice versa
-- NULL: going past the end or start will return nil
xSongPos.OUT_OF_BOUNDS = {
  CAP = 1,
  LOOP = 2,
  NULL = 3,
}

--- How to deal with loop boundaries
-- HARD: always stay within loop, no matter the position
-- SOFT: only stay within loop when playback takes us there
-- NONE: continue past loop boundary (ignore)
xSongPos.LOOP_BOUNDARY = {
  HARD = 1,
  SOFT = 2,
  NONE = 3,
}

--- How to deal with block-loop boundaries
-- HARD: always stay within loop, no matter the position
-- SOFT: only stay within loop when playback takes us there
-- NONE: continue past loop boundary (ignore)
xSongPos.BLOCK_BOUNDARY = {
  HARD = 1,
  SOFT = 2,
  NONE = 3,
}

--- Provide fallback values 
xSongPos.DEFAULT_BOUNDS_MODE = xSongPos.OUT_OF_BOUNDS.LOOP
xSongPos.DEFAULT_LOOP_MODE = xSongPos.LOOP_BOUNDARY.SOFT
xSongPos.DEFAULT_BLOCK_MODE = xSongPos.BLOCK_BOUNDARY.SOFT

---------------------------------------------------------------------------------------------------
-- [Static] Create a native SongPos object 
-- @param pos, renoise.SongPos or alike
-- @return table, renoise.SongPos 

function xSongPos.create(pos)
  TRACE("xSongPos.create(pos)",pos)
  local rslt = rns.transport.playback_pos
  rslt.sequence = pos.sequence
  rslt.line = pos.line
  return rslt
end

---------------------------------------------------------------------------------------------------
-- For convenience, return default settings 

function xSongPos.get_defaults()
  TRACE("xSongPos.get_defaults()")
  return {
    bounds = xSongPos.DEFAULT_BOUNDS_MODE,
    loop = xSongPos.DEFAULT_LOOP_MODE,
    block = xSongPos.DEFAULT_BLOCK_MODE,
  }
end 

---------------------------------------------------------------------------------------------------
-- For convenience, apply default settings 

function xSongPos.set_defaults(val)
  TRACE("xSongPos.set_defaults(val)",val)
  xSongPos.DEFAULT_BOUNDS_MODE = val.bounds
  xSongPos.DEFAULT_LOOP_MODE = val.loop
  xSongPos.DEFAULT_BLOCK_MODE = val.block
end 

---------------------------------------------------------------------------------------------------
-- [Class] Normalize the position, takes us from an 'imaginary' position to one  
-- that respect the actual pattern length/sequence plus loops
-- @param [loop_boundary], xSongPos.LOOP_BOUNDARY

-- @return table (renoise.SongPos-alike)

function xSongPos.normalize(pos,bounds_mode,loop_boundary,block_boundary)
  TRACE("xSongPos.normalize(pos,bounds_mode,loop_boundary,block_boundary)",pos,bounds_mode,loop_boundary,block_boundary)

  local seq_idx = pos.sequence
  local line_idx = pos.line

  -- cap sequence if out-of-bounds ------------------------
  local seq_length = cLib.clamp_value(seq_idx,1,#rns.sequencer.pattern_sequence)

  -- check for pattern out-of-bounds ----------------------
  local patt_num_lines = xPatternSequencer.get_number_of_lines(seq_idx)
  if (line_idx < 1) then
    xSongPos.decrease_by_lines(line_idx-patt_num_lines,pos,bounds_mode,loop_boundary,block_boundary)
  elseif (line_idx > patt_num_lines) then 
    pos.line = patt_num_lines
    xSongPos.increase_by_lines(line_idx-patt_num_lines,pos,bounds_mode,loop_boundary,block_boundary)
  end

end

---------------------------------------------------------------------------------------------------
-- [Class] Increase position by X number of lines
-- @param num_lines (number)
-- @param pos (SongPos)
-- @param [bounds_mode], xSongPos.OUT_OF_BOUNDS
-- @param [loop_boundary], xSongPos.LOOP_BOUNDARY
-- @param [block_boundary], xSongPos.BLOCK_BOUNDARY
-- @return pos (SongPos) 
-- @return number, lines travelled 

function xSongPos.increase_by_lines(num_lines,pos,bounds_mode,loop_boundary,block_boundary)
  TRACE("xSongPos.increase_by_lines(num_lines,pos,bounds_mode,loop_boundary,block_boundary)",num_lines,pos,bounds_mode,loop_boundary,block_boundary)

  assert(type(num_lines) == "number")

  if not bounds_mode then bounds_mode = xSongPos.DEFAULT_BOUNDS_MODE end
  if not loop_boundary then loop_boundary = xSongPos.DEFAULT_BLOCK_MODE end
  if not block_boundary then block_boundary = xSongPos.DEFAULT_BLOCK_MODE end

  -- no action needed
  if (num_lines == 0) then
    return 0
  end

  -- true when no further action is needed
  local done = false

  local seq_idx = pos.sequence
  local line_idx = pos.line

  -- sanity check: sequence within song boundaries?
  if (seq_idx > #rns.sequencer.pattern_sequence) then
    LOG("*** xSongPos - ignore out-of-bounds sequence index")
    return 0
  end

  -- even when we are supposedly spanning multiple 
  -- patterns, block looping might prevent this
  local exiting_blockloop = false
  if rns.transport.loop_block_enabled then
    exiting_blockloop = (block_boundary < xSongPos.BLOCK_BOUNDARY.NONE) and
      xBlockLoop.exiting(seq_idx,line_idx,num_lines) or false
  end

  local patt_num_lines = xPatternSequencer.get_number_of_lines(seq_idx)
  if (line_idx+num_lines <= patt_num_lines) or exiting_blockloop then
    pos.sequence = seq_idx
    pos.line = xSongPos.enforce_block_boundary("increase",{sequence=seq_idx,line=line_idx},num_lines,block_boundary)
  else
    local lines_remaining = num_lines - (patt_num_lines - line_idx)
    while(lines_remaining > 0) do
      seq_idx = seq_idx + 1
      seq_idx,line_idx,done = xSongPos.enforce_boundary("increase",{sequence=seq_idx,line=lines_remaining},bounds_mode,loop_boundary)
      if done then
        if (bounds_mode == xSongPos.OUT_OF_BOUNDS.CAP) then
          -- reduce num_lines, or travelled will no longer be correct
          num_lines = num_lines - lines_remaining
          done = false
        end
        break
      end

      patt_num_lines = xPatternSequencer.get_number_of_lines(seq_idx)
      lines_remaining = lines_remaining - patt_num_lines

      -- check if we have reached our goal
      if (lines_remaining < 0) then
        line_idx = lines_remaining + patt_num_lines
        break
      end

    end

    pos.sequence = seq_idx
    pos.line = line_idx
  
  end

  if not done then
    return num_lines
  else
    return 0
  end

end

---------------------------------------------------------------------------------------------------
-- [Class] Subtract a number of lines from position
-- @param num_lines, int
-- @param pos (SongPos)
-- @param [bounds_mode], xSongPos.OUT_OF_BOUNDS
-- @param [loop_boundary], xSongPos.LOOP_BOUNDARY
-- @param [block_boundary], xSongPos.BLOCK_BOUNDARY
-- @return pos (SongPos) 
-- @return number, lines travelled 

function xSongPos.decrease_by_lines(num_lines,pos,bounds_mode,loop_boundary,block_boundary)
  TRACE("xSongPos.decrease_by_lines(num_lines,pos,bounds_mode,loop_boundary,block_boundary)",num_lines,pos,bounds_mode,loop_boundary,block_boundary)

  assert(type(num_lines) == "number")

  if not bounds_mode then bounds_mode = xSongPos.DEFAULT_BOUNDS_MODE end
  if not loop_boundary then loop_boundary = xSongPos.DEFAULT_BLOCK_MODE end
  if not block_boundary then block_boundary = xSongPos.DEFAULT_BLOCK_MODE end

  -- no action needed
  if (num_lines == 0) then
    return
  end

  -- true when no further action is needed
  local done = false

  local seq_idx = pos.sequence
  local line_idx = pos.line

  -- even when we are supposedly spanning multiple 
  -- patterns, block looping might prevent this
  local exiting_blockloop = 
    (block_boundary < xSongPos.BLOCK_BOUNDARY.NONE) and
      xBlockLoop.exiting(seq_idx,line_idx,-num_lines) or false

  if (pos.line-num_lines > 0) or exiting_blockloop then
    pos.sequence = seq_idx
    pos.line = xSongPos.enforce_block_boundary("decrease",{sequence=seq_idx,line=pos.line},-num_lines,block_boundary)

  else
    local patt_num_lines = xPatternSequencer.get_number_of_lines(seq_idx)
    local lines_remaining = num_lines - line_idx

    -- make sure loop is evaluated at least once
    local first_run = true
    while first_run or (lines_remaining > 0) do

      first_run = false
      seq_idx = seq_idx - 1

      seq_idx,line_idx,done = 
        xSongPos.enforce_boundary("decrease",{sequence=seq_idx,line=lines_remaining},bounds_mode,loop_boundary)
      if done then
        if (bounds_mode == xSongPos.OUT_OF_BOUNDS.CAP) then
          -- reduce num_lines, or travelled will no longer be correct
          num_lines = -1 + num_lines - lines_remaining
          done = false
        end
        break
      end

      patt_num_lines = xPatternSequencer.get_number_of_lines(seq_idx)
      lines_remaining = lines_remaining - patt_num_lines

      -- check if we have reached our goal
      if (lines_remaining <= 0) then
        line_idx = -lines_remaining
        if (line_idx < 1) then
          -- zero is not a valid line index, normalize!!
          local new_pos = {sequence=seq_idx,line=line_idx}
          xSongPos.decrease_by_lines(1,new_pos,bounds_mode,block_boundary)
          seq_idx = new_pos.sequence
          line_idx = new_pos.line
        end
        break
      end

    end
    pos.sequence = seq_idx
    pos.line = line_idx
  end
  
  if not done then
    return num_lines
  else
    return 0
  end

end

---------------------------------------------------------------------------------------------------
-- [Class] Set to the next beat position
-- @param pos (SongPos)
-- @param [bounds_mode], xSongPos.OUT_OF_BOUNDS
-- @param [loop_boundary], xSongPos.LOOP_BOUNDARY
-- @param [block_boundary], xSongPos.BLOCK_BOUNDARY
-- @return number, lines travelled

function xSongPos.next_beat(pos,bounds_mode,loop_boundary,block_boundary)
  TRACE("xSongPos.next_beat(pos,bounds_mode,loop_boundary,block_boundary)",pos,bounds_mode,loop_boundary,block_boundary)

  if not bounds_mode then bounds_mode = xSongPos.DEFAULT_BOUNDS_MODE end
  if not loop_boundary then loop_boundary = xSongPos.DEFAULT_BLOCK_MODE end
  if not block_boundary then block_boundary = xSongPos.DEFAULT_BLOCK_MODE end

  local lines_beat = rns.transport.lpb
  local next_beat = math.ceil(pos.line/lines_beat)
  local next_line = 1 + next_beat*lines_beat
  return xSongPos.increase_by_lines(next_line - pos.line,pos,bounds_mode,loop_boundary,block_boundary)

end

---------------------------------------------------------------------------------------------------
-- [Class] Set to the next bar position
-- @param pos (SongPos)
-- @param [bounds_mode], xSongPos.OUT_OF_BOUNDS
-- @param [loop_boundary], xSongPos.LOOP_BOUNDARY
-- @param [block_boundary], xSongPos.BLOCK_BOUNDARY
-- @return number, lines travelled

function xSongPos.next_bar(pos,bounds_mode,loop_boundary,block_boundary)
  TRACE("xSongPos.next_bar(pos,bounds_mode,loop_boundary,block_boundary)",pos,bounds_mode,loop_boundary,block_boundary)

  if not bounds_mode then bounds_mode = xSongPos.DEFAULT_BOUNDS_MODE end
  if not loop_boundary then loop_boundary = xSongPos.DEFAULT_BLOCK_MODE end
  if not block_boundary then block_boundary = xSongPos.DEFAULT_BLOCK_MODE end

  local lines_beat = rns.transport.lpb
  local lines_bar = lines_beat * rns.transport.metronome_beats_per_bar
  local next_beat = math.ceil(pos.line/lines_bar)
  local next_line = 1 + next_beat*lines_bar
  return xSongPos.increase_by_lines(next_line - pos.line,pos,bounds_mode,loop_boundary,block_boundary)

end

---------------------------------------------------------------------------------------------------
-- [Class] Set to the next block position
-- @param pos (SongPos)
-- @param [bounds_mode], xSongPos.OUT_OF_BOUNDS
-- @param [loop_boundary], xSongPos.LOOP_BOUNDARY
-- @param [block_boundary], xSongPos.BLOCK_BOUNDARY
-- @return number, lines travelled

function xSongPos.next_block(pos,bounds_mode,loop_boundary,block_boundary)
  TRACE("xSongPos.next_block(pos,bounds_mode,loop_boundary,block_boundary)",pos,bounds_mode,loop_boundary,block_boundary)

  if not bounds_mode then bounds_mode = xSongPos.DEFAULT_BOUNDS_MODE end
  if not loop_boundary then loop_boundary = xSongPos.DEFAULT_BLOCK_MODE end
  if not block_boundary then block_boundary = xSongPos.DEFAULT_BLOCK_MODE end

  local lines_block = xBlockLoop.get_block_lines(pos.sequence)
  local next_beat = math.ceil(pos.line/lines_block)
  local next_line = 1 + next_beat*lines_block
  return xSongPos.increase_by_lines(next_line - pos.line,pos,bounds_mode,loop_boundary,block_boundary)

end

---------------------------------------------------------------------------------------------------
-- [Class] Set to the beginning of next pattern 
-- @param pos (SongPos)
-- @param [bounds_mode], xSongPos.OUT_OF_BOUNDS
-- @param [loop_boundary], xSongPos.LOOP_BOUNDARY
-- @param [block_boundary], xSongPos.BLOCK_BOUNDARY
-- @return number, lines travelled

function xSongPos.next_pattern(pos,bounds_mode,loop_boundary,block_boundary)
  TRACE("xSongPos.next_pattern(pos,bounds_mode,loop_boundary,block_boundary)",pos,bounds_mode,loop_boundary,block_boundary)

  if not bounds_mode then bounds_mode = xSongPos.DEFAULT_BOUNDS_MODE end
  if not loop_boundary then loop_boundary = xSongPos.DEFAULT_BLOCK_MODE end
  if not block_boundary then block_boundary = xSongPos.DEFAULT_BLOCK_MODE end

  local patt_num_lines = xPatternSequencer.get_number_of_lines(pos.sequence)
  local next_line = 1 + patt_num_lines

  return xSongPos.increase_by_lines(next_line - pos.line,pos,bounds_mode,loop_boundary,block_boundary)

end

---------------------------------------------------------------------------------------------------
-- [Static] Restrict the position to boundaries (sequence, loop)
-- @param direction, string ("increase" or "decrease")
-- @param pos, SongPos 
-- @param [bounds_mode], xSongPos.OUT_OF_BOUNDS
-- @param [loop_boundary], xSongPos.LOOP_BOUNDARY
-- @param [block_boundary], xSongPos.BLOCK_BOUNDARY
-- @return sequence,line,done
--  sequence (int)
--  line (int)
--  done (bool), true when no further action needed (capped/nullified)

function xSongPos.enforce_boundary(direction,pos,bounds_mode,loop_boundary,block_boundary)
  TRACE("xSongPos.enforce_boundary(direction,pos,loop_boundary,block_boundary)",direction,pos,loop_boundary,block_boundary)

  assert(type(direction),"string")

  if not bounds_mode then bounds_mode = xSongPos.DEFAULT_BOUNDS_MODE end
  if not loop_boundary then loop_boundary = xSongPos.DEFAULT_LOOP_MODE end
  if not block_boundary then block_boundary = xSongPos.DEFAULT_BLOCK_MODE end

  -- true when no further action is needed
  local done = false

  local seq_idx = pos.sequence
  local line_idx = pos.line 

  -- pattern loop -----------------------------------------
  -- if current pattern is looped, stay within it
  -- (pattern loop takes precedence, just like in Renoise -
  -- we are checking for a sequence loop in the code below)
  if rns.transport.loop_pattern then
    seq_idx = (direction == "increase") and 
      seq_idx - 1 or seq_idx + 1
    return seq_idx,line_idx,done
  end

  -- sequence loop ----------------------------------------
  -- consider if we have moved into a pattern, 
  -- perhaps we need to revise the sequence index?
  -- (looping should work "backwards" too)
  if (rns.transport.loop_sequence_start ~= 0) then
    local hard_boundary = (loop_boundary == xSongPos.LOOP_BOUNDARY.HARD)
    if (direction == "increase") then
      local loop_start = hard_boundary and
        rns.transport.loop_sequence_start.sequence or
          (rns.transport.loop_sequence_end == seq_idx-1) and
            rns.transport.loop_sequence_start
      if loop_start then
        return loop_start,line_idx,done
      end
    elseif (direction == "decrease") then
      local loop_end = hard_boundary and 
        rns.transport.loop_sequence_end.sequence or 
          (rns.transport.loop_sequence_start == seq_idx+1) and
            rns.transport.loop_sequence_end
      if loop_end then
        return loop_end,line_idx,done
      end
    end
  end

  -- sequence (entire song) -------------------------------
  if not xPatternSequencer.within_bounds(seq_idx) then 
    if (direction == "increase") then
      if (bounds_mode == xSongPos.OUT_OF_BOUNDS.CAP) then
        seq_idx = #rns.sequencer.pattern_sequence
        local patt_num_lines = xPatternSequencer.get_number_of_lines(seq_idx)
        line_idx = patt_num_lines
        done = true
      elseif (bounds_mode == xSongPos.OUT_OF_BOUNDS.LOOP) then
        seq_idx = 1
      elseif (bounds_mode == xSongPos.OUT_OF_BOUNDS.NULL) then
        seq_idx = nil
        line_idx = nil
        done = true
      end
    elseif (direction == "decrease") then
      if (bounds_mode == xSongPos.OUT_OF_BOUNDS.CAP) then
        seq_idx = 1
        line_idx = 1
        done = true
      elseif (bounds_mode == xSongPos.OUT_OF_BOUNDS.LOOP) then
        seq_idx = #rns.sequencer.pattern_sequence
        local last_patt_lines = xPatternSequencer.get_number_of_lines(seq_idx)
        line_idx = last_patt_lines - line_idx 
      elseif (bounds_mode == xSongPos.OUT_OF_BOUNDS.NULL) then
        seq_idx = nil
        line_idx = nil
        done = true
      end
    end
  end

  return seq_idx, line_idx, done

end

---------------------------------------------------------------------------------------------------
-- [Static] Restrict position to boundaries (block-loop)
-- @param direction, string - "increase" or "decrease"
-- @param pos, SongPos 
-- @param line_delta, int - #lines to add/subtract, negative when decreasing
-- @param [boundary], xSongPos.BLOCK_BOUNDARY
-- @return line, int

function xSongPos.enforce_block_boundary(direction,pos,line_delta,boundary)
  TRACE("xSongPos.enforce_block_boundary(direction,pos,line_delta,boundary)",direction,pos,line_delta,boundary)

  assert(type(direction),"string")
  assert(type(line_delta),"number")

  if not boundary then boundary = xSongPos.DEFAULT_BLOCK_MODE end

  if rns.transport.loop_block_enabled then

    if (boundary == xSongPos.BLOCK_BOUNDARY.NONE) then
      return pos.line + line_delta
    end

    local block_pos = rns.transport.loop_block_start_pos
    if (pos.sequence ~= block_pos.sequence) then
      return pos.line + line_delta
    end

    -- hard_boundary: if outside block, go to first/last line in block
    -- always: if inside block, wrap around
    local loop_block_end_pos = xBlockLoop.get_end()
    local hard_boundary = (boundary == xSongPos.BLOCK_BOUNDARY.HARD)
    local within_block = 
      xBlockLoop.within(block_pos.sequence,pos.line,loop_block_end_pos)
    local within_block_post = 
      xBlockLoop.within(block_pos.sequence,pos.line+line_delta,loop_block_end_pos)
    if (direction == "increase") then
      if (hard_boundary and not within_block) then
        return rns.transport.loop_block_start_pos.line
      end
      if (within_block and not within_block_post) then
        return -1 + block_pos.line + (pos.line+line_delta) - loop_block_end_pos
      end
    elseif (direction == "decrease") then
      if (hard_boundary and not within_block) then
        return loop_block_end_pos
      end
      if (within_block and not within_block_post) then
        return 1 + loop_block_end_pos + (pos.line+line_delta) - rns.transport.loop_block_start_pos.line
      end
    end
  end

  return pos.line + line_delta

end

---------------------------------------------------------------------------------------------------
-- [Static] Get the difference in lines between two song-positions
-- @param pos1 (SongPos)
-- @param pos2 (SongPos)
-- @return int

function xSongPos.get_line_diff(pos1,pos2)
  TRACE("xSongPos.get_line_diff(pos1,pos2)",pos1,pos2)

  local num_lines = 0

  if xSongPos.equal(pos1,pos2) then
    return num_lines
  end

  local early,late
  if not xSongPos.less_than(pos1,pos2) then
    early,late = pos2,pos1
  else
    early,late = pos1,pos2 
  end

  if (pos1.sequence == pos2.sequence) then
    return late.line - early.line
  else
    for seq_idx = early.sequence, late.sequence do
      local patt_num_lines = xPatternSequencer.get_number_of_lines(seq_idx)
      if (seq_idx == early.sequence) then
        num_lines = num_lines + patt_num_lines - early.line
      elseif (seq_idx == late.sequence) then
        num_lines = num_lines + late.line
      else
        num_lines = num_lines + patt_num_lines
      end
    end
    return num_lines
  end

end

---------------------------------------------------------------------------------------------------

function xSongPos.less_than(pos1,pos2)
  if (pos1.sequence == pos2.sequence) then
    return (pos1.line < pos2.line)
  else
    return (pos1.sequence < pos2.sequence)
  end
end

---------------------------------------------------------------------------------------------------

function xSongPos.equal(pos1,pos2)
  if (pos1.sequence == pos2.sequence) and (pos1.line == pos2.line) then
    return true
  else
    return false
  end
end

---------------------------------------------------------------------------------------------------

function xSongPos.less_than_or_equal(pos1,pos2)
  if (pos1.sequence == pos2.sequence) then
    if (pos1.line == pos2.line) then
      return true
    else
      return (pos1.line < pos2.line)
    end
  else
    return (pos1.sequence < pos2.sequence)
  end
end

