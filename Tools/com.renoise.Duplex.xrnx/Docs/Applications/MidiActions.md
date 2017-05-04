# Duplex.Applications.MidiActions

## About 

MidiActions will expose standard Renoise mappings as fully bi-directional mappings, with customizable scaling (exponential, logarithmic, linear) and range. 

By parsing the GlobalMidiActions file, it literally provides access to hundreds of features inside Renoise, such as BPM, LPB, and even UI view presets. You will have to map each feature manually, but only once - once mapped, the target will remain accessible. 

## Available options

| Name       | Description   |
| -----------|---------------|
| `action` | List of supported MIDI actions (GlobalMidiActions.lua) |
| `min_scaling` | Determine the minimum value to output |
| `max_scaling` | Determine the maximum value to output |
| `scaling` | Determine the output scaling |

## Available options

| Name       | Description   |
| -----------|---------------|
| `control` | MidiActions: designated control |

## Changelog

0.xx
- Initial release
