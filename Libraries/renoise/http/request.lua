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

-- General purpose utility functions
require "renoise.http.util"

-- JSON4Lua JSON Encoding and Decoding
require "renoise.http.json"

-- XML codec
require "renoise.http.xml_parser"
require "renoise.http.xml_encoder"

require "renoise.http.progress"


-------------------------------------------------------------------------------
--  Debugging
-------------------------------------------------------------------------------

-- Filter debug and error messages by severity
-- ALL / INFO / WARN / ERROR / FATAL / OFF
local log = Log(Log.ERROR)


-------------------------------------------------------------------------------
-- Idle notifier/handler
-------------------------------------------------------------------------------

-- Requests pool
local requests_pool = table.create()

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
    
    -- Paused  
    if (request.paused and request.progress.status ~= Progress.PAUSED) then            
      request.progress:_set_status(Progress.PAUSED)            
      log:info("Request paused.")
      -- stop polling when the only request is paused
      if (#requests_pool == 1) then
        detach()
      end            
    
    -- Cancelled  
    elseif (request.cancelled) then          
      requests_pool:remove(k)
      log:info("Request cancelled, removed from pool.")      
    
    -- Timeout
    elseif (request.text_status == Request.TIMEOUT and request.wait > 0) then      
      request.wait = request.wait - 1   
      
    -- Busy  
    elseif not (request.complete) then          
      request.complete = not (request:_read_content())  
      
    -- Complete
    else 
      log:info("Request complete, removed from pool.")
      requests_pool:remove(k)
    end
  end

  if (requests_pool:is_empty()) then
    detach()
  end

  return true
end


-- Get Scripts Dir
local function get_appdata_dir()    
  local dir = renoise.tool().bundle_path  
  local a,z
  if (os.platform() == "LINUX") then
    a,z = dir:find(".renoise")
  else
    a,z = dir:find("Renoise")
  end
  return dir:sub(1,z+1)
end


-------------------------------------------------------------------------------
--  Request class (PUBLIC)
-------------------------------------------------------------------------------

class "Request"

-- Library version
Request.VERSION = "100507"

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
Request.CANCELERROR = "CANCELERROR"


---## settings ##---
-- Default request options
Request.default_settings = table.create{

  -- jQuery uses "type" instead of "method"
  -- The type of request to make ("POST" or "GET"), default is "GET". 
  -- TODO Other HTTP request methods, such as PUT and DELETE, can also be used 
  -- here, but they are not supported by all browsers.
  method = Request.GET,

  -- A string containing the URL to which the request is sent.
  url = "",
   
  default_parts = {
    scheme = "http",    
    path = "/"
  },
  
  -- Enable to save files to disk by default
  save_file = false,
  
  default_download_folder = get_appdata_dir() .."Downloads",

  -- When sending data to the server, use this content-type. Default is
  -- "application/x-www-form-urlencoded", which is fine for most cases. If you
  -- explicitly pass in a content-type then it'll always be sent to the server 
  -- (even if no data is sent).
  content_type = "application/x-www-form-urlencoded",

  -- TODO By default, all requests are sent asynchronous. If you need 
  -- synchronous requests, set this option to false.
  async = true,

  -- Set a local timeout (in milliseconds) for the request of the header.
  header_timeout = 10000, 
  
  -- Set a local timeout (in milliseconds) for the request of the body.
  timeout = 0, -- 0 means: until connection is closed
  
  -- Maximum number of automatic request retries.
  max_retries = 30,
  
  -- Read cycles to wait between retries
  wait = 0, 

  -- Default: "text"
  -- The type of data that you're expecting back from the server. If none is 
  -- specified, we will intelligently try to get the results, based on the 
  -- MIME type of the response.
  -- -- "text": A plain text string.
  -- -- "lua_table": Expects data wrapped in a Lua table. The received
  -- --              data can be used directly without having to parse.
  -- -- "json": Evaluates the response as JSON and returns a Lua table. Any
  -- --         malformed JSON is rejected and a parse error is thrown.
  -- --         (See json.org for more information on proper JSON formatting.)
  -- -- TODO "xml": Returns a XML document parsed into a Lua table/object.
  -- -- TODO "html": Returns HTML as plain text; included script tags are
  -- --              evaluated when inserted in the DOM.
  -- -- TODO "lua_script": Evaluates the response as Lua and returns it as plain
  -- --                text. Disables caching unless option "cache" is used.
  -- --                Note: This will turn POSTs into GETs for remote-domain
  -- --                requests.
  -- -- TODO "jsonp": Loads in a JSON block using JSONP. Will add an extra
  -- --               "?callback=?" to the end of your URL to specify the 
  -- --               callback.
  -- -- TODO "binary": Automatically set when downloading files.
  -- --           Returns the path to the downloaded file.
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
  data = table.create{},

  -- TODO If set to false it will force the pages that you request to not be
  -- cached by the browser.
  cache = true,
  
  -- Cache size in KB
  max_cache_size = 5000,

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
    log:error(error_thrown)
  end,

  -- TODO A function to be called when the request finishes (after success and
  -- error callbacks are executed). The function gets passed two arguments: 
  -- The XMLHttpRequest object and a string describing the status of the 
  -- request. This is an Ajax Event.
  complete = function(xml_http_request, text_status) end,
  
  -- A function to be called whenever the download progress changes.  
  progress = function(progress_obj) 
    log:info(progress_obj.bytes .. " bytes received.")
  end
}


---## setup ##---
-- Set default values for future Ajax requests.
-- For details on the settings available for Request:setup(), 
-- see Request.default_settings.
function Request:setup(options)
  for k,v in pairs(options) do
    Request.default_settings[k] = v;
  end
end


---## __init ##---
--  A set of key/value pairs that configure the request. All options are 
-- optional. A default can be set for any option with Request:setup().
function Request:__init(custom_settings)  
  print("\n")
  log:info(">>> NEW REQUEST <<<")  
  
  custom_settings = custom_settings or table.create()
  
  -- First make a clone of the default settings
  self.settings = Request.default_settings:rcopy()
  
  -- User specified options override default options
  for k,v in pairs(custom_settings) do
    self.settings[k] = v;
  end
  
  -- Force uppercase on some settings
  self.settings.method = self.settings.method:upper()
  self.settings.data_type = self.settings.data_type:upper()  
  
  -- Force lowercase on some other settings
  self.settings.content_type = self.settings.content_type:lower()

  -- SocketClient object
  self.client_socket = nil

  --  table that receives the data
  self.contents = table.create()
  
  -- Table to store response info in 
  self.response = table.create()

  -- Content length
  self.length = 0
  
  -- Cache 
  self.cache = table.create()
  
  -- Cache size
  self.cache_len = 0
  
  -- Retried timeouts 
  self.retries = 0
  
  -- Number of redirects
  self.redirects = 0

  -- Connection status
  self.complete = false
  
  self.paused = false
  
  self.cancelled = false

  -- Name/Value pairs to construct the header
  self.header_map = table.create()
  
  -- Chunk variables
  self.chunk_size = 0
  self.chunk_remaining = 0
  self.chunks=table.create()
  self.chunk=""

  -- enctype="multipart/form-data"
  if (self.settings.content_type:find("multipart/mixed")) then
    self:_set_payload( self:_create_multipart_message(self.settings.data))
  elseif (self.settings.content_type:find("application/json")) then
    self:_set_payload(self:_create_json_message(self.settings.data))
  elseif (self.settings.content_type:find("application/xml")) then
    self:_set_payload(self:_create_xml_message(self.settings.data))    
  else -- Query string converted from the supplied parameters     
    self:_set_payload(self:_create_query_string(self.settings.data))
  end    

  -- Possible values for the request status besides nil are
  -- "TIMEOUT", "ERROR", "NOTMODIFIED", "PARSERERROR", "CANCELERROR".
  self.text_status = nil   

  -- Build the URL based on request method  
  self.url = Util:trim(self.settings.url)
  self.url_parts = URL:parse(self.url, self.settings.default_parts)  

  if (not table.is_empty(self.settings.data)) then
    if (self.settings.method == Request.GET) then
      if (not self.url_parts.query) then
        self.url = self.url .. "?" .. self:_get_payload()
      else
        self.url = self.url .. "&" .. self:_get_payload()
      end
    elseif (self.settings.method == Request.POST) then
      -- convert space entities
      self:_set_payload(self:_get_payload():gsub("%%20", "+"))
    end
  end
  
  self.progress = Progress(self.url, self.settings.progress)  
  
  if (not self.url_parts or not self.url_parts.host 
    or self.url_parts.host == "") then        
    self.text_status = Request.ERROR    
    self:_do_callback("Incorrect URL")
    return false
  end
  
  self:_enqueue()
end


---## get_downloaded_file ##---
-- Returns the path to the downloaded file, if any.
function Request:get_downloaded_file()
  return self.download_target
end


---## pause ##---
function Request:pause()
  if (not self.paused) then
    log:warn("Pausing request.")    
  end
  self.paused = true
end


---## resume ##---
function Request:resume()    
  local was_paused = self.paused
  if (was_paused) then
    log:warn("Resuming request.")    
  end
  self.paused = false  
  -- restart polling the requests pool 
  if (was_paused and #requests_pool == 1) then
    attach()
  end
end


---## cancel ##---
function Request:cancel()
  self.cancelled = true
  self:_do_callback("cancelled")      
  self.text_status = Request.CANCELERROR        
  self.progress:_set_status(Progress.CANCELLED)
  log:warn("Request cancelled by user.")  
end


-------------------------------------------------------------------------------
--  Request class (PRIVATE)
-------------------------------------------------------------------------------

---## enqueue ##---
-- Retrieves the header from the server and 
-- schedules the request for further download
function Request:_enqueue()
  local success, socket_error = self:_read_header()
  if (success) then
    requests_pool:insert(self)
    self.progress:_set_status(Progress.QUEUED)
    if (#requests_pool == 1) then
       attach()
    end
  else
    self.text_status = Request.ERROR
    log:error(("%s failed: %s."):format(self.url,
      (socket_error or "[unknown error]")))
    self:_do_callback(socket_error)  
  end
end


---## set_header ##---
-- Inserts or overrides a name/value pair in the [request] header map
function Request:_set_header(name, value)  
  self.header_map[name] = value  
end


---## get_header ##---
-- Returns the value of the specified [response] header
function Request:_get_header(name)      
  return self.response.header[name]
end


---## create_multipart_message ##---
-- Converts a parameter data table into a multipart message
function Request:_create_multipart_message(data)
  log:info("Create multipart message")
  log:info(data)

  local function get_random_string()
    local str = ""
    for i=1,4 do
      str = str .. math.random(1,9)
    end
    return str
  end

  local content_type = self.settings.content_type
  -- Content-Type: multipart/mixed; boundary=---------rnadom1234
  -- TODO enctype="multipart/form-data"
  local boundary = content_type:match("boundary=(.*)$") 
  if (not boundary) then
    boundary =  "---------rnadom" .. get_random_string()
    self:_set_header("Content-Type", 
      "multipart/mixed; boundary=" .. boundary)
  end  
  log:info("Multipart Boundary: " .. boundary)
  
  local msg = ""
  for k,v in pairs(data) do
    msg = ('Content-Disposition: form-data; name="%s"'):format(k)
    msg = msg .. "\r\n"
    msg = msg .. tostring(v)
  end
  return msg
end

---## create_json_message ##---
function Request:_create_json_message(data)
  log:info("Create JSON message")
  log:info(data)
  local ok, res = pcall(json.encode, data) 
  log:info(res)
  return res
end

---## create_xml_message ##---
function Request:_create_xml_message(data)
  log:info("Create XML message")
  log:info(data)
  local obj,err = XmlEncoder:encode_table(data)
  log:info(obj)
  return obj
end

---## create_query_string ##---
-- Converts a parameter data table into a query string
function Request:_get_status_code(string)
  local code = string:match(" (%d%d%d) ")
  if (code) then    
    return tonumber(code)    
  end
  -- when no status code could be found
  return 999 
end


---## create_query_string ##---
-- Converts a parameter data table into a query string
function Request:_create_query_string(data)
  if (not table.is_empty(data)) then
    log:info("Create query string: ")  
    log:info(data)  
  end
  return Util:http_build_query(data) 
end


---## set_payload ##---
-- specify the body of the request
function Request:_set_payload(data)
  self.payload = data
end


---## get_payload ##---
-- retrieve the body of the request
function Request:_get_payload()
  return self.payload
end


---## get_user_agent_string ##---
-- Generates a User-Agent string conforming to RFC 1945
function Request:_get_user_agent_string()
  local version = renoise.RENOISE_VERSION:gsub("%s", "")
  local os = os.platform():lower():gsub("^%l", string.upper)
  return string.format( "Renoise/%s (%s) HTTPLib/%s", version, os, Request.VERSION)   
end


---## read_header ##---
-- Sets up a connection and loads the HTTP header from the server
function Request:_read_header()
  
  local socket_error = nil
  
  -- Prevent infinite loop due to invalid redirect  
  if (self.redirects > 10) then
    return false, "Too many redirects detected."
  end
  self.redirects = self.redirects + 1 
  
  -- Reparse the URL, in case there's a redirect
  self.url_parts = URL:parse(self.url, self.settings.default_parts)
  
  if (not self.url_parts or not self.url_parts.host 
    or self.url_parts.host == "") then        
    self.text_status = Request.ERROR    
    --self:_do_callback("Incorrect URL")
    return false, "Incorrect URL"
  end
  
  -- Create a SocketClient object and connect with the server
  self.client_socket, socket_error = renoise.Socket.create_client(
    self.url_parts.host,  -- address
    tonumber(self.url_parts.port or 80), -- port
    renoise.Socket.PROTOCOL_TCP) -- protocol
  
  if not (self.client_socket) then
     return false, socket_error
  end  
  
  -- Determine Content-Length. With GET requests the body is empty. 
  -- With POST requests the body consists of a payload.
  local content_length = 0
  if (self.settings.method == Request.POST) then
    content_length = #self:_get_payload()
  end

  -- Setup the header
  local header = string.format("%s %s HTTP/1.1\r\n",
     self.settings.method, self.url_parts.path)
  self:_set_header("Host", self.url_parts.host) 
  self:_set_header("Content-Type", self.settings.content_type)  
  self:_set_header("Content-Length", content_length)  
  self:_set_header("Connection", "keep-alive")
  self:_set_header("User-Agent", self:_get_user_agent_string())

  -- Construct the HTTP request header
  for k,v in pairs(self.header_map) do
    header = string.format("%s%s: %s\r\n",header,k,v)
  end
  header = header .. "\r\n" -- mandatory empty line

  log:info(("=== REQUEST HEADERS (%s) ==="):format(self.url))
  log:info(header)

  -- Send the header
  local ok, socket_error = self.client_socket:send(header)
  if not (ok) then
    return false, socket_error
  end

  -- Send the POST parameters in the request body, if applicable
  if (self.settings.method == Request.POST) then
    log:info("=== POST DATA ===")
    log:info(self:_get_payload())
    ok, socket_error = self.client_socket:send(self:_get_payload())
    if not (ok) then
      return false, socket_error
    end
  end

  -- Read the response header
  local header_lines = table.create()

  while true do  
    local line, socket_error = self.client_socket:receive(
      "*l", self.settings.header_timeout)
      
    if (not line) then
      log:warn("Unexpected EOF while receiving header: "..socket_error)
      break -- unexpected EOF
    end

    if (line == "") then
      break -- header ends with an empty line
    end

    header_lines:insert(line)
  end

  log:info(("=== RESPONSE HEADER (%s) ==="):format(self.url))
  log:info(header_lines)
  log:info()
  
  self.response.header = Util:parse_message(header_lines:concat("\n"))  

  if (self.response.header and #self.response.header > 0) then
    -- TODO check content-length and HTTP status code  
    self.status_code = self:_get_status_code(self.response.header[1])
    if (self.status_code >= 400) then
      return false, ("HTTP Error: %s"):format(self.response.header[1])
    end
    
    -- File size
    self.response.content_length =
      tonumber(self.response.header["Content-Length"])
    self.progress.content_length = self.response.content_length
    
    self.response.transfer_encoding = 
      tostring(self.response.header["Transfer-Encoding"]):lower()
      
    -- Redirection
    if (self.response.header["Location"] and 
      #self.response.header["Location"] > 0
     -- and not self.response.header[1]:find("201") -- POST Created
    ) then      
      local location = self.response.header["Location"]                              
      log:info(("=== REDIRECTION TO (%s) ==="):format(location))
      local new_url_parts = URL:parse(location)            
      if (not new_url_parts.host) then        
        if (location:sub(1,1) ~= "/") then
          new_url_parts.path = "/"..location
        end
        -- Take care of a relative URL        
        new_url_parts.host = self.url_parts.host
        new_url_parts.scheme = self.url_parts.scheme        
        location = URL:build(new_url_parts)
      end
      self.url = location
      return self:_read_header()
    end
    return true
  else
    return false, "Time-out or invalid HTTP header"
  end
end


---## read_content ##---
-- Loads the response from the server
function Request:_read_content()  
  assert(self.client_socket and self.response.header,
    "read_header failed or was not called")
  
  self.progress:_set_status( Progress.BUSY )
  self.text_status = nil  
    
  local buffer, socket_error = 
    self.client_socket:receive("*all", self.settings.timeout)
  
  if (buffer) then
    -- We got a new buffer, so we reset the retry count
    self.retries = 0
        
    if (self.response.transfer_encoding == "chunked") then
      log:info("Unchunking buffer")
      self:_process_chunk(buffer)      
    else
      -- Store received new data
      self:_save_content(buffer)      
      self.length = self.length + #buffer    
    end 
        
    self.progress:_set_bytes(self.length)
            
    -- Display amount of data read
    if (self.length > 10 * 1024) then
      log:info(string.format("%d kbytes read (%s)", 
        self.length / 1024, self.url))
    else
      log:info(string.format("%d bytes read (%s)", 
        self.length, self.url))
    end
    
    -- Detect end of transmission
    if (self.length >= self.response.content_length
      and self.chunk_size == 0) then
      -- done
      --[[
      if (#self.chunks > 0) then
        self.contents = self.chunks
      end 
      --]]       
      self:_do_callback()
      return false
    else
      -- continue reading      
      return true
    end
    
  else
  -- timeout or error
    self.text_status = Request.TIMEOUT
    
    if (socket_error == "timeout" and 
      self.retries < self.settings.max_retries) then
      
      -- retry      
      self.retries = self.retries + 1
      
      --reset wait time
      self.wait = self.settings.wait
            
      log:warn(string.format("read timeout (%s); attempt (#%s)", 
        self.url, self.retries))
        
      return true
    else
      -- cancel request
      log:warn(socket_error)      
      self:_do_callback(socket_error)
      return false
    end
  end
end


---## process_chunk ##---
-- Unchunk a message stream. Chunked data is useful when the sender 
-- does not know the content-length beforehand, which is often the
-- case with dynamically generated data. A chunk can be split over
--  multiple buffers.
--
-- Example:
 -- Transfer-Encoding: chunked
 -- 
 -- 25
 -- This is the data in the first chunk
 -- 
 -- 1A
 -- and this is the second one
 -- 0
function Request:_process_chunk(buffer, same)
  -- new buffer
  if (not same) then
    log:info()  
    log:info("New buffer. Size: " .. #buffer .. " byte")    
    --Util:file_put_contents(self.settings.default_download_folder.."/raw.txt", buffer, "wb") 
     -- add buffer length to total message length
    self.length = self.length + #buffer     
    log:info("Total message size: " .. self.length .. " byte")
  end
  
  -- new chunk
  if (#self.chunk == 0) then      
    log:info()      
    log:info("New chunk")    
    
    if (self.temp_buffer) then
      buffer = self.temp_buffer .. buffer
      self.temp_buffer = nil
    end
    
    log:info("Remaining buffer: " .. #buffer .. " byte")             
    log:info(Util:bytes_to_string(buffer:sub(1,16)))
     
    -- Find the position of CRLF, eg. "[\r\n]2000 [extension]\r\n"
    -- ... at the beginning of the response, the first chunk
    local pattern = "^%x+.-\r\n"
    if (self.transfer_notstart) then
      -- ... at the start of each following chunk
      pattern = ("^\r\n%x+.-\r\n")      
    end
    self.transfer_notstart = true
    
    local chunk_header_start, chunk_boundary = buffer:find(pattern)
    
    if (not chunk_header_start) then
      log:info("Fragmented chunk header; prepend remaining buffer to next buffer")      
      self.temp_buffer = buffer
      return -- wait for new buffer
    end    
    
    log:info("Chunk header ends at: " .. tostring(chunk_boundary))

    
    assert(chunk_boundary > 1 and chunk_boundary < 50, "Incorrect chunk header")
    -- get the hex value, strip any CRLFs
    local chunk_header = buffer:sub(1, chunk_boundary)

--    local chunk_size_hex, chunk_extension = chunk_header:match("^(%x+)(.-)$")
    local chunk_size_hex = chunk_header:match("%x+")
    assert(chunk_size_hex, "Chunk size not found in header")
    
    -- convert to dec
    self.chunk_size = tonumber("0x"..chunk_size_hex)
    
    -- the whole chunk remains
    self.chunk_remaining = self.chunk_size
    
     -- The last chunk is a zero-length chunk, 
    -- with the chunk size coded as 0, but without any chunk data section.
    if (self.chunk_size == 0) then      
      log:info("Last chunk found, stopping.")
      self:_save_content("")
      return
    end    
    
    
    log:info("Chunk size: 0x" .. tostring(chunk_size_hex):upper()
      .. " (" .. self.chunk_size .. " byte)")          
    
          
    -- remove the chunk header from the buffer
    local chunk_start = chunk_boundary+1
    if (chunk_start) then
      chunk_start = chunk_start
      buffer = buffer:sub(chunk_start)                  
      log:info("Chunk starts at:" .. chunk_start)
    end 
  end      
     
  
  -- The chunk can be completed with this buffer
  if (#buffer >= self.chunk_remaining) then    
      
    -- append 1st part of the buffer to chunk    
    self.chunk=self.chunk..buffer:sub(1,self.chunk_remaining)
    
    -- save the chunk to disk or ram
    self:_save_content(self.chunk)
    --log:info(Util:bytes_to_string(self.chunk))
    log:info("Remaining data in this chunk: 0 (fully consumed)")
    
    -- remove the 1st part from the buffer
    buffer = buffer:sub(self.chunk_remaining+1)
    self.chunk = ""
    
    -- restart the process with the remaining buffer
    self:_process_chunk(buffer, true)   
    
  else 
    -- The chunk needs the next buffer
    
    -- append complete buffer to chunk
    self.chunk = self.chunk..buffer
    --log:info(Util:bytes_to_string(buffer:sub(-16)))    
    
    -- calculate how much data must be added to complete the chunk
    self.chunk_remaining = self.chunk_remaining - #buffer
    log:info("Remaining data in this chunk: " .. self.chunk_remaining)          
  end
end   


---## save_content ##---
function Request:_save_content(buffer)
  
  if (not self.settings.save_file) then
     self.contents:insert(buffer) 
  else     
    self.cache_len = self.cache_len + #buffer
    
    if (#buffer > 0) then
      self.cache:insert(buffer)
    end
    
    local cache_full = self.cache_len > 
      (self.settings.max_cache_size * 1024)
    
    -- write buffer when EOF or cache is full           
    if (#buffer == 0 or cache_full) then      
      self:_write_file(self.cache)
      self.cache:clear()       
      self.cache_len = 0      
    end       
  end
end


---## write_file ##---
function Request:_write_file(data)
    -- create tempfile
    if (not self.tempfile) then
      self.tempfile = os.tmpname()
      local err
      self.handle, err = io.open(self.tempfile, "wb")
    end
    log:info("Writing data to temporary file.")
    if (type(data)=="table") then
      data = table.concat(data)
    end
    if (io.type(self.handle) == "file") then
      self.handle:write(data)
    end
end


---## _get_ext_by_mime ##---
function Request:_get_ext_by_mime(type)
  if (type == "text/html") then
    return ".htm"
  elseif (type == "text/plain") then
    return ".txt"
  elseif (type == "application/xhtml+xml") then
    return ".xhtml"
  elseif (type == "application/xml") then
    return ".xml"  
  end
  
  return ""
end


---## do_callback ##---
-- Finalizes the transaction and executes the optional callback functions
function Request:_do_callback(socket_error)
  -- flush cache
  if (self.settings.save_file) then
    self:_write_file(self.cache)
  end
  if (self.tempfile and io.exists(self.tempfile) and io.type(self.handle) == "file") then
    self.handle:flush()
    self.handle:close()
  end 

  -- Print a small amount of received data in the terminal
  log:info(("=== CONTENT (%d bytes from %s) ==="):format(
    self.length, self.url))
  if (#self.contents > 0 and self.length <= 32 * 1024) then
    log:info(self.contents)  
  end

  if (socket_error) then
    log:info(("%s failed with error: '%s'."):format(self.url, socket_error))    
  else
    log:info(("%s has completed."):format(self.url))    
    
    if (self.settings.save_file) then         
      if (io.exists(self.tempfile)) then        
        if (not self.settings.default_download_folder) then
          self.settings.default_download_folder = self.tempfile:match("^(.+[/\\])")  
        end

        -- "/" is supported on all supported platforms as path seperator
        local dir = self.settings.default_download_folder:gsub("\\","/")

        -- Try to create target dir
        if (not io.exists(dir)) then          
          local ok, err = os.mkdir(dir)          
          log:info("Created download dir: "..dir .." Ok: ".. 
            tostring(ok).."; Err: " .. tostring(err))
        end
        
        -- strip trailing slash
        dir = dir:match("^(.+[^/\\])")
        
        if (io.exists(dir)) then
          local path = self.url_parts.path       
          local filename = Util:get_filename(path)          
          
          -- get filename from header          
          local cd = self:_get_header("Content-Disposition")          
          if (cd and #cd > 0) then
            log:info("Content-Disposition: " .. cd)
            filename = cd:match("filename=(.+)$") 
          end
          
          if (not filename) then
            filename = self.url_parts.host
          end
          
          -- add extension depending on content type
          local type = self:_get_header("Content-Type")
          type = type:match("^[^;]+")
          filename = filename .. Request:_get_ext_by_mime(type)                      
          
          -- generate unique name (1).txt
          local target = dir.."/"..filename
          local i = 1          
          while (io.exists(target)) do            
            local name = filename:match("^(.*)%.")
            local extension = Util:get_extension(filename)
            if (extension) then
              extension = "."..extension 
            else
              extension = ""
            end
            target = ("%s%s%s (%d)%s"):format(dir,"/",name,i, extension)
            i = i + 1
          end
          
          log:info("Moving tempfile to download dir: " .. target )          
          local result, error_message = os.rename(self.tempfile, target)
          if (not result) then
            log:error(error_message)
          else
            self.download_target = target
          end
        end -- download folder exists
      end -- temp file exists       
    end -- save file to harddisk
  end -- no socket error
  
  -- close the connection and invalidate
  self.client_socket = nil
  self.response.header = nil
    
  -- Decode data of non-plain datatypes
  local data = nil 
  local parser_error = nil
  
  if (self.settings.save_file) then
    if (self.download_target and io.exists(self.download_target)) then    
      data = self.download_target
    else
      parser_error = "Downloaded file not found"
    end
  elseif (self.length > 0) then
    data, parser_error = self:_decode(self.contents)
    if (parser_error) then 
      self.text_status = Request.PARSERERROR 
    end
  end
  
  local xml_http_request = self;  
  
  self.complete = true
  self.progress:_set_status(Progress.DONE)  
  
  -- invoke the external callbacks (if set)
  if (socket_error or parser_error) then
    -- TODO handle more errors    
    local error = socket_error or parser_error
    self.settings.error( xml_http_request, self.text_status, error)    
  else    
    self.settings.success( data, self.text_status, xml_http_request )
  end

  self.settings.complete( xml_http_request, self.text_status )   
end


---## decode ##---
-- Processes data in a different data type
 -- TODO process more data_types 
function Request:_decode(data)  
  local error, succeeded, result
  local data_type = self.settings.data_type    
  
  if (data_type == "TEXT") then
    return data:concat()
    
  elseif (data_type == "JSON") then
    log:info("Decoding JSON")    
    succeeded, result = pcall(json.decode, data:concat())    
    
  elseif (data_type == "OSC") then
  
  elseif (data_type == "LUA_TABLE") then
    -- assume data is a raw Lua table, return data unprocessed.
    return data
  
  elseif (data_type == "XML") then    
    log:info("Decoding XML")     
    result,error = XmlParser:ParseXmlText(data:concat())    
    succeeded = not error    
            
  elseif (data_type == "LUA_SCRIPT") then
    -- evaluate Lua
    
  elseif (data_type == "HTML") then
    -- parse HTML to text+layout
  end
  
  if (succeeded) then
    data = result
  else
    error = result
    log:error("Unable to decode: " .. (error or "unknown XML Parser error"))
  end     
  return data, error
end
