--[[============================================================================
Increment.lua
============================================================================]]--

return {
arguments = {
},
data = {
},
callback = [[
-------------------------------------------------------------------------------
-- Increment
-------------------------------------------------------------------------------

-- The global incrementor, 'INCR', is an ever-increasing line counter.
-- The longer you keep streaming, the higher this value will get. Not to 
-- be confused with the pattern line-number, a callback has no such thing.
-- Note: the counter is reset when you invoke xStream.start()

line.note_columns[1] = {
  volume_value = INCR -- will output until max. volume (0x80) is reached
}






]],
}