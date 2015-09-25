--[[============================================================================
Sequencer4.lua
============================================================================]]--

return {
arguments = {
  {
      name = "instr_idx",
      value = 2,
      properties = {
          min = 1,
          quant = 1,
          max = 255,
          zero_based = true,
          display_as_hex = true,
      },
      bind = "rns.selected_instrument_index_observable",
      description = "Specify the instrument number",
  },
  {
      name = "space",
      value = 2,
      properties = {
          items = {
              "1",
              "2",
              "4",
              "8",
              "16",
              "32",
              "64",
          },
          display = "switch",
      },
  },
  {
      name = "note1",
      value = 56.654347826087,
      properties = {
          max = 119,
          min = 0,
          display_as_note = true,
      },
  },
  {
      name = "note2",
      value = 37.614347826087,
      properties = {
          max = 119,
          min = 0,
          display_as_note = true,
      },
  },
  {
      name = "note3",
      value = 89.25,
      properties = {
          max = 119,
          min = 0,
          display_as_note = true,
      },
  },
  {
      name = "note4",
      value = 65.967391304348,
      properties = {
          max = 119,
          min = 0,
          display_as_note = true,
      },
  },
  {
      name = "vol1",
      value = 89.28652173913,
      properties = {
          min = 0,
          max = 127,
          display_as_hex = true,
      },
  },
  {
      name = "vol2",
      value = 60.07652173913,
      properties = {
          min = 0,
          max = 127,
          display_as_hex = true,
      },
  },
  {
      name = "vol3",
      value = 74.101739130435,
      properties = {
          min = 0,
          max = 127,
          display_as_hex = true,
      },
  },
  {
      name = "vol4",
      value = 99.777826086957,
      properties = {
          min = 0,
          max = 127,
          display_as_hex = true,
      },
  },
  {
      name = "trig1",
      value = 5,
      properties = {
          max = 4,
          min = 1,
          display = "switch",
          items = {
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
      name = "trig2",
      value = 5,
      properties = {
          max = 4,
          min = 1,
          display = "switch",
          items = {
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
      name = "trig3",
      value = 5,
      properties = {
          max = 4,
          min = 1,
          display = "switch",
          items = {
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
      name = "trig4",
      value = 4,
      properties = {
          max = 4,
          min = 1,
          display = "switch",
          items = {
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
      name = "repeat_ticks",
      value = 4,
      properties = {
          max = 16,
          quant = 1,
          min = 1,
      },
  },
  {
      name = "fx1_number",
      value = 15,
      properties = {
          display = "popup",
          items = "xEffectColumn.SUPPORTED_EFFECTS",
      },
      description = "Choose among available FX commands",
  },
  {
      name = "fx1_amt_x_",
      value = 8,
      properties = {
          min = 0,
          max = 15,
          quant = 1,
          display_as_hex = true,
      },
      description = "Choose FX amount (first digit)",
  },
  {
      name = "fx1_amt__y",
      value = 10,
      properties = {
          min = 0,
          max = 15,
          quant = 1,
          display_as_hex = true,
      },
      description = "Choose FX amount (second digit)",
  },
},
presets = {
  {
      vol4 = 99.777826086957,
      fx1_amt_x_ = 1.95,
      note4 = 65.967391304348,
      trig4 = 2,
      space = 3,
      fx1_number = 15,
      fx1_amt__y = 0,
      instr_idx = 2,
      note1 = 56.654347826087,
      trig3 = 5,
      note3 = 89.25,
      repeat_ticks = 1,
      vol1 = 89.28652173913,
      vol3 = 74.101739130435,
      trig1 = 3,
      vol2 = 5.5217391304348,
      note2 = 37.614347826087,
      trig2 = 4,
  },
  {
      vol4 = 15.792173913044,
      fx1_amt_x_ = 12,
      note4 = 65.967391304348,
      trig4 = 4,
      space = 3,
      fx1_number = 4,
      fx1_amt__y = 3,
      instr_idx = 2,
      note1 = 56.654347826087,
      trig3 = 4,
      note3 = 89.25,
      repeat_ticks = 6,
      vol1 = 89.28652173913,
      vol3 = 42.79347826087,
      trig1 = 3,
      vol2 = 86.194347826087,
      note2 = 37.614347826087,
      trig2 = 5,
  },
  {
      vol4 = 99.777826086957,
      fx1_amt_x_ = 8,
      note4 = 65.967391304348,
      trig4 = 4,
      space = 2,
      fx1_number = 14,
      fx1_amt__y = 10,
      instr_idx = 2,
      note1 = 56.654347826087,
      trig3 = 5,
      note3 = 89.25,
      repeat_ticks = 4,
      vol1 = 89.28652173913,
      vol3 = 74.101739130435,
      trig1 = 5,
      vol2 = 60.07652173913,
      note2 = 37.614347826087,
      trig2 = 5,
  },
  {
      vol4 = 88.071739130435,
      fx1_amt_x_ = 7.95,
      note4 = 77.608695652174,
      trig4 = 5,
      space = 2,
      fx1_number = 20,
      fx1_amt__y = 0,
      instr_idx = 3,
      note1 = 53.498260869565,
      trig3 = 3,
      note3 = 73.159130434783,
      repeat_ticks = 9,
      vol1 = 127,
      vol3 = 96.52,
      trig1 = 7,
      vol2 = 54.057826086957,
      note2 = 82.782608695652,
      trig2 = 4,
  },
  {
      vol4 = 88.071739130435,
      fx1_amt_x_ = 7.95,
      note4 = 77.608695652174,
      trig4 = 5,
      space = 2,
      fx1_number = 20,
      fx1_amt__y = 0,
      instr_idx = 3,
      note1 = 49.928260869565,
      trig3 = 3,
      note3 = 85.059130434783,
      repeat_ticks = 6,
      vol1 = 127,
      vol3 = 97.127391304348,
      trig1 = 7,
      vol2 = 47.818260869565,
      note2 = 82.782608695652,
      trig2 = 4,
  },
  {
      vol4 = 88.071739130435,
      fx1_amt_x_ = 7.95,
      note4 = 77.608695652174,
      trig4 = 5,
      space = 2,
      fx1_number = 20,
      fx1_amt__y = 0,
      instr_idx = 3,
      note1 = 54.688260869565,
      trig3 = 3,
      note3 = 81.489130434783,
      repeat_ticks = 6,
      vol1 = 89.28652173913,
      vol3 = 97.127391304348,
      trig1 = 7,
      vol2 = 34.510869565217,
      note2 = 82.782608695652,
      trig2 = 4,
  },
  {
      vol4 = 88.071739130435,
      fx1_amt_x_ = 7.95,
      note4 = 77.608695652174,
      trig4 = 5,
      space = 2,
      fx1_number = 20,
      fx1_amt__y = 0,
      instr_idx = 2,
      note1 = 53.498260869565,
      trig3 = 3,
      note3 = 73.159130434783,
      repeat_ticks = 6,
      vol1 = 127,
      vol3 = 96.52,
      trig1 = 7,
      vol2 = 54.057826086957,
      note2 = 82.782608695652,
      trig2 = 4,
  },
  {
      vol4 = 127,
      fx1_amt_x_ = 7.95,
      note4 = 77.608695652174,
      trig4 = 5,
      space = 2,
      fx1_number = 20,
      fx1_amt__y = 0,
      instr_idx = 2,
      note1 = 46.358260869565,
      trig3 = 3,
      note3 = 73.159130434783,
      repeat_ticks = 6,
      vol1 = 122.25130434783,
      vol3 = 104.14,
      trig1 = 7,
      vol2 = 78.022173913044,
      note2 = 82.782608695652,
      trig2 = 4,
  },
  {
      vol4 = 94.200869565217,
      fx1_amt_x_ = 0,
      note4 = 77.608695652174,
      trig4 = 5,
      space = 2,
      fx1_number = 2,
      fx1_amt__y = 0,
      instr_idx = 1,
      note1 = 46.358260869565,
      trig3 = 3,
      note3 = 73.159130434783,
      repeat_ticks = 3,
      vol1 = 85.145217391304,
      vol3 = 89.617826086957,
      trig1 = 1,
      vol2 = 127,
      note2 = 82,
      trig2 = 4,
  },
},
data = {
  trig_modes = {
      BLANK = 6,
      CHORD = 3,
      OFF = 2,
      ON = 1,
      EFFECT = 5,
      REPEAT = 4,
      SKIP = 7,
  },
  intervals = {
      1,
      2,
      4,
      8,
      16,
      32,
      64,
  },
},
callback = [[
-------------------------------------------------------------------------------
-- A small step sequencer 
-- Will output between 1-4 note columns and 1 effect column
-------------------------------------------------------------------------------

-- ## Trigger options
-- ON (normal note)
-- OFF (note-off)
-- CHORD (output all notes)
-- REPEAT (repeat previous)
-- EFFECT (apply effect to note)
-- BLANK ("---", blank line)
-- SKIP ("↷" skip this step)

-- Some global variables -----------------------

local spacing = data.intervals[args.space]
local seq_pos = xinc%spacing
local produce_output = (seq_pos == 0)

if produce_output then
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
          volume_value = args[("vol%d"):format(step)],
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
          volume_value = args.vol1,
        },
        {
          note_value = args.note2,
          instrument_value = args.instr_idx,
          volume_value = args.vol2,
        },
        {
          note_value = args.note3,
          instrument_value = args.instr_idx,
          volume_value = args.vol3,
        },
        {
          note_value = args.note4,
          instrument_value = args.instr_idx,
          volume_value = args.vol4,
        }
      }
    }
  elseif (trig_value == data.trig_modes.REPEAT) then    
  
      xline = {
          note_columns = {
          {
            note_value = args[("note%d"):format(step)],
            instrument_value = args.instr_idx,
            volume_value = args[("vol%d"):format(step)],
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
          volume_value = args[("vol%d"):format(step)],
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