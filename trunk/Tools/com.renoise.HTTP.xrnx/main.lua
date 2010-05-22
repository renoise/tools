-------------------------------------------------------------------------------
--  Requires
-------------------------------------------------------------------------------

require "log"
require "util"
require "SocketReader"

local log = Log(Log.ALL)

-------------------------------------------------------------------------------
--  Menu registration
-------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Update",
  active = function() 
    return connected()
  end,
  invoke = function()
    start()
  end
}

-------------------------------------------------------------------------------
--  Debug
-------------------------------------------------------------------------------

if true then 
  require "remdebug.engine"
  
  _AUTO_RELOAD_DEBUG = function()
    start()
  end
end 

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------

local readers = table.create()
local contents = table.create()
local callback = table.create()
local active = true

local function complete(key)
  log:info(callback[key] .. " has completed.")
  rprint(contents[key])
end

local function read()
   -- read content
    local content = table.create {}

    for k,r in ipairs(readers) do
      local buffer = r:read_bytes(1024*4, 200)
      if (not buffer) then
        readers[k] = nil
        complete(k)
      else
        contents[k]:insert(buffer)
      end
    end
    return true
end

--  request

local function request(url, method)
  
  local parsed_url = Util:parse(url)
  
  local get_request = string.format(
    "GET %s HTTP/1.1\nHost: %s\r\n\r\n", 
    parsed_url.path, parsed_url.host)
  
  local client = renoise.Socket.create_client(
    parsed_url.host, 80,  renoise.Socket.PROTOCOL_TCP)        
  
  local ok, err = client:send(get_request)
  
  if ok then
    local reader = SocketReader(client)
    
    -- read header
    local header = table.create {}
  
    while true do 
      local line = reader:read_line()
      if (not line) then 
        break -- unexpected EOF
      end
      
      if (line == "") then 
        break -- header ends with an empty line
      end 
      
      header:insert(line)
    end
  
    log:info("=== HEADER")
    rprint(header)

    -- read content
    local content = table.create {}
    contents:insert(content)
    readers:insert(reader)
    callback:insert(url)
    
    -- OR
    -- content:insert(reader:read_bytes(content_lenght from header))
    
    log:info("=== CONTENT")
    rprint(content)
    
  else
    return err
  end
end



-------------------------------------------------------------------------------

-- do we have an internet connection?

function connected()
  return true
end


-------------------------------------------------------------------------------

function start()  
  request("http://www.renoise.com/download/checkversion.php")
--  request("http://www.renoise.com/download/")
--  request("http://nl.archive.ubuntu.com/ubuntu-cdimages/10.04/release/ubuntu-10.04-dvd-amd64.iso")
end

-------------------------------------------------------------------------------
--  Idle notifier
-------------------------------------------------------------------------------

renoise.tool().app_idle_observable:add_notifier(function()
  if (active and not read()) then
     active = false;
  end
end)