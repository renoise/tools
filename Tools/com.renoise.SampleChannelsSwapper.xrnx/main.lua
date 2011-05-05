--[[============================================================================
main.lua
============================================================================]]--

renoise.tool():add_menu_entry {
  name = "Sample Editor:Process:Swap stereo channels...",
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

function main()

  local sample_buffer = renoise.song().selected_sample.sample_buffer
  
  if (sample_buffer == nil or not sample_buffer.has_sample_data) then
  
    renoise.app():show_error('No sample found!')
    return
  
  end  
  
  if (sample_buffer.number_of_channels < 2) then
  
    renoise.app():show_error('The sample must be stereo!')
    return  

  end
  
  local instrument_selected = renoise.song().selected_instrument
  local sample_selected = renoise.song().selected_sample
  local int_sample_selected = renoise.song().selected_sample_index
  local int_chans = sample_buffer.number_of_channels
  local int_rate = sample_buffer.sample_rate
  local int_depth = sample_buffer.bit_depth
  local int_frames = sample_buffer.number_of_frames

  local sample_new = instrument_selected:insert_sample_at(int_sample_selected+1)
  local buffer_new = sample_new.sample_buffer

  if not buffer_new:create_sample_data(int_rate, int_depth, int_chans, int_frames) then
    renoise.app():show_error('Error during sample creation!')
    return
  end
  
  buffer_new:prepare_sample_data_changes()
 
  local sample_number = 0  

  for sample_number = 1, sample_buffer.selection_start - 1 do
      
    buffer_new:set_sample_data(1, sample_number, sample_buffer:sample_data(1, sample_number))
    buffer_new:set_sample_data(2, sample_number, sample_buffer:sample_data(2, sample_number))
    
  end 

  for sample_number = sample_buffer.selection_start, sample_buffer.selection_end do
      
    buffer_new:set_sample_data(1, sample_number, sample_buffer:sample_data(2, sample_number))
    buffer_new:set_sample_data(2, sample_number, sample_buffer:sample_data(1, sample_number))
    
  end


  for sample_number = sample_buffer.selection_end + 1, sample_buffer.number_of_frames do
      
    buffer_new:set_sample_data(1, sample_number, sample_buffer:sample_data(1, sample_number))
    buffer_new:set_sample_data(2, sample_number, sample_buffer:sample_data(2, sample_number))
    
  end  
  
  buffer_new:finalize_sample_data_changes()

  instrument_selected:delete_sample_at(int_sample_selected)
  
  renoise.app():show_status('Channels swapping succesfully completed!')

end
