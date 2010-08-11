--[[============================================================================
TrackAutomation.lua
============================================================================]]--

error("do not run this file. read and copy/paste from it only...")


-------------------------------------------------------------------------------
-- Access the selected parameters automation 
-- (selected in the "Automation" tab in Renoise)

local selected_parameter = renoise.song().selected_parameter
local selected_pattern_track = renoise.song().selected_pattern_track

-- is a parameter selected?.
if (selected_parameter) then
  local selected_parameters_automation = selected_pattern_track:find_automation(
    selected_parameter)

  -- is there automation for the seelcted parameter?
  if (not selected_parameters_automation) then
  
    -- if not, create a new automation for the currently selected pattern/track
    selected_parameters_automation = selected_pattern_track:create_automation(
      selected_parameter)
  end

  ---- do something with existing automation
  
  -- iterate over all existing automation points
  for _,point in pairs(selected_parameters_automation.points) do
    print(("track automation: time=%s, value=%s"):format( 
      point.time, point.value))
  end
  
  -- clear all points
  selected_parameters_automation.points = {} 

  -- insert a single new point at line 2
  selected_parameters_automation:add_point_at(2, 0.5) 
  -- change its value when it already exists
  selected_parameters_automation:add_point_at(2, 0.8) 
  -- remove it again (must exist here)
  selected_parameters_automation:remove_point_at(2) 
  
  -- batch creation/insertion of points
  local new_points = table.create()
  for i=1,selected_parameters_automation.length do
    new_points:insert {
      time=i, 
      value=i/selected_parameters_automation.length
    }
  end
  
  -- assign them (note that new_points must be sorted by time)
  selected_parameters_automation.points = new_points 

  -- change the automations interpolation mode
  selected_parameters_automation.playmode =
    renoise.PatternTrackAutomation.PLAYMODE_CUBIC
end


-------------------------------------------------------------------------------
-- add menu entries for automation

-- shows up in the automation list on the left of the "Automation" tab
renoise.tool():add_menu_entry {
  name = "Track Automation:Do Something With Automation",
  invoke = function() do_something_with_current_automation() end,
  active = function() return can_do_something_with_current_automation() end 
}

-- shows up in the context menu of the automation !rulers!
renoise.tool():add_menu_entry {
  name = "Track Automation List:Do Something With Automation",
  invoke = function() do_something_with_current_automation() end, 
  active = function() return can_do_something_with_current_automation() end 
}

function can_do_something_with_current_automation()
 -- is a parameter selected and automation present?
 return (renoise.song().selected_parameter ~= nil and 
    selected_pattern_track:find_automation(selected_parameter))
end
 
function do_something_with_current_automation()
 -- do something with selected_parameters_automation
end

