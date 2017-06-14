--[[===============================================================================================
xStreamUserData
===============================================================================================]]--
--[[

Methods for handling the userdata folder

#

]]

--=================================================================================================

class 'xStreamUserData'


-- location of main userdata folder 
-- (can overridden by custom folder defined in preferences)
xStreamUserData.DEFAULT_ROOT = renoise.tool().bundle_path .. "/userdata/"
xStreamUserData.USERDATA_ROOT = xStreamUserData.DEFAULT_ROOT

-- userdata subfolders (fixed)
xStreamUserData.FAVORITES_FILE_PATH = "favorites.xml"
xStreamUserData.MODELS_FOLDER       = "models/"
xStreamUserData.STACKS_FOLDER       = "stacks/"
xStreamUserData.PRESET_BANK_FOLDER  = "presets/"

---------------------------------------------------------------------------------------------------
-- [Static] Copy files from old to new folder 
-- @return boolean, true when files were copied
-- @return string, error message when failed 

function xStreamUserData.migrate_to_folder(old_path,new_path)
  TRACE("xStreamUserData.migrate_to_folder(old_path,new_path)",old_path,new_path)

  local success,err = cFilesystem.copy_folder(old_path,new_path)
  if not success then 
    return false,err
  end 

  return true

end 
