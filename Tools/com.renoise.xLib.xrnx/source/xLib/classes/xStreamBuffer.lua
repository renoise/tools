--[[===============================================================================================
-- xStreamBuffer
===============================================================================================]]--

--[[

A real-time streaming buffer for writing data into tracks and automation lanes

## About

Together with xStreamPos, this class enables realtime reading from, and writing to tracks. 
Content is provided in the form of xLine instances, which is then transformed through the callback method. 

The class maintains separate buffers for input and output, as well as "scheduled" content. 

## Providing content 

There are two ways to provide content: 
1. Define 'input_callback' to let some other source provide you with content 
2. Define 'read_track_index' and let the class from that track

If neither are defined, an empty xLine instance is provided. 

## Scheduling 

Use scheduling to place content ahead of the stream position. 

## TODO 

Merge scheduled content into the output - currently, it's merged at the time of scheduling but it would be better if the merging happened just in time for output. 

For a example, scheduling an LFO reset at the beginning of a pattern, you would want to define a 'sparse' xline, containing just the effect column with a reset command. Otherwise, other parts of the line would be replaced too. 


## Changelog

0.51
- No dependancies, simplified implementation

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

  assert(type(xpos)=="xStreamPos")

  --- xStreamPos, drives this class
  self.xpos = xpos

  --- provide a function that generates instances of xLine 
  self.callback = nil

  --- function, when defined this becomes the source of content 
  -- {
  --  @param xinc 
  --  @return xline 
  -- }
  self.input_callback = nil

  --- string, value depends on success/failure during last callback 
  -- "" = no problem
  -- "Some error occurred" = description of error 
  self.callback_status_observable = renoise.Document.ObservableString("")

  --- int, decide which track we are reading from (0 = none)
  self.read_track_index = property(self.get_read_track_index,self.set_read_track_index)
  self.read_track_index_observable = renoise.Document.ObservableNumber(1)

  --- int, decide which track we are writing to (0 = none)
  self.write_track_index = property(self.get_write_track_index,self.set_write_track_index)
  self.write_track_index_observable = renoise.Document.ObservableNumber(1)

  --- xStreamBuffer.MUTE_MODE, controls how muting is done
  self.mute_mode = property(self.get_mute_mode,self.set_mute_mode)
  self.mute_mode_observable = renoise.Document.ObservableNumber(xStreamBuffer.MUTE_MODE.OFF)

  --- boolean, when false no callbacks are evaluated and no content written 
  self.active = property(self.get_active,self.set_active)
  self.active_observable = renoise.Document.ObservableBoolean(false)

  --- boolean, whether to expand (sub-)columns when writing data
  self.expand_columns = property(self.get_expand_columns,self.set_expand_columns)
  self.expand_columns_observable = renoise.Document.ObservableBoolean(true)

  --- boolean, whether to include hidden (not visible) columns
  self.include_hidden = property(self.get_include_hidden,self.set_include_hidden)
  self.include_hidden_observable = renoise.Document.ObservableBoolean(false)

  --- boolean, determine how to respond to 'undefined' content
  self.clear_undefined = property(self.get_clear_undefined,self.set_clear_undefined)
  self.clear_undefined_observable = renoise.Document.ObservableBoolean(true)

  --- xStreamBuffer.PLAYMODE, the preferred automation playmode
  self.automation_playmode = property(self.get_automation_playmode,self.set_automation_playmode)
  self.automation_playmode_observable = renoise.Document.ObservableNumber(xStreamBuffer.PLAYMODE.LINEAR)

  --== events ==--

  --- fired after wipe_futures() got called 
  --self.on_buffer_wiped = renoise.Document.ObservableBang()

  --== internal ==--

  -- > Note: all buffers are accessed with the 'xinc', counting from 0 
  --- table<xLine>, buffer containing pattern data
  self.input_buffer = nil
  --- table<xLine>, buffer containing regular output 
  self.output_buffer = nil
  --- table<xLine>, buffer containing scheduled content 
  self.scheduled = nil

  --- int, keep track of the highest/lowest line in our output buffer
  -- (content that is up to date and ready for output)
  self.highest_xinc = nil
  self.lowest_xinc = nil

  --- int, the mute buffer index, nil when not muted 
  self.mute_xinc = nil

  --== initialize ==--

  self:clear()

end

---------------------------------------------------------------------------------------------------
-- Get/set
---------------------------------------------------------------------------------------------------

function xStreamBuffer:get_automation_playmode()
  return self.automation_playmode_observable.value
end

function xStreamBuffer:set_automation_playmode(val)
  self.automation_playmode_observable.value = val
end

---------------------------------------------------------------------------------------------------

function xStreamBuffer:get_write_track_index()
  return self.write_track_index_observable.value
end

function xStreamBuffer:set_write_track_index(val)
  self.write_track_index_observable.value = val
end

---------------------------------------------------------------------------------------------------

function xStreamBuffer:get_read_track_index()
  return self.read_track_index_observable.value
end

function xStreamBuffer:set_read_track_index(val)
  self.read_track_index_observable.value = val
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

function xStreamBuffer:get_active()
  return self.active_observable.value
end

function xStreamBuffer:set_active(val)
  TRACE("xStreamBuffer:set_active(val)",val)
  self.active_observable.value = val
end

---------------------------------------------------------------------------------------------------
-- Class methods
---------------------------------------------------------------------------------------------------
-- update all content ahead of our position
-- method is called when xStreamPos is changing position 'abruptly' and we no longer can 
-- trust the contents of the input buffer to be correct 

function xStreamBuffer:refresh_input_buffer()
  TRACE("xStreamBuffer:refresh_input_buffer()")

  local pos = xSongPos.create(self.xpos.pos) 
  local xinc = self.xpos.xinc
  local writeahead = xStreamPos.determine_writeahead()
  for k = 0,writeahead-1 do   
    self:_obtain_and_store_input(xinc,pos)
    xSongPos.increase_by_lines(1,pos)
    xinc = xinc + 1
  end
  self:wipe_futures()

end

---------------------------------------------------------------------------------------------------
-- Get input from callback/pattern, and store the result in input buffer 

function xStreamBuffer:_obtain_and_store_input(xinc,pos)
  TRACE("xStreamBuffer:_obtain_and_store_input(xinc,pos)",xinc,pos)

  local xline = nil
  if self.input_callback then
    TRACE(">>> xStreamBuffer:_obtain_and_store_input - from callback, xinc:",xinc)
    xline = self.input_callback(xinc)    
  elseif (self.read_track_index > 0) then
    TRACE(">>> xStreamBuffer:_obtain_and_store_input - from pattern, xinc",xinc,"pos:",pos,"read_track_index:",self.read_track_index)
    xline = xLine.do_read(pos.sequence,pos.line,self.include_hidden,self.read_track_index)
  end

  if not xline then
    TRACE(">>> xStreamBuffer:_obtain_and_store_input - empty_xline as fallback")
    xline = table.rcopy(xLine.EMPTY_XLINE)
  end      

  self.input_buffer[xinc] = xline

  return xline

end

---------------------------------------------------------------------------------------------------
-- Wipe all data behind our current position. 
-- Invoked as new output is produced, and the old content becomes obsolete

function xStreamBuffer:_wipe_past()
  TRACE("xStreamBuffer:_wipe_past()")
  local prev_xinc = self.xpos.xinc - 1
  for i = prev_xinc,self.lowest_xinc,-1 do
    self.output_buffer[i] = nil
    self.input_buffer[i] = nil
    self.scheduled[i] = nil
  end
  self.lowest_xinc = prev_xinc
end

---------------------------------------------------------------------------------------------------
-- Forget all output ahead of our current write-position - 
-- call when fresh content needs to be produced in the next cycle

function xStreamBuffer:wipe_futures()
  TRACE("xStreamBuffer:wipe_futures()")
  local xinc = self.xpos.xinc --self:_get_immediate_xinc() 
  --print(">>> wipe_futures - xinc",xinc)
  for i = xinc,self.highest_xinc do
    self.output_buffer[i] = nil
    --print(">>> wipe_futures - clear position",i)
  end
  self.highest_xinc = xinc-1
  self.scheduled = {}
  --self.on_buffer_wiped:bang()
  TRACE(">>> xStreamBuffer:wipe_futures - highest_xinc",self.highest_xinc)
end

---------------------------------------------------------------------------------------------------
-- Clear when preparing to stream

function xStreamBuffer:clear()
  TRACE("xStreamBuffer:clear()")

  self.highest_xinc = -1
  self.lowest_xinc = 0

  if self.mute_xinc then
    self.mute_xinc = -1
  end

  self.input_buffer = {}
  self.output_buffer = {}
  self.scheduled = {}

  -- important, but the responsibility of the owner
  --self.xpos:reset()

end

---------------------------------------------------------------------------------------------------
-- Return song position based on buffer position
-- @param xinc (int)
-- @return SongPos

function xStreamBuffer:_get_songpos(xinc)
  TRACE("xStreamBuffer:_get_songpos(xinc)",xinc)

  local pos = xSongPos.create(self.xpos.pos)
  local delta = xinc - self.xpos.xinc
  xSongPos.increase_by_lines(delta,pos)
  return pos

end

---------------------------------------------------------------------------------------------------
-- Schedule an xline 
-- @param xline (xLine)
-- @param xinc (number), the buffer position 

function xStreamBuffer:schedule_line(xline,xinc)
  TRACE("xStreamBuffer:schedule_line(xline)")

  self.scheduled[xinc] = xLine(xline)

end

---------------------------------------------------------------------------------------------------
-- schedule a single column (merge into existing xline)

function xStreamBuffer:schedule_note_column(xnotecol,col_idx,xinc)
  TRACE("xStreamBuffer:schedule_note_column(xnotecol,col_idx,xinc)",xnotecol,col_idx,xinc)

  assert(type(col_idx)=="number")

  if not xinc then xinc = self:_get_immediate_xinc() end
  local xline = self:_read_input_buffer(xinc,self:_get_songpos(xinc)) 
  xline.note_columns[col_idx] = xnotecol
  self:schedule_line(xline,xinc)
  
end

---------------------------------------------------------------------------------------------------
-- schedule a single column (merge into existing xline)

function xStreamBuffer:schedule_effect_column(xeffectcol,col_idx,xinc)
  TRACE("xStreamBuffer:schedule_effect_column(xeffectcol,col_idx,xinc)",xeffectcol,col_idx,xinc)

  assert(type(col_idx)=="number")

  if not xinc then xinc = self:_get_immediate_xinc() end
  local xline = self:_read_input_buffer(xinc,self:_get_songpos(xinc))
  xline.effect_columns[col_idx] = xeffectcol
  self:schedule_line(xline,xinc)

end

---------------------------------------------------------------------------------------------------
-- get the buffer index relative to our position (used for scheduling)
--  note that counting starts from current line when parked 
-- @param offset (int), number of lines 
-- @return int

function xStreamBuffer:_get_immediate_xinc()
  TRACE("xStreamBuffer:_get_immediate_xinc()")

  local live_mode = rns.transport.playing and 1 or 0
  return self.xpos.xinc + live_mode

end

---------------------------------------------------------------------------------------------------
-- trigger mute event (schedule note-offs if configured to)

function xStreamBuffer:mute()
  TRACE("xStreamBuffer:mute()")

  local function produce_note_off()
    local note_cols = {}
    local track = rns.tracks[self.write_track_index]
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

  local xinc = self:_get_immediate_xinc() 

  if (self.mute_mode == xStreamBuffer.MUTE_MODE.OFF) then
    -- insert not one, but *two* note-offs - since it is possible
    -- (although rarely) for the first note-off not to be picked up...
    local xline = {}
    xline.note_columns = produce_note_off()
    self:schedule_line(xline,xinc)
    self:schedule_line(xline,xinc+1)
    --print(">>> scheduled mutes for xinc",xinc+1,xinc+2)
    self.mute_xinc = xinc+1
  else
    self.mute_xinc = xinc
  end

  self:immediate_output()

end

-------------------------------------------------------------------------------

function xStreamBuffer:unmute()
  TRACE("xStreamBuffer:unmute()")

  self.mute_xinc = nil
  self:wipe_futures()
  self:immediate_output()

end

---------------------------------------------------------------------------------------------------
-- Create content: process xline using our callback method, 
-- and update output_buffer with result
-- @param num_lines, int 

function xStreamBuffer:_create_content(xinc,pos)
  TRACE("xStreamBuffer:_create_content(xinc,pos)",xinc,pos)

  -- read input (create if needed)
  local xline = self:_read_input_buffer(xinc,pos)

  -- decide if we need to evaluate the callback: highest_xinc
  -- indicates whether we have already processed it 
  local success,err
  if (xinc > self.highest_xinc) then
    success,err = pcall(function()
      xline = self.callback(xinc,xline,pos)
    end)
    TRACE(">>> xStreamBuffer - processed callback - xinc,pos,success,err",xinc,pos,success,err)
    if not success and err then
      LOG("*** Error: please review the callback function - "..err)
      self.callback_status_observable.value = err
    end
  end

  if type(xline)=="table" then 
    -- looks like we have redefined the xline in the callback, 
    -- convert to xLine instances (will validate it)
    success,err = pcall(function()
      xline = xLine(xline)
    end)
    -- log errors 
    if not success and err then
      LOG("*** Error: "..err)
      self.callback_status_observable.value = err        
    end
    -- ensure that we have an instance
    if not success then 
      xline = xLine(xLine.EMPTY_XLINE)
    end
  end 

-- add the resulting line to our output buffer, 
-- it will be used again in later iterations...
  if xline then 
    self:_set_output(xinc,xline)
  end

end

---------------------------------------------------------------------------------------------------
-- Retrieve content (scheduled or regular output). 
-- @param xinc (number)
-- @return xLine

function xStreamBuffer:get_output(xinc)
  TRACE("xStreamBuffer:get_output(xinc)",xinc)

  local xline = nil
  if not self.active or (self.mute_xinc and (xinc > self.mute_xinc)) then
    TRACE(">>> xStreamBuffer:get_output - running silent (muted or inactive)")
    xline = table.rcopy(xLine.EMPTY_XLINE)
  elseif self.scheduled[xinc] then 
    xline = self.scheduled[xinc]
    TRACE(">>> xStreamBuffer:get_output - scheduled content",xline)
  else 
    xline = self.output_buffer[xinc]   
    TRACE(">>> xStreamBuffer:get_output - regular content",xline)
  end

  if (type(xline)=="table") then
    xline = xLine(xline)
  end

  return xline

end

---------------------------------------------------------------------------------------------------
-- Set output for a given position
-- @param xinc (int)
-- @param xline (xLine or table) the content to insert 

function xStreamBuffer:_set_output(xinc,xline)
  TRACE("xStreamBuffer:_set_output(xinc,xline)",xinc,xline)

  assert(type(xinc)=="number")
  assert(type(xline)=="xLine",("Expected xLine, got %s"):format(type(xline)))

  self.output_buffer[xinc] = xline
  self.highest_xinc = math.max(xinc,self.highest_xinc)

  TRACE(">>> xStreamBuffer._set_output - self.highest_xinc",self.highest_xinc)

end

---------------------------------------------------------------------------------------------------
-- Get scheduled/existing input, or obtain if needed 
-- @param xinc (int), the buffer position
-- @param pos (SongPos), where to read from song
-- @return xLine, xline descriptor (never nil)

function xStreamBuffer:_read_input_buffer(xinc,pos)
  TRACE("xStreamBuffer:_read_input_buffer(xinc,pos)",xinc,pos)

  assert(type(xinc)=="number")
  assert(type(pos)=="SongPos")

  local xline = nil
  if self.scheduled[xinc] then 
    xline = self.scheduled[xinc]
  elseif self.input_buffer[xinc] then
    xline = self.input_buffer[xinc]
  else
    xline = self:_obtain_and_store_input(xinc,pos)
  end

  -- input buffer is 'read-only', return copy 
  return xLine(xline)

end

---------------------------------------------------------------------------------------------------
-- Perform immediate output for the upcoming line
-- (used with time-critical situations, such as un/muting or changing arguments that are 
-- set to 'impacts_buffer=true')

function xStreamBuffer:immediate_output()
  TRACE("xStreamBuffer:immediate_output()")

  local live_mode = rns.transport.playing
  local xinc = self:_get_immediate_xinc() 
  local pos = xSongPos.create(self.xpos.pos)
  xSongPos.increase_by_lines(1,pos)

  TRACE("*** xStreamBuffer:immediate output")
  self:write_output(pos,xinc,1,live_mode)

end

---------------------------------------------------------------------------------------------------
-- Write #num_lines into the pattern-track and/or automation lane
-- (call periodically when streaming in realtime, or directly when processing offline)
-- @param pos (SongPos)
-- @param xinc (int), buffer position 
-- @param [num_lines] (int), use writeahead if not defined
-- @param live_mode (bool), skip line at playpos when true

function xStreamBuffer:write_output(pos,xinc,num_lines,live_mode)
  TRACE("xStreamBuffer:write_output(pos,xinc,num_lines,live_mode)",pos,xinc,num_lines,live_mode)

  if not self.active then 
    return 
  end 

  if not self.callback then
    LOG("*** xStreamBuffer:write_output - no callback defined")
    return
  end

  if not num_lines then
    num_lines = rns.transport.playing and xStreamPos.determine_writeahead() or 1
  end

  -- purge old content from buffers
  self:_wipe_past()

  -- generate new content as needed
  local tmp_pos = xSongPos.create(pos) 
  for i = 0,num_lines do
    if not self.output_buffer[i+xinc] 
      and not self.scheduled[i+xinc]
    then
      self:_create_content(i+xinc,tmp_pos)
    end
    xSongPos.increase_by_lines(1,tmp_pos)
  end

  local tmp_pos = rns.transport.edit_pos
  local patt_num_lines = xPatternSequencer.get_number_of_lines(pos.sequence)

  for i = 0,num_lines-1 do

    tmp_pos.sequence = pos.sequence
    tmp_pos.line = pos.line+i

    if (tmp_pos.line > patt_num_lines) then 
      TRACE("xStreamBuffer:write_output exceeded pattern - normalize the songpos and redial ")
      xSongPos.normalize(tmp_pos)
      self:write_output(tmp_pos,xinc+i,num_lines-i)
      return
    end 

    local cached_line = tmp_pos.line
    if rns.transport.loop_block_enabled then
      tmp_pos.line = xSongPos.enforce_block_boundary("increase",pos,i)
      if (cached_line ~= tmp_pos.line) then 
        TRACE("xStreamBuffer:write_output - exceeded a block-loop")
        self:write_output(tmp_pos,xinc+i,num_lines-i)
        return
      end
    end

    -- only write to line when a track has been specified
    if (self.write_track_index == 0) then 
      LOG("*** skip output - no write_track_index has been defined")
    else
      if live_mode and (tmp_pos.line+1 == rns.transport.playback_pos.line) then
        -- skip current line when live streaming
      else
        local phrase = nil
        local xline = self:get_output(xinc+i)      
        self:write_line(xline,tmp_pos,phrase,patt_num_lines)
      end    
    end

  end

end

---------------------------------------------------------------------------------------------------
-- Write a single line at the specified position 
-- @param xline, xLine 
-- @param pos, SongPos 
-- @param [phrase], renoise.InstrumentPhrase
-- @param patt_num_lines, number 

function xStreamBuffer:write_line(xline,pos,phrase,patt_num_lines)
  TRACE("xStreamBuffer:write_line(xline,pos,phrase,patt_num_lines)",xline,pos,phrase,patt_num_lines)
    
  if not self.active then 
    return 
  end 

  if (type(xline)~="xLine") then
    LOG("*** Expected an instance of xline for output - sequence:",pos.sequence,"line:",pos.line)
    return
  end

  local ptrack_auto = nil
  local last_auto_seq_idx = nil

  -- check if we can/need to resolve automation        
  local device_param = rns.selected_automation_parameter        
  if device_param and xline.automation then
    if (pos.sequence ~= last_auto_seq_idx) then
      last_auto_seq_idx = pos.sequence
      ptrack_auto = self:resolve_automation(pos.sequence)
    end
    --print("*** ptrack_auto",ptrack_auto)
    if ptrack_auto then
      if (device_param.value_quantum == 0) then
        ptrack_auto.playmode = self.automation_playmode
      end
    end
  end

  TRACE(">>> xStreamBuffer:write_line - self.write_track_index",self.write_track_index,"pos",pos,xline)

  local success,err = pcall(function()
    xline:do_write(
      pos.sequence,
      pos.line,
      self.write_track_index,
      phrase,
      ptrack_auto,
      patt_num_lines,
      self.include_hidden,
      self.expand_columns,
      self.clear_undefined)
  end)

  if not success then
    LOG("*** WARNING: an error occurred while writing pattern-line - "..err)
  end

end        

---------------------------------------------------------------------------------------------------
-- Resolve or create automation for parameter in the provided seq-index
-- can return nil if trying to create automation on non-automateable param.
-- @param seq_idx (int)
-- @return renoise.PatternTrackAutomation or nil

function xStreamBuffer:resolve_automation(seq_idx)
  TRACE("xStreamBuffer:resolve_automation(seq_idx)",seq_idx)
 
  local patt_idx = rns.sequencer:pattern(seq_idx)
  local patt = rns.patterns[patt_idx]
  if not patt then
    LOG("*** xStreamBuffer:resolve_automation - Could not find pattern")
    return
  end

  local device_param = rns.selected_automation_parameter -- API5
  if not device_param or not device_param.is_automatable then
    LOG("*** xStreamBuffer:resolve_automation - Could not device_param or not automatable")
    return
  end

  local ptrack = patt.tracks[self.read_track_index]
  if not device_param or not device_param.is_automatable then
    LOG("*** xStreamBuffer:resolve_automation - Could not find pattern-track")
    return
  end

  return xAutomation.get_or_create_automation(ptrack,device_param)

end


