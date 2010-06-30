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

--PAY ATTENTION! This script currently does NOT take in count automation!

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
  
  local num_tracks = table.getn(new_pattern.tracks);

  -- dealing with automation.
  -- first of all, let's create an intermediate point between the last point of previous
  -- pattern and the first of the new pattern, if it doesn't exists yet
  for num_track = 1, num_tracks do
  
	for num_auto = 1, table.getn(new_pattern.tracks[num_track].automation) do

		local points = new_pattern.tracks[num_track].automation[num_auto].points;
		for point = 1, table.getn(points) do
			
			if points[point].time >= current_line then
				points[point].time = points[point].time - current_line + 1
			else
				renoise.app():show_error(tostring(points[point].time,points[point].value))
				points:remove_point_at(0)
				renoise.app():show_error(tostring(points[point].time))
				point = point - 1 --fix index after removal				
			end
			
		end
	
	end
	
  end
  
  --iterate through tracks of the new pattern to shift lines up
  for num_track = 1, num_tracks do

    for i = current_line+1,new_pattern.number_of_lines do
      new_pattern.tracks[num_track].lines[i-current_line]:copy_from(new_pattern.tracks[num_track].lines[i]);      
    end
  
  end

  -- cut the new pattern
  new_pattern.number_of_lines = new_pattern.number_of_lines - current_line;
  
 
end
