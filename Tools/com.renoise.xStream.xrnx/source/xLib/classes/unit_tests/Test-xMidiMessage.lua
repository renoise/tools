--[[ 

  Testcase for xMidiMessage

--]]

_xlib_tests:insert({
name = "xMidiMessage",
fn = function()

  print(">>> xMidiMessage: starting unit-test...")

  require (_xlibroot.."xDocument")
  require (_xlibroot.."xMessage")
  require (_xlibroot.."xMidiMessage")

  --error("No tests defined...")

  print(">>> xMidiMessage: OK - passed all tests")

end
})
