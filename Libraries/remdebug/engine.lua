--[[---------------------------------------------------------------------------
-- RemDebug 1.0, Renoise Edition
-- Remote Debugger for Renoise Lua scripts, based on the
-- Kepler Projects remdebug (http://www.keplerproject.org/remdebug)
---------------------------------------------------------------------------]]--

local debug = require "debug"

module("remdebug.engine", package.seeall)

_COPYRIGHT = "2006 - Kepler Project, 2011 - Renoise.com"
_DESCRIPTION = "Remote Debugger for Renoise Lua " ..
  "scripts, based on the Kepler Project remdebug"
_VERSION = "1.0"

local _assert = _G.assert
local _print = _G.print
    
local stdout

local coro_debugger
local debug_server

local events = { BREAK = 1, WATCH = 2 }

local breakpoints = {}
local watches = {}

local step_into = false
local step_over = false
local step_level = 0
local stack_level = 0

local controller_host = "localhost"
local controller_port = 8171


-------------------------------------------------------------------------------
-- set_breakpoint

local function set_breakpoint(file, line)
  _assert(type(file) == 'string' and 
    type(line) == 'number')
  
  local file_key
  if (os.platform() == 'WINDOWS') then
    file_key = file:lower()
  else
    file_key = file
  end
     
  if (not breakpoints[file_key]) then
    breakpoints[file_key] = {}
  end
  
  breakpoints[file_key][line] = true
end


-- remove_breakpoint

local function remove_breakpoint(file, line)
  _assert(type(file) == 'string' and 
    type(line) == 'number')
  
  local file_key
  if (os.platform() == 'WINDOWS') then
    file_key = file:lower()
  else
    file_key = file
  end
  
  if (breakpoints[file_key]) then
    breakpoints[file_key][line] = nil
  end
end


-- has_breakpoint

local function has_breakpoint(file, line)
  if (file and line) then
    _assert(type(file) == 'string' and 
      type(line) == 'number')
    
    local file_key
    if (os.platform() == 'WINDOWS') then
      file_key = file:lower()
    else
      file_key = file
    end
    
    return breakpoints[file_key] and 
      breakpoints[file_key][line]
  else
    return false
  end
end


--  break_dir

local function break_dir(path)
  _assert(type(path) == 'string')
  
  local paths = {}
  
  path = path:gsub("\\", "/")
  for w in path:gfind("[^\/]+") do
    table.insert(paths, w)
  end
  
  return paths
end


--  file_exists

local function file_exists(filename)
  local file = io.open(filename)
  if (file ~= nil) then
    file:close()
    return true
  else
    return false
  end
end


--  merge_paths

local function merge_paths(path1, path2)
  local paths1 = break_dir(path1)
  local paths2 = break_dir(path2)
  
  for i, path in ipairs(paths2) do
    if (path == "..") then
      table.remove(paths1, table.getn(paths1))
    elseif (path ~= ".") then
      table.insert(paths1, path)
    end
  end
  
  if path1:find("^[\/]+") then
    return "/" .. table.concat(paths1, "/")
  else
    return table.concat(paths1, "/")
  end
end


-------------------------------------------------------------------------------
--  stack_depth

function stack_depth()
  local depth = 1
  for _ in function() return debug.getinfo(depth) end do
    depth = depth + 1
  end
  
  depth = depth - 2
  return depth
end


--  restore_vars

local function restore_vars(vars)
  if (type(vars) ~= 'table') then 
    return 
  end
  
  -- disable sctrict mode here, when enabled
  local _strict = _G._STRICT
  _G._STRICT = false
    
  local func = debug.getinfo(3, "f").func
  local i = 1
  local written_vars = {}
  
  while true do
    local name = debug.getlocal(3, i)
    if not name then break end
    -- ignoring internal control variables
    if vars[name] and string.sub(name,1,1) ~= '(' then
      debug.setlocal(3, i, vars[name])
      written_vars[name] = true
    end
    i = i + 1
  end
  
  i = 1
  while true do
    local name = debug.getupvalue(func, i)
    if not name then break end
    -- ignoring internal control variables
    if vars[name] and string.sub(name,1,1) ~= '(' then
      if not written_vars[name] then
        debug.setupvalue(func, i, vars[name])
        written_vars[name] = true
      end
    end
    i = i + 1
  end
  
  _G._STRICT = _strict
end


--  capture_vars

local function capture_vars()
  -- disable sctrict mode here, when enabled
  local _strict = _G._STRICT
  _G._STRICT = false
  
  
  local vars = { 
    __locals = {},
    __upvalues = {}
  }
  
  local func = debug.getinfo(3, "f").func
  
  local i = 1
  while true do
    local name, value = debug.getupvalue(func, i)
    if not name then break end
    if string.sub(name,1,1) ~= '(' then
      vars[name] = value
      vars.__upvalues[name] = value
    end
    i = i + 1
  end
  
  i = 1
  while true do
    local name, value = debug.getlocal(3, i)
    if not name then break end
    if string.sub(name,1,1) ~= '(' then
      vars[name] = value
      vars.__locals[name] = value
    end
    i = i + 1
  end
  
  setmetatable(vars, { 
    __index = getfenv(func), 
    __newindex = getfenv(func) 
  })
  
  _G._STRICT = _strict
  
  return vars
end


-------------------------------------------------------------------------------
--  debug_hook

local function debug_hook(event, line)
  stack_level = stack_depth()

  local file = debug.getinfo(2, "S").source
  
  -- completely ignore sources with no files (internal scripts)
  if (file and file:find("@") == 1) then
    file = string.sub(file, 2)
    
    -- use an abs paths for file, if possible and necessary 
    local merged_file = merge_paths(os.currentdir(), file)
    if file_exists(merged_file) then
      file = merged_file
    end

    local vars = capture_vars()
      
    table.foreach(watches, function (index, value)
      setfenv(value, vars)
      local status, res = pcall(value)
      if (status and res) then
        coroutine.resume(coro_debugger, 
          events.WATCH, vars, file, line, index)
      end
    end)

    if (step_into) or 
       (step_over and stack_level <= step_level) or
       (has_breakpoint(file, line))
    then
      step_into = false
      step_over = false
      
      if (coroutine.resume(coro_debugger, 
            events.BREAK, vars, file, line)) then
        restore_vars(vars)
      else
        error("Remdebug error: failed to resume the debugged thread")
      end
    end
  end
end


-------------------------------------------------------------------------------
-- debugger_loop

local function debugger_loop(server)

  local eval_env = {}

  while true do
    local command_line, status

    repeat
      local socket_timeout = 2000
      command_line, status = server:receive("*l", socket_timeout)
    until (command_line ~= nil or not server.is_open)

    if (not command_line) then 
      stop()
      break 
    end
    
    local _, _, command = command_line:find("^([A-Z]+)")
    
    
    -- setb
    
    if (command == "SETB") then
      local _, _, filename, line = 
        command_line:find("^[A-Z]+%s+([%w%p%s]+)%s+(%d+)%s*$")
            
      if (filename and line) then
        set_breakpoint(filename, tonumber(line))
        server:send("200 OK\n")
      else
        server:send("400 Bad Request\n")
      end
    
    
    -- delb
    
    elseif (command == "DELB") then
      local _, _, filename, line = 
        command_line:find("^[A-Z]+%s+([%w%p%s]+)%s+(%d+)%s*$")
      
      if (filename and line) then
        remove_breakpoint(filename, tonumber(line))
        server:send("200 OK\n")
      else
        server:send("400 Bad Request\n")
      end
   
    
    -- exec
    
    elseif (command == "EXEC") then
      local _, _, chunk = 
        command_line:find("^[A-Z]+%s+(.+)$")
      
      if chunk then
        local func = loadstring(chunk)
        local status, res
        
        if func then
          setfenv(func, eval_env)
          status, res = xpcall(func, debug.traceback)
        end
        
        res = tostring(res)
        
        -- also pass pending std out from print
        if (stdout and stdout ~= "") then
          if (res == "nil") then
            res = stdout                      
          else
            res = res .. stdout
          end
          stdout = nil
        end
        
        if (status) then
          server:send(("200 OK %d\n"):format(string.len(res)))
          server:send(res)
        else
          server:send(("401 Error in Execution %d\n"):format(
            string.len(res)))
          server:send(res)
        end
      else
        server:send("400 Bad Request\n")
      end
   
    
    -- setw
    
    elseif (command == "SETW") then
      local _, _, exp = command_line:find("^[A-Z]+%s+(.+)%s*$")
      if exp then
        local func = loadstring("return(" .. exp .. ")")
        local newidx = table.getn(watches) + 1
        watches[newidx] = func
        server:send("200 OK " .. newidx .. "\n")
      else
        server:send("400 Bad Request\n")
      end
   
    
    -- delw
    
    elseif (command == "DELW") then
      local _, _, index = command_line:find("^[A-Z]+%s+(%d+)%s*$")
      index = tonumber(index)
      if index then
        watches[index] = nil
        server:send("200 OK\n")
      else
        server:send("400 Bad Request\n")
      end
   

    -- run
    
    elseif (command == "RUN") then
      server:send("200 OK\n")
      local ev, vars, file, line, idx_watch = coroutine.yield()
      eval_env = vars
      if (ev == events.BREAK) then
        server:send(("202 Paused %s %s\n"):format(file, line))
      elseif (ev == events.WATCH) then
        server:send(("203 Paused %s %s %s\n"):format(file, line, idx_watch))
      else
        server:send(("401 Error in Execution %d\n"):format(string.len(file)))
        server:send(file)
      end
   
    
    -- step
    
    elseif (command == "STEP") then
      server:send("200 OK\n")
      step_into = true
      local ev, vars, file, line, idx_watch = coroutine.yield()
      eval_env = vars
      if ev == events.BREAK then
        server:send(("202 Paused %s %s\n"):format(file, line))
      elseif ev == events.WATCH then
        server:send(("203 Paused %s %s %s\n"):format(file, line, idx_watch))
      else
        server:send(("401 Error in Execution %d\n"):format(string.len(file)))
        server:send(file)
      end
    
    
    -- over
    
    elseif (command == "OVER") then
      server:send("200 OK\n")
      step_over = true
      step_level = stack_level
      local ev, vars, file, line, idx_watch = coroutine.yield()
      eval_env = vars
      if ev == events.BREAK then
        server:send(("202 Paused %s %s\n"):format(file, line))
      elseif ev == events.WATCH then
        server:send(("203 Paused %s %s %s\n"):format(file, line, idx_watch))
      else
        server:send(("401 Error in Execution %d\n"):format(string.len(file)))
        server:send(file)
      end
   
   
    -- stdout
    
    elseif (command == "STDOUT") then
      local res = stdout or ""
      stdout = nil

      server:send(("200 OK %d\n"):format(string.len(res)))
      server:send(res)
    
    
    -- locals
    
    elseif (command == "LOCALS") then
      local function _serialize(obj)
        local succeeded, result = pcall(tostring, obj)
        return succeeded and result or "???"
      end
      
      local res = ""
      for k,v in pairs(eval_env.__locals) do
        res = res .. _serialize(k) .. ' = ' .. _serialize(v) .. '\n'
      end
      
      server:send(("200 OK %d\n"):format(string.len(res)))
      server:send(res)

    
    -- default
    
    else
      server:send("400 Bad Request\n")
    end
  end
end


-------------------------------------------------------------------------------
-- remdebug.engine.config(tab)
-- Configures the engine
-------------------------------------------------------------------------------

function config(t)
  _assert(type(t) == "table")
  
  if t.host then
    controller_host = t.host
  end
  
  if t.port then
    controller_port = t.port
  end
end


-------------------------------------------------------------------------------
-- remdebug.engine.start()
-- Tries to start the debug session by connecting with a controller
-------------------------------------------------------------------------------

function start()
  pcall(require, "remdebug.config")

  -- reset status
  if debug_server then 
    stop()
  end
    
  breakpoints = {}
  watches = {}
  
  step_into = false
  step_over = false
  step_level = 0
  stack_level = 0
  
  stdout = nil
  
  -- connect
  local server, server_error
  local start_time = os.clock()
  
  repeat
    server, server_error = renoise.Socket.create_client(
      controller_host, controller_port)
    -- wait a bit until the controller started...
  until (server or os.clock() - start_time > 2.0) 
  
  if server then
    debug_server = server

    -- enable hooks
    debug.sethook(debug_hook, "l")

    _assert = _G.assert
    _G.assert = function(expression, message)
      if not expression then
        debug.sethook()
        _G.assert = _assert 
        
        local stack_trace =  debug.traceback(message) or ""
        debug_server:send(("401 Error in Execution %d\n"):format(
          string.len(stack_trace)))
        debug_server:send(stack_trace)
        debug_server:close()
        debug_server = nil
        
        error(message)
      end
      return expression, message
    end
      
    _print = _G.print
    _G.print = function(...)
      if (_print ~= _G.print) then
        _print(...)
      end
      
      stdout = stdout or ""

      local n = select('#', ...)
      for i = 1, n do
        local value = tostring(select(i, ...))
        stdout = stdout .. value
        if (i ~= n) then 
          stdout = stdout .. "\t"
        end
      end
      
      stdout = stdout .. "\n"
    end
    
    -- start running
    coro_debugger = coroutine.create(debugger_loop)
    return _assert(coroutine.resume(coro_debugger, server))
  else
    error(("Remdebug Error: connection failed: '%s'"):format(server_error))
  end
end


-------------------------------------------------------------------------------
-- remdebug.engine.stop()
-- stops a debug session by disconnecting from the controller
-------------------------------------------------------------------------------

function stop()
  -- disconnect from the server
  if debug_server then
    if (debug_server.is_open) then
      debug_server:close()
    end
    debug_server = nil
  end

  -- disable all hooks
  debug.sethook()
  _G.assert = _assert 
  _G.print = _print
end


--[[---------------------------------------------------------------------------
---------------------------------------------------------------------------]]--
