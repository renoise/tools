--[[============================================================================
-- Duplex.UIPad
-- Inheritance: UIComponent > UIPad
============================================================================]]--

--[[--
UIPad is designed to take control of a X/Y Pad

--]]

--==============================================================================

class 'UIPad' (UIComponent)

--------------------------------------------------------------------------------

--- Initialize the UIPad class
-- @param app (@{Duplex.Application})
-- @param map[opt] (table) mapping properties 

function UIPad:__init(app,map)
  TRACE('UIPad:__init',app,map)

  --- (table) current value
  -- @field x
  -- @field y
  -- @table value
  self.value = {0.5,0.5}
  
  --- (table) copy of the most recent value
  self._cached_value = nil

  --- (bool) see @{Duplex.UIComponent}
  --self.virtual_event = true

  UIComponent.__init(self,app,map)

end

--------------------------------------------------------------------------------

--- Value was changed
-- @param msg (@{Duplex.Message})
-- @return self or nil

function UIPad:do_change(msg)
  TRACE("UIPad:do_change()",msg)

  if not self:test(msg) then
    return
  end

  self.msg = msg

  local normalize = function(val)
    return scale_value(val,msg.xarg.minimum,msg.xarg.maximum,self.floor,self.ceiling)
  end

  local val_x,val_y = nil,nil
  if (type(msg.value) == "number") then
    -- MIDI style message (each axis is separate)
    if (msg.xarg.orientation == "vertical") then
      val_x = self.value[1]
      val_y = normalize(msg.value)
    else
      val_x = normalize(msg.value)
      val_y = self.value[2]
    end
  else
    --print("*** UIPad:do_change - pre normalize",msg.value[1],msg.value[2])
    -- OSC style message (combined)
    val_x = normalize(msg.value[1])
    val_y = normalize(msg.value[2])
    --print("*** UIPad:do_change - post normalize",val_x,val_y)
  end

  self:set_value(val_x,val_y)


  return self

end


--------------------------------------------------------------------------------

--- Set the UIPads values
-- @param val_x (number) 
-- @param val_y (number) 
-- @param skip_event (bool) skip event handler

function UIPad:set_value(val_x,val_y,skip_event)
  TRACE("UIPad:set_value()",val_x,val_y,skip_event)

  if self.value then
    self._cached_value = table.rcopy(self.value)
  end

  self.value = {val_x,val_y}

  --print("*** UIPad:set_value - val_x,val_y",val_x,val_y)

  if (skip_event) then
    self:invalidate()
  elseif (self.on_change) then 
    if (self:on_change()==false) then 
      self.value = table.rcopy(self._cached_value)
    else
      self:invalidate()
    end
  end


end



--------------------------------------------------------------------------------

--- Update the appearance - inherited from UIComponent
-- @see Duplex.UIComponent

function UIPad:draw()
  TRACE("UIPad:draw() - self.value",self.value)

  -- update dial/fader 
  local point = CanvasPoint()
  point.val = self.value
  self.canvas:write(point, 1, 1)
  UIComponent.draw(self)

end


--------------------------------------------------------------------------------

--- Add event listener
--    DEVICE_EVENT.VALUE_CHANGED
-- @see Duplex.UIComponent

function UIPad:add_listeners()

  self:remove_listeners()

  if self.on_change then
    self.app.display.device.message_stream:add_listener(
      self,DEVICE_EVENT.VALUE_CHANGED,
      function(msg) return self:do_change(msg) end )
  end

end


--------------------------------------------------------------------------------

--- Remove previously attached event listeners
-- @see Duplex.UIComponent

function UIPad:remove_listeners()

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT.VALUE_CHANGED)

end

