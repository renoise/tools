# Duplex.Applications.Matrix

< Back to [Applications](../Applications.md)

## About

Duplex Matrix takes control of the pattern matrix in Renoise. See this [video demonstration](http://www.youtube.com/watch?v=K_kCaYV_T78) to learn how it can be used. 

## Available mappings
  
| Name       | Description   |
| -----------|---------------|  
|`matrix`|Matrix: Press to toggle muted state<br>Hold to focus this track/pattern<br>Control value: |  
|`next_seq_page`|Matrix: display next sequence page|  
|`next_track_page`|Matrix: display next track page|  
|`prev_seq_page`|Matrix: display previous sequence page|  
|`prev_track_page`|Matrix: display previous track page|  
|`trigger_labels`|Matrix: Pattern-sequence labels (pattern names)|  
|`triggers`|Matrix: Pattern-sequence triggers<br>Press and release to trigger pattern<br>Press multiple buttons to define loop<br>Press and hold to toggle loop<br>Control value: |  

## Default options 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Description   |
| ------------- |---------------|  
|`bounds_mode`|What to do when a position outside the song is triggered|  
|`follow_track`|Align with the selected track in Renoise|  
|`page_size`|Specify the step size when using paged navigation|  
|`play_mode`|What to do when playback is started (or re-started)|  
|`sequence_mode`|Determines how pattern triggers work: <br>Select 'Position only' for controllers that does not<br>support the release event. Select 'Position & Loop'<br>if your controller supports the release event, and you<br>want to be able to control the looped range|  
|`switch_mode`|What to do when switching from one pattern to another|  

## Default palette 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Color|Text|Value|
| ------------- |------|----|-----|  
|`prev_seq_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|▲|true|  
|`slot_filled`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFF00; color: black">0xFF,0xFF,0x00</div>|▪|true|  
|`out_of_bounds`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#404000; color: white">0x40,0x40,0x00</div>|·|false|  
|`trigger_back`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>||nil|  
|`prev_seq_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|▲|false|  
|`prev_track_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|◄|true|  
|`slot_master_empty`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#004000; color: white">0x00,0x40,0x00</div>|·|false|  
|`slot_empty`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|·|false|  
|`slot_empty_muted`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#400000; color: white">0x40,0x00,0x00</div>|·|false|  
|`next_seq_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|▼|false|  
|`trigger_active`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>||nil|  
|`slot_filled_muted`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FF4000; color: white">0xFF,0x40,0x00</div>|▫|false|  
|`next_seq_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|▼|true|  
|`prev_track_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|◄|false|  
|`next_track_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|►|false|  
|`next_track_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|►|true|  
|`trigger_loop`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#4040FF; color: white">0x40,0x40,0xFF</div>||nil|  
|`slot_master_filled`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#00FF00; color: white">0x00,0xFF,0x00</div>|▪|true|

## Changelog

1.04
- Added: on-the-fly switching between patterns tries to 'keeps the beat'

1.01
- Tool-dev: use cLib/xLib libraries

0.95  
- Added changelog, more thourough documentation

0.93  
- Inclusion of UIButtonStrip for more flexible control of playback-pos
- Utilize "blinking" feature to display a scheduled pattern
- "follow_player" mode in Renoise will update the matrix immediately

0.92  
- Removed the destroy_app() method (not needed anymore)
- Assign tooltips to the virtual control surface

0.91  
- All mappings are now without dependancies (no more "required" groups)

0.81  - First release