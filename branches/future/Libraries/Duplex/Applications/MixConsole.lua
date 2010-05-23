--[[----------------------------------------------------------------------------
-- Duplex.MixConsole
----------------------------------------------------------------------------]]--

--[[

A generic mixer class 

--]]


--==============================================================================

class 'MixConsole' (Application)

function MixConsole:__init(
  display, 
  sliders_group_name, 
  buttons_group_name, 
  master_group_name)
  
  TRACE("MixConsole:__init",display,
    sliders_group_name,buttons_group_name,master_group_name)

  -- constructor 
  Application.__init(self)
  
  self.display = display

  -- master level (always present)
  self.master = nil
  self.master_group_name=master_group_name

  -- track levels / mute switches
  self.sliders = nil
  self.sliders_group_name=sliders_group_name
  self.buttons = nil
  self.buttons_group_name=buttons_group_name

  -- the number of tracks displayed side-by-side
  self.horizontal_size = nil

  -- the number of units spanned vertically
  -- (more than one, if grid controller)
  self.slider_vertical_units = 1

  -- list of observables
  --self.__observables = {}

  -- final steps
  self:build_app()
  self:__attach_to_song(renoise.song())
end


--------------------------------------------------------------------------------

-- volume level changed from Renoise

function MixConsole:set_track_volume(idx,value)
  TRACE("MixConsole:set_track_volume",idx,value)

  if not self.active then
    return
  end
  --renoise.song().tracks[idx].prefx_volume.value = value
  self.sliders[idx]:set_value(value)
  if(idx == get_master_track_index()) then
    self.master:set_value(value)
  end
end


--------------------------------------------------------------------------------

-- mute state changed from Renoise

function MixConsole:set_track_mute(idx,state)
  TRACE("MixConsole:set_track_mute",idx,state)

  if not self.active then
    return
  end
  local active = true
  if state == MUTE_STATE_ACTIVE then
    active = false
  end
  self.buttons[idx]:set(active)
  self.sliders[idx]:set_dimmed(active)

end

--------------------------------------------------------------------------------

-- master volume level changed from Renoise
--[[
function MixConsole:set_master_volume(value)
  TRACE("MixConsole:set_master_volume",value)
  if not self.active then
    return
  end
  --get_master_track().prefx_volume.value = value
  self.master:set_value(value)
end
]]


 --------------------------------------------------------------------------------

-- update: set controls to current values

function MixConsole:update()

  local value = nil
  for i=1,self.horizontal_size do
    if renoise.song().tracks[i] then
      value = renoise.song().tracks[i].prefx_volume.value
      self:set_track_volume(i,value)
      value = renoise.song().tracks[i].mute_state
      self:set_track_mute(i,value)
    end
  end

end

--------------------------------------------------------------------------------

-- create UI : grid or fader/encoder layout

function MixConsole:build_app()
  TRACE("MixConsole:build_app(")

  Application.build_app(self)

  self.horizontal_size = 8

  local observable = nil
  self.master = nil
  self.sliders = {}
  self.buttons = {}

  local grid_mode = false

  -- check if the control-map describes a grid controller
  for group_name,group in pairs(self.display.device.control_map.groups)do
    for attr,param in pairs(group) do
      if(attr == "xarg")then
        if(param["columns"])then
          grid_mode = true
        end
      end
    end
  end

  self.slider_vertical_units = 1
  if grid_mode then
    -- slider is composed from individual buttons
    self.slider_vertical_units = 8
  end

  for i=1,self.horizontal_size do

    -- sliders ---------------------------------------------------

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
      if (not self.active) then
        return false
      elseif not renoise.song().tracks[i] then
        print('Notice: Track is outside bounds')
        return false
      elseif i == get_master_track_index() then
        -- this will cause another event...
        self.master:set_value(obj.value)
      else
        renoise.song().tracks[i].prefx_volume.value = obj.value
      end
      return true
    end
    self.display:add(self.sliders[i])

    -- buttons ---------------------------------------------------

    self.buttons[i] = UIToggleButton(self.display)
    self.buttons[i].group_name = self.buttons_group_name
    self.buttons[i].x_pos = i
    self.buttons[i].y_pos = 1
    self.buttons[i].active = false

    -- mute state changed from controller
    -- (update the slider.dimmed property)
    self.buttons[i].on_change = function(obj) 
      if not self.active then
        return false
      elseif i == get_master_track_index() then
        print("Notice: Can't mute the master track")
        return false
      elseif not renoise.song().tracks[i] then
        print('Notice: Track is outside bounds')
        return false
      end
      local mute_state = nil
      local dimmed = nil
      if obj.active then
        mute_state = MUTE_STATE_OFF
        dimmed = true
      else
        mute_state = MUTE_STATE_ACTIVE
        dimmed = false
      end
      renoise.song().tracks[i].mute_state = mute_state
      self.sliders[i]:set_dimmed(dimmed)
      return true
    end
    self.display:add(self.buttons[i])

    -- apply customization (this will only affect 
    -- controllers that use color to represent values) 
    -- * normal tracks are green
    -- * master track is yellow
    -- * send tracks are red
    local master_track_index = get_master_track_index()
    if (i<master_track_index) then
      self.sliders[i]:colorize({0x00,0xff,0x00})
      self.buttons[i]:colorize({0x00,0xff,0x00})
    elseif (i>master_track_index)then
      self.sliders[i]:colorize({0xff,0x00,0x00})
      self.buttons[i]:colorize({0xff,0x00,0x00})
    end

  end

  -- master fader 
  --  todo: skip if no group is supplied as argument, 
  --  otherwise attempt to locate the best suited 

  self.master = UISlider(self.display)
  self.master.group_name = self.master_group_name
  self.master.x_pos = 1
  self.master.y_pos = 1
  self.master.toggleable = true
  self.master.ceiling = 1.4125375747681
  self.master:set_size(self.slider_vertical_units)
  self.master.on_change = function(obj) 
    if not self.active then
      return false
    end
    get_master_track().prefx_volume.value = obj.value
    return true
  end
  self.display:add(self.master)

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

  self.master:remove_listeners()
  for _,obj in ipairs(self.sliders) do
    obj.remove_listeners(obj)
  end
  for _,obj in ipairs(self.buttons) do
    obj.remove_listeners(obj)
  end

  Application.destroy_app(self)

end

--------------------------------------------------------------------------------

function MixConsole:on_new_document()
  self:__attach_to_song(renoise.song())
  self:update()

end

--------------------------------------------------------------------------------

-- adds notifiers to song
-- invoked when a new document becomes available

function MixConsole:__attach_to_song(song)
  song.tracks_observable:add_notifier(
    function()
      TRACE("PatternMatrix:tracks_changed fired...")
      self:add_observables()
      self:update()
    end
  )
  self:add_observables()

end

--------------------------------------------------------------------------------

-- add notifiers to parameters
-- invoked when tracks are added/removed/swapped

function MixConsole:add_observables()
  TRACE("MixConsole:add_observables()")

  local observable
  for i=1,self.horizontal_size do
    if renoise.song().tracks[i] then

      -- track volume level 
      observable = renoise.song().tracks[i].prefx_volume.value_string_observable
      local function slider_set()
        if not self.active then
          return
        end
        local value = renoise.song().tracks[i].prefx_volume.value
        -- compensate for potential loss of precision 
        if not compare(self.sliders[i].value,value,1000) then
          self:set_track_volume(i,value)
        end
      end
      observable:add_notifier(slider_set)

      -- track mute-state 
      observable = renoise.song().tracks[i].mute_state_observable
      local function button_set()
        self:set_track_mute(i,renoise.song().tracks[i].mute_state)
      end
      observable:add_notifier(button_set)

    end
  end
end
