--[[============================================================================
-- Duplex.UISlider
-- Inheritance: UIComponent > UISlider
============================================================================]]--

--[[--
The Slider supports different input methods: buttons or faders/dials


### Dial mode / fader mode

  In most cases, you would specify a UISlider to take control of either a dial/encoder or fader. 

     _    _______   
    | |  |xxxx   | <- UISlider, mapped to horizontally aligned fader
    | |   ¯¯¯¯¯¯¯  <- UISlider, mapped to vertically aligned fader 
    |x|   _         
    |x|  ( )       <- UISlider mapped to "dial"
     ¯    ¯
  
  Specify an "on_change" function to handle events from the slider. 
  

### Button mode

  In button mode, each value-step of the slider is assigned to a separate button. The size of the resulting slider is determined by the size you specify when creating the slider (or, by using the set_size() after the slider has been created). 
     _    _______   
    |_|  |x|x|x| | <- horizontally aligned UISlider (mapped to 4 buttons)  
    |_|   ¯¯¯¯¯¯¯  <- vertically aligned UISlider (mapped to 4 buttons)
    |x|   _         
    |x|  | |       <- single-button UISlider (toggles min/max value)
     ¯    ¯

  To map a slider onto button(s), you must also specify an "on_press" event handler. The method does not have to do anything special, but without it,
  the slider will never receive any events from the device. 

  In "button mode", you also have an additional property called "toggleable". Setting this to true will enable you to toggle off any active button, and thus gain an extra value-step from any series of buttons. 

### Other features

- Built-in quantize for MIDI devices (only output when 7bit values change)
- Built-in support for relative encoder/dials. Note that the type of relative encoder is specified in your control-map

### Changelog

  0.99
    - Got rid of "dimmed" method (just call set_palette instead)

--]]

--==============================================================================

class 'UISlider' (UIComponent)

--------------------------------------------------------------------------------

--- Initialize the UISlider class
-- @param app (@{Duplex.Application})
-- @param map[opt] (table) mapping properties 

function UISlider:__init(app,map)
  TRACE('UISlider:__init')

  --- (bool) this flag indicates that input method is a button
  self._button_mode = false

  UIComponent.__init(self,app,map)

  --- current value, between 0 and .ceiling
  self.value = 0

  --- (int), set the number of steps to quantize the value
  -- (this value is automatically set when we assign a size)
  self.steps = 1

  --- (int) the selected index, between 0 - number of steps
  self.index = 0

  --- (bool) if true, press twice to switch to deselected state
  -- only applies when input method is a button
  self.toggleable = false

  --- (bool) flip top/bottom direction 
  self.flipped = false

  --- (bool) see @{Duplex.UIComponent}
  --self.soft_echo = true

  --- slider is ORIENTATION.VERTICAL or ORIENTATION.HORIZONTAL?
  -- (use set_orientation() method to set this value)
  self._orientation = ORIENTATION.VERTICAL 

  --- (int) the size in units (can be > 1 when input method is a button)
  -- (always call set_size() method to set this value)
  self._size = 1

  --- default palette (only relevant for button mode)
  -- @field background The background color 
  -- @field tip The active point
  -- @field track The track color
  -- @table palette
  self.palette = {
    background    = {color = {0x00,0x00,0x00}, text = "·", val=false},
    tip           = {color = {0xFF,0xFF,0xFF}, text = "▪", val=true},
    track         = {color = {0xD0,0xD0,0xD0}, text = "▪", val=true},
  }

  --- internal values
  self._cached_index = self.index
  self._cached_value = self.value

  -- apply size 
  self:set_size(self._size)
  
  -- apply UISlider-specific values from map
  if map and map.group_name then
    self.toggleable = map.toggleable or false
    self.flipped = map.flipped or false
    self._orientation = map.orientation or ORIENTATION.VERTICAL 
  end

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

  self.soft_echo = not msg.is_virtual and msg.xarg.soft_echo

  local idx = nil

  if (self._orientation == ORIENTATION.HORIZONTAL) or (self._orientation == ORIENTATION.VERTICAL) then
    idx = self:_determine_index_by_pos(msg.xarg.column, msg.xarg.row)
  else
    idx = msg.xarg.index
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

  --print("got here B")

  if not self:test(msg) then
    return 
  end

  self.soft_echo = not msg.is_virtual and msg.xarg.soft_echo

  if (self.on_change ~= nil) then
    
    local new_val = nil
    
    local is_midi_device = (self.app.display.device.protocol == DEVICE_PROTOCOL.MIDI)
    
    local is_relative_7 = ((msg.xarg.mode == "rel_7_signed") or 
      (msg.xarg.mode == "rel_7_signed2") or
      (msg.xarg.mode == "rel_7_offset") or
      (msg.xarg.mode == "rel_7_twos_comp"))
    
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
      if (msg.xarg.mode == "rel_7_signed") then
        if (msg.midi_msg[3] < 64) then
          new_val = math.max(new_val-(step_size*msg.midi_msg[3]),0)
        elseif (msg.midi_msg[3] > 64) then
          new_val = math.min(new_val+(step_size*(msg.midi_msg[3]-64)),self.ceiling)
        end
      elseif (msg.xarg.mode == "rel_7_signed2") then
        if (msg.midi_msg[3] > 64) then
          new_val = math.max(new_val-(step_size*(msg.midi_msg[3]-64)),0)
        elseif (msg.midi_msg[3] < 64) then
          new_val = math.min(new_val+(step_size*msg.midi_msg[3]),self.ceiling)
        end
      elseif (msg.xarg.mode == "rel_7_offset") then
        if (msg.midi_msg[3] < 64) then
          new_val = math.max(new_val-(step_size*(64-msg.midi_msg[3])),0)
        elseif (msg.midi_msg[3] > 64) then
          new_val = math.min(new_val+(step_size*(msg.midi_msg[3]-64)),self.ceiling)
        end
      elseif (msg.xarg.mode == "rel_7_twos_comp") then
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
      new_val = scale_value(msg.value,msg.xarg.minimum,msg.xarg.maximum,self.floor,self.ceiling)
    end

    if not self:output_quantize(new_val) then
      return 
    end

    self:set_value(new_val) 

  end 

  return self

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

--- Set the value (will also update the index)
-- @param val (float), a number between 0 and .ceiling
-- @param skip_event (bool) skip event handler

function UISlider:set_value(val,skip_event)
  TRACE("UISlider:set_value()",val,skip_event)

  --if (self.value == val) then
  --  print("*** UISlider:set_value - skip update, same value being set",val)
  --  return
  --end

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

--- Set index (will also update the value)
-- @param idx (integer) 
-- @param skip_event (bool) skip event handler

function UISlider:set_index(idx,skip_event)
  TRACE("UISlider:set_index()",idx,skip_event)

  --if (self.index == idx) then
  --  print("*** UISlider:set_index - skip update, same index being set",idx)
  --  return
  --end

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
-- (only relevant when assigned to buttons)

function UISlider:force_update()

  self.canvas.delta = table.rcopy(self.canvas.buffer)
  self.canvas.has_changed = true
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
-- @param size (number)
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

  if not (self.group_name == msg.xarg.group_name) then
    return false
  end

  if not self.app.active then
    return false
  end
  
  if (self._orientation == ORIENTATION.VERTICAL) or
    (self._orientation == ORIENTATION.HORIZONTAL)
  then
    return UIComponent.test(self,msg.xarg.column,msg.xarg.row)
  end

  -- no-orientation, fill the entire group
  return true

end


--------------------------------------------------------------------------------

--- Update the appearance - inherited from UIComponent
-- @see Duplex.UIComponent

function UISlider:draw()
  TRACE("UISlider:draw() - self.value",self.value)

  --print("*** UISlider:draw - self._button_mode",self._button_mode)

  if not self._button_mode then

    local point = CanvasPoint()
    point.val = self.value
    self.canvas:write(point, 1, 1)

  else

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
          point.val = self.palette.tip.val        
          point:apply(self.palette.tip)
        elseif (self.flipped) then
          if (i <= idx) then
            apply_track = true
          end
        elseif ((self._size - i) < self.index) then
          apply_track = true
        end
        
        if(apply_track)then
          point.val = self.palette.track.val        
          point:apply(self.palette.track)
        end

        self.canvas:write(point, x, y)
      end

    end
  end

  UIComponent.draw(self)

end


--------------------------------------------------------------------------------

--- Set the position using x/y or index within group
-- @see Duplex.UIComponent

function UISlider:set_pos(x,y)
  TRACE("UISlider:set_pos()")

  self:_detect_button_mode()
  --print("self._button_mode",self._button_mode)
    
  UIComponent.set_pos(self,x,y)

end

--------------------------------------------------------------------------------

--- Add event listeners
--    DEVICE_EVENT.BUTTON_PRESSED
--    DEVICE_EVENT.VALUE_CHANGED
-- @see Duplex.UIComponent.add_listeners

function UISlider:add_listeners()
  TRACE("UISlider:add_listeners()")

  self:remove_listeners()

  if self.on_press then
    self.app.display.device.message_stream:add_listener(
      self,DEVICE_EVENT.BUTTON_PRESSED,
      function(msg) return self:do_press(msg) end )
  end

  if self.on_change then
    self.app.display.device.message_stream:add_listener(
      self,DEVICE_EVENT.VALUE_CHANGED,
      function(msg) return self:do_change(msg) end )
  end

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


--------------------------------------------------------------------------------

--- Detect if the control is assigned to button widget(s)

function UISlider:_detect_button_mode()

  local button_mode = false
  local widgets = self:_get_widgets()
  for k,v in ipairs(widgets) do
    if (type(v) == "Button") then
      button_mode = true
      break
    end
  end

  if button_mode and (self.on_press == nil) then
    self.on_press = function()
      -- dummy method, allowing us to receive "press" events
    end
  end

  self._button_mode = button_mode

end


