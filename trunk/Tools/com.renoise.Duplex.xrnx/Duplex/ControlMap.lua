--[[============================================================================
-- Duplex.ControlMap
============================================================================]]--

--[[--

Load and parse XML based control-map files, add extra methods, handy accessors. 

### XML syntax:

- Supported elements are: `Row`, `Column`, `Group`, `Param` and `SubParam` 
- Use `Row` and `Column` nodes for controlling the layout
- Only `Param` nodes are supported inside a `Group` node
- Only `SubParam` nodes are supported inside a `Param` node

### The `State` node

 Define a state that the control-map can make use of (see also: @{Duplex.StateController})
 Accepts the following attributes

  - `name` - (string) a unique name for identifying the state, and for prefixing nodes
  - `type` - (enum) "toggle", "momentary" or "trigger", determine how to respond to events
  - `value` - (string) the incoming message that we want to match against, e.g. "C#4|Ch2". 
  - `match` - (number) the exact value to match (e.g. CC number with value "5") 
  - `exclusive` - (string) specify a(ny) name for states that should be mutually exclusive
  - `invert` - (bool) when true, trigger will light up when state is inactive 
  - `receive_when_inactive` - (bool) when/if to receive/send parameter messages 
  - `hide_when_inactive` - (bool) when/if to show/hide parameters
  - `disable_when_inactive` - (bool) when/if to enable/disable parameters
  - `active` - (bool) set the initial state

### The `Row` and `Column` node

 State prefixing: supported
 A pure layout node that accepts no attributes 

### The `Group` node

 State prefixing: supported
 Accepts the following attributes 

  - `name` - (string) the group name, this value is passed on to all members (Param nodes)
  - `visible` - (bool) optional, define if group should be visible or hidden (default is true)
  - `columns` - (int) optional, define how many parameters to create before creating a new row
  - `colorspace` - (table) if not defined, inherited from parent or device
  - `orientation` (enum) "horizontal" or "vertical" - determines the flow of elements

### The `Param` node

 State prefixing: supported
 Accepts the following attributes

  - `type`  - (enum) lowercase version of @{Duplex.Globals.INPUT_TYPE}, e.g. `dial`
  - `value` - (string) the pattern that we match messages against, e.g. "C#4|Ch2". 
  - `action` - (string) specify this attribute to use a different output than input pattern
  - `name` - (string) give the parameter a descriptive name (optional)
  - `size` - (int) the relative size of the UIComponent (2 = 200% size)
  - `aspect` - (number) the relative aspect of the UIComponent (0.5 = half height)
  - `minimum` - (number) the minimum value (e.g. to set a button to unlit state)
  - `maximum` - (number) the maxmum value (e.g. to set a button to lit state)
  - `match` - (number) the exact value to match (e.g. CC number with value "5")
  - `match_from` - (number) a value range to match (require that you also specify match_to)
  - `match_to` - (number) a value range to match (require that you also specify match_from)
  - `skip_echo` - (bool) never send message back to device
  - `soft_echo` - (bool) only send virtually generated messages back to device
  - `invert` - (bool) swap the minimum and maximum values
  - `invert_x` - (bool) for XYPad, swap the top and bottom values
  - `invert_y` - (bool) for XYPad, swap the left and right values
  - `swap_axes` - (bool) for XYPad, swap the horizontal and vertical axes
  - `orientation` - (enum) specifies the orientation of a control - relevant for params of type=`fader`
  - `text` - (string) specify the text value, relevant for params of type=`label` 
  - `font` - (string) specify the font type, relevant for params of type=`label` 
  - `range` - (int) specify the range of an on-screen keyboard (number of keys)
  - `mode` - (enum) how to interpret incoming values (see @{Duplex.Globals.PARAM_MODE})
  - `class` - (string) interpret control-map in the context of which (device) class? (default is to use the current device context, but you can enter any literal class name, e.g. "OscDevice" or "LaunchPad")

  Some extra properties are added in runtime:

  - `id` - (string) a unique, auto-generated name
  - `index` - (int) the index (position) within the parent `Group` node
  - `group_name` - (string) this value is passed on from the parent `Group` node
  - `row` - (int) the row within the parent `Group`
  - `column` - the column within the parent `Group`
  - `has_subparams` - (bool) true when the parameter contains additional subparameters
  - `regex_patt` - (string) preprocessed regular expression, created when `value` contains wildcards and/or captures

### The `SubParam` node

  State prefixing: not supported
  The accepted attributes depend on the type of widget

  - `value` - (string) the pattern that we match messages against, e.g. "C#4|Ch2" (if not specified, will use parent node)
  - `field` - (string) what aspect of the parent parameters' value that is being stored (e.g. "x" for xypad x axis)

### Changes

  0.99.3
    - <Param @match> (new), match a specific (CC) value 
    - <Param @match_from, @match_to> (new), match a (CC) value-range 
    - <Param @mode> (new), explicitly state the value resolution (e.g. 7 or 14 bit)
    - <Param @class> (new), interpret parameter in the context of a specific device class

  0.99.2
    - Faster, more flexible parameter matching 
      - all messages are processed on startup, cached/memoized where possible
      - OSC patterns now support "captures", see get_osc_params() for more info
      - get_osc_params(): when using wildcards, returns table of regexp-matches
    - <Param @invert> (new), allows inverting the value (flip min/max)
    - <Param @soft_echo> (new) update device only when changed via virtual UI
    - <Param @font> (new), specify the font type - relevant for @type=labels only
    - <Param @velocity_enabled> attribute has been retired
    - <Param @is_virtual> attribute has been retired, just enter a blank @value
    - <Param @type="key"> widget type has been retired (use @type="button")
    - <SubParam> new node type for combining several parameters into one
      (finally, we can have a "proper" xypad control for MIDI devices)
    - <Group @visible> (new), set to false to hide the entire group 

  0.99.1 
    - TWEAK No more need to explicitly state "is_virtual" for parameters that only
      exist in the virtual UI - just leave the value attribute blank
  
  0.98.14
    - cache parameters
       o Faster retrieval of MIDI parameters (put in cache once requested)
    - New input method “xypad”, for creating XYPad controls in the 
      virtual control surface (paired-value support, however only OSC devices can 
      define this input method)
    - new input method: “key” - for accepting note-input from 
      individual buttons/pads (Note: OBSOLETE)
    - Control-map/virtual control surface: “keyboard” - a new input method for 
      representing a keyboard (the control surface will draw a series of keys)
       o In the control-map, you can specify it’s range (number of keys)
    - Control-map/XML parsing:
       o Attribute names can now contain underscore
    - Control-map/note value syntax: octave wildcard - you can now put an asterisk 
      in place of the octave to make mapping respond to the note only (e.g. “C-*”). 
      Used in the Midi-keyboard Grid Pie configuration to make navigation buttons 
      appear across all the black keys

  0.95
    - New button type: pushbutton (like togglebutton, has internal state control)
      - UISlider, UIToggleButton made compatible with pushbutton (special case)
      - We can now emulate sliders on the TouchOSC template (page 2)
      - Nocturn and Remote will now be able to support hold/release events
    - "name" attribute now optional (excluded from validation)
    - "size" attribute now also applied to dials (see MPD24/32)
    - Streamlined methods for detecting group size, grid mode

  0.9
    - First release

--]]

--==============================================================================

class 'ControlMap' 

ControlMap.WILDCARD_PATTERN = "(*)"
ControlMap.TOKEN_PATTERN = "(%%[ifs])"
ControlMap.CAPTURE_PATTERN = "{([^}]+)}"
ControlMap.STRING_PATTERN = "(%%s)"
ControlMap.FLOAT_PATTERN = "(%%f)"
ControlMap.INTEGER_PATTERN = "(%%i)"

--------------------------------------------------------------------------------

--- Initializate the ControlMap class

function ControlMap:__init()
  TRACE("ControlMap:__init")

  --- (table) associative array - groups by name
  self.groups = table.create() 

  --- (string) location of the control-map file
  self.file_path = ""

  ---(table) table of parameter patterns
  -- (key = pattern, value = list of parameters matching pattern)
  self.patterns = table.create()

  ---(table) table of OSC headers
  -- (like patterns, but OSC-only, and with no wildcards allowed)
  self.osc_headers = table.create()

  ---(table) remember matched OSC patterns 
  -- (key = osc_str, value = output from @{get_osc_params})
  self.osc_buffer = table.create()

  ---(table) remember matched MIDI patterns 
  -- (key = midi_str, value = output from @{get_osc_params})
  self.midi_buffer = table.create()

  --- (int) unique id, reset each time a control-map is parsed
  --self.id = nil 

  --- (table) parsed control-map 
  self.definition = nil 

  --- (table) associative array containing various parameter-patterns
  -- see @{create_typemap}
  self.typemaps = table.create()


end


--------------------------------------------------------------------------------

--- Load_definition: load and parse xml
-- @param file_path (string), the name of the file, e.g. "my_map.xml"
-- @param device_context (@{Duplex.Device}) used when parsing the xml

function ControlMap:load_definition(file_path,device_context)
  TRACE("ControlMap:load_definition",file_path,device_context)

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
    
    local xml_string = self._read_file(self, file_path)
    self:_parse_definition(file_path, xml_string, device_context)
    
  else
    renoise.app():show_error(
      ("Failed to load controller definition file: '%s'. " ..
       "The controller is not available."):format(file_path))
  end
end


--------------------------------------------------------------------------------

--- Parse the supplied xml string (reset the counter first)
-- @param control_map_name (string) path to XML file
-- @param xml_string (string) the XML string
-- @param device_context (@{Duplex.Device}) 

function ControlMap:_parse_definition(control_map_name, xml_string, device_context)
  --TRACE("ControlMap:_parse_definition",control_map_name, xml_string)

  self.id = 0

  -- must guard any file io access. may fail, and we don't want to bother
  -- the user with cryptic LUA error messages then...
  local succeeded, result = pcall(function() 
    -- remove comments before parsing
    xml_string = string.gsub (xml_string, "(<!--.-->)", "")
    return self:_parse_xml(xml_string,device_context) 
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

--- Retrieve `Param` node by position within group
-- @param index (int) the index/position
-- @param group_name (string) the control-map group name
-- @return (table or nil) table of attributes

function ControlMap:get_param_by_index(index,group_name)
  TRACE("ControlMap:get_param_by_index",index,group_name)

  if (self.groups[group_name]) then
    return self.groups[group_name][index]
  else
    local str_msg = "*** ControlMap: failed to get parameter with index %d in group %s"
    LOG(string.format(str_msg,index,group_name))
  end

end


--------------------------------------------------------------------------------

--- Retrieve `Param` node by x/y coordinates within group
-- @param x (int) the horizontal position
-- @param y (int) the vertical position
-- @param group_name (string) the control-map group name
-- @return (table or nil) table of attributes

function ControlMap:get_param_by_pos(x,y,group_name)
  TRACE("ControlMap:get_param_by_pos",x,y,group_name)

  local group = self.groups[group_name]
  if group and group.columns then
    local index = x + ((y-1)*group.columns)
    --print("index",index,"group.columns",group.columns,"#group",#group)
    if group[index] then
      return group[index]
    end
  end

end


--------------------------------------------------------------------------------

--- Retrieve `Param` nodes from group(s), supporting wildcard syntax.
-- 
-- Collect the third parameter from Pad_1:
--    group_name="Pad_1", index=3 
--
-- Collect all parameters from Pad_1
--    group_name="Pad_1", index=nil 
--
-- Collect the third parameter from Pad_1,Pad_2, etc.
--    group_name="Pad_*", index=3 
--
-- Collect every parameter from Pad_1,Pad_2, etc.
--    group_name="Pad_*", index=nil  
--
-- @param group_name (String) the control-map group name
-- @param index (int) optional index/position
-- @return (table or nil) the param attributes array

function ControlMap:get_params(group_name,index)
  TRACE("ControlMap:get_params",group_name,index)

  local params = table.create()

  -- perform wildcard search? 
  if group_name and string.find(group_name,ControlMap.WILDCARD_PATTERN) then

    -- loop through "more than enough" groups
    for count=1,9999 do

      local tmp_group_name = (group_name):gsub(ControlMap.WILDCARD_PATTERN,count)
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
              params:insert(v)
            end
          else
            -- collect all parameters
            params:insert(v)
          end
        end

      end
    end
  
  else -- non-wildcard matching
    if (self.groups[group_name]) then
      for k,v in ipairs(self.groups[group_name]) do
        if index then
          if (index == k) then
            params:insert(v)
          end
        else
          params:insert(v)
        end
      end
    end

  end

  if not table.is_empty(params) then
    return params
  end


end

--------------------------------------------------------------------------------

--- Invoked after having loaded a new controlmap, this function will attempt
-- to memoize as much information as possible (update osc/midi buffers etc.)

function ControlMap:memoize()

  -- store parameters with identical value-pattern
  -- (any type of value-pattern is allowed)
  local add_pattern = function(patt,param)
    if not self.patterns[patt] then
      self.patterns[patt] = table.create()
    end
    --print("*** ControlMap:memoize",rprint(param.xarg))
    self.patterns[patt]:insert(param)
  end

  -- store parameters with identical OSC headers
  -- (no wildcards allowed in this table)
  local add_header = function(patt,param)
    local parts = string.gmatch(patt,"[^%s]+")
    for v in parts do
      if (string.sub(v,0,1)=="/") then
        if not v:find("*",1,true) then
          if not self.osc_headers[v] then
            self.osc_headers[v] = table.create()
          end
          self.osc_headers[v]:insert(param)
        end
      end
    end
  end

  -- buffer parameters that can be literally matched 
  -- (no captures, tokens or wildcards allowed)
  local buffer_params = function(patt,param)
    if not param.xarg.regex_patt then
      self:get_osc_params(patt)
      self:get_midi_params(patt)
    end
  end

  -- iterate through control-map
  local patt = nil
  for _,grp in pairs(self.groups) do
    for _,param in ipairs(grp) do
      patt = param.xarg.action or param.xarg.value
      if patt then
        add_pattern(patt,param)
        add_header(patt,param)
        self:create_typemap(patt)
        buffer_params(patt,param)
      else -- subparameters?
        for __,subparam in ipairs(param) do
          patt = subparam.xarg.action or subparam.xarg.value
          if patt then
            add_pattern(patt,param)
            add_header(patt,param)
            self:create_typemap(patt)
            buffer_params(patt,subparam)
          end
        end
      end
    end
  end

  --print("*** patterns",rprint(self.patterns))
  --print("*** osc_headers",rprint(self.osc_headers))

end

--------------------------------------------------------------------------------

--- Retrieve parameters with a MIDI style pattern
-- 
-- `CC#105|Ch1` will match both `CC#105|Ch1` and `CC#105`
-- (match values on the default channel)
-- 
-- `C#*|Ch1` will match both `C#1|Ch1` and `C#5`
-- (support for wildcard syntax)
--
-- @param str (string, control-map value attribute)
-- @return table containing matched parameters

function ControlMap:get_midi_params(str)
  TRACE("ControlMap:get_midi_params",str)

  local matches = table.create()


  -- check if we have previously matched the pattern
  if (self.midi_buffer[str]) then
    --print("*** ControlMap:get_midi_params - retrieve buffered message",str,"#matches",#self.midi_buffer[str])
    return self.midi_buffer[str] 
  end

  local msg_context = self:determine_type(str)
  local str_no_channel = strip_channel_info(str)

  -- check if we are dealing with an octave wildcard
  -- (method will only work with range -1 to 9)
  local match_exact = function(param)
    local match_against = param.xarg.value
    --print("match_against",str,match_against,rprint(param.xarg.state_ids))
    if (msg_context == DEVICE_MESSAGE.MIDI_NOTE) and 
      (param.xarg.value):find(ControlMap.WILDCARD_PATTERN) 
    then
      local oct = str_no_channel:sub(#str_no_channel-1,#str_no_channel)
      if (oct~="-1") then
        oct = str_no_channel:sub(#str_no_channel)
      end
      match_against = (param.xarg.value):gsub(ControlMap.WILDCARD_PATTERN,oct)
    end
    if (match_against == str) or (match_against == str_no_channel) then
      return param
    end
  end

  -- first, look for an exact match
  -- iterate through <Param>, and possibly <SubParam> nodes 
  for _,group in pairs(self.groups) do
    for k,param in ipairs(group) do
      if (#param > 0) then
        for k2,subparam in ipairs(param) do
          --print("*** ControlMap:get_midi_params - check subparameter..")
          if match_exact(subparam) then
            matches:insert(subparam)
          end
        end
      else
        --print("*** ControlMap:get_midi_params - check parameter..")
        if match_exact(param) then
          matches:insert(param)
        end
      end
    end
  end

  -- next, match keyboard (no note information)
  if (msg_context == DEVICE_MESSAGE.MIDI_NOTE) then
    local str_no_note = strip_note_info(str)
    for _,group in pairs(self.groups) do
      for k,v in ipairs(group) do
        -- check if we already have matched the value
        local skip = false
        for k2,v2 in ipairs(matches) do
          if (v2.xarg.value == v.xarg.value) then
            skip = true
          end
        end
        if not skip and 
          (v.xarg.value == str) or 
          (v.xarg.value == str_no_note) or
          (v.xarg.value == "|") -- match any channel
        then
          matches:insert(v)
        end
      end
    end
  end

  -- remember match 
  self.midi_buffer[str] = matches
  
  --print("*** ControlMap:get_midi_params - #matches",#matches)

  return matches

end

--------------------------------------------------------------------------------

--- generate a map containing information about each OSC message pattern-part
-- @return (table) 
--
--  each part can define the following possible entries:
--    
--    [int] = {
--      text,        -- (string) the raw value
--      is_header,   -- (bool) when value is the header part
--      wildcard_pos,-- (int) position of first "*" (if any, in header text)
--      is_capture,  -- (bool) when token is surrounded by "{}"
--      is_token,    -- (bool) when "%f", "%i" or "%s" token 
--      is_string,   -- (bool) when "%s" token 
--      is_float,    -- (bool) when "%f" token 
--      is_integer   -- (bool) when "%i" token 
--    }
--  
--    has_captures  -- (bool) when any part contains a capture
--
--  in addition, the map will contain an entry specifying the order
--  of each possible item that can be matched with regular expressions:
--
--    order = {
--      [int] = {             -- position of character
--        method = [string]   -- "wildcard" or "capture"
--        type = [string]     -- "%f", "%i" or "%s"
--      }
--    }
--
--

function ControlMap:create_typemap(str_message)

  -- split the message into non-whitespace chunks
  local str_vars = string.gmatch(str_message,"[^%s]+")

  local tmap = {}
  local has_captures = false
  local counter = 1
  for v in str_vars do
    tmap[counter] = {}
    tmap[counter].text = v
    --print("string.sub(v,0,1)",string.sub(v,0,1))
    if (string.sub(v,0,1)=="/") then
      tmap[counter].is_header = true
      tmap[counter].wildcard_pos = v:find("*",1,true)
    else
      tmap[counter].is_capture = string.find(v,ControlMap.CAPTURE_PATTERN) and true or false
      tmap[counter].is_token = string.find(v,ControlMap.TOKEN_PATTERN) and true or false
      tmap[counter].is_string = string.find(v,ControlMap.STRING_PATTERN) and true or false
      tmap[counter].is_integer = string.find(v,ControlMap.INTEGER_PATTERN) and true or false
      tmap[counter].is_float = string.find(v,ControlMap.FLOAT_PATTERN) and true or false
      if not has_captures then
        has_captures = tmap[counter].is_capture
      end
    end
    counter = counter+1
  end

  tmap.has_captures = has_captures


  local find_pos = function(patt,t,str,s)

    local pos = 0
    local rslt = false
    local c1,c2 = nil,nil
    repeat
      pos,c1,c2 = string.find(str,patt,pos+1)
      --print("pos,c1,c2",pos,c1,c2,str,patt)
      if pos then
        t[pos] = {
          method = s,
          type = c2   -- %i, %f or %s
        }
        rslt = true
      end
    until not pos 

    return rslt

  end

  tmap.order = {}
  find_pos(ControlMap.WILDCARD_PATTERN,tmap.order,str_message,"wildcard")
  find_pos(ControlMap.CAPTURE_PATTERN,tmap.order,str_message,"capture")

  --print("*** tmap",rprint(tmap))
  self.typemaps[str_message] = tmap

  return tmap

end


--------------------------------------------------------------------------------

--- Retrieve parameters with a OSC style pattern.
--
-- ### Match floats, integers and strings using `%f`, `%i` and `%s`
--
-- `/press 1 %i` matches `/press 1 1` but not `/press 1 A`      
-- 
-- ### Specify wildcards using an asterisk
--
-- `/*/pre* 1 %f` matches `/12/press 1 1` and `/a/prefs 1 1.42` 
--
-- ### Specify captures using curved brackets
--
-- `/tilt {%f} %f {%f}` will capture the first and third number 
-- 
-- The method will match the action property if it's available, otherwise 
-- the `value` property (the `action` property is needed when a device 
-- transmit a different outgoing than incoming value)
-- 
-- @param osc_str (string), incoming OSC message
-- @return (table) result of match:
--  {
--    (table),  -- Param/SubParam node
--    (table),  -- resulting values
--    (table)   -- regular expression match(es)
--      {
--        index = [int],      -- position of match
--        chars = [string],   -- matches characters
--        method = [string],  -- "wildcard" or "capture"
--        type = [string]     -- "%f", "%s" or "%i"
--      }
--  }

function ControlMap:get_osc_params(osc_str)
  TRACE("ControlMap:get_osc_params",osc_str)

  local buf = self.osc_buffer[osc_str]
  if buf then
    --print("*** ControlMap:get_osc_params - retrieve buffered message:",osc_str)
    return buf
  end

  if (string.sub(osc_str,0,1)~="/") then 
    -- string does not appear to be an osc message
    return
  end

  local buffer = table.create()
  local matches = table.create()
  local regex_matches = nil
  local stop_match = false

  -- split incoming message into parts, separated by whitespace
  local val_parts = table.create()
  for v in string.gmatch(osc_str,"[^%s]+") do
    val_parts:insert(v)
  end

  --print("*** get_osc_params - osc_str,val_parts",osc_str,rprint(val_parts))

  -- matching logic
  local match_osc_param = function(param)

    --local str_attr = param.xarg.action or param.xarg.value
    local str_attr = param.xarg.action or param.xarg.value
    if (str_attr) then

      local matched = true
      local tmap = self.typemaps[str_attr]
      if (#val_parts~=#tmap) then
        -- ignore if different number of parts
        --print("*** reject, different number of parts",str_attr,#val_parts,#tmap)
        matched = false
      elseif param.xarg.regex_patt then

        -- check the part before the first wildcard 
        if tmap[1].wildcard_pos and (tmap[1].wildcard_pos > 1) then
          local val_begin = string.sub(osc_str,0,tmap[1].wildcard_pos-1)
          local attr_begin = string.sub(str_attr,0,tmap[1].wildcard_pos-1)
          if not (val_begin == attr_begin) then
            --print("*** wildcard detected, but different pattern",str_attr)
            matched = false
          end
        elseif not (tmap[1].text == val_parts[1]) then
          --print("*** no wildcard detected, different pattern",str_attr)
          matched = false
        end

        if matched then 

          -- make our table nice and tidy...
          -- {index = [int], chars = [val]}
          local create_table = function(arg)
            local args = {}
            for i = 1,#arg do
              if (i%2 == 1) then
                args[#args+1] = {}
                args[#args].index = arg[i]
              else
                args[#args].chars = arg[i]
              end
            end
            return args
          end

          --print("*** applying regular expression",param.xarg.regex_patt)
          regex_matches = pack_args(string.match(osc_str,param.xarg.regex_patt))
          --print("regex_matches",rprint(regex_matches))
          if table.is_empty(regex_matches) then
            --print("*** wildcard detected, but not matched",str_attr)
            matched = false
          else
            --print("*** wildcard detected and matched",str_attr)
            regex_matches = create_table(regex_matches)
          end

          if matched and tmap.has_captures then
            -- add additional information to regex_matches, so we can 
            -- determine if a value is the result of a capture etc.
            local i = 1
            local count = 1
            repeat
              if tmap.order[i] then
                regex_matches[count].method = tmap.order[i].method
                regex_matches[count].type = tmap.order[i].type
                count = count + 1
              end
              i = i + 1
            until count > #table.keys(tmap.order)
          end
          --print("regex_matches",rprint(regex_matches))

        end

      elseif not (tmap[1].text == val_parts[1]) then

        --print("*** no regex to match, and different pattern",tmap[1].text,val_parts[1])
        matched = false

      end

      if matched then

        -- return matching group + extracted value

        local values = table.create()
        local add_to_buffer = true
        local ignore = false

        -- if there are no captures specified, grab all tokens
        -- and create a table from those values
        if not tmap.has_captures then
          for o=2,#tmap do
            if (not ignore) then
              if tmap[o].is_float then
                values:insert(tonumber(val_parts[o]))
                add_to_buffer = false -- floats can't be buffered
              elseif tmap[o].is_integer then
                values:insert(tonumber(val_parts[o]))
              elseif tmap[o].is_string then
                -- wrong argument, ignore
                ignore = true
              end
            end
          end
        end

        --print("ignore",ignore)
        if not ignore then

          if tmap.has_captures then
            for k,v in ipairs(regex_matches) do
              if (v.method == "capture") then
                if (v.type == "%i") then 
                  values:insert(tonumber(v.chars))
                elseif (v.type == "%f") then
                  values:insert(tonumber(v.chars))
                  add_to_buffer = false -- floats can't be buffered
                else
                  values:insert(v.chars)
                end
              end
            end
            --print("captured value(s)",rprint(values))
          end

          --print("get_osc_params - final matched value",rprint(values))

          -- loop through "patterns", and add them to our matches
          -- (each entry in "patterns" can contain multiple parameters)
          local pattern = self.patterns[str_attr]
          for k,v in ipairs(pattern) do
            if add_to_buffer then
              buffer:insert({v,values,regex_matches})
            end
            --print("add matched value",rprint(values),rprint(v))
            matches:insert({v,values,regex_matches})

          end
          
          -- if literal match or no wildcard, stop matching...
          if table.is_empty(regex_matches) or not 
            tmap.has_captures
          then
            stop_match = true
          end

        end

      end
    end
  end


  local params = self.osc_headers[val_parts[1]]
  if params then

    -- literal match with a memoized header
    -------------------------------------------------------
    -- (no support for wildcards, but tokens and captures are fine)
    --print("matched memoized header",val_parts[1],#params)

    for _,v in ipairs(params) do
      if stop_match then
        break
      end
      match_osc_param(v)
      --print("literal matches so far...",#matches)
    end

  else

    -- search entire control-map
    -------------------------------------------------------

    for _,group in pairs(self.groups) do
      if stop_match then
        break
      end
      for _,v in ipairs(group) do
        if stop_match then
          break
        end
        match_osc_param(v)
        --print("matches so far...",#matches)
      end
    end

  end

  --print("*** get_osc_params - #matches",#matches)

  if not table.is_empty(buffer) then
    self.osc_buffer[osc_str] = buffer
  end

  return matches

end


--------------------------------------------------------------------------------

--- Parse a string into a colorspace table
-- @param str (String) a comma-separated string of RGB values, e.g. "4,4,0" 
-- @return table

function ControlMap:import_colorspace(str)
  TRACE("ControlMap:import_colorspace",str)

  local rslt = table.create()
  for i,v in string.gmatch(str,"[%d]+") do 
    rslt:insert(tonumber(i)) 
  end
  return rslt

end

--------------------------------------------------------------------------------

--- Count number of columns for the provided group
-- @param group_name (string) the control-map group name, e.g. `Encoders`
-- @return int, or nil if group does not exist

function ControlMap:count_columns(group_name)
  TRACE("ControlMap:count_columns",group_name)

  local group = self.groups[group_name]
  if (group) then
    if (group.columns) then
      return group.columns
    end
  end

end

--------------------------------------------------------------------------------

--- Count number of rows for the provided group
-- @param group_name (string) the control-map group name, e.g. `Encoders`
-- @return int, or nil if group does not exist

function ControlMap:count_rows(group_name)
  TRACE("ControlMap:count_rows",group_name)

  local group = self.groups[group_name]
  if (group) then
    if (group.columns) then
      return math.ceil(#group/group.columns)
    end
  end

end

--------------------------------------------------------------------------------

--- Count number of parameters in group
-- @param group_name (string) the control-map group name, e.g. `Encoders`
-- @return int, or nil if group does not exist

function ControlMap:get_group_size(group_name)
  TRACE("ControlMap:get_group_size",group_name)

  local group = self.groups[group_name]
  if (group) then
    return #self.groups[group_name]
  end

end

--------------------------------------------------------------------------------

--- Get width/height of provided group
-- @param group_name (String) the control-map group name, e.g. `Encoders`
-- @return width, or nil if not matched
-- @return height, or nil if not matched

function ControlMap:get_group_dimensions(group_name)
  
  local group = self.groups[group_name]
  if (group) then
    for attr, param in pairs(group) do
      if (attr == "xarg") then
        local width = tonumber(param.columns)
        local height = math.ceil(#group / width)
        return width,height
      end
    end
  end
end

--------------------------------------------------------------------------------

--- Test if the group describe a grid group 
-- (meaning: it contains columns, and each member is a button)
-- @param group_name (String) the control-map group name, e.g. `Encoders`
-- @return bool

function ControlMap:is_grid_group(group_name)
  
  local is_grid = true
  local group = self.groups[group_name]
  if (group) then
    -- look for "columns" group attribute
    -- check parameter type (only buttons allowed)
    for _, param in ipairs(group) do
      if (param.xarg and param.xarg.type) then
        if not string.find(param.xarg.type,"button") then
          return false
        end
      end
    end
    return true
  end

end

--------------------------------------------------------------------------------

--- Test if the parameter describes a button
-- @param group_name (string) the control-map group name, e.g. `Encoders`
-- @param index (int) index within group
-- @return bool, true if matched, false if not 

function ControlMap:is_button(group_name,index)
  
  -- use the first available index if nothing is specified
  if not index then
    index = 1
  end

  local group = self.groups[group_name]
  if (group) then
    local param = group[index]
    if (param.xarg and param.xarg.type) then
      if not string.find(param.xarg.type,"button") then
        return false
      else
        return true
      end
    end
  end

  return false

end

--------------------------------------------------------------------------------

--- Internal method for reading a file into a string

function ControlMap:_read_file(file_path)
  TRACE("ControlMap:_read_file",file_path)


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
-- @param str (string), supply a control-map `value` such as `C#4`
-- @return enum (@{Duplex.Globals.DEVICE_MESSAGE})

function ControlMap:determine_type(str)
  TRACE("ControlMap:determine_type",str)

  -- osc messages begin with a slash
  if string.sub(str,0,1)=="/" then
    return DEVICE_MESSAGE.OSC
  
  -- cc, if first two characters match "CC"
  elseif string.sub(str,1,2)=="CC" then
    return DEVICE_MESSAGE.MIDI_CC

  -- note, if message has a "#" or "-" as the second character
  elseif string.sub(str,2,2)=="#" or string.sub(str,2,2)=="-" then
    return DEVICE_MESSAGE.MIDI_NOTE

  -- pitch bend
  elseif string.sub(str,1,2)=="PB" then
    return DEVICE_MESSAGE.MIDI_PITCH_BEND

  -- program change
  elseif string.sub(str,1,3)=="Prg" then
    return DEVICE_MESSAGE.MIDI_PROGRAM_CHANGE

  -- channel pressure
  elseif string.sub(str,1,2)=="CP" then
    return DEVICE_MESSAGE.MIDI_CHANNEL_PRESSURE

  -- keyboard
  elseif string.sub(str,0,1)=="|" then
    return DEVICE_MESSAGE.MIDI_KEY
  

  else
    error(("Internal Error. Please report: " ..
      "unknown message-type: %s"):format(str or "nil"))
  end
  
end

--------------------------------------------------------------------------------

--- Parse the control-map into a table
-- (add meta-info - such as unique ids - while parsing)
-- @param str (String) the xml string
-- @param device_context (@{Duplex.Device}) 
-- @return Table

function ControlMap:_parse_xml(str,device_context)
  TRACE('ControlMap:_parse_xml(...)')

  --print("*** ControlMap:_parse_xml - str,device_context",str,device_context)

  local stack = {}
  local top = {}
  table.insert(stack, top)

  local state_ids = {}
  local depth = 0
  local uid = 0
  local i, j = 1, 1
  local parameter_index = 1
  
  -- helper function to extract attributes (xargs) from a given node,
  -- casting values to their respective type (number, bool) 

  local function parseargs(str,empty_element,label)

    --print("parseargs",str)

    local function bool(str)
      return (str=="true") and true or false
    end

    local xarg = {}
    string.gsub(str, "([%w_]+)=([\"'])(.-)%2", function (w, _, a)
      xarg[w] = a
    end)


    --print("xarg.mode",xarg.mode)


    -- add size attribute to buttons
    if (xarg.type) and
      (xarg.type=="button") or
      (xarg.type=="togglebutton") then
      if (not xarg.size) then
        xarg.size = 1
      end
    end

    -- cast as numbers
    if (xarg.maximum) then
      xarg.maximum = tonumber(xarg.maximum)
    end
    if (xarg.minimum) then
      xarg.minimum = tonumber(xarg.minimum)
    end
    if (xarg.range) then
      xarg.range = tonumber(xarg.range)
    end
    if (xarg.match) then
      xarg.match = tonumber(xarg.match)
    end
    if (xarg.match_from) then
      xarg.match_from = tonumber(xarg.match_from)
    end
    if (xarg.match_to) then
      xarg.match_to = tonumber(xarg.match_to)
    end
    if not xarg.mode then
      xarg.mode = device_context.default_parameter_mode
    end

    if (label == "Param") or (label == "SubParam") then

      -- cast as booleans (default to false)
      xarg.skip_echo = bool(xarg.skip_echo)
      xarg.soft_echo = bool(xarg.soft_echo)
      xarg.invert = bool(xarg.invert)
      xarg.invert_x = bool(xarg.invert_x)
      xarg.invert_y = bool(xarg.invert_y)
      xarg.swap_axes = bool(xarg.swap_axes)

    end

    if (label == "State") then
      --print("xarg.invert",xarg.invert,bool(xarg.invert))
      xarg.invert = bool(xarg.invert)
      xarg.disable_when_inactive = bool(xarg.disable_when_inactive)
      xarg.receive_when_inactive = bool(xarg.receive_when_inactive)
      xarg.hide_when_inactive = not xarg.hide_when_inactive and true or bool(xarg.hide_when_inactive)
    end

    -- cast as booleans (default to true)
    xarg.visible = not xarg.visible and true or bool(xarg.visible) 


    return xarg

  end


  -- provide a unique value for virtual params
  local mark_as_virtual = function(xarg)
    xarg.value = ("/duplex_uid_%d"):format(uid)
    xarg.skip_echo = true
    uid = uid+1
  end
  
  -- helper function to preprocess values into regular expressions

  local create_regex_patt = function(xarg)

    local str_val = xarg.action or xarg.value
    --print("create_regex_patt",str_val)

    -- start by testing if there is something to match
    if not str_val or 
      (
        not string.find(str_val,ControlMap.WILDCARD_PATTERN) and
        not string.find(str_val,ControlMap.TOKEN_PATTERN) and
        not string.find(str_val,ControlMap.CAPTURE_PATTERN)
      )
    then
      return nil
    end

    local regex_patt = str_val

    -- translate wildcard into regex
    regex_patt = string.gsub(regex_patt,ControlMap.WILDCARD_PATTERN,"()([^/%s]+)")

    -- convert tokens (captures first)

    -- integers 
    regex_patt = string.gsub(regex_patt,"{%%i}","()([\-]?%%d%+)")
    regex_patt = string.gsub(regex_patt,"%%i","[%%d%]+")

    -- floats
    regex_patt = string.gsub(regex_patt,"{%%f}","()([\-]?%%d%+[\.]*[%%d]*)")
    regex_patt = string.gsub(regex_patt,"%%f","[\-]?%%d%+[\.]*[%%d]*")

    --print("create_regexp_value - final pattern",regex_patt)

    return regex_patt

  end
  

  while true do
    local ni,j,c,label,xarg, empty = string.find(
      str, "<(%/?)([%w:]+)(.-)(%/?)>", i)

    if (not ni) then 
      break 
    end

    --print("ni,j,c,label,xarg, empty",ni,j,c,label,xarg, empty)

    local is_empty_tag = (empty == "/") and true or false
    local is_start_tag = (c == "") and true or false

    if is_start_tag or is_empty_tag then
      depth = depth+1
      state_ids[depth] = {}
    elseif not is_empty_tag then
      state_ids[depth] = nil
      depth = depth-1
    end


    -- break label by colon (states come first, label is last...)
    local label_parts = {}
    string.gsub(label, "([^\:]+)", function (w,_,a)
      label_parts[#label_parts+1] = w
    end)
    label = label_parts[#label_parts]

    --print("*** label_parts,label",rprint(label_parts),#label_parts)

    -- carry existing states (if any) into new nodes,
    -- and merge with the ones specified at that level 
      
    if is_empty_tag or is_start_tag then

      if (state_ids[depth-1]) then
        state_ids[depth] = table.rcopy(state_ids[depth-1])
      end

      if (#label_parts > 1) then
        
        -- one or more state ids, remove the label...
        label_parts[#label_parts] = nil 

        --print("depth",depth,"label",label,rprint(state_ids[depth]))
        for k,v in ipairs(label_parts) do
          if not (table.find(state_ids[depth],v)) then
            table.insert(state_ids[depth],v)
          end
        end

      end

    end

    --print("got here 3")
    --print("*** state_ids",rprint(state_ids))

    local text = string.sub(str, i, ni - 1)
    
    if (not string.find(text, "^%s*$")) then
      table.insert(top, text)
    end
    
    if is_empty_tag then  -- empty element tag

      --print("empty element tag - label",label)
      local xargs = parseargs(xarg,true,label)

      if (label ~= "State") then
        xargs.state_ids = table.rcopy(state_ids[depth])
        --print("*** assigned state ids to label,param",label,table.concat(state_ids[depth],","))
      end

      if (label == "Param") then
        xargs.index = parameter_index
        parameter_index = parameter_index + 1
      end

      table.insert(top, {label=label, xarg=xargs, empty=1})
    
    elseif is_start_tag then   -- start tag

      --print("start tag - label",label)
      local xargs = parseargs(xarg,false,label)

      if (label ~= "State") then
        xargs.state_ids = table.rcopy(state_ids[depth])
        --print("*** assigned state ids to label,param",label,table.concat(state_ids[depth],","))
      end

      -- <Param> node containing <SubParam> nodes
      if (label == "Param") then
        xargs.index = parameter_index
        parameter_index = parameter_index + 1
      end

      top = {label=label, xarg = xargs}
      table.insert(stack, top)   -- new level
    
    else  -- end tag

      --print("end tag - label",label)

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

        -- required: name attribute
        if not toclose.xarg.name then
          error("all groups must specify a name attribute")
        end
        
        -- import colorspace or create blank
        if (toclose.xarg.colorspace) then
          toclose.xarg.colorspace = self:import_colorspace(toclose.xarg.colorspace)
        else
          toclose.xarg.colorspace = nil
        end

        -- add "columns" attribute to all groups
        local columns = nil
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

          if not toclose[idx].xarg.value or (toclose[idx].xarg.value == "") 
            --and table.is_empty(toclose[idx])
          then
            mark_as_virtual(toclose[idx].xarg)
            --print("mark_as_virtual (parameter)",rprint(toclose[idx]))
          end

          -- extend properties to parameters
          toclose[idx].xarg.group_name =  toclose.xarg.name
          --print("*** toclose["..idx.."].xarg.group_name",toclose[idx].xarg.group_name)
          toclose[idx].xarg.colorspace =  toclose.xarg.colorspace
          -- figure out active row/column
          toclose[idx].xarg.column = counter + 1
          toclose[idx].xarg.row = math.floor(
            ((toclose[idx].xarg.index - 1) / columns) + 1)

          toclose[idx].xarg.regex_patt  =  create_regex_patt(toclose[idx].xarg)

          --print("loop through parameters",rprint(toclose[idx].xarg))

          -- loop through subparameters ...
          for idx2,_ in ipairs(toclose[idx]) do

            toclose[idx].xarg.has_subparams = true

            -- propagate certain attributes:
            -- if not defined in subparam, use param

            -- value
            if not toclose[idx][idx2].xarg.value then
              toclose[idx][idx2].xarg.value  =  toclose[idx].xarg.value
              if not toclose[idx].xarg.value then
                mark_as_virtual(toclose[idx][idx2].xarg)
                --print("mark_as_virtual (subparameter)",rprint(toclose[idx][idx2]))
              end
            end

            if not toclose[idx][idx2].xarg.type then
              toclose[idx][idx2].xarg.type  =  toclose[idx].xarg.type
            end

            if not toclose[idx][idx2].xarg.minimum then
              toclose[idx][idx2].xarg.minimum  =  toclose[idx].xarg.minimum
            end

            if not toclose[idx][idx2].xarg.maximum then
              toclose[idx][idx2].xarg.maximum  =  toclose[idx].xarg.maximum
            end
  
            -- copy internal attributes
            toclose[idx][idx2].xarg.group_name  =  toclose[idx].xarg.group_name
            toclose[idx][idx2].xarg.index       =  toclose[idx].xarg.index
            toclose[idx][idx2].xarg.column      =  toclose[idx].xarg.column
            toclose[idx][idx2].xarg.row         =  toclose[idx].xarg.row

            toclose[idx][idx2].xarg.regex_patt  =  create_regex_patt(toclose[idx][idx2].xarg)

            -- apply widget-specific attributes...

            local widget_hook = widget_hooks[toclose[idx].xarg.type]
            if widget_hook and widget_hook.process_subparams then
              widget_hook.process_subparams(toclose[idx],toclose[idx][idx2])
            end

            --print("loop through subparameters",toclose[idx][idx2].xarg.value,rprint(toclose[idx][idx2].xarg))

          end

          -- update/reset column count
          counter = counter + 1
          if (counter >= columns) then
            counter = 0
          end

        end
        
        self.groups[toclose.xarg.name] = toclose
        --print("self.groups",rprint(self.groups))

        -- reset parameter_index
        parameter_index = 1

      end


    end

    if is_empty_tag then
      state_ids[depth] = nil
      depth = depth-1
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

