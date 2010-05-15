--[[--------------------------------------------------------------------------
TestNotifiers.lua
--------------------------------------------------------------------------]]--

do

  ----------------------------------------------------------------------------
  -- tools
  
  local function assert_error(statement)
    assert(pcall(statement) == false, "expected function error")
  end
  
  
  ----------------------------------------------------------------------------
  -- setup
  
  -- SomeClass
  
  class "SomeClass"
    function SomeClass:__init(name)
      self.name = name
    end
  
    function SomeClass:BpmNotifier()
      local bpm = renoise.song().transport.bpm
      notifier_print("BPM changed to " .. bpm ..
        " in Object: '" .. self.name .. "'")
    end
  
  
  -- function
  
  local function BpmNotifierFunction()
    local bpm = renoise.song().transport.bpm
    notifier_print("BPM changed to " .. bpm ..
      " in global Function")
  end
  
  
  -- setup
  
  local bpm_observable = renoise.song().transport.bpm_observable
  local tpl_observable = renoise.song().transport.tpl_observable
  
  local obj1 = SomeClass("Obj1")
  local obj2 = SomeClass("Obj2")
  
  
  ----------------------------------------------------------------------------
  -- expect notifications
  
  notifier_print = function (message) --[[ do nothing --]] end
  
  bpm_observable:add_notifier(SomeClass.BpmNotifier, obj1)
  bpm_observable:add_notifier(SomeClass.BpmNotifier, obj2)
  bpm_observable:add_notifier(BpmNotifierFunction)
  
  assert(bpm_observable:has_notifier(SomeClass.BpmNotifier, obj1))
  assert(bpm_observable:has_notifier(obj2, SomeClass.BpmNotifier))
  assert(bpm_observable:has_notifier(BpmNotifierFunction))
  assert(not bpm_observable:has_notifier(function() end))
  
  tpl_observable:add_notifier(BpmNotifierFunction)
  tpl_observable:remove_notifier(BpmNotifierFunction)
  
  -- already added notifier
  assert_error(function() 
    bpm_observable:add_notifier(SomeClass.BpmNotifier, obj1)  
  end)
  assert_error(function() 
    bpm_observable:add_notifier(BpmNotifierFunction)
  end)
  
  local transport = renoise.song().transport
  local old_bpm = transport.bpm
  if transport.bpm == 999 then
    transport.bpm = transport.bpm - 1
  else
    transport.bpm = transport.bpm + 1
  end
  
  
  ----------------------------------------------------------------------------
  -- expect no notifications
  
  notifier_print = function (message) error(message) end
  
  bpm_observable:remove_notifier(SomeClass.BpmNotifier, obj1)
  bpm_observable:remove_notifier(SomeClass.BpmNotifier, obj2)
  bpm_observable:remove_notifier(BpmNotifierFunction)
  
  -- already removed notifiers
  assert_error(function() 
    bpm_observable:remove_notifier(SomeClass.BpmNotifier, obj1)
  end)
  assert_error(function() 
    bpm_observable:remove_notifier(BpmNotifierFunction)
  end)
  
  transport.bpm = old_bpm

end


------------------------------------------------------------------------------
-- test finalizers

collectgarbage()


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--

