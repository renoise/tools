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

-------- Constants

renoise.Song.MAX_NUMBER_OF_INSTRUMENTS

renoise.Song.SUB_COLUMN_NOTE
renoise.Song.SUB_COLUMN_INSTRUMENT
renoise.Song.SUB_COLUMN_VOLUME
renoise.Song.SUB_COLUMN_PANNING
renoise.Song.SUB_COLUMN_DELAY
renoise.Song.SUB_COLUMN_SAMPLE_EFFECT_NUMBER
renoise.Song.SUB_COLUMN_SAMPLE_EFFECT_AMOUNT

renoise.Song.SUB_COLUMN_EFFECT_NUMBER
renoise.Song.SUB_COLUMN_EFFECT_AMOUNT


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
-- give your changes a custom undo description (like: "Generate Synth Sample")
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

-- Access to a single track by index. Use properties 'tracks' to iterate over 
-- all tracks and to query the track count.
renoise.song():track(index)
  -> [renoise.Track object]

-- Set the selected track to prev/next relative to the current track. Takes
-- care of skipping over hidden tracks and wrapping around at the edges.
renoise.song():select_previous_track()
renoise.song():select_next_track()

-- Insert a new group track at the given index. Group tracks can only be
-- inserted before the Master track.
renoise.song():insert_group_at(index)
  -> [new renoise.GroupTrack object]

-- Add track at track_index to group at group_index by first moving it to the
-- right spot to the left of the group track, and then adding it. If group_index
-- is not a group track, a new group track will be created and both tracks
-- will be added to it.
renoise.song():add_track_to_group(track_index, group_index)
-- Removes track from its immediate parent group and places it outside it to
-- the left. Can only be called for tracks that are actually part of a group.
renoise.song():remove_track_from_group(track_index)
-- Delete the group with the given index and all its member tracks.
-- Index must be that of a group or a track that is a member of a group.
renoise.song():delete_group_at(index)

-- Insert a new instrument at the given index. This will remap all existing
-- notes in all patterns, if needed, and also update all other instrument links
-- in the song. Can't have more than MAX_NUMBER_OF_INSTRUMENTS in a song.
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

-- Access to a single instrument by index. Use properties 'instruments' to iterate 
-- over all instruments and to query the instrument count.
renoise.song():instrument(index)
  -> [renoise.Instrument object]

-- Captures the current instrument (selects the instrument) from the current
-- note column at the current cursor pos. Changes the selected instrument
-- accordingly, but does not return the result. When no instrument is present at
-- the current cursor pos, nothing will be done.
renoise.song():capture_instrument_from_pattern()

-- Tries to captures the nearest instrument from the current pattern track,
-- starting to look at the cursor pos, then advancing until an instrument is
-- found. Changes the selected instrument accordingly, but does not return
-- the result. When no instruments (notes) are present in the current pattern
-- track, nothing will be done.
renoise.song():capture_nearest_instrument_from_pattern()

-- Access to a single pattern by index. Use properties 'patterns' to iterate 
-- over all patterns and to query the pattern count.
renoise.song():pattern(index)
  -> [renoise.Pattern object]

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
-- returned. Parameter 'options' is a table with the following fields, all optional:
--
--     options = {
--       start_pos,     -- renoise.SongPos object. by default the song start.
--       end_pos,       -- renoise.SongPos object. by default the song end.
--       sample_rate,   -- one of 22050, 44100, 48000, 88200, 96000, 192000. \
--                      -- by default the players current rate.
--       bit_depth ,    -- number, one of 16, 24 or 32. by default 32.
--       interpolation, -- string, one of 'default', 'precise'. by default default'.
--       priority,      -- string, one "low", "realtime", "high". \
--                      -- by default "high".
--     }
--
-- To render only specific tracks or columns, mute the undesired tracks/columns
-- before starting to render.
-- Parameter 'file_name' must point to a valid, maybe already existing file. If it
-- already exists, the file will be silently overwritten. The renderer will
-- automatically add a ".wav" extension to the file_name, if missing.
-- Parameter 'rendering_done_callback' is ONLY called when rendering has succeeded.
-- You can do something with the file you've passed to the renderer here, like
-- for example loading the file into a sample buffer.
renoise.song():render([options, ] filename, rendering_done_callback)
  -> [boolean, error_message or nil]

-- Load/save all global MIDI mappings in the song into a XRNM file. 
-- Returns true when loading/saving succeeded, else false and the error_message.
renoise.song():load_midi_mappings(filename)
  -> [boolean, error_message or nil]
renoise.song():save_midi_mappings(filename)
  -> [boolean, error_message or nil]

-- clear all MIDI mappings in the song
renoise.song():clear_midi_mappings()


-------- Properties

-- When the song is loaded from or saved to a file, the absolute path and name
-- to the XRNS file is returned. Otherwise, an empty string is returned.
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
  -> [read-only, renoise.Observable object]
-- Set this to true to show the comments dialog after loading a song
renoise.song().show_comments_after_loading, _observable 
  -> [boolean]

-- Inject/fetch custom XRNX scripting tool data into the song. Can only be called
-- from scripts that are running in Renoise scripting tool bundles; attempts to
-- access the data from e.g. the scripting terminal will result in an error.
-- Returns nil when no data is present.
--
-- Each tool gets it's own data slot in the song, which is resolved by the tool's
-- bundle id, so this data is unique for every tool and persistent accross tools
-- with the same bundle id (but possibly different versions).
-- If you want to store renoise.Document data in here, you can use the
-- renoise.Document's 'to_string' and 'from_string' functions to serialize the data.
-- Alternatively, write your own serializers for your custom data.
renoise.song().tool_data
  -> [string or nil]
  
-- See renoise.song():render(). Returns true while rendering is in progress.
renoise.song().rendering
  -> [read-only, boolean]

-- See renoise.song():render(). Returns the current render progress amount.
renoise.song().rendering_progress
  -> [read-only, number, 0.0-1.0]

-- See renoise.Transport for more info.
renoise.song().transport
  -> [read-only, renoise.Transport object]

-- See renoise.PatternSequencer for more info.
renoise.song().sequencer
  -> [read-only, renoise.PatternSequencer object]

-- See renoise.PatternIterator for more info.
renoise.song().pattern_iterator
  -> [read-only, renoise.PatternIterator object]

-- number of normal playback tracks (non-master or sends) in song.
renoise.song().sequencer_track_count
  -> [read-only, number]
-- number of send tracks in song.
renoise.song().send_track_count
  -> [read-only, number]

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

-- Currently selected phrase the instrument's phrase map piano 
-- view. Can be nil.
renoise.song().selected_phrase, _observable
  -> [read-only, renoise.InstrumentPhrase object or nil]
renoise.song().selected_phrase_index
  -> [number, index or 0 when no phrase is selected]


-- Selected in the instrument's sample list. Only nil when no samples 
-- are present in the selected instrument.
renoise.song().selected_sample, _observable
  -> [read-only, renoise.Sample object or nil]
renoise.song().selected_sample_index
  -> [number, index or 0 when no sample is selected (no samples are present)]

-- Selected in the instrument's modulation view. Can be nil.
renoise.song().selected_sample_modulation_set, _observable 
  -> [read-only, renoise.SampleModulationSet object or nil]
renoise.song().selected_sample_modulation_set_index
  -> [number, index or 0 when no set is selected]

-- Selected in the instrument's effects view. Can be nil.
renoise.song().selected_sample_device_chain, _observable 
  -> [read-only, renoise.SampleDeviceChain object or nil]
renoise.song().selected_sample_device_chain_index
  -> [number, index or 0 when no set is selected]

-- Selected in the sample effect mixer. Can be nil.
renoise.song().selected_sample_device, _observable
  -> [read-only, renoise.AudioDevice object or nil]
renoise.song().selected_sample_device_index
  -> [number, index or 0 (when no device is selected)]

-- Selected in the pattern editor or mixer. Never nil.
renoise.song().selected_track, _observable
  -> [read-only, renoise.Track object]
renoise.song().selected_track_index, _observable
  -> [number]

-- Selected in the track DSP chain editor. Can be nil.
renoise.song().selected_track_device, _observable
  -> [read-only, renoise.AudioDevice object or nil]
renoise.song().selected_track_device_index
  -> [number, index or 0 (when no device is selected)]

-- DEPRECATED - alias for new 'selected_track_device' property
renoise.song().selected_device, _observable
  -> [read-only, renoise.AudioDevice object or nil]
renoise.song().selected_device_index
  -> [number, index or 0 (when no device is selected)]

-- DEPRECATED - alias for new 'selected_automation_parameter' property
renoise.song().selected_parameter, _observable
  -> [renoise.DeviceParameter object or nil]
  
-- Selected parameter in the automation editor. Can be nil.
-- When setting a new parameter, parameter must be automateable and 
-- must be one of the currently selected track device chain.
renoise.song().selected_automation_parameter, _observable
  -> [renoise.DeviceParameter object or nil]
-- parent device of 'selected_automation_parameter'. not settable.
renoise.song().selected_automation_device, _observable
  -> [renoise.AudioDevice object or nil]

-- The currently edited pattern. Never nil.
renoise.song().selected_pattern, _observable
  -> [read-only, renoise.Pattern object]
renoise.song().selected_pattern_index, _observable
  -> [number]

-- The currently edited pattern track object. Never nil.
-- and selected_track_observable for notifications.
renoise.song().selected_pattern_track, _observable
  -> [read-only, renoise.PatternTrack object]

-- The currently edited sequence position.
renoise.song().selected_sequence_index, _observable
  -> [number]

-- The currently edited line in the edited pattern.
renoise.song().selected_line
  -> [read-only, renoise.PatternLine object]
renoise.song().selected_line_index
  -> [number]

-- The currently edited column in the selected line in the edited
-- sequence/pattern. Nil when an effect column is selected.
renoise.song().selected_note_column
  -> [read-only, renoise.NoteColumn object or nil], [renoise.Line object or nil]
renoise.song().selected_note_column_index
  -> [number, index or 0 (when an effect column is selected)]

-- The currently edited column in the selected line in the edited
-- sequence/pattern. Nil when a note column is selected.
renoise.song().selected_effect_column
  -> [read-only, renoise.EffectColumn or nil], [renoise.Line object or nil]
renoise.song().selected_effect_column_index
  -> [number, index or 0 (when a note column is selected)]

-- The currently edited sub column type within the selected note/effect column.
renoise.song().selected_sub_column_type
  -> [read-only, enum = SUB_COLUMN]

-- Read/write access to the selection in the pattern editor.
-- The property is a table with the following members:
--
--  {
--    start_line,     -- Start pattern line index
--    start_track,    -- Start track index
--    start_column,   -- Start column index within start_track   
-- 
--    end_line,       -- End pattern line index
--    end_track,      -- End track index
--    end_column      -- End column index within end_track
--  }
--
-- Line indexes are valid from 1 to renoise.song().patterns[].number_of_lines
--
-- Track indexes are valid from 1 to #renoise.song().tracks
--
-- Column indexes are valid from 1 to 
--   (renoise.song().tracks[].visible_note_columns +
--    renoise.song().tracks[].visible_effect_columns)
--
-- When setting the selection, all members are optional. Combining them in 
-- various different ways will affect how specific the selection is. When 
-- 'selection_in_pattern' returns nil or is set to nil, no selection is present.
--
-- Examples: 
-- renoise.song().selection_in_pattern = {} 
--   --> clear
-- renoise.song().selection_in_pattern = { start_line = 1, end_line = 4 } 
--   --> select line 1 to 4, first to last track
-- renoise.song().selection_in_pattern = 
--   { start_line = 1, start_track = 1, end_line = 4, end_track = 1 } 
--   --> select line 1 to 4, in the first track only 
--
renoise.song().selection_in_pattern
  -> [table of start/end values or nil]
-- same as 'selection_in_pattern' but for the currently selected phrase (if any).
-- there are no tracks in phrases, so only 'line' and 'column' fields are valid.
renoise.song().selection_in_phrase
  -> [table of start/end values or nil]


--------------------------------------------------------------------------------
-- renoise.Transport
--------------------------------------------------------------------------------

-------- Constants

renoise.Transport.PLAYMODE_RESTART_PATTERN
renoise.Transport.PLAYMODE_CONTINUE_PATTERN

renoise.Transport.RECORD_PARAMETER_MODE_PATTERN
renoise.Transport.RECORD_PARAMETER_MODE_AUTOMATION

renoise.Transport.TIMING_MODEL_SPEED
renoise.Transport.TIMING_MODEL_LPB


-------- Functions

-- Panic.
renoise.song().transport:panic()

-- Mode: enum = PLAYMODE
renoise.song().transport:start(mode)
-- start playing the currently edited pattern at the given line offset
renoise.song().transport:start_at(line)
-- start playing a the given renoise.SongPos (sequence pos and line)
renoise.song().transport:start_at(song_pos)

-- stop playing. when already stopped this just stops all playing notes.
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

-- Old school speed or new LPB timing used?
-- With TIMING_MODEL_SPEED, tpl is used as speed factor. The lpb property 
-- is unused then. With TIMING_MODEL_LPB, tpl is used as event rate for effects
-- only and lpb defines relationship between pattern lines and beats.
renoise.song().transport.timing_model
  -> [read-only, enum = TIMING_MODEL]

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
  -> [number, 0-song_end_beats]

-- Edit position.
renoise.song().transport.edit_pos
  -> [renoise.SongPos object]
renoise.song().transport.edit_pos_beats
  -> [number, 0-sequence_length]

-- Song length.
renoise.song().transport.song_length
  -> [read-only, SongPos]
renoise.song().transport.song_length_beats
  -> [read-only, number]

-- Loop.
renoise.song().transport.loop_start
  -> [read-only, SongPos]
renoise.song().transport.loop_end
  -> [read-only, SongPos]
renoise.song().transport.loop_range[]
  -> [array of two renoise.SongPos objects]

renoise.song().transport.loop_start_beats
  -> [read-only, number within 0-song_end_beats]
renoise.song().transport.loop_end_beats
  -> [read-only, number within 0-song_end_beats]
renoise.song().transport.loop_range_beats[]
  -> [array of two numbers, 0-song_end_beats]

renoise.song().transport.loop_sequence_start
  -> [read-only, 0 or 1-sequence_length]
renoise.song().transport.loop_sequence_end
  -> [read-only, 0 or 1-sequence_length]
renoise.song().transport.loop_sequence_range[]
  -> [array of two numbers, 0 or 1-sequence_length or empty to disable]

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
  -> [1-16]
renoise.song().transport.metronome_lines_per_beat, _observable
  -> [number, 1-256 or 0 = songs current LPB]

-- Metronome precount.
renoise.song().transport.metronome_precount_enabled, _observable
  -> [boolean]
renoise.song().transport.metronome_precount_bars, _observable
  -> [number, 1-4]


-- Quantize.
renoise.song().transport.record_quantize_enabled, _observable
  -> [boolean]
renoise.song().transport.record_quantize_lines, _observable
  -> [number, 1-32]

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

-- Groove. (aka Shuffle)
renoise.song().transport.groove_enabled, _observable
  -> [boolean]
renoise.song().transport.groove_amounts[]
  -> [array of numbers, 0.0-1.0]
-- Attach notifiers that will be called as soon as any
-- groove amount value changed.
renoise.song().transport.groove_assignment_observable
  -> [renoise.Observable object]

-- Global Track Headroom.
-- To convert to dB:   dB = math.lin2db(renoise.song().transport.track_headroom)
-- To convert from dB: renoise.song().transport.track_headroom = math.db2lin(dB)
renoise.song().transport.track_headroom, _observable
  -> [number, math.db2lin(-12)-math.db2lin(0)]  
  
-- Computer Keyboard Velocity.
-- Will return the default value of 127 when keyboard_velocity_enabled == false.
renoise.song().transport.keyboard_velocity_enabled, _observable
  -> [boolean] 
renoise.song().transport.keyboard_velocity, _observable
  -> [number, 0-127]  
  
  
--------------------------------------------------------------------------------
-- renoise.PatternSequencer
--------------------------------------------------------------------------------

-------- Functions

-- Insert the specified pattern at the given position in the sequence.
renoise.song().sequencer:insert_sequence_at(sequence_pos, pattern_index)
-- Insert an empty, unreferenced pattern at the given position.
renoise.song().sequencer:insert_new_pattern_at(sequence_pos)
  -> [number, new pattern index]
-- Delete an existing position in the sequence. Renoise needs at least one
-- sequence in the song for playback. Completely removing all sequence positions
-- is not allowed.
renoise.song().sequencer:delete_sequence_at(sequence_pos)

-- Access to a single sequence by index (the pattern number). Use properties 
-- 'pattern_sequence' to iterate over the whole sequence and to query the 
-- sequence count.
renoise.song().sequencer:pattern(sequence_pos)
  -> [number, pattern index]

-- Clone a sequence range, appending it right after to_sequence_pos.
-- Slot muting is copied as well.
renoise.song().sequencer:clone_range(from_sequence_pos, to_sequence_pos)
-- Make patterns in the given sequence pos range unique, if needed.
renoise.song().sequencer:make_range_unique(from_sequence_pos, to_sequence_pos)

-- Sort patterns in the sequence in ascending order, keeping the old pattern
-- data in place. Aka, this will only change the visual order of patterns, but
-- not change the song's structure.
renoise.song().sequencer:sort()


-- Access to pattern sequence sections. When the 'is_start_of_section flag' is 
-- set for a sequence pos, a section ranges from this pos to the next pos
-- which starts a section, or till the end of the song when there are no others.
renoise.song().sequencer:sequence_is_start_of_section(sequence_index) 
  -> [boolean]
renoise.song().sequencer:set_sequence_is_start_of_section(
  sequence_index, true_or_false) 
renoise.song().sequencer:sequence_is_start_of_section_observable(sequence_index) 
  -> [renoise.Observable object]

-- Access to a pattern sequence section's name. Section names are only visible
-- for a sequence pos which starts the section (see sequence_is_start_of_section).
renoise.song().sequencer:sequence_section_name(sequence_index) 
  -> [string]
renoise.song().sequencer:set_sequence_section_name(sequence_index, string) 
renoise.song().sequencer:sequence_section_name_observable(sequence_index) 
  -> [renoise.Observable object]

-- Returns true if the given sequence pos is part of a section, else false.
renoise.song().sequencer:sequence_is_part_of_section(sequence_index) 
  -> [boolean]
-- Returns true if the given sequence pos is the end of a section, else false
renoise.song().sequencer:sequence_is_end_of_section(sequence_index) 
  -> [boolean]
  

-- Observable, which is fired, whenever the section layout in the sequence
-- changed in any way, i.e. new sections got added, existing ones got deleted
renoise.song().sequencer:sequence_sections_changed_observable() 
  -> [renoise.Observable object]


-- Access to sequencer slot mute states. Mute slots are memorized in the
-- sequencer and not in the patterns.
renoise.song().sequencer:track_sequence_slot_is_muted(track_index, sequence_index)
  -> [boolean]
renoise.song().sequencer:set_track_sequence_slot_is_muted(
  track_index, sequence_index, muted)


-- Access to sequencer slot selection states. 
renoise.song().sequencer:track_sequence_slot_is_selected(track_index, sequence_index)
  -> [boolean]
renoise.song().sequencer:set_track_sequence_slot_is_selected(
  track_index, sequence_index, selected)


-------- Properties

-- When true, the sequence will be auto sorted.
renoise.song().sequencer.keep_sequence_sorted, _observable 
  -> [boolean]

-- Access to the selected slots in the sequencer. When no selection is present
-- {0,0} is returned, else a range between (1-#sequencer.pattern_sequence)
renoise.song().sequencer.selection_range[], _observable
  -> [array of two numbers, a range]

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
  -> [iterator with pos, line (renoise.PatternLine object)]

-- Iterate over all note/effect_ columns in the song.
renoise.song().pattern_iterator:note_columns_in_song(boolean visible_only)
  -> [iterator with pos, column (renoise.NoteColumn object)]
renoise.song().pattern_iterator:effect_columns_in_song(boolean visible_only)
  -> [iterator with pos, column (renoise.EffectColumn object)]


------- Pattern

-- Iterate over all lines in the given pattern only.
renoise.song().pattern_iterator:lines_in_pattern(pattern_index)
  -> [iterator with pos, line (renoise.PatternLine object)]

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
  -> [iterator with pos, column (renoise.PatternLine object)]

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
  -> [iterator with pos, line (renoise.PatternLine object)]

-- Iterate over all note/effect columns in the specified pattern track.
renoise.song().pattern_iterator:note_columns_in_pattern_track(
  pattern_index, track_index, boolean visible_only)
  -> [iterator with pos, column (renoise.NoteColumn object)]

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
renoise.Track.TRACK_TYPE_GROUP

renoise.Track.MUTE_STATE_ACTIVE
renoise.Track.MUTE_STATE_OFF
renoise.Track.MUTE_STATE_MUTED


-------- Functions

-- Insert a new device at the given position. "device_path" must be one of
-- renoise.song().tracks[].available_devices.
renoise.song().tracks[]:insert_device_at(device_path, device_index)
  -> [newly created renoise.AudioDevice object]
-- Delete an existing device in a track. The mixer device at index 1 can not
-- be deleted from a track.
renoise.song().tracks[]:delete_device_at(device_index)
-- Swap the positions of two devices in the device chain. The mixer device at
-- index 1 can not be swapped or moved.
renoise.song().tracks[]:swap_devices_at(device_index1, device_index2)

-- Access to a single device by index. Use properties 'devices' to iterate 
-- over all devices and to query the device count.
renoise.song().tracks:device(index)
  -> [renoise.AudioDevice object]

-- Uses default mute state from the prefs. Not for the master track.
renoise.song().tracks[]:mute()
renoise.song().tracks[]:unmute()
renoise.song().tracks[]:solo()

-- Note column mutes. Only valid within (1-track.max_note_columns)
renoise.song().tracks[]:column_is_muted(column)
  -> [boolean]
renoise.song().tracks[]:column_is_muted_observable(column)
  -> [Observable object]
renoise.song().tracks[]:set_column_is_muted(column, muted)

-- Note column names. Only valid within (1-track.max_note_columns)
renoise.song().tracks[]:column_name(column)
  -> [string]
renoise.song().tracks[]:column_name_observable(column)
  -> [Observable object]
renoise.song().tracks[]:set_column_name(column, name)

-- Swap the positions of two note or effect columns within a track.
renoise.song().tracks[]:swap_note_columns_at(index1, index2)
renoise.song().tracks[]:swap_effect_columns_at(index1, index2)


-------- Properties

-- Type, name, color.
renoise.song().tracks[].type
  -> [read-only, enum = TRACK_TYPE]
renoise.song().tracks[].name, _observable
  -> [string]
renoise.song().tracks[].color[], _observable
  -> [array of 3 numbers (0-0xFF), RGB]

renoise.song().tracks[].color_blend, _observable
  -> [number, 0-100]

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

-- Collapsed/expanded visual appearance.
renoise.song().tracks[].collapsed, _observable
  -> [boolean]

-- Returns most immediate group parent or nil if not in a group.
renoise.song().tracks[].group_parent
  -> [renoise.GroupTrack object or nil]

-- Output routing.
renoise.song().tracks[].available_output_routings[]
  -> [read-only, array of strings]
renoise.song().tracks[].output_routing, _observable
  -> [string, one of 'available_output_routings']

-- Delay.
renoise.song().tracks[].output_delay, _observable
  -> [number, -100.0-100.0]

-- Pattern editor columns.
renoise.song().tracks[].max_effect_columns
  -> [read-only, number, 8 OR 0 depending on the track type]
renoise.song().tracks[].min_effect_columns
  -> [read-only, number, 1 OR 0 depending on the track type]

renoise.song().tracks[].max_note_columns
  -> [read-only, number, 12 OR 0 depending on the track type]
renoise.song().tracks[].min_note_columns
  -> [read-only, number, 1 OR 0 depending on the track type]

renoise.song().tracks[].visible_effect_columns, _observable
  -> [number, 1-8 OR 0-8, depending on the track type]
renoise.song().tracks[].visible_note_columns, _observable
  -> [number, 0 OR 1-12, depending on the track type]

renoise.song().tracks[].volume_column_visible, _observable
  -> [boolean]
renoise.song().tracks[].panning_column_visible, _observable
  -> [boolean]
renoise.song().tracks[].delay_column_visible, _observable
  -> [boolean]
renoise.song().tracks[].sample_effects_column_visible, _observable
  -> [boolean]

-- Devices.
renoise.song().tracks[].available_devices[]
  -> [read-only, array of strings]

-- Returns a list of tables containing more information about the devices. 
-- Each table has the following fields:
--  {
--    path,           -- The device's path used by insert_device_at()
--    name,           -- The device's name
--    short_name,     -- The device's name as displayed in shortened lists
--    favorite_name,  -- The device's name as displayed in favorites
--    is_favorite,    -- true if the device is a favorite
--    is_bridged      -- true if the device is a bridged plugin
--  }
renoise.song().tracks[].available_device_infos[]
  -> [read-only, array of strings]

renoise.song().tracks[].devices[], _observable
  -> [read-only, array of renoise.AudioDevice objects]


--------------------------------------------------------------------------------
-- renoise.GroupTrack (inherits from renoise.Track)
--------------------------------------------------------------------------------

-------- Functions

-- All member tracks of this group (including subgroups and their tracks).
renoise.song().tracks[].members[]
  -> [read-only, array of member tracks]

-- Collapsed/expanded visual appearance of whole group.
renoise.song().tracks[].group_collapsed
  -> [boolean]


--------------------------------------------------------------------------------
-- renoise.TrackDevice
--------------------------------------------------------------------------------

-- DEPRECATED - alias for renoise.AudioDevice


--------------------------------------------------------------------------------
-- renoise.AudioDevice
--------------------------------------------------------------------------------

-------- Functions

-- Access to a single preset name by index. Use properties 'presets' to iterate 
-- over all presets and to query the presets count.
renoise.song().tracks[].devices[]:preset(index)
  -> [string]

-- Access to a single parameter by index. Use properties 'parameters' to iterate 
-- over all parameters and to query the parameter count.
renoise.song().tracks[].devices[]:parameter(index)
  -> [renoise.DeviceParameter object]


-------- Properties

-- Fixed name of the device.
renoise.song().tracks[].devices[].name
  -> [read-only, string]
renoise.song().tracks[].devices[].short_name
  -> [read-only, string]

-- Configurable device display name.
renoise.song().tracks[].devices[].display_name, observable 
  -> [string, long device name or custom name]

-- Enable/bypass the device.
renoise.song().tracks[].devices[].is_active, _observable
  -> [boolean, not active = bypassed]

-- Maximize state in DSP chain.
renoise.song().tracks[].devices[].is_maximized, _observable
  -> [boolean]

-- Preset handling.
renoise.song().tracks[].devices[].active_preset, _observable
  -> [number, 0 when none is active or available]
renoise.song().tracks[].devices[].active_preset_data
  -> [string, raw serialized data in XML format of the active preset]
renoise.song().tracks[].devices[].presets[]
  -> [read-only, array of strings]

-- Parameters.
renoise.song().tracks[].devices[].is_active_parameter
  -> [read-only, renoise.DeviceParameter object]

renoise.song().tracks[].devices[].parameters[]
  -> [read-only, array of renoise.DeviceParameter objects]

-- Returns whether or not the device provides its own custom GUI (only 
-- available for some plugin devices)
renoise.song().tracks[].devices[].external_editor_available
  -> [read-only, boolean]

-- When the device has no custom GUI an error will be fired (see
-- external_editor_available), otherwise the external editor is opened/closed.
renoise.song().tracks[].devices[].external_editor_visible
  -> [boolean, true to show the editor, false to close it]
  
-- Returns a string that uniquely identifies the device, from "available_devices".
-- The string can be passed into: renoise.song().tracks[]:insert_device_at()
renoise.song().tracks[].devices[].device_path
  -> [read-only, string]


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
  -> [read-only, enum = POLARITY]

renoise.song().tracks[].devices[].parameters[].value_min
  -> [read-only, number]
renoise.song().tracks[].devices[].parameters[].value_max
  -> [read-only, number]
renoise.song().tracks[].devices[].parameters[].value_quantum
  -> [read-only, number]
renoise.song().tracks[].devices[].parameters[].value_default
  -> [read-only, number]

-- The minimum interval in pattern lines (as a number) at which a parameter can
-- have automation points. It is 1/256 for most parameters, but 1 for e.g. song
-- tempo, LPB and TPL which can only be automated once per pattern line.
renoise.song().tracks[].devices[].parameters[].time_quantum
  -> [read-only, number]

-- Not valid for parameters of instrument devices. Returns true if creating
-- envelope automation is possible for the parameter (see also
-- renoise.song().patterns[].tracks[]:create_automation)
renoise.song().tracks[].devices[].parameters[].is_automatable
  -> [read-only, boolean]

-- Is automated. Not valid for parameters of instrument devices.
renoise.song().tracks[].devices[].parameters[].is_automated, _observable
  -> [read-only, boolean]

-- parameter has a custom MIDI mapping in the current song.
renoise.song().tracks[].devices[].parameters[].is_midi_mapped, _observable 
  -> [read-only, boolean]
  
-- Show in mixer. Not valid for parameters of instrument devices.
renoise.song().tracks[].devices[].parameters[].show_in_mixer, _observable
  -> [boolean]

-- Values.
renoise.song().tracks[].devices[].parameters[].value, _observable
  -> [number]
renoise.song().tracks[].devices[].parameters[].value_string, _observable
  -> [string]


--------------------------------------------------------------------------------
-- renoise.Instrument
--------------------------------------------------------------------------------

-------- Constants

renoise.Instrument.TAB_SAMPLES
renoise.Instrument.TAB_PLUGIN
renoise.Instrument.TAB_EXT_MIDI

renoise.Instrument.PHRASES_OFF
renoise.Instrument.PHRASES_PLAY_SELECTIVE
renoise.Instrument.PHRASES_PLAY_KEYMAP

renoise.Instrument.LAYER_NOTE_DISABLED
renoise.Instrument.LAYER_NOTE_ON
renoise.Instrument.LAYER_NOTE_OFF

renoise.Instrument.OVERLAP_MODE_ALL
renoise.Instrument.OVERLAP_MODE_CYCLED
renoise.Instrument.OVERLAP_MODE_RANDOM

renoise.Instrument.NUMBER_OF_MACROS

renoise.Instrument.MAX_NUMBER_OF_PHRASES


-------- Functions

-- Reset, clear all settings and all samples.
renoise.song().instruments[]:clear()

-- Copy all settings from the other instrument, including all samples.
renoise.song().instruments[]:copy_from(
  other renoise.Instrument object)


-- Access a single macro by index [1-NUMBER_OF_MACROS].
-- See also property 'macros'.
renoise.song().instruments[]:macro(index) 
 -> [returns renoise.InstrumentMacro]


-- Insert a new phrase behind the given phrase index (1 for the first one).
renoise.song().instruments[]:insert_phrase_at(index) 
  -> [returns newly created renoise.InstrumentPhrase]
-- Delete a new phrase at the given phrase index.
renoise.song().instruments[]:delete_phrase_at(index)
  
-- Access a single phrase by index. Use properties 'phrases' to iterate
-- over all phrases and to query the phrase count.
renoise.song().instruments[]:phrase(index)
  -> [renoise.InstrumentPhrase object]

-- Returns true if a new phrase mapping can be inserted at the given 
-- phrase mapping index (see See renoise.song().instruments[].phrase_mappings). 
-- Passed phrase must exist and must not have a mapping yet.
-- Phrase note mappings may not overlap and are sorted by note, so there
-- can be max 119 phrases per instrument when each phrase is mapped to
-- a single key only. To make up room for new phrases, access phrases by 
-- index, adjust their note_range, then call 'insert_phrase_mapping_at' again.
renoise.song().instruments[]:can_insert_phrase_mapping_at(index) 
  -> [boolean]
-- Insert a new phrase mapping behind the given phrase mapping index.
-- The new phrase mapping will by default use the entire free (note) range 
-- between the previous and next phrase (if any). To adjust the note range 
-- of the new phrase change its 'new_phrase_mapping.note_range' property. 
renoise.song().instruments[]:insert_phrase_mapping_at(index, phrase) 
  -> [returns newly created renoise.InstrumentPhraseMapping]
-- Delete a new phrase mapping at the given phrase mapping index.
renoise.song().instruments[]:delete_phrase_mapping_at(index)

-- Access to a phrase note mapping by index. Use property 'phrase_mappings' to
-- iterate over all phrase mappings and to query the phrase (mapping) count.
renoise.song().instruments[]:phrase_mapping(index)
  -> [renoise.InstrumentPhraseMapping object]

-- Insert a new empty sample. returns the new renoise.Sample object.
-- Every newly inserted sample has a default mapping, which covers the 
-- entire key and velocity range, or it gets added as drum kit mapping 
-- when the instrument used a drum-kit mapping before the sample got added.
renoise.song().instruments[]:insert_sample_at(index)
  -> [new renoise.Sample object]
-- Delete an existing sample.
renoise.song().instruments[]:delete_sample_at(index)
-- Swap positions of two samples.
renoise.song().instruments[]:swap_samples_at(index1, index2)

-- Access to a single sample by index. Use properties 'samples' to iterate
-- over all samples and to query the sample count.
renoise.song().instruments[]:sample(index)
  -> [renoise.Sample object]

-- Access to a sample mapping by index. Use property 'sample_mappings' to
-- iterate over all sample mappings and to query the sample (mapping) count.
renoise.song().instruments[]:sample_mapping(layer, index)
  -> [renoise.SampleMapping object]

-- Insert a new modulation set at the given index
renoise.song().instruments[]:insert_sample_modulation_set_at(index) 
  -> [new renoise.SampleModulationSet object]
-- Delete an existing modulation set at the given index.
renoise.song().instruments[]:delete_sample_modulation_set_at(index)
-- Swap positions of two modulation sets.
renoise.song().instruments[]:swap_sample_modulation_sets_at(index1, index2)
  
-- Access to a single sample modulation set by index. Use property 
-- 'sample_modulation_sets' to iterate over all sets and to query the set count.
renoise.song().instruments[]:sample_modulation_set(index) 
  -> [renoise.SampleModulationSet object]

-- Insert a new sample device chain at the given index.
renoise.song().instruments[]:insert_sample_device_chain_at(index) 
  -> [returns newly created renoise.SampleDeviceChain]
-- Delete an existing sample device chain at the given index.
renoise.song().instruments[]:delete_sample_device_chain_at(index)
-- Swap positions of two sample device chains.
renoise.song().instruments[]:swap_sample_device_chains_at(index1, index2)

-- Access to a single device chain by index. Use property 'sample_device_chains' 
-- to iterate over all chains and to query the chain count.
renoise.song().instruments[]:sample_device_chain(index) 
  -> [renoise.SampleDeviceChain object]


-------- Properties

-- Currently active tab in the instrument GUI (samples, plugin or MIDI).
renoise.song().instruments[].active_tab, _observable 
  -> [enum = TAB]

-- Instrument's name.
renoise.song().instruments[].name, _observable
  -> [string]

-- Instrument's comment list. See renoise.song().comments for more info on
-- how to get notified on changes and how to change it.
renoise.song().instruments[].comments[], _observable
  -> [array of strings]
-- Notifier which is called as soon as any paragraph in the comments change.
renoise.song().instruments[].comments_assignment_observable
  -> [renoise.Observable object]
-- Set this to true to show the comments dialog after loading a song
renoise.song().instruments[].show_comments_after_loading, _observable 
  -> [boolean]

-- Macro parameter pane visibility in the GUI.
renoise.song().instruments[].macros_visible, _observable
 -> [boolean]

-- Macro parameters.
renoise.song().instruments[].macros[]
  -> [read-only, array of NUMBER_OF_MACROS renoise.InstrumentMacro objects]

-- Access the MIDI pitch-bend macro
renoise.song().instruments[].pitchbend_macro 
 -> [returns renoise.InstrumentMacro]

-- Access the MIDI modulation-wheel macro
renoise.song().instruments[].modulation_wheel_macro 
 -> [returns renoise.InstrumentMacro]

-- Access the MIDI channel pressure macro
renoise.song().instruments[].channel_pressure_macro 
 -> [returns renoise.InstrumentMacro]

-- Global linear volume of the instrument. Applied to all samples, MIDI and
-- plugins in the instrument.
renoise.song().instruments[].volume, _observable
 -> [number, 0-math.db2lin(6)]

-- Global relative pitch in semi tones. Applied to all samples, MIDI and 
-- plugins in the instrument.
renoise.song().instruments[].transpose, _observable
 -> [number, -120-120]

-- Global trigger options (quantization and scaling options). 
-- See renoise.InstrumentTriggerOptions for more info.
renoise.song().instruments[].trigger_options
  -> [renoise.InstrumentTriggerOptions object]

-- Sample mapping's overlap trigger mode.
renoise.song().instruments[]:sample_mapping_overlap_mode, observable
  -> [enum=OVERLAP_MODE]


-- Phrase editor pane visibility in the GUI.
renoise.song().instruments[].phrase_editor_visible, _observable
 -> [boolean]

-- Phrase playback. See PHRASES_XXX values.
renoise.song().instruments[].phrase_playback_mode, _observable
 -> [enum=PHRASES]
-- Phrase playback program: 0 = Off, 1-126 = specific phrase, 127 = keymap.
renoise.song().instruments[].phrase_program, _observable
 -> [number]

-- Phrases.
renoise.song().instruments[].phrases[], _observable 
  -> [read-only, array of renoise.InstrumentPhrase objects]
-- Phrase mappings.
renoise.song().instruments[].phrase_mappings[], _observable 
  -> [read-only, array of renoise.InstrumentPhraseMapping objects]
  

-- Samples slots.
renoise.song().instruments[].samples[], _observable
  -> [read-only, array of renoise.Sample objects]

-- Sample mappings (key/velocity to sample slot mappings).
-- sample_mappings[LAYER_NOTE_ON/OFF][]. Sample mappings also can 
-- be accessed via renoise.song().instruments[].samples[].sample_mapping
renoise.song().instruments[].sample_mappings[], _observable
  -> [read-only, array of tables of renoise.SampleMapping objects]

-- Sample modulation sets.
renoise.song().instruments[].sample_modulation_sets, _observable
  -> [read-only, table of renoise.SampleModulationSet objects]

-- Sample device chains.
renoise.song().instruments[].sample_device_chains
  -> [read-only, table of renoise.SampleDeviceChain objects]
  
-- MIDI input properties.
renoise.song().instruments[].midi_input_properties
  -> [read-only, renoise.InstrumentMidiInputProperties object]
  
-- MIDI output properties.
renoise.song().instruments[].midi_output_properties
  -> [read-only, renoise.InstrumentMidiOutputProperties object]

-- Plugin properties.
renoise.song().instruments[].plugin_properties
  -> [read-only, renoise.InstrumentPluginProperties object]


--------------------------------------------------------------------------------
-- renoise.InstrumentTriggerOptions
--------------------------------------------------------------------------------

-------- Constants

renoise.InstrumentTriggerOptions.QUANTIZE_NONE 
renoise.InstrumentTriggerOptions.QUANTIZE_LINE
renoise.InstrumentTriggerOptions.QUANTIZE_BEAT
renoise.InstrumentTriggerOptions.QUANTIZE_BAR


-------- Properties

-- List of all available scale modes.
renoise.song().instruments[].trigger_options.available_scale_modes
  -> [read-only, table of strings]

-- Scale to use when transposing. One of 'available_scales'.
renoise.song().instruments[].trigger_options.scale_mode, _observable
  -> [string, one of 'available_scales']

-- Scale-key to use when transposing (1=C, 2=C#, 3=D, ...)
renoise.song().instruments[].trigger_options.scale_key, _observable
  -> [number]

-- Trigger quantization mode.
renoise.song().instruments[].trigger_options.quantize, _observable
  -> [enum = QUANTIZE]

-- Mono/Poly mode.
renoise.song().instruments[].trigger_options.monophonic, _observable
  -> [boolean]

-- Glide amount when monophonic. 0 == off, 255 = instant
renoise.song().instruments[].trigger_options.monophonic_glide, _observable
  -> [number]


--------------------------------------------------------------------------------
-- renoise.InstrumentMacro
--------------------------------------------------------------------------------

-------- Functions

-- Access to a single attached parameter mapping by index. Use property
-- 'mappings' to query mapping count.
renoise.song().instruments[].macros[]:mapping(index) 
  -> [renoise.InstrumentMacroMapping object]
  

-------- Properties

-- Macro name as visible in the GUI when mappings are presents.
renoise.song().instruments[].macros[].name, _observable 
  -> [string]

-- Macro value.
renoise.song().instruments[].macros[].value, _observable 
  -> [number, 0-1]
-- Macro value string (0-100).
renoise.song().instruments[].macros[].value_string, _observable 
  -> [string]

-- Macro mappings, target parameters.
renoise.song().instruments[].macros[].mappings[], _observable
  -> [read-only, array of renoise.InstrumentMacroMapping objects]


--------------------------------------------------------------------------------
-- renoise.InstrumentMacroMapping
--------------------------------------------------------------------------------

-------- Constants

renoise.InstrumentMacroMapping.SCALING_LOG_FAST
renoise.InstrumentMacroMapping.SCALING_LOG_SLOW
renoise.InstrumentMacroMapping.SCALING_LINEAR
renoise.InstrumentMacroMapping.SCALING_EXP_SLOW
renoise.InstrumentMacroMapping.SCALING_EXP_FAST


-------- Properties

-- Linked parameter. Can be a sample FX- or modulation parameter. Never nil.
renoise.song().instruments[].macros[].mappings[].parameter
  -> [read-only, renoise.DeviceParameter]

-- Min/max range in which the macro applies its value to the target parameter.
-- Max can be < than Min. Mapping is then flipped.
renoise.song().instruments[].macros[].mappings[].parameter_min, _observable
  -> [number, 0-1]
renoise.song().instruments[].macros[].mappings[].parameter_max, _observable
  -> [number, 0-1]
  
-- Scaling which gets applied within the min/max range to set the dest value.
renoise.song().instruments[].macros[].mappings[].parameter_scaling, _observable
  -> [enum = SCALING]

  
--------------------------------------------------------------------------------
-- renoise.InstrumentPhrase
--------------------------------------------------------------------------------

-- General remarks: Phrases do use renoise.PatternLine objects just like the 
-- pattern tracks do. When the instrument column is enabled and used, 
-- not instruments, but samples are addressed/triggered in phrases.


-------- Constants

-- Maximum number of lines that can be present in a phrase.
renoise.InstrumentPhrase.MAX_NUMBER_OF_LINES

-- Min/Maximum number of note columns that can be present in a phrase.
renoise.InstrumentPhrase.MIN_NUMBER_OF_NOTE_COLUMNS
renoise.InstrumentPhrase.MAX_NUMBER_OF_NOTE_COLUMNS

-- Min/Maximum number of effect columns that can be present in a phrase.
renoise.InstrumentPhrase.MIN_NUMBER_OF_EFFECT_COLUMNS
renoise.InstrumentPhrase.MAX_NUMBER_OF_EFFECT_COLUMNS

-- See InstrumentPhraseMapping KEY_TRACKING
renoise.InstrumentPhrase.KEY_TRACKING_NONE
renoise.InstrumentPhrase.KEY_TRACKING_TRANSPOSE
renoise.InstrumentPhrase.KEY_TRACKING_OFFSET


-------- Functions

-- Deletes all lines.
renoise.song().instruments[].phrases[]:clear()

-- Copy contents from another phrase.
renoise.song().instruments[].phrases[]:copy_from(
  other renoise.InstrumentPhrase object)

-- Access to a single line by index. Line must be [1-MAX_NUMBER_OF_LINES]). 
-- This is a !lot! more efficient than calling the property: lines[index] to
-- randomly access lines.
renoise.song().instruments[].phrases[]:line(index)
  -> [renoise.PatternLine object]
-- Get a specific line range (index must be [1-MAX_NUMBER_OF_LINES])
renoise.song().instruments[].phrases[]:lines_in_range(index_from, index_to)
  -> [array of renoise.PatternLine objects]

-- Check/add/remove notifier functions or methods, which are called by 
-- Renoise as soon as any of the phrases's lines have changed.
-- See renoise.song().patterns[]:has_line_notifier for more details.
renoise.song().instruments[].phrases[]:has_line_notifier(func [, obj])
  -> [boolean]
renoise.song().instruments[].phrases[]:add_line_notifier(func [, obj])
renoise.song().instruments[].phrases[]:remove_line_notifier(func [, obj])

-- Same as line_notifier above, but the notifier only fires when the user
-- added, changed or deleted a line with the computer keyboard.
renoise.song().instruments[].phrases[]:has_line_edited_notifier(func [, obj])
  -> [boolean]
renoise.song().instruments[].phrases[]:add_line_edited_notifier(func [, obj])
renoise.song().instruments[].phrases[]:remove_line_edited_notifier(func [, obj])

-- Note column mute states. Only valid within (1-MAX_NUMBER_OF_NOTE_COLUMNS)
renoise.song().instruments[].phrases[]:column_is_muted(column)
  -> [boolean]
renoise.song().instruments[].phrases[]:column_is_muted_observable(column)
  -> [Observable object]
renoise.song().instruments[].phrases[]:set_column_is_muted(column, muted)

-- Note column names. Only valid within (1-MAX_NUMBER_OF_NOTE_COLUMNS)
renoise.song().instruments[].phrases[]:column_name(column)
  -> [string]
renoise.song().instruments[].phrases[]:column_name_observable(column)
  -> [Observable object]
renoise.song().instruments[].phrases[]:set_column_name(column, name)

-- Swap the positions of two note or effect columns within a phrase.
renoise.song().instruments[].phrases[]:swap_note_columns_at(index1, index2)
renoise.song().instruments[].phrases[]:swap_effect_columns_at(index1, index2)


-------- Properties

-- Name of the phrase as visible in the phrase editor and piano mappings.
renoise.song().instruments[].phrases[].name, _observable
  -> [string]

-- (Key)Mapping properties of the phrase or nil when no mapping is present.
renoise.song().instruments[].phrases[].mapping
  -> [renoise.InstrumentPhraseMapping object or nil]

-- Quickly check if a phrase has some non empty pattern lines.
renoise.song().instruments[].phrases[].is_empty, _observable
  -> [read-only, boolean]

-- Number of lines the phrase currently has. 16 by default. Max is
-- renoise.InstrumentPhrase.MAX_NUMBER_OF_LINES, min is 1.
renoise.song().instruments[].phrases[].number_of_lines, _observable
  -> [number, 1-MAX_NUMBER_OF_LINES]

-- Get all lines in a range [1, number_of_lines_in_pattern]
renoise.song().instruments[].phrases[].lines[]
  -> [read-only, array of renoise.PatternLine objects]

-- How many note columns are visible in the phrase.
renoise.song().instruments[].phrases[].visible_note_columns, _observable 
  -> [number, MIN_NUMBER_OF_NOTE_COLUMNS-MAX_NUMBER_OF_NOTE_COLUMNS]
-- How many effect columns are visible in the phrase.
renoise.song().instruments[].phrases[].visible_effect_columns, _observable
  -> [number, MIN_NUMBER_OF_EFFECT_COLUMNS-MAX_NUMBER_OF_EFFECT_COLUMNS]

-- Phrase's key-tracking mode.
renoise.song().instruments[].phrases[].key_tracking, _observable 
  -> [enum = KEY_TRACKING]

-- Phrase's base-note. Only relevant when key_tracking is set to transpose.
renoise.song().instruments[].phrases[].base_note, _observable 
  -> [number, 0-119, c-4=48]

-- Loop mode. The phrase plays as one-shot when disabled.
renoise.song().instruments[].phrases[].looping, _observable 
  -> [boolean]

-- Loop start. Playback will start from the beginning before entering loop
renoise.song().instruments[].phrases[].loop_start, _observable 
  -> [number, 1-number_of_lines]
-- Loop end. Needs to be > loop_start and <= number_of_lines
renoise.song().instruments[].phrases[].loop_end, _observable 
  -> [number, loop_start-number_of_lines]

-- Phrase autoseek settings.
renoisesong().instruments[].phrases[].autoseek, _observable
  -> [boolean]

-- Phrase local lines per beat setting. New phrases get initialized with 
-- the song's current LPB setting. TPL can not be configured in phrases.
renoise.song().instruments[].phrases[].lpb, _observable
  -> [number, 1-256]
  
-- Shuffle groove amount for a phrase. 
-- 0.0 = no shuffle (off), 1.0 = full shuffle 
renoise.song().instruments[].phrases[].shuffle, _observable
  -> [number, 0-1]

-- Column visibility.
renoise.song().instruments[].phrases[].instrument_column_visible, _observable
  -> [boolean]
renoise.song().instruments[].phrases[].volume_column_visible, _observable 
  -> [boolean]
renoise.song().instruments[].phrases[].panning_column_visible, _observable 
  -> [boolean]
renoise.song().instruments[].phrases[].delay_column_visible, _observable 
  -> [boolean]
renoise.song().instruments[].phrases[].sample_effects_column_visible, _observable 
  -> [boolean]

-------- Operators

-- Compares line content. All other properties are ignored.
==(InstrumentPhrase object, InstrumentPhrase object) 
  -> [boolean]
~=(InstrumentPhrase object, InstrumentPhrase object) 
  -> [boolean]


--------------------------------------------------------------------------------
-- renoise.InstrumentPhraseMapping
--------------------------------------------------------------------------------

-------- Constants

-- Every note plays back the phrase unpitched from line 1.
renoise.InstrumentPhraseMapping.KEY_TRACKING_NONE
-- Play the phrase transposed relative to the phrase's base_note.
renoise.InstrumentPhraseMapping.KEY_TRACKING_TRANSPOSE
-- Trigger phrase from the beginning (note_range start) up to the end (note_range end).
renoise.InstrumentPhraseMapping.KEY_TRACKING_OFFSET


-------- Properties

-- Linked phrase.
renoise.song().instruments[].phrases[].mapping.phrase
  -> [renoise.InstrumentPhrase object]

-- Phrase's key-tracking mode.
renoise.song().instruments[].phrases[].mapping.key_tracking, _observable 
  -> [enum = KEY_TRACKING]

-- Phrase's base-note. Only relevant when key_tracking is set to transpose.
renoise.song().instruments[].phrases[].mapping.base_note, _observable 
  -> [number, 0-119, c-4=48]

-- Note range the mapping is triggered at. Phrases may not overlap, so
-- note_range start can only be set behind previous's (if any) end and
-- note_range end can only be set before next mapping's (if any) start.
renoise.song().instruments[].phrases[].mapping.note_range, _observable 
  -> [table with two numbers (0-119, c-4=48)]

-- Loop mode. The phrase plays as one-shot when disabled.
renoise.song().instruments[].phrases[].mapping.looping, _observable 
  -> [boolean]
renoise.song().instruments[].phrases[].mapping.loop_start, _observable 
  -> [number]
renoise.song().instruments[].phrases[].mapping.loop_end, _observable 
  -> [number]


--------------------------------------------------------------------------------
-- renoise.InstrumentMidiInputProperties
--------------------------------------------------------------------------------

-------- Properties

-- When setting new devices, device names must be one of
-- renoise.Midi.available_input_devices.
-- Devices are automatically opened when needed. To close a device, set its 
-- name to "", e.g. an empty string.
renoise.song().instruments[].midi_input_properties.device_name, _observable
  -> [string]
renoise.song().instruments[].midi_input_properties.channel, _observable
  -> [number, 1-16, 0=Omni]
renoise.song().instruments[].midi_input_properties.note_range, _observable 
  -> [table with two numbers (0-119, c-4=48)]
renoise.song().instruments[].midi_input_properties.assigned_track, _observable
  -> [number, 1-renoise.song().sequencer_track_count, 0 = Current track]


--------------------------------------------------------------------------------
-- renoise.SampleModulationDevice
--------------------------------------------------------------------------------

--------- Constants

renoise.SampleModulationDevice.TARGET_VOLUME
renoise.SampleModulationDevice.TARGET_PANNING
renoise.SampleModulationDevice.TARGET_PITCH
renoise.SampleModulationDevice.TARGET_CUTOFF
renoise.SampleModulationDevice.TARGET_RESONANCE
renoise.SampleModulationDevice.TARGET_DRIVE

renoise.SampleModulationDevice.OPERATOR_ADD
renoise.SampleModulationDevice.OPERATOR_SUB
renoise.SampleModulationDevice.OPERATOR_MUL
renoise.SampleModulationDevice.OPERATOR_DIV

  
--------- functions

-- Reset the device to its default state.
renoise.song().instruments[].sample_modulation_sets[].devices[]:init()

-- Copy a device's state from another device. 'other_device' must be of the
-- same type.
renoise.song().instruments[].sample_modulation_sets[].devices[]:copy_from(
  other renoise.SampleModulationDevice object)

-- Access to a single parameter by index. Use properties 'parameters' to iterate 
-- over all parameters and to query the parameter count.
renoise.song().instruments[].sample_modulation_sets[].devices[]:parameter(index)
  -> [renoise.DeviceParameter object]

--------- properties

-- Fixed name of the device.
renoise.song().instruments[].sample_modulation_sets[].devices[].name
  -> [read-only, string]
renoise.song().instruments[].sample_modulation_sets[].devices[].short_name
  -> [read-only, string]

-- Configurable device display name.
renoise.song().instruments[].sample_modulation_sets[].devices[].display_name, observable 
  -> [string]

-- DEPRECATED: use 'is_active' instead
renoise.song().instruments[].sample_modulation_sets[].devices[].enabled, _observable
  -> [boolean]
-- Enable/bypass the device.
renoise.song().instruments[].sample_modulation_sets[].devices[].is_active, _observable
  -> [boolean, not active = bypassed]

-- Maximize state in modulation chain.
renoise.song().instruments[].sample_modulation_sets[].devices[].is_maximized, _observable
  -> [boolean]

-- Where the modulation gets applied (Volume, Pan, Pitch, Cutoff, Resonance).
renoise.song().instruments[].sample_modulation_sets[].devices[].target 
  -> [read-only, enum = TARGET]

-- Modulation operator: how the device applies.
renoise.song().instruments[].sample_modulation_sets[].devices[].operator, _observable
  -> [enum = OPERATOR]

-- Modulation polarity: when bipolar, the device applies it's values in a -1 to 1 range,
-- when unipolar in a 0 to 1 range.
renoise.song().instruments[].sample_modulation_sets[].devices[].bipolar, observable
  -> [boolean]

-- When true, the device has one of more time parameters, which can be switched to operate
-- in synced or unsynced mode (see tempo_synced)
renoise.song().instruments[].sample_modulation_sets[].devices[].tempo_sync_switching_allowed
  -> [read-only, boolean]
-- When true and the device supports sync switching (see 'tempo_sync_switching_allowed'),
-- the device operates in wall-clock (ms) instead of beat times.
renoise.song().instruments[].sample_modulation_sets[].devices[].tempo_synced, observable
  -> [boolean]
  
-- Generic access to all parameters of this device.
renoise.song().instruments[].sample_modulation_sets[].devices[].is_active_parameter
  -> [read-only, renoise.DeviceParameter object]

renoise.song().instruments[].sample_modulation_sets[].devices[].parameters[]
  -> [read-only, array of renoise.DeviceParameter objects]


--------------------------------------------------------------------------------
-- renoise.SampleOperandModulationDevice (inherits from renoise.SampleModulationDevice)
--------------------------------------------------------------------------------

-------- Properties

-- Operand value.
renoise.song().instruments[].sample_modulation_sets[].devices[].value 
  -> [renoise.DeviceParameter object, -1-1]


--------------------------------------------------------------------------------
-- renoise.SampleFaderModulationDevice (inherits from renoise.SampleModulationDevice)
--------------------------------------------------------------------------------

--------- Constants

renoise.SampleFaderModulationDevice.SCALING_LOG_FAST
renoise.SampleFaderModulationDevice.SCALING_LOG_SLOW
renoise.SampleFaderModulationDevice.SCALING_LINEAR
renoise.SampleFaderModulationDevice.SCALING_EXP_SLOW
renoise.SampleFaderModulationDevice.SCALING_EXP_FAST


-------- Properties

-- Scaling mode.
renoise.song().instruments[].sample_modulation_sets[].devices[].scaling, _observable 
  -> [enum = SCALING]

-- Start & Target value.
renoise.song().instruments[].sample_modulation_sets[].devices[].from
  -> [renoise.DeviceParameter object, 0-1]
renoise.song().instruments[].sample_modulation_sets[].devices[].to
  -> [renoise.DeviceParameter object, 0-1]

-- Duration.
renoise.song().instruments[].sample_modulation_sets[].devices[].duration
  -> [renoise.DeviceParameter object, 0-1]

-- Delay.
renoise.song().instruments[].sample_modulation_sets[].devices[].delay
  -> [renoise.DeviceParameter object, 0-1]


--------------------------------------------------------------------------------
-- renoise.SampleAhdrsModulationDevice (inherits from renoise.SampleModulationDevice)
--------------------------------------------------------------------------------

-------- Properties

-- Attack duration.
renoise.song().instruments[].sample_modulation_sets[].devices[].attack
  -> [renoise.DeviceParameter object, 0-1]
  
-- Hold duration.
renoise.song().instruments[].sample_modulation_sets[].devices[].hold
  -> [renoise.DeviceParameter object, 0-1]

-- Duration.
renoise.song().instruments[].sample_modulation_sets[].devices[].duration
  -> [renoise.DeviceParameter object, 0-1]

-- Sustain amount.
renoise.song().instruments[].sample_modulation_sets[].devices[].sustain
  -> [renoise.DeviceParameter object, 0-1]

-- Release duration.
renoise.song().instruments[].sample_modulation_sets[].devices[].release
  -> [renoise.DeviceParameter object, 0-1]


--------------------------------------------------------------------------------
-- renoise.SampleKeyTrackingModulationDevice (inherits from renoise.SampleModulationDevice)
--------------------------------------------------------------------------------

-------- Properties

-- Min/Max key value.
renoise.song().instruments[].sample_modulation_sets[].devices[].min
  -> [renoise.DeviceParameter object, 0-119]
renoise.song().instruments[].sample_modulation_sets[].devices[].max
  -> [renoise.DeviceParameter object, 0-119]


--------------------------------------------------------------------------------
-- renoise.SampleVelocityTrackingModulationDevice (inherits from renoise.SampleModulationDevice)
--------------------------------------------------------------------------------

--------- Constants

renoise.SampleVelocityTrackingModulationDevice.MODE_CLAMP
renoise.SampleVelocityTrackingModulationDevice.MODE_SCALE


-------- Properties

-- Mode.
renoise.song().instruments[].sample_modulation_sets[].devices[].mode, _observable 
  -> [enum = MODE]

-- Min/Max velocity.
renoise.song().instruments[].sample_modulation_sets[].devices[].min
  -> [renoise.DeviceParameter object, 0-127]
renoise.song().instruments[].sample_modulation_sets[].devices[].max
  -> [renoise.DeviceParameter object, 0-127]


--------------------------------------------------------------------------------
-- renoise.SampleEnvelopeModulationDevice (inherits from renoise.SampleModulationDevice)
--------------------------------------------------------------------------------

--------- Constants

renoise.SampleEnvelopeModulationDevice.PLAYMODE_POINTS
renoise.SampleEnvelopeModulationDevice.PLAYMODE_LINES
renoise.SampleEnvelopeModulationDevice.PLAYMODE_CURVES

renoise.SampleEnvelopeModulationDevice.LOOP_MODE_OFF
renoise.SampleEnvelopeModulationDevice.LOOP_MODE_FORWARD
renoise.SampleEnvelopeModulationDevice.LOOP_MODE_REVERSE
renoise.SampleEnvelopeModulationDevice.LOOP_MODE_PING_PONG

renoise.SampleEnvelopeModulationDevice.MIN_NUMBER_OF_POINTS
renoise.SampleEnvelopeModulationDevice.MAX_NUMBER_OF_POINTS


-------- Functions

-- Reset the envelope back to its default initial state.
renoise.song().instruments[].sample_modulation_sets[].devices[]:init()

-- Copy all properties from another SampleEnvelopeModulation object.
renoise.song().instruments[].sample_modulation_sets[].devices[]:copy_from(
  other renoise.SampleEnvelopeModulationDevice object)

-- Remove all points from the envelope.
renoise.song().instruments[].sample_modulation_sets[].devices[]:clear_points()
-- Remove points in the given [from, to) time range from the envelope.
renoise.song().instruments[].sample_modulation_sets[].devices[]:clear_points_in_range(
--  from_time, to_time)

-- Copy all points from another SampleEnvelopeModulation object.
renoise.song().instruments[].sample_modulation_sets[].devices[]:copy_points_from(
  other SampleEnvelopeModulationDevice object)

-- Test if a point exists at the given time.
renoise.song().instruments[].sample_modulation_sets[].devices[]:has_point_at(time)
  -> [boolean]
-- Add a new point value (or replace any existing value) at time. 
renoise.song().instruments[].sample_modulation_sets[].devices[]:add_point_at(
  time, value [, scaling])
-- Removes a point at the given time. Point must exist.
renoise.song().instruments[].sample_modulation_sets[].devices[]:remove_point_at(time)


-------- Properties

-- External editor visibility.
renoise.song().instruments[].sample_modulation_sets[].devices[].external_editor_visible
 -> [boolean, set to true to show the editor, false to close it]

-- Play mode (interpolation mode).
renoise.song().instruments[].sample_modulation_sets[].devices[].play_mode, _observable
  -> [enum = PLAYMODE]

-- Envelope length.
renoise.song().instruments[].sample_modulation_sets[].devices[].length, _observable
  -> [number, 6-1000]

-- Loop.
renoise.song().instruments[].sample_modulation_sets[].devices[].loop_mode, _observable
  -> [enum = LOOP_MODE]
renoise.song().instruments[].sample_modulation_sets[].devices[].loop_start, _observable
  -> [number, 1-envelope.length]
renoise.song().instruments[].sample_modulation_sets[].devices[].loop_end, _observable
  -> [number, 1-envelope.length]

-- Sustain.
renoise.song().instruments[].sample_modulation_sets[].devices[].sustain_enabled, _observable
  -> [boolean]
renoise.song().instruments[].sample_modulation_sets[].devices[].sustain_position, _observable
  -> [number, 1-envelope.length]

-- Fade amount. (Only applies to volume envelopes)
renoise.song().instruments[].sample_modulation_sets[].devices[].fade_amount, _observable
  -> [number, 0-4095]

-- Get all points of the envelope. When setting a new list of points,
-- items may be unsorted by time, but there may not be multiple points
-- for the same time. Returns a copy of the list, so changing
-- `points[1].value` will not do anything. Instead, change them via
-- `points = { something }` instead.
renoise.song().instruments[].sample_modulation_sets[].devices[].points[], _observable
  -> [array of {time, value} tables]

-- An envelope point's time.
renoise.song().instruments[].sample_modulation_sets[].devices[].points[].time
  -> [number, 1 - envelope.length]
-- An envelope point's value.
renoise.song().instruments[].sample_modulation_sets[].devices[].points[].value
  -> [number, 0.0 - 1.0]
-- An envelope point's scaling (used in 'lines' playback mode only - 0.0 is linear).
renoise.song().instruments[].sample_modulation_sets[].devices[].points[].scaling
  -> [number, -1.0 - 1.0]


--------------------------------------------------------------------------------
-- renoise.SampleStepperModulationDevice  (inherits from renoise.SampleModulationDevice)
--------------------------------------------------------------------------------

--------- Constants

renoise.SampleStepperModulationDevice.PLAYMODE_POINTS
renoise.SampleStepperModulationDevice.PLAYMODE_LINES
renoise.SampleStepperModulationDevice.PLAYMODE_CURVES

renoise.SampleStepperModulationDevice.MIN_NUMBER_OF_POINTS
renoise.SampleStepperModulationDevice.MAX_NUMBER_OF_POINTS


-------- Functions

-- Reset the envelope back to its default initial state.
renoise.song().instruments[].sample_modulation_sets[].devices[]:init()

-- Copy all properties from another SampleStepperModulation object.
renoise.song().instruments[].sample_modulation_sets[].devices[]:copy_from(
  other renoise.SampleStepperModulationDevice object)

-- Remove all points from the envelope.
renoise.song().instruments[].sample_modulation_sets[].devices[]:clear_points()
-- Remove points in the given [from, to) time range from the envelope.
renoise.song().instruments[].sample_modulation_sets[].devices[]:clear_points_in_range(
--  from_time, to_time)

-- Copy all points from another SampleStepperModulation object.
renoise.song().instruments[].sample_modulation_sets[].devices[]:copy_points_from(
  other SampleStepperModulationDevice object)

-- Test if a point exists at the given time.
renoise.song().instruments[].sample_modulation_sets[].devices[]:has_point_at(time)
  -> [boolean]
-- Add a new point value (or replace any existing value) at time. 
renoise.song().instruments[].sample_modulation_sets[].devices[]:add_point_at(
  time, value [, scaling])
-- Removes a point at the given time. Point must exist.
renoise.song().instruments[].sample_modulation_sets[].devices[]:remove_point_at(time)


-------- Properties

-- External editor visibility.
renoise.song().instruments[].sample_modulation_sets[].devices[].external_editor_visible
 -> [boolean, set to true to show the editor, false to close it]
  
-- Play mode (interpolation mode).
renoise.song().instruments[].sample_modulation_sets[].devices[].play_mode, _observable
  -> [enum = PLAYMODE]

-- Step size. -1 is the same as choosing RANDOM
renoise.song().instruments[].sample_modulation_sets[].devices[].play_step, _observable
  -> [number, -1-16]

-- Envelope length.
renoise.song().instruments[].sample_modulation_sets[].devices[].length, _observable
  -> [number, 1-256]

-- Get all points of the envelope. When setting a new list of points,
-- items may be unsorted by time, but there may not be multiple points
-- for the same time. Returns a copy of the list, so changing
-- `points[1].value` will not do anything. Instead, change them via
-- `points = { something }`.
renoise.song().instruments[].sample_modulation_sets[].devices[].points[], _observable
  -> [array of {time, value} tables]

-- An envelope point's time.
renoise.song().instruments[].sample_modulation_sets[].devices[].points[].time
  -> [number, 1 - envelope.length]
-- An envelope point's value.
renoise.song().instruments[].sample_modulation_sets[].devices[].points[].value
  -> [number, 0.0 - 1.0]
-- An envelope point's scaling (used in 'lines' playback mode only - 0.0 is linear).
renoise.song().instruments[].sample_modulation_sets[].devices[].points[].scaling
  -> [number, -1.0 - 1.0]


--------------------------------------------------------------------------------
-- renoise.SampleLfoModulationDevice (inherits from renoise.SampleModulationDevice)
--------------------------------------------------------------------------------

-------- Constants

renoise.SampleLfoModulationDevice.MODE_SIN
renoise.SampleLfoModulationDevice.MODE_SAW
renoise.SampleLfoModulationDevice.MODE_PULSE
renoise.SampleLfoModulationDevice.MODE_RANDOM


-------- Properties

-- LFO mode.
renoise.song().instruments[].sample_modulation_sets[].devices[].mode
  -> [enum = MODE]

-- Phase.
renoise.song().instruments[].sample_modulation_sets[].devices[].phase
  -> [renoise.DeviceParameter object, 0-360]

-- Frequency.
renoise.song().instruments[].sample_modulation_sets[].devices[].frequency
  -> [renoise.DeviceParameter object, 0-1]

-- Amount.
renoise.song().instruments[].sample_modulation_sets[].devices[].amount
  -> [renoise.DeviceParameter object, 0-1]

-- Delay.
renoise.song().instruments[].sample_modulation_sets[].devices[].delay
-> [renoise.DeviceParameter object, 0-1]

--------------------------------------------------------------------------------
-- renoise.SampleModulationSet
--------------------------------------------------------------------------------

-------- Functions

-- Reset all chain back to default initial state. Removing all devices too.
renoise.song().instruments[].sample_modulation_sets[]:init()

-- Copy all devices from another SampleModulationSet object.
renoise.song().instruments[].sample_modulation_sets[]:copy_from(
  other renoise.SampleModulationSet object)

-- Insert a new device at the given position. "device_path" must be one of
-- renoise.song().instruments[].sample_modulation_sets[].available_devices.
-- device_target specifies where the modulation gets applied (Volume, Pan, Pitch, Cutoff, Resonance)
-- see SampleModulationDevice.TARGET_* constants
renoise.song().instruments[].sample_modulation_sets[]:insert_device_at(device_path, device_target, index) 
  -> [returns new renoise.SampleModulationDevice object]
-- Delete a device at the given index.
renoise.song().instruments[].sample_modulation_sets[]:delete_device_at(index)
-- Access a single device by index.  
renoise.song().instruments[].sample_modulation_sets[]:device(index) 
 -> [renoise.SampleModulationDevice object]

 -- upgrade filter type to the latest version. Tries to find a somewhat matching
 -- filter in the new version, but things quite likely won't sound the same.
renoise.song().instruments[].sample_modulation_sets[]:upgrade_filter_version()
  

-------- Properties

-- Name of the modulation set.
renoise.song().instruments[].sample_modulation_sets[].name, _observable
  -> [string]
  
-- Input value for the volume domain
renoise.song().instruments[].sample_modulation_sets[].volume_input
  -> [renoise.DeviceParameter object]

-- Input value for the panning domain
renoise.song().instruments[].sample_modulation_sets[].panning_input
  -> [renoise.DeviceParameter object]

-- Input value for the pitch domain
renoise.song().instruments[].sample_modulation_sets[].pitch_input
  -> [renoise.DeviceParameter object]

-- Input value for the cutoff domain
renoise.song().instruments[].sample_modulation_sets[].cutoff_input
  -> [renoise.DeviceParameter object]

-- Input value for the resonance domain
renoise.song().instruments[].sample_modulation_sets[].resonance_input
  -> [renoise.DeviceParameter object]

-- Input value for the drive domain
renoise.song().instruments[].sample_modulation_sets[].drive_input
  -> [renoise.DeviceParameter object]

-- Pitch range in semitones
renoise.song().instruments[].sample_modulation_sets[].pitch_range, _observable 
  -> [number, 1 - 96]


-- All available devices, to be used in 'insert_device_at'.
renoise.song().instruments[].sample_modulation_sets[].available_devices[] 
  -> [read-only, array of strings]

-- Device list access.
renoise.song().instruments[].sample_modulation_sets[].devices[], observable 
  -> [read-only, array of renoise.SampleModulationDevice objects]

-- Filter version. See also function 'upgrade_filter_version'
renoise.song().instruments[].sample_modulation_sets[].filter_version, observable
  -> [read-only, number - 1,2 or 3 which is the latest version]

-- Filter type.
renoise.song().instruments[].sample_modulation_sets[].available_filter_types
  -> [read-only, list of strings]
renoise.song().instruments[].sample_modulation_sets[].filter_type, _observable
  -> [string, one of 'available_filter_types']

  
--------------------------------------------------------------------------------
-- renoise.SampleDeviceChain
--------------------------------------------------------------------------------

-------- Functions

-- Insert a new device at the given position. "device_path" must be one of
-- renoise.song().instruments[].sample_device_chains[].available_devices.
renoise.song().instruments[].sample_device_chains[]:insert_device_at(
  device_path, index) -> [returns new device]
-- Delete an existing device from a chain. The mixer device at index 1 can not
-- be deleted.
renoise.song().instruments[].sample_device_chains[]:delete_device_at(index)
-- Swap the positions of two devices in the device chain. The mixer device at
-- index 1 can not be swapped or moved.
renoise.song().instruments[].sample_device_chains[]:swap_devices_at(index, index)

-- Access to a single device in the chain.
renoise.song().instruments[].sample_device_chains[]:device(index) 
  -> [renoise.AudioDevice object]


-------- Properties

-- Name of the audio effect chain.
renoise.song().instruments[].sample_device_chains[].name, _observable 
  -> [string]
  
-- Allowed, available devices for 'insert_device_at'.
renoise.song().instruments[].sample_device_chains[].available_devices[]
  -> [read-only, array of strings]
-- Returns a list of tables containing more information about the devices. 
-- see renoise.Track available_device_infos for more info
renoise.song().instruments[].sample_device_chains[].available_device_infos[] 
  -> [read-only, array of device info tables]

-- Device access.
renoise.song().instruments[].sample_device_chains[].devices[], observable 
  -> [read-only, array of renoise.AudioDevice objects]

-- Output routing.
renoise.song().instruments[].sample_device_chains[].available_output_routings[]
  -> [read-only, array of strings]
renoise.song().instruments[].sample_device_chains[].output_routing, _observable
  -> [string, one of 'available_output_routings']


--------------------------------------------------------------------------------
-- renoise.InstrumentMidiOutputProperties
--------------------------------------------------------------------------------

-------- Constants

renoise.InstrumentMidiOutputProperties.TYPE_EXTERNAL
renoise.InstrumentMidiOutputProperties.TYPE_LINE_IN_RET
renoise.InstrumentMidiOutputProperties.TYPE_INTERNAL -- REWIRE


-------- Properties

-- Note: ReWire device always start with "ReWire: " in the device_name and
-- will always ignore the instrument_type and channel properties. MIDI
-- channels are not configurable for ReWire MIDI, and instrument_type will
-- always be "TYPE_INTERNAL" for ReWire devices.
renoise.song().instruments[].midi_output_properties.instrument_type, _observable
  -> [enum = TYPE]

-- When setting new devices, device names must be one of:
-- renoise.Midi.available_output_devices.
-- Devices are automatically opened when needed. To close a device, set its name
-- to "", e.g. an empty string.
renoise.song().instruments[].midi_output_properties.device_name, _observable
  -> [string]
renoise.song().instruments[].midi_output_properties.channel, _observable
  -> [number, 1-16]
renoise.song().instruments[].midi_output_properties.transpose, _observable
  -> [number, -120-120]
renoise.song().instruments[].midi_output_properties.program, _observable
  -> [number, 1-128, 0 = OFF]
renoise.song().instruments[].midi_output_properties.bank, _observable
  -> [number, 1-65536, 0 = OFF]
renoise.song().instruments[].midi_output_properties.delay, _observable
  -> [number, 0-100]
renoise.song().instruments[].midi_output_properties.duration, _observable
  -> [number, 1-8000, 8000 = INF]


--------------------------------------------------------------------------------
-- renoise.InstrumentPluginProperties
--------------------------------------------------------------------------------

-------- Functions

-- Load an existing, new, non aliased plugin. Pass an empty string to unload
-- an already assigned plugin. plugin_path must be one of:
-- plugin_properties.available_plugins.
renoise.song().instruments[].plugin_properties:load_plugin(plugin_path)
  -> [boolean, success]


-------- Properties

-- List of all currently available plugins. This is a list of unique plugin
-- names which also contains the plugin's type (VST/AU/DSSI/...), not including
-- the vendor names as visible in Renoise's GUI. Aka, its an identifier, and not
-- the name as visible in the GUI. When no plugin is loaded, the identifier is
-- an empty string.
renoise.song().instruments[].plugin_properties.available_plugins[]
  -> [read_only, array of strings]

-- Returns a list of tables containing more information about the plugins. 
-- Each table has the following fields:
--  {
--    path,           -- The plugin's path used by load_plugin()
--    name,           -- The plugin's name
--    short_name,     -- The plugin's name as displayed in shortened lists
--    favorite_name,  -- The plugin's name as displayed in favorites
--    is_favorite,    -- true if the plugin is a favorite
--    is_bridged      -- true if the plugin is a bridged plugin
--  }
renoise.song().instruments[].plugin_properties.available_plugin_infos[]
  -> [read-only, array of plugin info tables]
  
-- Returns true when a plugin is present; loaded successfully.
-- see 'plugin_properties.plugin_device_observable' for related notifications.
renoise.song().instruments[].plugin_properties.plugin_loaded
  -> [read-only, boolean]

-- Valid object for successfully loaded plugins, otherwise nil. Alias plugin
-- instruments of FX will return the resolved device, will link to the device
-- the alias points to.
-- The observable is fired when the device changes: when a plugin gets loaded or
-- unloaded or a plugin alias is assigned or unassigned.
renoise.song().instruments[].plugin_properties.plugin_device, _observable
 -> [renoise.InstrumentPluginDevice object or renoise.AudioDevice object or nil]

-- Valid for loaded and unloaded plugins.
renoise.song().instruments[].plugin_properties.alias_instrument_index, _observable
  -> [read-only, number or 0 (when no alias instrument is set)]
renoise.song().instruments[].plugin_properties.alias_fx_track_index, _observable
  -> [read-only, number or 0 (when no alias FX is set)]
renoise.song().instruments[].plugin_properties.alias_fx_device_index, _observable
  -> [read-only, number or 0 (when no alias FX is set)]

-- Valid for loaded and unloaded plugins. target instrument index or 0 of the 
-- plugin's MIDI output (when present)
renoise.song().instruments[].plugin_properties.midi_output_routing_index, _observable
  -> [read-only, number. 0 when no routing is set]
  
-- Valid for loaded and unloaded plugins.
renoise.song().instruments[].plugin_properties.channel, _observable
  -> [number, 1-16]
renoise.song().instruments[].plugin_properties.transpose, _observable
  -> [number, -120-120]

-- Valid for loaded and unloaded plugins.
renoise.song().instruments[].plugin_properties.volume, _observable
  -> [number, linear gain, 0-4]

-- Valid for loaded and unloaded plugins.
renoise.song().instruments[].plugin_properties.auto_suspend, _observable
  -> [boolean]


--------------------------------------------------------------------------------
-- renoise.InstrumentDevice
--------------------------------------------------------------------------------

-- DEPRECATED - alias for renoise.InstrumentPluginDevice


--------------------------------------------------------------------------------
-- renoise.InstrumentPluginDevice
--------------------------------------------------------------------------------

-------- Functions

-- Access to a single preset name by index. Use properties 'presets' to iterate 
-- over all presets and to query the presets count.
renoise.song().instruments[].plugin_properties.plugin_device:preset(index)
  -> [string]

-- Access to a single parameter by index. Use properties 'parameters' to iterate 
-- over all parameters and to query the parameter count.
renoise.song().instruments[].plugin_properties.plugin_device:parameter(index)
  -> [renoise.DeviceParameter object]


-------- Properties

-- Device name.
renoise.song().instruments[].plugin_properties.plugin_device.name
  -> [read-only, string]
renoise.song().instruments[].plugin_properties.plugin_device.short_name
  -> [read-only, string]

-- Preset handling.
renoise.song().instruments[].plugin_properties.plugin_device.active_preset, _observable
  -> [number, 0 when none is active or available]
  
renoise.song().instruments[].plugin_properties.plugin_device.active_preset_data
  -> [string, raw XML data of the active preset]

renoise.song().instruments[].plugin_properties.plugin_device.presets[]
  -> [read-only, array of strings]

-- Parameters.
renoise.song().instruments[].plugin_properties.plugin_device.parameters[]
  -> [read-only, array of renoise.DeviceParameter objects]

-- Returns whether or not the plugin provides its own custom GUI.
renoise.song().instruments[].plugin_properties.plugin_device.external_editor_available
  -> [read-only, boolean]

-- When the plugin has no custom GUI, Renoise will create a dummy editor for it which
-- lists the plugin parameters.
renoise.song().instruments[].plugin_properties.plugin_device.external_editor_visible
  -> [boolean, set to true to show the editor, false to close it]

-- Returns a string that uniquely identifies the plugin, from "available_plugins".
-- The string can be passed into: plugin_properties:load_plugin()
renoise.song().instruments[].plugin_properties.plugin_device.device_path
  -> [read_only, string]


--------------------------------------------------------------------------------
-- renoise.SampleMapping
--------------------------------------------------------------------------------

-- General remarks: Sample mappings of sliced samples are read-only: can not be
-- modified. See `sample_mappings[].read_only`

-------- Properties

-- True for sliced instruments. No sample mapping properties are allowed to 
-- be modified, but can be read.
renoise.song().instruments[].sample_mappings[].read_only
  -> [read-only, boolean]
  
-- Linked sample.
renoise.song().instruments[].sample_mappings[].sample
  -> [renoise.Sample object]

-- Mapping's layer (triggered via Note-Ons or Note-Offs?).
renoise.song().instruments[].sample_mappings[].layer, _observable
  -> [enum = renoise.Instrument.LAYER]

-- Mappings velocity->volume and key->pitch options.
renoise.song().instruments[].sample_mappings[].map_velocity_to_volume, _observable 
  -> [boolean]
renoise.song().instruments[].sample_mappings[].map_key_to_pitch, _observable 
  -> [boolean]

-- Mappings base-note. Final pitch of the played sample is:
--   played_note - mapping.base_note + sample.transpose + sample.finetune
renoise.song().instruments[].sample_mappings[].base_note, _observable 
  -> [number (0-119, c-4=48)]

-- Note range the mapping is triggered for.
renoise.song().instruments[].sample_mappings[].note_range, _observable 
  -> [table with two numbers (0-119, c-4=48)]

-- Velocity range the mapping is triggered for.
renoise.song().instruments[].sample_mappings[].velocity_range, _observable 
  -> [table with two numbers (0-127)]


--------------------------------------------------------------------------------
-- renoise.Sample
--------------------------------------------------------------------------------

-------- Constants

renoise.Sample.INTERPOLATE_NONE
renoise.Sample.INTERPOLATE_LINEAR
renoise.Sample.INTERPOLATE_CUBIC
renoise.Sample.INTERPOLATE_SINC

renoise.Sample.BEAT_SYNC_REPITCH
renoise.Sample.BEAT_SYNC_PERCUSSION
renoise.Sample.BEAT_SYNC_TEXTURE

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
renoise.song().instruments[].samples[]:copy_from(
  other renoise.Sample object)

-- Insert a new slice marker at the given sample position. Only samples in
-- the first sample slot may use slices. Creating slices will automatically
-- create sample aliases in the following slots: read-only sample slots that 
-- play the sample slice and are mapped to notes. Sliced sample lists can not 
-- be modified manually then. To update such aliases, modify the slice marker 
-- list instead. 
-- Existing 0S effects or notes will be updated to ensure that the old slices
-- are played back just as before.
renoise.song().instruments[].samples[]:insert_slice_marker(marker_sample_pos)
-- Delete an existing slice marker. marker_sample_pos must point to an existing
-- marker. See also property 'samples[].slice_markers'. Existing 0S effects or 
-- notes will be updated to ensure that the old slices are played back just as 
-- before.
renoise.song().instruments[].samples[]:delete_slice_marker(marker_sample_pos)
-- Change the sample position of an existing slice marker. see also property 
-- 'samples[].slice_markers'.
-- When moving a marker behind or before an existing other marker, existing 0S
-- effects or notes will automatically be updated to ensure that the old slices
-- are played back just as before.
renoise.song().instruments[].samples[]:move_slice_marker(
  old_marker_pos, new_marker_pos)

    
-------- Properties

-- True, when the sample slot is an alias to a sliced master sample. Such sample 
-- slots are read-only and automatically managed with the master samples slice 
-- list.
renoise.song().instruments[].samples[].is_slice_alias 
  -> [read-only, boolean]
    
-- Read/write access to the slice marker list of a sample. When new markers are 
-- set or existing ones unset, existing 0S effects or notes to existing slices 
-- will NOT be remapped (unlike its done with the insert/remove/move_slice_marker
-- functions). See function insert_slice_marker for info about marker limitations 
-- and preconditions.
renoise.song().instruments[].samples[].slice_markers, _observable 
  -> [table of numbers, sample positions]

    
-- Name.
renoise.song().instruments[].samples[].name, _observable
  -> [string]

-- Panning, volume.
renoise.song().instruments[].samples[].panning, _observable
  -> [number, 0.0-1.0]
renoise.song().instruments[].samples[].volume, _observable
  -> [number, 0.0-4.0]

-- Tuning.
renoise.song().instruments[].samples[].transpose, _observable
  -> [number, -120-120]
renoise.song().instruments[].samples[].fine_tune, _observable
  -> [number, -127-127]

-- Beat sync.
renoise.song().instruments[].samples[].beat_sync_enabled, _observable
  -> [boolean]
renoise.song().instruments[].samples[].beat_sync_lines, _observable
  -> [number, 1-512]
renoise.song().instruments[].samples[].beat_sync_mode, _observable
  -> [enum = BEAT_SYNC]

-- Interpolation, new note action, oneshot, mute_group, autoseek, autofade.
renoise.song().instruments[].samples[].interpolation_mode, _observable
  -> [enum = INTERPOLATE]
renoise.song().instruments[].samples[].oversample_enabled, _observable 
  -> [boolean]

renoise.song().instruments[].samples[].new_note_action, _observable
  -> [enum = NEW_NOTE_ACTION]
renoise.song().instruments[].samples[].oneshot, _observable 
  -> [boolean]
renoise.song().instruments[].samples[].mute_group, _observable 
  -> [number, 0-15 with 0=none]
renoise.song().instruments[].samples[].autoseek, _observable
  -> [boolean]
renoise.song().instruments[].samples[].autofade, _observable
  -> [boolean]

-- Loops.
renoise.song().instruments[].samples[].loop_mode, _observable
  -> [enum = LOOP_MODE]
renoise.song().instruments[].samples[].loop_release, _observable
  -> [boolean]
renoise.song().instruments[].samples[].loop_start, _observable
  -> [number, 1-num_sample_frames]
renoise.song().instruments[].samples[].loop_end, _observable
  -> [number, 1-num_sample_frames]

-- The linked modulation set. 0 when disable, else a valid index for the
-- instruments[].sample_modulation_sets table
renoise.song().instruments[].samples[].modulation_set_index, _observable 
  -> [number]
  
-- The linked instrument device chain. 0 when disable, else a valid index for the
-- instruments[].sample_device_chain table
renoise.song().instruments[].samples[].device_chain_index, _observable 
  -> [number]

-- Buffer.
renoise.song().instruments[].samples[].sample_buffer, _observable
  -> [read-only, renoise.SampleBuffer object]

-- Keyboard Note/velocity mapping
renoise.song().instruments[].samples[].sample_mapping
  -> [read-only, renoise.SampleMapping object]


--------------------------------------------------------------------------------
-- renoise.SampleBuffer
--------------------------------------------------------------------------------

-------- Constants

renoise.SampleBuffer.CHANNEL_LEFT
renoise.SampleBuffer.CHANNEL_RIGHT
renoise.SampleBuffer.CHANNEL_LEFT_AND_RIGHT


-------- Functions

-- Create new sample data with the given rate, bit-depth, channel and frame
-- count. Will trash existing sample data. Initial buffer is all zero.
-- Will only return false when memory allocation fails (you're running out
-- of memory). All other errors are fired as usual.
renoise.song().instruments[].samples[].sample_buffer:create_sample_data(
  sample_rate, bit_depth, num_channels, num_frames)
    -> [boolean, success]
-- Delete existing sample data.
renoise.song().instruments[].samples[].sample_buffer:delete_sample_data()

-- Read access to samples in a sample data buffer.
renoise.song().instruments[].samples[].sample_buffer:sample_data(
  channel_index, frame_index)
  -> [number -1-1]

-- Write access to samples in a sample data buffer. New samples values must be
-- within [-1, 1] and will be clipped automatically. Sample buffers may be 
-- read-only (see property 'read_only'). Attempts to write on such buffers 
-- will result into errors.
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
  -> [boolean, success]
-- Export sample data to a file. Possible errors are shown to the user,
-- otherwise success is returned. Valid export types are 'wav' or 'flac'.
renoise.song().instruments[].samples[].sample_buffer:save_as(filename, format)
  -> [boolean, success]


-------- Properties

-- Has sample data?
renoise.song().instruments[].samples[].sample_buffer.has_sample_data
  -> [read-only, boolean]

-- _NOTE: All following properties are invalid when no sample data is present,
-- 'has_sample_data' returns false:_

-- True, when the sample buffer can only be read, but not be modified. true for
-- sample aliases of sliced samples. To modify such sample buffers, modify the 
-- sliced master sample buffer instead.
renoise.song().instruments[].samples[].sample_buffer.read_only
  -> [read-only, boolean]
  
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

-- The first sample displayed in the sample editor view. Set together with
-- DisplayLength to control zooming.
renoise.song().instruments[].samples[].sample_buffer.display_start, _observable
  -> [number >= 1 <= number_of_frames]

-- The number of samples displayed in the sample editor view. Set together with
-- DisplayStart to control zooming.
renoise.song().instruments[].samples[].sample_buffer.display_length, _observable
  -> [number >= 1 <= number_of_frames]

-- The start and end points of the sample editor display.
renoise.song().instruments[].samples[].sample_buffer.display_range[], _observable
  -> [array of two numbers, 1-number_of_frames]

-- The vertical zoom level where 1.0 is fully zoomed out.
renoise.song().instruments[].samples[].sample_buffer.vertical_zoom_factor, _observable
   -> [number, 0.0-1.0]

-- Selection range as visible in the sample editor. always valid. returns the entire
-- buffer when no selection is present in the UI.
renoise.song().instruments[].samples[].sample_buffer.selection_start, _observable
  -> [number >= 1 <= number_of_frames]
renoise.song().instruments[].samples[].sample_buffer.selection_end, _observable
  -> [number >= 1 <= number_of_frames]
renoise.song().instruments[].samples[].sample_buffer.selection_range[], _observable
  -> [array of two numbers, 1-number_of_frames]

-- The selected channel.
renoise.song().instruments[].samples[].sample_buffer.selected_channel, _observable
  -> [enum = CHANNEL_LEFT, CHANNEL_RIGHT, CHANNEL_LEFT_AND_RIGHT]


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
renoise.song().patterns[]:copy_from(
  other renoise.Pattern object)

-- Access to a single pattern track by index. Use properties 'tracks' to
-- iterate over all tracks and to query the track count.
renoise.song().patterns[]:track(index)
  -> [renoise.PatternTrack object]

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
renoise.song().patterns[]:has_line_notifier(func [, obj])
  -> [boolean]
renoise.song().patterns[]:add_line_notifier(func [, obj])
renoise.song().patterns[]:remove_line_notifier(func [, obj])

-- Same as line_notifier above, but the notifier only fires when the user
-- added, changed or deleted a line with the computer or MIDI keyboard.
renoise.song().patterns[]:has_line_edited_notifier(func [, obj])
  -> [boolean]
renoise.song().patterns[]:add_line_edited_notifier(func [, obj])
renoise.song().patterns[]:remove_line_edited_notifier(func [, obj])


-------- Properties

-- Quickly check if any track in a pattern has some non empty pattern lines. 
-- This does not look at track automation.
renoise.song().patterns[].is_empty
  -> [read-only, boolean]

-- Name of the pattern, as visible in the pattern sequencer.
renoise.song().patterns[].name, _observable
  -> [string]

-- Number of lines the pattern currently has. 64 by default. Max is
-- renoise.Pattern.MAX_NUMBER_OF_LINES, min is 1.
renoise.song().patterns[].number_of_lines, _observable
  -> [number]

-- Access to the pattern tracks. Each pattern has #renoise.song().tracks amount
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
renoise.song().patterns[].tracks[]:copy_from(
  other renoise.PatternTrack object)

-- Access to a single line by index. Line must be [1-MAX_NUMBER_OF_LINES]). 
-- This is a !lot! more efficient than calling the property: lines[index] to
-- randomly access lines.
renoise.song().patterns[].tracks[]:line(index)
  -> [renoise.PatternLine]

-- Get a specific line range (index must be [1-Pattern.MAX_NUMBER_OF_LINES])
renoise.song().patterns[].tracks[]:lines_in_range(index_from, index_to)
  -> [array of renoise.PatternLine objects]


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

-- Ghosting (aliases)
renoise.song().patterns[].tracks[].is_alias 
  -> [read-only, boolean]
-- Pattern index the pattern track is aliased or 0 when its not aliased.
renoise.song().patterns[].tracks[].alias_pattern_index , _observable
  -> [number, index or 0 when no alias is present]
  
-- Color.
renoise.song().patterns[].tracks[].color, _observable
  -> [table with 3 numbers (0-0xFF, RGB) or nil when no custom slot color is set]

-- Returns true when all the track lines are empty. Does not look at automation.
renoise.song().patterns[].tracks[].is_empty, _observable
  -> [read-only, boolean]

-- Get all lines in range [1, number_of_lines_in_pattern]
renoise.song().patterns[].tracks[].lines[]
  -> [read-only, array of renoise.PatternLine objects]

-- Automation.
renoise.song().patterns[].tracks[].automation[], _observable
  -> [read-only, array of renoise.PatternTrackAutomation objects]


-------- Operators

-- Compares line content and automation. All other properties are ignored.
==(PatternTrack object, PatternTrack object) -> [boolean]
~=(PatternTrack object, PatternTrack object) -> [boolean]


--------------------------------------------------------------------------------
-- renoise.PatternTrackAutomation
--------------------------------------------------------------------------------

-- General remarks: Automation "time" is specified in lines + optional 1/256 
-- line fraction for the sub line grid. The sub line grid has 256 units per 
-- line. All times are internally quantized to this sub line grid.
-- For example a time of 1.5 means: line 1 with a note column delay of 128

-------- Constants

renoise.PatternTrackAutomation.PLAYMODE_POINTS
renoise.PatternTrackAutomation.PLAYMODE_LINES
renoise.PatternTrackAutomation.PLAYMODE_CURVES


-------- Functions

-- Removes all points from the automation. Will not delete the automation
-- from tracks[]:automation, instead the resulting automation will not do
-- anything at all.
renoise.song().patterns[].tracks[].automation[]:clear()
-- Remove all existing points in the given [from, to) time range from the 
-- automation.
renoise.song().patterns[].tracks[].automation[]:clear_range(from_time, to_time)

-- Copy all points and playback settings from another track automation.
renoise.song().patterns[].tracks[].automation[]:copy_from(
  other renoise.PatternTrackAutomation object)

-- Test if a point exists at the given time (in lines 
renoise.song().patterns[].tracks[].automation[]:has_point_at(time)
   -> [boolean]
-- Insert a new point, or change an existing one, if a point in
-- time already exists.
renoise.song().patterns[].tracks[].automation[]:add_point_at(
  time, value [, scaling])
-- Removes a point at the given time. Point must exist.
renoise.song().patterns[].tracks[].automation[]:remove_point_at(time)


-------- Properties

-- Destination device. Can in some rare circumstances be nil, i.e. when 
-- a device or track is about to be deleted.
renoise.song().patterns[].tracks[].automation[].dest_device
  -> [renoise.AudioDevice or nil]

-- Destination device's parameter. Can in some rare circumstances be nil, 
-- i.e. when a device or track is about to be deleted.
renoise.song().patterns[].tracks[].automation[].dest_parameter
  -> [renoise.DeviceParameter or nil]

-- play-mode (interpolation mode).
renoise.song().patterns[].tracks[].automation[].playmode, _observable
  -> [enum = PLAYMODE]

-- Max length (time in lines) of the automation. Will always fit the patterns length.
renoise.song().patterns[].tracks[].automation[].length
  -> [number, 1-NUM_LINES_IN_PATTERN]

-- Selection range as visible in the automation editor. always valid. 
-- returns the automation range no selection is present in the UI.
renoise.song().patterns[].tracks[].automation[].selection_start, _observable
  -> [number >= 1 <= automation.length+1]
renoise.song().patterns[].tracks[].automation[].selection_end, _observable
  -> [number >= 1 <= automation.length+1]
-- Get or set selection range. when setting an empty table, the existing 
-- selection, if any, will be cleared.
renoise.song().patterns[].tracks[].automation[].selection_range[], _observable
  -> [array of two numbers, 1-automation.length+1]

-- Get all points of the automation. When setting a new list of points,
-- items may be unsorted by time, but there may not be multiple points
-- for the same time. Returns a copy of the list, so changing
-- `points[1].value` will not do anything. Instead, change them via
-- `points = { something }` instead.
renoise.song().patterns[].tracks[].automation[].points[], _observable
  -> [array of {time, value} tables]

-- An automation point's time in pattern lines.
renoise.song().patterns[].tracks[].automation[].points[].time
  -> [number, 1 - NUM_LINES_IN_PATTERN]
-- An automation point's value [0-1.0]
renoise.song().patterns[].tracks[].automation[].points[].value
  -> [number, 0 - 1.0]
-- An envelope point's scaling (used in 'lines' playback mode only - 0.0 is linear).
renoise.song().patterns[].tracks[].automation[].points[].scaling
  -> [number, -1.0 - 1.0]


-------- Operators

-- Compares automation content only, ignoring dest parameters.
==(PatternTrackAutomation object, PatternTrackAutomation object) 
  -> [boolean]
~=(PatternTrackAutomation object, PatternTrackAutomation object) 
  -> [boolean]


--------------------------------------------------------------------------------
-- renoise.PatternTrackLine
--------------------------------------------------------------------------------

-- DEPRECATED - alias for renoise.PatternLine


--------------------------------------------------------------------------------
-- renoise.PatternLine
--------------------------------------------------------------------------------

-------- Constants

renoise.PatternLine.EMPTY_NOTE
renoise.PatternLine.NOTE_OFF

renoise.PatternLine.EMPTY_INSTRUMENT
renoise.PatternLine.EMPTY_VOLUME
renoise.PatternLine.EMPTY_PANNING
renoise.PatternLine.EMPTY_DELAY

renoise.PatternLine.EMPTY_EFFECT_NUMBER
renoise.PatternLine.EMPTY_EFFECT_AMOUNT


-------- Functions

-- Clear all note and effect columns.
renoise.song().patterns[].tracks[].lines[]:clear()

-- Copy contents from other_line, trashing column content.
renoise.song().patterns[].tracks[].lines[]:copy_from(
  other renoise.PatternLine object)

-- Access to a single note column by index. Use properties 'note_columns' 
-- to iterate over all note columns and to query the note_column count.
-- This is a !lot! more efficient than calling the property: 
-- note_columns[index] to randomly access columns. When iterating over all
-- columns, use pairs(note_columns).
renoise.song().patterns[].tracks[].lines[]:note_column(index)
  -> [renoise.NoteColumn object]

-- Access to a single effect column by index. Use properties 'effect_columns' 
-- to iterate over all effect columns and to query the effect_column count.
-- This is a !lot! more efficient than calling the property: 
-- effect_columns[index] to randomly access columns. When iterating over all
-- columns, use pairs(effect_columns).
renoise.song().patterns[].tracks[].lines[]:effect_column(index)
  -> [renoise.EffectColumn object]


-------- Properties

-- Is empty.
renoise.song().patterns[].tracks[].lines[].is_empty
  -> [boolean]

-- Columns.
renoise.song().patterns[].tracks[].lines[].note_columns[]
  -> [read-only, array of renoise.NoteColumn objects]
renoise.song().patterns[].tracks[].lines[].effect_columns[]
  -> [read-only, array of renoise.EffectColumn objects]


-------- Operators

-- Compares all columns.
==(PatternLine object, PatternLine object) 
  -> [boolean]
~=(PatternLine object, PatternLine object) 
  -> [boolean]

-- Serialize a line.
tostring(PatternLine object) 
  -> [string]


--------------------------------------------------------------------------------
-- renoise.NoteColumn
--------------------------------------------------------------------------------

-- General remarks: instrument columns are available for lines in phrases
-- but are ignored. See renoise.InstrumentPhrase for detail.


-------- Functions

-- Clear the note column.
renoise.song().patterns[].tracks[].lines[].note_columns[]:clear()

-- Copy the column's content from another column.
renoise.song().patterns[].tracks[].lines[].note_columns[]:copy_from(
  other renoise.NoteColumn object)


-------- Properties

-- True, when all note column properties are empty.
renoise.song().patterns[].tracks[].lines[].note_columns[].is_empty
  -> [read-only, boolean]

-- True, when this column is selected in the pattern or phrase 
-- editors current pattern.
renoise.song().patterns[].tracks[].lines[].note_columns[].is_selected
  -> [read-only, boolean]

-- Access note column properties either by values (numbers) or by strings.
-- The string representation uses exactly the same notation as you see
-- them in Renoise's pattern or phrase editor.

renoise.song().patterns[].tracks[].lines[].note_columns[].note_value
  -> [number, 0-119, 120=Off, 121=Empty]
renoise.song().patterns[].tracks[].lines[].note_columns[].note_string
  -> [string, 'C-0'-'G-9', 'OFF' or '---']

renoise.song().patterns[].tracks[].lines[].note_columns[].instrument_value
  -> [number, 0-254, 255==Empty]
renoise.song().patterns[].tracks[].lines[].note_columns[].instrument_string
  -> [string, '00'-'FE' or '..']

renoise.song().patterns[].tracks[].lines[].note_columns[].volume_value
  -> [number, 0-127, 255==Empty when column value is <= 0x80 or is 0xFF,
              i.e. is used to specify volume]
     [number, 0-65535 in the form 0x0000xxyy where
              xx=effect char 1 and yy=effect char 2,
              when column value is > 0x80, i.e. is used to specify an effect]
renoise.song().patterns[].tracks[].lines[].note_columns[].volume_string
  -> [string, '00'-'ZF' or '..']

renoise.song().patterns[].tracks[].lines[].note_columns[].panning_value
  -> [number, 0-127, 255==Empty when column value is <= 0x80 or is 0xFF,
              i.e. is used to specify pan]
     [number, 0-65535 in the form 0x0000xxyy where
              xx=effect char 1 and yy=effect char 2,
              when column value is > 0x80, i.e. is used to specify an effect]
renoise.song().patterns[].tracks[].lines[].note_columns[].panning_string
  -> [string, '00'-'ZF' or '..']

renoise.song().patterns[].tracks[].lines[].note_columns[].delay_value
  -> [number, 0-255]
renoise.song().patterns[].tracks[].lines[].note_columns[].delay_string
  -> [string, '00'-'FF' or '..']

renoise.song().patterns[].tracks[].lines[].note_columns[].effect_number_value
  -> [int, 0-65535 in the form 0x0000xxyy where xx=effect char 1 and yy=effect char 2]
song().patterns[].tracks[].lines[].note_columns[].effect_number_string
  -> [string, '00' - 'ZZ']

renoise.song().patterns[].tracks[].lines[].note_columns[].effect_amount_value 
  -> [int, 0-255]
renoise.song().patterns[].tracks[].lines[].note_columns[].effect_amount_string
  -> [string, '00' - 'FF']


-------- Operators

-- Compares the whole column.
==(NoteColumn object, NoteColumn object) -> [boolean]
~=(NoteColumn object, NoteColumn object) -> [boolean]

-- Serialize a column.
tostring(NoteColumn object) -> [string]


--------------------------------------------------------------------------------
-- renoise.EffectColumn
--------------------------------------------------------------------------------

-------- Functions

-- Clear the effect column.
renoise.song().patterns[].tracks[].lines[].effect_columns[]:clear()

-- Copy the column's content from another column.
renoise.song().patterns[].tracks[].lines[].effect_columns[]:copy_from(
  other renoise.EffectColumn object)


-------- Properties

-- True, when all effect column properties are empty.
renoise.song().patterns[].tracks[].lines[].effect_columns[].is_empty
  -> [read-only, boolean]

-- True, when this column is selected in the pattern or phrase editor.
renoise.song().patterns[].tracks[].lines[].effect_columns[].is_selected
  -> [read-only, boolean]

-- Access effect column properties either by values (numbers) or by strings.
renoise.song().patterns[].tracks[].lines[].effect_columns[].number_value
  -> [number, 0-65535 in the form 0x0000xxyy where xx=effect char 1 and yy=effect char 2]

renoise.song().patterns[].tracks[].lines[].effect_columns[].number_string
  -> [string, '00'-'ZZ']

renoise.song().patterns[].tracks[].lines[].effect_columns[].amount_value
  -> [number, 0-255]
renoise.song().patterns[].tracks[].lines[].effect_columns[].amount_string
  -> [string, '00'-'FF']


-------- Operators

-- Compares the whole column.
==(EffectColumn object, EffectColumn object) 
  -> [boolean]
~=(EffectColumn object, EffectColumn object) 
  -> [boolean]

-- Serialize a column.
tostring(EffectColumn object) -> [string]
