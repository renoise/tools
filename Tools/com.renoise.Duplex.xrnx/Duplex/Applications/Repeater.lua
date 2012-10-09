--[[----------------------------------------------------------------------------
-- Duplex.Repeater
-- Inheritance: Application > Repeater
----------------------------------------------------------------------------]]--

--[[

  This is our sample Repeater application 

--]]

--==============================================================================

-- constants

local DIVISORS = {1/1,1/2,1/4,1/8,1/16,1/32,1/64,1/128}
local HOLD_ENABLED = 1
local HOLD_DISABLED = 2
local FOLLOW_POS_ENABLED = 1
local FOLLOW_POS_DISABLED = 2
local LOCKED_ENABLED = 1
local LOCKED_DISABLED = 2
local RECORD_NONE = 1
local RECORD_TOUCH = 2
local RECORD_LATCH = 3
local MODE_OFF = 0
local MODE_FREE = 1
local MODE_EVEN = 2
local MODE_TRIPLET = 3
local MODE_DOTTED = 4
local MODE_AUTO = 5


--==============================================================================

class 'Repeater' (Application)

Repeater.default_options = {
  locked = {
    label = "Lock to device",
    description = "Disable locking if you want the controls to"
                .."\nfollow the currently selected device ",
    on_change = function(app)
      if (app.options.locked.value == LOCKED_DISABLED) then
        app:clear_device()
        app.current_device_requested = true
      end
      app:tag_device(app.target_device)
    end,
    items = {
      "Lock to device",
      "Roam freely"
    },
    value = 2,
  },
  record_method = {
    label = "Automation rec.",
    description = "Determine how to record automation",
    items = {
      "Disabled, do not record automation",
      "Touch, record only when touched",
      "Latch (experimental)",
    },
    value = 1,
    on_change = function(inst)
      inst.automation.latch_record = 
      (inst.options.record_method.value == RECORD_LATCH) and true or false
    end
  },
  follow_pos = {
    label = "Follow pos",
    description = "Bring focus to selected Repeater device",
    items = {
      "Enabled",
      "Disabled"
    },
    value = 1,
  },
  mode_select = {
    label = "Mode select",
    description = "Determine the working mode of the grid:"
                .."\nFree: scale between 1/1 and 1/128"
                .."\nEven: display only 'even' divisors"
                .."\nTriplet: display only 'triplet' divisors"
                .."\nDotted: display only 'dotted' divisors"
                .."\nAutomatic: display 'even','triplet' and 'dotted' "                
                .."\n  divisors, each on a separate line (automatic layout)",
    items = {
      "Free",
      "Even",
      "Triplet",
      "Dotted",
      "Automatic",
    },
    value = 5,
    on_change = function(app)
      app:init_grid()
    end
  },
  hold_option = {
    label = "Hold option",
    description = "Determine what to do when a button is released",
    items = {
      "Continue (hold)",
      "Stop (hold off)",
    },
    value = 1,
    on_change = function(app)
      if (app.options.hold_option.value == HOLD_DISABLED) then
        app:stop_repeating()
      end
    end
  },
  divisor_min = {
    label = "Divisor (min) ",
    hidden = true,
    description = "Specify the minimum divisor value",
    items = {
      "1/1",
      "1/2",
      "1/4",
      "1/8",
      "1/16",
      "1/32",
      "1/64",
      "1/128",
    },
    value = 1,
    on_change = function(app)
      app:init_grid()
    end
  },
  divisor_max = {
    label = "Divisor (max) ",
    hidden = true,
    description = "Specify the minimum divisor value",
    items = {
      "1/1",
      "1/2",
      "1/4",
      "1/8",
      "1/16",
      "1/32",
      "1/64",
      "1/128",
    },
    value = 8,
    on_change = function(app)
      app:init_grid()
    end
  }
}

Repeater.available_mappings = {
  grid = {
    description = "Repeater: button grid"
  },
  lock_button = {
    description = "Repeater: Lock/unlock device",
  },
  divisor_slider = {
    description = "Repeater: Control divisor using a fader/knob",
  },
  mode_slider = {
    description = "Repeater: Control mode using a fader/knob",
  },
  next_device = {
    description = "Repeater: Next device",
  },
  prev_device = {
    description = "Repeater: Previous device",
  },
  mode_even = {
    description = "Repeater: Set mode to 'even'",
  },
  mode_triplet = {
    description = "Repeater: Set mode to 'triplet'",
  },
  mode_dotted = {
    description = "Repeater: Set mode to 'triplet'",
  },
  mode_free = {
    description = "Repeater: Set mode to 'free'",
  },

}

Repeater.default_palette = {
  enabled           = { color = {0xFF,0xFF,0xFF}, val=true  },
  disabled          = { color = {0x00,0x00,0x00}, val=false },
  lock_on           = { color = {0xFF,0xFF,0xFF}, text = "♥", val=true  },
  lock_off          = { color = {0x00,0x00,0x00}, text = "♥", val=false },
  mode_on           = { color = {0xFF,0xFF,0xFF}, text = "■", val=true  },
  mode_off          = { color = {0x00,0x00,0x00}, text = "·", val=false },
  prev_device_on    = { color = {0xFF,0xFF,0xFF}, text = "◄", val=true  },
  prev_device_off   = { color = {0x00,0x00,0x00}, text = "◄", val=false },
  next_device_on    = { color = {0xFF,0xFF,0xFF}, text = "►", val=true  },
  next_device_off   = { color = {0x00,0x00,0x00}, text = "►", val=false },
  mode_even_on      = { color = {0xFF,0xFF,0xFF}, text = "E", val=true  },
  mode_even_off     = { color = {0x00,0x00,0x00}, text = "E", val=false },
  mode_triplet_on   = { color = {0xFF,0xFF,0xFF}, text = "T", val=true  },
  mode_triplet_off  = { color = {0x00,0x00,0x00}, text = "T", val=false },
  mode_dotted_on    = { color = {0xFF,0xFF,0xFF}, text = "D", val=true  },
  mode_dotted_off   = { color = {0x00,0x00,0x00}, text = "D", val=false },
  mode_free_on      = { color = {0xFF,0xFF,0xFF}, text = "F", val=true  },
  mode_free_off     = { color = {0x00,0x00,0x00}, text = "F", val=false },
}

--------------------------------------------------------------------------------

--- Constructor method
-- @param (VarArg), see Application to learn more

function Repeater:__init(...)
  TRACE("Repeater:__init(...)")

  -- keep reference to browser process, so we can
  -- maintain the "locked" options at all times
  self._process = select(1,...)

  -- use Automation class to record movements
  self.automation = Automation()

  -- set while recording automation
  self._record_mode = true

  -- the various UIComponents
  self._grid = nil          -- UIButtons...
  self._mode_slider = nil   -- UISlider
  self._mode_even = nil     -- UIButton
  self._mode_triplet = nil  -- UIButton
  self._mode_dotted = nil   -- UIButton
  self._mode_free = nil     -- UIButton
  self._divisor_slider = nil -- UISlider
  self._lock_button = nil   -- UIButton
  self._prev_button = nil   -- UIButton
  self._next_button = nil   -- UIButton

  -- number, grid size in units
  self._grid_width = nil
  self._grid_height = nil

  -- table, organized by [x][y], each containing the following
  -- .divisor (number), the divisor value
  -- .mode (number), the mode value (0-4)
  -- .tooltip (string)
  self._grid_map = table.create()

  -- (table or nil) in grid mode, current coordinate 
  -- e.g. {x=number,y=number} 
  self._grid_coords = nil

  -- TrackDevice, the device we are currently controlling
  self.target_device = nil

  -- current blink-state (lock button)
  self._blink = false

  -- the target's track-index/device-index 
  self.track_index = nil
  self.device_index = nil

  -- boolean, set to temporarily skip value notifier
  self.suppress_value_observable = false

  self._parameter_observables = table.create()
  self._device_observables = table.create()

  self.update_requested = false
  self.current_device_requested = false

  Application.__init(self,...)

  -- determine stuff after options have been applied

  self.automation.latch_record = 
  (self.options.record_method.value == RECORD_LATCH)

end

--------------------------------------------------------------------------------

-- check configuration, build & start the application

function Repeater:start_app()
  TRACE("Repeater:start_app()")

  if not Application.start_app(self) then
    return
  end
  self:initial_select()

  self.update_requested = true
  --self:update_grid()
  --self:set_mode()

end

--------------------------------------------------------------------------------

-- this search is performed on application start
-- if not in locked mode: use the currently focused track->device
-- if we are in locked mode: recognize any locked devices, but fall back
--  to the focused track->device if no locked device was found

function Repeater:initial_select()
  TRACE("Repeater:initial_select()")

  local song = renoise.song()
  local device,track_idx,device_idx
  local search = self:do_device_search()
  if search then
    device = search.device
    track_idx = search.track_index
    device_idx = search.device_index
  else
    -- we failed to match a locked device,
    -- perform a 'soft' unlock
    self.options.locked.value = LOCKED_DISABLED
    self:update_lock_button()
  end
  if not device then
    device = song.selected_device
    track_idx = song.selected_track_index
    device_idx = song.selected_device_index
  end

  if self:device_is_repeater_dsp(device) then
    local skip_tag = true
    self:goto_device(track_idx,device_idx,device,skip_tag)
    self.update_requested = true
  end
  self:update_prev_next(track_idx,device_idx)

end

--------------------------------------------------------------------------------

-- goto previous device
-- search from locked device (if available), otherwise use the selected device
-- @return boolean

function Repeater:goto_previous_device()
  TRACE("Repeater:goto_previous_device()")

  local song = renoise.song()
  local track_index,device_index
  if self.target_device then
    track_index = self.track_index
    device_index = self.device_index
  else
    track_index = song.selected_track_index
    device_index = song.selected_device_index
  end

  local search = self:search_previous_device(track_index,device_index)
  if search then
    self:goto_device(search.track_index,search.device_index,search.device)
    self.update_controller_requested = true
  end
  self:follow_device_pos()
  return search and true or false

end

--------------------------------------------------------------------------------

-- goto next device
-- search from locked device (if available), otherwise use the selected device
-- @return boolean

function Repeater:goto_next_device()
  TRACE("Repeater:goto_next_device()")

  local song = renoise.song()
  local track_index,device_index
  if self.target_device then
    track_index = self.track_index
    device_index = self.device_index
  else
    track_index = song.selected_track_index
    device_index = song.selected_device_index
  end
  local search = self:search_next_device(track_index,device_index)
  if search then
    self:goto_device(search.track_index,search.device_index,search.device)
    self.update_controller_requested = true
  end
  self:follow_device_pos()
  return search and true or false

end


--------------------------------------------------------------------------------

-- locate the prior device
-- @param track_index/device_index, start search from here
-- @return table or nil

function Repeater:search_previous_device(track_index,device_index)
  TRACE("Repeater:search_previous_device()",track_index,device_index)

  local matched = nil
  local locked = (self.options.locked.value == LOCKED_ENABLED)
  local display_name = self:get_unique_name()
  for track_idx,v in ripairs(renoise.song().tracks) do
    local include_track = true
    if track_index and (track_idx>track_index) then
      include_track = false
    end
    if include_track then
      for device_idx,device in ripairs(v.devices) do
        local include_device = true
        if device_index and (device_idx>=device_index) then
          include_device = false
        end
        if include_device then
          local search = {
            track_index=track_idx,
            device_index=device_idx,
            device=device
          }
          if locked and (device.display_name == display_name) then
            return search
          elseif self:device_is_repeater_dsp(device) then
            return search
          end
        end

      end

    end

    if device_index and include_track then
      device_index = nil
    end

  end

end

--------------------------------------------------------------------------------

-- locate the next device
-- @param track_index/device_index, start search from here
-- @return table or nil

function Repeater:search_next_device(track_index,device_index)
  TRACE("Repeater:search_next_device()",track_index,device_index)

  local matched = nil
  local locked = (self.options.locked.value == LOCKED_ENABLED)
  local display_name = self:get_unique_name()
  for track_idx,v in ipairs(renoise.song().tracks) do
    local include_track = true
    if track_index and (track_idx<track_index) then
      include_track = false
    end
    if include_track then
      for device_idx,device in ipairs(v.devices) do
        local include_device = true
        if device_index and (device_idx<=device_index) then
          include_device = false
        end
        if include_device then
          local search = {
            track_index=track_idx,
            device_index=device_idx,
            device=device
          }
          if locked and (device.display_name == display_name) then
            return search
          elseif self:device_is_repeater_dsp(device) then
            return search
          end
        end
      end

    end

    if device_index and include_track then
      device_index = nil
    end

  end

end

--------------------------------------------------------------------------------

-- attach to a device, transferring the 'tag' if needed
-- this is the final step of a "previous/next device" operation,
-- or called during the initial search

function Repeater:goto_device(track_index,device_index,device,skip_tag)
  TRACE("Repeater:goto_device()",track_index,device_index,device,skip_tag)
  
  self:attach_to_device(track_index,device_index,device)

  if not skip_tag and 
    (self.options.locked.value == LOCKED_ENABLED) 
  then
    self:tag_device(device)
  end
  self.update_focus_requested = true
  self:update_prev_next(track_index,device_index)

end


--------------------------------------------------------------------------------

-- update the lit state of the previous/next device buttons
-- @track_index,device_index (number) the active track/device

function Repeater:update_prev_next(track_index,device_index)
  TRACE("Repeater:update_prev_next()",track_index,device_index)

  -- use locked device if available
  if (self.options.locked.value == LOCKED_ENABLED) then
    track_index = self.track_index
    device_index = self.device_index
  end

  if self._prev_button then
    local prev_search = self:search_previous_device(track_index,device_index)
    local prev_state = (prev_search) and true or false
    if prev_state then
      self._prev_button:set(self.palette.prev_device_on)
    else
      self._prev_button:set(self.palette.prev_device_off)
    end
  end
  if self._next_button then
    local next_search = self:search_next_device(track_index,device_index)
    local next_state = (next_search) and true or false
    if next_state then
      self._next_button:set(self.palette.next_device_on)
    else
      self._next_button:set(self.palette.next_device_off)
    end
  end

end


--------------------------------------------------------------------------------

-- look for any Repeater device that match the provided name
-- it is called right after the target device has been removed,
-- or by initial_select()

function Repeater:do_device_search()
  TRACE("Repeater:do_device_search()")

  local song = renoise.song()
  local display_name = self:get_unique_name()
  local device_count = 0
  for track_idx,track in ipairs(song.tracks) do
    for device_idx,device in ipairs(track.devices) do
      if self:device_is_repeater_dsp(device) and 
        (device.display_name == display_name) 
      then
        return {
          device=device,
          track_index=track_idx,
          device_index=device_idx
        }
      end
    end
  end

end


--------------------------------------------------------------------------------

-- get the unique name of the device, as specified in options

function Repeater:get_unique_name()
  TRACE("Repeater:get_unique_name()")
  
  local dev_name = self._process.browser._device_name
  local cfg_name = self._process.browser._configuration_name
  local app_name = self._app_name

  local unique_name = ("Repeater:%s_%s_%s"):format(dev_name,cfg_name,app_name)
  --print("unique_name",unique_name)
  return unique_name
  
end



--------------------------------------------------------------------------------

-- test if the device is a valid target 

function Repeater:device_is_repeater_dsp(device)
  TRACE("Repeater:device_is_repeater_dsp()",device)

  if device and (device.name == "Repeater") then
    return true
  else
    return false
  end
end

--------------------------------------------------------------------------------

-- tag device (add unique identifier), clearing existing one(s)
-- @device (TrackDevice), leave out to simply clear

function Repeater:tag_device(device)
  TRACE("Repeater:tag_device()",device)

  local display_name = self:get_unique_name()
  for _,track in ipairs(renoise.song().tracks) do
    for k,d in ipairs(track.devices) do
      if (d.display_name==display_name) then
        d.display_name = d.name
      end
    end
  end

  if device then
    device.display_name = display_name
  end

end


--------------------------------------------------------------------------------

-- perform periodic updates

function Repeater:on_idle()

  if (not self.active) then 
    return 
  end

  local song = renoise.song()

  -- set to the current device
  if self.current_device_requested then
    self.current_device_requested = false
    self.update_requested = true
    self:attach_to_selected_device()
    -- update prev/next
    local track_idx = song.selected_track_index
    local device_idx = song.selected_device_index
    self:update_prev_next(track_idx,device_idx)
    -- update lock button
    if self.target_device then
      self:update_lock_button()
    end

  end

  -- when device is unassignable, blink lock button
  if self._lock_button and not self.target_device then
    local blink = (math.floor(os.clock()%2)==1)
    if blink~=self._blink then
      self._blink = blink
      if blink then
        self._lock_button:set(self.palette.lock_on)
      else
        self._lock_button:set(self.palette.lock_off)
      end
    end
  end

  if self.update_requested then
    self:set_mode()
    self:set_divisor()
    self:update_grid()
    self.update_requested = false
  end

  if self._record_mode then
    self.automation:update()
  end

end

--------------------------------------------------------------------------------

-- return the currently focused track->device in Renoise
-- @return Device

function Repeater:get_selected_device()
  TRACE("Repeater:get_selected_device()")

  local song = renoise.song()
  local track_idx = song.selected_track_index
  local device_index = song.selected_device_index
  return song.tracks[track_idx].devices[device_index]   

end

--------------------------------------------------------------------------------

-- attempt to select the current device 
-- failing to do so will clear the target device

function Repeater:attach_to_selected_device()
  TRACE("Repeater:attach_to_selected_device()")

  if (self.options.locked.value == LOCKED_DISABLED) then
    local song = renoise.song()
    local device = self:get_selected_device()
    if self:device_is_repeater_dsp(device) then
      local track_idx = song.selected_track_index
      local device_idx = song.selected_device_index
      self:attach_to_device(track_idx,device_idx,device)
    else
      self:clear_device()
    end
  end
end


--------------------------------------------------------------------------------

-- attach notifier to the device 
-- called when we use previous/next device, set the initial device
-- or are freely roaming the tracks

function Repeater:attach_to_device(track_idx,device_idx,device)
  TRACE("Repeater:attach_to_device()",track_idx,device_idx,device)

  -- clear the previous device references
  self:_remove_notifiers(self._parameter_observables)

  local track_changed = (self.track_index ~= track_idx)

  self.target_device = device
  self.track_index = track_idx
  self.device_index = device_idx

  -- listen for changes to the mode/divisor parameters
  local mode_param = self:get_repeater_param("Mode")
  --print("mode_param.value_observable",mode_param.value_observable)
  self._parameter_observables:insert(mode_param.value_observable)
  mode_param.value_observable:add_notifier(
    self, 
    function()
      --print("mode_param notifier fired...")
      if not self.suppress_value_observable then
        self.update_requested = true
      end
    end 
  )
  local divisor_param = self:get_repeater_param("Divisor")
  self._parameter_observables:insert(divisor_param.value_observable)
  divisor_param.value_observable:add_notifier(
    self, 
    function()
      --print("divisor_param notifier fired...")
      if not self.suppress_value_observable then
        self.update_requested = true
      end
    end 
  )

  -- new track? attach_to_track_devices
  if track_changed then
    local track = renoise.song().tracks[track_idx]
    --print("*** about to attach to track",track_idx,track)
    self:_attach_to_track_devices(track)
  end

  self:update_lock_button()

end


--------------------------------------------------------------------------------

-- keep track of devices (insert,remove,swap...)
-- invoked by attach_to_device()

function Repeater:_attach_to_track_devices(track)
  TRACE("Repeater:_attach_to_track_devices",track)

  self:_remove_notifiers(self._device_observables)
  self._device_observables = table.create()

  self._device_observables:insert(track.devices_observable)
  track.devices_observable:add_notifier(
    function(notifier)
      TRACE("Repeater:devices_observable fired...")
      --rprint(notifier)
      --[[
      if (notifier.type == "insert") then
        -- TODO stop when index is equal to, or higher 
      end
      ]]
      if (notifier.type == "swap") and self.device_index then
        if (notifier.index1 == self.device_index) then
          self.device_index = notifier.index2
        elseif (notifier.index2 == self.device_index) then
          self.device_index = notifier.index1
        end
      end

      if (notifier.type == "remove") then

        local search = self:do_device_search()
        if not search then
          self:clear_device()
        else
          if (search.track_index ~= self.track_index) then
            self:clear_device()
            self:initial_select()
          end
        end
      end
      self.automation:stop_automation()

    end
  )
end

--------------------------------------------------------------------------------

-- select track + device, but only when follow_pos is enabled

function Repeater:follow_device_pos()
  TRACE("Repeater:follow_device_pos()")

  if (self.options.follow_pos.value == FOLLOW_POS_ENABLED) then
    if self.track_index then
      renoise.song().selected_track_index = self.track_index
      renoise.song().selected_device_index = self.device_index
    end
  end

end


--------------------------------------------------------------------------------

-- update the state of the lock button

function Repeater:update_lock_button()
  TRACE("Repeater:update_lock_button()")

  if self._lock_button then
    if (self.options.locked.value == LOCKED_ENABLED) then
      self._lock_button:set(self.palette.lock_on)
    else
      self._lock_button:set(self.palette.lock_off)
    end
  end

end


--------------------------------------------------------------------------------

-- (grid mode) update everything: the mode and/or divisor value is gained
-- and the grid cells are drawn accordingly. Also, record automation. 

function Repeater:set_value_from_coords(x,y)
  TRACE("Repeater:set_value_from_coords(x,y)",x,y)

  if not self.target_device then
    return
  end

  local cell = self._grid_map[x][y]

  -- check if out-of-bounds 
  if not cell.divisor then
    --print("Ignore unmapped button")
    return
  end

  -- check if already active, and toggle state
  if self._grid_coords then
    if (x == self._grid_coords.x) and 
      (y == self._grid_coords.y) 
    then
      self:stop_repeating()
      -- TODO if button is held, toggle "hold" mode
      return
    end
  end
  
  self:set_divisor(cell.divisor)
  self:set_mode(cell.mode)
  self:update_grid(x,y)

end

--------------------------------------------------------------------------------

-- switch the mode (update device, mode buttons/slider)
-- @param enum_mode (number) one of the MODE_xx constants
-- @param toggle (boolean) when mode-select button is pushed

function Repeater:set_mode(enum_mode,toggle)
  TRACE("Repeater:set_mode(enum_mode,toggle)",enum_mode,toggle)

  if not self.target_device then
    return 
  end

  local mode_param = self:get_repeater_param("Mode")

  -- return if value hasn't changed
  if (mode_param.value == enum_mode) then
    return
  end

  if (enum_mode == nil) then
    -- if no value was provided, use the device value
    enum_mode = mode_param.value
  else
    -- check if we should toggle
    --[[
    if toggle and (enum_mode == mode_param.value) then
      print("*** MODE_OFF")
      enum_mode = MODE_OFF
    end
    ]]

    -- update device
    self.suppress_value_observable = true
    mode_param.value = enum_mode
    self.suppress_value_observable = false

  end

  -- update the grid mode? this is done only if:
  -- (1) the mode isn't MODE_OFF (this mode isn't selectable)
  -- (2) a mode button was pushed (the "toggle" argument)
  -- (3) grid button pushed in non-automatic layout (fewer buttons)
  if (enum_mode ~= MODE_OFF) then
    if toggle or (not toggle and (self.options.mode_select.value ~= MODE_AUTO))
    then
      self:_set_option("mode_select",enum_mode,self._process)
    end
  end

  -- update the slider
  if self._mode_slider then
    local skip_event = true
    self._mode_slider:set_value(enum_mode/4,skip_event)
  end

  -- update the buttons
  if enum_mode ~= MODE_OFF then
    if self._mode_even then
      if enum_mode == MODE_EVEN then
        self._mode_even:set(self.palette.mode_even_on)
      else
        self._mode_even:set(self.palette.mode_even_off)
      end
    end
    if self._mode_triplet then
      if enum_mode == MODE_TRIPLET then
        self._mode_triplet:set(self.palette.mode_triplet_on)
      else
        self._mode_triplet:set(self.palette.mode_triplet_off)
      end
    end
    if self._mode_dotted then
      if enum_mode == MODE_DOTTED then
        self._mode_dotted:set(self.palette.mode_dotted_on)
      else
        self._mode_dotted:set(self.palette.mode_dotted_off)
      end
    end
    if self._mode_free then
      if enum_mode == MODE_FREE then
        self._mode_free:set(self.palette.mode_free_on)
      else
        self._mode_free:set(self.palette.mode_free_off)
      end
    end
  end

  -- update automation
  if self._record_mode then
    local playmode = renoise.PatternTrackAutomation.PLAYMODE_POINTS
    self.automation:add_automation(self.track_index,mode_param,enum_mode/4,playmode)
  end

end

--------------------------------------------------------------------------------

--- Update divisor (call without argument to use existing value)
-- @param divisor_val (number) [optional] between 0 and 1

function Repeater:set_divisor(divisor_val)
  TRACE("Repeater:set_divisor(divisor_val)",divisor_val)

  if not self.target_device then
    return 
  end

  local divisor_param = self:get_repeater_param("Divisor")

  if divisor_val then

    -- update device
    local str_value = ("1/%f"):format(1/divisor_val)
    self.suppress_value_observable = true
    divisor_param.value_string = str_value
    self.suppress_value_observable = false
  end

  -- update the slider
  if self._divisor_slider then
    local skip_event = true
    self._divisor_slider:set_value(divisor_param.value,skip_event)
  end

  -- update automation
  if self._record_mode then
    local playmode = renoise.PatternTrackAutomation.PLAYMODE_POINTS
    self.automation:add_automation(self.track_index,divisor_param,divisor_param.value,playmode)
  end


end

--------------------------------------------------------------------------------

-- this method will calculate a the divisor from a linear value
-- (e.g. 0.5 will output 1/8 == 0.125)
-- @param divisor_val (number) between 0 and 1

function Repeater:divisor_from_linear_value(divisor_val)
  TRACE("Repeater:set_divisor_from_linear_value(divisor_val)",divisor_val)

  if (divisor_val == 0) then
    return 1
  end

  local step_size = 1/8
  local step = math.ceil(divisor_val/step_size)
  local step_fraction = step-(divisor_val/step_size)
  --print("step,step_fraction",step,step_fraction)
  local divisor_val = DIVISORS[step] 
  if (step>1) then
    divisor_val = divisor_val + (DIVISORS[step] * step_fraction)
  end

  return divisor_val

end

--------------------------------------------------------------------------------

-- set device to OFF mode, update controller + automation

function Repeater:stop_repeating()
  TRACE("Repeater:stop_repeating()")

  self:set_mode(MODE_OFF)
  self:update_grid()

end

--------------------------------------------------------------------------------

-- @param name (string)
-- @return DeviceParameter

function Repeater:get_repeater_param(param_name)
  TRACE("Repeater:get_repeater_param(param_name)",param_name)

  if (self.target_device) then
    for k,v in pairs(self.target_device.parameters) do
      if (v.name == param_name) then
        return v
      end
    end
  end

end

--------------------------------------------------------------------------------

-- configure a map of mode/divisor values for the available buttons
-- even/triplet/dotted: update divisor value by quantized amount
-- free: update the divisor value by an exact amount

function Repeater:init_grid()
  TRACE("Repeater:init_grid()")

  local map = self.mappings.grid
  if not map.group_name then
    --print("Repeater: init_grid failed")
    return
  end

  -- clear the current grid display
  self._grid_map = table.create()


  local min_divisor = DIVISORS[self.options.divisor_min.value]
  local max_divisor = DIVISORS[self.options.divisor_max.value]

  local produce_cell = function(mode,value)
    local tooltip = ""
    if value then
      --print("produce_cell",mode,value)
      if (mode == MODE_FREE) then
        tooltip = ("%.2f"):format(1/value)
      else
        tooltip = ("%i"):format(1/value)
      end
      if (mode == MODE_TRIPLET) then
        tooltip = tooltip.."T"
      elseif (mode == MODE_DOTTED) then
        tooltip = tooltip.."D"
      end
    end
    local cell = {
      divisor = value,
      mode = mode,
      tooltip = tooltip
    }
    return cell
  end

  if (self.options.mode_select.value == MODE_FREE) then
    
    -- distribute freely across grid

    local count = 1
    --local step_size = 127/((self._grid_width*self._grid_height)-1)
    local step_size = 1/((self._grid_width*self._grid_height))
    for y=1,self._grid_height do
      for x=1,self._grid_width do
        if not self._grid_map[x] then
          self._grid_map[x] = table.create()
        end
        --function scale_value(value,low_val,high_val,min_val,max_val)
        local val = step_size*count
        --local val_scaled = scale_value(val,0,127,min_divisor,max_divisor)
        local val_scaled = self:divisor_from_linear_value(val)
        --print("val_scaled",val_scaled)
        local cell = {
          divisor = val_scaled,
          mode = MODE_FREE,
          tooltip = ("1/%f"):format(1/val_scaled)
        }
        self._grid_map[x][y] = produce_cell(MODE_FREE,val_scaled)
        count = count+1
      end
    end

  elseif (self.options.mode_select.value == MODE_AUTO) then

    -- automatic layout, will mimic the repeater device
    -- by creating one row for each mode (even/triplet/dotted)

    for x=1,self._grid_width do
      for y=1,self._grid_height do
        if not self._grid_map[x] then
          self._grid_map[x] = table.create()
        end
        local mode = (y==1) and MODE_EVEN 
          or (y==2) and MODE_TRIPLET 
          or (y==3) and MODE_DOTTED

        self._grid_map[x][y] = produce_cell(mode,DIVISORS[x])
      end
    end


  else

    -- fill with quantized intervals

    local count = 1
    for y=1,self._grid_height do
      for x=1,self._grid_width do
        if not self._grid_map[x] then
          self._grid_map[x] = table.create()
        end
        --function scale_value(value,low_val,high_val,min_val,max_val)
        local mode = self.options.mode_select.value
        self._grid_map[x][y] = produce_cell(mode,DIVISORS[count])
        count = count+1
      end
    end


  end

  -- update visual appearance + tooltips
  for x=1,self._grid_width do
    for y=1,self._grid_height do
      local cell = self._grid_map[x][y]
      self._grid[x][y].tooltip = ("Repeater: 1 / %s"):format(cell.tooltip)
      self._grid[x][y]:set_palette({foreground={text=cell.tooltip}})
    end
  end
  self.display:apply_tooltips(self.mappings.grid.group_name)

  --rprint(self._grid_map)

end

--------------------------------------------------------------------------------

-- construct the user interface

function Repeater:_build_app()
  TRACE("Repeater:_build_app()")

  local cm = self.display.device.control_map

  -- button grid
  local map = self.mappings.grid
  if map.group_name then

    -- determine if valid target (grid)
    if not cm:is_grid_group(map.group_name) then
      local msg = "Repeater: could not assign 'grid', the control-map group is invalid"
        .."\n(please assign the mapping to a group made entirely from buttons)"
      renoise.app():show_warning(msg)
      --return false
    else
      -- determine the grid size 
      self._grid_width = cm:count_columns(map.group_name)
      self._grid_height = cm:count_rows(map.group_name)

      self._grid = table.create()

      for x=1,self._grid_width do
        self._grid[x] = table.create()
        for y=1,self._grid_height do
          local c = UIButton(self.display)
          c.group_name = map.group_name
          c:set_pos(x,y)
          c.on_press = function()
            if not self.active then
              return false
            end
            self:set_value_from_coords(x,y)
          end
          c.on_release = function(obj)
            if not self.active then
              return false
            end
            if (self.options.hold_option.value == HOLD_DISABLED) then
              if self._grid_coords and
                (x == self._grid_coords.x) and 
                (y == self._grid_coords.y) 
              then
                self:stop_repeating()
              end
            end
          end
          self:_add_component(c)
          self._grid[x][y] = c
        end
      end

      self:init_grid(self._grid_width,self._grid_height)

    end



  end

  -- lock button
  local map = self.mappings.lock_button
  if map.group_name then
    local c = UIButton(self.display)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)

      if not self.active then 
        return false 
      end
      local track_idx = renoise.song().selected_track_index
      if (self.options.locked.value ~= LOCKED_ENABLED) then
        -- attempt to lock device
        if not self.target_device then
          return 
        end
        -- set preference and update device name 
        self:_set_option("locked",LOCKED_ENABLED,self._process)
        self:tag_device(self.target_device)
      else
        -- unlock only when locked
        if (self.options.locked.value == LOCKED_ENABLED) then
          -- set preference and update device name 
          self:_set_option("locked",LOCKED_DISABLED,self._process)
          self.current_device_requested = true
          self:tag_device(nil)
        end

      end
      self:update_lock_button()

    end
    self:_add_component(c)
    self._lock_button = c
  end

  -- mode slider
  local map = self.mappings.mode_slider
  if map.group_name then
    local args = cm:get_indexed_element(map.index,map.group_name)
    local c = UISlider(self.display)
    c.group_name = map.group_name
    c:set_pos(map.index)
    c.tooltip = map.description
    c.on_change = function(obj)
      if not self.active then 
        return false 
      end
      local mode_val = round_value(obj.value*4)
      self:set_mode(mode_val)
    end
    self:_add_component(c)
    self._mode_slider = c
  end

  -- divisor slider
  local map = self.mappings.divisor_slider
  if map.group_name then
    local c = UISlider(self.display)
    c.group_name = map.group_name
    c:set_pos(map.index)
    --c.ceiling = 127
    c.tooltip = map.description
    c.on_change = function(obj)
      if not self.active then 
        return false 
      end
      local divisor_val = self:divisor_from_linear_value(obj.value)
      self:set_divisor(divisor_val)
      self.update_requested = true

    end
    self:_add_component(c)
    self._divisor_slider = c
  end

  -- mode_even
  local map = self.mappings.mode_even
  if map.group_name then
    local c = UIButton(self.display)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set(self.palette.mode_even_off)
    c:set_pos(map.index)
    c.on_press = function(obj)
      if not self.active then 
        return false 
      end
      self:set_mode(MODE_EVEN,true)
    end
    self:_add_component(c)
    self._mode_even = c
  end

  -- mode_triplet
  local map = self.mappings.mode_triplet
  if map.group_name then
    local c = UIButton(self.display)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set(self.palette.mode_triplet_off)
    c:set_pos(map.index)
    c.on_press = function(obj)
      if not self.active then 
        return false 
      end
      self:set_mode(MODE_TRIPLET,true)
    end
    self:_add_component(c)
    self._mode_triplet = c
  end

  -- mode_dotted
  local map = self.mappings.mode_dotted
  if map.group_name then
    local c = UIButton(self.display)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set(self.palette.mode_dotted_off)
    c:set_pos(map.index)
    c.on_press = function(obj)
      if not self.active then 
        return false 
      end
      self:set_mode(MODE_DOTTED,true)
    end
    self:_add_component(c)
    self._mode_dotted = c
  end

  -- mode_free
  local map = self.mappings.mode_free
  if map.group_name then
    local c = UIButton(self.display)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set(self.palette.mode_free_off)
    c:set_pos(map.index)
    c.on_press = function(obj)
      if not self.active then 
        return false 
      end
      self:set_mode(MODE_FREE,true)
    end
    self:_add_component(c)
    self._mode_free = c
  end

  -- previous device button
  local map = self.mappings.prev_device
  if map.group_name then
    local c = UIButton(self.display)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      if not self.active then return false end
      self:goto_previous_device()
    end
    self:_add_component(c)
    self._prev_button = c
  end

  -- next device button
  local map = self.mappings.next_device
  if map.group_name then
    local c = UIButton(self.display)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      if not self.active then return false end
      self:goto_next_device()
    end
    self:_add_component(c)
    self._next_button = c
  end


  -- attach to song at first run
  self:_attach_to_song()

  return true

end

--------------------------------------------------------------------------------

-- update controller grid (no impact on Renoise)

function Repeater:update_grid(x,y)
  TRACE("Repeater:update_grid(x,y)",x,y)

  if not self.target_device then
    print("no target device, cannot update grid")
    return
  end

  if not self._grid then
    print("no grid present, cannot update")
    return
  end

  -- turn off the current button
  if self._grid_coords then
    local old_x = self._grid_coords.x
    local old_y = self._grid_coords.y
    if (old_x ~= x) or (old_y ~= y) then
      local palette = {
        foreground = {
          color = self.palette.disabled.color,
          val = self.palette.disabled.val,
        }
      }
      self._grid[old_x][old_y]:set_palette(palette)
    end
  end

  local mode_param = self:get_repeater_param("Mode")
  if (mode_param.value ==MODE_OFF) then
    print("Repeater mode is OFF, nothing more to update")
    self._grid_coords = nil
    return
  end

  -- determine coords from current device settings
  if not x and not y then
    local mode_divisor = self:get_repeater_param("Divisor")
    for grid_x=1,self._grid_width do
      for grid_y=1,self._grid_height do
        local cell = self._grid_map[grid_x][grid_y]
        rprint(cell)
        if not cell.divisor or 
          (cell.mode == MODE_OFF) 
        then
          -- ignore unmapped or disabled buttons
        else
          local str_value = nil
          if (cell.mode == MODE_FREE) then
            str_value = ("1 / %.2f"):format(1/cell.divisor)
          else
            str_value = ("1 / %i"):format(1/cell.divisor)
          end
          if (round_value(mode_param.value) == cell.mode) and
            (mode_divisor.value_string == str_value)
          then
            x = grid_x
            y = grid_y
          end
        end
      end
    end
  end

  if x and y and (self._grid[x][y]) then
    local palette = {
      foreground = {
        color = self.palette.enabled.color,
        val = self.palette.enabled.val,
      }
    }
    self._grid[x][y]:set_palette(palette)
    self._grid_coords = {x=x,y=y}
  end


end

--------------------------------------------------------------------------------

-- called whenever a new document becomes available

function Repeater:on_new_document()
  TRACE("Repeater:on_new_document()")

  self:_attach_to_song()
  self:initial_select()

end

--------------------------------------------------------------------------------

--- Called when releasing the active document

function Repeater:on_release_document()
  TRACE("Repeater:on_release_document()")
  
  self:_remove_notifiers(self._device_observables)
  self.target_device = nil
  self.track_index = nil
  self.device_index = nil

end



--------------------------------------------------------------------------------

-- de-attach from the device

function Repeater:clear_device()
  TRACE("Repeater:clear_device()")

  self:_remove_notifiers(self._parameter_observables)
  self.automation:stop_automation()
  self.target_device = nil
  self.track_index = nil
  self.device_index = nil

end


--------------------------------------------------------------------------------

-- update the record mode (when editmode or record_method has changed)

function Repeater:_update_record_mode()
  TRACE("Repeater:_update_record_mode()")
  if (self.options.record_method.value ~= RECORD_NONE) then
    self._record_mode = renoise.song().transport.edit_mode 
  else
    self._record_mode = false
  end
end


--------------------------------------------------------------------------------

-- attach notifier to the song, handle changes

function Repeater:_attach_to_song()
  TRACE("Repeater:_attach_to_song()")

  -- update when a device is selected
  renoise.song().selected_device_observable:add_notifier(
    function()
      TRACE("Repeater:selected_device_observable")
      self.current_device_requested = true
    end
  )

  -- track edit_mode, and set record_mode accordingly
  renoise.song().transport.edit_mode_observable:add_notifier(
    function()
      TRACE("Repeater:edit_mode_observable fired...")
      self:_update_record_mode()
    end
  )
  self._record_mode = renoise.song().transport.edit_mode


  -- also call Automation class
  self.automation:attach_to_song()

end

--------------------------------------------------------------------------------

-- @param observables - list of observables
function Repeater:_remove_notifiers(observables)
  TRACE("Repeater:_remove_notifiers()",observables)

  for _,observable in pairs(observables) do
    -- temp security hack. can also happen when removing FX
    pcall(function() observable:remove_notifier(self) end)
  end
    
  observables:clear()

end
