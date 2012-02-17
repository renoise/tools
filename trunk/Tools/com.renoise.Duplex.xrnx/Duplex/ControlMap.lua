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
  
  - Underscore is not allowed in attribute names

--]]


--==============================================================================

class 'ControlMap' 

function ControlMap:__init()
  TRACE("ControlMap:__init")

  -- groups by name, e.g. self.groups["Triggers"]
  self.groups = table.create() 

  -- remember the name (this is a 'read-only' property, 
  -- setting it will not do anything useful)
  self.file_path = ""

  -- internal stuff

  self.midi_buffer = table.create()

  -- unique id, reset each time a control-map is parsed
  self.id = nil 

  -- control-map parsed into table
  self.definition = nil 

end


--------------------------------------------------------------------------------

-- load_definition: load and parse xml
-- @param file_path (string) the name of the file, e.g. "my_map.xml"

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

-- parse the supplied xml string (reset the counter first)

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

-- retrieve <param> by position within group
-- @return the <param> attributes array

function ControlMap:get_indexed_element(index,group_name)
  TRACE("ControlMap:get_indexed_element",index,group_name)

  if (self.groups[group_name] and self.groups[group_name][index]) then
    return self.groups[group_name][index].xarg
  end

  return nil
end

--------------------------------------------------------------------------------

-- parse a string like this "4,4,0" into a colorspace table

function ControlMap:import_colorspace(str)
  TRACE("ControlMap:import_colorspace",str)

  local rslt = table.create()
  rslt:insert(tonumber(string.sub(str,1,1)))
  rslt:insert(tonumber(string.sub(str,3,3)))
  rslt:insert(tonumber(string.sub(str,5,5)))
  return rslt

end

--------------------------------------------------------------------------------

-- get_params_by_value() 
-- used by the MidiDevice to retrieves a parameter by it's note/cc-value-string
-- the function will match values on the default channel, if not defined:
-- "CC#105|Ch1" will match both "CC#105|Ch1" and "CC#105" 
-- also, we have wildcard support: 
-- "C#*|Ch1" will match both "C#1|Ch1" and "C#5" 
-- @param str (string, control-map value attribute)
-- @return table of matched parameters

function ControlMap:get_params_by_value(str,msg_context)
  TRACE("ControlMap:get_params_by_value",str,msg_context)

  local matches = table.create()

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
    --print("controlMap: str2",str2)
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

-- get_osc_param() - used for parsing OSC messages
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
-- @return  <Param> node as table (only the first match is returned),
--          values (table), if matched against a wildcard,
--          wildcard_idx (integer), the matched index
--          replace_char (string), the characters to insert

function ControlMap:get_osc_param(str)
  TRACE("ControlMap:get_osc_param",str)


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
          local values = table.create()
          local ignore = false
          for o=2,#prop_table do
            if (not ignore) then
              if (prop_table[o]=="%f") then
                values:insert(tonumber(str_table[o]))
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
            return v,values,wildcard_idx,replace_char
          end

        end
      end
    end
  end


end


--------------------------------------------------------------------------------

-- return number of columns for the provided group

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

-- return number of rows for the provided group

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

-- get number of parameters in group

function ControlMap:get_group_size(group_name)
  TRACE("ControlMap:get_group_size",group_name)

  return #self.groups[group_name]

end

--------------------------------------------------------------------------------

-- get width/height of provided group
-- @group_name (string) the group-name we want to match
-- @return width/height or nil if not matched

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

-- test if the group describe a grid (columns, with each member being a button)
-- @return boolean

function ControlMap:is_grid_group(group_name)
  
  local is_grid = true
  local group = self.groups[group_name]
  if (group) then
    -- look for "columns" group attribute
    for attr, param in pairs(group) do
      if (attr == "xarg") then
        if (not param["columns"]) then
          return false
        end
      end
    end
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

-- test if the parameter describes a button
-- @param group_name (string, control-map group name)
-- @param index (integer, index within group)
-- @return boolean (false if not matched)

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

-- Determine the type of message (OSC/Note/CC)
-- @param str (string, control-map value)
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

-- Parse the control-map, and add runtime
-- information (element id's and group names)

function ControlMap:_parse_xml(s)
  TRACE('ControlMap:_parse_xml(...)')

  local stack = {}
  local top = {}
  table.insert(stack, top)

  local i, j = 1, 1
  local parameter_index = 1
  
  local function parseargs(s)
    local arg = {}
    string.gsub(s, "([%w_]+)=([\"'])(.-)%2", function (w, _, a)
      arg[w] = a
    end)

    -- meta-attr: add unique id for every node
    arg.id = string.format("%d", self.id)
    self.id = self.id+1

    return arg
  end

  local function bool(s)
    return (s=="true") and true or false
  end
  
  while true do
    local ni,j,c,label,xarg, empty = string.find(
      s, "<(%/?)([%w:]+)(.-)(%/?)>", i)

    if (not ni) then 
      break 
    end
      --[[
      print("Controlmap xargs")
      rprint(xarg)
      ]]
    
    local text = string.sub(s, i, ni - 1)
    
    if (not string.find(text, "^%s*$")) then
      table.insert(top, text)
    end
    
    if (empty == "/") then  -- empty element tag
      local xargs=parseargs(xarg)

      -- meta-attr: index each <Param> node
      if (label == "Param") then
        xargs.index = parameter_index
        parameter_index = parameter_index + 1
      end

      -- meta-attr: add size attribute to (toggle)buttons
      if (xargs["type"]) and
        (xargs["type"]=="button") or
        (xargs["type"]=="togglebutton") then
        if (not xargs["size"]) then
          xargs["size"] = 1
        end
      end

      -- meta-atrr - cast as numbers

      if (xargs["maximum"]) then
        xargs["maximum"] = tonumber(xargs["maximum"])
      end
      if (xargs["minimum"]) then
        xargs["minimum"] = tonumber(xargs["minimum"])
      end
      if (xargs["range"]) then
        xargs["range"] = tonumber(xargs["range"])
      end

      -- meta-attr - cast as booleans:
      xargs["skip_echo"] = bool(xargs["skip_echo"])
      xargs["invert_x"] = bool(xargs["invert_x"])
      xargs["invert_y"] = bool(xargs["invert_y"])
      xargs["velocity_enabled"] = bool(xargs["velocity_enabled"])

      table.insert(top, {label=label, xarg=xargs, empty=1})
    
    elseif (c == "") then   -- start tag
      top = {label=label, xarg=parseargs(xarg)}
      table.insert(stack, top)   -- new level
    
    else  -- end tag
      local toclose = table.remove(stack) -- remove top
      top = stack[#stack]
      
      if (#stack < 1) then
        error("nothing to close with "..label)
      end
      
      if toclose.label ~= label then
        error("trying to close "..toclose.label.." with "..label)
      end
      
      table.insert(top, toclose)

      -- meta-attr : columns and rows
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
        
        for key,val in ipairs(toclose) do
          
          -- extend some group properties to it's members
          toclose[key].xarg.group_name =  toclose.xarg.name
          toclose[key].xarg.colorspace =  toclose.xarg.colorspace
          -- figure out active row/column
          toclose[key].xarg.column = counter + 1
          toclose[key].xarg.row = math.floor(
            ((toclose[key].xarg.index - 1) / columns) + 1)
          
          counter = counter + 1
          if (counter >= columns) then
            counter = 0
          end
        end
        
        self.groups[toclose.xarg.name] = toclose
      end

      -- reset parameter_index
      parameter_index = 1

    end
    i = j + 1
  end
  
  local text = string.sub(s, i)
  
  if (not string.find(text, "^%s*$")) then
    table.insert(stack[#stack], text)
  end
  
  if (#stack > 1) then
    error("unclosed "..stack[stack.n].label)
  end
  
  return stack[1]
end

