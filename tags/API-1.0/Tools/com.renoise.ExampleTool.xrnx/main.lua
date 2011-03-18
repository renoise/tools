--[[============================================================================
com.renoise.ExampleTool.xrnx/main.lua
============================================================================]]--

-- XRNX Bundle Layout:

-- Tool scripts must describe themself through a manifest XML, to let Renoise
-- know which API version it relies on, what "it can do" and so on, without 
-- actually loading it. See "manifest.xml" in this exampel tool for more info 
-- please
--
-- When the manifest loads and looks OK, the main file of the tool will be 
-- loaded. This  is this file -> "main.lua".
--
-- You can load other files from here via LUAs 'require', or simply put
-- all the code in here. This file simply is the main entry point of your tool. 
-- While initializing, you can register your tool with Renoise, by creating 
-- keybindings, menu entries or listening to events from the application. 
-- We will describe all this below now:

 
--------------------------------------------------------------------------------
-- preferences
--------------------------------------------------------------------------------

-- tools can have preferences, just like Renoise. To use them we first need 
-- to create a renoise.Document object which holds the options that we want to 
-- store/restore
local options = renoise.Document.create("ExampleToolPreferences") {
  show_debug_prints = false
}

-- then we simply register this document as the main preferences for the tool:
renoise.tool().preferences = options

-- show_debug_prints is now a persistent option which gets saved & restored 
-- for upcoming Renoise seesions, program launches. 
-- the preferences file for tools is saved inside the tools bundle as 
-- "preferences.xml"

-- for more complex documents, or if you prefere doing things the OO way, you can
-- also inherit from renoise.Document.DocumentNode and register properties there:
--
class "ExampleToolPreferences"(renoise.Document.DocumentNode)

function ExampleToolPreferences:__init()
  renoise.Document.DocumentNode.__init(self)
  
  -- register an observable property "show_debug_prints" which also will be 
  -- loaded/saved with the document
  self:add_property("show_debug_prints", false)
end

local options = ExampleToolPreferences()
renoise.tool().preferences = options

-- which also allows you to create more complex documents.
-- please have a look at the Renoise.Tool.API.txt for more info and details 
-- about documents and what else you can load/store this way...

  
--------------------------------------------------------------------------------
-- menu entries
--------------------------------------------------------------------------------

-- you can add new menu entries into any existing context menues or the global 
-- menu in Renoise. to do so, we are using the tool's add_menu_entry function.
-- Please have a look at "Renoise.ScriptingTool.API.txt" i nthe documentation 
-- folder for a complete reference.
--
-- Note: all "invoke" functions here are wrapped into a local function(), 
-- because the functions, variables that are used are not yet know here. 
-- They are defined below, later in this file...

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Example Tool:Enable Example Debug Prints",
  selected = function() return options.show_debug_prints.value end,
  invoke = function() 
    options.show_debug_prints.value = not options.show_debug_prints.value 
  end
}

renoise.tool():add_menu_entry {
  name = "--- Main Menu:Tools:Example Tool:Show Dialog...",
  invoke = function() 
    show_dialog() 
  end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Example Tool:Show Status Message",
  invoke = function() 
    show_status_message() 
  end
}

renoise.tool():add_menu_entry {
  name = "--- Main Menu:Tools:Example Tool:Add New Entry",
  invoke = function() 
    insert_another_menu_entry() 
  end 
}


renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Example Tool:Remove Entry",
  active = function() 
    return can_remove_menu_entry() 
  end,
  invoke = function() 
    remove_menu_entry() 
  end
}


--------------------------------------------------------------------------------
-- key bindings
--------------------------------------------------------------------------------

-- you can also define keybindings for your script, which will be activated and 
-- mapped by the user just as any other key binding in Renoise.
-- Keybindings can be global (apploied everywhere in the GUI) or can be local 
-- to a specific part of the GUI, liek the Pattern Editor.
--
-- Again, have a look at "Renoise.ScriptingTool.API.txt" in the documentation 
-- folder for a complete reference.

renoise.tool():add_keybinding {
  name = "Global:Tools:Example Script Shortcut",
  invoke = function(repeated)
    if (not repeated) then -- we ignore soft repeated keys here
      renoise.app():show_prompt(
        "Congrats!",
        "You've pressed a magic keyboard combo "..
        "which was defined by a script example tool.",
        {"OK?"}
      )
    end
  end
}


--------------------------------------------------------------------------------
-- midi mappings
--------------------------------------------------------------------------------

-- Tools also can extend Renoises internal MIDI mapping set. This way you can 
-- add MIDI mappings to control your tool, or also write tools which do nothing
-- more than extending Renoises default MIDI mapping set.
--
-- Have a look at "Renoise.ScriptingTool.API.txt" in the documentation 
-- folder for a complete reference. Also have a look at the GlobalMidiActions.lua
-- file for examples mappings (this is Renoises complete default MIDI mapping set) 
-- and more descriptions of the passed message parameter.

renoise.tool():add_midi_mapping{
  name = "com.renoise.ExampleTool:Example MIDI Mapping",
  invoke = function(message)
    if (options.show_debug_prints.value) then
      print("com.renoise.ExampleTool: >> got midi_mapping message :")
      
      print(("  message:is_trigger(): %s)"):format(
        message:is_trigger() and "yes" or "no"))
      print(("  message:is_switch(): %s)"):format(
        message:is_switch() and "yes" or "no"))
      print(("  message:is_rel_value(): %s)"):format(
        message:is_rel_value() and "yes" or "no"))
      print(("  message:is_abs_value(): %s)"):format(
        message:is_abs_value() and "yes" or "no"))
      
      print(("  message.int_value: %d)"):format(
        message.int_value))
      print(("  message.boolean_value: %s)"):format(
        message.boolean_value and "true" or "false"))
    end
  end
}


--------------------------------------------------------------------------------
-- notifications
--------------------------------------------------------------------------------

-- You can attach and detach from a set of script related notifications at any 
-- time. Please see renoise.Document.API.txt -> Observable for more info

-- Invoked, as soon as the application became the foreground window,
-- for example when you alt-tab'ed to it, or switched with the mouse
-- from another app to Renoise.
renoise.tool().app_became_active_observable:add_notifier(function()
 handle_app_became_active_notification()
end)
  
-- Invoked, as soon as the application looses focus, another app
-- became the foreground window.
renoise.tool().app_resigned_active_observable:add_notifier(function()
  handle_app_resigned_active_notification()
end)
  
-- Invoked periodically in the background, more often when the work load
-- is low. less often when Renoises work load is high.
-- The exact interval is not defined and can not be relied on, but will be
-- around 10 times per sec.
-- You can do stuff in the background without blocking the application here.
-- Be gentle and don't do CPU heavy stuff in your notifier!
renoise.tool().app_idle_observable:add_notifier(function()
  handle_app_idle_notification()
end)
  
-- Invoked right before a document (song) gets replaced with a new one. The old 
-- document is still valid here.
renoise.tool().app_release_document_observable:add_notifier(function()
  handle_app_release_document_notification()
end)

-- Invoked each time a new document (song) was created or loaded.
renoise.tool().app_new_document_observable:add_notifier(function()
  handle_app_new_document_notification()
end)

-- Invoked each time the apps document (song) was successfully saved.
renoise.tool().app_saved_document_observable:add_notifier(function()
  handle_app_saved_document_notification()
end)


--------------------------------------------------------------------------------
-- debug hook
--------------------------------------------------------------------------------

-- This hook helps you testing & debugging your script while editing
-- it with an external editor or with Renoises built in script editor:
--
-- As soon as you save your script outside of the application, and then
-- focus the app (alt-tab to it for example), your script will get instantly
-- reloaded and your notifier is called.
-- You can put a test function into this notifier, or attach to a remote
-- debugger like RemDebug or simply nothing, just enable the auto-reload
-- functionality by setting _AUTO_RELOAD_DEBUG = true .
--
-- When editing script with Renoises built in editor, tools will automatically
-- reload as soon as you hit "Run Script", even if you don't have this notifier
-- set, but you nevertheless can use this to automatically invoke a test
-- function.
---
-- Note: When reloading the script causes an error, the old, last running
-- script instance will continue to run.
--
-- Finally: Changes in the actions menu may not be updated for new tools, 
-- unless you reload all tools manually with 'Reload Tools' in the menu.

_AUTO_RELOAD_DEBUG = function()
  handle_auto_reload_debug_notification()
end

-- or _AUTO_RELOAD_DEBUG = true


--------------------------------------------------------------------------------
-- global variables
--------------------------------------------------------------------------------

-- if you want to do something, each time the script gets loaded, then
-- simply do it here, in the global namespace when your tool gets loaded. 
-- The script will start running as soon as Renoise started, and stop running 
-- as soon as it closes. 
--
-- IMPORTANT: this also means that there will be no song (yet) when this script 
-- initializes, so any access to app().current_document() or song() will fail 
-- here.
-- If you really need the song to initialize your application, do this in
-- the notifications.app_new_document functions or in your action callbacks...

if (options.show_debug_prints.value) then
  print("com.renoise.ExampleTool: script was loaded...")
end


--------------------------------------------------------------------------------
-- functions
--------------------------------------------------------------------------------

-- show_dialog

function show_dialog()
  renoise.app():show_warning(
    ("This example does nothing more beside showing a warning message " ..
     "and the current BPM, which has an amazing value of '%s'!"):format(
     renoise.song().transport.bpm)
  )
end


--------------------------------------------------------------------------------

-- show_status_message

local status_message_count = 0

function show_status_message()
  status_message_count = status_message_count + 1

  renoise.app():show_status(
    ("com.renoise.ExampleTool: Showing status message no. %d..."):format(
     status_message_count)
  )
end


--------------------------------------------------------------------------------

-- insert_another_menu_entry

-- menu entries and keybindings can also be added on the fly. Here is a simply
-- example which does so:

local num_added_entries = 0

function insert_another_menu_entry() 
  num_added_entries = num_added_entries + 1
    
  local entry_name = ("Main Menu:Tools:Example Tool:New Entry %d"):format(
    num_added_entries)
  
  renoise.tool():add_menu_entry {
    name = entry_name,
    invoke = function() 
      renoise.app():show_status(
        ("New Entry %s was pressed..."):format(num_added_entries)) 
    end
  }
end

  
--------------------------------------------------------------------------------

-- can_remove_menu_entry

function can_remove_menu_entry() 
  return (num_added_entries > 0)
end


--------------------------------------------------------------------------------

-- remove_menu_entry

function remove_menu_entry() 
  assert(can_remove_menu_entry(), "entry should not be invoked")
  
  renoise.tool():remove_menu_entry(
    ("Main Menu:Tools:Example Tool:New Entry %d"):format(
     num_added_entries)) 
  
  num_added_entries = num_added_entries - 1
end


--------------------------------------------------------------------------------

-- implementation if the nofification callbacks, as attached above...

-- handle_app_became_active_notification

function handle_app_became_active_notification()
  if (options.show_debug_prints.value) then
    print("com.renoise.ExampleTool: >> app_became_active notification")
  end
end


-- handle_app_resigned_active_notification

function handle_app_resigned_active_notification()
  if (options.show_debug_prints.value) then
    print("com.renoise.ExampleTool: << app_resigned_active notification")
  end
end


-- handle_app_idle_notification

local last_idle_time = os.clock()

function handle_app_idle_notification()
  if os.clock() - last_idle_time >= 10 then
    last_idle_time = os.clock()
      if (options.show_debug_prints.value) then
        print("com.renoise.ExampleTool: 10 second idle notification")
      end
   end
end


-- handle_app_release_document_notification

function handle_app_release_document_notification()
  if (options.show_debug_prints.value) then
    print("com.renoise.ExampleTool: !! app_release_document notification")
  end
end


-- handle_app_new_document_notification

function handle_app_new_document_notification()
  if (options.show_debug_prints.value) then
    print("com.renoise.ExampleTool: !! app_new_document notification")
  end
end


-- handle_app_saved_document_notification

function handle_app_saved_document_notification()
  if (options.show_debug_prints.value) then
    print(("com.renoise.ExampleTool: !! handle_app_saved_document "..
      "notification (filename: '%s')"):format(renoise.song().file_name))
  end
end


-- handle_auto_reload_debug_notification

function handle_auto_reload_debug_notification()
  if (options.show_debug_prints.value) then
    print("com.renoise.ExampleTool: ** auto_reload_debug notification")
  end
end
