--[[----------------------------------------------------------------------------
-- Duplex.UIPushButton
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UIPushButton


About

UIPushButton is a stateless button (has no value), that can be used to
trigger events in an application. A special feature is the "sequence",
which is a built-in list of values that the button can cycle through
after being triggered (providing visual feedback of some kind)

- oneshot/trigger buttons (short blink)
- oneshot/trigger buttons with release (lit while pressed)
- "blinking" buttons (e.g "schedule pattern" in the Transport application)
- "fading" buttons (if the device has enough shades this is possible too)


Supported input methods

- button
- pushbutton
- togglebutton*

Events

- on_press()
- on_release()
- on_hold()

* release & hold events are not supported for this input method


--]]


--==============================================================================

class 'UIPushButton' (UIComponent)

function UIPushButton:__init(display)
  TRACE('UIPushButton:__init')

  UIComponent.__init(self,display)


  -- sequence of colors (specify at least one value)
  self.sequence = {
    {color={0xff,0xff,0xff},text="■"},
  }
  self.palette = {
    background = table.rcopy(display.palette.background),
  }

  -- the delay (in seconds) between updates 
  -- (choose a low value for faster updates)
  self.interval = 0.05

  -- start over when sequence is done
  self.loop = false

  -- specify the mode that the button is working in - 
  -- true: show the first color while pressed, then the sequence
  -- false: run the entire sequence immidiately when pressed
  self.wait_for_release = false

  self.on_press = function()
    -- override this with your own implementation
  end

  self.on_release = function()
    -- override this with your own implementation
  end

  -- external event handlers
  self.on_press = nil
  self.on_release = nil
  self.on_hold = nil

  -- internal stuff

  -- position within the sequence
  self._seq_index = 0

  -- keep a reference to the scheduled task (so we can cancel it)
  self._task = nil

  self._pressed = false

  self:add_listeners()

end


--------------------------------------------------------------------------------

-- user input via button

function UIPushButton:do_press()
  TRACE("UIPushButton:do_press")
  
  if (self.on_press ~= nil) then

    local msg = self:get_msg()
    if not (self.group_name == msg.group_name) then
      return 
    end
    if not self:test(msg.column,msg.row) then
      return 
    end

    self._pressed = true
    self:trigger()

  end

end

function UIPushButton:do_release()
  TRACE("UIPushButton:do_release")
  
  if (self.on_release ~= nil) and
    (self.wait_for_release) then

    local msg = self:get_msg()
    if not (self.group_name == msg.group_name) then
      return 
    end
    if not self:test(msg.column,msg.row) then
      return 
    end

    self._pressed = false
    self:invalidate()

  end

end

function UIPushButton:do_hold()
  TRACE("UIPushButton:do_release")
  
  if (self.on_hold ~= nil) then

    local msg = self:get_msg()
    if not (self.group_name == msg.group_name) then
      return 
    end
    if not self:test(msg.column,msg.row) then
      return 
    end

    self.on_hold()

  end

end

--------------------------------------------------------------------------------

function UIPushButton:trigger()
  TRACE("UIPushButton:trigger()")

    self._seq_index = 1
    self:_cancel_scheduled_task()
    self:_invoke_handler()

end


--------------------------------------------------------------------------------
-- Overridden from UIComponent
--------------------------------------------------------------------------------

-- once the draw() method is called, it will call itself repeatedly,
-- until the sequence is done, or a new event is triggered (start over again)

function UIPushButton:draw()
  --TRACE("UIPushButton:draw")

  if(not self._seq_index) then return end

  local point = CanvasPoint()
  local seq = self.sequence[self._seq_index]

  if (seq) then
    
    -- apply the color from the sequence
    point:apply(seq)
    -- if the color is completely dark, this is also how
    -- LED buttons will represent the value (turned off)
    if(get_color_average(seq.color)>0x00)then
      point.val = true        
    else
      point.val = false        
    end

    -- schedule another draw() by invalidating the component
    if not (self.wait_for_release and self._pressed) then
      self._task = self._display.scheduler:add_task(
        self, UIPushButton.invalidate, self.interval)
    end
    self._seq_index = self._seq_index+1
  
  else
    -- sequence done
    if (self.loop) then
      self._seq_index = 1
      self:draw()
    else
      self:stop()
    end
    return

  end

  self.canvas:fill(point)
  UIComponent.draw(self)

end

--------------------------------------------------------------------------------

-- set to background/false and stop from repeating

function UIPushButton:stop()

  local point = CanvasPoint()
  point:apply(self.palette.background)
  point.val = false
  self._seq_index = nil
  self.canvas:fill(point)
  UIComponent.draw(self)

end

--------------------------------------------------------------------------------

function UIPushButton:add_listeners()

  self._display.device.message_stream:add_listener(
    self, DEVICE_EVENT_BUTTON_PRESSED,
    function() self:do_press() end )

  self._display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_RELEASED,
    function() self:do_release() end )

  self._display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_HELD,
    function() self:do_hold() end )

end


--------------------------------------------------------------------------------

function UIPushButton:remove_listeners()

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED)

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_RELEASED)

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_HELD)

end


--------------------------------------------------------------------------------
-- Private
--------------------------------------------------------------------------------

-- trigger the external handler method

function UIPushButton:_invoke_handler()
  TRACE("UIPushButton:_invoke_handler()")

  if (self.on_press == nil) then return end

  local rslt = self:on_press()
  if (rslt~=false) then
    self:invalidate()
  end
end


--------------------------------------------------------------------------------

function UIPushButton:_cancel_scheduled_task()
  TRACE("UIPushButton:_cancel_scheduled_task()")

  if self._task then
    self._display.scheduler:remove_task(self._task)
  end

end


