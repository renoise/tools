--[[----------------------------------------------------------------------------
Duplex.BrowserProcess
----------------------------------------------------------------------------]]--
--[[--
Describes a process launched by the duplex browser - a device with one or more applications, set up by a device configuration

--]]

--==============================================================================

class 'BrowserProcess'

--------------------------------------------------------------------------------

--- Initialize the BrowserProcess class
-- @param p_browser (@{Duplex.Browser})

function BrowserProcess:__init(p_browser)
  TRACE("BrowserProcess:__init")

  --- (table) the full configuration we got instantiated with (if any)
  self.configuration = nil

  --- (table) shortcut for the configurations user settings
  self.settings = nil

  --- (Device), instance of @{Duplex.MidiDevice} or @{Duplex.OscDevice} class
  self.device = nil 
  
  --- (@{Duplex.Display})
  self.display = nil 

  --- (@{Duplex.MessageStream})
  self._message_stream = nil

  --- (renoise.Views.View) built by the display for the device
  self._control_surface_view = nil

  -- (renoise.Views.View) built by the display for the device
  self._control_surface_parent_view = nil

  -- (renoise.Views.View) for displaying/editing device settings
  self._settings_dialog = nil

  -- (renoise.Views.View) for displaying/editing device settings
  self._settings_view = nil

  --- (table) list of instantiated apps for the current configuration
  self._applications = table.create() 

  --- (bool) true when this process was running at least once after instantiated
  self._was_running = false

  --- (Renoise.ViewBuilder) 
  self._vb = renoise.ViewBuilder()

  --- (@{Duplex.Browser}) 
  self.browser = p_browser

end


--------------------------------------------------------------------------------

--- Check if this process matches the given device configurations
-- @param device_display_name (String)
-- @param config_name (String)
-- @return (bool) 

function BrowserProcess:matches(device_display_name, config_name)

  return (self.configuration ~= nil) and
    (self.configuration.device.display_name == device_display_name) and  
    (self.configuration.name == config_name)
end

--------------------------------------------------------------------------------

--- Check if this process matches the given configuration
-- @param config (String)
-- @return (bool) 

function BrowserProcess:matches_configuration(config)
  return self:matches(config.device.display_name, config.name)
end


--------------------------------------------------------------------------------

--- Decide whether the process instantiated correctly
-- @return (bool)

function BrowserProcess:instantiated()
  return (self.configuration ~= nil and self.device ~= nil)
end


--------------------------------------------------------------------------------

--- Initialize a process from the passed configuration. this will only 
-- create the device, display and app, but not start it. to start a process,
-- "start" must be called. 
-- @param configuration (Table) the device configuration
-- @return (bool) true when instantiated

function BrowserProcess:instantiate(configuration)
  TRACE("BrowserProcess:instantiate:", 
    configuration.device.display_name, configuration.name)

  assert(not self:instantiated(), "Internal Error. Please report: " .. 
    "browser process already instantiated")


  ---- validate the configuration (help controller developers to spot bugs)
  
  -- device node specified?
  if (not configuration.device) then
    renoise.app():show_warning(
      "Whoops! This configuration has no device definition")
      
    return false
  end

  -- control map specified?
  if (not configuration.device.control_map) then
    renoise.app():show_warning(
      "Whoops! This configuration has no control-map")
      
    return false
  end

  -- device class specified?
  local device_class_name = configuration.device.class_name

  if (not device_class_name) then
    local protocol = configuration.device.protocol
    
    -- use a generic class if the config does not specify one  
    if (protocol == DEVICE_PROTOCOL.MIDI)then
      device_class_name = "MidiDevice"
    
    elseif (protocol == DEVICE_PROTOCOL.OSC)then
      device_class_name = "OscDevice"
    
    else
      renoise.app():show_warning(
        ("Whoops! This configuration uses an " .. 
         "unexpected protocol (%s)"):format(protocol or "nil"))
        
      return false
    end
  end

  -- device class valid?
  if (not rawget(_G, device_class_name)) then
    renoise.app():show_warning(
      ("Whoops! Cannot instantiate device with " ..
       "unknown class: '%s'"):format(device_class_name))

    return false      
  end

  -- application class node specified?
  if (configuration.applications == nil) then 
    renoise.app():show_warning(("Whoops! Device configuration "..
       "contains no applications"))

    return false
  end
  
  -- application classes valid?
  for app_class_name in pairs(configuration.applications) do

    if configuration.applications[app_class_name].application then
      app_class_name = configuration.applications[app_class_name].application
    end
    if (not rawget(_G, app_class_name)) then
      renoise.app():show_warning(
        ("Whoops! Device configuration "..
         "contains unknown application class: '%s'"):format(
         app_class_name or "nil"))

      return false
    end
  end
  

  ---- assign the config and settings

  self.configuration = configuration
  self.settings = configuration_settings(configuration)

  ---- instantiate the device

  self._message_stream = MessageStream(self)

  if (configuration.device.protocol == DEVICE_PROTOCOL.MIDI) then

    local device_port_in = (self.settings.device_port_in.value ~= "") and 
      self.settings.device_port_in.value or configuration.device.device_port_in
      
    local device_port_out = (self.settings.device_port_out.value ~= "") and 
      self.settings.device_port_out.value or configuration.device.device_port_out
    
    self.device = _G[device_class_name](
      configuration.device.display_name, 
      self._message_stream,
      device_port_in,
      device_port_out
    )

    -- MIDI port setup changed
    renoise.Midi.devices_changed_observable():add_notifier(
      BrowserProcess._available_device_ports_changed, self
    )

  
  else  -- protocol == DEVICE_PROTOCOL.OSC

    local prefix = (self.settings.device_prefix.value ~= "") and 
      self.settings.device_prefix.value or configuration.device.device_prefix
    
    local address = (self.settings.device_address.value ~= "") and 
      self.settings.device_address.value or configuration.device.device_address
    
    local port_in = (self.settings.device_port_in.value ~= "") and 
      self.settings.device_port_in.value or configuration.device.device_port_in

    local port_out = (self.settings.device_port_out.value ~= "") and 
      self.settings.device_port_out.value or configuration.device.device_port_out

    self.device = _G[device_class_name](
      configuration.device.display_name,
      self._message_stream,
      prefix,
      address,
      tonumber(port_in),
      tonumber(port_out)
    )
  end
    
  self.device:set_control_map(
    configuration.device.control_map)

  self.display = Display(self)
  self.display.state_ctrl = StateController(self.display)
  self.device.display = self.display


  ---- instantiate all applications

  local config_apps = configuration.applications

  self._applications = table.create()

  for app_class_name,_ in pairs(config_apps) do

    local actual_cname = app_class_name
    if config_apps[app_class_name].application then
      actual_cname = config_apps[app_class_name].application
    end

    local hidden = config_apps[app_class_name].hidden_options or {}
    local mappings = table.rcopy(_G[actual_cname]["available_mappings"]) or {}
    local options = table.rcopy(_G[actual_cname]["default_options"]) or {}
    local palette = table.rcopy(_G[actual_cname]["default_palette"]) or {}
    local config_name = app_class_name

    -- import user-specified options from the preferences
    for k,v in pairs(options) do
      local app_node = self.settings.applications:property(app_class_name)
      if app_node then
        if app_node.options and app_node.options:property(k) then
          options[k].value = app_node.options:property(k).value
          if table_find(hidden,k) then
            options[k].hidden = true
          end
        end
      end
    end

    -- import mappings from device-config
    for k,v in pairs(mappings) do
      local user_mappings = config_apps[app_class_name].mappings or {}
      for k2,v2 in pairs(user_mappings) do
        if (k == k2) then
          for k3,v3 in pairs(v2) do
            mappings[k][k3] = v3
          end
        end
      end
    end
    
    -- merge with palette from device-config
    for k,v in pairs(palette) do
      local user_palette = config_apps[app_class_name].palette or {}
      for k2,v2 in pairs(user_palette) do
        if (k == k2) then
          for k3,v3 in pairs(v2) do
            palette[k][k3] = v3
          end
        end
      end
    end

    local app_instance = nil

    app_instance = _G[actual_cname](
        self, mappings, options, config_name, palette)
    
    self._applications:insert(app_instance)
  end

  self._was_running = false
  
  return true
end

--------------------------------------------------------------------------------

--- Handle device hot-plugging (ports changing while Renoise is running)

function BrowserProcess:_available_device_ports_changed()
  TRACE("BrowserProcess:_available_device_ports_changed()")

  -- close the device setting dialogs on MIDI port changes 
  -- so we don't have to bother updating them
  
  if (self:settings_dialog_visible()) then

    if (self.device.protocol == DEVICE_PROTOCOL.MIDI) then
      
      local ports_in,ports_out = Device.collect_midi_ports()
      self.device._vb.views["dpx_device_port_in"].items = ports_in
      self.device._vb.views["dpx_device_port_out"].items = ports_out
      
      --[[
      local device_port_in = (self.settings.device_port_in.value ~= "") and 
        self.settings.device_port_in.value or self.configuration.device.device_port_in
        
      local device_port_out = (self.settings.device_port_out.value ~= "") and 
        self.settings.device_port_out.value or self.configuration.device.device_port_out
      
      --print("*** device_port_in,device_port_out",device_port_in,device_port_out)
      ]]

    end

    --self:close_settings_dialog()

  end

  

end

--------------------------------------------------------------------------------

--- Decide whether the device settings dialog is visible 
-- @return (bool) 

function BrowserProcess:settings_dialog_visible()
  TRACE("BrowserProcess:settings_dialog_visible()")

  return (self._settings_dialog and self._settings_dialog.visible)
end

--------------------------------------------------------------------------------

--- Deinitialize a process actively. can always be called, even when 
-- initialization never happened

function BrowserProcess:invalidate()
  TRACE("BrowserProcess:invalidate")

  while (not self._applications:is_empty()) do
    local last_app = self._applications[#self._applications]
    if (last_app.running) then 
      last_app:stop_app() 
    end
    last_app:destroy_app()
    
    self._applications:remove(#self._applications)
  end
  
  self._was_running = false
  
  self._message_stream = nil
  self.display = nil

  if (self.device) then
    if (self:settings_dialog_visible()) then
      self:close_settings_dialog()
    end
    
    if (self:control_surface_visible()) then
      self:hide_control_surface()
    end
    
    self.device:release()
    self.device = nil
  end
  
  self.configuration = nil
end


--------------------------------------------------------------------------------

--- Decide if process is running (its apps are running)
-- @return bool

function BrowserProcess:running()

  if (#self._applications == 0) then
    return false -- can't run without apps
  end
  
  for _,app in pairs(self._applications) do
    if (not app.active) then
      return false
    end
  end
    
  return true
end


--------------------------------------------------------------------------------

--- Start running a fully configured process. returns true when successfully 
-- started, else false (may happen if one of the apps failed to start)

function BrowserProcess:start(start_running)
  TRACE("BrowserProcess:start",start_running)

  assert(self:instantiated(), "Internal Error. Please report: " .. 
    "trying to start a process which was not instantiated")

  assert(not self:running(), "Internal Error. Please report: " ..
    "trying to start a browser process which is already running")
  
  local succeeded = true
  
  -- start every single app we have
  for _,app in pairs(self._applications) do
    if (app:start_app(start_running) == false) then
      succeeded = false
      break
    end
  end
  
  -- stop already started apps on failures
  if (not succeeded) then
    for _,app in pairs(self._applications) do
      if (app.running) then
        app:stop_app()
      end
    end
  end
  
  -- refresh the display when reactivating an old process
  if (succeeded and self._was_running) then
    self.display:clear()
  end

  self._was_running = succeeded
    
  return succeeded
end


--------------------------------------------------------------------------------

--- Stop a running process. will not invalidate it, just stop all apps

function BrowserProcess:stop()
  TRACE("BrowserProcess:stop")

  assert(self:instantiated(), "Internal Error. Please report: " ..
    "trying to stop a process which was not instantiated")

  assert(self:running(), "Internal Error. Please report: " ..
    "trying to stop a browser process which is not running")
  
  for _,app in pairs(self._applications) do
    app:stop_app()
  end
end


--------------------------------------------------------------------------------

--- Returns true when the processes control surface is currently visible
-- (this is also an indication of whether this is the selected device)

function BrowserProcess:control_surface_visible()
  return (self._control_surface_view ~= nil)
end


--------------------------------------------------------------------------------

--- Show a device control surfaces in the browser gui
-- @param parent_view (ViewBuilder) the browser GUI

function BrowserProcess:show_control_surface(parent_view)
  TRACE("BrowserProcess:show_control_surface")

  assert(self:instantiated(), "Internal Error. Please report: " ..
    "trying to show a control map GUI which was not instantiated")
  
  assert(not self:control_surface_visible(), 
    "Internal Error. Please report: " ..
    "trying to show a control map GUI which is already shown")
    
  -- add the device GUI to the browser GUI
  self._control_surface_parent_view = parent_view

  self._control_surface_view = 
    self.display:build_control_surface()

  parent_view:add_child(self._control_surface_view)

  -- refresh the display when reactivating an old process
  if (self:running()) then
    self.display:clear()
  end
end


--------------------------------------------------------------------------------

--- Display, or bring the browser dialog to front

function BrowserProcess:show_settings_dialog()
  TRACE("BrowserProcess:show_settings_dialog")

  -- already visible? bring to front...
  if (self._settings_dialog and self._settings_dialog.visible) then
    self._settings_dialog:show()
    return    
  end

  local vb = self._vb

  local val_unhandled = self.settings.pass_unhandled.value
  local txt_unhandled = "When enabled, messages that are not handled by an "
                      .."\napplication are forwarded to Renoise (this also "
                      .."\napplies when the whole configuration is stopped). "
                      .."\nAllows you to use Renoise MIDI mapping-features in "
                      .."\ncombination with Duplex"

  -- define the basic settings view
  if not self._settings_view then
    self._settings_view = vb:column{
      spacing = DEFAULT_SPACING,
      margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
      vb:row{
        id="dpx_device_settings_root",
      },
      vb:column{
        id="dpx_unhandled_root",
        vb:row{
          vb:checkbox{
            value = val_unhandled,
            notifier = function(v)
              self.settings.pass_unhandled.value = v
            end,
          },
          vb:text {
            text = "Pass unhandled MIDI messages to Renoise",
            tooltip = txt_unhandled,
          }
        },
      },
      vb:space{
        height = 4,
      },
      vb:row{
        id="dpx_app_settings_root",
        spacing = DEFAULT_SPACING,
        vb:column{id="dpx_app_settings_col1",spacing = DEFAULT_SPACING},
        vb:column{id="dpx_app_settings_col2",spacing = DEFAULT_SPACING},
        vb:column{id="dpx_app_settings_col3",spacing = DEFAULT_SPACING},
        vb:column{id="dpx_app_settings_col4",spacing = DEFAULT_SPACING},
        vb:column{id="dpx_app_settings_col5",spacing = DEFAULT_SPACING},
        vb:column{id="dpx_app_settings_col6",spacing = DEFAULT_SPACING},
      }
    }

    -- attach the device settings
    self.device:show_settings_dialog(self)
    vb.views.dpx_device_settings_root:add_child(self.device._settings_view)

    -- sort alphabetically
    table.sort(self._applications,function(a,b)
      return (a._app_name < b._app_name)
    end)

    -- create & attach the various application settings
    local app_count = 0
    local apps_per_col = 16
    for _,app in pairs(self._applications) do
      app:_build_options(self)
      local col_idx = math.floor(app_count/apps_per_col)+1
      local col_id = ("dpx_app_settings_col%d"):format(col_idx)
      if not vb.views[col_id] then
        local msg = "The device configuration contains too many applications,"
                  .."\nsome options will not be available"
        renoise.app():show_warning(msg)
        break
      else
        vb.views[col_id]:add_child(app._settings_view)
        app_count = app_count + 1 
      end
    end

    -- show/hide the "unhandled message" part
    local elm = vb.views.dpx_unhandled_root
    local show_unhandled = (self.device.protocol == DEVICE_PROTOCOL.MIDI)
    vb.views.dpx_unhandled_root.visible = show_unhandled

  end

  self._settings_dialog = renoise.app():show_custom_dialog(
    "Duplex: Device Settings", self._settings_view)


end

--------------------------------------------------------------------------------

--- Close the device settings, when open

function BrowserProcess:close_settings_dialog()
  TRACE("BrowserProcess:close_settings_dialog()")

  if (self._settings_dialog and self._settings_dialog.visible) then
    self._settings_dialog:close()
  end

  self._settings_dialog = nil
end
  

--------------------------------------------------------------------------------

--- Hide the device control surfaces, when showing it...

function BrowserProcess:hide_control_surface()
  TRACE("BrowserProcess:hide_control_surface")

  assert(self:instantiated() and self:control_surface_visible(), 
    "Internal Error. Please report: " .. 
    "trying to hide a control map GUI which was not shown")
    
  -- remove the device GUI from the browser GUI
  self._control_surface_parent_view:remove_child(
    self._control_surface_view)

  self._control_surface_view = nil
  self._control_surface_parent_view = nil
end


--------------------------------------------------------------------------------

--- Clears/repaints the display, device, virtual UI

function BrowserProcess:clear_display()
  TRACE("BrowserProcess:clear_display")
  
  assert(self:instantiated(), "Internal Error. Please report: " ..
    "trying to clear a control map GUI which was not instantiated")
  
  if (self:running()) then
    self.display:clear() 
  end
end


--------------------------------------------------------------------------------

--- Start/stop device midi dump
-- @param dump (bool), true to start dumping MIDI

function BrowserProcess:set_dump_midi(dump)
  TRACE("BrowserProcess:set_dump_midi", dump)

  if (self:instantiated()) then
    if (self.device.protocol == DEVICE_PROTOCOL.MIDI) then
      self.device.dump_midi = dump
    end
  end
end


--------------------------------------------------------------------------------

--- Start/stop device osc dump
-- @param dump (bool), true to start dumping OSC

function BrowserProcess:set_dump_osc(dump)
  TRACE("BrowserProcess:set_dump_midi", dump)

  if (self:instantiated()) then
    if (self.device.protocol == DEVICE_PROTOCOL.OSC) then
      self.device.dump_osc = dump
    end
  end
end


--------------------------------------------------------------------------------

--- Provide idle support for all active apps

function BrowserProcess:on_idle()
  -- TRACE("BrowserProcess:idle")
  
  if (self:instantiated()) then
    
    -- idle process for stream
    self._message_stream:on_idle()
    
    -- modify ui components
    self.display:update("idle")
  
    -- then refresh the display 
    for _,app in pairs(self._applications) do
      app:on_idle()
    end
  end
end


--------------------------------------------------------------------------------

--- Provide document released notification for all active apps

function BrowserProcess:on_release_document()
  TRACE("BrowserProcess:on_release_document")

  if (self:instantiated()) then
    for _,app in pairs(self._applications) do
      app:on_release_document()
    end
  end
end


--------------------------------------------------------------------------------

--- Provide new document notification for all active apps

function BrowserProcess:on_new_document()
  TRACE("BrowserProcess:on_new_document")

  if (self:instantiated()) then
    for _,app in pairs(self._applications) do
      app:on_new_document()
    end
  end
end


--------------------------------------------------------------------------------

--- Provide window active notification for all active apps

function BrowserProcess:on_window_became_active()
  TRACE("BrowserProcess:on_window_became_active")

  if (self:instantiated()) then
    for _,app in pairs(self._applications) do
      app:on_window_became_active()
    end
  end
end


--------------------------------------------------------------------------------

--- Provide window resigned notification for all active apps

function BrowserProcess:on_window_resigned_active()
  TRACE("BrowserProcess:on_window_resigned_active")

  if (self:instantiated()) then
    for _,app in pairs(self._applications) do
      app:on_window_resigned_active()
    end
  end
end


--------------------------------------------------------------------------------

--- Comparison operator (check configs only)
-- @param other (BrowserProcess) the process to compare against

function BrowserProcess:__eq(other)
  return self:matches_configuration(other.configuration)
end

