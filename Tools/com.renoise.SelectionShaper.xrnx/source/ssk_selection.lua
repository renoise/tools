--[[===============================================================================================
SSK_Selection
===============================================================================================]]--

--[[

Manage selections for the SSK tool 

]]

--=================================================================================================

class 'SSK_Selection'


---------------------------------------------------------------------------------------------------

function SSK_Selection:__init(owner)
  assert(type(owner)=="SSK")

  self.owner = owner 
  self.prefs = owner.prefs

  --- selection start/length - can be derived from formula in text input
  --- (updated in real-time when sync_with_renoise is specified)
  self.start_frames = property(self.get_start_frames,self.set_start_frames)
  self.start_frames_observable = renoise.Document.ObservableNumber(0)
  self.length_frames = property(self.get_length_frames,self.set_length_frames)
  self.length_frames_observable = renoise.Document.ObservableNumber(0)
  --- beats are derived from frames   
  self.start_beats = 0
  self.length_beats = 0
  --- TODO derive offsets from user-specified values 
  -- (those values are not changed as a result of programmatically changing the selection, 
  -- only when changed manually in the waveform editor)
  self.start_offset = 0
  self.length_offset = 0

  --- Multiplying range
  self.multiply_setend = cReflection.evaluate_string(self.prefs.multiply_setend.value)

  
end 

---------------------------------------------------------------------------------------------------
-- Getters & setters
---------------------------------------------------------------------------------------------------

function SSK_Selection:get_start_frames()
  return self.start_frames_observable.value
end 

function SSK_Selection:set_start_frames(val)
  self.start_frames_observable.value = val
end 

---------------------------------------------------------------------------------------------------

function SSK_Selection:get_length_frames()
  return self.length_frames_observable.value
end 

function SSK_Selection:set_length_frames(val)
  self.length_frames_observable.value = val
end 

---------------------------------------------------------------------------------------------------
-- Class methods
---------------------------------------------------------------------------------------------------

function SSK_Selection:display_as_os_fx()
  return (self.prefs.display_selection_as.value == SSK_Gui.DISPLAY_AS.OS_EFFECT) 
end

function SSK_Selection:display_as_beats()
  return (self.prefs.display_selection_as.value == SSK_Gui.DISPLAY_AS.BEATS) 
end

function SSK_Selection:display_as_samples()
  return (self.prefs.display_selection_as.value == SSK_Gui.DISPLAY_AS.SAMPLES) 
end

---------------------------------------------------------------------------------------------------
-- @return number or nil 

function SSK_Selection:get_range()
  local buffer = self.owner:get_sample_buffer()
  if buffer then 
    return xSampleBuffer.get_selection_range(buffer)
  end 
end 

---------------------------------------------------------------------------------------------------

function SSK_Selection:toggle_left()
  local buffer = self.owner:get_sample_buffer()
  if buffer then 
    return xSampleBuffer.selection_toggle_left(buffer)
  end 
end

---------------------------------------------------------------------------------------------------

function SSK_Selection:toggle_right()
  local buffer = self.owner:get_sample_buffer()
  if buffer then 
    return xSampleBuffer.selection_toggle_right(buffer)
  end 
end

---------------------------------------------------------------------------------------------------

function SSK_Selection:nudge_start(val)
  TRACE("SSK_Selection:nudge_start(val)",val)

  local sync_enabled = self.prefs.sync_with_renoise.value
  local sample = self.owner.sample 
  local buffer = sample.sample_buffer

  if (self:display_as_samples() 
    or self:display_as_beats())
  then 
    self.start_frames = self.start_frames + val
    if buffer and sync_enabled then
      local new_end = self.start_frames + self.length_frames
      self:apply_range(self.start_frames,new_end)
    end
  elseif self:display_as_os_fx() then
    -- use 16 as right-click increment/decrement
    val = (val == -10) and -0x10 or (val == 10) and 0x10 or val
    local start_offset = self.start_offset
    local num_frames = buffer.number_of_frames
    if (num_frames < 0x100) then 
      -- for small buffers, look up nearest start 
      if (val > 0) then
        start_offset = xSampleBuffer.get_next_offset(num_frames,start_offset+val-1)
      else
        start_offset = xSampleBuffer.get_previous_offset(num_frames,start_offset+val+1) or 0
      end
    else
      start_offset = self.start_offset + val
    end 
    if start_offset then
      self.start_offset = cLib.clamp_value(start_offset,0,256)    
      --print("self.start_offset POST",self.start_offset)
      if buffer and sync_enabled then
        local new_start = xSampleBuffer.get_frame_by_offset(buffer,self.start_offset)
        local new_end = new_start + self.length_frames
        self:apply_range(new_start,new_end)
      end
    end
  end

end

---------------------------------------------------------------------------------------------------
-- update the selection length inputs via infinite spinner 

function SSK_Selection:nudge_length(val)
  TRACE("SSK_Selection:nudge_length(val)",val)

  local sync_enabled = self.prefs.sync_with_renoise.value
  local sample = self.owner.sample 
  local buffer = sample.sample_buffer

  if (self:display_as_samples() 
    or self:display_as_beats())
  then 
    local min = 1
    local max = buffer.number_of_frames
    self.length_frames = cLib.clamp_value(self.length_frames + val,min,max)
    if buffer and sync_enabled then
      --local sel_length = self.length_frames
      local new_end = self.start_frames + self.length_frames
      self:apply_range(self.start_frames,new_end)
    end
  elseif self:display_as_os_fx() then
    -- use 16 as right-click increment/decrement
    val = (val == -10) and -0x10 or (val == 10) and 0x10 or val
    local length_offset = 0 
    local num_frames = buffer.number_of_frames
    if (num_frames < 0x100) then 
      -- for small buffers, look up nearest length 
      -- search from current end point
      local end_offset = self.start_offset+self.length_offset
      if (val > 0) then
        end_offset = xSampleBuffer.get_next_offset(num_frames,end_offset+val-1)
      else
        end_offset = xSampleBuffer.get_previous_offset(num_frames,end_offset+val+1)
      end
      --print("nudge_length - end_offset",end_offset)
      if end_offset then 
        length_offset = end_offset - self.start_offset
      end
    else
      length_offset = self.length_offset + val
    end 
    if length_offset then
      self.length_offset = cLib.clamp_value(length_offset,0,256)    
      --print("self.length_offset POST",self.length_offset)
      if buffer and sync_enabled then
        local end_offset = self.start_offset+self.length_offset
        --print("end_offset",end_offset)
        local new_start = xSampleBuffer.get_frame_by_offset(buffer,self.start_offset)
        local new_end = xSampleBuffer.get_frame_by_offset(buffer,end_offset)
        --local sel_length = sel_end-sel_start
        self:apply_range(new_start,new_end)
      end
    end
  end

end


---------------------------------------------------------------------------------------------------
-- extend the selected range by the specified amount 

function SSK_Selection:multiply_length()
  TRACE("SSK_Selection:multiply_length()")

  local buffer = self.owner:get_sample_buffer()
  if buffer then
    if self:display_as_os_fx() then 
      local new_length_offset = cLib.round_value(self.multiply_setend*self.length_offset)
      local new_offset = self.start_offset+new_length_offset
      buffer.selection_end = xSampleBuffer.get_frame_by_offset(buffer,new_offset)-1
    else  
      local range = xSampleBuffer.get_selection_range(buffer)
      local new_length = cLib.round_value(self.multiply_setend*range)
      local new_end = self.start_frames + new_length
      self:apply_range(self.start_frames,new_end)
    end
  end

end

---------------------------------------------------------------------------------------------------
-- divide the selected range by the specified amount 

function SSK_Selection:divide_length()
  TRACE("SSK_Selection:divide_length()")

  local buffer = self.owner:get_sample_buffer()
  if buffer then
    if self:display_as_os_fx() then 
      local new_length_offset = cLib.round_value((1/self.multiply_setend)*self.length_offset)
      local new_offset = self.start_offset+new_length_offset
      buffer.selection_end = xSampleBuffer.get_frame_by_offset(buffer,new_offset)-1
    else
      local range = xSampleBuffer.get_selection_range(buffer)
      local new_length = cLib.round_value((1/self.multiply_setend)*range)
      local new_end = self.start_frames + new_length
      self:apply_range(self.start_frames,new_end)
    end
  end

end

---------------------------------------------------------------------------------------------------
-- true when the current selection aligns perfectly with the start (no leading space)
-- @return boolean 

function SSK_Selection:is_perfect_lead()
  TRACE("SSK_Selection:is_perfect_lead()")

  local as_os_fx = self:display_as_os_fx()
  if as_os_fx then
    return self.start_offset%self.length_offset == 0
  else
    return false
  end

end

---------------------------------------------------------------------------------------------------
-- true when the current selection aligns perfectly with the end (no trailing space)
-- @return boolean 

function SSK_Selection:is_perfect_trail()
  TRACE("SSK_Selection:is_perfect_trail()")

  local as_os_fx = self:display_as_os_fx()
  if as_os_fx then 
    local tmp = self.start_offset
    while (tmp < 256) do 
      tmp = tmp + self.length_offset
      if (tmp == 256) then 
        return true
      end 
    end 
  end
  return false 

end

---------------------------------------------------------------------------------------------------
-- 0S/offset mode: obtain the start & end of specific segment
-- return number,number (1-#frames in buffer)

function SSK_Selection:get_nth_segment_by_offset(idx,num_segments)
  TRACE("SSK_Selection:get_nth_segment_by_offset(idx,num_segments)",idx,num_segments)

  local buffer = self.owner:get_sample_buffer()
  assert(buffer)
  local frame_start = xSampleBuffer.get_frame_by_offset(buffer,idx*self.length_offset)
  local frame_end = xSampleBuffer.get_frame_by_offset(buffer,(idx+1)*self.length_offset)

  if (idx+1 == num_segments) then 
    -- extend last segment to the end  
    frame_end = buffer.number_of_frames
  else 
    frame_end = frame_end - 1
  end 
  
  return frame_start,frame_end

end

---------------------------------------------------------------------------------------------------
-- set selection range, extend buffer if needed 
-- @param sel_start (number), #frames, if negative we extend at the beginning
-- @param sel_end (number), #frames, if > buffer we extend at the end

function SSK_Selection:apply_range(sel_start,sel_end)
  TRACE("SSK_Selection:apply_range(sel_start,sel_end)",sel_start,sel_end)

  assert(type(sel_start)=="number")
  assert(type(sel_end)=="number")

  local buffer = self.owner:get_sample_buffer() 
  assert(type(buffer)=="SampleBuffer")


  -- TODO check if end point is > buffer AND 
  -- selection start is negative (we don't allow both)

  local range = sel_end - sel_start + 1
  if (range <= 0) then 
    renoise.app():show_error('Enter a number greater than zero')
  end

  if (sel_end <= buffer.number_of_frames) and (sel_start >= 1) then
    -- within existing buffer, select
    --print("set selection_range",sel_start,sel_end)
    buffer.selection_range = {sel_start,sel_end-1}
  else
    -- extend sample beyond start/end 
    local extend_at_end = (sel_start > 0)
    print("*** extend_at_end",extend_at_end)
    local loop_start = self.owner.sample.loop_start
    local loop_end = self.owner.sample.loop_end    
    local extend_by
    if extend_at_end then 
      extend_by = sel_end - buffer.number_of_frames - 1
    else
      extend_by = sel_start-1
      loop_start = loop_start+math.abs(extend_by)
      loop_end = loop_end+math.abs(extend_by)      
    end
    --print("extend_by",extend_by)

    local bop = xSampleBufferOperation{
      instrument_index = self.owner.instrument_index,
      sample_index = self.owner.sample_index,
      restore_zoom = true,
      force_frames = buffer.number_of_frames + math.abs(extend_by),
      operations = {
        xSampleBuffer.extend{
          buffer=buffer,
          extend_by=extend_by,
        }
      },
      on_complete = function(_bop_)
        TRACE("[apply_selection_range] process_done")
        local buffer = _bop_.buffer 
        local sample = _bop_.sample
        if extend_at_end then
          buffer.selection_range = {sel_start,buffer.number_of_frames}
        else
          buffer.selection_range = {1,range-1}
        end
        xSample.set_loop_pos(sample,loop_start,loop_end)
      end,
      on_error = function(err)
        TRACE("*** error message",err)
      end
    }
    bop:run()
  end

end

---------------------------------------------------------------------------------------------------
-- move selection forwards (towards end), inserting frames when needed
-- @return boolean 

function SSK_Selection:flick_forward()
  TRACE("SSK_Selection:flick_forward()")

  local buffer = self.owner:get_sample_buffer() 
  if not buffer then 
    return  
  end 

  local range = xSampleBuffer.get_selection_range(buffer)
  local sel_start,new_start,new_end 

  if self:display_as_os_fx() then 
    -- special handling for OS (stay precise)
    local new_start_offset = self.start_offset+self.length_offset
    local new_end_offset = self.start_offset+(self.length_offset*2)
    --print("new_start_offset,new_end_offset",new_start_offset,new_end_offset)
    new_start = xSampleBuffer.get_frame_by_offset(buffer,new_start_offset)    
    new_end = xSampleBuffer.get_frame_by_offset(buffer,new_end_offset)
    -- if (new_end_offset < 256) then 
    --   new_end = new_end - 1
    -- end 
  else 
    -- normal, frame based calculation
    new_start = buffer.selection_start+range
    new_end = new_start+range
  end 
  --print("flick back - range,new_start",range,new_start)
  self:apply_range(new_start,new_end)

end

---------------------------------------------------------------------------------------------------
-- move selection backwards (towards start), inserting frames when needed
-- @return boolean 

function SSK_Selection:flick_back()
  TRACE("SSK_Selection:flick_back()")

  local buffer = self.owner:get_sample_buffer() 
  if not buffer then 
    return  
  end 
  local range = xSampleBuffer.get_selection_range(buffer)
  local new_start,new_end 

  -- special handling for OS (stay precise)
  if self:display_as_os_fx() then 
    local start_offset = self.start_offset-self.length_offset
    new_start = xSampleBuffer.get_frame_by_offset(buffer,start_offset)
    new_end = xSampleBuffer.get_frame_by_offset(buffer,self.start_offset)
  else 
    new_start = buffer.selection_start - range
    new_end = new_start+range
  end 
  --print("flick back - new_start,new_end",new_start,new_end)
  self:apply_range(new_start,new_end)

end

---------------------------------------------------------------------------------------------------
-- when pressing the [-->] arrow button next to the sel.start input,
-- or while sync_with_renoise is enabled

function SSK_Selection:obtain_start_from_editor()
  TRACE("SSK_Selection:obtain_start_from_editor()")

  local buffer = self.owner:get_sample_buffer()
  if buffer then 
    self.start_frames = buffer.selection_start
    self.start_beats = self:get_beats_from_frame(buffer.selection_start)
    self.start_offset = self:get_offset_from_frame(buffer.selection_start)
    --print(">>> self.start_offset",self.start_offset)
  end 

end

---------------------------------------------------------------------------------------------------

function SSK_Selection:obtain_end_offset(buffer)
  return xSampleBuffer.get_offset_by_frame(buffer,buffer.selection_end+1)
end

---------------------------------------------------------------------------------------------------
-- when pressing the [-->] arrow button next to the sel.length input,
-- or while sync_with_renoise is enabled

function SSK_Selection:obtain_length_from_editor()
  TRACE("SSK_Selection:obtain_length_from_editor()")

  local buffer = self.owner:get_sample_buffer()
  if buffer then 
    local range = xSampleBuffer.get_selection_range(buffer)
    self.length_frames = xSampleBuffer.get_selection_range(buffer)
    self.length_beats = self:get_beats_from_frame(range)
    self.length_offset = self:obtain_end_offset(buffer)-self.start_offset
    --print(">>> self.length_offset",self.length_offset)
  end 

end

---------------------------------------------------------------------------------------------------
-- @return number 

function SSK_Selection:get_beats_from_frame(frame)
  TRACE("SSK_Selection:get_beats_from_frame(frame)",frame)
  local buffer = self.owner:get_sample_buffer() 
  if not buffer then 
    return 0 
  end  
  local beat = xSampleBuffer.get_beat_by_frame(buffer,frame) 
  return beat * (self:beat_unit_with_sync() * self:beat_unit_with_base_tune())
end

---------------------------------------------------------------------------------------------------
-- @return number 

function SSK_Selection:get_offset_from_frame(frame)
  TRACE("SSK_Selection:get_offset_from_frame(frame)",frame)
  local buffer = self.owner:get_sample_buffer() 
  if not buffer then 
    return 0 
  end
  return xSampleBuffer.get_offset_by_frame(buffer,frame) 
end

---------------------------------------------------------------------------------------------------
-- interpret the selection start/length input as user is typing
-- (invalid values are returned as undefined)
-- @param str (string)
-- @param is_start (boolean), when interpreting the selection start input 
-- @return number or nil, number or nil, number or nil

function SSK_Selection:interpret_input(str,is_start)
  TRACE("SSK_Selection:interpret_input(str)",str)

  local buffer = self.owner:get_sample_buffer() 
  assert(type(buffer)=="SampleBuffer")

  local frame,beat,offset = nil,nil
  if self:display_as_os_fx() then
    offset = cReflection.evaluate_string(str)
    if offset then 
      -- for start, we allow OS Effect to be 0 (== frame 1)
      if (offset == 0) and not is_start then
        offset = 256
      end
      if (offset >= 256) then 
        frame = buffer.number_of_frames
      else 
        frame = xSampleBuffer.get_frame_by_offset(buffer,offset)
      end
      if not is_start then 
        -- reduce end by one frame when not start 
        frame = frame - 1
      end 
      if offset then 
        beat = xSampleBuffer.get_beat_by_frame(buffer,frame)
      end
    end
  elseif self:display_as_samples() then 
    frame = SSK_Selection.string_to_frames(str,self.prefs.A4hz.value,buffer.sample_rate) 
    if frame then
      beat = xSampleBuffer.get_beat_by_frame(buffer,frame)          
      offset = xSampleBuffer.get_offset_by_frame(buffer,frame)
    end
  elseif self:display_as_beats() then 
    beat = cReflection.evaluate_string(str)
    if beat then
      frame = xSampleBuffer.get_frame_by_beat(buffer,beat)
      offset = xSampleBuffer.get_offset_by_frame(buffer,frame)
    end          
  end
  --print(">>> interpret_input - offset,beat,frame",offset,beat,frame)
  return offset,beat,frame

end

---------------------------------------------------------------------------------------------------
-- obtain the length in beats when sample is beat-synced

function SSK_Selection:beat_unit_with_sync()
  TRACE("SSK_Selection:beat_unit_with_sync()")
  assert(type(self.owner.sample)=="Sample")
  local buffer = self.owner:get_sample_buffer() 
  if not buffer or not self.owner.sample.beat_sync_enabled then 
    return 1
  else
    return (buffer.number_of_frames * (rns.transport.lpb / self.owner.sample.beat_sync_lines))
      / ((1 / rns.transport.bpm * 60) * buffer.sample_rate)
  end
end

---------------------------------------------------------------------------------------------------
-- for possible replacement - see xSample.get_transposed_note

function SSK_Selection:beat_unit_with_base_tune()
  TRACE("SSK_Selection:beat_unit_with_base_tune()")

  local sample = self.owner.sample 
  assert(type(sample)=="Sample")

  if (sample.transpose == 0 and sample.fine_tune == 0) 
    or sample.beat_sync_enabled
  then 
    return 1
  else 
    return math.pow ((1/2),(sample.transpose-(sample.fine_tune/128))/12)
  end
end

---------------------------------------------------------------------------------------------------
-- figure out the hz for the current selection, including sample transpose

function SSK_Selection:get_hz_from_range()
  TRACE("SSK_Selection:get_hz_from_range()")

  local buffer = self.owner:get_sample_buffer() 
  assert(type(buffer)=="SampleBuffer")

  local sample = self.owner.sample   
  assert(type(sample)=="Sample")

  local sel_hz = buffer.sample_rate/xSampleBuffer.get_selection_range(buffer) 
  local transp_hz = cLib.note_to_hz(xSample.get_transpose(sample))
  local base_hz = cLib.note_to_hz(48) 
  return (transp_hz / base_hz) * sel_hz

end

---------------------------------------------------------------------------------------------------
-- Static methods 
---------------------------------------------------------------------------------------------------
-- convert input to #frames (accepts notes, expressions and numbers)
-- was previous "str2wvnum"

function SSK_Selection.string_to_frames(str,ini_hz,sample_rate)
  TRACE("SSK_Selection.string_to_frames(str,ini_hz,sample_rate)",str,ini_hz,sample_rate)
  if (ini_hz==nil) then
    ini_hz=440
  end
  local st = xNoteColumn.note_string_to_value(str)
  -- check for out-of-range values (above 119)
  if not st or (st > 119) then 
    return cReflection.evaluate_string(str)
  else 
    return cLib.note_to_frames(st,sample_rate,ini_hz)
  end
end


