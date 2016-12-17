--[[============================================================================
xNotePos
============================================================================]]--

--[[--

Describes a position of a note-column within the project timeline
.
#

The name might be slightly misleading, as this class supports positions in both NoteColumns and EffectColumns (any kind of track)

]]

class 'xNotePos'

-------------------------------------------------------------------------------

function xNotePos:__init(...)
  --TRACE("xNotePos:__init(...)")

  local args = cLib.unpack_args(...)
  TRACE("xNotePos:__init - args #1",args)

  -- if no args, provide cursor position 
  if type(args)=="table" 
    and table.is_empty(args) 
  then
    args = {
      sequence = rns.selected_sequence_index,
      track = rns.selected_track_index,
      line = rns.selected_line_index,
      column = xTrack.get_selected_column_index(),
    }
  end

  TRACE("xNotePos:__init - args #2",args)

  -- number, sequence index of pattern
  self.sequence = args.sequence 

  -- number, track index 
  self.track = args.track

  -- number, line index
  self.line = args.line

  -- number, note/effect column index (across visible columns)
  self.column = args.column

end

-------------------------------------------------------------------------------
-- resolve the position, perform some validation steps
-- @return number (pattern index or nil if failed)
-- @return renoise.Pattern or string (if failed)
-- @return renoise.Track
-- @return renoise.PatternTrack
-- @return renoise.PatternLine

function xNotePos:resolve()
  TRACE("xNotePos:resolve()",self)

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
-- @return renoise.NoteColumn/EffectColumn or nil if invalid/out of bounds
-- @return string, error message if failed 

function xNotePos:get_column()

  local patt_idx,patt_or_err,track,ptrack,line = self:resolve()
  if not patt_idx then
    return nil,patt_or_err
  end

  return xLine.get_column(line,self.column,track)


end

-------------------------------------------------------------------------------
-- (attempt to) select the stored position
-- @return string, error message if failed 

function xNotePos:select()

  local patt_idx,patt_or_err,track,ptrack,line = self:resolve()
  if not patt_idx then
    return err
  end

  rns.selected_sequence_index = self.sequence
  rns.selected_track_index = self.track
  rns.selected_line_index = self.line
  xTrack.set_selected_column_index(track,self.column)

end

-------------------------------------------------------------------------------

function xNotePos:__tostring()

  return type(self)
    .. ", sequence=" ..tostring(self.sequence)
    .. ", track="..tostring(self.track)
    .. ", line=" ..tostring(self.line)
    .. ", column=" ..tostring(self.column)

end