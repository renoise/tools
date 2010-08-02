--[[============================================================================
Renoise Socket API Reference
============================================================================]]--

--[[

This reference describes the built-in OSC (Open Sound Control) support for 
Lua scripts in Renoise. OSC can be used in combination with sockets to 
send/receive Osc tagged data over process boundaries or exchange data 
across computers in a network (Internet).

Please have a look at http://opensoundcontrol.org for more general info 
about OSC

Please read the INTRODUCTION.txt first to get an overview about the complete
API, and scripting in Renoise in general...

Do not try to execute this file. It uses a .lua extension for markups only.


-------- Examples

-- for some small examples on how to use the OSC and the sockets API, have a
-- look at the code sippets in the "Snippets/Osc.lua" file please. 

]]


--==============================================================================
-- Osc
--==============================================================================

--------------------------------------------------------------------------------
-- renoise.Osc
--------------------------------------------------------------------------------

-- depackatizing raw (socket) data to OSC messages or bundles

-- converts the binary data to an OSC message or bundle. if the data does not 
-- look like an OSC message, or the message contains errors, nil is returned 
-- as first argument and the second return value will contain the error. 
-- if depackatizing was successfull, either a renoise.Osc.Bundle or Message 
-- object is returned. bundles may contain multiple messages or nested bundles.
renoise.Osc.from_binary_data(binary_data) 
  -> [Osc.Bundle or Osc.Message object or nil, error or nil]


--------------------------------------------------------------------------------
-- renoise.Osc.Message
--------------------------------------------------------------------------------

-------- create

-- create a new OSC message with the given pattern and optional arguments.
-- when arguments are specified, they must be specified as a table of 
-- {tag="X", value=SomeValue}'s. 
-- "tag" is the standard OSC type tag (see http://opensoundcontrol.org/spec-1_0)
-- all tags, except the 32 bit RGBA color tag are supported
-- "value" is the arguments value expressed by a Lua type. This value must 
-- be convertible to the specified tag, which means, you can for example 
-- not specify an "i" (integer) as type and pass a string as a value. Use a 
-- number value instead. Not all tags requre a value. the "value" field then
-- does not has to be specified.
renoise.Osc.Message(pattern [, table of {tag, value} arguments])


-------- properties

-- the message pattern (e.g. "/renoise/transport/start")
message.pattern 
  -> [read-only, string]

-- table of {tag="X", value=SomeValue}'s that represent the message arguments.
-- see renoise.Osc.Message->create for more info
message.arguments 
  -> [read-only, table of {tag, value} tables]
  
-- raw binary representation of the messsage, as needed when sending the 
-- message over the network through sockets
message.binary_data 
  -> [read-only, raw string]


--------------------------------------------------------------------------------
-- renoise.Socket.Bundle
--------------------------------------------------------------------------------

-------- create

-- create a new bundle by specifying a timetag and one or more messages.
-- if you don't know what to do with the timetag, simply use os.clock() 
-- which means "now". messages have to be renoise.Osc.Message objects. Nested
-- bundles (bundles with bundles) are right now not supported.
renoise.Osc.Message(pattern, single_message_or_table_of_messages)


-------- properties

-- time value of the bundle
bundle.timetag
  -> [read-only, number]
  
-- access to the bundles elements (messages or again tables)
bundle.elements
  -> [read-only, table of renoise.Osc.Message or renoise.Osc.Bundle objects]
  
-- raw binary representation of the bundle, as needed when sending the 
-- message over the network through sockets
bundle.binary_data 
  -> [read-only, raw string]


