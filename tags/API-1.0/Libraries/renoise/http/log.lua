class 'Log'

Log.ALL = 0
Log.INFODEBUG = 1
Log.WARN = 2
Log.ERROR = 3
Log.FATAL = 4
Log.OFF = 5

function Log:__init(v)
  self:set_level(v)
end
function Log:info(s)
   if self.level > Log.INFODEBUG then return end
    Log:output("INFO", s)
end
function Log:warn(s)
   if self.level > Log.WARN then return end
   Log:output("WARNING", s)
end
function Log:error(s)
   if self.level > Log.ERROR then return end
       Log:output("ERROR", s)
end
function Log:fatal(s)
   if self.level > Log.FATAL then return end
   Log:output("FATAL", s)
end
function Log:set_level(v)
  assert(type(v)=="number")
  self.level = v or Log.ALL
end
function Log:output(level, str)
  print(string.format("[%s] %s" , level,  tostring(str)))
end
