--[[===============================================================================================
-- AutoMateSandboxArgument.lua
===============================================================================================]]--

--[[--

This class is used for defining argument for AutoMate generators and transformers.

--]]


--=================================================================================================

class 'AutoMateSandboxArgument' (cPersistence)

AutoMateSandboxArgument.__PERSISTENCE = {
  "name",
  "value",
  "value_min",
  "value_max",
  "value_quantum",
  "display_as",
}

-- possible viewbuilder representations
AutoMateSandboxArgument.DISPLAY_AS = {  
  VALUEBOX = "valuebox",
  MINISLIDER = "minislider",
  POPUP = "popup",
}

---------------------------------------------------------------------------------------------------

function AutoMateSandboxArgument:__init(...)
  TRACE("AutoMateSandboxArgument:__init(...)")

  local args = cLib.unpack_args(...)

  -- cNumber 
  self.arg = cNumber{value=args.value or 0}
  
  -- string 
  self.name = args.name or "untitled" 

  self.value = property(self._get_value,self._set_value)
  self.value_min = property(self._get_value_min,self._set_value_min)
  self.value_max = property(self._get_value_max,self._set_value_max)
  self.value_enums = property(self._get_value_enums,self._set_value_enums)
  self.value_quantum = property(self._get_value_quantum,self._set_value_quantum)
  
  self.value_changed_observable = renoise.Document.ObservableBang()
  
  -- AutoMateSandboxArgument.DISPLAY_AS 
  self.display_as = AutoMateSandboxArgument.DISPLAY_AS.VALUEBOX
  
  -- assign remaining varargs to our cNumber -- 

  self.value_min = args.value_min or self.value_min 
  self.value_max = args.value_max or self.value_max 
  self.value_enums = args.value_enums or self.value_enums 
  self.value_quantum = args.value_quantum or self.value_quantum 

end

---------------------------------------------------------------------------------------------------
-- Getters and Setters
---------------------------------------------------------------------------------------------------
-- proxy access to cNumber

function AutoMateSandboxArgument:_get_value()
  return self.arg.value
end
function AutoMateSandboxArgument:_set_value(val)
  local old_val = self.arg.value 
  self.arg:set_value(val) -- clamp to min/max
  if (old_val ~= self.arg.value) then 
    self.value_changed_observable:bang()
  end
end

function AutoMateSandboxArgument:_get_value_min()
  return self.arg.value_min
end
function AutoMateSandboxArgument:_set_value_min(val)
  assert(type(val)=="number")
  self.arg.value_min = val
end

function AutoMateSandboxArgument:_get_value_max()
  return self.arg.value_max
end
function AutoMateSandboxArgument:_set_value_max(val)
  assert(type(val)=="number")
  self.arg.value_max = val
end

function AutoMateSandboxArgument:_get_value_enums()
  return self.arg.value_enums
end
function AutoMateSandboxArgument:_set_value_enums(val)
  assert(type(val)=="table")
  self.arg.value_enums = val
end

function AutoMateSandboxArgument:_get_value_quantum()
  return self.arg.value_quantum
end
function AutoMateSandboxArgument:_set_value_quantum(val)
  assert(type(val)=="table")
  self.arg.value_quantum = val
end

---------------------------------------------------------------------------------------------------
-- cPersistence
---------------------------------------------------------------------------------------------------
-- override default impl. 

function AutoMateSandboxArgument:assign_definition(def)
  TRACE("AutoMateSandboxArgument:assign_definition(def)",def)

  assert(type(def)=="table")

  self.name = def.name
  self.display_as = def.display_as
  self.arg = cNumber{
    value = def.value,
    value_min = def.value_min,
    value_max = def.value_max,
    value_quantum = def.value_quantum
  }

end

---------------------------------------------------------------------------------------------------
-- override default impl. 

function AutoMateSandboxArgument:obtain_definition()
  TRACE("AutoMateSandboxArgument:obtain_definition()")

  return {
    __type = type(self),
    name = self.name,
    display_as = self.display_as,
    value = self.arg.value,
    value_min = self.arg.value_min,
    value_max = self.arg.value_max,
    value_quantum = self.arg.value_quantum,
  }

end

---------------------------------------------------------------------------------------------------

function AutoMateSandboxArgument:__tostring()

  return type(self)
    .."{"
    .."name:"..tostring(self.name)
    ..",value:"..tostring(self.value)
    ..",min:"..tostring(self.value_min)
    ..",max:"..tostring(self.value_max)
    .."}"

end

