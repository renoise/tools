--[[===============================================================================================
-- AutoMate.lua
===============================================================================================]]--

--[[--

This class describes an automation clip created with AutoMate. 

--]]

--=================================================================================================

class 'AutoMateClip' (AutoMatePreset)

AutoMateClip.DEFAULT_NAME = "Untitled Clip"
AutoMateClip.__PERSISTENCE = {
  "name",
  "payload",
}

---------------------------------------------------------------------------------------------------
-- Constructor method

function AutoMateClip:__init(...)

  local args = cLib.unpack_args(...)

  -- string, user-assigned name 
  self.name = args.name and args.name or AutoMateClip.DEFAULT_NAME

  -- xEnvelope | xAudioDeviceAutomation
  self.payload = args.payload 

end

---------------------------------------------------------------------------------------------------
-- (override the cPersistence method)

function AutoMateClip:serialize()
  TRACE("AutoMateClip:serialize()")

  return ""
  .."--[[==========================================================================="
  .."\n AutoMateClip (" .. AutoMate.WEBSITE .. ")"
  .."\n===========================================================================]]--"
  .."\n"
  .."\nreturn " .. cLib.serialize_table(self:obtain_definition())

end  

---------------------------------------------------------------------------------------------------

function AutoMateClip:__tostring()

  return type(self).."{"
    .." name = "..tostring(self.name)
    ..",payload = "..tostring(self.payload)
    .."}"
end
