--------------------------------------------------------------------------------
-- Math
--------------------------------------------------------------------------------

-- greatest common divisor
function gcd(m,n)
  while n ~= 0 do
    local q = m
    m = n
    n = q % n
  end
  return m
end

-- least common multiplier (2 args)
function lcm(m,n)
  return ( m ~= 0 and n ~= 0 ) and m * n / gcd( m, n ) or 0
end

-- find least common multiplier with N args
function least_common(...)
  local cm = arg[1]
  for i=1,#arg-1,1 do
    cm = lcm(cm,arg[i+1])
  end
  return cm
end


--------------------------------------------------------------------------------
-- PHP style exlpode()
--------------------------------------------------------------------------------

function explode(div,str)
  if (div=='') then return false end
  local pos,arr = 0,table.create()
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end


--------------------------------------------------------------------------------
-- OneShotIdle Class
--------------------------------------------------------------------------------

-- delay a function call by the given amount of time into a tools idle notifier
--
-- for example: ´OneShotIdleNotifier(100, my_callback, some_arg, another_arg)´
-- calls "my_callback" with the given arguments with a delay of about 100 ms
-- a delay of 0 will call the callback "as soon as possible" in idle, but never
-- immediately

class "OneShotIdleNotifier"

function OneShotIdleNotifier:__init(delay_in_ms, callback, ...)
  assert(type(delay_in_ms) == "number" and delay_in_ms >= 0.0)
  assert(type(callback) == "function")

  self._callback = callback
  self._args = arg
  self._invoke_time = os.clock() + delay_in_ms / 1000

  renoise.tool().app_idle_observable:add_notifier(self, self.__on_idle)
end

function OneShotIdleNotifier:__on_idle()
  if (os.clock() >= self._invoke_time) then
    renoise.tool().app_idle_observable:remove_notifier(self, self.__on_idle)
    self._callback(unpack(self._args))
  end
end

