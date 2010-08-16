--[[============================================================================
com.renoise.PatternRotate.xrnx/main.lua
============================================================================]]--

-- modes

local MODE_WHOLE_PATTERN = 1
local MODE_TRACK_IN_PATTERN = 2
local MODE_SELECTION_IN_PATTERN = 3

local mode_names = {
  "Whole Pattern",
  "Track in Pattern",
  "Selection in Pattern"
}


--------------------------------------------------------------------------------
-- preferences
--------------------------------------------------------------------------------

local preferences = renoise.Document.create {
  mode = MODE_WHOLE_PATTERN,
  amount = 1,
  automation = true
}


--------------------------------------------------------------------------------
-- processing helpers
--------------------------------------------------------------------------------

-- moves and wraps an index into the specified range

local function rotate_index(index, amount, range_start, range_end)
  assert(index >= 0, "Internal error: unexpected rotate index")
  assert(range_start <= range_end, "Internal error: unexpected rotate range")
  
  local range = range_end - range_start + 1
  amount = amount % range

  return (index - range_start + amount + range) % range + range_start
end


-- queries the selection range start and end lines

local function selection_line_range()

  local line_start, line_end
  
  local iter = renoise.song().pattern_iterator:lines_in_pattern(
    renoise.song().selected_pattern_index)
  
  for pos,line in iter do
    for _,note_column in pairs(line.note_columns) do
      if (note_column.is_selected) then
        line_start = line_start or pos.line
        line_end = line_end and math.max(line_end, pos.line) or pos.line
      end
    end
    
    for _,effect_column in pairs(line.effect_columns) do
      if (effect_column.is_selected) then
        line_start = line_start or pos.line
        line_end = line_end and math.max(line_end, pos.line) or pos.line
      end
    end
  end
  
  return line_start, line_end
end


--------------------------------------------------------------------------------
-- processing
--------------------------------------------------------------------------------

-- rotate current pattern by the given amount in the given range

function rotate(amount, mode)
  
  assert(type(amount) == "number", 
    "Internal Error: Unexpected amount argument")
  assert(type(mode) == "number" and mode >= 1 and mode <= #mode_names, 
    "Internal Error: Unexpected mode argument")
  
  local song = renoise.song()
  
  local pattern = song.selected_pattern
  local pattern_index = song.selected_pattern_index
  
  
  -- create a scratch pattern 

  local temp_pattern_index = song.sequencer:insert_new_pattern_at(
    #song.sequencer.pattern_sequence)
  
  local temp_pattern = song.patterns[temp_pattern_index]

  if (not temp_pattern.is_empty) then 
    -- hackaround for a bug in b4: 
    -- insert_new_pattern_at returns the previous pattern
    temp_pattern_index = temp_pattern_index + 1
    temp_pattern = song.patterns[temp_pattern_index]
  end
  
  
  -- collect to be processed tracks

  local tracks_to_process = nil
  
  if (mode == MODE_WHOLE_PATTERN) then
    tracks_to_process = pattern.tracks
  elseif (mode == MODE_SELECTION_IN_PATTERN) then
    tracks_to_process = pattern.tracks 
  elseif (mode == MODE_TRACK_IN_PATTERN) then
    tracks_to_process = {
      [song.selected_track_index] = song.selected_pattern_track
    }
  else
    error("Internal error: unexpected rotate range mode")
  end


  -- get the selection line range

  local selection_start, selection_end, selection_range
  
  if (mode == MODE_SELECTION_IN_PATTERN) then
    selection_start, selection_end = selection_line_range()
  
    if (selection_start and selection_end) then
      selection_range = selection_end - selection_start + 1
    end
  end
        
        
  -- rotate track by track
          
  for track_index,track in pairs(tracks_to_process) do
    local temp_track = temp_pattern.tracks[track_index]
    
    -- copy the existing lines to the scratch track
    -- pattern lines are references. can't move them in-place
    temp_track:copy_from(track)
    
    -- handle selection mode seperately
    if (mode == MODE_SELECTION_IN_PATTERN) then
      if (selection_range) then

        -- paste selected columns back to the new pos
        for line_index = selection_start,selection_end do
          
          local dest_line_index = rotate_index(line_index, 
            amount, selection_start, selection_end)

          local src_line = temp_track:line(line_index)
          local dest_line = track:line(dest_line_index)
          
          for index,note_column in pairs(src_line.note_columns) do
            local dest_note_column = dest_line.note_columns[index]
            
            if (dest_note_column.is_selected) then
              dest_note_column:copy_from(note_column)
            end
          end
          
          for index,effect_column in pairs(src_line.effect_columns) do
            local dest_effect_column = dest_line.effect_columns[index]

            if (dest_effect_column.is_selected) then
              dest_effect_column:copy_from(effect_column)
            end
          end
        end
      end
      
    else
      -- paste lines from the temp track to the new pos
      local number_of_lines = pattern.number_of_lines
      
      for line_index = 1,number_of_lines do
        
        local dest_line_index = rotate_index(line_index, 
          amount, 1, number_of_lines)
        
        local src_line = temp_track:line(line_index)
        local dest_line = track:line(dest_line_index)
        
        dest_line:copy_from(src_line)
      end
      
      -- rotate automation in place
      if (preferences.automation.value == true) then
        for _,automation in pairs(track.automation) do
          local rotated_points = table.create(
            table.rcopy(automation.points))
          
          for _,point in pairs(rotated_points) do
            point.time = rotate_index(point.time, 
              amount, 1, number_of_lines)
          end
          
          rotated_points:sort(function(a,b) 
            return (a.time < b.time) 
          end)
          
          automation.points = rotated_points
        end
      end
    end
  end
  
  
  -- delete the scratch pattern
  
  temp_pattern:clear() -- empty patterns will be completely removed
  song.sequencer:delete_sequence_at(#song.sequencer.pattern_sequence)
end


--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local dialog = nil


-- show_dialog

function show_dialog()

  if (dialog and dialog.visible) then
    -- bring an existing dialog to front
    dialog:show() 
    return
  end
  
  
  --  consts

  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING

  local BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
  local BUTTON_WIDTH = 64
  local POPUP_WIDTH = 2*BUTTON_WIDTH
  
  local vb = renoise.ViewBuilder()


  --  create dialog content

  local dialog_content = vb:column {
    id = "dialog_content",
    margin = DEFAULT_MARGIN,
    spacing = DEFAULT_SPACING,

    -- Mode
    vb:column {
      vb:text {
        width = 30,
        text = "What:" 
      },
      vb:popup {
        width = POPUP_WIDTH,
        items = mode_names, 
        bind = preferences.mode,
        notifier = function()
          vb.views.automation_column.visible = 
            (preferences.mode.value ~= MODE_SELECTION_IN_PATTERN)
          
          vb.views.dialog_content:resize()
        end 
      },
    },

    -- Amount
    vb:column {
      vb:text { 
        width = 30,
        text = "By Lines:"  
      },
      vb:row { 
        vb:valuebox { 
          min = 1, 
          max = 256,
          bind = preferences.amount
        }
      }
    },
    
    
    -- Rotate Automation
    vb:column {
      id = "automation_column",
      visible = (preferences.mode.value ~= MODE_SELECTION_IN_PATTERN), 

      vb:space { height = 2*DEFAULT_SPACING },
      
      vb:row {
        vb:checkbox { bind = preferences.automation },
        vb:text { text = "Rotate Automation" }
      }
    },
        
    vb:space { height = 2*DEFAULT_SPACING },
    
    -- Process
    vb:row {
      vb:button { 
        text = "▲", 
        width = BUTTON_WIDTH, 
        height = BUTTON_HEIGHT,
        notifier = function()
          rotate(-preferences.amount.value, preferences.mode.value)
        end
      },
      vb:button { 
        text = "▼", 
        width = BUTTON_WIDTH, 
        height = BUTTON_HEIGHT,
        notifier = function()
          rotate(preferences.amount.value, preferences.mode.value)
        end
      }
    }
  }
    
  
  -- dialog key handler

  local function key_handler(dialog, key)
    print(key.name)
    
    if (key.name == "esc") then
      dialog:close()        
    
    elseif (key.name == "up") then
      rotate(-preferences.amount.value, preferences.mode.value)
    
    elseif (key.name == "down") then
      rotate(preferences.amount.value, preferences.mode.value)
    
    elseif (key.name == "tab") then
      local song = renoise.song()
      
      song.selected_track_index = rotate_index(song.selected_track_index,
        (key.modifiers == "shift") and -1 or 1, 1, #song.tracks
      )
          
    else
      -- forward all other keys to renoise
      return key 
    end
  end
    

  -- show the dialog

  dialog = renoise.app():show_custom_dialog(
    "Rotate Pattern", dialog_content, key_handler)
  
end


--------------------------------------------------------------------------------

-- close_dialog

function close_dialog()

  if (dialog and dialog.visible) then
    dialog:close()
  end

  dialog = nil
end


--------------------------------------------------------------------------------
-- tool registration
--------------------------------------------------------------------------------

-- menu entries

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Rotate...",
  invoke = show_dialog
}

-- keybindings

renoise.tool():add_keybinding {
  name = "Pattern Editor:Tools:Rotate...",
  invoke = show_dialog
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Pattern Operations:Rotate Pattern up",
  invoke = function() rotate(-1, MODE_WHOLE_PATTERN) end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Pattern Operations:Rotate Pattern down",
 invoke = function() rotate(1, MODE_WHOLE_PATTERN) end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Selection:Rotate Selection up",
  invoke = function() rotate(-1, MODE_SELECTION_IN_PATTERN) end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Selection:Rotate Selection down",
 invoke = function() rotate(1, MODE_SELECTION_IN_PATTERN) end
}


-- notifications

renoise.tool().app_new_document_observable:add_notifier(close_dialog)


-- preferences

renoise.tool().preferences = preferences

