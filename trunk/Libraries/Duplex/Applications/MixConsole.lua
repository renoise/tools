--[[----------------------------------------------------------------------------
-- Duplex.MixConsole
----------------------------------------------------------------------------]]--

--[[

A generic mixer class 

--]]


--==============================================================================

class 'MixConsole' (Application)

function MixConsole:__init(display, sliders_group_name,
  encoders_group_name, buttons_group_name, 
  master_group_name, page_scroll_group_name)
  
  TRACE("MixConsole:__init",display, sliders_group_name, 
    buttons_group_name, master_group_name)

  -- constructor 
  Application.__init(self)
  
  self.display = display

  -- master level (always present)
  self.master = nil
  self.master_group_name = master_group_name

  -- track levels
  self.sliders = nil
  self.sliders_group_name = sliders_group_name

  -- track mutes 
  self.buttons = nil
  self.buttons_group_name = buttons_group_name

  -- pan levels
  self.encoders = nil
  self.encoders_group_name = encoders_group_name
      
  self.page_scroller = nil
  self.page_scroll_group_name = page_scroll_group_name
  
  
  -- the number of tracks displayed side-by-side
  self.horizontal_size = nil

  -- the number of units spanned vertically
  -- (more than one, if grid controller)
  self.slider_vertical_units = 1

  -- offset of the whole track mapping, controlled by the scroller
  self.__track_offset = 0
  
  -- final steps
  self:build_app()
  self:__attach_to_song(renoise.song())
end


--------------------------------------------------------------------------------

-- volume level changed from Renoise

function MixConsole:set_track_volume(idx, value)
  TRACE("MixConsole:set_track_volume", idx, value)

  if (self.active) then
    self.sliders[idx]:set_value(value)
    
    -- update the master as well, if it has its own UI representation
    if (self.master and idx == get_master_track_index()) then
      self.master:set_value(value)
    end
  end
end


--------------------------------------------------------------------------------

-- panning changed from Renoise

function MixConsole:set_track_panning(idx, value)
  TRACE("MixConsole:set_track_panning", idx, value)

  if (self.active) then
    self.encoders[idx]:set_value(value)
  end
end


--------------------------------------------------------------------------------

-- mute state changed from Renoise

function MixConsole:set_track_mute(idx, state)
  TRACE("MixConsole:set_track_mute", idx, state)

  if (self.active) then
    -- set mute state to the button
    local active = (state == MUTE_STATE_ACTIVE)
    self.buttons[idx]:set(active)

    -- deactivate sliders and encoders to show that the track is inactive
    self.sliders[idx]:set_dimmed(not active)
    self.encoders[idx]:set_dimmed(not active)
  end
end


--------------------------------------------------------------------------------

-- update: set all controls to current values from renoise

function MixConsole:update()  
  
  local master_track_index = get_master_track_index()
  local tracks = renoise.song().tracks

  for i=1,self.horizontal_size do
    local track_index = self.__track_offset + i
    
    -- set default values
  
    if (track_index <= #tracks) then
      -- update component states from the track
      self:set_track_volume(i, tracks[track_index].prefx_volume.value)
      self:set_track_panning(i, tracks[track_index].prefx_panning.value)
      
      -- show that we can't change the master mute state
      if (track_index == get_master_track_index()) then
        self:set_track_mute(i, MUTE_STATE_OFF)
      else
        self:set_track_mute(i, tracks[track_index].mute_state)
      end
      
    else
      -- deactivate, reset controls which have no track
      self:set_track_volume(i, 0)
      self:set_track_panning(i, 0)
      self:set_track_mute(i, MUTE_STATE_OFF)
    end

  
    -- colorize:
    -- this will only affect controllers that use color to 
    -- represent values
    
    if (track_index < master_track_index) then
      -- normal tracks are green
      self.sliders[i]:colorize({0x00,0xff,0x00})
      self.encoders[i]:colorize({0x00,0xff,0x00})
      self.buttons[i]:colorize({0x00,0xff,0x00})

    elseif (track_index == master_track_index) then
      -- master track is yellow
      self.sliders[i]:colorize({0xff,0xff,0x00})
      self.encoders[i]:colorize({0xff,0xff,0x00})
      self.buttons[i]:colorize({0xff,0xff,0x00})      

    elseif (track_index <= #tracks) then
      -- send tracks are red
      self.sliders[i]:colorize({0xff,0x00,0x00})
      self.encoders[i]:colorize({0xff,0x00,0x00})
      self.buttons[i]:colorize({0xff,0x00,0x00})

    else 
      -- unmapped tracks are black
      self.sliders[i]:colorize({0x00,0x00,0x00})
      self.encoders[i]:colorize({0x00,0x00,0x00})
      self.buttons[i]:colorize({0x00,0x00,0x00}) 
    end
  end
end


--------------------------------------------------------------------------------

-- create UI: create a grid or fader/encoder layout, based on the group 
-- names from the controllers controlmap

function MixConsole:build_app()
  TRACE("MixConsole:build_app(")

  Application.build_app(self)

  -- TODO: get this from the control map?
  self.horizontal_size = 8

  self.sliders = {}
  self.encoders = {}
  self.buttons = {}
  self.master = nil

  -- check if the control-map describes a grid controller
  local grid_mode = false
  local control_map_groups = self.display.device.control_map.groups
  
  for group_name, group in pairs(control_map_groups) do
    for attr, param in pairs(group) do
      if (attr == "xarg" and param["columns"]) then
        grid_mode = true
      end
      
      if grid_mode then break end
    end

    if grid_mode then break end
  end

  -- slider is composed from individual buttons in grid mode
  -- TODO: get this from the control map?
  self.slider_vertical_units = (grid_mode) and 8 or 1
  
  for i=1,self.horizontal_size do

    -- sliders --------------------------------------------

    self.sliders[i] = UISlider(self.display)
    self.sliders[i].group_name = self.sliders_group_name
    self.sliders[i].x_pos = i
    self.sliders[i].y_pos = 1
    self.sliders[i].toggleable = true
    self.sliders[i].inverted = false
    self.sliders[i].ceiling = RENOISE_DECIBEL
    self.sliders[i].orientation = VERTICAL
    self.sliders[i]:set_size(self.slider_vertical_units)

    -- slider changed from controller
    self.sliders[i].on_change = function(obj) 
      local track_index = self.__track_offset + i
      
      if (not self.active) then
        return false

      elseif (track_index == get_master_track_index()) then
        if (self.master) then
          -- this will cause another event...
          self.master:set_value(obj.value)
        else
          local track = renoise.song().tracks[track_index]
          track.prefx_volume.value = obj.value
        end
        return true

      elseif (track_index > #renoise.song().tracks) then
        -- track is outside bounds
        return false

      else
        local track = renoise.song().tracks[track_index]
        track.prefx_volume.value = obj.value
        return true
      end
    end
    
    self.display:add(self.sliders[i])


    -- encoders -------------------------------------------

    self.encoders[i] = UISlider(self.display)
    self.encoders[i].group_name = self.encoders_group_name
    self.encoders[i].x_pos = i
    self.encoders[i].y_pos = 1
    self.encoders[i].toggleable = true
    self.encoders[i].inverted = false
    self.encoders[i].ceiling = 1.0
    self.encoders[i].orientation = VERTICAL
    self.encoders[i]:set_size(1)
    
    -- slider changed from controller
    self.encoders[i].on_change = function(obj) 
      local track_index = self.__track_offset + i
      
      if (not self.active) then
        return false
      
      elseif (i > #renoise.song().tracks) then
        -- track is outside bounds
        return false
      
      else
        local track = renoise.song().tracks[track_index]
        track.prefx_panning.value = obj.value
        return true
      end
    end
    
    self.display:add(self.encoders[i])
    
    
    -- buttons --------------------------------------------

    self.buttons[i] = UIToggleButton(self.display)
    self.buttons[i].group_name = self.buttons_group_name
    self.buttons[i].x_pos = i
    self.buttons[i].y_pos = 1
    self.buttons[i].active = false

    -- mute state changed from controller
    -- (update the slider.dimmed property)
    self.buttons[i].on_change = function(obj) 
      local track_index = self.__track_offset + i
      
      if (not self.active) then
        return false
      
      elseif (track_index == get_master_track_index()) then
        -- can't mute the master track
        return false
      
      elseif (track_index > #renoise.song().tracks) then
        -- track is outside bound
        return false
      end
      
      local track = renoise.song().tracks[track_index]
      
      local mute_state = obj.active and 
        MUTE_STATE_ACTIVE or MUTE_STATE_OFF
      
      local dimmed = not obj.active
      
      track.mute_state = mute_state
      
      self.sliders[i]:set_dimmed(dimmed)
      self.encoders[i]:set_dimmed(dimmed)
      
      return true
    end
    
    self.display:add(self.buttons[i])    
  end


  -- master fader (optional) ------------------------------

  if (self.master_group_name) then
    self.master = UISlider(self.display)
    self.master.group_name = self.master_group_name
    self.master.x_pos = 1
    self.master.y_pos = 1
    self.master.toggleable = true
    self.master.ceiling = RENOISE_DECIBEL
    self.master:set_size(self.slider_vertical_units)
    
    self.master.on_change = function(obj) 
      if (self.active) then
        get_master_track().prefx_volume.value = obj.value
        return true
      
      else
        return false
      end
    end 
     
    self.display:add(self.master)
  end
  
  
  -- track scrolling (optional) ---------------------------

  if (self.page_scroll_group_name) then
    self.page_scroller = UISpinner(self.display)
    self.page_scroller.group_name = self.page_scroll_group_name
    self.page_scroller.index = 0
    self.page_scroller.step_size = self.horizontal_size
    self.page_scroller.minimum = 0
    self.page_scroller.maximum = math.max(0, 
      #renoise.song().tracks - self.horizontal_size)
    self.page_scroller.x_pos = 1
    self.page_scroller.palette.foreground_dec.text = "◄"
    self.page_scroller.palette.foreground_inc.text = "►"
    self.page_scroller.on_press = function(obj) 
      self.__track_offset = obj.index
      self:__attach_to_tracks()
      self:update()
      return true
    end
    
    self.display:add(self.page_scroller)
  end
end


--------------------------------------------------------------------------------

-- start/resume application

function MixConsole:start_app()
  TRACE("MixConsole.start_app()")

  Application.start_app(self)
  self:update()
end


--------------------------------------------------------------------------------

function MixConsole:destroy_app()
  TRACE("MixConsole:destroy_app")

  for _,obj in ipairs(self.sliders) do
    obj.remove_listeners(obj)
  end
  
  for _,obj in ipairs(self.encoders) do
    obj.remove_listeners(obj)
  end
  
  for _,obj in ipairs(self.buttons) do
    obj.remove_listeners(obj)
  end

  if (self.master) then
    self.master:remove_listeners()
  end
  
  Application.destroy_app(self)
end


--------------------------------------------------------------------------------

function MixConsole:on_new_document()
  TRACE("MixConsole:on_new_document")
  
  self:__attach_to_song(renoise.song())
  self:update()
end


--------------------------------------------------------------------------------

-- adds notifiers to song
-- invoked when a new document becomes available

function MixConsole:__attach_to_song(song)
  TRACE("MixConsole:__attach_to_song()")
  
  -- update on track changes in the song
  song.tracks_observable:add_notifier(
    function()
      TRACE("MixConsole:tracks_changed fired...")
      self:__attach_to_tracks()
      self:update()
    end
  )

  -- and immediately attach to the current track set
  self:__attach_to_tracks()
end


--------------------------------------------------------------------------------

-- add notifiers to parameters
-- invoked when tracks are added/removed/swapped

function MixConsole:__attach_to_tracks()
  TRACE("MixConsole:__attach_to_tracks()")

  local tracks = renoise.song().tracks

  -- validate the page scroller
  if (self.page_scroller) then
    self.page_scroller.maximum = math.max(0, 
      #renoise.song().tracks - self.horizontal_size)
        
    if (self.__track_offset > self.page_scroller.maximum) then
      self.__track_offset = self.page_scroller.maximum
      self.page_scroller:set_index(self.__track_offset)
    end
  end
    
  --[[ available in branch future only
  -- detach all previously added notifiers first
  for _,track in pairs(tracks) do
    track.prefx_volume.value_observable:remove_notifier(self)
    track.prefx_panning.value_observable:remove_notifier(self)
    track.mute_state_observable:remove_notifier(self) 
  end]] 
  
  -- attach to the new ones in the order we want them
  for i=1,math.min(#tracks, self.horizontal_size) do
    local track_index = self.__track_offset + i
    local track = tracks[track_index]
    
    -- track volume level 
    track.prefx_volume.value_observable:add_notifier(
      self, 
      function()
        if (self.active) then
          local value = track.prefx_volume.value
          -- compensate for potential loss of precision 
          if not compare(self.sliders[i].value,value,1000) then
            self:set_track_volume(i, value)
          end
        end
      end 
    )

    -- track panning level 
    track.prefx_panning.value_observable:add_notifier(
      self, 
      function()
        if (self.active) then
          local value = track.prefx_panning.value
          -- compensate for potential loss of precision 
          if not compare(self.encoders[i].value,value,1000) then
            self:set_track_panning(i, value)
          end
        end
      end 
    )
    
    -- track mute-state 
    track.mute_state_observable:add_notifier(
      self, 
      function()
        if (self.active) then
          self:set_track_mute(i, track.mute_state)
        end
      end 
    )
  end
end

