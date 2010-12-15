--[[============================================================================
Renoise ScriptingTool API Reference
============================================================================]]--

--[[

This reference lists all available Lua functions and classes that are available
to Renoise xrnx scripting tools only. The scripting tool interface allows
your tool to interact with Renoise by injecting, creating menu entries or 
keybindings into Renoise; or by attaching to some common tool related notifiers.

Please read the INTRODUCTION.txt first to get an overview about the complete
API, and scripting for Renoise in general...

Have a look at the com.renoise.ExampleTool.xrnx for more info about XRNX tools.

Do not try to execute this file. It uses a .lua extension for markup only.

]]


--------------------------------------------------------------------------------
-- renoise
--------------------------------------------------------------------------------

-------- Functions

-- access to your tools interface to Renoise. only valid for xrnx tools
renoise.tool() 
  -> [renoise.ScriptingTool object]


--------------------------------------------------------------------------------
-- renoise.ScriptingTool
--------------------------------------------------------------------------------

-------- Functions

-- menu_entries: insert a new menu entry somewhere in Renoises existing 
-- context menus or the global app menu. insertion can be done while 
-- the script is initializing, but also dynamically later on.
--
-- The table passed as argument to 'add_menu_entry' is defined as:
--
-- * required fields
--   ["name"] = name and 'path' of the entry as shown in the global menus or 
--     context menus to the user
--   ["invoke"] = a function that is called as soon as the entry was clicked
--
-- * optional fields:
--   ["active"] = a function that should return true or false. when returning 
--     false, the action will not be invoked and "grayed out" in menus. This 
--     function is called every time before "invoke" is called and every time 
--     before a menu gets visible.
--   ["selected"] = a function that should return true or false. when returning
--     true, the entry will be marked as "this is a selected option"
--
-- Placing entries:
--
-- You can place your entries in any context menu or any window menu in Renoise.
-- To do so, use one of the specified categories in its name:
--
-- "Window Menu" -- Renoise icon menu in the window caption on Windows/Linux
-- "Main Menu" (:File", ":Edit", ":View", ":Tools" or ":Help") -- Main menu
-- "Scripting Menu" (:File",  or ":Tools") -- Scripting Editor & Terminal
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
-- "Track Automation" 
-- "Track Automation List"
-- "DSP Device"
-- "DSP Device Header"
-- "DSP Device Automation" 
--
-- Separating entries:
-- 
-- To divide entries into groups (separate entries with a line), prepend one or 
-- more dashes to the name, like "--- Main Menu:Tools:My Tool Group Starts Here"

-- returns true when the given entry was already added, else false
renoise.tool():has_menu_entry(menu_entry_name)
  -> [boolean]

-- add a new menu entry as described above
renoise.tool():add_menu_entry(menu_entry_definition_table)

-- remove a previously added menu entry by specifying its full name
renoise.tool():remove_menu_entry(menu_entry_name)


-- keybindings: register key bindings somewhere in Renoises existing 
-- set of bindings.
--
-- The table passed as argument to add_keybinding is defined as:
--
-- * required fields
--   ["name"] = the scope, name and category of the key binding
--   ["invoke"] = a function that is called as soon as the mapped key was 
--     pressed. The callback has one argument: "repeated", indicating
--     if its a virtual key repeat.
--
-- The key binding's 'name' must have 3 parts, separated with :'s
-- <scope:topic_name:binding_name>
-- * 'scope' is where the shortcut will be applied, just like you see them 
--   in the categories list in the keyboard assignment preferences pane
-- * 'topic_name' is useful to group entries in the key assignment pane.
--   use "tool" if you can not come up with something useful.
-- * 'binding_name' is the name of the binding
--
-- currently available scopes are:
-- "Global", "Automation", "Disk Browser", "Instrument Box", "Mixer", 
-- "Pattern Editor", "Pattern Matrix", "Pattern Sequencer", "Sample Editor"
-- "Track DSPs Chain"
--
-- Using a non available scope will not fire an error but only drive the binding
-- useless. It will be listed and can be mapped, but will never be invoked.
--
-- Theres no way to define default keyboard shortcuts for your entries. Users 
-- manually have to bind them in the keyboard prefs pane. As soon as they did,
-- they get saved just like any other key binding in Renoise.

-- returns true when the given entry was already added, else false
renoise.tool():has_keybinding(keybinding_name)
  -> [boolean]

-- add a new keybinding entry as described above
renoise.tool():add_keybinding(keybinding_definition_table)

-- remove a previously added key binding by specifying its name and path 
renoise.tool():remove_keybinding(keybinding_name)


-- midi_mappings: extend Renoises default MIDI mapping set with tools,
-- or add custom MIDI mappings for your tools.
--
-- The table passed as argument to 'add_midi_mapping' is defined as:
-- * required fields
--   ["name"] = the group, name of the midi mapping, as visible to the user
--   ["invoke"] = a function that is called to handle bound MIDI message
--
-- The mappings 'name' should have more than 1 parts, separated with :'s
-- <topic_name:optional_sub_topic_name:name>
-- topic_name and optional sub group names will create new groups in the list 
-- of MIDI mappings, as seen in Renoises MIDI mapping dialog.
-- If you can't come up with something useful, use your tools name as topic name.
-- Existing global mappings from Renoise can be overridden. In this case the original 
-- mapping is no longer called, but only your tools mapping.
--
-- The "invoke" function gets called with one argument, the midi message, which 
-- is a:
--
-- class "renoise.ScriptingTool.MidiMessage"
--   -- returns if action should be invoked
--   function is_trigger() -> boolean
--
--   -- check which properties are valid
--   function: is_switch() -> boolean
--   function: is_rel_value() -> boolean
--   function: is_abs_value() -> boolean
--
--   -- [0 - 127] for abs values, [-63 - 63] for relative values
--   -- valid when is_rel_value() or is_abs_value() returns true, else undefined
--   property: int_value
--
--   -- valid [true OR false] when :is_switch() returns true, else undefined
--   property: boolean_value
--
-- MIDI mappings which are defined by tools, can be used just like the regular 
-- ones in Renoise: Either manually lookup the mapping in the MIDI mapping dialogs
-- list, then bind it to a MIDI message, or, when your tool has a custom GUI, 
-- specify the mapping via a controls "control.midi_mapping" property. Such controls
-- will get highlighted as soon as the MIDI mapping dialog gets opened. Then users
-- only have to click on the highlighted control to map MIDI messages.

-- returns true when the given mapping was already added, else false
renoise.tool():has_midi_mapping(midi_mapping_name)
  -> [boolean]

-- add a new midi_mapping entry as described above
renoise.tool():add_midi_mapping(midi_mapping_definition_table)

-- remove a previously added midi mapping by specifying its name
renoise.tool():remove_midi_mapping(midi_mapping_name)


-- register a timer function or table with function and context (a method) 
-- which gets periodically called with the app_idle_observable for your tool. 
-- modal dialogs will avoid that timers are called. to create a one-shot timer,
-- simply remove the timer again in your timer function. timer_interval_in_ms 
-- must be > 0. the exact interval your function will be called with, will vary
-- a bit, depending on the workload. when enough CPU time is available its error
-- will be around +- 5 ms

-- returns true when the given function or method was registered as timer
renoise.tool():has_timer(function or {object, function} or {function, object})
  -> [boolean]

renoise.tool():add_timer(function or {object, function} or {function, object}, 
  timer_interval_in_ms)

-- remove a previously registered timer
renoise.tool():remove_timer(timer_func)


-------- Properties

-- full abs path and name of your tools bundle directory
renoise.tool().bundle_path
  -> [read-only, string]

-- invoked, as soon as the application became the foreground window,
-- for example when you alt-tab'ed to it, or switched with the mouse
-- from another app to Renoise
renoise.tool().app_became_active_observable
  -> [renoise.Document.Observable object]
  
-- invoked, as soon as the application looses focus, another app
-- became the foreground window 
renoise.tool().app_resigned_active_observable
  -> [renoise.Document.Observable object]

-- invoked periodically in the background, more often when the work load
-- is low, less often when Renoises work load is high.
-- The exact interval is not defined and can not be relied on, but will be
-- around 10 times per sec.
-- You can do stuff in the background without blocking the application here.
-- Be gentle and don't do CPU heavy stuff here please!
renoise.tool().app_idle_observable
  -> [renoise.Document.Observable object]

-- invoked each time before a new document gets created or loaded, aka the last 
-- time renoise.song() still points to the old song before a new one arrives.
-- you can explicitly release notifiers to the old document here, or do some own
-- housekeeping. also called right before the application exits.
renoise.tool().app_release_document_observable
  -> [renoise.Document.Observable object]

-- invoked each time a new document (song) was created or loaded, aka each time
-- the result of renoise.song() has changed. also called when the script gets
-- reloaded (only happens with the auto_reload debugging tools), in order 
-- to connect the new script instance to the already running document.
renoise.tool().app_new_document_observable
  -> [renoise.Document.Observable object]

-- invoked each time the apps document (song) got successfully saved. 
-- renoise.song().file_name will point to the filename it got saved to.
renoise.tool().app_saved_document_observable
  -> [renoise.Document.Observable object]

-- get or set an optional renoise.Document.DocumentNode object, which will be
-- used as set of persistent "options" or preferences for your tool. 
-- by default nil. when set, the assigned document object will be automatically 
-- loaded and saved by Renoise, in order to retain the tools state.
-- the preference xml file is saved/loaded within the tool bundle as 
-- "com.example.your_tool.xrnx/preferences.xml".
--
-- a simple example:
-- -- create a document first
-- my_options = renoise.Document.create("ScriptingToolPreferences") { 
--  some_option = true, 
--  some_value = "string_value"
-- }
--
-- OR
--
-- class "ExampleToolPreferences"(renoise.Document.DocumentNode)
-- function ExampleToolPreferences:__init()
--   renoise.Document.DocumentNode.__init(self)
--   self:add_property("some_option", true)
--   self:add_property("some_value", "string_value")
-- end
--
-- my_options = ExampleToolPreferences()
--
-- -- values can be accessed (read, written) via 
-- my_options.some_option.value, my_options.some_value.value
--
-- -- also notifiers can be added to listen to changes to the values
-- -- done by you, or after new values got loaded or a view changed the value:
-- my_options.some_option:add_notifier(function() end)
--
-- please see Renoise.Document.API.txt for more info about renoise.DocumentNode
-- and documents in the Renoise API in general.
renoise.tool().preferences
  -> [renoise.Document.DocumentNode object or nil]
    
