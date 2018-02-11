--[[ 

  Testcase for xMidiMessage

--]]

_xlib_tests:insert({
name = "xMidiMessage",
fn = function()

  LOG(">>> xMidiMessage: starting unit-test...")

  --require (_clibroot.."cDocument")
  --require (_xlibroot.."xMessage")
  cLib.require (_xlibroot.."xMidiMessage")
  _trace_filters = {"^xMidiMessage*"}

  --error("No tests defined...")

  LOG(">>> xMidiMessage: OK - passed all tests")

end
})
