--[[============================================================================
Renoise Song API Reference
============================================================================]]--

--[[

This reference lists all available Lua functions and classes that control
the Renoise main document - the song - with all its components like instruments,
tracks, patterns, and so on.

Please read the INTRODUCTION.txt first to get an overview about the complete
API, and scripting in Renoise in general...

Do not try to execute this file. It uses a .lua extension for markups only.

]]


--------------------------------------------------------------------------------
-- renoise
--------------------------------------------------------------------------------

-------- functions

renoise.song() 
  -> [renoise.Song object]


--------------------------------------------------------------------------------
-- renoise.Song
--------------------------------------------------------------------------------

-------- functions

renoise.song():can_undo()
  -> [boolean]
renoise.song():undo()

renoise.song():can_redo()
  -> [boolean]
renoise.song():redo()

renoise.song():insert_track_at(index)
  -> [new renoise.Track object]
renoise.song():delete_track_at(index)
renoise.song():swap_tracks_at(index1, index2)

renoise.song():insert_instrument_at(index)
  -> [new renoise.Instrument object]
renoise.song():delete_instrument_at(index)
renoise.song():swap_instruments_at(index2, index2)

renoise.song():capture_instrument_from_pattern()
renoise.song():capture_nearest_instrument_from_pattern()


-------- properties

renoise.song().file_name
  -> [read-only, string]

renoise.song().artist, _observable
  -> [string]
renoise.song().name, _observable
  -> [string]
renoise.song().comments[], _observable
  -> [array of strings]
-- notifiers that are called when any paragraph content changed
renoise.song().comments_assignment_observable
  -> [renoise.Observable object]


renoise.song().transport
  -> [read-only, renoise.Transport object]
renoise.song().sequencer
  -> [read-only, renoise.PatternSequencer object]
renoise.song().pattern_iterator
  -> [read-only, renoise.PatternIterator object]

renoise.song().instruments[], _observable
  -> [read-only, array of renoise.Instrument objects]
renoise.song().patterns[], _observable
  -> [read-only, array of renoise.Pattern objects]
renoise.song().tracks[], _observable
  -> [read-only, array of renoise.Track objects]

-- selected in the instrument box. never nil
renoise.song().selected_instrument, _observable
  -> [read-only, renoise.Instrument object]
renoise.song().selected_instrument_index, _observable
  -> [number]

-- selected in the instrument box. never nil
renoise.song().selected_sample, _observable
  -> [read-only, array of renoise.Sample objects]
renoise.song().selected_sample_index, _observable
  -> [number]

-- selected in the pattern editor or mixer. never nil
renoise.song().selected_track, _observable
  -> [read-only, renoise.Track object]
renoise.song().selected_track_index, _observable
  -> [number]

-- selected in the device chain editor. can be nil
renoise.song().selected_device, _observable
  -> [read-only, renoise.TrackDevice object or nil]
renoise.song().selected_device_index, _observable
  -> [number or 0 (when no device is selected)]

-- selected in the automation editor view. can be nil
renoise.song().selected_parameter, _observable
  -> [read-only, renoise.DeviceParameter or nil]
renoise.song().selected_parameter_index, _observable
  -> [read-only, number or 0 (when no parameter is selected)]

renoise.song().selected_pattern TODO: , _observable
  -> [read-only, renoise.Pattern object]
renoise.song().selected_pattern_track  TODO: , _observable
  -> [read-only, renoise.PatternTrack object]
renoise.song().selected_pattern_index   TODO: , _observable
  -> [number]

-- the currently edited sequence
renoise.song().selected_sequence_index, _observable
  -> [number]

-- the currently edited line in the edited sequence/pattern
renoise.song().selected_line
  -> [read-only, renoise.PatternTrackLine object]
renoise.song().selected_line_index
  -> [number]

-- the currently edited column in the selected line in the edited sequence/pattern
renoise.song().selected_note_column
  -> [read-only, renoise.NoteColumn object or nil], [renoise.Line object or nil]
renoise.song().selected_note_column_index
  -> [number or nil (when an effect column is selected)]

-- the currently edited column in the selected line in the edited sequence/pattern
renoise.song().selected_effect_column
  -> [read-only, renoise.EffectColumn or nil], [renoise.Line object or nil]
renoise.song().selected_effect_column_index
  -> [number or nil (when a note column is selected)]


--------------------------------------------------------------------------------
-- renoise.SongPos
--------------------------------------------------------------------------------

-------- properties

-- pos in pattern sequence
song_pos.sequence
  -> [number]

-- pos in pattern
song_pos.line
  -> [number]


--------------------------------------------------------------------------------
-- renoise.Transport
--------------------------------------------------------------------------------

-------- consts

renoise.Transport.PLAYMODE_RESTART_PATTERN
renoise.Transport.PLAYMODE_CONTINUE_PATTERN

renoise.Transport.RECORD_PARAMETER_MODE_PATTERN
renoise.Transport.RECORD_PARAMETER_MODE_AUTOMATION


-------- functions

renoise.song().transport:panic()

-- mode: enum = PLAYMODE
renoise.song().transport:start(mode)
renoise.song().transport:start_at(line)
renoise.song().transport:stop()

-- immediately start playing a sequence
renoise.song().transport:trigger_sequence(sequence_pos)
-- append the sequence to the scheduled sequence list
renoise.song().transport:add_scheduled_sequence(sequence_pos)
-- replace the scheduled sequence list with the given sequence
renoise.song().transport:set_scheduled_sequence(sequence_pos)

-- move the block look one segment forwards, when possible
renoise.song().transport:loop_block_move_forwards()
-- move the block look one segment backwards, when possible
renoise.song().transport:loop_block_move_backwards()

-- start a new sample recording when the sample dialog is visible,
-- else stop, finish it
renoise.song().transport:start_stop_sample_recording()
-- cancel a currently running sample recording when the sample dialog
-- is visible, else does nothing
renoise.song().transport:cancel_sample_recording()


-------- properties

renoise.song().transport.playing, [added B4] _observable
  -> [boolean]

renoise.song().transport.bpm, _observable
  -> [number, 32-999]
renoise.song().transport.lpb, _observable
  -> [number, 1-256]
renoise.song().transport.tpl, _observable
  -> [number, 1-16]

renoise.song().transport.playback_pos
  -> [renoise.SongPos object]
renoise.song().transport.playback_pos_beats
  -> [float, 0-song_end_beats]

renoise.song().transport.edit_pos
  -> [renoise.SongPos object]
renoise.song().transport.edit_pos_beats
  -> [float, 0-sequence_length]

renoise.song().transport.song_length
  -> [read-only, SongPos]
renoise.song().transport.song_length_beats
  -> [read-only, float]

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

renoise.song().transport.loop_block_enabled
  -> [boolean]
renoise.song().transport.loop_block_start_pos
  -> [read-only, renoise.SongPos object]
renoise.song().transport.loop_block_range_coeff
  -> [number, 2-16]

renoise.song().transport.loop_pattern
  -> [boolean]

renoise.song().transport.loop_sequence_start
  -> [read-only, 0 or 1 - sequence_length]
renoise.song().transport.loop_sequence_end
  -> [read-only, 0 or 1 - sequence_length]
renoise.song().transport.loop_sequence_range 
  -> [array of two numbers, 0 or 1-sequence_length or empty array to disable]

renoise.song().transport.edit_mode, _observable
  -> [boolean]
renoise.song().transport.edit_step, _observable
  -> [number, 0-64]
renoise.song().transport.octave, _observable
  -> [number, 0-8]

renoise.song().transport.metronome_enabled, _observable
  -> [boolean]
renoise.song().transport.metronome_beats_per_bar, _observable
  -> [1 - 16]
renoise.song().transport.metronome_lines_per_beat, _observable
  -> [number, 1 - 256 or 0 = current LPB]

renoise.song().transport.chord_mode_enabled, _observable
  -> [boolean]

renoise.song().transport.record_quantize_enabled, _observable
  -> [boolean]
renoise.song().transport.record_quantize_lines, _observable
  -> [number, 1 - 32]

renoise.song().transport.record_parameter_mode, _observable
  -> [enum = RECORD_PARAMETER_MODE]

renoise.song().transport.follow_player, _observable
  -> [boolean]
renoise.song().transport.wrapped_pattern_edit, _observable
  -> [boolean]
renoise.song().transport.single_track_edit_mode, _observable
  -> [boolean]

renoise.song().transport.shuffle_enabled, _observable
  -> [boolean]
renoise.song().transport.shuffle_amounts[]
  -> [array of floats, 0.0 - 1.0]

-- attach notifiers that will be called as soon as any
-- shuffle value changed
renoise.song().transport.shuffle_assignment_observable
  -> [renoise.Observable object]


--------------------------------------------------------------------------------
-- renoise.PatternSequencer
--------------------------------------------------------------------------------

-------- functions

-- insert a pattern at the given position. new pattern will be the same as
-- the one at sequence_pos, slot muting is copied as well
renoise.song().sequencer.insert_sequence_at(sequence_pos, pattern_index)

-- delete an existing position in the sequence
renoise.song().sequencer.delete_sequence_at(sequence_pos)

-- insert an empty, not yet referenced pattern at the given position
renoise.song().sequencer:insert_new_pattern_at(sequence_pos)
  -> [new pattern_index]

-- clone a sequence range, appending it right after to_sequence_pos
-- slot muting is copied as well
renoise.song().sequencer:clone_range(from_sequence_pos, to_sequence_pos)
-- make patterns unique, if needed, in the given sequencer range
renoise.song().sequencer:make_range_unique(from_sequence_pos, to_sequence_pos)

renoise.song().sequencer:track_sequence_slot_is_muted(track_index, sequence_index)
  -> [boolean]
renoise.song().sequencer:set_track_sequence_slot_is_muted(
  track_index, sequence_index, muted)


-------- properties

-- pattern order list: notifiers will only be fired when sequence positions
-- added, removed or changed their order. to get notified of pattern assignement
-- changes, use 'pattern_assignments_observable'
renoise.song().sequencer.pattern_sequence[], _observable
  -> [array of numbers]

-- attach notifiers that will be called as soon as any assignemnt
-- in any sequence position changed
renoise.song().sequencer.pattern_assignments_observable
  -> [renoise.Observable object]

-- attach notifiers that will be fired as soon as any slot muting property
-- in any track/sequence changed
renoise.song().sequencer.pattern_slot_mutes_observable
  -> [renoise.Observable object]


--------------------------------------------------------------------------------
-- renoise.PatternIterator
--------------------------------------------------------------------------------

-- general remarks: the iterators can only be use in "for" loops, like you use
-- for example pairs in Lua: 'for pos, line in pattern_iterator:lines_in_song do'

-- the returned 'pos' is a table with "pattern", "track", "line" fields for
-- all iterators, and an additional "column" field for the note/effect columns

-- the visible_only flags controls if all content should be traversed, or only
-- currently used patterns, columns and so on:
-- with "visible_patters_only" set, patterns are traversed in the order they
-- are referenced in the pattern sequence, but each pattern is accessed only once.
-- with "visible_columns_only" set, hidden columns are not traversed...


----- Song

-- iterate over all pattern lines in the song
renoise.song().pattern_iterator:lines_in_song(boolean visible_patterns_only)
  -> [iterator with pos, line (renoise.PatternTrackLine object)]

-- iterate over all note/effect_ columns in the song
renoise.song().pattern_iterator:note_columns_in_song(boolean visible_only)
  -> [iterator with pos, column (renoise.NoteColumn object)]
renoise.song():pattern_iterator:effect_columns_in_song(boolean visible_only)
  -> [iterator with pos, column (renoise.EffectColumn object)]


----- Pattern

-- iterate over all lines in the given pattern only
renoise.song().pattern_iterator:lines_in_pattern(pattern_index)
  -> [iterator with pos, line (renoise.PatternTrackLine object)]

-- iterate over all note/effect columns in the specified pattern
renoise.song().pattern_iterator:note_columns_in_pattern(
  pattern_index, boolean visible_only)
  -> [iterator with pos, column (renoise.NoteColumn object)]

renoise.song().pattern_iterator:effect_columns_in_pattern(
  pattern_index, boolean visible_only)
  -> [iterator with pos, column (renoise.EffectColumn object)]


----- Track

-- iterate over all lines in the given track only
renoise.song().pattern_iterator:lines_in_track(
  track_index, boolean visible_patterns_only)
  -> [iterator with pos, column (renoise.PatternTrackLine object)]

-- iterate over all note/effect columns in the specified track
renoise.song().pattern_iterator:note_columns_in_track(
  track_index, boolean visible_only)
  -> [iterator with pos, line (renoise.NoteColumn object)]

renoise.song().pattern_iterator:effect_columns_in_track(
  track_index, boolean visible_only)
  -> [iterator with pos, column (renoise.EffectColumn object)]


----- Track in Pattern

-- iterate over all lines in the given pattern, track only
renoise.song().pattern_iterator:lines_in_pattern_track(
  pattern_index, track_index)
  -> [iterator with pos, column (renoise.PatternTrackLine object)]

-- iterate over all note/effect columns in the specified pattern track
renoise.song().pattern_iterator:note_columns_in_pattern_track(
  pattern_index, track_index, boolean visible_only)
  -> [iterator with pos, line (renoise.NoteColumn object)]

renoise.song().pattern_iterator:effect_columns_in_pattern_track(
  pattern_index, track_index, boolean visible_only)
  -> [iterator with pos, column (renoise.EffectColumn object)]


--------------------------------------------------------------------------------
-- renoise.Track
--------------------------------------------------------------------------------

-------- consts

renoise.Track.TRACK_TYPE_SEQUENCER
renoise.Track.TRACK_TYPE_MASTER
renoise.Track.TRACK_TYPE_SEND

renoise.Track.MUTE_STATE_ACTIVE
renoise.Track.MUTE_STATE_OFF
renoise.Track.MUTE_STATE_MUTED


-------- functions

renoise.song().tracks[]:insert_device_at(device_name, device_index)
  -> [newly created renoise.TrackDevice object]

renoise.song().tracks[]:delete_device_at(device_index)
renoise.song().tracks[]:swap_devices_at(device_index1, device_index2)

-- not for the master, uses default mute state from the prefs
renoise.song().tracks[]:mute()
renoise.song().tracks[]:unmute()
renoise.song().tracks[]:solo()

-- note column column mutes. only valid within (1 - track.max_note_columns)
renoise.song().tracks[]:column_is_muted(column)
  -> [bool]
renoise.song().tracks[]:column_is_muted_observable(column)
  -> [Observable object]
renoise.song().tracks[]:mute_column(column, muted)


-------- properties

renoise.song().tracks[].type
  -> [enum = TRACK_TYPE]
renoise.song().tracks[].name, _observable
  -> [String]

renoise.song().tracks[].color, _observable 
  -> [table with 3 numbers (0-0xFF), RGB]
  
 -- !not available for the master!
renoise.song().tracks[].mute_state, _observable
  -> [enum = MUTE_STATE]

renoise.song().tracks[].solo_state, _observable 
  -> [boolean]

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

renoise.song().tracks[].available_output_routings[]
  -> [read-only, array of strings]
renoise.song().tracks[].output_routing, _observable
  -> [number, 1 - #available_output_routings]

renoise.song().tracks[].output_delay, _observable
  -> [float, -100.0 - 100.0]

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

renoise.song().tracks[].available_devices[]
  -> [read-only, array of strings]

renoise.song().tracks[].devices[], _observable
  -> [read-only, array of renoise.TrackDevice objects]


--------------------------------------------------------------------------------
-- renoise.TrackDevice
--------------------------------------------------------------------------------

-------- properties

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


--------------------------------------------------------------------------------
-- renoise.DeviceParameter
--------------------------------------------------------------------------------

-------- consts

renoise.DeviceParameter.POLARITY_UNIPOLAR
renoise.DeviceParameter.POLARITY_BIPOLAR


-------- functions

renoise.song().tracks[].devices[].parameters[].record_value(value)


-------- properties

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

renoise.song().tracks[].devices[].parameters[].is_automated, _observable
  -> [read-only, boolean]

renoise.song().tracks[].devices[].parameters[].show_in_mixer, _observable
  -> [boolean]

renoise.song().tracks[].devices[].parameters[].value, _observable
  -> [float]
renoise.song().tracks[].devices[].parameters[].value_string, _observable
  -> [string]


--------------------------------------------------------------------------------
-- renoise.Instrument
--------------------------------------------------------------------------------

-------- functions

-- reset, clear all settings including all samples
renoise.song().instruments[]:clear()

-- copy all settings from the other instrument, including all samples
renoise.song().instruments[]:copy_from(other_instrument object)

-- insert a new empty sample
renoise.song().instruments[]:insert_sample_at(index)
  -> [new renoise.Sample object]

-- delete or swaw existing samples
renoise.song().instruments[]:delete_sample_at(index)
renoise.song().instruments[]:swap_samples_at(index1, index2)


-------- properties

renoise.song().instruments[].name, _observable [string]

renoise.song().instruments[].split_map[]
  -> [array of 120 numbers]

-- attach notifiers that will be called as soon as any splitmap value changed
renoise.song().instruments[].split_map_assignment_observable
  -> [renoise.Observable object]

renoise.song().instruments[].samples[], _observable
  -> [read-only, array of renoise.Sample objects]


--------------------------------------------------------------------------------
-- renoise.Sample
--------------------------------------------------------------------------------

-------- consts

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


-------- functions

-- reset, clear all sample settings and the sample data
renoise.song().instruments[].samples[]:clear()

-- copy all settings from other instrument
renoise.song().instruments[].samples[]:copy_from(other_sample object)


-------- properties

renoise.song().instruments[].samples[].name, _observable
  -> [string]

renoise.song().instruments[].samples[].panning, _observable
  -> [float, 0.0 - 1.0]
renoise.song().instruments[].samples[].volume, _observable
  -> [float, 0.0 - 4.0]

renoise.song().instruments[].samples[].base_note, _observable
  -> [number, 0 - 119 with 48 = 'C-4']
renoise.song().instruments[].samples[].fine_tune, _observable
  -> [number, -127 - 127]

renoise.song().instruments[].samples[].beat_sync_enabled, _observable
  -> [boolean]
renoise.song().instruments[].samples[].beat_sync_lines, _observable
  -> [number, 0-512]

renoise.song().instruments[].samples[].interpolation_mode, _observable
  -> [enum = INTERPOLATE]
renoise.song().instruments[].samples[].new_note_action, _observable
  -> [enum = NEW_NOTE_ACTION]

renoise.song().instruments[].samples[].autoseek, _observable
  -> [boolean]

renoise.song().instruments[].samples[].loop_mode, _observable
  -> [enum = LOOP_MODE]
renoise.song().instruments[].samples[].loop_start, _observable
  -> [number, 1 - num_sample_frames]
renoise.song().instruments[].samples[].loop_end, _observable
  -> [number, 1 - num_sample_frames]

renoise.song().instruments[].samples[].sample_buffer, _observable
  -> [read-only, renoise.SampleBuffer object]


--------------------------------------------------------------------------------
-- renoise.SampleBuffer
--------------------------------------------------------------------------------

-------- functions

-- create new sample data with the given rate, bit-depth, channel and frame count.
-- will trash existing sample_data if present. initial buffer is all zero.
-- will only return false when memory allocation failed (you're running out
-- of memory). all other errors are fired as usual...
renoise.song().instruments[].samples[].sample_buffer.create_sample_data(
  sample_rate, bit_depth, num_channels, num_frames) 
    -> [boolean - success]

-- delete an existing sample data buffer
renoise.song().instruments[].samples[].sample_buffer.delete_sample_data()

-- read access to samples in a sample data buffer
renoise.song().instruments[].samples[].sample_buffer.sample_data(
  channel_index, frame_index)
  -> [float -1 - 1]
-- write access to samples in a sample data buffer. new samples values
-- must be within [-1, 1] but will be clipped automatically
renoise.song().instruments[].samples[].sample_buffer.set_sample_data(
  channel_index, frame_index, sample_value)

-- to be called once after the sample data was manipulated via 'set_sample_data'
-- this will create undo/redo data if necessary, and also update the sample view
-- caches for the sample. this is not invoked automatically to avoid performance
-- overhead when changing the sample data sample by sample, so don't forget to
-- call this after any data changes, or your changes may not be visible in the
-- GUI and can not be un/redone!
renoise.song().instruments[].samples[].sample_buffer.finalize_sample_data_changes()


-- load sample data from a file. file can be any audio format renoise supports.
-- possible errors are already shown to the user, success is returned.
renoise.song().instruments[].samples[].sample_buffer.load_from(filename)
  -> [boolean - success]

-- export sample data into a file. possible errors are already shown to the
-- user, success is returned. valid export types are 'wav' or 'flac'
renoise.song().instruments[].samples[].sample_buffer.save_as(filename, format)
  -> [boolean - success]


-------- properties

renoise.song().instruments[].samples[].sample_buffer.has_sample_data
  -> [read-only, boolean]

-- all following properties are invalid when no sample data is present,
-- 'has_sample_data' returns false

-- the current sample rate in Hz, like 44100
renoise.song().instruments[].samples[].sample_buffer.sample_rate
  -> [read-only, number]
-- the current bit depth, like 32, 16, 8.
renoise.song().instruments[].samples[].sample_buffer.bit_depth
  -> [read-only, number]

-- the number of sample channels (1 or 2)
renoise.song().instruments[].samples[].sample_buffer.number_of_channels
  -> [read-only, number]
-- the sample frame count (number of samples per channel)
renoise.song().instruments[].samples[].sample_buffer.number_of_frames
  -> [read-only, number]

-- selection range as visible in the sample editor. getters are always 
-- valid, but only relevant for the currently active sample.
-- setting new selections is only allowed for the currently selected 
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

-------- consts

renoise.Pattern.MAX_NUMBER_OF_LINES


-------- functions

-- deletes all lines & automation
renoise.song().patterns[]:clear()

-- copy contents from other pattern, including automation, when possible
renoise.song().patterns[].copy_from(other_pattern object)


-------- properties

renoise.song().patterns[].is_empty 
  -> [read-only, boolean]

renoise.song().patterns[].name, _observable 
  -> [string]
renoise.song().patterns[].number_of_lines, _observable 
  -> [number]

renoise.song().patterns[].tracks[] 
  -> [read-only, array of renoise.PatternTrack]


--------------------------------------------------------------------------------
-- renoise.PatternTrack
--------------------------------------------------------------------------------

-------- functions

-- deletes all lines & automation
renoise.song().patterns[].tracks[]:clear()

-- copy contents from other pattern track, including automation, when possible
renoise.song().patterns[].tracks[]:copy_from(other_pattern_track object)


-- get a specific line (line must be [1 - Pattern.MAX_NUMBER_OF_LINES])
renoise.song().patterns[].tracks[]:line(index) 
  -> [renoise.PatternTrackLine]

-- get a specific line range (index must be [1 - Pattern.MAX_NUMBER_OF_LINES])
renoise.song().patterns[].tracks[]:lines_in_range(index_from, index_to) 
  -> [array of renoise.PatternTrackLine]


-- returns the automation for the given device parameter or nil 
-- when there is none
renoise.song().patterns[].tracks[]:find_automation(parameter)
  -> [renoise.PatternTrackAutomation or nil]

-- creates a new automation for the given device parameter. 
-- fires and error when an automation already exists
-- returns the newly created automation
renoise.song().patterns[].tracks[]:create_automation(parameter)
  -> [renoise.PatternTrackAutomation object]

-- remove an existing automation the given device parameter. 
-- automation must exist
renoise.song().patterns[].tracks[]:delete_automation(parameter)


-------- properties

renoise.song().patterns[].tracks[].color, _observable 
  -> [table with 3 numbers (0-0xFF, RGB) or nil when no custom slot color is set]

-- returns true when all the track lines are empty. does not look at automation
renoise.song().patterns[].tracks[].is_empty, _observable 
  -> [read-only, boolean]

-- get all lines in range [1, number_of_lines_in_pattern]
renoise.song().patterns[].tracks[].lines[] 
  -> [read-only, array of renoise.PatternTrackLine objects]

renoise.song().patterns[].tracks[].automation[], _observable 
  -> [read-only, list of renoise.PatternTrackAutomation]

  
--------------------------------------------------------------------------------
-- renoise.PatternTrackAutomation
--------------------------------------------------------------------------------
  
-------- consts

renoise.PatternTrackAutomation.PLAYMODE_POINTS
renoise.PatternTrackAutomation.PLAYMODE_LINEAR
renoise.PatternTrackAutomation.PLAYMODE_CUBIC


-------- properties

renoise.song().patterns[].tracks[].automation[].dest_device 
  -> [renoise.TrackDevice]

renoise.song().patterns[].tracks[].automation[].dest_parameter 
  -> [renoise.DeviceParameter]
    
renoise.song().patterns[].tracks[].automation[].playmode, _observable
  -> [enum PLAYMODE]


-- max length (time) of the automation. will always fit the patterns length
renoise.song().patterns[].tracks[].automation[].length
  -> [number]

-- get all points of the automation. when setting a new list of points, 
-- items may be unsorted by time, but there may not be multiple points 
-- for the same time. returns a copy of the list, so changing 
-- points[1].value will not do anything. change them via points = {
-- something } instead....
renoise.song().patterns[].tracks[].automation[].points, _observable
  -> [list of {time, value} tables]

-- an automation points time in pattern lines
renoise.song().patterns[].tracks[].automation[].points[].time
  -> [number, 1 - NUM_LINES_IN_PATTERN]
-- an automation points value [0 - 1.0]
renoise.song().patterns[].tracks[].automation[].points[].value
  -> [number, 0 - 1.0]


-------- functions
  
-- removes all points from the automation. will not delete the automation
-- from tracks[]:automation, but it will not do anything at all...
renoise.song().patterns[].tracks[].automation[]:clear()

-- copy all points and playback settings from another track automation
renoise.song().patterns[].tracks[].automation[]:copy_from()


-- test if a point exists at the given time (in lines)
renoise.song().patterns[].tracks[].automation[]:has_point_at(time)
   -> [boolean]
   
-- insert a new point, or change an existing one, if a point at the 
-- time already exists   
renoise.song().patterns[].tracks[].automation[]:add_point_at(time, value)

-- removes a point at the given time. point must exist
renoise.song().patterns[].tracks[].automation[]:remove_point_at(time)
  
  
--------------------------------------------------------------------------------
-- renoise.PatternTrackLine
--------------------------------------------------------------------------------

-------- consts

renoise.PatternLine.EMPTY_NOTE
renoise.PatternLine.NOTE_OFF

renoise.PatternLine.EMPTY_INSTRUMENT
renoise.PatternLine.EMPTY_VOLUME
renoise.PatternLine.EMPTY_PANNING
renoise.PatternLine.EMPTY_DELAY

renoise.PatternLine.EMPTY_EFFECT_NUMBER
renoise.PatternLine.EMPTY_EFFECT_AMOUNT


-------- functions

-- clear all note and effect columns
renoise.song().patterns[].tracks[].lines[]:clear()

-- copy contents from other_line, trashing column content
renoise.song().patterns[].tracks[].lines[]:copy_from(other_line object)


-------- properties

renoise.song().patterns[].tracks[].lines[].is_empty 
  -> [boolean]

renoise.song().patterns[].tracks[].lines[].note_columns 
  -> [read-only, array of renoise.NoteColumn objects]

renoise.song().patterns[].tracks[].lines[].effect_columns 
  -> [read-only, array of renoise.EffectColumn objects]


--------------------------------------------------------------------------------
-- renoise.NoteColumn
--------------------------------------------------------------------------------

-------- functions

-- clear the note column
renoise.song().patterns[].tracks[].lines[].note_columns[]:clear()

-- copy the columns content from another column
renoise.song().patterns[].tracks[].lines[].note_columns[]:copy_from(other_column object)


-------- properties

-- true, when all properties are empty
renoise.song().patterns[].tracks[].lines[].note_columns[].is_empty 
  -> [read-only, boolean]
-- true, when this column is selected in the pattern_editors current pattern
renoise.song().patterns[].tracks[].lines[].note_columns[].is_selected 
  -> [read-only, boolean]

-- access note column properties either by values (numbers) or by strings
-- the string representation uses exactly the same notation as you see them
-- in Renoise's pattern editor

renoise.song().patterns[].tracks[].lines[].note_columns[].note_value 
  -> [number, 0-119, 120=Off, 121=Empty]
renoise.song().patterns[].tracks[].lines[].note_columns[].note_string 
  -> [string, 'C-0' - 'G-9', 'Off' or '---']

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


--------------------------------------------------------------------------------
-- renoise.EffectColumn
--------------------------------------------------------------------------------

-------- functions

-- clear the effect column
renoise.song().patterns[].tracks[].lines[].effect_columns[]:clear()

-- copy the columns content from another column
renoise.song().patterns[].tracks[].lines[].effect_columns[]:copy_from(other_column object)


-------- properties

-- true, when all properties are empty
renoise.song().patterns[].tracks[].lines[].effect_columns[].is_empty 
  -> [read-only, boolean]
-- true, when this column is selected in the pattern_editors current pattern
renoise.song().patterns[].tracks[].lines[].effect_columns[].is_selected 
  -> [read-only, boolean]

-- access effect column properties either by values (numbers) or by strings

renoise.song().patterns[].tracks[].lines[].effect_columns[].number_value 
  -> [number, 0-255]
renoise.song().patterns[].tracks[].lines[].effect_columns[].number_string 
  -> [string, '00' - 'FF']

renoise.song().patterns[].tracks[].lines[].effect_columns[].amount_value 
  -> number, 0-255]
renoise.song().patterns[].tracks[].lines[].effect_columns[].amount_string 
  -> [string, '00' - 'FF']

