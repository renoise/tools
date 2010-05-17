--[[----------------------------------------------------------------------------
-- Duplex.Canvas
----------------------------------------------------------------------------]]--

--[[

Use a Canvas class to represent values in a 2-dimensional space
- incremental output: maintains a delta buffer with recent values
- each point is represented by 
- - value (as defined by the DisplayObject)
- - text (replacement for color, for labelling buttons)
- - color (not yet implemented)

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
  self.check_delta(self,point,x,y)
  self.buffer[x][y] = point
end


--------------------------------------------------------------------------------

function Canvas:fill(point)
  for x = 1,self.width do
    for y = 1, self.height do
      self.check_delta(self,point,x,y)
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

