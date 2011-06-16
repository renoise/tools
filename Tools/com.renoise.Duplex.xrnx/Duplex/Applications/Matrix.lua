--[[----------------------------------------------------------------------------
-- Duplex.Matrix
-- Inheritance: Application > Matrix
----------------------------------------------------------------------------]]--

--[[

About

  This application will take control of the pattern matrix in Renoise 
  Apart from the matrix itself, it has controls for navigating the matrix
  ("sequence"/"track") and a number of pattern triggers ("triggers")

How to use

  - Hit matrix buttons to mute/unmute track slots, hold button to focus
  - Navigation features (page up/down/left/right), when song follow is on, 
    the matrix will automatically display the currently playing page
  - Depending on hardware capabilities, the matrix sequence can control both
    the pattern-loop range and the playback position (SEQUENCE_MODE). See also 
    the tutorial video located at http://www.youtube.com/watch?v=K_kCaYV_T78


Mappings

  matrix    - (UIToggleButton...) toggle slot muted state
  triggers  - (UISlider) sequence pattern-triggers
  sequence  - (UISpinner) control visible sequence page 
  track     - (UISpinner) control visible track page


Options

  play_mode     - what to do when triggered
  switch_mode   - what to do when switching pattern
  bounds_mode   - what to do when pressing "outside bounds"
  sequence_mode - determine the pattern-trigger mode
  follow_track  - align with the selected track in Renoise
  page_size     - specify step size when using paged navigation

Changes (equal to Duplex version number)

  0.95  - Added changelog, more thourough documentation

  0.93  - Inclusion of UIButtonStrip for more flexible control of playback-pos
        - Utilize "blinking" feature to display a scheduled pattern
        - "follow_player" mode in Renoise will update the matrix immediately

  0.92  - Removed the destroy_app() method (not needed anymore)
        - Assign tooltips to the virtual control surface

  0.91  - All mappings are now without dependancies (no more "required" groups)

  0.81  - First release

--]]


--==============================================================================


class 'Matrix' (Application)

Matrix.default_options = {
  play_mode = {
    label = "Playback start",
    description = "What to do when playback is started (or re-started)",
    items = {
      "Play/continue",
      "Toggle start & stop",
      "Retrigger pattern",
      "Schedule pattern"
    },
    value = 3,
  },
  switch_mode = {
    label = "Switch pattern",
    description = "What to do when switching from one pattern to another",
    items = {
      "Stop playback",
      "Switch instantly",
      "Trigger pattern",
      "Schedule pattern"
    },
    value = 2,
  },
  bounds_mode = {
    label = "Out of bounds",
    description = "What to do when a position outside the song is triggered",
    items = {
      "Stop playback",
      "Do nothing"
    },
    value = 2,
  },
  follow_track = {
    label = "Follow track",
    description = "Enable this if you want the Matrix to align with " 
                .."\nthe selected track in Renoise",
    on_change = function(inst)
      inst:_follow_track()
    end,
    items = {
      "Follow track enabled",
      "Follow track disabled"
    },
    value = 2,
  },
  --[[
  set_track = {
    label = "Set track",
    description = ""
  }
  ]]
  page_size = {
    label = "Page size",
    description = "Specify the step size when using paged navigation",
    on_change = function(inst)
      inst:_update_track_count()
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
  sequence_mode = {
    label = "Pattern-trigger",
    description = "Determines how pattern triggers work: "
                .."\nSelect 'Position only' for controllers that does not" 
                .."\nsupport the release event. Select 'Position & Loop'"
                .."\nif your controller supports the release event, and you" 
                .."\nwant to be able to control the looped range",
    on_change = function(inst)
      inst:_set_trigger_mode()
    end,
    items = {"Position + PatternLoop","Position only"},
    value = 1,
  }

}

function Matrix:__init(display,mappings,options,config_name)
  TRACE("Matrix:__init(",display,mappings,options,config_name)

  -- define the options (with defaults)

  self.PLAY_MODE_PLAY = 1
  self.PLAY_MODE_TOGGLE = 2
  self.PLAY_MODE_RETRIG = 3
  self.PLAY_MODE_SCHEDULE = 4

  self.SWITCH_MODE_STOP = 1
  self.SWITCH_MODE_SWITCH = 2
  self.SWITCH_MODE_TRIG = 3
  self.SWITCH_MODE_SCHEDULE = 4

  self.BOUNDS_MODE_STOP = 1
  self.BOUNDS_MODE_IGNORE = 2

  self.FOLLOW_TRACK_ON = 1
  self.FOLLOW_TRACK_OFF = 2

  self.TRACK_PAGE_AUTO = 1

  self.SEQUENCE_MODE_NORMAL = 1
  self.SEQUENCE_MODE_INDEX = 2

  --self:_set_default_options(true)

  -- define the mappings (unassigned)

  self.mappings = {
    matrix = {
      description = "Matrix: Press to toggle muted state"
                  .."\nHold to focus this track/pattern"
                  .."\nControl value: ",
      greedy = true,
    },
    triggers = {
      description = "Matrix: Pattern-sequence triggers"
                  .."\nPress and release to trigger pattern"
                  .."\nPress multiple buttons to define loop"
                  .."\nPress and hold to toggle loop"
                  .."\nControl value: ",
      orientation = VERTICAL,
    },
    sequence = { 
      description = "Matrix: Flip through pattern sequence"
                  .."\nControl value: ",
      orientation = HORIZONTAL,
      index = 1,
    },
    track = {
      description = "Matrix: Flip though tracks"
                  .."\nControl value: ",
      orientation = HORIZONTAL,
      index = 3,
    },
  }

  -- define default palette

  self.palette = {
    out_of_bounds = {
      color={0x40,0x40,0x00}, 
      text="",
    },
    slot_empty = {
      color={0x00,0x00,0x00},
      text="·",
    },
    slot_empty_muted = {
      color={0x40,0x00,0x00},
      text="▫",
    },
    slot_filled = {
      color={0xff,0xff,0x00},
      text="■",
    },
    slot_filled_muted = {
      color={0xff,0x40,0x00},
      text="□",
    },
    slot_master_filled = {
      color={0x00,0xff,0x00},
      text="■",
    },
    slot_master_empty = {
      color={0x00,0x40,0x00},
      text="·",
    },
    trigger_active = {
      color={0xff,0xff,0xff},
      text="►",
    },
    trigger_loop = {
      color={0x40,0x40,0xff},
      text="·",
    },
    trigger_back = {
      color={0x00,0x00,0x00},
      text="",
    },
  }

  -- the various controls
  self._buttons = nil
  self._trigger = nil
  self._sequence_navigator = nil
  self._track_navigator = nil

  -- size of the matrix grid 
  self._width = nil
  self._height = nil

  -- misc. properties 
  self._playing = nil
  self._play_page = nil  
  self._edit_page = nil  
  self._track_offset = 0  
  self._track_page = nil
  self._loop_sequence_range = {0,0}
  self._scheduled_pattern = nil
  self._playback_pos = nil

  -- idle flags
  self._update_slots_requested = false
  self._update_tracks_requested = false
  self._mute_notifier_disabled = false

  Application.__init(self,display,mappings,options,config_name)

end

--------------------------------------------------------------------------------

-- update slots visual appeareance 

function Matrix:_update_slots()
  TRACE("Matrix:_update_slots()")
  if (not self.active) then
    return
  end

  if (not self.mappings.matrix.group_name) then
    return
  end

  if self._update_slots_requested then
    -- do lazy updates in idle...
    return
  end

  local skip_event = true
  local song = renoise.song()
  local sequence = song.sequencer.pattern_sequence
  local tracks = song.tracks
  local seq_offset = self._edit_page*self._height
  local master_idx = get_master_track_index()
  local patt_idx = nil
  local button = nil
  local slot_muted = nil
  local slot_empty = nil
  local palette = {}

  -- loop through matrix & buttons
  if (self._buttons) then
    for track_idx = (1+self._track_offset),(self._width+self._track_offset) do
      for seq_index = (1+seq_offset),(self._height+seq_offset) do
        local bt_x = track_idx-self._track_offset
        local bt_y = seq_index-seq_offset
        button = self._buttons[bt_x][bt_y]

        if((sequence[seq_index]) and (song.tracks[track_idx]))then

          -- gain information about the slot
          patt_idx = sequence[seq_index]
          slot_muted = song.sequencer:track_sequence_slot_is_muted(
            track_idx, seq_index)
          slot_empty = song.patterns[patt_idx].tracks[track_idx].is_empty

          if (not slot_empty) then
            if (track_idx==master_idx)then -- master track
              palette.foreground = table.rcopy(self.palette.slot_master_filled)
              palette.background = table.rcopy(self.palette.slot_master_filled)
            else
              palette.foreground = table.rcopy(self.palette.slot_filled)
              palette.background = table.rcopy(self.palette.slot_filled_muted)
            end
          else
            -- empty slot 
            if (track_idx==master_idx)then
              palette.foreground = table.rcopy(self.palette.slot_master_empty)
              palette.background = table.rcopy(self.palette.slot_master_empty)
            else
              palette.foreground = table.rcopy(self.palette.slot_empty)
              palette.background = table.rcopy(self.palette.slot_empty_muted)
            end
          end
          -- workaround for devices with no colorspace:
          -- revert to the unlit state 
          if is_monochrome(self.display.device.colorspace) then
            if slot_empty then
              button:set(false,skip_event)
            else
              button:set(not slot_muted,skip_event)
            end
          else
            button:set(not slot_muted,skip_event)
          end

        elseif button then

          -- out-of-bounds space (below/next to song)
          palette.background = table.rcopy(self.palette.out_of_bounds)
          button:set(false,skip_event)

        end
        
        if(button)then
          button:set_palette(palette)
        end

      end
    end
  end
end


--------------------------------------------------------------------------------

function Matrix:start_app()
  TRACE("Matrix.start_app()")

  if not Application.start_app(self) then
    return
  end

  self._playing = renoise.song().transport.playing
  self._playback_pos = renoise.song().transport.playback_pos
  self._play_page = self:_get_play_page()

  self:_set_trigger_mode()

  -- update everything!
  self:_update_page_count()
  self:_update_seq_offset()
  self:_update_track_count()
  self:_update_position()
  self:_update_range()
  self:_update_slots()

end


--------------------------------------------------------------------------------

-- periodic updates: handle "un-observable" things here

function Matrix:on_idle()
--TRACE("Matrix:idle_app()",self._update_slots_requested)
  
  if (not self.active) then return end

  -- updated tracks/slots?
  if (self._update_tracks_requested) then
    -- note: _update_slots_requested is true as well
    TRACE("Matrix:on_idle ** update track count")
    self._update_tracks_requested = false
    self:_update_track_count()
  end
  -- 
  if (self._update_slots_requested) then
    TRACE("Matrix:on_idle ** update slots/page count")
    self._update_slots_requested = false
    self:_update_slots()
    self:_update_page_count()
  end

  -- update range?
  local rng = renoise.song().transport.loop_sequence_range
  if (rng[1]~=self._loop_sequence_range[1]) or
    (rng[2]~=self._loop_sequence_range[2]) 
  then
    TRACE("Matrix:on_idle ** update range")
    self:_update_range()
  end

  if renoise.song().transport.playing then

    local pos = renoise.song().transport.playback_pos

    -- ??? playback_pos might briefly contain the wrong value
    if (pos.sequence ~= self._playback_pos.sequence)then

      -- changed pattern
      self._playback_pos = pos

      if (self._trigger) then
        self._trigger:stop_blink()
      end
      -- entered a new play-page
      local play_page = self:_get_play_page()
      if (play_page~=self._play_page) then
        TRACE("Matrix:on_idle ** entered a new page")
        self:_check_page_change()
      end
      self:_update_position(pos.sequence)

    elseif (not self._playing) then
      -- playback resumed
      TRACE("Matrix:on_idle ** playback resumed")
      self:_update_position()
    elseif (self._trigger) and 
      (self._trigger:get_index() == 0) and 
      (self._play_page==self._edit_page) 
    then
      -- position now in play-range
      TRACE("Matrix:on_idle ** entered a new page")
      self:_update_position()      
    end

    self._playing = true

  else
    -- if we stopped playing, turn off position
    if(self._playing) then
      TRACE("Matrix:on_idle ** stopped playing")
      self:_update_position(0)
      self._playing = false
      if (self._trigger) then
        self._trigger:stop_blink()
      end
    end

  end
end

--------------------------------------------------------------------------------

-- called when a new document becomes available

function Matrix:on_new_document()
  TRACE("Matrix:on_new_document()")

  self:_attach_to_song(renoise.song())
  self:_update_page_count()
  self:_update_track_count()
  self:_update_slots()
end

--------------------------------------------------------------------------------
-- private methods
--------------------------------------------------------------------------------

-- check if we need to change page, but update only when following play-pos
-- called when page changes and when "follow_player" is enabled

function Matrix:_check_page_change() 
  TRACE("Matrix:_check_page_change")

  self._play_page = self:_get_play_page()
  if(renoise.song().transport.follow_player)then
    if(self._play_page~=self._edit_page)then
      self:_update_seq_offset()
      self:_update_range()
      self:_update_slots()
    end
  end

end

--------------------------------------------------------------------------------

-- update track navigator,
-- on new song, and when tracks have been changed

function Matrix:_update_track_count() 
  TRACE("Matrix:_update_track_count")

  if (self._track_navigator) then
    --local count = math.floor((#renoise.song().tracks-1)/self._width)
    local page_width = self:_get_page_width()
    local count = math.floor((#renoise.song().tracks-1)/page_width)
    self._track_navigator:set_range(nil,count)
  end

end

--------------------------------------------------------------------------------

-- update sequence offset

function Matrix:_update_seq_offset()
  TRACE("Matrix:_update_seq_offset()")

  local skip_event_handler = true
  if (self._sequence_navigator) then
    self._sequence_navigator:set_index(self._play_page, skip_event_handler)
  end
  self._edit_page = self._play_page

end

--------------------------------------------------------------------------------

-- update the switcher (when the number of pattern have changed)

function Matrix:_update_page_count()
  TRACE("Matrix:_update_page_count()")

  local seq_len = #renoise.song().sequencer.pattern_sequence
  local page_count = math.floor((seq_len-1)/self._height)
  if (self._sequence_navigator) then
    self._sequence_navigator:set_range(nil,page_count)
  end

end

--------------------------------------------------------------------------------

-- update range in sequence trigger

function Matrix:_update_range()

  if (self._trigger) then

    --local rng = self._trigger:get_range()
    local rng = renoise.song().transport.loop_sequence_range
    self._loop_sequence_range = rng

    -- set the range
    local start = (self._height*(self._edit_page+1))-(self._height-1)
    if not ((start+self._height-1)<rng[1]) and 
      not (start>rng[2]) then

      local index_start = self._loop_sequence_range[1]%self._height
      index_start = (index_start==0) and self._height or index_start
      if(start>rng[1]) then
       index_start = 1
      end

      local index_end = self._loop_sequence_range[2]%self._height
      index_end = (index_end==0) and self._height or index_end
      if((start+self._height-1)<self._loop_sequence_range[2]) then
        index_end = self._height
      end

      self._trigger:set_range(index_start,index_end,true)

    else
      self._trigger:set_range(0,0,true)
    end
    self._trigger:invalidate()
  end
end

--------------------------------------------------------------------------------

-- update index in sequence trigger
-- called when starting/stopping playback, changing page
-- @idx: (integer) the index, 0 - song-end (use current position if undefined)

function Matrix:_update_position(idx)
  TRACE("Matrix:_update_position()",idx)

  if not idx then
    idx = self._playback_pos.sequence
  end

  local pos_idx = nil
  if(self._playing)then
    local play_page = self:_get_play_page()
    -- we are at a visible page?
    if(self._edit_page == play_page)then
      pos_idx = idx-(self._play_page*self._height)
    else
      pos_idx = 0 -- no, hide sequence index 
    end
  else
    pos_idx = 0 -- stopped, hide sequence index 
  end

  if (self._trigger) then
    self._trigger:set_index(pos_idx,true)

    -- control trigger blinking
    if (self._scheduled_pattern) then
      local schedule_page = math.floor(self._scheduled_pattern/self._height)
      if (schedule_page==self._edit_page) then
        self._trigger:start_blink(self._trigger._blink_idx)
      else
        self._trigger:pause_blink()
      end
    end

    self._trigger:invalidate()
  end

end

--------------------------------------------------------------------------------

-- retrigger the current pattern

function Matrix:_retrigger_pattern()
  TRACE("Matrix:retrigger_pattern()")

  local play_pos = self._playback_pos.sequence
  if renoise.song().sequencer.pattern_sequence[play_pos] then
    renoise.song().transport:trigger_sequence(play_pos)
    self:_update_position(play_pos)
  end
end

--------------------------------------------------------------------------------

function Matrix:_set_trigger_mode()

  if (self._trigger) then
    local is_normal = 
      (self.options.sequence_mode.value==self.SEQUENCE_MODE_NORMAL)
    self._trigger.mode = is_normal and 
      self._trigger.MODE_NORMAL or self._trigger.MODE_INDEX 
  end

end

--------------------------------------------------------------------------------

function Matrix:_get_play_page()
  TRACE("Matrix:_get_play_page()")

  local play_pos = renoise.song().transport.playback_pos
  return math.floor((play_pos.sequence-1)/self._height)

end


--------------------------------------------------------------------------------

-- when following the active track in Renoise, we call this method
-- it will check if we are inside the current page, and update if not

function Matrix:_follow_track()
  TRACE("Matrix:_follow_track()")

  if (self.options.follow_track.value == self.FOLLOW_TRACK_OFF) then
    return
  end

  local song = renoise.song()
  local track_idx = song.selected_track_index
  local page = self:_get_track_page(track_idx)
  local page_width = self:_get_page_width()
  if (page~=self._track_page) then
    self._track_page = page
    self._track_offset = page*page_width
    self:_update_slots()
    if self._track_navigator then
      self._track_navigator:set_index(page,true)
    end
  end

end


--------------------------------------------------------------------------------

-- figure out the active "track page" based on the supplied track index
-- @param track_idx, renoise track number
-- return integer (0-number of pages)

function Matrix:_get_track_page(track_idx)

  local page_width = self:_get_page_width()
  local page = math.floor((track_idx-1)/page_width)
  return page

end

--------------------------------------------------------------------------------

function Matrix:_get_page_width()

  return (self.options.page_size.value==self.TRACK_PAGE_AUTO)
    and self._width or self.options.page_size.value-1

end

--------------------------------------------------------------------------------

function Matrix:_build_app()
  TRACE("Matrix:_build_app()")

  -- determine matrix size by looking at the control-map
  if (self.mappings.matrix.group_name) then
    local control_map = self.display.device.control_map
    self._width = control_map:count_columns(self.mappings.matrix.group_name)
    self._height = control_map:count_rows(self.mappings.matrix.group_name)
  elseif (self.mappings.triggers.group_name) then
    local control_map = self.display.device.control_map
    self._width = control_map:count_columns(self.mappings.triggers.group_name)
    self._height = control_map:count_rows(self.mappings.triggers.group_name)
  end

  -- embed the trigger-group in the matrix?
  local embed_triggers = (self.mappings.triggers.group_name==self.mappings.matrix.group_name)
  if(embed_triggers)then
    self._width = self._width-1
  end

  local observable = nil

  -- sequence (up/down scrolling)
  if (self.mappings.sequence.group_name) then
    local c = UISpinner(self.display)
    c.group_name = self.mappings.sequence.group_name
    c.tooltip = self.mappings.sequence.description
    c:set_pos(self.mappings.sequence.index or 1)
    c:set_orientation(self.mappings.sequence.orientation)
    c.text_orientation = self.mappings.sequence.orientation
    c.on_change = function(obj) 
      if (not self.active) then
        return false
      end
      if(self._edit_page~=obj.index)then
        self._edit_page = obj.index
        self:_update_slots()
        self:_update_range()
        if(self._edit_page~=self._play_page) then
          self:_update_position()
        end
        return true
      end
      return false
    end
    self:_add_component(c)
    self._sequence_navigator = c
  end

  --  track (sideways scrolling)
  if (self.mappings.track.group_name) then
    local c = UISpinner(self.display)
    c.group_name = self.mappings.track.group_name
    c.tooltip = self.mappings.track.description
    c:set_pos(self.mappings.track.index or 1)
    c:set_orientation(self.mappings.track.orientation)
    c.text_orientation = self.mappings.track.orientation
    c.on_change = function(obj) 
      TRACE("self._track_navigator.on_change:",obj)
      if (not self.active) then
        return false
      end
      --local track_idx = (obj.index*self._width)
      local page_width = self:_get_page_width()
      local track_idx = (obj.index*page_width)
      if (self.options.follow_track.value == self.FOLLOW_TRACK_ON) then
        -- let the notifier method deal with the track change...
        renoise.song().selected_track_index = 1+track_idx
      else
        self._track_offset = track_idx
        self:_update_slots()
      end
      return true
    end
    self:_add_component(c)
    self._track_navigator = c
  end

  -- play-position (navigator)
  if (self.mappings.triggers.group_name) then

    local x_pos = 1
    if(embed_triggers)then
      x_pos = self._width+1
    end

    local c = UIButtonStrip(self.display)
    -- note: the mode is set via the sequence_mode option, and needs to be 
    -- specified via device configurations if the controller has "togglebutton"
    -- as it's input method (for an example, see the TouchOSC configuration)
    c.group_name = self.mappings.triggers.group_name
    c.tooltip = self.mappings.triggers.description
    c.toggleable = true
    c.monochrome = is_monochrome(self.display.device.colorspace)
    c.flipped = true
    c:set_pos(x_pos)
    c:set_size(self._height)
    c:set_orientation(self.mappings.triggers.orientation)

    c.on_index_change = function(obj)

      if not self.active then
        return false
      end

      local obj_index = obj:get_index()
      local seq_index = obj_index + (self._height*self._edit_page)
      local seq_offset = self._playback_pos.sequence%self._height

      if obj_index==0 then

        TRACE("Matrix: position was toggled off")

        if (self.options.play_mode.value == self.PLAY_MODE_RETRIG) then
          self:_retrigger_pattern()
        elseif (self.options.play_mode.value == self.PLAY_MODE_PLAY) then
          return false
        elseif (self.options.play_mode.value == self.PLAY_MODE_TOGGLE) then
          renoise.song().transport:stop()
        elseif (self.options.play_mode.value == self.PLAY_MODE_SCHEDULE) then
          seq_index = self._playback_pos.sequence + 
            (self._height*self._edit_page)
          if renoise.song().sequencer.pattern_sequence[seq_index] then
            renoise.song().transport:set_scheduled_sequence(seq_index)
            --[[
            -- how to detect that a scheduled pattern starts to play,
            -- when it's the current one? an observable is needed?
            self._scheduled_pattern = seq_index
            local obj_index2 = seq_index%self._height
            obj:start_blink(obj_index2)
            ]]
          end
        end

      elseif not renoise.song().sequencer.pattern_sequence[seq_index] then

        TRACE("Matrix: position out of bounds")

        if (self.options.bounds_mode.value == self.BOUNDS_MODE_STOP) then
          renoise.song().transport:stop()
        end
        obj._cached_index = 0 -- hackish  
        return false

      elseif(self._playback_pos.sequence==seq_index)then

        TRACE("Matrix: position toggled back on")

        if (self.options.play_mode.value == self.PLAY_MODE_RETRIG) then
          self:_retrigger_pattern()
        elseif (self.options.play_mode.value == self.PLAY_MODE_PLAY) then
          if (not renoise.song().transport.playing) then
            if renoise.song().sequencer.pattern_sequence[seq_index] then
              renoise.song().transport:trigger_sequence(seq_index)
            end
          end
        elseif (self.options.play_mode.value == self.PLAY_MODE_SCHEDULE) then
          if renoise.song().sequencer.pattern_sequence[seq_index] then
            renoise.song().transport:set_scheduled_sequence(seq_index)
          end
        elseif (self.options.play_mode.value == self.PLAY_MODE_TOGGLE) then
          if (not renoise.song().transport.playing) then
            if renoise.song().sequencer.pattern_sequence[seq_index] then
              renoise.song().transport:trigger_sequence(seq_index)
              -- TODO : set index (for slightly faster update)
              return false
            end
          end
        end

      else

        TRACE("Matrix: switch to new position")

        if (not renoise.song().transport.playing) then
          -- start playback if stopped
          if renoise.song().sequencer.pattern_sequence[seq_index] then
            renoise.song().transport:trigger_sequence(seq_index)
            return false
          end
        else
          if(self.options.switch_mode.value == self.SWITCH_MODE_SCHEDULE) then
            if renoise.song().sequencer.pattern_sequence[seq_index] then
              -- schedule, but do not update display
              renoise.song().transport:set_scheduled_sequence(seq_index)
              self._scheduled_pattern = seq_index
              obj:start_blink(obj_index)
              return false
            end
          elseif(self.options.switch_mode.value == self.SWITCH_MODE_SWITCH) then
            -- instantly switch position:
            local new_pos = renoise.song().transport.playback_pos
            new_pos.sequence = seq_index
            -- if the desired pattern-line does not exist,start from 0
            local patt_idx = renoise.song().sequencer.pattern_sequence[seq_index]
            local num_lines = renoise.song().patterns[patt_idx].number_of_lines
            if(new_pos.line>num_lines)then
              new_pos.line = 1
            end
            renoise.song().transport.playback_pos = new_pos
          elseif(self.options.switch_mode.value == self.SWITCH_MODE_STOP) then
            renoise.song().transport:stop()
          elseif(self.options.switch_mode.value == self.SWITCH_MODE_TRIG) then
            if renoise.song().sequencer.pattern_sequence[seq_index] then
              self._playback_pos.sequence = seq_index
              self:_retrigger_pattern()
            end
          end
        end
      end
    end
    c.on_range_change = function(obj)

      if not self.active then
        return false
      end

      local rng = obj:get_range()

      -- check if the range is empty (0,0)
      if (rng[1]==0) and (rng[2]==0) then
        renoise.song().transport.loop_sequence_range = {0,0}
        return
      end

      -- TODO: support range selection across "pages"

      local start_index = rng[1] + (self._height*self._edit_page)
      local end_index = rng[2] + (self._height*self._edit_page)

      -- check if the range is out-of-bounds
      if not renoise.song().sequencer.pattern_sequence[start_index] then
        -- completely out-of-bounds, ignore
        return false
      elseif not renoise.song().sequencer.pattern_sequence[end_index] then
        -- partially out-of-bounds, correct
        local sequence_length = #renoise.song().sequencer.pattern_sequence
        renoise.song().transport.loop_sequence_range = {start_index,sequence_length}
        return false
      else
        -- range is within current page
        self._loop_sequence_range = {start_index,end_index}
        renoise.song().transport.loop_sequence_range = self._loop_sequence_range
      end
    end

    self:_add_component(c)
    self._trigger = c

  end

  -- grid buttons
  if (self.mappings.matrix.group_name) then
    self._buttons = {}
    for x=1,self._width do
      self._buttons[x] = {}

      for y=1,self._height do

        local c = UIToggleButton(self.display)
        c.group_name = self.mappings.matrix.group_name
        c.tooltip = self.mappings.matrix.description
        c:set_pos(x,y)
        c.active = false

        -- controller button pressed & held
        c.on_hold = function(obj) 

          local x_pos = x + self._track_offset
          local y_pos = y + (self._height*self._edit_page)
          obj:toggle()

          -- bring focus to pattern/track
          if (#renoise.song().tracks>=x_pos) then
            renoise.song().selected_track_index = x_pos
          end
          if renoise.song().sequencer.pattern_sequence[y_pos] then
            renoise.song().selected_sequence_index = y_pos
          end

        end

        -- controller button was pressed
        c.on_change = function(obj) 

          if not self.active then
            return false
          end

          local seq = renoise.song().sequencer
          local patt_seq = renoise.song().sequencer.pattern_sequence
          local master_idx = get_master_track_index()
          local seq_offset = self._edit_page*self._height
          --local sequence = renoise.song().sequencer.pattern_sequence
          local track_idx = x+self._track_offset
          local seq_idx = y+seq_offset
          local patt_idx = patt_seq[y+seq_offset]
          local patt = renoise.song().patterns[patt_idx]

          if track_idx == master_idx then
            -- master track is not toggle-able
            return false
          elseif not renoise.song().tracks[track_idx] then
            -- outside track bounds
            return false
          elseif not patt_seq[y+seq_offset] then
            -- outside sequence bounds
            return false
          else
            -- toggle matrix slot state
            local is_muted = seq:track_sequence_slot_is_muted(track_idx,seq_idx)
            renoise.song().sequencer:set_track_sequence_slot_is_muted(
              (track_idx),(y+seq_offset),(not is_muted))
          end
          -- don't update the entire grid the next time
          self._mute_notifier_disabled = true
          -- workaround for devices with no colorspace:
          -- revert to the unlit state 
          --if table.is_empty(self.display.device.colorspace) then
          if is_monochrome(self.display.device.colorspace) then
            local slot_empty = patt.tracks[x+self._track_offset].is_empty
            if slot_empty then
              obj:set(false,true)
              return false
            end
          end
            
          return true
        end

        self:_add_component(c)
        self._buttons[x][y] = c

      end  
    end
  end

  self:_attach_to_song(renoise.song())

  Application._build_app(self)
  return true

end


--------------------------------------------------------------------------------

-- adds notifiers to slot relevant states

function Matrix:_attach_to_song(song)
  TRACE("Matrix:_attach_to_song()")
  

  -- song notifiers

  song.sequencer.pattern_assignments_observable:add_notifier(
    function()
      TRACE("Matrix: pattern_assignments_observable fired...")
      self._update_slots_requested = true
    end
  )
  
  song.sequencer.pattern_sequence_observable:add_notifier(
    function(e)
      TRACE("Matrix: pattern_sequence_observable fired...")
      self._update_slots_requested = true
    end
  )

  song.sequencer.pattern_slot_mutes_observable:add_notifier(
    function()
      TRACE("Matrix:pattern_slot_mutes_observable fired...")
      -- TODO skip this when setting mute state from controller
      if not self._mute_notifier_disabled then
        self._update_slots_requested = true
      else
        self._mute_notifier_disabled = false
      end
    end
  )

  song.tracks_observable:add_notifier(
    function()
      TRACE("Matrix:tracks_observable fired...")
      self._update_slots_requested = true
    end
  )

  song.patterns_observable:add_notifier(
    function()
      TRACE("Matrix:patterns_observable fired...")
      self._update_slots_requested = true
    end
  )

  song.transport.follow_player_observable:add_notifier(
    function()
      TRACE("Matrix:follow_player_observable fired...")
      if(self._play_page~=self._edit_page)then
        self:_check_page_change()
      end
    end
  )

  -- slot notifiers
  
  local function slot_changed()
    TRACE("Matrix:slot_changed fired...")
    self._update_slots_requested = true
  end

  local function attach_slot_notifiers()
    local patterns = song.patterns

    for _,pattern in pairs(patterns) do
      local pattern_tracks = pattern.tracks
      
      for _,pattern_track in pairs(pattern_tracks) do
        local observable = pattern_track.is_empty_observable
        
        if (not observable:has_notifier(slot_changed)) then
          observable:add_notifier(slot_changed)
        end
      end
    end
  end

  -- attach to the initial slot set
  attach_slot_notifiers()
  
  -- and to new slots  
  song.tracks_observable:add_notifier(
    function()
      TRACE("Matrix:tracks_changed fired...")
      self._update_slots_requested = true
      self._update_tracks_requested = true
      attach_slot_notifiers()
    end
  )

  song.patterns_observable:add_notifier(
    function()
      TRACE("Matrix:patterns_changed fired...")
      self._update_slots_requested = true
      attach_slot_notifiers()
    end
  )

  -- follow active track in Renoise
  song.selected_track_index_observable:add_notifier(
    function()
      TRACE("Matrix:selected_track_observable fired...")

      if not self.active then 
        return false 
      end

      self:_follow_track()

    end
  )

  self:_follow_track()

end

