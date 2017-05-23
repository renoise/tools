--[[===========================================================================
LFO test.lua
===========================================================================]]--

return {
arguments = {
  {
      ["description"] = "",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "amplitude",
      ["properties"] = {
          ["display_as"] = "percent",
          ["max"] = 100,
          ["min"] = 0,
      },
      ["value"] = 50,
  },
  {
      ["description"] = "",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "offset",
      ["properties"] = {
          ["display_as"] = "percent",
          ["max"] = 100,
          ["min"] = 0,
      },
      ["value"] = 50,
  },
  {
      ["description"] = "",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "period",
      ["properties"] = {
          ["display_as"] = "minislider",
          ["max"] = 64,
          ["min"] = 1,
      },
      ["value"] = 46.739726027397,
  },
  {
      ["description"] = "",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "shape",
      ["properties"] = {
          ["display_as"] = "chooser",
          ["items"] = {
              "sine",
              "triangle",
          },
          ["max"] = 2,
          ["min"] = 1,
      },
      ["value"] = 1,
  },
},
presets = {
  {
      ["amplitude"] = 50,
      ["name"] = "Sine wave",
      ["offset"] = 50,
      ["period"] = 8,
      ["shape"] = 1,
  },
  {
      ["amplitude"] = 50,
      ["name"] = "Triangle",
      ["offset"] = 50,
      ["period"] = 8,
      ["shape"] = 2,
  },
},
data = {
  ["compute_phase"] = [[-------------------------------------------------------------------------------
-- compute the phase of the LFO
-------------------------------------------------------------------------------
return function(xinc)
  print(">>> compute_phase - xinc",xinc)
  local period = args.period
  local phase = xinc%period/period  
  print(">>> phase + data.phase_offset",phase + data.phase_offset)
  return (phase + data.phase_offset)%1
end

-- alternative implementation which allows the lfo to 
-- reach the peak value (e.g. for the triangle)
-- local phase = xinc%period/(period-1)
-- phase = (phase == 1) and 0.999 or phase]],
  ["last_phase"] = [[-- return a value of some kind 
return 0]],
  ["phase_offset"] = [[-- stores the phase offset
-- (calculated when the period is changed)
return 0]],
  ["shapes"] = [[-- return the literal name of the shape,
-- as specified by the 'shape' argument
return {
  "sine",
  "triangle",
}]],
},
events = {
  ["args.period"] = [[------------------------------------------------------------------------------
-- respond to argument 'period' changes
-- @param val (number)
------------------------------------------------------------------------------
if xinc then
  print("*** period changed",val,xinc)
  local curr_phase = data.compute_phase(xinc)
  data.phase_offset = data.last_phase-curr_phase
  print("curr_phase",curr_phase)
  print("data.last_phase",data.last_phase)
  print("data.phase_offset",data.phase_offset)
end]],
},
options = {
 color = 0xA54A24,
},
callback = [[
-------------------------------------------------------------------------------
-- An implementation of xLFO 
-------------------------------------------------------------------------------
local phase = data.compute_phase(xinc) -- compute phase from position
local min = (args.offset - args.amplitude) / 100 -- apply offset/amplitude
local max = (args.amplitude + args.offset) / 100
local shape = data.shapes[args.shape]  -- get the shape (e.g. 'sine')
local val = xLFO[shape](phase,min,max) -- fetch the LFO value 

-- write to automation
xline.automation = {
  {time_offset = 0.0, value = cLib.clamp_value(val,0,1)},
}

-- remember the last phase
data.last_phase = phase


]],
}