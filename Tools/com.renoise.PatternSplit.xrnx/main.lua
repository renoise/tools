--[[============================================================================
main.lua
============================================================================]]--

-- tool registration

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Pattern:Split",
  invoke = function() 
     split()
  end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Pattern Operations:Split",
  invoke = function(repeated) 
    if not repeated then
      split()
    end 
  end
}


--------------------------------------------------------------------------------
-- processing
--------------------------------------------------------------------------------

function split()

  --get the song that currently is active
  local song = renoise.song()
  
  --get the ordinal number of the current line (where to split)
  local current_line = song.transport.edit_pos.line

  --get the current pattern    
  local current_pattern = song.selected_pattern
  
  
  if current_line == current_pattern.number_of_lines then
    renoise.app():show_status(
      'Warning: cannot split at the bottom of the pattern, operation aborted.')
    return
  end

  --clone current pattern
  local selected_sequence_index = 
    song.selected_sequence_index
  
  local new_pattern_index = song.sequencer:clone_range(
    selected_sequence_index, selected_sequence_index)
    
  --get the new pattern  
  local new_pattern = song:pattern(
    song.sequencer:pattern(selected_sequence_index + 1))
      
  --cut the current pattern at that line
  current_pattern.number_of_lines = current_line 
  
  local num_tracks = #new_pattern.tracks

  -- dealing with automation.
  -- first of all, let's create an intermediate point between the last point of
  -- previous pattern and the first of the new pattern, if it doesn't exists yet
  for num_track = 1, num_tracks do
  
    local current_track = current_pattern.tracks[num_track]
    local new_track = new_pattern:track(num_track)
    
    for num_auto = 1, #new_track.automation do

      local current_automation = current_track.automation[num_auto]
      local new_automation = new_track.automation[num_auto]
      local points = new_automation.points
    
      -- let's see if the line on which we are cutting already has a point
      -- in the curve; in such case, we are lucky and don't need to compute
      -- the intermediate point..
      if not 
        new_automation:has_point_at(current_line) 
      then
        -- let's see if the current automation curve has any point before the
        -- current_line and any point after current_line.
        local previous_point = 1
        local next_point = #points

        for point = 1, #points do
        
          if 
            points[point].time < current_line and 
            previous_point < points[point].time 
          then
            -- get the highest line which is less than current_line
            previous_point = point
          end 
      
          if 
            points[point].time > current_line and 
            next_point > points[point].time 
          then
            -- get the lowest line which is greater than current_line
            next_point = point        
          end
    
        end
      
        -- now create the transition point
        local transition_time = current_line
        local transition_value

        if previous_point == next_point then
          transition_value = points[previous_point].value
        else
          transition_value = points[previous_point].value + 
            (points[next_point].value - points[previous_point].value) *
              (current_line - points[previous_point].time) /  
                (points[next_point].time - points[previous_point].time)
        end
        
        new_automation:add_point_at(current_line+1,transition_value)
        current_automation:add_point_at(current_line,transition_value)

      else

        for point = 1, #points do
        
          if points[point].time == current_line then
            new_automation:add_point_at(current_line+1,points[point].value)
            point = #points -- break
          end
          
        end

      end

      -- delete any point which is before the current_line
      for point = 1, #points do
      
        if points[point].time < current_line + 1 then
          new_automation:remove_point_at(points[point].time)
          point = point - 1
        end
    
      end
    
      -- refresh copy after deletion  
      points = new_automation.points
    
      -- shift back all the points after the current_line
      for point = 1, #points do

        local auto_time = points[point].time - current_line
        local auto_value = points[point].value

        new_automation:remove_point_at(points[point].time)      
        new_automation:add_point_at(auto_time,auto_value)
        
      end
  
    end
  
  end
  
  --iterate through tracks of the new pattern to shift lines up
  for num_track = 1, num_tracks do
  
    local new_track = new_pattern:track(num_track)

    for i = current_line+1,new_pattern.number_of_lines do
      new_track:line(i - current_line):copy_from(new_track:line(i))
    end 
  
  end

  -- cut the new pattern
  new_pattern.number_of_lines = 
    new_pattern.number_of_lines - current_line
 
end

