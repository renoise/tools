--[[----------------------------------------------------------------------------
-- Duplex.GridPie
-- Inheritance: Application > GridPie
----------------------------------------------------------------------------]]--

--[[

About

  Tool discussion is located here:
  http://forum.renoise.com/index.php?/topic/33484-new-tool-28-duplex-grid-pie/


Changes (equal to Duplex version number)

  0.98 - First release



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
    on_change = function(app)
      app:_set_page_sizes()
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
      app:_set_page_sizes()
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
  initialization = {
    label = "Initialization",
    description = "How Grid Pie should behave when launched",
    items = {
      "Manual start",
      "Auto (stopped)",
      "Auto (playing)",
    },
    value = 1,
  },
  shutdown = {
    label = "Shutdown",
    description = "How Grid Pie should behave when shut down",
    items = {
      "Keep everything",
      "Clear everything",
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
  self.FOLLOW_OFF = 1
  self.FOLLOW_TRACK = 2
  self.FOLLOW_TRACK_PATTERN = 3
  self.STEPSIZE_AUTO = 1

  self.AUTOSTART_MANUAL = 1
  self.AUTOSTART_STOP = 2
  self.AUTOSTART_PLAY = 3

  self.SHUTDOWN_KEEP_ALL = 1
  self.SHUTDOWN_CLEAR_ALL = 2

  self.HOLD_ENABLED = 1
  self.HOLD_DISABLED = 2

  self.GRIDPIE_NAME = "__GRID PIE__"
  self.GRIDPIE_BUFFER_NAME = "__GRID TMP__"

  -- width/height of the "grid" control-map group
  self.matrix_height = 0
  self.matrix_width = 0

  -- references to the grid's buttons
  self.MATRIX_CELLS = table.create()

  -- pattern index of gridpie pattern
  self.gridpie_patt_idx = nil

  -- sequence-pos/pattern-index of former gridpie pattern
  -- (assigned when session recording)
  self.gp_buffer_seq_pos = nil
  self.gp_buffer_patt_idx = nil

  -- true when we shouldn't listen for changes to the 
  -- gridpie pattern (when copying pattern data)
  self.skip_gp_notifier = false

  -- when we record changes in realtime (no aliasing)
  self.realtime_record = false

  -- list of tracks that should be output as 
  -- incremental updates (during idle loop)
  --  track_idx (number)
  --  src_patt_idx (number)
  --  last_output_pos (number or nil)
  self.realtime_tracks = table.create()

  -- number of lines to output, each time an 
  -- incremental update is written to the pattern
  self.writeahead_length = nil

  -- number of lines between incremental updates
  self.writeahead_interval = nil

  -- list of lengths (pattern-lines) for each track
  -- the value is nil when the track isn't active
  self.poly_counter = table.create()

  -- memorized state of the matrix 
  self.revert_pm_slot = table.create()

  -- indexed list of homeless tracks, 
  self.homeless_tracks = table.create()

  -- (number) the scheduled pattern (if any)
  self.scheduled_seq_idx = nil

  -- the state of our slow blink rate
  -- (alternates between true and false)
  self._blink = false

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

  -- when we have edited content that needs copy-expansion:
  -- [track_index] = {
  --   src_patt_idx (number)
  --   pos (line notifier table)
  --  }
  self.pending_updates = table.create()

  -- (Scheduler) delayed updates for copy-expanding
  self._update_task = nil

  -- keep track of held buttons in the matrix
  -- [x][y] = {
  --  obj (UIButton)
  --  ptrack (PatternTrack)
  --  track_idx (Number)
  --  seq_idx (Number)
  --  void (Boolean) 
  -- }
  self.held_buttons = table.create()

  -- the button which was first pressed
  self.src_button = nil -- UIButton

  -- page size (horizontal/vertical)
  self.page_size_v = nil
  self.page_size_h = nil

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
  self._line_notifiers = table.create()

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
    empty                   = { color={0x00,0x00,0x00}, text="·", val=false },
    empty_current           = { color={0x00,0x40,0x00}, text="·", val=false },
    empty_active            = { color={0x40,0x40,0x00}, text="·", val=true  },
    empty_active_current    = { color={0x40,0x40,0x00}, text="·", val=true  },
    content_selected        = { color={0xFF,0xFF,0x00}, text="·", val=true  },
    content_active          = { color={0x80,0x40,0x00}, text="·", val=false },
    content_active_master   = { color={0x80,0x80,0x00}, text="·", val=false },
    content_active_current  = { color={0x40,0x80,0x00}, text="·", val=false },
    inactive_content        = { color={0x40,0x00,0x00}, text="·", val=false },
    out_of_bounds           = { color={0x00,0x00,0x00}, text="·", val=false },  
    out_of_bounds_current   = { color={0x40,0x80,0x00}, text="·", val=false },  
    gridpie_normal          = { color={0x80,0x80,0x00}, text="·", val=false },  
    gridpie_alias           = { color={0xFF,0xFF,0x00}, text="·", val=true  },
    gridpie_current         = { color={0x40,0x80,0x00}, text="·", val=false },  
    gridpie_homeless        = { color={0xFF,0xFF,0x00}, text="·", val=true  },  
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
-- @param src_patt_idx (Number) "unresolved" source pattern index
-- @param pos (Table) pos.pattern, pos.track, pos.line

function GridPie:_add_pending_update(src_patt_idx,pos)
  TRACE("GridPie:_add_pending_update()",src_patt_idx,pos)
  if not self.pending_updates[pos.track] then
    self.pending_updates[pos.track] = table.create()
  end
  self.pending_updates[pos.track] = {
    src_patt_idx = src_patt_idx,
    --dest_patt_idx = pos.pattern,
    track_idx = pos.track,
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
  local gridpie_patt = rns.patterns[self.gridpie_patt_idx]

  if not gridpie_patt then
    --print("*** Oops! Grid Pie pattern has gone, cannot apply update!")
  end

  -- process those updates
  for track_idx =1, rns.sequencer_track_count do
    local v = self.pending_updates[track_idx]
    -- check the poly_counter (the track might have been
    -- de-activated since we scheduled the update)
    if v and self.poly_counter[v.track_idx] then

      --print("*** self.pending_updates[",track_idx,"]")
      --rprint(self.pending_updates[track_idx])

      local num_lines = self.poly_counter[v.track_idx]
      --print("*** num_lines",num_lines)
      --local alias_patt_idx = self:resolve_patt_idx(self.gridpie_patt_idx,v.track_idx)

      -- check if the change originated within the GP pattern, or
      -- if the source pattern is referenced in the GP pattern 
      -- (use the current GP pattern length if this is the case)
      local lines_total = nil
      local gp_ptrack = gridpie_patt.tracks[v.track_idx]
      local src_is_gpied = (v.src_patt_idx == gp_ptrack.alias_pattern_index)
      --print("*** src_is_gp",src_is_gpied)
      if src_is_gpied then
        lines_total = gridpie_patt.number_of_lines
      else
        lines_total = rns.patterns[v.src_patt_idx].number_of_lines
      end
      --print("*** lines_total",lines_total)

      -- determine the offset (if any)
      local offset = 0
      if (v.line > num_lines) then
        offset = math.floor((v.line-1)/num_lines)*num_lines
      end

      self.skip_gp_notifier = true
      local resolved_patt_idx = self:resolve_patt_idx(v.src_patt_idx,track_idx)
      self:copy_and_expand(resolved_patt_idx,nil,track_idx,num_lines,offset,lines_total)
      self.skip_gp_notifier = false

    end
  end
  
  self.pending_updates = table.create()

end

--------------------------------------------------------------------------------

--- Method used to determine the length of a given slot

function GridPie:determine_slot_length(seq_idx,patt_idx,track_idx)

  -- check if the slot is actively being used in the GP pattern
  -- yes, use that length
  -- no, use the length from the originating pattern


end


--------------------------------------------------------------------------------

--- Prepare a newly cloned Grid Pie pattern
-- we should call this method right after having cloned the pattern, 
-- and before we clear/update active_slots, homeless_tracks etc.

function GridPie:adapt_gridpie_pattern()
  TRACE("GridPie:adapt_gridpie_pattern()")
  
  local rns = renoise.song()
  local new_seq_idx = self:get_gridpie_seq_pos()
  local new_patt_idx = rns.sequencer:pattern(new_seq_idx)
  local new_patt = rns.patterns[new_patt_idx]
  local old_seq_idx = new_seq_idx-1
  local old_patt_idx = rns.sequencer:pattern(old_seq_idx)
  local old_patt = rns.patterns[old_patt_idx]
  --local gp_patt = rns.patterns[self.gridpie_patt_idx]
  local session_recording = self:is_session_recording()

  -- mute slots in the former GP pattern - unless they are 
  -- homeless slots that we are going to settle in their new home
  if not session_recording then
    for t_idx = 1,rns.sequencer_track_count do
      if session_recording or not self.homeless_tracks[t_idx] then
        rns.sequencer:set_track_sequence_slot_is_muted(t_idx,old_seq_idx,true)
        --print("*** in former GP pattern, mute non-homeless track #",t_idx)
      end
    end
  end
  -- assign name to the new pattern
  old_patt.name = ""
  new_patt.name = self.GRIDPIE_NAME

  self.gridpie_patt_idx = new_patt_idx
  --print("*** adapt_gridpie_pattern - new_patt_idx",self.gridpie_patt_idx)

  -- loop through tracks in the new pattern
  for track_idx,ptrack in ipairs(new_patt.tracks) do
    -- skip non-sequencer tracks
    if (track_idx <= rns.sequencer_track_count) then
      --print("*** loop through new pattern track #",track_idx)
      if not ptrack.is_alias then
        -- add unique slots to the cache
        self:set_pattern_cache(old_patt_idx,track_idx,old_patt.number_of_lines)
        -- if not recording, create alias for unique/homeless slot
        if not session_recording and not self.realtime_tracks[track_idx] then
        --if not session_recording then
          if self.homeless_tracks[track_idx] then
            -- reference homeless tracks 
            ptrack.alias_pattern_index = old_patt_idx
            self:mute_selected_track_slot(track_idx)
          elseif self.poly_counter[track_idx] then
            -- reference the currently selected slot
            local grid_slot_idx = self.active_slots[track_idx]
            if grid_slot_idx then
              local slot_patt_idx = rns.sequencer.pattern_sequence[grid_slot_idx]
              ptrack.alias_pattern_index = slot_patt_idx
              --print("*** in new GP pattern, create slot aliases for track #",track_idx)
            end
          end
        else
          --print("*** skip alias for realtime record-track",track_idx)
        end
      end
    end
    -- unmute all slots in the new pattern
    rns.sequencer:set_track_sequence_slot_is_muted(track_idx,new_seq_idx,false)
  end

  -- set any (formerly) homeless track as active, unless
  -- we are session recording
  for track_idx,_ in pairs(self.homeless_tracks) do
    --if not self.realtime_tracks[track_idx] then
    if not session_recording then
      -- mute the previously active slot
      if self.active_slots[track_idx] then
        rns.sequencer:set_track_sequence_slot_is_muted(track_idx,self.active_slots[track_idx],true)
      end
      self.active_slots[track_idx] = old_seq_idx
      --print("*** set homeless track as active: self.active_slots[",track_idx,"] =",old_seq_idx)
      self.homeless_tracks[track_idx] = nil
      self.realtime_tracks[track_idx] = nil
    end
  end

  if not session_recording and
    (rns.transport.edit_pos.sequence == old_seq_idx) 
  then
    -- if we were inside the previous GP pattern (edit pos), 
    -- always forward us to the new GP pattern
    local edit_pos = rns.transport.edit_pos
    edit_pos.sequence = new_seq_idx
    rns.transport.edit_pos = edit_pos
    --print("*** adapt_gridpie_pattern: rns.transport.edit_pos",edit_pos)
  end

  -- establish loop 
  rns.transport.loop_sequence_range = {new_seq_idx,new_seq_idx}


end


--------------------------------------------------------------------------------

--- Helper method to determine if we are currently recording a session

function GridPie:is_session_recording()

  return (self.realtime_record and 
    not renoise.song().transport.loop_pattern)

end

--------------------------------------------------------------------------------

function GridPie:clear_lines(track_idx,patt_idx,start_line,end_line)
  TRACE("GridPie:clear_lines()",track_idx,patt_idx,start_line,end_line)

  local rns = renoise.song()
  local iter = rns.pattern_iterator:lines_in_pattern_track(patt_idx,track_idx)

  for pos,line in iter do
    if (pos.line >= start_line) and (pos.line <= end_line) then
      --print("*** clear line #",pos.line)
      line:clear()
    end
  end

end

--------------------------------------------------------------------------------

--- Set one of the recombination pattern-tracks as aliased

function GridPie:alias_slot(track_idx,alias_p_idx)
  TRACE("GridPie:alias_slot()",track_idx,alias_p_idx)

  local rns = renoise.song()
  local patt_track = rns.patterns[self.gridpie_patt_idx].tracks[track_idx]
  local alias_ptrack = rns.patterns[alias_p_idx].tracks[track_idx]
  -- if the alias pattern is in itself an alias:
  if alias_ptrack.is_alias then
    alias_p_idx = alias_ptrack.alias_pattern_index
  end
  local aliased_patt = rns.patterns[alias_p_idx]
  patt_track.alias_pattern_index = alias_p_idx

  -- attach line notifier 
  if aliased_patt and not (aliased_patt:has_line_notifier(self._track_changes,self)) then
    aliased_patt:add_line_notifier(self._track_changes,self)
    --print("*** GridPie:alias_slot() - added line notifiers...")
  end
end

--------------------------------------------------------------------------------

--- Update the internal pattern cache, called immediately after copy-expand 
-- @param patt_idx (Number), the pattern index
-- @param track_idx (Number), the track index (0 to copy all tracks in pattern)
-- @param num_lines (Number), amount of lines or nil to clear

function GridPie:set_pattern_cache(patt_idx,track_idx,num_lines)
  --TRACE("GridPie:set_pattern_cache()",patt_idx,track_idx,num_lines)

  local rns = renoise.song()

  if not self.patt_cache[patt_idx] then
    self.patt_cache[patt_idx] = table.create()
  end

  if not num_lines then
    -- clear this entry
    self.patt_cache[patt_idx][track_idx] = nil
  elseif (track_idx==0) then
    -- copy pattern (all tracks) - call once for each track...
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

  -- resolve the pattern (we only have one master slot)
  --local resolved_idx = self:resolve_patt_idx(patt_idx,track_idx)

  if self.patt_cache[patt_idx] then
    local rslt = self.patt_cache[patt_idx][track_idx] 
    return rslt
  end

  return nil
  
end

--------------------------------------------------------------------------------

--- Apply the current settings to page_size_v and page_size_h variables

function GridPie:_set_page_sizes()
  --TRACE("GridPie:_set_page_sizes()")

  self.page_size_v = (self.options.page_size_v.value==self.STEPSIZE_AUTO) and
    self.matrix_height or self.options.page_size_v.value-1
  
  self.page_size_h = (self.options.page_size_h.value==self.STEPSIZE_AUTO) and
    self.matrix_width or self.options.page_size_h.value-1

end

--------------------------------------------------------------------------------

--- Figure out the upper boundary

function GridPie:_get_v_limit()
  local rns = renoise.song()
  local gridpie_seq_pos = self:get_gridpie_seq_pos()
  return math.max(1,gridpie_seq_pos - self.matrix_height)
end

--- Figure out the lower boundary

function GridPie:_get_h_limit()
  local rns = renoise.song()
  return math.max(1,rns.sequencer_track_count - self.matrix_width + 1)
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
-- @return (number), the quantized sequence index

function GridPie:set_vertical_pos_page(seq_idx)
  TRACE("GridPie:set_vertical_pos_page()",seq_idx)

  local page = math.floor((seq_idx-1)/self.page_size_v)
  local new_y = page*self.page_size_v+1

  if (self.options.follow_pos.value ~= self.FOLLOW_OFF) then
    if (self.options.follow_pos.value == self.FOLLOW_TRACK_PATTERN) then
      self:set_vertical_pos(new_y)
    end
  end

  return new_y

end

--------------------------------------------------------------------------------

--- update buttons for horizontal navigation

function GridPie:update_h_buttons()
  TRACE("GridPie:update_h_buttons()")

  local x_pos = self.x_pos
  --print("*** x_pos",x_pos)
  --print("*** self:_get_h_limit()",self:_get_h_limit())
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

--------------------------------------------------------------------------------

--- update buttons for vertical navigation

function GridPie:update_v_buttons()
  TRACE("GridPie:update_v_buttons()")

  local skip_event = true
  local y_pos = self.y_pos

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

--------------------------------------------------------------------------------

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

--- Check if a hold event should perform a "pattern toggle" 
-- this is only possible when every track is active & aligned
-- @param seq_idx (number)
-- @return boolean

function GridPie:can_mute_pattern(seq_idx)
  TRACE("GridPie:can_mute_pattern()",seq_idx)

  local rns = renoise.song()

  local able_to_toggle = true
  if not self:_slots_are_aligned(seq_idx) then
    able_to_toggle = false
  else
    --print("*** can_mute_pattern - got here")
    for i = 1,rns.sequencer_track_count do
      if not self.poly_counter[i] then
        --print("*** can_mute_pattern - missing poly_counter for track",i)
        able_to_toggle = false
        break
      end
    end
  end
  --print("*** can_mute_pattern - able_to_toggle",able_to_toggle)
  return able_to_toggle

end

--------------------------------------------------------------------------------

--- function to check if all slots are aligned to the same sequence index
-- @param seq_idx (number)
-- @return boolean

function GridPie:_slots_are_aligned(seq_idx)
  TRACE("GridPie:_slots_are_aligned()",seq_idx)

  local rns = renoise.song()
  local s_idx = nil
  local are_aligned = true
  for i = 1,rns.sequencer_track_count do
    if not s_idx then
      -- first time around
      s_idx = self.active_slots[i]
      if (s_idx~=seq_idx) then
        are_aligned = false
        break
      end
    elseif (s_idx~=self.active_slots[i]) then
      are_aligned = false
      break
    end
  end
  --print("*** slots_are_aligned - are_aligned",are_aligned)
  return are_aligned

end

--------------------------------------------------------------------------------

--- Is garbage PM position?

function GridPie:is_garbage_pos(track_idx,seq_idx)
  --TRACE("GridPie:is_garbage_pos()",track_idx,seq_idx)

  local rns = renoise.song()
  --local total_sequence = #rns.sequencer.pattern_sequence
  local gridpie_seq_pos = self:get_gridpie_seq_pos()

  if
    rns.sequencer.pattern_sequence[seq_idx] == nil or
    rns.tracks[track_idx] == nil or
    rns.tracks[track_idx].type == renoise.Track.TRACK_TYPE_MASTER or
    rns.tracks[track_idx].type == renoise.Track.TRACK_TYPE_SEND or
    gridpie_seq_pos <= seq_idx
  then
    return true
  else
    return false
  end

end

--------------------------------------------------------------------------------

--- Determine if we have manually looped a range in the pattern sequence
-- (excluding normal pattern loop, and song-wide looping)
--[[
function GridPie:is_custom_seq_loop()

  local rns = renoise.song()
  local seq_len = #rns.sequencer.pattern_sequence

  -- normal pattern loop
  if rns.transport.loop_pattern then
    --print("normal pattern loop")
    return false
  end

  -- song-wide loop
  if (rns.transport.loop_start.sequence == 1) and
    (rns.transport.loop_end.sequence == seq_len) and 
    (rns.transport.loop_end.line > 1)
  then
    --print("rns.transport.loop_end.sequence",rns.transport.loop_end.sequence)
    --print("rns.transport.loop_end.line",rns.transport.loop_end.line)
    --print("song-wide loop")
    return false
  end

  return true

end
]]

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
  --local total_sequence = #sequencer.pattern_sequence
  local gridpie_seq_pos = self:get_gridpie_seq_pos()

  for x = 1, rns.sequencer_track_count do
    for y = 1, gridpie_seq_pos do
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

end


--------------------------------------------------------------------------------

--- Initialize Grid Pie Pattern
-- (called when starting the application)

function GridPie:init_gp_pattern()
  TRACE("GridPie:init_gp_pattern()")

  local rns = renoise.song()
  local sequencer = rns.sequencer
  local total_sequence = #sequencer.pattern_sequence
  local last_pattern = rns.sequencer:pattern(total_sequence)

  -- determine the position we should start from:
  -- if playing, use the playback position
  -- else, use the currently edited pattern
  if rns.transport.playing then
    local playback_pos = rns.transport.playback_pos
    self._aligned_playpos = playback_pos.sequence
  else
    self._aligned_playpos = rns.selected_sequence_index
  end

  local gridpie_exist = rns.patterns[last_pattern].name == self.GRIDPIE_NAME
  --print("GridPie:init_gp_pattern - gridpie_exist",gridpie_exist)
  if not gridpie_exist then
    -- create new pattern
    local new_pattern = rns.sequencer:insert_new_pattern_at(total_sequence + 1)
    rns.patterns[new_pattern].name = self.GRIDPIE_NAME
    self.gridpie_patt_idx = new_pattern
    total_sequence = total_sequence + 1
  else
    -- clear pattern, unmute slot
    rns.patterns[last_pattern]:clear()
    rns.patterns[last_pattern].name = self.GRIDPIE_NAME
    for x = 1, rns.sequencer_track_count do
      rns.sequencer:set_track_sequence_slot_is_muted(x , total_sequence, false)
    end
    self.gridpie_patt_idx = last_pattern
  end

  -- establish loop 
  rns.transport.loop_sequence_range = {total_sequence,total_sequence}

  -- Cleanup any other pattern named __GRID_PIE__
  for x = 1, total_sequence - 1 do
    local tmp = rns.sequencer:pattern(x)
    if rns.patterns[tmp].name:find(self.GRIDPIE_NAME) ~= nil then
      rns.patterns[tmp].name = ""
    end
  end

  -- Running start: copy contents into pattern
  -- (but not if we launched on an existing gridpie pattern)
  if not gridpie_exist then
    self:set_vertical_pos_page(self._aligned_playpos)
    local y_pos = self._aligned_playpos-self.y_pos+1
    self:toggler(1,y_pos,true) 
  end

end

--------------------------------------------------------------------------------

--- Realtime recording, check if conditions have changed and call either 
-- start/stop_recording (will also update the pattern-sequence loop)
-- this method is called by various notifiers

function GridPie:check_recording_status()
  TRACE("GridPie:check_recording_status()")

  local rns = renoise.song()

  -- pattern sequence loop needs to be enabled 
  -- (span less than the entire song)
  --local custom_seq_loop = self:is_custom_seq_loop()

  if rns.transport.playing and 
    rns.transport.edit_mode and 
    rns.transport.follow_player
  then
    self.realtime_record = true
  elseif (not rns.transport.playing or
    not rns.transport.edit_mode or
    not rns.transport.follow_player)
  then
    self.realtime_record = false
    self.realtime_tracks = table.create()
  end

  -- turn pattern-loop off when session recording
  if self.realtime_record and not rns.transport.loop_pattern then
    rns.transport.loop_sequence_range = {}
  else
    local gp_seq_idx = self:get_gridpie_seq_pos()
    rns.transport.loop_sequence_range = {gp_seq_idx,gp_seq_idx}
  end

  --print("self.realtime_record",self.realtime_record)

end



--------------------------------------------------------------------------------

--- Build the initial pattern cache - called on application startup. 

function GridPie:build_cache()
  TRACE("GridPie:build_cache()")

  -- determine the total number of lines
  --self.patt_cache_lines = self:get_max_pattern_length()
  --print("GridPie:build_cache() - total lines:",self.patt_cache_lines)
  local rns = renoise.song()
  local gridpie_seq_pos = self:get_gridpie_seq_pos()

  for seq_idx = 1,gridpie_seq_pos do
    local patt_idx = rns.sequencer.pattern_sequence[seq_idx]
    local patt = rns.patterns[patt_idx]

    -- this is the entry point for the cache system
    -- here we pick up any (extended) slots and apply  
    -- their length to the originating/master slot
    local num_lines = patt.number_of_lines

    if (patt.name ~= self.GRIDPIE_NAME) then
      --print("GridPie:build_cache() - patt_idx",patt_idx)
      for track_idx=1,rns.sequencer_track_count do
        local alias_p_idx = self:resolve_patt_idx(patt_idx,track_idx)
        self:set_pattern_cache(alias_p_idx,track_idx,num_lines)
      end
    end
  end

  --rprint(self.patt_cache)

end


--------------------------------------------------------------------------------

--- Makes the target slot unique, update gridpie 
-- (first button that has been pressed is the target)
-- @param ptrack (PatternTrack) the target slot (destination)
-- @param track_idx (Number)
-- @param seq_idx (Number)
-- @return boolean, true when slot was made unique

function GridPie:make_slot_unique(ptrack,track_idx)
  TRACE("GridPie:make_slot_unique",ptrack,track_idx)
  
  if ptrack.is_alias then
    local src_patt_idx = ptrack.alias_pattern_index
    local src_patt = renoise.song().patterns[src_patt_idx]
    local src_ptrack = renoise.song().patterns[src_patt_idx].tracks[track_idx]
    ptrack.alias_pattern_index = 0
    self.skip_gp_notifier = true
    ptrack:copy_from(src_ptrack)
    --print("*** slot made unique")
    self.skip_gp_notifier = false

    self.update_requested = true
    return true
  end

  return false

end


--------------------------------------------------------------------------------

--- translate X/Y into track/sequence position

function GridPie:get_idx_from_coords(x,y)

  local track_idx = x + self.x_pos - 1
  local seq_idx = y + self.y_pos - 1
  return track_idx,seq_idx

end

--------------------------------------------------------------------------------

--- get a pattern-track (slot) from provided coordinates
-- @param x,y (number) grid x/y coordinates 
-- @param skip_garbage (boolean) skip garbage pos, including gridpie

function GridPie:get_ptrack_from_coords(x,y,skip_garbage)

  local t_idx,s_idx = self:get_idx_from_coords(x,y)
  local is_garbage = false
  if skip_garbage then
    is_garbage = self:is_garbage_pos(t_idx,s_idx)
  end
  if not is_garbage then
    local ptrack = self:get_ptrack(s_idx,t_idx)
    return ptrack,t_idx,s_idx
  end
  return nil,t_idx,s_idx

end

--------------------------------------------------------------------------------

--- Safely obtain a pattern-track by it's sequence/track index

function GridPie:get_ptrack(seq_idx,track_track)

  local p_idx = renoise.song().sequencer:pattern(seq_idx)
  if (p_idx) then
    local p = renoise.song().patterns[p_idx]
    local ptrack = p.tracks[track_track]
    if ptrack then
      return ptrack
    end 
  end

end

--------------------------------------------------------------------------------

--- Update the grid display
-- (used sparingly, as this will paint each and every slot in the grid)

function GridPie:adjust_grid()
  TRACE("GridPie:adjust_grid()")

  -- update the grid buttons 
  for x = 1, self.matrix_width do
    for y = 1, self.matrix_height do
      local cell = self:matrix_cell(x,y)
      self:paint_cell(cell,x,y)
    end
  end


end

--------------------------------------------------------------------------------

--- standalone method for painting individual cells in the grid
--  used by adjust_grid and update_homeless_tracks

function GridPie:paint_cell(cell,x,y)
  --TRACE("GridPie:paint_cell()",cell,x,y)
  
  local track_idx,seq_idx = self:get_idx_from_coords(x,y)
  local rns = renoise.song()
  local sel_seq_idx = rns.selected_sequence_index
  local sel_track_idx = renoise.song().selected_track_index
  local gridpie_seq_pos = self:get_gridpie_seq_pos()

  -- figure out if track/sequence highlight is in range, at which index
  local current_seq,current_trk = false,false
  local seq_end = self.y_pos + self.matrix_height
  local trk_end = self.x_pos + self.matrix_width
  current_trk = (sel_track_idx>=self.x_pos) and (sel_track_idx<trk_end) and 
    (track_idx%self.matrix_width == sel_track_idx%self.matrix_width)
  current_seq = (sel_seq_idx>=self.y_pos) and (sel_seq_idx<seq_end) and
    (seq_idx%self.matrix_height == sel_seq_idx%self.matrix_height) 

  -- determine if the slot has an aliased master
  local has_aliased_master = function(ptrk,t_idx)
    local is_alias = false
    if ptrk.is_alias then
      local mst_seq_idx = self.active_slots[track_idx]
      if mst_seq_idx and 
        rns.sequencer.pattern_sequence[self.active_slots[t_idx]] 
      then
        local mst_patt_idx = rns.sequencer:pattern(mst_seq_idx)
        local mst_ptrack = rns.patterns[mst_patt_idx].tracks[track_idx]
        is_alias = mst_ptrack.is_alias
      else
        --print("*** GridPie.paint_cell - failed to access an active slot for track #" .. track_idx)
      end
    end
    return is_alias
  end

  local is_master_slot = function(ptrk,t_idx,p_idx)
    local is_master = false
    local active_resolved_idx = nil
    if ptrk and not ptrk.is_alias and
      rns.sequencer.pattern_sequence[self.active_slots[t_idx]] 
    then
      local active_patt_idx = rns.sequencer:pattern(self.active_slots[t_idx])
      local active_resolved_idx = self:resolve_patt_idx(active_patt_idx,t_idx)
      if (p_idx == active_resolved_idx) and (p_idx ~= active_patt_idx) then
        --print("p_idx",p_idx,"active_resolved_idx",active_resolved_idx,"active_patt_idx",active_patt_idx)
        is_master = true
      end
    end
    return is_master,active_resolved_idx
  end


  if (track_idx>rns.sequencer_track_count) then
    -- track out-of-bounds
    cell:set(self.palette.out_of_bounds)
  elseif (seq_idx>=gridpie_seq_pos) then
    if (seq_idx==gridpie_seq_pos) then
      -- the grid pie pattern
      local patt_idx = rns.sequencer.pattern_sequence[seq_idx]
      local ptrack = rns.patterns[patt_idx].tracks[track_idx]
      -- show that an aliased slot can be resolved
      local is_alias = has_aliased_master(ptrack,track_idx)
      if is_alias then
        cell:set(self.palette.gridpie_alias)
      elseif (current_seq or current_trk) then
        cell:set(self.palette.gridpie_current)
      else
        cell:set(self.palette.gridpie_normal)
      end
    else
      -- sequence out-of-bounds
      cell:set(self.palette.out_of_bounds)
    end
  elseif cell ~= nil then
    -- we use the pattern matrix to determine the muted state
    local muted = rns.sequencer:track_sequence_slot_is_muted(track_idx, seq_idx)
    local patt_idx = rns.sequencer.pattern_sequence[seq_idx]
    local ptrack = rns.patterns[patt_idx].tracks[track_idx]
    local empty = ptrack.is_empty
    if empty then
      if muted then 
        local is_master = is_master_slot(ptrack,track_idx,patt_idx)
        if is_master then
          cell:set(self.palette.empty_active)
        elseif (current_seq or current_trk) then
          cell:set(self.palette.empty_current)
        else
          cell:set(self.palette.empty)
        end
      else 
        if current_trk then
          cell:set(self.palette.empty_active_current)
        else
          cell:set(self.palette.empty_active)
        end
      end
    else
      -- slots with content
      if muted then 
        local active_track = self.poly_counter[track_idx] and true or false
        if active_track then
          local is_master = is_master_slot(ptrack,track_idx,patt_idx)
          if is_master then
            cell:set(self.palette.content_active_master)
          else
            if current_trk then
              cell:set(self.palette.content_active_current)
            else
              cell:set(self.palette.content_active)
            end

          end
        else
          cell:set(self.palette.inactive_content)
        end
      else 
        cell:set(self.palette.content_selected)
      end
    end
  end

end

--------------------------------------------------------------------------------

--- Clear a given track (briefly mute to stop sound)

function GridPie:clear_track(track_idx)
  TRACE("GridPie:clear_track()",track_idx)

  local rns = renoise.song()
  rns.patterns[self.gridpie_patt_idx].tracks[track_idx]:clear()
  self.poly_counter[track_idx] = nil

  if (rns.tracks[track_idx].type == renoise.Track.TRACK_TYPE_SEQUENCER) and
    (rns.tracks[track_idx].mute_state==MUTE_STATE_ACTIVE) 
  then
    self:brief_track_mute(track_idx)
  end

end

--------------------------------------------------------------------------------

--- This is a hackaround, fix when API is updated
-- See: http://www.renoise.com/board/index.php?showtopic=31927

function GridPie:brief_track_mute(track_idx)

  local rns = renoise.song()
  rns.tracks[track_idx].mute_state = MUTE_STATE_OFF
  OneShotIdleNotifier(100, function() 
    rns.tracks[track_idx].mute_state = renoise.Track.MUTE_STATE_ACTIVE 
  end)

end

--------------------------------------------------------------------------------

--- Copy and expand a track 
-- @param patt_idx (Pattern) source pattern index
-- @param dest_patt_idx (number) optional, destination pattern index - defined when realtime recording, will use the source pattern index if not defined
-- @param track_idx (Number) the track index
-- @param num_lines (Number) optional, lines to copy before repeating - use source pattern length if not defined
-- @param offset (Number) optional, the source line offset - 0 is the default
-- @param lines_total (Number) optional, use destination pattern length if not defined
-- @param start_line (Number) optional, start output from this line
-- @param end_line (Number) optional, stop output at this line

function GridPie:copy_and_expand(patt_idx,dest_patt_idx,track_idx,num_lines,offset,lines_total,start_line,end_line)
  TRACE("GridPie:copy_and_expand()",patt_idx,dest_patt_idx,track_idx,num_lines,offset,lines_total,start_line,end_line)

  local rns = renoise.song()
  local patt = rns.patterns[patt_idx]
  local track = patt:track(track_idx)

  local dest_patt,dest_track = nil
  if dest_patt_idx then
    dest_patt = rns.patterns[dest_patt_idx]
    dest_track = dest_patt:track(track_idx)
  else
    dest_patt = patt
    dest_track = track
  end

  if not num_lines then
    num_lines = patt.number_of_lines
  end
  if lines_total == nil then
    lines_total = dest_patt.number_of_lines
  end
  if offset == nil then
    offset = 0
  end
  
  local incremental = (start_line or end_line)

  -- optimization: skip if num_lines and lines_total are the same
  if not incremental and (num_lines==lines_total) then
    --print("*** optimization: no need for expanding contents...")
    return
  end

  local src_is_empty = rns.patterns[patt_idx].tracks[track_idx].is_empty

  -- skip empty pattern-tracks if we are not performing a partial update
  if not incremental and src_is_empty then
    --print("*** optimization: skip empty pattern-track...")
  else 

    -- the multiplier is always a perfect fit when non-incremental,
    -- but we might need an extra run when doing incremental update
    local multiplier = lines_total / num_lines
    if incremental then
      multiplier = math.ceil(multiplier) 
    else
      multiplier = math.floor(multiplier) 
    end

    --print("*** copy_and_expand: num_lines",num_lines,"lines_total",lines_total,"offset",offset,"multiplier",multiplier)

    local to_line = nil
    --local approx_line = 1
    local do_copy = nil

    self.skip_gp_notifier = true

    for i=1, num_lines do

      for j=1, multiplier do

        to_line = (i + num_lines * j) - num_lines
        do_copy = true
        if (start_line and (to_line < start_line)) or
          (end_line and (to_line > end_line)) 
        then
          do_copy = false
        end
        --print("*** to_line",to_line,do_copy)

        if do_copy then

          local dest_line = dest_track:line(to_line)

          -- optimize: if empty, simply clear the lines
          if src_is_empty then
            --print("*** clear line at",to_line)
            dest_line:clear()
          else
            -- Copy the top of pattern to the expanded lines
            local source_line = track:line(i+offset)
            --print("*** copy from",i+offset,"to",to_line)
            dest_line:copy_from(source_line)
          end

          -- Copy the top of the automations to the expanded lines
          --[[
          for _,automation in pairs(track.automation) do
            for _,point in pairs(automation.points) do
              approx_line = math.floor(point.time)
              if approx_line == i then
                print("automation:add_point_at()",to_line + point.time - approx_line, point.value)
                automation:add_point_at(to_line + point.time - approx_line, point.value)
              elseif approx_line > i then
                break
              end
            end
          end
          ]]

        end

      end
    end

    self.skip_gp_notifier = false

  end


  -- update the pattern cache (if not performing a partial update)
  if not start_line then
    self:set_pattern_cache(patt_idx,track_idx,lines_total)
  end

end

--------------------------------------------------------------------------------

--- Show the first/master occurrence of the indicated GP slot, update display
-- (nothing will happen if the slot isn't aliased)

function GridPie:goto_slot(track_idx)

  local rns = renoise.song()
  local gp_seq_idx = self:get_gridpie_seq_pos()
  local gp_patt_idx = rns.sequencer:pattern(gp_seq_idx)
  local gp_ptrack = rns.patterns[gp_patt_idx].tracks[track_idx]
  --print("*** toggler - gp_ptrack",gp_ptrack)
  if gp_ptrack and (gp_ptrack.alias_pattern_index > 0) then 
    --print("*** toggler - gp_ptrack.alias_pattern_index",gp_ptrack.alias_pattern_index)
    
    -- locate the _first_ pattern (as patterns can repeat)
    for s_idx = 1, #rns.sequencer.pattern_sequence do
      if (rns.sequencer:pattern(s_idx) == gp_ptrack.alias_pattern_index) then

        -- display the master slot (vertical page)
        self.y_pos = self:set_vertical_pos_page(s_idx)
        --print("*** jumped page, y-pos is now",self.y_pos)
        self.v_update_requested = true
        if (self.options.follow_pos.value == self.FOLLOW_TRACK_PATTERN) then
          rns.transport.follow_player = false
          --print("*** dealing with an aliased slot, follow_player is disabled")
          rns.selected_sequence_index = s_idx
        end
        -- select/activate the slot (no change in gridpie pattern)
        self:mute_selected_track_slot(track_idx)
        rns.sequencer:set_track_sequence_slot_is_muted(track_idx,s_idx,false)
        self.active_slots[track_idx] = s_idx

        break

      end
    end

  end

end

--------------------------------------------------------------------------------

--- Call this method to clone the GP pattern, insert at the end
-- pattern_sequence_observable will take care of the rest...

function GridPie:clone_pattern()
  TRACE("GridPie:clone_pattern()")

  local rns = renoise.song()
  local gp_seq_idx = self:get_gridpie_seq_pos()
  rns.sequencer:clone_range(gp_seq_idx,gp_seq_idx)
  self.v_update_requested = true

end

--------------------------------------------------------------------------------

--- Toggle position in grid 
-- x/y (number), position of pressed button 
-- pattern (boolean), whether to copy entire pattern

function GridPie:toggler(x, y, pattern)
  TRACE("GridPie:toggler()",x, y, pattern)

  local rns = renoise.song()
  local gp_seq_idx = self:get_gridpie_seq_pos()
  local track_idx,seq_idx = self:get_idx_from_coords(x,y)

  if self:is_garbage_pos(track_idx, seq_idx) then 

    -- only allow events that happened in supported
    -- parts of the matrix (no master/send/gridpie pattern)

    --[[
    -- print some debug information...
    print("self.revert_pm_slot...")
    rprint(self.revert_pm_slot)
    print("self.patt_cache...")
    rprint(self.patt_cache)
    print("self.active_slots...")
    rprint(self.active_slots)
    print("self.poly_counter...")
    rprint(self.poly_counter)
    print("self.homeless_tracks...")
    rprint(self.homeless_tracks)
    ]]
    return 
  end
  
  -- process grid - disable line notifier
  local muted = false
  self.skip_gp_notifier = true
  if pattern then
    muted = self:_toggle_pattern(seq_idx,track_idx)
  else
    muted = self:_toggle_slot(seq_idx,track_idx)
  end
  self.update_requested = true

  -- re-enable line notifier
  self.skip_gp_notifier = false

  -- if the current pattern is the gridpie pattern,
  -- re-attach line notifiers (as slots have changed)
  --local gp_seq_idx = #rns.sequencer.pattern_sequence
  if (gp_seq_idx == rns.selected_sequence_index) then
    --print("*** toggler - re-attach line notifiers...")
    self:_attach_line_notifiers()
  end

  -- update the track/sequence position, but
  -- only when we have turned something on
  --[[
  if not muted then
    if (self.options.follow_pos.value ~= self.FOLLOW_OFF) then
      rns.selected_track_index = track_idx
      if (self.options.follow_pos.value == self.FOLLOW_TRACK_PATTERN) then
        rns.selected_sequence_index = seq_idx
      end
    end
  end
  ]]

  

end


--------------------------------------------------------------------------------

--- toggle a particular slot, auto-detect if we should toggle on or off
-- also, update the pattern-matrix mute state...
-- @param seq_idx (number), the pattern-sequence index 
-- @param track_idx (number), the track index

function GridPie:_toggle_slot(seq_idx,track_idx)
  TRACE("GridPie:_toggle_slot()",seq_idx,track_idx)

  local rns = renoise.song()
  local patt_idx = rns.sequencer:pattern(seq_idx)
  local patt = rns.patterns[seq_idx]
  local gridpie_patt = rns.patterns[self.gridpie_patt_idx]
  local old_lines = gridpie_patt.number_of_lines
  local old_pos = rns.transport.playback_pos

  -- true when we perform a recorded action (create a homeless slot)
  local stay_homeless = false

  -- check if the track should be toggled on or off
  local muted = false
  if self.poly_counter[track_idx] and 
    self.active_slots[track_idx] and 
    (self.active_slots[track_idx] == seq_idx) 
  then 
    muted = true 
  end

  if muted then
    if self.realtime_record then
      -- mute track 
      self.poly_counter[track_idx] = nil
      self:brief_track_mute(track_idx)
      self:incremental_update(track_idx)
      -- output note-off across note columns
      local line_idx = rns.transport.playback_pos.line
      local line = gridpie_patt.tracks[track_idx]:line(line_idx)
      local note_col_count = rns.tracks[track_idx].visible_note_columns
      for col_idx = 1,note_col_count do
        line.note_columns[col_idx].note_value = 120
      end

    else

      -- clear, mute track and update poly_counter
      self:clear_track(track_idx) 
      -- check if we have changed the length
      local lc = least_common(self.poly_counter:values())
      if lc then
        gridpie_patt.number_of_lines = self:_restrict_to_pattern_length(lc)
        self:_keep_the_beat(old_lines,old_pos)
      end

    end

  else

    -- copy contents from source track to recombination pattern
    --[[
    local alias_p_idx = self:resolve_patt_idx(patt_idx,track_idx)
    local alias_patt = rns.patterns[alias_p_idx]
    self.poly_counter[track_idx] = alias_patt.number_of_lines
    ]]
    self.poly_counter[track_idx] = patt.number_of_lines
    -- calculate new recombination pattern length
    local lc = least_common(self.poly_counter:values())
    if lc then
      
      -- how many different lengths have we got?
      -- (display this information in status bar)
      local poly_lines = table.create()
      for _,val in ipairs(self.poly_counter:values()) do 
        poly_lines[val] = true 
      end
      local poly_num = table.count(poly_lines)
      if poly_num > 1 then
        renoise.app():show_status("Grid Pie " .. poly_num .. "x poly combo!"
          .."Total length: " .. lc .. " lines")
      else
        renoise.app():show_status("")
      end

      local alias_p_idx = self:resolve_patt_idx(patt_idx,track_idx)

      -- special case: when realtime recording, copy-expand from
      -- the current position and a few lines ahead (LPS), writing
      -- the data directly into the GP pattern. 
      if self.realtime_record then

        if not self.realtime_tracks[track_idx] then
          --print("*** set up realtime recording for this track:",track_idx)
          -- make sure any existing alias is removed
          -- (copy existing contents into the slot)
          local gp_slot = gridpie_patt.tracks[track_idx]
          if gp_slot.is_alias then
            local existing_slot = self:get_ptrack(self.active_slots[track_idx],track_idx)
            gp_slot.alias_pattern_index = 0
            gp_slot:copy_from(existing_slot)
          end
        end

        -- define the realtime track, and output at once

        self.realtime_tracks[track_idx] = {
          src_patt_idx = alias_p_idx,
          track_idx = track_idx,
          last_output_pos = nil
        }
        self:incremental_update(track_idx)

        -- make sure track stays homeless >:p
        self.homeless_tracks[track_idx] = true
        stay_homeless = true

      else

        -- see if we can retrieve fully expanded tracks from the cache
        -- for all relevant tracks (we then perform a simple copy)
        local simple_copy = true
        for t_idx = 1, rns.sequencer_track_count do
          --if self.active_slots[t_idx] then
          if self.poly_counter[t_idx] then
            local s_idx = (t_idx==track_idx) and seq_idx or self.active_slots[t_idx]
            local p_idx = rns.sequencer.pattern_sequence[s_idx]
            --local resolved_idx = self:resolve_patt_idx(p_idx,t_idx)
            local cached_length = self:get_pattern_cache(p_idx,t_idx)
            --print("GridPie:toggler() - cached_length",cached_length)
            if cached_length and (cached_length<lc) then
              simple_copy = false
            end
          end
        end
        --print("*** GridPie:toggler() - do simple_copy ? ",simple_copy)
        
        
        if simple_copy then

          -- simple copy, only the current track is affected
          -- use the cached pattern if available & sufficienty long,

          --print("*** GridPie:toggler() - Simple copy")

          -- changed the recombination pattern's length?
          local length_matched = (lc == gridpie_patt.number_of_lines)
          if not length_matched then
            gridpie_patt.number_of_lines = lc
            self:_keep_the_beat(old_lines,old_pos)
          end

          self:alias_slot(track_idx,alias_p_idx)
          
        else

          -- complex copy, other tracks might have been  
          -- affected and should be expanded as well...
          
          --print("*** GridPie:toggler() - Complex copy")
          
          gridpie_patt.number_of_lines = self:_restrict_to_pattern_length(lc)
          self:_keep_the_beat(old_lines,old_pos)

          --if old_lines < gridpie_patt.number_of_lines then
            for idx=1, rns.sequencer_track_count do

              --print("*** self.poly_counter[",track_idx,"]",self.poly_counter[track_idx])
              if not self.poly_counter[idx] then
                --print("*** skip inactive track")
              else
                --print("*** complex copy - self.poly_counter[",idx,"]",self.poly_counter[idx])
                if idx == track_idx then
                  self:alias_slot(track_idx,alias_p_idx)
                end
                local slot_alias_idx = self:resolve_patt_idx(self.gridpie_patt_idx,idx)
                --print("*** slot_alias_idx",slot_alias_idx)
                local cached_lines = self:get_pattern_cache(slot_alias_idx,idx)
                --print("*** cached_lines",cached_lines)
                if cached_lines and 
                  (cached_lines < gridpie_patt.number_of_lines) 
                then
                  self.skip_gp_notifier = true
                  TRACE("GridPie:Expanding track ",idx,"with patt_idx",slot_alias_idx,"from",self.poly_counter[idx],"to",gridpie_patt.number_of_lines,"lines") 
                  self:copy_and_expand(slot_alias_idx,nil,idx,self.poly_counter[idx],nil,gridpie_patt.number_of_lines)
                  self.skip_gp_notifier = false
                else
                  --print("*** skip expanding track ",idx,", length is sufficient (",cached_lines,")")
                end
              end
            end
            
          --end
          
        end

      end
      
    else
      --print("*** toggler - no grid pie tracks available")
    end
  end

  -- nullify playpos if active tracks aren't all
  -- aligned to the same sequence position
    --[[
  local nullify = false
  for idx = 1, rns.sequencer_track_count do
    if (self.active_slots[idx] ~= self._aligned_playpos) then
      if self.poly_counter[idx] then
        nullify = true
      end
    end
    if nullify then
      -- cancel scheduled pattern & enable loop
      self._aligned_playpos = nil
      if not renoise.song().transport.loop_pattern then
        self:cancel_scheduled_pattern()
      end
      renoise.song().transport.loop_pattern = true
      break
    end
  end
  --print("*** toggler - self._aligned_playpos",self._aligned_playpos)
    ]]

  self:_update_pm_mutes(seq_idx,track_idx,muted)
  self.active_slots[track_idx] = seq_idx
  if not stay_homeless then
    self.homeless_tracks[track_idx] = nil
  end

  return muted

end

--------------------------------------------------------------------------------

--- Toggle a particular pattern

function GridPie:_toggle_pattern(seq_idx,track_idx)
  TRACE("GridPie:_toggle_pattern()",seq_idx,track_idx)

  local rns = renoise.song()
  local patt_idx = rns.sequencer:pattern(seq_idx)
  local source_patt = rns.patterns[patt_idx]
  local gridpie_patt = rns.patterns[self.gridpie_patt_idx]
  local old_lines = gridpie_patt.number_of_lines
  local old_pos = rns.transport.playback_pos

  local muted = self:can_mute_pattern(seq_idx)
  --print("*** muted",muted)
  if muted then
    -- mute/clear pattern, nullify playpos
    for t_idx=1,rns.sequencer_track_count do
      self:clear_track(t_idx)
    end
    self._aligned_playpos = nil

  else
    -- copy/import the pattern 
    local patt_idx = rns.sequencer:pattern(seq_idx)
    for track_idx = 1,rns.sequencer_track_count do
      local alias_p_idx = self:resolve_patt_idx(patt_idx,track_idx)
      gridpie_patt.tracks[track_idx].alias_pattern_index = alias_p_idx
      -- todo: copy-expand if needed?
    end

    -- toggling a pattern will align the slots
    self._aligned_playpos = seq_idx

  end

  -- update track poly-count (nullify when muted)
  for t_idx = 1, rns.sequencer_track_count do
    local alias_patt_idx = self:resolve_patt_idx(self.gridpie_patt_idx,t_idx)
    local alias_patt = rns.patterns[alias_patt_idx]
    self.poly_counter[t_idx] = (not muted) and 
      alias_patt.number_of_lines or nil 
  end

  -- update length of GP pattern
  local lc = least_common(self.poly_counter:values())
  --print("*** toggle pattern - lc",lc)
  if lc then
    gridpie_patt.number_of_lines = self:_restrict_to_pattern_length(lc)
  else
    gridpie_patt.number_of_lines = source_patt.number_of_lines 
  end
  -- adjust playback position
  self:_keep_the_beat(old_lines,old_pos)

  -- update PM mute state (do this _before_ active slots)
  self:_update_pm_mutes(seq_idx,nil,muted)

  -- update active slots 
  for t_idx = 1, rns.sequencer_track_count do
    self.active_slots[t_idx] = seq_idx
  end

  -- no track can be homeless at this point
  self.homeless_tracks = table.create()

  return muted

end

--------------------------------------------------------------------------------

--- Update PM mute state, called after toggling slot/pattern
-- @param seq_idx (number)
-- @param track_idx (number or nil), leave out to target the whole pattern
-- @param muted (boolean) true when we should mute the slot(s)

function GridPie:_update_pm_mutes(seq_idx,track_idx,muted)
  TRACE("GridPie:_update_pm_mutes()",seq_idx,track_idx,muted)

  local rns = renoise.song()
  for o = 1, rns.sequencer_track_count do
    local update_track = true
    if track_idx then
      if (track_idx~=o) then
        update_track = false
      end
    end
    if update_track then
      if self.active_slots[o] then
        -- change only affected slots (more efficient)
        self:mute_selected_track_slot(o)
        if rns.sequencer:pattern(seq_idx) then
          rns.sequencer:set_track_sequence_slot_is_muted(o , seq_idx, muted)
        end
      else
        -- loop through entire sequence
        --local total_sequence = #rns.sequencer.pattern_sequence
        local gridpie_seq_pos = self:get_gridpie_seq_pos()
        for i = 1, gridpie_seq_pos-1 do
          if i == seq_idx then
            rns.sequencer:set_track_sequence_slot_is_muted(o , i, muted)
          else
            rns.sequencer:set_track_sequence_slot_is_muted(o , i, true)
          end
        end
      end
    end
  end

end

--------------------------------------------------------------------------------

--- Build GUI Interface
-- equivalent to build_interface() in the original tool

function GridPie:_build_app()
  TRACE("GridPie:_build_app()")

  local rns = renoise.song()

  -- determine grid size by looking at the control-map
  local cm = self.display.device.control_map
  if (self.mappings.grid.group_name) then
    self.matrix_width = cm:count_columns(self.mappings.grid.group_name)
    self.matrix_height = cm:count_rows(self.mappings.grid.group_name)
  else
    local msg = "GridPie cannot initialize, the required mapping 'grid' is missing"
    renoise.app():show_warning(msg)
    return false
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
    for x = 1, self.matrix_width do
      self.MATRIX_CELLS[x] = table.create()
      for y = 1, self.matrix_height do

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
            if not self.active then 
              return false 
            end
            local bt = self.held_buttons[x][y]
            local gp_seq_idx = self:get_gridpie_seq_pos()
            if self.src_button and (bt.obj == self.src_button.obj) then
              --print("*** the first pressed button was released")
              if (bt.seq_idx == gp_seq_idx) then
                --print("*** GP slot released",x,y)
                if not bt.void then
                  if self.homeless_tracks[bt.track_idx] then
                    renoise.app():show_status("Grid Pie: homeless button released, clone pattern")
                    self:clone_pattern()
                  else
                    renoise.app():show_status("Grid Pie: GP button released, resolve alias")
                    self:goto_slot(bt.track_idx)
                  end
                --else
                --  print("*** GP slot void, do nothing...")
                end
              else
                --print("*** normal slot released",x,y)
                if not bt.void then
                  renoise.app():show_status("Grid Pie: button released, toggle slot")
                  self:toggler(x,y)
                --else
                --  print("*** normal slot void, do nothing...")
                end
              end
              self.src_button = nil
              --print("*** source button released")
            end

            self.held_buttons[x][y] = nil
            --print("*** self.held_buttons["..x.."]...")
            --rprint(self.held_buttons[x])
            --print("*** self.src_button",self.src_button)

          end
          c.on_hold = function(obj) 
            if not self.active then 
              return false 
            end
            local bt = self.held_buttons[x][y]
            local gp_seq_idx = self:get_gridpie_seq_pos()
            if (self.held_buttons[x][y].seq_idx == gp_seq_idx) then
              --print("*** GP slot held",x,y)
              if self.src_button and (bt.obj == self.src_button.obj) then
                --print("*** GP slot is the first pressed button")
                if not bt.void then
                  renoise.app():show_status("Grid Pie: GP button held, clone pattern")
                  self:clone_pattern()
                  bt.void = true
                --else
                --  print("*** GP slot void, do nothing...")
                end
              end
            else
              --print("*** normal slot held",x,y)
              if self.src_button and (bt.obj == self.src_button.obj) then
                --print("*** normal slot is the first pressed button")
                if not bt.void then
                  renoise.app():show_status("Grid Pie: button held, switch to pattern")
                  self:toggler(x,y,true)
                  bt.void = true
                --else
                --  print("*** normal slot void, do nothing...")
                end
              else
                --print("*** normal slot is held after...")
                --if self.src_button and not self.src_button.void then
                if self.src_button and not bt.void then
                  renoise.app():show_status("Grid Pie: second button held, force assign")
                  self:assign_to_slot(bt,true)
                  --[[
                  if (self.src_button.seq_idx == gp_seq_idx) then
                    renoise.app():show_status("normal slot is held after GP was pressed, force assign...")
                    self:assign_to_slot(bt,true)
                  else
                    renoise.app():show_status("normal slot is held after normal slot, force assign")
                    self:assign_to_slot(bt,true)
                  end
                  ]]
                end
              end
            end

          end
          c.on_press = function(obj) 
            if not self.active then 
              return false 
            end
            --print("obj",obj)
            local gp_seq_idx = self:get_gridpie_seq_pos()
            local ptrack,t_idx,s_idx = self:get_ptrack_from_coords(x,y,true)
            --print("self.held_buttons["..x.."]",self.held_buttons[x])
            self.held_buttons[x][y] = {
              obj = obj,
              ptrack = ptrack,
              track_idx = t_idx,
              seq_idx = s_idx,
              void = false
            }
            local bt = self.held_buttons[x][y]
            if not self.src_button then
              --print("*** the first pressed button",x,y)
              self.src_button = bt
            elseif (self.src_button.obj ~= obj) then
              local same_track = (bt.track_idx == self.src_button.track_idx)
              if not same_track then
                --print("*** not the same track, void the source")
                self.src_button.void = true
              else
                --print("*** any other button after the first")
                -- if any button in the same track was pressed, 
                -- flag it as "void" to suppress it's event
                for i = 1, self.matrix_height do
                  local tmp_bt = self.held_buttons[x][i]
                  if (i~=y) and tmp_bt then
                    --print("*** button at position ",i,"flagged as void")
                    tmp_bt.void = true
                  end
                end
                if (self.src_button.seq_idx == gp_seq_idx) then
                  --print("*** normal slot is pressed after GP was pressed, assign...")
                  if not self:assign_to_slot(bt) then
                    renoise.app():show_status("Grid Pie: slot-assignment failed, try with force")
                    bt.void = false
                  else
                    renoise.app():show_status("Grid Pie: slot was assigned")
                  end
                elseif (bt.seq_idx == gp_seq_idx) then
                  renoise.app():show_status("*** make selected slot unique")
                  self:make_slot_unique(self.src_button.ptrack,bt.track_idx)
                else
                  --print("*** normal slot is pressed after normal slot, assign")
                  if not self:assign_to_slot(bt) then
                    renoise.app():show_status("Grid Pie: slot-assignment failed, try with force")
                    bt.void = false
                  else
                    renoise.app():show_status("Grid Pie: slot was assigned")
                  end
                end
              end
            end

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

--- A unified method for multi-touch assign/unassign of slot aliases
-- @param bt (table) a table which contain details about the pressed button
-- @param force (boolean) force-assign (otherwise, unique slots are left alone)
-- @return boolean, true when assigned, false when we need to force-assign

--function GridPie:assign_to_slot(x,y,force)
function GridPie:assign_to_slot(bt,force)
  TRACE("GridPie:assign_to_slot()",bt,force)

  local rns = renoise.song()
  local gp_seq_idx = self:get_gridpie_seq_pos()
  local gp_patt_idx = rns.sequencer:pattern(gp_seq_idx)

  if not gp_patt_idx then
    --print("*** assign_to_slot: ouch, could not locate gridpie pattern...")
    return
  end

  --local target_ptrack,target_track_idx,target_seq_idx = self:get_ptrack_from_coords(x,y,true)
  local target_ptrack = bt.ptrack
  local target_track_idx = bt.track_idx
  local target_seq_idx = bt.seq_idx
  local target_patt_idx = rns.sequencer:pattern(target_seq_idx)
  local source_is_gp = (self.src_button.seq_idx == gp_seq_idx)
  local target_is_gp = (target_seq_idx == gp_seq_idx)
  --print("*** source_is_gp",source_is_gp)
  --print("*** target_is_gp",target_is_gp)

  if source_is_gp then
    --print("*** source_is_gp, try to assign content to the pressed slot")
    
    local resolved_idx = self:resolve_patt_idx(target_patt_idx,target_track_idx)
    local dest_patt = rns.patterns[resolved_idx]
    local dest_slot = dest_patt.tracks[target_track_idx]

    if dest_slot and (force or dest_slot.is_alias or dest_slot.is_empty) then

      local gp_patt = rns.patterns[gp_patt_idx]
      local gp_slot = gp_patt.tracks[target_track_idx]

      if not self.homeless_tracks[target_track_idx] then 
        -- make gp content unique before copying
        self:make_slot_unique(gp_slot,target_track_idx)
      end

      self.skip_gp_notifier = true
      dest_slot:copy_from(gp_slot)
      self.skip_gp_notifier = false
      self:alias_slot(target_track_idx,resolved_idx)
      self.homeless_tracks[target_track_idx] = nil

      -- update the mute state of the matrix 
      self:mute_selected_track_slot(target_track_idx)
      self.active_slots[target_track_idx] = target_seq_idx
      rns.sequencer:set_track_sequence_slot_is_muted(target_track_idx,target_seq_idx,false)
      self.update_requested = true
    else
      --print("*** ignore, target slot is unique (use 'force' to assign)")
      return false
    end
    --end

  elseif not self.src_button.ptrack then
    -- cannot continue
    --print("*** cannot assign, as source has no pattern-track")
  elseif target_is_gp then
    -- grid-pie pattern, make unique (un-alias)
    --print("*** make slot unique (un-alias)")
    if self:make_slot_unique(self.src_button.ptrack,target_track_idx) then
      self.update_requested = true
    end

  elseif target_ptrack and 
    --(force or self.src_button.ptrack.is_empty or self.src_button.ptrack.is_alias) 
    (force or target_ptrack.is_empty or target_ptrack.is_alias) 
  then
    -- button in the same track (normal/force-assign)
    
    local resolved_src_patt_idx = self:resolve_patt_idx(self.src_button.seq_idx,self.src_button.track_idx)

    if not target_ptrack.is_alias and
      (target_patt_idx == resolved_src_patt_idx) 
    then
      --print("*** do not assign alias to itself")
    elseif (target_ptrack.alias_pattern_index == resolved_src_patt_idx) then
      --print("*** do not assign an alias which is already assigned")
    else
      -- if we force-assign, clear any existing alias
      if target_ptrack.is_alias then
        target_ptrack.alias_pattern_index = 0
      end
      --print("*** copy into source from this pattern/track",resolved_src_patt_idx,target_track_idx)
      target_ptrack.alias_pattern_index = resolved_src_patt_idx
      -- if the target is active in gridpie, update gridpie as well
      if self.poly_counter[target_track_idx] and
        (self.active_slots[target_track_idx] == target_seq_idx) 
      then
        --print("*** update gridpie as well")
        self:alias_slot(target_track_idx,resolved_src_patt_idx)
      end
      -- update grid display (highlight master)
      -- (todo: skip this if master is outside grid)
      self.update_requested = true

    end
  else
    --print("*** ignore, target slot is unique (use 'force' to assign)")
    return false
  end

  return true

end

--------------------------------------------------------------------------------

--- Start application 

function GridPie:start_app(start_running)
  TRACE("GridPie:start_app()",start_running)

  -- this step will ensure that the application is properly mapped,
  -- after which it will call the build_app() method
  if not Application.start_app(self,start_running) then
    return
  end

  if start_running and
    (self.options.initialization.value == self.AUTOSTART_MANUAL) 
  then
    --print("AUTOSTART_MANUAL, application was halted...")
    self.active = false
    return
  end

  self._has_been_started = true

  local rns = renoise.song()

  -- initialize important stuff
  self:reset_tables()
  self:_set_page_sizes() 
  self.poly_counter = table.create()
  self:init_pm_slots_to(true)
  self:init_gp_pattern()
  self:build_cache()
  self:set_writeahead()

  self._track_count = rns.sequencer_track_count

  -- attach notifiers (after we have init'ed GP pattern!)
  local new_song = true
  self:_attach_to_song(new_song)

  -- adjust the Renoise interface
  renoise.app().window.pattern_matrix_is_visible = true
  rns.transport.follow_player = false

  -- start playing as soon as we have initialized?
  if (self.options.initialization.value == self.AUTOSTART_PLAY) then
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

    -- remove line notifiers from gridpie pattern
    self:_remove_line_notifiers()
    
    -- remove remaining notifiers
    local new_song = false
    self:_remove_notifiers(new_song,self._pattern_observables)
    self:_remove_notifiers(new_song,self._song_observables)

    -- clear housekeeping tables
    self:reset_tables()

    -- optional shutdown procedure
    if (self.options.shutdown.value == self.SHUTDOWN_CLEAR_ALL) then
      local gp_seq_idx = self:get_gridpie_seq_pos()
      local gp_patt_idx = rns.sequencer:pattern(gp_seq_idx)
      local gp_patt = rns.patterns[gp_patt_idx]
      rns.sequencer:delete_sequence_at(gp_seq_idx)
    end

  end

  self._has_been_started = false

  Application.stop_app(self)

end


--------------------------------------------------------------------------------

--- Abort (sleep during idle time and ignore any user input)

function GridPie:abort(notification)
  TRACE("GridPie:abort()",notification)

  self.active = false
  renoise.app():show_message("You dun goofed! Grid Pie needs to be restarted.")
  self._process.browser:stop_current_configuration()


end

--------------------------------------------------------------------------------

--- Attach line notifier to selected pattern, including any aliased patterns

function GridPie:_attach_line_notifiers()
  TRACE("GridPie:_attach_line_notifiers()")

  local rns = renoise.song()
  local patt_idx = rns.selected_pattern_index
  local patt = rns.patterns[patt_idx]

  -- remove, then attach new notifiers
  self:_remove_line_notifiers()
  for track_idx = 1,rns.sequencer_track_count do

    local resolved_idx = self:resolve_patt_idx(patt_idx,track_idx)
    local patt = rns.patterns[resolved_idx]

    if not (patt:has_line_notifier(self._track_changes,self))then
      self._line_notifiers[resolved_idx] = true
      patt:add_line_notifier(self._track_changes,self)
      --print("*** attach line notifier to source pattern #",resolved_idx)

    end
  end
end




--------------------------------------------------------------------------------

--- Remove current set of line notifiers

function GridPie:_remove_line_notifiers()

  local rns = renoise.song()

  for patt_idx,_ in pairs(self._line_notifiers) do

    --print("*** _remove_line_notifiers: _,patt_idx",_,patt_idx)

    --local patt_idx = rns.sequencer.pattern_sequence[self._current_seq_index]
    local patt = rns.patterns[patt_idx]
    if patt then
      if (rns.selected_sequence_index ~= self._current_seq_index) and
        (patt:has_line_notifier(self._track_changes,self)) then
        patt:remove_line_notifier(self._track_changes,self)
        --print("*** removed line notifier from source pattern")
      end
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
-- @param pos (table with fields "pattern", "track" and "line")

function GridPie:_track_changes(pos)

  if not self.active then
    return
  end 

  if self.skip_gp_notifier then
    --print("GridPie:_track_changes - bypassed line notifier")
    return
  end

  --TRACE("GridPie:_track_changes()",pos)

  local rns = renoise.song()

  if (pos.track > rns.sequencer_track_count) then
    --print("*** track_changes - ignore changes to non-sequencer tracks")
    return
  end


  -- check if change was fired from the combination pattern
  -- by looking at the position in the pattern sequence
  local gp_seq_idx = self:get_gridpie_seq_pos()
  local is_gp_patt = gp_seq_idx == rns.selected_sequence_index
  --print("*** track_changes - is_gp_patt",is_gp_patt)
  local gp_patt = rns.patterns[self.gridpie_patt_idx]

  if is_gp_patt then

    -- change happened in recombination pattern,
    -- perform a full copy-expand if needed

    -- check if we have initiated/emptied a homeless track
    if not self.poly_counter[pos.track] then
      renoise.app():show_status("Grid Pie: cannot synchronize changes, unspecified source track...")
      local ptrack = gp_patt.tracks[pos.track]
      if ptrack.is_empty then
        self._blink = false
        self:update_homeless_tracks()
        self.homeless_tracks[pos.track] = nil
      else
        self.homeless_tracks[pos.track] = true
      end
      --print("*** self.homeless_tracks[",pos.track,"] set to",self.homeless_tracks[pos.track])

      --rprint(self.homeless_tracks)
      return
    else
      --print("*** copy and expand changes onto itself...")
      self:_add_pending_update(self.gridpie_patt_idx,pos)

    end

  elseif self.poly_counter[pos.track] then

    -- change happened somewhere in the song
    -- (track changes only if active)
          local source_patt = rns.patterns[pos.pattern]
      local gp_ptrack = gp_patt.tracks[pos.track]
      if (pos.pattern==gp_ptrack.alias_pattern_index) then
        -- the source pattern-track is grid-pie'd 
        if source_patt and 
          (source_patt.number_of_lines == gp_patt.number_of_lines) 
        then
          --print("*** track_changes: same size - no copying is needed")
        else
          --print("*** track_changes: different size - copy and expand")
          self:_add_pending_update(pos.pattern,pos)
        end
      end
  else
    --print("*** track_changes: ignore change to this pattern-track")

  end


end


--------------------------------------------------------------------------------

--- Determine if a given pattern-track is aliased
-- @return Number, the aliased pattern index (or the original one)

function GridPie:resolve_patt_idx(patt_idx,track_idx)
  --TRACE("GridPie:resolve_patt_idx()",patt_idx,track_idx)

  local patt = nil
  local tmp_idx = patt_idx
  while (tmp_idx~=0) do
    patt_idx = tmp_idx
    patt = renoise.song().patterns[tmp_idx]
    tmp_idx = patt.tracks[track_idx].alias_pattern_index
  end
  --TRACE("GridPie:resolve_patt_idx() - patt_idx,track_idx",patt_idx,track_idx,"=patt_idx",patt_idx)
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

--- To display homeless tracks, we call this method

function GridPie:update_homeless_tracks()

  local rns = renoise.song()

  if (table_count(self.homeless_tracks) == 0) then
    return
  end

  -- iterate through tracks
  local lower_track = self.x_pos
  local upper_track = self.x_pos + self.matrix_width
  local lower_seq = self.y_pos
  local upper_seq = self.y_pos + self.matrix_height
  local gridpie_seq_pos = self:get_gridpie_seq_pos()
  
  --print("lower_seq,upper_seq,gridpie_seq_pos",lower_seq,upper_seq,gridpie_seq_pos)

  for track_idx,_ in pairs(self.homeless_tracks) do
    -- check if the track is visible on the controller
    local track_is_visible = (track_idx>=lower_track) and (track_idx<upper_track)
    local is_changed = false
    --print("*** update_homeless_tracks - track_idx,track_is_visible",track_idx,track_is_visible)
    if track_is_visible then
      local seq_is_visible = (gridpie_seq_pos>=lower_seq) and (gridpie_seq_pos<upper_seq)
      if seq_is_visible then
        local cell_y = gridpie_seq_pos%self.matrix_height
        if (cell_y == 0) then
          cell_y = self.matrix_height
        end 
        local cell = self:matrix_cell(track_idx,cell_y)
        --print("*** update_homeless_tracks - seq_is_visible,cell_y",seq_is_visible,cell_y)
        if self._blink then
            cell:set(self.palette.gridpie_homeless)
        else
          self:paint_cell(cell,track_idx,cell_y)
        end
      end

    end
  end

end

--------------------------------------------------------------------------------

--- Call this to toggle the blinking state of a scheduled pattern
-- @param clear (boolean) call this to clear the display
--[[
function GridPie:update_scheduled_pattern(clear)
  --TRACE("GridPie:update_scheduled_pattern()",clear)

  if not clear and not self.scheduled_seq_idx then
    --print("GridPie:update_scheduled_pattern - nothing to do, aborting...")
    return
  end

  if clear and not self._blink then
    --print("GridPie:update_scheduled_pattern - no need to clear, aborting...")
    return
  end

  if self._aligned_playpos and 
    (self.scheduled_seq_idx == self._aligned_playpos) 
  then
    --print("GridPie:update_scheduled_pattern- scheduled pattern is already active, aborting...")
    return
  end

  local rns = renoise.song()

  -- check that the sequence is in visible range
  local seq_end = self.y_pos + self.matrix_height
  local trk_end = self.x_pos + self.matrix_width
  local trk_in_range,seq_in_range = false,false
  if self._highlight_position then
    seq_in_range = (self.scheduled_seq_idx>=self.y_pos) and (self.scheduled_seq_idx<seq_end) 
  end
  if not seq_in_range then
    print("GridPie:update_scheduled_pattern- sequence not in range, aborting...")
    return
  end

  -- iterate through tracks
  for track_idx = 1, rns.sequencer_track_count do
      
    local ptrack = rns.patterns[self.scheduled_seq_idx].tracks[track_idx]
    trk_in_range = (track_idx>=self.x_pos) and (track_idx<trk_end) 
    if trk_in_range then
      
      local grid_y = self.scheduled_seq_idx%self.matrix_height
      grid_y =  (grid_y==0) and self.matrix_height or grid_y
      local cell = self:matrix_cell(track_idx,grid_y)
      if cell then
        if not clear and self._blink then
          -- lit, just paint the tracks
          if ptrack.is_empty then
            cell:set(self.palette.empty_active)
          else
            cell:set(self.palette.content_selected)
          end
        else
          -- unlit, call the "full" method        
          self:paint_cell(cell,track_idx,grid_y)
        end
      end

    end

  end

end
]]
--------------------------------------------------------------------------------

--- Handle idle updates 
--  (idler() in original tool)

function GridPie:on_idle()

  if not self.active then
    return
  end

  local rns = renoise.song()
  local gridpie_seq_pos = self:get_gridpie_seq_pos()
  local gridpie_patt_idx = rns.sequencer:pattern(gridpie_seq_pos)
  local playing_pos = rns.transport.playback_pos.sequence

  -- session recording: check if we have arrived at the new gp pattern
  if self.gp_buffer_seq_pos and (self.gp_buffer_seq_pos ~= playing_pos) then
    -- mute the previous gp slots 
    for t_idx = 1,rns.sequencer_track_count do
      rns.sequencer:set_track_sequence_slot_is_muted(t_idx,self.gp_buffer_seq_pos,true)
    end
    self.gp_buffer_seq_pos = nil
    self.gp_buffer_patt_idx = nil
  end

  -- always make sure gridpie pattern is present
  -- (soft check, allow a #copy of the GP pattern to be 
  -- present until picked up by the sequence_notifier)
  if rns.patterns[gridpie_patt_idx].name:find(self.GRIDPIE_NAME) == nil then
    self:abort()
  end
  --[[
  if rns.patterns[gridpie_patt_idx].name ~= self.GRIDPIE_NAME then
    self:abort()
  end
  ]]

  -- realtime output, have we travelled far enough? 
  if self.realtime_record then
    local playback_line = rns.transport.playback_pos.line
    for track_idx,trk in pairs(self.realtime_tracks) do
      if trk.crossed_boundary and (playback_line < trk.last_output_pos) then
        trk.crossed_boundary = false
        trk.last_output_pos = -self.writeahead_interval
        --print("*** continue incremental output from playback_line",playback_line)
      end
      if not trk.crossed_boundary then
        local check_line = trk.last_output_pos + self.writeahead_interval
        if (check_line < playback_line) then
          self:incremental_update(track_idx)
        end
      end
    end
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
    local seq_pos_changed = (self._playing_seq_idx~=playing_pos)
    if (playing_pos~=gridpie_seq_pos) and
      (playing_pos~= self.gp_buffer_seq_pos)
    then 
      --print("*** we have moved to a pattern outside gridpie",playing_pos)

      -- determine if this is the result of a scheduled 
      -- pattern (a huge hack, since we cannot reliably 
      -- determine the schedule list)

      --if seq_pos_changed and not rns.transport.follow_player then
      if seq_pos_changed then
        --print("*** switch to this sequence-position",playing_pos)
        local y_pos = playing_pos-self.y_pos+1
        self:toggler(1,y_pos,true)
      end

      rns.transport.follow_player = false
      self:playback_pos_to_gridpie()

    end

    if seq_pos_changed then
      self._playing_seq_idx = playing_pos
    end

  end

  if self.play_requested then
    self.play_requested = false
    rns.transport.playing = true
  end

  -- do stuff at a certain rate (seconds) 
  local blink = (math.floor(os.clock()*2)%2==0) and true or false
  if (blink ~= self._blink) then
    self._blink = blink
    self:update_homeless_tracks()
    --self:update_scheduled_pattern()
  end

  --[[
  if rns.transport.playing then
    -- use playback line number 
    local lpb = rns.transport.lpb
    local pos = rns.transport.playback_pos 
      or rns.transport.edit_pos
    blink = (math.floor((((pos.line-2)/lpb)+1)%2)==1)
  else -- use the clock 
    blink = (math.floor(os.clock()*2)%2==0) and true or false
  end
  ]]

end

--------------------------------------------------------------------------------

--- Call this to produce output for one of the realtime tracks

function GridPie:incremental_update(track_idx)
  TRACE("GridPie:incremental_update()",track_idx)

  local rns = renoise.song()
  local rt_trk = self.realtime_tracks[track_idx]
  if not rt_trk then
    --print("*** incremental_update - cannot update track",track_idx)
    return
  end

  local start_line = rns.transport.playback_pos.line
  local end_line = start_line + self.writeahead_length

  -- if we have a buffer gp pattern, we should output to that one
  local gridpie_patt = rns.patterns[self.gridpie_patt_idx]
  if self.gp_buffer_patt_idx then
    gridpie_patt = rns.patterns[self.gp_buffer_patt_idx]
  end

  self.skip_gp_notifier = true

  -- todo: optimize by setting the start line to the last output

  if not self.poly_counter[track_idx] then
    --print("*** slot is turned off, clear lines")
    self:clear_lines(track_idx,self.gridpie_patt_idx,start_line,end_line)
  else
    --print("*** realtime output ",track_idx," from patt_idx",rt_trk.src_patt_idx," to dest patt_idx",self.gridpie_patt_idx," from line #",start_line," to #",end_line) 
    self:copy_and_expand(rt_trk.src_patt_idx,self.gridpie_patt_idx,rt_trk.track_idx,nil,nil,gridpie_patt.number_of_lines,start_line,end_line)
  end

  rt_trk.last_output_pos = rns.transport.playback_pos.line

  -- check if the next update would meet/cross the pattern boundary
  local next_output_line = rt_trk.last_output_pos + self.writeahead_interval
  local crossed_boundary = (next_output_line >= gridpie_patt.number_of_lines)
  if crossed_boundary then
    --print("*** crossed_boundary")
    local dst_patt_idx = self.gridpie_patt_idx
    if not rns.transport.loop_pattern then
      -- "session recording" (when pattern is not looped)
      -- check if we have already created a copy of the GP pattern,
      local new_gp_seq_pos = self:get_gridpie_seq_pos()
      if not self.gp_buffer_seq_pos then
        self:clone_pattern()
        self.gp_buffer_seq_pos = new_gp_seq_pos
        self.gp_buffer_patt_idx = self.gridpie_patt_idx
        new_gp_seq_pos = new_gp_seq_pos+1
      end
      --print("*** self.gp_buffer_seq_pos",self.gp_buffer_seq_pos)
      -- set the target to the new pattern
      dst_patt_idx = rns.sequencer:pattern(new_gp_seq_pos)
      -- prepare "record-tracks" (empty/unique)
      local new_gp_patt = rns.patterns[dst_patt_idx]
      for track_idx,trk in pairs(self.realtime_tracks) do
        new_gp_patt.tracks[track_idx].alias_pattern_index = 0
        --print("*** prepared record-track ",track_idx," in new gp pattern ",dst_patt_idx)
      end
    end
    -- extend into beginning of pattern & reset the output_pos
    start_line = 1
    end_line = self.writeahead_length

    if not self.poly_counter[track_idx] then
      --print("*** slot is turned off, clear lines")
      self:clear_lines(track_idx,dst_patt_idx,start_line,end_line)
    else
      --print("*** realtime output ",track_idx," from patt_idx",rt_trk.src_patt_idx," to dest patt_idx",dst_patt_idx," from line #",start_line," to #",end_line) 
      self:copy_and_expand(rt_trk.src_patt_idx,dst_patt_idx,rt_trk.track_idx,nil,nil,nil,start_line,end_line)
    end

    rt_trk.crossed_boundary = true


  end

  self.skip_gp_notifier = false

end


--------------------------------------------------------------------------------

--- Quick'n'dirty method for obtaining the gridpie sequence index
-- (it will not check if the pattern is actually the right one)

function GridPie:get_gridpie_seq_pos()

  return #renoise.song().sequencer.pattern_sequence

end


--------------------------------------------------------------------------------

--- Determine if edit-position is inside the __GRID PIE__ pattern
-- @return boolean

function GridPie:edit_pos_in_gridpie()

  local rns = renoise.song()
  local gridpie_seq_pos = self:get_gridpie_seq_pos()
  local last_patt_idx = rns.sequencer:pattern(gridpie_seq_pos)
  local rslt = (last_patt_idx == rns.selected_pattern_index) 
  return rslt

end


--------------------------------------------------------------------------------

--- Mute existing selected slot (if any) in the pattern matrix

function GridPie:mute_selected_track_slot(track_idx)

  local rns = renoise.song()
  if rns.sequencer.pattern_sequence[self.active_slots[track_idx]] then
    rns.sequencer:set_track_sequence_slot_is_muted(
      track_idx,self.active_slots[track_idx],true)
  end

end

--------------------------------------------------------------------------------

--- Determine the x-position of a track within the grid

function GridPie:get_grid_x_pos(track_idx)

  local pos = (track_idx%self.matrix_width) + (self.x_pos%self.matrix_width) - 1
  if (pos == 0) then
    pos = self.matrix_width
  end
  return pos
end

--------------------------------------------------------------------------------

--- Determine the y-position of a pattern within the grid

function GridPie:get_grid_y_pos(patt_idx)

  local pos = (patt_idx%self.matrix_height) + (self.y_pos%self.matrix_height) - 1
  if (pos == 0) then
    pos = self.matrix_height
  end
  return pos

end


--------------------------------------------------------------------------------

--- Move playback position to the __GRID PIE__ pattern
-- @param restart (Boolean) force pattern to play from the beginning

function GridPie:playback_pos_to_gridpie(restart)
  TRACE("GridPie:playback_pos_to_gridpie()",restart)

  local rns = renoise.song()
  local gp_seq_pos = self:get_gridpie_seq_pos()
  if (rns.transport.playback_pos.sequence==gp_seq_pos) then
    return
  end

  local gp_patt = rns.patterns[self.gridpie_patt_idx]
  local songpos = rns.transport.playback_pos
  songpos.sequence = gp_seq_pos

  if songpos.line > gp_patt.number_of_lines then
    songpos.line = gp_patt.number_of_lines 
  end
  if restart and (songpos.sequence~=gp_seq_pos) then
    -- when started outside the __GRID PIE__ pattern, play
    -- from the last line (so the next one is the first)
    songpos.line = gp_patt.number_of_lines 
  end

  rns.transport.playback_pos = songpos

end

--------------------------------------------------------------------------------

--- Update the "gridpie_patt_idx" property

function GridPie:_maintain_gridpie_reference()
  TRACE("GridPie:_maintain_gridpie_reference()")

  local rns = renoise.song()
  local gp_seq_pos = self:get_gridpie_seq_pos()
  local gp_patt_idx = rns.sequencer:pattern(gp_seq_pos)
  local gp_patt = rns.patterns[gp_patt_idx]
  if (gp_patt.name == self.GRIDPIE_NAME) then
    self.gridpie_patt_idx = rns.sequencer.pattern_sequence[gp_seq_pos]
    --print("*** _maintain_gridpie_reference - self.gridpie_patt_idx",self.gridpie_patt_idx)
  end

end

--------------------------------------------------------------------------------

--- Prepare a bunch of values/tables

function GridPie:reset_tables()

  self.src_button = nil
  self.patt_cache = table.create()
  self.revert_pm_slot = table.create()
  self.active_slots = table.create()
  self.homeless_tracks = table.create()
  self.held_buttons = table.create()
  for x=1,self.matrix_width do
    self.held_buttons[x] = table.create()
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
      local gridpie_seq_pos = self:get_gridpie_seq_pos()
      self._track_count = rns.sequencer_track_count

      if (notification.type == "insert") then

        -- maintain matrix revert-state / active slots / poly-counter
        for idx = rns.sequencer_track_count-1, 1, -1 do
          if (idx>=notification.index) then
            self.active_slots[idx+1] = self.active_slots[idx]
            self.homeless_tracks[idx+1] = self.homeless_tracks[idx]
            self.poly_counter[idx+1] = self.poly_counter[idx]
            self.revert_pm_slot[idx+1] = self.revert_pm_slot[idx]
          end
          if (idx==notification.index) then
            self.active_slots[idx] = self._aligned_playpos or 1
            self.homeless_tracks[idx] = nil
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
              local alias_p_idx = self:resolve_patt_idx(patt_idx,idx)
              local alias_patt = rns.patterns[alias_p_idx]
              self.patt_cache[patt_idx][idx] = alias_patt.number_of_lines
            end
          end
        end

        -- mute the newly inserted track
        for i = 1, gridpie_seq_pos do
          rns.sequencer:set_track_sequence_slot_is_muted(notification.index , i, true)
        end

      elseif (notification.type == "remove") then

        local trk_count = rns.sequencer_track_count

        -- maintain matrix revert-state / active slots / poly-counter
        for idx=1, trk_count do
          if (idx>=notification.index) then
            self.active_slots[idx] = self.active_slots[idx+1]
            self.homeless_tracks[idx] = self.homeless_tracks[idx+1]
            self.poly_counter[idx] = self.poly_counter[idx+1]
            self.revert_pm_slot[idx] = self.revert_pm_slot[idx+1]
          end
        end
        self.active_slots[trk_count+1] = nil
        self.homeless_tracks[trk_count+1] = nil
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
      local gridpie_seq_pos = self:get_gridpie_seq_pos()
      if (notification.type == "remove") then

        -- maintain matrix revert-state 
        --local seq_len = #rns.sequencer.pattern_sequence
        for x = 1, rns.sequencer_track_count do
          for y=notification.index,gridpie_seq_pos do
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
        --local gridpie_seq_pos = self:get_gridpie_seq_pos()
        local gp_patt_idx = rns.sequencer.pattern_sequence[gridpie_seq_pos]
        local gp_patt = rns.patterns[gp_patt_idx]
        if (notification.index == gridpie_seq_pos) and 
          gp_patt.name:find(self.GRIDPIE_NAME) ~= nil 
        then
          --print("*** pattern_sequence_observable - dealing with a copy of the gridpie pattern")
          self:adapt_gridpie_pattern()
          return
        end

        -- maintain matrix revert-state 
        for x,_ in ripairs(self.revert_pm_slot) do
          for y=gridpie_seq_pos,notification.index,-1 do
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
          for idx = gridpie_seq_pos-2,1,-1 do
            if (idx>=notification.index) then
              self.patt_cache[idx+1] = table.rcopy(self.patt_cache[idx])
            end
            if (idx==notification.index) then
              self.patt_cache[idx] = nil
            end
          end
        end

        -- mute all slots in the new pattern,
        -- and add any unique slots to the cache
        local patt_idx = rns.sequencer.pattern_sequence[notification.index]
        local patt = rns.patterns[patt_idx]
        for track_idx = 1, rns.sequencer_track_count do
          rns.sequencer:set_track_sequence_slot_is_muted(track_idx,notification.index,true)
          local ptrack = rns.patterns[patt_idx].tracks[track_idx]
          if not ptrack.is_alias then
            self:set_pattern_cache(patt_idx,track_idx,patt.number_of_lines)
          end
        end
        

      end

      self:_maintain_gridpie_reference()
      self.v_update_requested = true

      -- maintain loop in pattern-sequence 
      rns.transport.loop_sequence_range = {gridpie_seq_pos,gridpie_seq_pos}

      -- always enforce position to gridpie pattern
      if rns.transport.playing then
        self:playback_pos_to_gridpie()
      end

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
      --[[
      elseif self.scheduled_seq_idx then
        self:update_scheduled_pattern(true)
        self.scheduled_seq_idx = nil
      ]]
      end
      self:check_recording_status()
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

        local page = math.floor((track_idx-1)/self.page_size_h)
        local new_x = page*self.page_size_h+1
        self:set_horizontal_pos(new_x)

      end

      self.update_requested = true

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

      self.update_requested = true

      self._current_seq_index = rns.selected_sequence_index

      -- attach pattern notifier
      local new_song = false
      self:_attach_to_pattern(new_song)

    end
  )

  self._song_observables:insert(rns.transport.loop_pattern_observable)
  rns.transport.loop_pattern_observable:add_notifier(self,
    function(app,notification)
      TRACE("GridPie:loop_pattern_observable fired...",notification)
      if not self.active then 
        return 
      end
      local rns = renoise.song()

      self:check_recording_status()

    end
  )


  self._song_observables:insert(rns.transport.edit_mode_observable)
  rns.transport.edit_mode_observable:add_notifier(self,
    function(app,notification)
      TRACE("GridPie:edit_mode_observable fired...",notification)
      if not self.active then 
        return 
      end
      self:check_recording_status()
    end
  )

  self._song_observables:insert(rns.transport.follow_player_observable)
  rns.transport.follow_player_observable:add_notifier(self,
    function(app,notification)
      TRACE("GridPie:follow_player_observable fired...",notification)
      if not self.active then 
        return 
      end
      self:check_recording_status()
    end
  )

  self._song_observables:insert(rns.transport.bpm_observable)
  rns.transport.bpm_observable:add_notifier(self,
    function(app,notification)
      TRACE("GridPie:bpm_observable fired...",notification)
      self:set_writeahead()
    end
  )

  self._song_observables:insert(rns.transport.lpb_observable)
  rns.transport.lpb_observable:add_notifier(self,
    function(app,notification)
      TRACE("GridPie:lpb_observable fired...",notification)
      self:set_writeahead()
    end
  )

  -- attach notifiers for pattern
  local new_song = true
  self:_attach_to_pattern(new_song)



end

--------------------------------------------------------------------------------

--- Attach notifiers to the pattern

function GridPie:_attach_to_pattern(new_song)
  TRACE("GridPie:_attach_to_pattern()")

  local rns = renoise.song()
  local patt = rns.patterns[rns.selected_pattern_index]

  -- remove notifier first 
  self:_remove_notifiers(new_song,self._pattern_observables)
  self._pattern_observables = table.create()

  -- attach line notifier for the pattern and it's aliases
  self:_attach_line_notifiers()

  -- attach number of lines observable
  self._pattern_observables:insert(patt.number_of_lines_observable)
  patt.number_of_lines_observable:add_notifier(self,
    function()
      TRACE("GridPie:number_of_lines_observable fired...")
      local rns = renoise.song()
      local patt_idx = rns.selected_pattern_index
      local seq_idx = rns.selected_sequence_index

      if (patt_idx == self.gridpie_patt_idx) then
        --print("*** GridPie: number_of_lines_observable - skip the recombination pattern")
        return
      end

      -- update the poly counter & cache length for affected slots
      if not self.patt_cache[patt_idx] then
        self.patt_cache[patt_idx] = table.create()
      end
      local patt = rns.patterns[patt_idx]
      for t_idx = 1, rns.sequencer_track_count do
        -- update existing cache entries for this pattern
        if self.patt_cache[patt_idx][t_idx] then
          --print("*** change self.patt_cache[",patt_idx,"][",t_idx,"]",self.patt_cache[patt_idx][t_idx],"into",patt.number_of_lines)
          self.patt_cache[patt_idx][t_idx] = patt.number_of_lines
        end
        -- update poly counter 
        local patt_seq = rns.sequencer.pattern_sequence
        local source_patt_idx = patt_seq[self.active_slots[t_idx]]
        if source_patt_idx and (source_patt_idx == patt_idx) then
          -- ??? use aliased value
          self.poly_counter[t_idx] = patt.number_of_lines 
          --print("*** self.poly_counter[",t_idx,"]",self.poly_counter[t_idx])
        end
      end
      local lc = least_common(self.poly_counter:values())
      if lc then
        local gp_patt = rns.patterns[self.gridpie_patt_idx]
        local old_lines = gp_patt.number_of_lines
        local old_pos = rns.transport.playback_pos
        gp_patt.number_of_lines = self:_restrict_to_pattern_length(lc)

        --print("output all active tracks that originate from this position")
        for t_idx = 1, rns.sequencer_track_count do
          if self.active_slots[t_idx] and 
            (self.active_slots[t_idx]==seq_idx) 
          then
            -- prepare delayed update
            local pos = {
              pattern = self.active_slots[t_idx],
              track = t_idx,
              line = 1
            }
            local patt_idx = rns.sequencer.pattern_sequence[self.active_slots[t_idx]]
            self:_add_pending_update(patt_idx,pos)
          end
        end
        if (lc ~= old_lines) then
          -- adjust playback position
          self:_keep_the_beat(old_lines,old_pos)
        end
      else
        --print("number_of_lines_observable - no grid pie tracks available")
      end

    end
  )

end

--------------------------------------------------------------------------------

--- To produce continous output to a pattern, we need to have an idea
-- about how much the song-position is advancing within a period of time
-- (the method is called when BPM/LPB is changed)

function GridPie:set_writeahead()
  TRACE("GridPie:set_writeahead()")

  local rns = renoise.song()
  local bpm = rns.transport.bpm
  local lpb = rns.transport.lpb

  self.writeahead_length = math.ceil(math.max(2,(bpm*lpb)/160))
  self.writeahead_interval = math.ceil(self.writeahead_length/2)

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
  local gridpie_patt = rns.patterns[self.gridpie_patt_idx]
  
  if (old_lines > gridpie_patt.number_of_lines) then
    -- If the playhead is within the valid range, do nothing
    if (old_pos.line > gridpie_patt.number_of_lines) then
      local lpb = rns.transport.lpb
      -- The playhead jumps back in the pattern by the same amount of lines as we, 
      -- at the moment the length changed, were located from the end of that 
      -- pattern. This should cause us to arrive at line 1 in the same time
      local new_line = (old_pos.line-old_lines) + gridpie_patt.number_of_lines
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
      if (new_line>gridpie_patt.number_of_lines) then
        new_line = new_line%gridpie_patt.number_of_lines
      end
      -- finally, ensure we *never* go to line 0
      if (new_line==0) then
        new_line = gridpie_patt.number_of_lines
      end
      old_pos.line = new_line
      rns.transport.playback_pos = old_pos
      --print("*** keep the beat - playback_pos.sequence",old_pos.sequence)
      --print("*** keep the beat - playback_pos.line",old_pos.line)
    end
  end

end

--------------------------------------------------------------------------------

--- Detach all attached notifiers in list, but don't even try to detach 
-- when a new song arrived - old observables will no longer be alive then...
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

