-------------------------------------------------------------------------------
--  ZIP functions (Info-ZIP)
-------------------------------------------------------------------------------

-- Info-ZIP Zip Error Code list:
-- http://www.info-zip.org/FAQ.html#error-codes
local code = {}

code[0] =
[[Normal; no errors or warnings detected.]]

code[2] =
[[The zipfile is either truncated or damaged in some way (e.g., bogus internal 
offsets) that makes it appear to be truncated.]]

code[3] =
[[The structure of the zipfile is invalid; for example, it may have been 
corrupted by a text-mode ("ASCII") transfer.]]

code[4] = 
[[Zip was unable to allocate sufficient memory to complete the command.]]

code[5] = 
[[Internal logic error. (This should never happen; it indicates a programming
 error of some sort.)]]

code[6] = 
[[ZipSplit was unable to create an archive of the specified size because the 
compressed size of a single included file is larger than the requested size. 
(Note that Zip and ZipSplit still do not support the creation of PKWARE-style 
multi-part archives.)]]
  
code[7] = 
[[The format of a zipfile comment was invalid.]]

code[8] = 
[[Testing (-T option) failed due to errors in the archive, insufficient memory
 to spawn UnZip, or inability to find UnZip.]]

code[9] =
[[Zip was interrupted by user (or superuser) action.]]

code[10] = 
[[Zip encountered an error creating or using a temporary file.]]

code[11] =
[[Reading or seeking (jumping) within an input file failed.]]

code[12] =
[[There was nothing for Zip to do (e.g., "zip foo.zip").]]

code[13] =
[[The zipfile was missing or empty (typically when updating or freshening).]]

code[14] =
[[Zip encountered an error writing to an output file (typically the archive);
 for example, the disk may be full.]]

code[15] =
[[Zip could not open an output file (typically the archive) for writing.]]

code[16] =
[[The command-line parameters were specified incorrectly.]]

code[18] =
[[Zip could not open a specified file for reading; either it doesn't exist or 
the user running Zip doesn't have permission to read it.]]


-- Zips the file at the given path to the given destination.
-- Depends on Info-ZIP Zip, which is included with Unix/Linux/MacOSX.
-- For Windows a Zip executable is required.
function zip(path, destination)
  local zip = "zip"
  if (os.platform()=="WINDOWS") then    
    zip = renoise.tool().bundle_path .. "\zip.exe"
  end
  
  -- Do input files exist?
  if (not io.exists(path)) then    
    return false, "Zip: The input path '".. path .."' does not exist."
  else 
    -- Empty zip file whether it exists or not
    TRACE("Zip: deleted contents, exit code " .. os.execute("zip -d " .. destination .. " *"))
  end
  local stat = io.stat(path)
  local str = ""  
  if (stat.type == "directory") then
    -- go to the folder and zip folder contents   
    str = ('cd "%s" && "%s" -r "%s" *'):format(path, zip, destination)    
  else 
    str = ('zip -j "%s" "%s"'):format(path, destination, path)
  end  
  
  TRACE(str)
  
  local error_code = os.execute(str)
  local err = (code[error_code] or 
    "Unknown exit code encountered: " .. error_code)

  TRACE("Zip: " .. err)
    
  if (error_code ~= 0) then 
    return false, err
  end
  return true
end


-- TRACE -----------

local DEBUG = true

function TRACE(obj)  
  if (not DEBUG) then 
    return
  end
  if (type(obj)=="table") then
    rprint(obj)
  else 
    print(obj)
  end
end
