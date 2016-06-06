--[[============================================================================
-- xStreamBuffer
============================================================================]]--

--[[

Input/output buffer for xStream

#

Content is read from the pattern as new content is requested from the callback method - this ensures that the callback always has a fully populated line to work on. 

Unlike the output buffer, the read buffer is not cleared when arguments change - it should be read only *once*. 

## About events

Events do not actually affect the buffer until the stream get_output() method is called - this means we can schedule content, but also pull it back, right until the last moment.


]]

--==============================================================================

class 'xStreamBuffer'

function xStreamBuffer:__init(xstream)

  self.xstream = xstream

  --- table<xLine descriptor> content read from pattern 
  self.line_descriptors = {}

  --- table<xLine> the output buffer
  self.output_buffer = {}

  --- int, keep track of the highest/lowest line in our buffers
  self.highest_xinc = 0
  self.lowest_xinc = 0

  --- table<pos={xLine,xNoteColumn,xEffectColumn...}>
  -- associate a position in the buffer with an xLine/xNoteColumn/xEffectColumn
  -- when adding and removing, both input and output buffer is modified
  self.events = {}

end

-------------------------------------------------------------------------------
-- read a line into the buffer from a pattern somewhere...

function xStreamBuffer:read_pos(xinc,pos,track_idx,include_hidden,include_events)
  TRACE("xStreamBuffer:read_pos()",xinc,pos,track_idx,include_hidden,include_events)

  local seq_idx,line_idx = pos.sequence,pos.line

  local xline = self.line_descriptors[xinc]
  local buffered = xline and true or false
  local has_read_buffer = xline and true or false
  if not xline then 
    xline = xLine.do_read(seq_idx,line_idx,include_hidden,track_idx)
    self.line_descriptors[xinc] = table.rcopy(xline) 
  end

  -- TODO include_events


  return xline,buffered

end

-------------------------------------------------------------------------------
-- [process] update all content ahead of our position
-- method is called when xStreamPos is changing position 'abruptly'

function xStreamBuffer:update_read_buffer(pos,track_idx,include_hidden)
  TRACE("xStreamBuffer:update_read_buffer()")

  if pos then
    for k = 0,self.xstream.writeahead-1 do
      local xinc = pos.lines_travelled
      self.line_descriptors[xinc] = xLine.do_read(
        pos.sequence,pos.line,include_hidden,track_idx)
      self.xstream.stream.readpos:increase_by_lines(1)
    end
    self:wipe_futures()
  end

end


-------------------------------------------------------------------------------
-- [process] wipe all data behind our current write-position
-- (see also xStreamArgs)

function xStreamBuffer:wipe_past()
  TRACE("xStreamBuffer:wipe_past()")

  local from_idx = self.xstream.stream.writepos.lines_travelled - 1
  for i = from_idx,self.lowest_xinc,-1 do
    self.output_buffer[i] = nil
    self.line_descriptors[i] = nil
    --print("*** wipe_past - cleared buffers at ",i)
  end

  self.lowest_xinc = from_idx
  --print("lowest_xinc ",from_idx)

end

-------------------------------------------------------------------------------
-- [process] forget all output ahead of our current write-position
-- method is automatically called when callback arguments have changed,
-- and will cause fresh line(s) to be created in the next cycle
-- (see also xStreamArgs)

function xStreamBuffer:wipe_futures()
  TRACE("xStreamBuffer:wipe_futures()")

  -- do not wipe while muted
  --if self.xstream.muted then
  --  return
  --end

  local from_idx = self.xstream.stream.writepos.lines_travelled
  if rns.transport.playing then
    -- when live streaming, exclude current line
    from_idx = from_idx+1
  end

  for i = from_idx,self.highest_xinc do
    self.output_buffer[i] = nil
    --print("*** wiped buffer at",i)
  end

  self.highest_xinc = self.xstream.stream.writepos.lines_travelled
  --print("*** self.highest_xinc",self.highest_xinc)

end


-------------------------------------------------------------------------------

function xStreamBuffer:clear()

  self.highest_xinc = 0
  self.lowest_xinc = 0

  self.line_descriptors = {}
  self.output_buffer = {}

end

-------------------------------------------------------------------------------

function xStreamBuffer:add_line(pos)

end

-------------------------------------------------------------------------------
-- clear single line (all events)

function xStreamBuffer:clear_line(pos)

end

-------------------------------------------------------------------------------
-- clear all lines ahead from given point in time

function xStreamBuffer:clear_lines(pos)

end


-------------------------------------------------------------------------------
--[[

function xStreamBuffer:add_note_column(pos,note_col)

end

-------------------------------------------------------------------------------

function xStreamBuffer:clear_note_column(pos,col_idx)

end

-------------------------------------------------------------------------------

function xStreamBuffer:clear_note_columns(pos)

end

-------------------------------------------------------------------------------

function xStreamBuffer:add_effect_column(pos,fx_col)

end

-------------------------------------------------------------------------------

function xStreamBuffer:clear_effect_column(pos,col_idx)

end

-------------------------------------------------------------------------------

function xStreamBuffer:clear_effect_columns(pos)

end


]]


