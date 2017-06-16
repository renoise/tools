--[[===============================================================================================
xStreamModels
===============================================================================================]]--
--[[

This class handles models for xStream 

When a model is instantiated, register it using add(). This will make the application able to propagate changes between instances

]]

--=================================================================================================

class 'xStreamModels'

---------------------------------------------------------------------------------------------------
-- constructor

function xStreamModels:__init(stack)
  TRACE("xStreamModels:__init(stack)",stack)

  assert(type(stack) == "xStreamStack")

  --- xStream - still required by model. Otherwise would use just stack..
  self.xstream = stack.xstream

  --- xStreamStack
  self.process = stack

  --- xStreamPrefs, current settings
  self.prefs = renoise.tool().preferences

  --- table<string>, unique names of all available models 
  self.available_models = {}
  self.available_models_changed_observable = renoise.Document.ObservableBang()

  --- table, registered models 
  -- {
  --  model:xStreamModel
  --  member_index:number
  -- }
  self.models = {}

  --- ObservableBang, fired as models are un/registered
  self.models_changed_observable = renoise.Document.ObservableBang()

end


---------------------------------------------------------------------------------------------------
-- Class methods 
---------------------------------------------------------------------------------------------------
-- Create new model from scratch 
-- @param str_name (string)
-- @return xStreamModel, when model got created
-- @return string, error message on failure

function xStreamModels:create(str_name)
  TRACE("xStreamModels:create(str_name)",str_name)

  assert(type(str_name) == "string")

  local member = self.xstream.stack:allocate_member()

  local model = xStreamModel(member.buffer,self.xstream.voicemgr,self.xstream.output_message)
  model.name = str_name

  local str_name_validate = xStreamModel.get_suggested_name(str_name)
  --print(">>> str_name,str_name_validate",str_name,str_name_validate)
  if (str_name ~= str_name_validate) then
    return false,"*** Error: a model already exists with this name."
  end

  model.modified = true
  model.name = str_name
  model.file_path = ("%s%s.lua"):format(xStreamModel.ROOT_PATH,str_name)
  model:parse_definition({
    callback = [[-------------------------------------------------------------------------------
-- Empty configuration
-------------------------------------------------------------------------------

-- Use this as a template for your own creations. 
--xline.note_columns[1].note_string = "C-4"
    
]],
  })

  self:add(model,member.member_index)

  -- immediately save the   
  local got_saved,err = model:save()
  if not got_saved and err then
    return false,err
  end

  return model

end

---------------------------------------------------------------------------------------------------
-- Register a model 

function xStreamModels:add(model,member_idx)
  TRACE("xStreamModels:add(model,member_idx)",model,member_idx)

  assert(type(model)=="xStreamModel")
  assert(type(member_idx)=="number")

  table.insert(self.models,{
    model = model,
    member_index = member_idx
  })
  model:attach_to_song()

  self.models_changed_observable:bang()

  if not table.find(self.available_models,model.name) then 
    table.insert(self.available_models,model.name)
    self.available_models_changed_observable:bang()
  end 

  model.args:fire_startup_arguments()

end

---------------------------------------------------------------------------------------------------
-- Remove all previously registered models

function xStreamModels:remove_all()
  TRACE("xStreamModels:remove_all()")

  for k,v in ripairs(self.models) do
    self:remove(v.model.name)
  end 

end

---------------------------------------------------------------------------------------------------
-- apply callback for each model
-- @param model_name (string), match models with this name 
-- @param [member_idx] (number) leave out to match all instances 
-- @param callback (function)
-- @return table<xStreamModel>

function xStreamModels:with_models(model_name,member_idx,callback)
  TRACE("xStreamModels:with_models(model_name,member_idx,callback)",model_name,member_idx,callback)

  for k,v in ipairs(self.models) do
    if member_idx then 
      if (v.model.name == model_name) and (v.member_index == member_idx) then
        callback(k,v.model)
      end
    else
      if (v.model.name == model_name) then
        callback(k,v.model)
      end
    end
  end

end 

---------------------------------------------------------------------------------------------------
-- Remove previously registed model 
-- @param model_name (string)
-- @param [member_idx] (number) leave out to remove all instances 

function xStreamModels:remove(model_name,member_idx)
  TRACE("xStreamModels:remove(model_name,member_idx)",model_name,member_idx)

  assert(type(model_name)=="string")

  self:with_models(model_name,member_idx,function(idx,model)
    model:detach_from_song()
    table.remove(self.models,idx)
    self.models_changed_observable:bang()  
  end)

end

---------------------------------------------------------------------------------------------------
-- Retrieve model index from available_models
-- @return number or nil

function xStreamModels:get_model_index_by_name(model_name)
  TRACE("xStreamModels:get_model_index_by_name(model_name)",model_name)

  return table.find(self.available_models,model_name)

end

---------------------------------------------------------------------------------------------------
-- @return bool, true when model was renamed 
-- @return string, error message when failed

function xStreamModels:rename_model(old_name,new_name)
  TRACE("xStreamModels:rename_model(old_name,new_name)",old_name,new_name)

  local model_idx = self:get_model_index_by_name(old_name)
  if not model_idx then 
    return false, "Could not retrieve model"
  end 

  self:with_models(old_name,nil,function(idx,model)
    --print("with_models - idx,model ",idx,model)
    --print("about to rename ",model.name)
    local success,err = model:rename(new_name)
    if not success then 
      return false,err
    end 
  end)

  self.available_models[model_idx] = new_name 
  self.available_models_changed_observable:bang()

  return true 

end

---------------------------------------------------------------------------------------------------
-- Delete from disk, unregister and remove from available models
-- @param model_idx (int)
-- @return bool, true when we deleted the file
-- @return string, error message when failed

function xStreamModels:delete_model(model_name)
  TRACE("xStreamModels:delete_model(model_name)",model_name)

  local model_idx = self:get_model_index_by_name(model_name)
  local model_fpath = xStreamModel.get_normalized_file_path(model_name)
  --print(">>> model_idx",model_idx)
  --print(">>> model_fpath",model_fpath)

  local success,err = os.remove(model_fpath)
  if not success then
    return false,err
  end

  -- leaving out member index to target all instances
  self:remove(model_name)

  table.remove(self.available_models,model_idx)
  self.available_models_changed_observable:bang()

  return true

end

---------------------------------------------------------------------------------------------------
-- Index all models (files ending with .lua) in a given folder

function xStreamModels:scan_for_available(str_path)
  TRACE("xStreamModels:scan_for_available(str_path)",str_path)

  assert(type(str_path)=="string","Expected string as argument")

  if not io.exists(str_path) then
    LOG("*** Could not open model, folder does not exist:"..str_path)
    return
  end

  local log_msg = ""
  for _, filename in pairs(os.filenames(str_path, "*.lua")) do
    local name_no_ext = cFilesystem.file_strip_extension(filename,"lua")
    table.insert(self.available_models,name_no_ext)
  end
  self.available_models_changed_observable:bang()

  if (log_msg ~= "") then
     LOG(log_msg.."*** WARNING One or more models failed to load during startup")
  end

end

---------------------------------------------------------------------------------------------------
-- Retrieve available_models as a regular table 
-- return table<string>

function xStreamModels:get_available()
  TRACE("xStreamModels:get_available()")

  return table.copy(self.available_models)

end

