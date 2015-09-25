function xparsexml_test()

  print("xParseXML: starting unit-test...")

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
  print("x...",rprint(x))

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



  print("xParseXML: OK - passed all tests")

end