--==============================================================================

--- Mlrx_group - this class represent a logical group in mlrx
-- the group takes care of administering updates to it's child tracks

class 'Mlrx_group' 

--------------------------------------------------------------------------------

--- Constructor method

function Mlrx_group:__init(main)

  --- (Mlrx) reference to main application
  self.main = main

  --- (int) group velocity (between 0-255)
  self.velocity = 0xFF

  --- (int) group panning (between 0-255)
  self.panning = 0x80

  --- (table) the color assigned to this group
  -- @field red
  -- @field green
  -- @field blue
  -- @table color
  self.color = {0xff,0xff,0xff}

  --- (table) a darker version of the color, black when monochrome
  -- @field red
  -- @field green
  -- @field blue
  -- @table color_dimmed
  self.color_dimmed = {0x36,0x36,0x36}

  --- (<Mlrx_track...>) updated whenever tracks are reassigned
  self.tracks = table.create()

  --- (Automation) instance of Duplex automation class
  self.automation = Automation()
  self.automation.follow_pos = Automation.FOLLOW_PLAY_POS
  self.automation.preferred_playmode = 
    renoise.PatternTrackAutomation.PLAYMODE_POINTS

  --- (bool) true when 'latched' automation is being recorded
  -- (this will cause the group button to blink)
  self.grp_latch_velocity = false
  self.grp_latch_panning = false

  --- (int) index of the track that most recently wrote
  -- to a pattern in the group 
  -- (used by the WRITE mode to determine if we should keep
  -- wiping tracks after any notes have stopped playing)
  self.active_track_index = nil

  --- (bool) a special 'void' type group that bypass mute groups
  self.void_mutes = false

end

--------------------------------------------------------------------------------

--- collect all Mlrx_tracks assigned to this group
-- @param self_idx (int) this group's index, as the main application know it

function Mlrx_group:collect_group_tracks(self_idx)
  TRACE("Mlrx_group:collect_group_tracks(self_idx)",self_idx)

  self.tracks = table.create()
  for _,trk in ipairs(self.main.tracks) do
    if (trk.group == self) then
      self.tracks:insert(trk)
    end
  end


end

--------------------------------------------------------------------------------

--- compare to another class instance (check for object identity)

function Mlrx_group:__eq(other)
  return rawequal(self, other)
end  

--------------------------------------------------------------------------------

--- this method will call track output in all child tracks
-- @param on_idle (bool) true when method is invoked by idle loop

function Mlrx_group:group_output(on_idle)
  TRACE("Mlrx_group:group_output()",on_idle)

  local writepos = Mlrx_pos()
  local wraparound = false

  -- skip while changes to the tracks are applied
  if on_idle and self.main.rebuild_indices_requested then
    --print("skip while changes to the tracks are applied")
    return
  end

  for _,trk in ipairs(self.tracks) do
    trk:track_output(writepos,trk.writeahead,wraparound,on_idle) 
  end

  if self.grp_latch_velocity or 
    self.grp_latch_panning
  then
    self.automation:update()
  else
    --self.automation:stop_automation()
  end


end

--------------------------------------------------------------------------------

--- specify the group panning level
-- @param val (float) value between 0 and 255
-- @param skip_output (bool) do not write automation

function Mlrx_group:set_grp_panning(val,skip_output)
  TRACE("Mlrx_group:set_grp_panning(val)",val,skip_output)

  val = clamp_value(val,0,Mlrx.INT_8BIT)
  self.panning = math.floor(val)

  if not skip_output and rns.transport.edit_mode and
    (self.main.options.automation.value ~= Mlrx.AUTOMATION_READ)
  then
    self:set_grp_automation(Mlrx_track.PARAM_PANNING)
  end

  if not rns.transport.edit_mode or 
    (self.main.options.automation.value == Mlrx.AUTOMATION_READ) 
  then
    self:update_mixer_params()  
  end

  self.main:initiate_settings_task()

end



--------------------------------------------------------------------------------

--- specify the group velocity level
-- @param val (float) value between 0 and 255
-- @param skip_output (bool) do not write automation

function Mlrx_group:set_grp_velocity(val,skip_output)
  TRACE("Mlrx_group:set_grp_velocity(val)",val,skip_output)

  val = clamp_value(val,0,Mlrx.INT_8BIT)
  self.velocity = math.floor(val)

  if not skip_output and rns.transport.edit_mode and
    (self.main.options.automation.value ~= Mlrx.AUTOMATION_READ)
  then
    self:set_grp_automation(Mlrx_track.PARAM_VELOCITY)
  end

  if not rns.transport.edit_mode or 
    (self.main.options.automation.value == Mlrx.AUTOMATION_READ) 
  then
    self:update_mixer_params()  
  end

  self.main:initiate_settings_task()

end

--------------------------------------------------------------------------------

--- record current group velocity/panning into active track/envelope
-- @param param_type (enum) Mlrx_track.PARAM_VELOCITY or Mlrx_track.PARAM_PANNING

function Mlrx_group:set_grp_automation(param_type)
  TRACE("Mlrx_group:set_grp_automation(param_type)",param_type)

  -- check if we have entered 'latched' automation mode (set first time 
  -- fader has been touched, while automation is in WRITE mode)
  if (self.main.options.automation.value == Mlrx.AUTOMATION_WRITE) then
    if (param_type == Mlrx_track.PARAM_VELOCITY) and not self.grp_latch_velocity then
      self.grp_latch_velocity = true
    end
    if (param_type == Mlrx_track.PARAM_PANNING) and not self.grp_latch_panning then
      self.grp_latch_panning = true
    end
  end

  local pos = Mlrx_pos()


  -- record into envelope, uaing Automation class
  self.automation.latch_record = self.grp_latch_velocity
  for _,trk in ipairs(self.tracks) do
    local rns_trk = rns.tracks[trk.rns_track_idx]
    if (param_type == Mlrx_track.PARAM_PANNING) then
      local dev_param = rns_trk.prefx_panning
      self.automation.latch_record = self.grp_latch_panning
      self.automation:add_automation(
        trk.rns_track_idx,dev_param,self.panning/Mlrx.INT_8BIT)
    elseif (param_type == Mlrx_track.PARAM_VELOCITY) then
      local dev_param = rns_trk.prefx_volume
      self.automation.latch_record = self.grp_latch_velocity
      self.automation:add_automation(
        trk.rns_track_idx,dev_param,self.velocity/Mlrx.INT_8BIT)
    end
    self.automation:update()
  end


  if (self.main.options.automation.value == Mlrx.AUTOMATION_READ_WRITE) then
    self.main:flash_automation_button()
  end

end

--------------------------------------------------------------------------------

--- when updating automation in READ mode, we need to set the panning
-- and velocity of all group tracks

function Mlrx_group:update_mixer_params()

  for _,trk in ipairs(self.tracks) do
    local rns_trk = rns.tracks[trk.rns_track_idx] 
    if rns_trk then
      rns_trk.prefx_volume.value = 
        (self.velocity*RENOISE_DECIBEL) / Mlrx.INT_8BIT
      rns_trk.prefx_panning.value = self.panning / Mlrx.INT_8BIT
    end
  
  end

end

--------------------------------------------------------------------------------

--- disable activity for the group (stop active tracks), or toggle mute state

function Mlrx_group:toggle()
  TRACE("Mlrx_group:toggle()")
  
  local toggle_mute = true
  local mute_state = renoise.Track.MUTE_STATE_ACTIVE
  for _,trk in ipairs(self.tracks) do
    if trk.phrase_recording then
      trk:stop_phrase_recording()
      self.main:update_sound_source()
    end
    if trk.note then
      self:cancel_notes()
      toggle_mute = false
    elseif (self.active_track == trk) and
      trk._clear_without_note and
      rns.transport.playing
    then
      -- stop the track from clearing pattern data
      trk._held_triggers = table.create()
      trk._last_pressed = nil
      self.main:update_track()
      toggle_mute = false
      --print("toggle_mute = false A")
    end
    -- stop track automation 
    if trk.trk_latch_velocity or
      trk.trk_latch_panning or
      trk.trk_latch_shuffle
    then
      trk.trk_latch_velocity = false
      trk.trk_latch_panning = false
      trk.trk_latch_shuffle = false
      toggle_mute = false
      --print("toggle_mute = false B")
    end
    local rns_trk = rns.tracks[trk.rns_track_idx] 
    if rns_trk and (rns_trk.mute_state ~= renoise.Track.MUTE_STATE_ACTIVE) then
      mute_state = renoise.Track.MUTE_STATE_OFF
    end
    trk._last_pressed = false
  end

  -- stop group automation 
  if self.grp_latch_velocity or self.grp_latch_panning then
    self.grp_latch_velocity = false
    self.grp_latch_panning = false
    toggle_mute = false
    --print("toggle_mute = false C")
  end

  --print("toggle_mute",toggle_mute,mute_state)

  if not toggle_mute then
    self.active_track_index = nil
  else
    mute_state = (mute_state == renoise.Track.MUTE_STATE_OFF) and 
      renoise.Track.MUTE_STATE_ACTIVE or renoise.Track.MUTE_STATE_OFF
    --print("mute_state",mute_state)

    for _,trk in ipairs(self.tracks) do
      local rns_trk = rns.tracks[trk.rns_track_idx] 
      rns_trk.mute_state = mute_state
    end
  end

end

--------------------------------------------------------------------------------

--- when switching track, check if we should output note-off for other tracks 

function Mlrx_group:switch_to_track(trk_idx)
  TRACE("Mlrx_group:switch_to_track()",trk_idx)

  if not self.void_mutes then

    local offpos = Mlrx_pos()
    offpos.line = offpos.line+1
    offpos:normalize()

    for _,trk in ipairs(self.main.tracks) do
      if (trk.group == self) and -- our group
        (trk_idx ~= trk.self_idx) -- other track
      then 
        trk:schedule_noteoff()
      end
    end
  end


end


--------------------------------------------------------------------------------

--- stop group, triggered when stopping playback
-- (will not write anything to pattern but simply cancel notes)

function Mlrx_group:cancel_notes()
  TRACE("Mlrx_group:cancel_notes()")

  --print("#self.tracks",#self.tracks)
  --rprint(self.tracks)

  for trk_idx,trk in ipairs(self.tracks) do
    if trk.note then
      trk.note = nil
      --print(" nullified the note in track",trk_idx)
    end
    self.main:update_trigger_pos(trk.self_idx) -- clear the light
  end

end


