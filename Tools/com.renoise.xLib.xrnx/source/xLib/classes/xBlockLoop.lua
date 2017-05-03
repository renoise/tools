--[[===============================================================================================
xBlockLoop
===============================================================================================]]--

--[[--

Methods for working with the Renoise loop-block
.
#

If you are planning to use this class for realtime manipulation of the block-loop, create an 
instance of the class and work with those properties. This is preferred over working directly 
on the values return from the Renoise API, as those can change during the evaluation of code. 

]]



class 'xBlockLoop'

---------------------------------------------------------------------------------------------------
-- [Constructor] accepts a single argument for initializing the class  

function xBlockLoop:__init(...)

  local args = cLib.unpack_args(...)

  -- properties --

  --- (number) number of lines to look ahead 
  self.writeahead = args.writeahead or 1

  --- (number) where the loop starts
  self.start_line = args.start_line or nil

  --- (number) where the loop ends
  self.end_line = args.end_line or nil

  --- (number) length of loop (read-only)
  self.length = property(self.get_length)
  
  -- initialize --

  if not self.start_line then
    self.start_line = xBlockLoop.get_start()
  end

  if not self.end_line then
    self.end_line = xBlockLoop.get_end()
  end


end

---------------------------------------------------------------------------------------------------
-- [Class] get length of loop

function xBlockLoop:get_length()
  return self.end_line - self.start_line + 1
end

---------------------------------------------------------------------------------------------------
-- [Class] check if line is near top of loop

function xBlockLoop:pos_near_top(line)
  return (line <= self.start_line+self.writeahead) 
end

---------------------------------------------------------------------------------------------------
-- [Class] check if line is near end of loop

function xBlockLoop:pos_near_end(line)
  
  return (line >= (self.end_line-self.writeahead))
    
end

---------------------------------------------------------------------------------------------------
-- [Static] Retrive number of lines in a block for a given pattern 

function xBlockLoop.get_block_lines(seq_idx)
  TRACE("xBlockLoop.get_block_lines(seq_idx)",seq_idx)

  local patt_num_lines = xSongPos.get_pattern_num_lines(seq_idx)
  return math.max(1,patt_num_lines/rns.transport.loop_block_range_coeff)

end

---------------------------------------------------------------------------------------------------
-- [Static] Return start line of the currently set block loop 
-- @return int, line index or nil

function xBlockLoop.get_start()

  if not rns.transport.loop_block_enabled then
    return 
  end

  local loop_pos = rns.transport.loop_block_start_pos
  return loop_pos.line

end

---------------------------------------------------------------------------------------------------
-- [Static] Calculates end line of the currently set block loop 
-- @return int, line index or nil

function xBlockLoop.get_end()

  if not rns.transport.loop_block_enabled then
    return 
  end

  local loop_pos = {
    sequence = rns.transport.loop_block_start_pos.sequence,
    line = rns.transport.loop_block_start_pos.line,
  }

  -- in special cases, the loop_pos might report an invalid sequence index
  -- (such as when the loop is positioned on the last pattern,
  -- and we then cut a previous pattern. In this case, check the length)
  if (loop_pos.sequence > #rns.sequencer.pattern_sequence) then
    LOG("*** xBlockLoop - fixing out-of-bounds value for end sequence",loop_pos.sequence,#rns.sequencer.pattern_sequence)
    loop_pos.sequence = #rns.sequencer.pattern_sequence
  end

  local block_lines = xBlockLoop.get_block_lines(loop_pos.sequence)
  return math.floor(loop_pos.line + block_lines - 1)

end

---------------------------------------------------------------------------------------------------
-- [Static] Determine if position is within currently set block loop
-- @param seq_idx (int) 
-- @param line_idx (int) line to check
-- @param end_pos (int) optional, avoids having to calculate this
-- @return bool

function xBlockLoop.within(seq_idx,line_idx,end_pos)

  assert(type(seq_idx),"number")
  assert(type(line_idx),"number")

  if not rns.transport.loop_block_enabled then
    return false
  end

  if (rns.transport.loop_block_start_pos.sequence ~= seq_idx) then
    return false
  end

  local loop_block_end_pos = end_pos or xBlockLoop.get_end()
  return  (line_idx >= rns.transport.loop_block_start_pos.line) and 
    (line_idx <= loop_block_end_pos) 

end

---------------------------------------------------------------------------------------------------
-- [Static] Check if we are heading out of a block-loop
-- @param seq_idx (int)
-- @param line_idx (int)
-- @param line_delta (int), #lines to add/subtract, negative when decreasing
-- @param end_pos (int) optional, avoids having to calculate this
-- @return line (int)

function xBlockLoop.exiting(seq_idx,line_idx,line_delta,end_pos)

  assert(type(seq_idx),"number")
  assert(type(line_idx),"number")
  assert(type(line_delta),"number")

  local exited = false
  if rns.transport.loop_block_enabled and
    (rns.transport.loop_block_start_pos.sequence == seq_idx)
  then
    local loop_block_end_pos = end_pos or xBlockLoop.get_end()
    local within_block = 
      xBlockLoop.within(seq_idx,line_idx,loop_block_end_pos)
    local within_block_post = 
      xBlockLoop.within(seq_idx,line_idx+line_delta,loop_block_end_pos)
    exited = (within_block and not within_block_post)
  end

  return exited

end
