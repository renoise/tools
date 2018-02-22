--[[

  Testcase for cParseXML

--]]

_tests:insert({
name = "cParseXML",
fn = function()

  print (">>> cParseXML: starting unit-test...")

  cLib.require (_clibroot.."cParseXML")
  _trace_filters = {"^cParseXML*"}

  -- First try with some broken XML

  local success,rslt = pcall(function()
    cParseXML.parse[[
      <RootNode foo="foo" under_score="__">
        <A1>some_text.node</A2>
      </RootNode>
    ]]    
  end)
  assert(not success)

  -- Now parse some well-formed XML

  local x,err = cParseXML.parse[[
    <RootNode foo="foo" under_score="__">
      <A1>some_text.node</A1>
      <A2>
        <B1>
          <C1><D1 bar_arg="bar">41</D1></C1>
          <!-- this is a comment -->
        </B1>
      </A2>
    </RootNode>
  ]]    

  assert(type(x)=="table")
  LOG(x.kids[1])
  assert(x.kids[1].name == "RootNode")

   -- simple = false
  --assert(x.kids[1].attr.under_score == "foo")

  -- simple = true
  LOG(x.kids[1].attr[1].name == "foo")
  LOG(x.kids[1].attr[1].value == "foo")
  assert(x.kids[1].attr[2].name == "under_score") 
  assert(x.kids[1].attr[2].value == "__") 
  assert(x.kids[1].kids[1].name == "A1")
  assert(x.kids[1].kids[2].name == "A2")
  assert(x.kids[1].kids[2].kids[1].name == "B1")
  assert(x.kids[1].kids[2].kids[1].name == "B1")
  assert(x.kids[1].kids[2].kids[1].kids[1].name == "C1")
  assert(x.kids[1].kids[2].kids[1].kids[1].kids[1].name == "D1")
  
   -- simple = false  
  --assert(x.kids[1].kids[2].kids[1].kids[1].kids[1].attr.bar_arg == "bar")
  LOG(x.kids[1].kids[2].kids[1].kids[1].kids[1].attr[1].name == "bar_arg")
  LOG(x.kids[1].kids[2].kids[1].kids[1].kids[1].attr[1].value == "bar")

  -- A more realistic example

  local x,err = cParseXML.parse[[
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

  --rprint(x)

  -- import XML from a file --

  local file_path = renoise.tool().bundle_path .. _test_path .. "/example_preferences.xml"
  LOG("file_path",file_path)
  local fhandle = io.open(file_path,"r")
  if not fhandle then
    fhandle:close()
    error("Failed to open file handle")
  end

  local str_xml = fhandle:read("*a")
  fhandle:close()

  local x,err = cParseXML.parse(str_xml)
  if not x then
    error(err)
  end

  -- convert to document
  --[[
  
  local doc = cParseXML.to_document(rslt)
  
  print ("doc",doc)

  local doc_file_out = _clibroot .. "/unit_tests/example_preferences_output.xml"
  doc:save_as(doc_file_out)
  ]]


  print (">>> cParseXML: OK - passed all tests")

end
})
