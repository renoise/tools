--[[============================================================================
xMidiCommand
============================================================================]]--

--[[--

Definition of a MIDI command within a pattern
.
#

Note: in Renoise, the MIDI command will override any existing notes when the 
number of note-columns are changed (that is, when the MIDI command "migrates" 
to the new, right-most note-column)

See also:
@{xLinePattern}


]]

class 'xMidiCommand'


xMidiCommand.TYPE = {
  CONTROLLER_CHANGE = 0,
  PITCH_BEND = 1,
  PROGRAM_CHANGE = 2,
  CH_AFTERTOUCH = 3,
}


-------------------------------------------------------------------------------

function xMidiCommand:__init(...)

	local args = cLib.unpack_args(...)

  self.instrument_index = property(self.get_instrument_index,self.set_instrument_index)
  self._instrument_index = args.instrument_index or 255 -- EMPTY

  self.message_type = property(self.get_message_type,self.set_message_type)
  self._message_type = args.message_type or xMidiCommand.TYPE.CONTROLLER_CHANGE 

  self.number_value = property(self.get_number_value)
  self.number_string = property(self.get_number_string)
  self.amount_value = property(self.get_amount_value)
  self.amount_string = property(self.get_amount_string)

  self._effect_column = xEffectColumn{
    number_value = args.number_value or 0,
    --number_string = args.number_string,
    amount_value = args.amount_value or 0,
    --amount_string = args.amount_string,
  }

end

-------------------------------------------------------------------------------
-- Getters/setters
-------------------------------------------------------------------------------

function xMidiCommand:get_number_value()
  return self._effect_column.number_value
end

function xMidiCommand:get_number_string()
  return self._effect_column.number_string
end

function xMidiCommand:get_amount_value()
  return self._effect_column.amount_value
end

function xMidiCommand:get_amount_string()
  return self._effect_column.amount_string
end

-------------------------------------------------------------------------------

function xMidiCommand:get_message_type()
  return self._message_type
end

function xMidiCommand:set_message_type(val)
  assert(type(val)=="number","Expected message_type to be a number")
  local type_count = #table.keys(xMidiCommand.TYPE)
  if (val < 1) or (val > type_count) then
    local msg = "Expected message_type to be a number between 1 and %d"
    error(msg:format(type_count))
  end
  self._message_type = val
end

-------------------------------------------------------------------------------

function xMidiCommand:get_instrument_index()
  return self._instrument_index
end

function xMidiCommand:set_instrument_index(val)
  assert(type(val)=="number","Expected instrument_index to be a number")
  if (val > 255) then
    local msg = "Expected message_type to be a number between 0 and 255"
    error(msg)
  end
  self._instrument_index = val
end

-------------------------------------------------------------------------------
-- Meta-methods
-------------------------------------------------------------------------------

function xMidiCommand:__tostring()

  return type(self)
    ..", instrument_index="..tostring(self.instrument_index)
    ..", message_type="..tostring(self.message_type)
    ..", number_string="..tostring(self.number_string)
    ..", amount_string="..tostring(self.amount_string)

end
