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

-- BROWSE --
entry.name = "Main Menu:Tools:"..TITLE..":Browse Tools..."
entry.invoke = function()   
  browse_tools() 
  -- show_tool_updates() 
end
renoise.tool():add_menu_entry(entry)

-- INSTALLED VERSIONS --
entry.name = "Main Menu:Tools:"..TITLE..":Show Installed Tools..."
entry.invoke = function()   
  local versions = get_installed_versions()    
  renoise.app():show_message(versions:concat("\n"))
end
renoise.tool():add_menu_entry(entry)

-- FETCH & READ RSS --
entry.name = "Main Menu:Tools:"..TITLE..":Parse Remote XML..."
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

-- UNZIP --
entry.name = "Main Menu:Tools:"..TITLE..":Install a Tool..."
entry.invoke = function()   
  local ok, err = unzip_tool("temp/com.renoise.UnzipTestSubject.xrnx")
  if (not ok) then
    renoise.app():show_error("UnZip: " .. err)
  else
    renoise.app():show_message("Test file was unzipped into:"..
      "\n\n Tools/com.renoise.UnzipTestSubject.xrnx")
  end  
end
renoise.tool():add_menu_entry(entry)  
  

-------------------------------------------------------------------------------
--  Main functions
-------------------------------------------------------------------------------

function get_xml()
   HTTP:request("http://renoise.com/download/RenoiseDocVersions.xml",
  -- HTTP:request("http://www.renoise.com/board/index.php?app=core&module=global&section=rss&type=forums&id=1",
    Request.POST, 
    nil, 
    function(data) 
      rprint(data)
      local vb = renoise.ViewBuilder()
      renoise.app():show_message("Open the Scripting Terminal to see the parsed remote XML")
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
  TRACE("Scanning path: '"..path.."'")
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

function get_installed_versions()    
  local versions = table.create()
  local root = get_tools_root()
  local tools = scan_tool_dirs(root)
  -- TRACE(tools)
  
  for _,tool in ipairs(tools) do    
    -- TRACE(root..v)
    local xml = root..tool.."/manifest.xml"    
    if (io.exists(xml)) then
      --local str = Util:read_file(xml)
      local tree = parse_xml(xml)
      TRACE(tree)
      local version, id        
      for _,v in ipairs(tree.ChildNodes) do               
        if (v.Name == "Version") then          
          version = v.Value            
        elseif (v.Name == "Id") then
          id = v.Value          
        end
        if (version and id) then
          local str = ("[%s] %s"):format(id, version)           
          versions:insert(str)
          break
        end
      end            
    end
  end  
  return versions
end

function text_xml_message()
  local settings = {
    content_type='application/xml',
    --data_type = 'xml',
    url='http://tools.renoise.com/services/xmlrpc',
    method=Request.POST,
    data={methodCall={methodName='views.get',params={
      param={value={string='ToolUpdates'}}
    }}},
    error=function(xml_http_request, text_status, error_thrown)
      renoise.app():show_error(
        "Could not load update info :(\n" .. (error_thrown or "") ) 
    end,
    success=function(d, text_status, xml_http_request)
      renoise.app():show_message(d)
    end    
  }
    
  local new_request = Request(settings)  
end

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


require "unzip"

-- Unzips the Tool within the Tools folder, in
-- a subfolder with the filename of the XRNX.
function unzip_tool(path)
  local p = URL:parse_path(path) 
  local filename = p[#p]
  local destination = get_tools_root() .. filename 
  return unzip(path, destination)
end
