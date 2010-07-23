--[[----------------------------------------------------------------------------
add_silence.lua
----------------------------------------------------------------------------]]--

-- notifiers

function instruments_list_changed()
end


--------------------------------------------------------------------------------

function new_song_loaded()
  if dialog ~= nil and dialog.visible then
    dialog:close()
    if not renoise.tool().app_new_document_observable:has_notifier(new_song_loaded)
  then
      renoise.tool().app_new_document_observable:add_notifier(new_song_loaded)
    end
  end
end

-- [[ GUI ]]

local dialog = nil
local DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT



local WHERE_START = 1
local WHERE_END = 2
local WHERE_BOTH = 3
local int_where = WHERE_END
local real_time = 1.0
local int_time_in_frames = 44100

--if renoise.song().selected_sample.sample_buffer.has_sample_data then
--	int_time_in_frames = 1.0 * renoise.song().selected_sample.sample_buffer.sample_rate
--end

--[[ Locals ]]

local function process_data()

  if (real_time == nil) then 
    renoise.app():show_error("Invalid duration value!")
    return
  end
 
  local instrument = renoise.song().selected_instrument
  local splitmap = instrument.split_map
  local sample = renoise.song().selected_sample
  local int_sample = renoise.song().selected_sample_index
  local buffer = sample.sample_buffer

  if (buffer.has_sample_data ~= true) then 
    renoise.app():show_error("No sample selected.")
    return
  end

  local int_chans = buffer.number_of_channels
  local int_rate = buffer.sample_rate
  local int_depth = buffer.bit_depth

  local int_frames_silence = 0
  
  if (int_time_in_frames == 0) then
  	-- might not be necessary anymore, since frames should always be set to *something*... 
    int_frames_silence = real_time * int_rate
  else
    int_frames_silence = int_time_in_frames
  end
  
  local int_frames = buffer.number_of_frames
  local int_frames_selected = buffer.selection_end - buffer.selection_start
  
  local sample_new = instrument:insert_sample_at(int_sample+1)
  local buffer_new = sample_new.sample_buffer
  
  local int_frames_new_sample

  if (int_where == WHERE_BOTH) then 
    int_frames_new_sample = int_frames + int_frames_silence * 2
  else
    int_frames_new_sample = int_frames + int_frames_silence
  end    

  if int_frames_new_sample > 0 and not buffer_new:create_sample_data(int_rate, int_depth, int_chans, int_frames_new_sample) then
    renoise.app():show_error("Error during sample creation!")
    renoise.song():undo()
    return
  end

  local int_frame
  local int_frame_new = 1

  if (buffer.selection_start > 1) then
    --copy the sample data before start of selection
    for int_frame = 1, (buffer.selection_start - 1) do
      for int_chan = 1, int_chans do
        buffer_new:set_sample_data(int_chan, int_frame_new, buffer:sample_data(int_chan, int_frame))
      end
      int_frame_new = int_frame_new + 1
    end
  end

  if (int_where ~= WHERE_END) then
    --add silence to the beginning
    for int_frame = 1, int_frames_silence do
      for int_chan = 1, int_chans do
        buffer_new:set_sample_data(int_chan, int_frame_new, 0)
      end
      int_frame_new = int_frame_new + 1
    end
  end
  
  for int_frame = buffer.selection_start, buffer.selection_end do
    --copy middle part
    for int_chan = 1, int_chans do
      buffer_new:set_sample_data(int_chan ,int_frame_new, buffer:sample_data(int_chan, int_frame))
    end
    int_frame_new = int_frame_new + 1
  end  
  
  if (int_where ~= WHERE_START) then
    --add silence to the end
    for int_frame = 1, int_frames_silence do
      for int_chan = 1, int_chans do
        buffer_new:set_sample_data(int_chan, int_frame_new, 0)
      end
      int_frame_new = int_frame_new + 1
    end
  end

  if (buffer.selection_end < int_frames) then
    --copy the sample data after selection
    for int_frame =  (buffer.selection_end + 1), int_frames do
      for int_chan = 1, int_chans do
        buffer_new:set_sample_data(int_chan,int_frame_new,buffer:sample_data(int_chan,int_frame))
      end
      int_frame_new = int_frame_new + 1
    end
  end
    
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
  if(int_where == WHERE_END) then 
    sample_new.loop_start = sample.loop_start
    sample_new.loop_end = sample.loop_end
  else
    sample_new.loop_start = sample.loop_start + int_frames_silence
    sample_new.loop_end = sample.loop_end + int_frames_silence
  end

  buffer_new:finalize_sample_data_changes() 
  
  instrument:delete_sample_at(int_sample)
  instrument.split_map = splitmap

end


--[[ GLOBALS ]]

function show_add_silence_dialog() 


  if not 
    renoise.song().instruments_observable:has_notifier(instruments_list_changed)
  then
    renoise.song().instruments_observable:add_notifier(instruments_list_changed)
  end
  
  if not 
    renoise.tool().app_new_document_observable:has_notifier(new_song_loaded) 
  then
    renoise.tool().app_new_document_observable:add_notifier(new_song_loaded)
  end

  if (dialog and dialog.visible) then
    -- already showing a dialog. bring it to front:
    dialog:show()
    return
  end


  local vb = renoise.ViewBuilder()

  local DEFAULT_DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local DEFAULT_DIALOG_SPACING = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
  local DEFAULT_DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
    
  local row_where = vb:row {
    vb:text {
      text = "Add silence at"
    },
    vb:chooser {
      id = "rdWhere",
      items = {"start","end", "both"},
      tooltip = [["Start = adds silence to start of sample End = adds silence to end of sample"]],
      value = int_where,
      notifier = function(new_index)
        int_where = new_index
      end
    }
  }
  local row_time1 = vb:row {
    vb:textfield {
      id = 'txtTime',
      width = 60,
      tooltip = "The duration of the silence seconds",
      value = tostring(real_time),
      notifier = function(real_value)
        real_time = tonumber(real_value)
	if real_time == nil then real_time = 0 end
        if renoise.song().selected_sample.sample_buffer.has_sample_data then
          int_time_in_frames = math.floor(real_time * renoise.song().selected_sample.sample_buffer.sample_rate) -- for some weird reason this breaks getting the selection length when selecting only one or two samples - oh well....
          vb.views.txtFrames.value = tostring(int_time_in_frames)
        end
      end      
    },
    vb:text {
      text = "seconds"
    }
  }
  local row_time2 = vb:row {
    vb:textfield {
      id = 'txtFrames',
      width = 60,
      tooltip = "The duration of the silence in number of frames",
      value = tostring(int_time_in_frames),
      notifier = function(real_value)
        int_time_in_frames = tonumber(real_value)
        if renoise.song().selected_sample.sample_buffer.has_sample_data then
          real_time = int_time_in_frames / renoise.song().selected_sample.sample_buffer.sample_rate
          vb.views.txtTime.value = tostring(real_time)
        end
      end      
    },
    vb:text {
      text = "frames"
    }
  }
  local row_time3 = vb:row {
    vb:button {
      text = "From selection",
      tooltip = "Get silence duration from selection length",
      height = DIALOG_BUTTON_HEIGHT,
      notifier = function()
        if renoise.song().selected_sample.sample_buffer.has_sample_data then
          int_time_in_frames = renoise.song().selected_sample.sample_buffer.selection_end - renoise.song().selected_sample.sample_buffer.selection_start + 1 --!!! why is that necessary, and does it cause problems elsewhere??
          vb.views.txtFrames.value = tostring(int_time_in_frames)
          real_time = int_time_in_frames / renoise.song().selected_sample.sample_buffer.sample_rate
          vb.views.txtTime.value = tostring(real_time)
         end
      end
    },
    vb:button {
      text = "Apply",
      tooltip = "*shhhh*",
      height = DIALOG_BUTTON_HEIGHT,
      notifier = function()
        process_data()
      end
    }
  }
  
  
  local main_rack = vb:column {
    margin = DEFAULT_DIALOG_MARGIN,
    spacing = DEFAULT_DIALOG_SPACING
  }
  
  main_rack:add_child(row_where)
  main_rack:add_child(row_time1)
  main_rack:add_child(row_time2)
  main_rack:add_child(row_time3)

  dialog = renoise.app():show_custom_dialog (
    "Add Silence",
    main_rack
  )


end
