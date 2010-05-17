--[[----------------------------------------------------------------------------
-- Duplex.Application
----------------------------------------------------------------------------]]--

--[[

A generic application class 

--]]


--==============================================================================

class 'Application'

-- constructor 
function Application:__init()
  TRACE("Application:__init()")
  
  self.name = "Application"

  -- the application is considered created once build_app() has been called
  self.created = false

  -- the view is a viewbuilder object (optional) 
  self.view = nil

  -- when the application is inactive, it should 
  -- sleep during idle time and ignore any user input
  self.active = false

  -- the custom dialog is only created if show_app() is called 
  self.dialog = nil
end


--------------------------------------------------------------------------------

-- (run once) create view and members

function Application:build_app()
  TRACE("Application:build_app()")
  
  local vb = renoise.ViewBuilder()
  self.view = vb:text{
    text="this is a blank application",
  }
  self.created = true

end


--------------------------------------------------------------------------------

-- start/resume application

function Application:start_app()
  TRACE("Application:start_app()")
  
  if not self.created then return false end
  self.active = true

end


--------------------------------------------------------------------------------

-- stop application

function Application:stop_app()
  TRACE("Application:stop_app()")
  
  if not self.created then return false end
  self.active = false

end


--------------------------------------------------------------------------------

-- display application

function Application:show_app()
  TRACE("Application:show_app()")
  
  if not self.created then return false end
  if (not self.dialog) or (not self.dialog.visible) then
    self:__create_dialog()
  end
  self.dialog:show()
end

--------------------------------------------------------------------------------

-- hide application

function Application:hide_app()
  TRACE("Application:hide_app()")
  
  if not self.dialog then return false end
  self.dialog:close()
  self.dialog = nil
end


--------------------------------------------------------------------------------

-- destroy application

function Application:destroy_app()
  self:stop_app()
end


--------------------------------------------------------------------------------

-- handle periodic updates 

function Application:idle_app()

end


--------------------------------------------------------------------------------

function Application:__create_dialog()
  TRACE("Application:__create_dialog()")
  
  self.dialog = renoise.app():show_custom_dialog(
    self.name,self.view
  )
end


--------------------------------------------------------------------------------

function Application:__tostring()
  return type(self)
end  

