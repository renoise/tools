# Concepts

This chapter explains a number of concepts, relevant to Duplex.

## Paged Navigation

The purpose on an application such as the Mixer is to show a lot of parameters, side-by-side. _Paged navigation_ is a concept which refines this by allowing you to navigate between those parameters in a more controlled, 'page based' fashion. 

The idea is to take a lot of parameters and divide them into pages. For example, consider a song with 12 tracks. If we have a controller with four sliders and some buttons, and want to use it as a small mixing console, we would probably want to configure it like this: 

       Page 1        Page 2        Page 3
    ┌─┐┌─┐┌─┐┌─┐  ┌─┐┌─┐┌─┐┌─┐  ┌─┐┌─┐┌─┐┌─┐
    │ ││ ││ ││ │  │ ││ ││ ││ │  │ ││ ││ ││ │
    │ ││ ││ ││ │  │ ││ ││ ││ │  │ ││ ││ ││ │
    │ ││ ││ ││ │  │ ││ ││ ││ │  │ ││ ││ ││ │
    │ ││ ││ ││ │  │ ││ ││ ││ │  │ ││ ││ ││ │
    └─┘└─┘└─┘└─┘  └─┘└─┘└─┘└─┘  └─┘└─┘└─┘└─┘
     1  2  3  4    5  6  7  8    9 10 11 12
      Tracks        Tracks        Tracks
    
The _page size_ in this case would be four. For any application that implements paged navigation, this is usually something you can specify through the [options dialog](GettingStarted.md#the-options-dialog).

The application would also need to expose two mappings, giving you the ability to navigate between the available pages. Those mappings would usually be called something like `previous/next_page`. 

## MIDI Thru / Pass Unhandled Messages

This feature allows you to pass 'unhandled' MIDI messages through to Renoise. This is useful when you want to benefit from the bi-directional nature of Duplex applications, but also use regular MIDI mappings in Renoise.

An 'unhandled' message is a parameter, such as a button or slider, which is not managed by a (running) Duplex application. Using the Duplex browser, you can see which parameters are mapped by hovering over them with the mouse - the tooltip should reveal when/if the parameter is currently in use by Duplex. 

The reason it works is because MIDI mappings in Renoise doesn't care which device it received the message from, only the message itself (which CC number, etc.).

The feature is implemented as a checkbox in the [device-configuration dialog](GettingStarted.md#the-device--configuration-dialog) and requires that the Renoise OSC server is [enabled and properly configured](Installation.md#enable-the-renoise-osc-server )

> Strictly speaking, you don't need unmapped parameters to try out this feature. Just follow the instructions here, while making sure that the application is not running. This works, as only running applications will try to handle messages. 

## MMC Transport Control

Duplex has built-in support for a set of MMC commands, providing direct control over the Renoise transport. These commands are evaluated as long as the following conditions are true:

* The MIDI device sending the MMC messages is active in Duplex 
* MMC has been enabled in the [Options dialog](GettingStarted.md#the-options-dialog)


|Name |Action taken|Sysex data (hex) |
|-----|------------|-----------------|
|MMC Stop|      Stop playing|       F0 7F 7F 06 01 F7
|MMC Play|      Start playing|      F0 7F 7F 06 02 F7 
|MMC Deferred Play|Continue playing|F0 7F 7F 06 03 F7 
|MMC Fast Fwd|  Next pattern|       F0 7F 7F 06 04 F7	 
|MMC Rewind|    Previous pattern|   F0 7F 7F 06 05 F7	 
|MMC Punch In|  Enable edit mode|   F0 7F 7F 06 06 F7	 
|MMC Punch Out| Disable edit mode|  F0 7F 7F 06 07 F7	 
|MMC Record     Pause|-|          F0 7F 7F 06 08 F7	 
|MMC Pause|     Stop Playing|       F0 7F 7F 06 09 F7	 
|MMC Eject|     -|                F0 7F 7F 06 0A F7	 
|MMC Chase|     -|                F0 7F 7F 06 0B F7	 
|MMC Cmd Error Reset|-|           F0 7F 7F 06 0C F7	 
|MMC Reset|-|                     F0 7F 7F 06 0D F7	 



