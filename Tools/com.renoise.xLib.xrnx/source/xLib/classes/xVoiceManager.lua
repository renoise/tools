--[[============================================================================
xLib.xVoiceManager
============================================================================]]--

--[[--

This class keeps track of active, playing voices as they are triggered.
.
#

When releasing a voice, the class triggers the provided callback method. So, you can use this with external MIDI devices or the internal OSC server. 

]]

--==============================================================================

class 'xVoiceManager'

function xVoiceManager:__init(...)

  local args = xLib.unpack_args(...)

  --- the maximum number of voices (0 = 'unlimited')
  -- TODO not yet implemented
  self.voice_limit = property(self.get_voice_limit,self.set_voice_limit)
  self.voice_limit_observable = renoise.Document.ObservableNumber()

  --- number, note duration in seconds (0 = infinite)
  self.duration = property(self.get_duration,self.set_duration)
  self.duration_observable = renoise.Document.ObservableNumber(0)

  --- table<xMidiMessage>, active voices
  self.voices = {}
  self.voices_observable = renoise.Document.ObservableNumberList()

  --- bool, whether to use automatic column allocation or not
  self.column_allocation = property(self.get_column_allocation,self.set_column_allocation)
  self.column_allocation_observable = renoise.Document.ObservableBoolean(false)

  --- TODO table<xMidiMessage>, voice messages (such as aftertouch)
  self.voice_msgs = {}

  --- TODO table<xMidiMessage>, channel messages (such as pitchbend)
  self.channel_msgs = {}

  --- voice about to be released (0 = none)
  self.released_index = renoise.Document.ObservableNumber(0)
  self.released_observable = renoise.Document.ObservableBang()

  --- newly triggered voice (0 = none)
  self.triggered_index = renoise.Document.ObservableNumber(0)
  self.triggered_observable = renoise.Document.ObservableBang()

  -- initialize

  renoise.tool().app_new_document_observable:add_notifier(function()
    rns = renoise.song()
    self:attach_to_song()
  end)

  renoise.tool().app_idle_observable:add_notifier(function()
    if (self.duration > 0) then
      self:check_expired()
    end
  end)

  self:attach_to_song()

end

--==============================================================================
-- Getters and setters 
--==============================================================================

function xVoiceManager:get_voice_limit()
  return self.voice_limit_observable.value
end

function xVoiceManager:set_voice_limit(val)

  -- if less than current #voices, release oldest ones first
  if (val < #self.voices) then
    for k = 1,(#self.voices-val) do
      self:release(k)
    end
  end

  self.voice_limit_observable.value = val

end

-------------------------------------------------------------------------------

function xVoiceManager:get_duration()
  return self.duration_observable.value
end

function xVoiceManager:set_duration(val)
  self.duration_observable.value = val
end

-------------------------------------------------------------------------------

function xVoiceManager:get_column_allocation()
  return self.column_allocation_observable.value
end

function xVoiceManager:set_column_allocation(val)
  self.column_allocation_observable.value = val
end

-------------------------------------------------------------------------------
--- @return table<int> containing all active MIDI-pitches
--[[
function xVoiceManager:get_active_notes()
  TRACE("xVoiceManager:get_active_notes()")

  local rslt = {}
  for k,v in ipairs(self.voices) do
    table.insert(rslt,v.values[2])
  end
  return rslt

end
]]

--==============================================================================
-- Class Methods
--==============================================================================
-- pass any message here - only note-on/off messages are processed
-- @param xmsg (xMidiMessage)
-- @return bool (true=added/removed, false=active) or nil 
-- @return int (voice index), when added or active

function xVoiceManager:input_message(xmsg)
  TRACE("xVoiceManager:input_message(xmsg)",xmsg)

  assert(type(xmsg)=="xMidiMessage","Expected xmsg to be xMidiMessage")

  if (xmsg.message_type ~= xMidiMessage.TYPE.NOTE_ON) 
    and (xmsg.message_type ~= xMidiMessage.TYPE.NOTE_OFF) 
  then
    LOG("xVoiceManager accepts note messages only ")
    return
  end

  local voice_idx = self:get_voice_index(xmsg)
  --print("voice_idx",voice_idx)
  if voice_idx then
    if (xmsg.message_type == xMidiMessage.TYPE.NOTE_OFF) then
      self:release(voice_idx)
      return true
    else
      LOG("*** xVoiceManager:input_message() - voice is already active")
      return false,voice_idx
    end
  end

  self:register(xmsg)
  return true,#self.voices

end

-------------------------------------------------------------------------------
-- register a voice

function xVoiceManager:register(xmsg)
  TRACE("xVoiceManager:register(xmsg)",xmsg)

  if self.column_allocation then
    --print(">>> register - xmsg.note_column_index PRE",xmsg.note_column_index)
    local available_columns = self:get_available_columns(xmsg.track_index)
    if not table.is_empty(available_columns) then
      local is_available = xmsg.note_column_index 
        and table.find(available_columns,xmsg.note_column_index) or false
      if not is_available then
        xmsg.note_column_index = available_columns[1]
      end
    else
      LOG("No more note columns available, using the last one")
      xmsg.note_column_index = 12
    end
    --print(">>> register - xmsg.note_column_index POST",xmsg.note_column_index)
  end

  table.insert(self.voices,xmsg)
  self.voices_observable:insert(#self.voices)

  -- trigger observable after adding
  self.triggered_index.value = #self.voices
  self.triggered_observable:bang()


end

-------------------------------------------------------------------------------
-- Release all active voices

function xVoiceManager:release_all()
  TRACE("xVoiceManager:release_all()")

  for k,v in ripairs(self.voices) do
    self:release(k)
    --print("released voice #",k)
  end

end

-------------------------------------------------------------------------------
-- Release all voices associated with a specific instrument

function xVoiceManager:release_all_instrument(instr_idx)
  TRACE("xVoiceManager:release_all_instrument(instr_idx)",instr_idx)

  for k,v in ripairs(self.voices) do
    if (v.instrument_index == instr_idx) then
      self:release(k)
    end
  end
end

-------------------------------------------------------------------------------
-- Release all voices associated with a specific track

function xVoiceManager:release_all_track(track_idx)
  TRACE("xVoiceManager:release_all_track(track_idx)",track_idx)

  for k,v in ripairs(self.voices) do
    if (v.track_index == track_idx) then
      self:release(k)
    end
  end
end

-------------------------------------------------------------------------------
-- release specific voice

function xVoiceManager:release(voice_idx)
  TRACE("xVoiceManager:release(voice_idx)",voice_idx)

  -- trigger observable before removing 
  self.released_index.value = voice_idx
  self.released_observable:bang()

  table.remove(self.voices,voice_idx)
  self.voices_observable:remove(voice_idx)

end

-------------------------------------------------------------------------------
-- check if any voices have expired (when duration is set)

function xVoiceManager:check_expired()
  --TRACE("xVoiceManager:check_expired()")

  for k,v in ripairs(self.voices) do
    local age = os.clock() - v.timestamp
    if (age > self.duration) then
      --print("release expired voice with age",age)
      self:release(k)
    end
  end

end

-------------------------------------------------------------------------------
-- locate among active voices, taking the pitch + track + instrument into
-- consideration (if all match, the voice is considered active...)
-- @param xmsg (xMidiMessage) should be a MIDI note-message
-- @return number or nil 

function xVoiceManager:get_voice_index(xmsg)
  TRACE("xVoiceManager:get_voice_index(xmsg)",xmsg)

  if xmsg.message_type 
    and (xmsg.message_type ~= xMidiMessage.TYPE.NOTE_ON
    and xmsg.message_type ~= xMidiMessage.TYPE.NOTE_OFF
    and xmsg.message_type ~= xMidiMessage.TYPE.KEY_AFTERTOUCH)
  then
    LOG("*** xVoiceManager:input_message() - only MIDI notes and key-aftertouch are accepted")
    return
  end

  -- note/aftertouch, both are second byte
  local note = xmsg.values[1]

  for k,v in ipairs(self.voices) do
    if (v.values[1] == note) 
      and xmsg.channel and (v.channel == xmsg.channel)
      and xmsg.track_index and (v.track_index == xmsg.track_index)
      and xmsg.instrument_index and (v.instrument_index == xmsg.instrument_index)
    then
      return k
    end
  end

end

-------------------------------------------------------------------------------
-- @param track_idx
-- @return table

function xVoiceManager:get_available_columns(track_idx)

  local available_indices = {1,2,3,4,5,6,7,8,9,10,11,12}
  for k,v in ipairs(self.voices) do
    if (v.track_index == track_idx) then
      if (table.find(available_indices,v.note_column_index)) then
        table.remove(available_indices,v.note_column_index)
      end
    end
  end
  table.sort(available_indices)
  return available_indices

end
-------------------------------------------------------------------------------
-- Monitor changes to tracks and instruments

function xVoiceManager:attach_to_song()

  rns.instruments_observable:add_notifier(function(arg)
    TRACE("xVoiceManager: instruments_observable fired...",rprint(arg))
    if (arg.type == "remove") then
      self:release_all_instrument(arg.index)
    elseif (arg.type == "insert") then
      for k,v in ipairs(self.voices) do
        if (v.track_index >= arg.index) then
          v.track_index = v.track_index + 1
          --print("raise track index by 1")
        end
      end
    end

    --print("instruments_observable - self.voices...",rprint(self.voices))

  end)

  rns.tracks_observable:add_notifier(function(arg)
    TRACE("xVoiceManager: tracks_observable fired...",rprint(arg))

    if (arg.type == "remove") then
      self:release_all_track(arg.index)
    elseif (arg.type == "insert") then
      for k,v in ipairs(self.voices) do
        if (v.track_index >= arg.index) then
          v.track_index = v.track_index + 1
          --print("raise track index by 1")
        end
      end
    end

    --print("tracks_observable - self.voices...",rprint(self.voices))

  end)

end

