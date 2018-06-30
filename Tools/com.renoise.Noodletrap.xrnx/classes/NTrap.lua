--[[============================================================================
-- NTrap
============================================================================]]--

--[[--

Noodletrap main application class 

--]]

--==============================================================================

class 'NTrap'

function NTrap:__init(prefs)
  TRACE("NTrap:__init(prefs)",prefs)

  assert(type(prefs) == "NTrapPrefs",
    "Settings needs to be an instance of NTrapPrefs")

  --- (NTrapPrefs) current settings
  self._settings = prefs

  --- (int) track context
  self._track_idx = nil

  --- (int)
  self._phrase_idx = 1

  --- (int) pattern context
  self._patt_idx = nil

  --- (renoise.Midi.MidiInputDevice)
  self._midi_in = nil

  --- (table) note events
  --  {
  --    [timestamp] = NTrapEvent,
  --    [timestamp] = NTrapEvent,
  --    etc
  --  }
  self._events = table.create()

  --- (int) how many playing voices do we have
  self._live_voices = 0

  --- (NTrapUI) 
  self._ui = NTrapUI(self)

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

  --- (int) count the total length of patterenoise.song while recording
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
  --self.process_slicer = nil


  -- Provide MIDI mappings

  renoise.tool():add_midi_mapping({
    name = "Tools:Noodletrap:Prepare/Record",
    invoke = function(msg)
      if msg:is_trigger() then
        self:toggle_recording()
      end
    end
  })

  renoise.tool():add_midi_mapping({
    name = "Tools:Noodletrap:Split Recording",
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
    name = "Tools:Noodletrap:Cancel Recording",
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

  local instr = rns.selected_instrument

  if (renoise.API_VERSION >= 5) then
    instr.phrase_playback_mode = renoise.Instrument.PHRASES_OFF
  else
    instr.phrase_playback_enabled = false
  end

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
  
  self:log_string(string.format("Prepared for recording at %.4f",os.clock()))

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
    local playpos_beats = rns.transport.playback_pos_beats
    local bps = get_bps()
    local beat_fract = playpos_beats - math.floor(playpos_beats)
    self._recording_begin = os.clock() - (bps*beat_fract)
    self:log_string(string.format(
      "Beginning recording at %.4f (offset by %.4f)",
      os.clock(),(bps*beat_fract)))
  else
    self._recording_begin = os.clock()
    self:log_string(string.format(
      "Beginning recording at %.4f",os.clock()))
  end

  self._recording_begin_patt_idx = rns.selected_pattern_index
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

  self:log_string(string.format(
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
  TRACE("NTrap:toggle_recording()")

  if self._recording then
    if (self._settings.stop_recording.value == NTrapPrefs.STOP_PATTERN) then
      if rns.transport.playing then
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
  elseif self._record_armed then
    self:cancel_recording()
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

  self:log_string(string.format(
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

  self:log_string(string.format(
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

  local instr = rns.selected_instrument

  if (renoise.API_VERSION > 4) then
    instr.phrase_playback_mode = renoise.Instrument.PHRASES_PLAY_KEYMAP
  else
    instr.phrase_playback_enabled = true
  end

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

function NTrap:is_running()
  --TRACE("NTrap:is_running()")
  
  if self._ui._dialog then
    return self._ui._dialog.visible
  else
    return false
  end

end


--------------------------------------------------------------------------------

--- log string

function NTrap:log_string(...)
  --TRACE("NTrap:log_string()",str)

  self._ui:log_string(...)

end


--------------------------------------------------------------------------------

--- Feed MIDI notes in - when recording
-- @param is_note_on (bool)
-- @param pitch (int) between 0-119
-- @param velocity (int) between 0-127
-- @param octave (int) 
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

  local note = NTrapEvent{
    timestamp = os.clock(),
    is_note_on = is_note_on,
    pitch = pitch,
    velocity = velocity,
    octave = octave,
    --playpos = 
  }

  self._ui:dump_note_info(note)

  if is_note_on 
    and self._record_armed 
    and (self._settings.start_recording.value == NTrapPrefs.START_NOTE) 
  then
    self:begin_recording()
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
  local playpos = rns.transport.playback_pos
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
        self:log_string(string.format("Entered pattern %d at %d, line count is %d",
          rns.selected_pattern_index,os.clock(),
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
      local playpos = rns.transport.playback_pos
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
    local playpos = rns.transport.playback_pos

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

  self._playpos = rns.transport.playback_pos

end

--------------------------------------------------------------------------------

--- Detach from song document (remove notifiers)

function NTrap:detach_from_song()
  TRACE("NTrap:detach_from_song()")

  local new_song = false
  self._active = false
  self:_remove_notifiers(new_song,self._song_notifiers)
  self:_remove_notifiers(new_song,self._instr_notifiers)
  self:_remove_notifiers(new_song,self._phrase_notifiers)
  self:_remove_notifiers(new_song,self._patt_notifiers)

end

--------------------------------------------------------------------------------

--- Connect to the song document (attach notifiers)

function NTrap:attach_to_song(new_song)
  TRACE("NTrap:attach_to_song(new_song)",new_song)

  --local rns = renoise.song()

  self._playpos = rns.transport.playback_pos

  self._active = true
  self:_remove_notifiers(new_song,self._song_notifiers)

  self._song_notifiers:insert(rns.transport.edit_mode_observable)
  rns.transport.edit_mode_observable:add_notifier(self,
    function()
      --print("*** NTrap:edit_mode_observable fired...")
      if not self:is_running() then 
        return 
      end

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

  self._song_notifiers:insert(rns.transport.record_quantize_enabled_observable)
  rns.transport.record_quantize_enabled_observable:add_notifier(self,
    function()
      --print("*** NTrap:record_quantize_enabled_observable fired...")
      if not self:is_running() then 
        return 
      end
      if (self._settings.record_quantize.value == NTrapPrefs.QUANTIZE_RENOISE) then
        self._ui:update_quantize_popup()
      end
    end
  )
  self._song_notifiers:insert(rns.transport.record_quantize_lines_observable)
  rns.transport.record_quantize_lines_observable:add_notifier(self,
    function()
      --print("*** NTrap:record_quantize_lines_observable fired...")
      if not self:is_running() then 
        return 
      end
      if (self._settings.record_quantize.value == NTrapPrefs.QUANTIZE_RENOISE) then
        self._ui:update_quantize_popup()
      end
    end
  )

  self._song_notifiers:insert(rns.transport.playing_observable)
  rns.transport.playing_observable:add_notifier(self,
    function()
      --print("*** NTrap:playing_observable fired...")
      if not self:is_running() then 
        return 
      end

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
      if not self:is_running() then 
        return 
      end

      --if (self._settings.target_instr.value == NTrapPrefs.INSTR_FOLLOW) then
        local idx = rns.selected_instrument_index
        self:_attach_to_instrument(false,idx)
        self._update_requested = true
      --end
    end
  )

  self._song_notifiers:insert(rns.selected_phrase_observable)
  rns.selected_phrase_observable:add_notifier(self,
    function()
      --print("*** NTrap:selected_phrase_observable fired...")
      if not self:is_running() then 
        return 
      end

      self:_obtain_selected_phrase()
      --print("*** self._phrase_idx",self._phrase_idx)
    end
  )

  self._song_notifiers:insert(rns.selected_sequence_index_observable)
  rns.selected_sequence_index_observable:add_notifier(self,
    function()
      --print("*** NTrap:selected_sequence_index fired...")
      if not self:is_running() then 
        return 
      end

      local idx = rns.selected_pattern_index
      self:_attach_to_pattern(false,idx)
    end
  )

  self:_attach_to_pattern(new_song,rns.selected_pattern_index)
  self:_attach_to_instrument(new_song,rns.selected_instrument_index)
  self._update_requested = true


end

--------------------------------------------------------------------------------

--- Attach notifiers to the current pattern

function NTrap:_attach_to_pattern(new_song,patt_idx)
  TRACE("NTrap:_attach_to_pattern(new_song,patt_idx)",new_song,patt_idx)

  --local rns = renoise.song()

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
  local instr = rns.instruments[instr_idx]
  self._ui:show_instrument_warning(not instr)
  if not instr then
    instr_idx = rns.selected_instrument_index
    instr = rns.instruments[instr_idx]
  end

  self._instr_notifiers:insert(instr.phrases_observable)
  instr.phrases_observable:add_notifier(self,
    function(arg)
      --print("*** NTrap:phrases_observable fired...",arg)
      if not self:is_running() then 
        return 
      end

      -- we lost the phrase somehow? 
      if (not instr.phrases[self._phrase_idx]) then
        self:_remove_notifiers(new_song,self._phrase_notifiers)
        self._phrase_idx = nil
      end
      self._update_requested = true
    end
  )

  instr.phrase_mappings_observable:add_notifier(self,
    function(arg)
      --print("*** NTrap:phrase_mappings_observable fired...",arg)
      if not self:is_running() then 
        return 
      end

      -- we lost the phrase somehow? 
      if (not instr.phrases[self._phrase_idx]) then
        self:_remove_notifiers(new_song,self._phrase_notifiers)
        self._phrase_idx = nil
      end
      self._update_requested = true
    end
  )

  self:_obtain_selected_phrase()
  self._update_requested = true

end

--------------------------------------------------------------------------------

--- Attach notifiers to the current instrument

function NTrap:_attach_to_phrase(new_song,phrase_idx)
  TRACE("NTrap:_attach_to_phrase(new_song,phrase_idx)",new_song,phrase_idx)

  self:_remove_notifiers(new_song,self._phrase_notifiers)
  local instr = rns.selected_instrument
  local phrase = instr.phrases[phrase_idx]

  if not phrase then
    self._phrase_idx = nil
    self._update_requested = true
    return
  end

  self:attach_to_phrase_mapping()

  self._phrase_idx = phrase_idx
  self._update_requested = true

end

--------------------------------------------------------------------------------

function NTrap:attach_to_phrase_mapping(phrase_mapping)
  TRACE("NTrap:attach_to_phrase_mapping(phrase_mapping)",phrase_mapping)

  if not phrase_mapping then
    phrase_mapping = xPhraseManager.get_selected_mapping()
  end

  if not phrase_mapping then
    LOG("*** Noodletrap: could not attach to phrase mapping")
    return
  end

  self._phrase_notifiers:insert(phrase_mapping.key_tracking_observable)
  phrase_mapping.key_tracking_observable:add_notifier(self,
    function()
      --print("*** NTrap:key_tracking_observable fired...")
      self._update_requested = true
    end
  )

  self._phrase_notifiers:insert(phrase_mapping.looping_observable)
  phrase_mapping.looping_observable:add_notifier(self,
    function()
      --print("*** NTrap:looping_observable fired...")
      self._update_requested = true
    end
  )

  self._phrase_notifiers:insert(phrase_mapping.note_range_observable)
  phrase_mapping.note_range_observable:add_notifier(self,
    function()
      --print("*** NTrap:note_range_observable fired...")
      self._update_requested = true
    end
  )

end

--------------------------------------------------------------------------------
-- Detach all attached notifiers in list, but don't even try to detach 
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
-- Since the selected_phrase_index is a global property of the song,
-- we check when switching instrument if we can eavesdrop on that value
-- (otherwise, we use the UI dialog for selecting a specific phrase)

function NTrap:_obtain_selected_phrase()
  TRACE("NTrap:_obtain_selected_phrase()")

  local phrase_idx = rns.selected_phrase_index
  if (phrase_idx > 0) then 
    self:_attach_to_phrase(false,phrase_idx)
  end

end

--------------------------------------------------------------------------------
-- Check if we can actually record
-- (will display an error message when something went wrong)
-- @return bool, true when ready

function NTrap:_recording_check()
  --TRACE("NTrap:_recording_check()")

  -- TODO no more room for keymapped phrases 


  return true

end


--------------------------------------------------------------------------------
-- If running as a standalone tool, save the key/value in the persistent
-- settings. Otherwise, compile a serialized string and hand it over...

function NTrap:_save_setting(key,value)
  TRACE("NTrap:_save_setting(key,value)",key,value)

  assert(type(self._settings) == "NTrapPrefs",
    "Please instantiate NTrapPrefs before saving preferences") 

  -- a property can never be nil 
  if (type(value)=="nil") then
    return
  end

  self._settings:property(key).value = value

end

--------------------------------------------------------------------------------
-- Open the selected MIDI port
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
    LOG("*** Noodletrap: Could not create MIDI input device ", port_name)
  end


end


--------------------------------------------------------------------------------
-- Close the MIDI port

function NTrap:_close_midi_port()
  TRACE("NTrap:_close_midi_port()")

  if (self._midi_in and self._midi_in.is_open) then
    self._midi_in:close()
  end

  self._midi_in = nil

end


--------------------------------------------------------------------------------
-- Interpret incoming MIDI

function NTrap:_midi_callback(message)
  TRACE(("NTrap: received MIDI %X %X %X"):format(
    message[1], message[2], message[3]))

  if not self:is_running() then 
    return 
  end

  local is_note_on = true
  local rns_pitch,velocity
  local rns_octave = rns.transport.octave

  if (message[1]>=128) and (message[1]<=159) then

    -- when aligned, lower the pitch - the renoise 
    -- octave is added on top once the note is written
    rns_pitch = message[2] -48

    -- ignore note if outside playable range 
    if (rns_pitch+(rns_octave*12) < 0) 
      or (rns_pitch+(rns_octave*12) > 119) 
    then
      LOG("*** Noodletrap: ignore note outside playable range",rns_pitch+(rns_octave*12))
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
-- @return int

function NTrap:_get_phrase_length()
  TRACE("NTrap:_get_phrase_length()")

  local phrase = rns.selected_phrase
  if phrase then
    return phrase.number_of_lines
  end
 
  return NTrapPrefs.PHRASE_LENGTH_DEFAULT

end

--------------------------------------------------------------------------------
-- @return int

function NTrap:_get_phrase_lpb()
  TRACE("NTrap:_get_phrase_lpb()")

  local phrase = rns.selected_phrase
  if phrase then
    return phrase.lpb
  end
  
  return NTrapPrefs.LPB_DEFAULT

end

--------------------------------------------------------------------------------
-- @return bool

function NTrap:_get_phrase_loop()
  TRACE("NTrap:_get_phrase_loop()")

  local phrase_mapping = xPhraseManager.get_selected_mapping()
  if phrase_mapping then
    return phrase_mapping.looping
  end
  
  return NTrapPrefs.LOOP_DEFAULT 

end

--------------------------------------------------------------------------------
-- @return int

function NTrap:_get_phrase_range()
  TRACE("NTrap:_get_phrase_range()")

  local phrase_mapping = xPhraseManager.get_selected_mapping()
  if phrase_mapping then
    local range = phrase_mapping.note_range
    return range[2]-range[1]+1
  end
  
  return NTrapPrefs.PHRASE_RANGE_DEFAULT 

end

--------------------------------------------------------------------------------
-- @return int

function NTrap:_get_phrase_offset()
  TRACE("NTrap:_get_phrase_offset()")

  local phrase_mapping = xPhraseManager.get_selected_mapping()
  if phrase_mapping then
    local range = phrase_mapping.note_range
    return range[1]+1
  end
  
  return NTrapPrefs.PHRASE_OFFSET_DEFAULT 

end

--------------------------------------------------------------------------------
-- @return enum KEY_TRACKING

function NTrap:_get_phrase_tracking()
  TRACE("NTrap:_get_phrase_tracking()")

  local phrase_mapping = xPhraseManager.get_selected_mapping()
  if phrase_mapping then
    return phrase_mapping.key_tracking
  end
  
  return NTrapPrefs.PHRASE_TRACKING_DEFAULT

end

--------------------------------------------------------------------------------

--- Get the currently playing pattern
-- @return int

function NTrap:_get_playing_pattern()
  TRACE("NTrap:_get_playing_pattern()")

  local playback_pos = rns.transport.playback_pos
  local patt_idx = rns.sequencer:pattern(playback_pos.sequence)
  return rns.patterns[patt_idx]

end

--------------------------------------------------------------------------------
-- How much are we quantizing the input (number or lines) 
-- @return int or nil if no quantize

function NTrap:_get_quant_amount()
  TRACE("NTrap:_get_quant_amount()")

  if (self._settings.record_quantize.value == NTrapPrefs.QUANTIZE_NONE) then
    return nil
  elseif (self._settings.record_quantize.value == NTrapPrefs.QUANTIZE_CUSTOM) then
    if (self._settings.record_quantize_custom.value == 1) then
      return nil
    else
      return self._settings.record_quantize_custom.value-1
    end
  elseif (self._settings.record_quantize.value == NTrapPrefs.QUANTIZE_RENOISE) then
    return rns.transport.record_quantize_enabled and
      rns.transport.record_quantize_lines or nil
  end

end

--------------------------------------------------------------------------------
-- Get number of lines remaning in the playing pattern
-- @return int, lines remaining
-- @return int, total lines

function NTrap:_get_pattern_lines_remaining()
  TRACE("NTrap:_get_pattern_lines_remaining()")

  local patt = self:_get_playing_pattern()
  local playback_pos = rns.transport.playback_pos

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
    self:log_string("Skipping empty recording (change this in settings)")    
    return
  end

  local max_note_cols = renoise.InstrumentPhrase.MAX_NUMBER_OF_NOTE_COLUMNS

  --local phrase_lps = get_phrase_lps(self._settings)
  local instr = rns.selected_instrument
  local instr_idx = rns.selected_instrument_index

  local keymap_args = {
    keymap_range = NTrap:_get_phrase_range(),
    keymap_offset = NTrap:_get_phrase_offset(),
  }

  local phrase,phrase_idx = xPhraseManager.auto_insert_phrase(instr_idx,nil,nil,keymap_args)
  if phrase and phrase.mapping then
    self:attach_to_phrase_mapping(phrase.mapping)
  end

  if not phrase then 
    LOG("*** Noodletrap: failed to allocate phrase, recording not saved")
    return
  end
  
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
      local lpb_factor = self._settings.phrase_lpb_custom.value / rns.transport.lpb
      total_lines = patt.number_of_lines * lpb_factor
      --print("*** split #3 - lpb_factor,self._recording_pattern_line_count",lpb_factor,self._recording_pattern_line_count)
    end
  elseif (self._settings.start_recording.value == NTrapPrefs.START_PATTERN) and
    (self._settings.stop_recording.value == NTrapPrefs.STOP_PATTERN) 
  then
    local lpb_factor = self._settings.phrase_lpb_custom.value / rns.transport.lpb
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

  --print("events",rprint(events))

  -- processing function, invoked by process-slicer
  -- (so only able to use static methods and properties)
  local parse_phrase_recording = function(
    recording_begin,recording_stop,ntrap,phrase_idx,quant_amount)
    
    -- this structure describes our voices
    -- table = 
    --  0 = {
    --    column = (int) 
    --    event = (table) -- NTrapEvent 
    --    line = (int)  -- the line at which note-on occurred
    --    offed = (int) -- the line at which the note is released
    --                  -- (set when multiple notes arrive within a line)
    --  }
    local voices = table.create()
    local yield_counter = 0
    local max_voice_count = 1

    -- write notes into the phrase
    local write_event = function(line,fraction,event,col_idx,quantize)
      --print("write_event = function(line,fraction,event,col_idx)",line,fraction,event,col_idx)
      if (line > renoise.InstrumentPhrase.MAX_NUMBER_OF_LINES) then
        LOG("*** Noodletrap: skipping event at line",line)
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
      if not quantize then
        note_col.delay_value = fraction * 255
      end
      max_voice_count = math.max(max_voice_count, col_idx)
      --print("max_voice_count",max_voice_count)
    end


    for _,evt in ipairs(events) do
      
      yield_counter = yield_counter - 1
      if (yield_counter < 0) then
        yield_counter = ntrap._settings.yield_counter.value
        --coroutine.yield()
      end

      --print("event",rprint(evt))
      --print("ntrap._recording_stop",recording_stop)
      if (evt.timestamp > recording_stop) then
        -- skip events that arrived after stop 
        --print("*** skip events after stop     ",evt.timestamp)
      else
        local line,fraction = resolve_line_in_phrase_by_timestamp(
          evt.timestamp,recording_begin,ntrap._settings)

        -- quantize line? 
        -- use the provided quantize amount, unless a note-off 
        -- set to preserve its length...
        local q_amount
        local preserve = self._settings.quantize_preserve_length.value
        --print("preserve,evt.is_note_on",preserve,evt.is_note_on)
        if (not evt.is_note_on and preserve) then
          q_amount = nil
        else
          q_amount = quant_amount
        end

        if q_amount then
          line = quantize_line(line,fraction,q_amount)
        end
        
        -- purge 'offed' notes 
        for k = max_note_cols, 1, -1 do
          local v = voices[k]
          if v and (v.offed == line) then
            --print("*** remove offed voice in line,column ",line,v.column,v.event.pitch)
            voices[k] = nil
          end
        end
        if (evt.is_note_on) then
          --print("*** note-on at line            ",line)

          local voice_column = nil
          if instr.trigger_options.monophonic then
            voice_column = 1
          else
            -- use the first/next available column
            voice_column = 0
            local leftmost = 1000
            local col_idx = 1
            while col_idx <= max_note_cols do
              if voices[col_idx] then
                voice_column = math.max(voices[col_idx].column,voice_column)
              else
                leftmost =  math.min(col_idx,leftmost)
              end
              col_idx = col_idx+1
            end
            if leftmost < voice_column then 
              -- first available column
              voice_column = leftmost
            else 
              -- next available column 
              voice_column = voice_column+1
            end
          end

          if (voice_column <= max_note_cols) then
            voices[voice_column] = {
              column = voice_column,
              event = evt,
              line = line,
              offed = false,
            }
            --print("sounded in column, pitch   ",voice_column,evt.pitch)
            write_event(line,fraction,evt,voice_column,q_amount)
          else
            LOG("*** Noodletrap: skipping output, not enough note columns")
          end
        else
          --print("*** note-off at line, pitch    ",line,evt.pitch)
          for k = 1, max_note_cols do

            local v = voices[k]
            if (v) and (v.event.pitch == evt.pitch) then
              if (v.line == line) then
                if not v.offed then
                  -- if on same line as note-on, write note-off in the next line
                  -- (as we can't note-off on the same line)
                  write_event(line+1,fraction,evt,v.column,q_amount)
                  -- flag the voice as being 'offed', so it won't be included
                  v.offed = line+1
                end
              else
                -- normal note-off
                if not v.offed then
                  write_event(line,fraction,evt,v.column,q_amount)
                end
                voices[k] = nil
                --print("note-off line,column,pitch   ",line,v.column,v.event.pitch)
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
    xPhraseManager.set_selected_phrase(phrase_idx)

  end

  -- call the processing function...
  --[[
  self.process_slicer = ProcessSlicer(
    parse_phrase_recording,
    self._recording_begin,
    self._recording_stop,
    self,
    vphrase_idx,
    self:_get_quant_amount())
  self.process_slicer:start()
  ]]

  parse_phrase_recording(
    self._recording_begin,
    self._recording_stop,
    self,
    phrase_idx,
    self:_get_quant_amount())


end

--==============================================================================
-- Static methods
--==============================================================================

--- Get song beats-per-second

function get_bps()

  local bpm = rns.transport.bpm
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

  return rns.transport.lpb / get_bps()

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
  
  local playpos = rns.transport.playback_pos
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

--------------------------------------------------------------------------------
-- quantize line:  snap to nearest line, then quantize
-- @param line (int) 
-- @param fraction (number) between 0 and 1
-- @param amount (int or nil) how many lines, nil to skip quantize
-- @return line

function quantize_line(line,fraction,quant_amount)

  if not quant_amount then
    return line
  end

  line = line-1 -- calculate with zero offset
  if (fraction > 0.5) then
    line = line+1
  end
  local quant_offset = (line%quant_amount)
  line = line - quant_offset
  return line+1  -- end zero offset

end


