local TITLE = "ToolUpdater"
local DEBUG = true

-------------------------------------------------------------------------------
--  Requires
-------------------------------------------------------------------------------

require "renoise.http"


function TRACE(obj)
  if (not DEBUG) then 
    return
  end
  if (type(obj)=="table") then
    rprint(obj)
  else 
    print(obj)
  end
end

-------------------------------------------------------------------------------
--  Menu registration
-------------------------------------------------------------------------------

local entry = {}

-- Download a file to disk
entry.name = "Main Menu:Tools:"..TITLE..":Test File Download..."
entry.invoke = function()   
  download_test()  
end
renoise.tool():add_menu_entry(entry)  

-- BROWSE --
entry.name = "Main Menu:Tools:"..TITLE..":Browse Tools..."
entry.active = function() return true end
entry.invoke = function()   
  browse_tools() 
  -- show_tool_updates() 
end
renoise.tool():add_menu_entry(entry)

-- INSTALLED VERSIONS --
entry.name = "Main Menu:Tools:"..TITLE..":Show Installed Tools..."
entry.invoke = function()     
  show_installed_tools()
end
renoise.tool():add_menu_entry(entry)

-- FETCH & READ REMOTE XML --
entry.name = "Main Menu:Tools:"..TITLE..":Parse RenoiseDocVersions.xml..."
entry.invoke = function()   
  get_xml()
end
renoise.tool():add_menu_entry(entry)

-- XML-RPC --
entry.name = "Main Menu:Tools:"..TITLE..":Test XML-RPC..."
entry.invoke = function()   
  text_xml_message()  
end
renoise.tool():add_menu_entry(entry)  

-- INSTALL & UNZIP TEST --
entry.name = "Main Menu:Tools:"..TITLE..":Install a Tool (old)..."
entry.invoke = function()   
  unzip_test()
end
renoise.tool():add_menu_entry(entry)  

entry.name = "Main Menu:Tools:"..TITLE..":Install a Tool (new)..."
entry.invoke = function()   
  unzip_test(true)
end
renoise.tool():add_menu_entry(entry)  

-- MIME FILE
entry.name = "Main Menu:Tools:"..TITLE..":Create MIME Types file..."
entry.invoke = function() create_mime_type_file() end  
renoise.tool():add_menu_entry(entry)  

-- JSON-RPC --
-- renoise.com doesn't have the renoisetool.get service yet
entry.name = "Main Menu:Tools:"..TITLE..":Test JSON-RPC Update..."
entry.active = function() return false end    
entry.invoke = function()   
 json_view_test()  
end
renoise.tool():add_menu_entry(entry)  
entry.active = function() return true end    


-------------------------------------------------------------------------------
--  Zip functions
-------------------------------------------------------------------------------


require "unzip"

-- Unzips the Tool within the Tools folder, in
-- a subfolder with the filename of the XRNX.
function unzip_tool(path)
  local p = URL:parse_path(path) 
  local filename = p[#p]
  local destination = get_tools_root() .. filename 
  return unzip(path, destination)
end
  

-------------------------------------------------------------------------------
--  Helper functions
-------------------------------------------------------------------------------

function get_xml()
   HTTP:request("http://renoise.com/download/RenoiseDocVersions.xml",
  -- HTTP:request("http://www.renoise.com/board/index.php?app=core&module=global&section=rss&type=forums&id=1",
    Request.POST, 
    nil, 
    function(data) 
      rprint(data)
      local vb = renoise.ViewBuilder()
      renoise.app():show_message(
        "Open the Scripting Terminal to see the parsed remote XML")
    end, 
    "xml")
end

local dialog = nil
local MAX_TOOLS = 5

class "Manifest" (renoise.Document.DocumentNode)
function Manifest:__init()
  renoise.Document.DocumentNode.__init(self) 
  self:add_properties {      
      Id = "N/A"
  }
end

function scan_tool_dirs(path, rel)
  rel = rel or ""
  TRACE("Scanning folder: '"..path.."'")
  local dirs = os.dirnames(path)
  local tools = table.create()
  for _,v in ipairs(dirs) do
    if (v:sub(1,1) == ".") then
      -- continue
    elseif (v:find(".xrnx", -5)) then
      tools:insert(rel..v)
    else 
      v = v..'/'
      local subdir = scan_tool_dirs(path .. v, rel..v)
      tools = Util:merge_tables(subdir, tools)      
    end
  end  
  return tools
end

function parse_xml(file)
 local obj,err = XmlParser:ParseXmlFile(file)
 if(not err) then
   return obj
 else
   TRACE(err)    
  end
end

function get_tools_root()
 local dir = renoise.tool().bundle_path
 local root = dir:sub(1,dir:find("Tools")+5)
 return root
end

local versions = nil

-- Returns a table containing the ids and versions
-- of all installed tools, eg:
-- [1][Id] = com.renoise.CreateTool
-- [1][Version] = 1.0
function get_installed_versions()    
  if (not versions) then
    versions = table.create()
  else
    return versions
  end
  
  local root = get_tools_root()
  local tools = scan_tool_dirs(root)
  -- TRACE(tools)
  
  for _,tool in ipairs(tools) do    
    -- TRACE(root..v)
    local xml = root..tool.."/manifest.xml"    
    if (io.exists(xml)) then
      --local str = Util:read_file(xml)
      local tree = parse_xml(xml)
      --TRACE(tree)
      local version, id, apiversion
      local category = ""      
      for _,v in ipairs(tree.ChildNodes) do               
        if (v.Name == "Version") then          
          version = v.Value            
        elseif (v.Name == "Id") then
          id = v.Value          
        elseif (v.Name == "ApiVersion") then
          apiversion = v.Value            
        elseif (v.Name == "Category") then
          category = v.Value                      
        end                
      end
      versions:insert({
        Id=id, 
        Version=version, 
        ApiVersion=apiversion, 
        Category=category
      })            
    end
  end  
  return versions
end


local function get_installed_version(tool_id)
  local installed_versions = get_installed_versions()
  for _,l in ipairs(installed_versions) do
    if (l.Id == tool_id) then
      return l
    end
  end
  return false
end

local function is_update_available(l, r)
  assert(l and l.Id == r.Id, "Tool IDs don't match.")   
  if (l.Version < r.Version or l.ApiVersion < r.ApiVersion) then
    return true
  end  
  return false
end

local function find_updates(remote_versions)  
  local updates = table.create()
  for _,r in ipairs(remote_versions) do
    if (is_update_available(get_installed_version(r.Id), r)) then
      updates:insert(r)
    end
  end
  return updates
end



-------------------------------------------------------------------------------
--  Network functions
-------------------------------------------------------------------------------

--------------------------------------------------------------
-- SHOW INSTALLED TOOLS
--------------------------------------------------------------

function show_installed_tools()
  --local versions = renoise.app().installed_tools
  local versions = get_installed_versions()
  local t = table.create()  
  local str = ""
  for _,v in ipairs(versions) do        
    --str = ("%s [%s] v%s %s\n"):format(str, v.id, v.version)    
    str = ("[%s] v%s"):format(v.Id, v.Version)     
    if (v.Category) then
      str = ("%s (%s)"):format(str, v.Category)
    end
    t:insert( str )
  end
  renoise.app():show_message(t:concat("\n"))
end



--------------------------------------------------------------
-- XML-RPC TOOL UPDATES
--------------------------------------------------------------

function text_xml_message()
  local settings = {
    content_type='application/xml',
    data_type = 'xml',
    url='http://tools.renoise.com/services/xmlrpc',
    method=Request.POST,
    data={methodCall={methodName='views.get',params={
      param={
        {value={string='ToolUpdates'}}, -- *view_name        
        {value={string='Defaults'}}, -- display_id 
        {value={}}, -- args
        {value={int=1}}, -- offset
        {value={int=5}}, -- limit        
        {value={boolean=1}} -- format_output        
      } -- param
    }}},
    error=function(xml_http_request, text_status, error_thrown)
      renoise.app():show_error(
        "Could not load update info :(\n" .. (error_thrown or "") ) 
    end,
    success=function(d, text_status, xml_http_request)
      --renoise.app():show_message("Server response will be shown in a browser window")
      local path = "toolupdates.html"      
      
      local t = table.create()
      local node = d      
      
      while (type(node) == 'table') do                      
        if (node.Name) then                              
          if (node.Name == "string") then                        
            t:insert( node.Value )
          end                    
        end        
        node = node.ChildNodes[1]
      end
      
      local html = "<html><head><base href='http://tools.renoise.com/'></head><body>"
        ..t:concat().."</body></html>"
      local file_ok = Util:file_put_contents(path, html)
      
      if (#t > 0 and file_ok) then      
        renoise.app():open_url(os.currentdir() .. path)
      end
    end    
  }
    
  local new_request = Request(settings)  
end



--------------------------------------------------------------
-- BROWSE TOOLS ONLINE
--------------------------------------------------------------

function browse_tools()
  local vb = renoise.ViewBuilder()
  local progress = vb:text{text="loading..."}
  local body = vb:column{ 
    margin=10,
    spacing=5, 
    uniform=true,
    vb:text{text=TITLE.." retrieves a list of applicable updates from the Renoise server.\n"
      .. "Currently the complete Tool list is downloaded."},
    progress 
  }
  
  if (dialog and dialog.visible) then
    dialog:show()
  end
  
  dialog = renoise.app():show_custom_dialog(      
        TITLE, body)
        
  local settings = {
    content_type='application/json',
    url='http://tools.renoise.com/services/json-rpc',
    method=Request.POST,
    data={method='views.get',params={view_name='ToolUpdates'}},
    error=function(xml_http_request, text_status, error_thrown)
      progress.text = "Could not load update info :(\n" .. (error_thrown or "")
    end,
    success=function(d, text_status, xml_http_request)
      body:remove_child(progress)
      local data = d.result
      local page = vb:column{spacing=3,visible=true,uniform=true}
      local pages = vb:row{spacing=5}
      local page_table = table.create()
      for k,v in ipairs(data) do               
        -- Tool group
        local tool = vb:row{         
          style="group",           
          margin=3,
          -- Checkbox
          vb:checkbox {
          },          
          -- Tool title          
          vb:text{ 
            text=v.node_title, 
            font="bold"
          },
          -- Website
          vb:bitmap {          
            mode = "body_color",
            bitmap = "images/link-icon.bmp",
            notifier = function() 
              renoise.app():open_url("http://tools.renoise.com/node/"..v.nid) 
            end
          },
          -- Tool version
          vb:text{ 
            text=v.node_data_field_api_field_version_value
          }          
        }  
        page:add_child(tool)
        if (k % MAX_TOOLS == 0) then
          local pid = "page_"..k / MAX_TOOLS
          page_table[pid] = page
          pages:add_child(page_table[pid]) 
          page = vb:column{spacing=3,visible=false,uniform=true}
        end                
      end        
      local items = table.create()
      for i=1,page_table:count() do
        items:insert("Page " .. i)
      end      
      body:add_child(                
        vb:row{          
          spacing = 5, 
          vb:column{
            margin = 3,
            height = "100%",
            style = "body",
            uniform = true,                    
            vb:popup{
              items = items,
              notifier = function(item)               
                for _,v in pairs(page_table) do
                  v.visible = false
                end
                page_table["page_"..item].visible = true
                pages:resize()
              end
            },
            vb:button{
              text = "Update\n selected Tools", 
              notifier = function() 
                renoise.app():show_prompt("Not implemented", 
                  "The list should display installed Tools that can be updated.".. 
                  "The selected Tools are then downloaded and installed.", 
                  {"OK"}) 
                end
            }
          },
          pages
      })      
    end,
    data_type='json'
  }
  local new_request = Request(settings)
end



--------------------------------------------------------------
-- JSON - CHECK FOR TOOL UPDATES 
--------------------------------------------------------------

function json_view_test()
  local versions = get_installed_versions()  
  local ids = table.create()
  rprint(versions)
  for _,v in ipairs(versions) do
    ids:insert(v.Id)    
  end
  if (#ids == 0) then
    return
  end
  local parameters = {
    Id=ids,
    ApiVersion=tonumber(renoise.API_VERSION)
  }
  local settings = {
    content_type='application/json',
    url='http://tools.renoise.com/services/json-rpc',
    method=Request.POST,
    data={
      method='renoisetool.get',
      params=parameters,
    },
    error=function(xml_http_request, text_status, error_thrown)
      print(text_status .. ": " .. error_thrown)
    end,
    success=function(d, text_status, xml_http_request)
      local updates = find_updates(d.result)
      rprint(d)
    end,
    data_type='json'
  }
 
  local new_request = Request(settings)  
end



--------------------------------------------------------------
-- INSTALL TOOL / UNZIP TEST
--------------------------------------------------------------

-- unzip_tool() has been superseded by renoise.app():install_tool()
function unzip_test(internal)  
  local xrnx = "com.renoise.UnzipTestSubject.xrnx"       
  
  local SEP = "/"
  if (os.platform() == "WINDOWS") then
    SEP = "\\"
  end
  
  -- relative path
  local path = "temp"..SEP..xrnx
  
  -- absolute path
  -- path = os.currentdir().. SEP..path
  
  print(path)
  
  if (not io.exists(path)) then
    renoise.app():show_error(path .. " does not exist")
    return false
  end
  
  local ok, err = ""
  if (not internal) then
    ok, err = unzip_tool(path)
    if (not ok) then 
      renoise.app():show_error("Unzip error: " .. err)  
    end
  else 
    ok = renoise.app():install_tool(path)
    if (not ok) then
      renoise.app():show_error("Error installing Tool")
    end
  end
  
  if (ok) then
    renoise.app():open_path(Util:get_tools_root()..xrnx)        
  end  
end

--------------------------------------------------------------
-- DOWNLOAD TEST
--------------------------------------------------------------

local request = nil
local path_to_file = ""

function download_test()

  if (dialog and dialog.visible) then
    dialog:show()    
    return
  end
 
  local urls = {
    "Choose or type URL...",
    
    -- XRNX
    "http://request.atomsk.nl/com.renoise.UpdateChecker_Rns270_V4.xrnx",
    
    -- PNG
    "http://request.atomsk.nl/matrix.png",
    
    -- 12 MB File (firefox 4)
    "http://request.atomsk.nl/ff4.exe",
    
    -- 100+ MB File (Puppy Linux ISO)
    "http://distro.ibiblio.org/pub/linux/distributions/puppylinux/puppy-215CE-Final.iso",       
    
     -- Chunked Transfer Encoding
    "http://request.atomsk.nl/chunk.php",
    "http://request.atomsk.nl/pngchunk.php",
        
    -- Redirection
    "http://request.atomsk.nl/redirect_rel.php",
    "http://request.atomsk.nl/redirect_abs.php",    
    
    -- Different forms    
    "request.atomsk.nl",
    "http://request.atomsk.nl/",
    "http://request.atomsk.nl",
    "http://www.request.atomsk.nl",
    
    -- renoise.com
    "http://renoise.com",
    "http://tools.renoise.com",
    
    -- IP Address (Sourceforge.com)
    "216.34.181.60",
    
    -- ERRORS
    
    -- Socket failed to resolve host name
    "--ERRORS--",
    
    -- Connection time-out (Google DNS)
    "8.8.8.8",
    
    -- 400 No Host (renoise.com)
    "188.40.147.28",
    
    -- 404 Not Found
    "http://request.atomsk.nl/404",
    
    -- 500 Internal Server Error
    "http://request.atomsk.nl/cgi-bin/500.pl",
    
  }
  
  local vb = renoise.ViewBuilder()
  
  
  local complete = function(d)     
    --request = nil    
    vb.views.cancel_button.visible = true
    vb.views.cancel_button.text = "Download"        
    vb.views.pause_button.visible = false                  
  end
  
  local success = function(d)   
    vb.views.progress.text = "Download has finished:\n" .. d
    --local success = renoise.app().install_tool(xrnx)  
    path_to_file = d
    vb.views.explore_button.visible = true    
  end
  
  local error = function(x, t, e)        
    vb.views.progress.text = e
  end
  
  local progress = function(p)                
    local str = ("Status: %s"):format(p:get_status())
    
    local size = p.content_length    
    if (size and size > 0) then
      size = size / 1024
      local kb = p.bytes / 1024      
      str = ("%s; %d kB / %d kB"):format(str, kb, size)
    end
    if (p.eta and p.percent and p.estimated_duration) then
      str = ("%s; %d%% [ETA %d s/ %d s]"):format(str, p.percent, p.eta, p.estimated_duration)      
    end
    --str = ("%s\nAvg Speed: %dkB/s; Min: %d kB/s; Max: %d kB/s; Current: %d kB/s;"):format(
    --  str, p.avg_speed, p.min_speed, p.max_speed, p.speed)
      
    if (p.status == Progress.BUSY) then
      vb.views.pause_button.visible = true
    end
      
    vb.views.progress.text = str
  end 
  
  -- When pressing download/cancel button
  local cancel_handler = function()         
    if (request and not request.complete) then 
      request:cancel()                  
      print("Request:cancel()")
    else
      local url = vb.views.url_field.text
      if (not url:find("://", 2, true)) then
        url = "http://" .. url
      end      
      --request = HTTP:download_file(url, progress, success, complete, error)
      
      vb.views.cancel_button.text = "Abort"
      vb.views.explore_button.visible = false
      
      request = Request({
        url=url, 
        method=Request.GET, 
        save_file=vb.views.save_checkbox.value, 
        success=success,
        complete=complete,
        error=error,
        progress=progress
      })   
      -- request will block here while sending/receiving headers
      -- any code here will be executed when done with headers
    end 
  end
  
  local pause_handler = function()      
    if (not request or request.cancelled) then 
      return
    end
 
    if (request.paused) then 
      request:resume()
      vb.views.pause_button.text = "Pause"
    elseif (request.progress:get_status() == Progress.BUSY) then    
      request:pause()
      vb.views.pause_button.text = "Resume"
    end
  end  
  
  local explore_handler = function()
    renoise.app():open_path(path_to_file)
  end
  
  local progress = vb:text{
    id = "progress",
    text = ""
  }
  
  local DCH = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT * 2
  local DCM = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DCS = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  
  local url_popup = vb:popup {
    id = "url_popup",
    width=400,
    items = urls,
    notifier = function(index) 
      if (index > 1) then
        local url = vb.views.url_popup.items[index]
        vb.views.url_field.text = url
      else 
        vb.views.url_field.edit_mode = true
      end
    end
  }
  
  local url_field = vb:textfield {
    id = "url_field",
    notifier = function(str)              
      if (vb.views.url_popup.value ~= 1 and 
        not table.find(urls, str)) then
        vb.views.url_popup.value = 1                 
      end
      vb.views.cancel_button.visible = (#str > 0)
    end
  }      
   
  local body = vb:column{ 
    id = "body",
    margin=10,
    spacing=5, 
    uniform=true,
    
    url_popup,
    
    url_field,
    
    
    vb:row {      
      vb:checkbox{
        id = "save_checkbox",      
        value = true      
      },
      vb:text{
        text = "Save to file",
      }
    },
    
    progress, 
    
    vb:row{
      id = "button_row",
      visible = true,
      vb:button{
        id = "cancel_button",
        height = DCH,
        text = "Download",       
        visible = false,  
        notifier = cancel_handler   
      },
      vb:button{
        id = "pause_button",
        height = DCH,        
        text = "Pause",
        visible = false,        
        notifier = pause_handler
      },
      vb:button{
        id = "explore_button",
        height = DCH,
        text = "Explore file...",
        visible = false,
        notifier = explore_handler
      }
    }
  }
  
  dialog = renoise.app():show_custom_dialog(      
        "Download", body)
 
end


--------------------------------------------------------------
-- MIME FILE
--------------------------------------------------------------


function create_mime_type_file()
  local t = Util:parse_config_file("mime.types")
  require "tablesave"
  local file = "mime_types.lua"
  table.save(t, file)
  renoise.app():open_path(os.currentdir() .. file)
end

renoise.tool():add_keybinding {
  name = "Global:Tools:Download Test...",
  invoke = download_test
}
