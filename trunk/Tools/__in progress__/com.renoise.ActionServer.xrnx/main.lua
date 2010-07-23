-------------------------------------------
-- Requires and initialization
-------------------------------------------

local root = "./"
local action_server = nil
local errors = {}

local package_path = package.path
package.path  = package.path:gsub("[\\/]Libraries", "")

require "GlobalMidiActions"
package.path = package_path

local expand = require "expand"

require "util"
Util.root = root

require "log"
local log = Log(Log.ALL)

-------------------------------------------
--  Menu registration
-------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:ActionServer:Start",
  active = function() 
    return not server_running()
  end,
  invoke = function()
    start_server()
  end
}
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:ActionServer:Stop",
  active = function() 
    return server_running()
  end,
  invoke = function()
    stop_server()
  end
}
renoise.tool():add_menu_entry {
  name = "--- Main Menu:Tools:ActionServer:Configure...",
  invoke = function()
    configure_server()
  end
}


-------------------------------------------
--  Debug
-------------------------------------------

if true then 
--  require "remdebug.engine"
  
  _AUTO_RELOAD_DEBUG = function()
    start_server()
  end
end  

-------------------------------------------
--  Renoise Actions Tree
-------------------------------------------

class 'ActionTree'

   -- default values
   ActionTree.message = {
       boolean_value = nil,
       int_value = nil,

       value_min_scaling = 0.0,
       value_max_scaling = 1.0,

       is_trigger = function() return true end,
       is_switch = function() return false end,
       is_rel_value = function() return false end,
       is_abs_value = function() return false end
   }   

   function ActionTree:find_action(action_name)
     local splits = Util:split(action_name, "?")
     action_name = splits[1]
     local query = splits[2]
     splits = Util:split(query, "=")     
     local type = splits[1]
     local value = splits[2]
     local message = table.create(ActionTree.message)
     if (type == 'b') then 
       message.boolean_value = splits[2]
     elseif (type == 'i') then 
       message.int_value = splits[2] 
       message.value_max_scaling = 99
       message.is_trigger = function() return false end
       message.is_abs_value = function() return true end
     end
     rprint(message)
     
     if table.find(ActionTree.action_names, action_name) then
       log:info("Invoking: " .. action_name)
       invoke_action(action_name, message)
       return true
     else
       log:warn("Action not found: " .. action_name)
     end
     return false
   end

   function ActionTree:get_action_tree()
    ActionTree.action_names = available_actions()    
    local trees = table.create()
    
    local function add(t, v, is_last)        
        if is_last then
            table.insert(t,v)
            return
        elseif not t[v] then             
            t[v] = {}                           
        end        
        return t[v]
    end   
    
    local t,splits = {}
    local s = 0
    for _,name in ipairs(ActionTree.action_names) do
        splits = Util:split(name,":")        
        t = trees        
        s = #splits
        for l,v in ipairs(splits) do                          
             t = add(t, v, s-l==0)            
        end                
    end
    return trees    
   end

   -- Converts the complete tree or a subtree into a HTML list structure
   -- @param t       table representing the action tree or subtree
   -- @param depth   specifies the amount of nesting
   -- @return string containing a nested HTML list
   function ActionTree:to_html_list(t, depth)
       t = t or {}
       local list = "<ul>"
       for k,v in pairs(t) do
          if type(v) ~= "table" then
             list = list .. "<li><a href='#'>"..v.."</a></li>"
          else
            list = list .. "<li><a href='#'>" .. k .. "</a>"
            if depth and depth > 1 then
                list = list .. ActionTree:to_html_list(v, depth-1)
            end
            list = list .. "</li>"
          end
       end
       return list .. "</ul>"
   end

   -- Returns a portion of the tree
   -- Example: get_subtree("Transport", "Playback")
   -- @param ...  vararg representing the path to the subtree
   -- @return table containing the subtree
   function ActionTree:get_subtree(...)      
      local path = {...}       
      local t = ActionTree.action_tree      
      for _,v in ipairs(path) do
         t = t[v]
      end
      return t
   end

   ActionTree.action_tree = ActionTree:get_action_tree() 

-------------------------------------------
-- ActionServer
-------------------------------------------

class "ActionServer"

  ActionServer.document_root = root .. "html"

  function ActionServer:__init(address,port)
      self.chunked = false
      
      -- create a server socket
      local server, socket_error = nil
      if address == nil then
        server, socket_error = renoise.Socket.create_server(port)
      else
        server, socket_error = renoise.Socket.create_server(address, port)
      end        

      if socket_error then
        renoise.app():show_warning(
          "Failed to start the action server: " .. socket_error)
      else
        -- start running
        self.server = server
        self.server:run(self)
        log:info("Server running at " .. self:get_address())
      end
  end

  

  function ActionServer:get_address()
    return self.server.local_address .. ':' .. self.server.local_port
  end

  function ActionServer:get_date(time) 
    return os.date("%a, %d %b %Y %X " .. Util:get_tzoffset(), time)
  end
  
   function ActionServer:get_action_names()
      return Action.action_names
   end 

  function ActionServer:parse_post_string(body)
    if #Util:trim(body) == 0 then return {} end
     local p = {}
     local key, val = nil
     for k,v in body:gmatch("([^=&]+)=([^=&]+)") do
       key = Util:urldecode(Util:trim(k))
       val = Util:urldecode(Util:trim(v))                    
       if key:match("%[%]$") then
         if p[key] == nil then
            p[key] = table.create()
         end
         p[key]:insert(val)
       else
         p[key] = val       
       end
     end     
     return p
  end

  function ActionServer:get_MIME(path)
    local ext = Util:get_extension(path)
    local mime = ActionServer.mime_types[ext] or "text/plain"
    log:info("Extension: " .. ext .. "; Content-Type: " .. mime)
    return mime
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
    local path_ext = Util:get_extension(path)
    return extensions:find(path_ext)
  end

  function ActionServer:set_header(k,v)
   self.header_map[k] = v
  end
  
  function ActionServer:remove_header(k)
    self:set_header(k,nil)
  end

  function ActionServer:init_header()
   self.header_map = table.create()
   self.header_map["Date"]  = self:get_date()
   self.header_map["Server"] = string.format(
     "Renoise %s (%s)", renoise.RENOISE_VERSION, os.platform():lower())
   self.header_map["Cache-Control"] = "max-age=3600, must-revalidate"
   self.header_map["Accept-Ranges"] = "none"
  end
  
  function ActionServer:is_binary(str)    
    return str ~= nil and str:match("^text") == nil
  end  
    
  function ActionServer:is_image(str)    
    return str ~= nil and str:match("^image") ~= nil
  end
  
  function ActionServer:get_etag(fullpath)
    local stat = io.stat(fullpath)
    local last_modified = stat.mtime
    return last_modified
  end

  function ActionServer:send_htdoc(socket, path, status, parameters)
     status = status or "200 OK"
     local buffer = nil
     local mime = self:get_MIME(path)
     
     self:set_header("Content-Type", mime)
     
     parameters = parameters or {}
     local fullpath = self:get_htdoc(path)
     local stat = io.stat(fullpath)
     local size = stat.size
     
     log:info("If-None-Match: " .. tostring(self.header["If-None-Match"]))
     log:info("If-Modified-Since: " .. tostring(self.header["If-Modified-Since"]))     
     
     -- Conditional GET with ETag / If-None-Match
     if self.header["If-None-Match"] and 
       tonumber(self:get_etag(fullpath)) <= tonumber(self.header["If-None-Match"])
     then
      status = "304 Not Modified"
      buffer = ""
      size = 0
      log:info("Serving empty body due to Conditional GET")
      self:set_header("Cache-Control", "no-cache, no-store")       
     else      
       -- Read file into string buffer
       local is_binary = self:is_binary(mime)     
       is_binary = false
       log:info("Is a binary file? " .. tostring(is_binary))
       buffer = Util:read_file(fullpath, true)
       assert(buffer, "Failed to read the requested file from disk")
     end
          
     -- Create body
     local body = nil          
     -- Interpret any Lua code in the buffer (see expand.lua)     
     if self:is_expandable(path) and #buffer > 0 then

       self:set_header("Content-Type", "text/html")
       self:set_header("Cache-Control", "private, max-age=0, must-revalidate")
      
       local tic = os.clock()               
       body = expand(
         buffer,          
         { L=self, 
           renoise=renoise, 
           P=parameters, 
           Util=Util, 
           ActionTree=ActionTree
         },
         _G
       )       
       local toc = os.clock()           
       log:info(string.format("Expanding embedded Lua code took %d ms", 
         (toc-tic) * 1000))             
       size = #body -- interpreted size is different from filesize
       self:set_header("ETag", os.time())
     else
       self:set_header("Cache-Control", "private, max-age=3600, must-revalidate")
       body = buffer
       self:set_header("ETag", self:get_etag(fullpath))       
     end
     
     -- Format "Content-Length"
     self:set_header("Content-Length", size)
     local unit = "B"
     self:set_header("Content-Length", size)
     if size > 1024 then 
       unit = "KB"
       size = string.format("%.1f", size / 1024) 
     end 
     log:info(string.format("Content-Length: %s %s", size, unit))
     
     -- Create header string from header table    
     local header = "HTTP/1.1 " .. status .. "\r\n"
     for k,v in pairs(self.header_map) do
       header = string.format("%s%s: %s\r\n",header,k,v)
     end     
     header = header .. "\r\n"     
     
     -- Send header
     local ok,err = socket:send(header)               
     if not ok then
       log:error("Failed to send header:\n".. err)
     end
     
     -- Send body
     local ok,err = socket:send(body)          
     if not ok then
       log:error("Failed to send body:\n".. err)
     end
     
  end
 
--Socket API Callbacks---------------------------   

  function ActionServer:socket_error(socket_error)
    renoise.app():show_warning(socket_error)
  end

  function ActionServer:socket_accepted(socket)
    log:info("Socket accepted")
  end

  function ActionServer:socket_message(socket, message)
      self.remote_addr = socket.peer_address .. ":" .. socket.peer_port
      log:info("Remote Addr: " .. self.remote_addr)
      print("\r\n----------MESSAGE RECEIVED----------")

      local header, body = nil
      if self.chunked then
         header = self.header
         body = message
         self.chunked = false
      else
         header, body = Util:parse_message(message)         
      end
      
      self.header = header
      
      if #body < tonumber(header["Content-Length"]) then
        self.chunked = true
        return
      end

      self:init_header()

      local parameters = nil -- POST and GET variables
      if #Util:trim(body) > 0 then log:info("Body:" .. body) end
      local path, url = nil
      local url_parts = {}
      local methods = table.create{"GET","POST","HEAD",
        "OPTIONS", "CONNECT", "PUT", "DELETE", "TRACE"}
      local method = header[1]:match("^(%w+)%s")

      if method ~= nil then        
        method = method:upper()
        url = header[1]:match("%s(.-)%s")        
        print(url)
        url_parts = Util:parse(url)                
        path = Util:trim(Util:urldecode(url_parts.path .. '?'..(url_parts.query or '')))
        -- strip ending ?
        if (path:sub(-1) == '?') then
          path = path:sub(1,-2)
        end
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
          if path == "/" then path = index_pages[1] end          
            self:send_htdoc(socket, path)
          return
      end

      if method ~= "HEAD" then
        parameters = self:parse_post_string(body)
        if  #path > 0 and self:is_htdoc(path) then
          if method == "POST" then
             -- parameters = self:parse_post_string(body)
          end
          self:send_htdoc(socket, path, nil, parameters)
          return
        else
          local action_name = string.sub(path:gsub('\/', ':'), 2)
          log:info ("Requested action:" .. action_name)
          local found = ActionTree:find_action(action_name)
          if found then            
             if parameters and parameters.ajax == "true" then               
               log:info("Action requested by Ajax")
               self:send_htdoc(socket, "/empty.txt")         
               return
             end
             self:set_header("Cache-Control", "private, max-age=0")
             self:send_htdoc(socket, index_pages[1], nil, parameters)          
             return
          end
        end
     end

    self:send_htdoc(socket, "/404.html", "404 Not Found", parameters)

    --- TODO: NON-HTTP (eg. Telnet, OSC)

  end
  
   function ActionServer:stop()
     if self.server then
       self.server:close()
       self.server = nil
     end
   end

-------------------------------------------
-- Start / Stop 
-------------------------------------------
local address = nil
local port = 8888
local INADDR_ANY = false

function restore_default_configuration()
    port = 80
    address = nil
    INADDR_ANY = false
end

function server_running()
    return (action_server ~= nil)
end

function start_server()
    print("\r\n==========STARTING SERVER===========")
    assert(not action_server, "server is already running")

    ActionServer.mime_types = Util:parse_config_file("/mime.types")
    action_server = ActionServer(address, port)
    
    renoise.app():open_url("localhost:"..port .. "/matrix.html")
end

function stop_server()
   print("\r\n==========STOPPING SERVER===========")
   assert(action_server, "server is not running")

   action_server:stop()
   action_server = nil
end

-- todo hostnames
local function is_valid_ip(str)
   return str:match("^%d.%d.%d.%d$") or str == "localhost"
end

local function set_address(value)
   if is_valid_ip(value) then
      address = value
   end
end

local function set_port(value)
   port = value
end

function configure_server()
   local vb = renoise.ViewBuilder()
   local DEFAULT_DIALOG_MARGIN =
    renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
   local DEFAULT_CONTROL_SPACING =
    renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
   local TEXT_ROW_WIDTH = 80
   local temp = address

   local content =
     vb:column {
       style = "invisible",
       margin = DEFAULT_DIALOG_MARGIN,
       spacing = DEFAULT_CONTROL_SPACING,

       vb:row {
          vb:text {
            width = TEXT_ROW_WIDTH,
            text = "INADDR_ANY"
          },
          vb:checkbox {
            value = INADDR_ANY,
            notifier = function(value)
               INADDR_ANY = value
               if value then
                 vb.views.address_field.value = "0.0.0.0"
               else
                 vb.views.address_field.value = temp
               end
            end
          },
        },

       vb:row {
          vb:text {
            width = TEXT_ROW_WIDTH,
            text = "Address"
          },
          vb:textfield {
            visible = not INADDR_ANY,
            id = "address_field",
            value = address,
            notifier = function(value)
              set_address(value)
            end
          },
        },

        vb:row {
          vb:text {
            width = TEXT_ROW_WIDTH,
            text = "Port"
          },
          vb:valuebox {
            value = port,
            min = 0,
            max = 65535,
            notifier = function(value)
              set_port(value)
            end
          }
        }

     }

  local buttons = {"OK", "Default"}

  local choice = renoise.app():show_custom_prompt(
    "Configure ActionServer", content, buttons)
  
  if (choice == "Cancel") then
    -- restore_previous_configuration()
  elseif (choice == "Default") then
      restore_default_configuration()
  end

  if choice then
   if server_running() then 
     stop_server()
   end
   start_server()
  end
end
