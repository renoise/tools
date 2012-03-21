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

function UISlider:__init(display)
  TRACE('UISlider:__init')

  UIComponent.__init(self,display)

  -- current value, between 0 and .ceiling
  self.value = nil

  -- TODO the minimum value (the opposite of ceiling)
  -- self.floor = 0

  -- set the number of steps to quantize the value
  -- (this value is automatically set when we assign a size)
  self.steps = 1

  -- the selected index, between 0 - number of steps
  self.index = nil

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
    background = table.rcopy(display.palette.background),
    tip = table.rcopy(display.palette.color_1),
    tip_dimmed = table.rcopy(display.palette.color_1_dimmed),
    track = table.rcopy(display.palette.color_2),
    track_dimmed = table.rcopy(display.palette.color_2_dimmed),
  }

  -- internal values
  self._cached_index = self.index
  self._cached_value = self.value

  -- attach ourself to the display message stream
  self:add_listeners()

end


--------------------------------------------------------------------------------

-- user input via button(s)
-- set index

function UISlider:do_press()
  TRACE("UISlider:do_press()")

  local msg = self:get_msg()

  if not (self.group_name == msg.group_name) then
    return
  end

  if not (self:test(msg.column, msg.row)) then
    return
  end

  local idx = self:_determine_index_by_pos(msg.column, msg.row)
  if (self.toggleable and self.index == idx) then
    idx = 0
  end

  self.set_index(self,idx)

end


--------------------------------------------------------------------------------

-- user input via button(s)
-- the release handler is here to force-update controls   
-- that handle their internal state automatically

function UISlider:do_release()
  TRACE("UISlider:do_press()")

  local msg = self:get_msg()
  if not (self.group_name == msg.group_name) then
    return
  end
  if not (self:test(msg.column, msg.row)) then
    return
  end
  if (msg.input_method == CONTROLLER_PUSHBUTTON) then
    self.canvas.delta = table.rcopy(self.canvas.buffer)
    self.canvas.has_changed = true
    self:invalidate()
  end

end

--------------------------------------------------------------------------------

-- user input via slider, dial: 
-- set index + precise value within the index

function UISlider:do_change()
  --TRACE("UISlider:do_change()")

  local msg = self:get_msg()

  if not (self.group_name == msg.group_name) then
    return
  end
  if not self:test(msg.column,msg.row) then
    return
  end
  -- scale from the message range to the sliders range
  local val = (msg.value / msg.max) * self.ceiling
  self:set_value(val)
end


--------------------------------------------------------------------------------

-- setting value will also set index
-- @val (float) 
-- @skip_event (boolean) skip event handler

function UISlider:set_value(val,skip_event)
  TRACE("UISlider:set_value()",val,skip_event)

  local idx = math.abs(math.ceil(((self.steps/self.ceiling)*val)-0.5))
  if (self._cached_index ~= idx) or
     (self._cached_value ~= val) 
  then
    self._cached_index = idx
    self._cached_value = val
    self.value = val
    self.index = idx

    if (skip_event) then
      self:invalidate()
    else
      self:_invoke_handler()
    end
  end  
end


--------------------------------------------------------------------------------

-- setting index will also set value
-- @idx (integer) 
-- @skip_event (boolean) skip event handler

function UISlider:set_index(idx,skip_event)
  TRACE("UISlider:set_index()",idx,skip_event)

  -- todo: cap value
  local rslt = false
  if (self._cached_index ~= idx) then
    self._cached_index = idx
    self._cached_value = self.value
    self.index = idx
    self.value = (idx~=0) and ((self.ceiling/self.steps)*idx) or 0

    if (skip_event) then
      self:invalidate()
    else
      self:_invoke_handler()
    end

  end
end


--------------------------------------------------------------------------------

function UISlider:set_dimmed(bool)
  -- TODO: only invalidate if we can dimm
  self.dimmed = bool
  self:invalidate()
end


--------------------------------------------------------------------------------

function UISlider:set_orientation(value)
  TRACE("UISlider:set_orientation",value)

  if (value == HORIZONTAL) or (value == VERTICAL) then
    self._orientation = value
    self:set_size(self._size) -- update canvas
  end
end

function UISlider:get_orientation()
  TRACE("UISlider:get_orientation()")
  return self._orientation
end


--------------------------------------------------------------------------------
-- Overridden from UIComponent
--------------------------------------------------------------------------------

-- setting the size will change the canvas too
-- @size (integer)

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

-- update the UIComponent canvas

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
          -- ensure that monochrome devices get this right! 
          local color = self.palette.tip.color
          local quantized = self._display.device:quantize_color(color)
          if(quantized[1]>0x00)then
            point.val = true        
          else
            point.val = false        
          end
          point:apply((self.dimmed) and 
            self.palette.tip_dimmed or self.palette.tip)
        elseif (self.flipped) then
          if (i <= idx)then
            apply_track = true
          end
        elseif ((self._size - i) < self.index) then
          apply_track = true
        end
        
        if(apply_track)then
          local color = self.palette.track.color
          local quantized = self._display.device:quantize_color(color)
          if(quantized[1]>0x00)then
            point.val = true        
          else
            point.val = false        
          end
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

function UISlider:add_listeners()

  self._display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED,
    function() self:do_press() end )

  self._display.device.message_stream:add_listener(
    self,DEVICE_EVENT_VALUE_CHANGED,
    function() self:do_change() end )

  self._display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_RELEASED,
    function() self:do_release() end )

end


--------------------------------------------------------------------------------

function UISlider:remove_listeners()

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

-- determine index by position, depends on orientation
-- @column (integer)
-- @row (integer)

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

-- trigger the external handler method

function UISlider:_invoke_handler()

  if (self.on_change == nil) then return end

  local rslt = self:on_change()  
  if (rslt==false) then  -- revert
    self.index = self._cached_index    
    self.value = self._cached_value  

  else
    self:invalidate()
  end
end


