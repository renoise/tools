--[[----------------------------------------------------------------------------
-- Duplex.UISlider
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UISlider
Requires: Globals, Display, CanvasPoint

-------------------------------------------------------------------------------

About

The Slider supports different input methods: buttons or sliders/encoders
- - use buttons to quantize the slider input
- - use faders/encoders to divide value into smaller segments
- supports horizontal/vertical and axis flipping
- display as normal/dimmed version (if supported in hardware)
- minimum size: 1

-------------------------------------------------------------------------------

Events

  on_change() - invoked whenever the slider recieve a new value


  General notes for UIComponent events:
  - if an event handler return false, we cancel/revert any changed values
  - if an event handler return true, the value (and appearance) is updated


-------------------------------------------------------------------------------

Usage

  -- create a vertical slider, 4 units in height

  local slider = UISlider(self.display)
  slider.group_name = "some_group_name"
  slider.x_pos = 1
  slider.y_pos = 1
  slider.toggleable = true
  slider.inverted = false
  slider.ceiling = 10
  slider.orientation = VERTICAL
  slider:set_size(4)
  slider.on_change = function(obj) 
    -- on_change needs to be specified, if we
    -- want the slider to respond to input
  end
  self.display:add(slider)


--]]


--==============================================================================

class 'UISlider' (UIComponent)

function UISlider:__init(display)
  TRACE('UISlider:__init')

  UIComponent.__init(self,display)

  -- the selected index (0 is deselected)
  self.index = 0

  -- default size is 0 (this will always draw)
  self.size = 0

  -- if true, press twice to switch to deselected state
  -- only applies when input method is a button
  self.toggleable = false

  -- paint a dimmed version
  self.dimmed = false

  -- current value (sliders/encoders offer more precision)
  self.value = 0

  -- slider is vertical or horizontal?
  self.orientation = VERTICAL 

  -- flip top/bottom direction 
  self.flipped = false

  -- default UIComponent size
  self:set_size(1)
  
  -- default palette
  self.palette = {
    background = table.rcopy(display.palette.background),
    tip = table.rcopy(display.palette.color_1),
    tip_dimmed = table.rcopy(display.palette.color_1_dimmed),
    track = table.rcopy(display.palette.color_2),
    track_dimmed = table.rcopy(display.palette.color_2_dimmed),
  }

  -- internal values
  self.__cached_index = self.index
  self.__cached_value = self.value

  -- attach ourself to the display message stream
  self:add_listeners()
end


--------------------------------------------------------------------------------

-- user input via button(s)
-- set index

function UISlider:do_press()
  local msg = self:get_msg()

  if not (self.group_name == msg.group_name) then
    return
  end

  if not (self:test(msg.column, msg.row)) then
    return
  end

  local idx = self:__determine_index_by_pos(msg.column, msg.row)
  if (self.toggleable and self.index == idx) then
    idx = 0
  end

  self.set_index(self,idx)
end


--------------------------------------------------------------------------------

-- user input via slider, encoder: 
-- set index + precise value within the index

function UISlider:do_change()
  TRACE("Slider:do_change()")

  local msg = self:get_msg()
  
  if not (self.group_name == msg.group_name) then
    return
  end
  
  if not self:test(msg.column,msg.row) then
    return
  end
  
  -- scale from the message range to the sliders range
  local tmp = (msg.value / msg.max) * self.ceiling / self.size
  self:set_value(tmp)
end


--------------------------------------------------------------------------------

-- setting value will also set index
-- @val (float) 
-- @skip_event (boolean) skip event handler

function UISlider:set_value(val,skip_event)
  TRACE("UISlider:set_value:",val)

  local idx = math.ceil((self.size/self.ceiling)*val)
  local rslt = false

  if (self.__cached_index ~= idx) or
     (self.__cached_value ~= val) 
  then
    self.__cached_index = idx
    self.__cached_value = val
    self.value = val
    self.index = idx
    
    self:invalidate()

    if (not skip_event) then
      self:__invoke_handler()
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
  if (self.__cached_index ~= idx) then
    self.__cached_index = idx
    self.__cached_value = self.value
    self.index = idx
    self.value = (self.ceiling/self.size)*idx
  
    if (not skip_event) then
      self:__invoke_handler()
    end
  end
end


--------------------------------------------------------------------------------

function UISlider:set_dimmed(bool)
  -- TODO: only invalidate if we can dimm
  self.dimmed = bool
  self:invalidate()
end


--------------------------------------------------------------------------------
-- Overridden from UIComponent
--------------------------------------------------------------------------------

-- setting the size will change the canvas too
-- @size (integer)

function UISlider:set_size(size)
  self.size = size

  if (self.orientation == VERTICAL) then
    UIComponent.set_size(self, 1, size)
  else
    assert(self.orientation == HORIZONTAL, 
      "Internal Error. Please report: unexpected UI orientation")
      
    UIComponent.set_size(self, size, 1)
  end
end


--------------------------------------------------------------------------------

function UISlider:draw()
  TRACE("UISlider:draw:", self.index)
  
  local idx = self.index

  if (not self.flipped) then
    idx = self.size - idx + 1
  end

  for i = 1,self.size do
    local x,y = 1,1

    local point = CanvasPoint()
    point:apply(self.palette.background)
    point.val = false      

    if (idx) then
      local apply_track = false
      if (i == idx) then
        -- figure out the offset within the "step",
        -- going from 0 to .ceiling value
        local step = self.ceiling/self.size
        local offset = self.value-(step*(self.index-1))
        point.val = offset * (1 / step) * self.ceiling
        point:apply((self.dimmed) and 
          self.palette.tip_dimmed or self.palette.tip)

      elseif (self.flipped) then
        if (i <= idx)then
          apply_track = true
        end

      elseif ((self.size - i) < self.index) then
        apply_track = true
      end
      
      if(apply_track)then
        -- if the color is completely dark, this is also how
        -- LED buttons will represent the value (turned off)
        if(get_color_average(self.palette.track.color)>0x00)then
          point.val = true        
        else
          point.val = false        
        end
        point:apply((self.dimmed) and 
          self.palette.track_dimmed or self.palette.track)
      end
    end

    if (self.orientation == VERTICAL) then 
      y = i
    else
      x = i  
    end
    
    self.canvas:write(point, x, y)
  end

  UIComponent.draw(self)
end


--------------------------------------------------------------------------------

function UISlider:add_listeners()

  self.__display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED,
    function() self:do_press() end )

  self.__display.device.message_stream:add_listener(
    self,DEVICE_EVENT_VALUE_CHANGED,
    function() self:do_change() end )

end


--------------------------------------------------------------------------------

function UISlider:remove_listeners()

  self.__display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED)

  self.__display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_VALUE_CHANGED)

end


--------------------------------------------------------------------------------
-- Private
--------------------------------------------------------------------------------

-- determine index by position, depends on orientation
-- @column (integer)
-- @row (integer)

function UISlider:__determine_index_by_pos(column,row)

  local idx,offset

  if (self.orientation == VERTICAL) then
    idx = row
    offset = self.y_pos
  else
    assert(self.orientation == HORIZONTAL, 
      "Internal Error. Please report: unexpected UI orientation")
      
    idx = column
    offset = self.x_pos
  end

  if not (self.flipped) then
    idx = (self.size-idx+offset)
  else
    idx = idx-offset+1
  end

  return idx
end


--------------------------------------------------------------------------------

-- trigger the external handler method

function UISlider:__invoke_handler()

  if (self.on_change == nil) then return end

  local rslt = self:on_change()  
  if (rslt==false) then  -- revert
    self.index = self.__cached_index    
    self.value = self.__cached_value  
  else
    self:invalidate()
  end
end


