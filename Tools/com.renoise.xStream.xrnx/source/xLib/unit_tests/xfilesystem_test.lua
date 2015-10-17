function xfilesystem_test()

  local unique_folder = "./xfilesystem_test/"
  local unique_file_path = unique_folder.."file.tmp"

  local function clean_temp_files()
    print(xFilesystem.rmdir("./xfilesystem_test/"))
  end

  -- initialize

  clean_temp_files()

  if io.exists(unique_folder) then
    error("Cannot run this unit-test - a folder already exists at this location: "..unique_folder.." (please remove it manually and try again)" )
    return
  end

  os.mkdir(unique_folder)


  print("xFilesystem: starting unit-test...")

  -- get_path_parts --
  
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

  -- get_parent_directory 

  local parent_folder = xFilesystem.get_parent_directory("C:\\Root Folder\\SubFolder\\file with.extension")
  assert(parent_folder == "C:/Root Folder/",parent_folder)
  parent_folder = xFilesystem.get_parent_directory(parent_folder)
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

  -- get_raw_filename

  assert(xFilesystem.get_raw_filename("C:\\Root Folder\\SubFolder\\file with.extension") == "file with")
  assert(xFilesystem.get_raw_filename("C:\\Root Folder\\SubFolder\\file without extension") == "file without extension")
  assert(xFilesystem.get_raw_filename("C:\\Root Folder\\SubFolder\\") == nil)


  -- TODO validate_filename




  -- define a 'tricky' string 
  local str_test = [[This is a long string with linebreaks
And some special characters: ∆ÿ≈!"#§%&/(
Will it be the same once loaded from disk?]]

  -- save to disk
  assert(xFilesystem.write_string_to_file(unique_folder.."file",str_test))

  -- ensure_unique_filename (no extension)
  local unique_file_path_1 = xFilesystem.ensure_unique_filename(unique_folder.."file")
  assert(unique_file_path_1 == unique_folder.."file (1)",unique_file_path_1)

  -- save to disk (with extension)
  assert(xFilesystem.write_string_to_file(unique_folder.."file.tmp",str_test))

  -- ensure_unique_filename
  local unique_file_path_1 = xFilesystem.ensure_unique_filename(unique_file_path)
  assert(unique_file_path_1 == unique_folder.."file (1).tmp",unique_file_path_1)

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
  assert(unique_file_path_2 == unique_folder.."file (2).tmp",unique_file_path_2)

  assert(xFilesystem.write_string_to_file(unique_file_path_2,str_test))

  -- create deep folder structure

  local deep_folder_path = unique_folder.."one/two/three/"

  assert(xFilesystem.makedir(deep_folder_path))
  assert(io.exists(deep_folder_path))


  clean_temp_files()


  print("xFilesystem: OK - passed all tests")

end