--[[============================================================================
Renoise Midi API Reference
============================================================================]]--

--[[

This reference describes the raw MIDI IO support for scripts in Renoise; the
ability to send and receive MIDI data.

Please read the INTRODUCTION first to get an overview about the complete
API, and scripting for Renoise in general...

Do not try to execute this file. It uses a .lua extension for markup only.


-------- Overview

The Renoise MIDI API allows you to access any installed MIDI input or output
device. You can also access unused MIDI in/outputs via Renoise's MIDI Remote,
Sync settings, and so on; as set up in the preferences.

-------- Error Handling

When accessing a new device, not used by Renoise nor by your or other scripts,
Renoise will try to open that device's driver. If something goes wrong an error
will be shown to the user. Something like ("MIDI Device Foo failed to open
(error)"). In contrast, none of the MIDI API functions will fail. In other
words, if a "real" device fails to open this is not your problem, but the user's
problem. This is also the reason why none of the MIDI API functions return error
codes.

All other types of logic errors, such as sending MIDI to a manually closed
device, sending bogus messages and so on, will be fired as typical Lua runtime
errors.


-------- Examples

For some simple examples on how to use MIDI IO in Renoise, have a look at the
"Snippets/Midi.lua" file.

]]--


--==============================================================================
-- Midi
--==============================================================================

--------------------------------------------------------------------------------
-- renoise.Midi
--------------------------------------------------------------------------------

-------- Device Enumeration

-- Return a list of strings with the currently available devices. This list can
-- change when devices are hot-plugged. See 'devices_changed_observable'
renoise.Midi.available_input_devices()
  -> [list of strings]
renoise.Midi.available_output_devices()
  -> [list of strings]

-- Fire notifications as soon as new devices become active or a previously
-- added device gets removed/unplugged.
-- This will only happen on Linux and OSX with real devices. On Windows this
-- may happen when using ReWire slaves. ReWire adds virtual MIDI devices to
-- Renoise.
-- Already opened references to devices which are no longer available will
-- do nothing. Aka, you can use them as before and they will not fire any
-- errors. The messages will simply go into the void...
renoise.Midi.devices_changed_observable()
  -> [renoise.Observable object]


-------- Device Creation

-- Listen to incoming MIDI data: opens access to a MIDI input device by
-- specifying a device name. Name must be one of "available_input_devices".
-- Returns a ready to use MIDI input device object.
-- One or both callbacks should be valid, and should either point to a function
-- with one parameter(message_table), or a table with an object and class,
-- a method.
-- All MIDI messages except active sensing will be forwarded to the callbacks.
-- When Renoise is already listening to this device, your callback and Renoise
-- (or even other scripts) will also handle the message.
-- Messages are received until the device reference is manually closed (see
-- midi_device:close()) or until the MidiInputDevice object gets garbage
-- collected.
renoise.Midi.create_input_device(device_name [,callback] [, sysex_callback])
  -> [MidiInputDevice object]

-- Send MIDI: open access to a MIDI device by specifying the device name.
-- Name must be one of "available_input_devices". All other device names will
-- fire an error. Returns a ready to use output device.
-- The real device driver gets automatically closed when the MidiOutputDevice
-- object gets garbage collected or when the device is explicitly closed
-- via midi_device:close() and nothing else references it.
renoise.Midi.create_output_device(device_name)
  -> [MidiOutputDevice object]


--------------------------------------------------------------------------------
-- renoise.Midi.MidiDevice
--------------------------------------------------------------------------------

-------- Properties

-- Returns true while the device is open (ready to send or receive messages).
-- Your device refs will never be auto-closed, "is_open" will only be false if
-- you explicitly call "midi_device:close()" to release a device.
midi_device.is_open
  -> [boolean]

-- The name of a device. This is the name you create a device with (via
-- 'create_input_device' or 'create_output_device')
midi_device.name
  -> [string]


-------- Functions

-- Close a running MIDI device. When no other client is using a device, Renoise
-- will also shut off the device driver so that, for example, Windows OS other
-- applications can use the device again. This is automatically done when
-- scripts are closed or your device objects are garbage collected.
midi_device:close()


--------------------------------------------------------------------------------
-- renoise.Midi.MidiInputDevice
--------------------------------------------------------------------------------

-- No public properties or functions


--------------------------------------------------------------------------------
-- renoise.Midi.MidiOutputDevice
--------------------------------------------------------------------------------

-------- Functions

-- Send raw 1-3 byte MIDI messages or sysex messages. The message is expected
-- to be an array of numbers. It must not be empty and can only contain
-- numbers >= 0 and <= 0xFF (bytes). Sysex messages must be sent in one block,
-- must start  with 0xF0, and end with 0xF7.
midi_device:send(message_table)

