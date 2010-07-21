--[[============================================================================
main.lua
============================================================================]]--

-- locals

local SLICING_MODE_SLICES = 1
local SLICING_MODE_SLICES_SECS = 2
local SLICING_MODE_SLICES_BPM = 3

local LOOP_MODE_FORWARD = 2
local LOOP_MODE_BACKWARD = 3
local LOOP_MODE_PINGPONG = 4

local nSlices = 4
local bDoMapping = true
local bDoSync = true
local nSyncLines = 0
local nSlicingMode = SLICING_MODE_SLICES
local bDoLoop = false
local nLoopMode = LOOP_MODE_FORWARD
local bDoAutoseek = false

--------------------------------------------------------------------------------
-- tool registration
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Sample Editor:Process:Beatslicer...",
  invoke = function() 
    show_dialog() 
  end
}

renoise.tool():add_keybinding {
	name = "Sample Editor:Process:BeatSlicer",
	invoke = function() 
		show_dialog() 
	end
}

--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

function show_dialog()

  local smpSel = renoise.song().selected_sample
  nSyncLines = smpSel.beat_sync_lines
  bDoSync = smpSel.beat_sync_enabled
  bDoLoop = smpSel.loop_mode > renoise.Sample.LOOP_MODE_OFF
  nLoopMode = smpSel.loop_mode
  bDoAutoseek = smpSel.autoseek

  local vb = renoise.ViewBuilder()

  local DEFAULT_CONTROL_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING

  local DEFAULT_DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local DEFAULT_DIALOG_SPACING = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
  local DEFAULT_DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
  
  local TEXT_WIDTH = 80
  
  local row1 = vb:row {
    vb:popup {
      id = "cmbSlicingMode",
      width = TEXT_WIDTH,
      items = {"Slices", "Seconds", "BPM"},
      value = nSlicingMode,
      notifier = function(nVal)
         nSlicingMode = nVal
      end,
      tooltip = "Select the slicing mode."
    },
    
    vb:textfield {
      id = 'nSlices',
      width = 80,
      tooltip = [[insert the number of slices to create]],
      value = tostring(nSlices),
      notifier = function(value)
        nSlices = value
      end      
    }
  }
  
  
  local row2 = vb:row {
    vb:checkbox {
      value = bDoMapping,
      tooltip = "Automatically create an instrument map for the newly " ..
        "created samples. *WARNING*: blindly overwrites the current one!",
      notifier = function(value)
        bDoMapping = value
      end,
    },
      
    vb:text {
      text = "Create instr. mapping"
    }
  }

  local row3 = vb:row {
    vb:checkbox {
      value = bDoSync,
      tooltip = 'Enable beat-sync',
      notifier = function(value)
        bDoSync = value
      end,
    },
      
    vb:text {
      width = TEXT_WIDTH - vb:checkbox{}.width,
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
   vb:checkbox {
      value = bDoLoop,
      tooltip = 'Enable sample loop',
      notifier = function(value)
        bDoLoop = value
      end
    },
    
    vb:text {
      text = "Loop",
      width = TEXT_WIDTH - vb:checkbox{}.width,
    },
    
    vb:popup {
      id = "cmbLoopMode",
      width = 80,
      items = {"None", "Forward", "Backward", "PingPong"},
      value = nLoopMode,
      notifier = function(nVal)
         nLoopMode = nVal
      end,
      tooltip = "Select the loop mode."
    }
  }

  local row5 = vb:row {
   vb:checkbox {
      value = bDoAutoseek,
      tooltip = 'Enable Autoseek',
      notifier = function(value)
        bDoAutoseek = value
      end
    },
    
    vb:text {
      text = "Autoseek",
      width = TEXT_WIDTH - vb:checkbox{}.width,
    },
    
  }

  local dialog = renoise.app():show_custom_prompt  (
    "Auto Slicer",
    vb:column{
      margin = DEFAULT_DIALOG_MARGIN,
      spacing = DEFAULT_CONTROL_SPACING,
      row1,
      row2,
      row3,
      row4,
      row5,
      vb:space { }
    },
    {'Slice!','Cancel'}
  )
  
  if dialog == 'Slice!' then
    slice_it()
  end

  
end


--------------------------------------------------------------------------------
-- processing
--------------------------------------------------------------------------------

function slice_it()

  local nSlices = tonumber(nSlices)
  local nSliceSize = 0
  if(nSlices==nil) then
    renoise.app():show_error("Invalid number of slices!")
    return
  end

  local insSel = renoise.song().selected_instrument
  local nSamples = table.getn(insSel.samples)
  local smpSel = renoise.song().selected_sample
  local nSmpSel = renoise.song().selected_sample_index
  local smpBuffSel = smpSel.sample_buffer
  local nSmpSize = smpSel.sample_buffer.number_of_frames
  
  if(nSlicingMode == SLICING_MODE_SLICES) then
    nSliceSize = nSmpSize / nSlices
  elseif(nSlicingMode == SLICING_MODE_SLICES_SECS) then
    if(nSlices>0) then
      nSliceSize = smpBuffSel.sample_rate * nSlices
      if(nSliceSize>0) then
        nSlices = math.ceil(nSmpSize / (nSliceSize))
      else
        nSlices = 0
      end
    end
  elseif(nSlicingMode == SLICING_MODE_SLICES_BPM) then
    if(nSlices>0) then
      nSliceSize = (60 / nSlices) * smpBuffSel.sample_rate
      if(nSliceSize>0) then
        nSlices = math.ceil(nSmpSize / (nSliceSize))
      end
    end    
  end

  if(nSlices <= 1 or nSliceSize <=1) then 
    renoise.app():show_error("Invalid number of slices!")
    return
  end
  
  local nSyncLines = tonumber(nSyncLines)
  local arrSplit = {}
  
  if(nSyncLines == nil or nSyncLines <= 1) then 
    renoise.app():show_error("Invalid number of sync lines!")
    return
  end

  local nBaseNote = smpSel.base_note
  
  if(bDoMapping) then
    local nCont
    for nCont = 1, 120 do
      arrSplit[nCont] = 1
    end
  end
  
  --calculate how many slices there  have to be
  
  local nFrame = 1  
  
  for nSlice = 1, nSlices do
  
    local smpNew = insSel.insert_sample_at(insSel,nSamples+1)
    nSamples = nSamples + 1
    local smpBuffNew = smpNew.sample_buffer
	
    if (nSlice == nSlices) then
      --the last slice will contain any other remaining piece of the source sample (should be a bunch of bytes)
      nSliceSize = nSmpSize - nFrame
    end
    
    if (smpBuffNew:create_sample_data(smpBuffSel.sample_rate, 
      smpBuffSel.bit_depth, smpBuffSel.number_of_channels, nSliceSize)) 
    then
	
      local nChan, nFrameNew
      for nFrameNew = 1, smpBuffNew.number_of_frames do
        for nChan = 1, smpBuffSel.number_of_channels do
          local lValue = 0
          if(nFrame<=nSmpSize) then
            lValue = smpBuffSel:sample_data(nChan,nFrame)
          end
          smpBuffNew:set_sample_data(nChan,nFrameNew,lValue)
        end
        nFrame = nFrame + 1
      end
      
      if(bDoMapping) then
        smpNew.base_note = nBaseNote + nSlice-1
        arrSplit[smpNew.base_note+1] = nSlice
      end
      
      smpNew.beat_sync_enabled = bDoSync and (nSyncLines>0)
      if(smpNew.beat_sync_enabled) then
        smpNew.beat_sync_lines = nSyncLines
      end
      
      if(bDoLoop) then
        smpNew.loop_mode = nLoopMode
      else
        smpNew.loop_mode = renoise.Sample.LOOP_MODE_OFF
      end
      if (bDoAutoseek) then
        smpNew.autoseek = bDoAutoseek
      end
       
      smpNew.name = smpSel.name .. " slice" .. tostring(nSlice)
      nSlice = nSlice + 1
      smpBuffNew:finalize_sample_data_changes()
      
    else
	
      renoise.app():show_error("Cannot create new sample! Aborting..")
      renoise.song():undo()
      return
	  
    end
		
  end
  
  insSel.delete_sample_at(insSel,nSmpSel)
  
  if(bDoMapping)then
    insSel.split_map = arrSplit
  end
end


