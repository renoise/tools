--[[============================================================================
xStreamModel
============================================================================]]--
--[[

	xStreamModel takes care of loading, saving and parsing xStream models

]]

--==============================================================================

class 'xStreamModel'

xStreamModel.DEFAULT_NAME = "Untitled model"

xStreamModel.CB_TYPE = {
  MAIN = "main",
  DATA = "data",
  EVENTS = "events",
}

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

  -- string, text representation of the function 
  self.callback_str = property(self.get_callback_str,self.set_callback_str)
  self.callback_str_observable = renoise.Document.ObservableString("")

  -- boolean, true when the model definition has been changed
  self.modified = property(self.get_modified,self.set_modified)
  self.modified_observable = renoise.Document.ObservableBoolean(false)

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
  self.data = {}

  -- ObservableBang, when data change somehow (remove, delete, rename...)
  self.data_observable = renoise.Document.ObservableBang()

  -- string, userdata definition - revert when stopping/exporting
  self.data_initial = nil

  -- table<xMidiMessage.TYPE=function>, event handlers
  self.events = {}

  -- ObservableBang, when events change somehow (remove, delete, rename...)
  self.events_observable = renoise.Document.ObservableBang()

  -- table<function>
  self.events_compiled = nil

  -- table<string> limit to these tokens during output
  -- (derived from the code specified in the callback)
  self.output_tokens = {}

  --- configure sandbox
  -- (add basic variables and a few utility methods)

  self.sandbox = xSandbox()
  self.sandbox.compile_at_once = true
  self.sandbox.str_prefix = [[
    xinc = select(1, ...)
    xline = select(2, ...)
    xpos = select(3, ...)
  ]]
  self.sandbox.str_suffix = [[
    return xline
  ]]

  local props_table = {

    -- Global

    ["rns"] = {
      access = function(env) 
        return rns 
      end,
    },
    ["renoise"] = {
      access = function(env) 
        return renoise 
      end,
    },

    ["xstream"] = {
      access = function(env) return self.xstream end,
    },

    -- Constants

    ["EMPTY_NOTE_COLUMNS"] = {
      access = function(env) 
        return xLine.EMPTY_NOTE_COLUMNS 
      end,
    },
    ["EMPTY_EFFECT_COLUMNS"] = {
      access = function(env) 
        return xLine.EMPTY_EFFECT_COLUMNS
      end,
    },
    ["EMPTY_XLINE"] = {
      access = function(env) 
        return xLine.EMPTY_XLINE
      end,
    },
    ["NOTE_OFF_VALUE"] = {
      access = function(env)
        return xNoteColumn.NOTE_OFF_VALUE
      end,
    },
    ["EMPTY_NOTE_VALUE"] = {
      access = function(env)
        return xNoteColumn.EMPTY_NOTE_VALUE
      end,
    },
    ["EMPTY_VOLUME_VALUE"] = {
      access = function(env)
        return xNoteColumn.EMPTY_VOLUME_VALUE
      end,
    },
    ["EMPTY_VALUE"] = {
      access = function(env)
        return xLinePattern.EMPTY_VALUE
      end,
    },
    ["SUPPORTED_EFFECT_CHARS"] = {
      access = function(env)
        return xEffectColumn.SUPPORTED_EFFECT_CHARS
      end,
    },

    -- Model properties

    ["args"] = {
      access = function(env) return self.args end,
    },
    ["data"] = {
      access = function(env) return self.data end,
    },

    -- xStream properties

    ["clear_undefined"] = {
      access = function(env) return self.xstream.clear_undefined end,
      assign = function(env,v) self.xstream.clear_undefined = v end,
    },
    ["expand_columns"] = {
      access = function(env) return self.xstream.expand_columns end,
      assign = function(env,v) self.xstream.expand_columns = v end,
    },
    ["include_hidden"] = {
      access = function(env) return self.xstream.include_hidden end,
      assign = function(env,v) self.xstream.include_hidden = v end,
    },
    ["automation_playmode"] = {
      access = function(env) return self.xstream.automation_playmode end,
      assign = function(env,v) self.xstream.automation_playmode = v end,
    },
    ["track_index"] = {
      access = function(env) return self.xstream.track_index end,
    },
    ["mute_mode"] = {
      access = function(env) return self.xstream.mute_mode end,
    },
    ["output_mode"] = {
      access = function(env) return self.xstream.output_mode end,
    },

    -- xStream objects

    ["playpos"] = {
      access = function(env) return self.xstream.stream.playpos end,
    },
    ["writepos"] = {
      access = function(env) return self.xstream.stream.writepos end,
    },
    ["buffer"] = {
      access = function(env) return self.xstream.buffer end,
    },
    ["voices"] = {
      access = function(env) return self.xstream.voicemgr.voices end,
    },
    ["voicemgr"] = {
      access = function(env) return self.xstream.voicemgr end,
    },

    -- Static classes 

    ["xLib"] = {
      access = function(env) return xLib end,
    },
    ["xStream"] = {
      access = function(env) return xStream end,
    },
    ["xTrack"] = {
      access = function(env) return xTrack end,
    },
    ["xTransport"] = {
      access = function(env) return xTransport end,
    },
    ["xScale"] = {
      access = function(env) return xScale end,
    },
    ["xMidiMessage"] = {
      access = function(env) return xMidiMessage end,
    },
    ["xOscMessage"] = {
      access = function(env) return xOscMessage end,
    },
    ["xAutomation"] = {
      access = function(env) return xAutomation end,
    },
    ["xParameter"] = {
      access = function(env) return xParameter end,
    },
    ["xPlayPos"] = {
      access = function(env) return xPlayPos end,
    },
    ["xAudioDevice"] = {
      access = function(env) return xAudioDevice end,
    },
    ["xPhraseManager"] = {
      access = function(env) return xAudioDevice end,
    },

  }

  self.sandbox.properties = props_table

  -- initialize -----------------------

  self.sandbox.modified_observable:add_notifier(function()
    self.modified = true
  end)

  self:add_preset_bank(xStreamPresets.DEFAULT_BANK_NAME)
  self.selected_preset_bank_index = 1

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
  return self.sandbox.callback_str_observable.value
end

function xStreamModel:set_callback_str(str)
  TRACE("xStreamModel:set_callback_str - ",#str)

  local modified = (str ~= self.sandbox.callback_str) 
  self.modified = modified and true or self.modified
  --print("self.modified",self.modified,self.name)

  -- live syntax check
  local passed,err = self.sandbox:test_syntax(str)
  self.xstream.callback_status_observable.value = passed and "" or err
  
  if not err then

    self.sandbox.callback_str_observable.value = str

    -- compile right away? 
    if self.xstream.prefs.live_coding.value then
      local passed,err = self.sandbox:compile()
      if not passed then -- should not happen! 
        LOG(err)
      end
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
-- reset to initial state

function xStreamModel:reset()

  self:parse_userdata(self.data_initial)
  self.modified = false

end

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
    return false,("The file '%s' does not look like a model definition"):format(file_path)
  end

  -- check if we are able to load the definition
  local passed,err = pcall(function()
    assert(loadfile(file_path))
  end) 
  if not passed then
    err = "*** Error: Failed to load the definition '"..name.."' - "..err
    return false,err
  end

  local def = assert(loadfile(file_path))()
  --print("file_path,def",file_path,def,rprint(def))

  -- succesfully loaded, import and apply settings --------

  self.callback_str = def.callback
  self.file_path = file_path
  self.name = name

  local passed,err = self:parse_definition(def)
  if not passed then
    err = "*** Error: Failed to load the definition '"..name.."' - "..err
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
    err = "*** Error: Failed to load the definition - "..err
    return false,err
  end

  local def = assert(loadstring(str_def))()

  -- succesfully parsed, now apply settings...

  self.callback_str = def.callback
  self.name = xStreamModel.get_suggested_name(xStreamModel.DEFAULT_NAME)
  self.file_path = xStreamModel.get_normalized_file_path(self.name)
  
  local passed,err = self:parse_definition(def)
  if not passed then
    err = "*** Error: Failed to load the definition - "..err
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

  self:parse_options(def.options)
  self:parse_arguments(def.arguments)
  self:parse_presets(def.presets)
  self:parse_userdata(def.data)
  self:parse_events(def.events)

  -- process the callback method ------

  --print("about to compile - file_path",file_path)
  self.callback_str = def.callback
  local passed,err = self.sandbox:compile()
  if not passed then
    return false, err
  end
  
  return true

end

-------------------------------------------------------------------------------
-- parse model options (color etc.)

function xStreamModel:parse_options(options_def)

  local color = vColor.color_table_to_value(xLib.COLOR_DISABLED)
  if not table.is_empty(options_def) then
    if (options_def.color) then
      --print("options_def.color",options_def.color)
      color = options_def.color
    end
  end

  self.color_observable.value = color


end

-------------------------------------------------------------------------------
-- create arguments

function xStreamModel:parse_arguments(args_def)
  TRACE("xStreamModel:parse_arguments(def)")
  
  self.args = xStreamArgs(self)
  if not table.is_empty(args_def) then
    for _,arg in ipairs(args_def) do
      --print("*** arg",rprint(arg))
      local passed,err = self.args:add(arg)
      --print("passed,err",passed,err)
      if not passed then
        err = "*** Error: xStreamModel:parse_definition - encountered errors: '"..err
        LOG(err)
        return false,err
      end
    end
  end

end

-------------------------------------------------------------------------------
-- model presets: clear existing, add new ones...

function xStreamModel:parse_presets(preset_def)
  TRACE("xStreamModel:parse_presets(def)")
  
  self.selected_preset_bank_index = 1
  self.selected_preset_bank:remove_all_presets()

  if not table.is_empty(preset_def) then
    for _,v in ipairs(preset_def) do
      self.selected_preset_bank:add_preset(v)
    end
  end

end

-------------------------------------------------------------------------------
-- @param data_def (table)
-- @return string, containing potential error message 

function xStreamModel:parse_userdata(data_def)
  TRACE("xStreamModel:parse_userdata(data_def)",data_def)
  
  self.data = {}
  self.data_initial = {}

  local str_status = ""

  if (type(data_def)=="table") then
    for k,v in pairs(data_def) do
      -- 1.48+ stores values as serialized string
      self.data_initial[k] = (type(data_def[k])=="table") 
        and xLib.serialize_table(data_def[k]) or data_def[k]
      if (type(v)=="table") then
        self.data[k] = v -- prior to 1.48
      elseif (type(v)=="string") then
        local str_fn = xSandbox.insert_return(v)
        --print(">>> str_fn",str_fn)
        local passed,err = self.sandbox:test_syntax(str_fn)
        --print("userdata - k,str_fn,passed,err",k,str_fn,passed,err)
        if passed then
          local fn = loadstring(str_fn)
          local passed,err = pcall(fn)
          if passed then
            self.data[k] = fn()
            if (type(self.data[k])=="function") then
              setfenv(self.data[k], self.sandbox.env)
            end
          end
        end
        if not passed then
          LOG("*** Failed to include userdata (bad syntax)",k,err)
          str_status = str_status..err
        end
      end

    end
  end

  self.modified = true

  --print(">>> parse_userdata - self.data",rprint(self.data))
  --print(">>> parse_userdata - self.data_initial",rprint(self.data_initial))

  return str_status

end

-------------------------------------------------------------------------------
-- rename event (update main callback)
-- @param old_name (string)
-- @param new_name (string)
-- @param cb_type (xStreamModel.CB_TYPE)

function xStreamModel:rename_callback(old_name,new_name,cb_type)
  TRACE("xStreamModel:rename_callback(old_name,new_name,cb_type)",old_name,new_name,cb_type)

  local str_fn = self.callback_str
  self.callback_str = xSandbox.rename_string_token(str_fn,old_name,new_name,cb_type..".")
  self.modified = true

  if (cb_type == xStreamModel.CB_TYPE.DATA) then
    self.data[new_name] = self.data[old_name]
    self.data[old_name] = nil
    self.data_initial[new_name] = self.data_initial[old_name]
    self.data_initial[old_name] = nil
    self.data_observable:bang()
    --print("self.data...",rprint(self.data))
  elseif (cb_type == xStreamModel.CB_TYPE.EVENTS) then
    self.events[new_name] = self.events[old_name]
    self.events[old_name] = nil
    self.events_compiled[new_name] = self.events_compiled[old_name]
    self.events_compiled[old_name] = nil
    self.events_observable:bang()
  else
    error("Unexpected callback type")
  end

end

-------------------------------------------------------------------------------
-- rename event (update main callback)
-- @param cb_type (xStreamModel.CB_TYPE)
-- @param cb_key (string), e.g. "midi.note_off"

function xStreamModel:remove_callback(cb_type,cb_key)
  TRACE("xStreamModel:remove_callback(cb_type,cb_key)",cb_type,cb_key)

  self.modified = true

  if (cb_type == xStreamModel.CB_TYPE.DATA) then
    self.data[cb_key] = nil
    self.data_initial[cb_key] = nil
    self.data_observable:bang()
  elseif (cb_type == xStreamModel.CB_TYPE.EVENTS) then
    self.events[cb_key] = nil
    self.events_compiled[cb_key] = nil
    self.events_observable:bang()
  else
    error("Unexpected callback type")
  end

end

-------------------------------------------------------------------------------

function xStreamModel:add_userdata(str_name,str_fn)
  TRACE("xStreamModel:add_userdata(str_name)",str_name,str_fn)

  if not str_fn then
    str_fn = [[-- provide a return value of some kind
return {"some_value"}
]]
  end

  self.data[str_name] = str_fn
  self.data_initial[str_name] = str_fn

  self.modified = true
  self.data_observable:bang()

end

-------------------------------------------------------------------------------
-- @param str_name (string), event key - e.g. "midi.note_on" or "args.tab.arg"
-- @param str_fn (string) the function as text

function xStreamModel:add_event(str_name,str_fn)
  TRACE("xStreamModel:add_event(str_name,str_fn)",str_name,str_fn)

  if not str_fn then
    local parts = xLib.split(str_name,"%.") -- split at dot
    if (parts[1] == "midi") then
      str_fn = [[------------------------------------------------------------------------------
-- respond to MIDI ']] .. parts[2] .. [[' messages
-- @param xmsg, the xMidiMessage we have received
------------------------------------------------------------------------------
]]
    elseif (parts[1] == "voice") then
      str_fn = [[------------------------------------------------------------------------------
-- respond to voice-manager events
-- @param arg (table) {type = xVoiceManager.EVENTS, index = int}
------------------------------------------------------------------------------
]]
    elseif (parts[1] == "args") then
      str_fn = [[------------------------------------------------------------------------------
-- respond to argument ']] .. parts[2] .. [[' changes
-- @param val (number/boolean/string)}
------------------------------------------------------------------------------
]]
    else 
      error("Unexpected event type")
    end

  end

  self.events[str_name] = str_fn
  self.events_compiled[str_name] = nil

  self:parse_events()

  self.modified = true
  self.events_observable:bang()

end

-------------------------------------------------------------------------------
-- parse and refresh event handlers
-- @param event_def (table)

function xStreamModel:parse_events(event_def)
  TRACE("xStreamModel:parse_events(def)")

  self.events_compiled = {}
  local str_status = ""

  if (type(event_def)=="table") and not table.is_empty(event_def) then
    self.events = {}
    for k,v in pairs(event_def) do
      self.events[k] = v
    end
  end

  if not (type(self.events)=="table") then
    return
  end

  for k,v in pairs(self.events) do
    
    local str_fn = nil
    local parts = xLib.split(k,"%.") -- split at dot

    if (parts[1] == "midi") then
      -- arguments for midi event
      str_fn = [[
local xmsg = select(1,...)
]]..v
    elseif (parts[1] == "voice") then
      -- arguments for voice event
      str_fn = [[
local arg = select(1,...)
]]..v
    elseif (parts[1] == "args") then
      -- value for args event
      str_fn = [[
local val = select(1,...)
]]..v
    else 
      error("Unexpected event type")
    end

    local passed,err = self.sandbox:test_syntax(str_fn)
    if passed then
      self.events_compiled[k] = loadstring(str_fn)
      setfenv(self.events_compiled[k], self.sandbox.env)
    else
      LOG("*** Failed to include event (bad syntax)",k,err)
      str_status = str_status .. err
    end
  end

  self.modified = true

  --print(">>> parse_events - self.events",str_status,rprint(self.events))

  return str_status

end

-------------------------------------------------------------------------------
-- extract functions (tokens), result is used in the output stage
-- @param str_fn (string)
-- @return table
--[[
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
]]
-------------------------------------------------------------------------------
-- return the model (arguments, callback) as valid lua string

function xStreamModel:serialize()
  TRACE("xStreamModel:serialize()")

  local args,presets = self.args:serialize()
  local max_depth,longstring = nil,true

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
  ..xLib.serialize_table(self.data_initial,max_depth,longstring)
  ..","
	.."\nevents = "
  ..xLib.serialize_table(self.events,max_depth,longstring)
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

  local compiled_fn,err = self.sandbox:test_syntax(self.callback_str)
  if not compiled_fn then
    return false, "The callback contains errors that need to be "
                .."fixed before you can save it to disk:\n"..err
  end

  local comments = xSandbox.contains_comment_blocks(self.callback_str)
  if comments then
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
    --self.callback_str_source = self.sandbox.callback_str
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

  --[[
  self.env.rns = rns

  local compiled_fn,err = self:compile(self.callback_str)
  if not compiled_fn then
    LOG("The callback contains errors: "..err)
  end
  ]]
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

  local prefs = renoise.tool().preferences
  local preset_bank_folder = prefs.user_folder.value..xStream.PRESET_BANK_FOLDER
  local str_folder = preset_bank_folder..self.name.."/"
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
    local prefs = renoise.tool().preferences
    local preset_bank_folder = prefs.user_folder.value..xStream.PRESET_BANK_FOLDER
    local preset_folder = ("%s%s/Untitled.xml"):format(preset_bank_folder,self.name)
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
-- produce a valid, unique data/event key (name)
-- @param str_name (string), preferred name
-- @param type (string, "events" or "data")
-- @return string, a unique name for the callback

function xStreamModel:get_suggested_callback_name(str_name,cb_type)
  TRACE("xStreamModel:get_suggested_callback_name(str_name,cb_type)",str_name,cb_type)

  -- for events, check the part after the dot 
  local key_name = str_name
  if (cb_type==xStreamModel.CB_TYPE.EVENTS) then
    local parts = xLib.split(str_name,"%.") -- split at dot
    key_name = parts[1]
  end
  --print("get_suggested_callback_name - key_name",key_name)

  local passed,err = xReflection.is_valid_identifier(key_name)
  if not passed then
    -- TODO strip illegal characters
    return false, err
  end

  local key_exists = function(key,cb_type)
    if (cb_type==xStreamModel.CB_TYPE.DATA) then
      --print("key,type(self.data[key]",key,type(self.data[key]))
      return (type(self.data[key]) ~= "nil")
    elseif (cb_type==xStreamModel.CB_TYPE.EVENTS) then
      return (type(self.events[key]) ~= "nil")
    else
      error("Unexpected callback type")
    end
  end

  local count = xLib.detect_counter_in_str(str_name)
  --print("count",count)

  local rslt = str_name
  
  if (cb_type==xStreamModel.CB_TYPE.DATA) then
    -- keep increasing count 
    while (key_exists(rslt,cb_type)) do
      rslt = ("%s_%d"):format(str_name,count)
      count = count + 1
    end
  elseif (cb_type==xStreamModel.CB_TYPE.EVENTS) then
    -- fail when name exists
    if (key_exists(rslt,cb_type)) then
      return false, "This event is already defined"
    end
  else
    error("Unexpected callback type")
  end

  return rslt

end


-------------------------------------------------------------------------------
-- return the path to the internal models 

function xStreamModel.get_normalized_file_path(str_name)
  local prefs = renoise.tool().preferences
  local models_folder = prefs.user_folder.value .. xStream.MODELS_FOLDER
  return ("%s%s.lua"):format(models_folder,str_name)
end

-------------------------------------------------------------------------------
-- look for certain "things" to confirm that this is a valid definition
-- before actually parsing the string
-- @param str_def (string)
-- @return bool

function xStreamModel.looks_like_definition(str_def)

  local pre = '\[?\"?'
  local post = '\]?\"?[%s]*=[%s]*{'

  --print(pre.."arguments"..post)

  if not string.find(str_def,"return[%s]*{") or
    not string.find(str_def,pre.."arguments"..post) or
    not string.find(str_def,pre.."presets"..post) or
    not string.find(str_def,pre.."data"..post) or
    not string.find(str_def,pre.."options"..post) or
    not string.find(str_def,pre.."callback"..post) 
  then
    return false
  else
    return true
  end

end

