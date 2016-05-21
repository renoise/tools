--[[============================================================================
xPlayPos
============================================================================]]--

--[[--

Extended play-position which support fractional time (‘between lines’) 
.
#


### How to use

  -- create an instance of the class
  local pos = xPlayPos()

  -- call update() when idle to track playback
  pos:update()
  
  -- ask for the position (normal SongPos object)
  pos:get()

  -- ask for the expanded position (table)
  pos:get_fractional()


]]

class 'xPlayPos'


function xPlayPos:__init()

  -- internal --

  --- int, SongPos, last position where a beat started
  self.last_beat_pos = nil

  -- number, last_beat_pos as beats
  self.last_beat = nil

  -- properties --

  --- int
  self.line = property(self.get_line,self.set_line)
  self._line = nil

  --- int
  self.sequence = property(self.get_sequence,self.set_sequence)
  self._sequence = nil

  -- initialize --

  local pos = rns.transport.playback_pos
  self.line = pos.line
  self.sequence = pos.sequence


end

-------------------------------------------------------------------------------
-- Getters/Setters
-------------------------------------------------------------------------------

function xPlayPos:get_line()
  return self._line
end

function xPlayPos:set_line(val)
  assert(type(val)=="number","Expected line to be a number")
  self._line = val
end

-------------------------------------------------------------------------------

function xPlayPos:get_sequence()
  return self._sequence
end

function xPlayPos:set_sequence(val)
  assert(type(val)=="number","Expected sequence to be a number")
  self._sequence = val
end

-------------------------------------------------------------------------------
-- Class Methods
-------------------------------------------------------------------------------

function xPlayPos:update()
  self:set(rns.transport.playback_pos)
end

-------------------------------------------------------------------------------
--- call as often as possible to maintain/track position
-- @param pos (SongPos)

function xPlayPos:set(pos)

  if self:has_changed(pos) then
    self:maintain_position(pos)
  end

  self.line = pos.line
  self.sequence = pos.sequence

end

-------------------------------------------------------------------------------
-- return a valid object for SongPos comparison operators 
-- @return SongPos

function xPlayPos:get()
  local pos = rns.transport.playback_pos
  pos.line = self.line
  pos.sequence = self.sequence
  return pos
end

-------------------------------------------------------------------------------
-- return a 'full' object, including fractional time
-- @return SongPos

function xPlayPos:get_fractional()

  self.line = rns.transport.playback_pos.line
  self.sequence = rns.transport.playback_pos.sequence

  local beats = xLib.fraction(rns.transport.playback_pos_beats)
  local beats_scaled = beats * rns.transport.lpb
  local line_in_beat = math.floor(beats_scaled)
  local fraction = xLib.scale_value(beats_scaled,line_in_beat,line_in_beat+1,0,1)
  --print("fraction",rns.transport.playback_pos,fraction)

  return {
    line = self.line,
    sequence = self.sequence,
    fraction = fraction,
  }

end

-------------------------------------------------------------------------------
-- @param SongPos
-- @return boolean

function xPlayPos:has_changed(pos)
  return not ((self.line == pos.line)
    and (self.sequence == pos.sequence))
end

-------------------------------------------------------------------------------
-- look for when we enter a 'beat' in the global timeline

function xPlayPos:maintain_position(pos)

  -- within the first line of a "song beat"?
  local beats = xLib.fraction(rns.transport.playback_pos_beats)
  local line_in_beat = beats * rns.transport.lpb
  local beat_pos_set = false
  if (line_in_beat < 1) then
    beat_pos_set = true
    self.last_beat_pos = pos
    --print("on first line of beat",pos,beats)
  end

  -- detect when first line in beat is skipped
  -- (due to fast playback or heavy CPU load)
  if not beat_pos_set then
    if self.last_beat and
      (self.last_beat > beats)
    then
      local xpos = xSongPos(pos)
      xpos:decrease_by_lines(math.floor(line_in_beat))
      self.last_beat_pos = xpos.pos
      --print("last_beat_pos was skipped, set to",self.last_beat_pos)
    end
  end

  self.last_beat = beats

end

-------------------------------------------------------------------------------
-- Metamethods - see also @{xSongPos}
-------------------------------------------------------------------------------
--[[
-- __eq sets handler for '==', '~='
function xPlayPos:__eq(other)
	return ((self.line == other.line)
    and (self.sequence == other.sequence))
end

-- __le sets handler for '<=', '>='
function xPlayPos:__le(other)
  if (self.sequence == other.sequence) then
    if (self.line == other.line) then
      return true
    else
      return (self.line < other.line)
    end
  else
    return (self.sequence < other.sequence)
  end
end

-- __lt sets handler for '<', '>' 
function xPlayPos:__lt(other)
  if (self.sequence == other.sequence) then
    return (self.line < other.line)
  else
    return (self.sequence < other.sequence)
  end
end
]]

function xPlayPos:__tostring()
  return type(self)
    .. ", sequence = " .. tostring(self.sequence)
    .. ", line = " .. tostring(self.line)
    .. ", fraction " .. tostring(self.fraction)

end