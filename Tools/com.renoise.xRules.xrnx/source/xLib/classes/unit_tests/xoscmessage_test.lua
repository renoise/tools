--[[ 

  Testcase for xOscMessage

--]]

do

  print("xOscMessage: starting unit-test...")

  require (xLib_dir.."xMessage")
  require (xLib_dir.."xOscMessage")

  -- construct from scratch
  local msg = xOscMessage{ 
    pattern_in = "/input/%s %d %f",
    pattern_out = "/output/$1 $2 $3",
    values = {
      {tag = xOscValue.TAG.STRING,  value = "foo"},
      {tag = xOscValue.TAG.INTEGER, value = 32},
      {tag = xOscValue.TAG.FLOAT,   value = 3.14},
    },
  }

  print(msg)

  assert(msg.pattern_in,"/input/%s %d %f")
  assert(msg.pattern_out,"/output/$1 $2 $3")
  assert(msg.values[1].value,"foo")
  assert(msg.values[2].value,32)
  assert(msg.values[3].value,3.14)


  -- construct from renoise.Osc.Message 
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


  print("xOscMessage: OK - passed all tests")

end