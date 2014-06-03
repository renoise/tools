--[[============================================================================
-- Duplex.Scheduler
============================================================================]]--

--[[--
Schedule tasks to execute after a defined amount of time

]]--

----------------------------------------------------------------------------]]--

class 'Scheduler' 

--------------------------------------------------------------------------------

--- Initialize the Scheduler class

function Scheduler:__init()
	TRACE("Scheduler:__init()")

  self.tasks = table.create()

end


--------------------------------------------------------------------------------

--- Perform idle task (check when it's time to execute a task)

function Scheduler:on_idle()

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

function Scheduler:add_task(ref,func,delay, ...)
  TRACE("Scheduler:add_task()",ref,func,delay)

  local task = ScheduledTask(ref,func,delay,arg)
  self.tasks:insert(task)

  return task

end


--------------------------------------------------------------------------------

--- Remove a previously scheduled task 
-- @param ref (ScheduledTask) reference to the task

function Scheduler:remove_task(ref)
  TRACE("Scheduler:remove_task()",ref)

  -- remove from list
  for idx,task in ripairs(self.tasks) do
    if (ref==task) then
      self.tasks:remove(idx)
      return
    end
  end
end


--------------------------------------------------------------------------------

--- Execute a given task (using the provided context or anonymously)
-- @param task (ScheduledTask) reference to the task

function Scheduler:_execute_task(task)
  TRACE("Scheduler:_execute_task",task)

  if task.ref then
    task.func(task.ref,unpack(task.args))
  else
    task.func(unpack(task.args))
  end
end


--[[----------------------------------------------------------------------------
-- Duplex.ScheduledTask
----------------------------------------------------------------------------]]--

class 'ScheduledTask' 

--------------------------------------------------------------------------------

--- A class representing a scheduled task
-- @param ref  (Object) the object to use as context (optional)
-- @param func (func) the function to call
-- @param delay (number) the delay before executing task
-- @param args (table) variable number of extra arguments

function ScheduledTask:__init(ref, func, delay, args)
  TRACE("ScheduledTask:__init", ref, func, delay, args)

  self.time = os.clock()+delay
  self.args = args
  self.ref = ref
  self.func = func

end


function ScheduledTask:__eq(other)
  return rawequal(self, other)
end  


