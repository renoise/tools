--[[============================================================================
main.lua
============================================================================]]--

local DOMAIN = "http://www.renoise.com"

local DEBUG = true
local INSTALLED_VERSION = renoise.RENOISE_VERSION

local vb = nil
local dialog = nil

-- requires

require "renoise.http"


--------------------------------------------------------------------------------
--  Preferences
--------------------------------------------------------------------------------

local options = renoise.Document.create("ScriptingToolPreferences") {    
  CheckOnStartup = true,
  Shown = false, 
  LastVersion = 0,
  DontRemindOldNews = false
}

renoise.tool().preferences = options


--------------------------------------------------------------------------------
--  Helper functions
--------------------------------------------------------------------------------

local function is_demo()
  return string.find(INSTALLED_VERSION, "Demo")~=nil
end

local function download_handler()  
  local url = "http://www.renoise.com/demo" 
  if (not is_demo()) then
    url = "http://backstage.renoise.com"    
  end
  renoise.app():open_url(url)  
  if (dialog and dialog.visible) then 
    dialog:close()
  end
end          

-- strip 0
local function get_status_version_str(s)
  s = tonumber(s)
  if (s == 0) then
    return ''
  end
  return s
end

local function get_release_str(s)
  s = tonumber(s)
  local v = {'Alpha','Beta','Release Candidate','Final'}
  return v[s]
end

local function get_version_str(product, version_table)
  local v = version_table
  return ("%s %d.%d.%d %s %s %s"):format(
        product, v.major, v.minor, v.revision, get_release_str(v.status),
        get_status_version_str(v.version), v.demo)
end

local function parse_renoise_version()
  local v = INSTALLED_VERSION
  
  local a = Util:split(v,'%.')
  local major = a[1]
  local minor = a[2]
  
  local b = Util:split(a[3], ' ')
  local revision = b[1]
  
  local status = "Final"
  local demo = true
  local version = 0
  local s = {a=1,b=2,rc=3,Final=4}
  
  if (b[2] == nil) then -- Final Registered    
    demo = false
  elseif (b[2] == "Demo") then -- Final Demo
    demo = true
  else    
    status = b[2]:match("(%a+)%d") -- a/b/rc
    version = b[2]:match("%a+(%d+)") -- 1,2,3...
    if (b[4] and b[4] == "Demo") then -- Demo
      demo = true
    else -- Registered
      demo = false
    end
  end
  if (demo) then 
    demo = "Demo"
  else 
    demo = "Registered"
  end
  return {major=major, minor=minor, revision=revision, 
    status=s[status], version=version, demo=demo}
end

local function get_version_hash(r)
  return (r.major*10000+r.minor*1000+r.revision*100+r.status*10+r.version)
end

-- Is installed version outdated compared to remote version?
local function is_newer(r)
  local i = parse_renoise_version()    
  
  local remote = get_version_hash(r)
  local installed = get_version_hash(i)
  
  if (DEBUG) then
    print("----------remote------------")
    rprint(r)
    print(remote)
    print("---------installed----------")
    rprint(i)
    print(installed)
    print("-----------------------------")
  end
  
  return remote > installed
end

local function is_old_news(r)
  local remote = get_version_hash(r)  
  return (options.LastVersion.value >= remote)
end


--------------------------------------------------------------------------------
--  Dialog
--------------------------------------------------------------------------------


-- This function is directly called by a launching the script 
-- through the Help > Check for Updates menu item. It's also
-- called in the last stage of the jsonrpc() function during a 
-- start-up check.
local function show_dialog(msg, outdated, remote_version)  
  if dialog and dialog.visible then
    dialog:show()
    return
  end
  
  vb = renoise.ViewBuilder()
  
  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local DEFAULT_CONTROL_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local BUTTON_WIDTH = 6*renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local BUTTON_HEIGHT = 2*renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
  
  local content = vb:column {
    margin = DEFAULT_DIALOG_MARGIN,
    spacing = DEFAULT_CONTROL_SPACING,    
    
    -- Message
    vb:column {      
      style = "group",
      margin = DEFAULT_DIALOG_MARGIN,
      
      vb:text {
        id = "msg",
        text = msg,        
      },    
      -- Version Info
      vb:text {
        text = "Installed Version",
        font = "bold"        
      },
      vb:text{
        id = "installed_version_textfield",
        text = get_version_str("Renoise", 
          parse_renoise_version(INSTALLED_VERSION))
      }, 
       vb:text {
        text = "Available Update",
        font = "bold"        
      }, 
      vb:text{
        id = "latest_update_textfield",
        text = remote_version
      },             
    },
    
    -- Buttons
    vb:horizontal_aligner {      
      mode = "left",
      vb:button {
        visible = false,
        width = BUTTON_WIDTH,
        height = BUTTON_HEIGHT,
        text = "Close",
        notifier = function() 
          dialog:close()
          -- TODO maybe cancel process here?
        end
      },
      vb:button {                
        width = BUTTON_WIDTH,
        height = BUTTON_HEIGHT,
        id = "download_button",
        visible = outdated or false,
        text = "Go to Download Page",
        notifier = download_handler
      }          
    },
    
    -- Start-Up Options
    vb:column {
      spacing = DEFAULT_CONTROL_SPACING,
      id = "options_rack",
      vb:text {
        font = "bold",
        text = "Options for Start-Up Check"
      },
      vb:row {      
        spacing = DEFAULT_CONTROL_SPACING,        
        vb:checkbox {        
          bind = options.CheckOnStartup,
          notifier = function(v) 
            vb.views.remind_row.visible = v
            vb.views.options_rack:resize()
          end
        }, 
        vb:text{
          text = "Check for updates"
        }
      },
      vb:row {      
        id = "remind_row",                        
        spacing = DEFAULT_CONTROL_SPACING,                
        visible = options.CheckOnStartup.value,
        vb:checkbox {        
          id = "remind_checkbox",
          bind = options.DontRemindOldNews
        }, 
        vb:text{
          text = "Don't tell me about this update again"
        }
      }
    },    
  }  
  
  dialog = renoise.app():show_custom_dialog("Check for Updates", content) 
end

-- Update the dialog that was launched manually, 
-- or show the startup dialog if there's an update.
local function update_dialog(version, outdated)              
  local message = nil
  if (outdated) then
    message = "There is an update for your Renoise installation!"    
  else
    message = "Your Renoise installation is up-to-date."     
  end       
  
  if dialog and dialog.visible then      
    vb.views.msg.text = message
    vb.views.latest_update_textfield.text = version
    vb.views.download_button.visible = outdated or false            
    dialog:show()
    return
  else      
    show_dialog(message, outdated, version)    
  end        
end


--------------------------------------------------------------------------------
--  Network code
--------------------------------------------------------------------------------

-- Executes a RPC call to a service on a remote server. 
-- Sends product name and demo state in JSON.
-- Receives version numbers in JSON.
-- Triggers dialogs. 
local function check_product_version_jsonrpc(menu)
  if (menu) then   
    show_dialog("Checking for updates...")
    --vb.views.remind_row.visible = false
  end
    
  local settings = {
    content_type='application/json',    
    url= DOMAIN..'/services/json-rpc',  
    method=Request.POST,
    data_type = 'json',
    data={
      version="1.1",
      method="product-version-checker.get",
      params={title='renoise', demo=is_demo() },      
    },
    error=function(xml_http_request, text_status, error_thrown)
      if (options.Shown.value) then
        if (dialog and dialog.visible) then
          dialog:close()
        end
        renoise.app():show_warning("Update check failed: \n"
          .. (error_thrown or "") ) 
      end
    end,
    success=function(d, text_status, xml_http_request)
      if (DEBUG) then
        print("-------service response-------")
        rprint(d)
        print("------------------------------")
      end

      local r = d.result
      
      -- Wipe status version if release status is Final
      if (r.status == 4) then
        r.version = 0
      end
      
      -- Installed version outdated / remote version is newer?
      local outdated = is_newer(r)
      
      -- check_product_version_jsonrpc() runs only once 
      -- on startup,or manually through the menu.     
      
      -- When Renoise is running, there's always a document
      -- so options.Shown.value is always true.
      
      -- By the time we're here, a document has probably loaded. 
      -- options.Shown.value is set to true by the notifier.
      
      -- You can see that happening by uncommenting this
      -- and restarting Renoise:
      
      -- renoise.app():show_warning("Outdated: " .. tostring(outdated)  
      --   .. "\nShown: " .. tostring(options.Shown.value));
      
      -- If it's a start-up check and there's no update, 
      -- don't display a dialog. If we check through the 
      -- menu, we want to see a dialog no matter what.
      
      -- Not accessed through the menu == start-up check.
      if (not menu) then
        if (not outdated) then          
            -- there is no newer version available than 
            -- the one already installed
            return         
        elseif (is_old_news(r) and options.DontRemindOldNews.value) then
          -- we don't want to keep being nagged about
          --  a newer version on the server
          return
        end
      end
      
      -- Remember the newest version
      if (outdated) then
        options.LastVersion.value = get_version_hash(r)
      end
      
      local version = get_version_str(r.title, r)
      
      -- Update the dialog that was launched manually, 
      -- or show the startup dialog if there's an update.
      update_dialog(version, outdated)
      
    end    
  }
    
  local new_request = Request(settings)  
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
  check_product_version_jsonrpc()  
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
--  Menu
--------------------------------------------------------------------------------

local entry = {}

entry.name = "Main Menu:Help:Check for Updates..."
entry.invoke = function() check_product_version_jsonrpc(true) end
renoise.tool():add_menu_entry(entry)