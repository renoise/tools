--[[----------------------------------------------------------------------------
-- Duplex.UIToggleButton
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UIToggleButton
Requires: Globals, Display, MessageStream, CanvasPoint

About

UIToggleButton is a simple rectangular on/off toggle button 
You can use it with a button, but also dial and fader input is supported: 
just turn the control to it's maximum or minimum to toggle between values 

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

  -- initial state is nil (to force drawing)
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

    local msg = self:get_msg()
    if not (self.group_name == msg.group_name) then
      return 
    end
    if not self:test(msg.column,msg.row) then
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
    local msg = self:get_msg()
    if not (self.group_name == msg.group_name) then
      return 
    end
    if not self:test(msg.column,msg.row) then
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
    local msg = self:get_msg()
    if not (self.group_name == msg.group_name) then
      return 
    end
    if not self:test(msg.column,msg.row) then
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
  
  self:__invoke_handler()
end


--------------------------------------------------------------------------------

-- set button state

function UIToggleButton:set(value)
--TRACE("UIToggleButton:set", value)
  
  if (self._cached_active ~= value) then

    self._cached_active = value
    self.active = value
  
    self:__invoke_handler()
  end
end


--------------------------------------------------------------------------------

function UIToggleButton:set_dimmed(bool)
  if(self.dimmed == bool)then
    return
  end
  self.dimmed = bool
  self:invalidate()
end


--------------------------------------------------------------------------------
-- Overridden from UIComponent
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
      point:apply(foreground_dimmed)
    else
      point:apply(foreground)
    end
    point.val = true
  else
    point:apply(background)
    point.val = false
  end
  self.canvas:fill(point)

  UIComponent.draw(self)

end


--------------------------------------------------------------------------------

function UIToggleButton:add_listeners()

  self.__display.device.message_stream:add_listener(
    self, DEVICE_EVENT_BUTTON_PRESSED,
    function() self:do_press() end )

  self.__display.device.message_stream:add_listener(
    self,DEVICE_EVENT_VALUE_CHANGED,
    function() self:do_change() end )

  self.__display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_HELD,
    function() self:do_hold() end )

end


--------------------------------------------------------------------------------

function UIToggleButton:remove_listeners()

  self.__display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED)

  self.__display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_VALUE_CHANGED)

  self.__display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_HELD)

end


--------------------------------------------------------------------------------
-- Private
--------------------------------------------------------------------------------

-- trigger the external handler method
-- (this can revert changes)

function UIToggleButton:__invoke_handler()

  if (self.on_change == nil) then return end

  local rslt = self:on_change()
  if (rslt==false) then  -- revert
    self.active = self._cached_active
  else
    self:invalidate()
  end
end


