--[[----------------------------------------------------------------------------

  Script        : It-Alien_Beatslicer.lua
  Creation Date : 10/19/2009
  Last modified : 11/19/2009
  Version       : 0.6

----------------------------------------------------------------------------]]--

manifest = {}
manifest.api_version = 0.2
manifest.author = "Fabio Napodano | It-Alien (it-alien@renoise.com)"
manifest.description = "divides a sample into pieces of equal size"
manifest.actions = {}

manifest.actions[#manifest.actions + 1] = {
  name = "SampleEditor:Process:Beatslicer",
  description = manifest.description,
  invoke = function() show_dialog() end
}

--[[ entry point ]]---------------------------------------------------------]]--

local SLICING_MODE_SLICES = 1;
local SLICING_MODE_SLICES_SECS = 2;
local SLICING_MODE_SLICES_BPM = 3;

local LOOP_MODE_FORWARD = 2;
local LOOP_MODE_BACKWARD = 3;
local LOOP_MODE_PINGPONG = 4;

local nSlices = 4;
local bDoMapping = true;
local bDoSync = true;
local nSyncLines = 0;
local nSlicingMode = SLICING_MODE_SLICES;
local bDoLoop = false;
local nLoopMode = LOOP_MODE_FORWARD;

function show_dialog()

	local smpSel = renoise.song().selected_sample;
	nSyncLines = smpSel.beat_sync_lines;
	bDoSync = smpSel.beat_sync_enabled;
	bDoLoop = smpSel.loop_mode > renoise.Sample.LOOP_MODE_OFF
	nLoopMode = smpSel.loop_mode;
	
	local vb = renoise.ViewBuilder();
	local DEFAULT_DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN;
	local DEFAULT_CONTROL_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING;
	local TEXT_ROW_WIDTH = 80;
	
	local row1 = vb:row {
		margin = DEFAULT_DIALOG_MARGIN,
		spacing = DEFAULT_CONTROL_SPACING,
		
         vb:popup {
            id = "cmbSlicingMode",
            width = 80,
            items = {"Slices", "Seconds", "BPM"},
            value = nSlicingMode,
            notifier = function(nVal)
               nSlicingMode = nVal
            end,
            tooltip = "Select the slicing mode."
		},
		
		vb:textfield {
			id = 'nSlices',
			width = 60,
			tooltip = [[insert the number of slices to create]],
			value = tostring(nSlices),
			notifier = function(value)
				nSlices = value
			end		  
		}
		
	}
	
	
	local row2 = vb:row {
		margin = DEFAULT_DIALOG_MARGIN,
		spacing = DEFAULT_CONTROL_SPACING,
		vb:checkbox {
            value = bDoMapping,
            tooltip = 'Automatically create an instrument map for the newly created samples. *WARNING*: blindly overwrites the current one!',
            notifier = function(value)
				bDoMapping = value
                end,
            },
			
		vb:text {
			text = "Create instrument mapping"
		}
	}

	local row3 = vb:row {
		margin = DEFAULT_DIALOG_MARGIN,
		spacing = DEFAULT_CONTROL_SPACING,
		vb:checkbox {
            value = bDoSync,
            tooltip = 'Enable beat-sync',
            notifier = function(value)
				bDoSync = value
                end,
            },
			
		vb:text {
			text = "Beat-Sync"
		},

		vb:textfield {
			id = 'nSynch',
			width = 30,
			tooltip = [[insert the number of lines to synch to]],
			value = tostring(nSyncLines),
			notifier = function(value)
				nSyncLines = value
			end		  
		}
	}

	local row4 = vb:row {
		margin = DEFAULT_DIALOG_MARGIN,
		spacing = DEFAULT_CONTROL_SPACING,
		vb:checkbox {
            value = bDoLoop,
            tooltip = 'Enable sample loop',
            notifier = function(value)
				bDoLoop = value
                end
        },
		vb:text {
			text = "Loop"
		},
		vb:popup {
            id = "cmbLoopMode",
            width = 100,
            items = {"None", "Forward", "Backward", "PingPong"},
            value = nLoopMode,
            notifier = function(nVal)
               nLoopMode = nVal
            end,
            tooltip = "Select the loop mode."
		}
	}

	local column51 = vb:column {
		style = "group",
		margin = DEFAULT_DIALOG_MARGIN,
		vb:button {
			text = "Slice!",
			tooltip = "Hit this button to automatically slice the current sample.",
			width = 130,
			notifier = function()
				slice_it()
			end
		}

	}	 
	
	local row5 = vb:row {
		margin = DEFAULT_DIALOG_MARGIN,
		spacing = DEFAULT_CONTROL_SPACING,
		column51
	}
	
	
	local grid = vb:vertical_aligner{};
	
	grid:add_child(row1);
	grid:add_child(row2);
	grid:add_child(row3);
	grid:add_child(row4);
	grid:add_child(row5);
	
	local dialog = renoise.app():show_custom_dialog	(
		"Automatic Beat Slicing",
		grid
	)
	
end

function slice_it()

	local nSlices = tonumber(nSlices);
	local nSliceSize = 0;
	if(nSlices==nil) then
		renoise.app():show_error("Invalid number of slices!");
		return;
	end

	local insSel = renoise.song().selected_instrument;
	local nSamples = table.getn(insSel.samples);
	local smpSel = renoise.song().selected_sample;
	local nSmpSel = renoise.song().selected_sample_index;
	local smpBuffSel = smpSel.sample_buffer;
	local nSmpSize = smpSel.sample_buffer.number_of_frames;
	
	if(nSlicingMode == SLICING_MODE_SLICES) then
		nSliceSize = nSmpSize / nSlices;
	elseif(nSlicingMode == SLICING_MODE_SLICES_SECS) then
		if(nSlice>0) then
			nSliceSize = smpBuffSel.sample_rate * nSlices;
			if(nSliceSize>0) then
				nSlices = math.ceil(nSmpSize / (nSliceSize));
			else
				nSlices = 0;
			end
		end
	elseif(nSlicingMode == SLICING_MODE_SLICES_BPM) then
		if(nSlices>0) then
			nSliceSize = (60 / nSlices) * smpBuffSel.sample_rate;
			if(nSliceSize>0) then
				nSlices = math.ceil(nSmpSize / (nSliceSize));
			end
		end		
	end

	if(nSlices <= 1 or nSliceSize <=1) then 
		renoise.app():show_error("Invalid number of slices!");
		return;
	end
	
	local nSyncLines = tonumber(nSyncLines);
	local arrSplit = {};
	
	if(nSyncLines == nil or nSyncLines <= 1) then 
		renoise.app():show_error("Invalid number of sync lines!");
		return;
	end

	local nBaseNote = smpSel.base_note;
	
	if(bDoMapping) then
		local nCont;
		for nCont = 1, 120 do
			arrSplit[nCont] = 1;
		end
	end
	
	local nSlice = 1;
	local nFrame = 1;
	while nFrame < nSmpSize do
	
		local smpNew = insSel.insert_sample_at(insSel,nSamples+1);
		nSamples = nSamples + 1;
		local smpBuffNew = smpNew.sample_buffer;
		
		if(smpBuffNew:create_sample_data(smpBuffSel.sample_rate, smpBuffSel.bit_depth, smpBuffSel.number_of_channels, nSliceSize)) then
		
			local nChan, nFrameNew;
			for nFrameNew = 1, smpBuffNew.number_of_frames do
				for nChan = 1, smpBuffSel.number_of_channels do
					local lValue = 0;
					if(nFrame<=nSmpSize) then
						lValue = smpBuffSel:sample_data(nChan,nFrame);
					end
					smpBuffNew:set_sample_data(nChan,nFrameNew,lValue);
				end
				nFrame = nFrame + 1;
			end
			
			if(bDoMapping) then
				smpNew.base_note = nBaseNote + nSlice-1;
				arrSplit[smpNew.base_note+1] = nSlice;
			end
			
			smpNew.beat_sync_enabled = bDoSync and (nSyncLines>0);
			if(smpNew.beat_sync_enabled) then
				smpNew.beat_sync_lines = nSyncLines;
			end
			
			if(bDoLoop) then
				smpNew.loop_mode = nLoopMode;
			else
				smpNew.loop_mode = renoise.Sample.LOOP_MODE_OFF;
			end

			smpNew.name = smpSel.name .. " slice" .. tostring(nSlice);
			nSlice = nSlice + 1;
			smpBuffNew:finalize_sample_data_changes();
			
		else
			renoise.app():show_error("Cannot create new sample! Aborting..");
			renoise.song():undo();
			return;
		end
	end
	insSel.delete_sample_at(insSel,nSmpSel);
	
	if(bDoMapping)then
		insSel.split_map = arrSplit;
	end

end