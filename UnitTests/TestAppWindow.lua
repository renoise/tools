--[[--------------------------------------------------------------------------
TestAppWindow.lua
--------------------------------------------------------------------------]]--

do

  ----------------------------------------------------------------------------
  -- tools
  
  local function assert_error(statement)
    assert(pcall(statement) == false, "expected function error")
  end
  
  
  -- shortcuts
  
  local window = renoise.app().window
  
  local UPPER_FRAME_DISK_BROWSER = 
    renoise.ApplicationWindow.UPPER_FRAME_DISK_BROWSER
  
  
  ----------------------------------------------------------------------------
  -- upper frame
  
  local notification_count = 0
  function disk_browser_is_expanded_changed()
    notification_count = notification_count + 1  
  end
  
  window.disk_browser_is_expanded = false
  
  window.disk_browser_is_expanded_observable:add_notifier(
    disk_browser_is_expanded_changed)
  
  window.disk_browser_is_expanded = true
  assert((window.disk_browser_is_expanded == true) and 
    (window.active_upper_frame == UPPER_FRAME_DISK_BROWSER))
  assert(notification_count == 1)
  
  window.disk_browser_is_expanded = false
  assert(window.disk_browser_is_expanded == false)
  assert(notification_count == 2)
  
  window.disk_browser_is_expanded_observable:remove_notifier(
    disk_browser_is_expanded_changed)

end


------------------------------------------------------------------------------
-- test finalizers

collectgarbage()


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--

