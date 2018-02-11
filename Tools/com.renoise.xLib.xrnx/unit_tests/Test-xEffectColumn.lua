--[[

  Testcase for xEffectColumn

--]]

_xlib_tests:insert({
name = "xEffectColumn",
fn = function()

  LOG(">>> xEffectColumn: starting unit-test...")

  cLib.require (_xlibroot.."xEffectColumn")
  --require (_xlibroot.."xNoteColumn")
  --require (_xlibroot.."xLinePattern")
  _trace_filters = {"^xEffectColumn*"}

  assert(xEffectColumn.number_string_to_value("00") == 0)
  assert(xEffectColumn.number_value_to_string(0) == "00")

  assert(xEffectColumn.number_string_to_value("01") == 1)
  assert(xEffectColumn.number_value_to_string(1) == "01")

  assert(xEffectColumn.number_string_to_value("11") == 257)
  assert(xEffectColumn.number_value_to_string(257) == "11")

  assert(xEffectColumn.number_string_to_value("ZT") == 8989)
  assert(xEffectColumn.number_value_to_string(8989) == "ZT")

  assert(xEffectColumn.number_string_to_value("FF") == 3855)
  assert(xEffectColumn.number_value_to_string(3855) == "FF")

  assert(xEffectColumn.amount_string_to_value("00") == 0)
  assert(xEffectColumn.amount_value_to_string(0) == "00")

  assert(xEffectColumn.amount_string_to_value("64") == 100)
  assert(xEffectColumn.amount_value_to_string(100) == "64")

  assert(xEffectColumn.amount_string_to_value("AA") == 170)
  assert(xEffectColumn.amount_value_to_string(170) == "AA")

  assert(xEffectColumn.amount_string_to_value("FF") == 0xFF)
  assert(xEffectColumn.amount_value_to_string(0xFF) == "FF")

  LOG(">>> xEffectColumn: OK - passed all tests")
  
end
})
