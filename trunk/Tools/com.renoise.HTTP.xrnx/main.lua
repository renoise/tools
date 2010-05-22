-------------------------------------------
--  Requires
-------------------------------------------

require "util"

-------------------------------------------
--  Menu registration
-------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Update",
  active = function() 
    return connected()
  end,
  invoke = function()
    start()
  end
}

-------------------------------------------
--  Debug
-------------------------------------------

if true then 
  require "remdebug.engine"
  
  _AUTO_RELOAD_DEBUG = function()
    start()
  end
end 

-------------------------------------------
--  Init
-------------------------------------------

local socket_client = nil

-------------------------------------------
--  Main

local function try(f)
   local ok,err = f
   if err then 
     renoise.app():show_warning(err)
     return
  end
end

local function request(url, method)
  local p = Util:parse(url)
  local str = string.format(
    "GET %s HTTP/1.1\nHost: %s\r\n\r\n", 
    p.path, p.host)
  print(str)
  
  local ok, err = renoise.Socket.create_client(p.host, 80,  renoise.Socket.PROTOCOL_TCP)  
  local client = ok
  if err then 
    renoise.app():show_warning(err)
    return
  end
  
  ok,err = client:send(str)
  
  if err then 
    renoise.app():show_warning(err)
    return
  end
  
  -- loop while receiving data within 100 ms
  local content
  local content_length = 0
  local bytes_received = 0
  local header,body,header_size,body_size = 0,0,0,0
  local first_packet = true
  repeat
    content = client:receive(100)
    if content then
      bytes_received = bytes_received + #content
      if first_packet then
        header,body,header_size,body_size = Util:parse_message(content)
        content_length = header["Content-Length"]          
        bytes_received = bytes_received - header_size
      end
    end  
    first_packet = false  
    print (url)
    print(body)
    print ("Content Length = " .. content_length)  
    print ("Bytes received = " .. bytes_received)
  until (content == nil)  
end

-- Do we have an internet connection?
function connected()
  return true
end

function start()  
  request("http://nl.archive.ubuntu.com/ubuntu-cdimages/10.04/release/ubuntu-10.04-dvd-amd64.iso")  
--  request("http://www.renoise.com/")    
--  request("http://www.renoise.com/download/checkversion.php")
end
