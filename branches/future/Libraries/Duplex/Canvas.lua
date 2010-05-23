--[[----------------------------------------------------------------------------
-- Duplex.Canvas
----------------------------------------------------------------------------]]--

--[[

Use a Canvas class to represent values in a 2-dimensional space
- incremental output: maintains a delta buffer with recent values

--]]


--==============================================================================

class 'Canvas' 

function Canvas:__init(device)
  TRACE("Canvas:__init")

  self.has_changed = false
  self.width = 0
  self.height = 0      
  self.delta = {{}}    
  self.buffer = {{}}
end


--------------------------------------------------------------------------------

-- called when changing the size of the parent display-object, 
-- to ensure that write() will not throw an error

function Canvas:set_size(width,height)
  TRACE('Canvas:set_size',width,height)
  
  self.width = width
  self.height = height
  for x = 1,width do
    for y = 1, height do
      if not self.buffer[x] then
        self.buffer[x] = {}
        self.delta[x] = {}
      end
    end
  end

end


--------------------------------------------------------------------------------

function Canvas:write(point,x,y)
  TRACE("Canvas:write", point, x, y)
  
  if not y then y = 1 end -- if one-dimensional 
  self:check_delta(point,x,y)
  self.buffer[x][y] = point
end


--------------------------------------------------------------------------------

function Canvas:fill(point)
  for x = 1,self.width do
    for y = 1, self.height do
      self:check_delta(point,x,y)
      self.buffer[x][y] = point
    end
  end
end


--------------------------------------------------------------------------------

function Canvas:check_delta(point,x,y)
  if not self.buffer[x][y] 
  or not(self.buffer[x][y].color == point.color) 
  or not(self.buffer[x][y].text == point.text) 
  or not(self.buffer[x][y].val == point.val) then
    self.delta[x][y] = point
    self.has_changed = true
  end
end


--------------------------------------------------------------------------------

function Canvas:clear_delta()
  self.delta = {{}}
  for x = 1,self.width do
    for y = 1, self.height do
      self.delta[x] = {}
    end
  end
  self.has_changed = false
end


--------------------------------------------------------------------------------

function Canvas:__tostring()
  return type(self)
end  


--[[----------------------------------------------------------------------------
-- Duplex.CanvasPoint
----------------------------------------------------------------------------]]--

--[[

CanvasPoint represents a point in a canvas 
- color (table of 8-bit r/g/b values)
- text (replacement for color, for labelling buttons)
- value (as defined by the UIComponent)

--]]


--==============================================================================

class 'CanvasPoint' 

function CanvasPoint:__init(text,color)
  self.text = text or ""
  self.color = color or {0x00,0x00,0x00}
  self.val = false
end


--------------------------------------------------------------------------------

-- apply(): import key/values pairs from external 
-- object without replacing existing keys
-- todo: simply import text and color!

function CanvasPoint:apply(obj)
  TRACE("CanvasPoint:apply", obj)
  
  for k,v in pairs(obj) do
    if (k=="text")then
      self.text = v
    end
    if (k=="color")then
      self.color = v
    end
  end
end


--------------------------------------------------------------------------------

function CanvasPoint:__tostring()
  return type(self)
end  

