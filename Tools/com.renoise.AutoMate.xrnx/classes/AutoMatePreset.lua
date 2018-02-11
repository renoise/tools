--[[===============================================================================================
-- AutoMate.lua
===============================================================================================]]--

--[[--

Base class for an AutoMate preset (`AutoMateClip`, `AutoMateGenerator`, etc.)
.

The class species just a single property, 'name', which is checked when loading presets.
See also: `AutoMatePresetManager`

--]]

--=================================================================================================

class 'AutoMatePreset' (cPersistence)

AutoMatePreset.__PERSISTENCE = {
  "name",
}

---------------------------------------------------------------------------------------------------

function AutoMatePreset:__init()
  TRACE("AutoMatePreset:__init()")

  self.name = nil 

end 




