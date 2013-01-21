--[[============================================================================
undo_management.lua, whatever can be undone, will be undone...
============================================================================]]--

function save_undo_state(description)
  if no_undo == true or enable_undo == false then
    return
  end

  local t = os.date('*t')
  local time_stamp = tostring(os.time()) 
  description = os.date('%y/%m/%d %H:%M:%S -> ')..description
  last_undo_preset = #undo_preset_table
  
  while undo_preset_table[#undo_preset_table] == time_stamp do
    time_stamp = tostring(os.time())
  end
  
  undo_preset_table[#undo_preset_table+1] = time_stamp
  undo_descriptions[#undo_descriptions+1] = description
  get_current_data()
  save_preset(undo_preset_table[#undo_preset_table],ENVELOPE_UNDO,undo_gui)
  if undo_gui ~= nil then
    if undo_gui.views['popup_undo'] ~= nil then
      undo_gui.views['popup_undo'].items = undo_descriptions
      undo_gui.views['popup_undo'].value = #undo_descriptions
    end
  end
end

--------------------------------------------------------------------------------

function load_undo_state(preset)
  no_undo = true
    local preset_file = undo_preset_table[preset]
    load_preset(preset_file,ENVELOPE_UNDO,undo_gui)
  no_undo = false
end

--------------------------------------------------------------------------------

function clear_undo_folder()
  local preset_root = get_tools_root().."com.renoise.EpicArpeggiator.xrnx"
  local undo_folder =  preset_root..PATH_SEPARATOR.."undo"..PATH_SEPARATOR
  local files = os.filenames(undo_folder)
  undo_preset_table = {}
  undo_descriptions = {}
  last_undo_preset = nil
  if undo_dialog then
    undo_dialog:close()
    undo_dialog = nil
  end
  
  no_undo = false  
  for _ = 1, #files do
    os.remove(undo_folder..files[_])
  end
end

--------------------------------------------------------------------------------
--      End of teh road...
--------------------------------------------------------------------------------

