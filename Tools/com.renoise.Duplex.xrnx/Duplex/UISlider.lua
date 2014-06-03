--[[============================================================================
-- Duplex.UISlider
-- Inheritance: UIComponent > UISlider
============================================================================]]--

--[[--
The Slider supports different input methods: buttons or faders/dials

- use multiple buttons to divide the value into discrete steps
- built-in quantize for MIDI devices (only output when 7bit values change)
- supports ORIENTATION.HORIZONTAL/vertical orientation and axis flipping
- display as normal/dimmed version (if supported in hardware)

--]]

--==============================================================================

class 'UISlider' (UIComponent)

--------------------------------------------------------------------------------

--- Initialize the UISlider class
-- @param app (@{Duplex.Application})

function UISlider:__init(app)
  TRACE('UISlider:__init')

  UIComponent.__init(self,app)

  --- current value, between 0 and .ceiling
  self.value = 0

  --- TODO the minimum value (the opposite of ceiling)
  -- self.floor = 0

  --- (int), set the number of steps to quantize the value
  -- (this value is automatically set when we assign a size)
  self.steps = 1

  --- (int) the selected index, between 0 - number of steps
  self.index = 0

  --- (bool) if true, press twice to switch to deselected state
  -- only applies when input method is a button
  self.toggleable = false

  --- (bool) paint a dimmed version
  -- only applies when input method is a button
  self.dimmed = false

  --- (bool) set this mode to ensure that slider is always displayed 
  -- correctly when using an array of buttons 
  -- (normally, this is not a problem, but when a slider is 
  -- resized to a single unit, this is the only way it will be 
  -- able to tell that it's a button)
  self.button_mode = false

  --- (bool) flip top/bottom direction 
  self.flipped = false

  --- slider is ORIENTATION.VERTICAL or ORIENTATION.HORIZONTAL?
  -- (use set_orientation() method to set this value)
  self._orientation = ORIENTATION.VERTICAL 

  --- (int) the 'physical' size, should always be 1 for dials/faders
  -- (use set_size() method to set this value)
  self._size = 1

  -- apply size 
  self:set_size(self._size)
  
  --- default palette
  -- @field background The background color 
  -- @field tip The active point
  -- @field tip_dimmed The active point (when dimmed)
  -- @field track The track color
  -- @field track_dimmed The track color (when dimmed)
  -- @table palette
  self.palette = {
    background    = {color = {0x00,0x00,0x00}, text = "·", val=false},
    tip           = {color = {0xFF,0xFF,0xFF}, text = "▪", val=true},
    tip_dimmed    = {color = {0xD0,0xD0,0xD0}, text = "▫", val=true},
    track         = {color = {0xD0,0xD0,0xD0}, text = "▪", val=true},
    track_dimmed  = {color = {0x80,0x80,0x80}, text = "▫", val=true},
  }

  --- internal values
  self._cached_index = self.index
  self._cached_value = self.value

  -- attach ourself to the display message stream
  self:add_listeners()

end


--------------------------------------------------------------------------------

--- A button was pressed
-- @param msg (@{Duplex.Message})
-- @return self or nil

function UISlider:do_press(msg)
  TRACE("UISlider:do_press()",msg)

  if not self:test(msg) then
    return 
  end

  local idx = nil

  if (self._orientation == ORIENTATION.HORIZONTAL) or (self._orientation == ORIENTATION.VERTICAL) then
    idx = self:_determine_index_by_pos(msg.column, msg.row)
  else
    idx = msg.index
  end

  if (self.toggleable and self.index == idx) then
    idx = 0
  end

  self.set_index(self,idx)

  return self

end

--------------------------------------------------------------------------------

--- A value was changed (slider, dial)
-- set index + precise value within the index
-- @param msg (@{Duplex.Message})
-- @return self or nil

function UISlider:do_change(msg)
  TRACE("UISlider:do_change()",msg)

  if not self:test(msg) then
    return 
  end

  if (self.on_change ~= nil) then
    
    local new_val = nil
    
    local is_midi_device = (self.app.display.device.protocol == DEVICE_PROTOCOL.MIDI)
    
    local is_relative_7 = ((msg.param.mode == "rel_7_signed") or 
      (msg.param.mode == "rel_7_signed2") or
      (msg.param.mode == "rel_7_offset") or
      (msg.param.mode == "rel_7_twos_comp"))
    
    if not msg.is_virtual and is_midi_device and is_relative_7 then
      -- check midi resolution
      local midi_res = self.app.display.device.default_midi_resolution
      if not (midi_res == 127) then
        LOG("UISlider: rel_7_signed2 mode expected '127' as the midi resolution")
        return 
      end
      -- treat as relative control
      new_val = self.value
      local step_size = self.ceiling/midi_res
      if (msg.param.mode == "rel_7_signed") then
        if (msg.midi_msg[3] < 64) then
          new_val = math.max(new_val-(step_size*msg.midi_msg[3]),0)
        elseif (msg.midi_msg[3] > 64) then
          new_val = math.min(new_val+(step_size*(msg.midi_msg[3]-64)),self.ceiling)
        end
      elseif (msg.param.mode == "rel_7_signed2") then
        if (msg.midi_msg[3] > 64) then
          new_val = math.max(new_val-(step_size*(msg.midi_msg[3]-64)),0)
        elseif (msg.midi_msg[3] < 64) then
          new_val = math.min(new_val+(step_size*msg.midi_msg[3]),self.ceiling)
        end
      elseif (msg.param.mode == "rel_7_offset") then
        if (msg.midi_msg[3] < 64) then
          new_val = math.max(new_val-(step_size*(64-msg.midi_msg[3])),0)
        elseif (msg.midi_msg[3] > 64) then
          new_val = math.min(new_val+(step_size*(msg.midi_msg[3]-64)),self.ceiling)
        end
      elseif (msg.param.mode == "rel_7_twos_comp") then
        if (msg.midi_msg[3] > 64) then
          new_val = math.max(new_val-(step_size*(128-msg.midi_msg[3])),0)
        elseif (msg.midi_msg[3] < 65) then
          new_val = math.min(new_val+(step_size*msg.midi_msg[3]),self.ceiling)
        end
      end
      -- check if outside range
      if ((new_val*midi_res) > midi_res) then
        LOG("UISlider: trying to assign out-of-range value, probably due to"
          .."/na parameter which has been set to an incorrect 'mode'")
        return 
      end
    else
      -- treat as absolute control:
      -- scale from the message range to the sliders range
      new_val = (msg.value / msg.max) * self.ceiling
    end

    if not self:output_quantize(new_val) then
      return 
    end

    self:set_value(new_val) 

  end 

  return self

end


--------------------------------------------------------------------------------

--- Set the value (will also update the index)
-- @param val (float), a number between 0 and .ceiling
-- @param skip_event (bool) skip event handler

function UISlider:set_value(val,skip_event)
  TRACE("UISlider:set_value()",val,skip_event)

  local idx = math.abs(math.ceil(((self.steps/self.ceiling)*val)-0.5))
  self._cached_value = self.value
  self._cached_index = self.index
  self.value = val
  self.index = idx

  self:invalidate()

  if not skip_event then
    return self:_invoke_handler() 
  end

end

--------------------------------------------------------------------------------

--- Check if parameter-quantization is in force
-- @return (bool) true when the message can pass, false when not

function UISlider:output_quantize(val)

  -- MIDI devices quantize their output by default
  if not (self.app.display.device.protocol == DEVICE_PROTOCOL.MIDI) then
    return true
  end

  local quantize_value = function(val)
    local midi_res = self.app.display.device.default_midi_resolution
    return math.floor((val/self.ceiling)*midi_res)
  end

  if self.app.display.device.output_quantize then
    local cached_val = quantize_value(self.value)
    local val = quantize_value(val)
    if (cached_val == val) then
      return false
    end
  end

  return true

end

--------------------------------------------------------------------------------

--- Set index (will also update the value)
-- @param idx (integer) 
-- @param skip_event (bool) skip event handler

function UISlider:set_index(idx,skip_event)
  TRACE("UISlider:set_index()",idx,skip_event)

  self._cached_index = self.index
  self._cached_value = self.value
  self.index = idx
  self.value = (idx~=0) and ((self.ceiling/self.steps)*idx) or 0

  self:invalidate()

  if not skip_event then
    return self:_invoke_handler()
  end

end

--------------------------------------------------------------------------------

--- Force-update controls that are handling their internal state by themselves

function UISlider:force_update()

  self.canvas.delta = table.rcopy(self.canvas.buffer)
  self.canvas.has_changed = true
  self:invalidate()

end

--------------------------------------------------------------------------------

--- Display the slider as "dimmed" (use alternative palette)
-- @param bool (bool) true for dimmed state, false for normal state

function UISlider:set_dimmed(bool)

  self.dimmed = bool
  self:invalidate()

end


--------------------------------------------------------------------------------

--- Set the slider orientation 
-- (only relevant when assigned to buttons)
-- @param value (@{Duplex.Globals.ORIENTATION}) 

function UISlider:set_orientation(value)
  TRACE("UISlider:set_orientation",value)

  assert((value == ORIENTATION.NONE) or 
    (value == ORIENTATION.HORIZONTAL) or 
    (value == ORIENTATION.VERTICAL),
    "Warning: UISlider received unexpected UI orientation")

  self._orientation = value
  self:set_size(self._size)

end

--------------------------------------------------------------------------------

--- Get the orientation 
-- @return @{Duplex.Globals.ORIENTATION}

function UISlider:get_orientation()
  TRACE("UISlider:get_orientation()")
  return self._orientation
end


--------------------------------------------------------------------------------
-- Overridden from UIComponent
--------------------------------------------------------------------------------

--- Override UIComponent with this method
-- @param size (Number)
-- @see Duplex.UIComponent

function UISlider:set_size(size)
  TRACE("UISlider:set_size",size)

  self.steps = size
  self._size = size

  if (self._orientation == ORIENTATION.VERTICAL) then
    UIComponent.set_size(self, 1, size)
  elseif (self._orientation == ORIENTATION.HORIZONTAL) or
    (self._orientation == ORIENTATION.NONE)
  then
    UIComponent.set_size(self, size, 1)
  end
end

--------------------------------------------------------------------------------

--- Expanded UIComponent test
-- @param msg (@{Duplex.Message})
-- @return bool, false when criteria is not met
-- @see Duplex.UIComponent.test

function UISlider:test(msg)

  if not (self.group_name == msg.group_name) then
    return false
  end

  if not self.app.active then
    return false
  end
  
  if (self._orientation == ORIENTATION.VERTICAL) or
    (self._orientation == ORIENTATION.HORIZONTAL)
  then
    return UIComponent.test(self,msg.column,msg.row)
  end

  -- no-orientation, fill the entire group
  return true

end


--------------------------------------------------------------------------------

--- Update the appearance - inherited from UIComponent
-- @see Duplex.UIComponent

function UISlider:draw()
  TRACE("UISlider:draw() - self.value",self.value)

  if (self._size==1) and not (self.button_mode) then
    -- update dial/fader 
    local point = CanvasPoint()
    point.val = self.value
    self.canvas:write(point, 1, 1)
  else
    -- update button array

    local idx = self.index
    if idx then

      if (not self.flipped) then
        idx = self._size - idx + 1
      end

      for i = 1,self._size do

        local x,y = 1,1
        if (self._orientation == ORIENTATION.VERTICAL) then 
          y = i
        else
          x = i  
        end

        local point = CanvasPoint()
        point:apply(self.palette.background)
        point.val = false      

        local apply_track = false

        if (i == idx) then
          -- update the tip of the slider
          point.val = self.palette.tip.val        
          point:apply((self.dimmed) and 
            self.palette.tip_dimmed or self.palette.tip)
        elseif (self.flipped) then
          if (i <= idx) then
            apply_track = true
          end
        elseif ((self._size - i) < self.index) then
          apply_track = true
        end
        
        if(apply_track)then
          point.val = self.palette.track.val        
          point:apply((self.dimmed) and 
            self.palette.track_dimmed or self.palette.track)
        end

        self.canvas:write(point, x, y)
      end

    end
  end

  UIComponent.draw(self)

end


--------------------------------------------------------------------------------

--- Add event listeners
--    DEVICE_EVENT.BUTTON_PRESSED
--    DEVICE_EVENT.VALUE_CHANGED
-- @see Duplex.UIComponent.add_listeners

function UISlider:add_listeners()
  TRACE("UISlider:add_listeners()")

  self.app.display.device.message_stream:add_listener(
    self,DEVICE_EVENT.BUTTON_PRESSED,
    function(msg) return self:do_press(msg) end )

  self.app.display.device.message_stream:add_listener(
    self,DEVICE_EVENT.VALUE_CHANGED,
    function(msg) return self:do_change(msg) end )

  --[[
  self.app.display.device.message_stream:add_listener(
    self,DEVICE_EVENT.BUTTON_RELEASED,
    function(msg) self:do_release(msg) end )
  ]]

end


--------------------------------------------------------------------------------

--- Remove previously attached event listeners
-- @see Duplex.UIComponent

function UISlider:remove_listeners()
  TRACE("UISlider:remove_listeners()")

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT.BUTTON_PRESSED)

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT.VALUE_CHANGED)

  --[[
  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT.BUTTON_RELEASED)
  ]]

end


--------------------------------------------------------------------------------
-- Private
--------------------------------------------------------------------------------

--- Determine index by position, depends on orientation
-- @param column (Number)
-- @param row (Number)

function UISlider:_determine_index_by_pos(column,row)

  local idx,offset

  if (self._orientation == ORIENTATION.VERTICAL) then
    idx = row
    offset = self.y_pos
  elseif (self._orientation == ORIENTATION.HORIZONTAL) then
    idx = column
    offset = self.x_pos
  elseif (self._orientation == ORIENTATION.NONE) then
    idx = column
    offset = self.x_pos
  end

  if not (self.flipped) then
    idx = (self._size-idx+offset)
  else
    idx = idx-offset+1
  end

  return idx
end


--------------------------------------------------------------------------------

--- Trigger the external handler method
-- @return true when message was handled, false when not

function UISlider:_invoke_handler()
  TRACE("UISlider:_invoke_handler")

  if self.on_change then
    if (self:on_change()==false) then
      --print("*** UISlider - revert to old value")
      self.index = self._cached_index    
      self.value = self._cached_value  
    end
    return true
  else
    return false
  end


end


