--[[============================================================================
Renoise Application API Reference
============================================================================]]--

--[[

This reference lists all available Lua functions and classes that control
the Renoise application. The Application is the Lua interface to Renoise's main
GUI and window (Application and ApplicationWindow).

Please read the INTRODUCTION.txt first to get an overview about the complete
API, and scripting in Renoise in general...

Do not try to execute this file. It uses a .lua extension for markups only.

]]


--------------------------------------------------------------------------------
-- renoise
--------------------------------------------------------------------------------

-------- functions

renoise.app() 
  -> [renoise.Application object]


--------------------------------------------------------------------------------
-- renoise.Application
--------------------------------------------------------------------------------

-------- functions

-- shows an info message dialog to the user
[added B4] renoise.app():show_message(message)

-- shows an error dialog to the user
renoise.app():show_error(message)

-- shows a warning dialog to the user
renoise.app():show_warning(message)

-- shows a message in Renoise's status bar to the user
renoise.app():show_status(message)

-- opens a modal dialog with a title, text and custom button labels
renoise.app():show_prompt(title, message, {button_labels})
  -> [pressed_button_label]

-- opens a modal dialog with a title, a custom content and custom button labels.
-- see Renoise.ViewBuilder.API.txt for more info. key_handler is an optional
-- notifier function for keyboard events in the dialog
renoise.app():show_custom_prompt(title, content_view, {button_labels} [, key_handler])
  -> [pressed_button_label]

-- shows a non modal dialog (a floating tool window) with custom content.
-- again see Renoise.ViewBuilder.API.txt. key_handler is an optional notifier
-- function for keyboard events in the dialog
renoise.app():show_custom_dialog(title, content_view [, key_handler])
  -> [renoise.Dialog object]


-- opens a modal dialog to query a filename and path to read from a file.
-- the given extension(s) should be something  like {"wav", "aiff"
-- or "*" (any file) }
renoise.app():prompt_for_filename_to_read({file_extensions}, dialog_title)
  -> [filename or empty string]

-- same as 'prompt_for_filename_to_read' but allows the user to select
-- more than one file
renoise.app():prompt_for_multiple_filenames_to_read({file_extensions}, dialog_title)
  -> [list of filenames or empty list]

-- open a modal dialog to get a filename and path for writing a file.
-- when an existing file was selected, the dialog will ask to overwrite it,
-- so you don't have to take of this by your own
renoise.app():prompt_for_filename_to_write(file_extension, dialog_title)
  -> [filename or empty string]

-- opens the default internet browser with the given url. url can also be
-- a file that browsers can open (like xml, html files...)
renoise.app():open_url(url)
-- opens the default file browser (explorer, finder...) with the given path.
-- passing file names instead of paths is undefined (will change from OS to OS)
renoise.app():open_path(file_path)


-- create a new song document (will ask the user to save changes if needed)
renoise.app():new_song()
renoise.app():new_song_no_template()

-- load a new song document from the given filename (will ask to save
-- changes if needed, any errors are shown to the user)
renoise.app():load_song(filename)

-- quicksave or save the current song under a new name, errors are shown
-- to the user
renoise.app():save_song()
renoise.app():save_song_as(filename)


-------- properties

-- access to the applications full log filename and path. will already be opened 
-- for writing, but you neverthless should be able to read from it
renoise.app().log_filename
  -> [string]

-- get the apps song document. the global "renoise.song()" function is actually
-- just a shortcut for renoise.app().current_song
renoise.app().current_song
  -> [renoise.Song object]

-- list of recently loaded/saved song files
renoise.app().recently_loaded_song_files 
  -> [array of strings, filenames]
renoise.app().recently_saved_song_files 
  -> [array of strings, filenames]

-- globally used clipboard "slots" in the application
renoise.app().active_clipboard_index 
  -> [number, 1-4]

-- access to the application window
renoise.app().window 
  -> [read-only, renoise.ApplicationWindow object]


--------------------------------------------------------------------------------
-- renoise.ApplicationWindow
--------------------------------------------------------------------------------

-------- consts

renoise.ApplicationWindow.UPPER_FRAME_DISK_BROWSER
renoise.ApplicationWindow.UPPER_FRAME_TRACK_SCOPES
renoise.ApplicationWindow.UPPER_FRAME_MASTER_SCOPES
renoise.ApplicationWindow.UPPER_FRAME_MASTER_SPECTRUM

renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR
renoise.ApplicationWindow.MIDDLE_FRAME_MIXER
renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_EDITOR
renoise.ApplicationWindow.MIDDLE_FRAME_SAMPLE_EDITOR

renoise.ApplicationWindow.LOWER_FRAME_TRACK_DSPS
renoise.ApplicationWindow.LOWER_FRAME_TRACK_AUTOMATION
renoise.ApplicationWindow.LOWER_FRAME_INSTRUMENT_PROPERTIES
renoise.ApplicationWindow.LOWER_FRAME_SONG_PROPERTIES


-------- functions

renoise.app().window:maximize()
renoise.app().window:minimize()

-- aka "un-maximize"
renoise.app().window:restore()

-- select/enable one of the global view presets, to memorize/restore
-- the user interface 'layout'
renoise.app().window:select_preset(preset_index)


-------- properties

renoise.app().window.fullscreen
  -> [boolean]

renoise.app().window.is_maximized
  -> [read-only, boolean]
renoise.app().window.is_minimized
  -> [read-only, boolean]

-- when true, the middle frame views (like the pattern editor) will
-- stay focused unless alt or middle mouse clicked...
renoise.app().window.lock_keyboard_focus
  -> [boolean]


-- dialog for recording new samples, floating above the main window
renoise.app().window.sample_record_dialog_is_visible
  -> [boolean]


-- frame with the transport, diskbrowser, instrument box...
renoise.app().window.upper_frame_is_visible, _observable
  -> [boolean]
renoise.app().window.active_upper_frame, _observable
  -> [enum = UPPER_FRAME]

-- frame with the pattern editor, mixer...
renoise.app().window.active_middle_frame, _observable
  -> [enum = MIDDLE_FRAME]

-- frame with the dsp chain view, automation...
renoise.app().window.lower_frame_is_visible, _observable
  -> [boolean]
renoise.app().window.active_lower_frame, _observable
  -> [enum = LOWER_FRAME]


-- pattern matrix, visible in pattern editor and mixer only...
renoise.app().window.pattern_matrix_is_visible, _observable
  -> [boolean]

-- pattern advanced edit, visible in pattern editor only...
renoise.app().window.pattern_advanced_edit_is_visible, _observable
  -> [boolean]

