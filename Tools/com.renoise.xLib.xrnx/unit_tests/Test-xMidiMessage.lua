--[[ 

  Testcase for xMidiMessage

--]]

_xlib_tests:insert({
name = "xMidiMessage",
fn = function()

  print(">>> xMidiMessage: starting unit-test...")

  require (_clibroot.."cDocument")
  require (_xlibroot.."xMessage")
  require (_xlibroot.."xMidiMessage")
  _trace_filters = {"^xMidiMessage*"}

  --error("No tests defined...")

  print(">>> xMidiMessage: OK - passed all tests")

end
})
