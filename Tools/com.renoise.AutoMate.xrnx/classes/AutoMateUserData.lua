--[[===============================================================================================
AutoMateUserData
===============================================================================================]]--
--[[

Methods for handling the userdata folder

#

]]

--=================================================================================================

class 'AutoMateUserData'


-- location of main userdata folder 
-- (can overridden by custom folder defined in preferences)
AutoMateUserData.DEFAULT_ROOT = renoise.tool().bundle_path .. "/userdata/"
AutoMateUserData.USERDATA_ROOT = AutoMateUserData.DEFAULT_ROOT

-- userdata subfolders
AutoMateUserData.LIBRARY_FOLDER     = "library/"
AutoMateUserData.GENERATORS_FOLDER  = "generators/"
AutoMateUserData.TRANSFORMERS_FOLDER  = "transformers/"

---------------------------------------------------------------------------------------------------
-- [Static] Copy files from old to new folder 
-- @return boolean, true when files were copied
-- @return string, error message when failed 

function AutoMateUserData.migrate_to_folder(old_path,new_path)
  TRACE("AutoMateUserData.migrate_to_folder(old_path,new_path)",old_path,new_path)

  local success,err = cFilesystem.copy_folder(old_path,new_path)
  if not success then 
    return false,err
  end 

  return true

end 
