--[[===========================================================================
 AutoMateGenerator (http://www.example.com)
===========================================================================]]--

return {
  ["__type"] = "AutoMateGenerator",
  ["__version"] = 0,
  ["name"] = "Linear Curve",
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
      ["name"] = "from",
      ["value"] = 0,
      ["value_min"] = 0,
      ["value_max"] = 1,
      ["value_quantum"] = 0,
      ["display_as"] = "minislider",
    },
    {
      ["__type"] = "AutoMateSandboxArgument",
      ["name"] = "to",
      ["value"] = 1,
      ["value_min"] = 0,
      ["value_max"] = 1,
      ["value_quantum"] = 0,
      ["display_as"] = "minislider",
    }
  },
  ["callback"] = [[
---------------------------------------------------------
-- determine value 
---------------------------------------------------------
local val = (1/number_of_points) * (index-1)
point.value = cLib.scale_value(val,0,1,args.from,args.to)
]]

}