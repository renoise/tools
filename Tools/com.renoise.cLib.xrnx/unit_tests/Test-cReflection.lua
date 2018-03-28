--[[ 

  Testcase for cReflection

--]]

_tests:insert({
name = "cReflection",
fn = function()

  LOG(">>> cReflection: starting unit-test...")

  cLib.require (_clibroot.."cReflection")
  _trace_filters = {"^cReflection*"}


  local instr = rns.selected_instrument

  -- object info
  local obj_info = cReflection.get_object_info(instr)
  print("obj_info",obj_info,rprint(obj_info))
  assert(table.find(obj_info,"channel_pressure_macro"))
  assert(table.find(obj_info,"pitchbend_macro"))
  assert(table.find(obj_info,"volume_observable"))

  -- object properties
  local obj_props = cReflection.get_object_properties(instr)
  print("obj_props",rprint(obj_props))
  assert(obj_props["modulation_wheel_macro"])
  assert(obj_props["modulation_wheel_macro"].name == "Modulation")
  assert(type(obj_props["modulation_wheel_macro"].mappings)=="table")
  assert(type(obj_props["comments"])=="table")
  assert(type(obj_props["macros"])=="table")

  -- is_standard_type
  assert(cReflection.is_standard_type(nil))
  assert(cReflection.is_standard_type(true))
  assert(cReflection.is_standard_type(42))
  assert(cReflection.is_standard_type("foo"))
  assert(cReflection.is_standard_type({}))
  assert(cReflection.is_standard_type(function()end))
  assert(not cReflection.is_standard_type(instr))
  assert(not cReflection.is_standard_type(cReflection))
  
  -- is_serializable_type
  assert(cReflection.is_serializable_type(true))
  assert(cReflection.is_serializable_type(42))
  assert(cReflection.is_serializable_type("foo"))
  assert(cReflection.is_serializable_type({"foo","bar",42}))
  assert(not cReflection.is_serializable_type(nil))
  assert(not cReflection.is_serializable_type(instr))
  assert(not cReflection.is_serializable_type(cReflection))
  assert(not cReflection.is_serializable_type(function()end))

  -- is_valid_identifier
	assert(not cReflection.is_valid_identifier("foo-bar"))
	assert(cReflection.is_valid_identifier("foobar42"))
	assert(cReflection.is_valid_identifier("foobar42"))
	assert(cReflection.is_valid_identifier("foo_bar"))
	assert(not cReflection.is_valid_identifier("foo-bar"))
	assert(not cReflection.is_valid_identifier("42foobar"))
	assert(not cReflection.is_valid_identifier("foo\nbar"))

  -- value casting
  assert(cReflection.cast_value(true,"boolean") == true)
  assert(cReflection.cast_value(false,"boolean") == false)
  assert(cReflection.cast_value("true","boolean") == true)
  assert(cReflection.cast_value("false","boolean") == false)
  assert(cReflection.cast_value("1","boolean") == true)
  assert(cReflection.cast_value("0","boolean") == false)

  -- set_property
  -- TODO 
  
  -- copy_object_properties
  -- TODO 
  
  LOG(">>> cReflection: OK - passed all tests")

end
})

