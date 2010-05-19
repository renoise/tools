--[[----------------------------------------------------------------------------
main.lua
----------------------------------------------------------------------------]]--

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Tempo Tap...",
  invoke = function() 
    show_dialog() 
  end
}

------------------------------------------------------------------------------

local vb = nil
local tempo = 128
local timetable = table.create()
local sensitivity = 4
local counter = 0
local round = true
local ready = false
local last_clock = 0
local auto = true

local function save_bpm(bpm)
  if (bpm >= 32 and bpm <= 999) then
    renoise.song().transport.bpm = bpm
  end
end

local function resize_table(t,length)
  assert(type(t) == "table")
  local size = #t
  if length > #t then  -- grow
    local last_value = t[#t]
    while #t ~= length do
       t:insert(last_value);
    end
  elseif length < #t then  -- shrink
    while #t ~= length do 
      t:remove(1) 
    end
  end
end

local function tap()
  
  local function get_average(tb)
    return (tb[#tb] - tb[1]) / (#tb-1)
  end
  
  local function get_bpm(dt)
   return 60 / dt
  end
  
  local function set_steadiness()
    local bpms = {}
    local dt = nil
  
    for i=#timetable,2,-1 do
      dt = timetable[i] - timetable[i - 1]
      table.insert(bpms, get_bpm(dt)) 
    end
    
    -- TODO calculate deviation
    local deviation = tempo - bpms[#bpms]
    -- vb.views.steadiness.value = math.log(math.abs(deviation))
  end
  
  local function reset()
    counter = 1
    ready = false
    while #timetable == 1 do 
      timetable:remove(1) 
    end
  end
  
  local function increase_counter()  
    counter = counter + 1
    if counter > sensitivity then
      timetable:remove(1)
      ready = true
      counter = 1
    end  
  end
  
  increase_counter()
  local clock = os.clock()
  timetable:insert(clock) 
  
  -- reset after 2 sec idle
  if last_clock > 0 and (clock - last_clock) > 2 then
    reset()
  end
  
  last_clock = clock
  
  if (#timetable > sensitivity) then
    timetable:remove(1)
  end
  if ready then
    local field = "%.2f"
    local dt = get_average(timetable)
    -- 60 BPM => 1 beat per sec         
    tempo = get_bpm(dt)
    if round then
      tempo = math.floor(tempo+0.5)
      field = "%d"
    end  
    vb.views.bpm_text.text = string.
      format("Tempo: ".. field .. " BPM [%d/%d]", 
        tempo, counter, #timetable)
    if counter == 1 and auto then 
      save_bpm(tempo)
      -- set_steadiness()
    end  
  else 
    vb.views.bpm_text.text = string.
      format("Keep tapping [%d/%d]...", counter, sensitivity)
  end
end  
  
-----------------------------------------------------------------------------


local dialog = nil
  
function show_dialog()

  tempo = renoise.song().transport.bpm
  
  local function set_rounding(value)
    round = value
  end
 
  local function set_sensitivity(value)
    sensitivity = value
    resize_table(timetable, value)
    ready = false
    counter = 1
  end
  
  local function key_handler(dialog, mod_string, key_string)
    if (key_string == "esc") then
      dialog:close()
    elseif (key_string == "return") then
      save_bpm(tempo)
    else    
      tap()   
    end 
  end
  
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

  local dialog_content = vb:column {
    margin = DEFAULT_DIALOG_MARGIN,
    spacing = DEFAULT_CONTROL_SPACING,
    uniform = true,

    vb:button {
      text = "TAP",
      width = WIDE,
      height = 80,
      notifier = function()       
        tap()
      end
    },
    
    vb:column {
       style = "invisible",
       margin = DEFAULT_DIALOG_MARGIN,
       spacing = DEFAULT_CONTROL_SPACING,
       vb:row {
          vb:text {
            width = TEXT_ROW_WIDTH,
            text = "Sensitivity"
          },
          vb:valuebox {
            value = sensitivity,
            min = 2,
            max = 10,
            notifier = function(value)
              set_sensitivity(value)
            end
          },
        },
        
        vb:row {
          vb:text {
            width = TEXT_ROW_WIDTH,
            text = "Round BPM"
          },
          vb:checkbox {
            value = round, 
            notifier = function(value)
              set_rounding(value)
            end
          },
        },       
      
        vb:row {
          vb:text {
            width = TEXT_ROW_WIDTH,
            text = "Auto-Save BPM"
          },
          vb:checkbox {
            value = auto, 
            notifier = function(value)
              auto = value
            end
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
            save_bpm(tempo)
          end
        }
      }
  }
  
  dialog = renoise.app():show_custom_dialog(
    dialog_title, dialog_content, key_handler)

end

--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--
