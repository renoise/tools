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

local requests = table.create()
local active = true

class "Request"

Request.GET = "GET"
Request.POST = "POST"
Request.HEAD = "HEAD"
Request.OPTIONS = "OPTIONS"

function Request:__init(url, method)
  method = method or Request.GET
  local parsed_url = Util:parse(url)

  local get_request = string.format(
    "%s %s HTTP/1.1\nHost: %s\r\n\r\n",
    method, parsed_url.path, parsed_url.host)

  local client = renoise.Socket.create_client(
    parsed_url.host, 80,  renoise.Socket.PROTOCOL_TCP)

  local ok, err = client:send(get_request)

  self.complete = false
  self.url = url
  self.contents = table.create()
  self.callback = function() end
  self.reader = SocketReader(client)
  self.length = 0
  self.header = table.create {}

  self:get_header()
end

function Request:get_header()      
    while true do 
      local line = self.reader:read_line()
      if (not line) then 
        break -- unexpected EOF
      end
      
      if (line == "") then 
        break -- header ends with an empty line
      end 
      
      self.header:insert(line)
    end

    log:info("=== HEADER ===")
    rprint(self.header)
    print("\r\n")
end

function Request:do_callback()
--  log:info("=== CONTENT ===")
--  rprint(self.contents)
  self.callback()
  log:info(self.url .. " has completed.")  
end

function Request:inc_length(amt)
  self.length = self.length + amt
end

function Request:get_content(mode, timeout)
  local buffer, err = self.reader:read(mode, timeout)
  if (not buffer) then
    self:do_callback()
    return false
  else
    self.contents:insert(buffer)
    self:inc_length(#buffer)
    log:info(string.format("%d bytes read (%s)", self.length, self.url))
    return #buffer
  end
end


-------------------------------------------------------------------------------
-- Idle handler

-- Read a few bytes from every request
local function read()
    for k,request in ipairs(requests) do
      if not request.complete then
        local bytes_received = request:get_content(1460, 10)
        if (not bytes_received) then
          request.complete = true
        end
      end
    end
    return true
end

-------------------------------------------------------------------------------
-- do we have an internet connection?

function connected()
  return true
end

-------------------------------------------------------------------------------

function http(url, method)
   requests:insert(Request(url, method))
end

function start()
  http("http://www.renoise.com/download/checkversion.php")
  http("http://www.renoise.com/download/")
  http("http://www.renoise.com/")
  --request("http://nl.archive.ubuntu.com/ubuntu-cdimages/10.04/release/ubuntu-10.04-dvd-amd64.iso")
end

-------------------------------------------------------------------------------
--  Idle notifier
-------------------------------------------------------------------------------

renoise.tool().app_idle_observable:add_notifier(function()
  if (active and not read()) then
     active = false;
  end
end)
