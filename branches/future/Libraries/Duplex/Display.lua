--[[----------------------------------------------------------------------------
-- Duplex.Display
----------------------------------------------------------------------------]]--

--[[

The Display is the base class for building device displays


--]]

module("Duplex", package.seeall);

class 'Display' 

local BUTTON_HEIGHT = 32
local BUTTON_WIDTH = 32

function Display:__init(device)
--print('"Display"')

	self.device = device	

	--	viewbuilder stuff
	self.vb = renoise.ViewBuilder()
	self.view = nil		

	--	temp values used during construction of control surface
	self.parents = {}
	self.grid_obj = nil		
	self.grid_count = 0
	--self.grid_columns = nil

	-- array of DisplayObject instances
	self.ui_objects = {}	

	-- each UI object notifier method is referenced by id, 
	-- so we can attach/detach the method when we need
	self.ui_notifiers = {}	

	-- "palette" is a table of named color-constants 
	self.palette = {
		background = {
			text="·",
			color={0x00,0x00,0x00}
		},
		color_1 = {
			text="■",
			color={0xff,0xff,0x00}
		},
		color_1_dimmed = {
			text="□",
			color={0x40,0x40,0x00}
		},
		color_2 = {
			text="▪",
			color={0x80,0x80,0x00}
		},
		color_2_dimmed = {
			text="▫",
			color={0x40,0x40,0x00}
		},
	}		

end

function Display:add(obj_instance)
--print('Display.add:')

	table.insert(self.ui_objects,#self.ui_objects+1,obj_instance)

end

-- TODO: clear display
-- use hardware-specific feature if possible

function Display:clear()
--print("Display:clear()")
	for _,group in pairs(self.device.control_map.groups)do

		for __,param in ipairs(group) do

			--rprint(param)
-- @elm : control-map definition of the element
-- @obj : reference to the DisplayObject instance
-- @point : canvas point containing text/value/color 
--[[
			local pt = Point()
			local obj = {ceiling=100}
			self.set_parameter(param,obj,pt)
--rprint(param)			
]]
		end

	end

end


-- update: will update virtual/hardware displays

function Display:update()

	if not self.view then
		return
	end

	for i,obj in ipairs(self.ui_objects) do
		if obj.dirty then

			-- update the object display
			obj.draw(obj)

			-- loop through the delta array - it contains all recent updates
			if obj.canvas.has_changed then
				for x = 1,obj.width do
					for y = 1, obj.height do
						if obj.canvas.delta[x][y] then
							local columns = self.device.control_map.groups[obj.group_name].columns
							local idx = (x+obj.x_pos-1)+((y+obj.y_pos-2)*columns)
							local elm = self.device.control_map.get_indexed_element(self.device.control_map,idx,obj.group_name)
							if elm then
								self.set_parameter(self,elm,obj,obj.canvas.delta[x][y])
							end
						end
					end
				end
				obj.canvas.clear_delta(obj.canvas)
			end

		end
	end

end

-- TODO set_device, 
--	update virtual control surface automatically
--[[
function Display:set_device

end
]]

-- set_parameter: update object states
-- @elm : control-map definition of the element
-- @obj : reference to the DisplayObject instance
-- @point : canvas point containing text/value/color 

function Display:set_parameter(elm,obj,point)
--print('Display:set_parameter',elm.name,elm.value,point.text)
--objinfo(point)

	local widget = nil
	local value = nil
	local num = nil

	-- update hardware display

	if self.device then 
		local msg_type = self.device.control_map.determine_type(self.device.control_map,elm.value)
		if msg_type == MIDI_NOTE_MESSAGE then
			num = self.device.extract_midi_note(self.device,elm.value)
			value = self.device.color_to_value(self.device,point.color)
			self.device.send_note_message(self.device,num,value)
		elseif msg_type == MIDI_CC_MESSAGE then
			num = self.device.extract_midi_cc(self.device,elm.value)
			value = self.device.color_to_value(self.device,point.color)
			self.device.send_cc_message(self.device,num,value)
		end
	end

	-- update virtual control surface
	if self.vb and self.vb.views then 
		widget = self.vb.views[elm.id]
	end
	if widget then
		if type(widget)=="Button" then
			widget.text = point.text
		end
		if type(widget)=="MiniSlider" then
			if(type(point.val)=="boolean")then
				if point.val then
					value = elm.maximum
				else
					value = elm.minimum
				end
			else
				-- scale the value from "local" to "external"
				-- for instance, from Renoise dB range (1.4125375747681) 
				-- to a 7-bit controller value (127)
				value = math.floor((point.val*(1/obj.ceiling))*elm.maximum)
			end
			widget.remove_notifier(widget,self.ui_notifiers[elm.id])
			widget.value = value*1 -- toNumber
			widget.add_notifier(widget,self.ui_notifiers[elm.id])
		end
	end

end

function Display:show_control_surface()
--print('Display:show_control_surface')

--[[
	if self.dialog and self.dialog.visible then
		self.dialog:show()
		return
	end
]]
	-- build the virtual control surface?
	if not self.view then
		self.build_control_surface(self)
	end
--[[
	self.dialog = renoise.app():show_custom_dialog(
		"Duplex",self.view
	)
	self.dialog:show()
]]
	self.vb.views.display_rootnode.visible = true

end


function Display:hide_control_surface()

	--self.dialog:close()
	self.vb.views.display_rootnode.visible = false

end


--	build the virtual control-surface
--  based on the parsed control-map

function Display:build_control_surface()
--print('Display:build_control_surface')

	self.view = self.vb:column{
		id="display_rootnode",
		style="invisible",
		margin = DEFAULT_MARGIN,
		spacing = 6,
	}
	self.walk_table(self,self.device.control_map.definition)

end


--	generate_message
--	@value : the value
--	@metadata : metadata table (min/max etc.)

function Display:generate_message(value, metadata)
--print('Display:generate_message:'..value)

	local msg = Message()
	msg.context = self.device.control_map.determine_type(self.device.control_map,metadata.value)
	msg.value = value

	-- input method
	if metadata.type == "button" then
		msg.input_method = CONTROLLER_BUTTON
	elseif metadata.type == "encoder" then
		msg.input_method = CONTROLLER_ENCODER
	end

	-- include additional meta-properties
	msg.name	= metadata.name
	msg.group_name = metadata.group_name
	msg.max		= metadata.maximum+0
	msg.min		= metadata.minimum+0
	msg.id		= metadata.id
	msg.index	= metadata.index
	msg.column	= metadata.column
	msg.row		= metadata.row
	msg.timestamp = os.clock()

	self.device.message_stream.input_message(self.device.message_stream,msg)

end

--	walk_table: create the virtual control surface
--	iterate through the control-map, while adding/collecting 
--	relevant meta-information 

function Display:walk_table(t, done, deep)

	deep = deep or 0	--	the nesting level
	deep = deep +1
	done = done or {}

	for key, value in pairs (t) do
		if type (value) == "table" and not done [value] then
		done [value] = true
		local grid_id = nil
		local view_obj = {
			meta = t[key].xarg	-- xml attributes
		}
		if t[key].label=="Param" then
			-- the parameters
			local notifier = nil
			local tooltip = string.format("%s (%s)",view_obj.meta.name,view_obj.meta.value)
			if t[key].xarg.type == "button" then
				notifier = function(value) 
					-- output the maximum value
					self.generate_message(self,view_obj.meta.maximum*1,view_obj.meta)
				end
				self.ui_notifiers[t[key].xarg.id] = notifier
				view_obj.view = self.vb:button{
					id=t[key].xarg.id,
					height=BUTTON_HEIGHT,
					width=BUTTON_WIDTH,
					tooltip = tooltip,
					notifier = notifier
				}
			elseif t[key].xarg.type == "encoder" then
				notifier = function(value) 
					-- output the current value
					self.generate_message(self,value,view_obj.meta)
				end
				self.ui_notifiers[t[key].xarg.id] = notifier
				view_obj.view = self.vb:minislider{
					id=t[key].xarg.id,
					min = view_obj.meta.minimum+0,
					max = view_obj.meta.maximum+0,
					tooltip = tooltip,
					height=BUTTON_HEIGHT/1.5,
					width = BUTTON_WIDTH,
					notifier = notifier
				}
			end
		elseif t[key].label=="Column" then
			view_obj.view = self.vb:column{
				style="invisible",
				spacing=DEFAULT_SPACING
			}
			self.parents[deep] = view_obj
		elseif t[key].label=="Row" then
			view_obj.view = self.vb:row{
				style="invisible",
				spacing=DEFAULT_SPACING,
			}
			self.parents[deep] = view_obj
		elseif t[key].label=="Group" then
			-- the group
			local orientation = t[key].xarg.orientation
			local columns = t[key].xarg.columns
			if columns then
				-- enter "grid mode": use current group as 
				-- base object for inserting multiple rows
				self.grid_count = self.grid_count+1
				grid_id = string.format("grid_%i",self.grid_count)
				orientation = "vertical"
			else
				-- exit "grid mode"
				self.grid_obj = nil
			end
			if orientation=="vertical" then
				view_obj.view = self.vb:column{
					style="group",
					id=grid_id,
					margin=DEFAULT_MARGIN,
					spacing=DEFAULT_SPACING,
				}
			else
				view_obj.view = self.vb:row{
					style="group",
					id=grid_id,
					margin=DEFAULT_MARGIN,
					spacing=DEFAULT_SPACING,
				}
			end
			-- more grid mode stuff: remember the original view_obj
			-- grid mode will otherwise loose this reference...
			if grid_id then
				self.grid_obj = view_obj
			end
			self.parents[deep] = view_obj
		end
		-- something was matched
		if view_obj.view then
			-- grid mode: create a(nother) row ?
			local row_id = nil
			if view_obj.meta.row then
				row_id = string.format("grid_%i_row_%i",self.grid_count,view_obj.meta.row)
			end
			if not grid_id and self.grid_obj and not self.vb.views[row_id] then
				local row_obj = {
					view = self.vb:row{
						id=row_id,
						spacing=DEFAULT_SPACING,
					}
				}
				-- assign grid objects to this row
				self.grid_obj.view:add_child(row_obj.view)
				self.parents[deep-1] = row_obj
			end
			-- attach to parent object (if it exists)
			local added = false
			for i = deep-1,1,-1 do
				if self.parents[i] then
					self.parents[i].view:add_child(view_obj.view)
					added = true
					break
				end
			end
			-- else, add to main view
			if not added then
				self.view:add_child(view_obj.view)
			end
		end
		self.walk_table (self,value, done, deep)
	end
  end
end
