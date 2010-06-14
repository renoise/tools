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

  -- the current index
  self.index = 0

  -- increase/decrease index by how much?
  self.step_size = 1

  -- the min/max index
  self.minimum = 0
  self.maximum = 1

  -- draw vertical or horizontal?
  self.orientation = HORIZONTAL 

  -- flip top/bottom direction 
  self.flipped = false

  self.palette = {
    foreground_dec = table.rcopy(display.palette.color_1), -- decrease
    foreground_inc = table.rcopy(display.palette.color_1), -- increase
    background = table.rcopy(display.palette.background)
  }

  -- private stuff
  self.__cached_index = self.index
  self.__size = 2

  self:set_size(self.__size)
  self.add_listeners(self)
end


--------------------------------------------------------------------------------

-- user input via button

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
    local idx = self.determine_index_by_pos(self, msg.column,msg.row)

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
      error("internal error: expected an index of 1 or 2")
    end

    if (changed) then
      self:invoke_handler()
    end
  end
end


--------------------------------------------------------------------------------

-- set index to specified value
-- @idx (integer)
-- @skip_event (boolean) skip event handler

function UISpinner:set_index(idx, skip_event)
  assert(idx >= self.minimum and idx <= self.maximum, 
    "invalid spinner index")
  
  local changed = false
  
  if (self.index ~= idx) then
    self.__cached_index = self.index
    self.index = idx
    changed = true
  end

  if (changed) then
    if (not skip_event) then
      self:invoke_handler()
    else
      self:invalidate()
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
    assert(self.orientation == HORIZONTAL)
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

  local point1 = CanvasPoint()
  local point2 = CanvasPoint() 

  if (self.minimum == self.maximum) then        -- [ ][ ]
    point1:apply(self.palette.background)
    point2:apply(self.palette.background)
  
  elseif (self.index == self.minimum) then      -- [ ][x]
    point1:apply(self.palette.background)
    point2:apply(self.palette.foreground_inc)
  
  elseif (self.index == self.maximum) then      -- [x][ ]
    point1:apply(self.palette.foreground_dec)
    point2:apply(self.palette.background)
  
  else                                          -- [x][x]
    point1:apply(self.palette.foreground_dec)
    point2:apply(self.palette.foreground_inc)
  end

  if (self.orientation == HORIZONTAL) then
    self.canvas:write(point1,1,1)
    self.canvas:write(point2,2,1)
  
  else
    assert(self.orientation == VERTICAL)
    self.canvas:write(point1,1,1)
    self.canvas:write(point2,1,2)
  end

  UIComponent.draw(self)
end


--------------------------------------------------------------------------------

-- set_size()  - omit this - only 2 is really accepted! 

function UISpinner:set_size(size)
  self.__size = 2
  
  if self.orientation == VERTICAL then
    UIComponent.set_size(self, 1, self.__size)
  
  else
    UIComponent.set_size(self, self.__size, 1)
  end
end


--------------------------------------------------------------------------------

function UISpinner:add_listeners()

  self.display.device.message_stream:add_listener(
    self, DEVICE_EVENT_BUTTON_PRESSED,
    function() self:do_press() end )
end


--------------------------------------------------------------------------------

function UISpinner:remove_listeners()

  self.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED)
end

