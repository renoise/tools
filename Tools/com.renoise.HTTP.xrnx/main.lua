-------------------------------------------------------------------------------
--  Requires
-------------------------------------------------------------------------------

require "log"
require "util"
local json = require("json")

local log = Log(Log.ALL)

local vb = nil

-------------------------------------------------------------------------------
--  Menu registration
-------------------------------------------------------------------------------

local entry = {}

entry.name = "Main Menu:Tools:Update..." 
entry.active = function() return connected() end
entry.invoke = function() update_start() end
renoise.tool():add_menu_entry(entry)

entry.name = "Main Menu:Tools:Search Online Manual..." 
entry.active = function() return connected() end
entry.invoke = function() search_start() end
renoise.tool():add_menu_entry(entry)

-------------------------------------------------------------------------------
--  Debug
-------------------------------------------------------------------------------

if false then 
  require "remdebug.engine"
  
  _AUTO_RELOAD_DEBUG = function()
    update_start()
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

function Request:__init(url, method, data, callback, dataType, save_file)
  method = method or Request.GET
  
  local url_parts = URL:parse(url)
  self.url = url
  self.data = data  
  self.dataType = dataType or "text"
  self.dataType = self.dataType:lower()
  
  self.method = method
  self.save_downloaded_file = save_file 
  
  self.client = nil
  self.contents = table.create {}
  self.length = 0
  self.complete = false
  self.post = ""
  self.header_map = table.create {}

  self.callback = function( res, status, self ) print(type(res), type(status)) end

  self.data = Request:create_query_string(data)        

  if (method == Request.GET) then 
    if (not url_parts.query) then
      self.url = self.url .. "?" .. self.data
    else 
      self.url = self.url .. "&" .. self.data
    end
  elseif (method == Request.POST) then 
    self.post = self.data:gsub("%%20", "+")
    self:set_header("Content-Type", "application/x-www-form-urlencoded")
  end  
end

function Request:set_header(name, value)
  self.header_map[name] = value
end

function Request:create_query_string(data)
  local str = ""
  for k,v in pairs(data) do
    str = str .. "&" .. k .. "=" .. v 
  end
  return Util:html_entity_encode(str:sub(2))
end


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
  
  local query = " "
  if (parsed_url.query) then
    query = "?" .. parsed_url.query
  end

  -- request content
  local header = string.format("%s %s%s HTTP/1.1\r\n", self.method, parsed_url.path, query)
  self:set_header("Host", parsed_url.host)
  self:set_header("User-Agent",  
    string.format( "Renoise %s (%s)", renoise.RENOISE_VERSION, os.platform():lower() )
  )        
  self:set_header("Connection", "keep-alive")
  self:set_header("Content-Length", #self.post)
  for k,v in pairs(self.header_map) do
    header = string.format("%s%s: %s\r\n",header,k,v)
  end     
  header = header .. "\r\n" 
  
  log:info("=== REQUEST HEADERS ===\n" .. header)
  
  local ok, socket_error = client:send(header)
  local ok, socket_error = client:send(self.post)  
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
  
  -- TODO process dataTypes
  local data = self.contents
  if (self.dataType == "json") then
    data = json.decode(self.contents:concat())
  elseif (self.dataType == "osc") then  
  elseif (self.dataType == "lua_array") then 
  elseif (self.dataType == "xml") then
    -- parse XML into table
  elseif (self.dataType == "lua") then 
    -- evaluate Lua
  elseif (self.dataType == "html") then 
    -- parse HTML to text+layout
  end
    
  -- invoke the external callback (if set)
  self.callback( data, socket_error, self )
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

function http(url, method, data, callback, dataType)
  local new_request = Request(url, method, data, callback, dataType)
  if (callback) then 
    new_request.callback = callback 
  end
  local succeeded, socket_error = new_request:read_header()

  if (succeeded) then
    requests:insert(new_request)
  else
     log:info(("%s failed: %s."):format(url, 
       (socket_error or "[unknown error]")))
  end
end

function post(url, data, callback, dataType)
  http(url, Request.POST, data, callback, dataType)
end

function get(url, data, callback, dataType)
  http(url, Request.GET, data, callback, dataType)
end

function http_download_file(url)
  local save_file = true
  local new_request = Request(url, Request.GET, nil,nil,nil, save_file)
  local succeeded, socket_error = new_request:read_header()

  if (succeeded) then
    requests:insert(new_request)
  else
     log:info(("%s failed: %s."):format(url, 
       (socket_error or "[unknown error]")))
  end
end

function update_start()
  -- Renoise Version Check; using HTTP Header "User-Agent"
  post("http://www.renoise.com/download/checkversion.php", {output="raw"}, 
    function(res, err)  
      if (res) then
        local buttons = table.create{"OK", "Go to downloads"}
        local choice = renoise.app():show_prompt(
          "Checking for Renoise updates", 
          table.concat(res), buttons)
        if (choice == buttons[2]) then
          renoise.app():open_url("http://www.renoise.com/download/renoise/")
        end  
      end
    end)
end


local search_cache = ""
local has_results = false

-- Don't query the derivative string if the search_cache
-- didn't return any results;
local function check_search_cache(str)  
  return (type(str) == "string" and
     str:match(string.format("^%s[.+]",search_cache)) and 
     has_results)  
end
  
local function autocomplete(str, callback)      
  local callback = callback or function(data) rprint(data) end
  if (#str == 0 or check_search_cache(str)) then 
    return
  end
  
  get("http://tutorials.renoise.com/api.php", 
    {action="opensearch",search=str}, 
    function( res, err )          
      search_cache = str
      has_results = #res[2] > 0
      callback(res)
    end, "json")    
end

local function set_input(str)
  vb.views.input.text = str
end

local function get_input()
  return vb.views.input.text
end
  
local function show_results(data)
  while (#data < 2) do
    table.insert(data,"---")
  end 
  -- TODO limit list size
  vb.views.results.items = data
end

local function get_selected_result()
  local index = vb.views.results.value
  return vb.views.results.items[index]
end

local function search_callback(text)
  autocomplete(text, 
    function(data)
      show_results(data[2])
    end)      
end

local function open_url(str)
   if (str ~= "---") then
     renoise.app():show_status("Opening help page for " .. str .. "...")
     renoise.app():open_url("http://tutorials.renoise.com/wiki/"
       .. get_selected_result())
   end
end

function search_start()
  vb = renoise.ViewBuilder()
  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local buttons = table.create{"Go"}
  local dialog_content =vb:horizontal_aligner {
    margin = DEFAULT_MARGIN,
    vb:column {
      style = "group",
      margin = DEFAULT_MARGIN,
      width = "100%",
      
      vb:text {
        id = "input",
      },                
      
      vb:chooser {
          id = "results",
          items = {"--", "--"},
          notifier = function(value)             
            set_input(get_selected_result()) 
          end   
      },
                
      vb:button {
        text = "Go",
        notifier = function() 
          open_url(get_selected_result())
        end
      }
    }
  }
  
  local function reset_input()
    set_input("Type keyword")
    show_results{}
  end
  
  local arrows = table.create{"up","down","left","right"}
    
  local function keyhandler(dialog, mod_string, key_string)    
    local str = get_input()
    local index = vb.views.results.value
    
    if (key_string == "return") then
      open_url(get_selected_result())
      return
    end

    if (key_string == "up") then    
      index = index - 1
    elseif (key_string == "down") then
      index = index + 1
    end
    
    if (index < 1) then
      vb.views.results.value = 1
    elseif (index > #vb.views.results.items) then
      vb.views.results.value = #vb.views.results.items
    else 
      vb.views.results.value = index
    end       
    
    if (str == "Type keyword" or key_string == "esc") then
        str = ""
    end        
    
    if (key_string == "back") then
      str = str:sub(1,-2)    
    end
    
    if (#key_string == 1) then      
      if (mod_string == "shift") then
        key_string = key_string:upper()
      end
      str = str .. key_string
    end        
    
    set_input(str)
    
    if (#str == 0) then
      reset_input()
    else
      search_callback(str)
    end    
  end

  reset_input()
  
  renoise.app():show_custom_dialog("Search Online Manual", 
    dialog_content, keyhandler);
  
end


-------------------------------------------------------------------------------
--  Idle notifier
-------------------------------------------------------------------------------

renoise.tool().app_idle_observable:add_notifier(function()
  if (active and not read()) then
     active = false;
  end
end)

