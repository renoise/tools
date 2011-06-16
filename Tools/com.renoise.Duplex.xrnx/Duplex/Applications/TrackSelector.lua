--[[----------------------------------------------------------------------------
-- Duplex.TrackSelector
-- Inheritance: Application > TrackSelector
----------------------------------------------------------------------------]]--

--[[

About

  The TrackSelector's purpose is to control the active Renoise track

Mappings

  prev_next_track  - (UISpinner) assign to two contiguous buttons
  prev_next_page   - (UISpinner) assign to two contiguous buttons
  select_track     - (UISlider) assign to dial/fader or multiple buttons
  select_first     - (UIPushButton) assign to single button
  select_master    - (UIPushButton) assign to single button
  select_sends     - (UIPushButton) assign to single button

Options

  page_size     - specify step size when using paged navigation


Changes (equal to Duplex version number)

  0.96  - First release


--]]


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

function TrackSelector:__init(display,mappings,options,config_name)

  -- globals
  self.TRACK_PAGE_AUTO = 1

  -- (Int) number of tracks available on controller
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

  -- (boolean) notifier flags: set when update is needed
  self._selected_track_observable_fired = false
  self._tracks_observable_fired = false

  -- UIComponent instances
  self._prev_next_track = nil
  self._prev_next_page = nil
  self._select_track = nil
  self._select_master = nil
  self._select_sends = nil
  self._select_first = nil

  -- define the mappings
  self.mappings = {
    prev_next_track = {    
      description = "TrackSelector: Select next/previous track",
      ui_component = UI_COMPONENT_SPINNER,
      orientation = HORIZONTAL,    
    },
    prev_next_page = {
      description = "TrackSelector: Select track-page",
      ui_component = UI_COMPONENT_SPINNER,
      orientation = HORIZONTAL,    
    },
    select_track = {
      description = "TrackSelector: Select active track",
      ui_component = UI_COMPONENT_SLIDER,
      orientation = HORIZONTAL,    
    },
    select_master = {
      description = "TrackSelector: Select master-track",
      ui_component = UI_COMPONENT_PUSHBUTTON,
    },
    select_sends = {
      description = "TrackSelector: Select 1st send-track",
      ui_component = UI_COMPONENT_PUSHBUTTON,
    },
    select_first = {
      description = "TrackSelector: Select first track",
      ui_component = UI_COMPONENT_PUSHBUTTON,
    },
  }
  Application.__init(self,display,mappings,options,config_name)

end

--------------------------------------------------------------------------------
-- called when application is started

function TrackSelector:start_app()

  -- validate configuration, build app
  if not Application.start_app(self) then
    return
  end

  self:_attach_to_song(renoise.song())
  self:update()

end

--------------------------------------------------------------------------------
-- called when a new document becomes available

function TrackSelector:on_new_document()
  TRACE("TrackSelector:on_new_document()")

  self:_attach_to_song(renoise.song())
  self:update()

end

--------------------------------------------------------------------------------
-- on_idle is automatically called many times per second

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
  return (self.options.page_size.value==self.TRACK_PAGE_AUTO)
    and self._slider_units or self.options.page_size.value-1
end

--------------------------------------------------------------------------------
-- set all components to values from Renoise

function TrackSelector:update()
  TRACE("TrackSelector:update()")

  local skip_event = true
  local page_width = self:_get_page_width()

  -- set the active track index + range
  if (self._prev_next_track) then
    local track_min = 1
    local track_max = #renoise.song().tracks
    self._prev_next_track:set_range(track_min,track_max)
    self._prev_next_track:set_index(self._selected_track_index,skip_event)
  end

  -- set the active track page + range
  if (self._prev_next_page) then
    local track_max = #renoise.song().tracks
    local track_index = self._selected_track_index
    local page = self:_get_track_page(track_index)
    self._track_page = page
    local pages = math.ceil(track_max/page_width)
    self._prev_next_page:set_range(1,pages)
    self._prev_next_page:set_index(page,skip_event)
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

end

--------------------------------------------------------------------------------
-- build_app - construct the various UIComponents
-- @return boolean (false if requirements were not met)

function TrackSelector:_build_app(song)
  TRACE("TrackSelector:_build_app",song)

  -- reference to the control-map
  local cm = self.display.device.control_map

  local slider_grid_mode = false

  -- check if required mappings are present
  --[[
  if not self.mappings.select_track.group_name then
    local msg = "A required mapping is missing from the " 
    .."TrackSelector configuration. You need to specify the "
    .."'select_track' mapping"
    renoise.app():show_warning(msg)
    return false
  end
  ]]

  -- add next/previous track control (spinner)
  local map = self.mappings.prev_next_track
  if map.group_name then
    TRACE("TrackSelector:add next/previous track control (spinner)")
    local c = UISpinner(self.display)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index or 1)
    c:set_orientation(map.orientation or HORIZONTAL)
    c.on_change = function(obj) 

      if (not self.active) then
        return false
      end
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
      --self._selected_track_index = track_idx
 
    end
    
    self:_add_component(c)
    self._prev_next_track = c
  end

  -- add previous/next page control (spinner)
  local map = self.mappings.prev_next_page
  if map.group_name then
    TRACE("TrackSelector:add previous/next page control (spinner)")
    local c = UISpinner(self.display)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index or 1)
    c:set_orientation(map.orientation or HORIZONTAL)
    c.on_change = function(obj)
      if (not self.active) then
        return false
      end
      -- figure out the resulting track index
      if self._out_of_bounds_track_index then
        self._selected_track_index = self._out_of_bounds_track_index
      end
      local page_width = self:_get_page_width()
      local page_diff = (obj.index-self._track_page)*page_width
      local track_idx = page_diff+self._selected_track_index
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
    self:_add_component(c)
    self._prev_next_page = c
  end

  -- add track-activator control (slider)
  local map = self.mappings.select_track
  if map.group_name then
    TRACE("TrackSelector:add track-activator control (slider)")
    
    -- is the control button-based?
    slider_grid_mode = self:is_button(cm,map.group_name,map.index)
    if slider_grid_mode then
      -- yes, count the number of available buttons
      if (map.orientation==HORIZONTAL) then
        self._slider_units = cm:count_columns(map.group_name)
      else
        self._slider_units = cm:count_rows(map.group_name)
      end
    end

    local c = UISlider(self.display)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index or 1)
    c.toggleable = false
    c.flipped = true
    c.palette.track = table.rcopy(self.display.palette.background)
    c:set_orientation(map.orientation)
    c:set_size(self._slider_units)
    c.on_change = function(obj) 

      if (not self.active) then
        return false
      end

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
          return false
        end
        -- reset the 'out of bounds' track 
        -- (since we manually selected this track)
        self._out_of_bounds_track_index = nil
        -- the notifier will take care of the rest
        renoise.song().selected_track_index = track_idx
      end

    end
    
    self:_add_component(c)
    self._select_track = c
  end

  -- add first track select (pushbutton)
  local map = self.mappings.select_first
  if map.group_name then
    TRACE("TrackSelector:add first track select (pushbutton)")
    local c = UIPushButton(self.display)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      if not self.active then 
        return false 
      end
      renoise.song().selected_track_index = 1
    end
    self:_add_component(c)
    self._select_first = c
  end

  -- add master-track select (pushbutton)
  local map = self.mappings.select_master
  if map.group_name then
    TRACE("TrackSelector:add master-track select (pushbutton)")
    local c = UIPushButton(self.display)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      if not self.active then 
        return false 
      end
      local track_idx = get_master_track_index()
      renoise.song().selected_track_index = track_idx
    end
    self:_add_component(c)
    self._select_master = c
  end

  -- add send-track select (pushbutton)
  local map = self.mappings.select_sends
  if map.group_name then
    TRACE("TrackSelector:add master-track select (pushbutton)")
    local c = UIPushButton(self.display)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      if not self.active then 
        return false 
      end
      local track_idx = get_master_track_index()+1
      -- outside bounds?
      if (track_idx>#renoise.song().tracks) then
        return false
      end
      renoise.song().selected_track_index = track_idx
    end
    self:_add_component(c)
    self._select_sends = c
  end

  Application._build_app(self)
  return true

end

--------------------------------------------------------------------------------
-- depricated (part of ControlMap.lua in the next release)

function TrackSelector:is_button(cm,group_name,index)

  -- greedy mappings might not specify an index,
  -- so we simply use the first available one...
  if not index then
    index = 1
  end
  local group = cm.groups[group_name]
  if (group) then
    local param = group[index]
    if (param["xarg"] and param["xarg"]["type"]) then
      if not (param["xarg"]["type"]=="button") and
         not (param["xarg"]["type"]=="togglebutton") and
         not (param["xarg"]["type"]=="pushbutton") 
      then
        return false
      else
        return true
      end
    end
  end

  return false

end

