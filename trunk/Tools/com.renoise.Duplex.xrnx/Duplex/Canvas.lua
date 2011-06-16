--[[----------------------------------------------------------------------------
-- Duplex.Canvas
----------------------------------------------------------------------------]]--

--[[

About 

Canvas is employed by the UIComponents to represent it's visible state. The 
canvas is essentially an extra layer that we perform updates "through". Think of 
it as pre-optimization before we output to a potentially slow protocol (MIDI),
only if something has *actually* changed in the Display the update is performed. 

--]]


--==============================================================================

class 'Canvas' 

function Canvas:__init(device)
  TRACE("Canvas:__init")

  self.has_changed = false
  self.width = 0
  self.height = 0      

  -- difference buffer, cleared on each update
  self.delta = {{}}   

  -- the current (complete) representation
  self.buffer = {{}}  

  -- table of extraneous points that should be cleared on next update
  -- created when the canvas is reduced in size, and contains just a 
  -- simple set of booleans (the Display class will create the empty
  -- points when needed)
  self.clear = {}
          
end


--------------------------------------------------------------------------------

-- this should be called whenever the size of the parent UIComponent changes

function Canvas:set_size(width,height)
  TRACE('Canvas:set_size',width,height)

  local old_width = self.width
  local old_height = self.height

  self.width = width
  self.height = height
  for x = 1,width do
    --for y = 1, height do
      if not self.buffer[x] then
        self.buffer[x] = {}
        self.delta[x] = {}
      end
    --end
  end

  -- if size is reduced, update the "clear" buffer
  self.clear = {}
  for x = width,old_width do
    for y = height,old_height do
      if(x>width) or (y>height) then
        if not self.clear[x] then
          self.clear[x] = {}
        end
        self.clear[x][y] = true
        self.buffer[x][y] = nil
        if (x>width) then
          self.buffer[x] = nil
        end
      end
    end
  end



end


--------------------------------------------------------------------------------

-- write a single point to the canvas

function Canvas:write(point,x,y)
  TRACE("Canvas:write", point, x, y)
  
  if not y then y = 1 end -- if one-dimensional 
  self:check_delta(point,x,y)
  self.buffer[x][y] = point
end


--------------------------------------------------------------------------------

-- fill entire canvas with given point

function Canvas:fill(point)
  for x = 1,self.width do
    for y = 1, self.height do
      self:check_delta(point,x,y)
      self.buffer[x][y] = point
    end
  end
end


--------------------------------------------------------------------------------

-- if point is different from existing value, mark the canvas as changed 
-- both color, text and value are considered when doing the comparison

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

-- after the display has finished drawing the object, this is called
-- to clear the delta buffer and mark the canvas as unchanged

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
- value (as defined by the UIComponent): note that boolean values true/false
  is translated to their <param> max/min property counterparts, which should 
  produce an enabled/disabled state in the controller

--]]


--==============================================================================

class 'CanvasPoint' 

function CanvasPoint:__init(text,color)
  self.text = text or ""
  self.color = color or {0x00,0x00,0x00}
  self.val = false
end


--------------------------------------------------------------------------------

-- apply(): apply values from external table
-- use this to quickly customize the look of a single point

function CanvasPoint:apply(obj)
--TRACE("CanvasPoint:apply", obj)
  
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

