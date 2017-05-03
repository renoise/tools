--[[============================================================================
LFO
============================================================================]]--

--[[--
Class used to create an oscillator in xStream, primarily useful for generating
pattern data.
#
]]

class 'LFO'

LFO.DEFAULT_TYPE        = "min"
LFO.DEFAULT_FREQ        = 16
LFO.DEFAULT_MIN_VALUE   = 0
LFO.DEFAULT_MAX_VALUE   = 1
LFO.DEFAULT_PHASE       = 0
LFO.DEFAULT_RESOLUTION  = nil
LFO.ABBREVIATIONS       =
{
  ["sine"]     = { "sin" },
  ["square"]   = { "pulse", "sqr" },
  ["random"]   = { "rnd", "noise", "rand" },
  ["triangle"] = { "tri", "triangle" },
  ["saw"]      = { "ramp", "sawtooth" },
  ["min"]      = { "low" },
  ["max"]      = { "high" }
}

LFO.func =
{
  ["sine"] =
    function(phase) return math.sin(math.rad(360 * phase)) / 2 + 0.5 end,
  ["square"] =
    function(phase) if (phase <= 0.5) then return 1 else return 0 end end,
  ["random"] =
    function(phase) return math.random() end,
  ["triangle"] =
    function(phase) return math.abs(((phase+0.75) % 1) - 0.5) * 2 end,
  ["saw"] =
    function(phase) return phase end,
  ["min"] =
    function() return 0 end,
  ["max"] =
    function() return 1 end
}

-------------------------------------------------------------------------------
-- constructor
-- @param type (string). Default: LFO.DEFAULT_TYPE
--   LFO type or user abbreviation thereof (e.g. "square" or "sqr").
-- @param freq (number, >0). Default: LFO.DEFAULT_FREQ
--   the duration of one oscillation in amount of lines.
-- @param phase (number, 0-1 or nil). Default: LFO.DEFAULT_PHASE
--   the phase of the LFO (e.g. "shifting" the cycle).
-- @param min_value (number or nil). Default: LFO.DEFAULT_MIN_VALUE
--   the the minimum value returned by the oscillator.
-- @param max_value (number or nil). Default: LFO.DEFAULT_MAX_VALUE
--   the the maximum value returned by the LFO.
-- @param resolution (number or nil). Default: nil
--   rounding the LFO output value to any resolution, e.g. 1, 0.2, 1/3.
-------------------------------------------------------------------------------

function LFO:__init(type, freq, phase, min_value, max_value, resolution, xinc)
  self.type = type or self.DEFAULT_TYPE
  self.freq = freq or self.DEFAULT_FREQ
  self.phase = phase or self.DEFAULT_PHASE
  self.min_value = min_value or self.DEFAULT_MIN_VALUE
  self.max_value = max_value or self.DEFAULT_MAX_VALUE
  self.resolution = resolution or self.DEFAULT_RESOLUTION
  self._start_xinc = xinc
  self._curr_xinc = nil
end

-------------------------------------------------------------------------------
-- Properties (get/set functions)
-------------------------------------------------------------------------------

LFO.type = property(
  function(obj) return obj._type end,
  function(obj, val)
    if not obj.func[val] then
      for i_osc, osc in pairs(obj.ABBREVIATIONS) do
        for i_abr, user_abr in ipairs(osc.user_abr) do
          if (user_abr == val) then val = i_osc end
        end
      end
    end
    assert(obj.func[val], "LFO error: invalid LFO type.")
    obj._type = val
  end)

LFO.freq = property(
  function(obj) return obj._freq end,
  function(obj, val)
    local valid =
    assert((tonumber(val) and (val > 0)) or not val,
      "LFO error: freq must be a number larger than zero.")
    obj._freq = tonumber(val) or obj.DEFAULT_FREQ
  end)

LFO.phase = property(
  function(obj) return obj._phase end,
  function(obj, val)
    assert((tonumber(val) and val >= 0 and val <= 1) or not val,
      "LFO error: phase must be a number between 0 and 1.")
    obj._phase = tonumber(val) or obj.DEFAULT_PHASE
  end)

LFO.min_value = property(
  function(obj) return obj._min_value end,
  function(obj, val)
    assert((tonumber(val)) or not val,
      "LFO error: min_value must be a number.")
    obj._min_value = tonumber(val) or obj.DEFAULT_MIN_VALUE
  end)

LFO.max_value = property(
  function(obj) return obj._max_value end,
  function(obj, val)
    assert((tonumber(val)) or not val,
      "LFO error: max_value must be a number.")
    obj._max_value = tonumber(val) or obj.DEFAULT_MAX_VALUE
  end)

LFO.resolution = property(
  function(obj) return obj._resolution end,
  function(obj, val)
    assert((tonumber(val)) or not val,
      "LFO error: resolution must be a number.")
    obj._resolution = tonumber(val) or obj.DEFAULT_RESOLUTION
  end)

LFO.value = property(
  function(obj)
    local result = obj.func[obj.type](obj.runtime % obj.freq / obj.freq +
          obj.phase) * (obj.max_value-obj.min_value) + obj.min_value
    if obj.resolution then
      result = math.floor((result*(1/obj.resolution))+0.5)/(1/obj.resolution)
    end
    return result
  end)

LFO.runtime = property(
  function(obj) return obj._curr_xinc - obj._start_xinc
  end)

-------------------------------------------------------------------------------
-- Metamethods
-------------------------------------------------------------------------------

function LFO:reset(phase)
  self.phase, self._start_xinc = phase or 0, self._curr_xinc
end

function LFO:__call(min, max, resolution, lower_lim, upper_lim, value, xinc)
  lower_lim, upper_lim = lower_lim or min, upper_lim or max
  self._curr_xinc = xinc
  value = tonumber(value) or self.value
  assert(tonumber(value) and value >= 0 and value <= 1,
    "LFO error: input value must be number between 0 and 1.")
  assert(tonumber(min .. max),
    "LFO error: scaling values must be numbers.")
  assert(tonumber(resolution) or resolution == nil,
    "LFO error: scaling resolution must be a number or nil.")
  local result = ((max-min) + min) * value
  if resolution then
    result = math.floor((result*(1/resolution))+0.5)/(1/resolution)
  end
  return math.max(lower_lim, math.min(upper_lim, result))
end

-------------------------------------------------------------------------------

function LFO:__tostring() return self.value end

function LFO:__len() return self.freq end

function LFO:__unm() return 0 - self.value end

-------------------------------------------------------------------------------

function LFO:__add(arg)
  if type(self) == type(arg) then arg = arg.value end
  return self.value + tonumber(arg)
end

function LFO:__mul(arg)
  if type(self) == type(arg) then arg = arg.value end
  return self.value * tonumber(arg)
end

function LFO:__sub(arg)
  if type(self) == type(arg) then arg = arg.value end
  return self.value - tonumber(arg)
end

function LFO:__div(arg)
  if type(self) == type(arg) then arg = arg.value end
  return self.value / tonumber(arg)
end

function LFO:__pow(arg)
  if type(self) == type(arg) then arg = arg.value end
  return self.value ^ tonumber(arg)
end