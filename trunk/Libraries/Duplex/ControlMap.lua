--[[----------------------------------------------------------------------------
-- Duplex.ControlMap
----------------------------------------------------------------------------]]--

--[[
Requires: Globals

Used for describing the layout of devices
- import and parse external XML data

Notes on the syntax of external XML :
- Supported elements: <Row>, <Column>, <Group> and <Param>
- <Group> nodes cannot be nested 
- Only <Param> node are supported inside a <Group> node
- Use <Row> and <Column> nodes for controlling the layout 
- Underscore not allowed in attribute names
- Indicate grid layout by supplying a "column" attribute for a <Group> node
- - Note that orientation is then ignored (using grid layout)
- Use "size" attribute with controls of certain type (sliders)

--]]

module("Duplex", package.seeall);

class 'ControlMap' 

function ControlMap:__init()
--print('"ControlMap"')

	self.id = nil			-- unique id assigned to parameters
	self.definition = nil	-- the xml parsed into a table
	self.groups = {}		-- table: {"Group1"=>{0,1,2...},"Another group"=>{10,11}}

end


-- load_definition: load and parse xml
-- @param file_path (string) the name of the file, e.g. "my_map.xml"

function ControlMap:load_definition(file_path)
print("ControlMap:load_definition:",MODULE_PATH..file_path)
	local xml_string = self.read_file(self,MODULE_PATH..file_path)
	self.parse_definition(self,xml_string)
end

-- parse the supplied xml string (reset the counter first)
function ControlMap:parse_definition(xml_string)
	self.id = 0
	self.definition = self.parse_xml(self,xml_string)
end


function ControlMap:get_indexed_element(index,group_name)
	if self.groups[group_name] then
		return self.groups[group_name][index].xarg
	end
end

-- get_element_by_value() 
-- this retrieves a parameter by it's value-string
-- @return table

function ControlMap:get_param_by_value(str)
--print("ControlMap:get_param_by_value",str)

	for _,__ in pairs(self.groups) do
		for k,v in ipairs(__) do
			if v["xarg"]["value"] == str then
				return v
			end
		end
	end
end


function ControlMap:read_file(file_path)
	local file_ref,err = io.open(file_path,"r")
	if (not err) then
		local rslt=file_ref:read("*a")
		io.close(file_ref)
		return rslt
	else
		return nil,err;
	end
end


-- Determine the type of message (OSC/Note/CC)
-- @return integer (e.g. MIDI_NOTE_MESSAGE)

function ControlMap:determine_type(str)
	
	if string.sub(str,0,1)=="/" then
		return OSC_MESSAGE
	elseif string.sub(str,1,2)=="CC" then
		return MIDI_CC_MESSAGE
	elseif string.sub(str,2,2)=="#" or string.sub(str,2,2)=="-" then
		return MIDI_NOTE_MESSAGE
	end

end


-- Parse the control-map, and add runtime
-- information (element id's and group names)

function ControlMap:parse_xml(s)
--print('ControlMap:parse_xml(...)')

	local stack = {}
	local top = {}
	table.insert(stack, top)
	local ni,c,label,xarg, empty
	local i, j = 1, 1
	local index = 1
	local function parseargs(s)
		local arg = {}
		string.gsub(s, "(%w+)=([\"'])(.-)%2", function (w, _, a)
			arg[w] = a
		end)

		-- meta-attr: add unique id for every node
		arg.id = string.format("%d",self.id)
		self.id = self.id+1

		return arg
	end
	while true do
		ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%w:]+)(.-)(%/?)>", i)
		if not ni then break end
		local text = string.sub(s, i, ni-1)
		if not string.find(text, "^%s*$") then
			table.insert(top, text)
		end
		if empty == "/" then  -- empty element tag

			local xargs=parseargs(xarg)

			-- meta-attr: index each <Param> node
			if label=="Param" then
				xargs.index = index
				index = index+1
			end

			table.insert(top, {label=label, xarg=xargs, empty=1})
		elseif c == "" then   -- start tag
			top = {label=label, xarg=parseargs(xarg)}
			table.insert(stack, top)   -- new level
		else  -- end tag
			local toclose = table.remove(stack)  -- remove top
			top = stack[#stack]
			if #stack < 1 then
				error("nothing to close with "..label)
			end
			if toclose.label ~= label then
				error("trying to close "..toclose.label.." with "..label)
			end
			table.insert(top, toclose)

			-- meta-attr : columns and rows
			if label == "Group" then
				-- add "columns" attribute to *all* groups
				local columns = nil
				if not toclose.xarg.columns then
					if toclose.xarg.orientation and toclose.xarg.orientation == "vertical" then
						columns = 1
					else
						columns = #toclose
					end
				else 
					columns =  toclose.xarg.columns*1	-- toNumber
				end
				toclose.columns = columns
				local counter = 0
				local row_counter = 0
				for key,val in ipairs(toclose) do
					-- add "group_name" to all members
					toclose[key].xarg.group_name =  toclose.xarg.name
					-- figure out active row/column
					toclose[key].xarg.column = counter+1
					toclose[key].xarg.row = math.floor(((toclose[key].xarg.index-1)/columns)+1)
					counter = counter+1
					if counter >= columns then
						row_counter = row_counter+1
						counter = 0
					end
				end
				self.groups[toclose.xarg.name]=toclose
			end
			-- reset index
			index = 1

		end
		i = j+1
	end
	local text = string.sub(s, i)
	if not string.find(text, "^%s*$") then
		table.insert(stack[#stack], text)
	end
	if #stack > 1 then
		error("unclosed "..stack[stack.n].label)
	end
	return stack[1]
end




