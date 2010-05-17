--[[----------------------------------------------------------------------------
-- Duplex.Point
----------------------------------------------------------------------------]]--

--[[

Point represents a point in a canvas (text,color)

--]]


--==============================================================================

class 'Point' 

function Point:__init(text,color)
  self.text = text or ""
  self.color = color or {0x00,0x00,0x00}
  self.val = false
end


--------------------------------------------------------------------------------

-- apply(): import key/values pairs from external 
-- object without replacing existing keys
-- todo: simply import text and color!

function Point:apply(obj)
--print(obj)
  for k,v in pairs(obj) do
    if (k=="text")then
      self.text = v
    end
    if (k=="color")then
      self.color = v
    end
  end
end

