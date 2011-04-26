--[[============================================================================
main.lua
============================================================================]]--

for num_track = 1, 256 do

  -- tool registration
  
  local binding_name = "Pattern Editor:Track:Select Track #" .. num_track
  
  if not renoise.tool():has_keybinding(binding_name) then
    renoise.tool():add_keybinding {
      name = binding_name,
      invoke = function() set_selected_track(num_track) end
    }
  end

    if not renoise.tool():has_midi_mapping(binding_name) then
    renoise.tool():add_midi_mapping {
      name = binding_name,
      invoke = function(message) 
	    if message:is_switch() then
	      set_selected_track(num_track) 
		end
	  end
    }
  end

end

--------------------------------------------------------------------------------
-- processing
--------------------------------------------------------------------------------

function set_selected_track(num_track)

  local track = renoise.song().tracks[num_track]

  if (track ~= nil) then
    renoise.song().selected_track_index = num_track;
	renoise.app():show_status("Track #"..num_track.." (\""..track.name.."\") selected.")
  else
    renoise.app():show_status("Track #"..num_track.." does not exist in this song.")
  end
 
end

