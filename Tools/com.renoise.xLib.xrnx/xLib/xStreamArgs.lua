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

function xStreamArgs:__init(xstream)
  TRACE("xStreamArgs:__init(xstream)",xstream)
  
  -- xStream, reference to owner
	self.xstream = xstream

  -- renoise.Document
  self.doc = nil

  -- table<xStreamArg>
  self.args = {}

  -- read-only copy of current values (used by callback)
  --self.values = property(self.get_values)

  -- int, read-only - number of registered arguments
  self.length = property(
    self.get_length)

  -- table<string>, name of each preset
  self.preset_names = {}

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
  
  -- TODO validate as proper lua variable name
  if (type(arg.name)~='string') then
    return false,"Argument name '"..arg.name.."' needs to be a proper lua variable name - no special characters or number as the first character"
  end

  -- avoid using existing or RESERVED_NAMES
  --print("*** got here",arg.name,type(self[arg.name]))
  if (type(self[arg.name]) ~= 'nil') or 
    (table.find(xStreamArgs.RESERVED_NAMES,arg.name)) 
  then
    --print("*** got here 2")
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
  arg.xstream = self.xstream

  local xarg = xStreamArg(arg)

  table.insert(self.args,xarg)
  --print("xarg.notifier",xarg.notifier)
 
  self.doc["Arguments"][arg.name]:add_notifier(xarg.notifier)

  -- simple read access, used by the callback method
  -- can apply some properties to the result, i.e. to make zero based 
  self[arg.name] = property(function()  
    local val = self.doc["Arguments"][arg.name].value
    if arg.properties.zero_based then
      val = val - 1
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
-- prompt user for a name 
-- @param str_name (string), suggested name
-- @param str_title (string), title of dialog
-- @return string

function xStreamArgs:prompt_for_name(str_name,str_title)
  TRACE("xStreamArgs:prompt_for_name(str_name,str_title)",str_name,str_title)

  local vb = renoise.ViewBuilder()
  local content_view = vb:column{
    margin = 8,
    vb:text{
      text = "Please enter a name",
    },
    vb:textfield{
      text = str_name,
      width = 100,
      notifier = function(str)
        str_name = str
      end,
    }
  }
  local key_handler = nil
  local title = str_title
  local button_labels = {"OK","Cancel"}

  local choice = renoise.app():show_custom_prompt(title, content_view, button_labels, key_handler)

  if (choice == "Cancel") then
    return
  end

  -- TODO validate that this name is without special characters
  -- needs to be able to save to disk

  return str_name

end

-------------------------------------------------------------------------------
-- add current values as a preset 
-- @param name (string)

function xStreamArgs:add_preset(name)
  TRACE("xStreamArgs:add_preset(name)",name)

 	local preset = renoise.Document.create("xStreamArgPreset"){} 
  --for _,arg_name in ipairs(self.names) do
  for _,arg in ipairs(self.args) do
    preset:add_property(arg.name, self.doc["Arguments"][arg.name])
  end
  self.doc["Presets"]:insert(preset)

  local idx = #self.doc["Presets"]
  self.preset_names[idx] = name
  self.selected_preset_index = idx

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

function xStreamArgs:rename_preset(idx)
  TRACE("xStreamArgs:add_preset(idx)",idx)

  local preset = self:get_preset_by_index(idx)
  if not preset then
    return
  end

  local name = self.preset_names[idx] or self.get_suggested_preset_name(idx)
  name = self:prompt_for_name(name,"Choose Preset Name")
  name = xFilesystem.sanitize_filename(name)

  self.preset_names[idx] = name

end

-------------------------------------------------------------------------------
-- recall preset 
-- @param idx (int)

function xStreamArgs:recall_preset(idx)
  TRACE("xStreamArgs:recall_preset(idx)",idx)

  local preset = self:get_preset_by_index(idx)
  if not preset then
    return
  end

  for _,arg in ipairs(self.args) do
    self.doc["Arguments"][arg.name].value = preset[arg.name].value
  end

  self.selected_preset_index = idx

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

  if (idx == self.selected_preset_index) then
    self.selected_preset_index = 0
  end

end


-------------------------------------------------------------------------------
-- import a preset from disk
-- @param file_path (string), if not specified show file browser
-- @return bool, true when preset was imported

function xStreamArgs:import_preset(file_path)

  if not file_path then
    file_path = renoise.app():prompt_for_filename_to_read({"*.xml"},"Import Preset")
  end
  if not file_path then
    return false
  end

  local folder,fname,ext = xFilesystem.get_path_parts(file_path)
  self:add_preset(fname) 

  local preset = self.doc["Presets"][self.selected_preset_index]
  preset:load_from(file_path)



end

-------------------------------------------------------------------------------
-- export a preset with the given name or index
-- @param idx (int), index of preset
-- @param name (string), provide a name (prompt user if not defined)
-- @return bool, true when export was successful

function xStreamArgs:export_preset(idx,name)
  TRACE("xStreamArgs:export_preset(idx,name)",idx,name)

  local preset = self:get_preset_by_index(idx)
  if not preset then
    return
  end
  
  if not name then
    name = self.preset_names[idx]
  end

  if not name then 
    name = self:prompt_for_name(
      self.get_suggested_preset_name(idx),"Choose Preset Name")
  end

  if not name then
    renoise.app():show_message("The preset needs a name before it can be saved")
    return false
  end

  name = xFilesystem.sanitize_filename(name)
  self.preset_names[idx] = name

  name = xFilesystem.file_add_extension(name,"xml")
  self.doc["Presets"][idx]:save_as(name)

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

  local num_presets = #self.doc["Presets"]
  --print("num_presets",num_presets)

  if (num_presets == 0) then
    error("there are no available presets")
    idx = 0
  end

  if idx and (idx > num_presets) then
    error("selected_preset_index needs to be between 1 and",#self.doc["Presets"])
  end

  self.selected_preset_index_observable.value = idx

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
      print("*** attach_to_song - arg.bind_str",arg.bind_str)
      --print("*** attach_to_song - arg.bind",arg.bind)
      --print("*** attach_to_song - arg.bind_notifier",arg.bind_notifier)
      arg.bind:add_notifier(arg.bind_notifier)
      --print("*** arg.bind:add_notifier...")
    end
  end

end

-------------------------------------------------------------------------------
-- when we switch away from the model using these argument

function xStreamArgs:detach_from_song()
  TRACE("xStreamArgs:attach_from_song()")

  for k,arg in ipairs(self.args) do
    if (arg.bind_notifier) then
      print("*** detach_from_song - arg.bind_str",arg.bind_str)
      --print("*** detach_from_song - arg.bind_notifier",arg.bind_notifier)
      --print("*** detach_from_song - arg.bind",arg.bind)
      pcall(function()
        if arg.bind:has_notifier(arg.bind_notifier) then
          arg.bind:remove_notifier(arg.bind_notifier)
          print("*** arg.bind:remove_notifier...")
        end
      end) 
    end
  end

end

-------------------------------------------------------------------------------
-- here we execute any associated polls

function xStreamArgs:on_idle()
  --TRACE("xStreamArgs:on_idle()")

  --rprint(self.polls)

  for k,arg in ipairs(self.args) do
    if (type(arg.poll)=="function") then
      -- execute and update argument accordingly
      local rslt = arg.poll()
      if rslt then
        --print("xStreamArgs:on_idle - ",arg.name,rslt)
        arg.observable.value = rslt
      end
    end
  end

end


-------------------------------------------------------------------------------
-- return arguments as a valid lua string, ready be to included
-- in a model definition - see also xStreamModel:serialize()
-- @return string

function xStreamArgs:serialize()
  TRACE("xStreamArgs:serialize()")

  local rslt = {}


  for idx,arg in ipairs(self.args) do

    -- remove default values from properties
    local props = table.rcopy(arg.properties)
    if (props.impacts_buffer == true) then
      props.impacts_buffer = nil
    end

    table.insert(rslt,{
      name = arg.name,
      value = arg.value,
      properties = props,
      description = arg.description,
      bind = arg.bind_str,
      poll = arg.poll_str
    })
  end

  local str_rslt = xLib.serialize_table(rslt)

  --print("xStreamArgs:serialize() - str_rslt",str_rslt)
  return str_rslt

end

