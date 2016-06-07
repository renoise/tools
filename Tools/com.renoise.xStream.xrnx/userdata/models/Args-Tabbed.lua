--[[===========================================================================
Args-Tabbed.lua
===========================================================================]]--

return {
arguments = {
  {
      ["locked"] = false,
      ["name"] = "baz",
      ["linked"] = false,
      ["value"] = 59,
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
      ["value"] = 4,
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
      ["value"] = 7,
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
      ["name"] = "two.bar",
      ["linked"] = false,
      ["value"] = 7,
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
events = {
},
options = {
 color = 0x000000,
},
callback = [[
-------------------------------------------------------------------------------
-- About - this model demonstrates how arguments can be grouped in tabs
-- The tabs are created by assigning a name to the argument which is
-- prefixed with the tab name - in this case, "one" or "two"
--
-- Linking - a special feature of tabbed arguments is the ability to 
-- synchronize/link values between tabs, when arguments share the same name
-- (as indicated by the small "chain" button). Press the chain to toggle. 
-------------------------------------------------------------------------------
-- print values
print(args.one.foo,args.two.foo)
]],
}