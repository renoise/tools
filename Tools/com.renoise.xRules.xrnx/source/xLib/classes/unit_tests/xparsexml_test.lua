--[[

  Testcase for xParseXML

--]]

do

  print("xParseXML: starting unit-test...")

  require (xLib_dir.."xParseXML")

  -- First try with some broken XML

  local success,rslt = xParseXML.parse[[
    <RootNode foo="foo" under_score="foo">
      <A1>some_text.node</A2>
    </RootNode>
  ]]    

  assert(not success)

  -- Now parse some well-formed XML

  local success,x = xParseXML.parse[[
    <RootNode foo="foo" under_score="foo">
      <A1>some_text.node</A1>
      <A2>
        <B1>
          <C1><D1 bar_arg="bar">41</D1></C1>
          <!-- this is a comment -->
        </B1>
      </A2>
    </RootNode>
  ]]    
  --print("x...",rprint(x))

  assert(type(x)=="table")
  assert(x[1].label == "RootNode")
  assert(x[1].xarg.under_score == "foo")
  assert(x[1][1].label == "A1")
  assert(x[1][2].label == "A2")
  assert(x[1][2][1].label == "B1")
  assert(x[1][2][1].label == "B1")
  assert(x[1][2][1][1].label == "C1")
  assert(x[1][2][1][1][1].label == "D1")
  assert(x[1][2][1][1][1].xarg.bar_arg == "bar")

  -- A more realistic example

  local success,x = xParseXML.parse[[
    <?xml version="1.0" encoding="UTF-8"?>
    <xStreamArgDocument doc_version="0">
      <Presets>
        <Preset type="lua_model:xStreamArgPreset">
          <velocity_enabled>false</velocity_enabled>
          <velocity>127</velocity>
          <instr_idx>1.0</instr_idx>
        </Preset>
        <Preset type="lua_model:xStreamArgPreset">
          <velocity_enabled>false</velocity_enabled>
          <velocity>127</velocity>
          <instr_idx>1.0</instr_idx>
        </Preset>
        <Preset type="lua_model:xStreamArgPreset">
          <velocity_enabled>false</velocity_enabled>
          <velocity>127</velocity>
          <instr_idx>1.0</instr_idx>
        </Preset>
        <Preset type="lua_model:xStreamArgPreset">
          <velocity_enabled>false</velocity_enabled>
          <velocity>127</velocity>
          <instr_idx>1.0</instr_idx>
        </Preset>
      </Presets>
      <Arguments>
        <velocity_enabled>false</velocity_enabled>
        <velocity>127</velocity>
        <instr_idx>1.0</instr_idx>
      </Arguments>
    </xStreamArgDocument>

  ]]

  rprint(x)

  -- import XML from a file --

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
  --[[
  
  local doc = xParseXML.to_document(rslt)
  
  print("doc",doc)

  local doc_file_out = xLib_dir .. "/unit_tests/example_preferences_output.xml"
  doc:save_as(doc_file_out)
  ]]


  print("xParseXML: OK - passed all tests")

end