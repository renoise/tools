--[[============================================================================
-- xStreamBuffer
============================================================================]]--

--[[

Input/output buffer for xStream

#

Content is read from the pattern as new content is requested from the callback method - this ensures that the callback always has a fully populated line to work on. Unlike the output buffer, the read buffer is not cleared when arguments change - it should be read only *once*. 

Note: buffer is zero-based. 

## About scheduled events

Scheduled events do not actually affect the buffer until the stream get_output() method is called - this means we can schedule content, but also pull it back, right until the last moment.


]]

--==============================================================================

class 'xStreamBuffer'

function xStreamBuffer:__init(xstream)
  TRACE("xStreamBuffer:__init(xstream)",xstream)

  self.xstream = xstream

  --- table<xLine or descriptor> content read from pattern 
  self.pattern_buffer = {}

  --- table<xLine> buffer containing the final output 
  self.output_buffer = {}

  --- table<xLine or descriptor>, scheduled events
  self.scheduled = {}

  --- int, keep track of the highest/lowest line in our buffers
  self.highest_xinc = 0
  self.lowest_xinc = 0

  --- int, the mute buffer index 
  self.mute_xinc = nil

  --- int, 'undefined' line to insert after output got muted 
  self.empty_xline = xLine({
    note_columns = {},
    effect_columns = {},
  })

end

-------------------------------------------------------------------------------
-- update all content ahead of our position
-- method is called when xStreamPos is changing position 'abruptly'

function xStreamBuffer:update_read_buffer()
  TRACE("xStreamBuffer:update_read_buffer()")

  local pos = self.xstream.stream.readpos
  if pos then
    for k = 0,self.xstream.stream.writeahead-1 do
      local xinc = pos.lines_travelled
      if self.scheduled[xinc] then
        self.pattern_buffer[xinc] = self.scheduled[xinc]
      else
        self.pattern_buffer[xinc] = xLine.do_read(
          pos.sequence,pos.line,self.xstream.include_hidden,self.xstream.track_index)
        --print("update_read_buffer - read from pattern - xinc,pos",xinc,pos)
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
    self.pattern_buffer[i] = nil
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

  local from_idx = self.xstream.stream.writepos.lines_travelled
  if rns.transport.playing then
    -- when live streaming, exclude current line
    from_idx = from_idx+1
  end

  --print("*** xStreamBuffer:wipe_futures - wiped buffer from",from_idx,"to",self.highest_xinc)
  for i = from_idx,self.highest_xinc do
    self.output_buffer[i] = nil
  end

  self.highest_xinc = self.xstream.stream.writepos.lines_travelled
  --print("*** xStreamBuffer:wipe_futures - self.highest_xinc",self.highest_xinc)

  -- pull the read position back to this point
  self.xstream.stream.readpos = xSongPos(self.xstream.stream.writepos)
  if rns.transport.playing then
    self.xstream.stream.readpos:increase_by_lines(1)
  end

end

-------------------------------------------------------------------------------
--- clear when preparing to stream

function xStreamBuffer:clear()
  TRACE("xStreamBuffer:clear()")

  self.highest_xinc = 0
  self.lowest_xinc = 0

  if self.mute_xinc then
    self.mute_xinc = -2
  end

  self.pattern_buffer = {}
  self.output_buffer = {}
  self.scheduled = {}

end

-------------------------------------------------------------------------------
-- get a xSongPos based on buffer read-position
-- (only be reliable as long as outer conditions does not change - loops,etc.)
-- @param xinc (int)
-- @return xSongPos

function xStreamBuffer:get_pos(xinc)
  TRACE("xStreamBuffer:get_pos(xinc)",xinc)

  local pos = xSongPos(self.xstream.stream.writepos)
  local delta = xinc - pos.lines_travelled
  pos:increase_by_lines(delta)
  --print("xStreamBuffer:get_pos - POST",pos)
  return pos

end

-------------------------------------------------------------------------------
-- return a buffer position which correspond to the desired schedule
-- @param schedule (int or xStream.SCHEDULE), schedule when negative 
-- @return int (xSongPos)

function xStreamBuffer:get_scheduled_pos(schedule)
  TRACE("xStreamBuffer:get_scheduled_pos(schedule)",schedule)

  local live_mode = rns.transport.playing
  local writepos = self.xstream.stream.writepos

  local schedules = {
    [xStream.SCHEDULE.LINE] = function()
      local pos = xSongPos(writepos)
      if live_mode then
        pos:increase_by_lines(1)
      end
      return pos
    end,
    [xStream.SCHEDULE.BEAT] = function()
      local pos = xSongPos(writepos)
      pos:decrease_by_lines(1) -- too cautious when on next line?
      pos:next_beat()
      return pos
    end,
    [xStream.SCHEDULE.BAR] = function()
      local pos = xSongPos(writepos)
      pos:next_bar()
      return pos
    end,
  }

  if schedules[schedule] then
    local pos = schedules[schedule]()
    local delta = pos.lines_travelled - writepos.lines_travelled
    pos.lines_travelled = writepos.lines_travelled + delta
    return pos
  else
    error("Unsupported schedule type, please use NONE/BEAT/BAR")
  end

end

-------------------------------------------------------------------------------
-- TODO Unregister a scheduled xline - 
--[[
function xStreamBuffer:unschedule_line(xinc)


  -- when within output range, wipe output buffer

    -- if output is imminent, clear 

  self.scheduled[xinc] = nil

end
]]

-------------------------------------------------------------------------------
-- @param xline (table), xline descriptor
-- @param xinc (int), position

function xStreamBuffer:schedule_line(xline,xinc)
  TRACE("xStreamBuffer:schedule_line(xline,xinc)",xline,xinc)

  if not xinc then xinc = self:get_xinc() end
  local writepos = self.xstream.stream.writepos
  local delta = xinc - writepos.lines_travelled
  local live_mode = rns.transport.playing

  -- any range: insert into events table 
  self.scheduled[xinc] = xline

  if (delta <= self.xstream.stream.writeahead) then
    if (delta == 1) then
      -- immediate output
      self:wipe_futures()
      self:write_output(writepos,2,live_mode)
    else
      -- within output range - insert into output_buffer
      self.output_buffer[xinc] = xLine.apply_descriptor(xline)
      self.highest_xinc = math.max(xinc,self.highest_xinc)
    end
  end

  --print("self.scheduled",rprint(self.scheduled))

end

-------------------------------------------------------------------------------
-- schedule a single column (merge into existing xline)

function xStreamBuffer:schedule_note_column(xnotecol,col_idx,xinc)
  TRACE("xStreamBuffer:schedule_note_column(xnotecol,col_idx,xinc)",xnotecol,col_idx,xinc)

  assert(type(col_idx)=="number")

  if not xinc then xinc = self:get_xinc() end
  local pos = self:get_pos(xinc)
  local xline = self:get_input(xinc,pos) 
  xline.note_columns[col_idx] = xnotecol
  self:schedule_line(xline,xinc)

end

-------------------------------------------------------------------------------
-- schedule a single column (merge into existing xline)

function xStreamBuffer:schedule_effect_column(xeffectcol,col_idx,xinc)
  TRACE("xStreamBuffer:schedule_effect_column(xeffectcol,col_idx,xinc)",xeffectcol,col_idx,xinc)

  assert(type(col_idx)=="number")

  if not xinc then xinc = self:get_xinc() end
  local pos = self:get_pos(xinc)
  local xline = self:get_input(xinc,pos)
  --print("schedule_effect_column - xline",rprint(xline))
  xline.effect_columns[col_idx] = xeffectcol
  self:schedule_line(xline,xinc)

end

-------------------------------------------------------------------------------
-- get the buffer index relative to our position (used for scheduling)
--  note that counting starts from current line when parked 
-- @param offset (int), number of lines 
-- @return int

function xStreamBuffer:get_xinc()
  TRACE("xStreamBuffer:get_xinc()")

  local writepos = self.xstream.stream.writepos
  local live_mode = rns.transport.playing
  return writepos.lines_travelled + (live_mode and 1 or 0)

end

-------------------------------------------------------------------------------
-- trigger mute event (schedule note-offs if configured to)

function xStreamBuffer:mute()
  TRACE("xStreamBuffer:mute()")

  --self:wipe_futures()

  local function produce_note_off()
    local note_cols = {}
    local track = rns.tracks[self.xstream.track_index]
    local note_col_count = track.visible_note_columns
    for _ = 1,note_col_count do
      table.insert(note_cols,{
        note_value = xNoteColumn.NOTE_OFF_VALUE,
        instrument_value = xLinePattern.EMPTY_VALUE,
        volume_value = xLinePattern.EMPTY_VALUE,
        panning_value = xLinePattern.EMPTY_VALUE,
        delay_value = 0,
      })
    end
    return note_cols
  end

  local xline = {}

  if (self.xstream.mute_mode == xStream.MUTE_MODE.OFF) then
    xline.note_columns = produce_note_off()
  end

  -- insert not one, but *two* note-offs - since it is possible
  -- (although rarely) for the first note-off not to be picked up...
  self.mute_xinc = self:get_xinc() 
  self:schedule_line(xline,self.mute_xinc+1)
  self:schedule_line(xline,self.mute_xinc+2)

end

-------------------------------------------------------------------------------

function xStreamBuffer:unmute()
  TRACE("xStreamBuffer:unmute()")

  self.mute_xinc = nil

end

-------------------------------------------------------------------------------
-- check if buffer has content for the specified range
-- @param pos (int), index in buffer 
-- @param num_lines (int)
-- @return bool, true when all content is present
-- @return int, (when not present) the first missing index 

function xStreamBuffer:has_content(pos,num_lines)
  TRACE("xStreamBuffer:has_content(pos,num_lines)",pos,num_lines)

  for i = pos,pos+num_lines do
    if not (self.output_buffer[i]) then
      --print("*** has_content - missing from",i)
      return false,i
    end
  end

  return true

end

-------------------------------------------------------------------------------
-- process lines using our callback method 
-- @param num_lines (int) how many lines to create 
-- @return table<xLine>

function xStreamBuffer:create_content(num_lines)
  TRACE("xStreamBuffer:create_content(num_lines)",num_lines)

  if not self.xstream.selected_model.sandbox.callback then
    error("No callback method has been specified")
  end

  local readpos = self.xstream.stream.readpos

  -- special case: if the pattern was deleted from the song, the readpos
  -- might be referring to a non-existing pattern - in such a case,
  -- we re-initialize to the current position
  -- TODO "proper" align of readpos via patt-seq notifications in xStreamPos 
  if not rns.sequencer.pattern_sequence[readpos.sequence] then
    LOG("*** xStreamBuffer:create_content - fixing missing pattern sequence")
    readpos = xSongPos(rns.transport.playback_pos)
  end
  

  for i = 0, num_lines-1 do

    local xinc = readpos.lines_travelled
    
    -- handle scheduling ----------------------------------

    local callback = nil
    local contains_code = nil
    local change_to_scheduled = false
    if self.xstream._scheduled_pos and self.xstream._scheduled_model then
      local compare_to = 1 + readpos.lines_travelled - num_lines + i
      if (self.xstream._scheduled_pos.lines_travelled <= compare_to) then
        change_to_scheduled = true
        --print("*** xStreamBuffer:create_content, scheduled - readpos,scheduled_pos,compare_to",readpos,self._scheduled_pos.lines_travelled,compare_to)
      end
    end
    if change_to_scheduled then
      callback = self.xstream._scheduled_model.sandbox.callback
      contains_code = self.xstream._scheduled_model.callback_contains_code
      -- TODO apply preset arguments 
    else
      callback = self.xstream.selected_model.sandbox.callback
      contains_code = self.xstream.selected_model.callback_contains_code
    end

    if not contains_code then
      --LOG("*** Skip, callback does not provide any functionality")
      -- TODO stacked model - forward 
    else

      -- retrieve existing content --------------------------

      local xline = self:get_input(xinc,readpos)

      -- process the callback -------------------------------

      local buffer_content = nil
      local success,err = pcall(function()
        buffer_content = callback(xinc,xLine(xline),xSongPos(readpos))
      end)
      --print("processed callback - xinc,readpos",xinc,readpos)
      if not success and err then
        LOG("*** Error: please review the callback function - "..err)
        -- TODO display runtime errors separately (runtime_status)
        self.xstream.callback_status_observable.value = err
      elseif success and buffer_content then
        -- we might have redefined the xline (or parts of it) in our  
        -- callback method - convert everything into class instances...
        local success,err = pcall(function()
          self.output_buffer[xinc] = xLine.apply_descriptor(buffer_content)
        end)
        if not success and err then
          LOG("*** Error: could not convert xline - "..err)
          self.output_buffer[xinc] = table.rcopy(xLine.EMPTY_XLINE)
        end
        --print("*** xStreamBuffer:create_content (callback evaluated) - highest_xinc,buffer",xinc,self.output_buffer[xinc])
        self.highest_xinc = math.max(xinc,self.highest_xinc)
      end

    end

    -- update counters -------------------------------

    readpos:increase_by_lines(1)

  end

end

-------------------------------------------------------------------------------
-- will produce output for the next number of lines
--  * generate content as needed or pull it from the buffer
-- @param xpos (xSongPos), always writepos when streaming 
-- @param num_lines (int), use writeahead if not defined
-- @param live_mode (bool), skip line at playpos when true

function xStreamBuffer:write_output(xpos,num_lines,live_mode)
  TRACE("xStreamBuffer:write_output(xpos,num_lines,live_mode)",xpos,num_lines,live_mode)

  if not self.xstream.selected_model then
    return
  end

  if not num_lines then
    num_lines = rns.transport.playing and self.xstream.stream.writeahead or 1
  end

  -- purge old content from buffers
  self:wipe_past()

  -- generate new content as needed
  local has_content,missing_from = 
    self:has_content(xpos.lines_travelled,num_lines-1)
  if not has_content then
    self:create_content(num_lines-(missing_from-xpos.lines_travelled))
  end

  local tmp_pos -- temp line-by-line position

  -- TODO decide this elsewhere (optimize)
  local patt_num_lines = xSongPos.get_pattern_num_lines(xpos.sequence)

  local phrase = nil
  local ptrack_auto = nil
  local last_auto_seq_idx = nil

  for i = 0,num_lines-1 do
    
    tmp_pos = xSongPos({sequence=xpos.sequence,line=xpos.line+i})
    tmp_pos.bounds_mode = self.xstream.bounds_mode
    --print("*** write_output i,tmp_pos",i,tmp_pos)

    if (tmp_pos.line > patt_num_lines) then
      -- exceeded pattern
      if (self.xstream.loop_mode ~= xSongPos.LOOP_BOUNDARY.NONE) then
        -- normalize the songpos and redial 
        --print("*** exceeded pattern PRE",tmp_pos,num_lines-i)
        tmp_pos.lines_travelled = xpos.lines_travelled + i - 1
        tmp_pos:normalize()
        --print("*** exceeded pattern POST",tmp_pos,num_lines-i)
        self:write_output(tmp_pos,num_lines-i)
      end
      return
    else
      -- check if we exceeded block-loop
      local cached_line = tmp_pos.line
      if rns.transport.loop_block_enabled and 
        (self.xstream.block_mode ~= xSongPos.BLOCK_BOUNDARY.NONE) 
      then
        tmp_pos.line = tmp_pos:enforce_block_boundary("increase",xpos.line,i)
        if (cached_line ~= tmp_pos.line) then
          tmp_pos.lines_travelled = xpos.lines_travelled + i
          --print("*** exceeded block loop",tmp_pos,num_lines-i)
          self:write_output(tmp_pos,num_lines-i)
          return
        end
      end

      if live_mode and (tmp_pos.line+1 == rns.transport.playback_pos.line) then
        -- skip current line when live streaming
      else
        --print("*** xpos.lines_travelled",xpos.lines_travelled)
        
        local xinc = xpos.lines_travelled+i
        local xline = nil

        xline = self:get_output(xinc)
        --print("*** normal output - xinc,tmp_pos",xinc,tmp_pos,xline)

        -- check if we can/need to resolve automation
        if type(xline)=="xLine" then
          if self.xstream.device_param and xline.automation then
            --print("*** xline.automation",xline.automation)
            if (tmp_pos.sequence ~= last_auto_seq_idx) then
              last_auto_seq_idx = tmp_pos.sequence
              --print("*** last_auto_seq_idx",last_auto_seq_idx)
              ptrack_auto = self.xstream:resolve_automation(tmp_pos.sequence)
            end
          end
          --print("*** ptrack_auto",ptrack_auto)
          if ptrack_auto then
            if (self.xstream.device_param.value_quantum == 0) then
              ptrack_auto.playmode = self.xstream.automation_playmode
            end
          end
        end

        --print("*** do_write - xinc,line,xline",xinc,tmp_pos.line,xline)
        if type(xline)=="xLine" then
          local success,err = pcall(function()
            xline:do_write(
              tmp_pos.sequence,
              tmp_pos.line,
              self.xstream.track_index,
              phrase,
              ptrack_auto,
              patt_num_lines,
              self.xstream.selected_model.output_tokens,
              self.xstream.include_hidden,
              self.xstream.expand_columns,
              self.xstream.clear_undefined)
          end)

          if not success then
            LOG("*** WARNING: an error occurred while writing pattern-line - "..err)
          end

        else
          --LOG("*** xStream: no output defined",tmp_pos,xpos.lines_travelled)
        end
      end

    end    
  end

end


-------------------------------------------------------------------------------
-- Return the finalized output buffer (or note-off/empty line when muted)

function xStreamBuffer:get_output(xinc)
  TRACE("xStreamBuffer:get_output(xinc)",xinc)

  if self.mute_xinc and (xinc > self.mute_xinc+2) then
    --print("following the note-offs comes silence...")
    return self.empty_xline
  elseif self.scheduled[xinc] then
    return xLine.apply_descriptor(self.scheduled[xinc])
  else
    --print("return from output buffer",xinc,self.output_buffer[xinc])
    return self.output_buffer[xinc]   
  end

end

-------------------------------------------------------------------------------
-- [Internal method] read a line from the input (buffer or pattern)
-- content can come from (a) scheduled lines (if any), or (b) pattern buffer
-- if neither exist, and pos is defined, we proceed to read from song
-- @param xinc (int), the buffer position
-- @param pos (SongPos), where to read from song
-- @return xLine, xline descriptor (never nil)

function xStreamBuffer:get_input(xinc,pos)
  TRACE("xStreamBuffer:get_input(xinc,pos)",xinc,pos)

  local xline = nil
  if xinc then
    if self.scheduled[xinc] then
      --print("*** xStreamBuffer:get_input - read from event buffer",xinc,rprint(self.scheduled[xinc]))
      xline = self.scheduled[xinc]
      -- descriptor might not be fully defined
      if not xline.note_columns then
        xline.note_columns = {}
      end
      if not xline.effect_columns then
        xline.effect_columns = {}
      end
    elseif self.pattern_buffer[xinc] then
      --print("*** xStreamBuffer:get_input - read from pattern buffer",xinc,self.pattern_buffer[xinc])
      xline = self.pattern_buffer[xinc]
    end
  end
  if pos then
    -- read from pattern & add to buffer 
    xline = xLine.do_read(pos.sequence,pos.line,self.xstream.include_hidden,self.xstream.track_index)    
    self.pattern_buffer[pos.lines_travelled] = table.rcopy(xline) 
    --print("*** xStreamBuffer:get_input - read from pattern",pos.lines_travelled,pos,xline)
  end

  if not xline then
    --print("*** xStreamBuffer:get_input - return empty xline")
    xline = table.rcopy(xLine.EMPTY_XLINE)
  end

  return xline

end

