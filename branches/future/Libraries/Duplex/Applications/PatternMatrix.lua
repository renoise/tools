--[[----------------------------------------------------------------------------
-- Duplex.PatternMatrix
----------------------------------------------------------------------------]]--

--[[

The pattern-matrix is useful with grid controllers
- buttons will mute/unmute track slots
- paged navigation: up/down/left/right (when song follow is on, 
  the matrix will automatically display the currently playing page)
- flexible options for song-position control (switch/retrigger/etc)
- minimum size: 4x4 (navigation + 3 tracks/patterns)

Todo
- track follow : automatically show the active track page


--]]

--==============================================================================


class 'PatternMatrix' (Application)

function PatternMatrix:__init(display,options)
  TRACE("PatternMatrix:__init(",display,options)

  Application.__init(self)

  -- "matrix_group_name" is required, other groups can be left out
  if (not options.matrix_group_name) then
    print("PatternMatrix: Warning - required parameter missing")
    return
  end

  -- todo: map missing trigger/control groups onto the matrix

  -- options, when current pos is pressed (again)

  self.PLAY_MODE_PLAY = 0       -- play/continue
  self.PLAY_MODE_TOGGLE = 1     -- toggle start & stop
  self.PLAY_MODE_RETRIG = 2     -- retrigger pattern
  self.PLAY_MODE_SCHEDULE = 3   -- schedule pattern

  -- options, when switching from one position to another

  self.SWITCH_MODE_STOP = 0     -- stop playback
  self.SWITCH_MODE_SWITCH = 1   -- switch to pattern
  self.SWITCH_MODE_TRIG = 2     -- trigger pattern
  self.SWITCH_MODE_SCHEDULE = 3 -- schedule pattern

  -- options, for empty matrix space below the song

  self.BOUNDS_MODE_STOP = 0     -- stop playback 
  self.BOUNDS_MODE_IGNORE = 1   -- nothing happens

  -- apply arguments 

  self.play_mode = self.PLAY_MODE_RETRIG
  self.switch_mode = self.SWITCH_MODE_SWITCH
  self.out_of_bounds = self.BOUNDS_MODE_STOP

  self.display = display

  -- useable control-map groups
  -- matrix group : minimum of 2x2 buttons (8x8<)
  -- trigger group: minimum of 2 buttons (8<)
  -- controls group: 4 buttons 

  self.matrix_group_name = options.matrix_group_name
  self.trigger_group_name = options.trigger_group_name
  self.controls_group_name = options.controls_group_name

  -- default size (control-map should redefine this)
  self.width = 4
  self.height = 4

  self.buttons = nil  -- [UIToggleButton,...]
  self.position = nil -- UISlider

  -- internal stuff

  self.__playing = nil
  self.__play_page = nil  -- the currently playing page
  self.__edit_page = nil  -- the currently editing page
  self.__track_offset = 0  -- the track offset (0-#tracks)

  -- the number of lines is used for determining the playback- 
  -- position within the currently playing pattern (in lines)
  --self.__num_lines = nil    -- 

  self.__playback_pos = nil
  self.__update_slots_requested = false
  self.__update_tracks_requested = false

  -- final steps

  self:build_app()
  self:__attach_to_song(renoise.song())

end


--------------------------------------------------------------------------------

function PatternMatrix:build_app()
  TRACE("PatternMatrix:build_app()")

  Application.build_app(self)

  -- determine matrix size by looking at the control-map
  local control_map = self.display.device.control_map.groups[self.matrix_group_name]
  if(control_map["columns"])then
      self.width = control_map["columns"]
      self.height = math.ceil(#control_map/self.width)
  end

  local observable = nil

  -- up/down (page selector)
  -- occupies the first two units in the scroll-group

  self.switcher = UISpinner(self.display)
  self.switcher.group_name = self.controls_group_name
  self.switcher.index = 0
  self.switcher.minimum = 0
  self.switcher.maximum = 1 
  self.switcher.palette.foreground_dec.text = "▲"
  self.switcher.palette.foreground_inc.text = "▼"
  self.switcher.on_press = function(obj) 
    if (not self.active) then
      return false
    end
    if(self.__edit_page~=obj.index)then
      self.__edit_page = obj.index
      self:update()
      if(self.__edit_page~=self.__play_page) then
        self:update_position(self.__playback_pos.sequence)
      end
      return true
    end
    return false
  end
  self.display:add(self.switcher)

  -- sideways (track scrolling)
  -- placed in same group as the page selector, to the right 

  self.scroller = UISpinner(self.display)
  self.scroller.group_name = self.controls_group_name
  self.scroller.index = 0
  self.scroller.step_size = 1
  self.scroller.minimum = 0
  self.scroller.maximum = 1
  self.scroller.x_pos = 3
  self.scroller.palette.foreground_dec.text = "◄"
  self.scroller.palette.foreground_inc.text = "►"
  self.scroller.on_press = function(obj) 
    TRACE("self.scroller.on_press:",obj.index)
    if (not self.active) then
      return false
    end
    self.__track_offset = obj.index*self.width
    self:update()
    return true
  end
  self.display:add(self.scroller)

  -- play-position (navigator)
  -- 

  -- quick hack to make a UISlider appear like a selector
  -- (TODO make into proper/custom class, capable of displaying
  --  the current position, looped range and scheduled pattern)
  self.position = UISlider(self.display)
  self.position.group_name = self.trigger_group_name
  self.position.x_pos = 1
  self.position.y_pos = 1
  self.position.toggleable = true
  self.position.flipped = true
  self.position.ceiling = self.height
  self.position.palette.foreground.text="►"
  self.position.palette.medium.text="·"
  self.position.palette.medium.color={0x00,0x00,0x00}
  self.position:set_size(self.height)
  -- position changed from controller
  self.position.on_change = function(obj) 

    if not self.active then
      return false
    end

    local seq_index = obj.index + (self.height*self.__edit_page)
    local seq_offset = self.__playback_pos.sequence%self.height

    if obj.index==0 then
      
      -- the position was toggled off
      if (self.play_mode == self.PLAY_MODE_RETRIG) then
        self:retrigger_pattern()
      elseif (self.play_mode == self.PLAY_MODE_PLAY) then
        return false
      elseif (self.play_mode == self.PLAY_MODE_TOGGLE) then
        renoise.song().transport:stop()
      elseif (self.play_mode == self.PLAY_MODE_SCHEDULE) then
        seq_index = self.__playback_pos.sequence + 
          (self.height*self.__edit_page)
        if renoise.song().sequencer.pattern_sequence[seq_index] then
          renoise.song().transport:set_scheduled_sequence(seq_index)
        end
      end

    elseif not renoise.song().sequencer.pattern_sequence[seq_index] then

      -- position out of bounds

      if (self.out_of_bounds == self.BOUNDS_MODE_STOP) then
        renoise.song().transport:stop()
        return true -- allow the button to flash briefly 
      end
      return false

    elseif(self.__playback_pos.sequence==seq_index)then

      -- position toggled back on

      if (self.play_mode == self.PLAY_MODE_RETRIG) then
        self:retrigger_pattern()
      elseif (self.play_mode == self.PLAY_MODE_PLAY) then
        if (not renoise.song().transport.playing) then
          if renoise.song().sequencer.pattern_sequence[seq_index] then
            renoise.song().transport:trigger_sequence(seq_index)
          end
        end
      elseif (self.play_mode == self.PLAY_MODE_SCHEDULE) then
        if renoise.song().sequencer.pattern_sequence[seq_index] then
          renoise.song().transport:set_scheduled_sequence(seq_index)
        end
      elseif (self.play_mode == self.PLAY_MODE_TOGGLE) then
        if (not renoise.song().transport.playing) then
          if renoise.song().sequencer.pattern_sequence[seq_index] then
            renoise.song().transport:trigger_sequence(seq_index)
          end
        end
      end

    else

      -- switch to new position

      if (not renoise.song().transport.playing) then
        -- start playback if stopped
        if renoise.song().sequencer.pattern_sequence[seq_index] then
          renoise.song().transport:trigger_sequence(seq_index)
        end
      else
        if(self.switch_mode == self.SWITCH_MODE_SCHEDULE) then
          if renoise.song().sequencer.pattern_sequence[seq_index] then
            -- schedule, but do not update display
            renoise.song().transport:set_scheduled_sequence(seq_index)
            return false
          end
        elseif(self.switch_mode == self.SWITCH_MODE_SWITCH) then
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
        elseif(self.switch_mode == self.SWITCH_MODE_STOP) then
          renoise.song().transport:stop()
        elseif(self.switch_mode == self.SWITCH_MODE_TRIG) then
          if renoise.song().sequencer.pattern_sequence[seq_index] then
            self.__playback_pos.sequence = seq_index
            self:retrigger_pattern()
          end
        end
      end
    end
    return true
  end
  self.display:add(self.position)

  -- grid buttons

  self.buttons = {}
  for x=1,self.width do
    self.buttons[x] = {}

    for y=1,self.height do
      self.buttons[x][y] = UIToggleButton(self.display)
      self.buttons[x][y].group_name = self.matrix_group_name
      self.buttons[x][y].x_pos = x
      self.buttons[x][y].y_pos = y
      self.buttons[x][y].active = false

      -- controller button pressed & held
      self.buttons[x][y].on_hold = function(obj) 
        TRACE("controller button pressed and held")
        obj:toggle()
        -- bring focus to pattern/track
        if (#renoise.song().tracks>=x) then
          renoise.song().selected_track_index = x
        end
        if renoise.song().sequencer.pattern_sequence[y] then
          renoise.song().selected_sequence_index = y
        end
      end

      -- controller button was pressed
      self.buttons[x][y].on_change = function(obj) 

        if not self.active then
          return false
        end

        local seq = renoise.song().sequencer.pattern_sequence
        local master_idx = get_master_track_index()
        local seq_offset = self.__edit_page*self.height

        if x+self.__track_offset == master_idx then
          --print('Notice: Master-track cannot be muted')
          return false
        elseif not renoise.song().tracks[x+self.__track_offset] then
          --print('Notice: Track is outside bounds')
          return false
        elseif not seq[y+seq_offset] then
          --print('Notice: Pattern is outside bounds')
          return false
        else
          renoise.song().sequencer:set_track_sequence_slot_is_muted(
            (x+self.__track_offset),(y+seq_offset),(not obj.active))-- "active" is negated
        end
        return true
      end

      self.display:add(self.buttons[x][y])

    end  
  end
end

--------------------------------------------------------------------------------

-- update slots visual appeareance 

function PatternMatrix:update()
  TRACE("PatternMatrix:update()")
  if (not self.active) then
    return
  end

  if self.__update_slots_requested then
    -- do lazy updates in idle...
    return
  end

  TRACE("PatternMatrix:update() - proceed")

  local sequence = renoise.song().sequencer.pattern_sequence
  local tracks = renoise.song().tracks

  local seq_offset = self.__edit_page*self.height
  local master_idx = get_master_track_index()
  
  local patt_idx = nil
  local button = nil
  local slot_muted = nil
  local slot_empty = nil
  local palette = {
    foreground = table.create(),
    foreground_dimmed = table.create(),
    background = table.create(),
  }

  -- loop through matrix & buttons

  for track_idx = (1+self.__track_offset),(self.width+self.__track_offset) do
    for seq_index = (1+seq_offset),(self.height+seq_offset) do

      button = self.buttons[track_idx-self.__track_offset][seq_index-seq_offset]

      if((sequence[seq_index]) and (renoise.song().tracks[track_idx]))then

        -- gain information about the slot
        patt_idx = sequence[seq_index]
        slot_muted = renoise.song().sequencer:track_sequence_slot_is_muted(
          track_idx, seq_index)

        slot_empty = renoise.song().patterns[patt_idx].tracks[track_idx].is_empty

        if (not slot_empty) then

          -- slot with content
          palette.foreground.text="■"
          palette.foreground.color={0xff,0xff,0x00}
          palette.foreground_dimmed.text="■"
          palette.foreground_dimmed.color={0xff,0xff,0x00}
          palette.background.text="□"
          palette.background.color={0x80,0x40,0x00} 
          if (track_idx==master_idx)then -- master track is green
            palette.foreground.color={0x40,0xff,0x00}
          end

        else

          -- empty slot 
          palette.foreground.text="·"
          palette.foreground.color={0x00,0x00,0x00}
          palette.foreground_dimmed.text="·"
          palette.background.text="▫"
          if (track_idx==master_idx)then -- master track is green
            palette.foreground_dimmed.color={0x00,0x40,0x00}
            palette.background.color={0x00,0x40,0x00}
          --elseif(track_idx>master_idx)then -- send track
          else -- normal track
            palette.foreground_dimmed.color={0x00,0x00,0x00}
            palette.background.color={0x40,0x00,0x00}
          end

        end

        button:set_dimmed(slot_empty)
        button:set(not slot_muted)

      elseif button then

        -- out-of-bounds space (below/next to song)
        palette.background.text=""
        palette.background.color={0x40,0x40,0x00}
        button:set(false)
        button:set_dimmed(false)

      end
      
      if(button)then
        button:set_palette(palette)
      end

    end
  end
end

--------------------------------------------------------------------------------

-- update scroller (on new song, and when tracks have been changed)
-- + no event fired

function PatternMatrix:update_track_count() 
  TRACE("PatternMatrix:update_track_count")

  local count = math.floor((#renoise.song().tracks-1)/self.width)
  self.scroller:set_maximum(count)
end


--------------------------------------------------------------------------------

-- update page switcher index 
-- + no event fired

function PatternMatrix:update_page_switcher()
  TRACE("PatternMatrix:update_page_switcher()")

  local skip_event_handler = true
  self.switcher:set_index(self.__play_page, skip_event_handler)
  
  self.__edit_page = self.__play_page
end


--------------------------------------------------------------------------------

-- update the switcher (when the number of pattern have changed)
-- + no event fired

function PatternMatrix:update_page_count()

  local seq_len = #renoise.song().sequencer.pattern_sequence
  local page_count = math.floor((seq_len-1)/self.height)
  self.switcher:set_maximum(page_count)
end


--------------------------------------------------------------------------------

-- update position in sequence
-- @idx: (integer) the index, 0 - song-end

function PatternMatrix:update_position(idx)
  local pos_idx = nil
  if(self.__playing)then
    local play_page = self:get_play_page()
    -- we are at a visible page?
    if(self.__edit_page == play_page)then
      pos_idx = idx-(self.__play_page*self.height)
    else
      pos_idx = 0 -- no, hide playback 
    end
  else
    pos_idx = 0 -- stopped
  end
  self.position:set_index(pos_idx,true)
  self.position:invalidate()

end

--------------------------------------------------------------------------------

-- retrigger the current pattern

function PatternMatrix:retrigger_pattern()

  local play_pos = self.__playback_pos.sequence
  if renoise.song().sequencer.pattern_sequence[play_pos] then
    renoise.song().transport:trigger_sequence(play_pos)
    self:update_position(play_pos)
  end
end

--------------------------------------------------------------------------------

function PatternMatrix:get_play_page()

  local play_pos = renoise.song().transport.playback_pos
  return math.floor((play_pos.sequence-1)/self.height)

end

--------------------------------------------------------------------------------

function PatternMatrix:start_app()
  TRACE("PatternMatrix.start_app()")

  Application.start_app(self)

  self.__playing = renoise.song().transport.playing
  self.__playback_pos = renoise.song().transport.playback_pos
  self.__play_page = self:get_play_page()

  -- update everything!
  self:update_page_count()
  self:update_page_switcher()
  self:update_track_count()
  self:update_position(self.__playback_pos.sequence)
  self:update()

end


--------------------------------------------------------------------------------

function PatternMatrix:destroy_app()
  TRACE("PatternMatrix:destroy_app")

  Application.destroy_app(self)

  self.position:remove_listeners()
  for i=1,self.width do
    for o=1,self.height do
      self.buttons[i][o]:remove_listeners()
      self.buttons[i][o]:set(false)

    end
  end

end


--------------------------------------------------------------------------------

-- periodic updates: handle "un-observable" things here

function PatternMatrix:idle_app()
--TRACE("PatternMatrix:idle_app()",self.__update_slots_requested)
  
  if (not self.active) then 
    return 
  end

  -- updated tracks/slots?
  if (self.__update_tracks_requested) then
    -- note: __update_slots_requested is true as well
    self.__update_tracks_requested = false
    self:update_track_count()
  end
  -- 
  if (self.__update_slots_requested) then
    self.__update_slots_requested = false
    self:update()
    self:update_page_count()
  end


  if renoise.song().transport.playing then


    local pos = renoise.song().transport.playback_pos
--[[
    if(self.__num_lines)then
      -- figure out the progress
      local complete = (pos.line/self.__num_lines)
      local counter = math.floor(complete*self.height)
      if (self.position.index == counter) then
        self.progress:set_index(0,true)
        self.progress:invalidate()
      else
        self.progress:set_index(counter,true)
        self.progress:invalidate()
      end

    end
]]

    -- ??? playback_pos might briefly contain the wrong value
    if (pos.sequence ~= self.__playback_pos.sequence)then

      -- changed pattern
      self.__playback_pos = pos

      -- update number of lines (used for progress)
      --local patt_idx = renoise.song().sequencer.pattern_sequence[renoise.song().selected_sequence_index]
      --self.__num_lines = renoise.song().patterns[patt_idx].number_of_lines

      -- check if we need to change page
      local play_page = self:get_play_page()
      if(play_page~=self.__play_page)then
        self.__play_page = play_page
        if(renoise.song().transport.follow_player)then
          if(self.__play_page~=self.__edit_page)then
            -- update only when following play-pos
            self:update_page_switcher()
            self:update()
          end
        end
      end
      self:update_position(pos.sequence)
    elseif (not self.__playing) then
      -- playback resumed
      self:update_position(self.__playback_pos.sequence)
    elseif (self.position.index == 0) and 
      (self.__play_page==self.__edit_page) then
      -- position now in play-range
      self:update_position(self.__playback_pos.sequence)      
    end

    self.__playing = true

  else
    -- if we stopped playing, turn off position
    if(self.__playing) then
      self:update_position(0)
      self.__playing = false
    end
  end
end

--------------------------------------------------------------------------------

-- called when a new document becomes available

function PatternMatrix:on_new_document()
  TRACE("PatternMatrix:on_new_document()")
  self:__attach_to_song(renoise.song())
  self:update_page_count()
  self:update_track_count()
  self:update()

end

--------------------------------------------------------------------------------

-- adds notifiers to slot relevant states

function PatternMatrix:__attach_to_song(song)
  TRACE("PatternMatrix:__attach_to_song()")
  


  -- song notifiers

  song.sequencer.pattern_assignments_observable:add_notifier(
    function()
      TRACE("PatternMatrix: pattern_assignments_observable fired...")
      self.__update_slots_requested = true
    end
  )
  
  song.sequencer.pattern_sequence_observable:add_notifier(
    function(e)
      TRACE("PatternMatrix: pattern_sequence_observable fired...")
      self.__update_slots_requested = true
    end
  )

  song.sequencer.pattern_slot_mutes_observable:add_notifier(
    function()
      TRACE("PatternMatrix:pattern_slot_mutes_observable fired...")
      self.__update_slots_requested = true
    end
  )

  song.tracks_observable:add_notifier(
    function()
      TRACE("PatternMatrix:tracks_observable fired...")
      self.__update_slots_requested = true
    end
  )

  song.patterns_observable:add_notifier(
    function()
      TRACE("PatternMatrix:patterns_observable fired...")
      self.__update_slots_requested = true
    end
  )

  
  -- slot notifiers
  
  local function slot_changed()
    TRACE("PatternMatrix:slot_changed fired...")
    self.__update_slots_requested = true
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
      TRACE("PatternMatrix:tracks_changed fired...")
      self.__update_slots_requested = true
      self.__update_tracks_requested = true
      attach_slot_notifiers()
    end
  )

  song.patterns_observable:add_notifier(
    function()
      TRACE("PatternMatrix:patterns_changed fired...")
      self.__update_slots_requested = true
      attach_slot_notifiers()
    end
  )
end

