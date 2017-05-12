--[[============================================================================
xRules
============================================================================]]--

--[[--

Rewrite MIDI/OSC messages on-the-fly using generated code

## About

xRules works by applying "rules" to the input, using specific conditions as 
triggers. Each rule can then change the input in a number of different ways. 

An implementation of this class (also called xRules) is available from the 
Renoise tools page (http://www.renoise.com/tools/xrules). The tool adds a 
visual interface, device management and more. 


## See also
@{xRuleset}  - (supporting class)
@{xRule}     - (supporting class)


]]


class 'xRules'

xRules.RULESET_FOLDER = "./rulesets/"

xRules.OUTPUT_OPTIONS = {
  INTERNAL_AUTO = "internal_auto",  -- output routed notes, others are raw
  INTERNAL_RAW  = "internal_raw",   -- always output as raw
  EXTERNAL_MIDI = "external_midi",  -- using PORT_NAME
  EXTERNAL_OSC  = "external_osc",   -- using OSC_DEVICE_NAME
}

--------------------------------------------------------------------------------

function xRules:__init(...)
  TRACE("xRules:__init(...)",...)

	local args = cLib.unpack_args(...)

  --- boolean
  self.active = property(self.get_active,self.set_active)
  self.active_observable = renoise.Document.ObservableBoolean(false)

  --- table<xRuleset>
  self.rulesets = {}

  --- define a function to display matched messages
  -- @param xmsg_in (xMessage)
  -- @param ruleset_idx (int)
  -- @param rule_idx (int)
  self.callback = nil

  ---  xMidiInput
  self.midi_input = xMidiInput{
    multibyte_enabled = args.multibyte_enabled,
    nrpn_enabled = args.nrpn_enabled,
    terminate_nrpns = args.terminate_nrpns,
  }

  --- number, default order of NRPN bytes (output) 
  self.nrpn_order = args.nrpn_order or xMidiMessage.NRPN_ORDER.MSB_LSB

  --- boolean, whether to terminate NRPNs (output)
  self.terminate_nrpns = args.terminate_nrpns_out or false


  --[[
  self.voice_manager = xVoiceManager{
    **TODO**
  }
  ]]

  --- table<xOscDevice>
  self.osc_devices = table.create()
  self.osc_devices_observable = renoise.Document.ObservableNumberList()

  --- table<renoise.Midi.MidiInputDevice>
  self.midi_inputs = {}

  --- table<renoise.Midi.MidiOutputDevice>
  self.midi_outputs = {}

  --- xOscClient, used for internal routing 
  self.osc_client = xOscClient()

  --- xOscRouter, incoming OSC is passed here
  self.osc_router = xOscRouter()

  --- xAutomation, built-in automation recording
  self.automation = xAutomation{
    highres_mode = true
  }

  --- table<uid>, relations between osc-patterns and osc router
  -- associative array, ordered by the pattern uid
  -- {rule_index=int,ruleset_index=int,router_index=int}
  self.osc_pattern_map = {}

  --- observable, track when rulesets are added/swapped/removed
  self.ruleset_observable = renoise.Document.ObservableNumberList()

  --- int, 0 = no selection
  self.selected_ruleset_index = property(self.get_selected_ruleset_index,self.set_selected_ruleset_index)
  self.selected_ruleset_index_observable = renoise.Document.ObservableNumber(0)
  self.selected_rule_index = property(self.get_selected_rule_index,self.set_selected_rule_index)
  self.selected_ruleset = property(self.get_selected_ruleset)
  self.selected_rule = property(self.get_selected_rule)

  --- table<function> rules associated with aspects
  self.aspect_handlers = {}

  --- table<function> rules associated with channels
  self.channel_handlers = {}

  -- initialize --

  self.midi_input.callback_fn = function(xmsg)
    self:match_message(xmsg)
  end


end

--==============================================================================
-- Getters/Setters 
--==============================================================================

function xRules:get_active()
  return self.active_observable.value
end

function xRules:set_active(val)
  self.active_observable.value = val
end

--------------------------------------------------------------------------------

function xRules:get_selected_ruleset_index()
  --TRACE("xRules:get_selected_ruleset_index()",self.selected_ruleset_index_observable.value)
  return self.selected_ruleset_index_observable.value
end

function xRules:set_selected_ruleset_index(val)
  --TRACE("xRules:set_selected_ruleset_index(val)",val)
  self.selected_ruleset_index_observable.value = val
end

--------------------------------------------------------------------------------

function xRules:get_selected_ruleset()
  return self.rulesets[self.selected_ruleset_index]
end

--------------------------------------------------------------------------------

function xRules:get_selected_rule()
  --TRACE("xRules:get_selected_rule()")
  local xruleset = self.selected_ruleset
  if xruleset then
    return xruleset.rules[xruleset.selected_rule_index]
  end
end

--------------------------------------------------------------------------------

function xRules:get_selected_rule_index()
  --TRACE("xRulesUI:get_selected_rule_index()")
  local xruleset = self.selected_ruleset
  if xruleset then
    return xruleset.selected_rule_index
  else
    return 0
  end
end

function xRules:set_selected_rule_index(val)
  --TRACE(">>> xRulesUI:set_selected_rule_index(val)")
  local xruleset = self.selected_ruleset
  if xruleset then
    xruleset.selected_rule_index = val
  end
end

--==============================================================================
-- Class Methods
--==============================================================================

-- input raw midi messages here and pass them into xMidiInput
-- @param msg (table), midi message

function xRules:input_midi(midi_msg,port_name)
  TRACE("xRules:input_midi(midi_msg,port_name)",midi_msg,port_name)

  assert(type(midi_msg),"table","Expected midi_msg to be a table")
  assert(type(port_name),"string","Expected port_name to be a string")

  self.midi_input:input(midi_msg,port_name)

end

--------------------------------------------------------------------------------
-- input raw sysex messages here (immediately matched)
-- @param sysex_msg (table), sysex message
-- @param port_name (string)

function xRules:input_sysex(sysex_msg,port_name)
  TRACE("xRules:input_sysex(sysex_msg,port_name)",sysex_msg,port_name)

  assert(type(sysex_msg),"table","Expected sysex_msg to be a table")
  assert(type(port_name),"string","Expected port_name to be a string")

  self:match_message(xMidiMessage{
    message_type = xMidiMessage.TYPE.SYSEX,
    values = sysex_msg,
    port_name = port_name,
  })

end

--------------------------------------------------------------------------------
--- pass osc message into router
-- @param osc_msg, renoise.Osc.Message
-- @param device, xOscDevice

function xRules:input_osc(osc_msg,device)
  TRACE("xRules:input_osc(osc_msg,device)",osc_msg,device)

  assert(type(osc_msg),"Message","Expected osc_msg to be an instance of renoise.Osc.Message")
  assert(type(device),"xOscDevice","Expected device to be an instance of xOscDevice")

  local matches = self.osc_router:input(osc_msg)

  -- look up osc_pattern_map 
  for k,v in ipairs(matches) do
    if (self.osc_pattern_map[v.uid]) then
      local map = self.osc_pattern_map[v.uid]
      local xrule = self.rulesets[map.ruleset_index].rules[map.rule_index]
      local values = {}
      for k,v in ipairs(osc_msg.arguments) do
        table.insert(values,v.value)
      end
      local xmsg = xOscMessage{
        values = values,
        device_name = device.name,
        -- we _could_ supply the original osc pattern, but it's risky - 
        -- if we e.g. supply values to the arguments, the rule will 
        -- start treating wildcards as literal values
        --pattern = xrule.osc_pattern,
        pattern = xOscPattern(xrule.osc_pattern),
        osc_msg = osc_msg,
      }        
      -- match against ruleset/rule
      self:match_message(xmsg,map.ruleset_index,map.rule_index)
    end
  end

end

--------------------------------------------------------------------------------
-- pass message into our (active) rulesets
-- @param xmsg (xMidiMessage or xOscMessage)
-- @param ruleset_idx (int) optional (set to match against specific ruleset)
-- @param rule_idx (int) optional (set to match against specific rule)
-- @param force_midi (boolean) force match (used by routings)
-- @return matches (table)
--  {
--    ruleset: index
--    rules: {index,index,index}
--  },

function xRules:match_message(xmsg,ruleset_idx,rule_idx,force_midi)
  TRACE("xRules:match_message(xmsg,ruleset_idx,rule_idx,force_midi)",xmsg,ruleset_idx,rule_idx,force_midi)

  local function do_match(ruleset,ruleset_idx)
    if ruleset.active then
      if not ruleset.osc_enabled 
        and (type(xmsg) == "xOscMessage")
      then
        --LOG("This ruleset is set to ignore OSC messages")
      else
        ruleset:match_message(xmsg,ruleset_idx,rule_idx,force_midi)
      end
    end
  end

  if ruleset_idx then
    do_match(self.rulesets[ruleset_idx],ruleset_idx)
  else
    for k,ruleset in ipairs(self.rulesets) do
      do_match(ruleset,k)
    end
  end

end

--------------------------------------------------------------------------------
-- transmit matched message - either internally or externally
-- @param out (table) {target=xRules.OUTPUT_OPTIONS,xmsg=xMessage}
-- @param xmsg_in (xMessage)
-- @param ruleset_idx (int)
-- @param rule_idx (int)
-- @return bool, true when triggered
-- @return string, error message when failed

function xRules:transmit(out,xmsg_in,ruleset_idx,rule_idx)
  TRACE("xRules:transmit(out,xmsg_in,ruleset_idx,rule_idx)",out,xmsg_in,ruleset_idx,rule_idx)

  local rns = renoise.song()

  local target = out.target
  local xmsg = out.xmsg
  local str_msg 
  local triggered,err

  if (target == xRules.OUTPUT_OPTIONS.INTERNAL_AUTO) then
    triggered,err = self.osc_client:trigger_auto(xmsg)
    str_msg = "Renoise (AUTO) ↩ " .. tostring(xmsg)
  elseif (target == xRules.OUTPUT_OPTIONS.INTERNAL_RAW) then
    triggered,err = self.osc_client:trigger_raw(xmsg)
    str_msg = "Renoise (RAW) ↩ " .. tostring(xmsg)
  elseif (target == xRules.OUTPUT_OPTIONS.EXTERNAL_MIDI) then
    for k,midi_output in pairs(self.midi_outputs) do
      if (k == xmsg.port_name) then
        xmsg.nrpn_order = self.nrpn_order
        xmsg.terminate_nrpns = self.terminate_nrpns
        str_msg = "MIDI ↪ " .. tostring(xmsg)
        local midi_msgs = xmsg:create_raw_message()
        for _,midi_msg in ipairs(midi_msgs) do
          midi_output:send(midi_msg)
        end
        triggered = true
        break
      end
    end
  elseif (target == xRules.OUTPUT_OPTIONS.EXTERNAL_OSC) then
    for k,osc_device in pairs(self.osc_devices) do
      if (xmsg.device_name == osc_device.name) then
        str_msg = "OSC ↪ " .. tostring(xmsg)
        triggered,err = osc_device:send(xmsg)
        break
      end
    end
  else
    -- here for compability reasons (xRules v0.5 did not have output options)
    triggered,err = self.osc_client:trigger_auto(xmsg)
    str_msg = "Renoise (AUTO) ↩ " .. tostring(xmsg)
  end

  if not triggered then
    return false,err
  end

  -- TODO register with voice-manager
  -- (need incoming as well as outgoing messages)

  -- invoke callback, i.e. to provide visual feedback
  if self.callback then
    self.callback(xmsg_in,ruleset_idx,rule_idx,str_msg)
  end

end

--------------------------------------------------------------------------------
-- remove pattern from the osc_router 
-- @param ruleset_idx, int
-- @param rule_idx, int (optional, leave out to remove whole ruleset)
-- @return int, first route index 

function xRules:remove_osc_patterns(ruleset_idx,rule_idx)
  TRACE("xRules:remove_osc_patterns(ruleset_idx,rule_idx)",ruleset_idx,rule_idx)

  local rslt = {}
  for k,v in pairs(self.osc_pattern_map) do
    if (v.ruleset_index == ruleset_idx) then
      local match_rule_idx
      if not rule_idx then
        match_rule_idx = v.rule_index
      elseif not match_rule_idx then
        match_rule_idx = rule_idx
      end
      if (v.rule_index == match_rule_idx) then        
        table.insert(rslt,v.router_index)      
        self.osc_pattern_map[k] = nil
      end
    end
  end

  table.sort(rslt)
  for k,v in ripairs(rslt) do
    self.osc_router:remove_pattern(v)
  end

  return rslt[1]

end

--------------------------------------------------------------------------------
-- maintain active indices of registered rules after they are added/removed
-- @param args (table) {type,index}
-- @param route_idx (int)

function xRules:maintain_osc_pattern_map(args,route_idx)
  TRACE("xRules:maintain_osc_pattern_map(args,route_idx)",args,route_idx)

  for k,v in pairs(self.osc_pattern_map) do
    if (v.rule_index > args.index) then
      if (args.type == "insert") then
        v.rule_index = v.rule_index+1
      elseif (args.type == "remove") then
        v.rule_index = v.rule_index-1
      end
    end
    if (v.router_index > route_idx) then
      if (args.type == "insert") then
        v.router_index = v.router_index+1
      elseif (args.type == "remove") then
        v.router_index = v.router_index-1
      end
    end
  end

end

--------------------------------------------------------------------------------
-- add/replace patterns in the osc_router

function xRules:add_osc_patterns(ruleset_idx)
  TRACE("xRules:add_osc_patterns(ruleset_idx)",ruleset_idx)
  
  local ruleset = self.rulesets[ruleset_idx]
  for k,v in ipairs(ruleset.rules) do
    self:register_with_osc_router(v.osc_pattern,ruleset_idx,k)
  end

end


--------------------------------------------------------------------------------
--- register the osc pattern
-- @return int, index of pattern within router

function xRules:register_with_osc_router(osc_pattern,ruleset_idx,rule_idx)
  TRACE("xRules:register_with_osc_router(osc_pattern,ruleset_idx,rule_idx)",osc_pattern,ruleset_idx,rule_idx)

  local router_index = self.osc_router:add_pattern(osc_pattern)
  self.osc_pattern_map[osc_pattern.uid] = {
    router_index = router_index,
    ruleset_index = ruleset_idx,
    rule_index = rule_idx,
  }

  return router_index

end

--------------------------------------------------------------------------------
-- @return boolean,string

function xRules:load_ruleset(file_path,idx)
  TRACE("xRules:load_ruleset(file_path,idx)",file_path,idx)
  
  if(type(file_path)~="string") then
    return false, "Expected file_path to be a string"
  end
  if(file_path == "") then
    return false, "Expected file_path to be a non-empty string"
  end
  if idx and (type(idx)~="number") then
    return false, "Expected idx to be a number"
  elseif not idx then
    idx = #self.rulesets + 1
  end

  local xruleset = self:add_ruleset({},idx)
  local passed,err = xruleset:load_definition(file_path)
  if not passed then
    local xruleset = self:remove_ruleset(idx)
    return false,err
  end
  xruleset.modified = false

  -- activate the osc patterns
  --[[
  for k,v in ipairs(self.rulesets) do
    self:add_osc_patterns(k)
  end
  ]]

  return true

end


--------------------------------------------------------------------------------
-- toggle active state of ruleset

function xRules:toggle_ruleset(ruleset_idx)
  TRACE("xRules:toggle_ruleset(ruleset_idx)",ruleset_idx)

  local ruleset = self.rulesets[ruleset_idx]
  if ruleset then
    ruleset.active = not ruleset.active
  end

end

--------------------------------------------------------------------------------
-- add ruleset, attach notifiers
-- @param ruleset_def (table)
-- @param ruleset_idx (int), specify index at which to insert (optional)
-- @return xRuleset

function xRules:add_ruleset(ruleset_def,ruleset_idx)
  TRACE("xRules:add_ruleset(ruleset_def,ruleset_idx)",ruleset_def,ruleset_idx)

  -- TODO implement better validation, return boolean on failure
  assert(type(ruleset_def)=="table","Expected ruleset_def to be a table")

  local ruleset = xRuleset(self,ruleset_def)

  if not ruleset_idx then
    ruleset_idx = #self.rulesets+1
  end

  -- just an extra precaution - we should always have an active ruleset
  --self.selected_ruleset_index_observable.value = val
  if (self.selected_ruleset_index == 0) then
    self.selected_ruleset_index = 1
  end

  table.insert(self.rulesets,ruleset_idx,ruleset)
  self.ruleset_observable:insert(ruleset_idx,1)

  ruleset.osc_enabled_observable:add_notifier(function()
    local xruleset = self.selected_ruleset
    if xruleset and not xruleset.suppress_notifier then
      local ruleset_idx = self.selected_ruleset_index
      if xruleset.osc_enabled then
        self:add_osc_patterns(ruleset_idx)
      else
        self:remove_osc_patterns(ruleset_idx)
      end
    end
  end)

  ruleset.rules_observable:add_notifier(function(args)
    local route_idx = nil
    if (args.type == "remove") then
      local ruleset_idx = self.selected_ruleset_index
      route_idx = self:remove_osc_patterns(ruleset_idx,args.index)
    elseif (args.type == "insert") then
      local xrule = ruleset.rules[args.index]
      local ruleset_idx = self.selected_ruleset_index
      route_idx = self:register_with_osc_router(xrule.osc_pattern,ruleset_idx,args.index)
    end
    if route_idx then
      self:maintain_osc_pattern_map(args,route_idx)
    end
  end)

  ruleset:compile()
  return ruleset

end

--------------------------------------------------------------------------------
-- @param idx (int)
-- @return boolean,string

function xRules:remove_ruleset(idx)
  TRACE("xRules:remove_ruleset(idx)",idx)

  local ruleset = self.rulesets[idx]
  if not ruleset then
    local err = ("Could not remove ruleset with index #%d- it doesn't exist"):format(idx)
    return false,err
  end

  -- trigger observables, maintain router/mappings
  for k,v in ripairs(ruleset.rules) do
    ruleset:remove_rule(k)
  end

  table.remove(self.rulesets,idx)
  self.ruleset_observable:remove(idx)

  return true

end

--------------------------------------------------------------------------------
-- @return boolean,string

function xRules:replace_ruleset(file_path,idx)
  TRACE("xRules:replace_ruleset(file_path,idx)",file_path,idx)

  assert(type(file_path)=="string","Expected file_path to be a string")
  assert(type(idx)=="number","Expected idx to be a string")

  self:remove_ruleset(idx)  
  local passed,err = self:load_ruleset(file_path,idx)

  return passed,err

end

--------------------------------------------------------------------------------
-- save current ruleset to file
-- @return boolean,string

function xRules:save_ruleset()
  TRACE("xRules:save_ruleset()")

  local xruleset = self.selected_ruleset
  local passed,err = xruleset:save_definition()
  if not passed then
    return false,err
  end
  xruleset.modified = false
  return true

end


--------------------------------------------------------------------------------
-- revert changes (reload file)
-- @return boolean,string

function xRules:revert_ruleset()
  TRACE("xRules:revert_ruleset()")

  local xruleset = self.selected_ruleset
  local xruleset_idx = self.selected_ruleset_index
  local passed,err = self:replace_ruleset(xruleset.file_path,xruleset_idx)
  if not passed then
    return false,err
  end
  return true

end

--------------------------------------------------------------------------------
-- open access to midi port 

function xRules:open_midi_input(port_name)
  TRACE("xRules:open_midi_input(port_name)",port_name)

  local input_devices = renoise.Midi.available_input_devices()
  if table.find(input_devices, port_name) then

    local port_available = (self.midi_inputs[port_name] ~= nil)
    local port_open = port_available and self.midi_inputs[port_name].is_open
    if port_available and port_open then
      -- don't create/open if already active
      return
    elseif port_available and not port_open then
      self.midi_inputs[port_name]:close()
    end

    self.midi_inputs[port_name] = renoise.Midi.create_input_device(port_name,
      function(midi_msg)
        if not xLib.is_song_available()
          or not self.active 
        then 
          return 
        end
        self:input_midi(midi_msg,port_name)
      end,
      function(sysex_msg)
        if not xLib.is_song_available()
          or not self.active 
        then 
          return 
        end
        self:input_sysex(sysex_msg,port_name)
      end
    )
  else
    LOG("*** Could not create MIDI input device " .. port_name)
  end

end


--------------------------------------------------------------------------------

function xRules:close_midi_input(port_name)
  TRACE("xRules:close_midi_input(port_name)",port_name)

  local midi_input = self.midi_inputs[port_name] 
  if (midi_input and midi_input.is_open) 
  then
    midi_input:close()
  end

  self.midi_inputs[port_name] = nil

end

--------------------------------------------------------------------------------

function xRules:open_midi_output(port_name)
  TRACE("xRules:open_midi_output(port_name)",port_name)

  local output_devices = renoise.Midi.available_output_devices()

  if table.find(output_devices, port_name) then
    self.midi_outputs[port_name] = renoise.Midi.create_output_device(port_name)
  else
    LOG("*** Could not create MIDI output device " .. port_name)
  end

end


--------------------------------------------------------------------------------

function xRules:close_midi_output(port_name)
  TRACE("xRules:close_midi_output(port_name)",port_name)

  local midi_output = self.midi_outputs[port_name] 
  if (midi_output and midi_output.is_open) 
  then
    midi_output:close()
  end

  self.midi_outputs[port_name] = nil

end

-------------------------------------------------------------------------------
-- add device, or replace existing with same name
-- @param device, xOscDevice (if not defined, create from scratch)
--  avoid triggering the 

function xRules:add_osc_device(device)
  TRACE("xRules:add_osc_device(device)",device)

  assert(type(device)=="xOscDevice","Expected xOscDevice as argument")

  device.callback = function(osc_msg)
    if not xLib.is_song_available()
      or not self.active 
    then 
      return 
    end
    self:input_osc(osc_msg,device)
  end

  local device_idx
  for k,v in ipairs(self.osc_devices) do
    if (v.name == device.name) then
      device_idx = k
      break
    end
  end

  if device_idx then
    local existing = self.osc_devices[device_idx]
    self.osc_devices[device_idx]:import(device:export())
  else
    self.osc_devices:insert(device)
    self.osc_devices_observable:insert(#self.osc_devices)
  end


end

-------------------------------------------------------------------------------
-- @param device_idx, integer

function xRules:remove_osc_device(device_idx)
  TRACE("xRules:remove_osc_device(device_idx)",device_idx)

  local device = self.osc_devices[device_idx]
  device:close()
  self.osc_devices:remove(device_idx)
  self.osc_devices_observable:remove(device_idx)

end

--------------------------------------------------------------------------------

function xRules:set_osc_device_property(device_name,key,value)
  TRACE("xRules:set_osc_device_property(device_name,key,value)",device_name,key,value)

  for k,v in ipairs(self.osc_devices) do
    if (v.name == device_name) then
      v[key] = value
    end
  end

end

-------------------------------------------------------------------------------

function xRules:get_unique_osc_device_name(str_name,count)
  TRACE("xRules:get_unique_osc_device_name(str_name,count)",str_name,count)

  local device_name_exists = function(str_name)
    for k,v in ipairs(self.osc_devices) do
      if (v.name == str_name) then
        return true
      end
    end
  end

  local count = 1
  local new_name = str_name
  while device_name_exists(new_name) do
    new_name = ("%s (%d)"):format(str_name,count)
    count = count+1
  end
  
  return new_name

end

-------------------------------------------------------------------------------
-- @return xRuleset,int(index) or nil

function xRules:get_ruleset_by_name(str_name)
  TRACE("xRules:get_ruleset_by_name(str_name)",str_name)

  for k,v in ipairs(self.rulesets) do
    if (v.name == str_name) then
      return v,k
    end
  end

end


