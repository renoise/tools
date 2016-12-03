--[[============================================================================
xSongPos
============================================================================]]--

--[[--

Describes a position within the project timeline
.
#

Three options are designed to deal with song boundaries, pattern-loop and 
block-loop boundaries. By default, they are set to settings which mimic
the behavior in Renoise when playing/manipulating the playback position:

self.bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP
self.loop_boundary = xSongPos.LOOP_BOUNDARY.SOFT
self.block_boundary = xSongPos.BLOCK_BOUNDARY.SOFT

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

-------------------------------------------------------------------------------
-- constructor - create new position 
-- at the very least, you need to specify a table containing {sequence,line}
-- @param pos[opt] (renoise.SongPos, xSongPos or {sequence,line} )

function xSongPos:__init(pos)

	--- renoise.SongPos, get/set interface
	self.pos = property(self.get_pos,self.set_pos)

	--- position in the pattern sequence.
  -- TODO make property
	self.sequence = pos and pos.sequence or nil

	--- position in the pattern at the given pattern sequence.
  -- TODO make property
	self.line = pos and pos.line or nil

  local is_xpos = (type(pos) == "xSongPos")

  --- int, travelled distance (in lines)
  -- note: this is not reliable unless you are (exclusively) using 
  -- the increase/decrease methods to control the position! 
  self.lines_travelled = is_xpos and 
    pos.lines_travelled or 0

  --- xSongPos.OUT_OF_BOUNDS, deal with sequence (song) boundaries
  self.bounds_mode = is_xpos and 
    pos.bounds_mode or xSongPos.OUT_OF_BOUNDS.LOOP

  --- xSongPos.LOOP_BOUNDARY, deals with patt-loop boundaries
  self.loop_boundary = is_xpos and 
    pos.loop_boundary or xSongPos.LOOP_BOUNDARY.SOFT

  --- xSongPos.BLOCK_BOUNDARY, deals with block-loop boundaries
  self.block_boundary = is_xpos and 
    pos.block_boundary or xSongPos.BLOCK_BOUNDARY.SOFT


end

--==============================================================================
-- Getters and setters 
--==============================================================================

-- returning a renoise.SongPos makes it possible
-- to use standard operators on objects
function xSongPos:get_pos()
  if not self.sequence or not self.line then
    return nil
  end
	local pos = rns.transport.playback_pos
	pos.sequence = self.sequence
	pos.line = self.line
	return pos
end

function xSongPos:set_pos(seq,ln)
  assert(type(seq) == "number")
  assert(type(ln) == "number")
  self.lines_travelled = 0
	self.sequence = seq
	self.line = ln
end

-------------------------------------------------------------------------------
-- Static methods
-------------------------------------------------------------------------------
-- Retrieve the pattern index while respecting the OUT_OF_BOUNDS mode
-- @param seq_idx, sequence index 
-- @return int or nil 

function xSongPos.get_pattern_index(seq_idx)
  --TRACE("xSongPos:get_pattern_index(seq_idx)",seq_idx,type(seq_idx))

  return rns.sequencer:pattern(seq_idx)

end

-------------------------------------------------------------------------------
-- Retrieve the pattern index 
-- OPTIMIZE how to implement a caching mechanism? 
-- @param seq_idx, sequence index 
-- @return int or nil 

function xSongPos.get_pattern_num_lines(seq_idx)
  --TRACE("xSongPos.get_pattern_num_lines(seq_idx)",seq_idx)
	
  assert(type(seq_idx) == "number")

  local patt_idx = rns.sequencer:pattern(seq_idx)
  if patt_idx then
    return rns:pattern(patt_idx).number_of_lines
  end

end

--------------------------------------------------------------------------------
-- @param seq_idx, sequence index
-- @return int, sequence index or nil

function xSongPos.end_of_sequence_loop(seq_idx)

  assert(type(seq_idx) == "number")

	if (rns.transport.loop_sequence_end == seq_idx) then
		return rns.transport.loop_sequence_start
	end

end

--------------------------------------------------------------------------------
-- @param seq_idx, sequence index
-- @return int, sequence index or nil

function xSongPos.start_of_sequence_loop(seq_idx)

  assert(type(seq_idx) == "number")

	if (rns.transport.loop_sequence_start == seq_idx) then
		return rns.transport.loop_sequence_end
	end

end

--------------------------------------------------------------------------------
-- check if line is equal to, or beyond end of block-loop
-- @param line_idx, line index
-- @return int, line index or nil
--[[
function xSongPos.end_of_blockloop(line_idx)

  assert(type(line_idx) == "number")

	if (line_idx >= xBlockLoop.get_end() ) then
		return rns.transport.loop_block_start_pos.line
	end

end

--------------------------------------------------------------------------------
-- check if line is equal to, or before start of block-loop
-- @param line_idx, line index
-- @return int, line index or nil

function xSongPos.start_of_blockloop(line_idx)

  assert(type(line_idx) == "number")

	if (line_idx <= rns.transport.loop_block_start_pos.line) then
		return xBlockLoop.get_end()
	end

end
]]
--------------------------------------------------------------------------------
-- check if position is within actual song boundaries
-- @param seq_idx, int
-- @param line_idx, int
-- @return bool

function xSongPos.within_bounds(seq_idx,line_idx)

  if (seq_idx > #rns.sequencer.pattern_sequence) then
    return false
  elseif (seq_idx < 1) then
    return false
  else
    return true
  end

end

--------------------------------------------------------------------------------
-- @param pos1 (SongPos)
-- @param pos2 (SongPos)
-- @return int

function xSongPos.get_line_diff(pos1,pos2)

  local num_lines = 0

  if (pos1 == pos2) then
    return num_lines
  end

  pos1 = xSongPos(pos1)
  pos2 = xSongPos(pos2)
  
  local early,late
  if (pos1 > pos2) then
    early,late = pos2,pos1
  else
    early,late = pos1,pos2 
  end

  if (pos1.sequence == pos2.sequence) then
    return late.line - early.line
  else
    for seq_idx = early.sequence, late.sequence do
      local patt_num_lines = xSongPos.get_pattern_num_lines(seq_idx)
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

--==============================================================================
-- Class Methods
--==============================================================================
-- Normalize the position, takes us from an 'imaginary' position to one  
-- that respect the actual pattern length/sequence plus loops

function xSongPos:normalize()

  local seq_idx = self.sequence
  local line_idx = self.line

  -- cap sequence if out-of-bounds ------------------------
  local seq_length = #rns.sequencer.pattern_sequence
  if (seq_idx > seq_length) then
    seq_idx = seq_length
  elseif (seq_idx < 1) then
    seq_idx = 1
  end

  -- check for pattern out-of-bounds ----------------------
  local patt_num_lines = xSongPos.get_pattern_num_lines(seq_idx)
  if (line_idx < 1) then
    self:decrease_by_lines(line_idx-patt_num_lines)
  elseif (line_idx > patt_num_lines) then 
    self.line = patt_num_lines
    self:increase_by_lines(line_idx-patt_num_lines)
  end

  return self.pos

end

--------------------------------------------------------------------------------
-- increase the position by X number of lines

function xSongPos:increase_by_lines(num_lines)

  assert(type(num_lines) == "number")

  -- no action needed
  if (num_lines == 0) then
    return
  end

  -- true when no further action is needed
  local done = false

  local seq_idx = self.sequence
  local line_idx = self.line

  -- sanity check: sequence within song boundaries?
  if (seq_idx > #rns.sequencer.pattern_sequence) then
    LOG("*** xSongPos - ignore out-of-bounds sequence index")
    return
  end

  -- even when we are supposedly spanning multiple 
  -- patterns, block looping might prevent this
  local exiting_blockloop = false
  if rns.transport.loop_block_enabled then
    exiting_blockloop = (self.block_boundary < xSongPos.BLOCK_BOUNDARY.NONE) and
      xBlockLoop.exiting(seq_idx,line_idx,num_lines) or false
  end

  local patt_num_lines = xSongPos.get_pattern_num_lines(seq_idx)
  if (line_idx+num_lines <= patt_num_lines) or exiting_blockloop then
    self.sequence = seq_idx
    self.line = self:enforce_block_boundary("increase",self.line,num_lines)
  else
    local lines_remaining = num_lines - (patt_num_lines - line_idx)
    while(lines_remaining > 0) do
      seq_idx = seq_idx + 1
      seq_idx,line_idx,done = 
        self:enforce_boundary("increase",seq_idx,lines_remaining)
      if done then
        if (self.bounds_mode == xSongPos.OUT_OF_BOUNDS.CAP) then
          -- reduce num_lines, or lines_travelled will no longer be correct
          num_lines = num_lines - lines_remaining
          done = false
        end
        break
      end

      patt_num_lines = xSongPos.get_pattern_num_lines(seq_idx)
      lines_remaining = lines_remaining - patt_num_lines

      -- check if we have reached our goal
      if (lines_remaining < 0) then
        line_idx = lines_remaining + patt_num_lines
        break
      end

    end

    self.sequence=seq_idx
    self.line=line_idx
  
  end

  if not done then
    self.lines_travelled = self.lines_travelled + num_lines
  end

end

--------------------------------------------------------------------------------
-- subtract a number of lines from position
-- @param num_lines, int

function xSongPos:decrease_by_lines(num_lines)

  assert(type(num_lines) == "number")

  -- no action needed
  if (num_lines == 0) then
    return
  end

  -- true when no further action is needed
  local done = false

  local seq_idx = self.sequence
  local line_idx = self.line

  -- even when we are supposedly spanning multiple 
  -- patterns, block looping might prevent this
  local exiting_blockloop = 
    (self.block_boundary < xSongPos.BLOCK_BOUNDARY.NONE) and
      xBlockLoop.exiting(seq_idx,line_idx,-num_lines) or false

  if (self.line-num_lines > 0) or exiting_blockloop then
    self.sequence = seq_idx
    self.line = self:enforce_block_boundary("decrease",self.line,-num_lines)

  else
    local patt_num_lines = xSongPos.get_pattern_num_lines(seq_idx)
    local lines_remaining = num_lines - line_idx

    -- make sure loop is evaluated at least once
    local first_run = true
    while first_run or (lines_remaining > 0) do

      first_run = false
      seq_idx = seq_idx - 1

      seq_idx,line_idx,done = 
        self:enforce_boundary("decrease",seq_idx,lines_remaining)
      if done then
        if (self.bounds_mode == xSongPos.OUT_OF_BOUNDS.CAP) then
          -- reduce num_lines, or lines_travelled will no longer be correct
          num_lines = -1 + num_lines - lines_remaining
          done = false
        end
        break
      end

      patt_num_lines = xSongPos.get_pattern_num_lines(seq_idx)
      lines_remaining = lines_remaining - patt_num_lines

      -- check if we have reached our goal
      if (lines_remaining <= 0) then
        line_idx = -lines_remaining
        if (line_idx < 1) then
          -- zero is not a valid line index, normalize!!
          local new_pos = xSongPos({sequence=seq_idx,line=line_idx})
          new_pos:decrease_by_lines(1)
          seq_idx = new_pos.sequence
          line_idx = new_pos.line
        end
        break
      end

    end
    self.sequence=seq_idx
    self.line=line_idx
  end
  
  if not done then
    self.lines_travelled = self.lines_travelled - num_lines
  end

end

--------------------------------------------------------------------------------
-- restrict the position to boundaries (sequence, loop)
-- @param direction, string ("increase" or "decrease")
-- @param seq_idx, int
-- @param line_idx, int
-- @return sequence,line,done
--  sequence (int)
--  line (int)
--  done (bool), true when no further action needed (capped/nullified)

function xSongPos:enforce_boundary(direction,seq_idx,line_idx)

  assert(type(direction),"string")
  assert(type(seq_idx),"number")
  assert(type(line_idx),"number")

  -- true when no further action is needed
  local done = false


  -- pattern loop -----------------------------------------
  -- if current pattern is looped, stay within it
  -- (pattern loop takes precedence, just like in Renoise -
  -- we are checking for a sequence loop in the code below)
  if rns.transport.loop_pattern then
    seq_idx = (direction == "increase") and 
      (seq_idx - 1) or (seq_idx + 1)
    return seq_idx,line_idx,done
  end

  -- sequence loop ----------------------------------------
  -- consider if we have moved into a pattern, 
  -- perhaps we need to revise the sequence index?
  -- (looping should work "backwards" too)
  if (rns.transport.loop_sequence_start ~= 0) then
    local hard_boundary = (self.loop_boundary == xSongPos.LOOP_BOUNDARY.HARD)
    if (direction == "increase") then
      local loop_start = hard_boundary and
        rns.transport.loop_sequence_start.sequence or
        self.end_of_sequence_loop(seq_idx-1)
      if loop_start then
        return loop_start,line_idx,done
      end
    elseif (direction == "decrease") then
      local loop_end = hard_boundary and 
        rns.transport.loop_sequence_end.sequence or 
        self.start_of_sequence_loop(seq_idx+1)
      if loop_end then
        return loop_end,line_idx,done
      end
    end
  end

  -- sequence (entire song) -------------------------------
  if not xSongPos.within_bounds(seq_idx,line_idx) then 
    if (direction == "increase") then
      if (self.bounds_mode == xSongPos.OUT_OF_BOUNDS.CAP) then
        seq_idx = #rns.sequencer.pattern_sequence
        local patt_num_lines = xSongPos.get_pattern_num_lines(seq_idx)
        line_idx = patt_num_lines
        done = true
      elseif (self.bounds_mode == xSongPos.OUT_OF_BOUNDS.LOOP) then
        seq_idx = 1
      elseif (self.bounds_mode == xSongPos.OUT_OF_BOUNDS.NULL) then
        seq_idx = nil
        line_idx = nil
        done = true
      end
    elseif (direction == "decrease") then
      if (self.bounds_mode == xSongPos.OUT_OF_BOUNDS.CAP) then
        seq_idx = 1
        line_idx = 1
        done = true
      elseif (self.bounds_mode == xSongPos.OUT_OF_BOUNDS.LOOP) then
        seq_idx = #rns.sequencer.pattern_sequence
        local last_patt_lines = xSongPos.get_pattern_num_lines(seq_idx)
        line_idx = last_patt_lines - line_idx 
      elseif (self.bounds_mode == xSongPos.OUT_OF_BOUNDS.NULL) then
        seq_idx = nil
        line_idx = nil
        done = true
      end
    end
  end

  return seq_idx, line_idx, done

end

--------------------------------------------------------------------------------
-- restrict the position to boundaries (block-loop)
-- @param direction, string ("increase" or "decrease")
-- @param line_idx (int)
-- @param line_delta (int), #lines to add/subtract, negative when decreasing
-- @return line (int)

function xSongPos:enforce_block_boundary(direction,line_idx,line_delta)

  assert(type(direction),"string")
  assert(type(line_idx),"line_idx")

  if rns.transport.loop_block_enabled then

    if (self.block_boundary == xSongPos.BLOCK_BOUNDARY.NONE) then
      return line_idx + line_delta
    end

    local block_pos = rns.transport.loop_block_start_pos
    if (self.sequence ~= block_pos.sequence) then
      return line_idx + line_delta
    end

    -- hard_boundary: if outside block, go to first/last line in block
    -- always: if inside block, wrap around
    local loop_block_end_pos = xBlockLoop.get_end()
    local hard_boundary = (self.block_boundary == xSongPos.BLOCK_BOUNDARY.HARD)
    local within_block = 
      xBlockLoop.within(block_pos.sequence,line_idx,loop_block_end_pos)
    local within_block_post = 
      xBlockLoop.within(block_pos.sequence,line_idx+line_delta,loop_block_end_pos)
    if (direction == "increase") then
      if (hard_boundary and not within_block) then
        return rns.transport.loop_block_start_pos.line
      end
      if (within_block and not within_block_post) then
        return -1 + block_pos.line + (line_idx+line_delta) - loop_block_end_pos
      end
    elseif (direction == "decrease") then
      if (hard_boundary and not within_block) then
        return loop_block_end_pos
      end
      if (within_block and not within_block_post) then
        return 1 + loop_block_end_pos + (line_idx+line_delta) - rns.transport.loop_block_start_pos.line
      end
    end
  end

  return line_idx + line_delta

end

--------------------------------------------------------------------------------
-- return the next beat position

function xSongPos:next_beat()

  local lines_beat = rns.transport.lpb

  local next_beat = math.floor(self.line/lines_beat)+1
  local next_line = 1 + next_beat*lines_beat

  self:increase_by_lines(next_line - self.line)

end

--------------------------------------------------------------------------------
-- return the next bar position

function xSongPos:next_bar()

  local lines_beat = rns.transport.lpb
  local lines_bar = lines_beat * renoise.song().transport.metronome_beats_per_bar

  local next_beat = math.floor(self.line/lines_bar)+1
  local next_line = 1 + next_beat*lines_bar

  self:increase_by_lines(next_line - self.line)

end

--------------------------------------------------------------------------------
-- return the next block position

function xSongPos:next_block()

  local lines_block = xBlockLoop.get_block_lines(self.sequence)

  local next_beat = math.floor(self.line/lines_block)+1
  local next_line = 1 + next_beat*lines_block

  self:increase_by_lines(next_line - self.line)

end

--------------------------------------------------------------------------------
-- return the beginning of next pattern 

function xSongPos:next_pattern()

  local patt_num_lines = xSongPos.get_pattern_num_lines(self.sequence)
  local next_line = 1 + patt_num_lines

  self:increase_by_lines(next_line - self.line)

end



-------------------------------------------------------------------------------
-- Metamethods (operators)
-------------------------------------------------------------------------------

-- sets handler for '==', '~='
function xSongPos:__eq(other)
  --TRACE("xSongPos:__eq(other)",other)
	return (self.pos == other.pos)
end

-- sets handler for '<=', '>='
function xSongPos:__le(other)
  if (self.sequence == other.sequence) then
    if (self.line == other.line) then
      return true
    else
      return (self.line < other.line)
    end
  else
    return (self.sequence < other.sequence)
  end
  --[[
  return (self.pos == other.pos) or 
    (self.pos > other.pos)
  ]]
end

-- sets handler for '<', '>' 
function xSongPos:__lt(other)
  if (self.sequence == other.sequence) then
    return (self.line < other.line)
  else
    return (self.sequence < other.sequence)
  end
  --[[
	return (self.pos > other.pos)
  ]]
end

function xSongPos:__tostring()
  return ("xSongPos: {sequence:%s,line:%s,lines_travelled:%s}"):format(tostring(self.sequence),tostring(self.line),tostring(self.lines_travelled))
end



