-------------------------------------------------------------------------------
--  SocketReader
-------------------------------------------------------------------------------

--[[ 
  
  Helper class to do read content from a socket in various modes (line by 
  line, by size, the full content).

  Uses an internal buffer to buffer, so it should not be reused, but thrown 
  away after the expected content was read...
  
]]

class "SocketReader"

function SocketReader:__init(socket)
  assert(socket and socket.is_open, "expected an open socket")
  
  self.__socket = socket
  self.__buffer = ""
  self.__done = false
end


-------------------------------------------------------------------------------

-- read from a socket with the given mode. mode is a Lua file io alike mode 
-- identifier, which can either be "*l" to read a line, "*all" to read 
-- everything until the EOF, error or timeout, or a number to read the 
-- specified number of bytes from the socket.
--
-- Note: this is just a shortcut to the readers "read_line", "read_bytes" and 
-- "read_all" methods. Please have a look at them for more info about the 
-- individual modes.

function SocketReader:read(mode, timeout)
  if (mode == "*l") then
    return self:read_line(timeout)
  
  elseif (mode == "*all") then
    return self:read_all(timeout)
  
  elseif (tonumber(mode) and tonumber(mode) > 0) then
    return self:read_bytes(tonumber(mode), timeout)
  
  else
    error("unknown SocketReader:read 'mode' argument: "..
      "expected '*l', '*all' or a number > 0.")
  end
end


-------------------------------------------------------------------------------
    
-- reads a line from a socket with the given timeout.
--
-- returns the line content (without the newline character) on success as first
-- return value, else the remaining content or nil on timeouts or errors. on 
-- errors, the error will be returned as the second return value

function SocketReader:read_line(timeout)
  timeout = timeout or 500
  assert(timeout > 0, "invalid timeout")
  
  if (self.__done) then
    return nil, nil
  end
  
  while true do 
    local line_start, line_end, line = self.__buffer:find("(.-)\r?\n")
    
    if (line ~= nil) then
      self.__buffer = self.__buffer:sub(line_end + 1) 
      return line, nil
    end
    
    local new_content, socket_error = self.__socket:receive(timeout)
    
    if (new_content ~= nil) then 
      self.__buffer = self.__buffer .. new_content
    else
      local remaining = self.__buffer
      self.__buffer = ""
      
      self.__done = true 
      return remaining, socket_error
    end
  end
end


-------------------------------------------------------------------------------

-- reads up to \param num_bytes from a socket with the given timeout
-- please note that the timeout will be applied each time the socket is read,
-- so the max time it takes to read all content is not necessarily smaller 
-- than the timeout
--
-- returns either the num_bytes sized content, remaining content or nil on 
-- errors as first return value. In case of an error or timeout the error 
-- will be passed as second return value

function SocketReader:read_bytes(num_bytes, timeout)
  assert(num_bytes > 0, "invalid num_bytes")
  
  timeout = timeout or 500
  assert(timeout > 0, "invalid timeout")
  
  if (self.__done) then
    return nil, nil
  end

  while true do 
    if (#self.__buffer >= num_bytes) then
      local result = self.__buffer:sub(1, num_bytes)
      self.__buffer = self.__buffer:sub(num_bytes + 1)
      return result, nil
    end
    
    local new_content, socket_error = self.__socket:receive(timeout)
    
    if (new_content ~= nil) then 
      self.__buffer = self.__buffer .. new_content
    
    else
      local remaining = self.__buffer
      self.__buffer = ""
      
      self.__done = true 
      return remaining, socket_error
    end
  end
end


-------------------------------------------------------------------------------

-- reads up to EOF, timeouts or errors from a socket with the given timeout
--
-- returns the content as first return value on success, else nil. The error 
-- or timeout is then passed as second return value

function SocketReader:read_all(timeout)
  timeout = timeout or 500
  assert(timeout > 0, "invalid timeout")
  
  if (self.__done) then
    return nil, nil
  end
  
  while true do 
    local new_content, socket_error = self.__socket:receive(timeout)
    
    if (new_content ~= nil) then 
      self.__buffer = self.__buffer .. new_content
    
    else
      local remaining = self.__buffer
      self.__buffer = ""
      self.__done = true 
      return remaining, socket_error
    end
  end
end
