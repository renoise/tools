--[[--------------------------------------------------------------------------
TestMidiActions.lua
--------------------------------------------------------------------------]]--

do

  local old_package_path = package.path
  
  package.path = package.path .. ";./../?.lua"
  require "GlobalMidiActions"
  
  package.path = old_package_path
  
  
  ----------------------------------------------------------------------------
  
  local message = {}
  
  local errors = table.create()
  local action_names = table.create()
  
  for _,action in pairs(available_actions()) do
    -- do not include window/dialog actions in unit tests...
    if not action:find("Window") and
       not action:find("Dialog") and
       -- also Sequence muting, or tests will take days
       not action:find("Sequence XX") and
       not action:find("Seq. XX") then
      action_names:insert(action)
    end
  end
  
  
  ----------------------------------------------------------------------------
  -- triggers
  
  message = {
    boolean_value = nil,
    int_value = nil,
    
    value_min_scaling = 0.0,
    value_max_scaling = 1.0,
    
    is_trigger = function() return true end,
    is_switch = function() return false end,
    is_rel_value = function() return false end,
    is_abs_value = function() return false end
  }
  
  for _,action in pairs(action_names) do
    local succeeded, err_message = pcall(invoke_action, action, message)
    if not succeeded then
      errors:insert(("Testing '%s' with void value:\n\t%s"):format(
        action, err_message))
    end
  end
  
  
  
  ----------------------------------------------------------------------------
  -- boolean values
  
  message = {
    boolean_value = nil,
    int_value = nil,
    
    value_min_scaling = 0.0,
    value_max_scaling = 1.0,
    
    is_trigger = function() return true end,
    is_switch = function() return true end,
    is_rel_value = function() return false end,
    is_abs_value = function() return false end
  }
  
  for _,b in pairs { false, true } do
    message.int_value = nil
    message.boolean_value = b
  
    for _,action in pairs(action_names) do
      local succeeded, err_message = pcall(invoke_action, action, message)
      if not succeeded then
        errors:insert(("Testing '%s' with boolean value:'%s'\n\t%s"):format(
          action,tostring(b), err_message))
      end
    end
  end
  
  
  ----------------------------------------------------------------------------
  -- abs values
  
  message = {
    boolean_value = nil,
    int_value = nil,
    
    value_min_scaling = 0.0,
    value_max_scaling = 1.0,
    
    is_trigger = function() return true end,
    is_switch = function() return true end,
    is_rel_value = function() return false end,
    is_abs_value = function() return true end
  }
  
  for value = 0,127 do
    message.int_value = value
    message.boolean_value = (value >= 64)
    
    for _,action in pairs(action_names) do
      local succeeded, err_message = pcall(invoke_action, action, message)
      if not succeeded then
        errors:insert(("Testing '%s' with abs value:'%s'\n\t%s"):format(
          action, tostring(value), err_message))
      end
    end
  end
  
  
  ----------------------------------------------------------------------------
  -- rel values
  
  message = {
    boolean_value = nil,
    int_value = nil,
    
    value_min_scaling = 0.0,
    value_max_scaling = 1.0,
    
    is_trigger = function() return true end,
    is_switch = function() return true end,
    is_rel_value = function() return true end,
    is_abs_value = function() return false end
  }
  
  for _,value in pairs { math.random(0, 63), math.random(64, 127) } do
    if value <= 63 then
      message.int_value = value
      message.boolean_value = true
    else
      message.int_value = -(value - 63)
      message.boolean_value = false
    end
  
    for _,action in pairs(action_names) do
      local succeeded, err_message = pcall(invoke_action, action, message)
      if not succeeded then
        errors:insert(("Testing '%s' with rel value:'%s'\n\t%s"):format(
          action, tostring(value), err_message))
      end
    end
  end
  
  
  -----------------------------------------------------------------------------
  -- dump errors
  
  if #errors > 0 then
    for _,e in pairs(errors) do
      print(e)
    end
    error("-- Test failed!")
  end

end


------------------------------------------------------------------------------
-- test finalizers

collectgarbage()


--[[---------------------------------------------------------------------------
---------------------------------------------------------------------------]]--
