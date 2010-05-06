--[[----------------------------------------------------------------------------
com.renoise.ExampleTool.xrnx/main.lua
----------------------------------------------------------------------------]]--

-- XRNX Bundle Layout:

-- Tool scripts must describe itself through a manifest XML, to let Renoise
-- know which API version it relies on, what "it can do" and so on, without 
-- actually loading it. This is done in the manifest.xml
--
-- When the manifest looks OK, the main file of the tool will be loaded. This 
-- is this file -> "main.lua".
-- You can load other files from here via LUAs 'require', or simply put
-- all the code in here. 
 
 
--------------------------------------------------------------------------------
-- manifest.mxl (required)

-- see 'manifest.mxl' for a description please


--------------------------------------------------------------------------------
-- main.lua  (required)

-- _MENU_ENTRIES and _KEY_BINDINGS (optional)

-- Optional list of menu and keyboard shortcut entries this script exposes to 
-- the user. When no entries and key bindings are defined, only the "globals" 
-- and notifiers of the script are invoked. This may be useful for a script 
-- which only needs to run in the background, like for example an OSC tool, or 
-- autobackup script extension or whatever else you can imagine...


-- _MENU_ENTRIES (optional)

_MENU_ENTRIES = table.create()

-- a _MENU_ENTRIES entry is defined as:
--
-- * required fields
--   ["name"] = name an dpath of the entry and its path as shown in the menu 
--     to the user. Start the name with one ore more '-'s to start a new group
--   ["invoke"] = a function that is called to invoke the action
--
-- * optional fields:
--   ["active"] =  a function that should return true or false. on false
--     the action will not be invoked and "grayed out" in menus. the function
--     is called every time before "invoke" is called and every time before
--     a menu gets visible
--   ["selected"] =  a function that should return true or false. when true
--     the entry will be marked as "selected option"
--
-- Placing menu entries:
--
-- You can place your entries in any context menu or any window menu in Renoise.
-- To to so, simply use one of the specified categories:
-- "Window Menu"
-- "Main Menu" (:File", ":Edit", ":View", ":Tools" or ":Help")
-- "Disk Browser Directories"
-- "Disk Browser Files"
-- "Instrument Box" 
-- "Instrument Box Samples" 
-- "Pattern Sequencer"
-- "Pattern Editor"
-- "Pattern Matrix"
-- "Pattern Matrix Header"
-- "Pattern Matrix",
-- "Sample Editor"
-- "Sample Editor Ruler"
-- "Mixer"
-- "Track DSPs Chain"
-- "Track DSPs Chain List"
-- "Automation" 
-- "Automation List"
-- "DSP Device"
-- "DSP Device Header"
-- "DSP Device Automation" 

_MENU_ENTRIES:insert {
  name = "Main Menu:Tools:Example Tool:Show Dialog",
  invoke = function() show_dialog() end
}

-- note: "show_status_message" is wrapped into a local function() below, 
-- because show_status_message is not yet know here. Its defined below...
_MENU_ENTRIES:insert {
  name = "Main Menu:Tools:Example Tool:Show Status Message",
  invoke = function() show_status_message() end
}

_MENU_ENTRIES:insert {
  name = "--- Main Menu:Tools:Example Tool:Enable Example Debug Prints",
  selected = function() return print_notifications end,
  invoke = function() print_notifications = not print_notifications end
}


-- _KEY_BINDINGS (optional)

_KEY_BINDINGS = table.create()

-- An _KEY_BINDINGS entry is defined as:
--
-- * required fields
--   ["name"] = the scope, name and category of the key binding
--   ["invoke"] = a function that is called as soon as the mapped key was pressed
--
-- You can define key mappings anywhere in Renoise where Renoise can place them.
-- Aka, you can use any of the categories that is listed in Renoises keyboard 
-- assigment preferences pane.
--
-- The key binding 'name' must have 3 parts, separated with :'s
-- <scope:topic_name:binding_name>
-- * 'scope' is where the shortcut will be applied, again just like you see them 
-- in the categories list in the keyboard assigment preferences pane
-- * 'topic_name' is useful to group multiple entries in the key assignemnt pane
-- use "tool" if you can not image something useful.
-- * 'binding_name' finally is the name of the binding
--
-- currently available scopes are:
-- "Global", "Automation", "Disk Browser", "Instrument Box", "Mixer", 
-- "Pattern Editor", "Pattern Matrix", "Pattern Sequencer", "Sample Editor"
-- "Track DSPs Chain"
--
-- Using a non avilable scope, will drive the shortcut useless. It will be 
-- listed, but can never be invoked.
-- Theres no way to define a default keyboard shortcut for your entry. Users 
-- manually have to bind them in the keyboard prefs pane. As soon as they did,
-- they get saved just like any other key binding in Renoise.

_KEY_BINDINGS:insert {
  name = "Global:Tools:Example Script Shortcut",
  invoke = function() show_key_binding_dialog() end
}


--------------------------------------------------------------------------------

-- _NOTIFICATIONS (optional)

-- optional list of notifications/events that the app forwards to
-- your tool script
_NOTIFICATIONS = {

  -- invoked, as soon as the application became the foreground window,
  -- for example when you alt-tab'ed to it, or switched with the mouse
  -- from another app to Renoise
  app_became_active = function()
    handle_app_became_active_notification()
  end,
  
  -- invoked, as soon as the application looses focus, another app
  -- became the foreground window
  app_resigned_active = function()
    handle_app_resigned_active_notification()
  end,
  
  -- invoked periodically in the background, more often when the work load
  -- is low. less often when Renoises work load is high.
  -- The exact interval is not defined and can not be relied on, but will be
  -- around 10 times per sec.
  -- You can do stuff in the background without blocking the application here.
  -- Be gentle and don't do CPU heavy stuff in your notifier!
  app_idle = function()
    handle_app_idle_notification()
  end,
  
  -- invoked each time a new document (song) was created or loaded
  app_new_document = function()
    handle_app_new_document_notification()
  end,
  
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
  auto_reload_debug = function()
    handle_auto_reload_debug_notification()
  end,
}



-------------------------------------------------------------------------------

-- global variables

-- set this to true, to print notification status to the console, to
-- see when which notifier gets called...
print_notifications = false

-- if you want to do something each time the script gets loaded, then
-- simply do it here, in the global namespace. The script will start running
-- as soon as Renoise started, and stop running as soon as it closes. 
-- IMPORTANT: this also means that there will be no song (yet) when this script 
-- initializes, so any access to app().current_document() or song() will fail 
-- here.
-- if you really need the song to initialize your application, do this in
-- the notifications.app_new_document functions or in your action callbacks...
if print_notifications then
  print("com.renoise.ExampleTool: script was loaded...")
end


-------------------------------------------------------------------------------

-- show_dialog

function show_dialog()
  renoise.app():show_warning(
    ("This example does nothing more beside showing a warning message " ..
     "and the current BPM, which has an amazing value of '%s'!"):format(
     renoise.song().transport.bpm)
  )
end


-- show_status_message

local status_message_count = 0

function show_status_message()
  status_message_count = status_message_count + 1

  renoise.app():show_status(
    ("com.renoise.ExampleTool: Status message no. %d..."):format(
     status_message_count)
  )
end


-- show_key_binding_dialog

function show_key_binding_dialog()
  renoise.app():show_prompt(
    "Congrats!",
    "You've pressed a magic keyboard combo "..
    "which was defined by a script example tool.",
    {"OK?"}
  )
end  


-------------------------------------------------------------------------------

-- implementation if the nofification callbacks, as used above...

-- handle_app_became_active_notification

function handle_app_became_active_notification()
  if print_notifications then
    print("com.renoise.ExampleTool: >> app_became_active notification")
  end
end


-- handle_app_resigned_active_notification

function handle_app_resigned_active_notification()
  if print_notifications then
    print("com.renoise.ExampleTool: << app_resigned_active notification")
  end
end


-- handle_app_idle_notification

local last_idle_time = os.clock()

function handle_app_idle_notification()
  if os.clock() - last_idle_time >= 10 then
    last_idle_time = os.clock()
      if print_notifications then
        print("com.renoise.ExampleTool: 10 second idle notification")
      end
   end
end


-- handle_app_new_document_notification

function handle_app_new_document_notification()
  if print_notifications then
    print("com.renoise.ExampleTool: !! app_new_document notification")
  end
end


-- handle_auto_reload_debug_notification

function handle_auto_reload_debug_notification()
  if print_notifications then
    print("com.renoise.ExampleTool: ** auto_reload_debug notification")
  end
end


--[[----------------------------------------------------------------------------
----------------------------------------------------------------------------]]--
