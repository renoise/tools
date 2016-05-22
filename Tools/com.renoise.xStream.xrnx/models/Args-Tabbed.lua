--[[===========================================================================
Args-Tabbed.lua
===========================================================================]]--

return {
arguments = {
  {
      name = "foo.arg1",
      value = 1,
      properties = {
          min = 0,
          max = 100,
          display_as = "integer",
          zero_based = false,
      },
      description = "",
  },
  {
      name = "foo.arg2",
      value = 2,
      properties = {
          min = 0,
          max = 100,
          display_as = "integer",
          zero_based = false,
      },
      description = "",
  },
  {
      name = "bar.arg1",
      value = 3,
      properties = {
          min = 0,
          max = 100,
          display_as = "integer",
          zero_based = false,
      },
      description = "",
  },
  {
      name = "bar.arg2",
      value = 4,
      properties = {
          min = 0,
          max = 100,
          display_as = "integer",
          zero_based = false,
      },
      description = "",
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
-- prefixed with the tab name - in this case, "foo" or "bar"
-- A special feature of tabbed arguments is the ability to synchronize
-- values between tabs, when arguments share the same name - this is 
-- indicated by the small "chain" button - enable to sync values
-------------------------------------------------------------------------------

-- print the first value (arg1) of each tab
print(args.foo.arg1)
print(args.bar.arg1)


]],
}