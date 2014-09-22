--[[============================================================================
-- Duplex.Application.PatternCursor
============================================================================]]--

--[[--

Navigate between lines and columns/tracks in the pattern editor.

### TODO 
refactor Mlrx_pos to make navigation across pattern boundaries more streamlined - currently, navigating with edit-step around very short patterns will not work, only when pattern contain more lines than editstep...

### Changes

  0.99.3
    - First release

--]]

--==============================================================================

class 'PatternCursor' (Application)


PatternCursor.WRAP_MODE_AUTO = 1
PatternCursor.WRAP_MODE_ON = 2
PatternCursor.WRAP_MODE_OFF = 3


PatternCursor.default_options = {

  wrap_mode = {
    label = "Pattern Wrap",
    description = "Whether to allow continuous movement between patterns or not",
    items = {
      "Auto (use Renoise setting)",
      "Yes (wrap inside pattern)",
      "No (move between patterns)",
    },
    value = 1,
  },
  
}

PatternCursor.available_mappings = {
  prev_line = {
    description = "PatternCursor: previous line"
  },
  next_line = {
    description = "PatternCursor: next line"
  },
  prev_line_editstep = {
    description = "PatternCursor: previous line (editstep)"
  },
  next_line_editstep = {
    description = "PatternCursor: next line (editstep)"
  },
  set_line = {
    description = "PatternCursor: set selected line"
  }
}

PatternCursor.default_palette = {
  line_up = { text = "▲"},
  line_down = { text = "▼"},
  editstep_up = { text = "▲e"},
  editstep_down = { text = "▼e"},
  enabled   = { color = {0xFF,0x80,0x80}, val=true  },
  disabled  = { color = {0x00,0x00,0x00}, val=false }
}


--------------------------------------------------------------------------------

--- Constructor method
-- @param (VarArg)
-- @see Duplex.Application

function PatternCursor:__init(...)

  self.repeat_change_by = nil
  self.repeat_ctrl = nil

  self._controls = {}

  Application.__init(self,...)

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.start_app
-- @return bool or nil

function PatternCursor:start_app()
  TRACE("PatternCursor:start_app()")

  if not Application.start_app(self) then
    return
  end
  --self:update()

end

--------------------------------------------------------------------------------

function PatternCursor:on_idle()

  if self.repeat_change_by then
    if self:changeLineBy(self.repeat_change_by) then
      self.repeat_ctrl:flash(0.2,self.palette.enabled,self.palette.disabled)
    end      
  end

end


--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application._build_app
-- @return bool

function PatternCursor:_build_app()
  TRACE("PatternCursor:_build_app()")

  local map = self.mappings.prev_line
  if map.group_name then
    local c = UIButton(self,map)
    c:set(self.palette.line_up)
    c.on_press = function(obj)
      if self:changeLineBy(-1) then
        c:flash(0.2,self.palette.enabled,self.palette.disabled)
      end
    end
    self._controls.prev_line = c
  end  

  local map = self.mappings.prev_line_editstep
  if map.group_name then
    local c = UIButton(self,map)
    c:set(self.palette.editstep_up)
    c.on_press = function(obj)
      if self:changeLineBy(-self.getStepSize()) then
        c:flash(0.2,self.palette.enabled,self.palette.disabled)
      end      
    end
    c.on_hold = function()
      self.repeat_change_by = - self.getStepSize()
      self.repeat_ctrl = c
    end
    c.on_release = function()
      if (self.repeat_ctrl == c) then
        self.repeat_change_by = nil
      end
    end
    self._controls.prev_line_editstep = c
  end  


  local map = self.mappings.next_line
  if map.group_name then
    local c = UIButton(self,map)
    c:set(self.palette.line_down)
    c.on_press = function(obj)
      if self:changeLineBy(1) then
        c:flash(0.2,self.palette.enabled,self.palette.disabled)
      end
    end
    self._controls.next_line = c
  end  

  local map = self.mappings.next_line_editstep
  if map.group_name then
    local c = UIButton(self,map)
    c:set(self.palette.editstep_down)
    c.on_press = function(obj)
      if self:changeLineBy(self.getStepSize()) then
        c:flash(0.2,self.palette.enabled,self.palette.disabled)
      end      
    end
    c.on_hold = function()
      self.repeat_change_by = self.getStepSize()
      self.repeat_ctrl = c
    end
    c.on_release = function()
      if (self.repeat_ctrl == c) then
        self.repeat_change_by = nil
      end
    end
    self._controls.next_line_editstep = c
  end    

  
  local map = self.mappings.set_line
  if map.group_name then
    local c = UISlider(self,map)
    c.on_change = function(obj)
      self:changeLineTo(obj.index)
    end
    self._controls.set_line = c
  end
    
  -- attach to song at first run
  --self:_attach_to_song()

  return true

end


--------------------------------------------------------------------------------

--- attempt to change selected line by provided amount
-- @param val (int) the relative number of lines to change by
-- @return bool (true when able to set line, false when not)

function PatternCursor:changeLineBy(val)
  TRACE("PatternCursor:changeLineBy(val)",val)

  local rns = renoise.song()
  local line_index = rns.selected_line_index
  local seq_index = rns.selected_sequence_index
  local patt_index = rns.selected_pattern_index
  local patt = rns.patterns[patt_index]
  
  local new_line_index = line_index + val
  local new_seq_index = seq_index
  local new_patt = rns.patterns[patt_index]

  --print("PRE new_line_index,new_seq_index",new_line_index,new_seq_index)
  
  if (new_line_index < 1) then
    if self:isWrappedEdit() then
      -- head into previous pattern
      new_seq_index = new_seq_index-1
      --print("head into previous pattern - new_seq_index,new_patt_index,new_patt",new_seq_index,new_patt_index,new_patt)
      if (new_seq_index > 0) then
        local new_patt_index = rns.sequencer.pattern_sequence[new_seq_index]
        new_patt = rns.patterns[new_patt_index]
        new_line_index = new_patt.number_of_lines + new_line_index 
      else
        new_line_index = 1
        new_seq_index = 1
      end
    else
      -- wrap around current pattern
      new_line_index = patt.number_of_lines + new_line_index 
    end
  elseif (new_line_index > patt.number_of_lines) then
    if self:isWrappedEdit() then
      -- head into next pattern
      new_seq_index = new_seq_index+1
      local seq_length = #renoise.song().sequencer.pattern_sequence
      --print("head into next pattern - new_seq_index,seq_length",new_seq_index,seq_length)
      if (new_seq_index > seq_length) then
        new_seq_index = seq_length
        local new_patt_index = rns.sequencer.pattern_sequence[new_seq_index]
        new_patt = rns.patterns[new_patt_index]
        new_line_index = new_patt.number_of_lines
        --print("got here A",new_patt.number_of_lines)
      else
        local new_patt_index = rns.sequencer.pattern_sequence[new_seq_index]
        new_patt = rns.patterns[new_patt_index]
        new_line_index = line_index - patt.number_of_lines + val
        --print("got here B",new_patt.number_of_lines)

      end
      
    else
      -- wrap around current pattern
      new_line_index = line_index - patt.number_of_lines + val
    end
  end

  --print("POST new_line_index,new_seq_index",new_line_index,new_seq_index)

  -- TODO without a proper mlrx_pos style method, we need this
  if (new_line_index > new_patt.number_of_lines) then
    new_line_index = new_patt.number_of_lines
  elseif (new_line_index < 1) then
    new_line_index = 1
  end

  --print("POST2 new_line_index,new_seq_index",new_line_index,new_seq_index)

  if (rns.selected_line_index == new_line_index) and
    (seq_index == new_seq_index) 
  then
    return false
  else
    rns.selected_sequence_index = new_seq_index
    rns.selected_line_index = new_line_index
    return true
  end
end      

--------------------------------------------------------------------------------

--- attempt to change selected line to specified value
-- @param val (int) the line to set
-- @return bool (true when able to set line, false when not)

function PatternCursor:changeLineTo(val)

  local rns = renoise.song()
  local patt_index = rns.selected_pattern_index
  local patt = rns.patterns[patt_index]    
  rns.selected_line_index = clamp_value(
    val, 1, patt.number_of_lines)
    
end      

--------------------------------------------------------------------------------

function PatternCursor:isWrappedEdit()

  local rns = renoise.song()
  if (self.options.wrap_mode.value == PatternCursor.WRAP_MODE_ON) or
    ((self.options.wrap_mode.value == PatternCursor.WRAP_MODE_AUTO) and
    rns.transport.wrapped_pattern_edit) 
  then
    return true
  else
    return false
  end
  
end

--------------------------------------------------------------------------------

function PatternCursor:getStepSize()

  local rns = renoise.song()
  return rns.transport.edit_step
  
end


