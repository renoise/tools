--==============================================================================

--- Mlrx_pos is a class for handling operations on song-position objects,
-- a more flexible implementation of the native SongPos

class 'Mlrx_pos' 

--------------------------------------------------------------------------------

--- Constructor method
-- @param pos[opt] (renoise.SongPos or Mlrx_pos)

function Mlrx_pos:__init(pos)

  if not pos then
    if rns.transport.playing then
      pos = rns.transport.playback_pos
    else
      pos = rns.transport.edit_pos
    end
  end

  self.line = pos.line
  self.sequence = pos.sequence

end

--------------------------------------------------------------------------------

--- compare with another position
-- @param other (renoise.SongPos or Mlrx_pos)

function Mlrx_pos:__eq(other)

  if (self.line == other.line) and
    (self.sequence == other.sequence)
  then
    return true
  end

end

--------------------------------------------------------------------------------

--- check if earlier than another position
-- @param other (renoise.SongPos or Mlrx_pos)

function Mlrx_pos:__lt(other)

  if (self.sequence == other.sequence) then
    return (self.line < other.line)
  elseif (self.sequence < other.sequence) then
    return true
  else
    return false
  end

end


--------------------------------------------------------------------------------

--- check if latern than another position
-- @param other (renoise.SongPos or Mlrx_pos)

function Mlrx_pos:__le(other)

  if (self.sequence == other.sequence) then
    return (self.line <= other.line)
  elseif (self.sequence <= other.sequence) then
    return true
  else
    return false
  end

end


--------------------------------------------------------------------------------

--- output some debugging info
-- @return string

function Mlrx_pos:__tostring()

  return "[Mlrx_pos: " .. self.sequence .. ", " .. self.line .. "]"

end


--------------------------------------------------------------------------------

--- quantize position to a given amount of lines 
-- note that quantization that arrive on the same line will only be allowed
-- when playback is stopped - otherwise, we choose the next point in time
-- @param quant (int) the line-quantize amount 
-- @return int (the difference in lines)

function Mlrx_pos:quantize(quant)

  -- figure out the closest quantized line
  local tmp_line = self.line%quant
  if (tmp_line==0) then
    tmp_line = quant
  end
  --print("trigger_press - tmp",tmp)

  --local quant_pos = Mlrx_pos(self)
  if (tmp_line == 1) and not rns.transport.playing then
    --self.line = self.line
  else
    self.line = self.line+(quant-tmp_line)+1
  end
  
  local force_to_start = true
  self:normalize(force_to_start)

  return quant-tmp_line

end

--------------------------------------------------------------------------------

--- ensure that a song-position stays with #number_of_lines, taking stuff like
-- pattern/sequence loop and song duration into consideration
-- @param force_to_start (bool) when dealing with quantized notes,
--    this will allow us to force a note to always trigger at the first line

function Mlrx_pos:normalize(force_to_start)

  local num_lines = Mlrx:count_lines(self.sequence)
  if (self.line > num_lines) then -- exceeded pattern length
    self.line = (force_to_start) and 1 or self.line-num_lines

    --print(" normalize - exceeded pattern length, line is now",self.line)
    if not Mlrx:pattern_is_looped() then
      self.sequence = self.sequence+1
      --print(" normalize - increase sequence to",self.sequence)
      if (self.sequence > #rns.sequencer.pattern_sequence) then
        --print(" normalize - set sequence to song start")
        self.sequence = 1
      elseif (self.sequence-1 == rns.transport.loop_sequence_end) then
        --print(" normalize - set sequence to loop start")
        self.sequence = rns.transport.loop_sequence_start
      end

    end

    local patt_idx = rns.sequencer.pattern_sequence[self.sequence]
    local patt = rns:pattern(patt_idx)
    if (patt.number_of_lines < self.line) then
      --print(" normalize - recursive action")
      self:normalize()
    end

  end

end

