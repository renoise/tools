--[[--------------------------------------------------------------------------
TestTransport.lua
--------------------------------------------------------------------------]]--

-- tools

local function assert_error(statement)
  assert(pcall(statement) == false, "expected function error")
end


-- shortcuts

local transport = renoise.song().transport


------------------------------------------------------------------------------
-- SongPos

local some_str = tostring(transport.edit_pos)
transport.edit_pos = renoise.SongPos(1, 1)
local new_pos = transport.edit_pos

assert_error(function()
  new_pos.does_not_exist = "Foo!"
end)

--[[ TODO:
assert_error(function()
  new_pos.sequence = 2
end)
assert_error(function()
  new_pos.line = 1
end)
--]]

transport.loop_range = {renoise.SongPos(1, 1), renoise.SongPos(1, 17)}

assert(transport.loop_start == transport.loop_range[1])
assert(transport.loop_end == transport.loop_range[2])

assert(transport.loop_start < transport.loop_end)
assert(transport.loop_end > transport.loop_start)

assert(transport.loop_start == renoise.SongPos(1, 1))
assert(transport.loop_start ~= renoise.SongPos(2, 1))


------------------------------------------------------------------------------
-- test finalizers

collectgarbage()


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--

