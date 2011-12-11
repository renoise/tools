--[[============================================================================
main.lua
============================================================================]]--

-- internal state

local dialog = nil
local vb = nil

local tempo = nil
local timetable = table.create()
local timetable_filled = false
local counter = 0
local last_clock = 0


-- options (tool preferences)

local options = renoise.Document.create("ScriptingToolPreferences") {
  sensitivity = 4,
  round_bpm = true,
  auto_save_bpm = true,
  tempo_track = false,
  sensitivity_min = 2,
  sensitivity_max = 10,
}


--------------------------------------------------------------------------------
-- tool setup
--------------------------------------------------------------------------------

renoise.tool().preferences = options

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:TempoTap...",
  invoke = function() show_dialog() end
}

local keybinding = {
  name = "Global:Tools:Show/Hide TempoTap",
  invoke = function() 
    if (dialog and dialog.visible) then
      dialog:close()      
    else
      show_dialog()
    end
  end
}

if (not renoise.tool():has_keybinding(keybinding.name)) then
  renoise.tool():add_keybinding(keybinding)
end

--------------------------------------------------------------------------------
-- helper functions
--------------------------------------------------------------------------------

local function resize_table(t, length)
  assert(type(t) == "table")
  assert(length > 0)

  while (#t < length) do
    table.insert(t, t[#t] or 0)
  end

  while (#t > length) do 
    table.remove(t, 1) 
  end
end


--------------------------------------------------------------------------------

-- set_text

local function set_text(str)
  renoise.app():show_status("[TempoTap] " .. str)
  if (vb) then
    vb.views.bpm_text.text = str    
  end    
end


--------------------------------------------------------------------------------
-- processing
--------------------------------------------------------------------------------

-- get_tempo_track

local function get_tempo_track()
  -- find an existing tempo track (a dedicated send track)
  -- optionally, use the master track
  for k,t in ripairs(renoise.song().tracks) do
    if (t.name == "Tempo") then
      return k
    end
  end
  
  -- find master track
  local master_track = nil
  for k,t in ripairs(renoise.song().tracks) do  
    if (t.type == renoise.Track.TRACK_TYPE_MASTER) then    
      master_track = k
    end
  end
    
  -- create a new tempo track      
  local index = master_track + 1
  local t = renoise.song():insert_track_at(index)
  t.name = "Tempo"
  return index 
end


--------------------------------------------------------------------------------

-- insert_bpm

local function insert_bpm(bpm)
  if (bpm > 255) then 
     renoise.app():show_status( 
       ("[TempoTap] Error: tempos higher than 255 BPM can not be written to the Tempo Track, tapped tempo was: %d"):format(bpm)
     )
     return
  end

  local song = renoise.song()
  
  -- get the tempo track
  local tempo_track = get_tempo_track()  
  
  -- get the sequence position and line number  
  local seq_index = song.transport.playback_pos.sequence
  local line_index = song.transport.playback_pos.line  
  
  -- convert current sequence_pos to pattern_index
  local pattern_index = song.sequencer.pattern_sequence[seq_index]  
 
  local fx = song.patterns[pattern_index].
    tracks[tempo_track].
    lines[line_index].
    effect_columns[1]
  
  fx.number_string = "ZT"
  fx.amount_value = bpm    
  
  set_text(string.format("Tapped tempo (%d BPM) written to Tempo Track.", bpm)) 
end


--------------------------------------------------------------------------------

-- save_bpm

local function save_bpm(bpm)
  if (bpm >= 32 and bpm <= 999) then
    renoise.song().transport.bpm = bpm      
    set_text(string.format("Playback tempo set to %d BPM.", bpm)) 
    if (options.tempo_track.value) then
      insert_bpm(bpm)      
    end    
  end
end


--------------------------------------------------------------------------------

-- reset

local reset = nil

reset = function()

  if (renoise.tool():has_timer(reset)) then
    renoise.tool():remove_timer(reset)    
  end

  counter = 1
  timetable_filled = false

  while (#timetable > 1) do 
    timetable:remove(1) 
  end    

  set_text("Tap counter has been reset.")  
  
end
  
  
--------------------------------------------------------------------------------

-- tap

local function tap()
  
  local function get_average(tb)
    return (tb[#tb] - tb[1]) / (#tb - 1)
  end
  
  local function get_bpm(dt)
    -- 60 BPM => 1 beat per sec         
    return (60 / dt)
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
    
  -- refresh reset timer
  if (renoise.tool():has_timer(reset)) then
    renoise.tool():remove_timer(reset)    
  end
  renoise.tool():add_timer(reset, 2000)
  
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
    
    set_text(string.format("Tempo: ".. 
      field .. " BPM [%d/%d]", tempo, counter, #timetable))
    
    if (counter == 1 and options.auto_save_bpm.value) then 
      save_bpm(tempo)
    end  

  else 
    set_text(string.
      format("Keep tapping [%d/%d]...", counter, 
        options.sensitivity.value))
  end
end  


--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

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
  local DEFAULT_BUTTON_HEIGHT =
    renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT   
  local TEXT_ROW_WIDTH = 100
  local WIDE = 180

  local dialog_title = "TempoTap"
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
      midi_mapping = "TempoTap:Tap [Trigger]",
      pressed = function()
        tap()
      end
    },
    
    vb:text {
      width = "100%",
      id = "bpm_text",
      text = "Tap a key to start",
      font = "bold"
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
          id = "sensitivity",          
          bind = options.sensitivity,
          min = options.sensitivity_min.value,
          max = options.sensitivity_max.value,
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
        }
      },
        
      vb:row {
        vb:text {
          width = TEXT_ROW_WIDTH,
          text = "Write Tempo Track"
        },
        vb:checkbox {
          bind = options.tempo_track, 
        }
      } 
    },      
    
    vb:horizontal_aligner {
      mode = "justify",
      margin = 4,
      vb:button {
        text = "Save Tempo",        
        midi_mapping = "TempoTap:Save Tempo [Trigger]",
        tooltip = "Save Playback Tempo, and write to Tempo Track if enabled (Return)",        
        height = DEFAULT_BUTTON_HEIGHT*2,
        notifier = function()       
          if (tempo) then
            save_bpm(tempo)
          end
        end
      },
      vb:button {
        text = "Reset Taps",        
        midi_mapping = "TempoTap:Reset [Trigger]",
        tooltip = "Start over with tapping (Del)",
        height = DEFAULT_BUTTON_HEIGHT*2,
        notifier = function()                 
          reset()          
        end
      }
    }
  }
  
  
  -- key_handler
  
  local function key_handler(dialog, key)
    -- ignore held keys
    if (key.repeated) then
      return
    end
    
    if (key.name == "esc") then
      dialog:close()
    
    elseif (key.name == "return") then
      if (tempo) then
        save_bpm(tempo)
      end
    
    elseif (key.name == "del") then      
        reset()      
      
    else    
      tap()   
    end 
    
  end
  
  
  -- show
  
  dialog = renoise.app():show_custom_dialog(
    dialog_title, dialog_content, key_handler)

end


--------------------------------------------------------------------------------
-- Custom MIDI Mapping
--------------------------------------------------------------------------------

renoise.tool():add_midi_mapping{
  name = "TempoTap:Show/Hide TempoTap [Trigger]",
  invoke = function(message)
    if (message:is_trigger()) then      
      if (dialog and dialog.visible) then
        dialog:close()  
      else
        show_dialog()
      end
    end
  end
}

renoise.tool():add_midi_mapping{
  name = "TempoTap:Tap [Trigger]",
  invoke = function(message)
    if (message:is_trigger()) then      
      tap()      
    end
  end
}

renoise.tool():add_midi_mapping{
  name = "TempoTap:Save Tempo [Trigger]",
  invoke = function(message)
    if (message:is_trigger() and tempo) then             
      save_bpm(tempo)          
    end
  end
}

renoise.tool():add_midi_mapping{
  name = "TempoTap:Reset [Trigger]",
  invoke = function(message)
    if (message:is_trigger()) then      
      reset()      
    end
  end
}

--------------------------------------------------------------------------------
-- Notifiers
--------------------------------------------------------------------------------

options.sensitivity:add_notifier(function()
  -- keep timetable in sync with the sensitivity
  resize_table(timetable, options.sensitivity.value)
  timetable_filled = false
  counter = 1
end)

