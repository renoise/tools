--[[============================================================================
xRule
============================================================================]]--

--[[--

This class defines logic rewriting MIDI messages, plus a sandbox environment 
.
#

A rule contains two main elements: 
  conditions - criteria that the message has to match
  actions - actions to take when message got matched

]]

require (_clibroot.."cSandbox")
require (_xlibroot.."xRules")

class 'xRule'

xRule.ASPECT = {
  SYSEX = "sysex",
  PORT_NAME = "port_name",
  DEVICE_NAME = "device_name",
  CHANNEL = "channel",
  TRACK_INDEX = "track_index",
  INSTRUMENT_INDEX = "instrument_index",
  MESSAGE_TYPE = "message_type",
  VALUE_1 = "value_1",
  VALUE_2 = "value_2",
  VALUE_3 = "value_3",
  VALUE_4 = "value_4",
  VALUE_5 = "value_5",
  VALUE_6 = "value_6",
  VALUE_7 = "value_7",
  VALUE_8 = "value_8",
  VALUE_9 = "value_9",
  --TRACK_NAME = "track_name",
  --INSTRUMENT_NAME = "instrument_name",
}

xRule.VALUES = {
  "value_1",
  "value_2",
  "value_3",
  "value_4",
  "value_5",
  "value_6",
  "value_7",
  "value_8",
  "value_9",
}

xRule.ASPECT_DEFAULTS = {
  SYSEX = "F0 * F7",
  DEVICE_NAME = {}, -- list of OSC devices
  PORT_NAME = {}, -- renoise.Midi.available_input_devices()
  CHANNEL = {},
  TRACK_INDEX = {},
  INSTRUMENT_INDEX = {},
  MESSAGE_TYPE = cLib.stringify_table(xMidiMessage.TYPE),
  VALUE_1 = 1,
  VALUE_2 = 1,
  VALUE_3 = 1,
  VALUE_4 = 1,
  VALUE_5 = 1,
  VALUE_6 = 1,
  VALUE_7 = 1,
  VALUE_8 = 1,
  VALUE_9 = 1,
}


for i = 1,16 do
  table.insert(xRule.ASPECT_DEFAULTS.CHANNEL,i)
end

for i = 1,128 do
  table.insert(xRule.ASPECT_DEFAULTS.TRACK_INDEX,i)
  table.insert(xRule.ASPECT_DEFAULTS.INSTRUMENT_INDEX,i)
end

-- provide the expected value type for aspects
-- (assume integer when not listed)
xRule.ASPECT_BASETYPE = {
  SYSEX = "string",
  PORT_NAME = "string",
  DEVICE_NAME = "string",
  MESSAGE_TYPE = "string",
}

-- list aspects restricted to TYPE_OPERATORS
xRule.ASPECT_TYPE_OPERATORS = {
  xRule.ASPECT.SYSEX,
  xRule.ASPECT.PORT_NAME,
  xRule.ASPECT.DEVICE_NAME,
  xRule.ASPECT.MESSAGE_TYPE,
}

xRule.LOGIC = {
  AND = 1,
  OR = 2,
}

xRule.OPERATOR = {
  BETWEEN = "between",
  EQUAL_TO = "equal_to",
  NOT_EQUAL_TO = "not_equal_to",
  LESS_THAN = "less_than",
  LESS_THAN_OR_EQUAL_TO = "less_than_or_equal_to",
  GREATER_THAN = "greater_than",
  GREATER_THAN_OR_EQUAL_TO = "greater_than_or_equal_to",
}

-- applies to xMidiMessage.TYPE, 
xRule.TYPE_OPERATORS = {
  xRule.OPERATOR.EQUAL_TO,
  xRule.OPERATOR.NOT_EQUAL_TO,
}

-- applies to all others
xRule.VALUE_OPERATORS = {
  xRule.OPERATOR.EQUAL_TO,
  xRule.OPERATOR.NOT_EQUAL_TO,
  xRule.OPERATOR.LESS_THAN,
  xRule.OPERATOR.LESS_THAN_OR_EQUAL_TO,
  xRule.OPERATOR.GREATER_THAN,
  xRule.OPERATOR.GREATER_THAN_OR_EQUAL_TO,
  xRule.OPERATOR.BETWEEN,
}

-- this is the reduced list shown in the user-interface
xRule.ACTIONS = {
  CALL_FUNCTION = "call_function",
  OUTPUT_MESSAGE = "output_message",  
  ROUTE_MESSAGE = "route_message",  
  SET_CHANNEL = "set_channel",
  SET_INSTRUMENT = "set_instrument",
  SET_MESSAGE_TYPE = "set_message_type",
  SET_PORT_NAME = "set_port_name",
  SET_DEVICE_NAME = "set_device_name",
  SET_TRACK = "set_track",
  --SET_SYSEX = "set_sysex",
  SET_VALUE = "set_value",
  INCREASE_INSTRUMENT = "increase_instrument",
  INCREASE_TRACK = "increase_track",
  INCREASE_CHANNEL = "increase_channel",
  INCREASE_VALUE = "increase_value", 
  DECREASE_INSTRUMENT = "decrease_instrument",
  DECREASE_TRACK = "decrease_track",
  DECREASE_CHANNEL = "decrease_channel",
  DECREASE_VALUE = "decrease_value", 
}

-- this is the full list with all possible values
-- TODO deprecate! 
xRule.ACTIONS_FULL = {
  CALL_FUNCTION = xRule.ACTIONS.CALL_FUNCTION,
  OUTPUT_MESSAGE = xRule.ACTIONS.OUTPUT_MESSAGE,  
  ROUTE_MESSAGE = xRule.ACTIONS.ROUTE_MESSAGE,  
  SET_CHANNEL = xRule.ACTIONS.SET_CHANNEL,
  SET_INSTRUMENT = xRule.ACTIONS.SET_INSTRUMENT,
  SET_PORT_NAME = xRule.ACTIONS.SET_PORT_NAME,
  SET_DEVICE_NAME = xRule.ACTIONS.SET_DEVICE_NAME,
  SET_TRACK = xRule.ACTIONS.SET_TRACK,
  SET_MESSAGE_TYPE = xRule.ACTIONS.SET_MESSAGE_TYPE,
  SET_VALUE_1 = "set_value_1",
  SET_VALUE_2 = "set_value_2",
  SET_VALUE_3 = "set_value_3",
  SET_VALUE_4 = "set_value_4",
  SET_VALUE_5 = "set_value_5",
  SET_VALUE_6 = "set_value_6",
  SET_VALUE_7 = "set_value_7",
  SET_VALUE_8 = "set_value_8",
  SET_VALUE_9 = "set_value_9",
  INCREASE_INSTRUMENT = xRule.ACTIONS.INCREASE_INSTRUMENT,
  INCREASE_TRACK = xRule.ACTIONS.INCREASE_TRACK,
  INCREASE_CHANNEL = xRule.ACTIONS.INCREASE_CHANNEL,
  INCREASE_VALUE_1 = "increase_value_1", 
  INCREASE_VALUE_2 = "increase_value_2", 
  INCREASE_VALUE_3 = "increase_value_3", 
  INCREASE_VALUE_4 = "increase_value_4", 
  INCREASE_VALUE_5 = "increase_value_5", 
  INCREASE_VALUE_6 = "increase_value_6", 
  INCREASE_VALUE_7 = "increase_value_7", 
  INCREASE_VALUE_8 = "increase_value_8", 
  INCREASE_VALUE_9 = "increase_value_9", 
  DECREASE_INSTRUMENT = xRule.ACTIONS.DECREASE_INSTRUMENT,
  DECREASE_TRACK = xRule.ACTIONS.DECREASE_TRACK,
  DECREASE_CHANNEL = xRule.ACTIONS.DECREASE_CHANNEL,
  DECREASE_VALUE_1 = "decrease_value_1", 
  DECREASE_VALUE_2 = "decrease_value_2", 
  DECREASE_VALUE_3 = "decrease_value_3", 
  DECREASE_VALUE_4 = "decrease_value_4", 
  DECREASE_VALUE_5 = "decrease_value_5", 
  DECREASE_VALUE_6 = "decrease_value_6", 
  DECREASE_VALUE_7 = "decrease_value_7", 
  DECREASE_VALUE_8 = "decrease_value_8", 
  DECREASE_VALUE_9 = "decrease_value_9", 
}

-- when a given action is relating to an aspect
-- (used for providing sensible defaults)
xRule.ACTIONS_TO_ASPECT_MAP = {
  SET_INSTRUMENT = xRule.ASPECT.INSTRUMENT_INDEX,
  SET_TRACK = xRule.ASPECT.TRACK_INDEX,
  SET_CHANNEL = xRule.ASPECT.CHANNEL,
  SET_VALUE_1 = xRule.ASPECT.VALUE_1,
  SET_VALUE_2 = xRule.ASPECT.VALUE_2,
  SET_VALUE_3 = xRule.ASPECT.VALUE_3,
  SET_VALUE_4 = xRule.ASPECT.VALUE_4,
  SET_VALUE_5 = xRule.ASPECT.VALUE_5,
  SET_VALUE_6 = xRule.ASPECT.VALUE_6,
  SET_VALUE_7 = xRule.ASPECT.VALUE_7,
  SET_VALUE_8 = xRule.ASPECT.VALUE_8,
  SET_VALUE_9 = xRule.ASPECT.VALUE_9,
  INCREASE_INSTRUMENT = xRule.ASPECT.INSTRUMENT_INDEX,
  INCREASE_TRACK = xRule.ASPECT.TRACK_INDEX,
  INCREASE_CHANNEL = xRule.ASPECT.CHANNEL,
  INCREASE_VALUE_1 = xRule.ASPECT.VALUE_1,
  INCREASE_VALUE_2 = xRule.ASPECT.VALUE_2,
  INCREASE_VALUE_3 = xRule.ASPECT.VALUE_3,
  INCREASE_VALUE_4 = xRule.ASPECT.VALUE_4,
  INCREASE_VALUE_5 = xRule.ASPECT.VALUE_5,
  INCREASE_VALUE_6 = xRule.ASPECT.VALUE_6,
  INCREASE_VALUE_7 = xRule.ASPECT.VALUE_7,
  INCREASE_VALUE_8 = xRule.ASPECT.VALUE_8,
  INCREASE_VALUE_9 = xRule.ASPECT.VALUE_9,
  DECREASE_INSTRUMENT = xRule.ASPECT.INSTRUMENT_INDEX,
  DECREASE_TRACK = xRule.ASPECT.TRACK_INDEX,
  DECREASE_CHANNEL = xRule.ASPECT.CHANNEL,
  DECREASE_VALUE_1 = xRule.ASPECT.VALUE_1,
  DECREASE_VALUE_2 = xRule.ASPECT.VALUE_2,
  DECREASE_VALUE_3 = xRule.ASPECT.VALUE_3,
  DECREASE_VALUE_4 = xRule.ASPECT.VALUE_4,
  DECREASE_VALUE_5 = xRule.ASPECT.VALUE_5,
  DECREASE_VALUE_6 = xRule.ASPECT.VALUE_6,
  DECREASE_VALUE_7 = xRule.ASPECT.VALUE_7,
  DECREASE_VALUE_8 = xRule.ASPECT.VALUE_8,
  DECREASE_VALUE_9 = xRule.ASPECT.VALUE_9,
}

-- provide the expected value type for actions
-- (assume integer when not listed)
xRule.ACTION_BASETYPE = {
  CALL_FUNCTION = "string",
  OUTPUT_MESSAGE = "string",
  ROUTE_MESSAGE = "string",
  SEND_MESSAGE = "string",
}



-------------------------------------------------------------------------------

function xRule:__init(def)

  if not def then
    def = {}
  end
  
  -- cast certain members to type
  --def.name = cReflection.cast_value(def.name,"string")
  --def.match_any = cReflection.cast_value(def.match_any,"boolean")
  --def.midi_enabled = cReflection.cast_value(def.midi_enabled,"boolean")

  -- public -----------------------

  --- table, indexed
  --[[
    {xRule.ASPECT = {
      xRule.OPERATOR.EQUAL_TO = [some_value],
      xRule.OPERATOR.GREATER_THAN = [some_value],
    }},
    -- these can (optionally) be separated by xRule.LOGIC statements
    {xRule.LOGIC.OR},
    {...and so on...}
  ]]
  self.conditions = def.conditions or {}

  --- table, indexed
  self.actions = def.actions or {}

  --- xOscPattern - see initialize()
  self.osc_pattern = nil

  --- string
  self.name = property(self.get_name,self.set_name)
  self.name_observable = renoise.Document.ObservableString(def.name or "")

  --- boolean, when true, we match *any* incoming message 
  -- (applied when the rule contains no conditions)
  self.match_any = property(self.get_match_any,self.set_match_any)
  self.match_any_observable = renoise.Document.ObservableBoolean(
    (type(def.match_any) ~= "boolean") and true or def.match_any)

  --- boolean, if set to false we ignore midi messages
  self.midi_enabled = property(self.get_midi_enabled,self.set_midi_enabled)
  self.midi_enabled_observable = renoise.Document.ObservableBoolean(
    (type(def.midi_enabled) ~= "boolean") and true or def.midi_enabled)

  --- xMessage, or implementation thereof
  self.last_received_message = nil


  --- easy access to values in last message (might be nil)
  self.values = property(self.get_values)

  -- internal --

  --- tracking the generated function to detect changes
  self.modified_observable = renoise.Document.ObservableBang()

  --- cSandbox
  self.sandbox = nil

  --== initialize ==--

  -- osc pattern 

  if def.osc_pattern then
    self.osc_pattern = xOscPattern{
      pattern_in = def.osc_pattern.pattern_in,
      pattern_out = def.osc_pattern.pattern_out,
    }
  else
    self.osc_pattern = xOscPattern()
  end

  self.osc_pattern.pattern_in_observable:add_notifier(function()
    self.modified_observable:bang()
  end)
  self.osc_pattern.pattern_out_observable:add_notifier(function()
    self.modified_observable:bang()
  end)

  --- configure sandbox:
  --  add basic variables and a few utility methods
  --  (be very careful that all code can access used classes and methods)

  self.sandbox = cSandbox()
  self.sandbox.compile_at_once = true
  self.sandbox.str_prefix = [[
    __xmsg = select(1, ...)
    __xrules = select(2, ...)
    __xruleset_index = select(3, ...)

    ---------------------------------------------------------------------------
    -- comparing numbers with variable precision
    -- @param val1 (number)
    -- @param val2 (number)
    -- @param operator (xRule.OPERATOR)
    -- @param precision (number), optional precision factor
    local compare_numbers = function(val1,val2,operator,precision)
      local is_equal = precision and cLib.float_compare(val1,val2,precision) 
        or val1 == val2
      local operators_table = {
        ["equal_to"] = function()
          return is_equal
        end,
        ["not_equal_to"] = function()
          return not is_equal
        end,
        ["less_than"] = function()
          return not is_equal and (val1 < val2)
        end,
        ["less_than_or_equal_to"] = function()
          return is_equal or (val1 < val2)
        end,
        ["greater_than"] = function()
          return not is_equal and (val1 > val2)
        end,
        ["greater_than_or_equal_to"] = function()
          return is_equal or (val1 > val2)
        end,
      }
      if not operators_table[operator] then
        error("Could not find operator")
      else
        return operators_table[operator]()
      end
    end

    ---------------------------------------------------------------------------
    -- add/clone message into the output queue
    -- @param val (string), one of xRules.OUTPUT_OPTIONS
    local output_message = function(val)

      local xmsg_out
      local xmsg_type = type(__xmsg)

      if not (xmsg_type=='xMidiMessage') 
        and not (xmsg_type=='xOscMessage')
      then
        error("Expected implementation of xMessage")
      end

      local def = __xmsg.__def
      if (val == xRules.OUTPUT_OPTIONS.EXTERNAL_OSC)
        and (type(__xmsg)=='xMidiMessage') 
      then 
        -- convert from MIDI -> OSC
        def.pattern = __xrule.osc_pattern
        def.device_name = __xmsg.device_name
        xmsg_out = xOscMessage(def)

      elseif (type(__xmsg)=='xOscMessage') 
        and ((val == xRules.OUTPUT_OPTIONS.EXTERNAL_MIDI)
        or (val == xRules.OUTPUT_OPTIONS.INTERNAL_RAW))
      then 
        -- convert from OSC -> MIDI
        def.message_type = __xmsg.message_type
        def.channel = __xmsg.channel
        def.bit_depth = __xmsg.bit_depth
        def.port_name = __xmsg.port_name
        xmsg_out = xMidiMessage(def)

      else -- internal can be both
        if (type(__xmsg)=='xOscMessage') then
          xmsg_out = xOscMessage(def)
        elseif (type(__xmsg)=='xMidiMessage') then
          xmsg_out = xMidiMessage(def)
        end
      end

      table.insert(__output,{
        target = val,
        xmsg = xmsg_out
      })

    end

    ---------------------------------------------------------------------------
    -- pass message on to a different rule/set
    -- @param val (string), "ruleset_name:rule_name"
    local route_message = function(val)
      local routing_values = cString.split(val,":")
      local rule,ruleset,rule_idx,ruleset_idx
      if (routing_values[1] == xRuleset.CURRENT_RULESET) then
        ruleset = __xrules.rulesets[__xruleset_index]
        ruleset_idx = __xruleset_index
      else
        ruleset,ruleset_idx = __xrules:get_ruleset_by_name(routing_values[1])
      end
      if ruleset then
        rule,rule_idx = ruleset:get_rule_by_name(routing_values[2])
        --ruleset,ruleset_idx = __xrules:get_ruleset_by_name(routing_values[1])
      else
      end
      if ruleset and rule then
        __xrules:match_message(__xmsg,ruleset_idx,rule_idx,true)
      end
    end

    ---------------------------------------------------------------------------
    -- (alias for xAutomation:record)
    local record_automation = function(track_idx,param,value,value_mode)
      __xrules.automation:record(track_idx,param,value,value_mode)
    end

    ---------------------------------------------------------------------------
    -- (alias for xAutomation:has_automation)
    local has_automation = function(track_idx,param)
      return __xrules.automation:has_automation(track_idx,param)
    end

    ---------------------------------------------------------------------------
    -- generated code...

  ]]
  self.sandbox.str_suffix = [[
    return __output,__evaluated
  ]]

  local props_table = {

    -- Global

    ["rns"] = {
      access = function(env) return rns end,
    },
    ["renoise"] = {
      access = function(env) return renoise end,
    },
    ["__xrule"] = {
      access = function(env) return self end,
    },
    ["rules"] = {
      access = function(env)         
        local ruleset = env.__xrules.rulesets[env.__xruleset_index]
        return ruleset.rules
      end,
    },

    -- Static class access 
    ["cLib"] = {
      access = function(env) return cLib end,
    },
    ["cString"] = {
      access = function(env) return cString end,
    },
    ["xLib"] = {
      access = function(env) return xLib end,
    },
    ["xRules"] = {
      access = function(env) return xRules end,
    },
    ["xRuleset"] = {
      access = function(env) return xRuleset end,
    },
    ["xTrack"] = {
      access = function(env) return xTrack end,
    },
    ["xTransport"] = {
      access = function(env) return xTransport end,
    },
    ["xScale"] = {
      access = function(env) return xScale end,
    },
    ["xMidiMessage"] = {
      access = function(env) return xMidiMessage end,
    },
    ["xOscMessage"] = {
      access = function(env) return xOscMessage end,
    },
    ["xAutomation"] = {
      access = function(env) return xAutomation end,
    },
    ["xParameter"] = {
      access = function(env) return xParameter end,
    },
    ["xPlayPos"] = {
      access = function(env) return xPlayPos end,
    },
    ["xAudioDevice"] = {
      access = function(env) return xAudioDevice end,
    },
    ["xPhraseManager"] = {
      access = function(env) return xAudioDevice end,
    },

    -- xMessage 

    ["track_index"] = {
      access = function(env) return env.__xmsg.track_index end,
      assign = function(env,v) env.__xmsg.track_index = v end,
    },
    ["instrument_index"]  = {
      access = function(env) return env.__xmsg.instrument_index end,
      assign = function(env,v) env.__xmsg.instrument_index = v end,
    },
    ["values"]  = {
      access = function(env) return env.__xmsg.values end,
      assign = function(env,v) env.__xmsg.values = v end,
    },

    -- xMidiMessage

    ["message_type"]  = {
      access = function(env) return env.__xmsg.message_type end,
      assign = function(env,v) env.__xmsg.message_type = v end,
    },
    ["channel"]  = {
      access = function(env) return env.__xmsg.channel end,
      assign = function(env,v) env.__xmsg.channel = v end,
    },
    ["bit_depth"]  = {
      access = function(env) return env.__xmsg.bit_depth end,
      assign = function(env,v) env.__xmsg.bit_depth = v end,
    },
    ["port_name"]  = {
      access = function(env) return env.__xmsg.port_name end,
      assign = function(env,v) env.__xmsg.port_name = v end,
    },

    -- xOscMessage

    ["device_name"]  = {
      access = function(env) return env.__xmsg.device_name end,
      assign = function(env,v) env.__xmsg.device_name = v end,
    },
  }

  for k = 1,#xRule.VALUES do
    props_table[("value_%x"):format(k)]  = {
      access = function(env) return env.__xmsg.values[k] end,
      assign = function(env,v) env.__xmsg.values[k] = v end,
    }
  end

  self.sandbox.properties = props_table
  self.sandbox.modified_observable:add_notifier(function()
    self.modified_observable:bang()
  end)

  local success,err = self:compile()
  if err then
    LOG(err)
  end

end

--==============================================================================
-- Getters/Setters 
--==============================================================================

function xRule:get_name()
  return self.name_observable.value
end

function xRule:set_name(val)
  assert(type(val)=="string","Expected name to be a string")
  val = val:gsub(":","") -- colons not allowed (used to indicate routings)
  local modified = (val ~= self.name_observable.value) and true or false
  self.name_observable.value = val
  if modified then
    self.modified_observable:bang()
  end
end

-------------------------------------------------------------------------------

function xRule:get_midi_enabled()
  return self.midi_enabled_observable.value
end

function xRule:set_midi_enabled(val)
  assert(type(val)=="boolean","Expected midi_enabled to be a boolean")
  local modified = (val ~= self.midi_enabled) and true or false
  self.midi_enabled_observable.value = val
  if modified then
    self.modified_observable:bang()
  end
end

-------------------------------------------------------------------------------

function xRule:get_values()
  --TRACE("xRule:get_values()")
  if self.last_received_message then
    return self.last_received_message.values
  end
end

-------------------------------------------------------------------------------

function xRule:get_match_any()
  return self.match_any_observable.value
end

function xRule:set_match_any(val)
  assert(type(val)=="boolean","Expected match_any to be a boolean")
  local modified = (val ~= self.match_any) and true or false
  self.match_any_observable.value = val
  if modified then
    local passed,err = self:compile()
    if err then
      LOG(err)
    end
    self.modified_observable:bang()

  end
end

--==============================================================================
-- Class Methods
--==============================================================================

-- return a table representation of the rule
-- @return table

function xRule:serialize()

  local t = {
    ["name"] = self.name,
    ["match_any"] = self.match_any,
    ["midi_enabled"] = self.midi_enabled,
    ["conditions"] = self.conditions,
    ["actions"] = self.actions,
    ["osc_pattern"] = {
      pattern_in = self.osc_pattern.pattern_in,
      pattern_out = self.osc_pattern.pattern_out,
    },
  }
  local max_depth,longstring = nil,true
  return cLib.serialize_table(t,max_depth,longstring)

end

-------------------------------------------------------------------------------
-- @param xmsg (xMessage or implementation thereof)
-- @param xrules (xRules) owner
-- @param ruleset_idx (int)
-- @return table<xMessage>

function xRule:match(xmsg,xrules,ruleset_idx)

  if not self.sandbox.callback then
    LOG("*** no sandbox callback, aborting..." )
    return {}
  end

  -- remember the last message to be matched, 
  -- make it inspectable by other rules
  self.last_received_message = xmsg

  -- prepare environment
  self.sandbox.env.__xmsg = {}
  self.sandbox.env.__output = {}
  self.sandbox.env.__evaluated = false

  local xmsgs,evaluated
  local success,err = pcall(function()
    xmsgs,evaluated = self.sandbox.callback(xmsg,xrules,ruleset_idx)
  end)
  if not success and err then
    LOG("*** ERROR: please review the callback function - "..err)
    LOG("*** ",self.sandbox.callback_str)
    return {}
  else
    return xmsgs,evaluated
  end

end

--------------------------------------------------------------------------------
-- go through conditions and fix 'stuff' 
-- * logic statements preceding conditions
-- * consecutive logic statements

function xRule:fix_conditions()

  local last_was_logic = false
  local yet_to_encounter_first_row = true
  local done = false
  local count = 1

  while not done do
    local v = self.conditions[count]
    -- figure out the logic used in this row
    if (#v == 1) then
      -- encountered logic
      if (not table.find(xRule.LOGIC,v[1])) then
        error("Unknown logic statement")
      end
      if yet_to_encounter_first_row then
        LOG("*** xRule: first entry can't be a logic statement (remove)")
        table.remove(self.conditions,count)
        count = count-1
      else
        count = count+1
        last_was_logic = true
      end
      if last_was_logic then
        -- eat up consecutive logic statements
        local removed = false
        while self.conditions[count] and (#self.conditions[count] == 1) do
          LOG("*** xRule: consecutive logic statements are not allowed (remove)")
          table.remove(self.conditions,count)
          removed = true
        end
        if removed then
          count = count-1            
        end
        v = self.conditions[count]
      end
    else
      last_was_logic = false
    end
    if (#v == 0) then
      yet_to_encounter_first_row = false
    end
    if not self.conditions[count+1] then
      done = true
    else
      count = count+1
    end
  end

end

-------------------------------------------------------------------------------
--- turn the rule into an executable lua statement
-- @return boolean, true when succeeded
-- @return string, error message

function xRule:compile()

  if (#self.conditions == 0) 
    and not self.match_any
  then
    self.sandbox.callback = nil
    return false,"Can't compile - no conditions were defined"
  end

  local build_sysex_condition = function(k,v)

    local t = cString.split(v," ")

    local str_fn = ""
    local last_was_wildcard = false
    for k,v in ipairs(t) do
      if (k > 1) and not last_was_wildcard then
        str_fn = str_fn .. "and "
      end
      -- skip wildcards 
      if (v ~= "*") then
        str_fn = str_fn .. "(values["..k.."] == 0x"..v..") "
        last_was_wildcard = false
      else
        last_was_wildcard = true
      end
    end
    str_fn = str_fn .. " \n"

    return str_fn

  end

  -- @param k, key (e.g. 'value_1')
  -- @param v, table (e.g. [equal_to] =>  440.4)
  local build_comparison = function(k,v)

    local str_fn = ""
    local count = 0
    for k2,v2 in pairs(v) do

      if (count > 0) then
        str_fn = str_fn .. "and "
      end

      local val = v2
      local precision = nil

      -- 'between' operator has a table with two values
      if (k2 == xRule.OPERATOR.BETWEEN) then
        if (type(val)~="table") then
          val = {val,val}
        end
      else
        if (type(val)=="table") then
          val = val[1]
        end
        -- wrap strings in quotes
        -- (except sysex, which is interpreted seperately)
        if (k ~= xMidiMessage.TYPE.SYSEX) then
          if (type(val)=="string") then
            val = "'"..val.."'"
          elseif (type(val)=="number") then
            -- always use variable-precision matching when osc-enabled
            -- (MIDI is always integer, but OSC can be floating point)
            if self.osc_pattern.complete then
              precision = self.osc_pattern.precision
            end
          end
        end
      end

      precision = tostring(precision)

      if (k == xMidiMessage.TYPE.SYSEX) then
        str_fn = str_fn .. build_sysex_condition(k,val)
      elseif (type(val)=="string") then
        if (k2 == xRule.OPERATOR.EQUAL_TO) then
          str_fn = str_fn .. "("..k.." == "..val..") \n"
        else
          str_fn = str_fn .. "("..k.." ~= "..val..") \n"
        end
      elseif (k2 == xRule.OPERATOR.BETWEEN) then
        str_fn = str_fn 
          .. "("
          .. "compare_numbers("..k..","..val[1]..",'"..xRule.OPERATOR.GREATER_THAN_OR_EQUAL_TO.."',"..precision..") and "
          .. "compare_numbers("..k..","..val[2]..",'"..xRule.OPERATOR.LESS_THAN_OR_EQUAL_TO.."',"..precision..")  "
          .. ") \n"
      else
        -- TODO confirm that k2 is found in xRule.OPERATOR
        --error("Unknown operator")
        str_fn = str_fn .. "(compare_numbers("..k..","..val..",'"..k2.."',"..precision..")) \n"

      end
      count = count+1
    end
    return str_fn
  end

  --== conditions ==--

  local str_fn = "if "

  if (#self.conditions == 0) and self.match_any then
    str_fn = str_fn .. "(true) "
  else
    local count = 0
    local last_was_logic = false
    for k,v in ipairs(self.conditions) do
      if (#v == 1) then
        -- logic statement
        if (v[1] == xRule.LOGIC.AND) then
          str_fn = str_fn .. "and "
        elseif (v[1] == xRule.LOGIC.OR) then
          str_fn = str_fn .. "or "
        else
          error("Unknown logic statement")
        end
        last_was_logic = true
      else
        -- insert 'and' statement when not at the first entry,
        -- and not immediately following another logic statement
        if not last_was_logic and (count > 0) then
          str_fn = str_fn .. "and "
        end
        for k2,v2 in pairs(v) do
          -- comparison
          str_fn = str_fn .. build_comparison(k2,v2)
        end
        last_was_logic = false
      end
      count = count+1
    end
  end

  --== actions ==--

  str_fn = str_fn .. "then \n"
  str_fn = str_fn .. "__evaluated = true \n"
  for k,v in ipairs(self.actions) do
    for k2,v2 in pairs(v) do
      if (k2 == xRule.ACTIONS.OUTPUT_MESSAGE) then
        str_fn = str_fn .. string.format("output_message('%s') \n",v2)
      elseif (k2 == xRule.ACTIONS.ROUTE_MESSAGE) then
        str_fn = str_fn .. string.format("route_message('%s') \n",v2)
      elseif (k2 == xRule.ACTIONS.SET_INSTRUMENT) then
        str_fn = str_fn .. string.format("instrument = %d \n",v2)
      elseif (k2 == xRule.ACTIONS.SET_TRACK) then
        str_fn = str_fn .. string.format("track = %d \n",v2)
      elseif (k2 == xRule.ACTIONS.SET_PORT_NAME) then
        str_fn = str_fn .. string.format("port_name = '%s' \n",v2)
      elseif (k2 == xRule.ACTIONS.SET_DEVICE_NAME) then
        str_fn = str_fn .. string.format("device_name = '%s' \n",v2)
      elseif (k2 == xRule.ACTIONS.SET_CHANNEL) then
        str_fn = str_fn .. string.format("channel = %d \n",v2)
      elseif (k2 == xRule.ACTIONS.SET_MESSAGE_TYPE) then
        str_fn = str_fn .. string.format("message_type = '%s' \n",v2)
      elseif (string.find(k2,"set_value_",nil,true)) then
        local value_idx = xRule.get_value_index(k2)
        if (type(v2) == "string") then
          str_fn = str_fn .. string.format("values[%d] = '%s' \n",value_idx,v2)
        else
          str_fn = str_fn .. string.format("values[%d] = %d \n",value_idx,v2)
        end
      elseif (k2 == xRule.ACTIONS.INCREASE_INSTRUMENT) then
        str_fn = str_fn .. string.format("instrument = instrument + %d \n",v2)
      elseif (k2 == xRule.ACTIONS.INCREASE_TRACK) then
        str_fn = str_fn .. string.format("track = track + %d \n",v2)
      elseif (k2 == xRule.ACTIONS.INCREASE_CHANNEL) then
        str_fn = str_fn .. string.format("channel = channel + %d \n",v2)
      elseif (string.find(k2,"increase_value_",nil,true)) then
        local value_idx = xRule.get_value_index(k2)
        str_fn = str_fn .. string.format("values[%d] = values[%d] + %d \n",value_idx,value_idx,v2)
      elseif (k2 == xRule.ACTIONS.DECREASE_INSTRUMENT) then
        str_fn = str_fn .. string.format("instrument = instrument - %d \n",v2)
      elseif (k2 == xRule.ACTIONS.DECREASE_TRACK) then
        str_fn = str_fn .. string.format("track = track - %d \n",v2)
      elseif (k2 == xRule.ACTIONS.DECREASE_CHANNEL) then
        str_fn = str_fn .. string.format("channel = channel - %d \n",v2)
      elseif (string.find(k2,"decrease_value_",nil,true)) then
        local value_idx = xRule.get_value_index(k2)
        str_fn = str_fn .. string.format("values[%d] = values[%d] - %d \n",value_idx,value_idx,v2)
      elseif (k2 == xRule.ACTIONS.CALL_FUNCTION) then
        str_fn = str_fn .. string.format("%s \n",v2)
      else
        error("Unknown action")
      end
    end
  end
  str_fn = str_fn .. "end \n"

  local passed,err = self.sandbox:test_syntax(str_fn) 
  if passed then
    self.sandbox.callback_str = str_fn
  else
    return false,"Invalid syntax when checking rule:"..err
  end

end

--==============================================================================
-- Static methods
--==============================================================================

-- extract hexadecimal value from end of string, e.g. "set_value_e" --> 14
-- @param str (string)
-- @return number or nil

function xRule.get_value_index(str)
  local match = string.match(str,"_(.)$")
  if match then
    return tonumber(("0x%s"):format(match))
  end
end

