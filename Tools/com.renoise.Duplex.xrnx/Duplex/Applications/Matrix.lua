--[[============================================================================
-- Duplex.Application.Matrix
============================================================================]]--

--[[--
Take control of the pattern matrix in Renoise with the endlessly scrollable matrix application. 
Inheritance: @{Duplex.Application} > Duplex.Application.Matrix 

### Demonstration video

See a video demonstrating this application at [Youtube][1]
[1]:http://www.youtube.com/watch?v=K_kCaYV_T78

### Changes

  0.95  
    - Added changelog, more thourough documentation

  0.93  
    - Inclusion of UIButtonStrip for more flexible control of playback-pos
    - Utilize "blinking" feature to display a scheduled pattern
    - "follow_player" mode in Renoise will update the matrix immediately

  0.92  
    - Removed the destroy_app() method (not needed anymore)
    - Assign tooltips to the virtual control surface

  0.91  
    - All mappings are now without dependancies (no more "required" groups)

  0.81  - First release

--]]


--==============================================================================

-- constants

local PLAY_MODE_PLAY = 1
local PLAY_MODE_TOGGLE = 2
local PLAY_MODE_RETRIG = 3
local PLAY_MODE_SCHEDULE = 4
local SWITCH_MODE_STOP = 1
local SWITCH_MODE_SWITCH = 2
local SWITCH_MODE_TRIG = 3
local SWITCH_MODE_SCHEDULE = 4
local BOUNDS_MODE_STOP = 1
local BOUNDS_MODE_IGNORE = 2
local FOLLOW_TRACK_ON = 1
local FOLLOW_TRACK_OFF = 2
local TRACK_PAGE_AUTO = 1
local SEQUENCE_MODE_NORMAL = 1
local SEQUENCE_MODE_INDEX = 2


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
    value = 1,
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
    value = 1,
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
      inst:_update_track_navigation()
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


Matrix.available_mappings = {
  matrix = {
    description = "Matrix: Press to toggle muted state"
                .."\nHold to focus this track/pattern"
                .."\nControl value: ",
  },
  triggers = {
    description = "Matrix: Pattern-sequence triggers"
                .."\nPress and release to trigger pattern"
                .."\nPress multiple buttons to define loop"
                .."\nPress and hold to toggle loop"
                .."\nControl value: ",
    orientation = ORIENTATION.VERTICAL,
  },
  next_seq_page = {
    description = "Matrix: display next sequence page"
  },
  prev_seq_page = {
    description = "Matrix: display previous sequence page"
  },
  next_track_page = {
    description = "Matrix: display next sequence page"
  },
  prev_track_page = {
    description = "Matrix: display previous sequence page"
  },
  --[[
  track = {
    description = "Matrix: Flip though tracks"
                .."\nControl value: ",
    orientation = ORIENTATION.HORIZONTAL,
    index = 3,
  },
  ]]
}

Matrix.default_palette = {
  -- pattern matrix
  out_of_bounds       = { color={0x40,0x40,0x00}, text="·", val=false },
  slot_empty          = { color={0x00,0x00,0x00}, text="·", val=false },
  slot_empty_muted    = { color={0x40,0x00,0x00}, text="·", val=false },
  slot_filled         = { color={0xff,0xff,0x00}, text="▪", val=true  },
  slot_filled_muted   = { color={0xff,0x40,0x00}, text="▫", val=false },
  slot_master_filled  = { color={0x00,0xff,0x00}, text="▪", val=true  },
  slot_master_empty   = { color={0x00,0x40,0x00}, text="·", val=false },
  -- pattern sequence (buttonstrip)
  trigger_active      = { color={0xff,0xff,0xff}},
  trigger_loop        = { color={0x40,0x40,0xff}},
  trigger_back        = { color={0x00,0x00,0x00}},
  -- pattern sequence navigation (prev/next)
  prev_seq_on = {     color = {0xFF,0xFF,0xFF}, text = "▲", val=true },
  prev_seq_off = {    color = {0x00,0x00,0x00}, text = "▲", val=false },
  next_seq_on = {     color = {0xFF,0xFF,0xFF}, text = "▼", val=true },
  next_seq_off = {    color = {0x00,0x00,0x00}, text = "▼", val=false },
  -- track navigation (prev/next)
  prev_track_on = {     color = {0xFF,0xFF,0xFF}, text = "◄", val=true },
  prev_track_off = {    color = {0x00,0x00,0x00}, text = "◄", val=false },
  next_track_on = {     color = {0xFF,0xFF,0xFF}, text = "►", val=true },
  next_track_off = {    color = {0x00,0x00,0x00}, text = "►", val=false },

}

--------------------------------------------------------------------------------

--- Constructor method
-- @param (VarArg)
-- @see Duplex.Application

function Matrix:__init(...)
  TRACE("Matrix:__init(",...)

  --- (table) keep references to UI controls here
  self._controls = table.create()

  --- (int) width of the matrix grid 
  self._width = nil

  --- (int) height of the matrix grid 
  self._height = nil

  --- (bool) true if currently playing
  self._playing = nil

  --- (int) the currently playing page
  self._play_page = nil  

  --- (int) current edit page
  self._edit_page = nil  

  --- (int) the total number of sequence pages
  self._seq_page_count = nil

  --- (int) the total number of track pages
  self._track_page_count = nil

  --- (int) the current track offset
  self._track_offset = 0  

  --- (int) the current track page
  self._track_page = nil

  --- (table) the loop sequence range
  -- @field 1 (int) begin
  -- @field 2 (int) end
  -- @table _loop_sequence_range
  self._loop_sequence_range = {0,0}

  --- (int) scheduled sequence index
  self._scheduled_pattern = nil

  --- (renoise.SongPos) current playback pos
  self._playback_pos = nil

  --- idle flags
  self._update_slots_requested = false
  self._update_tracks_requested = false
  self._mute_notifier_disabled = false

  Application.__init(self,...)

end

--------------------------------------------------------------------------------

--- update slots visual appeareance 

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
  if (self._controls._buttons) then
    for track_idx = (1+self._track_offset),(self._width+self._track_offset) do
      for seq_index = (1+seq_offset),(self._height+seq_offset) do
        local bt_x = track_idx-self._track_offset
        local bt_y = seq_index-seq_offset
        button = self._controls._buttons[bt_x][bt_y]

        if((sequence[seq_index]) and (song.tracks[track_idx]))then

          -- gain information about the slot
          patt_idx = sequence[seq_index]
          slot_muted = song.sequencer:track_sequence_slot_is_muted(
            track_idx, seq_index)
          slot_empty = song.patterns[patt_idx].tracks[track_idx].is_empty

          if (not slot_empty) then
            if (track_idx==master_idx)then -- master track
              button:set(self.palette.slot_master_filled)
            else
              if slot_muted then
                button:set(self.palette.slot_filled_muted)
              else
                button:set(self.palette.slot_filled)
              end
            end
          else
            -- empty slot 
            if (track_idx==master_idx)then
              button:set(self.palette.slot_master_empty)
            else
              if slot_muted then
                button:set(self.palette.slot_empty_muted)
              else
                button:set(self.palette.slot_empty)
              end
            end
          end

        elseif button then
          -- out-of-bounds space (below/next to song)
          button:set(self.palette.out_of_bounds)
        end

      end
    end
  end
end


--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.start_app
-- @return bool or nil

function Matrix:start_app()
  TRACE("Matrix.start_app()")

  if not Application.start_app(self) then
    return
  end

  self:_attach_to_song(renoise.song())


end


--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_idle

function Matrix:on_idle()
--TRACE("Matrix:idle_app()",self._update_slots_requested)
  
  if (not self.active) then return end

  -- updated tracks/slots?
  if (self._update_tracks_requested) then
    -- note: _update_slots_requested is true as well
    TRACE("Matrix:on_idle ** update track count")
    self._update_tracks_requested = false
    self:_update_track_page_count()
    --self:_update_track_navigation()
  end
  -- 
  if (self._update_slots_requested) then
    TRACE("Matrix:on_idle ** update slots/page count")
    self._update_slots_requested = false
    self:_update_slots()
    self:_update_seq_page_count()
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

      if (self._controls._trigger) then
        self._controls._trigger:stop_blink()
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
    elseif (self._controls._trigger) and 
      (self._controls._trigger:get_index() == 0) and 
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
      if (self._controls._trigger) then
        self._controls._trigger:stop_blink()
      end
    end

  end
end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_new_document

function Matrix:on_new_document()
  TRACE("Matrix:on_new_document()")

  self:_attach_to_song(renoise.song())

end

--------------------------------------------------------------------------------
-- private methods
--------------------------------------------------------------------------------

--- check if we need to change page, but update only when following play-pos
-- called when page changes and when "follow_player" is enabled

function Matrix:_check_page_change() 
  TRACE("Matrix:_check_page_change")

  self._play_page = self:_get_play_page()
  if(renoise.song().transport.follow_player)then
    if(self._play_page~=self._edit_page)then
      self._edit_page = self._play_page
      self:_update_seq_navigation()
      self:_update_range()
      self:_update_slots()
    end
  end

end

--------------------------------------------------------------------------------

--- update track navigator,
-- on new song, and when tracks have been changed

function Matrix:_update_track_navigation() 
  TRACE("Matrix:_update_track_navigation")

  if self._controls._next_track_page then
    if self:_has_next_track_page() then
      self._controls._next_track_page:set(self.palette.next_track_on)
    else
      self._controls._next_track_page:set(self.palette.next_track_off)
    end
  end

  if self._controls._prev_track_page then
    if self:_has_prev_track_page() then
      self._controls._prev_track_page:set(self.palette.prev_track_on)
    else
      self._controls._prev_track_page:set(self.palette.prev_track_off)
    end
  end

end

--------------------------------------------------------------------------------

--- update_seq_navigation

function Matrix:_update_seq_navigation()
  TRACE("Matrix:_update_seq_navigation()")

  -- we can go backwards?
  if self._controls._prev_seq_page then
    if self:_has_prev_seq_page() then
      self._controls._prev_seq_page:set(self.palette.prev_seq_on)
    else
      self._controls._prev_seq_page:set(self.palette.prev_seq_off)
    end
  end

  -- we can go forward?
  if self._controls._prev_seq_page then
    if self:_has_next_seq_page() then
      self._controls._next_seq_page:set(self.palette.next_seq_on)
    else
      self._controls._next_seq_page:set(self.palette.next_seq_off)
    end
  end

end

--------------------------------------------------------------------------------

--- has_next_seq_page
-- @return bool

function Matrix:_has_next_seq_page()
  local has_next = (self._edit_page < self._seq_page_count) 
  return has_next
end

--------------------------------------------------------------------------------

--- has_prev_seq_page
-- @return bool

function Matrix:_has_prev_seq_page()
  local has_prev = (self._edit_page > 0)
  return has_prev
end

--------------------------------------------------------------------------------

--- has_next_track_page
-- @return bool

function Matrix:_has_next_track_page()
  local has_next = (self._track_page < self._track_page_count) 
  return has_next
end

--------------------------------------------------------------------------------

--- has_prev_track_page
-- @return bool

function Matrix:_has_prev_track_page()
  local has_prev = (self._track_page > 0)
  return has_prev
end

--------------------------------------------------------------------------------

--- update_seq_page_count

function Matrix:_update_seq_page_count()
  TRACE("Matrix:_update_seq_page_count()")

  local seq_len = #renoise.song().sequencer.pattern_sequence
  self._seq_page_count = math.floor((seq_len-1)/self._height)
  self:_update_seq_navigation()

end

--------------------------------------------------------------------------------

--- update_track_page_count

function Matrix:_update_track_page_count()
  TRACE("Matrix:_update_track_page_count()")

  local page_width = self:_get_track_page_width()
  self._track_page_count = math.floor((#renoise.song().tracks-1)/page_width)
  self:_update_track_navigation()

end

--------------------------------------------------------------------------------

--- update range in sequence trigger

function Matrix:_update_range()

  if (self._controls._trigger) then

    --local rng = self._controls._trigger:get_range()
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

      self._controls._trigger:set_range(index_start,index_end,true)

    else
      self._controls._trigger:set_range(0,0,true)
    end
    self._controls._trigger:invalidate()
  end
end

--------------------------------------------------------------------------------

--- update index in sequence trigger
-- called when starting/stopping playback, changing page
-- @param idx (integer) the index, 0 - song-end (use current position if undefined)

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

  if (self._controls._trigger) then
    self._controls._trigger:set_index(pos_idx,true)

    -- control trigger blinking
    if (self._scheduled_pattern) then
      local schedule_page = math.floor(self._scheduled_pattern/self._height)
      if (schedule_page==self._edit_page) then
        self._controls._trigger:start_blink(self._controls._trigger._blink_idx)
      else
        self._controls._trigger:pause_blink()
      end
    end

    self._controls._trigger:invalidate()
  end

end

--------------------------------------------------------------------------------

--- retrigger the current pattern

function Matrix:_retrigger_pattern()
  TRACE("Matrix:retrigger_pattern()")

  local play_pos = self._playback_pos.sequence
  if renoise.song().sequencer.pattern_sequence[play_pos] then
    renoise.song().transport:trigger_sequence(play_pos)
    self:_update_position(play_pos)
  end
end

--------------------------------------------------------------------------------

--- set the current trigger mode, depending on options

function Matrix:_set_trigger_mode()

  if (self._controls._trigger) then
    local is_normal = 
      (self.options.sequence_mode.value == SEQUENCE_MODE_NORMAL)
    self._controls._trigger.mode = is_normal and 
      self._controls._trigger.MODE_NORMAL or self._controls._trigger.MODE_INDEX 
  end

end

--------------------------------------------------------------------------------

--- get the currently playing page
-- @return int

function Matrix:_get_play_page()
  TRACE("Matrix:_get_play_page()")

  local play_pos = renoise.song().transport.playback_pos
  return math.floor((play_pos.sequence-1)/self._height)

end


--------------------------------------------------------------------------------

--- get the currently edited page
-- @return int

function Matrix:_get_edit_page()
  TRACE("Matrix:_get_edit_page()")

  local edit_pos = renoise.song().transport.edit_pos
  return math.floor((edit_pos.sequence-1)/self._height)

end


--------------------------------------------------------------------------------

--- when following the active track in Renoise, we call this method
-- it will check if we are inside the current page, and update if not

function Matrix:_follow_track()
  TRACE("Matrix:_follow_track()")

  if (self.options.follow_track.value == FOLLOW_TRACK_OFF) then
    return
  end

  local song = renoise.song()
  local track_idx = song.selected_track_index
  local page = self:_get_track_page(track_idx)
  local page_width = self:_get_track_page_width()
  if (page~=self._track_page) then
    self._track_page = page
    self._track_offset = page*page_width
    self._update_tracks_requested = true
    self._update_slots_requested = true
    --self:_update_slots()
    --self:_update_track_navigation()
  end

end


--------------------------------------------------------------------------------

--- figure out the active "track page" based on the supplied track index
-- @param track_idx, renoise track number
-- return integer (0-number of pages)

function Matrix:_get_track_page(track_idx)

  local page_width = self:_get_track_page_width()
  return math.floor((track_idx-1)/page_width)

end

--------------------------------------------------------------------------------

--- get track page width
-- @return int

function Matrix:_get_track_page_width()

  return (self.options.page_size.value == TRACK_PAGE_AUTO)
    and self._width or self.options.page_size.value-1

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application._build_app
-- @return bool

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

  -- next sequence page
  local map = self.mappings.next_seq_page
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index or 1)
    c.on_press = function()
      if self:_has_next_seq_page() then
        self._edit_page = self._edit_page + 1
        self:_update_slots()
        self:_update_range()
        self:_update_seq_navigation()
        if(self._edit_page~=self._play_page) then
          self:_update_position()
        end
      end
    end
    self._controls._next_seq_page = c
  end

  -- previous sequence page
  local map = self.mappings.prev_seq_page
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index or 1)
    c.on_press = function()
      if self:_has_prev_seq_page() then
        self._edit_page = self._edit_page - 1
        self:_update_slots()
        self:_update_range()
        self:_update_seq_navigation()
        if(self._edit_page~=self._play_page) then
          self:_update_position()
        end
      end
    end
    self._controls._prev_seq_page = c
  end

  -- next track page
  local map = self.mappings.next_track_page
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index or 1)
    c.on_press = function()
      if self:_has_next_track_page() then
        local page_width = self:_get_track_page_width()
        self._track_page = self._track_page +1
        self._track_offset = self._track_page*page_width
        self:_update_track_navigation() 
        self:_update_slots()
      end
    end
    self._controls._next_track_page = c
  end

  -- previous track page
  local map = self.mappings.prev_track_page
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index or 1)
    c.on_press = function()
      if self:_has_prev_track_page() then
        local page_width = self:_get_track_page_width()
        self._track_page = self._track_page-1
        self._track_offset = self._track_page*page_width
        self:_update_track_navigation() 
        self:_update_slots()
      end
    end
    self._controls._prev_track_page = c
  end


  -- play-position (navigator)
  if (self.mappings.triggers.group_name) then

    local x_pos = 1
    if(embed_triggers)then
      x_pos = self._width+1
    end

    local c = UIButtonStrip(self)
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
    c:set_palette({
      index = self.palette.trigger_active,
      range = self.palette.trigger_loop,
      background = self.palette.trigger_back,
    })
    c:set_orientation(self.mappings.triggers.orientation)

    c.on_index_change = function(obj)
      
      TRACE("Matrix: on_index_change",obj)

      local obj_index = obj:get_index()
      local seq_index = obj_index + (self._height*self._edit_page)
      local seq_offset = self._playback_pos.sequence%self._height

      if obj_index==0 then

        TRACE("Matrix: position was toggled off")

        if (self.options.play_mode.value == PLAY_MODE_RETRIG) then
          self:_retrigger_pattern()
        elseif (self.options.play_mode.value == PLAY_MODE_PLAY) then
          return false
        elseif (self.options.play_mode.value == PLAY_MODE_TOGGLE) then
          renoise.song().transport:stop()
        elseif (self.options.play_mode.value == PLAY_MODE_SCHEDULE) then
          seq_index = self._playback_pos.sequence + 
            (self._height*self._edit_page)
          if renoise.song().sequencer.pattern_sequence[seq_index] then
            renoise.song().transport:set_scheduled_sequence(seq_index)
          end
        end

      elseif not renoise.song().sequencer.pattern_sequence[seq_index] then

        TRACE("Matrix: position out of bounds")

        if (self.options.bounds_mode.value == BOUNDS_MODE_STOP) then
          renoise.song().transport:stop()
        end
        obj._cached_index = 0 -- hackish  
        return false

      elseif(self._playback_pos.sequence==seq_index)then

        TRACE("Matrix: position toggled back on")

        if (self.options.play_mode.value == PLAY_MODE_RETRIG) then
          self:_retrigger_pattern()
        elseif (self.options.play_mode.value == PLAY_MODE_PLAY) then
          if (not renoise.song().transport.playing) then
            if renoise.song().sequencer.pattern_sequence[seq_index] then
              renoise.song().transport:trigger_sequence(seq_index)
            end
          end
        elseif (self.options.play_mode.value == PLAY_MODE_SCHEDULE) then
          if renoise.song().sequencer.pattern_sequence[seq_index] then
            renoise.song().transport:set_scheduled_sequence(seq_index)
          end
        elseif (self.options.play_mode.value == PLAY_MODE_TOGGLE) then
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
          if(self.options.switch_mode.value == SWITCH_MODE_SCHEDULE) then
            if renoise.song().sequencer.pattern_sequence[seq_index] then
              -- schedule, but do not update display
              renoise.song().transport:set_scheduled_sequence(seq_index)
              self._scheduled_pattern = seq_index
              obj:start_blink(obj_index)
              return false
            end
          elseif(self.options.switch_mode.value == SWITCH_MODE_SWITCH) then
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
          elseif(self.options.switch_mode.value == SWITCH_MODE_STOP) then
            renoise.song().transport:stop()
          elseif(self.options.switch_mode.value == SWITCH_MODE_TRIG) then
            if renoise.song().sequencer.pattern_sequence[seq_index] then
              self._playback_pos.sequence = seq_index
              self:_retrigger_pattern()
            end
          end
        end
      end
    end
    c.on_range_change = function(obj)

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

    self._controls._trigger = c

  end

  -- grid buttons
  if (self.mappings.matrix.group_name) then
    self._controls._buttons = {}
    for x=1,self._width do
      self._controls._buttons[x] = {}
      for y=1,self._height do
        local c = UIButton(self)
        c.group_name = self.mappings.matrix.group_name
        c.tooltip = self.mappings.matrix.description
        c:set_pos(x,y)
        c.on_hold = function() 
          -- bring focus to pattern/track

          local x_pos = x + self._track_offset
          local y_pos = y + (self._height*self._edit_page)
          --obj:toggle()
          if (#renoise.song().tracks>=x_pos) then
            renoise.song().selected_track_index = x_pos
          end
          if renoise.song().sequencer.pattern_sequence[y_pos] then
            renoise.song().selected_sequence_index = y_pos
          end
        end
        c.on_press = function() 
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
            return 
          elseif not renoise.song().tracks[track_idx] then
            -- outside track bounds
            return 
          elseif not patt_seq[y+seq_offset] then
            -- outside sequence bounds
            return 
          else
            -- toggle matrix slot state
            local is_muted = seq:track_sequence_slot_is_muted(track_idx,seq_idx)
            renoise.song().sequencer:set_track_sequence_slot_is_muted(
              (track_idx),(y+seq_offset),(not is_muted))
          end

        end
        self._controls._buttons[x][y] = c
      end  
    end
  end

  Application._build_app(self)
  return true

end


--------------------------------------------------------------------------------

--- add notifiers to relevant parts of the song

function Matrix:_attach_to_song(song)
  TRACE("Matrix:_attach_to_song()",song)

  local track_idx = renoise.song().selected_track_index
  self._playing = renoise.song().transport.playing
  self._playback_pos = renoise.song().transport.playback_pos
  self._play_page = self:_get_play_page()
  self._edit_page = self:_get_edit_page()
  self._track_page = self:_get_track_page(track_idx)
  self:_set_trigger_mode()
  self:_update_track_page_count()
  self:_update_seq_page_count()
  self:_update_position()
  self:_update_range()
  self:_update_slots()
  self:_follow_track()

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


end

