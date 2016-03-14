do

  print("xDocument: starting unit-test...")

  require (xLib_dir.."xParseXML")
  require (xLib_dir.."xDocument")
  require (xLib_dir.."xOscDevice") -- because it extends xDocument

  -- construct from scratch
  local doc_class = xOscDevice{ 
    name = "My TestDevice",
    prefix = "/test",
    address = "127.0.0.1",
    port_in = 8000,
    port_out = 8080,
  }

  -- serialize --

  assert(type(doc_class:serialize()) == "table")

  local serialized = doc_class:serialize()
  assert(serialized.name,"My TestDevice2")
  assert(serialized.prefix,"/test2")
  assert(serialized.address,"127.0.0.2")
  assert(serialized.port_in,8002)
  assert(serialized.port_out,8082)

  -- import node --


  -- import XML --
  local file_path = xLib_dir .. "/unit_tests/example_preferences.xml"
  local fhandle = io.open(file_path,"r")
  if not fhandle then
    fhandle:close()
    error("Failed to open file handle")
  end

  local str_xml = fhandle:read("*a")
  fhandle:close()

  local success,rslt = xParseXML.parse(str_xml)
  if not success then
    error(rslt)
  end

  print("rslt",rprint(rslt))

  -- convert to document



  print("xDocument: OK - passed all tests")

end