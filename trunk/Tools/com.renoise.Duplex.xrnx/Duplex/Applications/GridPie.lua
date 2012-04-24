--[[----------------------------------------------------------------------------
-- Duplex.GridPie
-- Inheritance: Application > GridPie
----------------------------------------------------------------------------]]--

--[[

About

  This application is a Duplex port of Grid Pie:
  http://www.renoise.com/board/index.php?/topic/27606-new-tool-27-grid-pie/

  What is Grid Pie? 

  Grid Pie is a performance interface. It lets the user combine different parts 
  of a linear song, non-linearly, in real time, using a special looping pattern 
  as a live drafting area. It does so by taking over the Pattern Matrix.

  Basic usage

  Once Grid Pie is started, it will mute all matrix slots and create the 
  special recombination pattern. Once you stop Grid Pie, it will revert those
  slots to their original state and remove the special pattern.

  While it is running, you can select any track on your controller to copy
  it to the recombination pattern. If "polyrhythms" have been enabled, it will
  even copy and expand pattern-tracks that have different lengths

  Navigating the Grid Pie

  A "hybrid" navigation scheme means that you can use the built-in controls
  for navigating the matrix, without going into the parts that are of no use
  to Grid Pie (such as send tracks). The navigation is fully compatible with the 
  "paged" navigation scheme of other Duplex apps (Mixer, etc.) - specify the 
  same page size to align them with each other. 


Mappings

  grid      - (UIButton...) - grid mapping, the individual buttons
  focus     - (UIButton...) - bring focus to active slot
  v_prev    - (UIButton)    - step to previous pattern
  v_next    - (UIButton)    - step to next pattern
  h_prev    - (UIButton)    - step to previous track
  h_next    - (UIButton)    - step to next track
  v_slider  - (UISlider)          - set pattern
  h_slider  - (UISlider)          - set track


Options
  follow_pos  - enable to make Renoise follow the pattern/track
  polyrhythms - allow/disallow polyrhythms when combining patterns (save CPU)
  page_size_v - determine how many patterns to scroll with each step
  page_size_h - determine how many tracks to scroll with each step
  auto_start  - Start playing when Grid Pie is launched
  hold_enabled - Enable this option only if your controller is capable
                of transmitting 'release' events (copy a pattern
                by pressing and holding a button in the grid)

Changes (equal to Duplex version number)

  0.98 - First release (based on v0.82 of the original tool)



--]]

--==============================================================================


class 'GridPie' (Application)


GridPie.default_options = {
  follow_pos = {
    label = "Follow position",
    description = "Enable this to sync the active pattern/track between Renoise & GridPie",
    items = {
      "Disabled",
      "Follow track",
      "Follow track & pattern",
    },
    value = 3,
  },
  polyrhythms = {
    label = "Polyrhythms",
    description = "Allow/disallow polyrhythms when combining patterns"
                .."\n(disable this feature if Grid Pie is using too much CPU)",
    items = {
      "Enabled",
      "Disabled",
    },
    value = 1,
  },
  page_size_v = {
    label = "Vertical page",
    description = "Specify the vertical page size",
    on_change = function(inst)
      inst:_set_step_sizes()
    end,
    items = {
      "Automatic: use available height",
      "1","2","3","4",
      "5","6","7","8",
      "9","10","11","12",
      "13","14","15","16",
    },
    value = 1,
  },
  page_size_h = {
    label = "Horizontal page",
    description = "Specify the horizontal page size",
    on_change = function(app)
      app:_set_step_sizes()
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
  auto_start = {
    label = "Auto-start",
    description = "Start playing when Grid Pie is launched",
    items = {
      "Enabled, start playing once ready",
      "Disabled",
    },
    value = 1,
  },
  hold_enabled = {
    label = "Pattern copy",
    description = "Enable this option only if your controller is capable"
                .."\nof transmitting 'release' events (copy a pattern"
                .."\nby pressing and holding a button in the grid)",
    on_change = function(app)
      local msg = "This change will take effect the next time you (re)load the tools"
      renoise.app():show_message(msg)
    end,
    items = {
      "Enabled",
      "Disabled",
    },
    value = 1,
  }
}

--------------------------------------------------------------------------------

function GridPie:__init(process,mappings,options,cfg_name,palette)
  TRACE("GridPie:__init(",process,mappings,options,cfg_name,palette)

  -- option constants
  self.POLY_ENABLED = 1
  self.POLY_DISABLED = 2
  self.FOLLOW_OFF = 1
  self.FOLLOW_TRACK = 2
  self.FOLLOW_TRACK_PATTERN = 3
  self.STEPSIZE_AUTO = 1
  self.AUTOSTART_ON = 1
  self.AUTOSTART_OFF = 2
  self.HOLD_ENABLED = 1
  self.HOLD_DISABLED = 2

  -- sequence index/name of recombination pattern
  self.gp_patt_idx = nil
  self.GRIDPIE_NAME = "__GRID_PIE__"

  -- true when we shouldn't listen for changes to the 
  -- recombination pattern (when copying pattern data)
  self.skip_gp_notifier = false

  -- width/height of the "grid" control-map group
  self.MATRIX_HEIGHT = nil
  self.MATRIX_WIDTH = nil

  -- references to the grid's buttons
  self.MATRIX_CELLS = table.create()

  -- remember length (pattern-lines) of each track
  self.POLY_COUNTER = table.create()

  -- memorized state of the matrix 
  self.REVERT_PM_SLOT = table.create()

  -- these indicate the upper-left corner of the area
  -- currently displayed on the controller
  self.X_POS = 1 
  self.Y_POS = 1

  -- remember the slot sequence indices
  -- (this is set, no matter if the track is active or not,
  -- check the POLY_COUNTER to see if the track is active) 
  self.active_slots = table.create()

  -- when we have edited content that needs copy-expansion:
  -- [track_index] = {
  --   src_patt_idx
  --   dest_patt_idx 
  --   pos 
  --  }
  self.pending_updates = table.create()

  -- (Scheduler) this is the task, created whenever we
  -- change something which require a delay
  self.update_task = nil

  -- boolean, true when button has been held
  self.held_button = nil

  -- page size (horizontal/vertical)
  self.page_size_v = nil
  self.page_size_h = nil

  -- the selected track/sequence index
  self.actual_x = nil
  self.actual_y = nil

  -- highlight the currently displayed pattern
  -- (true when "empty_current" color is different than "empty")
  self.show_current_pattern = false

  -- remember the current pattern (for line notifier)
  self._current_seq_index = nil

  -- running start: pattern seq. index when we started 
  self._cached_playpos = nil

  -- true once application has been initialized
  self._has_been_started = false

  -- various flags used by idle loop
  self.play_requested = false
  self.update_requested = false
  self.v_update_requested = false
  self.h_update_requested = false

  -- keep reference to process, so we stop/abort the application
  self._process = process

  -- UIComponent references
  self._bt_prev_seq = nil
  self._bt_next_seq = nil
  self._bt_prev_track = nil
  self._bt_next_track = nil
  self._v_slider = nil
  self._h_slider = nil

  self.mappings = {
    grid = {
      description = "GridPie: Press and release to copy track"
                  .."\nPress and hold to copy pattern"
                  .."\nControl value: ",
    },
    h_slider = {
      description = "GridPie: select pattern in sequence"
    },
    v_prev = {
      description = "GridPie: Press and release to display previous part of sequence"
                  .."\nPress and hold to display first pattern"
    },
    v_next = {
      description = "GridPie: Press and release to display next part of sequence"
                  .."\nPress and hold to display last pattern"
    },
    h_prev = {
      description = "GridPie: Press and release to display previous tracks in pattern"
                  .."\nPress and hold to go display first track"
    },
    h_next = {
      description = "GridPie: Press and release to display next tracks in pattern"
                  .."\nPress and hold to go display last track"
    },
    v_slider = {
      description = "GridPie: select track in pattern"
    },
  }

  self.palette = {
    -- the various grid-pie button states
    empty                   = { color={0x00,0x00,0x00}, text="·", val=false },
    empty_current           = { color={0x40,0x40,0x00}, text="·", val=false },
    active_filled           = { color={0xFF,0xFF,0x00}, text="·", val=true  },
    active_empty            = { color={0xFF,0x80,0x00}, text="·", val=true  },
    filled                  = { color={0x40,0x00,0x00}, text="·", val=false },
    filled_silent           = { color={0x80,0x40,0x00}, text="·", val=false },
    out_of_bounds           = { color={0x40,0x40,0x00}, text="·", val=false },  
    out_of_bounds_current   = { color={0x80,0x80,0x00}, text="·", val=false },  
    button_next_track_off   = { color={0x00,0x00,0x00}, text="►", val=false },
    button_next_track_on    = { color={0xFF,0x80,0x00}, text="►", val=true  },
    button_prev_track_on    = { color={0xFF,0x80,0x00}, text="◄", val=true  },
    button_prev_track_off   = { color={0x00,0x00,0x00}, text="◄", val=false },
    button_next_patt_on     = { color={0xFF,0x80,0x00}, text="▼", val=true  },
    button_next_patt_off    = { color={0x00,0x00,0x00}, text="▼", val=false },
    button_prev_patt_on     = { color={0xFF,0x80,0x00}, text="▲", val=true  },
    button_prev_patt_off    = { color={0x00,0x00,0x00}, text="▲", val=false },
  }

  Application.__init(self,process,mappings,options,cfg_name,palette)

end

--------------------------------------------------------------------------------

-- Method for adding pending updates, called whenever a pattern which is being
-- monitored has changed and a track requires a copy-expansion. 

function GridPie:_add_pending_update(src_patt_idx,dest_patt_idx,pos)

  if not self.pending_updates[pos.track] then
    self.pending_updates[pos.track] = table.create()
  end
  self.pending_updates[pos.track] = {
    src_patt_idx = src_patt_idx,
    dest_patt_idx = dest_patt_idx,
    pos = pos
  }
  self.display.scheduler:remove_task(self._update_task)
  self._update_task = self.display.scheduler:add_task(
    self, GridPie._apply_pending_updates, 0.25)

end

--------------------------------------------------------------------------------

function GridPie:_apply_pending_updates()
  TRACE("GridPie:_apply_pending_updates()")

  if not self.active then
    return false
  end

  local rns = renoise.song()

  -- go through, and copy-expand those updates
  for track_idx =1, #rns.tracks do
    local v = self.pending_updates[track_idx]
    if v then
      if (v.src_patt_idx == self.gp_patt_idx) then
        local src_patt = rns.patterns[self.gp_patt_idx]
        local dest_patt = rns.patterns[self.gp_patt_idx]
        local num_lines = self.POLY_COUNTER[v.pos.track]
        -- determine the offset (if any)
        local offset = 0
        if (v.pos.line > num_lines) then
          offset = math.floor((v.pos.line-1)/num_lines)*num_lines
        end
        if src_patt and dest_patt then
          self.skip_gp_notifier = true
          self:copy_and_expand(src_patt,dest_patt,track_idx,num_lines,offset)
          self.skip_gp_notifier = false
        end

      else
        -- not the recombination pattern, perform standard copy-expand
        local src_patt = rns.patterns[v.src_patt_idx]
        local dest_patt = rns.patterns[self.gp_patt_idx]
        local num_lines = src_patt.number_of_lines
        if src_patt and dest_patt then
          self.skip_gp_notifier = true
          self:copy_and_expand(src_patt,dest_patt,track_idx)
          self.skip_gp_notifier = false
        end
      end
    end
  end
  
  self.pending_updates = table.create()

end

--------------------------------------------------------------------------------

-- this function will apply the current settings
-- to the page_size_v and page_size_h variables

function GridPie:_set_step_sizes()
  --TRACE("GridPie:_set_step_sizes()")

  self.page_size_v = (self.options.page_size_v.value==self.STEPSIZE_AUTO) and
    self.MATRIX_HEIGHT or self.options.page_size_v.value-1
  
  self.page_size_h = (self.options.page_size_h.value==self.STEPSIZE_AUTO) and
    self.MATRIX_WIDTH or self.options.page_size_h.value-1

end

--------------------------------------------------------------------------------

-- figure out the boundaries

function GridPie:_get_v_limit()
  return math.max(1,#renoise.song().sequencer.pattern_sequence - self.MATRIX_HEIGHT)
end

function GridPie:_get_h_limit()
  return math.max(1,renoise.song().sequencer_track_count - self.MATRIX_WIDTH + 1)
end

--------------------------------------------------------------------------------

-- set the vertical/horizontal position 

function GridPie:set_vertical_pos(idx)
  TRACE("GridPie:set_vertical_pos()",idx)

  if (self.Y_POS~=idx) then
    self.Y_POS = idx
    self.v_update_requested = true
  end

end

function GridPie:set_horizontal_pos(idx)
  TRACE("GridPie:set_horizontal_pos()",idx)

  if (self.X_POS~=idx) then
    self.X_POS = idx
    self.h_update_requested = true
  end

end

--------------------------------------------------------------------------------

-- set a pattern sequence index, quantized to page size

function GridPie:set_vertical_pos_page(seq_idx)
  TRACE("GridPie:set_vertical_pos_page()",seq_idx)

  if (self.options.follow_pos.value ~= self.FOLLOW_OFF) then
    if (self.options.follow_pos.value == self.FOLLOW_TRACK_PATTERN) then
      --local seq_idx = renoise.song().selected_sequence_index
      --self.actual_y = seq_idx
      local page = math.floor((seq_idx-1)/self.page_size_v)
      local new_y = page*self.page_size_v+1
      self:set_vertical_pos(new_y)
    end
    -- hack: prevent track from changing
    self.actual_x = renoise.song().selected_track_index
  end

end

--------------------------------------------------------------------------------

-- update buttons for horizontal/vertical navigation

function GridPie:update_h_buttons()
  TRACE("GridPie:update_h_buttons()")

  local x_pos = self.actual_x or self.X_POS
  if self.mappings.h_next.group_name then
    if (x_pos<self:_get_h_limit()) then
      self._bt_next_track:set(self.palette.button_next_track_on)
    else
      self._bt_next_track:set(self.palette.button_next_track_off)
    end
  end
  if self.mappings.h_prev.group_name then
    if (x_pos>self.page_size_h) then
      self._bt_prev_track:set(self.palette.button_prev_track_on)
    else
      self._bt_prev_track:set(self.palette.button_prev_track_off)
    end
  end

end

function GridPie:update_v_buttons()
  TRACE("GridPie:update_v_buttons()")

  local skip_event = true
  local y_pos = self.actual_y or self.Y_POS

  if self.mappings.v_next.group_name then
    if (y_pos<self:_get_v_limit()) then
      self._bt_next_seq:set(self.palette.button_next_patt_on)
    else
      self._bt_next_seq:set(self.palette.button_next_patt_off)
    end
  end
  if self.mappings.v_prev.group_name then
    if (y_pos>self.page_size_v) then
      self._bt_prev_seq:set(self.palette.button_prev_patt_on)
    else
      self._bt_prev_seq:set(self.palette.button_prev_patt_off)
    end
  end

end

--------------------------------------------------------------------------------

-- update slider for horizontal/vertical navigation

function GridPie:update_v_slider()
  TRACE("GridPie:update_v_slider()")

  if self._v_slider then
    local skip_event = true
    local steps = self:_get_v_limit()
    local idx = math.min(steps,self.Y_POS-1)
    self._v_slider.steps = steps
    self._v_slider:set_index(idx,skip_event)
  end

end

function GridPie:update_h_slider()
  TRACE("GridPie:update_h_slider()")

  if self._h_slider then
    local skip_event = true
    local steps = self:_get_h_limit()
    local idx = math.min(steps,self.X_POS-1)
    self._h_slider.steps = steps
    self._h_slider:set_index(idx,skip_event)
  end

end

--------------------------------------------------------------------------------

-- handle paged navigation

function GridPie:goto_prev_track_page()
  TRACE("GridPie:goto_prev_track_page()")
  local limit = self:_get_h_limit()
  local new_x = math.min(limit,math.max(1,self.X_POS-self.page_size_h))
  self:set_horizontal_pos(new_x)
  self:align_track()
end

function GridPie:goto_next_track_page()
  TRACE("GridPie:goto_next_track_page()")
  if(self.X_POS<self:_get_h_limit()) then
    local new_x = self.X_POS+self.page_size_h
    self:set_horizontal_pos(new_x)
    self:align_track()
  end
end

function GridPie:goto_first_track_page()
  TRACE("GridPie:goto_first_track_page()")
  self:set_horizontal_pos(1)
  self:align_track()
end

function GridPie:goto_last_track_page()
  TRACE("GridPie:goto_last_track_page()")
  local new_x = 1
  local limit = self:_get_h_limit()
  while (new_x<limit) do
    new_x = new_x+self.page_size_h
  end
  self:set_horizontal_pos(new_x)
  self:align_track()
end

function GridPie:goto_next_seq_page()
  TRACE("GridPie:goto_next_seq_page()")
  if(self.Y_POS<self:_get_v_limit()) then
    local new_y = self.Y_POS+self.page_size_v
    self:set_vertical_pos(new_y)
    self:align_pattern()
  end
end

function GridPie:goto_prev_seq_page()
  TRACE("GridPie:goto_prev_seq_page()")
  local limit = 1
  local new_y = math.max(limit,self.Y_POS-self.page_size_v)
  self:set_vertical_pos(new_y)
  self:align_pattern()
end

function GridPie:goto_first_seq_page()
  TRACE("GridPie:goto_first_seq_page()")
  self:set_vertical_pos(1)
  self:align_pattern()
end

function GridPie:goto_last_seq_page()
  TRACE("GridPie:goto_last_seq_page()")
  local new_y = 1
  local limit = self:_get_v_limit()
  while (new_y<limit) do
    new_y = new_y+self.page_size_v
  end
  self:set_vertical_pos(new_y)
  self:align_pattern()
end


--------------------------------------------------------------------------------

-- align selected track/pattern with position

function GridPie:align_track()
  if (self.options.follow_pos.value ~= self.FOLLOW_OFF) then
    renoise.song().selected_track_index = self.X_POS
  end
end

function GridPie:align_pattern()
  if (self.options.follow_pos.value == self.FOLLOW_TRACK_PATTERN) then
    renoise.song().selected_sequence_index = self.Y_POS
  end
end

--------------------------------------------------------------------------------

-- Check if we can perform a "pattern toggle" (mute all tracks)
-- this is only possible when every track is enabled, and located on the 
-- same sequence-index as the pressed button 
-- @return boolean

function GridPie:can_mute_pattern(x,y)
  --TRACE("GridPie:can_mute_pattern()",x,y)

  local rns = renoise.song()

  local patt_idx = nil
  local able_to_toggle = true
  for i = 1,rns.sequencer_track_count do
    if not patt_idx then
      -- first time around, check if the sequence index
      patt_idx = self.active_slots[i]
      if (patt_idx~=y) then
        --print("sequence index doesn't match",patt_idx,y)
        able_to_toggle = false
        break
      end
    else  
      if (patt_idx~=self.active_slots[i]) then
        --print("sequence index not identical",patt_idx,self.active_slots[i])
        able_to_toggle = false
        break
      end
    end
    if not self.POLY_COUNTER[i] then
      --print("missing POLY_COUNTER")
      able_to_toggle = false
      break
    end
  end

  return able_to_toggle

end


--------------------------------------------------------------------------------

-- Is garbage PM position?

function GridPie:is_garbage_pos(x,y)
  --TRACE("GridPie:is_garbage_pos()",x,y)

  -- Garbage position?
  local sequencer = renoise.song().sequencer
  local total_sequence = #sequencer.pattern_sequence

  if
    renoise.song().sequencer.pattern_sequence[y] == nil or
    renoise.song().tracks[x] == nil or
    renoise.song().tracks[x].type == renoise.Track.TRACK_TYPE_MASTER or
    renoise.song().tracks[x].type == renoise.Track.TRACK_TYPE_SEND or
    total_sequence == y
  then
    return true
  else
    return false
  end

end


--------------------------------------------------------------------------------

-- Access a cell in the Grid Pie

function GridPie:matrix_cell(x,y)
  --TRACE("GridPie:matrix_cell()",x,y)

  if (self.MATRIX_CELLS[x] ~= nil) then
    return self.MATRIX_CELLS[x][y]
  end
end


--------------------------------------------------------------------------------

-- Toggle all slot mutes in Pattern Matrix
-- (called when starting and stopping the application)
-- @param val (Boolean) true when starting, false when stopping (restore) 
function GridPie:init_pm_slots_to(val)
  TRACE("GridPie:init_pm_slots_to()",val)

  local rns = renoise.song()
  local tracks = rns.tracks
  local sequencer = rns.sequencer
  local total_tracks = #tracks
  local total_sequence = #sequencer.pattern_sequence

  for x = 1, total_tracks do
    if
      tracks[x].type ~= renoise.Track.TRACK_TYPE_MASTER and
      tracks[x].type ~= renoise.Track.TRACK_TYPE_SEND
    then
      for y = 1, total_sequence do
        if val and rns.sequencer:track_sequence_slot_is_muted(x, y) then
          -- Store original state
          if not self.REVERT_PM_SLOT[x] then
            self.REVERT_PM_SLOT[x] = table.create()
          end
          self.REVERT_PM_SLOT[x][y] = true
        end
        rns.sequencer:set_track_sequence_slot_is_muted(x , y, val)
        if not val and self.REVERT_PM_SLOT ~= nil 
          and self.REVERT_PM_SLOT[x] ~= nil 
          and self.REVERT_PM_SLOT[x][y] ~= nil 
        then
          -- Revert to original state
          rns.sequencer:set_track_sequence_slot_is_muted(x , y, true)
        end
      end
    end
  end

end


--------------------------------------------------------------------------------

-- Initialize Grid Pie Pattern

function GridPie:init_gp_pattern()
  --TRACE("GridPie:init_gp_pattern()")

  local rns = renoise.song()
  local tracks = rns.tracks
  local total_tracks = #tracks
  local sequencer = rns.sequencer
  local total_sequence = #sequencer.pattern_sequence
  local last_pattern = rns.sequencer:pattern(total_sequence)

  -- determine the position we should start from:
  if renoise.song().transport.playing then
    -- if playing, use the playback position
    local playback_pos = renoise.song().transport.playback_pos
    self._cached_playpos = playback_pos.sequence
  else
    -- else, use the currently edited pattern
    self._cached_playpos = renoise.song().selected_sequence_index
  end

  if rns.patterns[last_pattern].name ~= self.GRIDPIE_NAME then
    -- Create new pattern
    local new_pattern = rns.sequencer:insert_new_pattern_at(total_sequence + 1)
    rns.patterns[new_pattern].name = self.GRIDPIE_NAME
    self.gp_patt_idx = new_pattern
    total_sequence = total_sequence + 1
  else
    -- Clear pattern, unmute slot
    rns.patterns[last_pattern]:clear()
    rns.patterns[last_pattern].name = self.GRIDPIE_NAME
    for x = 1, total_tracks do
      rns.sequencer:set_track_sequence_slot_is_muted(x , total_sequence, false)
    end
    self.gp_patt_idx = last_pattern
  end

  -- Cleanup any other pattern named __GRID_PIE__
  for x = 1, total_sequence - 1 do
    local tmp = rns.sequencer:pattern(x)

    if rns.patterns[tmp].name:find(self.GRIDPIE_NAME) ~= nil then
      rns.patterns[tmp].name = ""
    end
  end

  -- Running start: copy contents into pattern
  self:set_vertical_pos_page(self._cached_playpos)
  -- locate vertical position within the grid
  local y_pos = self._cached_playpos-self.Y_POS+1
  self:toggler(1,y_pos,true) 


end


--------------------------------------------------------------------------------

-- Adjust grid

function GridPie:adjust_grid()
  --TRACE("GridPie:adjust_grid()")

  local rns = renoise.song()
  local button_palette = nil
  local master_track_idx = get_master_track_index()
  local seq_idx = renoise.song().selected_sequence_index
  local total_sequence = #rns.sequencer.pattern_sequence

  -- todo: only when inside the visible range 
  local rng_end = self.Y_POS + self.MATRIX_HEIGHT
  local within_range = (seq_idx>=self.Y_POS) and (seq_idx<rng_end)

  -- update the grid buttons 
  for x = self.X_POS, self.MATRIX_WIDTH + self.X_POS - 1 do
    local silent_track = self.POLY_COUNTER[x] and true or false
    for y = self.Y_POS, self.MATRIX_HEIGHT + self.Y_POS - 1 do
      local cell = self:matrix_cell(x - self.X_POS + 1, y - self.Y_POS + 1)
      local current = (y%self.MATRIX_HEIGHT == seq_idx%self.MATRIX_HEIGHT)
      local empty,muted = false,true,true
      local bounds = (current) and 
        self.palette.out_of_bounds_current or self.palette.out_of_bounds
      if (x>=master_track_idx) then
        cell:set(bounds)
      elseif (y>=total_sequence) then
        cell:set(bounds)
      elseif cell ~= nil then
        muted = rns.sequencer:track_sequence_slot_is_muted(x, y)
        local patt_idx = rns.sequencer.pattern_sequence[y]
        empty = rns.patterns[patt_idx].tracks[x].is_empty
        if empty then
          if muted then 
            if within_range and
              (y%self.MATRIX_HEIGHT == seq_idx%self.MATRIX_HEIGHT) then
              cell:set(self.palette.empty_current)
            else
              cell:set(self.palette.empty)
            end
          else 
            cell:set(self.palette.active_empty)
          end
        else
          if muted then 
            if silent_track then
              cell:set(self.palette.filled_silent)
            else
              cell:set(self.palette.filled)
            end
          else 
            cell:set(self.palette.active_filled)
          end
        end
      end

    end
  end

  -- set the selected pattern/track, preferably to the user-specified 
  -- value (the "actual" position), or to the page's top/left corner 
  if (self.options.follow_pos.value ~= self.FOLLOW_OFF) then
    rns.selected_track_index = self.actual_x or self.X_POS
    if (self.options.follow_pos.value == self.FOLLOW_TRACK_PATTERN) then
      rns.selected_sequence_index = self.actual_y or self.Y_POS
    end
    --self.actual_x,self.actual_y = nil,nil

  end

end

--------------------------------------------------------------------------------

function GridPie:clear_track(idx)
  --TRACE("GridPie:clear_track()",idx)

  local rns = renoise.song()
  rns.patterns[self.gp_patt_idx].tracks[idx]:clear()
  self.POLY_COUNTER[idx] = nil
  if (rns.tracks[idx].mute_state==MUTE_STATE_ACTIVE) then
    -- TODO: This is a hackaround, fix when API is updated
    -- See: http://www.renoise.com/board/index.php?showtopic=31927
    rns.tracks[idx].mute_state = MUTE_STATE_OFF
    OneShotIdleNotifier(100, function() 
      rns.tracks[idx].mute_state = renoise.Track.MUTE_STATE_ACTIVE 
    end)
  end

end

--------------------------------------------------------------------------------

function GridPie:clear_tracks()
  --TRACE("GridPie:clear_tracks()")

  local rns = renoise.song()

  for idx=1,rns.sequencer_track_count do
    rns.patterns[self.gp_patt_idx].tracks[idx]:clear()
    self.POLY_COUNTER[idx] = nil
  end
  --if (rns.tracks[idx].mute_state==MUTE_STATE_ACTIVE) then
    for idx=1,rns.sequencer_track_count do
      rns.tracks[idx].mute_state = MUTE_STATE_OFF
    end
    -- TODO: This is a hackaround, fix when API is updated
    -- See: http://www.renoise.com/board/index.php?showtopic=31927
    OneShotIdleNotifier(100, function() 
      for idx=1,rns.sequencer_track_count do
        rns.tracks[idx].mute_state = renoise.Track.MUTE_STATE_ACTIVE 
      end
    end)
  --end

end

--------------------------------------------------------------------------------

-- Copy and expand a track
-- @param src_patt,dest_patt (Pattern), source & destination patterns
-- @param track_idx (Number), the track index
-- @param num_lines (Number), the number of lines to copy before repeating
-- @param offset (Number), the line at which copying should start (source)

function GridPie:copy_and_expand(src_patt,dest_patt,track_idx,num_lines,offset)
  TRACE("GridPie:copy_and_expand()",src_patt,dest_patt,track_idx,num_lines,offset)

  local source_track = src_patt:track(track_idx)
  local dest_track = dest_patt:track(track_idx)

  if num_lines == nil then
    num_lines = src_patt.number_of_lines
  end

  if offset == nil then
    offset = 0
  end

  if dest_patt.number_of_lines <= num_lines then
    return
  end

  -- (optimization) perform direct copy of the track, but only 
  -- if we have not defined an offset and src & dest differ...
  local offset_2 = 0
  if (offset==0) and src_patt ~= dest_patt then
    dest_track:copy_from(source_track)
  end

  local multiplier = math.floor(dest_patt.number_of_lines / num_lines)
  if (offset==0) then
    multiplier = multiplier-1
  end

  local to_line = 1
  local approx_line = 1

  for i=1, num_lines do
    for j=1, multiplier do

      if (offset==0) then
        -- skip the first few lines (already copied)
        to_line = i + num_lines * j
      else
        to_line = (i + num_lines * j) - num_lines
      end
      --local source_line = dest_track:line(i)
      local source_line = source_track:line(i+offset)
      local dest_line = dest_track:line(to_line)

      -- Copy the top of pattern to the expanded lines
      dest_line:copy_from(source_line)

      -- Copy the top of the automations to the expanded lines
      for _,automation in pairs(dest_track.automation) do
        for _,point in pairs(automation.points) do
          approx_line = math.floor(point.time)
          if approx_line == i then
            automation:add_point_at(to_line + point.time - approx_line, point.value)
          elseif approx_line > i then
            break
          end
        end
      end

    end
  end

end


--------------------------------------------------------------------------------

-- Toggler
-- x/y (number), position of pressed button 
-- pattern (boolean), whether to copy entire pattern

function GridPie:toggler(x, y, pattern)
  TRACE("GridPie:toggler()",x, y, pattern)


  x = x + (self.X_POS - 1)
  y = y + (self.Y_POS - 1)

  if self:is_garbage_pos(x, y) then 
    print("could not switch to appointed track/pattern:",x,y,pattern)
    return 
  end
  
  local rns = renoise.song()
  local source = rns.patterns[rns.sequencer:pattern(y)]
  local dest = rns.patterns[self.gp_patt_idx]
  local master_track_idx = get_master_track_index()
  local total_sequence = #rns.sequencer.pattern_sequence

  -- keep the beat: remember this value, so that we can 
  -- modify the play-pos (if necessary after the copy)
  local old_lines = dest.number_of_lines
  local old_pos = renoise.song().transport.playback_pos

  -- temporarily disable line notifier
  self.skip_gp_notifier = true

  if pattern then

    local muteable = self:can_mute_pattern(x,y)
    if muteable then
      -- clear pattern 
      self:clear_tracks()
    else
      -- copy pattern 
      dest:copy_from(source)
      dest.number_of_lines = source.number_of_lines 
    end

    -- Change PM
    for o = 1, rns.sequencer_track_count do

      if not muteable then
        self.POLY_COUNTER[o] = source.number_of_lines 
      end

      if self.active_slots[o] then
        -- change only affected parts
        rns.sequencer:set_track_sequence_slot_is_muted(o , self.active_slots[o], true)
        rns.sequencer:set_track_sequence_slot_is_muted(o , y, muteable)
      else
        -- loop through entire sequence
        for i = 1, #rns.sequencer.pattern_sequence - 1 do
          if (i<total_sequence) then
            if muteable then
              -- everything has just been muted!
              rns.sequencer:set_track_sequence_slot_is_muted(o , i, true)
            else
              if i == y then
                rns.sequencer:set_track_sequence_slot_is_muted(o , i, false)
              else
                rns.sequencer:set_track_sequence_slot_is_muted(o , i, true)
              end
            end

          end
        end

      end

    end

    for o = 1, rns.sequencer_track_count do
      self.active_slots[o] = y
    end

  else

    -- track copy

    local muted = false
    if self.POLY_COUNTER[x] and 
      self.active_slots[x] and 
      (self.active_slots[x] == y) 
    then 
      muted = true 
    end

    if muted then

      self:clear_track(x) -- will update POLY_COUNTER
      local lc = least_common(self.POLY_COUNTER:values())
      dest.number_of_lines = lc

    else

      -- POLY COUNTER may contain gaps, create ordered keys
      self.POLY_COUNTER[x] = source.number_of_lines
      local poly_lines = table.create()
      for _,val in ipairs(self.POLY_COUNTER:values()) do 
        poly_lines[val] = true 
      end
      local poly_num = table.count(poly_lines)
      if poly_num > 1 then
        renoise.app():show_status("Grid Pie " .. poly_num .. "x poly combo!")
      else
        renoise.app():show_status("")
      end

      local lc = least_common(self.POLY_COUNTER:values())
      if self.options.polyrhythms.value == self.POLY_DISABLED or
        lc > renoise.Pattern.MAX_NUMBER_OF_LINES or
        poly_num <= 1 or
        (lc == source.number_of_lines and lc == dest.number_of_lines)
      then

        -- Simple copy
        dest.number_of_lines = source.number_of_lines
        dest.tracks[x]:copy_from(source.tracks[x])

      else

        -- Complex copy
        dest.number_of_lines = lc

        --print("GridPie:Expanding track " .. x .. " from " .. source.number_of_lines .. " to " .. dest.number_of_lines .. " lines")

        self:copy_and_expand(source, dest, x)

        -- other tracks might have been affected by the
        -- changed length, and should be expanded as well...
        if old_lines < dest.number_of_lines then
          for idx=1,#rns.tracks do
            if
              idx ~= x and
              not dest.tracks[idx].is_empty and
              rns.tracks[idx].type ~= renoise.Track.TRACK_TYPE_MASTER and
              rns.tracks[idx].type ~= renoise.Track.TRACK_TYPE_SEND
            then
              TRACE("GridPie:Also expanding track " .. idx .. " from " .. old_lines .. " to " .. dest.number_of_lines .. " lines") 
              self:copy_and_expand(dest, dest, idx, old_lines)
            end
          end

        end

      end

    end

    -- Change PM

    if self.active_slots[x] then
      -- change only affected slots
      rns.sequencer:set_track_sequence_slot_is_muted(x , self.active_slots[x], true)
      rns.sequencer:set_track_sequence_slot_is_muted(x , y, muted)
    else
      -- loop through entire sequence
      for i = 1, #rns.sequencer.pattern_sequence - 1 do
        if (i<total_sequence) then
          if i == y then
            rns.sequencer:set_track_sequence_slot_is_muted(x , i, muted)
          else
            rns.sequencer:set_track_sequence_slot_is_muted(x , i, true)
          end
        end
      end
    end

    self.active_slots[x] = y

  end

  -- Keep the beat
  
  if (old_lines > dest.number_of_lines) then
    -- If the playhead is within the valid range, do nothing
    if (old_pos.line > dest.number_of_lines) then
      -- The playhead jumps back in the pattern by the same amount of lines as we, 
      -- at the moment the length changed, were located from the end of that 
      -- pattern. This should cause us to arrive at line 1 in the same time
      local new_line = (old_pos.line-old_lines) + dest.number_of_lines
      -- If the resulting line difference turned out to be a position before the 
      -- pattern start (a negative value), we go forward in line-increments that 
      -- match the LPB until we reach a positive value
      local lpb = renoise.song().transport.lpb
      while (new_line<0) do
        new_line = new_line+lpb
        -- ensure that the new line fit within new pattern
        -- (will happen when lpb is larger than pattern length)
        if (new_line>dest.number_of_lines) then
          new_line = new_line%dest.number_of_lines
        end
      end
      if (new_line==0) then
        new_line = dest.number_of_lines
      end
      old_pos.line = new_line
      renoise.song().transport.playback_pos = old_pos
    end
  end

  self.update_requested = true

  -- re-enable line notifier
  self.skip_gp_notifier = false

end


--------------------------------------------------------------------------------

-- Build GUI Interface
-- equivalent to build_interface() in the original tool

function GridPie:_build_app()
  TRACE("GridPie:_build_app()")

  -- determine grid size by looking at the control-map
  local cm = self.display.device.control_map
  if (self.mappings.grid.group_name) then
    self.MATRIX_WIDTH = cm:count_columns(self.mappings.grid.group_name)
    self.MATRIX_HEIGHT = cm:count_rows(self.mappings.grid.group_name)
  end

  -- button: vertical, previous 
  if (self.mappings.v_prev.group_name) then
    local c = UIButton(self.display)
    c.group_name = self.mappings.v_prev.group_name
    c.tooltip = self.mappings.v_prev.description
    c:set_pos(self.mappings.v_prev.index)
    c.active = false
    c.on_hold = function()
      if not self.active then return false end
      self:goto_first_seq_page()
    end
    c.on_press = function(obj) 
      if not self.active then return false end
      self:goto_prev_seq_page()
    end
    self:_add_component(c)
    self._bt_prev_seq = c
  end

  -- button: vertical, next 
  if (self.mappings.v_next.group_name) then
    local c = UIButton(self.display)
    c.group_name = self.mappings.v_next.group_name
    c.tooltip = self.mappings.v_next.description
    c:set_pos(self.mappings.v_next.index)
    c.active = false
    c.on_hold = function()
      if not self.active then return false end
      self:goto_last_seq_page()
    end
    c.on_press = function(obj) 
      if not self.active then return false end
      self:goto_next_seq_page()
    end
    self:_add_component(c)
    self._bt_next_seq = c
  end

  -- button: horizontal, previous
  if (self.mappings.h_prev.group_name) then
    local c = UIButton(self.display)
    c.group_name = self.mappings.h_prev.group_name
    c.tooltip = self.mappings.h_prev.description
    c:set_pos(self.mappings.h_prev.index)
    c.active = false
    c.on_hold = function()
      if not self.active then return false end
      self:goto_first_track_page()
    end
    c.on_press = function() 
      if not self.active then return false end
      self:goto_prev_track_page()
    end
    self:_add_component(c)
    self._bt_prev_track = c
  end

  -- button: horizontal, next
  if (self.mappings.h_next.group_name) then
    local c = UIButton(self.display)
    c.group_name = self.mappings.h_next.group_name
    c.tooltip = self.mappings.h_next.description
    c:set_pos(self.mappings.h_next.index)
    c.active = false
    c.on_hold = function()
      if not self.active then return false end
      self:goto_last_track_page()
    end
    c.on_press = function(obj) 
      if not self.active then return false end
      self:goto_next_track_page()
    end
    self:_add_component(c)
    self._bt_next_track = c
  end

  -- grid buttons
  if (self.mappings.grid.group_name) then
    self._buttons = {}
    for x = 1, self.MATRIX_WIDTH do
      self.MATRIX_CELLS[x] = table.create()
      for y = 1, self.MATRIX_HEIGHT do

        local c = UIButton(self.display)
        c.group_name = self.mappings.grid.group_name
        c.tooltip = self.mappings.grid.description
        c:set_pos(x,y)
        c.active = false
        if (self.options.hold_enabled.value == self.HOLD_DISABLED) then
          c.on_press = function(obj) 
            -- track copy
            if not self.active then 
              return false 
            end
            self:toggler(x,y) 
          end
        else
          c.on_release = function(obj) 
            -- track copy
            if not self.active then 
              return false 
            end
            -- if we just copied the pattern,
            -- no trigger when released
            if self.held_button and
              (self.held_button == obj) 
            then
              self.held_button = nil
              return 
            end
            self:toggler(x,y) 
          end
          c.on_hold = function(obj) 
            -- pattern copy
            self.held_button = obj
            if not self.active then 
              return false 
            end
            local pattern = true
            self:toggler(x,y,pattern) 
          end
        end
        self:_add_component(c)
        self.MATRIX_CELLS[x][y] = c
      end
    end
  end

  -- vertical slider
  if (self.mappings.v_slider.group_name) then
    local c = UISlider(self.display)
    c.group_name = self.mappings.v_slider.group_name
    c.tooltip = self.mappings.v_slider.description
    c:set_pos(self.mappings.v_slider.index or 1)
    c.on_change = function(obj) 
      if not self.active then return false end
      local limit = self:_get_v_limit()
      local val = math.min(limit,obj.index+1)
      self:set_vertical_pos(val)
      self:align_pattern()
    end
    self:_add_component(c)
    self._v_slider = c
  end

  -- horizontal slider
  if (self.mappings.h_slider.group_name) then
    local c = UISlider(self.display)
    c.group_name = self.mappings.h_slider.group_name
    c.tooltip = self.mappings.h_slider.description
    c:set_pos(self.mappings.h_slider.index or 1)
    c.on_change = function(obj) 
      if not self.active then return false end
      local limit = self:_get_h_limit()
      local val = math.min(limit,obj.index+1)
      self:set_horizontal_pos(val)
      self:align_track()
    end
    self:_add_component(c)
    self._h_slider = c
  end

  -- final steps
  Application._build_app(self)
  return true

end


--------------------------------------------------------------------------------

-- equivalent to main() in the original tool

function GridPie:start_app()
  TRACE("GridPie:start_app()")

  -- this step will ensure that the application is properly mapped,
  -- after which it will call the build_app() method
  if not Application.start_app(self) then
    return
  end

  self._has_been_started = true

  local rns = renoise.song()

  -- initialize important stuff
  self:reset_tables()
  self:_set_step_sizes() 
  self.POLY_COUNTER = table.create()
  self:init_pm_slots_to(true)
  self:init_gp_pattern()

  -- attach notifiers (after we have init'ed GP pattern!)
  self:_attach_to_song()

  -- update controller
  self:update_v_buttons()
  self:update_v_slider()
  self:update_h_buttons()
  self:update_h_slider()
  --self:adjust_grid()
  self.update_requested = true

  -- determine if we should highlight the current pattern
  if not table_compare(self.palette.empty.color,self.palette.empty_current.color)
    or (self.palette.empty.text ~= self.palette.empty_current.text)
    or (self.palette.empty.val ~= self.palette.empty_current.val)
  then
    self.show_current_pattern = true
  end

  -- adjust the Renoise interface
  renoise.app().window.pattern_matrix_is_visible = true
  rns.transport.follow_player = false
  rns.transport.loop_pattern = true

  -- start playing as soon as we have initialized?
  if (self.options.auto_start.value == self.AUTOSTART_ON) then
    self.play_requested = true
  end

  -- if follow_pos is enabled, display the first pattern,
  -- otherwise display the __GRID PIE__ pattern
  --[[
  if (self.options.follow_pos.value == self.FOLLOW_TRACK_PATTERN) then
    rns.selected_sequence_index = self._cached_playpos
  end
  else
    rns.selected_sequence_index = #rns.sequencer.pattern_sequence
  end
  ]]

end

--------------------------------------------------------------------------------

-- equivalent to stop() in the original tool

function GridPie:stop_app()
  TRACE("GridPie:stop_app()")

  if self._has_been_started then

    local rns = renoise.song()

    -- revert PM
    self:init_pm_slots_to(false)

    -- restore playback position
    if rns.transport.playing then
      if self._cached_playpos and
        (self._cached_playpos < #rns.sequencer.pattern_sequence) 
      then
        local playpos = rns.transport.playback_pos
        playpos.sequence = self._cached_playpos
        rns.transport.playback_pos = playpos
      else
        print("Grid Pie: could not reinstate original sequence position")
      end
    end

    self:_remove_line_notifier()
    local gp_patt = rns.patterns[self.gp_patt_idx]
    if gp_patt and (gp_patt:has_line_notifier(self._track_changes,self)) then
      gp_patt:remove_line_notifier(self._track_changes,self)
    end

  end

  self._has_been_started = false

  Application.stop_app(self)

end


--------------------------------------------------------------------------------

-- Abort (sleep during idle time and ignore any user input)

function GridPie:abort(notification)
  TRACE("GridPie:abort()",notification)

  if not self.active then
    return
  end

  renoise.app():show_status("You dun goofed! Grid Pie needs to be restarted.")
  self._process.browser:stop_current_configuration()

end

--------------------------------------------------------------------------------

-- attach line notifier

function GridPie:_attach_line_notifier()
  TRACE("GridPie:_attach_line_notifier()")

  local rns = renoise.song()
  local patt = rns.patterns[rns.selected_pattern_index]
  if (patt.name == self.GRIDPIE_NAME) then
    --print("Do not attach to the recombination pattern")
    return
  end

  self:_remove_line_notifier()

  -- now attach new notifier
  if not (patt:has_line_notifier(self._track_changes,self))then
    patt:add_line_notifier(self._track_changes,self)
  end

end

--------------------------------------------------------------------------------

-- remove line notifier 

function GridPie:_remove_line_notifier()

  local rns = renoise.song()
  local patt_idx = rns.sequencer.pattern_sequence[self._current_seq_index]
  local patt = rns.patterns[patt_idx]
  -- do not remove from the recombination pattern
  -- (this is only done when stopping the application)
  if patt then
    if (patt.name == self.GRIDPIE_NAME) then
      --print("Do not attach to the recombination pattern")
      return
    end
    if (rns.selected_sequence_index ~= self._current_seq_index) and
      (patt:has_line_notifier(self._track_changes,self)) then
      patt:remove_line_notifier(self._track_changes,self)
    end
  end

end

--------------------------------------------------------------------------------

-- decide if we need to update the recombination/source pattern
-- note: this method might be called hundreds of times when doing edits like
-- cutting all notes from a pattern, so we need it to be really simple

function GridPie:_track_changes(pos)
  --TRACE("GridPie:_track_changes()",pos)

  local rns = renoise.song()

  -- determine if we have changed the recombination or source pattern
  local source_changed = (pos.pattern ~= self.gp_patt_idx)
  --print("GridPie:_track_changes - source_changed",source_changed)

  if not source_changed then
    -- change happened in recombination pattern

    if self.skip_gp_notifier then
      --print("GridPie:_track_changes - bypassed line notifier")
      return
    end

    -- we need a source before we can update anything!
    if not self.POLY_COUNTER[pos.track] then
      rns:show_status("Grid Pie: cannot synchronize changes, unspecified source track...")
      return
    else
      -- perform 'simple' copy back to source track
      local source_patt = rns.patterns[self.gp_patt_idx]
      local dest_seq_idx = self.active_slots[pos.track]
      local dest_patt_idx = rns.sequencer.pattern_sequence[dest_seq_idx]
      local dest_patt = rns.patterns[dest_patt_idx]
      if source_patt and dest_patt then
        dest_patt.tracks[pos.track]:copy_from(source_patt.tracks[pos.track])
      end
      -- if recombination pattern has different length, 
      -- copy and expand changes onto itself...
      -- TODO check if pattern is completely empty (simple copy then)
      if (source_patt.number_of_lines ~= self.POLY_COUNTER[pos.track]) then
        self:_add_pending_update(self.gp_patt_idx,self.gp_patt_idx,pos)
      end

    end

  else
    -- change happened in source pattern
    local source_patt = rns.patterns[pos.pattern]

    -- check if the source pattern-track is grid-pie'd 
    if self.POLY_COUNTER[pos.track] and
      (self.active_slots[pos.track] == pos.pattern)
    then
      local dest_patt = rns.patterns[self.gp_patt_idx]
      if source_patt and 
        (source_patt.number_of_lines == dest_patt.number_of_lines) 
      then
        -- perform 'simple' copy to recombination pattern
        -- TODO check if pattern is completely empty (simple copy then)
        self.skip_gp_notifier = true
        dest_patt.tracks[pos.track]:copy_from(source_patt.tracks[pos.track])
        self.skip_gp_notifier = false
      else
        self:_add_pending_update(pos.pattern,self.gp_patt_idx,pos)
      end
    else
      --print("ignore change to this pattern-track")
      return
    end


  end



end

--------------------------------------------------------------------------------

-- Handle document change 
-- document_changed() in original tool

function GridPie:on_new_document(song)
  TRACE("GridPie:on_new_document()",song)

  self:_attach_to_song()
  self:abort()

end

--------------------------------------------------------------------------------

-- idler() in original tool

function GridPie:on_idle()

  if not self.active then
    return
  end

  local rns = renoise.song()
  local last_pattern = rns.sequencer:pattern(#rns.sequencer.pattern_sequence)
  if renoise.song().patterns[last_pattern].name ~= self.GRIDPIE_NAME then
    self:abort()
  end

  if self.v_update_requested then
    self.v_update_requested = false
    self.update_requested = true
    self:update_v_buttons()
    self:update_v_slider()
  end

  if self.h_update_requested then
    self.h_update_requested = false
    self.update_requested = true
    self:update_h_buttons()
    self:update_h_slider()
  end

  if self.update_requested then
    self.update_requested = false
    self:adjust_grid()
  end

  local grid_pie_pos = #rns.sequencer.pattern_sequence
  if (renoise.song().transport.playback_pos.sequence~=grid_pie_pos) then
    self:playback_pos_to_gridpie()
  end

  if self.play_requested then
    self.play_requested = false
    renoise.song().transport.playing = true
  end

  -- determine streaming mode
  -- (1) edit-mode is enabled
  -- (2) we are playing
  --[[
  if renoise.song().transport.playing and
    renoise.song().transport.edit_mode
  then
    print("GridPie: streaming mode...")
  end
  ]]

end

--------------------------------------------------------------------------------

-- determine if edit-position is inside the __GRID PIE__ pattern
-- @return boolean

function GridPie:edit_pos_in_gridpie()

  local rns = renoise.song()
  local total_sequence = #rns.sequencer.pattern_sequence
  local last_patt_idx = rns.sequencer:pattern(total_sequence)
  local rslt = (last_patt_idx == rns.selected_pattern_index) 
  return rslt

end

--------------------------------------------------------------------------------

-- move playback position to the __GRID PIE__ pattern
-- @param restart (Boolean) force pattern to play from the beginning

function GridPie:playback_pos_to_gridpie(restart)
  --TRACE("GridPie:playback_pos_to_gridpie()",restart)

  local rns = renoise.song()
  local total_sequence = #rns.sequencer.pattern_sequence
  local last_patt_idx = rns.sequencer:pattern(total_sequence)
  local last_patt = rns.patterns[last_patt_idx]
  local songpos = rns.transport.playback_pos
  songpos.sequence = total_sequence
  if songpos.line > last_patt.number_of_lines then
    -- todo: keep the beat
    songpos.line = last_patt.number_of_lines 
  end
  if restart and (songpos.sequence~=total_sequence) then
    -- when started outside the __GRID PIE__ pattern, play
    -- from the last line (so the next one is the first)
    songpos.line = last_patt.number_of_lines 
  end
  renoise.song().transport.playback_pos = songpos

end

--------------------------------------------------------------------------------

-- stuff that deal with the sequencer order:
-- (reset when tracks and patterns are added to the song)
--
-- TODO: maintain the data by supporting insert/remove for pattern/track

function GridPie:reset_tables()
  self.REVERT_PM_SLOT = table.create()
  self.active_slots = table.create()
end

--------------------------------------------------------------------------------

-- Bootsauce
-- equivalent to run() in original tool,
-- notification (tracks_changed,sequence_changed) are assigned anonymously

function GridPie:_attach_to_song()
  TRACE("GridPie:_attach_to_song()")

  local rns = renoise.song()

  -- Tracks have changed, stored slots are invalid, reset table
  rns.tracks_observable:add_notifier(
    function(notification)
      TRACE("GridPie:tracks_observable fired...",notification)
      if not self.active then 
        return 
      end
      self:reset_tables()
      -- mute newly inserted slots
      if (notification.type == "insert") then
        -- TODO: This is a hackaround, fix when API is updated
        -- See: http://www.renoise.com/board/index.php?showtopic=31893
        OneShotIdleNotifier(100, function()
          for i = 1, #renoise.song().sequencer.pattern_sequence - 1 do
            renoise.song().sequencer:set_track_sequence_slot_is_muted(notification.index , i, true)
          end
        end)
      end
      self.h_update_requested = true
    end
  )

  -- Sequence have changed
  rns.sequencer.pattern_sequence_observable:add_notifier(
    function(notification)
      TRACE("GridPie:pattern_sequence_observable fired...",notification)
      if not self.active then 
        return 
      end
      if (notification.type == "remove") then
        -- remove a specific sequence index
        local seq_len = #renoise.song().sequencer.pattern_sequence
        for x,_ in ipairs(self.REVERT_PM_SLOT) do
          for y=notification.index,seq_len do
            if (y == notification.index) then
              self.REVERT_PM_SLOT[x][y] = nil
            else
              self.REVERT_PM_SLOT[x][y-1] = self.REVERT_PM_SLOT[x][y]
              if not self.REVERT_PM_SLOT[x][y+1] then
                self.REVERT_PM_SLOT[x][y] = nil
              end
            end
          end
        end
      elseif (notification.type == "insert") then
        -- insert a pattern into the sequence 
        local seq_len = #renoise.song().sequencer.pattern_sequence
        for x,_ in ripairs(self.REVERT_PM_SLOT) do
          for y=seq_len,notification.index,-1 do
            self.REVERT_PM_SLOT[x][y+1] = self.REVERT_PM_SLOT[x][y]
            if (y == notification.index) then
              self.REVERT_PM_SLOT[x][y] = nil
            end
          end
        end
      end
      --self:reset_tables()
      --rprint(self.REVERT_PM_SLOT)
      self.v_update_requested = true
    end
  )

  -- when playback start, force playback to enter __GRID PIE__ pattern
  rns.transport.playing_observable:add_notifier(
    function()
      TRACE("GridPie:playing_observable fired...")
      if not self.active then return end
      if renoise.song().transport.playing then
        self:playback_pos_to_gridpie(true)
      end
    end
  )

  -- when changing track, update horizontal page
  rns.selected_track_index_observable:add_notifier(
    function()
      TRACE("GridPie:selected_track_index_observable fired...")
      if not self.active then return end
      if (self.options.follow_pos.value ~= self.FOLLOW_OFF) then
        local track_idx = renoise.song().selected_track_index
        self.actual_x = track_idx
        local page = math.floor((track_idx-1)/self.page_size_h)
        local new_x = page*self.page_size_h+1
        self:set_horizontal_pos(new_x)
        if (self.options.follow_pos.value ~= self.FOLLOW_TRACK_PATTERN) then
          -- hack: prevent track from changing
          --self.actual_y = renoise.song().selected_sequence_index
          --print("actual_y A",self.actual_y)
        end
      end
    end
  )

  -- when changing pattern in the sequence
  rns.selected_sequence_index_observable:add_notifier(
    function()
      TRACE("GridPie:selected_sequence_index_observable fired...")
      
      if not self.active then 
        return 
      end

      local rns = renoise.song()

      -- update vertical page
      local seq_idx = rns.selected_sequence_index
      self:set_vertical_pos_page(seq_idx)

      if (self.options.follow_pos.value == self.FOLLOW_TRACK_PATTERN) then
        self.actual_y = seq_idx
      end

      -- disable "follow_player" ? 
      if rns.transport.follow_player and
        (self.options.follow_pos.value ~= self.FOLLOW_OFF) and
        not self:edit_pos_in_gridpie()
      then
        rns.transport.follow_player = false
      end

      -- update the current pattern display?
      if self.show_current_pattern then
        self.update_requested = true
      end

      -- attach line notifier
      self:_attach_line_notifier()
      self._current_seq_index = rns.selected_sequence_index

    end
  )

  -- attach line notifier for the current pattern
  self:_attach_line_notifier()

  -- attach line notifier to the recombination pattern
  -- !! we need to have created the pattern before calling this!!
  local gp_patt = rns.patterns[self.gp_patt_idx]
  gp_patt:add_line_notifier(self._track_changes,self)


end


--------------------------------------------------------------------------------
-- OneShotIdle Class
--------------------------------------------------------------------------------

-- delay a function call by the given amount of time into a tools idle notifier
--
-- for example: ´OneShotIdleNotifier(100, my_callback, some_arg, another_arg)´
-- calls "my_callback" with the given arguments with a delay of about 100 ms
-- a delay of 0 will call the callback "as soon as possible" in idle, but never
-- immediately

class "OneShotIdleNotifier"

function OneShotIdleNotifier:__init(delay_in_ms, callback, ...)
  assert(type(delay_in_ms) == "number" and delay_in_ms >= 0.0)
  assert(type(callback) == "function")

  self._callback = callback
  self._args = arg
  self._invoke_time = os.clock() + delay_in_ms / 1000

  renoise.tool().app_idle_observable:add_notifier(self, self.__on_idle)
end

function OneShotIdleNotifier:__on_idle()
  if (os.clock() >= self._invoke_time) then
    renoise.tool().app_idle_observable:remove_notifier(self, self.__on_idle)
    self._callback(unpack(self._args))
  end
end

