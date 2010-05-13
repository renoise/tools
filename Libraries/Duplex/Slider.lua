--[[----------------------------------------------------------------------------
-- Duplex.Slider
----------------------------------------------------------------------------]]--

--[[

Inheritance: DisplayObject > Slider

- combine controls in order to form a single slider 
- display in horizontal and vertical orientation
- different input methods: buttons or sliders/encoders
- axis flipping (reverse the up/down direction)
- 

--]]

module("Slider", package.seeall);

class 'Slider' (DisplayObject)

function Slider:__init(display)
--print('"Slider"')

	DisplayObject.__init(self,display)

	-- 0 is empty (default)
	self.size = 0

	-- the selected index (0 is deselected)
	self.selected_index = 0

	-- if true, press twice to switch to deselected state*
	self.toggleable = false

	-- paint a dimmed version*
	self.dimmed = false

	-- current value (sliders/encoders offer more precision)
	self.value = 0

	-- the maximum value (between 0 and "ceiling")
	self.ceiling = 1

	-- slider is vertical or horizontal?
	self.orientation = VERTICAL 

	-- flip top/bottom direction 
	self.flipped = false

	--	* this only applies when input method is a button

	self.add_listeners(self)

	self.palette = {
		background = deepcopy(display.palette.background),
		foreground = deepcopy(display.palette.color_1),
		foreground_dimmed = deepcopy(display.palette.color_1_dimmed),
		medium = deepcopy(display.palette.color_2),
		medium_dimmed = deepcopy(display.palette.color_2_dimmed),
	}


end


-- user input via button: 
-- set index

function Slider:do_press()

	local idx = nil
	local msg = self.get_msg(self)

	if not (self.group_name == msg.group_name) then
		return
	end
	if not self.test(self,msg.column,msg.row) then
		return
	end

	idx = self.determine_index_by_pos(self,msg.column,msg.row)

	if self.toggleable then
		if self.selected_index == idx then
			idx = 0
		end
	end

	self.set_index(self,idx)

end


-- user input via slider, encoder: 
-- set index + precise value

function Slider:do_change()
--print("Slider:do_change()")

	local msg = self.get_msg(self)

	if not (self.group_name == msg.group_name) then
		return
	end
	if not self.test(self,msg.column,msg.row) then
		return
	end

	local idx = self.determine_index_by_pos(self,msg.column,msg.row)
	local tmp = (msg.value/msg.max)*self.ceiling/self.size
	local rslt = (self.ceiling/self.size)*(idx-1)+tmp
	self.set_value(self,rslt)
end


-- determine index by position, depends on orientation
-- @column (integer)
-- @row (integer)

function Slider:determine_index_by_pos(column,row)

	local pos,offset = nil,nil

	if self.orientation == VERTICAL then
		pos = row
		offset = self.y_pos
	else
		pos = column
		offset = self.x_pos
	end
	if not self.flipped then
		pos = self.size-pos+1
	end
	local idx = pos-(offset-1)

	return idx

end

-- setting the size will change the canvas too
-- @size (integer)

function Slider:set_size(size)

	self.size = size

	if self.orientation == VERTICAL then
		DisplayObject.set_size(self,1,size)
	else
		DisplayObject.set_size(self,size,1)
	end

end


-- setting precise value will also set index
-- @val (float) 
-- @silent (bool) - skip event

function Slider:set_value(val,silent)

	self.value = val

	local idx = math.ceil((self.size/self.ceiling)*val)

	self.selected_index = idx
	self.invalidate(self)

	if not silent and self.on_change then
		self.on_change(self)
	end

end

-- setting index will also set value
-- @idx (integer) 
-- @silent (bool) - skip event

function Slider:set_index(idx,silent)
--print("Slider:set_index:",idx,silent)

	-- todo: cap value

	self.selected_index = idx
	--self.invalidate(self)
	self.value = (self.ceiling/self.size)*idx
	self.invalidate(self)

	if not silent and self.on_change then
		self.on_change(self)
	end

end


function Slider:set_dimmed(bool)
	self.dimmed = bool
	self.invalidate(self)
end



function Slider:draw()
--print("Slider:draw:",self.selected_index)
	
	local x,y,value
	local idx = self.selected_index

	if not self.flipped then
		idx = self.size-idx+1
	end

	for i = 1,self.size do
		
		x,y = 1,1

		point = Point()

		point.apply(point,self.palette.background)

		if idx then

			if i == idx then

				-- figure out the offset within the "step",
				-- going from 0 to .ceiling value
				local step = self.ceiling/self.size
				local offset = self.value-(step*(self.selected_index-1))
				point.val = offset*(1/step)*self.ceiling

				if self.dimmed then
					point.apply(point,self.palette.foreground_dimmed)
				else
					point.apply(point,self.palette.foreground)
				end

			elseif self.flipped then
				if(i <= idx)then
					point.val = true
					if self.dimmed then
						point.apply(point,self.palette.medium_dimmed)
					else
						point.apply(point,self.palette.medium)
					end
				end

			elseif ((self.size-i) < self.selected_index) then

				point.val = true
				if self.dimmed then
					point.apply(point,self.palette.medium_dimmed)
				else
					point.apply(point,self.palette.medium)
				end

			end
		end

		if self.orientation == VERTICAL then 
			y = i
		else
			x = i  
		end
		self.canvas.write(self.canvas,point,x,y)
	end

	DisplayObject.draw(self)

end

function Slider:add_listeners()

	self.display.device.message_stream:add_listener(self,DEVICE_EVENT_BUTTON_PRESSED,function() self.do_press(self,self) end )
	self.display.device.message_stream:add_listener(self,DEVICE_EVENT_VALUE_CHANGED,function() self.do_change(self,self) end )

end

function Slider:remove_listeners()

	self.display.device.message_stream:remove_listener(self,DEVICE_EVENT_BUTTON_PRESSED)
	self.display.device.message_stream:remove_listener(self,DEVICE_EVENT_VALUE_CHANGED)

end
