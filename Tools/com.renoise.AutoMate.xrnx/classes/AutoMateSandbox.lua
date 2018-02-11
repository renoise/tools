--[[===============================================================================================
-- AutoMateSandbox.lua
===============================================================================================]]--

--[[--

This class is able to evaluate lua code, in order to generate or transform envelopes 

--]]

--=================================================================================================

class 'AutoMateSandbox' (AutoMatePreset)

AutoMateSandbox.__PERSISTENCE = {
  "name",
  "arguments",
  "callback",
}

---------------------------------------------------------------------------------------------------

function AutoMateSandbox:__init()
  TRACE("AutoMateSandbox:__init()")

  AutoMatePreset.__init(self)

  -- string, name of preset 
  self.name = "Linear Ramp Up"

  -- table<AutoMateSandboxArgument>
  self.arguments = {}

  -- arguments, using dot notation (used by sandbox)
  self._sandbox_args = {}

  -- string
  self.callback = property(self._get_callback,self._set_callback)
  self._callback = nil

  self.sandbox = cSandbox()
  self.sandbox.properties = {
    ["cLib"] = {
      access = function(env) return cLib end,
    },
  }
  self.sandbox.compile_at_once = true
  self.sandbox.str_prefix = [[
    index = select(1,...)
    number_of_points = select(2,...)
    points_per_line = select(3,...)
    playmode = select(4,...)
    xpos = select(5,...)
  ]]
  self.sandbox.str_suffix = [[
    return {
      time = point.time,
      value = cLib.clamp_value(point.value,0,1),
      playmode = playmode,
    }
  ]]

end

---------------------------------------------------------------------------------------------------

function AutoMateSandbox:__tostring()

  return type(self)
    .."{"
    .."name"..tostring(name)
    .."arguments"..tostring(#arguments)
    --.."callback"..tostring(callback)
    .."}"

end

---------------------------------------------------------------------------------------------------
-- Getters and Setters
---------------------------------------------------------------------------------------------------

function AutoMateSandbox:_get_callback()
  return self._callback
end

function AutoMateSandbox:_set_callback(str)
  TRACE("AutoMateSandbox:_set_callback(str)",str)

  assert(type(str)=="string")

  -- validate syntax before setting 
  local success,err = self.sandbox:test_syntax(str)
  if err then 
    error(err)
  end
  
  self._callback = str
  self.sandbox.callback_str = str

end

---------------------------------------------------------------------------------------------------
-- Class methods
---------------------------------------------------------------------------------------------------
-- generator function

function AutoMateSandbox:create_point(point_idx,number_of_points,ppl,playmode,xpos,xinc)     
  -- prepare environment (reset every time)
  self.sandbox.env.point = {}
  self.sandbox.env.args = self._sandbox_args
  local point = nil
  local success,err = pcall(function()
    point = self.sandbox.callback(point_idx,number_of_points,ppl,playmode,xpos,xinc)
  end)
  --print("success,err,point",success,err,rprint(point))
  if not success and err then
    LOG("*** ERROR: please review the callback function - "..err)
    LOG("*** ",self.sandbox.callback_str)
    return {}
  else
    return point
  end
end

---------------------------------------------------------------------------------------------------
-- @return AutoMateSandboxArgument or nil 
-- @return number or nil

function AutoMateSandbox:get_argument_by_name(name)

  for k,v in ipairs(self.arguments) do 
    if (v.name == name) then 
      return v,k
    end
  end

end

---------------------------------------------------------------------------------------------------
-- prepare table that is passed to sandbox 
-- (should be called _after_ preset is loaded)

function AutoMateSandbox:prepare_arguments()
  TRACE("AutoMateSandbox:prepare_arguments()")
  
  self._sandbox_args = {}
  if not table.is_empty(self.arguments) then
    for k,v in ipairs(self.arguments) do 
      self._sandbox_args[v.name] = v.value
    end
  end

  --print("self._sandbox_args",rprint(self._sandbox_args))

end

---------------------------------------------------------------------------------------------------
-- cPersistence
---------------------------------------------------------------------------------------------------
-- (extend the cPersistence method)

function AutoMateSandbox:load(file_path)
  TRACE("AutoMateSandbox:load(file_path)")

  cPersistence.load(self,file_path)
  self:prepare_arguments()

end

---------------------------------------------------------------------------------------------------
-- (override the cPersistence method)

function AutoMateSandbox:serialize()
  TRACE("AutoMateSandbox:serialize()")

  local max_depth = nil
  local longstring = true

  return ""
  .."--[[==========================================================================="
  .."\n "..type(self).." (" .. AutoMate.WEBSITE .. ")"
  .."\n===========================================================================]]--"
  .."\n"
  .."\nreturn " .. cLib.serialize_table(self:obtain_definition(),max_depth,longstring)

end  

