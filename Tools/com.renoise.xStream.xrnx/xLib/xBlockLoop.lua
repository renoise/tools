--[[============================================================================
xBlockLoop
============================================================================]]--
--[[
	
	Methods for working with the renoise loop_block


  TODO ability to observe renoise blockloop, automatically maintain 
  properties that otherwise are expensive to look up (end line)

]]



class 'xBlockLoop'

--------------------------------------------------------------------------------
-- retrieve 'expanded' block loop info (resolving the end point)
-- @return table or nil
--  sequence
--  start_line
--  end_line

function xBlockLoop.get()
  TRACE("xBlockLoop.get()")

  if not rns.transport.loop_block_enabled then
    return 
  end

  return {
    sequence=rns.transport.loop_block_start_pos.sequence,
    start_line=rns.transport.loop_block_start_pos.line,
    end_line=xBlockLoop.get_end()
  }

end

-------------------------------------------------------------------------------
-- calculates end line of the block loop 
-- @return int, line index or nil

function xBlockLoop.get_end()
  TRACE("xBlockLoop.get_end()")

  if not rns.transport.loop_block_enabled then
    return 
  end

  local loop_pos = rns.transport.loop_block_start_pos
  local patt_num_lines = xSongPos.get_pattern_num_lines(loop_pos.sequence)
  local loop_lines = math.max(1,patt_num_lines/rns.transport.loop_block_range_coeff)
  return math.floor(loop_pos.line + loop_lines - 1)

end

-------------------------------------------------------------------------------
-- determine if position is within block loop
-- @param seq_idx (int) 
-- @param line_idx (int) line to check
-- @param end_pos (int) optional, avoids having to calculate this
-- @return bool

function xBlockLoop.within(seq_idx,line_idx,end_pos)
  TRACE("xBlockLoop.within(seq_idx,line_idx,end_pos)",seq_idx,line_idx,end_pos)

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

--------------------------------------------------------------------------------
-- check if we are heading out of a blockloop
-- @param seq_idx (int)
-- @param line_idx (int)
-- @param line_delta (int), #lines to add/subtract, negative when decreasing
-- @param end_pos (int) optional, avoids having to calculate this
-- @return line (int)

function xBlockLoop.exiting(seq_idx,line_idx,line_delta,end_pos)
  TRACE("xBlockLoop.exiting(seq_idx,line_idx,line_delta,end_pos)",seq_idx,line_idx,line_delta,end_pos)

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
