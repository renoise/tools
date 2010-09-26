--[[----------------------------------------------------------------------------
-- Duplex.UIButtonStrip
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UIButtonStrip

--

About

The UIButtonStrip is an array of buttons that control an active index/range, 
especially useful for controlling a sequence with an a looped region. 

In addition to the basic set_range() and set_index() methods, there's two
additional methods, start/stop_blink(), which are used by the Matrix app
to display that a pattern has been scheduled.


This control has a number of interaction modes:

----------------------------------------------------------------------------

1:  MODE_NORMAL - set range/index using button combinations 
    
    In this mode, you set the index by pressing a button and releasing it, 
    or set the range by pressing multiple buttons at the same time, and then 
    releasing either. 
    
    To toggle the range on/off, you press and hold a button for a moment, 
    until the "button_held" event is triggered - this will toggle the range 
    on/off (note that when turned on in this way, it's length is always one,
    as this length is otherwise unobtainable).

    Events

      on_index_change
      on_range_change
      on_press
      on_release
      on_hold

    Supported input methods

      "button"

----------------------------------------------------------------------------

2:  MODE_INDEX - togglebutton compatible mode, only index can be set

    Events

      on_index_change
      on_press
      on_release*
      on_hold*

    Supported input methods

      "button"
      "togglebutton"

    * "togglebutton" not supported 


----------------------------------------------------------------------------

3:  MODE_BASIC - free mode, supply your own logic

    It's up to you to decide what happens when events are received, only
    basic operation (events, visual updates) are taken care of

    Events

      on_press 
      on_release*
      on_hold*

    Supported input methods

      "button"
      "togglebutton" 

    * "togglebutton" not supported 

----------------------------------------------------------------------------

Display logic 

For color displays, it's possible to differentiate 
between the index and range

[ ] = Background
[x] = Selected index
[o] = Range

[x][o][o][o][ ][ ] <- Index set to 1, range set to 1,4
[o][o][x][o][ ][ ] <- Index set to 3, range set to 1,4
[o][o][o][o][ ][x] <- Index set to 6, range set to 1,4

TIP : For monochromatic devices / LED buttons, if the "index" color 
is identical to the "range" color, the draw() method will use
an alternative/inverted color scheme.

[ ]     = Background
[x]/[ ] = Selected index
[x]     = Range

[ ][x][x][x][ ][ ] <- Index set to 1, range set to 1,4
[x][x][ ][x][ ][ ] <- Index set to 3, range set to 1,4
[x][x][x][x][ ][x] <- Index set to 6, range set to 1,4


--]]


--==============================================================================

class 'UIButtonStrip' (UIComponent)

function UIButtonStrip:__init(display)
  TRACE('UIButtonStrip:__init')

  UIComponent.__init(self,display)

  self.MODE_NORMAL = 1
  self.MODE_INDEX = 2
  self.MODE_BASIC = 3

  self.mode = self.MODE_NORMAL

  self.palette = {
    index = table.rcopy(display.palette.color_1),
    range = table.rcopy(display.palette.color_1_dimmed), 
    background = table.rcopy(display.palette.background)
  }

  self.add_listeners(self)
  
  -- if true, press selected index to toggle on/off
  self.toggleable = false

  -- if true, use alternative display method
  self.monochrome = false

  -- TODO flip top/bottom direction when setting/retrieving index/range
  --self.flipped = false

  -- TODO vertical or horizontal orientation?
  self.orientation = VERTICAL 

  -- external event handlers
  self.on_press = nil
  self.on_release = nil
  self.on_hold = nil
  self.on_index_change = nil
  self.on_range_change = nil

  -- internal stuff
  self.__held_event_fired = false
  self.__range_set = false
  self.__pressed_idx = nil
  self.__blink_idx = 0
  self.__blink_is_lit = nil
  self.__blink_task = nil
  self.__blink_interval = 0.5
  self.__size = nil
  self.__range = {0,0}
  self.__index = 0
  self.__cached_index = self.__index
  self.__cached_range = self.__range

end


--------------------------------------------------------------------------------

function UIButtonStrip:do_press()
  TRACE("UIButtonStrip:do_press()")

  local msg = self:get_msg()

  if not (self.group_name == msg.group_name) then
    return 
  end
  if not self:test(msg.column,msg.row) then
    return 
  end

  local idx = self:__determine_index_by_pos(msg.column, msg.row)

  if (self.mode == self.MODE_NORMAL) then
    if not (self.__pressed_idx) then
      -- this is the first button being pressed, remember it
      self.__pressed_idx = idx
      self.__held_event_fired = false
      self.__range_set = false
    else
      -- we are pressing multiple buttons - set the active range
      self:set_range(idx,self.__pressed_idx)
      self.__range_set = true
    end
  elseif (self.mode == self.MODE_INDEX) then
    if (self.toggleable) and (idx==self.__index) then
      self:set_index(0)
    else
      self:set_index(idx)
    end
  end

  if (self.on_press ~= nil) then
    self:on_press()
  end

end

--------------------------------------------------------------------------------

function UIButtonStrip:do_release()
  TRACE("UIButtonStrip:do_release()")

  local msg = self:get_msg()

  if not (self.group_name == msg.group_name) then
    return 
  end

  if not self:test(msg.column,msg.row) then
    return 
  end

  if (self.mode == self.MODE_NORMAL) then
    -- set index when the first button is being released
    local idx = self:__determine_index_by_pos(msg.column, msg.row)

    if (idx==self.__pressed_idx) then
      self.__pressed_idx = nil
      if (not self.__held_event_fired) and (not self.__range_set) then
        if (self.toggleable) and (idx==self.__index) then
          self:set_index(0)
        else
          self:set_index(idx)
        end
      end
    end
  end

  if (self.on_release ~= nil) then
    self:on_release()
  end

end

--------------------------------------------------------------------------------

function UIButtonStrip:do_hold()
  TRACE("UIButtonStrip:do_hold()")

  local msg = self:get_msg()

  if not (self.group_name == msg.group_name) then
    return 
  end

  if not self:test(msg.column,msg.row) then
    return 
  end

  if (self.mode == self.MODE_NORMAL) then
    -- toggle current range when held
    if (not self.__range_set) then
      if (self.__range[1]~=0) then
        self:set_range(0,0)
      else
        local idx = self:__determine_index_by_pos(msg.column, msg.row)
        self:set_range(idx,idx)
      end
      self.__range_set = false
    end
    self.__held_event_fired = true
  end


  if (self.on_hold ~= nil) then
    self:on_hold()
  end

end

--------------------------------------------------------------------------------

function UIButtonStrip:draw()
  TRACE("UIButtonStrip:draw")

  for idx = 1,self.__size do

    local point = CanvasPoint()
    local x,y = 1,1

    if self.__blink_idx and
      (idx==self.__blink_idx) and
      (self.__blink_is_lit) then
      -- a blinking, lit button
      point:apply(self.palette.index)
    elseif (idx == self.__index) and
      (idx~=self.__blink_idx) then
      -- selected index (not blinking)
      if not self.monochrome then
        point:apply(self.palette.index)
      else
        if (self:__in_range(idx)) then
          point:apply(self.palette.background)
        else
          point:apply(self.palette.index)
        end
      end
    elseif not self:__in_range(idx) then
      -- background
      point:apply(self.palette.background)
    else
      -- inside range
      if not self.monochrome then
        point:apply(self.palette.range)
      else
        point:apply(self.palette.index)
      end
    end

    if (self.orientation == VERTICAL) then 
      y = idx
    else
      x = idx
    end

    self.canvas:write(point, x, y)

  end

  UIComponent.draw(self)

end

--------------------------------------------------------------------------------

function UIButtonStrip:set_index(idx,skip_event)
  TRACE("UIButtonStrip:set_index()",idx)
  
  self.__cached_index = self.__index
  self.__index = idx

  if (not skip_event) and (self.on_index_change~=nil) then
    local rslt = self:on_index_change()  
    if (rslt==false) then  -- revert
      self.__index = self.__cached_index    
    else
      self:invalidate()
    end
  else
    self:invalidate()
  end


end

--------------------------------------------------------------------------------

function UIButtonStrip:get_index()
  --TRACE("UIButtonStrip:get_index()")
  return self.__index
end

--------------------------------------------------------------------------------

function UIButtonStrip:set_range(idx1,idx2,skip_event)
  TRACE("UIButtonStrip:set_range()",idx1,idx2)


  -- swap values if needed (first should be lowest)
  if (idx1>idx2) then
    idx1,idx2 = idx2,idx1
  end

  self.__cached_range = self.__range
  self.__range = {idx1,idx2}
  if (not skip_event) and (self.on_range_change~=nil) then
    local rslt = self:on_range_change()  
    if (rslt==false) then  -- revert
      self.__range = self.__cached_range  
    else
      self:invalidate()
    end
  else
    self:invalidate()
  end

end

--------------------------------------------------------------------------------

function UIButtonStrip:get_range()
  TRACE("UIButtonStrip:get_index()")
  return self.__range
end


--------------------------------------------------------------------------------

function UIButtonStrip:start_blink(idx)
  TRACE("UIButtonStrip:start_blink()",idx)

  self:stop_blink()
  self.__blink_idx = idx
  self.__blink_is_lit = false
  self:__toggle_blink()

end

--------------------------------------------------------------------------------

function UIButtonStrip:pause_blink(idx)
  TRACE("UIButtonStrip:pause_blink()",idx)

  if self.__blink_task then
    self.__display.scheduler:remove_task(self.__blink_task)
  end
  self.__blink_is_lit = false
  self:invalidate()

end

--------------------------------------------------------------------------------

function UIButtonStrip:stop_blink()
  TRACE("UIButtonStrip:stop_blink()")

  self.__blink_idx = 0
  if self.__blink_task then
    self.__display.scheduler:remove_task(self.__blink_task)
  end

end


--------------------------------------------------------------------------------
-- Overridden from UIComponent
--------------------------------------------------------------------------------

function UIButtonStrip:set_size(size)
  TRACE("UIButtonStrip:set_size()",size)

  self.__size = size

  if (self.orientation == VERTICAL) then
    UIComponent.set_size(self, 1, size)
  else
    assert(self.orientation == HORIZONTAL, 
      "Internal Error. Please report: unexpected UI orientation")
      
    UIComponent.set_size(self, size, 1)
  end
end

--------------------------------------------------------------------------------

function UIButtonStrip:add_listeners()

  self.__display.device.message_stream:add_listener(
    self, DEVICE_EVENT_BUTTON_PRESSED,
    function() self:do_press() end )

  self.__display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_HELD,
    function() self:do_hold() end )

  self.__display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_RELEASED,
    function() self:do_release() end )

end


--------------------------------------------------------------------------------

function UIButtonStrip:remove_listeners()

  self.__display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED)

  self.__display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_HELD)
    
  self.__display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_RELEASED)

end



--------------------------------------------------------------------------------
-- Private
--------------------------------------------------------------------------------

-- determine index by position, depends on orientation
-- @column (integer)
-- @row (integer)

function UIButtonStrip:__determine_index_by_pos(column,row)

  local idx,offset

  if (self.orientation == VERTICAL) then
    idx = row
    offset = self.y_pos
  else
    assert(self.orientation == HORIZONTAL, 
      "Internal Error. Please report: unexpected UI orientation")
      
    idx = column
    offset = self.x_pos
  end

  if not (self.flipped) then
    idx = (self.__size-idx+offset)
  else
    idx = idx-offset+1
  end

  return idx
end

--------------------------------------------------------------------------------

function UIButtonStrip:__toggle_blink()
  TRACE("UIButtonStrip:__toggle_blink()")

  self.__blink_is_lit = not self.__blink_is_lit

  self.__blink_task = self.__display.scheduler:add_task(
    self, UIButtonStrip.__toggle_blink, self.__blink_interval)

  self:invalidate()

end

--------------------------------------------------------------------------------

function UIButtonStrip:__in_range(idx)

  return not((idx<self.__range[1]) or (idx>self.__range[2]))

end

