--==============================================================================

--- Mlrx_track - this class represent a logical track in mlrx


class 'Mlrx_track' 

-- constants 

Mlrx_track.MIDDLE_C = 48
--Mlrx_track.NOTE_OFF = 120
--Mlrx_track.NOTE_EMPTY = 121
--Mlrx_track.VELPAN_EMPTY = 255
Mlrx_track.SHUFFLE_LENGTH = 4
Mlrx_track.MAX_OFFSETS = 256
Mlrx_track.FALLBACK_LINESYNC = 64

Mlrx_track.MIN_BEAT_SYNC = 8
Mlrx_track.MAX_BEAT_SYNC = 512

Mlrx_track.DEFAULT_VELOCITY = 0x7F
Mlrx_track.DEFAULT_PANNING = 0x40

Mlrx_track.WRITEAHEAD_SHORT = 400  
Mlrx_track.WRITEAHEAD_LONG = 250  

-- enums

Mlrx_track.TRIG_HOLD = 1  
Mlrx_track.TRIG_TOGGLE = 2
Mlrx_track.TRIG_TOUCH = 3 
Mlrx_track.TRIG_WRITE = 4 

Mlrx_track.ARP_ALL = 1
Mlrx_track.ARP_RANDOMIZE = 2
Mlrx_track.ARP_FORWARD = 3
Mlrx_track.ARP_TWOSTEP = 4
Mlrx_track.ARP_FOURSTEP = 5
Mlrx_track.ARP_KEYS = 6

Mlrx_track.TRACK_FXCOL_SXX = 1
Mlrx_track.TRACK_FXCOL_EXX = 2
Mlrx_track.TRACK_FXCOL_CXX = 3

Mlrx_track.PARAM_PANNING = 1
Mlrx_track.PARAM_VELOCITY = 2

Mlrx_track.DRIFT_OFF = 1
Mlrx_track.DRIFT_ALL = 2
Mlrx_track.DRIFT_CYCLE = 3

--- (enum) 
Mlrx_track.CYCLE = {
  CUSTOM = -1,  -- -1 = custom size (set cycle lines directly)
  EDITSTEP = 0, -- 0  = sync with edit_step
  FULL = 1,
  HALF = 2,
  FOURTH = 4,
  EIGHTH = 8,
  SIXTEENTH = 16,
}

-- predefined beat sync values
Mlrx_track.BEAT_SYNC_LINES = table.create()
for i = 16,513,16 do
  Mlrx_track.BEAT_SYNC_LINES:insert(i)
end

--------------------------------------------------------------------------------

--- Constructor method

function Mlrx_track:__init(main)
  --print("Mlrx_track:__init()",main)

  -- (Mlrx) reference to main application
  self.main = main

  -- (int) the associated Renoise instrument/track
  -- note: do not assume that they exist (they can be invalid)
  self.rns_instr_idx = nil
  self.rns_track_idx = nil

  -- (Mlrx_group) the group that this track belong to 
  self.group = nil

  -- (int) the index of this track in the main application 
  self.self_idx = nil

  -- (enum) the default triggering mode
  self.trig_mode = Mlrx_track.TRIG_HOLD

  -- (bool) the initial arp state
  self.arp_enabled = false
  
  -- (enum) the default arp mode 
  self.arp_mode = Mlrx_track.ARP_ALL

  -- (int) internal arp position
  self.arp_index = 1

  -- (enum) the default sample loop mode
  --self.loop_mode = nil

  -- (bool) whether to include notes in output
  self.do_note_output = true

  -- (bool) whether to include sample-offset in output
  self.do_sxx_output = true

  -- (bool) whether to include envelope-offset in output
  self.do_exx_output = false

  -- (renoise.Instrument or nil) the designated renoise instrument
  -- when value is nil, this means that the instrument doesn't exist,
  -- is defined but empty, or that it contains an 'empty sample'
  self.instr = nil

  -- (renoise.Sample or nil) the active sample, if any
  self.sample = nil

  -- (renoise.InstrumentPhrase or nil) the instrument phrase, if any
  self.phrase = nil

  -- (bool) true when next trigger will start a phrase recording 
  self.phrase_record_armed = false

  -- (bool) true while recording a new phrase
  self.phrase_recording = false

  -- (table) 
  --    [os.clock]
  --      [line index]
  --        (string) serialized PatternLine 
  self.phrase_recording_buffer = nil

  -- (ProcessSlicer) for dealing with CPU intensive tasks
  self.process_slicer = nil

  -- (bool) true when sample is being sliced
  self.is_sliced = false

  -- (int) the line-sync value
  -- when dealing with "raw" samples, equal to beat_sync_lines or approx. duration
  -- when dealing with a phrase, equal to phrase length
  self.sync_to_lines = nil

  -- (int) the current note to output
  self.note_pitch = Mlrx_track.MIDDLE_C

  -- (int) the current velocity level (0-127)
  self.velocity = Mlrx_track.DEFAULT_VELOCITY

  -- (bool) true when velocity is set to default value
  self.default_velocity = true

  -- (int) channel pressure, added to velocity when output
  self.pressure = 0

  -- (int) the current panning amount (0-127)
  self.panning = Mlrx_track.DEFAULT_PANNING

  -- (bool) true when panning is set to default value
  self.default_panning = true

  -- (bool) true when recording automation in WRITE mode
  self.trk_latch_velocity = false
  self.trk_latch_panning = false
  self.trk_latch_shuffle = false

  --- (Mlrx_track.CYCLE)
  self.cycle_length = Mlrx_track.CYCLE.FULL

  -- (int) the actual number of lines in the cycle 
  self.cycle_lines = nil

  -- (int) amount of track shuffle, between 0 and 255
  self.shuffle_amount = 0

  -- (bool) whether "shuffle cut" is enabled or not
  self.shuffle_cut = false

  -- (int) default drift value, between -128 and 128
  -- 1 = slowly forward, -1 slowly backwards, extremes are "strobing"
  self.drift_amount = 8

  -- (enum) the default drifting mode
  self.drift_mode = Mlrx_track.DRIFT_OFF

  -- (Mlrx_note or nil) playing/scheduled note 
  self.note = nil

  -- (SongPos) local copy of playback position
  -- used for checking if playback has 'wrapped around'
  self._last_playpos = nil

  -- (int) current note-column position
  self.note_col_idx = 1

  -- (int) current writeahead and readahead values
  self.writeahead = nil 
  self.readahead = nil 

  -- (int) depending on the trig mode we use different writeahead
  -- (make TOUCH mode more responsive, delete less data)
  self.writeahead_factor = Mlrx_track.WRITEAHEAD_LONG

  -- (enum) remember the loop mode each time it is enabled
  -- (this allows us to have an on/off style button)
  self._cached_loop_mode = nil

  -- (bool) when using TOGGLE or WRITE mode, we clear 
  -- pattern data, even when no notes is actively playing...
  self._clear_without_note = false

  -- (int) the most recently triggered button (1 - NUM__triggers)
  -- this value is kept after button has been released, so we can MIDI-trigger 
  -- notes from the same offset
  -- also, TRIG_WRITE/TRIG_TOGGLE will clear pattern data once this has been set
  self._last_pressed = nil

  -- (int) which button is currently being lit  (1 - NUM__triggers)
  self._lit_position = nil

  -- (int) number of trigger-buttons on the controller
  self._num_triggers = nil

  -- (table) array of held buttons (order of arrival)
  self._held_triggers = table.create()

  -- (table) current assigned MIDI notes 
  self._held_keys = table.create()

  -- (bool) true when we have navigated away from a track, 
  -- and released a midi triggered note there 
  self._hanging_notes = false

  -- (ScheduledTask) various task references
  self._prepare_sample_task = nil
  self._update_summary_task = nil
  self._slice_mode_task = nil
  self._attach_to_instr_task = nil
  self._decorate_track_task = nil
  self._set_transpose_task = nil

  -- named notifiers (need to be attached/detached)
  self.loop_mode_notifier = nil
  self.beat_sync_lines_notifier = nil
  self.beat_sync_enabled_notifier = nil

  -- (Array) collections of notifiers
  self._track_observables = table.create()
  self._sample_observables = table.create()
  self._phrase_observables = table.create()
  self._instr_observables = table.create()

end

--------------------------------------------------------------------------------

--- Output some debugging info

function Mlrx_track:__tostring()
  return "Mlrx_track - rns_track_idx",rns_track_idx,"rns_instr_idx",rns_instr_idx

end  

--------------------------------------------------------------------------------

-- called by the main class: clear all references to the document/song 

function Mlrx_track:clear_references()

  self.main.display.scheduler:remove_task(self._attach_to_instr_task)
  self.main.display.scheduler:remove_task(self._decorate_track_task)
  self.main.display.scheduler:remove_task(self._prepare_sample_task)
  self.main.display.scheduler:remove_task(self._set_transpose_task)
  self.main.display.scheduler:remove_task(self._slice_mode_task)
  self.main.display.scheduler:remove_task(self._update_summary_task)

  self:remove_notifiers(self._track_observables)
  self:remove_notifiers(self._phrase_observables)
  self:remove_notifiers(self._sample_observables)
  self:remove_notifiers(self._instr_observables)

end


--------------------------------------------------------------------------------

function Mlrx_track:update_summary_task()
  --TRACE("Mlrx_track:update_summary_task()")
  
  self.main.display.scheduler:remove_task(self._update_summary_task)
  self._update_summary_task = self.main.display.scheduler:add_task(
    self.main, Mlrx.update_summary, 0.2, self.self_idx)
    
end

--------------------------------------------------------------------------------

-- check if sample has changed - each time this method is called, a small 
-- "voiceprint" of the sample buffer is stored for later comparison

function Mlrx_track:sample_has_changed()
  TRACE("Mlrx_track:sample_has_changed()")

  if not self.sample then
    return
  end

  local rslt = not self.voiceprint and true or false
  local array_size = 16
  local voiceprint = table.create()

  if self.sample.sample_buffer.has_sample_data then
    --print("sample.sample_buffer.number_of_frames",sample.sample_buffer.number_of_frames)
    local sample_spacing = self.sample.sample_buffer.number_of_frames/array_size
    for frame_index = 1,self.sample.sample_buffer.number_of_frames,sample_spacing do
      local frame = 0 -- add channels together
      --print("sample.sample_buffer.number_of_channels",sample.sample_buffer.number_of_channels)
      for channel_index = 1,self.sample.sample_buffer.number_of_channels do
        frame = frame + self.sample.sample_buffer:sample_data(channel_index,frame_index)
      end
      voiceprint:insert(frame)
    end
  end
  
  if self.voiceprint and
    (voiceprint:concat(",")~=self.voiceprint:concat(",")) 
  then
    rslt = true
  end

  self.voiceprint = voiceprint
  --print("*** sample_has_changed - rslt",rslt,voiceprint)
  return rslt

end

--------------------------------------------------------------------------------

-- Automatically set the loop and beat-sync when a sample is being loaded
-- (which is detected via the sample_buffer/loop_mode observables...)

function Mlrx_track:prepare_sample_task()
  --TRACE("Mlrx_track:prepare_sample_task()")
  self.main.display.scheduler:remove_task(self._prepare_sample_task)
  self._prepare_sample_task = self.main.display.scheduler:add_task(
    self, Mlrx_track.prepare_sample, 0.2)
end

function Mlrx_track:prepare_sample()
  TRACE("Mlrx_track:prepare_sample()")

  if (self.main.options.sample_prep.value == Mlrx.SAMPLE_PREP_OFF) then
    return
  end

  local changed = self:sample_has_changed()
  if changed then


    local enable_beat_sync = true
    local slines = self:obtain_sample_lines()
    --print("*** prepare_sample - slines",slines)
    if not slines then
      self.sync_to_lines = Mlrx_track.FALLBACK_LINESYNC
    elseif (slines > Mlrx_track.MAX_BEAT_SYNC) or 
      (slines < Mlrx_track.MIN_BEAT_SYNC) 
    then
      enable_beat_sync = false
      self.sync_to_lines = round_value(slines)
    else
      self.sync_to_lines = self.sample.beat_sync_lines
    end
    self:determine_cycle_lines()
    --print("*** prepare_sample - enable_beat_sync",enable_beat_sync)

    self:remove_notifier(
      self.sample.beat_sync_enabled_observable,
      self.beat_sync_enabled_notifier)
    self.sample.beat_sync_enabled = enable_beat_sync
    self.sample.beat_sync_enabled_observable:add_notifier(self.beat_sync_enabled_notifier)
    self.main:update_linesync(self)


    -- enable looping
    if (self.sample.loop_mode == renoise.Sample.LOOP_MODE_OFF) then
      self:remove_notifier(
        self.sample.loop_mode_observable,
        self.loop_mode_notifier)
      self.sample.loop_mode = renoise.Sample.LOOP_MODE_FORWARD
      self.sample.loop_mode_observable:add_notifier(self.loop_mode_notifier)
    end
    self.main:update_toggle_loop(self)

  end

end

--------------------------------------------------------------------------------

function Mlrx_track:schedule_repeat(seq,line,playpos)
  TRACE("Mlrx_track:schedule_repeat(seq,line)",seq,line,playpos)

  local repeatpos = Mlrx_pos({
    sequence = seq,
    line = line
  })

  self.note.travelled = playpos.line-line

  -- if positive, take a closer look...probably means that
  -- the current pattern wrapped around
  if (self.note.travelled>0) then
    local diff = Mlrx:get_pos_diff(playpos,repeatpos)
    self.note.travelled = -diff
    --renoise.app():show_status("self.note.travelled:"..self.note.travelled)
  end
  self.note.repeatpos = repeatpos
  self.note.repeatpos.line = line + self.cycle_lines
  self.note.repeatpos:normalize()
  --print(" scheduled repeatpos",self.note.repeatpos)


end

--------------------------------------------------------------------------------

-- write a note to the pattern-track 

function Mlrx_track:write_note(rns_trk,line_idx,note_col,fxcol_1,fxcol_2,fxcol_3,first_note)


  if self.do_note_output then

    -- basic note properties
    --------------------------------------

    -- handle ARP_KEYS mode

    local note_pitch = self.note_pitch
    --if not first_note and (self.arp_mode == Mlrx_track.ARP_KEYS) then  
    if (self.arp_mode == Mlrx_track.ARP_KEYS) then  
      local keys = self._held_keys
      --print("*** write_note - ARP_FORWARD - self._held_keys",keys)
      --rprint(keys)
      if not self._held_keys:is_empty() then
        note_pitch = self._held_keys[(self.arp_index%#self._held_keys)+1]
      end
      self.arp_index = self.arp_index + 1
    end


    note_col.instrument_value = self.rns_instr_idx-1
    note_col.note_value = note_pitch

    -- volume / panning
    --------------------------------------

    if self.note or
      (self.main.options.automation.value ~= Mlrx.AUTOMATION_READ) 
    then
      note_col.volume_value = self.default_velocity and 
        renoise.PatternLine.EMPTY_VOLUME or 
          math.min(Mlrx.INT_7BIT,self.velocity+self.pressure)
      --print("*** write_note - note_col.volume_value",note_col.volume_value)
      note_col.panning_value = self.default_panning and 
        renoise.PatternLine.EMPTY_PANNING or self.panning
    end

    -- shuffle (delay column)
    --------------------------------------

    if (self.shuffle_amount > 0) then
      self:output_shuffle(rns_trk,line_idx,note_col,fxcol_3)
    else
      note_col.delay_value = renoise.PatternLine.EMPTY_DELAY
    end

  end


  -- sample/envelope: arpeggiator 
  --------------------------------------

  -- when neither enveloper or sample offsets are enabled...
  if not self.do_exx_output and not self.do_sxx_output then
    return
  end

  local note_index = self.note.index
  --print("*** write_note - note_index",note_index)
  if self.arp_enabled then

    --print("*** first_note",first_note)
    if first_note then
      -- reset arp counter
      self.arp_index = 1
    end
    --print("*** write_note - self.arp_index",self.arp_index)
    --print("*** write_note - self._last_pressed",self._last_pressed)

    -- build a table of active indices (at least one)
    local indices = table.create()
    if self._held_triggers:is_empty() then
      indices:insert(self._last_pressed)
    else
      indices = table.rcopy(self._held_triggers)
    end

    --print("*** indices...")
    --rprint(indices)
    --print("*** write_note - pre arpeggiator note_index",note_index)

    if not first_note and
      (self.arp_mode == Mlrx_track.ARP_ALL) 
    then 
      note_index = math.random(1,self.main._num_triggers)
    elseif not first_note and
      (self.arp_mode == Mlrx_track.ARP_TWOSTEP) or
      (self.arp_mode == Mlrx_track.ARP_FOURSTEP) 
    then  
      local step_size = (self.arp_mode == Mlrx_track.ARP_TWOSTEP) and 2 or 4
      note_index = ((math.floor((math.random(1,self.main._num_triggers)/step_size))*step_size)+note_index)%self.main._num_triggers
      if (note_index == 0) then
        note_index = self.main._num_triggers
      end
    elseif not first_note and
      (self.arp_mode == Mlrx_track.ARP_RANDOMIZE) 
    then  
      note_index = indices[(math.random(1,self.main._num_triggers)%#indices)+1]
    elseif (self.arp_mode == Mlrx_track.ARP_FORWARD) then  
      note_index = indices[(self.arp_index%#indices)+1]
      self.arp_index = self.arp_index + 1
    end

    --print("*** write_note - post arpeggiator note_index",note_index)

  end -- /arp_enabled


  -- sample/envelope offset: apply drift
  --------------------------------------

  local final_offset = (Mlrx_track.MAX_OFFSETS/self._num_triggers)*(note_index-1)
  --print("*** write_note - final_offset #A",final_offset)
  if (self.drift_mode ~= Mlrx_track.DRIFT_OFF) and (self.drift_amount ~= 0) then
    local drift_offset = (self.note.total_notes_written*self.drift_amount)
    if (self.drift_mode == Mlrx_track.DRIFT_CYCLE) then
      if (self.cycle_length > Mlrx_track.CYCLE.EDITSTEP) then
        drift_offset = drift_offset%(256/self.cycle_length) 
      else
        drift_offset = drift_offset%(256/self._num_triggers) 
      end
    end
    final_offset = (final_offset+drift_offset)%256
  end
  --print("*** write_note - final_offset #B",final_offset)


  -- display arpeggiated/shifted note as a brief flash
  local display_val = math.floor(final_offset/(255/self._num_triggers))+1
  if (display_val ~= self.note.index) then
    --print("*** write_note - display shifted note",display_val,"arpeggiated",note_index,"original",self.note.index)
    self.main:trigger_feedback(self.self_idx,display_val)
  end 


  -- sample/envelope offset: output
  --------------------------------------

  if self.do_sxx_output then
    fxcol_1.number_string = "0S"
    fxcol_1.amount_value = self.phrase and 
        (self.phrase.number_of_lines/self._num_triggers)*(note_index-1)
      or self.is_sliced and
          (note_index) -- 'out of bounds' slice offsets are OK
        or
          final_offset -- normal 
  end

  if self.do_exx_output then
    fxcol_2.number_string = "0E"
    fxcol_2.amount_value = final_offset
  end

  self.note.total_notes_written = self.note.total_notes_written + 1


end

--------------------------------------------------------------------------------

-- called whenever tempo has changed

function Mlrx_track:determine_writeahead()
  TRACE("Mlrx:determine_writeahead()")

  local bpm = rns.transport.bpm
  local lpb = rns.transport.lpb

  -- output buffer size
  self.writeahead = math.ceil(math.max(1,(bpm*lpb)/self.writeahead_factor))
  --print("Mlrx.writeahead",Mlrx.writeahead)

  -- lines-per-second 
  self.lps = 1 / (60/bpm/lpb)
  --print("Mlrx.lps",Mlrx.lps)

  -- we assume that idle loop is called every 10th of a second,
  -- so we can divide the lines-per-second with this value
  self.readahead = math.ceil(math.max(1,self.lps/10))
  --print("Mlrx.readahead",Mlrx.readahead)

end


--------------------------------------------------------------------------------

-- method for writing data into a pattern-track, a few lines at a time
-- also: fancy detection of active state, duration of notes and more...
--
-- @param writepos (Mlrx_pos) start from this position
-- @param writeahead (int) process # of lines, starting from writepos (0 means single line is written)
-- @param wraparound (bool) optional, true when writing across pattern boundaries
-- @param on_idle (bool) optional, true when invoked by idle loop (we then detect notes being active or turned off)

function Mlrx_track:track_output(writepos,writeahead,wraparound,on_idle)
  --TRACE("Mlrx_track:track_output()",writepos,writeahead,wraparound,on_idle,self.rns_track_idx)


  local rns_trk = rns.tracks[self.rns_track_idx]
  local patt_idx = rns.sequencer.pattern_sequence[writepos.sequence]
  local patt = rns:pattern(patt_idx)
  local readahead = self.readahead
  local active_track = self.main.tracks[self.group.active_track_index]

  ---------------------------------------------------------
  -- determine if we should wipe, read or write
  ---------------------------------------------------------

  local do_wipe = false
  local do_read = false

  local group_active = (self.note) and true or false
  if not group_active then
    for _,trk in ipairs(self.group.tracks) do
      if (trk.note) then
        --print("trk.note",trk.note,trk.self_idx)
        group_active = true
        --break
      end

    end
  end
  if group_active then
    if self.group.void_mutes then
      do_read = not self.note
      if self._clear_without_note then
        do_wipe = not self.note
      else
        do_wipe = false
      end
    else -- normal mute group (active)
      do_wipe = not self.note
    end
  else -- inactive group 
    do_read = true
    --print("self.group.active_track_index",self.group.active_track_index)
    --print("active_track",active_track)
    if active_track and 
      active_track._clear_without_note 
    then
      do_wipe = true 
    else
      do_wipe = false
    end
    --print("do_wipe",do_wipe)

  end


  local playpos = Mlrx_pos()
  --print("*** track_output - playpos",playpos,"track index",self.rns_track_idx,"do_wipe",do_wipe,"do_read",do_read,"wraparound",wraparound,"group_active",group_active)

  -- determine the rate at which notes repeat
  -- (if very fast, use alternative write method)
  local fast_repeat = (self.cycle_lines <= self.writeahead)


  ---------------------------------------------------
  -- check if we exceed the pattern 
  -- (then shorten the writeahead)
  ---------------------------------------------------

  local exceeded = false
  local exceeded_by = nil
  local line_to = writepos.line+writeahead
  if (line_to > patt.number_of_lines) then
    exceeded = true
    exceeded_by = line_to-patt.number_of_lines-1
    line_to = patt.number_of_lines
    writeahead = writeahead - exceeded_by
  end
  --print(" pattern exceeded_by",exceeded_by,"line_to",line_to,"writepos.line",writepos.line,"writeahead",writeahead)

  ---------------------------------------------------
  -- main loop:
  -- + wipe pattern data, or 
  -- + read notes using readahead, or
  -- + produce output using writeahead
  ---------------------------------------------------

  -- prepare our phrase-record buffer
  local clk = nil 
  if self.phrase_recording then
    clk = math.floor(os.clock() * 1000)
    if not self.phrase_recording_buffer[clk] then
      self.phrase_recording_buffer[clk] = table.create()
    end
  end

  local lines = patt.tracks[self.rns_track_idx]:lines_in_range(writepos.line,line_to)
  for i = 1,#lines do
    
    local line = lines[i]
    local line_idx = writepos.line+i-1
    local note_col = self:get_note_col(line)
    local fxcol_1 = line:effect_column(Mlrx_track.TRACK_FXCOL_SXX)
    local fxcol_2 = line:effect_column(Mlrx_track.TRACK_FXCOL_EXX)
    local fxcol_3 = line:effect_column(Mlrx_track.TRACK_FXCOL_CXX)

    writeahead = writeahead-1

    
    if do_wipe then 

      ---------------------------------------------------
      -- wipe inactive track in active group
      ---------------------------------------------------

      if (line_idx > playpos.line) or wraparound then
        --print("*** track_output - wipe @line",line_idx,"track index",self.rns_track_idx,"wraparound",wraparound,"playpos.line",playpos.line)
        self:smart_line_clear(rns_trk,note_col,fxcol_1,fxcol_2,fxcol_3)
        --line:clear()
      end


    elseif do_read then 

      if (readahead > 0) and not wraparound then

        ---------------------------------------------------
        -- read & display pattern data in inactive group
        ---------------------------------------------------

        --print("*** reading from @line",line_idx,"track index",self.rns_track_idx)

        if not note_col.is_empty and
          (rns_trk.mute_state ~= renoise.Track.MUTE_STATE_OFF)
        then

          local offset = nil

          -- check if the note match our track's instrument
          -- (we only want to display matching content)
          if ((note_col.instrument_value+1) == self.rns_instr_idx) then
            offset = 1 -- in case of no offset, this is correct
            --local fx_col_1 = line:effect_column(Mlrx_track.TRACK_FXCOL_SXX)
            --local fx_col_2 = line:effect_column(Mlrx_track.TRACK_FXCOL_EXX)
            if (fxcol_1.number_string == "0S") then
              offset = fxcol_1.amount_value
            elseif (fxcol_2.number_string == "0E") then
              offset = fxcol_2.amount_value
            end
          end

          if offset then
            local offset_total = Mlrx_track.MAX_OFFSETS
            local phrase = self:get_phrase_ref(note_col.note_value)
            if phrase then
              offset_total = phrase.number_of_lines
            elseif self.is_sliced then
              offset = offset - 1
              offset_total = self._num_triggers
            end
            offset = math.min(self._num_triggers,math.ceil((offset/offset_total)*self._num_triggers)+1)
            self.main:trigger_feedback(self.self_idx,offset)

          end

        end

        readahead = readahead-1

      end

    else

      ---------------------------------------------------
      -- process active track
      ---------------------------------------------------

      --print("self.note.startpos",self.note.startpos)
      --print("self.note.endpos",self.note.endpos)

      if self.note.repeatpos and (line_idx == self.note.repeatpos.line) and
        -- check if travelled "roughly" far enough for our repeat
        -- (otherwise, a 128-line repeat within a 64-line pattern wouldn't work)
        (self.note.travelled+self.writeahead*2 >= self.cycle_lines)
      then 

        -------------------------------
        -- output a repeated note 
        -------------------------------

        --print("*** output repeated note",line_idx,"track",self.rns_track_idx, "patt_idx",patt_idx)

        if self.note.repeatpos and not wraparound and
          (self.note.repeatpos.sequence ~= playpos.sequence) 
        then
          --print("sequence is not equal",self.note.repeatpos.sequence,playpos.sequence)
          -- this happens when we jump around the pattern sequence
          -- (align the note output with the playing sequence)
          self.note.repeatpos.sequence = playpos.sequence
        end

        self.note.written = self.note.repeatpos
        self:write_note(rns_trk,line_idx,note_col,fxcol_1,fxcol_2,fxcol_3)

        -- add to ignore list
        if (line_idx >= patt.number_of_lines) then
          local normalized_pos = Mlrx_pos(self.note.repeatpos)
          normalized_pos:normalize()
          self.note.ignore_lines:insert(normalized_pos)
          --print("*** insert into self.note.ignore_lines A ",normalized_pos)
        else
          self.note.ignore_lines:insert(self.note.repeatpos)
          --print("*** insert into self.note.ignore_lines B ",self.note.repeatpos)
        end
        --rprint(self.note.ignore_lines)
        self:schedule_repeat(self.note.repeatpos.sequence,line_idx,playpos)

      elseif self.note.startpos and 
        (line_idx == self.note.startpos.line) and
        not self.note.written
      then 

        -------------------------------
        -- output first note
        -------------------------------

        --print("*** output note for the first time",line_idx,", track",self.rns_track_idx)

        self:write_note(rns_trk,line_idx,note_col,fxcol_1,fxcol_2,fxcol_3,true)
        self.note.written = self.note.startpos
        self.note.ignore_lines:insert(self.note.startpos)
        self:schedule_repeat(writepos.sequence,line_idx,playpos)

      elseif not self.note.offed and
        self.note.endpos and
        (line_idx == self.note.endpos.line) 
      then 

        -------------------------------
        -- output note-off 
        -------------------------------

        
        -- in TOUCH mode, only output if a note does not already exist
        if (self.trig_mode == Mlrx_track.TRIG_TOUCH) and
          (note_col.note_value ~= renoise.PatternLine.EMPTY_NOTE)
        then
          -- do nothing
          --print("*** output note-off - leave existing note col intact",line_idx,note_col,"track",self.rns_track_idx)
        else
          --print("*** track_output -  note-off",line_idx,"track",self.rns_track_idx)
          self:smart_line_clear(rns_trk,note_col,fxcol_1,fxcol_2,fxcol_3)
          note_col.note_value = renoise.PatternLine.NOTE_OFF
        end

        self.note.offed = Mlrx_pos(writepos)
        self.note.offed.line = line_idx

      elseif self.note.startpos and 
        (not self.note.written or not self.note.active and 
        (self.note.startpos.sequence == writepos.sequence) and
        (self.note.startpos.line > line_idx))
      then

        -------------------------------
        -- wait for first note 
        -------------------------------

        --print("*** skip this line",line_idx,", track",self.rns_track_idx)

      elseif not self.note.offed and
        ((line_idx == 1) or 
        (line_idx > writepos.line))
      then 

        -------------------------------
        -- clear line
        -------------------------------

        --print("*** skip this line",line_idx,", track",self.rns_track_idx)
        local ignore = self.note:on_ignore_list(line_idx)
        --print("on ignore list",ignore)
        --rprint(self.note.ignore_lines)
        if not ignore then
          --print("*** clear line",line_idx,writepos,", track",self.rns_track_idx)
          if self.note.written or self.note.active then
            self:smart_line_clear(rns_trk,note_col,fxcol_1,fxcol_2,fxcol_3)
          end
        else
          --print("*** clear line (ignored)",line_idx,writepos,", track",self.rns_track_idx)
        end
  
      end



    end

    ---------------------------------------------------
    -- output track shuffle 
    ---------------------------------------------------
  
    if self.note and self.note.active or self.trk_latch_shuffle then
      if (self.shuffle_amount > 0) then
        self:output_shuffle(rns_trk,line_idx,note_col,fxcol_3)
      else
        note_col.delay_value = renoise.PatternLine.EMPTY_DELAY
      end
    end

    ---------------------------------------------------
    -- track mixer (continuous output once latched)
    ---------------------------------------------------

    if self.trk_latch_velocity then 
      note_col.volume_value = self.default_velocity and 
        renoise.PatternLine.EMPTY_VOLUME or 
          math.min(Mlrx.INT_7BIT,self.velocity+self.pressure)
      --print("*** track_output - note_col.volume_value",note_col.volume_value)

    end
    if self.trk_latch_panning then 
      note_col.panning_value = self.default_panning and 
        renoise.PatternLine.EMPTY_PANNING or self.panning
    end

    ---------------------------------------------------
    -- phrase recording
    ---------------------------------------------------

    if self.phrase_recording then
      self.phrase_recording_buffer[clk][line_idx] = tostring(line)
    end


  end -- / main loop

  ---------------------------------------------------
  -- track mixer (read & display)
  ---------------------------------------------------

  if on_idle then

    local read_automation = not rns.transport.edit_mode or not self.note
    --if not self.note then
    --  read_automation = true
    --end
      
    if read_automation then

      --print("*** read - track index",self.rns_track_idx,"playpos",playpos,"writepos",writepos)
      if (writepos.line == playpos.line) then
        local line = patt.tracks[self.rns_track_idx]:line(writepos.line)
        if not line.is_empty then
          local note_col = self:get_note_col(line)

          if not self.trk_latch_velocity then
            if (note_col.volume_value <= Mlrx.INT_7BIT) then
              self.velocity = note_col.volume_value 
            elseif (note_col.note_value < renoise.PatternLine.NOTE_OFF) and
              (note_col.volume_value == renoise.PatternLine.EMPTY_VOLUME) 
            then
              self.velocity = Mlrx_track.DEFAULT_VELOCITY
            end
            --print("*** track_output - read_automation",self.velocity)
            self.main:update_track_levels(self)
          end

          if not self.trk_latch_panning then
            if (note_col.panning_value <= Mlrx.INT_7BIT) then
              self.panning = note_col.panning_value 
            elseif (note_col.note_value < renoise.PatternLine.NOTE_OFF) and
              (note_col.panning_value == renoise.PatternLine.EMPTY_PANNING) 
            then
              self.panning = Mlrx_track.DEFAULT_PANNING
            end
            self.main:update_track_panning(self)
          end

          if not self.trk_latch_shuffle and 
            (note_col.delay_value ~= renoise.PatternLine.EMPTY_DELAY) 
          then
            self.shuffle_amount = note_col.delay_value
            self.main.track_shuffle_update_requested = true
          end

        end
      end

    end

  end -- / track mixer (read & display)

  ---------------------------------------------------
  -- detect note and travel length 
  ---------------------------------------------------

  if self.note and on_idle then

    -- check if playback has wrapped around in same pattern
    -- (and also, always initialize last_playpos)
    local repeated = false
    if self._last_playpos then
      repeated = (playpos < self._last_playpos)
    else
      self._last_playpos = playpos
    end

    if self.note.startpos then

      -- check if we have crossed the note-on point, and 
      -- measure how far a playing note might have travelled

      local position_lit = false

      if not self.note.active and self.note.written and
        (self.note.startpos.line <= playpos.line) and -- less than or equal to current position
        (self.note.startpos.line > playpos.line-self.writeahead) and -- within the 
        (self.note.startpos.sequence <= playpos.sequence) -- in current, or a previous pattern
      then
        self.note.active = true
        --print("*** track_output -  the sound was detected as active @playpos",playpos,", track",self.rns_track_idx)
        self:light_position(1)
        position_lit = true
      end

      if self.note.active then


        if not self.note.travelled then
          -- initialize the travel distance 
          --print("initialize the travel distance!")
          self.note.travelled = playpos.line - self.note.startpos.line
        else

          --if not self.note.travelled_total then
          --  self.note.travelled_total = 0
          --end

          local count_remaining = false
          if (self._last_playpos.sequence == playpos.sequence) then
            if not repeated then
              local diff = playpos.line - self._last_playpos.line
              --print("counted line difference",diff)
              self.note.travelled = self.note.travelled + diff
              --self.note.travelled_total = self.note.travelled_total + diff
            else -- repeated
              count_remaining = true
            end
          else -- next (or first) pattern
            count_remaining = true
          end

          if count_remaining then
            -- when crossing a pattern boundary, count lines in old pattern
            if not (playpos == self._last_playpos) then
              local diff = Mlrx:get_pos_diff(self._last_playpos,playpos)
              --print("counted line difference",diff)
              self.note.travelled = self.note.travelled + diff
              --self.note.travelled_total = self.note.travelled_total + diff
            end  

          end

          --print("*** track_output - travelled",self.note.travelled,"travelled_total",self.note.travelled_total,"wraparound",wraparound)
          if not wraparound and not position_lit then
            self:light_position(self.note.travelled)
          end


        end


      end

    end

    if self.note.endpos and self.note.offed then
    --if not wraparound and self.note.endpos and self.note.offed then
      --print("*** track_output - self.note.written",repeated,"repeated",self.note.written,"self.note.offed",self.note.offed,"self.note.endpos",self.note.endpos,"playpos",playpos)

      -- playback has continued past the endpos of the sound? 
      -- nullify notes that match this description


      local passed_note_off = false

      -- when a note-off was inserted at the top of a pattern 
      -- as the result of releasing a trigger near the bottom
      local spanning_boundary = false
      if self.note.written then
        spanning_boundary = (self.note.offed.line < self.note.written.line) and
        (math.abs(self.note.written.line - self.note.offed.line) > self.writeahead*2)
      end
      --print("spanning_boundary",spanning_boundary)

      -- we can't have passed the noteoff if playpos is less than offed 
      -- however, offset might have been inserted into top of pattern?
      if spanning_boundary and 
        (playpos.line > self.note.offed.line)
      then
        passed_note_off = false
        --print("passed_note_off B",passed_note_off)
      else

        -- simple check for note-off: we are inside the same pattern,
        -- and playpos is equal to, or greater than endpos
        --local passed_note_off = not repeated and 
        passed_note_off = (self.note.endpos.sequence == playpos.sequence) and 
          (self.note.endpos.line <= playpos.line)
        --print("passed_note_off A",passed_note_off)

        -- another check: we are at the top of a pattern,
        -- with the endpos being greater than our playpos
        local wrapped_around = repeated and (self.note.endpos.line > playpos.line)
        --print("wrapped_around",wrapped_around)

        passed_note_off = (passed_note_off or wrapped_around)
        --print("passed_note_off C",passed_note_off)

      end

      if passed_note_off then

        -- do some advanced clearing of notes (iterating through lines
        -- that might have been written ahead of our current position)

        local do_clear = true
        local clear_pos = nil

        if self.note.written then
          --print("*** track_output - nullify note, self.note.written",self.note.written,"self.note.offed",self.note.offed,"playpos",playpos,"wraparound",wraparound)
          if spanning_boundary then 
            do_clear = false
          else
            if (self.note.written < playpos) then
              clear_pos = Mlrx_pos(self.note.offed)
              --print("clear_pos A",clear_pos)
            else
              clear_pos = Mlrx_pos(self.note.written)
              --print("clear_pos B",clear_pos)
            end
          end
        else
          -- inactive tracks
          clear_pos = Mlrx_pos(self.note.offed)
          --print("clear_pos C",clear_pos)
        end

        --print("*** track_output - nullify note, do_clear",do_clear)

        if do_clear then

          clear_pos.line = clear_pos.line + math.max(1,math.floor(self.writeahead))
          clear_pos:normalize()

          --print("clear_pos D",clear_pos)

          -- be careful in touch mode (clear as little as possible)
          local leave_existing = false
          if self.note.written and 
            (self.trig_mode == Mlrx_track.TRIG_TOUCH) 
          then
            leave_existing = true
          end

          local tmp_pos = Mlrx_pos(self.note.offed)
          --print("*** track_output - nullify note, advanced clearing from/to",tmp_pos,clear_pos)
          while (tmp_pos ~= clear_pos) do
          --while (tmp_pos.sequence ~= clear_pos.sequence) or
          --  (tmp_pos < clear_pos) 
          --do
            tmp_pos.line = tmp_pos.line+1
            tmp_pos:normalize()

            --print("*** track_output - nullify note, tmp_pos",tmp_pos)

            -- pattern _might_ have changed, line certainly has:
            local tmp_patt_idx = rns.sequencer.pattern_sequence[tmp_pos.sequence]
            local tmp_patt = rns:pattern(tmp_patt_idx)
            local tmp_line = tmp_patt.tracks[self.rns_track_idx]:line(tmp_pos.line)
            local note_col = self:get_note_col(tmp_line)
            if leave_existing and 
              (tmp_pos > self.note.written) and
              (note_col.note_value ~= renoise.PatternLine.EMPTY_NOTE)
            then
              --print("*** nullify - leave existing note intact",tmp_pos.line,note_col)
              break
            else
              --print("*** nullify - clear this line",tmp_pos.line,note_col)
              --note_col:clear()
              local fxcol_1 = tmp_line:effect_column(Mlrx_track.TRACK_FXCOL_SXX)
              local fxcol_2 = tmp_line:effect_column(Mlrx_track.TRACK_FXCOL_EXX)
              local fxcol_3 = tmp_line:effect_column(Mlrx_track.TRACK_FXCOL_CXX)
              self:smart_line_clear(rns_trk,note_col,fxcol_1,fxcol_2,fxcol_3)
              note_col.note_value = renoise.PatternLine.NOTE_OFF
            end


          end
        end

        --print("*** track_output - nullify note with endpos",self.note.endpos,"self.self_idx",self.self_idx)

        self.note = nil
        self.main:update_trigger_pos(self.self_idx) -- clear the light

      end
    end

    -- purge the ignore list 
    if self.note and not table.is_empty(self.note.ignore_lines) then
      -- check if we are close enough to the end of the pattern to have wrapped
      --local wrapped = (playpos.line >= patt.number_of_lines) 
      local wrapped = (playpos.line+self.writeahead > patt.number_of_lines) 
      if not wraparound then -- ignore when writing into a different pattern
        for i,v in ipairs(self.note.ignore_lines) do
          if (v < playpos) then
            if wrapped and (playpos.line-self.writeahead*2 > v.line) then
              --print("ignore early positions as a result of wrapping",v)
            else
              self.note.ignore_lines:remove(i)
              --print("purge from self.note.ignore_lines",v)
            end
          elseif repeated and (v.line > (playpos.line+self.writeahead)) then
            --print("purge late repeatpos",v)
            self.note.ignore_lines:remove(i)
          end
        end

      end
      --print("post-purge ignore_lines")
      --rprint(self.note.ignore_lines)
    end


    self._last_playpos = playpos


  end -- / detect note and travel length

  ---------------------------------------------------
  -- when we exceeded the pattern boundary,
  -- call function again with new writepos
  ---------------------------------------------------

  if exceeded then 
    local wrap_pos = Mlrx_pos(writepos)
    wrap_pos.line = patt.number_of_lines+1
    wrap_pos:normalize()
    wraparound = true
    self:track_output(wrap_pos,exceeded_by,wraparound,on_idle)
  end

end

--------------------------------------------------------------------------------


function Mlrx_track:slice_mode_changed()
  TRACE("Mlrx_track:slice_mode_changed()")

  local sample = self.instr.samples[1]
  local is_sliced = (#sample.slice_markers > 0)
  --print("*** slice_mode_changed - is_sliced",is_sliced)
  --print("*** slice_mode_changed - self.is_sliced",self.is_sliced)
  --print("*** slice_mode_changed - #sample.slice_markers",#sample.slice_markers)

  self.is_sliced = (#sample.slice_markers > 0)
  self.note_pitch = sample.sample_mapping.base_note
  if self.is_sliced then
    if not rawequal(sample,self.sample) then
      self:attach_to_sample()
    end
  end
  self.main:update_sound_source()

end

--------------------------------------------------------------------------------

-- remove provided notifier, checking if it's already defined

function Mlrx_track:remove_notifier(obs,fn)
  --TRACE("Mlrx:remove_notifier",obs,fn)

  if obs:has_notifier(fn) then 
    obs:remove_notifier(fn) 
  end

end

--------------------------------------------------------------------------------

-- function for removing attached notifiers using 'brute force'
-- (do this for notifiers that might not exist)

function Mlrx_track:remove_notifiers(observables)
  --TRACE("Mlrx:remove_notifiers",observables)

  if not observables then
    return
  end
  
  for _,obs in ipairs(observables) do
    pcall(function() obs[1]:remove_notifier(obs[2]) end)
  end

end

--------------------------------------------------------------------------------

-- attach to phrase as indicated by note_pitch 

function Mlrx_track:attach_to_phrase()
  TRACE("Mlrx_track:attach_to_phrase")

  local phrase,phrase_index = self:get_phrase_ref(self.note_pitch)
  self.phrase = phrase
  --print("*** attach_to_phrase - self.phrase",self.phrase,"self.note_pitch",self.note_pitch)

  if not self.phrase then
    return
  end

  -- now attach notifiers

  local obs,fn = nil,nil
  self._phrase_observables = table.create()

  fn = function(param)
    TRACE("Mlrx_track:phrase.number_of_lines_observable fired...")
    self:set_transpose_task(0)
  end
  obs = self.phrase.number_of_lines_observable
  obs:add_notifier(fn)
  self._phrase_observables:insert({obs,fn})

  fn = function(param)
    TRACE("Mlrx_track:phrase.lpb_observable fired...")
    self:set_transpose_task(0)
    self.main:update_linesync(self)
  end
  obs = self.phrase.lpb_observable
  obs:add_notifier(fn)
  self._phrase_observables:insert({obs,fn})



end

--------------------------------------------------------------------------------

-- observe changes to track panning, velocity 
-- (used for displaying recorded automation envelopes)

function Mlrx_track:attach_to_track()
  TRACE("Mlrx_track:attach_to_track()")

  self:remove_notifiers(self._track_observables)
  self._track_observables = table.create()

  local rns_trk = rns.tracks[self.rns_track_idx]
  --print("*** attach_to_track - rns_trk",rns_trk)

  if not rns_trk then
    --print("*** attach_to_track - cannot attach to this track, it does not exist",self.rns_track_idx)
    return
  end

  local obs,fn = nil,nil

  local param = rns_trk.prefx_panning
  fn = function()
    --TRACE("Mlrx_track:prefx_panning_observable fired...")
    self.group.panning = param.value * Mlrx.INT_8BIT
    self.main.group_panning_update_requested = true
  end
  obs = param.value_observable
  obs:add_notifier(fn)
  self._track_observables:insert({obs,fn})

  local param = rns_trk.prefx_volume
  fn = function()
    --TRACE("Mlrx_track:prefx_volume_observable fired...",param.value)
    self.group.velocity = (param.value/RENOISE_DECIBEL) * Mlrx.INT_8BIT
    --print("self.group.velocity",self.group.velocity)
    self.main.group_level_update_requested = true
  end
  obs = param.value_observable
  obs:add_notifier(fn)
  self._track_observables:insert({obs,fn})


end

--------------------------------------------------------------------------------

-- listen for changes to sample transpose / beat-sync
-- NB: don't forget to remove existing notifiers!

function Mlrx_track:attach_to_sample()
  TRACE("Mlrx_track:attach_to_sample")

  local sample,sample_index = self:get_sample_ref(self.note_pitch)
  self.sample = sample
  --print("*** self.note_pitch",self.note_pitch)
  --print("*** self.sample",self.sample)

  if not self.sample then
    return
  end


  self.is_sliced = self.sample.sample_mapping.read_only
  
  --print("*** self.is_sliced",self.is_sliced)
  --print("*** self.note_pitch",self.note_pitch)

  local obs,fn = nil,nil
  self._sample_observables = table.create()

  fn = function()
    TRACE("Mlrx_track:sample.transpose_observable fired...")
    self:set_transpose_task(0)  
  end
  obs = self.sample.transpose_observable
  obs:add_notifier(fn)
  self._sample_observables:insert({obs,fn})

  fn = function()
    TRACE("Mlrx_track:sample.fine_tune_observable fired...")
    self:set_transpose_task(0)  
  end
  obs = self.sample.fine_tune_observable
  obs:add_notifier(fn)
  self._sample_observables:insert({obs,fn})

  fn = function(param)
    TRACE("Mlrx_track:sample.slice_markers_observable fired...",param)
    -- (workaround for a small issue with the scripting API: 
    -- called with a slight delay, as it seems that the number of 
    -- slice markers can be reported incorrectly when first set)
    self.main.display.scheduler:remove_task(self._slice_mode_task)
    self._slice_mode_task = self.main.display.scheduler:add_task(
      self, Mlrx_track.slice_mode_changed, 0.2)
  end
  obs = self.sample.slice_markers_observable
  obs:add_notifier(fn)
  self._sample_observables:insert({obs,fn})

  fn = function(param)
    TRACE("Mlrx_track:sample.sample_buffer_observable fired...",param)
    -- this can be an indicator for when samples have started loading...
    self:set_transpose_task(0)  
  end
  obs = self.sample.sample_buffer_observable
  obs:add_notifier(fn)
  self._sample_observables:insert({obs,fn})

  -- named notifiers (as they are attached, detached on the fly)

  fn = function(param)
    TRACE("Mlrx_track:sample.beat_sync_lines_observable fired...",param)
    self:update_summary_task()
  end
  obs = self.sample.beat_sync_lines_observable
  obs:add_notifier(fn)
  self._sample_observables:insert({obs,fn})
  self.beat_sync_lines_notifier = fn

  --print("has notifier: self.beat_sync_lines_notifier",obs:has_notifier(self.beat_sync_lines_notifier))

  fn = function(param)
    TRACE("Mlrx_track:sample.beat_sync_enabled_observable fired...",param)
    self:set_transpose_task(0)  
    self.main:update_linesync(self)
  end
  obs = self.sample.beat_sync_enabled_observable
  obs:add_notifier(fn)
  self._sample_observables:insert({obs,fn})
  self.beat_sync_enabled_notifier = fn

  fn = function(param)
    TRACE("Mlrx_track:sample.loop_mode_observable fired...",param,self.sample.loop_mode)
    -- if enabled, remember this value
    if (self.sample.loop_mode ~= renoise.Sample.LOOP_MODE_OFF) then
      self._cached_loop_mode = self.sample.loop_mode 
    end
    self.main:update_toggle_loop(self)

    -- can be an indicator for when a new sample has arrived
    self:prepare_sample_task()
  end
  obs = self.sample.loop_mode_observable
  obs:add_notifier(fn)
  self._sample_observables:insert({obs,fn})
  self.loop_mode_notifier = fn


end


--------------------------------------------------------------------------------

-- call this function to attach to an instrument (and the sample/phrase within)

function Mlrx_track:attach_to_instr_task()
  self.main.display.scheduler:remove_task(self._attach_to_instr_task)
  self._attach_to_instr_task = self.main.display.scheduler:add_task(
    self, Mlrx_track.attach_to_instr, 0.1)
end

-- @param first_run (bool), this is set when starting up:
--  + attach to instruments, but skip the transpose part
--  + take initial voiceprint of samples

function Mlrx_track:attach_to_instr(first_run)
  TRACE("Mlrx_track:attach_to_instr(first_run)",first_run)

  self:remove_notifiers(self._phrase_observables)
  self:remove_notifiers(self._sample_observables)
  self:remove_notifiers(self._instr_observables)

  -- reset properties that can always be determined
  -- by looking at the instrument itself 
  self.sample = nil
  self.phrase = nil
  self.is_sliced = nil
  self.sync_to_lines = nil
  -- self.cycle_lines = nil
  -- self.note_pitch = nil

  -- attach to instrument only when there is something to attach to
  self.instr = rns.instruments[self.rns_instr_idx]

  local has_phrases,has_samples = nil,nil
  if self.instr then
    has_phrases = self.instr.phrase_playback_enabled and 
      not table.is_empty(self.instr.phrases)
    has_samples = not table.is_empty(self.instr.samples)
  else
    return
  end

  --print("*** attach_to_instr - self.instr",self.instr)
  --print("*** attach_to_instr - has_phrases",has_phrases)
  --print("*** attach_to_instr - has_samples",has_samples)

  -- now attach notifiers

  local obs,fn = nil,nil
  self._instr_observables = table.create()

  fn = function(param)
    TRACE("Mlrx_track:instr.phrases_observable fired...")
    -- phrases might have gone entirely, or appeared for the first time
    self:attach_to_instr_task()
  end
  obs = self.instr.phrases_observable
  obs:add_notifier(fn)
  self._instr_observables:insert({obs,fn})

  fn = function(param)
    TRACE("Mlrx_track:instr.phrase_playback_enabled_observable fired...")


    self:attach_to_instr_task()
  end
  obs = self.instr.phrase_playback_enabled_observable
  obs:add_notifier(fn)
  self._instr_observables:insert({obs,fn})

  fn = function(param)
    TRACE("Mlrx_track:instr.samples_observable fired...",param)
    -- figure out if it was our sample that got nicked
    local sample_matched = nil
    for k,v in ipairs(self.instr.samples) do
      if rawequal(v,self.sample) then
        sample_matched = k
        break
      end
    end
    if sample_matched then
      self.sample = self.instr.samples[sample_matched]
      if self:sample_has_changed() then
        self:attach_to_instr_task()
      end
    else
      self.sample = nil
    end

    --print("*** sample_matched",sample_matched)
    --print("*** self.sample",self.sample)

  end
  obs = self.instr.samples_observable
  obs:add_notifier(fn)
  self._instr_observables:insert({obs,fn})

  fn = function(param)
    TRACE("Mlrx_track:instr.name_observable fired...")
    local sample = self:get_sample_ref(self.note_pitch)
    if self.sample then
      -- detect if a new sample has been loaded
      if self:sample_has_changed() then
        self:attach_to_instr_task()
      end
    else
      -- sample was deleted, or instrument cleared
      self:attach_to_instr_task()
    end
    self:decorate_track_task()
  end
  obs = self.instr.name_observable
  obs:add_notifier(fn)
  self._instr_observables:insert({obs,fn})

  -- handle when keyzone mappings are moved around, resized
  for k,v in ipairs(self.instr.samples) do
    fn = function()
      TRACE("Mlrx_track:sample.sample_mapping.note_range_observable fired...")
      if self.phrase then 
        return
      end
      for k2,v2 in ipairs(self.instr.samples) do
        if not self.sample and rawequal(v,v2) then
          self:attach_to_sample()
        end
        if rawequal(v,v2) and rawequal(v,self.sample) then
          self:set_transpose_task(0)
          self.main:update_linesync(self)
        end
      end
    end
    obs = v.sample_mapping.note_range_observable
    obs:add_notifier(fn)
    self._instr_observables:insert({obs,fn})
  end

  -- handle when phrase mappings are moved around, resized
  for k,v in ipairs(self.instr.phrases) do
    fn = function(param)
      TRACE("Mlrx_track:phrase.mapping.note_range_observable fired...",param)
      for k2,v2 in ipairs(self.instr.phrases) do
        if rawequal(v,v2) and not self.phrase then
          self:attach_to_phrase()
        end
        if rawequal(v,v2) and rawequal(v,self.phrase) then
          self:set_transpose_task(0)
          self.main:update_linesync(self)
        end
      end
    end
    obs = v.mapping.note_range_observable
    obs:add_notifier(fn)
    self._instr_observables:insert({obs,fn})
  end

  --print("*** self.instr.phrase_playback_enabled",self.instr.phrase_playback_enabled)

  if has_phrases then   
    self:attach_to_phrase()
  end
  if has_samples then
    self:attach_to_sample()
  end
  if not has_phrases and not has_samples then
    -- no content, make sure light is cleared
    self.note = nil
    self.main:update_trigger_pos(self.self_idx) 
  end

  --print("*** attach_to_instr - self.phrase",self.phrase)
  --print("*** attach_to_instr - self.sample",self.sample)

  -- label the beat-sync button
  self.main:update_linesync(self)

  if not self.note_pitch then
    self.note_pitch = Mlrx_track.MIDDLE_C
  end

  if first_run then
    -- take initial fingerprint
    self:sample_has_changed()
  end

  -- update sync_to_lines/note_pitch 
  self:set_transpose(0)

  if has_samples then
    self:prepare_sample()
  end

  self.main:update_track_task()

end

--------------------------------------------------------------------------------

-- when multiple note columns are present, leave Sxx & Exx alone
-- (this is invoked from active track in main loop)

function Mlrx_track:smart_line_clear(rns_trk,note_col,fxcol_1,fxcol_2,fxcol_3)

  if (rns_trk.visible_note_columns == 1) then
    if self.do_note_output then
      note_col:clear()
    end
    if self.do_sxx_output then
      fxcol_1:clear()
    end
    if self.do_exx_output then
      fxcol_2:clear()
    end
    fxcol_3:clear()
  else
    if self.do_note_output then
      note_col:clear()
    end
  end

end

--------------------------------------------------------------------------------

-- obtain reference to the current note column 

function Mlrx_track:get_note_col(line)

  local rns_trk = rns.tracks[self.rns_track_idx]
  if not self.note_col_idx or (
    rawequal(rns_trk,rns.selected_track) and
    (rns.selected_note_column_index > 0))
  then
    -- if currently selected in Renoise, remember position
    self.note_col_idx = rns.selected_note_column_index
    --print("*** get_note_col - self.note_col_idx",self.note_col_idx)
  end

  if not self.note_col_idx or (self.note_col_idx == 0) then
    self.note_col_idx = 1 -- fallback
  end

  return line:note_column(self.note_col_idx)

end

--------------------------------------------------------------------------------

function Mlrx_track:note_in_range(note,rng)
  return (note >= rng[1]) and (note <= rng[2])
end

--------------------------------------------------------------------------------

-- obtain reference to the active sample in the instrument
-- @return renoise.Sample,sample_index or nil if not found

function Mlrx_track:get_sample_ref(note)
  TRACE("Mlrx_track:get_sample_ref(note)",note)

  if not self.instr then
    return
  end

  for k,v in ipairs(self.instr.samples) do
    if self:note_in_range(note,v.sample_mapping.note_range) then
      return v,k
    end
  end

end

--------------------------------------------------------------------------------

-- obtain reference to the phrase indicated by the note
-- @return renoise.InstrumentPhrase,phrase_index or nil if not found

function Mlrx_track:get_phrase_ref(note)
  TRACE("Mlrx_track:get_phrase_ref(note)",note)

  for k,v in ipairs(self.instr.phrase_mappings) do
    if self:note_in_range(note,v.note_range) then
      return v.phrase,k
    end
  end


end


--------------------------------------------------------------------------------

-- figure out how many lines the sample would play for, if played back in 
-- it's original pitch and with the currently specified tempo
-- @return Int, number of lines or nil

function Mlrx_track:obtain_sample_lines(tempo_factor)
  TRACE("Mlrx_track:obtain_sample_lines(tempo_factor)",tempo_factor)

  local slines = nil 
  if not tempo_factor then
    tempo_factor = 1
  end

  if self.sample.sample_buffer.has_sample_data then
    local sframes = self.sample.sample_buffer.number_of_frames
    local srate = self.sample.sample_buffer.sample_rate
    local lines_per_sec = (rns.transport.bpm * rns.transport.lpb)/60
    slines = lines_per_sec * ((sframes/srate)/tempo_factor)
  end

  return slines

end

--------------------------------------------------------------------------------

-- beat-synced sample playback: restrict to predefined values
-- @param val (int), the transpose direction - e.g. -2 for two 'steps' down

function Mlrx_track:get_restricted_beat_sync(val)
  TRACE("Mlrx_track:get_restricted_beat_sync(val)",val)

  local tmp = nil
  for i,num_lines in ipairs(Mlrx_track.BEAT_SYNC_LINES) do
    if (Mlrx_track.BEAT_SYNC_LINES[i]>=self.sync_to_lines) then
      tmp = i
      break
    end
  end
  return Mlrx_track.BEAT_SYNC_LINES[math.max(1,math.min(32,tmp + val))]

end

--------------------------------------------------------------------------------

function Mlrx_track:set_sxx_output(val)
  TRACE("Mlrx_track:set_sxx_output(val)",val,type(val))

  self.do_sxx_output = val

  if self.do_sxx_output then
    local rns_trk = rns.tracks[self.rns_track_idx]
    if rns_trk and (rns_trk.visible_effect_columns < Mlrx_track.TRACK_FXCOL_SXX) then
      rns_trk.visible_effect_columns = Mlrx_track.TRACK_FXCOL_SXX
    end
  end

  self.main.initiate_settings_requested = true
  self.main:update_output_filter()

end

--------------------------------------------------------------------------------

function Mlrx_track:toggle_sxx_output()
  TRACE("Mlrx_track:toggle_sxx_output()")

  self:set_sxx_output(not self.do_sxx_output)

end

--------------------------------------------------------------------------------

function Mlrx_track:set_note_output(val)
  TRACE("Mlrx_track:toggle_note_output(val)",val)

  self.do_note_output = val
  self.main.initiate_settings_requested = true
  self.main:update_output_filter()

end

--------------------------------------------------------------------------------

function Mlrx_track:toggle_note_output()
  TRACE("Mlrx_track:toggle_note_output()")

  self:set_note_output(not self.do_note_output)

end

--------------------------------------------------------------------------------

function Mlrx_track:set_exx_output(val)
  TRACE("Mlrx_track:set_exx_output(val)",val,type(val))

  self.do_exx_output = val

  if self.do_exx_output then
    local rns_trk = rns.tracks[self.rns_track_idx]
    if rns_trk and (rns_trk.visible_effect_columns < Mlrx_track.TRACK_FXCOL_EXX) then
      rns_trk.visible_effect_columns = Mlrx_track.TRACK_FXCOL_EXX
    end
  end

  self.main.initiate_settings_requested = true
  self.main:update_output_filter()

end

--------------------------------------------------------------------------------

function Mlrx_track:toggle_exx_output()
  TRACE("Mlrx_track:toggle_exx_output()")

  self:set_exx_output(not self.do_exx_output)

end

--------------------------------------------------------------------------------

-- toggle the loop of the current sample 

function Mlrx_track:toggle_loop()
  TRACE("Mlrx_track:toggle_loop()")

  if self.sample then

    if (self.sample.loop_mode == renoise.Sample.LOOP_MODE_OFF) then
      -- enable, default to forward looping
      if not self._cached_loop_mode then
        self._cached_loop_mode = renoise.Sample.LOOP_MODE_FORWARD
      end
      self.sample.loop_mode = self._cached_loop_mode
    
    else
      self.sample.loop_mode = renoise.Sample.LOOP_MODE_OFF
    end

  end

end

--------------------------------------------------------------------------------

-- toggle the beat-sync of the current sample (ignore when using phrase)

function Mlrx_track:toggle_sync()
  TRACE("Mlrx_track:toggle_sync()")

  --print("*** toggle_sync - self.sample",self.sample)
  if not self.sample then
    return
  end

  --print("*** toggle_sync - self.phrase",self.phrase)
  if self.phrase and self.instr.phrase_playback_enabled then
    return
  end
  
  --print("*** toggle_sync - got here?")
  self.sample.beat_sync_enabled = not self.sample.beat_sync_enabled

end

--------------------------------------------------------------------------------

-- when not sliced, create a slice for each trigger button
-- when sliced, check if these were manually created before removing
-- @param force (bool) when button was held

function Mlrx_track:toggle_slicing(force)
  TRACE("Mlrx_track:toggle_slicing(force)",force)

  if not self.sample then 
    return
  end

  local function get_slice_offset(idx,div)
    return math.floor((idx-1)*div+1)
  end

  local function is_evenly_sliced()
    if (#self.sample.slice_markers ~= self._num_triggers) then
      return false -- slice count is wrong
    end
    local div = self.sample.sample_buffer.number_of_frames / self._num_triggers
    for i = 1, self._num_triggers do
      --print("*** is_evenly_sliced - slice#",i,self.sample.slice_markers[i],(i-1)*div+1)
      if (self.sample.slice_markers[i] ~= get_slice_offset(i,div)) then
        return false
      end
      --print("*** is_evenly_sliced - passed check of slice#",i)
    end
    return true
  end

  if self.is_sliced then
    if not force and not is_evenly_sliced() then
      local msg = "Message from mlrx: it seems the slice markers have been manually edited. "
                    .."To remove them anyway, press and hold the SLICE button"
      renoise.app():show_status(msg)
    else
      -- remove existing slices
      for i, m in ipairs(self.sample.slice_markers) do
        self.sample:delete_slice_marker(m)
      end
    end
  else -- not sliced
    if not force then
      local msg = "Message from mlrx: press and hold the SLICE button to "
                    .."slice this sample automatically"
      renoise.app():show_status(msg)
    else 
      -- create evenly distributed slices
      local div = self.sample.sample_buffer.number_of_frames / self._num_triggers
      for i = 1, self._num_triggers do
        self.sample:insert_slice_marker(get_slice_offset(i,div))
      end
    end
  end

end

--------------------------------------------------------------------------------

--- "record arm" a track - initiate recording once a note is triggered

function Mlrx_track:prepare_phrase_recording()

  if self.note and self.note.active then
    self:start_phrase_recording()
  else
    self.phrase_record_armed = true
  end

end

--------------------------------------------------------------------------------

--- start recording all output into a buffer

function Mlrx_track:start_phrase_recording()
  TRACE("Mlrx_track:start_phrase_recording()")

  self.phrase_record_armed = false
  self.phrase_recording = true
  self.phrase_recording_buffer = {}

end

--------------------------------------------------------------------------------

--- finalize a phrase recording
-- 1. allocate a new, single-note phrase to hold the recording
-- 2. parse the recorded data into this phrase (via coroutine)

function Mlrx_track:stop_phrase_recording()
  TRACE("Mlrx_track:stop_phrase_recording()")

  self.phrase_recording = false

  local target_phrase = self:allocate_phrase()
  --print("*** stop_phrase_recording - target_phrase",target_phrase)
  if not target_phrase then
    local msg = "Message from mlrx: could not allocate a target phrase (no more room left?)..."
    renoise.app():show_status(msg)
    return
  end

  local parse_phrase_recording = function ()

    local line_offset = nil
    local highest_line_idx = nil
    local target_line_idx = nil
    local wraparound = false
    local patt_num_lines = nil
    local patt_num_lines_total = 0
    local recording_length = nil

    local entry_keys = table.keys(self.phrase_recording_buffer)
    table.sort(entry_keys)

    for k,clk in ipairs(entry_keys) do

      local entry = self.phrase_recording_buffer[clk]

      local line_idxs = table.keys(entry)
      table.sort(line_idxs)

      for _,line_idx in pairs(line_idxs) do

        local line = entry[line_idx]
        local add_note = true
        --print("*** line_idx,line",line_idx,line)

        if not line_offset then
          -- the first line index becomes line 1 in the phrase
          line_offset = line_idx
          highest_line_idx = line_idx
          --print("*** stop_phrase_recording - line_offset",line_offset)
        elseif (line_idx <= self.writeahead) then
          -- check if this is a pattern that wrapped around 
          -- (only flag on second, third etc. loop)
          if (highest_line_idx > (self.writeahead*2)) then
            --print("*** stop_phrase_recording - pattern wrapped around",line_idx,"highest_line_idx",highest_line_idx)
            patt_num_lines = highest_line_idx
            -- increase pattern line-count only once! 
            if not wraparound then
              patt_num_lines_total = patt_num_lines_total + patt_num_lines
            end
            wraparound = true
          end

        elseif wraparound and 
          (line_idx > self.writeahead*2) and -- somewhat into the pattern
          (line_idx < (patt_num_lines-self.writeahead)) -- and away from the end
        then
          -- escaped the wraparound point
          patt_num_lines = nil
          wraparound = false
          --print("*** stop_phrase_recording - escaped the wraparound point",line_idx)
        elseif wraparound and
          (line_idx >= (patt_num_lines-self.writeahead))
        then
          --print("*** stop_phrase_recording - ignore lines from previous pattern once wrapped")
          add_note = false
        else
          --print("*** stop_phrase_recording - got here")
          highest_line_idx = math.max(highest_line_idx,line_idx)
        end

        if add_note then
          target_line_idx = patt_num_lines_total - line_offset + line_idx
          if (target_line_idx > 0) and -- skip first line and cap at 512
            (target_line_idx <= renoise.Pattern.MAX_NUMBER_OF_LINES) 
          then
            local target_line = target_phrase:line(target_line_idx)
            self:deserialize_line(line,target_line)
          end
          recording_length = target_line_idx
        end

      end

      -- show the progress in the status bar
      local msg = "Message from mlrx: processing recorded sequence...%d%% done"
      msg = string.format(msg,math.floor((k/#entry_keys)*100))
      renoise.app():show_status(msg)

      -- give time back to renoise
      coroutine.yield()

    end

    if recording_length then

      -- quantize the resulting number of lines (remember, output is always
      -- written ahead of time, so we can potentially choose to drop some lines)
      local lines_quant = math.ceil((recording_length-self.writeahead)/self.main._quantize)*self.main._quantize
      lines_quant = math.max(self.main._quantize,lines_quant)

      target_phrase.number_of_lines = math.min(lines_quant,renoise.Pattern.MAX_NUMBER_OF_LINES)
      self:sync_track_props(rns.tracks[self.rns_track_idx],target_phrase)

      -- output status message 
      local msg = nil
      if (recording_length > renoise.Pattern.MAX_NUMBER_OF_LINES) then
        -- warn when lines were dropped
        msg = "Message from mlrx: the recorded phrase has a duration of %d lines, "
            .."but phrases can only contain 512 lines or less (%d lines were dropped)"
        msg = string.format(msg,recording_length,recording_length-renoise.Pattern.MAX_NUMBER_OF_LINES)
      else
        msg = "Message from mlrx: a new phrase has been added to the instrument (length: %d lines)"
        msg = string.format(msg,target_phrase.number_of_lines)
      end

      renoise.app():show_status(msg)

    end

  end

  self.process_slicer = ProcessSlicer(parse_phrase_recording)
  self.process_slicer:start()

end

--------------------------------------------------------------------------------

--- this method is the opposite of PatternLine.toString()

function Mlrx_track:deserialize_line(str_ln,target_line)

  local max_note_cols = renoise.InstrumentPhrase.MAX_NUMBER_OF_NOTE_COLUMNS
  local count = 1
  local matches = string.gmatch(str_ln,"([^\|]*)|%s?")
  for k in matches do
    if (count <= max_note_cols) then
      local note_col = target_line:note_column(count)
      note_col.note_string = string.sub(k,1,3)
      note_col.instrument_string = string.sub(k,4,5)
      note_col.volume_string = string.sub(k,6,7)
      note_col.panning_string = string.sub(k,8,9)
      note_col.delay_string = string.sub(k,10,11)
    else
      local fx_col = target_line:effect_column(count-max_note_cols)
      fx_col.number_string = string.sub(k,1,2)
      fx_col.amount_string = string.sub(k,3,4)
    end 
    count = count + 1
  end

end

--------------------------------------------------------------------------------

--- capture a phrase from the currently selected pattern-track

function Mlrx_track:capture_phrase()
  TRACE("Mlrx_track:capture_phrase()")

  local patt = rns.selected_pattern
  local track = rns.tracks[self.rns_track_idx]
  local patt_track = patt.tracks[self.rns_track_idx]
  if patt_track then

    local target_phrase = self:allocate_phrase()
    --print("*** capture_phrase - target_phrase",target_phrase)
    if not target_phrase then
      local msg = "Message from mlrx: could not allocate a target phrase (no more room left?)..."
      renoise.app():show_status(msg)
      return
    end

    for k,v in ipairs(patt_track:lines_in_range(1,patt.number_of_lines)) do
      target_phrase:line(k):copy_from(v)
    end

    target_phrase.number_of_lines = patt.number_of_lines
    self:sync_track_props(track,target_phrase)
    self:select_phrase(target_phrase)

    local msg = "Message from mlrx: instrument phrase was succesfully captured (length: %d lines)"
    msg = string.format(msg,target_phrase.number_of_lines)
    renoise.app():show_status(msg)

  end

end

--------------------------------------------------------------------------------

--- activate, select & transpose into phrase 

function Mlrx_track:select_phrase(phrase)

  self.instr.phrase_playback_enabled = true
  if rawequal(self.instr,rns.selected_instrument) then
    rns.selected_phrase_index = #self.instr.phrases
  end
  self.note_pitch = phrase.mapping.base_note
  self:set_transpose(0)

end

--------------------------------------------------------------------------------

--- provided with source, target we make sure that the same number of 
-- volume/panning/delay and note/effect columns are visible
-- @param source (renoise.Track or renoise.InstrumentPhrase)
-- @param target (renoise.Track or renoise.InstrumentPhrase)

function Mlrx_track:sync_track_props(source,target)
  TRACE("Mlrx_track:sync_track_props(source,target)",source,target)

  --print("*** sync_track_props(source,target)",source,target)

  --target.number_of_lines = source.number_of_lines
  target.volume_column_visible = source.volume_column_visible
  target.panning_column_visible = source.panning_column_visible
  target.delay_column_visible = source.delay_column_visible
  target.visible_note_columns = source.visible_note_columns
  target.visible_effect_columns = source.visible_effect_columns

end

--------------------------------------------------------------------------------

--- create room for a newly recorded phrase (lowest non-phrase-mapped note)
-- @return renoise.InstrumentPhrase or nil if allocation failed 

function Mlrx_track:allocate_phrase()
  TRACE("Mlrx_track:allocate_phrase()")

  local insert_at = nil
  local insert_idx = nil
  if table.is_empty(self.instr.phrases) then
    insert_at = 0
    insert_idx = 1
  else
    local last_phrase = self.instr.phrases[#self.instr.phrases]
    if (last_phrase.mapping.note_range[2] < 119) then
      insert_at = last_phrase.mapping.note_range[2] + 1
      insert_idx = #self.instr.phrases + 1
    end
  end

  if insert_at then
    local phrase = self.instr:insert_phrase_at(insert_idx)
    phrase.mapping.note_range = {insert_at,insert_at}
    phrase.mapping.base_note = insert_at
    return phrase
  end

end

--------------------------------------------------------------------------------

--- toggle between phrase and normal sample playback


function Mlrx_track:toggle_phrase_mode()
  TRACE("Mlrx_track:toggle_phrase_mode()")

  if self.instr then

    local mode = self.instr.phrase_playback_enabled
    self.instr.phrase_playback_enabled = not mode

    if not self.instr.phrase_playback_enabled then
      -- phrase disabled, transpose into basenote of sample 
      local sample_ref = self:get_sample_ref(self.note_pitch)
      if sample_ref then -- adjust to basenote
        local new_pitch = sample_ref.sample_mapping.base_note
        --print("new_pitch",new_pitch,"self.note_pitch",self.note_pitch)
        if (new_pitch ~= self.note_pitch) then
          self.note_pitch = new_pitch
          --self:set_transpose(0)
        end
      end
    else
      -- phrase enabled, but does the instrument have any phrases?
      if table.is_empty(self.instr.phrases) then
        local msg = "Message from mlrx: this instrument does not contain any phrases. "
                  .."Press and hold the PHRASE button to record the phrase (when playing), "
                  .."or to capture from the pattern (when stopped)"
        renoise.app():show_status(msg)
        return
      end

      local phrase_ref = self:get_phrase_ref(self.note_pitch)
      if not phrase_ref then
        -- capture the most recently added phrase
        phrase_ref = self.instr.phrases[#self.instr.phrases]
      end
      if phrase_ref then -- adjust to basenote
        local new_pitch = phrase_ref.mapping.base_note
        --print("new_pitch",new_pitch,"self.note_pitch",self.note_pitch)
        if (new_pitch ~= self.note_pitch) then
          self.note_pitch = new_pitch
          --self:set_transpose(0)
        end
      end
      
    end

    self.main:update_track_task()

  end

end

--------------------------------------------------------------------------------

function Mlrx_track:apply_beatsync_to_tuning()
  TRACE("Mlrx_track:apply_beatsync_to_tuning()")

  -- start by computing the actual number of lines 
  local slines = self:obtain_sample_lines()

  local target_transp, tmp_lines = nil,nil
  local tmp_transp = 0

  -- figure out the transpose amount
  if (self.sample.beat_sync_lines > slines) then
    tmp_lines = 0
    while (tmp_lines < self.sample.beat_sync_lines) do
      tmp_transp = tmp_transp-1  
      tmp_lines = slines/(math.pow(2,tmp_transp/12))
    end
    target_transp = tmp_transp+1
  else
    tmp_lines = self.sample.beat_sync_lines+1
    while (tmp_lines > self.sample.beat_sync_lines) do
      tmp_transp = tmp_transp+1  
      tmp_lines = slines/(math.pow(2,tmp_transp/12))
    end
    target_transp = tmp_transp-1
  end

  -- compute the cents deviation
  local line_diff = tmp_lines
  tmp_lines = slines/(math.pow(2,target_transp/12))
  local target_cents = (tmp_lines-self.sample.beat_sync_lines)/(line_diff-tmp_lines)
  target_cents = math.abs(scale_value(target_cents,0,1,0,127))
  if (self.sample.beat_sync_lines >= slines) then
    target_cents = - target_cents
  end

  --print("*** target_transp",target_transp)
  --print("*** target_cents",target_cents)

  self.note_pitch = self.sample.sample_mapping.base_note
  self.sample.transpose = target_transp
  self.sample.fine_tune = target_cents
  self.sample.beat_sync_enabled = false

end


--------------------------------------------------------------------------------

-- double the tempo (half sync)

function Mlrx_track:set_phrase_lpb(val)
  TRACE("Mlrx_track:set_phrase_lpb(val)",val)

  if self.phrase then
    local phrase_lpb = self.phrase.lpb + val
    phrase_lpb = math.min(256,math.max(1,phrase_lpb))
    self.phrase.lpb = phrase_lpb
  end

end


--------------------------------------------------------------------------------

-- double the tempo for a phrase

function Mlrx_track:set_double_lpb()
  TRACE("Mlrx_track:set_double_lpb()")

  if self.phrase then
    local phrase_lpb = self.phrase.lpb*2
    if (phrase_lpb <= 256) then
      self.phrase.lpb = phrase_lpb

      return 
    end
  end

end

--------------------------------------------------------------------------------

-- double the tempo (half sync)

function Mlrx_track:set_half_lpb()
  TRACE("Mlrx_track:set_half_lpb()")

  if self.phrase then
    local phrase_lpb = self.phrase.lpb/2
    if (phrase_lpb ~= math.floor(phrase_lpb)) then
      -- fractional value, find an even replacement
      -- (obs! this can cause stuttering)
      local tmp = math.ceil(phrase_lpb)
      phrase_lpb = math.max(1,tmp-tmp%2)
    end
    if (phrase_lpb >= 1) then
      self.phrase.lpb = phrase_lpb
      return 
    end
  end

end



--------------------------------------------------------------------------------

-- halve the tempo (double sync)

function Mlrx_track:set_double_sync()
  TRACE("Mlrx_track:set_double_sync()")

  local count = 0
  for i = self.sync_to_lines, 513,16 do
    if (i == self.sync_to_lines*2) then
      self:set_beat_sync(-count)
      break
    end
    count = count + 1
  end

end

--------------------------------------------------------------------------------

-- double the tempo (half sync)

function Mlrx_track:set_half_sync()
  TRACE("Mlrx_track:set_half_sync()")

  local count = 0
  for i = self.sync_to_lines, 0,-16 do
    if (i <= self.sync_to_lines/2) then
      self:set_beat_sync(count)
      break
    end
    count = count + 1
  end

end


--------------------------------------------------------------------------------

-- when shuffle is set, add Cxx command to cut off overlapping sounds

function Mlrx_track:toggle_shuffle_cut()
  TRACE("Mlrx_track:toggle_shuffle_cut()")

  self.shuffle_cut = not self.shuffle_cut
  self.main:update_track_shuffle(self)
  self.main.initiate_settings_requested = true

end

--------------------------------------------------------------------------------

-- when shuffle is set, compute a little table of shuffle offsets
-- @param val (float), value between 0 and 255

function Mlrx_track:set_shuffle_amount(val)
  TRACE("Mlrx_track:set_shuffle_amount(val)",val)

  local new_val = math.floor(val)
  if (self.shuffle_amount == new_val) then
    return false
  end

  self.shuffle_amount = new_val
  --print("*** self.shuffle_amount",self.shuffle_amount)

  if rns.transport.edit_mode and 
    (self.main.options.automation.value ~= Mlrx.AUTOMATION_READ)
  then
    -- immediately output
    local pos = Mlrx_pos()
    if rns.transport.playing then
      pos.line = pos.line + 1
      pos:normalize()
    end

    local patt = rns:pattern(rns.sequencer.pattern_sequence[pos.sequence])
    local rns_trk = rns.tracks[self.rns_track_idx]
    local line = patt.tracks[self.rns_track_idx]:line(pos.line)
    local note_col = self:get_note_col(line)
    local fxcol_3 = line:effect_column(Mlrx_track.TRACK_FXCOL_CXX)

    self:output_shuffle(rns_trk,pos.line,note_col,fxcol_3)

    if (self.main.options.automation.value == Mlrx.AUTOMATION_WRITE) then
      self.trk_latch_shuffle = true
    end

  end

  self.main.track_shuffle_update_requested = true
  self.main.initiate_settings_requested = true

end

--------------------------------------------------------------------------------

function Mlrx_track:set_drift_amount(val)
  TRACE("Mlrx_track:set_drift_amount(val)",val)

  self.drift_amount = math.floor(val)
  --print("*** self.drift_amount",self.drift_amount)

  self.main:update_track_drift()
  self.main.initiate_settings_requested = true

end

--------------------------------------------------------------------------------

function Mlrx_track:cycle_drift_mode()
  TRACE("Mlrx_track:cycle_drift_mode()")

  local val = nil
  if (self.drift_mode == Mlrx_track.DRIFT_OFF) then
    val = Mlrx_track.DRIFT_ALL
  elseif (self.drift_mode == Mlrx_track.DRIFT_ALL) then
    val = Mlrx_track.DRIFT_CYCLE
  elseif (self.drift_mode == Mlrx_track.DRIFT_CYCLE) then
    val = Mlrx_track.DRIFT_OFF
  end

  self:set_drift_mode(val)

end

--------------------------------------------------------------------------------

function Mlrx_track:set_drift_mode(val)
  TRACE("Mlrx_track:set_drift_mode(val)",val)

  self.drift_mode = val
  --print("*** self.drift_mode",self.drift_mode)

  self.main:update_track_drift()
  self.main.initiate_settings_requested = true

end

--------------------------------------------------------------------------------

function Mlrx_track:set_transpose_task(val)

  self.main.display.scheduler:remove_task(self._set_transpose_task)
  self._set_transpose_task = self.main.display.scheduler:add_task(
    self, Mlrx_track.set_transpose, 0.2, val)

end

-- maintain or adjust the transpose/line sync amount 
-- @param val (int) the amount of 'tempos' or 'semitones' to transpose 

function Mlrx_track:set_transpose(val)
  TRACE("Mlrx_track:set_transpose(val)",val)

  --local new_transpose = clamp_value(self.note_pitch + val,0,119)
  local old_pitch = self.note_pitch
  local new_pitch = clamp_value(self.note_pitch + val,0,119)
  --print("*** set_transpose - new_pitch",new_pitch)

  if self.instr then
    if self.instr.phrase_playback_enabled then
      -- check if we transposed "into" a phrase
      local phrase,phrase_index = self:get_phrase_ref(new_pitch)
      if not phrase and self.phrase then
        --print("*** set_transpose - transposed away from phrase",self.phrase.name)
        self:remove_notifiers(self._phrase_observables)
        if rawequal(self.instr,rns.selected_instrument) then
          rns.selected_phrase_index = 0
        end
        self.phrase = nil
      else
        self.note_pitch = new_pitch
        if not rawequal(phrase,self.phrase) then
          --print("*** set_transpose - transposed into new phrase",phrase,self.phrase,phrase_index,self.instr.name)
          self:remove_notifiers(self._phrase_observables)
          -- if this is the selected instrument
          --print("selected instr:",rawequal(self.instr,rns.selected_instrument))
          if rawequal(self.instr,rns.selected_instrument) then
            rns.selected_phrase_index = phrase_index
          end
          self:attach_to_phrase()
        end
      end
    end

    local using_phrase = self.phrase
    if not self.instr.phrase_playback_enabled then
      using_phrase = false
    end

    if not using_phrase then

      local is_synced = (self.sample and self.sample.beat_sync_enabled)

      -- check if we transposed out from/into a sample
      local sample,sample_index = self:get_sample_ref(new_pitch)
      if not sample and self.sample then
        --print("*** set_transpose - transposed away from sample",self.sample.name)
        self:remove_notifiers(self._sample_observables)
        self.sample = nil
      else -- if not is_synced then
        self.note_pitch = new_pitch
        if not rawequal(sample,self.sample) then
          --print("*** set_transpose - transposed into sample",self.sample)
          self:remove_notifiers(self._sample_observables)
          self.sample = sample
          self:attach_to_sample()
          --print("playpos",Mlrx_pos())
          if self.note then
            -- make new sound play from next repeat-pos
            self.note.startpos = Mlrx_pos(self.note.repeatpos)
            self.note.repeatpos = nil
            self.note.written = nil
            self.note.offed = nil
            
            -- TODO clear any lines until note-start

          end

          if rawequal(self.instr,rns.selected_instrument) then
            rns.selected_sample_index = sample_index
          end

        end
      end

    end

    if not using_phrase and self.sample then

      if self.sample.beat_sync_enabled then

        --print("*** beat-synced sample - self.sync_to_lines",self.sample.beat_sync_lines)
        self.sync_to_lines = self.sample.beat_sync_lines 

      else

        --print("*** non beat-synced sample")
        -- determine approximate duration 

        -- include keyzone, transpose and finetune
        local transpose_offset = self.note_pitch - self.sample.sample_mapping.base_note
        transpose_offset = transpose_offset + (self.sample.transpose + self.sample.fine_tune/127)

        local tempo_factor = nil
        if (transpose_offset < 0) then
          tempo_factor = math.pow(2,-(math.abs(transpose_offset)/12))
        else
          tempo_factor = math.pow(2,(transpose_offset)/12)
        end

        local slines = self:obtain_sample_lines(tempo_factor)
        --print("*** set_transpose (sample) - slines",slines)  

        if slines then
          self.sync_to_lines = round_value(slines)
        else
          self.sync_to_lines = Mlrx_track.FALLBACK_LINESYNC
        end

        --print("*** set_transpose (sample) - sync_to_lines",self.sync_to_lines)  

      end



    elseif self.phrase then

      local lpb_factor = rns.transport.lpb / self.phrase.lpb
      --self.sync_to_lines = math.ceil(self.phrase.number_of_lines * lpb_factor)
      self.sync_to_lines = self.phrase.number_of_lines * lpb_factor
      --print("lpb_factor",lpb_factor)
      --print(" set_transpose (phrase) - self.phrase.number_of_lines",self.phrase.number_of_lines)  
      --print(" set_transpose (phrase) - self.sync_to_lines",self.sync_to_lines)  

      local tmp = self.sync_to_lines
      while not is_whole_number(self.sync_to_lines) do
        self.sync_to_lines = self.sync_to_lines + tmp
        --print("phrase - raise cycles to whole number",self.sync_to_lines)
      end

    end


  end

  self:determine_cycle_lines()
  self:update_summary_task()
  self.main.initiate_settings_requested = true

  --[[
  if (old_pitch ~= self.note_pitch) then
    self.main.initiate_settings_requested = true
  end
  ]]

end

--------------------------------------------------------------------------------
-- set beat-sync to relative tempo 

function Mlrx_track:set_beat_sync(val)
  TRACE("Mlrx_track:set_beat_sync(val)",val)

  self.sync_to_lines = self.sample.beat_sync_lines
  --print("*** set_beat_sync - self.sync_to_lines",self.sync_to_lines)

  val = -val -- up means down :-)

  self.sync_to_lines = self:get_restricted_beat_sync(val)
  --print("set_transpose - get_restricted_beat_sync",self.sync_to_lines)  
  
  self.sample.beat_sync_lines_observable:remove_notifier(self.beat_sync_lines_notifier)
  self.sample.beat_sync_lines = self.sync_to_lines
  self.sample.beat_sync_lines_observable:add_notifier(self.beat_sync_lines_notifier)

  self:determine_cycle_lines()

end

--------------------------------------------------------------------------------

-- kindly ask a playing track to schedule a note-off 
-- (this will ensure that the light is properly turned off, etc)

function Mlrx_track:schedule_noteoff()
  TRACE("Mlrx_track:schedule_noteoff()")

  if not self.do_note_output then
    return
  end

  if not self.note then
    self.note = Mlrx_note()
    self.index = 1
    self.time_pressed = os.clock()
    self.time_quant = os.clock()
  else
    --print("*** schedule_noteoff - track already got a note - self_idx",self.self_idx)
  end

  local playpos = Mlrx_pos()

  -- do not output or clear anything else!!
  self.note.startpos = nil
  self.note.repeatpos = nil

  local endpos = Mlrx_pos(playpos)
  endpos.line = endpos.line+1
  endpos:normalize()
  self.note.endpos = endpos
  self.note.ignore_lines:insert(playpos)
  --print("Mlrx_track.schedule_noteoff - endpos",endpos)

  -- immediately output
  self:track_output(playpos,1)



end

--------------------------------------------------------------------------------

function Mlrx_track:set_trig_mode(enum)
  TRACE("Mlrx_track:set_trig_mode(enum)",enum,type(enum))

  self.trig_mode = enum

  -- HOLD/TOUCH stops the active voice
  if self.note and self.note.active and (
    (self.trig_mode == Mlrx_track.TRIG_WRITE) or
    (self.trig_mode == Mlrx_track.TRIG_TOUCH))
  then
    self._last_pressed = nil
    self:schedule_noteoff()
  end

  -- easy way to tell when/if we should clear pattern data 
  self._clear_without_note = (self.trig_mode == Mlrx_track.TRIG_WRITE) or
    (self.trig_mode == Mlrx_track.TRIG_TOGGLE)

  self.writeahead_factor = (self.trig_mode == Mlrx_track.TRIG_TOUCH) and
    Mlrx_track.WRITEAHEAD_SHORT or Mlrx_track.WRITEAHEAD_LONG

  self.group.active_track_index = nil
  self.main.initiate_settings_requested = true

end

--------------------------------------------------------------------------------

  -- change the cycle length (and retrigger the playing note)
  -- TODO consider a more clever implementation : 
  -- if we expand the playing range (e.g. from 1/16 to 1/8), do not retrigger
  -- if we reduce the playing range, check if inside 'range' 
  -- if inside range, schedule the retrig
  -- @param val (Mlrx_track.CYCLE)
  -- @param programmatic (bool) do not toggle off

function Mlrx_track:set_cycle_length(val,programmatic)
  TRACE("Mlrx_track:set_cycle_length(val)",val,type(val))

  if not programmatic and (val == self.cycle_length) then
    self.cycle_length = Mlrx_track.CYCLE.FULL
  else
    self.cycle_length = val
  end
  self:determine_cycle_lines()

  if self.note and self.note.active then
    local skip_toggling = true
    self:trigger_press(self.note.index,skip_toggling)
  end

  self:update_summary_task()
  self.main.initiate_settings_requested = true

end

--------------------------------------------------------------------------------

--- increase_cycle

function Mlrx_track:increase_cycle()

  self.cycle_lines = self.cycle_lines + 1
  self.cycle_length = Mlrx_track.CYCLE.CUSTOM
  --print("increase_cycle - self.cycle_lines",self.cycle_lines)

end

--------------------------------------------------------------------------------

--- increase_cycle

function Mlrx_track:decrease_cycle()

  self.cycle_lines = math.max(1,self.cycle_lines - 1)
  self.cycle_length = Mlrx_track.CYCLE.CUSTOM
  --print("decrease_cycle - self.cycle_lines",self.cycle_lines)

end

--------------------------------------------------------------------------------

--- update cycle lines to cycle length, custom value etc. 

function Mlrx_track:determine_cycle_lines()


  if (self.cycle_length == Mlrx_track.CYCLE.CUSTOM) then
    -- do nothing
  elseif (self.cycle_length == Mlrx_track.CYCLE.EDITSTEP) then
    self.cycle_lines = math.max(1,rns.transport.edit_step)
  else
    if not self.sync_to_lines then
      self.cycle_lines = 4 -- fallback value
    else
      self.cycle_lines = math.max(1,math.floor(self.sync_to_lines/self.cycle_length))
    end
  end

end

--------------------------------------------------------------------------------

function Mlrx_track:set_arp_mode(mode)
  TRACE("Mlrx_track:set_arp_mode(mode)",mode)

  self.arp_mode = mode
  --print("*** self.arp_mode",self.arp_mode)
  self.main.initiate_settings_requested = true

end

--------------------------------------------------------------------------------

-- specify the track velocity level, record automation...
-- @param val (int) value between 0 and 127

function Mlrx_track:set_trk_velocity(val,skip_output)
  TRACE("Mlrx_track:set_trk_velocity(val)",val)

  self.velocity = math.min(Mlrx.INT_7BIT,math.floor(val))
  self.default_velocity = (self.velocity == Mlrx_track.DEFAULT_VELOCITY)
  --print("*** set_trk_velocity - self.velocity",self.velocity)

  if not skip_output and rns.transport.edit_mode and
    (self.main.options.automation.value ~= Mlrx.AUTOMATION_READ)
  then
    self:set_trk_automation(Mlrx_track.PARAM_VELOCITY)
  end

  self.main.initiate_settings_requested = true

end

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

-- specify the track velocity level, record automation...
-- @param val (int) value between 0 and 127

function Mlrx_track:set_trk_panning(val,skip_output)
  TRACE("Mlrx_track:set_trk_panning(val)",val,skip_output)

  self.panning = math.floor(val)
  self.default_panning = (self.panning == Mlrx_track.DEFAULT_PANNING)

  if not skip_output and rns.transport.edit_mode and
    (self.main.options.automation.value ~= Mlrx.AUTOMATION_READ)
  then
    self:set_trk_automation(Mlrx_track.PARAM_PANNING)
  end

  self.main.initiate_settings_requested = true

end

--------------------------------------------------------------------------------

-- record current track velocity/panning into active note column
-- (support function for set_trk_panning/set_trk_velocity)
-- @param param_type (enum) Mlrx_track.PARAM_VELOCITY or Mlrx_track.PARAM_PANNING

function Mlrx_track:set_trk_automation(param_type)
  TRACE("Mlrx_track:set_trk_automation(param_type)",param_type)

  local pos = Mlrx_pos()
  if rns.transport.playing then
    pos.line = pos.line + 1
    pos:normalize()
  end
  local patt_idx = rns.sequencer.pattern_sequence[pos.sequence]
  local patt = rns:pattern(patt_idx)
  local rns_trk = patt.tracks[self.rns_track_idx]
  local line = rns_trk:line(pos.line)
  local note_col = self:get_note_col(line)
  if (param_type == Mlrx_track.PARAM_PANNING) then
    note_col.panning_value = self.default_panning and 
      renoise.PatternLine.EMPTY_PANNING or self.panning
  elseif (param_type == Mlrx_track.PARAM_VELOCITY) then
    note_col.volume_value = self.default_velocity and 
      renoise.PatternLine.EMPTY_VOLUME or 
        math.min(Mlrx.INT_7BIT,self.velocity+self.pressure)
  end

  if (self.main.options.automation.value == Mlrx.AUTOMATION_WRITE) then
    if (param_type == Mlrx_track.PARAM_PANNING) then
      self.trk_latch_panning = true
    elseif (param_type == Mlrx_track.PARAM_VELOCITY) then
      self.trk_latch_velocity = true
    end   
  elseif (self.main.options.automation.value == Mlrx.AUTOMATION_READ_WRITE) then
    self.main:flash_automation_button()
  end

end

--------------------------------------------------------------------------------

-- output shuffle commands to pattern, reveal effect column

function Mlrx_track:output_shuffle(rns_trk,line_idx,note_col,fxcol_3)
  TRACE("Mlrx_track:output_shuffle()",rns_trk,line_idx,note_col,fxcol_3)

  local shuffle_offset = line_idx%Mlrx_track.SHUFFLE_LENGTH
  if (shuffle_offset == 0) then
    shuffle_offset = Mlrx_track.SHUFFLE_LENGTH
  end
  local midway = math.floor(Mlrx_track.SHUFFLE_LENGTH/2)+1

  if (shuffle_offset < midway) then
    note_col.delay_value = renoise.PatternLine.EMPTY_DELAY
  else
    note_col.delay_value = self.shuffle_amount
  end

  if self.shuffle_cut and (shuffle_offset+1 == midway) then
    fxcol_3.number_string = "0C"
    fxcol_3.amount_value = rns.transport.tpl-1
  else
    fxcol_3:clear()
  end

  if not rns_trk.delay_column_visible then
    rns_trk.delay_column_visible = true
  end
  if self.shuffle_cut and
    (rns_trk.visible_effect_columns < Mlrx_track.TRACK_FXCOL_CXX) 
  then
    rns_trk.visible_effect_columns = Mlrx_track.TRACK_FXCOL_CXX
  end

end

--------------------------------------------------------------------------------

-- cycle through arp modes

function Mlrx_track:cycle_arp_mode()
  TRACE("Mlrx_track:cycle_arp_mode()")

  if (self.arp_mode == Mlrx_track.ARP_KEYS) then
    self.arp_mode = Mlrx_track.ARP_RANDOMIZE
  elseif (self.arp_mode == Mlrx_track.ARP_RANDOMIZE) then
    self.arp_mode = Mlrx_track.ARP_FORWARD
  elseif (self.arp_mode == Mlrx_track.ARP_FORWARD) then
    self.arp_mode = Mlrx_track.ARP_TWOSTEP
  elseif (self.arp_mode == Mlrx_track.ARP_TWOSTEP) then
    self.arp_mode = Mlrx_track.ARP_FOURSTEP
  elseif (self.arp_mode == Mlrx_track.ARP_FOURSTEP) then
    self.arp_mode = Mlrx_track.ARP_ALL
  elseif (self.arp_mode == Mlrx_track.ARP_ALL) then
    self.arp_mode = Mlrx_track.ARP_KEYS
  end

  --print("self.arp_mode",self.arp_mode)

  self.main.initiate_settings_requested = true


end

--------------------------------------------------------------------------------

-- light up a button on the controller, appropriate for the given position
-- @param travelled (int), how many lines the note has travelled

function Mlrx_track:light_position(travelled)
  TRACE("Mlrx_track:light_position(travelled)",travelled)
  --print("Mlrx_track:light_position(travelled)",travelled,"self.note",self.note,"self.sync_to_lines",self.sync_to_lines)

  if not self.note or not self.sync_to_lines then
    return
  end

  -- compensate for negative values, restrict to lines in cycle
  if (travelled < 1) then
    --print("*** light_position - restrict to lines in cycle")
    travelled = self.cycle_lines + travelled
    if (self.cycle_length > Mlrx_track.CYCLE.FULL) then
      travelled = ((travelled-1)%self.cycle_lines)+1
    end
  end

  local offset = math.ceil((travelled/self.sync_to_lines) * self._num_triggers)
  --print("*** light_position - travelled,offset",travelled,offset)

  -- rotate the position, according to the offset
  if (offset ~= 0) then
    offset = (((offset+self.note.index-1)-1)%self._num_triggers)+1
    --offset = (offset==0) and self._num_triggers or offset
  else
    offset = self.note.index
  end

  if (offset ~= self._lit_position) then
    --print("*** light_position - final offset",offset)
    self.main:update_trigger_pos(self.self_idx,offset)

    -- TOGGLE mode: flash the original trigger
    if (self.trig_mode == Mlrx_track.TRIG_TOGGLE) and 
      (offset ~= self.note.index) 
    then
      self.main:trigger_feedback(self.self_idx,self.note.index,0.25)
    end


  end



end


--------------------------------------------------------------------------------

-- obtain the track name, as assigned to the Renoise track
-- ~04 (instrument with no content)
-- HighShot (instrument with name)

function Mlrx_track:get_name()

  local str_name = ""
  if self.instr and not (self.instr.name == "") then
    str_name = string.format("%s",self.instr.name)
  else
    str_name = string.format("~%02d",self.rns_instr_idx)
  end
  return str_name

end

--------------------------------------------------------------------------------

-- update the name/color of a renoise track within the mlrx-group

function Mlrx_track:decorate_track_task()
  --TRACE("Mlrx_track:decorate_track_task()")
  self.main.display.scheduler:remove_task(self._decorate_track_task)
  self._decorate_track_task = self.main.display.scheduler:add_task(
    self, Mlrx_track.decorate_track, 0.2, self.self_idx)
end

function Mlrx_track:decorate_track()
  TRACE("Mlrx_track:decorate_track()")

  local rns_trk = rns.tracks[self.rns_track_idx]

  if not rns_trk then
    --LOG(" decorate_track - track does not exist @",self.rns_track_idx)
    return
  end

  if not rns_trk.group_parent then
    --LOG(" something went wrong, track has no parent group")
    return
  end

  if (rns_trk.type ~= renoise.Track.TRACK_TYPE_SEQUENCER) then
    --LOG(" something went wrong, this is not a sequencer track")
    return
  end

  if rns_trk then

    rns_trk.name = self:get_name()
    rns_trk.color = (self.group.void_mutes) and 
      self.group.color_dimmed or self.group.color

    local opt_collapse = self.main.options.collapse_tracks.value
    if (opt_collapse == Mlrx.COLLAPSE_TRACKS_AUTO) then
      rns_trk.collapsed =  
        (self.rns_track_idx ~= rns.selected_track_index) and true or false
    else
      rns_trk.collapsed = 
        (opt_collapse == Mlrx.COLLAPSE_TRACKS_ON) and true or false
    end

    --rns_trk.visible_note_columns = 1
    rns_trk.volume_column_visible = true
    rns_trk.panning_column_visible = true

  end

end


--------------------------------------------------------------------------------

-- handle pressed buttons 

function Mlrx_track:trigger_press(trigger_idx,skip_toggling)
  TRACE("Mlrx_track:trigger_press()",trigger_idx,skip_toggling)

  if not self.instr then
    return
  end

  --print("*** trigger pressed - self.note",self.note)
  --print("*** trigger pressed - self._last_pressed",self._last_pressed)

  if not skip_toggling and (self.trig_mode == Mlrx_track.TRIG_TOGGLE) and
    self.note and (self._last_pressed == trigger_idx)
  then
    --print("*** trigger was pressed twice, turn off...",self._last_pressed,trigger_idx)
    self:trigger_release(trigger_idx,true)
    return
  end


  -- always initialize this value (reset when song is swapped)
  local playpos = Mlrx_pos()
  if not self._last_playpos then
    self._last_playpos = playpos
  end

  -- figure out the closest quantized line
  local startpos = Mlrx_pos(playpos)
  local quant_diff = startpos:quantize(self.main._quantize)
  local quant_time_delay = quant_diff/self.lps

  --print("trigger_press - startpos",startpos.line)

  self.note = Mlrx_note()
  self.note.index = trigger_idx
  self.note.time_pressed = os.clock()
  self.note.time_quant = os.clock()+quant_time_delay
  self.note.startpos = startpos

  -- WRITE/TOGGLE mode will need this when wiping tracks
  self.group.active_track_index = self.self_idx


  if (self.arp_mode == Mlrx_track.ARP_KEYS) then  
    -- when pressing additional keys in arpeggiator mode,
    -- the most recent note gets triggered first...
    if (#self._held_keys > 0) then
      self.arp_index = #self._held_keys-1
    end
  end

  -- if one or more MIDI keys were released while navigating to 
  -- a different track, initialize the held keys table
  if self._hanging_notes then
    self._hanging_notes = false
    local most_recent_key = self._held_keys[#self._held_keys]
    self._held_keys = table.create()
    self._held_keys:insert(most_recent_key)
    --print("initialize the held keys table")
    --rprint(self._held_keys)
  end

  -- when the track is phrase-record armed
  if self.phrase_record_armed then
    self:start_phrase_recording()
  end

  -- immediate output (don't wait for idle loop)
  self:track_output(playpos,self.writeahead)
  self.group:switch_to_track(self.self_idx)

  local active_track_option = self.main.options.active_track.value
  if (active_track_option == Mlrx.ACTIVE_TRACK_AUTO) then
    self.main:select_track(self.self_idx)
  end

  if not rns.transport.playing then
    if (self.main.options.play_on_trig.value == Mlrx.PLAY_ON_TRIG) then
      -- start playback, rewind a single line to play the note
      local tmp_pos = Mlrx_pos(startpos)
      tmp_pos.line = tmp_pos.line-1
      if (tmp_pos.line == 0) then
        tmp_pos.line = 1
      end
      rns.transport:start_at(tmp_pos.line)
      self.note.active = true
    else
      self.note = nil
    end
  end

  rns.transport.edit_mode = true

  self._last_pressed = trigger_idx

  --print("*** trigger_press - self._last_pressed",self._last_pressed,"self.note",self.note,"self_idx",self.self_idx)

end

--------------------------------------------------------------------------------

-- handle released buttons 
-- @trigger_idx (int) pressed trigger button
-- @param toggle_off (bool) toggle off, or revert to previous

function Mlrx_track:trigger_release(trigger_idx,toggle_off)
  TRACE("Mlrx_track:trigger_release()",trigger_idx,toggle_off)

  if not self.note then
    return
  end


  if not self._held_keys:is_empty() then
    --print("*** trigger_release - one or more MIDI keys are still pressed")
    return
  end


  --print("*** A trigger_release - self._held_triggers...",#self._held_triggers)
  --rprint(self._held_triggers)

  -- revert to previous pressed button ?
  if not toggle_off and not self._held_triggers:is_empty() then
    --print("*** trigger_release - key released, other key(s) still pressed")
    --rprint(self._held_triggers)
    local new_trigger = self._held_triggers[#self._held_triggers]
    --print("*** B trigger_release - new_trigger",new_trigger)
    if (new_trigger ~= self._last_pressed) then
      self:trigger_press(new_trigger or 1) 
    end
    return

  end

  if (self.trig_mode == Mlrx_track.TRIG_TOGGLE) and not toggle_off then
    --print("*** trigger_release - ignore in toggle mode")
    return
  end

  if (self.trig_mode == Mlrx_track.TRIG_HOLD) then
    --print("*** trigger_release - ignore in continously looping mode")
    return
  end

  -- update the release time
  local time_released = os.clock()
  --print("*** trigger_release - time_released",time_released)

  local pos = Mlrx_pos()
  local line_count = 0

  --print("*** trigger_release - self.note",self.note)
  --print("*** trigger_release - self.note.time_quant",self.note.time_quant)

  -- ??? sometimes, time_quant is not defined ???
  if self.note.time_quant and
    (time_released > self.note.time_quant) 
  then
    --print("*** trigger_release - released after note-on - output note-off at first given chance")
    pos.line = pos.line+1
  elseif self.note.startpos then
    --print("*** trigger_release - released before note-on, use held time as duration")
    pos = self.note.startpos
    local time_diff = time_released - self.note.time_pressed
    line_count = math.ceil(self.lps * (time_released - self.note.time_pressed))
    line_count = math.min(1,line_count) -- duration should be at least one line
  end

  self.note.endpos = Mlrx_pos({
    sequence = pos.sequence,
    line = pos.line + line_count
  })

  --print("trigger_release - self.endpos.line",self.note.endpos.line)

  -- normalize the endpos
  self.note.endpos:normalize()

  -- make sure it is _at least_ one line after startpos
  if self.note.startpos and 
    (self.note.startpos == self.note.endpos) 
  then
    --print("trigger_release - self.endpos (prior to normalize)",self.note.endpos.sequence,self.note.endpos.line)
    self.note.endpos.line = self.note.endpos.line+1
    self.note.endpos:normalize()
  end

  self.note.repeatpos = nil

  --print("trigger_release - self.endpos",self.note.endpos.sequence,self.note.endpos.line)

  -- output at once (snappier response)
  self.group:group_output()

  if (trigger_idx == self._held_triggers[#self._held_triggers]) then
    --print("*** trigger_release - last button released")
    self._held_triggers = table.create()
  else
    --remove_trigger(trigger_idx)
  end

  --print("trigger_release: self._held_triggers... B")
  --rprint(self._held_triggers)

end

--------------------------------------------------------------------------------

-- compare to another class instance (check for object identity)

function Mlrx_track:__eq(other)
  return rawequal(self, other)
end  

