--[[----------------------------------------------------------------------------
-- Duplex.Application
----------------------------------------------------------------------------]]--

--[[

A generic application class for Duplex

mappings allows us to choose where to put controls,
see actual application implementations for examples

@group_name: (required) the control-map group-name 
@index: the position where the control should be located (set in config)
@description: provide a sensible tooltip text for the virtual display
@orientation: defines the UIComponent orientation (VERTICAL/HORIZONTAL)

example_mapping = {
 group_name = "Main",
 index = 3,
}


(device-specific options are specified in the device configuration)

@label: displayed in options dialog
@description: tooltip in options dialog
@on_change: (function) code to execute when option is changed
@items: brief descriptions of each available choice (list)
@value: the default choice among the @items

example_option = {
 label = "My option",
 on_change = function() end,
 items = {"Choice 1", "Choice 2"},
 value = 1 -- this is the default value ("Choice 1")
}

--]]


--==============================================================================

class 'Application'

--- Initialize the Application class
-- @param ... (VarArg), containing:
--  [1] = process (BrowserProcess)
--  [2] = mappings (table, imported from device-config)
--  [3] = palette (table, imported from device-config)
--  [4] = options (table, imported from application default options)
--  [5] = config_name (string, imported from application default options)

function Application:__init(...)
  TRACE("Application:__init()")

  -- extract varargs using select
  local process, mappings, options, config_name, palette = select(1,...)

  self.mappings = mappings or {}
  self.palette = palette or {}
  self.options = options or {}

  -- instance of the Display class
  self.display = process.display
  
  -- (string) this is the name of the application as it appears
  -- in the device configuration, e.g. "MySecondMixer" - used for looking 
  -- up the correct preferences-key when specifying custom options 
  self._app_name = config_name

  -- when the application is inactive, it should 
  -- sleep during idle time and ignore any user input
  self.active = false

  -- update "self.mappings" with values from the provided configuration
  --self:_apply_mappings(mappings)

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

--- Start/resume application

function Application:start_app(start_running)
  TRACE("Application:start_app()",start_running)

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

--- Stop application

function Application:stop_app()
  TRACE("Application:stop_app()")
  
  if (not self.active) then
    return
  end

  self.active = false
end


--------------------------------------------------------------------------------

--- Create application (build interface)
-- @return (Boolean) true when application was built

function Application:_build_app()
  TRACE("Application:_build_app()")
  
  return true

end


--------------------------------------------------------------------------------

--- Destroy application (remove listeners, set to inactive state)

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

--- Handle idle updates for the application
-- (nothing is done by default)

function Application:on_idle()
  -- TRACE("Application:on_idle()")
  
  -- it's a good idea to include this check when doing complex stuff:..
  -- if (not self.active) then 
  --   return 
  -- end

end


--------------------------------------------------------------------------------

--- Called when releasing the active document

function Application:on_release_document()
  TRACE("Application:on_release_document()")
  
  -- nothing done by default
end


--------------------------------------------------------------------------------

--- Called when a new document becomes available

function Application:on_new_document()
  TRACE("Application:on_new_document()")
  
  -- nothing done by default
end


--------------------------------------------------------------------------------

--- Receive keypress events from the Duplex Browser dialog
-- @param key (table) forwarded from the keyhandler 
-- @return (boolean) if false, key event is not forwarded to Renoise

function Application:on_keypress(key)
  TRACE("Application:on_keypress",key)
  
  return true

end

--------------------------------------------------------------------------------

--- Assign matching palette entries

function Application:_apply_palette(palette)
  TRACE("Application:_apply_palette",palette)
  
  if not palette then
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

--- Check mappings: should be called before application is started
-- @return boolean (false if missing group-names were encountered)

function Application:_check_mappings(mappings)
  TRACE("Application:_check_mappings",mappings)
  
  if (self.display) then
    local cm = self.display.device.control_map
    for k,v in pairs(mappings) do
      for k2,v2 in pairs(v) do
        if(k2 == "group_name") then
          local matched_group = false
          local wildcard_idx = string.find(v2,"*")
          if not wildcard_idx then
            matched_group = cm.groups[v2]
          else
            -- loop through groups, looking for a wildcard match
            -- (the part until the underscore, followed by digits)
            local group_basename = v2:sub(0,wildcard_idx-1)
            for k3,v3 in pairs(cm.groups) do
              matched_group = string.match(k3,group_basename.."(%d+)")
              if matched_group then
                break
              end
            end
          end
          if not matched_group then
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
  end
  return true
end


--------------------------------------------------------------------------------

--- Create application options dialog

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
      text = self._app_name,
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

    -- sort alphabetically
    local sorted_options = table.create()
    for k,v in pairs(self.options) do
      sorted_options:insert({key=k,val=v})
    end
    table.sort(sorted_options,function(a,b)
      return (a.val.label < b.val.label)
    end)
    for k,v in pairs(sorted_options) do
      if not v.val.hidden then
        elm_group:add_child(self:_add_option_row(v.val,v.key,process))
        hidden_field.value = hidden_field.value+1
      end
    end

  end
end


--------------------------------------------------------------------------------
--                         Private Helper Functions
--------------------------------------------------------------------------------

--- Build a row of option controls
-- @return ViewBuilder view

function Application:_add_option_row(t,key,process)
  TRACE("Application:_add_option_row()",t,key,process)

  local vb = self._vb
  local elm = vb:row{
    id=("dpx_app_options_row_%s"):format(key),
    tooltip=t.description,
    visible = not t.hidden,
    vb:text{
      text=t.label,
      width=90,
    },
    vb:popup{
      id=("dpx_app_options_%s"):format(key),
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

--- Set option value 
-- @param key (String) the key to change 
-- @param val (Number) the value to change
-- @param process (BrowserProcess) supply this parameter to modify the 
--  persistent settings

function Application:_set_option(key, val, process)
  TRACE("Application:_set_option()",key, val, process)

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
      process.settings.applications:property(self._app_name).options
    -- check if we need to create the node 
    if not app_options_node:property(key) then
      app_options_node:add_property(key,val)
    else
      app_options_node:property(key).value = val
    end
  
    -- update settings UI (might be hidden/non-existent)
    if (self._settings_view)then
      local elm_id = ("dpx_app_options_%s"):format(key)
      local elm = self._vb.views[elm_id]
      if elm then
        elm.value = val
      end
    end

  end

end

--------------------------------------------------------------------------------

--- Register a UIComponent so we can automatically remove it when exiting
-- note that the display might not be present, so use with caution

function Application:_add_component(c)
  
  assert(self.display, "Internal Error. Please report: " ..
    "trying to add a UIComponent to an application without a display")

  self._ui_components:insert(c)
  self.display:add(c)

end  


--------------------------------------------------------------------------------

--- Prints the type of application (class name)

function Application:__tostring()
  return type(self)
end  


--------------------------------------------------------------------------------

-- Compare application to another class instance (check for object identity)

function Application:__eq(other)
  return rawequal(self, other)
end  

