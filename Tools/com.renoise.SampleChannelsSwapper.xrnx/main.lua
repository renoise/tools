--[[============================================================================
main.lua
============================================================================]]--

renoise.tool():add_menu_entry {
  name = "Sample Editor:Process:Swap stereo channels",
  invoke = function() 
    main() 
  end
}

renoise.tool():add_keybinding {
  name = "Sample Editor:Process:Swap stereo channels",
  invoke = function()
    main()
  end
}


--------------------------------------------------------------------------------

function main()

  local sample_buffer = renoise.song().selected_sample.sample_buffer
  
  if (sample_buffer == nil or not sample_buffer.has_sample_data) then
  
    renoise.app():show_error('No sample found!')
    return
  
  end  
  
  local int_sample = renoise.song().selected_sample_index
  
  if (sample_buffer.number_of_channels < 2) then
  
    renoise.app():show_error('The sample must be stereo!')
    return  

  end
  
  sample_buffer:prepare_sample_data_changes()

  for frame = sample_buffer.selection_start, sample_buffer.selection_end do
    local temp = sample_buffer:sample_data(1, frame)
    sample_buffer:set_sample_data(1, frame, sample_buffer:sample_data(2, frame))
    sample_buffer:set_sample_data(2, frame, temp)
  end 
  
  sample_buffer:finalize_sample_data_changes()

  renoise.app():show_status('Channels swapping succesfully completed!')

end
