--[[

	A simple descriptive class for pattern-positions
	(as they are fired by the 'line_notifier' method)
]]

class 'xPattPos'

function xPattPos:__init()

	self.line = line
	self.pattern = pattern
	self.track = track

end


