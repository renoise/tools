--[[===============================================================================================
xStreamModels
===============================================================================================]]--
--[[

This class handles models for an xStream process 

#

TODO this is the place for implementing stacked models. xStreamModelStack? 

]]

--=================================================================================================

class 'xStreamModels'

---------------------------------------------------------------------------------------------------
-- constructor

function xStreamModels:__init(process)
  TRACE("xStreamModels:__init(process)",process)

  assert(type(process) == "xStreamProcess", "Wrong type of parameter")

  --- xStream - still required by model. Otherwise would use just process..
  self.xstream = process.xstream

  --- xStreamProcess
  self.process = process

  --- xStreamPrefs, current settings
  self.prefs = renoise.tool().preferences

  --- table<xStreamModel>, registered models 
  self.models = {}

  --- table<int>, receive notification when models are added/removed
  -- the table itself contains just the model indices
  self.models_observable = renoise.Document.ObservableNumberList()

  --- int, the model index, 1-#models or 0 when none are available
  self.selected_model_index = property(self.get_selected_model_index,self.set_selected_model_index)
  self.selected_model_index_observable = renoise.Document.ObservableNumber(0)

  --- xStreamModel, read-only - nil when none are available
  self.selected_model = nil

end

---------------------------------------------------------------------------------------------------
-- Get/set
---------------------------------------------------------------------------------------------------

function xStreamModels:get_selected_model_index()
  return self.selected_model_index_observable.value
end

function xStreamModels:set_selected_model_index(idx)
  TRACE("xStreamModels:set_selected_model_index(idx)",idx)

  --[[
  if (#self.models == 0) then
    error("there are no available models")
  end
  ]]

  if (idx > #self.models) then
    error(("selected_model_index needs to be less than %d"):format(#self.models))
  end

  if (idx == self.selected_model_index_observable.value) then
    return
  end
  
  -- remove notifiers
  if self.selected_model then
    self.selected_model:detach_from_song()
  end

  -- update value
  self.selected_model = (idx > 0) and self.models[idx] or nil
  if self.selected_model then
    self.selected_model:attach_to_song()
  end
  --print("set_selected_model_index - selected_model_index =",idx)
  self.selected_model_index_observable.value = idx

  -- attach notifiers -------------------------------------

  local args_observable_notifier = function()
    TRACE("xStreamModels - args.args_observable_notifier fired...")
    self.selected_model.modified = true
  end

  local preset_index_notifier = function()
    TRACE("xStreamModels - preset_bank.selected_preset_index_observable fired...")
    local preset_idx = self.selected_model.selected_preset_bank.selected_preset_index
    self.selected_model.selected_preset_bank:recall_preset(preset_idx)
  end

  local preset_observable_notifier = function()
    TRACE("xStreamModels - preset_bank.presets_observable fired...")
    if self.selected_model:is_default_bank() then
      self.selected_model.modified = true
    end
  end

  local presets_modified_notifier = function()
    TRACE("xStreamModels - selected_preset_bank.modified_observable fired...")
    if self.selected_model.selected_preset_bank.modified then
      self.xstream.preset_bank_export_requested = true
    end
  end

  local preset_bank_notifier = function()
    TRACE("xStreamModels - selected_preset_bank_index_observable fired..")
    local preset_bank = self.selected_model.selected_preset_bank
    cObservable.attach(preset_bank.presets_observable,preset_observable_notifier)
    cObservable.attach(preset_bank.modified_observable,presets_modified_notifier)
    cObservable.attach(preset_bank.selected_preset_index_observable,preset_index_notifier)
  end

  if self.selected_model then
    cObservable.attach(self.selected_model.args.args_observable,args_observable_notifier)
    cObservable.attach(self.selected_model.selected_preset_bank_index_observable,preset_bank_notifier)
    preset_bank_notifier()
    self.selected_model.args:fire_startup_arguments()
  end



end

---------------------------------------------------------------------------------------------------
-- Class methods 
---------------------------------------------------------------------------------------------------
-- Activate the launch model

function xStreamModels:select_launch_model()
  TRACE("xStreamModels:select_launch_model()")

  for k,v in ipairs(self.models) do
    if (v.file_path == self.prefs.launch_model.value) then
      self.selected_model_index = k
    end
  end

end

---------------------------------------------------------------------------------------------------
-- @param model_name (string)
-- @return int (index) or nil
-- @return xStreamModel or nil

function xStreamModels:get_by_name(model_name)
  --TRACE("xStreamModels:get_by_name(model_name)",model_name)

  if not self.models then
    return 
  end

  for k,v in ipairs(self.models) do
    if (v.name == model_name) then
      return k,v
    end
  end

end


---------------------------------------------------------------------------------------------------
-- Create new model from scratch
-- @param str_name (string)
-- @return bool, true when model got created
-- @return string, error message on failure

function xStreamModels:create(str_name)
  TRACE("xStreamModels:create(str_name)",str_name)

  assert(type(str_name) == "string")

  local model = xStreamModel(self.process)
  model.name = str_name

  local str_name_validate = xStreamModel.get_suggested_name(str_name)
  --print(">>> str_name,str_name_validate",str_name,str_name_validate)
  if (str_name ~= str_name_validate) then
    return false,"*** Error: a model already exists with this name."
  end

  model.modified = true
  model.name = str_name
  model.file_path = ("%s%s.lua"):format(self:get_models_path(),str_name)
  model:parse_definition({
    callback = [[-------------------------------------------------------------------------------
-- Empty configuration
-------------------------------------------------------------------------------

-- Use this as a template for your own creations. 
--xline.note_columns[1].note_string = "C-4"
    
]],
  })

  self:add(model)
  self.selected_model_index = #self.models
  
  local got_saved,err = model:save()
  if not got_saved and err then
    return false,err
  end

  return true

end

---------------------------------------------------------------------------------------------------

function xStreamModels:add(model)
  TRACE("xStreamModels:add(model)")

  table.insert(self.models,model)
  self.models_observable:insert(#self.models)

end

---------------------------------------------------------------------------------------------------
-- Remove all models

function xStreamModels:remove_all()
  TRACE("xStreamModels:remove_all()")

  for k,_ in ripairs(self.models) do
    self:remove_model(k)
  end 

  self.selected_model_index = 0

end

---------------------------------------------------------------------------------------------------
-- Remove specific model from list
-- @param model_idx (int)

function xStreamModels:remove_model(model_idx)
  TRACE("xStreamModels:remove_model(model_idx)",model_idx)

  table.remove(self.models,model_idx)
  self.models_observable:remove(model_idx)

  if (self.selected_model_index == model_idx) then
    --print("remove_model - selected_model_index = 0")
    self.selected_model_index = 0
  end

end

---------------------------------------------------------------------------------------------------
-- Delete from disk, the remove from list
-- @param model_idx (int)
-- @return bool, true when we deleted the file
-- @return string, error message when failed

function xStreamModels:delete_model(model_idx)
  TRACE("xStreamModels:delete_model(model_idx)",model_idx)

  local model = self.models[model_idx]
  --print("model",model,"model.file_path",model.file_path)
  local success,err = os.remove(model.file_path)
  if not success then
    return false,err
  end

  self:remove_model(model_idx)

  return true

end

---------------------------------------------------------------------------------------------------
-- Load all models (files ending with .lua) in a given folder
-- log potential errors during parsing

function xStreamModels:load_all(str_path)
  TRACE("xStreamModels:load_all(str_path)",str_path)

  assert(type(str_path)=="string","Expected string as argument")

  if not io.exists(str_path) then
    LOG("*** Could not open model, folder does not exist:"..str_path)
    return
  end

  local log_msg = ""
  for _, filename in pairs(os.filenames(str_path, "*.lua")) do
    local model = xStreamModel(self.process)
    local model_file_path = str_path..filename
    local passed,err = model:load_definition(model_file_path)
    --print("passed,err",passed,err)
    if not passed then
      log_msg = log_msg .. err .. "\n"
    else
      --print("Add model",filename)
      self:add(model)
    end
  end

  if (log_msg ~= "") then
     LOG(log_msg.."*** WARNING One or more models failed to load during startup")
  end

end

---------------------------------------------------------------------------------------------------
-- @param no_asterisk (bool), don't add asterisk to modified models
-- return table<string>

function xStreamModels:get_names(no_asterisk)
  TRACE("xStreamModels:get_names(no_asterisk)",no_asterisk)

  local t = {}
  for _,v in ipairs(self.models) do
    if no_asterisk then
      table.insert(t,v.name)
    else
      table.insert(t,v.modified and v.name.."*" or v.name)
    end
  end
  return t

end

---------------------------------------------------------------------------------------------------
-- [Static] Get path to models root 

function xStreamModels.get_models_path()
  return xStreamUserData.USERDATA_ROOT .. xStreamUserData.MODELS_FOLDER
end
