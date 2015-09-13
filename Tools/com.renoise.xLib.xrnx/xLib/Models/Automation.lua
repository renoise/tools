--[[============================================================================
Automation.lua
============================================================================]]--

return {
arguments = {
  {
      name = "instr_idx",
      value = 1,
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
      name = "spread",
      value = 5,
      properties = {
          min = 0,
          quant = 1,
          max = 12,
      },
      description = "Control how much the second note column is offset in time",
  },
  {
      name = "volume",
      value = 128,
      properties = {
          max = 128,
          min = 0,
      },
      description = "Specify the general volume level",
  },
  {
      name = "env_A",
      value = 0,
      properties = {
          max = 1,
          min = 0,
      },
      description = "Control the first automation point in each line",
  },
  {
      name = "env_B",
      value = 0.33,
      properties = {
          max = 1,
          min = 0,
      },
      description = "Control the second automation point in each line",
  },
  {
      name = "env_C",
      value = 0.66,
      properties = {
          max = 1,
          min = 0,
      },
      description = "Control the third automation point in each line",
  },
  {
      name = "shuffle",
      value = 0.1,
      properties = {
          max = 1,
          min = 0,
      },
      description = "Control the amount of shuffle (delay on every second note)",
  },
  {
      name = "playmode",
      value = 2,
      properties = {
          items = {
              "POINTS",
              "LINEAR",
              "CUBIC",
          },
          impacts_buffer = false,
      },
      description = "Specify interpolation type for automation",
  },
},
data = {
},
callback = [[
-------------------------------------------------------------------------------
-- Automation (3 points per line)
-------------------------------------------------------------------------------

-- update automation interpolation in real-time -----------
if (xstream.automation_playmode ~= args.playmode) then
  xstream.automation_playmode = args.playmode
end

xline = {
  automation = {
    {
      time_offset = 0.0,
      value = args.env_A,
    },
    {
      time_offset = 0.33,
      value = args.env_B,
    },
    {
      time_offset = 0.66,
      value = args.env_C,
    },
  }
}

  

]],
}