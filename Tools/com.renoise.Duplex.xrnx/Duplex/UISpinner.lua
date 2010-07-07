--[[----------------------------------------------------------------------------
-- Duplex.UISpinner
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UISpinner
Requires: Globals, Display, CanvasPoint

About:

UISpinner makes it possible to select among a list of options
Imagine a list going from 1-5. This is how it could be displayed: 

[ ][x] (this is how 1 is displayed)
[x][x] (this is how 2/3/4 is displayed)
[x][ ] (this is how 5 is displayed)

- good for stuff like switching between pages 
- supports vertical/horizontal and axis flipping
- fixed size: 2 (two units spanned)

Events

  on_press() - invoked whenever the button is pressed

--]]


--==============================================================================

class 'UISpinner' (UIComponent)

function UISpinner:__init(display)
  TRACE('UISpinner:__init',display)

  UIComponent.__init(self,display)

  -- the current index (for buttons)
  self.index = 0
  self.value = 0

  -- increase/decrease index by how much?
  self.step_size = 1

  -- the min/max index
  self.minimum = 0
  self.maximum = 1

  -- draw vertical or horizontal?
  self.orientation = HORIZONTAL 

  -- up/down or left/right arrows?
  -- if specified, text arrows will appear
  self.text_orientation = HORIZONTAL 

  -- flip direction 
  self.flipped = false

  self.palette = {
    foreground_dec = {color=display.palette.color_1.color},
    foreground_inc = {color=display.palette.color_1.color},
    background = {color=display.palette.background.color},
    up_arrow = {text="▲"},
    down_arrow = {text="▼"},
    left_arrow = {text="◄"},
    right_arrow = {text="►"},
  }
  
  -- private stuff
  self.__cached_index = self.index
  self.__size = 2
  self:set_size(self.__size)
  self.add_listeners(self)
end

--------------------------------------------------------------------------------

-- user input via slider, encoder,
-- set index from entire range

function UISpinner:do_change()
  TRACE("UISpinner:do_change()")

  local msg = self.get_msg(self)
  
  if not (self.group_name == msg.group_name) then
    return
  end
  
  if not self:test(msg.column,msg.row) then
    return
  end

  self.value = msg.value/(msg.max/self.maximum)

  local step = msg.max/(self.maximum-self.minimum+1)
  local index = math.max(math.ceil(msg.value/step),1)-1

  if(index~=self.index)then
    self.index = index
    self:invoke_handler()
  end


end

--------------------------------------------------------------------------------

-- user input via button(s)

function UISpinner:do_press()
  TRACE("UISpinner:do_press")
  
  if (self.on_press ~= nil) then
    local msg = self.get_msg(self)
    
    if not (self.group_name == msg.group_name) then
      return 
    end
    
    if not self.test(self,msg.column,msg.row) then
      return 
    end

    local changed = false
    local idx = self:determine_index_by_pos(msg.column,msg.row)

    -- increase/decrease index
    if (idx == 1) then
      if (self.index > self.minimum) then
        self.__cached_index = self.index
        self.index = self.index - self.step_size
        
        if (self.index < self.minimum) then
          self.index = self.minimum
        end
        
        changed = true
      end
    
    elseif (idx == 2)then
      if (self.index < self.maximum) then
        self.__cached_index = self.index
        self.index = self.index + self.step_size
        
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
      self:invoke_handler()
    end
  end
end


--------------------------------------------------------------------------------

-- set a new minimum value for the index, clipping the current index when needed

function UISpinner:set_minimum(value)
  TRACE("UISpinner:set_minimum",value)
  if (self.minimum ~= value) then
    self.minimum = value
    
    if (self.minimum > self.maximum) then
      self.minimum, self.maximum = self.maximum, self.minimum
    end

    if (self.index < self.maximum) then
      self:set_index(self.maximum)
    end
    
    self:invalidate()
  end
end


--------------------------------------------------------------------------------

-- set a new maximum value for the index, clipping the current index when needed

function UISpinner:set_maximum(value)
  TRACE("UISpinner:set_maximum",value)

  if (self.maximum ~= value) then
    self.maximum = value
    self.ceiling = value
    
    if (self.minimum > self.maximum) then
      self.minimum, self.maximum = self.maximum, self.minimum
    end
    
    if (self.index > self.maximum) then
      self:set_index(self.maximum)
    end
    
    self:invalidate()
  end
end
  
  
--------------------------------------------------------------------------------

-- set index to specified value
-- @idx (integer)
-- @skip_event (boolean) skip event handler

function UISpinner:set_index(idx, skip_event_handler)
  TRACE("UISpinner:set_index",idx, skip_event_handler)
  assert(idx >= self.minimum and idx <= self.maximum, 
    "Internal Error. Please report: invalid index for a spinner")

  local changed = false
  
  if (self.index ~= idx) then
    self.__cached_index = self.index
    self.index = idx
    self.value = idx
    changed = true
  end

  if (changed) then
    self:invalidate()

    if (not skip_event_handler) then
      self:invoke_handler()
    end
  end
end


--------------------------------------------------------------------------------

-- determine index by position, depends on orientation
-- @column (integer)
-- @row (integer)

function UISpinner:determine_index_by_pos(column, row)

  local pos,offset = nil,nil

  if (self.orientation == VERTICAL) then
    pos = row
    offset = self.y_pos
  else
   assert(self.orientation == HORIZONTAL, 
      "Internal Error. Please report: unexpected UI orientation")
      
    pos = column
    offset = self.x_pos
  end
  
  if (self.flipped) then
    pos = self.__size - pos + 1
  end
  
  local idx = pos - (offset - 1)
  return idx
end


--------------------------------------------------------------------------------

-- trigger the external handler method

function UISpinner:invoke_handler()
  TRACE("UISpinner:invoke_handler()")

  local rslt = self.on_press(self)
  if not rslt then  -- revert
    self.index = self.__cached_index
  else
    self:invalidate()
  end

end


--------------------------------------------------------------------------------

function UISpinner:draw()
  TRACE("UISpinner:draw")

  if(self.__size==1)then

    -- dial mode : set precise value

    local point = CanvasPoint()
    point.val = self.value
    self.canvas:write(point,1,1)

  else
  
    -- button mode : set state

    local point1 = CanvasPoint()
    local point2 = CanvasPoint() 
    local blank = {text=""}
    local arrow1,arrow2 = blank,blank

    if(self.text_orientation == HORIZONTAL)then
      arrow1 = self.palette.left_arrow
      arrow2 = self.palette.right_arrow
    elseif(self.text_orientation == VERTICAL)then
      arrow1 = self.palette.up_arrow
      arrow2 = self.palette.down_arrow
    end

    if (self.minimum == self.maximum) then        -- [ ][ ]
      point1:apply(self.palette.background)
      point1:apply(blank)
      point2:apply(self.palette.background)
      point2:apply(blank)
    elseif (self.index == self.minimum) then      -- [ ][▼]
      point1:apply(self.palette.background)
      point1:apply(blank)
      point2:apply(self.palette.foreground_inc)
      point2:apply(arrow2)
    elseif (self.index == self.maximum) then      -- [▲][ ]
      point1:apply(self.palette.foreground_dec)
      point1:apply(arrow1)
      point2:apply(self.palette.background)
      point2:apply(blank)
    else                                          -- [▲][▼]
      point1:apply(self.palette.foreground_dec)
      point1:apply(arrow1)
      point2:apply(self.palette.foreground_inc)
      point2:apply(arrow2)
    end

    if (self.orientation == HORIZONTAL) then
      self.canvas:write(point1,1,1)
      self.canvas:write(point2,2,1)
    
    else
      assert(self.orientation == VERTICAL, 
        "Internal Error. Please report: unexpected UI orientation")

      self.canvas:write(point1,1,1)
      self.canvas:write(point2,1,2)
    end

  end

  UIComponent.draw(self)
end


--------------------------------------------------------------------------------

-- set_size()  - omit this - only 2 is really accepted! 

function UISpinner:set_size(size)
  
  self.__size = size
  
  if self.orientation == VERTICAL then
    UIComponent.set_size(self, 1, self.__size)
  
  else
    UIComponent.set_size(self, self.__size, 1)
  end
end


--------------------------------------------------------------------------------

function UISpinner:add_listeners()

  self.__display.device.message_stream:add_listener(
    self, DEVICE_EVENT_BUTTON_PRESSED,
    function() self:do_press() end )


  self.__display.device.message_stream:add_listener(
    self,DEVICE_EVENT_VALUE_CHANGED,
    function() self:do_change() end )

end


--------------------------------------------------------------------------------

function UISpinner:remove_listeners()

  self.__display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED)

  self.__display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_VALUE_CHANGED)


end

