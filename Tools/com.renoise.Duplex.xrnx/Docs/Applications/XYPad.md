# Duplex.Applications.XYPad

![XYPad_devices](../Images/XYPad_devices.png)  
*The XYPad application is available on multiple devices*

## Features
* Built-in automation recording 
* Supports knobs, a MIDI keyboard's touchpad or an OSC device's accelerometer
* Free roaming - jump between different XYPad devices in the song
* Device Lock - remember focused device between sessions

## Setting up (mapping)

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

## How to use


**Specially tweaked for grid/pad controllers**  
When you're using buttons to control an XYPad device, there is a slight amount
of variation applied, each time you hit the button. It's not enough to be noticeable,
but it will allow the XYPad to fire a signal on repeated hits, instead of just when
you hit _another_ button

## Discuss

Tool discussion is located on the [Renoise forum](http://forum.renoise.com/index.php?/topic/33154-new-tool-duplex-xypad/)

## Changelog

1.01
- Tool-dev: use cLib/xLib libraries
- High-res automation recording (interleaved or punch-in)

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

