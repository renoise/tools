--[[----------------------------------------------------------------------------
-- Duplex.PatternMatrix
----------------------------------------------------------------------------]]--

--[[

  About

  This application will take control of the pattern matrix in Renoise 
  - hit matrix buttons to mute/unmute track slots
  - navigation features (page up/down/left/right), when song follow is on, 
    the matrix will automatically display the currently playing page
  - flexible options for song-position control (switch/retrigger/etc)
  - minimum size (all features enabled): 4x4 (navigation + 3 tracks/patterns)


  ---------------------------------------------------------

  Control-map assignments 

  [][] <- "track" (any input)
  [][] <- "sequence" (any input)

  [][][][]  [<] <- "matrix"  "triggers" (button grid)
  [][][][]  [<]
  [][][][]  [<]
  [][][][]  [<]

  - triggers are "embedded" into the matrix if the
    group_name is an empty string (not nil)

  [] <- "play" (any input)
  [] <- "loop" (any input)
  [] <- "stop" (any input)
  [] <- "rec" (any input)




--]]

--==============================================================================


class 'PatternMatrix' (Application)

function PatternMatrix:__init(display,mappings,options)
  TRACE("PatternMatrix:__init(",display,mappings,options)

  Application.__init(self)

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

  self.options = {
    play_mode = {
      label = "When triggered",
      items = {"Play/continue","Toggle start & stop","Retrigger pattern","Schedule pattern"},
      default = 3,
    },
    switch_mode = {
      label = "When switching",
      items = {"Stop playback","Switch to pattern","Trigger pattern","Schedule pattern"},
      default = 2,
    },
    bounds_mode = {
      label = "When outside",
      items = {"Stop playback","Do nothing"},
      default = 1,
    },
    sync_navigation = {
      label = "Sync global sequence/track position",
      items = {true,false},
      default = 1,
    },
  }
  self:__set_default_options(true)

  -- define the mappings (unassigned)

  self.mappings = {
    matrix = {
      group_name = nil,
      description = "Use matrix group to toggle muted state for slots. Assign to a grid of buttons",
      required = true,
      index = nil,
    },
    triggers = {
      group_name = nil,
      description = "Next to the matrix is the pattern triggers. Assign to a row/column of buttons",
      required = false,
      index = nil,
    },
    sequence = { 
      group_name = nil,
      description = "Use this to flip through the song sequence. Assign to a fader, dial or two buttons",
      required = false,
      index = 0,
    },
    track = {
      group_name = nil,
      description = "Use this to flip through tracks. Assign to a fader, dial or two buttons",
      required = false,
      index = 2,
    },
    --[[
    play = {
      group_name = nil,
      description = "Use this to include a 'start playback' feature. Assign to a button, fader or dial",
      required = false,
      index = 4,
    },
    loop = {
      group_name = nil,
      description = "Use this to include a 'pattern loop' feature. Assign to a button, fader or dial",
      required = false,
      index = 5,
    },
    stop = {
      group_name = nil,
      description = "Use this to include a 'stop playback' feature. Assign to a button, fader or dial",
      required = false,
      index = 6,
    },
    rec = {
      group_name = nil,
      description = "Use this to include a 'toggle recordmode' feature. Assign to a button, fader or dial",
      required = false,
      index = 7,
    },
    ]]
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

  -- control-map should redefine this
  self.width = 4
  self.height = 4

  self.buttons = nil  -- [UIToggleButton,...]
  self.position = nil -- UISlider

  self.display = display


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


  -- apply arguments

  self:apply_options(options)
  self:apply_mappings(mappings)


  -- final steps

  --self:build_app()


end


--------------------------------------------------------------------------------

function PatternMatrix:build_app()
  TRACE("PatternMatrix:build_app()")

  Application.build_app(self)

  -- determine matrix size by looking at the control-map
  local control_map = self.display.device.control_map.groups[self.mappings.matrix.group_name]
  if(control_map["columns"])then
      self.width = control_map["columns"]
      self.height = math.ceil(#control_map/self.width)
  end

  -- if the trigger_group_name is not specified, put it in the matrix 
  local embed_triggers = (not self.mappings.triggers.group_name)
  if(embed_triggers)then
    self.mappings.triggers.group_name = self.mappings.matrix.group_name
    self.width = self.width-1
  end

  local observable = nil

  -- sequence (up/down scrolling)
  self.switcher = UISpinner(self.display)
  self.switcher.group_name = self.mappings.sequence.group_name
  self.switcher.index = self.mappings.track.index
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

  --  track (sideways scrolling)
  self.scroller = UISpinner(self.display)
  self.scroller.group_name = self.mappings.track.group_name
  self.scroller.index = self.mappings.track.index
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
  -- quick hack to make a UISlider appear like a selector
  -- (TODO make into proper/custom class, capable of displaying
  --  the current position, looped range and scheduled pattern)
  local x_pos = 1
  if(embed_triggers)then
    x_pos = self.width+1
  end
  self.position = UISlider(self.display)
  self.position.group_name = self.mappings.triggers.group_name
  self.position.x_pos = x_pos
  self.position.y_pos = 1
  self.position.toggleable = true
  self.position.flipped = true
  self.position.ceiling = self.height

  self.position.palette.background = table.copy(self.palette.trigger_back)
  self.position.palette.tip = table.rcopy(self.palette.trigger_active)
  self.position.palette.track = table.rcopy(self.palette.trigger_back)

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
      if (self.options.play_mode.value == self.PLAY_MODE_RETRIG) then
        self:retrigger_pattern()
      elseif (self.options.play_mode.value == self.PLAY_MODE_PLAY) then
        return false
      elseif (self.options.play_mode.value == self.PLAY_MODE_TOGGLE) then
        renoise.song().transport:stop()
      elseif (self.options.play_mode.value == self.PLAY_MODE_SCHEDULE) then
        seq_index = self.__playback_pos.sequence + 
          (self.height*self.__edit_page)
        if renoise.song().sequencer.pattern_sequence[seq_index] then
          renoise.song().transport:set_scheduled_sequence(seq_index)
        end
      end

    elseif not renoise.song().sequencer.pattern_sequence[seq_index] then

      -- position out of bounds
      if (self.options.bounds_mode.value == self.BOUNDS_MODE_STOP) then
        renoise.song().transport:stop()
        return true -- allow the button to flash briefly 
      end
      return false

    elseif(self.__playback_pos.sequence==seq_index)then

      -- position toggled back on
      if (self.options.play_mode.value == self.PLAY_MODE_RETRIG) then
        self:retrigger_pattern()
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
        if(self.options.switch_mode.value == self.SWITCH_MODE_SCHEDULE) then
          if renoise.song().sequencer.pattern_sequence[seq_index] then
            -- schedule, but do not update display
            renoise.song().transport:set_scheduled_sequence(seq_index)
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
      self.buttons[x][y].group_name = self.mappings.matrix.group_name
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
        TRACE("controller button was pressed",x,y)

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

  -- the finishing touch
  self:__attach_to_song(renoise.song())

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
  local palette = {}

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

        --button:set_dimmed(slot_empty)
        button:set(not slot_muted)

      elseif button then

        -- out-of-bounds space (below/next to song)
        palette.background = table.rcopy(self.palette.out_of_bounds)
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

-- call this method with an options table as argument

function PatternMatrix:apply_options(options)

  Application.apply_options(self,options)

end

--------------------------------------------------------------------------------

-- call this method with an mappings table as argument
-- todo: re-build the UI when mappings have changed

function PatternMatrix:apply_mappings(mappings)

  Application.apply_mappings(self,mappings)

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

  -- "matrix_group_name" is required
  if (not self.mappings.matrix.group_name) then

  -- display some helpful advice
  -- small issue: this dialog can become obscured by the main UI 

    local vb = renoise.ViewBuilder()
    local dlg_title = "PatternMatrix"
    local dlg_text = vb:column{
      margin=10,
      spacing=10,
      vb:text{
        text="Required mapping parameters are missing"
      },
      vb:horizontal_aligner{
        vb:row{
          spacing=6,
          vb:checkbox{
            id="choice",
            value=true
          },
          vb:text{
            text="Open 'Options' dialog and correct this",
          }
        }
      }
    }
    local dlg_buttons = {"OK"}
    renoise.app():show_custom_prompt(dlg_title,dlg_text,dlg_buttons)

    if (vb.views.choice.value) then
      self:build_options()
      self:show_app()
    end

    return false
  end

  if not (self.created) then 
    self:build_app()
  end

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

  if (self.position) then
    self.position:remove_listeners()
  end

  if (self.buttons) then
    for i=1,self.width do
      for o=1,self.height do
        self.buttons[i][o]:remove_listeners()
        self.buttons[i][o]:set(false)
      end
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

