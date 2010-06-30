--[[----------------------------------------------------------------------------
-- Duplex.MatrixTest
----------------------------------------------------------------------------]]--

--[[

Various tests for UIComponents embedded in a matrix 

  This is the layout

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

class 'MatrixTest' (Application)

function MatrixTest:__init(display,options)
  TRACE("MatrixTest:__init",display)

  Application.__init(self)

  self.display = display
  self.matrix_group_name = options.matrix_group_name
  
  self:build_app()
  

end


--------------------------------------------------------------------------------

function MatrixTest:build_app()

  Application.build_app(self)

  local slider = UISlider(self.display)
  slider.group_name = self.matrix_group_name
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
  slider.group_name = self.matrix_group_name
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
  slider.group_name = self.matrix_group_name
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
  slider.group_name = self.matrix_group_name
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
  slider.group_name = self.matrix_group_name
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
  slider.group_name = self.matrix_group_name
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
  slider.group_name = self.matrix_group_name
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
  slider.group_name = self.matrix_group_name
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


--------------------------------------------------------------------------------
-------  Application class methods
--------------------------------------------------------------------------------

function MatrixTest:start_app()
  TRACE("MatrixTest:start_app()")

  Application.start_app(self)
  --self:update()


end
  
--------------------------------------------------------------------------------

function MatrixTest:stop_app()
  TRACE("MatrixTest:stop_app()")

  Application.stop_app(self)


end


--------------------------------------------------------------------------------

function MatrixTest:idle_app()
  
  if not (self.active) then
    return
  end

end


--------------------------------------------------------------------------------

function MatrixTest:on_new_document()
  TRACE("MatrixTest:on_new_document()")

end

