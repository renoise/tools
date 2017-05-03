--[[============================================================================
xMessage
============================================================================]]--

--[[--

Abstract message class (the basis for OSC and MIDI messages)
.
#

### About

Some properties are added because of the xVoiceManager. This includes all the originating_XX properties (on by default). Usually you don't have to change these values - read the xVoiceManager description to learn what they do. 

### See also 
@{xOscMessage}
@{xMidiMessage}
@{xVoiceManager}


]]

-------------------------------------------------------------------------------

class 'xMessage' -- (xClass)

-------------------------------------------------------------------------------
-- [Constructor] accepts a single argument for initializing the class 
-- @param ...

function xMessage:__init(...)

	local args = cLib.unpack_args(...)

  -- args might be a user object - ignore and provide empty table
  if (type(args)~="table") then
    args = {}
  end

  --- number, when message got created
  self.timestamp = os.clock()
  
  --- table<xValue or implementation thereof>
  self.values = property(self.get_values,self.set_values)
  self._values = args.values or {}

  --- int, 1-num_tracks 
  self.track_index = property(self.get_track_index,self.set_track_index)
  self._track_index = args.track_index or rns.selected_track_index

  --- int, 1-num_instruments
  self.instrument_index = property(self.get_instrument_index,self.set_instrument_index)
  self._instrument_index = args.instrument_index or rns.selected_instrument_index

  --- int, 1-12 -- the note column index
  self.note_column_index = property(self.get_note_column_index,self.set_note_column_index)
  self._note_column_index = args.note_column_index or rns.selected_note_column_index

  --- int, 1-512 -- the pattern-line number
  self.line_index = property(self.get_line_index,self.set_line_index)
  self._line_index = args.line_index or rns.selected_line_index

  --- float, 0-1 -- optional high-precision value
  self.line_fraction = property(self.get_line_fraction,self.set_line_fraction)
  self._line_fraction = args.line_fraction or rns.selected_line_index

  --- int, 0-8 -- the octave 
  self.octave = property(self.get_octave,self.set_octave)
  self._octave = args.octave or rns.transport.octave

  --- the raw message, as received (or ready to send)
  self.raw_message = property(self.get_raw_message,self.set_raw_message)
  self._raw_message = args.raw_message

  -- internal --

  --- int, used when following (xVoiceManager)
  self._originating_track_index = nil

  --- int, -//-
  self._originating_instrument_index = nil

  --- int, -//-
  self._originating_octave = nil

  --- table, constructor 
  self.__def = property(self.get_definition)

  self._raw_cache = nil

end

-------------------------------------------------------------------------------
-- Getters/Setters
--------------------------------------------------------------------------------

function xMessage:get_raw_message()
  return self._raw_message
end

function xMessage:set_raw_message(val)
  self._raw_message = val
end

--------------------------------------------------------------------------------

function xMessage:get_values()
  return self._values
end

function xMessage:set_values(val)
  assert(type(val)=="table","Expected values to be a table")
  self.values = val
end

--------------------------------------------------------------------------------

function xMessage:get_track_index()
  return self._track_index
end

function xMessage:set_track_index(val)
  assert(type(val)=="number","Expected track_index to be a number")
  self._track_index = val
end

--------------------------------------------------------------------------------

function xMessage:get_instrument_index()
  return self._instrument_index
end

function xMessage:set_instrument_index(val)
  assert(type(val)=="number","Expected instrument_index to be a number")
  self._instrument_index = val
end

--------------------------------------------------------------------------------

function xMessage:get_note_column_index()
  return self._note_column_index
end

function xMessage:set_note_column_index(val)
  assert(type(val)=="number","Expected note_column_index to be a number")
  self._note_column_index = val
end

--------------------------------------------------------------------------------

function xMessage:get_line_index()
  return self._line_index
end

function xMessage:set_line_index(val)
  assert(type(val)=="number","Expected line_index to be a number")
  self._line_index = val
end

--------------------------------------------------------------------------------

function xMessage:get_octave()
  return self._octave
end

function xMessage:set_octave(val)
  assert(type(val)=="number","Expected octave to be a number")
  self._octave = val
end

-------------------------------------------------------------------------------
-- [Class] Produce a raw message (retrieve from cache if possible)
-- @return 

function xMessage:create_raw_message()
  --TRACE("xMessage:create_raw_message()")

  if self._raw_cache then
    return self._raw_cache
  else
    self._raw_cache = "hello world!"
  end

end


-------------------------------------------------------------------------------
-- [Class] Get class descriptor
-- @return table

function xMessage:get_definition()

  return {
    values = table.copy(self.values),
    track_index = self.track_index,
    instrument_index = self.instrument_index,
    note_column_index = self.note_column_index,
    line_index = self.line_index,
    octave = self.octave,
    raw_message = self.raw_message,
    _originating_instrument = self._originating_instrument,
    _originating_octave = self._originating_octave,
    _originating_track = self._originating_track,
  }

end

-------------------------------------------------------------------------------

function xMessage:__tostring()
  return type(self)..": "
    ..", timestamp="..tostring(self.timestamp)
    ..", track_index="..tostring(self.track_index)
    ..", instrument_index="..tostring(self.instrument_index)
    ..", note_column_index="..tostring(self.note_column_index)
    ..", line_index="..tostring(self.line_index)
    ..", octave="..tostring(self.octave)
    ..", #values="..tostring(#self.values)

end

