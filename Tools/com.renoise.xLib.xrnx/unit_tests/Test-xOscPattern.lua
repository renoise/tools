--[[

  Testcase for xOscPattern/xOscRouter

--]]

_xlib_tests:insert({
name = "xOscPattern",
fn = function()

  LOG(">>> xOscPattern: starting unit-test...")

  -----------------------------------------------------------

  -- initialize --

  --require (_clibroot.."cReflection")
  cLib.require (_xlibroot.."xOscPattern")
  --require (_xlibroot.."xOscRouter")
  --require (_xlibroot.."xValue")
  --require (_xlibroot.."xOscValue")
  _trace_filters = {"^xOscPattern*"}

  local osc_router = xOscRouter{
    patterns = {  
      xOscPattern{pattern_in = "/renoise/trigger/midi %i"},
      xOscPattern{pattern_in = "/renoise/trigger/note_on %i:track %i:instr %i:note %i:velocity"},
      xOscPattern{pattern_in = "/renoise/trigger/note_on 1 2 %i %i"},
      xOscPattern{pattern_in = "/renoise/trigger/note_on %i %i 48 0x80"},
      xOscPattern{pattern_in = "/renoise/trigger/note_off %i %i %i"},
      xOscPattern{pattern_in = "/renoise/trigger/note_off 1 1 64"},
      xOscPattern{pattern_in = "/renoise/trigger/note_off 1 1 64.0", strict = true},
      xOscPattern{pattern_in = "/renoise/trigger/note_off 1.0 1.0 64", strict = false},
      xOscPattern{pattern_in = "/foo/bar/baz"},
      xOscPattern{pattern_in = "/life_of_pi 3.1415926535897932384 %f"},
      xOscPattern{pattern_in = "/life_of_pi 3.14 %f", precision = 100},
      xOscPattern{pattern_in = "/life_of_pi %f 5.17"},
      xOscPattern{pattern_in = "/life_of_pi %f %f"},
      --[[
      ]]
    }
  }

  local create_note_message = function(instr,track,note,velocity)
    
    local osc_vars = table.create()
    osc_vars:insert({tag = "i",value = instr})
    osc_vars:insert({tag = "i",value = track})
    osc_vars:insert({tag = "i",value = note})
    
    local header = nil
    if (velocity) then
      header = "/renoise/trigger/note_on"
      osc_vars:insert({tag = "i",value = velocity})
    else
      header = "/renoise/trigger/note_off"
    end
    
    return renoise.Osc.Message(header,osc_vars)

  end

  --===========================================================================
  -- Pattern Matching
  --===========================================================================

  local osc_msg = renoise.Osc.Message("/renoise/trigger/midi",{
    {tag = "i", value = 1234}
  })
  local rslt = osc_router:input(osc_msg) 
  LOG("rslt...",rprint(rslt))
  assert(#rslt == 1)
  assert(rslt[1].pattern_in,"/renoise/trigger/midi %i")

  local osc_msg = renoise.Osc.Message("/renoise/trigger/midi",{
    {tag = "m", value = 1234} -- wrong datatype when compared to previous test
  })
  local rslt = osc_router:input(osc_msg) 
  --print("rslt...",rprint(rslt))
  assert(#rslt == 0)

  local osc_msg = create_note_message(1,1,64,127)
  local rslt = osc_router:input(osc_msg) 
  LOG("rslt...",rprint(rslt))
  assert(#rslt == 1)
  assert(rslt[1].pattern_in,"/renoise/trigger/note_on %i %i %i %i")

  local osc_msg = create_note_message(1,2,48,0x80)
  local rslt =  osc_router:input(osc_msg) 
  --print("rslt...",rprint(rslt))
  assert(#rslt == 3)
  assert(rslt[1].pattern_in,"/renoise/trigger/note_on %i %i %i %i")
  assert(rslt[2].pattern_in,"/renoise/trigger/note_on 1 2 %i %i")
  assert(rslt[3].pattern_in,"/renoise/trigger/note_on %i %i 48 0x80")

  local osc_msg = create_note_message(1,3,48,0x80)
  local rslt = osc_router:input(osc_msg) 
  --print("rslt...",rprint(rslt))
  assert(#rslt == 2)
  assert(rslt[1].pattern_in,"/renoise/trigger/note_on %i %i %i %i")
  assert(rslt[2].pattern_in,"/renoise/trigger/note_on %i %i 48 0x80")

  -- again, now retrieving from cache...
  local osc_msg = create_note_message(1,3,48,0x80)
  local rslt = osc_router:input(osc_msg) 
  --print("rslt...",rprint(rslt))
  assert(#rslt == 2)
  assert(rslt[1].pattern_in,"/renoise/trigger/note_on %i %i %i %i")
  assert(rslt[2].pattern_in,"/renoise/trigger/note_on %i %i 48 0x80")

  local osc_msg = renoise.Osc.Message("/foo/bar/baz")
  local rslt = osc_router:input(osc_msg) 
  --print("rslt...",rprint(rslt))
  assert(#rslt == 1)
  assert(rslt[1].pattern_in,"/foo/bar/baz")

  local osc_msg = create_note_message(1,1,64)
  local rslt = osc_router:input(osc_msg) 
  --print("rslt...",rprint(rslt))
  assert(#rslt == 3)
  assert(rslt[1].pattern_in,"/renoise/trigger/note_off %i %i %i")
  assert(rslt[2].pattern_in,"/renoise/trigger/note_off 1 1 64")
  assert(rslt[3].pattern_in,"/renoise/trigger/note_off 1 1 64.0")

  -- note: not cached, since we try to match the same message
  -- via both float and integer pattern
  local osc_msg = create_note_message(1,1,64)
  local rslt = osc_router:input(osc_msg) 
  --print("rslt...",rprint(rslt))
  assert(#rslt == 3)
  assert(rslt[1].pattern_in,"/renoise/trigger/note_off %i %i %i")
  assert(rslt[2].pattern_in,"/renoise/trigger/note_off 1 1 64")
  assert(rslt[3].pattern_in,"/renoise/trigger/note_off 1.0 1.0 64")

  -- enough precision for both literals
  local osc_msg = renoise.Osc.Message("/life_of_pi",{
    {tag="f",value=3.141592653589793}, 
    {tag="f",value=5.17},
  })
  local rslt = osc_router:input(osc_msg) 
  --print("rslt...",rprint(rslt))
  assert(#rslt == 4)
  assert(rslt[1].pattern_in,"/life_of_pi 3.1415926535897932384 %f")
  assert(rslt[2].pattern_in,"/life_of_pi 3.14 %f")
  assert(rslt[3].pattern_in,"/life_of_pi %f 5.17")
  assert(rslt[4].pattern_in,"/life_of_pi %f %f")

  -- enough precision for second literal only
  local osc_msg = renoise.Osc.Message("/life_of_pi",{
    {tag="f",value=3.1415}, 
    {tag="f",value=1.11},
  })
  local rslt = osc_router:input(osc_msg) 
  --print("rslt...",rprint(rslt))
  assert(#rslt == 2)
  assert(rslt[1].pattern_in,"/life_of_pi 3.14 %f")
  assert(rslt[2].pattern_in,"/life_of_pi %f %f")


  --===========================================================================
  -- Message Generation
  --===========================================================================

  -- assign these values

  local values = {
    ["/renoise/trigger/midi %i"] = {{value = 42}},
    ["/renoise/trigger/note_on %i:track %i:instr %i:note %i:velocity"] = {{value = 1},{value = 2},{value = 3},{value = 4}},
    ["/renoise/trigger/note_on 1 2 %i %i"] = {{value = nil},{value = nil},{value = 3},{value = 4}},
    ["/renoise/trigger/note_on %i %i 48 0x80"] = {{value = 1},{value = 2}},
    ["/renoise/trigger/note_off %i %i %i"] = {{value = 1},{value = 2},{value = 3}},
    ["/renoise/trigger/note_off 1 1 64"] = {},
    ["/renoise/trigger/note_off 1 1 64.0"] = {},
    ["/renoise/trigger/note_off 1.0 1.0 64"] = {},
    ["/foo/bar/baz"] = {},
    ["/life_of_pi 3.1415926535897932384 %f"] = {{value = nil},{value = 0.123}},
    ["/life_of_pi 3.14 %f"] = {{value = nil},{value = 1.2345}},
    ["/life_of_pi %f 5.17"] = {{value = 3.1415926535897932384}}, -- actual value 3.1415927410126
    ["/life_of_pi %f %f"] = {{value = 1.23},{value = 2.34}},
  }

  local rslt = {}
  for k,v in ipairs(osc_router.patterns) do  
    local osc_msg,err = v:generate(values[v.pattern_in]) 
    if osc_msg then
      table.insert(rslt,osc_msg)
    elseif err then 
      LOG("*** ",err)
    end
  end

  --print("rslt...",rprint(rslt))

  -- check results --

  assert(#rslt == #osc_router.patterns)

  assert(rslt[1].pattern == "/renoise/trigger/midi")
  assert(#rslt[1].arguments == 1)
  assert(rslt[1].arguments[1].tag == "i")
  assert(rslt[1].arguments[1].value == 42)

  assert(rslt[2].pattern == "/renoise/trigger/note_on")
  assert(#rslt[2].arguments == 4)
  assert(rslt[2].arguments[1].tag == "i")
  assert(rslt[2].arguments[2].tag == "i")
  assert(rslt[2].arguments[3].tag == "i")
  assert(rslt[2].arguments[4].tag == "i")
  assert(rslt[2].arguments[1].value == 1)
  assert(rslt[2].arguments[2].value == 2)
  assert(rslt[2].arguments[3].value == 3)
  assert(rslt[2].arguments[4].value == 4)

  assert(rslt[3].pattern == "/renoise/trigger/note_on")
  assert(#rslt[3].arguments == 4)
  assert(rslt[3].arguments[1].tag == "i")
  assert(rslt[3].arguments[2].tag == "i")
  assert(rslt[3].arguments[3].tag == "i")
  assert(rslt[3].arguments[4].tag == "i")
  assert(rslt[3].arguments[1].value == 1)
  assert(rslt[3].arguments[2].value == 2)
  assert(rslt[3].arguments[3].value == 3)
  assert(rslt[3].arguments[4].value == 4)

  assert(rslt[4].pattern == "/renoise/trigger/note_on")
  assert(#rslt[4].arguments == 4)
  assert(rslt[4].arguments[1].tag == "i")
  assert(rslt[4].arguments[2].tag == "i")
  assert(rslt[4].arguments[3].tag == "i")
  assert(rslt[4].arguments[4].tag == "i")
  assert(rslt[4].arguments[1].value == 1)
  assert(rslt[4].arguments[2].value == 2)
  assert(rslt[4].arguments[3].value == 48)
  assert(rslt[4].arguments[4].value == 0x80)

  assert(rslt[5].pattern == "/renoise/trigger/note_off")
  assert(#rslt[5].arguments == 3)
  assert(rslt[5].arguments[1].tag == "i")
  assert(rslt[5].arguments[2].tag == "i")
  assert(rslt[5].arguments[3].tag == "i")
  assert(rslt[5].arguments[1].value == 1)
  assert(rslt[5].arguments[2].value == 2)
  assert(rslt[5].arguments[3].value == 3)

  assert(rslt[6].pattern == "/renoise/trigger/note_off")
  assert(#rslt[6].arguments == 3)
  assert(rslt[6].arguments[1].tag == "i")
  assert(rslt[6].arguments[2].tag == "i")
  assert(rslt[6].arguments[3].tag == "i")
  assert(rslt[6].arguments[1].value == 1)
  assert(rslt[6].arguments[2].value == 1)
  assert(rslt[6].arguments[3].value == 64)

  assert(rslt[7].pattern == "/renoise/trigger/note_off")
  assert(#rslt[7].arguments == 3)
  assert(rslt[7].arguments[1].tag == "i")
  assert(rslt[7].arguments[2].tag == "i")
  assert(rslt[7].arguments[3].tag == "f")
  assert(rslt[7].arguments[1].value == 1)
  assert(rslt[7].arguments[2].value == 1)
  assert(rslt[7].arguments[3].value == 64.0)

  assert(rslt[8].pattern == "/renoise/trigger/note_off")
  assert(#rslt[8].arguments == 3)
  assert(rslt[8].arguments[1].tag == "i")
  assert(rslt[8].arguments[2].tag == "i")
  assert(rslt[8].arguments[3].tag == "i")
  assert(rslt[8].arguments[1].value == 1)
  assert(rslt[8].arguments[2].value == 1)
  assert(rslt[8].arguments[3].value == 64)

  assert(rslt[9].pattern == "/foo/bar/baz")
  assert(#rslt[9].arguments == 0)

  assert(rslt[10].pattern == "/life_of_pi")
  assert(#rslt[10].arguments == 2)
  assert(rslt[10].arguments[1].tag == "f")
  assert(rslt[10].arguments[2].tag == "f")
  assert(cLib.float_compare(rslt[10].arguments[1].value,3.1415926535897932384,10000))
  assert(cLib.float_compare(rslt[10].arguments[2].value,0.123,10000))

  assert(rslt[11].pattern == "/life_of_pi")
  assert(#rslt[11].arguments == 2)
  assert(rslt[11].arguments[1].tag == "f")
  assert(rslt[11].arguments[2].tag == "f")
  assert(cLib.float_compare(rslt[11].arguments[1].value,3.14,10000),rslt[11].arguments[1].value)
  assert(cLib.float_compare(rslt[11].arguments[2].value,1.2345,10000),rslt[11].arguments[2].value)

  assert(rslt[12].pattern == "/life_of_pi")
  assert(#rslt[12].arguments == 2)
  assert(rslt[12].arguments[1].tag == "f")
  assert(rslt[12].arguments[2].tag == "f")
  assert(cLib.float_compare(rslt[12].arguments[1].value,3.1415926535897932384,10000),rslt[12].arguments[1].value)
  assert(cLib.float_compare(rslt[12].arguments[2].value,5.17,10000),rslt[12].arguments[2].value)

  assert(rslt[13].pattern == "/life_of_pi")
  assert(#rslt[13].arguments == 2)
  assert(rslt[13].arguments[1].tag == "f")
  assert(rslt[13].arguments[2].tag == "f")
  assert(cLib.float_compare(rslt[13].arguments[1].value,1.23,10000),rslt[13].arguments[1].value)
  assert(cLib.float_compare(rslt[13].arguments[2].value,2.34,10000),rslt[13].arguments[2].value)


  LOG(">>> xOscPattern: OK - passed all tests")



end
})









