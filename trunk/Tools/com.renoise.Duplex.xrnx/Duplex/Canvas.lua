--[[============================================================================
-- Duplex.Canvas
============================================================================]]--

--[[--

Employed by the UIComponents to represent their visual state

The canvas is a two-dimensional table of CanvasPoints which can be resized. 
Each CanvasPoint specifies both the visual appearance of a button (via color or text), as well as any sort of value that the UIComponent might define. 

Also, the canvas is the layer we perform our updates "through". By checking the "delta", we can decide if something has *actually* changed before the update is performed. 

Think of it as pre-optimization - both cabled MIDI and wireless devices are capable of choking or skipping messages. 

--]]

--==============================================================================

class 'Canvas' 

--------------------------------------------------------------------------------

--- Initialize the Canvas class
-- @param device (Device) 

function Canvas:__init(device)
  TRACE("Canvas:__init")

  --- (bool) flag when we need to update the display
  self.has_changed = false

  --- (int) canvas width 
  self.width = 0

  --- (int) canvas height
  self.height = 0      

  --- (table) difference buffer, cleared on each update
  self.delta = {{}}   

  --- (table) the current, complete representation
  self.buffer = {{}}  

  --- table of extraneous points that should be cleared on next update
  -- created when the canvas is reduced in size, and contains just a 
  -- simple set of booleans (the Display class will create the empty
  -- points when needed)
  self.clear = {}

end


--------------------------------------------------------------------------------

--- Call whenever the size of the parent UIComponent changes
-- @param width (int)
-- @param height (int)

function Canvas:set_size(width,height)
  TRACE('Canvas:set_size',width,height)

  local old_width = self.width
  local old_height = self.height

  self.width = width
  self.height = height
  for x = 1,width do
    if not self.buffer[x] then
      self.buffer[x] = {}
      self.delta[x] = {}
    end
  end

  -- if size is reduced, update the "clear" buffer
  local new_table,is_reduced = {},false
  for x = width,old_width do
    for y = height,old_height do
      if(x>width) or (y>height) then
        is_reduced = true
        if not self.clear[x] then
          new_table[x] = {}
        end
        new_table[x][y] = true
        self.buffer[x][y] = nil
        if (x>width) then
          self.buffer[x] = nil
        end
      end
    end
  end
  if is_reduced then 
    self.clear = new_table
  end



end


--------------------------------------------------------------------------------

--- Write a single point to the canvas at the provided x/y coordinates
-- @param point (@{Duplex.CanvasPoint})
-- @param x (int) 
-- @param y (int)

function Canvas:write(point,x,y)
  --TRACE("Canvas:write", point, x, y)
  
  if not y then y = 1 end -- if one-dimensional 
  self:check_delta(point,x,y)
  self.buffer[x][y] = point
end


--------------------------------------------------------------------------------

--- Fill/flood entire canvas with given point
-- @param point (@{Duplex.CanvasPoint})

function Canvas:fill(point)
  for x = 1,self.width do
    for y = 1, self.height do
      self:check_delta(point,x,y)
      self.buffer[x][y] = point
    end
  end
end


--------------------------------------------------------------------------------

--- If point is different from existing value, mark the canvas as changed 
-- both color, text and value are considered when doing the comparison
-- @param point (@{Duplex.CanvasPoint})
-- @param x (int) 
-- @param y (int)

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

--- After the display has finished drawing the object, this is called
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


