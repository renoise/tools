--[[============================================================================
xCursorPos
============================================================================]]--

--[[--

Describes the position of the edit cursor within the project timeline
.
#

]]

class 'xCursorPos'

-------------------------------------------------------------------------------
-- [Constructor] accepts a single argument for initializing the class  

function xCursorPos:__init(...)
  --TRACE("xCursorPos:__init(...)")

  local args = cLib.unpack_args(...)

  -- if no args, provide cursor position 
  if type(args)=="table" 
    and table.is_empty(args) 
  then
    local highres = (rns.transport.follow_player and rns.transport.playing)
      and xCursorPos.get_highres_pos() or {fraction = 0}
    args = {
      sequence = rns.selected_sequence_index,
      track = rns.selected_track_index,
      line = rns.selected_line_index,
      fraction = highres.fraction,
      column = xTrack.get_selected_column_index(),
    }
  end

  --- number, sequence index of pattern
  self.sequence = args.sequence 

  --- number, track index 
  self.track = args.track

  --- number, line index
  self.line = args.line

  --- number, precise position in line (between 0-1)
  self.fraction = args.fraction

  --- number, note/effect column index (across visible columns)
  self.column = args.column

end

-------------------------------------------------------------------------------
-- [Class] Resolve the position, perform some validation steps
-- @return number (pattern index or nil if failed)
-- @return renoise.Pattern or string (if failed)
-- @return renoise.Track
-- @return renoise.PatternTrack
-- @return renoise.PatternLine

function xCursorPos:resolve()
  TRACE("xCursorPos:resolve()",self)

  if (self.sequence > #rns.sequencer.pattern_sequence) then
    return nil, "Sequence index is out of bounds"
  end
  if (self.line > renoise.Pattern.MAX_NUMBER_OF_LINES) then
    return nil, "Line index is out of bounds"
  end

  local patt_idx = rns.sequencer:pattern(self.sequence)
  local patt = rns.patterns[patt_idx]
  if not patt_idx then
    return nil, "Could not resolve pattern"
  end

  local track = rns.tracks[self.track]
  if not track then
    return nil, "Could not resolve track"
  end

  local ptrack = patt:track(self.track)
  local line = ptrack:line(self.line)
  if not line then
    return nil, "Could not resolve line"
  end

  return patt_idx,patt,track,ptrack,line 
  --xLine.get_column(line,self.column,track)

end

-------------------------------------------------------------------------------
-- [Class] Get the note/effect-column from the stored position
-- @return renoise.NoteColumn/EffectColumn or nil if invalid/out of bounds
-- @return string, [error message (string)]

function xCursorPos:get_column()
  TRACE("xCursorPos:get_column()")

  local patt_idx,patt_or_err,track,ptrack,line = self:resolve()
  if not patt_idx then
    return nil,patt_or_err
  end

  return xLine.get_column(line,self.column,track)

end

-------------------------------------------------------------------------------
-- [Class] Attempt to move the pattern-cursor to the stored position
-- @return string, [error message (string)]

function xCursorPos:select()
  TRACE("xCursorPos:select()")

  local patt_idx,patt_or_err,track,ptrack,line = self:resolve()
  if not patt_idx then
    return err
  end

  rns.selected_sequence_index = self.sequence
  rns.selected_track_index = self.track
  rns.selected_line_index = self.line
  xTrack.set_selected_column_index(track,self.column)

end

--------------------------------------------------------------------------------
-- [Static] Obtain a fraction position (only revelant while playback is active)
-- @return table (like songpos, but with 'fraction', a number between 0-1)

function xCursorPos.get_highres_pos()
  TRACE("xCursorPos:get_highres_pos()")

  local pos = rns.transport.playback_pos
  local beats = cLib.fraction(rns.transport.playback_pos_beats)
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

function xCursorPos:__tostring()

  return type(self)
    .. "{sequence=" ..tostring(self.sequence)
    .. ", track="..tostring(self.track)
    .. ", line=" ..tostring(self.line)
    .. ", fraction=" ..tostring(self.fraction)
    .. ", column=" ..tostring(self.column)
    .. "}"

end