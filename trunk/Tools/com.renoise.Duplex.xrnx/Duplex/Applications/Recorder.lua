--[[----------------------------------------------------------------------------
-- Duplex.Recorder
-- Inheritance: Application > Recorder
----------------------------------------------------------------------------]]--

--[[

About

  The Recorder is a looping sample-recorder that you can use for recording any 
  signal that you feed into Renoise, be that your voice, a guitar etc. Operation 
  is designed to be really simple,: press a button to select the track and bring 
  up the recording dialog, press again to start recording. Once the recording is 
  done, it’s (optionally) looped/synced to the beat, and you’re then instantly 
  able to switch among this, and all the other recordings you’ve made. The 
  Recorder will even allow samples with different lengths to loop continuously, 
  allowing for poly-rhythms.

  Whenever a song is saved, references to your recorded samples are not “lost” - 
  the Recorder is smart enough to remember and restore recording sessions. Each 
  recording is assigned a special name which is automatically recognized by the 
  application - and the next time you load the song, the recordings should be 
  right where you left them.



Using the Recorder 

  Note that when reading the following description, and using a controller with 
  faders/dials instead of a (button-based) grid controller, you don’t have 
  “sample slots” that you can press - instead, the recorder button is used for 
  this purpose. But otherwise, the description is pretty much the same. 

  IMPORTANT: before you record anything, please ensure that the recording dialog 
  in Renoise is set to create a new instrument on each take, and that the 
  recording is synced to the pattern length. If this is not done, the results 
  may be unpredictable. 

  1. Track select stage

  Press any recorder button to open/close the recording dialog for the desired 
  track (you can only record into sequencer tracks). When the recording dialog 
  has been opened, a sample slot will start to blink slowly. Press the sample 
  slot to enter the next stage. If your controller supports “hold” events, you 
  can also hold a recorder button for a moment to start recording as soon as 
  possible. 

  2. Preparation stage

  The preparation stage is the time spent before the playback position enters 
  the beginning of the pattern and begin the actual recording. On the recording 
  dialog it will read “Starting in XX lines...”, and the selected sample slot 
  will be  flashing rapidly. As long as you’re in the preparation stage, you can 
  hit the sample slot again to tell the Recorder that you wish to record only a 
  single pattern (now, both the the recorder button and the sample slot will 
  start flashing rapidly). This is known as a short take, and will take you 
  straight from the preparation stage to the finalizing stage.

  3. Recording stage

  In the recording stage, you’ll see both the recorder button and the sample 
  slot blinking slowly, in time with the beat. There is no limit to the length 
  of the recording, except of course the amount of RAM you computer has 
  installed, so you can keep it going for as long as you desire. 
  Press the sample slot again to stop the recording and enter the finalizing 
  stage.

  4. Finalizing stage

  The finalizing stage is the time spent while recording before the playback 
  reaches the beginning of a pattern. On the recording dialog it will read 
  “Stopping in XX lines...”, and the recording button will be flashing rapidly. 
  While you’re in the finalizing stage, pressing the sample slot will write the 
  yet-to-be sample to the pattern (however, this is only useful if you’ve not 
  enabled the writeahead mode, which does this automatically for you). 
  5: Post-recording stage

  Immediately after the recording has been made, the resulting sample is 
  automatically renamed, and the recording dialog is closed. We’re ready for 
  another recording. 

  Hint: you can choose another destination track for the recording, or abort the 
  recording at any time. Use the recorder button to select another track, and 
  turn a dial/select an existing sample slot to abort the recording.


Mappings

  recorders - (UIToggleButton...) toggle recording mode for track X
  sliders   - (UISlider...) sample-select sliders, assignable to grid controller


Options

  loop_mode     - determine the looping mode of recordings 
  beat_sync     - determine if the recording should be synced to the beat
  autostart     - specify the number of lines for the autostart note
  writeahead    - (obsolete) determine if sample playback should start after each recording
  trigger_mode  - toggle between continuous/05xx, or normal mode


Current limitations

  - The Recorder has been designed for recording samples that are synced to the 
    pattern length, creating a new instrument for each recording. If you choose 
    other settings, the results may be unpredictable. 
  - Please be careful when changing the tempo while recording, as this will 
    break the beat-sync of samples.
  - When you record something using the Recorder, each recording is named 
    something like “Track #2 - Recording #1” - please do not edit these names, 
    as they are used for keeping track of the recordings you have made.
  - Autostart is an extra note that's being written to the pattern immediately
    after a new recording has been made. Because Renoise needs a little moment
    to actually make the sample available for playback, the autostart option 
    has been added so you can adjust how quickly we should attempt to start
    playback. Adjust the amount so it matches your setup: the higher tempo your
    track is, the higher autostart value you need (for reference, with a delay 
    of one line at LPB4, autostart will break at around 185 BPM)
  - There is currently no check for when tracks and instruments are swapped 
    around while the application is running. If you accidentally swapped an 
    instrument, you should be able to restore it by starting and stopping the 
    application, as the list of instrument references are recreated on each 
    startup. 
  - Due to the way the scripting API works, some notifiers will only work when 
    specific parts of the interface are visible. For example, the Recorder is 
    automatically selecting active recordings as playback is progressing, but we 
    never get the notification that the pattern has changed while in the 
    instrument/sample editor

Changes (equal to Duplex version number)

  0.95  - First release



--]]

--==============================================================================


class 'Recorder' (Application)

Recorder.default_options = {
  --writeahead = {
  --  label = "Writeahead",
  --  description = "Automatically add recordings to the pattern?",
  --  items = {"Yes, take care of this","No, want to do it myself"},
  --  default = 2,
  --},
  loop_mode = {
    label = "Loop Mode",
    description = "Select the default loop mode for new recordings",
    items = {
      "Off",
      "Forward",
      "Reverse",
      "Ping-pong"
    },
    value = 2,
  },
  auto_seek = {
    label = "Autoseek",
    description = "Choose if new recordings should have autoseek enabled "
                .."\n(note that autoseek will make 05xx triggering useless)",
    items = {
      "Enable autoseek",
      "Disable autoseek"
    },
    value = 2,
  },
  beat_sync = {
    label = "Beat Sync",
    description = "Choose if new recordings should automatically"
                .."\nbe synced to the song tempo (max. 512 lines)",
    items = {
      "Sync enabled",
      "Sync disabled"
    },
    value = 1,
  },
  trigger_mode = {
    label = "Trigger mode",
    description = "Choose how notes are written to the pattern",
    items = {
      "Loop continuously (05xx)",
      "Retrig at pattern start"
    },
    value = 1,
  },
  autostart = {
    label = "Autostart",
    description = "Determine how many lines to use for autostart"
                .."\n(autostart will write the note to the pattern"
                .."\nimmediately after recording has finished."
                .."\nIf the value is too low, the note might not"
                .."\nplay the first time, as the sample takes a"
                .."\nmoment to be initialized properly)",
    items = {
      "Do not autostart",
      "Use LPB value",
      "1",
      "2", -- recommended setting 
      "3",
      "4",
      "5",
      "6",
      "7",
      "8"
    },
    value = 4,
  },

}

function Recorder:__init(display,mappings,options,config_name)
  TRACE("Recorder:__init(",display,mappings,options,config_name)

  Application.__init(self,config_name)

  self.display = display

  -- options

  --self.WRITEAHEAD_ON = 1
  --self.WRITEAHEAD_OFF = 2

  self.LOOP_MODE_OFF = 1
  self.LOOP_MODE_FORWARD = 2
  self.LOOP_MODE_REVERSE = 3
  self.LOOP_MODE_PING_PONG = 4

  self.BEAT_SYNC_ON = 1
  self.BEAT_SYNC_OFF = 2

  self.CONTINUOUS_MODE_ON = 1
  self.CONTINUOUS_MODE_OFF = 2

  self.AUTOSEEK_MODE_ON = 1
  self.AUTOSEEK_MODE_OFF = 2

  self.AUTOSTART_OFF = 1
  self.AUTOSTART_LPB = 2

  self.options = {  }

  self.mappings = {
    recorders = {
      description = "Recorder: Toggle recording mode",
      ui_component = {UI_COMPONENT_TOGGLEBUTTON},
    },
    sliders = {
      description = "Recorder: Switch between takes",
      ui_component = {UI_COMPONENT_SLIDER},
    },
  }

  self.palette = {
    slider_lit = {
      color = {0xff,0xff,0xff},
      text="■",
    },
    slider_dimmed = {
      color = {0x40,0x40,0x40},
      text="□",
    },
    recorder_lit = {
      color = {0xff,0x00,0xff},
      text="■",
    },
    recorder_dimmed = {
      color = {0x40,0x00,0x40},
      text="□",
    },
    --[[
    track_lit = {
      color = {0x00,0xff,0x00},
      text="■",
    },
    track_dimmed = {
      color = {0x00,0x40,0x00},
      text="□",
    },
    ]]
  }

  -- true if sliders are made from buttons
  self._grid_mode = false

  -- in grid mode, this is set to the slider height
  self._sliders_height = 1
  
  -- we need these numbers to be the same
  self._recorders_count = nil
  self._sliders_count = nil

  -- the currently selected track
  self._selected_track = nil

  -- set when preparing to record
  self._prepare = false

  -- set when recording is started
  self._recording = false

  -- set when recording is stopped
  self._finalizing = false

  -- set after recording is done
  -- (look for the resulting sample)
  self._post_recording = false

  -- set when we want to record immediately
  -- (press and hold recorder button)
  self._immediate_take = false

  -- set when we only want to record a single pattern
  -- will stop recording immediately after we've started
  -- (press track/sample button while in preparation state)
  self._short_take = false

  -- reference to most recent RecorderSample
  -- this is the "virtual" sample, before post-recording
  self._recent_sample = nil

  -- blinking booleans
  self._blink = false
  self._blink_fast = false

  -- internal sample counter (+1 for each "Recorded Sample")
  self._sample_count = nil

  -- this is the instrument we *guess* is the next recording
  -- before it has actually been recorded/created
  --self._bogus_instrument_idx = nil

  -- set when we have written the bogus note
  -- (cleared after each recording is done)
  --self._bogus_written = false

  -- set this to disable the pattern editor line notifier
  -- (used when writing bogus notes)
  --self._line_notifier_disabled = false

  -- set this to disable the track notifier
  -- (used when switching tracks using the controller)
  self._track_notifier_disabled = false

  -- detect pattern changes
  self._songpos_line = 0

  -- stop recording when stopped
  self._playing = nil

  -- the currently edited pattern index
  self._current_pattern = nil

  -- the various UIComponents
  self._recorders = {}
  self._sliders = {}

  -- maintain track/instrument references here:
  -- _tracks{} -- associative array of RecorderTracks
  self._tracks = {}

  -- apply arguments
  self.options = options
  self:_apply_mappings(mappings)


end

--------------------------------------------------------------------------------

function Recorder:start_app()
  TRACE("Recorder.start_app()")

  if not Application.start_app(self) then
    return
  end

  renoise.app().window.sample_record_dialog_is_visible = false
  self:_attach_to_song(renoise.song())

end

--------------------------------------------------------------------------------

-- periodic updates: this is where we check if any of the watched 
-- properties have changed (most are not observable)

function Recorder:on_idle()

  if (not self.active) then 
    return 
  end

  local playing = renoise.song().transport.playing
  local line =  renoise.song().transport.playback_pos.line
  local patt = renoise.song().patterns[renoise.song().selected_pattern_index]

  -- immediate take?
  if self._immediate_take then
      self._prepare = true
      TRACE("Recorder: start_stop_sample_recording()")
      renoise.song().transport:start_stop_sample_recording()
      self._immediate_take = false
  end

  -- single-pattern take?
  -- skip to finalizing step after a slight delay
  -- (one line) or the recording will be interrupted
  if self._recording 
    and (line>1) then
    if (self._short_take) then
      self._short_take = false
      self:_finalize_recording()
    end
  end
--[[
  if (self._finalizing) then
    if (self.options.writeahead.value==self.WRITEAHEAD_ON) and 
      not (self._bogus_written) then
      local track = self:_get_selected_track()
      if (track) then
        local trigger_mode = self.options.trigger_mode.value
        self:_write_bogus_note(track,trigger_mode)
        self._bogus_written = true
      end
    end
  end
]]
  -- detect when recording is started/done
  if (line<self._songpos_line) then
    if (self._finalizing) then
      -- process recording 
      self._finalizing = false
      self:_process_recording()
    elseif (self._prepare) then
      -- begin recording step
      self._prepare = false
      self._recording = true
    end
  end
  self._songpos_line = line

  if self._post_recording and self._recent_sample then
    self:_do_post_recording()
  end

  -- update slow blinking etc.
  -- stopped mode is special case, will not blink
  local lpb = renoise.song().transport.lpb
  local line_num = (renoise.song().transport.playback_pos.line/lpb)+1
  local blink = (math.floor(line_num%2)==1)
  -- hack#1 for stopped player (always toggle)
  if(not self._playing) then
    blink = (not blink)
  end
  if (blink~=self._blink) then
    self._blink = blink
    -- hack#2 for stopped player (always enable)
    if(not self._playing) then
      blink = true
    end
    -- look for final recording
    --[[
    if self._post_recording and self._recent_sample then
      self:_do_post_recording()
    end
    ]]
    if (self._selected_track) then
      -- blink: ghost sample
      if (self._grid_mode) then
        local track = self:_get_selected_track()
        if (track.has_ghost) and (not self._prepare) then
          local slider = self._sliders[self._selected_track]
          local palette = (blink) 
            and {tip=table.rcopy(self.palette.slider_lit)} 
            or {tip=table.rcopy(self.palette.slider_dimmed)}
          slider:set_palette(palette)
        end
      end
      -- blink: recorder 
      if (self._recording) and (not self._short_take) then
        self._recorders[self._selected_track]:set(blink,true)
      end
    end

  end

  -- update fast blinking
  self._blink_fast = (not self._blink_fast)
  local blink = self._blink_fast
  local process_blink = true
  -- stopped mode is special case, will not blink
  if (playing ~= self._playing) then
    process_blink = true
  elseif (not self._playing) then
    process_blink = false
  end
  if (process_blink) then
    if self._grid_mode and self._prepare then
      local track_idx = self._selected_track
      local track = self._tracks[track_idx]
      local slider = self._sliders[track_idx]
      local palette = (blink) 
        and {tip=table.rcopy(self.palette.slider_lit)} 
        or {tip=table.rcopy(self.palette.slider_dimmed)}
      slider:set_palette(palette)
    end
    if (not self._grid_mode and self._prepare) or
      (self._finalizing) or (self._short_take) then
      self._recorders[self._selected_track]:set(blink,true)
    end
  end
  -- check if playback is stopped
  if (playing ~= self._playing) then
    self._playing = playing
    if (not self._playing) then
      self:_abort_recording()
    end
  end
  -- check if recording dialog has been closed by user
  if (self._selected_track) then
    local track = self:_get_selected_track()
    if (track.has_ghost) and 
      not (renoise.app().window.sample_record_dialog_is_visible) then
      self:_abort_recording()
    end
  end

  -- did we change current_pattern?
  if (self._current_pattern ~= renoise.song().selected_pattern_index) then
    self._current_pattern = renoise.song().selected_pattern_index
  end

end

--------------------------------------------------------------------------------

-- called when a new document becomes available

function Recorder:on_new_document()
  TRACE("Recorder:on_new_document()")

  self:_attach_to_song(renoise.song())

end

--------------------------------------------------------------------------------

-- cancel the current recording
-- removes unreferenced samples, resizes sliders, removes ghost

function Recorder:_abort_recording()
  TRACE("Recorder:_abort_recording()")

  if (self._selected_track) then
    local skip_event = true
    self._recorders[self._selected_track]:set(false,skip_event)
    renoise.app().window.sample_record_dialog_is_visible = false
    self:_remove_ghost(self._selected_track)
    --[[
    if self._bogus_written then
      -- write to the pattern editor 
      -- this should remove bogus note from previous recording process
      local track = self:_get_selected_track()
      self:_write_to_pattern(track,self.options.trigger_mode.value)
    end
    ]]
  end
  
  -- remove unreferenced "samples" (since nothing got recorded)
  for track_idx=1,#self._tracks do
    local track = self._tracks[track_idx]
    if (track) then
      local changed = false
      for idx,sample in ripairs(track.samples) do
        if (not sample.instrument_value) then
          table.remove(track.samples,idx)
          changed = true
        end
      end
      -- resize sliders (except the selected track, which 
      -- already got resized by the "remove_ghost" method)
      if (changed) and (track_idx~=self._selected_track) then
        local slider = self._sliders[track_idx]
        self:_set_slider_size(slider,#track.samples)
      end
    end
  end

  -- get ready for next recording
  self:_reset_flags()

end

--------------------------------------------------------------------------------

-- enter the final stage of the recording
-- grid controllers will allow "bogus note" output while in this stage

function Recorder:_finalize_recording()
  TRACE("Recorder:_finalize_recording()")

  self._recording = false
  self._finalizing = true
  self:_restore_slider_tip(self._selected_track)
  TRACE("Recorder: start_stop_sample_recording()")
  renoise.song().transport:start_stop_sample_recording()

end

--------------------------------------------------------------------------------

-- process the current recording (create sample reference)

function Recorder:_process_recording()
  TRACE("Recorder:_process_recording()")

  -- set recorder button to default state
  local skip_event = true
  local palette = {foreground=table.rcopy(self.palette.recorder_lit)}
  local button = self._recorders[self._selected_track]
  button:set(false,skip_event)
  button:set_palette(palette)
  -- 

  local track_idx = self._selected_track
  local track = self._tracks[track_idx]

  -- create sample reference
  local sample = RecorderSample()
  local recording_index = #track.samples+1
  local sample_name = "Track #%i - Recording #%i"
  sample.name = string.format(sample_name,track_idx,recording_index)
  sample.track = track_idx
  table.insert(track.samples,sample)
  TRACE("Recorder: new recording ready for post - ",sample.name)
  self._recent_sample = sample

  track.has_ghost = false

  -- mark the newly created sample as active
  -- (the slider should already have it as the active index)
  track.selected_sample = #track.samples

  self:_restore_slider_tip(track_idx)

  -- setting the "_post_recording" flag will cause the on_idle loop to
  -- match the name of the resulting recording, and update the reference
  -- note that we can no longer switch the active track, as the sample
  -- reference has now been created
  self._post_recording = true

end

--------------------------------------------------------------------------------

-- final steps for recording: 
-- rename instrument, apply settings, get ready for next recording

function Recorder:_do_post_recording()
  TRACE("Recorder:_do_post_recording()")

  local instr_idx = self:_get_recording_index()
  if not instr_idx then
    print("Message from Recorder: could not locate recorded sample!")
  else
    -- create reference to the sample 
    local track = self:_get_selected_track()
    local count = #track.samples
    local track_idx = self._recent_sample.track
    local track = self._tracks[track_idx]
    local sample = track.samples[count]
    -- remember, zero-based index for instruments
    sample.instrument_value = instr_idx-1
    local real_sample = sample:get_sample()
    local sample_lines = self:get_sample_lines(real_sample)
    -- apply looping mode, beat-sync
    sample:set_loop_mode(self.options.loop_mode.value)
    sample:set_beat_sync(self.options.beat_sync.value,sample_lines)
    sample:set_autoseek_mode(self.options.auto_seek.value)
    -- write to pattern
    self:_write_to_pattern(track,sample_lines)
    -- rename instrument 
    local instr = renoise.song().instruments[instr_idx]
    instr.name = sample.name
    -- increase sample count
    --self._sample_count = self._sample_count+1
    -- select the sample
    track.selected_sample = count
    self:_select_sample(track,instr_idx)

  

    -- ready for next recording
    self:_reset_flags()
    renoise.app().window.sample_record_dialog_is_visible = false

  end


end

--------------------------------------------------------------------------------

-- reset flags/properties, so we're ready to perform another recording

function Recorder:_reset_flags()
  TRACE("Recorder:_reset_flags()")

  self._prepare = false
  self._recording = false
  self._finalizing = false
  self._post_recording = false
  self._immediate_take = false
  self._short_take = false
  self._recent_sample = nil
  --self._bogus_written = false

end

--------------------------------------------------------------------------------

-- add temporary ghost recording to a track:
-- increase the size of the slider by one, set visual state

function Recorder:_add_ghost(track_idx)
  TRACE("Recorder:_add_ghost",track_idx)

  local skip_event = true
  local track = self._tracks[track_idx]
  track.has_ghost = true
  local count = #track.samples
  local slider = self._sliders[track_idx]
  if (self._grid_mode) then
    local palette = (self._blink) 
      and {tip=table.rcopy(self.palette.slider_lit)} 
      or {tip=table.rcopy(self.palette.slider_dimmed)}
    slider:set_palette(palette)
  end
  self:_set_slider_size(slider,count+1)
  slider:set_index(count+1,skip_event)

end


--------------------------------------------------------------------------------

-- remove temporary ghost recording from a track 
-- match the size of the slider to #samples, restore visual state

function Recorder:_remove_ghost(track_idx)
  TRACE("Recorder:_remove_ghost",track_idx)

  local skip_event=true
  local track = self._tracks[track_idx]
  track.has_ghost = false
  local count = #track.samples
  local slider = self._sliders[track_idx]
  self:_set_slider_size(slider,count)
  self:_restore_slider_tip(track_idx)
  slider:set_index((track.selected_sample or 0),skip_event)

end

--------------------------------------------------------------------------------

-- set the slider steps/size to the given value:
-- for grid mode, we expand the physical size of the button array

function Recorder:_set_slider_size(slider,steps)
  TRACE("Recorder:_set_slider_size(",slider,steps,")")

  slider.steps = steps
  if (self._grid_mode) then
    slider:set_size(steps)
  end

end

--------------------------------------------------------------------------------

-- restore slider tip to default state

function Recorder:_restore_slider_tip(track_idx)
  TRACE("Recorder:_restore_slider_tip(",track_idx,")")

  if (self._grid_mode) then
    local slider = self._sliders[track_idx]
    slider:set_palette({tip=table.rcopy(self.palette.slider_lit)})
  end

end 


--------------------------------------------------------------------------------

--  (re)create list of track/instrument references present in the song

function Recorder:_locate_instruments()
  TRACE("Recorder:_locate_instruments")

  self._tracks = table.create()

  -- create basic tracks
  for i=1,self._recorders_count do
    local track = RecorderTrack()
    track.index = i 
    self._tracks[i]=track
  end

  for i,instr in ipairs(renoise.song().instruments) do

    local matches = string.gmatch(instr.name,"[%D]+([%d]+)[%D]+([%d]+)")
    for track_idx,instr_index in matches do
      -- cast to numbers 
      track_idx = (track_idx*1) 
      instr_index = (instr_index*1) 
      -- create tracks 
      local track = self._tracks[track_idx]
      if (not track)then
        track = RecorderTrack()
        track.index = track_idx
        self._tracks[track_idx] = track
      end
      -- create instruments 
      if (not track.samples[instr_index]) then
        local sample = RecorderSample()
        sample.name = instr.name
        sample.track = track_idx
        sample.instrument_value = (i-1) -- zero-based
        track.samples[instr_index] = sample
      end
    end
  end

end


--------------------------------------------------------------------------------

-- adds notifiers to song, set essential values

function Recorder:_attach_to_song(song)
  TRACE("Recorder:_attach_to_song",song)

  if not self._created then
    return
  end

  self:_update_sample_count()
  self:_locate_instruments()
  self:_update_sliders()
  self._playing = renoise.song().transport.playing
  self._current_pattern = renoise.song().selected_pattern_index

  -- update when changing track in Renoise
  song.selected_track_index_observable:add_notifier(
    function()
      TRACE("Recorder:selected_track_observable fired...")

      if not self.active then 
        return false 
      end
      if not self._track_notifier_disabled then
        if (song.selected_track_index ~= self._selected_track) then
          local suppress_action = true
          self:_attempt_track_switch(song.selected_track_index,suppress_action)
        end
      end

    end
  )
  -- update sliders when switching pattern in Renoise
  song.selected_pattern_index_observable:add_notifier(
    function(obj)
      TRACE("Recorder:selected_pattern_index_observable fired...",obj)

      if not self.active then 
        return false 
      end

      self:_update_sliders()
    end
  )
  -- monitor changes to the pattern 
  song.selected_pattern_observable:add_notifier(
    function()
      -- remove existing line notifier (if it exists)
      local patt = song.patterns[self._current_pattern]
      if (song.selected_pattern_index ~= self._current_pattern) and
        (patt:has_line_notifier(self._track_changes,self)) then
        patt:remove_line_notifier(self._track_changes,self)
      end
      self:_attach_line_notifier()
    end
  )

  self:_attach_line_notifier()


end

--------------------------------------------------------------------------------

-- attach line notifier (check for existing notifier first)

function Recorder:_attach_line_notifier()

  local song = renoise.song()
  local patt = song.patterns[song.selected_pattern_index]
  if not (patt:has_line_notifier(self._track_changes,self))then
    patt:add_line_notifier(self._track_changes,self)
  end

end

--------------------------------------------------------------------------------

-- decide if we need to update the display when the pattern editor has changed 
-- note: this method might be called hundreds of times when doing edits like
-- cutting all notes from a pattern, so we need it to be really simple

function Recorder:_track_changes(pos)

  if not self.active then 
    return false 
  end

  if not self._line_notifier_disabled then

    -- respond if the note is in the currently edited track,
    -- in a track that's included in the Recorder, and in the first line
    local skip_event = true
    local track = self._tracks[pos.track]
    if track and (pos.pattern==self._current_pattern) and (pos.line == 1) then
      -- locate the note in the track, then among the references
      track.selected_sample = nil
      --local patt_idx = renoise.song().selected_pattern_index
      local patt = renoise.song().patterns[pos.pattern]
      local note = patt.tracks[pos.track].lines[1].note_columns[1]
      local matched = false
      for k,sample in ipairs(track.samples) do
        -- remember, note indices are zero-based
        if (sample.instrument_value==note.instrument_value) then
          -- we found our active instrument
          track.selected_sample = k
          matched = true
          break
        end
      end
      -- set slider index
      local slider = self._sliders[pos.track]
      if (matched) then
        slider:set_index(track.selected_sample,skip_event)
      else
        slider:set_index(0,skip_event)
      end

    end
  end

end


--------------------------------------------------------------------------------

-- look for the highest internal sample count (instruments with samples that
-- are called "Recorded Sample XX"), and update the internal sample count 

function Recorder:_update_sample_count()
  TRACE("Recorder:_update_sample_count()")

  local num = 0
  for k,v in ipairs(renoise.song().instruments) do
    if (#v.samples>0)then
      local sample_name = v.samples[1].name
      local str = string.sub(sample_name,1,15)
      if (str=="Recorded Sample")then
        local tmp = string.sub(sample_name,17)
        num = math.max(tmp,num)
      end
    end
  end
  TRACE("Recorder:_update_sample_count:",num)

  self._sample_count = num or 0

end


--------------------------------------------------------------------------------

-- look for the newly created sample 
-- @return integer

function Recorder:_get_recording_index()
  TRACE("Recorder:_get_recording_index()")

  self:_update_sample_count()

  -- the name we're looking for
  local lookfor = string.format("Recorded Sample %02d",(self._sample_count))
  for k,v in ipairs(renoise.song().instruments) do
    if(v.name==lookfor) then
      TRACE("Recorder:_get_recording_index:",k)
      return k
    end
  end

end

--------------------------------------------------------------------------------

-- before the instrument has actually been created, we try to guess the index
-- by going through the list of available instruments, starting from the active
-- instrument - any empty instrument will be chosen, otherwise #instruments 
-- @return integer
--[[
function Recorder:_guess_recording_index()
  TRACE("Recorder:_guess_recording_index()")

  local idx = renoise.song().selected_instrument_index
  for i=idx, #renoise.song().instruments do
    local instr = renoise.song().instruments[i]
    if not instr.samples[1].sample_buffer.has_sample_data then
      return i-1
    end
  end
  
  return #renoise.song().instruments

end
]]

--------------------------------------------------------------------------------

-- @return RecorderTrack

function Recorder:_get_selected_track()
  return self._tracks[self._selected_track]
end

--------------------------------------------------------------------------------

-- process user input, contains the logic that control the recording stage
-- @param track (RecorderTrack)
-- @param obj (UISlider)
-- @return false or nil

function Recorder:_process_input(track,obj)
  TRACE("Recorder:_process_input(",track,obj,")")

  local function restore_index()
    if not obj then
      return
    end
    local skip_event = true
    obj:set_index((#track.samples+1),skip_event)
  end

  if self._prepare then

    -- flag as single pattern take
    self._short_take = true
    restore_index()
    return false

  elseif self._finalizing then

    -- output bogus notes while finalizing
    --[[
    self:_write_bogus_note(track,self.options.trigger_mode.value)
    self._bogus_written = true
    ]]

    restore_index()
    return false

  elseif self._recording then

    -- finalize recording
    self:_finalize_recording()
    restore_index()
    return false

  elseif (not self._prepare) 
    and (not self._recording)
    and (not self._finalizing) then

    -- prepare for recording
  TRACE("Recorder:prepare for recording")

    self._prepare = true
    TRACE("Recorder: start_stop_sample_recording()")
    renoise.song().transport:start_stop_sample_recording()
    restore_index()
    return false

  end

end

--------------------------------------------------------------------------------

function Recorder:_select_sample(track,idx)
  TRACE("Recorder:_select_sample(",track,idx,")")

  -- bring focus to the actual instrument
  if (track.samples[idx]) then
    local sample = track.samples[idx]
    if sample then
      local real_index = sample.instrument_value+1
      if (renoise.song().instruments[real_index]) then
        renoise.song().selected_instrument_index = real_index
      end
    end
  end

end

--------------------------------------------------------------------------------

-- called when switching pattern/loading song

function Recorder:_update_sliders()
  TRACE("Recorder:_update_sliders()")

  local skip_event = true

  for slider_idx=1,#self._sliders do

    -- the actual current track
    local track_idx = slider_idx
    local track = self._tracks[track_idx]
    -- no good to do this while recording
    if not (track.has_ghost) then
      local count = #track.samples
      local slider = self._sliders[slider_idx]
      if (count==0) then
        -- the current track has no recordings
        if (self._grid_mode) then
          slider:set_size(0)
        end
        slider:set_index(0,skip_event)
      else
        -- locate the note in the track, then among the references
        track.selected_sample = nil
        local patt_idx = renoise.song().selected_pattern_index
        local patt = renoise.song().patterns[patt_idx]
        local note = patt.tracks[track_idx].lines[1].note_columns[1]
        for k,sample in ipairs(track.samples) do
          -- remember, note indices are zero-based
          if (sample.instrument_value==note.instrument_value) then
            -- we found our active instrument
            track.selected_sample = k
            break
          end
        end
        -- set slider size
        if (track) then
          self:_set_slider_size(slider,count)
        else
          -- outside bounds
          slider:set_size(0)
        end
        -- set slider index
        if (track.selected_sample) then
          slider:set_index(track.selected_sample,skip_event)
        else
          slider:set_index(0,skip_event)
        end

      end

    end
  end

end

--------------------------------------------------------------------------------

-- switch to track: only sequencer tracks are possible targets
-- will also remove ghost track from previous track
-- @suppress_action (boolean, specified when using keyboard to switch tracks)
-- @return boolean (false if not successfull)

function Recorder:_attempt_track_switch(track_idx,suppress_action)
  TRACE("Recorder:_attempt_track_switch(",track_idx,suppress_action,")")

  --local track_idx = idx
  local skip_event = true
  local track = self._tracks[track_idx]
  local track_type = determine_track_type(track_idx)

  -- TODO support "scrolling" tracks 
  if not track then
    return false 
  end

  -- do not allow selecting non-sequencer tracks
  if (track_type~=TRACK_TYPE_SEQUENCER) then
    if not suppress_action then
      local msg = "The Recorder can only record in sequencer-tracks"
      renoise.app():show_status(msg)
    end
    return false 
  end

  if (self._selected_track) and 
      (self._selected_track~=track_idx) then
    self._recorders[self._selected_track]:set(false,skip_event)
    self:_remove_ghost(self._selected_track)
  end
  renoise.song().selected_track_index = track_idx
  self._selected_track = track_idx
  if not track.has_ghost then
    -- do this check to avoid that the sample recorder dialog 
    -- open when we switch tracks using the keyboard
    if suppress_action then
      if not renoise.app().window.sample_record_dialog_is_visible then
        return true
      else
        self:_add_ghost(track_idx)
        self._recorders[track_idx]:set(true,skip_event)
      end
    else
      renoise.app().window.sample_record_dialog_is_visible = true
      self:_add_ghost(track_idx)
    end
  else
    if self._grid_mode then
      -- grid mode: hide recording dialog
      self:_abort_recording()
    else
      -- normal mode: control recording stage
      local return_code = self:_process_input(track)
      return return_code
    end
  end

  return true

end

--------------------------------------------------------------------------------

-- build app
-- @return boolean (false if requirements were not met)

function Recorder:_build_app()
  TRACE("Recorder:_build_app()")

  local cm = self.display.device.control_map

  -- check that all required groups (mappings) exist
  if not (self.mappings.recorders.group_name) or
    not (self.mappings.sliders.group_name) then
    local msg = "One or more required mappings are missing from the" 
    .."Recorder configuration. You need to specify at least the"
    .."'recorders' and 'sliders' mappings"
    renoise.app():show_warning(msg)
    return false
  end

  -- count group sizes
  if (self.mappings.recorders.group_name) then
    self._recorders_count = cm:count_columns(self.mappings.recorders.group_name)
  end
  if (self.mappings.sliders.group_name) then
    self._sliders_count = cm:count_columns(self.mappings.sliders.group_name)
    self._sliders_height = cm:count_rows(self.mappings.sliders.group_name)
    self._grid_mode = cm:is_grid_group(self.mappings.sliders.group_name)
  end

  -- check that all groups have identical size
  if not (self._recorders_count==self._sliders_count) then
    local msg = "Recorder mappings 'recorders' and 'sliders' must have "
              .."exactly the same number of parameters in each group"
    renoise.app():show_warning(msg)
    return false
  end

  -- grid layout: determine y-offset for embedded controls
  -- 1st row: recorder buttons 
  -- 2nd row: track buttons (optional)
  -- remaining space: sliders
  local sliders_y_pos = 1
  if (self._grid_mode) then
    if (self.mappings.recorders.group_name==self.mappings.sliders.group_name) then
        sliders_y_pos = 2
    end
  end

  -- create recorder buttons --------------------------------------------------

  for i=1,self._recorders_count do
    local c = UIToggleButton(self.display)
    c.group_name = self.mappings.recorders.group_name
    c.tooltip = self.mappings.recorders.description
    c:set_pos(i,1)
    c.palette.foreground = table.rcopy(self.palette.recorder_lit)
    c.palette.background = table.rcopy(self.palette.recorder_dimmed)
    c.on_hold = function(obj)
      if not self.active then
        return false
      end

      -- start recording as soon as possible
      if renoise.app().window.sample_record_dialog_is_visible then
        self._immediate_take = true
      end

    end
    c.on_change = function(obj)
      if not self.active then 
        return false 
      end

      -- do not allow switching track while in post-recording stage
      if self._post_recording then
        return false 
      end
      self._track_notifier_disabled = true
      local result = self:_attempt_track_switch(i)
      self._track_notifier_disabled = false
      return result
    end
    self:_add_component(c)
    self._recorders[i] = c
  end

  -- create sample-selecting sliders ------------------------------------------

  for track_idx=1,self._recorders_count do
    local c = UISlider(self.display)
    c.group_name = self.mappings.sliders.group_name
    c.tooltip = self.mappings.sliders.description
    c:set_pos(track_idx,sliders_y_pos)
    c.toggleable = true
    c.flipped = true
    c.ceiling = 1.0
    c.button_mode = self._grid_mode
    c:set_orientation(VERTICAL)
    c.palette.track = table.rcopy(self.palette.slider_dimmed)
    c.palette.background = table.rcopy(self.palette.slider_dimmed)
    if (self._grid_mode) then
      c:set_size(0)
    else
      c:set_size(1)
    end
    c.on_change = function(obj) 

      if not self.active then
        return false
      end

      local track = self._tracks[track_idx]
      local is_current_track = (self._selected_track == track_idx)

      -- only for grid buttons: control recording stage
      if(is_current_track) 
        and (track.has_ghost)
        and (obj.index==0) 
      then
        local return_code = self:_process_input(track,obj)
        if (not return_code) then
          return false
        end
      end

      local sample = track.samples[track.selected_sample]
      local cached_selected_sample = track.selected_sample
      local cached_sample_active = (sample) and sample.active or false
            
      if (obj.index~=0) then
        if (sample) then
          sample.active = true
        end
        --track.selected_sample = math.floor(obj.value+0.5)
        track.selected_sample = obj.index
      else
        if (sample) then
          sample.active = false
        end
      end

      -- if any non-ghost sample is selected, abort the recording
      if (track.has_ghost) then
        self:_abort_recording()
      end

      -- when sample has changed...
      if (cached_selected_sample~=track.selected_sample) or
         (sample and (cached_sample_active~=sample.active))
      then
        self:_select_sample(track,track.selected_sample)
        self:_write_to_pattern(track) 
      end

      return true

    end

    self:_add_component(c)
    self._sliders[track_idx] = c

  end

  -- final steps

  Application._build_app(self)
  return true

end

--------------------------------------------------------------------------------

-- wrapper methods for writing to pattern, will temporarily disable
-- the pattern editor line nofifier
-- @param track (RecorderTrack)
-- @param sample_lines (integer)

function Recorder:_write_to_pattern(track,sample_lines)
  TRACE("Recorder:_write_to_pattern(",track,sample_lines,")")

  -- collect options
  local trigger_mode = self.options.trigger_mode.value
  local autostart = nil
  if (self.options.autostart.value==self.AUTOSTART_OFF) then
    sample_lines = nil -- this will skip autostarting
  elseif (self.options.autostart.value==self.AUTOSTART_LPB) then
    autostart = renoise.song().transport.lpb
  else
    autostart = self.options.autostart.value-2
  end

  -- write to the pattern
  self._line_notifier_disabled = true
  track:write_to_pattern(trigger_mode,sample_lines,autostart)
  self._line_notifier_disabled = false

end

--[[
function Recorder:_write_bogus_note(track,trigger_mode)
  local instr_val = self:_guess_recording_index()
  self._line_notifier_disabled = true
  track:write_bogus_note(instr_val,trigger_mode)
  self._line_notifier_disabled = false
end
]]

--------------------------------------------------------------------------------

-- calculate the number of lines in the current sample, based on the tempo 
-- if the sample is synced to the beat, we use that value instead
-- @return integer

function Recorder:get_sample_lines(sample)
  TRACE("Recorder:get_sample_lines(",sample,")")

  if sample.beat_sync_enabled then      
    return sample.beat_sync_lines 
  end

  local sframes = sample.sample_buffer.number_of_frames
  local bpm = renoise.song().transport.bpm
  local srate = sample.sample_buffer.sample_rate
  local secs = (sframes/srate)
  local ms_per_beat = (bpm/60)
  local lpb = renoise.song().transport.lpb
  -- apply rounding to the final result
  return math.floor((secs*ms_per_beat*lpb)+.5)

end

--==============================================================================

class 'RecorderTrack'

function RecorderTrack:__init()
  TRACE("RecorderTrack:__init()")

  self.index = 1              -- the actual Renoise track index
  self.samples = {}           -- [RecorderSample,RecorderSample,...]
  self.selected_sample = 0    -- the selected RecorderSample index
  self.has_ghost = false      -- true while dialog is "on" this track

end

--------------------------------------------------------------------------------

-- write the note to the currently edited pattern
-- @param trigger_mode (Recorder.CONTINUOUS_MODE_ON/OFF)
-- @param sample_lines (integer) 
-- @param autostart (integer) number of lines to delay autostart

function RecorderTrack:write_to_pattern(trigger_mode,sample_lines,autostart)
  TRACE("RecorderTrack:write_to_pattern(",trigger_mode,sample_lines,autostart,")")

  local continuous_mode = (trigger_mode==1)
  local note_val = 48
  local volume_val = 128
  local track_index = self.index
  local patt_track = renoise.song().selected_pattern.tracks[track_index]
  local note = patt_track:line(1).note_columns[1]
  local fx = patt_track:line(1).effect_columns[1]
  local sample = self.samples[self.selected_sample]
  -- start by clearing pattern
  patt_track:clear()
  if sample and sample.active then
    note.instrument_value = sample.instrument_value
    note.note_value = note_val
    note.volume_value = volume_val
    if continuous_mode then
      fx.number_string = "05"
      fx.amount_string = "00"
    else
      fx.number_string = "00"
      fx.amount_string = "00"
    end
  else
    note.instrument_value = 255 -- EMPTY
    note.note_value = 120       -- OFF
    note.volume_value = 255     -- EMPTY
    fx.number_string = "00"
    fx.amount_string = "00"
  end

  -- hackish way to force new sample to catch up with playback
  -- write a second note a single beat (based on LBP) that is
  -- carefully offset and delayed to match the tempo. It can 
  -- still fail, however, if the tempo is *much* too high...

  -- autostart is only for the post-recording stage
  if not sample_lines then
    return
  end

  -- first check that the line exist at all
  local song_track = renoise.song().tracks[track_index]
  --local insert_line = renoise.song().transport.lpb
  local insert_line = autostart
  if not (patt_track:line(insert_line)) then
    local msg = "Notice: Could not write offset note: pattern is too short"
    print(msg)
    renoise.app():show_status(msg)
    return
  else
    local offset = ((256/sample_lines)*insert_line)
    local divisions = (256/sample_lines)
    -- the delay (insert in previous line if specified)
    local delay =math.floor((offset-math.floor(offset))*256)
    if (delay>0) then
      insert_line = insert_line-1
    end
--[[
print("insert_line",insert_line)
print("offset",offset)
print("sample_lines",sample_lines)
print("delay",delay)
]]
    -- ensure that effect columns and delay are both visible
    song_track.delay_column_visible = true
    song_track.visible_effect_columns = math.max(2,
      song_track.visible_effect_columns)

    local patt_line = insert_line+1
    local note = patt_track:line(patt_line).note_columns[1]
    local fx1 = patt_track:line(patt_line).effect_columns[1]
    local fx2 = patt_track:line(patt_line).effect_columns[2]

    if sample and sample.active then
      note.instrument_value = sample.instrument_value
      note.note_value = note_val
      if (delay>0) then
        note.delay_value = 256-delay
      end
      note.volume_value = volume_val
      if continuous_mode then
        fx1.number_string = "05"
        fx1.amount_string = "00"
      else
        fx1.number_string = "00"
        fx1.amount_string = "00"
      end
      fx2.number_string = "09"
      fx2.amount_string = string.format("%02X",math.floor(math.min(offset,255)))
    else
      note.instrument_value = 255 -- EMPTY
      note.note_value = 121       -- EMPTY
      note.volume_value = 255     -- EMPTY
      note.delay_value = 0  
      fx1.number_string = "00"
      fx1.amount_string = "00"
      fx2.number_string = "00"
      fx2.amount_string = "00"
    end

  end


end

--------------------------------------------------------------------------------

-- write (what we guess is) the next note to the pattern
-- (note that the pattern editor notifier is temporarily disabled before 
-- writing bogus notes, since the instrument is yet-to-be...)
--[[
function RecorderTrack:write_bogus_note(instr_val,trigger_mode)
  TRACE("RecorderTrack:write_bogus_note(",instr_val,trigger_mode,")")

  local continuous_mode = (trigger_mode==1)
  local note_val = 48
  local volume_val = 128
  --local track_index = renoise.song().selected_track_index
  local track_index = self.index
  local real_track = renoise.song().selected_pattern.tracks[track_index]
  local note = real_track:line(1).note_columns[1]
  local fx = real_track:line(1).effect_columns[1]
  note.instrument_value = instr_val
  note.note_value = note_val
  note.volume_value = volume_val
  if continuous_mode then
    fx.number_string = "05"
    fx.amount_string = "00"
  else
    fx.number_string = "00"
    fx.amount_string = "00"
  end

end
]]
--==============================================================================

class 'RecorderSample'

function RecorderSample:__init(note_value,volume_value)

  self.active = true              -- "to output or not"
  self.name = nil                 -- e.g. "Track #1 - Recording #2"
  self.track = nil                -- the RecorderTrack index the sample belongs to
  self.instrument_value = nil     -- instrument index (zero-based)

end

--------------------------------------------------------------------------------

-- set beat sync to active (calculate value), or inactive

function RecorderSample:set_beat_sync(mode,sample_lines)
  TRACE("RecorderSample:set_beat_sync(",mode,")")

  local sample = self:get_sample()
  if (not sample) then
    return
  end

  local active = (mode==1) -- BEAT_SYNC_ON

  if active then
    if (sample_lines>512) then
      -- max beat-sync size is 512, show notice 
      local msg = "Notice: Beat-sync has been disabled for the recording, "
                .."since it exceeds the maximum allowed size of 512 lines"
      print(msg)
      renoise.app():show_status(msg)
      active = false
      sample.beat_sync_lines = 0
    else
      sample.beat_sync_lines = sample_lines 
    end
  end
  sample.beat_sync_enabled = active

end


--------------------------------------------------------------------------------

-- set loop to active (loop entire sample), or disable looping

function RecorderSample:set_loop_mode(mode)
  TRACE("RecorderSample:set_loop_mode(",mode,")")

  local sample = self:get_sample()
  if (not sample) then
    return
  end

  if (mode==1) then
    sample.loop_mode = renoise.Sample.LOOP_MODE_OFF
  else
    local sframes = sample.sample_buffer.number_of_frames
    sample.loop_start = 1
    sample.loop_end = sframes
    if (mode==2) then
      sample.loop_mode = renoise.Sample.LOOP_MODE_FORWARD
    elseif(mode==3)then 
      sample.loop_mode = renoise.Sample.LOOP_MODE_REVERSE
    elseif(mode==4)then 
      sample.loop_mode = renoise.Sample.LOOP_MODE_PING_PONG
    end
  end

end

--------------------------------------------------------------------------------

-- set loop to active (loop entire sample), or disable looping

function RecorderSample:set_autoseek_mode(mode)
  TRACE("RecorderSample:set_loop_mode(",mode,")")

  local sample = self:get_sample()
  if (not sample) then
    return
  end

  if (mode==1) then
    sample.autoseek = true
  else
    sample.autoseek = false
  end

end


--------------------------------------------------------------------------------

function RecorderSample:get_sample()
  return renoise.song().instruments[self.instrument_value+1].samples[1]
end
