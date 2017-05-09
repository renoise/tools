# Duplex.Applications.Mixer

< Back to [Applications](../Applications.md)

## Features

### Parameter pick-up

When the 'soft takeover' option is enabled, values will not be changed until you move a fader across the threshold point (the current value). This helps to avoid sudden jumps in levels.

### Automatic grid layout

Assigning the levels, mute and/or solo mapping to the same group (the grid) will automaticaly produce the following layout:

    +---- - --- - --- - --- +    +---- +  The master track 
    |mute1|mute2|mute3|mute4| -> |  m  |  will, when specified, 
    |---- - --- - --- - --- |    |  a  |  show up in the 
    |solo1|solo2|solo3|solo4| -> |  s  |  rightmost side 
    |---- - --- - --- - --- |    |  t  |  and use full height
    |  l  |  l  |  l  |  l  | -> |  e  |  
    |  e  |  e  |  e  |  e  |    |  r  |  
    |  v  |  v  |  v  |  v  |    |     |  
    |  e  |  e  |  e  |  e  |    |     |  
    |  l  |  l  |  l  |  l  |    |     |
    |     |     |     |     |    |     |
    |  1  |  2  |  3  |  4  |    |     |
    +---- - --- - --- - --- +    +---- +
  
> Important: while you can have any number of tracks, each group (levels, mute and/or solo) needs to contain the same number of parameters.

## Available mappings
  
| Name       | Description   |
| -----------|---------------|  
|`mute`|Mixer: Mute track|  
|`master`|Mixer: Master volume|  
|`solo`|Mixer: Solo track|  
|`prev_page`|Mixer: Previous track page|  
|`panning`|Mixer: Track panning|  
|`mode`|Mixer: Pre/Post FX mode|  
|`next_page`|Mixer: Next track page|  
|`levels`|Mixer: Track volume|  

## Default options 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Description   |
| ------------- |---------------|  
|`page_size`|Specify the step size when using paged navigation|  
|`record_method`|Determine if/how to record automation |  
|`sync_pre_post`|Decide if switching Pre/Post is reflected <br>both in Renoise and on the controller|  
|`pre_post`|Change if either Pre or Post FX volume/pan is controlled|  
|`take_over_volumes`|Enables soft take-over for volume: useful if device-faders<br>are not motorized. This feature will not take care of the<br>position of the fader until the volume value is reached.<br>Example: you are playing a song A and you finish it by<br>fading out the master volume. When you load a song B, the<br>master volume will not jump to 0 when you move the fader|  
|`follow_track`|Align with the selected track in Renoise|  
|`mute_mode`|Decide if pressing mute will MUTE or OFF the track|  

## Default palette 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Color|Text|Value|
| ------------- |------|----|-----|  
|`normal_tip_dimmed`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#0040FF; color: white">0x00,0x40,0xFF</div>||true|  
|`normal_mute_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#40FF40; color: white">0x40,0xFF,0x40</div>|M|true|  
|`send_lane`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#8100FF; color: white">0x81,0x00,0xFF</div>||true|  
|`send_mute_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FF4000; color: white">0xFF,0x40,0x00</div>|M|true|  
|`next_page_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|►|false|  
|`normal_mute_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|M|false|  
|`master_lane`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#8080FF; color: black">0x80,0x80,0xFF</div>||true|  
|`normal_tip`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#00FFFF; color: black">0x00,0xFF,0xFF</div>||true|  
|`background`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|·|false|  
|`prev_page_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|◄|false|  
|`next_page_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|►|true|  
|`prev_page_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|◄|true|  
|`normal_lane_dimmed`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#0040FF; color: white">0x00,0x40,0xFF</div>||true|  
|`mixer_mode_pre`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|Pre|true|  
|`solo_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|S|false|  
|`solo_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FF4000; color: white">0xFF,0x40,0x00</div>|S|true|  
|`master_tip`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>||true|  
|`mixer_mode_post`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|Post|false|  
|`send_mute_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|M|false|  
|`normal_lane`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#0081FF; color: white">0x00,0x81,0xFF</div>||true|  
|`master_mute_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFF40; color: black">0xFF,0xFF,0x40</div>|M|true|  
|`send_lane_dimmed`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#4000FF; color: white">0x40,0x00,0xFF</div>||true|  
|`send_tip_dimmed`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#4000FF; color: white">0x40,0x00,0xFF</div>||true|  
|`send_tip`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FF4000; color: white">0xFF,0x40,0x00</div>||true|  


## Changelog

1.01
- Tool-dev: use cLib/xLib libraries
- High-res automation recording (interleaved or punch-in)

0.99
- UIComponent: when possible, supply mapping as construction argument
- UIComponent references stored within self._controls

0.98
- Track navigation removed (delegated to TrackSelector app)

0.97  
- Renoise's 2.7 multi-solo mode supported/visualized
- Main display updates now happen in on_idle loop
- Ability to embed both mute & solo mappings into grid
- New option: "sync_pre_post" (Renoise 2.7+)

0.96  
- Option: paged navigation features (page_size)
- Option: offset tracks by X (for the Ohm64 configuration)

0.95  
- The various mappings now have less dependancies 
- Feature: hold mute button to toggle solo state for the given track
- Applied feedback fix (cascading mutes when solo'ing)
- Options: follow_track, mute_mode

0.92  
- Remove the destroy_app() method (not needed anymore)
- Assign tooltips to the virtual control surface

0.90  
- Use the new UIComponent.set_pos() method throughout the class
- Adjusted colors to degrade better on various devices

0.81  
- First release