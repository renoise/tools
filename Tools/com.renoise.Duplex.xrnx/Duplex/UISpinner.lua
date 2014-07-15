--[[============================================================================
-- Duplex.UISpinner
-- Inheritance: UIComponent > UISpinner
============================================================================]]--

--[[--
UISpinner makes it possible to select among a list of options

*This UIComponent has been deprecated in Duplex 0.98*

Flexible operating mode depend on if the unit-size is set to 1 or 2:
1 ( ) - single dial, will trigger event for each quantized value
2 [<][>]  - two buttons, for next/previous style operation

Supported input methods

- use "button" type input (next/previous buttons)
- use "dial" or "slider" (outputs quantized values)

--]]

--==============================================================================

class 'UISpinner' (UIComponent)

--------------------------------------------------------------------------------

--- Initialize the UISpinner class
-- @param app (@{Duplex.Application})
-- @param map[opt] (table) mapping properties 

function UISpinner:__init(app,map)
  TRACE('UISpinner:__init',app,map)

  UIComponent.__init(self,app,map)

  -- the current index (for buttons)
  self.index = 0
  self.value = 0

  -- increase/decrease index by how much?
  self.step_size = 1

  -- the min/max index
  self.minimum = 0
  self.maximum = 1

  -- up/down or left/right arrows?
  -- if specified, text arrows will appear
  self.text_orientation = ORIENTATION.HORIZONTAL 

  -- flip direction 
  self.flipped = false

  self.palette = {
    foreground_dec = {color={0xff,0xff,0xff}},
    foreground_inc = {color={0xff,0xff,0xff}},
    background = {color={0x00,0x00,0x00}},
    up_arrow = {text="▲"},
    down_arrow = {text="▼"},
    left_arrow = {text="◄"},
    right_arrow = {text="►"},
  }
  
  -- draw ORIENTATION.VERTICAL or ORIENTATION.HORIZONTAL?
  self._orientation = ORIENTATION.HORIZONTAL 

  -- internal stuff
  self._cached_index = self.index

  self._size = 2
  self:set_size(self._size)

end


--------------------------------------------------------------------------------

--- A value was changed (fader, dial)
-- @param msg (@{Duplex.Message})
-- @return bool or nil

function UISpinner:do_change(msg)
  TRACE("UISpinner:do_change",msg)

  if not self:test(msg) then
    return
  end

  if (self.on_change ~= nil) then

    -- restrict the value to fit within the range 
    self.value = (msg.value / ((msg.xarg.maximum-msg.xarg.minimum) /
      (self.maximum - self.minimum))) + self.minimum

    local index = math.floor(self.value+.5)

    if (index ~= self.index) then
      self._cached_index = self.index
      self.index = index
      self:_invoke_handler()
    end

  end

  return self

end


--------------------------------------------------------------------------------

--- A button was pressed
-- @param msg (@{Duplex.Message})
-- @return bool or nil

function UISpinner:do_press(msg)
  TRACE("UISpinner:do_press",msg)
  
  if not self:test(msg) then
    return 
  end

  if (self.on_change ~= nil) then
    
    local changed = false
    local idx = self:_determine_index_by_pos(msg.xarg.column,msg.xarg.row)
    -- increase/decrease index
    if (idx == 1) then
      if (self.index > self.minimum) then
        self._cached_index = self.index
        self.index = math.floor(self.index-self.step_size)
        
        if (self.index < self.minimum) then
          self.index = self.minimum
        end
        
        changed = true
      end
    
    elseif (idx == 2)then
      if (self.index < self.maximum) then
        self._cached_index = self.index
        self.index = math.floor(self.index+self.step_size)
        
        if (self.index > self.maximum) then
          self.index = self.maximum
        end
        
        changed = true
      end
    
    else
      error(("Internal Error. Please report: " .. 
        "expected a spinner index of 1 or 2"))
    end


    if (changed) then
      self.value = self.index
      self:_invoke_handler()
    end

  end

  if (msg.xarg.type == "togglebutton") then
    -- force update togglebuttons...
    self:force_refresh()
  end

  return self

end


--------------------------------------------------------------------------------

--- Set the slider orientation 
-- (only relevant when assigned to buttons)
-- @param value (@{Duplex.Globals.ORIENTATION}) 

function UISpinner:set_orientation(value)
  TRACE("UISpinner:set_orientation",value)

  if (value == ORIENTATION.HORIZONTAL) or (value == ORIENTATION.VERTICAL) then
    self._orientation = value
    self:set_size(self._size) -- update canvas
  end
end

--------------------------------------------------------------------------------

--- Get the orientation 
-- @return @{Duplex.Globals.ORIENTATION}

function UISpinner:get_orientation()
  TRACE("UISpinner:get_orientation()")
  return self._orientation
end

--------------------------------------------------------------------------------

--- Set a new value range, clipping the current index when needed (you can set 
--  just one value, since we skip nil values)
-- @param minimum (number)
-- @param maximum (number)

function UISpinner:set_range(minimum,maximum)
  TRACE("UISpinner:set_range",minimum,maximum)

  local changed = false

  if (minimum) and (self.minimum ~= minimum) then
    self.minimum = minimum
    changed = true
  end

  if (maximum) and (self.maximum ~= maximum) then
    self.maximum = maximum
    self.ceiling = maximum
    changed = true
  end

  if(changed)then

    if (self.minimum > self.maximum) then
      self.minimum, self.maximum = self.maximum, self.minimum
    end

    if (self.index > self.maximum) then
      self:set_index(self.maximum)
    elseif (self.index < self.minimum) then
      self:set_index(self.minimum)
    end

    self:invalidate()
  end

end
  
  
--------------------------------------------------------------------------------

--- Set index to specified value
-- @param idx (int)
-- @param skip_event_handler (bool) skip event handler

function UISpinner:set_index(idx, skip_event_handler)
  TRACE("UISpinner:set_index",idx, skip_event_handler)

  if(idx < self.minimum or idx > self.maximum)then
    --print("Notice: tried to set an invalid index for a UISpinner")
    return
  end

  local changed = false
  
  if (self.index ~= idx) then
    self._cached_index = self.index
    self.index = idx
    self.value = idx
    changed = true
  end

  if (changed) then
    self:invalidate()

    if (not skip_event_handler) then
      self:_invoke_handler()
    end
  end
end


--------------------------------------------------------------------------------
-- Overridden from UIComponent
--------------------------------------------------------------------------------

--- Update the appearance - inherited from UIComponent
-- @see Duplex.UIComponent

function UISpinner:draw()
  TRACE("UISpinner:draw")

  if (self._size == 1)then

    -- dial mode : set precise value

    local point = CanvasPoint()
    point.val = self.value
    self.canvas:write(point,1,1)

  else
  
    -- button mode : set state

    local point1 = CanvasPoint()
    local point2 = CanvasPoint() 
    local blank = {text="·"}
    local arrow1,arrow2 = blank,blank

    if(self.text_orientation == ORIENTATION.HORIZONTAL)then
      arrow1 = self.palette.left_arrow
      arrow2 = self.palette.right_arrow
    elseif(self.text_orientation == ORIENTATION.VERTICAL)then
      arrow1 = self.palette.up_arrow
      arrow2 = self.palette.down_arrow
    end

    if (self.minimum == self.maximum) then        -- [ ][ ]     
      point1:apply(self.palette.background)
      point1:apply(blank)
      point1.val = false
      point2:apply(self.palette.background)
      point2:apply(blank)
      point2.val = false
    elseif (self.index == self.minimum) then      -- [ ][▼]
      point1:apply(self.palette.background)
      point1:apply(blank)
      point1.val = false
      point2:apply(self.palette.foreground_inc)
      point2:apply(arrow2)
      point2.val = true
    elseif (self.index == self.maximum) then      -- [▲][ ]
      point1:apply(self.palette.foreground_dec)
      point1:apply(arrow1)
      point1.val = true
      point2:apply(self.palette.background)
      point2:apply(blank)
      point2.val = false
    else                                          -- [▲][▼]
      point1:apply(self.palette.foreground_dec)
      point1:apply(arrow1)
      point1.val = true
      point2:apply(self.palette.foreground_inc)
      point2:apply(arrow2)
      point2.val = true
    end

    if (self._orientation == ORIENTATION.HORIZONTAL) then

      if (self.flipped) then
        self.canvas:write(point1,2,1)
        self.canvas:write(point2,1,1)
      else
        self.canvas:write(point1,1,1)
        self.canvas:write(point2,2,1)
      end
    
    else
      assert(self._orientation == ORIENTATION.VERTICAL, 
        "Internal Error. Please report: unexpected UI orientation")

      if (self.flipped) then
        self.canvas:write(point1,1,2)
        self.canvas:write(point2,1,1)
      else
        self.canvas:write(point1,1,1)
        self.canvas:write(point2,1,2)
      end

    end

  end

  UIComponent.draw(self)
end


--------------------------------------------------------------------------------

--- Override UIComponent with this method
-- @param size (int) the size in units
-- @see Duplex.UIComponent

function UISpinner:set_size(size)
  
  self._size = size
  
  if self._orientation == ORIENTATION.VERTICAL then
    UIComponent.set_size(self, 1, self._size)
  else
    UIComponent.set_size(self, self._size, 1)
  end
end


--------------------------------------------------------------------------------

--- Add event listeners
--    DEVICE_EVENT.BUTTON_PRESSED
--    DEVICE_EVENT.VALUE_CHANGED
-- @see Duplex.UIComponent

function UISpinner:add_listeners()

  self:remove_listeners()

  if self.on_press then
    self.app.display.device.message_stream:add_listener(
      self, DEVICE_EVENT.BUTTON_PRESSED,
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

function UISpinner:remove_listeners()

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT.BUTTON_PRESSED)

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT.VALUE_CHANGED)

end


--------------------------------------------------------------------------------
-- Private
--------------------------------------------------------------------------------

--- Determine index by position
-- @param column (int)
-- @param row (int)
-- @return (int)

function UISpinner:_determine_index_by_pos(column, row)

  local idx,offset = nil,nil

  if (self._orientation == ORIENTATION.VERTICAL) then
    idx = row
    offset = self.y_pos

  else
   assert(self._orientation == ORIENTATION.HORIZONTAL, 
      "Internal Error. Please report: unexpected UI orientation")
    idx = column
    offset = self.x_pos
  end
  

  local idx = idx - (offset - 1)
  if (self.flipped) then
    idx = math.abs((idx-1)-(offset-1))
  end

  return idx
end


--------------------------------------------------------------------------------

--- Trigger the external handler method

function UISpinner:_invoke_handler()
  TRACE("UISpinner:_invoke_handler()")

  if (self.on_change == nil) then return end

  local rslt = self:on_change()
  if (rslt==false) then  -- revert
    self.index = self._cached_index
  else
    self:invalidate()
  end

end

