--[[============================================================================
process_slicer.lua
============================================================================]]--

--[[

ProcessSlicer allows you to slice up a function which takes a lot of 
processing time into multiple calls via Lua coroutines. 

* Example usage:

local slicer = ProcessSlicer(my_process_func, my_callback, arg1, argX)

-- The optional callback function will be called when the process has
-- finished. If the process has a return value, the callback will be 
-- called with the return value as argument. 
-- If you don't want a callback, but want to add arguments, replace 
-- my_callback with nil.

-- This starts calling 'my_process_func' in idle, passing all arguments 
-- you've specified in the ProcessSlicer constructor.
slicer:start() 

-- To abort a running sliced process, you can call "stop" at any time
-- from within your processing function of outside of it in the main thread. 
-- As soon as your process function returns, the slicer is automatically 
-- stopped.
slicer:stop() 

-- To give processing time back to Renoise, call 'coroutine.yield()' 
-- anywhere in your process function to temporarily yield back to Renoise:
function my_process_func()
  for j=1,100 do
    -- do something that needs a lot of time, and periodically call 
    -- "coroutine.yield()" to give processing time back to Renoise. Renoise 
    -- will switch back to this point of the function as soon as has done 
    -- "its" job:
    coroutine.yield()
  end  
end


* Drawbacks:

By slicing your processing function, you will also slice any changes that are 
done to the Renoise song into multiple undo actions (one action per slice/yield).

Modal dialogs will block the slicer, cause on_idle notifications are not fired then. 
It will even block your own process GUI when trying to show it modal.

]]

class "ProcessSlicer"

function ProcessSlicer:__init(process_func, callback, ...)
  assert(type(process_func) == "function", 
    "expected a function as first argument")
  
  assert(callback == nil or type(callback) == "function", 
    "expected nil or a function as second argument")    

  self.__process_func = process_func
  self.__process_func_args = arg
  self.__process_thread = nil
  self.__callback = callback
  self.__data = nil
end


--------------------------------------------------------------------------------
-- returns true when the current process currently is running

function ProcessSlicer:running()
  return (self.__process_thread ~= nil)
end


--------------------------------------------------------------------------------
-- start a process

function ProcessSlicer:start()
  assert(not self:running(), "process already running")
  
  self.__process_thread = coroutine.create(self.__process_func)
  
  renoise.tool().app_idle_observable:add_notifier(
    ProcessSlicer.__on_idle, self)
end


--------------------------------------------------------------------------------
-- stop a running process

function ProcessSlicer:stop()
  assert(self:running(), "process not running")

  renoise.tool().app_idle_observable:remove_notifier(
    ProcessSlicer.__on_idle, self)

  self.__process_thread = nil
end


--------------------------------------------------------------------------------

-- function that gets called from Renoise to do idle stuff. switches back 
-- into the processing function or detaches the thread

function ProcessSlicer:__on_idle()
  assert(self.__process_thread ~= nil, "ProcessSlicer internal error: "..
    "expected no idle call with no thread running")
  
  -- continue or start the process while its still active
  if (coroutine.status(self.__process_thread) == 'suspended') then
    local succeeded, data = coroutine.resume(
      self.__process_thread, unpack(self.__process_func_args))      
    self.__data = data    
    
    if (not succeeded) then
      -- stop the process on errors
      self:stop()
      -- and forward the error to the main thread
      error(data) 
    end
    
  -- stop when the process function completed
  elseif (coroutine.status(self.__process_thread) == 'dead') then  
    self:stop()        
    if (self.__callback ~= nil) then
      self.__callback(self.__data)
    end
  end
end
