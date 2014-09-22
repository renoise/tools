--[[============================================================================
-- Duplex.Application.TrackSelector
============================================================================]]--

--[[--
Select the active Renoise track, including shortcuts for master & send tracks.
Inheritance: @{Duplex.Application} > Duplex.Application.TrackSelector

### Changes

  0.99.3
    - All "pattern line mappings" has moved into 
      Duplex.Applications.PatternCursor

  0.98.28
    - New mappings: “next_track”,”prev_track” (UIButtons, replaces UISpinner)
    - New mappings: “next_page”,”prev_page” (UIButtons, replaces UISpinner)
    - FEATURE: Hold prev/next track to select first/last track
    - New mappings: “next_line”,”prev_line” (UIButtons)
    - New mappings: “line”(UISlider, replaces UISpinner)

  0.98.21
    - Fixed: application was updating display when stopped/paused

  0.98  
    - Deprecated UISpinner controls (exchanged with UIButtons)

  0.97
    - Allows to set focus to track by index, previous or next track
    - Supports paged navigation features (previous/next, page size)
    - Allows direct access to sequencer-track #1, master or send-track #1

  0.96  
    - First release


--]]


--==============================================================================

-- constants

local TRACK_PAGE_AUTO = 1


--==============================================================================

class 'TrackSelector' (Application)

TrackSelector.default_options = {
  page_size = {
    label = "Page size",
    description = "Specify the step size when using paged navigation",
    on_change = function(app)
      app:update()
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

TrackSelector.available_mappings = {
  --[[
  prev_next_track = {    
    description = "TrackSelector: Select next/previous track",
    orientation = ORIENTATION.HORIZONTAL,    
  },
  ]]
  prev_track = {    
    description = "TrackSelector: Select previous track",
    component = UIButton,
  },
  next_track = {    
    description = "TrackSelector: Select next track",
    component = UIButton,
  },
  --[[
  prev_next_page = {
    description = "TrackSelector: Select track-page",
    orientation = ORIENTATION.HORIZONTAL,    
  },
  ]]
  prev_page = {
    description = "TrackSelector: Select previous track-page",
    component = UIButton,
  },
  next_page = {
    description = "TrackSelector: Select next track-page",
    component = UIButton,
  },
  select_track = {
    description = "TrackSelector: Select active track",
    component = UISlider,
    orientation = ORIENTATION.HORIZONTAL,    
  },
  select_master = {
    description = "TrackSelector: Select master-track",
    component = UIButton,
  },
  select_sends = {
    description = "TrackSelector: Select 1st send-track",
    component = UIButton,
  },
  select_first = {
    description = "TrackSelector: Select first track",
    component = UIButton,
  },
}

TrackSelector.default_palette = {
  -- TODO add customization options for UISlider "select_track" as well
  track_sequencer_on  = { color = {0xFF,0xFF,0xFF}, text = "T", val=true  },
  track_sequencer_off = { color = {0x00,0x00,0x00}, text = "T", val=false },
  track_master_on     = { color = {0xFF,0xFF,0xFF}, text = "M", val=true  },
  track_master_off    = { color = {0x00,0x00,0x00}, text = "M", val=false },
  track_send_on       = { color = {0xFF,0xFF,0xFF}, text = "S", val=true  },
  track_send_off      = { color = {0x00,0x00,0x00}, text = "S", val=false },
  select_device_tip   = { color = {0xFF,0xFF,0xFF}, text = "▪", val=true  },
  select_device_back  = { color = {0x40,0x40,0x80}, text = "▫", val=false },
  track_prev_on       = { color = {0xFF,0xFF,0xFF}, text = "◄", val=true  },
  track_prev_off      = { color = {0x00,0x00,0x00}, text = "◄", val=false },
  track_next_on       = { color = {0xFF,0xFF,0xFF}, text = "►", val=true  },
  track_next_off      = { color = {0x00,0x00,0x00}, text = "►", val=false },
  page_prev_on        = { color = {0xFF,0xFF,0xFF}, text = "◄", val=true  },
  page_prev_off       = { color = {0x00,0x00,0x00}, text = "◄", val=false },
  page_next_on        = { color = {0xFF,0xFF,0xFF}, text = "►", val=true  },
  page_next_off       = { color = {0x00,0x00,0x00}, text = "►", val=false },

}

--------------------------------------------------------------------------------

--- Constructor method
-- @param (VarArg)
-- @see Duplex.Application

function TrackSelector:__init(...)

  -- (Int) #tracks available on controller
  self._slider_units = 1

  -- the active track page
  self._track_page = nil

  -- selected track index
  self._selected_track_index = nil

  -- out-of-bounds track index
  -- this is the track we *wanted* to select, but
  -- could not, because it was out of bounds
  -- (used when jumping back from topmost track)
  self._out_of_bounds_track_index = nil

  -- (bool) notifier flags: set when update is needed
  self._selected_track_observable_fired = false
  self._tracks_observable_fired = false

  -- UIComponent instances
  --self._prev_next_track = nil
  self._prev_track = nil
  self._next_track = nil
  --self._prev_next_page = nil
  self._prev_page = nil
  self._next_page = nil
  self._select_track = nil
  self._select_master = nil
  self._select_sends = nil
  self._select_first = nil

  Application.__init(self,...)

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.start_app
-- @return bool or nil

function TrackSelector:start_app()

  -- validate configuration, build app
  if not Application.start_app(self) then
    return
  end

  self:_attach_to_song(renoise.song())
  self:update()

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_new_document

function TrackSelector:on_new_document()
  TRACE("TrackSelector:on_new_document()")

  self:_attach_to_song(renoise.song())
  self:update()

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_idle

function TrackSelector:on_idle()

  if self._tracks_observable_fired then
    self._tracks_observable_fired = false
    self:update()
  end

  if self._selected_track_observable_fired then
    self._selected_track_observable_fired = false
    self:update()
  end

end

--------------------------------------------------------------------------------
-- adds notifiers to song, set essential values

function TrackSelector:_attach_to_song(song)
  TRACE("TrackSelector:_attach_to_song",song)

  self._selected_track_index = song.selected_track_index

  -- follow active track in Renoise
  song.selected_track_index_observable:add_notifier(
    function()
      TRACE("TrackSelector:selected_track_observable fired...")
      if not self.active then 
        return 
      end
      if (self._selected_track_index ~= song.selected_track_index)then
      -- request update on next idle() loop
        self._selected_track_index = song.selected_track_index
        self._selected_track_observable_fired = true
      end
    end
  )
  -- update on track changes in the song 
  song.tracks_observable:add_notifier(
    function()
      TRACE("TrackSelector:tracks_changed fired...")
      -- request update on next idle() loop
      self._tracks_observable_fired = true
    end
  )

end

--------------------------------------------------------------------------------

function TrackSelector:_get_track_page(track_idx)
  local page_width = self:_get_page_width()
  return math.ceil(track_idx/page_width)
end

--------------------------------------------------------------------------------

function TrackSelector:_get_page_width()
  return (self.options.page_size.value == TRACK_PAGE_AUTO)
    and self._slider_units or self.options.page_size.value-1
end

--------------------------------------------------------------------------------
-- set all components to values from Renoise

function TrackSelector:update()
  TRACE("TrackSelector:update()")

  local skip_event = true
  local page_width = self:_get_page_width()

  -- set the active track index + range
  --[[
  if (self._prev_next_track) then
    local track_min = 1
    local track_max = #renoise.song().tracks
    self._prev_next_track:set_range(track_min,track_max)
    self._prev_next_track:set_index(self._selected_track_index,skip_event)
  end
  ]]
  if (self._prev_track) then
    if (self._selected_track_index <= 1) then
      self._prev_track:set(self.palette.track_prev_off)
    else
      self._prev_track:set(self.palette.track_prev_on)
    end
  end
  if (self._next_track) then
    if (self._selected_track_index >= #renoise.song().tracks) then
      self._next_track:set(self.palette.track_next_off)
    else
      self._next_track:set(self.palette.track_next_on)
    end
  end

  -- set the active track page + range
  local track_max = #renoise.song().tracks
  local track_index = self._selected_track_index
  local page = self:_get_track_page(track_index)
  self._track_page = page
  local pages = math.ceil(track_max/page_width)
  --[[
  if (self._prev_next_page) then
    self._prev_next_page:set_range(1,pages)
    self._prev_next_page:set_index(page,skip_event)
  end
  ]]
  if (self._prev_page) then
    if (page > 1) then
      self._prev_page:set(self.palette.page_prev_on)
    else
      self._prev_page:set(self.palette.page_prev_off)
    end
  end
  if (self._next_page) then
    if (page < pages) then
      self._next_page:set(self.palette.page_next_on)
    else
      self._next_page:set(self.palette.page_next_off)
    end
  end

  -- set the active slider index
  if (self._select_track) then
    self._select_track.steps = #renoise.song().tracks
    -- figure out the position on the slider
    local page_index = (self._track_page) 
      and (self._track_page-1)*page_width
      or 0
    local slider_pos = self._selected_track_index-page_index
    self._select_track:set_index(slider_pos,skip_event)
  end

  local master_idx = get_master_track_index()

  -- set the seq./master/send buttons
  if self._select_first then
    if (track_index == 1) then
      self._select_first:set(self.palette.track_sequencer_on)
    else
      self._select_first:set(self.palette.track_sequencer_off)
    end
  end
  if self._select_master then
    if (track_index == master_idx) then
      self._select_master:set(self.palette.track_master_on)
    else
      self._select_master:set(self.palette.track_master_off)
    end
  end
  if self._select_sends then
    if (track_index == (master_idx+1)) then
      self._select_sends:set(self.palette.track_send_on)
    else
      self._select_sends:set(self.palette.track_send_off)
    end
  end

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application._build_app
-- @return bool

function TrackSelector:_build_app(song)
  TRACE("TrackSelector:_build_app",song)

  -- reference to the control-map
  local cm = self.display.device.control_map

  local slider_grid_mode = false

  -- add next/previous track control
  --[[
  local map = self.mappings.prev_next_track
  if map.group_name then
    TRACE("TrackSelector:add next/previous track control (spinner)")
    local c = UISpinner(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index or 1)
    c:set_orientation(map.orientation or ORIENTATION.HORIZONTAL)
    c.on_change = function(obj) 

      -- to learn if we increased or decreased the track,
      -- compare cached value in spinner (the old value
      -- is kept before new the new value is applied)
      local increased = (obj.index>obj._cached_index)
      local track_idx = renoise.song().selected_track_index
      -- ensure that we select a track within valid range
      if (increased) then
        track_idx = math.min(track_idx+1,#renoise.song().tracks)
      else
        track_idx = math.max(track_idx-1,1)
      end
      -- the notifier will take care of the rest
      renoise.song().selected_track_index = track_idx
 
    end
    
    self._prev_next_track = c
  end
  ]]
  local map = self.mappings.prev_track
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index or 1)
    c.on_press = function() 
      local track_idx = renoise.song().selected_track_index
      track_idx = math.max(track_idx-1,1)
      renoise.song().selected_track_index = track_idx
    end
    c.on_hold = function() 
      renoise.song().selected_track_index = 1
    end
    self._prev_track = c
  end

  local map = self.mappings.next_track
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index or 1)
    c.on_press = function() 
      local track_idx = renoise.song().selected_track_index
      track_idx = math.min(track_idx+1,#renoise.song().tracks)
      renoise.song().selected_track_index = track_idx
    end
    c.on_hold = function() 
      renoise.song().selected_track_index = #renoise.song().tracks
    end
    self._next_track = c
  end


  -- add previous/next page control
  --[[
  local map = self.mappings.prev_next_page
  if map.group_name then
    TRACE("TrackSelector:add previous/next page control (spinner)")
    local c = UISpinner(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index or 1)
    c:set_orientation(map.orientation or ORIENTATION.HORIZONTAL)
    c.on_change = function(obj)
      local track_idx = renoise.song().selected_track_index
      local track_page = self:_get_track_page(track_idx)
      -- figure out the resulting track index
      if self._out_of_bounds_track_index then
        track_idx = self._out_of_bounds_track_index
      end
      local page_width = self:_get_page_width()
      local page_diff = (obj.index-track_page)*page_width
      local track_idx = page_diff+track_idx

      -- outside bounds?
      if (track_idx>#renoise.song().tracks) then
        self._out_of_bounds_track_index = track_idx
        track_idx=#renoise.song().tracks
      else
        self._out_of_bounds_track_index = nil
      end
      -- the notifier will take care of the rest
      renoise.song().selected_track_index = track_idx
    end
    self._prev_next_page = c
  end
  ]]

  -- obtain track index, and set the "out of bounds"
  -- value if needed. Used by previous/next track page
  -- @param offset: -1 to decrease page, +1 to increase
  local get_track_index = function(offset)

    local track_idx = renoise.song().selected_track_index
    local track_page = self:_get_track_page(track_idx)

    -- figure out the resulting track index
    if self._out_of_bounds_track_index then
      track_idx = self._out_of_bounds_track_index
    end
    local page_width = self:_get_page_width()
    local track_idx = (offset*page_width)+track_idx

    -- outside bounds?
    if (track_idx>#renoise.song().tracks) then
      if not self._out_of_bounds_track_index then
        self._out_of_bounds_track_index = track_idx
      end
      track_idx=#renoise.song().tracks
    else
      if (track_idx<1) then
        track_idx = renoise.song().selected_track_index
      end
      self._out_of_bounds_track_index = nil
    end

    return track_idx

  end

  local map = self.mappings.prev_page
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index or 1)
    c.on_press = function()
      local track_idx = get_track_index(-1)
      renoise.song().selected_track_index = track_idx
    end
    self._prev_page = c
  end

  local map = self.mappings.next_page
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index or 1)
    c.on_press = function()
      local track_idx = get_track_index(1)
      renoise.song().selected_track_index = track_idx
    end
    self._next_page = c
  end

  -- add track-activator control
  local map = self.mappings.select_track
  if map.group_name then
    TRACE("TrackSelector:add track-activator control (slider)")
    
    -- is the control button-based?
    slider_grid_mode = cm:is_button(map.group_name,map.index)
    if slider_grid_mode then
      -- yes, count the # available buttons
      if (map.orientation==ORIENTATION.HORIZONTAL) then
        self._slider_units = cm:count_columns(map.group_name)
      else
        self._slider_units = cm:count_rows(map.group_name)
      end
    end

    local c = UISlider(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index or 1)
    c.toggleable = false
    c.flipped = true
    c:set_palette({
      tip = self.palette.select_device_tip,
      track = self.palette.select_device_back,
      background = self.palette.select_device_back,
    })
    c:set_orientation(map.orientation)
    c:set_size(self._slider_units)
    c.on_change = function(obj) 

      if (obj.index>0) then
        local track_idx = nil
        local page_width = self:_get_page_width()
        -- button-based slider?
        if (self._track_page) then
          track_idx = obj.index + (self._track_page-1)*page_width
        else
          track_idx = obj.index
        end
        -- outside bounds?
        if (track_idx>#renoise.song().tracks) then
          -- TODO if button-based, revert to previous index
          return 
        end
        -- reset the 'out of bounds' track 
        -- (since we manually selected this track)
        self._out_of_bounds_track_index = nil
        -- the notifier will take care of the rest
        renoise.song().selected_track_index = track_idx
      end

    end
    
    self._select_track = c
  end

  -- add first track select 
  local map = self.mappings.select_first
  if map.group_name then
    TRACE("TrackSelector:add first track select (pushbutton)")
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      renoise.song().selected_track_index = 1
    end
    self._select_first = c
  end

  -- add master-track select 
  local map = self.mappings.select_master
  if map.group_name then
    TRACE("TrackSelector:add master-track select (pushbutton)")
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      local track_idx = get_master_track_index()
      renoise.song().selected_track_index = track_idx
    end
    self._select_master = c
  end

  -- add send-track select 
  local map = self.mappings.select_sends
  if map.group_name then
    TRACE("TrackSelector:add master-track select (pushbutton)")
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      local track_idx = get_master_track_index()+1
      -- outside bounds?
      if (track_idx>#renoise.song().tracks) then
        return 
      end
      renoise.song().selected_track_index = track_idx
    end
    self._select_sends = c
  end

  Application._build_app(self)
  return true

end

