--[[
local foo = {1,2,3}
local bar = {
  one = 1,
  two = 2,
  three = 3
}
local baz = {
  one = 1,
  two = 2,
  three = 3,
  4,
}

function table_count(t)
  local n=0
  if ("table" == type(t)) then
    for key in pairs(t) do
      n = n + 1
    end
    return n
  else
    return nil
  end
end

print("foo",table_count(foo))
print("bar",table_count(bar))
rprint(bar)

local function isArray(t)
  local i = 0
  for _ in pairs(t) do
    i = i + 1
    if t[i] == nil then return false end
  end
  return true
end

print("isArray foo",isArray(foo))
print("isArray bar",isArray(bar))
print("isArray baz",isArray(baz))
]]