--[[============================================================================
cDebug
============================================================================]]--

--[[--

Debug tracing & logging
.
#

Set one or more expressions to either show all or only a few messages 
from `TRACE` calls.

Some examples: 
     {".*"} -> show all traces
     {"^Display:"} " -> show traces, starting with "Display:" only
     {"^ControlMap:", "^Display:"} -> show "Display:" and "ControlMap:"

]]

--==============================================================================

--_trace_filters = {".*"}

require (_clibroot.."cFilesystem")

class 'cDebug'

--------------------------------------------------------------------------------

function cDebug.serialize(obj)
  local succeeded, result = pcall(tostring, obj)
  if succeeded then
    return result 
  else
   return "???"
  end
end

--------------------------------------------------------------------------------

function cDebug.concat_args(...)

  local result = ""

  -- concat args to a string
  local n = select('#', ...)
  for i = 1, n do
    local obj = select(i, ...)
    if( type(obj) == 'table') then
      result = result .. cDebug.rdump(obj)
    else
      result = result .. cDebug.serialize(select(i, ...))
      if (i ~= n) then 
        result = result .. "\t"
      end
    end
  end

  return result

end

--------------------------------------------------------------------------------

function cDebug.rdump(t, indent, done)

  local result = "\n"
  done = done or {}
  indent = indent or string.rep(' ', 2)
  
  local next_indent
  for key, value in pairs(t) do
    if (type(value) == 'table' and not done[value]) then
      done[value] = true
      next_indent = next_indent or (indent .. string.rep(' ', 2))
      result = result .. indent .. '[' .. cDebug.serialize(key) .. '] => table\n'
      cDebug.rdump(value, next_indent .. string.rep(' ', 2), done)
    else
      result = result .. indent .. '[' .. cDebug.serialize(key) .. '] => ' .. 
        cDebug.serialize(value) .. '\n'
    end
  end
  
  return result
end

--------------------------------------------------------------------------------
-- calling this will iterate through the entire tool and remove all TRACE
-- statements (for internal use only!!)

function cDebug.remove_trace_statements()

  local msg = "Remove all TRACE statements from source files?"
  local choice = renoise.app():show_prompt("Confirm",msg,{"OK","Cancel"})
  if (choice == "Cancel") then
    return 
  end

  local str_path = renoise.tool().bundle_path
  local file_ext = {"*.lua"}

  -- @return false to stop recursion
  local callback_fn = function(path,file,type)

    if (type == cFilesystem.FILETYPE.FILE) then
      local file_path = path .. "/"..file
      local str_text,err = cFilesystem.load_string(file_path)
      if not str_text then
        if err then
          renoise.app():show_warning(err)
        end
        return false
      end
      local str_new = string.gsub(str_text,"\n%s*TRACE([^\n]*","")
      local passed,err = cFilesystem.write_string_to_file(file_path,str_new)
      if not passed then
        if err then
          renoise.app():show_warning(err)
        end
        return false
      end

    end
  
    return true

  end

  cFilesystem.recurse(str_path,callback_fn,file_ext)

end

--==============================================================================
-- Global namespace
--==============================================================================

--- TRACE implementation, provide detailed, filtered output 
-- @param (vararg)

if (_trace_filters ~= nil) then
  
  function TRACE(...)

    local result = cDebug.concat_args(...)
  
    -- apply filter
    for _,filter in pairs(_trace_filters) do
      if result:find(filter) then
        print (result)
        break
      end
    end
  end
  
else

  function TRACE()
    -- do nothing
  end
    
end

