--[[===========================================================================
Args-Controls.lua
===========================================================================]]--

return {
arguments = {
  {
      ["locked"] = false,
      ["name"] = "float",
      ["linked"] = false,
      ["value"] = 99999,
      ["properties"] = {
          ["display_as"] = "float",
      },
  },
  {
      ["locked"] = false,
      ["name"] = "hex",
      ["linked"] = false,
      ["value"] = 243,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "hex",
          ["max"] = 65535,
      },
  },
  {
      ["locked"] = false,
      ["name"] = "integer",
      ["linked"] = false,
      ["value"] = 11,
      ["properties"] = {
          ["display_as"] = "integer",
      },
  },
  {
      ["locked"] = false,
      ["name"] = "percent",
      ["linked"] = false,
      ["value"] = 7.2,
      ["properties"] = {
          ["min"] = -100,
          ["display_as"] = "percent",
          ["max"] = 100,
      },
  },
  {
      ["locked"] = false,
      ["name"] = "note",
      ["linked"] = false,
      ["value"] = 48,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "note",
          ["max"] = 119,
      },
  },
  {
      ["locked"] = false,
      ["name"] = "popup",
      ["linked"] = false,
      ["value"] = 2,
      ["properties"] = {
          ["display_as"] = "popup",
          ["items"] = {
              "one",
              "two",
              "three",
          },
      },
  },
  {
      ["locked"] = false,
      ["name"] = "chooser",
      ["linked"] = false,
      ["value"] = 1,
      ["properties"] = {
          ["display_as"] = "chooser",
          ["items"] = {
              "one",
              "two",
              "three",
          },
      },
  },
  {
      ["locked"] = false,
      ["name"] = "switch",
      ["linked"] = false,
      ["value"] = 1,
      ["properties"] = {
          ["display_as"] = "switch",
          ["items"] = {
              "one",
              "two",
              "three",
          },
      },
  },
  {
      ["locked"] = false,
      ["name"] = "minislider",
      ["linked"] = false,
      ["value"] = 35999.64,
      ["properties"] = {
          ["display_as"] = "minislider",
      },
  },
  {
      ["locked"] = false,
      ["name"] = "rotary",
      ["linked"] = false,
      ["value"] = 55999.44,
      ["properties"] = {
          ["display_as"] = "rotary",
      },
  },
  {
      ["locked"] = false,
      ["name"] = "checkbox",
      ["linked"] = false,
      ["value"] = false,
      ["properties"] = {
          ["display_as"] = "checkbox",
      },
  },
  {
      ["locked"] = false,
      ["name"] = "textfield",
      ["linked"] = false,
      ["value"] = "this is a string",
      ["properties"] = {
          ["display_as"] = "textfield",
      },
  },
},
presets = {
  {
      ["checkbox"] = false,
      ["note"] = 48,
      ["integer"] = 11,
      ["name"] = "",
      ["textfield"] = "this is a string",
      ["value"] = 4,
      ["popup"] = 2,
      ["chooser"] = 1,
      ["minislider"] = 35999.64,
      ["switch"] = 1,
      ["rotary"] = -39999.6,
      ["percent"] = 7.2,
      ["hex"] = 1,
  },
  {
      ["checkbox"] = false,
      ["note"] = 70.74688372093,
      ["integer"] = 34,
      ["name"] = "",
      ["textfield"] = "this is another string",
      ["value"] = 3.154,
      ["popup"] = 2,
      ["chooser"] = 2,
      ["minislider"] = -44222.813581395,
      ["switch"] = 2,
      ["rotary"] = -39999.6,
      ["percent"] = 67.441860465116,
      ["hex"] = 48,
  },
},
data = {
},
events = {
},
options = {
 color = 0x60AACA,
},
callback = [[
-------------------------------------------------------------------------------
-- How to define arguments
-- A demonstration of the various visual components you can use for
-- controlling arguments. Expand the arguments panel below to see them all
-- at the same time (click the arrow button)
-------------------------------------------------------------------------------
-- Display    Type      Supports      Supports  Requires  Restrict  
--                      'zero_based'  min/max   property  to range
-- VALUE      number                  yes                 
-- HEX        number    yes           yes                 
-- INTEGER    number    yes           yes                 
-- PERCENT    number                  yes                 
-- NOTE       number                  yes                 1-119
-- POPUP      number                            items     
-- CHOOSER    number                            items     
-- SWITCH     number                            items     
-- MINISLIDER number                  yes                 
-- ROTARY     number                  yes                 
-- BOOLEAN    boolean                                     
-- STRING     string
]],
}