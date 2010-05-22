function check_unique_pattern()
--[[Checks if the song sequence has patterns that are repeated--]]
   local song = renoise.song()
   local double = {}
   local doubles = 1
   local add_one = 0
   local hyve = 2
   double[1] = song.sequencer.pattern_sequence[1]
   local i = 2
   local sp_bound = #song.sequencer.pattern_sequence
   local return_val = 0

   while i <= sp_bound do
      for j = 1, #double do
         if song.sequencer.pattern_sequence[i] == double[j] then
            doubles = doubles + 1
            add_one = 0
            break
         else
            add_one = 1
         end
      end
      if add_one == 1 then
         double[hyve] = song.sequencer.pattern_sequence[i]
         add_one = 0
         hyve = hyve +1
      end
      i = i + 1
   end
   if doubles > 1 then
      return_val = cross_write_dialog(-1, double, doubles) 
   end      
   return return_val
end
function make_unique_pattern()
--[[Copies all repeated patterns to a unique pattern--]]
   local song = renoise.song()
   song.sequencer:make_range_unique(1, #song.sequencer.pattern_sequence)
   return
end