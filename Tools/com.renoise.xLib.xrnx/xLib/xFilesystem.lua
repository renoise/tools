--[[============================================================================
xFilesystem
============================================================================]]--
--[[


]]

class 'xFilesystem'

--- Static methods for dealing with the file-system


--------------------------------------------------------------------------------
--- split path into parts, seperated by slashes
-- important - folders should end with a slash
-- @return string, folder
-- @return string, filename
-- @return string, extension

function xFilesystem.get_path_parts(file_path)
  TRACE("xFilesystem.get_path_parts(file_path)",file_path)

  xFilesystem.assert_string(file_path,"file_path")

  local patt = "(.-)([^\\/]-%.?([^%.\\/]*))$"
  return string.match(file_path,patt)

end


--------------------------------------------------------------------------------
--- provided with a string, this method will find the parent folder
-- (using file system functions, so the location is guaranteed to exist)
-- @return string or nil if failed
-- @return int, error code

function xFilesystem.get_parent_directory(file_path)
  TRACE("xFilesystem.get_parent_directory(file_path)",file_path)

  xFilesystem.assert_string(file_path,"file_path")

  local path,file,ext = xFilesystem.get_path_parts(file_path)
  local path_parts = xFilesystem.get_directories(path)
  table.remove(path_parts) 

  return table.concat(path_parts,"/").."/"

end


--------------------------------------------------------------------------------
--- if file already exist, return a name with (number) appended to it

function xFilesystem.ensure_unique_filename(file_path)
  TRACE("xFilesystem.ensure_unique_filename(file_path)",file_path)

  xFilesystem.assert_string(file_path,"file_path")

  local rslt = file_path
  local path,file,ext = xFilesystem.get_path_parts(rslt)
  local count = 1
  while (io.exists(rslt)) do
    rslt = ("%s%s (%d).%s"):format(path,file,count,ext)
    count = count + 1
  end
  return rslt

end

--------------------------------------------------------------------------------
-- @return table<string>

function xFilesystem.get_directories(file_path)

  xFilesystem.assert_string(file_path,"file_path")

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

function xFilesystem.validate_filename(file_path)
  TRACE("xFilesystem.validate_filename(file_path)",file_path)

  xFilesystem.assert_string(file_path,"file_path")

  return not string.find(file_path,"[:\\/<>?|]")

end

--------------------------------------------------------------------------------
-- convert windows-style paths to unix-style 

function xFilesystem.unixslashes(file_path)
  print("xFilesystem.unixslashes(file_path)",file_path)

  return file_path:gsub("\\","/")

end

--------------------------------------------------------------------------------
--- remove illegal characters

function xFilesystem.sanitize_filename(file_path)
  TRACE("xFilesystem.sanitize_filename(file_path)",file_path)

  xFilesystem.assert_string(file_path,"file_path")

  return string.gsub(file_path,"[:\\/<>?|]","")

end


--------------------------------------------------------------------------------
-- add file extension (if it hasn't already got it)
-- @param filename (string), the whole filename and/or path
-- @param extension (string), the file extension, e.g. "lua"

function xFilesystem.file_add_extension(file_path,extension)
  TRACE("xFilesystem.file_add_extension(file_path,extension)",file_path,extension)

  xFilesystem.assert_string(file_path,"file_path")
  xFilesystem.assert_string(extension,"extension")

  local check_against = string.sub(file_path,-#extension)
  if ((check_against):lower() == (extension):lower()) then
    return file_path
  else
    return ("%s.%s"):format(file_path,extension) 
  end

end


--------------------------------------------------------------------------------
-- remove file extension (if present and matching)
-- @param file_path (string), the whole file path, e.g. "/home/example.lua"
-- @param extension (string), the file extension, e.g. "lua"
-- @return string, e.g. "example"

function xFilesystem.file_strip_extension(file_path,extension)
  TRACE("xFilesystem.file_strip_extension(file_path,extension)",file_path,extension)

  xFilesystem.assert_string(file_path,"file_path")
  xFilesystem.assert_string(extension,"extension")

  local patt = "(.*)%.([^.]*)$"
  local everything_else,ext = string.match(file_path,patt)

  if (string.lower(extension) == string.lower(ext)) then
    return everything_else
  end

  return file_path

end


--------------------------------------------------------------------------------
-- so widely used it got it's own function

function xFilesystem.assert_string(str,str_name)

  assert(str,"No "..str_name.." specified")
  assert(type(str)=="string",str_name..": expected string, got"..type(str))

end

--------------------------------------------------------------------------------
-- save string to disk
-- @return bool, true when successful, false when not
-- @erturn err, error message if failed

function xFilesystem.write_string_to_file(file_path,str)
  TRACE("xFilesystem.write_string_to_file(file_path,str)")
  --print("file_path",file_path)

  xFilesystem.assert_string(file_path,"file_path")

  local success = true

  local handle = io.open(file_path,"w")
  --print("handle",handle)
  if not handle:write(str) then
    success = false
  end
  handle:close()

  if not success then
    return false, "Could not write to file"
  else
    return true
  end

end