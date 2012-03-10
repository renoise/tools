
--[[============================================================================
preset_manager.lua
============================================================================]]--

-- Read from the manifest.xml file.
class "PresetTable" (renoise.Document.DocumentNode)
  function PresetTable:__init()    
    renoise.Document.DocumentNode.__init(self) 
    self:add_property("PresetVersion", "2.00")
    for x = 1,#preset_table do
      self:add_property(preset_table[x], "00")
    end
  end

local preset_table = PresetTable()

function get_preset_list(vb)
  local preset_root = get_tools_root().."com.renoise.EpicArpeggiator.xrnx"
  local preset_folder = preset_root..PATH_SEPARATOR.."presets"..PATH_SEPARATOR
  check_preset_folder(preset_root)
  
  local preset_files = os.filenames(preset_folder)
  
  for _ = 1, #preset_files do
    preset_files[_] = string.gsub(preset_files[_],".xml","")
  end
  vb.views.popup_preset.items = preset_files
end

function save_preset(preset_name,vb)

  preset_table:property("Scheme").value = tostring(vb.views.switch_note_pattern.value)

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
  preset_table:property("NoteMatrix").value = tm_serialized
  preset_table:property("NoteProfile").value = tostring(vb.views.custom_note_profile.value)
  preset_table:property("Distance").value = tostring(vb.views.vbox_distance_step.value)
  preset_table:property("DistanceMode").value = tostring(vb.views.popup_distance_mode.value)
  preset_table:property("OctaveRotation").value = tostring(vb.views.popup_octave_order.value)
  preset_table:property("OctaveRepeat").value = tostring(vb.views.octave_repeat_mode.value)
  preset_table:property("Termination").value = tostring(vb.views.vbox_termination_step.value)
  preset_table:property("TerminationMode").value = tostring(vb.views.popup_note_termination_mode.value)
  preset_table:property("NoteRotation").value = tostring(vb.views.popup_note_order.value)
  preset_table:property("NoteRepeat").value = tostring(vb.views.repeat_note.value)

  preset_table:property("ArpeggioPattern").value = tostring(vb.views.switch_arp_pattern.value)
  preset_table:property("CustomPattern").value = tostring(vb.views.custom_arpeggiator_profile.value)

  preset_table:property("NoteColumns").value = tostring(vb.views.max_note_colums.value)
  preset_table:property("ChordMode").value = tostring(vb.views.chord_mode_box.value)

  preset_table:property("InstrumentPool").value = tostring(vb.views.popup_procins.value)
  preset_table:property("InstrumentRotation").value = tostring(vb.views.popup_ins_insertion.value)
  preset_table:property("InstrumentRepeat").value = tostring(vb.views.repeat_instrument.value)

  preset_table:property("VolumePool").value = tostring(vb.views.popup_procvel.value)
  preset_table:property("VolumeRotation").value = tostring(vb.views.popup_vel_insertion.value)
  preset_table:property("VolumeRepeat").value = tostring(vb.views.repeat_velocity.value)

  
  local preset_root = get_tools_root().."com.renoise.EpicArpeggiator.xrnx"
  preset_file = preset_root..PATH_SEPARATOR.."presets"..PATH_SEPARATOR..preset_name..".xml"
  check_preset_folder(preset_root)
  if io.exists(preset_file) then
    local status = file_exists_dialog(preset_name)
    if status == false then
      return
    end
  end
  local ok,err = preset_table:save_as(preset_file)

  get_preset_list(vb)  
end

function load_preset(preset_name,vb)

  local preset_root = get_tools_root().."com.renoise.EpicArpeggiator.xrnx"
  preset_file = preset_root..PATH_SEPARATOR.."presets"..PATH_SEPARATOR..preset_name..".xml"

  get_preset_list(vb)  

  local ok,err = preset_table:load_from(preset_file)

  if ok == false then
    return
  end

  vb.views.switch_note_pattern.value = tonumber(preset_table:property("Scheme").value)

  local tm_serialized = preset_table:property("NoteMatrix").value
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

  vb.views.custom_note_profile.value = preset_table:property("NoteProfile").value
  vb.views.vbox_distance_step.value = tonumber(preset_table:property("Distance").value)
  vb.views.popup_distance_mode.value = tonumber(preset_table:property("DistanceMode").value)
  vb.views.popup_octave_order.value = tonumber(preset_table:property("OctaveRotation").value)
  vb.views.octave_repeat_mode.value = toboolean(preset_table:property("OctaveRepeat").value)
  
  vb.views.vbox_termination_step.value = tonumber(preset_table:property("Termination").value)
  vb.views.popup_note_termination_mode.value = tonumber(preset_table:property("TerminationMode").value)
  vb.views.popup_note_order.value = tonumber(preset_table:property("NoteRotation").value)
  vb.views.repeat_note.value = toboolean(preset_table:property("NoteRepeat").value)

  vb.views.switch_arp_pattern.value = tonumber(preset_table:property("ArpeggioPattern").value)
  vb.views.custom_arpeggiator_profile.value = preset_table:property("CustomPattern").value

  vb.views.max_note_colums.value = tonumber(preset_table:property("NoteColumns").value)
  vb.views.chord_mode_box.value = toboolean(preset_table:property("ChordMode").value)

  vb.views.popup_procins.value = preset_table:property("InstrumentPool").value
  vb.views.popup_ins_insertion.value = tonumber(preset_table:property("InstrumentRotation").value)
  vb.views.repeat_instrument.value = toboolean(preset_table:property("InstrumentRepeat").value)

  vb.views.popup_procvel.value = preset_table:property("VolumePool").value
  vb.views.popup_vel_insertion.value = tonumber(preset_table:property("VolumeRotation").value)
  vb.views.repeat_velocity.value = toboolean(preset_table:property("VolumeRepeat").value)


end

function show_folder()
  local preset_root = get_tools_root().."com.renoise.EpicArpeggiator.xrnx"
  local preset_folder = preset_root..PATH_SEPARATOR.."presets"
  check_preset_folder(preset_root)
  renoise.app():open_path(preset_folder)
end

function check_preset_folder(preset_root)
  local root_folders = os.dirnames(preset_root)
  local preset_folder_present = false
  
  for _ = 1, #root_folders do
    if root_folders[_] == "presets" then
      preset_folder_present = true
      break
    end 
  end

  if preset_folder_present == false then
    os.mkdir(preset_root..PATH_SEPARATOR.."presets")
  end

end

function show_help()
  local documentation_root = get_tools_root().."com.renoise.EpicArpeggiator.xrnx"
  local documentation_url = documentation_root..PATH_SEPARATOR.."documentation"..PATH_SEPARATOR.."index.html"

  renoise.app():open_url(documentation_url)

end

