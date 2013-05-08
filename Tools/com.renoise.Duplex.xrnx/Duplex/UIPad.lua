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
-- @param app (Duplex.Application)

function UIPad:__init(app)
  TRACE('UIPad:__init')

  UIComponent.__init(self,app)

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
-- @return self or nil

function UIPad:do_change(msg)
  TRACE("UIPad:do_change()",msg)

  if not (self.group_name == msg.group_name) then
    return
  end

  if not self.app.active then
    return 
  end
  
  if not self:test(msg.column,msg.row) then
    return
  end

  if (self.on_change ~= nil) then

    local val_x,val_y = nil,nil

    -- check if message was sent from a sub-parameter
    if msg.param.parent_id then
      val_x = (msg.param.index == 1) and msg.value or self.value[1]
      val_y = (msg.param.index == 2) and msg.value or self.value[2]
    else
      val_x = msg.value[1]
      val_y = msg.value[2]
    end
    
    self:set_value(val_x,val_y)

  end

  return self

end


--------------------------------------------------------------------------------

--- Set the UIPads values
-- @param val_x (Number) 
-- @param val_y (Number) 
-- @param skip_event (boolean) skip event handler

function UIPad:set_value(val_x,val_y,skip_event)
  TRACE("UIPad:set_value()",val_x,val_y,skip_event)

  self._cached_value = {self.value[1],self.value[2]}
  self.value = {val_x,val_y}

  --print("*** UIPad:set_value - val_x,val_y",val_x,val_y)

  if (skip_event) then
    self:invalidate()
  elseif (self.on_change) then 
    if (self:on_change()==false) then 
      self._value = self._cached_value  
    else
      self:invalidate()
    end
  end


end


--------------------------------------------------------------------------------

--- update the UIComponent canvas

function UIPad:draw()
  TRACE("UIPad:draw() - self.value",self.value)

  -- update dial/fader 
  local point = CanvasPoint()
  point.val = self.value
  self.canvas:write(point, 1, 1)
  UIComponent.draw(self)

end


--------------------------------------------------------------------------------

--- Add event listener (change)

function UIPad:add_listeners()

  self.app.display.device.message_stream:add_listener(
    self,DEVICE_EVENT_VALUE_CHANGED,
    function(msg) return self:do_change(msg) end )

end


--------------------------------------------------------------------------------

--- Remove previously attached event listener
-- @see UIPad:add_listeners

function UIPad:remove_listeners()

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_VALUE_CHANGED)

end

