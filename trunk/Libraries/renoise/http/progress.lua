-------------------------------------------------------------------------------
--  Progress class
-------------------------------------------------------------------------------

class "Progress"

Progress.INIT = "Initialized"
Progress.QUEUED = "Queued"
Progress.BUSY = "Downloading"
Progress.DONE = "Completed"
Progress.CANCELLED = "Cancelled"
Progress.PAUSED = "Paused"


---## __init ##---
function Progress:__init(callback)    
  -- current amount of received bytes
  self.bytes = 0
  
  self.content_length = nil
  
  -- current in percent
  -- can be nil if total filesize is unknown
  self.percent = nil
  
  -- elapsed time in ms
  self.elapsed_time = 0
  
  self.start_time = nil
  
  self.paused_time = nil
  
  -- estimated time until completion in ms
  -- can be nil if total filesize is unknown
  self.eta = nil
  
  self.estimated_duration = nil
  
  -- init / queued / busy / done
  self.status = Progress.INIT
  
  -- download speed
  self.speed = 0
  self.avg_speed = 0
  self.max_speed = 0
  self.min_speed = 0
  
  -- moving average
  self.timetable = table.create()
  self.timetable:insert({ms=os.clock(), bytes=0})
  self.timetable_spread = 10
  self.old_avg = nil
  self.new_avg = nil
  self.speeds = table.create()
  self.refresh = 5
  
  -- function to be called when new data has been received
  self.callback = callback     
end


---## get_speed ##---
-- Download speed in kBps
function Progress:get_speed()
  return self.speed
end


---## get_status ##---
function Progress:get_status()    
  return self.status
end


function Progress:_set_moving_average()
  local ms = os.clock() * 1000
  self.timetable:insert({ms=ms, bytes=self.bytes})
  
  -- remove oldest entry
  if (#self.timetable > self.timetable_spread) then    
    self.timetable:remove(1)
  end
end

function Progress:get_moving_average()  
  local high = self.timetable[#self.timetable]
  local low = self.timetable[1]
  local delta_kb = (high.bytes - low.bytes) / 1024
  local delta_t = (high.ms - low.ms) / 1000
  local kbps = 0
  if (delta_t > 0) then
   kbps = math.floor(delta_kb / delta_t)
  end
  
  self.speeds:insert(kbps)  
  if (#self.speeds > 5) then
    self.speeds:remove(1)
  end
  
  self.refresh = self.refresh - 1
  if (self.refresh == 0) then
    self.refresh = 5
    return self.new_avg or kbps
  end
  
  local sum = 0
  for _,v in ipairs(self.speeds) do
    sum = sum + v
  end
  self.old_avg = self.new_avg or 0
  self.new_avg = ((sum / #self.speeds) + self.old_avg) / 2
  
  return self.new_avg
end


---## set_speed ##---
function Progress:_set_speed(old, new)
  local seconds = os.clock() - (self.tic or 0.5)
  local amount = new - old
  self.tic = os.clock()
  self.speed = amount / 1024 / seconds
  self.avg_speed = self:get_moving_average()
  self.min_speed = math.min(self.speed, self.min_speed)
  self.max_speed = math.max(self.speed, self.max_speed)
end


---## set_status ##---
function Progress:_set_status(s)
  self.status = s  
  if (self.status == Progress.DONE) then
    self.eta = 0
  elseif (self.status == Progress.PAUSED) then
    self.paused_time = os.clock()
  elseif (self.status == Progress.BUSY and self.paused_time) then
    local paused_duration = (os.clock() - self.paused_time)
    self.elapsed_time = self.elapsed_time - paused_duration    
    self.paused_time = nil
  end
  self:_notify()
end


---## set_eta ##---
-- Estimate the arrival time of the downloaded file.
function Progress:_set_eta()
  if (not self.percent) then 
    return 
  end
  
  -- time (s) per 1 percent
  local time_per_percent = self.elapsed_time / self.percent
  
  -- eta = approximate time when 100% 
  local eta = time_per_percent * 100 + 1
  
  -- average from last result
  self.estimated_duration = ((self.estimated_duration or 0) + eta) / 2
  self.eta = math.max(0, self.estimated_duration - self.elapsed_time)
end


---## set_elapsed_time ##---
function Progress:_set_elapsed_time()  
  if (not self.start_time) then
    self.start_time = os.clock()
  end
  
  self.elapsed_time = os.clock() - self.start_time + self.elapsed_time
  
  self.start_time = os.clock()
  self:_set_eta()
end


---## notify ##---
-- Let the attached callback functions know something has changed.
function Progress:_notify()
  self.callback(self)
end


---## set_percent ##---
-- Calculate the percentage of download completion.
function Progress:_set_percent()
  if (self.content_length and self.content_length > 0) then
    self.percent = self.bytes / self.content_length * 100
  end
end


---## set_bytes ##---
-- Specify the current amount of received bytes.
-- Increased whenever the socket fills a new buffer.
function Progress:_set_bytes(b)  
  self:_set_speed(self.bytes, b)
  self.bytes = b
  self:_set_moving_average()
  self:_set_elapsed_time()
  self:_set_percent()  
  self:_notify()
end
