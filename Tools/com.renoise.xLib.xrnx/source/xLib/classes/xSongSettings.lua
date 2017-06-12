--[[===============================================================================================
xSongSettings
===============================================================================================]]--

--[[--

Store and retrieve information in the song comments field

]]

class 'xSongSettings'

---------------------------------------------------------------------------------------------------
-- Output the current settings as a lua string in the song comments
-- @param arr (table)
-- @param token_start (string)
-- @param token_end (string)

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

  return true

end

---------------------------------------------------------------------------------------------------
-- Retrive and apply the locally stored settings
-- TODO deserialize using sandbox
-- @param token_start (string)
-- @param token_end (string)
-- @return table when settings were found
-- @return [string], error message when failed

function xSongSettings.retrieve(token_start,token_end)
  TRACE("xSongSettings.retrieve(token_start,token_end)",token_start,token_end)

  local err = nil
  local rslt = nil
  local str_eval = ""
  local found_start_token = false

  for _,v in ipairs(rns.comments) do
    if (v == token_start) then
      found_start_token = true
    elseif (v == token_end) then
      if not found_start_token then
        return nil,"Found end token before start token"
      else
        rslt,err = loadstring(str_eval)
        if err then
          local msg = string.format("xSongSettings: an error occurred when importing settings: %s",err)
          return nil, err
        end
        rslt = rslt()
        return rslt
      end
    end
    if found_start_token then
      str_eval = str_eval.."\n"..v    
    end 
  end

  return false,"Did not find end token"

end


---------------------------------------------------------------------------------------------------
-- Check if the song contains locally stored settings
-- @param token_start (string)
-- @param token_end (string)
-- @return boolean, true when settings were found 
-- @return [string], error message when failed

function xSongSettings.test(token_start,token_end)
  TRACE("xSongSettings.test(token_start,token_end)",token_start,token_end)

  local found_start_token = false

  for _,v in ipairs(rns.comments) do
    if (v == token_start) then
      found_start_token = true
    elseif (v == token_end) then
      if found_start_token then
        return true
      else
        return false,"Found end token before start token"
      end
    end

  end

  return false,"Did not find end token"

end

---------------------------------------------------------------------------------------------------
-- Clear locally stored settings if matched
-- @param token_start (string)
-- @param token_end (string)
-- @return boolean, true when cleared/passed without problems
-- @return [string], error message when failed

function xSongSettings.clear(token_start,token_end)
  TRACE("xSongSettings.clear(token_start,token_end)",token_start,token_end)

  local start_token_line_idx = nil
  local end_token_line_idx = nil

  for k,v in ipairs(rns.comments) do
    if (v == token_start) then
      start_token_line_idx = k
    elseif (v == token_end) then
      if start_token_line_idx then
        end_token_line_idx = k
        break
      else
        return false,"Found end token before start token"
      end
    end
  end

  --print("start_token_line_idx",start_token_line_idx)
  --print("end_token_line_idx",end_token_line_idx)

  if not start_token_line_idx or not end_token_line_idx then
    return true
  end

  local rslt = {}
  for k,v in ipairs(rns.comments) do
    if (k < start_token_line_idx) 
      or (k > end_token_line_idx)    
    then 
      table.insert(rslt,v)
    end
  end
  
  rns.comments = rslt

  return true

end

