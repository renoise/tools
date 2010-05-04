--[[----------------------------------------------------------------------------
-- Duplex.Browser
----------------------------------------------------------------------------]]--

--[[

The Browser class provides easy access to running scripts

--]]

module("Duplex", package.seeall);

class 'Browser' (Application)

function Browser:__init(device_name,app_name)
--print("Browser:__init",device_name,app_name)

	-- initialize
	self.name = "Browser"
	self.device = nil
	self.display = nil
	self.stream = MessageStream()

	self.application = nil	--	current application

	self.init_app(self)

	-- apply arguments
	if device_name then
		self.set_device_index(self,device_name)
		if app_name then
			self.set_application(self,app_name)
		end
	end

end

function Browser:init_app()

	Application.init_app(self)

	self.vb = renoise.ViewBuilder()

	self.build_browser(self)
	-- hide after building
	self.vb.views.dpx_browser_app_row.visible = false
	--self.vb.views.dpx_browser_preset_row.visible = false
	self.vb.views.dpx_browser_device_settings.visible = false
	self.vb.views.dpx_browser_fix.visible = false

end

-- changing the active input device list index will
-- cause another method, "set_device" to become invoked

function Browser:set_device_index(name)
--print("Browser:set_device_index("..name..")")

	local idx = self.get_list_index(self,"dpx_browser_input_device",name)
	self.vb.views.dpx_browser_input_device.value = idx

end

-- set the active input device
-- * instantiate the new device 
-- * load dedicated class if it exists
-- * filter applications
-- @param name (string)	the name of the device, as it is printed
--						in the popup device selector list
-- @param silent (boolean) skip the 

function Browser:set_device(name)
--print("Browser:set_device("..name..")")

	local idx = self.get_list_index(self,"dpx_browser_input_device",name)
	self.vb.views.dpx_browser_input_device.value = idx

	if self.device then
		self.device.release(self.device)
		self.display.hide_control_surface(self.display)
	end

	-- "cascading" effect
	self.set_application(self,"None")

	if (name == "None") then
		self.vb.views.dpx_browser_app_row.visible = false
		self.vb.views.dpx_browser_device_settings.visible = false
		return	
	else
		self.vb.views.dpx_browser_app_row.visible = true
		self.vb.views.dpx_browser_device_settings.visible = true

	end

	local custom_devices = self.get_custom_devices(self)
	for _,k in ipairs(custom_devices) do
	
		if (name==k.display_name) then
			if k.classname then
				--print("Dedicated class support",name)
				self.instantiate_device(self,k.class_name)
			elseif k.control_map then

				local generic_class = nil
				if(k.protocol == DEVICE_MIDI_PROTOCOL)then
					generic_class = "MidiDevice"
				elseif(k.protocol == DEVICE_OSC_PROTOCOL)then
					generic_class = "OSCDevice"
				end

				local class_name = k.class_name or generic_class
				--print("Control-mapped support",class_name)
				self.instantiate_device(self,class_name)
			else
				alert("Whoops! This device needs a control-map")
			end
		end
		
	end

end


-- instantiate a device from it's basic information
-- TODO on-the-fly loading of classes 

function Browser:instantiate_device(class_name)
--print("Browser:instantiate_device:",class_name)

	if class_name == 'Launchpad' then

		self.device = Launchpad('Launchpad')
		self.device:set_controller_map("launchpad.xml")
		self.device.message_stream = self.stream

		self.display = Display(self.device)
		self.display.build_control_surface(self.display)
		self.vb.views.dpx_browser_rootnode:add_child(self.display.view)
		self.display.show_control_surface(self.display)

	end
	if class_name == 'Nocturn' then

		

	end

end


--	return list of valid devices plus a "none" option
--	include devices that match the device name (dedicated classes)
--	and/or has a control-map (as this enables the control surface)

function Browser:get_devices()

	local tmp = nil
	local rslt = {"None"}

	local input_devices = renoise.Midi.available_input_devices()
	local custom_devices = self.get_custom_devices(self)

	-- add custom devices 
	--table.insert(rslt, "--------  custom devices  ---------")
	for idx,t in ipairs(custom_devices) do
		for _,k in ripairs(input_devices) do
			if (string.sub(k,0,string.len(t.device_name))==t.device_name) then
				table.insert(rslt, t.display_name)
				table.remove(custom_devices,idx) -- remove from list
			end
		end
	end
	-- seperator
	--table.insert(rslt, "----  control-mapped devices  -----")
	-- add control-mapped devices 
	for _,t in ipairs(custom_devices) do
		if (t.control_map) then
			table.insert(rslt, t.display_name)
		end
	end

	return rslt

end

function Browser:get_list_index(view_elm,name)

	local elm = self.vb.views[view_elm]
	for idx,val in ipairs(elm.items)do
		if name == val then
			return idx
		end
	end
	print("could not load the item "..name)
	return 1

end


--	todo: check for "real" device config-files
--	@class_name : determine the class to instantiate
--	@display_name : the name listed in the popup 
--	@device_name : the device name, as reported by the os
--	@control_map : name of the default control-map

function Browser:get_custom_devices()

	return {
		--	this is a fullblown implementation (class + control-map)
		--  the class tell us of the hardware capabilities
		{
			class_name="Launchpad",			
			display_name="Launchpad",
			device_name="Launchpad",
			control_map="launchpad.xml",
			protocol=DEVICE_MIDI_PROTOCOL,
		},
		--	here, device_name is different from display_name 
		--	it should load as a generic MIDI device
		{
			class_name=nil,
			display_name="Nocturn",			
			device_name="Automap MIDI",		
			control_map="nocturn.xml",
			protocol=DEVICE_MIDI_PROTOCOL,
		},
		--	this is a defunkt implementation (no control-map)
		--	will cause a warning once it's opened
		{
			class_name=nil,					
			display_name="Remote SL",
			device_name="Automap MIDI",	
			control_map=nil,
			protocol=DEVICE_MIDI_PROTOCOL,
		},
		--	another generic implementation (no class-name)
		--	should load as a generic MIDI device
		{
			class_name=nil,					
			display_name="Behringer BCF2000",
			device_name="BCF2000",	-- ? 
			control_map="bcf2000.xml",
			protocol=DEVICE_MIDI_PROTOCOL,
		},
		--	and here I don't really know how to list osc clients?
		{
			class_name=nil,					
			display_name="mrmr",
			device_name="mrmr",
			control_map="mrmr.xml",
			protocol=DEVICE_OSC_PROTOCOL,
		},
	}

end


-- return list of supported applications
-- TODO filter applications by device
-- @param (string)	device_name: show only scripts that are  
--					guaranteed to work with this device

function Browser:get_applications(device_name)

	return {
		"None",
		"MixConsole",
		"PatternMatrix",
	}
	
end

--	return list of application presets
function Browser:get_presets()

	return {
		"None",
		"Normal (all buttons)",
		"Grid only",
		"Grid+Triggers"
	}

end


-- set application as active item 
-- currently, we display only a single app at a time
-- but it should be possible to run several apps!

function Browser:set_application(name)
--print("Browser:set_application:",name)
	--renoise.app():show_warning("not yet implemented")

	self.vb.views.dpx_browser_application.value = self.get_list_index(self,"dpx_browser_application",name)
	self.vb.views.dpx_browser_application_checkbox.value = false

	if self.application then
		self.application.destroy_app(self.application)
	end

	-- hide/show the "run" option
	if self.vb.views.dpx_browser_application.value == 1 then
		self.vb.views.dpx_browser_application_active.visible = false
		--self.display.clear(self.display)
	else
		self.vb.views.dpx_browser_application_active.visible = true
	end

	-- TODO load classes dynamically
	if name == "MixConsole" then
		self.application = MixConsole(self.display)
	end
	if name == "PatternMatrix" then
		self.application = PatternMatrix(self.display)
	end


end


-- TODO apply preset to application
-- application needs to expose parameters somehow...
function Browser:set_preset()
	renoise.app():show_warning("not yet implemented")
end

-- construct the browser "view" 
function Browser:build_browser()

	local input_devices = self.get_devices(self)
	local applications = self.get_applications(self)
	local presets = self.get_presets(self)

	--local vb = renoise.ViewBuilder()
	vb = self.vb
	self.view = vb:column{
		--margin = DEFAULT_MARGIN,
		id = 'dpx_browser_rootnode',
		style = "body",
		width = 400,
		vb:row{
			margin = DEFAULT_MARGIN,
			vb:text{
					text="Device",
					width=60,
			},
			vb:popup{
					id='dpx_browser_input_device',
					items=input_devices,
					--value=4,
					width=200,
					notifier=function(e)
						self.set_device(self,input_devices[e])
					end
			},
			vb:button{
					id='dpx_browser_device_settings',
					text="Settings",
					--visible=false,
			},
		},
		vb:row{
			margin = DEFAULT_MARGIN,
			id= 'dpx_browser_app_row',
			--visible=false,
			vb:text{
					text="Application",
					width=60,
			},
			vb:popup{
					id='dpx_browser_application',
					items=applications,
					value=1,
					width=200,
					notifier=function(e)
						self.set_application(self,applications[e])
					end
			},
			vb:row{
				id='dpx_browser_application_active',
				visible=false,
				vb:checkbox{
						value=false,
						id='dpx_browser_application_checkbox',
						notifier=function(e)
							if e then
								self.start_app(self)
							else
								self.stop_app(self)
							end
						end
				},
				vb:text{
						text="Run",
				},
			},
		},
		vb:row{
			margin = DEFAULT_MARGIN,
			id= 'dpx_browser_preset_row',
			visible=false,
			vb:text{
					text="Preset",
					width=60,
			},
			vb:popup{
					items=presets,
					value=1,
					width=200,
					notifier=function(e)
						self.set_preset(self,presets[e])
					end
			},
			vb:checkbox{
					value=false,
			},
			vb:text{
					text="Edit",
			},

		},
		-- the following is used to control initial size of dialog
		vb:button{
			id='dpx_browser_fix',
			width=400,
			height=400,
			text="BOOM",
		},
	}
end

-------  class methods ----------

function Browser:start_app()

	Application.start_app(self)

	if self.application then
		self.application.start_app(self.application)
	end
	

end


function Browser:stop_app()

	Application.stop_app(self)

	if self.application then
		self.application.stop_app(self.application)
	end

end


function Browser:idle_app()

	if not self.active then
		return
	end

	if self.display then
		self.display.update(self.display)
	end

	if self.application then
		self.application.idle_app(self.application,self.display)
	end

end
