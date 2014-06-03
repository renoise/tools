--[[============================================================================
-- Duplex.OscVoiceMgr
============================================================================]]--

--[[--
The OscVoiceMgr is a class for handling internally triggered notes, keeping track of the active voices and their context

The purpose is to keep track of active voices, and their context: how the note got triggered: which device/application/instrument/pitch etc.

Some of the problems that a voice-manager can solve:

* Notes are getting stuck when a keyboard octave is "virtually transposed", as the released key will transmit a different pitch than the pressed one. Solution: simply tell the voice-manager that your application's base octave has been changed with this & that many semitones. 
* When the same note is triggered multiple times, once any key is released, the remaining voices are also stopped. Solution: Trigger notes with the `keep_until_all_released` flag, and the note is kept alive until all pressed notes are released

--]]

--==============================================================================

class 'OscVoiceMgr'

--------------------------------------------------------------------------------

--- Initialize the OscVoiceMgr class

function OscVoiceMgr:__init()

  -- table,OscVoiceMgrNote
  self.playing = table.create()

end

--------------------------------------------------------------------------------

--- This is the main trigger function
-- @param app (Application) the calling application 
-- @param instr (int) the Renoise instrument index
-- @param track (int) the Renoise track index
-- @param pitch (int) 0-120
-- @param velocity (int) 0-127
-- @param keep (bool) if true, keep all notes until release
-- @param is_midi (bool) to distinguish between OSC and MIDI notes
-- @param channel (int) the MIDI channel, 1-16 (not used!!)

function OscVoiceMgr:trigger(app,instr,track,pitch,velocity,keep,is_midi,channel)
  TRACE("OscVoiceMgr:trigger()",app,instr,track,pitch,velocity,keep,is_midi,channel)

  local osc_client = app._process.browser._osc_client
  assert(osc_client,"Internal Error. Please report: " ..
    "expected internal OSC client to be present")

  local channel = 1 -- TODO

  if not is_midi then
    osc_client:trigger_instrument(true,instr,track,pitch,velocity) 
  else
    --osc_client:trigger_instrument(true,instr,track,pitch,velocity) 
    local pitch_offset = self:_get_pitch_offset()
    osc_client:trigger_midi({143+channel,pitch+pitch_offset,velocity}) 
  end

  -- register the note with the voice-manager
  local org_app = self:_get_originating_app(app)
  local note = OscVoiceMgrNote(org_app,instr,track,pitch,velocity,keep,is_midi,channel)
  self.playing:insert(note)

end


--------------------------------------------------------------------------------

--- The main release function. Will ensure that the right notes are released, 
-- even when the keyboard has been transposed since the notes were triggered
-- @param app (Application) the calling application 
-- @param instr (int) the Renoise instrument index
-- @param track (int) the Renoise track index
-- @param pitch (int) 0-120
-- @param velocity (int) 0-127
-- @param is_midi (bool) to distinguish between OSC and MIDI notes
-- @param channel (int) the MIDI channel, 1-16
-- @return int, the amount of temp-transpose detected (in semitones)
-- @see OscVoiceMgr:_release_note

function OscVoiceMgr:release(app,instr,track,pitch,velocity,is_midi,channel)
  TRACE("OscVoiceMgr:release()",app,instr,track,pitch,velocity,is_midi,channel)

  local transp = 0
  local org_app = self:_get_originating_app(app)

  channel = 1 -- TODO

  for k,v in ripairs(self.playing) do
    local release_note = false

    --print("OscVoiceMgr:release() - v.instr",v)
    --print("OscVoiceMgr:release() - v.instr",v.instr,instr)
    --print("OscVoiceMgr:release() - v.originating_app",v.originating_app,org_app)
    --print("OscVoiceMgr:release() - v.is_midi",v.is_midi)
    --print("OscVoiceMgr:release() - v.temp_transpose",v.temp_transpose)
    --print("OscVoiceMgr:release() - v.pitch",v.pitch,pitch)
    --print("OscVoiceMgr:release() - v.pitch-v.temp_transpose",v.pitch-v.temp_transpose)

    if (v.instr == instr) 
      and (v.is_held) 
      and (v.originating_app == org_app) 
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
        if self:_was_osc_triggered(org_app,pitch+v.temp_transpose,channel) then
          --print("transposed into midi keys, release osc")
          is_midi = false
        else
          transp = 0 
        end
      elseif self:_was_midi_triggered(org_app,pitch+v.temp_transpose,channel) then
        --print("transposed into osc keys, release midi")
        is_midi = true
        transp = 0 
      end

      self.playing:remove(k)

      -- cut note only if "keep all until released" is false,
      -- or we have in fact released all keys 
      local is_active = self:note_is_active(app,instr,pitch)
      if not is_active or not keep then
        self:_release_note(app,instr,track,pitch+transp,velocity,is_midi,channel)
      end
      return transp
    end
  end

  return transp

end

--------------------------------------------------------------------------------

--- If OSC triggered this note, return true
-- @param org_app (Application), the originating application
-- @param pitch (int) 0-120
-- @param channel (int) the MIDI channel, 1-16
-- @return bool

function OscVoiceMgr:_was_osc_triggered(org_app,pitch,channel)
  TRACE("OscVoiceMgr:_was_osc_triggered()",org_app,pitch,channel)

  for k,v in ipairs(self.playing) do
    if (not v.is_midi) 
      and (v.pitch == pitch) 
      and (v.originating_app == org_app)
      and (v.channel == channel) 
    then
      return true
    end
  end

end

--------------------------------------------------------------------------------

--- If MIDI triggered this note, return true
-- @param org_app (Application), the originating application
-- @param pitch (int) 0-120
-- @param channel (int) the MIDI channel, 1-16
-- @return bool

function OscVoiceMgr:_was_midi_triggered(org_app,pitch,channel)
  TRACE("OscVoiceMgr:_was_midi_triggered()",org_app,pitch,channel)

  for k,v in ipairs(self.playing) do
    if (v.is_midi) 
      and (v.pitch == pitch) 
      and (v.originating_app == org_app)
      and (v.channel == channel) 
    then
      return true
    end
  end

end

--------------------------------------------------------------------------------

--- Release a given note. We do not release notes directly,
-- this method is called by the main release() method when it has been 
-- determined that a note should be released
-- @param app (Application), the originating application
-- @param instr (int) the Renoise instrument index
-- @param track (int) the Renoise track index
-- @param pitch (int) 0-120
-- @param velocity (int) 0-127
-- @param is_midi (bool) to distinguish between OSC and MIDI notes
-- @param channel (int) the MIDI channel, 1-16
-- @see OscVoiceMgr:release

function OscVoiceMgr:_release_note(app,instr,track,pitch,velocity,is_midi,channel)
  TRACE("OscVoiceMgr:_release_note()",app,instr,track,pitch,velocity,is_midi,channel)

  if is_midi then
    local channel = 1
    self:_send_midi_release(app,pitch,velocity,channel)
  else
    self:_send_osc_release(app,instr,track,pitch,velocity)
  end

end

function OscVoiceMgr:_send_osc_release(app,instr,track,pitch,velocity)
  TRACE("OscVoiceMgr:_send_osc_release()",app,instr,track,pitch,velocity)
  
  local osc_client = app._process.browser._osc_client
  assert(osc_client,"Internal Error. Please report: " ..
    "expected internal OSC client to be present")

  osc_client:trigger_instrument(false,instr,track,pitch,velocity)

end

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
-- @param app (Duplex.Application)

function OscVoiceMgr:_get_originating_app(app)
  TRACE("OscVoiceMgr:_get_originating_app()",app._app_name)

  local device_name = app._process.configuration.device.display_name
  return ("%s_%s"):format(device_name,app._app_name)

end

--------------------------------------------------------------------------------

--- Check if a particular instrument-note is still playing, somewhere...
-- @param app (Application), check originating app
-- @param instr (int) instrument index
-- @param pitch (int) note pitch

function OscVoiceMgr:note_is_active(app,instr,pitch)
  TRACE("OscVoiceMgr:note_is_active()",app,instr,pitch)

  local org_app = self:_get_originating_app(app)
  for k,v in ipairs(self.playing) do
    --print(k,"v.instr,v.pitch",v.instr,v.pitch)
    if (v.instr == instr) 
      and (v.pitch-v.temp_transpose == pitch) 
      and (v.originating_app == org_app) 
    then
      return true
    end
  end
  return false

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

  local org_app = self:_get_originating_app(app)
  for k,v in ipairs(self.playing) do
    -- update the temporary transpose
    if (v.originating_app == org_app) and (v.is_held) then
      v.temp_transpose = v.temp_transpose + semitones
    end
  end

end


--------------------------------------------------------------------------------

--- Remove application from active voices (release, then remove)
-- @param app (Duplex.Application)

function OscVoiceMgr:remove_app(app)
  TRACE("OscVoiceMgr:remove_app()",app)

  local org_app = self:_get_originating_app(app)
  for k,v in ripairs(self.playing) do
    if (v.originating_app == org_app) then
      self:_release_note(app,v.instr,v.track,v.pitch+v.temp_transpose,v.velocity,v.is_midi,v.channel)
      self.playing:remove(k)
    end
  end

end


--==============================================================================

class 'OscVoiceMgrNote'

-- OscVoiceMgrNote is used for representing an active voice

function OscVoiceMgrNote:__init(org_app,instr,track,pitch,velocity,keep,is_midi,channel)

  -- a unique identifier for the application that triggered this note
  self.originating_app = org_app

  -- decide whether a released key should wait for all other
  -- pressed keys before it is allowed to release
  -- (set this to false if you're triggering notes with a pad controller 
  -- that doesn't send release notes)
  self.keep_until_all_released = keep

  -- the temporary transpose of the application
  self.temp_transpose = 0

  -- whether or not the key is held
  self.is_held = true

  -- pitch/velocity
  self.pitch = pitch
  self.velocity = velocity

  -- true when MIDI, false means OSC
  self.is_midi = is_midi

  -- for midi, but also helps to differentiate  
  -- (when looking for osc-triggered notes)
  self.channel = 1 -- TODO

  -- osc only
  self.instr = instr
  self.track = track


end

--------------------------------------------------------------------------------

function OscVoiceMgrNote:__tostring()
  local str = "OscVoiceMgrNote: pitch = %d, velocity = %d, transpose = %d, app = %s, is_midi = %s, channel = %s"
  return str:format(self.pitch,self.velocity,self.temp_transpose,self.originating_app,self.is_midi,channel)
end  


