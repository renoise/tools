--[[--------------------------------------------------------------------------
TestTransport.lua
--------------------------------------------------------------------------]]--

do

  ----------------------------------------------------------------------------
  -- tools
  
  local function assert_error(statement)
    assert(pcall(statement) == false, "expected function error")
  end
  
  
  -- shortcuts
  
  local transport = renoise.song().transport
  
  
  ----------------------------------------------------------------------------
  -- SongPos
  
  local some_str = tostring(transport.edit_pos)
  transport.edit_pos = renoise.SongPos(1, 1)
  local new_pos = transport.edit_pos
  
  assert_error(function()
    new_pos.does_not_exist = "Foo!"
  end)
  
  --[[ TODO:
  assert_error(function()
    new_pos.sequence = 2
  end)
  assert_error(function()
    new_pos.line = 1
  end)
  --]]
  
  transport.loop_range = {renoise.SongPos(1, 1), renoise.SongPos(1, 17)}
  
  assert(transport.loop_start == transport.loop_range[1])
  assert(transport.loop_end == transport.loop_range[2])
  
  assert(transport.loop_start < transport.loop_end)
  assert(transport.loop_end > transport.loop_start)
  
  assert(transport.loop_start == renoise.SongPos(1, 1))
  assert(transport.loop_start ~= renoise.SongPos(2, 1))
  
  
  
  ----------------------------------------------------------------------------
  -- Track Headroom
  
  function track_headroom_changed()
    print("track headroom changed: " .. transport.track_headroom)
  end
  
  transport.track_headroom_observable:add_notifier(track_headroom_changed)
 
  transport.track_headroom = math.db2lin(-6.0)
  
  assert_error(function()
    transport.track_headroom = math.db2lin(1.5)
  end)  
  
  transport.track_headroom_observable:remove_notifier(track_headroom_changed)
  
  
  ----------------------------------------------------------------------------
  -- Computer Keyboard Velocity
 
  transport.keyboard_velocity_enabled = false
  transport.keyboard_velocity = 127
  
  local num_keyboard_velocity_changes = 0
  function keyboard_velocity_changed()
    num_keyboard_velocity_changes = num_keyboard_velocity_changes + 1
  end
  
  local num_keyboard_velocity_enabled_changes = 0
  function keyboard_velocity_enabled_changed()
    num_keyboard_velocity_enabled_changes = 
      num_keyboard_velocity_enabled_changes + 1
  end
  
  transport.keyboard_velocity_observable:add_notifier(
    keyboard_velocity_changed)
  transport.keyboard_velocity_enabled_observable:add_notifier(
    keyboard_velocity_enabled_changed)
 
  transport.keyboard_velocity_enabled = true
  assert(transport.keyboard_velocity_enabled == true)
  
  transport.keyboard_velocity = 1
  assert(transport.keyboard_velocity == 1)
   
  transport.keyboard_velocity = 64
  assert(transport.keyboard_velocity == 64)
  
  assert_error(function()
    transport.keyboard_velocity = 128
  end)
  
  transport.keyboard_velocity_enabled = false
  assert(transport.keyboard_velocity_enabled ~= true)
  
  -- Should always return max 127 when disabled
  assert(transport.keyboard_velocity == 127)
  
  assert(num_keyboard_velocity_changes == 2)
  assert(num_keyboard_velocity_enabled_changes == 2)
  
  transport.keyboard_velocity_observable:remove_notifier(
    keyboard_velocity_changed)
    
  transport.keyboard_velocity_enabled_observable:remove_notifier(
    keyboard_velocity_enabled_changed)
  
end


------------------------------------------------------------------------------
-- test finalizers

collectgarbage()


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--

