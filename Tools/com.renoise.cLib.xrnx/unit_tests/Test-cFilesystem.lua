--[[

  Testcase for cFilesystem

--]]

_tests:insert({
name = "cFilesystem",
fn = function()

  cLib.require (_clibroot.."cFilesystem")
  _trace_filters = {"^cFilesystem*"}

  local absolute_path = renoise.tool().bundle_path .. "/cFilesystem_test/"
  local relative_path = "./../cFilesystem_test/"

  local function clean_temp_files()
    print (cFilesystem.rmdir(relative_path))
  end

  -- initialize

  clean_temp_files()

  if io.exists(relative_path) then
    error("Cannot run this unit-test - a folder already exists at this location: "..relative_path.." (please remove it manually and try again)" )
    return
  end

  os.mkdir(relative_path)

  ---------------------------------------------------------

  print (">>> cFilesystem: starting unit-test...")

  -- @ cFilesystem.get_path_parts 
  
	local folder,filename,extension = cFilesystem.get_path_parts("C:\\Root Folder\\SubFolder\\file with.extension")
  assert(folder == "C:\\Root Folder\\SubFolder\\")
  assert(filename == "file with.extension")
  assert(extension == "extension")

	local folder,filename,extension = cFilesystem.get_path_parts(".\\Root Folder\\SubFolder\\file without extension")
  assert(folder == ".\\Root Folder\\SubFolder\\")
  assert(filename == "file without extension")
  assert(extension == nil)

	local folder,filename,extension = cFilesystem.get_path_parts(".\\Root Folder\\SubFolder\\")
  assert(folder == ".\\Root Folder\\SubFolder\\")
  assert(filename == nil)
  assert(extension == nil)

	local folder,filename,extension = cFilesystem.get_path_parts("/root folder/subfolder/file without extension")
  assert(folder == "/root folder/subfolder/")
  assert(filename == "file without extension")
  assert(extension == nil)

	local folder,filename,extension = cFilesystem.get_path_parts("./root folder/subfolder/file with.extension")
  assert(folder == "./root folder/subfolder/")
  assert(filename == "file with.extension")
  assert(extension == "extension")

	local folder,filename,extension = cFilesystem.get_path_parts("./root folder/subfolder/")
  assert(folder == "./root folder/subfolder/")
  assert(filename == nil)
  assert(extension == nil)


  -- @ cFilesystem.get_parent_directory 

  local parent_folder = cFilesystem.get_parent_directory("C:\\Root Folder\\SubFolder\\file with.extension")
  assert(parent_folder == "C:/Root Folder/",parent_folder)
  parent_folder = cFilesystem.get_parent_directory(parent_folder)
  assert(parent_folder == "C:/")
  parent_folder = cFilesystem.get_parent_directory(parent_folder)
  print (parent_folder)
  assert(parent_folder == "C:/")

  local parent_folder = cFilesystem.get_parent_directory(".\\Root Folder\\SubFolder\\file without extension")
  assert(parent_folder == "./Root Folder/")
  parent_folder = cFilesystem.get_parent_directory(parent_folder)
  assert(parent_folder == "./")

  local parent_folder = cFilesystem.get_parent_directory("/root folder/subfolder/file without extension")
  assert(parent_folder == "/root folder/")
  parent_folder = cFilesystem.get_parent_directory(parent_folder)
  assert(parent_folder == "/")

  local parent_folder = cFilesystem.get_parent_directory("./root folder/subfolder/file with.extension")
  assert(parent_folder == "./root folder/",parent_folder)
  parent_folder = cFilesystem.get_parent_directory(parent_folder)
  assert(parent_folder == "./")


  -- @ cFilesystem.get_raw_filename

  assert(cFilesystem.get_raw_filename("C:\\Root Folder\\SubFolder\\file with.extension") == "file with")
  assert(cFilesystem.get_raw_filename("C:\\Root Folder\\SubFolder\\file without extension") == "file without extension")
  assert(cFilesystem.get_raw_filename("C:\\Root Folder\\SubFolder\\") == nil)


  -- TODO validate_filename




  -- define a 'tricky' string 
  local str_test = [[This is a long string with linebreaks
And some special characters: ���!"#�%&/(
Will it be the same once loaded from disk?]]

  -- save to disk
  assert(cFilesystem.write_string_to_file(relative_path.."file",str_test))

  -- ensure_unique_filename (no extension)
  local unique_file_path_1 = cFilesystem.ensure_unique_filename(relative_path.."file")
  assert(unique_file_path_1 == relative_path.."file (1)",unique_file_path_1)

  -- save to disk (with extension)
  assert(cFilesystem.write_string_to_file(relative_path.."file.tmp",str_test))

  -- ensure_unique_filename
  local unique_file_path_1 = cFilesystem.ensure_unique_filename(relative_path.."file.tmp")
  assert(unique_file_path_1 == relative_path.."file (1).tmp",unique_file_path_1)

  -- save string as unique filename 
  assert(cFilesystem.write_string_to_file(unique_file_path_1,str_test))

  -- now load string and compare results
  local fhandle = io.open(unique_file_path_1)
  local str_test_result = fhandle:read("*a")
  fhandle:close()
  assert(str_test == str_test_result)

  -- repeat, but using the unique filename as basis
  -- the method should detect the (1) and use it as basis 
  local unique_file_path_2 = cFilesystem.ensure_unique_filename(unique_file_path_1)
  assert(unique_file_path_2 == relative_path.."file (2).tmp",unique_file_path_2)
  assert(cFilesystem.write_string_to_file(unique_file_path_2,str_test))


  -- @ cFilesystem.makedir 

  local deep_folder_path = relative_path.."one/two/three/"
  assert(cFilesystem.makedir(deep_folder_path))
  assert(io.exists(deep_folder_path))

  local abs_path = absolute_path .. "foo/bar/"
  assert(cFilesystem.makedir(abs_path))
  assert(io.exists(abs_path))


  -- @ cFilesystem.rename

  local old_path = relative_path .. "file.tmp"
  local new_path = relative_path .. "renamed_file.tmp"
  assert(cFilesystem.rename(old_path,new_path))
  assert(io.exists(new_path))

  local old_path = relative_path .. "renamed_file.tmp"
  local new_path = relative_path .. "one"
  assert(not cFilesystem.rename(old_path,new_path))

  local old_path = relative_path .. "renamed_file.tmp"
  local new_path = relative_path .. "one/renamed_again.tmp"
  assert(cFilesystem.rename(old_path,new_path))

  local old_path = relative_path .. "one/two" 
  local new_path = relative_path .. "one/twostep"
  assert(cFilesystem.rename(old_path,new_path))

  local old_path = relative_path .. "one/renamed_again.tmp"
  local new_path = absolute_path .. "renamed_file.tmp"
  assert(cFilesystem.rename(old_path,new_path))

  local old_path = absolute_path .. "renamed_file.tmp"
  local new_path = absolute_path .. "foo"
  assert(not cFilesystem.rename(old_path,new_path))

  local old_path = absolute_path .. "renamed_file.tmp"
  local new_path = absolute_path .. "foo/bar/renamed_again.tmp"
  assert(cFilesystem.rename(old_path,new_path))

  local old_path = absolute_path .. "foo/bar"
  local new_path = absolute_path .. "foo/baz"
  assert(cFilesystem.rename(old_path,new_path))

  local old_path = absolute_path .. "foo"
  local new_path = absolute_path .. "foo/bar"
  assert(not cFilesystem.rename(old_path,new_path))

  local old_path = absolute_path .. "foo/baz"
  local new_path = absolute_path .. "baz"
  assert(cFilesystem.rename(old_path,new_path))

  local old_path = absolute_path .. "baz"
  local new_path = absolute_path .. "file"
  assert(not cFilesystem.rename(old_path,new_path))



  -- finish -----------------------------------------------

  --clean_temp_files()


  print (">>> cFilesystem: OK - passed all tests")

end
})
