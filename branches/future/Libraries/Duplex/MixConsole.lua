--[[----------------------------------------------------------------------------
-- Duplex.MixConsole
----------------------------------------------------------------------------]]--

--[[

A generic mixer class 

--]]

module("Duplex", package.seeall);


class 'MixConsole' (Application)

function MixConsole:__init(display)
--print("MixConsole:__init",display)

	-- constructor 
	Application.__init(self)
	
	-- controls
	self.master = nil
	self.sliders = nil
	self.buttons = nil
	
	self.display = display
	self.init_app(self)
	--self.start_app(self)

	self.add_observables(self)


end

function MixConsole:set_track_volume(idx,value)
--print("set_track_volume",idx,value)
	if not self.active then
		return
	end
	renoise.song().tracks[idx].prefx_volume.value = value
	self.sliders[idx].set_value(self.sliders[idx],value,true) -- skip on_change()  
end


function MixConsole:set_track_mute(idx,state)
--print("set_track_mute",idx,state)
	if not self.active then
		return
	end
	local active = true
	if state == MUTE_STATE_ACTIVE then
		active = false
	end
	self.buttons[idx].set(self.buttons[idx],active,true) -- skip on_change() 
	self.sliders[idx].set_dimmed(self.sliders[idx],active)

end

function MixConsole:set_master_volume(value)
	get_master_track().prefx_volume.value = value
	self.master.set_value(self.master,value,true) -- skip on_change()  
end

-- (re)building stuff & layout

function MixConsole:init_app()
--print("MixConsole:init_app(")

	Application.init_app(self)

	local observable = nil

	self.master = nil
	self.sliders = {}
	self.buttons = {}

	-- this should be done pretty flexible, to support
	-- as many different configurations as possible

	for i=1,8 do

		-- sliders ---------------------------------------------------

		self.sliders[i] = Slider(self.display)
		self.sliders[i].group_name = "Grid"
		self.sliders[i].x_pos = i
		self.sliders[i].y_pos = 1
		self.sliders[i].toggleable = true
		self.sliders[i].inverted = false
		self.sliders[i].ceiling = 1.4125375747681
		self.sliders[i].orientation = VERTICAL
		self.sliders[i].set_size(self.sliders[i],8)

		-- slider changed from controller
		self.sliders[i].on_change = function(obj) 
			if not self.active then
				print("Application is sleeping")
			elseif i == get_master_track_index() then
				return
			elseif not renoise.song().tracks[i] then
				print('Track is outside bounds')
			else
				renoise.song().tracks[i].prefx_volume.value = obj.value
			end
		end
		self.display.add(self.display,self.sliders[i])


		-- buttons ---------------------------------------------------

		self.buttons[i] = ToggleButton(self.display)
		self.buttons[i].group_name = "Controls"
		self.buttons[i].x_pos = i
		self.buttons[i].y_pos = 1
		self.buttons[i].active = false

		-- mute state changed from controller
		self.buttons[i].on_change = function(obj) 
			--print("self.buttons[",i,"]:on_change",obj.x_pos)
			if not self.active then
				print("Application is sleeping")
				return
			elseif i == get_master_track_index() then
				print("Can't mute the master track")
				return
			elseif not renoise.song().tracks[i] then
				print('Track is outside bounds')
				return
			end
			local mute_state = nil
			local dimmed = nil
			if obj.active then
				mute_state = MUTE_STATE_OFF
				dimmed = true
			else
				mute_state = MUTE_STATE_ACTIVE
				dimmed = false
			end
			renoise.song().tracks[i].mute_state = mute_state
			self.sliders[i].set_dimmed(self.sliders[i],dimmed)
		end
		self.display.add(self.display,self.buttons[i])



		-- apply customization -----------------------------------------------

		if (i>6) then
			self.sliders[i].colorize(self.sliders[i],{0x00,0xff,0x00})
			self.buttons[i].colorize(self.buttons[i],{0x00,0xff,0x00})
		elseif (i>3)then
			self.sliders[i].colorize(self.sliders[i],{0xff,0x00,0x00})
			self.buttons[i].colorize(self.buttons[i],{0xff,0x00,0x00})
		end


	end

	self.master = Slider(self.display)
	self.master.group_name = "Triggers"
	self.master.x_pos = 1
	self.master.y_pos = 1
	self.master.toggleable = true
	self.master.ceiling = 1.4125375747681
	self.master.set_size(self.master,8)
	self.master.on_change = function(obj) 
		--print("self.master:on_change",obj.value)
		get_master_track().prefx_volume.value = obj.value
	end
	self.display.add(self.display,self.master)

end


-- start/resume application
function MixConsole:start_app()
--print("MixConsole.start_app()")

	Application.start_app(self)

	-- set controls to current values
	local value = nil
	for i=1,8 do
		if renoise.song().tracks[i] then
			value = renoise.song().tracks[i].prefx_volume.value
			self.set_track_volume(self,i,value)
			value = renoise.song().tracks[i].mute_state
			self.set_track_mute(self,i,value)
		end
	end

end


function MixConsole:destroy_app()
--print("MixConsole:destroy_app")

	self.master.remove_listeners(self.master)
	for _,obj in ipairs(self.sliders) do
		obj.remove_listeners(obj)
	end
	for _,obj in ipairs(self.buttons) do
		obj.remove_listeners(obj)
	end

	Application.destroy_app(self)

end

-- add observables to renoise parameters
-- TODO update this list as more tracks are added

function MixConsole:add_observables()

	local observable

	for i=1,8 do

		-- slider changed from Renoise
		if renoise.song().tracks[i] then

			observable = renoise.song().tracks[i].prefx_volume.value_string_observable
			local function slider_set()
				local value = renoise.song().tracks[i].prefx_volume.value
				-- compensate for loss of precision 
				if not compare(self.sliders[i].value,value,1000) then
					self.set_track_volume(self,i,value)
				end
			end
			observable:add_notifier(slider_set)

			-- mute state changed from Renoise
			observable = renoise.song().tracks[i].mute_state_observable
			local function button_set()
				self.set_track_mute(self,i,renoise.song().tracks[i].mute_state)
			end
			observable:add_notifier(button_set)

		end


	end

end