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

  if not self:test(msg) then
    return 
  end

  local idx = nil

  if (self._orientation == HORIZONTAL) or (self._orientation == VERTICAL) then
    idx = self:_determine_index_by_pos(msg.column, msg.row)
  else
    idx = msg.index
  end

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

  if not self:test(msg) then
    return 
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

  if not self:test(msg) then
    return 
  end

  -- look for event handlers
  if (self.on_change ~= nil) then

    local new_val = nil

    local is_midi_device = (self._display.device.protocol == DEVICE_MIDI_PROTOCOL)

    local is_relative_7 = ((msg.param.mode == "rel_7_signed") or 
      (msg.param.mode == "rel_7_signed2") or
      (msg.param.mode == "rel_7_offset") or
      (msg.param.mode == "rel_7_twos_comp"))

    if not msg.is_virtual and is_midi_device and is_relative_7 then

      -- check midi resolution
      local midi_res = self._display.device.default_midi_resolution
      if not (midi_res == 127) then
        LOG("UISlider: rel_7_signed2 mode expected '127' as the midi resolution")
        return false
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
          new_val = math.max(new_val-(step_size*(msg.midi_msg[3]-62)),0)
        elseif (msg.midi_msg[3] > 64) then
          new_val = math.min(new_val+(step_size*(msg.midi_msg[3]-64)),self.ceiling)
        end

      elseif (msg.param.mode == "rel_7_twos_comp") then
        if (msg.midi_msg[3] > 64) then
          new_val = math.max(new_val-(step_size*(msg.midi_msg[3]-126)),0)
        elseif (msg.midi_msg[3] < 65) then
          new_val = math.min(new_val+(step_size*msg.midi_msg[3]),self.ceiling)
        end
      end

      -- check if outside range
      if ((new_val*midi_res) > midi_res) then
        LOG("UISlider: trying to assign out-of-range value, probably due to"
          .."/na parameter which has been set to an incorrect 'mode'")
        return false
      end

    else

      -- treat as absolute control:
      -- scale from the message range to the sliders range
      new_val = (msg.value / msg.max) * self.ceiling
      
    end


    -- if the quantized value isn't different from the current, 
    -- ignore the value but signal that the message got handled 
    -- (mostly relevant when changing the value from Renoise)
    if not self:output_quantize(new_val) then
      return true
    end

    -- set the value, and let us know if the event handler 
    -- actively rejected the request
    if (self:set_value(new_val)==false) then
      return false
    end

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


  --local idx = math.abs(math.ceil(((self.steps/self.ceiling)*val)-0.5))
  --print("*** SET_VALUE, idx",idx,"self._cached_index",self._cached_index,"self._cached_value",self._cached_value,"val",val)
  --if (self._cached_index ~= idx) or
  --   (self._cached_value ~= val)
  --then


  local idx = math.abs(math.ceil(((self.steps/self.ceiling)*val)-0.5))
  self._cached_index = idx
  self._cached_value = val
  self.value = val
  self.index = idx

  if (skip_event) then
    self:invalidate()
  else
    return self:_invoke_handler()
  end

  --end  

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

  assert((value == NO_ORIENTATION) or 
    (value == HORIZONTAL) or 
    (value == VERTICAL),
    "Warning: UISlider received unexpected UI orientation")

  self._orientation = value
  self:set_size(self._size)

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
  elseif (self._orientation == HORIZONTAL) or
    (self._orientation == NO_ORIENTATION)
  then
    UIComponent.set_size(self, size, 1)
  end
end

--------------------------------------------------------------------------------

--- Expanded UIComponent test: look for group name, event handlers before
-- proceeding with the normal UIComponent test
-- @param msg (Message)
-- @return boolean, false when criteria is not met

function UISlider:test(msg)

  -- look for group name
  if not (self.group_name == msg.group_name) then
    return false
  end

  -- test the X/Y position
  if (self._orientation == VERTICAL) or
    (self._orientation == HORIZONTAL)
  then
    return UIComponent.test(self,msg.column,msg.row)
  end

  return true

end


--------------------------------------------------------------------------------

--- Update the UIComponent canvas

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
        if (self._orientation == VERTICAL) then 
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
  elseif (self._orientation == HORIZONTAL) then
    idx = column
    offset = self.x_pos
  elseif (self._orientation == NO_ORIENTATION) then
    idx = column
    offset = self.x_pos
    --[[
    ]]
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

  -- when calling set_index() and set_value() before we
  -- have assigned a method, return 'true' (so we don't
  -- accidentially pass messages at construction time)
  if (self.on_change == nil) then
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


