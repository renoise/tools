--[[===============================================================================================
-- Duplex.Application.StepSequencer
===============================================================================================]]--

--[[--

A step sequencer for grid/pad-based controllers

#

[View the README.md](https://github.com/renoise/xrnx/blob/master/Tools/com.renoise.Duplex.xrnx/Docs/Applications/StepSequencer.md) (github)

--]]

--=================================================================================================

-- constants

local COLUMNS_SINGLE = 1
local COLUMNS_MULTI = 2
local FOLLOW_TRACK_ON = 1
local FOLLOW_TRACK_SET = 2
local FOLLOW_TRACK_OFF = 3
local FOLLOW_COLUMN_ON = 1
local FOLLOW_COLUMN_OFF = 2
local LINE_INCREMENT_AUTO = 1
local TRACK_PAGE_AUTO = 1
local FOLLOW_LINE_ON = 1
local FOLLOW_LINE_SET = 2
local FOLLOW_LINE_OFF = 3
local GRID_MODE_SINGLE = 2
local GRID_MODE_MULTIPLE = 1
local GRID_MODE_MULTIPLE_COLS = 3
local WRITE_MODE_RECORD_OFF = 1
local WRITE_MODE_RECORD_ON = 2
local PLAY_NOTES_ON = 2
local PLAY_NOTES_OFF = 1
local DISPLAY_NOTES_ON = 2
local DISPLAY_NOTES_OFF = 1

--=================================================================================================

class 'StepSequencer' (Application)

StepSequencer.default_options = {
  line_increment = {
    label = "Line increment",
    description = "Choose the number of lines to jump for each step "
                .."\nwhen flipping through pattern",
    on_change = function(inst)
      inst:_update_line_count()
      inst:_update_line_buttons()
    end,
    items = {
      "Automatic: use available width",      
      "1","2","3","4",
      "5","6","7","8",
      "9","10","11","12",
      "13","14","15","16"
    },
    value = 8,
  },
  follow_track = {
    label = "Follow track",
    description = "Enable this if you want to align the sequencer to " 
                .."\nthe selected track in pattern",
    on_change = function(inst)
      inst:_follow_track()
    end,
    items = {
      "Follow",
      "Follow + Set",      
      "Don't follow"
    },
    value = FOLLOW_TRACK_SET,
  },
  follow_column = {
    label = "Follow column",
    description = "Enable this if you want to align the sequencer to " 
                .."\nthe currently selected column in pattern",
    on_change = function(inst)
      inst:_update_selected_column()
    end,
    items = {
      "Follow",
      "Don't follow'"
    },
    value = FOLLOW_COLUMN_OFF,
  },
  follow_line = {
    label = "Follow line",
    description = "Enable this if you want to align the sequencer with " 
                .."\nthe selected line in pattern",
    on_change = function(inst)
      inst:_follow_track()
    end,
    items = {
      "Follow",
      "Follow + Set",
      "Don't follow'"
    },
    value = FOLLOW_LINE_SET,
  },
  grid_mode = {
    label = "Grid Mode",
    description = "Choose if you want to edit multiple tracks" 
                .."\nwith the grid or only one track.",
    on_change = function(inst)
      inst:_build_app()
      inst:_update_line_count()
      inst:_update_line_buttons()
      inst:_update_grid_mode()
      inst._update_grid_requested = true
      renoise.app():show_status("Grid mode changed.")
    end,
    items = {
      "Multiple tracks",
      "Single track/column"
    },
    value = GRID_MODE_MULTIPLE,
  },
  write_mode = {
    label = "Write Mode",
    description = "Choose if you want to write notes to the pattern" 
                .."\ndependent from Renoise's edit mode.",
    --on_change = function(inst)
    --end,
    items = {
      "All time",
      "Only in record mode"
    },
    value = WRITE_MODE_RECORD_ON,
  },
  play_notes = {
    label = "Play notes",
    description = "Choose if you want to play the instrument / note" 
                .."\non pushing a trigger pad or grid button."
                .."\nIf 'Write mode' is set to 'Only in edit mode' "
                .."\nnotes will be played only if edit mode is off.",
    --on_change = function(inst)
    --end,
    items = {
      "No",
      "Yes"
    },
    value = PLAY_NOTES_ON,
  },  
  display_notes = {
    label = "Display notes",
    description = "Choose if you want to display the note values" 
                .."\onto the grid buttons in Duplex",
    on_change = function(inst)
      inst._update_grid_requested = true
    end,
    items = {
      "No",
      "Yes"
    },
    value = DISPLAY_NOTES_ON,
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
  volume_steps = {
    label = "Volume steps",
    description = "Specify the step size of the"
                .."\nvolume-steps button",
    on_change = function(inst)
      inst:_update_track_count()
    end,
    items = {
      "3","4","6","8","12","16","24","32"
    },
    value = 3,
  },
}

StepSequencer.available_mappings = {
  grid = {
    description = "Sequencer: press to toggle note on/off"
                .."\nHold single button to copy note"
                .."\nHold multiple buttons to adjust level/transpose"
                .."\nControl value: ",
    orientation = ORIENTATION.VERTICAL,
    button_size = 1
  },
  level = {
    description = "Sequencer: Adjust note volume",
    orientation = ORIENTATION.VERTICAL,
  },
  levelslider = {
    description = "Sequencer: Adjust note volume",
  },
  levelsteps = {
    component = UIButton,
    description = "Sequencer: Increase the note volume step wise",
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
    component = UISpinner,
    description = "Sequencer: Flip through tracks/columns",
    orientation = ORIENTATION.HORIZONTAL,
  },
  transpose = {
    component = {UIButton,UIButton,UIButton,UIButton},
    description = "Sequencer: 4 buttons for transpose"
                .."\n1st: Oct down"
                .."\n2nd: Semi down"
                .."\n3rd: Semi up"
                .."\n4th: Oct up"
                .."\nControl value: ",
  },
  cycle_layout = {
    component = UIButton,
    description = "Sequencer: Cycle through available grid layouts",
  },
  
}

StepSequencer.default_palette = {
  out_of_bounds     = { color={0x40,0x40,0x00}, text="·", val=false},
  slot_empty        = { color={0x00,0x00,0x00}, text="·", val=false},
  slot_current      = { color={0x00,0x00,0x00}, text="·", val=false },
  slot_highlight    = { color={0xFF,0xFF,0xFF}, text="·", val=false },
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
  grid_mode_single  = { color={0x80,0x40,0xff}, text="☷", val=true},
  grid_mode_multiple= { color={0x40,0x80,0xff}, text="☰", val=true},
}

---------------------------------------------------------------------------------------------------
-- Constructor method
-- @param (VarArg)
-- @see Duplex.Application

function StepSequencer:__init(...)
  TRACE("StepSequencer:__init(",...)

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

  --- the track offset (0-#sequencer-tracks)
  self._track_offset = 0       
  self._track_page = nil

  --- boolean, true when song follow is enabled 
  self._follow_player = nil    

  --- boolean, track when playing state changes
  self._playing_line_index = nil

  --- boolean, set when switching from "not follow" to "follow"
  self._start_tracking = false 
                                
  --- remember the current pattern index here
  self._current_pattern_index = nil  
  
  --- remember the current line index
  self._current_edit_line_index = nil  

  --- remember the current column in track
  self._current_column_index = 1  
  
  self._update_lines_requested = false
  self._update_tracks_requested = false
  self._update_grid_requested = false

  --- collect patterns indices with line_notifiers 
  self._line_notifiers = table.create()

  --- collect references to pattern-alias notifier methods
  self._alias_notifiers = table.create()
  
  --- collect references to song notifier methods
  self._song_notifiers = table.create()
  
  --- number_of_lines_observable
  self._number_of_lines_observable = nil

  -- true when current track should be highlighted
  -- (actual value is derived from the palette)
  self._highlight_track = false

  -- the various controls
  self._buttons = {} -- {{UIButton}}
  self._levelstrip = nil -- UIButtonStrip
  self._levelsteps = nil -- UIButton
  self._levelslider = nil -- UISlider
  self._line_navigator = nil -- UISlider
  self._prev_line = nil -- UIButton
  self._next_line = nil -- UIButton
  self._track_navigator = nil -- UISlider
  self._transpose = nil -- {UIButton,UIButton,UIButton,UIButton}
  self._cycle_layout = nil -- UIButton

  -- highlighted matrix button (index)
  self._highlighted_button_index = nil

  --- track held grid keys
  self._keys_down = { } 
  self._volume_steps = {3,4,6,8,12,16,24,32} 

  --- don't toggle off if pressing multiple on / transposing / etc
  self._toggle_exempt = { } 

  Application.__init(self,...)
  --self:list_mappings_and_options(StepSequencer)

end

---------------------------------------------------------------------------------------------------
-- Inherited from Application
-- @see Duplex.Application.start_app
-- @return bool or nil

function StepSequencer:start_app()
  TRACE("StepSequencer.start_app()")

  if not Application.start_app(self) then
    return
  end

  self.voice_mgr = self._process.browser._voice_mgr
  assert(self.voice_mgr,"Internal Error. Please report: " ..
    "expected OSC voice-manager to be present")

  self._follow_player = rns.transport.follow_player

  -- determine if we should highlight the current track
  if not cLib.table_compare(self.palette.slot_empty.color,self.palette.slot_current.color)
    or (self.palette.slot_empty.text ~= self.palette.slot_current.text)
    or (self.palette.slot_empty.val ~= self.palette.slot_current.val)
  then
    self._highlight_track = true
  end

  self:_update_all()

  -- bind observables
  self:_attach_to_song()

end

---------------------------------------------------------------------------------------------------
-- Inherited from Application
-- @see Duplex.Application.stop_app

function StepSequencer:stop_app()
  TRACE("StepSequencer:stop_app()")

  self:_remove_notifiers(self._song_notifiers)
  self:_remove_notifiers(self._alias_notifiers)
  self:_remove_line_notifiers()
  self:_remove_pattern_lines_notifier()

  Application.stop_app(self)

end

---------------------------------------------------------------------------------------------------
-- Inherited from Application
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
  if (cm_group["columns"]) then
    if (self:_get_orientation()==ORIENTATION.VERTICAL) then
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
  self:_build_levelslider()
  self:_build_levelsteps()
  self:_build_transpose()
  self:_build_layout_cycler()

  self:_update_selected_column()

  Application._build_app(self)

  return true

end


---------------------------------------------------------------------------------------------------
-- Line (up/down scrolling)

function StepSequencer:_build_line()
  TRACE("StepSequencer:_build_line()")

  local map = self.mappings.line
  if map.group_name then
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

---------------------------------------------------------------------------------------------------
-- Track or column (sideways scrolling)

function StepSequencer:_build_track()
  TRACE("StepSequencer:_build_track()")

  if self.mappings.track.group_name then

    local c = UISpinner(self)
    c.group_name = self.mappings.track.group_name
    c.tooltip = self.mappings.track.description
    c:set_pos(self.mappings.track.index)
    c:set_orientation(self.mappings.track.orientation)
    c.on_press = function()
      -- (this handler is required for on_change to work)
    end
    c.on_change = function(obj) 
      if (self.options.follow_track.value == FOLLOW_TRACK_SET) then
        -- set the selected track index and let notifiers handle it
        local page_width = self:_get_track_page_width()
        local seq_track_idx = 1+(obj.index*page_width)        
        local rns_track_idx = StepSequencer._get_actual_track_index(seq_track_idx)
        --print(">>> page_width,seq_track_idx,rns_track_idx",page_width,seq_track_idx,rns_track_idx)
        if (rns.tracks[rns_track_idx]) then
          rns.selected_track_index = rns_track_idx
        end
      else
        -- update the controller 
        self._track_offset = obj.index*self:_get_track_page_width()
        self._update_grid_requested = true 
      end

    end
    self._track_navigator = c
  end

end

---------------------------------------------------------------------------------------------------
-- Construct user interface

function StepSequencer:_build_grid()
  TRACE("StepSequencer:_build_grid()")

  local orientation = self:_get_orientation()

  for track_idx=1,self._track_count do

    local button_idx_base = ( track_idx-1) * self._line_count 

    for line_idx=1,self._line_count do
      
      local x,y = track_idx,line_idx

      -- button_idx generates the index of all grid buttons independent from grid layout
      local button_idx = button_idx_base + line_idx

      -- x,y repesenting the grid layout independent from the grid mode setting
      local x_p,y_p = x,y

      -- _gms = grid mode single, tmm = grid mode multi
      -- workaround to get grid mode specific x/y values 
      -- into the button event functions (x.on_press etc.).
      -- once the grid is build, it was impossible to overwrite 
      -- change this values in this functions.
      local x_gmm,y_gmm = x,y
      local x_gms,y_gms = 1,button_idx

      if (self.options.grid_mode.value == GRID_MODE_SINGLE) then 
        x,y = x_gms,y_gms
      end

      if not (orientation == ORIENTATION.VERTICAL) then
        x,y = y,x
        x_p,y_p = y_p,x_p
        x_gms,y_gms = y_gms,x_gms
        x_gmm,y_gmm = y_gmm,x_gmm
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
      c.x_pos = x_p
      c.y_pos = y_p

      -- grid toggling
      c.on_press = function(obj)

        if (self.options.grid_mode.value == GRID_MODE_SINGLE) then 
          self:_process_grid_event(x_gms, y_gms, true,obj)
        elseif ( self.options.grid_mode.value == GRID_MODE_MULTIPLE ) then 
          self:_process_grid_event(x_gmm, y_gmm, true,obj)
        elseif ( self.options.grid_mode.value == GRID_MODE_MULTIPLE_COLS ) then 
          error("TODO")
        else
          error("Unexpected GRID_MODE")
        end
      end
      c.on_release = function(obj)
        if (self.options.grid_mode.value == GRID_MODE_SINGLE) then 
          self:_process_grid_event(x_gms, y_gms, false,obj)
        elseif ( self.options.grid_mode.value == GRID_MODE_MULTIPLE ) then 
          self:_process_grid_event(x_gmm, y_gmm, false,obj)
        elseif ( self.options.grid_mode.value == GRID_MODE_MULTIPLE_COLS ) then 
          error("TODO")
        else
          error("Unexpected GRID_MODE")
        end
      end
      
      -- hold to "pick up" note, volume & instrument (ie copy step)
      c.on_hold = function(obj)

        -- check if we're holding multiple keys
        local held = self:_walk_held_keys(nil, false)
        --if (held == 1 and self:_write_note()) then
        if (held == 1) then
          if (self.options.grid_mode.value == GRID_MODE_SINGLE) then    
            self._toggle_exempt[x_gms][y_gms] = true
            self:_copy_grid_button(x_gms,y_gms,obj)
          elseif ( self.options.grid_mode.value == GRID_MODE_MULTIPLE ) then    
            self._toggle_exempt[x_gmm][y_gmm] = true
            self:_copy_grid_button(x_gmm,y_gmm,obj)
          elseif ( self.options.grid_mode.value == GRID_MODE_MULTIPLE_COLS ) then    
            error("TODO")
          else
            error("Unexpected GRID_MODE")
          end

          local msg = "StepSequencer: note was copied"
          renoise.app():show_status(msg)

          -- make it blink off (visual feedback)
          local palette = {}
          palette.foreground = table.rcopy(self.palette.slot_empty)
          obj:set_palette(palette)
          self._update_grid_requested = true

        end

      end
      self._buttons[x][y] = c
    end  
  end
end

---------------------------------------------------------------------------------------------------
-- Construct user interface

function StepSequencer:_build_level()
  TRACE("StepSequencer:_build_level()")

  if self.mappings.level.group_name then

    -- figure out the number of rows in our level-slider group
    local cm_group = self.display.device.control_map.groups[
      self.mappings.level.group_name]

    -- level buttons
    local c = UIButtonStrip(self)
    c.group_name = self.mappings.level.group_name
    c.tooltip = self.mappings.level.description
    c.toggleable = false
    c.monochrome = is_monochrome(self.display.device.colorspace)
    c.mode = c.MODE_INDEX
    c.flipped = true
    c:set_orientation(self.mappings.level.orientation)
    c:set_size(#cm_group)
    c.on_index_change = function(obj) 

      local idx = obj:get_index()
      local idx_flipped = obj._size-obj:get_index()+1
      local newval = (127/(obj._size-1)) * (idx_flipped-1)

      -- check for held grid notes
      local held = self:_walk_held_keys(
        function(x,y)
          if (self:_get_orientation()==ORIENTATION.HORIZONTAL) then
            x,y = y,x
          end
          local notecol = self:get_notecolumn(x,y)
          if notecol then 
            notecol.volume_value = newval
          end
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
      self:_draw_volume_steps(newval)
      self:_draw_level_slider(newval)
      return true
    end
    self._levelstrip = c    
    self:_draw_volume_slider()
  end

end

---------------------------------------------------------------------------------------------------
-- Construct user interface

function StepSequencer:_build_levelslider()
  TRACE("StepSequencer:_build_levelslider()")

  if self.mappings.levelslider.group_name then

    local cm = self.display.device.control_map

    -- locate the control-map "maximum" attribute,
    -- and make the slider use this range as "ceiling"
    local param = cm:get_param_by_index(self.mappings.levelslider.index,self.mappings.levelslider.group_name)
    local args = param.xarg

    local c = UISlider(self)
    c.group_name = self.mappings.levelslider.group_name
    c.tooltip = self.mappings.levelslider.description

    c:set_pos(self.mappings.levelslider.index)
    c:set_value(self._base_volume)
    c.ceiling = args.maximum
    c.on_change = function(obj)
      local newval = math.ceil(obj.value)
      -- check for held grid notes

      local held = self:_walk_held_keys(
        function(x,y)
          if (self:_get_orientation()==ORIENTATION.HORIZONTAL) then
            x,y = y,x
          end
          local notecol = self:get_notecolumn(x,y)
          if notecol then 
            notecol.volume_value = newval
          end
        end,
        true
      )
      if (held == 0) then 
        self._base_volume = newval
        local msg = string.format("StepSequencer: Volume changed to %X",self._base_volume)
        renoise.app():show_status(msg)
      end
      self._update_grid_requested = true
      self:_draw_volume_slider(newval)
      self:_draw_volume_steps(newval)
      self:_draw_level_slider(newval)
      return true
    end
    self._levelslider = c
  end

end


---------------------------------------------------------------------------------------------------
-- Construct user interface

function StepSequencer:_build_levelsteps()
  TRACE("StepSequencer:_build_levelsteps()")

  if self.mappings.levelsteps.group_name then

    local cm = self.display.device.control_map

      -- locate the control-map "maximum" attribute,
      -- and make the slider use this range as "ceiling"
      local param = cm:get_param_by_index(self.mappings.levelsteps.index,self.mappings.levelsteps.group_name)
      local args = param.xarg

      local c = UIButton(self)
      c.group_name = self.mappings.levelsteps.group_name
      c.tooltip = self.mappings.levelsteps.description
      c:set_pos(self.mappings.levelsteps.index)
      c.monochrome = is_monochrome(self.display.device.colorspace)
      c.on_press = function(obj)
        local newval = self._base_volume + math.ceil (args.maximum/self._volume_steps[self.options.volume_steps.value])
        if ( newval > args.maximum and 
             args.maximum - self._base_volume < args.maximum/self._volume_steps[self.options.volume_steps.value] and
             args.maximum - self._base_volume ~= 0 ) then
          newval = args.maximum
        elseif ( newval >= args.maximum) then
          newval = 0
        end

        -- check for held grid notes
        local held = self:_walk_held_keys(
          function(x,y)
            if (self:_get_orientation()==ORIENTATION.HORIZONTAL) then
              x,y = y,x
            end
            local notecol = self:get_notecolumn(x,y)
            if notecol then 
              notecol.volume_value = newval
            end
          end,
          true
        )
         if (held == 0) then 
          self._base_volume = newval
          local msg = string.format("StepSequencer: Volume changed to %X",self._base_volume)
          renoise.app():show_status(msg)
        end
        self._update_grid_requested = true
        self:_draw_volume_slider(newval)        
        self:_draw_volume_steps(newval)
        self:_draw_level_slider(newval)
        return true
      end

      c.on_hold = function(obj)

        local newval = 100
        -- check for held grid notes
        local held = self:_walk_held_keys(
          function(x,y)
            if (self:_get_orientation()==ORIENTATION.HORIZONTAL) then
              x,y = y,x
            end
            local notecol = self:get_notecolumn(x,y)
            if notecol then 
              notecol.volume_value = newval
            end
          end,
          true
        )
        if (held == 0) then 
          self._base_volume = newval
          local msg = string.format("StepSequencer: Volume changed to %X",self._base_volume)
          renoise.app():show_status(msg)
        end
        self._update_grid_requested = true
        self:_draw_volume_slider(newval)
        self:_draw_volume_steps(newval)
        self:_draw_level_slider(newval)
        return true

      end
      self._levelsteps = c

      self:_draw_volume_steps()
  end

end


---------------------------------------------------------------------------------------------------
-- Build transpose buttons 

function StepSequencer:_build_transpose()
  TRACE("StepSequencer:_build_transpose()")

  if self.mappings.transpose.group_name then

    self._transpose = { }
    local transposes = { -12, -1, 1, 12 }
    for k,transpose in ipairs(transposes) do
      
      local c = UIButton(self)
      c.group_name = self.mappings.transpose.group_name
      c.tooltip = self.mappings.transpose.description
      c:set_pos(self.mappings.transpose.index+(k-1))
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
            local notecol = self:get_notecolumn(x,y)
            if notecol then 
              local newval = notecol.note_value + transpose
              if (newval > 0 and newval < 120) then 
                notecol.note_value = newval
              end
            end
          end,
          true
        )
        if (held == 0) then -- no keys down, change basenote instead of transpose
          self:_transpose_basenote(transpose)
        end
      end
      
      self._transpose[k] = c
      
    end

  end

end


---------------------------------------------------------------------------------------------------
-- Build layout cycler 

function StepSequencer:_build_layout_cycler()
  print("StepSequencer:_build_layout_cycler()")

  if self.mappings.cycle_layout.group_name then 
    local c = UIButton(self)
    c.group_name = self.mappings.cycle_layout.group_name
    c.tooltip = self.mappings.cycle_layout.description
    c:set_pos(self.mappings.cycle_layout.index)
    c.on_press = function(obj)
      if (self.options.grid_mode.value == GRID_MODE_SINGLE) then 
        self:_set_option("grid_mode",GRID_MODE_MULTIPLE,self._process)
      elseif (self.options.grid_mode.value == GRID_MODE_MULTIPLE) then
        self:_set_option("grid_mode",GRID_MODE_SINGLE,self._process)
      end 
      self:_update_grid_mode()
    end
    
    self._cycle_layout = c
    print(">>> self._cycle_layout",self._cycle_layout)
    
  end 
end

---------------------------------------------------------------------------------------------------
-- call every update method 

function StepSequencer:_update_all()
  TRACE("StepSequencer:_update_all()")

  self:_update_line_count()
  self:_update_line_buttons()
  self:_update_grid_mode()
  self:_follow_track()
  self:_update_selected_column()
  self._update_tracks_requested = true
  self._update_lines_requested = true
  self._update_grid_requested = true 

end

---------------------------------------------------------------------------------------------------
-- Update grid mode when it changes 

function StepSequencer:_update_grid_mode()
  print("StepSequencer:_update_grid_mode()")

  local obj = self._cycle_layout
  print(">>> obj",obj)
  if obj then 
    if (self.options.grid_mode.value == GRID_MODE_SINGLE) then 
      obj:set(self.palette.grid_mode_single)
    elseif (self.options.grid_mode.value == GRID_MODE_MULTIPLE) then 
      obj:set(self.palette.grid_mode_multiple)
    elseif (self.options.grid_mode.value == GRID_MODE_MULTIPLE_COLS) then 
      error("Unexpected GRID_MODE")
    end 
  end

end

---------------------------------------------------------------------------------------------------
-- Update track navigator on new song, and when tracks have been changed

function StepSequencer:_update_track_count()
  TRACE("StepSequencer:_update_track_count")

  if self._track_navigator then
    local page_width = self:_get_track_page_width()
    -- (only include sequencer tracks)
    local seq_tracks= xTrack.get_tracks_by_type(renoise.Track.TRACK_TYPE_SEQUENCER)
    local page_count = math.ceil(#seq_tracks/page_width)-1
    self._track_navigator:set_range(0,page_count)
  end

end

---------------------------------------------------------------------------------------------------
-- If the playback position is inside visible range of the sequencer, 
-- update the position indicator. Else, if follow mode is active, 
-- display the current page

function StepSequencer:_update_position()
  TRACE("StepSequencer:_update_position()")

  local pos = rns.transport.playback_pos
  if self:_songpos_is_visible(pos) then
    self:_draw_position(pos.line)
  else
    if self._follow_player or self._start_tracking then      
      self:_should_update_page()
      self._start_tracking = false
    end
    self:_draw_position(0)
  end

end

---------------------------------------------------------------------------------------------------
-- Check if we should switch the active page/range inside the pattern

function StepSequencer:_should_update_page()
  TRACE("StepSequencer:_should_update_page")

  local pos = rns.transport.edit_pos
  local line_inc = self:_get_line_increment()
  local page = math.ceil(pos.line/line_inc)-1
  --print(">>> page,self._edit_page",page,self._edit_page)
  if (page~=self._edit_page) or self._start_tracking then
    self._edit_page = page
    if self._line_navigator then
      self._line_navigator:set_index(page,true)
    end
    self._update_grid_requested = true
  end

end

---------------------------------------------------------------------------------------------------
-- Set the current edit page
-- @param idx (int)

function StepSequencer:set_page(idx)
  TRACE("StepSequencer:set_page(idx)",idx)

  if(self._edit_page~=idx)then
    self._edit_page = idx
    self:post_jump_update()
  end

end

---------------------------------------------------------------------------------------------------
-- Jump to topmost page

function StepSequencer:jump_to_top()
  TRACE("StepSequencer:jump_to_top()")

  self._edit_page = 0
  self:post_jump_update()

end

---------------------------------------------------------------------------------------------------
-- Jump to bottommost page

function StepSequencer:jump_to_bottom()
  TRACE("StepSequencer:jump_to_bottom()")

  self._edit_page = self._edit_page_count
  self:post_jump_update()

end

---------------------------------------------------------------------------------------------------
-- Jump to previous page

function StepSequencer:jump_to_prev_lines()
  TRACE("StepSequencer:jump_to_prev_lines()")

  if (self._edit_page > 0) then
    self._edit_page = self._edit_page-1
    self:post_jump_update()
  end

end

---------------------------------------------------------------------------------------------------
-- Jump to next page

function StepSequencer:jump_to_next_lines()
  TRACE("StepSequencer:jump_to_next_lines()")

  if (self._edit_page <= (self._edit_page_count-1)) then
    self._edit_page = self._edit_page+1
    self:post_jump_update()
  end

end

---------------------------------------------------------------------------------------------------
-- Update display after a jump

function StepSequencer:post_jump_update()
  TRACE("StepSequencer:post_jump_update()")

  self._follow_player = false
  self._update_grid_requested = true 
  self:_update_line_buttons()

  if (self.options.follow_line.value == FOLLOW_LINE_SET) then
    xPattern.jump_to_line(self:_get_line_offset()+1)
  end

end

---------------------------------------------------------------------------------------------------
-- Display a line-position within the sequencer
-- [GRID_MODE_MULTIPLE] show position inside the level-strip
-- [GRID_MODE_SINGLE] show position inside the matrix 
-- @param line_pos (number), current playback line (0 to clear)

function StepSequencer:_draw_position(line_pos)
  TRACE("StepSequencer:_draw_position(line_pos)",line_pos)

  local line_offset = self:_get_line_offset()

  if (line_pos == 0) then
    if self._levelstrip then
      self._levelstrip:set_index(0,true)
    end
    if self._highlighted_button_index then 
      self._highlighted_button_index = nil
      self._update_grid_requested = true    
    end
    return
  end

  if self._levelstrip and 
    ((self.options.grid_mode.value == GRID_MODE_MULTIPLE) 
    or (self.options.grid_mode.value == GRID_MODE_MULTIPLE_COLS))
  then
    -- display inside level-strip
    local new_idx = ((line_pos-1-line_offset)%self._levelstrip._size)+1
    local ctrl_idx = self._levelstrip:get_index()
    if (ctrl_idx~=new_idx) then
      self._levelstrip:set_index(new_idx,true)
    end
  elseif (self.options.grid_mode.value == GRID_MODE_SINGLE) then 
    -- display inside matrix 
    self._highlighted_button_index = line_pos - line_offset 
    self._update_grid_requested = true
  end 

end

---------------------------------------------------------------------------------------------------
-- Update the range of the line navigator

function StepSequencer:_update_line_count()
  TRACE("StepSequencer:_update_line_count()")

  if not self.active then 
    return 
  end

  local pattern = nil
  if (self._follow_player) then
    pattern = xPatternSequencer.get_playing_pattern()
  else
    pattern = rns.selected_pattern
  end
  local line_inc = self:_get_line_increment()
  self._edit_page_count = math.ceil(math.floor(pattern.number_of_lines)/line_inc)-1
  if self._line_navigator then
    self._line_navigator.steps = self._edit_page_count
  end
  self:_update_line_buttons()

end


---------------------------------------------------------------------------------------------------
-- Update the display (line buttons)

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

---------------------------------------------------------------------------------------------------
-- Update the display (main grid)

function StepSequencer:_update_grid()
  TRACE("StepSequencer:_update_grid()")

  if not self.active then 
    return 
  end

  self:_update_selected_column()
  
  local orientation = self:_get_orientation()

  -- loop through grid & buttons
  local line_offset = self:_get_line_offset()
  
  local track_c,line_c = nil,nil
  if ( self.options.grid_mode.value == GRID_MODE_SINGLE ) then 
    track_c = 1
    line_c = self._line_count * self._track_count
  elseif ( self.options.grid_mode.value == GRID_MODE_MULTIPLE ) then 
    track_c = self._track_count
    line_c = self._line_count  
  elseif ( self.options.grid_mode.value == GRID_MODE_MULTIPLE_COLS ) then 
    error("TODO")
  else
    error("Unexpected GRID_MODE")
  end

  for seq_track_idx = (1 + self._track_offset),(track_c+self._track_offset) do
    
    local actual_track_idx = StepSequencer._get_actual_track_index(seq_track_idx)
    local pattern_track = rns.selected_pattern.tracks[actual_track_idx]
    local current_track = (actual_track_idx==rns.selected_track_index)
    for line_idx = (1 + line_offset),(line_c + line_offset) do

      local x = line_idx - line_offset
      local y = seq_track_idx - self._track_offset
      -- button highlight: only in single track mode 
      local is_highlighted = false
      if (self.options.grid_mode.value == GRID_MODE_SINGLE) then 
        is_highlighted = (x == self._highlighted_button_index)
      end
      
      if(orientation == ORIENTATION.VERTICAL) then
        x,y = y,x
      end
      local button = self._buttons[x][y]

      if (button ~= nil) then 

        if is_highlighted then 
          -- let it shine 
          button:set(self.palette.slot_highlight)
        else
          local notecol = nil
          if (line_idx <= rns.selected_pattern.number_of_lines) and
            actual_track_idx and (actual_track_idx <= #rns.tracks) 
          then
            notecol = pattern_track:line(line_idx).note_columns[self._current_column_index]
          end
          self:_draw_grid_button(button,notecol,current_track)
        end
      end

    end
  end
end

---------------------------------------------------------------------------------------------------
-- Decide if we need to update the display when the pattern editor has changed 
-- note: this method might be called hundreds of times when doing edits like
-- cutting all notes from a pattern, so we need it to be really simple
-- @param linepos, table{pattern:number,track:number,line:number}

function StepSequencer:_track_line_changes(linepos)
  TRACE("StepSequencer:_track_line_changes()",linepos)

  -- a line notifier does not specify the sequence index, 
  -- so we use the current edit position as the basis
  local songpos = rns.transport.edit_pos 
  songpos.line = linepos.line 

  if self:_songpos_is_visible(songpos) and 
    self:_track_is_visible(linepos.track) 
  then
    self._update_grid_requested = true
  end

end

---------------------------------------------------------------------------------------------------
-- Check if a given line is within the visible range
-- @param pos, renoise.SongPos or table{sequence:number,line:number}
-- @return boolean

function StepSequencer:_songpos_is_visible(pos)
  TRACE("StepSequencer:_songpos_is_visible(pos)",pos)
  
  -- check if we are watching the playing pattern 
  local playing_patt_index = rns.sequencer:pattern(pos.sequence)
  if (playing_patt_index ~= self._current_pattern_index) then
    return false
  end

  local rslt = false
  local line_offset = self:_get_line_offset()

  if (self.options.grid_mode.value == GRID_MODE_SINGLE) then  
    -- [Single track] Use the entire matrix as range 
    rslt = (line_offset < pos.line) and 
      (pos.line <= line_offset+(self._track_count * self._line_count))
  elseif (self.options.grid_mode.value == GRID_MODE_MULTIPLE) or 
    (self.options.grid_mode.value == GRID_MODE_MULTIPLE_COLS) 
  then  
    -- [Multiple tracks/columns] Use the number of lines 
    rslt = (line_offset < pos.line) and 
      (pos.line <= (line_offset+self._line_count))
  else
    error("Unexpected GRID_MODE")
  end

  return rslt

end

---------------------------------------------------------------------------------------------------
-- Check if a given track is within the visible range
-- @param rns_track_idx (int)
-- @return boolean

function StepSequencer:_track_is_visible(rns_track_idx)
  TRACE("StepSequencer:_track_is_visible(rns_track_idx)",rns_track_idx)

  local seq_track_idx = StepSequencer._get_sequencer_track_index(rns_track_idx)
  if not seq_track_idx then
    return false 
  end

  return (seq_track_idx>self._track_offset) and
    (seq_track_idx<=(self._track_offset+self._track_count))

end

---------------------------------------------------------------------------------------------------
-- When following the active track in Renoise, we call this method
-- (note: track following is limited to sequencer tracks)

function StepSequencer:_follow_track()
  TRACE("StepSequencer:_follow_track()")

  if (self.options.follow_track.value == FOLLOW_TRACK_OFF) then
    return
  end

  local seq_track_idx = StepSequencer._get_sequencer_track_index(rns.selected_track_index)
  if not seq_track_idx then 
    LOG("StepSequencer: Can't follow track - out of bounds")
    return 
  end
  
  local page = self:_get_track_page(seq_track_idx)
  local page_width = self:_get_track_page_width()
  if (page~=self._track_page) then
    self._track_page = page
    self._track_offset = page*page_width
    self._update_grid_requested = true
    if self._track_navigator then
      self._track_navigator:set_index(page,true)
    end
  end

  if self._highlight_track then
    self._update_grid_requested = true
  end

end

---------------------------------------------------------------------------------------------------
-- Figure out the sequencer track index (filter out non-sequencer-tracks)
-- @param rns_track_idx, number
-- @return number or nil

function StepSequencer._get_sequencer_track_index(rns_track_idx)
  TRACE("StepSequencer._get_sequencer_track_index(rns_track_idx)",rns_track_idx)

  local seq_tracks = xTrack.get_tracks_by_type(renoise.Track.TRACK_TYPE_SEQUENCER)
  return table.find(seq_tracks,rns_track_idx)

end

---------------------------------------------------------------------------------------------------
-- Figure out the actual track index when providing a sequencer-track index
-- @param seq_track_idx, number
-- @return number or nil

function StepSequencer._get_actual_track_index(seq_track_idx)
  TRACE("StepSequencer._get_actual_track_index(seq_track_idx)",seq_track_idx)

  local seq_tracks = xTrack.get_tracks_by_type(renoise.Track.TRACK_TYPE_SEQUENCER)
  return seq_tracks[seq_track_idx]

end

---------------------------------------------------------------------------------------------------
-- When following the active track in Renoise, we call this method
-- (track following is limited to sequencer tracks)

function StepSequencer:_update_selected_column()
  TRACE("StepSequencer:_update_selected_column()")

  if (self.options.follow_column.value == FOLLOW_COLUMN_OFF) then
    self._current_column_index = 1
  else 
    self._current_column_index = rns.selected_note_column_index
  end

end

---------------------------------------------------------------------------------------------------
-- Figure out the active "track page" based on the sequencer-track index
-- @param seq_track_idx, number
-- return integer (0-number of pages)

function StepSequencer:_get_track_page(seq_track_idx)
  TRACE("StepSequencer:_get_track_page(seq_track_idx)",seq_track_idx)

  local page_width = self:_get_track_page_width()
  local page = math.floor((seq_track_idx-1)/page_width)
  return page

end

---------------------------------------------------------------------------------------------------
-- Get the currently set track-page width
-- @return int

function StepSequencer:_get_track_page_width()
  TRACE("StepSequencer:_get_track_page_width()")

  if (self.options.grid_mode.value == GRID_MODE_SINGLE) then
   return 1
  elseif ( self.options.grid_mode.value == GRID_MODE_MULTIPLE ) then
    return (self.options.page_size.value == TRACK_PAGE_AUTO)
      and self._track_count or self.options.page_size.value-1
  elseif ( self.options.grid_mode.value == GRID_MODE_MULTIPLE_COLS ) then
    error("TODO")
  else
    error("Unexpected GRID_MODE")
  end

end

---------------------------------------------------------------------------------------------------
-- Options - resolve the current line increment 
-- @return int

function StepSequencer:_get_line_increment()
  TRACE("StepSequencer:_get_line_increment()")

  if (self.options.line_increment.value ~= LINE_INCREMENT_AUTO) then 
    return self.options.line_increment.value-1
  else -- automatic size 
    if (self.options.grid_mode.value == GRID_MODE_SINGLE) then
      return self._track_count * self._line_count -- use complete grid 
    elseif ( self.options.grid_mode.value == GRID_MODE_MULTIPLE ) then
      return self._line_count
    elseif ( self.options.grid_mode.value == GRID_MODE_MULTIPLE_COLS ) then
      error("TODO")
    else
      error("Unexpected GRID_MODE")
    end  
  end

end 

---------------------------------------------------------------------------------------------------
-- Get the current line offset 

function StepSequencer:_get_line_offset()
  TRACE("StepSequencer:_get_line_offset()")

  local line_inc = self:_get_line_increment()
  return self._edit_page*line_inc

end

---------------------------------------------------------------------------------------------------
-- Get the orientation of the main grid
-- return ORIENTATION

function StepSequencer:_get_orientation()
  TRACE("StepSequencer:_get_orientation()")
  
  return self.mappings.grid.orientation

end

---------------------------------------------------------------------------------------------------
-- Add notifiers to relevant parts of the song

function StepSequencer:_attach_to_song()
  TRACE("StepSequencer:_attach_to_song()")
  
  self:_remove_notifiers(self._song_notifiers)

  local obs = nil 

  obs = rns.tracks_observable
  self._song_notifiers:insert(obs)
  obs:add_notifier(self,function()
    TRACE("StepSequencer:_tracks_notifier fired...")
    -- do this right away (updating the spinner is easily done, and we
    -- avoid that setting the index will fail, because idle() has yet to 
    -- increase the number of track pages...)
    self:_update_track_count()
    --self._update_tracks_requested = true
  end)

  obs = rns.patterns_observable
  self._song_notifiers:insert(obs)
  obs:add_notifier(self,function()
    TRACE("StepSequencer:_patterns_notifier()")
    self._update_lines_requested = true
  end)

  obs = rns.selected_track_index_observable
  self._song_notifiers:insert(obs)
  obs:add_notifier(self,function()
    TRACE("StepSequencer:_track_notifier()")
    self:_follow_track()
  end)

  obs = rns.selected_pattern_observable
  self._song_notifiers:insert(obs)
  obs:add_notifier(self,function()
    TRACE("StepSequencer:_pattern_notifier()")
    self:_attach_to_pattern(self._current_pattern_index)
  end)

  obs = rns.transport.follow_player_observable
  self._song_notifiers:insert(obs)
  obs:add_notifier(self,function()
    TRACE("StepSequencer:_follow_player_notifier()")
    -- if switching on, start tracking actively
    local follow = rns.transport.follow_player
    if not (follow == self._follow_player) then
      self._start_tracking = follow
    end
    self._follow_player = follow
    if(self._follow_player)then   
      self:_should_update_page()
    end
  end)

  self:_attach_to_pattern(rns.selected_pattern_index)

end

---------------------------------------------------------------------------------------------------
-- Add notifiers to the pattern

function StepSequencer:_attach_to_pattern(patt_idx)
  TRACE("StepSequencer:_attach_to_pattern()",patt_idx)

  self:_attach_line_notifiers(patt_idx)
  self:_attach_alias_notifiers(patt_idx)

end

---------------------------------------------------------------------------------------------------
-- Monitor the current pattern for changes to it's aliases

function StepSequencer:_attach_alias_notifiers(patt_idx)
  TRACE("StepSequencer:_attach_alias_notifiers()",patt_idx)

  self:_remove_notifiers(self._alias_notifiers)

  local patt = rns.patterns[patt_idx]
  for track_idx = 1,rns.sequencer_track_count do
    local track = patt.tracks[track_idx]
    self._alias_notifiers:insert(track.alias_pattern_index_observable)
    track.alias_pattern_index_observable:add_notifier(self,
      function(notification)
        TRACE("StepSequencer - alias_pattern_index_observable fired...",notification)
        self:_attach_line_notifiers(rns.selected_pattern_index)
        self._update_tracks_requested = true
      end
    )
  end

end

---------------------------------------------------------------------------------------------------
-- Attach line notifiers to pattern 
-- check for existing notifiers first, and remove those
-- then add pattern notifiers to pattern (including aliased slots)

function StepSequencer:_attach_line_notifiers(patt_idx)
  TRACE("StepSequencer:_attach_line_notifiers()",patt_idx)

  self:_remove_line_notifiers()

  local patt = rns.patterns[patt_idx]
  if not patt then
    LOG("Couldn't attach line notifiers: pattern #",patt_idx,"does not exist")
    return
  end

  local function attach_to_pattern_lines(patt_idx) 
    TRACE("StepSequencer:_attach_line_notifiers() - attach_to_pattern",patt_idx)
    if not (patt:has_line_notifier(self._track_line_changes,self))then
      patt:add_line_notifier(self._track_line_changes,self)
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

---------------------------------------------------------------------------------------------------

function StepSequencer:_remove_pattern_lines_notifier()
  TRACE("StepSequencer:_remove_pattern_lines_notifier()")

  pcall(function()
    local notifier = StepSequencer._number_of_lines_notifier
    self._number_of_lines_observable:remove_notifier(self,notifier)
  end)

end

---------------------------------------------------------------------------------------------------
-- Remove currently attached line notifiers 

function StepSequencer:_remove_line_notifiers()
  TRACE("StepSequencer:_remove_line_notifiers()")

  for patt_idx in ipairs(self._line_notifiers) do
    local patt = rns.patterns[patt_idx]
    TRACE("*** StepSequencer - remove_line_notifier from patt",patt,type(patt))
    if patt and (type(patt)~="number") and (patt:has_line_notifier(self._track_line_changes,self)) then
      patt:remove_line_notifier(self._track_line_changes,self)
    end
  end
  self._line_notifiers = table.create()

end

------------------------------------------------------------------------------------------
---------

function StepSequencer:_number_of_lines_notifier()

  self._update_lines_requested = true
  -- check if the edit-page exceed the new length 
  local line_offset = self:_get_line_offset()
  local patt = rns.patterns[self._current_pattern_index]
  if (line_offset>patt.number_of_lines) then
    self._edit_page = 0 -- reset
  end

end

---------------------------------------------------------------------------------------------------
-- Inherited from Application
-- @see Duplex.Application.on_new_document

function StepSequencer:on_new_document()
  TRACE("StepSequencer:on_new_document()")

  rns = renoise.song()

  if self.active then 
    self:_attach_to_song(true)  
    self:_update_all()
  end

end


---------------------------------------------------------------------------------------------------
-- STEP SEQUENCER FUNCTIONS
---------------------------------------------------------------------------------------------------
-- Handle when button in main grid is pressed
-- @param x, number
-- @param y, number
-- @param state, boolean
-- @param btn (UIButton)

function StepSequencer:_process_grid_event(x,y, state, btn)
  TRACE("StepSequencer:_process_grid_event()",x,y, state, btn)

  local track_idx,line_idx,t_ex = x,y,true
  if not (self:_get_orientation() == ORIENTATION.VERTICAL) then
    line_idx,track_idx = track_idx,line_idx
  end
  track_idx = track_idx+self._track_offset

  line_idx = line_idx+self:_get_line_offset()

  local rns_track_idx = StepSequencer._get_actual_track_index(track_idx)
  if not rns_track_idx or (rns_track_idx >= xTrack.get_master_track_index()) then 
    return false 
  end
  
  local current_track = (rns_track_idx == rns.selected_track_index)

  self:_update_selected_column()

  local notecol = rns.selected_pattern.tracks[rns_track_idx]:line(
    line_idx).note_columns[self._current_column_index]

  -- determine instrument by matching track title with instruments
  -- a matching title will select that instrument 
  local track_name = rns.tracks[rns_track_idx].name
  local instr_index = self:_obtain_instrument_by_name(track_name)
  if not instr_index then
    instr_index = rns.selected_instrument_index
  else
    local msg = "StepSequencer: matched track/instrument name"..track_name
    renoise.app():show_status(msg)
  end

  local base_note = (self._base_note-1) + (self._base_octave-1)*12
  
  if state then -- press

    self._keys_down[x][y] = true

    --if (note.note_string == "OFF" or note.note_string == "---") then
    if (notecol.note_string == "---") then
      if self:_write_note() then
        self:_set_note(notecol, base_note, instr_index-1, self._base_volume)
        self._toggle_exempt[x][y] = true
        -- and update the button ...
        self:_draw_grid_button(btn,notecol,current_track)
      elseif ( self:_play_note() ) then
        -- trigger note 
        self.voice_mgr:trigger(self,instr_index,rns_track_idx, base_note , self._base_volume , false)
      else
        LOG("StepSequencer: neither write nor play?")
      end
    else
      -- trigger note 
      if ( self:_play_note() and self.options.write_mode.value == WRITE_MODE_RECORD_ON ) then
        self.voice_mgr:trigger(self,instr_index,rns_track_idx, base_note , self._base_volume , false)
      end
    end

  else -- release

    self._keys_down[x][y] = nil
    if self:_write_note() then
      -- don't toggle off if we just turned on
      if (not self._toggle_exempt[x][y]) then    
        self:_clear_note(notecol)
        -- and update the button ...
        if (rns.selected_pattern.number_of_lines<line_idx) then
          -- reset to "out of bounds" color
          notecol = nil
        end
        self:_draw_grid_button(btn,notecol,current_track)
      else
        self._toggle_exempt[x][y] = nil
      end

    end
     -- release note
    if ( self:_play_note() ) then
       self.voice_mgr:release(self,instr_index,rns_track_idx, base_note , self._base_volume , false)
    end

  end


  -- -- trigger notes 
  -- if ( rns.transport.edit_mode == false 
  --      and self.options.play_notes.value == PLAY_NOTES_ON ) then
  --   if ( state ) then
  --     self.voice_mgr:trigger(self,instr_index,rns_track_idx, base_note , self._base_volume , false)
  --   else 
  --     self.voice_mgr:release(self,instr_index,rns_track_idx, base_note , self._base_volume , false)
  --   end
  -- end



  return true
end

---------------------------------------------------------------------------------------------------
-- Obtain instrument by name (track<>instrument synchronization)
-- @return int, instrument index

function StepSequencer:_obtain_instrument_by_name(name)
  TRACE("StepSequencer:_obtain_instrument_by_name()",name)

  for instr_index,instr in ipairs(rns.instruments) do
    if (instr.name == name) then
      return instr_index
    end
  end

end

---------------------------------------------------------------------------------------------------
-- Find and copy a note in the pattern (when button is held)
-- @param lx (int)
-- @param ly (int)
-- @param btn (@{Duplex.UIButton})
-- @return true when copying was done

function StepSequencer:_copy_grid_button(lx,ly, btn)
  TRACE("StepSequencer:_copy_grid_button()",lx,ly, btn)

  local gx = nil
  local gy = nil

  if not (self:_get_orientation() == ORIENTATION.VERTICAL) then
    lx,ly = ly,lx
  end

  local line_inc = self:_get_line_increment()

  if (self.options.grid_mode.value == GRID_MODE_SINGLE) then
    gx = lx+self._track_offset
    gy = ly+self._edit_page * line_inc
  elseif ( self.options.grid_mode.value == GRID_MODE_MULTIPLE ) then
    gx = lx+self._track_offset
    gy = ly+self._edit_page * line_inc
  elseif ( self.options.grid_mode.value == GRID_MODE_MULTIPLE_COLS ) then
    error("TODO")
  else
    error("Unexpected GRID_MODE")
  end

  local rns_track_idx = StepSequencer._get_actual_track_index(gx)
  if (rns_track_idx >= xTrack.get_master_track_index()) then 
    return false 
  end

  self:_update_selected_column()
  local rns_track = rns.selected_pattern.tracks[rns_track_idx]
  local notecol = rns_track:line(gy).note_columns[self._current_column_index]
  if not notecol then
    return false
  end

  -- copy note to base note
  if (notecol.note_value <= 120) then
    self:_set_basenote(notecol.note_value)
  else
    return false
  end

  -- copy volume to base volume
  local note_vol = math.min(127,notecol.volume_value)
  if (notecol.volume_value == 255 and notecol.note_value == 120) then
    note_vol = 0 -- special case: note-off
  end
  if (note_vol <= 127) then
    self._base_volume = note_vol
    self:_draw_volume_slider(note_vol)
    self:_draw_volume_steps(note_vol)
    self:_draw_level_slider(note_vol)
  end
  -- change selected instrument
  if (notecol.instrument_value < #rns.instruments) then
    rns.selected_instrument_index = notecol.instrument_value+1
  end
  
  return true

end

---------------------------------------------------------------------------------------------------
-- Function to safely obtain a note-column 
-- @param track_idx (number)
-- @param line_idx (number)
-- @return renoise.NoteColumn or nil 

function StepSequencer:get_notecolumn(track_idx,line_idx)

  local rns_track_idx = StepSequencer._get_actual_track_index(track_idx+self._track_offset)
  local ptrack = rns.selected_pattern.tracks[rns_track_idx]
  if not ptrack then
    LOG("*** StepSequencer: Failed to locate pattern-track")
    return 
  end
  local line_inc = self:_get_line_increment()  
  local pline = ptrack:line(line_idx + self._edit_page * line_inc)
  if not pline then
    LOG("*** StepSequencer: Failed to locate pattern-line")
    return 
  end
  local notecol = pline.note_columns[self._current_column_index]
  if not notecol then
    LOG("*** StepSequencer: Failed to locate note-column")
    return 
  end

  return notecol

end

---------------------------------------------------------------------------------------------------
-- Update display of volume slider
-- @param volume (int), between 0-127

function StepSequencer:_draw_volume_slider(volume)
  TRACE("StepSequencer:_draw_volume_slider()",volume)
  
  if self._levelstrip then

    if not volume then
      volume = self._base_volume
    end 

    local p = { }
    if (volume == 0) then
      p = table.rcopy(self.palette.slot_muted)
    else 
      p = self:_volume_palette(volume, 127)
    end

    local idx = self._levelstrip._size-math.floor((volume/127)*self._levelstrip._size)
    self._levelstrip:set_palette({range = p})
    self._levelstrip:set_range(idx,self._levelstrip._size)

  end

end

---------------------------------------------------------------------------------------------------
-- Update display of volume slider
-- @param volume (int), between 0-127

function StepSequencer:_draw_volume_steps(volume)
  TRACE("StepSequencer:_draw_volume_steps()",volume)
  
  if self._levelsteps then

    if not volume then
      volume = self._base_volume
    end 

    local p = { }
    if (volume == 0) then
      p = table.rcopy(self.palette.slot_muted)
    else 
      p = self:_volume_palette(volume, 127)
    end

    self._levelsteps:set(p)

  end

end

---------------------------------------------------------------------------------------------------
-- Update the level slider 
-- @param volume (int), between 0-127

function StepSequencer:_draw_level_slider(volume)
  if self._levelslider then
    self._levelslider:set_value(volume)
  end
end

---------------------------------------------------------------------------------------------------
-- Check if it should be possible to write not pattern
-- @return boolean

function StepSequencer:_write_note()
  TRACE("StepSequencer:_write_note()")

  if (rns.transport.edit_mode == true and 
    self.options.write_mode.value == WRITE_MODE_RECORD_ON) or 
     (self.options.write_mode.value == WRITE_MODE_RECORD_OFF) 
  then
    return true
  else
    return false
  end    

end

---------------------------------------------------------------------------------------------------
-- Check if note should be triggered
-- @return boolean

function StepSequencer:_play_note()
  TRACE("StepSequencer:_play_note()")
  if ( rns.transport.edit_mode == false and
    self.options.play_notes.value == PLAY_NOTES_ON ) 
  then
    return true
  else
    return false
  end    

end

---------------------------------------------------------------------------------------------------
-- Write properties into provided note column
-- @param notecol (NoteColumn)
-- @param note (int) note pitch
-- @param instrument (int) instrument number
-- @param volume (int) note velocity

function StepSequencer:_set_note(notecol,note,instrument,volume)
  TRACE("StepSequencer:_set_note(notecol,note,instrument,volume)",notecol,note,instrument,volume)

  if (note == 120) then 
    -- special case: note-off 
    notecol.note_value = 120
    notecol.instrument_value = 255
    notecol.volume_value = 255
  else
    notecol.note_value = note
    notecol.instrument_value = instrument
    notecol.volume_value = volume
  end 

end

---------------------------------------------------------------------------------------------------
-- Clear properties for note column
-- @param notecol (NoteColumn)

function StepSequencer:_clear_note(notecol)
  TRACE("StepSequencer:_clear_note(notecol)",notecol)

  self:_set_note(notecol, 121, 255, 255)

end

---------------------------------------------------------------------------------------------------
-- Assign color to button, based on note properties
-- @param button, UIButton
-- @param notecol, renoise.NoteColumn or nil 
-- @param current_track, boolean 

function StepSequencer:_draw_grid_button(button,notecol,current_track)
  TRACE("StepSequencer:_draw_grid_button()",button,notecol,current_track)
  
  if (notecol ~= nil) then
    if (notecol.note_value == 121) then
      if current_track then
        button:set(self.palette.slot_current)
      else
        button:set(self.palette.slot_empty)
      end
    elseif (notecol.note_value == 120 or notecol.volume_value == 0) then
      button:set(self.palette.slot_muted)
    else
      button:set(self:_volume_palette(notecol.volume_value, 127))
    end
    if (self.options.display_notes.value == DISPLAY_NOTES_ON and notecol.note_value ~= 121 ) then
       local t = tostring (notecol.note_string)
       if ( self.mappings.grid.button_size >= 1.3 ) then
         t = t.."\n"..tostring (notecol.volume_value)
       end
       button:set({text=t})
    end
  else
    button:set(self.palette.out_of_bounds)
  end

end

---------------------------------------------------------------------------------------------------
-- Figure out the color for a given volume level 
-- @param vol (int), between 0-127
-- @param max (int), 127
-- @return table{int,int,int}

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


---------------------------------------------------------------------------------------------------
-- Set basenote for new notes
-- @param note_value (int) note pitch

function StepSequencer:_set_basenote(note_value)
  TRACE("StepSequencer:_set_basenote(note_value)",note_value)

  local note = note_value % 12 +1
  local oct = math.floor(note_value / 12) +1
  self._base_note = note
  self._base_octave = oct
  local msg = string.format(
    "StepSequencer: Basenote changed to %s%i",NOTE_ARRAY[note],oct-1)

  renoise.app():show_status(msg)

end


---------------------------------------------------------------------------------------------------
-- Transpose existing basenote by given amount
-- @param steps (int) relative amount to add 

function StepSequencer:_transpose_basenote(steps)
  TRACE("StepSequencer:_transpose_basenote(steps)",steps)

  local baseNote = (self._base_note-1)+(self._base_octave-1)*12
  local newval = baseNote + steps
  if (0 <= newval and newval < 120) then
    self:_set_basenote(newval)
  end

end


---------------------------------------------------------------------------------------------------
-- Detach all previously attached notifiers first
-- @param observables - list of observables

function StepSequencer:_remove_notifiers(observables)
  TRACE("StepSequencer:_remove_notifiers()",observables)

  for _,observable in pairs(observables) do
    local passed,err = pcall(function() observable:remove_notifier(self) end)
    if not passed and err then
      --LOG("*** Could not remove observable",err)
    end 
  end
    
  observables:clear()

end

---------------------------------------------------------------------------------------------------
-- Apply a function to all held grid buttons, optionally adding them 
-- all to toggle_exempt table.  
-- @param callback (function), the callback function
-- @param toggle_exempt (bool), do not toggle off
-- @return the number of held keys

function StepSequencer:_walk_held_keys(callback,toggle_exempt)
  TRACE("StepSequencer:_walk_held_keys(callback,toggle_exempt)",callback,toggle_exempt)

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

---------------------------------------------------------------------------------------------------
-- Inherited from Application
-- @see Duplex.Application.on_idle

function StepSequencer:on_idle()
  --TRACE("StepSequencer:on_idle()")

  if not self.active then 
    return 
  end

  -- did we change current_pattern?
  if (self._current_pattern_index ~= rns.selected_pattern_index) then
    self._current_pattern_index = rns.selected_pattern_index
    self._update_lines_requested = true
    -- attach notifier to pattern length
    self:_remove_pattern_lines_notifier()
    self._number_of_lines_observable = rns.patterns[self._current_pattern_index].number_of_lines_observable
    self._number_of_lines_observable:add_notifier(self,StepSequencer._number_of_lines_notifier)
  end

  -- did we change current_column?
  if (self._current_column_index ~= rns.selected_note_column_index) then
    self:_update_selected_column();
    self._update_grid_requested = true
  end

  -- check if the edit line changed
  local edit_line_changed = false
  local line_index = rns.transport.edit_pos.line
  if (self._current_edit_line_index ~= line_index) then
    edit_line_changed = true
  end
  if edit_line_changed 
    and ((self.options.follow_line.value == FOLLOW_LINE_ON)
      or (self.options.follow_line.value == FOLLOW_LINE_SET)
      or (rns.transport.playing and rns.transport.follow_player))
  then
    self._current_edit_line_index = line_index
    self:_should_update_page()
    self:_update_line_buttons()
  end

  -- check if the playing line changed
  local playing_line_changed = false
  local playpos_line = rns.transport.playback_pos.line
  if rns.transport.playing and (playpos_line ~= self._playing_line_index) then
    -- playing at new line 
    playing_line_changed = true 
    self._playing_line_index = playpos_line
    self:_update_position()
  elseif not rns.transport.playing and self._playing_line_index then
    -- playback stopped 
    self._playing_line_index = nil
    self:_draw_position(0)
  end    
  
  if self._update_tracks_requested then
    self._update_grid_requested = true
    self._update_tracks_requested = false
    self:_update_track_count()
  end

  if self._update_lines_requested then
    self._update_grid_requested = true
    self._update_lines_requested = false
    self:_update_line_count()
  end
  
  if self._update_grid_requested then
    self._update_grid_requested = false
    self:_update_grid()
  end


end


