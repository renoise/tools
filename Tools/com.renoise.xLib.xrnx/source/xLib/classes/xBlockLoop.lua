--[[===============================================================================================
xBlockLoop
===============================================================================================]]--

--[[--

Methods for working with the Renoise loop-block.

# About

In the Renoise API, the loop-block can be controlled via transport.loop_range(). But the 
implementation is a both quite strict (as values are restricted to coefficients) and bit fuzzy, 
as you can apply that does not strictly adhere to those coefficients. As a result, the looped 
range can 'shift' after it has been set. 

This class tries to overcome those issues by providing a consistent interface and methods.  

If you are planning to use this class for realtime manipulation of the block-loop, create an 
instance of the class and work with those properties. This is preferred over working directly 
on the values returned from the API, as those can change during the evaluation of code. 

]]



class 'xBlockLoop'

xBlockLoop.COEFFS_ALL = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}
xBlockLoop.COEFFS_FOUR = {1,2,4,8,16}
xBlockLoop.COEFFS_THREE = {1,2,3,6,12}

xBlockLoop.COEFF_MODE = {
  ALL = 1,
  FOUR = 2,
  THREE = 3,
}

---------------------------------------------------------------------------------------------------
-- [Constructor] accepts a single argument for initializing the class  

function xBlockLoop:__init(...)

  local args = cLib.unpack_args(...)

  -- properties --

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
-- [Static] Retrive number of lines in a block for a given pattern 

function xBlockLoop.get_block_lines(seq_idx)
  TRACE("xBlockLoop.get_block_lines(seq_idx)",seq_idx)

  local patt_num_lines = xPatternSequencer.get_number_of_lines(seq_idx)
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

  local loop_pos = xSongPos.create(rns.transport.loop_block_start_pos)

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

---------------------------------------------------------------------------------------------------
-- Obtain the line number of the loop block previous to the current one
-- @return number or nil 

function xBlockLoop.get_previous_line_index()
  TRACE("xBlockLoop.get_previous_line_index")

  if rns.transport.loop_block_enabled then
    local coeff = rns.transport.loop_block_range_coeff
    local block_start = rns.transport.loop_block_start_pos.line
    local num_lines = rns.selected_pattern.number_of_lines
    local shift_lines = math.floor(num_lines/coeff)
    return block_start-shift_lines
  end

end

---------------------------------------------------------------------------------------------------
-- Obtain the line number of the loop block previous to the current one
-- @return number or nil 

function xBlockLoop:get_next_line_index()
  TRACE("xBlockLoop.get_next_line_index")

  if rns.transport.loop_block_enabled then
    local coeff = rns.transport.loop_block_range_coeff
    local block_start = rns.transport.loop_block_start_pos.line
    local num_lines = rns.selected_pattern.number_of_lines
    local shift_lines = math.floor(num_lines/coeff)
    return block_start+shift_lines
  end

end

---------------------------------------------------------------------------------------------------
-- Enforce range of lines to nearest valid coefficient. Modelled after Renoise, 
-- in that providing a too small/large range will fit to the nearest 'block-loopable' size. 
-- <br>Some examples with a 64 line pattern:
-- <br>• 1 & 4 will enlarge to 1 & 5 (4 lines - 1/16th)
-- <br>• 1 & 6 is not altered (5 lines - 1/12th, with 4 remaining lines)
-- <br>• 2 & 7 is not altered (-//-, but shifted*) 
-- <br>* Shifting is possible through the API but not through the Renoise UI!
-- @param start_line, number 
-- @param end_line, number 
-- @param num_lines, number - number of lines in pattern 
-- @param [coeffs], table<number> (use COEFFS_ALL if undefined)
-- @return number,number - the normalized start & end line

function xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
  TRACE("xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)",start_line,end_line,num_lines,coeffs)

  assert(type(start_line)=="number")
  assert(type(end_line)=="number")
  assert(type(num_lines)=="number")

  if not coeffs then 
    coeffs = xBlockLoop.COEFFS_ALL
  end 

  local line_count = end_line - start_line 
  local ideal_coeff = num_lines/line_count
  print(">>> line_count,ideal_coeff",line_count,ideal_coeff)

  -- locate matching or closest coeff.
  local matched_coeff = false
  local closest_match = 16 -- highest possible
  for k,v in ipairs(coeffs) do
    if (v == ideal_coeff) then
      matched_coeff = true
    elseif (v > ideal_coeff) then
      if (math.ceil(ideal_coeff) == v) then
        closest_match = coeffs[k]
      else
        closest_match = coeffs[k-1]
      end
      break
    end
  end

  print(">>> matched_coeff",matched_coeff)

  -- if not a valid coefficient, expand the size
  if not matched_coeff then
    print(">>> closest_match",closest_match)
    line_count = math.floor(num_lines/closest_match)
    end_line = start_line + line_count
  end

  print(">>> line_count,end_line",line_count,end_line)

  -- if result goes beyond boundary, move back
  if (end_line > num_lines+1) then
    print(">>> end_line",end_line)
    local offset = num_lines-end_line+1
    start_line   = start_line   + offset
    end_line = end_line + offset
  end

  return start_line,end_line

end
