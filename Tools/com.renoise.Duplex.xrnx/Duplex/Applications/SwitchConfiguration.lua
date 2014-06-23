--[[============================================================================
-- Duplex.Application.SwitchConfiguration
============================================================================]]--

--[[--
Switch between different configurations (next, previous and set).
Inheritance: @{Duplex.Application} > Duplex.Application.SwitchConfiguration


### Changes

  0.98
    - First release

--]]

--==============================================================================



class 'SwitchConfiguration' (Application)

SwitchConfiguration.default_options = {}

SwitchConfiguration.available_mappings = {
  goto_next = {
    description = "SwitchConfiguration: Goto next configuration"    
    .."\nControl value: ",
  },
  goto_previous = {
    description = "SwitchConfiguration: Goto previous configuration"    
    .."\nControl value: ",
  },
}

-- add mappings for config 1-16
for i = 1,16 do
  local map_name = ("goto_%d"):format(i)
  local map_description = "SwitchConfiguration: Goto configuration #%d"
    .."\nControl value: "
  SwitchConfiguration.available_mappings[map_name] = {
    description = map_description:format(i)
  }
end

SwitchConfiguration.default_palette = {    
  previous_config_on  = { color = {0xFF,0xFF,0xFF}, text = "◄", val=true},
  previous_config_off = { color = {0x00,0x00,0x00}, text = "◄", val=false},
  next_config_on      = { color = {0xFF,0xFF,0xFF}, text = "►", val=true},
  next_config_off     = { color = {0x00,0x00,0x00}, text = "►", val=false},
  set_config_on       = { color = {0xFF,0xFF,0xFF}, text = "■", val=true},
  set_config_off      = { color = {0x00,0x00,0x00}, text = "□", val=false}
}


--------------------------------------------------------------------------------

--- Constructor method
-- @param (VarArg)
-- @see Duplex.Application

function SwitchConfiguration:__init(...)
  TRACE("SwitchConfiguration:__init()")

  --- the various UIComponents
  self.controls = {}

  --- (@{Duplex.Browser}) reference to the duplex browser
  self._browser = select(1,...).browser

  Application.__init(self,...)

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.start_app
-- @return bool or nil

function SwitchConfiguration:start_app()
  TRACE("SwitchConfiguration.start_app()")

  if not Application.start_app(self) then
    return
  end
  self:update()
end


--------------------------------------------------------------------------------

--- Update display

function SwitchConfiguration:update()
  TRACE("SwitchConfiguration.update()")

  if self.controls.next then
    if self._browser:has_next_configuration() then
      self.controls.next:set(self.palette.next_config_on)
    else
      self.controls.next:set(self.palette.next_config_off)
    end
  end
  if self.controls.previous then
    if self._browser:has_previous_configuration() then
      self.controls.previous:set(self.palette.previous_config_on)
    else
      self.controls.previous:set(self.palette.previous_config_off)
    end
  end
  for i=1,16 do 
    local ctrl_name = ("goto_%d"):format(i)
    if self.controls[ctrl_name] then
      local cfg_idx = self:get_config_index()
      if (cfg_idx==i) then
        self.controls[ctrl_name]:set(self.palette.set_config_on)
      else
        self.controls[ctrl_name]:set(self.palette.set_config_off)
      end
    end

  end

end

--------------------------------------------------------------------------------

--- Retrieve the current configuration index 
-- @return int

function SwitchConfiguration:get_config_index()

  local cfg_name = self._browser._configuration_name
  local cfg_idx = self._browser:get_configuration_index(cfg_name)
  return cfg_idx

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application._build_app
-- @return bool

function SwitchConfiguration:_build_app()
    TRACE("SwitchConfiguration:_build_app()")

  local map = self.mappings.goto_next
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    --c:set(self.palette.next_config)
    c.on_press = function(obj)
      self._browser:set_next_configuration() 
    end
    self.controls.next = c
  end

  local map = self.mappings.goto_previous
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    --c:set(self.palette.previous_config)
    c.on_press = function(obj)
      self._browser:set_previous_configuration() 
    end
    self.controls.previous = c
  end

  for i=1,16 do 
    local map_name = ("goto_%d"):format(i)
    local map = self.mappings[map_name]
    if map.group_name then
      local c = UIButton(self)
      c.group_name = map.group_name
      c.tooltip = map.description
      c:set_pos(map.index)
      --c:set(self.palette.set_config)
      c.on_press = function(obj)
        self._browser:goto_configuration(i) 
      end
      self.controls[map_name] = c
    end

  end

  Application._build_app(self)
  return true

end
