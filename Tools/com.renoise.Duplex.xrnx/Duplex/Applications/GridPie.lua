--[[----------------------------------------------------------------------------
-- Duplex.GridPie
-- Inheritance: Application > GridPie
----------------------------------------------------------------------------]]--

--[[

About

  This application is a Duplex port of Grid Pie. 
  See http://www.renoise.com/board/index.php?/topic/27606-new-tool-27-grid-pie/

  -- TODO --
  - Remember held buttons, so they don't toggle when released
  - Enable ALL tracks when button is held

  ?? Questions ?? 

  - How does "init_pm_slots_to" work?





--]]

--==============================================================================


class 'GridPie' (Application)


GridPie.default_options = {
  follow_pos = {
    label = "Follow position",
    description = "Enable this to make Renoise follow the pattern/track",
    items = {
      "Enabled",
      "Disabled",
    },
    value = 1,
  },
  polyrhythms = {
    label = "Polyrhythms",
    description = "Disable this feature if it's using too much CPU",
    items = {
      "Enabled",
      "Disabled",
    },
    value = 1,
  },
  v_step = {
    label = "Vertical step",
    description = "Specify the vertical step size",
    on_change = function(inst)
      -- TODO
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
  h_step = {
    label = "Horizontal step",
    description = "Specify the horizontal step size",
    on_change = function(inst)
      -- TODO
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

function GridPie:__init(browser_process,mappings,options,config_name)
  TRACE("GridPie:__init(",browser_process,mappings,options,config_name)

  --[[ Globals, capitalized for easier recognition ]]--

  self.GRIDPIE_IDX = nil
  self.MATRIX_CELLS = table.create()
  self.MATRIX_HEIGHT = nil
  self.MATRIX_WIDTH = nil
  self.POLY_COUNTER = table.create()
  self.REVERT_PM_SLOT = table.create()

  self.X_POS = 1 
  self.Y_POS = 1

  -- option constants
  self.POLY_ENABLED = 1
  self.POLY_DISABLED = 2
  self.FOLLOW_POS_ON = 1
  self.FOLLOW_POS_OFF = 2

  -- misc private stuff
  self.v_step = 1
  self.h_step = 1

  -- UIComponent references
  self._bt_v_prev = nil
  self._bt_v_next = nil
  self._bt_h_prev = nil
  self._bt_h_next = nil

  self.mappings = {
    grid = {
      description = "GridPie: Press and release to copy track"
                  .."\nPress and hold to copy pattern"
                  .."\nControl value: ",
    },
    v_prev = {
      description = "GridPie: goto previous part of sequence"
    },
    v_next = {
      description = "GridPie: goto next part of sequence"
    },
    h_prev = {
      description = "GridPie: goto previous tracks in pattern"
    },
    h_next = {
      description = "GridPie: goto next tracks in pattern"
    },
  }

  self.palette = {
    out_of_bounds = {
      color={0x40,0x40,0x00}, 
      text="",
    },  
    selected_filled = {
      color={0xFF,0xFF,0x80},
      text="■",
    },
    selected_empty = {
      color={0xFF,0x80,0x40},
      text="■",
    },
    empty = {
      color={0x00,0x00,0x00},
      text="□"    
    },
    filled = {
      color={0x80,0x40,0x00},
      text="□",
    }
  }

  Application.__init(self,browser_process,mappings,options,config_name)


end

--------------------------------------------------------------------------------

-- this function will apply the current settings
-- to the v_step and h_step variables

function GridPie:_set_step_sizes()
  TRACE("GridPie:_set_step_sizes()")

  self.v_step = (self.options.v_step.value==1) and
    self.MATRIX_HEIGHT or self.options.v_step.value-1
  
  self.h_step = (self.options.h_step.value==1) and
    self.MATRIX_WIDTH or self.options.h_step.value-1

end

--------------------------------------------------------------------------------

function GridPie:_get_v_limit()
  return math.max(1,#renoise.song().sequencer.pattern_sequence - self.MATRIX_HEIGHT)
end

function GridPie:_get_h_limit()
  return renoise.song().sequencer_track_count - self.MATRIX_WIDTH + 1
end

--------------------------------------------------------------------------------

-- update buttons for horizontal navigation

function GridPie:update_h_buttons()

  local skip_event = true

  if (self.mappings.h_next.group_name) then
    self._bt_h_next:set(self.X_POS~=self:_get_h_limit(),skip_event)
  end
  if (self.mappings.h_prev.group_name) then
    self._bt_h_prev:set(self.X_POS~=1,skip_event)
  end

end

--------------------------------------------------------------------------------

-- update buttons for vertical navigation

function GridPie:update_v_buttons()

  local skip_event = true

  if (self.mappings.v_next.group_name) then
    self._bt_v_next:set(self.Y_POS~=self:_get_v_limit(),skip_event)
  end
  if (self.mappings.v_prev.group_name) then
    self._bt_v_prev:set(self.Y_POS~=1,skip_event)
  end

end

--------------------------------------------------------------------------------
-- Is garbage PM position?
--------------------------------------------------------------------------------

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
    -- Is garbage
    return true
  else
    -- Is not garbage
    return false
  end

end


--------------------------------------------------------------------------------
-- Access a cell in the Grid Pie
--------------------------------------------------------------------------------

function GridPie:matrix_cell(x,y)
  --TRACE("GridPie:matrix_cell()",x,y)

  if (self.MATRIX_CELLS[x] ~= nil) then
    return self.MATRIX_CELLS[x][y]
  else
    return nil
  end
end


--------------------------------------------------------------------------------
-- Toggle all slot mutes in Pattern Matrix
--------------------------------------------------------------------------------

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
--------------------------------------------------------------------------------

function GridPie:init_gp_pattern()
  TRACE("GridPie:init_gp_pattern()")

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

  -- Ajdust the Renoise interface, move playhead to last pattern, ...
  renoise.app().window.pattern_matrix_is_visible = true
  rns.selected_sequence_index = #sequencer.pattern_sequence
  rns.transport.follow_player = false
  rns.transport.loop_pattern = true
  rns.transport:start(renoise.Transport.PLAYMODE_RESTART_PATTERN)

end


--------------------------------------------------------------------------------
-- Adjust grid
--------------------------------------------------------------------------------

function GridPie:adjust_grid()
  TRACE("GridPie:adjust_grid()")

  local color = nil
  for x = self.X_POS, self.MATRIX_WIDTH + self.X_POS - 1 do
    for y = self.Y_POS, self.MATRIX_HEIGHT + self.Y_POS - 1 do
      local cell = self:matrix_cell(x - self.X_POS + 1, y - self.Y_POS + 1)
      local active,empty,muted = false,true,true
      if cell ~= nil and not self:is_garbage_pos(x, y) then
        muted = renoise.song().sequencer:track_sequence_slot_is_muted(x, y)
        active = not muted
        local patt_idx = renoise.song().sequencer.pattern_sequence[y]
        empty = renoise.song().patterns[patt_idx].tracks[x].is_empty
        if empty then
          if muted then 
            color = self.palette.empty
          else 
            color = self.palette.selected_empty 
          end
        else
          if muted then 
            color = self.palette.filled
          else 
            color = self.palette.selected_filled 
          end
        end
      elseif cell ~= nil then
        color = self.palette.out_of_bounds
      elseif self:is_garbage_pos(x, y) then
        color = self.palette.out_of_bounds
      end
      if color then
        -- assign same color to selected/inactive state
        cell:set_palette({background=color,foreground=color})
      end
      local skip_event = false
      cell:set(active,skip_event)

    end
  end
  if (self.options.follow_pos.value == self.FOLLOW_POS_ON) then
    renoise.song().selected_track_index = self.X_POS
    renoise.song().selected_sequence_index = self.Y_POS
  end

end


--------------------------------------------------------------------------------
-- Copy and expand a track
--------------------------------------------------------------------------------

function GridPie:copy_and_expand(source_pattern, dest_pattern, track_idx, number_of_lines)
  TRACE("GridPie:copy_and_expand()",source_pattern, dest_pattern, track_idx, number_of_lines)

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
--------------------------------------------------------------------------------

function GridPie:toggler(x, y)
  TRACE("GridPie:toggler()",x, y)

  local cell = self:matrix_cell(x, y)
  local muted = false
  if cell ~= nil and 
    --cell.color[2] == 255 
    cell.active
  then 
    print("cell.active",cell.active)
    muted = true 
  end

  print("muted",muted)

  x = x + (self.X_POS - 1)
  y = y + (self.Y_POS - 1)

  if self:is_garbage_pos(x, y) then return end

  local rns = renoise.song()
  local source = rns.patterns[rns.sequencer:pattern(y)]
  local dest = rns.patterns[self.GRIDPIE_IDX]
  local lc = least_common(dest.number_of_lines, source.number_of_lines)
  local toc = 0

  if muted then

    -- Mute
    -- TODO: This is a hackaround, fix when API is updated
    -- See: http://www.renoise.com/board/index.php?showtopic=31927
    rns.tracks[x].mute_state = renoise.Track.MUTE_STATE_OFF
    rns.patterns[self.GRIDPIE_IDX].tracks[x]:clear()
    OneShotIdleNotifier(100, function() rns.tracks[x].mute_state = renoise.Track.MUTE_STATE_ACTIVE end)
    self.POLY_COUNTER[x] = nil

  else

    -- Track polyrhythms
    self.POLY_COUNTER[x] = source.number_of_lines
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

      TRACE("Expanding track " .. x .. " from " .. source.number_of_lines .. " to " .. dest.number_of_lines .. " lines")

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
            TRACE("Also expanding track " .. idx .. " from " .. old_lines .. " to " .. dest.number_of_lines .. " lines") 
            self:copy_and_expand(dest, dest, idx, old_lines)
          end
        end

      end

    end

  end

  -- Change PM
  for i = 1, #rns.sequencer.pattern_sequence - 1 do
    if not self:is_garbage_pos(x, i) then
      if i == y then
        rns.sequencer:set_track_sequence_slot_is_muted(x , i, muted)
      else
        rns.sequencer:set_track_sequence_slot_is_muted(x , i, true)
      end
    end
  end
  self:adjust_grid()

end


--------------------------------------------------------------------------------
-- Build GUI Interface
-- equivalent to build_interface() in the original tool
--------------------------------------------------------------------------------

function GridPie:_build_app()
  TRACE("GridPie:_build_app()")

  -- supply this when setting UIComponents programmatically

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
    c.on_press = function(obj) 
      print("*** _bt_v_prev.on_press()")
      if not self.active then
        return
      end
      local limit = 1
      local new_y = math.max(limit,self.Y_POS-self.v_step)
      print("new_y",new_y)
      if (new_y~=self.Y_POS) then
        self.Y_POS = new_y
        self:adjust_grid()
        self:update_v_buttons()
      end
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
    c.on_press = function(obj) 
      print("*** _bt_v_next.on_press()")
      if not self.active then
        return
      end
      local limit = self:_get_v_limit()
      local new_y = math.min(self.Y_POS+self.v_step,limit)
      print("new_y",new_y)
      if (new_y~=self.Y_POS) then
        self.Y_POS = new_y
        self:adjust_grid()
        self:update_v_buttons()
      end
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
    c.on_press = function(obj) 
      print("*** _bt_h_prev.on_press()")
      if not self.active then
        return
      end
      local limit = 1
      local new_x = math.max(limit,self.X_POS-self.h_step)
      print("new_x",new_x)
      if (new_x~=self.X_POS) then
        self.X_POS = new_x
        self:adjust_grid()
        self:update_h_buttons()
      end
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
    c.on_press = function(obj) 
      if not self.active then
        return
      end
      local limit = self:_get_h_limit()
      local new_x = math.min(self.X_POS+self.h_step,limit)
      if (new_x~=self.X_POS) then
        self.X_POS = new_x
        self:adjust_grid()
        self:update_h_buttons()
      end
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
        c.on_hold = function(obj) 
          print("*** button.on_hold()")
        end
        c.on_release = function(obj) 
          print("*** button.on_release()",x,y)
          if not self.active then
            return false
          end
          self:toggler(x,y)
          --return true
        end
        c.on_hold = function(obj) 
          print("*** button.on_hold()",x,y)
          if not self.active then
            return false
          end
          for x = 1,self.MATRIX_WIDTH do
            self:toggler(x,y)
          end
          --return true
        end

        self:_add_component(c)
        self.MATRIX_CELLS[x][y] = c

      end

    end
  end

  self:_attach_to_song(renoise.song())

  Application._build_app(self)
  return true

end


--------------------------------------------------------------------------------
-- Main
-- equivalent to main() in the original tool
--------------------------------------------------------------------------------

function GridPie:start_app()
  TRACE("GridPie:start_app()")

  -- this step will ensure that the application is properly mapped,
  -- after which it will also call the build_app() method 
  if not Application.start_app(self) then
    return
  end

  self:_set_step_sizes() 

  self.REVERT_PM_SLOT = table.create()
  self.POLY_COUNTER = table.create()
  self:init_pm_slots_to(true)
  self:init_gp_pattern()

  self:update_v_buttons()
  self:update_h_buttons()
  self:adjust_grid()

end



--------------------------------------------------------------------------------
-- Abort
--------------------------------------------------------------------------------

function GridPie:abort(notification)
  TRACE("GridPie:abort()",notification)

  renoise.app():show_message(
    "You dun goofed! Grid Pie needs to be restarted."
  )

end


--------------------------------------------------------------------------------
-- Handle document change
-- document_changed() in original tool
--------------------------------------------------------------------------------

function GridPie:on_new_document(song)
  TRACE("GridPie:on_new_document()",song)

  -- Document has changed, stored slots are invalid, reset table
  self.REVERT_PM_SLOT = table.create()
  self:abort()

end

--------------------------------------------------------------------------------
-- Idler
-- idler() in original tool
--------------------------------------------------------------------------------

function GridPie:on_idle()

  --[[
  local last_pattern = renoise.song().sequencer:pattern(#renoise.song().sequencer.pattern_sequence)
  if renoise.song().patterns[last_pattern].name ~= "__GRID_PIE__" then
    self:abort()
  end
  ]]

end


--------------------------------------------------------------------------------
-- Bootsauce
-- equivalent to run() in original tool,
-- notification (tracks_changed,sequence_changed) are assigned anonymously
--------------------------------------------------------------------------------

function GridPie:_attach_to_song()
  TRACE("GridPie:_attach_to_song()")

  renoise.song().tracks_observable:add_notifier(
    function(notification)
      TRACE("GridPie:tracks_observable fired...",notification)

      if not self.active then
        return false
      end

      -- Tracks have changed, stored slots are invalid, reset table
      self.REVERT_PM_SLOT = table.create()
      if (notification.type == "insert") then

        -- TODO: This is a hackaround, fix when API is updated
        -- See: http://www.renoise.com/board/index.php?showtopic=31893
        OneShotIdleNotifier(100, function()
          for i = 1, #renoise.song().sequencer.pattern_sequence - 1 do
            renoise.song().sequencer:set_track_sequence_slot_is_muted(notification.index , i, true)
          end
        end)

      end

      self:update_h_buttons()
      self:adjust_grid()

    end
  )

  renoise.song().sequencer.pattern_sequence_observable:add_notifier(
    function()
      TRACE("GridPie:pattern_sequence_observable fired...")

      if not self.active then
        return false
      end

      -- Sequence have changed, stored slots are invalid, reset table
      self.REVERT_PM_SLOT = table.create()

      self:update_v_buttons()
      self:adjust_grid()

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

