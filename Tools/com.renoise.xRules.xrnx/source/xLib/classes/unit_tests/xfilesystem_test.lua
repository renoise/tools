do

  require (xLib_dir.."xFilesystem")

  local absolute_path = renoise.tool().bundle_path .. "/xfilesystem_test/"
  local relative_path = "./xfilesystem_test/"

  local function clean_temp_files()
    print(xFilesystem.rmdir("./xfilesystem_test/"))
  end

  -- initialize

  clean_temp_files()

  if io.exists(relative_path) then
    error("Cannot run this unit-test - a folder already exists at this location: "..relative_path.." (please remove it manually and try again)" )
    return
  end

  os.mkdir(relative_path)

  ---------------------------------------------------------

  print(">>> xFilesystem: starting unit-test...")

  -- @ xFilesystem.get_path_parts 
  
	local folder,filename,extension = xFilesystem.get_path_parts("C:\\Root Folder\\SubFolder\\file with.extension")
  assert(folder == "C:\\Root Folder\\SubFolder\\")
  assert(filename == "file with.extension")
  assert(extension == "extension")

	local folder,filename,extension = xFilesystem.get_path_parts(".\\Root Folder\\SubFolder\\file without extension")
  assert(folder == ".\\Root Folder\\SubFolder\\")
  assert(filename == "file without extension")
  assert(extension == nil)

	local folder,filename,extension = xFilesystem.get_path_parts(".\\Root Folder\\SubFolder\\")
  assert(folder == ".\\Root Folder\\SubFolder\\")
  assert(filename == nil)
  assert(extension == nil)

	local folder,filename,extension = xFilesystem.get_path_parts("/root folder/subfolder/file without extension")
  assert(folder == "/root folder/subfolder/")
  assert(filename == "file without extension")
  assert(extension == nil)

	local folder,filename,extension = xFilesystem.get_path_parts("./root folder/subfolder/file with.extension")
  assert(folder == "./root folder/subfolder/")
  assert(filename == "file with.extension")
  assert(extension == "extension")

	local folder,filename,extension = xFilesystem.get_path_parts("./root folder/subfolder/")
  assert(folder == "./root folder/subfolder/")
  assert(filename == nil)
  assert(extension == nil)


  -- @ xFilesystem.get_parent_directory 

  local parent_folder = xFilesystem.get_parent_directory("C:\\Root Folder\\SubFolder\\file with.extension")
  assert(parent_folder == "C:/Root Folder/",parent_folder)
  parent_folder = xFilesystem.get_parent_directory(parent_folder)
  assert(parent_folder == "C:/")
  parent_folder = xFilesystem.get_parent_directory(parent_folder)
  print(parent_folder)
  assert(parent_folder == "C:/")

  local parent_folder = xFilesystem.get_parent_directory(".\\Root Folder\\SubFolder\\file without extension")
  assert(parent_folder == "./Root Folder/")
  parent_folder = xFilesystem.get_parent_directory(parent_folder)
  assert(parent_folder == "./")

  local parent_folder = xFilesystem.get_parent_directory("/root folder/subfolder/file without extension")
  assert(parent_folder == "/root folder/")
  parent_folder = xFilesystem.get_parent_directory(parent_folder)
  assert(parent_folder == "/")

  local parent_folder = xFilesystem.get_parent_directory("./root folder/subfolder/file with.extension")
  assert(parent_folder == "./root folder/",parent_folder)
  parent_folder = xFilesystem.get_parent_directory(parent_folder)
  assert(parent_folder == "./")


  -- @ xFilesystem.get_raw_filename

  assert(xFilesystem.get_raw_filename("C:\\Root Folder\\SubFolder\\file with.extension") == "file with")
  assert(xFilesystem.get_raw_filename("C:\\Root Folder\\SubFolder\\file without extension") == "file without extension")
  assert(xFilesystem.get_raw_filename("C:\\Root Folder\\SubFolder\\") == nil)


  -- TODO validate_filename




  -- define a 'tricky' string 
  local str_test = [[This is a long string with linebreaks
And some special characters: ÆØÅ!"#¤%&/(
Will it be the same once loaded from disk?]]

  -- save to disk
  assert(xFilesystem.write_string_to_file(relative_path.."file",str_test))

  -- ensure_unique_filename (no extension)
  local unique_file_path_1 = xFilesystem.ensure_unique_filename(relative_path.."file")
  assert(unique_file_path_1 == relative_path.."file (1)",unique_file_path_1)

  -- save to disk (with extension)
  assert(xFilesystem.write_string_to_file(relative_path.."file.tmp",str_test))

  -- ensure_unique_filename
  local unique_file_path_1 = xFilesystem.ensure_unique_filename(relative_path.."file.tmp")
  assert(unique_file_path_1 == relative_path.."file (1).tmp",unique_file_path_1)

  -- save string as unique filename 
  assert(xFilesystem.write_string_to_file(unique_file_path_1,str_test))

  -- now load string and compare results
  local fhandle = io.open(unique_file_path_1)
  local str_test_result = fhandle:read("*a")
  fhandle:close()
  assert(str_test == str_test_result)

  -- repeat, but using the unique filename as basis
  -- the method should detect the (1) and use it as basis 
  local unique_file_path_2 = xFilesystem.ensure_unique_filename(unique_file_path_1)
  assert(unique_file_path_2 == relative_path.."file (2).tmp",unique_file_path_2)
  assert(xFilesystem.write_string_to_file(unique_file_path_2,str_test))


  -- @ xFilesystem.makedir 

  local deep_folder_path = relative_path.."one/two/three/"
  assert(xFilesystem.makedir(deep_folder_path))
  assert(io.exists(deep_folder_path))

  local abs_path = absolute_path .. "foo/bar/"
  assert(xFilesystem.makedir(abs_path))
  assert(io.exists(abs_path))


  -- @ xFilesystem.rename

  local old_path = relative_path .. "file.tmp"
  local new_path = relative_path .. "renamed_file.tmp"
  assert(xFilesystem.rename(old_path,new_path))
  assert(io.exists(new_path))

  local old_path = relative_path .. "renamed_file.tmp"
  local new_path = relative_path .. "one"
  assert(not xFilesystem.rename(old_path,new_path))

  local old_path = relative_path .. "renamed_file.tmp"
  local new_path = relative_path .. "one/renamed_again.tmp"
  assert(xFilesystem.rename(old_path,new_path))

  local old_path = relative_path .. "one/two" 
  local new_path = relative_path .. "one/twostep"
  assert(xFilesystem.rename(old_path,new_path))

  local old_path = relative_path .. "one/renamed_again.tmp"
  local new_path = absolute_path .. "renamed_file.tmp"
  assert(xFilesystem.rename(old_path,new_path))

  local old_path = absolute_path .. "renamed_file.tmp"
  local new_path = absolute_path .. "foo"
  assert(not xFilesystem.rename(old_path,new_path))

  local old_path = absolute_path .. "renamed_file.tmp"
  local new_path = absolute_path .. "foo/bar/renamed_again.tmp"
  assert(xFilesystem.rename(old_path,new_path))

  local old_path = absolute_path .. "foo/bar"
  local new_path = absolute_path .. "foo/baz"
  assert(xFilesystem.rename(old_path,new_path))

  local old_path = absolute_path .. "foo"
  local new_path = absolute_path .. "foo/bar"
  assert(not xFilesystem.rename(old_path,new_path))

  local old_path = absolute_path .. "foo/baz"
  local new_path = absolute_path .. "baz"
  assert(xFilesystem.rename(old_path,new_path))

  local old_path = absolute_path .. "baz"
  local new_path = absolute_path .. "file"
  assert(not xFilesystem.rename(old_path,new_path))



  -- finish -----------------------------------------------

  clean_temp_files()


  print(">>> xFilesystem: OK - passed all tests")

end