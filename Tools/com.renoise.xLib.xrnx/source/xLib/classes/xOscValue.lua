--[[============================================================================
xOscValue
============================================================================]]--

--[[--

A single value within a xOscMessage
.
#

]]

-------------------------------------------------------------------------------


class 'xOscValue' (xValue)

--- The type of message 
xOscValue.TAG = {
  FLOAT = "f",    -- float32
  INTEGER = "i",  -- int32
  STRING = "s",   --  OSC-string
  NUMBER = "n",   --  non-strict number (float OR integer)

}
-- more planned
--BLOB = "b",
--TIME = "t",
--FLOAT64 = "d",
--INTEGER64 = "h",
--ASCII = "c",
--MIDI = "m",     
--COLOR = "r",    
--BOOLEAN_TRUE = "T",
--BOOLEAN_FALSE = "F",
--NIL = "N",
--INF = "I",
--ALT_STRING = "S",


-------------------------------------------------------------------------------
-- [Constructor] accepts a single argument for initializing the class  
-- @param table

function xOscValue:__init(...)

  xValue.__init(self,...)
	local args = cLib.unpack_args(...)

  --- xOscValue.TAG
  self.tag = property(self.get_tag,self.set_tag)
  self.tag_observable = renoise.Document.ObservableString(args.tag or "")

end

-------------------------------------------------------------------------------

function xOscValue:get_tag()
  return self.tag_observable.value
end

function xOscValue:set_tag(val)
  assert(table.find(xOscValue.TAG,val) ~= nil, "Expected tag to be one of xOscValue.TAG")
  self.tag_observable.value = val
end

-------------------------------------------------------------------------------

function xOscValue:__tostring()

  local str = xValue.__tostring(self)
  return type(self) .. string.sub(str,17)
    ..", tag="..tostring(self.tag)

end

