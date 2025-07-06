--[[===============================================================================================
cScheduler
===============================================================================================]]--

--[[--

Schedule tasks to execute after a defined amount of time.

## About

## Changelog 

1.04
- Dynamically add/detach idle notifier as the need arises 


]]--

--=================================================================================================

class 'cScheduler' 

--------------------------------------------------------------------------------

--- Initialize the cScheduler class

function cScheduler:__init()
	TRACE("cScheduler:__init()")

  self.tasks = table.create()

end


--------------------------------------------------------------------------------

--- Perform idle task (check when it's time to execute a task)

function cScheduler:on_idle()

  -- check time
  for idx,task in ripairs(self.tasks) do
    if (task.time<=os.clock()) then
      self:_execute_task(task)
      self.tasks:remove(idx)
    end
  end
end


--------------------------------------------------------------------------------

--- Add a new task to the scheduler
-- @param ref  (Object) the object to use as context (optional)
-- @param func (func) the function to call
-- @param delay (number) the delay before executing task
-- @param ... (Vararg) variable number of extra arguments

function cScheduler:add_task(ref,func,delay, ...)
  TRACE("cScheduler:add_task()",ref,func,delay)

  local task = cScheduledTask(ref,func,delay,arg)
  self.tasks:insert(task)

  local obs = renoise.tool().app_idle_observable
  local fn = cScheduler.on_idle
  if not obs:has_notifier(self,fn) then
    obs:add_notifier(self,fn)
  end

  return task

end


--------------------------------------------------------------------------------

--- Remove a previously scheduled task 
-- @param ref (cScheduledTask) reference to the task

function cScheduler:remove_task(ref)
  TRACE("cScheduler:remove_task()",ref)

  -- remove from list
  for idx,task in ripairs(self.tasks) do
    if (ref==task) then
      self.tasks:remove(idx)
      return
    end
  end

  if (#self.tasks == 0) then
    local obs = renoise.tool().app_idle_observable
    local fn = cScheduler.on_idle
    if obs:has_notifier(self,fn) then
      obs:remove_notifier(self,fn)
    end
  end

end


--------------------------------------------------------------------------------

--- Execute a given task (using the provided context or anonymously)
-- @param task (cScheduledTask) reference to the task

function cScheduler:_execute_task(task)
  TRACE("cScheduler:_execute_task",task)

  if task.ref then
    task.func(task.ref,unpack(task.args))
  else
    task.func(unpack(task.args))
  end
end


--[[----------------------------------------------------------------------------
-- cScheduledTask
----------------------------------------------------------------------------]]--

class 'cScheduledTask' 

--------------------------------------------------------------------------------

--- A class representing a scheduled task
-- @param ref  (Object) the object to use as context (optional)
-- @param func (func) the function to call
-- @param delay (number) the delay before executing task
-- @param args (table) variable number of extra arguments

function cScheduledTask:__init(ref, func, delay, args)
  TRACE("cScheduledTask:__init", ref, func, delay, args)

  self.time = os.clock()+delay
  self.args = args
  self.ref = ref
  self.func = func

end


function cScheduledTask:__eq(other)
  return rawequal(self, other)
end  


