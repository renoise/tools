--[[----------------------------------------------------------------------------
-- Duplex.UISlider
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UISlider
Requires: Globals, Display, CanvasPoint

About

The Slider supports different input methods: buttons or sliders/encoders
- - use buttons to quantize the slider input
- - use faders/encoders to divide value into smaller segments
- display supports horizontal/vertical and axis flipping
- display as normal/dimmed version
- minimum unit size: 1x1

Events

  on_change() - invoked whenever the slider recieve a new value



--]]


--==============================================================================

class 'UISlider' (UIComponent)

function UISlider:__init(display)
  TRACE('UISlider:__init')

  UIComponent.__init(self,display)

  -- 0 is empty (default)
  self.size = 0

  -- the selected index (0 is deselected)
  self.index = 0

  -- if true, press twice to switch to deselected state*
  self.toggleable = false

  -- paint a dimmed version*
  self.dimmed = false

  -- current value (sliders/encoders offer more precision)
  self.value = 0

  -- the maximum value (between 0 and "ceiling")
  self.ceiling = 1

  -- slider is vertical or horizontal?
  self.orientation = VERTICAL 

  -- flip top/bottom direction 
  self.flipped = false

  --  * this only applies when input method is a button

  self.add_listeners(self)

  self.palette = {
    background = table.rcopy(display.palette.background),
    foreground = table.rcopy(display.palette.color_1),
    foreground_dimmed = table.rcopy(display.palette.color_1_dimmed),
    medium = table.rcopy(display.palette.color_2),
    medium_dimmed = table.rcopy(display.palette.color_2_dimmed),
  }

  -- internal values
  self._cached_index = self.index
  self._cached_value = self.value
end


--------------------------------------------------------------------------------

-- user input via button
-- set index

function UISlider:do_press()

  local idx = nil
  local msg = self.get_msg(self)

  if not (self.group_name == msg.group_name) then
    return
  end

  if not self.test(self,msg.column,msg.row) then
    return
  end

  idx = self.determine_index_by_pos(self,msg.column,msg.row)

  if self.toggleable then
    if self.index == idx then
      idx = 0
    end
  end

  self.set_index(self,idx)

end


--------------------------------------------------------------------------------

-- user input via slider, encoder: 
-- set index + precise value

function UISlider:do_change()
  TRACE("Slider:do_change()")

  local msg = self.get_msg(self)
  if not (self.group_name == msg.group_name) then
    return
  end
  if not self.test(self,msg.column,msg.row) then
    return
  end
  local idx = self.determine_index_by_pos(self,msg.column,msg.row)
  local tmp = (msg.value/msg.max)*self.ceiling/self.size
  local rslt = (self.ceiling/self.size)*(idx-1)+tmp
  self.set_value(self,rslt)
end


--------------------------------------------------------------------------------

-- determine index by position, depends on orientation
-- @column (integer)
-- @row (integer)

function UISlider:determine_index_by_pos(column,row)

  local pos,offset = nil,nil

  if self.orientation == VERTICAL then
    pos = row
    offset = self.y_pos
  else
    pos = column
    offset = self.x_pos
  end
  if not self.flipped then
    pos = self.size-pos+1
  end
  local idx = pos-(offset-1)

  return idx
end


--------------------------------------------------------------------------------

-- setting the size will change the canvas too
-- @size (integer)

function UISlider:set_size(size)

  self.size = size

  if self.orientation == VERTICAL then
    UIComponent.set_size(self,1,size)
  else
    UIComponent.set_size(self,size,1)
  end

end


--------------------------------------------------------------------------------

-- setting value will also set index
-- @val (float) 
-- @skip_event (boolean) skip event handler

function UISlider:set_value(val,skip_event)
  TRACE("UISlider:set_value:",val)

  local idx = math.ceil((self.size/self.ceiling)*val)
  local rslt = false

  if (self._cached_index ~= idx or
      self._cached_value ~= val) then
    self._cached_index = idx
    self._cached_value = val
    self.value = val
    self.index = idx
    self:invalidate()

    if (not skip_event) and (self.on_change ~= nil) then
      self:invoke_handler()
    end
  end  
end


--------------------------------------------------------------------------------

-- setting index will also set value
-- @idx (integer) 
-- @skip_event (boolean) skip event handler

function UISlider:set_index(idx,skip_event)
  TRACE("UISlider:set_index:",idx)

  -- todo: cap value
  local rslt = false
  if (self._cached_index ~= idx) then
    self._cached_index = idx
    self._cached_value = self.value
    self.index = idx
    self.value = (self.ceiling/self.size)*idx
  
    if (not skip_event) and(self.on_change ~= nil) then
      self:invoke_handler()
    end
  end
end


--------------------------------------------------------------------------------

-- trigger the external handler method
-- (this can revert changes)

function UISlider:invoke_handler()
  local rslt = self.on_change(self)
  
  if (not rslt) then  -- revert
    self.index = self._cached_index    
    self.value = self._cached_value  
  else
    self.invalidate(self)
  end
end


--------------------------------------------------------------------------------

function UISlider:set_dimmed(bool)
  self.dimmed = bool
  self.invalidate(self)
end


--------------------------------------------------------------------------------

function UISlider:draw()
  TRACE("UISlider:draw:",self.index)
  
  local x,y,value
  local idx = self.index

  if (not self.flipped) then
    idx = self.size-idx+1
  end

  for i = 1,self.size do
    x,y = 1,1

    local point = CanvasPoint()
    point:apply(self.palette.background)

    if idx then
      if i == idx then
        -- figure out the offset within the "step",
        -- going from 0 to .ceiling value
        local step = self.ceiling/self.size
        local offset = self.value-(step*(self.index-1))
        point.val = offset*(1/step)*self.ceiling

        if self.dimmed then
          point.apply(point,self.palette.foreground_dimmed)
        else
          point.apply(point,self.palette.foreground)
        end

      elseif self.flipped then
        if(i <= idx)then
          point.val = true
          if self.dimmed then
            point.apply(point,self.palette.medium_dimmed)
          else
            point.apply(point,self.palette.medium)
          end
        end

      elseif ((self.size-i) < self.index) then

        point.val = true
        if self.dimmed then
          point.apply(point,self.palette.medium_dimmed)
        else
          point.apply(point,self.palette.medium)
        end

      end
    end

    if (self.orientation == VERTICAL) then 
      y = i
    else
      x = i  
    end
    self.canvas.write(self.canvas,point,x,y)
  end

  UIComponent.draw(self)
end


--------------------------------------------------------------------------------

function UISlider:add_listeners()

  self.display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED,
    function() self.do_press(self,self) end )

  self.display.device.message_stream:add_listener(
    self,DEVICE_EVENT_VALUE_CHANGED,
    function() self.do_change(self,self) end )

end


--------------------------------------------------------------------------------

function UISlider:remove_listeners()

  self.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED)

  self.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_VALUE_CHANGED)

end

