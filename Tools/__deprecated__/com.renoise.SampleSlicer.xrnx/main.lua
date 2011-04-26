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
local rSliceSize = 0
local nShownSlice = 0
local nSlicingMode = SLICING_MODE_SLICES

local insSel = nil
local smpSel = nil
local nSmpSel = 0
local smpBuffSel = nil
local rSmpSize = 0

local bDoMapping = true
local arrSplit = {} -- array used for note mapping
local bDoSync = true
local nSyncLines = 0
local bDoLoop = false
local nLoopMode = LOOP_MODE_FORWARD
local bDoAutoseek = false
local rSampleSelStart = 0
local rSampleSelEnd = 0

local rLastIdleTime = 0.0
local rSliceShowInterval = 1

local dialog = nil
local vb = nil
local bDialogOpened = false
local bDoneSlicing = false

local DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT

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
  invoke = function(repeated)
    if not repeated then 
      show_dialog() 
    end
  end
}

--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

function show_dialog()

  smpSel = renoise.song().selected_sample
  
  if smpSel == nil or not smpSel.sample_buffer.has_sample_data then
    renoise.app():show_error("No sample has been selected!")
    return
  end
  
  nSyncLines = smpSel.beat_sync_lines
  bDoSync = smpSel.beat_sync_enabled
  bDoLoop = smpSel.loop_mode > renoise.Sample.LOOP_MODE_OFF
  nLoopMode = smpSel.loop_mode
  bDoAutoseek = smpSel.autoseek
  rSampleSelStart = smpSel.sample_buffer.selection_start
  rSampleSelEnd = smpSel.sample_buffer.selection_end

  vb = renoise.ViewBuilder()

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
        nShownSlice = 0
        run_slice_show()
      end,
      tooltip = "Select the slicing mode."
    },
    
    vb:textfield {
      id = 'nSlices',
      width = 80,
      tooltip = [[insert the number of slices to create]],
      value = tostring(nSlices),
      notifier = function(value)
        nSlices = tonumber(value)
        nShownSlice = 0
        run_slice_show()
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
        nSyncLines = tonumber(value)
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
  
  local row6 = vb:row {
    vb:button {
      text = "Slice!",
      tooltip = "Split the selected sample into slices",
      height = DIALOG_BUTTON_HEIGHT,
      width = vb.views["nSlices"].width,
      notifier = function()
        slice_it(false)
        stop_slice_show()
      end
    },
    vb:button {
      text = "Cancel",
      tooltip = "Close dialog and abort operation",
      height = DIALOG_BUTTON_HEIGHT,
      width = vb.views["nSlices"].width,	  
      notifier = function()
        stop_slice_show()
        dialog:close()        
      end
    }    	
  }
  
  run_slice_show()
  bDialogOpened = true
  nShownSlice = 0
  
  dialog = renoise.app():show_custom_dialog  (
    "Auto Slicer",
    vb:column{
      margin = DEFAULT_DIALOG_MARGIN,
      spacing = DEFAULT_CONTROL_SPACING,
      row1,
      row2,
      row3,
      row4,
      row5,
      row6,
      vb:space { }
    }--,
    --{'Slice!','Cancel'}
  )
  
  if dialog == 'Slice!' then
    slice_it()
  end

  
end


--------------------------------------------------------------------------------
-- calculates how much slices there will be according to the selected mode
--------------------------------------------------------------------------------

function get_number_of_slices()

  if smpSel == nil then
    return false
  end

  nSmpSel = renoise.song().selected_sample_index
  smpBuffSel = smpSel.sample_buffer
  rSmpSize = smpSel.sample_buffer.number_of_frames

  if(nSlicingMode == SLICING_MODE_SLICES) then
  
    rSliceSize = rSmpSize / nSlices
  
  elseif(nSlicingMode == SLICING_MODE_SLICES_SECS) then
  
    local nSecs = tonumber(vb.views["nSlices"].value)
  
    if(nSecs>0) then
  
      rSliceSize = smpBuffSel.sample_rate * nSecs
    
      if(rSliceSize>0) then	  
        nSlices = math.ceil(rSmpSize / rSliceSize)
      else	  
        nSlices = 0		
      end
    
    end
  
  elseif(nSlicingMode == SLICING_MODE_SLICES_BPM) then
  
    local rBPM = tonumber(vb.views["nSlices"].value)
  
    if(rBPM>0) then
      rSliceSize = (60 / rBPM) * smpBuffSel.sample_rate
      if(rSliceSize>0) then
        nSlices = math.ceil(rSmpSize / rSliceSize)
    else
      nSlices = 0
      end
    end    
  
  end

  if(nSlices <= 1 or rSliceSize <=1) then 
  
    return false
  
  end
  
  local nSyncLines = tonumber(nSyncLines)
  
  if bDoSync and (nSyncLines == nil or nSyncLines < 1) then 

  stop_slice_show()  
    renoise.app():show_error("Invalid number of sync lines!")
    return false
  
  end
  
  return true
  
end


--------------------------------------------------------------------------------
-- processing
--------------------------------------------------------------------------------

function slice_it(bSliceShow)

  nSlices = tonumber(nSlices)
  rSliceSize = 0
  if(nSlices==nil) then
    renoise.app():show_error("Invalid number of slices!")
    stop_slice_show()
    return
  end

  insSel = renoise.song().selected_instrument
  local nSamples = table.getn(insSel.samples)
  smpSel = renoise.song().selected_sample
  
  if insSel == nil or smpSel == nil then
    return
  end

  if not get_number_of_slices() then
    return
  end

  if(nSlices==nil or nSlices < 2) then
    renoise.app():show_error("Invalid number of slices!")	
    stop_slice_show()
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
  
  if (bSliceShow) then
  
    if (tonumber(nSlices) > 1) and (rSliceSize > 2) then

      if (nShownSlice + 1 > nSlices) then
        nShownSlice = 1
      else
        nShownSlice = nShownSlice + 1
      end
  
      smpSel = renoise.song().selected_sample
    
      if (smpSel ~= nil) then
    
        smpBuffSel = smpSel.sample_buffer
      
        if (smpBuffSel ~= nil and smpBuffSel.has_sample_data) then
      
          rSmpSize = smpBuffSel.number_of_frames
  
            local nSelStart = 1 + (nShownSlice - 1) * rSliceSize
            -- min() is used to avoid rounding errors which could overcome buffer size
            smpBuffSel.selection_range = {nSelStart,math.min(rSmpSize,nSelStart + rSliceSize)}
              
          end
    
      end
  
    end
  
  else
  
  for nSlice = 1, nSlices do
  
      local smpNew = insSel.insert_sample_at(insSel,nSamples+1)
      nSamples = nSamples + 1
      local smpBuffNew = smpNew.sample_buffer

      if (nSlice == nSlices) then
        --the last slice will contain any other remaining piece of the source sample (should be a bunch of bytes)
        rSliceSize = rSmpSize - nFrame
      end
    
      if (smpBuffNew:create_sample_data(smpBuffSel.sample_rate, 
        smpBuffSel.bit_depth, smpBuffSel.number_of_channels, rSliceSize)) 
      then
  
        local nChan, nFrameNew
        for nFrameNew = 1, smpBuffNew.number_of_frames do
          for nChan = 1, smpBuffSel.number_of_channels do
            local lValue = 0
            if(nFrame<=rSmpSize) then
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
  
  end
  
  if not bSliceShow then
  
    insSel.delete_sample_at(insSel,nSmpSel)
  
    if(bDoMapping)then
      insSel.split_map = arrSplit
    end
  
    bDoneSlicing = true

  end	

  
  
end

--------------------------------------------------------------------------------

-- start showing of slices into the sample view

function run_slice_show()
  if not (renoise.tool().app_idle_observable:has_notifier(slice_show)) then
    renoise.tool().app_idle_observable:add_notifier(slice_show)	
  end
end

--------------------------------------------------------------------------------

-- stop showing of slices into the sample view

function stop_slice_show()
  if (renoise.tool().app_idle_observable:has_notifier(slice_show)) then  
    renoise.tool().app_idle_observable:remove_notifier(slice_show)
    if not bDoneSlicing then
      -- no slicing has been actually done. reset selection
      if smpSel and smpSel.sample_buffer.selection_start >= smpSel.sample_buffer.selection_end then
        smpSel.sample_buffer.selection_range = {rSampleSelStart, rSampleSelEnd}
      end
    end
  end
  
  smpSel = nil
  insSel = nil
  
end

--------------------------------------------------------------------------------

function slice_show()

  if (bDialogOpened and not dialog or not dialog.visible) then
    stop_slice_show()
    return
  end

  -- allows for timed execution
  if (os.clock() - rLastIdleTime < rSliceShowInterval) then
    return
  end
  
  get_number_of_slices()

  slice_it(true)
  
  rLastIdleTime = os.clock()

end

