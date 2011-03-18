--[[============================================================================
Renoise Song API Reference
============================================================================]]--

--[[

This reference lists all available Lua functions and classes that control
Renoise's main document - the song - and the corresponding components such as
Instruments, Tracks, Patterns, and so on.

Please read the INTRODUCTION first to get an overview about the complete
API, and scripting for Renoise in general...

Do not try to execute this file. It uses a .lua extension for markup only.

]]--


--------------------------------------------------------------------------------
-- renoise
--------------------------------------------------------------------------------

-------- Functions

-- Access to the one and only loaded song in the app. Always valid after the
-- application is initialized. NOT valid when called from the XRNX globals while
-- a tool is still initializing; XRNX tools are initialized before the initial
-- song is created.
renoise.song()
  -> [renoise.Song object or nil]


--------------------------------------------------------------------------------
-- renoise.SongPos
--------------------------------------------------------------------------------

-- Helper class used in Transport and Song, representing a position in the song.

-------- Properties

-- Position in the pattern sequence.
song_pos.sequence
  -> [number]

-- Position in the pattern at the given pattern sequence.
song_pos.line
  -> [number]


-------- Operators

==(song_pos, song_pos) -> [boolean]
~=(song_pos, song_pos) -> [boolean]
>(song_pos, song_pos) -> [boolean]
>=(song_pos, song_pos) -> [boolean]
<(song_pos, song_pos) -> [boolean]
<=(song_pos, song_pos) -> [boolean]


--------------------------------------------------------------------------------
-- renoise.Song
--------------------------------------------------------------------------------

-------- Functions

-- Test if something in the song can be undone.
renoise.song():can_undo()
  -> [boolean]

-- Undo the last performed action. Will do nothing if nothing can be undone.
renoise.song():undo()

-- Test if something in the song can be redone.
renoise.song():can_redo()
  -> [boolean]

-- Redo a previously undo action. Will do nothing if nothing can be redone.
renoise.song():redo()

-- When modifying the song, Renoise will automatically add descriptions for
-- undo/redo by looking at what first changed (a track was inserted, a pattern
-- line changed, and so on). When the song is changed from an action in a menu
-- entry callback, the menu entry's label will automatically be used for the
-- undo description.
-- If those auto-generated names do not work for you, or you want  to use
-- something more descriptive, you can (!before changing anything in the song!)
-- give your changes a custom undo description (like: "Generate Synth  Sample")
renoise.song():describe_undo(description)

-- Insert a new track at the given index. Inserting a track behind or at the
-- Master Track's index will create a Send Track. Otherwise, a regular track is
-- created.
renoise.song():insert_track_at(index)
  -> [new renoise.Track object]

-- Delete an existing track. The Master track can not be deleted, but all Sends
-- can. Renoise needs at least one regular track to work, thus trying to
-- delete all regular tracks will fire an error.
renoise.song():delete_track_at(index)

-- Swap the positions of two tracks. A Send can only be swapped with a Send
-- track and a regular track can only be swapped with another regular track.
-- The Master can not be swapped at all.
renoise.song():swap_tracks_at(index1, index2)

-- Insert a new instrument at the given index. This will remap all existing
-- notes in all patterns, if needed, and also update all other instrument links
-- in the song.
renoise.song():insert_instrument_at(index)
  -> [new renoise.Instrument object]

-- Delete an existing instrument at the given index. Renoise needs at least one
-- instrument, thus trying to completely remove all instruments is not allowed.
-- This will remap all existing notes in all patterns and update all other
-- instrument links in the song.
renoise.song():delete_instrument_at(index)

-- Swap the position of two instruments. Will remap all existing notes in all
-- patterns and update all other instrument links in the song.
renoise.song():swap_instruments_at(index2, index2)

-- Captures the current instrument (selects the instrument) from the current
-- note column at the current cursor pos. Changes the the selected instrument
-- accordingly, but does not return the result. When no instrument is present at
-- the current cursor pos, nothing will be done.
renoise.song():capture_instrument_from_pattern()

-- Tries to captures the nearest instrument from the current pattern track,
-- starting to look at the cursor pos, then advancing until an instrument is
-- found. Changes the the selected instrument accordingly, but does not return
-- the result. When no instruments (notes) are present in the current pattern
-- track, nothing will be done.
renoise.song():capture_nearest_instrument_from_pattern()

-- When rendering (see renoise.song().rendering, renoise.song().rendering_progress),
-- the current render process is canceled. Otherwise, nothing is done.
renoise.song():cancel_rendering()

-- Start rendering a section of the song or the whole song to a WAV file.
-- Rendering job will be done in the background and the call will return
-- back immediately, but the Renoise GUI will be blocked during rendering. The
-- passed 'rendering_done_callback' function is called as soon as rendering is
-- done, e.g. successfully completed.
-- While rendering, the rendering status can be polled with the song().rendering
-- and song().rendering_progress properties, for example, in idle notifier
-- loops. If starting the rendering process fails (because of file IO errors for
-- example), the render function will return false and the error message is set
-- as the second return value. On success, only a single "true" value is
-- returned. Param 'options' is a table with the following fields, all optional:
--
--     options = {
--       start_pos,     -- renoise.SongPos object. by default the song start.
--       end_pos,       -- renoise.SongPos object. by default the song end.
--       sample_rate,   -- number, one of 22050, 44100, 48000, 88200, 96000. \
--                      -- by default the players current rate.
--       bit_depth ,    -- number, one of 16, 24 or 32. by default 32.
--       interpolation, -- string, one of 'cubic', 'sinc'. by default cubic'.
--       priority,      -- string, one "low", "realtime", "high". \
--                      -- by default "high".
--     }
--
-- To render only specific tracks or columns, mute the undesired tracks/columns
-- before starting to render.
-- Param 'file_name' must point to a valid, maybe already existing file. If it
-- already exists, the file will be silently overwritten. The renderer will
-- automatically add a ".wav" extension to the file_name, if missing.
-- Param 'rendering_done_callback' is ONLY called when rendering has succeeded.
-- You can do something with the file you've passed to the renderer here, like
-- for example loading the file into a sample buffer.
renoise.song():render([options, ] filename, rendering_done_callback)
  -> [boolean, error_message]


-------- Properties

-- When the song is loaded from or saved to a file, the absolute path and name
-- to the XRNS file is returned. Otherewise, an empty string is returned.
renoise.song().file_name
  -> [read-only, string]

-- Song Comments  
-- Note: All property tables of basic types in the API are temporary copies.
-- In other words `renoise.song().comments = { "Hello", "World" }` will work,
-- `renoise.song().comments[1] = "Hello"; renoise.song().comments[2] = "World"`
-- will *not* work.
renoise.song().artist, _observable
  -> [string]
renoise.song().name, _observable
  -> [string]
renoise.song().comments[], _observable
  -> [array of strings]

-- Notifier is called as soon as any paragraph in the comments change.
renoise.song().comments_assignment_observable
  -> [renoise.Observable object]

-- See renoise.song():render(). Returns true while rendering is in progress.
renoise.song().rendering
  -> [read-only, boolean]

-- See renoise.song():render(). Returns the current render progress amount.
renoise.song().rendering_progress
  -> [read-only, number, 0-1.0]

-- See renoise.Transport for more info.
renoise.song().transport
  -> [read-only, renoise.Transport object]

-- See renoise.PatternSequencer for more info.
renoise.song().sequencer
  -> [read-only, renoise.PatternSequencer object]

-- See renoise.PatternIterator for more info.
renoise.song().pattern_iterator
  -> [read-only, renoise.PatternIterator object]

-- Instrument, Pattern, and Track arrays
renoise.song().instruments[], _observable
  -> [read-only, array of renoise.Instrument objects]
renoise.song().patterns[], _observable
  -> [read-only, array of renoise.Pattern objects]
renoise.song().tracks[], _observable
  -> [read-only, array of renoise.Track objects]

-- Selected in the instrument box. Never nil.
renoise.song().selected_instrument, _observable
  -> [read-only, renoise.Instrument object]
renoise.song().selected_instrument_index, _observable
  -> [number]

-- Selected in the instrument box. Never nil.
renoise.song().selected_sample, _observable
  -> [read-only, array of renoise.Sample objects]
renoise.song().selected_sample_index, _observable
  -> [number]

-- Selected in the pattern editor or mixer. Never nil.
renoise.song().selected_track, _observable
  -> [read-only, renoise.Track object]
renoise.song().selected_track_index, _observable
  -> [number]

-- Selected in the device chain editor. Can be nil.
renoise.song().selected_device, _observable
  -> [read-only, renoise.TrackDevice object or nil]
renoise.song().selected_device_index, _observable
  -> [number or 0 (when no device is selected)]

-- Selected in the automation editor view. Can be nil.
renoise.song().selected_parameter, _observable
  -> [read-only, renoise.DeviceParameter or nil]
renoise.song().selected_parameter_index, _observable
  -> [read-only, number or 0 (when no parameter is selected)]

-- The currently edited pattern. Never nil.
renoise.song().selected_pattern, _observable
  -> [read-only, renoise.Pattern object]

-- The currently edited pattern track object. Never nil.
-- and selected_track_index_observable for notifications.
renoise.song().selected_pattern_track, _observable
  -> [read-only, renoise.PatternTrack object]

-- The currently edited pattern index.
renoise.song().selected_pattern_index, _observable
  -> [number]

-- The currently edited sequence position.
renoise.song().selected_sequence_index, _observable
  -> [number]

-- The currently edited line in the edited pattern.
renoise.song().selected_line
  -> [read-only, renoise.PatternTrackLine object]
renoise.song().selected_line_index
  -> [number]

-- The currently edited column in the selected line in the edited
-- sequence/pattern. Nil when an effect column is selected.
renoise.song().selected_note_column
  -> [read-only, renoise.NoteColumn object or nil], [renoise.Line object or nil]
renoise.song().selected_note_column_index
  -> [number or nil (when an effect column is selected)]

-- The currently edited column in the selected line in the edited
-- sequence/pattern. Nil when a note column is selected.
renoise.song().selected_effect_column
  -> [read-only, renoise.EffectColumn or nil], [renoise.Line object or nil]
renoise.song().selected_effect_column_index
  -> [number or nil (when a note column is selected)]


--------------------------------------------------------------------------------
-- renoise.Transport
--------------------------------------------------------------------------------

-------- Constants

renoise.Transport.PLAYMODE_RESTART_PATTERN
renoise.Transport.PLAYMODE_CONTINUE_PATTERN

renoise.Transport.RECORD_PARAMETER_MODE_PATTERN
renoise.Transport.RECORD_PARAMETER_MODE_AUTOMATION


-------- Functions

-- Panic.
renoise.song().transport:panic()

-- Mode: enum = PLAYMODE
renoise.song().transport:start(mode)
renoise.song().transport:start_at(line)
renoise.song().transport:stop()

-- Immediately start playing at the given sequence position.
renoise.song().transport:trigger_sequence(sequence_pos)

-- Append the sequence to the scheduled sequence list. Scheduled playback
-- positions will apply as soon as the currently playing pattern play to end.
renoise.song().transport:add_scheduled_sequence(sequence_pos)

-- Replace the scheduled sequence list with the given sequence.
renoise.song().transport:set_scheduled_sequence(sequence_pos)

-- Move the block loop one segment forwards, when possible.
renoise.song().transport:loop_block_move_forwards()

-- Move the block loop one segment backwards, when possible.
renoise.song().transport:loop_block_move_backwards()

-- Start a new sample recording when the sample dialog is visible,
-- otherwise stop and finish it.
renoise.song().transport:start_stop_sample_recording()

-- Cancel a currently running sample recording when the sample dialog
-- is visible, otherwise do nothing.
renoise.song().transport:cancel_sample_recording()


-------- Properties

-- Playing.
renoise.song().transport.playing, _observable
  -> [boolean]

-- BPM, LPB, and TPL.
renoise.song().transport.bpm, _observable
  -> [number, 32-999]
renoise.song().transport.lpb, _observable
  -> [number, 1-256]
renoise.song().transport.tpl, _observable
  -> [number, 1-16]

-- Playback position.
renoise.song().transport.playback_pos
  -> [renoise.SongPos object]
renoise.song().transport.playback_pos_beats
  -> [float, 0-song_end_beats]

-- Edit position.
renoise.song().transport.edit_pos
  -> [renoise.SongPos object]
renoise.song().transport.edit_pos_beats
  -> [float, 0-sequence_length]

-- Song length.
renoise.song().transport.song_length
  -> [read-only, SongPos]
renoise.song().transport.song_length_beats
  -> [read-only, float]

-- Loop.
renoise.song().transport.loop_start
  -> [read-only, SongPos]
renoise.song().transport.loop_end
  -> [read-only, SongPos]
renoise.song().transport.loop_range
  -> [array of two renoise.SongPos objects]

renoise.song().transport.loop_start_beats
  -> [read-only, float within 0 - song_end_beats]
renoise.song().transport.loop_end_beats
  -> [read-only, float within 0 - song_end_beats]
renoise.song().transport.loop_range_beats
  -> [array of two floats within 0 - song_end_beats]

renoise.song().transport.loop_sequence_start
  -> [read-only, 0 or 1 - sequence_length]
renoise.song().transport.loop_sequence_end
  -> [read-only, 0 or 1 - sequence_length]
renoise.song().transport.loop_sequence_range
  -> [array of two numbers, 0 or 1-sequence_length or empty array to disable]

renoise.song().transport.loop_pattern, _observable
  -> [boolean]

renoise.song().transport.loop_block_enabled
  -> [boolean]
renoise.song().transport.loop_block_start_pos
  -> [read-only, renoise.SongPos object]
renoise.song().transport.loop_block_range_coeff
  -> [number, 2-16]

-- Edit modes.
renoise.song().transport.edit_mode, _observable
  -> [boolean]
renoise.song().transport.edit_step, _observable
  -> [number, 0-64]
renoise.song().transport.octave, _observable
  -> [number, 0-8]

-- Metronome.
renoise.song().transport.metronome_enabled, _observable
  -> [boolean]
renoise.song().transport.metronome_beats_per_bar, _observable
  -> [1 - 16]
renoise.song().transport.metronome_lines_per_beat, _observable
  -> [number, 1 - 256 or 0 = current LPB]

-- Chord mode.
renoise.song().transport.chord_mode_enabled, _observable
  -> [boolean]

-- Quantize.
renoise.song().transport.record_quantize_enabled, _observable
  -> [boolean]
renoise.song().transport.record_quantize_lines, _observable
  -> [number, 1 - 32]

-- Record parameter.
renoise.song().transport.record_parameter_mode, _observable
  -> [enum = RECORD_PARAMETER_MODE]

-- Follow, wrapped pattern, single track modes.
renoise.song().transport.follow_player, _observable
  -> [boolean]
renoise.song().transport.wrapped_pattern_edit, _observable
  -> [boolean]
renoise.song().transport.single_track_edit_mode, _observable
  -> [boolean]

-- Shuffle.
renoise.song().transport.shuffle_enabled, _observable
  -> [boolean]
renoise.song().transport.shuffle_amounts[]
  -> [array of floats, 0.0 - 1.0]

-- Attach notifiers that will be called as soon as any
-- shuffle value changed.
renoise.song().transport.shuffle_assignment_observable
  -> [renoise.Observable object]


--------------------------------------------------------------------------------
-- renoise.PatternSequencer
--------------------------------------------------------------------------------

-------- Functions

-- Insert a new or existing pattern at the given position in the sequence.
renoise.song().sequencer.insert_sequence_at(sequence_pos, pattern_index)

-- Delete an existing position in the sequence. Renoise needs at least one
-- sequence in the song for playback. Completely removing all sequence positions
-- is not allowed.
renoise.song().sequencer.delete_sequence_at(sequence_pos)

-- Insert an empty, unreferenced pattern at the given position.
renoise.song().sequencer:insert_new_pattern_at(sequence_pos)
  -> [new pattern_index]

-- Clone a sequence range, appending it right after to_sequence_pos.
-- Slot muting is copied as well.
renoise.song().sequencer:clone_range(from_sequence_pos, to_sequence_pos)

-- Make patterns in the given sequence pos range unique, if needed.
renoise.song().sequencer:make_range_unique(from_sequence_pos, to_sequence_pos)

-- Access to sequencer slot mute states. Mute slots are memorized in the
-- sequencer and not in the patterns.
renoise.song().sequencer:track_sequence_slot_is_muted(track_index, sequence_index)
  -> [boolean]
renoise.song().sequencer:set_track_sequence_slot_is_muted(
  track_index, sequence_index, muted)


-------- Properties

-- Pattern order list: Notifiers will only be fired when sequence positions are
-- added, removed or their order changed. To get notified of pattern assignment
-- changes use the property 'pattern_assignments_observable'.
renoise.song().sequencer.pattern_sequence[], _observable
  -> [array of numbers]

-- Attach notifiers that will be called as soon as any pattern assignment
-- at any sequence position changes.
renoise.song().sequencer.pattern_assignments_observable
  -> [renoise.Observable object]

-- Attach notifiers that will be fired as soon as any slot muting property
-- in any track/sequence slot changes.
renoise.song().sequencer.pattern_slot_mutes_observable
  -> [renoise.Observable object]


--------------------------------------------------------------------------------
-- renoise.PatternIterator
--------------------------------------------------------------------------------

-- General remarks: Iterators can only be use in "for" loops like you would use
-- "pairs" in Lua, example:

--     for pos,line in pattern_iterator:lines_in_song do [...]

-- The returned 'pos' is a table with "pattern", "track", "line" fields, and an
-- additional "column" field for the note/effect columns.

-- The "visible_only" flag controls if all content should be traversed, or only
-- the currently used patterns, columns, and so on:
-- With "visible_patters_only" set, patterns are traversed in the order they
-- are referenced in the pattern sequence, but each pattern is accessed only
-- once. With "visible_columns_only" set, hidden columns are not traversed.


-------- Song

-- Iterate over all pattern lines in the song.
renoise.song().pattern_iterator:lines_in_song(boolean visible_patterns_only)
  -> [iterator with pos, line (renoise.PatternTrackLine object)]

-- Iterate over all note/effect_ columns in the song.
renoise.song().pattern_iterator:note_columns_in_song(boolean visible_only)
  -> [iterator with pos, column (renoise.NoteColumn object)]
renoise.song():pattern_iterator:effect_columns_in_song(boolean visible_only)
  -> [iterator with pos, column (renoise.EffectColumn object)]


------- Pattern

-- Iterate over all lines in the given pattern only.
renoise.song().pattern_iterator:lines_in_pattern(pattern_index)
  -> [iterator with pos, line (renoise.PatternTrackLine object)]

-- Iterate over all note/effect columns in the specified pattern.
renoise.song().pattern_iterator:note_columns_in_pattern(
  pattern_index, boolean visible_only)
  -> [iterator with pos, column (renoise.NoteColumn object)]

renoise.song().pattern_iterator:effect_columns_in_pattern(
  pattern_index, boolean visible_only)
  -> [iterator with pos, column (renoise.EffectColumn object)]


------- Track

-- Iterate over all lines in the given track only.
renoise.song().pattern_iterator:lines_in_track(
  track_index, boolean visible_patterns_only)
  -> [iterator with pos, column (renoise.PatternTrackLine object)]

-- Iterate over all note/effect columns in the specified track.
renoise.song().pattern_iterator:note_columns_in_track(
  track_index, boolean visible_only)
  -> [iterator with pos, line (renoise.NoteColumn object)]

renoise.song().pattern_iterator:effect_columns_in_track(
  track_index, boolean visible_only)
  -> [iterator with pos, column (renoise.EffectColumn object)]


------- Track in Pattern

-- Iterate over all lines in the given pattern, track only.
renoise.song().pattern_iterator:lines_in_pattern_track(
  pattern_index, track_index)
  -> [iterator with pos, column (renoise.PatternTrackLine object)]

-- Iterate over all note/effect columns in the specified pattern track.
renoise.song().pattern_iterator:note_columns_in_pattern_track(
  pattern_index, track_index, boolean visible_only)
  -> [iterator with pos, line (renoise.NoteColumn object)]

renoise.song().pattern_iterator:effect_columns_in_pattern_track(
  pattern_index, track_index, boolean visible_only)
  -> [iterator with pos, column (renoise.EffectColumn object)]


--------------------------------------------------------------------------------
-- renoise.Track
--------------------------------------------------------------------------------

-------- Constants

renoise.Track.TRACK_TYPE_SEQUENCER
renoise.Track.TRACK_TYPE_MASTER
renoise.Track.TRACK_TYPE_SEND

renoise.Track.MUTE_STATE_ACTIVE
renoise.Track.MUTE_STATE_OFF
renoise.Track.MUTE_STATE_MUTED


-------- Functions

-- Insert a new device at the given position. "device_name" must be one of
-- renoise.song().tracks[].available_devices.
renoise.song().tracks[]:insert_device_at(device_name, device_index)
  -> [newly created renoise.TrackDevice object]

-- Delete an existing device in a track. The mixer device at index 1 can not
-- be deleted from a track.
renoise.song().tracks[]:delete_device_at(device_index)

-- Swap the positions of two devices in the device chain. The mixer device at
-- index 1 can not be swapped or moved.
renoise.song().tracks[]:swap_devices_at(device_index1, device_index2)

-- Uses default mute state from the prefs. Not for the master track.
renoise.song().tracks[]:mute()
renoise.song().tracks[]:unmute()
renoise.song().tracks[]:solo()

-- Note column column mutes. Only valid within (1 - track.max_note_columns)
renoise.song().tracks[]:column_is_muted(column)
  -> [boolean]
renoise.song().tracks[]:column_is_muted_observable(column)
  -> [Observable object]
renoise.song().tracks[]:mute_column(column, muted)


-------- Properties

-- Type, name, color.
renoise.song().tracks[].type
  -> [enum = TRACK_TYPE]

renoise.song().tracks[].name, _observable
  -> [string]

renoise.song().tracks[].color, _observable
  -> [table with 3 numbers (0-0xFF), RGB]

-- Mute and solo states. Not available for the master track.
renoise.song().tracks[].mute_state, _observable
  -> [enum = MUTE_STATE]

renoise.song().tracks[].solo_state, _observable
  -> [boolean]

-- Volume, panning, width.
renoise.song().tracks[].prefx_volume
  -> [renoise.DeviceParameter object]
renoise.song().tracks[].prefx_panning
  -> [renoise.DeviceParameter object]
renoise.song().tracks[].prefx_width
  -> [renoise.DeviceParameter object]

renoise.song().tracks[].postfx_volume
  -> [renoise.DeviceParameter object]
renoise.song().tracks[].postfx_panning
  -> [renoise.DeviceParameter object]

-- Output routing.
renoise.song().tracks[].available_output_routings[]
  -> [read-only, array of strings]
renoise.song().tracks[].output_routing, _observable
  -> [number, 1 - #available_output_routings]

-- Delay.
renoise.song().tracks[].output_delay, _observable
  -> [float, -100.0 - 100.0]

-- Pattern editor columns.
renoise.song().tracks[].max_effect_columns
  -> [read-only, number, 4 OR 0, depending on the track type]
renoise.song().tracks[].min_effect_columns
  -> [read-only, number, 1 OR 0, depending on the track type]

renoise.song().tracks[].max_note_columns
  -> [read-only, number, 12 OR 0, depending on the track type]
renoise.song().tracks[].min_note_columns
  -> [read-only, number, 1 OR 0, depending on the track type]

renoise.song().tracks[].visible_effect_columns, _observable
  -> [number, 1-4 OR 0-4, depending on the track type]
renoise.song().tracks[].visible_note_columns, _observable
  -> [number, 0 OR 1-12, depending on the track type]

renoise.song().tracks[].volume_column_visible, _observable
  -> [boolean]
renoise.song().tracks[].panning_column_visible, _observable
  -> [boolean]
renoise.song().tracks[].delay_column_visible, _observable
  -> [boolean]

-- Devices.
renoise.song().tracks[].available_devices[]
  -> [read-only, array of strings]

renoise.song().tracks[].devices[], _observable
  -> [read-only, array of renoise.TrackDevice objects]


--------------------------------------------------------------------------------
-- renoise.TrackDevice
--------------------------------------------------------------------------------

-------- Properties

-- Devices.
renoise.song().tracks[].devices[].name
  -> [read-only, string]

renoise.song().tracks[].devices[].is_active, _observable
  -> [boolean, not active = 'bypassed']

renoise.song().tracks[].devices[].is_maximized, _observable
  -> [boolean]

renoise.song().tracks[].devices[].active_preset, _observable
  -> [number, 0 when none is active or available]

renoise.song().tracks[].devices[].presets[]
  -> [read-only, list of strings]

renoise.song().tracks[].devices[].parameters[]
  -> [read-only, array of renoise.DeviceParameter objects]

-- Returns whether or not the device provides its own custom GUI (only available
-- for some plugin devices)
renoise.song().tracks[].devices[].external_editor_available
  -> [read-only, boolean]

-- When the device has no custom GUI an error will be fired (see
-- external_editor_available), otherwise the external editor is opened/closed.
renoise.song().tracks[].devices[].external_editor_visible
  -> [boolean, set to true to show the editor, false to close it]


--------------------------------------------------------------------------------
-- renoise.DeviceParameter
--------------------------------------------------------------------------------

-------- Constants

renoise.DeviceParameter.POLARITY_UNIPOLAR
renoise.DeviceParameter.POLARITY_BIPOLAR


-------- Functions

-- Set a new value and write automation when the MIDI mapping
-- "record to automation" option is set. Only works for parameters
-- of track devices, not for instrument devices.
renoise.song().tracks[].devices[].parameters[]:record_value(value)


-------- Properties

-- Device parameters.
renoise.song().tracks[].devices[].parameters[].name
  -> [read-only, string]

renoise.song().tracks[].devices[].parameters[].polarity
  -> [read-only, enum=POLARITY]

renoise.song().tracks[].devices[].parameters[].value_min
  -> [read-only, float]
renoise.song().tracks[].devices[].parameters[].value_max
  -> [read-only, float]
renoise.song().tracks[].devices[].parameters[].value_quantum
  -> [read-only, float]
renoise.song().tracks[].devices[].parameters[].value_default
  -> [read-only, float]

-- Not valid for parameters of instrument devices. Returns true if creating
-- envelope automation is possible for the parameter (see also
-- renoise.song().patterns[].tracks[]:create_automation)
renoise.song().tracks[].devices[].parameters[].is_automatable
  -> [read-only, boolean]

-- Is automated. Not valid for parameters of instrument devices.
renoise.song().tracks[].devices[].parameters[].is_automated, _observable
  -> [read-only, boolean]

-- Show in mixer. Not valid for parameters of instrument devices.
renoise.song().tracks[].devices[].parameters[].show_in_mixer, _observable
  -> [boolean]

-- Values.
renoise.song().tracks[].devices[].parameters[].value, _observable
  -> [float]
renoise.song().tracks[].devices[].parameters[].value_string, _observable
  -> [string]


--------------------------------------------------------------------------------
-- renoise.Instrument
--------------------------------------------------------------------------------

-------- Functions

-- Reset, clear all settings and all samples.
renoise.song().instruments[]:clear()

-- Copy all settings from the other instruments, including all samples.
renoise.song().instruments[]:copy_from(other_instrument object)

-- Insert a new empty sample.
renoise.song().instruments[]:insert_sample_at(index)
  -> [new renoise.Sample object]

-- Delete existing samples. At least one sample must exist per instrument.
renoise.song().instruments[]:delete_sample_at(index)

-- Swap positions of two samples.
renoise.song().instruments[]:swap_samples_at(index1, index2)


-------- Properties

-- Name.
renoise.song().instruments[].name, _observable
  -> [string]

-- Split map.
renoise.song().instruments[].split_map[]
  -> [array of 120 numbers]

-- Attach notifiers that will be called as soon as any split-map value changed.
renoise.song().instruments[].split_map_assignment_observable
  -> [renoise.Observable object]

-- Midi and plugin properties.
renoise.song().instruments[].midi_properties
  -> [renoise.InstrumentMidiProperties object]

renoise.song().instruments[].plugin_properties
  -> [renoise.InstrumentPluginProperties object]

-- Samples.
renoise.song().instruments[].samples[], _observable
  -> [read-only, array of renoise.Sample objects]


--------------------------------------------------------------------------------
-- renoise.Instrument.MidiProperties
--------------------------------------------------------------------------------

-------- Constants

renoise.Instrument.MidiProperties.TYPE_EXTERNAL
renoise.Instrument.MidiProperties.TYPE_LINE_IN_RET
renoise.Instrument.MidiProperties.TYPE_INTERNAL -- REWIRE


-------- Properties

-- Note: ReWire device always start with "ReWire: " in the device_name and
-- will always ignore the instrument_type and midi_channel properties. MIDI
-- channels are not configurable for ReWire MIDI, and instrument_type will
-- always be "TYPE_INTERNAL" for ReWire devices.
renoise.song().instruments[].midi_properties.instrument_type, _observable
  -> [Enum=TYPE_XXX]

-- When setting new devices, device names must be one of:
-- renoise.Midi.available_output_devices.
-- Devices are automatically opened when needed. To close a device, set its name
-- to "", e.g. an empty string.
renoise.song().instruments[].midi_properties.device_name, _observable
  -> [string]
renoise.song().instruments[].midi_properties.midi_channel, _observable
  -> [number, 1 - 16]
renoise.song().instruments[].midi_properties.midi_base_note, _observable
  -> [number, 0 - 119, C-4=48]
renoise.song().instruments[].midi_properties.midi_program, _observable
  -> [number, 1 - 128, 0 = OFF]
renoise.song().instruments[].midi_properties.midi_bank, _observable
  -> [number, 1 - 65536, 0 = OFF]
renoise.song().instruments[].midi_properties.delay, _observable
  -> [number, 0 - 100]
renoise.song().instruments[].midi_properties.duration, _observable
  -> [number, 1 - 8000, 8000 = INF]


--------------------------------------------------------------------------------
-- renoise.Instrument.PluginProperties
--------------------------------------------------------------------------------

-------- Functions

-- Load an existing, new, non aliased plugin. Pass an empty string to unload
-- an already assigned plugin. plugin_name must be one of:
-- plugin_properties.available_plugins.
renoise.song().instruments[].plugin_properties:load_plugin(plugin_name)
  -> [boolean, success]


-------- Properties

-- List of all currently available plugins. This is a list of unique plugin
-- names which also contains the plugin's type (VST/AU/DSSI/...), not including
-- the vendor names as visible in Renoise's GUI. Aka, its an identifier, and not
-- the name as visible in the GUI. When no plugin is loaded, the identifier is
-- an empty string.
renoise.song().instruments[].plugin_properties.available_plugins[]
  -> [read_only, list of strings]

-- Plugin name will be a non empty string as soon as plugin is or was loaded,
-- not necessarily when a plugin is present. When loading the plugin failed, or
-- the plugin currently is not installed on the system, name will be set, but
-- the device will NOT be present. When the plugin was successfully loaded,
-- plugin_name will be one of "available_plugins".
renoise.song().instruments[].plugin_properties.plugin_name
  -> [read_only, string]

-- Returns true when a plugin is present; loaded successfully.
renoise.song().instruments[].plugin_properties.plugin_loaded
  -> [read-only, boolean]

-- Valid object for successfully loaded plugins, otherwise nil. Alias plugin
-- instruments of FX will return the resolved device, will link to the device
-- the alias points to.
renoise.song().instruments[].plugin_properties.plugin_device
 -> [renoise.InstrumentDevice object or renoise.TrackDevice object or nil]

-- Valid for loaded and unloaded plugins.
renoise.song().instruments[].plugin_properties.alias_instrument_index
  -> [read-only, number or 0 (when no alias instrument is set)]
renoise.song().instruments[].plugin_properties.alias_fx_track_index
  -> [read-only, number or 0 (when no alias FX is set)]
renoise.song().instruments[].plugin_properties.alias_fx_device_index
  -> [read-only, number or 0 (when no alias FX is set)]

-- Valid for loaded and unloaded plugins.
renoise.song().instruments[].plugin_properties.midi_channel, _observable
  -> [number, 1 - 16]
renoise.song().instruments[].plugin_properties.midi_base_note, _observable
  -> [number, 0 - 119, C-4=48]

-- Valid for loaded and unloaded plugins.
renoise.song().instruments[].plugin_properties.volume, _observable
  -> [number, linear gain, 0 - 4]

-- Valid for loaded and unloaded plugins.
renoise.song().instruments[].plugin_properties.auto_suspend, _observable
  -> [boolean]
  

--------------------------------------------------------------------------------
-- renoise.InstrumentDevice
--------------------------------------------------------------------------------

-------- Properties

-- Plugins.
renoise.song().instruments[].plugin_properties.plugin_device.name
  -> [read-only, string]

renoise.song().instruments[].plugin_properties.plugin_device.active_preset, _observable
  -> [number, 0 when none is active or available]

renoise.song().instruments[].plugin_properties.plugin_device.presets[]
  -> [read-only, list of strings]

renoise.song().instruments[].plugin_properties.plugin_device.parameters[]
  -> [read-only, list of renoise.DeviceParameter objects]

-- Returns whether or not the plugin provides its own custom GUI.
renoise.song().instruments[].plugin_properties.plugin_device.external_editor_available
  -> [read-only, boolean]

-- When the plugin has no custom GUI, Renoise will create a dummy editor for it which
-- lists the plugin parameters.
renoise.song().instruments[].plugin_properties.plugin_device.external_editor_visible
  -> [boolean, set to true to show the editor, false to close it]


--------------------------------------------------------------------------------
-- renoise.Sample
--------------------------------------------------------------------------------

-------- Constants

renoise.Sample.INTERPOLATE_NONE
renoise.Sample.INTERPOLATE_LINEAR
renoise.Sample.INTERPOLATE_CUBIC

renoise.Sample.NEW_NOTE_ACTION_NOTE_CUT
renoise.Sample.NEW_NOTE_ACTION_NOTE_OFF
renoise.Sample.NEW_NOTE_ACTION_SUSTAIN

renoise.Sample.LOOP_MODE_OFF
renoise.Sample.LOOP_MODE_FORWARD
renoise.Sample.LOOP_MODE_REVERSE
renoise.Sample.LOOP_MODE_PING_PONG


-------- Functions

-- Reset, clear all sample settings and sample data.
renoise.song().instruments[].samples[]:clear()

-- Copy all settings, including sample data from another sample.
renoise.song().instruments[].samples[]:copy_from(other_sample object)


-------- Properties

-- Name.
renoise.song().instruments[].samples[].name, _observable
  -> [string]

-- Panning, volume.
renoise.song().instruments[].samples[].panning, _observable
  -> [float, 0.0 - 1.0]
renoise.song().instruments[].samples[].volume, _observable
  -> [float, 0.0 - 4.0]

-- Tuning.
renoise.song().instruments[].samples[].base_note, _observable
  -> [number, 0 - 119 with 48 = 'C-4']
renoise.song().instruments[].samples[].fine_tune, _observable
  -> [number, -127 - 127]

-- Beat sync.
renoise.song().instruments[].samples[].beat_sync_enabled, _observable
  -> [boolean]
renoise.song().instruments[].samples[].beat_sync_lines, _observable
  -> [number, 0-512]

-- Interpolation, new note action, autoseek.
renoise.song().instruments[].samples[].interpolation_mode, _observable
  -> [enum = INTERPOLATE]
renoise.song().instruments[].samples[].new_note_action, _observable
  -> [enum = NEW_NOTE_ACTION]

renoise.song().instruments[].samples[].autoseek, _observable
  -> [boolean]

-- Loops.
renoise.song().instruments[].samples[].loop_mode, _observable
  -> [enum = LOOP_MODE]
renoise.song().instruments[].samples[].loop_start, _observable
  -> [number, 1 - num_sample_frames]
renoise.song().instruments[].samples[].loop_end, _observable
  -> [number, 1 - num_sample_frames]

-- Buffer.
renoise.song().instruments[].samples[].sample_buffer, _observable
  -> [read-only, renoise.SampleBuffer object]


--------------------------------------------------------------------------------
-- renoise.SampleBuffer
--------------------------------------------------------------------------------

-------- Functions

-- Create new sample data with the given rate, bit-depth, channel and frame
-- count. Will trash existing sample data. Initial buffer is all zero.
-- Will only return false when memory allocation fails (you're running out
-- of memory). All other errors are fired as usual.
renoise.song().instruments[].samples[].sample_buffer:create_sample_data(
  sample_rate, bit_depth, num_channels, num_frames)
    -> [boolean - success]

-- Delete existing sample data.
renoise.song().instruments[].samples[].sample_buffer:delete_sample_data()

-- Read access to samples in a sample data buffer.
renoise.song().instruments[].samples[].sample_buffer:sample_data(
  channel_index, frame_index)
  -> [float -1 - 1]

-- Write access to samples in a sample data buffer. New samples values must be
-- within [-1, 1] and will be clipped automatically.
-- IMPORTANT: before modifying buffers, call 'prepare_sample_data_changes'.
-- When you are done, call 'finalize_sample_data_changes' to generate undo/redo
-- data for your changes and update sample overview caches!
renoise.song().instruments[].samples[].sample_buffer:set_sample_data(
  channel_index, frame_index, sample_value)

-- To be called once BEFORE sample data gets manipulated via 'set_sample_data'.
-- This will prepare undo/redo data for the whole sample. See also
-- 'finalize_sample_data_changes'.
renoise.song().instruments[].samples[].sample_buffer:prepare_sample_data_changes()

-- To be called once AFTER the sample data is manipulated via 'set_sample_data'.
-- This will create undo/redo data for the whole sample, and also  update the
-- sample view caches for the sample. The reason this isn't automatically
-- invoked is to avoid performance overhead when changing sample data 'sample by
-- sample'. Don't forget to call this after any data changes, or changes may not
-- be visible in the GUI and can not be un/redone!
renoise.song().instruments[].samples[].sample_buffer:finalize_sample_data_changes()

-- Load sample data from a file. Files can be any audio format Renoise supports.
-- Possible errors are shown to the user, otherwise success is returned.
renoise.song().instruments[].samples[].sample_buffer:load_from(filename)
  -> [boolean - success]

-- Export sample data to a file. Possible errors are shown to the user,
-- otherwise success is returned. Valid export types are 'wav' or 'flac'.
renoise.song().instruments[].samples[].sample_buffer:save_as(filename, format)
  -> [boolean - success]


-------- Properties

-- Has sample data?
renoise.song().instruments[].samples[].sample_buffer.has_sample_data
  -> [read-only, boolean]

-- _NOTE: All following properties are invalid when no sample data is present,
-- 'has_sample_data' returns false:_

-- The current sample rate in Hz, like 44100.
renoise.song().instruments[].samples[].sample_buffer.sample_rate
  -> [read-only, number]

-- The current bit depth, like 32, 16, 8.
renoise.song().instruments[].samples[].sample_buffer.bit_depth
  -> [read-only, number]

-- The number of sample channels (1 or 2)
renoise.song().instruments[].samples[].sample_buffer.number_of_channels
  -> [read-only, number]

-- The sample frame count (number of samples per channel)
renoise.song().instruments[].samples[].sample_buffer.number_of_frames
  -> [read-only, number]

-- Selection range as visible in the sample editor. Getters are always
-- valid, but only relevant for the currently active sample.
-- Setting new selections is only allowed for the currently selected
-- sample.
renoise.song().instruments[].samples[].sample_buffer.selection_start
  -> [number >= 1 <= number_of_frames]
renoise.song().instruments[].samples[].sample_buffer.selection_end
  -> [number >= 1 <= number_of_frames]
renoise.song().instruments[].samples[].sample_buffer.selection_range
  -> [array of two numbers, >= 1 <= number_of_frames]


--------------------------------------------------------------------------------
-- renoise.Pattern
--------------------------------------------------------------------------------

-------- Constants

-- Maximum number of lines that can be present in a pattern.
renoise.Pattern.MAX_NUMBER_OF_LINES


-------- Functions

-- Deletes all lines & automation.
renoise.song().patterns[]:clear()

-- Copy contents from other patterns, including automation, when possible.
renoise.song().patterns[]:copy_from(other_pattern object)


-- Check/add/remove notifier functions or methods, which are called by Renoise
-- as soon as any of the pattern's lines have changed.
-- The notifiers are called as soon as a new line is added, an existing line
-- is cleared, or existing lines are somehow changed (notes, effects, anything)
--
-- A single argument is passed to the notifier function: "pos", a table with the
-- fields "pattern", "track" and "line", which defines where the change has
-- happened, e.g:
--
--     function my_pattern_line_notifier(pos)
--       -- check pos.pattern, pos.track, pos.line (all are indices)
--     end
--
-- Please be gentle with these notifiers, don't do too much stuff in there.
-- Ideally just set a flag like "pattern_dirty" which then gets picked up by
-- an app_idle notifier: The danger here is that line change notifiers can
-- be called hundreds of times when, for example, simply clearing a pattern.
--
-- If you are only interested in changes that are made to the currently edited
-- pattern, dynamically attach and detach to the selected pattern's line
-- notifiers by listening to "renoise.song().selected_pattern_observable".

renoise.song().patterns[]:has_line_notifier(func[, obj])
  -> [boolean]

renoise.song().patterns[]:add_line_notifier(func[, obj])
renoise.song().patterns[]:remove_line_notifier(func[, obj])


-------- Properties

-- Quickly check if a pattern has some pattern lines or automation.
renoise.song().patterns[].is_empty
  -> [read-only, boolean]

-- Name of the pattern, as visible in the pattern sequencer.
renoise.song().patterns[].name, _observable
  -> [string]

-- Number of lines the pattern currently has. 64 by default. Max is
-- renoise.Pattern.MAX_NUMBER_OF_LINES, min is 1.
renoise.song().patterns[].number_of_lines, _observable
  -> [number]

-- Access to the pattern tracks. Each pattern has #renoise.tracks amount
-- of tracks.
renoise.song().patterns[].tracks[]
  -> [read-only, array of renoise.PatternTrack]


-------- Operators

-- Compares all tracks and lines, including automation.
==(Pattern object, Pattern object) -> [boolean]
~=(Pattern object, Pattern object) -> [boolean]


--------------------------------------------------------------------------------
-- renoise.PatternTrack
--------------------------------------------------------------------------------

-------- Functions

-- Deletes all lines & automation.
renoise.song().patterns[].tracks[]:clear()

-- Copy contents from other pattern tracks, including automation when possible.
renoise.song().patterns[].tracks[]:copy_from(other_pattern_track object)


-- Get a specific line (line must be [1 - Pattern.MAX_NUMBER_OF_LINES]). This is
-- a !lot! more efficient than calling the property: lines[index]
renoise.song().patterns[].tracks[]:line(index)
  -> [renoise.PatternTrackLine]

-- Get a specific line range (index must be [1 - Pattern.MAX_NUMBER_OF_LINES])
renoise.song().patterns[].tracks[]:lines_in_range(index_from, index_to)
  -> [array of renoise.PatternTrackLine]


-- Returns the automation for the given device parameter or nil when there is
-- none.
renoise.song().patterns[].tracks[]:find_automation(parameter)
  -> [renoise.PatternTrackAutomation or nil]

-- Creates a new automation for the given device parameter.
-- Fires an error when an automation for the given parameter already exists.
-- Returns the newly created automation. Passed parameter must be automatable,
-- which can be tested with 'parameter.is_automatable'.
renoise.song().patterns[].tracks[]:create_automation(parameter)
  -> [renoise.PatternTrackAutomation object]

-- Remove an existing automation the given device parameter. Automation
-- must exist.
renoise.song().patterns[].tracks[]:delete_automation(parameter)


-------- Properties

-- Color.
renoise.song().patterns[].tracks[].color, _observable
  -> [table with 3 numbers (0-0xFF, RGB) or nil when no custom slot color is set]

-- Returns true when all the track lines are empty. Does not look at automation.
renoise.song().patterns[].tracks[].is_empty, _observable
  -> [read-only, boolean]

-- Get all lines in range [1, number_of_lines_in_pattern]
renoise.song().patterns[].tracks[].lines[]
  -> [read-only, array of renoise.PatternTrackLine objects]

-- Automation.
renoise.song().patterns[].tracks[].automation[], _observable
  -> [read-only, list of renoise.PatternTrackAutomation]


-------- Operators

-- Compares line content and automation.
==(PatternTrack object, PatternTrack object) -> [boolean]
~=(PatternTrack object, PatternTrack object) -> [boolean]


--------------------------------------------------------------------------------
-- renoise.PatternTrackAutomation
--------------------------------------------------------------------------------

-------- Constants

renoise.PatternTrackAutomation.PLAYMODE_POINTS
renoise.PatternTrackAutomation.PLAYMODE_LINEAR
renoise.PatternTrackAutomation.PLAYMODE_CUBIC


-------- Properties

-- Destination device, destination parameter, playmode.
renoise.song().patterns[].tracks[].automation[].dest_device
  -> [renoise.TrackDevice]

renoise.song().patterns[].tracks[].automation[].dest_parameter
  -> [renoise.DeviceParameter]

renoise.song().patterns[].tracks[].automation[].playmode, _observable
  -> [enum PLAYMODE]


-- Max length (time) of the automation. Will always fit the patterns length.
renoise.song().patterns[].tracks[].automation[].length
  -> [number]

-- Get all points of the automation. When setting a new list of points,
-- items may be unsorted by time, but there may not be multiple points
-- for the same time. Returns a copy of the list, so changing
-- `points[1].value` will not do anything. Instead, change them via
-- `points = { something }` instead.
renoise.song().patterns[].tracks[].automation[].points, _observable
  -> [list of {time, value} tables]

-- An automation point's time in pattern lines.
renoise.song().patterns[].tracks[].automation[].points[].time
  -> [number, 1 - NUM_LINES_IN_PATTERN]

-- An automation point's value [0 - 1.0]
renoise.song().patterns[].tracks[].automation[].points[].value
  -> [number, 0 - 1.0]


-------- Functions

-- Removes all points from the automation. Will not delete the automation
-- from tracks[]:automation, instead the resulting automation will not do
-- anything at all.
renoise.song().patterns[].tracks[].automation[]:clear()

-- Copy all points and playback settings from another track automation.
renoise.song().patterns[].tracks[].automation[]:copy_from()

-- Test if a point exists at the given time (in lines)
renoise.song().patterns[].tracks[].automation[]:has_point_at(time)
   -> [boolean]

-- Insert a new point, or change an existing one, if a point in
-- time already exists.
renoise.song().patterns[].tracks[].automation[]:add_point_at(time, value)

-- Removes a point at the given time. Point must exist.
renoise.song().patterns[].tracks[].automation[]:remove_point_at(time)


-------- Operators

-- Compares automation content only, ignoring dest parameters.
==(PatternTrackAutomation object, PatternTrackAutomation object) -> [boolean]
~=(PatternTrackAutomation object, PatternTrackAutomation object) -> [boolean]


--------------------------------------------------------------------------------
-- renoise.PatternTrackLine
--------------------------------------------------------------------------------

-------- Constants

renoise.PatternTrackLine.EMPTY_NOTE
renoise.PatternTrackLine.NOTE_OFF

renoise.PatternTrackLine.EMPTY_INSTRUMENT
renoise.PatternTrackLine.EMPTY_VOLUME
renoise.PatternTrackLine.EMPTY_PANNING
renoise.PatternTrackLine.EMPTY_DELAY

renoise.PatternTrackLine.EMPTY_EFFECT_NUMBER
renoise.PatternTrackLine.EMPTY_EFFECT_AMOUNT


-------- Functions

-- Clear all note and effect columns.
renoise.song().patterns[].tracks[].lines[]:clear()

-- Copy contents from other_line, trashing column content.
renoise.song().patterns[].tracks[].lines[]:copy_from(other_line object)


-------- Properties


-- Is empty.
renoise.song().patterns[].tracks[].lines[].is_empty
  -> [boolean]

-- Columns.
renoise.song().patterns[].tracks[].lines[].note_columns
  -> [read-only, array of renoise.NoteColumn objects]

renoise.song().patterns[].tracks[].lines[].effect_columns
  -> [read-only, array of renoise.EffectColumn objects]


-------- Operators

-- Compares all columns.
==(PatternTrackLine object, PatternTrackLine object) -> [boolean]
~=(PatternTrackLine object, PatternTrackLine object) -> [boolean]

-- Serialize a line.
tostring(Pattern object) -> [string]


--------------------------------------------------------------------------------
-- renoise.NoteColumn
--------------------------------------------------------------------------------

-------- Functions

-- Clear the note column.
renoise.song().patterns[].tracks[].lines[].note_columns[]:clear()

-- Copy the column's content from another column.
renoise.song().patterns[].tracks[].lines[].note_columns[]:copy_from(
  other_column object)


-------- Properties

-- True, when all note column properties are empty.
renoise.song().patterns[].tracks[].lines[].note_columns[].is_empty
  -> [read-only, boolean]

-- True, when this column is selected in the pattern editors current pattern.
renoise.song().patterns[].tracks[].lines[].note_columns[].is_selected
  -> [read-only, boolean]

-- Access note column properties either by values (numbers) or by strings.
-- The string representation uses exactly the same notation as you see
-- in Renoise's pattern editor.

renoise.song().patterns[].tracks[].lines[].note_columns[].note_value
  -> [number, 0-119, 120=Off, 121=Empty]
renoise.song().patterns[].tracks[].lines[].note_columns[].note_string
  -> [string, 'C-0' - 'G-9', 'OFF' or '---']

renoise.song().patterns[].tracks[].lines[].note_columns[].instrument_value
  -> [number, 0-254, 255==Empty]
renoise.song()patterns[].tracks[].lines[].note_columns[].instrument_string
  -> [string, '00' - 'FE' or '..']

renoise.song()patterns[].tracks[].lines[].note_columns[].volume_value
  -> [number, 0-254, 255==Empty]
renoise.song().patterns[].tracks[].lines[].note_columns[].volume_string
  -> [string, '00' - 'FE' or '..']

renoise.song().patterns[].tracks[].lines[].note_columns[].panning_value
  -> [number, 0-254, 255==Empty]
renoise.song().patterns[].tracks[].lines[].note_columns[].panning_string
  -> [string, '00' - 'FE' or '..']

renoise.song().patterns[].tracks[].lines[].note_columns[].delay_value
  -> [number, 0-255]
renoise.song().patterns[].tracks[].lines[].note_columns[].delay_string
  -> [string, '00' - 'FF' or '..']


-------- Operators

-- Compares the whole column.
==(NoteColumn object, NoteColumn object) -> [boolean]
~=(NoteColumn object, NoteColumn object) -> [boolean]

-- Serialize a column.
tostring(Pattern object) -> [string]


--------------------------------------------------------------------------------
-- renoise.EffectColumn
--------------------------------------------------------------------------------

-------- Functions

-- Clear the effect column.
renoise.song().patterns[].tracks[].lines[].effect_columns[]:clear()

-- Copy the column's content from another column.
renoise.song().patterns[].tracks[].lines[].effect_columns[]:copy_from(other_column object)


-------- Properties

-- True, when all effect column properties are empty.
renoise.song().patterns[].tracks[].lines[].effect_columns[].is_empty
  -> [read-only, boolean]

-- True, when this column is selected in the pattern_editors current pattern.
renoise.song().patterns[].tracks[].lines[].effect_columns[].is_selected
  -> [read-only, boolean]

-- Access effect column properties either by values (numbers) or by strings.

renoise.song().patterns[].tracks[].lines[].effect_columns[].number_value
  -> [number, 0-255]
renoise.song().patterns[].tracks[].lines[].effect_columns[].number_string
  -> [string, '00' - 'FF']

renoise.song().patterns[].tracks[].lines[].effect_columns[].amount_value
  -> number, 0-255]
renoise.song().patterns[].tracks[].lines[].effect_columns[].amount_string
  -> [string, '00' - 'FF']


-------- Operators

-- Compares the whole column.
==(EffectColumn object, EffectColumn object) -> [boolean]
~=(EffectColumn object, EffectColumn object) -> [boolean]

-- Serialize a column.
tostring(Pattern object) -> [string]

