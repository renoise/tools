--[[============================================================================
Classes.lua
============================================================================]]--

error("do not run this file. read and copy/paste from it only...")

--[[

Renoises lua API has a simple OO support inbuilt -> class "MyClass". All 
Renoise API objects use such classes.

See http://www.rasterbar.com/products/luabind/docs.html#defining-classes-in-lua
for more technical info and below for some simple examples

Something to keep in mind:

* constructor "function MyClass:__init(args)" must be defined for each class, 
  or the class can't be used to instantiate objects
  
* class defs are always global, so even locally defined classes will be 
  registered globally...

--]]


-------------------------------------------------------------------------------

-- abstract class

class 'Animal'
  function Animal:__init(name)
    self.name = name
    self.can_fly = nil
  end  

  function Animal:__tostring()
    assert(self.can_fly ~= nil, "I don't know if I can fly or not")
    
    return ("I am a %s (%s) and I %s fly"):format(self.name, type(self), 
      (self.can_fly and "can fly" or "can not fly"))
  end


-- derived classes

-- MAMMAL
class 'Mammal' (Animal)
  function Mammal:__init(str)
    Animal.__init(self, str)
    self.can_fly = false
  end

-- BIRD
class 'Bird' (Animal)
  function Bird:__init(str)
    Animal.__init(self, str)
    self.can_fly = true
  end

-- FISH
class 'Fish' (Animal)
  function Fish:__init(str)
    Animal.__init(self, str)
    self.can_fly = false
  end


-- run

local farm = table.create()

farm:insert(Mammal("cow"))
farm:insert(Bird("sparrow"))
farm:insert(Fish("bass"))

print(("type(Mammal('cow')) -> %s"):format(type(Mammal("cow"))))
print(("type(Mammal) -> %s"):format(type(Mammal)))

for _,animal in pairs(farm) do
  print(animal)
end


-------------------------------------------------------------------------------
-- Class operators

-- You can overload most operators in Lua for your classes. You do this by 
-- simply declaring a member function with the same name as an operator 
-- (the name of the metamethods in Lua).

--[[ The operators you can overload are:

* __add
* __sub
* __mul
* __div
* __pow
* __lt
* __le
* __eq
* __call
* __unm
* __tostring
* __len

--]]

-- "__tostring" isn't really an operator, but it's the metamethod that is 
-- called by the standard library's tostring() function. 

