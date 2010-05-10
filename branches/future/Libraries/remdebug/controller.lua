--[[---------------------------------------------------------------------------
-- RemDebug 1.0, Renoise Edition
-- Remote Debugger for Renoise Lua scripts, based on the
-- Kepler Project remdebug (http://www.keplerproject.org/remdebug)
---------------------------------------------------------------------------]]--

local socket = require"socket"

local from_session = false
if (#arg > 0 and arg[1] == "--from-session") then
  from_session = true
end

local server = nil
local client = nil

local breakpoints = {}
local watches = {}

local last_commandline = ""

local basedir = ""
local basefile = ""

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
-- connect

clear_screen()
print("Run the program you wish to debug with 'remdebug.engine.start()' now")

server = socket.bind("*", 8171)
client = server:accept()

do
  client:send("STEP\n")
  client:receive("*l")
  
  local breakpoint = client:receive("*l")
  
  -- step out of the session.start call...
  if (from_session) then
    client:send("STEP\n")
    client:receive("*l")
    breakpoint = client:receive("*l")
  end
    
  local _, _, filename, line = 
    breakpoint:find("^202 Paused%s+([%w%p%s]+)%s+(%d+)$")
  
  if (filename and line) then
    basefile = filename
    
    if filename:reverse():find("[/\\]+") then
      basedir = filename:sub(1, -filename:reverse():find("[/\\]+"))
    end
    
    show_file(filename, line)
    
    if (basedir and basedir ~= "") then
      print("Base directory is " .. basedir)
    end 
    
    print("Type 'n' to step over, 's' to step into, 'help' for more commands.")
    print("Any other expressions like 'print(my_var)' will be evaluated in " ..
      "the debugged programm...")
    print("")
    
  else
    local _, _, size = breakpoint:find(
      "^401 Error in Execution (%d+)$")
    
    if (size) then
      print("Error in remote application: ")
      print(client:receive(size))
      error("error in execution")
    end
  end
end


-------------------------------------------------------------------------------
-- command loop

while true do

  -- read command
  
  io.write("> ")
  local commandline = io.read("*line")
  
  if (commandline == "") then 
    commandline = last_commandline 
  else
    last_commandline = commandline
  end
  
  local _, _, command = commandline:find("^([a-z]+)")
  local _, _, command_args = commandline:find("^[a-z]+(.+)$")
  local _, _, separarated_command_args = commandline:find("^[a-z]+%s+(.+)$")
    
  if (command) then
    command = string.lower(command)
    command = command_shortcuts[command] or command
  end
  
  
  -- run, step, over
  
  if ((command == "run" or 
       command == "step" or 
       command == "over") 
      and not command_args)
  then
    client:send(string.upper(command) .. "\n")
    client:receive("*l")
    
    -- query current file and line position
    local breakpoint = client:receive("*l")
    
    if (not breakpoint) then
      print("Program finished")
      os.exit()
    end
    
    local _, _, status = breakpoint:find("^(%d+)")
    local break_succeeded = false
        
    if (status == "202") then
      local _, _, file, line = 
        breakpoint:find("^202 Paused%s+([%w%p%s]+)%s+(%d+)$")
      
      if (file and line) then 
        basefile = file
        show_file(file, line)
      end
      break_succeeded = true
          
    elseif (status == "203") then
      local _, _, file, line, watch_idx = 
        breakpoint:find("^203 Paused%s+([%w%p%s]+)%s+(%d+)%s+(%d+)$")
      
      if (file and line and watch_idx) then
        basefile = file       
        watch_idx = tonumber(watch_idx) 
        
        show_file(file, line, (" (watch expression %d: [%s])"):format(
          watch_idx, watches[watch_idx] or ""))
      end
      break_succeeded = true
      
    elseif (status == "401") then 
      local _, _, size = 
        breakpoint:find("^401 Error in Execution (%d+)$")
      
      if (size) then
        print("Error in remote application: ")
        print(client:receive(tonumber(size)))
        os.exit()
      end

    else
      print("Unknown error")
      os.exit()
    end
  
    -- query std out from prints
    if (break_succeeded) then
      client:send("STDOUT\n")
      
      local line = client:receive("*l")
      local _, _, status, len = line:find("^(%d+)[a-zA-Z ]+(%d+)$")
             
      if (status == "200") then
        if (tonumber(len) > 0) then
          local res = client:receive(tonumber(len))
          print(res)
        end
      
      else
        status = status or "nil"
        print("Unknown stdout error (" .. status .. ")")
      end

    end
    
    
  -- exit
  
  elseif (command == "exit" and not commandarg) then
    client:close()
    os.exit()
  
  
  -- setb
  
  elseif (command == "setb" and commandarg) then
    local _, _, filename, line = 
      commandline:find("^[a-z]+%s+([%w%p%s]+)%s+(%d+)$")
    
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
      
      if (client:receive("*l") == "200 OK") then 
        breakpoints[filename][line] = true
      else
        print("Error: breakpoint not inserted")
      end
    
    else
      print("Invalid command")
    end
  
  
  -- setw
  
  elseif (command == "setw" and commandarg) then
    local _, _, exp = commandline:find("^[a-z]+%s+(.+)$")
    
    if exp then
      client:send("SETW " .. exp .. "\n")
      
      local answer = client:receive("*l")
      local _, _, watch_idx = answer:find("^200 OK (%d+)$")
      
      if (watch_idx) then
        watches[watch_idx] = exp
        print("Inserted watch exp no. " .. watch_idx)
      else
        print("Error: Watch expression not inserted")
      end
    
    else
      print("Invalid command")
    end
    
  
  -- delb
  
  elseif (command == "delb" and commandarg) then
    local _, _, filename, line = 
      commandline:find("^[a-z]+%s+([%w%p%s]+)%s+(%d+)$")
    
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
      if (client:receive("*l") == "200 OK") then 
        breakpoints[filename][line] = nil
      else
        print("Error: breakpoint not removed")
      end
    
    else
      print("Invalid command")
    end
  
  
  -- delballb
  
  elseif (command == "delallb" and not commandarg) then
    
    for filename, breaks in pairs(breakpoints) do
      for line, _ in pairs(breaks) do
        client:send("DELB " .. filename .. " " .. line .. "\n")
        
        if (client:receive("*l") == "200 OK") then 
          breakpoints[filename][line] = nil
        else
          print(("Error: no breakpoint at file '%s' line %d"):format(
            filename, line))
        end
      end
    end
  
  
  -- delw
  
  elseif (command == "delw" and commandarg) then
    local _, _, index = commandline:find("^[a-z]+%s+(%d+)$")
    
    if (index) then
      client:send("DELW " .. index .. "\n")
      
      if (client:receive("*l") == "200 OK") then 
        watches[index] = nil
      
      else
        print("Error: watch expression not removed")
      end
    
    else
      print("Invalid command")
    end
  
  
  -- delallw
  
  elseif (command == "delallw" and not commandarg) then
    
    for index, exp in pairs(watches) do
      client:send("DELW " .. index .. "\n")
      
      if (client:receive("*l") == "200 OK") then 
        watches[index] = nil
      else
        print(("Error: no watch expression at " .. 
          "index %d [%s]"):format(index, exp))
      end
    end    
  
  
  -- eval
  
  elseif (command == "eval" and separarated_command_args) then
    local _, _, exp = commandline:find("^[a-z]+%s+(.+)$")
    
    if (exp) then 
      client:send("EXEC return (" .. exp .. ")\n")

      local line = client:receive("*l")
      local _, _, status, len = line:find("^(%d+)[a-zA-Z ]+(%d+)$")
             
      if (status == "200") then
        local res = client:receive(tonumber(len))
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
  
  elseif (command == "exec" and separarated_command_args) then
    local _, _, exp = commandline:find("^[a-z]+%s+(.+)$")
    
    if (exp) then 
      client:send("EXEC " .. exp .. "\n")
      local line = client:receive("*l")
      local _, _, status, len = line:find("^(%d+)[a-zA-Z ]+(%d+)$")
      
      if (status == "200") then
        local res = client:receive(tonumber(len))
        if (res and res ~= "nil") then
          print(res)
        end
      
      elseif (status == "401") then
        local res = client:receive(tonumber(len))
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
  
  elseif (command == "listb" and not commandarg) then
    for k, v in pairs(breakpoints) do
      io.write(k .. ": ")
      for k, v in pairs(v) do
        io.write(k .. " ")
      end
      io.write("\n")
    end


  -- listw
    
  elseif (command == "listw" and not commandarg) then
    for i, v in pairs(watches) do
      print("Watch exp. " .. i .. ": " .. v)
    end    
  
  
  -- basedir
  
  elseif (command == "basedir") then
    local _, _, dir = commandline:find("^[a-z]+%s+(.+)$")
    
    if (dir) then
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
  
  
  -- evaluate an expression by default
    
  else
    local _, _, only_spaces = commandline:find("^(%s*)$")
    
    if (not only_spaces) then
      client:send("EXEC " .. commandline .. "\n")
      
      local line = client:receive("*l")
      local _, _, status, len = line:find("^(%d+)[a-zA-Z ]+(%d+)$")
      
      if (status == "200") then
        local res = client:receive(tonumber(len))
        if (res and res ~= "nil") then
          print(res)
        end
      
      elseif (status == "401") then
        local res = client:receive(tonumber(len))
        print("Error in expression:")
        print(res)
        
      else
        status = status or "nil"
        print("Unknown exec error (" .. status .. ")")
      end

    end
  end

end


--[[---------------------------------------------------------------------------
---------------------------------------------------------------------------]]--

