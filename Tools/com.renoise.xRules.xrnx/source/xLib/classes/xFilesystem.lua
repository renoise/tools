--[[============================================================================
xFilesystem
============================================================================]]--
--[[

  Static methods for dealing with the file-system

]]

class 'xFilesystem'

xFilesystem.FILETYPE = {
  FOLDER = 1,
  FILE = 2,
}

--------------------------------------------------------------------------------
-- split path into parts, seperated by slashes
-- important - folders should end with a slash
-- note: this is a virtual function which doesn't require I/O access 
-- @param file_path (string)
-- @return string, folder
-- @return string, filename
-- @return string, extension

function xFilesystem.get_path_parts(file_path)

  xFilesystem.assert_string(file_path,"file_path")

  local patt = "(.-)([^\\/]-%.?([^%.\\/]*))$"
  local folder,filename,extension = string.match(file_path,patt)

  if (filename == extension) then
    extension = nil
  end

  if (filename == "") then
    filename = nil
  end

  return folder,filename,extension

end

--------------------------------------------------------------------------------
-- provided with a complete path, returns just the filename (no extension)
-- note: this is a virtual function which doesn't require I/O access 
-- @param file_path (string)
-- @return string or nil

function xFilesystem.get_raw_filename(file_path)

  xFilesystem.assert_string(file_path,"file_path")

  local folder,filename,extension = xFilesystem.get_path_parts(file_path)
  if not filename then
    return
  end
  if extension then
    return xFilesystem.file_strip_extension(filename,extension)
  else
    return filename
  end

end


--------------------------------------------------------------------------------
-- check if the given string indicates a root folder
-- note: a root folder is considered "/" on unix-based systems, and 
--  [drive letter]:/ on windows systems
-- note: this is a virtual function which doesn't require I/O access 

function xFilesystem.is_root_folder(str)

  xFilesystem.assert_string(str,"str")

  str = xFilesystem.unixslashes(str)
  if (str == "/") then
    return true
  elseif (str:match("[a-zA-Z]?:/+$")) then
    return true
  else
    return false
  end

end

--------------------------------------------------------------------------------
-- provided with a string, this method will find the parent folder
-- note: returned string is using unix slashes
-- note: this is a virtual function which doesn't require I/O access 
-- @param file_path (string)
-- @return string or nil if failed
-- @return int, error code

function xFilesystem.get_parent_directory(file_path)

  xFilesystem.assert_string(file_path,"file_path")

  local folder,filename,extension = xFilesystem.get_path_parts(file_path)
  local path_parts = xFilesystem.get_directories(folder)
  --print("#path_parts",#path_parts)
  if (#path_parts > 1) then
    table.remove(path_parts) 
    return table.concat(path_parts,"/").."/"
  else -- root 
    return file_path
  end

end


--------------------------------------------------------------------------------
-- if file already exist, return a name with (number) appended to it
-- note: this is a virtual function which doesn't require I/O access 
-- @param file_path (string)

function xFilesystem.ensure_unique_filename(file_path)

  xFilesystem.assert_string(file_path,"file_path")

  local rslt = file_path
  local folder,filename,extension = xFilesystem.get_path_parts(rslt)

  local file_no_ext = extension 
    and xFilesystem.file_strip_extension(filename,extension)
    or filename

  -- detect existing counter, and continue from there...
  local count = string.match(file_no_ext,"%((%d)%)$")
  if count then 
    file_no_ext = string.gsub(file_no_ext,"%s*%(%d%)$","")
  else
    count = 1
  end

  while (io.exists(rslt)) do
    if extension then
      rslt = ("%s%s (%d).%s"):format(folder,file_no_ext,count,extension)
    else
      rslt = ("%s%s (%d)"):format(folder,file_no_ext,count)
    end
    count = count + 1
  end
  return rslt

end

--------------------------------------------------------------------------------
-- break a string into directories
-- note: this is a virtual function which doesn't require I/O access 
-- @param file_path (string)
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
-- create a whole folder structure in one go
-- (unlike the standard os.mkdir, which is limited to a single folder)
-- @param file_path (string)
-- @return bool, true when folder(s) were created
-- @return string, error message when failed

function xFilesystem.makedir(file_path)

  xFilesystem.assert_string(file_path,"file_path")

  local folder_path = xFilesystem.get_path_parts(file_path)
  local folders = xLib.split(folder_path,"[/\\]")

  local tmp_path = ""

  for k,v in ipairs(folders) do
    tmp_path = ("%s%s/"):format(tmp_path,v)
    if (v == ".") then
      -- relative path, skip "dot"
    else
      if not io.exists(tmp_path) then
        --print("about to create folder - tmp_path",tmp_path)
        if xFilesystem.is_root_folder(tmp_path) then
          --print("skip root",tmp_path)
        else
          local success,err = os.mkdir(tmp_path)
          if not success then
            return false,err
          end
        end
      end
    end
  end

  return true

end

--------------------------------------------------------------------------------
-- rename a file or folder
-- @param old_f (string)
-- @param new_f (string)
-- @options (table) TODO
--    "replace" - for existing files/folders
--    "merge" - for existing folders

function xFilesystem.rename(old_f,new_f)

  xFilesystem.assert_string(old_f,"old_f")
  xFilesystem.assert_string(new_f,"new_f")

  local passed,err = os.rename(old_f,new_f)
  return passed,err

end

--------------------------------------------------------------------------------
-- on non-posix systems (windows), you can't remove a folder which is not
-- empty - this method will iterate through and delete all files/folders
-- @param folder_path (string)
-- @return bool, true when folder was removed
-- @return string, error message when failed

function xFilesystem.rmdir(folder_path)

  xFilesystem.assert_string(folder_path,"folder_path")

  if not io.exists(folder_path) then
    return false,"Folder does not exist"
  end

  for __, dirname in pairs(os.dirnames(folder_path)) do
    xFilesystem.rmdir(folder_path..dirname.."/")
  end

  for __, filename in pairs(os.filenames(folder_path)) do
    local success,err = os.remove(folder_path..filename)
    if not success then
      return false,err
    end
  end

  local success,err = os.remove(folder_path)
  if not success then
    return false,err
  end

end

--------------------------------------------------------------------------------
-- make sure a file/folder name does not contain anything considered bad 
-- (such as special characters or preceding ./ dot-slash combinations)
-- @param file_path (string)
-- @return bool,string

function xFilesystem.validate_filename(file_path)

  xFilesystem.assert_string(file_path,"file_path")

  if (file_path == "") then
    return false, "Please enter a valid, non-blank name"
  end

  if string.find(file_path,"[:\\/<>?|]") then
    return false, "The name contains illegal characters"
  end

  return true

end

--------------------------------------------------------------------------------
-- convert windows-style paths to unix-style 
--  also: remove doubleslashes 
-- @param file_path (string)
-- @return string

function xFilesystem.unixslashes(file_path)

  local str = file_path:gsub("\\","/")
  return str:gsub("/+","/")

end

--------------------------------------------------------------------------------
--- remove illegal characters (similar to validate, but attempts to fix)
-- @param file_path (string)
-- @return string

function xFilesystem.sanitize_filename(file_path)

  xFilesystem.assert_string(file_path,"file_path")

  return string.gsub(file_path,"[:\\/<>?|]","")

end


--------------------------------------------------------------------------------
-- add file extension (if it hasn't already got it)
-- @param file_path (string)
-- @param extension (string)
-- @return string

function xFilesystem.file_add_extension(file_path,extension)

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
-- @param file_path (string)
-- @param extension (string)
-- @return string

function xFilesystem.file_strip_extension(file_path,extension)

  xFilesystem.assert_string(file_path,"file_path")
  xFilesystem.assert_string(extension,"extension")

  local patt = "(.*)%.([^.]*)$"
  local everything_else,ext = string.match(file_path,patt)
  --print("everything_else,ext")

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
-- load string from disk

function xFilesystem.load_string(file_path)

  local handle,err = io.open(file_path,"r")
  if not handle then
    return false,err
  end

  local finfo = io.stat(file_path)
  if (finfo.type ~= "file") then
    handle:close()
    return false, "Attempting to load string from a non-file"
  end

  local str = handle:read("*a") 
  if not str then
    handle:close()
    return false, "Failed to read from file"
  end

  handle:close()
  return str

end

--------------------------------------------------------------------------------
-- save string to disk
-- @param file_path (string)
-- @param str (string)
-- @return bool, true when successful, false when not
-- @return string, error message when failed

function xFilesystem.write_string_to_file(file_path,str)
  --print("file_path",file_path)

  xFilesystem.assert_string(file_path,"file_path")

  local success = true

  --print("io.exists",io.exists(file_path))

  local handle,err = io.open(file_path,"w")
  --print(">>> write_string_to_file - handle,err",handle,err)
  if not handle then
    -- often triggered by a folder that does not exist
    return false,err
  end
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


--------------------------------------------------------------------------------
-- iterate through folders, starting from the provided path
-- @param str_path (string)
-- @param callback_fn (function) return false to stop recursion

function xFilesystem.recurse(str_path,callback_fn,file_ext,level)

  if not file_ext then
    file_ext = {"*.*"}
  end
  
  if not level then
    level = 0
  end
  
  --print("str_path,file_ext")

  if not io.exists(str_path) then
    LOG(str_path,"path does not exist, returning")
    return
  end

  local filenames = os.filenames(str_path,file_ext)
  for k,v in ipairs(filenames) do
    --print("filenames",k,v)
    if not callback_fn(str_path,v,xFilesystem.FILETYPE.FILE) then
      return
    end
  end
  local dirnames = os.dirnames(str_path)
  for k,v in ipairs(dirnames) do
    --print("dirnames",k,v)
    if not callback_fn(str_path,v,xFilesystem.FILETYPE.FOLDER) then
      return
    end
    xFilesystem.recurse(str_path.."/"..v,callback_fn,file_ext,level+1)
  end

end

