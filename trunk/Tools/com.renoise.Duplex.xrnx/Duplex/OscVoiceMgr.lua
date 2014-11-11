--[[============================================================================
-- Duplex.OscVoiceMgr
============================================================================]]--

--[[--
The OscVoiceMgr is a class for handling internally triggered notes, keeping track of the active voices and their context

The purpose is to keep track of active voices, and their context: how the note got triggered: which device/application/instrument/pitch etc.

Some of the problems that a voice-manager can solve:

* Notes are getting stuck when a keyboard octave is "virtually transposed", as the released key will transmit a different pitch than the pressed one. Solution: simply tell the voice-manager that your application's base octave has been changed with this & that many semitones. 
* When the same note is triggered multiple times, once any key is released, the remaining voices are also stopped. Solution: Trigger notes with the `keep_until_all_released` flag, and the note is kept alive until all pressed notes are released

### Changes

  0.99.4
    - Support for trigger options (hold/mono modes)
    - Register_callback(), makes apps able to receive notifications

  0.98.15
    - First release 



--]]

--==============================================================================

class 'OscVoiceMgr'

--------------------------------------------------------------------------------

--- Initialize the OscVoiceMgr class

function OscVoiceMgr:__init()

  -- table,OscVoiceMgrNote
  self.playing = table.create()

  -- table, Duplex.Application
  self._callbacks = table.create()


end

--------------------------------------------------------------------------------

--- This is the main trigger function
-- @param app (@{Duplex.Application}) the calling application 
-- @param instr_idx (int) the Renoise instrument index
-- @param track_idx (int) the Renoise track index
-- @param pitch (int) 0-120
-- @param velocity (int) 0-127
-- @param keep (bool) if true, keep all notes until release
-- @param is_midi (bool) to distinguish between OSC and MIDI notes
-- @param channel (int) the MIDI channel, 1-16 (not used!!)

function OscVoiceMgr:trigger(app,instr_idx,track_idx,pitch,velocity,keep,is_midi,channel)
  TRACE("OscVoiceMgr:trigger()",app,instr_idx,track_idx,pitch,velocity,keep,is_midi,channel)

  local rns = renoise.song()
  --local channel = 1 -- TODO

  local instr = rns.instruments[instr_idx]
  assert(instr,"Internal Error. Please report: " ..
    "expected an instrument at index",instr_idx)


  local hold_toggled_off = false

  -- if the instrument is set to hold mode, toggle the note 
  --print("hold_trigger_enabled,#self.playing",hold_trigger_enabled,#self.playing)
  if instr.trigger_options.hold then
  	for k,v in ipairs(self.playing) do
      --print("v.instr_idx,instr_idx",v.instr_idx,instr_idx)
      --print("v.pitch,pitch.v.pitch",pitch)
  		if (v.instr_idx == instr_idx) and
        (v.pitch == pitch)
      then
        local force_release = true
  			--self:release(app,instr_idx,v.track_idx,v.pitch,v.velocity,v.is_midi,v.channel,force_release)
        self:_notify_applications("remove",v,k)
        self.playing:remove(k)
  			--print("*** OscVoiceMgr cancel a voice due to hold - number of voices remaining: #",#self.playing)
        hold_toggled_off = true
  		end
  	end
  end

  -- if instrument is set to solo, cancel the previous note for that instrument
  if instr.trigger_options.monophonic then
  	for k,v in ipairs(self.playing) do
  		if (v.instr_idx == instr_idx) then
        local force_release = true
  			self:release(app,instr_idx,v.track_idx,v.pitch,v.velocity,v.is_midi,v.channel,force_release)
  			--print("*** OscVoiceMgr cancelled a voice due to mono - number of voices remaining: #",#self.playing)
        --hold_toggled_off = true
  		end
  	end
  end

  self:_trigger_note(app,instr_idx,track_idx,pitch,velocity,is_midi,channel)

  if not hold_toggled_off then
    -- register the note with the voice-manager
    local note = OscVoiceMgrNote(app,instr_idx,track_idx,pitch,velocity,keep,is_midi,channel)
    note.triggered_with_hold_mode = instr.trigger_options.hold and true or false
    self:_notify_applications("insert",note)
    self.playing:insert(note)
  end

  --print("*** trigger() - playing",#self.playing)

end


--------------------------------------------------------------------------------

--- The main release function. Will ensure that the right notes are released, 
-- even when the keyboard has been transposed since the notes were triggered
-- @param app (@{Duplex.Application}) the calling application 
-- @param instr_idx (int) the Renoise instrument index
-- @param track_idx (int) the Renoise track index
-- @param pitch (int) 0-120
-- @param velocity (int) 0-127
-- @param is_midi (bool) to distinguish between OSC and MIDI notes
-- @param channel (int) the MIDI channel, 1-16
-- @param force (bool) skip the check for hold mode
-- @return int, the amount of temp-transpose detected (in semitones)
-- @see OscVoiceMgr:_release_note

function OscVoiceMgr:release(app,instr_idx,track_idx,pitch,velocity,is_midi,channel,force)
  TRACE("OscVoiceMgr:release()",app,instr_idx,track_idx,pitch,velocity,is_midi,channel,force)

  local transp = 0
  local str_app = self:_get_app_name(app)

  --channel = 1 -- TODO

  local rns = renoise.song()
  assert(rns.instruments[instr_idx],string.format("Internal Error. Please report: " ..
    "expected instrument to be present at index %d",instr_idx))

  local hold_trigger_enabled = rns.instruments[instr_idx].trigger_options.hold

  -- if the instrument is set to hold mode, do not release 
  if not force then
    --print("hold_trigger_enabled,#self.playing",hold_trigger_enabled,#self.playing)
    if hold_trigger_enabled then
      for k,v in ripairs(self.playing) do
        if (v.instr_idx == instr_idx) 
          and (v.is_held) 
          and (v.originating_app == str_app) 
          and (v.pitch-v.temp_transpose == pitch)
        then
          --print("*** OscVoiceMgr do not release note yet (toggle mode)")
          v.is_held = false
        end
        return transp
      end

    end
  end

  for k,v in ripairs(self.playing) do
    local release_note = false

    --print("OscVoiceMgr:release() - v.instr",v)
    --print("OscVoiceMgr:release() - v.instr",v.instr_idx,instr_idx)
    --print("OscVoiceMgr:release() - v.originating_app",v.originating_app,str_app)
    --print("OscVoiceMgr:release() - v.is_midi",v.is_midi)
    --print("OscVoiceMgr:release() - v.temp_transpose",v.temp_transpose)
    --print("OscVoiceMgr:release() - v.pitch",v.pitch,pitch)
    --print("OscVoiceMgr:release() - v.pitch-v.temp_transpose",v.pitch-v.temp_transpose)

    if (v.instr_idx == instr_idx) 
      --and (v.is_held) 
      and (v.originating_app == str_app) 
      and (v.pitch-v.temp_transpose == pitch)
    then
      release_note = true
      transp = v.temp_transpose
    end
    if release_note then 

      local keep = v.keep_until_all_released
      local transp = v.temp_transpose

      -- before removing, check the triggered method
      -- (for example, when a keyboard is transposed beyond it's active range)
      if is_midi then
        if self:_was_osc_triggered(str_app,pitch+v.temp_transpose,channel) then
          --print("*** OscVoiceMgr transposed into midi keys, release osc")
          is_midi = false
        else
          transp = 0 
        end
      elseif self:_was_midi_triggered(str_app,pitch+v.temp_transpose,channel) then
        --print("*** OscVoiceMgr transposed into osc keys, release midi")
        is_midi = true
        transp = 0 
      end

      self:_notify_applications("remove",v,k)
      self.playing:remove(k)

      -- cut note only if "keep all until released" is false,
      -- or we have in fact released all keys 
      local is_active = self:note_is_active(instr_idx,pitch)
      if not is_active or not keep then
        if (v.triggered_with_hold_mode) or
          hold_trigger_enabled
        then
          self:_trigger_note(app,instr_idx,track_idx,pitch+transp,velocity,is_midi,channel)
        else
          self:_release_note(app,instr_idx,track_idx,pitch+transp,velocity,is_midi,channel)
        end
      end

      return transp
    end
  end
  return transp

end

--------------------------------------------------------------------------------

--- If OSC triggered this note, return true
-- @param str_app (@{Duplex.Application}), the originating application
-- @param pitch (int) 0-120
-- @param channel (int) the MIDI channel, 1-16
-- @return bool

function OscVoiceMgr:_was_osc_triggered(str_app,pitch,channel)
  TRACE("OscVoiceMgr:_was_osc_triggered()",str_app,pitch,channel)

  for k,v in ipairs(self.playing) do
    if (not v.is_midi) 
      and (v.pitch == pitch) 
      and (v.originating_app == str_app)
      and (v.channel == channel) 
    then
      return true
    end
  end

end

--------------------------------------------------------------------------------

--- If MIDI triggered this note, return true
-- @param str_app (@{Duplex.Application}), the originating application
-- @param pitch (int) 0-120
-- @param channel (int) the MIDI channel, 1-16
-- @return bool

function OscVoiceMgr:_was_midi_triggered(str_app,pitch,channel)
  TRACE("OscVoiceMgr:_was_midi_triggered()",str_app,pitch,channel)

  for k,v in ipairs(self.playing) do
    if (v.is_midi) 
      and (v.pitch == pitch) 
      and (v.originating_app == str_app)
      and (v.channel == channel) 
    then
      return true
    end
  end

end

--------------------------------------------------------------------------------

--- Trigger a note
-- note: also used for turning off notes using "hold mode"

function OscVoiceMgr:_trigger_note(app,instr_idx,track_idx,pitch,velocity,is_midi,channel)
  TRACE("OscVoiceMgr:_trigger_note()",app,instr_idx,track_idx,pitch,velocity,is_midi,channel)

  local osc_client = app._process.browser._osc_client
  assert(osc_client,"Internal Error. Please report: " ..
    "expected internal OSC client to be present")

  if not is_midi then
    --print("*** OscVoiceMgr trigger_instrument(true,...)",instr_idx,track_idx,pitch,velocity)
    osc_client:trigger_instrument(true,instr_idx,track_idx,pitch,velocity) 
  else
    local pitch_offset = self:_get_pitch_offset()
    osc_client:trigger_midi({143+channel,pitch+pitch_offset,velocity}) 
  end
end

--------------------------------------------------------------------------------

--- Release a given note. We do not release notes directly,
-- this method is called by the main release() method when it has been 
-- determined that a note should be released
-- @param app (@{Duplex.Application}), the originating application
-- @param instr_idx (int) the Renoise instrument index
-- @param track_idx (int) the Renoise track index
-- @param pitch (int) 0-120
-- @param velocity (int) 0-127
-- @param is_midi (bool) to distinguish between OSC and MIDI notes
-- @param channel (int) the MIDI channel, 1-16
-- @see OscVoiceMgr:release

function OscVoiceMgr:_release_note(app,instr_idx,track_idx,pitch,velocity,is_midi,channel)
  TRACE("OscVoiceMgr:_release_note()",app,instr_idx,track_idx,pitch,velocity,is_midi,channel)

  if is_midi then
    local channel = 1
    self:_send_midi_release(app,pitch,velocity,channel)
  else
    self:_send_osc_release(app,instr_idx,track_idx,pitch,velocity)
  end

end


-- osc release

function OscVoiceMgr:_send_osc_release(app,instr_idx,track_idx,pitch,velocity)
  TRACE("OscVoiceMgr:_send_osc_release()",app,instr_idx,track_idx,pitch,velocity)
  
  local osc_client = app._process.browser._osc_client
  assert(osc_client,"Internal Error. Please report: " ..
    "expected internal OSC client to be present")
  --print("*** OscVoiceMgr trigger_instrument(false,...)",instr_idx,track_idx,pitch,velocity)
  osc_client:trigger_instrument(false,instr_idx,track_idx,pitch,velocity)

end

-- midi release

function OscVoiceMgr:_send_midi_release(app,pitch,velocity,channel)
  TRACE("OscVoiceMgr:_send_midi_release()",app,pitch,velocity,channel)
  
  local osc_client = app._process.browser._osc_client
  assert(osc_client,"Internal Error. Please report: " ..
    "expected internal OSC client to be present")
  local pitch_offset = self:_get_pitch_offset()
  local t = {143+channel,pitch+pitch_offset,0}
  --rprint(t)
  osc_client:trigger_midi(t) 


end



--------------------------------------------------------------------------------

--- Return the pitch offset, a value which is used to "counter-transpose"
-- the transposition amount which Renoise automatically assign to MIDI-notes
-- (the value of which based on the current octave). 
-- @return int, number of semitones

function OscVoiceMgr:_get_pitch_offset()

  local pitch_offset = 48-(math.floor(renoise.song().transport.octave)*12)
  return pitch_offset

end

--------------------------------------------------------------------------------

--- Return a unique name for any running process/application
-- (can be called as static method)
-- @param app (@{Duplex.Application})
-- @return string, e.g. "Launchpad_MyMixer"

function OscVoiceMgr:_get_app_name(app)
  TRACE("OscVoiceMgr:_get_app_name()",app._app_name)

  if not app._process.configuration then
    LOG("Warning: voice manager received a process without a configuration",app._process)
    return ""
  end

  local device_name = app._process.configuration.device.display_name
  return ("%s_%s"):format(device_name,app._app_name)

end

--------------------------------------------------------------------------------

--- Check if a particular instrument-note is still playing, somewhere...
-- @param instr_idx (int) instrument index
-- @param pitch (int) note pitch
-- @return bool

function OscVoiceMgr:note_is_active(instr_idx,pitch)
  --TRACE("OscVoiceMgr:note_is_active()",instr_idx,pitch)

  for k,v in ipairs(self.playing) do
    if (v.instr_idx == instr_idx) 
      and (v.pitch-v.temp_transpose == pitch) 
    then
      return true
    end
  end
  return false

end

--------------------------------------------------------------------------------

--- When voices are added or removed, notify the application

function OscVoiceMgr:_notify_applications(evt,note,idx)
  TRACE("OscVoiceMgr:_notify_applications()",evt,note,idx)

  for k,v in ipairs(self._callbacks) do
    --if (v.application == note.app) then
      local notification = {
        type = evt,
        target = note,
        index = idx
      }
      v.callback(v.application,notification)
    --end
  end


end


--------------------------------------------------------------------------------

--- When an application transpose it's control surface, any triggered note
-- would need to be "de-transposed" once it's released - this function will
-- apply the amount of transpose to the currently held notes (the ones that 
-- match the application as their originating_app)
-- @param app (@{Duplex.Application})
-- @param semitones (int)

function OscVoiceMgr:transpose(app,semitones)
  TRACE("OscVoiceMgr:transpose()",app,semitones)

  local str_app = self:_get_app_name(app)
  for k,v in ipairs(self.playing) do
    -- update the temporary transpose
    if (v.originating_app == str_app) and (v.is_held) then
      if not (v.triggered_with_hold_mode) then
        v.temp_transpose = v.temp_transpose + semitones
        --print("*** OscVoiceMgr transpose before/after",v.temp_transpose,v.temp_transpose + semitones)
      end

    end
  end

end

--------------------------------------------------------------------------------

--- remove all active voices 

function OscVoiceMgr:remove_all_voices()
  TRACE("OscVoiceMgr:remove_all_voices()")

  for k,v in ripairs(self.playing) do
    self:release(v.app,v.instr_idx,v.track_idx,v.pitch+v.temp_transpose,v.velocity,v.is_midi,v.channel,true)
  end

end


--------------------------------------------------------------------------------

--- remove active voices from a given application
-- @param app (@{Duplex.Application})
-- @param instr_idx (int) this instrument only, optional

function OscVoiceMgr:remove_voices(app,instr_idx)
  TRACE("OscVoiceMgr:remove_voices()",app,instr_idx)

  local str_app = self:_get_app_name(app)
  for k,v in ripairs(self.playing) do
    if (v.originating_app == str_app) 
      and (not instr_idx or (instr_idx == v.instr_idx))
    then
      self:release(app,v.instr_idx,v.track_idx,v.pitch+v.temp_transpose,v.velocity,v.is_midi,v.channel,true)
    end
  end

end

--------------------------------------------------------------------------------

--- purge voices from provided application
-- @param app (@{Duplex.Application})
-- @param instr_idx (int, optional) only remove voices from this instrument

function OscVoiceMgr:purge_voices(app,instr_idx)
  TRACE("OscVoiceMgr:purge_voices()",app,instr_idx)

  local str_app = self:_get_app_name(app)
  for k,v in ripairs(self.playing) do
    if (v.originating_app == str_app) 
      and (not instr_idx or (instr_idx == v.instr_idx))
    then
      --print("purge voice from application",str_app)
      self:_notify_applications("remove",v,k)
      self.playing:remove(k)
    end
  end

end


--------------------------------------------------------------------------------

--- Remove application from active voices (release, then remove)
-- @param app (@{Duplex.Application})
-- @param func (Function)

function OscVoiceMgr:register_callback(app,func)
  TRACE("OscVoiceMgr:register_callback()",app)

  local matched = false
  for k,v in ipairs(self._callbacks) do
    if (v.application == app) then
      matched = true
    end
  end

  if not matched then
    self._callbacks:insert({
      application = app,
      callback = func
    })
  end

end


--==============================================================================

class 'OscVoiceMgrNote'

-- OscVoiceMgrNote is used for representing an active voice

function OscVoiceMgrNote:__init(app,instr_idx,track_idx,pitch,velocity,keep,is_midi,channel)

  --- (@{Duplex.Application}) the application that triggered this note
  self.app = app

  --- (string) a string for identifying the application
  self.originating_app = OscVoiceMgr._get_app_name(self,app)

  --- (bool) decide whether a released key should wait for all other
  -- pressed keys before it is allowed to release
  -- (set this to false if you're triggering notes with a pad controller 
  -- that doesn't send release notes)
  self.keep_until_all_released = keep

  --- (int) the temporary transpose of the application
  self.temp_transpose = 0

  --- (bool) whether or not the key is held
  self.is_held = true

  -- (bool) when true, these notes will keep playing even when released
  -- * note: also when switching away from hold mode, they keep playing 
  self.triggered_with_hold_mode = false

  --- (int) pitch
  self.pitch = pitch

  --- (int) velocity
  self.velocity = velocity

  --- (bool) true when MIDI, false means OSC
  self.is_midi = is_midi

  --- (int) for midi, but also helps to differentiate  
  -- (when looking for osc-triggered notes)
  self.channel = 1

  --- (int) the Renoise instrument index
  self.instr_idx = instr_idx

  --- (int) the Renoise track index
  self.track_idx = track_idx


end

--------------------------------------------------------------------------------

function OscVoiceMgrNote:__tostring()
  local str = "OscVoiceMgrNote: pitch = %d, velocity = %d, transpose = %d, app = %s, is_midi = %s, channel = %s"
  return str:format(self.pitch,self.velocity,self.temp_transpose,self.originating_app,self.is_midi,channel)
end  


