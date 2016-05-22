--[[============================================================================
xStreamModel
============================================================================]]--
--[[

	xStreamModel takes care of loading, saving and parsing xStream models

]]

--==============================================================================

class 'xStreamModel'

-- disallow the following lua methods/properties
xStreamModel.UNTRUSTED = {
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
  --"device_index", 
  --"param_index",
  "mute_mode",
  "output_mode",
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

xStreamModel.DEFAULT_NAME = "Untitled model"


-------------------------------------------------------------------------------
-- constructor
-- @param xstream (xStream)

function xStreamModel:__init(xstream)
  TRACE("xStreamModel:__init(xstream)",xstream,type(xstream))

  assert(type(xstream) == "xStream", "Wrong type of parameter")

  -- xStream, required
  self.xstream = xstream

  -- string, file location (if saved to, loaded from disk...)
  self.file_path = nil

  -- string 
  self.name = property(self.get_name,self.set_name)
  self.name_observable = renoise.Document.ObservableString("")

  -- number, valid 8-bit RGB representation (0xRRGGBB)
  self.color = property(self.get_color,self.set_color)
  self.color_observable = renoise.Document.ObservableNumber(0)

  -- function, provides us with content
  -- @param pos (int), 0 is first line
  -- @param num_lines (int), amount of lines to output
  -- @param xstr (xStream), reference to this class
  -- @return table<xLine>
  self.callback = nil

  -- string, text representation of the function 
  self.callback_str = property(self.get_callback_str,self.set_callback_str)
  self.callback_str_observable = renoise.Document.ObservableString("")

  -- string, compare against this to learn if modified
  -- (set whenver the callback is saved or loaded...)
  self.callback_str_source = nil

  -- boolean, true when the model definition has been changed
  self.modified = property(self.get_modified,self.set_modified)
  self.modified_observable = renoise.Document.ObservableBoolean(false)

  -- boolean, true when callback has been compiled 
  self.compiled = property(self.get_compiled,self.set_compiled)
  self.compiled_observable = renoise.Document.ObservableBoolean(false)

  -- xStreamArgs, describing the available arguments
  self.args = nil

  -- table<xStreamPresets>, list of active preset banks
  self.preset_banks = {}

  -- ObservableNumberList, notifier fired when banks are added/removed 
  self.preset_banks_observable = renoise.Document.ObservableNumberList()

  -- int, index of selected preset bank (0 = none)
  self.selected_preset_bank_index = property(self.get_preset_bank_index,self.set_preset_bank_index)
  self.selected_preset_bank_index_observable = renoise.Document.ObservableNumber(0)

  -- xStreamPresets, reference to selected preset bank (set via index)
  self.selected_preset_bank = property(self.get_selected_preset_bank)

  -- table<vararg>, variables, can be any basic type 
  self.data = nil

  -- table<vararg>, copy of data - revert when stopping/exporting
  self.data_initial = nil

  -- bool, when true we have redefined the xline (checked during compile)
  --self.user_redefined_xline = false

  -- table<string> limit to these tokens during output
  -- (derived from the code specified in the callback)
  self.output_tokens = {}

  -- define sandbox environment
  local env = {
    assert = _G.assert,
    ipairs = _G.ipairs,
    loadstring = _G.loadstring,
    math = _G.math,
    next = _G.next,
    pairs = _G.pairs,
    print = _G.print,
    select = _G.select,
    string = _G.string,
    table = _G.table,
    tonumber = _G.tonumber,
    tostring = _G.tostring,
    type = _G.type,
    unpack = _G.unpack,
    -- renoise extended
    ripairs = _G.ripairs,
    rprint = _G.rprint,
    -- access xlib methods/classes
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

  -- initialize -----------------------

  self:add_preset_bank(xStreamPresets.DEFAULT_BANK_NAME)
  self.selected_preset_bank_index = 1

  --self:load_preset_banks()

end

-------------------------------------------------------------------------------
-- Get/set methods
-------------------------------------------------------------------------------

function xStreamModel:get_name()
  if (self.name_observable.value == "") then
    return xStreamModel.DEFAULT_NAME
  end
  return self.name_observable.value
end

function xStreamModel:set_name(str)
  self.name_observable.value = str
end

-------------------------------------------------------------------------------

function xStreamModel:get_color()
  return self.color_observable.value
end

function xStreamModel:set_color(val)
  --print("val",val,"type",type(val))
  if (self.color_observable.value ~= val) then
    self.color_observable.value = val
    self.modified = true
  end
end

-------------------------------------------------------------------------------

function xStreamModel:get_callback_str()
  --TRACE("xStreamModel:get_callback_str - ",self.callback_str_observable.value)
  return self.callback_str_observable.value
end

function xStreamModel:set_callback_str(str)
  TRACE("xStreamModel:set_callback_str - ",#str)

  local modified = (str ~= self.callback_str_source) 
  self.modified = modified and true or self.modified

  self.callback_str_observable.value = str

  -- live syntax check
  local passed,err = self:test_syntax(str)
  self.xstream.callback_status_observable.value = passed and "" or err
  
  if not err and
    self.xstream.live_coding_observable.value
  then
    -- compile right away
    local passed,err = self:compile(str)
    if not passed then -- should not happen! 
      LOG(err)
    end
  else
    LOG(err)
  end


end


-------------------------------------------------------------------------------

function xStreamModel:get_modified()
  return self.modified_observable.value
end

function xStreamModel:set_modified(val)
  self.modified_observable.value = val
end

-------------------------------------------------------------------------------

function xStreamModel:get_compiled()
  return self.compiled_observable.value
end

function xStreamModel:set_compiled(val)
  self.compiled_observable.value = val
end

-------------------------------------------------------------------------------

function xStreamModel:get_preset_bank_index()
  return self.selected_preset_bank_index_observable.value
end

function xStreamModel:set_preset_bank_index(idx)
  if not self.preset_banks[idx] then
    LOG("Attempted to set out-of-range value for preset bank index")
    return
  end
  self.selected_preset_bank_index_observable.value = idx

  -- attach_to_preset_bank
  local obs = self.selected_preset_bank.modified_observable
  xObservable.attach(obs,self,self.handle_preset_changes)

end

-------------------------------------------------------------------------------

function xStreamModel:get_selected_preset_bank()
  return self.preset_banks[self.selected_preset_bank_index]
end

-------------------------------------------------------------------------------

function xStreamModel:get_preset_bank_by_name(str_name)
  return table.find(self:get_preset_bank_names(),str_name)
end

-------------------------------------------------------------------------------
-- Class methods
-------------------------------------------------------------------------------
-- load external model definition - will validate the function in a sandbox
-- @param file_path (string), prompt for file if not defined
-- @return bool, true when model was succesfully loaded
-- @return err, string containing error message

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

  -- confirm that file is likely a model definition
  -- (without parsing any code)
  local str_def,err = xFilesystem.load_string(file_path)
  --print(">>> load_definition - load_string - str_def,err",str_def,err)
  local passed = xStreamModel.looks_like_definition(str_def)
  if not passed then
    return false,"The string does not look like a model definition"
  end

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

  self.callback_str_source = def.callback
  self.file_path = file_path
  self.name = name

  local passed,err = self:parse_definition(def)
  if not passed then
    err = "ERROR: Failed to load the definition '"..name.."' - "..err
    return false,err
  end

  self:load_preset_banks()
  self.modified = false
  return true

end

-------------------------------------------------------------------------------
-- same as 'load_definition', but passing a string instead of file
-- @param str_def (string)
-- @return bool, true when model got loaded
-- @return string, error message on failure

function xStreamModel:load_from_string(str_def)
  TRACE("xStreamModel:load_from_string(str_def)",#str_def)

  local passed = xStreamModel.looks_like_definition(str_def)
  if not passed then
    return false,"The string does not look like a model definition"
  end

  local passed,err = pcall(function()
    assert(loadstring(str_def))
  end) 
  if not passed then
    err = "ERROR: Failed to load the definition - "..err
    return false,err
  end

  local def = assert(loadstring(str_def))()

  -- succesfully parsed, now apply settings...

  self.callback_str_source = def.callback
  self.name = xStreamModel.get_suggested_name(xStreamModel.DEFAULT_NAME)
  self.file_path = xStreamModel.get_normalized_file_path(self.name)
  
  local passed,err = self:parse_definition(def)
  if not passed then
    err = "ERROR: Failed to load the definition - "..err
    return false,err
  end

  self:load_preset_banks()
  self.modified = false
  return true


end

-------------------------------------------------------------------------------
-- @param def (table) definition table
-- return bool, true when model was succesfully loaded
-- return err, string containing error message

function xStreamModel:parse_definition(def)
  TRACE("xStreamModel:parse_definition(def)",def)

  -- default model options
  local color = vColor.color_table_to_value(xLib.COLOR_DISABLED)
  
  if not table.is_empty(def.options) then
    if (def.options.color) then
      --print("def.options.color",def.options.color)
      color = def.options.color
    end
  end

  self.color_observable.value = color

  -- create arguments
  self.args = xStreamArgs(self)
  if not table.is_empty(def.arguments) then
    for _,arg in ipairs(def.arguments) do
      --print("*** arg",rprint(arg))
      local passed,err = self.args:add(arg)
      --print("passed,err",passed,err)
      if not passed then
        err = "*** ERROR: xStreamModel:parse_definition - encountered errors: '"..err
        LOG(err)
        return false,err
      end
    end
  end

  -- clear existing presets
  self.selected_preset_bank_index = 1
  self.selected_preset_bank:remove_all_presets()

  -- create presets 
  if not table.is_empty(def.presets) then
    for _,v in ipairs(def.presets) do
      self.selected_preset_bank:add_preset(v)
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
  local passed,err = self:compile(def.callback)
  if not passed then
    return false, err
  end
  
  return true

end

-------------------------------------------------------------------------------
-- wrap callback in function with variable run-time arguments 
-- @param str_fn (string) function as string

function xStreamModel:prepare_callback(str_fn)
  TRACE("xStreamModel:prepare_callback(str_fn)",#str_fn)

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
  TRACE("xStreamModel:test_syntax(str_fn)",#str_fn)

  local function untrusted_fn()
    assert(loadstring(str_fn))
  end
  setfenv(untrusted_fn, self.env)
  local pass,err = pcall(untrusted_fn)
  if not pass then
    return false,err
  end

  return true

end

-------------------------------------------------------------------------------
-- nested block comments/longstrings are depricated in lua and will fail
-- to load if we save a model using these features
-- unfortunately, lua does not seem to agree with plain strings
-- that contains double brackets - instead, use brute-force 

function xStreamModel.get_comment_blocks(str_fn)
  TRACE("xStreamModel.get_comment_blocks(str_fn)",#str_fn)

  if string.find(str_fn,"%[%[") then
    return false
  elseif string.find(str_fn,"%]%]") then
    return false
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
  TRACE("xStreamModel:compile(str_fn)",#str_fn)

  assert(type(str_fn) == "string", "Expected string as parameter")

  -- access to model arguments/user-data
  self.env.args = self.args 
  self.env.data = self.data

  local str_combined = self:prepare_callback(str_fn)
  local syntax_ok,err = self:test_syntax(str_combined)
  if not syntax_ok then
    return false,err
  end

  -- safe to run 
  local def = loadstring(str_combined)
  self.callback = def()
  setfenv(self.callback, self.env)
  self.callback_str_observable.value = str_fn

  -- extract tokens for the output stage
  self.output_tokens = self:extract_tokens(str_fn)
  --print("*** tokens",rprint(self.output_tokens))

  --self.user_redefined_xline = self.check_if_redefined(str_fn)
  --print("self.user_redefined_xline",self.user_redefined_xline)

  self.compiled = true
  --self.modified = false

  return true

end

-------------------------------------------------------------------------------
-- extract functions (tokens), result is used in the output stage
-- @param str_fn (string)
-- @return table

function xStreamModel:extract_tokens(str_fn)
  TRACE("xStreamModel:extract_tokens(str_fn)",#str_fn)

  local rslt = {}

  -- combined note/effect-column tokens
  local all_tokens = {
    "note_value","note_string", 
    "instrument_value","instrument_string",
    "volume_value","volume_string",
    "panning_value","panning_string",
    "delay_value","delay_string",
    "number_value","number_string",
    "amount_value","amount_string",
  }

  for _,v in ipairs(all_tokens) do
    if string.find(str_fn,v) then
      table.insert(rslt,v)
    end
  end

  return rslt

end

-------------------------------------------------------------------------------
-- rename an argument within the callback - 
-- @param old_name (string)
-- @param new_name (string)

function xStreamModel:rename_argument(old_name,new_name)
  TRACE("xStreamModel:rename_argument(old_name,new_name)",old_name,new_name)

  local str_search = "args."..old_name
  local str_replace = "args."..new_name
  local str_patt = "(.?)("..str_search..")([^%w])"

  self.callback_str = string.gsub(self.callback_str,str_patt,function(...)
    local c1,c2,c3 = select(1,...),select(2,...),select(3,...)
    --print("c1,c2,c3",c1,c2,c3)
    local patt = "[%w_]" 
    if string.match(c1,patt) or string.match(c3,patt) then
      return c1..c2..c3
    end
    return c1..str_replace..c3
  end)

end

-------------------------------------------------------------------------------
-- check if we have redefined the xline in the callback function
-- @param str_fn (string)
-- @return bool
--[[
function xStreamModel.check_if_redefined(str_fn)

  local matched = (string.match(str_fn,"xline%s?=%s?") or
    string.match(str_fn,"xline.note_columns%s?=%s?") or
    string.match(str_fn,"xline.effect_columns%s?=%s?") or
    string.match(str_fn,"xline.automation%s?=%s?"))

  return matched and true or false

end
]]
-------------------------------------------------------------------------------
-- return the model (arguments, callback) as valid lua string

function xStreamModel:serialize()
  TRACE("xStreamModel:serialize()")

  local args,presets = self.args:serialize()

  local rslt = ""
  .."--[[==========================================================================="
  .."\n".. self.name .. ".lua"
  .."\n===========================================================================]]--"
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
	.."\noptions = {"
  .."\n color = "..vColor.value_to_hex_string(self.color)..","
  .."\n},"
	.."\ncallback = [[\n"
  ..self.callback_str
  .."\n]],"
  .."\n}"


  --print("xStreamModel:serialize()",rslt)
  return rslt

end

-------------------------------------------------------------------------------
-- revert to last saved model ()
-- @return bool, true when saved
-- @return string, error message when problem was encountered
--[[
function xStreamModel:revert()

  self.callback_str = self.callback_str_source
  
  if self.xstream.ui then
    self.xstream.ui:update_editor()
  end

end
]]

-------------------------------------------------------------------------------
-- refresh - (re-)load model from disk
-- @return bool, true when refreshed
-- @return string, error message when problem was encountered

function xStreamModel:refresh()
  TRACE("xStreamModel:refresh()")

  if self.modified then
    local str_msg = "Are you sure you want to (re-)load the model from disk?"
                  .."(this change cannot be undone)"
    local choice = renoise.app():show_prompt("Refresh model", str_msg, {"OK","Cancel"})
    if (choice == "Cancel") then
      return true
    end
  end

  self:detach_from_song()

  local success,err = self:load_definition(self.file_path)
  if not success then
    return false,err
  end

  self:attach_to_song()

  return true

end

-------------------------------------------------------------------------------
-- save model (prompt for file path if not already defined)
-- @param as_copy (bool), when invoked by 'save_as'
-- @return bool, true when saved
-- @return string, error message when problem was encountered

function xStreamModel:save(as_copy)
  TRACE("xStreamModel:save(as_copy)",as_copy)

  local file_path,name

  if not self.file_path or as_copy then
    file_path,name = self.prompt_for_location("Save as")
    if not file_path then
      return false
    end
    file_path = xFilesystem.unixslashes(file_path)
  else
    file_path = self.file_path
    name = self.name
  end
  
  local compiled_fn,err = self:compile(self.callback_str)
  if not compiled_fn then
    return false, "The callback contains errors that need to be "
                .."fixed before you can save it to disk:\n"..err
  end

  local comments = xStreamModel.get_comment_blocks(self.callback_str)
  if not comments then
    local str_msg = "Warning: the callback contains [[double brackets]], which need to"
                  .."\nbe removed from the code before the file can be saved"
                  .."\n(avoid using block comments and longstrings)"
    renoise.app():show_prompt("Strip comments",str_msg,{"OK"})
    return false
  end

  local got_saved,err = xFilesystem.write_string_to_file(file_path,self:serialize())
  if not got_saved then
    return false,err
  end

  if not as_copy then
    self.file_path = file_path
    self.name = name
    self.modified = false
    self.callback_str_source = self.callback_str
  end

  return true

end

-------------------------------------------------------------------------------
-- "save model as"
-- @return bool, true when saved
-- @return string, error message when problem was encountered

function xStreamModel:save_as()
  TRACE("xStreamModel:save_as()")
  
  local as_copy = true
  local passed,err = self:save(as_copy)
  if not passed then
    return false, err
  end

  return true

end

--------------------------------------------------------------------------------
-- rename model 

function xStreamModel:rename()
  TRACE("xStreamModel:rename()")

  --local model = self.xstream.selected_model

  local str_name,_ = vPrompt.prompt_for_string(self.name,
    "Enter a new name","Rename Model")
  if not str_name then
    return true
  end

  local str_from = self.file_path
  local folder,filename,ext = xFilesystem.get_path_parts(str_from)

  if not xFilesystem.validate_filename(str_name) then
    return false,"Please avoid using special characters in the name"
  end

  local str_to = ("%s%s.lua"):format(folder,str_name)
  --print("str_from,str_to",str_from,str_to)

  -- we might not yet have saved the model - skip in these cases...
  if io.exists(str_from) then
    if not io.exists(str_to) then
      if not os.rename(str_from,str_to) then
        return false,"Failed to rename, perhaps the file is in use by another application?"
      end
    else
      LOG("Warning: a model definition already exists at this location: "..str_to)
    end
  end

  -- update favorites to reflect new name
  self.xstream.favorites:rename_model(self.name,str_name)

  self.name = str_name
  self.file_path = str_to

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
  file_path = xFilesystem.unixslashes(file_path)

  local str_folder,str_filename,str_extension = 
    xFilesystem.get_path_parts(file_path)
  local name = xFilesystem.file_strip_extension(str_filename,str_extension)
  return file_path,name

end


-------------------------------------------------------------------------------
-- invoked when song or model has changed

function xStreamModel:attach_to_song()
  TRACE("xStreamModel:attach_to_song()")

  self.env.rns = rns
  local compiled_fn,err = self:compile(self.callback_str)
  if not compiled_fn then
    LOG("The callback contains errors: "..err)
  end
  self.args:attach_to_song()

end

-------------------------------------------------------------------------------

function xStreamModel:handle_preset_changes()
  TRACE("handle_preset_changes")
  if self:is_default_bank() then
    self.modified = true
  end
end

-------------------------------------------------------------------------------
-- invoked when song or model has changed

function xStreamModel:detach_from_song()
  TRACE("xStreamModel:detach_from_song()")

  self.args:detach_from_song()

end

-------------------------------------------------------------------------------
-- perform periodic updates

function xStreamModel:on_idle()

  -- argument polling
  self.args:on_idle()

end

-------------------------------------------------------------------------------
-- load all preset banks available to us
-- if problems occur, they are logged...

function xStreamModel:load_preset_banks()
  TRACE("xStreamModel:load_preset_banks()")

  local str_folder = xStream.PRESET_BANK_FOLDER..self.name.."/"
  --print("str_folder",str_folder)
  if io.exists(str_folder) then
    for __, filename in pairs(os.filenames(str_folder, "*.xml")) do
      --print("filename",filename)
      local filename_no_ext = xFilesystem.file_strip_extension(filename,"xml")
      local success,err = self:load_preset_bank(filename_no_ext)
      if not success then
        LOG("Failed while trying to load this preset bank: "..filename..", "..err)
      end
    end
  end

end


-------------------------------------------------------------------------------
-- load preset bank from our 'special' folder
-- @param str_name (string), the name of the bank
-- @return bool, true when loaded
-- @return string, error message when failed

function xStreamModel:load_preset_bank(str_name)
  TRACE("xStreamModel:load_preset_bank(str_name)",str_name)

  local preset_bank = xStreamPresets(self)
  preset_bank.name = str_name
  local file_path = preset_bank:path_to_xml(str_name)
  --print("file_path",file_path)

  if not io.exists(file_path) then
    return false, "Could not find a preset bank in the specified location"
  end

  local success,err = preset_bank:import(file_path,false)
  if not success then
    return false,err
  end

  table.insert(self.preset_banks,preset_bank)
  self.preset_banks_observable:insert(#self.preset_banks)

  return true

end

-------------------------------------------------------------------------------
-- @param str_name (string), prompt user if not defined
-- @return bool, true when created
-- @return string, error message

function xStreamModel:add_preset_bank(str_name)
  TRACE("xStreamModel:add_preset_bank(str_name)",str_name)

  if not str_name then

    -- supply a unique preset bank name (filename)
    local preset_folder = ("%s%s/Untitled.xml"):format(xStream.PRESET_BANK_FOLDER,self.name)
    local str_path = xFilesystem.ensure_unique_filename(preset_folder)
    str_name = xFilesystem.get_raw_filename(str_path)

    str_name = vPrompt.prompt_for_string(str_name,
      "Enter a name for the preset bank","Add Preset Bank")
    if not str_name then
      return false
    end
    if not xFilesystem.validate_filename(str_name) then
      local err = "Please avoid using special characters in the name"
      renoise.app():show_warning(err)
      return false
    end
  end

  local preset_bank = xStreamPresets(self)
  preset_bank.name = str_name
  table.insert(self.preset_banks,preset_bank)
  self.preset_banks_observable:insert(#self.preset_banks)

  return true

end

-------------------------------------------------------------------------------

function xStreamModel:remove_preset_bank(idx)
  TRACE("xStreamModel:remove_preset_bank(idx)",idx)

  local bank = self.preset_banks[idx]
  if not bank then
    LOG("Tried to remove non-existing preset bank")
    return
  end

  -- delete xml file
  bank:remove_xml()

  local old_name = bank.name

  if (idx <= self.selected_preset_bank_index) then
    self.selected_preset_bank_index = self.selected_preset_bank_index - 1
  end


  table.remove(self.preset_banks,idx)
  self.preset_banks_observable:remove(idx)

  -- favorites might be affected
  local favorites = self.xstream.favorites:get_by_preset_bank(old_name)
  if (#favorites > 0) then
    self.xstream.favorites.update_requested = true
  end


end

-------------------------------------------------------------------------------
-- retrieve preset from current bank by index
-- return table or nil

function xStreamModel:get_preset_by_index(idx)
  TRACE("xStreamModel:get_preset_by_index(idx)",idx)

  local preset_bank = self.selected_preset_bank
  local preset = preset_bank.presets[idx]
  if not preset then
    LOG("Tried to access a non-existing preset")
    return
  end

  return preset

end


-------------------------------------------------------------------------------
-- return table<string>

function xStreamModel:get_preset_bank_names()
  TRACE("xStreamModel:get_preset_bank_names()")

  local t = {}
  for _,v in ipairs(self.preset_banks) do
    table.insert(t,v.name)
  end
  return t

end

-------------------------------------------------------------------------------

function xStreamModel:is_default_bank()
  TRACE("xStreamModel:is_default_bank()")

  return (self.selected_preset_bank.name == xStreamPresets.DEFAULT_BANK_NAME)

end

-------------------------------------------------------------------------------
-- ensure that the name is unique (e.g. when creating new models)
-- @param str_name (string)
-- @return string

function xStreamModel.get_suggested_name(str_name)
  TRACE("xStreamModel.get_suggested_name(str_name)",str_name)

  local model_file_path = xStreamModel.get_normalized_file_path(str_name)
  local str_path = xFilesystem.ensure_unique_filename(model_file_path)
  local suggested_name = xFilesystem.get_raw_filename(str_path)
  return suggested_name

end

-------------------------------------------------------------------------------
-- return the path to the internal models 

function xStreamModel.get_normalized_file_path(str_name)

  return ("%s%s.lua"):format(xStream.MODELS_FOLDER,str_name)

end

-------------------------------------------------------------------------------
-- look for certain "things" to confirm that this is a valid definition
-- before actually parsing the string
-- @param str_def (string)
-- @return bool

function xStreamModel.looks_like_definition(str_def)

  if not string.find(str_def,"return[%s]*{") or
    not string.find(str_def,"arguments[%s]*=[%s]*{") or
    not string.find(str_def,"presets[%s]*=[%s]*{") or
    not string.find(str_def,"data[%s]*=[%s]*{") or
    not string.find(str_def,"options[%s]*=[%s]*{") or
    not string.find(str_def,"callback[%s]*=") 
  then
    return false
  else
    return true
  end

end
