# Duplex.Applications.Mixer

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
  

## Available options

| Name       | Description   |
| -----------|---------------|
| `pre_post` | Change if either Pre or Post FX volume/pan is controlled |
| `mute_mode` | Decide if pressing mute will MUTE or OFF the track |
| `follow_track` | Align with the selected track in Renoise |
| `page_size` | Specify the step size when using paged navigation |
| `take_over_volumes` | Enables _soft take-over_ for volume |
| `record_method` | Determine how to record automation |
| `record_method` | Determine how to record automation |

## Available mappings 

| Name       | Description   |
| -----------|---------------|
| `master` | Mixer: Master volume |
| `levels` | Mixer: Track volumes (group) |
| `panning` | Mixer: Track pannings (group) |
| `mute` | Mixer: Track mutes (group) |
| `solo` | Mixer: Track solos (group) |
| `next_page` | Mixer: Next track page |
| `prev_page` | Mixer: Previous track page |
| `mode` | Mixer: Pre/Post FX mode |

> Important: while you can have any number of tracks, each group (levels, mute and/or solo) needs to contain the same number of parameters.

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