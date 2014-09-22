--[[============================================================================
-- Duplex.RoamingDSP
============================================================================]]--

--[[--
Extend this class if you want an application to lock onto a specific type of device, or navigate between similar devices.
Inheritance: @{Duplex.Application} > Duplex.RoamingDSP

The application can target any device that has been selected in Renoise, freely roaming the tracks. If the lock button starts to blink slowly, it is to remind you that the application is currently 'homeless', has no matching device to control. 

Opposite to the "free-roaming mode" we have the "locked mode" which will lock to a single device. The locked mode can either be set by being mapped to a button, or via the options dialog. In either case, the application will 'tag' the device with a unique name. 

To complement the "lock" button, we also have a "focus" button. This button brings focus back to the locked device, whenever you have (manually) selected an un-locked device.

Finally, we can navigate between devices by using the 'next' and 'previous' buttons. In case we have locked to a device, previous/next will "transfer" the lock to that device.


### Changes

  0.98
    - First release


]]--

----------------------------------------------------------------------------]]--

class 'RoamingDSP' (Application)

RoamingDSP.FOLLOW_POS_ENABLED = 1
RoamingDSP.FOLLOW_POS_DISABLED = 2
RoamingDSP.LOCKED_ENABLED = 1
RoamingDSP.LOCKED_DISABLED = 2
RoamingDSP.RECORD_NONE = 1 -- No recording
RoamingDSP.RECORD_TOUCH = 2 -- Record when touched
RoamingDSP.RECORD_LATCH = 3 -- Record once touched

---  Options
-- @field locked Enable/Disable locking
-- @field record_method Determine how to record automation
-- @field follow_pos Follow the selected device in the DSP chain
-- @table default_options
RoamingDSP.default_options = {
  locked = {
    label = "Lock to device",
    description = "Disable locking if you want the controls to"
                .."\nfollow the currently selected device ",
    on_change = function(app)
      if (app.options.locked.value == RoamingDSP.LOCKED_DISABLED) then
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
      (inst.options.record_method.value == RoamingDSP.RECORD_LATCH) and true or false
    end
  },
  follow_pos = {
    label = "Follow pos",
    description = "Follow the selected device in the DSP chain",
    items = {
      "Enabled",
      "Disabled"
    },
    value = 1,
  },

}


---  Mappings
-- @field lock_button control the locked state of the selected device
-- @field next_device used for locating a device across tracks
-- @field prev_device used for locating a device across tracks
-- @table available_mappings
RoamingDSP.available_mappings = {
  lock_button = {
    description = "Lock/unlock device",
  },
  next_device = {
    description = "Next device",
  },
  prev_device = {
    description = "Previous device",
  },


}

RoamingDSP.default_palette = {
  lock_on           = { color = {0xFF,0xFF,0xFF}, text = "♥", val=true  },
  lock_off          = { color = {0x00,0x00,0x00}, text = "♥", val=false },
  prev_device_on    = { color = {0xFF,0xFF,0xFF}, text = "◄", val=true  },
  prev_device_off   = { color = {0x00,0x00,0x00}, text = "◄", val=false },
  next_device_on    = { color = {0xFF,0xFF,0xFF}, text = "►", val=true  },
  next_device_off   = { color = {0x00,0x00,0x00}, text = "►", val=false },
}

--------------------------------------------------------------------------------

--- Constructor method
-- @param (VarArg), see Application to learn more

function RoamingDSP:__init(...)
  TRACE("RoamingDSP:__init()")

  --- (@{Duplex.Automation}) used for recording movements
  self.automation = Automation()

  --- (bool) set while recording automation
  self._record_mode = true

  -- the various UIComponents
  self._controls = {}
  --self._controls.lock_button = nil   -- UIButton
  --self._controls.prev_button = nil   -- UIButton
  --self._controls.next_button = nil   -- UIButton

  --- (renoise.AudioDevice) the device we are currently controlling
  self.target_device = nil

  --- (bool) current blink-state (lock button)
  self._blink = false

  --- (int) the target track index
  self.track_index = nil

  --- (int) the target device index 
  self.device_index = nil

  --- (bool), set when we should attempt to attach to 
  -- the current device (althought we might not succeed)
  self.current_device_requested = false

  --- (table) list of observable parameters
  self._parameter_observables = table.create()

    --- (table) list of observable device parameters
  self._device_observables = table.create()

  Application.__init(self,...)

  -- determine stuff after options have been applied

  self.automation.latch_record = 
  (self.options.record_method.value == RoamingDSP.RECORD_LATCH)

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.start_app
-- @return bool or nil

function RoamingDSP:start_app()
  TRACE("RoamingDSP:start_app()")

  if not self._instance_name then
    local msg = "Could not start instance of Duplex RoamingDSP:"
              .."\nthe required property 'self._instance_name' has not"
              .."\nbeen specified, the application has been halted"
    renoise.app():show_warning(msg)
    return false
  end

  if not Application.start_app(self) then
    return false
  end

  self:initial_select()

end

--------------------------------------------------------------------------------

--- this search is performed on application start
-- if not in locked mode: use the currently focused track->device
-- if we are in locked mode: recognize any locked devices, but fall back
--  to the focused track->device if no locked device was found

function RoamingDSP:initial_select()
  TRACE("RoamingDSP:initial_select()")

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
    self.options.locked.value = RoamingDSP.LOCKED_DISABLED
    self:update_lock_button()
  end
  if not device then
    device = song.selected_device
    track_idx = song.selected_track_index
    device_idx = song.selected_device_index
  end

  if self:device_is_valid(device) then
    local skip_tag = true
    self:goto_device(track_idx,device_idx,device,skip_tag)
  end
  self:update_prev_next(track_idx,device_idx)

end

--------------------------------------------------------------------------------

--- goto previous device
-- search from locked device (if available), otherwise use the selected device
-- @return bool

function RoamingDSP:goto_previous_device()
  TRACE("RoamingDSP:goto_previous_device()")

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
  end
  self:follow_device_pos()
  return search and true or false

end

--------------------------------------------------------------------------------

--- goto next device
-- search from locked device (if available), otherwise use the selected device
-- @return bool

function RoamingDSP:goto_next_device()
  TRACE("RoamingDSP:goto_next_device()")

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
  end
  self:follow_device_pos()
  return search and true or false

end


--------------------------------------------------------------------------------

--- locate the prior device
-- @param track_index (int) start search from here
-- @param device_index (int) start search from here
-- @return table or nil

function RoamingDSP:search_previous_device(track_index,device_index)
  TRACE("RoamingDSP:search_previous_device()",track_index,device_index)

  local matched = nil
  local locked = (self.options.locked.value == RoamingDSP.LOCKED_ENABLED)
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
          elseif self:device_is_valid(device) then
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

--- locate the next device
-- @param track_index (int) start search from here
-- @param device_index (int) start search from here
-- @return table or nil

function RoamingDSP:search_next_device(track_index,device_index)
  TRACE("RoamingDSP:search_next_device()",track_index,device_index)

  local matched = nil
  local locked = (self.options.locked.value == RoamingDSP.LOCKED_ENABLED)
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
          elseif self:device_is_valid(device) then
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

--- attach to a device, transferring the 'tag' if needed
-- this is the final step of a "previous/next device" operation,
-- or called during the initial search
-- @param track_index (int) start search from here
-- @param device_index (int) start search from here
-- @param device (renoise.AudioDevice)
-- @param skip_tag (bool) don't tag device

function RoamingDSP:goto_device(track_index,device_index,device,skip_tag)
  TRACE("RoamingDSP:goto_device()",track_index,device_index,device,skip_tag)
  
  self:attach_to_device(track_index,device_index,device)

  if not skip_tag and 
    (self.options.locked.value == RoamingDSP.LOCKED_ENABLED) 
  then
    self:tag_device(device)
  end
  self:update_prev_next(track_index,device_index)

end


--------------------------------------------------------------------------------

--- update the lit state of the previous/next device buttons
-- @param track_index (int) 
-- @param device_index (int) 

function RoamingDSP:update_prev_next(track_index,device_index)

  -- use locked device if available
  if (self.options.locked.value == RoamingDSP.LOCKED_ENABLED) then
    track_index = self.track_index
    device_index = self.device_index
  end

  if self._controls.prev_button then
    local prev_search = self:search_previous_device(track_index,device_index)
    local prev_state = (prev_search) and true or false
    if prev_state then
      self._controls.prev_button:set(self.palette.prev_device_on)
    else
      self._controls.prev_button:set(self.palette.prev_device_off)
    end
  end
  if self._controls.next_button then
    local next_search = self:search_next_device(track_index,device_index)
    local next_state = (next_search) and true or false
    if next_state then
      self._controls.next_button:set(self.palette.next_device_on)
    else
      self._controls.next_button:set(self.palette.next_device_off)
    end
  end

end


--------------------------------------------------------------------------------

--- look for a device that match the provided name
-- it is called right after the target device has been removed,
-- or by initial_select()

function RoamingDSP:do_device_search()

  local song = renoise.song()
  local display_name = self:get_unique_name()
  local device_count = 0
  for track_idx,track in ipairs(song.tracks) do
    for device_idx,device in ipairs(track.devices) do
      if self:device_is_valid(device) and 
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

--- get the unique name of the device, as specified in options
-- @return string

function RoamingDSP:get_unique_name()
  
  local dev_name = self._process.browser._device_name
  local cfg_name = self._process.browser._configuration_name
  local app_name = self._app_name
  local inst = self._instance_name

  local unique_name = ("%s:%s_%s_%s"):format(inst,dev_name,cfg_name,app_name)
  return unique_name
  
end



--------------------------------------------------------------------------------

--- test if the device is a valid target 
-- @param device (renoise.AudioDevice)
-- @return bool

function RoamingDSP:device_is_valid(device)

  TRACE("RoamingDSP:device_is_valid(device)",device,"instance_name",self._instance_name)

  if device and (device.name == self._instance_name) then
    return true
  else
    return false
  end
end

--------------------------------------------------------------------------------

--- tag device (add unique identifier), clearing existing one(s)
-- @param device (renoise.AudioDevice), leave out to simply clear

function RoamingDSP:tag_device(device)

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

--- inherited from Application
-- @see Duplex.Application.on_idle

function RoamingDSP:on_idle()

  if (not self.active) then 
    return 
  end

  local song = renoise.song()

  -- set to the current device
  if self.current_device_requested then
    self.current_device_requested = false
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
  if self._controls.lock_button and not self.target_device then
    local blink = (math.floor(os.clock()%2)==1)
    if blink~=self._blink then
      self._blink = blink
      if blink then
        self._controls.lock_button:set(self.palette.lock_on)
      else
        self._controls.lock_button:set(self.palette.lock_off)
      end
    end
  end


  if self._record_mode then
    self.automation:update()
  end

end

--------------------------------------------------------------------------------

--- return the currently focused track->device in Renoise
-- @return Device

function RoamingDSP:get_selected_device()

  local song = renoise.song()
  local track_idx = song.selected_track_index
  local device_index = song.selected_device_index
  return song.tracks[track_idx].devices[device_index]   

end

--------------------------------------------------------------------------------

--- attempt to select the current device 
-- failing to do so will clear the target device

function RoamingDSP:attach_to_selected_device()

  if (self.options.locked.value == RoamingDSP.LOCKED_DISABLED) then
    local song = renoise.song()
    local device = self:get_selected_device()
    if self:device_is_valid(device) then
      local track_idx = song.selected_track_index
      local device_idx = song.selected_device_index
      self:attach_to_device(track_idx,device_idx,device)
    else
      self:clear_device()
    end
  end
end


--------------------------------------------------------------------------------

--- attach notifier to the device 
-- called when we use previous/next device, set the initial device
-- or are freely roaming the tracks

function RoamingDSP:attach_to_device(track_idx,device_idx,device)

  -- clear the previous device references
  self:_remove_notifiers(self._parameter_observables)

  local track_changed = (self.track_index ~= track_idx)

  self.target_device = device
  self.track_index = track_idx
  self.device_index = device_idx

  -- new track? attach_to_track_devices
  if track_changed then
    local track = renoise.song().tracks[track_idx]
    self:_attach_to_track_devices(track)
  end

  self:update_lock_button()

end


--------------------------------------------------------------------------------

-- @param name (string)
-- @return DeviceParameter or nil

function RoamingDSP:get_device_param(param_name)

  if (self.target_device) then
    for k,v in pairs(self.target_device.parameters) do
      if (v.name == param_name) then
        return v
      end
    end
  end

end


--------------------------------------------------------------------------------

-- update automation 
-- @param track_idx (int)
-- @param device_param (DeviceParameter)
-- @param value (number) 
-- @param playmode (enum) 

function RoamingDSP:update_automation(track_idx,device_param,value,playmode)

  if self._record_mode then
    
    -- default to points mode
    if not playmode then
      playmode = renoise.PatternTrackAutomation.PLAYMODE_POINTS
    end

    self.automation:add_automation(track_idx,device_param,value,playmode)

  end

end

--------------------------------------------------------------------------------

--- keep track of devices (insert,remove,swap...)
-- invoked by `attach_to_device()`
-- @param track (renoise.Track)

function RoamingDSP:_attach_to_track_devices(track)
  TRACE("RoamingDSP:_attach_to_track_devices()",track)

  self:_remove_notifiers(self._device_observables)
  self._device_observables = table.create()

  self._device_observables:insert(track.devices_observable)
  track.devices_observable:add_notifier(
    function(notifier)
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

--- select track + device, but only when follow_pos is enabled

function RoamingDSP:follow_device_pos()
  TRACE("RoamingDSP:follow_device_pos()")

  if (self.options.follow_pos.value == RoamingDSP.FOLLOW_POS_ENABLED) then
    if self.track_index then
      renoise.song().selected_track_index = self.track_index
      renoise.song().selected_device_index = self.device_index
    end
  end

end


--------------------------------------------------------------------------------

--- update the state of the lock button

function RoamingDSP:update_lock_button()
  TRACE("RoamingDSP:update_lock_button()")

  if self._controls.lock_button then
    if (self.options.locked.value == RoamingDSP.LOCKED_ENABLED) then
      self._controls.lock_button:set(self.palette.lock_on)
    else
      self._controls.lock_button:set(self.palette.lock_off)
    end
  end

end


--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application._build_app
-- @return bool

function RoamingDSP:_build_app()
  TRACE("RoamingDSP:_build_app()")

  local cm = self.display.device.control_map

  -- lock button
  local map = self.mappings.lock_button
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      TRACE("RoamingDSP - lock_button.on_press()")
      local track_idx = renoise.song().selected_track_index
      if (self.options.locked.value ~= RoamingDSP.LOCKED_ENABLED) then
        -- attempt to lock device
        if not self.target_device then
          return 
        end
        -- set preference and update device name 
        self:_set_option("locked",RoamingDSP.LOCKED_ENABLED,self._process)
        self:tag_device(self.target_device)
      else
        -- unlock only when locked
        if (self.options.locked.value == RoamingDSP.LOCKED_ENABLED) then
          -- set preference and update device name 
          self:_set_option("locked",RoamingDSP.LOCKED_DISABLED,self._process)
          self.current_device_requested = true
          self:tag_device(nil)
        end

      end
      self:update_lock_button()

    end
    self._controls.lock_button = c
  end

  -- previous device button
  local map = self.mappings.prev_device
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      TRACE("RoamingDSP - prev_device.on_press()")
      self:goto_previous_device()
    end
    self._controls.prev_button = c
  end

  -- next device button
  local map = self.mappings.next_device
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      TRACE("RoamingDSP - next_device.on_press()")
      self:goto_next_device()
    end
    self._controls.next_button = c
  end

  return true

end


--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_new_document

function RoamingDSP:on_new_document()

  self:_attach_to_song()
  self:initial_select()

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_release_document

function RoamingDSP:on_release_document()
  
  self:_remove_notifiers(self._device_observables)
  self.target_device = nil
  self.track_index = nil
  self.device_index = nil

end

--------------------------------------------------------------------------------

--- de-attach from the device

function RoamingDSP:clear_device()

  self:_remove_notifiers(self._parameter_observables)
  self.automation:stop_automation()
  self.target_device = nil
  self.track_index = nil
  self.device_index = nil

end


--------------------------------------------------------------------------------

--- update the record mode (when editmode or record_method has changed)

function RoamingDSP:_update_record_mode()
  if (self.options.record_method.value ~= RoamingDSP.RECORD_NONE) then
    self._record_mode = renoise.song().transport.edit_mode 
  else
    self._record_mode = false
  end
end

--------------------------------------------------------------------------------

--- attach notifier to the song, handle changes

function RoamingDSP:_attach_to_song()

  -- update when a device is selected
  renoise.song().selected_device_observable:add_notifier(
    function()
      self.current_device_requested = true
    end
  )

  -- track edit_mode, and set record_mode accordingly
  renoise.song().transport.edit_mode_observable:add_notifier(
    function()
      self:_update_record_mode()
    end
  )
  self._record_mode = renoise.song().transport.edit_mode

  -- also call Automation class
  self.automation:attach_to_song()

end

--------------------------------------------------------------------------------

--- "brute force" removal of registered notifiers 
-- @param observables - list of observables

function RoamingDSP:_remove_notifiers(observables)

  for _,observable in pairs(observables) do
    -- temp security hack. can also happen when removing FX
    pcall(function() observable:remove_notifier(self) end)
  end
    
  observables:clear()

end
