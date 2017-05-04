# Duplex.Applications.Matrix

## About

Duplex Matrix takes control of the pattern matrix in Renoise. See this [video demonstration](http://www.youtube.com/watch?v=K_kCaYV_T78) to learn how it can be used. 

## Available options

| Name       | Description   |
| -----------|---------------|
| `play_mode` | What to do when playback is started (or re-started) |
| `switch_mode` | What to do when switching from one pattern to another |
| `bounds_mode` | What to do when a position outside the song is triggered |
| `follow_track` | Align with the selected track in Renoise |
| `page_size` | Specify the step size when using paged navigation |
| `sequence_mode` | Determines how pattern triggers work |

## Available mappings 

| Name       | Description   |
| -----------|---------------|
| `matrix` | Matrix: main button grid (group) |
| `triggers` | Matrix: Pattern-sequence triggers |
| `next_seq_page` | Matrix: display next sequence page |
| `prev_seq_page` | Matrix: display previous sequence page |
| `next_track_page` | Matrix: display next track page |
| `prev_track_page` | Matrix: display previous track page |

## Changelog

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