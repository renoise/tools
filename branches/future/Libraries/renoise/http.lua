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
-- Load data from the server using a HTTP POST request.
-- post( url, [ data ], [ success(data, textStatus, XMLHttpRequest) ], [ data_type ] )
function HTTP:post(url, data, success, data_type)
  HTTP:request(url, Request.POST, data, success, data_type)
end


---## get ##---
-- Load data from the server using a HTTP GET request.
-- get( url, [ data ], [ success(data, textStatus, XMLHttpRequest) ], [ data_type ] )
function HTTP:get(url, data, success, data_type)
  HTTP:request(url, Request.GET, data, success, data_type)
end


---## http_download_file ##---
-- TODO replace/integrate with callback
function HTTP:download_file(url)
  local save_file = true
  local new_request = Request({url=url, method=Request.GET, file=save_file})
  local success, socket_error = new_request:read_header()

  if (success) then
    requests:insert(new_request)
  else
     log:info(("%s failed: %s."):format(url,
       (socket_error or "[unknown error]")))
  end
end