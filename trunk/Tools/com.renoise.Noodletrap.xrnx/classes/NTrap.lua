--[[============================================================================
-- NTrap
============================================================================]]--

--[[--

### About

Noodletrap lets you record notes while bypassing the recording process in Renoise. Instead, your recordings ("noodlings") are stored into the instrument itself, using phrases as the storage mechanism.

### Forum Topic 
http://forum.renoise.com/index.php/topic/43047-new-tool-30-noodletrap/


--]]

--==============================================================================


class 'NTrap'


function NTrap:__init()
  TRACE("NTrap:__init()")

  --- (int) instrument index (set on attach)
  self._instr_idx = nil

  --- (int) track context
  self._track_idx = nil

  --- (int)
  self._phrase_idx = 1

  --- (int) pattern context
  self._patt_idx = nil

  --- (renoise.Midi.MidiInputDevice)
  self._midi_in = nil

  --- (table) note events 
  -- [timestamp] = {
  --  .timestamp  -- (number)
  --  .is_note_on -- (bool)
  --  .pitch      -- (int) between 0 and 119
  --  .velocity   -- (int) between 0x00 and 0x7F
  --  .octave     -- (int) renoise octave offset
  --  .playpos    -- (renoise.SongPos) 
  -- }
  self._events = table.create()

  --- (int) how many playing voices do we have
  self._live_voices = 0

  --- (NTrapUI) 
  self._ui = NTrapUI(self)

  --- (NTrapPrefs) current settings
  self._settings = nil

  --- (bool) when attached to a song
  self._active = false

  --- (bool) true when ready to receive input
  self._record_armed = false

  --- (bool) true while actively recording 
  self._recording = false

  --- (bool) true when a recording has been requested to stop
  self._stop_requested = false
  
  --- (number) the time when recording began
  self._recording_begin = nil

  --- (int) the pattern in which recording was initiated
  self._recording_begin_patt_idx = nil

  --- (int) count the total length of patterns while recording
  self._recording_pattern_line_count = nil

  --- (number) the time when recording should be split
  self._split_requested_at = nil

  --- (number) the time when recording was stopped
  self._recording_stop = nil

  --- (number) update on idle loop
  self._playpos = nil 

  --- (table) 
  self._song_notifiers = table.create()
  --- (table) 
  self._patt_notifiers = table.create()
  --- (table) 
  self._instr_notifiers = table.create()
  --- (table) 
  self._phrase_notifiers = table.create()

  --- (bool) 
  self._update_requested = false
  --- (bool) 
  self._update_record_requested = false

  -- (ProcessSlicer) for dealing with CPU intensive tasks
  self.process_slicer = nil


  -- Provide MIDI mappings

  renoise.tool():add_midi_mapping({
    name = "Global:Tools:Noodletrap:Prepare/Record",
    invoke = function(msg)
      if msg:is_trigger() then
        self:toggle_recording()
      end
    end
  })

  renoise.tool():add_midi_mapping({
    name = "Global:Tools:Noodletrap:Split Recording",
    invoke = function(msg)
      if msg:is_trigger() then
        if self._recording then
          if (self._settings.split_recording.value == NTrapPrefs.SPLIT_MANUAL) then
            self._split_requested_at = os.clock()
          end
        end
      end
    end
  })

  renoise.tool():add_midi_mapping({
    name = "Global:Tools:Noodletrap:Cancel Recording",
    invoke = function(msg)
      if msg:is_trigger() then
        if self._recording or 
          self._record_armed 
        then
          self:cancel_recording()
        end
      end
    end
  })

end

--==============================================================================
-- Public methods
--==============================================================================


--- Prepare a new recording

function NTrap:prepare_recording()
  TRACE("NTrap:prepare_recording()")

  if not self:_recording_check() then
    return
  end

  local instr = self:_get_instrument()
  instr.phrase_playback_enabled = false
  self._record_armed = true
  self._update_record_requested = true
  self._update_bar_requested = true

  -- special case: if we are listening to the same condition 
  -- for both arm and start, begin recording straight away
  if (self._settings.arm_recording.value == NTrapPrefs.ARM_PLAYBACK) and
    (self._settings.start_recording.value == NTrapPrefs.START_PLAYBACK) 
  then
    self._ui:update_record_status()
    self:begin_recording()
  end

  LOG(string.format(
    "Prepared for recording at %.4f",os.clock()))

end

--------------------------------------------------------------------------------

--- Begin recording. From this moment on, events are captured...

function NTrap:begin_recording()
  TRACE("NTrap:begin_recording()")

  self._record_armed = false
  self._recording = true

  if (self._settings.start_recording.value == NTrapPrefs.START_PLAYBACK)
    or (self._settings.start_recording.value == NTrapPrefs.START_PATTERN)
  then
    -- when recording is initiated during an idle loop,
    -- apply offset to the beginning time
    local playpos_beats = renoise.song().transport.playback_pos_beats
    local bps = get_bps()
    local beat_fract = playpos_beats - math.floor(playpos_beats)
    self._recording_begin = os.clock() - (bps*beat_fract)
    LOG(string.format(
      "Beginning recording at %.4f (offset by %.4f)",
      os.clock(),(bps*beat_fract)))
  else
    self._recording_begin = os.clock()
    LOG(string.format(
      "Beginning recording at %.4f",os.clock()))
  end

  self._recording_begin_patt_idx = renoise.song().selected_pattern_index
  self._recording_pattern_line_count = 0
  self._ui:update_record_status()

  self:_on_idle()

end


--------------------------------------------------------------------------------

--- Split recording (process events leading up to that time)

function NTrap:split_recording()
  TRACE("NTrap:split_recording()")

  if not self._recording or 
     not self._split_requested_at 
  then
    return
  end

  LOG(string.format(
    "Split recording at %d",self._split_requested_at))

  self._recording_stop = self._split_requested_at

  -- purge old events 
  for k,v in ripairs(self._events) do
    if (v.timestamp < self._recording_begin) then
      self._events:remove(k)
    end
  end

  -- process copy of events
  local events = table.create()
  for k,v in ipairs(self._events) do
    if (v.timestamp <= self._split_requested_at) then
      events:insert(v)
    end
  end
  self:_process_recording(events)

  self._recording_begin = self._split_requested_at
  self._recording_stop = nil
  self._split_requested_at = nil

  local patt = self:_get_playing_pattern()
  self._recording_pattern_line_count = patt.number_of_lines


end

--------------------------------------------------------------------------------

--- Handle events triggered by the user
-- (might prepare a recording or stop the current one)

function NTrap:toggle_recording()

  if self._recording then
    if (self._settings.stop_recording.value == NTrapPrefs.STOP_PATTERN) then
      if renoise.song().transport.playing then
        self._stop_requested = true
        -- do not split the pattern 
        if (self._settings.split_recording.value == 
          NTrapPrefs.SPLIT_PATTERN) 
        then
          self._split_requested_at = nil
        end
        return
      end
      self:stop_recording()
    else
      self:stop_recording()
    end
  else
    self:prepare_recording()
  end
end

--------------------------------------------------------------------------------

--- Stop recording 

function NTrap:stop_recording()
  TRACE("NTrap:stop_recording()")
  
  self._recording_stop = os.clock()
  self:_process_recording(self._events)
  self:_reset_recording()
  self:_on_idle()

  LOG(string.format(
    "Recording was stopped at %.4f",os.clock()))

  if (self._settings.start_recording.value == NTrapPrefs.START_NOTE) and
    (self._settings.stop_recording.value == NTrapPrefs.STOP_NOTE)
  then
    self:prepare_recording()
  end

end

--------------------------------------------------------------------------------

--- Cancel recording, do not create phrase(s)

function NTrap:cancel_recording()
  TRACE("NTrap:cancel_recording()")

  self:_reset_recording()

  LOG(string.format(
    "Recording was cancelled at %.4f",os.clock()))

end

--------------------------------------------------------------------------------

--- Reset, be ready for a new recording

function NTrap:_reset_recording()
  TRACE("NTrap:_reset_recording()")

  self._events = table.create()
  self._record_armed = false
  self._recording = false
  self._record_armed = false
  self._stop_requested = false
  self._recording_pattern_line_count = nil

  local instr = self:_get_instrument()
  instr.phrase_playback_enabled = true
  self._update_record_requested = true
  self._update_bar_requested = true

end


--------------------------------------------------------------------------------

--- show the dialog (build ui if needed)

function NTrap:show_dialog()
  TRACE("NTrap:show_dialog()")

  self._ui:show()

end

--------------------------------------------------------------------------------

--- hide the dialog 

function NTrap:hide_dialog()
  TRACE("NTrap:hide_dialog()")

  self._ui:hide()

end


--------------------------------------------------------------------------------

--- log string

function NTrap:log_string(str)
  TRACE("NTrap:log_string()",str)

  self._ui:log_string(str)

end


--------------------------------------------------------------------------------

--- Feed MIDI notes in - when recording
-- @param is_note_on (bool)
-- @param note (int) between 0-119
-- @param velocity (int) between 0-127
-- @param octave velocity (int) between 0-127
-- @param quick (bool) quick repeats from PC keyboard - release + retrigger

function NTrap:input_note(is_note_on,pitch,velocity,octave,quick)
  TRACE("NTrap:input_note(is_note_on,pitch,velocity,octave)",is_note_on,pitch,velocity,octave)

  assert(type(is_note_on)=="boolean",
    "Wrong parameter type")

  assert(type(pitch)=="number",
    "Wrong parameter type")

  assert(type(velocity)=="number",
    "Wrong parameter type")

  assert(type(octave)=="number",
    "Wrong parameter type")

  -- TODO handle 'quick notes' from PC keyboard
  -- self:_insert_at_previous_line

  local note = {
    timestamp = os.clock(),
    is_note_on = is_note_on,
    pitch = pitch,
    velocity = velocity,
    octave = octave,
  }

  self._ui:dump_note_info(note)

  if self._record_armed then
    if (self._settings.start_recording.value == NTrapPrefs.START_NOTE) then
      self:begin_recording()
    end
  end

  if not self._recording then
    --print("Ignoring input when not recording...")
    return 
  end

  self._events:insert(note)

  if is_note_on then
    self._live_voices = self._live_voices + 1
  else
    self._live_voices = self._live_voices - 1
  end


end


--==============================================================================
-- Private methods
--==============================================================================

--- handle idle notifications

function NTrap:_on_idle()

  self._ui:_purge_live_keys()

  -- when playback enter a new pattern, or wrap around the current
  local playpos = renoise.song().transport.playback_pos
  local wrapped = (playpos.line < self._playpos.line) and true or false
  if wrapped then
    if self._recording then
      if (self._settings.stop_recording.value == NTrapPrefs.STOP_PATTERN) 
        and self._stop_requested
      then
        -- do not include this pattern, we have stopped recording
      else
        local patt = self:_get_playing_pattern()
        self._recording_pattern_line_count = 
          self._recording_pattern_line_count + patt.number_of_lines
        LOG(string.format("Entered pattern %d at %d, line count is %d",
          renoise.song().selected_pattern_index,os.clock(),
          self._recording_pattern_line_count))
      end
    end
  end

  if self._record_armed then

    if not self:_recording_check() then
      return
    end

    if (self._settings.start_recording.value == NTrapPrefs.START_PATTERN) then
      -- begin when wrapping around pattern (or count down)
      if wrapped then
        self:begin_recording()
      end
    end

    self._ui:update_blinks()
    self._update_record_requested = true

  elseif self._recording then

    -- ## stop
    if (self._settings.stop_recording.value == NTrapPrefs.STOP_NOTE) then
      -- stop when last note happened X beats ago...
      if (self._live_voices == 0) then
        local most_recent = self:_get_most_recent_event()
        if most_recent then
          local beats_passed = (os.clock() - most_recent.timestamp)
          if (beats_passed > self._settings.stop_recording_beats.value) then
            self:stop_recording()
          end
        end
      end

    elseif (self._settings.stop_recording.value == NTrapPrefs.STOP_PATTERN) then
      -- stop when reaching end of pattern
      local playpos = renoise.song().transport.playback_pos
      if self._stop_requested and wrapped
      then
        self:stop_recording()
      end

    elseif (self._settings.stop_recording.value == NTrapPrefs.STOP_LINES) then
      -- stop when reaching end of phrase
      local remaining,total = self:_get_phrase_lines_remaining()
      if (remaining < 1) then
        self:stop_recording()
      else
        self._ui:update_record_slider(math.abs(remaining-total)/total)
      end

    end

    -- ## split
    local rec_lines = self:_get_recorded_lines()
    local playpos = renoise.song().transport.playback_pos

    if (self._settings.split_recording.value == NTrapPrefs.SPLIT_PATTERN) and
      (playpos.line < self._playpos.line) 
    then 
      -- split by pattern boundary when crossing into pattern
      -- (except when we just began recording)
      if (rec_lines > 4) then
        self._split_requested_at = 
          resolve_timestamp_by_line_in_pattern(1)
        --print("SPLIT_PATTERN - self._split_requested_at,now",self._split_requested_at,os.clock())
      end

    elseif (self._settings.split_recording.value == NTrapPrefs.SPLIT_LINES) then
      -- split pattern by line when recording exceed #lines
      local split_lines = self._settings.split_recording_lines.value
      if (rec_lines >= (split_lines - 7)) then
        self._split_requested_at = self._recording_begin + 
          resolve_timestamp_by_line_in_phrase(split_lines,self._settings)
        --print("#2 - self._split_requested_at,now",self._split_requested_at,os.clock())
      end
    elseif (self._settings.split_recording.value == NTrapPrefs.SPLIT_MANUAL) then
      if (rec_lines >= renoise.InstrumentPhrase.MAX_NUMBER_OF_LINES) then
        self._split_requested_at = os.clock() + 
          resolve_timestamp_by_line_in_phrase(
            renoise.InstrumentPhrase.MAX_NUMBER_OF_LINES,self._settings)
        --print("#3 - self._split_requested_at,now",self._split_requested_at,os.clock())
      end
    end

    if self._split_requested_at and 
      (os.clock() >= self._split_requested_at) 
    then
      self:split_recording()
    end

    self._update_record_requested = true

  end

  if self._update_requested then
    self._update_record_requested = false
    self._update_bar_requested = false
    self._update_requested = false
    self._ui:update()
  end

  if self._update_record_requested then
    self._update_record_requested = false
    self._ui:update_record_status()
  end

  if self._update_bar_requested then
    self._update_bar_requested = false
    self._ui:update_phrase_bar()
  end

  self._playpos = renoise.song().transport.playback_pos

end

--------------------------------------------------------------------------------

--- Detach from song document (remove notifiers)

function NTrap:_detach_from_song()
  TRACE("NTrap:_detach_from_song()")

  local new_song = false
  self._active = false
  self:_remove_notifiers(new_song,self._song_notifiers)
  self:_remove_notifiers(new_song,self._instr_notifiers)
  self:_remove_notifiers(new_song,self._phrase_notifiers)
  self:_remove_notifiers(new_song,self._patt_notifiers)

end

--------------------------------------------------------------------------------

--- Connect to the song document (attach notifiers)

function NTrap:_attach_to_song(new_song)
  TRACE("NTrap:_attach_to_song(new_song)",new_song)

  local rns = renoise.song()

  self._playpos = rns.transport.playback_pos

  self._active = true
  self:_remove_notifiers(new_song,self._song_notifiers)

  self._song_notifiers:insert(rns.transport.edit_mode_observable)
  rns.transport.edit_mode_observable:add_notifier(self,
    function()
      --print("*** NTrap:edit_mode_observable fired...")
      if (self._settings.arm_recording.value == NTrapPrefs.ARM_EDITMODE) then
        if not rns.transport.edit_mode then
          if not self._recording then
            self:prepare_recording()
          end
        elseif not self._recording then
          self:cancel_recording()
        end
      end
    end
  )

  self._song_notifiers:insert(rns.transport.playing_observable)
  rns.transport.playing_observable:add_notifier(self,
    function()
      --print("*** NTrap:playing_observable fired...")
      if rns.transport.playing then
        if not self._recording then
          if not self._record_armed then
            if (self._settings.arm_recording.value == NTrapPrefs.ARM_PLAYBACK) then
              if (self._settings.start_recording.value == NTrapPrefs.START_PLAYBACK) then
                self:begin_recording()
              else
                self:prepare_recording()
              end
            end
          elseif (self._settings.start_recording.value == NTrapPrefs.START_PLAYBACK) then
            self:begin_recording()
          end
        end
      else
        if self._recording then
          self:stop_recording()
        end
      end
    end
  )

  self._song_notifiers:insert(rns.selected_track_index_observable)
  rns.selected_track_index_observable:add_notifier(self,
    function()
      --print("*** NTrap:selected_track_index_observable fired...")
    end
  )

  self._song_notifiers:insert(rns.selected_instrument_index_observable)
  rns.selected_instrument_index_observable:add_notifier(self,
    function()
      --print("*** NTrap:selected_instrument_index_observable fired...")
      if (self._settings.target_instr.value == NTrapPrefs.INSTR_FOLLOW) then
        local idx = rns.selected_instrument_index
        self:_attach_to_instrument(false,idx)
        self._update_requested = true
      end
    end
  )

  self._song_notifiers:insert(rns.selected_phrase_observable)
  rns.selected_phrase_observable:add_notifier(self,
    function()
      --print("*** NTrap:selected_phrase_observable fired...")
      self:_obtain_selected_phrase()
      --print("*** self._phrase_idx",self._phrase_idx)
    end
  )

  self._song_notifiers:insert(rns.selected_sequence_index_observable)
  rns.selected_sequence_index_observable:add_notifier(self,
    function()
      --print("*** NTrap:selected_sequence_index fired...")
      local idx = rns.selected_pattern_index
      self:_attach_to_pattern(false,idx)
    end
  )

  --[[
  rns.selected_pattern_index_observable:add_notifier(
    function()
      print("NTrap:selected_pattern_index fired...")
      local idx = rns.selected_pattern_index
      self:_attach_to_pattern(false,idx)
    end
  )
  ]]

  self:_attach_to_pattern(new_song,rns.selected_pattern_index)
  self:_attach_to_instrument(new_song,rns.selected_instrument_index)
  self._update_requested = true


end

--------------------------------------------------------------------------------

--- Attach notifiers to the current pattern

function NTrap:_attach_to_pattern(new_song,patt_idx)
  TRACE("NTrap:_attach_to_pattern(new_song,patt_idx)",new_song,patt_idx)

  local rns = renoise.song()

  self:_remove_notifiers(new_song,self._patt_notifiers)
  local patt = rns.patterns[patt_idx]

  self._patt_notifiers:insert(patt.number_of_lines_observable)
  patt.number_of_lines_observable:add_notifier(self,
    function()
      --print("*** NTrap:number_of_lines_observable fired...")
    end
  )

  self._patt_idx = patt_idx

end

--------------------------------------------------------------------------------

--- Attach notifiers to the current instrument

function NTrap:_attach_to_instrument(new_song,instr_idx)
  TRACE("NTrap:_attach_to_instrument(new_song,instr_idx)",new_song,instr_idx)

  self:_remove_notifiers(new_song,self._instr_notifiers)
  self:_remove_notifiers(new_song,self._phrase_notifiers)
  local instr = renoise.song().instruments[instr_idx]
  self._ui:show_instrument_warning(not instr)
  if not instr then
    instr_idx = renoise.song().selected_instrument_index
    instr = renoise.song().instruments[instr_idx]
  end

  self._instr_notifiers:insert(instr.phrases_observable)
  instr.phrases_observable:add_notifier(self,
    function()
      --print("*** NTrap:phrases_observable fired...")
      -- we lost the phrase somehow? 
      if (not instr.phrases[self._phrase_idx]) then
        self:_remove_notifiers(new_song,self._phrase_notifiers)
        self._phrase_idx = nil
      end
      self._update_requested = true
    end
  )

  self._instr_idx = instr_idx
  self:_obtain_selected_phrase()
  self._update_requested = true

end

--------------------------------------------------------------------------------

--- Attach notifiers to the current instrument

function NTrap:_attach_to_phrase(new_song,phrase_idx)
  TRACE("NTrap:_attach_to_phrase(new_song,phrase_idx)",new_song,phrase_idx)

  local rns = renoise.song()

  self:_remove_notifiers(new_song,self._phrase_notifiers)
  local instr = self:_get_instrument()
  local phrase = instr.phrases[phrase_idx]

  if not phrase then
    self._phrase_idx = nil
    self._update_requested = true
    return
  end

  self._phrase_notifiers:insert(phrase.mapping.key_tracking_observable)
  phrase.mapping.key_tracking_observable:add_notifier(self,
    function()
      --print("*** NTrap:key_tracking_observable fired...")
      self._update_requested = true
    end
  )

  self._phrase_notifiers:insert(phrase.mapping.looping_observable)
  phrase.mapping.looping_observable:add_notifier(self,
    function()
      --print("*** NTrap:looping_observable fired...")
      self._update_requested = true
    end
  )

  self._phrase_notifiers:insert(phrase.mapping.note_range_observable)
  phrase.mapping.note_range_observable:add_notifier(self,
    function()
      --print("*** NTrap:note_range_observable fired...")
      self._update_requested = true
    end
  )

  self._phrase_idx = phrase_idx
  self._update_requested = true

end

--------------------------------------------------------------------------------

--- detach all attached notifiers in list, but don't even try to detach 
-- when a new song arrived - old observables will no longer be alive then...
-- @param new_song (bool), true to leave existing notifiers alone
-- @param observables (table) 

function NTrap:_remove_notifiers(new_song,observables)
  TRACE("NTrap:_remove_notifiers()",new_song,#observables)

  if (not new_song) then
    for _,observable in pairs(observables) do
      pcall(function() observable:remove_notifier(self) end)
    end
  end
    
  observables:clear()

end

--------------------------------------------------------------------------------

--- Since the selected_phrase_index is a global property of the song,
-- we check when switching instrument if we can eavesdrop on that value
-- (otherwise, we use the UI dialog for selecting a specific phrase)

function NTrap:_obtain_selected_phrase()
  TRACE("NTrap:_obtain_selected_phrase()")

  if (renoise.song().selected_instrument_index == self._instr_idx) then
    local phrase_idx = renoise.song().selected_phrase_index
    if (phrase_idx > 0) then 
      self:_attach_to_phrase(false,phrase_idx)
    end
  end

end

--------------------------------------------------------------------------------

--- Delete the currently selected phrase

function NTrap:_delete_selected_phrase()
  TRACE("NTrap:_delete_selected_phrase()")

  local instr = self:_get_instrument()
  if (self._phrase_idx and instr.phrases[self._phrase_idx]) then
    instr:delete_phrase_at(self._phrase_idx)
  end

end

--------------------------------------------------------------------------------

--- Only possible when instrument is the selected one

function NTrap:_set_selected_phrase(idx)
  TRACE("NTrap:_set_selected_phrase()")

  if (renoise.song().selected_instrument_index == self._instr_idx) then
    local instr = self:_get_instrument()
    if instr.phrases[idx] then
      renoise.song().selected_phrase_index = idx
    end
  end

end

--------------------------------------------------------------------------------

--- Set previous/next phrase 

function NTrap:select_previous_phrase(idx)
  TRACE("NTrap:select_previous_phrase()")

  if not self._phrase_idx then
    LOG("No phrase have been selected")
    return
  end

  local phrase_idx = self._phrase_idx
  if phrase_idx then
    phrase_idx = math.max(1,phrase_idx-1)
  end
  
  self:_attach_to_phrase(false,phrase_idx)
  self:_set_selected_phrase(phrase_idx)


end

--------------------------------------------------------------------------------

--- Set previous/next phrase 

function NTrap:select_next_phrase(idx)
  TRACE("NTrap:select_next_phrase()")

  if not self._phrase_idx then
    LOG("No phrase have been selected")
    return
  end

  local phrase_idx = self._phrase_idx
  if phrase_idx then
    local instr = self:_get_instrument()
    phrase_idx = math.min(#instr.phrases,phrase_idx+1)
  end
  
  self:_attach_to_phrase(false,phrase_idx)
  self:_set_selected_phrase(phrase_idx)

end

--------------------------------------------------------------------------------

--- Check if we can actually record
-- (will display an error message when something went wrong)
-- @return bool, true when ready

function NTrap:_recording_check()
  TRACE("NTrap:_recording_check()")

  if not self._instr_idx then
    LOG("No instrument has been targeted")
    return false
  end

  --[[
  if renoise.song().transport.edit_mode then
    print("Can't record while edit mode is enabled")
    return false
  end
  ]]

  return true

end


--------------------------------------------------------------------------------

--- If running as a standalone tool, save the key/value in the persistent
-- settings. Otherwise, compile a serialized string and hand it over...

function NTrap:_save_setting(key,value)
  TRACE("NTrap:_save_setting(key,value)",key,value)

  assert(type(self._settings) == "NTrapPrefs",
    "Please instantiate NTrapPrefs before saving preferences") 

  self._settings:property(key).value = value

end

--------------------------------------------------------------------------------

--- Retrieve and apply settings
-- @param settings (renoise.Document) 

function NTrap:retrieve_settings(settings)
  TRACE("NTrap:retrieve_settings()",settings)

  assert(type(settings) == "NTrapPrefs",
    "Settings needs to be an instance of NTrapPrefs") 

  self._settings = settings
  self:_open_midi_port(self._settings.midi_in_port.value)
  self._update_requested = true

end


--------------------------------------------------------------------------------

--- Open the selected MIDI port
-- @param port_name (string)

function NTrap:_open_midi_port(port_name,store_setting)
  TRACE("NTrap:_open_midi_port(port_name)",port_name)

  local input_devices = renoise.Midi.available_input_devices()
  if table.find(input_devices, port_name) then
    self._midi_in = renoise.Midi.create_input_device(port_name,
      {self, NTrap._midi_callback}
    )
    if store_setting then
      self:_save_setting("midi_in_port",port_name)
    end
  else
    LOG("Could not create MIDI input device ", port_name)
  end


end


--------------------------------------------------------------------------------

--- Close the MIDI port

function NTrap:_close_midi_port()
  TRACE("NTrap:_close_midi_port()")

  if (self._midi_in and self._midi_in.is_open) then
    self._midi_in:close()
  end

  self._midi_in = nil

end


--------------------------------------------------------------------------------

--- Interpret incoming MIDI

function NTrap:_midi_callback(message)
  TRACE(("NTrap: received MIDI %X %X %X"):format(
    message[1], message[2], message[3]))

  local rns_octave = tonumber(renoise.song().transport.octave)
  local rns_pitch,velocity
  local is_note_on = true

  if (message[1]>=128) and (message[1]<=159) then

    rns_pitch = message[2]-48
    if (rns_pitch < 0) or
      (rns_pitch > 119) 
    then
      return
    end

    if(message[1]>143)then
      velocity = message[3]
    else
      velocity = 0
    end

    if (velocity==0) then
      is_note_on = false      
    end

    self:input_note(is_note_on,rns_pitch,velocity,rns_octave)

  end


end

--------------------------------------------------------------------------------

--- TODO Given the current time, insert note event at previous line
--[[
function NTrap:_insert_at_previous_line()

end
]]

--------------------------------------------------------------------------------

-- @return renoise.Instrument

function NTrap:_get_instrument()
  TRACE("NTrap:_get_instrument()")

  return renoise.song().instruments[self._instr_idx]

end

--------------------------------------------------------------------------------

--- Retrieve reference to the currently selected phrase, if any
-- @return renoise.InstrumentPhrase or nil

function NTrap:_get_phrase()
  TRACE("NTrap:_get_phrase()")

  local instr = self:_get_instrument()
  if instr then
    return instr.phrases[self._phrase_idx]
  end

end


--------------------------------------------------------------------------------

--- Create a virtual phrase object based on current criteria
-- @return table or nil (if not able to find room)
-- @return int, the index where we can insert

function NTrap:_get_virtual_phrase()
  TRACE("NTrap:_get_phrase()")

  --[[
  if not self._phrase_idx then
    LOG("No phrase have been selected")
    return
  end
  ]]

  local vphrase = {
    mapping = {}
  }
  local vphrase_idx = nil
  local instr = self:_get_instrument()
  local phrase = self:_get_phrase()
  local max_note = 119
  local prev_end = nil

  local range = self._settings.phrase_range_custom.value
  if phrase and (self._settings.phrase_range.value == 1) then
    range = self:_get_phrase_range()
  end

  -- find empty space from the selected phrase and upwards
  local begin_at, stop_at
  if self._phrase_idx then
    for k,v in ipairs(instr.phrase_mappings) do
      if (k >= self._phrase_idx) then
        if not prev_end then
          prev_end = v.note_range[1]-1
        end
        if not begin_at and
          (v.note_range[1] > prev_end+1) 
        then
          begin_at = prev_end+1
          stop_at = v.note_range[1]-1
          --print("found room between",begin_at,stop_at)
          vphrase_idx = k
          break
        end
        prev_end = v.note_range[2]
      end
    end
  end
  
  if not begin_at then
    begin_at = (prev_end) and prev_end+1 or 0
    if table.is_empty(instr.phrase_mappings) then
      vphrase_idx = 1
    else
      vphrase_idx = #instr.phrase_mappings+1
    end

  end
  if not stop_at then
    stop_at = begin_at + range - 1
  end

  if (stop_at-begin_at < range) then
    -- another phrase appears within our range
    range = stop_at-begin_at
  end
  if (stop_at > max_note) then
    -- there isn't enough room on the piano
    range = max_note-prev_end-1
  end

  -- if not room for the start, return
  if (begin_at > 119) then
    return 
  end

  vphrase.mapping.note_range = {begin_at,begin_at+range}
  return vphrase,vphrase_idx

end


--------------------------------------------------------------------------------

-- @return int

function NTrap:_get_phrase_length()
  TRACE("NTrap:_get_phrase_length()")

  local phrase = self:_get_phrase()
  if phrase then
    return phrase.number_of_lines
  end
 
  return NTrapPrefs.PHRASE_LENGTH_DEFAULT

end

--------------------------------------------------------------------------------

-- @return int

function NTrap:_get_phrase_lpb()
  TRACE("NTrap:_get_phrase_lpb()")

  local phrase = self:_get_phrase()
  if phrase then
    return phrase.lpb
  end
  
  return NTrapPrefs.LPB_DEFAULT

end

--------------------------------------------------------------------------------

-- @return bool

function NTrap:_get_phrase_loop()
  TRACE("NTrap:_get_phrase_loop()")

  local phrase = self:_get_phrase()
  if phrase then
    return phrase.mapping.looping
  end
  
  return NTrapPrefs.LOOP_DEFAULT 

end

--------------------------------------------------------------------------------

-- @return int

function NTrap:_get_phrase_range()
  TRACE("NTrap:_get_phrase_range()")

  local phrase = self:_get_phrase()
  if phrase then
    local range = phrase.mapping.note_range
    return range[2]-range[1]+1
  end
  
  return NTrapPrefs.PHRASE_RANGE_DEFAULT 

end

--------------------------------------------------------------------------------

-- @return enum KEY_TRACKING

function NTrap:_get_phrase_tracking()
  TRACE("NTrap:_get_phrase_tracking()")

  local phrase = self:_get_phrase()
  if phrase then
    return phrase.mapping.key_tracking
  end
  
  return NTrapPrefs.PHRASE_TRACKING_DEFAULT

end

--------------------------------------------------------------------------------

--- Get the currently playing pattern
-- @return int

function NTrap:_get_playing_pattern()
  TRACE("NTrap:_get_playing_pattern()")

  local playback_pos = renoise.song().transport.playback_pos
  local patt_idx = renoise.song().sequencer:pattern(playback_pos.sequence)
  return renoise.song().patterns[patt_idx]

end

--------------------------------------------------------------------------------

--- Get number of lines remaning in the playing pattern
-- @return int, lines remaining
-- @return int, total lines

function NTrap:_get_pattern_lines_remaining()
  TRACE("NTrap:_get_pattern_lines_remaining()")

  local patt = self:_get_playing_pattern()
  local playback_pos = renoise.song().transport.playback_pos

  return patt.number_of_lines - playback_pos.line,patt.number_of_lines

end

--------------------------------------------------------------------------------

--- Get number of (phrase) lines remaining before recording will be split
-- @return int, lines remaining

function NTrap:_get_split_lines_remaining()

  local lines_remaining = resolve_line_in_phrase_by_timestamp(
    self._split_requested_at,self._recording_begin,self._settings)
  local lines_recorded = resolve_line_in_phrase_by_timestamp(
    os.clock(),self._recording_begin,self._settings)
  return lines_remaining - lines_recorded


end

--------------------------------------------------------------------------------

--- Get number of lines remaning in the playing pattern
-- @return int, lines remaining
-- @return int, total lines

function NTrap:_get_recorded_lines()
  TRACE("NTrap:_get_pattern_lines_remaining()")

  return resolve_line_in_phrase_by_timestamp(
    os.clock(),self._recording_begin,self._settings)

end

-------------------------------------------------------------------------------

--- Compute an approximate value telling up how many lines we can record
-- (calculation is based on lines-per-second value for the virtual phrase)
-- @return int, lines remaining
-- @return int, total lines

function NTrap:_get_phrase_lines_remaining()
  TRACE("NTrap:_get_phrase_lines_remaining()")

  local phrase_lps = get_phrase_lps(self._settings)
  local recorded_time = (os.clock() - self._recording_begin)
  local phrase_lines = self._settings.stop_recording_lines.value
  return phrase_lines - math.floor(recorded_time*phrase_lps),phrase_lines

end


--------------------------------------------------------------------------------

-- @return number or nil

function NTrap:_get_most_recent_event()
  TRACE("NTrap:_get_most_recent_event()")

  if not table.is_empty(self._events) then
    return self._events[#self._events]
  end

end

--------------------------------------------------------------------------------

--- Process the recording. This is called each time we stop a recording,
-- or when recording is configured to create multiple takes
-- 1. allocate a new phrase to hold the recording
-- 2. parse the recorded data into this phrase via coroutine

function NTrap:_process_recording(events)
  TRACE("NTrap:_process_recording(events)",events)

  if table.is_empty(events) and
    (self._settings.skip_empty_enabled.value)
  then
    LOG("Skipping empty recording (change this in settings)")    
    return
  end

  local vphrase,vphrase_idx = self:_get_virtual_phrase()
  if not vphrase then
    LOG("Failed to allocate a phrase (no more room left?)")
    return
  end
  
  local phrase_lps = get_phrase_lps(self._settings)
  local instr = self:_get_instrument()
  local phrase = instr:insert_phrase_at(vphrase_idx)
  phrase.mapping.note_range = {
    vphrase.mapping.note_range[1],
    vphrase.mapping.note_range[2]
  }
  phrase.mapping.base_note = vphrase.mapping.note_range[1]
  phrase:clear() -- remove the default C-4 note

  -- @{ turn length into a "neat" value when using settings such as
  -- 'start at beginning of pattern' + 'after number of lines'
  local total_lines = nil
  if self._split_requested_at then 
    if (self._settings.split_recording.value == NTrapPrefs.SPLIT_LINES) then
      total_lines = self._settings.split_recording_lines.value
    elseif (self._settings.split_recording.value == NTrapPrefs.SPLIT_MANUAL) then
      total_lines = resolve_line_in_phrase_by_timestamp(
        self._split_requested_at,self._recording_begin,self._settings)
    elseif (self._settings.split_recording.value == NTrapPrefs.SPLIT_PATTERN) then
      local patt = self:_get_playing_pattern()
      local lpb_factor = self._settings.phrase_lpb_custom.value / renoise.song().transport.lpb
      total_lines = patt.number_of_lines * lpb_factor
      --print("*** split #3 - lpb_factor,self._recording_pattern_line_count",lpb_factor,self._recording_pattern_line_count)
    end
  elseif (self._settings.start_recording.value == NTrapPrefs.START_PATTERN) and
    (self._settings.stop_recording.value == NTrapPrefs.STOP_PATTERN) 
  then
    local lpb_factor = self._settings.phrase_lpb_custom.value / renoise.song().transport.lpb
    total_lines = self._recording_pattern_line_count * lpb_factor
  elseif (self._settings.stop_recording.value == NTrapPrefs.STOP_LINES) then
    total_lines = self._settings.stop_recording_lines.value
  end
  if not total_lines then
    total_lines = resolve_line_in_phrase_by_timestamp(
      self._recording_stop,self._recording_begin,self._settings)
  end
  phrase.number_of_lines = math.min(total_lines,
    renoise.InstrumentPhrase.MAX_NUMBER_OF_LINES)
  --print("*** total_lines",total_lines)

  -- @}

  -- processing function, invoked by process-slicer
  -- (so only able to use static methods and properties)
  local parse_phrase_recording = function(
    recording_begin,recording_stop,ntrap,phrase_idx)
    
    -- this structure describes our voices
    -- table = 
    --  0 = {
    --    column = (int) 
    --    event = (table)
    --    line = (int)
    --    offed = (int)
    --  }
    local voices = table.create()
    local yield_counter = 0
    local max_voice_count = 1

    -- write notes into the phrase
    local write_event = function(line,fraction,event,col_idx)
      if (line > renoise.InstrumentPhrase.MAX_NUMBER_OF_LINES) then
        LOG("*** skipping event at line",line)
        return
      end
      local phrase_line = phrase:line(line)
      local note_col = phrase_line.note_columns[col_idx]
      if event.is_note_on then
        note_col.note_value = event.pitch + (event.octave*12)
        note_col.volume_value = event.velocity
      else
        note_col.note_value = renoise.PatternLine.NOTE_OFF
      end
      note_col.delay_value = fraction * 255
      max_voice_count = math.max(max_voice_count, col_idx)
      --print("max_voice_count",max_voice_count)
    end


    for _,evt in ipairs(events) do
      
      yield_counter = yield_counter - 1
      if (yield_counter < 0) then
        yield_counter = ntrap._settings.yield_counter.value
        coroutine.yield()
      end

      --print("event",rprint(evt))
      --print("ntrap._recording_stop",recording_stop)
      if (evt.timestamp > recording_stop) then
        -- skip events that arrived after stop 
        --print("*** skip events after stop",evt.timestamp)
      else
        local line,fraction = resolve_line_in_phrase_by_timestamp(
          evt.timestamp,recording_begin,ntrap._settings)
        -- purge 'offed' notes 
        for k,v in ripairs(voices) do
          if (v.offed == line) then
            --print("*** remove offed voice in line,column ",line,v.column,v.event.pitch)
            voices:remove(k)
          end
        end
        if (evt.is_note_on) then
          --print("*** note-on at line",line)
          local voice_column = #voices+1
          if (voice_column <= renoise.InstrumentPhrase.MAX_NUMBER_OF_NOTE_COLUMNS) then
            voices[voice_column] = {
              column = voice_column,
              event = evt,
              line = line,
              offed = false,
            }
            --print("*** voice sounded in column, pitch",voice_column,evt.pitch)
            write_event(line,fraction,evt,voice_column)
          else
            LOG("*** skipping output, not enough note columns")
          end
        else
          --print("*** note-off at line",line)
          -- match pitch with playing notes
          for k,v in ipairs(voices) do
            if (v.event.pitch == evt.pitch) then
              -- apply octave difference (transposing in renoise while playing)
              local oct_diff = v.event.octave - evt.octave
              if (v.line == line) then
                if not v.offed then
                  -- if on same line as note-on, write note-off in the next line
                  -- and flag the voice as being 'offed'
                  write_event(line+1,fraction,evt,v.column)
                  v.offed = line+1
                  --print("*** voice offed in line,column,pitch ",v.offed,v.column,v.event.pitch)
                end
              else
                -- normal note-off
                write_event(line,fraction,evt,v.column)
                voices:remove(k)
                --print("*** voice turned off in line,column,pitch ",line,v.column,v.event.pitch)
              end
            end
          end
        end
      end
    end

    phrase.lpb = ntrap._settings.phrase_lpb_custom.value
    phrase.delay_column_visible = true
    phrase.mapping.looping = ntrap._settings.phrase_loop_custom.value
    phrase.visible_note_columns = max_voice_count
    ntrap._set_selected_phrase(ntrap,phrase_idx)

  end

  -- call the processing function...
  self.process_slicer = ProcessSlicer(
    parse_phrase_recording,
    self._recording_begin,
    self._recording_stop,
    self,
    vphrase_idx)
  self.process_slicer:start()


end

--==============================================================================
-- Static methods
--==============================================================================

--- Get song beats-per-second

function get_bps()

  local bpm = renoise.song().transport.bpm
  return (60/bpm)

end

--------------------------------------------------------------------------------

--- Get phrase lines-per-second

function get_phrase_lps(settings)

  return settings.phrase_lpb_custom.value / get_bps()

end

--------------------------------------------------------------------------------

--- Get song lines-per-second

function get_song_lps()

  return renoise.song().transport.lpb / get_bps()

end

--------------------------------------------------------------------------------

--- Get a line in the virtual recording by providing a timestamp
-- @param timestamp (number)
-- @return int, the line number
-- @return number, the fraction

function resolve_line_in_phrase_by_timestamp(timestamp,timestamp_begin,settings)
    
  local phrase_lps = get_phrase_lps(settings)
  local line = math.abs((timestamp - timestamp_begin)*phrase_lps)
  return math.floor(line)+1,line-math.floor(line)

end

--------------------------------------------------------------------------------

--- Obtain the timestamp of a specific line in the pattern

function resolve_timestamp_by_line_in_pattern(line)
  
  local playpos = renoise.song().transport.playback_pos
  if (playpos.line > line) then
    return os.clock() - (line / get_song_lps())
  else
    return os.clock() + (line / get_song_lps())
  end

end

--------------------------------------------------------------------------------

--- Obtain the timestamp of a specific line in the phrase
-- @param line (int)
function resolve_timestamp_by_line_in_phrase(line,settings)
  
  return (line / get_phrase_lps(settings))

end
