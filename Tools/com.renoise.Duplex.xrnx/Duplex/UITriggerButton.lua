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
  TRACE('UITriggerButton:__init')

  UIComponent.__init(self,display)

  -- sequence of colors (specify at least two values + background)
  self.sequence = {
    {color={0xff,0xff,0xff},text="■"},
    --{color={0x80,0x40,0x80},text="□"},
    --{color={0x40,0x00,0x40},text="▪"},
    --{color={0x00,0x00,0x00},text="▫"},
  }

  self.palette = {
    background = table.rcopy(display.palette.background),
  }

  -- the delay (in seconds) between updates 
  -- (choose a low value for faster updates)
  self.interval = 0.05

  -- start over when sequence is done
  self.loop = false

  -- internal stuff

  -- position within the sequence
  self.__seq_index = 0

  -- keep a reference to the scheduled task (so we can cancel it)
  self.__task = nil

  self:add_listeners()

end


--------------------------------------------------------------------------------

-- user input via button

function UITriggerButton:do_press()
  TRACE("UITriggerButton:do_press")
  
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
  TRACE("UITriggerButton:trigger()")

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
  TRACE("UITriggerButton:draw")

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
    --point.val = true

    -- schedule another draw() by invalidating the component
    self.__task = self.__display.scheduler:add_task(
      self, UITriggerButton.invalidate, self.interval)
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

function UITriggerButton:stop()

  local point = CanvasPoint()
  point:apply(self.palette.background)
  point.val = false
  self.__seq_index = nil
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
  TRACE("UITriggerButton:__invoke_handler()")

  if (self.on_change == nil) then return end

  local rslt = self:on_change()
  if (rslt~=false) then
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


