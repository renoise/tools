-------------------------------------------------------------------------------
--  Description
-------------------------------------------------------------------------------

-- The Request class is the glue between the high-level HTTP functions and
-- the low-level Socket API functions. Loosely based on jQuery.

-- Author: bantai [marvin@renoise.com]


-------------------------------------------------------------------------------
--  Dependencies
-------------------------------------------------------------------------------

-- Logger
require "renoise.http.log"
local log = Log(Log.ALL)

-- General purpose utility functions
require "renoise.http.util"

-- JSON4Lua JSON Encoding and Decoding
require "renoise.http.json"

-- Requests pool
local requests_pool = table.create()


-------------------------------------------------------------------------------
-- Idle notifier/handler
-------------------------------------------------------------------------------

local read = nil

local function attach()
  renoise.tool().app_idle_observable:add_notifier(read)
end

local function detach()
  renoise.tool().app_idle_observable:remove_notifier(read)
end

-- Read a few bytes from every request
read = function()

  -- Loop through the Requests pool
  for k,request in ipairs(requests_pool) do
    if not (request.complete) then
      request.complete = not (request:read_content())
      requests_pool:remove(k)
    end
  end

  if (requests_pool:is_empty()) then
    detach()
  end

  return true
end


-------------------------------------------------------------------------------
--  Request class
-------------------------------------------------------------------------------

class "Request"

-- Definition of HTTP request methods
Request.GET = "GET"
Request.POST = "POST"
Request.HEAD = "HEAD"
Request.OPTIONS = "OPTIONS"

-- Definition of statuses
Request.TIMEOUT = "TIMEOUT"
Request.ERROR = "ERROR"
Request.NOTMODIFIED = "NOTMODIFIED"
Request.PARSERERROR = "PARSERERROR"


---## settings ##---
-- Default request options
Request.settings = {

  -- jQuery uses "type" instead of "method"
  -- The type of request to make ("POST" or "GET"), default is "GET". 
  -- TODO Other HTTP request methods, such as PUT and DELETE, can also be used 
  -- here, but they are not supported by all browsers.
  method = Request.GET,

  -- A string containing the URL to which the request is sent.
  url = "",

  -- When sending data to the server, use this content-type. Default is
  -- "application/x-www-form-urlencoded", which is fine for most cases. If you
  -- explicitly pass in a content-type then it'll always be sent to the server 
  -- (even if no data is sent).
  content_type = "application/x-www-form-urlencoded",

  -- TODO By default, all requests are sent asynchronous. If you need 
  -- synchronous requests, set this option to false.
  async = true,

  -- TODO Set a local timeout (in milliseconds) for the request.
  timeout = 0,

  -- Default: Intelligent Guess (xml, json, script, or html)
  -- The type of data that you're expecting back from the server. If none is 
  -- specified, we will intelligently try to get the results, based on the 
  -- MIME type of the response.
  -- -- "text": A plain text string.
  -- -- "json": Evaluates the response as JSON and returns a Lua table. Any
  -- --         malformed JSON is rejected and a parse error is thrown.
  -- --         (See json.org for more information on proper JSON formatting.)
  -- -- TODO "xml": Returns a XML document parsed into a Lua table/object.
  -- -- TODO "html": Returns HTML as plain text; included script tags are
  -- --              evaluated when inserted in the DOM.
  -- -- TODO "script": Evaluates the response as Lua and returns it as plain
  -- --                text. Disables caching unless option "cache" is used.
  -- --                Note: This will turn POSTs into GETs for remote-domain
  -- --                requests.
  -- -- TODO "jsonp": Loads in a JSON block using JSONP. Will add an extra
  -- --               "?callback=?" to the end of your URL to specify the 
  -- --               callback.
  data_type = "text",

  -- Set this to true if you wish to use the traditional style of param 
  -- serialization.
  -- Traditional: ?a=1&a=2&a=3 which in PHP or Rails will result in $a = "3",
  --  while returning an array in JSP or Perl.
  -- Not traditional: ?a[]=1&a[]=2&a=3 which in PHP or Rails will result in
  --  $a = ["1","2","3"], but involves more parsing in JSP or Perl.
  -- See: http://benalman.com/news/2009/12/jquery-14-param-demystified/
  traditional = false,

  -- TODO Allow the request to be successful only if the response has changed 
  -- since the last request. This is done by checking the Last-Modified header. 
  -- Default value is false, ignoring the header. This technique also checks
  --  the 'etag' specified by the server to cache unmodified data.
  if_modified = false,

  -- Data to be sent to the server. It is converted to a query string, if not
  --  already a string. It's appended to the url for GET-requests.
  -- Object must be Key/Value pairs. If value is an Array, we serialize
  -- multiple values with same key based on the value of the traditional setting.
  data = table.create(),

  -- TODO If set to false it will force the pages that you request to not be
  -- cached by the browser.
  cache = true,

  -- TODO A username to be used in response to an HTTP access authentication
  -- request.
  username = nil,

  -- TODO A password to be used in response to an HTTP access authentication request.
  password = nil,

  -- A function to be called if the request succeeds. The function gets passed
  --  three arguments: The data returned from the server, formatted according 
  -- to the 'data_type' parameter; a string describing the status; and the 
  -- XMLHttpRequest object. This is an Ajax Event.
  -- TODO return a xml_http_request according to standards
  success = function(data, text_status, xml_http_request) end,

  -- TODO A function to be called if the request fails. The function is passed
  -- three arguments: The XMLHttpRequest object, a string describing the type
  -- of error that occurred and an optional exception object, if one occurred.
  --  Possible values for the second argument (besides null) are "timeout",
  -- "error", "notmodified" and "parsererror". This is an Ajax Event.
  error = function(xml_http_request, text_status, error_thrown)
   logger:error(error_thrown)
  end,

  -- TODO A function to be called when the request finishes (after success and
  -- error callbacks are executed). The function gets passed two arguments: 
  -- The XMLHttpRequest object and a string describing the status of the 
  -- request. This is an Ajax Event.
  complete = function(xml_http_request, text_status) end
}


---## setup ##---
-- Set default values for future Ajax requests.
-- For details on the settings available for Request:setup(), 
-- see Request.settings.
function Request:setup(options)
  for k,v in pairs(options) do
    Request.settings[k] = v;
  end
end


---## __init ##---
--  A set of key/value pairs that configure the request. All options are 
-- optional. A default can be set for any option with Request:setup().
function Request:__init(settings)
  settings = settings or table.create()

  -- User specified options override default options
  for k,v in pairs(settings) do
    self.settings[k] = v;
  end

  -- SocketClient object
  self.client_socket = nil

  -- Raw table that receives the data
  self.contents = table.create {}

  -- Content length
  self.length = 0

  -- Connection status
  self.complete = false

  -- Name/Value pairs to construct the header
  self.header_map = table.create {}

  -- Query string converted from the supplied parameters
  self.query_string = Request:create_query_string(self.settings.data)

  -- Possible values for the request status besides nil are
  -- "TIMEOUT", "ERROR", "NOTMODIFIED" and "PARSERERROR".
  self.text_status = nil

  -- Build the URL based on request method
  self.url = self.settings.url
  self.url_parts = URL:parse(self.url)

  if (self.settings.method == Request.GET) then
    if (not self.url_parts.query) then
      self.url = self.url .. "?" .. self.query_string
    else
      self.url = self.url .. "&" .. self.query_string
    end
  elseif (self.settings.method == Request.POST) then
    self.query_string = self.query_string:gsub("%%20", "+")
  end
  
  self:enqueue()
end


---## enqueue ##---
-- Retrieves the header from the server and 
-- schedules the request for further download
function Request:enqueue()
  local success, socket_error = self:read_header()
  if (success) then
    requests_pool:insert(self)
    if (#requests_pool == 1) then
       attach()
    end
  else
    self.text_status = Request.ERROR
    log:error(("%s failed: %s."):format(url,
      (socket_error or "[unknown error]")))
  end
end


---## set_header ##---
-- Inserts or overrides a name/value pair in the header map
function Request:set_header(name, value)
  self.header_map[name] = value
end


---## create_query_string ##---
-- Converts a parameter data table into a query string
function Request:create_query_string(data)
  local str = ""
  for k,v in pairs(data) do
    str = str .. "&" .. k .. "=" .. v
  end
  return Util:html_entity_encode(str:sub(2))
end


---## read_header ##---
-- Sets up a connection and loads the HTTP header from the server
function Request:read_header()

  local socket_error = nil

  -- Create a SocketClient object and connect with the server
  self.client_socket, socket_error = renoise.Socket.create_client(
    self.url_parts.host, self.url_parts.port or 80, renoise.Socket.PROTOCOL_TCP)
  
  if not (self.client_socket) then
     return false, socket_error
  end
  
  
  -- Determine Content-Length. With GET requests the body is empty. 
  -- With POST requests the body consists of the parameters.
  local content_length = 0
  if (self.settings.method == Request.POST) then
    content_length = #self.query_string
  end

  -- Setup the header
  local header = string.format("%s %s HTTP/1.1\r\n", self.settings.method, self.url)
  self:set_header("Host", self.url_parts.host)
  self:set_header("Content-Type", self.settings.content_type)
  self:set_header("Content-Length", content_length)
  self:set_header("Connection", "keep-alive")
  self:set_header("User-Agent",
    string.format( "Renoise %s (%s)", 
    renoise.RENOISE_VERSION, os.platform():lower() )
  )

  -- Construct the HTTP request header
  for k,v in pairs(self.header_map) do
    header = string.format("%s%s: %s\r\n",header,k,v)
  end
  header = header .. "\r\n" -- mandatory empty line

  log:info("=== REQUEST HEADERS ===\n" .. header)

  -- Send the header
  local ok, socket_error = self.client_socket:send(header)
  if not (ok) then
    return false, socket_error
  end

  -- Send the POST parameters in the request body, if applicable
  if (self.settings.method == Request.POST) then
    ok, socket_error = self.client_socket:send(self.query_string)
    if not (ok) then
      return false, socket_error
    end
  end

  -- Read the response header
  local header_lines = table.create {}

  while true do
    local line = self.client_socket:receive("*l", 1000)
    if (not line) then
      break -- unexpected EOF
    end

    if (line == "") then
      break -- header ends with an empty line
    end

    header_lines:insert(line)
  end

  log:info(("=== HEADER (%s) ==="):format(self.url))
  rprint(header_lines)
  print("\n")

  self.response_header = Util:parse_message(header_lines:concat("\n"))

  if (self.response_header) then
    -- TODO check content-length and HTTP status code
    return true
  else
    return false, "Invalid page header"
  end
end


---## read_content ##---
-- Loads the response from the server
function Request:read_content()
  assert(self.client_socket and self.response_header,
    "read_header failed or was not called")
  
  -- read all pending data
  local timeout = 0
  
  local buffer, socket_error = 
    self.client_socket:receive("*all", timeout)
  
  if (buffer) then
  -- got new data
    self.contents:insert(buffer)
    self.length = self.length + #buffer

    -- log
    if (self.length > 10 * 1024) then
      log:info(string.format("%d kbytes read (%s)", 
        self.length / 1024, self.url))
    else
      log:info(string.format("%d bytes read (%s)", 
        self.length, self.url))
    end
    
    if (self.length >= tonumber(self.response_header["Content-Length"])) then
      -- done
      self:do_callback()
      return false
    else
      -- continue reading
      return true
    end
    
  else
  -- timeout or error
    
    if (socket_error == "timeout") then
      -- retry next time (TODO: give up at soume point)
      log:info(string.format("read timeout (%s)", self.url))
      return true
    else
      -- cancel request
      self:do_callback(socket_error)
      return false
    end
  end
end


---## do_callback ##---
-- Finalizes the transaction and executes the optional callback functions
function Request:do_callback(socket_error)

  -- Print a small amount of received data in the terminal
  log:info(("=== CONTENT (%d bytes from %s) ==="):format(
    self.length, self.url))
  if (self.length <= 32 * 1024) then
    rprint(self.contents)
  else
    print(" *** too much content to display (> 32 kbytes) *** ")
  end

  if (socket_error) then
    log:info(("%s failed with error: '%s'."):format(self.url, socket_error))
  else
    log:info(("%s has completed."):format(self.url))

    --[[ TODO Save files directly on disk
    if (self.save_downloaded_file) then
      local _, _, filename, extension = self.url:find(".+[/\\](.+)%.(.+)$")
      assert(filename and extension, "failed to extract the filename")

      local file_name_and_path = renoise.app():prompt_for_filename_to_write(
        extension, ("Save %s.%s as"):format(filename, extension))

      if (file_name_and_path and file_name_and_path ~= "") then
        local file = io.open(file_name_and_path, "wb")

        if (file) then
          for _,buffer in pairs(self.contents) do
            file:write(buffer)
          end
          file:close()
        else
          log:info(("failed to open '%s' for writing."):format(
            file_name_and_path))
        end
      end
    end
    --]]
  end
  
  -- close the connection and invalidate
  self.client_socket = nil
  self.response_header = nil
  
  -- TODO process more data_types
  local data = self.contents
  local data_type = self.settings.data_type:lower()
  if (data_type == "json") then
    log:info("Decoding JSON")
    data = json.decode(data:concat())
  elseif (data_type == "osc") then
  elseif (data_type == "lua_array") then
  elseif (data_type == "xml") then
    -- parse XML into table
  elseif (data_type == "lua") then
    -- evaluate Lua
  elseif (data_type == "html") then
    -- parse HTML to text+layout
  end
  
  local xml_http_request = self;

  -- invoke the external callbacks (if set)
  if (socket_error) then
    self.settings.error( xml_http_request, self.text_status, socket_error)
  else
    self.settings.success( data, self.text_status, xml_http_request )
  end

  self.settings.complete( xml_http_request, self.text_status )

end