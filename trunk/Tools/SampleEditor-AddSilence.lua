--[[----------------------------------------------------------------------------

  Script        : It-Alien_add_silence.lua
  Creation Date : 10/19/2009
  Last modified : 10/22/2009
  Version       : 0.25

----------------------------------------------------------------------------]]--

manifest = {}
manifest.api_version = 0.2
manifest.author = "Fabio Napodano | It-Alien (it-alien@renoise.com)"
manifest.description = "adds desired amount of silence to a sample at beginning or and."
manifest.actions = {}

local WHERE_START = 1;
local WHERE_END = 2;
local WHERE_BOTH = 3;
local int_where = WHERE_END;
local real_time = 1.0;

manifest.actions[#manifest.actions + 1] = {
  name = "SampleEditor:Process:Add Silence",
  description = manifest.description,
  invoke = function() show_dialog() end
}

local dialog;

function process_data()

	if real_time == nil then 
		renoise.app():show_error("Invalid duration value!");
		return;
	end

	local instrument = renoise.song().selected_instrument;
	local splitmap = instrument.split_map;
	local sample = renoise.song().selected_sample;
	local int_sample = renoise.song().selected_sample_index;
	local buffer = sample.sample_buffer;
	local int_frames = buffer.number_of_frames;
	local int_chans = buffer.number_of_channels;
	local int_rate = buffer.sample_rate;
	local int_depth = buffer.bit_depth;
	local int_frames_silence = real_time * int_rate;
	
	local sample_new = instrument:insert_sample_at(int_sample+1);
	local buffer_new = sample_new.sample_buffer;
	
	local int_frames_new_sample;

	if (int_where == WHERE_BOTH) then 
		int_frames_new_sample = int_frames + int_frames_silence * 2;
	else
		int_frames_new_sample = int_frames + int_frames_silence;
	end		

	if int_frames_new_sample > 0 and not buffer_new:create_sample_data(int_rate, int_depth, int_chans, int_frames_new_sample) then
		renoise.app():show_error("Error during sample creation!");
		renoise.song():undo();
		return;
	end

	local int_frame;
	local int_frame_new = 1;

	if (int_where ~= WHERE_END) then
		--add silence to the beginning of new sample
		for int_frame = 1, int_frames_silence do
			for int_chan = 1, int_chans do
				buffer_new:set_sample_data(int_chan,int_frame_new,0);
			end
			int_frame_new = int_frame_new + 1;
		end
	end
	
	for int_frame = 1, int_frames do
		--copy original sample data
		for int_chan = 1, int_chans do
			buffer_new:set_sample_data(int_chan,int_frame_new,buffer:sample_data(int_chan,int_frame));
		end
		int_frame_new = int_frame_new + 1;
	end	
	
	if (int_where ~= WHERE_START) then
		--add silence to the end of new sample
		for int_frame = 1, int_frames_silence do
			for int_chan = 1, int_chans do
				buffer_new:set_sample_data(int_chan,int_frame_new,0);
			end
			int_frame_new = int_frame_new + 1;
		end
	end
		
	buffer_new:finalize_sample_data_changes(); 
	
	--restore sample properties
	sample_new.name = sample.name;
	sample_new.panning = sample.panning;
	sample_new.volume = sample.volume;
	sample_new.base_note = sample.base_note;
	sample_new.fine_tune = sample.fine_tune;
	sample_new.beat_sync_enabled = sample.beat_sync_enabled;
	sample_new.beat_sync_lines = sample.beat_sync_lines;
	sample_new.interpolation_mode = sample.interpolation_mode;
	sample_new.new_note_action = sample.new_note_action;
	sample_new.loop_mode = sample.loop_mode;
	if(int_where == WHERE_END) then 
		sample_new.loop_start = sample.loop_start;
	else
		sample_new.loop_start = sample.loop_start + int_frames_silence;
	end
	if(int_where == WHERE_END) then 
		sample_new.loop_end = sample.loop_end;
	else
		sample_new.loop_end = sample.loop_end + int_frames_silence;
	end

	instrument:delete_sample_at(int_sample);
	instrument.split_map = splitmap;

end

function show_dialog() 

	if (dialog and dialog.visible) then
        -- already showing a dialog. bring it to front:
        dialog:show()
        return
    end
	
	local vb = renoise.ViewBuilder();
	
	local row_where = vb:row {
		vb:text {
			text = "Add silence at";
		},
		vb:chooser {
			id = "rdWhere",
			items = {"start","end", "both"},
			tooltip = [["Start = adds silence to start of sample; End = adds silence to end of sample"]],
			value = int_where,
			notifier = function(new_index)
				int_where = new_index;
			end
		}
	
	}

	
	local row_time = vb:row {
		vb:text {
			text = "Duration:"
		},
		vb:textfield {
			id = 'txtTime',
			width = 40,
			tooltip = [[type the duration of the silence ]],
			value = tostring(real_time),
			notifier = function(real_value)
				real_time = tonumber(real_value);
			end		  
		},
		vb:text {
			text = "secs."
		}
	}
	
	
	local valigner = vb:vertical_aligner {
		margin = 10
	}
	
	local button_process = vb:button {
		text = "Apply",
		tooltip = "Hit this button to add silence to the current sample.",
		width = 140,
		notifier = function()
			process_data()
		end
	}
	
	valigner:add_child(row_where);
	valigner:add_child(row_time);
	valigner:add_child(button_process);
	
	dialog = renoise.app():show_custom_dialog	(
		"Add Silence",
		valigner
	);
end
