--[[============================================================================
-- Duplex.Application.StepSequencer 
============================================================================]]--

--[[--
Use your grid controller as a basic step sequencer.
Inheritance: @{Duplex.Application} > Duplex.Application.StepSequencer 

Each button in the grid corresponds to a line in a track. The grid 
is scrollable too - use the line/track mappings to access any part of the 
pattern you're editing. 

Originally written by daxton.fleming@gmail.com

### How to use:

- Press an empty button to put a note down, using the currently selected 
  instrument, base-note and volume
- Press a lit button to remove the note
- Press and hold a lit button to copy the note. Toggle a note on/off somewhere 
  else to paste the copied note to this location
- Transpose note up/down by pressing and holding any number of notes, and then 
  pressing the transpose buttons. Changes will be applied to all held notes
- Adjust note volume by pressing and holding any number of notes, and then 
  pressing a level button. Changes will be applied to all held notes
- Press level/transpose buttons when no notes are held, to adjust the base-note 
  and default volume

### Changes



  0.98.21
    - Support line_notifier when slots are aliased (also when created and/or removed)
    - Workflow: when navigating from a long pattern into a shorter one, start from 
      the top (IOW, always restrict to the actual pattern length)
    - Fixed: update the volume-level display when base volume is changed
    - Fixed: selecting a group track could cause an error

  0.98.20
    - Fixed: focus bug when holding button

  0.98.18
    - Mappings track, level, line, transpose are now optional. This should fix an 
      issue with the nano2K config that didn’t specify ‘track’
    - Fixed: under certain conditions, could throw error on startup

  0.98  
    - Palette now uses the standard format (easier to customize)
    - Sequencer tracks can be linked with instruments, simply by assigning 
      the same name to both. 
      UISpinner (deprecated) control replaced with UISlider+UIButton(s)

  0.96
    - Option: "follow_track", set to align to selected track in Renoise
    - Option: "track_increment", specify custom step size for track-switching

  0.95  
    - The sequencer is now fully synchronized with the currently selected 
      pattern in  Renoise. You can copy, delete or move notes around, 
      and the StepSequencer will update it's display accordingly
    - Enabling Renoise's follow mode will cause instant catch-up
    - Display volume/base-note changes in the status bar
    - Orientation: use as sideways 16-step sequencer on monome128 etc.
    - Option: "increment by this amount" value for navigating lines
    - Improved performance 

  0.93  
    - Support other devices than the Launchpad (such as the monome)
    - Display playposition and volume simultaneously 

  0.92  
    - Original version


--]]


--==============================================================================

-- global song reference 

rns = nil

-- constants

local COLUMNS_SINGLE = 1
local COLUMNS_MULTI = 2
local FOLLOW_TRACK_ON = 1
local FOLLOW_TRACK_OFF = 2
local TRACK_PAGE_AUTO = 1
local FOLLOW_LINE_ON = 1
local FOLLOW_LINE_OFF = 2

--==============================================================================


class 'StepSequencer' (Application)

StepSequencer.default_options = {
  line_increment = {
    label = "Line increment",
    description = "Choose the number of lines to jump for each step "
                .."when flipping through pattern",
    on_change = function(inst)
      inst:_update_line_count()
    end,
    items = {
      "1","2","3","4",
      "5","6","7","8",
      "9","10","11","12",
      "13","14","15","16"
    },
    value = 8,
  },
  follow_track = {
    label = "Follow track",
    description = "Enable this if you want to align the sequencer with " 
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
  follow_line = {
    label = "Follow line",
    description = "Enable this if you want to align the sequencer with " 
                .."\nthe selected line in Renoise",
    --on_change = function(inst)
    --  inst:_follow_track()
    --end,
    items = {
      "Follow line enabled",
      "Follow line disabled"
    },
    value = 2,
  },
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
}

StepSequencer.available_mappings = {
  grid = {
    description = "Sequencer: press to toggle note on/off"
                .."\nHold single button to copy note"
                .."\nHold multiple buttons to adjust level/transpose"
                .."\nControl value: ",
    orientation = ORIENTATION.VERTICAL,
  },
  level = {
    -- note: this control serves two purposes, as it will also display the 
    -- currently playing line - therefore, it needs to be the same size
    -- as the grid (rows if ORIENTATION.VERTICAL, columns if ORIENTATION.HORIZONTAL)
    description = "Sequencer: Adjust note volume",
    orientation = ORIENTATION.VERTICAL,
  },
  line = { 
    component = UISlider,
    description = "Sequencer: Flip up/down through lines",
  },
  prev_line = { 
    component = UIButton,
    description = "Sequencer: Go to previous line",
  },
  next_line = { 
    component = UIButton,
    description = "Sequencer: Go to next line",
  },
  track = {
    description = "Sequencer: Flip through tracks",
    orientation = ORIENTATION.HORIZONTAL,
  },
  transpose = {
    description = "Sequencer: 4 buttons for transpose"
                .."\n1st: Oct down"
                .."\n2nd: Semi down"
                .."\n3rd: Semi up"
                .."\n4th: Oct up"
                .."\nControl value: ",
  },
}

StepSequencer.default_palette = {
  out_of_bounds     = { color={0x40,0x40,0x00}, text="·", val=false},
  slot_empty        = { color={0x00,0x00,0x00}, text="·", val=false},
  slot_current      = { color={0x00,0x00,0x00}, text="·", val=false },
  slot_muted        = { color={0x40,0x00,0x00}, text="▫", val=false},
  slot_level_1      = { color={0x00,0x40,0xff}, text="▪", val=true},
  slot_level_2      = { color={0x00,0x80,0xff}, text="▪", val=true},
  slot_level_3      = { color={0x00,0xc0,0xff}, text="▪", val=true},
  slot_level_4      = { color={0x00,0xff,0xff}, text="▪", val=true},
  slot_level_5      = { color={0x40,0xff,0xff}, text="▪", val=true},
  slot_level_6      = { color={0x80,0xff,0xff}, text="▪", val=true},
  transpose_12_down = { color={0xff,0x00,0xff}, text="-12",val=false},
  transpose_1_down  = { color={0xc0,0x40,0xff}, text="-1", val=false},
  transpose_1_up    = { color={0x40,0xc0,0xff}, text="+1", val=false},
  transpose_12_up   = { color={0x00,0xff,0xff}, text="+12",val=false},
  prev_line_off     = { color={0x00,0x00,0x00}, text="-ln", val=false},
  prev_line_on      = { color={0xff,0xff,0xff}, text="-ln", val=true},
  next_line_off     = { color={0x00,0x00,0x00}, text="+ln", val=false},
  next_line_on      = { color={0xff,0xff,0xff}, text="+ln", val=true},


}


--------------------------------------------------------------------------------

--- constructor method
-- @param (VarArg)
-- @see Duplex.Application

function StepSequencer:__init(...)
  TRACE("StepSequencer:__init(",...)

  rns = renoise.song()

  --- default note/volume
  self._base_note = 1
  self._base_octave = 4
  self._base_volume = 100

  --- default note-grid size 
  self._track_count = 8
  self._line_count = 8

  --- the currently editing "page"
  self._edit_page = 0          
  self._edit_page_count = nil

  --- the track offset (0-#tracks)
  self._track_offset = 0       
  self._track_page = nil

  --- true when song follow is enabled, 
  -- set to false when using the line navigator
  self._follow_player = nil    

  --- a "fire once" flag, which is set when
  -- switching from "not follow" to "follow"
  self._start_tracking = false 
                                
  --- remember the current pattern index here
  self._current_pattern = nil  
  
  --- remember the current line index
  self._current_line_index = nil  
  
  self._update_lines_requested = false
  self._update_tracks_requested = false
  self._update_grid_requested = false

  --- collect patterns indices with line_notifiers 
  self._line_notifiers = table.create()

  --- collect references to pattern-alias notifier methods
  self._alias_notifiers = table.create()
  
  -- true when current track should be highlighted
  -- (actual value is derived from the palette)
  self._highlight_track = false

  -- the various controls
  self._buttons = {}
  self._level = nil
  self._line_navigator = nil
  self._track_navigator = nil
  self._transpose = nil

  --- track held grid keys
  self._keys_down = { } 
  
  --- don't toggle off if pressing multiple on / transposing / etc
  self._toggle_exempt = { } 

  Application.__init(self,...)

end


--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.start_app
-- @return bool or nil

function StepSequencer:start_app()
  TRACE("StepSequencer.start_app()")

  if not Application.start_app(self) then
    return
  end

  self._follow_player = rns.transport.follow_player

  -- determine if we should highlight the current track
  if not table_compare(self.palette.slot_empty.color,self.palette.slot_current.color)
    or (self.palette.slot_empty.text ~= self.palette.slot_current.text)
    or (self.palette.slot_empty.val ~= self.palette.slot_current.val)
  then
    self._highlight_track = true
  end

  -- update everything!
  self:_update_line_count()
  self:_update_track_count()
  self:_update_line_buttons()
  self:_update_grid()
  self:_follow_track()

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.stop_app

function StepSequencer:stop_app()
  TRACE("StepSequencer:stop_app()")

  self:remove_line_notifiers()
  Application.stop_app(self)

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application._build_app
-- @return bool

function StepSequencer:_build_app()
  TRACE("StepSequencer:_build_app()")

  -- determine grid size by looking at the control-map
  local cm_group = self.display.device.control_map.groups[
    self.mappings.grid.group_name]
  
  if not cm_group then
    local msg = "StepSequencer cannot initialize, the required mapping 'grid' is missing"
    renoise.app():show_warning(msg)
    return false
  end
  if (cm_group["columns"])then
    if(self:_get_orientation()==ORIENTATION.VERTICAL) then
      self._track_count = cm_group["columns"]
      self._line_count = math.ceil(#cm_group/self._track_count)
    else
      self._line_count = cm_group["columns"]
      self._track_count = math.ceil(#cm_group/self._line_count)
    end
  else
    -- not a grid controller? 
    local msg = "StepSequencer: the 'grid' mapping can only be assigned to a grid of buttons"
    renoise.app():show_warning(msg)
    return false
  end


  -- build each section's controllers
  self:_build_line()
  self:_build_track()
  self:_build_grid()
  self:_build_level()
  self:_build_transpose()

  -- bind observables
  self:_attach_to_song()

  Application._build_app(self)
  return true

end


--------------------------------------------------------------------------------

--- line (up/down scrolling)

function StepSequencer:_build_line()
  TRACE("StepSequencer:_build_line()")

  local map = self.mappings.line
  if map.group_name then

    --[[
    local c = UISpinner(self)
    c.group_name = self.mappings.line.group_name
    c.tooltip = self.mappings.line.description
    c:set_pos(self.mappings.line.index)
    c:set_orientation(self.mappings.line.orientation)
    c.text_orientation = ORIENTATION.VERTICAL
    c.step_size = 1
    c.on_change = function(obj) 

      if(self._edit_page~=obj.index)then
        self._edit_page = obj.index
        self._follow_player = false
        self:_update_grid()
        return true
      end

      return false

    end
    self._line_navigator = c
    ]]

    local c = UISlider(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c:set_orientation(map.orientation)
    c.on_change = function(obj) 
      set_page(obj.index)
    end
    self._line_navigator = c
  
  end

  local map = self.mappings.prev_line
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_release = function() 
      self:jump_to_prev_lines()
    end
    c.on_hold = function() 
      self:jump_to_top()
    end
    self._prev_line = c
  end

  local map = self.mappings.next_line
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_release = function() 
      self:jump_to_next_lines()
    end
    c.on_hold = function()
      self:jump_to_bottom()
    end
    self._next_line = c
  end

end


--------------------------------------------------------------------------------

---  track (sideways scrolling)

function StepSequencer:_build_track()
  TRACE("StepSequencer:_build_track()")

  if self.mappings.track.group_name then

    local c = UISpinner(self)
    c.group_name = self.mappings.track.group_name
    c.tooltip = self.mappings.track.description
    c:set_pos(self.mappings.track.index)
    c:set_orientation(self.mappings.track.orientation)
    --c.text_orientation = ORIENTATION.HORIZONTAL
    c.on_change = function(obj) 

      local page_width = self:_get_page_width()
      local track_idx = (obj.index*page_width)
      if (self.options.follow_track.value == FOLLOW_TRACK_ON) then
        -- if the follow_track option is specified, we set the
        -- track index and let the _follow_track() method handle it
        rns.selected_track_index = 1+track_idx
      else
        self._track_offset = obj.index*self:_get_page_width()
        self:_update_grid()
      end

    end
    self._track_navigator = c
  end

end


--------------------------------------------------------------------------------

--- construct user interface

function StepSequencer:_build_grid()
  TRACE("StepSequencer:_build_grid()")

  local orientation = self:_get_orientation()

  for track_idx=1,self._track_count do
    for line_idx=1,self._line_count do

      local x,y = track_idx,line_idx

      if not (orientation==ORIENTATION.VERTICAL) then
        x,y = y,x
      end

      -- construct tables
      if (not self._buttons[x]) then
        self._buttons[x] = {}
      end
      if (not self._keys_down[x]) then
        self._keys_down[x] = {}
      end
      if (not self._toggle_exempt[x]) then
        self._toggle_exempt[x] = {}
      end

      local c = UIButton(self)
      c.group_name = self.mappings.grid.group_name
      c.tooltip = self.mappings.grid.description
      c.x_pos = x
      c.y_pos = y

      -- grid toggling
      c.on_press = function(obj)
        self:_process_grid_event(x, y, true,obj)
      end
      c.on_release = function(obj)
        self:_process_grid_event(x, y, false,obj)
      end
      
      -- hold to "pick up" note, volume & instrument (ie copy step)
      c.on_hold = function(obj)

        -- check if we're holding multiple keys
        local held = self:_walk_held_keys(nil, false)
        if (held == 1) then
          self._toggle_exempt[x][y] = true
          self:_copy_grid_button(x,y,obj)

          local msg = "StepSequencer: note was copied"
          renoise.app():show_status(msg)

          -- make it blink off (visual feedback)
          local palette = {}
          palette.foreground = table.rcopy(self.palette.slot_empty)
          obj:set_palette(palette)
          self._update_grid_requested = true

          -- bring focus to track
          local track_idx = nil
          if (orientation==ORIENTATION.HORIZONTAL) then
            track_idx = y + self._track_offset
          else
            track_idx = x + self._track_offset
          end
          rns.selected_track_index = track_idx
        end

      end
      self._buttons[x][y] = c
    end  
  end
end


--------------------------------------------------------------------------------

--- construct user interface

function StepSequencer:_build_level()
  TRACE("StepSequencer:_build_level()")

  if self.mappings.level.group_name then


    -- figure out the number of rows in our level-slider group
    local cm = self.display.device.control_map

    -- level buttons
    local c = UIButtonStrip(self)
    c.group_name = self.mappings.level.group_name
    c.tooltip = self.mappings.level.description
    c.toggleable = false
    c.monochrome = is_monochrome(self.display.device.colorspace)
    c.mode = c.MODE_INDEX
    c.flipped = true
    c:set_orientation(self.mappings.level.orientation)
    c:set_size(self._line_count)
    c.on_index_change = function(obj) 

      local idx = obj:get_index()
      local idx_flipped = obj._size-obj:get_index()+1
      local newval = (127/(obj._size-1)) * (idx_flipped-1)

      -- check for held grid notes
      local held = self:_walk_held_keys(
        function(track_idx,line_idx)
          if (self:_get_orientation()==ORIENTATION.HORIZONTAL) then
            track_idx,line_idx = line_idx,track_idx
          end
          local tracks = rns.selected_pattern.tracks[track_idx + self._track_offset]
          local inc = self.options.line_increment.value
          local note = tracks:line(line_idx + self._edit_page * inc).note_columns[1]
          note.volume_value = newval
        end,
        true
      )
      if (held == 0) then 
        -- no keys down, change basenote instead of transpose
        self._base_volume = newval
        local msg = string.format(
          "StepSequencer: Volume changed to %X",newval)
        renoise.app():show_status(msg)
      end
      self._update_grid_requested = true
      self:_draw_volume_slider(newval)
      return true
    end
    self._level = c
  end

end


--------------------------------------------------------------------------------

--- construct user interface

function StepSequencer:_build_transpose()
  TRACE("StepSequencer:_build_transpose()")

  if self.mappings.transpose.group_name then


    self._transpose = { }
    local transposes = { -12, -1, 1, 12 }
    for k,v in ipairs(transposes) do
      
      local c = UIButton(self)
      c.group_name = self.mappings.transpose.group_name
      c.tooltip = self.mappings.transpose.description
      c:set_pos(self.mappings.transpose.index+(k-1))
      c.transpose = v
      if (k==1) then
        c:set(self.palette.transpose_12_down)
      elseif (k==2) then
        c:set(self.palette.transpose_1_down)
      elseif (k==3) then
        c:set(self.palette.transpose_1_up)
      elseif (k==4) then
        c:set(self.palette.transpose_12_up)
      end
      c.on_press = function(obj)
        
        -- check for held grid notes
        local held = self:_walk_held_keys(
          function(x,y)
            if (self:_get_orientation()==ORIENTATION.HORIZONTAL) then
              x,y = y,x
            end
            local inc = self.options.line_increment.value
            local note = rns.selected_pattern.tracks[x + self._track_offset]:line(
              y + self._edit_page * inc).note_columns[1]
            local newval = note.note_value + obj.transpose
            if (newval > 0 and newval < 120) then 
              note.note_value = newval
            end
          end,
          true
        )
        if (held == 0) then -- no keys down, change basenote instead of transpose
          self:_transpose_basenote(obj.transpose)
        end
      end
      
      self._transpose[k] = c
      
    end

  end

end


--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_idle

function StepSequencer:on_idle()
  --TRACE("StepSequencer:on_idle()")

  if not self.active then 
    return 
  end
  
  -- did we change current_pattern?
  if (self._current_pattern ~= rns.selected_pattern_index) then
    self._current_pattern = rns.selected_pattern_index
    self._update_lines_requested = true
    -- attach notifier to pattern length
    rns.patterns[self._current_pattern].number_of_lines_observable:add_notifier(
      function()
        --TRACE("StepSequencer: pattern length changed")
        self._update_lines_requested = true
        -- check if the edit-page exceed the new length 
        local line_offset = self._edit_page*self.options.line_increment.value
        local patt = rns.patterns[self._current_pattern]
        if (line_offset>patt.number_of_lines) then
          self._edit_page = 0 -- reset
        end
      end
    )
  end

  -- check if the current line changed
  if not rns.transport.follow_player and
    (self.options.follow_line.value == FOLLOW_LINE_ON) 
  then
    local line_index = rns.transport.edit_pos.line
    if (self._current_line_index ~= line_index) then
      self._current_line_index = line_index
      self:_update_page()
    end
  end

  -- check update flags
  if self._update_tracks_requested then
    self._update_grid_requested = true
    self._update_tracks_requested = false
    self:_update_track_count()
  end
  -- 
  if self._update_lines_requested then
    self._update_grid_requested = true
    self._update_lines_requested = false
    self:_update_line_count()
  end
  
  if self._update_grid_requested then
    self._update_grid_requested = false
    self:_update_grid()
  end
  
  if rns.transport.playing then
    self:_update_position()
  else
    -- clear level?
    self:_draw_position(0)
  end

end

--------------------------------------------------------------------------------

--- update track navigator,
-- on new song, and when tracks have been changed

function StepSequencer:_update_track_count()
  TRACE("StepSequencer:_update_track_count")

  if self._track_navigator then
    local page_width = self:_get_page_width()
    local count = math.floor((get_master_track_index()-2)/page_width)
    self._track_navigator:set_range(nil,count)
  end

end


--------------------------------------------------------------------------------

--- if the playback position is inside visible range of the sequencer, update
-- the position indicator
-- else, if follow mode is active, display the current page
-- (called on_idle when playing)

function StepSequencer:_update_position()
  --TRACE("StepSequencer:_update_position()")

  local pos = self:get_pos()
  if self:_line_is_visible(pos.line) then
    local line_offset = self._edit_page*self.options.line_increment.value
    self:_draw_position(((pos.line-1-line_offset)%self._line_count)+1)
  else
    if self._follow_player or
       self._start_tracking 
    then      
      self:_update_page()
      self._start_tracking = false
    else
      self:_draw_position(0)
    end
  end

end


--------------------------------------------------------------------------------

--- check if we should switch the active page/range inside the pattern

function StepSequencer:_update_page()
  TRACE("StepSequencer:_update_page")

  local pos = self:get_pos()

  local page = math.ceil(pos.line/self.options.line_increment.value)-1
  if (page~=self._edit_page) or
    (self._start_tracking) then
    self._edit_page = page
    if self._line_navigator then
      self._line_navigator:set_index(page,true)
    end
    self._update_grid_requested = true
  end

end

--------------------------------------------------------------------------------

--- get the current position (edit-pos when stopped, playpos when playing)
-- @return SongPos

function StepSequencer:get_pos()
  TRACE("StepSequencer:get_pos")

  local pos = nil
  if not rns.transport.follow_player and
    (self.options.follow_line.value == FOLLOW_LINE_ON) 
  then
    pos = rns.transport.edit_pos
  else
    pos = rns.transport.playback_pos
  end

  return pos

end

--------------------------------------------------------------------------------

--- set the current edit page
-- @param idx (int)

function StepSequencer:set_page(idx)
  TRACE("StepSequencer:set_page(idx)",idx)
  if(self._edit_page~=idx)then
    self._edit_page = idx
    self:post_jump_update()
  end
end

--------------------------------------------------------------------------------

--- jump to topmost page

function StepSequencer:jump_to_top()
  TRACE("StepSequencer:jump_to_top()")
  self._edit_page = 1
  self:post_jump_update()
end

--------------------------------------------------------------------------------

--- jump to bottommost page

function StepSequencer:jump_to_bottom()
  TRACE("StepSequencer:jump_to_bottom()")
  self._edit_page = self._edit_page_count
  self:post_jump_update()
end

--------------------------------------------------------------------------------

--- jump to previous page

function StepSequencer:jump_to_prev_lines()
  TRACE("StepSequencer:jump_to_prev_lines()")
  if (self._edit_page > 0) then
    self._edit_page = self._edit_page-1
    self:post_jump_update()
  end
end

--------------------------------------------------------------------------------

--- jump to next page

function StepSequencer:jump_to_next_lines()
  TRACE("StepSequencer:jump_to_next_lines()")
  if (self._edit_page <= (self._edit_page_count-1)) then
    self._edit_page = self._edit_page+1
    self:post_jump_update()
  end
end

--------------------------------------------------------------------------------

--- update display after a jump

function StepSequencer:post_jump_update()
  --TRACE("StepSequencer:post_jump_update()")

  self._follow_player = false
  self:_update_grid()
  self:_update_line_buttons()

end

--------------------------------------------------------------------------------

--- called on_idle 

function StepSequencer:_draw_position(idx)
  --TRACE("StepSequencer:_draw_position(idx)",idx)

  if self._level and rns.transport.playing then
    local ctrl_idx = self._level:get_index()
    if (ctrl_idx~=idx) then
      self._level:set_index(idx,true)
      TRACE("StepSequencer:_draw_position(",idx,")")
    end
  end

end


--------------------------------------------------------------------------------

--- update the range of the line navigator

function StepSequencer:_update_line_count()
  TRACE("StepSequencer:_update_line_count()")

  if not self.active then 
    return 
  end

  local pattern = nil
  if (self._follow_player) then
    pattern = get_playing_pattern()
  else
    pattern = rns.selected_pattern
  end
  local inc = self.options.line_increment.value
  self._edit_page_count = math.ceil(math.floor(pattern.number_of_lines)/inc)-1
  if self._line_navigator then
    --self._line_navigator:set_range(0,rng)
    self._line_navigator.steps = self._edit_page_count
    --print("self._edit_page_count:",self._edit_page_count)
  end

end


--------------------------------------------------------------------------------

--- update the display (line buttons)

function StepSequencer:_update_line_buttons()
  TRACE("StepSequencer:_update_line_buttons()")

  local ctrl = self._next_line 
  local palette = {}
  if ctrl then
    if (self._edit_page <= (self._edit_page_count-1)) then
      palette.foreground = table.rcopy(self.palette.next_line_on)
    else
      palette.foreground = table.rcopy(self.palette.next_line_off)
    end
    ctrl:set_palette(palette)
  end
  local ctrl = self._prev_line 
  if ctrl then
    if (self._edit_page > 0) then
      palette.foreground = table.rcopy(self.palette.prev_line_on)
    else
      palette.foreground = table.rcopy(self.palette.prev_line_off)
    end
    ctrl:set_palette(palette)
  end

end

--------------------------------------------------------------------------------

--- update the display (main grid)

function StepSequencer:_update_grid()
  TRACE("StepSequencer:_update_grid()")

  if not self.active then 
    return 
  end

  local orientation = self:_get_orientation()

  -- loop through grid & buttons
  local line_offset = self._edit_page*self.options.line_increment.value
  local master_idx = get_master_track_index()
  local track_count = #rns.tracks
  local selected_pattern_tracks = rns.selected_pattern.tracks
  local selected_pattern_lines = rns.selected_pattern.number_of_lines
  for track_idx = (1 + self._track_offset),(self._track_count+self._track_offset) do
    local pattern_track = selected_pattern_tracks[track_idx]
    local current_track = (track_idx==rns.selected_track_index)
    for line_idx = (1 + line_offset),(self._line_count + line_offset) do

      local button = nil
      if(orientation==ORIENTATION.VERTICAL) then
        button = self._buttons[track_idx - self._track_offset][line_idx - line_offset]
      else
        button = self._buttons[line_idx - line_offset][track_idx - self._track_offset]
      end

      if (button ~= nil) then 
        local note = nil
        if (line_idx <= selected_pattern_lines) and
          (track_idx <= track_count) then
          note = pattern_track:line(line_idx).note_columns[1]
        end
        self:_draw_grid_button(button,note,current_track)
      end

    end
  end
end


--------------------------------------------------------------------------------

--- decide if we need to update the display when the pattern editor has changed 
-- note: this method might be called hundreds of times when doing edits like
-- cutting all notes from a pattern, so we need it to be really simple

function StepSequencer:_track_changes(pos)
  TRACE("StepSequencer:_track_changes()",pos)

  if (self:_track_is_visible(pos.track)) and
    (self:_line_is_visible(pos.line)) then
    TRACE("StepSequencer:_track_changes - update_grid_requested")
    self._update_grid_requested = true
  end

end

--------------------------------------------------------------------------------

--- check if a given line is within the visible range
-- @param line_pos (int)

function StepSequencer:_line_is_visible(line_pos)
  
  local line_offset = self._edit_page*self.options.line_increment.value
  return (line_offset < line_pos) and
    (line_pos <= (line_offset+self._line_count))

end

--------------------------------------------------------------------------------

--- check if a given track is within the visible range
-- @param track_idx (int)

function StepSequencer:_track_is_visible(track_idx)

  return (track_idx>(self._track_offset)) and
    (track_idx<=(self._track_offset+self._track_count))

end

--------------------------------------------------------------------------------

--- when following the active track in Renoise, we call this method
-- (track following is limited to sequencer tracks)

function StepSequencer:_follow_track()
  TRACE("StepSequencer:_follow_track()")

  if (self.options.follow_track.value == FOLLOW_TRACK_OFF) then
    return
  end

  local master_idx = get_master_track_index()
  local track_idx = math.min(rns.selected_track_index,master_idx-1)
  local page = self:_get_track_page(track_idx)
  local page_width = self:_get_page_width()
  if (page~=self._track_page) then
    self._track_page = page
    self._track_offset = page*page_width
    --self:_update_grid()
    self._update_grid_requested = true
    if self._track_navigator then
      self._track_navigator:set_index(page,true)
    end
  end

  if self._highlight_track then
    self._update_grid_requested = true
  end

end

--------------------------------------------------------------------------------

--- figure out the active "track page" based on the supplied track index
-- @param track_idx, renoise track number
-- return integer (0-number of pages)

function StepSequencer:_get_track_page(track_idx)
  TRACE("StepSequencer:_get_track_page(track_idx)",track_idx)

  local page_width = self:_get_page_width()
  local page = math.floor((track_idx-1)/page_width)
  return page

end

--------------------------------------------------------------------------------

--- get the currently set page width
-- @return int

function StepSequencer:_get_page_width()
  TRACE("StepSequencer:_get_page_width()")

  return (self.options.page_size.value == TRACK_PAGE_AUTO)
    and self._track_count or self.options.page_size.value-1

end


--------------------------------------------------------------------------------

--- get the orientation of the main grid

function StepSequencer:_get_orientation()
  TRACE("StepSequencer:_get_orientation()")
  
  return self.mappings.grid.orientation

end
--------------------------------------------------------------------------------

--- add notifiers to relevant parts of the song

function StepSequencer:_attach_to_song()
  TRACE("StepSequencer:_attach_to_song()")
  
  -- song notifiers
  rns.tracks_observable:add_notifier(
    function()
      TRACE("StepSequencer:tracks_observable fired...")
      -- do this right away (updating the spinner is easily done, and we
      -- avoid that setting the index will fail, because idle() has yet to 
      -- increase the number of track pages...)
      self:_update_track_count()
      self._update_tracks_requested = true
    end
  )
  rns.patterns_observable:add_notifier(
    function()
      TRACE("StepSequencer:patterns_observable fired...")
      self._update_lines_requested = true
    end
  )
  rns.transport.follow_player_observable:add_notifier(
    function()
      TRACE("StepSequencer:follow_player_observable fired...")
      -- if switching on, start tracking actively
      local follow = rns.transport.follow_player
      if not (follow == self._follow_player) then
        self._start_tracking = follow
      end
      self._follow_player = follow
      if(self._follow_player)then   
        self:_update_page()
      end
    end
  )

  -- follow active track in Renoise
  rns.selected_track_index_observable:add_notifier(
    function()
      TRACE("StepSequencer:selected_track_observable fired...")
      self:_follow_track()
    end
  )

  -- monitor changes to the pattern (line notifiers, aliases)
  rns.selected_pattern_observable:add_notifier(
    function()
      TRACE("StepSequencer:selected_pattern_observable fired...")
      local new_song = false
      self:_attach_to_pattern(new_song,self._current_pattern)
    end
  )
  local new_song = true
  self:_attach_to_pattern(new_song,rns.selected_pattern_index)



end

--------------------------------------------------------------------------------

--- add notifiers to the pattern

function StepSequencer:_attach_to_pattern(new_song,patt_idx)
  TRACE("StepSequencer:_attach_to_pattern()",new_song,patt_idx)

  self:_attach_line_notifiers(new_song,patt_idx)
  self:_attach_alias_notifiers(new_song,patt_idx)

end

--------------------------------------------------------------------------------

--- monitor the current pattern for changes to it's aliases

function StepSequencer:_attach_alias_notifiers(new_song,patt_idx)
  TRACE("StepSequencer:_attach_alias_notifiers()",new_song,patt_idx)

  self:_remove_notifiers(new_song,self._alias_notifiers)

  local patt = rns.patterns[patt_idx]
  for track_idx = 1,rns.sequencer_track_count do
    local track = patt.tracks[track_idx]
    self._alias_notifiers:insert(track.alias_pattern_index_observable)
    track.alias_pattern_index_observable:add_notifier(self,
      function(notification)
        TRACE("StepSequencer - alias_pattern_index_observable fired...",notification)
        local new_song = false
        self:_attach_line_notifiers(new_song,rns.selected_pattern_index)
        self._update_tracks_requested = true
      end
    )
  end

end

--------------------------------------------------------------------------------

--- attach line notifiers to pattern 
-- check for existing notifiers first, and remove those
-- then add pattern notifiers to pattern (including aliased slots)

function StepSequencer:_attach_line_notifiers(new_song,patt_idx)
  TRACE("StepSequencer:_attach_line_notifiers()",new_song,patt_idx)

  self:remove_line_notifiers(new_song)

  local patt = rns.patterns[patt_idx]
  if not patt then
    LOG("Couldn't attach line notifiers: pattern #",patt_idx,"does not exist")
    return
  end

  local function attach_to_pattern_lines(patt_idx) 
    TRACE("StepSequencer:_attach_line_notifiers() - attach_to_pattern",patt_idx)
    if not (patt:has_line_notifier(self._track_changes,self))then
      patt:add_line_notifier(self._track_changes,self)
      self._line_notifiers:insert(patt_idx)
    end
  end

  for track_idx = 1,rns.sequencer_track_count do
    local alias_idx = patt.tracks[track_idx].alias_pattern_index
    if (alias_idx~=0) then
      attach_to_pattern_lines(alias_idx)
    else
      attach_to_pattern_lines(patt_idx)
    end
  end

end

--------------------------------------------------------------------------------

--- remove currently attached line notifiers 

function StepSequencer:remove_line_notifiers(new_song)
  TRACE("StepSequencer:remove_line_notifiers()",new_song)

  for patt_idx in ipairs(self._line_notifiers) do
    local patt = rns.patterns[patt_idx]
    TRACE("*** StepSequencer - remove_line_notifier from patt",patt,type(patt))
    if patt and (type(patt)~="number") and (patt:has_line_notifier(self._track_changes,self)) then
      patt:remove_line_notifier(self._track_changes,self)
    end
  end
  self._line_notifiers = table.create()
end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_new_document

function StepSequencer:on_new_document()
  TRACE("StepSequencer:on_new_document()")

  rns = renoise.song()

  local new_song = true
  self:_attach_to_song()
  self:_update_line_count()
  self:_update_track_count()
  self:_update_line_buttons()
  self:_update_grid()
  self:_follow_track()

end


--------------------------------------------------------------------------------
-- STEP SEQUENCER FUNCTIONS
--------------------------------------------------------------------------------

--- handle when button in main grid is pressed

function StepSequencer:_process_grid_event(x,y, state, btn)
  TRACE("StepSequencer:_process_grid_event()",x,y, state, btn)

  local track_idx,line_idx = x,y
  if not (self:_get_orientation() == ORIENTATION.VERTICAL) then
    line_idx,track_idx = track_idx,line_idx
  end

  track_idx = track_idx+self._track_offset
  line_idx = line_idx+self._edit_page*self.options.line_increment.value

  if (track_idx >= get_master_track_index()) then 
    return false 
  end
  
  -- check if we are dealing with a group track
  local track = rns.tracks[track_idx]
  if (track.type == renoise.Track.TRACK_TYPE_GROUP) then
    return
  end

  local current_track = (track_idx == rns.selected_track_index)

  local note = rns.selected_pattern.tracks[track_idx]:line(
    line_idx).note_columns[1]

  -- determine instrument by matching track title with instruments
  -- a matching title will select that instrument 
  local track_name = rns.tracks[track_idx].name
  local instr_index = self:_obtain_instrument_by_name(track_name)
  if not instr_index then
    instr_index = rns.selected_instrument_index
  else
    local msg = "StepSequencer: matched track/instrument name"..track_name
    renoise.app():show_status(msg)
  end

  if (state) then -- press
    self._keys_down[x][y] = true
    if (note.note_string == "OFF" or note.note_string == "---") then
      local base_note = (self._base_note-1) + 
        (self._base_octave-1)*12
      self:_set_note(note, base_note, instr_index-1, 
        self._base_volume)
      self._toggle_exempt[x][y] = true
      -- and update the button ...
      self:_draw_grid_button(btn,note,current_track)
    end
      
  else -- release
    self._keys_down[x][y] = nil
    -- don't toggle off if we just turned on
    if (not self._toggle_exempt[x][y]) then 
      self:_clear_note(note)
      -- and update the button ...
      if (rns.selected_pattern.number_of_lines<line_idx) then
        -- reset to "out of bounds" color
        note = nil
      end
      self:_draw_grid_button(btn,note,current_track)
    else
      self._toggle_exempt[x][y] = nil
    end
  end
  return true
end

--------------------------------------------------------------------------------

--- obtain instrument by name (track<>instrument synchronization)
-- @return (int) instrument index

function StepSequencer:_obtain_instrument_by_name(name)
  TRACE("StepSequencer:_obtain_instrument_by_name()",name)

  for instr_index,instr in ipairs(rns.instruments) do
    if (instr.name == name) then
      return instr_index
    end
  end

end

--------------------------------------------------------------------------------

--- invoked when starting a note-copy gesture (first held button)
-- @param lx (int)
-- @param ly (int)
-- @param btn (@{Duplex.UIButton})

function StepSequencer:_copy_grid_button(lx,ly, btn)
  TRACE("StepSequencer:_copy_grid_button()",lx,ly, btn)

  local gx = lx+self._track_offset
  local gy = ly+self._edit_page*self._line_count

  if not (self:_get_orientation() == ORIENTATION.VERTICAL) then
    gx,gy = gy,gx
  end

  if (gx >= get_master_track_index()) then 
    return false 
  end

  local note = rns.selected_pattern.tracks[gx]:line(gy).note_columns[1]
  
  if not note then
    return false
  end
  -- copy note to base note
  if (note.note_value < 120) then
    self:_set_basenote(note.note_value)
  end
  -- copy volume to base volume
  local note_vol = math.min(128,note.volume_value)
  if (note_vol <= 128) then
    self._base_volume = note_vol
    self:_draw_volume_slider(note_vol)
  end
  -- change selected instrument
  if (note.instrument_value < #rns.instruments) then
    rns.selected_instrument_index = note.instrument_value+1
  end
  
  return true
end

--------------------------------------------------------------------------------

--- update display of volume slider
-- @param volume (int), between 0-127

function StepSequencer:_draw_volume_slider(volume)
  TRACE("StepSequencer:_draw_volume_slider()",volume)
  
  if self._level then

    if not volume then
      volume = self._base_volume
    end 

    local p = { }
    if (volume == 0) then
      p = table.rcopy(self.palette.slot_muted)
    else 
      p = self:_volume_palette(volume, 127)
    end

    local idx = self._level._size-math.floor((volume/127)*self._level._size)
    self._level:set_palette({range = p})
    self._level:set_range(idx,self._level._size)

  end

end

--------------------------------------------------------------------------------

--- write properties into provided note column
-- @param note_obj (NoteColumn)
-- @param note (int) note pitch
-- @param instrument (int) instrument number
-- @param volume (int) note velocity

function StepSequencer:_set_note(note_obj,note,instrument,volume)
  TRACE("StepSequencer:_set_note(note_obj,note,instrument,volume)",note_obj,note,instrument,volume)

  note_obj.note_value = note
  note_obj.instrument_value = instrument
  note_obj.volume_value = volume
end


--------------------------------------------------------------------------------

--- clear properties for note column
-- @param note_obj (NoteColumn)

function StepSequencer:_clear_note(note_obj)
  TRACE("StepSequencer:_clear_note(note_obj)",note_obj)
  self:_set_note(note_obj, 121, 255, 255)
end


--------------------------------------------------------------------------------

--- assign color to button, based on note properties

function StepSequencer:_draw_grid_button(button,note,current_track)
  TRACE("StepSequencer:_draw_grid_button()",button,note,current_track)

  
  if (note ~= nil) then
    if (note.note_value == 121) then
      if current_track then
        button:set(self.palette.slot_current)
      else
        button:set(self.palette.slot_empty)
      end
    elseif (note.note_value == 120 or note.volume_value == 0) then
      button:set(self.palette.slot_muted)
    else
      button:set(self:_volume_palette(note.volume_value, 127))
    end
  else
    button:set(self.palette.out_of_bounds)
  end

end


--------------------------------------------------------------------------------

--- figure out the color for a given volume level 
-- @param vol (int), between 0-127
-- @param max (int), 127

function StepSequencer:_volume_palette(vol, max)
  TRACE("StepSequencer:_volume_palette(vol, max)",vol, max)
  if (vol > max) then 
    vol = max 
  end
  local available_levels = 6 -- the number of slot_level colors
  local vol_level = 1+ math.floor(vol / max * (available_levels-1))
  local swatch_name = ("slot_level_%d"):format(vol_level)
  return table.rcopy(self.palette[swatch_name])
end


--------------------------------------------------------------------------------

--- set basenote for new notes
-- @param note_value (int) note pitch

function StepSequencer:_set_basenote(note_value)
  TRACE("StepSequencer:_set_basenote(note_value)",note_value)
  local note = note_value % 12 +1
  local oct = math.floor(note_value / 12) +1
  self._base_note = note
  self._base_octave = oct
  local msg = string.format(
    "StepSequencer: Basenote changed to %s%i",NOTE_ARRAY[note],oct)

  renoise.app():show_status(msg)

end


--------------------------------------------------------------------------------

--- transpose existing basenote by given amount
-- @param steps (int) relative amount to add 

function StepSequencer:_transpose_basenote(steps)
  TRACE("StepSequencer:_transpose_basenote(steps)",steps)
  local baseNote = (self._base_note-1)+(self._base_octave-1)*12
  local newval = baseNote + steps
  if (0 <= newval and newval < 120) then
    self:_set_basenote(newval)
  end
end


--------------------------------------------------------------------------------

--- detach all previously attached notifiers first
-- but don't even try to detach when a new song arrived. old observables
-- will no longer be alive then...
-- @param new_song (bool), true to leave existing notifiers alone
-- @param observables - list of observables
function StepSequencer:_remove_notifiers(new_song,observables)
  TRACE("StepSequencer:_remove_notifiers()",new_song,observables)

  if (not new_song) then
    for _,observable in pairs(observables) do
      pcall(function() observable:remove_notifier(self) end)
    end
  end
    
  observables:clear()

end


--------------------------------------------------------------------------------

--- apply a function to all held grid buttons, optionally adding them 
-- all to toggle_exempt table.  return the number of held keys
-- @param callback (function), the callback function
-- @param toggle_exempt (bool), do not toggle off

function StepSequencer:_walk_held_keys(callback, toggle_exempt)
  local newval = nil
  local note = nil
  
  -- count as we go through pairs. # keysDown doesn't seem to work all the time?
  local ct = 0 
  
  for x,row in pairs(self._keys_down) do
    for y,down in pairs(row) do
      if (down) then
        ct = ct + 1
        if (callback ~= nil) then
          callback(x,y)
        end
        if (toggle_exempt) then
          self._toggle_exempt[x][y] = true
        end
      end
    end
  end
  return ct
end


