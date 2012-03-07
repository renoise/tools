--[[----------------------------------------------------------------------------
-- Duplex.Rotate
-- Inheritance: Application > Rotate
----------------------------------------------------------------------------]]--

--[[

  Based on taktik's Rotate tool:
  http://tools.renoise.com/tools/rotate-pattern

  This implementation currently only comes with mappings for some actions
  - track_in_pattern_up
  - track_in_pattern_down
  - whole_pattern_up
  - whole_pattern_down


--]]

--==============================================================================


class 'Rotate' (Application)

Rotate.default_options = {

  shift_amount = {
    label = "Shift amount",
    description = "Number of lines to shift",
    items = {"1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16"},
    value = 1
  },
  shift_automation = {
    label = "Shift automation",
    description = "Choose whether to shift automation as well",
    items = {
      "Yes",
      "No"
    },
    value = 2
  },
}

function Rotate:__init(process,mappings,options,cfg_name,palette)


  -- ranges

  self.RANGE_WHOLE_SONG = 1
  self.RANGE_WHOLE_PATTERN = 2
  self.RANGE_TRACK_IN_SONG = 3
  self.RANGE_TRACK_IN_PATTERN = 4
  self.RANGE_SELECTION_IN_PATTERN = 5

  self.SHIFT_AUTOMATION_ON = 1
  self.SHIFT_AUTOMATION_OFF = 2

  self.range_names = {
    "Whole Song",
    "Whole Pattern",
    "Track in Song",
    "Track in Pattern",
    "Selection in Pattern"
  }

  self.effect_column_properties = {
    "number_value",
    "amount_value",
  }

  self.note_column_properties = {
    "note_value",
    "instrument_value",
    "volume_value",
    "panning_value",
    "delay_value",
  }

  self.mappings = {
    track_in_pattern_up = { 
      description = "Rotate: toggle on/off"
    },
    track_in_pattern_down = {
      description = "Rotate: toggle on/off"
    },
    whole_pattern_up = {
      description = "Rotate: toggle on/off"
    },
    whole_pattern_down = {
      description = "Rotate: toggle on/off"
    },
  }

  self.palette = {
    up_bright = {
      color = {0xFF,0xFF,0xFF},
      text = "▲"
    },
    up_dimmed = {
      color = {0x80,0x80,0x80},
      text = "▲"
    },
    up_off = {
      color = {0x40,0x40,0x40},
      text = "▲"
    },
    down_bright = {
      color = {0xFF,0xFF,0xFF},
      text = "▼"
    },
    down_dimmed = {
      color = {0x80,0x80,0x80},
      text = "▼"
    },
    down_off = {
      color = {0x40,0x40,0x40},
      text = "▼"
    },
  }


  Application.__init(self,process,mappings,options,cfg_name,palette)

end

--------------------------------------------------------------------------------
-- local tools
--------------------------------------------------------------------------------

-- shifts and wraps an index into a specified range

function Rotate:rotate_index(index, shift_amount, range_start, range_end)
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

function Rotate:process(shift_amount, range_mode, shift_automation)
  
  range_mode = (range_mode ~= nil) and 
    range_mode or self.options.range_mode.value
  
  shift_automation = (shift_automation ~= nil) and 
    shift_automation or 
    (self.options.shift_automation.value == self.SHIFT_AUTOMATION_ON)
  
  assert(type(shift_amount) == "number", 
    "Internal Error: Unexpected shift_amount argument")
  assert(type(range_mode) == "number" and 
    range_mode >= 1 and range_mode <= #self.range_names, 
    "Internal Error: Unexpected range_mode argument")
  assert(type(shift_automation) == "boolean" and 
    "Internal Error: Unexpected shift_automation argument")
  
  local patterns = renoise.song().patterns
  local tracks = renoise.song().tracks
  
  local selected_track_index = renoise.song().selected_track_index
  local selected_pattern_index = renoise.song().selected_pattern_index
    
  
  ----- get the processing pattern & track range

  local process_selection = (range_mode == self.RANGE_SELECTION_IN_PATTERN)

  local pattern_start, pattern_end
  local track_start, track_end
  
  if (range_mode == self.RANGE_WHOLE_SONG) then
    pattern_start, pattern_end = 1, #patterns
    track_start, track_end = 1, #tracks
  
  elseif (range_mode == self.RANGE_WHOLE_PATTERN) then
    pattern_start, pattern_end = selected_pattern_index, selected_pattern_index
    track_start, track_end = 1, #tracks
  
  elseif (range_mode == self.RANGE_TRACK_IN_SONG) then
    pattern_start, pattern_end = 1, #patterns
    track_start, track_end = selected_track_index, selected_track_index
  
  elseif (range_mode == self.RANGE_TRACK_IN_PATTERN) then
    pattern_start, pattern_end = selected_pattern_index, selected_pattern_index
    track_start, track_end = selected_track_index, selected_track_index
  
  elseif (range_mode == self.RANGE_SELECTION_IN_PATTERN) then
    pattern_start, pattern_end = selected_pattern_index, selected_pattern_index
    track_start, track_end = 1, #tracks
  
  else
    error("Internal error: unexpected rotate range mode")
  end
  
  
  ----- rotate each pattern in the processing range
          
  for pattern_index = pattern_start,pattern_end do
    local pattern = patterns[pattern_index] 
      
    -- get the processing line range for the pattern
    local line_start, line_end, line_range
    
    if (process_selection) then
      line_start, line_end = self:selection_line_range(pattern_index)
    else
      line_start, line_end = 1, pattern.number_of_lines
    end
       
    if (line_start and line_end) then
      line_range = line_end - line_start + 1
    else
      -- no lines to rotate. bail out...
      break   
    end    
  
  
    ---- rotate each track in the pattern in the processing range
    
    for track_index = track_start,track_end do
      local track = pattern:track(track_index) 
      
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
  
          self:copy_line(src_line, temp_lines[line_index])
        
        else
  
          -- will skip those lines later on...
          temp_lines[line_index] = { is_empty = true }
        end
      end
      
      
      -- rotate pattern lines or selected columns
      
      for line_index = line_start,line_end do
        local dest_line_index = self:rotate_index(line_index, 
          shift_amount, line_start, line_end)
  
        local src_line = temp_lines[line_index]
        local dest_line = track:line(dest_line_index)
        
        if (process_selection) then
          -- copy column by column, checking the selection state
          for index,note_column in pairs(src_line.note_columns) do
            local dest_note_column = dest_line:note_column(index)
            
            if (dest_note_column.is_selected) then
              self:copy_note_column(note_column, dest_note_column)
            end
          end
          
          for index,effect_column in pairs(src_line.effect_columns) do
            local dest_effect_column = dest_line:effect_column(index)
            
            if (dest_effect_column.is_selected) then
              self:copy_effect_column(effect_column, dest_effect_column)
            end
          end
        
        else
          -- copy whole lines or clear in one batch (just to speed up things)
          if (src_line.is_empty) then
            dest_line:clear()
          else
            self:copy_line(src_line, dest_line)
          end
        end
      end
                
                
      -- rotate automation (not for pattern selections)
      
      if (shift_automation and not process_selection) then
        for _,automation in pairs(track.automation) do
          local rotated_points = table.create(
            table.rcopy(automation.points))
          
          for _,point in pairs(rotated_points) do
            if (point.time >= line_start and point.time <= line_end) then
              point.time = self:rotate_index(point.time, 
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
  end

  local range_name = self.range_names[range_mode]
  local shift_autom = (shift_automation) and "(including automation)" or ""
  local msg = "Rotate: %s by %i %s"
  msg = string.format(msg,range_name,shift_amount,shift_autom)
  renoise.app():show_status(msg)

end


--[[============================================================================
pattern_line_tools.lua
============================================================================]]--

--------------------------------------------------------------------------------

-- copy all effect column properties from src to dest column


function Rotate:copy_effect_column(src_column, dest_column)
  for _,property in pairs(self.effect_column_properties) do
    dest_column[property] = src_column[property]
  end
end


--------------------------------------------------------------------------------

-- copy all note column properties from src to dest column


function Rotate:copy_note_column(src_column, dest_column)
  for _,property in pairs(self.note_column_properties) do
    dest_column[property] = src_column[property]
  end
end


--------------------------------------------------------------------------------

-- creates a copy of the given patternline

function Rotate:copy_line(src_line, dest_line)

  for index,src_column in pairs(src_line.note_columns) do
    if (not dest_line.note_columns[index]) then
      dest_line.note_columns[index] = {}
    end

    local dest_column = dest_line.note_columns[index]
    self:copy_note_column(src_column, dest_column)
  end
  
  for index,src_column in pairs(src_line.effect_columns) do
    if (not dest_line.effect_columns[index]) then
      dest_line.effect_columns[index] = {}
    end
    
    local dest_column = dest_line.effect_columns[index]
    self:copy_effect_column(src_column, dest_column)
  end
end


--------------------------------------------------------------------------------

-- queries the selection range start and end lines

function Rotate:selection_line_range(pattern_index)

  local line_start, line_end
  
  if (pattern_index == renoise.song().selected_pattern_index) then
    local iter = renoise.song().pattern_iterator:lines_in_pattern(pattern_index)
    
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
  end
    
  return line_start, line_end
end

--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

-- construct the user interface

function Rotate:_build_app()
  TRACE("Rotate:_build_app()")


  if self.mappings.track_in_pattern_up.group_name then
    local c = UIButton(self.display)
    c.group_name = self.mappings.track_in_pattern_up.group_name
    c.tooltip = self.mappings.track_in_pattern_up.description
    c:set_pos(self.mappings.track_in_pattern_up.index)
    c:set(self.palette.up_off)
    c.on_press = function(obj)
      if not self.active then return false end
      local shift_amount = -self.options.shift_amount.value
      local range_mode = self.RANGE_TRACK_IN_PATTERN
      local shift_automation = 
        (self.options.shift_automation.value == self.SHIFT_AUTOMATION_ON)
      self:process(shift_amount,range_mode,shift_automation)
      obj:flash(
        0.1,self.palette.up_bright,self.palette.up_dimmed,self.palette.up_off)
    end
    self:_add_component(c)
    self._track_in_pattern_up = c
  end

  if self.mappings.track_in_pattern_down.group_name then
    local c = UIButton(self.display)
    c.group_name = self.mappings.track_in_pattern_down.group_name
    c.tooltip = self.mappings.track_in_pattern_down.description
    c:set_pos(self.mappings.track_in_pattern_down.index)
    c:set(self.palette.down_off)
    c.on_press = function(obj)
      if not self.active then return false end
      local shift_amount = self.options.shift_amount.value
      local range_mode = self.RANGE_TRACK_IN_PATTERN
      local shift_automation = 
        (self.options.shift_automation.value == self.SHIFT_AUTOMATION_ON)
      self:process(shift_amount,range_mode,shift_automation)
      obj:flash(
        0.1,self.palette.down_bright,self.palette.down_dimmed,self.palette.down_off)
    end
    self:_add_component(c)
    self._track_in_pattern_down = c
  end

  if self.mappings.whole_pattern_up.group_name then
    local c = UIButton(self.display)
    c.group_name = self.mappings.whole_pattern_up.group_name
    c.tooltip = self.mappings.whole_pattern_up.description
    c:set_pos(self.mappings.whole_pattern_up.index)
    c:set(self.palette.up_off)
    c.on_press = function(obj)
      if not self.active then return false end
      local shift_amount = -self.options.shift_amount.value
      local range_mode = self.RANGE_WHOLE_PATTERN
      local shift_automation = 
        (self.options.shift_automation.value == self.SHIFT_AUTOMATION_ON)
      self:process(shift_amount,range_mode,shift_automation)
      obj:flash(
        0.1,self.palette.up_bright,self.palette.up_dimmed,self.palette.up_off)
    end
    self:_add_component(c)
    self._whole_pattern_up = c
  end

  if self.mappings.whole_pattern_down.group_name then
    local c = UIButton(self.display)
    c.group_name = self.mappings.whole_pattern_down.group_name
    c.tooltip = self.mappings.whole_pattern_down.description
    c:set_pos(self.mappings.whole_pattern_down.index)
    c:set(self.palette.down_off)
    c.on_press = function(obj)
      if not self.active then return false end
      local shift_amount = self.options.shift_amount.value
      local range_mode = self.RANGE_WHOLE_PATTERN
      local shift_automation = 
        (self.options.shift_automation.value == self.SHIFT_AUTOMATION_ON)
      self:process(shift_amount,range_mode,shift_automation)
      obj:flash(
        0.1,self.palette.down_bright,self.palette.down_dimmed,self.palette.down_off)
    end
    self:_add_component(c)
    self._whole_pattern_down = c
  end

  return true

end

--------------------------------------------------------------------------------
-- tool registration
--------------------------------------------------------------------------------

-- check configuration, build & start the application

function Rotate:start_app()

  if not Application.start_app(self) then
    return
  end

end


