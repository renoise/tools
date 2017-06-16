--[[===============================================================================================
xStreamModel
===============================================================================================]]--
--[[

	xStreamModel takes care of loading, saving and parsing xStream models

]]

--=================================================================================================

class 'xStreamModel'

xStreamModel.DEFAULT_NAME = "Untitled model"
xStreamModel.FOLDER_NAME = "models/"
xStreamModel.ROOT_PATH = renoise.tool().bundle_path..xStreamModel.FOLDER_NAME

-- available callback types
xStreamModel.CB_TYPE = {
  MAIN = "main",
  DATA = "data",
  EVENTS = "events",
}

xStreamModel.DEFAULT_DATA_STR = [[-- specify an initial value for the variable
return %s
]]

---------------------------------------------------------------------------------------------------
-- constructor
-- @param buffer (xStreamBuffer)
-- @param voicemgr (xVoiceManager)
-- @param output_message (function) callback, intended for real-time preview/playback
--  ()

function xStreamModel:__init(buffer,voicemgr,output_message)
  TRACE("xStreamModel:__init(buffer,voicemgr,output_message)",buffer,voicemgr,output_message)

  assert(type(buffer) == "xStreamBuffer",type(buffer))
  assert(type(voicemgr) == "xVoiceManager",type(voicemgr))
  assert(type(output_message) == "function",type(output_message))

  --- xStreamBuffer
  self.buffer = buffer

  --- xStreamPrefs, current settings
  self.prefs = renoise.tool().preferences

  --- string, file location (if saved to, loaded from disk...)
  self.file_path = nil

  --- string 
  self.name = property(self.get_name,self.set_name)
  self.name_observable = renoise.Document.ObservableString("")

  --- number, valid 8-bit RGB representation (0xRRGGBB)
  self.color = property(self.get_color,self.set_color)
  self.color_observable = renoise.Document.ObservableNumber(0)

  --- string, text representation of the function 
  self.callback_str = property(self.get_callback_str,self.set_callback_str)
  --self.callback_str_observable = renoise.Document.ObservableString("")

  --- bool, true when the callback is not blank space / comments
  -- (use this to skip processing when not needed...)
  self.callback_contains_code = false

  --- signal when code was succesfully compiled 
  self.compiled_observable = renoise.Document.ObservableBang()

  --- boolean, true when the model definition has been changed
  -- due to changed callback, arguments, name, color ...
  self.modified = property(self.get_modified,self.set_modified)
  self.modified_observable = renoise.Document.ObservableBoolean(false)

  --- xStreamArgs, describing the available arguments
  self.args = nil

  --- table<xStreamModelPresets>, list of active preset banks
  self.preset_banks = {}

  --- ObservableNumberList, notifier fired when banks are added/removed 
  self.preset_banks_observable = renoise.Document.ObservableNumberList()

  self.selected_preset_index = property(self.get_preset_index,self.set_preset_index)

  --- int, index of selected preset bank (0 = none)
  self.selected_preset_bank_index = property(self.get_preset_bank_index,self.set_preset_bank_index)
  self.selected_preset_bank_index_observable = renoise.Document.ObservableNumber(0)

  -- xStreamModelPresets, reference to selected preset bank (set via index)
  self.selected_preset_bank = property(self.get_selected_preset_bank)

  --- table<vararg>, variables, can be any basic type 
  self.data = {}

  --- ObservableBang, when data change somehow (remove, delete, rename...)
  self.data_observable = renoise.Document.ObservableBang()

  --- string, userdata definition - revert when stopping/exporting
  self.data_initial = nil

  --- table<xMidiMessage.TYPE=function>, event handlers
  self.events = {}

  --- ObservableBang, when events change somehow (remove, delete, rename...)
  self.events_observable = renoise.Document.ObservableBang()

  --- table<function>
  self.events_compiled = {}

  --- ObservableBang, to produce new output when model is part of a stack
  self.on_rebuffer = renoise.Document.ObservableBang()

  --- configure sandbox
  -- (add basic variables and a few utility methods)

  self.sandbox = cSandbox()

  --== notifiers ==--

  local preset_observable_notifier = function()
    TRACE(">>> xStreamModel - preset_bank.presets_observable fired...")
    if self:is_default_bank() then
      self.modified = true
    end
  end

  self.selected_preset_bank_index_observable:add_notifier(function()
    local preset_bank = self.selected_preset_bank
    cObservable.attach(preset_bank.presets_observable,preset_observable_notifier)
  end)

  --== initialize ==--

  self:configure_sandbox()

  self.sandbox.modified_observable:add_notifier(function()
    self.modified = true
  end)

  self:add_preset_bank(xStreamModelPresets.DEFAULT_BANK_NAME)
  self.selected_preset_bank_index = 1

end

---------------------------------------------------------------------------------------------------
-- Get/set methods
---------------------------------------------------------------------------------------------------

function xStreamModel:get_name()
  if (self.name_observable.value == "") then
    return xStreamModel.DEFAULT_NAME
  end
  return self.name_observable.value
end

function xStreamModel:set_name(val)
  if (self.name_observable.value ~= val) then
    self.name_observable.value = val
    self.modified = true
  end  
end

---------------------------------------------------------------------------------------------------

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

---------------------------------------------------------------------------------------------------

function xStreamModel:get_callback_str()
  --TRACE("xStreamModel:get_callback_str - ",self.callback_str_observable.value)
  return self.sandbox.callback_str_observable.value
end

function xStreamModel:set_callback_str(str_fn)
  TRACE("xStreamModel:set_callback_str - ",#str_fn)

  local modified = (str_fn ~= self.sandbox.callback_str) 
  if modified then
    self.modified = modified 
  end
  --print("self.modified",self.modified,self.name)

  -- check if the callback contain any code at all? 
  self.callback_contains_code = cSandbox.contains_code(str_fn)

  -- live syntax check
  -- (a bit 'funny'' to set the buffer status from here, but...)
  local passed,err = self.sandbox:test_syntax(str_fn)
  self.buffer.callback_status_observable.value = passed and "" or err
  if err then
    LOG(err)
    return
  end 

  self.sandbox.callback_str_observable.value = str_fn

  local passed,err = self.sandbox:compile()
  if not passed then 
    self.buffer.callback_status_observable.value = err  
    LOG(err)
    return
  end
  -- process is listening for this  
  self.compiled_observable:bang()

end

---------------------------------------------------------------------------------------------------

function xStreamModel:get_modified()
  return self.modified_observable.value
end

function xStreamModel:set_modified(val)
  self.modified_observable.value = val
end

---------------------------------------------------------------------------------------------------

function xStreamModel:get_preset_index()

  if not self.selected_preset_bank then
    return 0
  end
  return self.selected_preset_bank.selected_preset_index
end

function xStreamModel:set_preset_index(val)

  if (self.selected_preset_bank_index == 0) then
    LOG("*** Can't set preset index - no bank selected")
    return
  end 

  if (val > #self.selected_preset_bank.presets) then
    LOG("*** Can't set preset index - out of range")
    return
  end

  self.selected_preset_bank.selected_preset_index = val

end

---------------------------------------------------------------------------------------------------

function xStreamModel:get_preset_bank_index()
  return self.selected_preset_bank_index_observable.value
end

function xStreamModel:set_preset_bank_index(idx)
  if not self.preset_banks[idx] then
    LOG("*** Attempted to set out-of-range value for preset bank index")
    return
  end
  self.selected_preset_bank_index_observable.value = idx

  -- attach_to_preset_bank
  local obs = self.selected_preset_bank.modified_observable
  cObservable.attach(obs,self,self.handle_preset_changes)

end

---------------------------------------------------------------------------------------------------

function xStreamModel:get_selected_preset_bank()
  return self.preset_banks[self.selected_preset_bank_index]
end

---------------------------------------------------------------------------------------------------

function xStreamModel:get_preset_bank_by_name(str_name)
  return table.find(self:get_preset_bank_names(),str_name)
end

---------------------------------------------------------------------------------------------------
-- Class methods
---------------------------------------------------------------------------------------------------
-- reset to initial state

function xStreamModel:reset()
  TRACE("xStreamModel:reset()")

  self:parse_data(self.data_initial)
  self.modified = false

end

---------------------------------------------------------------------------------------------------

function xStreamModel:configure_sandbox()
  TRACE("xStreamModel:configure_sandbox()")

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

    -- globals

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
    
    -- constants

    ["EMPTY_NOTE_COLUMNS"] = {
      access = function(env) 
        return table.rcopy(xLine.EMPTY_NOTE_COLUMNS)
      end,
    },
    ["EMPTY_EFFECT_COLUMNS"] = {
      access = function(env) 
        return table.rcopy(xLine.EMPTY_EFFECT_COLUMNS)
      end,
    },
    ["EMPTY_XLINE"] = {
      access = function(env) 
        return table.rcopy(xLine.EMPTY_XLINE)
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
        return table.rcopy(xEffectColumn.SUPPORTED_EFFECT_CHARS)
      end,
    },

    -- model props

    ["args"] = {
      access = function(env) return self.args end,
    },
    ["data"] = {
      access = function(env) return self.data end,
    },

    -- buffer 

    ["clear_undefined"] = {
      access = function(env) return self.buffer.clear_undefined end,
      assign = function(env,v) self.buffer.clear_undefined = v end,
    },
    ["expand_columns"] = {
      access = function(env) return self.buffer.expand_columns end,
      assign = function(env,v) self.buffer.expand_columns = v end,
    },
    ["include_hidden"] = {
      access = function(env) return self.buffer.include_hidden end,
      assign = function(env,v) self.buffer.include_hidden = v end,
    },
    ["automation_playmode"] = {
      access = function(env) return self.buffer.automation_playmode end,
      assign = function(env,v) self.buffer.automation_playmode = v end,
    },
    ["read_track"] = {
      access = function(env) return 
        rns.tracks[self.buffer.read_track_index]  
          and rns.tracks[self.buffer.read_track_index] 
          or rns.selected_track -- provide fallback
      end,
    },
    ["write_track"] = {
      access = function(env) return 
        rns.tracks[self.buffer.write_track_index]  
          and rns.tracks[self.buffer.write_track_index] 
          or rns.selected_track -- provide fallback
      end,
    },
    ["read_track_index"] = {
      access = function(env) return self.buffer.read_track_index end,
    },
    ["write_track_index"] = {
      access = function(env) return self.buffer.write_track_index end,
    },
    ["mute_mode"] = {
      access = function(env) return self.buffer.mute_mode end,
    },
    ["output_mode"] = {
      access = function(env) return self.output_mode end,
    },

    -- class instances

    --["xmodel"] = {
    --  access = function(env) return self end,
    --},
    ["xbuffer"] = {
      access = function(env) return self.buffer end,
    },
    --["xplaypos"] = {
    --  access = function(env) return self.stack.xpos.playpos end,
    --},
    --["xstream"] = {
    --  access = function(env) return self.stack.xstream end,
    --},
    ["xvoicemgr"] = {
      access = function(env) return self.voicemgr end,
    },
    ["output_message"] = {
      access = function(env) return self.output_message end,
    },

    -- classes 

    ["cLib"] = {
      access = function(env) return cLib end,
    },
    ["xLib"] = {
      access = function(env) return xLib end,
    },
    ["xLine"] = {
      access = function(env) return xLine end,
    },
    ["xStream"] = {
      access = function(env) return xStream end,
    },
    ["xStreamPos"] = {
      access = function(env) return xStreamPos end,
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
    ["xNoteColumn"] = {
      access = function(env) return xNoteColumn end,
    },
    ["xEffectColumn"] = {
      access = function(env) return xEffectColumn end,
    },
    ["xOscMessage"] = {
      access = function(env) return xOscMessage end,
    },
    ["xAutomation"] = {
      access = function(env) return xAutomation end,
    },
    ["xPatternPos"] = {
      access = function(env) return xPatternPos end,
    },
    ["xPatternSequencer"] = {
      access = function(env) return xPatternSequencer end,
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
    ["xLFO"] = {
      access = function(env) return xLFO end,
    },

  }

  self.sandbox.properties = props_table

end

---------------------------------------------------------------------------------------------------
-- Handle incoming MIDI/voice-manager/argument events - 
-- @param event_key (string), e.g. "midi.note_on" or "args.instr_idx"
-- @param arg (number/boolean/string/table) value to pass 

function xStreamModel:handle_event(event_key,arg)
  TRACE("xStreamModel:handle_event(event_key,arg)",event_key,arg)

  local handler = self.events_compiled[event_key]
  if handler then
    --print("about to handle event",event_key,arg,self.name)
    local passed,err = pcall(function()
      handler(arg)
    end)
    if not passed then
      LOG("*** Error while handling event",err)
    end
  end

end


---------------------------------------------------------------------------------------------------
-- Load external model definition - will validate the function in a sandbox
-- @param file_path (string), prompt for file if not defined
-- @return bool, true when model was succesfully loaded
-- @return err, string containing error message

function xStreamModel:load_definition(file_path)
  TRACE("xStreamModel:load_definition(file_path)",file_path)

  if not file_path then
    file_path = renoise.app():prompt_for_filename_to_read({"*.lua"},"Load model definition")
    file_path = cFilesystem.unixslashes(file_path)
  end

  -- use the filename as the name for the model
  local str_folder,str_filename,str_extension = 
    cFilesystem.get_path_parts(file_path)
  local name = cFilesystem.file_strip_extension(str_filename,str_extension)

  -- confirm that file is likely a model definition
  -- (without parsing any code)
  local str_def,err = cFilesystem.load_string(file_path)
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

---------------------------------------------------------------------------------------------------
-- Same as 'load_definition', but passing a string instead of file
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

---------------------------------------------------------------------------------------------------
-- @param def (table) definition table
-- return bool, true when model was succesfully loaded
-- return err, string containing error message

function xStreamModel:parse_definition(def)
  TRACE("xStreamModel:parse_definition(def)",def)

  self:parse_options(def.options)
  self:parse_arguments(def.arguments)
  self:parse_presets(def.presets)
  self:parse_data(def.data)
  self:parse_events(def.events)

  -- process the callback method ------

  --print("about to compile - file_path",file_path)
  self.callback_str = def.callback
  local passed,err = self.sandbox:compile()
  if not passed then
    return false, err
  end

  -- detach from song - only the selected model
  -- should receive active notifications
  self:detach_from_song()
  
  return true

end

---------------------------------------------------------------------------------------------------
-- parse model options (color etc.)

function xStreamModel:parse_options(options_def)

  local color = cColor.color_table_to_value(xLib.COLOR_DISABLED)
  if not table.is_empty(options_def) then
    if (options_def.color) then
      --print("options_def.color",options_def.color)
      color = options_def.color
    end
  end

  self.color_observable.value = color


end

---------------------------------------------------------------------------------------------------
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

  self.args.args_observable:add_notifier(function()
   --">>> xStreamModel - args.args_observable fired... ")
    self.modified = true
  end)

end

---------------------------------------------------------------------------------------------------
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

---------------------------------------------------------------------------------------------------
-- @param data_def (table), new userdata definitions 
-- @return string, containing potential error message 

function xStreamModel:parse_data(data_def)
  TRACE("xStreamModel:parse_data(data_def)",data_def)

  self.data = {}
  self.data_initial = {}

  local str_status = ""

  if (type(data_def)=="table") then
    for k,v in pairs(data_def) do
      -- 1.48+ stores values as serialized string
      self.data_initial[k] = (type(data_def[k])=="table") 
        and cLib.serialize_table(data_def[k]) or data_def[k]
      if (type(v)=="table") then
        self.data[k] = v -- prior to 1.48
      elseif (type(v)=="string") then
        local str_fn = cSandbox.insert_return(v)
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

  return str_status

end

---------------------------------------------------------------------------------------------------
-- rename event (update main callback)
-- @param old_name (string)
-- @param new_name (string)
-- @param cb_type (xStreamModel.CB_TYPE)
-- @return bool, true when renamed
-- @return string, error message when problem was encountered

function xStreamModel:rename_callback(old_name,new_name,cb_type)
  TRACE("xStreamModel:rename_callback(old_name,new_name,cb_type)",old_name,new_name,cb_type)

  -- check if name is valid lua identifier
  if (type(new_name)~='string') then
    return false,"The callback '"..new_name.."' needs to be a string value"
  end
  local is_valid,err = cReflection.is_valid_identifier(new_name) 
  if not is_valid then
    return false,err
  end

  self:rename_token(old_name,new_name,cb_type)

  if (cb_type == xStreamModel.CB_TYPE.DATA) then
    self.data[new_name] = self.data[old_name]
    self.data[old_name] = nil
    self.data_initial[new_name] = self.data_initial[old_name]
    self.data_initial[old_name] = nil
    self.data_observable:bang()
  elseif (cb_type == xStreamModel.CB_TYPE.EVENTS) then
    self.events[new_name] = self.events[old_name]
    self.events[old_name] = nil
    self.events_compiled[new_name] = self.events_compiled[old_name]
    self.events_compiled[old_name] = nil
    self.events_observable:bang()
  else
    error("Unexpected callback type")
  end

  return true

end

---------------------------------------------------------------------------------------------------
-- rename occurrences of provided token in all callbacks (main,data,events)
-- @param old_name (string)
-- @param new_name (string)
-- @param cb_type (xStreamModel.CB_TYPE)

function xStreamModel:rename_token(old_name,new_name,cb_type)
  TRACE("xStreamModel:rename_token(old_name,new_name,cb_type)",old_name,new_name,cb_type)

  local str_old,str_new
  local cb_type = cb_type.."."

  local main_modified = false
  str_old = self.callback_str
  str_new = cSandbox.rename_string_token(str_old,old_name,new_name,cb_type)
  if (str_old ~= str_new) then
    self.callback_str = str_new
    main_modified = true
  end

  local data_modified = false
  for k,v in ipairs(self.data_initial) do
    str_old = v
    str_new = cSandbox.rename_string_token(str_old,old_name,new_name,cb_type)
    if (str_old ~= str_new) then
      self.data[k] = str_new
      self.data_initial[k] = str_new
      data_modified = true
    end
  end
  if data_modified then
    self.parse_data(self.data_initial)
    self.modified = true
  end
  
  local events_modified = false
  for k,v in ipairs(self.events) do
    str_old = v
    str_new = cSandbox.rename_string_token(str_old,old_name,new_name,cb_type)
    if (str_old ~= str_new) then
      self.events[k] = str_new
      events_modified = true
    end
  end
  if events_modified then
    self:parse_events()
    self.modified = true
  end

  if main_modified or data_modified or events_modified then
    self.modified = true
  end

end

---------------------------------------------------------------------------------------------------
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

---------------------------------------------------------------------------------------------------
-- define initial data from current value 
-- @param str_name (string)
--[[
function xStreamModel:add_initial_data(str_name)
  TRACE("xStreamModel:add_initial_data(str_name)",str_name)

  local val = self.data[str_name]
  if val and not self.data_initial[str_name] then 
    local str_fn = nil
    if (type(val)=="table") then 
      str_fn = xStreamModel.DEFAULT_DATA_STR:format(cLib.serialize_table(val))
    else
      str_fn = xStreamModel.DEFAULT_DATA_STR:format(cLib.serialize_object(val))
    end 
    self.data_initial[str_name] = str_fn
  end

end
]]

---------------------------------------------------------------------------------------------------
-- Register a new data entry
-- @param str_name (string)

function xStreamModel:add_data(str_name,str_fn)
  TRACE("xStreamModel:add_data(str_name)",str_name,str_fn)

  if not str_fn then
    str_fn = xStreamModel.DEFAULT_DATA_STR:format('{"some_value"}')
  end

  self.data[str_name] = str_fn
  self.data_initial[str_name] = str_fn

  self.modified = true

  self.data_observable:bang()

end

---------------------------------------------------------------------------------------------------
-- @param str_name (string), event key - e.g. "midi.note_on" or "args.tab.arg"
-- @param str_fn (string) the function as text

function xStreamModel:add_event(str_name,str_fn)
  TRACE("xStreamModel:add_event(str_name,str_fn)",str_name,str_fn)

  if not str_fn then
    local parts = cString.split(str_name,"%.") -- split at dot
    if (parts[1] == "midi") then
      str_fn = [[------------------------------------------------------------------------------
-- respond to MIDI ']] .. parts[2] .. [[' messages
-- @param xmsg, the xMidiMessage we have received
------------------------------------------------------------------------------
]]
    elseif (parts[1] == "voice") then
      str_fn = [[------------------------------------------------------------------------------
-- respond to voice-manager events
-- ('xvoicemgr.triggered/released/stolen_index' contains the value)
------------------------------------------------------------------------------
]]
    elseif (parts[1] == "rns") then
      str_fn = [[------------------------------------------------------------------------------
-- respond to events in renoise 
-- @param arg, depends on the notifier (see Renoise API docs)
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

---------------------------------------------------------------------------------------------------
-- parse and refresh event handlers
-- @param event_def (table)

function xStreamModel:parse_events(event_def)
  TRACE("xStreamModel:parse_events(def)")

  --self.events_compiled = {}
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
    local parts = cString.split(k,"%.") -- split at dot
    --print("parts",rprint(parts))

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
    elseif (parts[1] == "rns") then
      -- renoise event (no value)
      str_fn = v
    else 
      error("Unexpected event type")
    end

    local passed,err = self.sandbox:test_syntax(str_fn)
    if passed then

      -- renoise event : remove 
      if (parts[1] == "rns") and self.events_compiled[k] then
        self:remove_event_notifier(k)
      end

      self.events_compiled[k] = loadstring(str_fn)
      setfenv(self.events_compiled[k], self.sandbox.env)

      -- renoise event : add 
      if (parts[1] == "rns") then
        local attached,err = cObservable.attach(k,self.events_compiled[k])
        if not attached then
          LOG("*** Something went wrong while parsing notifier",k,err)
        end
      end

    else
      LOG("*** Failed to include event (bad syntax)",k,err)
      str_status = str_status .. err
    end
  end

  return str_status

end

---------------------------------------------------------------------------------------------------
-- remove previously registered notifier 
-- @param key (string), name of 

function xStreamModel:remove_event_notifier(key)
  TRACE("xStreamModel:remove_event_notifier(key)",key)

  --print(">>> about to remove notifier",key,"from this model",self.name)
  local detached,err = cObservable.detach(key,self.events_compiled[key])
  if not detached then
    LOG("*** Something went wrong while parsing notifier",key,err)
  end

end

---------------------------------------------------------------------------------------------------
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
  ..cLib.serialize_table(self.data_initial,max_depth,longstring)
  ..","
	.."\nevents = "
  ..cLib.serialize_table(self.events,max_depth,longstring)
  ..","
	.."\noptions = {"
  .."\n color = "..cColor.value_to_hex_string(self.color)..","
  .."\n},"
	.."\ncallback = [[\n"
  ..self.callback_str
  .."\n]],"
  .."\n}"


  --print("xStreamModel:serialize()",rslt)
  return rslt

end

---------------------------------------------------------------------------------------------------
-- refresh - (re-)load model from disk
-- @return bool, true when refreshed
-- @return string, error message when problem was encountered

function xStreamModel:refresh()
  TRACE("xStreamModel:refresh()")

  if self.modified then
    local str_msg = "Are you sure you want to (re-)load the model from disk?"
                  .."\nNB: Any unsaved changes will be lost!"
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

---------------------------------------------------------------------------------------------------
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
    file_path = cFilesystem.unixslashes(file_path)
  else
    file_path = self.file_path
    name = self.name
  end

  local compiled_fn,err = self.sandbox:test_syntax(self.callback_str)
  if not compiled_fn then
    return false, "The callback contains errors that need to be "
                .."fixed before you can save it to disk:\n"..err
  end

  local comments = cSandbox.contains_comment_blocks(self.callback_str)
  if comments then
    local str_msg = "Warning: the callback contains [[double brackets]], which need to"
                  .."\nbe removed from the code before the file can be saved"
                  .."\n(avoid using block comments and longstrings)"
    renoise.app():show_prompt("Strip comments",str_msg,{"OK"})
    return false
  end

  local folder,_,__ = cFilesystem.get_path_parts(file_path)
  local folder_created,err = cFilesystem.makedir(folder)
  if not folder_created then
    return false,err
  end

  local got_saved,err = cFilesystem.write_string_to_file(file_path,self:serialize())
  if not got_saved then
    return false,err
  end

  if not as_copy then
    self.file_path = file_path
    self.name = name
    self.modified = false
  end

  return true

end

---------------------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------------------
-- NB: Invoke via xStreamModels:rename_model() to rename other instances too 
-- @return bool, true when renamed 
-- @return string, error message when failed 

function xStreamModel:rename(str_name)
  TRACE("xStreamModel:rename(str_name)",str_name)

  local str_from = self.file_path
  local folder,filename,ext = cFilesystem.get_path_parts(str_from)

  if not cFilesystem.validate_filename(str_name) then
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
      LOG("*** Warning: a model definition already exists at this location: "..str_to)
    end
  end

  self.name = str_name
  self.file_path = str_to

  return true

end

---------------------------------------------------------------------------------------------------

function xStreamModel:reveal_location()
  TRACE("xStreamModel:reveal_location()")

  if self.file_path then
    renoise.app():open_path(self.file_path)
  end

end

---------------------------------------------------------------------------------------------------
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
  file_path = cFilesystem.unixslashes(file_path)

  local str_folder,str_filename,str_extension = 
    cFilesystem.get_path_parts(file_path)
  local name = cFilesystem.file_strip_extension(str_filename,str_extension)
  return file_path,name

end


---------------------------------------------------------------------------------------------------
-- invoked when song or model has changed

function xStreamModel:attach_to_song()
  TRACE("xStreamModel:attach_to_song()")

  if not self.args then 
    LOG("*** Warning: trying to attach model without arguments (no definition was loaded?)")
    return 
  end 

  self:parse_events()
  self.args:attach_to_song()

end

---------------------------------------------------------------------------------------------------

function xStreamModel:handle_preset_changes()
  TRACE("handle_preset_changes")
  if self:is_default_bank() then
    self.modified = true
  end
end

---------------------------------------------------------------------------------------------------
-- invoked when song or model has changed

function xStreamModel:detach_from_song()
  TRACE("xStreamModel:detach_from_song()")

  self.args:detach_from_song()

  for k,v in pairs(self.events) do
    local parts = cString.split(k,"%.") -- split at dot
    if (parts[1] == "rns") and self.events_compiled[k] then
      self:remove_event_notifier(k)
    end
  end

end

---------------------------------------------------------------------------------------------------
-- perform periodic updates

function xStreamModel:on_idle()

  -- argument polling
  self.args:on_idle()

end

---------------------------------------------------------------------------------------------------
-- load all preset banks available to us
-- if problems occur, they are logged...

function xStreamModel:load_preset_banks()
  TRACE("xStreamModel:load_preset_banks()")

  local preset_bank_folder = xStreamModelPresets.ROOT_PATH
  local str_folder = preset_bank_folder..self.name.."/"
  --print("str_folder",str_folder)
  if io.exists(str_folder) then
    for __, filename in pairs(os.filenames(str_folder, "*.xml")) do
      --print("filename",filename)
      local filename_no_ext = cFilesystem.file_strip_extension(filename,"xml")
      local success,err = self:load_preset_bank(filename_no_ext)
      if not success then
        LOG("*** Failed while trying to load this preset bank: "..filename..", "..err)
      end
    end
  end

end


---------------------------------------------------------------------------------------------------
-- load preset bank from our 'special' folder
-- @param str_name (string), the name of the bank
-- @return bool, true when loaded
-- @return string, error message when failed

function xStreamModel:load_preset_bank(str_name)
  TRACE("xStreamModel:load_preset_bank(str_name)",str_name)

  local preset_bank = xStreamModelPresets(self)  
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

---------------------------------------------------------------------------------------------------
-- @param str_name (string), prompt user if not defined
-- @return bool, true when created
-- @return string, error message

function xStreamModel:add_preset_bank(str_name)
  TRACE("xStreamModel:add_preset_bank(str_name)",str_name)

  if not type(str_name)=="string" then 
    return false, "Please provide a name"
  end 

  if not cFilesystem.validate_filename(str_name) then
    return false, "Please avoid using special characters in the name"
  end

  local preset_bank = xStreamModelPresets(self)
  preset_bank.name = str_name
  table.insert(self.preset_banks,preset_bank)
  self.preset_banks_observable:insert(#self.preset_banks)

  return true

end

---------------------------------------------------------------------------------------------------

function xStreamModel:remove_preset_bank(idx)
  TRACE("xStreamModel:remove_preset_bank(idx)",idx)

  local bank = self.preset_banks[idx]
  if not bank then
    LOG("*** Tried to remove non-existing preset bank")
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
  -- TODO handle this through observable
  --[[
  local favorites = self.stack.xstream.favorites:get_by_preset_bank(old_name)
  if (#favorites > 0) then
    self.stack.xstream.favorites.update_requested = true
  end
  ]]


end

---------------------------------------------------------------------------------------------------
-- retrieve preset from current bank by index
-- return table or nil

function xStreamModel:get_preset_by_index(idx)
  TRACE("xStreamModel:get_preset_by_index(idx)",idx)

  local preset_bank = self.selected_preset_bank
  local preset = preset_bank.presets[idx]
  if not preset then
    LOG("*** Tried to access a non-existing preset")
    return
  end

  return preset

end


---------------------------------------------------------------------------------------------------
-- return table<string>

function xStreamModel:get_preset_bank_names()
  TRACE("xStreamModel:get_preset_bank_names()")

  local t = {}
  for _,v in ipairs(self.preset_banks) do
    table.insert(t,v.name)
  end
  return t

end

---------------------------------------------------------------------------------------------------

function xStreamModel:is_default_bank()
  TRACE("xStreamModel:is_default_bank()")

  return (self.selected_preset_bank.name == xStreamModelPresets.DEFAULT_BANK_NAME)

end

----------------------------------------------------------------------------------------------------

function xStreamModel:__tostring()
  return type(self) 
end

---------------------------------------------------------------------------------------------------
-- ensure that the name is unique (e.g. when creating new models)
-- @param str_name (string)
-- @return string

function xStreamModel.get_suggested_name(str_name)
  TRACE("xStreamModel.get_suggested_name(str_name)",str_name)

  local model_file_path = xStreamModel.get_normalized_file_path(str_name)
  local str_path = cFilesystem.ensure_unique_filename(model_file_path)
  local suggested_name = cFilesystem.get_raw_filename(str_path)
  return suggested_name

end

---------------------------------------------------------------------------------------------------
-- produce a valid, unique data/event key (name)
-- @param str_name (string), preferred name
-- @param cb_type (string, "events" or "data")
-- @return string, a unique name for the callback

function xStreamModel:get_suggested_callback_name(str_name,cb_type)
  TRACE("xStreamModel:get_suggested_callback_name(str_name,cb_type)",str_name,cb_type)

  -- for events, check the part after the dot 
  local key_name = str_name
  if (cb_type==xStreamModel.CB_TYPE.EVENTS) then
    local parts = cString.split(str_name,"%.") -- split at dot
    key_name = parts[1]
  end
  --print("get_suggested_callback_name - key_name",key_name)

  local passed,err = cReflection.is_valid_identifier(key_name)
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

  local count = cString.detect_counter_in_str(str_name)
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

---------------------------------------------------------------------------------------------------
-- Obtain a unique, valid (file-)name for a preset bank
-- @return strinf 

function xStreamModel.get_new_preset_bank_name()
  local preset_bank_folder = xStreamModelPresets.ROOT_PATH
  local preset_folder = ("%s%s/Untitled.xml"):format(preset_bank_folder,model.name)
  local str_path = cFilesystem.ensure_unique_filename(preset_folder)
  return cFilesystem.get_raw_filename(str_path)
end 

---------------------------------------------------------------------------------------------------
-- return the path to the internal models 
-- @param str_name (string)

function xStreamModel.get_normalized_file_path(str_name)
  TRACE("xStreamModel.get_normalized_file_path(str_name)",str_name)
  local models_folder = xStreamModel.ROOT_PATH
  return ("%s%s.lua"):format(models_folder,str_name)
end

---------------------------------------------------------------------------------------------------
-- look for certain "things" to confirm that this is a valid definition
-- before actually parsing the string
-- @param str_def (string)
-- @return bool

function xStreamModel.looks_like_definition(str_def)
  TRACE("xStreamModel.looks_like_definition(str_def)",str_def)

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

