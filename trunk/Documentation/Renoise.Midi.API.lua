--[[============================================================================
Renoise Midi API Reference
============================================================================]]--

--[[

This reference describes raw MIDI IO support for scripts in Renoise: the
ability to send and receive MIDI data.

Please read the INTRODUCTION.txt first to get an overview about the complete
API, and scripting in Renoise in general...

Do not try to execute this file. It uses a .lua extension for markups only.


-------- Overview

The Renoise Midi API allows you to access any MIDI input or output devices
that are installed in the system. So you can also use MIDI in/outputs which
are currently not used by Renoise (via Renoise's MIDI Remote, Sync settings,
and so on, as set up in the preferences).

-------- Error Handling

When accessing a device which was not yet accessed (not by Renoise and not
by your or other scripts), Renoise will try to open the device driver.
If something goes wrong with this, an error will be shown to the user, like
("MIDI Device Bla failed to open (error)"), but none of the MIDI API
functions will fail.

Aka, if the "real" device failed to open, this is not your problem, but the
users problem.

That's also the reason why none of the Midi API functions return error codes.
All other logic errors, like sending MIDI to a manually closed device, sending
bogus messages and so on, will be fired as usual as Lua runtime errors.


-------- Examples

For some simple examples on how to use MIDI IO in Renoise, have a look at the
"Snippets/Midi.lua" file please. There are two simple MIDI input and output
examples...

]]


--==============================================================================
-- Midi
--==============================================================================

--------------------------------------------------------------------------------
-- renoise.Midi
--------------------------------------------------------------------------------

-------- Device Enumeration

-- List of strings with the currently available devices. This list can change
-- when devices are hotplugged. See 'devices_changed_observable'
renoise.Midi.available_input_devices() 
  -> [list of strings]
renoise.Midi.available_output_devices() 
  -> [list of strings]

-- Fires notifications, as soon as new devices arrive or previously added ones
-- are removed.
-- This will only happen on Linux and OSX with real devices. On Windows this
-- may happen when using ReWire slaves. ReWire adds virtual MIDI devices to
-- Renoise.
-- Already opened references to devices which are no longer available, will
-- do nothing. Aka you can use them as before and they will not fire any errors
-- and the messages will go into the void...
renoise.Midi.devices_changed_observable() 
  -> [renoise.Observable object]


-------- Device Creation

-- Listens to incoming MIDI data: opens access to a MIDI device by its name.
-- Names must be one of "available_input_devices". All other device names will
-- fire a runtime error. Returns a ready to use input device.
-- One or both callbacks should be valid, and should either be a reference to
-- a function with one parameter(message_table), or a table with an object
-- and a class method.
-- All regular messages are forwarded to your device, except active sensing.
-- When Renoise already listens to the device, your callback and Renoise will
-- both handle the message. TODO: THIS WILL CHANGE: MIDI FILTER
-- Messages are received until the device reference is manually closed (see
-- midi_device:close()) or the MidiInputDevice object gets garbage collected.
renoise.Midi.create_input_device(device_name [,callback] [, sysex_callback])
  -> [MidiInputDevice object]

-- Send MIDI: Open reference to an available MIDI device by name. Name must be one of
-- "available_input_devices". All other device names will fire an error. Returns
-- a ready to use output device.
-- The real device driver gets automatically closed when the MidiOutputDevice
-- object gets garbage collected or when the device was explicitely closed
-- via midi_device:close() and nothing else references it.
renoise.Midi.create_output_device(device_name)
  -> [MidiOutputDevice object]


--------------------------------------------------------------------------------
-- renoise.Midi.MidiDevice
--------------------------------------------------------------------------------

-------- properties

-- Returns true while the device is open (ready to send or receive messages).
-- your device refs will never get auto-closed, is_open will only be false if
-- you explicitly called "midi_device:close()" to release a device
midi_device.is_open 
  -> [boolean]

-- The name of the device. This is the name you created the device with (via
-- 'create_input_device' or 'create_output_device')
midi_device.name 
  -> [string]


-------- functions

-- Close a running midi device. when no other client is using it, Renoise will
-- also shut off the device driver, so that for example on Windows other
-- applications can use the device again. This is automatically done when
-- scripts are closed or your device objects are garbage collected
midi_device:close()


--------------------------------------------------------------------------------
-- renoise.Midi.MidiInputDevice
--------------------------------------------------------------------------------

-- no public properties or functions


--------------------------------------------------------------------------------
-- renoise.Midi.MidiOutputDevice
--------------------------------------------------------------------------------

-------- functions

-- Send a regular 1-3 byte MIDI message or sysex message. Message is expected
-- to be a number array, must not be empty and can only contain numbers >= 0
-- and <= 0xFF (bytes)
midi_device:send(message_table)

