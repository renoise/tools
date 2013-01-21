
--[[============================================================================
preset_manager.lua
============================================================================]]--

class "PresetTable" (renoise.Document.DocumentNode)
  function PresetTable:__init()    
    renoise.Document.DocumentNode.__init(self) 
    self:add_property("PresetVersion", "2.00")
    for x = 1,#pat_preset_table do
      self:add_property(pat_preset_table[x], "00")
    end
  end
  
class "PatternPresetTable" (renoise.Document.DocumentNode)
  function PatternPresetTable:__init()    
    renoise.Document.DocumentNode.__init(self) 
    self:add_property("PresetVersion", "3.00")
    for x = 1,#pat_preset_table do
      self:add_property(pat_preset_table[x], "00")
    end
  end
  
class "EnvelopePresetTable" (renoise.Document.DocumentNode)
  function EnvelopePresetTable:__init()    
    renoise.Document.DocumentNode.__init(self) 
    self:add_property("PresetVersion", "3.15")
    for x = 1,#env_preset_table do
      self:add_property(env_preset_table[x], "00")
    end
  end

local pat_preset_table = PatternPresetTable()
local env_preset_table = EnvelopePresetTable()


---------------------------------------------------------------------------------------

function get_preset_list(vb)
  local preset_root = get_tools_root().."com.renoise.EpicArpeggiator.xrnx"
  local preset_folder = preset_root..PATH_SEPARATOR.."presets"..PATH_SEPARATOR
  local env_preset_folder = preset_root..PATH_SEPARATOR.."env_presets"..PATH_SEPARATOR
  check_preset_folder(preset_root)
  
  local preset_files = os.filenames(preset_folder)
  local env_preset_files = os.filenames(env_preset_folder)
  
  for _ = 1, #preset_files do
    preset_files[_] = string.gsub(preset_files[_],".xml","")
  end
  ea_gui.views.popup_preset.items = preset_files
  for _ = 1, #env_preset_files do
    env_preset_files[_] = string.gsub(env_preset_files[_],".xml","")
  end
  ea_gui.views.env_popup_preset.items = env_preset_files
end


---------------------------------------------------------------------------------------

function save_preset(preset_name,type,vb)
  local preset_root = get_tools_root().."com.renoise.EpicArpeggiator.xrnx"

  if type == PATTERN then
    pat_preset_table:property("Scheme").value = tostring(vb.views.switch_note_pattern.value)
  
    local checkbox = nil
    local cb = vb.views
    local tone_matrix = {}
    for t = 0, NUM_OCTAVES-1 do
      local oct = tostring(t)
      for i = 1, NUM_NOTES do
        if string.find(note_matrix[i], "#") then
            checkbox = note_matrix[i-1].."f"..oct
        else
            checkbox = note_matrix[i].."_"..oct
        end
        tone_matrix[t*NUM_NOTES + i]=tostring(cb[checkbox].value)
      end
    end
    local tm_serialized = table.serialize(tone_matrix,",")  
    pat_preset_table:property("NoteMatrix").value = tm_serialized
    pat_preset_table:property("NoteProfile").value = tostring(vb.views.custom_note_profile.value)
    pat_preset_table:property("Distance").value = tostring(vb.views.vbox_distance_step.value)
    pat_preset_table:property("DistanceMode").value = tostring(vb.views.popup_distance_mode.value)
    pat_preset_table:property("OctaveRotation").value = tostring(vb.views.popup_octave_order.value)
    pat_preset_table:property("OctaveRepeat").value = tostring(vb.views.octave_repeat_mode.value)
    pat_preset_table:property("Termination").value = tostring(vb.views.vbox_termination_step.value)
    pat_preset_table:property("TerminationMode").value =  tostring(vb.views.popup_note_termination_mode.value)
    pat_preset_table:property("NoteRotation").value = tostring(vb.views.popup_note_order.value)
    pat_preset_table:property("NoteRepeat").value = tostring(vb.views.repeat_note.value)
  
    pat_preset_table:property("ArpeggioPattern").value = tostring(vb.views.switch_arp_pattern.value)
    pat_preset_table:property("CustomPattern").value = tostring(vb.views.custom_arpeggiator_profile.value)
  
    pat_preset_table:property("NoteColumns").value = tostring(vb.views.max_note_colums.value)
    pat_preset_table:property("ChordMode").value = tostring(vb.views.chord_mode_box.value)
  
    pat_preset_table:property("InstrumentPool").value = tostring(vb.views.popup_procins.value)
    pat_preset_table:property("InstrumentRotation").value = tostring(vb.views.popup_ins_insertion.value)
    pat_preset_table:property("InstrumentRepeat").value = tostring(vb.views.repeat_instrument.value)
  
    pat_preset_table:property("VolumePool").value = tostring(vb.views.popup_procvel.value)
    pat_preset_table:property("VolumeRotation").value = tostring(vb.views.popup_vel_insertion.value)
    pat_preset_table:property("VolumeRepeat").value = tostring(vb.views.repeat_velocity.value)
  
    
    pat_preset_file = preset_root..PATH_SEPARATOR.."presets"..PATH_SEPARATOR..preset_name..".xml"
    
    check_preset_folder(preset_root)
    if io.exists(pat_preset_file) and preset_conversion_mode == false then
      local status = file_exists_dialog(preset_name)
      if status == false then
        return
      end
    end
    local ok,err = pat_preset_table:save_as(pat_preset_file)
  else
    env_preset_table:property("PresetVersion").value = "3.15"
    env_preset_table:property("Scheme").value = ''
    env_preset_table:property("PointSequences").value = ''
    env_preset_table:property("NoteScheme").value = tostring(env_pitch_scheme)
    env_preset_table:property("NotePointSequences").value = tostring(note_point_scheme)
    env_preset_table:property("NoteSchemeSize").value = tostring(note_scheme_size)
    env_preset_table:property("NoteLoopMode").value = tostring(auto_note_loop)
    env_preset_table:property("NoteLoopType").value = tostring(note_loop_type)
    env_preset_table:property("NoteDrawType").value = tostring(env_pitch_type)
    env_preset_table:property("NoteLoopStart").value = tostring(note_loop_start)
    env_preset_table:property("NoteLoopEnd").value = tostring(note_loop_end)
    env_preset_table:property("NoteSustain").value = tostring(note_sustain)
    env_preset_table:property("ToneFactor").value = tostring(env_multiplier)
    env_preset_table:property("Transpose").value = tostring(ea_gui.views['tone_scope_slider'].value)
    env_preset_table:property("TransposeLink").value = tostring(ea_gui.views['transpose_pitch_scheme'].value)
    env_preset_table:property("LoopAssistance").value = tostring(auto_note_loop)
    env_preset_table:property("NoteFrequencyMode").value = tostring(note_freq_type)
    env_preset_table:property("NoteFrequency").value = tostring(note_freq_val)
    env_preset_table:property("NoteLFOApply").value = tostring(note_lfo_data)
    env_preset_table:property("NoteLFO1").value = tostring(note_lfo1_type)
    env_preset_table:property("NoteLFOPhase1").value = tostring(note_lfo1_phase)
    env_preset_table:property("NoteLFOFrequency1").value = tostring(note_lfo1_freq)
    env_preset_table:property("NoteLFOAmount1").value = tostring(note_lfo1_amount)
    env_preset_table:property("NoteLFO2").value = tostring(note_lfo2_type)
    env_preset_table:property("NoteLFOPhase2").value = tostring(note_lfo2_phase)
    env_preset_table:property("NoteLFOFrequency2").value = tostring(note_lfo2_freq)
    env_preset_table:property("NoteLFOAmount2").value = tostring(note_lfo2_amount)

    env_preset_table:property("VolumeApply").value = tostring(envelope_volume_toggle)
    env_preset_table:property("VolumeScheme").value = tostring(env_vol_scheme)
    env_preset_table:property("VolumePointSequences").value = tostring(volume_point_scheme)
    env_preset_table:property("VolumeSchemeSize").value = tostring(vol_scheme_size)
    env_preset_table:property("VolumeDrawType").value =  tostring(env_volume_type)
    env_preset_table:property("VolumeLoopMode").value =  tostring(auto_vol_loop) 
    env_preset_table:property("VolumeLoopType").value =  tostring(vol_loop_type)
    env_preset_table:property("VolumeLoopStart").value =  tostring(vol_loop_start)
    env_preset_table:property("VolumeLoopEnd").value =  tostring(vol_loop_end)
    env_preset_table:property("VolumeSustain").value =  tostring(vol_sustain)
    env_preset_table:property("VolumeRelease").value =  tostring(vol_release)
    env_preset_table:property("VolumePulseMode").value =  tostring(vol_pulse_mode)
    env_preset_table:property("VolumeHighValue").value =  tostring(ea_gui.views['vol_assist_high_val'].value)
    env_preset_table:property("VolumeLowValue").value =  tostring(ea_gui.views['vol_assist_low_val'].value)
    env_preset_table:property("VolumeHighSize").value =  tostring(ea_gui.views['vol_assist_high_size'].value)
    env_preset_table:property("VolumeFrequencyMode").value = tostring(vol_freq_type)
    env_preset_table:property("VolumeFrequency").value = tostring(vol_freq_val)
    env_preset_table:property("VolumeLFOApply").value = tostring(vol_lfo_data)
    env_preset_table:property("VolumeLFO1").value = tostring(vol_lfo1_type)
    env_preset_table:property("VolumeLFOPhase1").value = tostring(vol_lfo1_phase)
    env_preset_table:property("VolumeLFOFrequency1").value = tostring(vol_lfo1_freq)
    env_preset_table:property("VolumeLFOAmount1").value = tostring(vol_lfo1_amount)
    env_preset_table:property("VolumeLFO2").value = tostring(vol_lfo2_type)
    env_preset_table:property("VolumeLFOPhase2").value = tostring(vol_lfo2_phase)
    env_preset_table:property("VolumeLFOFrequency2").value = tostring(vol_lfo2_freq)
    env_preset_table:property("VolumeLFOAmount2").value = tostring(vol_lfo2_amount)


    
    env_preset_table:property("PanningApply").value = tostring(envelope_panning_toggle)
    env_preset_table:property("PanningScheme").value = tostring(env_pan_scheme)
    env_preset_table:property("PanningPointSequences").value = tostring(panning_point_scheme)
    env_preset_table:property("PanningSchemeSize").value = tostring(pan_scheme_size)
    env_preset_table:property("PanningDrawType").value =  tostring(env_panning_type)
    env_preset_table:property("PanningLoopMode").value =  tostring(auto_pan_loop)
    env_preset_table:property("PanningLoopType").value =  tostring(pan_loop_type)
    env_preset_table:property("PanningLoopStart").value =  tostring(pan_loop_start)
    env_preset_table:property("PanningLoopEnd").value =  tostring(pan_loop_end)
    env_preset_table:property("PanningSustain").value =  tostring(pan_sustain)
    env_preset_table:property("PanningPulseMode").value =  tostring(pan_pulse_mode)
    env_preset_table:property("PanningFirstValue").value =  tostring(ea_gui.views['pan_assist_first_val'].value)
    env_preset_table:property("PanningNextValue").value =  tostring(ea_gui.views['pan_assist_second_val'].value)
    env_preset_table:property("PanningFirstSize").value =  tostring(ea_gui.views['pan_assist_first_size'].value)
    env_preset_table:property("PanningFrequencyMode").value = tostring(pan_freq_type)
    env_preset_table:property("PanningFrequency").value = tostring(pan_freq_val)
    env_preset_table:property("PanningLFOApply").value = tostring(pan_lfo_data)
    env_preset_table:property("PanningLFO1").value = tostring(pan_lfo1_type)
    env_preset_table:property("PanningLFOPhase1").value = tostring(pan_lfo1_phase)
    env_preset_table:property("PanningLFOFrequency1").value = tostring(pan_lfo1_freq)
    env_preset_table:property("PanningLFOAmount1").value = tostring(pan_lfo1_amount)
    env_preset_table:property("PanningLFO2").value = tostring(pan_lfo2_type)
    env_preset_table:property("PanningLFOPhase2").value = tostring(pan_lfo2_phase)
    env_preset_table:property("PanningLFOFrequency2").value = tostring(pan_lfo2_freq)
    env_preset_table:property("PanningLFOAmount2").value = tostring(pan_lfo2_amount)


    env_preset_table:property("CutoffApply").value = tostring(cutoff_data)
    env_preset_table:property("CutoffScheme").value = tostring(env_cut_scheme)
    env_preset_table:property("CutoffPointSequences").value = tostring(cutoff_point_scheme)
    env_preset_table:property("CutoffSchemeSize").value = tostring(cut_scheme_size)
    env_preset_table:property("CutoffDrawType").value =  tostring(env_cutoff_type)
    env_preset_table:property("CutoffEnabled").value =  tostring(cutoff_enabled)
    env_preset_table:property("CutoffLoopType").value =  tostring(cut_loop_type)
    env_preset_table:property("CutoffLoopStart").value =  tostring(cut_loop_start)
    env_preset_table:property("CutoffLoopEnd").value =  tostring(cut_loop_end)
    env_preset_table:property("CutoffSustain").value =  tostring(cut_sustain)
    env_preset_table:property("CutoffLFOApply").value = tostring(cut_lfo_data)
    env_preset_table:property("CutoffLFO").value = tostring(cut_lfo_type)
    env_preset_table:property("CutoffLFOPhase").value = tostring(cut_lfo_phase)
    env_preset_table:property("CutoffLFOFrequency").value = tostring(cut_lfo_freq)
    env_preset_table:property("CutoffLFOAmount").value = tostring(cut_lfo_amount)
    env_preset_table:property("CutoffFollower").value = tostring(cut_follow)
    env_preset_table:property("CutoffFollowerAttack").value = tostring(cut_follow_attack)
    env_preset_table:property("CutoffFollowerRelease").value = tostring(cut_follow_release)
    env_preset_table:property("CutoffFollowerAmount").value = tostring(cut_follow_amount)


    env_preset_table:property("ResonanceApply").value = tostring(resonance_data)
    env_preset_table:property("ResonanceScheme").value = tostring(env_res_scheme)
    env_preset_table:property("ResonancePointSequences").value = tostring(resonance_point_scheme)
    env_preset_table:property("ResonanceSchemeSize").value = tostring(res_scheme_size)
    env_preset_table:property("ResonanceDrawType").value =  tostring(env_resonance_type)
    env_preset_table:property("ResonanceEnabled").value =  tostring(resonance_enabled)
    env_preset_table:property("ResonanceLoopType").value =  tostring(res_loop_type)
    env_preset_table:property("ResonanceLoopStart").value =  tostring(res_loop_start)
    env_preset_table:property("ResonanceLoopEnd").value =  tostring(res_loop_end)
    env_preset_table:property("ResonanceSustain").value =  tostring(res_sustain)
    env_preset_table:property("ResonanceLFOApply").value = tostring(res_lfo_data)
    env_preset_table:property("ResonanceLFO").value = tostring(res_lfo_type)
    env_preset_table:property("ResonanceLFOPhase").value = tostring(res_lfo_phase)
    env_preset_table:property("ResonanceLFOFrequency").value = tostring(res_lfo_freq)
    env_preset_table:property("ResonanceLFOAmount").value = tostring(res_lfo_amount)
    env_preset_table:property("ResonanceFollower").value = tostring(res_follow)
    env_preset_table:property("ResonanceFollowerAttack").value = tostring(res_follow_attack)
    env_preset_table:property("ResonanceFollowerRelease").value = tostring(res_follow_release)
    env_preset_table:property("ResonanceFollowerAmount").value = tostring(res_follow_amount)

    env_preset_table:property("CutResFilterType").value =  tostring(cutres_filter_type)


    env_preset_file = preset_root..PATH_SEPARATOR.."env_presets"..PATH_SEPARATOR..preset_name..".xml"
    
    if type == ENVELOPE_UNDO then
      env_preset_file = preset_root..PATH_SEPARATOR.."undo"..PATH_SEPARATOR..preset_name..".xml"
    end
    
    check_preset_folder(preset_root)
    if io.exists(env_preset_file) and preset_conversion_mode == false then
      if type ~= ENVELOPE_UNDO then
        local status = file_exists_dialog(preset_name)
        if status == false then
          return
        end
      end
    end
    local ok,err = env_preset_table:save_as(env_preset_file)    
  end
  
  get_preset_list(vb)  
end


---------------------------------------------------------------------------------------

function load_preset(preset_name,type,vb)
  --remdebug.engine.start()
  local preset_root = get_tools_root().."com.renoise.EpicArpeggiator.xrnx"

  if type == PATTERN then  
    pat_preset_file = preset_root..PATH_SEPARATOR.."presets"..PATH_SEPARATOR..preset_name..".xml"
  
    get_preset_list(vb)  
    local ok,err = pat_preset_table:load_from(pat_preset_file)
    
    if ok == false then
      --Convert the old Pattern schemes
      if preset_conversion_mode == false then
        preset_conversion_mode = true
        print( 'preset loading error:',err)
        print( 'trying to convert')
        pat_preset_table = PresetTable()
        load_preset(preset_name,type,vb)
        pat_preset_table = PatternPresetTable()
        save_preset(preset_name,type,vb)
        preset_conversion_mode = false
        return
      else
        print( 'preset loading error:',err)
        return
      end
    end
  
    if tab_states.top == 1 then
      if tab_states.sub == 1 then
        vb.views.switch_note_pattern.value = tonumber(pat_preset_table:property("Scheme").value)
      end
    end
    switch_note_pattern_index = tonumber(pat_preset_table:property("Scheme").value)
    
    local tm_serialized = pat_preset_table:property("NoteMatrix").value
    local tone_matrix = tm_serialized:split( "[^,%s]+" )
  
    local checkbox = nil
    local cb = vb.views
    for t = 0, NUM_OCTAVES-1 do
      local oct = tostring(t)
      for i = 1, NUM_NOTES do
        if string.find(note_matrix[i], "#") then
            checkbox = note_matrix[i-1].."f"..oct
        else
            checkbox = note_matrix[i].."_"..oct
        end
        cb[checkbox].value = toboolean(tone_matrix[t*NUM_NOTES + i])
      end
    end
  
    vb.views.custom_note_profile.value = pat_preset_table:property("NoteProfile").value
    vb.views.vbox_distance_step.value = tonumber(pat_preset_table:property("Distance").value)
    vb.views.popup_distance_mode.value = tonumber(pat_preset_table:property("DistanceMode").value)
    vb.views.popup_octave_order.value = tonumber(pat_preset_table:property("OctaveRotation").value)
    vb.views.octave_repeat_mode.value = toboolean(pat_preset_table:property("OctaveRepeat").value)
    
    vb.views.vbox_termination_step.value = tonumber(pat_preset_table:property("Termination").value)
    vb.views.popup_note_termination_mode.value =  tonumber(pat_preset_table:property("TerminationMode").value)
    vb.views.popup_note_order.value = tonumber(pat_preset_table:property("NoteRotation").value)
    vb.views.repeat_note.value = toboolean(pat_preset_table:property("NoteRepeat").value)
  
    vb.views.switch_arp_pattern.value = tonumber(pat_preset_table:property("ArpeggioPattern").value)
    vb.views.custom_arpeggiator_profile.value = pat_preset_table:property("CustomPattern").value
  
    vb.views.max_note_colums.value = tonumber(pat_preset_table:property("NoteColumns").value)
    vb.views.chord_mode_box.value = toboolean(pat_preset_table:property("ChordMode").value)
  
    vb.views.popup_procins.value = pat_preset_table:property("InstrumentPool").value
    vb.views.popup_ins_insertion.value = tonumber(pat_preset_table:property("InstrumentRotation").value)
    vb.views.repeat_instrument.value = toboolean(pat_preset_table:property("InstrumentRepeat").value)
  
    vb.views.popup_procvel.value = pat_preset_table:property("VolumePool").value
    vb.views.popup_vel_insertion.value = tonumber(pat_preset_table:property("VolumeRotation").value)
    vb.views.repeat_velocity.value = toboolean(pat_preset_table:property("VolumeRepeat").value)

  else
    env_preset_file = preset_root..PATH_SEPARATOR.."env_presets"..PATH_SEPARATOR..preset_name..".xml"
    if type == ENVELOPE_UNDO then
      env_preset_file = preset_root..PATH_SEPARATOR.."undo"..PATH_SEPARATOR..preset_name..".xml"
    else
      get_preset_list(vb)  
    end    
    
    env_preset_table:property("FrequencyMode").value = '0'
    
    local ok,err = env_preset_table:load_from(env_preset_file)  

    preset_version = env_preset_table:property("PresetVersion").value    

    note_scheme_size = MINIMUM_FRAME_LENGTH
    vol_scheme_size = MINIMUM_FRAME_LENGTH
    pan_scheme_size = MINIMUM_FRAME_LENGTH
    ea_gui.views['auto_note_loop'].value = ARP_MODE_OFF
    ea_gui.views['auto_vol_loop'].value = ARP_MODE_OFF
    ea_gui.views['auto_pan_loop'].value = ARP_MODE_OFF
    note_loop_type = ENV_LOOP_OFF
    vol_loop_type = ENV_LOOP_OFF
    pan_loop_type = ENV_LOOP_OFF    
    envelope_volume_toggle = false
    envelope_panning_toggle = false    

    note_freq_val = 0
    vol_freq_val = 0
    pan_freq_val = 0
    
    note_freq_val = tonumber(env_preset_table:property("Frequency").value)
    env_pitch_scheme = env_preset_table:property("Scheme").value
    ea_gui.views['env_multiplier'].value = tonumber(env_preset_table:property("ToneFactor").value)
    if ea_gui.views['env_multiplier'].value ~= ENV_X100 then
      note_mode = false
      ea_gui.views['envelope_note_toggle'].text = "Tone"
    end
    tone_scope_offset = tonumber(env_preset_table:property("Transpose").value)
    if env_auto_apply == true then
      env_auto_apply = false
      ea_gui.views['tone_scope_slider'].value = tone_scope_offset
      ea_gui.views['transpose_pitch_scheme'].value = toboolean(env_preset_table:property("TransposeLink").value)
      env_auto_apply = true
    else
      ea_gui.views['tone_scope_slider'].value = tone_scope_offset
      ea_gui.views['transpose_pitch_scheme'].value = toboolean(env_preset_table:property("TransposeLink").value)
    end
    note_freq_type = tonumber(env_preset_table:property("FrequencyMode").value)
    note_point_scheme = env_preset_table:property("PointSequences").value
    local loop_assistance = tonumber(env_preset_table:property("LoopMode").value)
    

    ----------------------------------------
    --conversion from 3.00 to 3.10 or not?--
    ----------------------------------------
    
    if preset_version == "3.00" then
--      print('preset 300')
      env_pitch_scheme = env_pitch_scheme ..","..tostring(NOTE_SCHEME_TERMINATION)
      if loop_assistance == ARP_MODE_AUTO then
        auto_note_loop = loop_assistance
        vb.views['auto_note_loop'].value = loop_assistance
        note_loop_start = 0
        note_loop_type = ENV_LOOP_FORWARD
      end
    else
--      print('preset 310')


      note_freq_type = tonumber(env_preset_table:property("NoteFrequencyMode").value)
      note_freq_val = tonumber(env_preset_table:property("NoteFrequency").value)
      env_pitch_scheme = env_preset_table:property("NoteScheme").value
      note_point_scheme = env_preset_table:property("NotePointSequences").value
      note_scheme_size = tonumber(env_preset_table:property("NoteSchemeSize").value)
      env_pitch_type = tonumber(env_preset_table:property("NoteDrawType").value)
      auto_note_loop = tonumber(env_preset_table:property("NoteLoopMode").value)
      note_loop_type = tonumber(env_preset_table:property("NoteLoopType").value)
      note_sustain = tonumber(env_preset_table:property("NoteSustain").value)

      if tonumber(env_preset_table:property("LoopAssistance").value) == ARP_MODE_AUTO then
        note_loop_start = tonumber(env_preset_table:property("NoteLoopStart").value)
        note_loop_end = tonumber(env_preset_table:property("NoteLoopEnd").value)
        note_loop_type = ENV_LOOP_FORWARD
        change_from_tool = true
          vb.views['auto_note_loop'].value = ARP_MODE_AUTO
        change_from_tool = false
      end

      envelope_volume_toggle = toboolean(env_preset_table:property("VolumeApply").value)
      env_vol_scheme = env_preset_table:property("VolumeScheme").value
      volume_point_scheme = env_preset_table:property("VolumePointSequences").value
      vol_scheme_size = tonumber(env_preset_table:property("VolumeSchemeSize").value)
      vol_freq_type = tonumber(env_preset_table:property("VolumeFrequencyMode").value)
      vol_freq_val = tonumber(env_preset_table:property("VolumeFrequency").value)
      env_volume_type = tonumber(env_preset_table:property("VolumeDrawType").value)
      auto_vol_loop = tonumber(env_preset_table:property("VolumeLoopMode").value)
      vol_loop_type = tonumber(env_preset_table:property("VolumeLoopType").value)
      vol_loop_start =  tonumber(env_preset_table:property("VolumeLoopStart").value)
      vol_loop_end = tonumber(env_preset_table:property("VolumeLoopEnd").value)
      vol_release = -1
      vol_sustain = -1
      vol_release = tonumber(env_preset_table:property("VolumeRelease").value)
      vol_sustain = tonumber(env_preset_table:property("VolumeSustain").value)
      vol_pulse_mode = tonumber(env_preset_table:property("VolumePulseMode").value)
      vol_assist_high_val = tonumber(env_preset_table:property("VolumeHighValue").value)
      vol_assist_low_val = tonumber(env_preset_table:property("VolumeLowValue").value)
      vol_assist_high_size = tonumber(env_preset_table:property("VolumeHighSize").value)
  
      if tonumber(env_preset_table:property("VolumeLoopMode").value) == ARP_MODE_AUTO then
        vol_loop_start = 0
        vol_loop_end = vol_scheme_size
        vol_loop_type = ENV_LOOP_FORWARD
        change_from_tool = true
          vb.views['auto_vol_loop'].value = ARP_MODE_AUTO
        change_from_tool = false
      end

      envelope_panning_toggle = toboolean(env_preset_table:property("PanningApply").value)
      env_pan_scheme = env_preset_table:property("PanningScheme").value 
      panning_point_scheme = env_preset_table:property("PanningPointSequences").value 
      pan_scheme_size = tonumber(env_preset_table:property("PanningSchemeSize").value)
      env_panning_type = tonumber(env_preset_table:property("PanningDrawType").value)
      pan_freq_type = tonumber(env_preset_table:property("PanningFrequencyMode").value)
      pan_freq_val = tonumber(env_preset_table:property("PanningFrequency").value)
      auto_pan_loop = tonumber(env_preset_table:property("PanningLoopMode").value)
      pan_loop_type = tonumber(env_preset_table:property("PanningLoopType").value)
      pan_loop_start =  tonumber(env_preset_table:property("PanningLoopStart").value)
      pan_loop_end =  tonumber(env_preset_table:property("PanningLoopEnd").value)
      pan_sustain = -1
      pan_sustain = tonumber(env_preset_table:property("PanningSustain").value)
      pan_pulse_mode = tonumber(env_preset_table:property("PanningPulseMode").value)
      pan_assist_first_val = tonumber(env_preset_table:property("PanningFirstValue").value)
      pan_assist_next_val = tonumber(env_preset_table:property("PanningNextValue").value)
      pan_assist_first_size = tonumber(env_preset_table:property("PanningFirstSize").value)
      if tonumber(env_preset_table:property("PanningLoopMode").value) == ARP_MODE_AUTO then
        pan_loop_start = 0
        pan_loop_end = pan_scheme_size
        pan_loop_type = ENV_LOOP_FORWARD
        change_from_tool = true
          vb.views['auto_pan_loop'].value = ARP_MODE_AUTO
        change_from_tool = true
      end

      if note_freq_type == 0 then
        note_freq_type = FREQ_TYPE_FREEFORM
        note_freq_val = 0
      end
      if vol_freq_type == 0 then
        vol_freq_type = FREQ_TYPE_FREEFORM
        vol_freq_val = 0
      end
      if vol_freq_type == 0 then
        pan_freq_type = FREQ_TYPE_FREEFORM
        pan_freq_val = 0
      end
    end

    
    if preset_version == "3.00" then
      if loop_assistance == ARP_MODE_AUTO then
        note_loop_end = note_scheme_size

      else
        note_loop_end = -1
      end
      
      vol_sustain = -1
      vol_pulse_mode = ARP_MODE_OFF
      vol_loop_type = ENV_LOOP_OFF
      vol_loop_start = -1
      vol_loop_end = -1
      pan_sustain = -1
      pan_pulse_mode = ARP_MODE_OFF
      pan_loop_type = ENV_LOOP_OFF
      pan_loop_start = -1
      pan_loop_end = -1
    end
    
    if note_loop_end > note_scheme_size then
      note_scheme_size = note_loop_end
      env_note_value[note_loop_end] = NOTE_SCHEME_TERMINATION
    end
    if vol_loop_end > vol_scheme_size then
      vol_scheme_size = vol_loop_end
      env_vol_value[vol_loop_end] = VOL_PAN_TERMINATION
    end
    if pan_loop_end > pan_scheme_size then
      pan_scheme_size = pan_loop_end
      env_pan_value[pan_loop_end] = VOL_PAN_TERMINATION
    end    


    for column = ENV_NOTE_COLUMN, ENV_PAN_COLUMN do
      prepare_note_tables(column)
    end    
    
    init_tables(false)
    
    change_gui_properties()
    
    if preset_version == "3.15" then
      set_unattended_envelope_values()
      ea_gui.views['note_lfo_data'].color = bool_button[note_lfo_data]
      ea_gui.views['vol_lfo_data'].color = bool_button[vol_lfo_data]
      ea_gui.views['pan_lfo_data'].color = bool_button[pan_lfo_data]
      ea_gui.views['cut_lfo_data'].color = bool_button[cut_lfo_data]
      ea_gui.views['res_lfo_data'].color = bool_button[res_lfo_data]
      ea_gui.views['cutoff_data'].color = bool_button[cutoff_data]
      ea_gui.views['resonance_data'].color = bool_button[resonance_data]
    else
      ea_gui.views['note_lfo_data'].color = bool_button[false]
      ea_gui.views['vol_lfo_data'].color = bool_button[false]
      ea_gui.views['pan_lfo_data'].color = bool_button[false]
      ea_gui.views['cut_lfo_data'].color = bool_button[false]
      ea_gui.views['res_lfo_data'].color = bool_button[false]
      ea_gui.views['cutoff_data'].color = bool_button[false]
      ea_gui.views['resonance_data'].color = bool_button[false]
    end

    ea_gui.views['envelope_note_loop_toggle'].text = ENV_LOOP_TYPE[note_loop_type]
    ea_gui.views['envelope_volume_loop_toggle'].text = ENV_LOOP_TYPE[vol_loop_type]
    ea_gui.views['envelope_panning_loop_toggle'].text = ENV_LOOP_TYPE[pan_loop_type]

    set_cursor_location()

    
    if env_auto_apply then
      change_from_tool = true
        configure_envelope_loop()
      change_from_tool = false
      set_pitch_table()
      if preset_version == "3.15" then
        apply_unattended_properties()        
      end
    end
    toggle_pan_vol_color()
    toggle_sync_fields()

  end

end

---------------------------------------------------------------------------------------


function set_unattended_envelope_values()
--Values for the LFOs and the cutoff and resonance envelopes
--Only the tables and variables are prepared, nothing is ported to the envelopes yet!
    note_lfo_data = toboolean(env_preset_table:property("NoteLFOApply").value)
    note_lfo1_type = tonumber(env_preset_table:property("NoteLFO1").value)
    note_lfo1_phase = tonumber(env_preset_table:property("NoteLFOPhase1").value)
    note_lfo1_freq = tonumber(env_preset_table:property("NoteLFOFrequency1").value)
    note_lfo1_amount = tonumber(env_preset_table:property("NoteLFOAmount1").value)
    note_lfo2_type = tonumber(env_preset_table:property("NoteLFO2").value)
    note_lfo2_phase = tonumber(env_preset_table:property("NoteLFOPhase2").value)
    note_lfo2_freq = tonumber(env_preset_table:property("NoteLFOFrequency2").value)
    note_lfo2_amount = tonumber(env_preset_table:property("NoteLFOAmount2").value)
    

    vol_lfo_data = toboolean(env_preset_table:property("VolumeLFOApply").value)
    vol_lfo1_type = tonumber(env_preset_table:property("VolumeLFO1").value) 
    vol_lfo1_phase = tonumber(env_preset_table:property("VolumeLFOPhase1").value) 
    vol_lfo1_freq = tonumber(env_preset_table:property("VolumeLFOFrequency1").value) 
    vol_lfo1_amount = tonumber(env_preset_table:property("VolumeLFOAmount1").value) 
    vol_lfo2_type = tonumber(env_preset_table:property("VolumeLFO2").value) 
    vol_lfo2_phase = tonumber(env_preset_table:property("VolumeLFOPhase2").value) 
    vol_lfo2_freq = tonumber(env_preset_table:property("VolumeLFOFrequency2").value) 
    vol_lfo2_amount = tonumber(env_preset_table:property("VolumeLFOAmount2").value) 

    
    pan_lfo_data = toboolean(env_preset_table:property("PanningLFOApply").value) 
    pan_lfo1_type = tonumber(env_preset_table:property("PanningLFO1").value) 
    pan_lfo1_phase = tonumber(env_preset_table:property("PanningLFOPhase1").value) 
    pan_lfo1_freq = tonumber(env_preset_table:property("PanningLFOFrequency1").value) 
    pan_lfo1_amount = tonumber(env_preset_table:property("PanningLFOAmount1").value) 
    pan_lfo2_type = tonumber(env_preset_table:property("PanningLFO2").value) 
    pan_lfo2_phase = tonumber(env_preset_table:property("PanningLFOPhase2").value) 
    pan_lfo2_freq = tonumber(env_preset_table:property("PanningLFOFrequency2").value) 
    pan_lfo2_amount = tonumber(env_preset_table:property("PanningLFOAmount2").value)     
    
    
    cutoff_data = toboolean(env_preset_table:property("CutoffApply").value) 
    env_cut_scheme = env_preset_table:property("CutoffScheme").value
    cutoff_point_scheme = env_preset_table:property("CutoffPointSequences").value
    cut_scheme_size = tonumber(env_preset_table:property("CutoffSchemeSize").value) 
    env_cutoff_type = tonumber(env_preset_table:property("CutoffDrawType").value) 
    cutoff_enabled = toboolean(env_preset_table:property("CutoffEnabled").value) 
    cut_loop_type = tonumber(env_preset_table:property("CutoffLoopType").value) 
    cut_loop_start = tonumber(env_preset_table:property("CutoffLoopStart").value) 
    cut_loop_end = tonumber(env_preset_table:property("CutoffLoopEnd").value) 
    cut_sustain = tonumber(env_preset_table:property("CutoffSustain").value) 
    
    cut_lfo_data = toboolean(env_preset_table:property("CutoffLFOApply").value) 
    cut_lfo_type = tonumber(env_preset_table:property("CutoffLFO").value) 
    cut_lfo_phase = tonumber(env_preset_table:property("CutoffLFOPhase").value) 
    cut_lfo_freq = tonumber(env_preset_table:property("CutoffLFOFrequency").value) 
    cut_lfo_amount = tonumber(env_preset_table:property("CutoffLFOAmount").value) 
    cut_follow = toboolean(env_preset_table:property("CutoffFollower").value) 
    cut_follow_attack = tonumber(env_preset_table:property("CutoffFollowerAttack").value) 
    cut_follow_release = tonumber(env_preset_table:property("CutoffFollowerRelease").value) 
    cut_follow_amount = tonumber(env_preset_table:property("CutoffFollowerAmount").value) 


    resonance_data = toboolean(env_preset_table:property("ResonanceApply").value) 
    env_res_scheme = env_preset_table:property("ResonanceScheme").value
    resonance_point_scheme = env_preset_table:property("ResonancePointSequences").value
    res_scheme_size = tonumber(env_preset_table:property("ResonanceSchemeSize").value) 
    env_resonance_type = tonumber(env_preset_table:property("ResonanceDrawType").value) 
    resonance_enabled = toboolean(env_preset_table:property("ResonanceEnabled").value) 
    res_loop_type = tonumber(env_preset_table:property("ResonanceLoopType").value) 
    res_loop_start = tonumber(env_preset_table:property("ResonanceLoopStart").value) 
    res_loop_end = tonumber(env_preset_table:property("ResonanceLoopEnd").value) 
    res_sustain = tonumber(env_preset_table:property("ResonanceSustain").value) 

    res_lfo_data = toboolean(env_preset_table:property("ResonanceLFOApply").value) 
    res_lfo_type = tonumber(env_preset_table:property("ResonanceLFO").value) 
    res_lfo_phase = tonumber(env_preset_table:property("ResonanceLFOPhase").value) 
    res_lfo_freq = tonumber(env_preset_table:property("ResonanceLFOFrequency").value) 
    res_lfo_amount = tonumber(env_preset_table:property("ResonanceLFOAmount").value) 
    res_follow = toboolean(env_preset_table:property("ResonanceFollower").value) 
    res_follow_attack = tonumber(env_preset_table:property("ResonanceFollowerAttack").value) 
    res_follow_release = tonumber(env_preset_table:property("ResonanceFollowerRelease").value) 
    res_follow_amount = tonumber(env_preset_table:property("ResonanceFollowerAmount").value) 

    cutres_filter_type = tonumber(env_preset_table:property("CutResFilterType").value) 

    populate_cutres_tables(ENV_CUT)    
    populate_cutres_tables(ENV_RES)    
end


---------------------------------------------------------------------------------------

function prepare_note_tables(column)
--Convert the strings to tables to show in the tool-track
  local preset_version = env_preset_table:property("PresetVersion").value
  local freq_type = FREQ_TYPE_FREEFORM
  local freq_val = 0
  if column == ENV_NOTE_COLUMN then
--  print('initialising tables')
    init_tables(ENV_NOTE_COLUMN)    
    freq_type = note_freq_type
    freq_val = note_freq_val        
    
  elseif column == ENV_VOL_COLUMN then
    init_tables(ENV_VOL_COLUMN)    
    freq_type = vol_freq_type
    freq_val = vol_freq_val        
    
  elseif column == ENV_PAN_COLUMN then
    init_tables(ENV_PAN_COLUMN)  
    freq_type = pan_freq_type
    freq_val = pan_freq_val        
    
  end
  
  if freq_type == FREQ_TYPE_LINES then
--    print('lines',freq_val,freq_type)
    local rasters_per_line = sample_envelope_line_sync(false)
    local line_distance = freq_val

    if column == ENV_NOTE_COLUMN then
      local x_value_table = env_pitch_scheme:split( "[^,%s]+" )
      for t = 0, #x_value_table-1 do
        env_note_value[t*line_distance*rasters_per_line] = x_value_table[t+1]
        if t == #x_value_table-1 then
          note_scheme_size = t*line_distance*rasters_per_line
        end
      end
    elseif column == ENV_VOL_COLUMN and tonumber(preset_version) >= 3.10 then
      local x_value_table = env_vol_scheme:split( "[^,%s]+" )
      for t = 0, #x_value_table-1 do
        env_vol_value[t*line_distance*rasters_per_line] = x_value_table[t+1]
        if t == #x_value_table-1 then
          vol_scheme_size = t*line_distance*rasters_per_line
        end
      end
    elseif column == ENV_PAN_COLUMN and tonumber(preset_version) >= 3.10 then
      local x_value_table = env_pan_scheme:split( "[^,%s]+" )
      for t = 0, #x_value_table-1 do
        env_pan_value[t*line_distance*rasters_per_line] = x_value_table[t+1]
        if t == #x_value_table-1 then
          pan_scheme_size = t*line_distance*rasters_per_line
        end
      end
    end
  elseif freq_type == FREQ_TYPE_POINTS then
--    print('points')
    local line_distance = freq_val
    local note_value_table = env_pitch_scheme:split( "[^,%s]+" )
    note_point_scheme = "0"
    for t = 0, #note_value_table-1 do
      env_note_value[t*line_distance] = note_value_table[t+1]
      if t > 0 then
        note_point_scheme = note_point_scheme .. ","..tostring(t*line_distance)
      end
      if t == #note_value_table-1 then
        note_scheme_size = (t)*line_distance
      end
    end
    note_freq_val = 0
  elseif freq_type == FREQ_TYPE_FREEFORM then
--    print('freeform')
    local y_value_table = {}
    local x_value_table = {}
    local end_node = #y_value_table
    local leading_table = 1 --Notes
    local sub_position = 1

    if column == ENV_NOTE_COLUMN then
      y_value_table = env_pitch_scheme:split( "[^,%s]+" )
      x_value_table = note_point_scheme:split( "[^,%s]+" )
      note_freq_val = 0
    elseif column == ENV_VOL_COLUMN and tonumber(preset_version) >= 3.10 then
      y_value_table = env_vol_scheme:split( "[^,%s]+" )
      x_value_table = volume_point_scheme:split( "[^,%s]+" )
      vol_freq_val = 0
    elseif column == ENV_PAN_COLUMN and tonumber(preset_version) >= 3.10 then
      y_value_table = env_pan_scheme:split( "[^,%s]+" )
      x_value_table = panning_point_scheme:split( "[^,%s]+" )
      pan_freq_val = 0
    end
          
    end_node = #y_value_table
          
    if #y_value_table < #x_value_table then
      end_node = #x_value_table
      leading_table = 2
    end
          
    if #y_value_table == #x_value_table then
      leading_table = -1
    end
          
    if leading_table == 1 then
      sub_position = 2
            
      for t = #x_value_table+1, end_node do
        local new_val = tonumber(x_value_table[sub_position]) -
                        tonumber(x_value_table[sub_position -1])
        x_value_table[t] = tonumber(x_value_table[t-1])+new_val
        sub_position = sub_position + 1
      end
    else
      for t = #y_value_table+1, end_node do
        y_value_table[t] = y_value_table[sub_position]
        sub_position = sub_position + 1
        if sub_position > #y_value_table then
          sub_position = 1
        end
      end
    end
    
    for t = 1, end_node do
      
      if y_value_table[t] ~= nil and x_value_table[t] ~= nil then
        if column == ENV_NOTE_COLUMN then

          env_note_value[tonumber(x_value_table[t])] = y_value_table[t]
          
          if t == end_node then
            note_scheme_size = tonumber(x_value_table[t])
          end
        elseif column == ENV_VOL_COLUMN and tonumber(preset_version) >= 3.10 then
          env_vol_value[tonumber(x_value_table[t])] = y_value_table[t]
          if t == end_node then
            vol_scheme_size = tonumber(x_value_table[t])
          end
        elseif column == ENV_PAN_COLUMN and tonumber(preset_version) >= 3.10 then
          env_pan_value[tonumber(x_value_table[t])] = y_value_table[t]
          if t == end_node then
            pan_scheme_size = tonumber(x_value_table[t])
          end
        end
      end
    end

    for t = 0, note_scheme_size-1 do
      if env_note_value[t] == NOTE_SCHEME_TERMINATION then
        env_note_value[t] = EMPTY_CELL
      end
    end
    for t = 0, vol_scheme_size-1 do
      if  env_vol_value[t] == VOL_PAN_TERMINATION then
        env_vol_value[t] = EMPTY_CELL
      end
    end
    for t = 0, pan_scheme_size-1 do
      if  env_vol_value[t] == VOL_PAN_TERMINATION then
        env_vol_value[t] = EMPTY_CELL
      end
    end
  end  
  
  if note_loop_type ~= ENV_LOOP_OFF or auto_note_loop == ARP_MODE_AUTO then
    note_loop_start = 0
    note_loop_end = note_scheme_size
  else
    note_loop_start = -1
    note_loop_end = -1
  end
  if tonumber(env_preset_table:property("PresetVersion").value) >= 3.10 then
    if vol_loop_type ~= ENV_LOOP_OFF or auto_vol_loop == ARP_MODE_AUTO then
      vol_loop_start = 0
      vol_loop_end = vol_scheme_size
    else
      vol_loop_start = -1
      vol_loop_end = -1
    end
    if pan_loop_type ~= ENV_LOOP_OFF or auto_pan_loop == ARP_MODE_AUTO then
      pan_loop_start = 0
      pan_loop_end = pan_scheme_size
    else
      pan_loop_start = -1
      pan_loop_end = -1
    end
  else
    vol_loop_type = ENV_LOOP_OFF
    vol_sustain = -1
    vol_loop_start = -1
    vol_loop_end = -1
    pan_loop_type = ENV_LOOP_OFF
    pan_sustain = -1
    pan_loop_start = -1
    pan_loop_end = -1
  end

end


---------------------------------------------------------------------------------------

function show_folder(type)
  local preset_root = get_tools_root().."com.renoise.EpicArpeggiator.xrnx"
  local preset_folder = preset_root..PATH_SEPARATOR.."presets"
  if type == ENVELOPE then
    preset_folder = preset_root..PATH_SEPARATOR.."env_presets"
  end
  check_preset_folder(preset_root)
  renoise.app():open_path(preset_folder)
end


---------------------------------------------------------------------------------------

function check_preset_folder(preset_root)
  local root_folders = os.dirnames(preset_root)
  local preset_folder_present = false
  local env_preset_folder_present = false
  local undo_folder_present = false
  
  for _ = 1, #root_folders do
    if root_folders[_] == "presets" then
      preset_folder_present = true
    end 
    if root_folders[_] == "env_presets" then
      env_preset_folder_present = true
    end
    if root_folders[_] == "undo" then
      undo_folder_present = true
    end
  end

  if preset_folder_present == false then
    os.mkdir(preset_root..PATH_SEPARATOR.."presets")
  end
  if env_preset_folder_present == false then
    os.mkdir(preset_root..PATH_SEPARATOR.."env_presets")
  end
  if undo_folder_present == false then
    os.mkdir(preset_root..PATH_SEPARATOR.."undo")
  end

end


---------------------------------------------------------------------------------------

function show_help()
  local documentation_root = get_tools_root().."com.renoise.EpicArpeggiator.xrnx"
--  local documentation_url = documentation_root..PATH_SEPARATOR.."documentation"..PATH_SEPARATOR.."index.html"
  local documentation_url = 'file://'..documentation_root..PATH_SEPARATOR.."documentation"..PATH_SEPARATOR.."Epic Arpeggiator V3.0.pdf#"
  --documentation_url = documentation_url
  local page = 'page=1'
  if tab_states.top == 1 then
    page = 'page=7'
  end
  if tab_states.top == 2 then
    page = 'page=13'
  end
  
  if tab_states.top == 3 then
    page = 'page=4'
  end
  renoise.app():open_url(string.format("%s%s",documentation_url,page))
end


