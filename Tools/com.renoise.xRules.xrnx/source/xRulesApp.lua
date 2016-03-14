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

function xRulesApp:__init(prefs)

  assert(type(prefs) == "xRulesAppPrefs",
    "Settings needs to be an instance of xRulesAppPrefs") 

  --- xRulesAppPrefs, current settings
  self.prefs = prefs

  --  xRules, our main class 
  self.xrules = xRules{
    multibyte_enabled = self.prefs.midi_multibyte_enabled.value,
    nrpn_enabled = self.prefs.midi_nrpn_enabled.value,
    terminate_nrpns = self.prefs.midi_terminate_nrpns.value,
  }

  --- xRulesUI
  self.ui = xRulesUI(self)

  -- boolean, temporarily ignore modifications to rulesets
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
    --print(">>> xRulesApp:xrules.osc_devices_observable fired...",args)

    local device = self.xrules.osc_devices[args.index]

    if (args.type == "insert") then
      self:attach_to_osc_device(device)
    else
      self:detach_from_osc_device(device)
    end

    -- export devices 
    self:osc_device_modified_handler()

    -- rebuild to include device-name selectors
    self.ui._build_rule_requested = true

  end)

  self:import_profile()
  self.ui:select_rule_within_set(1,1)

end

--------------------------------------------------------------------------------
--- show the dialog (build ui if needed)

function xRulesApp:show_dialog()
  self.ui:show()
end

--------------------------------------------------------------------------------
--- hide the dialog 

function xRulesApp:hide_dialog()
  self.ui:hide()
end

--------------------------------------------------------------------------------
-- store active rulesets in preferences

function xRulesApp:store_ruleset_prefs()

  if self.suppress_ruleset_notifier then 
    --print("*** skip saving ruleset prefs")
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

  self.xrules.osc_client:create(self.prefs.osc_client_host.value,self.prefs.osc_client_port.value)
  self:apply_settings()

  self.xrules.active = true

end


--------------------------------------------------------------------------------
-- close devices, ignore messages

function xRulesApp:shutdown()

  self.xrules.active = false

  -- TODO

end

--------------------------------------------------------------------------------
--- apply settings, activate devices & rulesets

function xRulesApp:apply_settings()

  for k = 1, #self.prefs.midi_inputs do
    local port_name = self.prefs.midi_inputs[k].value
    self.xrules:open_midi_input(port_name)
  end

  for k = 1, #self.prefs.midi_outputs do
    local port_name = self.prefs.midi_outputs[k].value
    self.xrules:open_midi_output(port_name)
  end

  --print("self.prefs.osc_devices",self.prefs.osc_devices)
  for k = 1, #self.prefs.osc_devices do
    local osc_device = self.prefs.osc_devices[k].value
    local device = xOscDevice()
    device:import(osc_device)
    self.xrules:add_osc_device(device)
    
    --[[
    if not skip_prefs then
      self.prefs.osc_devices:insert(device:export())
    end
    ]]

  end

end

--------------------------------------------------------------------------------
-- when something has changed, export osc_devices to preferences

function xRulesApp:osc_device_modified_handler()

  self.prefs:remove_property(self.prefs.osc_devices)
  self.prefs:add_property("osc_devices",renoise.Document.ObservableStringList())

  for k,v in ipairs(self.xrules.osc_devices) do
    self.prefs.osc_devices:insert(v:export())
  end

end

--------------------------------------------------------------------------------

function xRulesApp:attach_to_osc_device(device)

  local obs = device.modified_observable
  local handler = self.osc_device_modified_handler
  xObservable.attach(obs,self,handler)

end

--------------------------------------------------------------------------------

function xRulesApp:detach_from_osc_device(device)

  local obs = device.modified_observable
  local handler = self.osc_device_modified_handler
  if obs:has_notifier(handler) then 
    obs:remove_notifier(handler) 
  end

end


--------------------------------------------------------------------------------
-- import rulesets, offer to 'fix' missing/invalid definitions

function xRulesApp:import_profile()

  self.xrules.active = self.prefs.autorun_enabled.value
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

