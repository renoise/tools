-------------------------------------------------------------------------------
--  Requires
-------------------------------------------------------------------------------

require "renoise.http"


-------------------------------------------------------------------------------
--  Menu registration
-------------------------------------------------------------------------------

local entry = {}

entry.name = "Main Menu:Tools:Read RSS..."
entry.active = function() return true end
entry.invoke = function() start() end
renoise.tool():add_menu_entry(entry)


-------------------------------------------------------------------------------
--  Main functions
-------------------------------------------------------------------------------

-- True = get the webpage
-- False = get the feed
local html = false

-- Big RSS Feed
local url = "http://www.renoise.com/board/index.php"

-- Small RSS Feed
--local url = "http://www.renoise.com/indepth/comments/feed/"

local data_type = "text"
local parameters = {}
if (not html) then
 -- data_type = "xml" -- xml parser doesn't currently work
  parameters = {app="core",module="global",section="rss",type="forums",id="1"}
end  


local callback = function(res, err)
  if (res) then    
    local buttons = table.create{"Close"}
    local choice = renoise.app():show_prompt(
      "Checking for Renoise updates",
      res, buttons)
  end
end


function start()
  HTTP:get(url, parameters, callback, data_type)
end

function dl()
  local url = "http://www.renoise.com/"
  HTTP:get(url, nil, function(res) rprint(res) end)
end
