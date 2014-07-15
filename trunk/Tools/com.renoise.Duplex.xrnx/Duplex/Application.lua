--[[============================================================================
-- Duplex.Application
============================================================================]]--

--[[--

The generic application class for Duplex. Supplies any class that extend it with basic methods like start, stop, idle time notifications.

Applications are instantiated by the Duplex Browser, and all .lua files in the Duplex/Applications folder are included on startup. To create a new Duplex application, you must extend this class and put it in that folder. 

--]]

--==============================================================================

class 'Application'

--- (table) the application default options, are overridden by any user-
-- specified choice (those are stored in Preferences.xml)
Application.default_options = {}

--- (table) the default mappings for this class
-- eacb named entry can contain the following fields
-- @field description
-- @field distributable
-- @field flipped
-- @field greedy
-- @field orientation
-- @field toggleable
-- @table available_mappings
Application.available_mappings = {}

--- (table) specify custom colors, values and text for the application, e.g. 
--     button_on     = { color={0xFF,0x80,0x00}, text="▼", val=true  },
--     button_off    = { color={0x00,0x00,0x00}, text="▼", val=false },
--
Application.default_palette = {}

--==============================================================================

--- Initialize the Application class
-- @param ... (VarArg), containing:
--
--  1.  process (@{Duplex.BrowserProcess})
--  2.  mappings (table)
--  3.  palette (table)
--  4.  options (table)
--  5.  config_name (string)

function Application:__init(...)
  TRACE("Application:__init()")

  --- extract varargs using select
  local process, mappings, options, config_name, palette = select(1,...)

  --- (@{Duplex.BrowserProcess}) where our application got instantiated 
  self._process = process

  --- (table) imported from device-config
  self.mappings = mappings or {}

  --- (table) imported from device-config
  self.palette = palette or {}

  --- (table) imported from application default options
  self.options = options or {}

  --- (@{Duplex.Display}) the display associated with our process
  self.display = process.display

  --- (string) this is the name of the application as it appears
  -- in the device configuration, e.g. "MySecondMixer" - used for looking 
  -- up the correct preferences-key when specifying custom options 
  self._app_name = config_name

  --- (bool) when the application is inactive, it should 
  -- sleep during idle time and ignore any user input
  self.active = false

  -- update "self.mappings" with values from the provided configuration
  --self:_apply_mappings(mappings)

  -- update "self.palette" with values from the device-configuration
  self:_apply_palette(palette)

  -- private stuff

  --- (bool) true once build_app has been run
  self._created = false
  
  --- (renoise.ViewBuilder) the options view
  self._vb = renoise.ViewBuilder()

  --- (renoise.Views.View) the settings view
  self._settings_view = nil

  --- (table) UIComponents registered via add_component method
  self._ui_components = table.create()

end

--------------------------------------------------------------------------------

--- Start/resume application
-- @param start_running (bool) when requested to auto-start 
-- @return bool or nil, false when application failed to start

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

  -- iterate through all registered UI components 
  for k,v in ipairs(self._ui_components) do

    --print("Application:start_app - _ui_components k,v",k,v)
    v:add_listeners()

    -- cap values to allowed range
    -- (floor/ceiling might have been set after creation)
    -- TODO refactor into widget_hooks (support complex values)
    if v.value and (type(v.value) == "number") then
      v.value = clamp_value(v.value,v.floor,v.ceiling)
    end

  end

  if (self.display) then
    self.display:apply_tooltips()
    self.display:apply_midi_mappings()
  end

  self.active = true

  return true

end


--------------------------------------------------------------------------------

--- Stop application, set active flag to false

function Application:stop_app()
  TRACE("Application:stop_app()")
  
  self.active = false

end


--------------------------------------------------------------------------------

--- Create application (build interface)
-- @return (bool) true when application was built. Can fail e.g. when a 
-- device configuration fails to provide a required mapping

function Application:_build_app()
  TRACE("Application:_build_app()")
  
  return true

end


--------------------------------------------------------------------------------

--- Destroy application: unregister components, set to inactive state
-- (not actually a used feature anymore?)

function Application:destroy_app()
  TRACE("Application:destroy_app()")
  
  self:stop_app()

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

--- Called when window loose focus

function Application:on_window_resigned_active()
  --TRACE("Application:on_window_resigned_active()")
  
  -- nothing done by default
end


--------------------------------------------------------------------------------

--- Called when window receive/regain focus

function Application:on_window_became_active()
  --TRACE("Application:on_window_became_active()")
  
  -- nothing done by default
end


--------------------------------------------------------------------------------

--- Receive keypress events from the Duplex Browser dialog
-- @param key (table) forwarded from the keyhandler 
--    key = {  
--      name,      -- name of the key, like 'esc' or 'a' - always valid  
--      modifiers, -- modifier states. 'shift + control' - always valid  
--      character, -- character representation of the key or nil  
--      note,      -- virtual keyboard piano key value (starting from 0) or nil  
--      repeated,  -- true when the key is soft repeated (hold down)  
--    }
-- @return (bool) if false, key event is not forwarded to Renoise

function Application:on_keypress(key)
  TRACE("Application:on_keypress",key)
  
  return true

end

--------------------------------------------------------------------------------

--- Assign matching palette entries
-- @param palette (table)

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
-- @param mappings (table) available_mappings 
-- @return bool, false if missing group-names were encountered

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
-- @param process (@{Duplex.BrowserProcess})  

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
-- @return renoise.Views.View

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
-- @param key (string) the key to change 
-- @param val (int or string) the value to change
-- @param process (@{Duplex.BrowserProcess}) supply this parameter to modify the 
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
-- @param c (@{Duplex.UIComponent})

function Application:_add_component(c)
  TRACE("Application:_add_component(c)",c)
  
  assert(self.display, "Internal Error. Please report: " ..
    "trying to add a UIComponent to an application without a display")

  -- todo: refactor as table in UIComponent: 
  -- disallowed_widget_types = {"MultiLineText"}, etc
  local widgets = c:_get_widgets()
  for k,v in ipairs(widgets) do
    if (type(c) == "UISlider") then
      if (type(v) == "MultiLineText") or
        (type(v) == "XYPad") 
      then
        renoise.app():show_warning("Cannot assign UISlider to "..type(v)..", maybe the device configuration contain an invalid entry?")
        return
      end
    end
  end

  self._ui_components:insert(c)
  self.display:add(c)


end  


--------------------------------------------------------------------------------

--- Return the type of application (class name)
-- @return string

function Application:__tostring()
  return type(self)
end  


--------------------------------------------------------------------------------

--- Compare application to another class instance (check for object identity)
-- @return bool

function Application:__eq(other)
  return rawequal(self, other)
end  

