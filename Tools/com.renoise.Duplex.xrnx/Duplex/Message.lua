--[[===============================================================================================
Message
===============================================================================================]]--

--[[--

The Message class is a container for messages, closely related to the ControlMap

See also:
@{Duplex.ControlMap}

--]]


class 'Message' 

---------------------------------------------------------------------------------------------------

--- Initialize Message class
-- @param device (Device)

function Message:__init(device)
  TRACE('Message:__init')

  --- (@{Duplex.Globals.DEVICE_MESSAGE}) the message context
  self.context = nil

  --- (table) `Param` node attributes, derived from the control-map
  -- @see Duplex.ControlMap
  self.xarg = table.create()

  --- (@{Duplex.Device}) reference to the originating device
  self.device = nil

  --- (table, number or string) the value for the chosen parameter 
  -- the type of value depend on what type of parameter we are controlling:
  -- a slider would have a number, a label a string, xypad a pair of numbers
  self.value = nil

  --- (int) the MIDI channel of the message, between 1-16
  -- (derived from the value parameter in the control-map)
  self.channel = nil 

  --- (bool) distinguish between MIDI NOTE-ON/OFF events
  self.is_note_off = false

  --- (bool) true when triggered from the virtual control surface
  self.is_virtual = false

  --- (table) the MIDI message payload (each entry a table of 3 bytes)
  -- this is either a copy of the message(s) we received from a MIDI controller,
  -- or a value being constructed by the virtual control surface
  self.midi_msgs = nil

  --- (number) set by os.clock() 
  self.timestamp = os.clock()  

  -- (bool) true once the button is held for a while
  self.held_event_fired = false

end

---------------------------------------------------------------------------------------------------
-- [Class] Retrieve the 'default', numeric value for a message 
-- v2: It's too obscure what this method does 
-- @return number or nil

function Message:get_numeric_value()
  TRACE("Message:get_numeric_value()")

  if (type(self.value) == "table") then
    return self.value[2] -- velocity for MIDI NOTE, 
  else
    return self.value 
  end

end  


---------------------------------------------------------------------------------------------------
-- [Class] Compare with another instance (only check for object identity)
-- @param other (@{Duplex.Message}) 
-- @return bool

function Message:__eq(other)
  return rawequal(self, other)
end  


---------------------------------------------------------------------------------------------------
-- [Class] For debugging purposes

function Message:__tostring()
  return type(self)
end

