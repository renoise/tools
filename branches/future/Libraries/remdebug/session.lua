--[[---------------------------------------------------------------------------
-- RemDebug 1.0, Renoise Edition
-- Remote Debugger for Renoise Lua scripts, based on the
-- Kepler Projects remdebug (http://www.keplerproject.org/remdebug)
---------------------------------------------------------------------------]]--

module("remdebug.session", package.seeall)

_COPYRIGHT = "2010 - Renoise.com"
_DESCRIPTION = "Remote Debugger for Renoise Lua " ..
  "scripts, based on the Kepler Project remdebug"
_VERSION = "1.0"

require "remdebug.engine"


-------------------------------------------------------------------------------
-- remdebug.session.start()
-- starts a local debug session by launching the controller and attaching
-- the engine
-------------------------------------------------------------------------------

function start(command, controller_name)
  
  local found_controller = false
      
  -- exec 'command only'
  if (command and not controller_name) then
    found_controller = true
    
    if (os.platform() == "WINDOWS") then
      os.execute(('start %s --from-session'):format(command))
    else
      os.execute(('%s --from-session &'):format(command))
    end
  
  -- exec 'comand "controller_file"'
  else
    command = command or "lua"
    controller_name = controller_name or "controller.lua"
  
    -- try to find "controller_name" in the package lib paths
    local package_paths = {}
    package.path:gsub("([^;]*)", function(str) 
      table.insert(package_paths, str); return "" 
    end)
    
    for _,path in pairs(package_paths) do
      local abs_controller_path = path:gsub("?.lua", "") .. 
        "/remdebug/" .. controller_name
  
      -- start the controller 
      if (io.open(abs_controller_path)) then
        if (os.platform() == "WINDOWS") then
          os.execute(('start %s "%s" --from-session'):format(
            command, abs_controller_path))
        else
          os.execute(('%s "%s" --from-session &'):format(
            command, abs_controller_path))
        end
        found_controller = true
        break
      end  
    end
  end
  
  -- and start debugging
  if (found_controller) then
    remdebug.engine.start()
  else
    error(("remdebug/%s could not be found in the package.path. " ..
      "Please make sure remdebug is installed correctly."):format(controller_name))
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

