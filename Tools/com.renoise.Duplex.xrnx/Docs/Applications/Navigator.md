# Duplex.Application.Navigator

< Back to [Applications](../Applications.md)

## About

Navigator can manipulate the playback position and block-loop of a pattern in realtime. You can do this, even playback is happening in a different pattern than the currently selected one. 


## Basic operation

  * Tap a button to move to a new position in the pattern.
  * When playback is stopped, moves the edit-position. Otherwise, the playhead.
  * Press+hold a single button to loop and/or select this range. 
  * Press two buttons to create a looped range.

### Controlling looped ranges

If you have looped a range, you can move this around as well. The following rules apply:

* If you press _inside_ the loop, the position is changed (like a normal button tap)
* If you press _outside_ the loop, the loop is moved to this position *
* If you press and hold _inside_ the loop, the loop is collapsed/cleared


### Measures: 4/4 and beyond

Generally speaking, most music is based on a 4/4 measure. Navigator knows this, but it's smart enough to auto-detect if the pattern length is a power of three. For example, a 64-line pattern is a power of four, as 64 divided by four is 16. But it can't be a power of three, because 64/3 isn't a whole number. 

This is how typical 64-line pattern would look like, if you had 4 buttons:

    ┌───1───┬───2───┬───3───┬───4───┐
    │  1-16 │ 17-32 │ 33-48 │ 49-64 │
    └───────┴───────┴───────┴───────┘

A 24-line pattern would also work with powers of four:

    ┌───1───┬───2───┬───3───┬───4───┐
    │  1-6  │  7-12 │ 13-18 │ 19-24 │
    └───────┴───────┴───────┴───────┘

Using powers of three, you can of course divide a 24-line pattern into three equal parts. But if the number of buttons on your controller does not line up perfectly, controlling it can be a bit "funny". Consider the following (controlling three parts with four buttons):

    ┌───1─────┬─2───────3┬──────4───┐
    │   1-8   │   9-16   │  17-24   │
    └─────────┴──────────┴──────────┘

In this example, pressing buttons 1+2 would select the range from 1-16, and pressing 3+4 would select the range from 9-24. So starting the range from the third button actually selected a range that begins _earlier_ than ending the range with the second button. 

## Requirements

Some of Navigators functionality is only available for devices that are capable of transmitting 'release' events. All range-based operations (such as hold-to-loop or hold-to-select) have this requirement.  

## Available mappings
  
| Name       | Description   |
| -----------|---------------|  
|`prev_block`|Navigator: Move the blockloop backwards
|`next_block`|Navigator: Move the blockloop forward
|`blockpos`|Navigator: Pattern position/blockloop<br>[Press and release] to change position/block<br>[Press and hold] to enable/disable loop<br>[Press multiple buttons] to define blockloop 

## Default options 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Description   |
| ------------- |---------------|  
|`operation`|Here you can choose if you want to be able to<br>control both the position and looped range,<br>or just the position. |  
|`loop_carry`|Enable this feature to have the looped range<br>'carried over' when a new position is set|  
|`pattern_select`|Match the pattern selection with the loop|  
|`valid_coeffs`|Select the set of coefficients that best <br>fit your particular musical content |  

## Default palette 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Color|Text|Value|
| ------------- |------|----|-----|  
|`prev_block_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|▲|true|  
|`blockpos_index`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|▪|true|  
|`next_block_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|▼|false|  
|`blockpos_range`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#808080; color: white">0x80,0x80,0x80</div>|▫|true|  
|`blockpos_background`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|·|true|  
|`prev_block_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|▲|false|  
|`next_block_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|▼|true|  

## Changelog

1.05
- Added: Improved handling of non-4/4 measures
- Added: Option to auto-detect measure (is now the default choice)

1.01
- Tool-dev: use cLib/xLib libraries

0.98.32
- Fixed: When jumping back in pattern, and briefly going to the previous pattern,
  the navigator would break if the previous pattern hadn’t same number of lines

0.98.27
- Should be more solid and support off-pattern updates
- New mappings: “prev_block”,”next_block”

0.98.21
- Fixed: issue when loading a new song while Navigator was displaying nothing
  (playback happening in a different pattern)

0.98
- Reset on new song
- Listen for changes to block-loop size
- Follow block loop enable

0.96
- Fixed: holding button while playback is stopped cause error 

0.95
- Interactively control the blockloop position and size

0.9
- First release