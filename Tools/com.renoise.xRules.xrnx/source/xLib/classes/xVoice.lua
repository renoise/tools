--[[============================================================================
xLib.xVoice
============================================================================]]--

--[[

	A representation of a single voice
  
  It might look similar to xMidiMessage, but only includes the information 
  necessary to stop the voice from playing, once triggered.
  
  See also
    xVoiceManager

]]

--==============================================================================

class 'xVoice'

function xVoice:__init(...)

  local args = xLib.unpack_args(...)

  self.note = args.note
  self.velocity = args.velocity
  self.track_index = args.track_index
  self.instrument_index = args.instrument_index

end

