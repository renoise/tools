--[[============================================================================
-- xStreamBuffer
============================================================================]]--

--[[

Input/output buffer for xStream

#

Content is read from the pattern as new content is requested from the callback method - this ensures that the callback always has a fully populated line to work on. 

Unlike the output buffer, the read buffer is not cleared when arguments change - it should be read only *once*. 

## About scheduled events

Scheduled events do not actually affect the buffer until the stream get_output() method is called - this means we can schedule content, but also pull it back, right until the last moment.


]]

--==============================================================================

class 'xStreamBuffer'

function xStreamBuffer:__init(xstream)

  self.xstream = xstream

  --- table<xLine or descriptor> content read from pattern 
  self.line_descriptors = {}

  --- table<xLine> the output buffer
  self.output_buffer = {}

  --- table<xLine or descriptor>, scheduled events
  self.scheduled = {}

  --- int, keep track of the highest/lowest line in our buffers
  self.highest_xinc = 0
  self.lowest_xinc = 0

end

-------------------------------------------------------------------------------
-- read a line from the buffer or pattern
-- content can come from (a) scheduled lines (if any), or (b) buffered data
-- if neither exist, and pos is defined, we proceed to read from song
-- @param xinc (int), the buffer position
-- @param pos (SongPos), where to read from song
-- @return xLine, xline descriptor or nil
-- @return bool (true when content comes from buffer)

function xStreamBuffer:read_pos(xinc,pos)
  TRACE("xStreamBuffer:read_pos(xinc,pos)",xinc,pos)

  local xline = nil
  if self.scheduled[xinc] then
    --print(">>> read_pos - read from event buffer",xinc)
    xline = self.scheduled[xinc]
  else
    --print(">>> read_pos - read from pattern buffer",xinc)
    xline = self.line_descriptors[xinc]
  end
  local buffered = xline and true or false
  if not buffered then 
    if pos then
      --print(">>> read_pos - read from pattern",xinc,pos.sequence,pos.line)
      local seq_idx,line_idx = pos.sequence,pos.line
      xline = xLine.do_read(
        seq_idx,line_idx,self.xstream.include_hidden,self.xstream.track_index)
      self.line_descriptors[xinc] = table.rcopy(xline) 
    end
  end

  if not xline then
    --print(">>> read_pos - return empty xline")
    xline = table.rcopy(xLine.EMPTY_XLINE)
  end

  return xline,buffered

end

-------------------------------------------------------------------------------
-- update all content ahead of our position
-- method is called when xStreamPos is changing position 'abruptly'

function xStreamBuffer:update_read_buffer()
  TRACE("xStreamBuffer:update_read_buffer()")

  local pos = self.stream.readpos
  if pos then
    for k = 0,self.xstream.writeahead-1 do
      local xinc = pos.lines_travelled
      if self.scheduled[xinc] then
        self.line_descriptors[xinc] = self.scheduled[xinc]
      else
        self.line_descriptors[xinc] = xLine.do_read(
          pos.sequence,pos.line,self.xstream.include_hidden,self.xstream.track_index)
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
    self.scheduled[i] = nil
    --print("*** wipe_past - cleared buffers at ",i)
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
  self.scheduled = {}

end

-------------------------------------------------------------------------------
-- return a buffer position which correspond to the desired schedule
-- @param schedule (xStream.SCHEDULE), NONE/BEAT/BAR
-- @return int (buffer position)
-- @return int (delta, difference from current position)

function xStreamBuffer:get_scheduled_pos(schedule)
  TRACE("xStreamBuffer:get_scheduled_pos(schedule)",schedule)

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
    local xinc = writepos.lines_travelled + delta
    return xinc,delta
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
--[[
function xStreamBuffer:schedule_line(schedule,xline)
  TRACE("xStreamBuffer:schedule_line(schedule,xline)",schedule,xline)

  assert(type(schedule)=="number")
  assert(type(xline)=="table")

  local xinc,delta = self:get_scheduled_pos(schedule)
  --print("xinc,delta",xinc,delta)
  self:add_line(xinc,xline)

end
]]

-------------------------------------------------------------------------------
-- TODO Unregister a scheduled xline - 
--[[
function xStreamBuffer:unschedule_line(xinc)
  TRACE("xStreamBuffer:unschedule_line(xinc)",xinc)


  -- when within output range, wipe output buffer

    -- if output is imminent, clear 

  self.scheduled[xinc] = nil

end
]]

-------------------------------------------------------------------------------

function xStreamBuffer:schedule_line(xinc,xline)
  TRACE("xStreamBuffer:schedule_line(xinc,xline)",xinc,xline)

  local live_mode = rns.transport.playing
  local writepos = self.xstream.stream.writepos
  local delta = xinc - writepos.lines_travelled

  if (delta <= self.xstream.writeahead) then
    -- within output range - insert into output_buffer
    --print("insert into output_buffer - xinc,delta",xinc,delta)
    self.output_buffer[xinc] = xLine.apply_descriptor(xline)
    self.highest_xinc = math.max(xinc,self.highest_xinc)
    if (delta == 1) then
      --print("immediate output")
      self.xstream:do_output(writepos,2,live_mode)
    end
  end

  -- any range: insert into events table 
  --print("insert xline into self.scheduled at position",xinc)
  self.scheduled[xinc] = xline

end

-------------------------------------------------------------------------------
-- schedule a single column (merge with existing content)

function xStreamBuffer:schedule_note_column(xinc,xnotecol,col_idx)
  TRACE("xStreamBuffer:schedule_note_column()",xinc,xnotecol,col_idx)

  local xline = self:read_pos(xinc)
  xline.note_columns[col_idx] = xnotecol
  self:schedule_line(xinc,xline)

end

