--[[===========================================================================
Args-Tabbed.lua
===========================================================================]]--

return {
arguments = {
  {
      locked = false,
      name = "argXYZ",
      linked = false,
      value = 3,
      properties = {
          max = 100,
          min = 0,
          display_as = "integer",
          zero_based = false,
      },
      description = "",
  },
  {
      locked = false,
      name = "arg2",
      linked = false,
      value = 75,
      properties = {
          min = 0,
          display_as = "integer",
          max = 100,
      },
  },
  {
      locked = true,
      name = "foo.arg1",
      linked = false,
      value = 10,
      properties = {
          min = 0,
          max = 100,
          display_as = "integer",
          zero_based = false,
      },
      description = "",
  },
  {
      locked = true,
      name = "foo.argX",
      linked = false,
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
      locked = false,
      name = "bar.arg1",
      linked = false,
      value = 10,
      properties = {
          max = 100,
          min = 0,
          display_as = "integer",
          zero_based = false,
      },
      description = "",
  },
  {
      locked = false,
      name = "bar.argYY",
      linked = false,
      value = 4,
      properties = {
          max = 100,
          min = 0,
          display_as = "integer",
          zero_based = false,
      },
      description = "",
  },
},
presets = {
  {
      arg2 = 75,
      argX = 2,
      arg1 = 3,
      name = "",
      argY = 4,
  },
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