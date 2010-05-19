--[[----------------------------------------------------------------------------
-- Duplex.Message
----------------------------------------------------------------------------]]--

--[[

The Message class is a container for messages, closely related to the ControlMap

? use meta-table methods to control "undefined" values ?

--]]


--==============================================================================

class 'Message' 

function Message:__init(device)
  TRACE('Message:__init')

  -- the context control how the number/value is output,
  -- it might indicate a CC, or OSC message
  self.context = nil

  -- the is the actual value for the chosen parameter
  -- (not to be confused with the control-map value)
  self.value = nil

  -- meta values are useful for further refinement of messages,
  -- for example by defining the expected/allowed range of values

  self.id = nil --  unique id for each parameter
  self.group_name = nil --  name of the parent group 
  self.index = nil --  (int) index within control-map group, zero-based
  self.column = nil --  (int) column, starting from 1
  self.row = nil --  (int) row, starting from 1
  self.timestamp = nil --  set by os.clock() 
  self.name = nil --  the parameter name
  self.max = nil --  maximum accepted/output value
  self.min = nil --  minimum accepted/output value
  
  --  the type - "button", "encoder", etc.
  -- will allow the virtual control surface to respond smarter 
  self.input_method = nil 
end


--------------------------------------------------------------------------------

function Message:__tostring()
  return string.format("message: context:%s, group_name:%s",
    totring(self.context), tostring(self.group_name))
end

