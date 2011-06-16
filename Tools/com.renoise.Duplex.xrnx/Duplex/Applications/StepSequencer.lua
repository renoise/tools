--[[----------------------------------------------------------------------------
-- Duplex.StepSequencer
-- Inheritance: Application > StepSequencer
----------------------------------------------------------------------------]]--

--[[

About

  The StepSequencer allows you to use your (grid) controller as a basic step 
  sequencer. Each button in the grid corresponds to a line in a track. The grid 
  is scrollable too - use the line/track mappings to access any part of the 
  pattern you're editing. 

How to use:

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


Mappings

  grid          - the note grid 
  transpose     - 4 buttons, oct-/semi-/semi+/oct+
  level         - adjust note volume/display current line
  line          - flip through lines
  track         - flip through tracks


Options

  orientation   - display horizontally or vertically
  line_increment- the amount of lines to jump by when scrolling
  follow_track  - align with the selected track in Renoise
  page_size     - specify step size when using paged navigation


Changes (equal to Duplex version number)

  0.95  - The sequencer is now fully synchronized with the currently selected 
          pattern in  Renoise. You can copy, delete or move notes around, 
          and the StepSequencer will update it's display accordingly
        - Enabling Renoise's follow mode will cause instant catch-up
        - Display volume/base-note changes in the status bar
        - Orientation: use as sideways 16-step sequencer on monome128 etc.
        - Option: "increment by this amount" value for navigating lines
        - Improved performance 

  0.93  - Support other devices than the Launchpad (such as the monome)
        - Display playposition and volume simultaneously 

  0.92  - Original version by daxton.fleming@gmail.com


--]]


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

function StepSequencer:__init(display,mappings,options,config_name)
  TRACE("StepSequencer:__init(",display,mappings,options,config_name)

  self.COLUMNS_SINGLE = 1
  self.COLUMNS_MULTI = 2

  self.FOLLOW_TRACK_ON = 1
  self.FOLLOW_TRACK_OFF = 2

  self.TRACK_PAGE_AUTO = 1

  --self.ORIENTATION_VERTICAL = 1
  --self.ORIENTATION_HORIZONTAL = 2

  --self:_set_default_options(true)

  -- define the mappings (unassigned)
  self.mappings = {
    grid = {
      description = "Sequencer: press to toggle note on/off"
                  .."\nHold single button to copy note"
                  .."\nHold multiple buttons to adjust level/transpose"
                  .."\nControl value: ",
      ui_component = UI_COMPONENT_CUSTOM,
      orientation = VERTICAL,
      greedy = true,
    },
    level = {
      -- note: this control serves two purposes, as it will also display the 
      -- currently playing line - therefore, it needs to be the same size
      -- as the grid (rows if vertical, columns if horizontal)
      description = "Sequencer: Adjust note volume",
      ui_component = UI_COMPONENT_BUTTONSTRIP,
      orientation = VERTICAL,
    },
    line = { 
      description = "Sequencer: Flip up/down through lines",
      ui_component = UI_COMPONENT_SPINNER,
      orientation = HORIZONTAL,
    },
    track = {
      description = "Sequencer: Flip through tracks",
      ui_component = UI_COMPONENT_SPINNER,
      orientation = HORIZONTAL,
    },
    transpose = {
      description = "Sequencer: 4 buttons for transpose"
                  .."\n1st: Oct down"
                  .."\n2nd: Semi down"
                  .."\n3rd: Semi up"
                  .."\n4th: Oct up"
                  .."\nControl value: ",
      ui_component = UI_COMPONENT_CUSTOM,
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
      text="",
    },
    slot_muted = { -- volume 0 or note_cut
      color={0x40,0x00,0x00},
      text="□",
    },
    slot_level = { -- at different volume levels (automatically scales to #slot_level levels
      { color={0x00,0x40,0xff}, },
      { color={0x00,0x80,0xff}, },
      { color={0x00,0xc0,0xff}, },
      { color={0x00,0xff,0xff}, },
      { color={0x40,0xff,0xff}, },
      { color={0x80,0xff,0xff}, },
    },
    
    transpose = {
      { color={0xff,0x00,0xff}, }, -- down an octave
      { color={0xc0,0x40,0xff}, }, -- down a semi
      { color={0x40,0xc0,0xff}, }, -- up a semi
      { color={0x00,0xff,0xff}, }, -- up an octave
    },
    position = {
      color={0x00,0xff,0x00},
    },

  }

  -- default note/volume
  self._base_note = 1
  self._base_octave = 4
  self._base_volume = 100

  -- default note-grid size 
  self._track_count = 8
  self._line_count = 8

  -- the currently editing "page"
  self._edit_page = 0          

  -- the track offset (0-#tracks)
  self._track_offset = 0       
  self._track_page = nil

  -- true when song follow is enabled, 
  -- set to false when using the line navigator
  self._follow_player = nil    

  -- a "fire once" flag, which is set when
  -- switching from "not follow" to "follow"
  self._start_tracking = false 
                                
  -- remember the current pattern index here
  self._current_pattern = nil  
  
  self._update_lines_requested = false
  self._update_tracks_requested = false
  self._update_grid_requested = false

  -- the various controls
  self._buttons = {}
  self._level = nil
  self._line_navigator = nil
  self._track_navigator = nil
  self._transpose = nil

  -- track held grid keys
  self._keys_down = { } 
  
  -- don't toggle off if pressing multiple on / transposing / etc
  self._toggle_exempt = { } 

  Application.__init(self,display,mappings,options,config_name)

end


--------------------------------------------------------------------------------

function StepSequencer:start_app()
  TRACE("StepSequencer.start_app()")

  if not Application.start_app(self) then
    return
  end

  self._follow_player = renoise.song().transport.follow_player

  -- update everything!
  self:_update_line_count()
  self:_update_track_count()
  self:_update_grid()
  self:_follow_track()

end


--------------------------------------------------------------------------------

function StepSequencer:_build_app()
  TRACE("StepSequencer:_build_app()")

  -- determine grid size by looking at the control-map
  local cm_group = self.display.device.control_map.groups[
    self.mappings.grid.group_name]
  
  if (cm_group["columns"])then
    if(self:_get_orientation()==VERTICAL) then
      self._track_count = cm_group["columns"]
      self._line_count = math.ceil(#cm_group/self._track_count)
    else
      self._line_count = cm_group["columns"]
      self._track_count = math.ceil(#cm_group/self._line_count)
    end
  else
    -- not a grid controller? 
    local msg = "The StepSequencer can only be used with a grid controller"
    renoise.app():show_warning(msg)
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

function StepSequencer:_build_line()
  -- line (up/down scrolling)
  local c = UISpinner(self.display)
  c.group_name = self.mappings.line.group_name
  c.tooltip = self.mappings.line.description
  c:set_pos(self.mappings.line.index)
  c:set_orientation(self.mappings.line.orientation)
  c.text_orientation = VERTICAL
  c.step_size = 1
  c.on_change = function(obj) 

    if (not self.active) then 
      return false 
    end

    if(self._edit_page~=obj.index)then
      self._edit_page = obj.index
      self._follow_player = false
      self:_update_grid()
      return true
    end

    return false

  end
  self:_add_component(c)
  self._line_navigator = c
end


--------------------------------------------------------------------------------

function StepSequencer:_build_track()
  --  track (sideways scrolling)
  local c = UISpinner(self.display)
  c.group_name = self.mappings.track.group_name
  c.tooltip = self.mappings.track.description
  c:set_pos(self.mappings.track.index)
  c:set_orientation(self.mappings.track.orientation)
  c.text_orientation = HORIZONTAL
  c.on_change = function(obj) 

    if (not self.active) then 
      return false 
    end

    local page_width = self:_get_page_width()
    local track_idx = (obj.index*page_width)

    if (self.options.follow_track.value == self.FOLLOW_TRACK_ON) then
      -- if the follow_track option is specified, we set the
      -- track index and let the _follow_track() method handle it
      renoise.song().selected_track_index = 1+track_idx
    else
      self._track_offset = obj.index*self:_get_page_width()
      self:_update_grid()
    end

  end
  self:_add_component(c)
  self._track_navigator = c
end


--------------------------------------------------------------------------------

function StepSequencer:_build_grid()

  --self._buttons = {}

  local orientation = self:_get_orientation()

  for track_idx=1,self._track_count do
    for line_idx=1,self._line_count do

      local x,y = track_idx,line_idx

      if not (orientation==VERTICAL) then
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

      local c = UIStepSeqButton(self.display)
      c.group_name = self.mappings.grid.group_name
      c.tooltip = self.mappings.grid.description
      c.x_pos = x
      c.y_pos = y
      c.active = false

      -- grid toggling
      c.on_press = function(obj)

        if (not self.active) then 
          return false 
        end

        return self:_process_grid_event(x, y, true,obj)

      end
      c.on_release = function(obj)

        if (not self.active) then 
          return false 
        end

        return self:_process_grid_event(x, y, false,obj)

      end
      
      -- hold to "pick up" note, volume & instrument (ie copy step)
      c.on_hold = function(obj)

        if (not self.active) then 
          return false 
        end

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
        end
      end
      self:_add_component(c)
      self._buttons[x][y] = c
    end  
  end
end


--------------------------------------------------------------------------------

function StepSequencer:_build_level()

  -- figure out the number of rows in our level-slider group

  local cm = self.display.device.control_map

  -- level buttons
  local c = UIButtonStrip(self.display)
  c.group_name = self.mappings.level.group_name
  c.tooltip = self.mappings.level.description
  c.toggleable = false
  c.monochrome = is_monochrome(self.display.device.colorspace)
  c.mode = c.MODE_INDEX
  c.flipped = true
  c:set_orientation(self.mappings.level.orientation)
  c:set_size(self._line_count)
  c.on_index_change = function(obj) 
    
    if not self.active then 
      return false 
    end

    local idx = obj:get_index()
    local idx_flipped = obj._size-obj:get_index()+1
    local newval = (127/(obj._size-1)) * (idx_flipped-1)

    -- check for held grid notes
    local held = self:_walk_held_keys(
      function(track_idx,line_idx)
        if (self:_get_orientation()==HORIZONTAL) then
          track_idx,line_idx = line_idx,track_idx
        end
        local tracks = renoise.song().selected_pattern.tracks[track_idx + self._track_offset]
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
    
    -- draw buttons
    local p = { }
    if (newval == 0) then
      p = table.rcopy(self.palette.slot_muted)
    else 
      p = self:_volume_palette(newval, 127)
    end
    c.palette.range = p
    c:set_range(idx,obj._size)
    c:invalidate()
    
    return true
  end
  self:_add_component(c)
  self._level = c

end


--------------------------------------------------------------------------------

function StepSequencer:_build_transpose()
  self._transpose = { }
  local transposes = { -12, -1, 1, 12 }
  for k,v in ipairs(transposes) do
    
    local c = UIStepSeqButton(self.display)
    c.group_name = self.mappings.transpose.group_name
    c.tooltip = self.mappings.transpose.description
    c:set_pos(self.mappings.transpose.index+(k-1))
    c.active = false
    c.transpose = v
    
    c.on_press = function(obj)
      
      if not self.active then 
        return false
      end
      
      -- check for held grid notes
      local held = self:_walk_held_keys(
        function(x,y)
          if (self:_get_orientation()==HORIZONTAL) then
            x,y = y,x
          end
          local inc = self.options.line_increment.value
          local note = renoise.song().selected_pattern.tracks[x + self._track_offset]:line(
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
    
    self:_add_component(c)
    self._transpose[k] = c
    
  end
end


--------------------------------------------------------------------------------

-- periodic updates: handle "un-observable" things here
function StepSequencer:on_idle()

  if not self.active then 
    return 
  end
  
  -- did we change current_pattern?
  if (self._current_pattern ~= renoise.song().selected_pattern_index) then
    self._current_pattern = renoise.song().selected_pattern_index
    self._update_lines_requested = true
    -- attach notifier to pattern length
    renoise.song().patterns[self._current_pattern].number_of_lines_observable:add_notifier(
      function()
        TRACE("StepSequencer: pattern length changed")
        self._update_lines_requested = true
      end
    )
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
    self:_update_transpose()
  end
  
  if renoise.song().transport.playing then
    self:_update_position()
  else
    -- clear level?
    self:_draw_position(0)
  end

end

--------------------------------------------------------------------------------

-- update track navigator,
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

-- if the playback position is inside visible range of the sequencer, update
-- the position indicator
-- else, if follow mode is active, display the current page
-- (called on_idle when playing)

function StepSequencer:_update_position()
  --TRACE("StepSequencer:_update_position()")

  local pos = renoise.song().transport.playback_pos.line
  if self:_line_is_visible(pos) then
    local line_offset = self._edit_page*self.options.line_increment.value
    self:_draw_position(((pos-1-line_offset)%self._line_count)+1)
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

-- check if we should switch the active page/range inside the pattern
-- invoked only when follow mode is enabled

function StepSequencer:_update_page()

  local line = renoise.song().transport.playback_pos.line
  local page = math.ceil(line/self.options.line_increment.value)-1
  if (page~=self._edit_page) or
    (self._start_tracking) then
    self._edit_page = page
    self._line_navigator:set_index(page,true)
    self._update_grid_requested = true
  end

end


--------------------------------------------------------------------------------

-- called on_idle 

function StepSequencer:_draw_position(idx)

  if renoise.song().transport.playing then
    local ctrl_idx = self._level:get_index()
    if (ctrl_idx~=idx) then
      self._level:set_index(idx,true)
  TRACE("StepSequencer:_draw_position(",idx,")")
    end
  end

end


--------------------------------------------------------------------------------

-- update the range of the line navigator

function StepSequencer:_update_line_count()
  TRACE("StepSequencer:_update_line_count()")

  if not self.active then 
    return 
  end

  local pattern = nil
  if (self._follow_player) then
    pattern = get_playing_pattern()
  else
    pattern = renoise.song().selected_pattern
  end
  local inc = self.options.line_increment.value
  local rng = math.ceil(math.floor(pattern.number_of_lines)/inc)-1

  self._line_navigator:set_range(0,rng)

end


--------------------------------------------------------------------------------

function StepSequencer:_update_grid()
  TRACE("StepSequencer:_update_grid()")

  if not self.active then 
    return 
  end

  local orientation = self:_get_orientation()

  -- loop through grid & buttons
  local line_offset = self._edit_page*self.options.line_increment.value
  local master_idx = get_master_track_index()
  local track_count = #renoise.song().tracks
  local selected_pattern_tracks = renoise.song().selected_pattern.tracks
  local selected_pattern_lines = renoise.song().selected_pattern.number_of_lines
  for track_idx = (1 + self._track_offset),(self._track_count+self._track_offset) do
    local pattern_track = selected_pattern_tracks[track_idx]
    for line_idx = (1 + line_offset),(self._line_count + line_offset) do

      local button = nil
      if(orientation==VERTICAL) then
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
        self:_draw_grid_button(button, note)
      end

    end
  end
end


--------------------------------------------------------------------------------

function StepSequencer:_update_transpose()

  if not self.active then 
    return
  end

  local palette = { }
  for k,btn in ipairs(self._transpose) do
    palette.foreground = table.rcopy(self.palette.transpose[k])
    btn:set_palette(palette)
  end
  
end

--------------------------------------------------------------------------------

-- decide if we need to update the display when the pattern editor has changed 
-- note: this method might be called hundreds of times when doing edits like
-- cutting all notes from a pattern, so we need it to be really simple

function StepSequencer:_track_changes(pos)

  if (self:_track_is_visible(pos.track)) and
    (self:_line_is_visible(pos.line)) then
    TRACE("StepSequencer:_track_changes - update_grid_requested")
    self._update_grid_requested = true
  end

end

--------------------------------------------------------------------------------

-- check if a given line is within the visible range

function StepSequencer:_line_is_visible(line_pos)
  
  local line_offset = self._edit_page*self.options.line_increment.value
  return (line_offset < line_pos) and
    (line_pos <= (line_offset+self._line_count))

end

--------------------------------------------------------------------------------

-- check if a given track is within the visible range

function StepSequencer:_track_is_visible(track_idx)

  return (track_idx>(self._track_offset)) and
    (track_idx<=(self._track_offset+self._track_count))

end

--------------------------------------------------------------------------------

-- when following the active track in Renoise, we call this method
-- (track following is limited to sequencer tracks)

function StepSequencer:_follow_track()
  TRACE("StepSequencer:_follow_track()")

  if (self.options.follow_track.value == self.FOLLOW_TRACK_OFF) then
    return
  end

  local song = renoise.song()
  local master_idx = get_master_track_index()
  local track_idx = math.min(song.selected_track_index,master_idx-1)
  local page = self:_get_track_page(track_idx)
  local page_width = self:_get_page_width()
  if (page~=self._track_page) then
    self._track_page = page
    self._track_offset = page*page_width
    self:_update_grid()
    if self._track_navigator then
      self._track_navigator:set_index(page,true)
    end
  end

end

--------------------------------------------------------------------------------

-- figure out the active "track page" based on the supplied track index
-- @param track_idx, renoise track number
-- return integer (0-number of pages)

function StepSequencer:_get_track_page(track_idx)

  local page_width = self:_get_page_width()
  local page = math.floor((track_idx-1)/page_width)
  return page

end

--------------------------------------------------------------------------------

function StepSequencer:_get_page_width()

  return (self.options.page_size.value==self.TRACK_PAGE_AUTO)
    and self._track_count or self.options.page_size.value-1

end


--------------------------------------------------------------------------------

function StepSequencer:_get_orientation()
  TRACE("StepSequencer:_get_orientation()")
  
  return self.mappings.grid.orientation

end
--------------------------------------------------------------------------------

function StepSequencer:_attach_to_song()
  TRACE("StepSequencer:_attach_to_song()")
  
  local song = renoise.song()

  -- song notifiers
  song.tracks_observable:add_notifier(
    function()
      TRACE("StepSequencer:tracks_observable fired...")
      -- do this right away (updating the spinner is easily done, and we
      -- avoid that setting the index will fail, because idle() has yet to 
      -- increase the number of track pages...)
      self:_update_track_count()
      self._update_tracks_requested = true
    end
  )
  song.patterns_observable:add_notifier(
    function()
      TRACE("StepSequencer:patterns_observable fired...")
      self._update_lines_requested = true
    end
  )
  song.transport.follow_player_observable:add_notifier(
    function()
      TRACE("StepSequencer:follow_player_observable fired...")
      -- if switching on, start tracking actively
      local follow = renoise.song().transport.follow_player
      if not (follow==self._follow_player) then
        self._start_tracking = follow
      end
      self._follow_player = follow
      if(self._follow_player)then   
        self:_update_page()
      end
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

  -- follow active track in Renoise
  song.selected_track_index_observable:add_notifier(
    function()
      TRACE("StepSequencer:selected_track_observable fired...")
      self:_follow_track()
    end
  )


end

--------------------------------------------------------------------------------

-- attach line notifier (check for existing notifier first)

function StepSequencer:_attach_line_notifier()

  local song = renoise.song()
  local patt = song.patterns[song.selected_pattern_index]
  if not (patt:has_line_notifier(self._track_changes,self))then
    patt:add_line_notifier(self._track_changes,self)
  end

end


--------------------------------------------------------------------------------

-- called when a new document becomes available

function StepSequencer:on_new_document()
  TRACE("StepSequencer:on_new_document()")

  self:_attach_to_song()
  self:_update_line_count()
  self:_update_track_count()
  self:_update_grid()
  self:_follow_track()

end


--------------------------------------------------------------------------------
-- STEP SEQUENCER FUNCTIONS
--------------------------------------------------------------------------------

function StepSequencer:_process_grid_event(x,y, state, btn)
  TRACE("StepSequencer:_process_grid_event()",x,y, state, btn)

  local track_idx,line_idx = x,y

  if not (self:_get_orientation()==VERTICAL) then
    line_idx,track_idx = track_idx,line_idx
  end

  track_idx = track_idx+self._track_offset
  line_idx = line_idx+self._edit_page*self.options.line_increment.value

  if (track_idx >= get_master_track_index()) then 
    return false 
  end
  
  local note = renoise.song().selected_pattern.tracks[track_idx]:line(
    line_idx).note_columns[1]
  
  if (state) then -- press
    self._keys_down[x][y] = true
    if (note.note_string == "OFF" or note.note_string == "---") then
      local base_note = (self._base_note-1) + 
        (self._base_octave-1)*12
      self:_set_note(note, base_note, renoise.song().selected_instrument_index-1, 
        self._base_volume)
      self._toggle_exempt[x][y] = true
      -- and update the button ...
      self:_draw_grid_button(btn, note)
    end
      
  else -- release
    self._keys_down[x][y] = nil
    -- don't toggle off if we just turned on
    if (not self._toggle_exempt[x][y]) then 
      self:_clear_note(note)
      -- and update the button ...
      if (renoise.song().selected_pattern.number_of_lines<line_idx) then
        -- reset to "out of bounds" color
        note = nil
      end
      self:_draw_grid_button(btn, note)
    else
      self._toggle_exempt[x][y] = nil
    end
  end
  return true
end


--------------------------------------------------------------------------------

function StepSequencer:_copy_grid_button(lx,ly, btn)
  TRACE("StepSequencer:_copy_grid_button()",lx,ly, btn)

  local gx = lx+self._track_offset
  local gy = ly+self._edit_page*self._line_count

  if not (self:_get_orientation()==VERTICAL) then
    gx,gy = gy,gx
  end

  if (gx >= get_master_track_index()) then 
    return false 
  end

  local note = renoise.song().selected_pattern.tracks[gx]:line(gy).note_columns[1]
  
  -- copy note to base note
  if (note.note_value < 120) then
    self:_set_basenote(note.note_value)
  end
  -- copy volume to base volume
  if (note.volume_value <= 127) then
    self._base_volume = note.volume_value
  end
  -- change selected instrument
  if (note.instrument_value < #renoise.song().instruments) then
    renoise.song().selected_instrument_index = note.instrument_value+1
  end
  
  return true
end


--------------------------------------------------------------------------------

function StepSequencer:_set_note(note_obj, note, instrument, volume)
  note_obj.note_value = note
  note_obj.instrument_value = instrument
  note_obj.volume_value = volume
end


--------------------------------------------------------------------------------

function StepSequencer:_clear_note(note_obj)
  self:_set_note(note_obj, 121, 255, 255)
end


--------------------------------------------------------------------------------

-- assign color to button, based on note properties

function StepSequencer:_draw_grid_button(button, note)
  --TRACE("StepSequencer:_draw_grid_button()",button, note)

  local palette = {}
  
  if (note ~= nil) then
    if (note.note_value == 121) then
      -- empty
      palette.foreground = table.rcopy(self.palette.slot_empty)
    elseif (note.note_value == 120 or note.volume_value == 0) then
      -- turned off 
      palette.foreground = table.rcopy(self.palette.slot_muted)
    else
      -- some volume
      palette.foreground = self:_volume_palette(note.volume_value, 127)
    end
  
  else
    -- out of bounds
    palette.foreground = table.rcopy(self.palette.out_of_bounds)
  end

  button:set_palette(palette)
end


--------------------------------------------------------------------------------

function StepSequencer:_volume_palette(vol, max)
  if (vol > max) then vol = max end
  local vol_level = 1+ math.floor(vol / max * (#self.palette.slot_level-1))
  return table.rcopy(self.palette.slot_level[vol_level])
end


--------------------------------------------------------------------------------

function StepSequencer:_set_basenote(note_value)
  local note = note_value % 12 +1
  local oct = math.floor(note_value / 12) +1
  self._base_note = note
  self._base_octave = oct
  local msg = string.format(
    "StepSequencer: Basenote changed to %s%i",NOTE_ARRAY[note],oct)

  renoise.app():show_status(msg)

end


--------------------------------------------------------------------------------

function StepSequencer:_transpose_basenote(steps)
  local baseNote = (self._base_note-1)+(self._base_octave-1)*12
  local newval = baseNote + steps
  if (0 <= newval and newval < 120) then
    self:_set_basenote(newval)
  end
end


--------------------------------------------------------------------------------

-- apply a function to all held grid buttons, optionally adding them 
-- all to toggle_exempt table.  return the number of held keys

function StepSequencer:_walk_held_keys(callback, toggleExempt)
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
        if (toggleExempt) then
          self._toggle_exempt[x][y] = true
        end
      end
    end
  end
  return ct
end


--[[----------------------------------------------------------------------------
-- Duplex.UIStepSeqButton
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UIStepSeqButton

About

UIStepSeqButton is a simple button with press & release handlers, 
with limited support for input methods - see UIToggleButton for a more 
general-purpose type of button.

Supported input methods

- button
- pushbutton
- togglebutton*

* release/hold events are not supported for this type 


Events

  on_press()
  on_release()
  on_hold()


--]]


--==============================================================================

class 'UIStepSeqButton' (UIComponent)

function UIStepSeqButton:__init(display)
  TRACE('UIStepSeqButton:__init')

  UIComponent.__init(self,display)

  self.palette = {
    foreground = table.rcopy(display.palette.color_1),
  }

  self.add_listeners(self)
  
  -- external event handlers
  self.on_press = nil
  self.on_release = nil
  self.on_hold = nil

end


--------------------------------------------------------------------------------

-- user input via button

function UIStepSeqButton:do_press()
  TRACE("UIStepSeqButton:do_press()")

  if (self.on_press ~= nil) then
    local msg = self:get_msg()
    if not (self.group_name == msg.group_name) then
      return 
    end
    if not self:test(msg.column,msg.row) then
      return 
    end
    self:on_press()
  end

end

-- ... and release

function UIStepSeqButton:do_release()
  TRACE("UIStepSeqButton:do_release()")

  if (self.on_release ~= nil) then
    local msg = self:get_msg()
    if not (self.group_name == msg.group_name) then
      return 
    end
    if not self:test(msg.column,msg.row) then
      return 
    end
    self:on_release()
  end

end


--------------------------------------------------------------------------------

-- user input via (held) button
-- on_hold() is the optional handler method

function UIStepSeqButton:do_hold()
  TRACE("UIStepSeqButton:do_hold()")

  if (self.on_hold ~= nil) then
    local msg = self:get_msg()
    if not (self.group_name == msg.group_name) then
      return 
    end
    if not self:test(msg.column,msg.row) then
      return 
    end
    self:on_hold()
  end

end


--------------------------------------------------------------------------------

function UIStepSeqButton:draw()
  TRACE("UIStepSeqButton:draw")

  local color = self.palette.foreground
  local point = CanvasPoint()
  point:apply(color)
  -- if the color is completely dark, this is also how
  -- LED buttons will represent the value (turned off)
  if(get_color_average(color.color)>0x00)then
    point.val = true        
  else
    point.val = false        
  end
  self.canvas:fill(point)
  UIComponent.draw(self)

end


--------------------------------------------------------------------------------

function UIStepSeqButton:add_listeners()

  self._display.device.message_stream:add_listener(
    self, DEVICE_EVENT_BUTTON_PRESSED,
    function() self:do_press() end )

  self._display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_HELD,
    function() self:do_hold() end )

  self._display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_RELEASED,
    function() self:do_release() end )

end


--------------------------------------------------------------------------------

function UIStepSeqButton:remove_listeners()

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED)

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_HELD)
    
  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_RELEASED)

end

