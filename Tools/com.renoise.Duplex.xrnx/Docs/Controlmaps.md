# Controlmaps

## What is a control-map

Control-maps are XML-based documents which describe the layout of a controller. When you see a virtual representation of a device in the Duplex browser, this is built entirely from the information present in the control-map. 

A control-map defines the available layout in terms of groups, rows and colums. Inside those groups, you can put parameters (buttons, sliders, etc.), and determine the physical size of those parameters, what values they respond to, and so on. 

### How to customize a control-map

Since control-maps are XML files, editing a control-map is best done in a text editor which supports "folding". This makes it easy to work with even the most complex documents, as you can simply fold (hide) whatever parts you are not interested in. 

If you're new to XML and text editors, don't worry. If you create a control-map that has invalid or broken syntax, Duplex should be able to offer advice on how to fix the problem. 

See the section below (anatomy of a control-map) to learn which properties you can add to each specific part of the control-map. Also, feel free to study the many control-maps that are bundled with Duplex. 

## The anatomy of a control-map

Let's pick apart a simple control-map like this one:

    <Device>
      <Name>Example control-map</Name>
      <Author>Danoise</Author>
	    <Description>An example on how to write a control-map</Description>
      <Parameters>
        <Column>
          <Row>
            <Group name="sliders" orientation="horizontal">
              <Param value="PB|Ch1" type="fader" maximum="127" minimum="0"/>
              <Param value="PB|Ch2" type="fader" maximum="127" minimum="0"/>
              <Param value="PB|Ch3" type="fader" maximum="127" minimum="0"/>
              <Param value="PB|Ch4" type="fader" maximum="127" minimum="0"/>
              <Param value="PB|Ch5" type="fader" maximum="127" minimum="0"/>
              <Param value="PB|Ch6" type="fader" maximum="127" minimum="0"/>
              <Param value="PB|Ch7" type="fader" maximum="127" minimum="0"/>
              <Param value="PB|Ch8" type="fader" maximum="127" minimum="0"/>
            </Group>
          </Row>
        </Column>
      </Parameters>
    </Device>


### The `Device` node

This is the top-most level in a control-map.  
You can add the following node types here: `<Name>`, `<Author>`, `<Description>`, `<State>` and `<Parameters>`

The first three nodes are informational, and appear in the Duplex browser:

|Node  |Type | Description   |
|------|-----|---------------|
|`<Name>`|string|A descriptive name for the control-map.
|`<Author>`|string|The author name here - e.g. your name.
|`<Description>`|string|A brief description of the control-map. This is a particularly useful place to show instructions to the user if/when a special preset needs to be loaded before things will work as expected. 


### The `Parameters` node

You can add `Row`, `Column`, and `Group` nodes inside the `Parameters` node. 

### The `State` node

Defines a state for the control-map. States allow dynamic switching of control-map nodes, while a configuration is running.  
Please refer to [this section](#states-when-static-maps-are-not-enough) to learn more about how they work.

|Attribute |Type  | Description   |
|----------|----- |---------------|
|`name`|string| a unique name for identifying the state, and for prefixing nodes|
|`type`|enum| "toggle", "momentary" or "trigger", determine how to respond to events
|`value`|string| the incoming message that we want to match against (see [matching by value](#matching-by-value). 
|`match`|number| the exact value to match (e.g. CC number with value "5") 
|`exclusive`|string| specify a(ny) name for states that should be mutually exclusive
|`invert`|bool| when true, trigger will light up when state is inactive 
|`receive_when_inactive`|bool| when/if to receive/send parameter messages 
|`hide_when_inactive` |bool| when/if to show/hide parameters
|`disable_when_inactive`|bool| when/if to enable/disable parameters
|`active`|bool| set the initial state

### The `Row` and `Column` node

A pure layout node that accepts no attributes  

### The `Group` node

Note: only `Param` nodes are supported inside a `Group` node

Accepts the following attributes: 

|Attribute |Type  | Description   |
|----------|----- |---------------|
|`name` |string| the group name, this value is passed on to all members (Param nodes)|
|`visible`|bool| optional, define if group should be visible or hidden (default is true)|
|`columns`|int| optional, define how many parameters to create before creating a new row
|`colorspace`|table| Some devices have multi-colored LEDs that are able to display a range of colors. The colorspace attribute is a simple way of defining what colors are accessible, and will also quantize the colors displayed in the virtual control surface. _If this value is not defined, it is inherited from parent or device_
|`orientation`|enum| "horizontal" or "vertical" - determines the flow of elements

### The `Param` node

Note: only `SubParam` nodes are supported inside a `Param` node

Accepts the following attributes:  

|Attribute |Type  | Description   |
|----------|----- |---------------|
|`type`|enum| the type of input, e.g. `dial` (see [Duplex.Globals.INPUT_TYPE](https://renoise.github.io/luadocs/duplex/modules/Duplex.Globals.html#INPUT_TYPE))
|`value`|string| the pattern that we match messages against (see [matching by value](#matching-by-value)). 
|`action`|string| specify this attribute to use a different output than input pattern
|`name`|string| give the parameter a descriptive name (optional)
|`size`|int| the relative size of the UIComponent (2 = 200% size)
|`aspect`|number| the relative aspect of the UIComponent (0.5 = half height)
|`minimum`|number| the minimum value (e.g. to set a button to unlit state)
|`maximum`|number| the maxmum value (e.g. to set a button to lit state)
|`match`|number| the exact value to match (e.g. CC number with value "5")
|`match_from`|number| a value range to match (require that you also specify match_to)
|`match_to`|number| a value range to match (require that you also specify match_from)
|`skip_echo`|bool| never send message back to device
|`soft_echo`|bool| only send virtually generated messages back to device
|`invert`|bool| swap the minimum and maximum values
|`invert_x`|bool| for XYPad, swap the top and bottom values
|`invert_y`|bool| for XYPad, swap the left and right values
|`swap_axes`|bool| for XYPad, swap the horizontal and vertical axes
|`orientation`|enum| specifies the orientation of a control - relevant for params of type=`fader`
|`text`|string| specify the text value, relevant for params of type=`label` 
|`font`|string| specify the font type, relevant for params of type=`label` 
|`range`|int| specify the range of an on-screen keyboard (number of keys)
|`mode`|enum| how to interpret incoming values (see [Duplex.Globals.PARAM_MODE](https://renoise.github.io/luadocs/duplex/modules/Duplex.Globals.html#PARAM_MODE))
|`throttle`|bool| whether we should throttle this parameter or not (overrides the device default)
|`class`|string| interpret control-map in the context of which (device) class? (default is to use the current device context, but you can enter any literal class name, e.g. "OscDevice" or "LaunchPad"). 

Some additional properties are added by Duplex while the tool is running. No need to know about these, unless you are writing your own applications.

|Attribute |Type  | Description   |
|----------|----- |---------------|
|`id`|string| a unique, auto-generated name
|`index`|int| the index (position) within the parent `Group` node
|`group_name`|string| this value is passed on from the parent `Group` node
|`row`|int| the row within the parent `Group`
|`column`|int|- the column within the parent `Group`
|`has_subparams`|bool| true when the parameter contains additional subparameters
|`regex_patt`|string| preprocessed regular expression, created when `value` contains wildcards and/or captures


### The `SubParam` node

A subparameter is required when a single parameter is representing multiple values - for example, an XY-pad specifies both X and Y.  
The accepted attributes depend on the type of widget.

|Name   |Type  | Description   |
|-------|----- |---------------|
|`value`|string| The pattern that we match messages against. If a value is not specified, the sub-parameter will use the value specified by its parent node. See also: [matching by value](#matching-by-value).
|`field`|string| What aspect of the parent parameters' value that is being stored (e.g. "x" for xypad x axis)

## Matching by value 

Whenever we receive a message from a device, the value attributes in the control-map determine if we should respond to the message or not. 
The syntax below is used by `<Param>`, `<SubParam>` and `<State>` nodes:

|Example   |Message type  | Matches because   |
|----------|------------- |-------------------|
|`CC#2`|MIDI Control-change|Starts with "CC"
|`CC#7|Ch6`|MIDI| Control-change + channel|Starts with "CC"
|`C-4`|MIDI Note|Has "-" or "#" as second character
|`G#5|Ch4`|MIDI Note + channel|Has "-" or "#" as second character
|`C--3`|MIDI Note (negative octave)|Has "-" or "#" as second character
|`PB`|MIDI PitchBend |Starts with "PB"
|`PB|Ch3`|MIDI PitchBend + channel|Starts with "PB"
|`Prg#2`|MIDI Program change |Starts with "Prg"
|`Prg#2`|Ch4|MIDI Program change + channel|Starts with "Prg"
|`/led 3 2 %i`|OSC message*|Starts with a slash
|`/xyz %f %f %f`|OSC message*|Starts with a slash

> OSC messages can contain embedded string directives:  
  `%i` means integer and `%f` is a floating-point value

## States : when static maps are not enough

Now, since a control-map is an XML document, you might think of it as static. But, since v0.99 Duplex has something called 'states', which allow you to enable or disable certain control-map features while a configuration is running. States are particularly useful when you are running out of space on a controller, and want to introduce a "modifier" key that reveals additional functionality. 

Almost everything in a control-map can be affected by states: `<Group>`, `<Row>`, `<Column>` and `<Param>`. 


### How to define a toggling state 

Adding a toggling state is done by associating a named state with a certain 'trigger' (usually, a button). In the example below we are defining two states - `AltOn` and `AltOff`, and making sure that one of them (`AltOff`) is set as active on startup:

    <Device>
      <States>
        <State name="AltOn" value="CC#12" type="toggle" hide_when_inactive="true"/>
        <State name="AltOff" value="CC#12" type="toggle" hide_when_inactive="true" active="true" />
      </States>
      <Parameters>
        <!-- parameters goes here .. -->
      <Parameters>
    </Device>      

Once the two states have been defined, the rest is simply a question of prefixing any target nodes that you want to show or hide, using the state names. As we specified that parameters affected by each state should `hide_when_inactive`, only one of these groups will now be visible at any one time:

    <!-- snip -->
    <Parameters>
      <AltOff:Group name="Toggle" >
        <Param value="CC#15" type="button" maximum="1" minimum="0"/>
      </Group>
      <AltOn:Group name="AltToggle" >
        <Param value="CC#15" type="button" maximum="1" minimum="0"/> 
      </Group>
    <Parameters>


## Changelog
  
0.99.5
- <Param @throttle> (new), enable/disable (MIDI) message throttling

0.99.3
- <Param @match> (new), match a specific (CC) value 
- <Param @match_from, @match_to> (new), match a (CC) value-range 
- <Param @mode> (new), specify resolution (7/14 bit) and operation (absolute/relative)
- <Param @class> (new), interpret parameter in the context of a specific device class

0.99.2
- Faster, more flexible parameter matching 
  - all messages are processed on startup, cached/memoized where possible
  - OSC patterns now support "captures", see get_osc_params() for more info
  - get_osc_params(): when using wildcards, returns table of regexp-matches
- <Param @invert> (new), allows inverting the value (flip min/max)
- <Param @soft_echo> (new) update device only when changed via virtual UI
- <Param @font> (new), specify the font type - relevant for @type=labels only
- <Param @velocity_enabled> attribute has been retired
- <Param @is_virtual> attribute has been retired, just enter a blank @value
- <Param @type="key"> widget type has been retired (use @type="button")
- <SubParam> new node type for combining several parameters into one
  (finally, we can have a "proper" xypad control for MIDI devices)
- <Group @visible> (new), set to false to hide the entire group 

0.99.1 
- TWEAK No more need to explicitly state "is_virtual" for parameters that only
  exist in the virtual UI - just leave the value attribute blank

0.98.14
- cache parameters
    o Faster retrieval of MIDI parameters (put in cache once requested)
- New input method `xypad`, for creating XYPad controls in the 
  virtual control surface (paired-value support, however only OSC devices can 
  define this input method)
- new input method: `key` - for accepting note-input from 
  individual buttons/pads (Note: OBSOLETE)
- Control-map/virtual control surface: `keyboard` - a new input method for 
  representing a keyboard (the control surface will draw a series of keys)
    o In the control-map, you can specify it`s range (number of keys)
- Control-map/XML parsing:
    o Attribute names can now contain underscore
- Control-map/note value syntax: octave wildcard - you can now put an asterisk 
  in place of the octave to make mapping respond to the note only (e.g. `C-*`). 
  Used in the Midi-keyboard Grid Pie configuration to make navigation buttons 
  appear across all the black keys

0.95
- New button type: pushbutton (like togglebutton, has internal state control)
  - UISlider, UIToggleButton made compatible with pushbutton (special case)
  - We can now emulate sliders on the TouchOSC template (page 2)
  - Nocturn and Remote will now be able to support hold/release events
- "name" attribute now optional (excluded from validation)
- "size" attribute now also applied to dials (see MPD24/32)
- Streamlined methods for detecting group size, grid mode

0.9
- First release
