# xRules - MIDI+OSC utility

## Introduction

xRules is a OSC+MIDI rewriting utility for Renoise. It allows you to transform, route and otherwise change incoming messages using a visual programming interface. The tool supports OSC as well as a wide variety of MIDI messages. For example, you can receive 14-bit MIDI via multibyte CC messages, Pitch Bend or NRPN.

## Installation 

Download the latest stable version from the [tool page](http://www.renoise.com/tools/xrules) (recommended) or download the source code from [github](https://github.com/renoise/xrnx/tree/master/Tools/com.renoise.Noodletrap.xrnx).  
To install, simply download the xrnx file and drag it on top of a Renoise window. 

## What the tool can be used for

* Rewrite messages on-the-fly before passing it on to Renoise
* Filter out unwanted messages with pinpoint precision
* Define complex routings using routing and wildcards  
* Supports 14-bit MIDI (NRPN, CC and pitch bend), including relative values  
* Convert and broadcast MIDI->OSC, OSC->MIDI

## Terms and concepts


At the core of xRules is the concept of Conditions and Actions, also known as 'WHEN' and 'THEN'. In the user-interface, 'WHEN' makes up the upper part of the rule-editor, while 'THEN' is the lower part. 

**Conditions** are criteria that you can freely define. For example, you could look for a message with a MIDI channel higher than 5, or a message whose first data byte is exactly 127. Only messages that match this criteria are passed on. 

By default, conditions assume AND logic, meaning that all conditions you define needs to be true in order for the rule to match (think of it as plain language: the initial condition is WHEN, followed by "AND some other condition"). However, it is possible to click the AND label, and toggle between AND and OR logic. This makes it possible to create a more complex logic: WHEN - AND - OR - AND - THEN...

**Actions** define what to do with the message as it passes through the rule. Each step can change something about the message, such as its value or intended output device. Actions also include custom Lua functions, which allow you to access the Renoise API directly (see the **xRules Lua Reference** below)

Both Conditions and Actions are applied to certain _aspects_ of a message. Exactly which aspects are available depend on the type of message, and whether it is an OSC or MIDI-message.

#### Global Aspects (always available)

    instrument_index -- the associated instrument index
    track_index    -- the associated track index
    values[...]    -- table access to message values
    value_1,value_2    -- individual access to values (1-9)
    

**Note**: By default, xRules will present a number of values in the list, named `value_1`, `value_2` and so on. If you select a specific `message_type`, xRules will provide contextual names for those aspects - more specifically, matching `note-on` messages will rename value_1 and value_2 into `note` and `velocity`, respectively.

#### MIDI Aspects

    channel      -- integer, between 1-16
    port_name    -- string, name of MIDI port
    message_type -- one of xMidiMessage.TYPE
    bit_depth    -- integer, 7 or 14 

#### OSC Aspects 

    device_name -- string, registered device name 


## Controlling Signal Flow

Understanding how messages arrive and sent is key to becoming comfortable with this tool. The following section explains these key concepts in a FAQ-style fashion: 

### How to work with (enable) MIDI input 
You can enable or disable MIDI Input for any particular rule by clicking the 'More' button in the rule toolbar, then choose the 'MIDI Input' tab. A small 'MIDI socket' icon will appear in the sidepanel, next to the rule. 

By default, a rule will receive messages from all active MIDI devices (you can select which ones in the Options dialog). You can then pinpoint the type of message you are looking for, by adding one or more conditions.

    WHEN message_type = 'note_on'
     AND channel = 5
    THEN ...do something ... 

Note that even when MIDI Input is disabled for the rule, it is still possible for other rules to send message to the rule via routing. Also, having disabled the MIDI Input will not prevent the rule from _creating_ MIDI messages of its own. 

### How to work with (enable) OSC input 

Similar to MIDI Input, you can enable or disable OSC Features by clicking the 'More' button in the rule toolbar. Unlike MIDI Input, OSC Features are enabled for the _entire ruleset_, with patterns being defined _per rule_. Before you can use OSC Features you also need to configure an OSC device. This is done in the Options dialog, by clicking the 'OSC' tab and then pressing 'Add Device'. 

Once you have enabled OSC and have defined one or more devices, you can start adding 'patterns'. 

#### OSC Input Pattern

Without an input pattern, a rule will not be able to receive OSC messages. The pattern is composed of two parts: the first is called the 'pattern', and is the 'path' segment that looks much like an internet URL. The second part is the values behind the pattern, which in xRules can be specified as 'literals' or 'wildcards':

    -- a pattern with no values
    /some/pattern
    
    -- a literal capture, values must match   
    /some/pattern 42 3.145 Hello

    -- a wildcard pattern captures values on the fly,
    -- using one of these capturing tokens:  
    -- %i - integer32
    -- %f - float32
    -- %n - number (integer OR float)
    -- %s - string
    /some/pattern %i %f %s

Of course, you can combine literals and wildcards in any way you like. The parsing is done as you are typing, and any errors should be displayed as a small 'warning symbol' next to the rule itself. 

Also, defining the input pattern will automatically create an output pattern - so you only need to define an output pattern _if the output needs to be different from the input_. 

#### OSC Output Pattern

The output pattern allows you to specify an alternative pattern and customize the order of values: 

    -- define an output pattern like this
    /another/pattern $1 $2 $3

    -- the "tokens" determine the order of incoming values 
    -- so, in order to output "in reverse" you would do this:
    /another/pattern $3 $2 $1 



### How to target a specific input/output device

When you receive input from a given device, you are also receiving the device port (when MIDI) or the device name (when OSC). So, at any stage it is possible to create a condition which states that a given message should arrive from port 'X' or have a device-name equal to 'Y'. 

    -- for MIDI messages    
    WHEN port_name = "Launchpad" 
    THEN ...

    -- for OSC messages
    WHEN device_name = "TouchOSC" 
    THEN ...

As the port or device name are part of the message, they can also be changed using actions. For example, you can set the port name using a popup menu (visual approach), or redefine it in a callback function (programmatic approach). 

    -- change the port assignment
    port_name = "My Loopback Port1"

    -- this will output to the port we just set
    output_message('external_midi')


### Converting between OSC & MIDI 

Pass OSC data into Renoise and let xRules the conversion to proper MIDI messages by specifying a message type. The order of values is preserved, e.g. `value_1` and `value_2` is always used for generating MIDI note messages. 


### Lua: controlling the order of values

If the message arrive in the "wrong order", you can swap properties in a Lua function, like this:

    values[1], values[2] = values[2],values[1] 
  
It's also possible to copy the entire values table, process it in any way you like and then pass it back to xRules:

    -- take a copy
    local values_copy = table.copy(values)

    -- do something with the copy...

    -- hand it back
    values = values_copy


### MIDI: How to create a note message

If you want xRules to output a note-message, you need to ensure that the message-type is set to `note_on` or `note_off`, and that the output is one that understands MIDI (all but `external_osc`)

To set the message type, either add a `set_message_type` action, or specify it manually in a custom function:

    message_type = "note_on"
    values[1] = 64    -- note
    values[2] = 127   -- velocity


### MIDI: Dealing with sysex data

You can tell that a message is a sysex message (when `message_type` = `sysex` is true). This is a type of message which is different from other MIDI messages, since it can specify a potentially "unlimited" number of values. Also, since a sysex message is not associated with voices, it does not carry any channel information.  

Sysex messages are often used for messages that deal with highly specific aspects of hardware devices, such as dumping patch data.  

**What it can be used for**: If you have a device which transmit sysex data, xRules can listen to this device and use the sysex as a trigger for some action in Renoise (via a Lua function). Or you can make xRules automatically initialize the device somehow, when the tool is started (see **Triggering Rules** to learn)

**Matching sysex data**: It is possible for xRules to not just listen for specific sysex messages, but also to use a 'wildcard' syntax to match messages with a bit more flexibility

    -- standard message using hexadecimal (00-FF)
    F0 00 01 02 03 F7

    -- use wildcard to indicate 'any value' on the second byte
    F0 * 01 02 03 F7


**Setting sysex data**: Use a Lua function to define many values in one go. For example:
    
    -- set message type
    message_type = "sysex"  

    -- define values (start with 0xF0 and end with 0xF7)
    values = {0xF0,0x00,0x01,0x02,0x03,0xF7}


## xRules Lua Reference

xRules is using a 'sandboxed' environment to execute lua code. From here, you can access Renoise API features as well as a number of additional methods and properties, as defined by xRules:

### Methods

    -- produce output using the specified method
    -- calling this message will add a _copy_ of the message 
    -- in its current state to the output queue. 
    output_message(xRules.OUTPUT_OPTIONS)

    -- route message to a different rule -
    -- @param destination: a string containing the name of
    -- the intended ruleset and rule (e.g. "MyRuleset:Notes")  
    route_message(destination)

    -- record automation (using the global configuration)
    -- @param track_index: a number specifying the track
    -- @param parameter: a renoise.DeviceParameter object
    -- @param value: the value to set
    record_automation(track_index,parameter,value)

    -- check if a device parameter has automation 
    -- @param track_index: a number specifying the track
    -- @param parameter: a renoise.DeviceParameter object
    has_automation(track_index,parameter)

### Properties


`renoise -> [table]` - access the renoise API  
`rns -> [renoise.Song]`, shorthand syntax for renoise.song()  
`rules -> [table]`, reference to all rules in ruleset  
`values -> [table]`, access to values in message  
`track_index -> [integer]`, track index (from message)      
`instrument_index -> [integer]`, instrument index (from message)  
`message_type -> [xMidiMessage.TYPE]`, The type of message ('note_on', etc.) 
`channel -> [integer]`, for xMidiMessage   
`bit_depth -> [integer]`, for xMidiMessage   
`port_name -> [string]`, for xMidiMessage   
`device_name -> [string]`, for xOscMessage  
`__xrule -> [instance of xRule]`, reference to rule itself  
`__xmsg -> [instance of xMidiMessage,xOscMessage]`, reference to the message we received  

### Static classes and Constants

From an xRules function you can access not only the Renoise API, but  also other useful supporting classes

#### Class: xLib

This is the core xLib class, containing static helper methods

#### Class: xRules

The main xRules class


##### xRules.OUTPUT_OPTIONS

You can specify a number of different modes for `output_message()`

    'internal_auto' (supports routing of notes to tracks/instruments)
    'internal_raw'  (raw MIDI, same as unrouted input from controller)
    'external_midi' (send to external MIDI device)
    'external_osc'  (send to external OSC device)


#### Class: xRuleset

Represents a collection of xRule instances

#### Class: xTrack

Static Methods for working with tracks

#### Class: xTransport

Extended transport, including pattern-sequence sections and more

#### Class: xScale

A representation of instrument scales, with methods for transforming notes according to the given scale, key

#### Class: xMidiMessage

A higher-level MIDI message

##### xMidiMessage.TYPE

    note_on
    note_off
    pitch_bend
    controller_change
    ch_aftertouch
    key_aftertouch
    song_position
    nrpn
    sysex

#### Class: xOscMessage

A higher-level OSC message 

#### Class: xAutomation

Control parameter automation

#### Class: xParameter

Control parameters using relative MIDI messages

#### Class: xPlayPos

Extended play-position with support for fractional time

#### Class: xAudioDevice

Static methods for dealing with instances of renoise.AudioDevice

#### Class: xPhraseManager

Static methods for dealing with instrument phrases

## Changelog

#### Done 0.79

    (fixed) xLib automation class could produce glitchy values [bug]
    (fixed) xRules: comparison (string, number) could break due to missing cLib reference in sandbox [bug]FIX popup dialog titles
    (changed) log window gone (uses the scripting console instead)
    (feature) click toolbar to view source and documentation

#### Done 0.78
   
    (feature) add MSB/LSB byte order for NRPN messages

#### Done 0.77

    (feature) added access to xAudioDevice, xPhraseManager classes

#### Done 0.76

    (fixed) numeric comparisons accidentally got broken in v0.75
    (tweak) longstring support for clipboard export (more readable)

#### Done 0.75

    (feature) xTransport - static methods for controlling the Renoise transport
    (feature) xParameter - control parameters using relative MIDI messages
    (feature) condition: show a text input when matching by string 
    (feature) conditions: compare float values with variable precision 
    (usability) when showing ruleset options (“more”), automatically select first active tab
    (tweak) MidiInput no longer throws errors when receiving unrecognized message 
    (fixed) OscRouter: patterns without values match similar patterns with values
    (fixed) OscPattern: “multiple rules responding to one message” - caching bug fixed
    (fixed) newly created OSC rules either run twice or not at all
    (fixed) maintain pattern/route mappings when adding/removing rules
    (fixed) sporadic errors when removing rules/rulesets while receiving messages 

#### Done 0.72
    
    (fixed) missing reference to document while loading a new song
    (fixed) no default message-type defined when converting from OSC (now using sysex)
    (feature) high-res automation recording (use in callback, configure in options)

#### Done 0.68
    
    (fixed) xOscMessage - values not included when cloning messages for output
    (fixed) xOscRouter - when using wildcard patterns, only first pattern was matched
    (fixed) options: custom OSC devices were not correctly saved 
    (fixed) with multibyte support enabled, pitch bend of 0 not transmitted
    (fixed) error when an activity indicator is lit as new model gets imported
    (fixed) when removing first ruleset, no ruleset is selected afterwards
    (fixed) using device_name in condition could corrupt the rule
    (feature) xOscDevice prefix should now be working
    (feature) xRule/sandbox - access values in other rules 
    (feature) shutdown (clicking logo) now closes devices - previously it just ignored input

#### Done 0.65

    When a rule is referencing port names that does not exist on the system, add to list
    When creating new profile, produce a “blank” preferences file
    Hot-plugging support - applies to xRule.ASPECT.PORT_NAME, options dialog
    Sysex support, match/edit message/pattern (including validation)
    Route_message: internal passing of message between rules
