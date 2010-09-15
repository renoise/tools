--[[----------------------------------------------------------------------------
-- Duplex.UIPushButton
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UIPushButton


About

UIPushButton is a stateless button (has no value), that can be used to
trigger events in an application. It's capable of more than just a brief
flash of light, you can also assign a sequence of colors to the button and
specify the amount of time that should pass between updates

- oneshot/trigger buttons (short blink)
- oneshot/trigger buttons with release (lit while pressed)
- blinking buttons (e.g "schedule pattern" in the Transport application)
- fading buttons (if the device has enough shades)


Supported input methods

- "button"
- "togglebutton" 

Events

- on_press()
- on_release()


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

  -- internal stuff

  -- position within the sequence
  self.__seq_index = 0

  -- keep a reference to the scheduled task (so we can cancel it)
  self.__task = nil

  self.__pressed = false


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

    self.__pressed = true

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

    self.__pressed = false

    self:invalidate()

  end

end

--------------------------------------------------------------------------------

function UIPushButton:trigger()
  TRACE("UIPushButton:trigger()")

    self.__seq_index = 1
    self:__cancel_scheduled_task()
    self:__invoke_handler()

end


--------------------------------------------------------------------------------
-- Overridden from UIComponent
--------------------------------------------------------------------------------

-- once the draw() method is called, it will call itself repeatedly,
-- until the sequence is done, or a new event is triggered (start over again)

function UIPushButton:draw()
  --TRACE("UIPushButton:draw")

  if(not self.__seq_index) then return end

  local point = CanvasPoint()
  local seq = self.sequence[self.__seq_index]

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
    if not (self.wait_for_release and self.__pressed) then
      self.__task = self.__display.scheduler:add_task(
        self, UIPushButton.invalidate, self.interval)
    end
    self.__seq_index = self.__seq_index+1
  
  else
    -- sequence done
    if (self.loop) then
      self.__seq_index = 1
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
  self.__seq_index = nil
  self.canvas:fill(point)
  UIComponent.draw(self)

end

--------------------------------------------------------------------------------

function UIPushButton:add_listeners()

  self.__display.device.message_stream:add_listener(
    self, DEVICE_EVENT_BUTTON_PRESSED,
    function() self:do_press() end )

  self.__display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_RELEASED,
    function() self:do_release() end )

end


--------------------------------------------------------------------------------

function UIPushButton:remove_listeners()

  self.__display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED)

  self.__display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_RELEASED)

end


--------------------------------------------------------------------------------
-- Private
--------------------------------------------------------------------------------

-- trigger the external handler method

function UIPushButton:__invoke_handler()
  TRACE("UIPushButton:__invoke_handler()")

  if (self.on_press == nil) then return end

  local rslt = self:on_press()
  if (rslt~=false) then
    self:invalidate()
  end
end


--------------------------------------------------------------------------------

function UIPushButton:__cancel_scheduled_task()
  TRACE("UIPushButton:__cancel_scheduled_task()")

  if self.__task then
    self.__display.scheduler:remove_task(self.__task)
  end

end


