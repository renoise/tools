--[[

Cacheable extensions:

- images (gif,png,bmp,jpeg,tiff)
- js
- css

--------------------

get_cache_dir()

--------------------

1) Cache DB

- get object
- save object
- load DB
- save DB
- clear cache

2) Cache functions

- get_cache(url)
- save_cache(url)

3) Cached Objects

- request url
- response headers
- path to cached file
- request date

--------------------


--]]

-- HTTP CACHING
-- http://www.peej.co.uk/articles/http-caching.html

require "renoise.http.util"



-- Returns the OS dependent cache directory and creates it if necessary.
-- chromium.org/user-experience
-- Windows 7/Vista: C:\Users\[USERNAME]\AppData\Local\Google\Chrome\User Data\Default\Cache
-- Windows XP: C:\Documents and Settings\[USERNAME]\Local Settings\Application Data\Google\Chrome\User Data\Default\Cache
local function get_cache_dir()  
  local dir = "Cache"  
  
  if (os.platform() == "LINUX") then  
    
    dir = "~/.cache/Renoise/HTTPLib"
    
  elseif (os.platform() == "MACINTOSH") then      
  
    dir = "~/Library/Caches/Renoise/HTTPLib"
    
  elseif (os.platform() == "WINDOWS") then
    
    if (os.getenv("HOMEPATH"):find("\\Users\\", 1)) then
      -- Windows 7/Vista         
      dir = os.getenv("USERPROFILE") .. '\\AppData\\Local\\Renoise\\HTTPLib\\Cache'
      
    elseif (os.getenv("HOMEPATH"):find("\\Documents")) then
      -- Windows XP
      dir = os.getenv('USERPROFILE')..'\\Local Settings\\Application Data\\Renoise\\HTTPLib\\Cache'    
    end
    
  end
  
  if (not io.exists(dir)) then
    local ok,err = Util:mkdir(dir)
    if (err) then
      log:error("Could not create cache directory at\n\t"..dir.."\n\t"..err)
    end
  end    
  
  return dir
end



-- Returns the OS dependent cache directory and creates it if necessary.
-- chromium.org/user-experience
class "CacheDB" (renoise.Document.DocumentNode)

function CacheDB:get_instance()
  return CacheDB.instance
end


function CacheDB:__init()
  renoise.Document.DocumentNode.__init(self)  
  self:add_property("Objects", renoise.Document.DocumentList())
end

function CacheDB:load()
  self:load_from(get_cache_dir().."/Cache.xml")
end

function CacheDB:save()
  self:save_as(get_cache_dir().."/Cache.xml")  
end

function CacheDB:new_object(url, headers, extension)
  log:info("Creating new Cache Object.")
  local o = CacheObject()
  o:set_url(url)  
  o:set_headers(headers)
  o:set_extension(extension)
  self.Objects:insert(o)
  return o
end

-- Does database contain resource identified by URL?
function CacheDB:get_object(url)
  local len = #self.Objects

  for i=1,len do      
    local obj = self.Objects[i]    
    print("Compare", obj:get_url(), url)
    if (obj:get_url() == url) then    
      return obj
    end
  end
  return false
end

-- Clear the database and destroy all cached files
function CacheDB:destroy()
end

-- Remove expired cache objects
function CacheDB:clean()
end

function CacheDB:contains(fieldname, value)
  local len = #self.Objects
  
  for i=1,len do      
    local obj = self.Objects[i]    
    
    -- urlencode?
    if (obj[fieldname] and obj[fieldname].value == value) then    
      return obj
    end
  end
  return false
end

CacheDB.instance = CacheDB()




class "CacheObject" (renoise.Document.DocumentNode)

function CacheObject:__init()
  renoise.Document.DocumentNode.__init(self)    
  
  self:add_property("extension", "")  
  self:add_property("headers", "")  
  self:add_property("url", "")    
  local date = 906000490
  self:add_property("date", 1)  
  self:add_property("number", 1)  
  self:add_property("path", "")
end

function CacheObject:__tostring()  
  return ("%s %s %s"):format(self:get_url(), self:get_path(), self:get_date())
end

function CacheObject:close()    
  if (self.handle and io.type(self.handle) == "file") then
    log:info("Closing handle for file: " .. self.path.value)
    self.handle:flush()
    self.handle:close()    
  end
end

function CacheObject:write_file(data)  
  
  if (not self.handle) then
      
    local number = 1
    local filename = ("f_%06x"):format(number)
    local path = ("%s/%s.%s"):format(get_cache_dir(), filename, self.extension.value)    
    local db = CacheDB.get_instance()
  
    while (db:contains("number", number) or io.exists(path)) do
      number = number + 1
      filename = ("f_%06x"):format(number)
      path = ("%s/%s.%s"):format(get_cache_dir(), filename, self.extension.value)    
    end
  
    path = Util:get_path(path)
  
    self:set_path(path)
    self:set_number(number)
    
    log:info("Creating cache file: " .. path)
    
    local err
    self.handle,err = io.open(path, "wb")    
    
    if (type(data)=="table") then
      data = table.concat(data)
    end
    
    if (io.type(self.handle) == "file") then      
      self.handle:write(data)
    end     
    
  end  
  
end

function CacheObject:set_number(n)
  self.number.value = n
end

function CacheObject:get_number()
  return self.number.value
end

function CacheObject:get_age()

end

-- calculate ETag
function CacheObject:get_etag()

end

-- return the cached file size
function CacheObject:get_size()
  local path = self.path.value
  if (io.exists(path)) then
    return io.stat(path)['size']
  end
end

-- return path to cached file
function CacheObject:get_path()
  return self.path.value
end

-- save path to cached file
function CacheObject:set_path(path)
  self.path.value = path
end


function CacheObject:set_url(url)
 self.url.value = url
end

function CacheObject:get_url(url)
 return self.url.value
end

function CacheObject:set_extension(extension)  
  self.extension.value = extension
end

function CacheObject:get_extension() 
  return self.extension.value
end

-- save request date in UNIX format
function CacheObject:set_unix_date(date)  
  self.date.value = date
end

function CacheObject:get_unix_date() 
  return self.date.value
end

function CacheObject:get_date()  
  local dt = os.date("*t", self:get_unix_date())
  return ("%s/%s/%s"):format(dt.day, dt.month, dt.year)
end

-- save response headers
function CacheObject:set_headers(headers)
  if (type(headers)=='table') then
    headers = table.concat(headers,'\n')
  end
  self.headers.value = headers
end


-- returns the response headers
function CacheObject:get_headers()
  return self.headers
end




-- remove this cache object including the cache file
function CacheObject:remove()
  log:info("Removing cache file: " .. self.path)  
  if (io.exists(self.path) and Util:get_filename(self.path):sub(1,2) == "f_") then
    -- os.remove(self.path)  
  end
end
