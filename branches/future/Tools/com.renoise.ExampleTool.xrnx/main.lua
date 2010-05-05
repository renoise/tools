--[[----------------------------------------------------------------------------
com.renoise.ExampleTool.xrnx/main.lua
----------------------------------------------------------------------------]]--

-- tool scripts must describe itself through a manifest XML, to let Renoise
-- know which API version it relies on, what "it can do" without actually
-- loading it. this is done in the manifest.xml
-- when the manifest looks OK, the main file of the tool will be loaded.
-- This is this file, main.lua.
-- You can load other files from here via LUAs require, or simply put
-- all the tools code in here. Just like you want...
-- Please note that your tool loaded only once when the application starts,
-- and will run in the background until the application quits
 
 
--------------------------------------------------------------------------------
-- manifest.mxl (required)

--[[

-- this is the API version the script relies on. The API is backwards
-- compatible (from version 1.0 on), but not forwards compatible.
-- So you can ensure that all API functions you use are available.
-- The current version is defined at 'renoise.API_VERSION'
<ApiVersion>

-- Unique identifier for your tool. The identidier must match the bundle name
-- of the tool (without the extension xrnx), and is used by Renoise to make sure
-- that only one version of a tool is present, to be able to auto-update it and
-- to create a default filename for it in case the tool was drag and dropped
-- to get installed. The id should be a string with 3 parts, separated by dots,
-- like org.superduper.tool. You don't have to use prefixes like com/org and so
-- on, but please try to use something personal, like your name or URL or
-- company name in order to make it as unique as possible.
<Id>


-- Name of the tool as visible to the user in for example tool browsers
<Name>

-- the author field is only used in descriptions of the tools in the app
-- or when a script fails. Providing an email is not necessary, but
-- recommended.
<Author>

-- the description is curently unused, but may be useful in some kind of
-- a tools editor for users, where they can see what the scripts are doing...
<Description>

--]]



--------------------------------------------------------------------------------
-- main.lua manifest (optional)

manifest = {}


-- manifest.actions (optional)

-- optional list of functions, that this script exposes to the user as menu
-- entries or keyboard shortcuts. when no actions are defined, only the
-- "globals" and notifiers of the script are invoked. This may be useful for
-- a script which only needs to run in the background, like for example an
-- OSC tool, or auto-backup script extension...
manifest.actions = {}

-- when an actions table is available, each each action must define:
--
-- * required fields
--   ["name"] = a string which is shown in the menu. use ":" for sub groups
--   ["description"] = a string of what this action does
--   ["invoke"] = a function that is called to invoke the action
--
-- * optional fields:
--   ["active"] =  a function that should return true or false. on false
--     the action will not be invoked and "grayed out" in menus. the function
--     is called every time before "invoke" is called and every time before
--     a menu gets visible
--
-- Placing menu entries in other places than the global menu:
--
-- You can place your entries in any context menu or any window menu in Renoise.
-- to to so, simply use one of the specified prefix strings:
-- "WindowMenu"
-- "MainMenu:File", "MainMenu:Edit", "MainMenu:View",
--   "MainMenu:Tools", "MainMenu:Help"
-- "DspDevice", "DspDeviceChain", "DspDeviceChainList",
--    "DspDeviceHeader", "DspParameterAutomation", "DspAutomationList"
-- "EnvelopeEditor"
-- "InstrumentBox", "InstrumentBoxSample"
-- "PatternSequencer"
-- "PatternEditor"
-- "PatternMatrix", "PatternMatrixHeader"
-- "SampleEditor", "SampleEditorRuler"
-- "DiskBrowserDirectoryList", "DiskBrowserFileList"
-- "MixerDspDeviceChain"

manifest.actions[#manifest.actions + 1] = {
  name = "MainMenu:Tools:Example Tools:Example Tool:Show Dialog",
  description = "Shows a totally useless dialog!",
  invoke = function() show_dialog() end
}

-- note: "show_status_message" is wrapped into a local function(), because
-- show_status_message is not yet know here. Its defined below...
manifest.actions[#manifest.actions + 1] = {
  name = "MainMenu:Tools:Example Tools:Example Tool:Show Status Message",
  description = "prints something to the status bar...",
  invoke = function() show_status_message() end
}


-- manifest.notifications (optional)

-- optional list of notifications/events that the app forwards to
-- your running script
manifest.notifications = {}

-- invoked, as soon as the application became the foreground window,
-- for example when you alt-tab'ed to it, or switched with the mouse
-- from another app to Renoise
manifest.notifications.app_became_active = function()
  handle_app_became_active_notification()
end

-- invoked, as soon as the application looses focus, another app
-- became the foreground window
manifest.notifications.app_resigned_active = function()
  handle_app_resigned_active_notification()
end

-- invoked periodically in the background, more often when the work load
-- is low. less often when Renoises work load is high.
-- The exact interval is not defined and can not be relied on, but will be
-- around 10 times per sec.
-- You can do stuff in the background without blocking the application here.
-- Be gentle and don't do CPU heavy stuff in your notifier!
manifest.notifications.app_idle = function()
  handle_app_idle_notification()
end

-- invoked each time a new document (song) was created or loaded
manifest.notifications.app_new_document = function()
  handle_app_new_document_notification()
end

-- This notifier helps you testing & debugging your script while editing
-- it with an external editor or with Renoises built in script editor:
--
-- As soon as you save your script outside of the application, and then
-- focus the app (alt-tab to it for example), your script will get instantly
-- reloaded and this notifier is called with this notifier set.
-- You can put a test function into this notifier, or attach to a remote
-- debugger like RemDebug or simply nothing, just enable the auto-reload
-- functionality.
--
-- When editing script with Renoises built in editor, tools will automatically
-- reload as soon as you hit "Run Script", even if you don't have this notifier
-- set, but you nevertheless can use this to automatically invoke a test
-- function.
---
-- Note: When reloading the script causes an error, the old, last running
-- script instance will continue to run.
--
-- Another note: Changes in the actions menu will not be updated unless
-- you reload all tools manually with 'Reload Tools' in the menu.

manifest.notifications.auto_reload_debug = function()
  handle_auto_reload_debug_notification()
end


-------------------------------------------------------------------------------

-- globals

-- set this to true, to print notification status to the console, to
-- see when which notifier gets called...
print_notifications = false

-- the script is loaded once, but the actions may be invoked several
-- times, so you can use global variables to memorize stuff...
status_message_count = 0


-- if you want to do something each time the script gets loaded, then
-- simply do it here, in the global namespace
-- IMPORTANT: there will be no song (yet) when this script initializes, so
-- any access to app().current_document() or song() will fail here.
-- if you really need the song to initialize your application, do this in
-- the notifications.app_new_document functions or in your actions...
if print_notifications then
  print("ExampleTool.lua: script was loaded...")
end

-------------------------------------------------------------------------------

-- actions

-- this is the action which gets invoked when hitting
-- "Example Tool:Show Dialog". see the manifest description above
function show_dialog()
  renoise.app():show_warning(
    string.format(
      "This example does nothing more beside showing a warning message " ..
      "and the current BPM, which has an amazing value of '%s'!",
      renoise.song().transport.bpm)
  )
end

function show_status_message()
  status_message_count = status_message_count + 1

  renoise.app():show_status(
    string.format("ExampleTool.lua: Status message no. %d...",
      status_message_count)
  )
end


-------------------------------------------------------------------------------

-- notifications

function handle_app_became_active_notification()
  if print_notifications then
    print("ExampleTool.lua: >> app_became_active notification")
  end
end

function handle_app_resigned_active_notification()
  if print_notifications then
    print("ExampleTool.lua: << app_resigned_active notification")
  end
end

last_idle_time = os.clock()
function handle_app_idle_notification()
  if os.clock() - last_idle_time >= 10 then
    last_idle_time = os.clock()
      if print_notifications then
        print("ExampleTool.lua: 10 second idle notification")
      end
   end
end

function handle_app_new_document_notification()
  if print_notifications then
    print("ExampleTool.lua: !! app_new_document notification")
  end
end

function handle_auto_reload_debug_notification()
  if print_notifications then
    print("ExampleTool.lua: ** auto_reload_debug notification")
  end
end


--[[----------------------------------------------------------------------------
----------------------------------------------------------------------------]]--
