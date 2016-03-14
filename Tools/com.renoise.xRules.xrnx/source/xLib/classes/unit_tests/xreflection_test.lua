do

  print("xReflection: starting unit-test...")

  require (xLib_dir.."xReflection")
  --require (xLib_dir.."xDocument") 
  --require (xLib_dir.."xOscDevice") 

  -- basename
  --[[
  local device = xOscDevice()
  assert(xReflection.get_basename(device) == "xOscDevice")
  assert(xReflection.get_basename(_G["xOscDevice"]) == "xOscDevice")
  ]]

  local instr = renoise.song().selected_instrument

  -- object info

  --local obj_info = xReflection.get_object_info(instr)
  --print("obj_info",obj_info,rprint(obj_info))

  -- object properties

  --local obj_props = xReflection.get_object_properties(instr)
  --print("obj_props",rprint(obj_props))

  -- is_valid_identifier

	assert(not xReflection.is_valid_identifier("foo-bar"))
	assert(xReflection.is_valid_identifier("foobar42"))
	assert(xReflection.is_valid_identifier("foobar42"))
	assert(xReflection.is_valid_identifier("foo_bar"))
	assert(not xReflection.is_valid_identifier("foo-bar"))
	assert(not xReflection.is_valid_identifier("42foobar"))
	assert(not xReflection.is_valid_identifier("foo\nbar"))

  -- value casting

  assert(xReflection.cast_value(true,"boolean") == true)
  assert(xReflection.cast_value(false,"boolean") == false)
  assert(xReflection.cast_value("true","boolean") == true)
  assert(xReflection.cast_value("false","boolean") == false)
  assert(xReflection.cast_value("1","boolean") == true)
  assert(xReflection.cast_value("0","boolean") == false)

  print("xReflection: OK - passed all tests")

end

