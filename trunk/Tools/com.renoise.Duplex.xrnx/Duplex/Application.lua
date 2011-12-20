--[[----------------------------------------------------------------------------
-- Duplex.Application
----------------------------------------------------------------------------]]--

--[[

A generic application class for Duplex

--]]


--==============================================================================

class 'Application'

-- constructor 
-- @process BrowserProcess
-- @mappings (table, imported from the device configuration)
-- @palette (table, imported from the device configuration)
-- @options (table, imported from the application default options)
-- @cfg_name (string, imported from the application default options)

function Application:__init(process,mappings,options,cfg_name,palette)
  TRACE("Application:__init()")

  -- this is the Display that our application is using
  self.display = process.display
  
  -- (string) this is the name of the application as it appears
  -- in the device configuration, e.g. "MySecondMixer" - used for looking 
  -- up the correct preferences-key when specifying custom options 
  self._cfg_name = cfg_name

  -- when the application is inactive, it should 
  -- sleep during idle time and ignore any user input
  self.active = false

  -- mappings allows us to choose where to put controls,
  -- see actual application implementations for examples
  --
  -- @group_name: (required) the control-map group-name 
  -- @index: the position where the control should be located (set in config)
  -- @description: provide a sensible tooltip text for the virtual display
  -- @orientation: defines the UIComponent orientation (VERTICAL/HORIZONTAL)
  -- 
  -- example_mapping = {
  --  group_name = "Main",
  --  index = 3,
  -- }

  -- note: mappings are specified in the application 
  self.mappings = self.mappings or {}

  -- update "self.mappings" with values from the provided configuration
  self:_apply_mappings(mappings)

  -- you can choose to expose your application's options here
  -- (device-specific options are specified in the device configuration)
  --
  -- @label: displayed in options dialog
  -- @description: tooltip in options dialog
  -- @on_change: (function) code to execute when option is changed
  -- @items: brief descriptions of each available choice (list)
  -- @value: the default choice among the @items
  --
  -- example_option = {
  --  label = "My option",
  --  on_change = function() end,
  --  items = {"Choice 1", "Choice 2"},
  --  value = 1 -- this is the default value ("Choice 1")
  -- }
  self.options = options or {}

  -- define a default palette for the application
  self.palette = self.palette or {}

  -- update "self.palette" with values from the device-configuration
  self:_apply_palette(palette)

  -- private stuff

  -- (boolean) true once build_app has been run
  self._created = false
  
  -- the options view
  self._vb = renoise.ViewBuilder()
  self._settings_view = nil

  -- UIComponents registered via add_component method
  self._ui_components = table.create()

end


--------------------------------------------------------------------------------

-- start/resume application

function Application:start_app()
  TRACE("Application:start_app()")

  if (self.active) then
    return false
  end

  -- validate mappings, then construction
  if not (self._created) then 
    if not self:_check_mappings(self.mappings) then
      return false
    end
    if self._build_app then
      if not self:_build_app() then
        return false
      end
      self._created = true
    end
  end

  if (self.display) then
    self.display:apply_tooltips()
  end

  self.active = true

  return true

end


--------------------------------------------------------------------------------

-- stop application

function Application:stop_app()
  TRACE("Application:stop_app()")
  
  if (not self.active) then
    return
  end

  self.active = false
end


--------------------------------------------------------------------------------

-- create application

function Application:_build_app()
  TRACE("Application:_build_app()")
  

end


--------------------------------------------------------------------------------

-- destroy application

function Application:destroy_app()
  TRACE("Application:destroy_app()")
  
  self:stop_app()

  -- unregister components
  if(self._ui_components)then
    for _,v in pairs(self._ui_components) do
      v:remove_listeners()
    end
  end
  
  self._created = false
end


--------------------------------------------------------------------------------

-- handle periodic updates (many times per second)
-- nothing is done by default

function Application:on_idle()
  -- TRACE("Application:on_idle()")
  
  -- it's a good idea to include this check when doing complex stuff:..
  -- if (not self.active) then 
  --   return 
  -- end

end


--------------------------------------------------------------------------------

-- called when a new document becomes available

function Application:on_new_document()
  TRACE("Application:on_new_document()")
  
  -- nothing done by default
end


--------------------------------------------------------------------------------

-- receive keypress events from the Duplex Browser dialog
-- @param key (table) forwarded from the keyhandler 
-- @return (boolean) if false, key event is not forwarded to Renoise

function Application:on_keypress(key)
  TRACE("Application:on_keypress",key)
  
  return true

end



--------------------------------------------------------------------------------

-- assign matching group-names

function Application:_apply_mappings(mappings)
  TRACE("Application:_apply_mappings",mappings)
  
  if not self.mappings then
    -- we've got no mappings
    self.mappings = {}
    return
  end

  for v,k in pairs(self.mappings) do
    for v2,k2 in pairs(mappings) do
      if (v==v2) then
        for k3,v3 in pairs(mappings[v]) do
          self.mappings[v][k3] = v3
        end
      end
    end
  end
end

--------------------------------------------------------------------------------

-- assign matching palette entries

function Application:_apply_palette(palette)
  TRACE("Application:_apply_palette",palette)
  
  if not self.palette then
    self.palette = {}
    return
  end

  for v,k in pairs(self.palette) do
    for v2,k2 in pairs(palette) do
      if (v==v2) then
        for k3,v3 in pairs(palette[v]) do
          self.palette[v][k3] = v3
        end
      end
    end
  end
end

--------------------------------------------------------------------------------

-- check mappings: should be called before application is started
-- @return boolean (false if missing group-names were encountered)

function Application:_check_mappings(mappings)
  TRACE("Application:_check_mappings",mappings)
  
  if (self.display) then
    local cm = self.display.device.control_map
    for k,v in pairs(mappings) do
      for k2,v2 in pairs(v) do
        if(k2 == "group_name") and not (cm.groups[v2])then
          local app_name = type(self)
          local msg = "Message from Duplex: the application %s "
                    .."has been stopped - the control-map group '%s', "
                    .."does not exist. Please review the device settings "
                    .."and/or control-map (other applications will "
                    .."continue to run)"
          msg = string.format(msg,app_name,v2)
          renoise.app():show_warning(msg)
          return false
        end
      end
    end
  end
  return true
end


--------------------------------------------------------------------------------

-- create application options dialog

function Application:_build_options(process)
  TRACE("Application:_build_options")
  
  if (self._settings_view)then
    return
  end
 
  local vb = self._vb 
  
  -- create basic dialog 
  self._settings_view = vb:column{
    style = "group",
    vb:button{
      text = self._cfg_name,
      width=273,
      notifier = function()
        local view = vb.views.dpx_app_options
        local hidden_field = vb.views.dpx_app_options_hidden_field
        if (view.visible) then
          view.height = 1
        else
          -- display option rows
          if (hidden_field.value~=0) then
            view.height = 6+hidden_field.value*20
          else
            view.visible = true
          end
        end
        view.visible = not view.visible
      end
    },
    vb:value{
      id = "dpx_app_options_hidden_field",
      visible = false,
    },
    vb:column{
      id = "dpx_app_options",
      margin = DEFAULT_MARGIN,
      spacing = DEFAULT_SPACING,
      visible = false,
      -- options are inserted here
    }
  }
  
  local elm_group = vb.views.dpx_app_options
  local hidden_field = vb.views.dpx_app_options_hidden_field
  if (self.options)then
    for k,v in pairs(self.options) do
      if not v.hidden then
        elm_group:add_child(self:_add_option_row(v,k,process))
        hidden_field.value = hidden_field.value+1
      end
    end

  end
end


--------------------------------------------------------------------------------
--                         Private Helper Functions
--------------------------------------------------------------------------------

-- build a row of option controls
-- @return ViewBuilder view

function Application:_add_option_row(t,key,process)
  TRACE("Application:_add_option_row()",t,key,process)

  local vb = self._vb
  local elm = vb:row{
    tooltip=t.description,
    vb:text{
      text=t.label,
      width=90,
    },
    vb:popup{
      items=t.items,
      value=(t.value>#t.items) and 1 or t.value, -- if invalid, set to first
      width=175,
      notifier = function(val)
        self:_set_option(key,val,process)
      end
    }
  }
  return elm
end


--------------------------------------------------------------------------------

-- set option value 

function Application:_set_option(key, val, process)

  -- set local value
  for k,v in pairs(self.options) do
    if (k == key) then
      self.options[k].value = val
      if (self.options[k].on_change) then
        self.options[k].on_change(self)
      end
    end
  end

  if process then
    -- update relevant device configuration
    local app_options_node = 
      process.settings.applications:property(self._cfg_name).options
    -- check if we need to create the node 
    if not app_options_node:property(key) then
      app_options_node:add_property(key,val)
    else
      app_options_node:property(key).value = val
    end
  end

end

--------------------------------------------------------------------------------

-- register a UIComponent so we can automatically remove it when exiting
-- note that the display might not be present, so use with caution

function Application:_add_component(c)
  
  assert(self.display, "Internal Error. Please report: " ..
    "trying to add a UIComponent to an application without a display")

  self._ui_components:insert(c)
  self.display:add(c)

end  


--------------------------------------------------------------------------------

function Application:__tostring()
  return type(self)
end  


--------------------------------------------------------------------------------

function Application:__eq(other)
  -- only check for object identity
  return rawequal(self, other)
end  

