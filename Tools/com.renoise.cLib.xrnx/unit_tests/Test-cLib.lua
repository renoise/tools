--[[ 

  Testcase for cNumber

--]]

_tests:insert({
  name = "cLib",
  fn = function()
  
    LOG(">>> cLib: starting unit-test...")
  
    cLib.require (_clibroot.."cLib")
    _trace_filters = {"^cLib*"}
  
    -- Utilities 
    
    local fn = function(...)
      return cLib.unpack_args(...)
    end
          
    local args = fn{
      foo="foo",
      bar="bar"
    }
    assert(args.foo == "foo")
    assert(args.bar == "bar")
    

    -- Number methods 
    
    local in_min = 0
    local in_max = 1000
    local out_min = 0
    local out_max = 1
    
    assert(cLib.scale_value(0,in_min,in_max,out_min,out_max) == 0)
    assert(cLib.scale_value(500,in_min,in_max,out_min,out_max) == 0.5)
    assert(cLib.scale_value(1000,in_min,in_max,out_min,out_max) == 1)
    assert(cLib.scale_value(2000,in_min,in_max,out_min,out_max) == 2)
    assert(cLib.scale_value(-500,in_min,in_max,out_min,out_max) == -0.5)
    assert(cLib.scale_value(-0,in_min,in_max,out_min,out_max) == -0)
    
    assert(cLib.string_to_percentage("0%") == 0)
    assert(cLib.string_to_percentage("50%") == 50)
    assert(cLib.string_to_percentage("33.3%") == 33.3)
    assert(cLib.string_to_percentage("-33.3%") == -33.3)
    assert(cLib.string_to_percentage("-0%") == -0)
    
    assert(cLib.average(0,100) == 50)
    assert(cLib.average(0,50,100) == 50)
    assert(cLib.average(0,50,50,100) == 50)
    assert(cLib.average(0,-100) == -50)
    assert(cLib.average(0,-50,-100) == -50)
    
    assert(cLib.clamp_value(0,0,100) == 0)
    assert(cLib.clamp_value(-100,0,100) == 0)
    assert(cLib.clamp_value(0,100,200) == 100)
    assert(cLib.clamp_value(0,-200,-100) == -100)
    
    --[[
    assert(cLib.wrap_value(10,0,9) == 0)
    assert(cLib.wrap_value(30,0,19) == 10)
    assert(cLib.wrap_value(300,0,199) == 100)
    print(">>>",cLib.wrap_value(128,64,127))
    assert(cLib.wrap_value(128,64,127) == 65)
    ]]
    
    assert(cLib.sign(0) == 1)
    --assert(cLib.sign(-0) == -1) 
    assert(cLib.sign(cLib.HUGE_INT) == 1)
    assert(cLib.sign(-cLib.HUGE_INT) == -1)
    
    
    -- TODO 
    -- inv_log_scale
    -- log_scale
    
    assert(cLib.is_whole_number(0.0) == true)
    assert(cLib.is_whole_number(0.1) == false)
    assert(cLib.is_whole_number(10.0001) == false)
    assert(cLib.is_whole_number(10.000000001) == false)
    
    -- Conversion 
    

    
    

  
    LOG(">>> cLib: OK - passed all tests")
  
  end
  })
  
  