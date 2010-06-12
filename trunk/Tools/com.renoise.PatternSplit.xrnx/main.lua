-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- tool registration
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Pattern:Split...",
  invoke = function() 
     split()
  end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Pattern:Split",
  invoke = function() split() end
}



-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- main content
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=



-------------------------------------------------------------------------------

function split()

  local selected_line = renoise.song().selected_line;
  
  --clone current pattern
  local new_pattern_index =    
    renoise.song().sequencer:clone_range(
      renoise.song().selected_sequence_index,
      renoise.song().selected_sequence_index);
    
  --get the new pattern  
  local new_pattern = renoise.song().patterns[
    renoise.song().sequencer.pattern_sequence[
      renoise.song().selected_sequence_index+1]];
      
  --get the current pattern    
  local current_pattern = renoise.song().selected_pattern;
  
  --get the ordinal number of the current line (where to split)
  local current_line = renoise.song().transport.edit_pos.line;
  
  --cut the current pattern at that line
  current_pattern.number_of_lines = current_line; 
  
  --iterate through tracks of the new pattern to shift lines up
  local num_tracks = table.getn(new_pattern.tracks);
  
  for t = 1, num_tracks do

    for i = current_line+1,new_pattern.number_of_lines do
      new_pattern.tracks[t].lines[i-current_line]:copy_from(new_pattern.tracks[t].lines[i]);      
    end
  
  end

  -- cut the new pattern
  new_pattern.number_of_lines = new_pattern.number_of_lines - current_line;
  
end
