-------------------------------------------------------------------------------
--  UNZIP functions (Info-ZIP)
-------------------------------------------------------------------------------

-- Info-ZIP UnZip Error Code list:
-- http://www.info-zip.org/FAQ.html#error-codes  
local code = {}

code[0] =
[[Normal; no errors or warnings detected. (There may still be errors in the 
archive, but if so, they weren't particularly relevant to UnZip's processing
 and are presumably quite minor.)]]
   
code[1] = 
[[One or more warning errors were encountered, but processing completed 
successfully anyway. This includes zipfiles where one or more files was skipped 
due to unsupported compression method or encryption with an unknown password.]]

code[2] =  
[[A generic error in the zipfile format was detected. Processing may have 
completed successfully anyway; some broken zipfiles created by other archivers
have simple work-arounds.]]

code[3] = 
[[A severe error in the zipfile format was detected. Processing probably failed 
 immediately.]]

code[4] = 
[[UnZip was unable to allocate memory for one or more buffers during program
 initialization.]]

code[5] = 
[[UnZip was unable to allocate memory or unable to obtain a tty (terminal) to 
read the decryption password(s).]]

code[6] = 
[[UnZip was unable to allocate memory during decompression to disk.]]
  
code[7] = 
[[UnZip was unable to allocate memory during in-memory decompression.]]

code[9] =
[[The specified zipfile(s) was not found.]]

code[10] = 
[[Invalid options were specified on the command line.]]

code[11] =
[[No matching files were found.]]

code[50] = 
[[The disk is (or was) full during extraction.]]

code[51] =   
[[The end of the ZIP archive was encountered prematurely.]]

code[80] = 
[[The user aborted UnZip prematurely with control-C (or similar)]]

code[81] =
[[Testing or extraction of one or more files failed due to unsupported 
compression methods or unsupported decryption.]]

code[82] =  
[[No files were found due to bad decryption password(s). (If even one 
file is successfully processed, however, the exit status is 1.)]]

-- Unzips the file at the given path to the given destination.
-- Depends on Info-ZIP UnZip, which is included with Unix/Linux/MacOSX.
-- This Tool contains an UnZip executable for Windows.
function unzip(path, destination)
  local str = ("unzip %s -d %s"):format(path, destination)
  
  TRACE(str)
  
  local error_code = os.execute(str) 

  TRACE("UnZip: " .. (code[error_code] or 
    "Unknown error encountered while unzipping."))
    
  if (error_code ~= 0) then 
    return false, code[error_code]
  end
  return true
end
