--[[===========================================================================
Granular.lua
===========================================================================]]--

return {
arguments = {
  {
      name = "start",
      value = 66,
      properties = {
          min = 0,
          display_as = "hex",
          max = 255,
      },
  },
  {
      name = "duration",
      value = 98,
      properties = {
          min = 0,
          display_as = "hex",
          max = 255,
      },
      description = "duration of process",
  },
  {
      name = "tempo",
      value = 1,
      properties = {
          min = 0,
          max = 8,
      },
      description = "Speed factor (0.5 = half, 1 = normal, 2 = double speed)",
  },
  {
      name = "vol_rnd",
      value = 37.832558139535,
      properties = {
          min = 0,
          display_as = "percent",
          max = 100,
      },
      description = "Amount of noise applied to volume",
  },
  {
      name = "pan_rnd",
      value = 76.920930232558,
      properties = {
          min = 0,
          display_as = "percent",
          max = 100,
      },
      description = "Amount of noise applied to panning",
  },
  {
      name = "dly_rnd",
      value = 83.172093023256,
      properties = {
          min = 0,
          display_as = "percent",
          max = 100,
      },
      description = "Amount of noise applied to delay",
  },
  {
      name = "pitch_rnd",
      value = 62.018604651163,
      properties = {
          min = 0,
          display_as = "percent",
          max = 100,
      },
      description = "Amount of detuning applied to notes",
  },
  {
      name = "offset_rnd",
      value = 0,
      properties = {
          min = 0,
          display_as = "percent",
          max = 100,
      },
      description = "Amount of noise applied to offset",
  },
  {
      name = "maybe_trig",
      value = 0,
      properties = {
          min = 0,
          display_as = "hex",
          max = 255,
      },
      description = "Probability that line is triggered",
  },
  {
      name = "pitch",
      value = 24.851627906977,
      properties = {
          max = 119,
          display_as = "note",
          min = 0,
      },
      description = "Note pitch",
  },
  {
      name = "instr_idx",
      value = 3,
      properties = {
          max = 255,
          min = 1,
          display_as = "hex",
          zero_based = true,
      },
      bind = "rns.selected_instrument_index_observable",
      description = "Specify the instrument number",
  },
  {
      name = "velocity",
      value = 84,
      properties = {
          min = 0,
          display_as = "hex",
          max = 127,
      },
      bind = "rns.transport.keyboard_velocity_observable",
      description = "Specify the keyboard velocity",
  },
  {
      name = "mode",
      value = 1,
      properties = {
          items = {
              "Forward",
              "Reverse",
              "Forward + 0Bxx",
              "Reverse + 0Bxx",
          },
      },
      description = "Playback mode",
  },
},
presets = {
  {
      pitch = 24.851627906977,
      pan_rnd = 76.920930232558,
      mode = 1,
      duration = 98,
      velocity = 84,
      instr_idx = 3,
      var2pitch = 1,
      pitch_rnd = 62.018604651163,
      offset_rnd = 0,
      name = "",
      dly_rnd = 83.172093023256,
      start = 66,
      vol_rnd = 37.832558139535,
      maybe_trig = 0,
      tempo = 1,
  },
  {
      pitch = 38.644558139535,
      pan_rnd = 78.06511627907,
      mode = 3,
      duration = 10,
      velocity = 84,
      instr_idx = 3,
      var2pitch = 1,
      pitch_rnd = 0,
      offset_rnd = 13.032558139535,
      name = "",
      dly_rnd = 73.972093023256,
      start = 42,
      vol_rnd = 82.558139534884,
      maybe_trig = 23,
      tempo = 0.1,
  },
  {
      pitch = 48.529860465116,
      pan_rnd = 57.051162790698,
      mode = 3,
      duration = 16,
      velocity = 84,
      instr_idx = 3,
      var2pitch = 1,
      pitch_rnd = 1.8139534883721,
      offset_rnd = 8,
      name = "",
      dly_rnd = 5.7023255813953,
      start = 8,
      vol_rnd = 26.744186046512,
      maybe_trig = 0,
      tempo = 0.56111627906977,
  },
  {
      instr_idx = 4,
      pan_rnd = 76.8,
      pitch = 41.511627906977,
      duration = 16,
      velocity = 84,
      mode = 1,
      var2pitch = 1,
      pitch_rnd = 62.018604651163,
      maybe_trig = 0,
      name = "",
      dly_rnd = 0,
      start = 0,
      vol_rnd = 1,
      offset_rnd = 0,
      tempo = 6,
  },
  {
      instr_idx = 3,
      pan_rnd = 7.5258644367809,
      pitch = 47.046511627907,
      velocity = 84,
      duration = 102.1027253029,
      vol_rnd = 29.947813348796,
      pitch_rnd = 81.731620227668,
      maybe_trig = 68.04773094882,
      name = "",
      dly_rnd = 31.82470168157,
      start = 243.51344340342,
      mode = 0,
      offset_rnd = 31.922360911893,
      tempo = 4.8053224280526,
  },
  {
      instr_idx = 3,
      pan_rnd = 76.8,
      pitch = 41.511627906977,
      velocity = 84,
      duration = 66,
      vol_rnd = 39.2,
      pitch_rnd = 90.33488372093,
      maybe_trig = 153,
      name = "",
      dly_rnd = 0,
      start = 4,
      mode = 1,
      offset_rnd = 0,
      tempo = 5.6803720930233,
  },
  {
      pitch = 49.725395348837,
      pan_rnd = 76.8,
      mode = 2,
      velocity = 84,
      duration = 27,
      instr_idx = 3,
      pitch_rnd = 84.455813953488,
      maybe_trig = 153,
      name = "",
      dly_rnd = 100,
      start = 43,
      vol_rnd = 100,
      offset_rnd = 0,
      tempo = 0.3,
  },
  {
      pitch = 0,
      pan_rnd = 76.8,
      mode = 2,
      velocity = 84,
      duration = 27,
      instr_idx = 3,
      pitch_rnd = 84.455813953488,
      maybe_trig = 153,
      name = "",
      dly_rnd = 100,
      start = 43,
      vol_rnd = 100,
      offset_rnd = 0,
      tempo = 0.3,
  },
  {
      pitch = 102.816,
      pan_rnd = 80,
      mode = 2,
      velocity = 84,
      duration = 64,
      instr_idx = 3,
      pitch_rnd = 80,
      maybe_trig = 153,
      name = "",
      dly_rnd = 8.4,
      start = 43,
      vol_rnd = 61.6,
      offset_rnd = 0,
      tempo = 0.3,
  },
  {
      pitch = 57.551720930233,
      pan_rnd = 38.372093023256,
      instr_idx = 3,
      velocity = 84,
      duration = 27,
      mode = 1,
      pitch_rnd = 0,
      offset_rnd = 8,
      name = "",
      dly_rnd = 98.037209302326,
      start = 43,
      vol_rnd = 22.325581395349,
      maybe_trig = 140,
      tempo = 0.3,
  },
},
data = {
  PLAYMODE = {
      REVERSE = 2,
      FORWARD = 1,
      FORWARD_Bxx = 3,
      REVERSE_Bxx = 4,
  },
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