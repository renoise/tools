--[[============================================================================
xLib.xVoiceManager
============================================================================]]--

--[[

	This class keeps track of active, playing voices

  When releasing a voice, the class triggers the provided callback method.
  So, you can use this with external MIDI devices or the internal OSC server - it's basically up to the callback method to decide what happens. 

]]

--==============================================================================

class 'xVoiceManager'

function xVoiceManager:__init()

  -- table<xMidiMessage>, active voices
  self.voices = {}
  self.voices_observable = renoise.Document.ObservableNumberList()

end

-------------------------------------------------------------------------------
-- pass any message here - only note-on/off messages are processed

function xVoiceManager:input_message(xmsg)

  -- TODO

end

-------------------------------------------------------------------------------
-- register a voice

function xVoiceManager:register(xmsg)

  table.insert(self.voices,xmsg)
  self.voices_observable:insert(#self.voices)

end

-------------------------------------------------------------------------------
-- release all active voices

function xVoiceManager:release_all()

  for k,v in ipairs(self.voices) do
    self:release(k)
  end

end

-------------------------------------------------------------------------------
-- release specific voice

function xVoiceManager:release(voice_idx)

  -- TODO trigger callback, which 
  table.remove(self.voices,voice_idx)
  self.voices_observable:remove(voice_idx)

end

-------------------------------------------------------------------------------
-- compare message to active voices
-- @return boolean, true when matched

function xVoiceManager:is_active(xmsg)

  -- TODO

end


