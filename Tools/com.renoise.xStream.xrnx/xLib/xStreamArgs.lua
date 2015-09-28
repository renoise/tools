--[[============================================================================
xStreamArgs
============================================================================]]--
--[[

	This class manages real-time observable values (arguments) for xStream,
  as well as the ability to save/recall presets 

  The observable values are exposed as properties of the class itself, while
  xStreamArg instances are accessed through .args

]]

class 'xStreamArgs'

xStreamArgs.RESERVED_NAMES = {"Arguments","Presets"}

-------------------------------------------------------------------------------
-- constructor
-- @param xstream (xStream)

function xStreamArgs:__init(model)
  TRACE("xStreamArgs:__init(model)",model)
  
  -- xStreamModel, reference to owner
	self.model = model

  -- renoise.Document
  self.doc = nil

  -- table<xStreamArg>
  self.args = {}

  -- int, read-only - number of registered arguments
  self.length = property(
    self.get_length)

  -- ObservableNumberList, notifier fired when items are added/removed 
  self.presets_observable = renoise.Document.ObservableNumberList()

  -- int, active preset (0 when none is active)
  self.selected_preset_index = property(
    self.get_selected_preset_index,self.set_selected_preset_index)
  self.selected_preset_index_observable = renoise.Document.ObservableNumber(0)

  -- initialize -----------------------

  local arguments = renoise.Document.create("xStreamArgs"){}
	self.doc = renoise.Document.create("xStreamArgDocument"){
    Presets = renoise.Document.DocumentList(),
  }
  self.doc:add_property("Arguments",arguments)

end

-------------------------------------------------------------------------------
-- Add property to our document, register notifier
-- @param arg (table), see xStreamArg.constructor
-- @return bool, true when accepted
-- @return string, error message

function xStreamArgs:add(arg)
  TRACE("xStreamArgs:add(arg)",arg)
  --rprint(arg.value)
  --print(type(arg.value))
  
  if (type(arg.name)~='string') then
    return false,"Argument name '"..arg.name.."' needs to be a string"
  end
  -- TODO validate as proper lua variable name
  --[[
    *** std::logic_error: 'observable and node names must not contain special characters. only alphanumerical characters and '_' are allowed (like XML keys).'
  ]]
  if not xReflection.is_valid_identifier(arg.name) then
    return false,"Argument name '"..arg.name.."' needs to be a proper lua variable name - no special characters or number as the first character"
  end

  -- avoid using existing or RESERVED_NAMES
  if (type(self[arg.name]) ~= 'nil') or 
    (table.find(xStreamArgs.RESERVED_NAMES,arg.name)) 
  then
    return false,"The argument "..arg.name.." is already defined. Please choose another name"
  end

  if (type(arg.value)=='nil') then
    return false,"Please provide a default value (makes the type unambigous)"
  end

  if arg.poll and arg.bind then
    return false,"Please specify either bind or poll for an argument, but not both"
  end   

  -- Observable needs a value in order to determine it's type.
  -- Try to evaluate the bind/poll string in order to get the 
  -- current value. If that fails, provide the default value
  local bind_val,err
  if arg.bind then
    --print("default value for arg.bind",arg.bind)
    local bind_val_no_obs = string.sub(arg.bind,1,#arg.bind-11)
    bind_val,err = xLib.parse_str(bind_val_no_obs)
  elseif arg.poll then
    --print("default value for arg.poll",arg.poll)
    bind_val,err = xLib.parse_str(arg.poll)
  end
  if not err then
    arg.value = bind_val or arg.value
  else
    LOG(err)
  end

  -- seems ok, add to our document and create xStreamArg 
  --print("arg.name,arg.value",arg.name,arg.value)
  arg.observable = self.doc["Arguments"]:add_property(arg.name,arg.value)
  arg.xstream = self.model.xstream

  local xarg = xStreamArg(arg)
  table.insert(self.args,xarg)
 
  self.doc["Arguments"][arg.name]:add_notifier(xarg.notifier)

  -- direct value access, used by the callback method
  -- can apply transformation to the result
  self[arg.name] = property(function()  
    local val = self.doc["Arguments"][arg.name].value
    if arg.properties then
      if arg.properties.zero_based then
        val = val - 1
      end
      if (arg.properties.quant == 1) then
        val = math.floor(val)
      end
    end
    return val
  end)

  --print("adding arg",arg.name)
  return true

end

-------------------------------------------------------------------------------
-- return copy of all current values (requested by e.g. callback)
-- TODO optimize by keeping this up to date when values change

function xStreamArgs:get_values()
  TRACE("xStreamArgs:get_values()")
  local rslt = {}
  for k,arg in ipairs(self.args) do
    --table.insert(rslt,arg.value)
    rslt[arg.name] = arg.value
  end
  --print("xStreamArgs:get_values - rslt",rprint(rslt))
  return rslt
end


-------------------------------------------------------------------------------
-- add current/supplied values as new preset 
-- @param t (table) use these values 

function xStreamArgs:add_preset(t)
  TRACE("xStreamArgs:add_preset(t)",t)

 	local preset = renoise.Document.create("xStreamArgPreset"){}
  if not t then
    for _,arg in ipairs(self.args) do
      preset:add_property(arg.name, arg.observable.value)
    end
  else
    for k,v in pairs(t) do
      preset:add_property(k,v)
    end
  end

  self.doc["Presets"]:insert(preset)
  local idx = self:get_number_of_presets()
  self.presets_observable:insert(idx)
  --self.selected_preset_index = idx

end

-------------------------------------------------------------------------------
-- retrieve preset by index
-- return renoise.Document or nil

function xStreamArgs:get_preset_by_index(idx)

  local preset = self.doc["Presets"][idx]
  if not preset then
    LOG("Tried to access a non-existing preset")
    return
  end

  return preset

end

-------------------------------------------------------------------------------
-- rename preset (prompt user)
-- @param name (string)
--[[
function xStreamArgs:rename_preset(idx)
  TRACE("xStreamArgs:add_preset(idx)",idx)

  local preset = self:get_preset_by_index(idx)
  if not preset then
    return
  end

  local name = self.presets_observable[idx].value or self.get_suggested_preset_name(idx)
  name = self:prompt_for_name(name,"Choose Preset Name")
  name = xFilesystem.sanitize_filename(name)

  self.presets_observable[idx].value = name

end
]]

-------------------------------------------------------------------------------
-- recall/activate preset 
-- @param idx (int)
-- @return bool, true when all arguments were recalled
-- @return string, message listing failed arguments or nil if no preset

function xStreamArgs:recall_preset(idx)
  TRACE("xStreamArgs:recall_preset(idx)",idx)

  local preset = self:get_preset_by_index(idx)
  if not preset then
    return false
  end
  
  local failed_args = {}
  for _,arg in ipairs(self.args) do
    if preset[arg.name] then
      if not arg.locked then
        self.doc["Arguments"][arg.name].value = preset[arg.name].value
      end
    else
      table.insert(failed_args,arg.name)
    end
  end

  self.selected_preset_index = idx

  if not table.is_empty(failed_args) then
    local msg = "WARNING: The following arguments could not be recalled: "
      ..table.concat(failed_args,", ")
    LOG(msg)
    return false,msg
  else
    return true
  end

end

-------------------------------------------------------------------------------
-- apply a random value to boolean, numeric values

function xStreamArgs:randomize()

  for _,arg in ipairs(self.args) do

    if not arg.locked then

      local val

      if (type(arg.value) == "boolean") then
        val = (math.random(0,1) == 1) and true or false
        --print("*** boolean random",val)
      elseif (type(arg.value) == "number") then
        if arg.properties then
          if (arg.properties.items) then
            -- popup or switch
            val = math.random(0,#arg.properties.items)
          elseif arg.properties.min and arg.properties.max then
            if (arg.properties.quant == 1) then
              -- integer
              val = math.random(arg.properties.min,arg.properties.max)
            else
              -- float
              val = xLib.scale_value(math.random(),0,1,arg.properties.min,arg.properties.max)
            end
          end
        end
      end

      if (type(val) ~= "nil") then
        self.doc["Arguments"][arg.name].value = val
      end

    end

  end

end

-------------------------------------------------------------------------------
-- update a preset with the current set of values
-- @param idx (int)

function xStreamArgs:update_preset(idx)
  TRACE("xStreamArgs:update_preset(idx)",idx)

  local preset = self:get_preset_by_index(idx)
  if not preset then
    return
  end

  for _,arg in ipairs(self.args) do
    preset[arg.name].value = self.doc["Arguments"][arg.name].value
  end

end

-------------------------------------------------------------------------------
-- remove preset 
-- @param idx (int)

function xStreamArgs:remove_preset(idx)
  TRACE("xStreamArgs:remove_preset(idx)",idx)

  local preset = self:get_preset_by_index(idx)
  if not preset then
    return
  end

  self.doc["Presets"]:remove(idx)
  self.presets_observable:remove(idx)

  if (idx == self.selected_preset_index) then
    self.selected_preset_index = 0
  elseif (idx < self.selected_preset_index) then
    self.selected_preset_index = self.selected_preset_index - 1   
  end

end


-------------------------------------------------------------------------------
-- TODO same as import, but without clearing existing presets

function xStreamArgs:append_bank()


end


-------------------------------------------------------------------------------
-- import all presets from xml file
-- @return bool, true when import was (at least partially) successful

function xStreamArgs:import_bank()
  TRACE("xStreamArgs:import_bank()")

  local ext = {"*.xml"}
  local title = "Import preset bank"
  local file_path = renoise.app():prompt_for_filename_to_read(ext,title)
  if (file_path == "") then
    LOG("Aborted loading...")
    return false
  end

  local fhandle = io.open(file_path,"r")
  if not fhandle then
    return false, "ERROR: Failed to open file handle"
  end

  local str_xml = fhandle:read("*a")
  local success,rslt = xParseXML.parse(str_xml)
  if not success then
    return false, rslt
  end

  -- clear existing presets before import 
  for i = self:get_number_of_presets(),1,-1 do
    self:remove_preset(i)
  end

  local last_inserted_preset_index = 0

  local arg_names = {}
  for _,arg in ipairs(self.args) do
    table.insert(arg_names,arg.name)
  end
  --print("arg_names",rprint(arg_names))

  for _,v in ipairs(rslt) do
    if (v.label == "xStreamArgDocument") then
      for __,v2 in ipairs(v) do
        if (v2.label == "Presets") then
          for k3,v3 in ipairs(v2) do
            if (v3.label == "Preset") then
             	local preset = renoise.Document.create("xStreamArgPreset"){}
              for ____,v4 in ipairs(v3) do
                local arg_index = table.find(arg_names,v4.label)
                if arg_index then
                  -- make sure we cast to right type, 
                  -- as XML are always defined as strings
                  local arg_type = type(self.args[arg_index].value)
                  if (arg_type == "number") then
                    preset:add_property(v4.label, tonumber(v4[1]))
                  elseif (arg_type == "boolean") then
                    preset:add_property(v4.label, (v4[1] == "true") and true or false)
                  else 
                    preset:add_property(v4.label, v4[1])
                  end
                else
                  --print("*** reject - ",v4.label)
                end
              end
              self.doc["Presets"]:insert(preset)
              --local name = self.get_suggested_preset_name(k3)
              self.presets_observable:insert(k3)
              last_inserted_preset_index = k3
            end
          end
        end
      end
    end
  end

  self.selected_preset_index = last_inserted_preset_index

  return true

end


-------------------------------------------------------------------------------
-- export all presets
-- @param name (string), provide a name (prompt user if not defined)
-- @return bool, true when export was successful

function xStreamArgs:export_bank()
  TRACE("xStreamArgs:export_bank()")

  local ext = "xml"
  local title = "Export all presets"
  local file_path = renoise.app():prompt_for_filename_to_write(ext,title)
  if (file_path == "") then
    LOG("Aborted saving...")
    return false
  end

  self.doc:save_as(file_path)

  return true

end

-------------------------------------------------------------------------------
-- update the selected preset

function xStreamArgs:get_selected_preset_index()
  TRACE("xStreamArgs:get_selected_preset_index()")
  return self.selected_preset_index_observable.value
end

function xStreamArgs:set_selected_preset_index(idx)
  TRACE("xStreamArgs:set_selected_preset_index(idx)",idx)

  local num_presets = self:get_number_of_presets()
  --print("num_presets",num_presets)

  if (num_presets == 0) then
    --error("there are no available presets")
    idx = 0
  end

  if idx and (idx > num_presets) then
    error("selected_preset_index needs to be between 1 and",num_presets)
  end

  self.selected_preset_index_observable.value = idx

end

-------------------------------------------------------------------------------

function xStreamArgs:get_number_of_presets()

  return #self.doc["Presets"]

end


-------------------------------------------------------------------------------
-- obtain suggested name for a preset

function xStreamArgs.get_suggested_preset_name(idx)
  TRACE("xStreamArgs:get_suggested_preset_name(idx)",idx)

  return "Preset #"..idx

end

-------------------------------------------------------------------------------

function xStreamArgs:get_length()
  TRACE("xStreamArgs:get_length()")

  return #self.args

end

-------------------------------------------------------------------------------
-- (re-)bind arguments when model or song has changed

function xStreamArgs:attach_to_song()
  TRACE("xStreamArgs:attach_to_song()")

  self:detach_from_song()

  for k,arg in ipairs(self.args) do
    if (arg.bind_notifier) then
      arg.bind = xStreamArg.resolve_binding(arg.bind_str)
      arg.bind:add_notifier(arg.bind_notifier)
      -- call it once, to initialize value
      arg.bind_notifier()
    end
  end

end

-------------------------------------------------------------------------------
-- when we switch away from the model using these argument

function xStreamArgs:detach_from_song()
  TRACE("xStreamArgs:detach_from_song()")

  for k,arg in ipairs(self.args) do
    if (arg.bind_notifier) then
      --print("*** detach_from_song - arg.bind_str",arg.bind_str)
      pcall(function()
        if arg.bind:has_notifier(arg.bind_notifier) then
          arg.bind:remove_notifier(arg.bind_notifier)
        end
      end) 
    end
  end

end

-------------------------------------------------------------------------------
-- execute running tasks for all registered arguments

function xStreamArgs:on_idle()
  --TRACE("xStreamArgs:on_idle()")

  for k,arg in ipairs(self.args) do
    if (type(arg.poll)=="function") then
      -- 'poll' - get current value 
      local rslt = arg.poll()
      if rslt then
        arg.observable.value = rslt
      end
    elseif (type(arg.value_update_requested) ~= "nil") then
      -- 'bind' requested an update
      arg.observable.value = arg.value_update_requested
      arg.value_update_requested = nil
    end
  end

end


-------------------------------------------------------------------------------
-- return arguments as a valid lua string, ready be to included
-- in a model definition - see also xStreamModel:serialize()
-- @return string

function xStreamArgs:serialize()
  TRACE("xStreamArgs:serialize()")

  local args = {}
  for idx,arg in ipairs(self.args) do

    local props = {}
    if arg.properties then
      -- remove default values from properties
      props = table.rcopy(arg.properties_initial)
      if (props.impacts_buffer == true) then
        props.impacts_buffer = nil
      end
    end

    table.insert(args,{
      name = arg.name,
      value = arg.value,
      properties = props,
      description = arg.description,
      bind = arg.bind_str,
      poll = arg.poll_str
    })

  end

  local presets = {}
  for i = 1,self:get_number_of_presets() do
    local preset = {}
    for k,v in ipairs(self.args) do
      preset[v.name] = self.doc["Presets"][i][v.name].value
    end
    table.insert(presets,preset)
  end

  local str_args = xLib.serialize_table(args)
  local str_presets = xLib.serialize_table(presets)

  return str_args,str_presets

end

