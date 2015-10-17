--[[============================================================================
Automation.lua
============================================================================]]--

return {
arguments = {
  {
      name = "env_A",
      value = 0,
      properties = {
          min = 0,
          max = 1,
      },
      description = "Control the first automation point in each line",
  },
  {
      name = "env_B",
      value = 0.33,
      properties = {
          min = 0,
          max = 1,
      },
      description = "Control the second automation point in each line",
  },
  {
      name = "env_C",
      value = 0.66,
      properties = {
          min = 0,
          max = 1,
      },
      description = "Control the third automation point in each line",
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
presets = {
},
data = {
},
options = {
 color = 0x935180,
},
callback = [[
-------------------------------------------------------------------------------
-- Writing automation 
-- This model writes three values, equally distributed across line-time 
-- NB: xStream will automatically lock to the selected selected parameter 
-- in the Renoise automation editor - use this to target the output!!
--------------------------------------=============================------------
automation_playmode = args.playmode
xline.automation = {
  {time_offset = 0.0, value = args.env_A},
  {time_offset = 0.33,value = args.env_B},
  {time_offset = 0.66,value = args.env_C},
}




]],
}