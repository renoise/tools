--[[===========================================================================
Args-Tabbed.lua
===========================================================================]]--

return {
arguments = {
  {
      ["locked"] = false,
      ["name"] = "baz",
      ["linked"] = false,
      ["value"] = 75,
      ["properties"] = {
          ["max"] = 100,
          ["min"] = 0,
          ["display_as"] = "integer",
          ["zero_based"] = false,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "one.foo",
      ["linked"] = false,
      ["value"] = 10,
      ["properties"] = {
          ["max"] = 100,
          ["min"] = 0,
          ["display_as"] = "integer",
          ["zero_based"] = false,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "one.bar",
      ["linked"] = false,
      ["value"] = 2,
      ["properties"] = {
          ["max"] = 100,
          ["min"] = 0,
          ["display_as"] = "integer",
          ["zero_based"] = false,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "two.foo",
      ["linked"] = true,
      ["value"] = 10,
      ["properties"] = {
          ["max"] = 100,
          ["min"] = 0,
          ["display_as"] = "integer",
          ["zero_based"] = false,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "two.bar",
      ["linked"] = false,
      ["value"] = 4,
      ["properties"] = {
          ["max"] = 100,
          ["min"] = 0,
          ["display_as"] = "integer",
          ["zero_based"] = false,
      },
      ["description"] = "",
  },
},
presets = {
},
data = {
},
options = {
 color = 0x000000,
},
callback = [[
-------------------------------------------------------------------------------
-- This model demonstrates how arguments can be grouped in tabs
-- The tabs are created by assigning a name to the argument which is
-- prefixed with the tab name - in this case, "one" or "two"
-- A special feature of tabbed arguments is the ability to synchronize
-- values between tabs, when arguments share the same name - this is 
-- indicated by the small "chain" button - enable to sync values
-------------------------------------------------------------------------------
-- print values
print(args.one.foo,args.two.foo)


]],
}