--[[============================================================================
main.lua
============================================================================]]--

require "gui"
--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Sample Editor:Process:Morph into...",
  invoke = function()
    show_dialog()
  end
}

renoise.tool():add_keybinding {
  name = "Sample Editor:Process:Morph into...",
  invoke = function()
    show_dialog()
  end
}

-- Get Tool Name

class "RenoiseScriptingTool" (renoise.Document.DocumentNode)
  function RenoiseScriptingTool:__init()    
    renoise.Document.DocumentNode.__init(self) 
    self:add_property("Name", "Untitled Tool")
  end

local manifest = RenoiseScriptingTool()
local ok,err = manifest:load_from("manifest.xml")
local tool_name = manifest:property("Name").value


--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------

function main()

  vb.views.cmbInstruments1.value = renoise.song().selected_instrument_index + 1
  vb.views.cmbSamples1.value =  renoise.song().selected_sample_index + 1
  vb.views.chkAction.value = true
  vb.views.rowAction.visible = false

end

function generate()

  if(instrument1 < 1) then
    
	renoise.app():show_warning("Please select instrument 'Source #1'");
	return;
	
  end

  if(instrument2 < 1) then
    
	renoise.app():show_warning("Please select instrument 'Source #2'");
	return;
	
  end

  if(sample1 < 1) then
    
    renoise.app():show_warning("Please select sample 'Source #1'");
	return;
	
  end

  if(sample2 < 1) then
    
    renoise.app():show_warning("Please select sample 'Source #2'");
	return;
	
  end
  
  if(instrument1 == instrument2 and sample1 == sample2) then
  
    renoise.app():show_warning("'Source #1' and 'Source #2' cannot be the same.");
	return;
  
  end
  
  if(samples < 1 or samples > 16) then
  
    renoise.app():show_warning("No. of samples must be between 1 and 16");
	return;
  
  end
  
  local buffer1 = renoise.song().instruments[instrument1].samples[sample1].sample_buffer;
  local buffer2 = renoise.song().instruments[instrument2].samples[sample2].sample_buffer;
  
  if not buffer1.has_sample_data then
  
    renoise.app():show_warning("'Source #1' has no sample data.");
	return;
  
  end
  
  if not buffer2.has_sample_data then
  
    renoise.app():show_warning("'Source #2' has no sample data.");
	return;
  
  end
  
  local frames1 = buffer1.number_of_frames;
  local frames2 = buffer2.number_of_frames;
  local channels1 = buffer1.number_of_channels;
  local channels2 = buffer2.number_of_channels;

  if(frames1 < 2) then
  
    renoise.app():show_warning("'Source #1' must have more than one frame of data.");
	return;
    
  end
  
  if(frames2 < 2) then
  
    renoise.app():show_warning("'Source #2' must have more than one frame of data.");
	return;
    
  end
  
  local step = buffer2.number_of_frames / frames1;
  
  local name1 = renoise.song().instruments[instrument1].samples[sample1].name
  local name2 = renoise.song().instruments[instrument2].samples[sample2].name
  
  -- add new instrument
  local instrument_new = renoise.song():insert_instrument_at(instrument1+1)
  
  for sample = 1, samples do
  
    --create the new sample
	local sample_new 
	if sample == 1 then 
	  sample_new = instrument_new.samples[1];
	else
	  if not one_instrument_per_sample then
	    sample_new = instrument_new:insert_sample_at(sample)
	  else
	    instrument_new = renoise.song():insert_instrument_at(instrument1+sample)
		sample_new = instrument_new.samples[1]
	  end
	end
	
	local sample_buffer_new = sample_new.sample_buffer
	
	sample_buffer_new:create_sample_data(buffer1.sample_rate, buffer1.bit_depth, channels1, frames1) 
	sample_buffer_new:prepare_sample_data_changes()
	
	local steps = samples + 1
	local frame2 = 1
	local weight1 = (steps - sample) / steps
	local weight2 = 1 - weight1
  
    for frame = 1, frames1 do
	
	  local frame1_data = 0
	  local frame2_data = 0
	
	  if(channels1 == channels2) then

  	    for channel = 1, channels1 do
	    
		  frame1_data = buffer1:sample_data(channel, frame)
		  frame2_data = buffer2:sample_data(channel, frame2)

		  local new_frame = frame1_data * weight1 + frame2_data * weight2
	      sample_buffer_new:set_sample_data(channel, frame, new_frame)
		  
	    end

	  elseif(channels1 == 1 and channels2 > 1) then
	  
	  -- buffer2 should be mixed together, then buffer1 should be mixed with buffer2 into buffer_new
		frame1_data = buffer1:sample_data(1, frame)
		  
		for channel = 1, channels2 do
		  
		  frame2_data = frame2_data + buffer2:sample_data(channel, frame2)
		  
		end
		  
		frame2_data = frame2_data / channels2;

        local new_frame = frame1_data * weight1 + frame2_data * weight2
	    sample_buffer_new:set_sample_data(1, frame, new_frame)
		
	  elseif(channels1 > 1 and channels2 == 1) then
	  
	  -- buffer1 channels should be mixed separately with the buffer2 channels and sent to one channel each

        frame2_data = buffer2:sample_data(1, frame2) * weight2
	  
		for channel = 1, channels1 do
		  
		  frame1_data = buffer1:sample_data(channel, frame)

		  local new_frame = frame1_data * weight1 + frame2_data
	      sample_buffer_new:set_sample_data(channel, frame, new_frame)
		  
		end

	  end
	
	  frame2 = frame2 + step
	  if frame2 > frames2 then
	    frame2 = frames2 --to avoid rounding errors when Source #2 is shorter than Source #1
	  end
	
	end

	sample_buffer_new:finalize_sample_data_changes()
	sample_new.name = "Morphing step #" .. sample

    instrument_new.name = "Morphing of " .. name1 .. " into " .. name2
	
	if samples > 1 and one_instrument_per_sample then
	  instrument_new.name = instrument_new.name .. ", step #" .. sample
	end
	
  end
  

end



