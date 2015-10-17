function xreflection_test()

  print("xReflection: starting unit-test...")

  -- is_valid_identifier

	assert(xReflection.is_valid_identifier("foo-bar"))
	assert(xReflection.is_valid_identifier("foobar42"))
	assert(xReflection.is_valid_identifier("foobar42"))
	assert(xReflection.is_valid_identifier("foo_bar"))
	assert(not xReflection.is_valid_identifier("foo-bar"))
	assert(not xReflection.is_valid_identifier("42foobar"))
	assert(not xReflection.is_valid_identifier("foo\nbar"))

  print("xReflection: OK - passed all tests")

end

