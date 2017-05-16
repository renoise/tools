--[[===============================================================================================
-- xStreamBuffer
===============================================================================================]]--

--[[

A real-time streaming buffer for writing data into tracks and automation lanes

## About

Together with xStreamPos, this class enables realtime reading from, and writing to tracks. 
All you need to do do is to provide content through it's callback method. 

## Changelog

0.5 
- Made part of xLib 

0.x 
- Initial version

]]

--=================================================================================================

class 'xStreamBuffer'

--- choose a mute mode
-- NONE = do nothing except to output 'nothing'
--    note: when combined with 'clear', this makes it possible to 
--    record into a track, using the mute button as a 'output switch'
-- OFF = insert OFF across columns, then nothing
--    TODO when 'clear_undefined' is true, OFF is only written when
--    there is not an existing note at that position
xStreamBuffer.MUTE_MODES = {"None","Off"}
xStreamBuffer.MUTE_MODE = {
  NONE = 1,
  OFF = 2,
}

-- automation interpolation modes
xStreamBuffer.PLAYMODES = {"Points","Linear","Cubic"}
xStreamBuffer.PLAYMODE = {
  POINTS = 1,
  LINEAR = 2,
  CUBIC = 3,
}

---------------------------------------------------------------------------------------------------
-- [Constructor]

function xStreamBuffer:__init(xpos)
  TRACE("xStreamBuffer:__init(xpos)",xpos)

  --- xStreamPos, drives this class
  self.xpos = xpos

  -- In progress: working towards a more clean separation
  -- of this class and xStream itself. 

  -- TODO refactor more stuff from xStream 
  -- scheduling (move to xstream, part of callback)
  -- automation (??)

  --- provide a function that generates instances of xLine 
  -- TODO "not callback_contains_code" <- sets callback to nil
  self.callback = nil

  --- string, value depends on success/failure during last callback 
  -- "" = no problem
  -- "Some error occurred" = description of error 
  self.callback_status_observable = renoise.Document.ObservableString("")

  --- int, decide which track to target (0 = none)
  self.track_index = property(self.get_track_index,self.set_track_index)
  self.track_index_observable = renoise.Document.ObservableNumber(0)

  --- xStreamBuffer.MUTE_MODE, controls how muting is done
  self.mute_mode = property(self.get_mute_mode,self.set_mute_mode)
  self.mute_mode_observable = renoise.Document.ObservableNumber(xStreamBuffer.MUTE_MODE.OFF)

  --- boolean, whether to expand (sub-)columns when writing data
  self.expand_columns = property(self.get_expand_columns,self.set_expand_columns)
  self.expand_columns_observable = renoise.Document.ObservableBoolean(true)

  -- table<string> limit to "tokens" during output
  -- (derived from the code specified in the callback)
  self.output_tokens = {}

  --- boolean, whether to include hidden (not visible) columns
  self.include_hidden = property(self.get_include_hidden,self.set_include_hidden)
  self.include_hidden_observable = renoise.Document.ObservableBoolean(false)

  --- boolean, determine how to respond to 'undefined' content
  self.clear_undefined = property(self.get_clear_undefined,self.set_clear_undefined)
  self.clear_undefined_observable = renoise.Document.ObservableBoolean(true)

  --- xStreamBuffer.PLAYMODE, the preferred automation playmode
  self.automation_playmode = property(self.get_automation_playmode,self.set_automation_playmode)
  self.automation_playmode_observable = renoise.Document.ObservableNumber(xStreamBuffer.PLAYMODE.LINEAR)

  --== internal ==--

  -- > Note: all buffers are accessed with the 'xinc', counting from 0 
  --- table<xLine/descriptor>, buffer containing pattern data
  self.pattern_buffer = nil
  --- table<xLine/descriptor>, buffer containing the output
  self.output_buffer = nil
  --- table<xLine/descriptor>, buffer containing scheduled events
  self.scheduled = nil

  --- int, keep track of the highest/lowest line in our buffers
  self.highest_xinc = nil
  self.lowest_xinc = nil

  --- int, the mute buffer index 
  self.mute_xinc = nil

  --- int, 'undefined' line to insert after output got muted 
  self.empty_xline = xLine({
    note_columns = {},
    effect_columns = {},
  })

  --== initialize ==--

  self:clear()

end

---------------------------------------------------------------------------------------------------

function xStreamBuffer:get_automation_playmode()
  return self.automation_playmode_observable.value
end

function xStreamBuffer:set_automation_playmode(val)
  self.automation_playmode_observable.value = val
end

---------------------------------------------------------------------------------------------------

function xStreamBuffer:get_track_index()
  return self.track_index_observable.value
end

function xStreamBuffer:set_track_index(val)
  self.track_index_observable.value = val
end

---------------------------------------------------------------------------------------------------

function xStreamBuffer:get_include_hidden()
  return self.include_hidden_observable.value
end

function xStreamBuffer:set_include_hidden(val)
  self.include_hidden_observable.value = val
end

---------------------------------------------------------------------------------------------------

function xStreamBuffer:get_clear_undefined()
  return self.clear_undefined_observable.value
end

function xStreamBuffer:set_clear_undefined(val)
  self.clear_undefined_observable.value = val
end

---------------------------------------------------------------------------------------------------

function xStreamBuffer:get_expand_columns()
  return self.expand_columns_observable.value
end

function xStreamBuffer:set_expand_columns(val)
  self.expand_columns_observable.value = val
end

---------------------------------------------------------------------------------------------------

function xStreamBuffer:get_mute_mode()
  return self.mute_mode_observable.value
end

function xStreamBuffer:set_mute_mode(val)
  self.mute_mode_observable.value = val
end

---------------------------------------------------------------------------------------------------
-- update all content ahead of our position
-- method is called when xStreamPos is changing position 'abruptly'

function xStreamBuffer:update_read_buffer()
  TRACE("xStreamBuffer:update_read_buffer()")

  local pos = xSongPos.create(self.xpos.pos) -- readpos
  local xinc = self.xpos.xinc -- readpos
  
  if pos then
    local writeahead = xStreamPos.determine_writeahead()
    for k = 0,writeahead-1 do
      
      if self.scheduled[xinc] then
        self.pattern_buffer[xinc] = self.scheduled[xinc]
      else
        self.pattern_buffer[xinc] = xLine.do_read(
          pos.sequence,pos.line,self.include_hidden,self.track_index)
        --print("update_read_buffer - read from pattern - xinc,pos",xinc,pos)
      end
      local travelled = xSongPos.increase_by_lines(1,pos)
      xinc = xinc + travelled
    end
    self:wipe_futures()
  end

end

---------------------------------------------------------------------------------------------------
-- wipe all data behind our current position
-- (see also xStreamArgs)

function xStreamBuffer:_wipe_past()
  TRACE("xStreamBuffer:_wipe_past()")

  local from_idx = self.xpos.xinc - 1
  for i = from_idx,self.lowest_xinc,-1 do
    self.output_buffer[i] = nil
    self.pattern_buffer[i] = nil
    self.scheduled[i] = nil
    print("*** _wipe_past - cleared buffers at ",i)
  end

  self.lowest_xinc = from_idx
  --print("lowest_xinc ",from_idx)

end

---------------------------------------------------------------------------------------------------
-- forget all output ahead of our current write-position
-- method is automatically called when callback arguments have changed,
-- and will cause fresh line(s) to be created in the next cycle
-- (see also xStreamArgs)

function xStreamBuffer:wipe_futures()
  TRACE("xStreamBuffer:wipe_futures()")

  local from_idx = self.xpos.xinc
  if rns.transport.playing then
    -- when live streaming, exclude current line
    from_idx = from_idx+1
  end

  print("*** xStreamBuffer:wipe_futures - wiping from",from_idx,"to",self.highest_xinc)
  for i = from_idx,self.highest_xinc do
    self.output_buffer[i] = nil
  end

  self.highest_xinc = self.xpos.xinc
  --print("*** xStreamBuffer:wipe_futures - self.highest_xinc",self.highest_xinc)

  -- pull the read position back to this point
  --[[
  print(">>> self.xpos.pos",self.xpos.pos)
  self.xpos.pos = xSongPos.create(self.xpos.pos)
  print(">>> self.xpos.pos",self.xpos.pos)
  if rns.transport.playing then
    self.xpos:_increase_read_position(1)
  end
  ]]

end

---------------------------------------------------------------------------------------------------
--- clear when preparing to stream

function xStreamBuffer:clear()
  TRACE("xStreamBuffer:clear()")

  self.highest_xinc = -1
  self.lowest_xinc = 0

  if self.mute_xinc then
    self.mute_xinc = -2
  end

  self.pattern_buffer = {}
  self.output_buffer = {}
  self.scheduled = {}
  --self.output_tokens = {}

  self.xpos:reset()

end

---------------------------------------------------------------------------------------------------
-- create a SongPos based on buffer read-position
-- @param xinc (int)
-- @return xSongPos

function xStreamBuffer:_get_songpos(xinc)
  TRACE("xStreamBuffer:_get_songpos(xinc)",xinc)

  local pos = xSongPos.create(self.xpos.pos)
  local delta = xinc - self.xpos.xinc
  xSongPos.increase_by_lines(delta,pos)
  return pos

end

---------------------------------------------------------------------------------------------------
-- @param xline (table), xline descriptor
-- @param xinc (int), position

function xStreamBuffer:schedule_line(xline,xinc)
  TRACE("xStreamBuffer:schedule_line(xline,xinc)",xline,xinc)

  if not xinc then xinc = self:_get_xinc() end
  local pos = self.xpos.pos
  local xinc = self.xpos.xinc
  local delta = xinc - xinc
  local live_mode = rns.transport.playing
  local writeahead = xStreamPos.determine_writeahead()

  -- insert into scheduled buffer
  self.scheduled[xinc] = xline

  if (delta <= writeahead) then
    if (delta == 1) then
      print("*** immediate output")
      self:wipe_futures()
      self:write_output(pos,xinc,2,live_mode)
    else
      -- within output range - insert into output_buffer
      self.output_buffer[xinc] = xLine.apply_descriptor(xline)
      self.highest_xinc = math.max(xinc,self.highest_xinc)
    end
  end

  --print("self.scheduled",rprint(self.scheduled))

end

---------------------------------------------------------------------------------------------------
-- schedule a single column (merge into existing xline)

function xStreamBuffer:schedule_note_column(xnotecol,col_idx,xinc)
  TRACE("xStreamBuffer:schedule_note_column(xnotecol,col_idx,xinc)",xnotecol,col_idx,xinc)

  assert(type(col_idx)=="number")

  if not xinc then xinc = self:_get_xinc() end
  local xline = self:get_input(xinc,self:_get_songpos(xinc)) 
  xline.note_columns[col_idx] = xnotecol
  self:schedule_line(xline,xinc)

end

---------------------------------------------------------------------------------------------------
-- schedule a single column (merge into existing xline)

function xStreamBuffer:schedule_effect_column(xeffectcol,col_idx,xinc)
  TRACE("xStreamBuffer:schedule_effect_column(xeffectcol,col_idx,xinc)",xeffectcol,col_idx,xinc)

  assert(type(col_idx)=="number")

  if not xinc then xinc = self:_get_xinc() end
  local xline = self:get_input(xinc,self:_get_songpos(xinc))
  --print("schedule_effect_column - xline",rprint(xline))
  xline.effect_columns[col_idx] = xeffectcol
  self:schedule_line(xline,xinc)

end

---------------------------------------------------------------------------------------------------
-- get the buffer index relative to our position (used for scheduling)
--  note that counting starts from current line when parked 
-- @param offset (int), number of lines 
-- @return int

function xStreamBuffer:_get_xinc()
  TRACE("xStreamBuffer:_get_xinc()")

  local live_mode = rns.transport.playing and 1 or 0
  return self.xpos.xinc + live_mode

end

---------------------------------------------------------------------------------------------------
-- trigger mute event (schedule note-offs if configured to)

function xStreamBuffer:mute()
  TRACE("xStreamBuffer:mute()")

  local function produce_note_off()
    local note_cols = {}
    local track = rns.tracks[self.track_index]
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

  if (self.mute_mode == xStreamBuffer.MUTE_MODE.OFF) then
    xline.note_columns = produce_note_off()
  end

  -- insert not one, but *two* note-offs - since it is possible
  -- (although rarely) for the first note-off not to be picked up...
  self.mute_xinc = self:_get_xinc() 
  self:schedule_line(xline,self.mute_xinc+1)
  self:schedule_line(xline,self.mute_xinc+2)

end

-------------------------------------------------------------------------------

function xStreamBuffer:unmute()
  TRACE("xStreamBuffer:unmute()")

  self.mute_xinc = nil

end

---------------------------------------------------------------------------------------------------
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

---------------------------------------------------------------------------------------------------
-- Create content: process #num_lines using our callback method, 
-- and update output_buffer with result
-- @param num_lines, int 

function xStreamBuffer:_create_content(num_lines)
  print("xStreamBuffer:_create_content(num_lines)",num_lines)

  local pos = xSongPos.create(self.xpos.pos)
  local xinc = self.xpos.xinc

  -- special case: if the pattern was deleted from the song, the pos
  -- might be referring to a non-existing pattern - in such a case,
  -- we re-initialize to the current position
  -- TODO "proper" align of pos via patt-seq notifications in xStreamPos 
  if not rns.sequencer.pattern_sequence[pos.sequence] then
    LOG("*** xStreamBuffer:create_content - fixing missing pattern sequence")
    pos = rns.transport.playback_pos
  end

  for i = 0, num_lines-1 do
    
    -- handle scheduling ----------------------------------
    --[[
    local callback = nil
    local contains_code = nil
    local change_to_scheduled = false
    if self.xstream._scheduled_xinc and self.xstream._scheduled_model then
      local compare_to = 1 + xinc - num_lines + i
      if (self.xstream._scheduled_xinc <= compare_to) then
        change_to_scheduled = true
      end
    end
    if change_to_scheduled then
      callback = self.callback
      contains_code = self.xstream._scheduled_model.callback_contains_code
      -- TODO apply preset arguments 
    else
      callback = self.callback
      contains_code = self.xstream.process.models.selected_model.callback_contains_code
    end
    ]]
    local callback = self.callback
    --contains_code = self.xstream.process.models.selected_model.callback_contains_code
    --if not contains_code then
      --LOG("*** Skip, callback does not provide any functionality")
      -- TODO stacked model - forward 
    --else

      -- retrieve content (input or pattern) --
      local xline = self:get_input(xinc,pos)

      -- decide if we need to evaluate the callback 
      -- (we only want to do this _once_ per line)
      local buffer_content = xline
      local success,err
      print(">>> should evaluate - xinc,self.highest_xinc ",xinc,self.highest_xinc)
      if (xinc > self.highest_xinc) then
        success,err = pcall(function()
          buffer_content = callback(xinc,xLine(xline),xSongPos.create(pos))
        end)
        print("processed callback - xinc,pos,success,err",xinc,pos,success,err)
      end
      if not success and err then
        LOG("*** Error: please review the callback function - "..err)
        -- TODO display runtime errors separately (runtime_status)
        self.callback_status_observable.value = err
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
        print("*** xStreamBuffer callback evaluated - highest_xinc,buffer",xinc,self.output_buffer[xinc])
        self.highest_xinc = math.max(xinc,self.highest_xinc)
      end

    --end

    -- update counters -------------------------------

    local travelled = xSongPos.increase_by_lines(1,pos)
    xinc = xinc + travelled

  end

end

---------------------------------------------------------------------------------------------------
-- Write #num_lines into the pattern-track and/or automation lane
-- @param pos (SongPos)
-- @param xinc (int), buffer position 
-- @param [num_lines] (int), use writeahead if not defined
-- @param live_mode (bool), skip line at playpos when true

function xStreamBuffer:write_output(pos,xinc,num_lines,live_mode)
  print("xStreamBuffer:write_output(pos,travelled,num_lines,live_mode)",pos,xinc,num_lines,live_mode)

  if not self.callback then
    LOG("*** Can't write output - no callback defined")
    return
  end

  if not num_lines then
    num_lines = rns.transport.playing and xStreamPos.determine_writeahead() or 1
  end

  -- purge old content from buffers
  self:_wipe_past()

  -- generate new content as needed
  local has_content,missing_from = self:has_content(xinc,num_lines-1)
  if not has_content then 
    self:_create_content(num_lines-(missing_from-xinc))
  end

  local tmp_pos -- temp line-by-line position

  -- TODO decide this elsewhere (optimize)
  local patt_num_lines = xPatternSequencer.get_number_of_lines(pos.sequence)

  local phrase = nil
  local ptrack_auto = nil
  local last_auto_seq_idx = nil

  for i = 0,num_lines-1 do
    
    tmp_pos = {sequence=pos.sequence,line=pos.line+i}
    --print("*** output i,tmp_pos",i,tmp_pos)

    if (tmp_pos.line > patt_num_lines) then
      -- exceeded pattern
      if (xSongPos.DEFAULT_LOOP_MODE ~= xSongPos.LOOP_BOUNDARY.NONE) then
        -- normalize the songpos and redial 
        print("*** exceeded pattern PRE",tmp_pos,num_lines-i)
        local tmp_travelled = xinc + i - 1
        xSongPos.normalize(tmp_pos)
        print("*** exceeded pattern POST",tmp_pos,num_lines-i)
        self:write_output(tmp_pos,tmp_travelled,num_lines-i)
      end
      return
    else
      -- check if we exceeded block-loop
      local cached_line = tmp_pos.line
      if rns.transport.loop_block_enabled and 
        (xSongPos.DEFAULT_BLOCK_MODE ~= xSongPos.BLOCK_BOUNDARY.NONE) 
      then
        tmp_pos.line = xSongPos.enforce_block_boundary("increase",pos,i)
        if (cached_line ~= tmp_pos.line) then
          local tmp_travelled = xinc + i
          print("*** exceeded block loop",tmp_pos,num_lines-i)
          self:write_output(tmp_pos,tmp_travelled,num_lines-i)
          return
        end
      end

      if live_mode and (tmp_pos.line+1 == rns.transport.playback_pos.line) then
        print(">>> skip current line when live streaming")
      else
        
        local xline = self:get_output(xinc+i)

        -- check if we can/need to resolve automation
        -- TODO re-implement 
        --[[
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
              ptrack_auto.playmode = self.automation_playmode
            end
          end
        end
        ]]

        if type(xline)=="xLine" then
          local success,err = pcall(function()
            xline:do_write(
              tmp_pos.sequence,
              tmp_pos.line,
              self.track_index,
              phrase,
              ptrack_auto,
              patt_num_lines,
              self.output_tokens,
              self.include_hidden,
              self.expand_columns,
              self.clear_undefined)
          end)

          if not success then
            LOG("*** WARNING: an error occurred while writing pattern-line - "..err)
          end

        else
          LOG("*** Expected an instance of xline for output")
        end
      end

    end    
  end

end


---------------------------------------------------------------------------------------------------
-- Return the finalized output buffer (or note-off/empty line when muted)

function xStreamBuffer:get_output(xinc)
  print("xStreamBuffer:get_output(xinc)",xinc)

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

---------------------------------------------------------------------------------------------------
-- Read a line from the input buffer or pattern. Content can come from either a scheduled line 
-- or a pattern buffer. If neither exist, and pos is defined, we proceed to read from song. 
-- @param xinc (int), the buffer position
-- @param [pos] (SongPos), where to read from song
-- @return xLine, xline descriptor (never nil)

function xStreamBuffer:get_input(xinc,pos)
  print("xStreamBuffer:get_input(xinc,pos)",xinc,pos)

  assert(type(xinc)=="number","Expected 'xinc' to be a number")

  local xline = nil
  if self.scheduled[xinc] then
    --print("*** read from scheduled buffer",xinc,rprint(self.scheduled[xinc]))
    xline = self.scheduled[xinc]
    -- descriptor might not be fully defined
    if not xline.note_columns then
      xline.note_columns = {}
    end
    if not xline.effect_columns then
      xline.effect_columns = {}
    end
  elseif self.pattern_buffer[xinc] then
    --print("*** read from pattern buffer",xinc,self.pattern_buffer[xinc])
    xline = self.pattern_buffer[xinc]
  end
  if pos then
    -- read from pattern & add to buffer 
    print(">>> do_read",pos)
    xline = xLine.do_read(pos.sequence,pos.line,self.include_hidden,self.track_index)    
    self.pattern_buffer[xinc] = table.rcopy(xline) 
  end

  if not xline then
    --print("*** xStreamBuffer:get_input - return empty xline")
    xline = table.rcopy(xLine.EMPTY_XLINE)
  end

  return xline

end

