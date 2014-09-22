--[[============================================================================
-- Duplex.Application.Recorder 
============================================================================]]--

--[[--
Record and loop any signal that you feed into Renoise, be that your voice, a guitar etc. 
Inheritance: @{Duplex.Application} > Duplex.Application.Recorder 


### Features

* flexible mappings: record using buttons, dials etc.
* loop samples with different lengths, allowing for poly-rhythms.
* supports sessions - restore recorded sessions next song is loaded

### Usage

Recorder operation is designed to be really simple:

* Press a button to select the track and bring up the recording dialog
* Press again to start recording
* Once done, the sample is (optionally) looped/synced to the beat, and you’re then instantly able to switch among this, and all the other recordings you’ve made. 

Note that when reading the following description, and using a controller with faders/dials instead of a (button-based) grid controller, you don’t have “sample slots” that you can press - instead, the recorder button is used for this purpose. But otherwise, the description is pretty much the same. 

 1. *Track select stage*
    Press any recorder button to open/close the recording dialog for the desired 
    track (you can only record into sequencer tracks). When the recording dialog 
    has been opened, a sample slot will start to blink slowly. Press the sample 
    slot to enter the next stage. If your controller supports “hold” events, you 
    can also hold a recorder button for a moment to start recording as soon as 
    possible. 
 
 2. *Preparation stage*
    The preparation stage is the time spent before the playback position enters 
    the beginning of the pattern and begin the actual recording. On the recording 
    dialog it will read “Starting in XX lines...”, and the selected sample slot 
    will be  flashing rapidly. As long as you’re in the preparation stage, you can 
    hit the sample slot again to tell the Recorder that you wish to record only a 
    single pattern (now, both the the recorder button and the sample slot will 
    start flashing rapidly). This is known as a short take, and will take you 
    straight from the preparation stage to the finalizing stage.
 
 3. *Recording stage*
    In the recording stage, you’ll see both the recorder button and the sample 
    slot blinking slowly, in time with the beat. There is no limit to the length 
    of the recording, except of course the amount of RAM you computer has 
    installed, so you can keep it going for as long as you desire. 
    Press the sample slot again to stop the recording and enter the finalizing 
    stage.
 
 4. *Finalizing stage* 
    The finalizing stage is the time spent while recording before the playback 
    reaches the beginning of a pattern. On the recording dialog it will read 
    “Stopping in XX lines...”, and the recording button will be flashing rapidly. 
    While you’re in the finalizing stage, pressing the sample slot will write the 
    yet-to-be sample to the pattern (however, this is only useful if you’ve not 
    enabled the writeahead mode, which does this automatically for you). 
 
 5. *Post-recording stage*
    Immediately after the recording has been made, the resulting sample is 
    automatically renamed, and the recording dialog is closed. We’re ready for 
    another recording. 

> Hint: you can choose another destination track for the recording, or abort the recording at any time. Use the recorder button to select another track, and turn a dial/select an existing sample slot to abort the recording.


### Mappings

  recorders - (UIButton...) toggle recording mode for track X
  sliders   - (UISlider...) sample-select sliders, assignable to grid controller


### Options

  loop_mode     - determine the looping mode of recordings 
  beat_sync     - determine if the recording should be synced to the beat
  autostart     - specify the number of lines for the autostart note
  writeahead    - (obsolete) determine if sample playback should start after each recording
  trigger_mode  - toggle between continuous/05xx, or normal mode
  follow_track  - align with the selected track in Renoise
  page_size     - specify step size when using paged navigation

### Notes

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
  - Due to the way the scripting API works, some notifiers will only work when 
    specific parts of the interface are visible. For example, the Recorder is 
    automatically selecting active recordings as playback is progressing, but we 
    never get the notification that the pattern has changed while in the 
    instrument/sample editor

### Changes

  0.98.28
    - Fixed issue with “autostart” option (broke the recording workflow)

  0.98.18
    - Fixed: under certain conditions, could throw error on startup

  0.98
    - First-run message explaining how to set up a recording
    - Detect v3 API and use alternate FX commands

  0.97
    - Any number of tracks supported, option to follow current track
    - Supports paged navigation features (previous/next, page size)
    - Detect when tracks are inserted/removed/swapped, maintain references

  0.96  
    - Detect when tracks are swapped/inserted/removed
    - Full undo support (tracks changes to pattern and recordings)
    - Unlimited number of tracks (paged navigation)
    - Option: page_size & follow_track

  0.95  
    - First release


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
  follow_track = {
    label = "Follow track",
    description = "Enable this if you want the Recorder to align with " 
                .."\nthe selected track in Renoise",
    on_change = function(inst)
      inst:_follow_track()
    end,
    items = {"Follow track enabled","Follow track disabled"},
    value = 2,
  },
  page_size = {
    label = "Page size",
    description = "Specify the step size when using paged navigation",
    on_change = function(inst)
      --inst:_attach_to_tracks()
    end,
    items = {
      "Automatic: use available width",
      "1","2","3","4",
      "5","6","7","8",
      "9","10","11","12",
      "13","14","15","16",
    },
    value = 1,
  },
  first_run = {
    label = "First run",
    hidden = true,
    description = "First time Recorder is launched, provide instructions",
    items = {
      "On",
      "Off",
    },
    value = 1,
  }
}

Recorder.available_mappings = {
  recorders = {
    description = "Recorder: Toggle recording mode",
  },
  sliders = {
    description = "Recorder: Switch between takes",
  },
}

Recorder.default_palette = {
  background    = { color = {0x00,0x00,0x00}, val = false },
  slider_lit    = { color = {0xff,0xff,0xff}, val = true  },
  slider_dimmed = { color = {0x40,0x40,0x40}, val = false },
  recorder_on   = { color = {0xff,0x40,0x40}, text="●", val = true  },
  recorder_off  = { color = {0x40,0x00,0x00}, text="○", val = false },

}

--------------------------------------------------------------------------------

--- Constructor method
-- @param (VarArg)
-- @see Duplex.Application

function Recorder:__init(...)
  TRACE("Recorder:__init(",...)

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

  self.FIRST_RUN_ON = 1
  self.FIRST_RUN_OFF = 2

  self.FOLLOW_TRACK_ON = 1
  self.FOLLOW_TRACK_OFF = 2

  self.TRACK_PAGE_AUTO = 1

  -- true if sliders are made from buttons
  self._grid_mode = false

  -- in grid mode, this is set to the slider height
  self._sliders_height = 1
  
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

  -- blinking bools
  self._blink = false
  self._blink_fast = false

  -- internal sample counter (+1 for each "Recorded Sample")
  self._sample_count = nil

  -- set this to disable the pattern editor line notifier
  self._line_notifier_disabled = false

  -- update everything on the next idle loop:
  -- set when tracks are swapped/removed/inserted,
  -- when we enter a new page or create a new song
  self._update_requested = false

  -- keep track of position within pattern
  self._songpos_line = 0

  -- stop recording when playback is stopped
  self._playing = nil

  -- the currently edited pattern index
  self._current_pattern = nil

  -- for keeping track of paged navigation
  self._track_offset = 0
  self._track_page = nil

  -- the currently selected track
  -- (don't confuse with renoise's selected_track)
  self._active_track_idx = nil

  -- the active control index 
  self._active_control_idx = nil

  -- the various UIComponents
  self._controls = {}
  self._controls.buttons = {}
  self._controls.sliders = {}

  -- maintain track/instrument references here
  self._tracks = {}

  -- keep reference to browser process, or we couldn't 
  -- set options while running (used by first_run) 
  self.recorder_process = select(1,...)

  Application.__init(self,...)

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.start_app
-- @return bool or nil

function Recorder:start_app()
  TRACE("Recorder.start_app()")

  if not Application.start_app(self) then
    return
  end

  renoise.app().window.sample_record_dialog_is_visible = false
  self:_attach_to_song(renoise.song())

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_idle

function Recorder:on_idle()
  --TRACE("Recorder:on_idle()")

  if (not self.active) then 
    return 
  end

  local playing = renoise.song().transport.playing
  local line =  renoise.song().transport.playback_pos.line
  local patt = renoise.song().patterns[renoise.song().selected_pattern_index]

  -- do we need to perform a complete refresh? 
  if(self._update_requested) then
    self._update_requested = false
    self:_update_all()
  end

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

    if (self._active_track_idx) then
      -- blink: ghost sample
      if (self._grid_mode) then
        local track = self._tracks[self._active_track_idx]
        if track and 
            track.has_ghost and 
            not self._prepare then
          if self._active_control_idx then
            local slider = self._controls.sliders[self._active_control_idx]
            if blink then
              slider:set_palette({tip=self.palette.slider_lit})
            else
              slider:set_palette({tip=self.palette.background})
            end
          end
        end
      end
      -- blink: recorder 
      if self._active_control_idx 
        and self._recording 
        and not self._short_take 
      then
        local button = self._controls.buttons[self._active_control_idx]
        if blink then
          button:set(self.palette.recorder_on)
        else
          button:set(self.palette.recorder_off)
        end
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
    if self._grid_mode 
        and self._prepare then
      local track_idx = self._active_track_idx
      local track = self._tracks[track_idx]
      if self._active_control_idx then
        local slider = self._controls.sliders[self._active_control_idx]
        if blink then
          slider:set_palette({tip=self.palette.slider_lit})
        else
          slider:set_palette({tip=self.palette.background})
        end
      end
    end
    if self._active_control_idx then 
      if (not self._grid_mode and self._prepare) or
        (self._finalizing) or (self._short_take) then
        local button = self._controls.buttons[self._active_control_idx]
        if blink then
          button:set(self.palette.recorder_on)
        else
          button:set(self.palette.recorder_off)
        end
      end
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
  if (self._active_track_idx) then
    local track = self._tracks[self._active_track_idx]
    if track and track.has_ghost and 
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

--- inherited from Application
-- @see Duplex.Application.on_new_document

function Recorder:on_new_document()
  TRACE("Recorder:on_new_document()")

  self:_attach_to_song(renoise.song())

end

--------------------------------------------------------------------------------

-- cancel the current recording
-- removes unreferenced samples, resizes sliders, removes ghost

function Recorder:_abort_recording()
  TRACE("Recorder:_abort_recording()")


  -- remove unreferenced "samples" 
  -- 1. because nothing got recorded (we aborted)
  -- 2. because we might just have deleted the take
  for track_idx=1,#self._tracks do
    local track = self._tracks[track_idx]
    if (track) then
      local changed = false
      for idx,sample in ripairs(track.samples) do
        if not sample or not sample.instrument_value then
          table.remove(track.samples,idx)
          changed = true
        end
      end
      -- resize sliders (except the selected track, which 
      -- already got resized by the "remove_ghost" method)
      TRACE("track_idx,self._active_track_idx",track_idx,self._active_track_idx)
      if changed and 
          (track_idx~=self._active_track_idx) then
        local control_idx = self:_get_control_idx(track_idx)
        self:_set_slider_steps(control_idx,#track.samples)
      end
    end
  end

  if (self._active_track_idx) then
    if self._active_control_idx then
      local button = self._controls.buttons[self._active_control_idx]
      button:set(self.palette.recorder_off)
    end
    renoise.app().window.sample_record_dialog_is_visible = false
    self:_remove_ghost(self._active_track_idx)
  end
  
  -- get ready for next recording
  self:_reset_flags()

end

--------------------------------------------------------------------------------

-- enter the final stage of the recording

function Recorder:_finalize_recording()
  TRACE("Recorder:_finalize_recording()")

  self._recording = false
  self._finalizing = true
  self:_restore_slider_tip(self._active_track_idx)
  TRACE("Recorder: start_stop_sample_recording()")
  renoise.song().transport:start_stop_sample_recording()

end

--------------------------------------------------------------------------------

-- process the current recording (create sample reference)

function Recorder:_process_recording()
  TRACE("Recorder:_process_recording()")

  -- set recorder button to default state
  if self._active_control_idx then
    local button = self._controls.buttons[self._active_control_idx]
    button:set(self.palette.recorder_off)
  end

  local track_idx = self._active_track_idx
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
    LOG("Message from Recorder: could not locate recorded sample!")
  else
    -- create reference to the sample 
    local track = self._tracks[self._active_track_idx]
    local count = #track.samples
    local track_idx = self._recent_sample.track
    local track = self._tracks[track_idx]
    local sample = track.samples[count]
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

end

--------------------------------------------------------------------------------

-- @return bool, true when one of the recorder-tracks have a ghost

function Recorder:_has_ghost()

  for k,v in ipairs(self._tracks) do
    if v and v.has_ghost then
      return true
    end
  end
  return false 

end

--------------------------------------------------------------------------------

-- add temporary ghost recording to a track:
-- increase the size of the slider by one, set visual state
-- @param track_idx (int)

function Recorder:_add_ghost(track_idx)
  TRACE("Recorder:_add_ghost(",track_idx,")")

  local skip_event = true
  local track = nil
  if not self._tracks[track_idx] then
    self:_create_track(track_idx)
  end
  track = self._tracks[track_idx]
  track.has_ghost = true
  -- update display only if within range
  local control_idx = self:_get_control_idx(track_idx)
  if control_idx then
    local count = #track.samples
    local slider = self._controls.sliders[control_idx]
    if (self._grid_mode) then
      if self._blink then
        slider:set_palette({tip=self.palette.slider_lit})
      else
        slider:set_palette({tip=self.palette.background})
      end

    end
    self:_set_slider_steps(control_idx,count+1)
    slider:set_index(count+1,skip_event)
  end

end


--------------------------------------------------------------------------------

-- remove temporary ghost recording from a track 
-- match the size of the slider to #samples, restore visual state
-- @param track_idx (int)

function Recorder:_remove_ghost(track_idx)
  TRACE("Recorder:_remove_ghost",track_idx)

  local skip_event=true
  local control_idx = self:_get_control_idx(track_idx)
  local track = self._tracks[track_idx]
  if track then
    track.has_ghost = false
    local count = #track.samples
    if control_idx then
      local slider = self._controls.sliders[control_idx]
      self:_set_slider_steps(control_idx,count)
      self:_restore_slider_tip(track_idx)
      slider:set_index((track.selected_sample or 0),skip_event)
    end
  end
end

--------------------------------------------------------------------------------

function Recorder:_create_track(track_idx)
  TRACE("Recorder:_create_track(",track_idx,")")
    local track = RecorderTrack()
    track.index = track_idx
    self._tracks[track_idx]=track
end

--------------------------------------------------------------------------------

-- set number of slider steps to the provided value
-- (for grid mode, expand the unit size as well...)
-- @param control_idx (int)
-- @param steps (int), 0=hide slider

function Recorder:_set_slider_steps(control_idx,steps)
  TRACE("Recorder:_set_slider_steps(",control_idx,steps,")")

  local slider = self._controls.sliders[control_idx]

  assert(slider, 
    "Internal Error. Please report: missing slider component")

  if (self._grid_mode) then
    --print("*** old, new step size",slider.steps,steps)
    slider:set_size(steps)
  elseif (steps==0) then
    -- since dials doesn't support zero steps...
    slider.steps = 1
    slider:set_index(0,true)
  else
    slider.steps = steps
  end

end

--------------------------------------------------------------------------------

-- restore slider tip to default (lit) state 

function Recorder:_restore_slider_tip(track_idx)
  TRACE("Recorder:_restore_slider_tip(",track_idx,")")

  local control_idx = self:_get_control_idx(track_idx)
  if self._grid_mode and
      control_idx then
    local slider = self._controls.sliders[control_idx]
    slider:set_palette({tip=self.palette.slider_lit})
  end
end 


--------------------------------------------------------------------------------

-- (re)create instrument references in the song
-- (stores the result in the table _tracks) 

function Recorder:_locate_instruments()
  TRACE("Recorder:_locate_instruments")

  self._tracks = table.create()

  for i,instr in ipairs(renoise.song().instruments) do

    local matches = string.gmatch(instr.name,"[%D]+([%d]+)[%D]+([%d]+)")
    for track_idx,instr_index in matches do
      track_idx = tonumber(track_idx) 
      instr_index = tonumber(instr_index) 
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
  self._playing = renoise.song().transport.playing
  self._current_pattern = renoise.song().selected_pattern_index

  -- when switching pattern in Renoise
  song.selected_pattern_index_observable:add_notifier(
    function(obj)
      TRACE("Recorder:selected_pattern_index_observable fired...",obj)

      if not self.active then 
        return false 
      end

      --self:_update_all()
      self._update_requested = true
    end
  )
  -- when changing track in Renoise
  song.selected_track_index_observable:add_notifier(
    function()
      TRACE("Recorder:selected_track_observable fired...")

      if not self.active then 
        return false 
      end

      -- if page has changed, this will update the display
      self:_follow_track()

    end
  )
  -- when inserting/deleting/swapping tracks
  song.tracks_observable:add_notifier(
    function(obj)
      TRACE("Recorder:tracks_observable fired...")

      local ghost_idx = nil

      if(obj.type=="insert")then

        local copy = false
        for i = #renoise.song().tracks,obj.index,-1 do
          if(self._tracks[i])then
            copy = true
          end
          if copy and self._tracks[i] then
            self._tracks[i].index = i+1
            self._tracks[i+1] = self._tracks[i]
            self._tracks[i+1]:_rename_samples(i+1)
            if self._tracks[i+1].has_ghost then
              ghost_idx = i+1
            end
            self._tracks[i] = nil

          end
        end
        -- "insert" can also be invoked when undoing 
        -- so we recreate the list of recordings
        self:_locate_instruments()

      elseif(obj.type=="remove")then

        local copy = false
        for i = obj.index,#renoise.song().tracks do
          if(self._tracks[i])then
            copy = true
          end
          if copy and self._tracks[i] then
            if (i==obj.index+self._track_offset) then
              -- orphan current track
              self._tracks[i]:_rename_samples()
              self._tracks[i] = nil
              if (i==self._active_track_idx) then
                self:_set_active_track(nil)
              end
            else
              self._tracks[i].index = i-1
              self._tracks[i-1] = self._tracks[i]
              self._tracks[i-1]:_rename_samples(i-1)
              if self._tracks[i-1].has_ghost then
                ghost_idx = i-1
              end
              self._tracks[i] = nil
            end
          end
        end

      elseif(obj.type=="swap")then

        if self._tracks[obj.index1] and self._tracks[obj.index2] then
          --print("swap existing record-tracks",obj.index1,obj.index2)
          self._tracks[obj.index1],self._tracks[obj.index2] =
            self._tracks[obj.index2],self._tracks[obj.index1]
          self._tracks[obj.index1].index = obj.index1
          self._tracks[obj.index2].index = obj.index2
          self._tracks[obj.index1]:_rename_samples(obj.index1)
          self._tracks[obj.index2]:_rename_samples(obj.index2)
          if self._tracks[obj.index1].has_ghost then
            ghost_idx = obj.index1
          elseif self._tracks[obj.index2].has_ghost then
            ghost_idx = obj.index2
          end
        elseif self._tracks[obj.index1] then
          --print("swap existing with non-existing 1",obj.index1,obj.index2)
          self._tracks[obj.index2] = self._tracks[obj.index1]
          self._tracks[obj.index2].index = obj.index2
          self._tracks[obj.index2]:_rename_samples(obj.index2)
          if self._tracks[obj.index1].has_ghost then
            ghost_idx = obj.index2
          end
          self._tracks[obj.index1] = nil
        elseif self._tracks[obj.index2] then
          --print("swap existing with non-existing 2",obj.index1,obj.index2)
          self._tracks[obj.index1] = self._tracks[obj.index2]
          self._tracks[obj.index1].index = obj.index1
          self._tracks[obj.index1]:_rename_samples(obj.index1)
          if self._tracks[obj.index2].has_ghost then
            ghost_idx = obj.index1
          end
          self._tracks[obj.index2] = nil
        end

      end

      -- a ghost track was affected?
      if ghost_idx then
        if not self._tracks[ghost_idx] then
          self:_create_track(ghost_idx)
        end
        --print("about to set ghost as active track",ghost_idx)
        self:_set_active_track(ghost_idx)
        self._tracks[ghost_idx].has_ghost = true

      end

      -- update on next idle loop, as we won't be able to  
      -- detect changed content in the pattern right away
      self._update_requested = true

    end
  
  )
  -- monitor changes to the pattern's content
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
  self._update_requested = true
  self:_follow_track()

end

--------------------------------------------------------------------------------

-- when following the active track in Renoise, we call this method
-- it will refresh the display when the track page has changed

function Recorder:_follow_track()
  TRACE("Recorder:_follow_track()")

  if (self.options.follow_track.value == self.FOLLOW_TRACK_OFF) then
    return
  end
  local song = renoise.song()
  local track_idx = song.selected_track_index
  local page = self:_get_track_page(track_idx)
  if (page~=self._track_page) then
    self._track_page = page
    self._track_offset = (page-1)*self:_get_page_width()
    self._active_control_idx = self:_get_control_idx(self._active_track_idx)
    self._update_requested = true

  end

end

--------------------------------------------------------------------------------

function Recorder:_get_track_page(track_idx)
  local page_width = self:_get_page_width()
  return math.ceil(track_idx/page_width)
end

--------------------------------------------------------------------------------

function Recorder:_get_page_width()
  return (self.options.page_size.value==self.TRACK_PAGE_AUTO)
    and #self._controls.sliders or self.options.page_size.value-1
end

--------------------------------------------------------------------------------

-- attach line notifier (check for existing notifier first)

function Recorder:_attach_line_notifier()
  TRACE("Recorder:_attach_line_notifier()")

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

    TRACE("Recorder:_track_changes()",pos.pattern,pos.track,pos.line)

    local track = self._tracks[pos.track]
    -- respond if the note located in the currently edited track,
    -- and the track is a recorder-track
    if track and 
      (pos.pattern==self._current_pattern) and 
      (pos.line == 1) 
    then
      self:_update_selected_sample(track,pos.pattern)
    end
  end

end

--------------------------------------------------------------------------------

-- locate the note in the pattern-track, and select it (if present)
-- @param track (RecorderTrack)
-- @param patt_idx (int), the desired pattern to check

function Recorder:_update_selected_sample(track,patt_idx)
  TRACE("Recorder:_update_selected_sample()",track,patt_idx)

  track.selected_sample = nil
  local skip_event = true
  local patt = renoise.song().patterns[patt_idx]
  local track_type = determine_track_type(track.index)
  if (track_type==renoise.Track.TRACK_TYPE_SEQUENCER) then
    local note = patt.tracks[track.index].lines[1].note_columns[1]
    for k,sample in ipairs(track.samples) do
      if (sample.instrument_value==note.instrument_value) then
        track.selected_sample = k
        break
      end
    end
  end
  -- set slider index
  local page_width = self:_get_page_width()
  local control_idx = self:_get_control_idx(track.index)
  if control_idx then
    local slider = self._controls.sliders[control_idx]
    if (track.selected_sample) then
      slider:set_index(track.selected_sample,skip_event)
    else
      slider:set_index(0,skip_event)
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
        local tmp = tonumber(string.sub(sample_name,17))
        if tmp then
          num = math.max(tmp,num)
        end
      end
    end
  end

  self._sample_count = num or 0

end


--------------------------------------------------------------------------------

-- look for the newly created sample 
-- @return int

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

-- supplied with a track index, this method will return the control index 
-- @param track_idx (int)
-- @return int or nil if the control is outside the visible range

function Recorder:_get_control_idx(track_idx)
  TRACE("Recorder:_get_control_idx(",track_idx,")")

  if not track_idx then
    return nil
  end

  local width = #self._controls.sliders

  if ((self._track_offset+width)<track_idx) then
    --print("above visible range")
    return nil
  elseif(self._track_offset>=track_idx) then
    --print("below visible range")
    return nil
  end

  local idx = (track_idx-self._track_offset)%width
  return (idx==0) and width or idx


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
    local idx = #track.samples+1
    local skip_event = true
    obj:set_size(idx)
    obj:set_index(idx,skip_event)
  end

  if self._prepare then

    -- flag as single pattern take
    self._short_take = true
    restore_index()
    return false

  elseif self._finalizing then

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
    if sample and sample.instrument_value then
      local real_index = sample.instrument_value+1
      if (renoise.song().instruments[real_index]) then
        renoise.song().selected_instrument_index = real_index
      end
    end
  end

end

--------------------------------------------------------------------------------

-- update all components 

function Recorder:_update_all()
  TRACE("Recorder:_update_all()")

  if (not self.active) then
    return false
  end

  local page_width = self:_get_page_width()
  local page_width = self:_get_page_width()
  local track_idx = renoise.song().selected_track_index 

  for control_idx=1,#self._controls.sliders do
    local button = self._controls.buttons[control_idx]
    local slider = self._controls.sliders[control_idx]
    local track_idx = control_idx+self._track_offset
    local track = self._tracks[track_idx]
    local track_type = determine_track_type(track_idx)
    if (track_type == renoise.Track.TRACK_TYPE_SEQUENCER) then
      if (track) then
        -- an active recorder track
        -- set number of steps
        local count = #track.samples
        self:_set_slider_steps(control_idx,count)
        if not (track.has_ghost) then
          --print("*** about to remove ghost with track idx",track_idx)
          self:_remove_ghost(track_idx)
          if (count~=0) then
            local patt_idx = renoise.song().selected_pattern_index
            self:_update_selected_sample(track,patt_idx)
          end
        else
          self:_add_ghost(track_idx)
        end
      else
        -- not a recorder-track 
        self:_set_slider_steps(control_idx,0)
      end
      -- update button state 
      local has_ghost = false
      if track and track.has_ghost then
        has_ghost = true
      end
      local button_state = (track_idx==self._active_track_idx) and has_ghost
      if button_state then
        button:set(self.palette.recorder_on)
      else
        button:set(self.palette.recorder_off)
      end
    else
      -- out of bounds
      self:_set_slider_steps(control_idx,0)
      button:set(self.palette.background)
    end

  end

end

--------------------------------------------------------------------------------

-- switch to track: only sequencer tracks are possible targets
-- - will move ghost track from previous track to current, or create it
-- @param track_idx (int)
-- @return bool - true if switched, false if not

function Recorder:_attempt_track_switch(track_idx)
  TRACE("Recorder:_attempt_track_switch(",track_idx,")")

  local track = self._tracks[track_idx]
  local track_type = determine_track_type(track_idx)

  -- do not allow selecting non-sequencer tracks
  if (track_type~=renoise.Track.TRACK_TYPE_SEQUENCER) then
    local msg = "The Recorder can only record in sequencer-tracks"
    renoise.app():show_status(msg)
    return false 
  end

  -- remove ghost from previous track
  if (self._active_track_idx) then
    if (self._active_track_idx~=track_idx) then
      local control_idx = self:_get_control_idx(self._active_track_idx)
      local button = self._controls.buttons[control_idx]
      if control_idx then
        button:set(self.palette.recorder_off)
      end
      self:_remove_ghost(self._active_track_idx)
    end
  end

  self:_set_active_track(track_idx)

  if not track or not track.has_ghost then
    renoise.app().window.sample_record_dialog_is_visible = true
    self:_add_ghost(track_idx)

    if (self.options.first_run.value==self.FIRST_RUN_ON) then
      local msg = "IMPORTANT ONE-TIME MESSAGE FROM DUPLEX RECORDER"
                .."\n"
                .."\nPlease ensure that the recording dialog in Renoise is set to "
                .."\ncreate instruments on each take, synced to the pattern length"
                .."\n"
                .."\nThanks!"
      renoise.app():show_message(msg)
      self:_set_option("first_run",self.FIRST_RUN_OFF,self.recorder_process)
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

--- set the active track
-- @param track_idx (int)

function Recorder:_set_active_track(track_idx)
  TRACE("Recorder:_set_active_track(",track_idx,")")

  self._active_track_idx = track_idx
  self._active_control_idx = self:_get_control_idx(track_idx)

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application._build_app
-- @return bool

function Recorder:_build_app()
  TRACE("Recorder:_build_app()")

  local cm = self.display.device.control_map
  local button_count,slider_count

  -- check that all required groups (mappings) exist
  if not (self.mappings.recorders.group_name) or
    not (self.mappings.sliders.group_name) then
    local msg = "One or more required mappings are missing from the" 
    .."Recorder configuration. You need to specify at least the"
    .."'recorders' and 'sliders' mappings"
    renoise.app():show_warning(msg)
    return false
  end

  -- check that groups have an identical size
  if (self.mappings.recorders.group_name) then
    button_count = cm:count_columns(self.mappings.recorders.group_name)
  end
  if (self.mappings.sliders.group_name) then
    slider_count = cm:count_columns(self.mappings.sliders.group_name)
    self._sliders_height = cm:count_rows(self.mappings.sliders.group_name)
    self._grid_mode = cm:is_grid_group(self.mappings.sliders.group_name)
  end
  if not (button_count==slider_count) then
    local msg = "Recorder mappings 'recorders' and 'sliders' must have "
              .."exactly the same number of parameters in each group"
    renoise.app():show_warning(msg)
    return false
  end

  -- grid layout: determine y-offset for embedded controls
  local sliders_y_pos = 1
  if (self._grid_mode) then
    if (self.mappings.recorders.group_name==self.mappings.sliders.group_name) then
        sliders_y_pos = 2
    end
  end

  -- create recorder buttons --------------------------------------------------

  for i=1,button_count do
    local c = UIButton(self)
    c.group_name = self.mappings.recorders.group_name
    c.tooltip = self.mappings.recorders.description
    c:set_pos(i,1)
    c:set(self.palette.recorder_off)
    c.on_hold = function(obj)
      -- start recording as soon as possible
      if renoise.app().window.sample_record_dialog_is_visible then
        self._immediate_take = true
      end

    end
    c.on_press = function(obj)
      -- do not allow switching track while in post-recording stage
      if self._post_recording then
        return  
      end
      local track_idx = i+self._track_offset
      if (self:_attempt_track_switch(track_idx)) then
        self:_update_all()
      end

    end
    self._controls.buttons[i] = c
  end

  -- create sample-selecting sliders ------------------------------------------

  local map = self.mappings.sliders
  for i=1,button_count do
    local c = UISlider(self,map)
    c.group_name = self.mappings.sliders.group_name
    c.tooltip = self.mappings.sliders.description
    c:set_pos(i,sliders_y_pos)
    c.toggleable = false
    c.flipped = true
    c:set_palette({track=self.palette.slider_dimmed,background=self.palette.slider_dimmed})
    c.ceiling = 1.0
    c:set_index(0,true)
    c:set_orientation(ORIENTATION.VERTICAL)
    if (self._grid_mode) then
      c:set_size(0)
    else
      c:set_size(1)
    end
    c.on_change = function(obj) 

      --print("self._controls.sliders[",i,"].on_change")

      local track_idx = i+self._track_offset
      local track = self._tracks[track_idx]

      if not track then
        return false
      end

      local is_current_track = (self._active_track_idx == track_idx)

      if self._grid_mode and
        is_current_track and
        track.has_ghost and
        (obj.index==obj._size) 
      then
        -- only for grid buttons: control recording stage
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
        track.selected_sample = obj.index
      else
        if (sample) then
          sample.active = false
        end
      end

      -- if a sample is selected, abort recording
      if (track.has_ghost) then
        self:_abort_recording()
      end

      -- when sample has changed, update the pattern
      if (cached_selected_sample~=track.selected_sample) or
          (sample and (cached_sample_active~=sample.active)) then
        self:_select_sample(track,track.selected_sample)
        self:_write_to_pattern(track) 
      end

      return true

    end

    self._controls.sliders[i] = c

  end

  -- final steps

  Application._build_app(self)
  return true

end

--------------------------------------------------------------------------------

-- wrapper methods for writing to pattern, will temporarily disable
-- the pattern editor line nofifier
-- @param track (RecorderTrack)
-- @param sample_lines (int)

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

--------------------------------------------------------------------------------

-- calculate the number of lines in the current sample, based on the tempo 
-- if the sample is synced to the beat, we use that value instead
-- @return int

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

  -- effect commands depend on API version
  local api_version = renoise.API_VERSION
  if (api_version>=3) then
    self.GLIDE_NUM_VALUE = 16
    self.OFFSET_NUM_VALUE = 28
  elseif (api_version>=2) then
    self.GLIDE_NUM_VALUE = 5
    self.OFFSET_NUM_VALUE = 9
  end


end

--------------------------------------------------------------------------------

-- write the note to the currently edited pattern
-- @param trigger_mode (Recorder.CONTINUOUS_MODE_ON/OFF)
-- @param sample_lines (int) 
-- @param autostart (int) number of lines to delay autostart

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
      fx.number_value = self.GLIDE_NUM_VALUE
    else
      fx.number_value = 0
    end
    fx.amount_value = 0
    --[[
  else
    note.instrument_value = 255 -- EMPTY
    note.note_value = 120       -- OFF
    note.volume_value = 255     -- EMPTY
    --fx.number_string = "00"
    --fx.amount_string = "00"
    fx.number_value = 0
    fx.amount_value = 0
    ]]

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
  local insert_line = autostart
  if not (patt_track:line(insert_line)) then
    local msg = "Notice: Could not write offset note: pattern is too short"
    LOG(msg)
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
        fx1.number_value = self.GLIDE_NUM_VALUE
      else
        fx1.number_value = 0
      end
      fx1.amount_value = 0
      fx2.number_value = self.OFFSET_NUM_VALUE
      fx2.amount_value = math.floor(math.min(offset,255))
    else
      --[[
      note.instrument_value = 255 -- EMPTY
      note.note_value = 121       -- EMPTY
      note.volume_value = 255     -- EMPTY
      note.delay_value = 0  
      fx1.number_string = "00"
      fx1.amount_string = "00"
      fx2.number_string = "00"
      fx2.amount_string = "00"
      ]]
      note:clear()
      fx1:clear()
      fx2:clear()
    end

  end


end


--------------------------------------------------------------------------------

-- recordings are automatically renamed when tracks are moved around
-- @param idx (int), track index - leave out to rename as "N/A"

function RecorderTrack:_rename_samples(idx)
  TRACE("Recorder:_rename_samples()",idx)

  for k,sample in ipairs(self.samples) do
    sample.name = string.gsub(sample.name,"%d+",function(w) 
      return idx or "N/A"
    end,1)
    local instr = renoise.song().instruments[sample.instrument_value+1]
    if instr then
      instr.name = sample.name
    end
  end

end

--------------------------------------------------------------------------------

function RecorderTrack:__tostring()
  return type(self)

end  


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

--------------------------------------------------------------------------------

function RecorderSample:__tostring()
  return type(self)
end  

