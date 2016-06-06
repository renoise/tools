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

  --- table<xLine>, scheduled events
  self.events = {}

end

-------------------------------------------------------------------------------
-- read a line into the buffer from a pattern somewhere...

function xStreamBuffer:read_pos(xinc,pos,track_idx,include_hidden,include_events)
  TRACE("xStreamBuffer:read_pos()",xinc,pos,track_idx,include_hidden,include_events)

  local seq_idx,line_idx = pos.sequence,pos.line

  local xline = nil
  if self.events[xinc] then
    print(">>> read_pos - read from event buffer",xinc)
    xline = self.events[xinc]
  else
    print(">>> read_pos - read from pattern",xinc)
    xline = self.line_descriptors[xinc]
  end
  local buffered = xline and true or false
  if not buffered then 
    xline = xLine.do_read(seq_idx,line_idx,include_hidden,track_idx)
    self.line_descriptors[xinc] = table.rcopy(xline) 
  end

  return xline,buffered

end

-------------------------------------------------------------------------------
-- update all content ahead of our position
-- method is called when xStreamPos is changing position 'abruptly'

function xStreamBuffer:update_read_buffer(track_idx,include_hidden)
  TRACE("xStreamBuffer:update_read_buffer()")

  local pos = self.stream.readpos
  if pos then
    for k = 0,self.xstream.writeahead-1 do
      local xinc = pos.lines_travelled
      if self.events[xinc] then
        self.line_descriptors[xinc] = self.events[xinc]
      else
        self.line_descriptors[xinc] = xLine.do_read(
          pos.sequence,pos.line,include_hidden,track_idx)
      end
      pos:increase_by_lines(1)
    end
    self:wipe_futures()
  end

end


-------------------------------------------------------------------------------
-- wipe all data behind our current write-position
-- (see also xStreamArgs)

function xStreamBuffer:wipe_past()
  TRACE("xStreamBuffer:wipe_past()")

  local from_idx = self.xstream.stream.writepos.lines_travelled - 1
  for i = from_idx,self.lowest_xinc,-1 do
    self.output_buffer[i] = nil
    self.line_descriptors[i] = nil
    self.events[i] = nil
    print("*** wipe_past - cleared buffers at ",i)
  end

  self.lowest_xinc = from_idx
  --print("lowest_xinc ",from_idx)

end

-------------------------------------------------------------------------------
-- forget all output ahead of our current write-position
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
--- clear when preparing to stream

function xStreamBuffer:clear()
  TRACE("xStreamBuffer:clear()")

  self.highest_xinc = 0
  self.lowest_xinc = 0

  self.line_descriptors = {}
  self.output_buffer = {}
  self.events = {}

end

-------------------------------------------------------------------------------
-- return a buffer position which correspond to the desired schedule
-- @param schedule (xStream.SCHEDULE), NONE/BEAT/BAR
-- @return int (buffer position)
-- @return int (delta, difference from current position)

function xStreamBuffer:get_buffer_pos(schedule)
  print("xStreamBuffer:get_buffer_pos(schedule)",schedule)

  local live_mode = rns.transport.playing
  local writepos = self.xstream.stream.writepos

  local schedules = {
    [xStream.SCHEDULE.NONE] = function()
      local pos = xSongPos(writepos)
      if live_mode then
        pos:increase_by_lines(1)
      end
      return pos.lines_travelled - writepos.lines_travelled
    end,
    [xStream.SCHEDULE.BEAT] = function()
      local pos = xSongPos(writepos)
      pos:decrease_by_lines(1) -- too cautious when on next line?
      pos:next_beat()
      return pos.lines_travelled - writepos.lines_travelled
    end,
    [xStream.SCHEDULE.BAR] = function()
      local pos = xSongPos(writepos)
      pos:next_bar()
      return pos.lines_travelled - writepos.lines_travelled
    end,
  }

  if schedules[schedule] then
    local delta = schedules[schedule]()
    local buffer_pos = writepos.lines_travelled + delta
    return buffer_pos,delta
  else
    error("Unsupported schedule type, please use NONE/BEAT/BAR")
  end

end

-------------------------------------------------------------------------------
-- Register a scheduled xline. When outside the output range (writeahead), 
-- the line will be included as part of the regular pattern content. When 
-- inside the writeahead range, the output buffer will be affected too. 
-- TODO When a schedule already exist for a given position, offer to merge
-- the two schedules, somehow...
-- @param schedule (xStream.SCHEDULE), NONE/BEAT/BAR
-- @param xline (table, xline descriptor)

function xStreamBuffer:schedule_line(schedule,xline)
  print("xStreamBuffer:schedule_line(schedule,xline)",schedule,xline)

  assert(type(schedule)=="number")
  assert(type(xline)=="table")

  local xinc = nil
  local writepos = self.xstream.stream.writepos
  local live_mode = rns.transport.playing

  local buffer_pos,delta = self:get_buffer_pos(schedule)
  print("buffer_pos,delta",buffer_pos,delta)
  if (delta <= self.xstream.writeahead) then
    -- within output range - insert into output_buffer
    print("insert into output_buffer at position",buffer_pos)
    self.output_buffer[buffer_pos] = xLine.apply_descriptor(xline)
    self.highest_xinc = math.max(buffer_pos,self.highest_xinc)
    if (delta == 1) then
      -- immediate output!
      self.xstream:do_output(writepos,2,live_mode)
    end
  end

  -- any range: insert into events table 
  --print("self.events",delta,type(self.events),rprint(self.events))
  --self.events[delta] = xline


end

-------------------------------------------------------------------------------
-- Unregister a scheduled xline - 

function xStreamBuffer:unschedule_line(xinc)
  print("xStreamBuffer:unschedule_line(xinc)",xinc)

  -- when within output range, wipe output buffer

    -- if output is imminent, clear 

  -- remove from events table


end

-------------------------------------------------------------------------------
--[[

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


