--[[ 

  Testcase for cReflection

--]]

__tests:insert({
name = "cReflection",
fn = function()

  print(">>> cReflection: starting unit-test...")

  require (_clibroot.."cReflection")

  -- basename
  --[[
  local device = xOscDevice()
  assert(cReflection.get_basename(device) == "xOscDevice")
  assert(cReflection.get_basename(_G["xOscDevice"]) == "xOscDevice")
  ]]

  local instr = rns.selected_instrument

  -- object info

  --local obj_info = cReflection.get_object_info(instr)
  --print("obj_info",obj_info,rprint(obj_info))

  -- object properties

  --local obj_props = cReflection.get_object_properties(instr)
  --print("obj_props",rprint(obj_props))

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

  print(">>> cReflection: OK - passed all tests")

end
})

