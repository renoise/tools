--[[----------------------------------------------------------------------------
main.lua
----------------------------------------------------------------------------]]--

-- TODO: calc, show steadiness and deviation
  

-- internal state

local dialog = nil
local vb = nil

local tempo = nil
local timetable = table.create()
local timetable_filled = false
local counter = 0
local last_clock = 0


-- options (tool preferences)

local options = renoise.Document.create {
  sensitivity = 4,
  round_bpm = true,
  auto_save_bpm = true
}

-- notifiers

options.sensitivity:add_notifier(function()
  -- keep timetable in sync with the sensitivity
  resize_table(timetable, options.sensitivity.value)
  timetable_filled = false
  counter = 1
end)

 
-----------------------------------------------------------------------------

-- tool setup

renoise.tool().preferences = options

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Tempo Tap...",
  invoke = function() 
    show_dialog() 
  end
}


-----------------------------------------------------------------------------

-- helper functions

function resize_table(t, length)
  assert(type(t) == "table")
  assert(length > 0)

  while (#t < length) do
    table.insert(t, t[#t] or 0)
  end

  while (#t > length) do 
    table.remove(t, 1) 
  end
end


------------------------------------------------------------------------------

-- save_bpm

function save_bpm(bpm)
  if (bpm >= 32 and bpm <= 999) then
    renoise.song().transport.bpm = bpm
  end
end


-- tap

function tap()
  
  local function get_average(tb)
    return (tb[#tb] - tb[1]) / (#tb - 1)
  end
  
  local function get_bpm(dt)
    -- 60 BPM => 1 beat per sec         
    return (60 / dt)
  end
  
  local function reset()
    counter = 1
    timetable_filled = false
    while (#timetable > 1) do 
      timetable:remove(1) 
    end
  end
  
  local function increase_counter()  
    counter = counter + 1
    if (counter > options.sensitivity.value) then
      timetable_filled = true
      counter = 1
    end  
  end
  
  increase_counter()
  
  local clock = os.clock()
  timetable:insert(clock) 
  
  if (last_clock > 0 and (clock - last_clock) > 2) then
    -- reset after 2 sec idle
    reset()
  end
  
  last_clock = clock
  
  if (#timetable > options.sensitivity.value) then
    timetable:remove(1)
  end
  
  if (timetable_filled) then
    tempo = get_bpm(get_average(timetable))
    
    local field = "%.2f"
  
    if (options.round_bpm.value) then
      tempo = math.floor(tempo + 0.5)
      field = "%d"
    end  
    
    vb.views.bpm_text.text = string.format("Tempo: ".. 
      field .. " BPM [%d/%d]", tempo, counter, #timetable)
    
    if (counter == 1 and options.auto_save_bpm.value) then 
      save_bpm(tempo)
    end  

  else 
    vb.views.bpm_text.text = string.
      format("Keep tapping [%d/%d]...", counter, 
        options.sensitivity.value)
  end
end  


-----------------------------------------------------------------------------

function show_dialog()

  if dialog and dialog.visible then
    dialog:show()
    return
  end

  vb = renoise.ViewBuilder()

  local DEFAULT_DIALOG_MARGIN = 
    renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local DEFAULT_CONTROL_SPACING = 
    renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local TEXT_ROW_WIDTH = 100
  local WIDE = 180

  local dialog_title = "Tempo Tap"
  local dialog_buttons = {"Close"};

  
  -- dialog content 
  
  local dialog_content = vb:column {
    margin = DEFAULT_DIALOG_MARGIN,
    spacing = DEFAULT_CONTROL_SPACING,
    uniform = true,

    vb:button {
      text = "TAP",
      width = WIDE,
      height = 80,
      pressed = function()       
        tap()
      end
    },
    
    vb:column {
       margin = DEFAULT_DIALOG_MARGIN,
       spacing = DEFAULT_CONTROL_SPACING,

       vb:row {
        vb:text {
          width = TEXT_ROW_WIDTH,
          text = "Sensitivity"
        },
        vb:valuebox {
          bind = options.sensitivity,
          min = 2,
          max = 10,
        },
      },
      
      vb:row {
        vb:text {
          width = TEXT_ROW_WIDTH,
          text = "Round BPM"
        },
        vb:checkbox {
          bind = options.round_bpm, 
        },
      },       
    
      vb:row {
        vb:text {
          width = TEXT_ROW_WIDTH,
          text = "Auto-Save BPM"
        },
        vb:checkbox {
          bind = options.auto_save_bpm, 
        },
      }, 
    },      
    
    vb:text {
      width = "100%",
      id = "bpm_text",
      text = "Tap a key to start"        
    },
    
    vb:row {
      vb:button {
        text = "Save BPM",
        tooltip = "Set Player Tempo (Return)",
        notifier = function()       
          if (tempo) then
            save_bpm(tempo)
          end
        end
      }
    }
  }
  
  
  -- key_handler
  
  local function key_handler(dialog, mod_string, key_string)
    if (key_string == "esc") then
      dialog:close()
    
    elseif (key_string == "return") then
      if (tempo) then
        save_bpm(tempo)
      end
    
    else    
      tap()   
    end 
  end
  
  
  -- show
  
  dialog = renoise.app():show_custom_dialog(
    dialog_title, dialog_content, key_handler)

end


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--
