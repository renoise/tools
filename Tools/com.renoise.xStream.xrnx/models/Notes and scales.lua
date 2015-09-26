--[[============================================================================
Notes and scales.lua
============================================================================]]--

return {
arguments = {
  {
      name = "curr_key",
      value = 5,
      properties = {
          items = {
              "C",
              "C#",
              "D",
              "D#",
              "E",
              "F",
              "F#",
              "G",
              "G#",
              "A",
              "A#",
              "B",
          },
      },
      description = "Select a key for the scale",
  },
  {
      name = "curr_scale",
      value = 4,
      properties = {
          items = {
              "None",
              "Natural Major",
              "Natural Minor",
              "Pentatonic Major",
              "Pentatonic Minor",
              "Egyptian Pentatonic",
              "Pentatonic Egyptian",
              "Blues Major",
              "Blues Minor",
              "Whole Tone",
              "Augmented",
              "Prometheus",
              "Tritone",
              "Harmonic Major",
              "Harmonic Minor",
              "Melodic Minor",
              "All Minor",
              "Dorian",
              "Phrygian",
              "Phrygian Dominant",
              "Lydian",
              "Lydian Augmented",
              "Mixolydian",
              "Locrian",
              "Locrian Major",
              "Super Locrian",
              "Neapolitan Major",
              "Neapolitan Minor",
              "Neapolitan Minor",
              "Romanian Minor",
              "Spanish Gypsy",
              "Hungarian Gypsy",
              "Enigmatic",
              "Overtone",
              "Diminished Half",
              "Diminished Whole",
              "Spanish Eight-Tone",
              "Nine-Tone Scale",
          },
      },
      description = "Specify which scale to use",
  },
},
presets = {
},
data = {
},
callback = [[
-------------------------------------------------------------------------------
-- Restricting to a harmonic scale
-------------------------------------------------------------------------------

-- In this example we will harmonize existing notes within the first 
-- note-column, according to the selected scale. The actual work is being
-- done by a method called 'restrict_to_scale' in the xScale class. 

local existing_note = xline.note_columns[1].note_value

xline.note_columns[1].note_value =
  restrict_to_scale(existing_note,args.curr_scale,args.curr_key)


]],
}