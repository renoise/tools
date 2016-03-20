--[[============================================================================
-- xRulesApp
============================================================================]]--

--[[--

  xRulesApp is an implemention of xRules
  Features device support, preferences and user-interface 

  See also:
    xLib.xRules

--]]

--==============================================================================

class 'xRulesApp'

function xRulesApp:__init(xprefs)
  TRACE("xRulesApp:__init()",xprefs)

  --- string, current tool version (for display)
  self.version = "0.65"

  --- xRulesAppPrefs, current settings
  self.prefs = renoise.tool().preferences

  --- xPreferences
  self.xprefs = xprefs

  --  xRules, our main class 
  self.xrules = xRules{
    multibyte_enabled = self.prefs.midi_multibyte_enabled.value,
    nrpn_enabled = self.prefs.midi_nrpn_enabled.value,
    terminate_nrpns = self.prefs.midi_terminate_nrpns.value,
  }

  --- xRulesUI
  self.ui = xRulesUI(self)

  -- boolean, don't synchronize preferences while true
  self.suppress_osc_device_notifier = false

  -- boolean, don't synchronize preferences while true
  self.suppress_ruleset_notifier = false

  --== initialize ==--
  
  self.xrules.ruleset_observable:add_notifier(function()
    --print("xRulesApp: ruleset_observable fired...")
    self:store_ruleset_prefs()
  end)

  self.ui.minimized_observable:add_notifier(function()
    self.prefs.show_minimized.value = self.ui.minimized
  end)

  -- flash indicator when a message was matched,
  -- and add the result to the log window 
  self.xrules.callback = function(xmsg_in,ruleset_idx,rule_idx,str_msg)
    --print("self.xrules.callback - xmsg_in,ruleset_idx,rule_idx,str_msg",xmsg_in,ruleset_idx,rule_idx,str_msg)
    if (type(xmsg_in) == "xOscMessage") then
      self.ui:enable_indicator(ruleset_idx,rule_idx,"osc")
    elseif (type(xmsg_in) == "xMidiMessage") then
      self.ui:enable_indicator(ruleset_idx,rule_idx,"midi")
    end
    if str_msg then
      local vlog = self.ui._log_dialog.vlog
      if vlog then
        vlog:add(str_msg)
      end
    end
  end

  self.xrules.osc_devices_observable:add_notifier(function(args)
    --print("xrules.osc_devices_observable fired...")
    if (args.type == "insert") then
      local device = self.xrules.osc_devices[args.index]
      xObservable.attach(device.modified_observable,self,self.export_osc_devices)
    --elseif (args.type == "remove") then
    end
    self:export_osc_devices()
    -- rebuild to include device-name selectors
    self.ui._build_rule_requested = true
  end)

  -- MIDI port setup changed
  renoise.Midi.devices_changed_observable():add_notifier(function()
    self:available_midi_ports_changed()
  end)

  self:import_profile()
  self.ui:select_rule_within_set(1,1)

end

--------------------------------------------------------------------------------
--- show the dialog (build ui if needed)

function xRulesApp:show_dialog()
  TRACE("xRulesApp:show_dialog()")
  self.ui:show()
  
  if not self.xrules.active then
    self:launch()
  end

end

--------------------------------------------------------------------------------
--- hide the dialog 

function xRulesApp:hide_dialog()
  TRACE("xRulesApp:hide_dialog()")
  self.ui:hide()
end

--------------------------------------------------------------------------------
-- store active rulesets in preferences

function xRulesApp:store_ruleset_prefs()
  TRACE("*** xRulesApp:store_ruleset_prefs()")

  if self.suppress_ruleset_notifier then 
    return 
  end

  for k = #self.prefs.active_rulesets,1,-1 do 
    self.prefs.active_rulesets:remove(k)
  end

  if not table.is_empty(self.xrules.rulesets) then
    for k = 1,#self.xrules.rulesets do 
      local v = self.xrules.rulesets[k]
      self.prefs.active_rulesets:insert(v.file_path)
    end
  end
  
end



--------------------------------------------------------------------------------
-- open devices, start listening

function xRulesApp:launch()
  TRACE("xRulesApp:launch()")

  self.xrules.osc_client:create(self.prefs.osc_client_host.value,self.prefs.osc_client_port.value)
  self:apply_settings()

  self.xrules.active = true

end


--------------------------------------------------------------------------------
-- close devices, ignore messages

function xRulesApp:shutdown()
  TRACE("xRulesApp:shutdown()")

  self.xrules.active = false

  -- shutdown all devices

  for k = 1, #self.prefs.midi_inputs do
    local port_name = self.prefs.midi_inputs[k].value
    self.xrules:close_midi_input(port_name)
  end

  for k = 1, #self.prefs.midi_outputs do
    local port_name = self.prefs.midi_outputs[k].value
    self.xrules:close_midi_output(port_name)
  end

  self.suppress_osc_device_notifier = true
  for k,v in ripairs(self.xrules.osc_devices) do
    self.xrules:remove_osc_device(k)
  end
  self.suppress_osc_device_notifier = false

end

--------------------------------------------------------------------------------

function xRulesApp:available_midi_ports_changed()
  TRACE("xRulesApp:available_midi_ports_changed()")

  self:initialize_midi_devices()

  self.ui._build_rule_requested = true

  local prefs_dialog = self.ui._prefs_dialog
  if prefs_dialog.dialog and prefs_dialog.dialog.visible then
    prefs_dialog:update_dialog()
  end

end

--------------------------------------------------------------------------------
-- open the MIDI inputs & outputs specified in preferences 

function xRulesApp:initialize_midi_devices()
  TRACE("xRulesApp:initialize_midi_devices()")

  --xRule.ASPECT_DEFAULTS.PORT_NAME = renoise.Midi.available_input_devices()

  for k = 1, #self.prefs.midi_inputs do
    local port_name = self.prefs.midi_inputs[k].value
    self.xrules:open_midi_input(port_name)
  end

  for k = 1, #self.prefs.midi_outputs do
    local port_name = self.prefs.midi_outputs[k].value
    self.xrules:open_midi_output(port_name)
  end

end

--------------------------------------------------------------------------------
--- activate devices & rulesets

function xRulesApp:apply_settings()
  TRACE("xRulesApp:apply_settings()")

  self:initialize_midi_devices()

  self.suppress_osc_device_notifier = true
  --print("got here 1 - self.prefs.osc_devices",self.prefs.osc_devices)
  for k = 1, #self.prefs.osc_devices do
    --print(">>> self.prefs.osc_devices[",k,"]",self.prefs.osc_devices[k],type(self.prefs.osc_devices[k]))
    local device_def = self.prefs.osc_devices[k].value
    self:add_osc_device(device_def)
  end
  self.suppress_osc_device_notifier = false

end

--------------------------------------------------------------------------------
-- when some device property has changed, export osc_devices to preferences
-- (skip while application is disabled, starting up or shutting down...)

function xRulesApp:export_osc_devices()
  TRACE("xRulesApp:export_osc_devices()")

  if self.suppress_osc_device_notifier then
    return
  end

  if not self.xrules.active then
    return
  end

  self.prefs:remove_property(self.prefs.osc_devices)
  self.prefs:add_property("osc_devices",renoise.Document.ObservableStringList())

  for k,v in ipairs(self.xrules.osc_devices) do
    self.prefs.osc_devices:insert(v:export())
  end

end

--------------------------------------------------------------------------------
-- add new OSC device from definition
-- @param device_def (table)

function xRulesApp:add_osc_device(device_def)
  TRACE("xRulesApp:add_osc_device(device_def)",device_def)

  local device = xOscDevice()
  device:import(device_def)
  self.xrules:add_osc_device(device)
  --print(">>> add_osc_device - device.active",device.active)

end

--------------------------------------------------------------------------------
-- import rulesets, offer to 'fix' missing/invalid definitions

function xRulesApp:import_profile()
  TRACE("xRulesApp:import_profile()")

  --self.xrules.active = self.prefs.autorun_enabled.value

  self.ui.minimized = self.prefs.show_minimized.value

  local active_rulesets = self.prefs.active_rulesets
  self.suppress_ruleset_notifier = true
  local err_msgs = {}
  if (#active_rulesets > 0) then
    --print("*** loading a total of",#active_rulesets,"rulesets")
    for k = 1, #active_rulesets do
      local v = active_rulesets[k]   
      --print("active_ruleset",k,v)
      local passed,err = self.xrules:load_ruleset(v.value)
      if not passed then
        table.insert(err_msgs,err)
      end
    end
  end
  self.suppress_ruleset_notifier = false

  if not table.is_empty(err_msgs) then
    local str_msg = "There was a problem loading one or more rulesets -"
                  .."\nclick 'Fix' to remove the affected sets"
    str_msg = str_msg .. "\n\n" .. table.concat(err_msgs,"\n")
    local choice = renoise.app():show_prompt("Message from xRules",str_msg,{"Fix","Ignore"})
    if (choice == "Fix") then
      self:store_ruleset_prefs()
    end
  end

end

