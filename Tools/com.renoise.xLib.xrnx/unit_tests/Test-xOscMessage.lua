--[[ 

  Testcase for xOscMessage

--]]

_xlib_tests:insert({
name = "xOscMessage",
fn = function()

  LOG(">>> xOscMessage: starting unit-test...")

  --require (_clibroot.."cDocument")
  --require (_xlibroot.."xMessage")
  --require (_xlibroot.."xOscDevice")
  --require (_xlibroot.."xValue")
  cLib.require (_xlibroot.."xOscValue")
  cLib.require (_xlibroot.."xOscMessage")
  _trace_filters = {"^xOscMessage*"}

  LOG("construct xOscMessage from scratch")
  local msg = xOscMessage{ 
    values = {
      {tag = xOscValue.TAG.STRING,  value = "foo"},
      {tag = xOscValue.TAG.INTEGER, value = 32},
      {tag = xOscValue.TAG.FLOAT,   value = 3.14},
    },
  }

  assert(msg.values[1].value,"foo")
  assert(msg.values[2].value,32)
  assert(msg.values[3].value,3.14)

  LOG("construct xOscMessage from renoise.Osc.Message")
  local pattern = "/test/input/"
  local arguments = {
      {tag = xOscValue.TAG.STRING,  value = "foo"},
      {tag = xOscValue.TAG.INTEGER, value = 32},
      {tag = xOscValue.TAG.FLOAT,   value = 3.14},
  }
  local native_msg = renoise.Osc.Message(pattern,arguments)
  local msg = xOscMessage(native_msg)

  assert(msg.values[1].value,"foo")
  assert(msg.values[2].value,32)
  assert(msg.values[3].value,3.14)

  LOG(">>> xOscMessage: OK - passed all tests")

end
})
