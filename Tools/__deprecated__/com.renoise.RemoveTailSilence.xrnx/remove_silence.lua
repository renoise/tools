--[[============================================================================
remove_silence.lua
============================================================================]]--

-- locals

local MODE_TRIMRIGHT = 4

local slider_volume = nil
local text_db = nil
local real_treshold = 0.001
local real_time = 0.01

local sample = nil
local buffer = nil
local int_frames = nil
local int_chans = nil
local int_mode = MODE_TRIMRIGHT


--------------------------------------------------------------------------------

local function is_under_threshold(int_frame)
  if (buffer == nil) then 
    return false, nil 
  end
  
  local real_value = nil
  local bool_is_under_threshold = true
  
  for int_chan = 1, int_chans do
    local real_value = math.abs(buffer:sample_data(int_chan,int_frame))
    if (real_value > real_treshold) then
      return false, real_value
    end
  end
  
  return true, real_value
end


--------------------------------------------------------------------------------

local function process_data(instrument, int_sample)

  if (real_time == nil) then
    renoise.app():show_error("Invalid time value!")
    return
  end

  local sample = instrument.samples[int_sample]
  
  local mapping = nil
  local int_layer = nil
  
  --print("ON layers:", table.getn(instrument.sample_mappings[renoise.Instrument.LAYER_NOTE_ON]))
  --print("OFF layers:", table.getn(instrument.sample_mappings[renoise.Instrument.LAYER_NOTE_OFF]))
  
  --look for old sample's sample mapping:
  for int_sample_mapping = 1, table.getn(instrument.sample_mappings[renoise.Instrument.LAYER_NOTE_ON]) do
  
    local sample_mapping = instrument.sample_mappings[renoise.Instrument.LAYER_NOTE_ON][int_sample_mapping]
	if sample_mapping.sample_index == int_sample then
	  mapping = sample_mapping
	  --print("sample found on ON layer ", int_sample_mapping)
	  int_layer = renoise.Instrument.LAYER_NOTE_ON
	  break
	else
	  --print(sample_mapping.sample_index,int_sample)
	end
  
  end

  if mapping == nil then
    for int_sample_mapping = 1, table.getn(instrument.sample_mappings[renoise.Instrument.LAYER_NOTE_OFF]) do
  
      local sample_mapping = instrument.sample_mappings[renoise.Instrument.LAYER_NOTE_OFF][int_sample_mapping]
	  if sample_mapping.sample_index == int_sample then
  	    mapping = sample_mapping
		print("sample found on OFF layer ", int_sample_mapping)
		int_layer = renoise.Instrument.LAYER_NOTE_OFF
	    break
	  end
  
    end
  end
  
  buffer = sample.sample_buffer
  int_frames = buffer.number_of_frames
  int_chans = buffer.number_of_channels
  
  local int_rate = buffer.sample_rate
  local int_depth = buffer.bit_depth
  
  local int_read_ahead = tonumber(real_time) * int_rate
  if(int_read_ahead == 0) then int_read_ahead = 1 end
  
  local int_cont, int_frame
  local int_silence_start = 0
  local int_silence_end = 0
  
  local array_int_silence_start = {}
  local array_int_silence_end = {}
  local int_detections = 0
  
  -- these will be useful when sample selection will be available in LUA API
  local int_range_start = 1
  local int_range_end = int_frames
  
  for int_frame = int_range_start, int_range_end do
  
    if (int_frame > int_range_end + int_read_ahead) then 
      -- we can already stop here
      break 
    end 

    local bool_is_under_threshold = is_under_threshold(int_frame)

    if (bool_is_under_threshold) then

      if (int_silence_start == 0) then
        -- found the beginning of a possible silence part
        int_silence_start = int_frame
        int_silence_end = 0
      else 
        -- silence is continuing
      
      end
        
    else

      if (int_silence_start ~= 0) then
        -- found the end of a possible silence part
        int_silence_end = int_frame

        if int_silence_end < int_range_end then 
          -- it is not a right trim
          int_silence_end = 0 
        end 

        if (int_silence_end - int_silence_start > int_read_ahead) then
        
          int_detections = int_detections +1
          array_int_silence_start[int_detections] = int_silence_start
          array_int_silence_end[int_detections] = int_silence_end
          
          --reset markers
          int_frame = int_silence_end + 1
          int_silence_start = 0
          int_silence_end = 0
          
        else
          --reset markers
          int_silence_start = 0
          int_silence_end = 0
        end
        
      else
        --reset markers
        int_silence_start = 0
        int_silence_end = 0
      end
    
    end
  
  end

  if int_silence_start ~= 0 then
    -- the sample ends with silence
    int_detections = int_detections + 1
    array_int_silence_start[int_detections] = int_silence_start
    array_int_silence_end[int_detections] = int_frames
  end
  
  local int_new_sample_length = 0
  
  -- we have to determine the size of the new sample before creating it
  int_new_sample_length = int_frames -- set the initial length value
    
  for int_detection = 1, int_detections do
    
    int_silence_start = array_int_silence_start[int_detection]
    int_silence_end = array_int_silence_end[int_detection]
	
	if int_silence_start == int_silence_end then return false end -- no silence found
	
	--print(int_silence_start,int_silence_end)
    
    --subtract the size of the removed data
    int_new_sample_length = int_new_sample_length - 
      (int_silence_end - int_silence_start)
      
  end
  
  if int_detections == 0 then return false end
  
  local sample_new = instrument:insert_sample_at(int_sample+1)
  local buffer_new = sample_new.sample_buffer

  --create the new sample which will substitute the old one
  if int_new_sample_length > 0 and 
    not buffer_new:create_sample_data(int_rate, 
      int_depth, int_chans, int_new_sample_length) 
  then
    renoise.app():show_error("Error during sample creation!")
    renoise.song():undo()
    return
  end
  
  buffer_new:prepare_sample_data_changes()
  
  local int_frame_new = 0
  int_frame = 1
  local int_detection
    
  for int_detection = 1, int_detections do
  
    int_silence_start = array_int_silence_start[int_detection]
    int_silence_end = array_int_silence_end[int_detection]
    
    while int_frame < int_silence_start do

      int_frame_new = int_frame_new + 1

      for int_chan = 1, int_chans do
        buffer_new:set_sample_data(int_chan,int_frame_new,
          buffer:sample_data(int_chan,int_frame))
      end
      
      int_frame = int_frame + 1
      
    end
  
    --simply skip the silence data
    int_frame = int_silence_end + 1
  
  end
  
  --pad the array with the last data
  while int_frame <= int_frames do
  
    int_frame_new = int_frame_new + 1
    
    for int_chan = 1, int_chans do
      buffer_new:set_sample_data(int_chan,int_frame_new,
        buffer:sample_data(int_chan,int_frame))
    end
    
    int_frame = int_frame + 1      
  end
  
  
  if int_detections > 0 then 
  
    buffer_new:finalize_sample_data_changes() 

    --restore sample properties
    sample_new.name = sample.name
    sample_new.panning = sample.panning
    sample_new.volume = sample.volume
    sample_new.base_note = sample.base_note
    sample_new.fine_tune = sample.fine_tune
    sample_new.beat_sync_enabled = sample.beat_sync_enabled
    sample_new.beat_sync_lines = sample.beat_sync_lines
    sample_new.interpolation_mode = sample.interpolation_mode
    sample_new.new_note_action = sample.new_note_action
    sample_new.loop_mode = sample.loop_mode
    
    if sample.loop_start < sample_new.sample_buffer.number_of_frames then 
      sample_new.loop_start = sample.loop_start 
    end
    
    if sample.loop_end < sample_new.sample_buffer.number_of_frames then 
      sample_new.loop_end = sample.loop_end 
    end

    instrument:delete_sample_at(int_sample)
    
    if mapping then
      instrument:insert_sample_mapping(
        int_layer, int_sample , mapping.base_note, mapping.note_range, mapping.velocity_range
      ) 
    end
	
	return true
	
  else
	
	return false

  end
  
end

--will cycle through samples of the current instrument and remove silence from them
function process_samples()

  local instrument = renoise.song().selected_instrument
  
  if table.getn(instrument.samples) > 0 and table.getn(instrument.samples[1].slice_markers) > 0 then
	renoise.app():show_warning("This instrument contains slices, this script does not support such case.")
	return
  end
  
  local num_samples = table.getn(instrument.samples)
  local num_trimmed = 0
  for int_sample = 1, num_samples do
  
    if process_data(instrument, int_sample) then 
	  num_trimmed = num_trimmed + 1 
	end
	
	renoise.app():show_status("Sample "..int_sample.." out of "..num_samples.." processed..")
	
  end
  
  renoise.app():show_status("All samples processed, "..num_trimmed.." trimmed.")

end

