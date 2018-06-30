--[[============================================================================
-- NTrapPrefs
============================================================================]]--

--[[--

Preferences for Noodletrap

--]]


--==============================================================================

class 'NTrapPrefs'(renoise.Document.DocumentNode)

NTrapPrefs.NO_INPUT = "No MIDI input selected"
NTrapPrefs.YIELD_DEFAULT = 100

NTrapPrefs.ARM_MANUAL = 1
NTrapPrefs.ARM_PLAYBACK = 2
NTrapPrefs.ARM_EDITMODE = 3
NTrapPrefs.ARM = {
  "Manual ('Start')",
  "When playback starts",
  "When edit-mode is disabled",
}

NTrapPrefs.START_NOTE = 1
NTrapPrefs.START_PLAYBACK = 2
NTrapPrefs.START_PATTERN = 3
NTrapPrefs.START = {
  "First incoming note",
  "When playback starts",
  "Beginning of pattern",
}

NTrapPrefs.SPLIT_LINES_DEFAULT = 128
NTrapPrefs.SPLIT_MANUAL = 1
NTrapPrefs.SPLIT_PATTERN = 2
NTrapPrefs.SPLIT_LINES = 3
NTrapPrefs.SPLIT = {
  "Manual ('Split')",
  "End of pattern",
  "When more than #lines -->",
}

NTrapPrefs.STOP_BEATS_DEFAULT = 4
NTrapPrefs.STOP_LINES_DEFAULT = 128
NTrapPrefs.STOP_NOTE = 1
NTrapPrefs.STOP_LINES = 2
NTrapPrefs.STOP_PATTERN = 3
NTrapPrefs.STOP = {
  "After last note --> beats",
  "After number of lines -->",
  "At end of pattern",
}

NTrapPrefs.QUANTIZE_DEFAULT = 1
NTrapPrefs.QUANTIZE_NONE = 1
NTrapPrefs.QUANTIZE_RENOISE = 2
NTrapPrefs.QUANTIZE_CUSTOM = 3
NTrapPrefs.QUANTIZE = {
  "No quantize",
  "Sync with Renoise",
  "Specify quantize", 
}

NTrapPrefs.PHRASE_LENGTH_DEFAULT = 32
NTrapPrefs.PHRASE_LENGTH = {
  "Base on selected phrase",
  "Base on current pattern",
  "Custom value",
}

NTrapPrefs.LPB_DEFAULT = 8
NTrapPrefs.LPB_FROM_PHRASE = 1
NTrapPrefs.LPB_FROM_SONG = 2
NTrapPrefs.LPB_CUSTOM = 3
NTrapPrefs.PHRASE_LPB = {
  "Base on selected phrase",
  "Base on current song",
  "Specify LPB value",
}

NTrapPrefs.LOOP_FROM_PHRASE = 1
NTrapPrefs.LOOP_CUSTOM = 2
NTrapPrefs.LOOP = {
  "Base on selected phrase",
  "Specify loop mode",
}

NTrapPrefs.LOOP_DEFAULT = true
NTrapPrefs.LOOP_ITEMS = {
  "Disabled",
  "Enabled",
}

NTrapPrefs.PHRASE_RANGE_DEFAULT = 12
NTrapPrefs.PHRASE_RANGE_COPY = 1
NTrapPrefs.PHRASE_RANGE_CUSTOM = 2
NTrapPrefs.PHRASE_RANGE = {
  "Base on selected phrase",
  "Specify #semitones -->",
}

NTrapPrefs.PHRASE_OFFSET_DEFAULT = 1
NTrapPrefs.PHRASE_OFFSET_COPY = 1
NTrapPrefs.PHRASE_OFFSET_CUSTOM = 2
NTrapPrefs.PHRASE_OFFSET = {
  "Base on selected phrase",
  "Specify note -->",
}

NTrapPrefs.PHRASE_TRACKING_COPY = 1
NTrapPrefs.PHRASE_TRACKING_CUSTOM = 2
NTrapPrefs.PHRASE_TRACKING = {
  "Base on selected phrase",
  "Specify key-tracking",
}

NTrapPrefs.PHRASE_TRACKING_DEFAULT = 1
NTrapPrefs.PHRASE_TRACKING_ITEMS = {
  "None",
  "Transpose",
  "Offset",
}


function NTrapPrefs:__init()

  renoise.Document.DocumentNode.__init(self)

  -- general options
  self:add_property("record_quantize",      renoise.Document.ObservableNumber(NTrapPrefs.QUANTIZE_DEFAULT))
  self:add_property("record_quantize_custom", renoise.Document.ObservableNumber(1))
  self:add_property("quantize_preserve_length", renoise.Document.ObservableBoolean(true))
  self:add_property("midi_in_port",         renoise.Document.ObservableString(NTrapPrefs.NO_INPUT))
  self:add_property("keyboard_enabled",     renoise.Document.ObservableBoolean(false))
  

  -- recording options
  self:add_property("arm_recording",        renoise.Document.ObservableNumber(1))
  self:add_property("start_recording",      renoise.Document.ObservableNumber(1))
  self:add_property("split_recording",       renoise.Document.ObservableNumber(1))
  self:add_property("split_recording_lines", renoise.Document.ObservableNumber(NTrapPrefs.SPLIT_LINES_DEFAULT))
  self:add_property("stop_recording",       renoise.Document.ObservableNumber(1))
  self:add_property("stop_recording_beats", renoise.Document.ObservableNumber(NTrapPrefs.STOP_BEATS_DEFAULT))
  self:add_property("stop_recording_lines", renoise.Document.ObservableNumber(NTrapPrefs.STOP_LINES_DEFAULT))


  -- phrase options
  self:add_property("phrase_lpb",           renoise.Document.ObservableNumber(NTrapPrefs.LPB_FROM_SONG))
  self:add_property("phrase_lpb_custom",    renoise.Document.ObservableNumber(NTrapPrefs.LPB_DEFAULT))
  self:add_property("phrase_loop",          renoise.Document.ObservableNumber(1))
  self:add_property("phrase_loop_custom",   renoise.Document.ObservableBoolean(NTrapPrefs.LOOP_DEFAULT))
  self:add_property("phrase_range",         renoise.Document.ObservableNumber(1))
  self:add_property("phrase_range_custom",  renoise.Document.ObservableNumber(NTrapPrefs.PHRASE_RANGE_DEFAULT))
  self:add_property("phrase_offset",         renoise.Document.ObservableNumber(1))
  self:add_property("phrase_offset_custom",  renoise.Document.ObservableNumber(NTrapPrefs.PHRASE_OFFSET_DEFAULT))
  self:add_property("phrase_tracking",        renoise.Document.ObservableNumber(1))
  self:add_property("phrase_tracking_custom", renoise.Document.ObservableNumber(NTrapPrefs.PHRASE_TRACKING_DEFAULT))

  -- settings
  self:add_property("autorun_enabled",    renoise.Document.ObservableBoolean(false))
  self:add_property("skip_empty_enabled", renoise.Document.ObservableBoolean(true))
  self:add_property("yield_counter",      renoise.Document.ObservableNumber(NTrapPrefs.YIELD_DEFAULT))
  self:add_property("log_events",      renoise.Document.ObservableBoolean(false))


end


