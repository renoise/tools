# Duplex.Applications.XYPad

## Features
* Built-in automation recording 
* Supports knobs, a MIDI keyboard's touchpad or an OSC device's accelerometer
* Free roaming - jump between different XYPad devices in the song
* Device Lock - remember focused device between sessions

## Usage

For basic operation, you can map _either_ `xy_pad` or `xy_grid` to your controller. Without any of these mappings, the application will refuse to start.

To map an OSC device, add a `Param` node to the control-map which look like this:

    <Param name="MyDevicePad" type="xypad"  minimum="0" maximum="127"/>

To map a MIDI device, add a `Param` node to the control-map which look like this:

    <Param name="XYPad_X" type="xypad" size="4" skip_echo="true">
      <SubParam value="CC#56" orientation="vertical" minimum="0" maximum="127" />
      <SubParam value="CC#57" orientation="horizontal" minimum="0" maximum="127" />
    </Param>

> Note: to enter the correct minimum and maximum values, it's important you know a bit about your device as the application will base it's min/max/axis values 
directly on the information specified here. 


## Discuss

Tool discussion is located on the [Renoise forum](http://forum.renoise.com/index.php?/topic/33154-new-tool-duplex-xypad/)

## Changelog

0.99.12
- Supports <SubParam> nodes (proper support for MIDI devices)
- Broadcasting of MIDI values

0.98.19
- Simplified setup: use unique, automatically-generated names to identify 
  “managed” XYPads (no more need for manually specified id’s)

0.98.15
- Fixed: No longer looses focus when navigating to a new track

0.98 
- First release 

