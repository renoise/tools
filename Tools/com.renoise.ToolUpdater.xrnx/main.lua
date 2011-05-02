
-- Tool Updater
-- 
-- Looks for available updates of installed Tools, which will then be 
-- downloaded from the Renoise server and installed.

--[[============================================================================
main.lua
============================================================================]]--

-- Include HTTP Library
require "renoise.http"

-- Placeholder for the dialog
local dialog = nil

-- Placeholder to expose the ViewBuilder outside the show_dialog() function
local vb = nil

-- Read from the manifest.xml file.
class "RenoiseScriptingTool" (renoise.Document.DocumentNode)
  function RenoiseScriptingTool:__init()    
    renoise.Document.DocumentNode.__init(self) 
    self:add_property("Name", "Untitled Tool")
    self:add_property("Id", "Unknown Id")
  end

local manifest = RenoiseScriptingTool()
local ok,err = manifest:load_from("manifest.xml")

-- Contants identifying this script
local TOOL_NAME = manifest:property("Name").value
local TOOL_ID = manifest:property("Id").value

local DOMAIN  = 'http://tools.renoise.com/'
local JSON_RPC_URL = DOMAIN .. 'services/json-rpc'

-- Maximum number of tool updates per page in the browser
local MAX_TOOLS = 10

local TOOLS_ROOT = renoise.tool().bundle_path:match("^.+Scripts[\\/]Tools")


--------------------------------------------------------------------------------
--  Preferences
--------------------------------------------------------------------------------

local options = renoise.Document.create("ScriptingToolPreferences") {    
  CheckOnStartup = false,
  Shown = false,   
}

renoise.tool().preferences = options


--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

-- Cache for the remote updates.
local remote_updates = {}

-- Cache for local tools listings.
-- NOTE: The tables use the Tool IDs as keys, remember use pairs() to loop.
local installed_tools = nil
local filtered_tools = nil


-- Returns a table with metadata from all installed tools
--[[
  
  [47] => table
    [api_version] =>  2
    [author] =>  PeanutHead
    [bundle_path] =>  C:\Users\PeanutHead\AppData\Roaming\Renoise\V2.7.0\Scripts\Tools\se.peanuts.PeanutButter.xrnx\
    [category] =>  Food
    [description] =>  Nice and sticky
    [enabled] =>  true
    [homepage] =>  http://tools.renoise.com/tools/peanut-butter
    [icon] =>
    [id] =>  se.peanuts.PeanutButter
    [loaded] =>  true
    [name] =>  Peanut Butter
    [platform] =>
    [version] =>  2

--]]

-- Get a listing of all installed tools and a filtered listing 
-- of only the tools installed directly under the Tools root.
-- NOTE: The resulting tables use the Tool IDs as keys, remember use pairs() to loop.
local function get_installed_tools(filter)   
  
  -- Cache listing of all installed Tools
  if (not installed_tools) then 
    installed_tools = table.create()
    local tools = renoise.app().installed_tools    
    for _,tool in ipairs(tools) do      
      installed_tools[tool.id] = tool      
    end
  end
  
  -- NOTE Due to the table keys being IDs, 
  --  any second install of a tool will
  --  overwrite the first one in the table
  
  -- Cache listing of all Tools minus those not 
  -- installed directly under the Tools root.  
  if (not filtered_tools) then
    filtered_tools = table.create()
    local tools = renoise.app().installed_tools    
    for _,tool in pairs(tools) do         
      local bundle = tool.bundle_path
      local pos = bundle:find(tool.id) - 2 
      local dir = bundle:sub(1,pos)    
      if (dir == TOOLS_ROOT) then      
        filtered_tools[tool.id] = tool
      end    
    end
  end  
  
  if (filter) then
    return filtered_tools
  else
    return installed_tools
  end
end

-- Create a listing of Tools installed directly 
-- under the Tools root folder.
local function get_filtered_tools()           
  if (not filtered_tools) then    
  
    filtered_tools = table.create()
    
    -- Get new list
    local tools = renoise.app().installed_tools    
    
    for _,tool in ipairs(tools) do         
      local bundle = tool.bundle_path
      local pos = bundle:find(tool.id) - 2 
      local dir = bundle:sub(1,pos)    
      if (dir == TOOLS_ROOT) then      
        filtered_tools[tool.id] = tool
      end    
    end  
    
  end
  
  return filtered_tools
end
 
-- Get the metadata of an installed tool by ID.
local function get_tool_metadata(remote_id)
  return get_filtered_tools()[remote_id]   
end

-- Compares the installed tool to the latest version from the server.
-- Returns true if the tool on the server is newer than the installed one.
local function is_update_available(localtool, remotetool)
  -- Do the Tool IDs match?  
  if (not (localtool and localtool.id == remotetool.Id)) then
    return false
  end  
  
  -- Is the installed tool older than the one on the server?
  -- Also update any tools with older API versions. The API 
  -- version of the remote tool is guaranteed to match the 
  -- running Renoise instance (Service argument). 
  return (tonumber(localtool.version) < tonumber(remotetool.Version)
    or tonumber(localtool.api_version) < tonumber(renoise.API_VERSION)
  ) 
end

-- Loops over requested tool metadata from the server, 
-- compares with installed tool metadata.
local function find_updates(remote_versions)  
  if (not remote_updates) then
    remote_updates = table.create()  
  
    for _,r in ipairs(remote_versions) do
      if (is_update_available(get_tool_metadata(r.Id), r)) then
        remote_updates:insert(r)
      end
    end
  end
  return remote_updates
end


--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------

local download_queue = table.create()
local install_paths = table.create()

-- Validates the installation of updates by 
-- comparing the version numbers.
local function validate_updates()
  print("Validating installation...")
  
  -- Destroy the caches  
  installed_tools = nil
  filtered_tools = nil  
 
  -- Get new listing including the hopefully updates tools
  local f = get_filtered_tools()  
  
  for k,u in ipairs(remote_updates) do
    print(f[u.Id].version, u.Version, f[u.Id].version == u.Version)
  end      
end

-- Queue an update for download and install.
-- After the last update, trigger a validation function.
local function download_update(meta, last)  
  local url = DOMAIN .. meta.path
  
    -- ERROR CALLBACK
  local error = function(x, t, e)        
    print(x,t,e)
  end
  
  -- COMPLETE CALLBACK
  local complete = function()        
    vb.views.current_download.text = ""
    vb.views.progress.text = ""
    vb.views.current_download.visible = false
    vb.views.progress.visible = false
  end
  
  -- SUCCESS CALLBACK
  local success = function(filepath)
    
    -- Queue the installation until all updates have been downloaded
    install_paths:insert(filepath)
    
    if (last) then       
      print("Installing updates...")
      for _,path in ipairs(install_paths) do
        print("Installing " .. path)
        renoise.app():install_tool(path)      
      end
      print("Done installing updates.")
      
      -- Validate the installation by comparing 
      -- the version numbers. Wait a bit.           
      if (renoise.tool():has_timer(validate_updates)) then
        renoise.tool():remove_timer(validate_updates)
      end
      -- NOTE: Timer won't trigger. Why not?
      renoise.tool():add_timer(validate_updates, 1000)
    end
  end
  
  -- PROGRESS CALLBACK
  local progress = function(p)
    if (vb) then      
      vb.views.current_download.text = tostring(p.url)
      vb.views.progress.text = tostring(p.bytes)
    end
  end 
  
  -- init log/progress
  vb.views.current_download.text = ""
  vb.views.progress.text = ""
  vb.views.current_download.visible = true
  vb.views.progress.visible = true
  
  local request = Request({
    url=url, 
    method=Request.GET, 
    save_file=true, -- write to harddisk
    default_download_folder = false, -- keep in temp folder
    success=success,
    complete=complete,
    error=error,
    progress=progress
  })   
  download_queue[meta.Id] = request  
end


--------------------------------------------------------------------------------
--  Network code
--------------------------------------------------------------------------------

-- json_find_updates
local function json_find_updates(success, error, complete)    

  -- Destroy caches
  remote_updates = nil
  installed_tools = nil
  filtered_tools = nil
  
  -- Retrieve a table with metadata from all installed tools
  -- installed directly under the Scripts/Tools folder
  -- [api_version] [id] [version]  
  local tools = get_filtered_tools()      
  
  -- A table with the ID of every installed tool
  local installed_ids = table.create()  
  
  for _,tool in pairs(tools) do    
    installed_ids:insert(tool.id)    
  end
  
  -- No Tools/IDs found
  if (#installed_ids == 0) then    
    success({result={}})
    complete()
    return
  end
  
  -- Parameters to send to the server.  
  -- Id: table containing the installed IDs
  -- ApiVersion: the API version of the running instance of Renoise    
  
  local json_post_data = {
    method='renoisetool.get',
    params={
      Id=installed_ids,
      ApiVersion=tonumber(renoise.API_VERSION)
    }
  } 
  
  -- When more than x amount of tools are installed, 
  -- just get whole list of tools from the server.
  if (#installed_ids > 5) then
    json_post_data = {
      method='renoisetool.all',
      params= {
        ApiVersion=tonumber(renoise.API_VERSION)
      }
    }
  end
  
  -- Request settings
  local settings = {
    content_type='application/json',
    url=JSON_RPC_URL,
    method=Request.POST,
    data=json_post_data,
    
    -- error callback
    error = error,
    
    -- success callback
    success = function(response, text_status, xml_http_request) 
      if (response and response.result) then        
        if (type(response.result) == "table") then
          success(response, text_status, xml_http_request) 
        else
          -- No Table received
          local error_thrown = "Unexpected reponse data format."
          if (type(response.result) == "string") then
            error_thrown = response.result
          end
          error(xml_http_request, text_status, error_thrown)  
        end        
      elseif (response and response.error) then
        -- JSONRPC Error
        local error_thrown = ("%s: %s"):format(
          response.error.name,
          response.error.message)
        error(xml_http_request, text_status, error_thrown)         
      else
        local error_thrown = "The server sent data I did not expect " ..
          "and I don't know what to do with it."
        error(xml_http_request, text_status, error_thrown)
      end
    end,
    
    -- complete callback
    complete = complete, 
    
    data_type='json'
  } -- end settings
 
  local new_request = Request(settings)  
end


--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local function close_dialog()
  if (dialog and dialog.visible) then
    dialog:close()
  end
  if (renoise.tool():has_timer(close_dialog)) then
    renoise.tool():remove_timer(close_dialog)
  end
end

local function browser(autoclose, silent)

  -- If dialog is already open, focus it and be done with it.
  -- To recheck updates, user has to close the dialog first.
  if (dialog and dialog.visible) then
    dialog:show()
    return
  end
  
  vb = renoise.ViewBuilder()
  
  local status = vb:text{
    text = "Loading...",
    font = "bold"
  }
  
  local description = vb:text{
    text = TOOL_NAME.." retrieves a list of updated Tools from the Renoise server."
  }
  
  local settings = vb:row {
    vb:checkbox {        
      bind = options.CheckOnStartup
    },
    vb:text {
      text = "Check on startup"
    }
  }    
  
  local main = vb:column {
    id = "main"
  }
  
  local body = vb:column{ 
    margin=10,
    spacing=5, 
    uniform=true,
    description,
    status,
    main,
    settings,        
  }    
  
  if (not silent) then
    dialog = renoise.app():show_custom_dialog(      
      TOOL_NAME, body)        
  end
  
  -- COMPLETE CALLBACK      
  local function complete()
    
  end      
  
   -- ERROR CALLBACK            
  local function error(xml_http_request, text_status, error_thrown)
      status.text = "Could not load update info. Maybe a connection problem.\nReason given: " .. (error_thrown or "")
  end
        
  -- SUCCESS CALLBACK
  local function success(response, text_status, xml_http_request)
     
    body:remove_child(status)             
    
    -- Metadata from all installed Tools
    local metadata = response.result        
    
    -- Find updates
    local updates = find_updates(metadata)
    
    if (#updates == 0) then
      main:add_child(
        vb:text {
          text = "All your installed Tools are up-to-date.",
          font = "bold"
        }
      )
      if (autoclose) then
        if (renoise.tool():has_timer(close_dialog)) then
          renoise.tool():remove_timer(close_dialog)
        end
        renoise.tool():add_timer(close_dialog, 1000)
      end
      
      return
    end
    
    if (silent) then
      dialog = renoise.app():show_custom_dialog(      
      TOOL_NAME, body)
    end
                
    local pages = vb:row{
      spacing=5
    }
    
    local page_table = table.create()
    
    local page = vb:column{
      spacing=3,
      visible=true,
      uniform=true
    }
    
    -- Button states
    local amount_selected = 0
    local batch_selecting = false
    
    local function update_select_all_button()
      if (not batch_selecting) then
        if (amount_selected > #updates / 2) then
          vb.views.select_all_button.text = "Deselect All"
        else
          vb.views.select_all_button.text = "Select All"
        end
      end
    end
    
    local function select_update(selected)
      if (selected) then
        amount_selected = amount_selected + 1
      else 
        amount_selected = amount_selected - 1
      end
      vb.views.update_button.active = amount_selected > 0      
      update_select_all_button()
    end
    
    local function batch_select()
      batch_selecting = true
      for k,toolmeta in ipairs(updates) do
        vb.views["c_"..k].value = 
          (vb.views.select_all_button.text == "Select All")
      end  
      batch_selecting = false
      update_select_all_button()
    end
    
    -- Generate listing of available updates
    for k,toolmeta in ipairs(updates) do               
      
      -- Tool group
      local tool = vb:row{         
        style="group",           
        margin=3,
        
        -- Checkbox
        vb:checkbox {
          id="c_"..k,
          notifier = select_update 
        },          
        
        -- Tool title          
        vb:text{ 
          text=get_tool_metadata(toolmeta.Id).name, 
          font="bold"
        },
        
        -- Website
        vb:bitmap {          
          mode = "body_color",
          bitmap = "images/link-icon.bmp",
          notifier = function() 
            renoise.app():open_url(DOMAIN.."node/"..toolmeta.nid) 
          end
        },
        
        -- Tool version
        vb:text{ 
          text=toolmeta.Version
        },       
      } -- end tool
              
      -- Add tool to page
      page:add_child(tool)        
      
      -- Pagination
      if (k % MAX_TOOLS == 0 or k == #updates) then
        local pid = "page_"..k / MAX_TOOLS
        page_table[pid] = page
        pages:add_child(page_table[pid]) 
        page = vb:column{
          spacing=3,
          visible=false,
          uniform=true
        }
      end
      
    end -- end listing         
         
    local items = table.create()
    
    for i=1,page_table:count() do
      items:insert("Page " .. i)
    end      
    
    -- Page Selector
    local page_selector = vb:popup{
      items = items,
      notifier = function(item)               
        for _,page in pairs(page_table) do
          page.visible = false
        end
        page_table["page_"..item].visible = true
        pages:resize()
      end          
    }     
    
    -- Update Button
    local update_button = vb:button{
      id = "update_button",
      active = amount_selected > 0,
      text = "Update\n selected Tools",       
      notifier = function()           
          -- Apply user selected updates          
          local selected_updates = table.create()
          local count = 0
          for k,toolmeta in ipairs(updates) do
            count = count + 1
            if (vb.views["c_"..k].value) then              
              download_update(toolmeta, amount_selected==count)
            end
          end          
        end
    }
    
    --- Select All Button
    local select_all_button = vb:button{
      id = "select_all_button",
      text = "Select All",
      notifier = batch_select
    }
          
    local left_column_height = "100%"
    if (#updates < 3) then 
      left_column_height = 100
    end 
    
    -- Body
    main:add_child(                      
      vb:row {          
        spacing = 5, 
                  
        -- left column
        vb:column { 
          margin = 3,
          height = left_column_height,
          style = "body",
          uniform = true,              
          page_selector,
          update_button,
          select_all_button,
        },
        
        -- right column
        pages          
      }     
    ) -- end body               
    
    main:add_child(
      vb:column{
        vb:text {
          id = "current_download",
          visible = false
        },
        vb:text {
          id = "progress",
          visible = false
        }      
      }
    )
    
  end
  
  json_find_updates(success, error, complete)  
end


--------------------------------------------------------------------------------
--  Start-up Mechanism
--------------------------------------------------------------------------------

-- Tool variables are cleared on "Reload all Tools", so there's a 
-- degree of statelessness. This mechanism bypasses that limitation 
-- using the Document Preferences API and document notifiers.

-- When Renoise is running, there's always a loaded document.
-- This fact can be used to determine whether is running or 
-- starting up. 
if (not options.Shown.value and options.CheckOnStartup.value) then  
  local autoclose = false
  local silent = true
  browser(autoclose, silent)
end

-- When starting or loading a new song, set a flag to true.
renoise.tool().app_new_document_observable:add_notifier(function()
  options.Shown.value = true
end)

-- When unloading a song or quitting Renoise, set a flag to false.
renoise.tool().app_release_document_observable:add_notifier(function()  
  options.Shown.value = false   
end)


--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Help:Find Tool Updates...",
  invoke = function()
    local autoclose = true
    local silent = false
    browser(autoclose, silent)
  end
}
