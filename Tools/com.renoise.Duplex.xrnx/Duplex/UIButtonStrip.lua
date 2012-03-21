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


  1:MODE_NORMAL - set range/index using button combinations 
    
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


  2:MODE_INDEX - togglebutton compatible mode, only index can be set

    Events

      on_index_change
      on_press
      on_release*
      on_hold*

    Supported input methods

      "button"
      "togglebutton"

    * "togglebutton" not supported 


  3:MODE_BASIC - free mode, supply your own logic

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



Display logic 

  For color displays, it's possible to differentiate 
  between the index and range

  [ ] = Background
  [x] = Selected index
  [o] = Range

  [x][o][o][o][ ][ ] <- Index set to 1, range set to 1,4
  [o][o][x][o][ ][ ] <- Index set to 3, range set to 1,4
  [o][o][o][o][ ][x] <- Index set to 6, range set to 1,4

  For monochromatic devices / LED buttons, if the "index" color 
  is identical to the "range" color, the draw() method will use
  an alternative/inverted color scheme:

  [ ]     = Background
  [x]/[ ] = Selected index
  [x]     = Range

  [ ][x][x][x][ ][ ] <- Index set to 1, range set to 1,4
  [x][x][ ][x][ ][ ] <- Index set to 3, range set to 1,4
  [ ][ ][x][ ][ ][ ] <- Index set to 3, range set to 3,3
  [x][x][x][x][ ][x] <- Index set to 6, range set to 1,4



Special methods  


  UIButtonStrip:set_steps(steps)

  Sets the number of steps, in case the buttonstrip is larger than the number
  of steps it is controlling (like having 8 buttons to control 4 steps). 
  Will display the strip "stretched" along it's axis




--]]


--==============================================================================

class 'UIButtonStrip' (UIComponent)

function UIButtonStrip:__init(display)
  TRACE("UIButtonStrip:__init(",display,")")

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

  -- flip top/bottom direction when setting/retrieving index/range
  self.flipped = false

  -- set this value when control has more buttons than indices
  -- (for example, when using 16 buttons to control 8 steps)
  self._steps = nil

  -- vertical or horizontal orientation?
  -- (use set_orientation() method to set this value)
  self._orientation = VERTICAL 

  -- external event handlers
  self.on_press = nil
  self.on_release = nil
  self.on_hold = nil
  self.on_index_change = nil
  self.on_range_change = nil

  -- internal stuff
  self._held_event_fired = false
  self._range_set = false
  self._pressed_idx = nil
  self._blink_idx = 0
  self._blink_is_lit = nil
  self._blink_task = nil
  self._blink_interval = 0.5
  self._size = 0
  self._range = {0,0}
  self._index = 0
  self._cached_index = self._index
  self._cached_range = self._range

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

  local idx = self:_determine_index_by_pos(msg.column, msg.row)

  if (self.mode == self.MODE_NORMAL) then
    if not (self._pressed_idx) then
      -- this is the first button being pressed, remember it
      self._pressed_idx = idx
      self._held_event_fired = false
      self._range_set = false
    else
      -- we are pressing multiple buttons - set the active range
      self:set_range(idx,self._pressed_idx)
      self._range_set = true
    end
  elseif (self.mode == self.MODE_INDEX) then
    if (self.toggleable) and (idx==self._index) then
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
    local idx = self:_determine_index_by_pos(msg.column, msg.row)

    if (idx==self._pressed_idx) then
      self._pressed_idx = nil
      if (not self._held_event_fired) and (not self._range_set) then
        if (self.toggleable) and (idx==self._index) then
          self:set_index(0)

        else
          self:set_index(idx)

        end
      end
    end
  end

  -- force-update controls that are handling 
  -- their internal state automatically...
  if (msg.input_method == CONTROLLER_PUSHBUTTON) then
    self.canvas.delta = table.rcopy(self.canvas.buffer)
    self.canvas.has_changed = true
    self:invalidate()
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
    if (not self._range_set) then
      if (self._range[1]~=0) then
        self:set_range(0,0)
      else
        local idx = self:_determine_index_by_pos(msg.column, msg.row)
        self:set_range(idx,idx)
      end
      self._range_set = false
    end
    self._held_event_fired = true
  end


  if (self.on_hold ~= nil) then
    self:on_hold()
  end

end

--------------------------------------------------------------------------------

function UIButtonStrip:draw()
  --TRACE("UIButtonStrip:draw()")

  local factor
  local scale_range = false
  local blink_idx = self._blink_idx
  local rng1 = self._range[1]
  local rng2 = self._range[2]
  if self._steps and (self._steps~=self._size) then
    -- scale values to step size
    scale_range = true
    factor = self._steps/self._size
    blink_idx = math.ceil(blink_idx*factor)
    rng1 = math.ceil(rng1*factor)
    rng2 = math.ceil(rng2*factor)
  end

  for i = 1,self._size do

    local idx = (scale_range) and math.ceil(i*factor) or i

    local point = CanvasPoint()
    local x,y = 1,1

    if blink_idx and
      (idx==blink_idx) and
      (self._blink_is_lit) 
    then
      -- a blinking, lit button
      point:apply(self.palette.index)
      point.val = true
   elseif (idx == self._index) and
      (idx~=blink_idx) 
    then
      -- selected index (not blinking)
      if not self.monochrome then
        point:apply(self.palette.index)
        point.val = true
      else
        if (rng1==rng2) then
          point:apply(self.palette.index)
          point.val = true
        elseif (self:_in_range(idx)) then
          point:apply(self.palette.background)
          point.val = false
        else
          point:apply(self.palette.index)
          point.val = true
        end
      end
    elseif not self:_in_range(idx) then
      -- background
      point:apply(self.palette.background)
      point.val = false
    else
      -- inside range
      if not self.monochrome then
        point:apply(self.palette.range)
        point.val = true
      else
        point:apply(self.palette.index)
        point.val = true
      end
    end

    if (self._orientation == VERTICAL) then 
      y = i
    else
      x = i
    end

    self.canvas:write(point, x, y)

  end

  UIComponent.draw(self)

end

--------------------------------------------------------------------------------

-- get/set the current index

function UIButtonStrip:set_index(idx,skip_event)
  TRACE("UIButtonStrip:set_index(",idx,skip_event,")")
  
  if not skip_event then
    if self._steps and (self._steps~=self._size) then
      local factor = self._steps/self._size
      idx = math.ceil(idx*factor)
      --return idx
    end
  end

  if (idx~=self._index) then

    self._cached_index = self._index
    self._index = idx

    if (not skip_event) and (self.on_index_change~=nil) then
      local rslt = self:on_index_change()  
      if (rslt==false) then  -- revert
        self._index = self._cached_index    
      else
        self:invalidate()
      end
    else
      self:invalidate()
    end

  end

end


function UIButtonStrip:get_index()
  --TRACE("UIButtonStrip:get_index()")

  return self._index
end

--------------------------------------------------------------------------------

-- get/set the current range

function UIButtonStrip:set_range(idx1,idx2,skip_event)
  TRACE("UIButtonStrip:set_range(",idx1,idx2,skip_event,")")


  -- swap values if needed (first should be lowest)
  if (idx1>idx2) then
    idx1,idx2 = idx2,idx1
  end

  if not skip_event then
    if self._steps and (self._steps~=self._size) then
      local factor = self._steps/self._size
      local range = {}
      idx1 = math.ceil(idx1*factor)
      idx2 = math.ceil(idx2*factor)
      --return range
    end
  end

  self._cached_range = self._range
  self._range = {idx1,idx2}
  if (not skip_event) and (self.on_range_change~=nil) then
    local rslt = self:on_range_change()  
    if (rslt==false) then  -- revert
      self._range = self._cached_range  
    else
      self:invalidate()
    end
  else
    self:invalidate()
  end

end


function UIButtonStrip:get_range()
  TRACE("UIButtonStrip:get_range()")

  return self._range
end

--------------------------------------------------------------------------------

-- get/set the number of steps 

function UIButtonStrip:set_steps(steps)
  TRACE("UIButtonStrip:set_steps()")

  if (steps ~= self._steps) then

    self._steps = steps
    local factor = self._steps/self._size
    local rng1 = math.ceil(self._range[1]*factor)
    local rng2 = math.ceil(self._range[2]*factor)
    local idx = math.ceil(self._index*factor)

    self._index = idx
    self._range = {rng1,rng2}

  end

end

function UIButtonStrip:get_steps()

  return self._steps

end

--------------------------------------------------------------------------------

function UIButtonStrip:start_blink(idx)
  TRACE("UIButtonStrip:start_blink(",idx,")")

  self:stop_blink()
  self._blink_idx = idx
  self._blink_is_lit = false
  self:_toggle_blink()

end

--------------------------------------------------------------------------------

function UIButtonStrip:pause_blink(idx)
  TRACE("UIButtonStrip:pause_blink(",idx,")")

  if self._blink_task then
    self._display.scheduler:remove_task(self._blink_task)
  end
  self._blink_is_lit = false
  self:invalidate()

end

--------------------------------------------------------------------------------

function UIButtonStrip:stop_blink()
  TRACE("UIButtonStrip:stop_blink()")

  self._blink_idx = 0
  if self._blink_task then
    self._display.scheduler:remove_task(self._blink_task)
  end

end

--------------------------------------------------------------------------------

function UIButtonStrip:set_orientation(value)
  TRACE("UIButtonStrip:set_orientation(",value,")")

  if (value == HORIZONTAL) or (value == VERTICAL) then
    self._orientation = value
    self:set_size(self._size) -- update canvas
  end
end

function UIButtonStrip:get_orientation()
  TRACE("UIButtonStrip:get_orientation()")
  return self._orientation
end

--------------------------------------------------------------------------------
-- Overridden from UIComponent
--------------------------------------------------------------------------------

function UIButtonStrip:set_size(size)
  TRACE("UIButtonStrip:set_size(",size,")")

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

function UIButtonStrip:add_listeners()
  TRACE("UIButtonStrip:add_listeners()")

  self._display.device.message_stream:add_listener(
    self, DEVICE_EVENT_BUTTON_PRESSED,
    function() self:do_press() end )

  self._display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_HELD,
    function() self:do_hold() end )

  self._display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_RELEASED,
    function() self:do_release() end )

end


--------------------------------------------------------------------------------

function UIButtonStrip:remove_listeners()
  TRACE("UIButtonStrip:remove_listeners()")

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED)

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_HELD)
    
  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_RELEASED)

end



--------------------------------------------------------------------------------
-- Private
--------------------------------------------------------------------------------

-- determine index by position, depends on orientation
-- @column (integer)
-- @row (integer)

function UIButtonStrip:_determine_index_by_pos(column,row)

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

function UIButtonStrip:_toggle_blink()
  TRACE("UIButtonStrip:_toggle_blink()")

  self._blink_is_lit = not self._blink_is_lit

  self._blink_task = self._display.scheduler:add_task(
    self, UIButtonStrip._toggle_blink, self._blink_interval)

  self:invalidate()

end

--------------------------------------------------------------------------------

function UIButtonStrip:_in_range(idx)

  return not((idx<self._range[1]) or (idx>self._range[2]))

end

