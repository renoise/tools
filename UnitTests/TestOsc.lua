--[[--------------------------------------------------------------------------
TestOsc.lua
--------------------------------------------------------------------------]]--

do

  ----------------------------------------------------------------------------
  -- tools
  
  local function assert_error(statement)
    assert(pcall(statement) == false, "expected function error")
  end
  
  local OscMessage = renoise.Osc.Message  
  local OscBundle = renoise.Osc.Bundle
  
  
  -- create & access messages
  
  local message = OscMessage("/test/message")
  
  message = OscMessage("/test/message", {
    {tag="s", value="string"}, 
    {tag="i", value=12},
    {tag="b", value="blob"}
  })
  
  assert(message.pattern == "/test/message")
  assert(message.binary_data:find("/test/message") == 1)
  assert(#message.binary_data > #message.pattern)

  assert(#message.arguments == 3)
  assert(message.arguments[1].tag == "s")
  assert(message.arguments[1].value == "string")
  assert(message.arguments[2].tag == "i")
  assert(message.arguments[2].value == 12)
  assert(message.arguments[3].tag == "b")
  assert(message.arguments[3].value == "blob")
  
  -- unknown tag
  assert_error(function()
    OscMessage("/test/message", { {tag="X"} })
  end)
  -- missing tag value
  assert_error(function()
    OscMessage("/test/message", { {tag="i"} })
  end)
  -- bogus tag value
  assert_error(function()
    OscMessage("/test/message", { {tag="i", value="string"} })
  end)
  

  -- create & access  bundles
  
  local timetag = 99
  local bundle = OscBundle(timetag, message)
  assert(#bundle.elements == 1)
    
  bundle = OscBundle(timetag, {OscMessage("/bla"), message})
  assert(#bundle.elements == 2)
  assert(type(bundle.elements[1]) == "Message")
  assert(type(bundle.elements[2]) == "Message")
  assert(bundle.elements[2].arguments[2].tag == "i")
  assert(bundle.elements[2].arguments[2].value == 12)


  -- binary data -> bundles or messages

  local result, error = renoise.Osc.from_binary_data("garbage")
  assert(not result and error)
  
  result, error = renoise.Osc.from_binary_data(bundle.binary_data)
  assert(result and not error)
  assert(type(result) == "Bundle")
  assert(result.timetag == bundle.timetag)
  assert(result.elements[2].arguments[2].tag == "i")
  assert(result.elements[2].arguments[2].value == 12)
  
  
  result, error = renoise.Osc.from_binary_data(message.binary_data)
  assert(result and not error)
  assert(type(result) == "Message")
  assert(result.arguments[2].tag == "i")
  assert(result.arguments[2].value == 12)
  
end


------------------------------------------------------------------------------
-- test finalizers

collectgarbage()


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--

