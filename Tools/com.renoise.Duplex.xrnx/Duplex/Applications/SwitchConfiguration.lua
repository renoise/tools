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

function SwitchConfiguration:__init(browser_process, mappings, options, config_name)
    TRACE("SwitchConfiguration:__init(",browser_process,mappings,options,config_name)

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

    -- the various UIComponents
    self.controls = {}
    self._browser = browser_process.browser

    Application.__init(self,browser_process,mappings,options,config_name)


end

--------------------------------------------------------------------------------

function SwitchConfiguration:start_app()
    TRACE("SwitchConfiguration.start_app()")

    if not Application.start_app(self) then
        return
    end

end


--------------------------------------------------------------------------------

function SwitchConfiguration:_build_app()
    TRACE("SwitchConfiguration:_build_app()")

    if self.mappings.goto_next.group_name then
        local c = UIPushButton(self.display)
        c.group_name = self.mappings.goto_next.group_name
        c.tooltip = self.mappings.goto_next.description
        c:set_pos(self.mappings.goto_next.index)
        c.interval = 0.5
        c.sequence = {
            {color={0xff,0xff,0xff},text="►"},
            {color={0x00,0x00,0x00},text=" "},
        }
        c.on_press = function(obj)
            if not self.active then return false end
            self._browser:set_next_configuration() 
        end
        self:_add_component(c)
        self.controls.next = c
    end

    if self.mappings.goto_previous.group_name then
        local c = UIPushButton(self.display)
        c.group_name = self.mappings.goto_previous.group_name
        c.tooltip = self.mappings.goto_previous.description
        c:set_pos(self.mappings.goto_previous.index)
        c.interval = 0.5
        c.sequence = {
            {color={0xff,0xff,0xff},text="◄"},
            {color={0x00,0x00,0x00},text=" "},
        }
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
