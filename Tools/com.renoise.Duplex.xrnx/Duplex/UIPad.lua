--[[----------------------------------------------------------------------------
-- Duplex.UIPad
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UIPad

--]]

--==============================================================================

class 'UIPad' (UIComponent)

function UIPad:__init(display)
  TRACE('UIPad:__init')

  UIComponent.__init(self,display)

  -- current values, between 0 and .ceiling
  self.value = {nil,nil}
  
  -- the second index, used when we specify each axis seperately
  -- (assign the X to main index, and Y axis to this one)
  self.secondary_index = nil

  -- internal values
  self._cached_value = self.value

  -- attach ourself to the display message stream
  self:add_listeners()

end

--------------------------------------------------------------------------------

-- user input via control

function UIPad:do_change(msg)
  TRACE("UIPad:do_change()",msg)

  if not (self.group_name == msg.group_name) then
    return
  end
  if not self:test(msg.column,msg.row) then
    return
  end
  -- scale from the message range to the sliders range
  local val_x = msg.value[1]
  local val_y = msg.value[2]
  self:set_value(val_x,val_y)
end


--------------------------------------------------------------------------------

-- setting value will also set index
-- @val (float) 
-- @skip_event (boolean) skip event handler

function UIPad:set_value(val_x,val_y,skip_event)
  TRACE("UIPad:set_value()",val_x,val_y,skip_event)

  if (self._cached_value[1] ~= val_x) or
    (self._cached_value[2] ~= val_y)
  then
    self._cached_value = {val_x,val_y}
    self.value = {val_x,val_y}

    if (skip_event) then
      self:invalidate()
    else
      self:_invoke_handler()
    end
  end  
end


--------------------------------------------------------------------------------

-- update the UIComponent canvas

function UIPad:draw()
  TRACE("UIPad:draw()")

  -- update dial/fader 
  local point = CanvasPoint()
  point.val = self.value
  self.canvas:write(point, 1, 1)
  UIComponent.draw(self)

end


--------------------------------------------------------------------------------

function UIPad:add_listeners()

  self._display.device.message_stream:add_listener(
    self,DEVICE_EVENT_VALUE_CHANGED,
    function(msg) self:do_change(msg) end )

end


--------------------------------------------------------------------------------

function UIPad:remove_listeners()

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_VALUE_CHANGED)

end

--------------------------------------------------------------------------------

-- trigger the external handler method

function UIPad:_invoke_handler()

  if (self.on_change == nil) then return end
  local rslt = self:on_change()  
  if (rslt==false) then  -- revert
    self._value = self._cached_value  

  else
    self:invalidate()
  end
end


