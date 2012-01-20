--[[============================================================================
main.lua
============================================================================]]--

for num_track = 1, 256 do

  -- tool registration
  
  local key_binding_name = string.format(
    "Pattern Editor:Track:Select Track #%.3d", num_track)
  
  renoise.tool():add_keybinding {
    name = key_binding_name,
    invoke = function() 
      set_selected_track(num_track) 
    end
  }
  
  local midi_mapping_name = string.format(
    "Navigation:Tracks:Select Track #%.3d", num_track)
  
  renoise.tool():add_midi_mapping {
    name = midi_mapping_name,
    invoke = function(message) 
      if message:is_trigger() then
        set_selected_track(num_track) 
      end
    end
  }
  
end


--------------------------------------------------------------------------------
-- processing
--------------------------------------------------------------------------------

function set_selected_track(num_track)

  local track = renoise.song().tracks[num_track]

  if (track ~= nil) then
    renoise.song().selected_track_index = num_track
    
    renoise.app():show_status("Track #" .. num_track ..
      " (\""..track.name.."\") selected.")
  else
    renoise.app():show_status("Track #" .. num_track .. 
      " does not exist in this song.")
  end
 
end

