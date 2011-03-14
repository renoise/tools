--[[--------------------------------------------------------------------------
TestClass.lua
--------------------------------------------------------------------------]]--

-- GlobalBaseClass

class "GlobalBaseClass"

function GlobalBaseClass:__init(str)
  self.__str = str
end

function GlobalBaseClass:__tostring()
  return self.__str
end


-- GlobalMyClass

class "GlobalMyClass"(GlobalBaseClass)

function GlobalMyClass:__init(str)
  GlobalBaseClass.__init(self, str)
end


-- namespace

namespace = { }


-- namespace.BaseClass

class (namespace, "BaseClass")

function namespace.BaseClass:__init(str)
  self.__str = str
end

function namespace.BaseClass:__tostring()
  return self.__str
end


-- namespace.MyClass(BaseClass)

class (namespace, "MyClass")(namespace.BaseClass)
 
function namespace.MyClass:__init(str)
  namespace.BaseClass.__init(self, str)
end


------------------------------------------------------------------------------
-- test

do

  -- tools
  
  local function assert_error(statement)
    assert(pcall(statement) == false, "expected function error")
  end
  
  
  -- test class namespaces
  
  assert_error(function() 
    assert(tostring(MyClass("Olla")) == "Olla") 
  end)
  
  assert(tostring(namespace.MyClass("Olla")) == "Olla")
  
  assert(type(GlobalBaseClass) == "GlobalBaseClass class")
  assert(type(GlobalBaseClass()) == "GlobalBaseClass")
  
  assert(type(GlobalMyClass) == "GlobalMyClass class")
  assert(type(GlobalMyClass()) == "GlobalMyClass")
  
  assert(type(namespace.BaseClass) == "BaseClass class")
  assert(type(namespace.BaseClass()) == "BaseClass")
  
  assert(type(namespace.MyClass) == "MyClass class")
  assert(type(namespace.MyClass()) == "MyClass")
  
  assert(type(renoise.song()) == "Song")
  assert(type(renoise.Song) == "Song class")
  
  -- rprint(namespace)
  -- oprint(GlobalMyClass())
  -- oprint(namespace.MyClass())


  -- test class object comparison
  
  local obj1 = GlobalMyClass()
  local obj2 = GlobalMyClass()
  
  assert(rawequal(obj1, obj1))
  assert(not rawequal(obj1, obj2))

  assert(rawequal(renoise.song(), renoise.song()))
  assert(rawequal(renoise.song().tracks[1], renoise.song().tracks[1]))
  assert(not rawequal(renoise.song().tracks[1], renoise.song().tracks[2]))
  assert(not rawequal(renoise.song().tracks[1], renoise.song().instruments[1]))
  assert(not rawequal(renoise.song().tracks[1], obj1))

end

