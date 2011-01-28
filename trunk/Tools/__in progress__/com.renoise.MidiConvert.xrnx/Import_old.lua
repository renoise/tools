--[[
I tried to make an OO class, but yield would throw:
$ Error: attempt to yield across metamethod/C-call boundary

I also tried to make a Lua module, but I got:
$ Error: attempt to get length of upvalue [...]

Dinked around for hours, gave up.
Thusly, this file is procedural. Each function is to be prepended with `import_`
Good times
]]--


--[[
TODO:

local example = Midi()
example:importMid("/path/to/test.midi")
print(example:getTxt())
-- Or:
-- rprint(example.tracks)
]]--