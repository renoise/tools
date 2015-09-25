--[[============================================================================
xStreamModel
============================================================================]]--
--[[

	xStreamModel takes care of loading, saving and parsing xStream models

]]


class 'xStreamModel'

-- disallow the following lua methods/properties
xStreamModel.UNTRUSTED = {
  --"_G",
  "collectgarbage",
  "coroutine",
  "dofile",
  "io",
  "load",
  "loadfile",
  "module",
  "os",
  "setfenv",
  "class",
  "rawset",
  "rawget",
}

-- expose the following xstream properties (read/write) 
xStreamModel.PROXY_PROPS = {
  "clear_undefined",
  "expand_columns",
  "include_hidden",
  "automation_playmode",
  "track_index",
  "device_index",
  "param_index",
  "mute_mode",

}

-- mark the following as read-only properties
xStreamModel.PROXY_CONSTS = {
  "EMPTY_XLINE",
  "EMPTY_NOTE_COLUMNS",
  "EMPTY_EFFECT_COLUMNS",
  "NOTE_OFF_VALUE",
  "EMPTY_NOTE_VALUE",
  "EMPTY_VALUE",
}

-------------------------------------------------------------------------------
-- constructor
-- @param xstream (xStream)

function xStreamModel:__init(xstream)
  TRACE("xStreamModel:__init(xstream)",xstream,type(xstream))

  assert(type(xstream) == "xStream", "Wrong type of parameter")

  -- xStream, required
  self.xstream = xstream

  -- string 
  self.name = property(self.get_name,self.set_name)
  self.name_observable = renoise.Document.ObservableString("")

  -- string, file location (if saved to, loaded from disk...)
  self.file_path = nil

  -- function, provides us with content
  -- @param pos (int), 0 is first line
  -- @param num_lines (int), amount of lines to output
  -- @param xstr (xStream), reference to this class
  -- @return table<xLine>
  self.callback = nil

  -- string, text representation of the function 
  self.callback_str = property(self.get_callback_str,self.set_callback_str)
  self.callback_str_observable = renoise.Document.ObservableString("")

  -- boolean, true when user has edited the callback method 
  self.modified = property(self.get_modified,self.set_modified)
  self.modified_observable = renoise.Document.ObservableBoolean(false)

  -- xStreamArgs, class with it's own preset import/export mechanism
  self.args = nil

  -- table<vararg>, variables, can be any basic type 
  self.data = nil

  -- table<vararg>, copy of data - revert to this when stopping/exporting
  self.data_initial = nil

  -- bool, when true we have redefined the xline (checked during compile)
  self.user_redefined_xline = nil

  -- table<string> limit to these tokens during output
  self.output_tokens = {}

  -- define sandbox environment
  local env = {
    _G = _G,
    assert = assert,
    ipairs = ipairs,
    loadstring = loadstring,
    math = math,
    next = next,
    pairs = pairs,
    print = print,
    select = select,
    string = string,
    table = table,
    tonumber = tonumber,
    tostring = tostring,
    type = type,
    type = type,
    unpack = unpack,
    -- renoise extended
    ripairs = ripairs,
    rprint = rprint,
    -- selective xlib methods/classes
    xnote_column = xNoteColumn,
    xeffect_column = xEffectColumn,
    restrict_to_scale = xScale.restrict_to_scale,
    xScale = {
      SCALES = xScale.SCALES,
    },
    -- arrives from song
    rns = rns,
    -- arrives with model
    args = {}, 
    data = {}, 
  }

  self.env = env

  env = {}

  -- unset untrusted members
  --for k,v in ipairs(xStreamModel.UNTRUSTED) do
  --  env[v] = nil
  --end

  -- metatable (constants and shorthands)
  setmetatable(self.env,{
    __index = function (t,k)
      --print("metatable.__index",t,k)
      if (k == "EMPTY_NOTE_COLUMNS") then
        return {
            {},{},{},{},
            {},{},{},{},
            {},{},{},{},
          }
      elseif (k == "EMPTY_EFFECT_COLUMNS") then
        return {
            {},{},{},{},
            {},{},{},{},
          }
      elseif (k == "EMPTY_XLINE") then
        return {
          note_columns = {
            {},{},{},{},
            {},{},{},{},
            {},{},{},{},
          },
          effect_columns = {
            {},{},{},{},
            {},{},{},{},
          },
        }
      elseif (k == "NOTE_OFF_VALUE") then
        return xNoteColumn.NOTE_OFF_VALUE
      elseif (k == "EMPTY_NOTE_VALUE") then
        return xNoteColumn.EMPTY_NOTE_VALUE
      elseif (k == "EMPTY_VOLUME_VALUE") then
        return xNoteColumn.EMPTY_VOLUME_VALUE
      elseif (k == "EMPTY_VALUE") then
        return xLinePattern.EMPTY_VALUE
      elseif (k == "SUPPORTED_EFFECT_CHARS") then
        return xEffectColumn.SUPPORTED_EFFECT_CHARS
      elseif table.find(xStreamModel.PROXY_PROPS,k) then
        return self.xstream[k]
      elseif table.find(xStreamModel.UNTRUSTED,k) then
        error("Property or method is not allowed in a callback:"..k)
      else
        --print("got here",t,k,env[k])
        --print("*** access ",k)
        return env[k]
      end
    end,
    __newindex = function (t,k,v)
      if table.find(xStreamModel.PROXY_CONSTS,k) then
        error("Attempt to modify read-only member:"..k)
      elseif table.find(xStreamModel.PROXY_PROPS,k) then
        self.xstream[k] = v
      --elseif type(env[k] == "nil") then
        --error("Attempt to specify undefined :"..k)
      else
        --print("*** assign ",k,v)
        env[k] = v
      end
    end,
    __metatable = false -- prevent tampering
  })

 
end

-------------------------------------------------------------------------------

function xStreamModel:get_suggested_name()
  return "Untitled model"
end

-------------------------------------------------------------------------------

function xStreamModel:get_name()
  if (self.name_observable.value == "") then
    return self:get_suggested_name()
  end
  return self.name_observable.value
end

function xStreamModel:set_name(str)
  self.name_observable.value = str
end

-------------------------------------------------------------------------------

function xStreamModel:get_callback_str()
  --TRACE("xStreamModel:get_callback_str - ",self.callback_str_observable.value)
  return self.callback_str_observable.value
end

function xStreamModel:set_callback_str(str)
  --TRACE("xStreamModel:set_callback_str - ",str)
  if (str ~= self.callback_str_observable.value) then
    self.modified = true
    -- live syntax check
    -- perform with a small time delay 
    local passed,err = self:test_syntax(str)
    self.xstream.callback_status_observable.value = passed and "" or err
  end
  self.callback_str_observable.value = str
end

-------------------------------------------------------------------------------

function xStreamModel:get_modified()
  return self.modified_observable.value
end

function xStreamModel:set_modified(val)
  self.modified_observable.value = val
end

-------------------------------------------------------------------------------
-- load external model definition - will validate the function in a sandbox
-- @param file_path (string), prompt for file if not defined
-- return bool, true when model was succesfully loaded
-- return err, string containing error message

function xStreamModel:load_definition(file_path)
  TRACE("xStreamModel:load_definition(file_path)",file_path)

  assert(self.xstream,"No .xstream property was defined")

  if not file_path then
    file_path = renoise.app():prompt_for_filename_to_read({"*.lua"},"Load model definition")
    file_path = xFilesystem.unixslashes(file_path)
  end

  -- use the filename as the name for the model
  local str_folder,str_filename,str_extension = 
    xFilesystem.get_path_parts(file_path)
  local name = xFilesystem.file_strip_extension(str_filename,str_extension)

  -- check if we are able to load the definition
  local passed,err = pcall(function()
    assert(loadfile(file_path))
  end) 
  if not passed then
    err = "ERROR: Failed to load the definition '"..name.."' - "..err
    return false,err
  end

  local def = assert(loadfile(file_path))()
  --print("file_path,def",file_path,def,rprint(def))

  -- succesfully loaded, import and apply settings --------

  self.file_path = file_path
  self.name = name

  -- create arguments
  self.args = xStreamArgs(self)
  if not table.is_empty(def.arguments) then
    for _,arg in ipairs(def.arguments) do
      --print("*** arg",rprint(arg))
      passed,err = self.args:add(arg)
      if not passed then
        err = "ERROR: Failed to load the definition '"..name.."' - "..err
        return false,err
      end
    end
  end

  -- create presets 
  if not table.is_empty(def.presets) then
    for _,v in ipairs(def.presets) do
      self.args:add_preset(v)
    end
  end

  -- create user-data
  self.data = {}
  if not table.is_empty(def.data) then
    for k,v in pairs(def.data) do
      self.data[k] = v
    end
  end

  -- restore initial state with this
  self.data_initial = table.rcopy(self.data)

  -- process the callback method
  --print("about to compile - file_path",file_path)
  local compiled_fn,err = self:compile(def.callback)
  if not compiled_fn then
    return false, err
  end

  
  return true

end

-------------------------------------------------------------------------------
-- wrap callback in function with variable run-time arguments 
-- @param str_fn (string) function as string

function xStreamModel:prepare_callback(str_fn)

  -- arguments are defined via vararg(...)
  -- @param line_index (int), current line index
  -- @return table<xLine>
  local str_combined = [[return function(...)
  local xinc,xline,xpos = select(1, ...),select(2, ...),select(3, ...)
  ]]..str_fn..[[
  return xline
  end]]

  return str_combined

end

-------------------------------------------------------------------------------
-- check for syntax errors within our sandbox environment
-- wrap in assert for better-quality error messages
-- @param str_fn (string) function as string
-- @return boolean, true when method passed
-- @return string, error message when failed

function xStreamModel:test_syntax(str_fn)

  local function untrusted_fn()
    assert(loadstring(str_fn))
  end
  setfenv(untrusted_fn, self.env)
  local pass,err = pcall(untrusted_fn)
  if not pass then
    return false,err
  else 
    return true
  end


end

-------------------------------------------------------------------------------
-- Compilation of callback method is performed in a number of steps. It can
-- fail, but this should never render the model invalid. 
-- 1. check for syntax errors
-- 2. check for logic errors ("test-run") - TODO
-- 3. passed, extract tokens and update model
-- @param str_fn (string) function as string
-- @return boolean, true when method passed
-- @return string, error message when failed

function xStreamModel:compile(str_fn)
  TRACE("xStreamModel:compile(str_fn)",str_fn)

  assert(type(str_fn) == "string", "Expected string as parameter")

  -- model
  self.env.args = self.args 
  self.env.data = self.data
  -- xstream
  --self.env.clear_undefined = self.xstream.proxy.clear_undefined

  local str_combined = self:prepare_callback(str_fn)
  local syntax_ok,err = self:test_syntax(str_combined)
  if not syntax_ok then
    return false,err
  end

  -- safe to run 
  local def = loadstring(str_combined)
  self.callback = def()
  setfenv(self.callback, self.env)
  self.callback_str = str_fn

  -- extract tokens for the output stage
  self.output_tokens = self:extract_tokens(str_fn)
  --print("*** tokens",rprint(self.output_tokens))

  self.user_redefined_xline = self.check_if_redefined(str_fn)
  --print("self.user_redefined_xline",self.user_redefined_xline)

  self.modified = false

  return true

end

-------------------------------------------------------------------------------
-- extract functions (tokens), result is used in the output stage
-- @param str_fn (string)
-- @return table

function xStreamModel:extract_tokens(str_fn)
  TRACE("xStreamModel:extract_tokens(str_fn)",str_fn)

  local rslt = {}

  -- extract tokens
  -- TODO "note_add","note_sub","note_set", etc
  local all_tokens = {
    "note_value","note_string", 
    "instrument_value","instrument_string",
    "volume_value","volume_string",
    "panning_value","panning_string",
    "delay_value","delay_string",
    "number_value","number_string",
    "amount_value","amount_string",
  }

  for k,v in ipairs(all_tokens) do
    if string.find(str_fn,v) then
      table.insert(rslt,v)
    end
  end

  return rslt

end

-------------------------------------------------------------------------------
-- check if we have redefined the xline in the callback function
-- @param str_fn (string)
-- @return bool

function xStreamModel.check_if_redefined(str_fn)

  local matched = (string.match(str_fn,"xline%s?=%s?") or
    string.match(str_fn,"xline.note_columns%s?=%s?") or
    string.match(str_fn,"xline.effect_columns%s?=%s?") or
    string.match(str_fn,"xline.automation%s?=%s?"))

  return matched and true or false

end

-------------------------------------------------------------------------------
-- return the model (arguments, callback) as valid lua string

function xStreamModel:serialize()
  TRACE("xStreamModel:serialize()")

  local args,presets = self.args:serialize()

  local rslt = ""
  .."--[[============================================================================"
  .."\n" .. self.name .. ".lua"
  .."\n============================================================================]]--"
  .."\n"
  .."\nreturn {"
	.."\narguments = "
  ..args
  ..","
	.."\npresets = "
  ..presets
  ..","
	.."\ndata = "
  ..xLib.serialize_table(self.data_initial)
  ..","
	.."\ncallback = [[\n"
  ..self.callback_str
  .."\n]],"
  .."\n}"


  --print("xStreamModel:serialize()",rslt)
  return rslt

end

-------------------------------------------------------------------------------
-- save model (prompt for file path if not already defined)
-- @return bool, true when saved
-- @return string, error message when problem was encountered

function xStreamModel:save()
  TRACE("xStreamModel:save()")

  local file_path,name
  if not self.file_path then
    file_path,name = self.prompt_for_location("Save as")
    if not file_path then
      return false
    end
    file_path = xFilesystem.unixslashes(file_path)
    self.file_path = file_path
    self.name = name
  end
  --print("save() - name",name)
  
  -- test compile, return if failed
  local compiled_fn,err = self:compile(self.callback_str)
  --print("compiled_fn,err",compiled_fn,err)
  if not compiled_fn then
    return false, "The callback contains errors that need to be "
                .."fixed before you can save it to disk:\n"..err
  end

  xFilesystem.write_string_to_file(self.file_path,self:serialize())

  self.modified = false

  return true

end

-------------------------------------------------------------------------------
-- "save model as"
-- always prompt for file path, rename current model and save
-- @return bool, true when saved
-- @return string, error message when problem was encountered

function xStreamModel:save_as()
  TRACE("xStreamModel:save_as()")

  local file_path,name = self.prompt_for_location("Save as")
  if not file_path then
    return false
  end
  file_path = xFilesystem.unixslashes(file_path)

  self.file_path = file_path
  self.name = name
  
  local passed,err = self:save()
  if not passed then
    return false, err
  end

  return true

end

-------------------------------------------------------------------------------

function xStreamModel:reveal_location()
  TRACE("xStreamModel:reveal_location()")

  if self.file_path then
    renoise.app():open_path(self.file_path)
  end

end

-------------------------------------------------------------------------------
-- prompt for file path
-- @param str_title (string), title for file browser dialog
-- @return string or nil (file-path, complete path plus name)
-- @return string or nil (name only)

function xStreamModel.prompt_for_location(str_title)
  TRACE("xStreamModel.prompt_for_location(str_title)",str_title)

  local extension = "lua"
  local file_path = renoise.app():prompt_for_filename_to_write(extension,str_title)
  if (file_path == "") then
    return 
  end
  --print("*** prompt_for_location() - file_path",file_path,type(file_path))
  file_path = xFilesystem.unixslashes(file_path)

  local str_folder,str_filename,str_extension = 
    xFilesystem.get_path_parts(file_path)
  --print("str_filename",str_filename)
  local name = xFilesystem.file_strip_extension(str_filename,str_extension)

  return file_path,name

end


-------------------------------------------------------------------------------
-- invoked when song or model has changed

function xStreamModel:attach_to_song()
  TRACE("xStreamModel:attach_to_song()")

  self.env.rns = rns
  self.args:attach_to_song()

end


-------------------------------------------------------------------------------
-- invoked when song or model has changed

function xStreamModel:detach_from_song()
  TRACE("xStreamModel:detach_from_song()")

  self.args:detach_from_song()

end



