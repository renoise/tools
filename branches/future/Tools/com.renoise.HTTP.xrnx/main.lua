-------------------------------------------------------------------------------
--  Requires
-------------------------------------------------------------------------------

require "log"
require "util"

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

function Request:__init(url, method, save_file)
  method = method or Request.GET
  
  self.url = url
  self.method = method
  self.save_downloaded_file = save_file 
  
  self.client = nil
  self.contents = table.create {}
  self.length = 0
  self.complete = false

  self.callback = function(socket_error) end
end


-- read_header

function Request:read_header()  
  
  -- connect 
  local parsed_url = Util:parse(self.url)

  if not (parsed_url and parsed_url.host) then
     return false, "Invalid URL"
  end
  
  local client, socket_error = renoise.Socket.create_client(
    parsed_url.host, 80, renoise.Socket.PROTOCOL_TCP)

  self.client = client
  
  if not (client) then
     return false, socket_error
  end
  
  -- request content
  local get_request = string.format(
    "%s %s HTTP/1.1\nHost: %s\r\n\r\n",
    self.method, parsed_url.path, parsed_url.host)

  local ok, socket_error = client:send(get_request)
  
  if not (ok) then
    return false, socket_error
  end
  
  -- read the header
  local header_lines = table.create {}
     
  while true do 
    local line = self.client:receive("*l", 1000)
    if (not line) then 
      break -- unexpected EOF
    end
    
    if (line == "") then 
      break -- header ends with an empty line
    end 
    
    header_lines:insert(line)
  end

  log:info(("=== HEADER (%s) ==="):format(self.url))
  rprint(header_lines)
  print("\n")
  
  self.header = Util:parse_message(header_lines:concat("\n"))
  
  if (self.header) then
    return true
  else
    return false, "Invalid page header"
  end
end


-- read_content

function Request:read_content()
  assert(self.client and self.header, 
    "read_header failed or was not called")
  
  -- read all pending data
  local timeout = 0
  
  local buffer, socket_error = 
    self.client:receive("*all", timeout)
  
  if (buffer) then
  -- got new data
    self.contents:insert(buffer)
    self.length = self.length + #buffer

    -- log
    if (self.length > 10 * 1024) then
      log:info(string.format("%d kbytes read (%s)", 
        self.length / 1024, self.url))
    else
      log:info(string.format("%d bytes read (%s)", 
        self.length, self.url))
    end
    
    if (self.length >= tonumber(self.header["Content-Length"])) then
      -- done
      self:do_callback()
      return false
    else
      -- continue reading
      return true
    end
    
  else
  -- timeout or error
    
    if (socket_error == "timeout") then
      -- retry next time (TODO: give up at soume point)
      log:info(string.format("read timeout (%s)", self.url))
      return true
    else
      -- cancel request
      self:do_callback(socket_error)
      return false
    end
  end
end


-- do_callback

function Request:do_callback(socket_error)

  -- log
  log:info(("=== CONTENT (%d bytes from %s) ==="):format(
    self.length, self.url))
  if (self.length <= 32 * 1024) then
    rprint(self.contents)
  else
    print(" *** lots of content (> 32 kbytes) *** ")
  end
  
  if (socket_error) then
    log:info(("%s failed with error: '%s'."):format(self.url, socket_error))
  else
    log:info(("%s has completed."):format(self.url))  
    
    if (self.save_downloaded_file) then
      local _, _, filename, extension = self.url:find(".+[/\\](.+)%.(.+)$")
      assert(filename and extension, "failed to extract the filename")
      
      local file_name_and_path = renoise.app():prompt_for_filename_to_write(
        extension, ("Save %s.%s as"):format(filename, extension))
      
      if (file_name_and_path and file_name_and_path ~= "") then
        local file = io.open(file_name_and_path, "wb")
        
        if (file) then
          for _,buffer in pairs(self.contents) do
            file:write(buffer)
          end
          file:close()
        else
          log:info(("failed to open '%s' for writing."):format(
            file_name_and_path))  
        end
      end
    end
  end
  
  -- close the connection and invalidate
  self.client = nil
  self.header = nil

  -- invoke the external callback (if set)
  self.callback(socket_error)
end


-------------------------------------------------------------------------------
-- Idle handler

-- Read a few bytes from every request
local function read()
  for k,request in ipairs(requests) do
    if not (request.complete) then
      request.complete = not (request:read_content())
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
  local new_request = Request(url, method)
  local succeeded, socket_error = new_request:read_header()

  if (succeeded) then
    requests:insert(new_request)
  else
     log:info(("%s failed: %s."):format(url, 
       (socket_error or "[unknown error]")))
  end
end

function http_download_file(url)
  local save_file = true
  local new_request = Request(url, Request.GET, save_file)
  local succeeded, socket_error = new_request:read_header()

  if (succeeded) then
    requests:insert(new_request)
  else
     log:info(("%s failed: %s."):format(url, 
       (socket_error or "[unknown error]")))
  end
end

function start()
  http("http://www.renoise.com/download/checkversion.php")
  http("http://www.renoise.com/download/")
  http("http://www.renoise.com/")
  
  http("http://qwe.renoise.com/invalid_host_name.php")
  http("htsj:invalid_url")
  
  -- http_download_file("http://mirror.renoise.com/download/Renoise_2_5_1_Demo.exe")
  -- http("http://nl.archive.ubuntu.com/ubuntu-cdimages/10.04/release/ubuntu-10.04-dvd-amd64.iso")
end


-------------------------------------------------------------------------------
--  Idle notifier
-------------------------------------------------------------------------------

renoise.tool().app_idle_observable:add_notifier(function()
  if (active and not read()) then
     active = false;
  end
end)

