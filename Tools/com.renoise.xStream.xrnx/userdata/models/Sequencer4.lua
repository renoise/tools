--[[===========================================================================
Sequencer4.lua
===========================================================================]]--

return {
arguments = {
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
      ["name"] = "space",
      ["linked"] = false,
      ["value"] = 2,
      ["properties"] = {
          ["items"] = {
              "1",
              "2",
              "4",
              "8",
              "16",
              "32",
              "64",
          },
          ["display_as"] = "switch",
      },
  },
  {
      ["locked"] = false,
      ["name"] = "note1",
      ["linked"] = false,
      ["value"] = 72.049348429823,
      ["properties"] = {
          ["max"] = 119,
          ["display_as"] = "note",
          ["min"] = 0,
      },
  },
  {
      ["locked"] = false,
      ["name"] = "note2",
      ["linked"] = false,
      ["value"] = 25.316599017304,
      ["properties"] = {
          ["max"] = 119,
          ["display_as"] = "note",
          ["min"] = 0,
      },
  },
  {
      ["locked"] = false,
      ["name"] = "note3",
      ["linked"] = false,
      ["value"] = 79.955565050203,
      ["properties"] = {
          ["max"] = 119,
          ["display_as"] = "note",
          ["min"] = 0,
      },
  },
  {
      ["locked"] = false,
      ["name"] = "note4",
      ["linked"] = false,
      ["value"] = 19.244392223884,
      ["properties"] = {
          ["max"] = 119,
          ["display_as"] = "note",
          ["min"] = 0,
      },
  },
  {
      ["locked"] = false,
      ["name"] = "vol1",
      ["linked"] = false,
      ["value"] = 58.304422132023,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "hex",
          ["max"] = 127,
      },
  },
  {
      ["locked"] = false,
      ["name"] = "vol2",
      ["linked"] = false,
      ["value"] = 83.86953337199,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "hex",
          ["max"] = 127,
      },
  },
  {
      ["locked"] = false,
      ["name"] = "vol3",
      ["linked"] = false,
      ["value"] = 11.988006225776,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "hex",
          ["max"] = 127,
      },
  },
  {
      ["locked"] = false,
      ["name"] = "vol4",
      ["linked"] = false,
      ["value"] = 28.588274788659,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "hex",
          ["max"] = 127,
      },
  },
  {
      ["locked"] = false,
      ["name"] = "trig1",
      ["linked"] = false,
      ["value"] = 3,
      ["properties"] = {
          ["display_as"] = "switch",
          ["items"] = {
              "ON",
              "OFF",
              "CHD",
              "RPT",
              "FX1",
              "---",
              "↷",
          },
      },
  },
  {
      ["locked"] = false,
      ["name"] = "trig2",
      ["linked"] = false,
      ["value"] = 3,
      ["properties"] = {
          ["display_as"] = "switch",
          ["items"] = {
              "ON",
              "OFF",
              "CHD",
              "RPT",
              "FX1",
              "---",
              "↷",
          },
      },
  },
  {
      ["locked"] = false,
      ["name"] = "trig3",
      ["linked"] = false,
      ["value"] = 7,
      ["properties"] = {
          ["display_as"] = "switch",
          ["items"] = {
              "ON",
              "OFF",
              "CHD",
              "RPT",
              "FX1",
              "---",
              "↷",
          },
      },
  },
  {
      ["locked"] = false,
      ["name"] = "trig4",
      ["linked"] = false,
      ["value"] = 3,
      ["properties"] = {
          ["display_as"] = "switch",
          ["items"] = {
              "ON",
              "OFF",
              "CHD",
              "RPT",
              "FX1",
              "---",
              "↷",
          },
      },
  },
  {
      ["locked"] = false,
      ["name"] = "repeat_ticks",
      ["linked"] = false,
      ["value"] = 12,
      ["properties"] = {
          ["max"] = 16,
          ["display_as"] = "integer",
          ["min"] = 1,
      },
  },
  {
      ["locked"] = false,
      ["name"] = "fx1_number",
      ["linked"] = false,
      ["value"] = 15,
      ["properties"] = {
          ["display_as"] = "popup",
          ["items"] = "xEffectColumn.SUPPORTED_EFFECTS",
      },
      ["description"] = "Choose among available FX commands",
  },
  {
      ["locked"] = false,
      ["name"] = "fx1_amt_x_",
      ["linked"] = false,
      ["value"] = 10,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "hex",
          ["max"] = 15,
      },
      ["description"] = "Choose FX amount (first digit)",
  },
  {
      ["locked"] = false,
      ["name"] = "fx1_amt__y",
      ["linked"] = false,
      ["value"] = 9,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "hex",
          ["max"] = 15,
      },
      ["description"] = "Choose FX amount (second digit)",
  },
},
presets = {
  {
      ["vol4"] = 99.777826086957,
      ["velocity"] = 84,
      ["fx1_amt_x_"] = 1.95,
      ["note4"] = 65.967391304348,
      ["trig4"] = 2,
      ["space"] = 3,
      ["fx1_number"] = 15,
      ["fx1_amt__y"] = 0,
      ["instr_idx"] = 2,
      ["note2"] = 37.614347826087,
      ["trig3"] = 5,
      ["note3"] = 89.25,
      ["name"] = "",
      ["note1"] = 56.654347826087,
      ["vol1"] = 89.28652173913,
      ["vol3"] = 74.101739130435,
      ["trig1"] = 3,
      ["vol2"] = 5.5217391304348,
      ["repeat_ticks"] = 1,
      ["trig2"] = 4,
  },
  {
      ["vol4"] = 15.792173913044,
      ["velocity"] = 84,
      ["fx1_amt_x_"] = 12,
      ["note4"] = 65.967391304348,
      ["trig4"] = 4,
      ["space"] = 3,
      ["fx1_number"] = 4,
      ["fx1_amt__y"] = 3,
      ["instr_idx"] = 2,
      ["note2"] = 37.614347826087,
      ["trig3"] = 4,
      ["note3"] = 89.25,
      ["name"] = "",
      ["note1"] = 56.654347826087,
      ["vol1"] = 89.28652173913,
      ["vol3"] = 42.79347826087,
      ["trig1"] = 3,
      ["vol2"] = 86.194347826087,
      ["repeat_ticks"] = 6,
      ["trig2"] = 5,
  },
  {
      ["vol4"] = 99.777826086957,
      ["velocity"] = 84,
      ["fx1_amt_x_"] = 11,
      ["note4"] = 65.967391304348,
      ["trig4"] = 5,
      ["space"] = 2,
      ["fx1_number"] = 15,
      ["fx1_amt__y"] = 10,
      ["instr_idx"] = 2,
      ["note2"] = 37.614347826087,
      ["trig3"] = 1,
      ["note3"] = 89.25,
      ["name"] = "",
      ["note1"] = 56.654347826087,
      ["vol1"] = 89.28652173913,
      ["vol3"] = 74.101739130435,
      ["trig1"] = 1,
      ["vol2"] = 60.07652173913,
      ["repeat_ticks"] = 4,
      ["trig2"] = 5,
  },
  {
      ["vol4"] = 88.071739130435,
      ["velocity"] = 84,
      ["fx1_amt_x_"] = 7.95,
      ["note4"] = 77.608695652174,
      ["trig4"] = 5,
      ["space"] = 2,
      ["fx1_number"] = 20,
      ["fx1_amt__y"] = 0,
      ["instr_idx"] = 3,
      ["note2"] = 82.782608695652,
      ["trig3"] = 3,
      ["note3"] = 73.159130434783,
      ["name"] = "",
      ["note1"] = 53.498260869565,
      ["vol1"] = 127,
      ["vol3"] = 96.52,
      ["trig1"] = 7,
      ["vol2"] = 54.057826086957,
      ["repeat_ticks"] = 9,
      ["trig2"] = 4,
  },
  {
      ["vol4"] = 88.071739130435,
      ["velocity"] = 84,
      ["fx1_amt_x_"] = 7.95,
      ["note4"] = 77.608695652174,
      ["trig4"] = 5,
      ["space"] = 2,
      ["fx1_number"] = 20,
      ["fx1_amt__y"] = 0,
      ["instr_idx"] = 3,
      ["note2"] = 82.782608695652,
      ["trig3"] = 3,
      ["note3"] = 85.059130434783,
      ["name"] = "",
      ["note1"] = 49.928260869565,
      ["vol1"] = 127,
      ["vol3"] = 97.127391304348,
      ["trig1"] = 7,
      ["vol2"] = 47.818260869565,
      ["repeat_ticks"] = 6,
      ["trig2"] = 4,
  },
  {
      ["vol4"] = 88.071739130435,
      ["velocity"] = 84,
      ["fx1_amt_x_"] = 7.95,
      ["note4"] = 77.608695652174,
      ["trig4"] = 5,
      ["space"] = 2,
      ["fx1_number"] = 20,
      ["fx1_amt__y"] = 0,
      ["instr_idx"] = 3,
      ["note2"] = 82.782608695652,
      ["trig3"] = 3,
      ["note3"] = 81.489130434783,
      ["name"] = "",
      ["note1"] = 54.688260869565,
      ["vol1"] = 89.28652173913,
      ["vol3"] = 97.127391304348,
      ["trig1"] = 7,
      ["vol2"] = 34.510869565217,
      ["repeat_ticks"] = 6,
      ["trig2"] = 4,
  },
  {
      ["vol4"] = 88.071739130435,
      ["velocity"] = 84,
      ["fx1_amt_x_"] = 7.95,
      ["note4"] = 77.608695652174,
      ["trig4"] = 5,
      ["space"] = 2,
      ["fx1_number"] = 20,
      ["fx1_amt__y"] = 0,
      ["instr_idx"] = 3,
      ["note2"] = 82.782608695652,
      ["trig3"] = 3,
      ["note3"] = 73.159130434783,
      ["name"] = "",
      ["note1"] = 53.498260869565,
      ["vol1"] = 127,
      ["vol3"] = 96.52,
      ["trig1"] = 7,
      ["vol2"] = 54.057826086957,
      ["repeat_ticks"] = 6,
      ["trig2"] = 4,
  },
  {
      ["vol4"] = 127,
      ["velocity"] = 84,
      ["fx1_amt_x_"] = 7.95,
      ["note4"] = 77.608695652174,
      ["trig4"] = 5,
      ["space"] = 2,
      ["fx1_number"] = 20,
      ["fx1_amt__y"] = 0,
      ["instr_idx"] = 3,
      ["note2"] = 82.782608695652,
      ["trig3"] = 3,
      ["note3"] = 73.159130434783,
      ["name"] = "",
      ["note1"] = 46.358260869565,
      ["vol1"] = 122.25130434783,
      ["vol3"] = 104.14,
      ["trig1"] = 7,
      ["vol2"] = 78.022173913044,
      ["repeat_ticks"] = 6,
      ["trig2"] = 4,
  },
  {
      ["vol4"] = 94.200869565217,
      ["velocity"] = 84,
      ["fx1_amt_x_"] = 0,
      ["note4"] = 77.608695652174,
      ["trig4"] = 5,
      ["space"] = 2,
      ["fx1_number"] = 2,
      ["fx1_amt__y"] = 0,
      ["instr_idx"] = 1,
      ["note2"] = 82,
      ["trig3"] = 3,
      ["note3"] = 73.159130434783,
      ["name"] = "",
      ["note1"] = 46.358260869565,
      ["vol1"] = 85.145217391304,
      ["vol3"] = 89.617826086957,
      ["trig1"] = 1,
      ["vol2"] = 127,
      ["repeat_ticks"] = 3,
      ["trig2"] = 4,
  },
  {
      ["vol4"] = 120.57383953368,
      ["velocity"] = 84,
      ["fx1_amt_x_"] = 5,
      ["note4"] = 70.255287331767,
      ["trig4"] = 5,
      ["space"] = 1,
      ["fx1_number"] = 15,
      ["fx1_amt__y"] = 6,
      ["instr_idx"] = 5,
      ["note2"] = 56.974150822474,
      ["trig3"] = 7,
      ["note3"] = 91.52652173913,
      ["name"] = "",
      ["note1"] = 27.085238196966,
      ["vol1"] = 82.199041718802,
      ["vol3"] = 99.954313791314,
      ["trig1"] = 1,
      ["vol2"] = 78.985961485641,
      ["repeat_ticks"] = 15,
      ["trig2"] = 3,
  },
  {
      ["vol4"] = 28.588274788659,
      ["velocity"] = 84,
      ["fx1_amt_x_"] = 10,
      ["note4"] = 19.244392223884,
      ["trig4"] = 3,
      ["space"] = 2,
      ["fx1_number"] = 15,
      ["fx1_amt__y"] = 9,
      ["instr_idx"] = 5,
      ["note2"] = 25.316599017304,
      ["trig3"] = 7,
      ["note3"] = 79.955565050203,
      ["name"] = "",
      ["note1"] = 72.049348429823,
      ["vol1"] = 58.304422132023,
      ["vol3"] = 11.988006225776,
      ["trig1"] = 3,
      ["repeat_ticks"] = 12,
      ["trig2"] = 3,
      ["vol2"] = 83.86953337199,
  },
},
data = {
  ["trig_modes"] = [[{
  ["BLANK"] = 6,
  ["CHORD"] = 3,
  ["OFF"] = 2,
  ["ON"] = 1,
  ["EFFECT"] = 5,
  ["REPEAT"] = 4,
  ["SKIP"] = 7,
}]],
  ["intervals"] = [[{
  1,
  2,
  4,
  8,
  16,
  32,
  64,
}]],
},
events = {
},
options = {
 color = 0x505552,
},
callback = [[
-------------------------------------------------------------------------------
-- A simple-ish step sequencer 
-- This sequencer is limited to four steps, but does some rather clever
-- things nevertheless. Outputs between 1-4 note columns and 1 effect column
-------------------------------------------------------------------------------
-- ## Trigger options
-- ON (normal note)
-- OFF (note-off)
-- CHORD (output all notes)
-- REPEAT (repeat previous)
-- EFFECT (apply effect to note)
-- BLANK ("---", blank line)
-- SKIP ("↷" skip this step)
-------------------------------------------------------------------------------
-- Now the code: 
local spacing = data.intervals[args.space]
local seq_pos = xinc%spacing
local produce_output = (seq_pos == 0)
if produce_output then
  local vol_factor = args.velocity/0x80
  local global_step = math.floor(xinc/spacing)
  local num_steps = 0
  local skip_table = {}
  for i = 1,4 do
    if (args[("trig%d"):format(i)] ~= data.trig_modes.SKIP) then
      num_steps = num_steps + 1
      table.insert(skip_table,i)
    end
  end
  local step = skip_table[(global_step%num_steps)+1] or 0
  local trig_value = args[("trig%d"):format(step)]
  --print("trig_value",trig_value)
  if (trig_value == data.trig_modes.ON) then
    xline = {
      note_columns = {
        {
          note_value = args[("note%d"):format(step)],
          instrument_value = args.instr_idx,
          volume_value = vol_factor*args[("vol%d"):format(step)],
        }
      }
    }    
  elseif (trig_value == data.trig_modes.OFF) then
    xline = {
      note_columns = {
        {
          note_value = NOTE_OFF_VALUE,
          instrument_value = args.instr_idx,
        }
      }
    }
  elseif (trig_value == data.trig_modes.CHORD) then
    xline = {
      note_columns = {
        {
          note_value = args.note1,
          instrument_value = args.instr_idx,
          volume_value = vol_factor*args.vol1,
        },
        {
          note_value = args.note2,
          instrument_value = args.instr_idx,
          volume_value = vol_factor*args.vol2,
        },
        {
          note_value = args.note3,
          instrument_value = args.instr_idx,
          volume_value = vol_factor*args.vol3,
        },
        {
          note_value = args.note4,
          instrument_value = args.instr_idx,
          volume_value = vol_factor*args.vol4,
        }
      }
    }
  elseif (trig_value == data.trig_modes.REPEAT) then    
      xline = {
          note_columns = {
          {
            note_value = args[("note%d"):format(step)],
            instrument_value = args.instr_idx,
            volume_value = vol_factor*args[("vol%d"):format(step)],
            panning_string = ("R%X"):format(args.repeat_ticks),
          }
        } 
      }
  elseif (trig_value == data.trig_modes.EFFECT) then
    xline = {
      note_columns = {
        {
          note_value = args[("note%d"):format(step)],
          instrument_value = args.instr_idx,
          volume_value = vol_factor*args[("vol%d"):format(step)],
        }
      },
      effect_columns = {
        {
          number_value = SUPPORTED_EFFECT_CHARS[args.fx1_number],
          amount_value = args.fx1_amt_x_ *16 + args.fx1_amt__y,
        }
      }
    }
  elseif (trig_value == data.trig_modes.BLANK) then  
    xline = {
      note_columns = {
        {
          note_value = EMPTY_NOTE_VALUE,
        }
      }
    }
  end  
else
  xline = EMPTY_XLINE
end
]],
}