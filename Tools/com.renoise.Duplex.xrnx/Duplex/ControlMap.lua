--[[----------------------------------------------------------------------------
-- Duplex.ControlMap
----------------------------------------------------------------------------]]--

--[[

Requires: Globals

About:

  Essentially, the ControlMap class will import a control-map file, and add 
  some extra methods, more handy methods for accessing the groups. 

Notes on the XML syntax:

  - Supported elements are: <Row>, <Column>, <Group> and <Param>
  
  - <Group> nodes cannot be nested 
  
  - Only <Param> nodes are supported inside a <Group> node
  
  - Use <Row> and <Column> nodes for controlling the layout 
    - Use "orientation" attribute to control vertical/horizontal layout 
  
  - Indicate grid layout by supplying a "column" attribute for a <Group> node
    - Note that orientation is then ignored (using a grid layout)
  
  - Use "size" attribute to control the unit size of certain controls like 
    sliders

--]]


--==============================================================================

class 'ControlMap' 

--------------------------------------------------------------------------------

--- Initializate the ControlMap class

function ControlMap:__init()
  TRACE("ControlMap:__init")

  -- groups by name, e.g. self.groups["Triggers"]
  self.groups = table.create() 

  -- remember the name (this is a 'read-only' property, 
  -- setting it will not do anything useful)
  self.file_path = ""

  -- remember matched patterns (optimize)
  self.midi_buffer = table.create()
  self.osc_buffer = table.create()

  -- unique id, reset each time a control-map is parsed
  self.id = nil 

  -- control-map parsed into table
  self.definition = nil 

end


--------------------------------------------------------------------------------

--- Load_definition: load and parse xml
-- @param file_path (String) the name of the file, e.g. "my_map.xml"

function ControlMap:load_definition(file_path)
  TRACE("ControlMap:load_definition",file_path)

  self.file_path = file_path
  
  -- try to find the controller definition in the package path
  local package_paths = {}
  package.path:gsub("([^;]*)", function(str) 
    if (#str > 1) then table.insert(package_paths, str) end
  end)
  
  for _,path in pairs(package_paths) do
    local lib_path_base = path:gsub("?.lua", "")
 
    if io.exists(lib_path_base .. "/Duplex/" .. file_path) then
      file_path = lib_path_base .. "/Duplex/" .. file_path
      break
    end
    
    if (io.exists(lib_path_base .. file_path)) then
      file_path = lib_path_base .. file_path
      break
    end
  end
       
  -- load the control-map
  if io.exists(file_path) then
    TRACE("ControlMap:load_definition:", file_path)
    
    local xml_string = self.read_file(self, file_path)
    self:parse_definition(file_path, xml_string)
  
  else
    renoise.app():show_error(
      ("Failed to load controller definition file: '%s'. " ..
       "The controller is not available."):format(file_path))
  end
end


--------------------------------------------------------------------------------

--- Parse the supplied xml string (reset the counter first)
-- @param control_map_name (String) path to XML file
-- @param xml_string (String) the XML string

function ControlMap:parse_definition(control_map_name, xml_string)
  --TRACE("ControlMap:parse_definition",control_map_name, xml_string)

  self.id = 0

  -- must guard any file io access. may fail, and we don't want to bother
  -- the user with cryptic LUA error messages then...
  local succeeded, result = pcall(function() 
    -- remove comments before parsing
    xml_string = string.gsub (xml_string, "(<!--.-->)", "")
    return self:_parse_xml(xml_string) 
  end)
  
  if (succeeded) then
    self.definition = result
  
  else
    renoise.app():show_error(
      ("Whoops! Failed to parse the controller definition file: "..
       "'%s'.\n\n%s"):format(control_map_name, result or "unknown error"))       
  end
end


--------------------------------------------------------------------------------

--- Retrieve <param> by position within group
-- @param index (Number) the index/position
-- @param group_name (String) the control-map group name
-- @return the <param> attributes array

function ControlMap:get_indexed_element(index,group_name)
  TRACE("ControlMap:get_indexed_element",index,group_name)

  if (self.groups[group_name] and self.groups[group_name][index]) then
    return self.groups[group_name][index].xarg
  end


  return nil
end


--------------------------------------------------------------------------------

--- Retrieve <param> in indicated group, supporting wildcard syntax
--  * group_name="Pad_1" and index=3 would collect the third parameter 
--    from the group named Pad_1
--  * group_name="Pad_1" and index=nil would collect all parameters
--    from the group named Pad_1
--  * group_name="Pad_*" and index=3 would collect the third parameter 
--    from groups Pad_1,Pad_2, etc.
--  * group_name="Pad_*" and index=nil would collect every parameter 
--    from groups Pad_1,Pad_2, etc.
-- @param group_name (String) the control-map group name
-- @param index (Number) optional index/position
-- @return the <param> attributes array

function ControlMap:get_params(group_name,index)
  TRACE("ControlMap:get_params",group_name,index)

  local params = table.create()

  -- perform wildcard search? 
  if group_name and string.find(group_name,"*") then

    -- loop through "more than enough" groups
    for count=1,9999 do

      local tmp_group_name = (group_name):gsub("*",count)
      --print("tmp_group_name",tmp_group_name)

      if not self.groups[tmp_group_name] then
        break
      else
        -- matched a group using wildcard 
        for k,v in ipairs(self.groups[tmp_group_name]) do
          if index then
            if (index == k) then
              -- collect indexed parameter
              --print("collect indexed parameter")
              params:insert(v.xarg)
            end
          else
            -- collect all parameters
            params:insert(v.xarg)
          end
        end
        --[[
        if (self.groups[tmp_group_name] and self.groups[tmp_group_name][index]) then
          params:insert(v.xarg)
        end
        ]]
      end
    end
  
  else -- non-wildcard matching
    if (self.groups[group_name]) then
      for k,v in ipairs(self.groups[group_name]) do
        if index then
          if (index == k) then
            params:insert(v.xarg)
          end
        else
          params:insert(v.xarg)
        end
      end
    end

  end

  if not table.is_empty(params) then
    return params
  else
    return nil
  end


end


--------------------------------------------------------------------------------

--- Parse a string into a colorspace table
-- @param str (String) a comma-separated string of RGB values, e.g. "4,4,0" 
-- @return Table

function ControlMap:import_colorspace(str)
  TRACE("ControlMap:import_colorspace",str)

  local rslt = table.create()
  rslt:insert(tonumber(string.sub(str,1,1)))
  rslt:insert(tonumber(string.sub(str,3,3)))
  rslt:insert(tonumber(string.sub(str,5,5)))
  return rslt

end

--------------------------------------------------------------------------------

--- Get parameters by value: 
-- used by the MidiDevice to retrieves a parameter by it's note/cc-value-string.
-- The function will match values on the default channel, if not defined:
-- "CC#105|Ch1" will match both "CC#105|Ch1" and "CC#105". 
-- Also, we have wildcard support: 
-- "C#*|Ch1" will match both "C#1|Ch1" and "C#5" 
-- @param str (string, control-map value attribute)
-- @param msg_context (String/Enum) the message context, e.g. MIDI_NOTE_MESSAGE
-- @return Table containing matched parameters

function ControlMap:get_params_by_value(str,msg_context)
  TRACE("ControlMap:get_params_by_value",str,msg_context)

  local matches = table.create()

  --print("get_params_by_value",str,msg_context)

  -- check if we have previously matched the pattern
  if (self.midi_buffer[str]) then
    return self.midi_buffer[str] 
  end

  -- first, look for an exact match
  local str2 = strip_channel_info(str)
  for _,group in pairs(self.groups) do
    for k,v in ipairs(group) do
      -- check if we are dealing with an octave wildcard
      -- (method will only work with range -1 to 9)
      local match_against = v["xarg"]["value"]
      if (msg_context == MIDI_NOTE_MESSAGE) and (v["xarg"]["value"]):find("*") then
        local oct = str2:sub(#str2-1,#str2)
        if (oct~="-1") then
          oct = str2:sub(#str2)
        end
        match_against = (v["xarg"]["value"]):gsub("*",oct)
      end
      if (match_against == str) or (match_against == str2) then
        matches:insert(v)
      end
    end
  end

  -- next, match keyboard (no note information)
  if (msg_context == MIDI_NOTE_MESSAGE) then
    local str2 = strip_note_info(str)
    for _,group in pairs(self.groups) do
      for k,v in ipairs(group) do
        -- check if we already have matched the value
        local skip = false
        for k2,v2 in ipairs(matches) do
          if (v2["xarg"]["value"] == v["xarg"]["value"]) then
            skip = true
          end
        end
        if not skip and 
          (v["xarg"]["value"] == str) or 
          (v["xarg"]["value"] == str2) or
          (v["xarg"]["value"] == "|") -- match any channel
        then
          matches:insert(v)
        end
      end
    end
  end

  -- remember match 
  self.midi_buffer[str] = matches

  return matches

end


--------------------------------------------------------------------------------

--- Get OSC parameters: 
-- retrieve a parameter by matching it's "value" or "action" attribute, 
-- with pattern-matching for particular types of values:
-- "/press 1 %i" matches "/press 1 1" but not "/press 1 A"
-- "/pre** 1 %f" matches "/press 1 1" and "/preff 10 1.42"
--
-- the method will match the action property if it's available, otherwise 
-- the "value" property (the action property is needed when a device 
-- transmit a different outgoing than incoming value)
-- 
-- @param str (string, control-map value/action attribute)
-- @return  Table (<Param> node),
--          values (table), if matched against a wildcard,
--          wildcard_idx (integer), the matched index
--          replace_char (string), the characters to insert

function ControlMap:get_osc_param(str)
  TRACE("ControlMap:get_osc_param",str)

  -- check if we have previously matched the pattern
  if self.osc_buffer[str] then
    local buf = self.osc_buffer[str]
    return buf[1],buf[2],buf[3],buf[4]
  end

  -- split incoming message into parts, separated by whitespace
  local str_table = table.create()
  for v in string.gmatch(str,"[^%s]+") do
    str_table:insert(v)
  end

  local wildcard_idx = nil
  local replace_char = ""

  for _,group in pairs(self.groups) do
    for _,v in ipairs(group) do
      local str_prop = v["xarg"]["action"] or v["xarg"]["value"]
      if (str_prop) then

        -- split match into parts, separated by whitespace
        local prop_table = table.create()
        for p in string.gmatch(str_prop,"[^%s]+") do
          prop_table:insert(p)
        end
        local matched = true
        if (#str_table~=#prop_table) then
          -- ignore if different number of parts
          matched = false
        elseif(str_table[1]~=prop_table[1]) then
          -- ignore if different pattern, but first we 
          -- check of there's a wildcard present
          if (prop_table[1]):find("*",1,true) then
            local char2 = nil
            for i = 1,#str_table[1] do
              local char1 = (str_table[1]):sub(i,i)
              -- only proceed with source token when we have not yet
              -- found a wildcard 
              if (replace_char =="") then
                char2 = (prop_table[1]):sub(i,i)
              end
              if (char1~=char2) then
                -- capture the target parameter's index
                -- (as long as it's a number)
                if (char2 == "*") and ((char1):match("(%d*)")) then
                  wildcard_idx = i
                  replace_char = replace_char..char1
                  matched = true
                else
                  -- failed to match a character
                  matched = false
                  break
                end
              end
            end
          else
            --print("*** no wildcard detected")
            matched = false
          end
        end

        if matched then
          -- return matching group + extracted value
          local add_to_buffer = true
          local values = table.create()
          local ignore = false
          for o=2,#prop_table do
            if (not ignore) then
              if (prop_table[o]=="%f") then
                values:insert(tonumber(str_table[o]))
                add_to_buffer = false -- floats can't be buffered
              elseif (prop_table[o]=="%i") then
                values:insert(tonumber(str_table[o]))
              elseif (prop_table[o]~=str_table[o]) then
                -- wrong argument, ignore
                ignore = true
              end
            end
          end
          --rprint(values)
          if not ignore then
            if add_to_buffer then
              self.osc_buffer[str] = {v,values,wildcard_idx,replace_char}
            end
            return v,values,wildcard_idx,replace_char
          end

        end
      end
    end
  end


end


--------------------------------------------------------------------------------

--- Count number of columns for the provided group
-- @param group_name (String) the control-map group name, e.g. "Encoders"
-- @return Number

function ControlMap:count_columns(group_name)
  TRACE("ControlMap:count_columns",group_name)

  local group = self.groups[group_name]
  if (group) then
    if (group["columns"]) then
      return group["columns"]
    end
  end

end

--------------------------------------------------------------------------------

--- Count number of rows for the provided group
-- @param group_name (String) the control-map group name, e.g. "Encoders"
-- @return Number

function ControlMap:count_rows(group_name)
  TRACE("ControlMap:count_rows",group_name)

  local group = self.groups[group_name]
  if (group) then
    if (group["columns"]) then
      return math.ceil(#group/group["columns"])
    end
  end

end

--------------------------------------------------------------------------------

--- Count number of parameters in group
-- @param group_name (String) the control-map group name, e.g. "Encoders"
-- @return Number

function ControlMap:get_group_size(group_name)
  TRACE("ControlMap:get_group_size",group_name)

  return #self.groups[group_name]

end

--------------------------------------------------------------------------------

--- Get width/height of provided group
-- @param group_name (String) the control-map group name, e.g. "Encoders"
-- @return width (or nil if not matched)
-- @return height (or nil if not matched)

function ControlMap:get_group_dimensions(group_name)
  
  local group = self.groups[group_name]
  if (group) then
    for attr, param in pairs(group) do
      if (attr == "xarg") then
        --local width = tonumber(param["columns"])
        local width = tonumber(param["columns"])
        local height = math.ceil(#group / width)
        return width,height
      end
    end
  end
end

--------------------------------------------------------------------------------

--- Test if the group describe a grid group 
-- (meaning: it contains columns, and each member is a button)
-- @param group_name (String) the control-map group name, e.g. "Encoders"
-- @return boolean

function ControlMap:is_grid_group(group_name)
  
  local is_grid = true
  local group = self.groups[group_name]
  if (group) then
    -- look for "columns" group attribute
    --[[
    for attr, param in pairs(group) do
      if (attr == "xarg") then
        if (not param["columns"]) then
          return false
        end
      end
    end
    ]]
    -- check parameter type
    for _, param in ipairs(group) do
      if (param["xarg"] and param["xarg"]["type"]) then
        if not (param["xarg"]["type"]=="button") and
           not (param["xarg"]["type"]=="togglebutton") and
           not (param["xarg"]["type"]=="pushbutton") 
        then
          return false
        end
      end
    end
    return true
  end

end

--------------------------------------------------------------------------------

--- Test if the parameter describes a button
-- @param group_name (String) the control-map group name, e.g. "Encoders"
-- @param index (Number/Int) index within group
-- @return (Boolean) true if matched, false if not 

function ControlMap:is_button(group_name,index)
  
  -- use the first available index if nothing is specified
  if not index then
    index = 1
  end

  local group = self.groups[group_name]
  if (group) then
    local param = group[index]
    if (param["xarg"] and param["xarg"]["type"]) then
      if not (param["xarg"]["type"]=="button") and
         not (param["xarg"]["type"]=="togglebutton") and
         not (param["xarg"]["type"]=="pushbutton") 
      then
        return false
      else
        return true
      end
    end
  end

  return false

end

--------------------------------------------------------------------------------

-- Internal method for reading a file into a string

function ControlMap:read_file(file_path)
  TRACE("ControlMap:read_file",file_path)


  local file_ref, err = io.open(file_path, "r")
  
  if (not err) then
    local rslt = file_ref:read("*a")
    io.close(file_ref)
    return rslt
  else
    return nil,err
  end

end

--------------------------------------------------------------------------------

--- Determine the type of message (OSC/Note/CC)
-- @param str (String), supply a control-map value such as "C#4"
-- @return integer (e.g. MIDI_NOTE_MESSAGE)

function ControlMap:determine_type(str)
  TRACE("ControlMap:determine_type",str)

  -- osc messages begin with a slash
  if string.sub(str,0,1)=="/" then
    return OSC_MESSAGE
  
  -- cc, if first two characters match "CC"
  elseif string.sub(str,1,2)=="CC" then
    return MIDI_CC_MESSAGE

  -- note, if message has a "#" or "-" as the second character
  elseif string.sub(str,2,2)=="#" or string.sub(str,2,2)=="-" then
    return MIDI_NOTE_MESSAGE

  -- pitch bend
  elseif string.sub(str,1,2)=="PB" then
    return MIDI_PITCH_BEND_MESSAGE

  -- channel pressure
  elseif string.sub(str,1,2)=="CP" then
    return MIDI_CHANNEL_PRESSURE

  -- keyboard
  elseif string.sub(str,0,1)=="|" then
    return MIDI_KEY_MESSAGE
  

  else
    error(("Internal Error. Please report: " ..
      "unknown message-type: %s"):format(str or "nil"))
  end
  
end


--------------------------------------------------------------------------------

--- Parse the control-map into a table
-- (add meta-info - such as unique ids - while parsing)
-- @param str (String) the xml string
-- @return Table

function ControlMap:_parse_xml(str)
  TRACE('ControlMap:_parse_xml(...)')

  local stack = {}
  local top = {}
  table.insert(stack, top)

  local i, j = 1, 1
  local parameter_index = 1
  
  -- helper function to extract attributes (args) from a given node,
  -- casting values to their respective type (number, boolean) 

  local function parseargs(str)

    --print("parseargs",str)

    local function bool(str)
      return (str=="true") and true or false
    end

    local arg = {}
    string.gsub(str, "([%w_]+)=([\"'])(.-)%2", function (w, _, a)
      arg[w] = a
    end)

    -- add unique id for every node
    arg.id = string.format("%d", self.id)
    self.id = self.id+1

    -- add size attribute to buttons
    if (arg["type"]) and
      (arg["type"]=="button") or
      (arg["type"]=="togglebutton") then
      if (not arg["size"]) then
        arg["size"] = 1
      end
    end

    -- cast as numbers
    if (arg["maximum"]) then
      arg["maximum"] = tonumber(arg["maximum"])
    end
    if (arg["minimum"]) then
      arg["minimum"] = tonumber(arg["minimum"])
    end
    if (arg["range"]) then
      arg["range"] = tonumber(arg["range"])
    end

    -- cast as booleans:
    arg["skip_echo"] = bool(arg["skip_echo"])
    arg["invert_x"] = bool(arg["invert_x"])
    arg["invert_y"] = bool(arg["invert_y"])
    arg["velocity_enabled"] = bool(arg["velocity_enabled"])

    return arg

  end

  
  while true do
    local ni,j,c,label,xarg, empty = string.find(
      str, "<(%/?)([%w:]+)(.-)(%/?)>", i)

    if (not ni) then 
      break 
    end
    
    local text = string.sub(str, i, ni - 1)
    
    if (not string.find(text, "^%s*$")) then
      table.insert(top, text)
    end
    
    if (empty == "/") then  -- empty element tag

      --print("empty element tag - label",label)
      local xargs = parseargs(xarg)

      -- meta-attr: index each <Param> node
      if (label == "Param") then
        xargs.index = parameter_index
        parameter_index = parameter_index + 1
      end

      table.insert(top, {label=label, xarg=xargs, empty=1})
    
    elseif (c == "") then   -- start tag

      --print("start tag - label",label)

      local xargs = parseargs(xarg)
      top = {label=label, xarg = xargs}
      table.insert(stack, top)   -- new level
    
    else  -- end tag

      -- remove top
      local toclose = table.remove(stack)
      top = stack[#stack]
      
      if (#stack < 1) then
        error("nothing to close with "..label)
      end
      
      if toclose.label ~= label then
        error("trying to close "..toclose.label.." with "..label)
      end
      
      table.insert(top, toclose)

      if (label == "Group") then
        
        -- add "columns" attribute to *all* groups
        local columns = nil

        -- import colorspace or create blank
        if (toclose.xarg.colorspace) then
          toclose.xarg.colorspace = self:import_colorspace(toclose.xarg.colorspace)
        else
          toclose.xarg.colorspace = nil
        end
        if (not toclose.xarg.columns) then
          if (toclose.xarg.orientation and 
              toclose.xarg.orientation == "vertical") 
          then
            columns = 1
          else
            columns = #toclose
          end

        else 
          columns = tonumber(toclose.xarg.columns)
        end
        
        toclose.columns = columns
        
        local counter = 0
        
        -- loop through parameters in group ...

        for idx,val in ipairs(toclose) do

          -- extend properties to parameters
          toclose[idx].xarg.group_name =  toclose.xarg.name
          --print("*** toclose["..idx.."].xarg.group_name",toclose[idx].xarg.group_name)
          toclose[idx].xarg.colorspace =  toclose.xarg.colorspace
          -- figure out active row/column
          toclose[idx].xarg.column = counter + 1
          toclose[idx].xarg.row = math.floor(
            ((toclose[idx].xarg.index - 1) / columns) + 1)

          counter = counter + 1
          if (counter >= columns) then
            counter = 0
          end
        end
        
        self.groups[toclose.xarg.name] = toclose

        -- reset parameter_index
        parameter_index = 1

      end


    end
    i = j + 1
  end
  
  local text = string.sub(str, i)
  
  if (not string.find(text, "^%s*$")) then
    table.insert(stack[#stack], text)
  end
  
  if (#stack > 1) then
    error("unclosed "..stack[stack.n].label)
  end
  
  return stack[1]
end

