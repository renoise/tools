--[[

	## ABOUT

	This class will simplify the process of searching patterns for specific 
	types of data. 

]]

class 'xSeeker'

function xSeeker:__init()

	-- boolean, enable this flag to capture all results, 
	-- when false it only returns the first match
	self.greedy = false

	-- boolean, this flag will make the search respect how a live,
	-- playing voice can be released by e.g. a matrix mute
	-- when false, it searches for 'raw' pattern data only
	self.live_mode = true

end

