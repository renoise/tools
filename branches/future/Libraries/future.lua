--[[----------------------------------------------------------------------------
-- future.lua
----------------------------------------------------------------------------]]--

--[[
  module which enables some branch/futures standard Lua functions before 
  they got released - before they are built into Renoise. This way you can 
  already test and use them, before the new alpha builds are avilable.
  
  To use this module, put a:
    pcall(require, "future") 
  
  somewhere into your scripts. The 'pcall' will ensure that your script runs 
  even without "future" in the paths, but its recommended to remove the 
  require "future" with every new alpha.
  
  This file will be emptied / updated each time branches/future was 
  merged back to the trunk...
]]

-- nothing in here at the moment...
