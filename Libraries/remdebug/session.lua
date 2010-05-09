--[[---------------------------------------------------------------------------
-- RemDebug 1.0, Renoise Edition
-- Remote Debugger for Renoise Lua scripts, based on the
-- Kepler Projects remdebug (http://www.keplerproject.org/remdebug)
---------------------------------------------------------------------------]]--

module("remdebug.session", package.seeall)

_COPYRIGHT = "2010 - Renoise.com"
_DESCRIPTION = "Remote Debugger for Renoise Lua " ..
  "scripts, based on the Kepler Projects remdebug"
_VERSION = "1.0"

require "remdebug.engine"


-------------------------------------------------------------------------------
-- remdebug.session.start()
-- starts a local debug session by launching the controller and attacing
-- the engine
-------------------------------------------------------------------------------

function start(command, controller_name)
  command = command or "lua"
  controller_name = controller_name or "controller.lua"
  
  -- try to find "controller_name" in the package lib paths
  local found_controller = false
    
  local package_paths = {}
  package.path:gsub("([^;]*)", function(str) 
    table.insert(package_paths, str) return "" 
  end)
  
  for _,path in pairs(package_paths) do
    local remdebug_controller = path:gsub("?.lua", "") .. 
      "/remdebug/" .. controller_name
    
    -- start the controller 
    if io.open(remdebug_controller) then
      if (os.platform() == "WINDOWS") then
        os.execute(('start %s "%s" --from-session'):format(command, remdebug_controller))
      else
        os.execute(('%s "%s" --from-session &'):format(command, remdebug_controller))
      end
    
      found_controller = true
      break
    end  
  end
  
  -- and start debugging
  if (found_controller) then
    remdebug.engine.start()
  else
    error(("remdebug/%s could not be found in the package.path. " ..
      "Plase make sure remdebug is installed correctly."):format(controller_name))
  end
end


-------------------------------------------------------------------------------
-- remdebug.session.stop()
-- stops a running debug session by detaching the engine
-------------------------------------------------------------------------------

function stop()
  remdebug.engine.stop()
end


--[[---------------------------------------------------------------------------
---------------------------------------------------------------------------]]--

