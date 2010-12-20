--[[============================================================================
Renoise ScriptingTool API Reference
============================================================================]]--

--[[

This reference lists all available Lua functions and classes that are available
to Renoise XRNX "scripting tool" packages. The scripting tool interface allows
your tool to interact with Renoise by injecting or creating menu entries and
keybindings into Renoise; or by attaching it to some common tool related
notifiers.

Please read the INTRODUCTION first to get an overview about the complete
API, and scripting for Renoise in general...

Have a look at the com.renoise.ExampleTool.xrnx for more info about XRNX tools.

Do not try to execute this file. It uses a .lua extension for markup only.

]]--


--------------------------------------------------------------------------------
-- renoise
--------------------------------------------------------------------------------

-------- Functions

-- Access your tool's interface to Renoise. Only valid for XRNX tools.
renoise.tool()
  -> [renoise.ScriptingTool object]


--------------------------------------------------------------------------------
-- renoise.ScriptingTool
--------------------------------------------------------------------------------

-------- Functions

-- menu_entries: Insert a new menu entry somewhere in Renoise's existing
-- context menus or the global app menu. Insertion can be done during
-- script initialization, but can also be done dynamically later on.
--
-- The Lua table passed to 'add_menu_entry' is defined as:
--
-- * Required fields:
--   + ["name"] = Name and 'path' of the entry as shown in the global menus or
--       context menus to the user
--   + ["invoke"] = A function that is called as soon as the entry is clicked
--
-- * Optional fields:
--   + ["active"] = A function that should return true or false. When returning
--       false, the action will not be invoked and will be "greyed out" in
--       menus. This function is always called before "invoke", and every time
--       prior to a menu becoming visible.
--   + ["selected"] = A function that should return true or false. When
--       returning true, the entry will be marked as "this is a selected option"
--
-- Positioning entries:
--
-- You can place your entries in any context menu or any window menu in Renoise.
-- To do so, use one of the specified categories in its name:
--
-- + "Window Menu" -- Renoise icon menu in the window caption on Windows/Linux
-- + "Main Menu" (:File", ":Edit", ":View", ":Tools" or ":Help") -- Main menu
-- + "Scripting Menu" (:File",  or ":Tools") -- Scripting Editor & Terminal
-- + "Disk Browser Directories"
-- + "Disk Browser Files"
-- + "Instrument Box"
-- + "Instrument Box Samples"
-- + "Pattern Sequencer"
-- + "Pattern Editor"
-- + "Pattern Matrix"
-- + "Pattern Matrix Header"
-- + "Pattern Matrix",
-- + "Sample Editor"
-- + "Sample Editor Ruler"
-- + "Mixer"
-- + "Track DSPs Chain"
-- + "Track DSPs Chain List"
-- + "Track Automation"
-- + "Track Automation List"
-- + "DSP Device"
-- + "DSP Device Header"
-- + "DSP Device Automation"
--
-- Separating entries:
--
-- To divide entries into groups (separate entries with a line), prepend one or
-- more dashes to the name, like "--- Main Menu:Tools:My Tool Group Starts Here"

-- Returns true if the given entry already exists, otherwise false.
renoise.tool():has_menu_entry(menu_entry_name)
  -> [boolean]

-- Add a new menu entry as described above.
renoise.tool():add_menu_entry(menu_entry_definition_table)

-- Remove a previously added menu entry by specifying its full name.
renoise.tool():remove_menu_entry(menu_entry_name)


-- keybindings: Register key bindings somewhere in Renoise's existing
-- set of bindings.
--
-- The Lua table passed to add_keybinding is defined as:
--
-- * Required fields:
--   + ["name"] = The scope, name and category of the key binding.
--   + ["invoke"] = A function that is called as soon as the mapped key is
--       pressed. The callback has one argument: "repeated", indicating
--       if its a virtual key repeat.
--
-- The key binding's 'name' must have 3 parts, separated by ":" e.g.
-- [scope:topic_name:binding_name]
--
-- * 'scope' is where the shortcut will be applied, just like those
--    in the categories list for the keyboard assignment preference pane.
-- * 'topic_name' is useful when grouping entries in the key assignment pane.
--    Use "tool" if you can't come up with something meaningful.
-- * 'binding_name' is the name of the binding.
--
-- Currently available scopes are:
-- > "Global", "Automation", "Disk Browser", "Instrument Box", "Mixer",
-- > "Pattern Editor", "Pattern Matrix", "Pattern Sequencer", "Sample Editor"
-- > "Track DSPs Chain"
--
-- Using an unavailable scope will not fire an error, instead it will render the
-- binding useless. It will be listed and mappable, but never be invoked.
--
-- There's no way to define default keyboard shortcuts for your entries. Users
-- manually have to bind them in the keyboard prefs pane. As soon as they do,
-- they'll get saved just like any other key binding in Renoise.

-- Returns true when the given keybinging already exists, otherwise false.
renoise.tool():has_keybinding(keybinding_name)
  -> [boolean]

-- Add a new keybinding entry as described above.
renoise.tool():add_keybinding(keybinding_definition_table)

-- Remove a previously added key binding by specifying its name and path.
renoise.tool():remove_keybinding(keybinding_name)


--[[

midi_mappings: Extend Renoise's default MIDI mapping set, or add custom MIDI
mappings for your tools.

The Lua table passed to 'add_midi_mapping' is defined as:

* Required fields:
  + ["name"] = The group, name of the midi mapping; as visible to the user.
  + ["invoke"] = A function that is called to handle a bound MIDI message.

The mappings 'name' should have more than 1 part, separated by ":" e.g.
[topic_name:optional_sub_topic_name:name]

topic_name and optional sub group names will create new groups in the list
of MIDI mappings, as seen in Renoise's MIDI mapping dialog.
If you can't come up with a meaningful string, use your tool's name as the topic
name. Existing global mappings from Renoise can be overridden. In this case the
original mappings are no longer called, only your tool's mapping.

The "invoke" function gets called with one argument, the midi message, which
is modeled as:

    class "renoise.ScriptingTool.MidiMessage"
    
      -- returns if action should be invoked
      function is_trigger() -> boolean

      -- check which properties are valid
      function: is_switch() -> boolean
      function: is_rel_value() -> boolean
      function: is_abs_value() -> boolean

      -- [0 - 127] for abs values, [-63 - 63] for relative values
      -- valid when is_rel_value() or is_abs_value() returns true, else undefined
      property: int_value

      -- valid [true OR false] when :is_switch() returns true, else undefined
      property: boolean_value

A tool's MIDI mappings can be used just like the regular mappings in Renoise.
Either by manually looking up the mapping in the MIDI mapping
list, then binding it to a MIDI message, or when your tool has a custom GUI,
specifying the mapping via a control's "control.midi_mapping" property. Such
controls will get highlighted as soon as the MIDI mapping dialog is opened.
Then, users simply click on the highlighted control to map MIDI messages.

]]--

-- Returns true when the given mapping already exists, otherwise false.
renoise.tool():has_midi_mapping(midi_mapping_name)
  -> [boolean]

-- Add a new midi_mapping entry as described above.
renoise.tool():add_midi_mapping(midi_mapping_definition_table)

-- Remove a previously added midi mapping by specifying its name.
renoise.tool():remove_midi_mapping(midi_mapping_name)

--[[

Register a timer function or table with a function and context (a method)
that periodically gets called by the app_idle_observable for your tool.
Modal dialogs will avoid that timers are called. To create a one-shot timer,
simply call remove_timer at the end of your timer function. Timer_interval_in_ms
must be > 0. The exact interval your function is called will vary
a bit, depending on workload; e.g. when enough CPU time is available the
rounding error will be around +/- 5 ms

]]--

-- Returns true when the given function or method was registered as a timer.
renoise.tool():has_timer(function or {object, function} or {function, object})
  -> [boolean]

-- Add a new timer as described above.
renoise.tool():add_timer(function or {object, function} or {function, object},
  timer_interval_in_ms)

-- Remove a previously registered timer.
renoise.tool():remove_timer(timer_func)


-------- Properties

-- Full absolute path and name to your tool's bundle directory.
renoise.tool().bundle_path
  -> [read-only, string]

-- Invoked as soon as the application becomes the foreground window.
-- For example, when you ATL-TAB to it, or activate it with the mouse
-- from another app to Renoise.
renoise.tool().app_became_active_observable
  -> [renoise.Document.Observable object]

-- Invoked as soon as the application looses focus and another app
-- becomes the foreground window.
renoise.tool().app_resigned_active_observable
  -> [renoise.Document.Observable object]

-- Invoked periodically in the background, more often when the work load
-- is low, less often when Renoise's work load is high.
-- The exact interval is undefined and can not be relied on, but will be
-- around 10 times per sec.
-- You can do stuff in the background without blocking the application here.
-- Be gentle and don't do CPU heavy stuff here please!
renoise.tool().app_idle_observable
  -> [renoise.Document.Observable object]

-- Invoked each time before a new document gets created or loaded, aka the last
-- time renoise.song() still points to the old song before a new one arrives.
-- You can explicitly release notifiers to the old document here, or do your own
-- housekeeping. Also called right before the application exits.
renoise.tool().app_release_document_observable
  -> [renoise.Document.Observable object]

-- Invoked each time a new document (song) is created or loaded, aka each time
-- the result of renoise.song() is changed. Also called when the script gets
-- reloaded (only happens with the auto_reload debugging tools), in order
-- to connect the new script instance to the already running document.
renoise.tool().app_new_document_observable
  -> [renoise.Document.Observable object]

-- invoked each time the app's document (song) is successfully saved.
-- renoise.song().file_name will point to the filename that it was saved to.
renoise.tool().app_saved_document_observable
  -> [renoise.Document.Observable object]

--[[

Get or set an optional renoise.Document.DocumentNode object, which will be
used as set of persistent "options" or preferences for your tool.
By default nil. When set, the assigned document object will automatically be
loaded and saved by Renoise, to retain the tools state.
The preference XML file is saved/loaded within the tool bundle as
"com.example.your_tool.xrnx/preferences.xml".

A simple example:

    -- create a document first
    my_options = renoise.Document.create("ScriptingToolPreferences") {
     some_option = true,
     some_value = "string_value"
    }

Or:

    class "ExampleToolPreferences"(renoise.Document.DocumentNode)

      function ExampleToolPreferences:__init()
        renoise.Document.DocumentNode.__init(self)
        self:add_property("some_option", true)
        self:add_property("some_value", "string_value")
      end

      my_options = ExampleToolPreferences()

      -- values can be accessed (read, written) via
      my_options.some_option.value, my_options.some_value.value

      -- also notifiers can be added to listen to changes to the values
      -- done by you, or after new values got loaded or a view changed the value:
      my_options.some_option:add_notifier(function() end)

]]--

-- Please see Renoise.Document.API for more info about renoise.DocumentNode
-- and for info on Documents in general.
renoise.tool().preferences
  -> [renoise.Document.DocumentNode object or nil]

