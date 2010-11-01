--[[============================================================================
main.lua
============================================================================]]--

--[[

This tool shows how to slice up a function which takes a lot of processing 
time into multiple calls via Lua coroutines. 

This mainly is useful to:
- show the current progress of your processing function
- allow users to abort the progress at any time
- avoids that Renoise asks to kill your process function cause it assumes 
  its frozen when taking more than 10 seconds

Please have a look at "process_slicer.lua" for more info. This file basically
just shows how to create a GUI for the ProcessSlicer class.

]]

require "process_slicer"


--------------------------------------------------------------------------------

-- main: dummy example for sliced working function which needs a lot of time

function main(update_progress_func)
  local i = 0
  
  local num_iterations = 1000
  for j=1,num_iterations do
    i = i + 1
   
    -- waste time (your tool would do something useful here)
    for k=1,1000000 do
      local a = 12/12*3434
    end
    
    -- show the progress in the GUI
    update_progress_func(i / num_iterations)
    
    -- and periodically give time back to renoise
    coroutine.yield()
  end  
end


--------------------------------------------------------------------------------

-- creates a dialog which starts stops and visualizes a sliced progress

local function create_gui()

  local dialog, process
  local vb = renoise.ViewBuilder()

  -- Note: we allow multiple dialogs and processes in this example. If you 
  -- only want one dialog to be shown and only one process running, make 
  -- 'dialog' and 'process' global, and check if if the dialog is visible 
  -- here. If your dialog and viewbuilder is global, you also don't have to 
  -- pass an "update_progress_func" to the processing function, but can call 
  -- it directly.
  
  ----- process GUI functions (callbacks): 
  
  local function update_progress(progress)
    if (not dialog or not dialog.visible) then
      -- abort processing when the dialog was closed
      process:stop()
      return
    end
    
    -- else update the progress text
    if (progress == 1.0) then
      vb.views.start_button.text = "Start"
      vb.views.progress_text.text = "Done!"
    else
      vb.views.progress_text.text = string.format(
        "Working hard (%d%% done)...", progress * 100)
    end
  end

  local function start_stop_process()
    if (not process or not process:running()) then
      -- start running
      vb.views.start_button.text = "Stop"
      process = ProcessSlicer(main, update_progress)
      process:start()
      
    elseif (process and process:running()) then
      -- stop running
      vb.views.start_button.text = "Start"
      vb.views.progress_text.text = "Process Aborted!"
      process:stop()
    end
  end


  ---- process GUI

  local DEFAULT_DIALOG_MARGIN = 
    renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  
  local DEFAULT_CONTROL_SPACING = 
    renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  
  local DEFAULT_DIALOG_BUTTON_HEIGHT = 
    renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
  
  local dialog_content = vb:column {
    uniform = false,
    margin = DEFAULT_DIALOG_MARGIN,
    spacing = DEFAULT_CONTROL_SPACING,

    -- (add some content here)
    
    vb:text {
      id = "progress_text",
      text = "Hit 'Start' to begin a sliced process:"
    },

    vb:button {
      id = "start_button",
      text = "Start",
      height = DEFAULT_DIALOG_BUTTON_HEIGHT,
      width = 80,
      notifier = start_stop_process
    }
  }

  dialog = renoise.app():show_custom_dialog(
    "Sliced Process Example", dialog_content)
end


--------------------------------------------------------------------------------

renoise.tool():add_menu_entry{
  name = "Main Menu:Tools:Example Tool Sliced Process...",
  invoke = function()
    create_gui()
  end
}


