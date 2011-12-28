-------------------------------------------------------------------------------
--  Description
-------------------------------------------------------------------------------

-- This HTTP library offers jQuery Ajax-like functions for web requests.
-- It's built on top of Renoise's internal Socket API.

-- Author: bantai [marvin@renoise.com]


-------------------------------------------------------------------------------
--  Dependencies
-------------------------------------------------------------------------------

-- The HTTP functions below are built on top of the Request class.
require "renoise.http.request"


-------------------------------------------------------------------------------
--  Public functions
-------------------------------------------------------------------------------

class "HTTP"

---## http ##---
--- Perform an asynchronous HTTP (Ajax) request.
function HTTP:request(url, method, data, success, data_type)
  if (type(data) == "function") then    
    success = data
    data = nil
  elseif (type(data) == "string") then
    data_type = data
    data = nil
    success = nil
  elseif (type(success) == "string") then
    data_type = success
    success = nil 
  end
    
  local settings = {
    url=url,
    method=method,
    data=data,
    success=success,
    data_type=data_type
  }

  local new_request = Request(settings)
end


---## post ##---
-- Return data from the server using a HTTP POST request.
-- post( url, [ data ], [ success(data, textStatus, XMLHttpRequest) ], [ data_type ] )
function HTTP:post(url, data, success, data_type)
  HTTP:request(url, Request.POST, data, success, data_type)
end


---## get ##---
-- Return data from the server using a HTTP GET request.
-- get( url, [ data ], [ success(data, textStatus, XMLHttpRequest) ], [ data_type ] )
function HTTP:get(url, data, success, data_type)
  HTTP:request(url, Request.GET, data, success, data_type)
end


---## http_download_file ##---
-- Download file at given URL into the default download folder.
-- The path to the file is given in the success callback.
-- TODO replace/integrate with callback
function HTTP:download_file(url, progress_callback, success, complete, error)    
  
  local new_request = Request(
    {
    url=url, 
    method=Request.GET, 
    save_file=true,
    default_download_folder=true,
    success=success,
    complete=complete,
    error=error,
    progress=progress_callback    
   })  
   
   return new_request

end
