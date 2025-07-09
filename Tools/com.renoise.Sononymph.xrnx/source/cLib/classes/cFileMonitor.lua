
--[[

  Monitor files by checking their modification date - 

  ## How to respond to changes: 
  
    * The class emits "file_modified" events when change is detected 
    * Respond to this event by accessing "changed"
  
]]

---------------------------------------------------------------------------------------------------

class "cFileMonitor"

---------------------------------------------------------------------------------------------------
-- Constructor
-- @param polling_interval (number), seconds, 0 = as often as possible)
-- @param emit_initial (boolean), when true change is emitted while initially adding files 

function cFileMonitor:__init(...)

  local args = cLib.unpack_args(...)
  
  -- validate options 
  if args.polling_interval then 
    assert(type(args.polling_interval == "number"))
  end
  if args.emit_initial then 
    assert(type(args.emit_initial == "boolean"))
  end
  
  -- properties 
   
  -- table<string>, currently watched files 
  self.paths = property(self.get_paths,self.set_paths)
  self._paths = {}
   
  -- boolean, true when actively monitoring files 
  self.is_monitoring = property(self.get_is_monitoring)
  self._is_monitoring = renoise.Document.ObservableBoolean(false)

  -- polling interval (seconds, 0 = as often as possible)
  self.polling_interval = property(self.get_polling_interval,self.set_polling_interval)
  self.polling_interval_observable = renoise.Document.ObservableNumber(args.polling_interval or 0)
  
  -- boolean - 
  self.emit_initial = true 
    
  -- events 

  -- table<key = filename, value = table of stats>
  -- read-only: most recently changed files 
  self.changed = property(self.get_changed)
  
  -- use this to get notified when files have changed 
  self.changed_observable = renoise.Document.ObservableBang()
  
  -- private 
  
  -- number 
  self._last_poll = nil 
  
  -- (table, key is filename and return value from io.stat() is value)
  self._stats = {}
  
  -- table,string - recently changed files 
  self._changed = {}
  
end

---------------------------------------------------------------------------------------------------
-- Properties

function cFileMonitor:get_changed()
  return self._changed 
end

---------------------------------------------------------------------------------------------------

function cFileMonitor:get_is_monitoring()
  return self._is_monitoring
end

---------------------------------------------------------------------------------------------------

function cFileMonitor:get_paths()
  return self._paths 
end

function cFileMonitor:set_paths(paths)
  self._paths = paths
end 

---------------------------------------------------------------------------------------------------

function cFileMonitor:get_polling_interval()
  return self.polling_interval_observable.value
end

function cFileMonitor:set_polling_interval(val)
  self.polling_interval_observable.value = val
end 

---------------------------------------------------------------------------------------------------
-- Public methods 
---------------------------------------------------------------------------------------------------

function cFileMonitor:start()
  TRACE("cFileMonitor:start()")
  
  -- register idle observable 
  self:_add_notifier()
  
  self._is_monitoring.value = true 
end

---------------------------------------------------------------------------------------------------

function cFileMonitor:stop()
  TRACE("cFileMonitor:stop()")
  
  -- unregister idle observable 
  self:_remove_notifier()
  
  self._is_monitoring.value = false
end

---------------------------------------------------------------------------------------------------
-- Private methods 
---------------------------------------------------------------------------------------------------

function cFileMonitor:idle_notifier()

  -- polling interval 
  local do_poll = false 
  if (self.polling_interval > 0) then 
    local time = os.clock()
    if not self._last_poll then 
      self._last_poll = time    
      do_poll = true 
    elseif (self._last_poll + self.polling_interval < time) then 
      self._last_poll = time    
      do_poll = true 
    end 
  else 
    do_poll = true 
  end 
  
  if not do_poll then 
    return 
  end
  
  -- check for changes and memorize
  local modified = self:_get_modified()
  if not table.is_empty(modified) then 
    self._changed = {}
    for path,stats in pairs(modified) do 
      self._stats[path] = stats
      table.insert(self._changed,path)
    end 
    self.changed_observable:bang()
  end
  
end

---------------------------------------------------------------------------------------------------
-- iterate through, and check all monitored files 
-- @return table {filename = stats} or nil if no changed files 

function cFileMonitor:_get_modified()
  --TRACE("cFileMonitor:get_modified()")
  
  local rslt = {}
  
  for _,path in ipairs(self.paths) do 
    local stats = self:_get_stats_if_changed(path)
    if stats then 
      rslt[path] = stats
    end
  end
  
  return rslt
  
end

---------------------------------------------------------------------------------------------------
-- @param path (string)
-- @return stats (table) if changed or nil if not 

function cFileMonitor:_get_stats_if_changed(path)
  --TRACE("cFileMonitor:_get_stats_if_changed(path)",path)

  local cached = self._stats[path]
  if cached then 
    local stats = io.stat(path)
    if stats then 
      if (stats.mtime > cached.mtime) then 
        return stats
      end 
    end
  elseif self.emit_initial then
    return io.stat(path)
  end 
  
end

---------------------------------------------------------------------------------------------------

function cFileMonitor:_remove_notifier()
  TRACE("cFileMonitor:_remove_notifier()")
  
  local idle_obs = renoise.tool().app_idle_observable  
  if idle_obs:has_notifier(self,cFileMonitor.idle_notifier) then
    idle_obs:remove_notifier(self,cFileMonitor.idle_notifier)
  end

end


---------------------------------------------------------------------------------------------------

function cFileMonitor:_add_notifier()
  TRACE("cFileMonitor:_add_notifier()")
  
  local idle_obs = renoise.tool().app_idle_observable  
  if not idle_obs:has_notifier(self,cFileMonitor.idle_notifier) then
    idle_obs:add_notifier(self,cFileMonitor.idle_notifier)
  end

end


