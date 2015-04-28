--[[============================================================================
Renoise Application API Reference
============================================================================]]--

--[[

This reference lists all available Lua functions and classes that control
the Renoise application. The Application is the Lua interface to Renoise's main
GUI and window (Application and ApplicationWindow).

Please read the INTRODUCTION first to get an overview about the complete
API, and scripting for Renoise in general...

Do not try to execute this file. It uses a .lua extension for markup only.

]]--


--------------------------------------------------------------------------------
-- renoise
--------------------------------------------------------------------------------

-------- Functions

renoise.app() 
  -> [renoise.Application object]


--------------------------------------------------------------------------------
-- renoise.Application
--------------------------------------------------------------------------------

-------- Functions

-- Shows an info message dialog to the user.
renoise.app():show_message(message)

-- Shows an error dialog to the user.
renoise.app():show_error(message)

-- Shows a warning dialog to the user.
renoise.app():show_warning(message)

-- Shows a message in Renoise's status bar to the user.
renoise.app():show_status(message)


-- Opens a modal dialog with a title, text and custom button labels.
renoise.app():show_prompt(title, message, {button_labels})
  -> [pressed_button_label]

-- Opens a modal dialog with a title, custom content and custom button labels.
-- See Renoise.ViewBuilder.API for more info. key_handler is an optional
-- notifier function for keyboard events in the dialog.
renoise.app():show_custom_prompt(title, content_view, {button_labels} [, key_handler])
  -> [pressed_button_label]

-- Shows a non modal dialog (a floating tool window) with custom content.
-- Again see Renoise.ViewBuilder.API for more info about custom views.
-- key_handler is an optional notifier function for keyboard events that are 
-- received by the dialog.
renoise.app():show_custom_dialog(title, content_view [, key_handler])
  -> [renoise.Dialog object]


-- Opens a modal dialog to query an existing directory from the user.
renoise.app():prompt_for_path(dialog_title)
  -> [valid path or empty string]

-- Opens a modal dialog to query a filename and path to read from a file.
-- The given extension(s) should be something  like {"wav", "aiff"
-- or "*" (any file) }
renoise.app():prompt_for_filename_to_read({file_extensions}, dialog_title)
  -> [filename or empty string]

-- Same as 'prompt_for_filename_to_read' but allows the user to select
-- more than one file.
renoise.app():prompt_for_multiple_filenames_to_read({file_extensions}, dialog_title)
  -> [list of filenames or empty list]

-- Open a modal dialog to get a filename and path for writing.
-- When an existing file is selected, the dialog will ask whether or not to 
-- overwrite it, so you don't have to take care of this on your own.
renoise.app():prompt_for_filename_to_write(file_extension, dialog_title)
  -> [filename or empty string]


-- Opens the default internet browser with the given URL. The URL can also be
-- a file that browsers can open (like xml, html files...).
renoise.app():open_url(url)
-- Opens the default file browser (explorer, finder...) with the given path.
renoise.app():open_path(file_path)


-- Install, update or uninstall a tool. Any errors are shown to the user 
-- during (un)installation. Installing an already existing tool will upgrade 
-- the tool without confirmation. Upgraded tools will automatically be
-- re-enabled, if necessary.
renoise.app().install_tool(file_path_to_xrnx)
renoise.app().uninstall_tool(file_path_to_xrnx)


-- Create a new song document (will ask the user to save changes if needed).
-- The song is not created immediately, but soon after the call was made and 
-- the user did not aborted the operation. In order to continue execution 
-- with the new song, attach a notifier to 'app_new_document_observable'
-- See renoise.ScriptingTool.API.lua for more info.
renoise.app():new_song()
renoise.app():new_song_no_template()

-- Load a new song document from the given filename (will ask to save
-- changes if needed, any errors are shown to the user).
-- Just like new_song(), the song is not loaded immediately, but soon after 
-- the call was made. See 'renoise.app():new_song()' for details.
renoise.app():load_song(filename)

-- Quicksave or save the current song under a new name. Any errors
-- during the export are shown to the user.
renoise.app():save_song()
renoise.app():save_song_as(filename)


-------- Properties

-- Access to the application's full log filename and path. Will already be opened 
-- for writing, but you nevertheless should be able to read from it.
renoise.app().log_filename
  -> [read-only, string]

-- Get the apps main document, the song. The global "renoise.song()" function 
-- is, in fact, a shortcut to this property.
renoise.app().current_song
  -> [read-only, renoise.Song object]

-- List of recently loaded/saved song files.
renoise.app().recently_loaded_song_files 
  -> [read-only, array of strings, filenames]
renoise.app().recently_saved_song_files 
  -> [read-only, array of strings, filenames]

-- Returns information about all currently installed tools.
renoise.app().installed_tools 
  -> [read-only, array of tables with tool info]

-- Globally used clipboard "slots" in the application.
renoise.app().active_clipboard_index 
  -> [number, 1-4]

-- Access to the application's window.
renoise.app().window 
  -> [read-only, renoise.ApplicationWindow object]


--------------------------------------------------------------------------------
-- renoise.ApplicationWindow
--------------------------------------------------------------------------------

-------- Constants

renoise.ApplicationWindow.UPPER_FRAME_TRACK_SCOPES
renoise.ApplicationWindow.UPPER_FRAME_MASTER_SPECTRUM

renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
renoise.ApplicationWindow.MIDDLE_FRAME_MIXER
renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_OVERVIEW
renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR
renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_KEYZONES
renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_MODULATION
renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EFFECTS
renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PLUGIN_EDITOR
renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_MIDI_EDITOR

renoise.ApplicationWindow.LOWER_FRAME_TRACK_DSPS
renoise.ApplicationWindow.LOWER_FRAME_TRACK_AUTOMATION

renoise.ApplicationWindow.MIXER_FADER_TYPE_24DB 
renoise.ApplicationWindow.MIXER_FADER_TYPE_48DB
renoise.ApplicationWindow.MIXER_FADER_TYPE_96DB
renoise.ApplicationWindow.MIXER_FADER_TYPE_LINEAR

-------- Functions

-- Expand the window over the entire screen, without hiding menu bars, 
-- docks and so on.
renoise.app().window:maximize()

-- Minimize the window to the dock or taskbar, depending on the OS.
renoise.app().window:minimize()

-- "un-maximize" or "un-minimize" the window, or just bring it to front.
renoise.app().window:restore()

-- Select/enable one of the global view presets, to memorize/restore
-- the user interface 'layout'.
renoise.app().window:select_preset(preset_index)


-------- Properties

-- Get/set if the application is running fullscreen.
renoise.app().window.fullscreen
  -> [boolean]

-- Window status flags.
renoise.app().window.is_maximized
  -> [read-only, boolean]
renoise.app().window.is_minimized
  -> [read-only, boolean]

-- When true, the middle frame views (like the pattern editor) will
-- stay focused unless alt or middle mouse is clicked.
renoise.app().window.lock_keyboard_focus
  -> [boolean]


-- Dialog for recording new samples, floating above the main window.
renoise.app().window.sample_record_dialog_is_visible
  -> [boolean]

-- Diskbrowser Panel.
renoise.app().window.disk_browser_is_visible, _observable
  -> [boolean]
  
-- InstrumentBox.
renoise.app().window.instrument_box_is_visible, _observable
  -> [boolean]

-- Instrument Editor detaching.
renoise.app().window.instrument_editor_is_detached, _observable
  -> [boolean]

-- Frame with the scopes/master spectrum...
renoise.app().window.upper_frame_is_visible, _observable
  -> [boolean]
renoise.app().window.active_upper_frame, _observable
  -> [enum = UPPER_FRAME]

-- Frame with the pattern editor, mixer...
renoise.app().window.active_middle_frame, _observable
  -> [enum = MIDDLE_FRAME]

-- Frame with the DSP chain view, automation, etc.
renoise.app().window.lower_frame_is_visible, _observable
  -> [boolean]
renoise.app().window.active_lower_frame, _observable
  -> [enum = LOWER_FRAME]


-- Pattern matrix, visible in pattern editor and mixer only...
renoise.app().window.pattern_matrix_is_visible, _observable
  -> [boolean]

-- Pattern advanced edit, visible in pattern editor only...
renoise.app().window.pattern_advanced_edit_is_visible, _observable
  -> [boolean]
  
-- Mixer views Pre/Post volume setting.
renoise.app().window.mixer_view_post_fx, _observable
  -> [boolean]  

-- Mixer fader type setting.
renoise.app().window.mixer_fader_type, _observable
  -> [enum=MIXER_FADER_TYPE_XXX]
  