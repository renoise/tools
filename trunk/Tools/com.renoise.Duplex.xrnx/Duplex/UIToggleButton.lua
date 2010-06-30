--[[----------------------------------------------------------------------------
-- Duplex.UIToggleButton
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UIToggleButton
Requires: Globals, Display, MessageStream, CanvasPoint

About

UIToggleButton is a simple rectangular toggle button
- display as normal/dimmed version
- minimum unit size: 1x1

Events

  on_change() - invoked whenever the button change it's active state
  on_hold()   - (optional) invoked when the button is held for a while


--]]


--==============================================================================

class 'UIToggleButton' (UIComponent)

function UIToggleButton:__init(display)
  TRACE('UIToggleButton:__init')

  UIComponent.__init(self,display)

  -- initial state is nil
  self.active = nil

  -- paint inverted
  self.inverted = false

  self._cached_active = nil

  self.palette = {
    foreground = table.rcopy(display.palette.color_1),
    foreground_dimmed = table.rcopy(display.palette.color_1_dimmed),
    background = table.rcopy(display.palette.background)
  }

  self.add_listeners(self)

end


--------------------------------------------------------------------------------

-- user input via button

function UIToggleButton:do_press()
  TRACE("UIToggleButton:do_press")
  
  if (self.on_change ~= nil) then

    local msg = self.get_msg(self)
    if not (self.group_name == msg.group_name) then
      return 
    end
    if not self.test(self,msg.column,msg.row) then
      return 
    end

    self.toggle(self)

  end

end


--------------------------------------------------------------------------------

-- user input via slider, encoder

function UIToggleButton:do_change()
  TRACE("UIToggleButton:do_change()")

  if (self.on_change ~= nil) then
    local msg = self.get_msg(self)
    if not (self.group_name == msg.group_name) then
      return 
    end
    if not self.test(self,msg.column,msg.row) then
      return 
    end
    -- toggle when moved away from min/max values
    if self.active and msg.value < msg.max then
      self.toggle(self)
    elseif not self.active and msg.value > msg.min then
      self.toggle(self)
    end
  end

end

--------------------------------------------------------------------------------

-- user input via (held) button
-- on_hold() is the optional handler method

function UIToggleButton:do_hold()
  TRACE("UIToggleButton:do_hold()")

  if (self.on_hold ~= nil) then
    local msg = self.get_msg(self)
    if not (self.group_name == msg.group_name) then
      return 
    end
    if not self.test(self,msg.column,msg.row) then
      return 
    end
    self:on_hold()
  end

end

--------------------------------------------------------------------------------

-- toggle button state

function UIToggleButton:toggle()
  TRACE("UIToggleButton:toggle")

  self.active = not self.active
  self._cached_active = self.active
  
  if (self.on_change ~= nil) then
    self:invoke_handler()
  end
end


--------------------------------------------------------------------------------

-- set button state

function UIToggleButton:set(value)
--TRACE("UIToggleButton:set", value)
  
  if (self._cached_active ~= value) then

    self._cached_active = value
    self.active = value
    --self.invalidate(self)
  
    if (self.on_change ~= nil) then
      self:invoke_handler()
    end
  end
end


--------------------------------------------------------------------------------

function UIToggleButton:set_dimmed(bool)
  if(self.dimmed == bool)then
    return
  end
  self.dimmed = bool
  self.invalidate(self)
end


--------------------------------------------------------------------------------

-- trigger the external handler method
-- (this can revert changes)

function UIToggleButton:invoke_handler()
  local rslt = self.on_change(self)
  if not rslt then  -- revert
    self.active = self._cached_active
  else
    self.invalidate(self)
  end
end


--------------------------------------------------------------------------------

function UIToggleButton:draw()
  TRACE("UIToggleButton:draw")

  local foreground,foreground_dimmed,background

  if(self.inverted)then
    foreground = self.palette.background
    foreground_dimmed = self.palette.background
    background = self.palette.foreground
  else
    foreground = self.palette.foreground
    foreground_dimmed = self.palette.foreground_dimmed
    background = self.palette.background
  end
  
  local point = CanvasPoint()

  if self.active then
    if self.dimmed then
      point.apply(point,foreground_dimmed)
    else
      point.apply(point,foreground)
    end
    point.val = true
  else
    point.apply(point,background)
    point.val = false
  end
  self.canvas.fill(self.canvas,point)

  UIComponent.draw(self)

end


--------------------------------------------------------------------------------

function UIToggleButton:add_listeners()

  self.display.device.message_stream:add_listener(
    self, DEVICE_EVENT_BUTTON_PRESSED,
    function() self:do_press() end )

  self.display.device.message_stream:add_listener(
    self,DEVICE_EVENT_VALUE_CHANGED,
    function() self:do_change() end )

  self.display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_HELD,
    function() self.do_hold(self,self) end )

end


--------------------------------------------------------------------------------

function UIToggleButton:remove_listeners()

  self.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED)

  self.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_VALUE_CHANGED)

  self.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_HELD)

end

