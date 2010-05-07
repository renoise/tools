-------------------------------------------
--  Renoise Network Interface
-------------------------------------------

manifest = {}
manifest.api_version = 0.3
manifest.author = "bantai [marvin@renoise.com]"
manifest.description = "Exposes Renoise functions through networking"

-- require "remdebug.engine"

manifest.actions = {}
manifest.actions[#manifest.actions + 1] = {
  name = "MainMenu:Tools:WebServer",
  description = "Webserver",
  invoke = function()
--    remdebug.engine.start() -- debugger will connect and initially break here
    start_server()
--    remdebug.engine.stop()
  end
}

manifest.notifications = {}
manifest.notifications.app_idle = function()
end

manifest.notifications.auto_reload_debug = function()
  start_server()
end

-------------------------------------------
-- Requires and initialization
-------------------------------------------

-- Hack: load GlobalMidiActions.lua from Libraries/..
local package_path = package.path
package.path  = package.path:gsub("[\\/]Libraries", "")

require "GlobalMidiActions"
package.path = package_path

require "WebServer.Log"
local log = Log(Log.ALL)

local expand = require "WebServer.Expand"

local echo_server = nil
local errors = {}
local action_names = {}

local message = {
  boolean_value = nil,
  int_value = nil,
  
  value_min_scaling = 0.0,
  value_max_scaling = 1.0,
  
  is_trigger = function() return true end,
  is_switch = function() return false end,
  is_rel_value = function() return false end,
  is_abs_value = function() return false end
}

for k,v in pairs(available_actions()) do
  -- do not include window/dialog actions in unit tests...
  if not string.find(v, "Window") and
     not string.find(v, "Dialog") and
     -- also Sequence muting, or tests will take days
     not string.find(v, "Sequence XX") and
     not string.find(v, "Seq. XX") then
    action_names[#action_names + 1] = v
  end
end

--log:info("number of actions;" .. #action_names)
--log:info("action[1];" .. action_names[1])

-------------------------------------------
--  Util functions
-------------------------------------------

local function song()
  return renoise.song()
end

local function find_action(action_name)
  if table.find(action_names,action_name) then
    invoke_action(action_name, message)
  else
    log:warn("Action not found: " .. action_name)
  end
--[[
  if action_names[action_name] then
    log:info("Executing: " .. action_name)
    invoke_action(action_name, message)
  else
    log:warn("Action not found: " .. action_name)
  end
]]--
end

local function split_lines(str)
  local t = {}
  local function helper(line) table.insert(t, line) return "" end
  helper((str:gsub("(.-)\r?\n", helper)))
  return t
end

local function parse_message(m)
  local header = ""
  local body = ""
  local lines = split_lines(m)
  local s = false
  for _,l in pairs(lines) do
    if s then body=body..l.."\r\n" else header=header..l.."\r\n" end
    if l:match("^$") then s = true end
  end
  rprint(lines)
  return header, body
end

local function read_file(file_path)
  local file_ref,err = io.open(file_path,"r")
  if not err then
    local result=file_ref:read("*all")
    io.close(file_ref)
    return result
  else
    return nil,err;
  end
end

-- Compute the difference in seconds between local time and UTC.
local function get_timezone()
  local now = os.time()
  return os.difftime(now, os.time(os.date("!*t", now)))
end

-- Return a timezone string in ISO 8601:2000 standard form (+hhmm or -hhmm)
local function get_tzoffset()  
  local h, m = math.modf(get_timezone() / 3600)
  return string.format("%+.4d", 100 * h + 60 * m)
end

local function html_entity_decode(str)  
  local a,b = str:gsub("%%20", " ")
  a,b = a:gsub("%%5B", "[")
  a,b = a:gsub("%%5D", "]")  
  return a
end

local function get_extension(file)
    return file:match("%.(%a+)$")
end


local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

local config_dir = "./WebServer/"

-- Assumes "#comment" is a comment, "value  key_1 key_2"
local function parse_config_file(filename)
   local str = read_file(config_dir .. filename)
   local lines = split_lines(str)
   local t = {}
   local k, v = nil
   for _,l in ipairs(lines) do
      if not l:find("^(%s*)#") then
        local a = split(l, "%s+")
           for i=2,#a do
              t[a[i]] = a[1]
           end
      end
   end
   return t
end

-------------------------------------------
-- Classes
-------------------------------------------

class "ActionServer"

  ActionServer.document_root = "./WebServer/html"
  
  function ActionServer:__init(address,port)
   self.renoise = renoise 
   -- create a server socket
   local server, socket_error =
     renoise.Socket.create_server(address, port)
   
   if socket_error then 
     renoise.app():show_warning(
       "Failed to start the echo server: " .. socket_error)
   else
     -- start running
     self.server = server
     self.server:run(self)
     log:info("Server running at " .. self:get_address())
   end
  end

  function ActionServer:socket_error(socket_error)
    renoise.app():show_warning(socket_error)
  end
  
  function ActionServer:get_address()
    return self.server.local_address .. ':' .. self.server.local_port
  end

  function ActionServer:get_date()
    return os.date("%a, %d %b %Y %X " .. get_tzoffset())
  end

  function ActionServer:socket_accepted(socket)
    log:info("Socket accepted")
  end

  function ActionServer:parse_post_string(body)
    if #trim(body) == 0 then return {} end
     local p = {}
     for k,v in body:gmatch("([^=&]+)=([^=&]+)") do
       p[trim(k)] = trim(v)
     end
     return p
  end

  function ActionServer:get_MIME(path)
    local ext = get_extension(path)
    local mime = ActionServer.mime_types[ext] or "text/plain"
    log:info("Extension: " .. ext .. "; Content-Type: " .. mime)
  end

  function ActionServer:get_htdoc(path)
    if path == nil then path = "" end
    return ActionServer.document_root .. path
  end

  function ActionServer:is_htdoc(path)
    local fullpath = self:get_htdoc(path)
    local f,err = io.open(fullpath)
    if f then io.close(f) end
    local exists = (f~=nil)
    log:info("Path " .. fullpath .. " exists?: " .. tostring(exists))
    return exists
  end

  function ActionServer:is_expandable(path)
    local extensions = table.create{"lua","html"}
    local path_ext = get_extension(path)
    return extensions:find(path_ext)
  end

  function ActionServer:header(k,v)
   self.header_map[k] = v
  end

  function ActionServer:init_header()
   self.header_map = table.create()
   self.header_map["Date"]  = self:get_date()
   self.header_map["Server"] = "Renoise Vx.xx"
   self.header_map["Cache-Control"] = "max-age=3600, must-revalidate"
   self.header_map["Accept-Ranges"] = "none"
  end

  function ActionServer:send_htdoc(socket, path, status, parameters)
     status = status or "200 OK"

     self:init_header()
     self:header("Content-Type", self:get_MIME(path))

     parameters = parameters or {}
     local fullpath = self:get_htdoc(path)
     local template = read_file(fullpath)
     local page = nil

     if self:is_expandable(path) then
       self:header("Cache-Control", "private, max-age=0")
       page = expand(template, {L=self, renoise=renoise, P=parameters}, _G)
     else
       self:header("Cache-Control", "private, max-age=3600")
       page = template
     end

     self:header("Content-Length", #page)

     local header = "HTTP/1.1 " .. status .. "\r\n"
     for k,v in pairs(self.header_map) do
       header = string.format("%s%s: %s\r\n",header,k,v)
     end
     header = header .. "\r\n"
     socket:send(header)
     socket:send(page)
  end

  function ActionServer:socket_message(socket, message)
      print("\r\n----------MESSAGE RECEIVED----------")
      local header, body = parse_message(message)
      local parameters = nil -- POST and GET variables
      if #trim(body) > 0 then log:info("Body:" .. body) end
      local path = nil
      local methods = table.create{"GET","POST","HEAD",
        "OPTIONS", "CONNECT", "PUT", "DELETE", "TRACE"}
      local method = header:match("^(%w+)%s")

      if method ~= nil then
        method = method:upper()
        path = header:match("%s(.-)%s")
        path = trim(html_entity_decode(path))
      else
        log:warn("No HTTP method received")
        return
      end

      self.path = path

      if path == nil then
        log:warn("No HTTP path received")
        return
      end
      if #path == 0 then return end

      -- handle index pages quickly
      local index_pages = table.create{"/index.html","/index.lua","/"}
      if index_pages:find(path) then
          if path == "/" then path = "/index.html" end
          self:send_htdoc(socket, path)
          return
      end

      if method ~= "HEAD" then
        if  #path > 0 and self:is_htdoc(path) then
          if method == "POST" then
             parameters = self:parse_post_string(body)
          end
          self:send_htdoc(socket, path, nil, parameters)
          return
        else
          local action_name = string.sub(path:gsub('\/', ':'), 2)
          log:info ("Requested action:" .. action_name)
          find_action(action_name)
        end
     end

    self:send_htdoc(socket, "/404.html", "404 Not Found", parameters)

    --- TODO: NON-HTTP (eg. Telnet, OSC)
--[[  if message == "p" then
        song().transport:start(1)
      elseif message == "s" then
        song().transport:stop()
      elseif #message > 0 then
        song().transport:start(1)
      end
]]--

  end

-------------------------------------------

function start_server()
    print("\r\n==========SERVER START===========")
    ActionServer.mime_types = parse_config_file("/mime.types")
    local address = "localhost"
    local port = 80
    echo_server = ActionServer(address, port)
--    renoise.app():open_url("http://"..address..":"..port)
end
