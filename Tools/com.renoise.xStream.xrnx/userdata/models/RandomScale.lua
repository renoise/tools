--[[===========================================================================
RandomScale.lua
===========================================================================]]--

return {
arguments = {
  {
      ["locked"] = false,
      ["name"] = "base_note",
      ["linked"] = false,
      ["value"] = 44.093589041096,
      ["properties"] = {
          ["min"] = 0,
          ["impacts_buffer"] = false,
          ["display_as"] = "note",
          ["max"] = 108,
      },
      ["description"] = "the base not to play",
  },
  {
      ["locked"] = false,
      ["name"] = "instrument",
      ["linked"] = false,
      ["value"] = 0,
      ["properties"] = {
          ["zero_based"] = false,
          ["max"] = 100,
          ["display_as"] = "integer",
          ["min"] = 0,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "base_mood",
      ["linked"] = false,
      ["value"] = 3,
      ["properties"] = {
          ["max"] = 4,
          ["zero_based"] = false,
          ["display_as"] = "integer",
          ["min"] = 1,
      },
      ["description"] = "- 1 major\n- 2 major 2\n- 3 major 3\n- 4 minor",
  },
  {
      ["locked"] = false,
      ["name"] = "note_1_prop",
      ["linked"] = false,
      ["value"] = 10,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "minislider",
          ["max"] = 10,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "note_1_1_prop",
      ["linked"] = false,
      ["value"] = 0,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "minislider",
          ["max"] = 10,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "note_1_2_prop",
      ["linked"] = false,
      ["value"] = 0,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "minislider",
          ["max"] = 10,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "note_1_3_prop",
      ["linked"] = false,
      ["value"] = 3.1506849315068,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "minislider",
          ["max"] = 10,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "note_2_prop",
      ["linked"] = false,
      ["value"] = 0,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "minislider",
          ["max"] = 10,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "note_2_1_prop",
      ["linked"] = false,
      ["value"] = 7.6712328767123,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "minislider",
          ["max"] = 10,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "note_2_2_prop",
      ["linked"] = false,
      ["value"] = 5.4794520547945,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "minislider",
          ["max"] = 10,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "note_2_3_prop",
      ["linked"] = false,
      ["value"] = 1.7808219178082,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "minislider",
          ["max"] = 10,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "note_3_prop",
      ["linked"] = false,
      ["value"] = 10,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "minislider",
          ["max"] = 10,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "note_3_1_prop",
      ["linked"] = false,
      ["value"] = 0,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "minislider",
          ["max"] = 10,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "note_3_2_prop",
      ["linked"] = false,
      ["value"] = 1.0958904109589,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "minislider",
          ["max"] = 10,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "note_3_3_prop",
      ["linked"] = false,
      ["value"] = 0,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "minislider",
          ["max"] = 10,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "note_4_prop",
      ["linked"] = false,
      ["value"] = 8.0821917808219,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "minislider",
          ["max"] = 10,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "note_4_1_prop",
      ["linked"] = false,
      ["value"] = 0,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "minislider",
          ["max"] = 10,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "note_4_2_prop",
      ["linked"] = false,
      ["value"] = 2.6027397260274,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "minislider",
          ["max"] = 10,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "note_4_3_prop",
      ["linked"] = false,
      ["value"] = 0,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "minislider",
          ["max"] = 10,
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
-- ------
-- propability 1 to 10 if true
-- ------

function random( percent )
  return ( math.random(0, 9) < percent )
end

-- ------
-- set note or off or empty
-- ------

-- note 

function note_prop( step_size, line, prop )
  if ( xpos.line % step_size == line )
  then
    return random(prop) 
  else
    return false
  end
end


function note_or_not()
  return ( 
    note_prop( 16,  1,   args.note_1_prop ) or
    note_prop( 16,  2,   args.note_1_1_prop ) or
    note_prop( 16,  3,   args.note_1_2_prop ) or
    note_prop( 16,  4,   args.note_1_3_prop ) or
    note_prop( 16,  5,   args.note_2_prop ) or
    note_prop( 16,  6,   args.note_2_1_prop ) or
    note_prop( 16,  7,   args.note_2_2_prop ) or
    note_prop( 16,  8,   args.note_2_3_prop ) or
    note_prop( 16,  9,   args.note_3_prop ) or
    note_prop( 16, 11,   args.note_3_1_prop) or
    note_prop( 16, 10,   args.note_3_2_prop) or
    note_prop( 16, 12,   args.note_3_3_prop) or
    note_prop( 16, 13,   args.note_4_prop) or
    note_prop( 16, 14,   args.note_4_1_prop) or
    note_prop( 16, 15,   args.note_4_2_prop) or
    note_prop( 16,  0,   args.note_4_3_prop) )
end



-- off

function off_or_not()
  return false
end    



-- ------
-- choose note
-- ------


local major  = { 0, 2, 4, 5, 7, 9, 11 }
-- base chord is more likely
local major2 = { 0, 0, 2, 4, 4, 5, 7, 7, 9, 11 } 
-- base chord is even more likely
local major3 = { 0, 0, 0, 2, 4, 4, 4, 5, 7, 7, 7, 9, 11 } 

local minor = { 0, 2, 3, 5, 7, 8, 10 }
local base_note_value = args.base_note

function random_minor_value()
  return base_note_value + minor[math.random(1,7)]
end

function random_major2_value()
  return base_note_value + major2[math.random(1,10)]
end

function random_major3_value()
  return base_note_value + major3[math.random(1,13)]
end

function random_major_value()
  return base_note_value + major[math.random(1,7)]
end

function note_value()
  if (args.base_mood == 1)
  then 
    return random_major_value()
  elseif (args.base_mood == 2)
  then 
    return random_major2_value()
  elseif (args.base_mood == 3)
  then 
    return random_major3_value()
  else
    return random_minor_value()
  end
end


-- -----
-- main
-- -----




if( note_or_not() ) then

  xline.note_columns[1] = {
    note_value       = note_value(),
    instrument_value = args.instrument
  }

elseif( off_or_not() ) then
  
  xline.note_columns[1] = {
    note_value       = 120, 
    instrument_value = args.instrument
  }  
  
else

  xline.note_columns[1] = {
    note_value       = 121,
    instrument_value = 255
  }  

end
]],
}