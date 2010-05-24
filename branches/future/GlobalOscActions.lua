--[[--------------------------------------------------------------------------
-- GlobalOscActions.lua

 DO NOT EDIT THIS FILE IN THE RENOISE RESOURCE FOLDER! UPDATING RENOISE WILL
 TRASH YOUR MODIFICATIONS!
 
 TO EXTEND THE DEFAULT OSC IMPLEMENTATION, COPY THIS FILE TO THE RENOISE 
 PREFERENCES FOLDER, THEN DO YOUR CHANGES THERE.

--------------------------------------------------------------------------]]--

--[[--------------------------------------------------------------------------

 This file defines Renoise default OSC message set. Beside of the ones you 
 find listed here, Renoise already processes some realtime critical messages 
 internally. Those will never be trigger here, and thus can also not be 
 overloaded by this script:
 
 
 ---- Realtime Messages
 
 -- TODO: list all
 /renoise/trigger/XXX

 
 ---- Message Format
 
 All other messages, received by Renoises global OSC server are handled 
 in this script. 
 
 message arguments are passes to the process function as a table (array) of:

 argument = {
   tag, -- (OSC type tag. See http://opensoundcontrol.org/spec-1_0)
   value -- (OSC value as lua type: nil, boolean, number or a string)
 }
 
 In this file the patterns are strings !without! the "/renoise" prefix. But 
 the prefix must be specified when sending something to Renoise. Some valid 
 message examples are:
 
 /renoise/transport/play (handled internally)
 /renoise/track[1]/volume f=1.0 (handled here)
 /renoise/window/activate_gui_preset i=1 (handled here)
 ...
 
 
 ---- Remote evaluation of Lua expressions via OSC
 
 With a special OSC message "/renoise/evaluate" you can evaluate Lua 
 expressions remotely, and thus do "anything" the Renoise Lua API offers 
 remotely. This way you don't need to edit this file here, in order
 to extend Renoises Osc implementation, but can completely do this in your 
 client.

 "/renoise/evaluate" expects exactly one argument, the to be evaluated 
 Lua expression, and will run the expression in a custom environment. This 
 custom environment is a sandbox which only allows access to some global 
 functions and the renoise.XXX modules. It can also not change anything 
 from this script. Please see below (evaluate_env) for the complete list of
 allowed funcitons and modules. 
 This is done to prevent that such custom expressions cause harm, because 
 in theory anyone/anthing could send messages to your opened OSC port.

]]


------------------------------------------------------------------------------
-- Message Registration
------------------------------------------------------------------------------

local message_map = table.create{}


-- create a message argument
-- name is only needed when generating a list of available messages for the user
-- type is the expected lua type name for the OSC argument

local function argument(name, type)
  return { name = name, type = type }
end


-- register a message with the given optional arguments and a handler function

local function add_message(message, arguments_or_handler, handler)
  assert(message_map[message] == nil, 
    "message is already registered")
  
  -- arguments + handler
  if (handler) then
    message_map[message] = { 
      handler = handler, 
      arguments = arguments_or_handler 
    }
  
  -- no arguments + handler
  else
    message_map[message] = { 
      handler = arguments_or_handler, 
      arguments = {}
    }
  end
  
end
 

------------------------------------------------------------------------------
-- Evaluate Environment
------------------------------------------------------------------------------

-- environment for expressions. may only access a few safe globals and modules
local evaluate_env = {
  _VERSION = _G._VERSION,
  
  math = table.rcopy(math),
  renoise = table.rcopy(renoise),
  string = table.rcopy(string),
  table = table.rcopy(table),
  
  assert = _G.assert,
  error = _G.error,
  ipairs = _G.ipairs,
  next = _G.next,
  pairs = _G.pairs,
  pcall = _G.pcall,
  print = _G.print,
  select = _G.select,
  tonumber = _G.tonumber,
  tostring = _G.tostring,
  type = _G.type,
  unpack = _G.unpack,
  xpcall = _G.xpcall
}

-- compile and evaluate an expression in the evaluate_env sandbox
local function evaluate(expression)
  local eval_function, message = loadstring(expression)
  
  if (not eval_function) then 
    -- failed to compile
    return nil, message 
  
  else
    -- run and return the result...
    setfenv(eval_function, evaluate_env)
    return pcall(eval_function)
  end
end


------------------------------------------------------------------------------
-- Message Helpers
------------------------------------------------------------------------------

-- clamp_value

local function clamp_value(value, min_value, max_value)
  return math.min(max_value, math.max(value, min_value))
end


------------------------------------------------------------------------------
-- Messages
------------------------------------------------------------------------------

-- evaluate

add_message("/evaluate", { argument("expression", "string") },  
  function(expression)
    print(("OSC Message: evaluating '%s'"):format(expression))

    local succeeded, error_message = evaluate(expression)
    if (not succeeded) then
      print(("*** expression failed: '%s'"):format(error_message))
    end
  end
)


-- transport

add_message("/transport/start", 
  function()
    local play_mode = renoise.Transport.PLAYMODE_RESTART_PATTERN
    renoise.song().transport:start(play_mode)
  end
)

add_message("/transport/stop", 
  function()
    renoise.song().transport:stop()
  end
)

add_message("/transport/bpm", { argument("bpm_value", "number") }, 
  function(bpm)
    renoise.song().transport.bpm = clamp_value(bpm, 32, 999)
  end
)

add_message("/transport/lpb", { argument("lpb_value", "number") }, 
  function(lpb)
    renoise.song().transport.lpb = clamp_value(bpm, 1, 255)
  end
)


------------------------------------------------------------------------------
-- Interface
------------------------------------------------------------------------------

-- available_messages

function available_messages()
  local ret = table.create {}

  for name, message in pairs(message_map) do
    ret:insert {
      name = name,
      arguments = message.arguments
    }
  end
    
  return ret
end


-- process_message

function process_message(pattern, arguments)
  local handled = false
  local message = message_map[pattern]
  
  -- find message, compare argument count
  if (message and #message.arguments == #arguments) then
    local arguments_match = true
    local argument_values = table.create{}
    
    -- check argument types
    for i = 1, #arguments do
      if (message.arguments[i].type == type(arguments[i].value)) then 
        argument_values:insert(arguments[i].value)
      else
        arguments_match = false
        break
      end
    end
    
    -- invoke the message
    if (arguments_match) then
      message.handler(unpack(argument_values))
      handled = true
    end
  end
    
  return handled
end

--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--
