--[[===========================================================================
Sequencer4.lua
===========================================================================]]--

return {
arguments = {
  {
      ["description"] = "",
      ["linked"] = false,
      ["locked"] = true,
      ["name"] = "instr_idx",
      ["properties"] = {
          ["display_as"] = "integer",
          ["max"] = 100,
          ["min"] = 0,
          ["zero_based"] = false,
      },
      ["value"] = 0,
  },
  {
      ["description"] = "",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "follow_instr",
      ["properties"] = {
          ["display_as"] = "checkbox",
      },
      ["value"] = true,
  },
  {
      ["bind"] = "rns.transport.keyboard_velocity_observable",
      ["description"] = "Specify the keyboard velocity",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "velocity",
      ["properties"] = {
          ["display_as"] = "minislider",
          ["max"] = 127,
          ["min"] = 0,
      },
      ["value"] = 84,
  },
  {
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "space",
      ["properties"] = {
          ["display_as"] = "switch",
          ["items"] = {
              "1",
              "2",
              "4",
              "8",
              "16",
              "32",
              "64",
          },
      },
      ["value"] = 2,
  },
  {
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "note1",
      ["properties"] = {
          ["display_as"] = "note",
          ["max"] = 119,
          ["min"] = 0,
      },
      ["value"] = 56.654347826087,
  },
  {
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "note2",
      ["properties"] = {
          ["display_as"] = "note",
          ["max"] = 119,
          ["min"] = 0,
      },
      ["value"] = 37.614347826087,
  },
  {
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "note3",
      ["properties"] = {
          ["display_as"] = "note",
          ["max"] = 119,
          ["min"] = 0,
      },
      ["value"] = 89.25,
  },
  {
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "note4",
      ["properties"] = {
          ["display_as"] = "note",
          ["max"] = 119,
          ["min"] = 0,
      },
      ["value"] = 65.967391304348,
  },
  {
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "vol1",
      ["properties"] = {
          ["display_as"] = "hex",
          ["max"] = 127,
          ["min"] = 0,
      },
      ["value"] = 89.28652173913,
  },
  {
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "vol2",
      ["properties"] = {
          ["display_as"] = "hex",
          ["max"] = 127,
          ["min"] = 0,
      },
      ["value"] = 60.07652173913,
  },
  {
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "vol3",
      ["properties"] = {
          ["display_as"] = "hex",
          ["max"] = 127,
          ["min"] = 0,
      },
      ["value"] = 74.101739130435,
  },
  {
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "vol4",
      ["properties"] = {
          ["display_as"] = "hex",
          ["max"] = 127,
          ["min"] = 0,
      },
      ["value"] = 99.777826086957,
  },
  {
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "trig1",
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
      ["value"] = 1,
  },
  {
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "trig2",
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
      ["value"] = 5,
  },
  {
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "trig3",
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
      ["value"] = 1,
  },
  {
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "trig4",
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
      ["value"] = 5,
  },
  {
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "repeat_ticks",
      ["properties"] = {
          ["display_as"] = "integer",
          ["max"] = 16,
          ["min"] = 1,
      },
      ["value"] = 4,
  },
  {
      ["description"] = "",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "strum_chord",
      ["properties"] = {
          ["display_as"] = "minislider",
          ["max"] = 64,
          ["min"] = 0,
      },
      ["value"] = 64,
  },
  {
      ["description"] = "Choose among available FX commands",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "fx1_number",
      ["properties"] = {
          ["display_as"] = "popup",
          ["items"] = "xEffectColumn.SUPPORTED_EFFECTS",
      },
      ["value"] = 15,
  },
  {
      ["description"] = "Choose FX amount (first digit)",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "fx1_amt_x_",
      ["properties"] = {
          ["display_as"] = "hex",
          ["max"] = 15,
          ["min"] = 0,
      },
      ["value"] = 11,
  },
  {
      ["description"] = "Choose FX amount (second digit)",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "fx1_amt__y",
      ["properties"] = {
          ["display_as"] = "hex",
          ["max"] = 15,
          ["min"] = 0,
      },
      ["value"] = 10,
  },
},
presets = {
  {
      ["follow_instr"] = true,
      ["fx1_amt__y"] = 0,
      ["fx1_amt_x_"] = 1.95,
      ["fx1_number"] = 15,
      ["instr_idx"] = 0,
      ["name"] = "Hesitant",
      ["note1"] = 56.654347826087,
      ["note2"] = 37.614347826087,
      ["note3"] = 89.25,
      ["note4"] = 65.967391304348,
      ["repeat_ticks"] = 1,
      ["space"] = 2,
      ["strum_chord"] = 64,
      ["trig1"] = 3,
      ["trig2"] = 4,
      ["trig3"] = 5,
      ["trig4"] = 2,
      ["velocity"] = 84,
      ["vol1"] = 89.28652173913,
      ["vol2"] = 5.5217391304348,
      ["vol3"] = 74.101739130435,
      ["vol4"] = 99.777826086957,
  },
  {
      ["fx1_amt__y"] = 3,
      ["fx1_amt_x_"] = 12,
      ["fx1_number"] = 4,
      ["instr_idx"] = 2,
      ["name"] = "Slide on Two",
      ["note1"] = 56.654347826087,
      ["note2"] = 37.614347826087,
      ["note3"] = 89.25,
      ["note4"] = 65.967391304348,
      ["repeat_ticks"] = 6,
      ["space"] = 3,
      ["trig1"] = 3,
      ["trig2"] = 5,
      ["trig3"] = 4,
      ["trig4"] = 4,
      ["velocity"] = 84,
      ["vol1"] = 89.28652173913,
      ["vol2"] = 86.194347826087,
      ["vol3"] = 42.79347826087,
      ["vol4"] = 15.792173913044,
  },
  {
      ["fx1_amt__y"] = 10,
      ["fx1_amt_x_"] = 11,
      ["fx1_number"] = 15,
      ["instr_idx"] = 2,
      ["name"] = "Straight",
      ["note1"] = 56.654347826087,
      ["note2"] = 37.614347826087,
      ["note3"] = 89.25,
      ["note4"] = 65.967391304348,
      ["repeat_ticks"] = 4,
      ["space"] = 2,
      ["trig1"] = 1,
      ["trig2"] = 5,
      ["trig3"] = 1,
      ["trig4"] = 5,
      ["velocity"] = 84,
      ["vol1"] = 89.28652173913,
      ["vol2"] = 60.07652173913,
      ["vol3"] = 74.101739130435,
      ["vol4"] = 99.777826086957,
  },
  {
      ["fx1_amt__y"] = 0,
      ["fx1_amt_x_"] = 7.95,
      ["fx1_number"] = 20,
      ["instr_idx"] = 3,
      ["name"] = "Waltz Pt1",
      ["note1"] = 53.498260869565,
      ["note2"] = 82.782608695652,
      ["note3"] = 73.159130434783,
      ["note4"] = 77.608695652174,
      ["repeat_ticks"] = 9,
      ["space"] = 2,
      ["trig1"] = 7,
      ["trig2"] = 4,
      ["trig3"] = 3,
      ["trig4"] = 5,
      ["velocity"] = 84,
      ["vol1"] = 127,
      ["vol2"] = 54.057826086957,
      ["vol3"] = 96.52,
      ["vol4"] = 88.071739130435,
  },
  {
      ["fx1_amt__y"] = 0,
      ["fx1_amt_x_"] = 7.95,
      ["fx1_number"] = 20,
      ["instr_idx"] = 3,
      ["name"] = "Waltz Expand",
      ["note1"] = 49.928260869565,
      ["note2"] = 82.782608695652,
      ["note3"] = 85.059130434783,
      ["note4"] = 77.608695652174,
      ["repeat_ticks"] = 6,
      ["space"] = 2,
      ["trig1"] = 7,
      ["trig2"] = 4,
      ["trig3"] = 3,
      ["trig4"] = 5,
      ["velocity"] = 84,
      ["vol1"] = 127,
      ["vol2"] = 47.818260869565,
      ["vol3"] = 97.127391304348,
      ["vol4"] = 88.071739130435,
  },
  {
      ["follow_instr"] = true,
      ["fx1_amt__y"] = 0,
      ["fx1_amt_x_"] = 7.95,
      ["fx1_number"] = 20,
      ["instr_idx"] = 0,
      ["name"] = "Waltz Pt2",
      ["note1"] = 54.688260869565,
      ["note2"] = 82.782608695652,
      ["note3"] = 81.489130434783,
      ["note4"] = 77.608695652174,
      ["repeat_ticks"] = 6,
      ["space"] = 2,
      ["strum_chord"] = 64,
      ["trig1"] = 7,
      ["trig2"] = 4,
      ["trig3"] = 3,
      ["trig4"] = 5,
      ["velocity"] = 84,
      ["vol1"] = 89.28652173913,
      ["vol2"] = 34.510869565217,
      ["vol3"] = 97.127391304348,
      ["vol4"] = 88.071739130435,
  },
  {
      ["fx1_amt__y"] = 0,
      ["fx1_amt_x_"] = 7.95,
      ["fx1_number"] = 20,
      ["instr_idx"] = 3,
      ["name"] = "Waltz Pt3",
      ["note1"] = 46.358260869565,
      ["note2"] = 82.782608695652,
      ["note3"] = 73.159130434783,
      ["note4"] = 77.608695652174,
      ["repeat_ticks"] = 6,
      ["space"] = 2,
      ["trig1"] = 7,
      ["trig2"] = 4,
      ["trig3"] = 3,
      ["trig4"] = 5,
      ["velocity"] = 84,
      ["vol1"] = 122.25130434783,
      ["vol2"] = 78.022173913044,
      ["vol3"] = 104.14,
      ["vol4"] = 127,
  },
  {
      ["follow_instr"] = true,
      ["fx1_amt__y"] = 0,
      ["fx1_amt_x_"] = 7.95,
      ["fx1_number"] = 20,
      ["instr_idx"] = 0,
      ["name"] = "Sweet Waltz",
      ["note1"] = 53.358260869565,
      ["note2"] = 80.782608695652,
      ["note3"] = 72.159130434783,
      ["note4"] = 77.608695652174,
      ["repeat_ticks"] = 6,
      ["space"] = 2,
      ["strum_chord"] = 64,
      ["trig1"] = 7,
      ["trig2"] = 4,
      ["trig3"] = 3,
      ["trig4"] = 5,
      ["velocity"] = 84,
      ["vol1"] = 122.25130434783,
      ["vol2"] = 78.022173913044,
      ["vol3"] = 104.14,
      ["vol4"] = 127,
  },
  {
      ["follow_instr"] = true,
      ["fx1_amt__y"] = 0,
      ["fx1_amt_x_"] = 0,
      ["fx1_number"] = 2,
      ["instr_idx"] = 0,
      ["name"] = "Tiny Sweets",
      ["note1"] = 46.358260869565,
      ["note2"] = 82,
      ["note3"] = 73.159130434783,
      ["note4"] = 77.608695652174,
      ["repeat_ticks"] = 3,
      ["space"] = 2,
      ["strum_chord"] = 64,
      ["trig1"] = 1,
      ["trig2"] = 4,
      ["trig3"] = 3,
      ["trig4"] = 5,
      ["velocity"] = 84,
      ["vol1"] = 85.145217391304,
      ["vol2"] = 127,
      ["vol3"] = 89.617826086957,
      ["vol4"] = 94.200869565217,
  },
  {
      ["follow_instr"] = true,
      ["fx1_amt__y"] = 6,
      ["fx1_amt_x_"] = 5,
      ["fx1_number"] = 15,
      ["instr_idx"] = 0,
      ["name"] = "Mantra in 3",
      ["note1"] = 27.085238196966,
      ["note2"] = 56.974150822474,
      ["note3"] = 91.52652173913,
      ["note4"] = 70.255287331767,
      ["repeat_ticks"] = 15,
      ["space"] = 1,
      ["strum_chord"] = 64,
      ["trig1"] = 1,
      ["trig2"] = 3,
      ["trig3"] = 7,
      ["trig4"] = 5,
      ["velocity"] = 84,
      ["vol1"] = 82.199041718802,
      ["vol2"] = 78.985961485641,
      ["vol3"] = 99.954313791314,
      ["vol4"] = 120.57383953368,
  },
  {
      ["fx1_amt__y"] = 0,
      ["fx1_amt_x_"] = 7.95,
      ["fx1_number"] = 20,
      ["instr_idx"] = 2,
      ["name"] = "Strumming",
      ["note1"] = 53.358260869565,
      ["note2"] = 80.782608695652,
      ["note3"] = 72.159130434783,
      ["note4"] = 77.608695652174,
      ["repeat_ticks"] = 6,
      ["space"] = 1,
      ["strum_chord"] = 64,
      ["trig1"] = 3,
      ["trig2"] = 3,
      ["trig3"] = 3,
      ["trig4"] = 3,
      ["velocity"] = 84,
      ["vol1"] = 122.25130434783,
      ["vol2"] = 78.022173913044,
      ["vol3"] = 104.14,
      ["vol4"] = 127,
  },
},
data = {
  ["intervals"] = [[{
  1,
  2,
  4,
  8,
  16,
  32,
  64,
}]],
  ["trig_modes"] = [[{
  ["BLANK"] = 6,
  ["CHORD"] = 3,
  ["OFF"] = 2,
  ["ON"] = 1,
  ["EFFECT"] = 5,
  ["REPEAT"] = 4,
  ["SKIP"] = 7,
}]],
},
events = {
  ["rns.selected_instrument_index_observable"] = [[------------------------------------------------------------------------------
-- respond to selected instrument in renoise 
------------------------------------------------------------------------------
if args.follow_instr then
 args.instr_idx = rns.selected_instrument_index-1
end]],
},
options = {
 color = 0x505552,
},
callback = [[
-------------------------------------------------------------------------------
-- Four step sequencer with FX module
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
          delay_value = args.strum_chord,
        },
        {
          note_value = args.note3,
          instrument_value = args.instr_idx,
          volume_value = vol_factor*args.vol3,
          delay_value = args.strum_chord*2,
        },
        {
          note_value = args.note4,
          instrument_value = args.instr_idx,
          volume_value = vol_factor*args.vol4,
          delay_value = args.strum_chord*3,
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