--[[----------------------------------------------------------------------------
-- Duplex.Scheduler
----------------------------------------------------------------------------]]--

--[[

The Scheduler class will execute tasks after a defined amount of time
- UIComponents use this for scheduling updates to their display


--]]


--==============================================================================

class 'Scheduler' 

function Scheduler:__init()

	print("Scheduler:__init()")

  self.tasks = table.create{}


end

function Scheduler:on_idle()
  TRACE("Scheduler:on_idle()",os.clock())

  -- check time
  for idx,task in ripairs(self.tasks) do
    if (task.time<=os.clock()) then
      self:__execute_task(task)
      self.tasks:remove(idx)
    end
  end


end

function Scheduler:add_task(ref,func,delay)
  TRACE("Scheduler:add_task()",ref,func,delay)

  local task = ScheduledTask(ref,func,delay)
  self.tasks:insert(task)
  return task

end

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

function Scheduler:__execute_task(task)
  --print("Scheduler:__execute_task",task)

  --print("about to call task.func:",task.func)
  task.func(task.ref)


end

--[[----------------------------------------------------------------------------
-- Duplex.ScheduledTask
----------------------------------------------------------------------------]]--


class 'ScheduledTask' 

function ScheduledTask:__init(ref,func,delay)
	TRACE("ScheduledTask:__init()",ref,func,delay)

  self.time = os.clock()+delay
  self.ref = ref
  self.func = func

end

--------------------------------------------------------------------------------

function ScheduledTask:__eq(other)
  return rawequal(self, other)
end  


