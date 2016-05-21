--[[============================================================================
xLib.xVoice
============================================================================]]--

--[[--

A representation of a single voice
.
#

It might look similar to xMidiMessage, but only includes the information 
necessary to stop the voice from playing, once triggered.

See also
@{xVoiceManager}

]]

--==============================================================================

class 'xVoice'

--------------------------------------------------------------------------------
--- Constructor
-- @param args <vararg>

function xVoice:__init(...)

  local args = xLib.unpack_args(...)

  --- int
  self.note = args.note

  --- int
  self.velocity = args.velocity

  --- int
  self.track_index = args.track_index

  --- int
  self.instrument_index = args.instrument_index

end

