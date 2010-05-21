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

local client = nil

-------------------------------------------
--  Main

local function request(url, method)
  local p = Util:parse(url)
  rprint(p)
  local header = 1;
  local str = string.format(
    "GET %s HTTP/1.1\nHost: %s\r\n\r\n", 
    p.path, p.host)
  print(str)
  local ok, err = client:send(str)
  print(client:receive(500))
end


-- Do we have an internet connection?
function connected()
  return true
end

function start()  
  client = renoise.Socket.create_client("www.renoise.com", 80,  renoise.Socket.PROTOCOL_TCP)  
  request("http://www.renoise.com/download/checkversion.php")
end


