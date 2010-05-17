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
  
--print("MixConsole:__init",display,
--  sliders_group_name,buttons_group_name,master_group_name)

  -- constructor 
  Application.__init(self)
  
  self.sliders_group_name=sliders_group_name
  self.buttons_group_name=buttons_group_name
  self.master_group_name=master_group_name

  -- controls
  self.master = nil
  self.sliders = nil
  self.buttons = nil

  -- the number of tracks displayed
  self.horizontal_size = nil

  self.display = display
  self.build_app(self)

  self.add_observables(self)

end


--------------------------------------------------------------------------------

function MixConsole:set_track_volume(idx,value)
--print("set_track_volume",idx,value)
  if not self.active then
    return
  end
  renoise.song().tracks[idx].prefx_volume.value = value
  self.sliders[idx].set_value(self.sliders[idx],value,true) -- skip on_change()  
end


--------------------------------------------------------------------------------

function MixConsole:set_track_mute(idx,state)
--print("set_track_mute",idx,state)
  if not self.active then
    return
  end
  local active = true
  if state == MUTE_STATE_ACTIVE then
    active = false
  end
  self.buttons[idx].set(self.buttons[idx],active,true) -- skip on_change() 
  self.sliders[idx].set_dimmed(self.sliders[idx],active)

end


--------------------------------------------------------------------------------

function MixConsole:set_master_volume(value)
  get_master_track().prefx_volume.value = value
  self.master.set_value(self.master,value,true) -- skip on_change()  
end


--------------------------------------------------------------------------------

-- create UI layout : pretty flexible, to support many different configurations 
-- there's a lot of control-map checking before the final layout is decided

function MixConsole:build_app()
--print("MixConsole:build_app(")

  Application.build_app(self)

  self.horizontal_size = 8

  local observable = nil
  self.master = nil
  self.sliders = {}
  self.buttons = {}

  -- determine where we should put the volume levels...
  -- master fader should always be a physical slider if possible
  -- if one of the groups contain a "columns" attribute, we switch to 
  -- grid controller mode
  -- rotary encoders or sliders (if they exist) for individual tracks
  -- as a last option, use toggle buttons 

  local grid_mode = false

  for group_name,group in pairs(self.display.device.control_map.groups)do
    for attr,param in pairs(group) do
      if(attr == "xarg")then
        --rprint(param)
        if(param["columns"])then
          --sliders_group_name = param["name"]
          grid_mode = true
        end
      end
    end
  end

  -- this is where we specify the size of the slider
  -- size is 1 by default, this is good for encoders and faders
  local slider_vertical_units = 1

  if grid_mode then
    -- slider is composed from several smaller units (buttons)
    slider_vertical_units = 8
  end

  for i=1,self.horizontal_size do

    -- sliders ---------------------------------------------------

    self.sliders[i] = Slider(self.display)
    self.sliders[i].group_name = self.sliders_group_name
    self.sliders[i].x_pos = i
    self.sliders[i].y_pos = 1
    self.sliders[i].toggleable = true
    self.sliders[i].inverted = false
    self.sliders[i].ceiling = RENOISE_DECIBEL
    self.sliders[i].orientation = VERTICAL
    --self.sliders[i].set_size(self.sliders[i],8)
    self.sliders[i].set_size(self.sliders[i],slider_vertical_units)

    -- slider changed from controller
    self.sliders[i].on_change = function(obj) 
      if not self.active then
        return false
      --elseif i == get_master_track_index() then
      --  print('Track is controlled seperately')
      --  return false
      elseif not renoise.song().tracks[i] then
        print('Track is outside bounds')
        return false
      else
        renoise.song().tracks[i].prefx_volume.value = obj.value
      end
      return true
    end
    self.display.add(self.display,self.sliders[i])

    -- buttons ---------------------------------------------------

    self.buttons[i] = ToggleButton(self.display)
    self.buttons[i].group_name = self.buttons_group_name
    self.buttons[i].x_pos = i
    self.buttons[i].y_pos = 1
    self.buttons[i].active = false

    -- mute state changed from controller
    self.buttons[i].on_change = function(obj) 
      --print("self.buttons[",i,"]:on_change",obj.x_pos)
      if not self.active then
        return false
      elseif i == get_master_track_index() then
        print("Can't mute the master track")
        return false
      elseif not renoise.song().tracks[i] then
        print('Track is outside bounds')
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
      self.sliders[i].set_dimmed(self.sliders[i],dimmed)
      return true
    end
    self.display.add(self.display,self.buttons[i])


    -- apply customization (this will only affect 
    -- controllers that use color to represent values) : 

    if (i>6) then
      self.sliders[i].colorize(self.sliders[i],{0x00,0xff,0x00})
      self.buttons[i].colorize(self.buttons[i],{0x00,0xff,0x00})
    elseif (i>3)then
      self.sliders[i].colorize(self.sliders[i],{0xff,0x00,0x00})
      self.buttons[i].colorize(self.buttons[i],{0xff,0x00,0x00})
    end

  end

  -- master fader 
  --  todo: skip if no group is supplied as argument, 
  --  otherwise attempt to locate the best suited 

  self.master = Slider(self.display)
  self.master.group_name = self.master_group_name
  self.master.x_pos = 1
  self.master.y_pos = 1
  self.master.toggleable = true
  self.master.ceiling = 1.4125375747681
  self.master.set_size(self.master,slider_vertical_units)
  self.master.on_change = function(obj) 
--print("self.master:on_change",obj.value)
    if not self.active then
      return false
    end
    get_master_track().prefx_volume.value = obj.value
    return true
  end
  self.display.add(self.display,self.master)

end


--------------------------------------------------------------------------------

-- start/resume application

function MixConsole:start_app()
--print("MixConsole.start_app()")

  Application.start_app(self)

  -- set controls to current values
  local value = nil
  for i=1,self.horizontal_size do
    if renoise.song().tracks[i] then
      value = renoise.song().tracks[i].prefx_volume.value
      self.set_track_volume(self,i,value)
      value = renoise.song().tracks[i].mute_state
      self.set_track_mute(self,i,value)
    end
  end

end


--------------------------------------------------------------------------------

function MixConsole:destroy_app()
--print("MixConsole:destroy_app")

  self.master.remove_listeners(self.master)
  for _,obj in ipairs(self.sliders) do
    obj.remove_listeners(obj)
  end
  for _,obj in ipairs(self.buttons) do
    obj.remove_listeners(obj)
  end

  Application.destroy_app(self)

end


--------------------------------------------------------------------------------

-- add observables to renoise parameters
-- TODO keep this list up-to-date as tracks are added/removed

function MixConsole:add_observables()
--print("MixConsole:add_observables()")

  local observable

  for i=1,self.horizontal_size do

    -- slider changed from Renoise
    if renoise.song().tracks[i] then

      observable = renoise.song().tracks[i].prefx_volume.value_string_observable
      local function slider_set()
        local value = renoise.song().tracks[i].prefx_volume.value
        -- compensate for loss of precision 
        if not compare(self.sliders[i].value,value,1000) then
          self.set_track_volume(self,i,value)
        end
      end
      observable:add_notifier(slider_set)

      -- mute state changed from Renoise
      observable = renoise.song().tracks[i].mute_state_observable
      local function button_set()
        self.set_track_mute(self,i,renoise.song().tracks[i].mute_state)
      end
      observable:add_notifier(button_set)

    end
  end
end

