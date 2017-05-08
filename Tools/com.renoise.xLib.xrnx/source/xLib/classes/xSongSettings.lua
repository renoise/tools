--[[===============================================================================================
xSongSettings
===============================================================================================]]--

--[[--

Saves information in the song comments field

]]

class 'xSongSettings'

--------------------------------------------------------------------------------

--- Output the current settings as a lua string in the song comments

function xSongSettings.store(arr,token_start,token_end)
  TRACE("xSongSettings.store(arr,token_start,token_end)",arr,token_start,token_end)

  local rslt = table.create()

  -- read the "foreign" parts of the song comment
  local capture_line = true
  for _,v in ipairs(rns.comments) do
    if (v == token_start) then
      capture_line = false
    end
    if capture_line then
      rslt:insert(v)
    end 
    if (v == token_end) then
      capture_line = true
    end
  end

  -- serialize table and insert at the end
  local depth = 10
  local longstring = true
  local str_table = cLib.serialize_table(arr,depth,longstring)
  local lines = cString.split(str_table,"\n")

  rslt:insert(token_start)
  for k,v in ipairs(lines) do
    if (k == 1) then 
      -- the table needs to be prefixed with a return statement,
      -- or the table will evaluate to nothing...
      v = "return "..v
    end
    rslt:insert(v)
  end
  rslt:insert(token_end)

  rns.comments = rslt

end

--------------------------------------------------------------------------------
-- Retrive and apply the locally stored settings
-- TODO deserialize using sandbox
-- @return table or nil, [string, error message]

function xSongSettings.retrieve(token_start,token_end)
  TRACE("xSongSettings.retrieve(token_start,token_end)",token_start,token_end)

  local err = nil
  local rslt = nil
  local str_eval = ""
  local capture_line = false

  for _,v in ipairs(rns.comments) do
    if (v == token_start) then
      capture_line = true
    elseif (v == token_end) then
      rslt,err = loadstring(str_eval)
      if err then
        local msg = string.format("xSongSettings: an error occurred when importing settings: %s",err)
        return nil, err
      end
      rslt = rslt()
      return rslt
    end
    if capture_line then
      str_eval = str_eval.."\n"..v    
    end 
  end

end


