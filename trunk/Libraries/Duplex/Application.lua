--[[----------------------------------------------------------------------------
-- Duplex.Application
----------------------------------------------------------------------------]]--

--[[

A generic application class 

--]]

module("Duplex", package.seeall);

class 'Application'

-- constructor 
function Application:__init()
--print("Application:__init()")
	self.name = "Application"
	self.created = false
	self.view = nil
	self.active = false
end

-- create application
function Application:init_app()
--print("Application:init_app()")
	local vb = renoise.ViewBuilder()
	self.view = vb:text{
		text="this is a blank application",
	}
	self.created = true

end

-- start/resume application
function Application:start_app()
--print("Application:start_app()")
	if not self.created then return false end
	self.active = true

end

-- stop application
function Application:stop_app()
--print("Application:stop_app()")
	if not self.created then return false end
	self.active = false

end

-- display application
function Application:show_app()
--print("Application:show_app()")
	if not self.created then return false end
	self.dialog = renoise.app():show_custom_dialog(
		self.name,self.view
	)
	self.dialog:show()
end

-- hide application
function Application:hide_app()
	if not self.created then return false end
	self.dialog:close()
end


-- destroy application
function Application:destroy_app()
	self.stop_app(self)
end

-- handle periodic updates 
function Application:idle_app()

end

