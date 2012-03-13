--[[----------------------------------------------------------------------------
-- Duplex.SwitchConfiguration
-- Inheritance: Application > SwitchConfiguration
----------------------------------------------------------------------------]]--

--[[

About

  The SwitchConfiguration application is aimed at controlling the different
  configurations for a device and to switch between them (next and previous).


Changes (equal to Duplex version number)

  0.98  First release

--]]

--==============================================================================



class 'SwitchConfiguration' (Application)

SwitchConfiguration.default_options = {}
SwitchConfiguration.need_browser = true

function SwitchConfiguration:__init(process, mappings, options, cfg_name,palette)
    TRACE("SwitchConfiguration:__init(",process,mappings,options,cfg_name,palette)

    self.mappings = {
        goto_next = {
            description = "SwitchConfiguration: Goto next configuration"    
            .."\nControl value: ",
        },
        goto_previous = {
            description = "SwitchConfiguration: Goto previous configuration"    
            .."\nControl value: ",
        },

    }

    self.palette = {    
      previous_config_on = {  color = {0xFF,0xFF,0xFF}, text = "◄", val=true},
      previous_config_off = { color = {0x00,0x00,0x00}, text = "◄", val=false},
      next_config_on      = { color = {0xFF,0xFF,0xFF}, text = "►", val=true},
      next_config_off     = { color = {0x00,0x00,0x00}, text = "►", val=false}
    }

    -- the various UIComponents
    self.controls = {}
    self._browser = process.browser

    Application.__init(self,process,mappings,options,cfg_name,palette)


end

--------------------------------------------------------------------------------

function SwitchConfiguration:start_app()
    TRACE("SwitchConfiguration.start_app()")

    if not Application.start_app(self) then
        return
    end
    self:update()
end


--------------------------------------------------------------------------------

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

end


--------------------------------------------------------------------------------

function SwitchConfiguration:_build_app()
    TRACE("SwitchConfiguration:_build_app()")

    if self.mappings.goto_next.group_name then
        local c = UIButton(self.display)
        c.group_name = self.mappings.goto_next.group_name
        c.tooltip = self.mappings.goto_next.description
        c:set_pos(self.mappings.goto_next.index)
        c:set(self.palette.next_config)
        c.on_press = function(obj)
            if not self.active then return false end
            self._browser:set_next_configuration() 
        end
        self:_add_component(c)
        self.controls.next = c
    end

    if self.mappings.goto_previous.group_name then
        local c = UIButton(self.display)
        c.group_name = self.mappings.goto_previous.group_name
        c.tooltip = self.mappings.goto_previous.description
        c:set_pos(self.mappings.goto_previous.index)
        c:set(self.palette.previous_config)
        c.on_press = function(obj)
            if not self.active then return false end
            self._browser:set_previous_configuration() 
        end
        self:_add_component(c)
        self.controls.previous = c
    end

    Application._build_app(self)
    return true

end
