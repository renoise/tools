--[[----------------Helper functions-----------------------------]]
function randomize(tstart, tend)
   local number = tostring(os.clock())
   if string.find(number,"%.") ~= nil then
      number = string.sub(number, string.find(number,"%.")+1)
   end
   math.randomseed( tonumber(number))
   number  = number + math.random(1, 7)
   math.randomseed( tonumber(number))
   math.random(tstart, tend); math.random(tstart, tend); math.random(tstart, tend)
   local result = math.random(tstart, tend)
   return result
end
string.split = function(str, pattern)
  pattern = pattern or "[^%s]+"
  if pattern:len() == 0 then pattern = "[^%s]+" end
  local parts = {__index = table.insert}
  setmetatable(parts, parts)
  str:gsub(pattern, parts)
  setmetatable(parts, nil)
  parts.__index = nil
  return parts
end
function ferris_wheel(source_table, target_table, direction, repeat_mode)
--[[
   Copies one table into another depending on the desired order.
   This routine is specifically designed when one does *not* want to 
   sort out the original table, it is only to create a temporary table
   using the contents of the other in different order or even in 
   mirrored waves.
   I made changes in the top/down/top and down/top/down schemes not to regenerate
   the previous note if it would be the same. 
--]]
      local tend = #source_table
      if repeat_mode == true then
         repeat_mode = 0
      elseif repeat_mode == false then
         repeat_mode = 1
      end
      if direction == 1 or direction == 5 then --Top-Down / random
         target_table = source_table
      elseif direction == 2 then --Down-Top
         local subt = #source_table
         for t=1, #source_table do
           target_table[t] = source_table[subt]
           subt = subt - 1 
         end
      elseif direction == 3 then --Top-Down-Top
         for t=1, #source_table do
           target_table[t] = source_table[t]
         end
         local subt = #source_table 
         local offc = repeat_mode
         if repeat_mode == 0 then
            target_table[#target_table+1] = source_table[#source_table]
            tend = tend+1
         else
            offc = 2
         end
         for t=(tend), (tend*2-offc) do
           target_table[t] = source_table[subt]
           subt = subt - 1 
         end
      elseif direction == 4 then --Down-Top-Down
         local subt = #source_table 
         local tend = #source_table
         local offs = 2
         for t=1, #source_table do
           target_table[t] = source_table[subt]
           subt = subt - 1
         end
         if repeat_mode == 0 then
            target_table[#target_table+1] = source_table[subt]
            tend = tend+1
            offs = 1
         else
            tend = #source_table - 1
         end
         for t=offs, tend do
            target_table[#target_table+1] = source_table[t]
         end
      end
   return target_table
end