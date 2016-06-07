--[[===========================================================================
Args-Events.lua
===========================================================================]]--

return {
arguments = {
  {
      ["locked"] = false,
      ["name"] = "my_arg",
      ["linked"] = false,
      ["value"] = 77.013698630137,
      ["properties"] = {
          ["max"] = 100,
          ["display_as"] = "minislider",
          ["min"] = 0,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "tab1.arg1",
      ["linked"] = false,
      ["value"] = 40,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "integer",
          ["max"] = 100,
      },
  },
  {
      ["locked"] = false,
      ["name"] = "tab2.arg1",
      ["linked"] = false,
      ["value"] = 39,
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
  ["args.tab2.arg1"] = [[------------------------------------------------------------------------------
-- respond to argument 'tab2' changes
-- @param val (number/boolean/string)}
------------------------------------------------------------------------------

print("args.tab2.arg1",val)
]],
  ["args.tab1.arg1"] = [[------------------------------------------------------------------------------
-- respond to argument 'tab1' changes
-- @param val (number/boolean/string)}
------------------------------------------------------------------------------

print("args.tab1.arg1",val)
]],
  ["args.my_arg"] = [[------------------------------------------------------------------------------
-- respond to argument 'my_arg' changes
-- @param val (number/boolean/string)}
------------------------------------------------------------------------------

print("args.my_arg",val)

]],
},
options = {
 color = 0x000000,
},
callback = [[
-------------------------------------------------------------------------------
-- Responding to argument changes via event handlers
-- Here is a demonstration of yet another approach to events  - using 
-- custom event handlers. In several cases, this can be a good approach.
-------------------------------------------------------------------------------

-- Hints:
-- Press the 'view' popup below to switch between event handlers
-- Open the scripting console to view the debug information
]],
}