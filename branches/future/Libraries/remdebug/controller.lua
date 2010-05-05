--[[---------------------------------------------------------------------------
-- RemDebug 1.0, Renoise Edition
-- Remote Debugger for Renoise Lua scripts, based on the
-- Kepler Project remdebug (http://www.keplerproject.org/remdebug)
---------------------------------------------------------------------------]]--

local socket = require"socket"


-------------------------------------------------------------------------------
-- clear_screen

local function clear_screen()
  if string.find(string.lower(os.getenv('OS') or ''),'^windows') then
    os.execute("cls")
  else
    os.execute("clear")
  end
  
  print("-- Lua Remote Debugger --")
end


-------------------------------------------------------------------------------
-- show_file

local function show_file(file, line, info_message)

  line = tonumber(line)
  info_message = info_message or ""

  local before = 10
  local after  = 8

  clear_screen()
  print("Paused at file " .. file .. " line " .. line .. info_message)
  print()
      
  if (not file:find('%.')) then 
    file = file..'.lua' 
  end

  local f = io.open(file,'r')
  if not f then
    -- try to find the file in the path
    local path = package.path or LUA_PATH or ''
    for c in string.gmatch (path, "[^;]+") do
      local c = string.gsub (c, "%?%.lua", file)
      f = io.open (c,'r')
      if f then
        break
      end
    end
    
    if not f then
      print('Cannot find '..file)
      return
    end
  end

  local i = 0
  for l in f:lines() do
    i = i + 1
    if i >= (line - before) then
      if i > (line + after) then 
        break
      end
      if i == line then
        print(i .. '*** ' .. l)
      else
        print(i .. '    ' .. l)
      end
    end
  end

  f:close()
  
  print("")  
end


-------------------------------------------------------------------------------
-- main

clear_screen()
print("Run the program you wish to debug with 'remdebug.engine.start()' now")


-- connect

local breakpoints = {}
local watches = {}

local basedir = ""
local basefile = ""

local server = socket.bind("*", 8171)
local client = server:accept()

client:send("STEP\n")
client:receive()

local breakpoint = client:receive()

local _, _, filename, line = 
  breakpoint:find("^202 Paused%s+([%w%p]+)%s+(%d+)$")

if (filename and line) then
  basefile = filename
  
  if filename:reverse():find("[/\\]+") then
    basedir = filename:sub(1, -filename:reverse():find("[/\\]+"))
  end
  
  show_file(filename, line)
  print("Base directory is " .. basedir)
  print("Type 'help' for commands")
  
else
  local _, _, size = 
    breakpoint:find("^401 Error in Execution (%d+)$")
  
  if size then
    print("Error in remote application: ")
    print(client:receive(size))
  end
end

local last_commandline = ""

local command_shortcuts = {
  ["b"] = "setb", ["db"] = "delb", ["dab"] = "delallb",
  ["w"] = "setw", ["dw"] = "delw", ["daw"] = "delallw",
  ["c"] = "run", ["r"] = "run",
  ["s"] = "step", ["i"] = "step",
  ["n"] = "over", ["o"] = "over",
  ["lb"] = "listb", ["lw"] = "listw", ["lb"] = "listb",
  ["print"] = "eval", ["p"] = "eval",
  ["e"] = "exec",
  ["q"] = "exit"
}


-- command loop

while true do

  -- read command
  
  io.write("> ")
  local commandline = io.read("*line")
  
  if commandline == "" then 
    commandline = last_commandline 
  else
    last_commandline = commandline
  end
  
  local _, _, command = commandline:find("^([a-z]+)")
  
  if (command) then
    command = string.lower(command)
    command = command_shortcuts[command] or command
  end
  
  
  -- run, step, over
  
  if (command == "run" or command == "step" or command == "over") then
    client:send(string.upper(command) .. "\n")
    client:receive()
    
    local breakpoint = client:receive()
    if (not breakpoint) then
      print("Program finished")
      os.exit()
    end
    
    local _, _, status = breakpoint:find("^(%d+)")
    
    if (status == "202") then
      local _, _, file, line = 
        breakpoint:find("^202 Paused%s+([%w%p]+)%s+(%d+)$")
      
      if (file and line) then 
        basefile = file
        show_file(file, line)
      end
    
    elseif (status == "203") then
      local _, _, file, line, watch_idx = 
        breakpoint:find("^203 Paused%s+([%w%p]+)%s+(%d+)%s+(%d+)$")
      
      if (file and line) and watch_idx then
        basefile = file       
        watch_idx = tonumber(watch_idx) 
        show_file(file, line, 
          (" (watch expression %d: [%s])"):format(watch_idx, watches[watch_idx] or ""))
      end
    
    elseif (status == "401") then 
      local _, _, size = 
        breakpoint:find("^401 Error in Execution (%d+)$")
      
      if size then
        print("Error in remote application: ")
        print(client:receive(tonumber(size)))
        os.exit()
      end
    
    else
      print("Unknown error")
      os.exit()
    end
  
  
  -- exit
  
  elseif (command == "exit") then
    client:close()
    os.exit()
  
  
  -- setb
  
  elseif (command == "setb") then
    local _, _, filename, line = 
      commandline:find("^[a-z]+%s+([%w%p]+)%s+(%d+)$")
    
    if (not filename and not line) then 
      _, _, line = commandline:find("^[a-z]+%s+(%d+)$")
      filename = basefile   
    else
      filename = basedir .. filename
    end
      
    if (filename and line) then
      if (not breakpoints[filename]) then 
        breakpoints[filename] = {} 
      end
      
      client:send("SETB " .. filename .. " " .. line .. "\n")
      if (client:receive() == "200 OK") then 
        breakpoints[filename][line] = true
      else
        print("Error: breakpoint not inserted")
      end
    else
      print("Invalid command")
    end
  
  
  -- setw
  
  elseif (command == "setw") then
    local _, _, exp = 
      commandline:find("^[a-z]+%s+(.+)$")
    
    if exp then
      client:send("SETW " .. exp .. "\n")
      local answer = client:receive()
      local _, _, watch_idx = answer:find("^200 OK (%d+)$")
      if watch_idx then
        watches[watch_idx] = exp
        print("Inserted watch exp no. " .. watch_idx)
      else
        print("Error: Watch expression not inserted")
      end
    else
      print("Invalid command")
    end
    
  
  -- delb
  
  elseif (command == "delb") then
    local _, _, filename, line = 
      commandline:find("^[a-z]+%s+([%w%p]+)%s+(%d+)$")
    
    if (not filename and not line) then 
      _, _, line = commandline:find("^[a-z]+%s+(%d+)$")
      filename = basefile   
    else
      filename = basedir .. filename
    end
      
    if (filename and line) then
      if (not breakpoints[filename]) then 
        breakpoints[filename] = {} 
      end
      
      client:send("DELB " .. filename .. " " .. line .. "\n")
      if client:receive() == "200 OK" then 
        breakpoints[filename][line] = nil
      else
        print("Error: breakpoint not removed")
      end
    else
      print("Invalid command")
    end
  
  
  -- delballb
  
  elseif (command == "delallb") then
    for filename, breaks in pairs(breakpoints) do
      for line, _ in pairs(breaks) do
        client:send("DELB " .. filename .. " " .. line .. "\n")
        if client:receive() == "200 OK" then 
          breakpoints[filename][line] = nil
        else
          print(("Error: no breakpoint at file '%s' line %d"):format(filename, line))
        end
      end
    end
  
  
  -- delw
  
  elseif (command == "delw") then
    local _, _, index = 
      commandline:find("^[a-z]+%s+(%d+)$")
    
    if index then
      client:send("DELW " .. index .. "\n")
      if client:receive() == "200 OK" then 
      watches[index] = nil
      else
        print("Error: watch expression not removed")
      end
    else
      print("Invalid command")
    end
  
  
  -- delallw
  
  elseif (command == "delallw") then
    for index, exp in pairs(watches) do
      client:send("DELW " .. index .. "\n")
      if client:receive() == "200 OK" then 
      watches[index] = nil
      else
        print(("Error: no watch expression at index %d [%s]"):format(index, exp))
      end
    end    
  
  
  -- eval
  
  elseif (command == "eval") then
    local _, _, exp = 
      commandline:find("^[a-z]+%s+(.+)$")
    
    if exp then 
      client:send("EXEC return (" .. exp .. ")\n")

      local line = client:receive()
      local _, _, status, len = line:find("^(%d+)[a-zA-Z ]+(%d+)$")
             
      if (status == "200") then
        len = tonumber(len)
        local res = client:receive(len)
        print(res)
      elseif (status == "401") then
        local res = client:receive(tonumber(len))
        print("Error in expression:")
        print(res)
      else
        status = status or "nil"
        print("Unknown eval error (" .. status .. ")")
      end
    else
      print("Invalid eval command")
    end
  
  
  -- exec
  
  elseif (command == "exec") then
    local _, _, exp = commandline:find("^[a-z]+%s+(.+)$")
    
    if exp then 
      client:send("EXEC " .. exp .. "\n")
      local line = client:receive()
      local _, _, status, len = line:find("^(%d+)[%s%w]+(%d+)$")
      
      if (status == "200") then
        local res = client:receive(tonumber(len))
        if (res and res ~= "nil") then
          print(res)
        end
      elseif (status == "401") then
        local res = client:receive( tonumber(len))
        print("Error in expression:")
        print(res)
      else
        status = status or "nil"
        print("Unknown exec error (" .. status .. ")")
      end
    else
      print("Invalid expression")
    end
  
  
  -- listb
  
  elseif (command == "listb") then
    for k, v in pairs(breakpoints) do
      io.write(k .. ": ")
      for k, v in pairs(v) do
        io.write(k .. " ")
      end
      io.write("\n")
    end


  -- listw
    
  elseif (command == "listw") then
    for i, v in pairs(watches) do
      print("Watch exp. " .. i .. ": " .. v)
    end    
  
  
  -- basedir
  
  elseif (command == "basedir") then
    local _, _, dir = commandline:find("^[a-z]+%s+(.+)$")
    if dir then
      if not dir:find("/$") then 
        dir = dir .. "/"
      end
      basedir = dir
      print("New base directory is " .. basedir)
    else
      print(basedir)
    end
 
 
  -- help
  
  elseif (command == "help") then

    print([[
setb, b [<file>] <line> -- sets a breakpoint
delb, db  [<file>] <line> -- removes a breakpoint
delallb, dab -- removes all breakpoints
setw, w  <exp> -- adds a new watch expression
delw, dw <index> -- removes the watch expression at index
delallw, daw -- removes all watch expressions
run, r,c -- run until next breakpoint
step, s, i -- run until next line, stepping into function calls
over, o, n -- run until next line, stepping over function calls
listb, lb -- lists breakpoints
listw, lw -- lists watch expressions
eval, print, p <exp> -- evaluates expression on the current context and returns its value
exec, e <stmt> -- executes statement on the current context
basedir [<path>] -- sets the base path of the remote application, or shows the current one
exit, q -- exits debugger
]])
  
  else
    local _, _, spaces = 
      commandline:find("^(%s*)$")
    
    if not spaces then
      print("Invalid command")
    end
  end
end


--[[---------------------------------------------------------------------------
---------------------------------------------------------------------------]]--
