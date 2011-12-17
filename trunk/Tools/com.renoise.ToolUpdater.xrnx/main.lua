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
local remote_updates = table.create()

-- Cache for local tools listings.
-- NOTE: The tables use the Tool IDs as keys, remember use pairs() to loop.
local installed_tools = nil
local filtered_tools = nil


local function call(func, ...)    
  if (func and type(func) == "function") then
    func(unpack(arg))
  end 
end


-- Returns a table with metadata from all installed tools
--[[
  
  [47] => table
    [api_version] =>  2
    [author] =>  PeanutHead
    [auto_upgraded] => false
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

-- Create a listing of Tools, discarding old duplicates.
local function get_filtered_tools()           
  
  if (not filtered_tools) then    
  
    filtered_tools = table.create()
    
    -- Get new list
    local tools = renoise.app().installed_tools    
    
    -- Add new or newer tool to list
    for _,tool in ipairs(tools) do        
      if (not filtered_tools[tool.id] or 
        filtered_tools[tool.id].version < tool.version) then
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
    or (localtool.auto_upgraded and tonumber(localtool.version) == tonumber(remotetool.Version))
    or tonumber(localtool.api_version) < tonumber(renoise.API_VERSION)
  ) 
end

-- Loops over requested tool metadata from the server, 
-- compares with installed tool metadata.
local function find_updates(remote_versions)  
  if (#remote_updates == 0) then      
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

-- Stores request objects by Tool ID
local download_queue = table.create()

local install_paths = table.create()
local selected_updates = table.create()

-- Validates the installation of updates by 
-- comparing the version numbers.
local function validate_updates(callback)
  print("Validating update process...")
  
  -- Destroy the caches  
  installed_tools = nil
  filtered_tools = nil  
 
  -- Get new listing including the hopefully updates tools
  local f = get_filtered_tools()  
    
  for k,u in ipairs(remote_updates) do
    local status = "FAILED"
    if (f[u.Id].version == u.Version) then
      status = "ok"
    end
    print(("Update [V%s to V%s] for %s %s"):format(
      f[u.Id].version, u.Version, u.Id, status))
  end      
  print("Validation finished")
  
  call(callback)  
end


-- Start installation of the updates if all downloads have completed.
local function start_installation(completed_all)  
  
  if (download_queue:count() == 0) then               
    
    completed_all()
    
    for _,path in ipairs(install_paths) do
      -- Skip failed downloads
      if (#path > 0) then
        print("Installing " .. path)
        renoise.app():install_tool(path)            
      end
    end    
    
    -- Validation has to start after installation
    -- validate_updates()    
  end
end

-- Queue an update for download and install.
-- After the last update, trigger a validation function.
local function download_update(meta, progress_callback, completed_one, completed_all, error_callback)
  
  local url = DOMAIN .. meta.path 
  
    -- ERROR CALLBACK
  local error = function(x, t, e)            
      
    -- Add a dummy path just to flag the download as completed
    install_paths:insert("")
    
    error_callback(x,t,e)
  end
  
  -- COMPLETE CALLBACK
  local complete = function()                
    
    -- Remove request from queue
    if (download_queue[meta.Id]) then
      download_queue[meta.Id] = nil
    end
  
    -- Launch callback
    call(completed_one)
      
    -- Start installation when all downloads have completed
    start_installation(completed_all)    
    
  end
  
  -- SUCCESS CALLBACK
  local success = function(filepath)
    
    -- Queue the installation until all updates have been downloaded
    install_paths:insert(filepath)          
  end
  
  -- PROGRESS CALLBACK
  local progress = progress_callback
  
  -- Look for new updates (if not already downloading)
  if (not download_queue[meta.Id]) then
  
    local request = Request({
      url=url,
      method=Request.GET, 
      data={nid=meta.nid},
      save_file=true, -- write to harddisk
      default_download_folder = false, -- keep in temp folder
      success=success,
      complete=complete,
      error=error,
      progress=progress
    })     
  
    download_queue[meta.Id] = request  
  end
end

local function cancel_update_process()
  -- Cancel downloads one by one
  for id,request in pairs(download_queue) do
    download_queue[id] = nil
    request:cancel()            
  end
  -- Delete references to temp files
  table.clear(install_paths)
end


--------------------------------------------------------------------------------
--  Network code
--------------------------------------------------------------------------------

-- json_find_updates
local function json_find_updates(success, error, complete)    

  -- Destroy caches
  remote_updates = table.create()
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

local body = nil

local function browser_init(autoclose, silent)  
  
  local success = nil
  local error = nil
  local complete = nil
  
  vb = renoise.ViewBuilder()
  
  
  local status = vb:text{        
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
  
  local monitor = vb:column{
    style = "border",
    margin = 10,
    id = "monitor",
    visible = download_queue:count() > 0,
    vb:text {
      id = "current_download",      
    },
    vb:text {
      id = "progress",      
    }      
  }
  
  local function dialog_init()
    status.visible = true
    status.text = "Loading..."    
    main.visible = false    
  end
  
  local check_button = vb:button {    
    visible = false,
    text = "Search for updates again",
    notifier = function()      
      dialog:close()
      vb = nil      
      browser_init(autoclose, false)      
    end
  }
  
  body = vb:column{ 
    id = "body",
    margin=10,
    spacing=5, 
    uniform=true,
    description,
    status,
    main,
    settings,                
    monitor,    
  } 
  
  dialog_init()   
  
  if (not silent and (not dialog or not dialog.visible)) then
    dialog = renoise.app():show_custom_dialog(      
      TOOL_NAME, body)        
  end
  
  -- COMPLETE CALLBACK        
  complete = function()    
    check_button.visible = true
  end      
  
   -- ERROR CALLBACK            
  error = function(xml_http_request, text_status, error_thrown)
      status.text = "Could not load update info. Maybe a connection problem.\nReason given: " .. (error_thrown or "")
  end
        
  -- SUCCESS CALLBACK
  success = function(response, text_status, xml_http_request)     
    
    -- Metadata from all installed Tools
    local metadata = response.result        
    
    -- Find updates
    local updates = find_updates(metadata)
    
    if (#updates == 0) then
      
      status.text = "All your installed Tools are up-to-date."
      
      if (autoclose) then
        if (renoise.tool():has_timer(close_dialog)) then
          renoise.tool():remove_timer(close_dialog)
        end
        renoise.tool():add_timer(close_dialog, 1000)
      end
      
      return
    end
    
    status.text = "The following updates are available:"
                
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
          notifier = select_update,          
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
          text="V"..toolmeta.Version
         },       
        
      } -- end tool
              
      -- Add tool to page
      page:add_child(tool)        
      
      -- Pagination
      if (k % MAX_TOOLS == 0 or k == #updates) then
        local pagenumber = math.ceil(k / MAX_TOOLS)
        local pid = "page_"..pagenumber
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
    
    -- Called at the start of download process
    local init_progress = function()
      -- Disable all buttons
      --vb.views.update_button.active = false        
      vb.views.select_all_button.active = false        
      -- Init progress monitor
      vb.views.current_download.text = ""
      vb.views.progress.text = ""
      vb.views.monitor.visible = true      
    end
    
    -- DOWNLOAD PROGRESS CALLBACK
    local progress_callback = function(p)      
      if (vb) then            
        vb.views.current_download.text = tostring(p.url)
        local str = ""
        if (p.eta and p.percent and p.estimated_duration) then
          local eta = ("%d sec"):format(p.eta)
          local dur = ("%d sec"):format(p.estimated_duration)          
          if (p.eta > 60) then
            eta = ("%d min"):format(p.eta / 60)
          end          
          if (p.estimated_duration > 60) then
            dur = ("%d min"):format(p.estimated_duration / 60)
          end          
          str = ("%d%% [ETA %s / %s]; Avg Speed: %d kB/s"):format(
            p.percent, eta, dur, p.avg_speed)   
          vb.views.progress.text = str
        else
          vb.views.progress.text = tostring(p.bytes)
        end
        vb.views.progress.text = str
      end
    end
    
    -- DOWNLOAD FAILED CALLBACK
    local download_failed = function(x,t,e)
      status.visible = true
      status.text = ("Download failed: %s\nReason: %s"):format(x.url, e)
      print("[ERROR]", x.url, t, e)
    end
    
    -- COMPLETED ONE DOWNLOAD
    -- Called whenever a download has finished
    local completed_one = function()      
    end
    
    -- COMPLETED ALL DOWNLOADS
    -- Stuff to do when installation is complete
    local completed_all = function()          
      if (vb) then
        -- Enable all buttons
        vb.views.update_button.active = true
        vb.views.select_all_button.active = true        
        -- Reset progress        
        vb.views.monitor.visible = false
        vb.views.current_download.text = ""
        vb.views.progress.text = ""        
        vb.views.update_button.text = "Update\nselected Tools"        
      end
    end
    
    -- Update Button
    local update_button = vb:button{
      id = "update_button",
      active = amount_selected > 0 and #remote_updates  == 0,
      text = "Update\nselected Tools",
      notifier = function()                                           
        
        if (download_queue:count() > 0) then
          
          cancel_update_process()
          
          -- Hide progress        
          vb.views.monitor.visible = false
          vb.views.current_download.text = ""
          vb.views.progress.text = ""        
          
          -- Reset checkboxes
          for k,_ in ipairs(updates) do            
            if (vb.views["c_"..k].value) then              
              vb.views["c_"..k].active = true
            end
          end        
          
          vb.views.update_button.text = "Update\nselected Tools"
        
        else 
          
          status.text = ""
          status.visible = false
          init_progress()
          
          vb.views.update_button.text = "Cancel\nupdate process"
           
          -- Download and install user selected updates                                                
          for k,toolmeta in ipairs(updates) do            
            if (vb.views["c_"..k].value) then              
              vb.views["c_"..k].active = false
              download_update(toolmeta, progress_callback, 
                completed_one, completed_all, download_failed)        
            end
          end  
        
        end                          
      
      end -- end Update Button
    }
    
    --- Select All Button
    local select_all_button = vb:button{
      id = "select_all_button",
      text = "Select All",
      notifier = batch_select
    }
    
    -- Main
    main:add_child(
      vb:row {          
        spacing = 5, 
                  
        -- left column
        vb:column { 
          margin = 3,
          height = 100,
          style = "body",
          uniform = true,              
          page_selector,
          update_button,
          select_all_button,
        },
        
        -- right column
        pages          
      }     
    ) -- end Main               
  
    -- status.visible = false
    main.visible = true
    
    -- Show dialog now because it wasn't open before
    if (silent and not dialog) then
      dialog = renoise.app():show_custom_dialog(      
      TOOL_NAME, body)
    end
      
  end
  
  -- Check RIGHT NOW!  
  json_find_updates(success, error, complete)    
end


local function browser_open(autoclose, silent)
  -- If dialog is already open, focus it and be done with it.
  -- To recheck updates, user has to close the dialog first.
  if (dialog and dialog.visible) then    
    dialog:show()
    return
  end    
  
  if (download_queue:count() == 0 or not vb) then
    browser_init(autoclose, silent)  
    return
  end
  
  if (not silent) then
    dialog = renoise.app():show_custom_dialog(      
      TOOL_NAME, body)        
   end
  
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
  browser_open(autoclose, silent)
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
    local autoclose = false
    local silent = false
    browser_open(autoclose, silent)
  end
}
