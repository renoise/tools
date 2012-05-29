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
  measure     - specify the time signature (for keeping the beat)
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
  --[[
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
  ]]
  measure = {
    label = "Beat measures",
    description = "Set this to the time signature of your song - it affects how"
                .."\nthe 'beat-keeping' feature will work. It is likely"
                .."\nthat you will use 'Four', as most music is in 4/4",
    items = {
      "One", "Two", "Three", "Four","Five","Six","Seven","Eight"
    },
    value = 4,
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

--- initialize the GridPie application

function GridPie:__init(process,mappings,options,cfg_name,palette)
  TRACE("GridPie:__init(",process,mappings,options,cfg_name,palette)

  -- option constants
  --self.POLY_ENABLED = 1
  --self.POLY_DISABLED = 2
  self.FOLLOW_OFF = 1
  self.FOLLOW_TRACK = 2
  self.FOLLOW_TRACK_PATTERN = 3
  self.STEPSIZE_AUTO = 1
  self.AUTOSTART_ON = 1
  self.AUTOSTART_OFF = 2
  self.HOLD_ENABLED = 1
  self.HOLD_DISABLED = 2

  self.GRIDPIE_NAME = "__GRID PIE__"

  -- width/height of the "grid" control-map group
  self.MATRIX_HEIGHT = 0
  self.MATRIX_WIDTH = 0

  -- references to the grid's buttons
  self.MATRIX_CELLS = table.create()

  -- sequence index/name of recombination pattern
  self.gridpie_patt_idx = nil

  -- true when we shouldn't listen for changes to the 
  -- recombination pattern (when copying pattern data)
  self.skip_gp_notifier = false

  -- list of pattern indices aliased within recombination pattern 
  self.aliased_patterns = table.create()

  -- remember length (pattern-lines) of each track
  self.poly_counter = table.create()

  -- memorized state of the matrix 
  self.revert_pm_slot = table.create()

  -- these indicate the upper-left corner of the area
  -- currently displayed on the controller
  self.x_pos = 1 
  self.y_pos = 1

  -- remember the slot sequence indices, set by toggler()
  -- (this is set, no matter if the track is active or not,
  -- check the poly_counter to see if the track is active) 
  self.active_slots = table.create()

  -- remember the number of sequencer tracks, so we can
  -- tell when tracks have been removed or inserted 
  -- before the tracks_observable is invoked
  self._track_count = nil

  -- the pattern cache: a table with this structure
  -- [patt_idx] = {
  --  [track_idx] = {
  --   cached_length (Number)
  --  }
  -- }
  self.patt_cache = table.create()

  -- the total lines in the pattern cache (1-512)
  --self.patt_cache_lines = nil

  -- track which grid buttons that are empty
  -- (two-dimensional array, set in adjust_grid)
  self.matrix_is_empty = table.create()

  -- when we have edited content that needs copy-expansion:
  -- [track_index] = {
  --   src_patt_idx
  --   dest_patt_idx 
  --   pos 
  --  }
  self.pending_updates = table.create()

  -- (Scheduler) this is the tasks which is created when
  -- we use the matrix to toggle slot state
  self._toggle_tasks = table.create()

  -- (Scheduler) this is the task which is created when
  -- we change something which require a delayed update
  self._update_task = nil

  -- boolean, true when button has been held
  self.held_button = nil

  -- boolean, true will ignore changes to slot mute state
  self._skip_mute_notifier = false

  -- boolean, true when we should *not* perform the
  -- scheduled toggle tasks
  self._clear_toggle_tasks = false

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

  -- pattern seq. index from when we started, and the 
  -- "aligned" song position (nil when all active tracks
  -- aren't aligned to the same sequence pos)
  self._aligned_playpos = nil

  -- internal value for keeping track of playback 
  -- progress through the pattern sequence...
  self._playing_seq_idx = nil

  -- true once application has been initialized
  self._has_been_started = false

  -- various flags used by idle loop
  self.play_requested = false
  self.update_requested = false
  self.v_update_requested = false
  self.h_update_requested = false

  -- keep reference to process, so we stop/abort the application
  self._process = process

  -- observable tables
  self._song_observables = table.create()
  self._pattern_observables = table.create()

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
    empty_current           = { color={0x00,0x40,0x00}, text="·", val=false },
    active_filled           = { color={0xFF,0xFF,0x00}, text="·", val=true  },
    active_empty            = { color={0xFF,0x80,0x00}, text="·", val=true  },
    filled                  = { color={0x40,0x00,0x00}, text="·", val=false },
    filled_silent           = { color={0x80,0x40,0x00}, text="·", val=false },
    out_of_bounds           = { color={0x40,0x40,0x00}, text="·", val=false },  
    out_of_bounds_current   = { color={0x40,0x80,0x00}, text="·", val=false },  
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

--- Method for adding pending updates, called whenever a pattern which is being
-- monitored has changed and a track requires a copy-expansion. 
-- @param src_patt_idx (Number) source pattern index
-- @param dest_patt_idx (Number) destination pattern index
-- @param pos (Table) pos.pattern, pos.track, pos.line

function GridPie:_add_pending_update(src_patt_idx,dest_patt_idx,pos)
  TRACE("GridPie:_add_pending_update()",src_patt_idx,dest_patt_idx,pos)
  if not self.pending_updates[pos.track] then
    self.pending_updates[pos.track] = table.create()
  end
  self.pending_updates[pos.track] = {
    src_patt_idx = src_patt_idx,
    dest_patt_idx = dest_patt_idx,
    track = pos.track,
    pattern = pos.pattern,
    line = pos.line
  }
  self.display.scheduler:remove_task(self._update_task)
  self._update_task = self.display.scheduler:add_task(
    self, GridPie._apply_pending_updates, 0.25)

end

--------------------------------------------------------------------------------

--- Copy/expand tracks once the scheduled updates have timed out

function GridPie:_apply_pending_updates()
  TRACE("GridPie:_apply_pending_updates()")

  if not self.active then
    return false
  end

  --rprint(self.pending_updates)

  local rns = renoise.song()

  -- process those updates
  for track_idx =1, rns.sequencer_track_count do
    local v = self.pending_updates[track_idx]
    if v then
      if (v.src_patt_idx == self.gridpie_patt_idx) then
        -- copy from recombination pattern
        local src_patt = rns.patterns[self.gridpie_patt_idx]
        local dest_patt = rns.patterns[v.dest_patt_idx]
        local num_lines = self.poly_counter[v.track]
        local alias_patt = self:resolve_patt_idx(self.gridpie_patt_idx,v.track)
        local cached_lines = self:get_pattern_cache(alias_patt,v.track)
        local lines_total = cached_lines and 
          math.max(src_patt.number_of_lines,cached_lines) or 
          src_patt.number_of_lines
        -- determine the offset (if any)
        local offset = 0
        if (v.line > num_lines) then
          offset = math.floor((v.line-1)/num_lines)*num_lines
        end
        if src_patt and dest_patt then
          self.skip_gp_notifier = true
          self:copy_and_expand(src_patt,dest_patt,track_idx,num_lines,offset,lines_total)
          local cached_patt_idx = self:resolve_patt_idx(v.dest_patt_idx,track_idx)
          self:set_pattern_cache(cached_patt_idx,track_idx,lines_total)
          self.skip_gp_notifier = false
        end

      else
        -- not the recombination pattern, perform standard copy-expand
        --print("perform standard copy-expand",v.src_patt_idx,self.gridpie_patt_idx)
        local src_patt = rns.patterns[v.src_patt_idx]
        local dest_patt = rns.patterns[self.gridpie_patt_idx]
        local num_lines = src_patt.number_of_lines
        if src_patt and dest_patt then
          self.skip_gp_notifier = true
          self:copy_and_expand(src_patt,dest_patt,track_idx)
          local cached_patt_idx = self:resolve_patt_idx(v.src_patt_idx,track_idx)
          self:set_pattern_cache(cached_patt_idx,track_idx,dest_patt.number_of_lines)
          self.skip_gp_notifier = false
        end
      end
    end
  end
  
  self.pending_updates = table.create()

end

--------------------------------------------------------------------------------

--- Go through a specific pattern (src_patt_idx) and create alias-pattern 
-- (dest_patt_idx) containing aliases (used when toggling a whole pattern)
-- @param src_patt_idx (Number)
-- @param dest_patt_idx (Number)

function GridPie:_alias_pattern(src_patt_idx,dest_patt_idx)
  TRACE("GridPie:_alias_pattern()",src_patt_idx,dest_patt_idx)

  local rns = renoise.song()
  --local src_patt = rns.patterns[src_patt_idx]
  local dest_patt = rns.patterns[dest_patt_idx]

  for track_idx = 1,rns.sequencer_track_count do

    local alias_patt_idx = self:resolve_patt_idx(src_patt_idx,track_idx)
    dest_patt.tracks[track_idx].alias_pattern_index = alias_patt_idx

  end

end

--------------------------------------------------------------------------------

--- Create "alias pattern" (a pattern containing aliases and mute states)
-- 1. create aliases for the provided pattern, based on the active slots
-- 2. apply the current mixer mute state as matrix slot mutes
-- @param seq_idx (Number) the sequence index

function GridPie:_create_alias_pattern(seq_idx)
  TRACE("GridPie:_create_alias_pattern()",seq_idx)
  
  local rns = renoise.song()
  local patt_idx = rns.sequencer:pattern(seq_idx)
  local patt = rns.patterns[patt_idx]
  if not patt then
    --print("GridPie:_alias_pattern() - could not locate pattern")
    return 
  end

  for track_idx,ptrack in ipairs(patt.tracks) do
    if not ptrack.is_alias then
      local grid_slot_idx = self.active_slots[track_idx]
      if grid_slot_idx then
        local patt_idx = rns.sequencer.pattern_sequence[grid_slot_idx]
        ptrack.alias_pattern_index = patt_idx
      end
    end

    local track = rns.tracks[track_idx]
    local muted = (track.mute_state ~= MUTE_STATE_ACTIVE)
    self._skip_mute_notifier = true
    rns.sequencer:set_track_sequence_slot_is_muted(
      track_idx,seq_idx,muted)
    --print("track_idx,seq_idx,muted",track_idx,seq_idx,muted)
    self._skip_mute_notifier = false
  end

end

--------------------------------------------------------------------------------

--- Set one of the recombination pattern-tracks as aliased
-- (and attach a line notifier if not already present)

function GridPie:set_aliased_pattern(track_idx,alias_patt_idx)
  TRACE("GridPie:set_aliased_pattern()",track_idx,alias_patt_idx)

  local rns = renoise.song()
  local patt_track = rns.patterns[self.gridpie_patt_idx].tracks[track_idx]
  local alias_patt_track = rns.patterns[alias_patt_idx].tracks[track_idx]
  -- if the alias pattern is in itself an alias:
  if alias_patt_track.is_alias then
    alias_patt_idx = alias_patt_track.alias_pattern_index
  end
  local aliased_patt = rns.patterns[alias_patt_idx]
  --if not patt_track.is_alias then
    patt_track.alias_pattern_index = alias_patt_idx
  --end
  if aliased_patt and not (aliased_patt:has_line_notifier(self._track_changes,self)) then
    aliased_patt:add_line_notifier(self._track_changes,self)
    --print("GridPie:set_aliased_pattern() - add line notifier...")
    self.aliased_patterns:insert(aliased_patt)
  end
end

--------------------------------------------------------------------------------

--- Update the internal pattern cache
-- @param patt_idx (Number), the pattern index
-- @param track_idx (Number), the track index (0 to copy all tracks in pattern)
-- @param num_lines (Number), amount of lines or nil to clear

function GridPie:set_pattern_cache(patt_idx,track_idx,num_lines)
  TRACE("GridPie:set_pattern_cache()",patt_idx,track_idx,num_lines)

  local rns = renoise.song()

  if not self.patt_cache[patt_idx] then
    self.patt_cache[patt_idx] = table.create()
  end

  if not num_lines then
    -- clear this entry
    self.patt_cache[patt_idx][track_idx] = nil
  elseif (track_idx==0) then
    -- copy all tracks: call once for each track...
    for track_idx = 1,rns.sequencer_track_count do
      self:set_pattern_cache(patt_idx,track_idx,num_lines)
    end
  elseif self.patt_cache[patt_idx][track_idx] and
      (num_lines > self.patt_cache[patt_idx][track_idx]) then
    -- only set value if longer than the existing one
    self.patt_cache[patt_idx][track_idx] = num_lines
  else
    self.patt_cache[patt_idx][track_idx] = num_lines
  end

  --rprint(self.patt_cache)

end

--------------------------------------------------------------------------------

--- Retrieve value from internal pattern cache
-- @param patt_idx (Number), the pattern index
-- @param track_idx (Number), the track index 
-- @return (Number or nil), amount of lines with valid data 

function GridPie:get_pattern_cache(patt_idx,track_idx)
  TRACE("GridPie:get_pattern_cache()",patt_idx,track_idx)

  if self.patt_cache[patt_idx] then
    local rslt = self.patt_cache[patt_idx][track_idx] 
    return rslt
  end

  return nil
  
end

--------------------------------------------------------------------------------

--- Apply the current settings to page_size_v and page_size_h variables

function GridPie:_set_step_sizes()
  --TRACE("GridPie:_set_step_sizes()")

  self.page_size_v = (self.options.page_size_v.value==self.STEPSIZE_AUTO) and
    self.MATRIX_HEIGHT or self.options.page_size_v.value-1
  
  self.page_size_h = (self.options.page_size_h.value==self.STEPSIZE_AUTO) and
    self.MATRIX_WIDTH or self.options.page_size_h.value-1

end

--------------------------------------------------------------------------------

--- Figure out the upper boundary

function GridPie:_get_v_limit()
  local rns = renoise.song()
  return math.max(1,#rns.sequencer.pattern_sequence - self.MATRIX_HEIGHT)
end

--- Figure out the lower boundary

function GridPie:_get_h_limit()
  local rns = renoise.song()
  return math.max(1,rns.sequencer_track_count - self.MATRIX_WIDTH + 1)
end

--------------------------------------------------------------------------------

--- set the vertical position of the grid

function GridPie:set_vertical_pos(idx)
  TRACE("GridPie:set_vertical_pos()",idx)

  if (self.y_pos~=idx) then
    self.y_pos = idx
    self.v_update_requested = true
  end

end

--- set the horizontal position of the grid

function GridPie:set_horizontal_pos(idx)
  TRACE("GridPie:set_horizontal_pos()",idx)

  if (self.x_pos~=idx) then
    self.x_pos = idx
    self.h_update_requested = true
  end

end

--------------------------------------------------------------------------------

--- set a pattern sequence index, quantized to page size

function GridPie:set_vertical_pos_page(seq_idx)
  TRACE("GridPie:set_vertical_pos_page()",seq_idx)

  if (self.options.follow_pos.value ~= self.FOLLOW_OFF) then
    if (self.options.follow_pos.value == self.FOLLOW_TRACK_PATTERN) then
      local page = math.floor((seq_idx-1)/self.page_size_v)
      local new_y = page*self.page_size_v+1
      self:set_vertical_pos(new_y)
    end
    -- hack: prevent track from changing
    if self.actual_x then
      self.actual_x = renoise.song().selected_track_index
    end
  end

end

--------------------------------------------------------------------------------

--- update buttons for horizontal navigation

function GridPie:update_h_buttons()
  TRACE("GridPie:update_h_buttons()")

  local x_pos = self.actual_x or self.x_pos
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

--- update buttons for vertical navigation

function GridPie:update_v_buttons()
  TRACE("GridPie:update_v_buttons()")

  local skip_event = true
  local y_pos = self.actual_y or self.y_pos

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

--- update slider for horizontal/vertical navigation

function GridPie:update_v_slider()
  TRACE("GridPie:update_v_slider()")

  if self._v_slider then
    local skip_event = true
    local steps = self:_get_v_limit()
    local idx = math.min(steps,self.y_pos-1)
    self._v_slider.steps = steps
    self._v_slider:set_index(idx,skip_event)
  end

end

function GridPie:update_h_slider()
  TRACE("GridPie:update_h_slider()")

  if self._h_slider then
    local skip_event = true
    local steps = self:_get_h_limit()
    local idx = math.min(steps,self.x_pos-1)
    self._h_slider.steps = steps
    self._h_slider:set_index(idx,skip_event)
  end

end

--------------------------------------------------------------------------------

--- go to previous track-page

function GridPie:goto_prev_track_page()
  TRACE("GridPie:goto_prev_track_page()")
  local limit = self:_get_h_limit()
  local new_x = math.min(limit,math.max(1,self.x_pos-self.page_size_h))
  self:set_horizontal_pos(new_x)
  self:align_track()
end

--- go to next track-page

function GridPie:goto_next_track_page()
  TRACE("GridPie:goto_next_track_page()")
  if(self.x_pos<self:_get_h_limit()) then
    local new_x = self.x_pos+self.page_size_h
    self:set_horizontal_pos(new_x)
    self:align_track()
  end
end

--- go to first track-page

function GridPie:goto_first_track_page()
  TRACE("GridPie:goto_first_track_page()")
  self:set_horizontal_pos(1)
  self:align_track()
end

--- go to last track-page

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

--- go to next sequence-page

function GridPie:goto_next_seq_page()
  TRACE("GridPie:goto_next_seq_page()")
  if(self.y_pos<self:_get_v_limit()) then
    local new_y = self.y_pos+self.page_size_v
    self:set_vertical_pos(new_y)
    self:align_pattern()
  end
end

--- go to previous sequence-page

function GridPie:goto_prev_seq_page()
  TRACE("GridPie:goto_prev_seq_page()")
  local limit = 1
  local new_y = math.max(limit,self.y_pos-self.page_size_v)
  self:set_vertical_pos(new_y)
  self:align_pattern()
end

--- go to first sequence-page

function GridPie:goto_first_seq_page()
  TRACE("GridPie:goto_first_seq_page()")
  self:set_vertical_pos(1)
  self:align_pattern()
end

--- go to last sequence-page

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

-- align selected track with current grid-pie position

function GridPie:align_track()
  if (self.options.follow_pos.value ~= self.FOLLOW_OFF) then
    renoise.song().selected_track_index = self.x_pos
  end
end

-- align selected pattern with current grid-pie position

function GridPie:align_pattern()
  if (self.options.follow_pos.value == self.FOLLOW_TRACK_PATTERN) then
    renoise.song().selected_sequence_index = self.y_pos
  end
end

--------------------------------------------------------------------------------

--- Check if we can perform a "pattern toggle" (mute all tracks)
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
    if not self.poly_counter[i] then
      --print("missing poly_counter")
      able_to_toggle = false
      break
    end
  end

  return able_to_toggle

end


--------------------------------------------------------------------------------

--- Is garbage PM position?

function GridPie:is_garbage_pos(x,y)
  --TRACE("GridPie:is_garbage_pos()",x,y)

  local rns = renoise.song()
  local total_sequence = #rns.sequencer.pattern_sequence

  if
    rns.sequencer.pattern_sequence[y] == nil or
    rns.tracks[x] == nil or
    rns.tracks[x].type == renoise.Track.TRACK_TYPE_MASTER or
    rns.tracks[x].type == renoise.Track.TRACK_TYPE_SEND or
    total_sequence == y
  then
    return true
  else
    return false
  end

end


--------------------------------------------------------------------------------

--- Access a cell in the Grid Pie

function GridPie:matrix_cell(x,y)
  --TRACE("GridPie:matrix_cell()",x,y)

  if (self.MATRIX_CELLS[x] ~= nil) then
    return self.MATRIX_CELLS[x][y]
  end
end


--------------------------------------------------------------------------------

--- Toggle all slot mutes in Pattern Matrix
-- (called when starting and stopping the application)
-- @param val (Boolean) true when starting, false when stopping (restore) 
function GridPie:init_pm_slots_to(val)
  TRACE("GridPie:init_pm_slots_to()",val)

  local rns = renoise.song()
  local sequencer = rns.sequencer
  local total_sequence = #sequencer.pattern_sequence

  self._skip_mute_notifier = true

  for x = 1, rns.sequencer_track_count do
    for y = 1, total_sequence do
      if val and rns.sequencer:track_sequence_slot_is_muted(x, y) then
        -- Store original state
        if not self.revert_pm_slot[x] then
          self.revert_pm_slot[x] = table.create()
        end
        self.revert_pm_slot[x][y] = true
      end
      rns.sequencer:set_track_sequence_slot_is_muted(x , y, val)
      if not val and self.revert_pm_slot ~= nil 
        and self.revert_pm_slot[x] ~= nil 
        and self.revert_pm_slot[x][y] ~= nil 
      then
        -- Revert to original state
        rns.sequencer:set_track_sequence_slot_is_muted(x , y, true)
      end
    end
  end

  self._skip_mute_notifier = false

end


--------------------------------------------------------------------------------

--- Initialize Grid Pie Pattern

function GridPie:init_gp_pattern()
  TRACE("GridPie:init_gp_pattern()")

  local rns = renoise.song()
  local sequencer = rns.sequencer
  local total_sequence = #sequencer.pattern_sequence
  local last_pattern = rns.sequencer:pattern(total_sequence)

  -- determine the position we should start from:
  if rns.transport.playing then
    -- if playing, use the playback position
    local playback_pos = rns.transport.playback_pos
    self._aligned_playpos = playback_pos.sequence
  else
    -- else, use the currently edited pattern
    self._aligned_playpos = rns.selected_sequence_index
  end

  if rns.patterns[last_pattern].name ~= self.GRIDPIE_NAME then
    -- Create new pattern
    local new_pattern = rns.sequencer:insert_new_pattern_at(total_sequence + 1)
    rns.patterns[new_pattern].name = self.GRIDPIE_NAME
    self.gridpie_patt_idx = new_pattern
    total_sequence = total_sequence + 1
  else
    -- Clear pattern, unmute slot
    rns.patterns[last_pattern]:clear()
    rns.patterns[last_pattern].name = self.GRIDPIE_NAME
    self._skip_mute_notifier = true
    for x = 1, rns.sequencer_track_count do
      rns.sequencer:set_track_sequence_slot_is_muted(x , total_sequence, false)
    end
    self._skip_mute_notifier = false
    self.gridpie_patt_idx = last_pattern
  end

  -- Cleanup any other pattern named __GRID_PIE__
  for x = 1, total_sequence - 1 do
    local tmp = rns.sequencer:pattern(x)
    if rns.patterns[tmp].name:find(self.GRIDPIE_NAME) ~= nil then
      rns.patterns[tmp].name = ""
    end
  end

  -- Running start: copy contents into pattern
  self:set_vertical_pos_page(self._aligned_playpos)
  local y_pos = self._aligned_playpos-self.y_pos+1
  self:toggler(1,y_pos,true) 


end

--------------------------------------------------------------------------------

--- Build the initial pattern cache - called on application startup. 
--  Basically, we look at each pattern and assign their length to the pattern
--  cache (this includes patterns with extended, aliased note data)
--  TODO: apply serialized pattern cache from song-data 

function GridPie:build_cache()

  -- determine the total number of lines
  --self.patt_cache_lines = self:get_max_pattern_length()
  --print("GridPie:build_cache() - total lines:",self.patt_cache_lines)
  local rns = renoise.song()
  for seq_idx = 1,#rns.sequencer.pattern_sequence do
    local patt_idx = rns.sequencer.pattern_sequence[seq_idx]
    local patt = rns.patterns[patt_idx]
    local num_lines = patt.number_of_lines
    if (patt.name ~= self.GRIDPIE_NAME) then
      --print("GridPie:build_cache() - patt_idx",patt_idx)
      for track_idx=1,rns.sequencer_track_count do
        local alias_patt_idx = self:resolve_patt_idx(patt_idx,track_idx)
        local alias_patt = rns.patterns[alias_patt_idx]
        --local num_lines = alias_patt.number_of_lines
        --self:set_pattern_cache(patt_idx,track_idx,num_lines)
        if (patt_idx~=alias_patt_idx) then
          self:set_pattern_cache(alias_patt_idx,track_idx,num_lines)
        end
        self:set_pattern_cache(patt_idx,track_idx,num_lines)
      end
    end
  end

  --rprint(self.patt_cache)

end

--------------------------------------------------------------------------------

--- Retrieve the combined pattern length (global least_common value)
-- @return number
--[[
function GridPie:get_max_pattern_length()

  -- loop through all pattern until gridpie pattern is reached
  local rns = renoise.song()
  local length = 0
  local lengths = table.create()
  for i=1,#rns.sequencer.pattern_sequence do
    local patt_idx = rns.sequencer:pattern(i)
    local patt_len = rns.patterns[patt_idx].number_of_lines
    lengths:insert(patt_len)
  end
  return math.min(
    renoise.Pattern.MAX_NUMBER_OF_LINES,
    least_common(lengths:values()) )
end
]]

--------------------------------------------------------------------------------

--- Update the grid display

function GridPie:adjust_grid()
  --TRACE("GridPie:adjust_grid()")

  local rns = renoise.song()
  local button_palette = nil
  local master_track_idx = get_master_track_index()
  local seq_idx = rns.selected_sequence_index
  local total_sequence = #rns.sequencer.pattern_sequence

  -- todo: only when inside the visible range 
  local rng_end = self.y_pos + self.MATRIX_HEIGHT
  local within_range = (seq_idx>=self.y_pos) and (seq_idx<rng_end)

  -- update the grid buttons 
  for x = self.x_pos, self.MATRIX_WIDTH + self.x_pos - 1 do
    local silent_track = self.poly_counter[x] and true or false
    for y = self.y_pos, self.MATRIX_HEIGHT + self.y_pos - 1 do
      local cell_x = x - self.x_pos + 1
      local cell_y = y - self.y_pos + 1
      local cell = self:matrix_cell(cell_x,cell_y)
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
        self.matrix_is_empty[cell_x][cell_y] = empty
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

  --print("self.matrix_is_empty...")
  --rprint(self.matrix_is_empty)

  -- set the selected pattern/track, preferably to the user-specified 
  -- value (the "actual" position), or to the page's top/left corner 
  if (self.options.follow_pos.value ~= self.FOLLOW_OFF) then
    rns.selected_track_index = self.actual_x or self.x_pos
    if (self.options.follow_pos.value == self.FOLLOW_TRACK_PATTERN) then
      rns.selected_sequence_index = self.actual_y or self.y_pos
    end
    --self.actual_x,self.actual_y = nil,nil

  end

end

--------------------------------------------------------------------------------

--- Clear a given track (briefly mute to stop sound)

function GridPie:clear_track(idx)
  --TRACE("GridPie:clear_track()",idx)

  local rns = renoise.song()
  rns.patterns[self.gridpie_patt_idx].tracks[idx]:clear()
  self.poly_counter[idx] = nil
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

--- Clear all tracks (briefly mute to stop sound)

function GridPie:clear_tracks()
  --TRACE("GridPie:clear_tracks()")

  local rns = renoise.song()
  for idx=1,rns.sequencer_track_count do
    self:clear_track(idx)
  end

end

--------------------------------------------------------------------------------

--- Copy and expand a track
-- @param src_patt (Pattern) source pattern
-- @param dest_patt (Pattern) destination pattern
-- @param track_idx (Number) the track index
-- @param num_lines (Number) optional, lines to copy before repeating - will use
--  source pattern length if not defined
-- @param offset (Number) optional, the source line offset - 0 is the default
-- @param lines_total (Number) optional, dest pattern length if not defined

function GridPie:copy_and_expand(src_patt,dest_patt,track_idx,num_lines,offset,lines_total)
  TRACE("GridPie:copy_and_expand()",src_patt,dest_patt,track_idx,num_lines,offset,lines_total)

  local source_track = src_patt:track(track_idx)
  local dest_track = dest_patt:track(track_idx)

  if num_lines == nil then
    num_lines = src_patt.number_of_lines
  end
  --print("num_lines",num_lines)

  if offset == nil then
    offset = 0
  end

  if lines_total == nil then
    lines_total = dest_patt.number_of_lines
  end

  -- (optimization) perform direct copies of the track?
  local quick_copy = false
  --[[
  if (offset==0) and src_patt ~= dest_patt then
    print("GridPie:copy_and_expand() - perform quick copy first, then expand...")
    dest_track:copy_from(source_track)
    quick_copy = true
  end
  ]]
  --print("quick_copy",quick_copy)

  local multiplier = math.floor(lines_total / num_lines)
  if quick_copy then
    -- assume that first cycle has already been copied
    multiplier = multiplier-1
  end
  --print("multiplier",multiplier)

  local to_line = nil
  local approx_line = 1

  for i=1, num_lines do
    for j=1, multiplier do

      local source_line = source_track:line(i+offset)
      to_line = i + num_lines * j
      if not quick_copy then
        to_line = to_line - num_lines
      end
      local dest_line = dest_track:line(to_line)

      -- Copy the top of pattern to the expanded lines
      --print("copy from",i+offset,"to",to_line)
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

--- Toggle position in grid 
-- x/y (number), position of pressed button 
-- pattern (boolean), whether to copy entire pattern

function GridPie:toggler(x, y, pattern)
  TRACE("GridPie:toggler()",x, y, pattern)

  -- translate from controller into track/sequence position
  local track_idx = x + (self.x_pos - 1)
  local seq_idx = y + (self.y_pos - 1)

  if self:is_garbage_pos(track_idx, seq_idx) then 
    print("could not switch to appointed track/pattern:",track_idx,seq_idx,pattern)

    print("self.revert_pm_slot...")
    rprint(self.revert_pm_slot)
    print("self.patt_cache...")
    rprint(self.patt_cache)
    print("self.active_slots...")
    rprint(self.active_slots)
    print("self.poly_counter...")
    rprint(self.poly_counter)
    print("self.aliased_patterns...")
    rprint(self.aliased_patterns)
    --[[
    ]]
    return 
  end
  
  local rns = renoise.song()
  local patt_idx = rns.sequencer:pattern(seq_idx)
  local source = rns.patterns[patt_idx]
  local dest = rns.patterns[self.gridpie_patt_idx]
  local master_track_idx = get_master_track_index()
  local total_sequence = #rns.sequencer.pattern_sequence

  -- keep the beat: remember this value, so that we can 
  -- modify the play-pos (if necessary after the copy)
  local old_lines = dest.number_of_lines
  local old_pos = rns.transport.playback_pos

  -- temporarily disable line notifier
  self.skip_gp_notifier = true

  if pattern then

    self._aligned_playpos = seq_idx

    local muteable = self:can_mute_pattern(track_idx,seq_idx)
    if muteable then
      -- clear pattern 
      self:clear_tracks()
    else
      -- copy pattern 
      dest.number_of_lines = source.number_of_lines 
      self:_keep_the_beat(old_lines,old_pos)
      --dest:copy_from(source)
      self:_alias_pattern(patt_idx,self.gridpie_patt_idx)

      self:set_pattern_cache(patt_idx,0,dest.number_of_lines)
    end

    -- Change PM
    for o = 1, rns.sequencer_track_count do

      if not muteable then
        -- TODO use aliased value
        self.poly_counter[o] = source.number_of_lines 
      end

      self._skip_mute_notifier = true

      if self.active_slots[o] then
        -- change only affected parts
        rns.sequencer:set_track_sequence_slot_is_muted(o , self.active_slots[o], true)
        rns.sequencer:set_track_sequence_slot_is_muted(o , seq_idx, muteable)
      else
        -- loop through entire sequence
        for i = 1, #rns.sequencer.pattern_sequence - 1 do
          if (i<total_sequence) then
            if muteable then
              -- everything has just been muted!
              rns.sequencer:set_track_sequence_slot_is_muted(o , i, true)
            else
              if i == seq_idx then
                rns.sequencer:set_track_sequence_slot_is_muted(o , i, false)
              else
                rns.sequencer:set_track_sequence_slot_is_muted(o , i, true)
              end
            end

          end
        end
      end
      self._skip_mute_notifier = false

    end

    for o = 1, rns.sequencer_track_count do
      self.active_slots[o] = seq_idx
    end

  else

    -- track copy

    local muted = false
    if self.poly_counter[track_idx] and 
      self.active_slots[track_idx] and 
      (self.active_slots[track_idx] == seq_idx) 
    then 
      muted = true 
    end

    if muted then

      self:clear_track(track_idx) -- will update poly_counter
      local lc = least_common(self.poly_counter:values())
      if lc then
        dest.number_of_lines = self:_restrict_to_pattern_length(lc)
        self:_keep_the_beat(old_lines,old_pos)
      else
        --print("toggler - no grid pie tracks available")
      end

    else

      -- copy contents from source track to recombination pattern
      local alias_patt_idx = self:resolve_patt_idx(patt_idx,track_idx)
      local alias_patt = rns.patterns[alias_patt_idx]
      self.poly_counter[track_idx] = alias_patt.number_of_lines
      -- how many lengths do we have? (poly_num)
      local poly_lines = table.create()
      for _,val in ipairs(self.poly_counter:values()) do 
        poly_lines[val] = true 
      end
      local poly_num = table.count(poly_lines)
      if poly_num > 1 then
        renoise.app():show_status("Grid Pie " .. poly_num .. "x poly combo!")
      else
        renoise.app():show_status("")
      end
      -- calculate new recombination pattern length
      local lc = least_common(self.poly_counter:values())
      if lc then

        --local simple_copy = poly_num <= 1
        local simple_copy = true
        --print("GridPie:toggler() - simple_copy A",simple_copy)

        -- changed the recombination pattern's length?
        local length_matched = (lc == dest.number_of_lines)

        -- see if we can retrieve fully expanded tracks from the cache
        -- for all relevant tracks
        for t_idx = 1, rns.sequencer_track_count do
          --if self.active_slots[t_idx] then
          if self.poly_counter[t_idx] then
            local s_idx = (t_idx==track_idx) and seq_idx or self.active_slots[t_idx]
            local p_idx = rns.sequencer.pattern_sequence[s_idx]
            local resolved_idx = self:resolve_patt_idx(p_idx,t_idx)
            local cached_length = self:get_pattern_cache(resolved_idx,t_idx)
            --print("GridPie:toggler() - cached_length",cached_length)
            if cached_length and (cached_length<lc) then
              simple_copy = false
            end
          end
        end
        --print("GridPie:toggler() - simple_copy B",simple_copy)
 

        if simple_copy then

          --print("GridPie:toggler() - Simple copy")

          -- use the cached pattern when it's sufficienty long
          local cached_length = self:get_pattern_cache(alias_patt_idx,track_idx)
          --print("GridPie:toggler() - cached_length",cached_length)
          local use_cached = cached_length and (cached_length>=lc) or false
          --print("GridPie:toggler() - use_cached",use_cached)

          if not length_matched then
            dest.number_of_lines = lc
            self:_keep_the_beat(old_lines,old_pos)
          end
          if not length_matched and not use_cached then
            dest.tracks[track_idx]:copy_from(source.tracks[track_idx])
            self:set_pattern_cache(patt_idx,track_idx,lc)
          end
          self:set_aliased_pattern(track_idx,patt_idx)

        else

          --print("GridPie:toggler() - Complex copy")

          dest.number_of_lines = self:_restrict_to_pattern_length(lc)
          self:_keep_the_beat(old_lines,old_pos)

          --print("GridPie:Expanding track " .. x .. " from " .. source.number_of_lines .. " to " .. dest.number_of_lines .. " lines")

          self:copy_and_expand(source, source, track_idx,source.number_of_lines,nil,dest.number_of_lines)
          self:set_pattern_cache(alias_patt_idx,track_idx,dest.number_of_lines)
          self:set_aliased_pattern(track_idx,alias_patt_idx)

          -- other tracks might have been affected by the
          -- changed length, and should be expanded as well...
          if old_lines < dest.number_of_lines then
            for idx=1, rns.sequencer_track_count do
              if
                idx ~= track_idx --and
                --not dest.tracks[idx].is_empty
              then
                local cached_patt_idx = self:resolve_patt_idx(self.gridpie_patt_idx,idx)
                TRACE("GridPie:Also expanding track ",idx,"with patt_idx",cached_patt_idx,"from",old_lines,"to",dest.number_of_lines,"lines") 
                self:copy_and_expand(dest, dest, idx, old_lines)
                self:set_pattern_cache(cached_patt_idx,idx,dest.number_of_lines)
              end
            end

          end

        end

      else
        --print("toggler - no grid pie tracks available")
      end
    end

    -- Change PM
    self._skip_mute_notifier = true
    if self.active_slots[track_idx] then
      -- change only affected slots
      rns.sequencer:set_track_sequence_slot_is_muted(track_idx , self.active_slots[track_idx], true)
      rns.sequencer:set_track_sequence_slot_is_muted(track_idx , seq_idx, muted)
    else
      -- loop through entire sequence
      for i = 1, #rns.sequencer.pattern_sequence - 1 do
        if (i<total_sequence) then
          if i == seq_idx then
            rns.sequencer:set_track_sequence_slot_is_muted(track_idx , i, muted)
          else
            rns.sequencer:set_track_sequence_slot_is_muted(track_idx , i, true)
          end
        end
      end
    end
    self._skip_mute_notifier = false

    self.active_slots[track_idx] = seq_idx

  end

  -- nullify playpos if active tracks aren't all
  -- aligned to the same sequence position
  for track_idx = 1, rns.sequencer_track_count do
    if self.poly_counter[track_idx] and 
      (self.active_slots[track_idx] ~= self._aligned_playpos)
    then
      self._aligned_playpos = nil
      if not renoise.song().transport.loop_pattern then
        self:cancel_scheduled_pattern()
      end
      break
    end
  end
  --print("GridPie:toggler() -  self._aligned_playpos",self._aligned_playpos)

  self.update_requested = true

  -- re-enable line notifier
  self.skip_gp_notifier = false

end


--------------------------------------------------------------------------------

--- Build GUI Interface
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

--- Start application 
-- (equivalent to main() in the original tool)

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
  self.poly_counter = table.create()
  self:init_pm_slots_to(true)
  self:init_gp_pattern()
  self:build_cache()

  self._track_count = rns.sequencer_track_count

  -- attach notifiers (after we have init'ed GP pattern!)
  local new_song = true
  self:_attach_to_song(new_song)

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

  -- update controller
  self:update_v_buttons()
  self:update_v_slider()
  self:update_h_buttons()
  self:update_h_slider()
  self:adjust_grid()

end

--------------------------------------------------------------------------------

--- Stop application
-- (equivalent to stop() in the original tool)

function GridPie:stop_app()
  TRACE("GridPie:stop_app()")

  if self._has_been_started then

    local rns = renoise.song()

    -- revert PM
    self:init_pm_slots_to(false)

    -- clear cache
    self.patt_cache = table.create()

    -- remove line notifiers from gridpie pattern
    self:_remove_line_notifier()
    local gp_patt = rns.patterns[self.gridpie_patt_idx]
    if gp_patt and (gp_patt:has_line_notifier(self._track_changes,self)) then
      gp_patt:remove_line_notifier(self._track_changes,self)
    end

    -- remove line notifiers from aliased pattern
    for aliased_patt_idx in ipairs(self.aliased_patterns) do
      local aliased_patt = rns.patterns[aliased_patt_idx]
      if aliased_patt and (type(aliased_patt)~="number") and (aliased_patt:has_line_notifier(self._track_changes,self)) then
        aliased_patt:remove_line_notifier(self._track_changes,self)
      end
    end
    self.aliased_patterns = table.create()
    
    -- remove remaining notifiers
    local new_song = false
    self:_remove_notifiers(new_song,self._pattern_observables)
    self:_remove_notifiers(new_song,self._song_observables)

  end

  self._has_been_started = false

  Application.stop_app(self)

end


--------------------------------------------------------------------------------

--- Abort (sleep during idle time and ignore any user input)

function GridPie:abort(notification)
  TRACE("GridPie:abort()",notification)

  --[[
  if not self.active then
    return
  end
  ]]

  renoise.app():show_status("You dun goofed! Grid Pie needs to be restarted.")
  self._process.browser:stop_current_configuration()

end

--------------------------------------------------------------------------------

--- Attach line notifier to source pattern

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

--- Remove line notifier from source pattern

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

--- Safe way to set pattern length

function GridPie:_restrict_to_pattern_length(num_lines)
  TRACE("GridPie:_restrict_to_pattern_length()",num_lines)
  return math.max(0,math.min(num_lines,renoise.Pattern.MAX_NUMBER_OF_LINES))

end

--------------------------------------------------------------------------------

--- Decide if we need to update the recombination/source pattern
-- note: this method might be called hundreds of times when doing edits like
-- cutting all notes from a pattern, so we need it to be really simple

function GridPie:_track_changes(pos)
  --TRACE("GridPie:_track_changes()",pos)

  if not self.active then
    return
  end 

  if self.skip_gp_notifier then
    --print("GridPie:_track_changes - bypassed line notifier")
    return
  end

  TRACE("GridPie:_track_changes()",pos)

  local rns = renoise.song()

  -- check if change was fired from the combination pattern
  -- by looking at the position in the pattern sequence
  local grid_seq_idx = #rns.sequencer.pattern_sequence
  local is_grid_patt = grid_seq_idx == rns.selected_sequence_index
  --print("GridPie:_track_changes - is_grid_patt",is_grid_patt)

  if is_grid_patt then
    -- change happened in recombination pattern

    -- we need a source before we can update anything!
    if not self.poly_counter[pos.track] then
      renoise.app():show_status("Grid Pie: cannot synchronize changes, unspecified source track...")
      return
    else
      -- copy and expand changes onto itself...
      local source_patt = rns.patterns[self.gridpie_patt_idx]
      self:_add_pending_update(self.gridpie_patt_idx,self.gridpie_patt_idx,pos)

    end

  else
    -- change happened in source pattern
    local source_patt = rns.patterns[pos.pattern]
    local seq_idx = rns.selected_sequence_index

    if self.poly_counter[pos.track] and
      (self.active_slots[pos.track] == seq_idx)
    then
      -- the source pattern-track is grid-pie'd 
      local dest_patt = rns.patterns[self.gridpie_patt_idx]
      if source_patt and 
        (source_patt.number_of_lines == dest_patt.number_of_lines) 
      then
        --print("same size - no copying is needed")
      else
        --print("different size - copy and expand")
        self:_add_pending_update(pos.pattern,pos.pattern,pos)
      end
    else
      print("GridPie:_track_changes() - ignore change to this pattern-track")
    end

  end

  -- determine if the slot has switched between empty <-> content
  -- todo: check if section is visible first
  local cell_x = self:get_grid_x_pos(pos.track)
  local cell_y = self:get_grid_y_pos(pos.pattern)
  --print("cell_x,cell_y",cell_x,cell_y)
  local patt = rns.patterns[pos.pattern]
  if patt.tracks[pos.track] then
    local cell_is_empty = patt.tracks[pos.track].is_empty
    if (cell_is_empty ~= self.matrix_is_empty[cell_x][cell_y]) then
      self.matrix_is_empty[cell_x][cell_y] = cell_is_empty
      self.update_requested = true
    end
  end

end

--------------------------------------------------------------------------------

--- Determine if a given pattern-track is aliased
-- @return Number, the aliased pattern index (or the original one)

function GridPie:resolve_patt_idx(patt_idx,track_idx)
  TRACE("GridPie:resolve_patt_idx()",patt_idx,track_idx)
  local patt = nil
  local tmp_idx = patt_idx
  while (tmp_idx~=0) do
    patt_idx = tmp_idx
    patt = renoise.song().patterns[tmp_idx]
    tmp_idx = patt.tracks[track_idx].alias_pattern_index
  end
  TRACE("GridPie:resolve_patt_idx() - patt_idx,track_idx",patt_idx,track_idx,"=patt_idx",patt_idx)
  return patt_idx
    
end


--------------------------------------------------------------------------------

--- Handle document change 
-- (document_changed() in original tool)

function GridPie:on_new_document()
  TRACE("GridPie:on_new_document()")

  self:abort()

end

--------------------------------------------------------------------------------

--- Handle idle updates 
--  (idler() in original tool)

function GridPie:on_idle()

  if not self.active then
    return
  end

  local rns = renoise.song()

  -- always make sure gridpie pattern is present
  local last_pattern = rns.sequencer:pattern(#rns.sequencer.pattern_sequence)
  if rns.patterns[last_pattern].name ~= self.GRIDPIE_NAME then
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
  
  if rns.transport.playing then
    local grid_pie_pos = #rns.sequencer.pattern_sequence
    local playing_pos = rns.transport.playback_pos.sequence
    local seq_pos_changed = (self._playing_seq_idx~=playing_pos)
    if (playing_pos~=grid_pie_pos) then
      -- we have moved to a pattern outside gridpie,
      -- determine if this is the result of a scheduled 
      -- pattern (a huge hack, since we cannot reliably 
      -- determine the schedule list)
      if 
        not rns.transport.follow_player and 
        seq_pos_changed 
      then
        --print("*** switch to this sequence-position",playing_pos)
        -- switch to this sequence-position,
        -- (but only when into a new position) 
        -- todo: optimize by making "mutable" a global property
        -- which is updated when toggling slots
        local muteable = self:can_mute_pattern(1,playing_pos)
        if not muteable then
          local y_pos = playing_pos-self.y_pos+1
          self:toggler(1,y_pos,true)
          -- if pattern loop is not enabled, schedule the
          -- next pattern in the sequence...
          self._aligned_playpos = playing_pos
          if not rns.transport.loop_pattern then
            local next_pos = self:next_pattern(playing_pos)
            rns.transport:set_scheduled_sequence(next_pos)            
          end
        end
      end
      -- always enforce position to gridpie pattern
      self:playback_pos_to_gridpie()

      if rns.transport.follow_player and
        (self.options.follow_pos.value ~= self.FOLLOW_OFF)-- and
        --not self:edit_pos_in_gridpie()
      then
        rns.transport.follow_player = false
      end

    else
      if seq_pos_changed and 
        not rns.transport.loop_pattern and 
        self._aligned_playpos
      then
        -- inside an unlooped gridpie pattern 
        -- schedule the next pattern in the sequence...
        local next_pos = self:next_pattern(self._aligned_playpos)
        rns.transport:set_scheduled_sequence(next_pos)
      end
    end
    if seq_pos_changed then
      self._playing_seq_idx = playing_pos
    end

  end

  if self.play_requested then
    self.play_requested = false
    rns.transport.playing = true
  end

  -- determine streaming mode
  -- (1) edit-mode is enabled
  -- (2) we are playing
  --[[
  if rns.transport.playing and
    rns.transport.edit_mode
  then
    print("GridPie: streaming mode...")
  end
  ]]

end

--------------------------------------------------------------------------------

--- Get the next pattern in the pattern sequence (go to the first pattern 
-- if we reach the gridpie pattern)
-- todo: consider pattern-sequence loops as well

function GridPie:next_pattern(seq_idx)
  TRACE("GridPie:next_pattern()",seq_idx)

  local rns = renoise.song()
  seq_idx = seq_idx+1

  -- check if within sequence loop
  if (rns.transport.loop_end.sequence == seq_idx) then
    return rns.transport.loop_start.sequence
  end

  -- check for end-of-song
  local grid_pie_pos = #rns.sequencer.pattern_sequence
  if (seq_idx == grid_pie_pos) then
    return 1
  end

  return seq_idx

end

--------------------------------------------------------------------------------

--- Workaround for the missing ability to clear the schedule list:
-- instead, we schedule the recombination pattern 

function GridPie:cancel_scheduled_pattern()

  local rns = renoise.song()
  local grid_pie_pos = #rns.sequencer.pattern_sequence
  rns.transport:set_scheduled_sequence(grid_pie_pos)

end

--------------------------------------------------------------------------------

--- Determine if edit-position is inside the __GRID PIE__ pattern
-- @return boolean

function GridPie:edit_pos_in_gridpie()

  local rns = renoise.song()
  local total_sequence = #rns.sequencer.pattern_sequence
  local last_patt_idx = rns.sequencer:pattern(total_sequence)
  local rslt = (last_patt_idx == rns.selected_pattern_index) 
  return rslt

end

--------------------------------------------------------------------------------

--- Determine the x-position of a track within the grid

function GridPie:get_grid_x_pos(track_idx)

  local pos = (track_idx%self.MATRIX_WIDTH) + (self.x_pos%self.MATRIX_WIDTH) - 1
  if (pos == 0) then
    pos = self.MATRIX_WIDTH
  end
  return pos
end

--------------------------------------------------------------------------------

--- Determine the y-position of a pattern within the grid

function GridPie:get_grid_y_pos(patt_idx)

  local pos = (patt_idx%self.MATRIX_HEIGHT) + (self.y_pos%self.MATRIX_HEIGHT) - 1
  if (pos == 0) then
    pos = self.MATRIX_HEIGHT
  end
  return pos

end


--------------------------------------------------------------------------------

--- Move playback position to the __GRID PIE__ pattern
-- @param restart (Boolean) force pattern to play from the beginning

function GridPie:playback_pos_to_gridpie(restart)
  TRACE("GridPie:playback_pos_to_gridpie()",restart)

  local rns = renoise.song()
  local grid_pie_pos = #rns.sequencer.pattern_sequence
  if (rns.transport.playback_pos.sequence==grid_pie_pos) then
    return
  end

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
  rns.transport.playback_pos = songpos

end

--------------------------------------------------------------------------------

--- Update the "gridpie_patt_idx" property

function GridPie:_maintain_gridpie_reference()
  TRACE("GridPie:_maintain_gridpie_reference()")

  local rns = renoise.song()
  local total_sequence = #rns.sequencer.pattern_sequence
  local last_patt_idx = rns.sequencer:pattern(total_sequence)
  local last_patt = rns.patterns[last_patt_idx]
  if (last_patt.name == self.GRIDPIE_NAME) then
    self.gridpie_patt_idx = rns.sequencer.pattern_sequence[total_sequence]
  end

end

--------------------------------------------------------------------------------

--- Prepare stuff that deal with the sequencer order

function GridPie:reset_tables()

  self.revert_pm_slot = table.create()
  self.active_slots = table.create()
  self.matrix_is_empty = table.create()
  -- note: width/height is set in build_app()
  for x=1,self.MATRIX_WIDTH do
    self.matrix_is_empty[x] = table.create()
    for y=1,self.MATRIX_HEIGHT do
      self.matrix_is_empty[x][y] = true
    end
  end

end

--------------------------------------------------------------------------------

--- Attach notifiers to the song
-- equivalent to run() in original tool,

function GridPie:_attach_to_song(new_song)
  TRACE("GridPie:_attach_to_song()",new_song)

  local rns = renoise.song()
  self:_remove_notifiers(new_song,self._pattern_observables)
  self:_remove_notifiers(new_song,self._song_observables)

  self._song_observables = table.create()

  -- When tracks have been inserted/removed/swapped
  self._song_observables:insert(rns.tracks_observable)
  rns.tracks_observable:add_notifier(self,
    function(app,notification)
      TRACE("GridPie:tracks_observable fired...",notification)
      if not self.active then 
        return 
      end
      local rns = renoise.song()
      self._track_count = rns.sequencer_track_count

      -- workaround for the situation where mute slots have
      -- triggered a toggle-task before the tracks observable
      if self._clear_toggle_tasks then
        for _,task in ipairs(self._toggle_tasks) do
          self.display.scheduler:remove_task(task)
        end
        self._toggle_tasks = table.create()
        self._clear_toggle_tasks = false
      end

      if (notification.type == "insert") then

        -- maintain matrix revert-state / active slots / poly-counter
        for idx = rns.sequencer_track_count-1, 1, -1 do
          if (idx>=notification.index) then
            self.active_slots[idx+1] = self.active_slots[idx]
            self.poly_counter[idx+1] = self.poly_counter[idx]
            self.revert_pm_slot[idx+1] = self.revert_pm_slot[idx]
          end
          if (idx==notification.index) then
            self.active_slots[idx] = self._aligned_playpos or 1
            self.poly_counter[idx] = nil
            self.revert_pm_slot[idx] = nil
          end
        end

        -- maintain pattern cache
        for patt_idx, length in ipairs(self.patt_cache) do
          for idx = rns.sequencer_track_count-1, 1, -1 do
            if (idx>=notification.index) then
              self.patt_cache[patt_idx][idx+1] = self.patt_cache[patt_idx][idx]
            end
            if (idx==notification.index) then
              local alias_patt_idx = self:resolve_patt_idx(patt_idx,idx)
              local alias_patt = rns.patterns[alias_patt_idx]
              self.patt_cache[patt_idx][idx] = alias_patt.number_of_lines
            end
          end
        end

        -- mute the newly inserted track
        self._skip_mute_notifier = true
        for i = 1, #renoise.song().sequencer.pattern_sequence - 1 do
          renoise.song().sequencer:set_track_sequence_slot_is_muted(notification.index , i, true)
        end
        self._skip_mute_notifier = false

      elseif (notification.type == "remove") then

        local trk_count = rns.sequencer_track_count

        -- maintain matrix revert-state / active slots / poly-counter
        for idx=1, trk_count do
          if (idx>=notification.index) then
            self.active_slots[idx] = self.active_slots[idx+1]
            self.poly_counter[idx] = self.poly_counter[idx+1]
            self.revert_pm_slot[idx] = self.revert_pm_slot[idx+1]
          end
        end
        self.active_slots[trk_count+1] = nil
        self.poly_counter[trk_count+1] = nil
        self.revert_pm_slot[trk_count+1] = nil


        -- maintain pattern cache
        for patt_idx, length in ipairs(self.patt_cache) do
          for idx = 1,rns.sequencer_track_count do
            if (idx>=notification.index) then
              self.patt_cache[patt_idx][idx] = self.patt_cache[patt_idx][idx+1]
            end
          end
          self.patt_cache[patt_idx][#self.patt_cache[patt_idx]] = nil
        end


      end
      self.h_update_requested = true
    end
  )

  -- When patterns are inserted/removed from the sequence 
  self._song_observables:insert(rns.sequencer.pattern_sequence_observable)
  rns.sequencer.pattern_sequence_observable:add_notifier(self,
    function(app,notification)
      TRACE("GridPie:pattern_sequence_observable fired...",notification)
      if not self.active then 
        return 
      end
      local rns = renoise.song()
      if (notification.type == "remove") then

        -- maintain matrix revert-state 
        local seq_len = #rns.sequencer.pattern_sequence
        for x = 1, rns.sequencer_track_count do
          for y=notification.index,seq_len do
            if not self.revert_pm_slot[x] then
              self.revert_pm_slot[x] = table.create()
            end
            if (y == notification.index) then
              self.revert_pm_slot[x][y] = nil
            else
              self.revert_pm_slot[x][y-1] = self.revert_pm_slot[x][y]
              if not self.revert_pm_slot[x][y+1] then
                self.revert_pm_slot[x][y] = nil
              end
            end
          end
        end
        -- maintain pattern cache: not really relevant, as the pattern
        -- is still present even when not part of the active sequence

        -- maintain active slots / poly-counter
        for track_idx=1, rns.sequencer_track_count do
          if self.active_slots[track_idx] and 
            (self.active_slots[track_idx] == notification.index) 
          then
            self.active_slots[track_idx] = nil
            self.poly_counter[track_idx] = nil
          end
        end

      elseif (notification.type == "insert") then
        -- insert a pattern into the sequence 

        -- special case: when the name contains "__GRID PIE__", we are
        -- dealing with a copy of the gridpie pattern 
        local seq_len = #rns.sequencer.pattern_sequence
        local patt_idx = rns.sequencer.pattern_sequence[seq_len]
        local patt = rns.patterns[patt_idx]
        if (notification.index == seq_len) and 
          patt.name:find(self.GRIDPIE_NAME) ~= nil 
        then
          --print("seems to be a clone of the gridpie pattern")
          patt.name = self.GRIDPIE_NAME
          local gp_patt = rns.patterns[self.gridpie_patt_idx]
          gp_patt.name = ""
          self.gridpie_patt_idx = patt_idx
          self:_create_alias_pattern(notification.index-1)
          return
        end

        -- maintain matrix revert-state 
        for x,_ in ripairs(self.revert_pm_slot) do
          for y=seq_len,notification.index,-1 do
            if (self.revert_pm_slot[x]) then
              self.revert_pm_slot[x][y+1] = self.revert_pm_slot[x][y]
            end
            if (y == notification.index) then
              self.revert_pm_slot[x][y] = nil
            end
          end
        end

        -- maintain active slots / poly-counter:
        -- detect if the pattern sequence is sorted
        -- (a cached pattern with the same pattern 
        -- index as the newly inserted pattern)

        if (self.patt_cache[notification.index]) then
          --print("*** ordered sequence was detected")
          for idx = #renoise.song().sequencer.pattern_sequence-2,1,-1 do
            if (idx>=notification.index) then
              self.patt_cache[idx+1] = table.rcopy(self.patt_cache[idx])
            end
            if (idx==notification.index) then
              self.patt_cache[idx] = nil
            end
          end
        end

        -- mute all slots in the newly inserted pattern
        self._skip_mute_notifier = true
        for track_idx = 1, rns.sequencer_track_count do
          rns.sequencer:set_track_sequence_slot_is_muted(track_idx,notification.index,true)
        end
        self._skip_mute_notifier = false

        -- todo: add the new pattern to the cache

        -- always enforce position to gridpie pattern
        self:playback_pos_to_gridpie()

      end

      self:_maintain_gridpie_reference()
      self.v_update_requested = true

    end
  )

  -- when playback start, force playback to enter __GRID PIE__ pattern
  self._song_observables:insert(rns.transport.playing_observable)
  rns.transport.playing_observable:add_notifier(self,
    function()
      --TRACE("GridPie:playing_observable fired...")
      if not self.active then return end
      if renoise.song().transport.playing then
        self:playback_pos_to_gridpie(true)
      end
    end
  )

  -- when changing track, update horizontal page
  self._song_observables:insert(rns.selected_track_index_observable)
  rns.selected_track_index_observable:add_notifier(self,
    function()
      --TRACE("GridPie:selected_track_index_observable fired...")
      if not self.active then 
        return 
      end
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
  self._song_observables:insert(rns.selected_sequence_index_observable)
  rns.selected_sequence_index_observable:add_notifier(self,
    function()
      --TRACE("GridPie:selected_sequence_index_observable fired...")
      
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

      -- update the current pattern display?
      if self.show_current_pattern then
        self.update_requested = true
      end

      -- attach line notifier
      self:_attach_line_notifier()
      self._current_seq_index = rns.selected_sequence_index

      -- attach pattern notifier
      local new_song = false
      self:_attach_to_pattern(new_song)

    end
  )

  -- when matrix mute slot state has changed
  self._song_observables:insert(rns.sequencer.pattern_slot_mutes_observable)
  rns.sequencer.pattern_slot_mutes_observable:add_notifier(self,
    function()
      TRACE("GridPie:sequencer.pattern_slot_mutes_observable fired...")
      
      if not self.active then 
        return 
      end

      if self._skip_mute_notifier then 
        --print("*** bypass the slot mutes observable ")
        return 
      end

      -- if the number of tracks have changed, do not
      -- check for changed slots (this is a workaround
      -- for the situation where this notifier is called
      -- before the tracks_observable)
      if (rns.sequencer_track_count~=self._track_count) then
        --print("*** ignore slot mutes observable due to change in tracks...")
        self._clear_toggle_tasks = true
        return
      end

      -- locate changed slots, collect into these tables...
      local muted = table.create() 
      local unmuted = table.create() 
      for seq_idx = 1,#renoise.song().sequencer.pattern_sequence-1 do
        for track_idx = 1,renoise.song().sequencer_track_count do
          local is_muted = renoise.song().sequencer:track_sequence_slot_is_muted(track_idx,seq_idx)
          if (self.active_slots[track_idx] == seq_idx) then
            if is_muted and self.poly_counter[track_idx] then
              muted[track_idx] = seq_idx
            elseif not is_muted and not self.poly_counter[track_idx] then
              unmuted[track_idx] = seq_idx
            end
          else
            if not is_muted then
              unmuted[track_idx] = seq_idx
            end
          end
        end
      end

      -- now toggle the relevant slots
      for track_idx = 1,renoise.song().sequencer_track_count do
        local seq_idx = nil
        if (muted[track_idx]) then
          seq_idx = muted[track_idx]
        end
        if (unmuted[track_idx]) then
          seq_idx = unmuted[track_idx]
        end
        if seq_idx then
          local x_pos = track_idx-(self.x_pos)+1
          local y_pos = seq_idx-(self.y_pos)+1
          self._toggle_tasks:insert(self.display.scheduler:add_task(
            self, GridPie.toggler,0.1,x_pos,y_pos))
        end
      end
    end
  )
  self._song_observables:insert(rns.transport.loop_pattern_observable)
  rns.transport.loop_pattern_observable:add_notifier(self,
    function(app,notification)
      TRACE("GridPie:transport.loop_pattern_observable fired...",app,notification)
      if not self.active then 
        return 
      end
      if self._aligned_playpos and
        not renoise.song().transport.loop_pattern 
      then
        self:cancel_scheduled_pattern()
      end
    end
  )
  

  -- attach line notifier for the current pattern
  self:_attach_line_notifier()

  -- attach notifiers for pattern
  local new_song = true
  self:_attach_to_pattern(new_song)

  -- attach line notifier to the recombination pattern
  -- !! we need to have created the pattern before calling this!!
  local gp_patt = rns.patterns[self.gridpie_patt_idx]
  gp_patt:add_line_notifier(self._track_changes,self)


end

--------------------------------------------------------------------------------

--- Attach notifiers to the pattern

function GridPie:_attach_to_pattern(new_song)
  TRACE("GridPie:_attach_to_pattern()")

  -- remove notifier first 
  self:_remove_notifiers(new_song,self._pattern_observables)

  local rns = renoise.song()
  local patt = rns.patterns[rns.selected_pattern_index]
  if (patt.name == self.GRIDPIE_NAME) then
    --print("Do not attach to the recombination pattern")
    return
  end
  self._pattern_observables = table.create()
  self._pattern_observables:insert(patt.number_of_lines_observable)
  patt.number_of_lines_observable:add_notifier(self,
    function()
      TRACE("GridPie:number_of_lines_observable fired...")
      local rns = renoise.song()
      local patt_idx = rns.selected_pattern_index

      if (patt_idx == self.gridpie_patt_idx) then
        --print("*** GridPie: skip the recombination pattern")
        return
      end

      -- include tracks which are currently in __GRID PIE__
      local patt_seq = rns.sequencer.pattern_sequence
      local patt = rns.patterns[patt_idx]
      for i = 1, rns.sequencer_track_count do
        local source_patt_idx = patt_seq[self.active_slots[i]]
        if source_patt_idx and (source_patt_idx == patt_idx) then
          -- todo: use aliased value?
          self.poly_counter[i] = patt.number_of_lines 
        end
      end
      local lc = least_common(self.poly_counter:values())
      if lc then
        local gp_patt = rns.patterns[self.gridpie_patt_idx]
        local old_lines = gp_patt.number_of_lines
        local old_pos = rns.transport.playback_pos
        gp_patt.number_of_lines = self:_restrict_to_pattern_length(lc)
        -- if overall length has changed, output all active tracks 
        if (lc ~= old_lines) then
          for i = 1, rns.sequencer_track_count do
            if (self.active_slots[i]) then
              -- prepare delayed update
              local pos = {
                pattern = self.active_slots[i],
                track = i,
                line = 1
              }
              local sequencer = rns.sequencer
              local src_patt_idx = sequencer.pattern_sequence[self.active_slots[i]]
              self:_add_pending_update(src_patt_idx,self.gridpie_patt_idx,pos)
            end
          end
          -- adjust playback position
          self:_keep_the_beat(old_lines,old_pos)
        else
          -- output the tracks that are based on this pattern
          local seq_idx = rns.selected_sequence_index
          for i = 1, rns.sequencer_track_count do
            if (self.active_slots[i] == seq_idx) then
              -- prepare delayed update
              local pos = {
                pattern = self.active_slots[i],
                track = i,
                line = 1
              }
              local src_patt_idx = rns.sequencer.pattern_sequence[self.active_slots[i]]
              self:_add_pending_update(src_patt_idx,self.gridpie_patt_idx,pos)
            end
          end

          
        end
      else
        --print("number_of_lines_observable - no grid pie tracks available")
      end

    end
  )

end

--------------------------------------------------------------------------------

--- Keep the beat: perform a number of tricks in order to keep the playback
-- inside the __GRID PIE__ pattern steady, even as it's size is being changed
-- note: to avoid glitches, call this method *before* doing anything heavy, 
-- CPU-wise (this method in itself is quite light on the CPU)
-- @param old_lines (Number) the previous number of lines
-- @param old_pos (SongPosition) the songposition to translate

function GridPie:_keep_the_beat(old_lines,old_pos)
  TRACE("GridPie:_keep_the_beat()",old_lines,old_pos)

  local rns = renoise.song()
  local meter = self.options.measure.value
  local dest = rns.patterns[self.gridpie_patt_idx]
  
  if (old_lines > dest.number_of_lines) then
    -- If the playhead is within the valid range, do nothing
    if (old_pos.line > dest.number_of_lines) then
      local lpb = rns.transport.lpb
      -- The playhead jumps back in the pattern by the same amount of lines as we, 
      -- at the moment the length changed, were located from the end of that 
      -- pattern. This should cause us to arrive at line 1 in the same time
      local new_line = (old_pos.line-old_lines) + dest.number_of_lines
      -- If the resulting line difference turned out negative, 
      -- go forward in line-increments that match the LPB 
      if (new_line<0) then
        while (new_line<0) do
          new_line = new_line+lpb
        end
      else
        -- lower the value to the first line within the LPB range
        new_line = new_line%lpb
      end
      -- add the number of beats
      local num_beats = math.floor((old_lines)/lpb)%meter
      local num_beats_reached = math.floor((old_pos.line)/lpb)%meter
      new_line = new_line+(num_beats_reached*lpb)
      -- ensure that the new line fit within new pattern
      -- (will happen when lpb is larger than pattern length)
      if (new_line>dest.number_of_lines) then
        new_line = new_line%dest.number_of_lines
      end
      -- finally, ensure we *never* go to line 0
      if (new_line==0) then
        new_line = dest.number_of_lines
      end
      old_pos.line = new_line
      rns.transport.playback_pos = old_pos
    end
  end

end

--------------------------------------------------------------------------------

--- Detach all previously attached notifiers first
-- but don't even try to detach when a new song arrived. old observables
-- will no longer be alive then...
-- @param new_song - boolean, true to leave existing notifiers alone
-- @param observables - list of observables
function GridPie:_remove_notifiers(new_song,observables)
  TRACE("GridPie:_remove_notifiers()",new_song,observables)

  if (not new_song) then
    for _,observable in pairs(observables) do
      pcall(function() observable:remove_notifier(self) end)
    end
  end
    
  observables:clear()

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

