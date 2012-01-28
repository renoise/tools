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

  grid      - (UIToggleButton...) - grid mapping, the individual buttons
  focus     - (UIToggleButton...) - bring focus to active slot
  v_prev    - (UIToggleButton)    - step to previous pattern
  v_next    - (UIToggleButton)    - step to next pattern
  h_prev    - (UIToggleButton)    - step to previous track
  h_next    - (UIToggleButton)    - step to next track
  v_slider  - (UISlider)          - set pattern
  h_slider  - (UISlider)          - set track


Options
  follow_pos    - enable to make Renoise follow the pattern/track
  polyrhythms   - allow/disallow polyrhythms when combining patterns (save CPU)
  page_size_v        - determine how many patterns to scroll with each step
  page_size_h        - determine how many tracks to scroll with each step

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
    value = 1,
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

  -- sequence index of our special recombination pattern
  self.GRIDPIE_IDX = nil

  -- width/height of the "grid" control-map group
  self.MATRIX_HEIGHT = nil
  self.MATRIX_WIDTH = nil

  -- references to the grid's UIToggleButtons
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

  -- boolean, true when button has been held
  self.held_button = nil

  -- page size (horizontal/vertical)
  self.page_size_v = nil
  self.page_size_h = nil

  -- the selected track/sequence index
  self.actual_x = nil
  self.actual_y = nil

  -- various flags used by idle loop
  self.play_requested = false
  self.update_requested = false
  self.v_update_requested = false
  self.h_update_requested = false
  self.disable_follow_player = false
  --self.suppress_track_notification = false

  -- keep reference to process, so we stop/abort the application
  self._process = process

  -- UIComponent references
  self._bt_v_prev = nil
  self._bt_v_next = nil
  self._bt_h_prev = nil
  self._bt_h_next = nil
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
    active_filled = {
      color={0xFF,0xFF,0x80},
      text="■",
    },
    active_empty = {
      color={0xFF,0x80,0x40},
      text="■",
    },
    empty = {
      color={0x00,0x00,0x00},
      text="□"    
    },
    filled = {
      color={0x40,0x00,0x40},
      text="□",
    },
    filled_silent = {
      color={0x80,0x40,0x40},
      text="□",
    },
    out_of_bounds = {
      color={0x40,0x40,0x00}, 
      text="",
    },  
  }

  Application.__init(self,process,mappings,options,cfg_name,palette)

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
  --TRACE("GridPie:set_vertical_pos()",idx)

  if (self.Y_POS~=idx) then
    self.Y_POS = idx
    self.v_update_requested = true
  end

end

function GridPie:set_horizontal_pos(idx)
  --TRACE("GridPie:set_horizontal_pos()",idx)

  if (self.X_POS~=idx) then
    self.X_POS = idx
    self.h_update_requested = true
  end

end

--------------------------------------------------------------------------------

-- update buttons for horizontal/vertical navigation

function GridPie:update_h_buttons()
  --TRACE("GridPie:update_h_buttons()")

  local skip_event = true
  local x_pos = self.actual_x or self.X_POS

  if self.mappings.h_next.group_name then
    self._bt_h_next:set(x_pos<self:_get_h_limit(),skip_event)
  end
  if self.mappings.h_prev.group_name then
    self._bt_h_prev:set(x_pos>self.page_size_h,skip_event)
  end

end

function GridPie:update_v_buttons()
  --TRACE("GridPie:update_v_buttons()")

  local skip_event = true
  local y_pos = self.actual_y or self.Y_POS

  if self.mappings.v_next.group_name then
    self._bt_v_next:set(y_pos<self:_get_v_limit(),skip_event)
  end
  if self.mappings.v_prev.group_name then
    self._bt_v_prev:set(y_pos>self.page_size_v,skip_event)
  end

end

--------------------------------------------------------------------------------

-- update slider for horizontal/vertical navigation

function GridPie:update_v_slider()
  --TRACE("GridPie:update_v_slider()")

  if self._v_slider then
    local skip_event = true
    local steps = self:_get_v_limit()
    local idx = math.min(steps,self.Y_POS-1)
    self._v_slider.steps = steps
    self._v_slider:set_index(idx,skip_event)
  end

end

function GridPie:update_h_slider()
  --TRACE("GridPie:update_h_slider()")

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
  --for i = 1,#self.POLY_COUNTER do
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

function GridPie:init_pm_slots_to(val)
  --TRACE("GridPie:init_pm_slots_to()",val)

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
        local tmp = x .. ',' .. y
        if val and rns.sequencer:track_sequence_slot_is_muted(x, y) then
        -- Store original state
          self.REVERT_PM_SLOT[tmp] = true
        end
        rns.sequencer:set_track_sequence_slot_is_muted(x , y, val)
        if not val and self.REVERT_PM_SLOT ~= nil and self.REVERT_PM_SLOT[tmp] ~= nil then
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

  if rns.patterns[last_pattern].name ~= "__GRID_PIE__" then
    -- Create new pattern
    local new_pattern = rns.sequencer:insert_new_pattern_at(total_sequence + 1)
    rns.patterns[new_pattern].name = "__GRID_PIE__"
    self.GRIDPIE_IDX = new_pattern
    total_sequence = total_sequence + 1
  else
    -- Clear pattern, unmute slot
    rns.patterns[last_pattern]:clear()
    rns.patterns[last_pattern].name = "__GRID_PIE__"
    for x = 1, total_tracks do
      rns.sequencer:set_track_sequence_slot_is_muted(x , total_sequence, false)
    end
    self.GRIDPIE_IDX = last_pattern
  end

  -- Cleanup any other pattern named __GRID_PIE__
  for x = 1, total_sequence - 1 do
    local tmp = rns.sequencer:pattern(x)

    if rns.patterns[tmp].name:find("__GRID_PIE__") ~= nil then
      rns.patterns[tmp].name = ""
    end
  end


end


--------------------------------------------------------------------------------

-- Adjust grid

function GridPie:adjust_grid()
  --TRACE("GridPie:adjust_grid()")

  local rns = renoise.song()
  local color = nil
  local master_track_idx = get_master_track_index()
  local total_sequence = #rns.sequencer.pattern_sequence

  for x = self.X_POS, self.MATRIX_WIDTH + self.X_POS - 1 do
    local silent_track = self.POLY_COUNTER[x] and true or false
    for y = self.Y_POS, self.MATRIX_HEIGHT + self.Y_POS - 1 do
      local cell = self:matrix_cell(x - self.X_POS + 1, y - self.Y_POS + 1)
      local active,empty,muted = false,true,true
      if (x>=master_track_idx) then
        color = self.palette.out_of_bounds
      elseif (y>=total_sequence) then
        color = self.palette.out_of_bounds
      elseif cell ~= nil then
        muted = rns.sequencer:track_sequence_slot_is_muted(x, y)
        active = not muted
        local patt_idx = rns.sequencer.pattern_sequence[y]
        empty = rns.patterns[patt_idx].tracks[x].is_empty
        if empty then
          if muted then 
            color = self.palette.empty
          else 
            color = self.palette.active_empty 
          end
        else
          if muted then 
            color = silent_track and self.palette.filled_silent
              or self.palette.filled
          else 
            color = self.palette.active_filled 
          end
        end
      end
      if color then
        -- assign same color to selected/inactive state
        cell:set_palette({background=color,foreground=color})
      end
      local skip_event = false
      cell:set(active,skip_event)

    end
  end

  -- set the selected pattern/track, preferably to the user-specified 
  -- value (the "actual" position), or to the page's top/left corner 
  if (self.options.follow_pos.value ~= self.FOLLOW_OFF) then
    rns.selected_track_index = self.actual_x or self.X_POS
    if (self.options.follow_pos.value == self.FOLLOW_TRACK_PATTERN) then
      rns.selected_sequence_index = self.actual_y or self.Y_POS
    end
    self.actual_x,self.actual_y = nil,nil
  end

end

--------------------------------------------------------------------------------

function GridPie:clear_track(idx)
  --TRACE("GridPie:clear_track()",idx)

  local rns = renoise.song()
  rns.patterns[self.GRIDPIE_IDX].tracks[idx]:clear()
  self.POLY_COUNTER[idx] = nil
  if (rns.tracks[idx].mute_state==MUTE_STATE_ACTIVE) then
    -- TODO: This is a hackaround, fix when API is updated
    -- See: http://www.renoise.com/board/index.php?showtopic=31927
    rns.tracks[idx].mute_state = MUTE_STATE_OFF
    OneShotIdleNotifier(100, function() rns.tracks[idx].mute_state = renoise.Track.MUTE_STATE_ACTIVE end)
  end

end

--------------------------------------------------------------------------------

function GridPie:clear_tracks()
  --TRACE("GridPie:clear_tracks()")

  local rns = renoise.song()

  for idx=1,rns.sequencer_track_count do
    rns.patterns[self.GRIDPIE_IDX].tracks[idx]:clear()
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

function GridPie:copy_and_expand(source_pattern, dest_pattern, track_idx, number_of_lines)
  --TRACE("GridPie:copy_and_expand()",source_pattern, dest_pattern, track_idx, number_of_lines)

  local source_track = source_pattern:track(track_idx)
  local dest_track = dest_pattern:track(track_idx)

  if number_of_lines == nil then
    number_of_lines = source_pattern.number_of_lines
  end

  if source_pattern ~= dest_pattern then
    dest_track:copy_from(source_track)
  end

  if dest_pattern.number_of_lines <= number_of_lines then
    return
  end

  local multiplier = math.floor(dest_pattern.number_of_lines / number_of_lines) - 1
  local to_line = 1
  local approx_line = 1

  for i=1, number_of_lines do
    for j=1, multiplier do

      to_line = i + number_of_lines * j
      local source_line = dest_track:line(i)
      local dest_line = dest_track:line(to_line)

      -- Copy the top of pattern to the expanded lines
      if not source_line.is_empty then
        dest_line:copy_from(source_line)
      end

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

function GridPie:toggler(x, y, pattern)
  --TRACE("GridPie:toggler()",x, y, pattern)

  local cell = self:matrix_cell(x, y)
  local muted = false
  if cell ~= nil and 
    cell.active
  then 
    muted = true 
  end

  x = x + (self.X_POS - 1)
  y = y + (self.Y_POS - 1)

  if self:is_garbage_pos(x, y) then 
    return 
  end

  --[[
  if (self.options.follow_pos.value ~= self.FOLLOW_OFF) then
    self.actual_x = x
    self.suppress_track_notification = true
  end
  ]]
  
  local rns = renoise.song()
  local source = rns.patterns[rns.sequencer:pattern(y)]
  local dest = rns.patterns[self.GRIDPIE_IDX]
  local master_track_idx = get_master_track_index()
  local total_sequence = #rns.sequencer.pattern_sequence

  if pattern then

    local muteable = self:can_mute_pattern(x,y)
    --print("muteable",muteable)
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
        --print("track #",o," - stored index is ",self.active_slots[o], " - set to",y)
        rns.sequencer:set_track_sequence_slot_is_muted(o , self.active_slots[o], true)
        rns.sequencer:set_track_sequence_slot_is_muted(o , y, muteable)
      else
        -- loop through entire sequence
        for i = 1, #rns.sequencer.pattern_sequence - 1 do
          --print("got here",o,i)
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

    if muted then

      self:clear_track(x)

    else

      -- Track polyrhythms

      self.POLY_COUNTER[x] = source.number_of_lines
      local lc = least_common(dest.number_of_lines, source.number_of_lines)
      local poly_lines = table.create()
      for _,val in ipairs(self.POLY_COUNTER:values()) do poly_lines[val] = true end
      local poly_num = table.count(poly_lines)

      if poly_num > 1 then
        renoise.app():show_status("Grid Pie " .. poly_num .. "x poly combo!")
      else
        renoise.app():show_status("")
      end

      if
        self.options.polyrhythms.value == self.POLY_DISABLED or
        lc > renoise.Pattern.MAX_NUMBER_OF_LINES or
        poly_num <= 1 or
        (lc == source.number_of_lines and lc == dest.number_of_lines)
      then

        -- Simple copy
        dest.number_of_lines = source.number_of_lines
        dest.tracks[x]:copy_from(source.tracks[x])

      else

        -- Complex copy
        local old_lines = dest.number_of_lines
        dest.number_of_lines = lc

        TRACE("GridPie:Expanding track " .. x .. " from " .. source.number_of_lines .. " to " .. dest.number_of_lines .. " lines")

        OneShotIdleNotifier(0, function()
          self:copy_and_expand(source, dest, x)
        end)

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
      --print("track #",x," - stored index is ",self.active_slots[x], " - set to",y)
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

  self.update_requested = true

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
    local c = UIToggleButton(self.display)
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
    self._bt_v_prev = c
  end

  -- button: vertical, next 
  if (self.mappings.v_next.group_name) then
    local c = UIToggleButton(self.display)
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
    self._bt_v_next = c
  end

  -- button: horizontal, previous
  if (self.mappings.h_prev.group_name) then
    local c = UIToggleButton(self.display)
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
    self._bt_h_prev = c
  end

  -- button: horizontal, next
  if (self.mappings.h_next.group_name) then
    local c = UIToggleButton(self.display)
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
    self._bt_h_next = c
  end

  -- grid buttons
  if (self.mappings.grid.group_name) then
    self._buttons = {}
    for x = 1, self.MATRIX_WIDTH do
      self.MATRIX_CELLS[x] = table.create()
      for y = 1, self.MATRIX_HEIGHT do

        local c = UIToggleButton(self.display)
        c.group_name = self.mappings.grid.group_name
        c.tooltip = self.mappings.grid.description
        c:set_pos(x,y)
        c.active = false
        if (self.options.hold_enabled.value == self.HOLD_DISABLED) then
          c.on_press = function(obj) 
            -- track copy
            if not self.active then return false end
            self:toggler(x,y) 
          end
        else
          c.on_release = function(obj) 
            -- track copy
            if not self.active then return false end
            if self.held_button and
              (self.held_button == obj) then
              self.held_button = nil
              return false
            end
            self:toggler(x,y) 
          end
          c.on_hold = function(obj) 
            -- pattern copy
            self.held_button = obj
            if not self.active then return false end
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
  self:_attach_to_song(renoise.song())
  Application._build_app(self)
  return true

end


--------------------------------------------------------------------------------

-- equivalent to main() in the original tool

function GridPie:start_app()
  TRACE("GridPie:start_app()")

  -- this step will ensure that the application is properly mapped,
  -- after which it will call the build_app() method, which in 
  -- turn will call attach_to_song() method)
  if not Application.start_app(self) then
    return
  end

  local rns = renoise.song()

  -- initialize important stuff
  self:reset_tables()
  self.POLY_COUNTER = table.create()
  self:init_pm_slots_to(true)
  self:init_gp_pattern()
  self:_set_step_sizes() 

  -- update controller
  self:update_v_buttons()
  self:update_v_slider()
  self:update_h_buttons()
  self:update_h_slider()
  self:adjust_grid()

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
  if (self.options.follow_pos.value == self.FOLLOW_TRACK_PATTERN) then
    rns.selected_sequence_index = 1
  else
    rns.selected_sequence_index = #rns.sequencer.pattern_sequence
  end


end

--------------------------------------------------------------------------------

-- equivalent to stop() in the original tool

function GridPie:stop_app()
  TRACE("GridPie:stop_app()")

  -- Revert PM
  self:init_pm_slots_to(false)

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
  if renoise.song().patterns[last_pattern].name ~= "__GRID_PIE__" then
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

  if self.disable_follow_player then
    self.disable_follow_player = false
    renoise.song().transport.follow_player = false
  end

  local grid_pie_pos = #rns.sequencer.pattern_sequence
  if (renoise.song().transport.playback_pos.sequence~=grid_pie_pos) then
    self:playback_pos_to_gridpie()
  end

  if self.play_requested then
    self.play_requested = false
    renoise.song().transport.playing = true
  end

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

  -- Tracks have changed, stored slots are invalid, reset table
  renoise.song().tracks_observable:add_notifier(
    function(notification)
      TRACE("GridPie:tracks_observable fired...",notification,notification.type)
      if not self.active then return end
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

  -- Sequence have changed, stored slots are invalid, reset table
  renoise.song().sequencer.pattern_sequence_observable:add_notifier(
    function(notification)
      TRACE("GridPie:pattern_sequence_observable fired...",notification,notification.type)
      if not self.active then return end
      self:reset_tables()
      self.v_update_requested = true
    end
  )

  -- when playback start, force playback to enter __GRID PIE__ pattern
  renoise.song().transport.playing_observable:add_notifier(
    function()
      TRACE("GridPie:playing_observable fired...")
      if not self.active then return end
      if renoise.song().transport.playing then
        self:playback_pos_to_gridpie(true)
      end
    end
  )

  -- when follow_pos is enabled, enforce a disabled "follow_player"
  renoise.song().transport.follow_player_observable:add_notifier(
    function()
      TRACE("GridPie:follow_player_observable fired...")
      if not self.active then return end
      if renoise.song().transport.follow_player and
        (self.options.follow_pos.value ~= self.FOLLOW_OFF) 
      then
        self.disable_follow_player = true
      end
    end
  )

  -- when changing track, update horizontal page
  renoise.song().selected_track_index_observable:add_notifier(
    function()
      TRACE("GridPie:selected_track_index_observable fired...")
      if not self.active then return end
      --[[
      if self.suppress_track_notification then
        self.suppress_track_notification = false
        print("suppressed_track_notification")
        return
      end
      ]]
      if (self.options.follow_pos.value ~= self.FOLLOW_OFF) then
        local track_idx = renoise.song().selected_track_index
        self.actual_x = track_idx
        local page = math.floor((track_idx-1)/self.page_size_h)
        local new_x = page*self.page_size_h+1
        self:set_horizontal_pos(new_x)
        -- hack: prevent track from changing
        self.actual_y = renoise.song().selected_sequence_index
      end
    end
  )

  -- when changing pattern in the sequence, update vertical page
  renoise.song().selected_sequence_index_observable:add_notifier(
    function()
      --TRACE("GridPie:selected_sequence_index_observable fired...")
      if not self.active then return end
      if (self.options.follow_pos.value ~= self.FOLLOW_OFF) then
        if (self.options.follow_pos.value == self.FOLLOW_TRACK_PATTERN) then
          local seq_idx = renoise.song().selected_sequence_index
          self.actual_y = seq_idx
          local page = math.floor((seq_idx-1)/self.page_size_v)
          local new_y = page*self.page_size_v+1
          self:set_vertical_pos(new_y)
        end
        -- hack: prevent track from changing
        self.actual_x = renoise.song().selected_track_index
      end
    end
  )


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

