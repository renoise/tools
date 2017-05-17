--[[============================================================================
xPlayPos
============================================================================]]--

--[[--

Extended play-position which support fractional time (between lines).

#



## How to use

    -- create an instance of the class
    local pos = xPlayPos()

    -- set to some position 
    pos(rns.transport.playback_pos)

    -- call update() when idle to track playback
    pos:update()
    
    -- ask for the expanded position 
    pos()

    -- get any specific property:
    -- pos.fraction
    -- pos.sequence)
    -- pos.line

    -- to return it as a normal SongPos object
    xSongPos.create(pos)


]]

class 'xPlayPos'


function xPlayPos:__init()
  TRACE("xPlayPos:__init()")

  -- internal --

  --- int, SongPos, last position where a beat started
  --self.last_beat_pos = nil

  -- number, last_beat_pos as beats
  self.last_beat = nil

  -- properties --

  --- int, read-only
  self.line = property(self.get_line)
  self._line = nil

  --- int, read-only
  self.sequence = property(self.get_sequence)
  self._sequence = nil

  -- initialize --

  local pos = rns.transport.playing and
    rns.transport.playback_pos or rns.transport.edit_pos

  self._line = pos.line
  self._sequence = pos.sequence


end

-------------------------------------------------------------------------------
-- Getters/Setters
-------------------------------------------------------------------------------

function xPlayPos:get_line()
  return self._line
end

-------------------------------------------------------------------------------

function xPlayPos:get_sequence()
  return self._sequence
end

-------------------------------------------------------------------------------
-- Class Methods
-------------------------------------------------------------------------------
--- call as often as possible to maintain/track position

function xPlayPos:update()
  self:set(rns.transport.playback_pos)
end

-------------------------------------------------------------------------------
-- @param pos (SongPos)

function xPlayPos:set(pos)
  --TRACE("xPlayPos:set(pos)",pos.sequence,pos.line)

  if self:has_changed(pos) then
    self:maintain_position(pos)
  end

  self._line = pos.line
  self._sequence = pos.sequence

end

-------------------------------------------------------------------------------
-- note: a realtime version of this method exists below
-- @return table (like SongPos but with extra 'fraction' field)

function xPlayPos:__call()

  return xPlayPos.get(self,self.last_beat)

end

--------------------------------------------------------------------------------
-- [Static] Obtain a fraction position (only revelant while playback is active)
-- @return table (like songpos, but with 'fraction', a number between 0-1)

function xPlayPos.get(pos,beats)
  TRACE("xPlayPos:get_highres_pos()")

  if not pos then pos = rns.transport.playback_pos end
  if not beats then beats = rns.transport.playback_pos_beats end
  
  local beats = cLib.fraction(beats)
  local beats_scaled = beats * rns.transport.lpb
  local line_in_beat = math.floor(beats_scaled)
  local fraction = cLib.scale_value(beats_scaled,line_in_beat,line_in_beat+1,0,1)

  return {
    line = pos.line,
    sequence = pos.sequence,
    fraction = fraction,
  }

end

-------------------------------------------------------------------------------
-- @param pos SongPos
-- @return boolean

function xPlayPos:has_changed(pos)
  return not ((self._line == pos.line)
    and (self._sequence == pos.sequence))
end

-------------------------------------------------------------------------------
-- look for when we enter a 'beat' in the global timeline

function xPlayPos:maintain_position(pos)

  -- within the first line of a "song beat"?
  local beats = cLib.fraction(rns.transport.playback_pos_beats)
  --[[
  local line_in_beat = beats * rns.transport.lpb
  local beat_pos_set = false
  if (line_in_beat < 1) then
    beat_pos_set = true
    self.last_beat_pos = pos
  end

  -- detect when first line in beat is skipped
  -- (due to fast playback or heavy CPU load)
  if not beat_pos_set then
    if self.last_beat and
      (self.last_beat > beats)
    then
      local xinc = xSongPos.decrease_by_lines(math.floor(line_in_beat),pos)
      self.last_beat_pos = pos
    end
  end
  ]]
  self.last_beat = beats

end

-------------------------------------------------------------------------------

function xPlayPos:__tostring()
  return type(self)
    .. ":sequence=" .. tostring(self._sequence)
    .. ",line=" .. tostring(self._line)
    --.. ", fraction " .. tostring(self.fraction)

end