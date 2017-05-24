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
      ["value"] = 5.032,
  },
  {
      ["description"] = "",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "shift",
      ["properties"] = {
          ["display_as"] = "percent",
          ["max"] = 100,
          ["min"] = 0,
      },
      ["value"] = 0,
  },
  {
      ["description"] = "",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "highres",
      ["properties"] = {
          ["display_as"] = "checkbox",
      },
      ["value"] = true,
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
              "square",
          },
          ["max"] = 3,
          ["min"] = 1,
      },
      ["value"] = 3,
  },
},
presets = {
  {
      ["amplitude"] = 50,
      ["name"] = "Sine@16",
      ["offset"] = 50,
      ["period"] = 16,
      ["shape"] = 1,
      ["shift"] = 0,
  },
  {
      ["amplitude"] = 50,
      ["name"] = "Sine@8",
      ["offset"] = 50,
      ["period"] = 8,
      ["shape"] = 1,
      ["shift"] = 0,
  },
  {
      ["amplitude"] = 50,
      ["name"] = "Triangle@8",
      ["offset"] = 50,
      ["period"] = 8,
      ["shape"] = 2,
      ["shift"] = 0,
  },
},
data = {
  ["compute_phase"] = [[-------------------------------------------------------------------------------
-- compute the phase of the LFO
-------------------------------------------------------------------------------
return function(xinc,period,offset)
  local phase = xinc%period/period  
  local offset = offset or 0
  local shift = args.shift/100
  local phase = (phase + shift + offset) % 1
  return phase
end]],
  ["curr_phase"] = [[-- store the current phase here
return nil]],
  ["last_period"] = [[-- store the last set period here
return nil]],
  ["phase_offset"] = [[-- the current phase offset
-- (calculated when the period is changed)
return 0]],
  ["prev_phases"] = [[-- previous phases can be accessed by the xinc
-- (the table is maintained using the 'store_phase' method)
return {}]],
  ["shapes"] = [[-- return the literal name of the shape,
-- as specified by the 'shape' argument
return {
  "sine",
  "triangle",
  "square",
}]],
  ["store_phase"] = [[-------------------------------------------------------------------------------
-- function to store previous phases 
-- note: as new entries are added, we purge old ones
-------------------------------------------------------------------------------
return function(xinc,phase)
  
  -- store the phase 
  data.prev_phases[xinc] = phase
  
  -- purge old values  
  local keep_count = 10 
  local purge_until = data.purge_until or xinc - keep_count
  for k = xinc-keep_count, purge_until, -1 do
    data.prev_phases[k] = nil
  end
  data.purge_until = xinc - keep_count
  
end]],
},
events = {
  ["args.period"] = [[------------------------------------------------------------------------------
-- respond to argument 'period' changes
-- @param val (number)
------------------------------------------------------------------------------
if xinc then -- output has started
  
  -- figure out the xinc at which the change *actually* happened - 
  -- necessary since 'xinc' is always ahead by the 'writeahead'      
  local curr_xinc = xinc - xStreamPos.determine_writeahead() + 1
  local curr_phase = data.compute_phase(curr_xinc,val)
  local prev_phase = data.prev_phases[curr_xinc]
  data.phase_offset = prev_phase - curr_phase
  
end]],
},
options = {
 color = 0xA54A24,
},
callback = [[
-------------------------------------------------------------------------------
-- Using xLFO to control the selected parameter 
-- Demonstrates the following things:
-- * How to use the xLFO class as a basic oscillator
-- * How to write automation to the selected parameter
-- * How to maintain movement (phase) over time. This is the tricky part!
-------------------------------------------------------------------------------

-- initialize a bunch of parameters 
local offset = data.phase_offset or 0
local phase = data.compute_phase(xinc,args.period,offset) -- compute phase
local min = (args.offset - args.amplitude) / 100 -- apply offset/amplitude
local max = (args.amplitude + args.offset) / 100
local shape = data.shapes[args.shape]  -- get the shape (e.g. 'sine')

-- write to automation 
if not args.highres then  
  -- "lo-res" mode - 1 value per line 
  local val = xLFO[shape](phase,min,max) -- fetch the LFO value 
  xline.automation = {
    {time_offset = 0.0, value = cLib.clamp_value(val,0,1)},
  }
else 
  -- highres mode: 4 values per line
  local step = 1/args.period
  local val1 = xLFO[shape](phase,min,max) 
  local val2 = xLFO[shape](phase+0.25*step,min,max) 
  local val3 = xLFO[shape](phase+0.5*step,min,max) 
  local val4 = xLFO[shape](phase+0.75*step,min,max) 
  xline.automation = {
    {time_offset = 0.0, value = cLib.clamp_value(val1,0,1)},
    {time_offset = 0.25, value = cLib.clamp_value(val2,0,1)},
    {time_offset = 0.50, value = cLib.clamp_value(val3,0,1)},
    {time_offset = 0.75, value = cLib.clamp_value(val4,0,1)},
  }
end
  
-- remember the phase - used for maintaining the 
-- phase while changing the period/frequency...
data.store_phase(xinc,phase)
]],
}