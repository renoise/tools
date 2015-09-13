--[[============================================================================
Sequencer4.lua
============================================================================]]--

return {
arguments = {
  {
      name = "space",
      value = 4,
      properties = {
          display = "switch",
          items = {
              "1",
              "2",
              "4",
              "8",
              "16",
              "32",
              "64",
          },
      },
  },
  {
      name = "note1",
      value = 30.441860465116,
      properties = {
          min = 0,
          max = 119,
          display_as_note = true,
      },
  },
  {
      name = "note2",
      value = 106.54651162791,
      properties = {
          min = 0,
          max = 119,
          display_as_note = true,
      },
  },
  {
      name = "note3",
      value = 19.372093023256,
      properties = {
          min = 0,
          max = 119,
          display_as_note = true,
      },
  },
  {
      name = "note4",
      value = 35.069023255814,
      properties = {
          min = 0,
          max = 119,
          display_as_note = true,
      },
  },
  {
      name = "vol1",
      value = 16.244186046512,
      properties = {
          min = 0,
          max = 127,
          display_as_hex = true,
      },
  },
  {
      name = "vol2",
      value = 26.581395348837,
      properties = {
          min = 0,
          max = 127,
          display_as_hex = true,
      },
  },
  {
      name = "vol3",
      value = 100.41860465116,
      properties = {
          min = 0,
          max = 127,
          display_as_hex = true,
      },
  },
  {
      name = "vol4",
      value = 60,
      properties = {
          min = 0,
          max = 127,
          display_as_hex = true,
      },
  },
  {
      name = "trig1",
      value = 2,
      properties = {
          min = 1,
          max = 4,
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
      value = 4,
      properties = {
          min = 1,
          max = 4,
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
      value = 3,
      properties = {
          min = 1,
          max = 4,
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
      value = 1,
      properties = {
          min = 1,
          max = 4,
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
},
data = {
  trig_modes = {
      SKP = 7,
      FX1 = 5,
      OFF = 2,
      ON = 1,
      RPT = 4,
      CHD = 3,
      NIL = 6,
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
-------------------------------------------------------------------------------

-- Trigger options 
-- ON (Play note)
-- OFF (Note-off)
-- CHD ('Chord' - output all)
-- RPT (Repeat previous)
-- FX1 (Apply effect to note)
-- --- (NIL, Blank line)
-- ↷   (SKP, Skip this step)

-- Some global variables -----------------------

local spacing = data.intervals[args.space]
local seq_pos = xinc%spacing
local produce_output = (seq_pos == 0)

if produce_output then
  local global_step = math.floor(xinc/spacing)
  local num_steps = 0
  local skip_table = {}
  for i = 1,4 do
    if (args[("trig%d"):format(i)] ~= data.trig_modes.SKP) then
      num_steps = num_steps + 1
      table.insert(skip_table,i)
    end
  end
  local step = skip_table[(global_step%num_steps)+1] or 0
  
  xline.note_columns[1] = {
    note_value = args[("note%d"):format(step)],
    volume_value = args[("vol%d"):format(step)],
  }
else

  xline.note_columns[1] = {}
  
end  







]],
}