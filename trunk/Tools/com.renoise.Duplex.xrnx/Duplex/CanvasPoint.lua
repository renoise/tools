--[[============================================================================
-- Duplex.CanvasPoint
============================================================================]]--

--[[--

CanvasPoint represents a single position within a @{Duplex.Canvas}
  - color (table) 8-bit r/g/b values
  - text (string) button or label text 
  - value (number or table) as defined by the UIComponent


--]]


--==============================================================================

class 'CanvasPoint' 

--------------------------------------------------------------------------------

--- Initialize the Canvas class
-- @param text (string) 
-- @param color (table)
-- @param val (number or table)
--    {int,int,int}

function CanvasPoint:__init(text,color,val)
  self.text = text or ""
  self.color = color or {0x00,0x00,0x00}
  self.val = val or false
end


--------------------------------------------------------------------------------

--- Change visual appearance (text and color)
-- @param obj (table)

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

--- For debug purposes
-- @return (string)

function CanvasPoint:__tostring()
  return type(self)
end  

