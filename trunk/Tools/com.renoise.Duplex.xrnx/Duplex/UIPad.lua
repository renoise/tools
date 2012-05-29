--[[----------------------------------------------------------------------------
-- Duplex.UIPad
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UIPad

--]]

--==============================================================================

class 'UIPad' (UIComponent)

--------------------------------------------------------------------------------

--- Initialize the UIPad class
-- @param display (Duplex.Display)

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

--- Value was changed
-- @param msg (Duplex.Message)
-- @return boolean, true when message was handled

function UIPad:do_change(msg)
  TRACE("UIPad:do_change()",msg)

  if (self.on_change ~= nil) then

    if not (self.group_name == msg.group_name) then
      return false
    end
    if not self:test(msg.column,msg.row) then
      return false
    end
    local val_x = msg.value[1]
    local val_y = msg.value[2]
    
    return self:set_value(val_x,val_y)

  end

  return false

end


--------------------------------------------------------------------------------

--- Set the UIPads values
-- @param val_x (Number) 
-- @param val_y (Number) 
-- @param skip_event (boolean) skip event handler
-- @return boolean, true when value was set

function UIPad:set_value(val_x,val_y,skip_event)
  TRACE("UIPad:set_value()",val_x,val_y,skip_event)

  if (self._cached_value[1] ~= val_x) or
    (self._cached_value[2] ~= val_y)
  then
    self._cached_value = {self.value[1],self.value[2]}
    self.value = {val_x,val_y}

    if (skip_event) then
      self:invalidate()
    else

      if (self.on_change == nil) then 
        return false
      end
      if (self:on_change()==false) then 
        self._value = self._cached_value  
        return false
      else
        self:invalidate()
      end
    end
  end  

  return true

end


--------------------------------------------------------------------------------

--- update the UIComponent canvas

function UIPad:draw()
  TRACE("UIPad:draw()")

  -- update dial/fader 
  local point = CanvasPoint()
  point.val = self.value
  self.canvas:write(point, 1, 1)
  UIComponent.draw(self)

end


--------------------------------------------------------------------------------

--- Add event listener (change)

function UIPad:add_listeners()

  self._display.device.message_stream:add_listener(
    self,DEVICE_EVENT_VALUE_CHANGED,
    function(msg) return self:do_change(msg) end )

end


--------------------------------------------------------------------------------

--- Remove previously attached event listener
-- @see UIPad:add_listeners

function UIPad:remove_listeners()

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_VALUE_CHANGED)

end

