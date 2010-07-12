--[[----------------------------------------------------------------------------
-- Duplex.UITriggerButton
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UITriggerButton


About

Essentially, UITriggerButton is a button that will light up for a moment. 
The UITriggerButton will allow you to specify the amount of time that should
pass between updates, as well as a customizable sequence of colors to display. 


Input methods

- only the "button" type is supported for this control


Events

- on_change() - external function to invoke after button is pressed


--]]


--==============================================================================

class 'UITriggerButton' (UIComponent)

function UITriggerButton:__init(display)
  print('UITriggerButton:__init')

  UIComponent.__init(self,display)

  -- sequence of colors (specify at least two values + background)
  self.sequence = {
    {color={0xff,0xff,0xff},text="■"},
    {color={0x80,0x40,0x80},text="□"},
    {color={0x40,0x00,0x40},text="▪"},
    {color={0x00,0x00,0x00},text="▫"},
  }

  self.palette = {
    background = table.rcopy(display.palette.background),
  }

  -- the delay (in seconds) between updates 
  -- (choose a low value such as 0.1 for faster updates)
  self.interval = 0.05

  -- internal stuff

  -- position within the sequence
  self.__seq_index = nil

  -- keep a reference to the scheduled task (so we can cancel it)
  self.__task = nil

  self:add_listeners()

end


--------------------------------------------------------------------------------

-- user input via button

function UITriggerButton:do_press()
  print("UITriggerButton:do_press")
  
  if (self.on_change ~= nil) then

    local msg = self:get_msg()
    if not (self.group_name == msg.group_name) then
      return 
    end
    if not self:test(msg.column,msg.row) then
      return 
    end

    self:trigger()

  end

end

--------------------------------------------------------------------------------

function UITriggerButton:trigger()

    self.__seq_index = 1
    self:__cancel_scheduled_task()
    self:__invoke_handler()

end


--------------------------------------------------------------------------------
-- Overridden from UIComponent
--------------------------------------------------------------------------------

-- once the draw() method is called, it will call itself repeatedly,
-- until the sequence is done, or a new event is triggered (in which case it
-- will start over again)

function UITriggerButton:draw()
  if(not self.__seq_index) then return end
  --print("UITriggerButton:draw")

  local point = CanvasPoint()
  local seq = self.sequence[self.__seq_index]

  if (seq) then
    
    -- apply the color from the sequence
    point:apply(seq)
    point.val = true

    -- schedule another draw() by invalidating the component
    self.__task = self.__display.scheduler:add_task(
      self, UITriggerButton.invalidate, self.interval)
    self.__seq_index = self.__seq_index+1
  
  else

    -- sequence done, set to background/false
    -- and stop the draw method from repeating
    point:apply(self.palette.background)
    point.val = false
    self.__seq_index = nil

  end

  self.canvas:fill(point)

  UIComponent.draw(self)
end


--------------------------------------------------------------------------------

function UITriggerButton:add_listeners()

  self.__display.device.message_stream:add_listener(
    self, DEVICE_EVENT_BUTTON_PRESSED,
    function() self:do_press() end )

end


--------------------------------------------------------------------------------

function UITriggerButton:remove_listeners()

  self.__display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED)

end


--------------------------------------------------------------------------------
-- Private
--------------------------------------------------------------------------------

-- trigger the external handler method
-- (this can revert changes)

function UITriggerButton:__invoke_handler()
  print("UITriggerButton:__invoke_handler()")

  if (self.on_change == nil) then return end

  local rslt = self:on_change()
  if rslt then
    self:invalidate()
  end
end


--------------------------------------------------------------------------------

function UITriggerButton:__cancel_scheduled_task()
  TRACE("UITriggerButton:__cancel_scheduled_task()")

  if self.__task then
    self.__display.scheduler:remove_task(self.__task)
  end

end


