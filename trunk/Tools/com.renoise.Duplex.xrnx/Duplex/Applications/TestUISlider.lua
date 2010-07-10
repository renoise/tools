--[[----------------------------------------------------------------------------
-- Duplex.TestUISlider
----------------------------------------------------------------------------]]--

--[[

Various tests for UISlider 

  This is the layout for slider embedded in a matrix 

  |1|2|3|4|5|6|7|8|
   _______________ 
  | |_____________|
  | | |___________|
  | | | |_________|
  | | | | |_______|
  | | | | |
  | | | | |
  | | | | |
  |_|_|_|_|

  4 horizontal sliders, each with different settings
  4 vertical sliders, -#-


--]]



--==============================================================================

class 'TestUISlider' (Application)

function TestUISlider:__init(display)
  TRACE("TestUISlider:__init",display)

  self.display = display

  local slider = UISlider(self.display)
  slider.group_name = "Grid"
  slider.x_pos = 1
  slider.y_pos = 1
  slider.toggleable = true
  slider.flipped = false
  slider.ceiling = 8
  slider.orientation = VERTICAL
  slider.palette.background.color = {0x40,0x00,0x00},
  slider:set_size(8)
  slider.on_change = function(obj) 
    return self.active
  end
  self.display:add(slider)

  local slider = UISlider(self.display)
  slider.group_name = "Grid"
  slider.x_pos = 2
  slider.y_pos = 1
  slider.toggleable = true
  slider.flipped = false
  slider.ceiling = 7
  slider.orientation = HORIZONTAL
  slider.palette.background.color = {0x00,0x40,0x00},
  slider:set_size(7)
  slider.on_change = function(obj) 
    return self.active
  end
  self.display:add(slider)

  local slider = UISlider(self.display)
  slider.group_name = "Grid"
  slider.x_pos = 2
  slider.y_pos = 2
  slider.toggleable = false
  slider.flipped = false
  slider.ceiling = RENOISE_DECIBEL
  slider.orientation = VERTICAL
  slider.palette.background.color = {0x40,0x00,0x00},
  slider:set_size(7)
  slider.on_change = function(obj) 
    return self.active
  end
  self.display:add(slider)

  local slider = UISlider(self.display)
  slider.group_name = "Grid"
  slider.x_pos = 3
  slider.y_pos = 2
  slider.toggleable = false
  slider.flipped = false
  slider.ceiling = RENOISE_DECIBEL
  slider.orientation = HORIZONTAL
  slider.palette.background.color = {0x00,0x40,0x00},
  slider:set_size(6)
  slider.on_change = function(obj) 
    return self.active
  end
  self.display:add(slider)

  local slider = UISlider(self.display)
  slider.group_name = "Grid"
  slider.x_pos = 3
  slider.y_pos = 3
  slider.toggleable = true
  slider.flipped = true
  slider.ceiling = RENOISE_DECIBEL
  slider.orientation = VERTICAL
  slider.palette.background.color = {0x40,0x00,0x00},
  slider:set_size(6)
  slider.on_change = function(obj) 
    return self.active
  end
  self.display:add(slider)

  local slider = UISlider(self.display)
  slider.group_name = "Grid"
  slider.x_pos = 4
  slider.y_pos = 3
  slider.toggleable = true
  slider.flipped = true
  slider.ceiling = RENOISE_DECIBEL
  slider.orientation = HORIZONTAL
  slider.palette.background.color = {0x00,0x40,0x00},
  slider:set_size(5)
  slider.on_change = function(obj) 
    return self.active
  end
  self.display:add(slider)

  local slider = UISlider(self.display)
  slider.group_name = "Grid"
  slider.x_pos = 4
  slider.y_pos = 4
  slider.toggleable = false
  slider.flipped = true
  slider.ceiling = RENOISE_DECIBEL
  slider.orientation = VERTICAL
  slider.palette.background.color = {0x40,0x00,0x00},
  slider:set_size(5)
  slider.on_change = function(obj) 
    return self.active
  end
  self.display:add(slider)

  local slider = UISlider(self.display)
  slider.group_name = "Grid"
  slider.x_pos = 5
  slider.y_pos = 4
  slider.toggleable = false
  slider.flipped = true
  slider.ceiling = RENOISE_DECIBEL
  slider.orientation = HORIZONTAL
  slider.palette.background.color = {0x00,0x40,0x00},
  slider:set_size(4)
  slider.on_change = function(obj) 
    return self.active
  end
  self.display:add(slider)


end

