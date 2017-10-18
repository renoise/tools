--[[===========================================================================
Notes and scales.lua
===========================================================================]]--

return {
arguments = {
  {
      ["locked"] = false,
      ["name"] = "curr_key",
      ["linked"] = false,
      ["value"] = 5,
      ["properties"] = {
          ["items"] = {
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
      ["description"] = "Select a key for the scale",
  },
  {
      ["locked"] = false,
      ["name"] = "curr_scale",
      ["linked"] = false,
      ["value"] = 4,
      ["properties"] = {
          ["items"] = {
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
      ["description"] = "Specify which scale to use",
  },
},
presets = {
},
data = {
},
events = {
},
options = {
 color = 0x69997A,
},
callback = [[
-----------------------------------------------------------------------------
-- Restricting to a harmonic scale
-- Try running this example on some existing notes. You will see that 
-- notes are being transformed into the selected key & scale. 
-- The actual work is being done by 'restrict_to_scale()', a helper 
-- method for xStream (OK, a little bit like cheating...)
-----------------------------------------------------------------------------

local existing_note = xline.note_columns[1].note_value
xline.note_columns[1].note_value =
  xScale.restrict_to_scale(existing_note,args.curr_scale,args.curr_key)
]],
}