--[[============================================================================
Renoise OSC API Reference
============================================================================]]--

--[[

This reference describes the built-in OSC (Open Sound Control) support for
Lua scripts in Renoise. OSC can be used in combination with sockets to
send/receive OSC tagged data over process boundaries or to exchange data
across computers in a network (Internet).

Please have a look at <http://opensoundcontrol.org> for more general info
about OSC

Please read the INTRODUCTION.txt first to get an overview about the complete
API, and scripting in Renoise in general...

Do not try to execute this file. It uses a .lua extension for markups only.


-------- Examples

-- For some small examples on how to use the OSC and sockets API, have a
-- look at the code snippets in the "Snippets/Osc.lua" file please.

]]


--==============================================================================
-- Osc
--==============================================================================

--------------------------------------------------------------------------------
-- renoise.Osc
--------------------------------------------------------------------------------

-- De-packetizing raw (socket) data to OSC messages or bundles
-- converts the binary data to an OSC message or bundle. If the data does not
-- look like an OSC message, or the message contains errors, nil is returned
-- as first argument and the second return value will contain the error.
-- If de-packetizing was successful, either a renoise.Osc.Bundle or Message
-- object is returned. Bundles may contain multiple messages or nested bundles.
renoise.Osc.from_binary_data(binary_data)
  -> [Osc.Bundle or Osc.Message object or nil, error or nil]


--------------------------------------------------------------------------------
-- renoise.Osc.Message
--------------------------------------------------------------------------------

-------- create

-- Create a new OSC message with the given pattern and optional arguments.
-- When arguments are specified, they must be specified as a table of
-- {tag="X", value=SomeValue}'s.
-- "tag" is a standard OSC type tag.
-- "value" is the arguments value expressed by a Lua type. The value must
-- be convertible to the specified tag, which means, you cannot for example
-- specify an "i" (integer) as type and then pass a string as the value. Use a
-- number value instead. Not all tags require a value, like the T,F boolean 
-- tags. Then a "value" field should not be specified. For more info, see:
-- <http://opensoundcontrol.org/spec-1_0>
--
-- Valid tags are (OSC Type Tag, Type of corresponding value)
-- 
-- + i,    int32
-- + f,    float32
-- + s,    OSC-string
-- + b,    OSC-blob
-- + h,    64 bit big-endian two's complement integer
-- + t,    OSC-timetag
-- + d,    64 bit ("double") IEEE 754 floating point number
-- + S,    Alternate type represented as an OSC-string
-- + c,    An ascii character, sent as 32 bits
-- + r,    32 bit RGBA color
-- + m,    4 byte MIDI message. Bytes from MSB to LSB are: port id, 
--         status byte, data1, data2
-- + T,    True. No value needs to be specified.
-- + F,    False. No value needs to be specified.
-- + N,    Nil. No value needs to be specified.
-- + I,    Infinitum. No value needs to be specified.
-- + [],  Indicates the beginning, end of an array. _currently not 
--        supported by Renoise._
--
renoise.Osc.Message(pattern [, table of {tag, value} arguments])


-------- properties

-- the message pattern (e.g. "/renoise/transport/start")
message.pattern
  -> [read-only, string]

-- table of {tag="X", value=SomeValue}'s that represents the message arguments.
-- see renoise.Osc.Message "create" for more info.
message.arguments
  -> [read-only, table of {tag, value} tables]

-- raw binary representation of the messsage, as needed when e.g. sending the
-- message over the network through sockets
message.binary_data
  -> [read-only, raw string]


--------------------------------------------------------------------------------
-- renoise.Osc.Bundle
--------------------------------------------------------------------------------

-------- create

-- Create a new bundle by specifying a time-tag and one or more messages.
-- If you do not know what to do with the time-tag, use os.clock(),
-- which simply means "now". Messages must be renoise.Osc.Message objects.
-- Nested bundles (bundles in bundles) are right now not supported.
renoise.Osc.Bundle(pattern, single_message_or_table_of_messages)


-------- properties

-- time value of the bundle
bundle.timetag
  -> [read-only, number]

-- access to the bundle elements (table of messages or bundle objects)
bundle.elements
  -> [read-only, table of renoise.Osc.Message or renoise.Osc.Bundle objects]

-- raw binary representation of the bundle, as needed when e.g. sending the
-- message over the network through sockets
bundle.binary_data
  -> [read-only, raw string]

