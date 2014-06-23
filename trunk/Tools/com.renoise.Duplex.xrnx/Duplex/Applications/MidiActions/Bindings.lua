--[[============================================================================
-- Duplex.Applications.MidiActions.Bindings
============================================================================]]--

--[[--

This is a configuration file for the MidiActions application, supplying semantic information about known/common Renoise MIDI mappings.

### Possible entries: 

    name        string, matches an entry in GlobalMidiActions
    label       string, assign label to the control (button)
    is_boolean  boolean, treat the value as a boolean value
    is_integer  boolean, treat the value as an integer value
    minimum     number or function, the smallest possible value 
    maximum     number or function, the biggest possible value 
    value_func  function, return the current value 
    observable  function, return Observable 
    param       function, return DeviceParameter
    offset      number, offset value by amount

### How to use:
 
Specify a `value_func`, and the parameter will be synchronized to your controller at all times. 

`Param` does the same, but will query the parameter directly, to obtain the min/max settings. 

If `param` is not defined (only a few entries are actual parameters), you can specify a custom minimum/maximum value. 

Specify an `observable` to respond to changes from Renoise. This is more efficient than polling the value (as value_func does), but it's not perfect: MidiActions will not able to tell the value, only that it has changed value since the last time it was polled. For this reason, it's optimal to specify both `observable` as well as `value_func` and/or `param` 
 
See also @{Duplex.Applications.MidiActions}
]]


MidiActions.assist_table = {

  {
    name = "Transport:Playback:Panic [Trigger]",  
    label = "Panic",
  },
  {
    name = "Transport:Playback:Start Playing [Trigger]",  
    label = "Play",
  },
  {
    name = "Transport:Playback:Stop Playing [Trigger]",  
    label = "Stop",
  },
  {
    name = "Transport:Playback:Start/Stop Playing [Set]", 
    label = "Play",
    is_boolean = true,
    observable = function()
      return renoise.song().transport.playing_observable
    end,
    value_func = function()
      return renoise.song().transport.playing
    end
  },
  {
    name = "Transport:Playback:Loop Pattern [Set]",   
    label = "Loop",
    is_boolean = true,
    observable = function()
      return renoise.song().transport.loop_pattern_observable
    end,
    value_func = function()
      return renoise.song().transport.loop_pattern
    end
  },
  --[[
  {
    name = "Transport:Playback:Loop Pattern [Toggle]",   
    label = "Loop",
    is_boolean = true,
    observable = function()
      return renoise.song().transport.loop_pattern_observable
    end,
    value_func = function()
      return renoise.song().transport.loop_pattern
    end
  },
  ]]
  {
    name = "Transport:Playback:Loop Block [Set]",   
    label = "LoopBlock",
    is_boolean = true,
    value_func = function() 
      return renoise.song().transport.loop_block_enabled 
    end,
  },
  --[[
  {
    name = "Transport:Playback:Loop Block [Toggle]",   
    label = "LoopBlock",
    is_boolean = true,
    value_func = function() 
      return renoise.song().transport.loop_block_enabled 
    end,
  },
  ]]
  {
    name = "Transport:Playback:Loop Block Range [Set]",   
    label = "LoopBlock#",
    is_integer = true,
    minimum = 16,
    maximum = 2,
    value_func = function()
      return renoise.song().transport.loop_block_range_coeff
    end,
  },
  {
    name = "Transport:Playback:Move Loop Block Backwards [Trigger]",
    label = "BlockUp",
  },
  {
    name = "Transport:Playback:Move Loop Block Forwards [Trigger]",
    label = "BlockDown",
  },
  {
    name = "Transport:Playback:Follow Player [Set]", 
    label = "Follow",
    is_boolean = true,
    observable = function()
      return renoise.song().transport.follow_player_observable
    end,
    value_func = function()
      return renoise.song().transport.follow_player
    end
  },
  --[[
  {
    name = "Transport:Playback:Follow Player [Toggle]",  
    label = "Follow",
    is_boolean = true,
    observable = function()
      return renoise.song().transport.follow_player_observable
    end,
    value_func = function()
      return renoise.song().transport.follow_player
    end
  },
  ]]
  {
    name = "Transport:Record:Undo Last Action [Trigger]",
    label = "Undo",
  },
  {
    name = "Transport:Record:Redo Last Action [Trigger]",
    label = "Redo",
  },
  {
    name = "Transport:Record:Metronome Enabled [Set]",  
    label = "Metro",
    is_boolean = true,
    observable = function()
      return renoise.song().transport.metronome_enabled_observable
    end,
    value_func = function()
      return renoise.song().transport.metronome_enabled
    end
  },
  --[[
  {
    name = "Transport:Record:Metronome Enabled [Toggle]",  
    label = "Metronome",
    is_boolean = true,
    observable = function()
      return renoise.song().transport.metronome_enabled_observable
    end,
    value_func = function()
      return renoise.song().transport.metronome_enabled
    end
  },
  ]]
  {
    name = "Transport:Record:Chord Mode Enabled [Set]",
    label = "Chord",
    is_boolean = true,
    observable = function()
      return renoise.song().transport.chord_mode_enabled_observable
    end,
    value_func = function()
      return renoise.song().transport.chord_mode_enabled
    end
  },
  --[[
  {
    name = "Transport:Record:Chord Mode Enabled [Toggle]",
    label = "Chord",
    is_boolean = true,
    observable = function()
      return renoise.song().transport.chord_mode_enabled_observable
    end,
    value_func = function()
      return renoise.song().transport.chord_mode_enabled
    end
  },
  ]]
  {
    name = "Transport:Record:Quantization Enabled [Set]",
    label = "Quant",
    is_boolean = true,
    observable = function()
      return renoise.song().transport.record_quantize_enabled_observable
    end,
    value_func = function()
      return renoise.song().transport.record_quantize_enabled
    end
  },
  --[[
  {
    name = "Transport:Record:Quantization Enabled [Toggle]",
    label = "Quant",
    is_boolean = true,
    observable = function()
      return renoise.song().transport.record_quantize_enabled_observable
    end,
    value_func = function()
      return renoise.song().transport.record_quantize_enabled
    end
  },
  ]]
  {
    name = "Transport:Record:Quantization Amount [Set]",  
    label = "Quant#",
    is_integer = true,
    minimum = 1,
    maximum = 32,
    observable = function()
      return renoise.song().transport.record_quantize_lines_observable
    end,
    value_func = function()
      return renoise.song().transport.record_quantize_lines
    end
  },
  --[[
  {
    name = "Transport:Record:Quantization Amount [Toggle]",  
    label = "Quant#",
    minimum = 1,
    maximum = 32,
    observable = function()
      return renoise.song().transport.record_quantize_lines_observable
    end,
    value_func = function()
      return renoise.song().transport.record_quantize_lines
    end
  },
  ]]
  {
    name = "Transport:Record:Decrease Quantization Amount [Trigger]",  
    label = "Quant-",
  },
  {
    name = "Transport:Record:Increase Quantization Amount [Trigger]",  
    label = "Quant+",
  },
  {
    name = "Transport:Record:Parameter Record Mode [Set]",
    label = "RecMode",
    is_boolean = true,
    observable = function() 
      return renoise.song().transport.record_parameter_mode_observable
    end,
    value_func = function() 
      return (renoise.song().transport.record_parameter_mode ==
        renoise.Transport.RECORD_PARAMETER_MODE_AUTOMATION)
    end,
  },
  --[[
  {
    name = "Transport:Record:Parameter Record Mode [Toggle]",
    label = "RecMode",
    is_boolean = true,
    observable = function() 
      return renoise.song().transport.record_parameter_mode_observable
    end,
    value_func = function() 
      return (renoise.song().transport.record_parameter_mode ==
        renoise.Transport.RECORD_PARAMETER_MODE_AUTOMATION)
    end,
  },
  ]]
  {
    name = "Transport:Record:Start/Stop Sample Recording [Trigger]",  
    label = "RecToggle",
  },
  {
    name = "Transport:Record:Cancel Sample Recording [Trigger]",  
    label = "RecCancel",
  },
  {
    name = "Transport:Song:BPM [Set]",
    label = "BPM",
    is_integer = true,
    minimum = 32,
    maximum = 999,
    offset = -60,
    observable = function()
      return renoise.song().transport.bpm_observable
    end,
    value_func = function()
      return renoise.song().transport.bpm
    end
  },
  {
    name = "Transport:Song:Decrease BPM [Trigger]",  
    label = "BPM-",
  },
  {
    name = "Transport:Song:Increase BPM [Trigger]",  
    label = "BPM+",
  },
  {
    name = "Transport:Song:LPB [Set]",
    label = "LPB",
    is_integer = true,
    minimum = 1,
    maximum = 256,
    observable = function()
      return renoise.song().transport.lpb_observable
    end,
    value_func = function()
      return renoise.song().transport.lpb
    end
  },
  {
    name = "Transport:Song:Decrease LPB [Trigger]",  
    label = "LPB-",
  },
  {
    name = "Transport:Song:Increase LPB [Trigger]",  
    label = "LPB+",
  },
  {
    name = "Transport:Song:Shuffle Enabled [Set]",
    label = "Shuffle",
    is_boolean = true,
    observable = function()
      return renoise.song().transport.groove_enabled_observable
    end,
    value_func = function()
      return renoise.song().transport.groove_enabled
    end,
  },
  --[[
  {
    name = "Transport:Song:Shuffle Enabled [Toggle]",
    label = "Shuffle",
    is_boolean = true,
    observable = function()
      return renoise.song().transport.groove_enabled_observable
    end,
    value_func = function()
      return renoise.song().transport.groove_enabled
    end,
  },
  ]]
  {
    name = "Transport:Edit:Edit Mode [Set]",
    label = "Edit",
    is_boolean = true,
    observable = function()
      return renoise.song().transport.edit_mode_observable
    end,
    value_func = function()
      return renoise.song().transport.edit_mode
    end,
    
  },
  --[[
  {
    name = "Transport:Edit:Edit Mode [Toggle]",
    label = "Edit",
    is_boolean = true,
    observable = function()
      return renoise.song().transport.edit_mode_observable
    end,
    value_func = function()
      return renoise.song().transport.edit_mode
    end,
  },
  ]]
  {
    name = "Transport:Edit:Edit Mode Step [Set]",
    label = "Step#",
    is_integer = true,
    minimum = 0,
    maximum = 64,
    observable = function()
      return renoise.song().transport.edit_step_observable
    end,
    value_func = function()
      return renoise.song().transport.edit_step
    end,
  },
  {
    name = "Transport:Edit:Decrease Edit Mode Step [Trigger]",  
    label = "Step-",
  },
  {
    name = "Transport:Edit:Increase Edit Mode Step [Trigger]",  
    label = "Step+",
  },
  {
    name = "Transport:Edit:Octave [Set]",
    label = "Oct#",
    is_integer = true,
    minimum = 0,
    maximum = 8,
    observable = function()
      return renoise.song().transport.octave_observable
    end,
    value_func = function()
      return renoise.song().transport.octave
    end,
  },
  {
    name = "Transport:Edit:Decrease Octave [Trigger]",  
    label = "Oct-",
  },
  {
    name = "Transport:Edit:Increase Octave [Trigger]",  
    label = "Oct+",
  },
  {
    name = "Transport:Edit:Single Track Edit Mode [Set]",
    label = "Single",
    is_boolean = true,
    observable = function()
      return renoise.song().transport.single_track_edit_mode_observable
    end,
    value_func = function()
      return renoise.song().transport.single_track_edit_mode
    end,
  },
  --[[
  {
    name = "Transport:Edit:Single Track Edit Mode [Toggle]",
    label = "Single",
    is_boolean = true,
    observable = function()
      return renoise.song().transport.single_track_edit_mode_observable
    end,
    value_func = function()
      return renoise.song().transport.single_track_edit_mode
    end,
  },
  {
    name = "Transport:Edit:Patternwrap Mode [Toggle]",
    label = "PattWrap",
    is_boolean = true,
    observable = function()
      return renoise.song().transport.wrapped_pattern_edit_observable
    end,
    value_func = function()
      return renoise.song().transport.wrapped_pattern_edit
    end,
  },
  ]]
  {
    name = "Transport:Edit:Patternwrap Mode [Set]",
    label = "PattWrap",
    is_boolean = true,
    observable = function()
      return renoise.song().transport.wrapped_pattern_edit_observable
    end,
    value_func = function()
      return renoise.song().transport.wrapped_pattern_edit
    end,
  },
  {
    name = "Seq. Triggering:Trigger:Current [Trigger]",  
    label = "TrigCurr",
  },
  {
    name = "Seq. Triggering:Trigger:Sequence XX [Set]",
    label = "TrigSeq#",
    is_integer = true,
    minimum = 1,
    maximum = function()
      return renoise.song().transport.song_length.sequence
    end,
  },
  --"Seq. Triggering:Trigger:Sequence XX:Sequence #%02d [Trigger]"
  {
    name = "Seq. Triggering:Schedule:Current [Trigger]",  
    label = "SchedCurr",
  },
  {
    name = "Seq. Triggering:Schedule:Sequence XX [Set]",
    label = "SchedSeq#",
    is_integer = true,
    minimum = 1,
    maximum = function()
      return renoise.song().transport.song_length.sequence
    end,
  },
  --"Seq. Triggering:Schedule:Sequence XX:Sequence #%02d [Trigger]"
  {
    name = "Seq. Triggering:Add Scheduled:Current [Trigger]",  
    label = "AddSchCurr",
  },
  {
    name = "Seq. Triggering:Add Scheduled:Sequence XX [Set]",
    label = "AddSched#",
    is_integer = true,
    minimum = 1,
    maximum = function()
      return renoise.song().transport.song_length.sequence
    end,
  },
  {
    name = "Seq. Triggering:Add Scheduled:Sequence XX:Sequence #* [Trigger]",
    label = "AddSched",
  },
  --[[
  {
    name = "Seq. Muting:Selected Seq. [Toggle]:Mute Track #* [Toggle]",
    label = "SeqMuteTrk",
  },
  ]]
  {
    name = "Seq. Muting:Selected Seq. [Set]:Mute Track #* [Set]",
    label = "S.Mute",
    is_boolean = true,
    value_func = function(trk_idx)
      local rns = renoise.song()
      if rns.tracks[trk_idx] then
        local seq_idx = rns.selected_sequence_index
        local is_muted = rns.sequencer:track_sequence_slot_is_muted(trk_idx, seq_idx)
        return is_muted
      end
    end,
  },
  --"Seq. Muting:Seq. XX [Toggle]:Seq. #%02d:Mute Track #%02d [Toggle]"
  --"Seq. Muting:Seq. XX [Set]:Seq. #%02d:Mute Track #%02d [Set]"
  {
    name = "Track Muting:Mute All [Trigger]",  
    label = "MuteAll",
  },
  {
    name = "Track Muting:Unmute All [Trigger]",  
    label = "UnmuteAll",
  },
  --[[
  {
    name = "Track Muting:Mute/Unmute:Current Track [Toggle]",
    label = "MuteCurr",
    is_boolean = true,
    value_func = function()
      local track = renoise.song().selected_track
      if track.mute_state == renoise.Track.MUTE_STATE_ACTIVE and
        track.type ~= renoise.Track.TRACK_TYPE_MASTER 
      then
        return false
      end
      return true
    end,
  },
  ]]
  {
    name = "Track Muting:Mute/Unmute:Current Track [Set]",
    label = "MuteCurr",
    is_boolean = true,
    value_func = function()
      local track = renoise.song().selected_track
      if track.mute_state == renoise.Track.MUTE_STATE_ACTIVE and
        track.type ~= renoise.Track.TRACK_TYPE_MASTER 
      then
        return false
      end
      return true
    end,
  },
  {
    name = "Track Muting:Solo:Current Track [Trigger]",  
    label = "SoloCurr",
  },
  {
    name = "Track Muting:Mute/Unmute:Track XX [Set]:Track #* [Set]",
    label = "Mute",
    is_boolean = true,
    value_func = function(trk_idx)
      local track = renoise.song().tracks[trk_idx]
      if track then
        if track.mute_state == renoise.Track.MUTE_STATE_ACTIVE and
          track.type ~= renoise.Track.TRACK_TYPE_MASTER 
        then
          return false
        end
      end
      return true
    end,
    observable = function(trk_idx)
      local rns = renoise.song()
      local track = rns.tracks[trk_idx]
      if track then
        return rns.tracks[trk_idx].mute_state_observable
      end
    end,
  },
  {
    name = "Track Muting:Solo:Track XX:Track #* [Trigger]",
    label = "Solo",
  },
  --[[
  {
    name = "Track Muting:Mute/Unmute:Send Track XX [Toggle]:Send Track #* [Toggle]",
    label = "SendTrkMuteToggle",
  },
  ]]
  {
    name = "Track Muting:Mute/Unmute:Send Track XX [Set]:Send Track #* [Set]",
    label = "SendTrkMuteToggle",
    is_boolean = true,
    value_func = function(send_index)
      local rns = renoise.song()
      local track = send_track(send_index)
      if track then
        if track.mute_state == renoise.Track.MUTE_STATE_ACTIVE and
          track.type ~= renoise.Track.TRACK_TYPE_MASTER 
        then
          return false
        end
      end
      return true
    end,
    observable = function(send_index)
      local rns = renoise.song()
      local track = send_track(send_index)
      if track then
        return track.mute_state_observable
      end
    end,

  },
  {
    name = "Track Muting:Solo:Send Track XX:Send Track #* [Trigger]",
    label = "SoloSendTrk",
  },
  {
    name = "Track Levels:Volume:Current Track (Pre) [Set]",
    label = "VolCurr",
    param = function()
      return renoise.song().selected_track.prefx_volume
    end,
  },
  {
    name = "Track Levels:Panning:Current Track (Pre) [Set]",
    label = "PanCurr",
    param = function()
      return renoise.song().selected_track.prefx_panning
    end,
  },
  {
    name = "Track Levels:Width:Current Track [Set]",
    label = "WidthCurr",
    param = function()
      return renoise.song().selected_track.prefx_width
    end,
  },
  {
    name = "Track Levels:Volume:Current Track (Post) [Set]",
    label = "VolCurr",
    param = function()
      return renoise.song().selected_track.postfx_volume
    end,
  },
  {
    name = "Track Levels:Panning:Current Track (Post) [Set]",
    label = "PanCurr",
    param = function()
      return renoise.song().selected_track.postfx_panning
    end,
  },
  {
    name = "Track Levels:Volume:Master Track (Pre) [Set]",
    label = "VolMast",
    param = function()
      return get_master_track().prefx_volume
    end,
  },
  {
    name = "Track Levels:Panning:Master Track (Pre) [Set]",
    label = "PanMast",
    param = function()
      return get_master_track().prefx_panning
    end,
  },
  {
    name = "Track Levels:Width:Master Track [Set]",
    label = "WidthMast",
    param = function()
      return get_master_track().prefx_width
    end,
  },
  {
    name = "Track Levels:Volume:Master Track (Post) [Set]",
    label = "VolMast",
    param = function()
      return get_master_track().postfx_volume
    end,
  },
  {
    name = "Track Levels:Panning:Master Track (Post) [Set]",
    label = "PanMast",
    param = function()
      return get_master_track().postfx_panning
    end,
  },
  {
    name = "Track Levels:Volume:Track XX (Pre):Track #* [Set]",
    label = "TrkVol",
    param = function(trk_idx)
      local track = renoise.song().tracks[trk_idx]
      if track then
        return track.prefx_volume
      end
    end,
  },
  {
    name = "Track Levels:Volume:Track XX (Post):Track #* [Set]",
    label = "TrkVolP",
    param = function(trk_idx)
      local track = renoise.song().tracks[trk_idx]
      if track then
        return track.postfx_volume
      end
    end,
  },
  {
    name = "Track Levels:Panning:Track XX (Pre):Track #* [Set]",
    label = "TrkPan",
    param = function(trk_idx)
      local track = renoise.song().tracks[trk_idx]
      if track then
        return track.prefx_panning
      end
    end,
  },
  {
    name = "Track Levels:Panning:Track XX (Post):Track #* [Set]",
    label = "TrkPan",
    param = function(trk_idx)
      local track = renoise.song().tracks[trk_idx]
      if track then
        return track.postfx_panning
      end
    end,
  },
  {
    name = "Track Levels:Width:Track XX:Track #* [Set]",
    label = "TrkWidth",
    param = function(trk_idx)
      local track = renoise.song().tracks[trk_idx]
      if track then
        return track.prefx_width
      end
    end,
  },
  {
    name = "Track Levels:Volume:Send Track XX (Pre):Send Track #* [Set]",
    label = "SendTrkVol",
    param = function(send_index)
      local rns = renoise.song()
      local track = send_track(send_index)
      if track then
        return track.prefx_volume
      end
    end,
  },
  {
    name = "Track Levels:Volume:Send Track XX (Post):Send Track #* [Set]",
    label = "SendTrkVolP",
    param = function(send_index)
      local rns = renoise.song()
      local track = send_track(send_index)
      if track then
        return track.postfx_volume
      end
    end,
  },
  {
    name = "Track Levels:Panning:Send Track XX (Pre):Send Track #* [Set]",
    label = "SendTrkPanP",
    param = function(send_index)
      local rns = renoise.song()
      local track = send_track(send_index)
      if track then
        return track.prefx_panning
      end
    end,
  },
  {
    name = "Track Levels:Panning:Send Track XX (Post):Send Track #* [Set]",
    label = "SendTrkPanP",
    param = function(send_index)
      local rns = renoise.song()
      local track = send_track(send_index)
      if track then
        return track.postfx_panning
      end
    end,
  },
  {
    name = "Track Levels:Width:Send Track XX:Send Track #* [Set]",
    label = "SendTrkWidth",
    param = function(send_index)
      local rns = renoise.song()
      local track = send_track(send_index)
      if track then
        return track.prefx_width
      end
    end,
  },
  --[[
  {
    name = "Track DSPs:Selected FX Active [Toggle]",
    label = "ToggleDSP",
    is_boolean = true,
    value_func = function()
      if renoise.song().selected_device then
        return renoise.song().selected_device.is_active
      end
    end,
  },
  ]]
  {
    name = "Track DSPs:Selected FX Active [Set]",
    label = "ToggleDSP",
    is_boolean = true,
    value_func = function()
      if renoise.song().selected_device then
        return renoise.song().selected_device.is_active
      end
    end,
  },
  {
    name = "Track DSPs:Selected FX:Parameter #* [Set]",
    label = "FXParam",
    param = function(param_index)
      local sel_device = renoise.song().selected_device
      if sel_device and sel_device.parameters[param_index] then
        return sel_device.parameters[param_index]
      end
    end,
  },
  {
    name = "Track DSPs:Selected FX (Mixer Subset):Parameter #* [Set]",
    label = "FXPrmSub",
  },
  {
    name = "Navigation:Sequencer:Current Sequence Pos [Set]",
    label = "CurrSeq#",
    is_integer = true,
    minimum = 1,
    maximum = function() 
      return renoise.song().transport.song_length.sequence 
    end,
  },
  {
    name = "Navigation:Sequencer:Select Previous Sequence Pos [Trigger]",  
    label = "PrevSeq",
  },
  {
    name = "Navigation:Sequencer:Select Next Sequence Pos [Trigger]",  
    label = "NextSeq",
  },
  {
    name = "Navigation:Sequencer:Current Pattern [Set]",  
    label = "CurrPatt",
    is_integer = true,
    minimum = 1,
    maximum = 1000,
    observable = function()
      return renoise.song().selected_pattern_index_observable
    end,
  },
  {
    name = "Navigation:Sequencer:Decrease Current Pattern [Trigger]",  
    label = "CurrPatt-",
  },
  {
    name = "Navigation:Sequencer:Increase Current Pattern [Trigger]",  
    label = "CurrPatt+",
  },
  {
    name = "Navigation:Tracks:Current Track [Set]",
    label = "CurrTrk#",
    is_integer = true,
    minimum = 1,
    maximum = function() 
      return #renoise.song().tracks 
    end,
    observable = function()
      return renoise.song().selected_track_index_observable
    end,
  },
  {
    name = "Navigation:Tracks:Select Previous Track [Trigger]",  
    label = "PrevTrk",
  },
  {
    name = "Navigation:Tracks:Select Next Track [Trigger]",  
    label = "NextTrk",
  },
  {
    name = "Navigation:Columns:Select Previous Column [Trigger]",  
    label = "PrevCol",
  },
  {
    name = "Navigation:Columns:Select Next Column [Trigger]",  
    label = "NextCol",
  },
  {
    name = "Navigation:Columns:Select Previous Note Column [Trigger]",  
    label = "NoteCol-",
  },
  {
    name = "Navigation:Columns:Select Next Note Column [Trigger]",  
    label = "NoteCol+",
  },
  --[[
  {
    name = "Navigation:Columns:Show Volume Column [Toggle]",
    label = "VolCol",
    is_boolean = true,
    value_func = function()
      return renoise.song().selected_track.volume_column_visible
    end,
  },
  ]]
  {
    name = "Navigation:Columns:Show Volume Column [Set]",
    label = "VolCol",
    is_boolean = true,
    value_func = function()
      return renoise.song().selected_track.volume_column_visible
    end,
  },
  --[[
  {
    name = "Navigation:Columns:Show Panning Column [Toggle]",
    label = "PanCol",
    is_boolean = true,
    value_func = function()
      return renoise.song().selected_track.panning_column_visible
    end,
  },
  ]]
  {
    name = "Navigation:Columns:Show Panning Column [Set]",
    label = "PanCol",
    is_boolean = true,
    value_func = function()
      return renoise.song().selected_track.panning_column_visible
    end,
  },
  --[[
  {
    name = "Navigation:Columns:Show Delay Column [Toggle]",
    label = "DlyCol",
    is_boolean = true,
    value_func = function()
      return renoise.song().selected_track.delay_column_visible
    end,
  },
  ]]
  {
    name = "Navigation:Columns:Show Delay Column [Set]",
    label = "DlyCol",
    is_boolean = true,
    value_func = function()
      return renoise.song().selected_track.delay_column_visible
    end,
  },
  {
    name = "Navigation:Track DSPs:Current Track DSP [Set]",
    label = "CurrDSP#",
    is_integer = true,
    minimum = 1,
    maximum = function() 
      return #renoise.song().selected_track.devices 
    end,
    observable = function()
      return renoise.song().selected_device_index_observable
    end
  },
  {
    name = "Navigation:Track DSPs:Select Previous Track DSP [Trigger]",  
    label = "PrevDSP",
  },
  {
    name = "Navigation:Track DSPs:Select Next Track DSP [Trigger]",  
    label = "NextDSP",
  },
  {
    name = "Navigation:Instruments:Current Instrument [Set]",
    label = "Instr#",
    is_integer = true,
    minimum = 1,
    maximum = function() 
      return #renoise.song().instruments 
    end,
    observable = function()
      return renoise.song().selected_instrument_index_observable
    end,
    value_func = function()
      return renoise.song().selected_instrument_index
    end
  },
  {
    name = "Navigation:Instruments:Decrease Current Instrument [Trigger]",  
    label = "Instr-",
  },
  {
    name = "Navigation:Instruments:Increase Current Instrument [Trigger]",  
    label = "Instr+",
  },
  {
    name = "Navigation:Instruments:Capture Nearest From Pattern [Trigger]",  
    label = "CaptNear",
  },
  {
    name = "Navigation:Instruments:Capture From Pattern [Trigger]",  
    label = "Capture",
  },
  --[[
  {
    name = "GUI:Window:Fullscreen Mode [Toggle]",
    label = "FullScr",
    is_boolean = true,
    value_func = function() 
      return renoise.app().window.fullscreen
    end,
  },
  ]]
  {
    name = "GUI:Window:Fullscreen Mode [Set]",
    label = "FullScr",
    is_boolean = true,
    value_func = function() 
      return renoise.app().window.fullscreen
    end,
  },
  {
    name = "GUI:Dialogs:Show Sample Recorder [Set]",
    label = "RecDlg",
    is_boolean = true,
    value_func = function() 
      return renoise.app().window.sample_record_dialog_is_visible
    end,
  },
  --[[
  {
    name = "GUI:Dialogs:Show Sample Recorder [Toggle]",
    label = "RecDlg",
    is_boolean = true,
    value_func = function() 
      return renoise.app().window.sample_record_dialog_is_visible
    end,
  },
  ]]
  {
    name = "GUI:Presets:Activate Preset [Set]",           
    label = "Preset",
    is_integer = true,
    minimum = 1,
    maximum = 8,
  },
  {
    name = "GUI:Presets:Activate Preset #* [Trigger]",
    label = "Preset",
  },
  --[[
  {
    name = "GUI:Upper Frame:Show Upper Frame [Toggle]",
    label = "Upper",
    is_boolean = true,
    value_func = function() 
      return renoise.app().window.upper_frame_is_visible
    end,
  },
  ]]
  {
    name = "GUI:Upper Frame:Show Upper Frame [Set]",
    label = "Upper",
    is_boolean = true,
    value_func = function() 
      return renoise.app().window.upper_frame_is_visible
    end,
  },
  {
    name = "GUI:Upper Frame:Select Previous [Trigger]",  
    label = "Upper-",
  },
  {
    name = "GUI:Upper Frame:Select Next [Trigger]",  
    label = "Upper+",
  },
  {
    name = "GUI:Upper Frame:Select [Set]",
    label = "Upper#",
    is_integer = true,
    minimum = 1,
    maximum = 4
  },
  {
    name = "GUI:Show Disk Browser [Trigger]",  
    label = "Browser",
  },
  {
    name = "GUI:Upper Frame:Show Track Scopes [Trigger]",  
    label = "Scopes",
  },
  --[[
  {
    name = "GUI:Upper Frame:Show Master Scopes [Trigger]",  
    label = "MstScopes",
  },
  ]]
  {
    name = "GUI:Upper Frame:Show Master Spectrum [Trigger]",  
    label = "Spectrum",
  },
  {
    name = "GUI:Middle Frame:Select Previous [Trigger]",  
    label = "Middle-",
  },
  {
    name = "GUI:Middle Frame:Select Next [Trigger]",  
    label = "Middle+",
  },
  {
    name = "GUI:Middle Frame:Select [Set]",
    label = "Middle#",
    is_integer = true,
    minimum = 1,
    maximum = 4
  },
  {
    name = "GUI:Middle Frame:Show Pattern Editor [Trigger]",  
    label = "Pattern",
  },
  {
    name = "GUI:Middle Frame:Show Mixer [Trigger]",  
    label = "Mixer",
  },
  {
    name = "GUI:Middle Frame:Show Key-Zone Editor [Trigger]",  
    label = "KeyZone",
  },
  {
    name = "GUI:Middle Frame:Show Sample Editor [Trigger]",  
    label = "Sampler",
  },
  {
    name = "GUI:Middle Frame:Show Pattern Matrix [Set]",
    label = "Matrix",
    is_boolean = true,
    value_func = function() 
      return renoise.app().window.pattern_matrix_is_visible
    end,
  },
  --[[
  {
    name = "GUI:Middle Frame:Show Pattern Matrix [Toggle]",
    label = "Matrix",
    is_boolean = true,
    value_func = function() 
      return renoise.app().window.pattern_matrix_is_visible
    end,
  },
  ]]
  {
    name = "GUI:Middle Frame:Show Pattern Advanced Edit [Set]",
    label = "AdvEdit",
    is_boolean = true,
    value_func = function() 
      return renoise.app().window.pattern_advanced_edit_is_visible
    end,
  },
  --[[
  {
    name = "GUI:Middle Frame:Show Pattern Advanced Edit [Toggle]",
    label = "AdvEdit",
    is_boolean = true,
    value_func = function() 
      return renoise.app().window.pattern_advanced_edit_is_visible
    end,
  },
  {
    name = "GUI:Lower Frame:Show Lower Frame [Toggle]",
    label = "Lower",
    is_boolean = true,
    value_func = function() 
      return renoise.app().window.lower_frame_is_visible
    end,
  },
  ]]
  {
    name = "GUI:Lower Frame:Show Lower Frame [Set]",
    label = "Lower",
    is_boolean = true,
    value_func = function() 
      return renoise.app().window.lower_frame_is_visible
    end,
  },
  {
    name = "GUI:Lower Frame:Select Previous [Trigger]",  
    label = "Lower-",
  },
  {
    name = "GUI:Lower Frame:Select Next [Trigger]",  
    label = "Lower-",
  },
  {
    name = "GUI:Lower Frame:Select [Set]",
    label = "Lower#",
    is_integer = true,
    minimum = 1,
    maximum = 4
  },
  {
    name = "GUI:Lower Frame:Show Track DSPs [Trigger]",  
    label = "TrackDSP",
  },
  {
    name = "GUI:Lower Frame:Show Track Automation [Trigger]",  
    label = "Automation",
  },
  {
    name = "GUI:Lower Frame:Show Instrument Properties [Trigger]",  
    label = "Instrument",
  },
  {
    name = "GUI:Lower Frame:Show Song Properties [Trigger]",  
    label = "Song",
  },
}

