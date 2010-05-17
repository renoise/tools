--[[----------------------------------------------------------------------------
-- Duplex.DisplayObject
----------------------------------------------------------------------------]]--

--[[

Inheritance: DisplayObject 

The base class for UI objects

More methods:
  do_press()
  do_change()

--]]


--==============================================================================

class 'DisplayObject' 

function DisplayObject:__init(display)

  self.canvas = Canvas()    -- 
  self.display = display    -- the parent display
  self.group_name = nil    -- for indexed elements

  self.width = 1        -- set through set_size()
  self.height = 1        --

  self.palette = {}

  self.x_pos = 1
  self.y_pos = 1

  self.dirty = true      -- request refresh

  self.set_size(self,self.width,self.width)

end


--------------------------------------------------------------------------------

--  request update on next refresh

function DisplayObject:invalidate()
  self.dirty = true
end


--------------------------------------------------------------------------------

-- draw() - update the visual definition

function DisplayObject:draw()
  TRACE("DisplayObject:draw")

  self.dirty = false
end


--------------------------------------------------------------------------------

-- get_msg()  returns the last broadcast event 
--        (used by event handlers)

function DisplayObject:get_msg()
  return self.display.device.message_stream.current_message
end


--------------------------------------------------------------------------------

-- set_size()  important to use this instead 
-- of setting width/height directly (because of canvas)

function DisplayObject:set_size(width,height)
  TRACE("DisplayObject:set_size",width,height)

  self.canvas.set_size(self.canvas,width,height)
  self.width = width      
  self.height = height
end


--------------------------------------------------------------------------------

-- perform simple "inside square" hit test
-- @return (boolean) true if inside area

function DisplayObject:test(x_pos,y_pos)
  TRACE("DisplayObject:test(",x_pos,y_pos,")")

  -- pressed to the left or above?
  if x_pos < self.x_pos or y_pos < self.y_pos then
    return false
  end
  -- pressed to the right or below?
  if x_pos >= self.x_pos+self.width or 
    y_pos >= self.y_pos+self.height then
    return false
  end
  return true
end


--------------------------------------------------------------------------------

-- simple color adjustment: 
-- store original color values as "_color"

function DisplayObject:colorize(rgb)
  TRACE("DisplayObject:colorize:",rgb)

  for k,v in pairs(self.palette) do

    if not v._color then
      self.palette[k]._color = deepcopy(v.color)
    end
    v.color[1]=v._color[1]*rgb[1]/255
    v.color[2]=v._color[2]*rgb[2]/255
    v.color[3]=v._color[3]*rgb[3]/255
  end
end


--------------------------------------------------------------------------------

function DisplayObject:add_listeners()
  -- override to specify your own event handlers 
end


--------------------------------------------------------------------------------

function DisplayObject:remove_listeners()
  -- override to remove specified event handlers 
end


--------------------------------------------------------------------------------

function DisplayObject:__eq(other)
  -- only check for object identity
  return rawequal(self, other)
end  


--------------------------------------------------------------------------------

function DisplayObject:__tostring()
  return type(self)
end  

