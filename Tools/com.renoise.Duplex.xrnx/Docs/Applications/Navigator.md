# Duplex.Application.Navigator

## Features 

  * Single press & release to move playback to the indicated position
  * When stopped, press & release will cause the edit-pos to move 
  * Pressing two buttons will create a block-loop with that approximate size
  * When a loop has been created, hold any button to cleared it again

## How to use

To take advantage of this application, you need to assign a number of buttons to the "blockpos" - the more buttons, the higher precision you will get. Generally speaking, you want to map either 4, 8 or 16 buttons for music which is based on a 4/4 measure. 

## Available mappings 

| Name       | Description   |
| -----------|---------------|
|`prev_block`|Navigator: Move the blockloop backwards|  
|`next_block`|Navigator: Move the blockloop forward|  
|`blockpos`|Navigator: Pattern position/blockloop <br>Press and release to change position/block<br>Press and hold to enable/disable loop<br>Press multiple buttons to define blockloop |  

## Available options

| Name       | Description   |
| -----------|---------------|
|`operation`|Here you can choose if you want to be able to control both the position and looped range, or just the position. Note that setting the range will require that your controller is capable of transmitting 'release' events.|  
|`loop_carry`|Enable this feature to have the looped range 'carried over' when a new position is set|  
|`pattern_select`|Match the pattern selection with the loop|  
|`valid_coeffs`|Select the set of coefficients that best fit your particular musical content |  

## Changelog

0.98.32
- FIXME When jumping back in pattern, and briefly going to the previous pattern,
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