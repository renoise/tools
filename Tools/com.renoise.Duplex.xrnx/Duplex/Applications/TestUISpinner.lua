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
  c:set_range(0,1)
  c.__orientation = HORIZONTAL
  c.text_orientation = VERTICAL
  c.on_change = function(obj)
    if(self.active)then
      print(("spinner#1.on_change(): is now at index %i out of %i"):format(obj.index,c.maximum))
    end
    return self.active
  end
  self.display:add(c)

  -- grid-based spinner, horisontal with left/right arrows
	local c = UISpinner(display)
  c.group_name = "Grid"
  c.x_pos = 1
  c.y_pos = 2
  c.__orientation = HORIZONTAL
  c.text_orientation = HORIZONTAL
  c:set_range(1,3)
  c.on_change = function(obj)
    if(self.active)then
      print(("spinner#2.on_change(): is now at index %i out of %i"):format(obj.index,c.maximum))
    end
    return self.active
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
  c:set_range(0,1)
  c.on_change = function(obj)
    if(self.active)then
      print(("spinner#3.on_change(): is now at index %i out of %i"):format(obj.index,c.maximum))
    end
    return self.active
  end
  self.display:add(c)

  -- grid-based spinner, like #2 but flipped and with step size
	local c = UISpinner(display)
  c.group_name = "Grid"
  c.x_pos = 3
  c.y_pos = 2
  c:set_range(1,4)
  c.step_size = 5 -- improbable step size, but not causing errors
  c.flipped = true
  c.text_orientation = HORIZONTAL
  c.__orientation = HORIZONTAL
  c.on_change = function(obj)
    if(self.active)then
      print(("spinner#4.on_change(): is now at index %i out of %i"):format(obj.index,c.maximum))
    end
    return self.active
  end
  self.display:add(c)

  -- grid-based spinner, vertical with up/down arrows
	local c = UISpinner(display)
  c.group_name = "Grid"
  c.x_pos = 1
  c.y_pos = 3
  c:set_range(0,1)
  c.text_orientation = VERTICAL
  c:set_orientation(VERTICAL) -- call the set_orientation() method
  c.on_change = function(obj)
    if(self.active)then
      print(("spinner#5.on_change(): is now at index %i out of %i"):format(obj.index,c.maximum))
    end
    return self.active
  end
  self.display:add(c)

  -- grid-based spinner, vertical with left/right arrows
	local c = UISpinner(display)
  c.group_name = "Grid"
  c.x_pos = 2
  c.y_pos = 3
  c:set_orientation(VERTICAL) 
  c.text_orientation = HORIZONTAL
  c:set_range(1,3)
  c.on_change = function(obj)
    if(self.active)then
      print(("spinner#6.on_change(): is now at index %i out of %i"):format(obj.index,c.maximum))
    end
    return self.active
  end
  self.display:add(c)

  -- dial-based spinner. range 3/8
	local c = UISpinner(display)
  c.group_name = "EncodersEffect"
  c.x_pos = 1
  c.y_pos = 1
  c:set_range(3,8)
  c:set_index(8)
  c:set_size(1) -- dials only span a single unit
  c.on_change = function(obj)
    if(self.active)then
      print(("spinner#7.on_change(): is now at index %i out of %i"):format(obj.index,c.maximum))
    end
    return self.active
  end
  self.display:add(c)

  -- dial-based spinner, range 0/1
	local c = UISpinner(display)
  c.group_name = "EncodersEffect"
  c.x_pos = 2
  c.y_pos = 1
  c:set_range(0,1)
  c:set_index(1) 
  c:set_size(1) 
  c.on_change = function(obj)
    if(self.active)then
      print(("spinner#8.on_change(): is now at index %i out of %i"):format(obj.index,c.maximum))
    end
    return self.active
  end
  self.display:add(c)

  -- dial-based spinner, range 32/999
	local c = UISpinner(display)
  c.group_name = "EncodersEffect"
  c.x_pos = 3
  c.y_pos = 1
  c:set_range(32,999)
  c:set_index(999) 
  c:set_size(1) 
  c.on_change = function(obj)
    if(self.active)then
      print(("spinner#9.on_change(): is now at index %i out of %i"):format(obj.index,c.maximum))
    end
    return self.active
  end
  self.display:add(c)

end

