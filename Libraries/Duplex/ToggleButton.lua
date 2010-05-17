--[[----------------------------------------------------------------------------
-- Duplex.ToggleButton
----------------------------------------------------------------------------]]--

--[[

Inheritance: DisplayObject > ToggleButton
Requires: Globals, Display, MessageStream, Point

ToggleButton is a simple rectangular toggle button

--]]


--==============================================================================

class 'ToggleButton' (DisplayObject)

function ToggleButton:__init(display)
--print('"ToggleButton"')

  DisplayObject.__init(self,display)

  self.active = true

  self.palette = {
    foreground = deepcopy(display.palette.color_1),
    foreground_dimmed = deepcopy(display.palette.color_1_dimmed),
    background = deepcopy(display.palette.background)
  }

  self.add_listeners(self)
  self._cached_active = self.active

end


--------------------------------------------------------------------------------

-- user input via button

function ToggleButton:do_press()
--print("ToggleButton:do_press")
  local msg = self.get_msg(self)
  if not (self.group_name == msg.group_name) then
    return 
  end
  if not self.test(self,msg.column,msg.row) then
    return 
  end
  self.toggle(self)

end


--------------------------------------------------------------------------------

-- user input via slider, encoder

function ToggleButton:do_change()
--print("ToggleButton:do_change()")

  local msg = self.get_msg(self)

  if not (self.group_name == msg.group_name) then
    return 
  end

  -- perform simple "inside square" hit test:
  if not self.test(self,msg.column,msg.row) then
    return 
  end

  if self.active and msg.value < msg.max then
    self.toggle(self)
  elseif not self.active and msg.value > msg.min then
    self.toggle(self)
  end

end


--------------------------------------------------------------------------------

function ToggleButton:toggle(silent)
--print("ToggleButton:toggle")

  self._cached_active = self.active
  self.active = not self.active
  --self.invalidate(self)
  if not silent and self.on_change then
    self.on_change(self)
  end
end


--------------------------------------------------------------------------------

function ToggleButton:set(value,silent)

  self.active = value
  self.invalidate(self)
  if not silent and self.on_change then
    --self.on_change(self)
    self:invoke_handler()
  end
end


--------------------------------------------------------------------------------

function ToggleButton:set_dimmed(bool)
  self.dimmed = bool
  self.invalidate(self)
end


--------------------------------------------------------------------------------

-- trigger the external handler method
-- (this can revert changes)

function ToggleButton:invoke_handler()
  local rslt = self.on_change(self)
  if not rslt then  -- revert
    self.active = self._cached_active
  else
    self.invalidate(self)
  end
end


--------------------------------------------------------------------------------

function ToggleButton:draw()
--print("ToggleButton:draw")

  local point = Point()

  if self.active then
    if self.dimmed then
      point.apply(point,self.palette.foreground_dimmed)
    else
      point.apply(point,self.palette.foreground)
    end
    point.val = true
  else
    point.apply(point,self.palette.background)
    point.val = false
  end
  self.canvas.fill(self.canvas,point)

  DisplayObject.draw(self)

end


--------------------------------------------------------------------------------

function ToggleButton:add_listeners()
  self.display.device.message_stream:add_listener(
    self, DEVICE_EVENT_BUTTON_PRESSED,
    function() self:do_press() end )

  self.display.device.message_stream:add_listener(
    self,DEVICE_EVENT_VALUE_CHANGED,
    function() self:do_change() end )
end


--------------------------------------------------------------------------------

function ToggleButton:remove_listeners()
  self.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED)

  self.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_VALUE_CHANGED)
end
