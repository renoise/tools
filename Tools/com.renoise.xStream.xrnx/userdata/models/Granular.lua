--[[===========================================================================
Granular.lua
===========================================================================]]--

return {
arguments = {
  {
      ["locked"] = false,
      ["name"] = "start",
      ["linked"] = false,
      ["value"] = 66,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "hex",
          ["max"] = 255,
      },
  },
  {
      ["locked"] = false,
      ["name"] = "duration",
      ["linked"] = false,
      ["value"] = 98,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "hex",
          ["max"] = 255,
      },
      ["description"] = "duration of process",
  },
  {
      ["locked"] = false,
      ["name"] = "tempo",
      ["linked"] = false,
      ["value"] = 1,
      ["properties"] = {
          ["min"] = 0,
          ["max"] = 8,
      },
      ["description"] = "Speed factor (0.5 = half, 1 = normal, 2 = double speed)",
  },
  {
      ["locked"] = false,
      ["name"] = "vol_rnd",
      ["linked"] = false,
      ["value"] = 37.832558139535,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "percent",
          ["max"] = 100,
      },
      ["description"] = "Amount of noise applied to volume",
  },
  {
      ["locked"] = false,
      ["name"] = "pan_rnd",
      ["linked"] = false,
      ["value"] = 76.920930232558,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "percent",
          ["max"] = 100,
      },
      ["description"] = "Amount of noise applied to panning",
  },
  {
      ["locked"] = false,
      ["name"] = "dly_rnd",
      ["linked"] = false,
      ["value"] = 83.172093023256,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "percent",
          ["max"] = 100,
      },
      ["description"] = "Amount of noise applied to delay",
  },
  {
      ["locked"] = false,
      ["name"] = "pitch_rnd",
      ["linked"] = false,
      ["value"] = 62.018604651163,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "percent",
          ["max"] = 100,
      },
      ["description"] = "Amount of detuning applied to notes",
  },
  {
      ["locked"] = false,
      ["name"] = "offset_rnd",
      ["linked"] = false,
      ["value"] = 0,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "percent",
          ["max"] = 100,
      },
      ["description"] = "Amount of noise applied to offset",
  },
  {
      ["locked"] = false,
      ["name"] = "maybe_trig",
      ["linked"] = false,
      ["value"] = 0,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "hex",
          ["max"] = 255,
      },
      ["description"] = "Probability that line is triggered",
  },
  {
      ["locked"] = false,
      ["name"] = "pitch",
      ["linked"] = false,
      ["value"] = 24.851627906977,
      ["properties"] = {
          ["max"] = 119,
          ["display_as"] = "note",
          ["min"] = 0,
      },
      ["description"] = "Note pitch",
  },
  {
      ["locked"] = false,
      ["name"] = "instr_idx",
      ["linked"] = false,
      ["value"] = 1,
      ["properties"] = {
          ["min"] = 1,
          ["max"] = 255,
          ["display_as"] = "hex",
          ["zero_based"] = true,
      },
      ["bind"] = "rns.selected_instrument_index_observable",
      ["description"] = "Specify the instrument number",
  },
  {
      ["locked"] = false,
      ["name"] = "velocity",
      ["linked"] = false,
      ["value"] = 69,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "hex",
          ["max"] = 127,
      },
      ["bind"] = "rns.transport.keyboard_velocity_observable",
      ["description"] = "Specify the keyboard velocity",
  },
  {
      ["locked"] = false,
      ["name"] = "mode",
      ["linked"] = false,
      ["value"] = 1,
      ["properties"] = {
          ["items"] = {
              "Forward",
              "Reverse",
              "Forward + 0Bxx",
              "Reverse + 0Bxx",
          },
      },
      ["description"] = "Playback mode",
  },
},
presets = {
  {
      ["instr_idx"] = 3,
      ["pan_rnd"] = 76.920930232558,
      ["vol_rnd"] = 37.832558139535,
      ["duration"] = 98,
      ["velocity"] = 84,
      ["offset_rnd"] = 0,
      ["var2pitch"] = 1,
      ["pitch_rnd"] = 62.018604651163,
      ["maybe_trig"] = 0,
      ["name"] = "",
      ["dly_rnd"] = 83.172093023256,
      ["start"] = 66,
      ["mode"] = 1,
      ["pitch"] = 24.851627906977,
      ["tempo"] = 1,
  },
  {
      ["instr_idx"] = 3,
      ["pan_rnd"] = 78.06511627907,
      ["vol_rnd"] = 82.558139534884,
      ["duration"] = 10,
      ["velocity"] = 84,
      ["offset_rnd"] = 13.032558139535,
      ["var2pitch"] = 1,
      ["pitch_rnd"] = 0,
      ["maybe_trig"] = 23,
      ["name"] = "",
      ["dly_rnd"] = 73.972093023256,
      ["start"] = 42,
      ["mode"] = 3,
      ["pitch"] = 38.644558139535,
      ["tempo"] = 0.1,
  },
  {
      ["instr_idx"] = 3,
      ["pan_rnd"] = 57.051162790698,
      ["vol_rnd"] = 26.744186046512,
      ["duration"] = 16,
      ["velocity"] = 84,
      ["offset_rnd"] = 8,
      ["var2pitch"] = 1,
      ["pitch_rnd"] = 1.8139534883721,
      ["maybe_trig"] = 0,
      ["name"] = "",
      ["dly_rnd"] = 5.7023255813953,
      ["start"] = 8,
      ["mode"] = 3,
      ["pitch"] = 48.529860465116,
      ["tempo"] = 0.56111627906977,
  },
  {
      ["instr_idx"] = 4,
      ["pan_rnd"] = 76.8,
      ["vol_rnd"] = 1,
      ["duration"] = 16,
      ["velocity"] = 84,
      ["maybe_trig"] = 0,
      ["var2pitch"] = 1,
      ["pitch_rnd"] = 62.018604651163,
      ["offset_rnd"] = 0,
      ["name"] = "",
      ["dly_rnd"] = 0,
      ["start"] = 0,
      ["mode"] = 1,
      ["pitch"] = 41.511627906977,
      ["tempo"] = 6,
  },
  {
      ["instr_idx"] = 3,
      ["pan_rnd"] = 7.5258644367809,
      ["mode"] = 0,
      ["duration"] = 102.1027253029,
      ["velocity"] = 84,
      ["pitch"] = 47.046511627907,
      ["pitch_rnd"] = 81.731620227668,
      ["offset_rnd"] = 31.922360911893,
      ["name"] = "",
      ["dly_rnd"] = 31.82470168157,
      ["start"] = 243.51344340342,
      ["vol_rnd"] = 29.947813348796,
      ["maybe_trig"] = 68.04773094882,
      ["tempo"] = 4.8053224280526,
  },
  {
      ["instr_idx"] = 3,
      ["pan_rnd"] = 76.8,
      ["mode"] = 1,
      ["duration"] = 66,
      ["velocity"] = 84,
      ["pitch"] = 41.511627906977,
      ["pitch_rnd"] = 90.33488372093,
      ["offset_rnd"] = 0,
      ["name"] = "",
      ["dly_rnd"] = 0,
      ["start"] = 4,
      ["vol_rnd"] = 39.2,
      ["maybe_trig"] = 153,
      ["tempo"] = 5.6803720930233,
  },
  {
      ["instr_idx"] = 3,
      ["pan_rnd"] = 76.8,
      ["vol_rnd"] = 100,
      ["duration"] = 27,
      ["velocity"] = 84,
      ["maybe_trig"] = 153,
      ["pitch_rnd"] = 84.455813953488,
      ["offset_rnd"] = 0,
      ["name"] = "",
      ["dly_rnd"] = 100,
      ["start"] = 43,
      ["mode"] = 2,
      ["pitch"] = 49.725395348837,
      ["tempo"] = 0.3,
  },
  {
      ["instr_idx"] = 3,
      ["pan_rnd"] = 76.8,
      ["vol_rnd"] = 100,
      ["duration"] = 27,
      ["velocity"] = 84,
      ["maybe_trig"] = 153,
      ["pitch_rnd"] = 84.455813953488,
      ["offset_rnd"] = 0,
      ["name"] = "",
      ["dly_rnd"] = 100,
      ["start"] = 43,
      ["mode"] = 2,
      ["pitch"] = 0,
      ["tempo"] = 0.3,
  },
  {
      ["instr_idx"] = 3,
      ["pan_rnd"] = 80,
      ["vol_rnd"] = 61.6,
      ["duration"] = 64,
      ["velocity"] = 84,
      ["maybe_trig"] = 153,
      ["pitch_rnd"] = 80,
      ["offset_rnd"] = 0,
      ["name"] = "",
      ["dly_rnd"] = 8.4,
      ["start"] = 43,
      ["mode"] = 2,
      ["pitch"] = 102.816,
      ["tempo"] = 0.3,
  },
  {
      ["pitch"] = 57.551720930233,
      ["pan_rnd"] = 38.372093023256,
      ["vol_rnd"] = 22.325581395349,
      ["duration"] = 27,
      ["velocity"] = 84,
      ["instr_idx"] = 3,
      ["pitch_rnd"] = 0,
      ["maybe_trig"] = 140,
      ["name"] = "",
      ["dly_rnd"] = 98.037209302326,
      ["start"] = 43,
      ["mode"] = 1,
      ["offset_rnd"] = 8,
      ["tempo"] = 0.3,
  },
},
data = {
  ["PLAYMODE"] = [[{
  ["REVERSE_Bxx"] = 4,
  ["FORWARD"] = 1,
  ["FORWARD_Bxx"] = 3,
  ["REVERSE"] = 2,
}]],
},
events = {
},
options = {
 color = 0xCA8759,
},
callback = [[
-------------------------------------------------------------------------------
-- Granular model
-- Output: 1 note column (vol+pan+dly), multiple effect columns
-- Listening to the keyboard velocity and selected instrument 
-- Tip: Increase density by playing at higher speeds
-------------------------------------------------------------------------------

local forward = (args.mode == data.PLAYMODE.FORWARD)
  or (args.mode == data.PLAYMODE.FORWARD_Bxx)
local write_bxx = (args.mode == data.PLAYMODE.FORWARD_Bxx)
  or (args.mode == data.PLAYMODE.REVERSE_Bxx)
local my_xinc = forward and xinc or -xinc
local pos = args.start + (my_xinc*args.tempo)%args.duration
local sample_offset = pos + math.random(0,args.offset_rnd)
local pan_scaled = args.pan_rnd/100*0x40
local pan_rnd = math.random(-pan_scaled,pan_scaled)
local do_pitch = (args.pitch_rnd > 0)
local pitch_scaled = args.pitch_rnd/100*0xFF
local pitch_rnd = math.random(-pitch_scaled,pitch_scaled)
local volume_rnd = math.random(0,args.vol_rnd/100*0x80)
local delay_rnd = math.random(0,args.dly_rnd/100*0xFF)
--
xline.note_columns[1] = {
  note_value =args.pitch,
  instrument_value = args.instr_idx,
  volume_value = args.velocity-(volume_rnd*(args.velocity/0x80)),
  panning_value = (pan_rnd ~= 0) and 0x40+pan_rnd or 255,
  delay_value = (delay_rnd > 0) and delay_rnd or 0,
}
xline.effect_columns[1] = {
  number_string = "0S",
  amount_value = sample_offset%0xFF
}
xline.effect_columns[2] = {
  number_string = write_bxx and "0B" or "00",
  amount_string = write_bxx and "00" or "00"
}
xline.effect_columns[3] = {
  number_string = do_pitch and ((pitch_rnd > 0) 
    and "0U" or "0D") or "00",
  amount_value = do_pitch and ((pitch_rnd > 0) 
    and pitch_rnd or math.abs(pitch_rnd)) or 0
}
xline.effect_columns[4] = {
  number_string = (args.maybe_trig > 0) and "0Y" or "00",
  amount_value = args.maybe_trig
}
]],
}