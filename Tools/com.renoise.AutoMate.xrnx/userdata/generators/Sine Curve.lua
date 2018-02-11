--[[===========================================================================
 AutoMateGenerator (http://www.example.com)
===========================================================================]]--

return {
  ["__type"] = "AutoMateGenerator",
  ["__version"] = 0,
  ["name"] = "Sine Curve",
  ["arguments"] = {
    {
      ["__type"] = "AutoMateSandboxArgument",
      ["name"] = "density",
      ["value"] = 1,
      ["value_min"] = -512,
      ["value_max"] = 256,
      ["value_quantum"] = 0,
      ["display_as"] = "valuebox",
    },
    {
      ["__type"] = "AutoMateSandboxArgument",
      ["name"] = "cycles",
      ["value"] = 1,
      ["value_min"] = 1,
      ["value_max"] = 512,
      ["value_quantum"] = 0,
      ["display_as"] = "valuebox",
    },
    {
      ["__type"] = "AutoMateSandboxArgument",
      ["name"] = "center",
      ["value"] = 0,
      ["value_min"] = -100,
      ["value_max"] = 100,
      ["value_quantum"] = 0,
      ["display_as"] = "valuebox",
    },
    {
      ["__type"] = "AutoMateSandboxArgument",
      ["name"] = "amplitude",
      ["value"] = 1,
      ["value_min"] = 0,
      ["value_max"] = 1,
      ["value_quantum"] = 0,
      ["display_as"] = "minislider",
    },
    {
      ["__type"] = "AutoMateSandboxArgument",
      ["name"] = "phase",
      ["value"] = 90,
      ["value_min"] = 0,
      ["value_max"] = 180,
      ["value_quantum"] = 0,
      ["display_as"] = "minislider",
    }
  },
  ["callback"] = [[
-------------------------------------------------------------------------------
-- determine value 
-------------------------------------------------------------------------------
local val = (1/number_of_points) * (index-1)      -- linear value 
val = val + (args.phase/180)                      -- adjust phase 
val = math.sin(val * math.pi*2 * args.cycles)     -- create sine 
val = val + (args.center/100)                     -- adjust center 
point.value = cLib.scale_value(val,-args.amplitude,args.amplitude,0,1)
]]

}