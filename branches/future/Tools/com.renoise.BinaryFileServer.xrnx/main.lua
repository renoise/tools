-------------------------------------------
-- Requires and initialization
-------------------------------------------

require "log"

local log = Log(Log.ALL)

local root = "./"
local binary_file_server = nil
local errors = {}


-------------------------------------------
--  Menu registration
-------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:BinaryFileServer:Start",
  active = function() 
    return not server_running()
  end,
  invoke = function()
    start_server()
  end
}
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:BinaryFileServer:Stop",
  active = function() 
    return server_running()
  end,
  invoke = function()
    stop_server()
  end
}

-------------------------------------------
-- Util
-------------------------------------------

class "Util"

function Util:read_file(file_path, binary)
  local mode = "r"
  if binary then mode = "rb" end
  local file_ref,err = io.open(file_path, mode)
  if not err then
    local data=file_ref:read("*all")        
    io.close(file_ref)    
    return data
  else
    return nil,err;
  end
end

-------------------------------------------
-- BinaryFileServer
-------------------------------------------

class "BinaryFileServer"

  BinaryFileServer.document_root = root .. "files"

  function BinaryFileServer:__init(address,port)
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

 
  function BinaryFileServer:get_address()
    return self.server.local_address .. ':' .. self.server.local_port
  end
  
  function BinaryFileServer:set_header(k,v)
   self.header_map[k] = v
  end

  function BinaryFileServer:init_header()
   self.header_map = table.create()
   self.header_map["Date"]  = "20-5-2010"
   self.header_map["Server"] = "Renoise Vx.xx"
   self.header_map["Cache-Control"] = "no-store, no-cache, must-revalidate"
   self.header_map["Accept-Ranges"] = "none"
   self.header_map["Content-Type"] = "image/png"   
  end
  
  function BinaryFileServer:get_htdoc(path)
    if path == nil then path = "" end
    return BinaryFileServer.document_root .. path
  end

  function BinaryFileServer:send_htdoc(socket, path, status, parameters)
     local fullpath = self:get_htdoc(path)       
     
     -- Read binary file (image) into string buffer
     local buffer = Util:read_file(fullpath, true)
     assert(buffer, "failed to read the file")
     rprint(buffer)

     -- Set filesize
     local stat = io.stat(fullpath)
     self:set_header("Content-Length", stat.size)

     -- Create header string from header table
     status = status or "200 OK"
     local header = "HTTP/1.1 " .. status .. "\r\n"
     for k,v in pairs(self.header_map) do
       header = string.format("%s%s: %s\r\n",header,k,v)
     end     
     header = header .. "\r\n"     

     -- Send header     
     rprint(header)
     socket:send(header)
     
     -- Send data               
     local ok,err = socket:send(buffer)   
     print(ok, err)
     
     if not ok then
       log:error("Failed to send data:\n".. err)
     end
  end
  
   function BinaryFileServer:stop()
     if self.server then
       self.server:stop()
       self.server = nil
     end
   end     

--Socket API Callbacks---------------------------  
  
  function BinaryFileServer:socket_error(socket_error)
    renoise.app():show_warning(socket_error)
  end

  function BinaryFileServer:socket_accepted(socket)
    log:info("Socket accepted")
  end  

  function BinaryFileServer:socket_message(socket, message)
      self.remote_addr = socket.peer_address .. ":" .. socket.peer_port
      log:info("Remote Addr: " .. self.remote_addr)
      print("\r\n----------MESSAGE RECEIVED----------")
      self:init_header()
      self:send_htdoc(socket, "/image.png")
  end
  

-------------------------------------------
-- Start / Stop 
-------------------------------------------
local address = "localhost"
local port = 12345
local INADDR_ANY = false

function server_running()
    return (binary_file_server ~= nil)
end

function start_server()
    print("\r\n==========STARTING SERVER===========")
    assert(not binary_file_server, "server is already running")
    binary_file_server = BinaryFileServer(address, port)
    renoise.app():open_url(binary_file_server:get_address())  
end

function stop_server()
   print("\r\n==========STOPPING SERVER===========")
   assert(binary_file_server, "server is not running")

   binary_file_server:stop()
   binary_file_server = nil
end

