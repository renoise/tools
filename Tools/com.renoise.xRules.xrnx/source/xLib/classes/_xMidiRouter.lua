--[[============================================================================
xMidiRouter
============================================================================]]--
--[[--

A simple MIDI router using xMidiMessage instances to describe routes
.
#

### Notes

* Undefined properties will make a pattern less specific (catch all)
* The class provides caching for messages that support it

### Examples

  -- match all notes on channel one:
  {message_type = "note_on", channel = 1, value1 = nil}

  -- match only C-4 on channel 10
  {message_type = "note_on", channel = 10, value1 = 48}

  -- match a specific sysex message 
  {message_type = "sysex", value1 = {0xFC,0xFE,0xFF}}


--]]

-------------------------------------------------------------------------------

class 'xMidiRouter'

function xMidiRouter:__init(...)

  local args = xLib.unpack_args(...)

  self.patterns = property(self.get_patterns,self.set_patterns)
  self._patterns = args.patterns or {}

  -- internal --

  self.cache = {}

end
