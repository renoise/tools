--[[----------------------------------------------------------------------------
remove_silence.lua
----------------------------------------------------------------------------]]--

local EPSILON = 1e-12
local MINUSINFDB = -200.0

function LinToDb(Value)
   if (Value > EPSILON) then
    return math.log10(Value) * 20.0
  else
    return MINUSINFDB
  end
end

function DbToLin(Value)
  if (Value > MINUSINFDB) then
    return math.pow(10.0, Value * 0.05)
  else
    return 0.0
  end
end

local MODE_ERASE = 1
local MODE_SILENCE = 2
local MODE_TRIMLEFT = 3
local MODE_TRIMRIGHT = 4
local MODE_TRIMBOTH = 5

local slider_volume = nil
local text_db = nil
local real_treshold = 0
local real_time = 0.01

local sample = nil
local buffer = nil
local int_frames = nil
local int_chans = nil
local int_mode = MODE_SILENCE


local dialog

local function is_under_threshold(int_frame)

  local real_value = nil

  if(buffer == nil) then return false, nil end
  
  local bool_is_under_threshold = true
  local int_chan
  for int_chan = 1, int_chans do

    local real_value = math.abs(buffer:sample_data(int_chan,int_frame))
    
    if (real_value > real_treshold) then
      return false, real_value
    end
    
  end
  
  return true, real_value
  
end

local function process_data()

  if real_time == nil then
    renoise.app():show_error("Invalid time value!")
    return
  end

  sample = renoise.song().selected_sample
  local instrument = renoise.song().selected_instrument
  local splitmap = instrument.split_map
  local int_sample = renoise.song().selected_sample_index
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
  
  --these will be useful when sample selection will be available in LUA API
  local int_range_start = 1
  local int_range_end = int_frames
  
  for int_frame = int_range_start, int_range_end do
  
    if (int_frame > int_range_end + int_read_ahead) then break end -- we can already stop here

    if (int_mode == MODE_TRIMLEFT) then
      if int_detections > 0 or int_silence_start > int_range_start then break end -- we already finished trimming to the left
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

        if (int_mode == MODE_TRIMRIGHT) then
          if int_silence_end < int_range_end then int_silence_end = 0 end -- it is not a right trim
        end

        if (int_mode == MODE_TRIMBOTH) then
          if int_silence_end ~= int_range_end and int_silence_start ~= int_range_start then int_silence_end = 0 end -- it is not a trim
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
    int_detections = int_detections +1
    array_int_silence_start[int_detections] = int_silence_start
    array_int_silence_end[int_detections] = int_frames
  end
  
  local int_new_sample_length = 0
  
  if(int_mode == MODE_SILENCE) then
  
    int_new_sample_length = int_frames -- no difference between new and old samples length
  
  else

    --we have to determine the size of the new sample before creating it

    int_new_sample_length = int_frames -- set the initial length value
    
    for int_detection = 1, int_detections do
    
      int_silence_start = array_int_silence_start[int_detection]
      int_silence_end = array_int_silence_end[int_detection]
    
      --subtract the size of the removed data
      int_new_sample_length = int_new_sample_length - (int_silence_end - int_silence_start)
      
    end
  
  end

  local sample_new = instrument:insert_sample_at(int_sample+1)
  local buffer_new = sample_new.sample_buffer

  --create the new sample which will substitute the old one
  if int_new_sample_length > 0 and not buffer_new:create_sample_data(int_rate, int_depth, int_chans, int_new_sample_length) then
    renoise.app():show_error("Error during sample creation!")
    renoise.song():undo()
    return
  end
  
  local int_frame_new = 0
  int_frame = 1
  local int_detection
    
  for int_detection = 1, int_detections do
  
    int_silence_start = array_int_silence_start[int_detection]
    int_silence_end = array_int_silence_end[int_detection]
    
    while int_frame < int_silence_start do

      int_frame_new = int_frame_new + 1

      for int_chan = 1, int_chans do
        buffer_new:set_sample_data(int_chan,int_frame_new,buffer:sample_data(int_chan,int_frame))
      end
      
      int_frame = int_frame + 1
      
    end
  
    while int_frame <= int_silence_end do
    
      if(int_mode == MODE_SILENCE) then
        --zero the data
        int_frame_new = int_frame_new + 1
        for int_chan = 1, int_chans do
          buffer_new:set_sample_data(int_chan,int_frame_new,0)
        end
      else
        --simply skip the silence data
      end
      
      int_frame = int_frame + 1
    
    end
  
  end
  
  --pad the array with the last data
  while int_frame <= int_frames do
  
    int_frame_new = int_frame_new + 1
    
    for int_chan = 1, int_chans do
      buffer_new:set_sample_data(int_chan,int_frame_new,buffer:sample_data(int_chan,int_frame))
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
    if sample.loop_start < sample_new.sample_buffer.number_of_frames then sample_new.loop_start = sample.loop_start end
    if sample.loop_end < sample_new.sample_buffer.number_of_frames then sample_new.loop_end = sample.loop_end end

    instrument:delete_sample_at(int_sample)
    
    instrument.split_map = splitmap
  end
  
end


--[[ GLOBALS ]]

function show_remove_silence_dialog() 

  if (dialog and dialog.visible) then
    -- already showing a dialog. bring it to front:
    dialog:show()
    return
  end
  
  local vb = renoise.ViewBuilder()

  local DEFAULT_DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local DEFAULT_DIALOG_SPACING = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
  local DEFAULT_DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT

  local text_lbl_treshold = vb:text {
    text = "Treshold: "
  }
  
  local text_lbl_db = vb:text {
    text = "dB"
  }

  text_db = vb:text {
    text = "0"
  }

  slider_volume = vb:slider {
     id='amplification_level',
     width = 140,
     min = 0, -- -INF using log scale
     max = 1, -- 0 Decibels using log scale
     value = 0,
     notifier = function(value)
    real_treshold = math.pow(value,3)
    if(real_treshold==0) then
      text_db.text = "-INF"
    else
      text_db.text = string.format("%.2f",LinToDb(real_treshold))      
    end
     end
  }
  
  slider_volume.value = 0.2
  
  local row_db = vb:row {
    text_lbl_treshold,
    text_db,
    text_lbl_db
  }
  
  local column_slider = vb:column {
    slider_volume
  }
  
  local row_time = vb:row {
    vb:text {
      text = "For more than:"
    },
    vb:textfield {
      id = 'txtTime',
      width = 40,
      tooltip = [[type the number of seconds which identify the silence ]],
      value = tostring(real_time),
      notifier = function(real_value)
        real_time = tonumber(real_value)
      end      
    },
    vb:text {
      text = "secs."
    }
  }
  
  local column_mode = vb:column {
    vb:text {
      text = "With relevant data.."
    },
    vb:chooser {
      id = "rdMode",
      tooltip = [["Erase = set data to zero Remove = deletes data from sample"]],
      value = int_mode,      
      items = {"remove", "silence", "trim left", "tirm right", "trim"},
      notifier = function(new_index)
        int_mode = new_index
      end
    }
  }
  
  local main_rack = vb:column {
    margin = DEFAULT_DIALOG_MARGIN,
    spacing = DEFAULT_DIALOG_SPACING
  }
  
  main_rack:add_child(row_db)
  main_rack:add_child(column_slider)
  main_rack:add_child(row_time)
  main_rack:add_child(column_mode)
  
  dialog = renoise.app():show_custom_prompt  (
    "Delete Silence",
    main_rack,
	{'Apply','Cancel'}
  )
end
