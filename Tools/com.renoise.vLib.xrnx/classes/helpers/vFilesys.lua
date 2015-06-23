--[[============================================================================
vFilesys
============================================================================]]--
--[[


]]

class 'vFilesys'

--------------------------------------------------------------------------------
--- Static methods for dealing with the file-system


--------------------------------------------------------------------------------
-- important - folders should end with a slash
-- @return string, folder
-- @return string, filename
-- @return string, extension

function vFilesys.get_path_parts(file_path)
  TRACE("vFilesys.get_path_parts(file_path)",file_path)

  local patt = "(.-)([^\\/]-%.?([^%.\\/]*))$"
  return string.match(file_path,patt)

end


--------------------------------------------------------------------------------
--- provided with a string, this method will find the parent folder
-- (using file system functions, so the location is guaranteed to exist)
-- @return string or nil if failed
-- @return int, error code

function vFilesys.get_parent_directory(file_path)
  TRACE("vFilesys.get_parent_directory(file_path)",file_path)

  local path,file,ext = vFilesys.get_path_parts(file_path)
  local path_parts = vFilesys.get_directories(path)
  table.remove(path_parts) 

  return table.concat(path_parts,"/").."/"

end


--------------------------------------------------------------------------------
--- if file already exist, return a name with (number) appended to it

function vFilesys.ensure_unique_filename(file_path)
  TRACE("vFilesys.ensure_unique_filename(file_path)",file_path)

  local rslt = file_path
  local path,file,ext = vFilesys.get_path_parts(rslt)
  local count = 1
  while (io.exists(rslt)) do
    rslt = ("%s%s (%d).%s"):format(path,file,count,ext)
    count = count + 1
  end
  return rslt

end

--------------------------------------------------------------------------------
--- split path into parts, seperated by slashes
-- @return table>string

function vFilesys.get_directories(file_path)

  local matches = string.gmatch(file_path,"(.-)([^\\/])")
  local part = ""
  local parts = {}
  for k,v in matches do
    if (k=="") then
      part = part..v
    else
      table.insert(parts,part)
      part = v
    end
  end
  table.insert(parts,part)

  return parts

end

--------------------------------------------------------------------------------
--- make sure a file/folder name does not contain anything considered bad 
-- return bool

function vFilesys.validate_filename(str)
  TRACE("vFilesys.validate_filename(str)",str)

  return not string.find(str,"[:\\/<>?|]")

end

--------------------------------------------------------------------------------
--- remove illegal characters

function vFilesys.sanitize_filename(filename)
  TRACE("vFilesys.sanitize_filename(filename)",filename)

  return string.gsub(filename,"[:\\/<>?|]","")

end


