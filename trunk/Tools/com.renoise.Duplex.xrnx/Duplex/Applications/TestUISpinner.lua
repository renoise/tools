--[[----------------------------------------------------------------------------
-- Duplex.TestUISpinner
----------------------------------------------------------------------------]]--

--[[

About

This class is for testing the UISpinner functionality
Please use the Ohm64 controller to launch the example


--]]

--==============================================================================


class 'TestUISpinner' (Application)

function TestUISpinner:__init(display)

  self.display = display

  -- grid-based spinner, horisontal with up/down arrows
	local c = UISpinner(display)
  c.group_name = "Grid"
  c.x_pos = 1
  c.y_pos = 1
  c.minimum = 0
  c.maximum = 1
  c.__orientation = HORIZONTAL
  c.text_orientation = VERTICAL
  c.on_change = function(obj)
    print(("spinner#1.on_change(): is now at index %i out of %i"):format(obj.index,c.maximum))
    return true
  end
  self.display:add(c)

  -- grid-based spinner, horisontal with left/right arrows
	local c = UISpinner(display)
  c.group_name = "Grid"
  c.x_pos = 1
  c.y_pos = 2
  c.__orientation = HORIZONTAL
  c.text_orientation = HORIZONTAL
  c:set_minimum(1) -- watch out, this modifies the index (0 by default)
  c:set_maximum(3) -- 
  c.on_change = function(obj)
    print(("spinner#2.on_change(): is now at index %i out of %i"):format(obj.index,c.maximum))
    return true
  end
  self.display:add(c)

  -- grid-based spinner, like #1 but flipped
	local c = UISpinner(display)
  c.group_name = "Grid"
  c.x_pos = 3
  c.y_pos = 1
  c.flipped = true
  c.__orientation = HORIZONTAL
  c.text_orientation = VERTICAL
  c.minimum = 0
  c.maximum = 1
  c.on_change = function(obj)
    print(("spinner#3.on_change(): is now at index %i out of %i"):format(obj.index,c.maximum))
    return true
  end
  self.display:add(c)

  -- grid-based spinner, like #2 but flipped and with step size
	local c = UISpinner(display)
  c.group_name = "Grid"
  c.x_pos = 3
  c.y_pos = 2
  c:set_minimum(1)
  c:set_maximum(4)
  c.step_size = 5 -- improbable step size, but not causing errors
  c.flipped = true
  c.text_orientation = HORIZONTAL
  c.__orientation = HORIZONTAL
  c.on_change = function(obj)
    print(("spinner#4.on_change(): is now at index %i out of %i"):format(obj.index,c.maximum))
    return true
  end
  self.display:add(c)

  -- grid-based spinner, vertical with up/down arrows
	local c = UISpinner(display)
  c.group_name = "Grid"
  c.x_pos = 1
  c.y_pos = 3
  c.minimum = 0
  c.maximum = 1
  c.text_orientation = VERTICAL
  c:set_orientation(VERTICAL) -- call the set_orientation() method
  c.on_change = function(obj)
    print(("spinner#5.on_change(): is now at index %i out of %i"):format(obj.index,c.maximum))
    return true
  end
  self.display:add(c)

  -- grid-based spinner, vertical with left/right arrows
	local c = UISpinner(display)
  c.group_name = "Grid"
  c.x_pos = 2
  c.y_pos = 3
  c:set_orientation(VERTICAL) -- remember this, or the size will be "horizontal" (the default)
  c.text_orientation = HORIZONTAL
  c:set_minimum(1) -- watch out, this modifies the index (0 by default)
  c:set_maximum(3) -- 
  c.on_change = function(obj)
    print(("spinner#6.on_change(): is now at index %i out of %i"):format(obj.index,c.maximum))
    return true
  end
  self.display:add(c)

end

