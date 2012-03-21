--[[---------------------------------------------------------------------------
-- RemDebug 1.0, Renoise Edition
-- Remote Debugger for Renoise Lua scripts, based on the
-- Kepler Projects remdebug (http://www.keplerproject.org/remdebug)
---------------------------------------------------------------------------]]--

module("remdebug.session", package.seeall)

require "remdebug.engine"

_COPYRIGHT = "2010 - Renoise.com"
_DESCRIPTION = "Remote Debugger for Renoise Lua " ..
  "scripts, based on the Kepler Project remdebug"
_VERSION = "1.0"

local running = false


-------------------------------------------------------------------------------
-- remdebug.session.start()
-- starts a local debug session by launching the controller and attaching
-- the engine
-------------------------------------------------------------------------------

function start(command, controller_name)
  if running then
    return -- do not restart when already running
  end
  
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
        
        elseif (os.platform() == "MACINTOSH") then
          
          local tmp_command = ('%s "%s" --from-session || ' .. 
            '(echo; echo "** Failed to lauch the controller. ' ..
            'Please make sure that Lua for Max OSX is installed.")'):format(
            command, abs_controller_path)
            
          local tmp_filename = os.tmpname() .. ".command"
          local tmp_file = io.open(tmp_filename, "w")
          
          tmp_file:write(tmp_command)
          tmp_file:close()
          
          os.execute(('chmod +x "%s" && open --new "%s"'):format(
            tmp_filename, tmp_filename))
          
        elseif (os.platform() == "LINUX") then
          local exec_line = 
            ('%%TERMINAL%% -e "%s "%s" --from-session"'):format(
             command, abs_controller_path)
            
          local exec_command = 
            "(" .. exec_line:gsub("%%TERMINAL%%", "$COLORTERM") .. ") || \n" ..
            "(" .. exec_line:gsub("%%TERMINAL%%", "$TERM") .. ") || \n" ..
            "(" .. exec_line:gsub("%%TERMINAL%%", "xterm") .. ")"
            
          os.execute(exec_command)
          
        else
          error(("unexpected platform '%s'"):format(
            os.platform()))
        end
        
        found_controller = true
        break
      end  
    end
  end
  
  
  if (found_controller) then
    running = true
  
    -- and start debugging
    remdebug.engine.config { host="localhost" }
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
  if (running) then
    running = false    
    remdebug.engine.stop()
  end
end


--[[---------------------------------------------------------------------------
---------------------------------------------------------------------------]]--

