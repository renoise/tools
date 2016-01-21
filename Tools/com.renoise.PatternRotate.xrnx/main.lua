--[[============================================================================
com.renoise.PatternRotate.xrnx/main.lua
============================================================================]]--

-- requires

require "pattern_line_tools"

local song = renoise.song


-- ranges

local RANGE_WHOLE_SONG = 1
local RANGE_WHOLE_PATTERN = 2
local RANGE_WHOLE_PHRASE = 3
local RANGE_TRACK_IN_SONG = 4
local RANGE_TRACK_IN_PATTERN = 5
local RANGE_SELECTION_IN_PATTERN = 6
local RANGE_SELECTION_IN_PHRASE = 7

local range_names = {
  "Whole Song",
  "Whole Pattern",
  "Whole Phrase",
  "Track in Song",
  "Track in Pattern",
  "Selection in Pattern",
  "Selection in Phrase"
}



--------------------------------------------------------------------------------
-- preferences
--------------------------------------------------------------------------------

local preferences = renoise.Document.create("ScriptingToolPreferences") {
  range_mode = RANGE_WHOLE_PATTERN,
  shift_amount = 1,
  shift_automation = true
}


--------------------------------------------------------------------------------
-- local tools
--------------------------------------------------------------------------------

-- shifts and wraps an index into a specified range

local function rotate_index(index, shift_amount, range_start, range_end)
  assert(index >= 0, "Internal error: unexpected rotate index")
  assert(range_start <= range_end, "Internal error: invalid rotate range")
  
  local range = range_end - range_start + 1
  shift_amount = shift_amount % range

  return (index - range_start + shift_amount + range) % range + range_start
end



--------------------------------------------------------------------------------
-- processing
--------------------------------------------------------------------------------

-- rotate patterns in the specified range by the given amount

function rotate(shift_amount, range_mode, shift_automation)
  
  range_mode = (range_mode ~= nil) and 
    range_mode or preferences.range_mode.value
  
  shift_automation = (shift_automation ~= nil) and 
    shift_automation or preferences.shift_automation.value
  
  assert(type(shift_amount) == "number", 
    "Internal Error: Unexpected shift_amount argument")
  assert(type(range_mode) == "number" and 
    range_mode >= 1 and range_mode <= #range_names, 
    "Internal Error: Unexpected range_mode argument")
  assert(type(shift_automation) == "boolean" and 
    "Internal Error: Unexpected shift_automation argument")
  
  local patterns = song().patterns
  local tracks = song().tracks
  
  local selected_track_index = song().selected_track_index
  local selected_pattern_index = song().selected_pattern_index
  local selected_phrase_index = song().selected_phrase_index
  
  ----- get the processing pattern & track range

  local process_selection = (range_mode == RANGE_SELECTION_IN_PATTERN or
    range_mode == RANGE_SELECTION_IN_PHRASE)


  local pattern_start, pattern_end
  local track_start, track_end
  local phrase_index  

  if (range_mode == RANGE_WHOLE_SONG) then
    pattern_start, pattern_end = 1, #patterns
    track_start, track_end = 1, #tracks
  
  elseif (range_mode == RANGE_WHOLE_PATTERN) then
    pattern_start, pattern_end = selected_pattern_index, selected_pattern_index
    track_start, track_end = 1, #tracks

  elseif (range_mode == RANGE_WHOLE_PHRASE) then
    phrase_index = selected_phrase_index
    track_start, track_end = 1, 1

  elseif (range_mode == RANGE_TRACK_IN_SONG) then
    pattern_start, pattern_end = 1, #patterns
    track_start, track_end = selected_track_index, selected_track_index
  
  elseif (range_mode == RANGE_TRACK_IN_PATTERN) then
    pattern_start, pattern_end = selected_pattern_index, selected_pattern_index
    track_start, track_end = selected_track_index, selected_track_index
  
  elseif (range_mode == RANGE_SELECTION_IN_PATTERN) then
    pattern_start, pattern_end = selected_pattern_index, selected_pattern_index
    track_start, track_end = 1, #tracks
  
  elseif (range_mode == RANGE_SELECTION_IN_PHRASE) then
    phrase_index = selected_phrase_index
    track_start, track_end = 1, 1
  else
    error("Internal error: unexpected rotate range mode")
  end
  
  if (range_mode == RANGE_WHOLE_PHRASE or 
      range_mode == RANGE_SELECTION_IN_PHRASE)
  then  
    ----- rotate selected phrase in the processing range


    local instrument = song().selected_instrument
    local phrase = instrument.phrases[phrase_index] 
    if not phrase then
      -- no phrase to work on...
      return
    end

    local visible_note_columns = phrase.visible_note_columns

    -- get the processing line range for the pattern
    local line_start, line_end, col_start, col_end --, line_range
    if (process_selection) then
      local selection = renoise.song().selection_in_phrase
      line_start = selection.start_line
      line_end = selection.end_line
      col_start = selection.start_column
      col_end = selection.end_column    
    else
      line_start, line_end = 1, phrase.number_of_lines
    end

    rotate_lines(
      phrase,
      line_start,
      line_end,
      col_start,
      col_end,      
      process_selection,
      visible_note_columns,
      false, -- shift_automation doesn't apply to phrases
      shift_amount)

  else  
    ----- rotate each pattern in the processing range
            
    for pattern_index = pattern_start,pattern_end do
      local pattern = patterns[pattern_index] 
        
      -- get the processing line range for the pattern
      local line_start, line_end, col_start, col_end --, line_range
      
      if (process_selection) then
        local selection = renoise.song().selection_in_pattern
        line_start = selection.start_line
        line_end = selection.end_line
        col_start = selection.start_column
        col_end = selection.end_column
        track_start = selection.start_track
        track_end = selection.end_track
      else
        line_start, line_end = 1, pattern.number_of_lines
      end 
      
      for track_index = track_start,track_end do

        local tmp_col_start,tmp_col_end
        local track = pattern:track(track_index) 
        local visible_note_columns = tracks[track_index].visible_note_columns
        local inbetween_track = 
          ((track_index > track_start) and 
          (track_index < track_end))

        if (track_start == track_end) then
          tmp_col_start,tmp_col_end = col_start,col_end
        elseif inbetween_track then
          tmp_col_start,tmp_col_end = 1,12
        elseif (track_index == track_start) then
          tmp_col_start,tmp_col_end = col_start,12
        elseif (track_index == track_end) then
          tmp_col_start,tmp_col_end = 1,col_end
        end

        rotate_lines(track,
          line_start,
          line_end,
          tmp_col_start,
          tmp_col_end,          
          process_selection,
          visible_note_columns,
          shift_automation,
          shift_amount)

      end

    end
  
  end

end

--------------------------------------------------------------------------------

-- rotate track (phrase or pattern-track) in the processing range

function rotate_lines(track,
  line_start,
  line_end,
  col_start,
  col_end,
  process_selection,
  visible_note_columns,
  shift_automation,
  shift_amount)
  

  if not line_start or not line_end then
    -- no lines to rotate. bail out...
    return   
  end   

  -- copy relevant lines to a temp array first (pattern lines are references)

  local temp_lines = {}

  for line_index = line_start,line_end do
    local src_line = track:line(line_index)
    
    if (process_selection or not src_line.is_empty) then
    
      -- will copy later on, empty or not...
      temp_lines[line_index] = { 
        is_empty = src_line.is_empty, 
        note_columns = {}, 
        effect_columns = {} 
      }

      copy_line(src_line, temp_lines[line_index])
    
    else

      -- will skip those lines later on...
      temp_lines[line_index] = { is_empty = true }
    end
  end
  
  -- check if col is between start/stop column
  local is_selected_col = function(index) 
    return ((index >= col_start) and
      (index <= col_end)) and true or false
  end
  
  -- rotate pattern lines or selected columns
  
  for line_index = line_start,line_end do
    local dest_line_index = rotate_index(line_index, 
      shift_amount, line_start, line_end)

    local src_line = temp_lines[line_index]
    local dest_line = track:line(dest_line_index)
    
    if (process_selection) then
      -- copy column by column, checking the selection state
      for index,note_column in pairs(src_line.note_columns) do
        
        if (index <= visible_note_columns) then
          if (is_selected_col(index)) then
            local dest_note_column = dest_line:note_column(index)
            copy_note_column(note_column, dest_note_column)
          end
        end
      end
      
      for index,effect_column in pairs(src_line.effect_columns) do
        
        local fxcol_index = visible_note_columns + index
        if (is_selected_col(fxcol_index)) then
          local dest_effect_column = dest_line:effect_column(index)
          copy_effect_column(effect_column, dest_effect_column)
        end
      end
    
    else
      -- copy whole lines or clear in one batch (just to speed up things)
      if (src_line.is_empty) then
        dest_line:clear()
      else
        copy_line(src_line, dest_line)
      end
    end
  end
            
            
  -- rotate automation (not for pattern selections)
  
  if (shift_automation and not process_selection) then
    for _,automation in pairs(track.automation) do
      local rotated_points = table.create(
        table.rcopy(automation.points))
      
      for _,point in pairs(rotated_points) do            
        if (point.time >= line_start and point.time < line_end + 1) then
          point.time = rotate_index(point.time, 
            shift_amount, line_start, line_end)
        end
      end
      
      rotated_points:sort(function(a,b) 
        return (a.time < b.time) 
      end)
      
      automation.points = rotated_points
    end
  end


end      


--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local dialog = nil


-- show_dialog

function show_dialog(options)

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
        text = "What:" 
      },
      vb:popup {
        width = POPUP_WIDTH,
        items = range_names, 
        value = options.range or RANGE_WHOLE_PATTERN,       
        bind = preferences.range_mode,
        notifier = function()
          vb.views.automation_column.visible = 
            (preferences.range_mode.value ~= RANGE_SELECTION_IN_PATTERN and
              preferences.range_mode.value ~= RANGE_SELECTION_IN_PHRASE)
          vb.views.dialog_content:resize()
        end 
      },
    },

    -- Amount
    vb:column {
      vb:text { 
        text = "By Lines:"  
      },
      vb:row { 
        vb:valuebox { 
          min = 1, 
          max = 256,
          bind = preferences.shift_amount
        }
      }
    },
    
    -- Rotate Automation
    vb:column {
      id = "automation_column",
      visible = (preferences.range_mode.value ~= RANGE_SELECTION_IN_PATTERN), 
      
      vb:space { height = 2*DEFAULT_SPACING },
      
      vb:row {
        vb:checkbox { bind = preferences.shift_automation },
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
          rotate(-preferences.shift_amount.value)
        end
      },
      vb:button { 
        text = "▼", 
        width = BUTTON_WIDTH, 
        height = BUTTON_HEIGHT,
        notifier = function()
          rotate(preferences.shift_amount.value)
        end
      }
    }
  }
    
  
  -- dialog key handler

  local function key_handler(dialog, key)
    
    if (key.name == "esc") then
      dialog:close()        
    
    elseif (key.name == "up") then
      rotate(-preferences.shift_amount.value)
    
    elseif (key.name == "down") then
      rotate(preferences.shift_amount.value)
    
    elseif (key.name == "tab") then
      song().selected_track_index = rotate_index(song().selected_track_index,
        (key.modifiers == "shift") and -1 or 1, 1, #song().tracks
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
  invoke = function()
    show_dialog({range = RANGE_WHOLE_PATTERN})
  end
}

renoise.tool():add_menu_entry {
  name = "Phrase Editor:Rotate...",
  invoke = function()
    show_dialog({range = RANGE_WHOLE_PHRASE})
  end
}

-- keybindings

renoise.tool():add_keybinding {
  name = "Pattern Editor:Tools:Rotate...",
  invoke = function(repeated) 
    if (not repeated) then 
      show_dialog({range = RANGE_WHOLE_PATTERN})
    end
  end
}


renoise.tool():add_keybinding {
  name = "Phrase Editor:Tools:Rotate...",
  invoke = function(repeated) 
    if (not repeated) then 
      show_dialog({range = RANGE_WHOLE_PHRASE})
    end
  end
}


renoise.tool():add_keybinding {
  name = "Pattern Editor:Pattern Operations:Rotate Pattern up",
  invoke = function(repeated) rotate(-1, RANGE_WHOLE_PATTERN) end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Pattern Operations:Rotate Pattern down",
 invoke = function(repeated) rotate(1, RANGE_WHOLE_PATTERN) end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Selection:Rotate Selection up",
  invoke = function(repeated) rotate(-1, RANGE_SELECTION_IN_PATTERN) end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Selection:Rotate Selection down",
  invoke = function(repeated) rotate(1, RANGE_SELECTION_IN_PATTERN) end
}

renoise.tool():add_keybinding {
  name = "Phrase Editor:Phrase Operations:Rotate Phrase up",
  invoke = function(repeated) rotate(-1, RANGE_WHOLE_PHRASE) end
}

renoise.tool():add_keybinding {
  name = "Phrase Editor:Phrase Operations:Rotate Phrase down",
 invoke = function(repeated) rotate(1, RANGE_WHOLE_PHRASE) end
}

renoise.tool():add_keybinding {
  name = "Phrase Editor:Selection:Rotate Selection up",
  invoke = function(repeated) rotate(-1, RANGE_SELECTION_IN_PHRASE) end
}

renoise.tool():add_keybinding {
  name = "Phrase Editor:Selection:Rotate Selection down",
  invoke = function(repeated) rotate(1, RANGE_SELECTION_IN_PHRASE) end
}

-- notifications

renoise.tool().app_new_document_observable:add_notifier(close_dialog)


-- preferences

renoise.tool().preferences = preferences

