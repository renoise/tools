--[[----------------------------------------------------------------------------
-- Duplex.UISlider
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UISlider
Requires: Globals, Display, CanvasPoint

-------------------------------------------------------------------------------

About

The Slider supports different input methods: buttons or faders/dials
- - use buttons to quantize the slider input
- - use faders/dials to divide value into smaller segments
- supports horizontal/vertical and axis flipping
- display as normal/dimmed version (if supported in hardware)
- minimum size: 1

-------------------------------------------------------------------------------

Events

  on_change() - invoked whenever the slider recieve a new value

  - if an event handler return false, we cancel/revert any changed values
  - if an event handler return true, the value (and appearance) is updated


-------------------------------------------------------------------------------

Usage

  -- create a vertical slider, 4 units in height

  local slider = UISlider(self.display)
  slider.group_name = "some_group_name"
  slider.x_pos = 1
  slider.y_pos = 1
  slider.toggleable = true
  slider.inverted = false
  slider.ceiling = 10
  slider:set_orientation(VERTICAL)
  slider:set_size(4)
  slider.on_change = function(obj) 
    -- on_change needs to be specified, if we
    -- want the slider to respond to input
  end
  self.display:add(slider)


--]]


--==============================================================================

class 'UISlider' (UIComponent)

--------------------------------------------------------------------------------

--- Initialize the UISlider class
-- @param display (Duplex.Display)

function UISlider:__init(display)
  TRACE('UISlider:__init')

  UIComponent.__init(self,display)

  -- current value, between 0 and .ceiling
  self.value = 0

  -- TODO the minimum value (the opposite of ceiling)
  -- self.floor = 0

  -- set the number of steps to quantize the value
  -- (this value is automatically set when we assign a size)
  self.steps = 1

  -- the selected index, between 0 - number of steps
  self.index = 0

  -- if true, press twice to switch to deselected state
  -- only applies when input method is a button
  self.toggleable = false

  -- paint a dimmed version
  -- only applies when input method is a button
  self.dimmed = false

  -- set this mode to ensure that slider is always displayed 
  -- correctly when using an array of buttons 
  -- (normally, this is not a problem, but when a slider is 
  -- resized to a single unit, this is the only way it will be 
  -- able to tell that it's a button)
  self.button_mode = false

  -- flip top/bottom direction 
  self.flipped = false

  -- slider is vertical or horizontal?
  -- (use set_orientation() method to set this value)
  self._orientation = VERTICAL 

  -- the 'physical' size (should always be 1 for dials/faders)
  -- (use set_size() method to set this value)
  self._size = 1

  -- apply size 
  self:set_size(self._size)
  
  -- default palette
  self.palette = {
    background    = {color = {0x00,0x00,0x00}, text = "·", val=false},
    tip           = {color = {0xFF,0xFF,0xFF}, text = "▪", val=true},
    tip_dimmed    = {color = {0xD0,0xD0,0xD0}, text = "▫", val=true},
    track         = {color = {0xD0,0xD0,0xD0}, text = "▪", val=true},
    track_dimmed  = {color = {0x80,0x80,0x80}, text = "▫", val=true},
  }

  -- internal values
  self._cached_index = self.index
  self._cached_value = self.value

  -- attach ourself to the display message stream
  self:add_listeners()

end


--------------------------------------------------------------------------------

--- A button was pressed
-- @param msg (Duplex.Message)
-- @return boolean, true when message was handled

function UISlider:do_press(msg)
  TRACE("UISlider:do_press()",msg)

  if not self:test(msg.group_name,msg.column, msg.row) then
    return false
  end

  local idx = self:_determine_index_by_pos(msg.column, msg.row)
  if (self.toggleable and self.index == idx) then
    idx = 0
  end

  if not self.set_index(self,idx) then
    return false
  end

  return true

end


--------------------------------------------------------------------------------

--- A button was released
-- @param msg (Duplex.Message)
-- @return boolean, true when message was handled

function UISlider:do_release(msg)
  TRACE("UISlider:do_release()",msg)

  if not self:test(msg.group_name,msg.column, msg.row) then
    return false
  end
  if (msg.input_method == CONTROLLER_PUSHBUTTON) then
    self:force_update()
  end

  return true

end

--------------------------------------------------------------------------------

--- A value was changed (slider, dial)
-- set index + precise value within the index
-- @param msg (Duplex.Message)
-- @return boolean, true when message was handled

function UISlider:do_change(msg)
  TRACE("UISlider:do_change()",msg)

  if not self:test(msg.group_name,msg.column,msg.row) then
    return false
  end
  -- scale from the message range to the sliders range
  local val = (msg.value / msg.max) * self.ceiling
  
  if not self:set_value(val) then
    return false
  end
  
  return true

end


--------------------------------------------------------------------------------

--- Set the value (will also update the index)
-- @param val (float), a number between 0 and .ceiling
-- @param skip_event (boolean) skip event handler
-- @return (boolean), false when rejected by handler 

function UISlider:set_value(val,skip_event)
  TRACE("UISlider:set_value()",val,skip_event)

  local idx = math.abs(math.ceil(((self.steps/self.ceiling)*val)-0.5))
  if (self._cached_index ~= idx) or
     (self._cached_value ~= val)
  then

    if not self:output_quantize(val) then
      -- silently ignore message
      return
    else

      self._cached_index = idx
      self._cached_value = val
      self.value = val
      self.index = idx

      if (skip_event) then
        self:invalidate()
      else
        return self:_invoke_handler()
      end
    end

  end  

end

--------------------------------------------------------------------------------

--- Check if parameter-quantization is in force
-- @return (Boolean) true when the message can pass, false when not

function UISlider:output_quantize(val)

  if not (self._display.device.protocol == DEVICE_MIDI_PROTOCOL) then
    return true
  end

  if self._display.device.output_quantize then

    local cached_val = self:quantize_value(self._cached_value)
    local val = self:quantize_value(val)
    if (cached_val == val) then
      return false
    end
  end

  return true

end

function UISlider:quantize_value(val)

  local midi_res = self._display.device.default_midi_resolution
  return math.floor((val/self.ceiling)*midi_res)

end

--------------------------------------------------------------------------------

--- Set index (will also update the value)
-- @param idx (integer) 
-- @param skip_event (boolean) skip event handler
-- @return (boolean), false when rejected by handler 

function UISlider:set_index(idx,skip_event)
  TRACE("UISlider:set_index()",idx,skip_event)

  local rslt = false
  if (self._cached_index ~= idx) then
    self._cached_index = idx
    self._cached_value = self.value
    self.index = idx
    self.value = (idx~=0) and ((self.ceiling/self.steps)*idx) or 0

    if (skip_event) then
      self:invalidate()
    else
      return self:_invoke_handler()
    end

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
-- @param bool (Boolean) true for dimmed state, false for normal state

function UISlider:set_dimmed(bool)

  self.dimmed = bool
  self:invalidate()

end


--------------------------------------------------------------------------------

--- Set the slider orientation 
-- (only relevant when assigned to buttons)
-- @param value (Enum) either VERTICAL or HORIZONTAL

function UISlider:set_orientation(value)
  TRACE("UISlider:set_orientation",value)

  if (value == HORIZONTAL) or (value == VERTICAL) then
    self._orientation = value
    self:set_size(self._size) -- update canvas
  end
end

--------------------------------------------------------------------------------

--- Get the orientation 
-- @return (Enum) either VERTICAL or HORIZONTAL

function UISlider:get_orientation()
  TRACE("UISlider:get_orientation()")
  return self._orientation
end


--------------------------------------------------------------------------------
-- Overridden from UIComponent
--------------------------------------------------------------------------------

--- Set the size (will change the canvas too)
-- @param size (Number)

function UISlider:set_size(size)
  TRACE("UISlider:set_size",size)

  self.steps = size
  self._size = size

  if (self._orientation == VERTICAL) then
    UIComponent.set_size(self, 1, size)
  else
    assert(self._orientation == HORIZONTAL, 
      "Internal Error. Please report: unexpected UI orientation")
      
    UIComponent.set_size(self, size, 1)
  end
end

--------------------------------------------------------------------------------

--- Expanded UIComponent test: look for group name, event handlers before
-- proceeding with the normal UIComponent test
-- @param group_name (String)
-- @param column (Number)
-- @param row (Number)
-- @return boolean, false when criteria is not met

function UISlider:test(group_name,column,row)

  -- look for group name
  if not (self.group_name == group_name) then
    return false
  end

  -- look for event handlers
  if (self.on_change == nil) then  
    return false
  end 

  -- test the X/Y position
  return UIComponent.test(self,column,row)

end


--------------------------------------------------------------------------------

--- Update the UIComponent canvas

function UISlider:draw()
  TRACE("UISlider:draw()")

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

        if (self._orientation == VERTICAL) then 
          y = i
        else
          x = i  
        end
        self.canvas:write(point, x, y)
      end

    end
  end

  UIComponent.draw(self)

end


--------------------------------------------------------------------------------

--- Add event listeners (press, release, change)

function UISlider:add_listeners()
  TRACE("UISlider:add_listeners()")

  self._display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED,
    function(msg) return self:do_press(msg) end )

  self._display.device.message_stream:add_listener(
    self,DEVICE_EVENT_VALUE_CHANGED,
    function(msg) return self:do_change(msg) end )

  self._display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_RELEASED,
    function(msg) return self:do_release(msg) end )

end


--------------------------------------------------------------------------------

--- Remove previously attached event listeners
-- @see UISlider:add_listeners

function UISlider:remove_listeners()
  TRACE("UISlider:remove_listeners()")

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED)

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_VALUE_CHANGED)

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_RELEASED)


end


--------------------------------------------------------------------------------
-- Private
--------------------------------------------------------------------------------

--- Determine index by position, depends on orientation
-- @param column (Number)
-- @param row (Number)

function UISlider:_determine_index_by_pos(column,row)

  local idx,offset

  if (self._orientation == VERTICAL) then
    idx = row
    offset = self.y_pos
  else
    assert(self._orientation == HORIZONTAL, 
      "Internal Error. Please report: unexpected UI orientation")
      
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

  -- when calling set_index() and set_value() before we
  -- have assigned a method, return 'true' (so we don't
  -- accidentially pass messages at construction time)
  if not self.on_change then
    return true
  end

  if (self:on_change()==false) then
    self.index = self._cached_index    
    self.value = self._cached_value  
    return false
  else
    self:invalidate()
    return true
  end
end


