--[[===============================================================================================
xSample
===============================================================================================]]--

--[[--

Static methods for working with renoise.Sample objects
.
#

]]

require (_clibroot.."cReflection")
require (_xlibroot.."xSampleMapping")
require (_xlibroot.."xPhrase")
require (_xlibroot.."xNoteColumn")

class 'xSample'

xSample.SAMPLE_INFO = {
  EMPTY = 1,
  SILENT = 2,
  PAN_LEFT = 4,
  PAN_RIGHT = 8,
  DUPLICATE = 16,
  MONO = 32,
  STEREO = 64,
}

xSample.SAMPLE_CHANNELS = {
  LEFT = 1,
  RIGHT = 2,
  BOTH = 3,
}

--- SAMPLE_CONVERT: misc. channel operations
-- MONO_MIX: stereo -> mono mix (mix left and right)
-- MONO_LEFT: stereo -> mono (keep left)
-- MONO_RIGHT: stereo -> mono (keep right)
-- STEREO: mono -> stereo
-- SWAP: stereo (swap channels)
xSample.SAMPLE_CONVERT = {
  MONO_MIX = 1, -- TODO
  MONO_LEFT = 2,
  MONO_RIGHT = 3,
  STEREO = 4,
  SWAP = 5,
}

xSample.BIT_DEPTH = {0,8,16,24,32}



---------------------------------------------------------------------------------------------------
-- credit goes to dblue
-- @param sample (renoise.Sample)
-- @return int (0 when no sample data)

function xSample.get_bit_depth(sample)
  TRACE("xSample.get_bit_depth(sample)",sample)

  local function reverse(t)
    local nt = {}
    local size = #t + 1
    for k,v in ipairs(t) do
      nt[size - k] = v
    end
    return nt
  end
  
  local function tobits(num)
    local t = {}
    while num > 0 do
      local rest = num % 2
      t[#t + 1] = rest
      num = (num - rest) / 2
    end
    t = reverse(t)
    return t
  end
  
  -- Vars and crap
  local bit_depth = 0
  local sample_max = math.pow(2, 32) / 2
  local buffer = sample.sample_buffer
  
  -- If we got some sample data to analyze
  if (buffer.has_sample_data) then
  
    local channels = buffer.number_of_channels
    local frames = buffer.number_of_frames
    
    for f = 1, frames do
      for c = 1, channels do
      
        -- Convert float to 32-bit unsigned int
        local s = (1 + buffer:sample_data(c, f)) * sample_max
        
        -- Measure bits used
        local bits = tobits(s)
        for b = 1, #bits do
          if bits[b] == 1 then
            if b > bit_depth then
              bit_depth = b
            end
          end
        end

      end
    end
  end
    
  return xSample.bits_to_xbits(bit_depth),bit_depth

end


---------------------------------------------------------------------------------------------------
-- convert any bit-depth to a valid xSample representation
-- @param num_bits (int)
-- @return int (xSample.BIT_DEPTH)

function xSample.bits_to_xbits(num_bits)
  if (num_bits == 0) then
    return 0
  end
  for k,xbits in ipairs(xSample.BIT_DEPTH) do
    if (num_bits <= xbits) then
      return xbits
    end
  end
  error("Number is outside allowed range")

end


----------------------------------------------------------------------------------------------------
-- check if sample has duplicate channel data, is hard-panned or silent
-- (several detection functions in one means less methods are needed...)
-- @param sample  (renoise.Sample)
-- @return enum (xSample.SAMPLE_[...])

function xSample.get_channel_info(sample)
  TRACE("xSample.get_channel_info(sample)",sample)

  local buffer = sample.sample_buffer
  if not buffer.has_sample_data then
    return xSample.SAMPLE_INFO.EMPTY
  end

  -- not much to do with a monophonic sound...
  if (buffer.number_of_channels == 1) then
    if xSample.sample_buffer_is_silent(buffer,xSample.SAMPLE_CHANNELS.LEFT) then
      return xSample.SAMPLE_INFO.SILENT
    else
      return xSample.SAMPLE_INFO.MONO
    end
  end

  local l_pan = true
  local r_pan = true
  local silent = true
  local duplicate = true

  local l = nil
  local r = nil
  local frames = buffer.number_of_frames
  for f = 1, frames do
    l = buffer:sample_data(1,f)
    r = buffer:sample_data(2,f)
    if (l ~= 0) then
      silent = false
      r_pan = false
    end
    if (r ~= 0) then
      silent = false
      l_pan = false
    end
    if (l ~= r) then
      duplicate = false
      if not silent and not r_pan and not l_pan then
        return xSample.SAMPLE_INFO.STEREO
      end
    end
  end

  if silent then
    return xSample.SAMPLE_INFO.SILENT
  elseif duplicate then
    return xSample.SAMPLE_INFO.DUPLICATE
  elseif r_pan then
    return xSample.SAMPLE_INFO.PAN_RIGHT
  elseif l_pan then
    return xSample.SAMPLE_INFO.PAN_LEFT
  end

  return xSample.SAMPLE_INFO.STEREO

end

----------------------------------------------------------------------------------------------------
-- convert sample: change bit-depth, perform channel operations, crop etc.
-- (jumping through a few hoops to keep keyzone and phrases intact...)
-- @param instr (renoise.Instrument)
-- @param sample_idx (int)
-- @param bit_depth (xSample.BIT_DEPTH)
-- @param channel_action (xSample.SAMPLE_CONVERT)
-- @param range (table) source start/end frames
-- @return renoise.Sample or nil (when failed to convert)

function xSample.convert_sample(instr,sample_idx,bit_depth,channel_action,range)
  TRACE("xSample.convert_sample(instr,sample_idx,bit_depth,channel_action)",instr,sample_idx,bit_depth,channel_action)

  local sample = instr.samples[sample_idx]
  local buffer = sample.sample_buffer
  if not buffer.has_sample_data then
    return false
  end

  local num_channels = (channel_action == xSample.SAMPLE_CONVERT.STEREO) and 2 or 1
  local num_frames = (range) and (range.end_frame-range.start_frame+1) or buffer.number_of_frames

  local new_sample = instr:insert_sample_at(sample_idx+1)
  local new_buffer = new_sample.sample_buffer
  local success = new_buffer:create_sample_data(
    buffer.sample_rate, 
    bit_depth, 
    num_channels,
    num_frames)  

  if not success then
    error("Failed to create sample buffer")
  end

  -- detect if instrument is in drumkit mode
  -- (when basenote is shifted by one semitone)
  local drumkit_mode = not ((new_sample.sample_mapping.note_range[1] == 0) and 
    (new_sample.sample_mapping.note_range[2] == 119))

  -- initialize certain aspects of sample
  -- before copying over information...
  new_sample.loop_start = 1
  new_sample.loop_end = num_frames

  cReflection.copy_object_properties(sample,new_sample)

  -- only when copying single channel 
  local channel_idx = 1 
  if(channel_action == xSample.SAMPLE_CONVERT.MONO_RIGHT) then
    channel_idx = 2
  end
  
  -- change sample 
  local f = nil
  new_buffer:prepare_sample_data_changes()
  for f_idx = range.start_frame,num_frames do

    if(channel_action == xSample.SAMPLE_CONVERT.MONO_MIX) then
      -- mix stereo to mono signal
      -- TODO 
    else
      -- copy from one channel to target channel(s)
      f = buffer:sample_data(channel_idx,f_idx)
      new_buffer:set_sample_data(1,f_idx,f)
      if (num_channels == 2) then
        f = buffer:sample_data(channel_idx,f_idx)
        new_buffer:set_sample_data(2,f_idx,f)
      end
    end

  end
  new_buffer:finalize_sample_data_changes()
  -- /change sample 

  -- when in drumkit mode, shift back keyzone mappings
  if drumkit_mode then
    xSampleMapping.shift_keyzone_by_semitones(instr,sample_idx+2,-1)
  end

  -- rewrite phrases so we don't loose direct sample 
  -- references when deleting the original sample
  for k,v in ipairs(instr.phrases) do
    xPhrase.replace_sample_index(v,sample_idx,sample_idx+1)
  end

  instr:delete_sample_at(sample_idx)

  return new_sample

end

----------------------------------------------------------------------------------------------------
-- check if the indicated sample buffer is silent
-- @param buffer (renoise.SampleBuffer)
-- @param channels (xSample.SAMPLE_CHANNELS)
-- @return bool (or nil if no data)

function xSample.sample_buffer_is_silent(buffer,channels)
  TRACE("xSample.sample_buffer_is_silent(buffer,channels)",buffer,channels)

  if not buffer.has_sample_data then
    return 
  end

  local frames = buffer.number_of_frames

  if (channels == xSample.SAMPLE_CHANNELS.BOTH) then
    for f = 1, frames do
      if (buffer:sample_data(1,f) ~= 0) or 
        (buffer:sample_data(2,f) ~= 0) 
      then
        return false
      end
    end
  elseif (channels == xSample.SAMPLE_CHANNELS.LEFT) then
    for f = 1, frames do
      if (buffer:sample_data(1,f) ~= 0) then
        return false
      end
    end
  elseif (channels == xSample.SAMPLE_CHANNELS.RIGHT) then
    for f = 1, frames do
      if (buffer:sample_data(2,f) ~= 0) then
        return false
      end
    end
  end

  return true

end

----------------------------------------------------------------------------------------------------
-- extract tokens from a sample name 
-- @param str, e.g. "VST: Synth1 VST (Honky Piano)_0x7F_C-5" 
-- @return table, {
--    sample_name = string ("Recorded sample 01"),
--    plugin_type = string ("VST" or "AU"),
--    plugin_name = string ("Synth1 VST"),
--    preset_name = string ("Honky Piano"),
--    velocity = string ("0x7F"),
--    note = string ("C-5")
--  }

function xSample.get_name_tokens(str)

  -- start by assuming it's a plugin
  local matches = str:gmatch("(.*): (.*) %((.*)%)[_%s]?([^_%s]*)[_%s]?([A-Z]*[-#]?[%d]*)")  
  local arg1,arg2,arg3,arg4,arg5 = matches()

  -- from end 
  local arg5_is_note = arg5 and xNoteColumn.note_string_to_value(arg5)
  local arg4_is_note = arg4 and xNoteColumn.note_string_to_value(arg4)
  local arg4_is_velocity = arg4 and tonumber(arg4)
  if arg5_is_note then
    return {
      plugin_type = arg1,
      plugin_name = arg2,
      preset_name = arg3,
      velocity = arg4,
      note = (arg5 ~= "") and arg5 or nil,
    }
  elseif arg4_is_velocity then
    return {
      plugin_type = arg1,
      plugin_name = arg2,
      preset_name = arg3,
      velocity = arg4
    }
  elseif arg4_is_note then
    return {
      plugin_type = arg1,
      plugin_name = arg2,
      preset_name = arg3,
      note = (arg4 ~= "") and arg4 or nil,
    }
  elseif arg3 then
    return {
      plugin_type = arg1,
      plugin_name = arg2,
      preset_name = arg3,
    }
  else
    -- does not seem to be a plugin
    local matches = str:gmatch("(.-)[_%s]?([^_%s]*)[_%s]?([A-Z]*[-#]?[%d]*)$") 
    local arg1,arg2,arg3 = matches()
    local arg3_is_note = arg3 and xNoteColumn.note_string_to_value(arg3)
    local arg2_is_note = arg2 and xNoteColumn.note_string_to_value(arg2)
    local arg2_is_velocity = arg2 and tonumber(arg2)
    if (arg1 == "") then
      return {
        sample_name = arg2,
      }
    elseif arg3_is_note then
      return {
        sample_name = arg1,
        velocity = arg2,
        note = (arg3 ~= "") and arg3 or nil,
      }
    elseif arg2_is_velocity then
      return {
        sample_name = arg1,
        velocity = arg2,
      }
    elseif arg2_is_note then
      return {
        sample_name = arg1,
        note = (arg2 ~= "") and arg2 or nil,
      }
    else 
      return {
        sample_name = arg1,
      }
    end
  end

  return {}

end

---------------------------------------------------------------------------------------------------
-- select region in waveform editor (clamp to valid range)
-- @param sample (renoise.Sample)
-- @param sel_start (int)
-- @param sel_end (int)

function xSample.set_buffer_selection(sample,sel_start,sel_end)
  TRACE("xSample.set_buffer_selection()",sample,sel_start,sel_end)
  
  local buffer = sample.sample_buffer
  if not buffer.has_sample_data then
    return false, "Cannot select, sample has no data"
  end

  local min = 1
  local max = buffer.number_of_frames  
  
  buffer.selection_range = {
    cLib.clamp_value(sel_start,min,max),
    cLib.clamp_value(sel_end,min,max),
  }

end

---------------------------------------------------------------------------------------------------
-- get a buffer position by "line"
-- note that fractional line values are supported
-- @param sample (renoise.Sample)
-- @param line (number) 
-- @return number or nil if out of bounds/no buffer

function xSample.get_buffer_frame_by_line(sample,line)
  TRACE("xSample.get_buffer_frame_by_line(line)",line)

  local buffer = sample.sample_buffer
  if not buffer.has_sample_data then
    return false, "Sample has no data"
  end

  local lines_per_minute = (rns.transport.lpb*rns.transport.bpm)
  local lines_per_sec = 60/lines_per_minute
  local line_frames = lines_per_sec*buffer.sample_rate
  return line*line_frames

end

---------------------------------------------------------------------------------------------------
-- get a buffer position by "beat"
-- note that fractional beat values are supported
-- @param beat (number)
-- @return number or nil if out of bounds/no buffer

function xSample.get_buffer_frame_by_beat(beat)
  TRACE("xSample.get_buffer_frame_by_beat(beat)",beat)
  
  local lpb = rns.transport.lpb
  return (xSample.get_buffer_frame_by_line(beat*lpb))

end

---------------------------------------------------------------------------------------------------
-- obtain the buffer frame from a particular position in the song
-- @param sample (renoise.Sample)
-- @param trigger_pos (xCursorPos), triggering position + note/pitch/delay/offset
-- @param end_pos (xCursorPos), the end position
-- @param [ignore_sxx] (boolean), handle special case with sliced instruments, where Sxx is 
--  used on the root sample for triggering individual slices 
-- @return table{
--  frame (number)
--  notecol (renoise.NoteColumn)
-- } or false,error (string) when failed

function xSample.get_buffer_frame_by_notepos(sample,trigger_pos,end_pos,ignore_sxx)
  TRACE("xSample.get_buffer_frame_by_notepos(sample,trigger_pos,end_pos,ignore_sxx)",sample,trigger_pos,end_pos,ignore_sxx)

  local patt_idx,patt,track,ptrack,line = trigger_pos:resolve()
  if not line then
    return false,"Could not resolve pattern-line"                    
  end

  local notecol = line.note_columns[trigger_pos.column]
  if not notecol then
    return false, "Could not resolve note-column"
  end

  -- get number of lines to the trigger note
  local line_diff = xSongPos.get_line_diff(trigger_pos,end_pos)

  -- precise position #1: subtract delay from triggering note
  if track.delay_column_visible then
    if (notecol.delay_value > 0) then
      line_diff = line_diff - (notecol.delay_value / 255)
    end
  end
  -- precise position #2: add fractional line 
  line_diff = line_diff + end_pos.fraction

  local frame = xSample.get_buffer_frame_by_line(sample,line_diff)
  frame = xSample.get_transposed_frame(notecol.note_value,frame,sample)

  -- increase frame if the sample was triggered using Sxx command 
  if not ignore_sxx and sample.sample_buffer.has_sample_data then 
    local matched_sxx = xLinePattern.get_effect_command(track,line,"0S",trigger_pos.column,true)
    if not table.is_empty(matched_sxx) then 
      -- the last matched value is the one affecting playback 
      local total_frames = sample.sample_buffer.number_of_frames       
      local applied_sxx = matched_sxx[#matched_sxx].value
      frame = frame + ((total_frames/256) * applied_sxx)
    end 
  end 


  return frame,notecol

end

---------------------------------------------------------------------------------------------------
-- transpose the number of frames 

function xSample.get_transposed_frame(note_value,frame,sample)
  TRACE("xSample.get_transposed_frame(note_value,frame,sample)",note_value,frame,sample)
  
  local transposed_note = xSample.get_transposed_note(note_value,sample)
  local transp_hz = cLib.note_to_hz(transposed_note)
  local base_hz = cLib.note_to_hz(48) -- middle C-4 note
  local ratio = base_hz / transp_hz
  frame = frame / ratio
  return frame

end

---------------------------------------------------------------------------------------------------
-- obtain the transposed note. Final pitch of the played sample is:
--   played_note - mapping.base_note + sample.transpose + sample.finetune 
-- @param played_note (number)
-- @param sample (Renoise.Sample)
-- @return number (natural number = pitch, fraction = finetune)

function xSample.get_transposed_note(played_note,sample)
  TRACE("xSample.get_transposed_note(played_note,sample)",played_note,sample)

  local mapping_note = sample.sample_mapping.base_note
  local sample_transpose = sample.transpose + (sample.fine_tune/128)
  return 48 + played_note - mapping_note + sample_transpose
end

---------------------------------------------------------------------------------------------------
-- obtain the note which is used when synced across a number of lines
-- (depends on sample length and playback speed)

function xSample.get_beatsynced_note(bpm,sample)
  TRACE("xSample.get_beatsynced_note(bpm,sample)",bpm,sample)
  
  local bpm = rns.transport.bpm
  local lpb = rns.transport.lpb
  return cLib.lines_to_note(sample.beat_sync_lines,bpm,lpb)

end

---------------------------------------------------------------------------------------------------
-- initialize loop to full range, using the provided mode

function xSample.initialize_loop(sample,loop_mode)

  local num_frames = 0
  if sample.sample_buffer.has_sample_data then
    num_frames = sample.sample_buffer.number_of_frames
  end
  sample.loop_start = 1
  sample.loop_end = num_frames or 1
  sample.loop_mode = loop_mode or renoise.Sample.LOOP_MODE_OFF

end

